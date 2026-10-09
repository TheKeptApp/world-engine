// Production optional reader for Sources/WorldPackage/SurfaceCompanion.swift.
// No palette application or guessed semantics. Publish records only after ALL checks.
const materials=['unknown','brick','stone','wood','metal','concrete','render','glass','asphalt','clay_tile','slate','bituminous_shingle'];
const encoding={roleBits:[0,2],materialBits:[3,7],materialProvenanceBits:[8,9],colourProvenanceBits:[10,11],reservedBits:[12,15]};
const check=(ok,message)=>{if(!ok)throw Error('Surface companion rejected: '+message);};
const integer=x=>Number.isSafeInteger(x)&&x>=0;
const bytes=x=>x instanceof Uint8Array?x:new Uint8Array(x);
const json=x=>JSON.parse(new TextDecoder().decode(x));
const same=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
export async function sha256(data){return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes(data))),x=>x.toString(16).padStart(2,'0')).join('');}
function path(p){check(typeof p==='string'&&/^[A-Za-z0-9_.\/-]+$/.test(p)&&!p.startsWith('/')&&!p.split('/').some(x=>!x||x==='.'||x==='..'),'unsafe relative path');return p;}
function glb(data){
 const v=new DataView(data.buffer,data.byteOffset,data.byteLength);check(data.length>=28&&v.getUint32(0,true)===0x46546c67&&v.getUint32(4,true)===2&&v.getUint32(8,true)===data.length,'GLB header');
 const n=v.getUint32(12,true);check(n%4===0&&20+n+8<=data.length&&v.getUint32(16,true)===0x4e4f534a,'GLB JSON');
 const g=json(data.subarray(20,20+n)),start=28+n,len=v.getUint32(20+n,true);check(v.getUint32(24+n,true)===0x004e4942&&start+len===data.length,'GLB BIN');
 check(g.buffers?.length===1&&!g.buffers[0].uri&&g.buffers[0].byteLength<=len,'external GLB buffer');
 function scalar(id){
  const a=g.accessors?.[id],b=g.bufferViews?.[a?.bufferView],size={5121:1,5123:2,5125:4}[a?.componentType];
  check(a&&b&&size&&a.type==='SCALAR'&&!a.sparse&&!a.normalized&&integer(a.count)&&b.buffer===0,'scalar accessor');
  const offset=a.byteOffset??0,begin=b.byteOffset??0,stride=b.byteStride??size;
  check(integer(begin)&&integer(offset)&&integer(b.byteLength)&&integer(stride)&&stride>=size&&(begin+offset)%size===0&&stride%size===0&&begin+b.byteLength<=len&&offset+(a.count? (a.count-1)*stride+size:0)<=b.byteLength,'accessor bounds');
  return {count:a.count,get(i){check(integer(i)&&i<a.count,'accessor index');const at=start+begin+offset+i*stride;return size===1?v.getUint8(at):size===2?v.getUint16(at,true):v.getUint32(at,true);}};
 }
 function positions(id){
  const a=g.accessors?.[id],b=g.bufferViews?.[a?.bufferView];
  check(a&&b&&a.componentType===5126&&a.type==='VEC3'&&!a.sparse&&!a.normalized&&b.buffer===0,'position accessor');
  const offset=a.byteOffset??0,begin=b.byteOffset??0,stride=b.byteStride??12;
  check(integer(a.count)&&integer(begin)&&integer(offset)&&integer(stride)&&stride>=12&&stride%4===0&&(begin+offset)%4===0&&offset+(a.count?(a.count-1)*stride+12:0)<=b.byteLength&&begin+b.byteLength<=len,'position bounds');
  const out=new Float32Array(a.count*3);
  for(let i=0;i<a.count;i++)for(let k=0;k<3;k++)out[i*3+k]=v.getFloat32(start+begin+offset+i*stride+k*4,true);
  return out;
 }
 return {g,scalar,positions};
}
export async function readSurfaceRoles({readPackage,readCompanion,expectedManifest}){
 const index=json(bytes(await readCompanion('index.json')));
 check(index.schema==='worldengine.surface-roles/1','schema');
 check(same(index.roles,['other','roof','wall','trim','door'])&&same(index.materialClasses,materials)&&same(index.provenance,['none','mapped_tag','family_inference']),'tables');
 for(const [k,v]of Object.entries(encoding))check(same(index.encoding?.[k],v),'encoding '+k);
 check(index.packageHash?.path==='world.json'&&index.payload?.path==='triangles.u16le','binding paths');
 const worldBytes=bytes(await readPackage('world.json')),world=json(worldBytes);
 check(await sha256(worldBytes)===index.packageHash.sha256,'package hash (stale/repacked companion)');
 if(expectedManifest)check(same(world,expectedManifest),'loaded manifest differs');
 const payload=bytes(await readCompanion('triangles.u16le'));
 check(payload.length===index.payload.bytes&&await sha256(payload)===index.payload.sha256,'payload hash/length');
 const view=new DataView(payload.buffer,payload.byteOffset,payload.byteLength),entries=index.primitives;
 check(Array.isArray(entries)&&Array.isArray(index.featureSources),'records');
 const witnesses=new Map();for(const w of index.featureSources){
  check(typeof w.feature==='string'&&w.tags&&typeof w.tags==='object'&&!Array.isArray(w.tags),'feature witness');
  // A source relation may emit multiple polygon features. Repeated identical
  // provenance is valid; conflicting tags for the same source ID remain fatal.
  const prior=witnesses.get(w.feature),canonical=t=>JSON.stringify(Object.entries(t).sort(([a],[b])=>a.localeCompare(b)));
  check(!prior||canonical(prior)===canonical(w.tags),'conflicting feature witness');witnesses.set(w.feature,w.tags);
 }
 const paths=Object.keys(world.files??{}).filter(p=>p.endsWith('.glb')).sort();check(paths.length>0,'package GLB inventory');
 const bindings=new Map();
 const groups=new Map(),records=new Map(),roles=[0,0,0,0,0];let end=0,triangles=0,primitiveCount=0;
 for(const e of entries){
  path(e.path);check(paths.includes(e.path)&&integer(e.mesh)&&integer(e.primitive)&&integer(e.lod)&&integer(e.triangleCount)&&integer(e.byteOffset),'primitive identity');
  const expectedLOD=Number(e.path.match(/lod(\d+)\.glb$/)?.[1]??0);check(e.lod===expectedLOD,'LOD');
  check(e.byteOffset%4===0&&e.byteOffset>=end&&e.byteOffset+2*e.triangleCount<=payload.length,'slice overlap/bounds');
  for(let i=end;i<e.byteOffset;i++)check(payload[i]===0,'nonzero padding');end=e.byteOffset+2*e.triangleCount;
  const key=JSON.stringify([e.path,e.mesh,e.primitive]);check(!records.has(key),'duplicate primitive');records.set(key,e);
  if(!groups.has(e.path))groups.set(e.path,[]);groups.get(e.path).push(e);
 }
 check(end===payload.length,'trailing payload'); // Empty GLBs correctly have no primitive records; verified below.
 const scenes=new Map();
 for(const p of paths){
  const data=bytes(await readPackage(path(p))),hash=await sha256(data),file=world.files[p];check(hash===file.sha256&&data.length===file.bytes,'package GLB hash');
  const {g,scalar,positions}=glb(data);let count=0;
  for(const [mi,m]of g.meshes.entries())for(const [pi,prim]of m.primitives.entries()){
   const e=records.get(JSON.stringify([p,mi,pi]));check(e&&e.sha256===hash,'GLB binding/primitive coverage');
   check((prim.mode??4)===4,'primitive mode');const inds=scalar(prim.indices);check(inds.count%3===0&&inds.count/3===e.triangleCount,'triangle count');
   const geometryHash=await surfaceGeometryHash(positions(prim.attributes.POSITION),Uint32Array.from({length:inds.count},(_,i)=>inds.get(i)));
   if(!bindings.has(p))bindings.set(p,[]);bindings.get(p).push({mesh:mi,primitive:pi,geometryHash,triangleCount:e.triangleCount});
   let ids=null,features=null;
   for(let i=0;i<e.triangleCount;i++){
    const word=view.getUint16(e.byteOffset+2*i,true),role=word&7,material=word>>3&31,mp=word>>8&3,cp=word>>10&3;
    check(word>>12===0&&role<5&&material<materials.length&&mp<3&&cp<3,'reserved word/table value');
    check((material===0)===(mp===0)&&mp!==2,'unsupported material provenance');check(role!==0||word===0,'other must remain unknown');roles[role]++;
    if(word===0)continue;
    if(!ids){
     ids=scalar(prim.attributes?._FEATURE);
     const chunk=world.chunks.find(c=>c.lods.includes(p));check(chunk,'annotated nonbuilding/prototype');
     if(!scenes.has(chunk.scene)){
      const raw=bytes(await readPackage(path(chunk.scene))),binding=world.files[chunk.scene];check(binding&&raw.length===binding.bytes&&await sha256(raw)===binding.sha256,'scene feature hash');
      const fs=json(raw).features,map=new Map();check(Array.isArray(fs),'feature table');for(const f of fs){check(integer(f.index)&&!map.has(f.index),'duplicate feature');map.set(f.index,f);}scenes.set(chunk.scene,map);
     }
     features=scenes.get(chunk.scene);
    }
    const corners=[0,1,2].map(k=>ids.get(inds.get(i*3+k)));check(corners.every(x=>x===corners[0]),'mixed feature triangle');
    const f=features.get(corners[0]),tags=witnesses.get(f?.id);check(f?.kind==='building'&&tags,'missing building witness');
    if(cp===2)check(typeof f.generated?.profile==='string'&&f.generated.profile.length>0&&typeof f.generated?.role==='string'&&f.generated.role.length>0&&Array.isArray(f.generated?.colors)&&f.generated.colors.length===4&&integer(f.generated.colorSet),'missing generator colour inference witness');
    if(cp===1){const key=role===1?'roof:colour':role===2?'building:colour':'';check(typeof tags[key]==='string'&&tags[key]===f.source?.[key],'missing/mismatched mapped colour witness');}
    if(mp===1){const key=role===1?'roof:material':'building:material',tag=tags[key];check(typeof tag==='string'&&tag===f.source?.[key]&&tag.trim().toLowerCase()===materials[material],'material witness mismatch');}
   }
   triangles+=e.triangleCount;count++;
  }
  check(count===(groups.get(p)?.length??0),'extra primitive');primitiveCount+=count;
 }
 // No partial records escape on rejection. Metadata is CPU-only, no GPU changes.
 return Object.freeze({report:Object.freeze({schema:index.schema,packageHash:index.packageHash.sha256,payloadHash:index.payload.sha256,primitives:primitiveCount,triangles,roles,payloadBytes:payload.length,status:'validated; no appearance application'}),
  async matchGeometry(p,position,index){
   const key=await surfaceGeometryHash(position,index),found=bindings.get(p)?.filter(b=>b.geometryHash===key)??[];
   check(found.length===1,'loaded geometry does not uniquely match validated primitive');return Object.freeze({...found[0]});
  },
  word(p,mesh,primitive,triangle){const e=records.get(JSON.stringify([p,mesh,primitive]));check(e&&integer(triangle)&&triangle<e.triangleCount,'record lookup');return view.getUint16(e.byteOffset+2*triangle,true);}});
}
export async function loadSurfaceRoles(packageBase,companionIndex,expectedManifest){
 if(companionIndex==null||companionIndex==='off')return null;
 const origin=location.origin,base=new URL(packageBase,location.href),index=new URL(companionIndex,location.href);
 check(base.origin===origin&&index.origin===origin&&index.pathname.endsWith('/index.json')&&!index.search&&!index.hash,'same-origin index URL required');
 const side=new URL('./',index);
 const reader=root=>async p=>{const url=new URL(path(p),root);check(url.origin===origin&&url.pathname.startsWith(root.pathname),'path escape');const r=await fetch(url,{cache:'no-store'});check(r.ok&&!r.redirected,'fetch '+p);return new Uint8Array(await r.arrayBuffer());};
 return readSurfaceRoles({readPackage:reader(base),readCompanion:reader(side),expectedManifest});
}

// Canonical little-endian representation: independent of GLB buffer interleaving.
export async function surfaceGeometryHash(position,index){
 check(position.length%3===0&&index.length%3===0,'geometry shape');
 const raw=new Uint8Array(8+4*(position.length+index.length)),v=new DataView(raw.buffer);
 v.setUint32(0,position.length,true);v.setUint32(4,index.length,true);
 for(let i=0;i<position.length;i++){check(Number.isFinite(position[i]),'nonfinite position');v.setFloat32(8+4*i,position[i],true);}
 for(let i=0;i<index.length;i++){check(integer(index[i])&&index[i]<position.length/3,'geometry index');v.setUint32(8+4*(position.length+i),index[i],true);}
 return sha256(raw);
}
