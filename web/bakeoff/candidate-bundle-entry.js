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
let sidecar;
WorldScene.prototype.load=async function(...args){
 const r=await fetch(this.base+'spatial-cells.json');if(!r.ok)throw Error('Missing candidate spatial export: '+this.base);sidecar=await r.json();
 const bytes=await (await fetch(this.base+'world.json')).arrayBuffer(),digest=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(b=>b.toString(16).padStart(2,'0')).join('');if(digest!==sidecar.sourceWorldSha256)throw Error('Candidate spatial source hash mismatch');
 T.BufferGeometry.prototype.deleteAttribute=function(n){if(n==='_feature')features.set(this,this.attributes[n]);return remove.call(this,n);};
 try{return await load.apply(this,args);}finally{T.BufferGeometry.prototype.deleteAttribute=remove;WorldScene.prototype.load=load;}
};
T.WebGPURenderer.prototype.setAnimationLoop=function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=loop;
 const b=window.bakeoff,v=installSpatialCells(b.scene,b.camera,{renderer:this,features,sidecar,mergeSourceRuns:true});b.spatialCells=v.report;
 const ring=installContextRing(b,context);b.contextRing=ring.report;b.contextMeshes=ring.meshes;
 b.shadowCells=installShadowCells(b.scene,b.camera,b.world,{features,renderer:this}).report;
 b.candidateBundle={spatialCells:true,spatialMergeRuns:true,shadowCells:true,contextRing:true,lightTrial:'on',paletteB:'tableA',far:false};
 return loop.call(this,t=>{updateDetailedOnly(v,ring.meshes);callback(t);});
};
await import('./main.js');
