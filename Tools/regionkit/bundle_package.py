#!/usr/bin/env python3
"""Bundle validated source inputs and existing standard/adaptive package schemas."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bundle(area, world, adaptive, qa, adaptive_qa, output):
    if shutil.disk_usage(output.parent).free < 8_000_000_000:
        raise RuntimeError('Disk guard: below 8 GB')
    archive = output.with_suffix('.zip')
    if output.exists() or archive.exists():
        raise ValueError('Choose a new bundle destination')
    report = json.loads(qa.read_text())
    packed_report = json.loads(adaptive_qa.read_text())
    assert report['status'] == packed_report['status'] == 'PASS'
    assert report['worldSHA256'] == packed_report['sourceWorldSHA256'] == sha(world / 'world.json')
    assert packed_report['packedWorldSHA256'] == sha(adaptive / 'world.json')
    assert report['sourceManifestSHA256'] == sha(area / 'manifest.json')
    manifest = json.loads((area / 'manifest.json').read_text())
    assert manifest['id'] == report['area'] == packed_report['area']
    for root in (world, adaptive):
        for name, entry in json.loads((root / 'world.json').read_text())['files'].items():
            assert sha(root / name) == entry['sha256'] and (root / name).stat().st_size == entry['bytes']
    source_files = {'manifest.json', 'NOTICE.md'}
    for source in manifest['sources']:
        path = area / source['path']
        assert path.resolve().is_relative_to(area.resolve())
        assert sha(path) == source['sha256'] and path.stat().st_size == source['bytes']
        source_files.add(source['path'])
    source_files.update(str(p.relative_to(area)) for p in area.glob('*.overpassql'))
    output.mkdir()
    (output / 'area').mkdir()
    for name in sorted(source_files):
        target = output / 'area' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(area / name, target)
    shutil.copytree(world, output / 'world')
    shutil.copytree(adaptive, output / 'adaptive')
    shutil.copy2(qa, output / 'coverage-qa.json')
    shutil.copy2(adaptive_qa, output / 'adaptive-qa.json')
    (output / 'README.md').write_text('''# Internal extended-area package\n\n`area/manifest.json` and its declared sources are the native input. `world/world.json` keeps worldengine.package/1; `adaptive/world.json` additionally requires adaptive-budget-bvh/1 support. Use the package frame origin for cameras. LOD0/LOD1 are available; consumer streaming is not implemented by this bundle. Source observations absent from the receipt remain gaps, not inferred survey coverage. No extra observation sidecars are copied implicitly.\n\nKeep area/NOTICE.md, world/LICENSE-DATA.md and adaptive/LICENSE-DATA.md with their contents. © OpenStreetMap contributors. The exact source snapshots are included. The existing public ODbL offer status is recorded in each world.json; this internal handoff does not clear an external release.\n''')
    files = {str(p.relative_to(output)): {'bytes': p.stat().st_size, 'sha256': sha(p)}
             for p in sorted(output.rglob('*')) if p.is_file()}
    index = {'format': 'worldengine-source-package-bundle/1', 'area': manifest['id'], 'files': files}
    (output / 'bundle.json').write_text(json.dumps(index, indent=2, sort_keys=True)+'\n')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in sorted(output.rglob('*')):
            if not path.is_file():
                continue
            info = zipfile.ZipInfo(str(path.relative_to(output)), date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        for name, entry in files.items():
            assert hashlib.sha256(z.read(name)).hexdigest() == entry['sha256']
    result = {'area': manifest['id'], 'files': len(files)+1, 'uncompressedBytes': sum(p.stat().st_size for p in output.rglob('*') if p.is_file()),
              'archiveBytes': archive.stat().st_size, 'archiveSHA256': sha(archive), 'bundleIndexSHA256': sha(output / 'bundle.json'),
              'zipCRCAndPayloadHashesVerified': True}
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('area', 'world', 'adaptive', 'qa', 'adaptive-qa', 'output'):
        p.add_argument('--'+name, type=Path, required=True)
    a = p.parse_args()
    bundle(a.area, a.world, a.adaptive, a.qa, a.adaptive_qa, a.output)
