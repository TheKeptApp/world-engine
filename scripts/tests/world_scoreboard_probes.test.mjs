import test from 'node:test';
import assert from 'node:assert/strict';
import * as T from '../../web/node_modules/three/build/three.module.js';
import {probeScene} from '../world_scoreboard_probes.mjs';
import {THRESHOLDS} from '../world_scoreboard_checks.mjs';
function fixture(kind='generated-ground'){
 const root=new T.Group(),core=new T.Group(),material=new T.MeshBasicMaterial();
 const ground=new T.Mesh(new T.PlaneGeometry(10000,10000).rotateX(-Math.PI/2),material);ground.name='core';core.add(ground);root.add(core);
 const boundary=new T.Group(),plane=new T.Mesh(new T.PlaneGeometry(12000,12000).rotateX(-Math.PI/2),material);plane.position.y=-.02;boundary.add(plane);root.add(boundary);
 const camera=new T.PerspectiveCamera(50,1005/565,10,5000);camera.position.set(0,40,0);camera.lookAt(0,0,-40);camera.updateMatrixWorld(true);
 return {b:{T,world:{root,manifest:{chunks:[{}]},materials:{water:{}}},camera,spec:{viewport:{width:1005,height:565}}},metadata:[{features:[{id:'test',kind,lod0:{static:[[0,4]],water:[]}}]}],core,material};
}
test('frame mask distinguishes featureless ground from a mapped park without colour fitting',()=>{
 const f=fixture(),a=probeScene(f.b,f.metadata,THRESHOLDS);assert.equal(a.blankGround.fraction,1);assert.equal(a.blankGround.pass,false);
 f.metadata[0].features[0].kind='park';const b=probeScene(f.b,f.metadata,THRESHOLDS);assert.equal(b.blankGround.fraction,0);assert.equal(b.blankGround.pass,true);
});
test('near-clipped static building fails; moving it in front of near plane clears the failure',()=>{
 const f=fixture('park'),box=new T.Mesh(new T.BoxGeometry(5,5,5),f.material),direction=f.b.camera.getWorldDirection(new T.Vector3());box.name='near building';box.position.copy(f.b.camera.position).addScaledVector(direction,10);f.core.add(box);
 const clipped=probeScene(f.b,f.metadata,THRESHOLDS);assert.equal(clipped.clipping.pass,false);assert.equal(clipped.clipping.potential,true);
 box.position.copy(f.b.camera.position).addScaledVector(direction,30);const clear=probeScene(f.b,f.metadata,THRESHOLDS);assert.equal(clear.clipping.pass,true);assert.equal(clear.clipping.potential,false);
});
test('instance near-plane intersections are warnings when static ground is not lost',()=>{
 const f=fixture('park'),box=new T.InstancedMesh(new T.BoxGeometry(5,5,5),f.material,1),direction=f.b.camera.getWorldDirection(new T.Vector3()),position=f.b.camera.position.clone().addScaledVector(direction,10);box.name='near instance';box.setMatrixAt(0,new T.Matrix4().makeTranslation(...position.toArray()));f.b.world.root.add(box);
 const p=probeScene(f.b,f.metadata,THRESHOLDS);assert.equal(p.clipping.potential,true);assert.equal(p.clipping.pass,true);assert.equal(p.clipping.status,'warning');
});
