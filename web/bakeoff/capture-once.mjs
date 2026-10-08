// Run under scripts/heavy.sh. Uses installed laptop Chrome, not a synthetic timing estimate.
import {createRequire} from 'node:module';
import {mkdir,writeFile,readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {homedir} from 'node:os';
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json'));
const scenes=JSON.parse(await readFile(new URL("./scenes.json",import.meta.url),"utf8"));
const {chromium}=require('playwright');
const browser=await chromium.launch({channel:'chrome',headless:false,args:['--window-position=0,0','--disable-background-timer-throttling','--disable-renderer-backgrounding']});
try{
 for(const scene of (process.env.SCENES||'lakeview,sloans').split(','))for(const mode of (process.env.MODES||'baseline,candidate').split(',')){
 const viewport=scenes[scene].viewport;
 const page=await browser.newPage({viewport,deviceScaleFactor:1});const errors=[];page.on('pageerror',e=>{errors.push(e.stack||e.message);console.error(e.stack||e.message);page.evaluate(message=>{document.body.dataset.error=message;},e.stack||e.message).catch(()=>{});});page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto(`http://127.0.0.1:8782/${scene}.html?capture${mode==='baseline'?'&baseline':''}${process.env.CAMERA_QUERY||''}`);
 await page.waitForFunction(()=>document.body.dataset.ready==='1'||document.body.dataset.error,null,{timeout:180000});
 console.log(`${scene}/${mode}: first frame ready`);
 const failure=await page.evaluate(()=>document.body.dataset.error);if(failure)throw Error(failure);
 await page.waitForTimeout(2500);
 await page.evaluate(()=>window.bakeoff.resetMetrics());
 await page.waitForTimeout(10000);
 const metrics=await page.evaluate(()=>({...window.bakeoff.metrics,gpu:(()=>{const g=window.bakeoff.renderer.backend.gl,e=g.getExtension('WEBGL_debug_renderer_info');return g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER);})()}));
 if(!(metrics.triangles>0&&metrics.drawCalls>0&&Number.isFinite(metrics.fps)))throw Error('Renderer produced invalid metrics');
 if(scene==='sloans'&&metrics.camera.direction[0]>=0)throw Error('Sloan camera must face west');
 const dir=`web/bakeoff/evidence/${mode}`;await mkdir(dir,{recursive:true});await page.evaluate(()=>{window.bakeoff.freeze=true;});await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));await page.screenshot({path:`${dir}/${scene}.png`});await writeFile(`${dir}/${scene}.json`,JSON.stringify({...metrics,capturedUTC:new Date().toISOString(),errors},null,2));console.log(JSON.stringify({...metrics,errors}));if(errors.length)throw Error(errors.join('\n'));await page.close();
 }
}finally{await browser.close();}
