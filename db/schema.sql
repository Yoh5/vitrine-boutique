-- Dar Hdiya — boutique de démonstration (fictive)
-- Principe : la page affiche, la base décide.
-- Le visiteur (rôle anon, comme sur Supabase) LIT le catalogue et les zones.
-- Il n'écrit rien directement : il appelle passer_commande(), qui recalcule
-- prix, remise, frais et stock dans une seule transaction.

-- Rôle du visiteur anonyme. Sur Supabase il existe déjà ; en local on le crée.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
end $$;

grant usage on schema public to anon;

-- ---------------------------------------------------------------- tables

create table if not exists produits (
  id          serial primary key,
  slug        text not null unique,
  categorie   text not null,
  nom         jsonb not null,            -- {"fr": "...", "ar": "...", "en": "..."}
  description jsonb not null default '{}'::jsonb,
  prix_dh     numeric(10,2) not null check (prix_dh > 0),
  stock       integer not null check (stock >= 0),
  actif       boolean not null default true
);

create table if not exists zones (
  id                     serial primary key,
  ville                  text not null unique,
  nom                    jsonb not null,
  frais_dh               numeric(10,2) not null check (frais_dh >= 0),
  delai                  text not null,           -- « 24 h », « 2 à 3 jours »
  livraison_offerte_des  numeric(10,2)            -- seuil après remise ; null = jamais
);

create table if not exists promos (
  code        text primary key check (code = upper(code)),
  type        text not null check (type in ('pourcent', 'montant')),
  valeur      numeric(10,2) not null check (valeur > 0),
  minimum_dh  numeric(10,2) not null default 0,
  fin         timestamptz,                         -- null = sans date de fin
  actif       boolean not null default true,
  check (type <> 'pourcent' or valeur <= 100)
);

create table if not exists commandes (
  id          serial primary key,
  numero      text not null unique,
  nom         text not null,
  telephone   text not null,                       -- normalisé : 0XXXXXXXXX
  zone_id     integer not null references zones(id),
  adresse     text not null,
  sous_total  numeric(10,2) not null,
  remise      numeric(10,2) not null default 0,
  frais       numeric(10,2) not null,
  total       numeric(10,2) not null,
  code_promo  text,
  paiement    text not null default 'livraison' check (paiement = 'livraison'),
  statut      text not null default 'recue'
              check (statut in ('recue', 'confirmee', 'expediee', 'livree', 'annulee')),
  cree_le     timestamptz not null default now()
);

create table if not exists lignes_commande (
  commande_id   integer not null references commandes(id) on delete cascade,
  produit_id    integer not null references produits(id),
  quantite      integer not null check (quantite between 1 and 20),
  prix_unitaire numeric(10,2) not null,
  primary key (commande_id, produit_id)
);

-- ---------------------------------------------------------------- accès

alter table produits        enable row level security;
alter table zones           enable row level security;
alter table promos          enable row level security;
alter table commandes       enable row level security;
alter table lignes_commande enable row level security;

revoke all on produits, zones, promos, commandes, lignes_commande from anon;
grant select on produits, zones to anon;

drop policy if exists catalogue_visible on produits;
create policy catalogue_visible on produits for select to anon using (actif);

drop policy if exists zones_visibles on zones;
create policy zones_visibles on zones for select to anon using (true);
-- promos, commandes, lignes_commande : aucune règle pour anon = aucun accès.

-- ---------------------------------------------------------------- fonctions

