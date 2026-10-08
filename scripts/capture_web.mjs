// One-command capture worker. scripts/capture-web.sh owns heavy admission.
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {mkdir,readFile,writeFile,access,statfs} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {createHash,randomUUID} from 'node:crypto';
import {parseArgs} from 'node:util';
import {modeQueries,verifyCounters,verifyCoverage,verifyPixels} from './web_capture_checks.mjs';
import {startCaptureServer} from './web_capture_server.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const {values}=parseArgs({options:{output:{type:'string'},matrix:{type:'boolean'},foliage:{type:'string',default:'off'},crown:{type:'string',default:'off'},'web-fixtures':{type:'boolean'}}});
const runtime=process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules');
const require=createRequire(resolve(runtime,'package.json'));
const {chromium}=require('playwright'),{PNG}=require('pngjs');
const run=resolve(values.output||resolve(root,'.build/lookloop/web-'+randomUUID()));
const readJSON=async path=>JSON.parse(await readFile(resolve(root,path),'utf8'));
const hash=data=>createHash('sha256').update(data).digest('hex');
let browser,server,created=false,stage='contract';
const report={status:'failed',frames:[],events:[],startedUTC:new Date().toISOString()};
const started=performance.now();
async function command(executable,args){
 await new Promise((ok,no)=>{const child=spawn(executable,args,{cwd:root,env:process.env,stdio:['ignore','pipe','pipe']});
 child.stdout.on('data',x=>process.stderr.write(x));child.stderr.on('data',x=>process.stderr.write(x));child.on('error',no);child.on('exit',code=>code===0?ok():no(Error(`${executable} exited ${code}`)));});
}
async function exists(path){try{await access(resolve(root,path));return true;}catch{return false;}}
try{
 const contract=await readJSON('docs/lookloop/a3-capture-contract.json');
 if(!values['web-fixtures'])throw Error('A3 contract currently describes native cameras/dates; web capture requires an approved web fixture mapping (--web-fixtures), not a silent native-to-web substitution');
 const scenes=await readJSON('web/bakeoff/scenes.json'),fixture=await readJSON('web/bakeoff/fixture.json');
 const identities={sloans:'ordinary-street-afternoon',lakeview:'lakeview-postcard-afternoon'};
 for(const [scene,id] of Object.entries(identities))if(!scenes[scene]||!contract.views.some(v=>v.id===id))throw Error('Frozen scene/view identity missing: '+scene);
 const modes=modeQueries({foliage:values.foliage,crown:values.crown,matrix:values.matrix});
 if(modes.some(m=>m.crownV2==='on')&&!(await readFile(resolve(root,'web/bakeoff/main.js'),'utf8')).includes('crownV2'))throw Error('crownV2=on is unsupported by this checkout; do not label an unchanged frame as the prototype');
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Less than 8 GB free; capture not started');
 await mkdir(dirname(run),{recursive:true});await mkdir(run,{recursive:false});created=true;
 report.contract={nativeSource:'docs/lookloop/a3-capture-contract.json',nativeSha256:hash(JSON.stringify(contract)),nativeParity:false,identities,webScenes:scenes,webFixture:fixture};
 stage='assets';console.error('web capture: preparing worktree-local assets');
 if(!await exists('web/node_modules/three'))await command('npm',['ci','--prefix',resolve(root,'web'),'--no-audit','--no-fund']);
 await command(resolve(root,'scripts/export-package.sh'),[]);
 // Exactly the existing bakeoff/export.sh recipe, using the release exporter already built above.
 await command(resolve(root,'.build/release/worldbake'),['export',resolve(root,'Data/areas/lakeview-sheil-park'),resolve(root,'web/bakeoff/generated/lakeview-sheil-park'),'--date','2026-07-15T20:00:00Z','--season','1','--focus','41.9445,-87.6660,41.9465,-87.6630','--margin','100','--version','a2-existing-exporter']);
 stage='server';server=await startCaptureServer(root);report.origin=server.origin;
 for(const scene of Object.keys(identities)){const response=await fetch(`${server.origin}/${scene}.html`);if(!response.ok)throw Error('Server readiness HTTP '+response.status);}
 report.events.push({stage:'server-ready',origin:server.origin});
 stage='browser';browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,timeout:30000,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
 report.browser={version:browser.version(),engine:'Chromium via Playwright (installed Chrome)',sandbox:true};
 for(const scene of ['sloans','lakeview'])for(const mode of modes){
  stage=`capture ${scene}/${mode.foliageExp1}/${mode.crownV2}`;console.error('web capture: '+stage);
  const viewport=scenes[scene].viewport,page=await browser.newPage({viewport,deviceScaleFactor:1}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  const query=new URLSearchParams({capture:'',still:'',tier:'standard',...mode}),url=`${server.origin}/${scene}.html?${query}`;
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
  const evidence=await page.evaluate(()=>{const b=window.bakeoff,g=b.renderer.backend.gl;g.finish();return {metrics:b.metrics,foliageExp1:b.foliageExp1,crownV2:b.crownV2??false,fixture:b.fixture,stableUpdates:window.__captureReadiness.stable};});
  if(evidence.foliageExp1!==mode.foliageExp1||evidence.crownV2!==(mode.crownV2==='on'))throw Error('Rendered experiment modes differ from requested query');
  verifyCounters(evidence.metrics);
  const image=await page.screenshot({type:'png'}),pixels=verifyPixels(PNG.sync.read(image),viewport);
  if(errors.length)throw Error(errors.join('\n'));
  const filename=`${scene}-foliage-${mode.foliageExp1}-crown-${mode.crownV2}.png`;
  await writeFile(resolve(run,filename),image);
  report.frames.push({scene,view:identities[scene],...mode,url,...evidence,pixels,frame:filename,sha256:hash(image),seconds:(performance.now()-t)/1000});
  await page.close();
 }
 stage='coverage';verifyCoverage(report.frames);
 if(server.failures.length)throw Error('Server resource failures: '+server.failures.join(', '));
 report.status='passed';
}catch(error){report.error={stage,message:error.stack||error.message};process.exitCode=1;console.error('web capture failed:',stage,error.message);}
finally{
 try{await browser?.close();}finally{await server?.close();}
 report.seconds=(performance.now()-started)/1000;
 if(created)await writeFile(resolve(run,'web-capture.json'),JSON.stringify(report,null,2)+'\n');
}
if(report.status==='passed')for(const frame of report.frames)console.log(resolve(run,frame.frame));
