#!/usr/bin/env python3
"""Builds WorldEnvironment's 256-star catalog from the Yale Bright Star Catalogue, 5th rev. ed. (BSC5).

    python3 scripts/data/build_star_catalog.py <out.json>                      # downloads both inputs
    python3 scripts/data/build_star_catalog.py <out.json> --bsc5 FILE --iau FILE   # offline, local copies

Inputs (official sources, downloaded when no local file is given; nothing raw is stored in the repo):
  * NASA HEASARC table `bsc5p` (Hoffleit & Warren 1991, CDS V/50), as the .tdat file
    https://heasarc.gsfc.nasa.gov/FTP/heasarc/dbase/tdat_files/heasarc_bsc5p.tdat.gz  (about 0.9 MB, gzip)
  * IAU Working Group on Star Names, "IAU Catalog of Star Names" (proper names only; BSC5 has none)
    https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt  (about 70 KB)

Rules (kept from the HYG-based build, sky-seasons proposal §4): exclude non-stellar rows and rows without
coordinates or magnitude; merge unresolved components within 2 arcminutes (connected groups, processed in
stable catalog-ID order) by combining fluxes, m = -2.5 log10(sum 10^(-0.4 m_i)), with the flux-weighted
normalized position; sort by magnitude, then catalog ID; keep the brightest 256. Deterministic: the same
input bytes give the same output bytes.

Shared combined V (added after an independent check found delta Ser wrongly in the 256). A flux sum is only
right when each row carries its own component's V. For close pairs that photometry could not separate, BSC5 lists
both components with the SAME V, and that V is the light of the pair together, not of each star: HR 5788 and
HR 5789 (delta Ser) both read 3.80 while their multiple-star field m_mdiff says the two differ by 1.1 mag, so the
two cannot each be 3.80. Summing them gave 3.047, a phantom 0.75 mag too bright (true combined V 3.80, fainter
than the cut). Rule: within one merged group, components that carry exactly the same V and a multiple-star
magnitude difference m_mdiff > 0 are one measurement; that V is counted once (its flux shared equally between
them for the position weighting). Rows with different V stay resolved components and are flux-summed as before
(alpha Cen, Castor, Mizar and the rest all have different V per row). Identical V with m_mdiff 0 or missing would
be two equal stars measured separately and is still summed (none occurs in BSC5). The multiple-star fields are
HEASARC's m_cnt (components in the system), m_id (component letters), m_mdiff (magnitude difference of the two
brightest components) and m_sep (their separation in arcsec). That the shared V is a combined magnitude is
inferred from the data (equal V against a positive m_mdiff); the catalogue's own CDS ReadMe, where it would be
stated, could not be read (CDS blocks automated access) and is unverified.

BSC5 specifics (decisions logged in the output header and in Catalog/STARS-NOTICE.md):
  * Catalog ID = HR number (the Bright Star Catalogue number), `hr` repeats it as a string, `hd` is the Henry
    Draper number, `hip` is null (BSC5 carries no Hipparcos cross-identification).
  * Positions: the BSC5 J2000 (FK5) coordinates in their native sexagesimal form (0.1 s of time, 1 arcsec).
  * Excluded: the 14 HR numbers that are not stars (novae, supernovae, clusters, M31; no magnitude in BSC5), and
    two entries that BSC5 lists at a peak magnitude the star holds only briefly (PEAK_ONLY): HR 5958 = T CrB, a
    recurrent nova at its 1946 maximum (V 2.0; about 10 at rest), and HR 681 = Mira, a long-period variable
    near its maximum (V 3.04). The previous HYG file also left both out.
  * Colour index: BSC5 B-V of the brightest component, null when missing (the loader then draws white).
    None of the 256 kept stars lacks one.
  * Proper motion: BSC5 gives PM in arcsec per year (J2000, RA includes cos(dec)), parallax in arcsec and
    radial velocity in km/s. The loader moves a star as pos = u*distPc + velPcPerYear*years, so `distPc` is
    1/parallax and `velPcPerYear` the 3-D velocity (tangential from PM and distance, radial from RV, missing
    RV counts as 0), for stars with a BSC5 parallax of at least 0.001 arcsec. BSC5 parallaxes predate Hipparcos
    and are rough for distant stars (Canopus: 36 pc against about 95 pc today), but the displacement over time
    is PM times years whatever the distance, so distPc is only the motion's scale, not a quotable distance.
    Stars without a usable parallax carry null for both and stay at their J2000 position; the largest
    neglected motion is printed and written to the header.
  * Proper names come from the IAU catalogue, joined on the HR number (or HD number where the IAU lists a
    star by HD); a merged group takes the name of its brightest named component.
"""
import argparse, gzip, hashlib, json, math, re, subprocess
from collections import defaultdict

