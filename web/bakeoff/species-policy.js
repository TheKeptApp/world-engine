import {stableRandom} from './stable-random.js';
const form=k=>/Pyramidal|Upright|Oval/.test(k)?'oval':/Vase|Open|Spreading/.test(k)?'spreading':k==='conifer'?'conifer':'broad';
export function speciesFor(inst,kind,pack,region,data){
 const f=data.foliageSeasons,known=pack.species.find(s=>s.id===inst.species);if(known)return known;
 const ids=[...new Set(pack.cities.find(c=>c.id===region).mix.map(m=>f.species[m.id]?m.id:f.nearest[m.id]).filter(Boolean))];
 let pool=ids.filter(id=>form(f.species[id].kind||'')===form(kind));
 if(!pool.length&&kind==='conifer'){const row=data.vegetation[data.vegetationRegions[region].slots.conifer1];return {id:region+'-generic-conifer',crownKind:'conifer',evergreen:true,bark:row.branches,seasonColours:{summer:row.colours[1]}};}
 if(!pool.length)throw Error('No P2 species fallback for '+region+'/'+kind);
 const rng=stableRandom(inst.id,0),id=pool[Math.floor(rng()*pool.length)];return pack.species.find(s=>s.id===id);
}
