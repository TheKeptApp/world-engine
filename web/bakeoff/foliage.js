import * as T from 'three/webgpu';
import {mergeGeometries,mergeVertices} from 'three/addons/utils/BufferGeometryUtils.js';
import {speciesFor} from './species-policy.js';
// All shape numbers are P2 fcda086/Props.swift, compiled in data/p2-crowns.json.
const v=a=>new T.Vector3(...a);
function colour(g,c){g.setAttribute('color',new T.BufferAttribute(new Float32Array(g.attributes.position.count*3).fill(0),3));for(let i=0;i<g.attributes.position.count;i++)g.attributes.color.setXYZ(i,c.r,c.g,c.b);return g;}
function limb(a,b,r,c,sides){const delta=b.clone().sub(a),g=new T.CylinderGeometry(r*.45,r,delta.length(),sides,1,true);g.applyQuaternion(new T.Quaternion().setFromUnitVectors(v([0,1,0]),delta.normalize()));g.translate(...a.clone().add(b).multiplyScalar(.5).toArray());return colour(g,c);}
function cubeSphere(){const g=new T.BoxGeometry(2,2,2,2,2,2),p=g.attributes.position,n=g.attributes.normal;for(let i=0;i<p.count;i++){const u=v([p.getX(i),p.getY(i),p.getZ(i)]).normalize();p.setXYZ(i,...u.toArray());n.setXYZ(i,...u.toArray());}return g;}
function seasonal(species,state){const keys=['bud_leafout','summer','peak_colour','bare_or_evergreen'];if(species.evergreen)return new T.Color(species.seasonColours.summer);const c=new T.Color(0,0,0);keys.forEach((k,i)=>c.add(new T.Color(species.seasonColours[k]).multiplyScalar(state.weights[i])));return c;}
function build(species,lod,state,data){
 const kind=(species.crownKind||data.foliageSeasons.species[species.id].kind),s=data.shapes[kind],parts=[],leaf=seasonal(species,state);
 const family=Object.values(data.vegetation).find(f=>f.packSpecies===species.id),fallback=data.vegetation[data.vegetationRegions.chicago.bark],bark=new T.Color(species.bark||family?.branches||fallback.branches);
 if(!s){ // P2 conifer tiers; evergreens retain their summer crown in every season.
  if(lod<3)parts.push(limb(v([0,0,0]),v([0,.22,0]),.018,bark,lod===0?6:3));
  const tiers=lod>=2?[[.14,1,.24]]:lod===1?[[.14,.58,.26],[.38,.8,.2],[.6,1,.13]]:Array.from({length:7},(_,i)=>{const t=i/6;return [.12+.62*t,i===6?1:.38+.56*t,.27-.2*t];});
  for(const [a,b,r]of tiers){const g=new T.ConeGeometry(r,b-a,lod===0?10:lod===1?7:5,1,true);g.translate(0,(a+b)/2,0);parts.push(colour(g,leaf));}
 }else{
  const radius=s.trunkRadius,top=s.trunkTop;
  parts.push(limb(v([0,0,0]),v([0,top+.08,0]),radius,bark,lod===0?7:lod===1?5:3));
  const lobes=(lod===0?s.lobes:s.lobes.slice(0,s.midCount).map(([c,r])=>[c,r*s.midScale]));
  for(const [center,r]of s.lobes.slice(0,lod<2?5:3))parts.push(limb(v([0,top-.04,0]),v(center),radius*.62,bark,lod===0?4:3));
  if(state.leafFraction>0){
   const selected=lobes.filter((_,i)=>(i+.5)/lobes.length<=state.leafFraction);
   for(const [center,r]of (lod>=2?[[s.crown,1]]:selected)){
    const g=lod===0?cubeSphere():new T.IcosahedronGeometry(1,0);g.scale(r,r*.92,r);g.translate(...center);
    const p=g.attributes.position,n=g.attributes.normal,c=v(s.crown),rr=v(s.radii).multiply(v(s.radii));
    if(lod>=2){ // P2 ray-to-last-lobe-exit shell; same crown in every viewing direction.
     for(let i=0;i<p.count;i++){const dir=v([p.getX(i),p.getY(i),p.getZ(i)]).sub(c).multiply(v(s.radii)).normalize();let hit=0;
      for(const [lc,lr]of selected){const radii=v([lr,lr*.92,lr]),o=c.clone().sub(v(lc)).divide(radii),d=dir.clone().divide(radii),a=d.dot(d),b=2*o.dot(d),cc=o.dot(o)-1,disc=b*b-4*a*cc;if(disc>=0)hit=Math.max(hit,(-b+Math.sqrt(disc))/(2*a));}
      const point=c.clone().addScaledVector(dir,hit);p.setXYZ(i,...point.toArray());n.setXYZ(i,...dir.toArray());
     }
    }
    for(let i=0;i<p.count;i++){const normal=v([n.getX(i),n.getY(i),n.getZ(i)]).normalize(),cn=v([p.getX(i),p.getY(i),p.getZ(i)]).sub(c).divide(rr).normalize();normal.addScaledVector(cn,Math.max(0,normal.dot(cn))).normalize();n.setXYZ(i,...normal.toArray());}
    parts.push(colour(g,leaf));
   }
  }
  // P2 Foliage.widthScale: pack midpoint spread/height over the silhouette width.
  const min=[Infinity,Infinity],max=[-Infinity,-Infinity];for(const [c,r]of s.lobes)for(let i=0;i<2;i++){const x=c[i*2];min[i]=Math.min(min[i],x-r);max[i]=Math.max(max[i],x+r);}
  const width=((max[0]-min[0])+(max[1]-min[1]))/2,d=species.dimensionsM;
  const scale=Math.max(.6,Math.min(1.2,(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1])/width));
  for(const g of parts)g.scale(scale,1,scale);
 }
 const pieces=parts.map(g=>{g.deleteAttribute('uv');return g.index?g.toNonIndexed():g;}),merged=mergeGeometries(pieces),out=mergeVertices(merged);new Set([...pieces,...parts,merged]).forEach(g=>g.dispose());out.computeBoundingBox();out.computeBoundingSphere();return out;
}
export function applySpecies(world,pack,roughness,region,state,data){
 const assignments={},material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness});material.shadowSide=T.BackSide;
 const groups=[],cache=new Map();
 for(const group of world.lodGroups){if(!group.isTree){groups.push(group);continue;}const split=new Map();
  for(const inst of group.instances){const species=speciesFor(inst,group.kind,pack,region,data);if(!split.has(species.id))split.set(species.id,{species,list:[]});split.get(species.id).list.push(inst);}
  group.levels.forEach(mesh=>world.root.remove(mesh));
  for(const {species,list}of split.values()){
   const key=group.key+'/'+species.id,kind=(species.crownKind||data.foliageSeasons.species[species.id].kind);
   assignments[key]={species:species.id,silhouette:kind,source:list.every(i=>i.species)?'export species + provenance':'P2 inferred city/form fallback',count:list.length};
   const capacity=list.length<=256?Math.max(1,list.length):Math.max(1001,list.length);
   const levels=group.levels.map((_,lod)=>{const gkey=species.id+'/'+lod;let g=cache.get(gkey);if(!g){g=build(species,lod,state,data);cache.set(gkey,g);}const geo=g.clone();geo.setAttribute('instOrigin',new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));const m=new T.InstancedMesh(geo,material,capacity);m.count=0;m.castShadow=m.receiveShadow=true;m.userData.costCategory='foliage';world.root.add(m);return m;});
   // P2 exports already applied widthScale to stretch; undo that duplication for tagged species.
   const s=data.shapes[kind],d=species.dimensionsM;let widthScale=1;if(s){const widths=[0,2].map(axis=>Math.max(...s.lobes.map(([c,r])=>c[axis]+r))-Math.min(...s.lobes.map(([c,r])=>c[axis]-r)));widthScale=Math.max(.6,Math.min(1.2,(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1])/((widths[0]+widths[1])/2)));}
   const instances=list.map(i=>i.species?{...i,stretch:(i.stretch||[1,1]).map(x=>x/widthScale)}:i);
   groups.push({...group,key,instances,levels,triangles:levels.map(m=>m.geometry.index.count/3),counts:levels.map(()=>0)});
  }
 }
 world.lodGroups=groups;return assignments;
}