BSC5_URL = "https://heasarc.gsfc.nasa.gov/FTP/heasarc/dbase/tdat_files/heasarc_bsc5p.tdat.gz"
IAU_URL = "https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt"
MAG_LIMIT = 6.5           # candidates for merging; the 256th star is far brighter than this
MERGE_ARCMIN = 2.0
COUNT = 256
PARALLAX_MIN = 0.001      # arcsec; below this (or missing) the star carries no motion
# HR numbers excluded beyond the rows without a magnitude: BSC5 lists them at a peak magnitude that the star
# holds only briefly, so a fixed point of that brightness would be a phantom for most of the time.
PEAK_ONLY = {5958: "T CrB, recurrent nova, listed at its 1946 maximum (V 2.0; about 10 at rest)",
             681: "Mira (omicron Cet), long-period variable listed near maximum (V 3.04; below naked-eye visibility for months)"}
ARCSEC = math.pi / 648000
KMS_TO_PC_PER_YEAR = 1.0227121650537e-6   # 1 km/s in parsecs per Julian year

ap = argparse.ArgumentParser()
ap.add_argument('out')
ap.add_argument('--bsc5', help='local heasarc_bsc5p.tdat or .tdat.gz (default: download from HEASARC)')
ap.add_argument('--iau', help='local IAU-CSN.txt (default: download from the IAU WGSN page)')
args = ap.parse_args()

def fetch(url):
    # curl (default User-Agent, system certificate store): python.org builds of Python often lack the macOS CA bundle.
    return subprocess.run(['curl', '-fsSL', '--max-time', '120', url], check=True, capture_output=True).stdout

raw_bsc = open(args.bsc5, 'rb').read() if args.bsc5 else fetch(BSC5_URL)
if raw_bsc[:2] == b'\x1f\x8b':
    raw_bsc = gzip.decompress(raw_bsc)
raw_iau = open(args.iau, 'rb').read() if args.iau else fetch(IAU_URL)
sha_bsc = hashlib.sha256(raw_bsc).hexdigest()
sha_iau = hashlib.sha256(raw_iau).hexdigest()

def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

# --- BSC5 (HEASARC .tdat: header, "line[1] = field names", then <DATA> rows separated by "|") ---
lines = raw_bsc.decode('utf-8').splitlines()
fields = next(l for l in lines if l.startswith('line[1]')).split('=', 1)[1].split()
rows = []
for l in lines[lines.index('<DATA>') + 1:]:
    if not l.strip() or l.startswith('<END>'):
        continue
    p = l.split('|')
    if p[-1] == '':
        p = p[:-1]
    assert len(p) == len(fields), l[:80]
    rows.append(dict(zip(fields, p)))
assert len(rows) == 9110, len(rows)

def sexagesimal(text, hours):
    """'064508.9' (hhmmss.s) or '-164258' (+-ddmmss) to degrees."""
    s = text.strip()
    sign = -1.0 if s.startswith('-') else 1.0
    s = s.lstrip('+-')
    whole, _, frac = s.partition('.')
    whole = whole.rjust(6, '0')
    value = int(whole[:-4]) + int(whole[-4:-2]) / 60 + (int(whole[-2:]) + (float('0.' + frac) if frac else 0)) / 3600
    return sign * value * (15.0 if hours else 1.0)

def designation(alt):
    """BSC5 'name': optional Flamsteed number, Bayer letter (3 chars), component digit, constellation (3 chars).
    Returns (bayer, constellation); bayer is e.g. 'Alp' or 'Alp-1', None for stars without a Bayer letter."""
    body = re.sub(r'^\s*\d+', '', alt.rstrip())   # drop the Flamsteed number
    if len(body) < 7:
        return None, None
    greek, idx, con = body[:3].strip(), body[3].strip(), body[4:7].strip()
    bayer = (greek + ('-' + idx if idx else '')) if greek else None
    return bayer, con or None

