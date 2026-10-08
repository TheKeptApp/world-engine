import assert from 'node:assert/strict';
import {appearanceToRadiance,radianceToAppearance} from './sky-colour.js';
import {stableRandom} from './stable-random.js';
const e={linearGain:1.2745606273192622,saturation:1.08,contrast:1.06};
for(const hex of ['73A5CC','A2C4DC','DBDCD1','F0F2EF','CAD6DE','7AAFE2','8FBAE7','A0C8F2']){
 const rgb=hex.match(/../g).map(h=>parseInt(h,16)/255).map(x=>x<=.04045?x/12.92:((x+.055)/1.055)**2);
 const recovered=radianceToAppearance(appearanceToRadiance(rgb,e),e);
 assert.ok(Math.max(...rgb.map((v,i)=>Math.abs(v-recovered[i])))<1e-10,hex+' must survive the single post transfer');
}
const a=stableRandom('crown',7),b=stableRandom('crown',7);for(let i=0;i<20;i++)assert.equal(a(),b());
console.log('PASS: sky appearance round-trip and deterministic crown/cloud seeds');
