"""Shared test vectors for the on-device Swift port (`Sources/LiveSky`), exported from this reference code.

    Tools/livefeeds/livefeeds.sh vectors [OUT]     # default Tests/LiveSkyTests/Fixtures/live-sky-vectors.json

The Python modules stay the oracle: the Swift tests read this file and must reproduce every value within the
tolerances listed in it. `tests/test_vectors.py` regenerates the vectors in memory and fails when the committed
file no longer matches the Python output, so the two cannot drift silently. Deterministic: inputs are fixed
instants and places, no clock and no network.
"""

import json
import math
import os
from typing import List

from .sats import passes as sp
from .sats.elements import parse_omm_json, parse_tle
from .sats.sgp4 import Satellite
from .sky import astro, bodies, skyglow, stars
from .sky.bodies import Frame, Observer

SCHEMA = "worldengine.live-sky-vectors/1"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DEFAULT_OUT = os.path.join(REPO_ROOT, "Tests", "LiveSkyTests", "Fixtures", "live-sky-vectors.json")

PLACES = [
    {"name": "Chicago", "lat": 41.8781, "lon": -87.6298, "elevM": 181.0},
    {"name": "Denver", "lat": 39.7392, "lon": -104.9903, "elevM": 1609.0},
    {"name": "Miami", "lat": 25.7617, "lon": -80.1918, "elevM": 2.0},
]
INSTANTS = [
    1791259200,   # 2026-10-06T04:00:00Z
    1766534400,   # 2025-12-24T00:00:00Z
    1814472000,   # 2027-07-01T12:00:00Z
]
TIME_INSTANTS = [946728000, 1136073599, 1483228800, 1791259200, 1814472000]  # J2000 noon, leap-second edges, ...

ISS_2008 = ("ISS (ZARYA)", "1 25544U 98067A   08264.51782528 -.00002182  00000-0 -11606-4 0  2927",
            "2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.72125391563537")
V5 = ("00005", "1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
      "2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667")
OMM_SAMPLE = [{
    "OBJECT_NAME": "ISS (ZARYA)", "OBJECT_ID": "1998-067A", "EPOCH": "2008-09-20T12:25:40.104192",
    "MEAN_MOTION": 15.72125391, "ECCENTRICITY": 0.0006703, "INCLINATION": 51.6416,
    "RA_OF_ASC_NODE": 247.4627, "ARG_OF_PERICENTER": 130.536, "MEAN_ANOMALY": 325.0288,
    "EPHEMERIS_TYPE": 0, "CLASSIFICATION_TYPE": "U", "NORAD_CAT_ID": 25544, "ELEMENT_SET_NO": 292,
    "REV_AT_EPOCH": 56353, "BSTAR": -1.1606e-05, "MEAN_MOTION_DOT": -2.182e-05, "MEAN_MOTION_DDOT": 0,
}]

# Agreement the Swift port must reach (both sides are IEEE double; differences come only from the order of
# floating-point operations and libm). Angles in degrees, distances as named.
TOLERANCES = {
    "angleDeg": 1e-7, "timeDays": 1e-10, "deltaTSeconds": 1e-6, "distanceKm": 1e-4, "distanceAu": 1e-10,
    "magnitude": 1e-7, "fraction": 1e-9, "sgp4PositionKm": 1e-6, "sgp4VelocityKmS": 1e-9,
    "skyMag": 1e-7, "radiance": 1e-9,
    # Pass records are rounded by the reference (t 0.1 s, angles 0.001 deg, range 0.1 km, magnitude 0.01), so a
    # value on a rounding edge may differ by one unit in the last place.
    "passTimeSeconds": 0.15, "passAngleDeg": 0.0015, "passRangeKm": 0.15, "passMagnitude": 0.015,
}


def _vec(v) -> List[float]:
    return [float(x) for x in v]


