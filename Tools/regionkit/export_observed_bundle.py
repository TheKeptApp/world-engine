#!/usr/bin/env python3
"""Bundle the existing web export with separate, GREEN observed-data sidecars.

No generator changes and no inferred fallback ladder values. Rendering consumers
must explicitly opt into the observations in a later owner-approved change.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE / 'lidar'))
import observed_heights as O


def bundle(area, output, date, binary):
    O.require_heavy_lock()
    O.disk_guard(REPO)
    root = REPO / 'Data/areas' / area
    heights = json.loads((root / 'building-heights.json').read_text())
    roofs = json.loads((root / 'building-roofs.json').read_text())
    qa = json.loads((root / 'observed-qa.json').read_text())
    terrain = json.loads((root / 'elevation/metadata.json').read_text())
    terrain_qa = json.loads((root / 'elevation/qa.json').read_text())
    for source in [heights['source'], roofs['source'], terrain]:
        if source.get('licenseStatus') != 'GREEN':
            raise ValueError('Only GREEN observations may be bundled')
    if qa['status'] not in ('PASS', 'PASS_WITH_GAPS') or terrain_qa['status'] not in ('PASS', 'PASS_WITH_GAPS'):
        raise ValueError('Observed-data QA must pass before export')
    if qa['heightSHA256'] != O.sha(root / 'building-heights.json') or qa['roofSHA256'] != O.sha(root / 'building-roofs.json'):
        raise ValueError('Stale building QA')
    if terrain_qa['metadataSHA256'] != O.sha(root / 'elevation/metadata.json'):
        raise ValueError('Stale terrain QA')
    if heights['footprints']['sha256'] != O.sha(root / 'osm.json') or roofs['heightSidecarSHA256'] != O.sha(root / 'building-heights.json'):
        raise ValueError('Stale building provenance')
    for item in terrain['nativeClips'] + terrain['bands']:
        if O.sha(root / 'elevation' / item['file']) != item['sha256']:
            raise ValueError('Terrain payload digest mismatch')
    output = Path(output).resolve()
    if output.exists():
        raise ValueError('Output already exists; choose a fresh bundle directory')
    output.mkdir(parents=True)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    subprocess.run([str(Path(binary).resolve()), 'export', str(root), str(output / 'world'),
                    '--date', date, '--version', revision], cwd=REPO, check=True)
    obs = output / 'observations'
    obs.mkdir()
    for filename in ['manifest.json', 'building-heights.json', 'building-roofs.json', 'observed-qa.json']:
        shutil.copy2(root / filename, obs / filename)
    shutil.copytree(root / 'elevation', obs / 'elevation')
    # Raw OSM is retained as the footprint source for rebuilding the sidecar joins.
    shutil.copy2(root / 'osm.json', obs / 'osm.json')
    index = {'format': 'worldengine-observed-web-bundle/1', 'area': area,
             'webPackage': 'world/world.json', 'sourceRevision': revision, 'exportDate': date,
             'observationsAppliedToMesh': False, 'newFallbackLadderApplied': False,
             'quality': 'Grade D; no independent accuracy calibration. Observed nulls preserved.',
             'consumerHandoff': 'P2: building heights/roofs; 5A: native 1 m NAVD88 and distance bands.',
             'files': {str(p.relative_to(output)): {'sha256': O.sha(p), 'bytes': p.stat().st_size}
                       for p in sorted(output.rglob('*')) if p.is_file()}}
    (output / 'bundle.json').write_text(json.dumps(index, indent=2) + '\n')
    (output / 'README.md').write_text('''# Observed data and web package\n\nOpen world/world.json with the existing WorldEngine web viewer. The observations directory is a separate data handoff: the current generator does not consume these lidar heights, roof forms or native terrain. The mesh uses existing generator rules; no new fallback ladder has been applied. Missing observed values remain null. Roof forms are inferred classifications; all height/roof grades are D, uncalibrated. Acquisition dates are in source metadata; these are not live observations.\n\n© OpenStreetMap contributors. OSM footprints and their enhanced building sidecars remain under ODbL-1.0 (https://opendatacommons.org/licenses/odbl/1-0/); raw footprint source is included. USGS 3DEP lidar and elevation are US Government public-domain data. Preserve the full world/LICENSE-DATA.md and source metadata when redistributing.\n''')
    print(json.dumps({'bundle': str(output), 'area': area, 'files': len(index['files']), 'observationsAppliedToMesh': False}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--area', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--date', required=True)
    parser.add_argument('--binary', default=str(REPO / '.build/debug/worldbake'))
    args = parser.parse_args()
    bundle(args.area, args.output, args.date, args.binary)
