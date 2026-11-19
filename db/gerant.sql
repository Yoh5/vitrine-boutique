-- Dar Hdiya — espace du gérant (démonstration n°6 : tableau de bord du commerçant, même base que la boutique).
-- Même principe que la boutique : la page affiche, la base décide.
--   * Seuls les comptes inscrits dans « gerants » entrent ; un compte Supabase quelconque est refusé.
--   * Le rôle « demo » (identifiants publics) voit les commandes avec nom, téléphone et adresse MASQUÉS.
--   * Les changements de statut suivent un circuit fixé ici ; une annulation remet le stock en rayon.
--   * Une correction de stock est refusée si une vente est passée entre l'affichage et l'envoi.
--   * Chaque action est écrite dans le journal : qui, quoi, avant, après.
-- À exécuter APRÈS schema.sql (et après le seed pour la référence du compte démo).

-- ---------------------------------------------------------------- tables

create table if not exists gerants (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nom     text not null,
  role    text not null check (role in ('gerant', 'demo'))
);

create table if not exists journal_gerant (
  id       bigserial primary key,
  quand    timestamptz not null default now(),
  user_id  uuid,
  qui      text not null,
  action   text not null,                -- statut | stock | vente
  cible    text not null,                -- numéro de commande ou slug du produit
  avant    jsonb,
  apres    jsonb,
  motif    text
);

-- État de référence du catalogue, rétabli chaque nuit : les visiteurs du compte démo peuvent modifier le stock.
create table if not exists reference_demo (
  produit_id integer primary key references produits(id) on delete cascade,
  stock      integer not null,
  actif      boolean not null
);
insert into reference_demo (produit_id, stock, actif)
select id, stock, actif from produits
on conflict (produit_id) do nothing;

alter table gerants        enable row level security;
alter table journal_gerant enable row level security;
alter table reference_demo enable row level security;
-- Aucune politique, aucun droit : on n'y passe que par les fonctions ci-dessous.
revoke all on gerants, journal_gerant, reference_demo from anon, authenticated;
revoke all on sequence journal_gerant_id_seq from anon, authenticated;

-- ---------------------------------------------------------------- outils internes (aucun droit public)

-- Rôle du compte connecté, ou refus. auth.uid() est fourni par Supabase (émulé en local).
create or replace function gerant_courant(out o_role text, out o_nom text)
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  select g.role, g.nom into o_role, o_nom from gerants g where g.user_id = auth.uid();
  if o_role is null then raise exception 'acces_refuse'; end if;
end $$;

create or replace function masquer_nom(p text) returns text
language sql immutable as $$
  -- « Salma Bennani » -> « Salma B. » ; un seul mot -> son initiale
  select case when position(' ' in btrim(p)) > 0
              then split_part(btrim(p), ' ', 1) || ' ' || left(split_part(btrim(p), ' ', 2), 1) || '.'
              else left(btrim(p), 1) || '.' end
$$;

create or replace function masquer_telephone(p text) returns text
language sql immutable as $$
  select left(p, 2) || ' •• •• •• ' || right(p, 2)
$$;

-- Une commande vue par le gérant (données complètes) ou par le compte démo (données masquées).
create or replace function commande_vue(c commandes, p_role text) returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'numero', c.numero, 'statut', c.statut, 'cree_le', c.cree_le,
    'nom',       case when p_role = 'gerant' then c.nom else masquer_nom(c.nom) end,
    'telephone', case when p_role = 'gerant' then c.telephone else masquer_telephone(c.telephone) end,
    'adresse',   case when p_role = 'gerant' then c.adresse else null end,
    'ville', z.ville, 'zone', z.nom,
    'sous_total', c.sous_total, 'remise', c.remise, 'frais', c.frais, 'total', c.total,
    'code_promo', c.code_promo,
    'articles', (select coalesce(sum(l.quantite), 0) from lignes_commande l where l.commande_id = c.id))
  from zones z where z.id = c.zone_id
$$;

-- ---------------------------------------------------------------- lecture

create or replace function moi() returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object('role', o_role, 'nom', o_nom) from gerant_courant()
$$;

-- Chiffres du jour (heure de Casablanca), file d'attente, alertes de stock, 7 derniers jours.
create or replace function tableau_de_bord() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_jour date := (now() at time zone 'Africa/Casablanca')::date;
begin
  perform gerant_courant();
  return jsonb_build_object(
    'jour', v_jour,
    'aujourdhui', (
      select jsonb_build_object(
        'commandes', count(*),
        'chiffre', coalesce(sum(total), 0),
        'panier_moyen', coalesce(round(avg(total), 2), 0))
      from commandes
      where statut <> 'annulee' and (cree_le at time zone 'Africa/Casablanca')::date = v_jour),
    'a_traiter', (select count(*) from commandes where statut = 'recue'),
    'a_expedier', (select count(*) from commandes where statut = 'confirmee'),
    'ruptures', (select count(*) from produits where actif and stock = 0),
    'stock_bas', (select count(*) from produits where actif and stock between 1 and 3),
    'semaine', (
      select jsonb_agg(jsonb_build_object('jour', g.j::date, 'commandes', coalesce(n, 0), 'chiffre', coalesce(ca, 0))
                       order by j)
      from generate_series(v_jour - 6, v_jour, interval '1 day') g(j)
      left join (
        select (cree_le at time zone 'Africa/Casablanca')::date d, count(*) n, sum(total) ca
        from commandes where statut <> 'annulee' group by 1
      ) s on s.d = g.j::date));
