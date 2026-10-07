"""Observer geometry, sunlight, passes and visibility for SGP4 satellites.

Frames: SGP4 gives TEME; TEME is turned to Earth-fixed by GMST (IAU 1982, UT1 = UTC; polar motion ignored,
a few metres). The observer sits on the WGS84 ellipsoid. A satellite is sunlit unless it is inside the Earth's
cylindrical shadow (no penumbra; entry and exit times are good to about 10 s). A pass is visible to the eye
where the satellite is sunlit, at least 10 degrees up, and the Sun is at least 6 degrees below the observer's
horizon (civil twilight or darker), the usual rule of NASA's Spot the Station and Heavens-Above.
"""

import math
from dataclasses import dataclass
from typing import List, Optional, Tuple

from .sgp4 import PropagationError, Satellite

D2R = math.pi / 180
RE_KM = 6378.137
F_WGS84 = 1 / 298.257223563
MIN_PASS_ALT = 10.0       # degrees: passes whose maximum is lower are not reported
VISIBLE_MIN_ALT = 10.0
SUN_MAX_ALT_FOR_VISIBLE = -6.0
STEP_S = 20.0
VIS_STEP_S = 5.0
TRACK_STEP_S = 10.0

Vec = Tuple[float, float, float]


def gmst_rad(posix: float) -> float:
    """Vallado's gstime (IAU 1982), the angle SGP4's TEME is defined against."""
    jd = posix / 86400.0 + 2440587.5
    tut1 = (jd - 2451545.0) / 36525.0
    temp = (-6.2e-6 * tut1 ** 3 + 0.093104 * tut1 ** 2 + (876600.0 * 3600 + 8640184.812866) * tut1 + 67310.54841)
    return math.fmod(temp * D2R / 240.0, 2 * math.pi) % (2 * math.pi)


def teme_to_ecef(r: Vec, posix: float) -> Vec:
    g = gmst_rad(posix)
    c, s = math.cos(g), math.sin(g)
    return (c * r[0] + s * r[1], -s * r[0] + c * r[1], r[2])


def observer_ecef(lat: float, lon: float, elev_m: float) -> Vec:
    phi, lam = lat * D2R, lon * D2R
    e2 = F_WGS84 * (2 - F_WGS84)
    n = RE_KM / math.sqrt(1 - e2 * math.sin(phi) ** 2)
    h = elev_m / 1000.0
    return ((n + h) * math.cos(phi) * math.cos(lam), (n + h) * math.cos(phi) * math.sin(lam),
            (n * (1 - e2) + h) * math.sin(phi))


def geodetic(r_ecef: Vec) -> Tuple[float, float, float]:
    """(lat, lon, height km) on WGS84."""
    x, y, z = r_ecef
    e2 = F_WGS84 * (2 - F_WGS84)
    lon = math.atan2(y, x)
    p = math.hypot(x, y)
    lat = math.atan2(z, p * (1 - e2))
    for _ in range(6):
        n = RE_KM / math.sqrt(1 - e2 * math.sin(lat) ** 2)
        h = p / math.cos(lat) - n
        lat = math.atan2(z, p * (1 - e2 * n / (n + h)))
    n = RE_KM / math.sqrt(1 - e2 * math.sin(lat) ** 2)
    return lat / D2R, lon / D2R, p / math.cos(lat) - n


def look_angles(rho: Vec, lat: float, lon: float) -> Tuple[float, float, float]:
    """(altitude deg, azimuth deg from north through east, range km) of an Earth-fixed offset vector."""
    phi, lam = lat * D2R, lon * D2R
    sp, cp, sl, cl = math.sin(phi), math.cos(phi), math.sin(lam), math.cos(lam)
    s = sp * cl * rho[0] + sp * sl * rho[1] - cp * rho[2]
    e = -sl * rho[0] + cl * rho[1]
    z = cp * cl * rho[0] + cp * sl * rho[1] + sp * rho[2]
    rng = math.sqrt(s * s + e * e + z * z)
    return math.asin(max(-1.0, min(1.0, z / rng))) / D2R, math.atan2(e, -s) / D2R % 360.0, rng


