// Run under scripts/heavy.sh. Uses installed laptop Chrome, not a synthetic timing estimate.
import {freezeInputs} from './freeze.mjs';
import {createRequire} from 'node:module';
import {mkdir,writeFile,readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {homedir} from 'node:os';
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json'));
const scenes=JSON.parse(await readFile(new URL("./scenes.json",import.meta.url),"utf8"));
const {chromium}=require('playwright');
const order=(process.env.SCENES||'sloans,lakeview').split(',');
const frozen=await freezeInputs(),events=[];
const checkFrozen=async stage=>{const current=await freezeInputs();if(current.sha256!==frozen.sha256)throw Error(`Hold-out invalid: inputs changed at ${stage}`);events.push({stage,utc:new Date().toISOString(),sha256:current.sha256});};
const browser=await chromium.launch({channel:'chrome',headless:false,args:['--window-position=0,0','--disable-background-timer-throttling','--disable-renderer-backgrounding']});
try{
 for(const scene of order)for(const mode of (process.env.MODES||'baseline,candidate').split(','))for(const tier of (mode==='baseline'?['standard']:(process.env.TIERS||'standard').split(','))){
 await checkFrozen(`${scene}/${mode}/${tier}/before`);
 const viewport=scenes[scene].viewport;
 const page=await browser.newPage({viewport,deviceScaleFactor:1});const errors=[];page.on('pageerror',e=>{errors.push(e.stack||e.message);console.error(e.stack||e.message);page.evaluate(message=>{document.body.dataset.error=message;},e.stack||e.message).catch(()=>{});});page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto(`http://127.0.0.1:8782/${scene}.html?capture${mode==='baseline'?'&baseline':''}&tier=${tier}`);
 await page.waitForFunction(()=>document.body.dataset.ready==='1'||document.body.dataset.error,null,{timeout:180000});
 console.log(`${scene}/${mode}: first frame ready`);
 const failure=await page.evaluate(()=>document.body.dataset.error);if(failure)throw Error(failure);
 await page.waitForTimeout(2500);
 await page.evaluate(()=>window.bakeoff.resetMetrics());
 await page.waitForTimeout(10000);
 const metrics=await page.evaluate(()=>({...window.bakeoff.metrics,gpu:(()=>{const g=window.bakeoff.renderer.backend.gl,e=g.getExtension('WEBGL_debug_renderer_info');return g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER);})()}));
 if(!(metrics.triangles>0&&metrics.drawCalls>0&&Number.isFinite(metrics.fps)))throw Error('Renderer produced invalid metrics');
 if(scene==='sloans'&&metrics.camera.direction[0]>=0)throw Error('Sloan camera must face west');
 await checkFrozen(`${scene}/${mode}/${tier}/after`);
 const resolved=await page.evaluate(()=>({policy:window.bakeoff.policy,fixture:window.bakeoff.fixture,species:window.bakeoff.species}));
 const dir=`web/bakeoff/evidence/${mode}${tier==='standard'?'':'-'+tier}`;await mkdir(dir,{recursive:true});await page.evaluate(()=>{window.bakeoff.freeze=true;});await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await page.screenshot({path:`${dir}/${scene}.png`});await writeFile(`${dir}/${scene}.json`,JSON.stringify({...metrics,inputSha256:frozen.sha256,resolved,capturedUTC:new Date().toISOString(),errors},null,2));console.log(JSON.stringify({...metrics,cost:metrics.cost?{passes:metrics.cost.passes,contentTextureMiB:metrics.cost.contentTextureMiB,targetTextureMiB:metrics.cost.targetTextureMiB,renderbufferMiB:metrics.cost.renderbufferMiB,unknownAllocations:metrics.cost.unknownAllocations}:null,errors}));if(errors.length)throw Error(errors.join('\n'));await page.close();
 }
 if(order.join(',')==='sloans,lakeview'&&!process.env.MODES)await writeFile('web/bakeoff/evidence/holdout-proof.json',JSON.stringify({order,unchanged:true,...frozen,events},null,2)+'\n');
}finally{await browser.close();}
