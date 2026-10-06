"""Time scales, reference frames and horizon coordinates (Meeus, Astronomical Algorithms, 2nd ed.).

Conventions used throughout `livefeeds.sky`:
  * instants are POSIX seconds (UTC); UT1 is taken equal to UTC (|UT1-UTC| < 0.9 s by definition of UTC,
    worth at most 13.5 arcsec of hour angle; documented in docs/live-world/sky.md);
  * TT = UTC + leap seconds + 32.184 s from 1972 on (exact), Espenak-Meeus Delta T before;
  * vectors are plain 3-tuples; angles in the public API are degrees.
"""

import math
from typing import Sequence, Tuple

Vec = Tuple[float, float, float]

RAD = math.pi / 180.0
ARCSEC = RAD / 3600.0
AU_KM = 149_597_870.7
C_AU_PER_DAY = 173.1446326846693  # speed of light
J2000 = 2_451_545.0
OBLIQUITY_J2000 = 23.4392911 * RAD  # IAU 1976, used to rotate J2000 ecliptic elements to the J2000 equator

# (POSIX second the offset starts, TAI-UTC). IERS Bulletin C; no leap second since 2017-01-01.
# Bulletin C 72 (July 2026) announced none for the end of 2026; extend this table when one is announced.
LEAP_SECONDS = (
    (63072000, 10), (78796800, 11), (94694400, 12), (126230400, 13), (157766400, 14), (189302400, 15),
    (220924800, 16), (252460800, 17), (283996800, 18), (315532800, 19), (362793600, 20), (394329600, 21),
    (425865600, 22), (489024000, 23), (567993600, 24), (631152000, 25), (662688000, 26), (709948800, 27),
    (741484800, 28), (773020800, 29), (820454400, 30), (867715200, 31), (915148800, 32), (1136073600, 33),
    (1230768000, 34), (1341100800, 35), (1435708800, 36), (1483228800, 37),
)


# -- vectors ------------------------------------------------------------------------------------

def dot(a: Vec, b: Vec) -> float:
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def norm(a: Vec) -> float:
    return math.sqrt(dot(a, a))


def sub(a: Vec, b: Vec) -> Vec:
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def add(a: Vec, b: Vec) -> Vec:
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def scale(a: Vec, k: float) -> Vec:
    return (a[0] * k, a[1] * k, a[2] * k)


def unit(a: Vec) -> Vec:
    n = norm(a)
    return (a[0] / n, a[1] / n, a[2] / n)


def matvec(m: Sequence[Sequence[float]], v: Vec) -> Vec:
    return (m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2],
            m[1][0] * v[0] + m[1][1] * v[1] + m[1][2] * v[2],
            m[2][0] * v[0] + m[2][1] * v[1] + m[2][2] * v[2])


