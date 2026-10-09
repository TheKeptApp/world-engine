// Consumer only: retain A4's reported representation and hash-bound payload unchanged.
import * as T from 'three/webgpu';
import {installFarParent} from './spatial-far.js';
import {geometryFingerprint} from './spatial-cells.js';
import {farViewAllowed} from './candidate-far-policy.js';
export function installFarTrial(scene,camera,world,loaded,{features,spatialSidecar,groundCeiling}={}){
 if(!Number.isFinite(groundCeiling))throw Error('Far consumer requires a finite conservative ground ceiling');
 const originals=orderedFarSources(world,loaded);
 if(originals.length!==loaded.sidecar.sources.length)throw Error('Far bound source coverage mismatch');
 const material=originals[0]?.[0].material;if(!material||Array.isArray(material)||originals.some(([o])=>o.material!==material))throw Error('Far sources require one compatible material');
 if(material.positionNode)throw Error('Far parent requires rigid original static material');
 const transfer=transferExistingFacades(loaded,originals.map(([o])=>o),features);
 const materialView={root:world.root,materials:{static:material}};
 const far=installFarParent(scene,camera,materialView,loaded,{features,spatialSidecar}),update=far.update;far.report.surfaceTransfer=transfer;
 far.update=()=>{
  const allowed=farViewAllowed(camera,groundCeiling);
  Object.assign(far.report,{viewMinimumAltitudeMetres:400,groundCeiling,altitudeAboveCeiling:camera.position.y-groundCeiling,viewAllowed:allowed});
  if(allowed)update();
  else if(far.report.selected){for(const [o,visible]of originals)o.visible=visible;far.parent.visible=false;far.report.selected=false;far.report.swaps++;}
  if(!far.report.selected)for(const [o]of originals)delete o.userData.farShadowVisible;
 };
 far.update();return far;
}

// Reuse the existing runtime wall override only on the same feature and paint slot.
// No colour classification, new coefficients, or changes to original geometry.
export function transferExistingFacades(loaded,sources,features){
 if(loaded.facadeTransfer)return loaded.facadeTransfer;
 const geometry=loaded.geometry,farFeature=geometry.attributes._feature,farPaint=geometry.attributes._paint,out=new Float32Array(geometry.attributes.position.count*4),mapping=new Map();let next=0,copiedVertices=0,unmappedVertices=0;
 if(sources.every(o=>!o.geometry.attributes._facade)){geometry.setAttribute('_facade',new T.BufferAttribute(out,4));return {rule:'Original sources have no facade override',copiedVertices:0,unmappedVertices:out.length/4};}
 if(sources.some(o=>!o.geometry.attributes._facade))throw Error('Incomplete original facade assignments');
 for(let i=0;i<loaded.sidecar.sources.length;i++){
  const g=sources[i].geometry;if(geometryFingerprint(g)!==loaded.sidecar.sources[i])throw Error('Far source order mismatch');const face=g.attributes._facade;
  const feature=features?.get(g),paint=g.attributes._paint;if(!feature||!paint||!farFeature||!farPaint)throw Error('Missing facade transfer provenance');
  const rows=new Map();for(let i=0;i<g.index.count;i++){const vertex=g.index.getX(i),id=feature.getX(vertex);if(!rows.has(id))rows.set(id,new Map());const slots=rows.get(id),slot=Math.round(paint.getX(vertex)),value=[face.getX(vertex),face.getY(vertex),face.getZ(vertex),face.getW(vertex)],old=slots.get(slot);if(old&&old.some((v,k)=>v!==value[k]))throw Error('Ambiguous within-feature facade assignment');slots.set(slot,value);}
  for(const slots of rows.values())mapping.set(next++,slots);
 }
 if(next!==loaded.sidecar.rows.length)throw Error('Far feature order mismatch');
 if(farFeature&&farPaint)for(let i=0;i<farFeature.count;i++){const value=mapping.get(farFeature.getX(i))?.get(Math.round(farPaint.getX(i)));if(value){out.set(value,i*4);copiedVertices++;}else unmappedVertices++;}
 geometry.setAttribute('_facade',new T.BufferAttribute(out,4));return {rule:'Existing _facade by original feature order and paint slot; no new look values',copiedVertices,unmappedVertices};
}

export function orderedFarSources(world,loaded){
 const wanted=new Set(loaded.sidecar.sources),originals=[],match=o=>o.isMesh&&!o.isInstancedMesh&&(o.material===world.materials.static||o.userData.costCategory==='opaque world');
 if(world.manifest?.chunks){
  if(world.manifest.chunks.length!==loaded.sidecar.sources.length)throw Error('Far chunk count mismatch');
  for(let i=0;i<world.manifest.chunks.length;i++){const candidates=[];world.root.children[i]?.traverse(o=>{if(match(o)&&geometryFingerprint(o.geometry)===loaded.sidecar.sources[i])candidates.push(o);});if(candidates.length!==1)throw Error('Far chunk source identity mismatch');originals.push([candidates[0],candidates[0].visible]);}
 }else world.root.traverse(o=>{if(match(o)&&wanted.has(geometryFingerprint(o.geometry)))originals.push([o,o.visible]);});
 return originals;
}
