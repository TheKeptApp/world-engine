#!/usr/bin/env python3
"""Account for any exported area's cells, source closure and licensed provenance."""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import shutil
import struct


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def decoded_geometry(path):
    data = path.read_bytes()
    magic, version, size, length, kind = struct.unpack_from('<5I', data)
    assert (magic, version, size, kind) == (0x46546c67, 2, len(data), 0x4e4f534a)
    gltf = json.loads(data[20:20+length])
    scalar = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
    used = {i for mesh in gltf['meshes'] for primitive in mesh['primitives']
            for i in [primitive['indices'], *primitive['attributes'].values()]}
    return sum(gltf['accessors'][i]['count'] * scalar[gltf['accessors'][i]['componentType']]
               * width[gltf['accessors'][i]['type']] for i in used)


def receipt(area, package, extent):
    if shutil.disk_usage(package).free < 8_000_000_000:
        raise RuntimeError('Disk guard: below 8 GB')
    manifest = json.loads((area / 'manifest.json').read_text())
    world = json.loads((package / 'world.json').read_text())
    assert world['schema'] == 'worldengine.package/1'
    assert world['area']['id'] == manifest['id'] == extent['id']
    sources = []
    for source in manifest['sources']:
        path = area / source['path']
        assert sha(path) == source['sha256']
        assert path.stat().st_size == source['bytes']
        assert source.get('license') and source.get('attribution')
        sources.append({k: source.get(k) for k in ('path', 'bytes', 'sha256', 'bounds', 'license', 'dataTimestamp')})
    detailed = [s for s in manifest['sources'] if 'all' in s['layers']]
    b = extent['bounds']
    assert any(s['bounds']['south'] <= b['south'] and s['bounds']['west'] <= b['west']
               and s['bounds']['north'] >= b['north'] and s['bounds']['east'] >= b['east'] for s in detailed)
    for name, entry in world['files'].items():
        path = package / name
        assert path.stat().st_size == entry['bytes'] and sha(path) == entry['sha256'], name
    assert world['chunkSize'] == extent['cellMeters']
    nx = math.ceil(manifest['widthMeters'] / world['chunkSize'])
    ny = math.ceil(manifest['heightMeters'] / world['chunkSize'])
    assert [nx, ny] == extent['expectedGrid']
    assert len(world['chunks']) == nx * ny
    assert len({tuple(c['index']) for c in world['chunks']}) == nx * ny
    expected = {(x, y) for x in range(nx) for y in range(ny)}
    assert {tuple(c['index']) for c in world['chunks']} == expected
    lods = []
    for lod in range(2):
        sizes = sorted((package / c['lods'][lod]).stat().st_size for c in world['chunks'])
        decoded = [decoded_geometry(package / c['lods'][lod]) for c in world['chunks']]
        lods.append({'meanDecodedGeometryMBPerCell': sum(decoded) / len(decoded) / 1e6,
                     'maxDecodedGeometryMBPerCell': max(decoded) / 1e6, 'lod': lod, 'cells': len(sizes), 'bytes': sum(sizes),
                     'meanMBPerCell': sum(sizes) / len(sizes) / 1e6,
                     'medianMBPerCell': sizes[len(sizes)//2] / 1e6,
                     'maxMBPerCell': max(sizes) / 1e6,
                     'triangles': sum(c['triangles'][lod] for c in world['chunks'])})
    doc = json.loads((area / 'osm.json').read_text())
    assert not doc.get('remark')
    elements = {(e['type'], e['id']): e for e in doc['elements']}
    missing = [(e['id'], n) for e in elements.values() if e['type'] == 'way'
               for n in e['nodes'] if ('node', n) not in elements]
    assert not missing, 'Incomplete way recursion'
    water = []
    for e in elements.values():
        if e['type'] != 'relation' or e.get('tags', {}).get('natural') != 'water':
            continue
        ways = [elements.get(('way', m['ref'])) for m in e['members'] if m['type'] == 'way']
        endpoints = Counter(n for w in ways if w and w.get('nodes') for n in (w['nodes'][0], w['nodes'][-1]))
        water.append({'id': e['id'], 'name': e.get('tags', {}).get('name'),
                      'ways': len(ways), 'missingWays': sum(w is None for w in ways),
                      'unpairedEndpoints': sum(v % 2 for v in endpoints.values())})
    assert all(w['missingWays'] == 0 and w['unpairedEndpoints'] == 0 for w in water)
    return {'area': manifest['id'], 'status': 'PASS', 'scope': 'Package integrity and source closure; not real-world completeness or device performance',
            'worldSHA256': sha(package / 'world.json'), 'sourceManifestSHA256': sha(area / 'manifest.json'),
            'requestedBounds': extent['bounds'], 'widthMeters': manifest['widthMeters'], 'heightMeters': manifest['heightMeters'],
            'cells': nx * ny, 'grid': [nx, ny], 'detailCounts': dict(Counter(c['detail'] for c in world['chunks'])),
            'lods': lods, 'totalPackageBytes': sum(p.stat().st_size for p in package.rglob('*') if p.is_file()),
            'commonAndMetadataBytes': sum(p.stat().st_size for p in package.rglob('*') if p.is_file()) - sum(x['bytes'] for x in lods),
            'missingWayNodeReferences': len(missing), 'waterRelations': water, 'sources': sources,
            'heightRoofObservationSidecarsPresent': all((area / x).is_file() for x in ('building-heights.json', 'building-roofs.json')),
            'terrainPresent': (area / 'elevation/metadata.json').is_file(),
            'dataLicense': world['dataLicense']}


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--area', type=Path, required=True)
    ap.add_argument('--package', type=Path, required=True)
    ap.add_argument('--config', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    a = ap.parse_args()
    ext = next(x for x in json.loads(a.config.read_text())['areas'] if x['id'] == a.area.name)
    result = receipt(a.area, a.package, ext)
    a.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
