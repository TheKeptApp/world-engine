// Local CPU scene-graph accounting only. No browser/server/capture/GPU context.
import assert from 'node:assert/strict';
import {registerHooks} from 'node:module';
import {createHash} from 'node:crypto';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
const assets=process.env.WORLDENGINE_ASSETS;if(!assets)throw Error('WORLDENGINE_ASSETS required');
registerHooks({resolve(spec,ctx,next){if(spec==='three')spec=pathToFileURL(resolve(assets,'web/node_modules/three/build/three.module.js')).href;else if(spec.startsWith('three/'))spec=pathToFileURL(resolve(assets,'web/node_modules/three',spec==='three/webgpu'?'build/three.webgpu.js':spec==='three/tsl'?'build/three.tsl.js':spec.replace('three/addons/','examples/jsm/'))).href;return next(spec,ctx);}});
globalThis.ProgressEvent=class{constructor(type,props){Object.assign(this,{type},props);}};
globalThis.fetch=async input=>{let url=typeof input==='string'?input:input.url;const p=url.startsWith('file:')?fileURLToPath(url):resolve('web/bakeoff',url);const bytes=await readFile(p);return new Response(bytes,{headers:{'Content-Length':String(bytes.length)}});};
const T=await import('three/webgpu');
const {WorldScene}=await import('../src/world.js'),{LocalFrame}=await import('../src/geo.js');
const {applySpecies}=await import('./foliage.js'),{phenology}=await import('./phenology.js'),{facadeDetails}=await import('./facades.js'),{addFrontRange}=await import('./backdrop.js'),{resolvePolicy}=await import('./policy.js'),{installShadowCasters}=await import('./shadow-casters.js');
const json=async p=>JSON.parse(await readFile(p)),local=n=>json('web/bakeoff/'+n),pack=n=>json(resolve(assets,'docs/proposals',n));
const scenes=await local('scenes.json'),fixture=await local('fixture.json'),p2=await local('data/p2-crowns.json'),foliage=await pack('foliage-seasons-v1/foliage-values.json'),crown=await json('docs/proposals/crown-silhouettes-v2/values.json');
const cal=await pack('style-b-calibration-v2/values.json'),lake=await pack('lake-winter-v1/lake-winter-values.json');
const results=[];
for(const id of ['sloans','lakeview'])for(const tier of ['off','standard','floor']){
 const enabled=tier!=='off',config=scenes[id],policy=resolvePolicy(cal,lake,fixture,await local('data/sky-correction.json'),await local('data/haze-values.json'),config.climateRegion);
 const world=new WorldScene(pathToFileURL((id==='sloans'?resolve(assets,'Generated/package/sloans-lake'):resolve('web/bakeoff/generated/lakeview-sheil-park'))+'/').href);await world.load();
 const scene=new T.Scene();scene.add(world.root);const origin=world.manifest.frame.origin,frame=new LocalFrame(origin.latitude,origin.longitude),camera=new T.PerspectiveCamera(config.camera.fov,config.viewport.width/config.viewport.height,.2,150000);
 camera.position.fromArray(frame.scene(...config.camera.eye));camera.lookAt(new T.Vector3(...frame.scene(...config.camera.target)));camera.updateMatrixWorld();
 const state=phenology(fixture.date,config.region,p2);world.setSeason(state.exportSeasonIndex);
 applySpecies(world,foliage,policy.look.materials.roughness.foliage,config.region,state,p2,'off',enabled?{pack:crown,tier,camera,height:()=>config.viewport.height}:null);
 const facade=facadeDetails(scene,await local('data/'+id+'-facades.json'),frame,await local('data/facade-values.json'),config.region,policy.look,await local('data/facade-mechanics.json'));facade.update(camera,config.viewport.height);
 if(config.backdrop)await addFrontRange(scene,config.backdrop,frame,origin,await pack('mountain-terrain-v1/values.json'),policy,camera);
 world.updateLODs(camera.position);world.updateTufts(camera.position,camera.position);scene.updateMatrixWorld(true);
 const frustum=new T.Frustum().setFromProjectionMatrix(new T.Matrix4().multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse));let mainTriangles=0,mainDraws=0,elmCount=0;const lodCounts=[0,0,0,0];
 scene.traverseVisible(o=>{if(!o.isMesh||!camera.layers.test(o.layers)||o.isInstancedMesh&&!o.count)return;if(o.frustumCulled&&!frustum.intersectsObject(o))return;mainTriangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3*(o.isInstancedMesh?o.count:1);mainDraws++;});
 for(const g of world.lodGroups)if(g.species?.id==='ulmus_americana'){elmCount+=g.instances.length;g.levels.forEach((m,i)=>lodCounts[i]+=m.count);}
 const sun=new T.DirectionalLight();scene.add(sun);const shadow=installShadowCasters(scene,world,sun,camera).report;
 // Three common/Background.js creates SphereGeometry(1,32,32); post is one fullscreen triangle.
 const backgroundTriangles=new T.SphereGeometry(1,32,32).index.count/3;
 mainTriangles+=backgroundTriangles;mainDraws++;
 results.push({scene:id,crownV2:tier,crownBudget:world.crownBudget,mainTriangles,mainDraws,background:{triangles:backgroundTriangles,draws:1},post:{triangles:1,draws:1},shadowTrianglesUpperBound:shadow.potentialTriangles,shadowDrawsUpperBound:shadow.draws,shadowRadiusM:shadow.radiusM,elmCount,lodCounts,standard:{main:mainTriangles<=500000,draws:mainDraws<=120},floor:{main:mainTriangles<400000,draws:mainDraws<=100,shadow:shadow.potentialTriangles<=150000}});
}
for(const r of results){if(r.crownV2==='standard')assert(r.standard.main&&r.standard.draws);if(r.crownV2==='floor')assert(r.floor.main&&r.floor.draws&&r.floor.shadow);}
const inputHashes={};for(const p of ['docs/proposals/crown-silhouettes-v2/values.json','web/bakeoff/foliage.js','web/bakeoff/main.js','web/bakeoff/fixture.json','web/bakeoff/scenes.json'])inputHashes[p]=createHash('sha256').update(await readFile(p)).digest('hex');
await writeFile('web/bakeoff/evidence/crown-v2/scene-costs.json',JSON.stringify({inputHashes,kind:'CPU scene submission model, not rendered counters',notes:'Uses shared WorldScene, frozen camera/date, actual facade and DEM geometry, actual shadow caster selection. Main frustum culling at mesh/instance-batch bounds. Includes Three Background sphere; post fullscreen triangle listed separately. Shadow is pre-frustum upper bound. Water/facade material-only changes cannot alter these topology counts. No GPU/frame-time claim.',results},null,2)+'\n');console.log(JSON.stringify(results));
