// Bakeoff data adapter; no area IDs, cameras, grades or new material values.
// Approved: haze-visibility-v1 regions; foliage-seasons-v1 cities/species;
// P2 fcda086 nearest-species/shape adapters. R authorizes inferred gaps, 9 Oct.
export function regionalAdapter(input,{haze,fullHaze,foliage,p2}){
 const {id,climateRegion,speciesRegion,latitude}=input;
 if(!id||!Number.isFinite(latitude)||Math.abs(latitude)>90)throw Error('Regional latitude required');
 const climate=fullHaze.regions.find(r=>r.id===climateRegion);
 const city=foliage.cities.find(c=>c.id===speciesRegion);
 if(!climate||!city)throw Error('Approved climate and species inputs required');
 const h=structuredClone(haze),f=structuredClone(foliage),d=structuredClone(p2);
 if(!h.regions.some(r=>r.id===climateRegion))h.regions.push(structuredClone(climate));
 const proxies=[],mix=[];
 for(const entry of city.mix){
  const target=d.foliageSeasons.species[entry.id]?entry.id:d.foliageSeasons.nearest[entry.id];
  const species=f.species.find(s=>s.id===target);if(!species)continue;
  // Evergreen broadleaves have no P2 shape: retain their biology/colours, use
  // the existing rounded scaffold, explicitly inferred rather than conifer.
  if(!d.foliageSeasons.species[target].kind){d.foliageSeasons.species[target].kind='treeRounded';proxies.push({from:entry.id,to:target,shape:'treeRounded',status:'inferred broadleaf scaffold'});}
  else if(target!==entry.id)proxies.push({from:entry.id,to:target,status:'inferred P2 nearest botanical display proxy'});
  if(!mix.some(m=>m.id===target))mix.push({id:target});
 }
 if(!mix.length)throw Error('No described approved species');
 // Retain exported shape families when the regional pack lacks a matching
 // silhouette. Use its first deciduous species albedo; do not introduce a
 // foreign city palette. P2 form groups are broad/oval/spreading/conifer.
 for(const kinds of [['treeRounded'],['treePyramidal','treeUpright'],['treeVase','treeOpen'],['conifer']]){
  if(mix.some(m=>kinds.includes(d.foliageSeasons.species[m.id].kind)))continue;
  const base=mix.map(m=>f.species.find(s=>s.id===m.id)).find(s=>s.evergreen===(kinds[0]==='conifer'));
  if(!base)throw Error('Regional mix cannot cover exported foliage form '+kinds[0]);
  const proxy=id+'/inferred/'+kinds[0],s={...structuredClone(base),id:proxy};
  f.species.push(s);d.foliageSeasons.species[proxy]={kind:kinds[0]};mix.push({id:proxy});proxies.push({from:base.id,to:proxy,shape:kinds[0],status:'inferred existing P2 scaffold; regional species palette retained'});
 }
 f.cities.push({id,mix,typicalMixStatus:'inferred climate-region proxy; not inventory'});
 d.vegetationRegions[id]={slots:{},bark:d.vegetationRegions.chicago.bark};
 // No calibrated regional day-of-year knots: foliage policy does not license
 // inventing autumn from latitude. Explicit neutral retained-foliage prior.
 d.phenology[id]={quality:'unknown',status:'inferred neutral summer; no regional calendar knots'};
 return {haze:h,foliage:f,p2:d,report:{...input,status:'inferred regional adapter',hazeKey:`haze-visibility-v1/regions.${climateRegion}`,speciesKey:`foliage-seasons-v1/cities.${speciesRegion}.mix`,proxies,phenology:d.phenology[id],facades:'No matching facade-detail family: exported geometry/materials retained',sharedLook:'style-b-calibration-v2 unchanged; no regional exposure or saturation'}};
}
