import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {regionalSpecies} from './policy.js';
import {stableRandom} from './stable-random.js';
// Authored interpretations of foliage-seasons-v1/species[].crown.description.
export function silhouette(species){const d=species.crown.description.toLowerCase();if(/conical|cone/.test(d))return 'conical';if(/vase|arching/.test(d))return 'vase';if(/pyramid|heartlike/.test(d))return 'pyramidal';if(/open|airy|spreading/.test(d))return 'spreading';return /upright|oval/.test(d)?'oval':'rounded';}
function paint(g,hex,darkening=0){const c=new T.Color(hex),n=g.attributes.normal,a=new Float32Array(n.count*3);for(let i=0;i<n.count;i++){const f=1-darkening*(1-n.getY(i))*.5;a.set([c.r*f,c.g*f,c.b*f],i*3);}g.setAttribute('color',new T.BufferAttribute(a,3));return g;}
function limb(a,b,r,hex){const delta=b.clone().sub(a),g=new T.CylinderGeometry(r*.55,r,delta.length(),7,1);g.applyQuaternion(new T.Quaternion().setFromUnitVectors(new T.Vector3(0,1,0),delta.normalize()));g.translate(...a.clone().add(b).multiplyScalar(.5).toArray());return paint(g,hex);}
function crown(species,bounds,lod,season,variant){
 const rng=stableRandom('a2-crown-'+species.id,variant),h=bounds.max.y,w=Math.max(bounds.max.x-bounds.min.x,bounds.max.z-bounds.min.z),parts=[],shape=silhouette(species);
 const bark=species.evergreen?'#766A5A':species.seasonColours.bare_or_evergreen; // deciduous winterPolicy bark swatch
 const conical=shape==='conical',trunkTop=h*(conical?.85:.52);
 parts.push(limb(new T.Vector3(),new T.Vector3(0,trunkTop,0),w*.033,bark));
 const tier=lod===0?species.crown.nearClusterLobes:lod===1?species.crown.midClusterLobes:species.crown.farMasses,n=Math.round((tier[0]+tier[1])/2);
 const holes=species.crown.skyHoleFractionProposal.reduce((a,b)=>a+b,0)/2;
 for(let i=0;i<n;i++){
  const t=(i+.5)/n,a=i*Math.PI*(3-Math.sqrt(5)),jitter=rng();let y=h*(.38+.48*t),r=w*.29*Math.sqrt(Math.max(.1,1-(2*t-1)**2)),vertical=h*.115;
  if(shape==='vase'){r=w*(.17+.20*t);y=h*(.46+.40*t);vertical=h*.095;}
  if(shape==='spreading'){r=w*(.20+.15*jitter);y=h*(.57+.24*t);vertical=h*.075;}
  if(shape==='pyramidal'){r=w*.38*(1-.72*t);y=h*(.33+.54*t);vertical=h*.11;}
  if(shape==='oval'){r*=.7;vertical=h*.13;}
  const center=new T.Vector3(Math.cos(a)*r,y,Math.sin(a)*r);
  if(lod<2&&!conical)parts.push(limb(new T.Vector3(0,trunkTop*.7,0),center,w*.009,bark));
  let g;
  if(conical){const radius=w*.45*(1-.85*t);g=new T.ConeGeometry(radius,h*.23,lod===0?16:10,2);center.set(0,h*(.22+.65*t),0);}
  else {g=new T.SphereGeometry(1,lod===0?16:10,lod===0?10:7);const p=g.attributes.position;for(let v=0;v<p.count;v++){const x=p.getX(v),y0=p.getY(v),z=p.getZ(v),f=1+.045*Math.sin(x*3+i)*Math.cos(z*4-i);p.setXYZ(v,x*f,y0*f,z*f);}const lobe=w*(.15+.035*jitter)*(1-holes);g.scale(lobe,vertical,lobe*(.8+.25*rng()));}
  // Retain analytic smooth lobe normals: high-frequency recomputed normals made craggy blobs.
  g.translate(...center.toArray());parts.push(paint(g,species.seasonColours[season],species.crown.baseContactDarkeningProposal));
 }
 const g=mergeGeometries(parts);parts.forEach(p=>p.dispose());g.computeBoundingBox();
 // Exactly retain the exported envelope; silhouette detail never enlarges a particular tree.
 const b=g.boundingBox,sx=(bounds.max.x-bounds.min.x)/(b.max.x-b.min.x),sy=h/b.max.y,sz=(bounds.max.z-bounds.min.z)/(b.max.z-b.min.z),tx=bounds.min.x-b.min.x*sx,tz=bounds.min.z-b.min.z*sz;g.scale(sx,sy,sz);g.translate(tx,0,tz);
 g.computeBoundingBox();g.computeBoundingSphere();return g;
}
export function applySpecies(world,pack,roughness,region,season){
 const assignments={},material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness});material.shadowSide=T.BackSide;
 const cache=new Map();
 for(const group of world.lodGroups){if(!group.isTree)continue;const kind=group.kind,variant=Number(group.key.split('/')[1]),species=regionalSpecies(pack,region,kind,variant);assignments[group.key]={species:species.id,silhouette:silhouette(species)};
 group.levels.forEach((mesh,lod)=>{mesh.geometry.computeBoundingBox();const bounds=mesh.geometry.boundingBox,key=species.id+'/'+kind+'/'+variant+'/'+lod+'/'+bounds.min.toArray()+'/'+bounds.max.toArray();let geometry=cache.get(key);if(!geometry){geometry=crown(species,bounds,lod,season,variant);cache.set(key,geometry);}const copy=geometry.clone();copy.setAttribute('instOrigin',mesh.geometry.attributes.instOrigin);mesh.geometry=copy;mesh.material=material;group.triangles[lod]=copy.index.count/3;});
 }
 return assignments;
}
