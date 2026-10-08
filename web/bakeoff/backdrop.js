import * as T from 'three/webgpu';
import {Fn,Discard,output,attribute,vec3,vec4,float,dot,abs,max,min,exp,length,mix,select,smoothstep,positionWorld,cameraPosition,uniform} from 'three/tsl';
import {linearHex,luminance,mountainVisibility} from './atmosphere.js';
// mountain-terrain-v1: real DEM, geocentric curvature, no invented snow.
export async function addFrontRange(scene,config,frame,origin,pack,policy,camera){
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
 const p=pack.palettes.summer,A=policy.atmosphere,rule=A.mountains,L=policy.look.lighting;
 const m=new T.MeshStandardNodeMaterial({color:p.graniteHex,roughness:p.roughness.rock,side:T.DoubleSide});
 // The homogeneous atmosphere is applied HERE once for terrain so the visibility
 // test sees the un-fogged lit radiance; world materials use the same term via scene.fogNode.
 m.fog=false;m.transparent=true;m.forceSinglePass=true;
 const rock=linearHex(p.graniteHex),sky=linearHex(policy.sky.fillHex),ground=linearHex(policy.look.materials.groundBaseHex.lawn),sun=linearHex(L.sun.hex);
 const az=L.sun.azimuthDeg*Math.PI/180,el=L.sun.elevationDeg*Math.PI/180,sd=[Math.sin(az)*Math.cos(el),Math.sin(el),-Math.cos(az)*Math.cos(el)];
 const normals=g.attributes.normal,lit=[],bands=[],angles=[],ridges=new Map(),sums=new Map();
 const eye=camera.position,binSize=pack.lod.horizonImpostor.azimuthSampleDeg*Math.PI/180;
 for(let i=0;i<w*h;i++){
  const dx=positions[i*3]-eye.x,dy=positions[i*3+1]-eye.y,dz=positions[i*3+2]-eye.z,distance=Math.hypot(dx,dy,dz),horizontal=Math.hypot(dx,dz);
  const n=[normals.getX(i),normals.getY(i),normals.getZ(i)],hemi=n[1]*.5+.5,cosine=Math.max(0,n.reduce((v,x,j)=>v+x*sd[j],0));
  // Lambert diffuse in the same linear-light units as the shared sun/fill.
  const colour=rock.map((v,j)=>v*(policy.ambientIntensity*(ground[j]*(1-hemi)+sky[j]*hemi)+policy.directIntensity*sun[j]*cosine)/Math.PI);
  lit.push(colour);const band=pack.demByDistance.findIndex(b=>distance>=b.rangeM[0]&&distance<b.rangeM[1]);bands.push(band);
  const weight=Math.cos((north-(Math.floor(i/w)+.5)/h*(north-south))*Math.PI/180),sum=sums.get(band)||[0,0,0,0];for(let j=0;j<3;j++)sum[j]+=colour[j]*weight;sum[3]+=weight;sums.set(band,sum);
  const bin=Math.floor(Math.atan2(dx,-dz)/binSize);angles.push(bin);ridges.set(bin,Math.max(ridges.get(bin)||0,Math.atan2(dy,horizontal)));
 }
 const coarse=new Float32Array(w*h*3),ridge=new Float32Array(w*h);
 for(let i=0;i<w*h;i++){const avg=sums.get(bands[i]);coarse.set(avg.slice(0,3).map(v=>v/avg[3]),i*3);ridge[i]=Math.tan(ridges.get(angles[i]));}
 g.setAttribute('coarseRadiance',new T.BufferAttribute(coarse,3));g.setAttribute('ridgeReliefAngle',new T.BufferAttribute(ridge,1));
 const projectedScale=uniform(1),air=vec3(...A.airlightLinear),weights=vec3(.2126,.7152,.0722),airY=max(dot(air,weights),.001);
 m.outputNode=Fn(()=>{
  const transmission=exp(length(positionWorld.sub(cameraPosition)).mul(-A.sigmaPerM));
  const fine=output.rgb,contrast=abs(dot(fine,weights).sub(dot(air,weights))).div(airY).mul(transmission);
  // haze-visibility-v1/mountains.internalDetailContrast: below threshold use
  // an area-weighted diffuse mean in the source mountain pack distance band.
  // This removes fold shading without moving, enlarging or boosting terrain.
  const simplified=select(contrast.lessThan(rule.internalDetailContrast),attribute('coarseRadiance','vec3'),fine);
  // Averaging must never rescue a silhouette that failed its original contrast.
  const retained=min(contrast,abs(dot(simplified,weights).sub(dot(air,weights))).div(airY).mul(transmission));
  const pixels=attribute('ridgeReliefAngle','float').mul(projectedScale);
  const alpha=smoothstep(rule.cullContrast,rule.retainContrast,retained).mul(select(pixels.greaterThanEqual(rule.minProjectedHeightPx),float(A.summitsObscured?0:1),float(0)));
  Discard(alpha.lessThanEqual(0));
  return vec4(mix(air,simplified,transmission),alpha);
 })();
 const mesh=new T.Mesh(g,m);mesh.name='USGS 3DEP Front Range';mesh.userData.costCategory='DEM';scene.add(mesh);
 const diagnostics={vertices:w*h,triangles:indices.length/3,observerElevationM:observer,source:'haze-visibility-v1/mountains + mountain-terrain-v1/lod.horizonImpostor.azimuthSampleDeg',sightline:'geocentric DEM plus ordinary terrain/world depth occlusion; refraction off',cloud:'simulated clear fixture; no summit-obscuring cloud layer',airlightLinear:A.airlightLinear};
 const updateProjection=height=>{projectedScale.value=height/(2*Math.tan(camera.fov*Math.PI/360));let eligible=0,maxContrast=0;for(let i=0;i<w*h;i++){const distance=Math.hypot(positions[i*3]-eye.x,positions[i*3+1]-eye.y,positions[i*3+2]-eye.z);if(distance<5000)continue;const v=mountainVisibility(rule,lit[i],A.airlightLinear,A.sigmaPerM,distance,ridge[i]*projectedScale.value,A.summitsObscured);if(v.retain)eligible++;maxContrast=Math.max(maxContrast,v.retainedContrast);}Object.assign(diagnostics,{eligibleVerticesBeforeDepthOcclusion:eligible,maxEstimatedRetainedContrast:maxContrast,projectedHeightRule:rule.minProjectedHeightPx});};
 return {diagnostics,updateProjection};
}
