import json
import os
import tempfile
import unittest

from regionkit import areacheck, osmclip

BOX = (0.0, 0.0, 1.0, 1.0)   # S, W, N, E


def node(i, lat, lon, tags=None):
    d = {"type": "node", "id": i, "lat": lat, "lon": lon}
    if tags:
        d["tags"] = tags
    return d


def doc_text(elements):
    # Overpass-like pretty text with trailing-zero coordinates that a re-serialisation would change
    parts = [json.dumps(e, indent=2).replace('"lat": 0.5,', '"lat": 0.5000000,') for e in elements]
    return '{\n  "version": 0.6,\n  "elements": [\n\n' + ",\n".join(parts) + "\n\n  ]\n}\n"


def fixture():
    els = [
        node(1, 0.5, 0.5), node(2, 0.6, 0.6),                  # inside: way 10
        node(3, 5.0, 5.0), node(4, 5.1, 5.1),                  # far: way 11 (lake member, dropped)
        node(5, 5.2, 5.2), node(6, 5.3, 5.3),                  # far: way 12 (also in a small relation, kept)
        node(7, 0.9, 0.9), node(8, 5.0, 5.0 + 1e-9),           # node 8 is shared by far ways 11 and 13
        node(9, 7.0, 7.0, {"amenity": "bench"}),               # lone tagged node, never referenced
        node(20, 6.0, 6.0),                                    # far node used only by way 11? (see 11)
        {"type": "way", "id": 10, "nodes": [1, 2], "tags": {"highway": "residential"}},
        {"type": "way", "id": 11, "nodes": [3, 4, 20]},
        {"type": "way", "id": 12, "nodes": [5, 6]},
        {"type": "way", "id": 13, "nodes": [8, 7]},            # crosses into the box via node 7
    ]
    lake = {"type": "relation", "id": 100, "tags": {"type": "multipolygon", "natural": "water"},
            "members": [{"type": "way", "ref": w, "role": "outer"} for w in (10, 11, 12, 13)]}
    small = {"type": "relation", "id": 101, "tags": {"type": "multipolygon", "leisure": "park"},
             "members": [{"type": "way", "ref": 12, "role": "outer"}]}
    return els + [lake, small]


class Clip(unittest.TestCase):
    def test_clip_keeps_referenced_and_is_byte_stable(self):
        text = doc_text(fixture())
        new, rep = osmclip.clip_text(text, BOX, min_members=4)
        d = json.loads(new)
        ids = {(e["type"], e["id"]) for e in d["elements"]}
        self.assertNotIn(("way", 11), ids)                      # far lake member dropped
        self.assertIn(("way", 12), ids)                         # listed by a small relation
        self.assertIn(("way", 13), ids)                         # intersects the box
        self.assertIn(("way", 10), ids)
        self.assertIn(("relation", 100), ids)                   # relation itself kept, members untouched
        self.assertEqual(len([e for e in d["elements"] if e["id"] == 100][0]["members"]), 4)
        self.assertNotIn(("node", 3), ids)
        self.assertNotIn(("node", 4), ids)
        self.assertNotIn(("node", 20), ids)
        self.assertIn(("node", 8), ids)                         # shared with kept way 13
        self.assertIn(("node", 9), ids)                         # lone node kept
        self.assertIn("0.5000000", new)                         # kept elements are copied verbatim
        self.assertEqual((rep["ways_dropped"], rep["nodes_dropped"]), (1, 3))
        # every kept way's nodes are present
        nodes = {e["id"] for e in d["elements"] if e["type"] == "node"}
        for e in d["elements"]:
            if e["type"] == "way":
                self.assertTrue(set(e["nodes"]) <= nodes)

    def test_below_threshold_is_untouched(self):
        text = doc_text(fixture())
        new, rep = osmclip.clip_text(text, BOX, min_members=5)
        self.assertEqual(rep["ways_dropped"], 0)
        self.assertEqual(json.loads(new), json.loads(text))

    def test_idempotent(self):
        once, _ = osmclip.clip_text(doc_text(fixture()), BOX, min_members=4)
        twice, rep = osmclip.clip_text(once, BOX, min_members=4)
        self.assertEqual(once, twice)
        self.assertEqual(rep["ways_dropped"], 0)

    def test_manifest_update_keeps_other_sources(self):
        m = ('{\n  "sources" : [\n    {\n      "bytes" : 10,\n      "path" : "osm.json",\n'
             '      "sha256" : "aa"\n    },\n    {\n      "bytes" : 20,\n      "path" : "context.json",\n'
             '      "sha256" : "bb"\n    }\n  ]\n}')
        out = osmclip.update_manifest_text(m, "osm.json", 99, "cc")
        d = json.loads(out)
        self.assertEqual((d["sources"][0]["bytes"], d["sources"][0]["sha256"]), (99, "cc"))
        self.assertEqual((d["sources"][1]["bytes"], d["sources"][1]["sha256"]), (20, "bb"))


class AreaCheck(unittest.TestCase):
    def make(self, root, name, els, w=1000, h=1000):
        d = os.path.join(root, name)
        os.makedirs(d)
        with open(os.path.join(d, "osm.json"), "w") as f:
            f.write(doc_text(els))
        with open(os.path.join(d, "manifest.json"), "w") as f:
            json.dump({"widthMeters": w, "heightMeters": h, "sources": [
                {"format": "osm-overpass-json", "layers": ["all"], "bytes": 1, "path": "osm.json", "sha256": "00"},
                {"layers": ["context"], "path": "context.json",
                 "bounds": {"south": 0, "west": 0, "north": 1, "east": 1}}]}, f)

    def test_flags(self):
        with tempfile.TemporaryDirectory() as root:
            self.make(root, "ok", [node(1, 0, 0)])
            self.make(root, "huge", fixture())
            rows = {r["area"]: r for r in areacheck.area_rows(root, budget=0.001, min_members=4)}
            self.assertEqual(len(rows["huge"]["problems"]), 2)       # over budget + big relation
            rows = {r["area"]: r for r in areacheck.area_rows(root, budget=5.0, min_members=300)}
            self.assertEqual(rows["huge"]["problems"], [])
            self.assertEqual(rows["ok"]["problems"], [])

    def test_clipped_stub_passes(self):
        with tempfile.TemporaryDirectory() as root:
            self.make(root, "huge", fixture())
            d = os.path.join(root, "huge")
            osmclip.clip_area(d, min_members=4, log=lambda *_: None)
            rows = areacheck.area_rows(root, budget=5.0, min_members=4)
            self.assertEqual(rows[0]["problems"], [])


if __name__ == "__main__":
    unittest.main()
