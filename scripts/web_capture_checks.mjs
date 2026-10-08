// Capture validation only; never modifies renderer state or look values.
export function modeQueries({foliage='off',crown='off',matrix=false}={}) {
 const fs=matrix?['off','remove','layered']:[foliage],cs=matrix?['off','on']:[crown];
 if(fs.some(x=>!['off','remove','layered'].includes(x))||cs.some(x=>!['off','on'].includes(x)))throw Error('Unsupported capture mode');
 return cs.flatMap(crownV2=>fs.map(foliageExp1=>({foliageExp1,crownV2})));
}
export function verifyCounters(metrics) {
 if(!metrics||!Number.isSafeInteger(metrics.triangles)||metrics.triangles<=0||!Number.isSafeInteger(metrics.drawCalls)||metrics.drawCalls<=0)throw Error('Scene-ready signal has missing/invalid triangle or draw counters');
 return [metrics.triangles,metrics.drawCalls];
}
export function verifyCoverage(records) {
 const seen=new Map();
 for(const row of records){const fingerprint=JSON.stringify(verifyCounters(row.metrics));
  if(seen.has(row.scene)&&seen.get(row.scene)!==fingerprint)throw Error(`Unequal scene coverage: ${row.scene} triangles/draws differ; batch rejected`);
  seen.set(row.scene,fingerprint);
 }
}
export function verifyPixels({width,height,data},expected) {
 if(width!==expected.width||height!==expected.height)throw Error(`Wrong frame size: ${width}x${height}, expected ${expected.width}x${expected.height}`);
 let min=255,max=0,sum=0,squared=0,count=0;
 // Exclude the credits overlay at the top: text on a flat canvas is not a valid world.
 for(let y=Math.ceil(height*.15);y<height;y++)for(let x=0;x<width;x++){
  const i=(y*width+x)*4,v=(data[i]+data[i+1]+data[i+2])/3;
  min=Math.min(min,v);max=Math.max(max,v);sum+=v;squared+=v*v;count++;
 }
 const variance=squared/count-(sum/count)**2;
 if(max-min<8||variance<4)throw Error('Flat frame: insufficient pixel range/variance below the credits overlay');
 return {range:max-min,variance};
}
