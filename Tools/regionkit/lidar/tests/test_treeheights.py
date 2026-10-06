"""Offline tests of the lidar tree-height pure functions (numpy, scipy; scikit-image for the watershed test).

Synthetic crowns (half-ellipsoids of known height and radius on a flat ground) are rasterised into a canopy
height model and run through the same tops -> crown regions -> statistics path the measurement uses.
"""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import treeheights as th  # noqa: E402

try:
    import skimage  # noqa: F401
    HAVE_SKIMAGE = True
except ImportError:  # pragma: no cover
    HAVE_SKIMAGE = False

PARAMS = json.load(open(os.path.join(os.path.dirname(HERE), "data", "trees.json")))["params"]
CELL = PARAMS["chmCell"]


def crown_surface(shape, cx, cy, height, radius, base_frac=0.35, cell=CELL):
    """Half-ellipsoid crown: from base_frac x height at the rim up to `height` over the centre (cx, cy in m)."""
    ny, nx = shape
    xx, yy = np.meshgrid((np.arange(nx) + 0.5) * cell, (np.arange(ny) + 0.5) * cell)
    d2 = ((xx - cx) ** 2 + (yy - cy) ** 2) / radius ** 2
    zb = base_frac * height
    return np.where(d2 < 1, zb + (height - zb) * np.sqrt(np.clip(1 - d2, 0, None)), 0.0).astype(np.float32)


def scene(trees, shape=(60, 60)):
    chm = np.zeros(shape, dtype=np.float32)
    for cx, cy, h, r in trees:
        chm = np.maximum(chm, crown_surface(shape, cx, cy, h, r))
    return chm


class ChmRaster(unittest.TestCase):
    def test_max_per_cell(self):
        x = np.array([0.2, 0.7, 1.4, 5.0])
        y = np.array([0.1, 0.9, 0.5, 5.0])
        h = np.array([3.0, 7.0, 4.0, 9.0])
        chm = th.chm_max(x, y, h, 0.0, 0.0, 3, 2, 1.0)
        self.assertEqual(chm.shape, (2, 3))
        self.assertEqual(float(chm[0, 0]), 7.0)  # two points in cell (0, 0): the maximum
        self.assertEqual(float(chm[0, 1]), 4.0)
        self.assertEqual(float(chm.sum()), 11.0)  # the point outside the grid and empty cells add nothing

    def test_smoothing_keeps_a_flat_surface(self):
        flat = np.full((20, 20), 8.0, dtype=np.float32)
        self.assertTrue(np.allclose(th.smooth_chm(flat, 1.0), 8.0, atol=1e-4))


class RoofClutter(unittest.TestCase):
    CFG = PARAMS["roofClutter"]

    def test_small_holes_are_filled_big_ones_and_border_gaps_are_not(self):
        m = np.ones((30, 30), dtype=bool)
        m[5:8, 5:8] = False      # 9-cell hole inside: filled
        m[15:25, 15:25] = False  # 100-cell hole: a courtyard, stays
        m[0, 10:13] = False      # touches the border: stays
        out = th.fill_small_holes(m, 60)
        self.assertTrue(out[6, 6])
        self.assertFalse(out[20, 20])
        self.assertFalse(out[0, 11])

    def test_wall_points_and_roof_edges_go_crowns_over_the_roof_stay(self):
        shape = (60, 60)
        bld = np.zeros(shape, dtype=np.float32)
        bld[20:36, 20:36] = 10.0                   # a 16 m square flat roof 10 m high
        veg = np.zeros(shape, dtype=np.float32)
        veg[19, 20:36] = 6.0                       # wall points just outside the roof edge
        veg[20, 20:36] = 9.8                       # roof-edge points classed as vegetation
        veg[28:31, 28:31] = 14.0                   # a crown 4 m above the roof
        veg[50:54, 5:9] = 12.0                     # a tree on open ground
        clean, removed = th.remove_roof_clutter(veg, bld, self.CFG)
        self.assertTrue(removed[19, 25] and removed[20, 25])
        self.assertEqual(float(clean[29, 29]), 14.0)
        self.assertEqual(float(clean[52, 7]), 12.0)
        self.assertEqual(int(removed[50:54, 5:9].sum()), 0)

    def test_courtyard_tree_stays_but_a_gap_in_the_roof_does_not_save_clutter(self):
        shape = (80, 80)
        bld = np.zeros(shape, dtype=np.float32)
        bld[10:60, 10:60] = 12.0
        bld[25:45, 25:45] = 0.0                    # a 400-cell courtyard
        bld[15:18, 15:18] = 0.0                    # a 9-cell gap in the roof
        veg = np.zeros(shape, dtype=np.float32)
        veg[33:37, 33:37] = 9.0                    # courtyard tree
        veg[15:18, 15:18] = 5.0                    # clutter in the roof gap
        clean, removed = th.remove_roof_clutter(veg, bld, self.CFG)
        self.assertEqual(float(clean[35, 35]), 9.0)
        self.assertTrue(removed[16, 16])

    def test_tops_on_roofs(self):
        roof = np.zeros((20, 20), dtype=bool)
        roof[5:15, 5:15] = True
        roof_h = np.where(roof, 8.0, 0.0).astype(np.float32)
        iy = np.array([10, 10, 10, 2])
        ix = np.array([10, 10, 10, 2])
        h = np.array([9.5, 12.9, 13.1, 6.0])  # rooftop plant, still below +5, a crown 5 m above, ground tree
        drop = th.tops_on_roofs(iy, ix, h, roof, roof_h, 5.0)
        self.assertEqual(drop.tolist(), [True, True, False, False])

    def test_building_cell_height_beside_a_cell_sets_the_roof_height_for_wall_points(self):
        # A wall cell next to a tall roof is judged against that roof, not against a low porch roof nearer to it.
        bld = np.zeros((40, 40), dtype=np.float32)
        bld[5:20, 5:20] = 12.0
        bld[21:25, 5:20] = 4.0        # a low porch roof one cell farther from the wall cell than the tall roof
        veg = np.zeros_like(bld)
        veg[20, 10] = 11.5            # wall points between the two roofs
        m = th.roof_clutter_masks(veg, bld, self.CFG)
        self.assertTrue(bool(m["clutter"][20, 10]))
        self.assertGreaterEqual(float(m["roof_h"][20, 10]), 12.0)

    def test_no_buildings_changes_nothing(self):
        veg = np.full((10, 10), 5.0, dtype=np.float32)
        clean, removed = th.remove_roof_clutter(veg, np.zeros_like(veg), self.CFG)
        self.assertTrue(np.array_equal(clean, veg))
        self.assertFalse(removed.any())


