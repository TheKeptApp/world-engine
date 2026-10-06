"""Offline tests of the heights comparison's pure functions (numpy, scipy, shapely; no network, no lidar data).

Synthetic buildings (a gable roof on flat ground, with a class-2 ground ring) are sampled as noisy point
clouds and measured the way the real data is.
"""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import heights as H  # noqa: E402

PRM = json.load(open(os.path.join(os.path.dirname(HERE), "data", "heights.json")))
GROUND_Z = 187.0


def footprint(L=12.0, W=8.0, x0=0.0, y0=0.0):
    from shapely.geometry import box
    return box(x0 - L / 2, y0 - W / 2, x0 + L / 2, y0 + W / 2)


def gable_cloud(poly, eave=6.0, pitch=35.0, density=12.0, noise=0.03, seed=1):
    """Class-6 points of a gable roof (ridge along x) over `poly`, absolute z = GROUND_Z + roof height."""
    import shapely
    rng = np.random.default_rng(seed)
    x0, y0, x1, y1 = poly.bounds
    cy = (y0 + y1) / 2
    half = (y1 - y0) / 2
    n = int(density * poly.area * 1.6)
    x, y = rng.uniform(x0, x1, n), rng.uniform(y0, y1, n)
    ok = shapely.contains_xy(poly, x, y)
    x, y = x[ok], y[ok]
    z = GROUND_Z + eave + (half - np.abs(y - cy)) * math.tan(math.radians(pitch)) + rng.normal(0, noise, len(x))
    return np.stack([x, y, z], axis=1)


def ground_cloud(poly, density=2.0, noise=0.05, seed=2):
    """Class-2 points on flat ground in a 20 m neighbourhood, none under the building."""
    import shapely
    rng = np.random.default_rng(seed)
    x0, y0, x1, y1 = poly.buffer(20).bounds
    n = int(density * (x1 - x0) * (y1 - y0))
    x, y = rng.uniform(x0, x1, n), rng.uniform(y0, y1, n)
    ok = ~shapely.contains_xy(poly, x, y)
    return np.stack([x[ok], y[ok], GROUND_Z + rng.normal(0, noise, ok.sum())], axis=1)


class Sources(unittest.TestCase):
    def test_height_source_property_and_inferred(self):
        ml = {"height": 5.7, "sources": [{"dataset": "Microsoft ML Buildings"}]}
        self.assertEqual(H.height_source(ml), ("Microsoft ML Buildings", "inferred", False))
        osm_ml = {"height": 5.4, "sources": [{"dataset": "OpenStreetMap", "record_id": "w1@2"},
                                             {"dataset": "Microsoft ML Buildings", "property": "/properties/height"}]}
        self.assertEqual(H.height_source(osm_ml), ("Microsoft ML Buildings", "property", True))
        osm_usgs = {"height": 7.7, "sources": [{"dataset": "OpenStreetMap", "record_id": "w1@1"},
                                               {"dataset": "USGS Lidar", "property": "/properties/height"}]}
        self.assertEqual(H.height_source(osm_usgs), ("USGS Lidar", "property", True))
        self.assertEqual(H.height_source({"sources": [{"dataset": "OpenStreetMap"}]}), (None, None, True))

    def test_height_source_osm_only_root(self):
        # OSM is the only (geometry) source and a height is present: the height is OSM's own.
        self.assertEqual(H.height_source({"height": 9.0, "sources": [{"dataset": "OpenStreetMap"}]}), ("OpenStreetMap", "inferred", True))

    def test_groups(self):
        self.assertEqual(H.group_of("Microsoft ML Buildings", False), "msOsmFree")
        self.assertEqual(H.group_of("Microsoft ML Buildings", True), "msOsmMatched")
        self.assertEqual(H.group_of("USGS Lidar", True), "usgsOsmMatched")
        self.assertEqual(H.group_of("Esri Community Maps", False), "other")

    def test_stratum(self):
        names = PRM["strataNames"]
        self.assertEqual(H.stratum(20, PRM["strataAreaM2"], names), "under45")
        self.assertEqual(H.stratum(45, PRM["strataAreaM2"], names), "45to90")
        self.assertEqual(H.stratum(200, PRM["strataAreaM2"], names), "90plus")

    def test_record_polygon_area(self):
        # 0.0001 deg of latitude is about 11.1 m; of longitude about 8.28 m at 42 N.
        lat0, lon0 = 42.0, -87.7
        ring = [[lon0, lat0], [lon0 + 0.0001, lat0], [lon0 + 0.0001, lat0 + 0.0001], [lon0, lat0 + 0.0001], [lon0, lat0]]
        poly = H.record_polygon({"polygons": [[ring]]}, lat0, lon0)
        self.assertAlmostEqual(poly.area, 11.107 * 8.28, delta=0.5)


