// Capture harness for existing shipping modules, not a renderer implementation.
import * as T from 'three/webgpu';
import {WorldScene} from '/src/world.js';
import {Lighting} from '/src/lighting.js';
import {createPost} from '/src/post.js';
import {LocalFrame} from '/src/geo.js';
import {updateCameraNear} from '/src/camera-near.js';
import {installCostLedger} from '/budget.js';
import {probeScene} from '/scoreboard-probes.mjs';
window.addEventListener('error',e=>document.body.dataset.error=e.error?.stack||e.message);
window.addEventListener('unhandledrejection',e=>document.body.dataset.error=e.reason?.stack||String(e.reason));
async function main(){
 const spec=await (await fetch('/scoreboard-contract.json')).json();
 const world=new WorldScene(spec.world);await world.load();
 const scene=new T.Scene();scene.add(world.root);
 const renderer=new T.WebGPURenderer({canvas:document.querySelector('canvas'),antialias:true,forceWebGL:true,powerPreference:'high-performance'});
 await renderer.init();renderer.setPixelRatio(1);renderer.setSize(spec.viewport.width,spec.viewport.height,false);
 renderer.shadowMap.enabled=true;renderer.shadowMap.type=T.PCFSoftShadowMap;renderer.info.autoReset=false;
 const camera=new T.PerspectiveCamera(spec.pose.fov,spec.viewport.width/spec.viewport.height,.1,5000),frame=new LocalFrame(world.manifest.frame.origin.latitude,world.manifest.frame.origin.longitude);
 camera.position.fromArray(frame.scene(...spec.camera.eye));const target=new T.Vector3(...frame.scene(...spec.camera.target));camera.lookAt(target);updateCameraNear(camera);
 const state=world.environment.states[world.environment.defaultState];world.setSeason(state.season);
 const lighting=new Lighting(scene);await lighting.apply(state,world.globals,spec.world+state.sky);
 world.root.traverse(o=>{if(o.isMesh)o.userData.costCategory=o.isInstancedMesh?'instances':o.material===world.materials.water?'water':'opaque world';});
 const ledger=installCostLedger(renderer,camera),post=createPost(renderer,scene,camera);
 let prior='',stable=0,samples=0;
 window.scoreboard={T,world,scene,camera,renderer,lighting,ledger,state,spec,freeze:false,metrics:null,probe:()=>probeScene(window.scoreboard,spec.metadata,spec.thresholds)};
 renderer.setAnimationLoop(()=>{
  if(window.scoreboard.freeze)return;
  updateCameraNear(camera);world.updateLODs(camera.position);world.updateTufts(target,camera.position);lighting.update(target,camera.position,world.globals);
  renderer.info.reset();ledger.reset();post.render();samples++;
  const passes=ledger.snapshot().passes,key=JSON.stringify(passes);stable=key===prior?stable+1:1;prior=key;
  window.scoreboard.metrics={passes,allPass:{triangles:renderer.info.render.triangles,draws:renderer.info.render.drawCalls},samples,stable,camera:{position:camera.position.toArray(),direction:camera.getWorldDirection(new T.Vector3()).toArray(),fov:camera.fov,near:camera.near,far:camera.far},backend:'WebGL2',crownV2:'off',crownV3:'off',exposure:{kind:'package light state; no auto exposure',value:state.light.exposure,date:state.date},season:state.season};
  if(samples>=4&&stable>=3)document.body.dataset.ready='1';
 });
}
main().catch(error=>{document.body.dataset.error=error.stack||error.message;console.error(error);});