end $$;

create or replace function liste_commandes(p_statut text default null, p_recherche text default null,
                                           p_limite integer default 100) returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_role text := (select o_role from gerant_courant());
  v_q    text := nullif(btrim(coalesce(p_recherche, '')), '');
begin
  if p_statut is not null and p_statut not in ('recue', 'confirmee', 'expediee', 'livree', 'annulee') then
    raise exception 'statut_inconnu';
  end if;
  return coalesce((
    select jsonb_agg(commande_vue(c, v_role) order by c.cree_le desc)
    from (
      select * from commandes c
      where (p_statut is null or c.statut = p_statut)
        and (v_q is null
             or c.numero ilike '%' || v_q || '%'
             -- le compte démo ne peut pas chercher dans les données qu'il ne voit pas
             or (v_role = 'gerant' and (c.nom ilike '%' || v_q || '%'
                                        or c.telephone like '%' || regexp_replace(v_q, '\D', '', 'g') || '%'
                                           and regexp_replace(v_q, '\D', '', 'g') <> '')))
      order by c.cree_le desc
      limit least(greatest(coalesce(p_limite, 100), 1), 500)
    ) c), '[]'::jsonb);
end $$;

create or replace function detail_commande(p_numero text) returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_role text := (select o_role from gerant_courant());
  c      commandes;
begin
  select * into c from commandes where numero = upper(btrim(p_numero));
  if not found then raise exception 'commande_introuvable'; end if;
  return commande_vue(c, v_role) || jsonb_build_object(
    'lignes', (select jsonb_agg(jsonb_build_object(
                        'produit_id', p.id, 'slug', p.slug, 'nom', p.nom,
                        'quantite', l.quantite, 'prix', l.prix_unitaire) order by p.id)
               from lignes_commande l join produits p on p.id = l.produit_id where l.commande_id = c.id),
    'suivantes', suivants_possibles(c.statut),
    'historique', (select coalesce(jsonb_agg(jsonb_build_object(
                        'quand', j.quand, 'qui', j.qui, 'avant', j.avant, 'apres', j.apres, 'motif', j.motif)
                        order by j.quand), '[]'::jsonb)
                   from journal_gerant j where j.action = 'statut' and j.cible = c.numero));
end $$;

create or replace function stock_gerant() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  perform gerant_courant();
  return (
    select jsonb_agg(jsonb_build_object(
             'id', p.id, 'slug', p.slug, 'nom', p.nom, 'categorie', p.categorie,
             'prix', p.prix_dh, 'stock', p.stock, 'actif', p.actif,
             'vendus_30j', coalesce(v.n, 0))
           -- d'abord ce qui demande une action : ruptures, puis stock bas, puis le reste
           order by (not p.actif), (p.stock > 0), (p.stock > 3), p.stock, p.id)
    from produits p
    left join (
      select l.produit_id, sum(l.quantite) n
      from lignes_commande l join commandes c on c.id = l.commande_id
      where c.statut <> 'annulee' and c.cree_le > now() - interval '30 days'
      group by 1
    ) v on v.produit_id = p.id);
end $$;

create or replace function journal(p_limite integer default 50) returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  perform gerant_courant();
  return coalesce((
    select jsonb_agg(jsonb_build_object('quand', quand, 'qui', qui, 'action', action, 'cible', cible,
                                        'avant', avant, 'apres', apres, 'motif', motif) order by quand desc, id desc)
    from (select * from journal_gerant order by quand desc, id desc
          limit least(greatest(coalesce(p_limite, 50), 1), 200)) j), '[]'::jsonb);
end $$;

-- ---------------------------------------------------------------- écriture

-- Le circuit d'une commande. Annulation possible tant que rien n'est parti.
create or replace function suivants_possibles(p_statut text) returns text[]
language sql immutable as $$
  select case p_statut
    when 'recue'     then array['confirmee', 'annulee']
    when 'confirmee' then array['expediee', 'annulee']
    when 'expediee'  then array['livree']
    else array[]::text[] end
$$;

create or replace function changer_statut(p_numero text, p_statut text, p_motif text default null) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  g        record;
  c        commandes;
  v_motif  text := nullif(btrim(coalesce(p_motif, '')), '');
