// Greenville lacks a bakeoff climate adapter and context: exercise fail-closed on its frozen shipping scoreboard view.
// Run under heavy.sh. This is a missing-data regression, not bakeoff look qualification.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {startCaptureServer} from '../../../scripts/web_capture_server.mjs';
import {inspectionCamera} from '../../../scripts/web_capture_blocks.mjs';
import {THRESHOLDS,passTotals,tierChecks,verifyLadderPose} from '../../../scripts/world_scoreboard_checks.mjs';
import {verifyPixels,byteDifference} from '../../../scripts/web_capture_checks.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..'),area='greenville-downtown',out=resolve(root,process.argv[2]||'web/bakeoff/evidence/context-buildings/greenville');
const req=createRequire(resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/package.json')),{chromium}=req('playwright'),{PNG}=req('pngjs');
const read=async p=>JSON.parse(await readFile(resolve(root,p),'utf8')),run=(exe,args)=>execFileSync(resolve(root,exe),args,{cwd:root,stdio:['ignore','pipe','inherit']});
const saved=await read('docs/scoreboard/world-scoreboard-v0.json'),row=saved.rows.find(r=>r.area===area&&r.altitude===600),packagePath='Generated/web-capture/context-greenville';
run('.build/release/worldbake',['export',resolve(root,'Data/areas',area),resolve(root,packagePath),'--date',row.date]);
run('.build/release/export-context',[resolve(root,'Data/areas',area),resolve(root,'web/bakeoff/generated/context',area+'.json')]);
const data=await read('web/bakeoff/generated/context/'+area+'.json');if(data.status!=='missing-context-source')throw Error('Data changed: use full context harness');
const world=await read(packagePath+'/world.json'),metadata=await Promise.all(world.chunks.map(c=>read(packagePath+'/'+c.scene))),viewport=row.evidence.viewport;
const spec={world:'/world/capture/context-greenville/',pose:row.pose,camera:inspectionCamera(row.pose,600,world.frame.origin),viewport,metadata,thresholds:THRESHOLDS};
const source=await readFile(resolve(root,'scripts/world_scoreboard_page.mjs'),'utf8');
const pageSource=source.replace(" const ledger=", `
 const query=new URLSearchParams(location.search);
 if(query.has('fixedTime')){const nf=renderer._nodes.nodeFrame,update=nf.update.bind(nf);nf.update=()=>{update();nf.time=0;nf.deltaTime=0;};nf.time=0;nf.deltaTime=0;}
 const ledger=`).replace(' renderer.setAnimationLoop', `
 if(new URLSearchParams(location.search).has('contextRing')){const {installContextRing}=await import('/context-ring.js');window.scoreboard.contextRing=installContextRing(window.scoreboard,${JSON.stringify(data)}).report;}
 renderer.setAnimationLoop`);
const html='<!doctype html><html><meta charset="utf-8"><style>body{margin:0}canvas{display:block}small{position:absolute;top:8px;left:8px;color:white;background:#172128b0;font:9px system-ui}</style><script type="importmap">{"imports":{"three":"/vendor/build/three.webgpu.js","three/webgpu":"/vendor/build/three.webgpu.js","three/tsl":"/vendor/build/three.tsl.js","three/addons/":"/vendor/examples/jsm/"}}</script><body><canvas></canvas><small>© OpenStreetMap contributors; see package LICENSE-DATA.md</small><script type="module" src="/missing-page.mjs"></script></body></html>';
let browser,server;const result={qualification:'fresh-process shipping scoreboard; raw time versus fixed shader time 0; missing-context no-op only',frames:[],status:'failed'};await mkdir(dirname(out),{recursive:true});await mkdir(out,{recursive:false});
try{
 server=await startCaptureServer(root,{'/missing.html':html,'/missing-page.mjs':pageSource,'/scoreboard-contract.json':spec,'/scoreboard-probes.mjs':await readFile(resolve(root,'scripts/world_scoreboard_probes.mjs'),'utf8')});let control;
 const controls={};
 for(const mode of ['raw-off','raw-on','fixed-off','fixed-repeat','fixed-on']){
  browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true});const page=await browser.newPage({viewport,deviceScaleFactor:1});
  await page.goto(server.origin+'/missing.html?'+(mode.startsWith('fixed')?'fixedTime&':'')+(mode.endsWith('-on')?'contextRing=1':''));
  await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return window.scoreboard?.metrics?.stable>=3;},null,{timeout:180000});
  const e=await page.evaluate(()=>{const b=window.scoreboard;b.freeze=true;b.renderer.backend.gl.finish();return {metrics:b.metrics,shaderTime:b.renderer._nodes.nodeFrame.time,context:b.contextRing??null,detectors:b.probe()};});
  const image=await page.screenshot({timeout:120000}),png=PNG.sync.read(image);e.frame=mode+'.png';
  // Persist the candidate BEFORE any assertion, including dimension/camera/no-op checks.
  await writeFile(resolve(out,e.frame),image);
  const family=mode.split('-')[0];
  if(mode.endsWith('-off'))controls[family]=png;
  else {const prior=controls[family];e.difference=byteDifference(prior.data,png.data);
   const diff=new PNG({width:png.width,height:png.height});for(let i=0;i<png.data.length;i+=4){for(let c=0;c<3;c++)diff.data[i+c]=Math.min(255,Math.abs(png.data[i+c]-prior.data[i+c])*16);diff.data[i+3]=255;}
   e.diffFrame=mode+'-diff-x16.png';await writeFile(resolve(out,e.diffFrame),PNG.sync.write(diff));
  }
  e.cameraCheck=verifyLadderPose(e.metrics.camera,spec.pose);e.pixels=verifyPixels(png,viewport);
  const totals=passTotals(e.metrics.passes);e.budgets={totals,tiers:tierChecks(totals.main,totals.shadow)};e.sha256=createHash('sha256').update(image).digest('hex');result.frames.push({mode,...e});
  await writeFile(resolve(out,'manifest.json'),JSON.stringify(result,null,2)+'\n');await browser.close();browser=null;
 }
 if(result.frames.some(f=>f.mode.startsWith('fixed')&&f.difference?.differingBytes))throw Error('Fixed-time fresh-process no-op changed pixels; evidence saved');
 result.status='passed';
}catch(e){result.error=e.stack;process.exitCode=1;}finally{await browser?.close();await server?.close();await writeFile(resolve(out,'manifest.json'),JSON.stringify(result,null,2)+'\n');}
