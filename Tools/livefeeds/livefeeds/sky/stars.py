"""Bright stars: catalogue loading and apparent horizon positions.

Input is any `worldengine.stars/1` file (unit vectors, equatorial J2000, epoch J2000), by default the
engine's own Yale Bright Star Catalogue extract (`Sources/WorldEnvironment/Catalog/stars-bsc5-bright256.json`,
public domain, see its STARS-NOTICE.md). That file stops at magnitude 3.4. A fuller extract (BSC5 to
magnitude 6.5, about 9,000 stars) in the same schema comes from `scripts/data/build_star_catalog.py OUT --count all
--missing-bv null` (stars without B-V carry ci null and are drawn white); it is not built yet because the BSC5 source
host (HEASARC) is denied by the cloud network policy. Pass it with `--catalog`.

Per star: space motion to the date (when the catalogue gives it), annual aberration, precession and
nutation, then horizon coordinates and refraction. Stellar parallax (< 1 arcsec) is ignored.
"""

import json
import math
import os
from typing import Dict, List, Optional

from . import astro
from .bodies import Frame, Observer, aberrate

REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
DEFAULT_CATALOG = os.path.join(REPO_ROOT, "Sources", "WorldEnvironment", "Catalog", "stars-bsc5-bright256.json")

_cache: Dict[str, dict] = {}


def load_catalog(path: Optional[str] = None) -> dict:
    path = path or DEFAULT_CATALOG
    if path not in _cache:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        if data.get("schema") != "worldengine.stars/1":
            raise ValueError("unsupported star catalogue schema: %r" % data.get("schema"))
        _cache[path] = data
    return _cache[path]


def j2000_direction(star: dict, years_since_j2000: float) -> astro.Vec:
    u = tuple(star["u"])
    dist, vel = star.get("distPc"), star.get("velPcPerYear")
    if dist and vel:
        p = astro.add(astro.scale(u, dist), astro.scale(tuple(vel), years_since_j2000))
        return astro.unit(p)
    return u


def apparent_stars(fr: Frame, obs: Observer, catalog: dict, min_alt_deg: float = -1.0) -> List[dict]:
    """Stars whose apparent altitude is at least `min_alt_deg`, brightest first."""
    years = fr.t * 100.0
    out = []
    for s in catalog["stars"]:
        u = aberrate(j2000_direction(s, years), fr.v_earth)
        v = astro.matvec(fr.to_date, u)
        alt, az = astro.alt_az(v, obs.lat, fr.lst)
        app = alt + astro.refraction_deg(alt, obs.pressure_hpa, obs.temp_c)
        if app < min_alt_deg:
            continue
        ra, dec = astro.ra_dec(v)
        out.append({
            "id": "hr%s" % s["hr"], "name": s.get("name"), "mag": s["mag"], "colorIndexBV": s.get("ci"),
            "altDeg": alt, "apparentAltDeg": app, "azDeg": az, "raDeg": ra, "decDeg": dec,
        })
    out.sort(key=lambda r: (r["mag"], r["id"]))
    return out


def extinction_mag(apparent_alt_deg: float, k_v: float = 0.25) -> float:
    """Atmospheric extinction in V for a typical inland site (k = 0.25 mag per air mass, assumption)."""
    x = astro.airmass(apparent_alt_deg)
    return k_v * x if math.isfinite(x) else 99.0