class Window(unittest.TestCase):
    def test_radius_grows_with_height_and_is_clamped(self):
        win = PARAMS["window"]
        r = th.window_radius(np.array([0.0, 5.0, 15.0, 100.0]), win)
        self.assertEqual(float(r[0]), win["minRadius"])
        self.assertEqual(float(r[-1]), win["maxRadius"])
        self.assertTrue(r[1] <= r[2])


class Tops(unittest.TestCase):
    def tops(self, chm):
        return th.local_maxima(chm, CELL, PARAMS["window"], PARAMS["minTreeHeight"])

    def test_single_tree(self):
        chm = scene([(30.0, 30.0, 12.0, 4.0)])
        iy, ix, h = self.tops(chm)
        self.assertEqual(len(iy), 1)
        self.assertAlmostEqual(float(h[0]), 12.0, delta=0.2)
        self.assertLessEqual(abs(int(ix[0]) - 30), 1)
        self.assertLessEqual(abs(int(iy[0]) - 30), 1)

    def test_two_separate_trees(self):
        chm = scene([(15.0, 30.0, 12.0, 4.0), (40.0, 30.0, 9.0, 3.0)])
        iy, ix, h = self.tops(chm)
        self.assertEqual(len(iy), 2)
        self.assertEqual(sorted(round(float(v)) for v in h), [9, 12])

    def test_two_adjacent_crowns_stay_two(self):
        # Neighbouring street trees whose crowns touch but whose tops are 8 m apart.
        chm = scene([(22.0, 30.0, 14.0, 5.0), (30.0, 30.0, 14.0, 5.0)])
        iy, ix, _ = self.tops(chm)
        self.assertEqual(len(iy), 2)

    def test_twig_spike_on_one_crown_is_one_tree(self):
        # A leaf-off crown with two high branches 1.5 m apart is one tree: the window is wider than that.
        chm = scene([(30.0, 30.0, 14.0, 5.0)])
        chm[30, 28] = max(chm[30, 28], 14.2)
        chm[30, 30] = max(chm[30, 30], 14.1)
        iy, _, _ = self.tops(chm)
        self.assertEqual(len(iy), 1)

    def test_plateau_gives_one_top(self):
        chm = np.zeros((30, 30), dtype=np.float32)
        chm[10:14, 10:14] = 10.0
        iy, _, _ = self.tops(chm)
        self.assertEqual(len(iy), 1)

    def test_below_minimum_height_is_ignored(self):
        chm = scene([(30.0, 30.0, 2.8, 2.0)])
        iy, _, _ = self.tops(chm)
        self.assertEqual(len(iy), 0)

    def test_sorted_tallest_first(self):
        chm = scene([(15.0, 15.0, 8.0, 3.0), (45.0, 45.0, 16.0, 5.0), (15.0, 45.0, 11.0, 4.0)])
        _, _, h = self.tops(chm)
        self.assertTrue(all(h[i] >= h[i + 1] for i in range(len(h) - 1)))


