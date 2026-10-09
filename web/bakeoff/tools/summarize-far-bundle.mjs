// A3 handoff and static budget accounting only; no visual score.
import {readFile,writeFile} from 'node:fs/promises';
const [destination,...paths]=process.argv.slice(2);if(!destination||paths.length!==3)throw Error('Expected three area reports');
const reports=await Promise.all(paths.map(async path=>({path,r:JSON.parse(await readFile(path,'utf8'))}))),rows=[],hashes=reports[0].r.sourceHashes;
for(const {path,r}of reports){
 if(r.status!=='completed'||r.frames.length!==9)throw Error('Incomplete capture: '+path);
 if(JSON.stringify(r.sourceHashes)!==JSON.stringify(hashes))throw Error('Mixed captured sources');
 for(let i=0;i<9;i+=3){const [before,repeat,after]=r.frames.slice(i,i+3);
  if(before.mode!=='before'||repeat.mode!=='repeat'||after.mode!=='after'||repeat.difference.differingBytes)throw Error('Full-image control failed');
  if(!after.cameraCheck.pass||!after.metrics.bundle.far||JSON.stringify(before.shadow)!==JSON.stringify(after.shadow))throw Error('Pose/shadow coverage changed');
  if(after.altitude<400&&(after.difference.differingBytes||after.metrics.farParent.selected||after.metrics.farWater.active||after.metrics.context.mergeActive))throw Error('Near view changed');
  if(after.altitude>=400&&(!after.metrics.farParent.selected||!after.metrics.farWater.active||!after.metrics.context.mergeActive))throw Error('Far member not admitted');
  rows.push({view:after.view,altitude:after.altitude,before:{main:before.main,shadow:before.shadow},after:{main:after.main,shadow:after.shadow},tiers:after.tiers,difference:after.difference,paths:{before:before.path,after:after.path,repeat:repeat.path},pngHashes:{before:before.pngSha256,after:after.pngSha256,repeat:repeat.pngSha256},farParent:after.metrics.farParent,farWater:after.metrics.farWater,context:after.metrics.context,source:path});
 }
}
const result={schema:'a10-far-budget-bundle/1',status:'static-counter-qualified; A3/native/memory pending',sourceHashes:hashes,rows,controls:'Nine exact full-image repeats; six exact near-view comparisons; original shadow submissions retained',scoring:'A3 only',floorPass:rows.filter(r=>r.tiers.floor.pass).length,standardPass:rows.filter(r=>r.tiers.standard.pass).length};
await writeFile(destination,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({views:rows.length,floorPass:result.floorPass,standardPass:result.standardPass}));
