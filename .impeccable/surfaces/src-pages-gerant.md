---
version: 1
slug: "src-pages-gerant"
primary_target: "src/pages/gerant"
related_targets: []
---

# Espace du gérant (/gerant/)

Mode : **Operate**. Public : le commerçant (et le prospect qui teste avec le compte démo), sur téléphone surtout, entre deux clients. Tâches : voir ce qui manque en rayon et corriger un stock ; traiter les commandes reçues (confirmer, expédier, livrer, annuler avec motif) ; relire le journal. Données privées, rendues dans le navigateur après connexion (Supabase Auth + fonctions de la base). Le compte démo voit les données personnelles masquées.

Contraintes : même monde que la boutique (DESIGN.md), un seul rouge par vue, tout ce que le marchand écrirait (nombres de stock, montants, lignes de bon) au feutre. Aucune vente inventée affichée comme réelle : les commandes de démonstration sont dites telles.

## Direction contract

THESIS : l'arrière-boutique est la réserve du hanout vue par celui qui la tient : on y compte ce qui reste sur l'étagère. Refuse le gabarit d'administration (barre latérale, rangée de cartes KPI, tableau gris).

OWN-WORLD : bandeau d'enseigne en émail profond « arrière-boutique » au-dessus d'un mur chaulé ; chaque produit est une ligne de réserve avec sa vignette photo, son code de case (A-01) et son stock écrit en grand au feutre (Kalam) ; une correction raye l'ancien chiffre et écrit le nouveau à côté. Ruptures marquées d'un tampon d'encre rouge d'erreur, stock bas en rouge foncé. Onglets = puces de rayon émaillées. Bons de commande = papier ligné du carnet.

STORY : en arrivant, le gérant voit d'un coup ce qui manque et combien de commandes attendent ; il corrige un stock en deux gestes ; la base refuse une correction si une vente vient de passer et le dit ; il traite les commandes une par une.

FIRST VIEWPORT : mobile 390 — enseigne fine (DAR HDIYA · arrière-boutique, nom du compte, sortir) ; puces Réserve · Commandes · Journal ; bandeau bois « 3 commandes à traiter · 475 DH aujourd'hui » avec le seul bouton rouge « Traiter » ; puis « À surveiller » : ruptures et stocks bas, chiffres au feutre de 2 rem ; le reste des rayons A–E en dessous. Bureau : réserve en deux colonnes (à surveiller à gauche, rayons à droite).

FORM : « La réserve d'abord », 5e de ma liste ordonnée (registre, crochet à bons, file du matin, tableau noir, réserve, tableau maître-détail) ; clé de tirage f359c5a8, choisie par l'utilisateur parmi les trois structures tirées.

SIGNATURE : correction de stock — l'ancien chiffre est rayé au feutre, le nouveau s'écrit à côté, le tampon « compté par la base » apparaît à la confirmation ; en cas de vente concurrente, la ligne affiche le nouveau compte et demande de recompter.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
