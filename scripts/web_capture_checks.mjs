// Capture validation only; never modifies renderer state or look values.
export function modeQueries({foliage='off',crown='off',matrix=false}={}) {
 const fs=matrix?['off','remove','layered']:[foliage],cs=crown.split(',');
 if(fs.some(x=>!['off','remove','layered'].includes(x))||cs.some(x=>!['off','on','standard','floor'].includes(x)))throw Error('Unsupported capture mode');
 return cs.flatMap(crownV2=>fs.map(foliageExp1=>({foliageExp1,crownV2})));
}
export function verifyModes(evidence,mode) {
 const expected=mode.crownV2==='on'?'standard':mode.crownV2;
 const resolved=evidence.crownV2===false?'off':evidence.crownV2;
 if(evidence.foliageExp1!==mode.foliageExp1||resolved!==expected)throw Error('Rendered experiment modes differ from requested query');
}
export function verifyCounters(metrics) {
 if(!metrics||!Number.isSafeInteger(metrics.triangles)||metrics.triangles<=0||!Number.isSafeInteger(metrics.drawCalls)||metrics.drawCalls<=0)throw Error('Scene-ready signal has missing/invalid triangle or draw counters');
 return [metrics.triangles,metrics.drawCalls];
}
// The ledger groups ground, roads, buildings and context as opaque world.
// Only the explicitly named foliage bucket may differ; every other pass stays equal.
export function coveragePasses(metrics) {
 verifyCounters(metrics);
 const entries=Object.entries(metrics.cost?.passes||{}).sort(([a],[b])=>a.localeCompare(b));
 if(!entries.some(([key])=>key==='main/opaque world'))throw Error('Missing non-foliage coverage ledger');
 for(const [key,p] of entries)if(!Number.isSafeInteger(p.triangles)||p.triangles<0||!Number.isSafeInteger(p.draws)||p.draws<0)throw Error('Invalid coverage pass: '+key);
 return Object.fromEntries(entries);
}
export function verifyCoverage(records,{expectedDifferent=false}={}) {
 const seen=new Map(),sameModes=new Map(),deltas=[];
 for(const row of records){
  const passes=coveragePasses(row.metrics),full=JSON.stringify([verifyCounters(row.metrics),passes]);
  const mode=JSON.stringify([row.scene,row.foliageExp1||'off',row.crownV2||'off',row.crownV3||'off']);
  if(sameModes.has(mode)&&sameModes.get(mode)!==full)throw Error(`Unequal scene coverage: ${row.scene} identical-mode repeat differs`);
  sameModes.set(mode,full);
  const nonFoliage=Object.fromEntries(Object.entries(passes).filter(([key])=>!key.endsWith('/foliage')));
  const foliage=Object.entries(passes).filter(([key])=>key.endsWith('/foliage')).reduce((a,[,p])=>({triangles:a.triangles+p.triangles,draws:a.draws+p.draws}),{triangles:0,draws:0});
  const first=seen.get(row.scene);
  if(first){
   if(expectedDifferent?JSON.stringify(first.nonFoliage)!==JSON.stringify(nonFoliage):first.full!==full)throw Error(`Unequal scene coverage: ${row.scene} ${expectedDifferent?'non-foliage passes':'triangles/draws'} differ; batch rejected`);
   deltas.push({scene:row.scene,foliageExp1:row.foliageExp1,crownV2:row.crownV2,crownV3:row.crownV3||'off',foliageDelta:{triangles:foliage.triangles-first.foliage.triangles,draws:foliage.draws-first.foliage.draws}});
  }else seen.set(row.scene,{full,nonFoliage,foliage});
 }
 return {expectedDifferent,deltas};
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

export function byteDifference(a,b) {
 const length=Math.max(a.length,b.length);let differingBytes=0,max=0,sum=0;
 for(let i=0;i<length;i++){
  const delta=i>=a.length||i>=b.length?255:Math.abs(a[i]-b[i]);
  if(delta) differingBytes++;
  max=Math.max(max,delta);sum+=delta;
 }
 return {freshBytes:a.length,repeatBytes:b.length,differingBytes,max,mean:length?sum/length:0};
}
