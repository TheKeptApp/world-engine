// haze-visibility-v1: all values are selected by climate / season / state / time.
// No city camera or score is accepted. These are labelled authored fallback fixtures.
const decode=x=>x<=.04045?x/12.92:((x+.055)/1.055)**2.4;
export const linearHex=hex=>[1,3,5].map(i=>decode(parseInt(hex.slice(i,i+2),16)/255));
export const luminance=c=>c[0]*.2126+c[1]*.7152+c[2]*.0722;
export const transmittance=(sigma,distance)=>Math.exp(-sigma*distance);
export function resolveAtmosphere(pack,region,fixture){
 const season=fixture.atmosphereSeason,state=fixture.skyState,time=fixture.timeOfDay;
 const preset=pack.regions.find(r=>r.id===region)?.seasons[season]?.[state];
 if(!preset||!(preset.visibilityKm>0))throw Error('No approved regional visibility preset');
 if(fixture.atmosphereLayers?.length)throw Error('This homogeneous fixture renderer cannot silently ignore local atmospheric layers');
 const sigma=-Math.log(pack.definition.contrastThreshold)/(1000*preset.visibilityKm);
 if(Math.abs(sigma-preset.extinctionPerM)>5e-13)throw Error('MOR conversion disagrees with pack');
 const day=linearHex(pack.airlight.stateDayHex[state]),t=pack.airlight.timeMix[time];
 if(!Number.isFinite(t))throw Error('Unknown atmosphere time');
 const timed=t?linearHex(pack.airlight.timeHex[time]):day;
 return {region,season,state,time,visibilityKm:preset.visibilityKm,sigmaPerM:preset.extinctionPerM,airlightLinear:day.map((v,i)=>v*(1-t)+timed[i]*t),airlightSource:'haze-visibility-v1/airlight.stateDayHex + timeHex/timeMix; palette fallback',sourceKey:`haze-visibility-v1/regions[id=${region}].seasons.${season}.${state}`,status:'authored regional fallback; simulated, not observed',mountains:pack.mountains,summitsObscured:fixture.summitsObscured===true,layers:'none supplied; homogeneous ray optical depth',applyOnce:pack.integration.applyOnce};
}
export function mountainVisibility(rule,lit,air,sigma,distance,projectedHeightPx,blocked=false){
 const c0=Math.abs(luminance(lit)-luminance(air))/Math.max(luminance(air),.001),contrast=c0*transmittance(sigma,distance);
 const x=Math.max(0,Math.min(1,(contrast-rule.cullContrast)/(rule.retainContrast-rule.cullContrast)));
 return {initialContrast:c0,retainedContrast:contrast,alpha:blocked||projectedHeightPx<rule.minProjectedHeightPx?0:x*x*(3-2*x),retain:!blocked&&projectedHeightPx>=rule.minProjectedHeightPx&&contrast>=rule.retainContrast,internalDetail:contrast>=rule.internalDetailContrast};
}