def _time_vectors():
    out = []
    for t in TIME_INSTANTS:
        tc = astro.centuries_tt(t)
        dpsi, deps = astro.nutation(tc)
        out.append({"posix": t, "jdUtc": astro.jd_utc(t), "deltaTSeconds": astro.delta_t(t), "jdTt": astro.jd_tt(t),
                    "centuriesTt": tc, "gmstDeg": astro.gmst_deg(t), "gastDeg": astro.gast_deg(t),
                    "lstDegChicago": astro.lst_deg(t, PLACES[0]["lon"]), "nutationLonArcsec": dpsi,
                    "nutationOblArcsec": deps, "meanObliquityRad": astro.mean_obliquity(tc),
                    "trueObliquityRad": astro.true_obliquity(tc), "refractionDegAt10": astro.refraction_deg(10.0),
                    "airmassAt30": astro.airmass(30.0)})
    return out


def _sky_vectors(catalog: dict, star_count: int):
    out = []
    subset = {"stars": catalog["stars"][:star_count]}
    for p in PLACES:
        obs = Observer(p["lat"], p["lon"], p["elevM"])
        for t in INSTANTS:
            ss = bodies.solar_system(t, obs)
            fr = Frame.make(t, obs)
            st = stars.apparent_stars(fr, obs, subset, min_alt_deg=-90.0)
            out.append({"place": p["name"], "lat": p["lat"], "lon": p["lon"], "elevM": p["elevM"], "posix": t,
                        "frame": {"lstDeg": fr.lst, "earthAu": _vec(fr.earth), "vEarthAuPerDay": _vec(fr.v_earth),
                                  "observerKm": _vec(fr.observer_km)},
                        "bodies": ss,
                        "stars": [{k: s[k] for k in ("id", "altDeg", "apparentAltDeg", "azDeg", "raDeg", "decDeg")}
                                  for s in st]})
    return out


def _skyglow_vectors():
    rows = []
    for art in (None, 0.0, 0.5, 3.0, 40.0):
        for sun_alt in (10.0, 0.0, -3.0, -9.0, -15.0, -30.0):
            for moon_alt, phase in ((-10.0, 0.0), (45.0, 10.0), (20.0, 90.0), (70.0, 150.0)):
                rows.append({"artificial": art, "sunAltDeg": sun_alt, "moonAltDeg": moon_alt, "moonPhaseDeg": phase,
                             **skyglow.sky_brightness(art, sun_alt, moon_alt, phase)})
    lm = [{"skyMag": m, "limitingMagnitude": skyglow.limiting_magnitude(m)} for m in (16.0, 18.5, 20.0, 21.0, 22.0)]
    ext = [{"apparentAltDeg": a, "extinctionMag": stars.extinction_mag(a)} for a in (90.0, 45.0, 20.0, 5.0, 0.5)]
    grid = skyglow.RadianceGrid(north=42.5, west=-88.6, dlat=0.05, dlon=0.05, rows=30, cols=30,
                                values=[float((i * 7) % 13) * 2.5 for i in range(900)],
                                product="synthetic", year=2024, source={})
    wr = [{"lat": la, "lon": lo, "weightedRadiance": skyglow.weighted_radiance(grid, la, lo)}
          for la, lo in ((41.9, -87.9), (42.0, -88.0), (42.4, -88.5), (45.0, -80.0))]
    return {"skyBrightness": rows, "limitingMagnitude": lm, "extinction": ext,
            "radianceGrid": {"north": grid.north, "west": grid.west, "dlat": grid.dlat, "dlon": grid.dlon,
                             "rows": grid.rows, "cols": grid.cols, "values": grid.values}, "weightedRadiance": wr}


def _elements_dict(e):
    return {"name": e.name, "noradId": e.norad_id, "epoch": e.epoch, "inclinationDeg": e.inclination,
            "raanDeg": e.raan, "eccentricity": e.eccentricity, "argPerigeeDeg": e.arg_perigee,
            "meanAnomalyDeg": e.mean_anomaly, "meanMotionRevPerDay": e.mean_motion, "bstar": e.bstar}


