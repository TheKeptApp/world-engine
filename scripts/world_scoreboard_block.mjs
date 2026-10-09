// One block's export + three observations, always admitted by heavy.sh from the coordinator.
import {createRequire} from 'node:module';
import {homedir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {readFile,writeFile,mkdir,statfs} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {startCaptureServer} from './web_capture_server.mjs';
import {inspectionCamera} from './web_capture_blocks.mjs';
import {LocalFrame} from '../web/src/geo.js';
import {THRESHOLDS,sha256,parseStats,typeTag,sourceRoads,featureChecks,passTotals,tierChecks} from './world_scoreboard_checks.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..'),spec=JSON.parse(await readFile(process.argv[2],'utf8'));
const runtime=process.env.PLAYWRIGHT_ROOT||resolve(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules');
const require=createRequire(resolve(runtime,'package.json')),{chromium}=require('playwright'),{PNG}=require('pngjs');
let browser,server;
for(const sig of ['SIGTERM','SIGINT'])process.once(sig,()=>{const timer=setTimeout(()=>process.exit(130),8000);Promise.allSettled([browser?.close(),server?.close()]).finally(()=>{clearTimeout(timer);process.exit(130);});});
const json=async path=>JSON.parse(await readFile(path,'utf8'));
async function command(executable,args){return await new Promise((ok,no)=>{
 const child=spawn(executable,args,{cwd:root,stdio:['ignore','pipe','pipe']}),out=[];
 child.stdout.on('data',b=>out.push(b));child.stderr.on('data',b=>process.stderr.write(b));child.on('error',no);child.on('exit',code=>code===0?ok(Buffer.concat(out).toString()):no(Error(executable+' exited '+code+'\n'+Buffer.concat(out).toString().slice(-2000))));
});}
// Inspect existing feature vertex ranges, without generating alternative geometry.
function tunnelSurface(data,features,tunnelIDs){
 const jsonLength=data.readUInt32LE(12),gltf=JSON.parse(data.subarray(20,20+jsonLength).toString()),binaryStart=20+jsonLength+8;
 const heights=[];
 for(const mesh of gltf.meshes)for(const primitive of mesh.primitives){
  const name=gltf.materials[primitive.material]?.name;if(name!=='worldStatic')continue;
  const acc=gltf.accessors[primitive.attributes.POSITION],view=gltf.bufferViews[acc.bufferView],offset=binaryStart+(view.byteOffset||0)+(acc.byteOffset||0),stride=view.byteStride||12;
  if(acc.componentType!==5126||acc.type!=='VEC3')throw Error('Unsupported GLB position accessor');
  for(const f of features.filter(f=>tunnelIDs.has(f.id)&&['road','path','sidewalk','crossing'].includes(f.kind)))for(const [start,count] of f.lod0.static){
   let minY=Infinity,maxY=-Infinity;for(let i=start;i<start+count;i++){const y=data.readFloatLE(offset+i*stride+4);minY=Math.min(minY,y);maxY=Math.max(maxY,y);}if(count)heights.push({id:f.id,minY,maxY,surface:maxY>=THRESHOLDS.tunnelSurfaceY});
  }
 }
 return heights;
}
try{
 const disk=await statfs(root);if(disk.bavail*disk.bsize<8*1024**3)throw Error('Less than 8 GB free; block not started');
 const areaDir=resolve(root,'Data/areas',spec.area),out=resolve(root,'Generated/web-capture','scoreboard-'+spec.area),exe=resolve(root,'.build/release/worldbake');
 console.error('scoreboard export: '+spec.area);
 await command(exe,['export',areaDir,out,'--date',spec.utc,'--version',spec.commit]);
 const statsText=await command(exe,['stats',areaDir]),stats=parseStats(statsText),world=await json(resolve(out,'world.json'));
 if(!world.frame.vertical.includes('y = 0 is ground'))throw Error('Scoreboard ladder needs a terrain-aware camera adapter; export is no longer flat ground');
 const verified=[];for(const [file,record] of Object.entries(world.files)){const bytes=await readFile(resolve(out,file));if(bytes.length!==record.bytes||sha256(bytes)!==record.sha256)throw Error('Package file hash mismatch: '+file);verified.push(file);}
 const metadata=await Promise.all(world.chunks.map(c=>json(resolve(out,c.scene)))),features=metadata.flatMap(m=>m.features),elements=new Map();
 for(const source of spec.sources.filter(s=>s.format==='osm-overpass-json'&&s.layers.includes('all')))for(const e of (await json(resolve(areaDir,source.path))).elements)elements.set(e.type+'/'+e.id,e);
 const roads=sourceRoads([...elements.values()],new LocalFrame(spec.center.latitude,spec.center.longitude)),checks=featureChecks(stats,features,roads.tunnelIDs),tunnelRanges=[];
 for(let i=0;i<metadata.length;i++)if(metadata[i].features.some(f=>roads.tunnelIDs.has(f.id)))tunnelRanges.push(...tunnelSurface(await readFile(resolve(out,world.chunks[i].lods[0])),metadata[i].features,roads.tunnelIDs));
 checks.tunnel={sourceTunnelWays:roads.tunnelIDs.size,sourceGroundBuildingPassages:roads.groundPassageIDs.size,groundBuildingPassageIDs:[...roads.groundPassageIDs].sort(),groundPassagePolicy:'pedestrian building_passage without a negative source layer can have a ground-level floor; carriageway passages retain the filed core guard',candidates:checks.tunnelCandidates,ranges:tunnelRanges,pass:!tunnelRanges.some(r=>r.surface)};delete checks.tunnelCandidates;
 const block={area:spec.area,type:typeTag(stats,spec.width*spec.height,roads.gridAlignment),typeInputs:{squareMetres:spec.width*spec.height,gridAlignment:roads.gridAlignment},sourceInventory:stats,featureChecks:checks,package:{sha256:sha256(await readFile(resolve(out,'world.json'))),chunks:world.chunks.length,verifiedFiles:verified.length,frame:world.frame,recipe:world.recipe},rows:[]};
 await mkdir(spec.output,{recursive:true});await writeFile(resolve(spec.output,'source-stats.md'),statsText);
 const overrides={
  '/scoreboard.html':'<!doctype html><html><meta charset="utf-8"><title>World scoreboard capture</title><style>body{margin:0}canvas{display:block;width:100vw;height:100vh}small{position:absolute;left:8px;top:8px;background:#172128b0;color:white;font:9px system-ui;padding:3px 6px}</style><script type="importmap">{"imports":{"three":"/vendor/build/three.webgpu.js","three/webgpu":"/vendor/build/three.webgpu.js","three/tsl":"/vendor/build/three.tsl.js","three/addons/":"/vendor/examples/jsm/"}}</script><body><canvas></canvas><small>© OpenStreetMap contributors · Overture Maps · USGS 3DEP; see package LICENSE-DATA.md</small><script type="module" src="/scoreboard-page.mjs"></script></body></html>',
  '/scoreboard-page.mjs':await readFile(resolve(root,'scripts/world_scoreboard_page.mjs'),'utf8'),
  '/scoreboard-probes.mjs':await readFile(resolve(root,'scripts/world_scoreboard_probes.mjs'),'utf8')
 };
 server=await startCaptureServer(root,overrides);
 browser=await chromium.launch({channel:'chrome',headless:false,chromiumSandbox:true,timeout:30000,args:['--disable-background-timer-throttling','--disable-renderer-backgrounding']});
 block.browser={version:browser.version(),sandbox:true};
 for(const altitude of spec.altitudes){
  console.error('scoreboard capture: '+spec.area+'/'+altitude);
  const pose={...spec.pose,altitudeAGLMetres:altitude},camera=inspectionCamera(pose,altitude,world.frame.origin),contract={world:'/world/capture/scoreboard-'+spec.area+'/',pose,camera,viewport:spec.viewport,metadata,thresholds:THRESHOLDS};
  overrides['/scoreboard-contract.json']=contract;
  const page=await browser.newPage({viewport:spec.viewport,deviceScaleFactor:1}),errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  const started=performance.now();await page.goto(server.origin+'/scoreboard.html',{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForFunction(()=>{if(document.body.dataset.error)throw Error(document.body.dataset.error);return document.body.dataset.ready==='1'&&window.scoreboard?.metrics?.stable>=3;},null,{polling:'raf',timeout:180000});
  const evidence=await page.evaluate(()=>{const b=window.scoreboard;b.freeze=true;b.renderer.setAnimationLoop(null);b.renderer.backend.gl.finish();return b.metrics;});
  const image=await page.screenshot({type:'png'}),png=PNG.sync.read(image);
  if(png.width!==spec.viewport.width||png.height!==spec.viewport.height)throw Error('Wrong capture size');
  let n=0,sum=0,sum2=0,min=255,max=0;for(let y=30;y<png.height;y+=2)for(let x=0;x<png.width;x+=2){const i=(y*png.width+x)*4,v=(png.data[i]+png.data[i+1]+png.data[i+2])/3;n++;sum+=v;sum2+=v*v;min=Math.min(min,v);max=Math.max(max,v);}
  const pixels={variance:sum2/n-(sum/n)**2,range:max-min};pixels.pass=pixels.variance>=THRESHOLDS.pixelVariance&&pixels.range>=THRESHOLDS.pixelRange;
  const probes=await page.evaluate(()=>window.scoreboard.probe());if(errors.length)throw Error(errors.join('\n'));
  const totals=passTotals(evidence.passes);if(Object.values(totals).reduce((n,p)=>n+p.triangles,0)!==evidence.allPass.triangles||Object.values(totals).reduce((n,p)=>n+p.draws,0)!==evidence.allPass.draws)throw Error('Pass ledger does not reconcile with renderer.info');
  const tiers=tierChecks(totals.main,totals.shadow),failures=[];
  for(const [name,check] of Object.entries(checks))if(check.pass===false)failures.push(name);
  if(!probes.blankGround.pass)failures.push('blank-ground');
  if(!probes.clipping.pass)failures.push('clipping');if(!pixels.pass)failures.push('flat-frame');
  for(const [name,check] of Object.entries(tiers))if(!check.pass)failures.push('budget-'+name);
  const row={key:spec.area+'/'+altitude,area:spec.area,type:block.type,altitude,pose,date:spec.utc,renderer:spec.renderer,crown:'off',metrics:{mainTriangles:totals.main.triangles,mainDraws:totals.main.draws,shadowTriangles:totals.shadow.triangles,shadowDraws:totals.shadow.draws,blankGroundFraction:probes.blankGround.fraction,sourceBuildings:stats.buildings,exportedBuildings:checks.buildings.exportedUnique,buildingRelativeError:checks.buildings.relativeError,sourceWater:checks.water.source,exportedWater:checks.water.exportedUnique,sourceParks:checks.park.source,exportedParks:checks.park.exportedUnique,tunnelSurfaceRanges:tunnelRanges.filter(r=>r.surface).length,nearClipTriangles:probes.clipping.intersectingTriangles},tiers,detectors:probes,featureChecks:checks,passes:evidence.passes,evidence:{camera:evidence.camera,exposure:evidence.exposure,season:evidence.season,samples:evidence.samples,stable:evidence.stable,allPass:evidence.allPass,pngSha256:sha256(image),viewport:spec.viewport,seconds:(performance.now()-started)/1000},failures,warnings:probes.clipping.potential?['potential-near-clipping']:[],comparisonInputs:{pose,date:spec.utc,viewport:spec.viewport,renderer:spec.renderer,sourceHash:spec.sourceHash,detectorContract:spec.detectorContract,exportRecipe:{focus:'entire held area',date:spec.utc},harnessHash:spec.harnessHash}};
  row.detectors.pixels=pixels;row.metrics.clippedStaticFraction=probes.clipping.lostStaticFraction;row.metrics.pixelVariance=pixels.variance;
  await writeFile(resolve(spec.output,altitude+'.png'),image);block.rows.push(row);await page.close();
 }
 if(server.failures.length)throw Error('Resource failures: '+server.failures.join(', '));
 await writeFile(resolve(spec.output,'block.json'),JSON.stringify(block,null,2)+'\n');
 console.log(spec.area+' complete: '+block.rows.length+' frames');
}catch(error){console.error(error.stack||error.message);process.exitCode=1;}
finally{try{await browser?.close();}finally{await server?.close();}}
