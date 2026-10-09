// Tooling adapter: replay existing contracts/export semantics; no look values or renderer edits.
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {LocalFrame} from '../web/src/geo.js';
export function inspectionCamera(pose,altitude,origin={latitude:pose.lat,longitude:pose.lon}){
 const {lat,lon,heading,fov}=pose,frame=new LocalFrame(origin.latitude,origin.longitude),r=heading*Math.PI/180;
 const base=frame.local(lat,lon),east=base[0]+100*Math.sin(r),north=base[1]+100*Math.cos(r);let latitude=lat,longitude=lon;
 // Invert the existing WGS84 local frame for an exact horizontal direction.
 for(let i=0;i<5;i++){
  const p=frame.local(latitude,longitude),a=frame.local(latitude+1e-5,longitude),b=frame.local(latitude,longitude+1e-5);
  const j00=(a[0]-p[0])/1e-5,j01=(b[0]-p[0])/1e-5,j10=(a[1]-p[1])/1e-5,j11=(b[1]-p[1])/1e-5,det=j00*j11-j01*j10;
  latitude+=((east-p[0])*j11-(north-p[1])*j01)/det;
  longitude+=(j00*(north-p[1])-j10*(east-p[0]))/det;
 }
 return {eye:[lat,lon,altitude],target:[latitude,longitude,altitude-100*Math.tan((pose.pitchDown??45)*Math.PI/180)],fov};
}
export async function blockContract(root,block){
 const read=async p=>JSON.parse(await readFile(resolve(root,p),'utf8'));
 const frozen=await read('scripts/web_capture_contract.json');
 if(block==='lakeview-ladder'){
  const saved=frozen.scenes.lakeview,pose={lat:saved.camera.eye[0],lon:saved.camera.eye[1],heading:270,pitchDown:45,fov:50};
  const manifest=await read('web/bakeoff/generated/lakeview-sheil-park/world.json');
  if(!manifest.frame.vertical.includes('y = 0 is ground'))throw Error('Lakeview ladder requires its flat-ground export');
  return {...frozen,source:'R scene-budget hold-out qualification; existing Lakeview eye and shared 40/150/600 m, heading270/pitch45/FOV50 recipe',fixture:{...frozen.fixture,date:'2026-10-15'},scenes:Object.fromEntries([40,150,600].map(alt=>['lakeview-'+alt,{...saved,templateScene:'lakeview',viewport:{width:1005,height:565},camera:inspectionCamera(pose,alt,manifest.frame.origin),inspection:{...pose,altitudeAGLMetres:alt,utc:'2026-10-15T20:30:00Z',groundDatum:manifest.frame.vertical}}]))};
 }
 if(block==='lakeview-600'){
  const saved=frozen.scenes.lakeview,pose={lat:saved.camera.eye[0],lon:saved.camera.eye[1],heading:270,pitchDown:45,fov:50};
  return {...frozen,source:'R near-plane follow-up; saved Lakeview web eye, same 600 m/270/45/50 diagnostic recipe as lake-banding-diagnosis.md',fixture:{...frozen.fixture,date:'2026-10-15'},scenes:{lakeview:{...saved,viewport:{width:1005,height:565},camera:inspectionCamera(pose,600),inspection:{...pose,altitudeAGLMetres:600,utc:'2026-10-15T20:30:00Z',groundDatum:'export flat ground y=0; resolved from generated manifest before navigation'}}}};
 }
 if(block==='sloans-ladder'){
  const ladder=await read('scripts/web_sloans_ladder.json');
  return {...frozen,source:ladder.source,ladder,tier:ladder.tier,fixture:{...frozen.fixture,date:ladder.utc.slice(0,10)},scenes:Object.fromEntries(ladder.altitudesAGLMetres.map(alt=>['sloans-'+alt,{...frozen.scenes.sloans,templateScene:'sloans',viewport:ladder.viewport,camera:inspectionCamera(ladder.pose,alt),inspection:{...ladder.pose,altitudeAGLMetres:alt,utc:ladder.utc,groundDatum:ladder.groundDatum}}]))};
 }
 if(block==='wilmette'){
  const demo=(await read('Apps/WorldLab/Resources/demo.json')).areas['wilmette-vattmann-park'];
  const native=(await read('docs/lookloop/a3-capture-contract.json')).views.find(v=>v.id==='wilmette-street-afternoon');
  const pose=demo.cameras['northshore-postcard'],area=native.area;
  return {...frozen,source:'a3-capture-contract.json wilmette-street-afternoon + demo.json northshore-postcard; crown-native-before-evidence.md pose recipe (40/150/600 m, pitch 45, 1005x565)',fixture:{...frozen.fixture,date:native.utc.slice(0,10)},scenes:Object.fromEntries([40,150,600].map(alt=>['wilmette-'+alt,{world:'/world/capture/'+area+'/',mock:'01-lakeview',viewport:{width:1005,height:565},camera:inspectionCamera(pose,alt),region:'chicago',climateRegion:'great-lakes',area,inspection:{altitudeMetres:alt,heading:pose.heading,pitchDown:45,sourceUTC:native.utc}}])),exports:[{area,date:native.utc,focus:[demo.focus.south,demo.focus.west,demo.focus.north,demo.focus.east].join(',')}]};
 }
 if(block==='west-highland'){
  const prior=await read('docs/lookloop/west-highland-capture-contract.json'),c=prior.camera,area=prior.area;
  const manifest=await read('Data/areas/'+area+'/manifest.json'),b=manifest.approvedBounds;
  return {...frozen,source:'docs/lookloop/west-highland-capture-contract.json (existing frozen web camera)',fixture:prior.fixture,scenes:{'west-highland':{world:'/world/capture/'+area+'/',mock:'06-sloans',viewport:c.viewportPixels,camera:{eye:[c.eye.latitude,c.eye.longitude,c.eye.sceneYMetres],target:[c.target.latitude,c.target.longitude,c.target.sceneYMetres],fov:c.verticalFovDegrees},region:'denver',climateRegion:'front-range',area}},exports:[{area,date:prior.fixture.date+'T20:30:00Z',focus:[b.south,b.west,b.north,b.east].join(',')}]};
 }
 throw Error('No integrated web region/fixture adapter for '+block+'; current web haze and phenology tables cover only Denver/Chicago; renderer-owner integration required');
}
export async function facadeInputs(root,area,exportPath){
 // Same semantic extraction as web/bakeoff/compile-facade-data.py, parameterized for captures.
 const read=async p=>JSON.parse(await readFile(p,'utf8'));
 const osm=(await read(resolve(root,'Data/areas',area,'osm.json'))).elements;
 const nodes=new Map(osm.filter(e=>e.type==='node').map(e=>[e.id,e]));
 const ways=new Map(osm.filter(e=>e.type==='way').map(e=>[String(e.id),e]));
 const manifest=await read(resolve(exportPath,'world.json')),all=[];
 for(const chunk of manifest.chunks)all.push(...(await read(resolve(exportPath,chunk.scene))).features);
 const fences=new Set(all.filter(f=>f.kind==='generated-fence').map(f=>f.id.replace(/^gen:fence:/,''))),seen=new Set(),features=[];
 const points=ids=>ids.filter(n=>nodes.has(n)).map(n=>[nodes.get(n).lat,nodes.get(n).lon]);
 for(const f of all){
  if(f.kind!=='building'||seen.has(f.id)||!f.generated?.family)continue;
  seen.add(f.id);const way=ways.get(f.id.split('/').at(-1));if(!way)continue;
  const ring=points(way.nodes.slice(0,-1));if(ring.length<3)continue;
  features.push({id:f.id,ring,generated:f.generated,source:f.source||{},hasFence:fences.has(f.id)});
 }
 const roads=[...ways.values()].filter(w=>['residential','tertiary','secondary','primary','unclassified','living_street'].includes(w.tags?.highway)).map(w=>points(w.nodes||[])).filter(p=>p.length>1);
 return {source:`Data/areas/${area}/osm.json + export chunks/*/scene.json; OSM attribution retained.`,features,roads};
}
