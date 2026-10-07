"""Offline tests of the slope-grid pure functions (numpy + scipy; no network, no lidar data).

Synthetic ground point clouds (planes, a hole for a building) go through the same DTM, filter, slope and
encoding code as the real data.
"""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import slope as S  # noqa: E402


def plane_points(w, h, sx, sy, density=4.0, noise=0.0, seed=1, z0=180.0):
    rng = np.random.default_rng(seed)
    n = int(w * h * density)
    x = rng.uniform(-w / 2, w / 2, n)
    y = rng.uniform(-h / 2, h / 2, n)
    z = z0 + sx * x + sy * y + rng.normal(0, noise, n) if noise else z0 + sx * x + sy * y
    return np.stack([x, y, z], axis=1)


class GridTests(unittest.TestCase):
    def test_shape_and_index_orientation(self):
        cols, rows = S.grid_shape(40, 30)
        self.assertEqual((cols, rows), (40, 30))
        # south-west corner cell is index 0; north-east is the last; row 0 is the southern row
        idx = S.cell_index([-19.5, 19.5, -19.5, 25.0], [-14.5, 14.5, 14.5, 0.0], -20, -15, cols, rows)
        self.assertEqual(idx.tolist(), [0, rows * cols - 1, (rows - 1) * cols, -1])

    def test_mean_dtm(self):
        P = np.array([[0.2, 0.2, 1.0], [0.7, 0.4, 3.0], [1.5, 0.5, 5.0]])
        dtm, n = S.mean_dtm(P, 0, 0, 2, 2)
        self.assertAlmostEqual(dtm[0, 0], 2.0)
        self.assertAlmostEqual(dtm[0, 1], 5.0)
        self.assertTrue(np.isnan(dtm[1, 0]) and np.isnan(dtm[1, 1]))
        self.assertEqual(n.tolist(), [[2, 1], [0, 0]])

    def test_gap_fill_respects_2m(self):
        # points only in the west half; a hole wider than 2 m stays empty, a cell next to points is filled
        P = plane_points(20, 20, 0.0, 0.0, density=6)
        P = P[P[:, 0] < -3]
        dtm, _ = S.mean_dtm(P, -10, -10, 20, 20)
        dtm[5, 2] = np.nan  # a single empty cell surrounded by points
        filled = S.gap_fill(dtm, P, -10, -10, max_dist=2.0)
        self.assertTrue(np.isfinite(filled[5, 2]))
        self.assertAlmostEqual(filled[5, 2], 180.0, places=6)
        self.assertTrue(np.isfinite(filled[:, 7]).all())   # centre x = -2.5: within 2 m of points (x < -3)
        self.assertTrue(np.isnan(filled[:, 9:]).all())     # centre x >= -0.5: farther than 2 m
        self.assertTrue(np.isnan(filled[:, 15]).all())


class SlopeTests(unittest.TestCase):
    def test_horn_on_plane(self):
        for sx, sy in ((0.1, 0.0), (0.0, -0.25), (0.3, 0.4)):
            yy, xx = np.mgrid[0:20, 0:20].astype(float)
            z = 5 + sx * (xx + 0.5) + sy * (yy + 0.5)
            s = S.slope_pipeline(z)
            inner = s[2:-2, 2:-2]
            self.assertTrue(np.allclose(inner, 100 * math.hypot(sx, sy), atol=1e-9))
            self.assertTrue(np.isnan(s[0]).all() and np.isnan(s[:, -1]).all())  # edge -> no data

    def test_nodata_window(self):
        z = np.zeros((10, 10))
        z[5, 5] = np.nan
        s = S.horn_slope_percent(S.mean3x3(z))
        self.assertTrue(np.isnan(s[4:7, 4:7]).all())
        self.assertTrue(np.isfinite(s[1:4, 1:4]).all())
        self.assertEqual(float(np.nanmax(s)), 0.0)

    def test_mean3x3_keeps_nan(self):
        z = np.arange(25, dtype=float).reshape(5, 5)
        z[0, 0] = np.nan
        m = S.mean3x3(z)
        self.assertTrue(np.isnan(m[0, 0]))
        self.assertAlmostEqual(m[2, 2], 12.0)
        self.assertAlmostEqual(m[1, 1], np.mean([1, 2, 5, 6, 7, 10, 11, 12]))

    def test_end_to_end_noisy_plane(self):
        # 8 % slope towards the north-east, 6 points/m2, 3 cm noise: median within 1 point of truth
        P = plane_points(60, 60, 0.048, 0.064, density=6, noise=0.03, seed=3)
        dtm, _ = S.mean_dtm(P, -30, -30, 60, 60)
        dtm = S.gap_fill(dtm, P, -30, -30)
        s = S.slope_pipeline(dtm)
        self.assertLess(abs(np.nanmedian(s) - 8.0), 1.0)
        self.assertLess(np.nanpercentile(np.abs(s - 8.0), 90), 3.0)

    def test_building_hole_is_nodata(self):
        P = plane_points(40, 40, 0.05, 0.0, density=6, seed=4)
        hole = (np.abs(P[:, 0]) < 6) & (np.abs(P[:, 1]) < 6)
        P = P[~hole]
        dtm, _ = S.mean_dtm(P, -20, -20, 40, 40)
        dtm = S.gap_fill(dtm, P, -20, -20)
        q = S.quantize(S.slope_pipeline(dtm))
        self.assertTrue((q[18:22, 18:22] == S.NODATA).all())   # centre of the 12 m hole
        self.assertEqual(int(np.median(q[q != S.NODATA])), 10)  # 5 % -> 10


