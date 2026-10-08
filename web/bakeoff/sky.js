import * as T from 'three/webgpu';
import {appearanceToRadiance} from './sky-colour.js';
import {stableRandom} from './stable-random.js';
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
// Calibration-v2 owns colours/coverage. weather-moments-v1/inherited.sharedLighting.sky
// supplies world-elevation anchors and one shared partly-cloudy preset.
// Seeded cumulus ellipsoids are a renderer construction, never placed for a camera.
export function createSkyTexture(sky,exposure,weather){
 const width=2048,height=1024,rng=stableRandom('a2-clear-cumulus'),lobes=[];
 for(let c=0;c<30;c++){const u=(c+.15+.7*rng())/30,v=.525+rng()*.25,span=.012+rng()*.026;for(let j=0;j<7;j++)lobes.push({u:u+(rng()-.5)*span*2,v:v+(rng()-.5)*span,rx:span*(.5+rng()*.5),ry:span*(.3+rng()*.45)});}
 const density=new Float32Array(width*height),upper=[];
 for(let y=height/2;y<height;y++)for(let x=0;x<width;x++){const u=(x+.5)/width,v=(y+.5)/height;let d=0;for(const l of lobes){const dx=Math.min(Math.abs(u-l.u),Math.abs(u-l.u-1),Math.abs(u-l.u+1))/l.rx,dy=(v-l.v)/l.ry;d=Math.max(d,Math.max(0,1-dx*dx-dy*dy));}density[y*width+x]=d;upper.push(d);}
 upper.sort((a,b)=>a-b);const threshold=Math.max(.001,upper[Math.floor((1-sky.coverage01)*upper.length)]);
 const colours=[sky.horizonHex,sky.midHex,sky.zenithHex].map(h=>new T.Color(h).toArray());
 const angles=[...weather.gradient].sort((a,b)=>a.elevationDeg-b.elevationDeg).map(a=>a.elevationDeg);
 // Two panorama texels of coverage smoothing prevent hard quantile edges.
 const edgeWidth=2/(width*Math.min(...lobes.map(l=>l.rx)));
 const lit=new T.Color(sky.cloudLitHex).toArray(),shade=new T.Color(sky.cloudShadeHex).toArray(),data=new Float32Array(width*height*4);
 for(let y=0;y<height;y++)for(let x=0;x<width;x++){
  const elevation=Math.max(0,((y+.5)/height-.5)*180),band=elevation<angles[1]?0:1,t=Math.max(0,Math.min(1,(elevation-angles[band])/(angles[band+1]-angles[band])));
  let colour=colours[band].map((v,i)=>v+(colours[band+1][i]-v)*t);
  const d=density[y*width+x],alpha=smooth(Math.max(0,threshold-edgeWidth),threshold+edgeWidth,d)*smooth(0,5,elevation),light=smooth(threshold,1,d);
  colour=colour.map((v,i)=>v*(1-alpha)+(shade[i]+(lit[i]-shade[i])*light)*alpha);
  data.set([...appearanceToRadiance(colour,exposure),1],(y*width+x)*4);
 }
 const tex=new T.DataTexture(data,width,height,T.RGBAFormat,T.FloatType);tex.minFilter=tex.magFilter=T.LinearFilter;tex.wrapS=T.RepeatWrapping;tex.needsUpdate=true;return tex;
}
