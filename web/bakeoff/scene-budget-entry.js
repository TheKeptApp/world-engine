// Opt-in entry only. Shipping main.js and shared viewer sources remain unchanged.
import * as T from 'three/webgpu';
import {WorldScene} from '/src/world.js';
import {installSceneBudget,validateSceneBudgetQuery} from './scene-budget.js';
const query=new URLSearchParams(location.search);
validateSceneBudgetQuery(query);
const features=new WeakMap(),remove=T.BufferGeometry.prototype.deleteAttribute;
const load=WorldScene.prototype.load,loop=T.WebGPURenderer.prototype.setAnimationLoop;
// Preserve feature provenance out-of-band; the shipping loader still removes its GPU attribute.
WorldScene.prototype.load=async function(...args){
 T.BufferGeometry.prototype.deleteAttribute=function(name){if(name==='_feature'&&this.attributes[name])features.set(this,this.attributes[name]);return remove.call(this,name);};
 try{return await load.apply(this,args);}finally{T.BufferGeometry.prototype.deleteAttribute=remove;WorldScene.prototype.load=load;}
};
T.WebGPURenderer.prototype.setAnimationLoop=function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=loop;
 const b=window.bakeoff,variant=installSceneBudget(b.scene,b.camera,features);
 b.sceneBudget=variant.report;
 return loop.call(this,t=>{variant.update();callback(t);});
};
await import('./main.js');
