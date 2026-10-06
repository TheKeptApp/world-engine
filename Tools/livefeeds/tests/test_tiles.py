import unittest

from livefeeds import tiles
from livefeeds.tiles import AreaError, Rect


class TileMathTests(unittest.TestCase):
    def test_known_tiles(self):
        # (0, 0) is the corner shared by tiles 8191/8192 at zoom 14.
        self.assertEqual(tiles.tile_xy(0.0, 0.0), (8192, 8192))
        self.assertEqual(tiles.tile_xy(0.0001, -0.0001), (8191, 8191))
        # Reference values from the OpenStreetMap slippy-map formulas (zoom 14).
        self.assertEqual(tiles.tile_xy(39.7500, -104.9900), (3413, 6217))
        self.assertEqual(tiles.tile_xy(51.4778, -0.0015), (8191, 5450))

    def test_bounds_contain_the_point_and_tile_size_is_about_right(self):
        lat, lon = 39.75, -104.99
        x, y = tiles.tile_xy(lat, lon)
        s, w, n, e = tiles.tile_bounds(x, y)
        self.assertTrue(s <= lat < n and w <= lon < e)
        # about 1.9 km on a side at this latitude (live-feeds.md 4.3)
        self.assertAlmostEqual((n - s) * 111.2, 1.88, delta=0.1)
        self.assertAlmostEqual((e - w) * 111.32 * 0.7686, 1.88, delta=0.1)

    def test_bounds_of_adjacent_tiles_share_edges(self):
        a = tiles.tile_bounds(3413, 6217)
        b = tiles.tile_bounds(3414, 6217)
        c = tiles.tile_bounds(3413, 6218)
        self.assertAlmostEqual(a[3], b[1])        # east of a == west of b
        self.assertAlmostEqual(a[0], c[2])        # south of a == north of c

    def test_clamps_at_the_poles_and_antimeridian(self):
        self.assertEqual(tiles.tile_xy(89.9, 0)[1], 0)
        self.assertEqual(tiles.tile_xy(-89.9, 0)[1], (1 << 14) - 1)
        self.assertEqual(tiles.tile_xy(0, 180.0)[0], (1 << 14) - 1)


class RectTests(unittest.TestCase):
    def test_bbox_snaps_outward_to_whole_tiles(self):
        r = tiles.rect_from_bbox(39.7495, -104.9905, 39.7505, -104.9895)
        s, w, n, e = r.bbox()
        self.assertLessEqual(s, 39.7495)
        self.assertLessEqual(w, -104.9905)
        self.assertGreaterEqual(n, 39.7505)
        self.assertGreaterEqual(e, -104.9895)
        # tile-aligned: the snapped box maps back to the same rectangle
        self.assertEqual(tiles.rect_from_bbox(s + 1e-7, w + 1e-7, n - 1e-7, e - 1e-7), r)

    def test_identical_views_share_a_canonical_rectangle(self):
        a = tiles.rect_from_bbox(39.7495, -104.9905, 39.7505, -104.9895)
        b = tiles.rect_from_bbox(39.7499, -104.9901, 39.7501, -104.9899)
        self.assertEqual(a, b)
        self.assertEqual(a.key(), "14/3413/6217/3413/6217")

    def test_three_by_three_view(self):
        x, y = 3413, 6217
        s = tiles.tile_bounds(x - 1, y + 1)[0] + 1e-6
        w = tiles.tile_bounds(x - 1, y)[1] + 1e-6
        n = tiles.tile_bounds(x + 1, y - 1)[2] - 1e-6
        e = tiles.tile_bounds(x + 1, y)[3] - 1e-6
        r = tiles.rect_from_bbox(s, w, n, e)
        self.assertEqual((r.columns, r.rows), (3, 3))
        self.assertEqual(len(list(r.tiles())), 9)

    def test_cap_is_four_by_four(self):
        ok = Rect(14, 100, 100, 103, 103)
        tiles._check_size(ok)
        with self.assertRaises(AreaError) as cm:
            tiles.parse_tiles("14/100/100/104/103")
        self.assertEqual(cm.exception.code, "area-too-large")
        with self.assertRaises(AreaError):
            tiles.rect_from_bbox(39.0, -105.5, 40.0, -104.5)

    def test_bbox_errors(self):
        for text in ("1,2,3", "a,b,c,d", "40,-105,39,-104", "39,-104,40,-105", "39,-105,40,nan", "-91,0,0,1",
                     "0,0,10,181", ""):
            with self.assertRaises(AreaError, msg=text) as cm:
                tiles.parse_bbox(text)
            self.assertEqual(cm.exception.code, "bad-bbox")

    def test_tiles_parameter_errors(self):
        for text in ("14/1/2/3", "14/a/2/3/4", "13/1/1/1/1", "14/5/5/4/5", "14/-1/0/0/0", "14/0/0/99999/0"):
            with self.assertRaises(AreaError, msg=text) as cm:
                tiles.parse_tiles(text)
            self.assertIn(cm.exception.code, ("bad-tiles", "area-too-large"))

    def test_parse_tiles_roundtrip(self):
        r = tiles.parse_tiles("14/3412/6216/3414/6218")
        self.assertEqual(r.key(), "14/3412/6216/3414/6218")
        self.assertEqual((r.columns, r.rows), (3, 3))

    def test_bbox_intersects(self):
        box = [39.40, -105.60, 40.30, -104.55]
        self.assertTrue(tiles.bbox_intersects(box, (39.7, -105.0, 39.8, -104.9)))
        self.assertTrue(tiles.bbox_intersects(box, (39.0, -106.0, 41.0, -104.0)))      # contains
        self.assertFalse(tiles.bbox_intersects(box, (41.0, -105.0, 41.1, -104.9)))
        self.assertFalse(tiles.bbox_intersects(box, (39.7, -120.0, 39.8, -119.9)))


if __name__ == "__main__":
    unittest.main()
