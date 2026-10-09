// No DOM, browser, GPU render, capture or grading. Baseline is immutable Git data.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import vm from 'node:vm';
const baseline='fc439aadce9a560a6f46fd1c5a81d972ce5e32d6';
const here=fileURLToPath(new URL('.',import.meta.url));
const assets=process.env.WORLDENGINE_ASSETS;if(!assets)throw Error('Set WORLDENGINE_ASSETS to the checkout containing installed three.js and packs');
const three=resolve(assets,'web/node_modules/three');
const url=p=>pathToFileURL(p).href;
const source=await readFile(new URL('./foliage.js',import.meta.url),'utf8');
const old=execFileSync('git',['show',`${baseline}:web/bakeoff/foliage.js`],{encoding:'utf8'});
const dataURL=s=>'data:text/javascript;base64,'+Buffer.from(s).toString('base64');
async function load(s,tsl){
 s=s.replace(/from (['"])([^'"]+)\1/g,(_,quote,name)=>{
  const target=name==='three/webgpu'?url(resolve(three,'build/three.webgpu.js')):name==='three/tsl'?(tsl||url(resolve(three,'build/three.tsl.js'))):name.startsWith('three/addons/')?url(resolve(three,'examples/jsm',name.slice(13))):url(resolve(here,name));
  return 'from '+JSON.stringify(target);
 });
 return import(dataURL(s));
}
const current=await load(source),legacy=await load(old.replace('function build(','export function build('));
const T=await import(url(resolve(three,'build/three.webgpu.js')));
const data=JSON.parse(await readFile(new URL('./data/p2-crowns.json',import.meta.url)));
const pack=JSON.parse(await readFile(resolve(assets,'docs/proposals/foliage-seasons-v1/foliage-values.json')));
const {phenology}=await import('./phenology.js');
for(const value of [undefined,null,'off','remove','layered'])assert.equal(current.foliageExp1Mode(value),value??'off');
for(const value of ['',false,0,'OFF','bad','../layered'])assert.throws(()=>current.foliageExp1Mode(value),/Invalid foliageExp1/);

// Evaluate the actual material-node recipe with scalar/vector arithmetic instead
// of a GPU. This tests production operations, not a second copy of its formula.
const arithmetic=dataURL(`
const ctx={};export function inputs(x){Object.assign(ctx,x);}
export function value(x){return {value:x,mul(b){return value(binary(x,b.value??b,(a,b)=>a*b));},add(b){return value(binary(x,b.value??b,(a,b)=>a+b));}};}
function binary(a,b,f){return Array.isArray(a)?a.map((x,i)=>f(x,Array.isArray(b)?b[i]:b)):f(a,b);}
export const attribute=name=>value(ctx[name]);export const float=value;
export const clamp=(x,a,b)=>value(Math.max(a,Math.min(b,x.value)));
export function smoothstep(a,b,x){const t=Math.max(0,Math.min(1,(x.value-a)/(b-a)));return value(t*t*(3-2*t));}
export function mix(a,b,t){return value(binary(a.value,b.value,(x,y)=>x+(y-x)*t.value));}
`);
const numeric=await load(source,arithmetic),ops=await import(arithmetic);
const close=(a,b)=>assert.ok(Math.abs(a-b)<=.0001,`${a} != ${b}`);
for(const [A,t,A1,M]of [[.5,0,.65,.94],[.65,0,.65,.94],[.75,.198251,.719388,.951895],[.825,.5,.825,.97],[.9,.801749,.930612,.988105],[1,1,1,1]]){
 ops.inputs({exp1AO:A,exp1Mask:1});const m={colorNode:ops.value([1,.5,.25]),aoNode:null};numeric.applyFoliageExp1(m,'layered');close(m.aoNode.value,A1);close((m.aoNode.value-.65)/.35,t);m.colorNode.value.forEach((x,i)=>close(x,[1,.5,.25][i]*M));
 for(const mode of [undefined,'off','remove']){const color=ops.value([.1,.2,.3]),control={colorNode:color,aoNode:null};numeric.applyFoliageExp1(control,mode);assert.equal(control.colorNode,color);assert.equal(control.aoNode,null);}
 ops.inputs({exp1AO:A,exp1Mask:0});const bark=[.1,.2,.3],control={colorNode:ops.value(bark)};numeric.applyFoliageExp1(control,'layered');assert.deepEqual(control.colorNode.value,bark);assert.equal(control.aoNode.value,1);
}
// P2 adapter witnesses: top/underside and lobe overlap, including far-shell no overlap.
const shape={crown:[0,0,0],radii:[1,1,1]};
close(current.crownExp1AO([0,1,0],[0,1,0],shape,[]),1);
close(current.crownExp1AO([0,1,0],[0,-1,0],shape,[]),.75);
close(current.crownExp1AO([0,-1,0],[0,1,0],shape,[]),.66);
close(current.crownExp1AO([0,1,0],[0,-1,0],shape,[[[0,1,0],1]]),.75*.86);

function equalGeometry(a,b){
 assert.deepEqual(a.index.array,b.index.array,'index/topology changed');
 for(const [name,attribute]of Object.entries(b.attributes))assert.deepEqual(a.attributes[name].array,attribute.array,name+' changed');
 assert.deepEqual(a.boundingBox,b.boundingBox);assert.deepEqual(a.boundingSphere,b.boundingSphere);
}
let cases=0,bytes=0;
const species=pack.species.filter(s=>data.foliageSeasons.species[s.id]);
species.push({id:'chicago-generic-conifer',crownKind:'conifer',evergreen:true,bark:'#796B57',seasonColours:{summer:'#476851'}});
for(const region of ['denver','chicago'])for(const date of ['2026-01-08','2026-05-15','2026-07-08','2026-10-08'])for(const s of species)for(const lod of [0,1,2,3]){
 const state=phenology(date,region,data),a=current.build(s,lod,state,data),b=legacy.build(s,lod,state,data);equalGeometry(a,b);
 const eligible=!s.evergreen&&!!data.shapes[s.crownKind||data.foliageSeasons.species[s.id]?.kind]&&lod<3;
 const {exp1AO:ao,exp1Mask:mask,leafMask}=a.attributes;
 for(let i=0;i<mask.count;i++){assert.equal(mask.getX(i),eligible&&leafMask.getX(i)===1?1:0);assert(Number.isFinite(ao.getX(i)));if(!mask.getX(i))assert.equal(ao.getX(i),1);}
 bytes+=ao.array.byteLength+mask.array.byteLength;cases++;a.dispose();b.dispose();
}
// Compare real Three node graphs and instance data to today's immutable code.
function canonical(m){const ids=new Map();return JSON.stringify(m.toJSON(),(_,v)=>typeof v==='string'?v.replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi,id=>{if(!ids.has(id))ids.set(id,'id'+ids.size);return ids.get(id);}):v);}
function world(){return {root:new T.Group(),runtime:{lodDistances:[20,60,150]},updateLODs(){},lodGroups:[{isTree:true,key:'fixture',kind:'treeRounded',instances:[{id:'stable-1',position:[0,0,0],yaw:.5,scale:10,species:'acer_platanoides',stretch:[1,1]},{id:'stable-2',position:[30,0,0],yaw:.3,scale:8,species:'acer_platanoides',stretch:[1,1]}],levels:Array.from({length:4},()=>new T.Mesh())}]};}
const state=phenology('2026-10-08','denver',data),reference=world();legacy.applySpecies(reference,pack,.9,'denver',state,data);reference.updateLODs(new T.Vector3());
for(const mode of [undefined,'off','remove','layered']){
 const w=world();current.applySpecies(w,pack,.9,'denver',state,data,mode);w.updateLODs(new T.Vector3());
 assert.deepEqual(w.lodGroups.map(g=>g.instances),reference.lodGroups.map(g=>g.instances));
 for(let j=0;j<w.lodGroups.length;j++)for(let lod=0;lod<4;lod++){
  const a=w.lodGroups[j].levels[lod],b=reference.lodGroups[j].levels[lod];equalGeometry(a.geometry,b.geometry);
  if(mode!=='layered')assert.equal(canonical(a.material),canonical(b.material),'identity material graph changed');
  assert.equal(a.castShadow,b.castShadow);assert.equal(a.receiveShadow,b.receiveShadow);
 }
}
// The rest of main is byte-identical after removing only flag plumbing.
const v3Plumbing=[" const crownV3=q.get('crownV3')??'off';\n", " if(!['off','standard'].includes(crownV3))throw Error('Invalid crownV3: '+crownV3);\n", " if(crownV3!=='off'&&crownV2)throw Error('Choose one crown experiment');\n", ' let v3=null,v3Module=null;\n', " if(!baseline&&crownV3==='standard'){v3Module=await import('./crown-v3.js');v3=v3Module.installCrownV3(world,camera,()=>renderer.domElement.clientHeight,p2,seasonal,sunDirection);}\n", " if(v3&&q.has('capture')){scene.updateMatrixWorld(true);world.crownV3Report.fragments=v3Module.estimateFragments(v3.groups,camera,renderer.domElement.width,renderer.domElement.height);}\n", "crownV3:!baseline&&crownV3!=='off'?crownV3:false,"];
const withoutV3=v3Plumbing.reduce((s,line)=>{assert(s.includes(line),'missing bounded v3 plumbing');return s.replace(line,'');},await readFile(new URL('./main.js',import.meta.url),'utf8'));
const main=withoutV3.replace(',crownV2Mode','').replace(" const crownV2=crownV2Mode(q.get('crownV2'));\n const crownPack=crownV2?await get('/packs/crown-silhouettes-v2/values.json'):null;\n",'').replace(',crownV2?{pack:crownPack,tier:crownV2,camera,height:()=>renderer.domElement.clientHeight}:null','').replace('crownV2:!baseline&&crownV2,',''),oldMain=execFileSync('git',['show',`${baseline}:web/bakeoff/main.js`],{encoding:'utf8'});
const unchanged=main.replace('applySpecies,foliageExp1Mode','applySpecies').replace(" const foliageExp1=foliageExp1Mode(q.get('foliageExp1'));\n",'').replace('config.region,seasonal,p2,foliageExp1);','config.region,seasonal,p2);').replace("foliageExp1:baseline?'off':foliageExp1,",'');assert.equal(unchanged,oldMain,'non-experiment renderer code changed');
const capture=await readFile(new URL('./capture-once.mjs',import.meta.url),'utf8'),preamble=capture.split('// Runtime capture')[0];
for(const mode of [undefined,'off','remove','layered']){
 const ctx={process:{env:mode===undefined?{}:{FOLIAGE_EXP1:mode}}};vm.runInNewContext(preamble+'\nglobalThis.result={experiment,experimentSuffix,evidenceDirectory};',ctx);
 const r=ctx.result;assert.equal(r.experiment,mode??'off');assert.equal(r.experimentSuffix('baseline',r.experiment),'&baseline');
 for(const tier of ['hero','standard','floor'])assert.equal(r.evidenceDirectory('candidate',tier,r.experiment),`web/bakeoff/evidence/foliage-exp1/${mode??'off'}/${tier}`);
 assert.equal(r.evidenceDirectory('baseline','standard',r.experiment),'web/bakeoff/evidence/baseline');assert.equal(r.experimentSuffix('candidate',r.experiment),'&foliageExp1='+(mode??'off'));
}
for(const mode of ['', 'bad','../layered'])assert.throws(()=>vm.runInNewContext(preamble,{process:{env:{FOLIAGE_EXP1:mode}}}),/Invalid FOLIAGE_EXP1/);
assert(capture.includes("resolved.foliageExp1!==(mode==='baseline'?'off':experiment)"));
console.log(`PASS: spec numeric witnesses; masks/bark/conifer/skyline controls; ${cases} geometry cases byte-identical to ${baseline}; extra attributes ${bytes} bytes across test fixtures`);
console.log('PASS: absent/off/remove real Three material graphs, legacy geometry and instance inputs identical; all other main.js code identical; mode validation/routing verified without browser launch');
console.log('LIMIT: structural render-input identity, not GPU pixel readback; no captures or scores run. Layered shader compilation and visible AO consumption await A3 capture.');

