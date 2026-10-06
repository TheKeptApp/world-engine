import copy
import unittest

from regionkit import draft, profiles, stats, validate


def house(area=120, aspect=1.3, rect=0.9, levels=None, roof=None, height=None, roof_height=None, angle=None,
          colour=None, material=None, roof_colour=None, roof_material=None, broad=False, btype="house", role="house"):
    return {"role": role, "type": btype, "area": area, "aspect": aspect, "rect": rect, "broad_front": broad,
            "levels_raw": levels, "levels_int": None if levels is None else int(levels + 0.5),
            "roof_shape": roof, "height": height, "roof_height": roof_height, "roof_angle": angle,
            "building_colour": colour, "building_material": material, "roof_colour": roof_colour, "roof_material": roof_material}


class FakeCell:
    def __init__(self, buildings, trees=(), center=(42.0, -88.0)):
        self.buildings = list(buildings)
        self.trees = list(trees)
        self.spec = {"center": list(center)}


class Shrinkage(unittest.TestCase):
    def test_formula(self):
        self.assertAlmostEqual(stats.shrink(1.0, 0.0, 30, 30), 0.5)
        self.assertAlmostEqual(stats.shrink(0.2, 0.8, 90, 30), (90 * 0.2 + 30 * 0.8) / 120)
        self.assertEqual(stats.shrink(None, 0.7, 10, 30), 0.7)
        self.assertEqual(stats.shrink(0.1, 0.7, 0, 30), 0.7)

    def test_percentile_type7(self):
        self.assertAlmostEqual(stats.percentile([1, 2, 3, 4], 0.5), 2.5)
        self.assertAlmostEqual(stats.percentile([10, 20, 30], 0.25), 15)
        self.assertEqual(stats.ecdf([1, 2, 3, 4], 2), 0.5)


class IPF(unittest.TestCase):
    def test_matches_feasible_target_and_keeps_zeros(self):
        rows = {"a": {"gabled": 1, "hipped": 0, "flat": 0}, "b": {"gabled": 0.5, "hipped": 0.5, "flat": 0},
                "c": {"gabled": 0, "hipped": 0, "flat": 1}}
        w = {"a": 50, "b": 30, "c": 20}
        target = {"gabled": 0.55, "hipped": 0.25, "flat": 0.20}   # reachable: hipped only via b (max 0.30)
        new, achieved, resid, feasible = draft.ipf_roofs(rows, w, target)
        self.assertTrue(feasible)
        self.assertLess(resid, 1e-6)
        self.assertEqual(new["a"]["hipped"], 0)       # hipped-free family stays hipped-free
        self.assertEqual(new["c"]["gabled"], 0)
        for f in new:
            self.assertAlmostEqual(sum(new[f].values()), 1)

    def test_partially_unreachable_target_leaves_residual(self):
        rows = {"a": {"gabled": 1, "hipped": 0, "flat": 0}, "b": {"gabled": 0.5, "hipped": 0.5, "flat": 0},
                "c": {"gabled": 0, "hipped": 0, "flat": 1}}
        new, achieved, resid, feasible = draft.ipf_roofs(rows, {"a": 50, "b": 30, "c": 20}, {"gabled": 0.45, "hipped": 0.35, "flat": 0.20})
        self.assertAlmostEqual(achieved["hipped"], 0.30, places=3)   # capped by the only family with hips
        self.assertAlmostEqual(resid, 0.05, places=3)

    def test_infeasible_target_reported(self):
        rows = {"a": {"gabled": 1, "hipped": 0, "flat": 0}, "b": {"gabled": 0, "hipped": 1, "flat": 0}}
        new, achieved, resid, feasible = draft.ipf_roofs(rows, {"a": 1, "b": 1}, {"gabled": 0.4, "hipped": 0.4, "flat": 0.2})
        self.assertFalse(feasible)
        self.assertAlmostEqual(achieved["flat"], 0)


