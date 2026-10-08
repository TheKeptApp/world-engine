"""Committed observed height datasets must share one method and preserve evidence."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import compare_heights as C


class HeightHoldouts(unittest.TestCase):
    def test_configured_areas_share_method_and_valid_height_evidence(self):
        areas = C.O.L.load('observed-heights.json')['authorizedAreas']
        result = C.compare(areas)
        self.assertTrue(result['identicalMethods'])
        self.assertEqual(result['errors'], [])
        self.assertEqual(len(result['areas']), len(areas))
        print('HEIGHT_COMPARISON ' + C.json.dumps(result, sort_keys=True))
