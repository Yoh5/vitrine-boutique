/**
 * Espace du gérant : connexion (Supabase Auth) et appels aux fonctions de la base.
 * La session vit dans le navigateur ; chaque appel porte le jeton, et c'est la base qui décide
 * (rôle gérant ou démo, données masquées, circuit des statuts, stock sans écrasement).
 */
import type { Nom } from './api';

const API = (import.meta.env.PUBLIC_API_URL ?? 'http://localhost:54321').replace(/\/$/, '');
const CLE = import.meta.env.PUBLIC_API_KEY ?? '';
// Supabase : https://<projet>.supabase.co/rest/v1 -> https://<projet>.supabase.co/auth/v1
const AUTH = API.replace(/\/rest\/v1$/, '/auth/v1');
const CLE_SESSION = 'darhdiya:session';

export type Session = { access_token: string; refresh_token: string; expires_at: number; email: string };

export class ErreurGerant extends Error {
  constructor(public code: string) { super(code); }
}

export function lireSession(): Session | null {
  try {
    const s = JSON.parse(localStorage.getItem(CLE_SESSION) ?? 'null');
    return s && typeof s.access_token === 'string' ? s : null;
  } catch { return null; }
}
function ecrireSession(s: Session | null) {
  try { s ? localStorage.setItem(CLE_SESSION, JSON.stringify(s)) : localStorage.removeItem(CLE_SESSION); } catch { /* navigation privée */ }
}

async function auth(chemin: string, corps: object): Promise<Session> {
  let r: Response;
  try {
    r = await fetch(`${AUTH}/${chemin}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', apikey: CLE }, body: JSON.stringify(corps),
    });
  } catch { throw new ErreurGerant('reseau'); }
  const j = await r.json().catch(() => null);
  if (!r.ok || !j?.access_token) {
    throw new ErreurGerant(r.status === 400 || r.status === 401 ? 'identifiants' : r.status === 429 ? 'trop_d_essais' : 'reseau');
  }
  const s: Session = {
    access_token: j.access_token, refresh_token: j.refresh_token,
    expires_at: j.expires_at ?? Math.floor(Date.now() / 1000) + (j.expires_in ?? 3600),
    email: j.user?.email ?? '',
  };
  ecrireSession(s);
  return s;
}

export const connecter = (email: string, motDePasse: string) =>
  auth('token?grant_type=password', { email: email.trim(), password: motDePasse });

export async function deconnecter() {
  const s = lireSession();
  ecrireSession(null);
  if (s) {
    fetch(`${AUTH}/logout`, { method: 'POST', headers: { apikey: CLE, Authorization: `Bearer ${s.access_token}` } })
      .catch(() => {});
  }
}

async function jetonValide(): Promise<string> {
  const s = lireSession();
  if (!s) throw new ErreurGerant('non_connecte');
  if (s.expires_at - 60 > Date.now() / 1000) return s.access_token;
  try {
    return (await auth('token?grant_type=refresh_token', { refresh_token: s.refresh_token })).access_token;
  } catch {
    ecrireSession(null);
    throw new ErreurGerant('non_connecte');
  }
}

async function rpc<T>(fonction: string, corps: object = {}): Promise<T> {
  const jeton = await jetonValide();
  let r: Response;
  try {
    r = await fetch(`${API}/rpc/${fonction}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', apikey: CLE, Authorization: `Bearer ${jeton}` },
      body: JSON.stringify(corps),
    });
  } catch { throw new ErreurGerant('reseau'); }
  const j = await r.json().catch(() => null);
  if (r.status === 401) { ecrireSession(null); throw new ErreurGerant('non_connecte'); }
  if (!r.ok) throw new ErreurGerant(j?.code === 'P0001' && j?.message ? j.message : 'reseau');
  return j as T;
}

// ---------------------------------------------------------------- types renvoyés par la base

export type Statut = 'recue' | 'confirmee' | 'expediee' | 'livree' | 'annulee';
export type Moi = { role: 'gerant' | 'demo'; nom: string };
export type Tableau = {
  jour: string;
  aujourdhui: { commandes: number; chiffre: number; panier_moyen: number };
  a_traiter: number; a_expedier: number; ruptures: number; stock_bas: number;
  semaine: { jour: string; commandes: number; chiffre: number }[];
};
export type ProduitStock = {
  id: number; slug: string; nom: Nom; categorie: string; prix: number; stock: number; actif: boolean; vendus_30j: number;
};
export type Commande = {
  numero: string; statut: Statut; cree_le: string; nom: string; telephone: string; adresse: string | null;
  ville: string; zone: Nom; sous_total: number; remise: number; frais: number; total: number;
  code_promo: string | null; articles: number;
};
export type DetailCommande = Commande & {
  lignes: { produit_id: number; slug: string; nom: Nom; quantite: number; prix: number }[];
  suivantes: Statut[];
  historique: { quand: string; qui: string; avant: Statut; apres: Statut; motif: string | null }[];
};
export type EntreeJournal = {
  quand: string; qui: string; action: 'statut' | 'stock' | 'vente'; cible: string;
  avant: unknown; apres: unknown; motif: string | null;
};

