// Measurement only; never grades images. Fail on changed existing submissions or added shadows.
import {readFile,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {byteDifference} from '../../../scripts/web_capture_checks.mjs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
const req=createRequire(resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/package.json')),{PNG}=req('pngjs');
const base=resolve(dirname(fileURLToPath(import.meta.url)),'../evidence/context-ring'),rows=[];
for(const folder of ['main-600','holdouts-40','holdouts-150','west-highland']){
 const report=JSON.parse(await readFile(resolve(base,folder,'manifest.json'),'utf8'));
 if(report.status!=='complete')throw Error('Incomplete '+folder);
 for(const on of report.frames.filter(f=>f.variant==='on')){
  const off=report.frames.find(f=>f.id===on.id&&f.variant==='off'),repeat=report.frames.find(f=>f.id===on.id&&f.variant==='off-repeat');
  if(off.sha256!==repeat.sha256)throw Error('Repeat changed '+on.id);
  const passes=Object.fromEntries(Object.entries(on.metrics.cost.passes).filter(([k])=>!k.includes('/context ')));
  if(Object.keys({...passes,...off.metrics.cost.passes}).some(k=>JSON.stringify(passes[k])!==JSON.stringify(off.metrics.cost.passes[k])))throw Error('Existing passes changed '+on.id);
  const main=Object.entries(on.contextPasses).filter(([k])=>k.startsWith('main/')).reduce((s,[,v])=>({triangles:s.triangles+v.triangles,draws:s.draws+v.draws}),{triangles:0,draws:0});
  if(Object.keys(on.contextPasses).some(k=>k.startsWith('shadow/')))throw Error('Added shadow '+on.id);
  const onPixels=PNG.sync.read(await readFile(resolve(base,folder,on.frame))).data,offPixels=PNG.sync.read(await readFile(resolve(base,folder,off.frame))).data;
  const pixelDifference=byteDifference(offPixels,onPixels);
  rows.push({pixelDifference,id:on.id,folder,blankBefore:off.blank.fraction,blankAfter:on.blank.fraction,blankPass:on.blank.pass,blankNonRegression:on.blank.fraction<=off.blank.fraction,addedMain:main,envelopePass:main.triangles<=40000&&main.draws<=8,main:on.budgets.totals.main,shadow:on.budgets.totals.shadow,tiers:on.budgets.tiers,coreSubmissionsUnchanged:true,repeatExact:true,contextStatus:on.context.status,geometryBytes:on.context.geometryBytes});
 }
}
const missing=JSON.parse(await readFile(resolve(base,'greenville-missing-paused/manifest.json'),'utf8'));
if(missing.status!=='passed')throw Error('Greenville missing-data regression failed');
const summary={gate:'strict blank fraction <35%; context <=40k main tris/8 draws, zero added shadows; no scores',rows,greenville:{status:'missing context; paused shipping-scoreboard no-op only; fresh-process control was noisy; not bakeoff coverage qualification',result:missing.status,blank:missing.frames[1].detectors.blankGround,unchangedPixels:missing.frames[1].difference,main:missing.frames[1].budgets.totals.main,shadow:missing.frames[1].budgets.totals.shadow}};
await writeFile(resolve(base,'summary.json'),JSON.stringify(summary,null,2)+'\n');
for(const r of rows)console.log(`${r.id}: ${(r.blankBefore*100).toFixed(2)} -> ${(r.blankAfter*100).toFixed(2)}%; +${r.addedMain.triangles}/${r.addedMain.draws}; core unchanged`);
