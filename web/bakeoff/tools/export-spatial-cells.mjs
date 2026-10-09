#!/usr/bin/env node
// Opt-in post-export stage. No shipping exporter/schema changes; no simplification.
import {registerHooks} from 'node:module';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
registerHooks({resolve(s,c,next){if(s==='three')s=pathToFileURL(root+'/web/node_modules/three/build/three.module.js').href;else if(s.startsWith('three/'))s=pathToFileURL(root+'/web/node_modules/three/'+(s==='three/webgpu'?'build/three.webgpu.js':s.replace('three/addons/','examples/jsm/'))).href;return next(s,c);}});
globalThis.ProgressEvent=class{constructor(t,p){Object.assign(this,{type:t},p);}};
const {GLTFLoader}=await import('three/addons/loaders/GLTFLoader.js'),{geometryFingerprint,describeRows,SCHEMA}=await import('../spatial-cells.js');
const folder=resolve(process.argv[2]??'');if(!process.argv[2])throw Error('Usage: node export-spatial-cells.mjs existing-package-directory');
const worldBytes=await readFile(resolve(folder,'world.json')),world=JSON.parse(worldBytes),sha=b=>createHash('sha256').update(b).digest('hex');
const result={schema:SCHEMA,sourceWorldSha256:sha(worldBytes),leafMetres:100,pageMetres:200,groupMetres:[400,800],origin:[0,0],geometryErrorMetres:0,geometries:{},files:{},pages:{},instances:world.instances,prototypes:world.prototypes,boundary:world.boundary};
for(const name of [...world.chunks.map(c=>c.lods[0]),world.boundary]){
 const bytes=await readFile(resolve(folder,name));result.files[name]=sha(bytes);
 const gltf=await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset,bytes.byteOffset+bytes.byteLength),'');gltf.scene.updateMatrixWorld(true);
 gltf.scene.traverse(o=>{if(!o.isMesh)return;const key=geometryFingerprint(o.geometry),rows=describeRows(o,o.geometry.attributes._feature);
  if(result.geometries[key]&&JSON.stringify(result.geometries[key].map(r=>[r.indices,r.bounds]))!==JSON.stringify(rows.map(r=>[r.indices,r.bounds])))throw Error('Fingerprint collision or inconsistent feature provenance: '+key);
  result.geometries[key]=rows;
  for(const row of rows){const p=row.page.join(',');(result.pages[p]??=[]).push({file:name,geometry:key,leaf:row.leaf,groups:row.groups,triangles:row.indices.length/3});}
 });
}
const instances=JSON.parse(await readFile(resolve(folder,world.instances)));result.instancePages={};for(const instance of instances.instances){const [x,,z]=instance.position,page=`${Math.floor(x/200)},${Math.floor(z/200)}`;(result.instancePages[page]??=[]).push({id:instance.id,kind:instance.kind,variant:instance.variant,leaf:[Math.floor(x/100),Math.floor(z/100)],groups:[400,800].map(s=>[Math.floor(x/s),Math.floor(z/s)]),sourcePosition:instance.position});}
await writeFile(resolve(folder,'spatial-cells.json'),JSON.stringify(result)+'\n');console.log(JSON.stringify({package:folder,geometries:Object.keys(result.geometries).length,pages:Object.keys(result.pages).length,sidecarBytes:Buffer.byteLength(JSON.stringify(result))}));
