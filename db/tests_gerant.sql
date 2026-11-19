-- Tests de l'espace du gérant. Base fraîchement semée + gerant.sql ; transaction annulée à la fin.
\set QUIET on
begin;

create function pg_temp.doit_echouer(appel text, attendu text) returns void
language plpgsql as $$
declare passe boolean := false;
begin
  begin
    execute appel;
    passe := true;
  exception when others then
    if sqlerrm <> attendu then
      raise exception 'ÉCHEC : % -> « % » au lieu de « % »', appel, sqlerrm, attendu;
    end if;
  end;
  if passe then raise exception 'ÉCHEC : % aurait dû être refusé (%)', appel, attendu; end if;
end $$;

create function pg_temp.egal(obtenu anyelement, attendu anyelement, quoi text) returns void
language plpgsql as $$
begin
  if obtenu is distinct from attendu then
    raise exception 'ÉCHEC : % = % au lieu de %', quoi, obtenu, attendu;
  end if;
end $$;

-- Se connecter comme un compte : rôle authenticated + jeton dont le « sub » est l'identifiant (comme PostgREST).
create function pg_temp.connecte(p_id text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_id, 'role', 'authenticated')::text, true);
$$;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'gerant@exemple.test'),
  ('00000000-0000-0000-0000-00000000000d', 'demo@exemple.test'),
  ('00000000-0000-0000-0000-00000000000f', 'inconnu@exemple.test');
insert into gerants (user_id, nom, role) values
  ('00000000-0000-0000-0000-00000000000a', 'Karima (gérante)', 'gerant'),
  ('00000000-0000-0000-0000-00000000000d', 'Visiteur démo', 'demo');

-- Deux commandes passées sur la boutique, comme un visiteur.
create temp table cmd(n int, numero text);
grant all on cmd to anon, authenticated;
set role anon;
insert into cmd select 1, passer_commande('[{"produit_id":3,"quantite":2},{"produit_id":10,"quantite":1}]', 1, null,
                                         'Salma Bennani', '06 12 34 56 78', '12 rue des Orangers, Maârif')->>'numero';
insert into cmd select 2, passer_commande('[{"produit_id":7,"quantite":1}]', 2, null,
                                         'Youssef El Amrani', '0700112233', '5 avenue Hassan II, Rabat')->>'numero';
reset role;

\echo '1. Le visiteur et un compte inconnu n''entrent pas'
set role anon;
do $$ begin
  perform pg_temp.doit_echouer('select moi()', 'permission denied for function moi');
  perform pg_temp.doit_echouer('select liste_commandes()', 'permission denied for function liste_commandes');
  perform pg_temp.doit_echouer('select reinitialiser_demo()', 'permission denied for function reinitialiser_demo');
end $$;
reset role;
set role authenticated;
select pg_temp.connecte('00000000-0000-0000-0000-00000000000f') \g /dev/null
do $$ begin
  perform pg_temp.doit_echouer('select moi()', 'acces_refuse');
  perform pg_temp.doit_echouer('select tableau_de_bord()', 'acces_refuse');
  perform pg_temp.doit_echouer('select liste_commandes()', 'acces_refuse');
  perform pg_temp.doit_echouer($q$select detail_commande('X')$q$, 'acces_refuse');
  perform pg_temp.doit_echouer('select stock_gerant()', 'acces_refuse');
  perform pg_temp.doit_echouer('select journal()', 'acces_refuse');
  perform pg_temp.doit_echouer($q$select changer_statut('X', 'confirmee')$q$, 'acces_refuse');
  perform pg_temp.doit_echouer($q$select ajuster_stock(3, 0, 5, 'essai')$q$, 'acces_refuse');
  perform pg_temp.doit_echouer('select mettre_en_vente(3, false)', 'acces_refuse');
  -- ni les tables, ni les fonctions internes
  perform pg_temp.doit_echouer('select * from gerants', 'permission denied for table gerants');
  perform pg_temp.doit_echouer('select * from journal_gerant', 'permission denied for table journal_gerant');
  perform pg_temp.doit_echouer('select * from commandes', 'permission denied for table commandes');
  perform pg_temp.doit_echouer('select * from gerant_courant()', 'permission denied for function gerant_courant');
  perform pg_temp.doit_echouer('select reinitialiser_demo()', 'permission denied for function reinitialiser_demo');
  perform pg_temp.doit_echouer('update produits set stock = 0', 'permission denied for table produits');