begin
  select * into g from gerant_courant();
  -- FOR UPDATE : deux onglets qui annulent la même commande ne remettent pas deux fois le stock.
  select * into c from commandes where numero = upper(btrim(p_numero)) for update;
  if not found then raise exception 'commande_introuvable'; end if;
  if not (p_statut = any (suivants_possibles(c.statut))) then raise exception 'transition_interdite'; end if;
  if p_statut = 'annulee' and (v_motif is null or length(v_motif) < 3) then raise exception 'motif_requis'; end if;
  if v_motif is not null and length(v_motif) > 200 then raise exception 'motif_trop_long'; end if;

  update commandes set statut = p_statut where id = c.id;

  if p_statut = 'annulee' then
    update produits p set stock = p.stock + l.quantite
    from lignes_commande l where l.commande_id = c.id and p.id = l.produit_id;
  end if;

  insert into journal_gerant (user_id, qui, action, cible, avant, apres, motif)
  values (auth.uid(), g.o_nom, 'statut', c.numero, to_jsonb(c.statut), to_jsonb(p_statut), v_motif);

  return detail_commande(c.numero);
end $$;

-- Nouveau stock absolu, à condition que le stock n'ait pas bougé depuis l'affichage (p_vu).
create or replace function ajuster_stock(p_produit_id integer, p_vu integer, p_nouveau integer, p_motif text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  g       record;
  p       produits;
  v_motif text := btrim(coalesce(p_motif, ''));
begin
  select * into g from gerant_courant();
  if p_nouveau is null or p_nouveau < 0 or p_nouveau > 9999 then raise exception 'stock_invalide'; end if;
  if length(v_motif) < 3 then raise exception 'motif_requis'; end if;
  if length(v_motif) > 200 then raise exception 'motif_trop_long'; end if;

  select * into p from produits where id = p_produit_id for update;
  if not found then raise exception 'produit_introuvable'; end if;
  if p.stock is distinct from p_vu then raise exception 'stock_modifie'; end if;
  if p.stock = p_nouveau then raise exception 'rien_a_changer'; end if;

  update produits set stock = p_nouveau where id = p.id;
  insert into journal_gerant (user_id, qui, action, cible, avant, apres, motif)
  values (auth.uid(), g.o_nom, 'stock', p.slug, to_jsonb(p.stock), to_jsonb(p_nouveau), v_motif);

  return jsonb_build_object('id', p.id, 'stock', p_nouveau);
end $$;

create or replace function mettre_en_vente(p_produit_id integer, p_actif boolean) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  g record;
  p produits;
begin
  select * into g from gerant_courant();
  if p_actif is null then raise exception 'valeur_invalide'; end if;
  select * into p from produits where id = p_produit_id for update;
  if not found then raise exception 'produit_introuvable'; end if;
  if p.actif = p_actif then raise exception 'rien_a_changer'; end if;
  update produits set actif = p_actif where id = p.id;
  insert into journal_gerant (user_id, qui, action, cible, avant, apres)
  values (auth.uid(), g.o_nom, 'vente', p.slug, to_jsonb(p.actif), to_jsonb(p_actif));
  return jsonb_build_object('id', p.id, 'actif', p_actif);
end $$;

-- Chaque nuit : le catalogue reprend son état de référence (le compte démo est public).
create or replace function reinitialiser_demo() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare n integer;
begin
  update produits p set stock = r.stock, actif = r.actif
  from reference_demo r where r.produit_id = p.id and (p.stock, p.actif) is distinct from (r.stock, r.actif);
  get diagnostics n = row_count;
  insert into journal_gerant (qui, action, cible, apres)
  values ('remise à zéro', 'stock', 'catalogue', to_jsonb(n));
  return n;
end $$;

-- ---------------------------------------------------------------- droits

do $$
declare f text;
begin
  -- internes : personne
  foreach f in array array[
    'gerant_courant()', 'masquer_nom(text)', 'masquer_telephone(text)', 'commande_vue(commandes, text)',
    'suivants_possibles(text)', 'reinitialiser_demo()'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
  end loop;
  -- portes du gérant : comptes connectés seulement (le contrôle du rôle est dans chaque fonction)
  foreach f in array array[
    'moi()', 'tableau_de_bord()', 'liste_commandes(text, text, integer)', 'detail_commande(text)',
    'stock_gerant()', 'journal(integer)', 'changer_statut(text, text, text)',
    'ajuster_stock(integer, integer, integer, text)', 'mettre_en_vente(integer, boolean)'] loop
    execute format('revoke all on function %s from public, anon, authenticated', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- Remise à zéro nocturne, si l'extension pg_cron est activée (Supabase : Integrations > Cron).
do $$ begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('dar-hdiya-remise-a-zero', '0 3 * * *', 'select public.reinitialiser_demo()');
  end if;
end $$;
