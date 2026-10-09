// Per-frame budget qualification and OFF/ON handoff; assigns no visual score.
import {readFile,writeFile} from 'node:fs/promises';
const [destination,...paths]=process.argv.slice(2);if(!destination||paths.length!==8)throw Error('Expected eight area manifests');
const reports=await Promise.all(paths.map(async path=>({path,report:JSON.parse(await readFile(path,'utf8'))})));
const acceptedCaptureWorkers=new Set(["791fd013c18f4d66d80055bdacc5d5eaca0c5dc42079a1b4be4e0c7cb7c5766b", "9b0407daa62d8140ef8a32ea9b7b942b380b832ce810d8ca54dbcc0a68d26faf"]);
const rows=[],hashes=reports.find(x=>x.report.status==='completed')?.report.sourceHashes;if(!hashes)throw Error('No completed candidate capture');
for(const {path,report:r}of reports){
 if(r.status==='unsupported-regional-adapter'){
  if(r.area!=='greenville-downtown'||r.frames.length!==3)throw Error('Unexpected unsupported capture');
  rows.push(...r.frames.map(f=>({...f,status:'unqualified',reason:r.error})));continue;
 }
 const partial=r.status==='failed'&&r.area==='winnetka-village-green'&&r.frames.length===3;
 if(!partial&&(r.status!=='completed'||r.frames.length!==9))throw Error('Incomplete area: '+path);
 if(!acceptedCaptureWorkers.has(r.sourceHashes['web/bakeoff/tools/capture-budget-bundle.mjs']))throw Error('Unaudited capture worker');
 if(r.servedMainSha256!==reports.find(x=>x.report.status==='completed').report.servedMainSha256)throw Error('Mixed served render source');
 for(const [key,value]of Object.entries(hashes))if(r.sourceHashes[key]!==value&&key!=='web/bakeoff/tools/capture-budget-bundle.mjs')throw Error('Mixed candidate render source: '+key);
 for(let i=0;i<r.frames.length;i+=3){const [off,repeat,on]=r.frames.slice(i,i+3);
  if(off.mode!=='off'||repeat.mode!=='repeat'||on.mode!=='on'||repeat.difference.differingBytes||!on.cameraCheck.pass)throw Error('Control/pose failed');
  if(on.metrics.bundle?.far!==false||on.metrics.palette?.mode!=='tableA'||on.metrics.light?.mode!=='on'||!on.metrics.context||!on.metrics.shadowCells?.enabled)throw Error('Bundle member missing');
  if(on.metrics.context.addedShadowTriangles||on.metrics.context.addedShadowDraws||on.metrics.shadowCells.reachChanged)throw Error('Unapproved shadow policy');
  rows.push({view:on.view,altitude:on.altitude,status:'measured',mainOff:off.main,shadowOff:off.shadow,main:on.main,shadow:on.shadow,tiers:on.tiers,imageDifference:on.difference,off:off.path,on:on.path,pngHashes:{off:off.pngSha256,on:on.pngSha256},context:on.metrics.context,source:path,creditsStyle:r.creditsStyle??'original 13.5px fractional line-height',captureWorkerSha256:r.sourceHashes['web/bakeoff/tools/capture-budget-bundle.mjs']});
 }
 if(partial)for(const altitude of [150,600])rows.push({view:r.area+'/'+altitude,altitude,status:'unqualified',main:null,shadow:null,tiers:{floor:{pass:false},standard:{pass:false}},reason:r.error,source:path});
}
if(rows.length!==24||new Set(rows.map(r=>r.view)).size!==24)throw Error('Incomplete/duplicate scoreboard views');
const result={status:'qualification-incomplete',renderer:'bakeoff-existing-look/full-scoreboard-package',sourceHashes:hashes,captureWorkerVersions:[...new Set(reports.map(x=>x.report.sourceHashes['web/bakeoff/tools/capture-budget-bundle.mjs']))],controlRepair:'Only capture worker differs: retained attribution uses integer line-height after rejected Evanston row-27 control. All render modules and served render clock sources remain identical; within-area OFF/ON styles match. No pixel mask.',views:24,measured:rows.filter(r=>r.status==='measured').length,floorPass:rows.filter(r=>r.status==='measured'&&r.tiers.floor.pass).length,standardPass:rows.filter(r=>r.status==='measured'&&r.tiers.standard.pass).length,rows,reports:paths,scoring:'A3 paired scoring only; no score or promotion'};
await writeFile(destination,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({status:result.status,measured:result.measured,floorPass:result.floorPass,standardPass:result.standardPass}));