class Measure(unittest.TestCase):
    def setUp(self):
        self.poly = footprint()
        self.roof = gable_cloud(self.poly)
        self.ground = ground_cloud(self.poly)

    def test_gable_top_and_eave(self):
        r = H.measure(self.poly, self.roof, self.ground, PRM)
        self.assertEqual(r["status"], "ok")
        self.assertEqual(r["groundMode"], "ring")
        ridge = 6.0 + 4.0 * math.tan(math.radians(35))  # 8.80 above ground
        self.assertAlmostEqual(r["top"] + 0, ridge, delta=0.25)  # p95 of a gable sits just under the ridge
        self.assertLessEqual(r["top"], ridge + 0.1)
        # The eave estimate is a little above the true eave (0.5 m of erosion on a 35 degree slope).
        self.assertGreaterEqual(r["eave"], 6.0 - 0.1)
        self.assertLessEqual(r["eave"], 6.0 + 0.7)
        self.assertAlmostEqual(r["span"], r["top"] - r["eave"], places=9)
        self.assertGreater(r["cover"], 0.9)

    def test_ground_offset_is_removed(self):
        up = self.ground.copy()
        up[:, 2] += 3.0
        roof = self.roof.copy()
        roof[:, 2] += 3.0
        a = H.measure(self.poly, self.roof, self.ground, PRM)
        b = H.measure(self.poly, roof, up, PRM)
        self.assertAlmostEqual(a["top"], b["top"], places=6)

    def test_no_building_points(self):
        r = H.measure(self.poly, self.roof[:0], self.ground, PRM)
        self.assertEqual(r["status"], "noBuilding")
        self.assertEqual(r["points"], 0)

    def test_few_points_with_cover(self):
        # Under minBuildingPoints but spread over the roof: counted as too few, not as absent.
        roof = self.roof[:: max(1, len(self.roof) // 15)]
        r = H.measure(self.poly, roof, self.ground, PRM, fallback_ground=GROUND_Z)
        self.assertLess(r["points"], PRM["minBuildingPoints"])
        self.assertIn(r["status"], ("fewPoints", "noBuilding"))

    def test_partial_cover(self):
        # Only the western third of the roof has points (the rest was built after the flight).
        roof = self.roof[self.roof[:, 0] < -2.0]
        r = H.measure(self.poly, roof, self.ground, PRM)
        self.assertEqual(r["status"], "partial")
        self.assertLess(r["cover"], PRM["minRoofCover"])

    def test_too_small_and_eroded(self):
        self.assertEqual(H.measure(footprint(3, 3), self.roof, self.ground, PRM)["status"], "tooSmall")
        self.assertEqual(H.measure(footprint(20, 1.0), self.roof, self.ground, PRM)["status"], "eroded")

    def test_ground_fallbacks(self):
        ring = PRM["groundRing"]
        g, n, mode = H.ground_level(self.ground, self.poly, ring)
        self.assertEqual(mode, "ring")
        self.assertAlmostEqual(g, GROUND_Z, delta=0.05)
        # Only points 10-14 m away: the 3-8 m ring is empty, the wide ring (15 m) finds them.
        far = self.ground[(np.abs(self.ground[:, 0]) >= 16) | (np.abs(self.ground[:, 1]) >= 14)]
        g, n, mode = H.ground_level(far, self.poly, ring)
        self.assertEqual(mode, "wide")
        # None at all: no level, the caller falls back to its ground model.
        self.assertEqual(H.ground_level(self.ground[:0], self.poly, ring)[2], "none")
        r = H.measure(self.poly, self.roof, self.ground[:0], PRM, fallback_ground=GROUND_Z)
        self.assertEqual(r["groundMode"], "model")
        self.assertEqual(r["status"], "ok")
        r2 = H.measure(self.poly, self.roof, self.ground[:0], PRM, fallback_ground=None)
        self.assertEqual(r2["status"], "noGround")

    def test_flat_roof_has_no_span(self):
        roof = gable_cloud(self.poly, pitch=0.0)
        r = H.measure(self.poly, roof, self.ground, PRM)
        self.assertAlmostEqual(r["top"], 6.0, delta=0.15)
        self.assertAlmostEqual(r["span"], 0.0, delta=0.15)


class Statistics(unittest.TestCase):
    def test_error_stats_known(self):
        ref = np.array([6.0, 8.0, 9.0, 10.0, 7.0])
        ov = ref - 3.0
        s = H.error_stats(ov, ref, within=1.5)
        self.assertEqual(s["n"], 5)
        self.assertAlmostEqual(s["bias"], -3.0)
        self.assertAlmostEqual(s["medianAbsError"], 3.0)
        self.assertEqual(s["withinShare"], 0.0)
        self.assertAlmostEqual(s["slopeOvOnRef"], 1.0, places=6)
        self.assertAlmostEqual(s["interceptOvOnRef"], -3.0, places=6)
        self.assertAlmostEqual(s["pearsonR"], 1.0, places=6)

    def test_error_stats_compressed_range(self):
        rng = np.random.default_rng(3)
        ref = rng.uniform(5, 12, 400)
        ov = 3.0 + 0.4 * ref + rng.normal(0, 0.3, 400)  # a compressed, biased estimator
        s = H.error_stats(ov, ref)
        self.assertAlmostEqual(s["slopeOvOnRef"], 0.4, delta=0.05)
        self.assertLess(s["bias"], 0)
        # Regressing the reference on the estimator gives the steeper line a correction would use.
        self.assertGreater(s["slopeRefOnOv"], 1.0)

    def test_spearman(self):
        x = np.arange(10.0)
        self.assertAlmostEqual(H.spearman(x, x ** 3), 1.0)
        self.assertAlmostEqual(H.spearman(x, -x), -1.0)
        self.assertIsNone(H.spearman(x, np.ones(10)))
        self.assertIsNone(H.spearman(x[:2], x[:2]))

    def test_error_stats_empty(self):
        self.assertEqual(H.error_stats([], []), {"n": 0})
        self.assertIsNone(H.error_stats([5, 5, 5], [6, 7, 8])["slopeRefOnOv"])  # no spread in the estimator

    def test_low_high(self):
        ov = np.array([5.0, 5.5, 5.9, 6.5, 8.0, 9.0])
        ref = np.array([8.0, 9.0, 5.5, 9.0, 8.0, 9.0])
        s = H.low_high(ov, ref, low=6.0, high=7.5)
        self.assertEqual(s["lidarHighN"], 5)
        self.assertEqual(s["overtureLowGivenLidarHigh"], 2)
        self.assertAlmostEqual(s["overtureLowGivenLidarHighShare"], 2 / 5)
        self.assertEqual(s["overtureLowN"], 3)
        self.assertAlmostEqual(s["lidarHighGivenOvertureLowShare"], 2 / 3, places=3)

    def test_binned_conditional(self):
        ov = np.array([4.5] * 6 + [7.5] * 6)
        ref = np.array([8.0, 8.5, 9.0, 9.5, 10.0, 7.0] + [9.0] * 6)
        rows = H.binned_conditional(ov, ref, [0, 3, 5, 8, 100], min_n=5)
        self.assertEqual(rows[0]["suppressed"], True)
        self.assertEqual(rows[1]["overtureBin"], "3-5")
        self.assertEqual(rows[1]["n"], 6)
        self.assertAlmostEqual(rows[1]["lidarMedian"], 8.75)
        self.assertAlmostEqual(rows[1]["lidarHighShare"], 5 / 6, places=3)

    def test_suppress_small(self):
        self.assertEqual(H.suppress({"x": 1}, 4, 5), {"n": 4, "suppressed": True})
        self.assertEqual(H.suppress({"x": 1}, 5, 5), {"x": 1})

    def test_cv_linear_recovers_line(self):
        rng = np.random.default_rng(4)
        ov = rng.uniform(3, 8, 200)
        ref = 2.0 + 1.3 * ov + rng.normal(0, 0.2, 200)
        pred = H.cv_linear(ov, ref, 5)
        self.assertLess(float(np.median(np.abs(pred - ref))), 0.3)

    def test_cv_binned_uses_training_folds_only(self):
        ov = np.array([4.0] * 20 + [7.0] * 20)
        ref = np.array([8.0] * 20 + [9.0] * 20)
        pred = H.cv_binned(ov, ref, [0, 5, 100], 5, min_n=3)
        self.assertTrue(np.allclose(pred[:20], 8.0) and np.allclose(pred[20:], 9.0))


class Floors(unittest.TestCase):
    def test_floors_from_height(self):
        # round((height - rise) / perFloor), halves up (as Swift's .rounded()), at least 1.
        self.assertEqual(H.floors_from_height(5.72, 2.8, 3.0), 1)
        self.assertEqual(H.floors_from_height(9.5, 2.8, 3.0), 2)
        self.assertEqual(H.floors_from_height(7.0, 2.5, 3.0), 2)  # 1.5 -> 2
        self.assertEqual(H.floors_from_height(3.0, 2.8, 3.0), 1)  # floor at 1
        self.assertEqual(H.floors_from_height(12.4, 0.0, 3.2), 4)

    def test_floors_eval(self):
        eff = [5.7, None, 9.5, 9.5]
        rise = [2.8, 2.8, 2.8, 2.8]
        truth = [2, 2, 2, 3]
        e = H.floors_eval(eff, rise, truth, fallback=2, per_floor=3.0)
        # derived: 1 (5.7), 2 (fallback), 2 (9.5), 2 (9.5)
        self.assertEqual(e["floorsDistribution"], {"1": 1, "2": 3, "3plus": 0})
        self.assertAlmostEqual(e["exactShare"], 2 / 4)
        self.assertAlmostEqual(e["lowerThanLidarShare"], 2 / 4)
        self.assertAlmostEqual(e["heightKeptShare"], 3 / 4)

    def test_plan_depths(self):
        sizes = {"0-0-0-0": 10, "1-0-0-0": 20, "1-1-0-0": 30, "2-0-0-0": 100}
        table, best = H.plan_depths(list(sizes), sizes, budget=70)
        self.assertEqual(best, 1)
        self.assertEqual(table[1]["cumulativeBytes"], 60)
        self.assertEqual(table[2]["cumulativeBytes"], 160)


class Selection(unittest.TestCase):
    def test_analysed(self):
        ok = {"status": "ok", "top": 8.0, "points": 40, "cover": 0.9}
        self.assertTrue(H.analysed(ok, PRM))
        self.assertFalse(H.analysed(dict(ok, points=19), PRM))
        self.assertFalse(H.analysed(dict(ok, cover=0.4), PRM))
        self.assertFalse(H.analysed(dict(ok, status="tooSmall"), PRM))
        self.assertTrue(H.analysed(dict(ok, points=19), PRM, min_points=10))
        self.assertFalse(H.analysed(dict(ok, status="noGround", top=None), PRM))

    def test_status_counts(self):
        rows = [{"status": "ok", "top": 8.0, "points": 40, "cover": 0.9}, {"status": "noBuilding", "points": 0, "cover": 0.0},
                {"status": "partial", "top": 7.0, "points": 40, "cover": 0.3}, {"status": "tooSmall"}]
        c = H.status_counts(rows, PRM)
        self.assertEqual(c, {"analysed": 1, "noBuilding": 1, "partial": 1, "tooSmall": 1})


if __name__ == "__main__":
    unittest.main()
