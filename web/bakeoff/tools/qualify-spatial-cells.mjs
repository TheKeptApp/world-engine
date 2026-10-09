#!/usr/bin/env node
// Run under scripts/heavy.sh. Uses existing packages; never exports shipping geometry.
import {readFile,writeFile,mkdir,statfs} from 'node:fs/promises';import {resolve,dirname} from 'node:path';import {fileURLToPath} from 'node:url';import {createRequire} from 'node:module';import {homedir} from 'node:os';import {createHash} from 'node:crypto';
import {startCaptureServer} from '../../../scripts/web_capture_server.mjs';import {blockContract,inspectionCamera} from '../../../scripts/web_capture_blocks.mjs';import {byteDifference} from '../../../scripts/web_capture_checks.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..'),[family,area,destination]=process.argv.slice(2),out=resolve(destination??'');
if(!['bakeoff','scoreboard'].includes(family)||!area||!destination)throw Error('Usage: qualify-spatial-cells.mjs bakeoff|scoreboard area output-directory');
const require=createRequire(resolve(process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'),'package.json')),{chromium}=require('playwright'),{PNG}=require('pngjs');
const json=async p=>JSON.parse(await readFile(resolve(root,p),'utf8')),sha=b=>createHash('sha256').update(b).digest('hex');
const overrides={},report={family,area,status:'running',frames:[],sourceHashes:{},startedUTC:new Date().toISOString(),controlGate:{maxByte:2,meanByte:.001},losslessGate:{maxByte:0,meanByte:0}};let server,browser;
for(const signal of ['SIGTERM','SIGINT'])process.once(signal,()=>{Promise.allSettled([browser?.close(),server?.close()]).finally(()=>process.exit(130));});
function regions(a,b,width,height){const keys=new Set();for(let i=0;i<a.length;i+=4)if(a.slice(i,i+4).some((v,j)=>v!==b[i+j]))keys.add(`${Math.floor((i/4%width)/32)*32},${Math.floor(Math.floor(i/4/width)/32)*32}`);return [...keys].map(k=>k.split(',').map(Number));}
try{
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Disk guard under 8 GB');await mkdir(out,{recursive:false});
 for(const name of ['web/bakeoff/spatial-cells.js','web/bakeoff/spatial-cells-entry.js','web/bakeoff/main.js','web/src/world.js','scripts/world_scoreboard_page.mjs','web/bakeoff/entry.js','web/bakeoff/tools/qualify-spatial-cells.mjs','web/bakeoff/spatial-diagnostics.js'])report.sourceHashes[name]=sha(await readFile(resolve(root,name)));
 let views;
 if(family==='bakeoff'){
  if(!['sloans','lakeview'].includes(area))throw Error('Bakeoff scope is Sloan/Lakeview only');const contract=await blockContract(root,area==='sloans'?'sloans-ladder':'lakeview-ladder');
  const world=await json(area==='sloans'?'Generated/package/sloans-lake/world.json':'web/bakeoff/generated/lakeview-sheil-park/world.json');
  views=Object.entries(contract.scenes).map(([id,s])=>{s.camera=inspectionCamera(s.inspection,s.inspection.altitudeAGLMetres,world.frame.origin);return {id,altitude:s.inspection.altitudeAGLMetres,config:s};});
  overrides['/scenes.json']=contract.scenes;overrides['/fixture.json']=contract.fixture;
  for(const v of views){overrides['/'+v.id+'.html']=(await readFile(resolve(root,'web/bakeoff/'+area+'.html'),'utf8')).replace('data-scene="'+area+'"','data-scene="'+v.id+'"');overrides['/data/'+v.id+'-facades.json']=await json('web/bakeoff/data/'+area+'-facades.json');}
 }else{
  const scoreboard=await json('docs/scoreboard/world-scoreboard-v0.json'),old=scoreboard.rows.filter(r=>r.area===area);if(old.length!==3)throw Error('Unknown scoreboard area');
  const world=await json('Generated/web-capture/scoreboard-'+area+'/world.json');views=old.map(r=>({id:r.key,altitude:r.altitude,row:r,world,camera:inspectionCamera(r.pose,r.altitude,world.frame.origin)}));
  overrides['/scoreboard.html']='<!doctype html><html><style>body{margin:0}canvas{display:block;width:100vw;height:100vh}small{position:absolute;left:8px;top:8px;background:#172128b0;color:white;font:9px system-ui;padding:3px 6px}</style><script type="importmap">{"imports":{"three":"/vendor/build/three.webgpu.js","three/webgpu":"/vendor/build/three.webgpu.js","three/tsl":"/vendor/build/three.tsl.js","three/addons/":"/vendor/examples/jsm/"}}</script><body><canvas></canvas><small>© OpenStreetMap contributors · Overture Maps · USGS 3DEP; see package LICENSE-DATA.md</small><script type="module" src="/scoreboard-page.mjs"></script></body></html>';
  let source=await readFile(resolve(root,'scripts/world_scoreboard_page.mjs'),'utf8');
  for(const anchor of [" const world=new WorldScene(spec.world);await world.load();",' let prior=','  renderer.info.reset();',"backend:'WebGL2',crownV2",'ledger.reset();post.render();samples++;'])if(source.split(anchor).length!==2)throw Error('Scoreboard capture anchor changed: '+anchor);
  source=source.replace('ledger.reset();post.render();samples++;','ledger.reset();renderer._nodes.nodeFrame.time=0;renderer._nodes.nodeFrame.deltaTime=0;post.render();samples++;');
  report.captureClock={seconds:0,captureOnly:true,method:'served scoreboard NodeFrame time/deltaTime pin'};
  source=source.replace(" const world=new WorldScene(spec.world);await world.load();",` const active=new URLSearchParams(location.search).get('spatialCells')==='1',features=new WeakMap(),remove=T.BufferGeometry.prototype.deleteAttribute;
 if(active)T.BufferGeometry.prototype.deleteAttribute=function(n){if(n==='_feature')features.set(this,this.attributes[n]);return remove.call(this,n);};
 const world=new WorldScene(spec.world);try{await world.load();}finally{T.BufferGeometry.prototype.deleteAttribute=remove;}`);
  source=source.replace(' let prior=',` let spatial,proxies=[];
 if(active){const {installSpatialCells}=await import('/spatial-cells.js'),sidecar=await (await fetch(spec.world+'spatial-cells.json')).json();
 scene.updateMatrixWorld(true);scene.traverse(o=>{if(o.isMesh&&o.castShadow){const p=o.clone();p.layers.set(1);p.matrixAutoUpdate=false;p.matrix.copy(o.matrixWorld);proxies.push([o,p]);}});for(const [,p]of proxies)scene.add(p);scene.traverse(o=>{if(o.isLight&&o.shadow)o.shadow.camera.layers.enable(1);});
 spatial=installSpatialCells(scene,camera,{renderer,features,sidecar});}
 let prior=`);
  source=source.replace('  renderer.info.reset();',`  if(spatial){for(const [o,p]of proxies){p.geometry=o.geometry;p.visible=o.visible;p.count=o.count;if(o.isInstancedMesh)p.instanceMatrix=o.instanceMatrix;}spatial.update();}
  renderer.info.reset();`);
  source=source.replace("backend:'WebGL2',crownV2", "spatial:spatial?.report,backend:'WebGL2',crownV2");
  report.servedScoreboardPageSha256=sha(source);overrides['/scoreboard-page.mjs']=source;overrides['/scoreboard-probes.mjs']=await readFile(resolve(root,'scripts/world_scoreboard_probes.mjs'),'utf8');
 }
 server=await startCaptureServer(root,overrides);browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
 for(const view of views){
  if(family==='scoreboard')overrides['/scoreboard-contract.json']={world:'/world/capture/scoreboard-'+area+'/',pose:view.row.pose,camera:view.camera,viewport:view.row.evidence.viewport,metadata:[],thresholds:{}};
  const active=['sloans','lakeview','sloans-lake','lakeview-sheil-park'].includes(area),frames=[];
  for(const mode of active?['default','repeat','lossless']:['default']){
   const viewport=family==='bakeoff'?view.config.viewport:view.row.evidence.viewport,page=await browser.newPage({viewport,deviceScaleFactor:1}),errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.goto(server.origin+(family==='bakeoff'?'/'+view.id+'.html?capture&crownV2=off&foliageExp1=off':'/scoreboard.html?')+(mode==='lossless'?'&spatialCells=1':''),{waitUntil:'domcontentloaded'});
   await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return document.body.dataset.ready==='1'&&(window.bakeoff?.metrics?.samples>=4||window.scoreboard?.metrics?.stable>=3);},null,{timeout:180000});
   if(family==='bakeoff'){
    // Same frozen-time witness as scripts/capture_web.mjs; never snapshot an animated water phase.
    await page.evaluate(()=>{window.bakeoff.freeze=true;});
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
   }
   const metrics=await page.evaluate(()=>{const b=window.bakeoff??window.scoreboard;b.freeze=true;b.renderer.setAnimationLoop(null);b.renderer.backend.gl.finish();return {metrics:b.metrics,spatial:b.spatialCells};});
   if(errors.length)throw Error(errors.join('\n'));const diagnostics=process.env.A10_DIAGNOSTICS?await page.evaluate(async ({family,altitude})=>{const {diagnose}=await import('/spatial-diagnostics.js');return diagnose(window.bakeoff??window.scoreboard,family==='bakeoff'?(altitude===40?[[0,125],[64,125]]:altitude===150?[[283,546]]:[]):altitude===600?[[500,344]]:[]);},{family,altitude:view.altitude}):undefined;const image=await page.screenshot(),png=PNG.sync.read(image),path=resolve(out,view.altitude+'-'+mode+'.png');await writeFile(path,image);
   const passes=metrics.metrics.cost?.passes??metrics.metrics.passes,main=Object.entries(passes).filter(([k])=>k.startsWith('main/')).reduce((a,[,v])=>({triangles:a.triangles+v.triangles,draws:a.draws+v.draws}),{triangles:0,draws:0});
   const row={view:view.id,altitude:view.altitude,mode,path,pngSha256:sha(image),main,metrics,diagnostics};if(mode!=='default'){row.diff=byteDifference(frames[0].data,png.data);row.regions=regions(frames[0].data,png.data,png.width,png.height);row.pass=mode==='repeat'?row.diff.max<=2&&row.diff.mean<=.001:row.diff.max===0;}
   frames.push({data:png.data});report.frames.push(row);console.log(JSON.stringify({view:view.id,mode,main,diff:row.diff,pass:row.pass}));await page.close();
  }
 }
 for(const [file,digest] of Object.entries(report.sourceHashes))if(sha(await readFile(resolve(root,file)))!==digest)throw Error('Source changed during capture: '+file);
 if(server.failures.length)throw Error('Resource failures: '+server.failures.join(', '));report.status=report.frames.some(f=>f.pass===false)?'pixel-gate-failed':'completed';
}catch(e){report.status='failed';report.error=e.stack||String(e);console.error(report.error);process.exitCode=1;}finally{await browser?.close();await server?.close();await writeFile(resolve(out,'qualification.json'),JSON.stringify(report,null,2)+'\n').catch(()=>{});}
