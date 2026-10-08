import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {phenology} from './phenology.js';
const data=JSON.parse(await readFile(new URL('./data/p2-crowns.json',import.meta.url)));
for(const region of ['denver','chicago']){
 for(const date of ['2026-01-15','2026-04-25','2026-07-15','2026-10-08','2026-12-15']){
  const p=phenology(date,region,data);assert.ok(Math.abs(p.weights.reduce((a,b)=>a+b)-1)<1e-12);assert.ok(p.leafFraction>=0&&p.leafFraction<=1);
 }
 assert.equal(phenology('2026-01-15',region,data).leafFraction,0);
 assert.equal(phenology('2026-07-15',region,data).weights[1],1);
 assert.ok(phenology('2026-10-08',region,data).colourProgress>0);
}
assert.notDeepEqual(phenology('2026-10-08','denver',data),phenology('2026-10-08','chicago',data));
for(const shape of Object.values(data.shapes)){assert.equal(shape.lobes.length,10);assert.equal(shape.midCount,5);assert.ok(shape.trunkRadius<shape.trunkTop);}
console.log('PASS: date-derived seasonal continuity, regional prior, winter leaf loss, P2 shape data');

const {witnessLight}=await import('./lighting.js');
for(const elevation of [15,40,75]){const p=witnessLight({sun:{hex:'#FFE8C6',directRelative:1,elevationDeg:elevation},sky:{fillHex:'#AEBCCA'},shadow:{neutralWitnessShadowToLitLinearY:.62}});assert.ok(Math.abs(p.witness.ratio-.62)<1e-12);}
console.log('PASS: linear-Y neutral witness ratio across sun elevations');

const {facadeFamily,wallColour,detailTier}=await import('./facade-policy.js');
const pack=JSON.parse(await readFile(new URL('./data/facade-values.json',import.meta.url)));
const f=facadeFamily('chicago',{family:'brickStackedFacade'},pack);
assert.equal(wallColour(f,{},pack,()=>0),f.wall,'Unknown era is not invented');
assert.equal(wallColour(f,{'building:colour':'#123456'},pack,()=>0),'#123456');
assert.equal(facadeFamily('chicago',{family:'unknown'},pack),null);
assert.equal(detailTier(10,10,780,47,pack.lod),'near');
assert.equal(detailTier(10,10000,780,47,pack.lod),'far');
console.log('PASS: family/era provenance, mapped colour priority, distance tiers');
