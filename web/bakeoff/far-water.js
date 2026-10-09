// R's >=400 m far-geometry approval; native World.swift buildStatic merges Chunk water.
// Preserve selected topology and material; world-space rebaking is intentionally not pixel-exact.
import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
export const FAR_WATER_HEIGHT=400;
export function installFarWater(sourceRoot,camera,{height=()=>camera.position.y}={}){
 const root=new T.Group();root.name='far water pools';sourceRoot.add(root);
 const report={enabled:true,active:false,sourceDraws:0,draws:0,triangles:0,bufferBytes:0,rebuilds:0,thresholdM:FAR_WATER_HEIGHT};
 let previous='',hidden=[],meshes=[];
 function restore(){for(const [o,mask]of hidden)o.layers.mask=mask;hidden=[];}
 function update(){
  restore();root.visible=false;
  if(height()<FAR_WATER_HEIGHT){Object.assign(report,{active:false,sourceDraws:0,draws:0,triangles:0});return;}
  sourceRoot.updateMatrixWorld(true);const sources=[];
  sourceRoot.traverse(o=>{if(!o.isMesh||o.parent===root||!o.visible||o.isInstancedMesh||o.userData.costCategory!=='water'||!camera.layers.test(o.layers))return;
   for(let p=o.parent;p;p=p.parent)if(!p.visible)return;
   if(Array.isArray(o.material)||o.material.transparent||o.castShadow||o.geometry.groups.length)throw Error('Unsupported far water render state');
   sources.push(o);
  });
  const signature=JSON.stringify(sources.map(o=>[o.uuid,o.geometry.uuid,o.geometry.index?.version,o.geometry.drawRange,o.matrixWorld.elements]));
  if(signature!==previous){
   for(const m of meshes){root.remove(m);m.geometry.dispose();}meshes=[];report.bufferBytes=0;
   const bins=new Map();
   for(const o of sources){const key=JSON.stringify([o.material.uuid,o.receiveShadow,o.renderOrder,Object.entries(o.geometry.attributes).map(([k,a])=>[k,a.itemSize,a.normalized,a.array.constructor.name])]);
    if(!bins.has(key))bins.set(key,[]);bins.get(key).push(o);
   }
   for(const group of bins.values()){
    const parts=group.map(o=>{const g=o.geometry.clone(),{start,count}=g.drawRange,ids=g.index?.array;
     if(!ids)throw Error('Far water requires indexed source');
     g.setIndex(new T.BufferAttribute(ids.slice(start,Math.min(ids.length,start+count)),1));g.setDrawRange(0,Infinity);g.applyMatrix4(o.matrixWorld);return g;
    });
    const geometry=mergeGeometries(parts,false);for(const p of parts)p.dispose();if(!geometry)throw Error('Incompatible water attributes');
    const m=new T.Mesh(geometry,group[0].material);m.name='far merged water';m.castShadow=false;m.receiveShadow=group[0].receiveShadow;m.renderOrder=group[0].renderOrder;m.frustumCulled=false;m.userData.costCategory='water';m.userData.farWater=true;root.add(m);meshes.push(m);
    report.bufferBytes+=geometry.index.array.byteLength+Object.values(geometry.attributes).reduce((n,a)=>n+a.array.byteLength,0);
   }
   previous=signature;report.rebuilds++;
  }
  for(const o of sources){hidden.push([o,o.layers.mask]);o.layers.set(2);}
  root.visible=true;Object.assign(report,{active:true,sourceDraws:sources.length,draws:meshes.length,triangles:meshes.reduce((n,m)=>n+m.geometry.index.count/3,0)});
 }
 return {update,restore,report,root};
}
