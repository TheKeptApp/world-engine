import test from 'node:test';import assert from 'node:assert/strict';import {readFile} from 'node:fs/promises';import {createHash} from 'node:crypto';
import {distribution} from '../scene_budget_qualification_helpers.mjs';
const evidence=JSON.parse(await readFile(new URL('../../web/bakeoff/evidence/scene-budget-qualification/manifest.json',import.meta.url)));
test('evidence retains all hold-outs, twelve motion samples per path and every pixel failure',()=>{
 assert.equal(evidence.holdouts.length,6);assert.equal(evidence.motion.length,2);const failures=[];
 for(const row of evidence.holdouts)if(row.difference.differingBytes)failures.push(row.scene);
 for(const path of evidence.motion){assert.equal(path.comparisons.length,12);assert.equal(path.frames.length,10*path.fps+1);for(const f of path.comparisons){assert.equal(f.regions.reduce((n,r)=>n+r.differingBytes,0),f.differingBytes);if(f.differingBytes)failures.push(path.path+':'+f.index);}}
 assert.deepEqual(evidence.exactPixelFailures,failures);assert.ok(failures.length);assert.match(evidence.qualification,/FAIL/);assert.equal(evidence.globalStatic600Diagnostic.adopted,false);
});
test('all-frame costs and over-floor lists reproduce from retained counters',()=>{
 for(const path of evidence.motion)for(const mode of ['default','variant']){
  const over=[];for(const f of path.frames){const sums=Object.entries(f[mode].passes).filter(([k])=>k.startsWith('main/')).reduce((a,[,v])=>({triangles:a.triangles+v.triangles,draws:a.draws+v.draws}),{triangles:0,draws:0});assert.deepEqual(f[mode].main,sums);if(sums.draws>100)over.push(f.index);}
  assert.deepEqual(path[mode].overDrawFloor,over);
  for(const phase of ['selectionMs','poolingMs','maintenanceMs'])assert.deepEqual(path[mode].cpu[phase],distribution(path.frames.map(f=>f[mode].cpu[phase])));
 }
});
test('shipping and experiment sources still match recorded qualification hashes',async()=>{
 for(const [file,value] of Object.entries(evidence.sourceIdentity)){const b=await readFile(new URL('../../'+file,import.meta.url));assert.equal(createHash('sha256').update(b).digest('hex'),value.sha256);assert.equal(value.byteIdenticalToAfc72bd,true);}
});
