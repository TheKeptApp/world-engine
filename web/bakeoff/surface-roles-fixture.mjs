// Small self-contained companion fixture: same material colour, distinct roof/door roles.
import {sha256} from './surface-roles.js';
export async function surfaceFixture({tags={},word=0x0801,mixed=false}={}){
 const enc=x=>new TextEncoder().encode(JSON.stringify(x));
 const bin=new Uint8Array(36),dv=new DataView(bin.buffer);[0,1,2,3,4,5].forEach((n,i)=>dv.setUint32(i*4,n,true));
 if(mixed)dv.setUint16(24,1,true);
 const g={asset:{version:'2.0'},buffers:[{byteLength:36}],bufferViews:[{buffer:0,byteOffset:0,byteLength:24},{buffer:0,byteOffset:24,byteLength:12}],accessors:[{bufferView:0,componentType:5125,count:6,type:'SCALAR'},{bufferView:1,componentType:5123,count:6,type:'SCALAR'}],meshes:[{primitives:[{indices:0,attributes:{_FEATURE:1},material:0,mode:4}]}],materials:[{pbrMetallicRoughness:{baseColorFactor:[.5,.5,.5,1]}}]};
 const j=enc(g),n=Math.ceil(j.length/4)*4,data=new Uint8Array(28+n+bin.length),v=new DataView(data.buffer);v.setUint32(0,0x46546c67,true);v.setUint32(4,2,true);v.setUint32(8,data.length,true);v.setUint32(12,n,true);v.setUint32(16,0x4e4f534a,true);data.fill(32,20,20+n);data.set(j,20);v.setUint32(20+n,bin.length,true);v.setUint32(24+n,0x004e4942,true);data.set(bin,28+n);
 const scene=enc({features:[{index:0,id:'fixture/1',kind:'building',source:tags,generated:{profile:'fixture',role:'block',colors:['#888888','#888888','#888888','#888888'],colorSet:0}}]});
 const files={'chunks/0/lod0.glb':data,'chunks/0/scene.json':scene};
 const manifest={files:{},chunks:[{lods:['chunks/0/lod0.glb'],scene:'chunks/0/scene.json'}]};
 for(const [p,b]of Object.entries(files))manifest.files[p]={sha256:await sha256(b),bytes:b.length};files['world.json']=enc(manifest);
 const payload=new Uint8Array([word&255,word>>8,4,8]); // family-colour roof/door; material unknown
 const index={schema:'worldengine.surface-roles/1',roles:['other','roof','wall','trim','door'],materialClasses:['unknown','brick','stone','wood','metal','concrete','render','glass','asphalt','clay_tile','slate','bituminous_shingle'],provenance:['none','mapped_tag','family_inference'],encoding:{roleBits:[0,2],materialBits:[3,7],materialProvenanceBits:[8,9],colourProvenanceBits:[10,11],reservedBits:[12,15]},packageHash:{path:'world.json',sha256:await sha256(files['world.json'])},payload:{path:'triangles.u16le',bytes:4,sha256:await sha256(payload)},primitives:[{path:'chunks/0/lod0.glb',mesh:0,primitive:0,lod:0,triangleCount:2,byteOffset:0,sha256:await sha256(data)}],featureSources:[{feature:'fixture/1',tags}]};
 return {files,index,payload,enc};
}