end $$;
-- sans jeton du tout
select set_config('request.jwt.claims', '', true) \g /dev/null
do $$ begin perform pg_temp.doit_echouer('select moi()', 'acces_refuse'); end $$;

\echo '2. Le compte démo voit les commandes, données personnelles masquées'
select pg_temp.connecte('00000000-0000-0000-0000-00000000000d') \g /dev/null
do $$
declare c jsonb := (select x from jsonb_array_elements(liste_commandes()) x
                    where x->>'numero' = (select numero from cmd where n = 1));
begin
  perform pg_temp.egal(moi()->>'role', 'demo', 'rôle');
  perform pg_temp.egal(jsonb_array_length(liste_commandes()), 2, 'commandes visibles');
  perform pg_temp.egal(c->>'nom', 'Salma B.', 'nom masqué');
  perform pg_temp.egal(c->>'telephone', '06 •• •• •• 78', 'téléphone masqué');
  perform pg_temp.egal(c->'adresse', 'null'::jsonb, 'adresse cachée');
  perform pg_temp.egal((c->>'total')::numeric, 410::numeric, 'total (livraison offerte dès 400)');
  perform pg_temp.egal((c->>'articles')::int, 3, 'articles');
  perform pg_temp.egal(detail_commande((select numero from cmd where n = 1))->>'telephone', '06 •• •• •• 78',
                       'téléphone masqué dans le détail');
  -- il ne peut pas retrouver une commande par une donnée qu'il ne voit pas
  perform pg_temp.egal(jsonb_array_length(liste_commandes(null, 'Bennani')), 0, 'recherche par nom (démo)');
  perform pg_temp.egal(jsonb_array_length(liste_commandes(null, '12 34 56')), 0, 'recherche par téléphone (démo)');
  perform pg_temp.egal(jsonb_array_length(liste_commandes(null, (select numero from cmd where n = 2))), 1,
                       'recherche par numéro (démo)');
end $$;

\echo '3. Le gérant voit tout et cherche par nom ou téléphone'
select pg_temp.connecte('00000000-0000-0000-0000-00000000000a') \g /dev/null
do $$
declare c jsonb := detail_commande((select numero from cmd where n = 1));
begin
  perform pg_temp.egal(c->>'nom', 'Salma Bennani', 'nom complet');
  perform pg_temp.egal(c->>'telephone', '0612345678', 'téléphone complet');
  perform pg_temp.egal(c->>'adresse', '12 rue des Orangers, Maârif', 'adresse');
  perform pg_temp.egal(jsonb_array_length(c->'lignes'), 2, 'lignes');
  perform pg_temp.egal(c->'suivantes', '["confirmee", "annulee"]'::jsonb, 'suites possibles');
  perform pg_temp.egal(jsonb_array_length(liste_commandes(null, 'bennani')), 1, 'recherche par nom');
  perform pg_temp.egal(jsonb_array_length(liste_commandes(null, '07 00 11')), 1, 'recherche par téléphone');
  perform pg_temp.egal(jsonb_array_length(liste_commandes('recue')), 2, 'filtre par statut');
  perform pg_temp.egal(jsonb_array_length(liste_commandes('livree')), 0, 'filtre vide');
  perform pg_temp.doit_echouer($q$select liste_commandes('perdue')$q$, 'statut_inconnu');
  perform pg_temp.doit_echouer($q$select detail_commande('DH-000000-XXXXX')$q$, 'commande_introuvable');