@unittest.skipUnless(HAVE_SKIMAGE, "scikit-image not installed")
class Crowns(unittest.TestCase):
    def measure(self, chm):
        sm = th.smooth_chm(chm, PARAMS["smoothSigma"])
        iy, ix, _ = th.local_maxima(sm, CELL, PARAMS["window"], PARAMS["minTreeHeight"])
        h = np.array([chm[max(y - 1, 0):y + 2, max(x - 1, 0):x + 2].max() for y, x in zip(iy, ix)])
        labels = th.watershed_labels(sm, iy, ix, PARAMS["crown"]["minAbsoluteHeight"])
        return h, th.crown_measures(sm, labels, iy, ix, h, CELL, PARAMS["crown"])

    def test_isolated_crown_radius_is_recovered(self):
        for height, radius in [(8.0, 2.7), (14.0, 4.7), (20.0, 7.0)]:
            chm = scene([(40.0, 40.0, height, radius)], shape=(80, 80))
            h, cm = self.measure(chm)
            self.assertEqual(len(h), 1)
            self.assertAlmostEqual(float(h[0]), height, delta=0.3)
            self.assertAlmostEqual(float(cm["radius"][0]), radius, delta=0.15 * radius + 0.3)
            self.assertTrue(bool(cm["free"][0]))

    def test_touching_crowns_are_not_free_and_do_not_overlap(self):
        chm = scene([(22.0, 30.0, 14.0, 5.0), (31.0, 30.0, 14.0, 5.0)])
        h, cm = self.measure(chm)
        self.assertEqual(len(h), 2)
        self.assertFalse(bool(cm["free"].any()))
        smooth = th.smooth_chm(chm, PARAMS["smoothSigma"])
        covered = int((smooth >= PARAMS["crown"]["minAbsoluteHeight"]).sum())
        self.assertLessEqual(int(cm["cells"].sum()), covered)  # basins partition the cover; no cell counted twice

    def test_crown_radius_of_area(self):
        self.assertAlmostEqual(th.crown_radius(math.pi * 9.0), 3.0, places=9)
        self.assertEqual(th.crown_radius(0.0), 0.0)


class Statistics(unittest.TestCase):
    def test_percentiles(self):
        s = th.percentile_summary(np.arange(1, 101), [10, 25, 50, 75, 90], 5)
        self.assertEqual(s["n"], 100)
        self.assertAlmostEqual(s["p50"], 50.5, places=6)
        self.assertAlmostEqual(s["p25"], 25.75, places=6)
        self.assertAlmostEqual(s["p90"], 90.1, places=6)
        self.assertAlmostEqual(s["mean"], 50.5, places=6)

    def test_small_samples_report_only_the_count(self):
        self.assertEqual(th.percentile_summary([1.0, 2.0, 3.0], [50], 5), {"n": 3})
        self.assertEqual(th.percentile_summary([], [50], 5), {"n": 0})

    def test_non_finite_values_are_dropped(self):
        s = th.percentile_summary([1.0, np.nan, 3.0, np.inf, 5.0, 7.0, 9.0], [50], 5)
        self.assertEqual(s["n"], 5)
        self.assertAlmostEqual(s["p50"], 5.0)

    def test_share_below(self):
        self.assertAlmostEqual(th.share_below([3, 5, 7, 7, 9, 12], 7.0), 2 / 6)
        self.assertTrue(math.isnan(th.share_below([], 7.0)))

    def test_ratio_fit_recovers_a_known_slope(self):
        h = np.linspace(4, 24, 40)
        fit = th.fit_ratio(h, 0.3 * h)
        self.assertAlmostEqual(fit["throughOrigin"], 0.3, places=4)
        self.assertAlmostEqual(fit["medianRatio"], 0.3, places=4)
        self.assertAlmostEqual(fit["linearSlope"], 0.3, places=4)
        self.assertAlmostEqual(fit["linearIntercept"], 0.0, places=4)
        self.assertAlmostEqual(fit["pearson"], 1.0, places=4)

    def test_ratio_fit_with_intercept(self):
        h = np.linspace(4, 24, 40)
        fit = th.fit_ratio(h, 1.0 + 0.2 * h)
        self.assertAlmostEqual(fit["linearSlope"], 0.2, places=4)
        self.assertAlmostEqual(fit["linearIntercept"], 1.0, places=4)
        self.assertGreater(fit["throughOrigin"], 0.2)

    def test_ratio_fit_needs_data(self):
        self.assertEqual(th.fit_ratio([5.0, 6.0], [1.0, 2.0]), {"n": 2})

    def test_mesh_ratio_for_the_generators_archetypes(self):
        lobe = {"broad": 0.29, "oval": 0.19, "spreading": 0.36}
        mean, rms = th.mesh_radius_ratio({"broad": 1.0}, lobe)
        self.assertAlmostEqual(mean, 0.3335, places=4)
        self.assertAlmostEqual(rms, 0.3335, places=4)
        mean, rms = th.mesh_radius_ratio({"broad": 0.4, "oval": 0.2, "spreading": 0.4}, lobe)
        self.assertAlmostEqual(mean, 0.3427, places=3)
        self.assertGreater(rms, mean)


if __name__ == "__main__":
    unittest.main()
