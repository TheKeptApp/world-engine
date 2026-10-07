"""role()/situation()/eligibility/tag parsing parity with the Swift sources (cases read from the code
and ported from Tests/WorldMapTests and Tests/WorldGenTests)."""
import unittest

from regionkit import geo, rules

T = {"smallArea": 60, "largeArea": 220, "hugeArea": 350, "broadAspect": 1.7, "squareAspect": 1.5,
     "squareRectangularity": 0.78, "narrowAspect": 1.7}


class TagParsing(unittest.TestCase):
    def test_lengths(self):
        for raw, m in [("12", 12.0), ("12 m", 12.0), ("12.5m", 12.5), ("12,5", 12.5), ("7 metres", 7.0),
                       ("40'", 12.192), ("40'6\"", 12.3444), ("40 ft", 12.192), ("9;12", 9.0)]:
            self.assertAlmostEqual(rules.parse_length(raw), m, places=4, msg=raw)

    def test_bad_lengths(self):
        for raw in ["tall", "", "-5", "0", "12 km", "5000"]:
            self.assertIsNone(rules.parse_length(raw), raw)

    def test_numbers(self):
        self.assertEqual(rules.parse_number("3"), 3)
        self.assertEqual(rules.parse_number("2.5"), 2.5)
        self.assertEqual(rules.parse_number("2;3"), 2)
        self.assertIsNone(rules.parse_number("lots"))
        self.assertIsNone(rules.parse_number("1_0"))
        self.assertIsNone(rules.parse_number("nan"))
        self.assertIsNone(rules.parse_number("600"))

    def test_swift_rounding(self):
        self.assertEqual(rules.swift_round(2.5), 3)   # Python round() would give 2
        self.assertEqual(rules.swift_round(1.5), 2)
        self.assertEqual(rules.swift_round(0.4), 0)


class Roles(unittest.TestCase):
    def test_role_order(self):
        self.assertEqual(rules.role("garage", 5), "garage")         # garage beats tiny
        self.assertEqual(rules.role("carport", 300), "garage")
        self.assertEqual(rules.role("house", 11.9), "shed")         # tiny beats house
        self.assertEqual(rules.role("house", 12.0), "house")
        self.assertEqual(rules.role("hut", 80), "shed")
        self.assertEqual(rules.role("yes", 249.9), "house")
        self.assertEqual(rules.role("yes", 250), "block")
        self.assertEqual(rules.role("apartments", 120), "block")
        self.assertEqual(rules.role("terrace", 900), "house")
        self.assertEqual(rules.role("semidetached_house", 100), "house")


class Situations(unittest.TestCase):
    def test_semidetached_first(self):
        self.assertEqual(rules.situation("semidetached_house", 2, 100, 1.2, 0.9, False, T), "semidetached")

    def test_levels(self):
        self.assertEqual(rules.situation("house", 1, 100, 1.8, 0.9, True, T), "oneFloorBroad")
        self.assertEqual(rules.situation("house", 1, 100, 1.8, 0.9, False, T), "oneFloor")
        self.assertEqual(rules.situation("house", 1, 100, 1.6, 0.9, True, T), "oneFloor")
        self.assertEqual(rules.situation("house", 2, 100, 1.4, 0.8, False, T), "twoFloorSquare")
        self.assertEqual(rules.situation("house", 2, 100, 1.4, 0.7, False, T), "twoFloor")
        self.assertEqual(rules.situation("house", 2, 100, 1.7, 0.9, False, T), "twoFloorNarrow")
        self.assertEqual(rules.situation("house", 2.5, 100, 1.2, 0.9, False, T), "threeFloor")   # rounds to 3
        self.assertEqual(rules.situation("house", 7, 100, 1.2, 0.9, False, T), "threeFloor")

    def test_area_keys(self):
        self.assertEqual(rules.situation("house", None, 59, 1.2, 0.9, False, T), "small")
        self.assertEqual(rules.situation("house", None, 221, 1.2, 0.9, False, T), "large")
        self.assertEqual(rules.situation("house", None, 220, 1.2, 0.9, False, T), "unknown")
        self.assertEqual(rules.situation("house", 0.4, 100, 1.2, 0.9, False, T), "unknown")   # 0 levels = untagged