class EncodingTests(unittest.TestCase):
    def test_quantize(self):
        s = np.array([0.0, 0.24, 0.25, 7.3, 126.7, 126.8, 127.0, 400.0, np.nan, -0.1])
        self.assertEqual(S.quantize(s).tolist(), [0, 0, 1, 15, 253, 253, 254, 254, 255, 0])
        d = S.dequantize(np.array([0, 15, 254, 255], np.uint8))
        self.assertEqual(d[:3].tolist(), [0.0, 7.5, 127.0])
        self.assertTrue(np.isnan(d[3]))

    def test_raw_deflate_roundtrip(self):
        q = (np.arange(600).reshape(20, 30) % 256).astype(np.uint8)
        blob = S.encode(q)
        self.assertNotEqual(blob[:1], b"\x78")  # no zlib header
        self.assertTrue(np.array_equal(S.decode(blob, 30, 20), q))
        import zlib
        self.assertEqual(zlib.decompress(blob, -15), q.tobytes())
        self.assertEqual(S.encode(q), blob)  # deterministic

    def test_header_deterministic(self):
        blob = S.encode(np.zeros((2, 3), np.uint8))
        src = {"id": "x", "title": "t"}
        h1 = S.dumps(S.header(41.9, -87.6, 3, 2, 3, 2, blob, src, 12.345, 0.123456, {"how": "h"}))
        h2 = S.dumps(S.header(41.9, -87.6, 3, 2, 3, 2, blob, src, 12.345, 0.123456, {"how": "h"}))
        self.assertEqual(h1, h2)
        self.assertTrue(h1.endswith("}\n"))
        d = json.loads(h1)
        self.assertEqual(d["minX"], -1.5)
        self.assertEqual(d["minY"], -1)
        self.assertEqual(d["format"], "worldengine-slope-grid-v1")
        self.assertEqual(list(d.keys()), sorted(d.keys()))
        self.assertEqual(d["binBytes"], len(blob))


class StatsTests(unittest.TestCase):
    def test_diff_stats(self):
        a = np.array([1.0, 2.0, 20.0, 30.0, np.nan])
        b = np.array([1.5, 5.0, 26.0, 31.0, 3.0])
        st = S.diff_stats(a, b, b, 15)
        self.assertEqual(st["slopeBelow15"]["cells"], 2)
        self.assertEqual(st["slopeBelow15"]["shareWithin2Pts"], 0.5)
        self.assertEqual(st["slope15AndAbove"]["shareWithin5Pts"], 0.5)

    def test_local_box_to_merc_contains_centre(self):
        x0, y0, x1, y1 = S.local_box_to_merc(41.9, -87.6, (-510, -510, 510, 510))
        cx, cy = S.rp.lonlat_to_merc(-87.6, 41.9)
        self.assertTrue(x0 < cx < x1 and y0 < cy < y1)
        k = 1 / math.cos(math.radians(41.9))
        self.assertAlmostEqual((x1 - x0) / k, 1020, delta=2)


if __name__ == "__main__":
    unittest.main()
