#!/usr/bin/env python3
"""Terrain slope grids from USGS 3DEP lidar, one per committed test area.

Offline research tool for WorldEngine's region kit. Not part of the engine or any app. Output per area:
Data/areas/<id>/terrain-slope.bin (uint8 slope grid, raw deflate) and terrain-slope.json (header). Method and
format: README.md next to this file. Point clouds, DEM windows and intermediate grids stay in the work
directory (outside the repository).

Subcommands (all take --work DIR, never inside the repository; --areas limits the areas):
  plan      EPT nodes meeting each area box, points per depth, node sizes (HTTP HEAD) -> chosen depth
  fetch     read those EPT nodes (LAZ over HTTPS), byte cap per area
  grid      ground points -> 1 m DTM -> slope grid; split-sample check (work directory)
  validate  compare with the USGS 3DEP 1 m DEM (windowed COG reads from the public prd-tnm bucket)
  emit      write Data/areas/<id>/terrain-slope.bin and .json
  all       plan + fetch + grid + validate + emit

The pure functions (grid, filter, slope, encoding, statistics) need numpy and scipy only and are tested
offline in tests/test_slope.py.
"""

import argparse
import hashlib
import json
import math
import os
import ssl
import sys
import time
import urllib.parse
import urllib.request
import zlib

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "lidar"))
import roofplanes as rp  # noqa: E402  (local_en, local_to_latlon, Web Mercator, EPT node bounds)

UA = "WorldEngine-regionkit-terrain/0.1 (offline research tool; USGS 3DEP slope grids)"
FORMAT = "worldengine-slope-grid-v1"
NODATA = 255
CAP = 254  # slope >= 127 %
METHOD = ("Vendor ground-class (2) lidar points are binned on a 1 m grid in the area's local frame (exact WGS84 "
          "east/north about the manifest centre); each cell takes the mean height of its ground points. Empty cells "
          "are filled by inverse-distance weighting (power 2, up to 12 neighbours) of ground points within 2 m of the "
          "cell centre; cells with no ground point within 2 m stay no-data (buildings, water: no terrain is invented "
          "there). The DTM is smoothed with a 3x3 mean over the valid cells of the window (no-data cells stay "
          "no-data), then slope percent = 100 x |grad z| is taken with the Horn 3x3 operator; any no-data cell in "
          "the Horn window makes the slope no-data.")


# ================================================================ pure functions (tested offline)


def grid_shape(width, height, cell=1.0):
    """Columns and rows of a grid covering [-w/2, w/2] x [-h/2, h/2]."""
    return int(round(width / cell)), int(round(height / cell))


def cell_index(x, y, min_x, min_y, cols, rows, cell=1.0):
    """Flat cell index (row-major, row 0 south, col 0 west) of points; -1 outside the grid."""
    ix = np.floor((np.asarray(x, float) - min_x) / cell).astype(np.int64)
    iy = np.floor((np.asarray(y, float) - min_y) / cell).astype(np.int64)
    ok = (ix >= 0) & (ix < cols) & (iy >= 0) & (iy < rows)
    return np.where(ok, iy * cols + ix, -1)


def mean_dtm(P, min_x, min_y, cols, rows, cell=1.0):
    """Mean z of the points in each cell; NaN where a cell has none. Returns (dtm[rows, cols], counts)."""
    idx = cell_index(P[:, 0], P[:, 1], min_x, min_y, cols, rows, cell)
    ok = idx >= 0
    n = np.bincount(idx[ok], minlength=rows * cols)
    s = np.bincount(idx[ok], weights=P[ok, 2].astype(float), minlength=rows * cols)
    with np.errstate(invalid="ignore", divide="ignore"):
        z = np.where(n > 0, s / np.maximum(n, 1), np.nan)
    return z.reshape(rows, cols), n.reshape(rows, cols)


