// Qualification probes only; the on-disk afc72bd renderer variant is unchanged.
export function instrumentBudgetSource(source){
 const replace=(before,after)=>{if(source.split(before).length!==2)throw Error('Qualification instrumentation source mismatch: '+before);source=source.replace(before,after);};
 replace(' function update(){',' function update(){const __qStart=performance.now();');
 replace('  if(signature===previous)return;',"  if(signature===previous){globalThis.__sceneBudgetObserve?.({selectionMs:0,poolingMs:0,maintenanceMs:performance.now()-__qStart,cached:true});return;}");
 replace('  const frustum=new T.Frustum()', '  const __qSelect=performance.now();\n  const frustum=new T.Frustum()');
 replace('  for(const items of buckets.values()){','  const __qPool=performance.now();\n  for(const items of buckets.values()){');
 const end='  Object.assign(report,{updates:report.updates+1,retainedTriangles,rejectedTriangles,pooledDraws:root.children.length,mainSourceMeshes:sources.length});';
 replace(end,end+'\n  globalThis.__sceneBudgetObserve?.({selectionMs:__qPool-__qSelect,poolingMs:performance.now()-__qPool,maintenanceMs:__qSelect-__qStart,cached:false});');
 return source;
}
export function pathSamples(fps=30){const count=10*fps;return Array.from({length:12},(_,i)=>Math.round(i*count/11));}
export function pathPose(path,k,fps,origin){
 if(!['pan','descent'].includes(path))throw Error('Unknown motion path');const t=k/(10*fps);
 return {position:[origin[0]+(path==='pan'?-100+200*t:0),path==='pan'?150:600-560*t,origin[2]],heading:270,pitch:45,timeMs:k*1000/fps};
}
export function distribution(values){const a=[...values].sort((a,b)=>a-b);return {count:a.length,p50:a[Math.max(0,Math.ceil(a.length*.5)-1)]??0,p95:a[Math.max(0,Math.ceil(a.length*.95)-1)]??0,max:a.at(-1)??0};}
export function difference(a,b,width,height){
 if(a.length!==b.length||a.length!==width*height*4)throw Error('Pixel dimension mismatch');
 let max=0,sum=0,count=0,pixels=0;const regions=[];
 // Every differing 32px region is retained; zero threshold, no discarded component size.
 for(let y0=0;y0<height;y0+=32)for(let x0=0;x0<width;x0+=32){let n=0,m=0,s=0;
  for(let y=y0;y<Math.min(height,y0+32);y++)for(let x=x0;x<Math.min(width,x0+32);x++){let changed=false;
   for(let c=0;c<4;c++){const d=Math.abs(a[(y*width+x)*4+c]-b[(y*width+x)*4+c]);max=Math.max(max,d);sum+=d;if(d){count++;n++;changed=true;}m=Math.max(m,d);s+=d;}if(changed)pixels++;
  }if(n)regions.push({x:x0,y:y0,width:Math.min(32,width-x0),height:Math.min(32,height-y0),differingBytes:n,max:m,sum:s});
 }
 return {maxByte:max,meanAbsoluteByte:sum/a.length,maxNormalized:max/255,meanNormalized:sum/a.length/255,differingBytes:count,differingPixels:pixels,regions};
}
export function installBufferProbe(){
 const get=HTMLCanvasElement.prototype.getContext;
 HTMLCanvasElement.prototype.getContext=function(type,...args){const gl=get.call(this,type,...args);if(type!=='webgl2'||!gl||gl.__qualificationProbe)return gl;
  const buffers=new WeakMap(),records=new Set(),bound=new Map();let created=0,deleted=0,collected=0,uploaded=0,peakCount=0,peakBytes=0;
  // Peaks are observed at completed-frame snapshots, not intra-frame driver residency.
  const alive=()=>{let bytes=0,count=0;for(const record of records){if(!record.ref.deref()){records.delete(record);collected++;continue;}bytes+=record.bytes;count++;}peakCount=Math.max(peakCount,count);peakBytes=Math.max(peakBytes,bytes);return {count,bytes};};
  const create=gl.createBuffer.bind(gl),del=gl.deleteBuffer.bind(gl),bind=gl.bindBuffer.bind(gl),data=gl.bufferData.bind(gl),sub=gl.bufferSubData.bind(gl);
  gl.createBuffer=()=>{const b=create();if(b){const state={ref:new WeakRef(b),bytes:0};buffers.set(b,state);records.add(state);created++;}return b;};
  gl.deleteBuffer=b=>{const state=buffers.get(b);if(state){records.delete(state);buffers.delete(b);deleted++;}return del(b);};
  gl.bindBuffer=(target,b)=>{bound.set(target,b);return bind(target,b);};
  const size=(a,offset=0,length)=>typeof a==='number'?a:a===null?0:(length===undefined?(a.byteLength-offset*(a.BYTES_PER_ELEMENT||1)):length*(a.BYTES_PER_ELEMENT||1));
  gl.bufferData=(target,a,usage,offset,length)=>{const r=offset===undefined?data(target,a,usage):length===undefined?data(target,a,usage,offset):data(target,a,usage,offset,length);const n=size(a,offset,length),state=buffers.get(bound.get(target));if(state)state.bytes=n;if(typeof a!=='number')uploaded+=n;return r;};
  gl.bufferSubData=(target,offset,a,start,length)=>{const r=start===undefined?sub(target,offset,a):length===undefined?sub(target,offset,a,start):sub(target,offset,a,start,length);uploaded+=size(a,start,length);return r;};
  gl.__qualificationProbe={snapshot:()=>{const a=alive();return {activeBuffers:a.count,activeBufferBytes:a.bytes,peakBuffers:peakCount,peakBufferBytes:peakBytes,totalCreated:created,totalDeleted:deleted,gcReleasedHandles:collected,totalUploadedBytes:uploaded};}};return gl;
 };
}
