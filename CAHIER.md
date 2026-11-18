# Boutique de démonstration — cahier de conception

*Commencé le 18/11/2026. Projet n°1 de `idees-portfolio-freelance` : la démo qui
répond aux offres de boutique en ligne (3 offres sur 6 reçues sur freelancer.ma).*

## 1. Ce que la démo doit prouver à un client

Un commerçant marocain qui lit un devis veut voir **sa** boutique, pas un projet
d'IA. La démo doit lui montrer, en 2 minutes et sur son téléphone :

1. un catalogue en **français, arabe (droite à gauche) et anglais** ;
2. un panier, un **code promo**, des **frais de livraison calculés par ville** ;
3. une commande en **paiement à la livraison** qui part aussi **sur WhatsApp**
   avec le message déjà rempli ;
4. un **numéro de suivi** que le client final consulte lui-même ;
5. un **stock** qui baisse vraiment, et une rupture qui se voit.

**Le point qui distingue :** *la page affiche, la base décide.* Le prix, la
remise, les frais de port et le stock sont recalculés par la base de données au
moment de la commande. Un visiteur qui modifie la page ne peut ni payer moins,
ni commander un produit épuisé. C'est sa signature (« le modèle observe, le code
décide ») traduite pour un commerçant.

## 2. La marque (fictive, et dite fictive)

**Dar Hdiya** (« la maison du cadeau ») : coffrets et cadeaux marocains —
argan, savon noir, thé et verres, poteries de Safi, babouches, coffrets
mariage et Aïd. Pied de page : « Boutique fictive de démonstration ». Aucune
marque réelle, aucun avis inventé (règle des vitrines).

Même marque, plus tard, pour l'assistant WhatsApp (idée 5) et le tableau de bord
du commerçant (idée 6) : une seule base, trois démos.

## 3. Périmètre

| Dans la démo | Hors de la démo, et pourquoi |
|---|---|
| 24 produits, 5 catégories, recherche, filtres | — |
| Panier (mémorisé dans le navigateur) | — |
| Codes promo : pourcentage ou montant, minimum d'achat, date de fin | — |
| Zones de livraison par ville, frais et délai, livraison offerte au-delà d'un seuil | — |
| Paiement à la livraison | — |
| Commande WhatsApp (wa.me, message composé) | — |
| Suivi par numéro + téléphone | — |
| Stock décrémenté à la commande, rupture affichée | — |
| **Paiement par carte** | exige un compte marchand (CMI, YouCan Pay…) au nom du commerçant ; bouton présent mais marqué « sur un vrai projet » |
| Espace administrateur | c'est l'idée 6 (tableau de bord), projet suivant |
| Comptes clients | inutile pour un achat au Maroc où la commande se confirme par téléphone |

## 4. Choix techniques

- **Front :** HTML / CSS / JS sans framework, comme les 4 vitrines ; tout le texte
  dans `content.js` ; bascule RTL par propriétés CSS logiques. Hébergé sur Netlify.
- **Base :** Supabase (PostgreSQL), offre gratuite. Tables `produits`, `zones`,
  `promos`, `commandes`, `lignes_commande`.
- **Sécurité par la base (RLS) :** le visiteur anonyme peut **lire** produits et
  zones, **rien d'autre**. Il ne peut pas écrire dans `commandes` : il appelle une
  fonction `passer_commande(panier, ville, code, nom, téléphone)` qui, dans une
  seule transaction :
  1. relit les prix en base (le prix envoyé par la page est ignoré) ;
  2. verrouille et vérifie le stock de chaque ligne, refuse s'il manque ;
  3. applique le code promo s'il est valide (date, minimum) ;
  4. calcule les frais de la zone ;
  5. décrémente le stock, crée la commande, renvoie le numéro de suivi.
- **Suivi :** fonction `suivre_commande(numéro, téléphone)` ; sans le bon téléphone,
  rien n'est renvoyé (pas d'énumération des commandes d'autrui).
- **Design :** palette tirée du sujet (cadeau, artisanat, chaleur), contrastes
  mesurés ; skills ui-ux-pro-max / impeccable comme pour les vitrines.

## 5. Tests (avant d'annoncer quoi que ce soit)

Tests SQL sur les fonctions, chacun d'abord vu échouer :

- un prix modifié côté page ne change pas le total ;
- deux commandes simultanées sur la dernière pièce : une seule passe ;
- stock insuffisant → refus, rien n'est décrémenté ;
- code expiré, minimum non atteint, code inconnu → refusés ;
- livraison offerte au-delà du seuil ;
- suivi avec un mauvais téléphone → rien.

Puis vérification navigateur : bureau FR/AR/EN, mobile 375 px, parcours complet.

## 6. Plan

0. ✅ Cahier (ce document).
1. Schéma SQL + fonctions + tests (en local d'abord, Postgres ou Supabase CLI).
2. Catalogue et données (24 produits, photos libres créditées).
3. Pages : accueil, catalogue, fiche produit, panier, commande, suivi.
4. Branchement Supabase, déploiement Netlify.
5. Page « Shopify, WooCommerce ou YouCan au Maroc » — **chiffres vérifiés sur
   les sites officiels avant publication**, jamais de mémoire.
6. Ajout au portfolio et au README GitHub.

**À confirmer par Axel :** création d'un projet Supabase gratuit (compte à lui)
au moment de l'étape 4.
