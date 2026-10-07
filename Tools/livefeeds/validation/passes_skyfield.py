"""Compare livefeeds.sats pass times and sunlight with Skyfield (validation only, not a test).

Same element set on both sides, so this checks our frames, pass search and shadow model, not SGP4 itself
(see sgp4_vallado.py for that). Needs `skyfield` and `skyfield-data` from PyPI:
    PYTHONPATH=Tools/livefeeds /tmp/v/bin/python Tools/livefeeds/validation/passes_skyfield.py
"""
import os
import time

import skyfield_data
from skyfield.api import EarthSatellite, Loader, wgs84

from livefeeds.sats import elements, passes, sgp4

PLACES = {"Chicago": (41.8781, -87.6298, 181.0), "Denver": (39.7392, -104.9903, 1609.0),
          "Miami": (25.7617, -80.1918, 2.0)}
# The ISS element set printed in the "Two-line element set" format description (epoch 2008-09-20).
L0, L1, L2 = ("ISS (ZARYA)", "1 25544U 98067A   08264.51782528 -.00002182  00000-0 -11606-4 0  2927",
              "2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.72125391563537")

load = Loader(os.path.join(os.path.dirname(skyfield_data.__file__), "data"))
eph = load("de421.bsp")
ts = load.timescale(builtin=True)


def main():
    el = elements.parse_tle(L0, L1, L2)
    sat = sgp4.Satellite(el)
    ref = EarthSatellite(L1, L2, L0, ts)
    t0, t1 = el.epoch, el.epoch + 3 * 86400
    worst = {"rise": 0.0, "culmination": 0.0, "set": 0.0, "maxAlt": 0.0}
    n = 0
    lit_disagree = lit_total = 0
    for place, (lat, lon, el_m) in PLACES.items():
        ours = passes.find_passes(sat, passes.Observer(lat, lon, el_m), t0, t1)
        topo = wgs84.latlon(lat, lon, elevation_m=el_m)
        tt, ev = ref.find_events(topo, ts.from_datetime(_dt(t0)), ts.from_datetime(_dt(t1)), altitude_degrees=0.0)
        groups, cur = [], {}
        for ti, e in zip(tt, ev):
            k = ("rise", "culmination", "set")[e]
            if k == "rise":
                cur = {}
            cur[k] = ti
            if k == "set" and "rise" in cur and "culmination" in cur:
                groups.append(cur)
        for p in ours:
            if p["startsBeforeWindow"] or p["endsAfterWindow"]:
                continue
            g = min(groups, key=lambda g: abs(g["culmination"].utc_datetime().timestamp() - p["culmination"]["t"]))
            for k in ("rise", "culmination", "set"):
                worst[k] = max(worst[k], abs(g[k].utc_datetime().timestamp() - p[k]["t"]))
            alt = (ref - topo).at(g["culmination"]).altaz()[0].degrees
            worst["maxAlt"] = max(worst["maxAlt"], abs(alt - p["culmination"]["altDeg"]))
            n += 1
            # Sunlight along the pass, every 5 s.
            tt5 = ts.from_datetimes([_dt(p["rise"]["t"] + 5 * k) for k in range(int((p["set"]["t"] - p["rise"]["t"]) / 5))])
            lit_ref = ref.at(tt5).is_sunlit(eph)
            for ti, lr in zip(tt5, lit_ref):
                o = passes.Observer(lat, lon, el_m).observe(sat, ti.utc_datetime().timestamp())
                lit_total += 1
                lit_disagree += int(o.sunlit != bool(lr))
        print("%s: %d passes (max alt >= 10 deg) in 3 days from %s" % (place, len(ours), time.strftime("%Y-%m-%d %H:%MZ", time.gmtime(t0))))
    print("passes compared: %d" % n)
    print("worst |dt| rise %.1f s, culmination %.1f s, set %.1f s; worst |d maxAlt| %.3f deg"
          % (worst["rise"], worst["culmination"], worst["set"], worst["maxAlt"]))
    print("sunlit flag disagreements: %d of %d samples (cylindrical shadow vs Skyfield's)" % (lit_disagree, lit_total))


def _dt(posix):
    import datetime
    return datetime.datetime.fromtimestamp(posix, datetime.timezone.utc)


if __name__ == "__main__":
    main()
