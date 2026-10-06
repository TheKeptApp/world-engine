"""Offline tests of the lidar pilot's pure functions (numpy, scipy, shapely; no network, no lidar data).

Synthetic roofs (gable, hip, flat, cross-gable on an L footprint) are sampled as noisy point clouds and as
triangle meshes, then run through the same planes -> raster -> classifier path the pilot uses.
"""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import roofplanes as rp  # noqa: E402

PARAMS = json.load(open(os.path.join(os.path.dirname(HERE), "data", "params.json")))


def roof_z(kind, x, y, L=12.0, W=8.0, pitch=35.0, h0=6.0):
    t = math.tan(math.radians(pitch))
    if kind == "gable":
        return h0 + (W / 2 - np.abs(y)) * t
    if kind == "hip":
        return h0 + np.minimum(W / 2 - np.abs(y), L / 2 - np.abs(x)) * t
    if kind == "flat":
        return np.full_like(x, h0)
    if kind == "cross":  # L footprint: main gable along x (y in [-4, 4]) + wing gable along y at x in [2, 6], y in [-4, 10]
        main = np.where(np.abs(y) <= 4, h0 + (4 - np.abs(y)) * t, -np.inf)
        wing = np.where((x >= 2) & (x <= 6), h0 + (2 - np.abs(x - 4)) * t, -np.inf)
        return np.maximum(main, wing)
    raise ValueError(kind)


def footprint(kind):
    from shapely.geometry import Polygon
    if kind == "cross":
        return Polygon([(-6, -4), (6, -4), (6, 10), (2, 10), (2, 4), (-6, 4)])
    return Polygon([(-6, -4), (6, -4), (6, 4), (-6, 4)])


def cloud(kind, density=15.0, noise=0.03, seed=1):
    rng = np.random.default_rng(seed)
    fp = footprint(kind)
    x0, y0, x1, y1 = fp.bounds
    n = int(density * fp.area)
    import shapely
    pts = []
    while len(pts) < n:
        x = rng.uniform(x0, x1, n)
        y = rng.uniform(y0, y1, n)
        ok = shapely.contains_xy(fp, x, y)
        z = roof_z(kind, x[ok], y[ok])
        pts += list(zip(x[ok], y[ok], z + rng.normal(0, noise, ok.sum())))
    return np.array(pts[:n]), fp


def classify_cloud(kind, **kw):
    import shapely
    P, fp = cloud(kind, **kw)
    er = fp.buffer(-PARAMS["footprintErosion"])
    x0, y0, x1, y1 = er.bounds
    gx, gy = rp.raster_cells((x0, y0), (x1, y1), PARAMS["cell"])
    inside = shapely.contains_xy(er, gx, gy)
    P = P[shapely.contains_xy(er, P[:, 0], P[:, 1])]
    res, _ = rp.roof_from_points(P, gx, gy, inside, rp.min_area_rect(np.array(er.exterior.coords)), PARAMS)
    return res


class Coordinates(unittest.TestCase):
    def test_mercator_round_trip(self):
        lon, lat = np.array([-87.6912, -105.0445]), np.array([42.0372, 39.7494])
        x, y = rp.lonlat_to_merc(lon, lat)
        lo2, la2 = rp.merc_to_lonlat(x, y)
        self.assertTrue(np.allclose(lo2, lon, atol=1e-10) and np.allclose(la2, lat, atol=1e-10))

    def test_local_en_scale(self):
        # 0.001 deg of latitude is about 111.07 m at 42 N; of longitude about 82.8 m.
        e, n = rp.local_en(42.0, -87.7, 42.001, -87.7)
        self.assertAlmostEqual(float(n), 111.07, delta=0.1)
        e, n = rp.local_en(42.0, -87.7, 42.0, -87.699)
        self.assertAlmostEqual(float(e), 82.8, delta=0.2)

    def test_ept_node_bounds(self):
        root = [0, 0, 0, 1024, 1024, 1024]
        self.assertEqual(rp.ept_node_bounds(root, "0-0-0-0"), [0, 0, 0, 1024, 1024, 1024])
        self.assertEqual(rp.ept_node_bounds(root, "2-1-3-0"), [256, 768, 0, 512, 1024, 256])
        self.assertAlmostEqual(rp.rect_overlap_share([0, 0, 0, 10, 10, 10], (5, 5, 20, 20)), 0.25)
        self.assertEqual(rp.rect_overlap_share([0, 0, 0, 10, 10, 10], (11, 11, 20, 20)), 0.0)


