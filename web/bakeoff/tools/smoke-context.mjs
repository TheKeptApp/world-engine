// Run under heavy.sh: verify the normal preview data URL path, not only capture overrides.
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {startCaptureServer} from '../../../scripts/web_capture_server.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..'),req=createRequire(resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/package.json')),{chromium}=req('playwright');
let server,browser;
try{
 server=await startCaptureServer(root);browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true});
 for(const mode of ['off','on']){
  const page=await browser.newPage({viewport:{width:390,height:585}}),requests=[];page.on('request',r=>{if(r.url().includes('/generated/context/'))requests.push(r.url());});
  await page.goto(server.origin+'/sloans.html?capture&still&sceneBudget=1'+(mode==='on'?'&contextRing=1':''));
  await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return window.bakeoff?.metrics?.triangles>0;},null,{timeout:180000});
  const report=await page.evaluate(()=>({context:window.bakeoff.contextRing??null,passes:window.bakeoff.metrics.cost.passes}));
  if(mode==='off'&&(requests.length||report.context))throw Error('OFF fetched or installed context');
  if(mode==='on'&&(!report.context?.enabled||report.context.status!=='available'||requests.length!==1))throw Error('Normal preview URL did not load context');
  console.log(JSON.stringify({mode,contextRequests:requests.length,status:report.context?.status??'off'}));await page.close();
 }
 if(server.failures.length)throw Error('Missing preview resources: '+server.failures.join(','));
}finally{await browser?.close();await server?.close();}
