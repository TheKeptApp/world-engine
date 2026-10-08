#!/usr/bin/env python3
"""Audit observed building sidecars; report unknowns separately from broken invariants."""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(HERE.parent/'lidar'))
import observed_heights as O


def inspect_record(height, roof, area, valid, compactness, policy):
    flags = []; errors = []
    value = height.get('roof_top_agl_m')
    if value is None:
        flags.append('height_missing')
    elif not isinstance(value, (int,float)) or not math.isfinite(value) or value <= 0:
        errors.append('height_zero_or_invalid')
    elif value > policy['heightReviewCeilingM']:
        flags.append('height_implausibly_large')
    if value is not None and height.get('evidence_code') != 'measured_derived_lidar':
        errors.append('height_without_observed_evidence')
    if height.get('evidence_code') == 'measured_derived_lidar' and value is None:
        errors.append('measured_height_is_null')
    if value is not None and (not isinstance(height.get('base_elevation_m'), (int,float)) or not math.isfinite(height['base_elevation_m'])):
        errors.append('height_without_ground')
    if not valid or area <= 0:
        errors.append('footprint_invalid')
    elif area < policy['minimumFootprintM2'] or area > policy['maximumFootprintM2'] or compactness < policy['minimumCompactness']:
        flags.append('footprint_implausible_or_below_method_size')
    if height.get('quality_grade') not in ('A','B','C','D'):
        errors.append('quality_grade_invalid')
    if height.get('quality_grade') != 'D' and not height.get('calibration_group'):
        errors.append('grade_without_calibration')
    if value is not None:
        for field in ['roof_typical_agl_m','eave_agl_m']:
            x = height.get(field)
            if x is not None and (not isinstance(x, (int,float)) or not math.isfinite(x) or x <= 0 or (isinstance(value, (int,float)) and x > value + policy['roofHeightToleranceM'])):
                flags.append(field + '_exceeds_roof_top_or_nonpositive')
    if roof is None:
        errors.append('roof_record_missing')
    else:
        form,pitch,ridge = roof.get('type'),roof.get('pitch_deg'),roof.get('ridge_bearing_deg')
        if form is not None and value is None:
            errors.append('roof_form_without_height')
        if form is not None and form not in ('flat','gable','hip','other'):
            errors.append('roof_type_invalid')
        if form is not None and (not isinstance(pitch, (int,float)) or not math.isfinite(pitch) or not 0 <= pitch <= 90):
            errors.append('roof_pitch_missing_or_invalid')
        if form in ('gable','hip') and (not isinstance(ridge, (int,float)) or not math.isfinite(ridge) or not 0 <= ridge < 180):
            errors.append('roof_ridge_missing_or_invalid')
        if form in ('flat','other',None) and ridge is not None:
            errors.append('unexpected_ridge')
        if form is None and pitch is not None:
            errors.append('unknown_roof_has_pitch')
    return {'flags':flags,'errors':errors}


def run(area, output):
    # QA is a test run, including when invoked independently.
    O.require_heavy_lock(); O.disk_guard(REPO)
    allowed = O.L.load('observed-heights.json')['authorizedAreas']
    if area not in allowed: raise ValueError('Area not authorized for QA processing')
    root = REPO/'Data/areas'/area
    heights=json.loads((root/'building-heights.json').read_text()); roofs=json.loads((root/'building-roofs.json').read_text())
    policy=json.loads((HERE/'data/observed.json').read_text())
    man=json.loads((root/'manifest.json').read_text())
    fps,_=O.L.footprints({'area':'Data/areas/'+area},man)
    rows={}; errors=[]
    source=heights['source']
    if not source.get('groundAndRoofSameSurvey') or not source.get('fullDensity'): errors.append('height_survey_provenance_incomplete')
    if source.get('licenseStatus') != 'GREEN': errors.append('height_source_not_green')
    if roofs['source']['id'] != source['id'] or roofs['source']['verticalCRS'] != source['verticalCRS']: errors.append('roof_height_source_or_datum_mismatch')
    digest=O.sha(root/'building-heights.json')
    if roofs['heightSidecarSHA256'] != digest: errors.append('roof_height_digest_mismatch')
    if heights['footprints']['sha256'] != O.sha(root/'osm.json'): errors.append('stale_footprint_digest')
    if set(heights['records']) != set(roofs['records']): errors.append('roof_height_id_mismatch')
    for ref,h in heights['records'].items():
        p=fps[ref]['poly']; compact=4*math.pi*p.area/p.length**2 if p.length else 0
        rows[ref]=inspect_record(h,roofs['records'].get(ref),p.area,p.is_valid,compact,policy)
    values=Counter(h['roof_top_agl_m'] for h in heights['records'].values() if h['roof_top_agl_m'] is not None)
    for value,n in values.items():
        if n>=policy['repeatedHeightMinimumCount'] and n/sum(values.values())>=policy['repeatedHeightMinimumFraction']:
            for ref,h in heights['records'].items():
                if h['roof_top_agl_m']==value: rows[ref]['flags'].append('possible_repeated_placeholder_height')
    counts=Counter(flag for row in rows.values() for flag in row['flags'])
    failures=Counter(flag for row in rows.values() for flag in row['errors'])
    result={'format':'worldengine-observed-data-qa/1','area':area,'heightSHA256':digest,
            'roofSHA256':O.sha(root/'building-roofs.json'),'policy':policy,
            'counts':{'buildings':len(rows),'flags':dict(counts),'errors':dict(failures)},'datasetErrors':errors,
            'status':'FAIL' if errors or failures else 'PASS_WITH_GAPS' if counts else 'PASS',
            'qualityNote':'Identical checks for every configured area; missing data remain null. Flags are review needs, not independently verified accuracy.',
            'records':rows}
    Path(output).write_text(json.dumps(result,indent=2,sort_keys=True,allow_nan=False)+'\n')
    print(json.dumps({k:result[k] for k in ['area','status','counts','datasetErrors']}))
    return 1 if errors or failures else 0


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--area',required=True);ap.add_argument('--output',required=True)
    a=ap.parse_args();sys.exit(run(a.area,a.output))
