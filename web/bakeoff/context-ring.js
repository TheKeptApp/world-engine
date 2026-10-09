// world-edge-options.md §First test; native ContextRing aerial geometry and 200 m coverage fade.
// Calibration-v2 owns matte response; existing palette and single scene airlight/grade are reused.
import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {attribute,positionWorld,vec3,float,min,smoothstep,mix} from 'three/tsl';

export function ringStrips(core,cov){const [x0,z0,x1,z1]=core,[a,b,c,d]=cov;return [[a,b,c,z0],[a,z1,c,d],[a,z0,x0,z1],[x1,z0,c,z1]].filter(r=>r[2]>r[0]&&r[3]>r[1]);}
export function clipPolygon(poly,rect){
 for(const [axis,bound,sign] of [[0,rect[0],1],[2,rect[1],1],[0,rect[2],-1],[2,rect[3],-1]]){
  const out=[];for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length],da=(a[axis]-bound)*sign,db=(b[axis]-bound)*sign;
   if(da>=0)out.push(a);if((da>=0)!==(db>=0)){const t=da/(da-db);out.push(a.map((v,k)=>v+(b[k]-v)*t));}}
  poly=out;if(poly.length<3)return [];
 }return poly;
}
export function clippedTriangles(mesh,core,coverage){
 const out=[],strips=ringStrips(core,coverage);
 for(let i=0;i<mesh.index.length;i+=3){const ids=mesh.index.slice(i,i+3),tri=ids.map(n=>mesh.position.slice(n*3,n*3+3)),paint=mesh.paint.slice(ids[0]*4,ids[0]*4+4);
  for(const strip of strips){const p=clipPolygon(tri,strip);for(let k=1;k+1<p.length;k++){
   const a=p[0],b=p[k],c=p[k+1],area=(b[0]-a[0])*(c[2]-a[2])-(b[2]-a[2])*(c[0]-a[0]);
   if(Math.abs(area)>1e-7)out.push({points:[a,b,c],paint});
  }}
 }return out;
}
export function installContextRing(b,data,{mergeLand=false,mergeOpaque=false,mergeAllowed=()=>true}={}){
 const report={enabled:true,status:data.status,area:data.area,source:data.source,buildings:0,addedShadowTriangles:0,addedShadowDraws:0,uploadedTriangles:0,uploadedDraws:0,geometryBytes:0};
 if(data.status==='missing-context-source')return {report,meshes:[]};
 if(![1,2].includes(data.formatVersion))throw Error('Unsupported context geometry version');
 const origin=b.world.manifest.frame.origin;
 if(Math.abs(origin.latitude-data.origin.latitude)>1e-8||Math.abs(origin.longitude-data.origin.longitude)>1e-8)throw Error('Context and detailed origins differ');
 const names=new Map(Object.entries(data.namedSlots).map(([name,slot])=>[slot,name])),slots=new Map();
 for(const slot of b.world.palettes.slots)for(const name of slot.names||[])slots.set(name,slot.slot);
 const palette=b.world.paletteTexture.image.data;
 const colour=(paint)=>{const [slot,shade,flags]=paint,name=flags&4?'lawn':names.get(slot),mapped=slots.get(name);let c;
  if(mapped!==undefined)c=new T.Color().fromArray(palette,mapped*4);else c=new T.Color(data.palette[slot]);
  if(name==='road')c.set(b.policy.look.materials.groundBaseHex.asphalt);
  if(flags&4)c.set(b.policy.look.materials.groundBaseHex.lawn);
  return c.multiplyScalar(shade).toArray();};
 const backdropSlot=slots.get('backdrop');
 const base=backdropSlot===undefined?new T.Color(data.palette[data.namedSlots.backdrop]):new T.Color().fromArray(palette,backdropSlot*4);
 const [x0,z0,x1,z1]=data.coverage;
 const edge=min(min(positionWorld.x.sub(x0),positionWorld.z.sub(z0)),min(float(x1).sub(positionWorld.x),float(z1).sub(positionWorld.z)));
 const material=new T.MeshStandardNodeMaterial({roughness:b.policy.look.materials.roughness.masonry,metalness:0});
 material.colorNode=mix(vec3(base.r,base.g,base.b),attribute('color','vec3'),smoothstep(0,data.fadeWidthM,edge));
 let waterMaterial=b.world.materials.water; b.world.root.traverse(o=>{if(o.isMesh&&o.userData.costCategory==='water')waterMaterial=o.material;});
 const groups=[[],[],[],[],[]],cx=(data.core[0]+data.core[2])/2,cz=(data.core[1]+data.core[3])/2;
 for(const cell of data.cells)for(const tri of clippedTriangles(cell.mesh,data.core,data.coverage)){
  const x=tri.points.reduce((s,p)=>s+p[0],0)/3,z=tri.points.reduce((s,p)=>s+p[2],0)/3;
  groups[(x>=cx?1:0)+(z>=cz?2:0)].push(tri);
 }
 groups[4]=clippedTriangles(data.water,data.core,data.coverage);
 // Keep the existing five ring batches; one opaque mass batch is bounded by the total cap.
 const landCount=groups.reduce((s,g)=>s+g.length,0);
 report.buildingCandidates=(data.buildingMasses||[]).length;report.buildings=0;report.inferredHeights=0;
 const masses=[];
 for(const b of data.buildingMasses||[]){
  if(landCount+masses.length+b.mesh.index.length/3>40000)continue;
  for(let i=0;i<b.mesh.index.length;i+=3){const ids=b.mesh.index.slice(i,i+3);masses.push({points:ids.map(n=>b.mesh.position.slice(n*3,n*3+3)),normal:b.normal.slice(ids[0]*3,ids[0]*3+3),paint:[data.namedSlots.residential,1,0,0]});}
  report.buildings++;if(b.heightSource==='typeDefault')report.inferredHeights++;
 }
 report.buildingsSkippedByBudget=report.buildingCandidates-report.buildings;
 groups.push(masses);
 if(landCount>40000)throw Error('Existing ring alone exceeds 40k triangle cap');
 if(mergeLand&&!mergeOpaque){groups[0].push(...groups[1],...groups[2],...groups[3]);groups[1]=[];groups[2]=[];groups[3]=[];}

 report.mergeLand=mergeLand;report.mergeOpaque=mergeOpaque;
 const meshes=[];
 for(let group=0;group<groups.length;group++){
  if(!groups[group].length)continue;const position=[],colors=[],normals=[],extra=[],paint=[],facade=[];
  for(const tri of groups[group])for(const p of tri.points){position.push(...p);colors.push(...colour(tri.paint));normals.push(...(tri.normal||[0,1,0]));extra.push(1,0,0,0);paint.push(...tri.paint);facade.push(0,0,0,0);}
  const geometry=new T.BufferGeometry();for(const [name,array,size] of [['position',position,3],['normal',normals,3],['color',colors,3],['_extra',extra,4],['_paint',paint,4],['_facade',facade,4]])geometry.setAttribute(name,new T.Float32BufferAttribute(array,size));
  geometry.setIndex(Array.from({length:position.length/3},(_,i)=>i));geometry.computeBoundingBox();geometry.computeBoundingSphere();
  const mesh=new T.Mesh(geometry,group===4?waterMaterial:material);mesh.name=`context ring ${group===4?'water':group===5?'building-masses':'land-roads-'+group}`;
  mesh.castShadow=false;mesh.receiveShadow=false;mesh.userData.contextRing=true;mesh.userData.costCategory=group===4?'context water':group===5?'context buildings':'context land/roads';mesh.userData.contextKind=group===4?'context-water':group===5?'context-building':'context-mapped-land-roads';
  b.scene.add(mesh);meshes.push(mesh);report.uploadedTriangles+=position.length/9;report.uploadedDraws++;report.geometryBytes+=Object.values(geometry.attributes).reduce((s,a)=>s+a.array.byteLength,0)+geometry.index.array.byteLength;
 }
 // Preserve original ring-source depth ordering before pooling; all share one material.
 // R requires exact Sloan pixels. This is a general camera rule, not a location recipe.
 const originals=meshes.filter(m=>m.userData.contextKind!=='context-water');let merged,priorOrder='';
 const update=()=>{if(!mergeOpaque||!originals.length)return;
  if(!mergeAllowed()){if(merged)b.scene.remove(merged);for(const m of originals)if(m.parent!==b.scene)b.scene.add(m);report.uploadedDraws=meshes.length;report.mergeActive=false;return;}
  for(const m of originals)b.scene.remove(m);if(merged&&merged.parent!==b.scene)b.scene.add(merged);report.mergeActive=true;report.uploadedDraws=meshes.filter(m=>m.userData.contextKind==='context-water').length+1;
  b.camera?.updateMatrixWorld();const projection=b.camera?new T.Matrix4().multiplyMatrices(b.camera.projectionMatrix,b.camera.matrixWorldInverse):null;
  const ordered=originals.map(m=>({m,z:projection?m.geometry.boundingSphere.center.clone().applyMatrix4(m.matrixWorld).applyMatrix4(projection).z:0})).sort((a,c)=>a.z-c.z||a.m.id-c.m.id).map(x=>x.m);
  const order=ordered.map(m=>m.id).join(',');if(order===priorOrder)return;priorOrder=order;
  const geometry=mergeGeometries(ordered.map(m=>m.geometry),false);if(!geometry)throw Error('Ring opaque layouts differ');
  if(merged){merged.geometry.dispose();merged.geometry=geometry;}else{merged=new T.Mesh(geometry,material);merged.name='context ring opaque';merged.castShadow=false;merged.receiveShadow=false;merged.userData={contextRing:true,costCategory:'context land/roads',contextKind:'context-mapped-land-roads'};b.scene.add(merged);}
  for(const m of originals)b.scene.remove(m);
  report.opaqueSourceOrder=ordered.map(m=>m.name);report.uploadedDraws=meshes.filter(m=>m.userData.contextKind==='context-water').length+1;
 };
 update();
 report.coverage=data.coverage;report.core=data.core;report.stats=data.stats;
 return {report,get meshes(){return mergeOpaque&&merged&&report.mergeActive?[...meshes.filter(m=>m.userData.contextKind==='context-water'),merged]:meshes;},update};
}
