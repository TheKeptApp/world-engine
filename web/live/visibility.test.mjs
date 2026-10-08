import test from 'node:test';
import assert from 'node:assert/strict';
import {visibilityState,localSeason,airlightColour} from './visibility.mjs';
import pack from './pack-data.mjs';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const now=Date.parse('2026-06-21T19:00:00Z');
const observation=(age=0,extras={})=>({kind:'observation',source:'synthetic test adapter',observedAt:now-age*60000,representative:true,value:25,unit:'km',convention:'MOR_5_PERCENT',...extras});
const base={lat:39.7392,lon:-104.9903,time:now,region:'front-range',weatherState:{...observation(),states:['clear']}};
const state=(extras={})=>visibilityState({...base,...extras},now);
test('generated data matches approved source hash and every selected field',()=>{
 const bytes=readFileSync(new URL('../../docs/proposals/haze-visibility-v1/values.json',import.meta.url));
 assert.equal(pack.sha256,createHash('sha256').update(bytes).digest('hex'));
 const source=JSON.parse(bytes);for(const key of ['regions','states','definition','selection','airlight','severityOverrides']) assert.deepEqual(pack[key],source[key]);
});
test('all region/season/state fallback values are pack exact',()=>{
 for(const r of pack.regions) for(const [season,month] of [['winter',1],['spring',4],['summer',7],['autumn',10]]) for(const s of Object.keys(pack.states)){
  const result=state({region:r.id,time:`2026-${String(month).padStart(2,'0')}-15T12:00:00Z`,weatherState:s});
  assert.equal(result.season,season);assert.equal(result.extinctionPerM,r.seasons[season][s].extinctionPerM);assert.equal(result.label,'demo');
 }
});
test('southern seasons reverse; solar local date crosses month boundary',()=>{
 assert.equal(localSeason({lat:-34,lon:151,time:'2026-01-15T00:00:00Z'}),'summer');
 assert.equal(localSeason({lat:-34,lon:151,time:'2026-07-15T00:00:00Z'}),'winter');
 assert.equal(localSeason({lat:40,lon:-105,time:'2026-03-01T00:01:00Z'}),'winter');
 assert.equal(localSeason({lat:40,lon:105,time:'2026-02-28T23:59:00Z'}),'spring');
});
test('fresh exact observation replaces total; 5% MOR, units, no double-counting',()=>{
 for(const [value,unit] of [[10,'km'],[10000,'m'],[10/1.609344,'SM']]){
  const r=state({weatherState:{...base.weatherState,states:['rain','hazy']},observedVisibility:observation(0,{value,unit})});
  assert.ok(Math.abs(r.extinctionPerM-pack.definition.constant/10000)<1e-12);assert.equal(r.label,'live');assert.equal(r.estimated,false);
 }
});
test('60 minute soft and 180 minute hard boundaries',()=>{
 for(const [age,label,expired] of [[59.999,'live',false],[60,'stale',false],[179.999,'stale',false],[180,'stale',true],[181,'stale',true]]){
  const r=state({observedVisibility:observation(age)});assert.equal(r.label,label);assert.equal(r.hardExpired,expired);
  assert.equal(r.basis,expired?'estimated-region-state':'observed-total');assert.equal(r.observationAgeMinutes,age);
 }
});
test('fixtures, replay, future and missing metadata never masquerade as live',()=>{
 for(const obs of [undefined,observation(0,{kind:'demo'}),observation(0,{kind:'forecast'}),observation(0,{kind:'history'}),observation(-1),observation(0,{observedAt:undefined}),observation(0,{source:''})]) assert.notEqual(state({observedVisibility:obs}).label,'live');
 assert.equal(state({observedVisibility:observation(),weatherState:'clear'}).label,'demo');
 assert.equal(state({observedVisibility:observation(),time:now-86400000}).label,'demo');
 assert.equal(state({observedVisibility:observation(),time:now+1}).label,'demo');
});
test('censored 10SM and 9999 preserve bounds without forcing Denver to the ceiling',()=>{
 for(const [report,bound] of [['10SM',16.09344],['9999',10]]){
  const r=state({observedVisibility:observation(0,{report})});
  assert.equal(r.lowerBoundKm,bound);assert.equal(r.visibilityKm,75);assert.equal(r.estimated,true);assert.equal(r.label,'demo');
 }
 assert.equal(state({observedVisibility:observation(0,{value:10,unit:'SM',reportingSystem:'US_METAR'})}).lowerBoundKm,16.09344);
});
test('censored bounds cannot clear a contradictory severe event',()=>{
 const r=state({weatherState:{...base.weatherState,states:['snow'],severity:'snowSquall'},observedVisibility:observation(0,{report:'10SM'})});
 assert.equal(r.visibilityKm,0.3);assert.equal(r.contradictoryBound,true);assert.equal(r.lowerBoundKm,16.09344);
});
test('expired event remains uncertain and conservative; no seasonal event invention',()=>{
 const r=state({weatherState:{...observation(200),states:['smoke']},observedVisibility:observation(200)});
 assert.equal(r.state,'smoke');assert.equal(r.visibilityKm,5);assert.equal(r.eventUncertain,true);assert.equal(r.label,'stale');
 assert.equal(state({weatherState:'clear',time:'2026-12-21T19:00:00Z'}).state,'clear');
});
test('combined states use maximum extinction, light severity replaces ordinary state',()=>{
 assert.equal(state({weatherState:{states:['rain','snow']}}).visibilityKm,2);
 assert.equal(state({weatherState:{states:['rain'],severity:'lightRain'}}).visibilityKm,12);
 assert.throws(()=>state({weatherState:{states:['clear'],severity:'snowSquall'}}));
});
test('invalid visibility rejected without inventing clear air',()=>{
 for(const value of [null,0,-1,NaN,Infinity,'10']) assert.equal(state({observedVisibility:observation(0,{value})}).basis,'estimated-region-state');
 for(const extras of [{unit:'miles'},{convention:'2_PERCENT'},{representative:false},{report:'CAVOK'}]) assert.equal(state({observedVisibility:observation(0,extras)}).basis,'estimated-region-state');
 assert.equal(state({observedVisibility:observation(0,{value:500})}).visibilityKm,500);
 assert.throws(()=>state({region:'unknown'}));assert.throws(()=>state({weatherState:'toString'}));
});
test('airlight is pack-colour linear blend; night does not change extinction',()=>{
 assert.equal(airlightColour('clear','day').hex,'#BDD0D9');assert.equal(airlightColour('rain','night').hex,'#475568');
 const d=airlightColour('clear','day'),n=airlightColour('clear','night');assert.notDeepEqual(d,n);
 const golden=airlightColour('clear','goldenHour');assert.ok(golden.linearRGB.every(Number.isFinite));
 assert.equal(state({time:'2026-06-21T06:00:00Z'}).extinctionPerM,state().extinctionPerM);
});