class Planes(unittest.TestCase):
    def test_fit_plane_pitch_aspect(self):
        rng = np.random.default_rng(0)
        x, y = rng.uniform(0, 5, 200), rng.uniform(0, 5, 200)
        z = 3 - x * math.tan(math.radians(30))  # falls towards +x (east)
        n, _, rms = rp.fit_plane(np.stack([x, y, z], 1))
        pitch, aspect = rp.pitch_aspect(n)
        self.assertAlmostEqual(pitch, 30, places=3)
        self.assertAlmostEqual(aspect, 90, places=3)
        self.assertLess(rms, 1e-9)

    def test_cluster_planes(self):
        n1 = np.array([0, 0.5, 0.866])
        n2 = np.array([0, -0.5, 0.866])
        ids = rp.cluster_planes(np.array([n1, n1, n2, n1]), np.array([1.0, 1.02, 1.0, 3.0]), 2.0, 0.08)
        self.assertEqual(list(ids), [0, 0, 1, 2])

    def test_triangles_top_grid_upper_envelope(self):
        low = [[0, 0, 1], [4, 0, 1], [0, 4, 1]]
        high = [[0, 0, 2], [4, 0, 2], [0, 4, 2]]
        gx, gy = rp.raster_cells((0, 0), (4, 4), 0.5)
        best = rp.triangles_top_grid(np.array([low, high], float), gx, gy, 0.05)
        self.assertTrue((best[best >= 0] == 1).all())
        self.assertEqual(best[0, 0], 1)
        self.assertEqual(best[-1, -1], -1)


class Classifier(unittest.TestCase):
    def test_gable(self):
        r = classify_cloud("gable")
        self.assertEqual((r["simple"], r["form"]), ("gable", "gable"), r)
        self.assertAlmostEqual(r["pitch"], 35, delta=2)
        self.assertAlmostEqual(r["ridge"], 90, delta=5)  # ridge along x = east-west, bearing 90

    def test_hip(self):
        r = classify_cloud("hip", seed=2)
        self.assertEqual((r["simple"], r["form"]), ("hip", "hip"), r)

    def test_flat(self):
        r = classify_cloud("flat", seed=3)
        self.assertEqual(r["form"], "flat", r)

    def test_cross_gable_is_complex(self):
        r = classify_cloud("cross", seed=4)
        self.assertTrue(r["complex"], r)
        self.assertEqual(r["form"], "complex")

    def test_sparse_density_still_gable(self):
        r = classify_cloud("gable", density=4.0, seed=5)
        self.assertEqual(r["form"], "gable", r)

    def test_sparse_hip(self):
        r = classify_cloud("hip", density=4.0, seed=6)
        self.assertEqual(r["simple"], "hip", r)

    def test_best_shift(self):
        a = np.zeros((20, 20), bool)
        a[5:10, 5:12] = True
        b = np.roll(np.roll(a, 2, 0), -3, 1)
        dx, dy, iou0, iou = rp.best_shift(a, b, 4)
        self.assertEqual((dx, dy), (-3, 2))
        self.assertAlmostEqual(iou, 1.0)

    def test_nearest_label_grid(self):
        gx, gy = rp.raster_cells((0, 0), (2, 1), 0.5)
        g = rp.nearest_label_grid(np.array([[0.2, 0.2], [1.8, 0.8]]), np.array([3, 7]), gx, gy, 0.6)
        self.assertEqual(g[0, 0], 3)
        self.assertEqual(g[1, 3], 7)
        self.assertEqual(g[0, 2], -1)

    def test_low_coverage_is_unknown(self):
        planes = [{"id": 0, "area": 5.0, "pitch": 30, "aspect": 0, "cx": 0, "cy": 0}]
        r = rp.classify_roof(planes, np.zeros((1, 2)), np.zeros(1, int), (0, 0, 1, 0, 6, 4), 80.0, PARAMS["classify"])
        self.assertEqual(r["form"], "unknown")


