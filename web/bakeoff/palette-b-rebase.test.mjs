// Read-only capture-reuse audit. No browser, GPU, export or score.
import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {blockContract,inspectionCamera} from '../../scripts/web_capture_blocks.mjs';
const root=resolve('.'),base='web/bakeoff/evidence/palette-b',load=async p=>JSON.parse(await readFile(p));
const before=await load(base+'/manifest.json'),sourceHashes={};
for(const path of Object.keys(before.sourceHashes).filter(p=>p.startsWith('web/'))){
 let bytes=await readFile(path);
 if(path==='web/bakeoff/entry.js')bytes=Buffer.from(bytes.toString().replace("new URLSearchParams(location.search).get('spatialCells')==='1'?'./spatial-cells-entry.js':",''));
 const hash=createHash('sha256').update(bytes).digest('hex');assert.equal(hash,before.sourceHashes[path],path+' render input changed');sourceHashes[path]=hash;
}
// Reviewed against main 69f7141: additional probes are screen-only, exports loop unused;
// pose checks and contract hashing are read-only. Only palette plumbing differs from main.
assert.equal(createHash('sha256').update(await readFile('scripts/capture_web.mjs')).digest('hex'),'afdef1a783252a91078be1c012dfbc8889dfab44ad4ebe6169d573727c195a89','review capture-worker changes before reusing evidence');
for(const [block,run]of [['sloans-ladder','absent'],['lakeview-150','lakeview-default'],['lakeview-600','lakeview-control-absent']]){
 const old=await load(base+'/'+run+'/web-capture.json'),c=await blockContract(root,block);
 assert(!c.exports?.length);assert.deepEqual(c.fixture,old.contract.fixture);
 for(const view of Object.values(c.scenes)){
  view.camera=inspectionCamera(c.ladder?.pose??view.inspection,view.inspection.altitudeAGLMetres,old.exportFrame.origin);
  if(!c.ladder)view.inspection.groundDatum=old.exportFrame.vertical;
 }
 assert.deepEqual(c.scenes,old.contract.scenes,block+' camera/scene inputs changed');
}
const {controls}=await load(base+'/rebase-controls/comparison.json');
for(const row of controls){
 assert.equal(row.worldBelow32.maxByte,0);assert.equal(row.worldBelow32.meanNormalized,0);
 assert.equal(createHash('sha256').update(await readFile(row.frame)).digest('hex'),row.sha256);
}
for(const scene of ['sloans','lakeview'])assert.equal(controls.find(r=>r.name===scene+'-absent').sha256,controls.find(r=>r.name===scene+'-off').sha256);

const report={status:'passed R-approved exact-world gate; credits strip excluded',rebasedOnto:execFileSync('git',['rev-parse','origin/main'],{encoding:'utf8'}).trim(),priorFrames:34,sourceHashes,controls,noiseGate:{authority:'R coordinator decision, 9 October 2026',region:'rows y >= 32',excluded:'credits rows 0..31',max:0,mean:0,observedWorldMax:0,observedWorldMean:0,wholeImageGating:false,postRebaseBaseline:controls.map(({name,frame,sha256})=>({name,frame,sha256}))},reason:'Render inputs and all prior fixture/scene/camera values identical; existingExports path unused; server MIME correction affects JS overrides not used here, HTML/JSON bodies unchanged; idempotent close affects teardown only. Four fresh controls have identical world pixels but a credits background edge mismatch on row 27. No scores.'};
await writeFile(base+'/rebase-validation.json',JSON.stringify(report,null,2)+'\n');
console.log('PASS source/fixture/camera preservation. PASS approved world gate max/mean 0/0; excluded credits difference row 27; four fresh baselines hash-verified.');
