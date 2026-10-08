import test from 'node:test';import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,rm} from 'node:fs/promises';import {tmpdir} from 'node:os';import {join} from 'node:path';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels} from '../web_capture_checks.mjs';
import {startCaptureServer} from '../web_capture_server.mjs';
test('mode matrix and invalid values',()=>{assert.equal(modeQueries({matrix:true}).length,6);assert.throws(()=>modeQueries({crown:'pretend'}));});
test('counter guard rejects incomplete and unequal scene coverage',()=>{
 assert.throws(()=>verifyCounters({triangles:0,drawCalls:1}));
 const a={scene:'sloans',metrics:{triangles:10,drawCalls:2}};
 verifyCoverage([a,{...a,scene:'lakeview',metrics:{triangles:30,drawCalls:3}},a]);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{triangles:9,drawCalls:2}}]),/Unequal/);
 assert.throws(()=>verifyCoverage([a,{...a,metrics:{triangles:10,drawCalls:1}}]),/Unequal/);
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
