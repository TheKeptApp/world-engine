import math
import unittest

from regionkit import geo


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


class PolygonArea(unittest.TestCase):
    def test_shoelace_square_and_orientation(self):
        sq = rect(0, 0, 10, 10)
        self.assertAlmostEqual(geo.signed_area(sq), 100.0)
        self.assertAlmostEqual(geo.signed_area(sq[::-1]), -100.0)

    def test_holes_subtract(self):
        p = geo.Polygon(rect(0, 0, 10, 10), [rect(2, 2, 4, 4)])
        self.assertAlmostEqual(p.area, 96.0)

    def test_centroid_of_l_shape(self):
        l = [(0, 0), (2, 0), (2, 1), (1, 1), (1, 2), (0, 2)]
        c = geo.centroid(l)
        self.assertAlmostEqual(c[0], 5 / 6)
        self.assertAlmostEqual(c[1], 5 / 6)

    def test_clean_removes_collinear_and_duplicates(self):
        ring = [(0, 0), (5, 0), (10, 0), (10, 10), (10, 10.001), (0, 10), (0, 0)]
        c = geo.clean_ring(ring)
        self.assertEqual(len(c), 4)
        poly = geo.Polygon(rect(0, 0, 10, 10)[::-1]).cleaned()
        self.assertGreater(geo.signed_area(poly.outer), 0)  # outer forced CCW

    def test_cleaned_drops_tiny(self):
        self.assertIsNone(geo.Polygon(rect(0, 0, 0.5, 0.5)).cleaned(min_area=1.0))


class Footprints(unittest.TestCase):
    """Ported from Tests/WorldGenTests/WorldGenTests.swift (Footprint analysis suite)."""

    def test_rectangle(self):
        a = geo.Footprint(geo.Polygon(rect(0, 0, 12, 8)))
        self.assertEqual(a.kind, "rectangle")
        self.assertAlmostEqual(a.obb.half_length, 6)
        self.assertAlmostEqual(a.obb.half_width, 4)
        self.assertAlmostEqual(abs(a.obb.u[0]), 1)
        self.assertAlmostEqual(a.aspect, 1.5)

    def test_rotated_rectangle_finds_its_axis(self):
        ang = 0.5
        u = (math.cos(ang), math.sin(ang))
        v = (-math.sin(ang), math.cos(ang))
        ring = [(0, 0), (u[0] * 14, u[1] * 14), (u[0] * 14 + v[0] * 9, u[1] * 14 + v[1] * 9), (v[0] * 9, v[1] * 9)]
        a = geo.Footprint(geo.Polygon(ring))
        self.assertEqual(a.kind, "rectangle")
        self.assertAlmostEqual(abs(geo.dot(a.obb.u, u)), 1, places=6)
        self.assertAlmostEqual(a.rectangularity, 1, places=6)
        self.assertAlmostEqual(a.aspect, 14 / 9, places=6)

    def test_l_shape_splits_into_two_roofs(self):
        l = geo.Polygon([(0, 0), (14, 0), (14, 6), (6, 6), (6, 12), (0, 12)])
        a = geo.Footprint(l)
        self.assertEqual(a.kind, "orthogonal")
        self.assertEqual(a.roof_rects, 2)
        self.assertAlmostEqual(a.rectangularity, l.area / (14 * 12))

    def test_notched_rectangles(self):
        small = geo.Polygon([(0, 0), (10, 0), (10, 1.5), (12, 1.5), (12, 9), (0, 9)])
        self.assertEqual(geo.Footprint(small).kind, "rectangle")
        deep = geo.Polygon([(0, 0), (8, 0), (8, 4), (12, 4), (12, 9), (0, 9)])
        a = geo.Footprint(deep)
        self.assertEqual(a.kind, "orthogonal")
        self.assertGreaterEqual(a.roof_rects, 2)

    def test_tiny_and_irregular(self):
        self.assertEqual(geo.Footprint(geo.Polygon(rect(0, 0, 3, 3))).kind, "tiny")
        blob = geo.Polygon([(math.cos(k / 7 * 2 * math.pi) * 9, math.sin(k / 7 * 2 * math.pi) * 6) for k in range(7)])
        self.assertEqual(geo.Footprint(blob).kind, "irregular")

    def test_degenerate_aspect_is_one(self):
        self.assertEqual(geo.OrientedRect((0, 0), (1, 0), 0, 0).aspect, 1.0)


class FrameAndClipping(unittest.TestCase):
    def test_local_frame_metres(self):
        fr = geo.LocalFrame(40.0, -105.0)
        x, y = fr.xy(40.0, -105.0)
        self.assertAlmostEqual(x, 0, places=6)
        s, w, n, e = geo.box_around(40.0, -105.0, 500)
        self.assertAlmostEqual(fr.xy(n, -105.0)[1], 500, delta=0.05)
        self.assertAlmostEqual(fr.xy(40.0, e)[0], 500, delta=0.05)

    def test_clip_polyline(self):
        pieces = geo.clip_polyline([(-10, 5), (20, 5)], (0, 0, 10, 10))
        self.assertEqual(len(pieces), 1)
        self.assertAlmostEqual(geo.polyline_length(pieces[0]), 10)
        out_in_out = geo.clip_polyline([(-5, 5), (5, 5), (5, 15), (5, 25), (5, 5)], (0, 0, 10, 10))
        self.assertEqual(len(out_in_out), 2)

    def test_clip_ring_area(self):
        r = geo.clip_ring(rect(-5, -5, 5, 5), (0, 0, 10, 10))
        self.assertAlmostEqual(abs(geo.signed_area(r)), 25)

    def test_raster_union_area(self):
        r = geo.Raster((0, 0, 100, 100), 1.0)
        r.fill_polygon(geo.Polygon(rect(10, 10, 60, 60)))
        r.fill_polygon(geo.Polygon(rect(40, 40, 90, 90)))  # overlap counted once
        self.assertAlmostEqual(r.area(), 2500 + 2500 - 400, delta=1)

    def test_segment_distance(self):
        self.assertAlmostEqual(geo.ring_line_distance(rect(0, 0, 10, 10), [(15, -5), (15, 15)]), 5)
        self.assertEqual(geo.ring_line_distance(rect(0, 0, 10, 10), [(5, -5), (5, 15)]), 0.0)

    def test_segment_index_nearest(self):
        idx = geo.SegmentIndex([[(-100, -10), (100, -10)], [(-100, 40), (100, 40)]])
        hit = idx.nearest((0, 0), 60)
        self.assertEqual(hit[2], 0)
        self.assertAlmostEqual(hit[1], 10)
        self.assertIsNone(idx.nearest((0, 0), 5))


if __name__ == "__main__":
    unittest.main()
