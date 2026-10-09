// Evidence verification only: reads completed captures; does not launch a browser or score.
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
const [variant,control]=process.argv.slice(2);assert(variant&&control,'usage: node scene-budget-capture.test.mjs VARIANT_DIR DEFAULT_CONTROL_DIR');
const root=resolve('.'),baseline=resolve('docs/lookloop/captures/a7-web-crown-all-near-fix');
const saved=JSON.parse(await readFile(resolve(baseline,'manifest.json'))),on=JSON.parse(await readFile(resolve(variant,'web-capture.json'))),off=JSON.parse(await readFile(resolve(control,'web-capture.json')));
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json')),{PNG}=require('pngjs');
const sum=passes=>Object.entries(passes).filter(([k])=>k.startsWith('main/')).reduce((a,[,p])=>({triangles:a.triangles+p.triangles,draws:a.draws+p.draws}),{triangles:0,draws:0});
const shadowAndPost=passes=>Object.fromEntries(Object.entries(passes).filter(([k])=>!k.startsWith('main/')).sort());
assert.equal(on.status,'passed');assert.equal(off.status,'passed');assert.equal(on.frames.length,6);assert.equal(off.frames.length,3);
for(const alt of [40,150,600]){
 const old=saved.frames.find(f=>f.scene==='sloans-'+alt&&f.mode==='off'&&!f.repeat),fresh=off.frames.find(f=>f.scene===old.scene);
 const bytes=await readFile(resolve(baseline,old.file));assert.equal(createHash('sha256').update(bytes).digest('hex'),old.sha256);assert.deepEqual(await readFile(resolve(control,fresh.frame)),bytes);
 for(const frame of on.frames.filter(f=>f.scene===old.scene)){
  assert.equal(frame.sceneBudget.enabled,true);assert.equal(frame.crownV2,false);assert.equal(frame.crownV3,false);assert.equal(frame.foliageExp1,'off');assert.equal(frame.crownBudget,null);
  assert.deepEqual(frame.metrics.camera,old.resolvedCamera);assert.deepEqual(frame.camera,old.requestedCamera);assert.deepEqual(frame.projection,old.projection);assert.deepEqual(frame.exposure,old.exposureState.values);assert.deepEqual(frame.fixture,old.fixture);
  assert.deepEqual(shadowAndPost(frame.metrics.cost.passes),shadowAndPost(old.passes));
  const image=await readFile(resolve(variant,frame.frame));assert.deepEqual(image,bytes);assert.deepEqual(PNG.sync.read(image).data,PNG.sync.read(bytes).data);
  const main=sum(frame.metrics.cost.passes);assert.equal(main.triangles,frame.sceneBudget.retainedTriangles+1984);assert.equal(main.draws,frame.sceneBudget.pooledDraws+1);
  if(alt===150)assert(main.triangles<400000&&main.draws<=100);
 }
 console.log(alt+' m: exact baseline/default/variant/repeat PNG and RGBA; pose/exposure/shadow/post match; '+JSON.stringify(sum(on.frames.find(f=>f.scene===old.scene).metrics.cost.passes)));
}
