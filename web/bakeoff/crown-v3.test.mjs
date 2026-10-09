import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {buildCrownV3,crownV3Mode,crownV3Level,ALLOCATIONS} from './crown-v3.js';
const data=JSON.parse(await readFile(new URL('./data/p2-crowns.json',import.meta.url)));
const pack=JSON.parse(await readFile(new URL('../../docs/proposals/foliage-seasons-v1/foliage-values.json',import.meta.url)));
assert.equal(crownV3Mode(),false);assert.equal(crownV3Mode('off'),false);assert.equal(crownV3Mode('standard'),'standard');for(const x of ['','floor','on','invalid'])assert.throws(()=>crownV3Mode(x));
assert.deepEqual([1.99,2,5.99,6,19.99,20].map(crownV3Level),[3,2,2,1,1,0]);
let cases=0;
for(const species of pack.species.filter(s=>!s.evergreen&&data.shapes[data.foliageSeasons.species[s.id]?.kind]))for(let lod=0;lod<4;lod++)for(const seed of ['a','b','c']){
 const a=buildCrownV3(species,lod,{leafFraction:1},data,seed),b=buildCrownV3(species,lod,{leafFraction:1},data,seed);
 assert.equal(a.index.count/3,ALLOCATIONS[lod].reduce((a,b)=>a+b,0));assert(a.userData.crownV3.lobes>=5&&a.userData.crownV3.lobes<=9);
 for(const [name,attr]of Object.entries(a.attributes)){assert.deepEqual(attr.array,b.attributes[name].array);assert([...attr.array].every(Number.isFinite));}
 const n=a.attributes.normal;for(let i=0;i<n.count;i++)assert(Math.abs(Math.hypot(n.getX(i),n.getY(i),n.getZ(i))-1)<1e-5);
 const bare=buildCrownV3(species,lod,{leafFraction:0},data,seed);assert.equal(bare.index.count/3,ALLOCATIONS[lod][0]);cases++;
}
console.log('PASS crown v3 deterministic geometry, allocations, finite smooth normals, bare identity, projected LOD and flag validation:',cases,'cases');
// Integration: conserve identities and seasonal instance colours; cull only
// outside the actual camera frustum, re-evaluate on projection/movement changes.
const {applySpecies}=await import('./foliage.js');
const {installCrownV3,estimateFragments}=await import('./crown-v3.js');
const T=await import('three/webgpu');
const species=pack.species.find(s=>s.id==='ulmus_americana');
const world={root:new T.Group(),runtime:{lodDistances:[20,60,150]},updateLODs(){},lodGroups:[{isTree:true,key:'fixture',kind:'treeVase',instances:Array.from({length:300},(_,i)=>({id:'tree-'+i,position:[i<2?0:10000+i*10,0,-40-i*2],yaw:.2,scale:10,species:species.id,stretch:[1,1]})),levels:Array.from({length:4},()=>new T.Mesh())}]};
const state={date:'2026-10-15',weights:[0,0,1,0],leafFraction:1};
applySpecies(world,pack,.92,'denver',state,data,'off');
const camera=new T.PerspectiveCamera(50,1,.2,20000);camera.position.set(0,10,0);camera.lookAt(0,8,-40);
const {groups}=installCrownV3(world,camera,()=>256,data,state,new T.Vector3(1,1,0).normalize());
world.updateLODs(camera.position);world.root.updateMatrixWorld(true);
assert.equal(world.crownV3Report.trees,300);assert(world.crownV3Report.frustumCulled>0);assert.equal(world.crownV3Report.lodCounts.reduce((a,b)=>a+b,0)+world.crownV3Report.frustumCulled,300);
for(const g of groups)for(const m of g.levels){assert.equal(m.instanceMatrix.count,1001);assert(m.material.depthWrite);assert.equal(m.material.transparent,false);assert.equal(m.material.alphaTest,.5);for(let i=0;i<m.count;i++)assert(Number.isFinite(m.geometry.attributes.leafTint.getX(i)));}
const estimate=estimateFragments(groups,camera,256,256);assert(estimate.preCutoutFragments>=estimate.postCutoutFragments);assert(estimate.coveredPixels>0);assert.equal(estimate.nearClippedTrianglesOmitted,0);
console.log('PASS pooled capacity, conservative frustum accounting, seasonal tints, alpha depth writes and projected fragment estimate');
