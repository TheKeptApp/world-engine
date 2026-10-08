import pack from './pack-data.mjs';
import {instant, coordinates} from './astronomy.mjs';
const owns = (o,k) => Object.hasOwn(o,k);
const severe = new Set(['smoke','rain','snow']);
export function localSeason({lat,lon,time}) {
  coordinates(lat,lon);
  // Longitude-based local mean solar date: deterministic, no timezone database/feed.
  // haze-visibility-v1 regions[*].seasonBasis: meteorological, hemisphere-aware.
  const month = new Date(instant(time)+lon*240000).getUTCMonth();
  const index = Math.floor(((month+1)%12)/3);
  return ['winter','spring','summer','autumn'][(index+(lat<0?2:0))%4];
}
function metadata(input, now) {
  if (!input || input.kind !== 'observation') return {status:'demo',ageMinutes:null};
  if (typeof input.source !== 'string' || !input.source.trim()) return {status:'demo',ageMinutes:null};
  let stamp;
  try { stamp = instant(input.observedAt); } catch { return {status:'invalid',ageMinutes:null}; }
  const ageMinutes = (now-stamp)/60000;
  if (ageMinutes<0) return {status:'invalid',ageMinutes};
  const {softAgeMinutes,hardAgeMinutes} = pack.selection.staleData;
  return {status:ageMinutes>=hardAgeMinutes?'expired':ageMinutes>=softAgeMinutes?'stale':'live',ageMinutes};
}
function parseVisibility(input) {
  if (!input || input.representative !== true) return null;
  // Explicit reporting codes; preserve bounds, never turn ceiling bins into exact MOR.
  if (input.report === '10SM') return {km:16.09344,lowerBound:true};
  if (input.report === '9999') return {km:10,lowerBound:true};
  if (input.report !== undefined) return null;
  const factors = {km:1,m:0.001,SM:1.609344};
  if (!owns(factors,input.unit) || !Number.isFinite(input.value) || input.value<=0) return null;
  const km = input.value*factors[input.unit];
  if (!Number.isFinite(km) || km<=0 || input.convention !== 'MOR_5_PERCENT') return null;
  if (input.unit==='SM' && input.value===10 && input.reportingSystem==='US_METAR')
    return {km,lowerBound:true};
  return {km,lowerBound:input.lowerBound===true};
}
export function visibilityState({lat,lon,time,region,weatherState,observedVisibility}, now) {
  const season = localSeason({lat,lon,time});
  const regional = pack.regions.find(r=>r.id===region);
  if (!regional) throw new RangeError('Unknown haze region: '+region);
  const weather = typeof weatherState==='string'?{states:[weatherState],kind:'demo'}:weatherState;
  const states = weather?.states ?? (weather?.state?[weather.state]:null);
  if (!Array.isArray(states) || !states.length || states.some(s=>!owns(pack.states,s)))
    throw new RangeError('weatherState must name one or more pack states');
  // selection.combinedStates: strongest candidate, never sum total extinction.
  const candidates = states.map(state=>({state,...regional.seasons[season][state]}));
  let selected = candidates.reduce((a,b)=>a.extinctionPerM>=b.extinctionPerM?a:b);
  if (weather.severity !== undefined) {
    const expected = {lightRain:'rain',heavyRain:'rain',lightSnow:'snow',snowSquall:'snow',denseSmoke:'smoke'};
    if (!owns(expected,weather.severity) || !states.includes(expected[weather.severity]))
      throw new RangeError('Severity must match rain, snow or smoke; local fog needs a spatial adapter');
    const event = {...pack.severityOverrides[weather.severity],state:expected[weather.severity]};
    // Replace the same contributor with its severity, then combine other states.
    selected = [event,...candidates.filter(c=>c.state!==event.state)]
      .reduce((a,b)=>a.extinctionPerM>=b.extinctionPerM?a:b);
  }
  const weatherMeta = metadata(weather,now), observationMeta = metadata(observedVisibility,now);
  const visibility = parseVisibility(observedVisibility);
  const observedUsable = visibility && ['live','stale'].includes(observationMeta.status);
  let extinctionPerM = selected.extinctionPerM, visibilityKm = selected.visibilityKm;
  let basis = 'estimated-region-state', lowerBoundKm = null, contradictoryBound = false;
  if (observedUsable) {
    if (visibility.lowerBound) {
      lowerBoundKm = visibility.km;
      contradictoryBound = states.some(s=>severe.has(s)) && visibilityKm<lowerBoundKm;
      // selection.censoredObservation: retain a conflicting event, otherwise combine prior/bound.
      if (!contradictoryBound) {
        visibilityKm = Math.max(visibilityKm,lowerBoundKm);
        extinctionPerM = pack.definition.constant/1000/visibilityKm;
      }
      basis = 'estimated-censored-prior';
    } else {
      visibilityKm = visibility.km;
      extinctionPerM = pack.definition.constant/1000/visibilityKm;
      basis = 'observed-total';
    }
  }
  const stale = [weatherMeta,observationMeta].some(x=>['stale','expired'].includes(x.status));
  const timeAge = (now-instant(time))/60000;
  const replay = timeAge<0 || timeAge>=pack.selection.staleData.softAgeMinutes;
  // String/fixture weather can never upgrade to live, even with a fresh visibility fixture.
  let label = 'demo';
  if (weather.kind==='observation' && stale) label='stale';
  else if (weatherMeta.status==='live' && observationMeta.status==='live' && basis==='observed-total') label='live';
  if (replay) label='demo';
  return {extinctionPerM,visibilityKm,season,state:selected.state,label,basis,
    estimated:basis!=='observed-total',lowerBoundKm,contradictoryBound,
    weatherAgeMinutes:weatherMeta.ageMinutes,observationAgeMinutes:observationMeta.ageMinutes,
    weatherStatus:weatherMeta.status,observationStatus:visibility?observationMeta.status:'invalid-or-missing',
    hardExpired:observationMeta.status==='expired',
    eventUncertain:states.some(s=>severe.has(s)) && weatherMeta.status!=='live',replay};
}
export function airlightColour(state,phase) {
  // haze-visibility-v1 airlight.stateDayHex/timeHex/timeMix: linear-light mix, once.
  const decode = hex => hex.slice(1).match(/../g).map(h=>{
    const c = parseInt(h,16)/255; return c<=0.04045?c/12.92:((c+0.055)/1.055)**2.4;
  });
  const day = decode(pack.airlight.stateDayHex[state]);
  const mix = pack.airlight.timeMix[phase];
  if (mix===undefined) throw new RangeError('Unknown phase');
  const night = mix?decode(pack.airlight.timeHex[phase]):day;
  const linearRGB = day.map((v,i)=>v*(1-mix)+night[i]*mix);
  const hex = '#'+linearRGB.map(c=>Math.round(255*(c<=0.0031308?12.92*c:1.055*c**(1/2.4)-0.055))
    .toString(16).padStart(2,'0')).join('').toUpperCase();
  return {linearRGB,hex,space:'linear-sRGB',basis:'authored-palette-fallback'};
}
