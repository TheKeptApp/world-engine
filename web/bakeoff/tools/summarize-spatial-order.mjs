#!/usr/bin/env node
// Summarize retained read-only probes; does not render, export or alter shadow policy.
import {readFile,writeFile} from 'node:fs/promises';
const [destination,...files]=process.argv.slice(2);if(!destination||files.length!==4)throw Error('Usage: summarize-spatial-order.mjs output.json four-qualification.json-files');
const reports=await Promise.all(files.map(async path=>({path,...JSON.parse(await readFile(path,'utf8'))}))),result={qualification:[],shadows:[],models:'conservative existing-light-frustum feature/instance bounds; not visible shadow depth ownership'};
for(const report of reports){if(report.status!=='completed')throw Error(`Qualification did not pass: ${report.path}`);
 for(const row of report.frames){if(row.mode!=='lossless')continue;const baseline=report.frames.find(r=>r.altitude===row.altitude&&r.mode==='default'),repeat=report.frames.find(r=>r.altitude===row.altitude&&r.mode==='repeat');if(row.diff.max!==0||row.diff.mean!==0||repeat.diff.max!==0)throw Error('Exact control/variant gate failed');result.qualification.push({family:report.family,area:report.area,altitude:row.altitude,default:baseline.main,variant:row.main,diff:row.diff,regions:row.regions,control:repeat.diff,sourceHashes:report.sourceHashes,paths:[baseline.path,repeat.path,row.path],hashes:[baseline.pngSha256,repeat.pngSha256,row.pngSha256],resources:row.metrics.spatial??row.metrics.metrics.spatial});}
 if(report.family!=='scoreboard')continue;
 for(const row of report.frames.filter(r=>r.mode==='default'&&r.altitude!==600)){
  const passes=row.metrics.metrics.passes,actual=Object.entries(passes).filter(([k])=>k.startsWith('shadow/')).reduce((a,[,v])=>({triangles:a.triangles+v.triangles,draws:a.draws+v.draws}),{triangles:0,draws:0}),d=row.diagnostics;
  if(d.shadow.reduce((n,m)=>n+m.triangles,0)!==actual.triangles||d.shadow.length!==actual.draws||d.details.reduce((n,m)=>n+m.triangles,0)!==actual.triangles)throw Error(`Shadow ownership does not reconcile: ${report.area}/${row.altitude}`);
  const categories={},bands={},models={fineBounds:0,backFaceOnly:0,farVegetation:0,buildingBoxFarVegetation:0};
  for(const item of d.details){const category=item.category,c=categories[category]??={submitted:0,inLight:0,potentialVisibleGroundShadow:0,backFacingInLight:0,featuresOrInstances:0,bands:{}};c.submitted+=item.triangles;c.featuresOrInstances++;c.bands[item.band]=(c.bands[item.band]??0)+item.triangles;bands[item.band]=(bands[item.band]??0)+item.triangles;
   if(!item.inLight)continue;c.inLight+=item.triangles;if(item.potentialVisibleShadow)c.potentialVisibleGroundShadow+=item.triangles;const back=item.backFacingTriangles??item.triangles;c.backFacingInLight+=back;models.fineBounds+=item.triangles;models.backFaceOnly+=back;const far=item.instance!==undefined&&/tree|bush/i.test(category)?Math.min(item.triangles,item.farTriangles):back;models.farVegetation+=far;models.buildingBoxFarVegetation+=category==='building'?12:far;
  }
  result.shadows.push({area:report.area,altitude:row.altitude,actual,categories,bands,models,source:report.path});
 }
}
await writeFile(destination,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({views:result.qualification.length,shadows:result.shadows.map(s=>({area:s.area,altitude:s.altitude,actual:s.actual,models:s.models}))}));
