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
// foliage-exp1-spec.md §Approved native eligibility amendment (66aac35).
// Props.swift crownPaint accepts only SeasonalPalette.order deciduous1..9
// (slots 3..6 / 24..28). Web has species identity, not native paint slots:
// only these P2 deciduous crown generators are equivalent; never infer from RGB.
export function deciduousExp1Identity(species,kind){
 return species.evergreen===false&&['treeRounded','treePyramidal','treeVase','treeOpen','treeUpright'].includes(kind);
}
export function crownExp1Eligible(species,kind,lod,state){
 // Generated opaque leaves only; bare leaves are omitted, no cards are built,
 // and lod>=3 is the skyline control. Wood never calls this crown adapter.
 return deciduousExp1Identity(species,kind)&&lod<3&&state.leafFraction>0;
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
    if(crownExp1Eligible(species,kind,lod,state))crownExp1Attributes(g,s,lod>=2?[]:selected);
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
// crown-silhouettes-v2 values: content.speciesByCity[*][American elm],
// content.construction and lod; panels 01/14/17–22. Shape-only prototype.
export function crownV2Mode(value){
 if(value==null||value==='off')return false;
 if(value===''||value==='on'||value==='standard')return 'standard';
 if(value==='floor')return 'floor';
 throw Error('Invalid crownV2: '+value);
}
export function crownV2Level(pixels,lod,previous){
 const raw=pixels>=lod.nearMinPx?0:pixels>=lod.middleMinPx?1:2;
 if(previous==null||raw===previous)return raw;
 const boundary=raw<previous?(raw===0?lod.nearMinPx:lod.middleMinPx):(previous===0?lod.nearMinPx:lod.middleMinPx);
 if(Math.abs(pixels-boundary)<boundary*lod.hysteresisFraction)return previous;
 return raw;
}
export function buildElmV2(species,lod,state,data,pack,seed){
 const recipe=pack.content.speciesByCity.denver.find(s=>s.name==='American elm');
 const rng=stableRandom(seed),mean=a=>(a[0]+a[1])/2,H=mean(species.dimensionsM.height);
 const s=data.shapes.treeVase,leaf=seasonal(species,state),family=Object.values(data.vegetation).find(f=>f.packSpecies===species.id),bark=new T.Color(species.bark||family.branches);
 const parts=[],primary=[],layerCount=recipe.layers[0],count=mean(pack.content.construction.nearPrimaryLobes);
 // Authoring interpolation of the open-vase panels: 3 layers, unequal shoulders,
 // rising branch forks, hollow lower centre. Ratios are prototype mechanics,
 // not measured dimensions or city/camera overrides. Existing P2 trunk ratios.
 for(let i=0;i<count;i++){
  const layer=Math.floor(i/(count/layerCount)),a=2*Math.PI*(i%(count/layerCount))/(count/layerCount)+layer*.37+(rng()-.5)*.22;
  const r=(recipe.primaryLobeRadiusM[0]+(recipe.primaryLobeRadiusM[1]-recipe.primaryLobeRadiusM[0])*(.55+.45*rng()))/H;
  const spread=mean(species.dimensionsM.spread)/H/2;
  const radius=spread*[.72,.85,.58][layer]*(.88+.12*rng());
  primary.push({c:[Math.cos(a)*radius,.52+layer*.16+(rng()-.5)*.06,Math.sin(a)*radius],r,layer,angle:a});
 }
 // Near has 24 primary lobes; middle merges into 9 layer/sector envelopes;
 // far merges to 3 branch fans. Bounds retain the same mature envelope.
 const buckets=new Map();for(const p of primary){const sector=Math.floor(((p.angle%(2*Math.PI)+2*Math.PI)%(2*Math.PI))/(2*Math.PI/3));const key=lod===0?buckets.size:lod===1?p.layer*3+sector:sector;if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push(p);}
 const lobes=[...buckets.values()].map(list=>{
  const box=new T.Box3();for(const p of list){box.expandByPoint(v(p.c).sub(v([p.r,p.r*.65,p.r])));box.expandByPoint(v(p.c).add(v([p.r,p.r*.65,p.r])));}
  return {c:box.getCenter(new T.Vector3()),r:box.getSize(new T.Vector3()).multiplyScalar(.5)};
 });
 const sides=lod===0?7:lod===1?5:3;
 parts.push(limb(v([0,0,0]),v([0,s.trunkTop,0]),s.trunkRadius,bark,sides));
 const active=lobes.filter((_,i)=>(i+.5)/lobes.length<=state.leafFraction);
 for(const [i,l]of lobes.entries()){
  const fork=v([l.c.x*.3,s.trunkTop,l.c.z*.3]),tip=l.c.clone();
  parts.push(limb(v([0,s.trunkTop*.65,0]),fork,s.trunkRadius*.55,bark,sides));
  parts.push(limb(fork,tip,s.trunkRadius*.3,bark,sides));
  if(!active.includes(l))continue;
  const g=lod<2?new T.IcosahedronGeometry(1,1):new T.OctahedronGeometry(1,0),p=g.attributes.position;
  // Unequal broad lobes, not repeated spheres. No individual leaves/cards.
  for(let j=0;j<p.count;j++){const u=v([p.getX(j),p.getY(j),p.getZ(j)]);const f=1+.08*Math.sin(u.x*5+i)*Math.cos(u.z*4+i);u.multiply(l.r).multiplyScalar(f).add(l.c);p.setXYZ(j,...u.toArray());}
  g.computeVertexNormals();colour(g,leaf,true);
  if(crownExp1Eligible(species,'treeVase',lod,state))crownExp1Attributes(g,s,active.map(x=>[x.c.toArray(),Math.max(x.r.x,x.r.y,x.r.z)]));
  parts.push(g);
 }
 const pieces=parts.map(g=>{g.deleteAttribute('uv');return g.index?g.toNonIndexed():g;}),merged=mergeGeometries(pieces),out=mergeVertices(merged);
 new Set([...parts,...pieces,merged]).forEach(g=>g.dispose());out.computeBoundingBox();out.computeBoundingSphere();
 out.userData.crownV2={seed,primaryLobes:lobes.length,leafLobes:active.length,source:'crown-silhouettes-v2/content.construction'};
 return out;
}
// R's A2 CROWN: FIT STANDARD BUDGET decision (evidence/crown-v2/REPORT.md):
// 217 standard / 75 floor tris per elm. Average caps apply to the entire elm population, not
// just visible crowns. Start with far silhouettes, then spend nearest-first.
export function allocateCrownBudget(entries,targetAverage){
 const ordered=[...entries].sort((a,b)=>a.distance-b.distance||a.key.localeCompare(b.key));
 const limit=Math.floor(entries.length*targetAverage);let spent=entries.reduce((n,e)=>n+e.costs[2],0);
 if(spent>limit)throw Error('Far crown topology exceeds crown budget');
 const levels=new Map(entries.map(e=>[e.key,2]));
 for(const e of ordered){for(let level=e.desired;level<2;level++){const extra=e.costs[level]-e.costs[2];if(spent+extra<=limit){levels.set(e.key,level);spent+=extra;break;}}}
 return {levels,spent,limit,average:spent/Math.max(1,entries.length)};
}
function poolElmGroups(groups,root){
 const pooled=new Map();for(const g of groups.filter(g=>g.crownV2)){const key=g.key.split('/elm-v2-').pop();if(!pooled.has(key))pooled.set(key,[]);pooled.get(key).push(g);}
 const out=groups.filter(g=>!g.crownV2);
 for(const [key,list]of pooled){const first=list[0],instances=list.flatMap(g=>g.instances),capacity=instances.length<=256?Math.max(1,instances.length):Math.max(1001,instances.length);
  const levels=first.levels.map(old=>{const geo=old.geometry.clone();for(const name of ['leafTint','instOrigin'])geo.setAttribute(name,new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));const m=new T.InstancedMesh(geo,old.material,capacity);m.count=0;m.castShadow=m.receiveShadow=true;m.userData.costCategory='foliage';root.add(m);return m;});
  for(const g of list)for(const m of g.levels){root.remove(m);m.geometry.dispose();m.dispose?.();}
  out.push({...first,key:'elm-v2/'+key,instances,levels,counts:levels.map(()=>0)});
 }
 return out;
}
function updateElmV2(group,camera,height,pack,allocated){
 const buckets=group.levels.map(()=>[]),focal=height/(2*Math.tan(camera.fov*Math.PI/360));group.crownLevels??=new Map();
 for(const inst of group.instances){const pixels=inst.scale*focal/Math.max(camera.near,camera.position.distanceTo(v(inst.position)));const level=crownV2Level(pixels,pack.lod,group.crownLevels.get(inst.id));group.crownLevels.set(inst.id,level);buckets[allocated.get(group.key+'/'+inst.id)].push(inst);}
 for(let lod=0;lod<buckets.length;lod++){const m=group.levels[lod],list=buckets[lod];list.forEach((i,n)=>{const stretch=i.stretch||[1,1];m.setMatrixAt(n,new T.Matrix4().compose(v(i.position),new T.Quaternion().setFromAxisAngle(v([0,1,0]),i.yaw),v([i.scale*stretch[0],i.scale,i.scale*stretch[1]])));m.geometry.attributes.instOrigin.setXYZ(n,...i.position);});m.count=list.length;m.visible=!!list.length;m.instanceMatrix.needsUpdate=true;m.geometry.attributes.instOrigin.needsUpdate=true;if(list.length)m.computeBoundingSphere();group.counts[lod]=list.length;}
}

