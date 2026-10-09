import {fileURLToPath} from 'node:url';
import test from 'node:test';import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,rm} from 'node:fs/promises';import {tmpdir} from 'node:os';import {join} from 'node:path';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels,byteDifference,verifyModes} from '../web_capture_checks.mjs';
import {startCaptureServer} from '../web_capture_server.mjs';
test('mode matrix and invalid values',()=>{assert.equal(modeQueries({matrix:true}).length,3);assert.throws(()=>modeQueries({crown:'pretend'}));});
test('crown modes preserve standard/floor spelling and reject wrong resolved state',()=>{
 for(const crown of ['off','on','standard','floor']){
  const mode=modeQueries({crown})[0];assert.equal(mode.crownV2,crown);
  const evidence={foliageExp1:'off',crownV2:crown==='off'?false:crown==='on'?'standard':crown};
  verifyModes(evidence,mode);
  assert.throws(()=>verifyModes({...evidence,crownV2:crown==='floor'?'standard':'floor'},mode));
 }
});
test('authorized Sloan ladder is distinct from the saved web pair and has exact pose directions',async()=>{
 const {blockContract,inspectionCamera}=await import('../web_capture_blocks.mjs');
 const {LocalFrame}=await import('../../web/src/geo.js');
 const {fileURLToPath}=await import('node:url');
 const {readFile}=await import('node:fs/promises');
 const root=fileURLToPath(new URL('../../',import.meta.url));
 const before=await readFile(new URL('../web_capture_contract.json',import.meta.url));
 const c=await blockContract(root,'sloans-ladder');
 assert.equal(c.ladder.utc,'2026-10-15T20:30:00Z');assert.equal(c.fixture.date,'2026-10-15');
 assert.deepEqual(Object.values(c.scenes).map(s=>s.camera.eye),[40,150,600].map(h=>[39.7511195,-105.0389,h]));
 const origin={latitude:39.7494,longitude:-105.0445},frame=new LocalFrame(origin.latitude,origin.longitude);
 const camera=inspectionCamera(c.ladder.pose,40,origin),a=frame.local(...camera.eye),b=frame.local(...camera.target);
 assert.ok(Math.abs(b[0]-a[0]+100)<1e-6);assert.ok(Math.abs(b[1]-a[1])<1e-6);
 assert.ok(Math.abs(camera.eye[2]-camera.target[2]-100)<1e-6);assert.equal(camera.fov,50);
 assert.deepEqual(await readFile(new URL('../web_capture_contract.json',import.meta.url)),before);
});
test('counter guard rejects incomplete and unequal scene coverage',()=>{
 assert.throws(()=>verifyCounters({triangles:0,drawCalls:1}));
 const a={scene:'sloans',metrics:{triangles:10,drawCalls:2,cost:{passes:{'main/opaque world':{triangles:10,draws:2}}}}};
 verifyCoverage([a,{...a,scene:'lakeview'},a]);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{...a.metrics,triangles:9}}]),/Unequal/);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{...a.metrics,drawCalls:1}}]),/Unequal/);
});
test('v3 is a distinct coverage mode; repeats and non-foliage stay strict',()=>{
 const row=(v3,n,ground=10)=>({scene:'sloans',foliageExp1:'off',crownV2:false,crownV3:v3,metrics:{triangles:ground+n,drawCalls:3,cost:{passes:{'main/opaque world':{triangles:ground,draws:2},'main/foliage':{triangles:n,draws:1}}}}});
 assert.equal(verifyCoverage([row(false,5),row('standard',8)],{expectedDifferent:true}).deltas[0].crownV3,'standard');
 assert.throws(()=>verifyCoverage([row('standard',8),row('standard',9)],{expectedDifferent:true}),/identical-mode repeat/);
 assert.throws(()=>verifyCoverage([row(false,5),row('standard',8,11)],{expectedDifferent:true}),/non-foliage/);
});
test('size and flat-image checks do not accept credit text as world evidence',()=>{
 const p={width:20,height:20,data:Buffer.alloc(20*20*4)};
 for(let i=0;i<20*3*4;i++)p.data[i]=i%256;
 assert.throws(()=>verifyPixels(p,p),/Flat/);
 assert.throws(()=>verifyPixels(p,{width:21,height:20}),/Wrong/);
 for(let i=20*3*4;i<p.data.length;i++)p.data[i]=i%256;
 assert.ok(verifyPixels(p,p).variance>0);
});
test('owned ephemeral server responds before navigation and closes its port',async()=>{
 const root=await mkdtemp(join(tmpdir(),'web-capture-test-'));let server;
 try{await mkdir(join(root,'web/bakeoff'),{recursive:true});await writeFile(join(root,'web/bakeoff/sloans.html'),'fixture');
 server=await startCaptureServer(root);assert.equal(await(await fetch(server.origin+'/sloans.html')).text(),'fixture');
 assert.equal((await fetch(server.origin+'/absent')).status,404);assert.deepEqual(server.failures,['/absent']);
 await server.close();await assert.rejects(fetch(server.origin+'/sloans.html'));server=null;
 }finally{if(server)await server.close();await rm(root,{recursive:true});}
});

