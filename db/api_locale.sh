#!/usr/bin/env bash
# API REST locale : PostgREST devant la base de lancer_tests.sh (la même API que Supabase).
set -e
cd "$(dirname "$0")"
docker exec -i darhdiya-db psql -U postgres -q < api.sql
docker network create darhdiya >/dev/null 2>&1 || true
docker network connect darhdiya darhdiya-db 2>/dev/null || true
docker rm -f darhdiya-api >/dev/null 2>&1 || true
docker run -d --name darhdiya-api --network darhdiya -p 54321:3000 \
  -e PGRST_DB_URI="postgres://authenticator:demo@darhdiya-db:5432/postgres" \
  -e PGRST_DB_SCHEMAS=public -e PGRST_DB_ANON_ROLE=anon \
  -e PGRST_JWT_SECRET=secret-local-de-developpement-32-caracteres-au-moins postgrest/postgrest:latest >/dev/null
echo "API sur http://localhost:54321"
