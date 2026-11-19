#!/usr/bin/env bash
# Un seul fichier à coller dans l'éditeur SQL de Supabase : schéma + données de démonstration.
# (api.sql et supabase_defauts.sql ne servent qu'en local : Supabase a déjà ses rôles et ses droits.)
set -e
cd "$(dirname "$0")"
{ echo "-- Généré par preparer_supabase.sh le $(date -u +%Y-%m-%dT%H:%MZ). Ne pas modifier ici."
  cat schema.sql seed.sql descriptions.sql gerant.sql; } > supabase_complet.sql
# Pour un projet déjà en ligne (boutique installée avant l'espace du gérant) : seulement gerant.sql.
{ echo "-- Généré par preparer_supabase.sh le $(date -u +%Y-%m-%dT%H:%MZ). Espace du gérant seul."
  cat gerant.sql; } > supabase_gerant.sql
echo "db/supabase_complet.sql prêt ($(wc -l < supabase_complet.sql) lignes), db/supabase_gerant.sql prêt ($(wc -l < supabase_gerant.sql) lignes)"