end $$;

\echo '4. Le circuit des statuts est fixé par la base'
do $$
declare
  n1 text := (select numero from cmd where n = 1);
begin
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L)', n1, 'livree'), 'transition_interdite');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L)', n1, 'expediee'), 'transition_interdite');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L)', n1, 'n_importe'), 'transition_interdite');
  perform pg_temp.egal(changer_statut(n1, 'confirmee')->>'statut', 'confirmee', 'confirmée');
  perform pg_temp.egal(changer_statut(lower(n1), 'expediee')->>'statut', 'expediee', 'expédiée (numéro en minuscules)');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L, %L)', n1, 'annulee', 'client absent'),
                               'transition_interdite');                -- trop tard : le colis est parti
  perform pg_temp.egal(changer_statut(n1, 'livree')->>'statut', 'livree', 'livrée');
  -- livree est un état final
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L)', n1, 'recue'), 'transition_interdite');
  perform pg_temp.egal(jsonb_array_length(detail_commande(n1)->'suivantes'), 0, 'livrée = fin');
  perform pg_temp.egal(jsonb_array_length(detail_commande(n1)->'historique'), 3, 'historique de la commande');
  perform pg_temp.egal(detail_commande(n1)->'historique'->0->>'qui', 'Karima (gérante)', 'auteur journalisé');
end $$;

\echo '5. Une annulation remet le stock en rayon, une seule fois'
do $$
declare
  n2 text := (select numero from cmd where n = 2);
  s_avant int := (select (x->>'stock')::int from jsonb_array_elements(stock_gerant()) x where (x->>'id')::int = 7);
  s_apres int;
begin
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L)', n2, 'annulee'), 'motif_requis');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L, %L)', n2, 'annulee', ' x '), 'motif_requis');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L, %L)', n2, 'annulee', repeat('x', 201)),
                               'motif_trop_long');
  perform pg_temp.egal(changer_statut(n2, 'annulee', 'client injoignable')->>'statut', 'annulee', 'annulée');
  s_apres := (select (x->>'stock')::int from jsonb_array_elements(stock_gerant()) x where (x->>'id')::int = 7);
  perform pg_temp.egal(s_apres, s_avant + 1, 'stock remis');
  perform pg_temp.doit_echouer(format('select changer_statut(%L, %L, %L)', n2, 'annulee', 'deux fois'),
                               'transition_interdite');
  s_apres := (select (x->>'stock')::int from jsonb_array_elements(stock_gerant()) x where (x->>'id')::int = 7);
  perform pg_temp.egal(s_apres, s_avant + 1, 'stock remis une seule fois');
  perform pg_temp.egal(journal(1)->0->>'motif', 'client injoignable', 'motif journalisé');
end $$;

\echo '6. Stock : une vente passée entre-temps n''est pas écrasée'
do $$
declare s int;
begin
  s := (select (x->>'stock')::int from jsonb_array_elements(stock_gerant()) x where (x->>'id')::int = 3);
  perform pg_temp.doit_echouer(format('select ajuster_stock(3, %s, 50, %L)', s + 1, 'arrivage'), 'stock_modifie');
  perform pg_temp.doit_echouer(format('select ajuster_stock(3, %s, -1, %L)', s, 'arrivage'), 'stock_invalide');
  perform pg_temp.doit_echouer(format('select ajuster_stock(3, %s, 10000, %L)', s, 'arrivage'), 'stock_invalide');
  perform pg_temp.doit_echouer(format('select ajuster_stock(3, %s, 50, %L)', s, ''), 'motif_requis');
  perform pg_temp.doit_echouer(format('select ajuster_stock(3, %s, %s, %L)', s, s, 'rien'), 'rien_a_changer');
  perform pg_temp.doit_echouer(format('select ajuster_stock(999, 0, 5, %L)', 'arrivage'), 'produit_introuvable');
  perform pg_temp.egal((ajuster_stock(3, s, 50, 'arrivage du souk')->>'stock')::int, 50, 'stock ajusté');
  perform pg_temp.egal(journal(1)->0->>'motif', 'arrivage du souk', 'motif au journal');
  perform pg_temp.egal(journal(1)->0->'avant', to_jsonb(s), 'avant au journal');
