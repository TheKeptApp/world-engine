import * as T from 'three/webgpu';
// One shared field across chunks: cancelling paired edges avoids visible chunk seams.
// Distance to shore is an artistic depth proxy, not bathymetry.
export function shorelineField(meshes){
 const edges=new Map(),bounds=new T.Box3();
 const key=(x,z)=>`${x.toFixed(2)},${z.toFixed(2)}`;
 for(const mesh of meshes){const g=mesh.geometry,p=g.attributes.position,idx=g.index.array;g.computeBoundingBox();bounds.union(g.boundingBox.clone().applyMatrix4(mesh.matrixWorld));const points=Array.from({length:p.count},(_,i)=>new T.Vector3().fromBufferAttribute(p,i).applyMatrix4(mesh.matrixWorld));
 for(let t=0;t<idx.length;t+=3)for(let k=0;k<3;k++){const i=idx[t+k],j=idx[t+(k+1)%3],a=[points[i].x,points[i].z],b=[points[j].x,points[j].z],ka=key(...a),kb=key(...b),s=ka<kb?ka+'|'+kb:kb+'|'+ka;const e=edges.get(s);if(e)e.count++;else edges.set(s,{a,b,count:1});}}
 const segments=[...edges.values()].filter(e=>e.count===1),size=1024,bytes=new Uint8Array(size*size*4),width=bounds.max.x-bounds.min.x,depth=bounds.max.z-bounds.min.z;
 for(let y=0;y<size;y++)for(let x=0;x<size;x++){const px=bounds.min.x+(x+.5)/size*width,pz=bounds.min.z+(y+.5)/size*depth;let distance=32;for(const {a,b} of segments){if(px<Math.min(a[0],b[0])-distance||px>Math.max(a[0],b[0])+distance||pz<Math.min(a[1],b[1])-distance||pz>Math.max(a[1],b[1])+distance)continue;const dx=b[0]-a[0],dz=b[1]-a[1],t=Math.max(0,Math.min(1,((px-a[0])*dx+(pz-a[1])*dz)/(dx*dx+dz*dz||1)));distance=Math.min(distance,Math.hypot(px-a[0]-dx*t,pz-a[1]-dz*t));}const i=(y*size+x)*4;bytes[i]=bytes[i+1]=bytes[i+2]=Math.round(distance/32*255);bytes[i+3]=255;}
 const texture=new T.DataTexture(bytes,size,size);texture.minFilter=texture.magFilter=T.LinearFilter;texture.generateMipmaps=false;texture.needsUpdate=true;return {texture,min:[bounds.min.x,bounds.min.z],span:[width,depth],segments:segments.length};
}
