---
name: Dar Hdiya
description: Boutique de démonstration en hanout marocain — l'étiquette affiche, le comptoir compte.
colors:
  etagere: "#0f5c6e"
  etagere-fonce: "#0a4250"
  mur: "#e9eeec"
  mur-clair: "#f6f8f7"
  bois: "#7a4e2d"
  bois-clair: "#9a6a42"
  bois-fonce: "#573620"
  kraft: "#cda36b"
  kraft-clair: "#e3c99a"
  encre: "#17150f"
  encre-douce: "#4a4f4d"
  rouge: "#c8102e"
  rouge-fonce: "#9c0c23"
  succes: "#1e6b47"
  erreur: "#b42318"
  regle: "#b9cfd8"
typography:
  display:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(1.5rem, 1.1rem + 2vw, 2.4rem)"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "0.01em"
    fontVariation: "'wdth' 125"
  display-ar:
    fontFamily: "Lalezar, Almarai, system-ui, sans-serif"
    fontSize: "clamp(1.7rem, 1.2rem + 2.2vw, 2.6rem)"
    lineHeight: 1
  headline:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(1.4rem, 1.1rem + 1.4vw, 2.1rem)"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "0.01em"
    fontVariation: "'wdth' 118"
  marker:
    fontFamily: "Kalam, cursive"
    fontSize: "1.05rem"
    fontWeight: 700
    lineHeight: 1.2
  marker-price:
    fontFamily: "Kalam, cursive"
    fontSize: "1.6rem"
    fontWeight: 700
    lineHeight: 1.1
  marker-ar:
    fontFamily: "Aref Ruqaa, Almarai, serif"
    fontSize: "1.05rem"
    fontWeight: 700
  body:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  body-ar:
    fontFamily: "Almarai, system-ui, sans-serif"
    fontSize: "1rem"
    lineHeight: 1.7
  label:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "0.72rem"
    fontWeight: 700
    letterSpacing: "0.04em"
rounded:
  etiquette: "2px"
  md: "6px"
  comptoir: "10px"
  pastille: "50%"
spacing:
  xs: "0.4rem"
  sm: "0.6rem"
  md: "1rem"
  lg: "1.75rem"
  xl: "2.6rem"
  ligne-carnet: "2.75rem"
components:
  button-action:
    backgroundColor: "{colors.rouge}"
    textColor: "{colors.mur-clair}"
    rounded: "{rounded.md}"
    padding: "0 1.2rem"
    height: "48px"
  button-action-hover:
    backgroundColor: "{colors.rouge-fonce}"
  button-ghost:
    textColor: "{colors.encre}"
    rounded: "{rounded.md}"
    padding: "0 1.2rem"
    height: "48px"
  chip-rayon:
    backgroundColor: "{colors.etagere-fonce}"
    textColor: "{colors.mur-clair}"
    rounded: "{rounded.md}"
    padding: "0 0.9rem"
    height: "44px"
  etiquette:
    backgroundColor: "{colors.kraft}"
    textColor: "{colors.encre}"
    rounded: "{rounded.etiquette}"
    padding: "0.85rem 0.7rem 0.6rem"
  input:
    backgroundColor: "{colors.mur-clair}"
    textColor: "{colors.encre}"
    rounded: "{rounded.md}"
    height: "48px"
  comptoir-barre:
    backgroundColor: "{colors.bois-fonce}"
    textColor: "{colors.mur-clair}"
    rounded: "{rounded.comptoir}"
---

# Design System: Dar Hdiya

## Overview

**Creative North Star: "Le hanout"**

La boutique est l'épicerie de quartier marocaine que tout commerçant connaît par cœur : une étagère émaillée bleu-vert pleine du sol au plafond, des planches de bois, un produit par case, et sous chaque produit une étiquette en carton écrite au feutre. Le client prend un produit et le pose au comptoir ; c'est le comptoir — la base de données — qui fait le compte, dans un carnet ligné. L'étiquette affiche, le comptoir décide.

La densité est celle d'un vrai rayon : beaucoup de produits visibles, une grille stricte, aucune carte blanche flottante. Les matières sont réelles (photo de bois pour les planches, fibre de carton pour les étiquettes), jamais imitées en dégradés. Le monde refuse deux choses : la grille de cartes blanches des thèmes e-commerce standard, et le décor « marocain » de convention (crème, terracotta, zellige, arcs).

**Key Characteristics:**
- Étagère bleu-vert engagée sur 30 à 50 % de l'écran, planches continues d'une case à l'autre.
- Étiquettes manuscrites (Kalam en latin, ruqaa en arabe), légèrement de travers, accrochées sous la planche.
- Un seul rouge, pour une seule action à la fois.
- Le carnet du comptoir : papier ligné, chaque ligne écrite sur une réglure, total compté par la base.
- Trilingue avec arabe de droite à gauche natif (propriétés logiques, inclinaisons inversées).

## Colors

Une couleur engagée (l'émail de l'étagère), des matières (bois, carton, encre) et un seul rouge d'action.

