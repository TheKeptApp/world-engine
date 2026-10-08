import unittest
import numpy as np
import observed_heights as O
import observed_roofs as R
from test_heights import footprint, gable_cloud, ground_cloud

class RoofEvidence(unittest.TestCase):
    def test_missing_height_does_not_imply_flat(self):
        rec = R.classify(footprint(), np.empty((0, 3)), {'evidence_code': 'missing'}, O.L.load('params.json'))
        self.assertIsNone(rec['type'])
        self.assertIsNone(rec['pitch_deg'])
        self.assertIsNone(rec['ridge_bearing_deg'])
        self.assertIsNone(rec['confidence']['support_score'])

    def test_gable_recovers_pitch_and_axis_without_probability_claim(self):
        p = footprint(); points = gable_cloud(p)
        h = O.record_for(p, points, ground_cloud(p), O.H.load_params())
        h['qa']['roof_selection'] = {'planarPointShare': None}
        r = R.classify(p, points, h, O.L.load('params.json'))
        self.assertEqual(r['type'], 'gable')
        self.assertAlmostEqual(r['pitch_deg'], 35, delta=2)
        self.assertAlmostEqual(r['ridge_bearing_deg'], 90, delta=2)
        self.assertIsNone(r['confidence']['calibrated_probability'])
        self.assertEqual(r['quality_grade'], 'D')

    def test_flat_has_measured_small_pitch_and_no_ridge(self):
        p = footprint(); points = gable_cloud(p, pitch=0)
        h = O.record_for(p, points, ground_cloud(p), O.H.load_params())
        h['qa']['roof_selection'] = {'planarPointShare': None}
        r = R.classify(p, points, h, O.L.load('params.json'))
        self.assertEqual(r['type'], 'flat')
        self.assertLess(r['pitch_deg'], 1)
        self.assertIsNone(r['ridge_bearing_deg'])

    def test_nearly_north_ridge_wraps_rounded_180_to_zero(self):
        from shapely.affinity import rotate
        p = footprint(); points = gable_cloud(p)
        angle = np.deg2rad(90.04)
        matrix = np.array([[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]])
        points[:, :2] = points[:, :2] @ matrix.T
        p = rotate(p, 90.04, origin=(0,0))
        h = O.record_for(p, points, ground_cloud(p), O.H.load_params())
        h['qa']['roof_selection'] = {'planarPointShare': None}
        r = R.classify(p, points, h, O.L.load('params.json'))
        self.assertEqual(r['type'], 'gable')
        self.assertGreaterEqual(r['ridge_bearing_deg'], 0)
        self.assertLess(r['ridge_bearing_deg'], 180)
        self.assertAlmostEqual(r['ridge_bearing_deg'], 0, delta=1)
