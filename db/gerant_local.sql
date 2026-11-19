-- LOCAL SEULEMENT : deux comptes pour développer l'espace du gérant sans Supabase Auth.
-- (En ligne, les comptes se créent dans Supabase > Authentication, puis une ligne dans « gerants ».)
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'gerant@exemple.test'),
  ('00000000-0000-0000-0000-00000000000d', 'demo@exemple.test')
on conflict do nothing;
insert into gerants (user_id, nom, role) values
  ('00000000-0000-0000-0000-00000000000a', 'Karima', 'gerant'),
  ('00000000-0000-0000-0000-00000000000d', 'Visiteur démo', 'demo')
on conflict do nothing;
grant authenticated to authenticator;
