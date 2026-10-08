import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {stableRandom} from './stable-random.js';
import {facadeFamily,wallColour,detailTier} from './facade-policy.js';
const mean=x=>Array.isArray(x)?(x[0]+x[1])/2:x;
const dist=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
const inside=(p,ring)=>{let hit=false;for(let i=0,j=ring.length-1;i<ring.length;j=i++){const a=ring[i],b=ring[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])hit=!hit;}return hit;};
const nearest=(p,a,b)=>{const x=b[0]-a[0],z=b[1]-a[1],t=Math.max(0,Math.min(1,((p[0]-a[0])*x+(p[1]-a[1])*z)/(x*x+z*z||1)));return [a[0]+x*t,a[1]+z*t];};
// Preserve all unknown families/eras. Export wall slots are changed only on the
// feature's existing vertices; this cannot recolour adjacent lawns or roofs.
export async function facadeColours(world,pack,region){
 let count=0;world.root.traverse(o=>{if(o.isMesh)o.geometry.setAttribute('_facade',new T.BufferAttribute(new Float32Array(o.geometry.attributes.position.count*4),4));});
 await Promise.all(world.manifest.chunks.map(async(chunk,ci)=>{
  const info=await (await fetch(world.base+chunk.scene)).json();let mesh;world.root.children[ci].traverse(o=>{if(o.isMesh&&o.material===world.materials.static)mesh=o;});if(!mesh)return;
  const g=mesh.geometry,idx=g.index.array,paint=g.attributes._paint,fa=g.attributes._facade;
  for(const f of info.features){if(f.kind!=='building'||!f.generated)continue;const family=facadeFamily(region,f.generated,pack);if(!family)continue;
   const hex=wallColour(family,f.source||{},pack,stableRandom('facade-era/'+f.id)),colour=new T.Color(hex),old=f.generated.colors?.[0]?.toLowerCase();if(!old)continue;
   const slots=new Set(world.palettes.slots.filter(s=>s.srgb.toLowerCase()===old).map(s=>s.slot));
   for(const [start,n]of f.lod0.static)for(let i=start*3;i<Math.min(idx.length,(start+n)*3);i++){const j=idx[i];if(slots.has(Math.round(paint.getX(j))))fa.setXYZW(j,colour.r,colour.g,colour.b,family.id.includes('greystone')?2:1);}
   count++;
  }fa.needsUpdate=true;
 }));return count;
}
export function facadeDetails(scene,source,frame,pack,region,look,mechanics){
 const features=source.features.map(f=>({...f,ring:f.ring.map(([lat,lon])=>{const p=frame.scene(lat,lon);return [p[0],p[2]];})}));
 const roads=source.roads.flatMap(line=>line.slice(1).map((p,i)=>[line[i],p].map(([lat,lon])=>{const v=frame.scene(lat,lon);return [v[0],v[2]];})));
 const plans=[],root=new T.Group();root.name='Pack facade detail tiers';scene.add(root);
 const material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness:look.materials.roughness.masonry});
 for(const f of features){const family=facadeFamily(region,f.generated,pack);if(!family)continue;const ring=f.ring,H=f.generated.eaveHeight;if(!(H>0))continue;
  let area=0;for(let i=0;i<ring.length;i++){const a=ring[i],b=ring[(i+1)%ring.length];area+=a[0]*b[1]-b[0]*a[1];}
  let best=null;for(let i=0;i<ring.length;i++){const a=ring[i],b=ring[(i+1)%ring.length],len=dist(a,b);if(len<mechanics.minimumFrontageM)continue;const dir=[(b[0]-a[0])/len,(b[1]-a[1])/len],normal=area>0?[dir[1],-dir[0]]:[-dir[1],dir[0]],mid=[(a[0]+b[0])/2,(a[1]+b[1])/2];
   for(const [r0,r1]of roads){const road=nearest(mid,r0,r1),d=dist(mid,road);if((road[0]-mid[0])*normal[0]+(road[1]-mid[1])*normal[1]<=0)continue;if(!best||d<best.distance)best={a,dir,normal,len,mid,distance:d};}
  }if(!best)continue;
  const rng=stableRandom('facade-detail/'+f.id),wall=wallColour(family,f.source||{},pack,rng),trim=family.trim||family.wall,depth=mean(family.bayProjectionM),base=mean(family.raisedBaseM||mechanics.defaultRaisedBaseM);
  // P2 planBay/frontClear: do not intrude into roads or neighboring footprints.
  const clear=best.distance>=mechanics.frontClearM+mechanics.roadMarginM&&!features.some(other=>other.id!==f.id&&[0,.5,1].some(t=>inside([best.a[0]+best.dir[0]*best.len*t+best.normal[0]*mechanics.frontClearM,best.a[1]+best.dir[1]*best.len*t+best.normal[1]*mechanics.frontClearM],other.ring)));
  plans.push({f,family,H,base,depth,wall,trim,...best,clear});
 }
 let signature='',report={buildings:plans.length,tiers:{},features:{},source:'facade-detail-v1/content,lod; export grammar + OSM footprints; inferred additions, not surveyed facade inventory'};
 function update(camera,height){
  const tiers=plans.map(p=>detailTier(p.H,Math.hypot(camera.position.x-p.mid[0],camera.position.z-p.mid[1]),height,camera.fov,pack.lod)),key=tiers.join(',')+'/'+height+'/'+camera.fov;
  if(key===signature)return;signature=key;for(const m of [...root.children]){root.remove(m);m.geometry.dispose();}const buckets=new Map();report.tiers={near:0,middle:0,far:0};report.features={bays:0,stoops:0,cornices:0,fences:0};
  plans.forEach((p,index)=>{const tier=tiers[index];report.tiers[tier]++;if(tier==='far')return;const near=tier==='near',distance=Math.hypot(camera.position.x-p.mid[0],camera.position.z-p.mid[1]),pxPerM=height/(2*Math.tan(camera.fov*Math.PI/360)*Math.max(distance,Number.EPSILON));
   const pieces=[],thin=mean(pack.content.details.windowRecessM),floorH=(p.H-p.base)/Math.max(1,p.f.generated.floors),at=(x,y,z)=>[p.a[0]+p.dir[0]*x+p.normal[0]*z,y,p.a[1]+p.dir[1]*x+p.normal[1]*z];
   function box(x,y,z,w,h,d,hex,essential=false){if(!essential&&Math.min(w,h,d)*pxPerM<pack.lod.featureCullBelowPx)return;const g=new T.BoxGeometry(w,h,d);g.rotateY(-Math.atan2(p.dir[1],p.dir[0]));g.translate(...at(x,y,z));g.deleteAttribute('uv');const c=new T.Color(hex),a=new Float32Array(g.attributes.position.count*3);for(let i=0;i<a.length;i+=3)a.set([c.r,c.g,c.b],i);g.setAttribute('color',new T.BufferAttribute(a,3));pieces.push(g);}
   const cornice=mean(p.family.corniceProjectionM||thin);box(p.len/2,p.H-thin/2,cornice/2,p.len,thin,cornice,p.trim,true);report.features.cornices++;
   // Existing export bays/stoops are retained. Add a restrained secondary bay only
   // to long straight fronts, clear of entry and neighbors (same rule every city).
   if(p.clear&&p.len>=mechanics.minimumBayFrontageM){const width=Math.min(mean(mechanics.bayWidthM),p.len*mechanics.bayWidthFraction),x=p.len*mechanics.bayCentreFraction;
    box(x,(p.H+p.base)/2,p.depth/2,width,p.H-p.base-thin,p.depth,p.wall,true);
    for(let floor=0;floor<Math.max(1,p.f.generated.floors);floor++){const y=p.base+floorH*(floor+.5);box(x,y,p.depth+thin/2,width-thin*2,Math.min(mean(mechanics.windowHeightM),floorH-thin*2),thin,p.f.generated.colors?.[2]||mechanics.glassHex,true);box(x,y-mean(mechanics.windowHeightM)/2,p.depth+thin/2,width+thin,thin,thin*2,p.trim);}
    report.features.bays++;
   }
   if(p.clear&&!p.f.generated.hasPorch){const width=mean(mechanics.stoopWidthM),x=p.len*mechanics.entryFraction,tread=mean(pack.content.details.stoopTreadM),risers=Math.max(1,Math.round(p.base/mean(pack.content.details.stoopRiserM)));
    if(near&&tread*pxPerM>=pack.lod.featureCullBelowPx){for(let i=0;i<risers;i++){const h=p.base*(risers-i)/risers;box(x,h/2,(i+.5)*tread,width,h,tread,p.trim,true);}}else box(x,p.base/2,risers*tread/2,width,p.base,risers*tread,p.trim,true);report.features.stoops++;
   }
   // Fences only where export data actually contains one; never invent a lot line.
   if(p.f.hasFence&&p.clear){const H=mean(pack.content.details.ironFenceHeightM),bar=mean(pack.content.details.ironBarWidthM),z=mechanics.frontClearM,x0=0,x1=p.len*mechanics.fenceFrontageFraction;
    if(near&&bar*pxPerM>=pack.lod.featureCullBelowPx){for(let x=x0;x<x1;x+=mechanics.fenceSpacingM)box(x,H/2,z,bar,H,bar,pack.content.details.ironColour,true);}
    for(const y of [H*mechanics.fenceLowerRailFraction,H])box((x0+x1)/2,y,z,x1-x0,bar,bar,pack.content.details.ironColour);report.features.fences++;
   }
   if(pieces.length){const key=Math.floor(p.mid[0]/mechanics.cellM)+','+Math.floor(p.mid[1]/mechanics.cellM);if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push(...pieces);}
  });
  for(const parts of buckets.values()){const geometry=mergeGeometries(parts);parts.forEach(g=>g.dispose());const mesh=new T.Mesh(geometry,material);mesh.castShadow=mesh.receiveShadow=true;mesh.userData.costCategory='facade details';root.add(mesh);}
 }
 return {update,report};
}
