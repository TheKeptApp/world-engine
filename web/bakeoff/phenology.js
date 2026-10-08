// Port of Sources/WorldEnvironment/Phenology.swift calendar priors. User requested
// date-derived season; this explicitly inferred replay is NOT observed phenology.
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
export function phenology(date,region,data){
 const d=new Date(date+'T12:00:00Z');if(!Number.isFinite(+d))throw Error('Invalid replay date');
 const doy=Math.floor((d-Date.UTC(d.getUTCFullYear(),0,1))/86400000)+1;
 const p=data.phenology[region];if(!p)throw Error('No regional phenology prior');
 const [start,full,mature,colour,peak,drop,end]=p;
 const g=smooth(start,full,doy),m=smooth(full,mature,doy),c=smooth(colour,peak,doy),fall=smooth(drop,end,doy);
 const weights=[g*(1-m)*(1-c)*(1-fall),g*m*(1-c)*(1-fall),g*c*(1-fall),1-g+g*fall];
 return {date,dayOfYear:doy,source:data.phenology.source,dataKind:'climatological_art_prior; calendar explicitly requested by R',weights,leafFraction:g*(1-fall),colourProgress:c,exportSeasonIndex:weights.indexOf(Math.max(...weights))};
}
