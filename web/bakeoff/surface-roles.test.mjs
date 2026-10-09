import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {readSurfaceRoles,loadSurfaceRoles,sha256} from './surface-roles.js';
import {surfaceFixture} from './surface-roles-fixture.mjs';
const root=process.env.SURFACE_ROLE_AUDIT_ROOT;
assert.equal(await loadSurfaceRoles(null,null),null);assert.equal(await loadSurfaceRoles(null,'off'),null);
let tests=2;
const f=await surfaceFixture();
const fixtureRun=async(edit=()=>{},payload=f.payload)=>{const index=structuredClone(f.index);edit(index);return readSurfaceRoles({readPackage:async p=>f.files[p],readCompanion:async p=>p==='index.json'?f.enc(index):payload});};
const valid=await fixtureRun();assert.equal(valid.word('chunks/0/lod0.glb',0,0,0)&7,1);assert.equal(valid.word('chunks/0/lod0.glb',0,0,1)&7,4);tests++;
for(const edit of [x=>x.schema='bad',x=>x.packageHash.sha256='bad',x=>x.payload.sha256='bad',x=>x.primitives[0].triangleCount++,x=>x.primitives[0].byteOffset=2,x=>x.primitives[0].mesh++,x=>x.primitives[0].lod++,x=>x.primitives.push(x.primitives[0]),x=>x.primitives=[],x=>x.featureSources=[],x=>x.roles[1]='door',x=>x.primitives[0].path='../escape.glb',x=>x.encoding.colourProvenanceBits=[8,9]]){await assert.rejects(fixtureRun(edit),/Surface companion rejected/);tests++;}
for(const word of [0x8001,5,0x0901,0x0019,0x0404]){const p=f.payload.slice();new DataView(p.buffer).setUint16(0,word,true);const hash=await sha256(p);await assert.rejects(fixtureRun(x=>x.payload.sha256=hash,p),/Surface companion rejected/);tests++;}
for(const options of [{tags:{'roof:material':'brick','roof:colour':'#888888'},word:0x0509},{mixed:true}]){
 const v=await surfaceFixture(options),go=()=>readSurfaceRoles({readPackage:async p=>v.files[p],readCompanion:async p=>p==='index.json'?v.enc(v.index):v.payload});
 if(options.mixed)await assert.rejects(go(),/mixed feature triangle/);else {assert.equal((await go()).word('chunks/0/lod0.glb',0,0,0),0x0509);v.index.featureSources[0].tags['roof:colour']='#777777';await assert.rejects(go(),/mapped colour witness/);}tests++;
}
const main=await readFile('web/bakeoff/main.js','utf8');assert(main.includes("q.has('surfaceRoles')&&q.get('surfaceRoles')!=='off'"));assert(main.includes("loadSurfaceRoles(config.world,q.get('surfaceRoles'),world.manifest)"));
const priorFetch=globalThis.fetch,priorLocation=globalThis.location;let fetches=0;
globalThis.location={origin:'http://localhost',href:'http://localhost/view.html'};
globalThis.fetch=async url=>{fetches++;const p=new URL(url).pathname;const data=p==='/companion/index.json'?f.enc(f.index):p==='/companion/triangles.u16le'?f.payload:f.files[p.replace('/package/','')];return {ok:!!data,redirected:false,arrayBuffer:async()=>data.buffer.slice(data.byteOffset,data.byteOffset+data.byteLength)};};
try{
 assert.equal(await loadSurfaceRoles('/package/',null),null);assert.equal(await loadSurfaceRoles('/package/','off'),null);assert.equal(fetches,0);
 assert.equal((await loadSurfaceRoles('/package/','/companion/index.json',JSON.parse(new TextDecoder().decode(f.files['world.json'])))).report.triangles,2);
 await assert.rejects(loadSurfaceRoles('/package/','https://external.invalid/index.json'),/same-origin/);
 await assert.rejects(loadSurfaceRoles('/package/','/companion/index.json',{wrong:'manifest'}),/loaded manifest differs/);
 const savedSchema=f.index.schema;f.index.schema='invalid';await assert.rejects(loadSurfaceRoles('/package/','/companion/index.json'),/schema/);f.index.schema=savedSchema;
 tests+=5;
}finally{globalThis.fetch=priorFetch;if(priorLocation===undefined)delete globalThis.location;else globalThis.location=priorLocation;}
for(const area of root?['sloans-lake','lakeview-sheil-park']:[]){
 const packageDir=root+'/'+area+'-on',companionDir=root+'/'+area+'-companion';
 const readPackage=async p=>new Uint8Array(await readFile(packageDir+'/'+p));
 const original=JSON.parse(await readFile(companionDir+'/index.json'));
 const run=async (edit=x=>{},override={})=>{const index=structuredClone(original);edit(index);return readSurfaceRoles({readPackage:override.readPackage??readPackage,readCompanion:async p=>p==='index.json'?new TextEncoder().encode(JSON.stringify(index)):new Uint8Array(await readFile(companionDir+'/'+p)),...override});};
 const valid=await run();assert.equal(valid.report.triangles,area==='sloans-lake'?456225:1797471);assert.equal(valid.report.status,'validated; no appearance application');tests++;
 const mutations=[x=>x.schema='unknown',x=>x.packageHash.sha256='0'.repeat(64),x=>x.payload.sha256='0'.repeat(64),x=>x.payload.bytes++,x=>x.primitives[0].sha256='0'.repeat(64),x=>x.primitives[0].triangleCount++,x=>x.primitives[1].byteOffset=0,x=>x.primitives[0].lod++,x=>x.primitives.push(x.primitives[0]),x=>x.primitives.pop(),x=>x.primitives[0].path='../escape.glb',x=>x.roles[1]='door',x=>x.encoding.reservedBits=[10,15],x=>x.featureSources=[]];
 for(const edit of mutations){await assert.rejects(run(edit),/Surface companion rejected/);tests++;}
 // Corrupt real payload with its hash honestly updated: reserved-word checks must reject.
 const payload=new Uint8Array(await readFile(companionDir+'/triangles.u16le'));payload[1]|=0x80;
 await assert.rejects(run(()=>{}, {readCompanion:async p=>{if(p!=='index.json')return payload;const i=structuredClone(original);i.payload.sha256=await sha256(payload);return new TextEncoder().encode(JSON.stringify(i));}}),/reserved word/);tests++;
 if(area==='sloans-lake'){
  await assert.rejects(run(()=>{},{readPackage:async p=>new Uint8Array(await readFile(root+'/sloans-lake-packed/'+p))}),/package hash/);tests++;
 }
 console.log('PASS actual companion:',area,valid.report);
}
console.log('PASS surface companion production reader:',tests,'positive/rejection checks; no render or colour mutation.');
