// CPU observations of the already-loaded scene. No materials or visibility are modified.
export function segmentInViewport(a,b){
 let lo=0,hi=1;for(let axis=0;axis<2;axis++){const d=b[axis]-a[axis];if(Math.abs(d)<1e-12){if(Math.abs(a[axis])>1)return false;continue;}let p=(-1-a[axis])/d,q=(1-a[axis])/d;if(p>q)[p,q]=[q,p];lo=Math.max(lo,p);hi=Math.min(hi,q);if(lo>hi)return false;}return true;
}
export function probeScene(b,metadata,thresholds){
 const {T,world,camera}=b;world.root.updateMatrixWorld(true);camera.updateMatrixWorld(true);
 const meshes=[],labels=new Map();
 for(let i=0;i<world.manifest.chunks.length;i++)world.root.children[i].traverse(o=>{
  if(!o.isMesh)return;meshes.push(o);const water=o.material===world.materials.water;
  labels.set(o,metadata[i].features.flatMap(f=>(f.lod0[water?'water':'static']||[]).map(([start,count])=>({start,end:start+count,kind:f.kind,id:f.id}))));
 });
 world.root.children[world.manifest.chunks.length].traverse(o=>{if(o.isMesh){meshes.push(o);labels.set(o,[{start:0,end:Infinity,kind:'boundary',id:'boundary'}]);}});
 const ray=new T.Raycaster(),counts={},ndc=new T.Vector2(),cols=thresholds.probeColumns,rows=thresholds.probeRows;
 // Raycasts are a structural frame mask. Props/foliage are excluded, so blank fraction
 // is an upper bound; a park area has its own identity and is not blank lawn.
 for(let y=0;y<rows;y++)for(let x=0;x<cols;x++){
  ndc.set(2*(x+.5)/cols-1,1-2*(y+.5)/rows);ray.setFromCamera(ndc,camera);ray.near=0;ray.far=camera.far;
  const hit=ray.intersectObjects(meshes,false)[0];let kind='sky';
  if(hit){const depth=hit.point.clone().applyMatrix4(camera.matrixWorldInverse).z;
   if(-depth<camera.near)kind='near-clipped';else{const ranges=labels.get(hit.object),v=hit.face.a;kind=ranges.find(r=>v>=r.start&&v<r.end)?.kind||'unknown';}}
  counts[kind]=(counts[kind]||0)+1;
 }
 const total=cols*rows,blank=(counts.boundary||0)+(counts['generated-ground']||0);
 // Exact near-plane intersections of submitted mesh triangles, including instances.
 // A 2 px segment inside the viewport is a potential visible clip, not an occlusion proof.
 let triangles=0,maxSegmentPixels=0;const names=new Set(),m=new T.Matrix4(),instance=new T.Matrix4(),combined=new T.Matrix4(),box=new T.Box3();
 const point=new T.Vector3(),v=[new T.Vector3(),new T.Vector3(),new T.Vector3()];
 const viewMeshes=[];world.root.traverse(o=>{if(o.isMesh&&o.visible)viewMeshes.push(o);});
 for(const mesh of viewMeshes){const geometry=mesh.geometry;geometry.computeBoundingBox();const index=geometry.index,position=geometry.getAttribute('position');if(!index||!position)continue;
  for(let inst=0;inst<(mesh.isInstancedMesh?mesh.count:1);inst++){
   if(mesh.isInstancedMesh){mesh.getMatrixAt(inst,instance);combined.multiplyMatrices(mesh.matrixWorld,instance);}else combined.copy(mesh.matrixWorld);
   m.multiplyMatrices(camera.matrixWorldInverse,combined);box.copy(geometry.boundingBox).applyMatrix4(m);
   if(-box.min.z<camera.near||-box.max.z>=camera.near)continue;
   for(let k=0;k<index.count;k+=3){for(let j=0;j<3;j++)v[j].fromBufferAttribute(position,index.getX(k+j)).applyMatrix4(m);
    const depths=v.map(p=>-p.z);if(Math.min(...depths)>=camera.near||Math.max(...depths)<=camera.near)continue;
    const cut=[];for(let j=0;j<3;j++){const n=(j+1)%3;if((depths[j]<camera.near)===(depths[n]<camera.near))continue;
     const t=(camera.near-depths[j])/(depths[n]-depths[j]);point.copy(v[j]).lerp(v[n],t).applyMatrix4(camera.projectionMatrix);cut.push([point.x,point.y]);}
    if(cut.length!==2||!segmentInViewport(cut[0],cut[1]))continue;
    const pixels=Math.hypot((cut[1][0]-cut[0][0])*b.spec.viewport.width/2,(cut[1][1]-cut[0][1])*b.spec.viewport.height/2);
    if(pixels>=thresholds.clippingSegmentPixels){triangles++;maxSegmentPixels=Math.max(maxSegmentPixels,pixels);names.add(mesh.name);}
   }
  }
 }
 const lost=(counts['near-clipped']||0)/total;
 return {blankGround:{fraction:blank/total,blankSamples:blank,totalSamples:total,counts,pass:blank/total<=thresholds.blankGroundFraction,method:'81x45 pixel-centre structural ray mask of static/water/boundary; excludes instance occlusion; upper bound, not colour grading'},clipping:{potential:triangles>0,intersectingTriangles:triangles,maxSegmentPixels,lostStaticFraction:lost,pass:lost<thresholds.clippedStaticFraction,meshes:[...names].sort(),status:lost>=thresholds.clippedStaticFraction?'fail':triangles?'warning':'pass',method:'static nearest-hit loss >=1% fails; near-plane triangle intersections including instances >=2 px warn; instance occlusion not resolved'}};
}
