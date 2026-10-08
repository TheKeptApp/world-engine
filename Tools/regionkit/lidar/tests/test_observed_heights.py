"""Height evidence and missingness tests; synthetic observations only."""
import sys
from pathlib import Path
import unittest

import numpy as np
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import observed_heights as O
from test_heights import footprint, gable_cloud, ground_cloud


class ObservedHeights(unittest.TestCase):
    def test_same_survey_height_is_invariant_to_vertical_offset(self):
        poly = footprint()
        roof, ground = gable_cloud(poly), ground_cloud(poly)
        a = O.record_for(poly, roof, ground, O.H.load_params())
        roof[:, 2] += 1000
        ground[:, 2] += 1000
        b = O.record_for(poly, roof, ground, O.H.load_params())
        self.assertEqual(a['evidence_code'], 'measured_derived_lidar')
        self.assertEqual(a['roof_top_agl_m'], b['roof_top_agl_m'])
        self.assertAlmostEqual(b['base_elevation_m'] - a['base_elevation_m'], 1000, places=3)
        self.assertEqual(a['quality_grade'], 'D')
        self.assertIsNone(a['interval90_m'])

    def test_no_ground_never_becomes_a_height(self):
        poly = footprint()
        rec = O.record_for(poly, gable_cloud(poly), np.empty((0, 3)), O.H.load_params())
        self.assertEqual(rec['evidence_code'], 'missing')
        self.assertIsNone(rec['roof_top_agl_m'])
        self.assertIsNone(rec['base_elevation_m'])

    def test_missing_roof_is_not_zero_or_default(self):
        poly = footprint()
        rec = O.record_for(poly, np.empty((0, 3)), ground_cloud(poly), O.H.load_params())
        self.assertEqual(rec['evidence_code'], 'missing')
        self.assertIsNone(rec['roof_top_agl_m'])
        self.assertIsNone(rec['eave_agl_m'])

    def test_unclassified_planar_roof_and_sparse_noise(self):
        poly = footprint()
        roof, ground = gable_cloud(poly), ground_cloud(poly)
        settings = {'minimumPlanarPointShare': .8, 'maximumPitchDeg': 75}
        selected, diag = O.planar_candidates(poly, roof, ground, O.H.load_params(), settings)
        self.assertGreater(len(selected), 20)
        self.assertEqual(diag['status'], 'planar_candidates')
        self.assertEqual(O.record_for(poly, selected, ground, O.H.load_params())['quality_grade'], 'D')
        rng = np.random.default_rng(91)
        noise = np.column_stack((rng.uniform(-5, 5, 70), rng.uniform(-3, 3, 70), rng.uniform(189, 220, 70)))
        selected, diag = O.planar_candidates(poly, noise, ground, O.H.load_params(), settings)
        self.assertEqual(len(selected), 0)

    def test_grades_require_independent_calibration_and_qa(self):
        self.assertEqual(O.grade_for(.5, 0, True), 'D')
        self.assertEqual(O.grade_for(.5, 100, False), 'D')
        self.assertEqual(O.grade_for(float('nan'), 100, True), 'D')
        self.assertEqual([O.grade_for(e, 100, True) for e in [1, 3, 5, 6]], ['A', 'B', 'C', 'D'])


if __name__ == '__main__':
    unittest.main()
