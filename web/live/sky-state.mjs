import {solarPosition,lunarPosition,instant} from './astronomy.mjs';
import {visibilityState,airlightColour} from './visibility.mjs';
// R approved for A6 only: docs/decisions/owner-log.md, 2026-10-08.
// sky-seasons-v1 §2.1 golden [-4,+6], blue [-6,-4]; golden wins shared endpoint.
// night-fog-v1 states[id=night].time.maxElevationDeg: full night <= -12.
export function phaseOfDay(elevationDeg) {
  if (!Number.isFinite(elevationDeg) || Math.abs(elevationDeg)>90) throw new RangeError('Invalid solar elevation');
  return {phase:elevationDeg>6?'day':elevationDeg>=-4?'goldenHour':elevationDeg>=-6?'blueHour':'night',
    twilight:elevationDeg< -6 && elevationDeg> -12, fullNight:elevationDeg<=-12};
}
// Clock injection is for deterministic tests. Production default is the real wall clock.
export function createSkyState({clock=Date.now}={}) {
  if (typeof clock!=='function') throw new TypeError('clock must be a function');
  return function getSkyState(input) {
    const now=instant(clock());
    const sun=solarPosition(input), moon=lunarPosition(input);
    const phase=phaseOfDay(sun.elevationDeg);
    const visibility=visibilityState(input,now);
    return {time:new Date(instant(input.time)).toISOString(),sun,moon,...phase,
      directSunAboveHorizon:sun.elevationDeg>0,
      airlight:airlightColour(visibility.state,phase.phase),
      extinctionPerM:visibility.extinctionPerM,label:visibility.label,visibility};
  };
}
export const getSkyState = createSkyState();
