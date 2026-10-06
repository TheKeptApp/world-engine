"""Sun, Moon and planets: apparent topocentric positions, distance, phase and magnitude.

Planets and the Earth-Moon barycentre: E. M. Standish, "Keplerian Elements for Approximate Positions of
the Major Planets" (JPL Solar System Dynamics, table 1, valid 1800-2050 AD), a fit to JPL DE405. Stated
heliocentric errors are seconds to a few arcminutes of arc (largest for Saturn). Moon: Meeus chapter 47
(ELP-2000/82 truncated, about 10 arcsec in longitude). Pipeline per body (Meeus chapters 23, 33, 40):
light time, annual aberration (first order, from the Earth's velocity), precession and nutation to the
true equator of date, topocentric parallax by vector subtraction, then horizon coordinates and refraction.
"""

import math
from dataclasses import dataclass
from typing import Dict, Optional, Tuple

from . import astro
from .astro import RAD, Vec
from .moontables import B_TERMS, LR_TERMS

VALID_FROM = -5364662400  # 1800-01-01
VALID_UNTIL = 2556143999  # 2050-12-31 23:59:59

# a (au), e, I, L, long. perihelion, long. node (deg), each followed by its rate per Julian century.
STANDISH = {
    "mercury": ((0.38709927, 0.00000037), (0.20563593, 0.00001906), (7.00497902, -0.00594749),
                (252.25032350, 149472.67411175), (77.45779628, 0.16047689), (48.33076593, -0.12534081)),
    "venus": ((0.72333566, 0.00000390), (0.00677672, -0.00004107), (3.39467605, -0.00078890),
              (181.97909950, 58517.81538729), (131.60246718, 0.00268329), (76.67984255, -0.27769418)),
    "emb": ((1.00000261, 0.00000562), (0.01671123, -0.00004392), (-0.00001531, -0.01294668),
            (100.46457166, 35999.37244981), (102.93768193, 0.32327364), (0.0, 0.0)),
    "mars": ((1.52371034, 0.00001847), (0.09339410, 0.00007882), (1.84969142, -0.00813131),
             (-4.55343205, 19140.30268499), (-23.94362959, 0.44441088), (49.55953891, -0.29257343)),
    "jupiter": ((5.20288700, -0.00011607), (0.04838624, -0.00013253), (1.30439695, -0.00183714),
                (34.39644051, 3034.74612775), (14.72847983, 0.21252668), (100.47390909, 0.20469106)),
    "saturn": ((9.53667594, -0.00125060), (0.05386179, -0.00050991), (2.48599187, 0.00193609),
               (49.95424423, 1222.49362201), (92.59887831, -0.41897216), (113.66242448, -0.28867794)),
    "uranus": ((19.18916464, -0.00196176), (0.04725744, -0.00004397), (0.77263783, -0.00242939),
               (313.23810451, 428.48202785), (170.95427630, 0.40805281), (74.01692503, 0.04240589)),
    "neptune": ((30.06992276, 0.00026291), (0.00859048, 0.00005105), (1.77004347, 0.00035372),
                (-55.12002969, 218.45945325), (44.96476227, -0.32241464), (131.78422574, -0.00508664)),
}
PLANETS = ("mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune")
EARTH_MOON_MASS_RATIO = 81.30056
MOON_RADIUS_KM = 1737.4
SUN_RADIUS_KM = 696_000.0
# Saturn's north ring-plane pole, J2000 equatorial (IAU WGCCRE 2015: RA 40.589, Dec 83.537 deg).
SATURN_POLE = astro.from_ra_dec(40.589, 83.537)


class OutOfRange(ValueError):
    pass


def _check(posix: float) -> None:
    if not (VALID_FROM <= posix <= VALID_UNTIL):
        raise OutOfRange("planetary elements are valid 1800-2050 only")


