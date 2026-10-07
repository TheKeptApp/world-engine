"""Compare livefeeds.sky with Skyfield + JPL DE421 for 3 dates x 3 places (validation only, not a test).

Needs a separate environment with `skyfield` and `skyfield-data` (both on PyPI; skyfield-data bundles
DE421 and the IERS finals file, so nothing is downloaded at run time):
    python3 -m venv /tmp/v && /tmp/v/bin/pip install skyfield skyfield-data
    PYTHONPATH=Tools/livefeeds /tmp/v/bin/python Tools/livefeeds/validation/sky_reference.py
Prints a Markdown table of angular errors (arcsec) between our apparent topocentric airless positions and
Skyfield's for the Sun, Moon, planets and five catalogue stars.
"""
import calendar
import math
import os

import skyfield_data
from skyfield.api import Loader, Star, wgs84

from livefeeds.sky import astro, bodies, stars

PLACES = {"Chicago": (41.8781, -87.6298, 181.0), "Denver": (39.7392, -104.9903, 1609.0),
          "Miami": (25.7617, -80.1918, 2.0)}
DATES = ((2026, 1, 15, 3, 0), (2026, 6, 21, 4, 30), (2026, 10, 6, 2, 0))
STAR_IDS = ("2491", "7001", "5340", "424", "1713")  # Sirius, Vega, Arcturus, Polaris, Rigel
NAMES = {"sun": "sun", "moon": "moon", "mercury": "mercury", "venus": "venus", "mars": "mars",
         "jupiter": "jupiter barycenter", "saturn": "saturn barycenter", "uranus": "uranus barycenter",
         "neptune": "neptune barycenter"}

load = Loader(os.path.join(os.path.dirname(skyfield_data.__file__), "data"))
eph = load("de421.bsp")
ts = load.timescale(builtin=True)


def sep(alt1, az1, alt2, az2):
    a = astro.from_ra_dec(az1, alt1)
    b = astro.from_ra_dec(az2, alt2)
    return astro.angular_separation_deg(a, b) * 3600


def main():
    cat = stars.load_catalog()
    by_hr = {s["hr"]: s for s in cat["stars"]}
    rows = []
    worst = {}
    for (y, mo, d, h, mi) in DATES:
        posix = calendar.timegm((y, mo, d, h, mi, 0))
        t = ts.utc(y, mo, d, h, mi)
        for place, (lat, lon, el) in PLACES.items():
            obs = bodies.Observer(lat, lon, el)
            ours = bodies.solar_system(posix, obs)
            topo = eph["earth"] + wgs84.latlon(lat, lon, elevation_m=el)
            fr = bodies.Frame.make(posix, obs)
            errs = {}
            for k, name in NAMES.items():
                alt, az, dist = topo.at(t).observe(eph[name]).apparent().altaz()
                errs[k] = sep(ours[k]["altDeg"], ours[k]["azDeg"], alt.degrees, az.degrees)
            for hr in STAR_IDS:
                s = dict(by_hr[hr], velPcPerYear=None)
                ra, dec = astro.ra_dec(tuple(s["u"]))
                u = bodies.aberrate(tuple(s["u"]), fr.v_earth)
                v = astro.matvec(fr.to_date, u)
                a1, z1 = astro.alt_az(v, lat, fr.lst)
                star = Star(ra_hours=ra / 15, dec_degrees=dec)
                alt, az, _ = topo.at(t).observe(star).apparent().altaz()
                errs["star" + hr] = sep(a1, z1, alt.degrees, az.degrees)
            rows.append(("%04d-%02d-%02d %02d:%02dZ" % (y, mo, d, h, mi), place, errs))
            for k, v in errs.items():
                worst[k] = max(worst.get(k, 0), v)
    keys = list(NAMES) + ["star" + h for h in STAR_IDS]
    print("| UTC | Place | " + " | ".join(keys) + " |")
    print("|---|---|" + "---|" * len(keys))
    for when, place, e in rows:
        print("| %s | %s | " % (when, place) + " | ".join("%.1f" % e[k] for k in keys) + " |")
    print("| **max** | | " + " | ".join("**%.1f**" % worst[k] for k in keys) + " |")
    # Moon phase cross-check.
    for (y, mo, d, h, mi) in DATES:
        posix = calendar.timegm((y, mo, d, h, mi, 0))
        t = ts.utc(y, mo, d, h, mi)
        ours = bodies.solar_system(posix, bodies.Observer(*PLACES["Chicago"]))["moon"]
        from skyfield import almanac
        frac = almanac.fraction_illuminated(eph, "moon", t)
        print("moon illuminated %04d-%02d-%02d: ours %.4f skyfield(geocentric) %.4f" % (y, mo, d, ours["illuminatedFraction"], frac))


if __name__ == "__main__":
    main()
