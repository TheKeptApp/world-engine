#!/usr/bin/env python3
"""Read-back terrain QA: source-native clips, requested coverage and ridge envelopes."""
import argparse
import json
import math
import os
from pathlib import Path
import re
import numpy as np
import rasterio
from affine import Affine
import elevation as E


def require_lock():
    owner=Path.home()/'.agent-heavy-lock/owner'
    match=re.search(r'(?im)^pid\s*[=:]\s*(\d+)',owner.read_text() if owner.exists() else '')
    if not match or int(match.group(1))!=os.getppid():
        raise RuntimeError('Run directly under scripts/heavy.sh with a live owned lock')


def audit(area):
    require_lock();E.guard()
    root=E.REPO/'Data/areas'/area/'elevation'
    meta=json.loads((root/'metadata.json').read_text());errors=[];flags=[];reports=[]
    man=json.loads((root.parent/'manifest.json').read_text())
    policy=json.loads((E.REPO/meta['policy'].split('#')[0]).read_text())['demByDistance']
    expected=[([b['rangeM'][0],min(b['rangeM'][1],meta['maximumDistanceM'])],b['meshSampleGuideM']) for b in policy[1:] if b['rangeM'][0]<meta['maximumDistanceM']]
    if [(b['rangeM'],b['sampleSpacingM']) for b in meta['bands']]!=expected:errors.append('distance_policy_incomplete_or_changed')
    cx,cy=[v[0] for v in E.transform('EPSG:4326',meta['horizontalCRS'],[man['center']['longitude']],[man['center']['latitude']])]
    width=man['widthMeters']+2*meta['nativeBufferMeters'];height=man['heightMeters']+2*meta['nativeBufferMeters']
    native_mask=np.zeros((math.ceil(height),math.ceil(width)),dtype='uint8')
    native_transform=E.from_origin(cx-width/2,cy+height/2,1,1)
    if not meta['nativeClips']:errors.append('no_native_1m_clips')
    for entry in meta['nativeClips']:
        path=root/entry['file']
        if E.digest(path)!=entry['sha256']:errors.append(entry['file']+': digest')
        with rasterio.open(path) as ds:
            a=ds.read(1,masked=True)
            if ds.crs.linear_units not in ('metre','meter') or ds.res!=(1.,1.) or not np.isfinite(a.compressed()).all():errors.append(entry['file']+': resolution/finite')
            coverage=np.zeros_like(native_mask)
            E.reproject((~np.ma.getmaskarray(a)).astype('uint8'),coverage,src_transform=ds.transform,src_crs=ds.crs,src_nodata=0,dst_transform=native_transform,dst_crs=meta['horizontalCRS'],dst_nodata=0,resampling=E.Resampling.nearest,num_threads=1)
            native_mask=np.maximum(native_mask,coverage)
            reports.append({'file':entry['file'],'validFraction':float(a.count()/a.size),'minimumM':float(a.min()) if a.count() else None,'maximumM':float(a.max()) if a.count() else None})
    native_coverage={'coveredCells':int(native_mask.sum()),'requestedCells':int(native_mask.size),'validFraction':float(native_mask.mean()),'scope':'Area rectangle plus configured halo; 1 m coverage mask, persisted elevation clips unresampled'}
    if native_coverage['validFraction']<1:flags.append('native_1m_coverage_gap')
    for entry in meta['bands']:
        path=root/entry['file']
        if E.digest(path)!=entry['sha256']:errors.append(entry['file']+': digest')
        with np.load(path) as d:
            a,lo,hi=d['elevation_m'],d['minimum_m'],d['maximum_m'];valid=a!=E.NODATA
            if list(a.shape)!=entry['shape'] or lo.shape!=a.shape or hi.shape!=a.shape:errors.append(entry['file']+': shape')
            if not np.isfinite(a).all() or not np.isfinite(lo).all() or not np.isfinite(hi).all():errors.append(entry['file']+': nonfinite')
            if np.any(lo[valid]>a[valid]) or np.any(hi[valid]<a[valid]) or np.any(lo[valid]==E.NODATA) or np.any(hi[valid]==E.NODATA):errors.append(entry['file']+': envelope')
            mask=E.band_mask(a.shape,Affine(*entry['transform'][:6]),cx,cy,*entry['rangeM'])
            covered=int((mask&valid).sum());requested=int(mask.sum())
            if covered!=entry['coveredCells'] or requested!=entry['requestedCells'] or np.any(valid&~mask):errors.append(entry['file']+': coverage_metadata')
            fraction=covered/requested if requested else 0
            if fraction<1:flags.append(entry['file']+': coverage_gap')
            reports.append({'file':entry['file'],'validFraction':fraction,'minimumM':float(lo[valid].min()) if valid.any() else None,'maximumM':float(hi[valid].max()) if valid.any() else None})
    result={'format':'worldengine-elevation-qa/1','area':area,'metadataSHA256':E.digest(root/'metadata.json'),'status':'FAIL' if errors else 'PASS_WITH_GAPS' if flags else 'PASS','errors':errors,'flags':flags,'nativeCoverage':native_coverage,'artifacts':reports}
    (root/'qa.json').write_text(json.dumps(result,indent=2,allow_nan=False)+'\n');print(json.dumps(result));return result


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--area',required=True);args=ap.parse_args();raise SystemExit(bool(audit(args.area)['errors']))
