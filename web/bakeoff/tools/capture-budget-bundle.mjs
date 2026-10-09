#!/usr/bin/env node
// Capture-only fixture adapter: full existing scoreboard packages/poses, existing bakeoff looks.
// Greenville remains explicitly unsupported; no invented regional look or missing-source pass.
import {readFile,writeFile,mkdir,statfs} from 'node:fs/promises';import {resolve,dirname} from 'node:path';import {fileURLToPath} from 'node:url';import {createRequire} from 'node:module';import {homedir} from 'node:os';import {createHash} from 'node:crypto';
import {startCaptureServer} from '../../../scripts/web_capture_server.mjs';import {inspectionCamera,facadeInputs} from '../../../scripts/web_capture_blocks.mjs';import {byteDifference} from '../../../scripts/web_capture_checks.mjs';import {passTotals,tierChecks,verifyLadderPose} from '../../../scripts/world_scoreboard_checks.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..'),[area,destination]=process.argv.slice(2),out=resolve(destination??'');if(!area||!destination)throw Error('Usage: capture-budget-bundle.mjs scoreboard-area output');
const req=createRequire(resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/package.json')),{chromium}=req('playwright'),{PNG}=req('pngjs');
const json=async p=>JSON.parse(await readFile(resolve(root,p),'utf8')),sha=b=>createHash('sha256').update(b).digest('hex');
const reference=await json('docs/scoreboard/world-scoreboard-v0.json'),rows=reference.rows.filter(r=>r.area===area);if(rows.length!==3)throw Error('Unknown scoreboard area');
await mkdir(out,{recursive:false});const report={area,status:'running',renderer:'bakeoff-existing-look/full-scoreboard-package',frames:[],sourceHashes:{},note:'Existing shipping scoreboard remains separate; this report composes the approved bakeoff look flags.'};let browser,server;
const save=()=>writeFile(resolve(out,'manifest.json'),JSON.stringify(report,null,2)+'\n');
try{
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Disk guard below 8 GB');
 for(const f of ['web/bakeoff/entry.js','web/bakeoff/tools/capture-budget-bundle.mjs','web/bakeoff/candidate-bundle-entry.js','web/bakeoff/candidate-bundle.js','web/bakeoff/spatial-cells.js','web/bakeoff/shadow-cells.js','web/bakeoff/context-ring.js','web/bakeoff/main.js','web/bakeoff/light-trial.js','web/bakeoff/palette-b.js','web/src/world.js','web/src/materials.js'])report.sourceHashes[f]=sha(await readFile(resolve(root,f)));
 if(area==='greenville-downtown'){
  report.status='unsupported-regional-adapter';report.error='Existing bakeoff haze/phenology capture adapters cover Denver/Chicagoland only; Greenville cannot run the entire palette/light bundle without inventing regional inputs.';
  report.frames=rows.map(r=>({view:r.key,altitude:r.altitude,main:null,shadow:null,tiers:{floor:{pass:false},standard:{pass:false}},reason:report.error}));await save();process.exitCode=2;
 }else{
  const frozen=await json('scripts/web_capture_contract.json'),folder='Generated/web-capture/scoreboard-'+area,worldBytes=await readFile(resolve(root,folder,'world.json')),world=JSON.parse(worldBytes),facades=await facadeInputs(root,area,resolve(root,folder)),context=await json('web/bakeoff/generated/context/'+area+'.json');
  report.packageSha256=sha(worldBytes);report.context={status:context.status,source:context.source,stats:context.stats};
  // The fixed capture catalog supplies region fixtures; the renderer accepts no area ID rule.
  const denver=['sloans-lake','west-highland'].includes(area),base=structuredClone(frozen.scenes[denver?'sloans':'lakeview']);
  const scenes=Object.fromEntries(rows.map(row=>[row.key.replace('/','-'),{...structuredClone(base),world:'/world/capture/scoreboard-'+area+'/',context:'/candidate-context.json',viewport:row.evidence.viewport,camera:inspectionCamera(row.pose,row.altitude,world.frame.origin),inspection:{...row.pose,utc:row.date},area}]));
  const overrides={'/scenes.json':scenes,'/fixture.json':{...frozen.fixture,date:rows[0].date.slice(0,10)},'/candidate-context.json':context};
  let main=await readFile(resolve(root,'web/bakeoff/main.js'),'utf8');if(main.split('post.render();').length!==2)throw Error('Capture clock anchor changed');main=main.replace('post.render();','renderer._nodes.nodeFrame.time=0;renderer._nodes.nodeFrame.deltaTime=0;post.render();');overrides['/main.js']=main;report.servedMainSha256=sha(main);report.clock={time:0,now:0,exposure:'existing fixed calibration gain',captureOnly:true};
  report.creditsStyle='capture-only integer 14px line-height; attribution retained, no masked pixels';
  const html=(await readFile(resolve(root,'web/bakeoff/lakeview.html'),'utf8')).replace('</body>','<style>body.capture small{line-height:14px}</style></body>');for(const [id]of Object.entries(scenes)){overrides['/'+id+'.html']=html.replace('data-scene="lakeview"','data-scene="'+id+'"');overrides['/data/'+id+'-facades.json']=facades;}
  server=await startCaptureServer(root,overrides);browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
  for(const row of rows){const id=row.key.replace('/','-'),config=scenes[id];let control;
   for(const mode of ['off','repeat','on']){
    const page=await browser.newPage({viewport:config.viewport,deviceScaleFactor:1}),errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(server.origin+'/'+id+'.html?capture&still&crownV2=off&foliageExp1=off'+(mode==='on'?'&spatialCells=1&spatialMergeRuns=1&shadowCells=1&contextRing=1&lightTrial=on&paletteB=tableA':''),{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);const b=window.bakeoff,m=b?.metrics;if(!m||m.samples<3)return false;const key=JSON.stringify([m.cost.passes,m.camera]),p=window.__stable??={key:null,samples:-1,n:0};if(p.samples===m.samples)return false;p.n=p.key===key?p.n+1:1;p.key=key;p.samples=m.samples;return p.n>=3;},null,{timeout:180000,polling:'raf'});
    const metrics=await page.evaluate(()=>{const b=window.bakeoff;b.freeze=true;b.renderer.setAnimationLoop(null);b.renderer.backend.gl.finish();return {metrics:b.metrics,spatial:b.spatialCells,shadowCells:b.shadowCells,context:b.contextRing,palette:b.paletteB,light:b.lightTrial,bundle:b.candidateBundle};});
    const image=await page.screenshot(),png=PNG.sync.read(image),path=resolve(out,row.altitude+'-'+mode+'.png');await writeFile(path,image);const totals=passTotals(metrics.metrics.cost.passes),diff=mode==='off'?null:byteDifference(control,png.data);if(mode==='off')control=png.data;
    const f={view:row.key,altitude:row.altitude,mode,path,pngSha256:sha(image),main:totals.main,shadow:totals.shadow,tiers:tierChecks(totals.main,totals.shadow),difference:diff,metrics,cameraCheck:verifyLadderPose(metrics.metrics.camera,row.pose),pose:row.pose,date:row.date};report.frames.push(f);await save();await page.close();
    if(errors.length)throw Error(errors.join('\n'));if(mode==='repeat'&&diff.differingBytes)throw Error('Exact full-image repeat failed: '+row.key);if(!f.cameraCheck.pass)throw Error('Camera mismatch: '+row.key);
    if(mode==='on'&&(!metrics.bundle||metrics.palette?.mode!=='tableA'||metrics.light?.mode!=='on'))throw Error('Candidate flag not consumed: '+row.key);
    console.log(JSON.stringify({view:row.key,mode,main:f.main,shadow:f.shadow,tiers:f.tiers,difference:diff}));
   }
  }
  for(const [f,digest]of Object.entries(report.sourceHashes))if(sha(await readFile(resolve(root,f)))!==digest)throw Error('Source changed during capture: '+f);
  if(server.failures.length)throw Error('Resource failures: '+server.failures.join(', '));report.status='completed';
 }
}catch(e){report.status='failed';report.error=e.stack;process.exitCode=1;console.error(e.stack);}finally{await browser?.close();await server?.close();await save();}
