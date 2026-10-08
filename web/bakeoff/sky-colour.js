// 5A docs/look-spec-changes.md, 2026-10-08: tone curve on luminance holds hue.
// Same ACES fit coefficients as installed three.js, applied once to linear Y.
const lum=v=>v[0]*.2126+v[1]*.7152+v[2]*.0722;
const curve=x=>(x*(x+.0245786)-.000090537)/(x*(.983729*x+.432951)+.238081);
export function appearanceToRadiance(rgb,e){
 const graded=rgb.map(x=>(x-.5)/e.contrast+.5),y=lum(graded),mapped=graded.map(x=>(x-y*(1-e.saturation))/e.saturation);
 const a=1-.983729*y,b=.0245786-.432951*y,c=-.000090537-.238081*y;
 const linearY=(-b+Math.sqrt(b*b-4*a*c))/(2*a)*.6/e.linearGain;
 return mapped.map(x=>Math.max(0,x*linearY/y));
}
export function radianceToAppearance(rgb,e){const y=lum(rgb),mappedY=curve(y*e.linearGain/.6),mapped=rgb.map(x=>x*mappedY/y);return mapped.map(x=>((mappedY+(x-mappedY)*e.saturation)-.5)*e.contrast+.5);}
