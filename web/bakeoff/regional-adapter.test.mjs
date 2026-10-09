import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {regionalAdapter} from './regional-adapter.mjs';
import {phenology} from './phenology.js';
import {speciesFor} from './species-policy.js';
import {resolveAtmosphere} from './atmosphere.js';
const read=async p=>JSON.parse(await readFile(p));
const data={haze:await read('web/bakeoff/data/haze-values.json'),fullHaze:await read('docs/proposals/haze-visibility-v1/values.json'),foliage:await read('docs/proposals/foliage-seasons-v1/foliage-values.json'),p2:await read('web/bakeoff/data/p2-crowns.json')},before=JSON.stringify(data);
const input={id:'test-region',climateRegion:'southeast-inland',speciesRegion:'atlanta',latitude:34.8475};
const a=regionalAdapter(input,data),b=regionalAdapter(input,data);
assert.deepEqual(a,b);assert.equal(JSON.stringify(data),before);
assert.deepEqual(a.haze.regions.slice(0,2),data.haze.regions);
for(const region of ['chicago','denver'])for(const date of ['2026-01-15','2026-07-15','2026-10-15'])assert.deepEqual(phenology(date,region,a.p2),phenology(date,region,data.p2));
assert.deepEqual(phenology('2026-10-15',input.id,a.p2).weights,[0,1,0,0]);
for(const kind of ['treeBroad','treeOval','treeSpreading','conifer'])for(let i=0;i<30;i++){
 const s=speciesFor({id:String(i)},kind,a.foliage,input.id,a.p2);assert(s);assert(a.p2.foliageSeasons.species[s.id].kind);assert.equal(s, speciesFor({id:String(i)},kind,a.foliage,input.id,a.p2));
}
const state=resolveAtmosphere(a.haze,input.climateRegion,{atmosphereSeason:'summer',skyState:'clear',timeOfDay:'day'});assert.equal(state.visibilityKm,25);
assert.throws(()=>regionalAdapter({...input,climateRegion:'pending'},data),/Approved/);
assert.throws(()=>regionalAdapter({...input,latitude:NaN},data),/latitude/);
// Same climate/species inputs at a different latitude never create new palette values.
const c=regionalAdapter({...input,latitude:36},data);assert.deepEqual(c.foliage,a.foliage);
console.log('PASS regional adapter: immutable established regions, deterministic proxies, all exported forms, approved MOR, explicit unknown phenology, no pending fallback.');
