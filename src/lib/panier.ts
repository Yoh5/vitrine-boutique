/** Panier du visiteur, gardé dans le navigateur. Il ne contient que des identifiants et des quantités :
 *  aucun prix n'est stocké ici, c'est la base qui compte. */
import type { Ligne } from './api';

const CLE = 'darhdiya:panier';
const EVT = 'darhdiya:panier';

export function lirePanier(): Ligne[] {
  try {
    const v = JSON.parse(localStorage.getItem(CLE) ?? '[]');
    return Array.isArray(v) ? v.filter((l) => Number.isInteger(l?.produit_id) && Number.isInteger(l?.quantite) && l.quantite > 0) : [];
  } catch {
    return [];
  }
}

function ecrire(p: Ligne[]) {
  localStorage.setItem(CLE, JSON.stringify(p));
  window.dispatchEvent(new CustomEvent(EVT, { detail: p }));
}

export function quantite(id: number): number {
  return lirePanier().find((l) => l.produit_id === id)?.quantite ?? 0;
}

export function poser(id: number, n: number) {
  const p = lirePanier();
  const l = p.find((x) => x.produit_id === id);
  if (l) l.quantite = Math.min(20, l.quantite + n);
  else p.push({ produit_id: id, quantite: Math.min(20, n) });
  ecrire(p.filter((x) => x.quantite > 0));
}

export function fixer(id: number, n: number) {
  ecrire(lirePanier().map((l) => (l.produit_id === id ? { ...l, quantite: Math.max(0, Math.min(20, n)) } : l)).filter((l) => l.quantite > 0));
}

export function vider() { ecrire([]); }

export function surChangement(f: (p: Ligne[]) => void) {
  window.addEventListener(EVT, (e) => f((e as CustomEvent<Ligne[]>).detail));
  window.addEventListener('storage', (e) => { if (e.key === CLE) f(lirePanier()); });
}

export const nbArticles = (p: Ligne[]) => p.reduce((s, l) => s + l.quantite, 0);
