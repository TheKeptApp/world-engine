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
 const hash=createHash('sha256').update(await readFile(path)).digest('hex');assert.equal(hash,before.sourceHashes[path],path+' render input changed');sourceHashes[path]=hash;
}
// Main's optional existingExports branch is not reached by these contracts.
let worker=await readFile('scripts/capture_web.mjs','utf8');
worker=worker.replace("existingExports:{type:'boolean',default:false},",'').replace("  if(values.existingExports){if(!await exists('Generated/web-capture/'+spec.area+'/world.json'))throw Error('Requested existing export is absent: '+spec.area);}\n  else await command",'  await command');
assert.equal(createHash('sha256').update(worker).digest('hex'),before.sourceHashes['scripts/capture_web.mjs'],'unexpected capture-worker change');
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
for(const row of controls)assert.equal(row.worldBelow32.maxByte,0);
const report={status:'whole-image gate blocked; world gate awaits R approval',rebasedOnto:execFileSync('git',['rev-parse','origin/main'],{encoding:'utf8'}).trim(),priorFrames:34,sourceHashes,controls,noiseGate:{units:'channel values normalized to 0..1',max:2/255,mean:1e-3,observedWorldMax:0,observedWorldMean:0,wholeImagePassed:false},reason:'Render inputs and all prior fixture/scene/camera values identical; existingExports path unused; server MIME correction affects JS overrides not used here, HTML/JSON bodies unchanged; idempotent close affects teardown only. Four fresh controls have identical world pixels but a credits background edge mismatch on row 27. No scores.'};
await writeFile(base+'/rebase-validation.json',JSON.stringify(report,null,2)+'\n');
console.log('PASS source/fixture/camera preservation. BLOCKED whole-image noise gate: row 27 credits edge; world max/mean 0/0.');