test('expectedDifferent only exempts foliage between distinct modes',()=>{
 const row=(foliageExp1,n,world=10)=>({scene:'sloans',foliageExp1,crownV2:'off',metrics:{triangles:world+n,drawCalls:3,cost:{passes:{'main/opaque world':{triangles:world,draws:2},'main/foliage':{triangles:n,draws:1}}}}});
 const a=row('off',20),b=row('remove',2);
 assert.throws(()=>verifyCoverage([a,b]),/Unequal/);
 assert.equal(verifyCoverage([a,b],{expectedDifferent:true}).deltas[0].foliageDelta.triangles,-18);
 assert.throws(()=>verifyCoverage([a,row('remove',2,9)],{expectedDifferent:true}),/non-foliage/);
 assert.throws(()=>verifyCoverage([a,row('off',2)],{expectedDifferent:true}),/identical-mode/);
 assert.throws(()=>verifyCoverage([{...a,metrics:{triangles:3,drawCalls:1}}],{expectedDifferent:true}),/Missing/);
 assert.equal(modeQueries({matrix:true,crown:'off,on'}).length,6);
});
test('frozen web contract agrees with saved pair metadata, not native views',async()=>{
 const {readFile}=await import('node:fs/promises');
 const contract=JSON.parse(await readFile(new URL('../web_capture_contract.json',import.meta.url)));
 const grades=JSON.parse(await readFile(new URL('../../docs/lookloop/web-4127a32/grades.json',import.meta.url)));
 for(const [scene,config] of Object.entries(contract.scenes)){
  const capture=grades.views[scene].capture;
  assert.deepEqual(contract.fixture,capture.resolved.fixture);
  assert.equal(config.camera.fov,capture.camera.fov);
  assert.deepEqual([config.viewport.width,config.viewport.height],capture.viewport.slice(1));
 }
});
test('owned server replays frozen JSON without editing renderer files',async()=>{
 const root=await mkdtemp(join(tmpdir(),'web-contract-test-'));let server;
 try{
  server=await startCaptureServer(root,{'/fixture.json':{date:'2026-10-08'}});
  assert.deepEqual(await(await fetch(server.origin+'/fixture.json')).json(),{date:'2026-10-08'});
  assert.equal((await fetch(server.origin+'/favicon.ico')).status,204);
  assert.deepEqual(server.failures,[]);
 }finally{if(server)await server.close();await rm(root,{recursive:true});}
});

test('repeat byte difference reports exact equality, changes and unequal lengths',()=>{
 assert.deepEqual(byteDifference(Buffer.from([1,2]),Buffer.from([1,2])),{freshBytes:2,repeatBytes:2,differingBytes:0,max:0,mean:0});
 assert.deepEqual(byteDifference(Buffer.from([1,2]),Buffer.from([1,4])),{freshBytes:2,repeatBytes:2,differingBytes:1,max:2,mean:1});
 assert.equal(byteDifference(Buffer.from([1]),Buffer.from([1,2])).differingBytes,1);
});
test('block adapters retain frozen camera and native inspection pose recipe',async()=>{
 const {blockContract,inspectionCamera}=await import('../web_capture_blocks.mjs');
 const {LocalFrame}=await import('../../web/src/geo.js');
 const {fileURLToPath}=await import('node:url');
 const root=fileURLToPath(new URL('../../',import.meta.url));
 const w=await blockContract(root,'wilmette');assert.equal(w.fixture.date,'2026-09-15');
 assert.deepEqual(Object.values(w.scenes).map(s=>s.camera.eye[2]),[40,150,600]);
 for(const heading of [0,90,180,270]){
  const c=inspectionCamera({lat:42,lon:-87,heading,fov:50},40),f=new LocalFrame(42,-87),[e,n]=f.local(...c.target);
  assert.ok(Math.abs(e-100*Math.sin(heading*Math.PI/180))<1e-6);assert.ok(Math.abs(n-100*Math.cos(heading*Math.PI/180))<1e-6);
  assert.ok(Math.abs(c.eye[2]-c.target[2]-100)<1e-6);
 }
 const h=await blockContract(root,'west-highland');assert.deepEqual(h.scenes['west-highland'].camera.eye,[39.759946,-105.04,350]);
 await assert.rejects(blockContract(root,'greenville-downtown'),/No integrated web region/);
});
test('facade adapter reads only this area and export semantics',async()=>{
 const {facadeInputs}=await import('../web_capture_blocks.mjs');
 const root=await mkdtemp(join(tmpdir(),'web-facades-test-'));
 try{
  await mkdir(join(root,'Data/areas/test'),{recursive:true});await mkdir(join(root,'export'));
  const nodes=[{type:'node',id:1,lat:1,lon:2},{type:'node',id:2,lat:2,lon:3},{type:'node',id:3,lat:3,lon:4}];
  await writeFile(join(root,'Data/areas/test/osm.json'),JSON.stringify({elements:[...nodes,{type:'way',id:4,nodes:[1,2,3,1]},{type:'way',id:5,nodes:[1,2],tags:{highway:'residential'}}]}));
  await writeFile(join(root,'export/world.json'),JSON.stringify({chunks:[{scene:'scene.json'}]}));
  const building={kind:'building',id:'way/4',generated:{family:'fixture'},source:{building:'yes'}};
  await writeFile(join(root,'export/scene.json'),JSON.stringify({features:[building,building,{kind:'generated-fence',id:'gen:fence:way/4'}]}));
  const result=await facadeInputs(root,'test',join(root,'export'));
  assert.equal(result.features.length,1);assert.equal(result.features[0].hasFence,true);
  assert.deepEqual(result.features[0].ring,[[1,2],[2,3],[3,4]]);assert.deepEqual(result.roads,[[[1,2],[2,3]]]);
 }finally{await rm(root,{recursive:true});}
});

