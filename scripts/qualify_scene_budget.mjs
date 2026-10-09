// Scripted camera qualification. scripts/qualify-scene-budget.sh owns admission.
import {readFile,writeFile,appendFile,mkdir,statfs} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {createHash} from 'node:crypto';
import {parseArgs} from 'node:util';
import {setTimeout as sleep} from 'node:timers/promises';
import {blockContract} from './web_capture_blocks.mjs';
import {startCaptureServer} from './web_capture_server.mjs';
import {verifyPixels} from './web_capture_checks.mjs';
import {instrumentBudgetSource,pathSamples,pathPose,distribution,installBufferProbe} from './scene_budget_qualification_helpers.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const {values}=parseArgs({options:{path:{type:'string'},mode:{type:'string'},output:{type:'string'},fps:{type:'string',default:'30'},static600:{type:'boolean',default:false},globalStatic:{type:'boolean',default:false}}});
if(!['pan','descent'].includes(values.path)||!['off','on'].includes(values.mode)||!values.output)throw Error('Required: --path pan|descent --mode off|on --output NEW_DIR');
if(values.globalStatic&&(!values.static600||values.mode!=='on')||values.static600&&values.path!=='descent')throw Error('Static diagnostic requires the variant and descent pose');
const fps=+values.fps;if(!Number.isInteger(fps)||fps<2||fps>60)throw Error('Invalid fixed rate');
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json')),{chromium}=require('playwright'),{PNG}=require('pngjs');
const hash=b=>createHash('sha256').update(b).digest('hex'),output=resolve(values.output),report={status:'failed',path:values.path,mode:values.mode,fps,simulationSeconds:values.static600?0:10,sampleFrames:values.static600?[0]:pathSamples(fps),frames:[],startedUTC:new Date().toISOString()};
let browser,server,page,created=false;
for(const sig of ['SIGINT','SIGTERM'])process.once(sig,()=>{report.interruptedBy=sig;const timer=setTimeout(()=>process.exit(130),8000);timer.unref();browser?.close().catch(()=>{});});
try{
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Less than 8 GiB free');
 await mkdir(output,{recursive:false});created=true;
 const contract=await blockContract(root,'sloans-ladder'),id=values.path==='pan'?'sloans-150':'sloans-600',config=contract.scenes[id];
 const files=['web/bakeoff/main.js','web/bakeoff/scene-budget.js','web/bakeoff/scene-budget-entry.js','web/bakeoff/scene-budget-qualification-entry.js','scripts/scene_budget_qualification_helpers.mjs','scripts/qualify_scene_budget.mjs'];report.sourceHashes={};for(const f of files)report.sourceHashes[f]=hash(await readFile(resolve(root,f)));
 const source=await readFile(resolve(root,'web/bakeoff/scene-budget.js'),'utf8');let instrumented=instrumentBudgetSource(source);if(values.globalStatic){const key='o.userData.costCategory,cell,o.material.transparent?o.uuid:null';if(instrumented.split(key).length!==2)throw Error('Global static diagnostic anchor mismatch');instrumented=instrumented.replace(key,'o.userData.costCategory,o.material.transparent?o.uuid:null');}report.globalStaticDiagnostic=values.globalStatic;report.instrumentedSourceSHA256=hash(instrumented);
 const html=(await readFile(resolve(root,'web/bakeoff/sloans.html'),'utf8')).replace('data-scene="sloans"','data-scene="'+id+'"').replace('src="entry.js"','src="scene-budget-qualification-entry.js"');
 server=await startCaptureServer(root,{['/'+id+'.html']:html,'/scenes.json':contract.scenes,'/fixture.json':contract.fixture,['/data/'+id+'-facades.json']:JSON.parse(await readFile(resolve(root,'web/bakeoff/data/sloans-facades.json'))),'/scene-budget.js':instrumented});
 browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,args:['--enable-precise-memory-info','--disable-background-timer-throttling','--disable-renderer-backgrounding']});report.browserVersion=browser.version();
 page=await browser.newPage({viewport:config.viewport,deviceScaleFactor:1});const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.addInitScript(installBufferProbe);
 report.url=server.origin+'/'+id+'.html?capture&foliageExp1=off&crownV2=off'+(values.mode==='on'?'&sceneBudget=1':'');await page.goto(report.url,{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return !!window.__qualification;},null,{timeout:180000});
 const origin=await page.evaluate(()=>window.bakeoff.camera.position.toArray()),cdp=await page.context().newCDPSession(page);report.origin=origin;report.contract=contract;
 const initial=pathPose(values.path,0,fps,origin);for(let i=0;i<3;i++)await page.evaluate(p=>window.__qualification.step(p),initial);
 await cdp.send('HeapProfiler.collectGarbage');report.startHeap=await cdp.send('Runtime.getHeapUsage');
 const start=performance.now();report.memoryStart=await page.evaluate(()=>window.bakeoff.renderer.backend.gl.__qualificationProbe.snapshot());
 for(let k=0;k<=(values.static600?0:10*fps);k++){
  const delay=start+k*1000/fps-performance.now();if(delay>0)await sleep(delay);
  const sample=report.sampleFrames.includes(k),pose=pathPose(values.path,k,fps,origin),frame=await page.evaluate(({pose,sample})=>window.__qualification.step(pose,sample),{pose,sample});
  if(frame.resolved.sceneBudget!==(values.mode==='on')||frame.resolved.foliage!=='off'||frame.resolved.crownV2||frame.resolved.crownV3)throw Error('Wrong resolved motion mode');
  Object.assign(frame,{index:k,simulationTimeSeconds:k/fps,wallTimeSeconds:(performance.now()-start)/1000,pose,sample});
  if(frame.pixelData){const {width,height,base64}=frame.pixelData,raw=Buffer.from(base64,'base64'),pixels=Buffer.alloc(raw.length);for(let y=0;y<height;y++)raw.copy(pixels,y*width*4,(height-1-y)*width*4,(height-y)*width*4);verifyPixels({width,height,data:pixels},config.viewport);const png=PNG.sync.write({width,height,data:pixels}),file=`${values.path}-${values.mode}-${String(k).padStart(3,'0')}.png`;await writeFile(resolve(output,file),png);frame.image={file,sha256:hash(png),width,height};delete frame.pixelData;}
  report.frames.push(frame);await appendFile(resolve(output,'frames.ndjson'),JSON.stringify(frame)+'\n');if(k%fps===0)console.error(`qualification ${values.path}/${values.mode}: ${k}/${10*fps} completed`);
  if(errors.length)throw Error(errors.join('\n'));
 }
 report.actualWallSeconds=(performance.now()-start)/1000;report.endHeapBeforeGC=await cdp.send('Runtime.getHeapUsage');await cdp.send('HeapProfiler.collectGarbage');report.endHeapAfterGC=await cdp.send('Runtime.getHeapUsage');report.buffersAfterGC=await page.evaluate(()=>window.bakeoff.renderer.backend.gl.__qualificationProbe.snapshot());
 const get=k=>report.frames.map(f=>f.cpu[k]);report.cpu={selectionMs:distribution(get('selectionMs')),poolingMs:distribution(get('poolingMs')),maintenanceMs:distribution(get('maintenanceMs')),totalMs:distribution(report.frames.map(f=>f.cpu.selectionMs+f.cpu.poolingMs+f.cpu.maintenanceMs)),instrumentedCompletedFrameMs:distribution(report.frames.map(f=>f.frameMs))};
 report.memoryEnd=report.frames.at(-1).buffers;report.overDrawFloor=report.frames.filter(f=>Object.entries(f.passes).filter(([k])=>k.startsWith('main/')).reduce((a,[,v])=>a+v.draws,0)>100).map(f=>f.index);
 report.framesOverTimeBudget=report.frames.filter(f=>f.frameMs>1000/fps).map(f=>f.index);report.status='completed';if(server.failures.length)throw Error('Server resource failures: '+server.failures.join(', '));
}catch(e){report.status='failed';report.error=e.stack||e.message;process.exitCode=1;console.error(report.error);}
finally{if(report.frames.length&&!report.cpu)report.cpu={selectionMs:distribution(report.frames.map(f=>f.cpu.selectionMs)),poolingMs:distribution(report.frames.map(f=>f.cpu.poolingMs)),maintenanceMs:distribution(report.frames.map(f=>f.cpu.maintenanceMs))};await browser?.close();await server?.close();if(created)await writeFile(resolve(output,'qualification.json'),JSON.stringify(report,null,2)+'\n');}
console.log(JSON.stringify({status:report.status,path:values.path,mode:values.mode,output,cpu:report.cpu,overDrawFloor:report.overDrawFloor?.length,actualWallSeconds:report.actualWallSeconds,memoryStart:report.memoryStart,memoryEnd:report.memoryEnd,error:report.error}));
