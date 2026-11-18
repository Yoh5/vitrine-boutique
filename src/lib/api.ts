/**
 * Accès à la base par son API REST (PostgREST).
 * En local : PostgREST dans Docker (http://localhost:54321).
 * En ligne : Supabase (https://<projet>.supabase.co/rest/v1 + clé publique « anon »).
 * Même API, mêmes appels : seules les deux variables changent.
 */
const BASE = (import.meta.env.PUBLIC_API_URL ?? 'http://localhost:54321').replace(/\/$/, '');
const CLE = import.meta.env.PUBLIC_API_KEY ?? '';

function entetes(): Record<string, string> {
  const h: Record<string, string> = { 'Content-Type': 'application/json' };
  if (CLE) { h.apikey = CLE; h.Authorization = `Bearer ${CLE}`; }
  return h;
}

export type Nom = { fr: string; ar: string; en: string };
export type Produit = {
  id: number; slug: string; categorie: string; nom: Nom; description: Partial<Nom>;
  prix_dh: number; stock: number;
};
export type Zone = { id: number; ville: string; nom: Nom; frais_dh: number; delai: string; livraison_offerte_des: number | null };
export type Ligne = { produit_id: number; quantite: number };
export type Calcul = {
  lignes: { produit_id: number; quantite: number; prix: number }[];
  sous_total: number; remise: number; frais: number; total: number; delai: string;
  livraison_offerte_des: number | null; code: string | null;
};

/** Erreur métier renvoyée par la base : `code` est la clé à traduire (stock_insuffisant…). */
export class ErreurBoutique extends Error {
  constructor(public code: string) { super(code); }
}

async function lire<T>(chemin: string): Promise<T> {
  const r = await fetch(`${BASE}/${chemin}`, { headers: entetes() });
  if (!r.ok) throw new Error(`API ${r.status} sur ${chemin}`);
  return r.json();
}

async function appeler<T>(fonction: string, corps: object): Promise<T> {
  let r: Response;
  try {
    r = await fetch(`${BASE}/rpc/${fonction}`, { method: 'POST', headers: entetes(), body: JSON.stringify(corps) });
  } catch {
    throw new ErreurBoutique('reseau');
  }
  const json = await r.json().catch(() => null);
  if (!r.ok) throw new ErreurBoutique(json?.code === 'P0001' && json?.message ? json.message : 'reseau');
  return json as T;
}

export const produits = () => lire<Produit[]>('produits?select=id,slug,categorie,nom,description,prix_dh,stock&order=id');
export const zones = () => lire<Zone[]>('zones?select=*&order=id');
export const stocks = () => lire<{ id: number; stock: number }[]>('produits?select=id,stock');

export const apercu = (panier: Ligne[], zone: number, code: string | null) =>
  appeler<Calcul>('apercu_commande', { p_panier: panier, p_zone_id: zone, p_code: code });

export const commander = (panier: Ligne[], zone: number, code: string | null,
                          nom: string, telephone: string, adresse: string) =>
  appeler<{ numero: string; total: number; delai: string }>('passer_commande', {
    p_panier: panier, p_zone_id: zone, p_code: code, p_nom: nom, p_telephone: telephone, p_adresse: adresse,
  });

export const suivre = (numero: string, telephone: string) =>
  appeler<null | {
    numero: string; statut: string; cree_le: string; total: number; ville: string; delai: string;
    lignes: { nom: Nom; quantite: number }[];
  }>('suivre_commande', { p_numero: numero, p_telephone: telephone });
