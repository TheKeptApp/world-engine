// Capture-only producer: same exporter recipe and version; reject any package drift.
import {readFile,mkdir,mkdtemp,rm} from 'node:fs/promises';
import {resolve} from 'node:path';
import {spawn} from 'node:child_process';
const read=async p=>JSON.parse(await readFile(p,'utf8'));
export async function prepareGroundCompanions(root,contract,selected){
 const demo=await read(resolve(root,'Apps/WorldLab/Resources/demo.json')),seen=new Map(),urls={};
 for(const scene of selected){
  const c=contract.scenes[scene],area=c.area??(c.world.includes('sloans')?'sloans-lake':'lakeview-sheil-park');
  if(!seen.has(area)){
   const spec=contract.exports?.find(x=>x.area===area);
   const existing=resolve(root,spec?'Generated/web-capture/'+area:area==='sloans-lake'?'Generated/package/'+area:'web/bakeoff/generated/'+area);
   const before=await readFile(resolve(existing,'world.json')),world=JSON.parse(before);
   let args;
   if(spec)args=['--date',spec.date,'--focus',spec.focus,'--margin','100'];
   else if(area==='sloans-lake')args=['--date',demo.fixtures.goldenUTC,'--focus',[demo.focus.south,demo.focus.west,demo.focus.north,demo.focus.east].join(','),'--state','golden='+demo.fixtures.goldenUTC,'--state','noon='+demo.fixtures.noonUTC];
   else args=['--date','2026-07-15T20:00:00Z','--season','1','--focus','41.9445,-87.6660,41.9465,-87.6630','--margin','100'];
   const base=resolve(root,'web/bakeoff/generated/ground-companions');await mkdir(base,{recursive:true});
   const temp=await mkdtemp(resolve(base,'build-')),companion=resolve(base,area);
   try{
    await new Promise((ok,no)=>{const p=spawn(resolve(root,'.build/release/worldbake'),['export',resolve(root,'Data/areas',area),temp,...args,'--version',world.generator.version,'--surface-roles-to',companion],{cwd:root,stdio:'inherit'});p.on('error',no);p.on('exit',code=>code===0?ok():no(Error('Companion export failed '+code)));});
    const after=await readFile(resolve(temp,'world.json'));if(!before.equals(after))throw Error('Companion recipe changed package: '+area+'; refusing unbound roles');
   }finally{await rm(temp,{recursive:true,force:true});}
   seen.set(area,'/generated/ground-companions/'+area+'/index.json');
  }
  urls[scene]=seen.get(area);
 }
 return urls;
}
