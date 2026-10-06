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


if __name__ == "__main__":
    unittest.main()
