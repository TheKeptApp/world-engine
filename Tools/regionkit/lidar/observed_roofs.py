#!/usr/bin/env python3
"""Roof evidence sidecars from the same surveyed points as observed_heights."""
import argparse
from collections import Counter
import json
from pathlib import Path

import numpy as np
import shapely
import observed_heights as O

VERSION = 'worldengine-observed-roofs/1'


def classify(poly, points, height, params):
    out = {'type': None, 'pitch_deg': None, 'ridge_bearing_deg': None,
           'evidence_code': 'missing', 'quality_grade': 'D',
           'confidence': {'calibrated_probability': None, 'support_score': None,
                          'label': 'unvalidated'},
           'qa': {'reasons': [], 'plane_count': 0, 'coverage': None}}
    if height['evidence_code'] == 'missing':
        out['qa']['reasons'] = ['no_accepted_height']
        return out
    raster = O.L.roof_raster(poly, params)
    if raster is None:
        out['qa']['reasons'] = ['empty_eroded_footprint']
        return out
    eroded, _, gx, gy, inside = raster
    take = shapely.contains_xy(eroded, points[:, 0], points[:, 1])
    take &= points[:, 2] - height['base_elevation_m'] >= params['minHeightAboveGround']
    result, planes = O.RP.roof_from_points(points[take], gx, gy, inside, O.L.rect_of(eroded), params)
    out['qa'] = {'reasons': result.get('reasons', []), 'plane_count': len(planes),
                 'coverage': result.get('coverage'), 'classifier_form': result['form']}
    if result['form'] == 'unknown':
        return out
    form = {'complex': 'other'}.get(result['form'], result['form'])
    pitch = result.get('pitch')
    if form == 'flat':
        area = sum(p['area'] for p in planes)
        pitch = round(sum(p['pitch'] * p['area'] for p in planes) / area, 1) if area else None
    share = height['qa']['roof_selection']['planarPointShare']
    coverage = max(0., min(1., result.get('coverage', 0.)))
    out.update(type=form, pitch_deg=pitch,
               ridge_bearing_deg=result.get('ridge') if form in ('gable', 'hip') else None,
               evidence_code='measured_derived_lidar')
    out['confidence']['support_score'] = round(coverage * (share if share is not None else 1.), 3)
    return out


def run(args):
    O.disk_guard(O.REPO)
    control = json.loads(Path(args.config).read_text())
    area = args.area or control['defaultArea']
    if area not in control['authorizedAreas']:
        raise ValueError('Area not authorized')
    cfg = O.L.load(str(O.HERE.parent / 'terrain/data/areas.json'))
    man, src, *_ = O.S.area_ctx(cfg, area)
    work = O.S.Work(args.work)
    path = O.REPO / 'Data/areas' / area / 'building-heights.json'
    heights = json.loads(path.read_text())
    if heights['source']['id'] != src['id'] or not heights['source']['fullDensity']:
        raise ValueError('Expected same full-density survey as height sidecar')
    if heights['footprints']['sha256'] != O.sha(path.parent / 'osm.json'):
        raise ValueError('Footprints changed since height extraction')
    # Use exactly the cached acquisition and selected returns from the height run.
    plan = json.loads(Path(work.p('plan', area + '.json')).read_text())
    if not plan['fullDensity']:
        raise ValueError('Partial survey forbidden')
    _, nodes = O.S.hierarchy(src, work, area, O.S.area_ctx({**cfg, 'marginMeters': control['marginMeters']}, area)[-1])
    if any(not Path(work.p('laz', area, key + '.laz')).is_file() for key in nodes):
        raise ValueError('Incomplete survey cache')
    pts, _ = O.read_points(work, area, man, control['marginMeters'])
    indexes = {c: O.L.PointIndex(p) for c, p in pts.items() if len(p)}
    fps, _ = O.L.footprints({'area': 'Data/areas/' + area}, man)
    hp, rp = O.H.load_params(), O.L.load('params.json')
    records = {}
    for ref, height in heights['records'].items():
        poly = fps[ref]['poly']
        c = 1 if height['roof_point_selection'] == 'derived_planar_unclassified' else 6
        points = pts[c][indexes[c].query(poly.bounds)] if c in indexes else np.empty((0, 3))
        if height['evidence_code'] != 'missing' and c == 1:
            ground = pts[2][indexes[2].query(poly.buffer(hp['groundRing']['wideOuterM']).bounds)]
            points, _ = O.planar_candidates(poly, points, ground, hp, control['unclassifiedRoof'])
        records[ref] = classify(poly, points, height, rp)
    out = {'format': VERSION, 'area': area, 'source': heights['source'],
           'footprints': heights['footprints'], 'outputBranch': heights['outputBranch'],
           'heightSidecarSHA256': O.sha(path),
           'method': {'parameters': {k: rp[k] for k in ('footprintErosion', 'minHeightAboveGround', 'normals', 'regionGrow', 'cell', 'fillDist', 'classify')}, 'version': VERSION,
                      'parameterSource': 'Existing lidar pilot params.json / roofplanes.classify_roof v1',
                      'pitch': 'Area-weighted plane inclination in degrees from horizontal',
                      'ridge': 'Approximate principal-footprint-axis bearing inferred from facing roof planes, clockwise from true north, modulo 180; not a traced ridge segment',
                      'confidence': 'support_score = significant-plane coverage (clamped 0–1) times accepted planar-point share; uncalibrated support indicator, not probability',
                      'limitations': '2020 survey; current roof validation absent; unclassified returns may contain vegetation. Nulls are not flat roofs. Other is classifier complex. All quality grades D.'},
           'counts': dict(Counter(r['type'] or 'missing' for r in records.values())), 'records': records}
    O.disk_guard(path.parent)
    (path.parent / 'building-roofs.json').write_text(json.dumps(out, indent=2, sort_keys=True, allow_nan=False) + '\n')
    print(json.dumps(out['counts']))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--area')
    ap.add_argument('--config', default=str(O.HERE / 'data/observed-heights.json'))
    ap.add_argument('--work', required=True)
    run(ap.parse_args())
