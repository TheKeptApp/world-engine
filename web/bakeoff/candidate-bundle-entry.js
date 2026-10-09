import {prepareFarFacades} from './candidate-facade-transfer.js';
import {installFarTrial} from './candidate-far-runtime.js';
import {farViewAllowed} from './candidate-far-policy.js';
import {installFarWater} from './far-water.js';
// R candidate bundle, 9 Oct 2026. Existing look trials, no shipping source edits.
import * as T from 'three/webgpu';
import {WorldScene} from '/src/world.js';
import {installSpatialCells,validateSpatialQuery} from './spatial-cells.js';
import {installShadowCells} from './shadow-cells.js';
import {updateDetailedOnly} from './candidate-bundle.js';
import {installContextRing} from './context-ring.js';
const q=new URLSearchParams(location.search);validateSpatialQuery(q);
for(const [key,value]of Object.entries({spatialMergeRuns:'1',shadowCells:'1',contextRing:'1',lightTrial:'on',paletteB:'tableA'}))if(q.get(key)!==value)throw Error('Candidate requires '+key+'='+value);
const id=document.body.dataset.scene,scenes=await (await fetch('scenes.json')).json(),config=scenes[id];
const response=await fetch(config.context??`/data/${id}-context.json`);if(!response.ok)throw Error('Missing candidate context export');
const context=await response.json(),features=new WeakMap(),remove=T.BufferGeometry.prototype.deleteAttribute,load=WorldScene.prototype.load,loop=T.WebGPURenderer.prototype.setAnimationLoop;
let sidecar,farModule,farLoaded;
WorldScene.prototype.load=async function(...args){
 const r=await fetch(this.base+'spatial-cells.json');if(!r.ok)throw Error('Missing candidate spatial export: '+this.base);sidecar=await r.json();
 const bytes=await (await fetch(this.base+'world.json')).arrayBuffer(),digest=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(b=>b.toString(16).padStart(2,'0')).join('');if(digest!==sidecar.sourceWorldSha256)throw Error('Candidate spatial source hash mismatch');
 T.BufferGeometry.prototype.deleteAttribute=function(n){if(n==='_feature')features.set(this,this.attributes[n]);return remove.call(this,n);};
 try{const result=await load.apply(this,args);if(q.get('farParent')==='1'){farModule=await import('./spatial-far.js');farLoaded=await farModule.loadFarParent(this.base);}return result;}finally{T.BufferGeometry.prototype.deleteAttribute=remove;WorldScene.prototype.load=load;}
};
T.WebGPURenderer.prototype.setAnimationLoop=async function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=loop;
 const b=window.bakeoff,groundCeiling=Math.max(b.world.manifest.bounds?.max?.[1]??NaN,farLoaded?.sidecar.bounds[4]??-Infinity),height=()=>b.camera.position.y-groundCeiling;
 b.camera.userData.drawableHeight=b.renderer.domElement.height;
 if(farLoaded)await prepareFarFacades(b.world,farLoaded,features);
 const far=farLoaded?installFarTrial(b.scene,b.camera,b.world,farLoaded,{features,spatialSidecar:sidecar,groundCeiling}):null;b.farParent=far?.report;
 const v=installSpatialCells(b.scene,b.camera,{renderer:this,features,sidecar,mergeSourceRuns:true});b.spatialCells=v.report;
 const ring=installContextRing(b,context,{mergeOpaque:q.get('contextMerge')==='2',mergeAllowed:()=>farViewAllowed(b.camera,groundCeiling)});b.contextRing=ring.report;b.contextMeshes=ring.meshes;
 b.shadowCells=installShadowCells(b.scene,b.camera,b.world,{features,renderer:this}).report;
 const water=q.get('farWater')==='1'?installFarWater(v.root,b.camera,{height}):null;b.farWater=water?.report;
 b.candidateBundle={spatialCells:true,spatialMergeRuns:true,shadowCells:true,contextRing:true,lightTrial:'on',paletteB:'tableA',far:!!far};
 return loop.call(this,t=>{water?.restore();far?.update();ring.update?.();updateDetailedOnly(v,ring.meshes);water?.update();callback(t);});
};
await import('./main.js');
