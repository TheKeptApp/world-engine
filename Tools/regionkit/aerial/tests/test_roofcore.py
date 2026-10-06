"""Offline tests of the pure functions in roofcore.py (numpy only, no network, no imagery)."""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import roofcore as rc  # noqa: E402

FAMILIES = json.load(open(os.path.join(os.path.dirname(HERE), "data", "roof_families.json")))
PARAMS = json.load(open(os.path.join(os.path.dirname(HERE), "data", "params.json")))


def fam(rgb):
    return rc.colour_family(rc.srgb_to_lab(np.array(rgb, dtype=float)), FAMILIES)


class Colour(unittest.TestCase):
    def test_lab_round_trip(self):
        for rgb in ([0, 0, 0], [255, 255, 255], [128, 64, 32], [12, 200, 90]):
            back = rc.lab_to_srgb(rc.srgb_to_lab(np.array(rgb, dtype=float)))
            self.assertTrue(np.allclose(back, rgb, atol=0.5), (rgb, back))

    def test_known_lab(self):
        L, a, b = rc.srgb_to_lab(np.array([255, 255, 255.0]))
        self.assertAlmostEqual(L, 100, places=2)
        self.assertAlmostEqual(a, 0, places=2)
        self.assertAlmostEqual(b, 0, places=2)

    def test_achromatic_bands(self):
        self.assertEqual(fam([40, 40, 42]), "black")
        self.assertEqual(fam([90, 90, 92]), "charcoal")
        self.assertEqual(fam([140, 140, 140]), "grey")
        self.assertEqual(fam([230, 230, 228]), "white")

    def test_chromatic_families(self):
        self.assertEqual(fam([150, 80, 60]), "red")
        self.assertEqual(fam([110, 88, 70]), "brown")
        self.assertEqual(fam([185, 160, 125]), "tan")
        self.assertEqual(fam([90, 130, 100]), "green")
        self.assertEqual(fam([80, 100, 150]), "blue")

    def test_dark_blue_cast_is_black(self):
        # very dark roofs in NAIP carry a blue cast: L* ~ 18, b* ~ -8 must stay achromatic
        self.assertEqual(rc.colour_family([18.0, 1.0, -8.0], FAMILIES), "black")

    def test_robust_colour_ignores_outliers(self):
        px = np.array([[100, 100, 100]] * 90 + [[255, 0, 0]] * 10)
        lab, hx = rc.robust_colour(px)
        self.assertEqual(hx, "#646464")

    def test_scene_relative_rules(self):
        rules = FAMILIES["sceneRelative"]
        neutral = (-1.8, 1.5)
        self.assertEqual(rc.colour_family_relative([45.0, 2.5, 6.0], neutral, rules), "brown")    # warm, dark
        self.assertEqual(rc.colour_family_relative([56.0, -1.5, 6.5], neutral, rules), "tan")     # warm, light
        self.assertEqual(rc.colour_family_relative([50.0, -2.0, 1.0], neutral, rules), "grey")    # near neutral
        self.assertEqual(rc.colour_family_relative([25.0, 0.0, -6.0], neutral, rules), "black")   # cool cast, dark
        self.assertEqual(rc.colour_family_relative([75.0, -1.0, 0.0], neutral, rules), "white")

    def test_scene_neutral_is_median(self):
        self.assertEqual(rc.scene_neutral([[50, -2, 1], [40, -1, 2], [60, 9, 9]]), (-1.0, 2.0))


class Geometry(unittest.TestCase):
    def test_min_area_rect_rotated(self):
        ang = math.radians(30)
        c, s = math.cos(ang), math.sin(ang)
        pts = [(x * c - y * s + 5, x * s + y * c - 3) for x, y in ((-5, -2), (5, -2), (5, 2), (-5, 2))]
        cx, cy, a, length, width = rc.min_area_rect(pts)
        self.assertAlmostEqual(length, 10, places=6)
        self.assertAlmostEqual(width, 4, places=6)
        self.assertAlmostEqual(a, ang, places=6)
        self.assertAlmostEqual(cx, 5, places=6)
        self.assertAlmostEqual(cy, -3, places=6)

    def test_shape_features_l_shape(self):
        ring = [(0, 0), (10, 0), (10, 4), (4, 4), (4, 10), (0, 10), (0, 0)]
        f = rc.shape_features(ring)
        self.assertAlmostEqual(f["area"], 64)
        self.assertAlmostEqual(f["rectangularity"], 0.64)
        self.assertEqual(f["vertices"], 6)


def _rect_case(values_by_label, model, noise=1.0, seed=1):
    """Synthetic 40 x 60 px roof: luminance per facet of `model` plus Gaussian noise."""
    shape = (40, 60)
    rect = (30.0, 20.0, 0.0, 60.0, 40.0)
    lab = rc.facet_labels(shape, rect, model)
    rng = np.random.default_rng(seed)
    lum = np.choose(lab, values_by_label).astype(float) + rng.normal(0, noise, shape)
    valid = np.ones(shape, dtype=bool)
    feats = rc.shape_features([(0, 0), (60, 0), (60, 40), (0, 40)])
    return lum, valid, rect, feats


