// CPU geometry/material tests only; no browser, capture, score or GPU timing.
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {load,current,T,data,pack,phenology,canonical,equalGeometry,world} from './foliage-exp1.test.mjs';
const base='855babe';
const before=await load(execFileSync('git',['show',`${base}:web/bakeoff/foliage.js`],{encoding:'utf8'}));
const crown=JSON.parse(await readFile('docs/proposals/crown-silhouettes-v2/values.json'));
const elm=pack.species.find(s=>s.id==='ulmus_americana'),state=phenology('2026-10-08','denver',data);
for(const x of [undefined,null,'off'])assert.equal(current.crownV2Mode(x),false);
for(const x of ['','on'])assert.equal(current.crownV2Mode(x),'standard');
assert.throws(()=>current.crownV2Mode('bad'));
let identities=0;
const species=pack.species.filter(s=>data.foliageSeasons.species[s.id]);species.push({id:'chicago-generic-conifer',crownKind:'conifer',evergreen:true,bark:'#796B57',seasonColours:{summer:'#476851'}});
for(const region of ['denver','chicago'])for(const date of ['2026-01-08','2026-05-15','2026-07-08','2026-10-08'])for(const s of species)for(const lod of [0,1,2,3]){
 const st=phenology(date,region,data),a=current.build(s,lod,st,data),b=before.build(s,lod,st,data);equalGeometry(a,b);a.dispose();b.dispose();identities++;
}
const a=world(),b=world();for(const w of [a,b])w.lodGroups[0].instances.forEach(i=>i.species='ulmus_americana');
current.applySpecies(a,pack,.92,'denver',state,data,'off',null);before.applySpecies(b,pack,.92,'denver',state,data,'off');
a.updateLODs(new T.Vector3());b.updateLODs(new T.Vector3());
assert.deepEqual(a.lodGroups.map(g=>g.instances),b.lodGroups.map(g=>g.instances));
for(let i=0;i<a.lodGroups.length;i++)for(let l=0;l<4;l++){equalGeometry(a.lodGroups[i].levels[l].geometry,b.lodGroups[i].levels[l].geometry);assert.equal(canonical(a.lodGroups[i].levels[l].material),canonical(b.lodGroups[i].levels[l].material));}
const costs=[];
for(let seed=0;seed<4;seed++){
 const row=[];
 for(let lod=0;lod<3;lod++){
  const args=[elm,lod,state,data,crown,'elm-v2/'+seed],a=current.buildElmV2(...args),b=current.buildElmV2(...args);equalGeometry(a,b);
  const counts=[crown.content.construction.nearPrimaryLobes,crown.content.construction.middlePrimaryLobes,crown.content.construction.farPrimaryLobes][lod];assert(a.userData.crownV2.primaryLobes>=counts[0]&&a.userData.crownV2.primaryLobes<=counts[1]);
  const lobes=a.userData.crownV2.leafLobes,branches=a.userData.crownV2.primaryLobes,sides=[7,5,3][lod];
  const expected=(1+2*branches)*sides*2+lobes*[80,80,8][lod];assert.equal(a.index.count/3,expected);
  assert(a.attributes.position.array.every(Number.isFinite));row.push({level:['near','middle','far'][lod],triangles:expected,draws:1,lobes});
 }
 assert(row[0].triangles>row[1].triangles&&row[1].triangles>row[2].triangles);for(const r of row)r.shadowTriangles=row[2].triangles;costs.push(row);
}
const x=current.buildElmV2(elm,0,state,data,crown,'a'),y=current.buildElmV2(elm,0,state,data,crown,'b');assert.notDeepEqual(x.attributes.position.array,y.attributes.position.array);
for(const [px,l]of [[21,0],[10,1],[5,2]])assert.equal(current.crownV2Level(px,crown.lod),l);
assert.equal(current.crownV2Level(19,crown.lod,0),0);assert.equal(current.crownV2Level(17,crown.lod,0),1);
await mkdir('web/bakeoff/evidence/crown-v2',{recursive:true});await writeFile('web/bakeoff/evidence/crown-v2/crowns.json',JSON.stringify({base,identityCases:identities,costs,note:'CPU topology counts; one crown per draw upper cost, scene uses instancing. Existing shadow policy selects far LOD2. No GPU measurements.'},null,2)+'\n');
console.log('PASS: crownV2 absent/off identity '+identities+' cases + material graphs; seeded determinism; LOD counts/thresholds');console.log(JSON.stringify(costs[0]));

for(const target of [75,217]){
 const entries=Array.from({length:100},(_,i)=>({key:String(i),distance:i,costs:[2606,910,66],desired:0}));
 const a=current.allocateCrownBudget(entries,target),b=current.allocateCrownBudget([...entries].reverse(),target);
 assert.equal(a.spent,b.spent);assert.deepEqual([...a.levels].sort(),[...b.levels].sort());assert(a.spent<=target*100);
 for(let i=1;i<100;i++)assert(a.levels.get(String(i))>=a.levels.get(String(i-1)),'nearer equal-cost crown has priority');
}
assert.equal(current.crownV2Mode('floor'),'floor');
console.log('PASS: nearest-first standard/floor cap, stable order, mode defaults');

// Budget decisions survive real instancing, repeated updates and view movement.
for(const tier of ['standard','floor']){
 const w=world();w.lodGroups[0].instances=Array.from({length:100},(_,i)=>({id:'elm-'+i,position:[i*2,0,0],yaw:0,scale:20,species:'ulmus_americana',stretch:[1,1]}));
 const camera=new T.PerspectiveCamera(35,1,.2,10000);camera.position.set(0,2,0);
 current.applySpecies(w,pack,.92,'denver',state,data,'off',{pack:crown,tier,camera,height:()=>585});
 for(const x of [0,0,100]){camera.position.x=x;w.updateLODs(camera.position);
  let count=0,triangles=0;const origins=[];
  for(const g of w.lodGroups)for(let lod=0;lod<4;lod++){const m=g.levels[lod];count+=m.count;triangles+=m.count*g.triangles[lod];for(let i=0;i<m.count;i++)origins.push(m.geometry.attributes.instOrigin.getX(i));}
  assert.equal(count,100);assert.equal(new Set(origins).size,100);assert.equal(triangles,w.crownBudget.triangles);assert(triangles<=100*(tier==='floor'?75:217));assert.equal(w.treeTriangles,triangles);
 }
}
console.log('PASS: actual pooled instance counts/origins, nearest allocation and repeated/moving-camera updates');
