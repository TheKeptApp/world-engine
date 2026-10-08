// Invert the installed three.js ACES transfer + our one shared grade.
// Pack sky swatches are appearance targets, not HDR material albedos.
// Encoding them before the single post pass prevents applying that transfer twice.
const input=[[.59719,.35458,.04823],[.076,.90834,.01566],[.02840,.13383,.83777]];
const output=[[1.60475,-.53108,-.07367],[-.10208,1.10813,-.00605],[-.00327,-.07276,1.07602]];
const mul=(m,v)=>m.map(r=>r.reduce((s,x,i)=>s+x*v[i],0));
function inverse(m){const a=m.map((r,i)=>[...r,...[0,1,2].map(j=>+(i===j))]);for(let k=0;k<3;k++){const d=a[k][k];a[k]=a[k].map(x=>x/d);for(let i=0;i<3;i++)if(i!==k){const f=a[i][k];a[i]=a[i].map((x,j)=>x-f*a[k][j]);}}return a.map(r=>r.slice(3));}
const invIn=inverse(input),invOut=inverse(output),lum=v=>v[0]*.2126+v[1]*.7152+v[2]*.0722;
export function appearanceToRadiance(rgb,e){const graded=rgb.map(x=>(x-.5)/e.contrast+.5),y=lum(graded),mapped=graded.map(x=>(x-y*(1-e.saturation))/e.saturation);const curve=mul(invOut,mapped).map(v=>{const a=1-.983729*v,b=.0245786-.432951*v,c=-.000090537-.238081*v;return (-b+Math.sqrt(b*b-4*a*c))/(2*a);});return mul(invIn,curve).map(x=>Math.max(0,x*.6/e.linearGain));}
export function radianceToAppearance(rgb,e){const v=mul(input,rgb.map(x=>x*e.linearGain/.6)).map(x=>(x*(x+.0245786)-.000090537)/(x*(.983729*x+.432951)+.238081));const c=mul(output,v),y=lum(c);return c.map(x=>((y+(x-y)*e.saturation)-.5)*e.contrast+.5);}