### Primary
- **Émail d'étagère** (etagere) : fond de l'étagère et des rayons ; c'est la couleur du monde, elle couvre de grandes surfaces, jamais des détails. Blanc dessus : 7,56:1.
- **Émail profond** (etagere-fonce) : enseigne, puces de rayon, fond d'une case vide « composé à la commande ».

### Secondary
- **Carton kraft** (kraft, kraft-clair) : étiquettes de prix (avec la texture réelle), bouton de langue actif, contour des boutons « Poser ». Encre sur kraft : 7,86:1. Kraft sur émail : 3,26:1, donc décor et très grand texte seulement.
- **Bois de planche** (bois, bois-clair, bois-fonce) : planches (texture photographique multipliée par le bois), filet sous l'enseigne, barre du comptoir.

### Tertiary
- **Rouge d'action** (rouge, rouge-fonce au survol) : le bouton d'action principal de la vue, et le texte « plus qu'une pièce ». Blanc dessus : 5,88:1.

### Neutral
- **Mur chaulé** (mur) : fond des pages claires (comptoir, suivi, fiche). Encre dessus : 15,56:1.
- **Mur clair** (mur-clair) : champs de saisie, fond des photos.
- **Encre de feutre** (encre) : texte principal, pied de page.
- **Encre délavée** (encre-douce) : texte secondaire, aides (7,11:1 sur le mur).
- **Réglure** (regle) : lignes du carnet.
- **Vert reçu** (succes) et **erreur** (erreur) : tampon « compté par la base », étapes de suivi ; messages de formulaire.

### Named Rules
**The One Red Rule.** Le rouge marque une seule action par écran (« Au comptoir », « Commander », « Poser » sur la fiche). Jamais deux boutons rouges visibles ensemble, jamais de rouge décoratif.

**The Kraft-Is-Not-Text Rule.** Le kraft ne porte jamais de petit texte sur l'émail (3,26:1) : il sert de matière, de contour ou de fond d'étiquette.

## Typography

**Display Font:** Archivo très large (wdth 118 à 125, 800–900) ; en arabe Lalezar
**Body Font:** Archivo (latin) et Almarai (arabe)
**Label/Mono Font:** Kalam (latin) et Aref Ruqaa (arabe) pour tout ce qui est « écrit à la main »

**Character:** Une enseigne émaillée en capitales larges au-dessus d'un rayon, et l'écriture du marchand au feutre sur le carton. En arabe, la ruqaa est l'écriture manuscrite du quotidien, pas une calligraphie décorative.

### Hierarchy
- **Display** (900, clamp 1,5–2,4 rem, interligne 1) : le nom sur l'enseigne, en capitales.
- **Headline** (800, clamp 1,4–2,1 rem pour les rayons, 1,8–3 rem pour les titres de page) : titres de rayon et de page, capitales larges en latin.
- **Marker** (Kalam 700, 1,05 rem ; prix 1,6 rem) : nom et prix sur les étiquettes, lignes du carnet.
- **Body** (400, 1 rem, interligne 1,5 ; 1,7 en arabe) : texte courant, formulaires, pied de page, 60–70 caractères au plus par ligne.
- **Label** (700, 0,72 rem, espacement 0,04 em) : codes de case (A-01) en haut à droite de l'étiquette.

### Named Rules
**The Hand-Is-The-Price Rule.** Tout ce que le marchand écrirait (nom sur l'étiquette, prix, lignes du carnet, totaux) est en écriture manuscrite ; tout ce que l'interface dit (boutons, aides, erreurs) est en Archivo / Almarai.

## Layout

L'étagère est une grille stricte sans gouttière horizontale : 2 cases sur mobile, 3 dès 640 px, 4 dès 960 px, 5 dès 1280 px, dans un conteneur de 1320 px au plus (marges de 1 rem). Chaque case = photo carrée (5:4 sur mobile pour montrer plus d'une rangée), planche, étiquette, bouton « Poser ». Les rangées sont espacées de 2,6 rem. Les rayons portent une lettre (A à E) qui sert aussi de préfixe au code de case.

Le comptoir est une barre collée en bas sur mobile ; à partir de 1100 px il devient un bloc flottant en bas à l'extrémité de lecture (droite en latin, gauche en arabe). Les pages claires (comptoir, suivi) passent sur deux colonnes à 960 px : carnet à gauche, formulaire à droite.

Le carnet suit une grille verticale de 2,75 rem (44 px) : chaque ligne de texte, chaque rangée de contrôles et chaque total tombe sur une réglure.

## Elevation & Depth

La profondeur est celle d'objets posés : les produits portent une ombre douce d'objet sur la planche, les planches projettent une ombre vers le bas, les étiquettes pendent avec une ombre courte. Rien ne flotte sauf le comptoir sur grand écran.

