import {createHash} from 'node:crypto';
import {readFile,readdir} from 'node:fs/promises';
import {resolve,relative} from 'node:path';
const here=resolve('web/bakeoff'),root=resolve('.'),assets=resolve(process.env.WORLDENGINE_ASSETS||root);
async function files(directory){const result=[];for(const e of await readdir(directory,{withFileTypes:true})){const p=resolve(directory,e.name);if(e.isDirectory())result.push(...await files(p));else if(e.isFile())result.push(p);}return result.sort();}
export async function freezeInputs(){
 const selected=(await readdir(here)).filter(n=>/\.(js|mjs|html|css|json|py|sh)$/.test(n)).map(n=>resolve(here,n));
 selected.push(...await files(resolve(root,'web/src')),...await files(resolve(here,'data')));
 const packs=['style-b-calibration-v2/values.json','foliage-seasons-v1/foliage-values.json','lake-winter-v1/lake-winter-values.json','water-surfaces-v1/water-values.json','mountain-terrain-v1/values.json','weather-moments-v1/values.json'];
 selected.push(...packs.map(p=>resolve(assets,'docs/proposals',p)));
 selected.push(resolve(root,'docs/proposals/haze-visibility-v1/values.json'));
 selected.push(resolve(root,'Tools/lookloop/mock-corrections.json'),resolve(root,'Tools/lookloop/calibration-regions.json'),resolve(root,'Tools/lookloop/region_colours.py'),resolve(root,'Tools/lookloop/conformance.py'),...['01-lakeview','06-sloans'].map(n=>resolve(assets,'docs/proposals/style-b-calibration-v2/frames',n+'.png')));
 selected.push(...await files(resolve(here,'generated/lakeview-sheil-park')),...await files(resolve(assets,'Generated/package/sloans-lake')));
 const hashes={};for(const p of selected.sort())hashes[relative(p.startsWith(here)?here:assets,p)]=createHash('sha256').update(await readFile(p)).digest('hex');
 return {sha256:createHash('sha256').update(JSON.stringify(hashes)).digest('hex'),files:hashes};
}
