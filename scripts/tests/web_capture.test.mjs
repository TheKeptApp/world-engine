import test from 'node:test';import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,rm} from 'node:fs/promises';import {tmpdir} from 'node:os';import {join} from 'node:path';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels} from '../web_capture_checks.mjs';
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