def gap_fill(dtm, P, min_x, min_y, cell=1.0, max_dist=2.0, k=12):
    """Fill NaN cells by IDW (power 2) of points within max_dist of the cell centre; others stay NaN."""
    from scipy.spatial import cKDTree
    out = dtm.copy()
    miss = np.argwhere(np.isnan(dtm))
    if len(miss) == 0 or len(P) == 0:
        return out
    cx = min_x + (miss[:, 1] + 0.5) * cell
    cy = min_y + (miss[:, 0] + 0.5) * cell
    tree = cKDTree(P[:, :2].astype(float))
    d, j = tree.query(np.stack([cx, cy], axis=1), k=min(k, len(P)), distance_upper_bound=max_dist)
    if d.ndim == 1:
        d, j = d[:, None], j[:, None]
    valid = np.isfinite(d)
    zs = np.zeros_like(d)
    zs[valid] = P[j[valid], 2]
    w = np.where(valid, 1.0 / np.maximum(d, 0.05) ** 2, 0.0)
    ws = w.sum(axis=1)
    filled = ws > 0
    out[miss[filled, 0], miss[filled, 1]] = (w * zs).sum(axis=1)[filled] / ws[filled]
    return out


def mean3x3(z):
    """3x3 mean over the valid (non-NaN) cells of each window; NaN cells stay NaN."""
    from scipy import ndimage
    valid = np.isfinite(z)
    zz = np.where(valid, z, 0.0)
    k = np.ones((3, 3))
    s = ndimage.convolve(zz, k, mode="constant", cval=0.0)
    n = ndimage.convolve(valid.astype(float), k, mode="constant", cval=0.0)
    with np.errstate(invalid="ignore", divide="ignore"):
        out = s / n
    out[~valid] = np.nan
    return out


def horn_slope_percent(z, cell=1.0):
    """Slope percent (100 |grad z|) by the Horn 3x3 operator; NaN where any window cell (or the edge) is NaN."""
    rows, cols = z.shape
    p = np.full((rows + 2, cols + 2), np.nan)
    p[1:-1, 1:-1] = z

    def s(dy, dx):
        return p[1 + dy:1 + dy + rows, 1 + dx:1 + dx + cols]
    # dy = +1 is the next row (one cell further north); the sign does not matter for |grad|
    gx = ((s(-1, 1) + 2 * s(0, 1) + s(1, 1)) - (s(-1, -1) + 2 * s(0, -1) + s(1, -1))) / (8 * cell)
    gy = ((s(1, -1) + 2 * s(1, 0) + s(1, 1)) - (s(-1, -1) + 2 * s(-1, 0) + s(-1, 1))) / (8 * cell)
    out = 100.0 * np.hypot(gx, gy)  # NaN propagates from the eight neighbours ...
    out[np.isnan(z)] = np.nan       # ... and the centre cell (unused by Horn) counts too
    return out


def slope_pipeline(dtm, cell=1.0):
    return horn_slope_percent(mean3x3(dtm), cell)


def quantize(slope):
    """uint8: floor(slope * 2 + 0.5) for slope < 127 % (at most 253), 254 for >= 127 %, 255 for NaN."""
    s = np.asarray(slope, float)
    q = np.full(s.shape, NODATA, np.uint8)
    ok = np.isfinite(s)
    v = np.floor(np.maximum(s[ok], 0.0) * 2 + 0.5)
    q[ok] = np.where(s[ok] >= 127.0, CAP, np.minimum(v, 253)).astype(np.uint8)
    return q


def dequantize(q):
    """Slope percent of uint8 codes (254 -> 127, 255 -> NaN)."""
    q = np.asarray(q)
    out = q.astype(float) / 2
    out[q == NODATA] = np.nan
    return out


def raw_deflate(data):
    c = zlib.compressobj(9, zlib.DEFLATED, -15)
    return c.compress(bytes(data)) + c.flush()


def raw_inflate(blob):
    return zlib.decompress(blob, -15)


def encode(q):
    """Row-major bytes (row 0 = south, as stored) -> raw deflate."""
    return raw_deflate(np.ascontiguousarray(q, np.uint8).tobytes())


def decode(blob, cols, rows):
    return np.frombuffer(raw_inflate(blob), np.uint8).reshape(rows, cols)