class ComplexRule2(unittest.TestCase):
    """The 2.0 complex rule (`rules` argument of classify_roof): dormers, porches and split slopes are not a second
    mass; a real cross gable still is. Rasters are built by hand: a 12 x 8 m roof on a 0.5 m grid (eroded footprint
    11 x 7 m), south half falls south (aspect 180), north half falls north (aspect 0)."""
    RULES = {"mergeAspectDeg": 15.0, "mergePitchDeg": 6.0, "minorShare": 0.07, "mixedMinShare": 0.25,
             "noPairMinPlanes": 2, "cellM": 0.5}
    RECT = (0.0, 0.0, 1.0, 0.0, 5.5, 3.5)

    def raster(self, assign):
        """assign(x, y) -> plane id; returns cells_xy, cell_plane for the 11 x 7 m eroded footprint."""
        xs = np.arange(-5.25, 5.5, 0.5)
        ys = np.arange(-3.25, 3.5, 0.5)
        cells = np.array([(x, y) for y in ys for x in xs])
        return cells, np.array([assign(x, y) for x, y in cells])

    def run_rules(self, planes, assign, rules):
        cells, cp = self.raster(assign)
        return rp.classify_roof(planes, cells, cp, self.RECT, 77.0, PARAMS["classify"], rules)

    @staticmethod
    def pl(pid, area, pitch, aspect, cx, cy):
        return {"id": pid, "area": area, "pitch": pitch, "aspect": aspect, "cx": cx, "cy": cy}

    def test_split_slope_is_one_slope(self):
        # north slope broken into two touching planes (a chimney or noise): 3 sloped planes under 1.0
        planes = [self.pl(1, 38.5, 35, 0, 0, 1.75), self.pl(2, 12.0, 36, 4, 3, 1.75), self.pl(3, 26.5, 35, 180, 0, -1.75)]
        assign = lambda x, y: 3 if y < 0 else (2 if x > 2.5 else 1)  # noqa: E731
        old = self.run_rules(planes, assign, None)
        new = self.run_rules(planes, assign, self.RULES)
        self.assertEqual(old["form"], "complex", old)
        self.assertEqual(new["form"], "gable", new)

    def test_small_dormer_plane_is_minor(self):
        # an 8 % steeper plane on the north slope: a dormer, not a wing
        planes = [self.pl(1, 30.0, 35, 0, 0, 1.75), self.pl(2, 6.2, 48, 0, 3, 1.75), self.pl(3, 38.5, 35, 180, 0, -1.75)]
        assign = lambda x, y: 3 if y < 0 else (2 if (x > 3 and y > 0.5) else 1)  # noqa: E731
        rules = {**self.RULES, "minorShare": 0.10}
        self.assertEqual(self.run_rules(planes, assign, None)["form"], "complex")
        self.assertEqual(self.run_rules(planes, assign, rules)["form"], "gable")

    def test_porch_flat_share_is_not_mixed(self):
        # a flat porch roof holding about a fifth of the roof
        planes = [self.pl(1, 30.0, 35, 0, 0, 1.75), self.pl(2, 15.0, 2, 0, 4, -1.75), self.pl(3, 32.0, 35, 180, 0, -1.75)]
        assign = lambda x, y: 3 if y < 0 and x < 2.0 else (2 if y < 0 else 1)  # noqa: E731
        old = self.run_rules(planes, assign, None)
        new = self.run_rules(planes, assign, self.RULES)
        self.assertIn("mixed flat and sloped", old["reasons"], old)
        self.assertNotIn("mixed flat and sloped", new["reasons"], new)

    def test_single_slope_is_not_complex(self):
        planes = [self.pl(1, 77.0, 25, 0, 0, 0)]
        assign = lambda x, y: 1  # noqa: E731
        old = self.run_rules(planes, assign, None)
        new = self.run_rules(planes, assign, self.RULES)
        self.assertTrue(old["complex"], old)
        self.assertFalse(new["complex"], new)

    def test_major_extra_masses_stay_complex(self):
        # a wing with its own slopes (two on-axis, one off-axis), each over a tenth of the roof: complex under 2.0
        planes = [self.pl(1, 20.0, 35, 0, -2, 1.75), self.pl(2, 20.0, 35, 180, -2, -1.75),
                  self.pl(3, 14.0, 35, 90, 4, 0), self.pl(4, 10.0, 35, 270, 2, 0), self.pl(5, 13.0, 30, 40, 4, 2)]
        assign = lambda x, y: (3 if y > 1.5 else (5 if y > 0 else 4)) if x > 1 else (1 if y > 0 else 2)  # noqa: E731
        res = self.run_rules(planes, assign, self.RULES)
        self.assertEqual(res["form"], "complex", res)

    def test_cross_gable_cloud_is_complex_under_new_rules(self):
        import shapely
        P, fp = cloud("cross", seed=4)
        er = fp.buffer(-PARAMS["footprintErosion"])
        x0, y0, x1, y1 = er.bounds
        gx, gy = rp.raster_cells((x0, y0), (x1, y1), PARAMS["cell"])
        inside = shapely.contains_xy(er, gx, gy)
        P = P[shapely.contains_xy(er, P[:, 0], P[:, 1])]
        res, _ = rp.roof_from_points(P, gx, gy, inside, rp.min_area_rect(np.array(er.exterior.coords)), PARAMS, self.RULES)
        self.assertEqual(res["form"], "complex", res)

    def test_merge_coplanar_keeps_far_apart_planes_apart(self):
        # two planes with the same aspect and pitch that do not touch stay two planes
        planes = [self.pl(1, 10.0, 35, 0, -3, 0), self.pl(2, 10.0, 35, 0, 3, 0)]
        cells = np.array([[-3.0, 0.0], [3.0, 0.0]])
        merged, cp = rp.merge_coplanar(planes, cells, np.array([1, 2]), self.RULES)
        self.assertEqual(len(merged), 2)
        self.assertEqual(list(cp), [1, 2])

    def test_merge_coplanar_joins_touching_aspects_across_north(self):
        planes = [self.pl(1, 10.0, 35, 356, 0, 0), self.pl(2, 10.0, 35, 5, 1, 0)]
        cells = np.array([[0.0, 0.0], [0.5, 0.0]])
        merged, cp = rp.merge_coplanar(planes, cells, np.array([1, 2]), self.RULES)
        self.assertEqual(len(merged), 1)
        self.assertAlmostEqual(merged[0]["area"], 20.0)
        self.assertLess(min(merged[0]["aspect"], 360 - merged[0]["aspect"]), 3)  # about north (0 / 360), not 180
        self.assertEqual(len(set(cp.tolist())), 1)


