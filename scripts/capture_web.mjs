// One-command capture worker. scripts/capture-web.sh owns heavy admission.
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {mkdir,readFile,writeFile,access,statfs} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {createHash,randomUUID} from 'node:crypto';
import {parseArgs} from 'node:util';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels,byteDifference,verifyModes} from './web_capture_checks.mjs';
import {blockContract,facadeInputs,inspectionCamera} from './web_capture_blocks.mjs';
import {verifyLadderPose,THRESHOLDS,passTotals,tierChecks} from './world_scoreboard_checks.mjs';
import {startCaptureServer} from './web_capture_server.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const {values}=parseArgs({options:{output:{type:'string'},scene:{type:'string'},block:{type:'string'},repeat:{type:'boolean',default:false},matrix:{type:'boolean'},foliage:{type:'string',default:'off'},crown:{type:'string',default:'off'},crownV3:{type:'string'},paletteB:{type:'string'},lightTrial:{type:'string'},groundTrial:{type:'string'},sceneBudget:{type:'boolean',default:false},existingExports:{type:'boolean',default:false},screen:{type:'boolean',default:false},expectedDifferent:{type:'boolean',default:false}}});
const runtime=process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules');
const require=createRequire(resolve(runtime,'package.json'));
const {chromium}=require('playwright'),{PNG}=require('pngjs');
const run=resolve(values.output||resolve(root,'.build/lookloop/web-'+randomUUID()));
const readJSON=async path=>JSON.parse(await readFile(resolve(root,path),'utf8'));
const hash=data=>createHash('sha256').update(data).digest('hex');
let browser,server,created=false,stage='contract';
// Signal trap: cleanup is bounded by the outer capture_timeout.py watchdog.
for(const sig of ['SIGTERM','SIGINT'])process.once(sig,()=>{
 console.error('web capture interrupted: closing owned browser and server');
 const forced=setTimeout(()=>process.exit(130),8000);
 Promise.allSettled([browser?.close(),server?.close()]).finally(()=>{clearTimeout(forced);process.exit(130);});
});
const report={status:'failed',frames:[],events:[],startedUTC:new Date().toISOString()};
const started=performance.now();
async function command(executable,args){
 await new Promise((ok,no)=>{const child=spawn(executable,args,{cwd:root,env:process.env,stdio:['ignore','pipe','pipe']});
 child.stdout.on('data',x=>process.stderr.write(x));child.stderr.on('data',x=>process.stderr.write(x));child.on('error',no);child.on('exit',code=>code===0?ok():no(Error(`${executable} exited ${code}`)));});
}
async function exists(path){try{await access(resolve(root,path));return true;}catch{return false;}}
try{
 const contract=values.block?await blockContract(root,values.block):await readJSON('scripts/web_capture_contract.json');
 const {scenes,fixture}=contract;
 const selected=values.scene?[values.scene]:(values.block?Object.keys(scenes):['sloans','lakeview']);
 if(selected.some(scene=>!Object.hasOwn(scenes,scene)))throw Error('Unsupported frozen web scene: '+values.scene);
 const freshFrames=new Map();
 const identities=Object.fromEntries(selected.map(scene=>[scene,scene+'-frozen-web']));
 const modes=modeQueries({foliage:values.foliage,crown:values.crown,matrix:values.matrix});
 if(modes.some(m=>m.crownV2!=='off')&&!(await readFile(resolve(root,'web/bakeoff/main.js'),'utf8')).includes('crownV2'))throw Error('Requested crown mode is unsupported by this checkout');
 if(values.crownV3!==undefined){if(!['off','standard'].includes(values.crownV3)||modes.some(m=>m.crownV2!=='off'))throw Error('Invalid crownV3 capture mode');for(const mode of modes)mode.crownV3=values.crownV3;}
 if(values.sceneBudget){if(modes.some(m=>m.crownV2!=='off'||m.foliageExp1!=='off')||values.crownV3&&values.crownV3!=='off')throw Error('sceneBudget capture requires all crown/foliage modes OFF');for(const mode of modes)mode.sceneBudget='1';}
 if(values.paletteB!==undefined){if(!['off','lot','tableA'].includes(values.paletteB))throw Error('Invalid paletteB capture mode');for(const mode of modes)mode.paletteB=values.paletteB;}
 if(values.lightTrial!==undefined){if(!['off','on'].includes(values.lightTrial))throw Error('Invalid lightTrial capture mode');for(const mode of modes)mode.lightTrial=values.lightTrial;}
 if(values.groundTrial!==undefined){if(!['off','on'].includes(values.groundTrial))throw Error('Invalid groundTrial capture mode');for(const mode of modes)mode.groundTrial=values.groundTrial;}
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Less than 8 GB free; capture not started');
 await mkdir(dirname(run),{recursive:true});await mkdir(run,{recursive:false});created=true;
 report.contract={...contract,sha256:hash(JSON.stringify(contract))};
 stage='assets';console.error('web capture: preparing worktree-local assets');
 if(!await exists('web/node_modules/three'))await command('npm',['ci','--prefix',resolve(root,'web'),'--no-audit','--no-fund']);
 await command(resolve(root,'scripts/export-package.sh'),[]);
 if(contract.ladder){
  const manifest=await readJSON('Generated/package/sloans-lake/world.json');
  if(!manifest.frame.vertical.includes('y = 0 is ground'))throw Error('Web ladder requires the frozen flat-ground export datum; viewer adapter required for terrain');
  for(const scene of selected)scenes[scene].camera=inspectionCamera(contract.ladder.pose,scenes[scene].inspection.altitudeAGLMetres,manifest.frame.origin);
  report.exportFrame=manifest.frame;
  report.contract.sha256=hash(JSON.stringify({...contract,exportFrame:manifest.frame}));
 }
 // Exactly the existing bakeoff/export.sh recipe, using the release exporter already built above.
 if(selected.includes('lakeview'))await command(resolve(root,'.build/release/worldbake'),['export',resolve(root,'Data/areas/lakeview-sheil-park'),resolve(root,'web/bakeoff/generated/lakeview-sheil-park'),'--date','2026-07-15T20:00:00Z','--season','1','--focus','41.9445,-87.6660,41.9465,-87.6630','--margin','100','--version','a2-existing-exporter']);
 if(['lakeview-600','lakeview-150'].includes(values.block)){
  const manifest=await readJSON('web/bakeoff/generated/lakeview-sheil-park/world.json');
  if(!manifest.frame.vertical.includes('y = 0 is ground'))throw Error('Lakeview inspection requires its flat-ground datum');
  scenes.lakeview.camera=inspectionCamera(scenes.lakeview.inspection,scenes.lakeview.inspection.altitudeAGLMetres,manifest.frame.origin);
  scenes.lakeview.inspection.groundDatum=manifest.frame.vertical;report.exportFrame=manifest.frame;
  report.contract.sha256=hash(JSON.stringify({...contract,exportFrame:manifest.frame}));
 }
 const overrides={'/scenes.json':scenes,'/fixture.json':fixture,'/capture-probes.mjs':await readFile(resolve(root,'scripts/world_scoreboard_probes.mjs'),'utf8')};
 const probeMetadata={};
 for(const scene of selected)if(scenes[scene].templateScene){
  const template=scenes[scene].templateScene;
  overrides['/'+scene+'.html']=(await readFile(resolve(root,'web/bakeoff',template+'.html'),'utf8')).replace('data-scene="'+template+'"','data-scene="'+scene+'"');
  overrides['/data/'+scene+'-facades.json']=await readJSON('web/bakeoff/data/'+template+'-facades.json');
 }
 for(const spec of contract.exports||[]){
  const out=resolve(root,'Generated/web-capture',spec.area);
  if(values.existingExports){if(!await exists('Generated/web-capture/'+spec.area+'/world.json'))throw Error('Requested existing export is absent: '+spec.area);}
  else await command(resolve(root,'.build/release/worldbake'),['export',resolve(root,'Data/areas',spec.area),out,'--date',spec.date,'--focus',spec.focus,'--margin','100']);
  const facades=await facadeInputs(root,spec.area,out),manifest=await readJSON(out+'/world.json');
  const metadata=values.screen?await Promise.all(manifest.chunks.map(c=>readJSON(out+'/'+c.scene))):null;
  for(const scene of selected.filter(scene=>scenes[scene].area===spec.area)){
   if(scenes[scene].inspection){
    const pose=scenes[scene].inspection;
    if(!manifest.frame.vertical.includes('y = 0 is ground'))throw Error('Inspection requires flat-ground datum');
    scenes[scene].camera=inspectionCamera(pose,pose.altitudeAGLMetres,manifest.frame.origin);
    pose.groundDatum=manifest.frame.vertical;
   }
   if(metadata)probeMetadata[scene]=metadata;
   overrides['/data/'+scene+'-facades.json']=facades;
   overrides['/'+scene+'.html']=(await readFile(resolve(root,'web/bakeoff/lakeview.html'),'utf8')).replace('data-scene="lakeview"','data-scene="'+scene+'"');
  }
 }
 report.contract.sha256=hash(JSON.stringify({...contract,exportFrame:report.exportFrame??null}));
 const companions=values.groundTrial==='on'?await (await import('../web/bakeoff/prepare-ground-companions.mjs')).prepareGroundCompanions(root,contract,selected):{};
 stage='server';server=await startCaptureServer(root,overrides);report.origin=server.origin;
 for(const scene of Object.keys(identities)){const response=await fetch(`${server.origin}/${scene}.html`);if(!response.ok)throw Error('Server readiness HTTP '+response.status);}
 report.events.push({stage:'server-ready',origin:server.origin});
 stage='browser';browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,timeout:30000,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
 report.browser={version:browser.version(),engine:'Chromium via Playwright (installed Chrome)',sandbox:true};
 for(const scene of selected)for(const mode of modes)for(const repeat of (values.repeat?[false,true]:[false])){
  if(values.repeat&&report.frames.length){await browser.close();browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,timeout:30000,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});}
  stage=`capture ${scene}/${mode.foliageExp1}/${mode.crownV2}`;console.error('web capture: '+stage);
  const viewport=scenes[scene].viewport,page=await browser.newPage({viewport,deviceScaleFactor:1}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  const query=new URLSearchParams({capture:'',tier:contract.tier,...mode,...(companions[scene]?{surfaceRoles:companions[scene]}:{})}),url=`${server.origin}/${scene}.html?${query}`;
  const t=performance.now();await page.goto(url,{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForFunction(()=>{
   if(document.body.dataset.error)throw Error(document.body.dataset.error);
   const b=window.bakeoff,m=b?.metrics;if(document.body.dataset.ready!=='1'||!m||!(m.triangles>0&&m.drawCalls>0)||m.samples<3)return false;
   const key=JSON.stringify([m.triangles,m.drawCalls,m.cost?.passes,m.camera]);
   const p=window.__captureReadiness??={key:null,samples:-1,stable:0};
   if(p.samples===m.samples)return false;
   p.stable=p.key===key?p.stable+1:1;p.key=key;p.samples=m.samples;
   return p.stable>=3;
  },null,{polling:'raf',timeout:180000});
  await page.evaluate(()=>{window.bakeoff.freeze=true;});
  await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
  const evidence=await page.evaluate(()=>{const b=window.bakeoff,g=b.renderer.backend.gl;g.finish();return {groundTrialReport:b.groundTrial??null,lightTrialReport:b.lightTrial??null,paletteBReport:b.paletteB??null,sceneBudget:b.sceneBudget??null,metrics:b.metrics,foliageExp1:b.foliageExp1,crownV2:b.crownV2??false,crownBudget:b.world.crownBudget??null,crownV3:b.crownV3??false,crownV3Report:b.world.crownV3Report??null,fixture:b.fixture,projection:{near:b.camera.near,far:b.camera.far},exposure:b.policy.look.lighting.exposure,stableUpdates:window.__captureReadiness.stable};});
  verifyModes(evidence,mode);
  if((evidence.groundTrialReport?.mode??'off')!==(mode.groundTrial??'off'))throw Error('groundTrial did not resolve as requested');
  if((evidence.lightTrialReport?.mode??'off')!==(mode.lightTrial??'off'))throw Error('lightTrial did not resolve as requested');
  if((evidence.paletteBReport?.mode??'off')!==(mode.paletteB??'off'))throw Error('paletteB did not resolve as requested');
  if(values.sceneBudget!==!!evidence.sceneBudget?.enabled)throw Error('sceneBudget did not resolve as requested');
  if((evidence.crownV3||'off')!==(mode.crownV3||'off'))throw Error('crownV3 did not resolve as requested');
  verifyCounters(evidence.metrics);
  if(scenes[scene].inspection)evidence.cameraCheck=verifyLadderPose(evidence.metrics.camera,scenes[scene].inspection);
  if(values.screen){
   if(!probeMetadata[scene])throw Error('Screen requires capture-export metadata');
   evidence.detectors=await page.evaluate(async ({metadata,thresholds,viewport})=>{
    const {probeScene}=await import('/capture-probes.mjs'),T=await import('three/webgpu'),b=window.bakeoff;
    return probeScene({...b,T,spec:{viewport}},metadata,thresholds);
   },{metadata:probeMetadata[scene],thresholds:THRESHOLDS,viewport});
   const totals=passTotals(evidence.metrics.cost.passes);evidence.budgets={totals,tiers:tierChecks(totals.main,totals.shadow)};
  }
  const image=await page.screenshot({type:'png'}),pixels=verifyPixels(PNG.sync.read(image),viewport);
  if(errors.length)throw Error(errors.join('\n'));
  const filename=`${scene}-foliage-${mode.foliageExp1}-crown-${mode.crownV2}${mode.crownV3?'-v3-'+mode.crownV3:''}${mode.paletteB?'-palette-'+mode.paletteB:''}${mode.lightTrial?'-light-'+mode.lightTrial:''}${mode.groundTrial?'-ground-'+mode.groundTrial:''}${values.sceneBudget?'-scene-budget':''}${values.repeat?(repeat?'-repeat':'-fresh'):''}.png`;
  await writeFile(resolve(run,filename),image);
  report.frames.push({scene,repeat,view:identities[scene],camera:scenes[scene].camera,inspection:scenes[scene].inspection??null,date:fixture.date,...mode,url,...evidence,pixels,frame:filename,sha256:hash(image),seconds:(performance.now()-t)/1000});
  await page.close();
  if(values.repeat){
   const key=JSON.stringify([scene,mode]);
   if(!repeat)freshFrames.set(key,image);
   else{
    const fresh=freshFrames.get(key),difference={scene,...mode,png:byteDifference(fresh,image),rgba:byteDifference(PNG.sync.read(fresh).data,PNG.sync.read(image).data)};
    (report.repeatDifferences??=[]).push(difference);
    report.coverage=verifyCoverage(report.frames,{expectedDifferent:values.expectedDifferent});
    if(difference.png.differingBytes||difference.rgba.differingBytes)throw Error(`Noisy repeat: ${scene}; PNG ${difference.png.differingBytes} differing bytes; RGBA ${difference.rgba.differingBytes}, max ${difference.rgba.max}, mean ${difference.rgba.mean}; batch stopped`);
   }
  }
 }
 stage='coverage';report.coverage=verifyCoverage(report.frames,{expectedDifferent:values.expectedDifferent});
 if(server.failures.length)throw Error('Server resource failures: '+server.failures.join(', '));
 report.status='passed';
}catch(error){report.error={stage,message:error.stack||error.message};process.exitCode=1;console.error('web capture failed:',stage,error.message);}
finally{
 try{await browser?.close();}finally{await server?.close();}
 report.seconds=(performance.now()-started)/1000;
 if(created)await writeFile(resolve(run,'web-capture.json'),JSON.stringify(report,null,2)+'\n');
}
if(report.status==='passed')for(const frame of report.frames)console.log(resolve(run,frame.frame));