test('capture overrides serve JavaScript with the correct MIME and close idempotently',async()=>{const server=await startCaptureServer(fileURLToPath(new URL('../../',import.meta.url)),{'/probe.mjs':'export const probe=1;'});try{const r=await fetch(server.origin+'/probe.mjs');assert.equal(r.headers.get('content-type'),'text/javascript');assert.equal(await r.text(),'export const probe=1;');}finally{await server.close();await server.close();}});


test('Lakeview ladder reuses the saved eye and exact shared pose with its export origin',async()=>{
 const {blockContract}=await import('../web_capture_blocks.mjs');
 const {LocalFrame}=await import('../../web/src/geo.js');
 const root=await mkdtemp(join(tmpdir(),'lakeview-ladder-test-'));
 try {
  await mkdir(join(root,'scripts'));await mkdir(join(root,'web/bakeoff/generated/lakeview-sheil-park'),{recursive:true});
  await writeFile(join(root,'scripts/web_capture_contract.json'),JSON.stringify({fixture:{date:'old'},scenes:{lakeview:{camera:{eye:[41.945182,-87.66432,100],target:[0,0,0]},world:'/world/lakeview/'}}}));
  const manifest={frame:{origin:{latitude:41.943,longitude:-87.666},vertical:'flat y = 0 is ground'}};
  const file=join(root,'web/bakeoff/generated/lakeview-sheil-park/world.json');await writeFile(file,JSON.stringify(manifest));
  const c=await blockContract(root,'lakeview-ladder'),frame=new LocalFrame(41.943,-87.666);
  assert.deepEqual(Object.values(c.scenes).map(v=>v.camera.eye[2]),[40,150,600]);
  for(const v of Object.values(c.scenes)){const a=frame.local(...v.camera.eye),b=frame.local(...v.camera.target);assert.ok(Math.abs(b[0]-a[0]+100)<1e-6);assert.ok(Math.abs(b[1]-a[1])<1e-6);assert.equal(v.camera.fov,50);assert.equal(v.templateScene,'lakeview');}
  await writeFile(file,JSON.stringify({frame:{...manifest.frame,vertical:'unknown'}}));await assert.rejects(blockContract(root,'lakeview-ladder'),/flat-ground/);
 }finally{await rm(root,{recursive:true});}
});

test('palette trial Lakeview 150 uses the existing inspection pose without moving the saved contract',async()=>{
 const {blockContract}=await import('../web_capture_blocks.mjs');
 const {fileURLToPath}=await import('node:url');
 const root=fileURLToPath(new URL('../../',import.meta.url));
 const a=await blockContract(root,'lakeview-150'),b=await blockContract(root,'lakeview-600');
 assert.deepEqual(a.scenes.lakeview.camera.eye.slice(0,2),b.scenes.lakeview.camera.eye.slice(0,2));
 assert.equal(a.scenes.lakeview.camera.eye[2],150);assert.equal(b.scenes.lakeview.camera.eye[2],600);
 assert.equal(a.scenes.lakeview.camera.fov,b.scenes.lakeview.camera.fov);
 assert.deepEqual(a.fixture,b.fixture);
});