class RoofType(unittest.TestCase):
    P = dict(PARAMS["roof"], minPixels=60)

    def test_gable(self):
        lum, valid, rect, feats = _rect_case([62, 44], "gable_long")
        t, conf, d = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual(t, "gable")
        self.assertEqual(d["ridge"], "long")

    def test_gable_across(self):
        lum, valid, rect, feats = _rect_case([62, 44], "gable_short")
        t, _, d = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual(t, "gable")
        self.assertEqual(d["ridge"], "short")

    def test_hip(self):
        lum, valid, rect, feats = _rect_case([62, 40, 55, 47], "hip")
        t, _, _ = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual(t, "hip")

    def test_flat(self):
        lum, valid, rect, feats = _rect_case([50, 50], "gable_long", noise=1.0)
        t, _, _ = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual(t, "flat")

    def test_complex_footprint(self):
        lum, valid, rect, _ = _rect_case([62, 44], "gable_long", noise=6.0)
        lshape = rc.shape_features([(0, 0), (10, 0), (10, 4), (4, 4), (4, 10), (0, 10)])
        t, _, _ = rc.classify_roof(lum, valid, rect, lshape, self.P)
        self.assertEqual(t, "complex")

    def test_textured_unexplained_is_complex(self):
        rng = np.random.default_rng(3)
        lum, valid, rect, feats = _rect_case([50, 50], "gable_long")
        lum = 50 + rng.normal(0, 12, lum.shape)
        t, _, _ = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual(t, "complex")

    def test_too_few_pixels_is_unknown(self):
        lum, valid, rect, feats = _rect_case([62, 44], "gable_long")
        valid[:] = False
        valid[0, :10] = True
        t, conf, _ = rc.classify_roof(lum, valid, rect, feats, self.P)
        self.assertEqual((t, conf), ("unknown", 0.0))

    def test_hip_labels_are_nearest_edge(self):
        lab = rc.facet_labels((40, 60), (30.0, 20.0, 0.0, 60.0, 40.0), "hip")
        self.assertEqual(lab[20, 2], 3)    # near the left short edge -> end facet
        self.assertEqual(lab[20, 57], 2)   # near the right short edge -> end facet
        self.assertEqual(lab[2, 30], 1)    # near the top long edge -> side facet (v < 0)
        self.assertEqual(lab[37, 30], 0)   # near the bottom long edge -> side facet (v > 0)


class Canopy(unittest.TestCase):
    def test_share(self):
        mask = np.zeros((10, 10), bool)
        mask[:5] = True
        region = np.zeros((10, 10), bool)
        region[:, :4] = True
        self.assertAlmostEqual(rc.share(mask, region), 0.5)
        self.assertIsNone(rc.share(mask, np.zeros((10, 10), bool)))

    def test_ndvi(self):
        self.assertAlmostEqual(float(rc.ndvi(np.array([50.0]), np.array([150.0]))[0]), 0.5)
        self.assertEqual(float(rc.ndvi(np.array([0.0]), np.array([0.0]))[0]), 0.0)

    def test_lawn_vs_crowns(self):
        """Smooth high-NDVI lawn -> vegetation, not canopy; lumpy high-NDVI crowns -> canopy; paving -> neither."""
        rng = np.random.default_rng(7)
        h, w = 90, 90
        red = np.full((h, w), 90.0)
        nir = np.full((h, w), 90.0)                       # paving: NDVI 0
        red[:, 30:60] = 65
        nir[:, 30:60] = 200 + rng.normal(0, 2, (h, 30))   # lawn: NDVI ~0.5, smooth
        red[:, 60:] = 45
        nir[:, 60:] = 150 + rng.normal(0, 35, (h, 30))    # crowns: NDVI ~0.5, lumpy
        veg, can = rc.canopy_mask(red, nir, PARAMS["canopy"], 0.3)
        self.assertLess(veg[:, :25].mean(), 0.01)
        self.assertGreater(veg[:, 35:55].mean(), 0.99)
        self.assertLess(can[:, 36:54].mean(), 0.05)
        self.assertGreater(can[:, 66:84].mean(), 0.9)

    def test_opening_removes_thin_lines(self):
        m = np.zeros((30, 30), bool)
        m[10:12, :] = True          # 2 px line
        m[18:28, 5:15] = True       # 10 px block
        o = rc.opening(m, 2)
        self.assertFalse(o[10:12, :].any())
        self.assertTrue(o[20:26, 7:13].all())


class Sampling(unittest.TestCase):
    def test_stable_sample_order_independent(self):
        ids = [f"id{i}" for i in range(100)]
        a = rc.stable_sample(ids, 10, "seed")
        b = rc.stable_sample(list(reversed(ids)), 10, "seed")
        self.assertEqual(a, b)
        self.assertNotEqual(a, rc.stable_sample(ids, 10, "other"))

    def test_suppress_small(self):
        stat = {"n": 4, "medianHex": "#123456", "medianLab": [1, 2, 3]}
        self.assertEqual(rc.suppress_small(stat, 5), {"n": 4, "suppressed": "n < 5"})
        big = {"n": 5, "medianHex": "#123456"}
        self.assertIs(rc.suppress_small(big, 5), big)
        self.assertIsNone(rc.suppress_small(None, 5))
        self.assertEqual(PARAMS["minGroupN"], 5)

    def test_confusion(self):
        m, acc, c, n = rc.confusion([("hip", "hip"), ("hip", "gable"), ("flat", "flat")], ["flat", "gable", "hip"])
        self.assertEqual((c, n), (2, 3))
        self.assertEqual(m["hip"]["gable"], 1)


if __name__ == "__main__":
    unittest.main()