def num(v):
    """JSON number: int when integral (deterministic header)."""
    f = float(v)
    return int(f) if f.is_integer() else f


def header(lat0, lon0, width, height, cols, rows, blob, source, ground_density, nodata_share, validation, cell=1.0):
    return {
        "format": FORMAT,
        "frame": {"origin": {"latitude": lat0, "longitude": lon0}},
        "cellM": num(cell),
        "minX": num(-width / 2),
        "minY": num(-height / 2),
        "cols": cols,
        "rows": rows,
        "encoding": "uint8 row-major, row 0 south, col 0 west; raw deflate",
        "quantization": "value = round(slope percent × 2); 254 = ≥ 127 %; 255 = no data",
        "binFile": "terrain-slope.bin",
        "binSha256": hashlib.sha256(blob).hexdigest(),
        "binBytes": len(blob),
        "method": METHOD,
        "source": source,
        "groundPointsPerM2": round(float(ground_density), 2),
        "noDataShare": round(float(nodata_share), 4),
        "validation": validation,
    }


def dumps(obj):
    return json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def diff_stats(a, b, ref, split):
    """|a - b| statistics (percentage points) on cells where both are finite, split by ref < split / >= split."""
    ok = np.isfinite(a) & np.isfinite(b) & np.isfinite(ref)
    out = {}
    for name, m in ((f"slopeBelow{split}", ok & (ref < split)), (f"slope{split}AndAbove", ok & (ref >= split))):
        d = np.abs(a[m] - b[m])
        if len(d) == 0:
            out[name] = {"cells": 0}
            continue
        out[name] = {"cells": int(len(d)),
                     "medianAbsDiffPts": round(float(np.median(d)), 2),
                     "p90AbsDiffPts": round(float(np.percentile(d, 90)), 2),
                     "shareWithin2Pts": round(float(np.mean(d <= 2)), 4),
                     "shareWithin5Pts": round(float(np.mean(d <= 5)), 4)}
    return out


def dilate(mask, cells=1):
    from scipy import ndimage
    if cells <= 0:
        return mask
    return ndimage.binary_dilation(mask, structure=np.ones((3, 3), bool), iterations=cells)


def area_box_local(width, height, margin):
    return (-width / 2 - margin, -height / 2 - margin, width / 2 + margin, height / 2 + margin)


def local_box_to_merc(lat0, lon0, box, samples=21):
    """EPSG:3857 rectangle enclosing a local box (sampled along its edges)."""
    x0, y0, x1, y1 = box
    t = np.linspace(0, 1, samples)
    ex = np.concatenate([x0 + (x1 - x0) * t, np.full(samples, x1), x1 - (x1 - x0) * t, np.full(samples, x0)])
    ny = np.concatenate([np.full(samples, y0), y0 + (y1 - y0) * t, np.full(samples, y1), y1 - (y1 - y0) * t])
    lat, lon = rp.local_to_latlon(lat0, lon0, ex, ny)
    mx, my = rp.lonlat_to_merc(lon, lat)
    return float(mx.min()), float(my.min()), float(mx.max()), float(my.max())


# ================================================================ I/O


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def load_cfg():
    with open(os.path.join(HERE, "data", "areas.json")) as f:
        return json.load(f)


def manifest(area_id):
    with open(os.path.join(REPO, "Data", "areas", area_id, "manifest.json")) as f:
        return json.load(f)


