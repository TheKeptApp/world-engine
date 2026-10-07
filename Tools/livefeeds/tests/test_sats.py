"""Satellite layer: element parsing, SGP4, passes, contract states and the CelesTrak store (offline)."""

import json
import math
import tempfile
import unittest

from livefeeds import fetch
from livefeeds.sats import celestrak, contract, elements, passes, sgp4

# The ISS element set printed in the public "two-line element set" format description (epoch 2008-09-20).
ISS = ("ISS (ZARYA)", "1 25544U 98067A   08264.51782528 -.00002182  00000-0 -11606-4 0  2927",
       "2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.72125391563537")
# Vallado's verification satellite 00005 (SGP4-VER.TLE), first line pair.
V5 = ("", "1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753",
      "2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667")
CHICAGO = (41.8781, -87.6298, 181.0)


def iss():
    return elements.parse_tle(*ISS)


class ElementTests(unittest.TestCase):
    def test_tle_fields(self):
        el = iss()
        self.assertEqual(el.norad_id, 25544)
        self.assertAlmostEqual(el.bstar, -0.11606e-4)
        self.assertAlmostEqual(el.eccentricity, 0.0006703)
        self.assertAlmostEqual(el.mean_motion, 15.72125391)
        # 2008 day 264.51782528 = 2008-09-20 12:25:40.1 UTC
        self.assertAlmostEqual(el.epoch, 1221913540.1, delta=0.1)

    def test_checksum(self):
        bad = ISS[1][:-1] + "0"
        with self.assertRaises(elements.ElementError):
            elements.parse_tle(ISS[0], bad, ISS[2])

    def test_text_two_and_three_line(self):
        self.assertEqual(len(elements.parse_tle_text("\n".join(ISS) + "\n" + "\n".join(ISS[1:]))), 2)

    def test_omm_json(self):
        rec = {"OBJECT_NAME": "ISS (ZARYA)", "NORAD_CAT_ID": 25544, "EPOCH": "2008-09-20T12:25:40.104192",
               "MEAN_MOTION": 15.72125391, "ECCENTRICITY": 0.0006703, "INCLINATION": 51.6416,
               "RA_OF_ASC_NODE": 247.4627, "ARG_OF_PERICENTER": 130.536, "MEAN_ANOMALY": 325.0288,
               "BSTAR": -1.1606e-05}
        a, b = elements.parse_omm_json([rec])[0], iss()
        ra, _ = sgp4.Satellite(a).propagate(b.epoch + 3600)
        rb, _ = sgp4.Satellite(b).propagate(b.epoch + 3600)
        self.assertLess(math.dist(ra, rb), 1e-3)


class Sgp4Tests(unittest.TestCase):
    def test_vallado_00005_epoch_state(self):
        r, v = sgp4.Satellite(elements.parse_tle(*V5)).propagate_minutes(0.0)
        for got, want in zip(r, (7022.46529266, -1400.08296755, 0.03995155)):
            self.assertAlmostEqual(got, want, places=6)
        for got, want in zip(v, (1.893841015, 6.405893759, 4.534807250)):
            self.assertAlmostEqual(got, want, places=8)

    def test_deep_space_rejected(self):
        geo = elements.Elements(1, "GEO", 0.0, 0.05, 80.0, 0.0002, 0.0, 0.0, 1.0027, 0.0)
        with self.assertRaises(sgp4.DeepSpace):
            sgp4.Satellite(geo)

    def test_iss_height_plausible(self):
        el = iss()
        r, v = sgp4.Satellite(el).propagate(el.epoch + 7200)
        self.assertTrue(6700 < math.sqrt(sum(x * x for x in r)) < 6800)
        self.assertTrue(7.5 < math.sqrt(sum(x * x for x in v)) < 7.8)


class PassTests(unittest.TestCase):
    def setUp(self):
        self.el = iss()
        self.sat = sgp4.Satellite(self.el)
        self.obs = passes.Observer(*CHICAGO)
        self.ps = passes.find_passes(self.sat, self.obs, self.el.epoch, self.el.epoch + 86400, -1.8)

    def test_pass_shape(self):
        self.assertGreater(len(self.ps), 3)
        for p in self.ps:
            self.assertLess(p["rise"]["t"], p["culmination"]["t"])
            self.assertLess(p["culmination"]["t"], p["set"]["t"])
            self.assertGreaterEqual(p["culmination"]["altDeg"], passes.MIN_PASS_ALT)
            self.assertAlmostEqual(p["rise"]["altDeg"], 0.0, delta=0.05)
            self.assertEqual(p["basis"], "forecast")

    def test_visible_passes_follow_the_rules(self):
        vis = [p for p in self.ps if p["visible"]]
        self.assertTrue(vis)
        for p in vis:
            w = p["visibleWindow"]
            for pt in w["track"]:
                o = self.obs.observe(self.sat, pt["t"])
                self.assertTrue(o.sunlit)
                self.assertLessEqual(o.sun_alt, passes.SUN_MAX_ALT_FOR_VISIBLE + 0.01)
                self.assertGreaterEqual(o.alt, passes.VISIBLE_MIN_ALT - 0.5)
            self.assertLess(w["brightestMagnitude"], 0)

    def test_shadow_model(self):
        sun = (1.0, 0.0, 0.0)
        self.assertTrue(passes.sunlit((7000.0, 0.0, 0.0), sun))
        self.assertFalse(passes.sunlit((-7000.0, 0.0, 0.0), sun))
        self.assertTrue(passes.sunlit((-7000.0, 6500.0, 0.0), sun))

    def test_geodetic_round_trip(self):
        e = passes.observer_ecef(41.8781, -87.6298, 1000.0)
        lat, lon, h = passes.geodetic(e)
        self.assertAlmostEqual(lat, 41.8781, places=6)
        self.assertAlmostEqual(lon, -87.6298, places=6)
        self.assertAlmostEqual(h, 1.0, places=4)


