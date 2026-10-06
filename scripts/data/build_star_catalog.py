#!/usr/bin/env python3
"""Builds WorldEnvironment's 256-star catalog from HYG Database v4.1 (CC BY-SA 4.0).

    python3 scripts/data/build_star_catalog.py <hygdata_v41.csv> <out.json>

Rules (sky-seasons proposal §4): exclude the Sun and rows without coordinates or magnitude;
merge unresolved components within 2 arcminutes (connected groups, processed in stable catalog-ID
order) by combining fluxes, m = -2.5 log10(sum 10^(-0.4 m_i)), with the flux-weighted normalized
position and velocity; sort by magnitude, then catalog ID; keep the brightest 256. Deterministic:
same input bytes give the same output bytes.
"""
import csv, hashlib, json, math, sys
from collections import defaultdict

SRC, OUT = sys.argv[1], sys.argv[2]
MAG_LIMIT = 6.5           # candidates for merging; the 256th star is far brighter than this
MERGE_ARCMIN = 2.0
COUNT = 256

raw = open(SRC, 'rb').read()
sha256 = hashlib.sha256(raw).hexdigest()
blob = hashlib.sha1(b'blob %d\0' % len(raw) + raw).hexdigest()

def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

stars = []
for row in csv.DictReader(raw.decode('utf-8').splitlines()):
    sid = int(row['id'])
    if sid == 0 or row['proper'] == 'Sol':
        continue
    ra_h, dec, mag = f(row['ra']), f(row['dec']), f(row['mag'])
    if ra_h is None or dec is None or mag is None or mag > MAG_LIMIT:
        continue
    ra = math.radians(ra_h * 15); de = math.radians(dec)
    u = (math.cos(de) * math.cos(ra), math.cos(de) * math.sin(ra), math.sin(de))
    xyz = [f(row[k]) for k in ('x', 'y', 'z')]
    vel = [f(row[k]) for k in ('vx', 'vy', 'vz')]
    dist = f(row['dist'])
    stars.append(dict(id=sid, hip=row['hip'] or None, hr=row['hr'] or None, name=row['proper'] or None,
                      bayer=row['bayer'] or None, con=row['con'] or None, mag=mag, ci=f(row['ci']), u=u,
                      dist=dist if dist and dist < 100000 else None,
                      vel=vel if all(v is not None for v in vel) and dist and dist < 100000 else None))
stars.sort(key=lambda s: s['id'])

# Connected groups within 2' (cell hashing on the unit sphere).
lim = math.cos(math.radians(MERGE_ARCMIN / 60))
cell = math.radians(MERGE_ARCMIN / 60) * 2
grid = defaultdict(list)
def key(u):
    return tuple(int(math.floor(c / cell)) for c in u)
for i, s in enumerate(stars):
    grid[key(s['u'])].append(i)
parent = list(range(len(stars)))
def find(i):
    while parent[i] != i:
        parent[i] = parent[parent[i]]; i = parent[i]
    return i
for i, s in enumerate(stars):
    k = key(s['u'])
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for j in grid.get((k[0] + dx, k[1] + dy, k[2] + dz), []):
                    if j > i and sum(a * b for a, b in zip(s['u'], stars[j]['u'])) >= lim:
                        ri, rj = find(i), find(j)
                        if ri != rj:
                            parent[max(ri, rj)] = min(ri, rj)
groups = defaultdict(list)
for i in range(len(stars)):
    groups[find(i)].append(i)

merged = []
for root, members in groups.items():
    ms = sorted((stars[i] for i in members), key=lambda s: s['id'])
    fluxes = [10 ** (-0.4 * s['mag']) for s in ms]
    total = sum(fluxes)
    mag = -2.5 * math.log10(total)
    u = [sum(fl * s['u'][k] for fl, s in zip(fluxes, ms)) for k in range(3)]
    n = math.sqrt(sum(c * c for c in u)); u = [c / n for c in u]
    primary = min(ms, key=lambda s: (s['mag'], s['id']))
    named = next((s['name'] for s in sorted(ms, key=lambda s: (s['mag'], s['id'])) if s['name']), None)
    ci = primary['ci']
    vel = primary['vel']
    merged.append(dict(id=primary['id'], components=[s['id'] for s in ms], hip=primary['hip'], hr=primary['hr'], name=named,
                       bayer=primary['bayer'], con=primary['con'], mag=mag, ci=ci, u=u, dist=primary['dist'], vel=vel))

merged.sort(key=lambda s: (s['mag'], s['id']))
top = merged[:COUNT]

def rnd(x, n):
    return None if x is None else round(x, n)

out = {
    "schema": "worldengine.stars/1",
    "count": len(top),
    "epoch": "J2000.0", "equinox": "J2000.0",
    "frame": "unit direction vectors, equatorial J2000 (x toward RA 0h, z toward north celestial pole)",
    "source": {
        "name": "HYG Database v4.1", "author": "David Nash / Astronomy Nexus",
        "url": "https://github.com/astronexus/HYG-Database", "file": "hyg/CURRENT/hygdata_v41.csv",
        "gitBlobSHA1": blob, "sha256": sha256,
        "license": "CC BY-SA 4.0", "licenseURL": "https://creativecommons.org/licenses/by-sa/4.0/",
    },
    "license": "This derived data file is licensed CC BY-SA 4.0 (share-alike with its source).",
    "changes": [
        "Excluded the Sun and rows without coordinates or magnitude; considered stars to magnitude 6.5.",
        "Merged components within 2 arcminutes into one point: combined flux magnitude, flux-weighted normalized position; "
        "identity, color index and velocity of the brightest component.",
        "Converted right ascension/declination to unit vectors; rounded vectors to 1e-7, magnitudes to 0.001, color index to 0.001.",
        "Kept the 256 brightest after sorting by magnitude, then catalog ID; added component ID lists.",
    ],
    "generator": "scripts/data/build_star_catalog.py",
    "stars": [dict(id=s['id'], components=s['components'], hip=s['hip'], hr=s['hr'], name=s['name'], bayer=s['bayer'], con=s['con'],
                   mag=round(s['mag'], 3), ci=rnd(s['ci'], 3), u=[round(c, 7) for c in s['u']],
                   distPc=rnd(s['dist'], 4), velPcPerYear=[float(f"{v:.6e}") for v in s['vel']] if s['vel'] else None)
              for s in top],
}
open(OUT, 'w').write(json.dumps(out, indent=1, ensure_ascii=False, sort_keys=True) + '\n')
print(f"{len(stars)} candidates, {len(merged)} after merging, kept {len(top)}; faintest kept {top[-1]['mag']:.3f}; sha256 {sha256}")
