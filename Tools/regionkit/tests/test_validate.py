import copy
import os
import unittest

from regionkit import paths, profiles, validate


class ExistingProfiles(unittest.TestCase):
    def test_all_known_profiles_pass(self):
        known = profiles.all_known()
        ids = [k[0] for k in known]
        self.assertIn("default", ids)
        self.assertIn("front-range", ids)
        self.assertIn("north-texas-dfw", ids)
        for pid, prof, src in known:
            r = validate.validate(prof, pid)
            self.assertTrue(r.ok, "%s: %s" % (src, r.errors))

    def test_written_drafts_pass(self):
        for root, _, files in os.walk(paths.DRAFTS):
            if "profile.json" in files:
                p = os.path.join(root, "profile.json")
                r = validate.validate(paths.load_json(p), p)
                self.assertTrue(r.ok, "%s: %s" % (p, r.errors))


class Broken(unittest.TestCase):
    def setUp(self):
        self.base, _ = profiles.load("front-range")

    def broken(self, mutate):
        p = copy.deepcopy(self.base)
        mutate(p)
        return validate.validate(p)

    def test_missing_required_key(self):
        self.assertFalse(self.broken(lambda p: p.pop("garage")).ok)
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0].pop("porch")).ok)

    def test_bad_colour(self):
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0]["colors"][0].__setitem__(1, "#12345")).ok)
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0]["colors"][0].pop()).ok)

    def test_unknown_type_in_rules(self):
        self.assertFalse(self.broken(lambda p: p["typeRules"]["unknown"].__setitem__("castle", 5)).ok)

    def test_negative_weight(self):
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0]["roof"].__setitem__("gabled", -1)).ok)
        self.assertFalse(self.broken(lambda p: p["typeRules"]["oneFloor"].__setitem__("bungalow", -3)).ok)

    def test_range_order_and_float_floors(self):
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0].__setitem__("pitch", [35, 20])).ok)
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0].__setitem__("floors", [1.0])).ok)
        self.assertFalse(self.broken(lambda p: p["houseTypes"][0].__setitem__("floors", [0])).ok)

    def test_silently_dropped_rule_is_an_error(self):
        self.assertFalse(self.broken(lambda p: p["typeRules"]["oneFloor"].__setitem__("bungalow", "65")).ok)

    def test_comment_string_in_type_rules_is_fine(self):
        self.assertTrue(self.broken(lambda p: p["typeRules"].__setitem__("comment", "note")).ok)

    def test_share_out_of_range(self):
        self.assertFalse(self.broken(lambda p: p["trees"].__setitem__("deciduousShare", 1.2)).ok)


class OptionalFields(unittest.TestCase):
    """trees.canopyShare and typeThresholds.*AreaPercentile are optional (absent or null = nil)."""

    def setUp(self):
        self.base, _ = profiles.load("front-range")
        for k in validate.THRESH_PCT:
            self.base["typeThresholds"].pop(k, None)
        self.base["trees"].pop("canopyShare", None)
        self.base.pop("provenance", None)

    def check(self, mutate):
        p = copy.deepcopy(self.base)
        mutate(p)
        return validate.validate(p)

    def pct(self, s, l, h):
        def m(p):
            for k, v in zip(validate.THRESH_PCT, (s, l, h)):
                p["typeThresholds"][k] = v
        return m

    def test_absent_and_null_are_fine(self):
        r = self.check(lambda p: None)
        self.assertTrue(r.ok, r.errors)
        self.assertFalse(r.warnings)
        r = self.check(self.pct(None, None, None))
        self.assertTrue(r.ok, r.errors)
        self.assertTrue(self.check(lambda p: p["trees"].__setitem__("canopyShare", None)).ok)

    def test_valid_values_are_known_keys(self):
        r = self.check(lambda p: (self.pct(0.02, 0.865, 0.99)(p), p["trees"].__setitem__("canopyShare", 0.58)))
        self.assertTrue(r.ok, r.errors)
        self.assertFalse([i for i in r.info if "Percentile" in i or "canopyShare" in i])   # not "unknown key"

    def test_ranges(self):
        self.assertFalse(self.check(lambda p: p["trees"].__setitem__("canopyShare", 1.3)).ok)
        self.assertFalse(self.check(lambda p: p["trees"].__setitem__("canopyShare", -0.1)).ok)
        self.assertFalse(self.check(lambda p: p["trees"].__setitem__("canopyShare", "0.5")).ok)
        self.assertFalse(self.check(self.pct(0.02, 0.865, 1.5)).ok)
        self.assertFalse(self.check(self.pct(-0.1, 0.865, 0.99)).ok)
        self.assertFalse(self.check(self.pct(0.02, "0.865", 0.99)).ok)

    def test_order(self):
        self.assertFalse(self.check(self.pct(0.9, 0.865, 0.99)).ok)
        self.assertFalse(self.check(self.pct(0.02, 0.99, 0.99)).ok)    # strictly increasing
        self.assertFalse(self.check(self.pct(0.02, None, 0.01)).ok)    # order checked among present ones

    def test_partial_set_warns(self):
        r = self.check(self.pct(None, 0.865, None))
        self.assertTrue(r.ok, r.errors)
        self.assertTrue(any("area percentiles" in w for w in r.warnings))

    def test_provenance_is_a_documentation_key(self):
        r = self.check(lambda p: p.__setitem__("provenance", {"comment": "doc", "typeRules.unknown": {"status": "measured", "n": 3}}))
        self.assertTrue(r.ok)
        self.assertFalse(r.warnings)
        self.assertFalse([i for i in r.info if "provenance" in i])
        r = self.check(lambda p: p.__setitem__("provenance", "measured"))
        self.assertTrue(r.ok)                                           # the decoder ignores it either way
        self.assertTrue(any("provenance" in w for w in r.warnings))


if __name__ == "__main__":
    unittest.main()
