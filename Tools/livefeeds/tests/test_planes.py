"""Ambient planes: StableRandom port, glide path, timing, determinism, flows, labels (offline)."""

import calendar
import json
import math
import unittest

from livefeeds.planes import ambient as A
from livefeeds.planes.stablerandom import StableRandom, fnv1a

EXAMPLE_T = 1791281250  # 2026-10-06 10:07:30Z, the example instant of ambient-planes.md section 7


class StableRandomTests(unittest.TestCase):
    def test_reference_vectors(self):
        self.assertEqual(fnv1a("a"), 0xAF63DC4C8601EC8C)       # published FNV-1a 64 test vector
        r = StableRandom(salt="")
        r.state = 0
        self.assertEqual(r.next(), 0xE220A8397B1DCDAF)         # SplitMix64 from seed 0, first output
        self.assertEqual(r.next(), 0x6E789E6AA1B965F4)

    def test_unit_range_and_determinism(self):
        a = [StableRandom(20732, 123, salt="x").unit() for _ in range(3)]
        b = [StableRandom(20732, 123, salt="x").unit() for _ in range(3)]
        self.assertEqual(a, b)
        r = StableRandom(1, 2, salt="y")
        self.assertTrue(all(0 <= r.unit() < 1 for _ in range(1000)))


class GeometryTests(unittest.TestCase):
    def setUp(self):
        self.ap = A.Airport(A.load_area("ord"))

    def test_glide_path_table(self):
        # ambient-planes.md 2.2: h at 1, 5 and 10 NM = 112, 500 and 986 m.
        for nm, h in ((1, 112), (5, 500), (10, 986)):
            self.assertAlmostEqual(15 + nm * A.NM * self.ap.tan_glide, h, delta=1)

    def test_corridor_time_and_closed_form(self):
        v = 150 * A.KT
        # Find tau at the corridor start by bisection on the closed form; spec: about 273 s.
        lo, hi = 0.0, 600.0
        while hi - lo > 0.01:
            mid = (lo + hi) / 2
            if self.ap._arrival_distance(v, mid) is None:
                hi = mid
            else:
                lo = mid
        self.assertAlmostEqual(lo, 273, delta=2)
        # Integrate dt = dd / V(d) numerically and compare with the closed form.
        d_target = self.ap._arrival_distance(v, 200.0)
        n, tsum = 20000, 0.0
        for i in range(n):
            d = d_target * (i + 0.5) / n
            tsum += (d_target / n) / self.ap._arrival_speed(v, d)
        self.assertAlmostEqual(tsum, 200.0, delta=0.05)

    def test_destination_along_runway_heading(self):
        lat, lon = A.destination(41.98391, -87.89019, 270.0, 1852.0)
        self.assertAlmostEqual(lat, 41.98391, places=4)
        self.assertAlmostEqual((lon + 87.89019) * 111320 * math.cos(math.radians(lat)), -1852, delta=3)


