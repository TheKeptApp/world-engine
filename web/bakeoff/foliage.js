import * as T from 'three/webgpu';
import {mergeGeometries} from 'three/addons/utils/BufferGeometryUtils.js';
import {regionalSpecies} from './policy.js';
// Species assignments are inferred display fixtures, never an inventory claim.

const rand=n=>{const x=Math.sin(n*127.1+311.7)*43758.5453;return x-Math.floor(x);};
function paint(g,hex,seed){const c=new T.Color(hex),p=g.attributes.position,a=new Float32Array(p.count*3);for(let i=0;i<p.count;i++){const f=.88+.18*rand(seed+Math.floor(p.getY(i)*3));a.set([c.r*f,c.g*f,c.b*f],i*3);}g.setAttribute('color',new T.BufferAttribute(a,3));return g;}
function limb(a,b,r,hex){const d=b.clone().sub(a),g=new T.CylinderGeometry(r*.55,r,d.length(),6,1);g.applyQuaternion(new T.Quaternion().setFromUnitVectors(new T.Vector3(0,1,0),d.normalize()));g.translate(...a.clone().add(b).multiplyScalar(.5).toArray());return paint(g,hex,9);}
function crown(kind,species,bounds,lod,season){
 const h=bounds.max.y,w=Math.max(bounds.max.x-bounds.min.x,bounds.max.z-bounds.min.z),parts=[];
 // The deciduous bare-season swatch is bark (foliage-seasons-v1/winterPolicy).
 const bark=species.evergreen?'#766A5A':species.seasonColours.bare_or_evergreen;
 const trunkTop=h*(kind==='conifer'?.88:.67);parts.push(limb(new T.Vector3(0,0,0),new T.Vector3(h*.013,trunkTop,h*.006),Math.max(h*.011,w*.033),bark));
 // foliage-seasons-v1/species[].crown: tier counts and authored silhouette forms.
 const tier=lod===0?species.crown.nearClusterLobes:lod===1?species.crown.midClusterLobes:species.crown.farMasses;
 const n=Math.round((tier[0]+tier[1])/2);
 for(let i=0;i<n;i++){const a=i*2.39996+rand(i)*.5;let radius=w*(.14+.2*rand(i+71)),y=h*(.47+.35*rand(i+27));if(kind==='treeSpreading'){radius*=1.15;y=h*(.54+.21*rand(i+27));}if(kind==='treeOval'){radius*=.65;y=h*(.52+.32*rand(i+27));}if(kind==='conifer'){y=h*(.27+i/n*.63);radius=w*.36*(1-i/(n+2));}
 const center=new T.Vector3(Math.cos(a)*radius,y,Math.sin(a)*radius);
 if(lod<2&&kind!=='conifer')parts.push(limb(new T.Vector3(0,trunkTop*.65,0),center,w*.011,bark));
 const g=kind==='conifer'?new T.ConeGeometry(radius*1.4,h*.27,9,2):new T.SphereGeometry(1,lod===0?12:8,lod===0?9:6);
 if(kind!=='conifer'){const p=g.attributes.position;for(let v=0;v<p.count;v++){const x=p.getX(v),y0=p.getY(v),z=p.getZ(v);const f=1+.13*Math.sin(x*9+i)*Math.sin(z*8+i*.7)+.08*Math.cos(y0*13+i);p.setXYZ(v,x*f,y0*f,z*f);}g.scale(w*(.18+.06*rand(i+13)),h*(kind==='treeOval'?.20:kind==='treeSpreading'?.10:.13),w*.19);g.computeVertexNormals();}
 g.translate(...center.toArray());parts.push(paint(g,species.seasonColours[season],i+28));
 }
 const g=mergeGeometries(parts);parts.forEach(p=>p.dispose());g.computeBoundingBox();g.computeBoundingSphere();return g;
}
export function applySpecies(world,pack,roughness,region,season){
 const assignments={};
 const material=new T.MeshStandardNodeMaterial({vertexColors:true,roughness});material.shadowSide=T.BackSide;
 const cache=new Map();
 for(const group of world.lodGroups){if(!group.isTree)continue;const kind=group.kind,species=regionalSpecies(pack,region,kind,Number(group.key.split('/')[1]));assignments[group.key]=species.id;
 group.levels.forEach((mesh,lod)=>{const key=species.id+'/'+kind+'/'+lod;let geometry=cache.get(key);if(!geometry){mesh.geometry.computeBoundingBox();geometry=crown(kind,species,mesh.geometry.boundingBox,lod,season);cache.set(key,geometry);}const copy=geometry.clone();copy.setAttribute('instOrigin',mesh.geometry.attributes.instOrigin);mesh.geometry=copy;mesh.material=material;group.triangles[lod]=copy.index.count/3;});
 }
 return assignments;
}
