// docs/execution/scene-budget-diagnosis.md §Fine visibility, then compatible pooling.
// Main-only selection: untouched layer-1 shadow proxies retain their original coverage.
import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
export function validateSceneBudgetQuery(q){
 if(q.get('sceneBudget')!=='1'||q.has('baseline')||['crownV2','crownV3','foliageExp1'].some(k=>q.has(k)&&q.get(k)!=='off'))throw Error('sceneBudget=1 requires crown/foliage OFF; baseline and allocator combinations are unsupported');
}
export function featureRows(mesh,feature){
 const g=mesh.geometry,p=g.attributes.position,index=g.index,rows=new Map();
 for(let i=0;i<(index?.count??p.count);i+=3){
  const a=index?index.getX(i):i;
  const key=feature?feature.getX(a):mesh.userData.costCategory==='DEM'?`${Math.floor(p.getX(a)/2000)},${Math.floor(p.getZ(a)/2000)}`:'whole';
  let row=rows.get(key);if(!row){row={indices:[],bounds:new T.Box3()};rows.set(key,row);}
  for(let j=0;j<3;j++){const n=index?index.getX(i+j):i+j;row.indices.push(n);row.bounds.expandByPoint(new T.Vector3().fromBufferAttribute(p,n));}
 }
 return [...rows.values()];
}
// Exact geometry/layout identity; instance-specific attributes are copied, not identity keys.
export function geometryKey(g){
 const attrs=Object.entries(g.attributes).filter(([,a])=>!a.isInstancedBufferAttribute).sort(([a],[b])=>a.localeCompare(b));
 return JSON.stringify([g.index?Array.from(g.index.array):null,attrs.map(([n,a])=>[n,a.itemSize,a.normalized,a.array.constructor.name,Array.from(a.array)])]);
}
const layout=g=>JSON.stringify(Object.entries(g.attributes).filter(([,a])=>!a.isInstancedBufferAttribute).sort().map(([n,a])=>[n,a.itemSize,a.normalized,a.array.constructor.name]));
const capacity=n=>n<=256?Math.max(1,n):Math.max(1001,n);
function visible(o){for(let p=o;p;p=p.parent)if(!p.visible)return false;return true;}
export function installSceneBudget(scene,camera,features=new WeakMap()){
 const root=new T.Group();root.name='opt-in scene budget main';scene.updateMatrixWorld(true);
 let sources=[];const known=new WeakSet();
 const attached=o=>{for(let p=o;p;p=p.parent){if(p===root)return false;if(p===scene)return true;}return false;};
 function collect(){
  sources=sources.filter(({mesh:o})=>attached(o));
  scene.traverse(o=>{if(o.isMesh&&!o.userData.contextRing&&attached(o)&&!known.has(o)&&camera.layers.test(o.layers)&&!Array.isArray(o.material)){known.add(o);sources.push({mesh:o,geometry:null});}});
  for(const source of sources)if(source.geometry!==source.mesh.geometry){const o=source.mesh;source.geometry=o.geometry;source.rows=o.isInstancedMesh?null:featureRows(o,features.get(o.geometry));source.key=o.isInstancedMesh?geometryKey(o.geometry):layout(o.geometry);}
 }
 collect();scene.add(root);let previous=null;
 const report={enabled:true,source:'scene-budget-diagnosis.md',paddingMetres:.5,staticPoolMetres:800,instancePool:'all compatible visible instances',distanceLOD:false,updates:0};
 function update(){
  scene.updateMatrixWorld(true);camera.updateMatrixWorld();collect();
  const signature=JSON.stringify([camera.projectionMatrix.elements,camera.matrixWorld.elements,sources.map(({mesh:o})=>[o.uuid,o.geometry.uuid,o.visible,o.count,o.matrixWorld.elements])]);
  if(signature===previous)return;
  previous=signature;
  for(const o of [...root.children]){root.remove(o);o.geometry.dispose();o.dispose?.();}
  const frustum=new T.Frustum().setFromProjectionMatrix(new T.Matrix4().multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse)),buckets=new Map();
  let rejectedTriangles=0,retainedTriangles=0;
  const put=(key,item)=>{if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push(item);};
  for(const source of sources){const o=source.mesh,g=o.geometry;
   // Original main mesh stays alive for LOD updates and source identity, on unused layer 2.
   o.layers.set(2);
   if(!visible(o)||o.isInstancedMesh&&!o.count)continue;
   if(o.frustumCulled&&!frustum.intersectsObject(o))continue;
   const triangles=(g.index?.count??g.attributes.position.count)/3;
   if(o.isInstancedMesh){
    if(!g.boundingBox)g.computeBoundingBox();
    for(let i=0;i<o.count;i++){
     const m=new T.Matrix4();o.getMatrixAt(i,m);m.premultiply(o.matrixWorld);
     const bounds=g.boundingBox.clone().applyMatrix4(m).expandByScalar(report.paddingMetres);
     if(!frustum.intersectsBox(bounds)){rejectedTriangles+=triangles;continue;}
     const attrs=Object.entries(g.attributes).filter(([,a])=>a.isInstancedBufferAttribute).sort().map(([n,a])=>[n,a.itemSize,a.normalized,a.meshPerAttribute,a.array.constructor.name]);
     const key=JSON.stringify(['instance',o.material.uuid,source.key,attrs,o.renderOrder,o.userData.costCategory,o.material.transparent?o.uuid:null]);
     put(key,{o,i,m});retainedTriangles+=triangles;
    }
   }else{
    for(const row of source.rows){const bounds=row.bounds.clone().applyMatrix4(o.matrixWorld).expandByScalar(report.paddingMetres);
     if(!frustum.intersectsBox(bounds)){rejectedTriangles+=row.indices.length/3;continue;}
     const c=bounds.getCenter(new T.Vector3()),cell=`${Math.floor(c.x/800)},${Math.floor(c.z/800)}`;
     // Keep exact model matrices and transparent ordering; do not round or rebake positions.
     const key=JSON.stringify(['static',o.material.uuid,source.key,o.matrixWorld.elements,o.renderOrder,o.userData.costCategory,cell,o.material.transparent?o.uuid:null]);
     put(key,{o,row});retainedTriangles+=row.indices.length/3;
    }
   }
  }
  for(const items of buckets.values()){
   const first=items[0],o=first.o;let mesh;
   if(o.isInstancedMesh){
    const count=items.length,g=new T.BufferGeometry();
    for(const [n,a] of Object.entries(o.geometry.attributes)){
     if(!a.isInstancedBufferAttribute){g.setAttribute(n,a);continue;}
     if(a.meshPerAttribute!==1)throw Error('sceneBudget unsupported grouped instance attribute: '+n);
     const attr=new T.InstancedBufferAttribute(new a.array.constructor(capacity(count)*a.itemSize),a.itemSize,a.normalized);
     items.forEach(({o,i},j)=>{const source=o.geometry.attributes[n];for(let k=0;k<a.itemSize;k++)attr.array[j*a.itemSize+k]=source.array[i*a.itemSize+k];});g.setAttribute(n,attr);
    }
    g.setIndex(o.geometry.index);mesh=new T.InstancedMesh(g,o.material,capacity(count));mesh.count=count;
    items.forEach(({m},i)=>mesh.setMatrixAt(i,m));mesh.computeBoundingBox();mesh.computeBoundingSphere();
   }else{
    const perMesh=new Map();for(const {o,row} of items){if(!perMesh.has(o))perMesh.set(o,[]);perMesh.get(o).push(...row.indices);}
    const pieces=[...perMesh].map(([o,ids])=>{const g=o.geometry.clone();g.setIndex(ids);return g;});
    const g=pieces.length===1?pieces[0]:mergeGeometries(pieces);if(!g)throw Error('sceneBudget incompatible static merge');
    if(pieces.length>1)pieces.forEach(p=>p.dispose());g.computeBoundingBox();g.computeBoundingSphere();mesh=new T.Mesh(g,o.material);mesh.matrixAutoUpdate=false;mesh.matrix.copy(o.matrixWorld);
   }
   mesh.name='sceneBudget '+o.name;mesh.castShadow=false;mesh.receiveShadow=o.receiveShadow;mesh.renderOrder=o.renderOrder;mesh.userData.costCategory=o.userData.costCategory;root.add(mesh);
  }
  Object.assign(report,{updates:report.updates+1,retainedTriangles,rejectedTriangles,pooledDraws:root.children.length,mainSourceMeshes:sources.length});
 }
 update();return {report,update};
}