-- Téléphone marocain : 06/07/05 + 8 chiffres, ou +212 / 00212. Renvoie 0XXXXXXXXX ou null.
create or replace function normaliser_telephone(p text) returns text
language sql immutable as $$
  select case
    when d ~ '^0[5-7][0-9]{8}$'      then d
    when d ~ '^212[5-7][0-9]{8}$'    then '0' || substr(d, 4)
    when d ~ '^00212[5-7][0-9]{8}$'  then '0' || substr(d, 6)
  end
  from (select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') as d) x
$$;

-- Erreurs : un code court en message, que la page traduit dans la langue du visiteur.

-- Le calcul, écrit UNE fois : l'aperçu du comptoir et la commande l'appellent tous les deux,
-- ils ne peuvent donc pas diverger. Interne : le visiteur ne l'appelle pas directement.
-- p_verrou = true (commande) : verrouille les produits jusqu'à la fin de la transaction.
create or replace function calculer_commande(
  p_panier  jsonb,      -- [{"produit_id": 3, "quantite": 2}, ...] ; tout autre champ est ignoré
  p_zone_id integer,
  p_code    text,
  p_verrou  boolean
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_code       text := nullif(upper(btrim(coalesce(p_code, ''))), '');
  v_ligne      record;
  v_produit    produits%rowtype;
  v_zone       zones%rowtype;
  v_promo      promos%rowtype;
  v_sous_total numeric(10,2) := 0;
  v_remise     numeric(10,2) := 0;
  v_frais      numeric(10,2);
  v_lignes     jsonb;
  v_detail     jsonb := '[]'::jsonb;
begin
  if jsonb_typeof(p_panier) is distinct from 'array' or jsonb_array_length(p_panier) = 0 then
    raise exception 'panier_vide';
  end if;

  select * into v_zone from zones where id = p_zone_id;
  if not found then raise exception 'zone_inconnue'; end if;

  -- Panier regroupé par produit ; quantités entières de 1 à 20 par produit.
  -- (Pas de table temporaire : dans une fonction security definer, le visiteur pourrait en créer une du même nom.)
  begin
    select coalesce(jsonb_agg(jsonb_build_object('produit_id', produit_id, 'quantite', quantite)
                              order by produit_id), '[]'::jsonb)
    into v_lignes
    from (select (e->>'produit_id')::integer as produit_id,
                 sum((e->>'quantite')::integer)::integer as quantite
          from jsonb_array_elements(p_panier) e
          group by 1) s;
  exception when others then
    raise exception 'panier_invalide';
  end;
  if exists (select 1 from jsonb_array_elements(v_lignes) x
             where x->'produit_id' = 'null'::jsonb or x->'quantite' = 'null'::jsonb
                or (x->>'quantite')::integer not between 1 and 20) then
    raise exception 'quantite_invalide';
  end if;

  -- Ordre fixe des produits (évite l'interblocage), verrou si commande, puis contrôle du stock.
  for v_ligne in select (x->>'produit_id')::integer as produit_id, (x->>'quantite')::integer as quantite
                 from jsonb_array_elements(v_lignes) x order by 1 loop
    if p_verrou then
      select * into v_produit from produits where id = v_ligne.produit_id for update;
    else
      select * into v_produit from produits where id = v_ligne.produit_id;
    end if;
    if not found or not v_produit.actif then raise exception 'produit_indisponible'; end if;
    if v_produit.stock < v_ligne.quantite then raise exception 'stock_insuffisant'; end if;
    v_sous_total := v_sous_total + v_produit.prix_dh * v_ligne.quantite;   -- prix lu en base
    v_detail := v_detail || jsonb_build_object('produit_id', v_produit.id, 'quantite', v_ligne.quantite,
                                               'prix', v_produit.prix_dh);
  end loop;

  if v_code is not null then
    select * into v_promo from promos where code = v_code and actif;
    if not found then raise exception 'code_invalide'; end if;
    if v_promo.fin is not null and v_promo.fin < now() then raise exception 'code_expire'; end if;
    if v_sous_total < v_promo.minimum_dh then raise exception 'minimum_non_atteint'; end if;
    v_remise := case v_promo.type
                  when 'pourcent' then round(v_sous_total * v_promo.valeur / 100, 2)
                  else least(v_promo.valeur, v_sous_total)
                end;
  end if;

  v_frais := case when v_zone.livraison_offerte_des is not null
                       and v_sous_total - v_remise >= v_zone.livraison_offerte_des
                  then 0 else v_zone.frais_dh end;

  return jsonb_build_object(
    'lignes', v_detail, 'zone_id', v_zone.id, 'code', v_code,
    'sous_total', v_sous_total, 'remise', v_remise, 'frais', v_frais,
    'total', v_sous_total - v_remise + v_frais, 'delai', v_zone.delai,
    'livraison_offerte_des', v_zone.livraison_offerte_des);
end $$;

-- Aperçu du comptoir : le même calcul, sans rien écrire ni verrouiller.
create or replace function apercu_commande(p_panier jsonb, p_zone_id integer, p_code text)
returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select calculer_commande(p_panier, p_zone_id, p_code, false)
$$;

create or replace function passer_commande(
  p_panier    jsonb,
  p_zone_id   integer,
  p_code      text,
  p_nom       text,
  p_telephone text,
  p_adresse   text
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tel     text := normaliser_telephone(p_telephone);
  v_nom     text := btrim(coalesce(p_nom, ''));
  v_adresse text := btrim(coalesce(p_adresse, ''));
  v_calc    jsonb;
  v_numero  text;
  v_id      integer;
begin
  if length(v_nom) not between 2 and 80 then raise exception 'nom_invalide'; end if;
  if v_tel is null then raise exception 'telephone_invalide'; end if;
  if length(v_adresse) not between 5 and 300 then raise exception 'adresse_invalide'; end if;

  v_calc := calculer_commande(p_panier, p_zone_id, p_code, true);   -- produits verrouillés

  loop
    v_numero := 'DH-' || to_char(now(), 'YYMMDD') || '-'
                || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 5));
    exit when not exists (select 1 from commandes where numero = v_numero);
  end loop;

  insert into commandes (numero, nom, telephone, zone_id, adresse,
                         sous_total, remise, frais, total, code_promo)
  values (v_numero, v_nom, v_tel, p_zone_id, v_adresse,
          (v_calc->>'sous_total')::numeric, (v_calc->>'remise')::numeric,
          (v_calc->>'frais')::numeric, (v_calc->>'total')::numeric, v_calc->>'code')
  returning id into v_id;

  insert into lignes_commande (commande_id, produit_id, quantite, prix_unitaire)
  select v_id, (x->>'produit_id')::integer, (x->>'quantite')::integer, (x->>'prix')::numeric
  from jsonb_array_elements(v_calc->'lignes') x;

  update produits pr set stock = pr.stock - (x->>'quantite')::integer
  from jsonb_array_elements(v_calc->'lignes') x where pr.id = (x->>'produit_id')::integer;

  return jsonb_build_object(
    'numero', v_numero, 'sous_total', v_calc->'sous_total', 'remise', v_calc->'remise',
    'frais', v_calc->'frais', 'total', v_calc->'total', 'delai', v_calc->>'delai');
end $$;

-- Suivi : il faut le numéro ET le téléphone de la commande ; sinon null, sans dire lequel est faux.
create or replace function suivre_commande(p_numero text, p_telephone text) returns jsonb
language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'numero', c.numero, 'statut', c.statut, 'cree_le', c.cree_le,
    'total', c.total, 'ville', z.ville, 'delai', z.delai,
    'lignes', (select jsonb_agg(jsonb_build_object('nom', p.nom, 'quantite', l.quantite)
                                order by p.id)
               from lignes_commande l join produits p on p.id = l.produit_id
               where l.commande_id = c.id))
  from commandes c join zones z on z.id = c.zone_id
  where c.numero = upper(btrim(p_numero))
    and c.telephone = normaliser_telephone(p_telephone)
$$;

revoke all on function passer_commande(jsonb, integer, text, text, text, text) from public;
revoke all on function suivre_commande(text, text) from public;
revoke all on function apercu_commande(jsonb, integer, text) from public;
revoke all on function calculer_commande(jsonb, integer, text, boolean) from public;
grant execute on function passer_commande(jsonb, integer, text, text, text, text) to anon;
grant execute on function suivre_commande(text, text) to anon;
grant execute on function apercu_commande(jsonb, integer, text) to anon;
-- calculer_commande : aucun droit pour anon (sinon il pourrait verrouiller des produits à volonté).
