"""Offline tests of the roof-hints pure functions (mansard rule, pitch class, block assignment and ids, roof mix).

numpy and shapely only; no network and no lidar data. Plane dicts are built by hand in the footprint's metre frame.
"""
import json
import math
import os
import sys
import unittest

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import roofhints as rh  # noqa: E402

CFG = rh.load_cfg()
CLS = json.load(open(os.path.join(os.path.dirname(HERE), "data", "params.json")))["classify"]
MP = CFG["mansard"]
RECT = (0.0, 0.0, 1.0, 0.0, 6.0, 4.0)  # centre, long axis = east, half-length 6, half-width 4


def plane(pid, area, pitch, aspect, cx, cy):
    return {"id": pid, "area": area, "pitch": pitch, "aspect": aspect, "cx": cx, "cy": cy}


def mansard_planes(steep=65.0, top_pitch=2.0):
    """Four steep lower planes (one per side, falling outward) round a flat top."""
    return [plane(0, 90, top_pitch, 0, 0, 0),
            plane(1, 25, steep, 90, 5.0, 0),    # east side, falls east
            plane(2, 25, steep, 270, -5.0, 0),  # west
            plane(3, 18, steep, 0, 0, 3.2),     # north
            plane(4, 18, steep, 180, 0, -3.2)]  # south


