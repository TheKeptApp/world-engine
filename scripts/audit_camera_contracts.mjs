// Read-only audit: measured scoreboard matrices and retained web contracts.
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {LocalFrame} from '../web/src/geo.js';
import {resolvedPose} from './world_scoreboard_checks.mjs';
const root=resolve(new URL('../',import.meta.url).pathname),read=async p=>JSON.parse(await readFile(resolve(root,p),'utf8'));
const scoreboard=await read('docs/scoreboard/world-scoreboard-v0.json'),rows=[];
for(const r of scoreboard.rows){
 const actual=resolvedPose(r.evidence.camera),expected={pitchDown:r.pose.pitchDown,heading:r.pose.heading,fov:r.pose.fov,height:r.altitude};
 rows.push({area:r.area,contract:'scoreboard ladder',height:r.altitude,expected,resolved:actual,source:'docs/scoreboard/world-scoreboard-v0.json',mismatches:diff(expected,actual)});
}
function diff(a,b){return Object.keys(a).filter(k=>Math.abs(k==='heading'?((b[k]-a[k]+540)%360)-180:b[k]-a[k])>.001);}
// Retained matrices are the authority for historical frames; the JSON is not edited.
for(const path of ['docs/review/holdout-camera-retained.json','docs/lookloop/captures/a7-web-crown-all-near-fix/manifest.json']){
 const d=await read(path);
 for(const f of d.frames){
  const annotation=f.inspection||f.pose,requested=f.camera||f.requestedCamera,camera=f.resolvedCamera;
  if(!annotation||!camera)continue;
  const area=f.area||(f.scene.startsWith('sloans')?'sloans-lake':'lakeview-sheil-park');
  const expected={pitchDown:annotation.pitchDown,heading:annotation.heading,fov:requested.fov,height:requested.eye[2]},actual=resolvedPose(camera);
  rows.push({area,contract:'retained bakeoff ladder',height:expected.height,expected,resolved:actual,source:f.originalReport||path,frame:f.frame||f.file,sha256:f.sha256,mismatches:diff(expected,actual)});
 }
}
const frozen=await read('scripts/web_capture_contract.json');
for(const [name,c] of Object.entries(frozen.scenes)){
 const area=name==='sloans'?'sloans-lake':'lakeview-sheil-park',m=await read('Data/areas/'+area+'/manifest.json'),frame=new LocalFrame(m.center.latitude,m.center.longitude),eye=frame.scene(...c.camera.eye),target=frame.scene(...c.camera.target);
 const actual=resolvedPose({position:eye,direction:target.map((v,i)=>v-eye[i]),fov:c.camera.fov});
 rows.push({area,contract:'saved street pair (not ladder)',height:c.camera.eye[2],expected:{fov:c.camera.fov,height:c.camera.eye[2]},resolved:actual,source:'scripts/web_capture_contract.json',mismatches:diff({fov:c.camera.fov,height:c.camera.eye[2]},actual),note:'Pitch/heading are eye-target-defined, not annotated as 45°.'});
}
const west=await read('docs/lookloop/west-highland-capture-contract.json'),c=west.camera,m=await read('Data/areas/west-highland/manifest.json'),frame=new LocalFrame(m.center.latitude,m.center.longitude),eye=frame.scene(c.eye.latitude,c.eye.longitude,c.eye.sceneYMetres),target=frame.scene(c.target.latitude,c.target.longitude,c.target.sceneYMetres);
rows.push({area:'west-highland',contract:'saved aerial (not ladder)',height:c.eye.sceneYMetres,expected:{fov:c.verticalFovDegrees,height:c.eye.sceneYMetres},resolved:resolvedPose({position:eye,direction:target.map((v,i)=>v-eye[i]),fov:c.verticalFovDegrees}),source:'docs/lookloop/west-highland-capture-contract.json',mismatches:[],note:'Eye-target contract; no 45° annotation.'});
await writeFile(resolve(root,'docs/review/holdout-camera-audit.json'),JSON.stringify({schemaVersion:1,rows},null,2)+'\n');
console.log(rows.length+' camera records; '+rows.filter(r=>r.mismatches.length).length+' mismatched records');