export function applySpecies(world,pack,roughness,region,state,data,mode='off',crownV2=null){
 mode=foliageExp1Mode(mode);
 const assignments={},material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness});material.shadowSide=T.BackSide;material.vertexColors=false;material.colorNode=mix(attribute('color','vec3'),attribute('leafTint','vec3'),attribute('leafMask','float'));
 const controlMaterial=new T.MeshStandardNodeMaterial({roughness});
 controlMaterial.shadowSide=T.BackSide;controlMaterial.vertexColors=false;controlMaterial.colorNode=material.colorNode;
 applyFoliageExp1(material,mode);
 let groups=[];const cache=new Map();
 for(const group of world.lodGroups){if(!group.isTree){groups.push(group);continue;}const split=new Map();
  for(const inst of group.instances){const species=speciesFor(inst,group.kind,pack,region,data);const elm=!!crownV2&&species.id==='ulmus_americana',variant=elm?Math.floor(stableRandom(inst.id+'/crown-v2')()*4):0,key=species.id+(elm?'/elm-v2-'+variant:'');if(!split.has(key))split.set(key,{species,list:[],elm,variant});split.get(key).list.push(inst);}
  group.levels.forEach(mesh=>world.root.remove(mesh));
  for(const {species,list,elm,variant}of split.values()){
   const key=group.key+'/'+species.id+(elm?'/elm-v2-'+variant:''),kind=(species.crownKind||data.foliageSeasons.species[species.id].kind);
   assignments[key]={species:species.id,silhouette:kind,source:list.every(i=>i.species)?'export species + provenance':'P2 inferred city/form fallback',count:list.length};
   const capacity=list.length<=256?Math.max(1,list.length):Math.max(1001,list.length);
   const levels=group.levels.map((_,lod)=>{const gkey=species.id+'/'+lod+(elm?'/elm-v2-'+variant:'');let g=cache.get(gkey);if(!g){g=elm?buildElmV2(species,Math.min(lod,2),state,data,crownV2.pack,'elm-v2/'+variant):build(species,lod,state,data);cache.set(gkey,g);}const geo=g.clone();geo.setAttribute('leafTint',new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));geo.setAttribute('instOrigin',new T.InstancedBufferAttribute(new Float32Array(capacity*3),3));const m=new T.InstancedMesh(geo,deciduousExp1Identity(species,kind)?material:controlMaterial,capacity);m.count=0;m.castShadow=m.receiveShadow=true;m.userData.costCategory='foliage';world.root.add(m);return m;});
   // P2 exports already applied widthScale to stretch; undo that duplication for tagged species.
   const s=data.shapes[kind],d=species.dimensionsM;let widthScale=1;if(s){const widths=[0,2].map(axis=>Math.max(...s.lobes.map(([c,r])=>c[axis]+r))-Math.min(...s.lobes.map(([c,r])=>c[axis]-r)));widthScale=Math.max(.6,Math.min(1.2,(d.spread[0]+d.spread[1])/(d.height[0]+d.height[1])/((widths[0]+widths[1])/2)));}
   const instances=list.map(i=>i.species?{...i,stretch:(i.stretch||[1,1]).map(x=>x/widthScale)}:i);
   groups.push({...group,key,species,instances,levels,...(elm?{crownV2:true}:{}),triangles:levels.map(m=>m.geometry.index.count/3),counts:levels.map(()=>0)});
  }
 }
 if(crownV2)groups=poolElmGroups(groups,world.root);
 world.lodGroups=groups;
 // Same rebucketing as the shared loader; colours follow identities across LODs.
 const update=world.updateLODs.bind(world);world.updateLODs=position=>{update(position);
  let allocation=null;
  if(crownV2){const focal=crownV2.height()/(2*Math.tan(crownV2.camera.fov*Math.PI/360)),entries=[];
   for(const g of groups.filter(g=>g.crownV2))for(const i of g.instances){const distance=crownV2.camera.position.distanceTo(v(i.position));entries.push({key:g.key+'/'+i.id,distance,costs:g.triangles,desired:crownV2Level(i.scale*focal/Math.max(crownV2.camera.near,distance),crownV2.pack.lod,g.crownLevels?.get(i.id))});}
   allocation=allocateCrownBudget(entries,crownV2.tier==='floor'?75:217);world.crownBudget={tier:crownV2.tier||'standard',trees:entries.length,triangles:allocation.spent,limit:allocation.limit,average:allocation.average};
  }
  for(const g of groups.filter(g=>g.isTree)){if(g.crownV2)updateElmV2(g,crownV2.camera,crownV2.height(),crownV2.pack,allocation.levels);const counts=g.levels.map(()=>0);
   for(const inst of g.instances){const d=Math.hypot(Math.fround(inst.position[0])-position.x,Math.fround(inst.position[2])-position.z);let lod=0;while(lod<g.levels.length-1&&lod<world.runtime.lodDistances.length&&d>=world.runtime.lodDistances[lod])lod++;
    if(g.crownV2)lod=allocation.levels.get(g.key+'/'+inst.id);
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
  if(crownV2)world.treeTriangles=groups.filter(g=>g.isTree).reduce((n,g)=>n+g.levels.reduce((sum,m,l)=>sum+m.count*g.triangles[l],0),0);
 };return assignments;
}
