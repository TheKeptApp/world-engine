// R's Ground/Materials trial. No new palette, spatial noise, topology or lighting.
import {texture,vec2,mix,clamp,select} from 'three/tsl';
import {namedSlot} from './palette-b.js';
export function groundTrialMode(value){if(value==null||value==='off')return 'off';if(value==='on')return value;throw Error('Invalid groundTrial: '+value);}
export async function prepareGroundTrial(world){
 if(!world.surfaceRoles)throw Error('groundTrial requires the validated A4 surface companion');
 const slots=['lawnA','lawnB'].map(name=>namedSlot(world.palettes,name));
 const report={mode:'on',rule:'Preserve exported semantic surface distinctions: lawn tone/shade and roof/wall/trim colour assignments',lawnSource:'Sources/WorldGen/Yards/YardGeneration.swift: building.ref.random("yard"), tone, lawnShade, lotSeed; GroundDetail.swift: worn/contact field; WorldShaders.metal lawn mix',surfaceRoles:world.surfaceRoles.report,lawnEndpoints:slots.map(slot=>({slot,linearRGB:Array.from(world.paletteTexture.image.data.slice(slot*4,slot*4+3))})),restoredTriangles:[0,0,0,0,0],mappedTriangles:0,addedTriangles:0,addedDraws:0};
 // Stage all validation before mutating any attributes. A geometry hash binds the
 // runtime mesh to the exact validated GLB primitive, never a name/slot/hex guess.
 const edits=[],restoredSlots=new Map();
 for(const [ci,chunk]of world.manifest.chunks.entries()){
  const meshes=[];world.root.children[ci].traverse(o=>{if(o.isMesh&&o.material===world.materials.static)meshes.push(o);});
  for(const mesh of meshes){
   const g=mesh.geometry,p=g.attributes.position,idx=g.index?.array,face=g.attributes._facade;
   if(!idx||!face)throw Error('groundTrial requires indexed static geometry and legacy facade attribute');
   const positions=Float32Array.from({length:p.count*3},(_,i)=>p.getComponent(Math.floor(i/3),i%3));
   const binding=await world.surfaceRoles.matchGeometry(chunk.lods[0],positions,idx);
   const values=new Map();
   for(let t=0;t<binding.triangleCount;t++){
    const word=world.surfaceRoles.word(chunk.lods[0],binding.mesh,binding.primitive,t),role=word&7,cp=word>>10&3;
    // Mapped/unknown provenance stays byte-identical; door is not part of this trial.
    const restore=role>=1&&role<=3&&cp===2;
    if(restore){
     report.restoredTriangles[role]++;
     const slot=Math.round(g.attributes._paint.getX(idx[t*3]));
     restoredSlots.set(slot,{slot,linearRGB:Array.from(world.paletteTexture.image.data.slice(slot*4,slot*4+3)),source:'export palette assignment; family colour provenance'});
    }
    if(cp===1)report.mappedTriangles++;
    for(let k=0;k<3;k++){
     const v=idx[t*3+k],prior=values.get(v);
     if(prior!==undefined&&prior!==restore)throw Error('groundTrial rejects a shared vertex crossing semantic role boundaries');
     values.set(v,restore);
    }
   }
   edits.push({face,values});
  }
 }
 for(const {face,values}of edits){for(const [v,restore]of values)if(restore)face.setXYZW(v,0,0,0,0);face.needsUpdate=true;}
 report.restoredSlots=[...restoredSlots.values()].sort((a,b)=>a.slot-b.slot);
 return {report,lawnNode(palette,tone,shade,original,flag){
  const [a,b]=slots.map(slot=>texture(palette,vec2((slot+.5)/256,.5)).rgb);
  return select(flag,mix(a,b,clamp(tone,0,1)).mul(shade),original);
 }};
}