### Shadow Vocabulary
- **Objet posé** (`box-shadow: 0 2px 4px rgb(23 21 15 / 0.18), 0 8px 18px rgb(23 21 15 / 0.12)`) : photos de produits, carnet, bon de commande.
- **Planche** (`box-shadow: 0 6px 8px -4px rgb(0 0 0 / 0.45)`) : sous chaque planche.
- **Étiquette pendue** (`box-shadow: 0 3px 6px rgb(0 0 0 / 0.3)`) : étiquettes de prix.
- **Comptoir flottant** (`box-shadow: 0 10px 30px rgb(0 0 0 / 0.35)`) : barre du comptoir à partir de 1100 px.
- **Case vide** (`box-shadow: inset 0 10px 18px rgb(0 0 0 / 0.35)`) : fond d'une case « composé à la commande ».

### Named Rules
**The Real-Material Rule.** Une matière se montre par sa photo (bois, carton) ou pas du tout ; jamais de dégradé, de biseau ou d'embossage CSS qui imite une matière.

## Shapes

Coins presque droits pour ce qui est en papier (étiquettes 2 px, haut des photos 3 px, carnet 4 px), coins de 6 px pour les contrôles, 10 px pour le comptoir flottant, cercle pour les lettres de rayon et les pastilles de suivi. Les étiquettes sont inclinées de −1,6° à +1,4° selon leur rang (inclinaisons inversées en arabe) et se redressent au survol. Un trou rond (7 px, couleur d'émail) marque l'endroit où l'étiquette est accrochée.

## Components

### Buttons
- **Shape:** coins doux (6 px), 48 px de haut, bordure de 2 px.
- **Primary (action):** fond rouge d'action, texte blanc, icône à gauche ; rouge foncé au survol, léger enfoncement au clic.
- **Hover / Focus:** transition de 200 ms ; anneau de focus rouge de 3 px (kraft clair sur les fonds sombres).
- **Ghost:** transparent, bordure et texte encre, rempli d'encre au survol.
- **Poser (sur l'étagère):** transparent, bordure kraft clair, texte blanc ; rempli de kraft une fois le produit posé (« Posé · 2 »).
- **WhatsApp:** bordure et texte vert reçu.

### Chips
- **Style:** puces de rayon en émail profond, texte blanc, lettre de rayon en kraft clair ; 44 px de haut, défilement horizontal sans barre.
- **State:** ancres vers les rayons ; pas d'état sélectionné.

### Cards / Containers
- **Corner Style:** pas de carte : la case d'étagère est un objet posé sur une planche, l'étiquette est un carton.
- **Background:** photo carrée sur mur clair ; case vide en émail profond avec contour pointillé kraft.
- **Shadow Strategy:** voir « Objet posé » et « Étiquette pendue ».
- **Internal Padding:** étiquette 0,85 / 0,7 / 0,6 rem, place réservée en fin de ligne pour le code de case.

### Inputs / Fields
- **Style:** fond blanc, bordure de 2 px en encre délavée, coins de 6 px, 48 px de haut ; la recherche de l'étagère est sans bordure sur mur clair, 44 px.
- **Focus:** bordure encre et anneau rouge.
- **Error / Disabled:** bordure et message en rouge d'erreur sous le champ ; le paiement par carte est un choix désactivé à bordure pointillée, avec sa note.

### Navigation
- **Style:** enseigne émaillée en tête ; sélecteur de langue en trois cases de 44 px (FR, ع, EN), la langue active sur fond kraft clair.

### L'étiquette de prix (Signature Component)
Carton kraft texturé, trou d'accroche, nom au feutre (3 lignes au plus, unités insécables), prix au feutre en grand, code de case, état du stock (« En stock », « Plus que 2 » en rouge foncé, « Épuisé » avec le prix barré au feutre).

### Le carnet du comptoir (Signature Component)
Papier blanc ligné à 2,75 rem avec marge rouge dessinée ; chaque ligne s'écrit de gauche à droite (de droite à gauche en arabe) en 500 ms quand un produit arrive ; une ligne refusée par la base est rayée en rouge avec la raison ; un tampon vert « Compté par la base » apparaît quand le total vient de la base.

## Do's and Don'ts

### Do:
- **Do** garder l'étagère en émail (#0f5c6e) comme surface dominante des pages de catalogue.
- **Do** écrire au feutre tout ce que le marchand écrirait, et en Archivo / Almarai tout ce que l'interface dit.
- **Do** montrer les matières par leur photo créditée (bois, carton) et cadrer toutes les photos de produits au même format.
- **Do** afficher une case vide « composé à la commande » quand un produit n'a pas de photo, plutôt qu'un carré blanc.
- **Do** utiliser les propriétés logiques et inverser les inclinaisons en arabe.

### Don't:
- **Don't** utiliser une grille de cartes blanches, ni le décor de convention crème, terracotta, zellige.
- **Don't** imiter une matière en CSS (dégradés en bandes, biseaux, embossage).
- **Don't** afficher deux boutons rouges dans la même vue.
- **Don't** poser du petit texte kraft sur l'émail.
- **Don't** afficher un avis client, une vente ou un chiffre inventé : la boutique est fictive et le dit.