class Eligibility(unittest.TestCase):
    profile = {
        "houseTypes": [
            {"id": "ranch", "floors": [1], "minAspect": 1.6, "broadFrontage": True},
            {"id": "square", "floors": [2], "maxAspect": 1.4, "minRectangularity": 0.78},
            {"id": "any", "floors": [1, 2]},
        ],
        "typeRules": {"unknown": {"ranch": 50, "square": 30, "any": 20}, "large": {"ranch": 1}},
    }

    def test_filtering_and_fallback(self):
        p = rules.type_probabilities(self.profile, "unknown", None, 2.0, 0.9, True)
        self.assertAlmostEqual(p["ranch"], 50 / 70)
        self.assertNotIn("square", p)
        p = rules.type_probabilities(self.profile, "unknown", 2, 1.2, 0.9, False)
        self.assertEqual(set(p), {"square", "any"})
        # nothing eligible -> unfiltered weights (BuildingGenerator falls back to `all`)
        p = rules.type_probabilities(self.profile, "large", None, 1.0, 0.5, False)
        self.assertEqual(p, {"ranch": 1.0})
        # missing key -> `unknown`
        p = rules.type_probabilities(self.profile, "threeFloor", 3, 1.0, 0.9, False)
        self.assertEqual(p, {"ranch": 50 / 100, "square": 30 / 100, "any": 20 / 100})


class RoofsColoursRoads(unittest.TestCase):
    def test_roof_mapping(self):
        self.assertEqual(rules.map_roof("gambrel"), "gabled")
        self.assertEqual(rules.map_roof("half-hipped"), "hipped")
        self.assertEqual(rules.map_roof("skillion"), "slab")
        self.assertIsNone(rules.map_roof("dome"))
        self.assertIsNone(rules.map_roof(None))

    def test_engine_colours(self):
        self.assertEqual(rules.engine_hex(" Grey "), "#9A9A97")
        self.assertEqual(rules.engine_hex("#a0b1c2"), "#a0b1c2")
        self.assertIsNone(rules.engine_hex("dark grey"))

    def test_road_width(self):
        # RoadRules (main 4b979d4): parked cars on both sides unless tagged otherwise.
        self.assertEqual(rules.road_width("residential", {}), (8.0, "default"))
        self.assertAlmostEqual(rules.road_width("residential", {"lanes": "1"})[0], 4.5 + 2 * 2.3)
        self.assertAlmostEqual(rules.road_width("residential", {"parking:right": "no"})[0], 8 - 2.3)
        self.assertEqual(rules.road_width("residential", {"parking:both": "no"}), (4.5, "default"))
        self.assertEqual(rules.parking_sides({"parking:lane:both": "separate"}), 0)
        self.assertEqual(rules.road_width("primary", {"lanes": "4"}), (4 * 3.3, "lanes"))
        self.assertEqual(rules.road_width("residential", {"width": "9 m", "lanes": "2"}), (9.0, "width"))
        self.assertEqual(rules.highway_kind("primary_link"), "primary")

    def test_front_edge_faces_named_street_not_alley(self):
        """Mirrors BuildingGenerationTests.frontDoorFacesTheNamedStreetNotTheAlley."""
        streets = geo.SegmentIndex([[(-100, -10), (100, -10)]])
        ring = [(-5, 0), (5, 0), (5, 12), (-5, 12)]  # CCW
        e = rules.best_edge(ring, streets, 60)
        self.assertEqual(e, 0)  # the south edge (0,0)->(5,0)
        obb = geo.minimum_area_rect(ring)
        self.assertFalse(rules.broad_front(ring, e, obb))  # short side faces the street
        wide = [(-8, 0), (8, 0), (8, 6), (-8, 6)]
        self.assertTrue(rules.broad_front(wide, rules.best_edge(wide, streets, 60), geo.minimum_area_rect(wide)))


if __name__ == "__main__":
    unittest.main()
