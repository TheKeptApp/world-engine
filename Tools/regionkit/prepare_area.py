#!/usr/bin/env python3
"""Fetch a bounded OSM area from explicitly authorized rectangle configuration."""
import argparse
import datetime
import hashlib
import json
import math
import re
from pathlib import Path
import shutil
import ssl
import urllib.parse
import urllib.request

REPO = Path(__file__).resolve().parents[2]


def prepare(config, area, endpoint):
    if shutil.disk_usage(REPO).free < 8_000_000_000:
        raise RuntimeError('Disk guard: below 8 GB')
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', area):
        raise ValueError('Invalid area identifier')
    cfg = json.loads(Path(config).read_text())
    row = next(a for a in cfg['areas'] if a['id'] == area)
    if row.get('processingStatus') != 'AUTHORIZED':
        raise ValueError('Area is not authorized for processing')
    target = REPO / 'Data/areas' / area
    if target.exists():
        raise ValueError('Refusing to replace an existing area')
    b = row['bounds']; lat = (b['north'] + b['south']) / 2; lon = (b['west'] + b['east']) / 2
    # WGS84 meridional/prime-vertical radii at rectangle centre.
    a, e2 = 6378137., 0.0066943799901413165
    q = 1 - e2 * math.sin(math.radians(lat)) ** 2
    north = math.pi / 180 * a * (1-e2) / q ** 1.5
    east = math.pi / 180 * a / math.sqrt(q) * math.cos(math.radians(lat))
    halo = cfg['processingBufferMeters']
    bounds = {'south': b['south']-halo/north, 'north': b['north']+halo/north,
              'west': b['west']-halo/east, 'east': b['east']+halo/east}
    bbox = ','.join(str(bounds[k]) for k in ('south', 'west', 'north', 'east'))
    query = f'[out:json][timeout:180][maxsize:33554432];(nwr({bbox}););out body;>;out skel qt;'
    req = urllib.request.Request(endpoint, data=urllib.parse.urlencode({'data': query}).encode(),
                                 headers={'User-Agent': 'WorldEngine-regionkit/1'})
    try:
        import certifi
        ctx = ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=240) as r:
        body = r.read(33_554_433)
    if len(body) > 33_554_432:
        raise RuntimeError('OSM response exceeds bounded request')
    data = json.loads(body)
    if data.get('remark') or not data.get('elements'):
        raise RuntimeError('Incomplete or empty OSM response')
    stamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    man = {'formatVersion': 1, 'id': area, 'name': row['name'], 'center': {'latitude': lat, 'longitude': lon},
           'widthMeters': (b['east']-b['west'])*east, 'heightMeters': (b['north']-b['south'])*north,
           'approvedBounds': b, 'processingBufferMeters': halo,
           'sources': [{'path': 'osm.json', 'format': 'osm-overpass-json', 'layers': ['all'],
                        'bounds': bounds, 'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest(),
                        'license': 'ODbL-1.0', 'attribution': '© OpenStreetMap contributors',
                        'dataTimestamp': data.get('osm3s', {}).get('timestamp_osm_base'), 'fetchedAt': stamp}]}
    target.mkdir(parents=True)
    (target / 'osm.json').write_bytes(body)
    (target / 'manifest.json').write_text(json.dumps(man, indent=2) + '\n')
    print(json.dumps({'area': area, 'elements': len(data['elements']), 'bytes': len(body)}))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--config', required=True); ap.add_argument('--area', required=True)
    ap.add_argument('--endpoint', default='https://overpass-api.de/api/interpreter')
    args = ap.parse_args(); prepare(args.config, args.area, args.endpoint)