def sun_eci_unit(posix: float) -> Vec:
    """Low-precision apparent Sun direction (Meeus 25, about 0.01 deg), true equator of date."""
    jd = posix / 86400.0 + 2440587.5 + 69.184 / 86400.0
    t = (jd - 2451545.0) / 36525.0
    l0 = 280.46646 + 36000.76983 * t
    m = (357.52911 + 35999.05029 * t) * D2R
    c = ((1.914602 - 0.004817 * t) * math.sin(m) + 0.019993 * math.sin(2 * m) + 0.000289 * math.sin(3 * m))
    om = (125.04 - 1934.136 * t) * D2R
    lam = (l0 + c - 0.00569 - 0.00478 * math.sin(om)) * D2R
    eps = (23.439291 - 0.0130042 * t + 0.00256 * math.cos(om)) * D2R
    return (math.cos(lam), math.cos(eps) * math.sin(lam), math.sin(eps) * math.sin(lam))


def sunlit(r_eci: Vec, sun_u: Vec) -> bool:
    d = r_eci[0] * sun_u[0] + r_eci[1] * sun_u[1] + r_eci[2] * sun_u[2]
    if d >= 0:
        return True
    perp = (r_eci[0] - d * sun_u[0], r_eci[1] - d * sun_u[1], r_eci[2] - d * sun_u[2])
    return math.sqrt(perp[0] ** 2 + perp[1] ** 2 + perp[2] ** 2) > RE_KM


def magnitude(std_mag: Optional[float], range_km: float, phase_rad: float) -> Optional[float]:
    """Diffuse-sphere estimate from a standard magnitude (at 1000 km, phase angle 90 deg)."""
    if std_mag is None:
        return None
    f = (math.pi - phase_rad) * math.cos(phase_rad) + math.sin(phase_rad)
    if f <= 1e-6:
        return None
    return std_mag + 5 * math.log10(range_km / 1000.0) - 2.5 * math.log10(f)


@dataclass
class Observation:
    t: float
    alt: float
    az: float
    range_km: float
    sunlit: bool
    sun_alt: float
    phase_rad: float
    lat: float
    lon: float
    height_km: float


class Observer:
    def __init__(self, lat: float, lon: float, elev_m: float = 0.0):
        self.lat, self.lon, self.elev_m = lat, lon, elev_m
        self.ecef = observer_ecef(lat, lon, elev_m)

    def observe(self, sat: Satellite, t: float) -> Observation:
        r, _ = sat.propagate(t)
        re = teme_to_ecef(r, t)
        rho = (re[0] - self.ecef[0], re[1] - self.ecef[1], re[2] - self.ecef[2])
        alt, az, rng = look_angles(rho, self.lat, self.lon)
        su = sun_eci_unit(t)
        su_e = teme_to_ecef(su, t)
        sun_alt, _, _ = look_angles(su_e, self.lat, self.lon)
        # Phase angle Sun-satellite-observer (Sun at infinity).
        to_obs = (-rho[0] / rng, -rho[1] / rng, -rho[2] / rng)
        cosph = su_e[0] * to_obs[0] + su_e[1] * to_obs[1] + su_e[2] * to_obs[2]
        lat, lon, h = geodetic(re)
        return Observation(t, alt, az, rng, sunlit(r, su), sun_alt, math.acos(max(-1.0, min(1.0, cosph))),
                           lat, lon, h)

    def altitude(self, sat: Satellite, t: float) -> float:
        r, _ = sat.propagate(t)
        re = teme_to_ecef(r, t)
        return look_angles((re[0] - self.ecef[0], re[1] - self.ecef[1], re[2] - self.ecef[2]), self.lat, self.lon)[0]


