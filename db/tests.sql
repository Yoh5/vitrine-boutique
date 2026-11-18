-- Tests de la base. Lancés sur une base fraîchement semée, dans une transaction annulée à la fin.
-- psql -v ON_ERROR_STOP=1 -f tests.sql : le premier test faux arrête tout avec son message.
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

create function pg_temp.cmd(panier text, zone int default 1, code text default null,
                            tel text default '0612345678') returns jsonb
language sql as $$
  select passer_commande(panier::jsonb, zone, code, 'Salma Bennani', tel, '12 rue des Orangers, Maârif')
$$;

set role anon;

\echo '1. Le visiteur lit le catalogue, rien d''autre'
do $$ begin
  perform pg_temp.egal((select count(*) from produits), 24::bigint, 'produits visibles');
  perform pg_temp.egal((select count(*) from zones), 7::bigint, 'zones visibles');
  perform pg_temp.doit_echouer('select * from promos', 'permission denied for table promos');
  perform pg_temp.doit_echouer('select * from commandes', 'permission denied for table commandes');
  perform pg_temp.doit_echouer(
    $q$insert into commandes (numero, nom, telephone, zone_id, adresse, sous_total, frais, total)
       values ('X', 'X', '0600000000', 1, 'xxxxx', 1, 0, 1)$q$,
    'permission denied for table commandes');
  perform pg_temp.doit_echouer('update produits set prix_dh = 1', 'permission denied for table produits');
end $$;

\echo '2. Commande simple : prix, frais, stock'
do $$ declare r jsonb; begin
  r := pg_temp.cmd('[{"produit_id":1,"quantite":2}]');           -- 2 x 120, Casablanca 20 DH
  perform pg_temp.egal((r->>'sous_total')::numeric, 240::numeric, 'sous-total');
  perform pg_temp.egal((r->>'frais')::numeric, 20::numeric, 'frais');
  perform pg_temp.egal((r->>'total')::numeric, 260::numeric, 'total');
  perform pg_temp.egal((select stock from produits where id = 1), 38, 'stock après commande');
  if r->>'numero' !~ '^DH-[0-9]{6}-[0-9A-F]{5}$' then
    raise exception 'ÉCHEC : numéro de suivi mal formé : %', r->>'numero';
  end if;
end $$;

\echo '3. Un prix envoyé par la page est ignoré'
do $$ declare r jsonb; begin
  r := pg_temp.cmd('[{"produit_id":1,"quantite":1,"prix_dh":1,"prix":1}]');
  perform pg_temp.egal((r->>'total')::numeric, 140::numeric, 'total malgré le prix trafiqué');
end $$;

\echo '4. Livraison offerte au-delà du seuil, calculé APRÈS remise'
do $$ declare r jsonb; begin
  r := pg_temp.cmd('[{"produit_id":8,"quantite":2}]');           -- 520 >= 400 : offerte
  perform pg_temp.egal((r->>'frais')::numeric, 0::numeric, 'frais au-delà du seuil');
  r := pg_temp.cmd('[{"produit_id":10,"quantite":1},{"produit_id":12,"quantite":1}]', 1, 'BIENVENUE10');
  -- 410 - 41 = 369 < 400 : frais dus
  perform pg_temp.egal((r->>'remise')::numeric, 41::numeric, 'remise 10 %');
  perform pg_temp.egal((r->>'frais')::numeric, 20::numeric, 'frais sous le seuil après remise');
  perform pg_temp.egal((r->>'total')::numeric, 389::numeric, 'total');
  r := pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 7);         -- « Autres villes » : jamais offerte
  perform pg_temp.egal((r->>'frais')::numeric, 45::numeric, 'frais autres villes');
end $$;

\echo '5. Codes promo'
do $$ declare r jsonb; begin
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 1, 'AID50')$q$,
                               'minimum_non_atteint');
  r := pg_temp.cmd('[{"produit_id":10,"quantite":1}]', 1, 'aid50');   -- 320 >= 300, minuscules acceptées
  perform pg_temp.egal((r->>'remise')::numeric, 50::numeric, 'remise montant');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 1, 'ETE2026')$q$,
                               'code_expire');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 1, 'GRATUIT')$q$,
                               'code_invalide');
  r := pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 1, '   ');      -- code vide = pas de code
  perform pg_temp.egal((r->>'remise')::numeric, 0::numeric, 'code vide');
