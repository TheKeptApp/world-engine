// Consume declared LOD1 surface ranges; reuse existing runtime colours, never infer surfaces.
import * as T from 'three/webgpu';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {orderedFarSources} from './candidate-far-runtime.js';
export function transferDeclaredFacadeRanges(loaded,sources,features,inputs){
 const parent=loaded.geometry,attribute=parent.attributes._feature,paint=parent.attributes._paint,out=new Float32Array(parent.attributes.position.count*4),vertices=new Map(),overrides=[];
 if(!attribute||!paint||!loaded.sidecar.featureRecords)throw Error('Missing declared far surface provenance');
 for(let i=0;i<attribute.count;i++){const id=attribute.getX(i);if(!vertices.has(id))vertices.set(id,[]);vertices.get(id).push(i);}
 for(const source of sources){const g=source.geometry,feature=features.get(g),face=g.attributes._facade,p=g.attributes._paint,byFeature=new Map();if(!feature||!face||!p)throw Error('Missing original surface assignment');
  for(let i=0;i<g.index.count;i++){const v=g.index.getX(i);if(face.getW(v)===0)continue;const id=feature.getX(v),slot=Math.round(p.getX(v)),value=[face.getX(v),face.getY(v),face.getZ(v),face.getW(v)];if(!byFeature.has(id))byFeature.set(id,new Map());const map=byFeature.get(id),old=map.get(slot);if(old&&old.some((n,k)=>n!==value[k]))throw Error('Conflicting existing nonzero wall overrides');map.set(slot,value);}overrides.push(byFeature);
 }
 let copiedVertices=0,unmappedWallVertices=0,featuresWithOverrides=0;
 for(const record of loaded.sidecar.featureRecords){const input=inputs.find(x=>x.chunk===record.chunk);if(!input)throw Error('Missing far chunk metadata');const slots=overrides[input.sourceIndex].get(record.index);if(!slots?.size)continue;
  if(record.kind!=='building'||record.lod!==1)throw Error('Wall override outside declared building LOD1');featuresWithOverrides++;
  const metadata=input.scene.features.find(f=>f.index===record.index);if(metadata?.id!==record.id||!Array.isArray(metadata.lod1?.static))throw Error('Missing declared LOD1 static ranges');
  const g=input.geometry,feature=g.attributes._feature,p=g.attributes._paint,localVertices=new Map(),selected=new Set();if(!feature||!p)throw Error('Missing LOD1 feature/paint attributes');
  for(let i=0;i<g.index.count;i+=3){const ids=[g.index.getX(i),g.index.getX(i+1),g.index.getX(i+2)];if(feature.getX(ids[0])!==record.index)continue;if(ids.some(v=>feature.getX(v)!==record.index))throw Error('Mixed LOD1 triangle feature');const body=metadata.lod1.static.some(([start,count])=>i>=start*3&&i<(start+count)*3);for(const v of ids){if(!localVertices.has(v))localVertices.set(v,localVertices.size);if(body)selected.add(v);}}
  const destinations=vertices.get(record.ordinal);if(destinations?.length!==localVertices.size)throw Error('Far surface vertex order mismatch');
  for(const [v,local]of localVertices){const dst=destinations[local],slot=Math.round(p.getX(v));if(Math.round(paint.getX(dst))!==slot)throw Error('Far surface paint binding mismatch');if(!selected.has(v))continue;const value=slots.get(slot);if(value){out.set(value,dst*4);copiedVertices++;}else unmappedWallVertices++;}
 }
 parent.setAttribute('_facade',new T.BufferAttribute(out,4));loaded.facadeTransfer={rule:'Existing nonzero runtime override + hash-bound scene.lod1.static ranges; exact exporter vertex order',featuresWithOverrides,copiedVertices,unmappedWallVertices};return loaded.facadeTransfer;
}
export async function prepareFarFacades(world,loaded,features){
 const originals=orderedFarSources(world,loaded).map(([o])=>o),loader=new GLTFLoader(),inputs=[];
 const boundBytes=async name=>{const r=await fetch(world.base+name);if(!r.ok)throw Error('Missing bound far surface input: '+name);const bytes=await r.arrayBuffer(),digest=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(n=>n.toString(16).padStart(2,'0')).join('');if(digest!==loaded.sidecar.sourceFiles[name])throw Error('Far surface binding mismatch: '+name);return bytes;};
 for(let i=0;i<world.manifest.chunks.length;i++){const chunk=world.manifest.chunks[i],scene=JSON.parse(new TextDecoder().decode(await boundBytes(chunk.scene))),gltf=await loader.parseAsync(await boundBytes(chunk.lods[1]),world.base),meshes=[];gltf.scene.traverse(o=>{if(o.isMesh&&o.material.name==='worldStatic')meshes.push(o);});if(meshes.length!==1)throw Error('Unsupported far surface layout');inputs.push({chunk:chunk.id,sourceIndex:i,scene,geometry:meshes[0].geometry,gltf});}

 try{return transferDeclaredFacadeRanges(loaded,originals,features,inputs);}finally{for(const input of inputs)input.gltf.scene.traverse(o=>{if(o.isMesh){o.geometry.dispose();for(const m of Array.isArray(o.material)?o.material:[o.material])m.dispose();}});}
}
