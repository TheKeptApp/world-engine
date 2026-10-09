// R-approved Stage 2 trial; default off, no shader/material/water/look edits.
import * as T from 'three/webgpu';
import {geometryFingerprint} from './spatial-cells.js';
export function farEligible(bounds,eye,view,near,minimum=400){
 if(bounds.distanceToPoint(eye)<minimum)return false;
 for(let i=0;i<8;i++){const p=new T.Vector3(i&1?bounds.max.x:bounds.min.x,i&2?bounds.max.y:bounds.min.y,i&4?bounds.max.z:bounds.min.z).applyMatrix4(view);if(-p.z<=near)return false;}return true;
}
const sha=async b=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',b)),n=>n.toString(16).padStart(2,'0')).join('');
export async function loadFarParent(base){
 const fetchBytes=async name=>{const r=await fetch(base+name);if(!r.ok)throw Error('Missing far input: '+name);return r.arrayBuffer();},s=JSON.parse(new TextDecoder().decode(await fetchBytes('far-parent.json')));
 if(s.schema!=='world-far-parent/1'||s.minimumDistanceMetres!==400||s.sourceFiles?.['world.json']!==s.sourceWorldSha256||!Array.isArray(s.bounds)||s.bounds.length!==6||!s.bounds.every(Number.isFinite)||s.bounds.slice(0,3).some((v,i)=>v>s.bounds[i+3]))throw Error('Invalid far schema/distance');
 for(const [name,digest]of Object.entries(s.sourceFiles))if(await sha(await fetchBytes(name))!==digest)throw Error('Far binding mismatch: '+name);
 const bytes=await fetchBytes(s.payload);if(await sha(bytes)!==s.payloadSha256)throw Error('Far payload binding mismatch');
 const types={Float32Array,Uint32Array,Uint16Array,Uint8Array,Int8Array,Int16Array,Int32Array},g=new T.BufferGeometry();
 for(const [name,a]of Object.entries(s.attributes)){const C=types[a.type];if(!C||a.offset%4||a.offset+a.bytes>bytes.byteLength)throw Error('Invalid far attribute');const attr=new T.BufferAttribute(new C(bytes,a.offset,a.bytes/C.BYTES_PER_ELEMENT),a.itemSize,a.normalized);if(name==='index')g.setIndex(attr);else g.setAttribute(name,attr);}
 if(geometryFingerprint(g)!==s.geometryFingerprint)throw Error('Far geometry fingerprint mismatch');g.computeBoundingBox();g.computeBoundingSphere();return {sidecar:s,geometry:g};
}
export function installFarParent(scene,camera,world,loaded,{features,spatialSidecar}={}){
 scene.updateMatrixWorld(true);const {sidecar:s,geometry:g}=loaded,wanted=new Set(s.sources),sources=[];
 world.root.traverse(o=>{if(o.isMesh&&!o.isInstancedMesh&&o.material===world.materials.static&&wanted.has(geometryFingerprint(o.geometry)))sources.push({o,visible:o.visible});});
 if(sources.length!==s.sources.length)throw Error('Far source coverage mismatch');
 const parent=new T.Mesh(g,world.materials.static);parent.name='simplified far complete core';parent.castShadow=false;parent.receiveShadow=true;parent.userData.costCategory='opaque world';parent.visible=false;scene.add(parent);features?.set(g,g.attributes._feature);g.deleteAttribute('_feature');spatialSidecar.geometries[s.geometryFingerprint]=s.rows;
 const bounds=new T.Box3(new T.Vector3(...s.bounds.slice(0,3)),new T.Vector3(...s.bounds.slice(3))).expandByScalar(.5),report={enabled:true,selected:false,minimumDistanceMetres:400,geometryErrorMetres:s.geometryErrorMetres,parentScope:s.parentScope,swaps:0,children:sources.length,atomicCoverage:true};
 function update(){camera.updateMatrixWorld();const cameraBounds=bounds.clone().applyMatrix4(camera.matrixWorldInverse),depthMin=-cameraBounds.max.z;Object.assign(report,{worldBounds:[...bounds.min.toArray(),...bounds.max.toArray()],cameraBounds:[...cameraBounds.min.toArray(),...cameraBounds.max.toArray()],minimumDepthMetres:depthMin,nearestDistanceMetres:bounds.distanceToPoint(camera.position),projectedErrorPlanningPixels:depthMin>camera.near?s.geometryErrorMetres*(camera.userData.drawableHeight??0)/(2*Math.tan(camera.fov*Math.PI/360)*depthMin):null});const eligible=farEligible(bounds,camera.position,camera.matrixWorldInverse,camera.near);if(eligible===report.selected)return;for(const {o,visible}of sources){o.userData.farShadowVisible=visible;o.visible=eligible?false:visible;}parent.visible=eligible;report.selected=eligible;report.swaps++;}
 update();return {update,report,parent};
}
