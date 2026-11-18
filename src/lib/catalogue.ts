import photosJson from '../data/photos.json';
import { CATEGORIES, RAYON, type Categorie } from '../i18n/ui';
import type { Produit } from './api';

export type Photo = { fichier: string; titre: string; auteur: string; licence: string; source: string };
const PHOTOS = photosJson as Record<string, Photo>;
export const photo = (slug: string): Photo | undefined => PHOTOS[slug];
export const toutesLesPhotos = () => Object.entries(PHOTOS);

/** Code de case : lettre du rayon + rang dans le rayon (A-01, B-03…). Stable : dérivé de l'ordre des identifiants. */
export function codes(tous: Produit[]): Record<number, string> {
  const out: Record<number, string> = {};
  for (const c of CATEGORIES) {
    tous.filter((p) => p.categorie === c).sort((a, b) => a.id - b.id)
      .forEach((p, i) => { out[p.id] = `${RAYON[c as Categorie]}-${String(i + 1).padStart(2, '0')}`; });
  }
  return out;
}

export const SEUIL_RARE = 3;

/** Espace insécable entre un nombre et son unité : « 250 g » ne se coupe jamais. */
export const insecable = (s: string) => s.replace(/(\d) (ml|g|kg|مل|غ)(?=$|[\s,.])/g, '$1\u00a0$2');