def matmul(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def rot_x(t: float):
    c, s = math.cos(t), math.sin(t)
    return ((1, 0, 0), (0, c, s), (0, -s, c))


def rot_y(t: float):
    c, s = math.cos(t), math.sin(t)
    return ((c, 0, -s), (0, 1, 0), (s, 0, c))


def rot_z(t: float):
    c, s = math.cos(t), math.sin(t)
    return ((c, s, 0), (-s, c, 0), (0, 0, 1))


def wrap360(x: float) -> float:
    return x % 360.0


def wrap180(x: float) -> float:
    return (x + 180.0) % 360.0 - 180.0


# -- time ---------------------------------------------------------------------------------------

def jd_utc(posix: float) -> float:
    return posix / 86400.0 + 2_440_587.5


def tai_minus_utc(posix: float) -> int:
    off = 0
    for start, value in LEAP_SECONDS:
        if posix >= start:
            off = value
    return off


def delta_t(posix: float) -> float:
    """TT - UT in seconds."""
    if posix >= LEAP_SECONDS[0][0]:
        return tai_minus_utc(posix) + 32.184
    t = 1970.0 + posix / (365.25 * 86400.0) - 1975.0  # Espenak-Meeus 1961-1986 segment (pre-1972 callers only)
    return 45.45 + 1.067 * t - t * t / 260.0 - t ** 3 / 718.0


def jd_tt(posix: float) -> float:
    return jd_utc(posix) + delta_t(posix) / 86400.0


def centuries_tt(posix: float) -> float:
    return (jd_tt(posix) - J2000) / 36525.0


def gmst_deg(posix: float) -> float:
    """Greenwich mean sidereal time, degrees (Meeus 12.4, UT1 = UTC)."""
    jd = jd_utc(posix)
    t = (jd - J2000) / 36525.0
    return wrap360(280.46061837 + 360.98564736629 * (jd - J2000) + 0.000387933 * t * t - t ** 3 / 38_710_000.0)


def gast_deg(posix: float) -> float:
    """Greenwich apparent sidereal time, degrees (GMST + equation of the equinoxes)."""
    t = centuries_tt(posix)
    dpsi, deps = nutation(t)
    return wrap360(gmst_deg(posix) + dpsi / 3600.0 * math.cos(true_obliquity(t)))


def lst_deg(posix: float, lon_deg: float) -> float:
    """Local apparent sidereal time, degrees (east longitude positive)."""
    return wrap360(gast_deg(posix) + lon_deg)


# -- precession and nutation ---------------------------------------------------------------------

# IAU 1980 nutation, the 13 largest terms (Meeus table 22.A): D, M, M', F, Omega, psi (1e-4"), psi T, eps, eps T.
# Truncation error is below 0.1 arcsec, which is well inside this module's budget.
_NUT = (
    (0, 0, 0, 0, 1, -171996, -174.2, 92025, 8.9),
    (-2, 0, 0, 2, 2, -13187, -1.6, 5736, -3.1),
    (0, 0, 0, 2, 2, -2274, -0.2, 977, -0.5),
    (0, 0, 0, 0, 2, 2062, 0.2, -895, 0.5),
    (0, 1, 0, 0, 0, 1426, -3.4, 54, -0.1),
    (0, 0, 1, 0, 0, 712, 0.1, -7, 0),
    (-2, 1, 0, 2, 2, -517, 1.2, 224, -0.6),
    (0, 0, 0, 2, 1, -386, -0.4, 200, 0),
    (0, 0, 1, 2, 2, -301, 0, 129, -0.1),
    (-2, -1, 0, 2, 2, 217, -0.5, -95, 0.3),
    (-2, 0, 1, 0, 0, -158, 0, 0, 0),
    (-2, 0, 0, 2, 1, 129, 0.1, -70, 0),
    (0, 0, -1, 2, 2, 123, 0, -53, 0),
)


def nutation(t: float) -> Tuple[float, float]:
    """(delta psi, delta epsilon) in arcseconds for TT centuries since J2000."""
    d = (297.85036 + 445267.111480 * t - 0.0019142 * t * t + t ** 3 / 189474) * RAD
    m = (357.52772 + 35999.050340 * t - 0.0001603 * t * t - t ** 3 / 300000) * RAD
    mp = (134.96298 + 477198.867398 * t + 0.0086972 * t * t + t ** 3 / 56250) * RAD
    f = (93.27191 + 483202.017538 * t - 0.0036825 * t * t + t ** 3 / 327270) * RAD
    om = (125.04452 - 1934.136261 * t + 0.0020708 * t * t + t ** 3 / 450000) * RAD
    dpsi = deps = 0.0
    for cd, cm, cmp, cf, co, ps, pst, ep, ept in _NUT:
        arg = cd * d + cm * m + cmp * mp + cf * f + co * om
        dpsi += (ps + pst * t) * math.sin(arg)
        deps += (ep + ept * t) * math.cos(arg)
    return dpsi * 1e-4, deps * 1e-4


def mean_obliquity(t: float) -> float:
    """Radians (Meeus 22.2)."""
    return (23.439291111 - (46.8150 * t + 0.00059 * t * t - 0.001813 * t ** 3) / 3600.0) * RAD


def true_obliquity(t: float) -> float:
    return mean_obliquity(t) + nutation(t)[1] * ARCSEC


def precession_matrix(t: float):
    """J2000 mean equator -> mean equator of date (Meeus 21.2/21.3 rigorous angles)."""
    zeta = (2306.2181 * t + 0.30188 * t * t + 0.017998 * t ** 3) * ARCSEC
    z = (2306.2181 * t + 1.09468 * t * t + 0.018203 * t ** 3) * ARCSEC
    theta = (2004.3109 * t - 0.42665 * t * t - 0.041833 * t ** 3) * ARCSEC
    return matmul(rot_z(-z), matmul(rot_y(theta), rot_z(-zeta)))


def nutation_matrix(t: float):
    """Mean equator of date -> true equator of date."""
    dpsi, deps = nutation(t)
    eps0 = mean_obliquity(t)
    eps = eps0 + deps * ARCSEC
    return matmul(rot_x(-eps), matmul(rot_z(-dpsi * ARCSEC), rot_x(eps0)))


def j2000_to_date_matrix(t: float):
    return matmul(nutation_matrix(t), precession_matrix(t))


def ecliptic_j2000_to_equatorial_j2000(v: Vec) -> Vec:
    return matvec(rot_x(-OBLIQUITY_J2000), v)


# -- spherical and horizon coordinates ----------------------------------------------------------

def ra_dec(v: Vec) -> Tuple[float, float]:
    """Degrees: right ascension in [0, 360), declination."""
    r = norm(v)
    return wrap360(math.atan2(v[1], v[0]) / RAD), math.asin(max(-1.0, min(1.0, v[2] / r))) / RAD


def from_ra_dec(ra_deg: float, dec_deg: float, r: float = 1.0) -> Vec:
    a, d = ra_deg * RAD, dec_deg * RAD
    return (r * math.cos(d) * math.cos(a), r * math.cos(d) * math.sin(a), r * math.sin(d))


def observer_vector_km(lat_deg: float, lon_deg: float, elev_m: float, lst: float) -> Vec:
    """Observer in the true equator-of-date frame, km (WGS84 ellipsoid); `lst` in degrees."""
    a, f = 6378.137, 1 / 298.257223563
    phi = lat_deg * RAD
    c = 1 / math.sqrt(math.cos(phi) ** 2 + (1 - f) ** 2 * math.sin(phi) ** 2)
    s = (1 - f) ** 2 * c
    h = elev_m / 1000.0
    rxy = (a * c + h) * math.cos(phi)
    th = lst * RAD
    return (rxy * math.cos(th), rxy * math.sin(th), (a * s + h) * math.sin(phi))


def alt_az(v_date: Vec, lat_deg: float, lst: float) -> Tuple[float, float]:
    """Geometric altitude and azimuth (degrees, azimuth from north through east) of a topocentric
    true-equator-of-date vector."""
    ra, dec = ra_dec(v_date)
    h = (lst - ra) * RAD
    d, phi = dec * RAD, lat_deg * RAD
    alt = math.asin(max(-1.0, min(1.0, math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(h))))
    az = math.atan2(-math.cos(d) * math.sin(h), math.sin(d) * math.cos(phi) - math.cos(d) * math.cos(h) * math.sin(phi))
    return alt / RAD, wrap360(az / RAD)


def refraction_deg(alt_geometric: float, pressure_hpa: float = 1010.0, temp_c: float = 10.0) -> float:
    """Atmospheric refraction to add to a geometric altitude (Saemundsson, Meeus 16.4), degrees.
    Returns 0 well below the horizon, where the formula is meaningless."""
    if alt_geometric < -1.9:
        return 0.0
    h = max(alt_geometric, -1.9)
    r = 1.02 / math.tan((h + 10.3 / (h + 5.11)) * RAD)  # arcminutes
    return max(r, 0.0) * (pressure_hpa / 1010.0) * (283.0 / (273.0 + temp_c)) / 60.0


def airmass(alt_apparent: float) -> float:
    """Kasten & Young (1989) relative air mass; large but finite at the horizon."""
    if alt_apparent <= -1.0:
        return float("inf")
    z = 90.0 - max(alt_apparent, 0.0)
    return 1.0 / (math.cos(z * RAD) + 0.50572 * (96.07995 - z) ** -1.6364)


def angular_separation_deg(a: Vec, b: Vec) -> float:
    c = dot(unit(a), unit(b))
    return math.acos(max(-1.0, min(1.0, c))) / RAD
