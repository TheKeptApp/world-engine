// R's crown-v3 prototype: opt-in only. Construction ratios below are prototype
// mechanics, not measured pack values. Shape authority: crown-silhouettes-v2
// panels 01/14/17–22; colours/dimensions remain foliage-seasons-v1/P2 data.
import * as T from 'three/webgpu';
import {attribute,float,vec3,mix,select,length,sin,cos,atan,dot,max,normalWorld} from 'three/tsl';
import {stableRandom} from './stable-random.js';
export const ALLOCATIONS=[[160,240,600],[24,56,120],[12,24,64],[0,0,8]];
export function crownV3Mode(value){if(value==null||value==='off')return false;if(value==='standard')return 'standard';throw Error('Invalid crownV3: '+value);}
// crowns.md projected thresholds 20/6 px; tiny <2 px from pack detail cull.
export function crownV3Level(pixels){return pixels>=20?0:pixels>=6?1:pixels>=2?2:3;}
const V=a=>new T.Vector3(...a);
const distribute=(total,n,unit=1)=>Array.from({length:n},(_,i)=>unit*(Math.floor(total/unit/n)+(i<total/unit%n?1:0)));
export function buildCrownV3(species,lod,state,data,seed=species.id){
 const rng=stableRandom(seed),kind=species.crownKind||data.foliageSeasons.species[species.id].kind,s=data.shapes[kind];
 const family=Object.values(data.vegetation).find(f=>f.packSpecies===species.id),bark=new T.Color(species.bark||family?.branches||'#796B57');
 const pos=[],norm=[],col=[],leaf=[],patch=[],uv=[],ao=[];
 function vertex(p,n,isLeaf,isPatch,t=[0,0],occ=1){pos.push(...p.toArray());norm.push(...n.toArray());col.push(bark.r,bark.g,bark.b);leaf.push(isLeaf?1:0);patch.push(isPatch?1:0);uv.push(...t);ao.push(occ);}
 function tri(a,b,c,ns,isLeaf=false,isPatch=false,uvs=null,occ=1){[a,b,c].forEach((p,i)=>vertex(p,ns[i],isLeaf,isPatch,uvs?.[i],occ));}
 function branch(a,b,r,sides){const axis=b.clone().sub(a).normalize(),u=new T.Vector3().crossVectors(axis,V([0,0,1])).normalize(),w=new T.Vector3().crossVectors(axis,u).normalize();for(let i=0;i<sides;i++){const n=t=>u.clone().multiplyScalar(Math.cos(t)).addScaledVector(w,Math.sin(t)),n0=n(i*2*Math.PI/sides),n1=n((i+1)*2*Math.PI/sides),a0=a.clone().addScaledVector(n0,r),a1=a.clone().addScaledVector(n1,r),b0=b.clone().addScaledVector(n0,r*.4),b1=b.clone().addScaledVector(n1,r*.4);tri(a0,a1,b0,[n0,n1,n0]);tri(a1,b1,b0,[n1,n1,n0]);}}
 const count=5+Math.floor(rng()*5),offset=V([(rng()-.5)*.10,0,(rng()-.5)*.10]),lobes=[];
 // Three unequal height layers with a displaced centre; species envelope owns
 // width and height. Golden-angle placement avoids repeated radial balls.
 const d=species.dimensionsM,spread=(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1]);
 for(let i=0;i<count;i++){const angle=i*2.399963229728653+rng()*.6,layer=i%3,reach=spread*(.24+.12*rng())*(kind==='treeUpright'?.6:1),r=spread*(.13+.07*rng());lobes.push({c:V([Math.cos(angle)*reach,.53+layer*.16+(rng()-.5)*.07,Math.sin(angle)*reach]).add(offset),r:V([r*(.8+.4*rng()),r*(kind==='treePyramidal'?1.15:.7),r*(.7+.5*rng())])});}
 const budget=ALLOCATIONS[lod];
 if(lod<3){const segments=lod===0?10:lod===1?4:2,sides=distribute(budget[0]/2,segments);branch(V([0,0,0]),V([offset.x*.3,s.trunkTop,offset.z*.3]),s.trunkRadius,sides[0]);for(let i=1;i<segments;i++){const l=lobes[(i-1)%count];branch(V([offset.x*.3,s.trunkTop*(.8+.2*rng()),offset.z*.3]),l.c,s.trunkRadius*(.35+.2*rng()),sides[i]);}
  if(state.leafFraction>0){const interiors=lod===2?3:count,costs=distribute(budget[1],interiors,2);for(let i=0;i<interiors;i++){if((i+.5)/interiors>state.leafFraction)continue;const l=lobes[i%count],sides=costs[i]/2,r=l.r.clone().multiplyScalar(.62),top=l.c.clone().add(V([0,r.y,0])),bottom=l.c.clone().sub(V([0,r.y,0]));for(let j=0;j<sides;j++){const n0=V([Math.cos(j*2*Math.PI/sides),0,Math.sin(j*2*Math.PI/sides)]),n1=V([Math.cos((j+1)*2*Math.PI/sides),0,Math.sin((j+1)*2*Math.PI/sides)]),a=n0.clone().multiply(r).add(l.c),b=n1.clone().multiply(r).add(l.c);tri(top,b,a,[V([0,1,0]),n1,n0],true,false,null,.88);tri(bottom,a,b,[V([0,-1,0]),n0,n1],true,false,null,.88);}}}
 }
 if(state.leafFraction>0){
  // 2–3 intersecting patches per lobe, not a forest of leaf cards. Fan
  // tessellation spends the specified patch triangles on curved smooth normals.
  const cards=lod===3?2:count*(lod===2?2:3),costs=distribute(budget[2],cards);
  for(let i=0;i<cards;i++){if((i+.5)/cards>state.leafFraction)continue;const l=lod===3?{c:V([offset.x,.68,offset.z]),r:V([spread*.48,.32,spread*.48])}:lobes[Math.floor(i/(lod===2?2:3))],angle=(i%3)*Math.PI/3+(rng()-.5)*.5;
   const u=V([Math.cos(angle),0,Math.sin(angle)]),w=V([-Math.sin(angle)*.3,.95,Math.cos(angle)*.3]).normalize(),pn=new T.Vector3().crossVectors(u,w).normalize(),center=l.c.clone().addScaledVector(pn,((i%3)-1)*l.r.x*.28),N=costs[i];
   const rim=j=>{const a=j/N*2*Math.PI,f=1+.12*Math.sin(a*3+i)+.07*Math.cos(a*5+i),xy=[Math.cos(a)*f,Math.sin(a)*f],p=center.clone().addScaledVector(u,xy[0]*l.r.x).addScaledVector(w,xy[1]*l.r.y),n=pn.clone().multiplyScalar(.65).addScaledVector(u,xy[0]).addScaledVector(w,xy[1]).normalize();return {p,n,xy};};
   for(let j=0;j<N;j++){const a=rim(j),b=rim((j+1)%N);tri(center,a.p,b.p,[pn,a.n,b.n],true,true,[[0,0],a.xy,b.xy]);}
  }
 }
 const g=new T.BufferGeometry();for(const [name,array,size]of [['position',pos,3],['normal',norm,3],['color',col,3],['leafMask',leaf,1],['v3Patch',patch,1],['v3UV',uv,2],['v3AO',ao,1]])g.setAttribute(name,new T.Float32BufferAttribute(array,size));g.setIndex(Array.from({length:pos.length/3},(_,i)=>i));g.computeBoundingBox();g.computeBoundingSphere();g.userData.crownV3={lobes:count,seed,lod,allocation:budget,leafFraction:state.leafFraction};return g;
}
function materialV3(old,sunDirection){
 const m=old.clone();m.side=T.DoubleSide;m.shadowSide=T.DoubleSide;m.transparent=false;m.depthWrite=true;m.alphaTest=.5;
 const p=attribute('v3Patch','float'),uv=attribute('v3UV','vec2'),angle=atan(uv.y,uv.x);
 // Broad edge cutout, no photographic texture/no noise. Same field all views.
 const edge=float(.86).add(sin(angle.mul(7)).mul(.065)).add(cos(angle.mul(11)).mul(.035));
 m.opacityNode=select(p.greaterThan(.5),select(length(uv).lessThan(edge),1,0),1);
 m.aoNode=attribute('v3AO','float'); // Separate restrained interior AO, once.
 // R v3 small sun-dependent transmission, prototype amplitude .035 linear.
 m.emissiveNode=attribute('leafTint','vec3').mul(max(dot(normalWorld.negate(),vec3(...sunDirection.toArray())),0)).mul(p).mul(.035);
 return m;
}
export function installCrownV3(world,camera,height,data,state,sunDirection){
 const eligible=g=>g.isTree&&g.species?.evergreen===false&&['treeRounded','treePyramidal','treeVase','treeOpen','treeUpright'].includes(g.species.crownKind||data.foliageSeasons.species[g.species.id]?.kind);
 const original=world.lodGroups,selected=original.filter(eligible),pools=new Map();
 for(const g of selected){if(!pools.has(g.species.id))pools.set(g.species.id,[]);pools.get(g.species.id).push(g);for(const m of g.levels)world.root.remove(m);}
 const groups=[];
 for(const [id,sources]of pools){const instances=sources.flatMap(g=>g.instances),capacity=instances.length<=256?Math.max(1,instances.length):Math.max(1001,instances.length),material=materialV3(sources[0].levels[0].material,sunDirection),levels=ALLOCATIONS.map((_,lod)=>{const geo=buildCrownV3(sources[0].species,lod,state,data,'crown-v3/'+id);for(const name of ['leafTint','instOrigin'])geo.setAttribute(name,new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));const mesh=new T.InstancedMesh(geo,material,capacity);mesh.count=0;mesh.castShadow=mesh.receiveShadow=true;mesh.userData.costCategory='foliage';world.root.add(mesh);return mesh;});groups.push({...sources[0],key:'crown-v3/'+id,instances,levels,triangles:levels.map(m=>m.geometry.index.count/3),counts:[0,0,0,0],crownV3:true,sources});}
 world.lodGroups=[...original.filter(g=>!eligible(g)),...groups];
 const before=world.updateLODs.bind(world);
 const frustum=new T.Frustum(),sphere=new T.Sphere();
 world.updateLODs=position=>{before(position);camera.updateMatrixWorld();frustum.setFromProjectionMatrix(new T.Matrix4().multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse));const focal=height()/(2*Math.tan(camera.fov*Math.PI/360)),matrix=new T.Matrix4();
  for(const g of groups){const tints=new Map();for(const old of g.sources){const indices=[0,0,0,0];for(const i of old.instances){let l=0;const d=Math.hypot(Math.fround(i.position[0])-position.x,Math.fround(i.position[2])-position.z);while(l<old.levels.length-1&&l<world.runtime.lodDistances.length&&d>=world.runtime.lodDistances[l])l++;const a=old.levels[l].geometry.attributes.leafTint,n=indices[l]++;tints.set(i.id,[a.getX(n),a.getY(n),a.getZ(n)]);}}
   g.counts=[0,0,0,0];g.culled=0;for(const i of g.instances){const bounds=g.levels[0].geometry.boundingSphere,stretch=i.stretch||[1,1];sphere.center.copy(bounds.center).multiply(V([i.scale*stretch[0],i.scale,i.scale*stretch[1]])).applyAxisAngle(V([0,1,0]),i.yaw).add(V(i.position));sphere.radius=bounds.radius*i.scale*Math.max(1,...stretch);if(!frustum.intersectsSphere(sphere)){g.culled++;continue;}const level=crownV3Level(i.scale*focal/Math.max(camera.near,camera.position.distanceTo(V(i.position)))),m=g.levels[level],n=g.counts[level]++,s=i.stretch||[1,1];matrix.compose(V(i.position),new T.Quaternion().setFromAxisAngle(V([0,1,0]),i.yaw),V([i.scale*s[0],i.scale,i.scale*s[1]]));m.setMatrixAt(n,matrix);m.geometry.attributes.instOrigin.setXYZ(n,...i.position);m.geometry.attributes.leafTint.setXYZ(n,...tints.get(i.id));}
   g.levels.forEach((m,l)=>{m.count=g.counts[l];m.visible=m.count>0;m.instanceMatrix.needsUpdate=true;m.geometry.attributes.leafTint.needsUpdate=true;m.geometry.attributes.instOrigin.needsUpdate=true;if(m.count)m.computeBoundingSphere();});
  }
  world.crownV3Report={recipe:'unequal-lobes-cutout-v3',groups:groups.length,trees:groups.reduce((n,g)=>n+g.instances.length,0),frustumCulled:groups.reduce((n,g)=>n+g.culled,0),lodCounts:ALLOCATIONS.map((_,l)=>groups.reduce((n,g)=>n+g.counts[l],0)),allocations:ALLOCATIONS};
 };
 return {groups};
}
// CPU projection estimate, NOT a GPU fragment counter. Full drawable crop;
// alpha test reproduced; depth/scene occlusion deliberately ignored (upper bound).
export function estimateFragments(groups,camera,width,height){
 const hits=new Uint16Array(width*height);let raw=0,accepted=0,clipped=0;
 camera.updateMatrixWorld();const vp=new T.Matrix4().multiplyMatrices(camera.projectionMatrix,camera.matrixWorldInverse),matrix=new T.Matrix4();
 for(const group of groups)for(const mesh of group.levels){if(!mesh.visible)continue;const g=mesh.geometry,p=g.attributes.position,uv=g.attributes.v3UV,mask=g.attributes.v3Patch;
  for(let instance=0;instance<mesh.count;instance++){mesh.getMatrixAt(instance,matrix);const m=new T.Matrix4().multiplyMatrices(vp,new T.Matrix4().multiplyMatrices(mesh.matrixWorld,matrix));
   for(let k=0;k<g.index.count;k+=3){const ids=[0,1,2].map(j=>g.index.getX(k+j));if(mask.getX(ids[0])<.5)continue;
    let polygon=ids.map(i=>({p:new T.Vector4(p.getX(i),p.getY(i),p.getZ(i),1).applyMatrix4(m),uv:[uv.getX(i),uv.getY(i)]}));
    for(const plane of [p=>p.w+p.x,p=>p.w-p.x,p=>p.w+p.y,p=>p.w-p.y,p=>p.w+p.z,p=>p.w-p.z]){const out=[];for(let j=0;j<polygon.length;j++){const a=polygon[j],b=polygon[(j+1)%polygon.length],da=plane(a.p),db=plane(b.p);if(da>=0)out.push(a);if((da>=0)!==(db>=0)){const t=da/(da-db);out.push({p:a.p.clone().lerp(b.p,t),uv:a.uv.map((v,i)=>v+(b.uv[i]-v)*t)});}}polygon=out;}
    for(let j=1;j<polygon.length-1;j++){const clippedVertices=[polygon[0],polygon[j],polygon[j+1]],ps=clippedVertices.map(v=>v.p);
    const a=ps.map(p=>[(p.x/p.w+1)*width/2,(1-p.y/p.w)*height/2,1/p.w]);
    const edge=(a,b,x,y)=>(x-a[0])*(b[1]-a[1])-(y-a[1])*(b[0]-a[0]),area=edge(a[0],a[1],a[2][0],a[2][1]);if(Math.abs(area)<1e-8)continue;
    const xmin=Math.max(0,Math.floor(Math.min(...a.map(p=>p[0])))),xmax=Math.min(width-1,Math.ceil(Math.max(...a.map(p=>p[0])))),ymin=Math.max(0,Math.floor(Math.min(...a.map(p=>p[1])))),ymax=Math.min(height-1,Math.ceil(Math.max(...a.map(p=>p[1]))));
    for(let y=ymin;y<=ymax;y++)for(let x=xmin;x<=xmax;x++){const b=[edge(a[1],a[2],x+.5,y+.5)/area,edge(a[2],a[0],x+.5,y+.5)/area,edge(a[0],a[1],x+.5,y+.5)/area];if(b.some(t=>t<0))continue;raw++;const w=b.reduce((n,t,i)=>n+t*a[i][2],0),u=b.reduce((n,t,i)=>n+t*a[i][2]*clippedVertices[i].uv[0],0)/w,v=b.reduce((n,t,i)=>n+t*a[i][2]*clippedVertices[i].uv[1],0)/w,angle=Math.atan2(v,u),radius=.86+.065*Math.sin(angle*7)+.035*Math.cos(angle*11);if(Math.hypot(u,v)>radius)continue;accepted++;hits[y*width+x]++;}
    }
   }
  }
 }
 let covered=0,above6=0,peak=0;for(const n of hits){if(n){covered++;peak=Math.max(peak,n);if(n>6)above6++;}}
 return {method:'CPU pixel-centre raster estimate; cutout field; no scene/depth occlusion; no MSAA; full drawable crop',width,height,preCutoutFragments:raw,postCutoutFragments:accepted,coveredPixels:covered,averageCardLayers:covered?accepted/covered:0,pixelsAbove6:above6,peakLayers:peak,over6Flag:above6>0,nearClippedTrianglesOmitted:clipped};
}
