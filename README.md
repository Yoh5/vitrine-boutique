# Dar Hdiya — boutique en ligne de démonstration

Cinquième démonstration du portfolio freelance, la première **boutique** : catalogue, panier,
commande et suivi qui fonctionnent pour de vrai, avec une base de données. **Boutique fictive** :
aucun produit n'est vendu, aucune commande n'est livrée, et le pied de page le dit.

| Demande récurrente d'un commerçant | Où c'est dans la boutique |
|---|---|
| Français, arabe **et** anglais | une page par produit et par langue (`/fr/`, `/ar/`, `/en/`) ; l'arabe se lit de droite à gauche, étiquettes en écriture ruqaa |
| Paiement à la livraison | seul mode actif ; le paiement par carte est affiché mais marqué « sur un vrai projet » (il faut le compte marchand du commerçant : CMI, YouCan Pay…) |
| Commande par WhatsApp | après la commande, le récapitulatif (numéro, articles, total) part sur WhatsApp en un clic |
| Frais de livraison par ville | 7 zones, frais et délai par ville, livraison offerte au-delà d'un seuil (calculé **après** remise) |
| Codes promo | pourcentage ou montant, minimum d'achat, date de fin ; un code refusé dit pourquoi |
| Gestion du stock | le stock baisse à chaque commande, « plus qu'une pièce » s'affiche, un produit épuisé ne se commande plus |
| Suivi de commande | numéro + téléphone de la commande ; sans le bon téléphone, rien ne s'affiche |
| Recherche et filtres | recherche dans les trois langues ou par code de case ; rayons (A à E) en raccourcis |

## La page affiche, la base décide

C'est ce qui distingue cette boutique d'un thème posé sur une plateforme : **le prix, la remise, les
frais et le stock sont recalculés par la base de données au moment de la commande.** La page n'envoie
que des identifiants et des quantités.

- Un visiteur qui modifie la page (prix, total) ne paie pas moins : le prix envoyé est ignoré.
- Deux clients sur la dernière pièce au même instant : **un seul l'obtient**, l'autre est prévenu.
- Le carnet du comptoir affiche le total renvoyé par la base, avec la même fonction de calcul que la
  commande : l'aperçu et la commande ne peuvent pas diverger.
- Le visiteur ne peut lire que le catalogue et les zones ; il n'a aucun droit sur les promos, les
  commandes ni la fonction de calcul.

Tout cela est **testé** (`db/tests.sql`, `db/test_concurrence.sh`) : 12 groupes de tests et un test de
deux commandes simultanées sur la dernière pièce. Les tests ont été vérifiés en cassant volontairement
la fonction (contrôle du stock retiré, seuil calculé avant la remise, suivi sans téléphone, date de fin
ignorée, verrou retiré) : chaque fois, un test échoue. Ils tournent aussi sous les **droits par défaut
de Supabase** (`db/supabase_defauts.sql`), qui accordent tout à `anon` et `authenticated` : le schéma
les retire explicitement.

## Lancer en local

Il faut Docker et Node.

```bash
bash db/lancer_tests.sh          # base jetable + schéma + données + tous les tests
bash db/api_locale.sh            # API REST locale (PostgREST, la même que celle de Supabase)
npm install && npm run dev       # boutique sur http://localhost:4321/fr/
```

## Mettre en ligne

1. **Supabase** (gratuit) : créer un projet, ouvrir l'éditeur SQL, coller `db/supabase_complet.sql`
   (généré par `bash db/preparer_supabase.sh`), exécuter.
2. **Netlify** : relier le dépôt, puis définir deux variables :
   `PUBLIC_API_URL = https://<projet>.supabase.co/rest/v1` et `PUBLIC_API_KEY = <clé anon>`.
   La clé « anon » est faite pour être publique ; la clé « service_role » ne doit **jamais** être
   mise dans le site.

Le catalogue est lu dans la base au moment de la construction (une page par produit) et le stock est
relu en direct dans le navigateur : après un changement de catalogue, relancer la construction.

## Adapter à un vrai client

1. Produits, zones et codes : `db/seed.sql` et `db/descriptions.sql` (ou directement dans Supabase).
2. Textes de l'interface dans les trois langues : `src/i18n/ui.ts`.
3. Photos : `public/photos/<slug>.webp` (carrées, 900 px) et leurs crédits dans `src/data/photos.json`.
4. WhatsApp : mettre le numéro du commerçant dans le lien `wa.me` de `src/pages/[lang]/comptoir.astro`.
5. Retirer « boutique fictive » du pied de page (`demo` dans `ui.ts`).

## Choix de conception — distinct des quatre autres vitrines

Le design est décrit dans `DESIGN.md`. En bref : la boutique est **un hanout**, l'épicerie de quartier
que tout commerçant marocain connaît. Étagère émaillée bleu-vert, planches de bois, une étiquette en
carton écrite au feutre sous chaque produit (Kalam en latin, ruqaa en arabe, l'écriture manuscrite du
quotidien), et un carnet ligné au comptoir. Un seul rouge, pour une seule action à la fois. Les matières
(bois, carton) sont de vraies photos, pas des imitations en CSS.

## Limites, dites franchement

- Une seule huile d'argan en rayon : la seule autre photo libre de droits sans marque montrait le même
  flacon. Le 50 ml reste en base, **retiré de la vente** (`actif = false`) : c'est aussi la démonstration
  qu'un produit retiré disparaît de la boutique sans casser les commandes passées.
- Pas d'espace administrateur : c'est la démonstration suivante (tableau de bord du commerçant, même base).
- Le paiement par carte n'est pas branché, volontairement.

## Crédits

Photos et textures : Wikimedia Commons, sous licences libres ; auteur, licence et lien sur la page
« Photos » de la boutique (`/fr/credits/`). Icônes : Lucide (ISC). Polices : Google Fonts (OFL).
