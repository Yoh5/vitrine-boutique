# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

delegated (18/11/2026) : **Astro** (pages statiques, une page par produit et par langue, routage i18n /fr /ar /en) + îlots en TypeScript sans React pour le panier, la commande et le suivi ; **Supabase** (PostgreSQL) pour le catalogue, les commandes et les règles ; hébergement Netlify. Choisi plutôt qu'une plateforme (Shopify/YouCan) parce que la démo doit prouver la capacité à construire, et que la base testée (prix, remise, frais et stock décidés par la base) est l'argument principal.

## Users

Premier public, confirmé : **des commerçants marocains qui reçoivent un devis d'Axel sur freelancer.ma** et veulent voir, sur leur téléphone, la boutique qu'il construirait pour eux (catalogue trilingue, paiement à la livraison, WhatsApp, livraison par ville, promo, suivi). Les acheteurs de la boutique sont une mise en scène : la démo est fictive et le dit.

## Product Purpose

Une boutique de démonstration complète et fonctionnelle, utilisée comme preuve dans les devis. Succès : un commerçant parcourt l'achat de bout en bout en 2 minutes et comprend qu'il obtiendra la même chose.

## Positioning

**La page affiche, la base décide.** Prix, remise, frais de port et stock sont recalculés par la base au moment de la commande ; un visiteur qui modifie la page ne peut ni payer moins ni commander un produit épuisé. Deux clients sur la dernière pièce : un seul l'obtient. Testé (10 groupes de tests, test de concurrence, mutations détectées).

## Operating Context

Consultée surtout sur mobile, depuis un lien dans un devis. Maroc : commande confirmée par téléphone ou WhatsApp, paiement à la livraison dominant, frais et délais variables selon la ville.

## Capabilities and Constraints

- 24 produits en base dont 23 en vente (un retiré, pour montrer le cas), 5 catégories (soins, thé, poterie, textile, coffrets) ; 7 zones de livraison ; 3 codes promo dont un expiré pour montrer le refus.
- Paiement à la livraison seulement ; le paiement par carte exige un compte marchand au nom du commerçant (CMI, YouCan Pay…) : présent dans l'interface mais marqué « sur un vrai projet ».
- Pas de comptes clients. Espace du gérant (/gerant/, démonstration n°6) sur la même base : réserve, commandes, journal ; compte démo aux données personnelles masquées.
- Français, arabe (droite à gauche), anglais.

## Brand Commitments

Nom : **Dar Hdiya** (« la maison du cadeau »), marque fictive. Chaque vitrine d'Axel a son propre design : ne reprendre ni l'identité de Dar Zellige, Warda, Mouja ou Silicium.

## Evidence on Hand

- Base et tests : `db/` (schéma, données, tests, test de concurrence).
- Aucun avis client, aucune vente, aucun chiffre réel : ne jamais en afficher ni en inventer. Photos : libres de droits et créditées, ou absentes.

## Product Principles

1. La preuve avant la promesse : chaque argument montré à un commerçant doit être démontrable dans la démo.
2. Fictif et honnête : la boutique dit qu'elle est une démonstration.
3. Le parcours d'achat marocain réel (livraison, WhatsApp, téléphone) prime sur les conventions des boutiques occidentales.
4. Rapide sur un téléphone moyen et une connexion 4G.

## Accessibility & Inclusion

WCAG AA : contrastes 4,5:1, navigation au clavier, cibles de 44 px, lecture de droite à gauche correcte en arabe.
