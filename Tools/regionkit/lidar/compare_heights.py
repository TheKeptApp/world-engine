#!/usr/bin/env python3
"""Compare arbitrary height hold-outs without changing their measurement policy."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path
import observed_heights as O


def compare(areas):
    O.require_heavy_lock()
    rows = []; methods = []; errors = []
    for area in areas:
        if area not in O.L.load('observed-heights.json')['authorizedAreas']:
            raise ValueError('Unauthorized area: ' + area)
        root = O.REPO / 'Data/areas' / area
        d = json.loads((root / 'building-heights.json').read_text())
        methods.append(d['method'])
        if d['footprints']['sha256'] != O.sha(root / 'osm.json'):
            errors.append(area + ': footprint digest mismatch')
        src = d['source']
        if not (src['licenseStatus'] == 'GREEN' and src['fullDensity'] and src['groundAndRoofSameSurvey'] and src['verticalUnits'] == 'metre'):
            errors.append(area + ': survey evidence incomplete')
        accepted = 0; values = []; grades = Counter(); missing = Counter()
        for ref, r in d['records'].items():
            h = r['roof_top_agl_m']; grades[r['quality_grade']] += 1
            if h is None:
                missing[r['qa']['status']] += 1
                if r['evidence_code'] != 'missing': errors.append(area + ':' + ref + ': missing height labelled measured')
            else:
                accepted += 1; values.append(h)
                ground = r['base_elevation_m']
                if not (isinstance(h, (float,int)) and math.isfinite(h) and h > 0 and isinstance(ground,(float,int)) and math.isfinite(ground) and r['evidence_code'] == 'measured_derived_lidar'):
                    errors.append(area + ':' + ref + ': invalid measured height or ground')
            if r['quality_grade'] not in ('A','B','C','D') or (r['quality_grade'] != 'D' and not r.get('calibration_group')):
                errors.append(area + ':' + ref + ': unsupported grade')
        n = len(d['records'])
        rows.append({'area': area, 'footprints': n, 'accepted': accepted, 'null': n-accepted,
                     'coverageFraction': accepted/n if n else None, 'grades': dict(grades),
                     'heightRangeM': [min(values),max(values)] if values else None,
                     'missingReasons': dict(missing), 'surveyCollected': src['collected'],
                     'heightSHA256': O.sha(root/'building-heights.json')})
    if methods and any(m != methods[0] for m in methods[1:]):
        errors.append('Measurement methods differ between areas')
    return {'format':'worldengine-height-comparison/1', 'identicalMethods': len(set(json.dumps(m,sort_keys=True) for m in methods)) <= 1,
            'qualityNote':'Coverage is accepted measurement support, not independently verified accuracy. Uncalibrated grades remain D. Missing footprints outside OSM are not counted.',
            'areas':rows, 'errors':errors, 'status':'FAIL' if errors else 'PASS_WITH_GAPS' if any(r['null'] for r in rows) else 'PASS'}


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--areas', nargs='+', required=True);ap.add_argument('--output',required=True)
    args=ap.parse_args();result=compare(args.areas)
    Path(args.output).parent.mkdir(parents=True,exist_ok=True)
    Path(args.output).write_text(json.dumps(result,indent=2,sort_keys=True,allow_nan=False)+'\n')
    print(json.dumps(result));raise SystemExit(bool(result['errors']))