def heliocentric_ecliptic(body: str, t: float) -> Vec:
    """Heliocentric ecliptic-and-equinox-J2000 position (au), t in TT centuries since J2000."""
    (a, ad), (e, ed), (i, idot), (l, ldot), (w, wdot), (o, odot) = STANDISH[body]
    a, e = a + ad * t, e + ed * t
    i, l, w, o = (i + idot * t) * RAD, (l + ldot * t) * RAD, (w + wdot * t) * RAD, (o + odot * t) * RAD
    arg_peri = w - o
    m = math.remainder(l - w, 2 * math.pi)
    big_e = m + e * math.sin(m)
    for _ in range(15):
        d = (big_e - e * math.sin(big_e) - m) / (1 - e * math.cos(big_e))
        big_e -= d
        if abs(d) < 1e-14:
            break
    xp, yp = a * (math.cos(big_e) - e), a * math.sqrt(1 - e * e) * math.sin(big_e)
    cw, sw, co, so, ci, si = math.cos(arg_peri), math.sin(arg_peri), math.cos(o), math.sin(o), math.cos(i), math.sin(i)
    return ((cw * co - sw * so * ci) * xp + (-sw * co - cw * so * ci) * yp,
            (cw * so + sw * co * ci) * xp + (-sw * so + cw * co * ci) * yp,
            (sw * si) * xp + (cw * si) * yp)


def moon_ecliptic_of_date(t: float) -> Tuple[float, float, float]:
    """Geometric geocentric ecliptic longitude, latitude (deg, mean equinox of date) and distance (km)."""
    t2, t3, t4 = t * t, t ** 3, t ** 4
    lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000
    d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000
    m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000
    mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000
    f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000
    a1, a2, a3 = 119.75 + 131.849 * t, 53.09 + 479264.290 * t, 313.45 + 481266.484 * t
    ecc = 1 - 0.002516 * t - 0.0000074 * t2
    sl = sr = sb = 0.0
    for cd, cm, cmp, cf, vl, vr in LR_TERMS:
        arg = (cd * d + cm * m + cmp * mp + cf * f) * RAD
        k = ecc ** abs(cm)
        sl += vl * k * math.sin(arg)
        sr += vr * k * math.cos(arg)
    for cd, cm, cmp, cf, vb in B_TERMS:
        arg = (cd * d + cm * m + cmp * mp + cf * f) * RAD
        sb += vb * ecc ** abs(cm) * math.sin(arg)
    sl += 3958 * math.sin(a1 * RAD) + 1962 * math.sin((lp - f) * RAD) + 318 * math.sin(a2 * RAD)
    sb += (-2235 * math.sin(lp * RAD) + 382 * math.sin(a3 * RAD) + 175 * math.sin((a1 - f) * RAD)
           + 175 * math.sin((a1 + f) * RAD) + 127 * math.sin((lp - mp) * RAD) - 115 * math.sin((lp + mp) * RAD))
    return astro.wrap360(lp + sl / 1e6), sb / 1e6, 385000.56 + sr / 1000.0


def moon_geocentric_date_km(t: float) -> Vec:
    """Apparent geocentric Moon, true equator and equinox of date, km."""
    lon, lat, dist = moon_ecliptic_of_date(t)
    dpsi, _ = astro.nutation(t)
    lam, beta, eps = (lon + dpsi / 3600.0) * RAD, lat * RAD, astro.true_obliquity(t)
    v = (dist * math.cos(beta) * math.cos(lam), dist * math.cos(beta) * math.sin(lam), dist * math.sin(beta))
    return astro.matvec(astro.rot_x(-eps), v)


def earth_heliocentric(t: float) -> Vec:
    """Heliocentric Earth (au, ecliptic J2000): barycentre minus the Moon's share."""
    emb = heliocentric_ecliptic("emb", t)
    lon, lat, dist = moon_ecliptic_of_date(t)
    lam, beta = lon * RAD, lat * RAD
    r = dist / astro.AU_KM / (1 + EARTH_MOON_MASS_RATIO)
    return (emb[0] - r * math.cos(beta) * math.cos(lam), emb[1] - r * math.cos(beta) * math.sin(lam),
            emb[2] - r * math.sin(beta))


def earth_velocity(t: float) -> Vec:
    """Earth heliocentric velocity, au/day (ecliptic J2000), by central difference over +-0.05 day."""
    h = 0.05 / 36525.0
    a, b = heliocentric_ecliptic("emb", t + h), heliocentric_ecliptic("emb", t - h)
    return astro.scale(astro.sub(a, b), 1 / 0.1)


@dataclass
class Observer:
    lat: float
    lon: float
    elev_m: float = 0.0
    pressure_hpa: float = 1010.0
    temp_c: float = 10.0


