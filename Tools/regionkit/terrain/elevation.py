#!/usr/bin/env python3
"""Native elevation clips plus distance-banded terrain with preserved min/max envelopes."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import ssl
import time
import urllib.parse
import urllib.request

import certifi
import numpy as np
import rasterio
from rasterio.warp import transform, transform_bounds, reproject, Resampling
from rasterio.windows import from_bounds, Window
from rasterio.transform import from_origin

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
NODATA = -9999.


def guard():
    if shutil.disk_usage(REPO).free < 8_000_000_000:
        raise RuntimeError('Disk guard: below 8 GB')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def catalogue(dataset, bounds, work):
    query = urllib.parse.urlencode({'datasets': dataset, 'bbox': ','.join(map(str, bounds)), 'max': 1000, 'outputFormat': 'JSON'})
    url = 'https://tnmaccess.nationalmap.gov/api/v1/products?' + query
    path = work / (hashlib.sha256(query.encode()).hexdigest() + '.json')
    d = json.loads(path.read_text()) if path.exists() else None
    if not isinstance(d, dict) or not isinstance(d.get('items'), list) or d.get('error'):
        for attempt in range(4):
            guard()
            try:
                with urllib.request.urlopen(url, context=ssl.create_default_context(cafile=certifi.where()), timeout=60) as r:
                    d = json.loads(r.read())
                if not isinstance(d.get('items'), list) or d.get('error'):
                    raise ValueError('Catalogue returned an error or incomplete response')
                path.write_text(json.dumps(d))
                break
            except urllib.error.HTTPError as e:
                if e.code not in (408,429,500,502,503,504) or attempt == 3: raise
            except (ValueError, urllib.error.URLError):
                if attempt == 3: raise
            time.sleep(2 + 4 * attempt)
    if d.get('total', 0) > len(d.get('items', [])):
        raise RuntimeError('Catalogue pagination required; refusing incomplete catalogue')
    return d['items']


def latest_tiles(items):
    selected = {}
    for item in items:
        match = re.search(r'(n\d+w\d+)', item['downloadURL'])
        if not match:
            continue
        tile = match.group(1)
        if tile not in selected or (item.get('publicationDate', ''), item['downloadURL']) > (selected[tile].get('publicationDate', ''), selected[tile]['downloadURL']):
            selected[tile] = item
    return [selected[k] for k in sorted(selected)]


def source_info(item, ds):
    return {'url': item['downloadURL'], 'title': item['title'], 'publicationDate': item.get('publicationDate'),
            'acquisitionDate': None, 'metadataURL': item.get('metaUrl'),
            'horizontalCRS': str(ds.crs), 'nativePixelSize': list(ds.res),
            'nativePixelUnits': 'degree' if ds.crs.is_geographic else 'metre',
            'verticalDatum': 'NAVD88', 'verticalUnits': 'metre'}


def clipped_window(ds, bounds):
    a, b, c, d = bounds
    a, b, c, d = max(a, ds.bounds.left), max(b, ds.bounds.bottom), min(c, ds.bounds.right), min(d, ds.bounds.top)
    if a >= c or b >= d:
        return None
    w = from_bounds(a, b, c, d, ds.transform)
    x0, y0 = max(0, math.floor(w.col_off)), max(0, math.floor(w.row_off))
    x1, y1 = min(ds.width, math.ceil(w.col_off + w.width)), min(ds.height, math.ceil(w.row_off + w.height))
    return Window(x0, y0, x1 - x0, y1 - y0)


def read_native(ds, window, control):
    guard()
    if window.width * window.height * 4 > control['maximumNativeReadBytes']:
        raise RuntimeError('Native read exceeds memory bound')
    return ds.read(1, window=window, masked=True).astype('float32').filled(NODATA)


def grid_spec(cx, cy, radius, step):
    size = math.ceil(2 * radius / step)
    return (size, size), from_origin(cx - radius, cy + radius, step, step)


def band_mask(shape, affine, cx, cy, inner, outer):
    x = affine.c + (np.arange(shape[1]) + .5) * affine.a - cx
    y = affine.f + (np.arange(shape[0]) + .5) * affine.e - cy
    r2 = y[:, None] ** 2 + x[None, :] ** 2
    return (r2 >= inner ** 2) & (r2 < outer ** 2)


def run(args):
    guard()
    control = json.loads(Path(args.config).read_text())
    area = args.area or control['defaultArea']
    if area not in control['authorizedAreas'] or control['licenseStatus'] != 'GREEN':
        raise ValueError('Authorized area and GREEN licence required')
    man = json.loads((REPO / 'Data/areas' / area / 'manifest.json').read_text())
    lat, lon = man['center']['latitude'], man['center']['longitude']
    # NAD83 UTM for this CONUS source family. Other territories need their own verified datum configuration.
    crs = f'EPSG:{26900 + int((lon + 180) // 6) + 1}'
    cx, cy = [p[0] for p in transform('EPSG:4326', crs, [lon], [lat])]
    work = Path(args.work); work.mkdir(parents=True, exist_ok=True)
    output = REPO / 'Data/areas' / area / 'elevation'; output.mkdir(exist_ok=True)
    meta = {'format': 'worldengine-elevation/1', 'area': area, 'horizontalCRS': crs,
            'verticalDatum': control['verticalDatum'], 'verticalCRS': control['verticalCRS'],
            'verticalUnits': 'metre', 'license': control['license'], 'licenseStatus': 'GREEN',
            'sourceEvidence': control['sourceEvidence'], 'checkedOn': control['checkedOn'],
            'ellipsoidTransformApplied': False, 'geoidModel': None, 'nodata': NODATA,
            'policy': control['distancePolicy'], 'nativeProject': control['nativeProjects'][area],
            'nativeBufferMeters': control['nativeBufferMeters'], 'maximumDistanceM': control['maximumDistanceM'],
            'nativeClips': [], 'bands': [],
            'limitations': 'Orthometric elevations, not WGS84 ellipsoid heights. Publication dates are not acquisition dates. No current-survey or positional-accuracy claim; source-native ridge maxima are retained per output cell. No shoreline/road flattening or renderer changes.'}
    width, height = man['widthMeters'] + 2 * control['nativeBufferMeters'], man['heightMeters'] + 2 * control['nativeBufferMeters']
    bounds = (cx-width/2, cy-height/2, cx+width/2, cy+height/2)
    geo = transform_bounds(crs, 'EPSG:4326', *bounds)
    items = [i for i in catalogue('Digital Elevation Model (DEM) 1 meter', geo, work) if control['nativeProjects'][area] in i['downloadURL']]
    if not items:
        raise RuntimeError('No matching native 1 m tiles')
    for i, item in enumerate(items):
        with rasterio.open('/vsicurl/' + item['downloadURL']) as ds:
            if ds.crs.linear_units not in ('metre', 'meter') or any(abs(v-1) > 1e-6 for v in ds.res):
                raise ValueError('Source is not native 1 m')
            window = clipped_window(ds, transform_bounds(crs, ds.crs, *bounds))
            if window is None: continue
            a = read_native(ds, window, control)
            path = output / f'native-1m-{i}.tif'
            with rasterio.open(path, 'w', driver='GTiff', width=a.shape[1], height=a.shape[0], count=1,
                               dtype='float32', crs=ds.crs, transform=ds.window_transform(window), nodata=NODATA,
                               compress='deflate', predictor=3, tiled=True) as dest:
                dest.write(a, 1); dest.set_band_unit(1, 'metre'); dest.update_tags(vertical_datum='NAVD88')
            valid = a != NODATA
            meta['nativeClips'].append({**source_info(item, ds), 'file': path.name, 'sha256': digest(path),
                                       'shape': list(a.shape), 'transform': list(ds.window_transform(window)),
                                       'validFraction': float(valid.mean()), 'resampling': 'none'})
    policy = json.loads((REPO / control['distancePolicy'].split('#')[0]).read_text())['demByDistance']
    for band in policy[1:]:
        inner, outer = band['rangeM']; outer = min(outer, control['maximumDistanceM'])
        if inner >= outer: continue
        step = band['meshSampleGuideM']
        shape, affine = grid_spec(cx, cy, outer, step)
        mask = band_mask(shape, affine, cx, cy, inner, outer)
        mean = np.full(shape, NODATA, dtype='float32')
        upper, lower = mean.copy(), mean.copy()
        bounds = (cx-outer, cy-outer, cx+outer, cy+outer)
        geo = transform_bounds(crs, 'EPSG:4326', *bounds)
        dataset = 'National Elevation Dataset (NED) ' + ('1/3 arc-second' if outer <= 2000 else '1 arc-second')
        items = latest_tiles(catalogue(dataset, geo, work))
        sources = []
        for item in items:
            with rasterio.open('/vsicurl/' + item['downloadURL']) as ds:
                window = clipped_window(ds, transform_bounds(crs, ds.crs, *bounds))
                if window is None: continue
                a = read_native(ds, window, control)
                options = dict(src_transform=ds.window_transform(window), src_crs=ds.crs, src_nodata=NODATA,
                               dst_transform=affine, dst_crs=crs, dst_nodata=NODATA, num_threads=1)
                # Nearest sample is the surface; extrema envelopes preserve sharp source ridges/valleys separately.
                temp = np.full(shape, NODATA, dtype='float32')
                reproject(a, temp, resampling=Resampling.nearest, **options)
                valid = (temp != NODATA) & mask; mean[valid] = temp[valid]
                for dest, method, fn in [(upper, Resampling.max, np.maximum), (lower, Resampling.min, np.minimum)]:
                    temp.fill(NODATA); reproject(a, temp, resampling=method, **options)
                    valid = (temp != NODATA) & mask
                    empty = valid & (dest == NODATA); dest[empty] = temp[empty]
                    both = valid & ~empty; dest[both] = fn(dest[both], temp[both])
                sources.append(source_info(item, ds))
        path = output / f'band-{inner}-{outer}m.npz'
        guard(); np.savez_compressed(path, elevation_m=mean, minimum_m=lower, maximum_m=upper)
        valid = mask & (mean != NODATA)
        entry = {'file': path.name, 'sha256': digest(path), 'rangeM': [inner, outer], 'sampleSpacingM': step,
                 'shape': list(shape), 'transform': list(affine), 'sources': sources,
                 'resampling': 'nearest native elevation; min/max aggregated from full native pixels (no overview)',
                 'coveredCells': int(valid.sum()), 'requestedCells': int(mask.sum()),
                 'validFraction': float(valid.sum()/mask.sum()),
                 'minElevationM': float(mean[valid].min()) if valid.any() else None,
                 'maxElevationM': float(upper[valid].max()) if valid.any() else None}
        meta['bands'].append(entry)
        print(json.dumps({k:entry[k] for k in ['rangeM','validFraction','maxElevationM']}), flush=True)
        (output/'metadata.json').write_text(json.dumps(meta, indent=2, allow_nan=False)+'\n')
    if not meta['bands']: raise RuntimeError('No terrain bands')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--area'); ap.add_argument('--config', default=str(HERE/'data/elevation.json'))
    ap.add_argument('--work', required=True); args = ap.parse_args()
    os.environ['CURL_CA_BUNDLE'] = certifi.where()
    with rasterio.Env(GDAL_DISABLE_READDIR_ON_OPEN='EMPTY_DIR', GDAL_HTTP_TIMEOUT='45', GDAL_HTTP_MAX_RETRY='2', GDAL_CACHEMAX=64*1024*1024):
        run(args)
