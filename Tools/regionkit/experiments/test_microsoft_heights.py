import unittest
from shapely.geometry import box
from microsoft_heights import match, metrics, usable, tile_bounds

class JoinControls(unittest.TestCase):
    def test_unique_and_low_overlap(self):
        matches,diag=match({'good':box(0,0,10,10),'low':box(20,0,30,10)},[box(0,0,10,10),box(25,0,35,10)])
        self.assertEqual(set(matches),{'good'});self.assertEqual(diag['noEligibleOverlap'],1)
    def test_duplicate_sources_rejected(self):
        matches,diag=match({'a':box(0,0,10,10)},[box(0,0,10,10)]*2)
        self.assertFalse(matches);self.assertEqual(diag['multipleEligibleSources'],1)
    def test_shared_source_rejected(self):
        matches,diag=match({'a':box(0,0,10,10),'b':box(0,0,10,10)},[box(0,0,10,10)])
        self.assertFalse(matches);self.assertEqual(diag['sharedEligibleSourceRecords'],1)
    def test_missing_and_signed_errors(self):
        for value in [-1,0,None,True,float('nan'),'4']:self.assertFalse(usable(value))
        self.assertTrue(usable(4));m=metrics([-2,0,1]);self.assertAlmostEqual(m['signedMeanBiasM'],-1/3)
        self.assertEqual(m['medianAbsoluteM'],1);self.assertFalse(metrics([])['meetsProposedThresholds'])
    def test_quadkey_bounds(self):
        self.assertEqual(tile_bounds('')[0],-180);self.assertEqual(tile_bounds('')[2],180)
        w,s,e,n=tile_bounds('023101030');self.assertTrue(w < -105.0445 < e and s <39.7494<n)

if __name__=='__main__':unittest.main()
