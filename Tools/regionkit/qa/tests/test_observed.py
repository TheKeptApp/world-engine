import json
from pathlib import Path
import sys
import unittest
HERE=Path(__file__).resolve().parents[1];sys.path.insert(0,str(HERE))
from observed import inspect_record
POLICY=json.loads((HERE/'data/observed.json').read_text())

class BadEvidence(unittest.TestCase):
    def height(self, value):
        return {'roof_top_agl_m':value,'evidence_code':'missing' if value is None else 'measured_derived_lidar','base_elevation_m':1600,'quality_grade':'D'}
    def test_missing_height_flags_but_does_not_invent_failure(self):
        r=inspect_record(self.height(None),{'type':None,'pitch_deg':None,'ridge_bearing_deg':None},100,True,.5,POLICY)
        self.assertEqual(r['flags'],['height_missing']);self.assertEqual(r['errors'],[])
    def test_zero_height_and_broken_footprint_fail(self):
        r=inspect_record(self.height(0),None,0,False,0,POLICY)
        self.assertIn('height_zero_or_invalid',r['errors']);self.assertIn('footprint_invalid',r['errors'])
    def test_roof_without_height_and_wrong_bearing_fail(self):
        r=inspect_record(self.height(None),{'type':'gable','pitch_deg':30,'ridge_bearing_deg':190},100,True,.5,POLICY)
        self.assertIn('roof_form_without_height',r['errors']);self.assertIn('roof_ridge_missing_or_invalid',r['errors'])
    def test_unlabelled_placeholder_and_uncalibrated_grade_fail(self):
        h=self.height(6);h.update(evidence_code='inferred',quality_grade='A')
        r=inspect_record(h,{'type':'flat','pitch_deg':1,'ridge_bearing_deg':None},100,True,.5,POLICY)
        self.assertIn('height_without_observed_evidence',r['errors']);self.assertIn('grade_without_calibration',r['errors'])