@dataclass
class Frame:
    """Everything that depends only on the instant and the observer."""
    posix: float
    t: float           # TT centuries since J2000
    lst: float         # local apparent sidereal time, degrees
    to_date: tuple     # J2000 equator -> true equator of date
    earth: Vec         # heliocentric Earth, au, ecliptic J2000
    v_earth: Vec       # au/day, equatorial J2000
    observer_km: Vec   # true equator of date

    @classmethod
    def make(cls, posix: float, obs: Observer) -> "Frame":
        t = astro.centuries_tt(posix)
        lst = astro.lst_deg(posix, obs.lon)
        return cls(posix, t, lst, astro.j2000_to_date_matrix(t), earth_heliocentric(t),
                   astro.ecliptic_j2000_to_equatorial_j2000(earth_velocity(t)),
                   astro.observer_vector_km(obs.lat, obs.lon, obs.elev_m, lst))


def aberrate(u: Vec, v_earth: Vec) -> Vec:
    """First-order annual aberration of a J2000 unit direction (about 20 arcsec)."""
    k = 1 / astro.C_AU_PER_DAY
    return astro.unit(astro.add(u, astro.scale(v_earth, k)))


def _geocentric_body_j2000_au(body: str, fr: Frame) -> Tuple[Vec, Vec, float]:
    """(astrometric geocentric equatorial J2000 au, heliocentric ecliptic J2000 au, light time days)."""
    tau = 0.0
    for _ in range(3):
        tb = fr.t - tau / 36525.0
        p = (0.0, 0.0, 0.0) if body == "sun" else heliocentric_ecliptic(body, tb)
        g = astro.sub(p, fr.earth)
        tau = astro.norm(g) / astro.C_AU_PER_DAY
    return astro.ecliptic_j2000_to_equatorial_j2000(g), p, tau


def apparent_topocentric_km(body: str, fr: Frame) -> Tuple[Vec, Optional[Vec]]:
    """Topocentric apparent position (km, true equator of date) and, for planets, the heliocentric
    position (au, ecliptic J2000) used for phase and magnitude."""
    if body == "moon":
        return astro.sub(moon_geocentric_date_km(fr.t), fr.observer_km), None
    g, helio, _ = _geocentric_body_j2000_au(body, fr)
    dist_km = astro.norm(g) * astro.AU_KM
    u = aberrate(astro.unit(g), fr.v_earth)
    geo = astro.scale(astro.matvec(fr.to_date, u), dist_km)
    return astro.sub(geo, fr.observer_km), (None if body == "sun" else helio)


def horizon(v_date: Vec, fr: Frame, obs: Observer) -> Dict[str, float]:
    alt, az = astro.alt_az(v_date, obs.lat, fr.lst)
    ra, dec = astro.ra_dec(v_date)
    return {"altDeg": alt, "apparentAltDeg": alt + astro.refraction_deg(alt, obs.pressure_hpa, obs.temp_c),
            "azDeg": az, "raDeg": ra, "decDeg": dec}


def planet_magnitude(body: str, r_au: float, delta_au: float, phase_deg: float,
                     ring_tilt_deg: float = 0.0) -> float:
    """Visual magnitude, Meeus chapter 41 (G. Muller / Astronomical Almanac 1984 expressions).
    Saturn omits the small Sun-Earth ring-longitude term (<= 0.1 mag)."""
    base = 5 * math.log10(r_au * delta_au)
    i = phase_deg
    if body == "mercury":
        return -0.42 + base + 0.0380 * i - 0.000273 * i * i + 0.000002 * i ** 3
    if body == "venus":
        return -4.40 + base + 0.0009 * i + 0.000239 * i * i - 0.00000065 * i ** 3
    if body == "mars":
        return -1.52 + base + 0.016 * i
    if body == "jupiter":
        return -9.40 + base + 0.005 * i
    if body == "saturn":
        sb = math.sin(abs(ring_tilt_deg) * RAD)
        return -8.88 + base - 2.60 * sb + 1.25 * sb * sb
    if body == "uranus":
        return -7.19 + base
    if body == "neptune":
        return -6.87 + base
    raise KeyError(body)


