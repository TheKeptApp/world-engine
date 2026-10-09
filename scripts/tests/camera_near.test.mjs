import test from 'node:test';
import assert from 'node:assert/strict';
import {updateCameraNear} from '../../web/src/camera-near.js';
import {mkdtemp,mkdir,copyFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {blockContract} from '../web_capture_blocks.mjs';

function legacy(camera) {
  const near=Math.min(500,Math.max(0.1,0.25*camera.position.y));
  if(Math.abs(near-camera.near)>0.05*camera.near){camera.near=near;camera.updateProjectionMatrix();}
}
const camera=()=>({position:{y:0},near:.2,updates:0,updateProjectionMatrix(){this.updates++;}});
test('shipping viewer near values and projection updates exactly match the old rule',()=>{
  const old=camera(),shared=camera();
  const heights=[-100,0,.4,.42,.420000001,1.65,40,41,42,150,600,2000,3000,1999,600,150,40,1.65];
  for(let i=0;i<10000;i++)heights.push(Math.sin(i)*2500);
  for(const y of heights){old.position.y=shared.position.y=y;legacy(old);updateCameraNear(shared);assert.ok(Object.is(old.near,shared.near));assert.equal(old.updates,shared.updates);}
});
test('ladder heights resolve to 10/37.5/150 m; stationary height does not rebuild projection',()=>{
  const c=camera();for(const [y,near] of [[40,10],[150,37.5],[600,150]]){c.position.y=y;updateCameraNear(c);assert.equal(c.near,near);const n=c.updates;updateCameraNear(c);assert.equal(c.updates,n);}
});
test('Lakeview hold-out contract works before generated assets exist',async()=>{
 const dir=await mkdtemp(join(tmpdir(),'a7-lakeview-contract-'));
 try{await mkdir(join(dir,'scripts'));await copyFile(new URL('../web_capture_contract.json',import.meta.url),join(dir,'scripts/web_capture_contract.json'));
 const c=await blockContract(dir,'lakeview-600');assert.equal(c.fixture.date,'2026-10-15');assert.equal(c.scenes.lakeview.inspection.altitudeAGLMetres,600);assert.deepEqual(c.scenes.lakeview.camera.eye,[41.945182,-87.66432,600]);assert.equal(c.scenes.lakeview.camera.fov,50);
 }finally{await rm(dir,{recursive:true,force:true});}
});
