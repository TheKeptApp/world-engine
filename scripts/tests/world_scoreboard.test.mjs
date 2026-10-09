import test from 'node:test';
import assert from 'node:assert/strict';
import {parseStats,typeTag,tierChecks,featureChecks,sourceRoads,compareRuns,passTotals} from '../world_scoreboard_checks.mjs';
import {segmentInViewport} from '../world_scoreboard_probes.mjs';
import {LocalFrame} from '../../web/src/geo.js';
test('source inventory is independent and rejects absent sections',()=>{
 const s=parseStats('| Buildings (excluding parts) | 100 |\n## Areas\n\n| park | 1 | 20000 m² |\n| water | 2 | 40000 m² |\n## Next\n');
 assert.equal(s.buildings,100);assert.equal(s.areas.water.features,2);assert.throws(()=>parseStats(''),/Buildings/);
});
test('floor strict boundary and provisional standard boundary',()=>{
 const s={triangles:150000,draws:20};assert.equal(tierChecks({triangles:400000,draws:100},s).floor.pass,false);
 assert.equal(tierChecks({triangles:399999,draws:100},s).floor.pass,true);
 assert.equal(tierChecks({triangles:500000,draws:120},{triangles:180000,draws:400}).standard.pass,true);
 assert.equal(tierChecks({triangles:500001,draws:120},s).standard.pass,false);
});
test('source change changes water detection; building +/-2% is inclusive',()=>{
 const features=Array.from({length:98},(_,i)=>({id:'way/'+i,kind:'building',lod0:{static:[[0,3]],water:[]}}));
 assert.equal(featureChecks({buildings:100,areas:{}},features,new Set()).buildings.pass,true);
 assert.equal(featureChecks({buildings:101,areas:{}},features,new Set()).buildings.pass,false);
 assert.equal(featureChecks({buildings:100,areas:{water:{features:1}}},features,new Set()).water.pass,false);
 assert.equal(featureChecks({buildings:100,areas:{}},features,new Set()).water.pass,true);
});
test('split chunk features are deduplicated, zero vertex ranges are absent',()=>{
 const f={id:'way/1',kind:'park',lod0:{static:[[0,3]],water:[]}};
 assert.equal(featureChecks({buildings:0,areas:{park:{features:1}}},[f,f],new Set()).park.exportedUnique,1);
 assert.equal(featureChecks({buildings:0,areas:{park:{features:1}}},[{...f,lod0:{static:[[0,0]],water:[]}}],new Set()).park.pass,false);
});
test('type selection is source-driven with fixed precedence',()=>{
 assert.equal(typeTag({buildings:2000,areas:{water:{squareMetres:100000}}},1e6,1),'park/water');
 assert.equal(typeTag({buildings:2000,areas:{}},1e6,.8),'dense grid');
 assert.equal(typeTag({buildings:2000,areas:{}},1e6,.2),'mixed');
 assert.equal(typeTag({buildings:200,areas:{}},1e6,1),'suburban');
});
test('ground-level building passages are distinct; negative layers still screen underground',()=>{
 const elements=[{type:'way',id:1,tags:{highway:'primary',tunnel:'yes'}},{type:'way',id:2,tags:{highway:'primary',tunnel:'no'}},{type:'way',id:3,tags:{highway:'footway',tunnel:'building_passage'}},{type:'way',id:4,tags:{highway:'footway',tunnel:'building_passage',layer:'-1'}},{type:'way',id:5,tags:{highway:'service',tunnel:'building_passage'}}];
 const r=sourceRoads(elements,new LocalFrame(40,-105));assert.deepEqual([...r.tunnelIDs],['way/1','way/4','way/5']);assert.deepEqual([...r.groundPassageIDs],['way/3']);
});
test('pass submissions keep main, shadow and post distinct',()=>{
 const t=passTotals({'main/world':{triangles:10,draws:2},'shadow/world':{triangles:20,draws:3},'post/blend':{triangles:1,draws:1}});assert.equal(t.main.triangles,10);assert.equal(t.shadow.triangles,20);assert.throws(()=>passTotals({'main/world':{triangles:NaN,draws:1}}));
});
test('near-plane intersection must cross the viewport, not merely its bounding box',()=>{
 assert.equal(segmentInViewport([-2,0],[2,0]),true);assert.equal(segmentInViewport([2,2],[3,3]),false);assert.equal(segmentInViewport([-2,2],[2,2]),false);assert.equal(segmentInViewport([0,-2],[0,2]),true);
});
test('JSON diff handles first run, metrics, changed contract and removed blocks',()=>{
 const row={key:'a/40',comparisonInputs:{sourceHash:'same'},metrics:{mainTriangles:10},failures:[]};
 assert.equal(compareRuns({rows:[row]},null).status,'first-run');
 assert.equal(compareRuns({rows:[row]},{rows:[row]}).changes.length,0);
 const changed={...row,metrics:{mainTriangles:20},failures:['budget']};assert.equal(compareRuns({rows:[changed]},{rows:[row]}).changes[0].metrics.mainTriangles.delta,10);
 assert.equal(compareRuns({rows:[{...changed,comparisonInputs:{sourceHash:'new'}}]},{rows:[row]}).changes[0].comparable,false);
 assert.deepEqual(compareRuns({rows:[]},{rows:[row]}).removed,['a/40']);
});
