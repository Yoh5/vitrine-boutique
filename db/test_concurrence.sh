#!/usr/bin/env bash
# Deux clients commandent la dernière pièce (coffret de l'Aïd, stock 1) au même moment.
# Le client A garde sa transaction ouverte 3 s ; B arrive pendant ce temps.
# Attendu : une seule commande passe, le stock finit à 0, jamais à -1.
set -u
C=${1:-darhdiya-db}
P="docker exec -i $C psql -U postgres -q -t -A"
$P -c "update produits set stock = 1 where id = 24; delete from commandes;" >/dev/null

APPEL="select passer_commande('[{\"produit_id\":24,\"quantite\":1}]', 1, null, 'Client', '0611111111', '1 rue Test, Casablanca')"
($P -c "set role anon; begin; $APPEL; select pg_sleep(3); commit;" > /tmp/a.out 2>&1) &
sleep 1
($P -c "set role anon; $APPEL;" > /tmp/b.out 2>&1) &
wait

ok=$(grep -l '"numero"' /tmp/a.out /tmp/b.out 2>/dev/null | wc -l)
refus=$(grep -l 'stock_insuffisant' /tmp/a.out /tmp/b.out 2>/dev/null | wc -l)
stock=$($P -c "select stock from produits where id = 24")
n=$($P -c "select count(*) from lignes_commande where produit_id = 24")
echo "commandes passées : $ok, refusées : $refus, stock final : $stock, lignes en base : $n"
if [ "$ok" = 1 ] && [ "$refus" = 1 ] && [ "$stock" = 0 ] && [ "$n" = 1 ]; then
  echo "Concurrence : OK"
else
  echo "Concurrence : ÉCHEC"; cat /tmp/a.out /tmp/b.out; exit 1
fi
