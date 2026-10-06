import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import blockmath as bm  # noqa: E402


class BlockId(unittest.TestCase):
    def test_order_and_duplicates_do_not_matter(self):
        self.assertEqual(bm.block_id([3, 1, 2]), bm.block_id([2, 2, 1, 3]))

    def test_format_and_difference(self):
        a = bm.block_id([1, 2, 3])
        self.assertRegex(a, r"^cb-[0-9a-f]{8}$")
        self.assertNotEqual(a, bm.block_id([1, 2, 4]))

    def test_collision_suffix(self):
        a = bm.block_id([1, 2])
        b = bm.block_id([1, 2], taken={a})
        c = bm.block_id([1, 2], taken={a, b})
        self.assertEqual((b, c), (a + "-2", a + "-3"))

    def test_string_and_int_ids_agree(self):
        self.assertEqual(bm.block_id([10, 20]), bm.block_id(["20", "10"]))


class Spacing(unittest.TestCase):
    def test_density_and_spacing(self):
        r = bm.tree_estimate(0.42, 10000, 105, 400)
        self.assertAlmostEqual(r["trees"], 40.0, places=6)
        self.assertAlmostEqual(r["treesPerHa"], 40.0, places=6)
        self.assertAlmostEqual(r["gridSpacingM"], 15.811, places=2)
        self.assertAlmostEqual(r["frontageSpacingM"], 10.0, places=6)

    def test_scales_with_area(self):
        r = bm.tree_estimate(0.21, 25000, 105, 600)
        self.assertAlmostEqual(r["treesPerHa"], 20.0, places=6)
        self.assertAlmostEqual(r["trees"], 50.0, places=6)

    def test_range_orders(self):
        r = bm.tree_estimate(0.4, 10000, 100, 300, (92, 112))
        lo, hi = r["treesPerHaRange"]
        self.assertLess(lo, r["treesPerHa"])
        self.assertGreater(hi, r["treesPerHa"])

    def test_degenerate(self):
        self.assertIsNone(bm.tree_estimate(0.0, 10000, 105, 100))
        self.assertIsNone(bm.tree_estimate(None, 10000, 105, 100))
        self.assertIsNone(bm.tree_estimate(0.3, 0, 105, 100))

    def test_no_frontage_or_under_one_tree(self):
        self.assertIsNone(bm.tree_estimate(0.3, 10000, 105, 0)["frontageSpacingM"])
        self.assertIsNone(bm.tree_estimate(0.01, 1000, 105, 100)["frontageSpacingM"])


class Confidence(unittest.TestCase):
    def test_full_block(self):
        self.assertEqual(bm.block_confidence(0.86, 20000, True, 0.0), (0.86, "high"))

    def test_small_edge_park(self):
        v, t = bm.block_confidence(0.86, 2500, False, 20.0)
        self.assertAlmostEqual(v, 0.86 * 0.5 * 0.85 * 0.8, places=2)
        self.assertEqual(t, "low")

    def test_size_floor(self):
        self.assertEqual(bm.block_confidence(0.8, 500, True, 0)[0], 0.4)

    def test_tiers(self):
        self.assertEqual(bm.block_confidence(0.74, 10000, True, 0)[1], "medium")
        self.assertEqual(bm.block_confidence(0.59, 10000, True, 0)[1], "low")


class Calibration(unittest.TestCase):
    def test_wilson(self):
        lo, hi = bm.wilson_interval(50, 100)
        self.assertAlmostEqual(lo, 0.4038, places=3)
        self.assertAlmostEqual(hi, 0.5962, places=3)
        self.assertEqual(bm.wilson_interval(0, 0), (None, None))
        lo, hi = bm.wilson_interval(0, 20)
        self.assertAlmostEqual(lo, 0.0, places=9)
        self.assertGreater(hi, 0.1)

    def test_ratio_and_effective_crown(self):
        self.assertAlmostEqual(bm.ratio_of_sums([10, 20], [1, 2]), 10.0)
        self.assertAlmostEqual(bm.effective_crown_area([1500, 1000, 500], [10, 10, 10]), 100.0)
        self.assertIsNone(bm.ratio_of_sums([1], [0]))

    def test_bootstrap_deterministic_and_brackets(self):
        data = [(12, 1.0), (15, 1.1), (9, 0.9), (20, 1.5), (11, 1.0), (14, 1.2)]

        def stat(s):
            return bm.ratio_of_sums([x for x, _ in s], [y for _, y in s])
        r1 = bm.cluster_bootstrap(data, stat, n_boot=500, seed="t")
        self.assertEqual(r1, bm.cluster_bootstrap(data, stat, n_boot=500, seed="t"))
        est, lo, hi = r1
        self.assertLessEqual(lo, est)
        self.assertGreaterEqual(hi, est)
        self.assertNotEqual(r1, bm.cluster_bootstrap(data, stat, n_boot=500, seed="u"))

    def test_constant_data_has_zero_width_interval(self):
        data = [(10, 1.0)] * 8

        def stat(s):
            return bm.ratio_of_sums([x for x, _ in s], [y for _, y in s])
        self.assertEqual(bm.cluster_bootstrap(data, stat, n_boot=200), (10.0, 10.0, 10.0))

    def test_paired_difference(self):
        label = [1, 1, 0, 0, 1, 0, 0, 0]
        mask = [1, 1, 1, 1, 1, 0, 1, 0]
        d, lo, hi = bm.paired_difference_bootstrap(label, mask, n_boot=500)
        self.assertAlmostEqual(d, -3 / 8)
        self.assertLessEqual(lo, d)
        self.assertGreaterEqual(hi, d)
        self.assertLessEqual(hi, 0.0)


if __name__ == "__main__":
    unittest.main()
