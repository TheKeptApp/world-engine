// NOAA Solar Calculation Details (Meeus, Astronomical Algorithms, ch. 25):
// https://gml.noaa.gov/grad/solcalc/calcdetails.html (offline implementation).
// All elevations are geometric, airless; UTC approximates UT1. East-positive longitude.
const R = Math.PI / 180;
const sin = x => Math.sin(x * R), cos = x => Math.cos(x * R);
const wrap = x => ((x % 360) + 360) % 360;
const clamp = x => Math.max(-1, Math.min(1, x));
export function instant(value) {
  if (!(value instanceof Date) && typeof value !== 'number' &&
      !(typeof value === 'string' && /T.*(?:Z|[+-]\d\d:\d\d)$/.test(value)))
    throw new TypeError('time must be a Date, epoch milliseconds, or ISO timestamp with offset');
  const ms = new Date(value).getTime();
  if (!Number.isFinite(ms)) throw new RangeError('Invalid time');
  return ms;
}
export function coordinates(lat, lon) {
  if (!Number.isFinite(lat) || Math.abs(lat) > 90 || !Number.isFinite(lon) || Math.abs(lon) > 180)
    throw new RangeError('Latitude/longitude out of range');
}
export function direction(azimuthDeg, elevationDeg) {
  return { x: sin(azimuthDeg) * cos(elevationDeg), y: sin(elevationDeg), z: -cos(azimuthDeg) * cos(elevationDeg) };
}
export function solarPosition({lat, lon, time}) {
  coordinates(lat, lon);
  const ms = instant(time), jd = ms / 86400000 + 2440587.5;
  const t = (jd - 2451545) / 36525;
  const l0 = wrap(280.46646 + t * (36000.76983 + t * 0.0003032));
  const m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  const e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  const center = sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin(2*m) * (0.019993 - 0.000101*t) + sin(3*m)*0.000289;
  const omega = 125.04 - 1934.136*t;
  const longitude = l0 + center - 0.00569 - 0.00478*sin(omega);
  const obliquity = 23 + (26 + (21.448-t*(46.815+t*(0.00059-t*0.001813)))/60)/60 + 0.00256*cos(omega);
  const declination = Math.asin(sin(obliquity)*sin(longitude));
  const y = Math.tan(obliquity*R/2)**2;
  const equation = 4/R*(y*sin(2*l0)-2*e*sin(m)+4*e*y*sin(m)*cos(2*l0)-0.5*y*y*sin(4*l0)-1.25*e*e*sin(2*m));
  const minutes = ((ms % 86400000)+86400000)%86400000/60000;
  const hourAngleDeg = wrap((minutes + equation + 4*lon)/4)-180;
  const elevationDeg = Math.asin(clamp(sin(lat)*Math.sin(declination)+cos(lat)*Math.cos(declination)*cos(hourAngleDeg)))/R;
  const azimuthDeg = wrap(Math.atan2(sin(hourAngleDeg),cos(hourAngleDeg)*sin(lat)-Math.tan(declination)*cos(lat))/R+180);
  return {azimuthDeg, elevationDeg, direction: direction(azimuthDeg,elevationDeg), hourAngleDeg,
    eclipticLongitudeDeg: wrap(longitude), obliquityDeg: obliquity};
}
// Truncated Meeus ch.47, Tables 47.A/B (largest terms); approximate Moon only.
// No invented moonlight: expose geometric horizon gate; renderer decides illumination.
export function lunarPosition({lat, lon, time}) {
  const sun = solarPosition({lat,lon,time});
  const d = instant(time)/86400000+2440587.5-2451545, t = d/36525;
  const l = wrap(218.3164477+481267.88123421*t-0.0015786*t*t);
  const D = wrap(297.8501921+445267.1114034*t-0.0018819*t*t);
  const M = wrap(357.5291092+35999.0502909*t-0.0001536*t*t);
  const P = wrap(134.9633964+477198.8675055*t+0.0087414*t*t);
  const F = wrap(93.272095+483202.0175233*t-0.0036539*t*t);
  const longitude = l+6.288774*sin(P)+1.274027*sin(2*D-P)+0.658314*sin(2*D)+0.213618*sin(2*P)
    -0.185116*sin(M)-0.114332*sin(2*F)+0.058793*sin(2*D-2*P)+0.057066*sin(2*D-M-P)
    +0.053322*sin(2*D+P)+0.045758*sin(2*D-M)-0.040923*sin(M-P)-0.034720*sin(D);
  const latitude = 5.128122*sin(F)+0.280602*sin(P+F)+0.277693*sin(P-F)+0.173237*sin(2*D-F)
    +0.055413*sin(2*D-P+F)+0.046271*sin(2*D-P-F)+0.032573*sin(2*D+F)+0.017198*sin(2*P+F);
  const distanceKm = 385000.56-20905.355*cos(P)-3699.111*cos(2*D-P)-2955.968*cos(2*D)-569.925*cos(2*P);
  const eps = sun.obliquityDeg;
  const ra = Math.atan2(sin(longitude)*cos(eps)-Math.tan(latitude*R)*sin(eps),cos(longitude))/R;
  const dec = Math.asin(sin(latitude)*cos(eps)+cos(latitude)*sin(eps)*sin(longitude));
  const hourAngle = wrap(280.46061837+360.98564736629*d+0.000387933*t*t-t*t*t/38710000+lon-ra);
  // Spherical sea-level observer subtraction, including lunar parallax.
  const east = -distanceKm*Math.cos(dec)*sin(hourAngle);
  const north = distanceKm*(Math.sin(dec)*cos(lat)-Math.cos(dec)*cos(hourAngle)*sin(lat));
  const up = distanceKm*(Math.sin(dec)*sin(lat)+Math.cos(dec)*cos(hourAngle)*cos(lat))-6378.137;
  const elevationDeg = Math.atan2(up,Math.hypot(east,north))/R;
  const azimuthDeg = wrap(Math.atan2(east,north)/R);
  const elongationDeg = wrap(longitude-sun.eclipticLongitudeDeg);
  const illuminatedFraction = (1-cos(latitude)*cos(elongationDeg))/2;
  return {azimuthDeg,elevationDeg,direction:direction(azimuthDeg,elevationDeg),illuminatedFraction,
    elongationDeg, waxing: elongationDeg < 180, aboveHorizon:elevationDeg>0,
    model:'Meeus47-truncated-spherical-topocentric', approximate:true};
}
