import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {solarPosition,lunarPosition} from './astronomy.mjs';
const load = file => JSON.parse(readFileSync(new URL(file,import.meta.url)));
const circular = (a,b) => Math.abs(((a-b+540)%360)-180);
const angle = (a,e,b,f) => Math.acos(Math.max(-1,Math.min(1,
  Math.sin(e*Math.PI/180)*Math.sin(f*Math.PI/180)+Math.cos(e*Math.PI/180)*Math.cos(f*Math.PI/180)*Math.cos((a-b)*Math.PI/180))))*180/Math.PI;
let maxE=0,maxA=0,maxAngle=0;
for (const f of load('fixtures/solar-reference.json').fixtures) {
  test(`${f.city} ${f.date} ${f.event}: independent USNO reference`,()=>{
    const s = solarPosition(f);
    const e = Math.abs(s.elevationDeg-f.elevationDeg), a=circular(s.azimuthDeg,f.azimuthDeg);
    const delta=angle(s.azimuthDeg,s.elevationDeg,f.azimuthDeg,f.elevationDeg);
    maxE=Math.max(maxE,e);maxA=Math.max(maxA,a);maxAngle=Math.max(maxAngle,delta);
    assert.ok(e<0.05,`elevation ${e}`);assert.ok(a<0.1,`azimuth ${a}`);
    assert.ok(delta<0.05,`direction ${delta}`);
    assert.ok(Math.abs(Math.hypot(...Object.values(s.direction))-1)<1e-12);
  });
}
test('solar maximum reference disagreement',()=>console.log(JSON.stringify({maxElevationDeg:maxE,maxAzimuthDeg:maxA,maxDirectionDeg:maxAngle})));
let moonMax=0,moonPhaseMax=0;
for (const f of load('fixtures/moon-reference.json').fixtures) {
  test(`moon ${f.time} ${f.lat}: pinned independent fixture`,()=>{
    const s=lunarPosition(f), ref=f.moon;
    const delta=angle(s.azimuthDeg,s.elevationDeg,ref.azimuthDeg,ref.altitudeGeometricTopocentricDeg);
    const phase=Math.abs(s.illuminatedFraction-ref.illuminatedFractionTopocentric);
    moonMax=Math.max(moonMax,delta);moonPhaseMax=Math.max(moonPhaseMax,phase);
    assert.ok(delta<1,`moon direction ${delta}`);assert.ok(phase<0.03,`phase ${phase}`);
    if(Math.abs(ref.altitudeGeometricTopocentricDeg)>1) assert.equal(s.aboveHorizon,ref.aboveGeometricHorizon);
  });
}
test('moon maximum reference disagreement',()=>console.log(JSON.stringify({moonMaxDirectionDeg:moonMax,moonMaxIllumination:moonPhaseMax})));
test('offset equivalence, negative epoch, poles and dateline',()=>{
  assert.deepEqual(solarPosition({lat:40,lon:-105,time:'2026-06-21T12:00:00-07:00'}),solarPosition({lat:40,lon:-105,time:'2026-06-21T19:00:00Z'}));
  for(const lat of [-90,0,90]) for(const lon of [-180,180]) {
    const s=solarPosition({lat,lon,time:'1960-01-01T00:00:00Z'});
    assert.ok(Number.isFinite(s.elevationDeg));assert.ok(s.azimuthDeg>=0&&s.azimuthDeg<360);
  }
  assert.ok(solarPosition({lat:85,lon:0,time:'2026-06-21T00:00:00Z'}).elevationDeg>0);
  assert.ok(solarPosition({lat:85,lon:0,time:'2026-12-21T12:00:00Z'}).elevationDeg<0);
});
test('reject invalid coordinates and ambiguous dates',()=>{
  for(const lat of [NaN,Infinity,91,'40']) assert.throws(()=>solarPosition({lat,lon:0,time:0}));
  for(const time of [null,'2026-01-01','2026-01-01T00:00:00',NaN,'bad']) assert.throws(()=>solarPosition({lat:0,lon:0,time}));
});
