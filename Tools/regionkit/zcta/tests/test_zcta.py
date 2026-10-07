import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
try:
    import shapely  # noqa: F401
    HAVE = True
except ImportError:
    HAVE = False

import zcta

B = {"south": 0.0, "west": 0.0, "north": 1.0, "east": 1.0}


def feat(zid, rings):
    return {"properties": {"ZCTA5": zid}, "geometry": {"type": "Polygon", "coordinates": rings}}


class Basics(unittest.TestCase):
    def test_context_bounds(self):
        m = {"sources": [{"layers": ["all"], "bounds": 1}, {"layers": ["context"], "bounds": 2}]}
        self.assertEqual(zcta.context_bounds(m), 2)

    def test_query_url(self):
        u = zcta.query_url(B)
        self.assertIn("outFields=ZCTA5", u)
        self.assertNotIn("maxAllowableOffset", u)

    def test_orientation(self):
        cw = [[0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]
        self.assertGreater(zcta.signed_area(zcta.fmt_ring(cw, True)), 0)
        self.assertLess(zcta.signed_area(zcta.fmt_ring(cw, False)), 0)


@unittest.skipUnless(HAVE, "shapely not installed")
class Clip(unittest.TestCase):
    def test_clip_orient_sort_holes(self):
        outer = [[-1, -1], [2, -1], [2, 2], [-1, 2], [-1, -1]]
        hole = [[0.4, 0.4], [0.6, 0.4], [0.6, 0.6], [0.4, 0.6], [0.4, 0.4]]
        outside = [[5, 5], [6, 5], [6, 6], [5, 6], [5, 5]]
        small = [[0, 0], [0.5, 0], [0.5, 0.5], [0, 0.5], [0, 0]]
        doc = zcta.build([feat("2", [outer, hole]), feat("9", [outside]), feat("1", [small])], B)
        self.assertEqual([z["id"] for z in doc["zctas"]], ["1", "2"])
        poly = doc["zctas"][1]["polygons"][0]
        self.assertEqual(len(poly), 2)
        self.assertGreater(zcta.signed_area(poly[0]), 0)
        self.assertLess(zcta.signed_area(poly[1]), 0)
        xs = [p[0] for p in poly[0]]
        self.assertTrue(min(xs) >= 0 and max(xs) <= 1)
        self.assertEqual(poly[0][0], poly[0][-1])

    def test_deterministic(self):
        f = [feat("2", [[[-1, -1], [2, -1], [2, 2], [-1, 2], [-1, -1]]])]
        self.assertEqual(zcta.dump(zcta.build(f, B)), zcta.dump(zcta.build(f, B)))
        self.assertTrue(zcta.dump(zcta.build(f, B)).endswith("}\n"))


if __name__ == "__main__":
    unittest.main()