class MakeDraft(unittest.TestCase):
    def setUp(self):
        self.tmpl, _ = profiles.load("default")

    def test_template_kept_without_data(self):
        cell = FakeCell([house() for _ in range(10)])
        p, prov = draft.make_draft("z", "Zone", "r", [cell], self.tmpl, "default", [100.0] * 50, None)
        self.assertTrue(validate.validate(p).ok)
        self.assertEqual(prov.items["houseTypes[].roof"]["status"], "template")
        self.assertEqual(p["houseTypes"], self.tmpl["houseTypes"])

    def test_roof_and_levels_calibration(self):
        hs = [house(roof="hipped", levels=1, area=150) for _ in range(60)] + [house(roof="gabled", levels=2, area=150) for _ in range(20)]
        hs += [house(area=150) for _ in range(100)]
        cell = FakeCell(hs, trees=[{"leaf_type": "needleleaved", "height": None}] * 40)
        p, prov = draft.make_draft("z", "Zone", "r", [cell], self.tmpl, "default", [float(a) for a in range(50, 400)], None)
        self.assertTrue(validate.validate(p).ok, validate.validate(p).errors)
        self.assertEqual(prov.items["houseTypes[].roof"]["status"], "calibrated")
        e = draft.expected_roof_mix(hs, p)
        e0 = draft.expected_roof_mix(hs, self.tmpl)
        self.assertGreater(e["hipped"], e0["hipped"])          # moved toward the measured hipped majority
        # compactGabled is gabled-only in the template and must stay so
        cg = next(h for h in p["houseTypes"] if h["id"] == "compactGabled")
        self.assertEqual(cg["roof"]["hipped"], 0)
        self.assertEqual(prov.items["typeRules.unknown/small/large"]["status"], "calibrated")
        self.assertLess(p["trees"]["deciduousShare"], self.tmpl["trees"]["deciduousShare"])  # 40 conifers pull it down
        self.assertAlmostEqual(p["trees"]["deciduousShare"], round(stats.shrink(0.0, 0.8, 40, 30), 3))

    def test_percentile_thresholds_written_with_absolute_fallback(self):
        tmpl = copy.deepcopy(self.tmpl)
        for k in draft.DEFAULT_AREA_PERCENTILES:
            tmpl["typeThresholds"].pop(k, None)
        hs = [house(area=float(a)) for a in range(80, 200)]          # 120 houses -> transfer applies
        p, prov = draft.make_draft("z", "Zone", "r", [FakeCell(hs)], tmpl, "default", [float(a) for a in range(50, 400)], None)
        th = p["typeThresholds"]
        self.assertEqual({k: th[k] for k in draft.DEFAULT_AREA_PERCENTILES}, draft.DEFAULT_AREA_PERCENTILES)
        self.assertEqual(draft.DEFAULT_AREA_PERCENTILES,
                         {"smallAreaPercentile": 0.02, "largeAreaPercentile": 0.865, "hugeAreaPercentile": 0.99})
        self.assertEqual(prov.items["typeThresholds.small/large/hugeAreaPercentile"]["status"], "default")
        # the absolute values are still the percentile transfer (fallback), not the template's
        self.assertEqual(prov.items["typeThresholds.smallArea/largeArea/hugeArea"]["status"], "calibrated")
        self.assertNotEqual(th["largeArea"], tmpl["typeThresholds"]["largeArea"])
        self.assertTrue(validate.validate(p).ok, validate.validate(p).errors)

    def test_template_percentiles_kept_and_absolutes_kept_without_data(self):
        tmpl = copy.deepcopy(self.tmpl)
        tmpl["typeThresholds"].update(smallAreaPercentile=0.05, largeAreaPercentile=0.8, hugeAreaPercentile=0.95)
        p, prov = draft.make_draft("z", "Zone", "r", [FakeCell([house() for _ in range(10)])], tmpl, "default", [100.0] * 50, None)
        th = p["typeThresholds"]
        self.assertEqual((th["smallAreaPercentile"], th["largeAreaPercentile"], th["hugeAreaPercentile"]), (0.05, 0.8, 0.95))
        self.assertEqual(prov.items["typeThresholds.small/large/hugeAreaPercentile"]["status"], "template")
        for k in ("smallArea", "largeArea", "hugeArea"):                 # n < 30: template absolutes
            self.assertEqual(th[k], tmpl["typeThresholds"][k])

    def test_relative_thresholds_rule(self):
        th = dict(self.tmpl["typeThresholds"], smallAreaPercentile=0.1, largeAreaPercentile=0.9, hugeAreaPercentile=None)
        areas = [float(a) for a in range(100, 200)]                    # 100 houses
        out, used = draft.relative_thresholds(th, areas)
        self.assertAlmostEqual(out["smallArea"], stats.percentile(areas, 0.1))
        self.assertAlmostEqual(out["largeArea"], stats.percentile(areas, 0.9))
        self.assertEqual(out["hugeArea"], th["hugeArea"])               # no percentile -> absolute
        self.assertEqual(used, {"smallArea": "percentile", "largeArea": "percentile", "hugeArea": "absolute"})
        out, used = draft.relative_thresholds(th, areas[:29])          # < 30 houses -> absolute fallback
        self.assertEqual((out["smallArea"], out["largeArea"]), (th["smallArea"], th["largeArea"]))
        self.assertEqual(set(used.values()), {"absolute"})

    def test_floor_check_moves_toward_measured_floors(self):
        from regionkit import commands
        prof = copy.deepcopy(self.tmpl)        # unknown: compactGabled(1) 50, broadLow(1) 25, twoStoryHipped(2) 15, flatRoof(1) 10
        prof["typeThresholds"].update(smallAreaPercentile=0.02, largeAreaPercentile=0.865, hugeAreaPercentile=0.99)
        hs = [house(area=120 + i % 40, aspect=1.2, levels=2) for i in range(80)] + [house(area=120 + i % 40, aspect=1.2, levels=1) for i in range(20)]
        hs += [house(area=120 + i % 40, aspect=1.2) for i in range(100)]
        res = commands.floor_check([FakeCell(hs)], prof)
        self.assertEqual(res["housesWithLevels"], 100)
        self.assertEqual(res["thresholds"]["largeArea"]["from"], "percentile")
        self.assertAlmostEqual(res["truth"]["2"], 0.8, places=3)
        self.assertGreater(res["after"]["2"], res["before"]["2"])
        self.assertLess(res["tvdAfter"], res["tvdBefore"])
        self.assertEqual(prof["typeRules"]["unknown"], self.tmpl["typeRules"]["unknown"])   # input not modified
        self.assertEqual(set(res["typeRules"]["unknown"]), set(self.tmpl["typeRules"]["unknown"]))  # no family added

    def test_perfloor_clamped(self):
        hs = [house(levels=2, height=9.0, roof="flat", area=150) for _ in range(25)]  # 4.5 m per level -> clamp 3.8
        p, prov = draft.make_draft("z", "Zone", "r", [FakeCell(hs)], self.tmpl, "default", [100.0] * 40, None)
        self.assertEqual(prov.items["houseTypes[].perFloor"]["status"], "calibrated")
        for h in p["houseTypes"]:
            self.assertLessEqual(h["perFloor"][1], 3.8)

    def test_colour_shift_stays_in_band(self):
        hs = [house(material="brick", area=150) for _ in range(40)]
        tmpl = copy.deepcopy(self.tmpl)
        p, prov = draft.make_draft("z", "Zone", "r", [FakeCell(hs)], tmpl, "default", [100.0] * 40, None,
                                   materials={"wall": {"brick": {"family": "red", "hex": "#A9735F"}}, "roof": {}})
        self.assertEqual(prov.items["houseTypes[].colors[wall]"]["status"], "calibrated")
        self.assertTrue(validate.validate(p).ok)


if __name__ == "__main__":
    unittest.main()