class TrafficTests(unittest.TestCase):
    def setUp(self):
        self.ord, self.den = A.load_area("ord"), A.load_area("den")

    def test_deterministic_and_labelled(self):
        a = A.snapshot([self.ord, self.den], EXAMPLE_T)
        b = A.snapshot([self.ord, self.den], EXAMPLE_T)
        self.assertEqual(json.dumps(a), json.dumps(b))
        self.assertFalse(a["live"])
        self.assertEqual(a["basis"], "simulated")
        self.assertEqual(a["label"], "Illustrative air traffic — not live")
        self.assertFalse(a["attribution"][0]["live"])
        self.assertIn("OpenStreetMap", a["attribution"][0]["text"])
        for v in a["vehicles"]:
            self.assertEqual(v["kind"], "aircraft-ambient")
            self.assertEqual(v["basis"], "simulated")
            self.assertEqual(v["label"], A.LABEL)
            self.assertTrue(v["id"].startswith("amb:"))
        self.assertIn("amb:ORD:27L:20732:0123", [v["id"] for v in a["vehicles"]])

    def test_spacing_and_daily_volume(self):
        ap = A.Airport(self.ord)
        day = ap.local_day(EXAMPLE_T)
        times = [s.t for s in (ap.slot("27L", "arr", day, k) for k in range(576)) if s]
        self.assertGreaterEqual(min(b - a for a, b in zip(times, times[1:])), 100.0)
        self.assertTrue(150 < len(times) < 300)

    def test_departures_quiet_at_night(self):
        ap = A.Airport(self.ord)
        day = ap.local_day(EXAMPLE_T)
        midnight = ap.local_midnight(day)
        for k in range(576):
            s = ap.slot("27C", "dep", day, k)
            if s:
                h = (s.t - midnight) / 3600.0
                self.assertTrue(5 <= h < 22, h)

    def test_approach_profile(self):
        ap = A.Airport(self.ord)
        day = ap.local_day(EXAMPLE_T)
        s = next(ap.slot("27L", "arr", day, k) for k in range(300, 576) if ap.slot("27L", "arr", day, k))
        far = ap.state(s, s.t - 270)
        near = ap.state(s, s.t - 30)
        self.assertGreater(far["altitudeM"], near["altitudeM"])
        self.assertGreater(far["speedMps"], near["speedMps"])
        self.assertLess(far["lon"], -87.6)
        self.assertGreater(far["lon"], near["lon"])          # west flow: arrivals come from the east
        self.assertEqual(ap.state(s, s.t + 1)["phase"], "flare")
        roll = ap.state(s, s.t + 20)
        self.assertEqual((roll["phase"], roll["altitudeM"]), ("rollout", 0.0))
        self.assertIsNone(ap.state(s, s.t + 120))             # dissolved after the roll-out
        self.assertIsNone(ap.state(s, s.t - 400))             # not yet on the corridor
        # Fades are stateless: opacity rises from 0 at the corridor start.
        first = next(ap.state(s, s.t - tau) for tau in range(400, 0, -1) if ap.state(s, s.t - tau))
        self.assertLess(first["opacity"], 0.1)
        self.assertAlmostEqual((first["altitudeM"] - 15) / ap.tan_glide, ap.corridor, delta=150)

    def test_departure_profile(self):
        ap = A.Airport(self.den)
        day = ap.local_day(EXAMPLE_T)
        s = next(ap.slot("17L", "dep", day, k) for k in range(200, 576) if ap.slot("17L", "dep", day, k))
        self.assertLess(ap.state(s, s.t + 1)["opacity"], 1.0)  # fades in at brake release
        roll = ap.state(s, s.t + 10)
        self.assertEqual((roll["phase"], roll["altitudeM"]), ("takeoffRoll", 0.0))
        climb = ap.state(s, s.t + 120)
        self.assertEqual(climb["phase"], "climb")
        self.assertLess(climb["lat"], 39.86)                  # south flow departures head south
        self.assertLessEqual(climb["altitudeM"], 3000)

    def test_flow_from_wind(self):
        self.assertEqual(A.choose_flow(self.ord, None, None), "west")
        self.assertEqual(A.choose_flow(self.ord, 90.0, 10 * A.KT), "east")     # 10 kt from the east
        self.assertEqual(A.choose_flow(self.ord, 90.0, 3 * A.KT), "west")      # calm: default
        self.assertEqual(A.choose_flow(self.ord, 0.0, 15 * A.KT), "west")      # pure crosswind: default
        self.assertEqual(A.choose_flow(self.den, 0.0, 10 * A.KT), "north")
        snap = A.snapshot([self.ord], EXAMPLE_T, wind=(90.0, 10 * A.KT))
        self.assertEqual(snap["flows"]["ORD"], "east")
        for v in snap["vehicles"]:
            self.assertIn(v["route"].split()[1], ("09R", "10L", "09C", "10C"))

    def test_mode_off_draws_nothing(self):
        off = dict(self.ord, aircraftMode="off")
        self.assertEqual(A.snapshot([off], EXAMPLE_T)["vehicles"], [])

    def test_multiplier_wraps(self):
        table = self.ord["model"]["hourlyMultiplier"]
        self.assertAlmostEqual(A.multiplier(table, 8.5), 1.0)
        self.assertAlmostEqual(A.multiplier(table, 0.0), (table[23] + table[0]) / 2)


if __name__ == "__main__":
    unittest.main()
