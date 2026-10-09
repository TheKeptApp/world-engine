#!/usr/bin/env python3
"""Regenerate baseline/current road measurements; invoke directly through scripts/heavy.sh."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HARNESS = Path(__file__).with_name('RoadGuardMeasurement.swift')

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run(argv, cwd=ROOT):
    subprocess.run([str(x) for x in argv], cwd=cwd, check=True)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--baseline-ref', required=True)
    p.add_argument('--areas', nargs='+', required=True)
    p.add_argument('--date', required=True)
    p.add_argument('--season', type=int, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--diagnostics', type=Path, required=True)
    a = p.parse_args()
    owner = Path.home()/'.agent-heavy-lock/owner'
    if not owner.exists() or f'pid={os.getppid()}' not in owner.read_text().splitlines():
        raise SystemExit('Run directly through scripts/heavy.sh; active owned lock required')
    if shutil.disk_usage(ROOT).free < 8*1024**3:
        raise SystemExit('Disk guard: less than 8 GiB free')
    for area in a.areas:
        if Path(area).name != area or area in ('.','..'):
            raise SystemExit('Area must be a single directory name')
    baseline = subprocess.check_output(['git','rev-parse',a.baseline_ref+'^{commit}'],cwd=ROOT,text=True).strip()
    generated = ROOT/'Generated'; generated.mkdir(exist_ok=True)
    a.output.parent.mkdir(parents=True,exist_ok=True); a.diagnostics.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='road-guard-',dir=generated) as scratch:
        scratch = Path(scratch); snapshot = scratch/'baseline'; snapshot.mkdir()
        archive = subprocess.check_output(['git','archive',baseline,'Package.swift','Sources','Tests','Apps/WorldLab/Sources'],cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(snapshot,filter='data')
        results = []
        for name,source in [('before',snapshot),('after',ROOT)]:
            if shutil.disk_usage(ROOT).free < 8*1024**3:
                raise SystemExit('Disk guard: less than 8 GiB free')
            run(['swift','build','--jobs','2','--target','WorldGen'],cwd=source)
            binary_path = Path(subprocess.check_output(['swift','build','--show-bin-path'],cwd=source,text=True).strip())
            objects = sorted(p for m in ['WorldGeo','WorldMap','WorldMesh','WorldGen'] for p in (binary_path/(m+'.build')).glob('*.o'))
            executable = scratch/name; output = scratch/(name+'.json')
            run(['swiftc',*(['-D','GUARD'] if name=='after' else []),'-I',binary_path/'Modules',HARNESS,*objects,'-o',executable])
            run([executable,ROOT,output,a.diagnostics.resolve() if name=='after' else '-',a.date,a.season,*a.areas])
            results.append(json.loads(output.read_text()))
        rows = []
        for before,after in zip(*results):
            assert before['area']==after['area']
            rows.append({'area':before['area'],'before':before,'after':after,
                         'roadTriangleDelta':after['roadTriangles']-before['roadTriangles'],
                         'roadGraphUnchanged':before['graphSHA256']==after['graphSHA256'],
                         'meshBatchDelta':after['staticChunkBatches']-before['staticChunkBatches'],
                         'pedestrianTriangleDelta':after['pedestrianTriangles']-before['pedestrianTriangles'],
                         'pedestrianGraphUnchanged':before['pedestrianGraphSHA256']==after['pedestrianGraphSHA256'],
                         'waterUnchanged':before['waterSHA256']==after['waterSHA256']})
        hashes = {}
        for area in a.areas:
            directory = ROOT/'Data/areas'/area
            manifest = json.loads((directory/'manifest.json').read_text())
            for path in [directory/'manifest.json',*[directory/s['path'] for s in manifest['sources']]]:
                hashes[str(path.relative_to(ROOT))] = sha(path)
        source_files = ['Sources/WorldMap/MapFeatures.swift','Sources/WorldMap/MapFeatureBuilder.swift','Sources/WorldMap/UnsupportedFeatures.swift',
                        'Sources/WorldGen/SceneGenerator.swift','Sources/WorldGen/RoadMarkings.swift','Sources/WorldGen/WorldBuild.swift',
                        'Sources/WorldGen/Context/ContextFeatures.swift','Sources/worldbake/main.swift',
                        'Sources/WorldGen/ShoreBand.swift','Sources/WorldGen/Look.swift','Sources/WorldGen/Profiles/look.json','Sources/WorldEngine/Shaders/WorldShaders.metal',
                        'Tools/regionkit/qa/road_guard_measurement.py','Tools/regionkit/qa/RoadGuardMeasurement.swift']
        report = {'schema':'road-guard-measurement/2','baselineCommit':baseline,
                  'recipe':{'date':a.date,'season':a.season,'focus':'full manifest bounds','profile':'normal regional/zoned selection'},
                  'measurement':'Supplied areas only. Pedestrian ref/centerline JSON and water position/index/extra hashes included. Loaded road ref/centerline JSON hash; canonical static position/index v2 hash. Not full routing equivalence, materials, dynamic props or GPU draw calls.',
                  'areas':rows,'sourceHashes':hashes,'implementationHashes':{s:sha(ROOT/s) for s in source_files}}
        a.output.write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')

if __name__=='__main__':
    main()
