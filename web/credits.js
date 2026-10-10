// UI only. Wording is copied verbatim from A11 docs/legal/credits-draft.md.
// Conditional notices come from the displayed package, never a research-source inventory.
export function applicableCredits(manifest, catalog) {
  const sourceText = JSON.stringify(manifest?.sources ?? []).toLowerCase();
  return catalog.filter(c => c.id === 'osm' || c.matches.some(key => sourceText.includes(key)));
}
export async function mountCredits({worldBase = new URLSearchParams(location.search).get('world') || 'world/', host = document.body} = {}) {
  if (document.getElementById('world-credits')) return;
  const response = await fetch(new URL('credits.json', import.meta.url));
  if (!response.ok) throw Error('Data credits unavailable');
  const catalog = await response.json();
  const root = document.createElement('div'); root.id = 'world-credits';
  const style = document.createElement('style');
  style.textContent = `#world-credits{position:fixed;left:8px;bottom:calc(env(safe-area-inset-bottom) + 8px);z-index:1000;font:14px/1.5 -apple-system,system-ui,sans-serif;color:#111;max-width:calc(100vw - 16px);touch-action:manipulation;user-select:text}#world-credits button{font:inherit;min-height:44px;padding:8px 12px;border:1px solid #777;border-radius:6px;background:#fff;color:#111}#world-credits dialog{box-sizing:border-box;width:min(560px,calc(100vw - 24px));max-height:calc(100dvh - 24px);padding:16px;border:1px solid #777;border-radius:8px;overflow:auto;overscroll-behavior:contain;touch-action:pan-y;font:14px/1.5 -apple-system,system-ui,sans-serif;color:#111;background:#fff}#world-credits dialog::backdrop{background:rgba(0,0,0,.3)}#world-credits a{color:#0645ad;overflow-wrap:anywhere}#world-credits p{margin:12px 0}#world-credits h2{font-size:20px}#world-credits .close{float:right}#world-credits .osm{display:block;background:#fff;padding:2px 6px;border-radius:4px;font-size:12px}`;
  const button = document.createElement('button'); button.textContent = 'About / credits'; button.setAttribute('aria-haspopup','dialog');
  const osm = document.createElement('a'); osm.className='osm'; osm.textContent=catalog[0].paragraphs[0][0].text; osm.href=catalog[0].paragraphs[0][0].url; osm.target='_blank'; osm.rel='noopener';
  const dialog = document.createElement('dialog'); dialog.setAttribute('aria-labelledby','world-credits-title');
  const close = document.createElement('button'); close.className='close'; close.textContent='Close'; close.addEventListener('click',()=>dialog.close());
  const title=document.createElement('h2');title.id='world-credits-title';title.textContent='Data credits';
  const content=document.createElement('div');
  function fill(manifest) {
    content.replaceChildren();
    for(const entry of applicableCredits(manifest,catalog)) for(const paragraph of entry.paragraphs) {
      const p=document.createElement('p');for(const part of paragraph){const node=document.createElement(part.url?'a':'span');node.textContent=part.text;if(part.url){node.href=part.url;node.target='_blank';node.rel='noopener';}p.append(node);}content.append(p);
    }
  }
  fill(null); dialog.append(close,title,content); button.addEventListener('click',()=>{dialog.showModal();close.focus();});dialog.addEventListener('close',()=>button.focus());
  root.append(style,button,osm,dialog);host.append(root);
  // A failed package lookup keeps OSM reachable and visibly reports incomplete notices.
  try {const r=await fetch(new URL('world.json',new URL(worldBase,location.href)));if(!r.ok)throw Error('package');fill(await r.json());root.dataset.status='loaded';}
  catch {root.dataset.status='incomplete';const p=document.createElement('p');p.textContent='Source credits unavailable.';content.append(p);}
  return root;
}
if (typeof document !== 'undefined' && document.querySelector('script[data-world-credits]')) mountCredits().catch(error=>console.error(error));
