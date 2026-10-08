import {resolveAtmosphere} from './atmosphere.js';
// General pack resolver: deliberately accepts no camera, scene ID or image score.
// Renderer unit conversion is analytic, not fitted to either evaluation frame.
export function resolvePolicy(cal,lake,fixture,correction,haze,climateRegion){
 const look=cal.sharedLook,L=look.lighting,atmosphere=resolveAtmosphere(haze,climateRegion,fixture);
 const shadowRatio=L.shadow.neutralWitnessShadowToLitLinearY;
 if(!(shadowRatio>0&&shadowRatio<1))throw Error('Invalid neutral witness ratio');
 return {
  look,
  // Lambert BRDF divides incident radiance by pi. A/(A+D)=the pack witness ratio.
  directIntensity:Math.PI*L.sun.directRelative,
  ambientIntensity:Math.PI*L.sun.directRelative*shadowRatio/(1-shadowRatio),
  // Calibration-v2 STATUS.md: approved shared correction, never sampled from this run.
  sky:{...L.sky,...Object.fromEntries(Object.entries(correction.set).map(([k,v])=>[k.split('.').at(-1),v]))},
  // haze-visibility-v1 explicitly supersedes lake-winter-v1 background extinction.
  atmosphere,
  hazeExtinctionPerM:atmosphere.sigmaPerM,
  season:fixture.phenophase,
  wind:lake.water.windStates[String(fixture.windKmh)],
  reflectedSky:lake.water.skyStates[fixture.skyState],
 };
}
// Region selects an illustrative candidate pool, never an observed tree inventory.
export function regionalSpecies(pack,region,kind,variant=0){
 const city=pack.cities.find(c=>c.id===region);
 if(!city)throw Error(`No foliage pack region: ${region}`);
 const pool=city.mix.map(m=>pack.species.find(s=>s.id===m.id)).filter(Boolean);
 const candidates=pool.filter(s=>kind==='conifer'?s.evergreen:!s.evergreen);
 const eligible=candidates.length?candidates:pack.species.filter(s=>kind==='conifer'?s.evergreen:!s.evergreen);
 const ordinal={treeBroad:0,treeOval:1,treeSpreading:2,conifer:3}[kind]??0;
 return eligible[(ordinal+variant)%eligible.length];
}
