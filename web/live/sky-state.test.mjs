import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {createSkyState,phaseOfDay} from './sky-state.mjs';
const now=Date.parse('2026-06-21T19:00:00Z');
const sky=createSkyState({clock:()=>now});
const input={lat:39.7494,lon:-105.0445,time:now,region:'front-range',weatherState:'clear'};
test('approved phase boundaries and twilight are unambiguous',()=>{
 for(const [e,phase,twilight,fullNight] of [[6.001,'day',false,false],[6,'goldenHour',false,false],[-4,'goldenHour',false,false],[-4.001,'blueHour',false,false],[-6,'blueHour',false,false],[-6.001,'night',true,false],[-11.999,'night',true,false],[-12,'night',false,true],[-90,'night',false,true]]) assert.deepEqual(phaseOfDay(e),{phase,twilight,fullNight});
 for(const e of [NaN,Infinity,91]) assert.throws(()=>phaseOfDay(e));
});
test('public interface stays demo for every minute of slider day',()=>{
 const phases=new Set();
 for(let minute=0;minute<1440;minute++) {
  const s=sky({...input,time:Date.parse('2026-06-21T06:00:00Z')+minute*60000});
  phases.add(s.phase);assert.equal(s.label,'demo');assert.equal(s.visibility.estimated,true);
  assert.ok(s.extinctionPerM>0);assert.ok(s.airlight.linearRGB.every(Number.isFinite));
  assert.equal(s.directSunAboveHorizon,s.sun.elevationDeg>0);
 }
 assert.equal(phases.size,4);
});
test('shadow geometry: noon points south, shadow north, unit source direction',()=>{
 const s=sky(input);assert.ok(Math.abs(s.sun.azimuthDeg-180)<2);
 assert.ok(s.sun.direction.z>0);assert.ok(s.sun.direction.y>0);
 const height=1, length=height*Math.hypot(s.sun.direction.x,s.sun.direction.z)/s.sun.direction.y;
 assert.ok(Math.abs(length-height/Math.tan(s.sun.elevationDeg*Math.PI/180))<1e-12);
 assert.deepEqual(s.sun,sky({...input,region:'great-lakes',weatherState:'rain'}).sun);
});
test('integration cannot call stale, missing, forecast or fixture weather live',()=>{
 const meta={kind:'observation',source:'test-fixture',observedAt:now,representative:true};
 const live={...input,weatherState:{...meta,states:['clear']},observedVisibility:{...meta,value:20,unit:'km',convention:'MOR_5_PERCENT'}};
 assert.equal(sky(live).label,'live');
 for(const age of [60,180,200]) {
  const s=sky({...live,observedVisibility:{...live.observedVisibility,observedAt:now-age*60000}});
  assert.equal(s.label,'stale');assert.equal(s.visibility.observationAgeMinutes,age);
 }
 for(const kind of ['forecast','history','demo']) assert.notEqual(sky({...live,weatherState:{...live.weatherState,kind}}).label,'live');
 assert.notEqual(sky({...live,observedVisibility:undefined}).label,'live');
 assert.notEqual(sky({...live,weatherState:{...live.weatherState,observedAt:undefined}}).label,'live');
});
test('standalone demo executes actual bundled script and slider handlers without network',()=>{
 const html=readFileSync(new URL('index.html',import.meta.url),'utf8');
 assert.match(html,/connect-src 'none'/);assert.doesNotMatch(html,/<script[^>]+src=/);
 const script=html.match(/<script type="module">([\s\S]*?)<\/script>/)[1];
 const nodes=Object.fromEntries(['minute','weather','clock','summary','swatch','state'].map(id=>[id,{value:id==='minute'?'720':'clear',style:{},handlers:{},addEventListener(event,fn){this.handlers[event]=fn;}}]));
 vm.runInNewContext(script,{document:{getElementById:id=>nodes[id]},Date});
 for(const value of ['0','360','720','1200','1439']){
  nodes.minute.value=value;nodes.minute.handlers.input();
  assert.equal(JSON.parse(nodes.state.textContent).label,'demo');assert.match(nodes.clock.textContent,/MDT$/);
 }
 nodes.weather.value='rain';nodes.weather.handlers.change();
 assert.equal(JSON.parse(nodes.state.textContent).visibility.state,'rain');
});
