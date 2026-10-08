#!/usr/bin/env python3
"""Survey-backed building height sidecar. Run verification under scripts/heavy.sh; bounded data work may run separately.

Uses the existing terrain source registry and full-density EPT fetcher. No renderer
changes or height imputation. Raw points stay in the caller's external scratch.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
from types import SimpleNamespace

import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / 'terrain'))
import heights as H
import lidar as L
import roofplanes as RP
import slope as S

VERSION = 'worldengine-observed-heights/1'


def disk_guard(path):
    if shutil.disk_usage(path).free < 8_000_000_000:
        raise RuntimeError('Disk guard: less than 8 GB free; no data work allowed')


def require_heavy_lock():
    owner = Path.home() / '.agent-heavy-lock' / 'owner'
    text = owner.read_text() if owner.exists() else ''
    match = re.search(r'(?im)^pid\s*[=:]\s*(\d+)', text)
    if not match or int(match.group(1)) != os.getppid():
        raise RuntimeError('Run directly under scripts/heavy.sh with a live owned lock')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def grade_for(p90=None, validation_n=0, qa_passed=False):
    """No numerical accuracy claim without independent validation and local QA."""
    if not qa_passed or validation_n <= 0 or p90 is None or not math.isfinite(p90) or p90 < 0:
        return 'D'
    return 'A' if p90 <= 1 else 'B' if p90 <= 3 else 'C' if p90 <= 5 else 'D'


def record_for(poly, roof, ground, prm):
    """Same-survey class-6 roof and class-2 ground, local XY and absolute Z metres."""
    base, gn, mode = H.ground_level(ground, poly, prm['groundRing'])
    m = H.measure(poly, roof, ground, prm, fallback_ground=None)
    accepted = m['status'] == 'ok' and base is not None and math.isfinite(m.get('top', float('nan'))) and m['top'] > 0
    flags = ['height_error_uncalibrated', 'survey_footprint_change_not_independently_checked']
    if not accepted:
        flags.append(m['status'] if m['status'] != 'ok' else 'nonpositive_or_invalid_height')
    if mode == 'wide':
        flags.append('wide_ground_ring')
    return {
        'roof_top_agl_m': round(m['top'], 3) if accepted else None,
        'roof_typical_agl_m': round(m['p50'], 3) if accepted else None,
        'eave_agl_m': round(m['eave'], 3) if accepted and m.get('eave') is not None else None,
        'base_elevation_m': round(base, 3) if base is not None else None,
        'height_statistic': 'p95', 'height_reference': 'surrounding_ground_ring_median',
        'evidence_code': 'measured_derived_lidar' if accepted else 'missing',
        'quality_grade': grade_for(),
        'quality_reason': 'No independent local height-error calibration' if accepted else 'Measurement rejected: ' + m['status'],
        'interval90_m': None, 'calibration_group': None,
        'qa': {'status': m['status'], 'roof_point_count': m.get('points', 0),
               'valid_roof_fraction': m.get('cover'), 'ground_point_count': gn,
               'ground_mode': mode, 'footprint_m2': round(poly.area, 3), 'flags': flags},
    }


def planar_candidates(poly, points, ground, prm, settings):
    """Conservative roof candidates from unclassified returns; not vendor roof labels."""
    import shapely
    base, _, _ = H.ground_level(ground, poly, prm['groundRing'])
    if base is None or len(points) < prm['minBuildingPoints']:
        return points[:0], {'status': 'no_ground_or_too_few_points', 'planarPointShare': None}
    eroded = poly.buffer(-prm['footprintErosion'])
    if eroded.is_empty:
        return points[:0], {'status': 'eroded', 'planarPointShare': None}
    take = shapely.contains_xy(eroded, points[:, 0], points[:, 1]) & (points[:, 2] - base >= prm['minHeightAboveGround'])
    P = points[take]
    if len(P) < prm['minBuildingPoints']:
        return P[:0], {'status': 'few_elevated_points', 'planarPointShare': None}
    parameters = L.load('params.json')
    normals, variation = RP.point_normals(P, parameters['normals']['k'])
    labels = RP.region_grow(P, normals, variation, parameters['regionGrow'])
    kept = np.zeros(len(P), dtype=bool)
    for label in np.unique(labels[labels >= 0]):
        mask = labels == label
        normal, _, _ = RP.fit_plane(P[mask])
        pitch, _ = RP.pitch_aspect(normal)
        if pitch <= settings['maximumPitchDeg']:
            kept |= mask
    share = float(kept.mean())
    if share < settings['minimumPlanarPointShare']:
        return P[:0], {'status': 'insufficient_planar_support', 'planarPointShare': round(share, 3)}
    return P[kept], {'status': 'planar_candidates', 'planarPointShare': round(share, 3)}


def read_points(work, area, man, margin):
    import laspy
    pts = {1: [], 2: [], 6: []}
    classes = Counter()
    for path in sorted(Path(work.p('laz', area)).glob('*.laz')):
        disk_guard(work.root)
        las = laspy.read(path)
        lon, lat = RP.merc_to_lonlat(np.asarray(las.x), np.asarray(las.y))
        x, y = RP.local_en(man['center']['latitude'], man['center']['longitude'], lat, lon)
        valid = (abs(x) <= man['widthMeters'] / 2 + margin) & (abs(y) <= man['heightMeters'] / 2 + margin)
        cls = np.asarray(las.classification)
        for c, n in zip(*np.unique(cls[valid], return_counts=True)):
            classes[int(c)] += int(n)
        for c in pts:
            take = valid & (cls == c)
            pts[c].append(np.column_stack((x[take], y[take], np.asarray(las.z)[take])))
    return {c: np.concatenate(v) if v else np.empty((0, 3)) for c, v in pts.items()}, dict(classes)


def run(args):
    disk_guard(REPO)
    if args.verify or args.command == 'verify':
        require_heavy_lock()
        import unittest
        suite = unittest.defaultTestLoader.discover(str(HERE / 'tests'))
        if not unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful():
            raise RuntimeError('Lidar regression suite failed; no extraction performed')
    if args.command == 'verify':
        return
    control = json.loads(Path(args.config).read_text())
    args.area = args.area or control['defaultArea']
    cfg = json.loads((HERE.parent / 'terrain/data/areas.json').read_text())
    cfg['marginMeters'] = control['marginMeters']
    cfg['maxBytesPerArea'] = control['maxBytesPerArea']
    if args.area not in control['authorizedAreas']:
        raise ValueError('Area is not authorized for processing in the selected configuration')
    cfg['areas'] = [a for a in cfg['areas'] if a['id'] == args.area]
    work = S.Work(args.work)
    disk_guard(work.root)
    original_http = S.http
    def guarded_http(*a, **kw):
        disk_guard(work.root)
        return original_http(*a, **kw)
    S.http = guarded_http
    man, src, *_ = S.area_ctx(cfg, args.area)
    provenance = control['sources'][src['id']]
    if provenance['licenseStatus'] != 'GREEN' or provenance['verticalUnits'] != 'metre':
        raise ValueError('Verified GREEN licence and metre vertical units required')
    prm = H.load_params()
    if args.command in ('fetch', 'all'):
        fetch_args = SimpleNamespace(areas=[args.area], allow_partial=False)
        S.cmd_plan(fetch_args, work, cfg)
        disk_guard(work.root)
        S.cmd_fetch(fetch_args, work, cfg)
    if args.command == 'fetch':
        return
    plan = json.loads(Path(work.p('plan', args.area + '.json')).read_text())
    if not plan['fullDensity']:
        raise ValueError('Full-density survey required')
    ept, nodes = S.hierarchy(src, work, args.area, S.area_ctx(cfg, args.area)[-1])
    if str(ept['srs'].get('horizontal')) != '3857':
        raise ValueError('Expected documented EPSG:3857 EPT horizontal frame')
    for key in nodes:
        if not Path(work.p('laz', args.area, key + '.laz')).is_file():
            raise ValueError('Incomplete survey download: ' + key)
    pts, counts = read_points(work, args.area, man, cfg['marginMeters'])
    if not len(pts[2]):
        raise ValueError('No same-survey ground points; refusing heights')
    inferred_roof_class = not len(pts[6]) and control['unclassifiedRoof']['enabled']
    roof_class = 1 if inferred_roof_class else 6
    ground_index = L.PointIndex(pts[2])
    roof_index = L.PointIndex(pts[roof_class]) if len(pts[roof_class]) else None
    fps, stamp = L.footprints({'area': 'Data/areas/' + args.area}, man)
    records = {}
    for ref, fp in sorted(fps.items()):
        p = fp['poly']; c = p.centroid
        if abs(c.x) > man['widthMeters'] / 2 or abs(c.y) > man['heightMeters'] / 2:
            continue
        if p.is_empty or not p.is_valid:
            raise ValueError('Invalid footprint: ' + ref)
        g = pts[2][ground_index.query(p.buffer(prm['groundRing']['wideOuterM']).bounds)]
        r = pts[roof_class][roof_index.query(p.bounds)] if roof_index else np.empty((0, 3))
        diagnostics = {'status': 'vendor_building_class', 'planarPointShare': None}
        if inferred_roof_class:
            r, diagnostics = planar_candidates(p, r, g, prm, control['unclassifiedRoof'])
        records[ref] = record_for(p, r, g, prm)
        records[ref]['roof_point_selection'] = 'derived_planar_unclassified' if inferred_roof_class else 'vendor_class_6'
        records[ref]['qa']['roof_selection'] = diagnostics
        if inferred_roof_class:
            records[ref]['qa']['flags'].append('roof_point_classification_unvalidated')
    out = {
        'format': VERSION, 'area': args.area,
        'source': {**src, **provenance, 'groundAndRoofSameSurvey': True, 'eptSRS': ept['srs'], 'fullDensity': True},
        'footprints': {'source': 'OpenStreetMap', 'timestamp': stamp,
                       'sha256': sha(REPO / 'Data/areas' / args.area / 'osm.json'),
                       'scope': 'Closed building ways and multipolygon buildings; building:part excluded',
                       'license': 'ODbL-1.0', 'attribution': '© OpenStreetMap contributors'},
        'outputBranch': 'ODbL-enhanced',
        'method': {'version': VERSION, 'parameters': {k: prm[k] for k in ('minFootprintM2', 'footprintErosion', 'groundRing', 'minHeightAboveGround', 'minBuildingPoints', 'cover', 'minRoofCover', 'noBuildingMaxCover', 'topPercentile', 'eaveBand')}, 'roofCandidateParameters': {k: L.load('params.json')[k] for k in ('normals', 'regionGrow')}, 'unclassifiedRoof': control['unclassifiedRoof'], 'heightDefinition': 'p95 selected roof Z (vendor class 6, or explicitly labelled planar class-1 candidates) minus median class-2 ground Z in 3–8 m ring, expanded to 15 m if needed; no unrelated DEM fallback',
                   'alignment': 'Source coordinates; no fitted footprint shift',
                   'limitations': 'Not current-building validation; acquisition dates are in source metadata. Roof classification, footprint age and ring-ground slope can bias heights. Per-record grade D until independently calibrated.'},
        'counts': {'footprints': len(records), 'evidence': dict(Counter(r['evidence_code'] for r in records.values())), 'pointClasses': counts},
        'records': records,
    }
    target = REPO / 'Data/areas' / args.area / 'building-heights.json'
    disk_guard(target.parent)
    target.write_text(json.dumps(out, indent=2, sort_keys=True, allow_nan=False) + '\n')
    print(json.dumps(out['counts']))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('command', choices=['fetch', 'measure', 'all', 'verify'])
    ap.add_argument('--area')
    ap.add_argument('--config', default=str(HERE / 'data/observed-heights.json'))
    ap.add_argument('--work', required=True)
    ap.add_argument('--verify', action='store_true', help='Run full lidar regression suite before processing')
    run(ap.parse_args())
