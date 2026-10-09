// Observational tooling only: no generator or renderer decisions are changed here.
import {createHash} from 'node:crypto';
export const THRESHOLDS={blankGroundFraction:.35,buildingRelativeError:.02,tunnelSurfaceY:-.1,clippingSegmentPixels:2,clippedStaticFraction:.01,pixelVariance:4,pixelRange:10,probeColumns:81,probeRows:45};
export const TIERS={floor:{mainTriangles:400000,mainExclusive:true,shadowTriangles:150000,mainDraws:100},standard:{mainTriangles:500000,mainExclusive:false,shadowTriangles:180000,mainDraws:120,provisional:true}};
export const sha256=bytes=>createHash('sha256').update(bytes).digest('hex');
export function parseStats(markdown){
 const building=markdown.match(/\| Buildings \(excluding parts\) \| (\d+) \|/);
 if(!building)throw Error('Source inventory lacks the Buildings (excluding parts) row');
 const section=markdown.split('## Areas\n')[1]?.split('\n## ')[0];
 if(!section)throw Error('Source inventory lacks the Areas section');
 const areas={};for(const match of section.matchAll(/\| ([\w]+) \| (\d+) \| ([\d.]+) m² \|/g))areas[match[1]]={features:+match[2],squareMetres:+match[3]};
 return {buildings:+building[1],areas,source:'worldbake stats; AreaLoader.loadFeatures, core bounds, non-part OSM + accepted Overture footprints'};
}
export function typeTag(stats,squareMetres,gridAlignment){
 const area=['water','pool','park','grass','garden','meadow','recreation','wood'].reduce((n,k)=>n+(stats.areas[k]?.squareMetres||0),0);
 if(area/squareMetres>=.1)return 'park/water';
 const density=stats.buildings/(squareMetres/1e6);
 if(density>=1000&&gridAlignment>=.7)return 'dense grid';
 if(density<1000)return 'suburban';
 return 'mixed';
}
export function tierChecks(main,shadow){
 return Object.fromEntries(Object.entries(TIERS).map(([name,t])=>[name,{pass:(t.mainExclusive?main.triangles<t.mainTriangles:main.triangles<=t.mainTriangles)&&main.draws<=t.mainDraws&&shadow.triangles<=t.shadowTriangles,mainTrianglesPass:t.mainExclusive?main.triangles<t.mainTriangles:main.triangles<=t.mainTriangles,mainDrawsPass:main.draws<=t.mainDraws,shadowTrianglesPass:shadow.triangles<=t.shadowTriangles,shadowDrawLimit:null}]));
}
export function passTotals(passes){
 const out={main:{triangles:0,draws:0},shadow:{triangles:0,draws:0},post:{triangles:0,draws:0}};
 for(const [key,p] of Object.entries(passes)){const category=key.split('/')[0];if(!out[category])throw Error('Unknown pass '+key);for(const k of ['triangles','draws']){if(!Number.isSafeInteger(p[k])||p[k]<0)throw Error('Invalid pass counter');out[category][k]+=p[k];}}
 if(!out.main.triangles||!out.main.draws)throw Error('No main submissions');return out;
}
export function featureChecks(stats,features,tunnelIDs){
 const drawn=features.filter(f=>Object.values(f.lod0).some(r=>r.some(([,n])=>n>0))),byKind=k=>new Set(drawn.filter(f=>f.kind===k).map(f=>f.id));
 const buildings=byKind('building').size,relativeError=stats.buildings?Math.abs(buildings-stats.buildings)/stats.buildings:(buildings?1:0);
 const water=byKind('water').size,park=byKind('park').size;
 return {buildings:{source:stats.buildings,exportedUnique:buildings,relativeError,pass:relativeError<=THRESHOLDS.buildingRelativeError},water:{source:stats.areas.water?.features||0,exportedUnique:water,pass:!!(stats.areas.water?.features)===!!water},park:{source:stats.areas.park?.features||0,exportedUnique:park,pass:!!(stats.areas.park?.features)===!!park},tunnelCandidates:[...new Set(drawn.filter(f=>tunnelIDs.has(f.id)&&['road','path','sidewalk','crossing'].includes(f.kind)).map(f=>f.id))]};
}
export function sourceRoads(elements,frame){
 const nodes=new Map(elements.filter(e=>e.type==='node').map(e=>[e.id,e])),tunnels=new Set(),passages=new Set();let aligned=0,length=0;
 const pathKinds=new Set(['pedestrian','footway','path','cycleway','bridleway','steps','corridor']);
 for(const e of elements){if(e.type!=='way'||!e.tags?.highway)continue;
  if(e.tags.tunnel&&e.tags.tunnel!=='no'){
   // Keep the filed carriageway guard (including service building passages).
   // A mapped pedestrian building passage can have a ground-level floor;
   // an explicit negative layer still requires the underground screen.
   (pathKinds.has(e.tags.highway)&&e.tags.tunnel==='building_passage'&&!(Number(e.tags.layer)<0)?passages:tunnels).add('way/'+e.id);
  }
  for(let i=1;i<(e.nodes||[]).length;i++){const a=nodes.get(e.nodes[i-1]),b=nodes.get(e.nodes[i]);if(!a||!b)continue;const p=frame.local(a.lat,a.lon),q=frame.local(b.lat,b.lon),dx=q[0]-p[0],dy=q[1]-p[1],d=Math.hypot(dx,dy);if(d<1)continue;const angle=Math.abs(Math.atan2(dy,dx)*180/Math.PI)%90;length+=d;if(Math.min(angle,90-angle)<=15)aligned+=d;}}
 return {gridAlignment:length?aligned/length:0,tunnelIDs:tunnels,groundPassageIDs:passages};
}
export function compareRuns(current,previous){
 if(!previous)return {status:'first-run',added:current.rows.map(r=>r.key),removed:[],changes:[]};
 const old=new Map(previous.rows.map(r=>[r.key,r])),now=new Map(current.rows.map(r=>[r.key,r])),changes=[];
 for(const r of current.rows){const p=old.get(r.key);if(!p)continue;
  const comparable=JSON.stringify(r.comparisonInputs)===JSON.stringify(p.comparisonInputs);
  const delta={};for(const [name,value] of Object.entries(r.metrics)){if(name==='pixelVariance')continue; // Wind-phase pixel variance is diagnostic; flat-frame threshold changes still appear in failures.
   if(typeof value==='number'&&typeof p.metrics[name]==='number'&&value!==p.metrics[name])delta[name]={previous:p.metrics[name],current:value,delta:value-p.metrics[name]};}
  const failuresChanged=JSON.stringify(r.failures)!==JSON.stringify(p.failures);
  if(!comparable||Object.keys(delta).length||failuresChanged)changes.push({key:r.key,comparable,reason:comparable?null:'camera, source, renderer kind, harness, or detector contract changed',metrics:delta,failuresBefore:p.failures,failuresAfter:r.failures});
 }
 return {status:'compared',previousCommit:previous.commit,added:[...now.keys()].filter(k=>!old.has(k)),removed:[...old.keys()].filter(k=>!now.has(k)),changes};
}
