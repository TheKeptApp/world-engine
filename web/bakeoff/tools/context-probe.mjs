// Same 81x45 structural sample grid/denominator as world_scoreboard_probes.mjs.
// Keep unknown/generated ground blank; count only actual mapped context triangles.
export function contextBlankProbe(b,metadata,T){
 const {world,camera}=b;world.root.updateMatrixWorld(true);b.scene.updateMatrixWorld(true);camera.updateMatrixWorld(true);
 const meshes=[],labels=new Map();
 for(let i=0;i<world.manifest.chunks.length;i++)world.root.children[i].traverse(o=>{
  if(!o.isMesh)return;meshes.push(o);const water=o.userData.costCategory==='water'||o.material===world.materials.water;
  labels.set(o,metadata[i].features.flatMap(f=>(f.lod0[water?'water':'static']||[]).map(([start,count])=>({start,end:start+count,kind:f.kind}))));
 });
 world.root.children[world.manifest.chunks.length].traverse(o=>{if(o.isMesh){meshes.push(o);labels.set(o,[{start:0,end:Infinity,kind:'boundary'}]);}});
 for(const mesh of b.contextMeshes||[]){meshes.push(mesh);labels.set(mesh,[{start:0,end:Infinity,kind:mesh.userData.contextKind}]);}
 const ray=new T.Raycaster();ray.layers.enableAll();const ndc=new T.Vector2(),counts={},cols=81,rows=45;
 for(let y=0;y<rows;y++)for(let x=0;x<cols;x++){
  ndc.set(2*(x+.5)/cols-1,1-2*(y+.5)/rows);ray.setFromCamera(ndc,camera);ray.near=0;ray.far=camera.far;
  const hit=ray.intersectObjects(meshes,false)[0];let kind='sky';
  if(hit){const depth=-hit.point.clone().applyMatrix4(camera.matrixWorldInverse).z;
   kind=depth<camera.near?'near-clipped':labels.get(hit.object).find(r=>hit.face.a>=r.start&&hit.face.a<r.end)?.kind||'unknown';}
  counts[kind]=(counts[kind]||0)+1;
 }
 const blank=(counts.boundary||0)+(counts['generated-ground']||0),total=cols*rows;
 return {fraction:blank/total,blankSamples:blank,totalSamples:total,counts,pass:blank/total<.35,method:'81x45 structural ray mask; unchanged boundary/generated-ground numerator; actual mapped context triangles added; instances excluded; strict <35%'};
}
