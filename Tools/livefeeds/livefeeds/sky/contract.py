"""Builds the `worldengine.live.sky/1` JSON document (spec: docs/live-world/sky.md)."""

import time
from typing import List, Optional

from . import bodies, skyglow, stars
from .bodies import Frame, Observer

SCHEMA = "worldengine.live.sky/1"
RECOMPUTE_SECONDS = 60
# Apparent-position error budget, arcsec: rounded up from the worst case of the 3 dates x 3 places
# validation against JPL DE421 (docs/live-world/sky.md section 5). Not a guarantee outside 2000-2050.
ACCURACY = {"unit": "arcsec", "basis": "inferred",
            "sun": 20, "moon": 10, "stars": 5, "mercury": 20, "venus": 40, "mars": 40, "jupiter": 120,
            "saturn": 400, "uranus": 20, "neptune": 60}  # stars drift 15 arcsec per second of time; a minute is 0.25 deg

# Light-pollution input is an annual composite; it ages but does not go "live".
RADIANCE_FRESH_YEARS = 2
RADIANCE_STALE_YEARS = 6

ATTRIBUTION_STARS = {
    "source": "bsc5",
    "text": "Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren), via NASA HEASARC. "
            "Star names: IAU Working Group on Star Names.",
    "url": "https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html",
    "required": True,
}
ATTRIBUTION_BLACK_MARBLE = {
    "source": "nasa-black-marble",
    "text": "Night lights: NASA Black Marble (VIIRS Day/Night Band), NASA Goddard Space Flight Center.",
    "url": "https://blackmarble.gsfc.nasa.gov/",
    "required": False,
}


def _round(d: dict, nd: int = 4) -> dict:
    return {k: (round(v, nd) if isinstance(v, float) else v) for k, v in d.items()}


def light_pollution(grid: Optional[skyglow.RadianceGrid], lat: float, lon: float, now_year: int) -> dict:
    if grid is None:
        return {"state": "unavailable", "reason": "no radiance grid loaded for this place",
                "artificialToNaturalRatio": None, "weightedRadiance": None, "basis": "inferred", "confidence": None}
    wr = skyglow.weighted_radiance(grid, lat, lon)
    if wr is None:
        return {"state": "unavailable", "reason": "place outside the radiance grid", "artificialToNaturalRatio": None,
                "weightedRadiance": None, "basis": "inferred", "confidence": None}
    age = now_year - grid.year
    state = "fresh" if age <= RADIANCE_FRESH_YEARS else ("stale" if age <= RADIANCE_STALE_YEARS else "unavailable")
    if state == "unavailable":
        return {"state": state, "reason": "radiance composite older than %d years" % RADIANCE_STALE_YEARS,
                "artificialToNaturalRatio": None, "weightedRadiance": None, "basis": "inferred", "confidence": None}
    return {
        "state": state,
        "product": grid.product, "compositeYear": grid.year,
        "weightedRadiance": {"value": round(wr, 3), "unit": "nW/cm^2/sr", "basis": "observed",
                             "note": "kernel-weighted mean of the satellite composite around the observer"},
        "artificialToNaturalRatio": round(skyglow.artificial_ratio(wr), 3),
        "basis": "inferred", "confidence": "low",
    }


def build(posix: float, obs: Observer, catalog_path: Optional[str] = None,
          radiance: Optional[skyglow.RadianceGrid] = None, now: Optional[float] = None) -> dict:
    now = time.time() if now is None else now
    doc = {"schema": SCHEMA, "layer": "sky", "generatedAt": int(now), "at": int(posix),
           "observer": {"lat": obs.lat, "lon": obs.lon, "elevM": obs.elev_m},
           "recomputeSeconds": RECOMPUTE_SECONDS, "live": False}
    try:
        ss = bodies.solar_system(posix, obs)
    except bodies.OutOfRange as exc:
        doc.update(state="unavailable", reason=str(exc), attribution=[ATTRIBUTION_STARS])
        return doc
    fr = Frame.make(posix, obs)
    year = time.gmtime(now).tm_year
    lp = light_pollution(radiance, obs.lat, obs.lon, year)
    sky = skyglow.sky_brightness(lp["artificialToNaturalRatio"] if lp["state"] != "unavailable" else None,
                                 ss["sun"]["apparentAltDeg"], ss["moon"]["altDeg"], ss["moon"]["phaseAngleDeg"])
    sky = dict(_round(sky, 2), basis="inferred",
               confidence="low" if lp["state"] != "unavailable" else "assumesDarkSite",
               note=None if lp["state"] != "unavailable" else
               "no light-pollution data: dark-site sky assumed, real limiting magnitude is likely lower")
    nelm = sky["limitingMagnitudeNow"]
    cat = stars.load_catalog(catalog_path)
    star_rows: List[dict] = []
    for s in stars.apparent_stars(fr, obs, cat):
        ext = stars.extinction_mag(s["apparentAltDeg"]) - stars.extinction_mag(90.0)
        row = _round(s, 4)
        row["visibleToEye"] = s["mag"] + ext <= nelm
        star_rows.append(row)
    planets = []
    for name in bodies.PLANETS:
        p = _round(ss[name], 4)
        p["visibleToEye"] = p["apparentAltDeg"] > 0 and p["magnitude"] <= nelm
        planets.append(dict(p, id=name, basis="inferred"))
    doc.update(
        state="fresh",
        sun=dict(_round(ss["sun"], 4), basis="inferred"),
        moon=dict(_round(ss["moon"], 4), basis="inferred"),
        planets=planets,
        stars={"basis": "inferred", "catalog": cat["source"]["name"], "catalogFaintestMag": max(
            x["mag"] for x in cat["stars"]), "count": len(star_rows), "items": star_rows},
        lightPollution=lp,
        skyBrightness=sky,
        accuracy=ACCURACY,
        attribution=[ATTRIBUTION_STARS] + ([ATTRIBUTION_BLACK_MARBLE] if lp["state"] != "unavailable" else []),
    )
    return doc
