// Capture-server-only entry override. No normal page imports this file.
import * as T from 'three/webgpu';
let lastCPU=null;
globalThis.__sceneBudgetObserve=x=>{lastCPU=x;};
// Keep the original resize/facade refresh logic available to the scripted camera.
const Resize=globalThis.ResizeObserver,refresh=[];
globalThis.ResizeObserver=class extends Resize{constructor(fn){super(fn);refresh.push(fn);}};
const original=T.WebGPURenderer.prototype.setAnimationLoop;
T.WebGPURenderer.prototype.setAnimationLoop=function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=original;
 const b=window.bakeoff,backend=this.backend,draw=backend.draw.bind(backend);let passes={};
 backend.draw=(object,info,...args)=>{const d=info.render.drawCalls,t=info.render.triangles,r=draw(object,info,...args),phase=object.camera===b.camera?'main':object.camera.isOrthographicCamera&&object.object.userData.costCategory?'shadow':'post',key=phase+'/'+(object.object.userData.costCategory||'sky/composite'),p=passes[key]??={draws:0,triangles:0};p.draws+=info.render.drawCalls-d;p.triangles+=info.render.triangles-t;return r;};
 b.freeze=true;
 window.__qualification={step(pose,readPixels=false){
  const start=performance.now();b.camera.position.fromArray(pose.position);const h=pose.heading*Math.PI/180,p=pose.pitch*Math.PI/180;
  b.camera.lookAt(b.camera.position.clone().add(new T.Vector3(Math.sin(h)*Math.cos(p),-Math.sin(p),-Math.cos(h)*Math.cos(p))));b.camera.updateMatrixWorld();
  b.world.updateLODs(b.camera.position);b.world.updateTufts(b.camera.position,b.camera.position);refresh.forEach(fn=>fn());
  lastCPU=null;passes={};callback(pose.timeMs);const gl=backend.gl;gl.finish();const frameMs=performance.now()-start;
  const memory=performance.memory?{usedJSHeapBytes:performance.memory.usedJSHeapSize,totalJSHeapBytes:performance.memory.totalJSHeapSize}:null;
  const result={passes,frameMs,cpu:lastCPU??{selectionMs:0,poolingMs:0,maintenanceMs:0,cached:true},buffers:gl.__qualificationProbe.snapshot(),memory,rendererMemory:{...b.renderer.info.memory},camera:{position:b.camera.position.toArray(),direction:b.camera.getWorldDirection(new T.Vector3()).toArray(),fov:b.camera.fov,near:b.camera.near},resolved:{sceneBudget:!!b.sceneBudget,foliage:b.foliageExp1,crownV2:b.crownV2,crownV3:b.crownV3},exposure:b.policy.look.lighting.exposure};
  if(readPixels){const w=gl.drawingBufferWidth,h=gl.drawingBufferHeight,a=new Uint8Array(w*h*4);gl.readPixels(0,0,w,h,gl.RGBA,gl.UNSIGNED_BYTE,a);let s='';for(let i=0;i<a.length;i+=8192)s+=String.fromCharCode(...a.subarray(i,i+8192));result.pixelData={width:w,height:h,base64:btoa(s)};}
  return result;
 }};
 // Automatic animation is intentionally paused; the worker advances exactly one completed frame.
};
await import('./entry.js');