def _sat_vectors():
    iss = parse_tle(*ISS_2008)
    v5 = parse_tle(*V5)
    omm = parse_omm_json(OMM_SAMPLE)[0]
    states = []
    for name, el in (("ISS_2008", iss), ("V5", v5)):
        sat = Satellite(el)
        for minutes in (0.0, 1.0, 60.0, 360.0, 720.0, 1440.0, 4320.0):
            r, v = sat.propagate_minutes(minutes)
            states.append({"sat": name, "minutes": minutes, "rKm": _vec(r), "vKmS": _vec(v)})
    obs_rows, pass_rows = [], []
    sat = Satellite(iss)
    for p in PLACES:
        o = sp.Observer(p["lat"], p["lon"], p["elevM"])
        for dt in (0.0, 1800.0, 7200.0, 43200.0):
            ob = o.observe(sat, iss.epoch + dt)
            obs_rows.append({"place": p["name"], "posix": iss.epoch + dt, "altDeg": ob.alt, "azDeg": ob.az,
                             "rangeKm": ob.range_km, "sunlit": ob.sunlit, "sunAltDeg": ob.sun_alt,
                             "phaseRad": ob.phase_rad, "latDeg": ob.lat, "lonDeg": ob.lon, "heightKm": ob.height_km})
        ps = sp.find_passes(sat, o, iss.epoch, iss.epoch + 3 * 86400, std_mag=-1.8)
        pass_rows.append({"place": p["name"], "lat": p["lat"], "lon": p["lon"], "elevM": p["elevM"],
                          "start": iss.epoch, "end": iss.epoch + 3 * 86400, "stdMag": -1.8, "passes": ps})
    return {"tle": {"ISS_2008": list(ISS_2008), "V5": list(V5)}, "omm": OMM_SAMPLE,
            "elements": {"ISS_2008": _elements_dict(iss), "V5": _elements_dict(v5), "OMM": _elements_dict(omm)},
            "states": states, "observations": obs_rows, "passes": pass_rows,
            "magnitude": [{"stdMag": -1.8, "rangeKm": r, "phaseRad": ph, "magnitude": sp.magnitude(-1.8, r, ph)}
                          for r in (420.0, 900.0, 2000.0) for ph in (0.3, 1.2, 2.5)]}


def build(star_count: int = 40) -> dict:
    catalog = stars.load_catalog()
    return {
        "schema": SCHEMA,
        "generator": "Tools/livefeeds/livefeeds.sh vectors (Python reference: Tools/livefeeds/livefeeds/sky, sats)",
        "note": "Inputs and expected outputs for the Swift port. Stars use the first %d entries of the engine's "
                "catalogue (Sources/WorldEnvironment/Catalog/stars-bsc5-bright256.json), matched by id." % star_count,
        "tolerances": TOLERANCES,
        "constants": {"passStepSeconds": sp.STEP_S, "minPassAltDeg": sp.MIN_PASS_ALT,
                      "visibleMinAltDeg": sp.VISIBLE_MIN_ALT, "sunMaxAltForVisibleDeg": sp.SUN_MAX_ALT_FOR_VISIBLE},
        "time": _time_vectors(),
        "sky": _sky_vectors(catalog, star_count),
        "skyglow": _skyglow_vectors(),
        "satellites": _sat_vectors(),
    }


def _clean(x):
    """JSON without NaN or infinity (none are expected; fail loudly if one appears)."""
    if isinstance(x, float):
        if not math.isfinite(x):
            raise ValueError("non-finite value in vectors")
        return x
    if isinstance(x, dict):
        return {k: _clean(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [_clean(v) for v in x]
    return x


def dumps(doc: dict) -> str:
    return json.dumps(_clean(doc), indent=1, sort_keys=True) + "\n"


def main(argv=None) -> int:
    out = (argv or [DEFAULT_OUT])[0]
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(dumps(build()))
    print(out)
    return 0
