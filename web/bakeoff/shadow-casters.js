import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
// Sources/WorldGen/Profiles/look.json shadows.rangeM; R's shared floor includes the entire shadow pass.
export function installShadowCasters(scene,world,sun,camera){
 const root=new T.Group();root.name='budgeted shadow-only casters';scene.add(root);
 sun.shadow.camera.layers.set(1);
 const material=new T.MeshBasicNodeMaterial();material.shadowSide=T.BackSide;
 const sources=[];scene.updateMatrixWorld(true);scene.traverse(o=>{if(o.isMesh&&o.castShadow){sources.push(o);o.castShadow=false;}});
 const treeMeshes=new Set(world.lodGroups.filter(g=>g.isTree).flatMap(g=>g.levels));
 const report={source:'Sources/WorldGen/Profiles/look.json/shadows.rangeM; R floor shadow triangles=150000',limit:150000,maxRadiusM:120,treeLOD:2};
 function rebuild(){
  for(const mesh of [...root.children]){root.remove(mesh);mesh.geometry.dispose();mesh.dispose?.();}
  scene.updateMatrixWorld(true);let radius=report.maxRadiusM,total=0;
  const add=(mesh,category)=>{mesh.layers.set(1);mesh.castShadow=true;mesh.userData.costCategory=category;root.add(mesh);total+=(mesh.geometry.index?.count??mesh.geometry.attributes.position.count)/3*(mesh.isInstancedMesh?mesh.count:1);};
  const near=p=>Math.hypot(p.x-camera.position.x,p.z-camera.position.z)<=radius;
  for(;;){total=0;
   for(const source of sources){if(treeMeshes.has(source)||!source.visible)continue;
    if(source.isInstancedMesh){const matrices=[],m=new T.Matrix4(),p=new T.Vector3();for(let i=0;i<source.count;i++){source.getMatrixAt(i,m);m.premultiply(source.matrixWorld);if(near(p.setFromMatrixPosition(m)))matrices.push(m.clone());}if(!matrices.length)continue;const mesh=new T.InstancedMesh(source.geometry.clone(),material,matrices.length);matrices.forEach((m,i)=>mesh.setMatrixAt(i,m));mesh.computeBoundingSphere();add(mesh,source.userData.costCategory);continue;}
    const geo=source.geometry,p=geo.attributes.position,index=geo.index,ids=[],a=new T.Vector3(),b=new T.Vector3(),c=new T.Vector3();
    for(let i=0,n=index?.count??p.count;i<n;i+=3){const tri=[0,1,2].map(k=>index?index.getX(i+k):i+k);[a,b,c].forEach((v,k)=>v.fromBufferAttribute(p,tri[k]).applyMatrix4(source.matrixWorld));
     const dx=Math.max(Math.min(a.x,b.x,c.x)-camera.position.x,0,camera.position.x-Math.max(a.x,b.x,c.x)),dz=Math.max(Math.min(a.z,b.z,c.z)-camera.position.z,0,camera.position.z-Math.max(a.z,b.z,c.z));if(Math.hypot(dx,dz)<=radius)ids.push(...tri);
    }if(!ids.length)continue;const g=geo.clone();g.setIndex(ids);const mesh=new T.Mesh(g,material);mesh.matrixAutoUpdate=false;mesh.matrix.copy(source.matrixWorld);add(mesh,source.userData.costCategory);
   }
   for(const group of world.lodGroups.filter(g=>g.isTree)){const list=group.instances.filter(i=>near(new T.Vector3(...i.position)));if(!list.length)continue;
    const depthMaterial=group.crownV3?new T.MeshBasicNodeMaterial({side:T.DoubleSide,shadowSide:T.DoubleSide,alphaTest:.5}):material;
    if(group.crownV3)depthMaterial.opacityNode=group.levels[2].material.opacityNode;
    const mesh=new T.InstancedMesh(group.levels[Math.min(report.treeLOD,group.levels.length-1)].geometry.clone(),depthMaterial,list.length),m=new T.Matrix4();list.forEach((i,n)=>{const s=i.stretch||[1,1];m.compose(new T.Vector3(...i.position),new T.Quaternion().setFromAxisAngle(new T.Vector3(0,1,0),i.yaw),new T.Vector3(i.scale*s[0],i.scale,i.scale*s[1]));mesh.setMatrixAt(n,m.premultiply(world.root.matrixWorld));});mesh.computeBoundingSphere();mesh.userData.crownV2=!!group.crownV2;add(mesh,'foliage');
   }
   if(total<=report.limit)break;
   for(const mesh of [...root.children]){root.remove(mesh);mesh.geometry.dispose();mesh.dispose?.();}radius/=2;
   if(radius<Number.EPSILON)throw Error('Cannot meet shadow floor');
  }
  // All elm far casters share the same depth material. Batch shadow-only
  // triangles across seed variants; keep every instance and its exact LOD.
  // Other crowns and the default-off path are untouched.
  const elms=root.children.filter(m=>m.userData.crownV2);
  if(elms.length>1){const pieces=[],matrix=new T.Matrix4();
   for(const mesh of elms)for(let i=0;i<mesh.count;i++){mesh.getMatrixAt(i,matrix);const geo=new T.BufferGeometry();for(const name of ['position','normal'])geo.setAttribute(name,mesh.geometry.attributes[name].clone());geo.setIndex(mesh.geometry.index.clone());geo.applyMatrix4(matrix);pieces.push(geo);}
   const geometry=mergeGeometries(pieces),batch=new T.Mesh(geometry,material);batch.layers.set(1);batch.castShadow=true;batch.userData.costCategory='foliage';root.add(batch);
   pieces.forEach(g=>g.dispose());for(const mesh of elms){root.remove(mesh);mesh.geometry.dispose();mesh.dispose();}
  }
  Object.assign(report,{radiusM:radius,potentialTriangles:total,draws:root.children.length});
 }
 rebuild();return {report,rebuild};
}
