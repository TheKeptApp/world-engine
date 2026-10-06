"""End-to-end measurement on a synthetic cell (generated here; not real map data)."""
import json
import unittest

from regionkit import geo, measure, osm, profiles

LAT0, LON0 = 40.0, -100.0
S, W, N, E = geo.box_around(LAT0, LON0, 1000.0)
DLAT, DLON = (N - S) / 2000.0, (E - W) / 2000.0   # degrees per metre at the centre


def build_doc():
    els, nid, wid = [], [1], [1000]

    def node(x, y, tags=None):
        nid[0] += 1
        e = {"type": "node", "id": nid[0], "lat": LAT0 + y * DLAT, "lon": LON0 + x * DLON}
        if tags:
            e["tags"] = tags
        els.append(e)
        return nid[0]

    def way(pts, tags, closed=False):
        ids = [node(x, y) for x, y in pts]
        if closed:
            ids.append(ids[0])
        wid[0] += 1
        els.append({"type": "way", "id": wid[0], "nodes": ids, "tags": tags})

    def rect(x0, y0, x1, y1, tags):
        way([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], tags, closed=True)

    way([(-200, -20), (200, -20)], {"highway": "residential", "name": "Test Street"})
    way([(-200, 40), (200, 40)], {"highway": "service", "service": "alley"})
    rect(-5, 0, 5, 12, {"building": "house", "building:levels": "1", "roof:shape": "hipped"})
    rect(20, 0, 36, 8, {"building": "house", "roof:shape": "gabled", "building:material": "brick"})
    rect(50, 0, 62, 14, {"building": "yes"})
    node(56, 7, {"shop": "bakery"})
    rect(-3, 30, 3, 36, {"building": "garage"})
    rect(70, 30, 72, 32, {"building": "shed"})
    rect(100, 0, 130, 20, {"building": "apartments", "building:levels": "4", "height": "14"})
    rect(300, 0, 310, 10, {"building": "house"})            # centroid outside the cell
    node(-30, 60, {"natural": "tree", "leaf_type": "broadleaved"})
    node(-40, 60, {"natural": "tree", "genus": "Pinus"})
    node(-50, 60, {"natural": "tree", "species": "Quercus virginiana", "height": "12"})
    way([(-50, 20), (50, 20)], {"barrier": "fence"})
    rect(-200, -10, 200, 200, {"landuse": "residential"})
    return {"osm3s": {"timestamp_osm_base": "2026-01-01T00:00:00Z"}, "elements": els}


class SyntheticCell(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmpl, _ = profiles.load("default")
        spec = {"id": "synthetic", "source": "test", "bbox": list(geo.box_around(LAT0, LON0, 200)), "center": [LAT0, LON0],
                "radiusMeters": 200}
        doc = osm.Doc.from_overpass(json.dumps(build_doc()))
        cls.cell = measure.Cell(spec, doc, cls.tmpl, {"timestamp_osm_base": doc.timestamp})
        cls.s = measure.summarize([cls.cell], cls.tmpl)

    def test_counts_and_roles(self):
        b = self.s["buildings"]
        self.assertEqual(b["outlines"], 6)
        self.assertEqual(b["byRole"]["house"]["n"], 3)
        self.assertEqual(b["byRole"]["garage"]["n"], 1)
        self.assertEqual(b["byRole"]["shed"]["n"], 1)
        self.assertEqual(b["byRole"]["block"]["n"], 1)
        self.assertAlmostEqual(self.s["areaKm2"], 0.16, places=3)

    def test_setback_and_frontage(self):
        sb = self.s["setback"]
        self.assertEqual(sb["housesMeasured"], 3)
        self.assertAlmostEqual(sb["facadeToCurbM"]["p50"], 17.0, delta=0.1)   # 20 m to the centreline - 6 m / 2
        fr = self.s["frontage"]
        self.assertEqual(fr["housesWithFrontEdge"], 3)
        self.assertEqual(fr["longSideFacesStreet"], 1)   # only the 16 x 8 house; 10 x 12 and 12 x 14 show their short side

    def test_alleys(self):
        al = self.s["alleys"]
        self.assertEqual(al["housesWithin30mOfAlley"]["n"], 2)
        self.assertEqual(al["garagesAdjacentToAlley"]["n"], 1)
        self.assertAlmostEqual(al["alleyKm"], 0.4, places=2)

    def test_barriers_trees_landuse(self):
        self.assertAlmostEqual(self.s["barriers"]["fence"]["km"], 0.1, places=3)
        t = self.s["trees"]
        self.assertEqual(t["count"], 3)
        self.assertEqual(t["leafTypeTagOrGenus"]["broadleaved"]["n"], 2)
        self.assertEqual(t["leafTypeTagOrGenus"]["needleleaved"]["n"], 1)
        self.assertEqual(t["leafCycleTagOrGenus"]["evergreen"]["n"], 2)
        self.assertGreater(self.s["coverage"]["residentialLanduseShare"], 0.5)

    def test_use_mix_and_levels(self):
        u = self.s["useMix"]["byCount"]
        self.assertEqual(u["residential"]["n"], 3)          # 2 houses + apartments
        self.assertEqual(u["commercial (tags/POI)"]["n"], 1)
        self.assertEqual(self.s["levels"]["all"]["withLevels"], 2)
        self.assertEqual(self.s["roofShape"]["houses"]["mapped"]["hipped"]["n"], 1)
        self.assertEqual(self.s["materialsAndColours"]["buildingMaterial"]["all"]["brick"]["n"], 1)


if __name__ == "__main__":
    unittest.main()
