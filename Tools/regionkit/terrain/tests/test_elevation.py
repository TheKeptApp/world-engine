"""Synthetic end-to-end elevation extraction, including nodata and ridge extrema."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import numpy as np
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import elevation as E

class ElevationEvidence(unittest.TestCase):
    def test_native_clip_and_coarse_peak_envelope(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); area = root/'Data/areas/example'; area.mkdir(parents=True)
            man = {'center': {'latitude': 39.75, 'longitude': -105.0}, 'widthMeters': 12, 'heightMeters': 12}
            (area/'manifest.json').write_text(json.dumps(man))
            cx,cy = [v[0] for v in E.transform('EPSG:4326','EPSG:26913',[-105],[39.75])]
            source = root/'USGS_1_n40w106_TEST.tif'
            a = np.full((40,40), 1600, dtype='float32'); a[8,8] = 1900; a[:3,:3] = E.NODATA
            with E.rasterio.open(source,'w',driver='GTiff',width=40,height=40,count=1,dtype='float32',crs='EPSG:26913',transform=E.from_origin(cx-20,cy+20,1,1),nodata=E.NODATA) as ds: ds.write(a,1)
            (root/'policy.json').write_text(json.dumps({'demByDistance':[{'rangeM':[0,5]}, {'rangeM':[5,20],'meshSampleGuideM':4}]}))
            config = {'defaultArea':'example','authorizedAreas':['example'],'licenseStatus':'GREEN','verticalDatum':'NAVD88','verticalCRS':'EPSG:5703','license':'public domain','sourceEvidence':[],'checkedOn':'2026-10-08','nativeBufferMeters':0,'nativeProjects':{'example':'TEST'},'maximumDistanceM':20,'maximumNativeReadBytes':100000,'distancePolicy':'policy.json#demByDistance'}
            cp = root/'config.json'; cp.write_text(json.dumps(config))
            real_open = E.rasterio.open
            def opener(path,*args,**kw): return real_open(str(path).removeprefix('/vsicurl/'),*args,**kw)
            item = {'downloadURL':str(source),'title':'Synthetic TEST','publicationDate':'2026-01-01'}
            from types import SimpleNamespace
            with patch.object(E,'REPO',root), patch.object(E,'catalogue',return_value=[item]), patch.object(E.rasterio,'open',side_effect=opener):
                E.run(SimpleNamespace(config=str(cp),area=None,work=str(root/'cache')))
            data = area/'elevation'; meta = json.loads((data/'metadata.json').read_text())
            self.assertFalse(meta['ellipsoidTransformApplied'])
            self.assertEqual(meta['nativeClips'][0]['resampling'],'none')
            with real_open(data/'native-1m-0.tif') as ds:
                self.assertEqual(ds.res,(1.,1.)); self.assertTrue(np.all(ds.read(1)==1600))
            with np.load(data/'band-5-20m.npz') as d:
                self.assertEqual(float(d['maximum_m'].max()),1900)
                valid = d['elevation_m'] != E.NODATA
                self.assertTrue(np.all(d['maximum_m'][valid] >= d['elevation_m'][valid]))
                self.assertTrue(np.all(d['minimum_m'][valid] <= d['elevation_m'][valid]))
                self.assertTrue(np.any(~valid))
            import audit_elevation as A
            with patch.object(E,'REPO',root):
                result=A.audit('example')
                self.assertEqual(result['errors'],[])
                self.assertEqual(result['nativeCoverage']['validFraction'],1.)
                meta['bands'][0]['coveredCells']-=1
                (data/'metadata.json').write_text(json.dumps(meta))
                result=A.audit('example')
                self.assertTrue(any('coverage_metadata' in e for e in result['errors']))

class CatalogueFailures(unittest.TestCase):
    def test_http_200_error_is_retried_and_not_cached_as_data(self):
        import io
        with tempfile.TemporaryDirectory() as directory:
            work=Path(directory)
            valid={'total':0,'items':[]}
            responses=[io.BytesIO(b'{"error":"temporary provider failure"}'),io.BytesIO(json.dumps(valid).encode())]
            with patch.object(E.urllib.request,'urlopen',side_effect=responses) as request,patch.object(E.time,'sleep'):
                self.assertEqual(E.catalogue('fixture',(-1,-1,1,1),work),[])
            self.assertEqual(request.call_count,2)
            self.assertEqual(json.loads(next(work.glob('*.json')).read_text()),valid)

    def test_permanent_http_error_does_not_retry_or_create_cache(self):
        from urllib.error import HTTPError
        with tempfile.TemporaryDirectory() as directory:
            work=Path(directory)
            with patch.object(E.urllib.request,'urlopen',side_effect=HTTPError('https://example.invalid',404,'missing',{},None)) as request,patch.object(E.time,'sleep') as sleep:
                with self.assertRaises(HTTPError):E.catalogue('fixture',(-1,-1,1,1),work)
            self.assertEqual(request.call_count,1);sleep.assert_not_called();self.assertEqual(list(work.iterdir()),[])