stars, skipped = [], defaultdict(list)
for r in rows:
    hr = int(r['hr'])
    mag, ra_t, dec_t = num(r['vmag']), r['cra'], r['cdec']
    if mag is None or not ra_t.strip() or not dec_t.strip():
        skipped['no magnitude or coordinates (non-stellar)'].append(hr); continue
    if hr in PEAK_ONLY:
        skipped['listed only at a peak magnitude'].append(hr); continue
    if mag > MAG_LIMIT:
        continue
    ra = math.radians(sexagesimal(ra_t, True)); de = math.radians(sexagesimal(dec_t, False))
    u = (math.cos(de) * math.cos(ra), math.cos(de) * math.sin(ra), math.sin(de))
    plx, pmra, pmdec, rv = num(r['parallax']), num(r['pmra']), num(r['pmdec']), num(r['radvel'])
    dist = vel = None
    if plx is not None and plx >= PARALLAX_MIN and pmra is not None and pmdec is not None:
        dist = 1.0 / plx
        e_ra = (-math.sin(ra), math.cos(ra), 0.0)
        e_de = (-math.sin(de) * math.cos(ra), -math.sin(de) * math.sin(ra), math.cos(de))
        vr = (rv or 0.0) * KMS_TO_PC_PER_YEAR
        vel = [dist * ARCSEC * (pmra * e_ra[k] + pmdec * e_de[k]) + vr * u[k] for k in range(3)]
    bayer, con = designation(r['alt_name'])
    stars.append(dict(id=hr, hd=int(r['hd']) if num(r['hd']) else None, name=None, bayer=bayer, con=con,
                      mag=mag, mdiff=num(r['m_mdiff']), ci=num(r['bv_color']), u=u, dist=dist, vel=vel,
                      pm=math.hypot(pmra or 0.0, pmdec or 0.0)))
stars.sort(key=lambda s: s['id'])

# --- Proper names from the IAU Catalog of Star Names, joined on HR (or HD) ---
by_hr = {s['id']: s for s in stars}
by_hd = {s['hd']: s for s in stars if s['hd']}
names = defaultdict(set)
for l in raw_iau.decode('utf-8').splitlines():
    if not l.strip() or l[0] in '#$':
        continue
    name, desig = l[:18].strip(), l[36:49].strip()
    m = re.fullmatch(r'(HR|HD) (\d+)', desig)
    if not (name and m):
        continue
    target = (by_hr if m.group(1) == 'HR' else by_hd).get(int(m.group(2)))
    if target:
        names[target['id']].add(name)
for hr, ns in names.items():
    by_hr[hr]['name'] = sorted(ns)[0]   # one IAU name per star is the rule; duplicates are reported below
multi = {hr: sorted(ns) for hr, ns in names.items() if len(ns) > 1}

# --- Connected groups within 2' (cell hashing on the unit sphere) ---
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

merged, shared_v = [], []
for root, members in groups.items():
    ms = sorted((stars[i] for i in members), key=lambda s: s['id'])
    # Shared combined V: components with exactly the same V and m_mdiff > 0 are one measurement (see the docstring).
    same_v = defaultdict(list)
    for s in ms:
        same_v[s['mag']].append(s)
    fluxes = []
    for s in ms:
        twins = same_v[s['mag']]
        shared = len(twins) > 1 and all((t['mdiff'] or 0) > 0 for t in twins)
        fluxes.append(10 ** (-0.4 * s['mag']) / (len(twins) if shared else 1))
    mag = -2.5 * math.log10(sum(fluxes))
    for v, twins in same_v.items():
        if len(twins) > 1 and all((t['mdiff'] or 0) > 0 for t in twins):
            summed = -2.5 * math.log10(sum(10 ** (-0.4 * t['mag']) for t in ms))   # what summing every row would give
            shared_v.append((sorted(t['id'] for t in twins), v, summed, mag))
    u = [sum(fl * s['u'][k] for fl, s in zip(fluxes, ms)) for k in range(3)]
    n = math.sqrt(sum(c * c for c in u)); u = [c / n for c in u]
    primary = min(ms, key=lambda s: (s['mag'], s['id']))
    named = next((s['name'] for s in sorted(ms, key=lambda s: (s['mag'], s['id'])) if s['name']), None)
    merged.append(dict(id=primary['id'], components=[s['id'] for s in ms], hd=primary['hd'], name=named,
                       bayer=primary['bayer'], con=primary['con'], mag=mag, ci=primary['ci'], u=u,
                       dist=primary['dist'], vel=primary['vel'], pm=primary['pm']))
shared_v.sort()

merged.sort(key=lambda s: (s['mag'], s['id']))
top = merged[:COUNT]
assert all(s['ci'] is not None for s in top), "a kept star lacks B-V; decide the fallback explicitly"
still = [s for s in top if s['vel'] is None]
worst = max(still, key=lambda s: s['pm']) if still else None

def rnd(x, n):
    return None if x is None else round(x, n)

