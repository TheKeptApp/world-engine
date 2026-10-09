// Read finished captures only; never renders, scores, or changes qualification thresholds.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {parseArgs} from 'node:util';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {difference} from './scene_budget_qualification_helpers.mjs';
const {values}=parseArgs({options:Object.fromEntries(['lakeviewOff','lakeviewOn','wilmetteOff','wilmetteOn','panOff','panOn','descentOff','descentOn','static600','control','output','incomplete30'].map(k=>[k,{type:'string'}]))});
for(const k of ['lakeviewOff','lakeviewOn','wilmetteOff','wilmetteOn','panOff','panOn','descentOff','descentOn','static600','control','output'])if(!values[k])throw Error('Missing --'+k);
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json')),{PNG}=require('pngjs');
const read=async p=>JSON.parse(await readFile(p)),sha=b=>createHash('sha256').update(b).digest('hex');
const sum=passes=>Object.entries(passes).filter(([k])=>k.startsWith('main/')).reduce((a,[,v])=>({triangles:a.triangles+v.triangles,draws:a.draws+v.draws}),{triangles:0,draws:0});
const compare=async(a,b)=>{const x=await readFile(a),y=await readFile(b),p=PNG.sync.read(x),q=PNG.sync.read(y);if(p.width!==q.width||p.height!==q.height)throw Error('PNG size mismatch');return {defaultPath:a,variantPath:b,defaultSHA256:sha(x),variantSHA256:sha(y),encodedPNGIdentical:x.equals(y),...difference(p.data,q.data,p.width,p.height)};};
const framePath=(dir,f)=>resolve(dir,f.frame||f.file||f.image?.file||f.png);
const report={testedCommit:'afc72bd',qualification:'FAIL — do not adopt',createdUTC:new Date().toISOString(),pixelGate:'All decoded RGBA bytes equal; no threshold or masked region',units:'maxByte and meanAbsoluteByte are 0–255 byte units; normalized equivalents divide by 255',holdouts:[],motion:[],inputs:{...values}};
for(const block of ['lakeview','wilmette']){
 const offDir=values[block+'Off'],onDir=values[block+'On'],off=await read(resolve(offDir,'web-capture.json')),on=await read(resolve(onDir,'web-capture.json'));if(off.status!=='passed'||on.status!=='passed')throw Error('Incomplete static capture');
 for(const a of off.frames){const b=on.frames.find(f=>f.scene===a.scene&&f.repeat===a.repeat);if(!b)throw Error('Missing matching hold-out frame');
  for(const k of ['camera','date','inspection','fixture','projection','exposure','foliageExp1','crownV2','crownV3'])if(JSON.stringify(a[k])!==JSON.stringify(b[k]))throw Error('Unmatched '+k);
  report.holdouts.push({block,scene:a.scene,default:sum(a.metrics.cost.passes),variant:sum(b.metrics.cost.passes),camera:a.camera,inspection:a.inspection,date:a.date,difference:await compare(framePath(offDir,a),framePath(onDir,b))});
 }
}
for(const path of ['pan','descent']){
 const offDir=values[path+'Off'],onDir=values[path+'On'],off=await read(resolve(offDir,'qualification.json')),on=await read(resolve(onDir,'qualification.json'));if(off.status!=='completed'||on.status!=='completed'||off.fps!==on.fps||JSON.stringify(off.sampleFrames)!==JSON.stringify(on.sampleFrames)||off.frames.length!==on.frames.length)throw Error('Incomplete/unmatched motion sequence');
 const frames=off.frames.map((a,i)=>{const b=on.frames[i];for(const k of ['pose','camera','exposure'])if(JSON.stringify(a[k])!==JSON.stringify(b[k]))throw Error('Unmatched motion '+k+' at '+i);return {index:i,simulationTimeSeconds:a.simulationTimeSeconds,pose:a.pose,default:{...a,main:sum(a.passes)},variant:{...b,main:sum(b.passes)}};});
 const comparisons=[];for(const i of off.sampleFrames)comparisons.push({index:i,simulationTimeSeconds:i/off.fps,...await compare(framePath(offDir,off.frames[i]),framePath(onDir,on.frames[i]))});
 report.motion.push({path,fps:off.fps,simulationSeconds:off.simulationSeconds,completedFrames:frames.length,browserVersion:on.browserVersion,fixture:on.contract.fixture,startedUTC:{default:off.startedUTC,variant:on.startedUTC},default:{cpu:off.cpu,actualWallSeconds:off.actualWallSeconds,overDrawFloor:off.overDrawFloor,memoryStart:off.memoryStart,memoryEnd:off.memoryEnd,buffersAfterGC:off.buffersAfterGC,startHeap:off.startHeap,endHeapAfterGC:off.endHeapAfterGC,sourceHashes:off.sourceHashes},variant:{cpu:on.cpu,actualWallSeconds:on.actualWallSeconds,overDrawFloor:on.overDrawFloor,memoryStart:on.memoryStart,memoryEnd:on.memoryEnd,buffersAfterGC:on.buffersAfterGC,startHeap:on.startHeap,endHeapAfterGC:on.endHeapAfterGC,sourceHashes:on.sourceHashes},comparisons,frames});
}
const ctrl=await read(resolve(values.control,'web-capture.json')),base=await read(resolve(values.lakeviewOff,'web-capture.json')),a=base.frames.find(f=>f.scene==='lakeview-150');report.lakeviewDefaultRepeatControl=[];for(const b of ctrl.frames)report.lakeviewDefaultRepeatControl.push(await compare(framePath(values.lakeviewOff,a),framePath(values.control,b)));
const diagnostic=await read(resolve(values.static600,'qualification.json'));if(diagnostic.status!=='completed'||!diagnostic.globalStaticDiagnostic)throw Error('Invalid static diagnostic');const f=diagnostic.frames[0],desc=await read(resolve(values.descentOff,'qualification.json'));report.globalStatic600Diagnostic={adopted:false,change:'Remove spatial cell from static compatibility key only in the served copy; exact material/layout/model matrix/render order/category/transparency identity retained',main:sum(f.passes),difference:await compare(framePath(values.descentOff,desc.frames[0]),framePath(values.static600,f)),sourceHashes:diagnostic.sourceHashes,instrumentedSourceSHA256:diagnostic.instrumentedSourceSHA256};
report.exactPixelFailures=[...report.holdouts.filter(f=>f.difference.differingBytes).map(f=>f.scene),...report.motion.flatMap(m=>m.comparisons.filter(f=>f.differingBytes).map(f=>m.path+':'+f.index))];
report.sourceIdentity={};
for(const file of ['web/bakeoff/main.js','web/bakeoff/scene-budget.js','web/bakeoff/scene-budget-entry.js','web/bakeoff/entry.js','web/src/world.js','Sources/WorldEngine/Shaders/WorldShaders.metal']){const bytes=await readFile(file),original=execFileSync('git',['show','afc72bd:'+file]);if(!bytes.equals(original))throw Error('Source differs from tested afc72bd: '+file);report.sourceIdentity[file]={sha256:sha(bytes),byteIdenticalToAfc72bd:true};}
if(values.incomplete30){const retry=await read(resolve(values.incomplete30,'qualification.json'));if(retry.status!=='failed'||retry.fps!==30)throw Error('Invalid partial retry evidence');report.incomplete30HzRetry={path:resolve(values.incomplete30,'qualification.json'),status:retry.status,fps:retry.fps,completedFrames:retry.frames.length,completedSamples:retry.frames.filter(f=>f.sample).length,interruptedBy:retry.interruptedBy,error:retry.error.split('\n')[0],cpu:retry.cpu,lastFrame:Object.fromEntries(['index','frameMs','buffers','wallTimeSeconds'].map(k=>[k,retry.frames.at(-1)[k]]))};}
await mkdir(dirname(resolve(values.output)),{recursive:true});await writeFile(values.output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({output:values.output,exactPixelFailures:report.exactPixelFailures,globalStatic600:report.globalStatic600Diagnostic.main}));