class Stats(unittest.TestCase):
    def test_wilson(self):
        lo, hi = rp.wilson(50, 100)
        self.assertAlmostEqual(lo, 0.4038, places=3)
        self.assertAlmostEqual(hi, 0.5962, places=3)
        self.assertEqual(rp.wilson(0, 0), (None, None))

    def test_kappa(self):
        m = rp.confusion([("a", "a")] * 20 + [("b", "b")] * 20 + [("a", "b")] * 5 + [("b", "a")] * 5, ["a", "b"])
        self.assertAlmostEqual(rp.kappa(m, ["a", "b"]), 0.6, places=4)

    def test_p2_mapping(self):
        self.assertEqual([rp.p2_simple(s) for s in ("gabled", "hipped", "flat", "slab", "x")],
                         ["gable", "hip", "flat", "flat", "unknown"])

    def test_stable_sample(self):
        ids = [f"way/{i}" for i in range(100)]
        a = rp.stable_sample(ids, 10, "s")
        self.assertEqual(a, rp.stable_sample(list(reversed(ids)), 10, "s"))
        self.assertEqual(len(set(a)), 10)

    def test_suppress_small(self):
        self.assertEqual(rp.suppress_small({"x": 1}, 4, 5), {"n": 4, "suppressed": True})
        self.assertEqual(rp.suppress_small({"x": 1}, 5, 5), {"x": 1})


if __name__ == "__main__":
    unittest.main()