class ContractTests(unittest.TestCase):
    CFG = {"satellites": [{"noradId": 25544, "stdMag": -1.8}]}

    def test_fresh_stale_unavailable(self):
        el = iss()
        for days, want in ((0.5, "fresh"), (5, "stale"), (20, "unavailable")):
            doc = contract.build([el], *CHICAGO, at=el.epoch + days * 86400, hours=6, config=self.CFG, now=0)
            self.assertEqual(doc["state"], want, days)
            self.assertEqual(doc["satellites"][0]["state"], want)
            if want == "unavailable":
                self.assertEqual(doc["satellites"][0]["passes"], [])
                self.assertIsNone(doc["satellites"][0]["now"])

    def test_labels_and_attribution(self):
        el = iss()
        doc = contract.build([el], *CHICAGO, at=el.epoch, hours=24, config=self.CFG, now=0)
        self.assertEqual(doc["schema"], "worldengine.live.satellites/1")
        self.assertFalse(doc["live"])
        s = doc["satellites"][0]
        self.assertEqual(s["basis"], "forecast")
        self.assertEqual(s["now"]["basis"], "forecast")
        self.assertEqual(s["standardMagnitude"]["basis"], "inferred")
        self.assertEqual(doc["elements"]["basis"], "observed")
        self.assertEqual(doc["attribution"][0]["source"], "celestrak")
        self.assertNotIn("line1", json.dumps(doc))  # raw elements never leave the relay

    def test_no_elements_is_unavailable(self):
        doc = contract.build([], *CHICAGO, at=0, hours=1, config=self.CFG, now=0, fetch_error="blocked")
        self.assertEqual(doc["state"], "unavailable")
        self.assertEqual(doc["elements"]["error"], "blocked")

    def test_unknown_magnitude_is_null(self):
        el = iss()
        doc = contract.build([el], *CHICAGO, at=el.epoch, hours=24, config={"satellites": []}, now=0)
        self.assertIsNone(doc["satellites"][0]["standardMagnitude"])
        for p in doc["satellites"][0]["passes"]:
            self.assertIsNone(p["culmination"]["magnitude"])


class StoreTests(unittest.TestCase):
    def _records(self):
        return [{"OBJECT_NAME": "ISS (ZARYA)", "NORAD_CAT_ID": 25544, "EPOCH": "2008-09-20T12:25:40",
                 "MEAN_MOTION": 15.72125391, "ECCENTRICITY": 0.0006703, "INCLINATION": 51.6416,
                 "RA_OF_ASC_NODE": 247.4627, "ARG_OF_PERICENTER": 130.536, "MEAN_ANOMALY": 325.0288,
                 "BSTAR": -1.1606e-05}]

    def test_rate_limit_and_cache(self):
        calls = []
        clock = [1000.0]

        def getter(url):
            calls.append(url)
            return fetch.FetchResult(200, json.dumps(self._records()).encode(), None, None, 10)

        with tempfile.TemporaryDirectory() as d:
            st = celestrak.ElementStore(d, min_refresh_seconds=10, refresh_seconds=10, getter=getter,
                                        clock=lambda: clock[0])
            self.assertEqual(st.min_refresh, celestrak.MIN_REFRESH_SECONDS)  # never below 2 hours
            els, fetched, err = st.load("stations")
            self.assertEqual((len(els), fetched, err), (1, 1000.0, None))
            clock[0] += 3600
            st.load("stations")
            self.assertEqual(len(calls), 1)  # within 2 hours: cache only
            clock[0] += 3601
            st.load("stations")
            self.assertEqual(len(calls), 2)
            self.assertIn("GROUP=stations", calls[0])

    def test_block_backs_off_a_day_and_keeps_cache(self):
        mode = ["ok"]
        clock = [0.0]
        calls = []

        def getter(url):
            calls.append(url)
            if mode[0] == "ok":
                return fetch.FetchResult(200, json.dumps(self._records()).encode(), None, None, 10)
            raise fetch.FetchError("HTTP 403", 403)

        with tempfile.TemporaryDirectory() as d:
            st = celestrak.ElementStore(d, getter=getter, clock=lambda: clock[0])
            st.load("visual")
            mode[0] = "blocked"
            clock[0] += 7 * 3600
            els, fetched, err = st.load("visual")
            self.assertEqual(len(els), 1)
            self.assertEqual(fetched, 0.0)
            self.assertIn("403", err)
            clock[0] += 6 * 3600
            st.load("visual")
            self.assertEqual(len(calls), 2)  # backing off for a day
            clock[0] += 19 * 3600
            st.load("visual")
            self.assertEqual(len(calls), 3)

    def test_any_http_error_stops_for_a_day(self):
        for status in (301, 404, 503):
            clock = [0.0]
            calls = []

            def getter(url):
                calls.append(url)
                raise fetch.FetchError("HTTP %d" % status, status)

            with tempfile.TemporaryDirectory() as d:
                st = celestrak.ElementStore(d, getter=getter, clock=lambda: clock[0])
                _, _, err = st.load("visual")
                self.assertIn("needsHuman", err)
                clock[0] += 12 * 3600
                st.load("visual")
                self.assertEqual(len(calls), 1)


if __name__ == "__main__":
    unittest.main()
