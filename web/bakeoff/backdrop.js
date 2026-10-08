import * as T from 'three/webgpu';
// mountain-terrain-v1: real DEM, geocentric curvature, no invented snow.
export async function addFrontRange(scene,config,frame,origin,pack){
 const response=await fetch(config.dem);if(!response.ok)throw Error('DEM unavailable');
 const d=await response.json(),[west,south,east,north]=d.bbox,w=d.width,h=d.height;
 const sample=(lat,lon)=>d.heightsM[Math.max(0,Math.min(h-1,Math.round((north-lat)/(north-south)*h-.5)))*w+Math.max(0,Math.min(w-1,Math.round((lon-west)/(east-west)*w-.5)))];
 const observer=sample(origin.latitude,origin.longitude),positions=[],indices=[];
 const [sl,cl,so,co]=frame.trig;
 for(let row=0;row<h;row++)for(let col=0;col<w;col++){
  const lat=(north-(row+.5)/h*(north-south))*Math.PI/180,lon=(west+(col+.5)/w*(east-west))*Math.PI/180,alt=d.heightsM[row*w+col];
  const e2=6.6943799901413165e-3,n=6378137/Math.sqrt(1-e2*Math.sin(lat)**2);
  const dx=(n+alt)*Math.cos(lat)*Math.cos(lon)-frame.origin[0],dy=(n+alt)*Math.cos(lat)*Math.sin(lon)-frame.origin[1],dz=(n*(1-e2)+alt)*Math.sin(lat)-frame.origin[2];
  positions.push(-so*dx+co*dy,cl*co*dx+cl*so*dy+sl*dz-observer,sl*co*dx+sl*so*dy-cl*dz);
 }
 for(let r=0;r<h-1;r++)for(let c=0;c<w-1;c++){
  const a=r*w+c,b=a+1,k=a+w;
  // The detailed export owns the near ground; DEM is the far-view layer only.
  if(Math.hypot(positions[a*3],positions[a*3+2])<5000)continue;
  indices.push(a,k,b,b,k,k+1);
 }
 const g=new T.BufferGeometry();g.setAttribute('position',new T.Float32BufferAttribute(positions,3));g.setIndex(indices);g.computeVertexNormals();
 const p=pack.palettes.summer,m=new T.MeshStandardNodeMaterial({color:p.graniteHex,roughness:p.roughness.rock,side:T.DoubleSide});
 const mesh=new T.Mesh(g,m);mesh.name='USGS 3DEP Front Range';mesh.userData.costCategory='DEM';scene.add(mesh);
 return {vertices:w*h,triangles:indices.length/3,observerElevationM:observer};
}