end $$;

\echo '6. Stock : refus sans rien décrémenter'
do $$ begin
  perform pg_temp.doit_echouer(
    $q$select pg_temp.cmd('[{"produit_id":1,"quantite":1},{"produit_id":24,"quantite":2}]')$q$,
    'stock_insuffisant');
  perform pg_temp.egal((select stock from produits where id = 24), 1, 'stock du coffret intact');
  perform pg_temp.egal((select stock from produits where id = 1), 35, 'stock de l''autre ligne intact');
end $$;

\echo '7. Panier : regroupement et valeurs refusées'
do $$ declare r jsonb; begin
  r := pg_temp.cmd('[{"produit_id":3,"quantite":1},{"produit_id":3,"quantite":2}]');
  perform pg_temp.egal((r->>'sous_total')::numeric, 135::numeric, 'lignes regroupées (3 x 45)');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3,"quantite":15},{"produit_id":3,"quantite":6}]')$q$,
                               'quantite_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3,"quantite":0}]')$q$, 'quantite_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3,"quantite":-2}]')$q$, 'quantite_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3}]')$q$, 'quantite_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3,"quantite":"deux"}]')$q$, 'panier_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":3,"quantite":1.5}]')$q$, 'panier_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[]')$q$, 'panier_vide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('{"produit_id":3}')$q$, 'panier_vide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":999,"quantite":1}]')$q$, 'produit_indisponible');
end $$;

\echo '8. Produit retiré de la vente'
reset role;
update produits set actif = false where id = 23;
set role anon;
do $$ begin
  perform pg_temp.egal((select count(*) from produits), 23::bigint, 'produit retiré invisible');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":23,"quantite":1}]')$q$, 'produit_indisponible');
end $$;

\echo '9. Coordonnées'
do $$ begin
  perform pg_temp.egal(normaliser_telephone('+212 6 12 34 56 78'), '0612345678', '+212');
  perform pg_temp.egal(normaliser_telephone('00212-712-345-678'), '0712345678', '00212');
  perform pg_temp.egal(normaliser_telephone('05 22 12 34 56'), '0522123456', 'fixe');
  perform pg_temp.egal(normaliser_telephone('0812345678'), null::text, 'préfixe 08');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 1, null, '12345')$q$,
                               'telephone_invalide');
  perform pg_temp.doit_echouer($q$select pg_temp.cmd('[{"produit_id":1,"quantite":1}]', 99)$q$, 'zone_inconnue');
  perform pg_temp.doit_echouer(
    $q$select passer_commande('[{"produit_id":1,"quantite":1}]', 1, null, ' A ', '0612345678', '12 rue X')$q$,
    'nom_invalide');
  perform pg_temp.doit_echouer(
    $q$select passer_commande('[{"produit_id":1,"quantite":1}]', 1, null, 'Salma', '0612345678', 'ici')$q$,
    'adresse_invalide');
end $$;

\echo '10. Suivi : numéro ET téléphone'
do $$ declare r jsonb; s jsonb; begin
  r := pg_temp.cmd('[{"produit_id":5,"quantite":2}]', 3, null, '0698765432');
  s := suivre_commande(r->>'numero', '+212 698 76 54 32');
  perform pg_temp.egal(s->>'statut', 'recue', 'statut');
  perform pg_temp.egal(s->>'ville', 'marrakech', 'ville');
  perform pg_temp.egal(s->'lignes'->0->>'quantite', '2', 'quantité suivie');
  perform pg_temp.egal(suivre_commande(lower(r->>'numero'), '0698765432')->>'numero', r->>'numero',
                       'numéro en minuscules');
  perform pg_temp.egal(suivre_commande(r->>'numero', '0612345678'), null::jsonb, 'mauvais téléphone');
  perform pg_temp.egal(suivre_commande('DH-000000-00000', '0698765432'), null::jsonb, 'numéro inconnu');
end $$;

reset role;
rollback;
\echo 'Tous les tests passent.'
