// Default-off, same shadow source geometry/material/order/reach. Unsupported deformation retains source.
import * as T from 'three/webgpu';
import {featureRows} from './scene-budget.js';
const U=2**-23,GAMMA=8*U/(1-8*U),TINY=8*2**-126;
export function fpTransformBox(box,matrix){
 const e=matrix.elements.map(Math.fround),lo=box.min.toArray(),hi=box.max.toArray(),min=[],max=[];
 for(let r=0;r<3;r++){let a=e[12+r],b=a,magnitude=Math.abs(a);for(let k=0;k<3;k++){const x=e[k*4+r]*lo[k],y=e[k*4+r]*hi[k];a+=Math.min(x,y);b+=Math.max(x,y);magnitude+=Math.max(Math.abs(x),Math.abs(y));}const error=GAMMA*magnitude+TINY;min.push(a-error);max.push(b+error);}
 return new T.Box3(new T.Vector3(...min),new T.Vector3(...max));
}
export function rigidIntersects(box,instance,modelView,projection){
 const local=instance?fpTransformBox(box,instance):box,clip=fpTransformBox(fpTransformBox(local,modelView),projection);
 if([...clip.min.toArray(),...clip.max.toArray()].some(v=>!Number.isFinite(v)))return true;return clip.max.x>=-1&&clip.min.x<=1&&clip.max.y>=-1&&clip.min.y<=1&&clip.max.z>=-1&&clip.min.z<=1;
}
export function needsUnboundedPadding(o,world){
 const m=o.material,g=o.geometry;
 if(Array.isArray(m)||Object.values(g.attributes).some(a=>a.isInstancedBufferAttribute&&a.meshPerAttribute!==1)||o.isBatchedMesh||o.instanceColor||o.morphTexture||o.isSkinnedMesh||Object.keys(g.morphAttributes??{}).length||m.displacementMap||m.castShadowPositionNode||m.vertexNode)return true;
 if(!m.positionNode)return false;
 if(m.positionNode!==world?.materials?.foliage?.positionNode)return true;
 const paint=g.attributes._paint;if(!paint)return true;for(let i=0;i<paint.count;i++)if(paint.getW(i)>0)return true;
 return false;
}
const positionKey=g=>{let h=2166136261;const a=g.attributes.position.array;for(const b of new Uint8Array(a.buffer,a.byteOffset,a.byteLength))h=Math.imul(h^b,16777619);return `${g.attributes.position.count}/${h>>>0}`;};
export function installShadowCells(scene,camera,world,{features=new WeakMap(),renderer}={}){
 const light=[];scene.traverse(o=>{if(o.isLight&&o.castShadow&&o.shadow){if(!o.isDirectionalLight)throw Error('shadowCells supports directional lights only');light.push({o,mask:o.shadow.camera.layers.mask});}});if(light.length!==1)throw Error('shadowCells requires one directional light');
 const {o:sun,mask}=light[0],layer=29,bit=1<<layer,root=new T.Group();root.name='shadow cells opt-in';scene.add(root);sun.shadow.camera.layers.set(layer);
 const sources=[],known=new WeakSet(),provenance=new Map();world.root.traverse(o=>{if(o.isMesh&&features.has(o.geometry)){const key=positionKey(o.geometry),old=provenance.get(key),attr=features.get(o.geometry);if(old&&(old.count!==attr.count||old.array.some((v,i)=>v!==attr.array[i])))throw Error('Shadow provenance collision');provenance.set(key,attr);}});
 const precision=renderer?.backend?.gl?.getShaderPrecisionFormat(renderer.backend.gl.VERTEX_SHADER,renderer.backend.gl.HIGH_FLOAT)?.precision??23;
 const report={highpPrecision:precision,enabled:true,reachChanged:false,lodChanged:false,padding:'rigid: gamma8 highp transform interval; deformed: unbounded, source retained',updates:0,triangles:0,draws:0,unboundedTriangles:0,bufferBytes:0};
 const attached=o=>{for(let p=o;p;p=p.parent){if(p===root)return false;if(p===scene)return true;}return false;},visible=o=>{for(let p=o;p;p=p.parent)if(!p.visible)return false;return true;};
 function collect(){scene.traverse(o=>{if(o.isMesh&&attached(o)&&o.castShadow&&!known.has(o)&&((mask&0xFFFFFFFE)?(mask&o.layers.mask):camera.layers.test(o.layers))){known.add(o);sources.push({o,geometry:null});}});}
 function prepare(s){const o=s.o,g=o.geometry;if(s.geometry===g)return;if(s.mesh){root.remove(s.mesh);s.mesh.geometry.dispose();s.mesh.dispose?.();}s.geometry=g;s.unbounded=precision<23||needsUnboundedPadding(o,world);s.mesh=null;if(s.unbounded)return;
  const clone=new T.BufferGeometry();for(const [name,a]of Object.entries(g.attributes)){if(a.isInstancedBufferAttribute){const b=new T.InstancedBufferAttribute(new a.array.constructor(a.array.length),a.itemSize,a.normalized,a.meshPerAttribute);b.setUsage(a.usage);clone.setAttribute(name,b);report.bufferBytes+=b.array.byteLength;}else clone.setAttribute(name,a);}clone.boundingSphere=g.boundingSphere?.clone()??null;clone.boundingBox=g.boundingBox?.clone()??null;
  if(o.isInstancedMesh){clone.setIndex(g.index);s.mesh=new T.InstancedMesh(clone,o.material,o.instanceMatrix.count);s.mesh.instanceMatrix.setUsage(o.instanceMatrix.usage);report.bufferBytes+=s.mesh.instanceMatrix.array.byteLength;}
  else{const index=new T.BufferAttribute(new Uint32Array(g.index?.count??g.attributes.position.count),1);index.setUsage(T.DynamicDrawUsage);clone.setIndex(index);report.bufferBytes+=index.array.byteLength;const attr=features.get(g)??provenance.get(positionKey(g));s.mesh=new T.Mesh(clone,o.material);s.rows=featureRows(o,attr);s.owners=new Map();s.rows.forEach((r,id)=>{for(let i=0;i<r.indices.length;i+=3){const vertex=r.indices[i];if(s.owners.has(vertex)&&s.owners.get(vertex)!==id)throw Error('Ambiguous shadow feature ownership');s.owners.set(vertex,id);}});}
  const p=s.mesh;p.name='shadowCells '+o.name;p.layers.set(layer);p.castShadow=true;p.receiveShadow=false;p.matrixAutoUpdate=false;p.matrix.copy(o.matrixWorld);p.frustumCulled=false;p.renderOrder=o.renderOrder;p.userData.costCategory=o.userData.costCategory;p.userData.spatialOrder={sourceID:o.userData.spatialOrder?.sourceID??o.id,groupOrder:0,run:0};root.add(p);
 }
 const matrix=new T.Matrix4(),modelView=new T.Matrix4(),frustum=new T.Frustum();
 function update(){scene.updateMatrixWorld(true);sun.shadow.updateMatrices(sun);const sc=sun.shadow.camera;frustum.setFromProjectionMatrix(new T.Matrix4().multiplyMatrices(sc.projectionMatrix,sc.matrixWorldInverse));collect();let triangles=0,draws=0,unboundedTriangles=0;
  for(const s of sources){const o=s.o;if(!attached(o)){if(s.mesh)s.mesh.visible=false;continue;}prepare(s);const eligible=visible(o)&&o.castShadow&&(!o.frustumCulled||frustum.intersectsObject(o));const g=o.geometry,n=Math.min(g.index?.count??g.attributes.position.count,g.drawRange.count);
   if(s.unbounded){o.layers.enable(layer);if(eligible){const t=n/3*(o.isInstancedMesh?o.count:1);triangles+=t;unboundedTriangles+=t;draws+=o.isInstancedMesh&&o.count===0?0:1;}continue;}o.layers.disable(layer);const p=s.mesh;p.matrix.copy(o.matrixWorld);p.updateMatrixWorld(true);modelView.multiplyMatrices(sc.matrixWorldInverse,o.matrixWorld);let count=0;
   if(eligible&&o.isInstancedMesh){if(!g.boundingBox)g.computeBoundingBox();for(let i=0;i<o.count;i++){o.getMatrixAt(i,matrix);if(!rigidIntersects(g.boundingBox,matrix,modelView,sc.projectionMatrix))continue;p.setMatrixAt(count,matrix);for(const [name,a]of Object.entries(g.attributes))if(a.isInstancedBufferAttribute)for(let k=0;k<a.itemSize;k++)p.geometry.attributes[name].array[count*a.itemSize+k]=a.array[i*a.itemSize+k];count++;}}
   else if(eligible){const selected=s.rows.map(r=>rigidIntersects(r.bounds,null,modelView,sc.projectionMatrix)),index=g.index;for(let i=g.drawRange.start;i<Math.min(g.index?.count??g.attributes.position.count,g.drawRange.start+g.drawRange.count);i+=3){const a=index?index.getX(i):i;if(!selected[s.owners.get(a)])continue;for(let k=0;k<3;k++)p.geometry.index.array[count++]=index?index.getX(i+k):i+k;}}
   p.visible=count>0;if(o.isInstancedMesh){p.count=count;p.instanceMatrix.needsUpdate=true;for(const a of Object.values(p.geometry.attributes))if(a.isInstancedBufferAttribute)a.needsUpdate=true;triangles+=count*n/3;}else{p.geometry.setDrawRange(0,count);p.geometry.index.needsUpdate=true;triangles+=count/3;}if(count)draws++;
  }Object.assign(report,{updates:report.updates+1,triangles,draws,unboundedTriangles});
 }
 const before=scene.onBeforeRender;scene.onBeforeRender=function(renderer,s,c,...args){before.call(this,renderer,s,c,...args);if(c===camera)update();};return {update,report,root};
}
