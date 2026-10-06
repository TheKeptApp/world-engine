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


if __name__ == "__main__":
    unittest.main()
