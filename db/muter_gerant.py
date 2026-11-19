# Tests par mutation de gerant.sql : chaque défaut injecté doit faire échouer tests_gerant.sql.
# Usage (après bash db/lancer_tests.sh) : python db/muter_gerant.py
import subprocess, sys
from pathlib import Path
D = str(Path(__file__).parent)
P = ["docker", "exec", "-i", "darhdiya-db", "psql", "-U", "postgres", "-v", "ON_ERROR_STOP=1", "-q"]
lire = lambda f: open(f"{D}/{f}", encoding="utf-8").read()
def psql(sql):
    return subprocess.run(P, input=sql.encode("utf-8"), capture_output=True)
base = lire("gerant.sql")
graine = lire("seed.sql") + lire("descriptions.sql")
tests = lire("tests_gerant.sql")
mutations = [
 ("masquage démo retiré", "case when p_role = 'gerant' then c.telephone", "case when true then c.telephone"),
 ("stock non remis à l'annulation", "if p_statut = 'annulee' then\n    update produits", "if false then\n    update produits"),
 ("vente concurrente ignorée", "if p.stock is distinct from p_vu then raise exception 'stock_modifie'; end if;", ""),
 ("compte inconnu accepté", "if o_role is null then raise exception 'acces_refuse'; end if;", "if o_role is null then o_role := 'gerant'; o_nom := '?'; end if;"),
 ("annulation après expédition", "when 'expediee'  then array['livree']", "when 'expediee'  then array['livree', 'annulee']"),
 ("démo cherche par nom", "or (v_role = 'gerant' and (c.nom", "or ((c.nom"),
 ("annulées comptées dans le CA", "where statut <> 'annulee' and (cree_le", "where (cree_le"),
 ("motif d'annulation facultatif", "if p_statut = 'annulee' and (v_motif is null or length(v_motif) < 3) then raise exception 'motif_requis'; end if;", ""),
 ("remise à zéro sans le statut actif", "set stock = r.stock, actif = r.actif", "set stock = r.stock"),
 (None, None, None),
]
for nom, a, b in mutations:
    src = base if nom is None else base.replace(a, b)
    if nom and src == base: print("INTROUVABLE :", nom); continue
    psql(graine); r0 = psql(src)
    if r0.returncode: print("chargement raté :", nom, r0.stderr.decode()[-200:]); continue
    r = psql(tests); out = (r.stdout + r.stderr).decode("utf-8", "replace")
    if nom is None:
        print("ORIGINAL :", "OK" if r.returncode == 0 else "ÉCHOUE " + out[-300:]); continue
    msg = next((l for l in out.splitlines() if "ÉCHEC" in l), out.strip().splitlines()[-1] if out.strip() else "")
    print(("SURVIT  : " if r.returncode == 0 else "détecté : ") + nom + ("" if r.returncode == 0 else " -> " + msg.split("ÉCHEC")[-1][:100]))