def solar_system(posix: float, obs: Observer) -> Dict[str, dict]:
    """Sun, Moon and seven planets for one instant and place (all angles degrees)."""
    _check(posix)
    fr = Frame.make(posix, obs)
    out: Dict[str, dict] = {}
    sun_v, _ = apparent_topocentric_km("sun", fr)
    out["sun"] = dict(horizon(sun_v, fr, obs), distanceAu=astro.norm(sun_v) / astro.AU_KM,
                      angularDiameterDeg=2 * math.degrees(math.asin(SUN_RADIUS_KM / astro.norm(sun_v))),
                      magnitude=-26.74)
    moon_v, _ = apparent_topocentric_km("moon", fr)
    # Phase angle: the angle Sun-Moon-observer.
    i = astro.angular_separation_deg(astro.sub(sun_v, moon_v), astro.scale(moon_v, -1))
    k = (1 + math.cos(i * RAD)) / 2
    lon_m, _, _ = moon_ecliptic_of_date(fr.t)
    sun_lon = _ecliptic_longitude_of_date(sun_v, fr.t)
    elong = astro.wrap360(lon_m - sun_lon)
    sun_ra, sun_dec = astro.ra_dec(sun_v)
    m_ra, m_dec = astro.ra_dec(moon_v)
    chi = math.degrees(math.atan2(
        math.cos(math.radians(sun_dec)) * math.sin(math.radians(sun_ra - m_ra)),
        math.sin(math.radians(sun_dec)) * math.cos(math.radians(m_dec))
        - math.cos(math.radians(sun_dec)) * math.sin(math.radians(m_dec)) * math.cos(math.radians(sun_ra - m_ra))))
    ha = math.radians(fr.lst - m_ra)
    q = math.degrees(math.atan2(math.sin(ha), math.tan(math.radians(obs.lat)) * math.cos(math.radians(m_dec))
                                - math.sin(math.radians(m_dec)) * math.cos(ha)))
    dist = astro.norm(moon_v)
    out["moon"] = dict(horizon(moon_v, fr, obs), distanceKm=dist,
                       angularDiameterDeg=2 * math.degrees(math.asin(MOON_RADIUS_KM / dist)),
                       phaseAngleDeg=i, illuminatedFraction=k, elongationLongitudeDeg=elong,
                       phaseName=moon_phase_name(k, elong),
                       ageDays=elong / 360.0 * 29.530589,
                       brightLimbPositionAngleDeg=astro.wrap360(chi),
                       brightLimbFromZenithDeg=astro.wrap180(chi - q),
                       magnitude=moon_magnitude(i, dist))
    for body in PLANETS:
        v, helio = apparent_topocentric_km(body, fr)
        delta = astro.norm(v) / astro.AU_KM
        r = astro.norm(helio)
        phase = math.degrees(math.acos(max(-1.0, min(1.0, (r * r + delta * delta - astro.norm(fr.earth) ** 2)
                                                         / (2 * r * delta)))))
        tilt = 0.0
        if body == "saturn":
            g, _, _ = _geocentric_body_j2000_au(body, fr)
            tilt = math.degrees(math.asin(astro.dot(astro.unit(g), SATURN_POLE)))
        out[body] = dict(horizon(v, fr, obs), distanceAu=delta, heliocentricDistanceAu=r, phaseAngleDeg=phase,
                         illuminatedFraction=(1 + math.cos(phase * RAD)) / 2,
                         magnitude=planet_magnitude(body, r, delta, phase, tilt))
        if body == "saturn":
            out[body]["ringTiltDeg"] = -tilt
    return out


def _ecliptic_longitude_of_date(v_date: Vec, t: float) -> float:
    eps = astro.true_obliquity(t)
    e = astro.matvec(astro.rot_x(eps), v_date)
    return astro.wrap360(math.degrees(math.atan2(e[1], e[0])))


def moon_phase_name(k: float, elong: float) -> str:
    """Name from the illuminated fraction and the Sun-Moon longitude difference (0 new, 180 full)."""
    if k >= 0.98:
        return "full"
    if k <= 0.02:
        return "new"
    if abs(k - 0.5) < 0.03:
        return "firstQuarter" if elong < 180 else "lastQuarter"
    return ("waxing" if elong < 180 else "waning") + ("Gibbous" if k > 0.5 else "Crescent")


def moon_magnitude(phase_deg: float, dist_km: float) -> float:
    """Allen (1976) style approximation used by many planetaria: -12.73 at full, plus the phase law
    0.026|i| + 4e-9 i^4 (Krisciunas & Schaefer 1991), scaled for distance."""
    i = abs(phase_deg)
    return -12.73 + 0.026 * i + 4e-9 * i ** 4 + 5 * math.log10(dist_km / 384400.0)
