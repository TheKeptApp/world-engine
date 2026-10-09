// Default-off bakeoff only. Load source geometry before main, attach after sceneBudget selection.
import * as T from 'three/webgpu';
import {installContextRing} from './context-ring.js';
const q=new URLSearchParams(location.search);
if(q.has('baseline')||['crownV2','crownV3','foliageExp1','paletteB'].some(k=>q.has(k)&&q.get(k)!=='off'))throw Error('contextRing requires baseline/crown/foliage/palette experiments off');
const id=document.body.dataset.scene,scenes=await (await fetch('scenes.json')).json();
const response=await fetch(scenes[id]?.context??`data/${id}-context.json`);
if(!response.ok)throw Error(`Missing context export for ${id}; run tools/export-context.swift via build-context-exporter.sh`);
const data=await response.json(),loop=T.WebGPURenderer.prototype.setAnimationLoop;
T.WebGPURenderer.prototype.setAnimationLoop=function(callback){
 T.WebGPURenderer.prototype.setAnimationLoop=loop;
 const b=window.bakeoff,variant=installContextRing(b,data,{mergeLand:q.get('contextMerge')==='1',mergeOpaque:q.get('contextMerge')==='2'});
 b.contextRing=variant.report;b.contextMeshes=variant.meshes;
 // sceneBudget is already installed by its entry; keep ring batches separate from its pools.
 const result=loop.call(this,t=>{variant.update?.();callback(t);});
 return result;
};
await import(q.get('spatialCells')==='1'?'./spatial-cells-entry.js':q.get('sceneBudget')==='1'?'./scene-budget-entry.js':'./main.js');
