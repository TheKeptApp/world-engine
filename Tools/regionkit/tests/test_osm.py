import json
import os
import unittest

from regionkit import geo, osm

FIX = os.path.join(os.path.dirname(__file__), "fixtures", "multipolygon.json")


class Parsing(unittest.TestCase):
    def setUp(self):
        with open(FIX, "rb") as f:
            self.doc = osm.Doc.from_overpass(f.read())

    def test_elements_and_timestamp(self):
        self.assertEqual(self.doc.timestamp, "2026-01-01T00:00:00Z")
        self.assertEqual(len(self.doc.nodes), 13)
        self.assertEqual(len(self.doc.ways), 4)
        self.assertIn(200, self.doc.relations)
        self.assertIn(201, self.doc.excluded_relations)   # printed without members
        self.assertNotIn(201, self.doc.relations)

    def test_multipolygon_assembly(self):
        fr = geo.LocalFrame(0.00015, 0.00015)
        polys, err = osm.assemble(self.doc, 200, fr)
        self.assertIsNone(err)
        self.assertEqual(len(polys), 1)
        p = polys[0]
        self.assertEqual(len(p.holes), 1)
        self.assertEqual(len(p.outer), 4)
        side = 0.0003 * 111319.5  # ~33.4 m
        self.assertAlmostEqual(abs(geo.signed_area(p.outer)), side * side, delta=side * side * 0.01)
        self.assertAlmostEqual(p.area, side * side * (1 - 1 / 9), delta=side * side * 0.01)

    def test_join_rings_failure(self):
        self.assertIsNone(osm.join_rings([[1, 2, 3]]))
        rings = osm.join_rings([[1, 2], [3, 2], [3, 1]])
        self.assertEqual(len(rings), 1)
        self.assertEqual(rings[0][0], rings[0][-1])

    def test_missing_member(self):
        d = osm.Doc.from_overpass(json.dumps({"elements": [
            {"type": "relation", "id": 1, "members": [{"type": "way", "ref": 9, "role": "outer"}], "tags": {"type": "multipolygon", "building": "yes"}}]}))
        polys, err = osm.assemble(d, 1, geo.LocalFrame(0, 0))
        self.assertIn("missing", err)

    def test_tag_rules(self):
        self.assertEqual(osm.building_type({"building": "house"}), "house")
        self.assertIsNone(osm.building_type({"building": "no"}))
        self.assertEqual(osm.building_type({"building:part": "yes"}), "yes")
        self.assertEqual(osm.building_type({"building:part": "roof"}), "roof")
        self.assertTrue(osm.is_area_way([1, 2, 3, 1], {"building": "yes"}))
        self.assertFalse(osm.is_area_way([1, 2, 3, 1], {"highway": "pedestrian"}))
        self.assertTrue(osm.is_area_way([1, 2, 3, 1], {"highway": "pedestrian", "area": "yes"}))
        self.assertFalse(osm.is_area_way([1, 2, 3], {"building": "yes"}))

    def test_query_never_asks_for_meta(self):
        q = osm.cell_query([1, 2, 3, 4], [0, 1, 4, 5])
        self.assertNotIn("meta", q)
        self.assertIn("out body qt;", q)
        self.assertIn("count_members()<300", q)


if __name__ == "__main__":
    unittest.main()