class Work:
    def __init__(self, root):
        root = os.path.realpath(root)
        if root == REPO or root.startswith(REPO + os.sep):
            sys.exit("refusing a work directory inside the repository")
        self.root = root
        os.makedirs(root, exist_ok=True)

    def p(self, *parts):
        path = os.path.join(self.root, *parts)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path

    def ledger(self):
        try:
            with open(self.p("ledger.json")) as f:
                return json.load(f)
        except FileNotFoundError:
            return []

    def ledger_add(self, area, kind, what, nbytes):
        led = self.ledger()
        led.append({"area": area, "kind": kind, "what": what[:200], "bytes": int(nbytes),
                    "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())})
        with open(self.p("ledger.json"), "w") as f:
            json.dump(led, f, indent=0)

    def bytes_for(self, area, kinds=None):
        return sum(e["bytes"] for e in self.ledger() if e["area"] == area and (kinds is None or e["kind"] in kinds))


def _ssl():
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def http(url, work, area, kind, method="GET"):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": UA})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=300, context=_ssl()) as r:
                if method == "HEAD":
                    return int(r.headers.get("Content-Length", 0))
                body = r.read()
            work.ledger_add(area, kind, url, len(body))
            return body
        except urllib.error.HTTPError as e:
            if e.code not in (408, 429, 500, 502, 503, 504) or attempt == 3:
                raise
            log(f"retry temporary HTTP {e.code}: {url}")
            time.sleep(2 + 4 * attempt)
        except Exception as e:  # transient network errors
            if attempt == 3:
                raise
            log(f"retry {url}: {e}")
            time.sleep(2 + 4 * attempt)


def cached_json(url, work, area, name, kind):
    path = work.p("ept", name)
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    body = http(url, work, area, kind)
    with open(path, "wb") as f:
        f.write(body)
    return json.loads(body)


def area_ctx(cfg, area_id):
    man = manifest(area_id)
    src = cfg["sources"][next(a["source"] for a in cfg["areas"] if a["id"] == area_id)]
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    w, h = float(man["widthMeters"]), float(man["heightMeters"])
    box = area_box_local(w, h, cfg["marginMeters"])
    return man, src, lat0, lon0, w, h, box, local_box_to_merc(lat0, lon0, box)


def hierarchy(src, work, area, mbox):
    root = src["eptRoot"]
    tag = root.rstrip("/").split("/")[-1]
    ept = cached_json(root + "ept.json", work, area, f"{tag}/ept.json", "ept-meta")
    cube = ept["bounds"]
    found, pending = {}, ["0-0-0-0"]
    while pending:
        hk = pending.pop()
        h = cached_json(root + f"ept-hierarchy/{hk}.json", work, area, f"{tag}/h-{hk}.json", "ept-hierarchy")
        for key, count in h.items():
            if rp.rect_overlap_share(rp.ept_node_bounds(cube, key), mbox) <= 0:
                continue
            if count == -1:
                pending.append(key)
            else:
                found[key] = count
    return ept, found


def cmd_plan(args, work, cfg):
    plans = {}
    for area in args.areas:
        man, src, lat0, lon0, w, h, box, mbox = area_ctx(cfg, area)
        ept, nodes = hierarchy(src, work, area, mbox)
        sizes_path = work.p("plan", f"{area}-sizes.json")
        sizes = json.load(open(sizes_path)) if os.path.exists(sizes_path) else {}
        todo = [k for k in nodes if k not in sizes]
        for i, key in enumerate(sorted(todo)):
            sizes[key] = http(src["eptRoot"] + f"ept-data/{key}.laz", work, area, "head", method="HEAD")
            if i % 50 == 0:
                log(f"[plan {area}] HEAD {i + 1}/{len(todo)}")
        with open(sizes_path, "w") as f:
            json.dump(sizes, f)
        ground_m2 = (box[2] - box[0]) * (box[3] - box[1])
        depths, cum_pts, cum_bytes = {}, 0.0, 0
        for d in sorted({int(k.split("-")[0]) for k in nodes}):
            keys = [k for k in nodes if int(k.split("-")[0]) == d]
            inbox = sum(nodes[k] * rp.rect_overlap_share(rp.ept_node_bounds(ept["bounds"], k), mbox) for k in keys)
            cum_pts += inbox
            cum_bytes += sum(sizes[k] for k in keys)
            depths[d] = {"nodes": len(keys), "points": sum(nodes[k] for k in keys),
                         "cumulativeDensityPerM2": round(cum_pts / ground_m2, 2), "cumulativeBytes": cum_bytes}
        full = max(depths)
        fits = [d for d in depths if depths[d]["cumulativeBytes"] <= cfg["maxBytesPerArea"]]
        chosen = max(fits) if fits else None
        plans[area] = {"ept": src["eptRoot"], "srs": ept["srs"].get("horizontal"), "fullDepth": full,
                       "chosenDepth": chosen, "fullDensity": chosen == full, "depths": depths}
        with open(work.p("plan", f"{area}.json"), "w") as f:
            json.dump(plans[area], f, indent=1)
    print(json.dumps(plans, indent=1))
    for area, p in plans.items():
        if p["chosenDepth"] is None:
            sys.exit(f"{area}: even depth 0 exceeds the byte cap")
        if not p["fullDensity"]:
            log(f"WARNING {area}: full depth {p['fullDepth']} needs "
                f"{p['depths'][p['fullDepth']]['cumulativeBytes']:,} bytes > cap; chosen depth {p['chosenDepth']}")
    return plans


def cmd_fetch(args, work, cfg):
    for area in args.areas:
        plan_path = work.p("plan", f"{area}.json")
        if not os.path.exists(plan_path):
            sys.exit("run plan first")
        plan = json.load(open(plan_path))
        if not plan["fullDensity"] and not args.allow_partial:
            sys.exit(f"{area}: full density exceeds the byte cap; stopping (rerun with --allow-partial to accept "
                     f"depth {plan['chosenDepth']})")
        man, src, lat0, lon0, w, h, box, mbox = area_ctx(cfg, area)
        ept, nodes = hierarchy(src, work, area, mbox)
        sizes = json.load(open(work.p("plan", f"{area}-sizes.json")))
        keys = sorted((k for k in nodes if int(k.split("-")[0]) <= plan["chosenDepth"]),
                      key=lambda k: [int(v) for v in k.split("-")])
        total = work.bytes_for(area, {"ept-data"})
        for i, key in enumerate(keys):
            path = work.p("laz", area, key + ".laz")
            if os.path.exists(path):
                continue
            if total + sizes.get(key, 0) > cfg["maxBytesPerArea"]:
                sys.exit(f"{area}: byte cap reached ({total:,} bytes); stopping before {key}")
            body = http(src["eptRoot"] + f"ept-data/{key}.laz", work, area, "ept-data")
            total += len(body)
            with open(path, "wb") as f:
                f.write(body)
            if i % 25 == 0:
                log(f"[fetch {area}] {i + 1}/{len(keys)} nodes, {total / 1e6:.1f} MB")
        log(f"[fetch {area}] {len(keys)} nodes, {total:,} bytes of LAZ")


def load_points(work, area, lat0, lon0, box):
    """Ground points (local x, y, z) and class counts in the local box; also building/water points (x, y)."""
    import glob
    import laspy
    ground, other = [], {6: [], 9: []}
    counts = {}
    files = sorted(glob.glob(work.p("laz", area, "*.laz")),
                   key=lambda p: [int(v) for v in os.path.basename(p)[:-4].split("-")])
    for path in files:
        las = laspy.read(path)
        cls = np.asarray(las.classification)
        lon, lat = rp.merc_to_lonlat(np.asarray(las.x), np.asarray(las.y))
        e, n = rp.local_en(lat0, lon0, lat, lon)
        ok = (e >= box[0]) & (e <= box[2]) & (n >= box[1]) & (n <= box[3])
        for c, k in zip(*np.unique(cls[ok], return_counts=True)):
            counts[int(c)] = counts.get(int(c), 0) + int(k)
        g = ok & (cls == 2)
        ground.append(np.stack([e[g], n[g], np.asarray(las.z)[g]], axis=1))
        for c in other:
            m = ok & (cls == c)
            other[c].append(np.stack([e[m], n[m]], axis=1))
    G = np.concatenate(ground) if ground else np.zeros((0, 3))
    return G, {c: np.concatenate(v) for c, v in other.items()}, counts, len(files)


def build_slope(G, w, h, cfg):
    cell = cfg["cellM"]
    cols, rows = grid_shape(w, h, cell)
    dtm, n = mean_dtm(G, -w / 2, -h / 2, cols, rows, cell)
    filled = gap_fill(dtm, G, -w / 2, -h / 2, cell, cfg["gapFillMeters"], cfg["gapFillNeighbours"])
    return filled, slope_pipeline(filled, cell), n


def cmd_grid(args, work, cfg):
    for area in args.areas:
        man, src, lat0, lon0, w, h, box, mbox = area_ctx(cfg, area)
        G, other, counts, nfiles = load_points(work, area, lat0, lon0, box)
        cell = cfg["cellM"]
        cols, rows = grid_shape(w, h, cell)
        inner = (np.abs(G[:, 0]) <= w / 2) & (np.abs(G[:, 1]) <= h / 2)
        density = inner.sum() / (w * h)
        log(f"[grid {area}] {nfiles} nodes, {len(G):,} ground points in box (+margin), {density:.2f} per m2 in area")
        dtm, slope, n = build_slope(G, w, h, cfg)
        q = quantize(slope)
        # building / water occupancy (for validation masks)
        occ = np.zeros(rows * cols, bool)
        for c in (6, 9):
            idx = cell_index(other[c][:, 0], other[c][:, 1], -w / 2, -h / 2, cols, rows, cell)
            occ[idx[idx >= 0]] = True
        occ = occ.reshape(rows, cols)
        # split-sample: alternate ground points in read order
        half_a, half_b = G[0::2], G[1::2]
        _, sa, _ = build_slope(half_a, w, h, cfg)
        _, sb, _ = build_slope(half_b, w, h, cfg)
        split = diff_stats(sa, sb, slope, cfg["slopeClassSplitPercent"])
        np.savez_compressed(work.p("grid", f"{area}.npz"), dtm=dtm, slope=slope, q=q, occ=occ, n=n)
        stats = {"groundPointsPerM2": float(density), "noDataShare": float(np.mean(q == NODATA)),
                 "cellsWithGroundPoint": float(np.mean(n > 0)), "classCounts": counts, "nodes": nfiles,
                 "lazBytes": work.bytes_for(area, {"ept-data"}), "splitSample": split,
                 "slopePercentiles": {p: round(float(np.nanpercentile(slope, p)), 2) for p in (50, 90, 99)}}
        with open(work.p("grid", f"{area}-stats.json"), "w") as f:
            json.dump(stats, f, indent=1)
        print(area, json.dumps(stats, indent=1))


def tnm_dem_tiles(work, area, lat0, lon0, w, h, project):
    lat, lon = rp.local_to_latlon(lat0, lon0, np.array([-w / 2, w / 2]), np.array([-h / 2, h / 2]))
    q = urllib.parse.urlencode({"datasets": "Digital Elevation Model (DEM) 1 meter",
                                "bbox": f"{lon[0]},{lat[0]},{lon[1]},{lat[1]}", "max": 50, "outputFormat": "JSON"})
    d = json.loads(http("https://tnmaccess.nationalmap.gov/api/v1/products?" + q, work, area, "tnm-api"))
    return [it for it in d.get("items", []) if project in it.get("downloadURL", "")]


def sample_dem(url, xs, ys, pad=4):
    """Bilinear DEM heights at UTM points from a windowed COG read; returns (z, bytes estimate, crs info)."""
    import rasterio
    from rasterio.windows import from_bounds
    from scipy import ndimage
    with rasterio.open("/vsicurl/" + url) as ds:
        win = from_bounds(xs.min(), ys.min(), xs.max(), ys.max(), ds.transform).round_offsets().round_lengths()
        col0 = max(int(win.col_off) - pad, 0)
        row0 = max(int(win.row_off) - pad, 0)
        col1 = min(int(win.col_off + win.width) + pad, ds.width)
        row1 = min(int(win.row_off + win.height) + pad, ds.height)
        if col1 <= col0 or row1 <= row0:
            return np.full(xs.shape, np.nan), 0, None
        window = rasterio.windows.Window(col0, row0, col1 - col0, row1 - row0)
        a = ds.read(1, window=window, masked=True).astype(float).filled(np.nan)
        brows, bcols = ds.block_shapes[0]
        nbytes = 0
        for bi in range(row0 // brows, (row1 - 1) // brows + 1):
            for bj in range(col0 // bcols, (col1 - 1) // bcols + 1):
                try:
                    nbytes += ds.block_size(1, bi, bj)
                except Exception:
                    pass
        inv = ~ds.transform
        c, r = inv * (xs, ys)
        info = {"crs": ds.crs.to_string(), "blockShape": [brows, bcols], "tiled": ds.profile.get("tiled")}
    rr, cc = r - row0 - 0.5, c - col0 - 0.5
    z = ndimage.map_coordinates(a, [rr.ravel(), cc.ravel()], order=1, mode="constant", cval=np.nan)
    return z.reshape(xs.shape), nbytes, info


def cmd_validate(args, work, cfg):
    import os as _os
    from rasterio.warp import transform as warp
    _os.environ.setdefault("GDAL_HTTP_USERAGENT", UA)
    _os.environ.setdefault("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")
    _os.environ.setdefault("CPL_VSIL_CURL_ALLOWED_EXTENSIONS", ".tif")
    split_pct = cfg["slopeClassSplitPercent"]
    for area in args.areas:
        man, src, lat0, lon0, w, h, box, mbox = area_ctx(cfg, area)
        g = np.load(work.p("grid", f"{area}.npz"))
        dtm, q, occ = g["dtm"], g["q"], g["occ"]
        rows, cols = q.shape
        cell = cfg["cellM"]
        tiles = tnm_dem_tiles(work, area, lat0, lon0, w, h, src["tnmProject"])
        if not tiles:
            log(f"[validate {area}] no 1 m DEM of {src['tnmProject']} found")
            continue
        # cell centres -> lat/lon (exact inverse of the local frame) -> DEM CRS; candidate sub-cell shifts
        ex = -w / 2 + (np.arange(cols) + 0.5) * cell
        ny = -h / 2 + (np.arange(rows) + 0.5) * cell
        E, N = np.meshgrid(ex, ny)
        lat, lon = rp.local_to_latlon(lat0, lon0, E.ravel(), N.ravel())
        dem = np.full(E.size, np.nan)
        used, nbytes_total, info = [], 0, None
        for it in tiles:
            import rasterio
            with rasterio.open("/vsicurl/" + it["downloadURL"]) as ds:
                crs = ds.crs
            xs, ys = warp("EPSG:4326", crs, lon.tolist(), lat.tolist())
            xs, ys = np.asarray(xs), np.asarray(ys)
            z, nb, info = sample_dem(it["downloadURL"], xs, ys)
            take = np.isnan(dem) & np.isfinite(z)
            if take.any():
                dem[take] = z[take]
                used.append(it["downloadURL"])
            nbytes_total += nb
            work.ledger_add(area, "dem-window-estimate", it["downloadURL"], nb)
        dem = dem.reshape(rows, cols)
        # horizontal alignment check: integer-cell shift of the DEM that best matches the DTM heights
        best = None
        for dy in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                a = dtm[2:-2, 2:-2]
                b = dem[2 + dy:rows - 2 + dy, 2 + dx:cols - 2 + dx]
                m = np.isfinite(a) & np.isfinite(b) & ~dilate(occ, 2)[2:-2, 2:-2]
                r = a[m] - b[m]
                mad = float(np.median(np.abs(r - np.median(r))))
                if best is None or mad < best[0]:
                    best = (mad, dx, dy, float(np.median(r)))
        dem_slope = slope_pipeline(dem, cell)
        ours = dequantize(q)
        # buildings: vendor class 6 where the project has it (Denver's DRCOG delivery leaves buildings in class 1),
        # so also every cell within 2 m of our own no-data (no ground point within 2 m: roofs, water)
        cls_mask = dilate(occ, 2)
        gap_mask = dilate(q == NODATA, 2)
        stats = diff_stats(np.where(cls_mask | gap_mask, np.nan, ours), dem_slope, dem_slope, split_pct)
        edge = diff_stats(np.where(cls_mask | ~gap_mask, np.nan, ours), dem_slope, dem_slope, split_pct)
        val = {
            "how": (f"Our 1 m slope (as encoded) vs the same 3x3-mean + Horn slope of the USGS 3DEP 1 m DEM "
                    f"({src['tnmProject']}, bilinear-sampled at our cell centres from a windowed read of the public "
                    f"COG), excluding cells within 2 m of lidar building/water points or of our no-data; classes by "
                    f"DEM slope. Both come from the same lidar, so this measures gridding/method error, not lidar "
                    f"accuracy. nearNoDataEdge: the excluded cells within 2 m of our no-data (e.g. yard strips next "
                    f"to houses), where the DEM interpolates across buildings."),
            "reference": {"product": "USGS 3DEP 1 m DEM", "tiles": used},
            "vsReference1mDEM": stats,
            "nearNoDataEdge": edge,
            "heightMedianOffsetM": round(best[3], 3),
            "heightResidualMadM": round(best[0], 3),
            "bestIntegerShiftCells": [best[1], best[2]],
        }
        with open(work.p("grid", f"{area}-validation.json"), "w") as f:
            json.dump({"validation": val, "demBytesEstimate": nbytes_total, "demInfo": info}, f, indent=1)
        print(area, json.dumps(val, indent=1), "DEM bytes (block estimate):", nbytes_total, info)


def cmd_emit(args, work, cfg):
    for area in args.areas:
        man, src, lat0, lon0, w, h, box, mbox = area_ctx(cfg, area)
        g = np.load(work.p("grid", f"{area}.npz"))
        q = g["q"]
        rows, cols = q.shape
        stats = json.load(open(work.p("grid", f"{area}-stats.json")))
        vpath = work.p("grid", f"{area}-validation.json")
        validation = {}
        if os.path.exists(vpath):
            validation = json.load(open(vpath))["validation"]
        validation["splitSample"] = {
            "how": "DTM and slope rebuilt from alternate halves of the ground points (each at half density); "
                   "|slope A - slope B| by our full-density slope class; an upper bound on point-noise error.",
            **stats["splitSample"]}
        blob = encode(q)
        source = {"id": src["id"], "title": src["title"], "attribution": "USGS 3D Elevation Program",
                  "license": "public-domain", "licenseURL": cfg["licenseURL"], "url": src["eptRoot"],
                  "collected": src["collected"], "qualityLevel": src["qualityLevel"],
                  "verticalAccuracy": src["verticalAccuracy"]}
        hdr = header(lat0, lon0, w, h, cols, rows, blob, source, stats["groundPointsPerM2"], stats["noDataShare"],
                     validation, cfg["cellM"])
        out_dir = os.path.join(REPO, "Data", "areas", area)
        with open(os.path.join(out_dir, "terrain-slope.bin"), "wb") as f:
            f.write(blob)
        with open(os.path.join(out_dir, "terrain-slope.json"), "w") as f:
            f.write(dumps(hdr))
        assert np.array_equal(decode(blob, cols, rows), q)
        log(f"[emit {area}] {len(blob):,} bytes bin, {cols}x{rows}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["plan", "fetch", "grid", "validate", "emit", "all"])
    ap.add_argument("--work", required=True)
    ap.add_argument("--areas", nargs="*")
    ap.add_argument("--allow-partial", action="store_true", help="accept a shallower EPT depth than full")
    args = ap.parse_args()
    cfg = load_cfg()
    args.areas = args.areas or [a["id"] for a in cfg["areas"]]
    work = Work(args.work)
    steps = {"plan": [cmd_plan], "fetch": [cmd_fetch], "grid": [cmd_grid], "validate": [cmd_validate],
             "emit": [cmd_emit], "all": [cmd_plan, cmd_fetch, cmd_grid, cmd_validate, cmd_emit]}[args.cmd]
    for step in steps:
        step(args, work, cfg)


if __name__ == "__main__":
    main()