class OvertureFootprints(unittest.TestCase):
    """The engine's ref for an Overture record and the footprint merge (Sources/WorldMap/OvertureSource.swift)."""

    def test_ref_is_signed_int64_of_first_16_hex(self):
        self.assertEqual(rh.overture_ref("000d07de-8477-475b-b2e4-c0adfe78ae8e"), "overture/000d07de8477475bb2e4c0adfe78ae8e")
        self.assertEqual(rh.overture_ref("FFFFFFFF-FFFF-FFFF-0000-000000000000"), "overture/ffffffffffffffff0000000000000000")
        self.assertIsNone(rh.overture_ref("000d07de8477475b"))  # a 16-digit prefix is not a GERS id

    def test_ref_needs_16_hex_digits(self):
        self.assertIsNone(rh.overture_ref("1234"))
        self.assertIsNone(rh.overture_ref("zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"))

    def make_area(self, tmp):
        """A tiny area: centre (42.0, -87.7), 200 m box; one OSM house; four Overture records."""
        import json as js
        man = {"center": {"latitude": 42.0, "longitude": -87.7}, "widthMeters": 200, "heightMeters": 200}
        dlat, dlon = 1 / 111320.0, 1 / (111320.0 * math.cos(math.radians(42.0)))

        def sq(e, n, w=8.0):  # closed [lon, lat] ring, e/n metres from the centre
            pts = [(e, n), (e + w, n), (e + w, n + w), (e, n + w), (e, n)]
            return [[-87.7 + x * dlon, 42.0 + y * dlat] for x, y in pts]
        os.makedirs(os.path.join(tmp, "area"))
        nodes = [{"type": "node", "id": 1 + i, "lat": 42.0 + y * dlat, "lon": -87.7 + x * dlon}
                 for i, (x, y) in enumerate([(0, 0), (10, 0), (10, 10), (0, 10)])]
        way = {"type": "way", "id": 100, "nodes": [1, 2, 3, 4, 1], "tags": {"building": "house"}}
        with open(os.path.join(tmp, "area", "osm.json"), "w") as f:
            js.dump({"elements": nodes + [way]}, f)
        recs = [
            {"id": "00000000-0000-0001-0000-000000000001", "sources": [{"dataset": "Microsoft ML Buildings"}], "polygons": [[sq(40, 40)]]},   # kept
            {"id": "00000000-0000-0002-0000-000000000002", "sources": [{"dataset": "OpenStreetMap"}], "polygons": [[sq(60, 60)]]},            # OSM source: dropped
            {"id": "00000000-0000-0003-0000-000000000003", "sources": [{"dataset": "Microsoft ML Buildings"}], "polygons": [[sq(1, 1, 6)]]},  # centroid inside the OSM house: dropped
            {"id": "00000000-0000-0004-0000-000000000004", "sources": [{"dataset": "Microsoft ML Buildings"}], "polygons": [[sq(300, 0)]]},   # outside the box: dropped
            {"id": "00000000-0000-0005-0000-000000000005", "sources": [{"dataset": "Microsoft ML Buildings"}], "polygons": [[sq(-50, -50, 4)], [sq(-30, -30, 8)]]},  # multi: largest kept
            {"id": "00000000-0000-0006-0000-000000000006", "sources": [{"dataset": "Microsoft ML Buildings"}], "polygons": [[sq(-70, 40, 0.5)]]},  # under 1 m2: skipped
        ]
        with open(os.path.join(tmp, "area", "overture-buildings.json"), "w") as f:
            js.dump({"format": "overture-buildings-v1", "buildings": recs}, f)
        return man, {"area": "area"}

    def test_merge_rules(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            man, pilot = self.make_area(tmp)
            out, rep = rh.overture_footprints(pilot, man, root=tmp)
        self.assertEqual(sorted(out), ["overture/00000000000000010000000000000001", "overture/00000000000000050000000000000005"])
        self.assertEqual(rep["records"], 6)
        self.assertEqual(rep["droppedOsmSource"], 1)
        self.assertEqual(rep["droppedInsideOsm"], 1)
        self.assertEqual(rep["droppedOutsideBounds"], 1)
        self.assertEqual(rep["added"], 2)
        self.assertEqual(rep["multiPolygonRecords"], 1)
        self.assertAlmostEqual(out["overture/00000000000000050000000000000005"]["poly"].area, 64.0, delta=1.0)  # the 8 m square, not the 4 m one


class PitchClass(unittest.TestCase):
    pc = CFG["pitchClasses"]

    def test_boundaries(self):
        f = lambda d: rh.pitch_class(d, self.pc)  # noqa: E731
        self.assertEqual(f(0.0), "flat")
        self.assertEqual(f(9.99), "flat")
        self.assertEqual(f(10.0), "low")
        self.assertEqual(f(24.99), "low")
        self.assertEqual(f(25.0), "medium")
        self.assertEqual(f(40.0), "medium")
        self.assertEqual(f(40.01), "steep")
        self.assertEqual(f(70.0), "steep")
        self.assertIsNone(f(None))

    def test_dominant_pitch(self):
        planes = [plane(0, 40, 30.0, 0, 0, 2), plane(1, 38, 31.0, 180, 0, -2), plane(2, 9, 3.0, 90, 5, 0)]
        self.assertEqual(rh.dominant_pitch(planes, CLS, "gable", {}), 30.0)  # largest sloped plane
        self.assertEqual(rh.dominant_pitch([plane(0, 50, 2.5, 0, 0, 0)], CLS, "flat", {}), 2.5)
        self.assertEqual(rh.dominant_pitch(planes, CLS, "mansard", {"steepPitch": 66.2}), 66.2)
        self.assertIsNone(rh.dominant_pitch([], CLS, "flat", {}))


class MansardRule(unittest.TestCase):
    def test_ring_of_steep_planes_round_flat_top(self):
        r = rh.mansard_rule(mansard_planes(), RECT, CLS, MP)
        self.assertTrue(r["mansard"])
        self.assertEqual(r["sides"], 4)
        self.assertAlmostEqual(r["steepPitch"], 65.0)

    def test_low_top_counts(self):
        self.assertTrue(rh.mansard_rule(mansard_planes(top_pitch=20.0), RECT, CLS, MP)["mansard"])

    def test_three_sides_is_enough_two_is_not(self):
        three = [p for p in mansard_planes() if p["id"] != 4]
        self.assertTrue(rh.mansard_rule(three, RECT, CLS, MP)["mansard"])
        two = [p for p in mansard_planes() if p["id"] in (0, 1, 2)]
        r = rh.mansard_rule(two, RECT, CLS, MP)
        self.assertFalse(r["mansard"])
        self.assertEqual(r["sides"], 2)

    def test_hip_roof_is_not_mansard(self):
        # four 33 deg planes, no top: steep threshold not reached
        hip = [plane(i, 25, 33.0, az, x, y) for i, (az, x, y) in enumerate([(90, 4, 0), (270, -4, 0), (0, 0, 2.5), (180, 0, -2.5)])]
        self.assertFalse(rh.mansard_rule(hip, RECT, CLS, MP)["mansard"])

    def test_steep_hip_without_top_is_not_mansard(self):
        steep_hip = [plane(i, 25, 52.0, az, x, y) for i, (az, x, y) in enumerate([(90, 4, 0), (270, -4, 0), (0, 0, 2.5), (180, 0, -2.5)])]
        self.assertFalse(rh.mansard_rule(steep_hip, RECT, CLS, MP)["mansard"])

    def test_flat_roof_with_steep_strip_is_not_mansard(self):
        # flat roof (two flat planes) with a 50 deg strip down the middle: steep on two sides only
        planes = [plane(0, 40, 1.0, 0, -3.5, 0), plane(1, 40, 1.0, 0, 3.5, 0),
                  plane(2, 12, 50.0, 0, 0, 2.5), plane(3, 12, 50.0, 180, 0, -2.5)]
        self.assertFalse(rh.mansard_rule(planes, RECT, CLS, MP)["mansard"])

    def test_top_must_be_central(self):
        planes = mansard_planes()
        planes[0] = plane(0, 90, 2.0, 0, 5.0, 3.0)  # the flat part sits in a corner (an addition)
        self.assertFalse(rh.mansard_rule(planes, RECT, CLS, MP)["mansard"])

    def test_extra_slopes_break_the_ring(self):
        planes = mansard_planes() + [plane(9, 60, 30.0, 45, 2, 2)]  # a 30 deg wing holding a large share
        self.assertFalse(rh.mansard_rule(planes, RECT, CLS, MP)["mansard"])

    def test_steep_planes_must_face_outwards(self):
        planes = mansard_planes()
        for p in planes[1:]:
            p["aspect"] = (p["aspect"] + 180) % 360  # facing inwards (a valley, not a roof edge)
        self.assertFalse(rh.mansard_rule(planes, RECT, CLS, MP)["mansard"])

    def test_rotated_rectangle(self):
        a = math.radians(30)
        ux, uy = math.cos(a), math.sin(a)
        # rotate plane centroids and aspects with the rectangle (aspect = clockwise azimuth from north)
        planes = []
        for p in mansard_planes():
            x = p["cx"] * ux - p["cy"] * uy
            y = p["cx"] * uy + p["cy"] * ux
            planes.append(dict(p, cx=x, cy=y, aspect=(p["aspect"] - 30) % 360))
        self.assertTrue(rh.mansard_rule(planes, (0.0, 0.0, ux, uy, 6.0, 4.0), CLS, MP)["mansard"])

    def test_make_record_labels_mansard_and_skips_unknown(self):
        res = {"form": "complex", "coverage": 0.95}
        hts = {"top": 11.04, "eave": 7.26}
        extras = {"points": 400, "cover": 0.98, "density": 4.0}
        rec = rh.make_record(res, mansard_planes(), RECT, hts, extras, CFG, CLS)
        self.assertEqual(rec["form"], "mansard")
        self.assertEqual(rec["pitchClass"], "steep")
        self.assertEqual((rec["topM"], rec["eaveM"]), (11.0, 7.3))
        self.assertLessEqual(rec["confidence"], 0.8)  # mansard form factor
        self.assertIsNone(rh.make_record({"form": "unknown"}, [], RECT, hts, extras, CFG, CLS))


class Blocks(unittest.TestCase):
    def squares(self):
        from shapely.geometry import box
        return [box(0, 0, 10, 10), box(10, 0, 20, 10), box(0, 10, 20, 12)]

    def test_assign_to_faces(self):
        xy = np.array([[5, 5], [15, 5], [3, 11], [50, 50]])
        self.assertEqual(list(rh.assign_to_faces(self.squares(), xy)), [0, 1, 2, -1])

    def test_boundary_point_goes_to_smallest_face(self):
        # (5, 10) lies on the edge shared by face 0 (area 100) and face 2 (area 40): the smaller wins
        self.assertEqual(list(rh.assign_to_faces(self.squares(), np.array([[5.0, 10.0]]))), [2])

    def test_assign_empty(self):
        self.assertEqual(len(rh.assign_to_faces(self.squares(), np.zeros((0, 2)))), 0)

    def test_block_id_is_order_independent_and_stable(self):
        a = rh.block_id([30, 5, 17])
        self.assertEqual(a, rh.block_id([17, 30, 5]))
        self.assertTrue(a.startswith("blk-") and len(a) == 12)
        self.assertNotEqual(a, rh.block_id([30, 5, 18]))
        self.assertEqual(rh.block_id([1, 2]), "blk-" + __import__("hashlib").sha1(b"1,2").hexdigest()[:8])

    def test_bounding_ways_and_faces(self):
        from shapely.geometry import LineString
        streets = [(11, LineString([(-5, 0), (25, 0)])), (12, LineString([(-5, 20)] + [(25, 20)])),
                   (13, LineString([(0, -5), (0, 25)])), (14, LineString([(20, -5), (20, 25)])),
                   (15, LineString([(10, 8), (10, 12)]))]  # a short inner stub, not on the boundary of face 0
        faces = rh.block_faces(streets[:4], (-5, -5, 25, 25), 50)
        inner = [f for f in faces if abs(f["poly"].area - 400) < 1][0]
        self.assertFalse(inner["clipped"])
        self.assertEqual(sorted(rh.bounding_ways(inner["poly"], streets[:4], CFG["blocks"])), [11, 12, 13, 14])
        self.assertEqual(sorted(rh.bounding_ways(inner["poly"], streets, CFG["blocks"])), [11, 12, 13, 14])
        self.assertTrue(any(f["clipped"] for f in faces))  # the faces outside the street ring touch the area edge


class RoofMix(unittest.TestCase):
    pc = CFG["pitchClasses"]

    def recs(self, forms, pitch=30.0):
        return [{"form": f, "pitchDeg": pitch + i, "pitchClass": rh.pitch_class(pitch + i, self.pc)} for i, f in enumerate(forms)]

    def test_privacy_floor(self):
        out = rh.mix_of(self.recs(["flat", "gable", "hip", "hip"]), 5, self.pc)
        self.assertTrue(out["suppressed"])
        self.assertEqual(out["nClassified"], 4)
        self.assertIsNone(out["shares"])
        self.assertIsNone(out["medianPitchDeg"])

    def test_shares_at_floor(self):
        out = rh.mix_of(self.recs(["flat", "gable", "gable", "hip", "complex"], pitch=8.0), 5, self.pc)
        self.assertFalse(out["suppressed"])
        self.assertEqual(out["shares"], {"flat": 0.2, "hip": 0.2, "gable": 0.4, "mansard": 0.0, "complex": 0.2})
        self.assertAlmostEqual(sum(out["shares"].values()), 1.0)
        self.assertEqual(out["medianPitchDeg"], 10.0)
        self.assertAlmostEqual(sum(out["pitchClassShares"].values()), 1.0, places=2)


if __name__ == "__main__":
    unittest.main()