end $$;
-- la vente concurrente : un visiteur achète pendant que le gérant regarde l'écran
set role anon;
select passer_commande('[{"produit_id":3,"quantite":1}]', 1, null, 'Nadia Tazi', '0611223344', '3 rue de Fès, Casablanca') \g /dev/null
set role authenticated;
select pg_temp.connecte('00000000-0000-0000-0000-00000000000a') \g /dev/null
do $$ begin
  perform pg_temp.doit_echouer($q$select ajuster_stock(3, 50, 60, 'recompte')$q$, 'stock_modifie');
  perform pg_temp.egal((ajuster_stock(3, 49, 60, 'recompte')->>'stock')::int, 60, 'après relecture');
end $$;

\echo '7. Retirer un produit de la vente le cache de la boutique'
do $$ begin
  perform pg_temp.egal((mettre_en_vente(5, false)->>'actif')::boolean, false, 'retiré');
  perform pg_temp.doit_echouer('select mettre_en_vente(5, false)', 'rien_a_changer');
end $$;
set role anon;
do $$ begin
  perform pg_temp.egal((select count(*) from produits where id = 5), 0::bigint, 'invisible au visiteur');
end $$;
set role authenticated;
select pg_temp.connecte('00000000-0000-0000-0000-00000000000a') \g /dev/null

\echo '8. Tableau de bord : annulées exclues, files d''attente, alertes'
do $$
declare t jsonb := tableau_de_bord();
begin
  perform pg_temp.egal((t->'aujourdhui'->>'commandes')::int, 2, 'commandes du jour (hors annulée)');
  perform pg_temp.egal((t->'aujourdhui'->>'chiffre')::numeric, 410 + 65::numeric, 'chiffre du jour');
  perform pg_temp.egal((t->>'a_traiter')::int, 1, 'à traiter');
  perform pg_temp.egal((t->>'a_expedier')::int, 0, 'à expédier');
  perform pg_temp.egal(jsonb_array_length(t->'semaine'), 7, 'sept jours');
  perform pg_temp.egal((t->'semaine'->6->>'commandes')::int, 2, 'aujourd''hui dans la semaine');
end $$;
reset role;
update produits set stock = 0 where id = 24;   -- coffret en rupture
set role authenticated;
select pg_temp.connecte('00000000-0000-0000-0000-00000000000a') \g /dev/null
do $$ begin
  perform pg_temp.egal((tableau_de_bord()->>'ruptures')::int, 1, 'ruptures');
  perform pg_temp.egal((stock_gerant()->0->>'id')::int, 24, 'rupture en tête de liste');
end $$;

\echo '9. Le compte démo peut agir (journalisé à son nom)'
select pg_temp.connecte('00000000-0000-0000-0000-00000000000d') \g /dev/null
do $$ begin
  perform pg_temp.egal((ajuster_stock(24, 0, 4, 'essai démo')->>'stock')::int, 4, 'démo ajuste');
  perform pg_temp.egal(journal(1)->0->>'qui', 'Visiteur démo', 'auteur démo');
end $$;

\echo '10. Remise à zéro nocturne'
reset role;
do $$ begin
  perform reinitialiser_demo();
  perform pg_temp.egal((select stock from produits where id = 24), 1, 'stock de référence');
  perform pg_temp.egal((select stock from produits where id = 3),
                       (select stock from reference_demo where produit_id = 3), 'stock du savon');
  perform pg_temp.egal((select actif from produits where id = 5), true, 'produit remis en vente');
  perform pg_temp.egal((select actif from produits where id = 2), false, 'argan 50 ml reste retirée');
end $$;

\echo 'Tous les tests du gérant passent.'
rollback;
