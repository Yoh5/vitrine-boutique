-- Reproduit en local les droits par défaut d'un projet Supabase, AVANT schema.sql :
-- Supabase accorde tout, sur toute nouvelle table, séquence et fonction du schéma public,
-- aux rôles anon et authenticated. Un schéma qui ne serait verrouillé que contre un Postgres
-- vierge passerait les tests ici et fuirait en ligne : c'est ce que ce fichier empêche.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
grant usage on schema public to anon, authenticated;
alter default privileges in schema public grant all on tables    to anon, authenticated;
alter default privileges in schema public grant all on sequences to anon, authenticated;
alter default privileges in schema public grant all on functions to anon, authenticated;
