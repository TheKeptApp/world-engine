// Experiment-only entry; default main and shared shipping modules stay unchanged.
import * as T from 'three/webgpu';
import {installFarWater} from './far-water.js';
import {installShadowCells} from './shadow-cells.js';
import {WorldScene} from '/src/world.js';
import {installSpatialCells,validateSpatialQuery} from './spatial-cells.js';
const query=new URLSearchParams(location.search),mainActive=query.get('spatialCells')==='1';if(mainActive)validateSpatialQuery(query);if(query.get('shadowCells')==='1'&&['sceneBudget','crownV2','crownV3','foliageExp1'].some(k=>query.has(k)&&query.get(k)!=='off'))throw Error('shadowCells requires independent crown-off variant');
const features=new WeakMap(),remove=T.BufferGeometry.prototype.deleteAttribute,load=WorldScene.prototype.load,loop=T.WebGPURenderer.prototype.setAnimationLoop;
let sidecar;
WorldScene.prototype.load=async function(...args){
 if(mainActive){const response=await fetch(this.base+'spatial-cells.json');if(!response.ok)throw Error('Missing opt-in spatial export: '+this.base);sidecar=await response.json();
 const bytes=await (await fetch(this.base+'world.json')).arrayBuffer(),digest=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');if(digest!==sidecar.sourceWorldSha256)throw Error('Spatial sidecar does not match source world');}
 T.BufferGeometry.prototype.deleteAttribute=function(n){if(n==='_feature')features.set(this,this.attributes[n]);return remove.call(this,n);};
 try{return await load.apply(this,args);}finally{T.BufferGeometry.prototype.deleteAttribute=remove;WorldScene.prototype.load=load;}
};
T.WebGPURenderer.prototype.setAnimationLoop=function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=loop;const b=window.bakeoff,v=mainActive?installSpatialCells(b.scene,b.camera,{renderer:this,features,sidecar,groupMetres:Number(query.get('spatialGroup')??800),mergeSourceRuns:query.get('spatialMergeRuns')==='1'}):null;b.spatialCells=v?.report;
 if(query.get('shadowCells')==='1'){const s=installShadowCells(b.scene,b.camera,b.world,{features,renderer:this});b.shadowCells=s.report;}
 const water=query.get('farWater')==='1'&&v?installFarWater(v.root,b.camera):null;b.farWater=water?.report;
 return loop.call(this,t=>{water?.restore();v?.update();water?.update();callback(t);});
};
await import('./main.js');