export const moi = () => rpc<Moi>('moi');
export const tableau = () => rpc<Tableau>('tableau_de_bord');
export const stock = () => rpc<ProduitStock[]>('stock_gerant');
export const commandes = (statut: Statut | null, recherche: string | null) =>
  rpc<Commande[]>('liste_commandes', { p_statut: statut, p_recherche: recherche, p_limite: 200 });
export const detail = (numero: string) => rpc<DetailCommande>('detail_commande', { p_numero: numero });
export const changerStatut = (numero: string, statut: Statut, motif: string | null) =>
  rpc<DetailCommande>('changer_statut', { p_numero: numero, p_statut: statut, p_motif: motif });
export const ajusterStock = (id: number, vu: number, nouveau: number, motif: string) =>
  rpc<{ id: number; stock: number }>('ajuster_stock', { p_produit_id: id, p_vu: vu, p_nouveau: nouveau, p_motif: motif });
export const mettreEnVente = (id: number, actif: boolean) =>
  rpc<{ id: number; actif: boolean }>('mettre_en_vente', { p_produit_id: id, p_actif: actif });
export const journal = () => rpc<EntreeJournal[]>('journal', { p_limite: 100 });

// ---------------------------------------------------------------- textes

export const STATUTS: Record<Statut, string> = {
  recue: 'Reçue', confirmee: 'Confirmée', expediee: 'Expédiée', livree: 'Livrée', annulee: 'Annulée',
};
/** Libellé du bouton qui fait passer une commande au statut donné. */
export const ACTIONS: Record<Statut, string> = {
  recue: '', confirmee: 'Confirmer', expediee: 'Marquer expédiée', livree: 'Marquer livrée', annulee: 'Annuler',
};

export const ERREURS: Record<string, string> = {
  identifiants: 'E-mail ou mot de passe incorrect.',
  trop_d_essais: 'Trop d’essais. Attendez une minute avant de réessayer.',
  reseau: 'La base ne répond pas. Vérifiez la connexion et réessayez.',
  non_connecte: 'Votre session a expiré. Reconnectez-vous.',
  acces_refuse: 'Ce compte n’a pas accès à l’arrière-boutique.',
  stock_modifie: 'Une vente vient de passer sur ce produit : le stock a changé. Recomptez avant de corriger.',
  stock_invalide: 'Le stock doit être un nombre entre 0 et 9 999.',
  motif_requis: 'Indiquez un motif (3 caractères au moins).',
  motif_trop_long: 'Motif trop long (200 caractères au plus).',
  rien_a_changer: 'Ce chiffre est déjà celui de la réserve.',
  transition_interdite: 'Cette étape n’est plus possible pour cette commande.',
  commande_introuvable: 'Commande introuvable.',
  produit_introuvable: 'Produit introuvable.',
  statut_inconnu: 'Statut inconnu.',
};
export const message = (e: unknown) =>
  ERREURS[e instanceof ErreurGerant ? e.code : 'reseau'] ?? ERREURS.reseau;

export const dh = (n: number) =>
  `${new Intl.NumberFormat('fr-MA', { maximumFractionDigits: 2 }).format(Number(n))} DH`;

const FMT_JOUR = new Intl.DateTimeFormat('fr-FR', { timeZone: 'Africa/Casablanca', weekday: 'short', day: 'numeric', month: 'short' });
const FMT_HEURE = new Intl.DateTimeFormat('fr-FR', { timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit' });
const FMT_CLE = new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Casablanca' });
/** « 14:05 » aujourd'hui, « hier 09:12 », sinon « mar. 17 nov. 09:12 » (heure de Casablanca). */
export function quand(iso: string): string {
  const d = new Date(iso);
  const jour = FMT_CLE.format(d);
  const auj = FMT_CLE.format(new Date());
  const hier = FMT_CLE.format(new Date(Date.now() - 864e5));
  const h = FMT_HEURE.format(d);
  if (jour === auj) return `aujourd’hui ${h}`;
  if (jour === hier) return `hier ${h}`;
  return `${FMT_JOUR.format(d)} ${h}`;
}

/** Code de case (A-01) : même calcul que la boutique, sur l'ordre du catalogue par rayon. */
export const RAYONS: [string, string, string][] = [
  ['soins', 'A', 'Soins et hammam'], ['the', 'B', 'Thé'], ['poterie', 'C', 'Poterie et cuivre'],
  ['textile', 'D', 'Cuir et textile'], ['coffrets', 'E', 'Coffrets'],
];
