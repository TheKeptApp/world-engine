// Exact-lossless gate and per-view budget accounting; no visual score.
import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const [destination,...paths]=process.argv.slice(2);
if(!destination||paths.length!==8)throw Error('Expected destination and eight qualification reports');
const reports=await Promise.all(paths.map(async path=>({path,report:JSON.parse(await readFile(path,'utf8'))})));
const first=reports[0].report.sourceHashes;
const rows=[];
for(const {path,report:r}of reports){
 if(r.status!=='completed'||r.frames.length!==9)throw Error('Incomplete qualification: '+path);
 for(const key of Object.keys(first))if(r.sourceHashes[key]!==first[key])throw Error('Mixed source revision: '+key);
 for(let i=0;i<9;i+=3){
  const [off,repeat,on]=r.frames.slice(i,i+3);
  if(off.mode!=='default'||repeat.mode!=='repeat'||on.mode!=='lossless')throw Error('Mode/order mismatch');
  for(const f of [repeat,on])if(!f.pass||f.diff.max||f.diff.mean||f.diff.differingBytes||f.shadowDepth.diff.max||f.shadowDepth.diff.mean||f.shadowDepth.diff.differingBytes)throw Error('Exact gate failed: '+f.path);
  if(on.metrics.shadowCells.reachChanged||on.metrics.shadowCells.lodChanged)throw Error('Lossless policy changed');
  if(on.shadow.triangles!==on.metrics.shadowCells.triangles||on.shadow.draws!==on.metrics.shadowCells.draws)throw Error('Shadow ledger mismatch');
  rows.push({family:r.family,area:r.area,view:on.view,altitude:on.altitude,main:on.main,shadowBefore:off.shadow,shadowAfter:on.shadow,imageDifference:on.diff,depthDifference:on.shadowDepth.diff,off:off.path,on:on.path});
 }
}
const result={status:'exact-pass',comparisonViews:rows.length,repeatControls:rows.length,sourceHashes:first,rows,reports:paths};
await writeFile(destination,JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({status:result.status,views:rows.length,sha256:createHash('sha256').update(JSON.stringify(result)).digest('hex')}));