out = {
    "schema": "worldengine.stars/1",
    "count": len(top),
    "epoch": "J2000.0", "equinox": "J2000.0",
    "frame": "unit direction vectors, equatorial J2000 (x toward RA 0h, z toward north celestial pole)",
    "source": {
        "name": "Yale Bright Star Catalogue, 5th Revised Ed. (preliminary version, 1991)",
        "author": "Dorrit Hoffleit and Wayne H. Warren Jr.",
        "url": "https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html",
        "file": BSC5_URL, "distributor": "NASA HEASARC (table bsc5p; same catalogue as CDS V/50)",
        "sha256": sha_bsc, "sha256Of": "the decompressed .tdat file",
        "license": "Public domain (distributed freely by NASA HEASARC; no copyright or licence condition found; see STARS-NOTICE.md)",
        "licenseURL": "https://www.usa.gov/government-works",
    },
    "nameSource": {
        "name": "IAU Catalog of Star Names (IAU-CSN), IAU Working Group on Star Names",
        "url": "https://www.iau.org/public/themes/naming_stars/", "file": IAU_URL, "sha256": sha_iau,
        "license": "Creative Commons Attribution, per the IAU-CSN file header (names only; credited in STARS-NOTICE.md)",
    },
    "license": "This derived data file is public domain, like its source; star names are credited to the IAU WGSN (see STARS-NOTICE.md).",
    "changes": [
        "Excluded the 14 HR numbers that are not stars (no magnitude in BSC5), HR 5958 (T CrB, a recurrent nova listed at its 1946 maximum) and HR 681 (Mira, a long-period variable listed near its maximum); considered stars to magnitude 6.5.",
        "Merged components within 2 arcminutes into one point: combined flux magnitude, flux-weighted normalized position; identity, color index and velocity of the brightest component.",
        "Shared combined V: BSC5 lists some close pairs with the same V in both rows and a positive multiple-star magnitude difference (m_mdiff), which makes that V the light of the pair together; "
        "components with the same V and m_mdiff > 0 are counted once instead of flux-summed (otherwise HR 5788/5789 = delta Ser would read 3.05 instead of 3.80); rows with different V are summed as before"
        + (f" (applies to {len(shared_v)} groups among the candidates: " + ", ".join("HR " + "/".join(map(str, ids)) + f" V {v:.2f}" for ids, v, _, _ in shared_v) + ")." if shared_v else "."),
        "Converted the BSC5 J2000 right ascension/declination to unit vectors; rounded vectors to 1e-7, magnitudes to 0.001, color index (BSC5 B-V, two decimals) to 0.001.",
        "id and hr are the HR (Bright Star Catalogue) number, hd the Henry Draper number; hip is null (BSC5 has no Hipparcos cross-identification).",
        "distPc is 1/parallax and velPcPerYear the space velocity from BSC5 proper motion, parallax and radial velocity, only for stars with a parallax of at least 0.001 arcsec "
        "(BSC5 parallaxes are pre-Hipparcos and rough for distant stars, so distPc only scales the motion and is not a quotable distance); "
        + (f"the other {len(still)} stars carry null and stay at their J2000 position (largest neglected proper motion {worst['pm']:.3f} arcsec/year, HR {worst['id']})." if worst else "none are affected."),
        "Proper names: IAU Catalog of Star Names, joined on HR (or HD) number.",
        "Kept the 256 brightest after sorting by magnitude, then HR number; added component HR lists.",
    ],
    "generator": "scripts/data/build_star_catalog.py",
    "stars": [dict(id=s['id'], components=s['components'], hip=None, hr=str(s['id']), hd=s['hd'], name=s['name'], bayer=s['bayer'],
                   con=s['con'], mag=round(s['mag'], 3), ci=rnd(s['ci'], 3), u=[round(c, 7) for c in s['u']],
                   distPc=rnd(s['dist'], 4), velPcPerYear=[float(f"{v:.6e}") for v in s['vel']] if s['vel'] else None)
              for s in top],
}
open(args.out, 'w').write(json.dumps(out, indent=1, ensure_ascii=False, sort_keys=True) + '\n')
print(f"{len(stars)} candidates, {len(merged)} after merging, kept {len(top)}; faintest kept {top[-1]['mag']:.3f}; "
      f"{sum(1 for s in top if s['name'])} named; {len(still)} without motion"
      + (f" (largest neglected PM {worst['pm']:.3f} arcsec/yr, HR {worst['id']})" if worst else ""))
print(f"BSC5 sha256 {sha_bsc}\nIAU-CSN sha256 {sha_iau}")
for why, hrs in skipped.items():
    print(f"skipped ({why}): {sorted(hrs)}")
for ids, v, summed, mag in shared_v:
    print(f"shared combined V counted once: HR {'/'.join(map(str, ids))}, V {v:.2f} in each row; flux-summing would give {summed:.3f}, now {mag:.3f}")
if multi:
    print("IAU names for one HR number (first alphabetical used):", multi)
