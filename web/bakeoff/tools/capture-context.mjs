// Run with scripts/heavy.sh. Bakeoff-only capture: existing exporter/contracts, no shared tooling edits.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {startCaptureServer} from '../../../scripts/web_capture_server.mjs';
import {blockContract,inspectionCamera,facadeInputs} from '../../../scripts/web_capture_blocks.mjs';
import {passTotals,tierChecks,verifyLadderPose} from '../../../scripts/world_scoreboard_checks.mjs';
import {verifyPixels,byteDifference} from '../../../scripts/web_capture_checks.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
const req=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json'));
const {chromium}=req('playwright'),{PNG}=req('pngjs');
const read=async p=>JSON.parse(await readFile(resolve(root,p),'utf8'));
const out=resolve(root,process.argv[2]||'web/bakeoff/evidence/context-ring');await mkdir(dirname(out),{recursive:true});await mkdir(out,{recursive:false});
const hash=x=>createHash('sha256').update(x).digest('hex');
const run=(exe,args)=>execFileSync(resolve(root,exe),args,{cwd:root,stdio:['ignore','pipe','inherit']}).toString();
let browser,server;const report={sourceCommit:run('/usr/bin/git',['rev-parse','HEAD']).trim(),frames:[],sources:[],status:'running'};
try{
 run('.build/release/worldbake',['export',resolve(root,'Data/areas/lakeview-sheil-park'),resolve(root,'web/bakeoff/generated/lakeview-sheil-park'),'--date','2026-07-15T20:00:00Z','--season','1','--focus','41.9445,-87.6660,41.9465,-87.6630','--margin','100','--version','a5-context-control']);
 const blocks=(process.env.CONTEXT_BLOCKS||'sloans-ladder,lakeview-ladder,wilmette,west-highland').split(',');
 for(const block of blocks){
  const contract=await blockContract(root,block),overrides={'/scenes.json':contract.scenes,'/fixture.json':contract.fixture,'/context-probe.mjs':await readFile(resolve(root,'web/bakeoff/tools/context-probe.mjs'),'utf8')};
  for(const spec of contract.exports||[])run('.build/release/worldbake',['export',resolve(root,'Data/areas',spec.area),resolve(root,'Generated/web-capture',spec.area),'--date',spec.date,'--focus',spec.focus,'--margin','100']);
  for(const [id,config] of Object.entries(contract.scenes)){
   if(process.env.CONTEXT_ALTITUDE&&config.inspection?.altitudeAGLMetres!==+process.env.CONTEXT_ALTITUDE)continue;
   const area=config.area||(id.startsWith('sloans')?'sloans-lake':'lakeview-sheil-park');
   const packagePath=config.area?'Generated/web-capture/'+area:area==='sloans-lake'?'Generated/package/sloans-lake':'web/bakeoff/generated/'+area;
   const manifest=await read(packagePath+'/world.json'),metadata=await Promise.all(manifest.chunks.map(c=>read(packagePath+'/'+c.scene)));
   if(config.inspection)config.camera=inspectionCamera(config.inspection,config.inspection.altitudeAGLMetres,manifest.frame.origin);
   const contextPath=resolve(root,'web/bakeoff/generated/context',area+'.json');run('.build/release/export-context',[resolve(root,'Data/areas',area),contextPath]);
   const bytes=await readFile(contextPath),data=JSON.parse(bytes);
   for(const source of data.sources||[]){const raw=await readFile(resolve(root,'Data/areas',area,source.path));if(hash(raw)!==source.sha256||raw.length!==source.bytes)throw Error('Context source provenance mismatch: '+area+'/'+source.path);}
   overrides['/data/'+id+'-context.json']=data;
   overrides['/data/'+id+'-facades.json']=config.area?await facadeInputs(root,area,resolve(root,packagePath)):await read('web/bakeoff/data/'+config.templateScene+'-facades.json');
   overrides['/'+id+'.html']=(await readFile(resolve(root,'web/bakeoff/lakeview.html'),'utf8')).replace('data-scene="lakeview"','data-scene="'+id+'"');
   report.sources.push({id,area,status:data.status,bytes:bytes.length,sha256:hash(bytes),sources:data.sources??[],stats:data.stats??{},origin:manifest.frame.origin});
   server=await startCaptureServer(root,overrides);
   let fresh;
   for(const variant of ['off','off-repeat','on']){
    console.error(`context capture ${id} ${variant}`);
    browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
    const page=await browser.newPage({viewport:config.viewport,deviceScaleFactor:1}),errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(`${server.origin}/${id}.html?capture&still&sceneBudget=1&foliageExp1=off&crownV2=off${variant==='on'?'&contextRing=1':''}`,{waitUntil:'domcontentloaded'});
    await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);const b=window.bakeoff,m=b?.metrics;if(!m||m.samples<3)return false;const key=JSON.stringify([m.cost.passes,m.camera]),p=window.__stable??={key:null,samples:-1,n:0};if(p.samples===m.samples)return false;p.n=p.key===key?p.n+1:1;p.key=key;p.samples=m.samples;return p.n>=3;},null,{timeout:180000,polling:'raf'});
    await page.evaluate(()=>{window.bakeoff.freeze=true;});
    const e=await page.evaluate(async metadata=>{const b=window.bakeoff,T=await import('three/webgpu'),{contextBlankProbe}=await import('/context-probe.mjs');b.renderer.backend.gl.finish();return {metrics:b.metrics,context:b.contextRing??null,blank:contextBlankProbe(b,metadata,T),projection:{near:b.camera.near,far:b.camera.far},exposure:b.policy.look.lighting.exposure};},metadata);
    if(config.inspection)e.cameraCheck=verifyLadderPose(e.metrics.camera,config.inspection);
    const image=await page.screenshot(),png=PNG.sync.read(image);e.pixels=verifyPixels(png,config.viewport);
    if(errors.length)throw Error(errors.join('\n'));
    if(variant==='off')fresh=png.data;
    if(variant==='off-repeat'||variant==='on'&&data.status==='missing-context-source'){e.repeat=byteDifference(fresh,png.data);if(e.repeat.differingBytes)throw Error('Control/no-source repeat changed: '+id);}
    const totals=passTotals(e.metrics.cost.passes);e.budgets={totals,tiers:tierChecks(totals.main,totals.shadow)};
    const contextPasses=Object.entries(e.metrics.cost.passes).filter(([k])=>k.includes('/context '));
    e.contextPasses=Object.fromEntries(contextPasses);
    if(contextPasses.some(([k,v])=>k.startsWith('shadow/')&&(v.draws||v.triangles)))throw Error('Context added shadow submissions');
    const filename=id+'-'+variant+'.png';await writeFile(resolve(out,filename),image);
    report.frames.push({id,area,variant,frame:filename,sha256:hash(image),contract:{camera:config.camera,inspection:config.inspection??null,fixture:contract.fixture,viewport:config.viewport},...e});
    await writeFile(resolve(out,'manifest.json'),JSON.stringify(report,null,2)+'\n');await browser.close();browser=null;
   }
   if(server.failures.length)throw Error('Resources missing: '+server.failures.join(','));await server.close();server=null;
  }
 }
 report.status='complete';
}catch(e){report.status='failed';report.error=e.stack;process.exitCode=1;console.error(e.stack);}
finally{await browser?.close();await server?.close();await writeFile(resolve(out,'manifest.json'),JSON.stringify(report,null,2)+'\n');}
