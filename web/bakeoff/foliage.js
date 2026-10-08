import * as T from 'three/webgpu';
import {mergeGeometries,mergeVertices} from 'three/addons/utils/BufferGeometryUtils.js';
import {attribute,mix,float,clamp,smoothstep} from 'three/tsl';
import {phenology} from './phenology.js';
import {stableRandom} from './stable-random.js';
import {speciesFor} from './species-policy.js';
// docs/research/foliage-exp1-spec.md: fixed experiment, default identity control.
export function foliageExp1Mode(value){
 const mode=value??'off';
 if(!['off','remove','layered'].includes(mode))throw Error('Invalid foliageExp1 mode: '+mode);
 return mode;
}
export function applyFoliageExp1(material,mode){
 if(foliageExp1Mode(mode)!=='layered')return; // Preserve the exact original graph.
 const mask=attribute('exp1Mask','float'),A0=clamp(attribute('exp1AO','float'),.65,1);
 const t=smoothstep(.65,1,A0),A1=float(.65).add(t.mul(.35)),M=float(.94).add(t.mul(.06));
 const original=material.colorNode;
 material.colorNode=mix(original,original.mul(M),mask);
 material.aoNode=mix(float(1),A1,mask);
}
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
export function crownExp1AO(position,normal,shape,lobes){
 const rel=(position[1]-shape.crown[1])/shape.radii[1];
 let A=Math.min(.66+.34*smooth(-1,.7,rel),1-.25*smooth(.2,.8,-normal[1]));
 for(const [c,r]of lobes)if(Math.hypot(...position.map((x,i)=>x-c[i]))<.98*r)A*=.86;
 return A;
}
function crownExp1Attributes(g,s,lobes){
 const p=g.attributes.position,n=g.attributes.normal;
 for(let i=0;i<p.count;i++){
  g.attributes.exp1AO.setX(i,crownExp1AO([p.getX(i),p.getY(i),p.getZ(i)],[n.getX(i),n.getY(i),n.getZ(i)],s,lobes));
  g.attributes.exp1Mask.setX(i,1);
 }
}
// All shape numbers are P2 fcda086/Props.swift, compiled in data/p2-crowns.json.
const v=a=>new T.Vector3(...a);
function colour(g,c,leaf=false){g.setAttribute('exp1AO',new T.BufferAttribute(new Float32Array(g.attributes.position.count).fill(1),1));g.setAttribute('exp1Mask',new T.BufferAttribute(new Float32Array(g.attributes.position.count),1));g.setAttribute('leafMask',new T.BufferAttribute(new Float32Array(g.attributes.position.count).fill(leaf?1:0),1));g.setAttribute('color',new T.BufferAttribute(new Float32Array(g.attributes.position.count*3).fill(0),3));for(let i=0;i<g.attributes.position.count;i++)g.attributes.color.setXYZ(i,c.r,c.g,c.b);return g;}
function limb(a,b,r,c,sides){const delta=b.clone().sub(a),g=new T.CylinderGeometry(r*.45,r,delta.length(),sides,1,true);g.applyQuaternion(new T.Quaternion().setFromUnitVectors(v([0,1,0]),delta.normalize()));g.translate(...a.clone().add(b).multiplyScalar(.5).toArray());return colour(g,c);}
function cubeSphere(){const g=new T.BoxGeometry(2,2,2,2,2,2),p=g.attributes.position,n=g.attributes.normal;for(let i=0;i<p.count;i++){const u=v([p.getX(i),p.getY(i),p.getZ(i)]).normalize();p.setXYZ(i,...u.toArray());n.setXYZ(i,...u.toArray());}return g;}
function seasonal(species,state){const keys=['bud_leafout','summer','peak_colour','bare_or_evergreen'];if(species.evergreen)return new T.Color(species.seasonColours.summer);const c=new T.Color(0,0,0);keys.forEach((k,i)=>c.add(new T.Color(species.seasonColours[k]).multiplyScalar(state.weights[i])));return c;}
export function build(species,lod,state,data){
 const kind=(species.crownKind||data.foliageSeasons.species[species.id].kind),s=data.shapes[kind],parts=[],leaf=seasonal(species,state);
 const family=Object.values(data.vegetation).find(f=>f.packSpecies===species.id),fallback=data.vegetation[data.vegetationRegions.chicago.bark],bark=new T.Color(species.bark||family?.branches||fallback.branches);
 if(!s){ // P2 conifer tiers; evergreens retain their summer crown in every season.
  if(lod<3)parts.push(limb(v([0,0,0]),v([0,.22,0]),.018,bark,lod===0?6:3));
  const tiers=lod>=2?[[.14,1,.24]]:lod===1?[[.14,.58,.26],[.38,.8,.2],[.6,1,.13]]:Array.from({length:7},(_,i)=>{const t=i/6;return [.12+.62*t,i===6?1:.38+.56*t,.27-.2*t];});
  for(const [a,b,r]of tiers){const g=new T.ConeGeometry(r,b-a,lod===0?10:lod===1?7:5,1,true);g.translate(0,(a+b)/2,0);parts.push(colour(g,leaf,true));}
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
    colour(g,leaf,true);
    if(!species.evergreen&&lod<3)crownExp1Attributes(g,s,lod>=2?[]:selected);
    parts.push(g);
   }
  }
  // P2 Foliage.widthScale: pack midpoint spread/height over the silhouette width.
  const min=[Infinity,Infinity],max=[-Infinity,-Infinity];for(const [c,r]of s.lobes)for(let i=0;i<2;i++){const x=c[i*2];min[i]=Math.min(min[i],x-r);max[i]=Math.max(max[i],x+r);}
  const width=((max[0]-min[0])+(max[1]-min[1]))/2,d=species.dimensionsM;
  const scale=Math.max(.6,Math.min(1.2,(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1])/width));
  for(const g of parts)g.scale(scale,1,scale);
 }
 const pieces=parts.map(g=>{g.deleteAttribute('uv');return g.index?g.toNonIndexed():g;}),merged=mergeGeometries(pieces);
 // Keep the legacy weld keys/order: new AO must never split a previously welded
 // vertex. Remap its first representative through the unchanged output index.
 const ao=merged.attributes.exp1AO,mask=merged.attributes.exp1Mask;
 merged.deleteAttribute('exp1AO');merged.deleteAttribute('exp1Mask');
 const out=mergeVertices(merged),count=out.attributes.position.count;
 const outAO=new Float32Array(count).fill(1),outMask=new Float32Array(count),seen=new Uint8Array(count);
 for(let i=0;i<out.index.count;i++){const j=out.index.getX(i);if(!seen[j]){outAO[j]=ao.getX(i);outMask[j]=mask.getX(i);seen[j]=1;}}
 out.setAttribute('exp1AO',new T.BufferAttribute(outAO,1));out.setAttribute('exp1Mask',new T.BufferAttribute(outMask,1));
 new Set([...pieces,...parts,merged]).forEach(g=>g.dispose());out.computeBoundingBox();out.computeBoundingSphere();return out;
}
export function applySpecies(world,pack,roughness,region,state,data,mode='off'){
 mode=foliageExp1Mode(mode);
 const assignments={},material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness});material.shadowSide=T.BackSide;material.vertexColors=false;material.colorNode=mix(attribute('color','vec3'),attribute('leafTint','vec3'),attribute('leafMask','float'));
 applyFoliageExp1(material,mode);
 const groups=[],cache=new Map();
 for(const group of world.lodGroups){if(!group.isTree){groups.push(group);continue;}const split=new Map();
  for(const inst of group.instances){const species=speciesFor(inst,group.kind,pack,region,data);if(!split.has(species.id))split.set(species.id,{species,list:[]});split.get(species.id).list.push(inst);}
  group.levels.forEach(mesh=>world.root.remove(mesh));
  for(const {species,list}of split.values()){
   const key=group.key+'/'+species.id,kind=(species.crownKind||data.foliageSeasons.species[species.id].kind);
   assignments[key]={species:species.id,silhouette:kind,source:list.every(i=>i.species)?'export species + provenance':'P2 inferred city/form fallback',count:list.length};
   const capacity=list.length<=256?Math.max(1,list.length):Math.max(1001,list.length);
   const levels=group.levels.map((_,lod)=>{const gkey=species.id+'/'+lod;let g=cache.get(gkey);if(!g){g=build(species,lod,state,data);cache.set(gkey,g);}const geo=g.clone();geo.setAttribute('leafTint',new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));geo.setAttribute('instOrigin',new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));const m=new T.InstancedMesh(geo,material,capacity);m.count=0;m.castShadow=m.receiveShadow=true;m.userData.costCategory='foliage';world.root.add(m);return m;});
   // P2 exports already applied widthScale to stretch; undo that duplication for tagged species.
   const s=data.shapes[kind],d=species.dimensionsM;let widthScale=1;if(s){const widths=[0,2].map(axis=>Math.max(...s.lobes.map(([c,r])=>c[axis]+r))-Math.min(...s.lobes.map(([c,r])=>c[axis]-r)));widthScale=Math.max(.6,Math.min(1.2,(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1])/((widths[0]+widths[1])/2)));}
   const instances=list.map(i=>i.species?{...i,stretch:(i.stretch||[1,1]).map(x=>x/widthScale)}:i);
   groups.push({...group,key,species,instances,levels,triangles:levels.map(m=>m.geometry.index.count/3),counts:levels.map(()=>0)});
  }
 }
 world.lodGroups=groups;
 // Same rebucketing as the shared loader; colours follow identities across LODs.
 const update=world.updateLODs.bind(world);world.updateLODs=position=>{update(position);
  for(const g of groups.filter(g=>g.isTree)){const counts=g.levels.map(()=>0);
   for(const inst of g.instances){const d=Math.hypot(Math.fround(inst.position[0])-position.x,Math.fround(inst.position[2])-position.z);let lod=0;while(lod<g.levels.length-1&&lod<world.runtime.lodDistances.length&&d>=world.runtime.lodDistances[lod])lod++;
    const rng=stableRandom(inst.id+'/phenology-timing-v1'),shift=(2*rng()-1)*7;
    const individual=phenology(state.date,region,data,shift);
    // P2/5A vegetation regional autumn colours survive applyingFoliageSummer.
    const family=Object.values(data.vegetation).find(f=>f.packSpecies===g.species.id);
    const sp=family&&!g.species.evergreen?{...g.species,seasonColours:{...g.species.seasonColours,peak_colour:family.colours[2]}}:g.species;
    const slot=Object.values(data.vegetationRegions[region].slots).find(id=>data.vegetation[id.split('@')[0]]?.packSpecies===g.species.id);
    const lag=Number(slot?.split('@')[1]||0);if(lag){const retained=individual.weights[2]*lag;individual.weights[2]-=retained;individual.weights[1]+=retained;}
    const c=seasonal(sp,individual);g.levels[lod].geometry.attributes.leafTint.setXYZ(counts[lod]++,c.r,c.g,c.b);
   }g.levels.forEach(m=>m.geometry.attributes.leafTint.needsUpdate=true);
  }
 };return assignments;
}
