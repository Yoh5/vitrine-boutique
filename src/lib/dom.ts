/** Petit constructeur d'éléments : tout le texte passe par textContent (les noms viennent de la base). */
type Attrs = Record<string, string | number | boolean | null | undefined | ((e: Event) => void)>;
type Enfant = Node | string | number | null | undefined | false;

export function h<K extends keyof HTMLElementTagNameMap>(tag: K, attrs: Attrs = {}, ...enfants: Enfant[]): HTMLElementTagNameMap[K] {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v === null || v === undefined || v === false) continue;
    if (typeof v === 'function') el.addEventListener(k.replace(/^on/, ''), v as EventListener);
    else if (k === 'class') el.className = String(v);
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, String(v));
  }
  for (const e of enfants) {
    if (e === null || e === undefined || e === false) continue;
    el.append(e instanceof Node ? e : document.createTextNode(String(e)));
  }
  return el;
}

/** SVG d'icône (chaîne de confiance, écrite dans le code) dans un span. */
export function icone(svg: string): HTMLSpanElement {
  const s = document.createElement('span');
  s.className = 'ico';
  s.innerHTML = svg;
  return s;
}