def _bisect(f, a: float, b: float, rising: bool, tol: float = 0.5) -> float:
    while b - a > tol:
        m = (a + b) / 2
        if (f(m) > 0) == rising:
            b = m
        else:
            a = m
    return (a + b) / 2


def _maximize(f, a: float, b: float, tol: float = 0.5) -> float:
    g = (math.sqrt(5) - 1) / 2
    c, d = b - g * (b - a), a + g * (b - a)
    fc, fd = f(c), f(d)
    while b - a > tol:
        if fc > fd:
            b, d, fd = d, c, fc
            c = b - g * (b - a)
            fc = f(c)
        else:
            a, c, fc = c, d, fd
            d = a + g * (b - a)
            fd = f(d)
    return (a + b) / 2


def _point(o: Observation, std_mag: Optional[float]) -> dict:
    m = magnitude(std_mag, o.range_km, o.phase_rad) if o.sunlit else None
    return {"t": round(o.t, 1), "altDeg": round(o.alt, 3), "azDeg": round(o.az, 3), "rangeKm": round(o.range_km, 1),
            "sunlit": o.sunlit, "magnitude": None if m is None else round(m, 2)}


def find_passes(sat: Satellite, obs: Observer, start: float, end: float,
                std_mag: Optional[float] = None) -> List[dict]:
    """Passes above the horizon in [start, end] whose maximum altitude reaches MIN_PASS_ALT."""
    def f(t):
        return obs.altitude(sat, t)

    passes = []
    t = start
    prev = f(t)
    rise = start if prev > 0 else None
    while t < end:
        t2 = min(t + STEP_S, end)
        cur = f(t2)
        if prev <= 0 < cur:
            rise = _bisect(f, t, t2, True)
        elif prev > 0 >= cur and rise is not None:
            passes.append((rise, _bisect(f, t, t2, False), rise == start, False))
            rise = None
        prev, t = cur, t2
    if rise is not None:
        passes.append((rise, end, rise == start, True))

    out = []
    for rise, set_, cut_start, cut_end in passes:
        tc = _maximize(f, rise, set_)
        top = obs.observe(sat, tc)
        if top.alt < MIN_PASS_ALT:
            continue
        samples = []
        n = max(2, int(math.ceil((set_ - rise) / VIS_STEP_S)) + 1)
        for i in range(n):
            ti = rise + (set_ - rise) * i / (n - 1)
            samples.append(obs.observe(sat, ti))
        vis = [o for o in samples if o.sunlit and o.alt >= VISIBLE_MIN_ALT and o.sun_alt <= SUN_MAX_ALT_FOR_VISIBLE]
        rec = {
            "rise": _point(obs.observe(sat, rise), std_mag), "culmination": _point(top, std_mag),
            "set": _point(obs.observe(sat, set_), std_mag),
            "startsBeforeWindow": cut_start, "endsAfterWindow": cut_end,
            "visible": bool(vis), "basis": "forecast",
        }
        if vis:
            v0, v1 = vis[0].t, vis[-1].t
            track = [obs.observe(sat, v0 + k * TRACK_STEP_S) for k in range(int((v1 - v0) // TRACK_STEP_S) + 1)]
            if track[-1].t < v1:
                track.append(obs.observe(sat, v1))
            mags = [magnitude(std_mag, o.range_km, o.phase_rad) for o in vis]
            mags = [m for m in mags if m is not None]
            rec["visibleWindow"] = {
                "start": _point(vis[0], std_mag), "end": _point(vis[-1], std_mag),
                "maxAltDeg": round(max(o.alt for o in vis), 3),
                "brightestMagnitude": round(min(mags), 2) if mags else None,
                "endsInShadow": not samples[min(len(samples) - 1, samples.index(vis[-1]) + 1)].sunlit,
                "track": [_point(o, std_mag) for o in track],
            }
        out.append(rec)
    return out