// Approved 66aac35 identity gate: native deciduous slots, not petal-like colour.
for(const kind of ['treeRounded','treePyramidal','treeVase','treeOpen','treeUpright']){
 assert(current.deciduousExp1Identity({evergreen:false},kind));
 for(const lod of [0,1,2])assert(current.crownExp1Eligible({evergreen:false},kind,lod,{leafFraction:1}));
 assert(!current.crownExp1Eligible({evergreen:false},kind,3,{leafFraction:1}));
 assert(!current.crownExp1Eligible({evergreen:false},kind,0,{leafFraction:0}));
 assert(!current.deciduousExp1Identity({evergreen:true},kind));
}
for(const kind of ['flowerBush','bush','conifer','tufts','unknown'])assert(!current.deciduousExp1Identity({evergreen:false},kind));
// Bushes/petals bypass species rebuilding entirely; conifers keep the original
// material graph even in layered mode. Compare real geometry bytes and graphs.
function controls(){
 const w=world();w.lodGroups[0].kind='conifer';
 w.lodGroups[0].instances=w.lodGroups[0].instances.map(i=>({...i,species:undefined}));
 for(const kind of ['bush','flowerBush']){
  const geometry=new T.BoxGeometry(),material=new T.MeshStandardNodeMaterial();
  geometry.setAttribute('_extra',new T.BufferAttribute(new Float32Array(geometry.attributes.position.count*4).fill(.9),4));
  geometry.setAttribute('_paint',new T.BufferAttribute(new Float32Array(geometry.attributes.position.count*4).fill(29),4));
  w.lodGroups.push({isTree:false,kind,instances:[],levels:[new T.Mesh(geometry,material)]});
 }
 return w;
}
function sameBytes(a,b){assert.equal(a.constructor,b.constructor);assert(Buffer.from(a.buffer,a.byteOffset,a.byteLength).equals(Buffer.from(b.buffer,b.byteOffset,b.byteLength)));}
const control=controls();legacy.applySpecies(control,pack,.9,'denver',state,data);control.updateLODs(new T.Vector3());
for(const mode of ['off','remove','layered']){
 const w=controls(),bushes=w.lodGroups.filter(g=>!g.isTree);current.applySpecies(w,pack,.9,'denver',state,data,mode);w.updateLODs(new T.Vector3());
 assert.deepEqual(w.lodGroups.filter(g=>!g.isTree),bushes);
 for(let i=0;i<w.lodGroups.length;i++)for(let j=0;j<w.lodGroups[i].levels.length;j++){
  const a=w.lodGroups[i].levels[j],b=control.lodGroups[i].levels[j];
  sameBytes(a.geometry.index.array,b.geometry.index.array);
  for(const [key,attr]of Object.entries(b.geometry.attributes))sameBytes(a.geometry.attributes[key].array,attr.array);
  assert.equal(canonical(a.material),canonical(b.material),mode+' changed control graph');
  if(w.lodGroups[i].isTree)assert(a.geometry.attributes.exp1Mask.array.every(x=>x===0));
 }
}
console.log('PASS: bush/flower-bush/conifer geometry and material controls byte-identical to pre-experiment baseline in off/remove/layered; GPU pixels not captured');

export {load,current,legacy,T,data,pack,phenology,canonical,equalGeometry,world};
