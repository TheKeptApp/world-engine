"""Offline tests of the roof-accuracy tool's pure functions (numpy only; no network, no imagery, no lidar)."""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import roofaccuracy as ra  # noqa: E402

CFG = ra.load_cfg()


class Sampling(unittest.TestCase):
    refs = [f"way/{i}" for i in range(500)] + [f"overture/{i}" for i in range(50)] + ["relation/7"]

    def test_sets_are_stable_disjoint_and_osm_only(self):
        a1 = ra.draw_sets(self.refs, CFG, "evanston-south")
        a2 = ra.draw_sets(list(reversed(self.refs)), CFG, "evanston-south")
        self.assertEqual(a1, a2)  # independent of the order of the input
        test, tune = a1
        self.assertEqual((len(test), len(tune)), (CFG["test"]["n"], CFG["tune"]["n"]))
        self.assertFalse(set(test) & set(tune))
        self.assertTrue(all(r.startswith(("way/", "relation/")) for r in test + tune))

    def test_area_changes_the_draw(self):
        self.assertNotEqual(ra.draw_sets(self.refs, CFG, "evanston-south")[0], ra.draw_sets(self.refs, CFG, "lakeview-sheil-park")[0])

    def test_adding_roofs_keeps_most_of_the_sample(self):
        # the n smallest hashes: appending refs can only displace sampled ones, never reshuffle the rest
        more = self.refs + [f"way/{i}" for i in range(1000, 1010)]
        a = set(ra.draw_sets(self.refs, CFG, "x")[0])
        b = set(ra.draw_sets(more, CFG, "x")[0])
        self.assertGreaterEqual(len(a & b), len(a) - 5)


class Scoring(unittest.TestCase):
    def test_accuracy_per_class_and_cant_tell(self):
        pairs = [("flat", "flat"), ("gable", "gable"), ("gable", "complex"), ("hip", "hip"), ("complex", "complex"),
                 ("complex", "gable"), ("cant_tell", "complex")]
        s = ra.score_pairs(pairs)
        self.assertEqual((s["nLabelled"], s["nCantTell"], s["n"], s["correct"]), (7, 1, 6, 4))
        self.assertAlmostEqual(s["accuracy"], 0.667, places=3)
        self.assertEqual(s["perClass"]["gable"]["nHand"], 2)
        self.assertEqual(s["perClass"]["gable"]["correct"], 1)
        self.assertEqual(s["perClass"]["complex"]["nPredicted"], 2)
        self.assertEqual(s["perClass"]["complex"]["precision"], 0.5)
        self.assertEqual(s["perClass"]["mansard"]["nHand"], 0)
        self.assertIsNone(s["perClass"]["mansard"]["recall"])

    def test_simple_called_complex_and_the_reverse(self):
        pairs = [("flat", "flat"), ("gable", "complex"), ("hip", "complex"), ("hip", "hip"), ("complex", "hip"), ("complex", "complex")]
        s = ra.score_pairs(pairs)
        self.assertEqual(s["simpleCalledComplex"], {"nSimpleByHand": 4, "calledComplex": 2, "rate": 0.5})
        self.assertEqual(s["complexCalledSimple"], {"nComplexByHand": 2, "calledSimple": 1, "rate": 0.5})
        self.assertEqual(s["simpleFormAccuracy"]["correct"], 2)

    def test_confusion_rows_are_hand_labels(self):
        s = ra.score_pairs([("gable", "hip"), ("gable", "hip"), ("hip", "gable")])
        self.assertEqual(s["confusion"]["gable"]["hip"], 2)
        self.assertEqual(s["confusion"]["hip"]["gable"], 1)

    def test_empty(self):
        s = ra.score_pairs([])
        self.assertEqual((s["n"], s["accuracy"]), (0, None))


if __name__ == "__main__":
    unittest.main()
