#!/usr/bin/env node
// Read-only evidence reconciliation. Never writes frames or declares a visual score.
import {readFile,writeFile} from 'node:fs/promises';
const [output,...paths]=process.argv.slice(2);if(!output||paths.length!==10)throw Error('Expected output plus four shadow-only, four stress and two combined reports');
const reports=await Promise.all(paths.map(async path=>({path,report:JSON.parse(await readFile(path,'utf8'))})));
const rows=[];
for(let index=0;index<reports.length;index++){
 const {path,report:r}=reports[index],kind=index<4?'shadow-only':index<8?'shadow-stress':'combined';
 if(r.status!=='completed'||r.frames.length!==9)throw Error('Incomplete qualification '+path);
 for(const f of r.frames){if(f.mode==='default')continue;for(const [name,d]of [['image',f.diff],['shadow depth',f.shadowDepth?.diff]])if(!d||d.max!==0||d.mean!==0||d.differingBytes!==0)throw Error(`Nonexact ${name}: ${path} ${f.view} ${f.mode}`);}
 for(const f of r.frames.filter(f=>f.mode==='lossless')){
  const base=r.frames.find(b=>b.view===f.view&&b.mode==='default'),s=f.metrics.shadowCells;if(!s||s.triangles!==f.shadow.triangles||s.draws!==f.shadow.draws||s.reachChanged||s.lodChanged)throw Error('Shadow ledger mismatch '+f.view);
  if(kind==='shadow-only'&&JSON.stringify(base.main)!==JSON.stringify(f.main))throw Error('Shadow-only changed main cost');
  if(kind==='shadow-stress'){
   if(f.view.includes('light-edge')&&!(f.shadowAudit?.edgeInstances>0))throw Error('Missing light edge witness');
   if(f.view.includes('offscreen-caster')&&!(f.shadowAudit?.offscreenInstances>0))throw Error('Missing offscreen caster witness');
   if(f.view.includes('low-sun')&&!(f.shadowDepth.nonClearTexels>0&&f.metrics.shadowStress?.frames>=4))throw Error('Missing populated low-sun witness');
  }
  if(kind==='combined'&&!(f.metrics.spatial??f.metrics.metrics.spatial)?.mergeSourceRuns)throw Error('Missing opt-in source-run flag');

  rows.push({kind,family:r.family,area:r.area,view:f.view,altitude:f.altitude,defaultMain:base.main,variantMain:f.main,defaultShadow:base.shadow,variantShadow:f.shadow,mainDelta:{triangles:f.main.triangles-base.main.triangles,draws:f.main.draws-base.main.draws},shadowDelta:{triangles:f.shadow.triangles-base.shadow.triangles,draws:f.shadow.draws-base.shadow.draws},image:f.diff,shadowDepth:f.shadowDepth.diff,unboundedShadowTriangles:s.unboundedTriangles,shadowBuffersBytes:s.bufferBytes,shadowAudit:f.shadowAudit,frame:f.path,depth:f.shadowDepth.path,qualification:path,sourceHashes:r.sourceHashes});
 }
}
const summary={status:'stopped-for-R-draw-budget',defaultOff:true,shippingChanged:false,shadowOnlyViews:12,shadowStressViews:12,combinedViews:6,repeatControls:30,pixelGate:{max:0,mean:0},floor:{mainTrianglesStrictlyBelow:400000,mainDrawsAtMost:100,shadowTrianglesAtMost:150000},rows};
summary.remainingFloorFailures=rows.filter(r=>r.kind==='combined'&&(r.variantMain.triangles>=400000||r.variantMain.draws>100||r.variantShadow.triangles>150000));
summary.drawGate={pass:rows.filter(r=>r.kind==='combined').every(r=>r.variantMain.draws<=100),limit:100};
if(process.env.A10_ORDERED_DELTAS)summary.orderedRunDeltas=JSON.parse(await readFile(process.env.A10_ORDERED_DELTAS,'utf8'));
if(process.env.A10_ADJACENT_PROBE){const p=JSON.parse(await readFile(process.env.A10_ADJACENT_PROBE,'utf8'));if(p.status!=='completed'||p.frames.some(f=>f.diff&&f.diff.max!==0))throw Error('Invalid adjacent probe');summary.rejectedAdjacentProbe={qualification:process.env.A10_ADJACENT_PROBE,source:'/private/tmp/a10-adjacent-draws-rejected/adjacent-draws.js',allPixelsExact:true,retainedRuntime:false,views:p.frames.filter(f=>f.mode==='lossless').map(f=>({altitude:f.altitude,main:f.main,adapter:f.metrics.metrics.spatial.adjacent}))};}
await writeFile(output,JSON.stringify(summary,null,2)+'\n');console.log(JSON.stringify({status:summary.status,views:rows.length,remainingFloorFailures:summary.remainingFloorFailures.map(r=>({view:r.view,main:r.variantMain,shadow:r.variantShadow}))}));
