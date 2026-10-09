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
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..'),area='greenville-downtown',out=resolve(root,'web/bakeoff/evidence/context-ring/greenville-missing-paused');
const req=createRequire(resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/package.json')),{chromium}=req('playwright'),{PNG}=req('pngjs');
const read=async p=>JSON.parse(await readFile(resolve(root,p),'utf8')),run=(exe,args)=>execFileSync(resolve(root,exe),args,{cwd:root,stdio:['ignore','pipe','inherit']});
const saved=await read('docs/scoreboard/world-scoreboard-v0.json'),row=saved.rows.find(r=>r.area===area&&r.altitude===600),packagePath='Generated/web-capture/context-greenville';
run('.build/release/worldbake',['export',resolve(root,'Data/areas',area),resolve(root,packagePath),'--date',row.date]);
run('.build/release/export-context',[resolve(root,'Data/areas',area),resolve(root,'web/bakeoff/generated/context',area+'.json')]);
const data=await read('web/bakeoff/generated/context/'+area+'.json');if(data.status!=='missing-context-source')throw Error('Data changed: use full context harness');
const world=await read(packagePath+'/world.json'),metadata=await Promise.all(world.chunks.map(c=>read(packagePath+'/'+c.scene))),viewport=row.evidence.viewport;
const spec={world:'/world/capture/context-greenville/',pose:row.pose,camera:inspectionCamera(row.pose,600,world.frame.origin),viewport,metadata,thresholds:THRESHOLDS};
const source=await readFile(resolve(root,'scripts/world_scoreboard_page.mjs'),'utf8');
const pageSource=source;
const html='<!doctype html><html><meta charset="utf-8"><style>body{margin:0}canvas{display:block}small{position:absolute;top:8px;left:8px;color:white;background:#172128b0;font:9px system-ui}</style><script type="importmap">{"imports":{"three":"/vendor/build/three.webgpu.js","three/webgpu":"/vendor/build/three.webgpu.js","three/tsl":"/vendor/build/three.tsl.js","three/addons/":"/vendor/examples/jsm/"}}</script><body><canvas></canvas><small>© OpenStreetMap contributors; see package LICENSE-DATA.md</small><script type="module" src="/missing-page.mjs"></script></body></html>';
let browser,server;const result={qualification:'same paused shipping scoreboard frame; explicit missing-data no-op only; fresh-process pixels were noisy; no bakeoff coverage qualification',frames:[],status:'failed'};await mkdir(dirname(out),{recursive:true});await mkdir(out,{recursive:false});
try{
 server=await startCaptureServer(root,{'/missing.html':html,'/missing-page.mjs':pageSource,'/scoreboard-contract.json':spec,'/scoreboard-probes.mjs':await readFile(resolve(root,'scripts/world_scoreboard_probes.mjs'),'utf8')});let control;
 browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true});const page=await browser.newPage({viewport,deviceScaleFactor:1});
 await page.goto(server.origin+'/missing.html');
 await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return window.scoreboard?.metrics?.stable>=3;},null,{timeout:180000});
 await page.evaluate(()=>{window.scoreboard.freeze=true;});
 for(const mode of ['off','on']){
  if(mode==='on')await page.evaluate(async data=>{const {installContextRing}=await import('/context-ring.js');window.scoreboard.contextRing=installContextRing(window.scoreboard,data).report;},data);
  const e=await page.evaluate(()=>{const b=window.scoreboard;b.freeze=true;b.renderer.backend.gl.finish();return {metrics:b.metrics,context:b.contextRing??null,detectors:b.probe()};});
  e.cameraCheck=verifyLadderPose(e.metrics.camera,spec.pose);const image=await page.screenshot(),png=PNG.sync.read(image);e.pixels=verifyPixels(png,viewport);
  if(mode==='off')control=png.data;else{e.difference=byteDifference(control,png.data);if(e.difference.differingBytes)throw Error('Missing-data mode changed pixels');}
  const totals=passTotals(e.metrics.passes);e.budgets={totals,tiers:tierChecks(totals.main,totals.shadow)};e.sha256=createHash('sha256').update(image).digest('hex');e.frame=mode+'.png';result.frames.push({mode,...e});await writeFile(resolve(out,e.frame),image);
 }
 result.status='passed';
}catch(e){result.error=e.stack;process.exitCode=1;}finally{await browser?.close();await server?.close();await writeFile(resolve(out,'manifest.json'),JSON.stringify(result,null,2)+'\n');}
