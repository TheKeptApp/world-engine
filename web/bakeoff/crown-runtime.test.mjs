// One fresh, sandboxed Chrome + loopback server per invocation. Run via heavy.sh.
import {createRequire} from 'node:module';
import {createHash} from 'node:crypto';
import {homedir} from 'node:os';
import {resolve} from 'node:path';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
const [scene='sloans',mode='off',label='runtime']=process.argv.slice(2);
assert(['sloans','lakeview'].includes(scene));assert(['off','standard','floor'].includes(mode));assert(/^[a-z0-9-]+$/.test(label));
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json'));
const {chromium}=require('playwright');
const scenes=JSON.parse(await readFile('web/bakeoff/scenes.json'));
const server=spawn(process.execPath,['web/bakeoff/serve.mjs'],{env:{...process.env,PORT:'8783'},stdio:['ignore','pipe','pipe']});
let browser,page;const errors=[],warnings=[],started=Date.now();const result={scene,mode,label,status:'failed',sourceHashes:{}};
for(const f of ['main.js','foliage.js','shadow-casters.js','crown-runtime.test.mjs','scenes.json','fixture.json'])result.sourceHashes[f]=createHash('sha256').update(await readFile('web/bakeoff/'+f)).digest('hex');
try{
 await new Promise((ok,no)=>{server.once('error',no);server.once('exit',code=>no(Error('Server exited '+code)));server.stdout.on('data',s=>{if(s.toString().includes('Bake-off:'))ok();});server.stderr.on('data',s=>errors.push(s.toString()));});
 browser=await chromium.launch({channel:'chrome',headless:true,chromiumSandbox:true,timeout:30000});
 result.browser=browser.version();page=await browser.newPage({viewport:scenes[scene].viewport,deviceScaleFactor:1});
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());else if(m.type()==='warning')warnings.push(m.text());});
 await page.goto(`http://127.0.0.1:8783/${scene}.html?capture&crownV2=${mode}&foliageExp1=off`,{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return document.body.dataset.ready==='1'&&window.bakeoff?.metrics?.samples>=60;},null,{timeout:60000});
 result.secondsToReady=(Date.now()-started)/1000;
 Object.assign(result,await page.evaluate(()=>{const b=window.bakeoff,gl=b.renderer.backend.gl,e=gl.getExtension('WEBGL_debug_renderer_info');gl.finish();return {metrics:b.metrics,resolvedMode:b.crownV2,gpu:gl.getParameter(e?e.UNMASKED_RENDERER_WEBGL:gl.RENDERER),allocation:b.world.crownBudget};}));
 assert.equal(result.resolvedMode,mode==='off'?false:mode);assert.equal(errors.length,0,errors.join('\n'));
 const passes=result.metrics.cost.passes,sums={};for(const [key,v]of Object.entries(passes)){const phase=key.split('/')[0],a=sums[phase]??={triangles:0,draws:0};a.triangles+=v.triangles;a.draws+=v.draws;}
 result.measured=sums;assert.equal(Object.values(sums).reduce((n,x)=>n+x.triangles,0),result.metrics.triangles);assert.equal(Object.values(sums).reduce((n,x)=>n+x.draws,0),result.metrics.drawCalls);
 if(mode==='standard'){assert(sums.main.triangles<=500000&&sums.main.draws<=120);if(scene==='sloans')assert(result.metrics.drawCalls<=120&&result.metrics.triangles<=500000);}
 if(mode==='floor')assert(sums.main.triangles<400000&&sums.main.draws<=100);assert(sums.shadow.triangles<=150000);
 result.status='passed';
}catch(e){result.error=e.stack||String(e);if(page)result.diagnostic=await page.evaluate(()=>({status:document.querySelector('#status')?.textContent,ready:document.body.dataset.ready,error:document.body.dataset.error,mode:window.bakeoff?.crownV2})).catch(()=>null);process.exitCode=1;}
finally{await browser?.close();server.kill();await new Promise(r=>server.exitCode!==null?r():server.once('exit',r));result.errors=errors;result.warnings=[...new Set(warnings)];await mkdir('web/bakeoff/evidence/crown-v2/runtime',{recursive:true});await writeFile(`web/bakeoff/evidence/crown-v2/runtime/${label}-${scene}-${mode}.json`,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({status:result.status,scene,mode,seconds:result.secondsToReady,measured:result.measured,error:result.error,diagnostic:result.diagnostic,errors,warnings:result.warnings.slice(0,4)}));}
