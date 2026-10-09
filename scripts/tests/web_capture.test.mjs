import test from 'node:test';import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,rm} from 'node:fs/promises';import {tmpdir} from 'node:os';import {join} from 'node:path';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels,byteDifference} from '../web_capture_checks.mjs';
import {startCaptureServer} from '../web_capture_server.mjs';
test('mode matrix and invalid values',()=>{assert.equal(modeQueries({matrix:true}).length,3);assert.throws(()=>modeQueries({crown:'pretend'}));});
test('counter guard rejects incomplete and unequal scene coverage',()=>{
 assert.throws(()=>verifyCounters({triangles:0,drawCalls:1}));
 const a={scene:'sloans',metrics:{triangles:10,drawCalls:2,cost:{passes:{'main/opaque world':{triangles:10,draws:2}}}}};
 verifyCoverage([a,{...a,scene:'lakeview'},a]);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{...a.metrics,triangles:9}}]),/Unequal/);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{...a.metrics,drawCalls:1}}]),/Unequal/);
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
  assert.equal(c.eye[2]-c.target[2],100);
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
