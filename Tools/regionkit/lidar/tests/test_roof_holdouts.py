"""Verify committed roof hold-outs without area-specific classifier settings."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import compare_roofs as C

class RoofHoldouts(unittest.TestCase):
    def test_configured_roofs_have_common_methods_and_valid_evidence(self):
        result=C.compare(C.O.L.load('observed-heights.json')['authorizedAreas'])
        self.assertTrue(result['identicalMethods']);self.assertEqual(result['errors'],[])
        print('ROOF_COMPARISON '+C.json.dumps(result,sort_keys=True))
