import unittest
import numpy as np
from scipy.spatial import cKDTree
from shapely.geometry import box
from fallback_validation import metrics,levels_candidate,dsm_candidate,number
class FallbackValidation(unittest.TestCase):
 def test_signed_bias_and_absolute_percentiles(self):
  m=metrics([-3,-2,-1,0,1]);self.assertEqual(m['medianAbsoluteM'],1);self.assertEqual(m['meanBiasM'],-1);self.assertAlmostEqual(m['p90AbsoluteM'],2.6)
 def test_small_sample_not_a_pass(self):self.assertIsNone(metrics([0,0])['p90AbsoluteM'])
 def test_levels_preserve_unknown_roof(self):self.assertEqual(levels_candidate({'building:levels':'2'},3),(None,6,'missing_roof_height'))
 def test_explicit_roof(self):self.assertEqual(levels_candidate({'building:levels':'2','roof:height':'1.5'},3)[0],7.5)
 def test_explicit_roof_wins_over_shape(self):self.assertEqual(levels_candidate({'building:levels':'2','roof:height':'1.5','roof:shape':'flat'},3)[0],7.5)
 def test_invalid_roof_is_not_inferred_flat(self):self.assertIsNone(levels_candidate({'building:levels':'2','roof:height':'unknown','roof:shape':'flat'},3)[0])
 def test_invalid_value(self):self.assertIsNone(number(True));self.assertIsNone(number('nan'));self.assertIsNone(number(-1))
 def test_dsm_ground_subtraction(self):
  xy=np.array([(x+.5,y+.5) for x in range(6) for y in range(6)]);ground=np.column_stack((xy,np.full(len(xy),100)));surface=np.column_stack((xy,np.full(len(xy),108)));cfg={'erosionM':.1,'minimumSurfacePoints':20,'cellM':1,'groundNeighbours':12,'groundRadiusM':15,'minimumGroundNeighbours':3,'minimumCoverage':.5}
  self.assertAlmostEqual(dsm_candidate(box(0,0,6,6),surface,cKDTree(xy),ground,cfg)[0],8)
