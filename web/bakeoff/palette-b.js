// R's scoped palette-B trial: docs/execution/palette-diagnosis.md §4.
// Semantic selectors only. These are trial hypotheses, not approved pack replacements.
import * as T from 'three/webgpu';
import {texture,vec2,mix,clamp,select} from 'three/tsl';
export const TABLE={
 source:'0d6a222:docs/execution/palette-diagnosis.md §4; R tableA authorization',
 colourSpace:'sRGB',
 slots:{lawnA:'#5F6C53',lawnB:'#748066',tufts:'#727A5B',road:'#5D6468',sidewalk:'#ABA99E',curb:'#AAA89E',bark:'#6C6151'},
 species:{
  acer_platanoides:{summer:'#46603D',peak_colour:'#A16E42'},
  tilia_cordata:{summer:'#46603D',peak_colour:'#A49650'},
  ulmus_americana:{summer:'#46603D',peak_colour:'#9A9150'},
  populus_tremuloides:{summer:'#445D48',peak_colour:'#AC974B'},
  populus_deltoides:{summer:'#445D48',peak_colour:'#A28F49'},
  picea_pungens:{summer:'#526A70'}
 },
 bark:{general:'#6C6151',preserveSpecies:['populus_tremuloides']},
 water:{deep:'#4C707A',shallow:'#637F74',valueSemantic:'displayAppearance; existing inverse-grade then neutral irradiance compensation'}
};
export function paletteBMode(value){if(value==null||value==='off')return 'off';if(['lot','tableA'].includes(value))return value;throw Error('Invalid paletteB: '+value);}
export function namedSlot(palettes,name){
 const matches=palettes.slots.filter(s=>s.names?.includes(name));
 if(matches.length!==1)throw Error('paletteB requires one exported named slot: '+name);
 return matches[0].slot;
}
// A named slot is an assignment, not a search for equal RGB values.
export function applySlots(world,values){
 for(const [name,hex]of Object.entries(values)){
  const slot=namedSlot(world.palettes,name),c=new T.Color(hex);
  world.paletteTexture.image.data.set([c.r,c.g,c.b,1],slot*4);
 }
 world.paletteTexture.needsUpdate=true;
}
export async function preparePaletteB(mode,{look,foliage,p2,lake,config={}}){
 mode=paletteBMode(mode);if(mode==='off')return null;
 const bytes=new TextEncoder().encode(JSON.stringify(TABLE));
 const tableHash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(n=>n.toString(16).padStart(2,'0')).join('');
 const report={mode,tableHash,source:TABLE.source,colourSpace:TABLE.colourSpace,resolved:[],deferred:['roof','wall','plaster','mapped colour guard'],lawnRule:'Paint.Flags.lawn=4: mix exported lawnA/lawnB in linear light by clamp(extra.y,0,1), multiplied by paint.y (native WorldShaders.metal)',transfer:'one sRGB decode at input; unchanged main.js grade and one explicit sRGB output encode'};
 const record=(selector,from,to,semantic='albedo')=>report.resolved.push({selector,from,to,valueSemantic:semantic});
 if(mode==='tableA'){
  // These calibration keys only feed the already-named ground overrides.
  for(const [key,name]of Object.entries({asphalt:'road',concrete:'sidewalk',curb:'curb'})){
   record('look.materials.groundBaseHex.'+key,look.materials.groundBaseHex[key],TABLE.slots[name]);
   look.materials.groundBaseHex[key]=TABLE.slots[name];
  }
  for(const species of foliage.species){
   const endpoints=TABLE.species[species.id];
   if(endpoints)for(const [season,hex]of Object.entries(endpoints)){
    record('foliage.species[id='+species.id+'].seasonColours.'+season,species.seasonColours[season],hex);species.seasonColours[season]=hex;
   }
   if(!TABLE.bark.preserveSpecies.includes(species.id)){
    record('foliage.species[id='+species.id+'].bark',species.bark??'P2 vegetation branches fallback',TABLE.bark.general);species.bark=TABLE.bark.general;
   }
  }
  // applySpecies uses vegetation peak endpoints after the foliage pack. Preserve
  // that precedence, all phenology weights and the region's green-retention prior.
  for(const [key,family]of Object.entries(p2.vegetation)){
   const peak=TABLE.species[family.packSpecies]?.peak_colour;
   if(peak){record('p2.vegetation.'+key+'.colours[2]',family.colours[2],peak);family.colours[2]=peak;}
   if(!TABLE.bark.preserveSpecies.includes(family.packSpecies)){
    record('p2.vegetation.'+key+'.branches',family.branches,TABLE.bark.general);family.branches=TABLE.bark.general;
   }
  }
  for(const [key,profile]of Object.entries(lake.water.profiles).filter(([key])=>key===config.waterProfile)){
   record('lake.water.profiles.'+key+'.shallowColourHex',profile.shallowColourHex,TABLE.water.shallow,'displayAppearance');profile.shallowColourHex=TABLE.water.shallow;
  }
  for(const state of lake.states)if(state.id===config.waterState&&state.surfaceValues?.[0]?.baseColourHex){
   record('lake.states[id='+state.id+'].surfaceValues[0].baseColourHex',state.surfaceValues[0].baseColourHex,TABLE.water.deep,'displayAppearance');state.surfaceValues[0].baseColourHex=TABLE.water.deep;
  }
 }
 let lawnSlots;
 return {report,applyPalette(world){
  lawnSlots=['lawnA','lawnB'].map(name=>namedSlot(world.palettes,name));
  if(mode==='tableA'){
   for(const [name,hex]of Object.entries(TABLE.slots)){
    const slot=namedSlot(world.palettes,name);
    record('palettes.slots[names contains '+name+']; slot='+slot,Array.from(world.paletteTexture.image.data.slice(slot*4,slot*4+3)),hex);
   }
   applySlots(world,TABLE.slots);
  }
  report.lawnEndpoints=Object.fromEntries(['lawnA','lawnB'].map((name,i)=>[name,{slot:lawnSlots[i],linearRGB:Array.from(world.paletteTexture.image.data.slice(lawnSlots[i]*4,lawnSlots[i]*4+3)),provenance:mode==='lot'?'export palettes.seasonalSlots.'+name:'TABLE.slots.'+name}]));
 },lawnNode(palette,tone,shade,original,flag){
  if(!lawnSlots)throw Error('paletteB lawn endpoints unresolved');
  const [a,b]=lawnSlots.map(slot=>texture(palette,vec2((slot+.5)/256,.5)).rgb);
  return select(flag,mix(a,b,clamp(tone,0,1)).mul(shade),original);
 }};
}
