// ff4f86e spatial-cells-design §§Recommendation, Exporter contract.
// Lossless opt-in: immutable vertex data, reusable bounded selection buffers.
import * as T from 'three/webgpu';
import {featureRows,geometryKey} from './scene-budget.js';
export const SCHEMA='world-spatial-cells/1';
export function geometryFingerprint(g){
 let h=2166136261;for(const a of [g.attributes.position.array,g.index?.array??new Uint32Array()]){
  const bytes=new Uint8Array(a.buffer,a.byteOffset,a.byteLength);for(const b of bytes)h=Math.imul(h^b,16777619);
 }return `${g.attributes.position.count}/${g.index?.count??0}/${h>>>0}`;
}
export function describeRows(mesh,feature){
 return featureRows(mesh,feature).map(row=>{
  const bounds=row.bounds.clone().applyMatrix4(mesh.matrixWorld).expandByScalar(.5),c=bounds.getCenter(new T.Vector3());
  return {indices:row.indices,bounds:[...row.bounds.min.toArray(),...row.bounds.max.toArray()],leaf:[Math.floor(c.x/100),Math.floor(c.z/100)],page:[Math.floor(c.x/200),Math.floor(c.z/200)],groups:[400,800].map(s=>[Math.floor(c.x/s),Math.floor(c.z/s)])};
 });
}
export function validateSpatialQuery(q){
 if(q.get('spatialCells')!=='1'||['sceneBudget','baseline'].some(k=>q.has(k))||['crownV2','crownV3','foliageExp1'].some(k=>q.has(k)&&q.get(k)!=='off'))throw Error('spatialCells=1 requires default crown/foliage OFF, no other experiment');
 if(q.has('spatialGroup')&&!['400','800'].includes(q.get('spatialGroup')))throw Error('spatialGroup must be 400 or 800');
 if(q.has('spatialMergeRuns')&&!['0','1'].includes(q.get('spatialMergeRuns')))throw Error('spatialMergeRuns must be 0 or 1');
 if(q.has('spatialFar'))throw Error('Simplified far parents are unavailable until the lossless pixel gate passes');
}
const box=a=>new T.Box3(new T.Vector3(...a.slice(0,3)),new T.Vector3(...a.slice(3)));
const layout=g=>JSON.stringify(Object.entries(g.attributes).filter(([,a])=>!a.isInstancedBufferAttribute).sort().map(([n,a])=>[n,a.itemSize,a.normalized,a.array.constructor.name]));
const capacity=n=>n<=256?Math.max(1,n):Math.max(1001,n);
function effectiveVisible(o){for(let p=o;p;p=p.parent)if(!p.visible)return false;return true;}
// Match Three r180's opaque comparator, retaining source identity for derived draws.
export function spatialOpaqueSort(a,b){
 const A=a.object.userData.spatialOrder,B=b.object.userData.spatialOrder;
 return (A?.groupOrder??a.groupOrder)-(B?.groupOrder??b.groupOrder)||a.renderOrder-b.renderOrder||a.z-b.z||(A?.sourceID??a.id)-(B?.sourceID??b.id)||(A?.run??0)-(B?.run??0)||a.id-b.id;
}
export function orderedCellRuns(rows,index,groupMetres){
 // A complete feature can revisit a cell. Preserve original primitive order across runs.
 const owners=new Map();for(const row of rows)for(let i=0;i<row.indices.length;i+=3){const key=row.indices.slice(i,i+3).join(',');let q=owners.get(key);if(!q){q=[];owners.set(key,q);}q.push(row);}
 const runs=[];let current;
 for(let i=0;i<index.count;i+=3){const ids=[index.getX(i),index.getX(i+1),index.getX(i+2)],q=owners.get(ids.join(',')),row=q?.shift();if(!row)throw Error('Spatial rows do not cover original primitive order');const c=row.worldBounds.getCenter(new T.Vector3()),cell=`${Math.floor(c.x/groupMetres)},${Math.floor(c.z/groupMetres)}`;
  if(current?.cell!==cell){current={cell,atoms:[]};runs.push(current);}let atom=current.atoms.at(-1);if(atom?.row!==row){atom={row,indices:[]};current.atoms.push(atom);}atom.indices.push(...ids);
 }return runs;
}
export function installSpatialCells(scene,camera,{renderer,features=new WeakMap(),sidecar,groupMetres=800,mergeSourceRuns=false}={}){
 if(sidecar?.schema!==SCHEMA||![400,800].includes(groupMetres))throw Error('Invalid spatial sidecar/group size');
 renderer?.setOpaqueSort(spatialOpaqueSort);scene.updateMatrixWorld(true);const root=new T.Group();root.name='spatial cells opt-in main';scene.add(root);
 const sources=[],known=new WeakSet(),pools=new Map(),scratch=new T.Matrix4(),bounds=new T.Box3(),frustum=new T.Frustum();
 const report={enabled:true,schema:SCHEMA,leafMetres:100,pageMetres:200,groupMetres,mergeSourceRuns,geometryErrorMetres:0,updates:0,rebuilds:0,bufferBytes:0,exportRows:0,derivedRows:0};
 let previous='',pages=new Map();
 const attached=o=>{for(let p=o;p;p=p.parent){if(p===root)return false;if(p===scene)return true;}return false;};
 function collect(){
  let changed=false;
  for(let i=sources.length-1;i>=0;i--)if(!attached(sources[i].o)){known.delete(sources[i].o);sources.splice(i,1);changed=true;}
  scene.traverse(o=>{if(o.isMesh&&!o.userData.contextRing&&attached(o)&&!known.has(o)&&camera.layers.test(o.layers)&&!Array.isArray(o.material)){known.add(o);sources.push({o});changed=true;}});
  for(const s of sources){const o=s.o;if(!attached(o)){if(!s.removed){s.removed=true;changed=true;}continue;}
   if(s.geometry===o.geometry)continue;changed=true;s.geometry=o.geometry;
   if(o.isInstancedMesh){s.key=geometryKey(o.geometry);s.rows=null;}
   else{
    const exported=sidecar.geometries[geometryFingerprint(o.geometry)];
    const rows=exported??describeRows(o,features.get(o.geometry));
    s.rows=rows.map(r=>({...r,localBounds:box(r.bounds),worldBounds:box(r.bounds).applyMatrix4(o.matrixWorld).expandByScalar(.5)}));
    report[exported?'exportRows':'derivedRows']+=rows.length;s.key=layout(o.geometry);
   }
  }return changed;
 }
 function rebuild(){
  pages=new Map();
  for(const s of sources)for(const row of s.rows??[]){const c=row.worldBounds.getCenter(new T.Vector3()),pageID=`${Math.floor(c.x/200)},${Math.floor(c.z/200)}`,leafID=`${Math.floor(c.x/100)},${Math.floor(c.z/100)}`;
   let page=pages.get(pageID);if(!page){page={bounds:new T.Box3(),leaves:new Map()};pages.set(pageID,page);}let leaf=page.leaves.get(leafID);if(!leaf){leaf={bounds:new T.Box3(),rows:[]};page.leaves.set(leafID,leaf);}page.bounds.union(row.worldBounds);leaf.bounds.union(row.worldBounds);leaf.rows.push(row);
  }
  report.residentPages=pages.size;report.visibilityLeaves=[...pages.values()].reduce((n,p)=>n+p.leaves.size,0);
  for(const p of pools.values()){root.remove(p.mesh);p.mesh.geometry.dispose();p.mesh.dispose?.();}pools.clear();report.bufferBytes=0;
  const bins=new Map();let order=0;
  for(const s of sources){if(s.removed)continue;const o=s.o,g=o.geometry;
   const attrs=Object.entries(g.attributes).filter(([,a])=>a.isInstancedBufferAttribute).sort().map(([n,a])=>[n,a.itemSize,a.normalized,a.meshPerAttribute,a.array.constructor.name]);
   // Preserve original model transforms; no Float32 world-matrix rebaking.
   const base=JSON.stringify([o.isInstancedMesh,o.material.uuid,s.key,attrs,o.matrixWorld.elements,o.renderOrder,o.receiveShadow,o.userData.costCategory,o.material.transparent||!o.isInstancedMesh?o.uuid:null]);
   const put=(key,atom)=>{if(!bins.has(key))bins.set(key,{o,atoms:[],base,order:order++});bins.get(key).atoms.push(atom);};
   if(o.isInstancedMesh)put(base,{s});else{const runs=orderedCellRuns(s.rows,g.index,groupMetres);runs.forEach((run,i)=>{for(const atom of run.atoms)put(mergeSourceRuns?base:base+'/'+i,{s,...atom});});}
  }
  const staticStorage=new Map();
  for(const b of bins.values())if(!b.o.isInstancedMesh){let store=staticStorage.get(b.base);if(!store){store={sources:new Set()};staticStorage.set(b.base,store);}for(const {s}of b.atoms)store.sources.add(s);}
  for(const store of staticStorage.values()){
   store.offsets=new Map();let vertices=0;for(const source of store.sources){store.offsets.set(source,vertices);vertices+=source.geometry.attributes.position.count;}store.attrs={};
   const first=[...store.sources][0];for(const [name,a]of Object.entries(first.geometry.attributes)){
    if(store.sources.size===1){store.attrs[name]=a;continue;}
    const array=new a.array.constructor(vertices*a.itemSize);for(const [source,offset]of store.offsets)array.set(source.geometry.attributes[name].array,offset*a.itemSize);
    store.attrs[name]=new T.BufferAttribute(array,a.itemSize,a.normalized);report.bufferBytes+=array.byteLength;
   }
  }
  for(const [key,b]of bins){const {o,atoms}=b,g=new T.BufferGeometry();let mesh,p;
   if(o.isInstancedMesh){
    const n=atoms.reduce((n,{s})=>n+s.o.instanceMatrix.count,0),cap=capacity(n);
    for(const [name,a]of Object.entries(o.geometry.attributes)){
     if(!a.isInstancedBufferAttribute){g.setAttribute(name,a);continue;}
     if(a.meshPerAttribute!==1)throw Error('Grouped instance attributes unsupported: '+name);
     const attr=new T.InstancedBufferAttribute(new a.array.constructor(cap*a.itemSize),a.itemSize,a.normalized);attr.setUsage(T.DynamicDrawUsage);g.setAttribute(name,attr);report.bufferBytes+=attr.array.byteLength;
    }g.setIndex(o.geometry.index);mesh=new T.InstancedMesh(g,o.material,cap);mesh.count=0;mesh.instanceMatrix.setUsage(T.DynamicDrawUsage);report.bufferBytes+=mesh.instanceMatrix.array.byteLength;p={mesh,atoms,instance:true};
   }else{
    const store=staticStorage.get(b.base),offsets=store.offsets;for(const [name,a]of Object.entries(store.attrs))g.setAttribute(name,a);
    // Shared storage must not change the previous group's render-sort centre.
    if(!o.geometry.boundingBox)o.geometry.computeBoundingBox();if(!o.geometry.boundingSphere)o.geometry.computeBoundingSphere();g.boundingBox=o.geometry.boundingBox.clone();g.boundingSphere=o.geometry.boundingSphere.clone();
    const indices=new T.BufferAttribute(new Uint32Array(atoms.reduce((n,{indices})=>n+indices.length,0)),1);indices.setUsage(T.DynamicDrawUsage);g.setIndex(indices);report.bufferBytes+=indices.array.byteLength;p={mesh:new T.Mesh(g,o.material),atoms,offsets,instance:false};mesh=p.mesh;
   }
   mesh.matrixAutoUpdate=false;mesh.matrix.copy(o.matrixWorld);mesh.castShadow=false;mesh.receiveShadow=o.receiveShadow;mesh.renderOrder=o.renderOrder;mesh.userData.costCategory=o.userData.costCategory;mesh.frustumCulled=false;mesh.name='spatial '+o.name;let groupOrder=0;for(let ancestor=o.parent;ancestor;ancestor=ancestor.parent)if(ancestor.isGroup&&ancestor.renderOrder)groupOrder=ancestor.renderOrder;mesh.userData.spatialOrder={sourceID:o.id,groupOrder,run:b.order};root.add(mesh);pools.set(key,p);
  }report.rebuilds++;report.poolCapacity=pools.size;
 }
 function update(){
  const started=performance.now();scene.updateMatrixWorld(true);camera.updateMatrixWorld();const changed=collect();if(changed)rebuild();
  const signature=JSON.stringify([camera.projectionMatrix.elements,camera.matrixWorld.elements,sources.filter(s=>!s.removed).map(({o})=>[o.geometry.uuid,o.visible,o.count,o.instanceMatrix?.version,o.matrixWorld.elements])]);
  if(signature===previous)return;previous=signature;
  frustum.setFromProjectionMatrix(scratch.multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse));
  for(const page of pages.values()){const pageVisible=frustum.intersectsBox(page.bounds);for(const leaf of page.leaves.values()){const leafVisible=pageVisible&&frustum.intersectsBox(leaf.bounds);for(const row of leaf.rows)row.selected=leafVisible&&frustum.intersectsBox(row.worldBounds);}}
  const eligible=new Map();for(const s of sources){const o=s.o;o.layers.set(2);eligible.set(s,!s.removed&&effectiveVisible(o)&&(!o.frustumCulled||frustum.intersectsObject(o)));}
  let triangles=0,draws=0;
  for(const p of pools.values()){
   const {mesh,atoms}=p;let count=0;
   for(const {s,row,indices}of atoms){const o=s.o;if(!eligible.get(s))continue;
    if(p.instance){const g=o.geometry;if(!g.boundingBox)g.computeBoundingBox();for(let i=0;i<o.count;i++){
     o.getMatrixAt(i,scratch);bounds.copy(g.boundingBox).applyMatrix4(scratch).applyMatrix4(o.matrixWorld).expandByScalar(.5);if(!frustum.intersectsBox(bounds))continue;
     mesh.setMatrixAt(count,scratch);for(const [name,a]of Object.entries(g.attributes))if(a.isInstancedBufferAttribute)for(let k=0;k<a.itemSize;k++)mesh.geometry.attributes[name].array[count*a.itemSize+k]=a.array[i*a.itemSize+k];count++;
    }}else if(row.selected){const a=mesh.geometry.index.array,offset=p.offsets.get(s);for(const index of indices)a[count++]=index+offset;}
   }
   mesh.visible=count>0;
   if(p.instance){mesh.count=count;mesh.instanceMatrix.needsUpdate=true;for(const a of Object.values(mesh.geometry.attributes))if(a.isInstancedBufferAttribute)a.needsUpdate=true;triangles+=count*(mesh.geometry.index?.count??mesh.geometry.attributes.position.count)/3;}
   else{mesh.geometry.setDrawRange(0,count);mesh.geometry.index.clearUpdateRanges();mesh.geometry.index.addUpdateRange(0,count);mesh.geometry.index.needsUpdate=true;triangles+=count/3;}
   if(count)draws++;
  }Object.assign(report,{updates:report.updates+1,triangles,draws,updateMs:performance.now()-started});
 }
 update();return {update,report,root};
}
