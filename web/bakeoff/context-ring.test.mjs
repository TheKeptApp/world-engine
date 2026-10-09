import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {ringStrips,clippedTriangles} from './context-ring.js';
const core=[-1,-1,1,1],cov=[-3,-3,3,3];
const mesh={position:[-4,0,-4,4,0,-4,0,0,4],paint:[0,1,0,0,0,1,0,0,0,1,0,0],index:[0,1,2]};
test('clipped geometry cannot span detailed core or leave source coverage',()=>{
 const triangles=clippedTriangles(mesh,core,cov);assert.ok(triangles.length>0);
 for(const {points} of triangles){for(const p of points)assert.ok(p[0]>=-3&&p[0]<=3&&p[2]>=-3&&p[2]<=3);
 assert.ok(ringStrips(core,cov).some(r=>points.every(p=>p[0]>=r[0]-1e-8&&p[0]<=r[2]+1e-8&&p[2]>=r[1]-1e-8&&p[2]<=r[3]+1e-8)));}
});
test('all-core triangle produces no context; four exact ring strips',()=>{
 const m={...mesh,position:[-.5,0,-.5,.5,0,-.5,0,0,.5]};assert.equal(clippedTriangles(m,core,cov).length,0);assert.equal(ringStrips(core,cov).length,4);
});
test('default path remains opt-in, no shadows or context scene-budget pooling',()=>{
 const read=p=>readFileSync(new URL(p,import.meta.url),'utf8');
 assert.match(read('./entry.js'),/get\('contextRing'\)==='1'/);
 assert.match(read('./context-ring.js'),/mesh.castShadow=false/);
 assert.match(read('./scene-budget.js'),/!o.userData.contextRing/);
 const exporter=read('./tools/export-context.swift');assert.match(exporter,/transitionWidth = -1/);assert.match(exporter,/tallHeight = Double.greatestFiniteMagnitude/);assert.match(exporter,/tallFootprint = Double.greatestFiniteMagnitude/);
});

test('sceneBudget leaves separately counted context on the main layer',async()=>{
 const T=await import('three/webgpu'),{installSceneBudget}=await import('./scene-budget.js');
 const scene=new T.Scene(),camera=new T.PerspectiveCamera(50,1,.1,100);camera.position.z=10;camera.lookAt(0,0,0);camera.updateMatrixWorld();
 const mesh=new T.Mesh(new T.PlaneGeometry(1,1),new T.MeshBasicMaterial());mesh.userData.contextRing=true;scene.add(mesh);
 const v=installSceneBudget(scene,camera);v.update();assert.equal(v.report.mainSourceMeshes,0);assert.equal(mesh.layers.mask,1);
});

test('missing data is an explicit zero-cost no-op, not invented land',async()=>{
 const {installContextRing}=await import('./context-ring.js');
 const v=installContextRing({}, {status:'missing-context-source',area:'synthetic'});
 assert.equal(v.report.status,'missing-context-source');assert.deepEqual(v.meshes,[]);assert.equal(v.report.uploadedTriangles,0);assert.equal(v.report.addedShadowDraws,0);
});

test('clipping preserves mapped area and holes represented by triangulation',()=>{
 const quad={position:[-3,0,-3,3,0,-3,3,0,3,-3,0,3],paint:Array(4).fill([0,1,0,0]).flat(),index:[0,1,2,0,2,3]};
 const tris=clippedTriangles(quad,core,cov);
 const area=tris.reduce((sum,{points:[a,b,c]})=>sum+Math.abs((b[0]-a[0])*(c[2]-a[2])-(b[2]-a[2])*(c[0]-a[0]))/2,0);
 assert.ok(Math.abs(area-32)<1e-7); // 36 m² mapped quad minus 4 m² detailed core; no duplicate strips.
});
