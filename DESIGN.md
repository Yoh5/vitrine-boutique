# Dar Hdiya — système de design

Source : ui-ux-pro-max. Palette « Gift & Wishlist » (rouge cadeau + or) adaptée au sujet
marocain ; paire arabe de la base (Naskh) écartée parce que Dar Zellige l'utilise déjà.
Règle des vitrines : chaque site a son propre design.

| Déjà pris | Couleurs | Polices |
|---|---|---|
| Dar Zellige | crème, terracotta, vert zellige | Playfair, Karla, Noto Naskh |
| Warda | lait, rose | Cormorant, Jost, El Messiri, Tajawal |
| Mouja | béton, vermillon, océan | Barlow, Changa, IBM Plex Arabic |
| Silicium | papier, vernis vert, cuivre | IBM Plex, JetBrains Mono, Noto Kufi/Sans Arabic |

## Couleurs (contrastes mesurés, WCAG)

| Jeton | Hex | Usage | Contraste |
|---|---|---|---|
| `--papier` | `#FAF6EE` | fond | — |
| `--carte` | `#FFFFFF` | cartes, panneaux | — |
| `--encre` | `#1B2140` | texte, pied de page | 14,56 sur papier |
| `--encre-douce` | `#4E5470` | texte secondaire | 6,89 sur papier |
| `--grenade` | `#8E1B2E` | boutons, liens, prix | 8,30 sur papier ; blanc dessus 8,95 |
| `--grenade-fonce` | `#6B1322` | survol des boutons | blanc dessus 12,06 |
| `--or` | `#B8862B` | **décor seulement** (filets, ruban, étoiles) | 3,01 : jamais pour du texte sur fond clair |
| `--or-texte` | `#8A6118` | petit texte doré (étiquettes) | 5,12 sur papier |
| `--or` sur `--encre` | | texte doré du pied de page | 4,84 |
| `--ligne` | `#E6DCC8` | bordures | — |
| `--succes` | `#1E6B47` | stock disponible, commande passée | 6,00 |
| `--erreur` | `#B42318` | erreurs de formulaire | 6,57 sur carte |

## Typographie

- Latin : **Fraunces** (titres, serif chaleureuse) + **Figtree** (texte).
- Arabe : **Reem Kufi** (titres) + **Almarai** (texte).
- Corps 16 px minimum, interligne 1,5 (1,7 en arabe).

## Règles

- Mobile d'abord (375 px), puis 768 / 1024 / 1440. Aucun défilement horizontal.
- Cibles tactiles de 44 px minimum ; focus visible ; `prefers-reduced-motion` respecté.
- Icônes SVG (jamais d'émoji). Bascule RTL par propriétés CSS logiques.
- Mouvement discret : fondu de 300 ms au défilement, rien d'autre.
- Ce qui ne s'affiche jamais : avis clients, « meilleures ventes » inventés, compte à rebours factice.
