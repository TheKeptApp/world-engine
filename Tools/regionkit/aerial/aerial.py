#!/usr/bin/env python3
"""Aerial roof study: roof colour, roof-type guess and tree canopy per block from NAIP imagery.

Offline research tool for WorldEngine's region kit. Not part of the engine or any app; nothing here is
loaded at runtime. See README.md for the one-command run and docs/research/aerial.md for the results.

Subcommands (all take --work DIR; default $AERIAL_WORK or <system temp>/worldengine-aerial, never the repo):
  fetch     OSM footprints and streets (one Overpass request), Overture buildings (bbox-filtered GeoParquet
            reads), and a windowed NAIP read (COG range requests). Cached in the work directory.
  analyse   footprint merge, alignment, per-building estimates (work directory only), blocks and canopy,
            aggregate results -> results/summary.json
  crops     stable random sample + crops with outlines for hand labelling (work directory only)
  points    stable random points + contact sheets for a photo-interpreted canopy check (work directory only)
  score     compare hand labels (work directory) with the estimates -> results/accuracy.json (including the
            canopy point check)
  all       fetch + analyse (+ score when label files exist)

Privacy: per-building values, crops and labels stay in the work directory. Only aggregates go to results/.
"""

import argparse
import datetime as dt
import gzip
import hashlib
import json
import logging
import math
import os
import re
import sys
import tempfile
import time
import urllib.parse
import urllib.request

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import roofcore as rc  # noqa: E402

UA = "WorldEngine-regionkit/0.1 (offline research tool)"
TOOL_VERSION = "regionkit-aerial 0.1"
RESULTS = os.path.join(HERE, "results")
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))


def load(name):
    with open(os.path.join(HERE, "data", name)) as f:
        return json.load(f)


def log(*a):
    print(*a, file=sys.stderr, flush=True)


# ---------------------------------------------------------------- work dir and ledger

class Work:
    def __init__(self, root):
        self.root = os.path.realpath(root)
        if os.path.commonpath([self.root, REPO]) == REPO:
            raise SystemExit("work directory must be outside the repository (crops and per-building values)")
        os.makedirs(os.path.join(self.root, "raw"), exist_ok=True)

    def p(self, *parts):
        path = os.path.join(self.root, *parts)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path

    def ledger_add(self, kind, what, nbytes):
        path = self.p("ledger.json")
        led = json.load(open(path)) if os.path.exists(path) else []
        led.append({"kind": kind, "what": what, "bytes": int(nbytes),
                    "at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")})
        json.dump(led, open(path, "w"), indent=1)

    def ledger(self):
        path = self.p("ledger.json")
        return json.load(open(path)) if os.path.exists(path) else []


_last_overpass = [0.0]


def _ssl_context():
    """Verified TLS with certifi's CA bundle when present (python.org builds may ship without CA roots)."""
    import ssl
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def http(url, work, kind, data=None, headers=None, timeout=180):
    req = urllib.request.Request(url, data=data, headers={"User-Agent": UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=timeout, context=_ssl_context()) as r:
        body = r.read()
    work.ledger_add(kind, url.split("?")[0][:160], len(body))
    return body


def overpass(query, work, endpoints):
    """One request at a time, >= 5 s apart, back off >= 60 s on 429/504, fallback endpoint."""
    for attempt in range(6):
        ep = endpoints[min(attempt // 3, len(endpoints) - 1)]
        wait = 5 - (time.time() - _last_overpass[0])
        if wait > 0:
            time.sleep(wait)
        try:
            _last_overpass[0] = time.time()
            return json.loads(http(ep, work, "overpass", data=urllib.parse.urlencode({"data": query}).encode()))
        except urllib.error.HTTPError as e:
            if e.code in (429, 504):
                log(f"[overpass] HTTP {e.code}; backing off 65 s")
                time.sleep(65)
                continue
            raise
        except urllib.error.URLError as e:
            log(f"[overpass] {e}; retrying in 65 s")
            time.sleep(65)
    raise SystemExit("Overpass failed")


# ---------------------------------------------------------------- cell geometry

def cell_geometry(cell):
    from rasterio.warp import transform
    lat, lon = cell["center"]
    xs, ys = transform("EPSG:4326", cell["crs"], [lon], [lat])
    cx, cy = xs[0], ys[0]
    h = cell["sizeMeters"] / 2
    utm = (cx - h, cy - h, cx + h, cy + h)

    def wgs_bbox(margin):
        x0, y0, x1, y1 = utm[0] - margin, utm[1] - margin, utm[2] + margin, utm[3] + margin
        lons, lats = transform(cell["crs"], "EPSG:4326", [x0, x1, x1, x0], [y0, y0, y1, y1])
        return (min(lats), min(lons), max(lats), max(lons))  # S, W, N, E

    return {"utm": utm, "center_utm": (cx, cy), "bbox_buildings": wgs_bbox(cell["buildingMarginMeters"]),
            "bbox_streets": wgs_bbox(cell["streetMarginMeters"]), "bbox_cell": wgs_bbox(0)}


# ---------------------------------------------------------------- fetch

def fetch_osm(cell, geo, work):
    path = work.p("raw", "overpass.json")
    if os.path.exists(path):
        return json.load(open(path))
    s, w, n, e = (round(x, 6) for x in geo["bbox_buildings"])
    s2, w2, n2, e2 = (round(x, 6) for x in geo["bbox_streets"])
    classes = "|".join(cell["overpass"]["streetClasses"])
    q = (f"[out:json][timeout:90];\n(\n  way[\"building\"]({s},{w},{n},{e});\n  relation[\"building\"]({s},{w},{n},{e});\n"
         f"  way[\"highway\"~\"^({classes})$\"]({s2},{w2},{n2},{e2});\n);\nout body geom;")
    log("[osm] Overpass query (one request)")
    data = overpass(q, work, cell["overpass"]["endpoints"])
    data["query"] = q
    json.dump(data, open(path, "w"))
    return data


def _duck_http_bytes(con):
    tot = 0
    try:
        rows = con.execute("select message from duckdb_logs where type='HTTP'").fetchall()
    except Exception:
        return None
    for (m,) in rows:
        req, _, resp = m.partition("'response'")
        if "GET" in req:
            mm = re.search(r"Content-Length[=:]\s*'?(\d+)", resp)
            if mm:
                tot += int(mm.group(1))
    return tot


def fetch_overture(cell, geo, work):
    path = work.p("raw", "overture.json.gz")
    if os.path.exists(path):
        return json.load(gzip.open(path))
    rel = cell["overture"]["release"]
    root = cell["overture"]["stacRoot"]
    coll = json.loads(http(f"{root}/{rel}/buildings/building/collection.json", work, "overture-stac"))
    s, w, n, e = geo["bbox_buildings"]
    bbs = coll["extent"]["spatial"]["bbox"][1:]
    items = [l["href"] for l in coll["links"] if l["rel"] == "item"]
    urls = []
    for i, b in enumerate(bbs):
        if b[2] < w or b[0] > e or b[3] < s or b[1] > n:
            continue
        href = items[i] if items[i].startswith("http") else f"{root}/{rel}/buildings/building/{items[i].lstrip('./')}"
        it = json.loads(http(href, work, "overture-stac"))
        ib = it["bbox"]
        if ib[2] < w or ib[0] > e or ib[3] < s or ib[1] > n:
            continue
        urls.append(it["assets"]["aws"]["href"])
    import duckdb
    con = duckdb.connect()
    con.execute(f"SET extension_directory='{work.p('duckdb-ext')}'")
    con.execute("INSTALL httpfs")
    con.execute("LOAD httpfs")
    con.execute("SET s3_region='us-west-2'")
    con.execute("CALL enable_logging('HTTP')")
    flist = "[" + ",".join(f"'{u}'" for u in urls) + "]"
    q = (f"SELECT id, height, num_floors, roof_shape, roof_color, roof_material, subtype, class, sources, "
         f"ST_AsWKB(geometry) AS wkb FROM read_parquet({flist}) "
         f"WHERE bbox.xmin <= {e} AND bbox.xmax >= {w} AND bbox.ymin <= {n} AND bbox.ymax >= {s}")
    try:
        rows = con.execute(q).fetchall()
    except Exception as ex:  # no ST_AsWKB without the spatial extension: read the raw WKB column
        log("[overture] falling back to raw geometry column:", str(ex)[:120])
        rows = con.execute(q.replace("ST_AsWKB(geometry)", "geometry")).fetchall()
    nbytes = _duck_http_bytes(con)
    recs = []
    for r in rows:
        recs.append({"id": r[0], "height": r[1], "num_floors": r[2], "roof_shape": r[3], "roof_color": r[4],
                     "roof_material": r[5], "subtype": r[6], "class": r[7],
                     "sources": [{"dataset": x.get("dataset"), "record_id": x.get("record_id")} for x in (r[8] or [])],
                     "wkb": bytes(r[9]).hex()})
    work.ledger_add("overture-parquet", f"{len(urls)} file(s), release {rel}", nbytes or 0)
    out = {"release": rel, "files": urls, "rows": recs, "bytesMeasured": nbytes is not None}
    with gzip.open(path, "wt") as f:
        json.dump(out, f)
    log(f"[overture] {len(recs)} rows from {len(urls)} file(s); {nbytes} bytes")
    return out


class _GdalBytes(logging.Handler):
    """Sums the byte ranges GDAL's /vsicurl/ reports in its debug log ("Downloading A-B")."""

    def __init__(self):
        super().__init__()
        self.ranges = []
        self.lines = []

    def emit(self, record):
        msg = record.getMessage()
        if "Downloading" in msg or "response_code" in msg:
            self.lines.append(msg[:200])
        for a, b in re.findall(r"Downloading (\d+)-(\d+)", msg):
            self.ranges.append((int(a), int(b)))

    def total(self):
        return sum(b - a + 1 for a, b in set(self.ranges))


def fetch_naip(cell, geo, work):
    tif = work.p("raw", "naip.tif")
    meta_path = work.p("raw", "naip.json")
    if os.path.exists(tif) and os.path.exists(meta_path):
        return json.load(open(meta_path))
    import rasterio
    from rasterio.windows import from_bounds
    lat, lon = cell["center"]
    body = json.dumps({"collections": [cell["naip"]["collection"]],
                       "intersects": {"type": "Point", "coordinates": [lon, lat]}, "limit": 100}).encode()
    res = json.loads(http(cell["naip"]["stacSearch"], work, "naip-stac", data=body,
                          headers={"Content-Type": "application/json"}))
    feats = [f for f in res["features"] if f["properties"].get("naip:state") == cell["naip"]["state"]]
    feats.sort(key=lambda f: f["properties"]["datetime"], reverse=True)
    item = feats[0]
    x0, y0, x1, y1 = geo["utm"]
    ib = item["properties"]["proj:bbox"]
    if not (ib[0] <= x0 and ib[1] <= y0 and ib[2] >= x1 and ib[3] >= y1):
        raise SystemExit("most recent NAIP item does not cover the whole cell; mosaicking is not implemented")
    token = json.loads(http(cell["naip"]["tokenEndpoint"], work, "naip-token"))["token"]
    href = item["assets"]["image"]["href"]
    handler = _GdalBytes()
    lg = logging.getLogger("rasterio")
    lg.setLevel(logging.DEBUG)
    lg.addHandler(handler)
    with rasterio.Env(CPL_DEBUG="ON", GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR",
                      CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif", GDAL_HTTP_MERGE_CONSECUTIVE_RANGES="YES",
                      GDAL_HTTP_USERAGENT=UA, VSI_CACHE="FALSE"):
        with rasterio.open(f"/vsicurl/{href}?{token}") as src:
            if src.crs.to_string() != cell["crs"]:
                raise SystemExit(f"unexpected CRS {src.crs}")
            win = from_bounds(x0, y0, x1, y1, src.transform).round_offsets().round_lengths()
            data = src.read(window=win)
            transform = src.window_transform(win)
            profile = {"driver": "GTiff", "dtype": data.dtype.name, "count": data.shape[0], "height": data.shape[1],
                       "width": data.shape[2], "crs": src.crs, "transform": transform, "compress": "deflate"}
            info = {"compression": str(src.compression), "blockShapes": src.block_shapes[:1],
                    "fullShape": [src.height, src.width], "dtype": data.dtype.name, "res": list(src.res),
                    "descriptions": list(src.descriptions), "tags": {k: v for k, v in src.tags().items()}}
    lg.removeHandler(handler)
    with rasterio.open(tif, "w", **profile) as dst:
        dst.write(data)
    work.ledger_add("naip-cog-ranges", href, handler.total())
    p = item["properties"]
    meta = {"item": item["id"], "href": href, "datetime": p["datetime"], "gsd": p.get("gsd"), "year": p.get("naip:year"),
            "state": p.get("naip:state"), "bands": ["red", "green", "blue", "nir"], "window": [int(win.col_off), int(win.row_off), int(win.width), int(win.height)],
            "windowShape": list(data.shape), "cog": info, "rangeBytes": handler.total(), "rangeRequests": len(set(handler.ranges)),
            "otherItems": [{"id": f["id"], "datetime": f["properties"]["datetime"], "gsd": f["properties"].get("gsd")} for f in feats[1:]]}
    json.dump(meta, open(meta_path, "w"), indent=1)
    json.dump(handler.lines, open(work.p("raw", "naip_gdal_log.json"), "w"), indent=0)
    log(f"[naip] {item['id']} window {data.shape}; {handler.total()} bytes in {len(set(handler.ranges))} range(s)")
    return meta


def cmd_fetch(args, work):
    cell = load("cell.json")
    geo = cell_geometry(cell)
    fetch_naip(cell, geo, work)
    fetch_osm(cell, geo, work)
    fetch_overture(cell, geo, work)
    tot = sum(x["bytes"] for x in work.ledger())
    log(f"[fetch] ledger total {tot} bytes")


# ---------------------------------------------------------------- footprints and image

def _to_utm(lonlat, crs):
    from rasterio.warp import transform
    xs, ys = transform("EPSG:4326", crs, [p[0] for p in lonlat], [p[1] for p in lonlat])
    return list(zip(xs, ys))


def osm_footprints(osm, crs):
    """OSM building polygons (UTM) with their OSM IDs. Relations: outer members merged and polygonized."""
    from shapely.geometry import LineString, Polygon
    from shapely.ops import linemerge, polygonize, unary_union
    out = []
    for e in osm["elements"]:
        tags = e.get("tags", {})
        if "building" not in tags:
            continue
        if e["type"] == "way" and len(e.get("geometry", [])) >= 4:
            pts = _to_utm([(g["lon"], g["lat"]) for g in e["geometry"]], crs)
            poly = Polygon(pts).buffer(0)
        elif e["type"] == "relation":
            lines = [LineString(_to_utm([(g["lon"], g["lat"]) for g in m["geometry"]], crs))
                     for m in e.get("members", []) if m.get("role") == "outer" and m.get("geometry")]
            polys = list(polygonize(linemerge(unary_union(lines)))) if lines else []
            if not polys:
                continue
            poly = max(polys, key=lambda p: p.area)
        else:
            continue
        if poly.is_empty:
            continue
        if poly.geom_type == "MultiPolygon":
            poly = max(poly.geoms, key=lambda p: p.area)
        out.append({"id": f"osm:{e['type']}/{e['id']}", "source": "osm", "poly": poly,
                    "osmTags": {k: tags[k] for k in ("building", "roof:shape", "roof:colour", "roof:material", "building:levels") if k in tags}})
    return out


def overture_footprints(ov, crs, osm_polys, drop_overlap):
    """Overture buildings with no OpenStreetMap source (Microsoft ML footprints here), minus OSM overlaps."""
    from shapely import wkb as swkb
    from shapely.geometry import Polygon
    from shapely.strtree import STRtree
    tree = STRtree([o["poly"] for o in osm_polys]) if osm_polys else None
    out, dropped = [], 0
    for r in ov["rows"]:
        datasets = sorted(set(s["dataset"] for s in r["sources"]))
        if "OpenStreetMap" in datasets:
            continue
        g = swkb.loads(bytes.fromhex(r["wkb"]))
        if g.geom_type == "MultiPolygon":
            g = max(g.geoms, key=lambda p: p.area)
        poly = Polygon(_to_utm(list(g.exterior.coords), crs)).buffer(0)
        if tree is not None:
            hit = False
            for i in tree.query(poly):
                o = osm_polys[int(i)]["poly"]
                if poly.intersection(o).area / max(min(poly.area, o.area), 1e-6) > drop_overlap:
                    hit = True
                    break
            if hit:
                dropped += 1
                continue
        out.append({"id": f"gers:{r['id']}", "source": "overture:" + "+".join(datasets), "poly": poly,
                    "height": r.get("height")})
    return out, dropped


def load_image(work, degrade_to=None):
    """NAIP window -> dict(bands float arrays, transform, res). Optional block-average to a coarser pixel."""
    import rasterio
    from affine import Affine
    with rasterio.open(work.p("raw", "naip.tif")) as s:
        a = s.read().astype(np.float64)
        tr = s.transform
    res = tr.a
    if degrade_to and degrade_to > res * 1.01:
        k = int(round(degrade_to / res))
        h, w = (a.shape[1] // k) * k, (a.shape[2] // k) * k
        a = a[:, :h, :w].reshape(a.shape[0], h // k, k, w // k, k).mean(axis=(2, 4))
        tr = tr * Affine.scale(k, k)
        res = tr.a
    return {"r": a[0], "g": a[1], "b": a[2], "n": a[3], "transform": tr, "res": res,
            "shape": a.shape[1:]}


def to_pixels(coords, tr):
    inv = ~tr
    return [inv * (x, y) for x, y in coords]


def rasterize_poly(poly, tr, shape, shift=(0.0, 0.0)):
    from rasterio.features import rasterize
    from shapely.affinity import translate
    p = translate(poly, xoff=shift[0], yoff=shift[1])
    return rasterize([(p, 1)], out_shape=shape, transform=tr, fill=0, dtype="uint8").astype(bool)


def global_alignment(img, buildings, search_m):
    """One (dx, dy) shift in metres for all footprints: maximises the mean luminance gradient on the
    footprint outlines (outlines should sit on roof edges). Relief displacement and digitising offsets differ
    per building, so this only removes the common part."""
    from rasterio.features import rasterize
    lum = rc.srgb_to_lab(np.dstack([img["r"], img["g"], img["b"]]))[..., 0]
    gy, gx = np.gradient(lum)
    grad = np.hypot(gx, gy)
    tr, res = img["transform"], img["res"]
    outlines = [b["poly"].exterior for b in buildings]
    base = rasterize([(o, 1) for o in outlines], out_shape=img["shape"], transform=tr, fill=0, dtype="uint8").astype(bool)
    rows, cols = np.nonzero(base)
    k = int(round(search_m / res))
    best, scores = None, {}
    h, w = img["shape"]
    for dy in range(-k, k + 1):
        for dx in range(-k, k + 1):
            rr, cc = rows + dy, cols + dx
            ok = (rr >= 0) & (rr < h) & (cc >= 0) & (cc < w)
            s = float(grad[rr[ok], cc[ok]].mean())
            scores[(dx, dy)] = s
            if best is None or s > best[0]:
                best = (s, dx, dy)
    s0 = scores[(0, 0)]
    _, dx, dy = best
    # pixel shift (dx right, dy down) -> metres (east, north)
    return {"dxPixels": dx, "dyPixels": dy, "eastMeters": round(dx * res, 2), "northMeters": round(-dy * res, 2),
            "gradientAtZero": round(s0, 3), "gradientAtBest": round(best[0], 3)}


def footprint_window(b, img, shift_m):
    """(shifted polygon, r0, c0, h, w) of the padded footprint window, or None if it leaves the image."""
    from rasterio.windows import from_bounds
    from shapely.affinity import translate
    tr, res = img["transform"], img["res"]
    poly = translate(b["poly"], xoff=shift_m[0], yoff=shift_m[1])
    minx, miny, maxx, maxy = poly.bounds
    pad = 3 * res + 1.0
    win = from_bounds(minx - pad, miny - pad, maxx + pad, maxy + pad, tr).round_offsets().round_lengths()
    r0, c0 = int(win.row_off), int(win.col_off)
    h, w = int(win.height), int(win.width)
    H, W = img["shape"]
    if r0 < 0 or c0 < 0 or r0 + h > H or c0 + w > W:
        return None
    return poly, r0, c0, h, w


def estimate_building(b, img, params, shift_m):
    """Per-building colour and roof-type estimate (values stay in the work directory)."""
    from affine import Affine
    fp, rp = params["footprint"], dict(params["roof"])
    tr, res = img["transform"], img["res"]
    min_px = max(4, int(round(fp["minUsableM2"] / res ** 2)))  # area thresholds, so 0.3 m and 0.6 m compare fairly
    rp["minPixels"] = max(4, int(round(rp["minUsableM2"] / res ** 2)))
    fw = footprint_window(b, img, shift_m)
    if fw is None:
        return {"status": "outside"}
    poly, r0, c0, h, w = fw
    sl = (slice(r0, r0 + h), slice(c0, c0 + w))
    wtr = tr * Affine.translation(c0, r0)
    mask = rasterize_poly(poly, wtr, (h, w))
    if mask.sum() < 4:
        return {"status": "tiny"}
    R, G, B, N = img["r"][sl], img["g"][sl], img["b"][sl], img["n"][sl]
    nd = rc.ndvi(R, N)
    veg = nd > fp["vegNdvi"]
    er = rc.erode(mask, max(1, int(round(fp["erosionMeters"] / res))))
    if er.sum() < 10:
        er = mask
    shadow = np.maximum(np.maximum(R, G), B) < fp["deepShadowMaxRgb"]
    usable = er & ~veg & ~shadow
    veg_share = float(veg[mask].mean())
    usable_share = float(usable.sum()) / max(int(er.sum()), 1)
    out = {"status": "ok", "vegShare": round(veg_share, 3), "usableShare": round(usable_share, 3),
           "mostlyHidden": veg_share > fp["mostlyHiddenVegShare"], "pixels": int(mask.sum())}
    rgb = np.dstack([R, G, B])
    if usable.sum() >= min_px and usable_share >= fp["minUsableShare"]:
        lab, hx = rc.robust_colour(rgb[usable])
        out["colour"] = {"hex": hx, "lab": [round(float(x), 1) for x in lab],
                         "family": rc.colour_family(lab, load_families()),
                         "confidence": round(min(1.0, usable_share / 0.8), 2)}
    else:
        out["colour"] = {"family": "unknown", "confidence": 0.0}
    ring_px = [(x - c0, y - r0) for x, y in to_pixels(list(poly.exterior.coords), tr)]
    shape_m = rc.shape_features(list(b["poly"].exterior.coords))
    rect = rc.min_area_rect(ring_px)
    lum = rc.srgb_to_lab(rgb)[..., 0]
    if usable_share >= fp["minUsableShare"]:
        typ, conf, diag = rc.classify_roof(lum, usable, rect, shape_m, rp)
    else:
        typ, conf, diag = "unknown", 0.0, {"validPixels": int(usable.sum())}
    out["roof"] = {"type": typ, "confidence": conf, "diag": diag}
    out["shape"] = {k: round(v, 3) for k, v in shape_m.items() if k != "rect"}
    return out


_FAM = []


def load_families():
    if not _FAM:
        _FAM.append(load("roof_families.json"))
    return _FAM[0]


def blocks(osm, geo, crs):
    """Block faces: polygonize OSM street centrelines (plus the cell outline) and clip to the cell."""
    from shapely.geometry import LineString, box
    from shapely.ops import polygonize, unary_union
    cell = box(*geo["utm"])
    lines = []
    for e in osm["elements"]:
        if e["type"] == "way" and "highway" in e.get("tags", {}) and len(e.get("geometry", [])) >= 2:
            lines.append(LineString(_to_utm([(g["lon"], g["lat"]) for g in e["geometry"]], crs)))
    noded = unary_union(lines + [cell.exterior])
    faces = []
    for f in polygonize(noded):
        c = f.intersection(cell)
        if c.is_empty or c.area < 50:
            continue
        # a complete block is bounded by streets only; faces closed by the cell outline are clipped edge blocks
        on_edge = f.exterior.intersection(cell.exterior.buffer(0.05)).length
        faces.append({"poly": c, "fullyInside": bool(on_edge < 1.0), "area": c.area})
    return faces, len(lines)


def cell_buildings(work, cell, geo, params):
    from shapely.geometry import box
    osm = json.load(open(work.p("raw", "overpass.json")))
    ov = json.load(gzip.open(work.p("raw", "overture.json.gz")))
    crs = cell["crs"]
    o = osm_footprints(osm, crs)
    m, dropped = overture_footprints(ov, crs, o, params["footprint"]["osmOverlapDrop"])
    cbox = box(*geo["utm"])
    allb = o + m
    keep = [b for b in allb if cbox.contains(b["poly"].centroid) and b["poly"].area >= params["minFootprintM2"]]
    stats = {"osmInQuery": len(o), "overtureNoOsmInQuery": len(m), "overtureDroppedAsOsmOverlap": dropped,
             "inCell": sum(1 for b in allb if cbox.contains(b["poly"].centroid)),
             "belowMinArea": sum(1 for b in allb if cbox.contains(b["poly"].centroid) and b["poly"].area < params["minFootprintM2"]),
             "kept": len(keep), "keptOsm": sum(1 for b in keep if b["source"] == "osm"),
             "keptOverture": sum(1 for b in keep if b["source"] != "osm")}
    return keep, stats, osm


def pct(values, qs=(0, 10, 25, 50, 75, 90, 100)):
    if not values:
        return None
    return {f"p{q}": round(float(np.percentile(values, q)), 3) for q in qs}


def dist(items, order=None):
    from collections import Counter
    c = Counter(items)
    n = sum(c.values())
    keys = order or sorted(c)
    keys = list(keys) + [k for k in sorted(c) if k not in keys]
    return {"n": n, "counts": {k: c.get(k, 0) for k in keys if c.get(k, 0) or order},
            "shares": {k: round(c.get(k, 0) / n, 3) if n else None for k in keys if c.get(k, 0) or order}}


def run_estimates(work, params, degrade=None):
    cell = load("cell.json")
    geo = cell_geometry(cell)
    builds, fstats, osm = cell_buildings(work, cell, geo, params)
    img = load_image(work, degrade)
    align = global_alignment(img, builds, params["alignSearchMeters"])
    shift = (align["eastMeters"], align["northMeters"])
    recs = []
    for b in builds:
        e = estimate_building(b, img, params, shift)
        e.update({"id": b["id"], "source": b["source"], "area": round(b["poly"].area, 1)})
        recs.append(e)
    # colour rule set 2: families relative to the scene's neutral roof colour (grey-world on roofs)
    labs = [r["colour"]["lab"] for r in recs if r.get("status") == "ok" and "lab" in r["colour"]]
    neutral = rc.scene_neutral(labs) if labs else (0.0, 0.0)
    rules2 = load_families()["sceneRelative"]
    for r in recs:
        if r.get("status") == "ok":
            lab = r["colour"].get("lab")
            r["colour"]["familyScene"] = rc.colour_family_relative(lab, neutral, rules2) if lab else "unknown"
    align["sceneNeutralAB"] = [round(neutral[0], 2), round(neutral[1], 2)]
    return cell, geo, builds, fstats, osm, img, align, recs


def cmd_analyse(args, work):
    params = load("params.json")
    fam = load_families()
    cell, geo, builds, fstats, osm, img, align, recs = run_estimates(work, params)
    json.dump(recs, open(work.p("buildings.json"), "w"), indent=0)  # per-building: work directory only
    # degraded-resolution run (0.6 m, block average of the same scene) for the resolution comparison
    _, _, _, _, _, _, align6, recs6 = run_estimates(work, params, params["degradedResolutionMeters"])
    json.dump(recs6, open(work.p("buildings_0p6.json"), "w"), indent=0)

    ok = [r for r in recs if r.get("status") == "ok"]
    order_fam = fam["order"] + ["unknown"]
    order_roof = ["flat", "gable", "hip", "complex", "unknown"]

    min_n = params["minGroupN"]  # privacy: statistics over fewer buildings are reported as a count only

    def colour_summary(rs):
        out = {}
        for key, name in (("family", "rules1Absolute"), ("familyScene", "rules2SceneRelative")):
            fams = [r["colour"].get(key, "unknown") for r in rs]
            palette = {}
            for f in fam["order"]:
                labs = [r["colour"]["lab"] for r in rs if r["colour"].get(key) == f]
                if labs:
                    med = np.median(np.array(labs), axis=0)
                    palette[f] = rc.suppress_small({"n": len(labs), "medianHex": rc.hex_from_rgb(rc.lab_to_srgb(med)),
                                                    "medianLab": [round(float(x), 1) for x in med]}, min_n)
            out[name] = {"families": dist(fams, order_fam), "medianColourPerFamily": palette}
        labs = [r["colour"]["lab"] for r in rs if "lab" in r["colour"]]
        if labs:
            arr = np.array(labs)
            out["allRoofs"] = rc.suppress_small(
                {"n": len(labs), "medianLab": [round(float(x), 1) for x in np.median(arr, axis=0)],
                 "medianHex": rc.hex_from_rgb(rc.lab_to_srgb(np.median(arr, axis=0))),
                 "lightnessPercentiles": pct(arr[:, 0].tolist()),
                 "chromaPercentiles": pct(np.hypot(arr[:, 1], arr[:, 2]).tolist())}, min_n)
        return out

    def roof_summary(rs):
        return dist([r["roof"]["type"] for r in rs], order_roof)

    groups = {"all": ok, "osmOnly": [r for r in ok if r["source"] == "osm"],
              "overtureOnly": [r for r in ok if r["source"] != "osm"],
              "main": [r for r in ok if r["area"] >= params["smallBuildingM2"]],
              "small": [r for r in ok if r["area"] < params["smallBuildingM2"]]}
    colour = {g: colour_summary(rs) for g, rs in groups.items()}
    roof = {g: roof_summary(rs) for g, rs in groups.items()}
    confident = {g: dist([r["roof"]["type"] for r in rs if r["roof"]["confidence"] >= params["hints"]["roofTypeMinConfidence"]], order_roof)
                 for g, rs in groups.items()}
    hidden = {g: {"n": len(rs), "mostlyHiddenByCanopy": sum(1 for r in rs if r["mostlyHidden"]),
                  "colourUnknown": sum(1 for r in rs if r["colour"]["family"] == "unknown"),
                  "vegShareInFootprint": pct([r["vegShare"] for r in rs]) if len(rs) >= min_n
                  else {"n": len(rs), "suppressed": f"n < {min_n}"}} for g, rs in groups.items()}

    # canopy
    veg, can = rc.canopy_mask(img["r"], img["n"], params["canopy"], img["res"])
    faces, nlines = blocks(osm, geo, cell["crs"])
    block_rows = []
    for f in faces:
        m = rasterize_poly(f["poly"], img["transform"], img["shape"])
        s = rc.share(can, m)
        if s is None:
            continue
        block_rows.append({"canopyPct": round(100 * s, 1), "vegetationPct": round(100 * rc.share(veg, m), 1),
                           "areaM2": round(f["area"]), "fullyInsideCell": f["fullyInside"]})
    block_rows.sort(key=lambda x: x["canopyPct"])
    full = [b for b in block_rows if b["fullyInsideCell"]]

    def block_stats(rows):
        if not rows:
            return None
        vals = [b["canopyPct"] for b in rows]
        areas = [b["areaM2"] for b in rows]
        hist = np.histogram(vals, bins=list(range(0, 101, 10)))[0].tolist()
        return {"n": len(rows), "areaWeightedMeanPct": round(float(np.average(vals, weights=areas)), 1),
                "meanPct": round(float(np.mean(vals)), 1), "percentiles": pct(vals),
                "histogram10pct": {f"{10 * i}-{10 * i + 10}": hist[i] for i in range(10)}}

    canopy = {"cellCanopyPct": round(100 * float(can.mean()), 1), "cellVegetationPct": round(100 * float(veg.mean()), 1),
              "streetWaysUsed": nlines, "blocksAll": block_stats(block_rows), "blocksFullyInside": block_stats(full),
              "blockValuesSorted": [{k: b[k] for k in ("canopyPct", "vegetationPct", "areaM2", "fullyInsideCell")} for b in block_rows],
              "method": "canopy = NDVI > %.2f AND NIR texture (std over vegetation pixels, %.1f m window) > %.0f DN, opening %.1f m, majority %.1f m"
                        % (params["canopy"]["vegNdvi"], params["canopy"]["textureRadiusMeters"], params["canopy"]["textureMinStd"],
                           params["canopy"]["openingRadiusMeters"], params["canopy"]["majorityRadiusMeters"])}
    np.save(work.p("canopy_mask.npy"), can)

    meta = json.load(open(work.p("raw", "naip.json")))
    ov = json.load(gzip.open(work.p("raw", "overture.json.gz")))
    osm_base = osm.get("osm3s", {}).get("timestamp_osm_base")
    led = work.ledger()
    summary = {
        "tool": TOOL_VERSION,
        "generated": dt.date.today().isoformat(),
        "privacy": "Aggregates only. Per-building estimates, crops and hand labels stay in the work directory outside the repository.",
        "cell": {"id": cell["id"], "sizeMeters": cell["sizeMeters"], "crs": cell["crs"], "anchor": "public park (see data/cell.json)"},
        "sources": {
            "imagery": {"dataset": "USDA NAIP via Microsoft Planetary Computer (STAC collection naip)", "item": meta["item"],
                        "acquired": meta["datetime"][:10], "gsdMeters": meta["gsd"], "bands": meta["bands"],
                        "licence": "Public domain (USDA FSA); credit requested: 'NAIP imagery provided by USDA Farm Service Agency'",
                        "otherItemsAtCell": meta["otherItems"]},
            "osm": {"timestampOsmBase": osm_base, "licence": "ODbL 1.0, (c) OpenStreetMap contributors"},
            "overture": {"release": ov["release"], "theme": "buildings", "licence": "ODbL 1.0 (Microsoft ML Buildings footprints)",
                         "files": len(ov["files"])},
        },
        "footprints": fstats,
        "alignment": {"fullResolution": align, "degraded0p6m": align6},
        "estimated": {"ok": len(ok), "notEstimated": len(recs) - len(ok)},
        "roofColour": colour,
        "roofType": roof,
        "roofTypeAtConfidence": {"threshold": params["hints"]["roofTypeMinConfidence"], **confident},
        "canopyOverRoofs": hidden,
        "canopy": canopy,
        "bytesDownloaded": {"total": sum(x["bytes"] for x in led),
                            "byKind": {k: sum(x["bytes"] for x in led if x["kind"] == k) for k in sorted(set(x["kind"] for x in led))},
                            "note": "Data requests only (measured response bodies; NAIP = sum of COG byte ranges from GDAL's log; Overture = DuckDB HTTP log). Python wheels and the DuckDB httpfs extension are listed in docs/research/aerial.md."},
    }
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    log(f"[analyse] {len(ok)} buildings estimated; canopy {canopy['cellCanopyPct']} %; results/summary.json written")


# ---------------------------------------------------------------- sample, crops, points

SETS = {"A": ("seed", "sample_key.json", "labels.json", "crops"),
        "B": ("seedB", "sample_key_B.json", "labels_B.json", "crops_B")}


def sample_ids(recs, params, which="A", exclude=()):
    """Stable random sample: at least minOsm OSM buildings (or all, if fewer), the rest Overture-only.
    Sample B is drawn with another seed from the buildings not in sample A."""
    sp = params["sample"]
    seed = sp[SETS[which][0]]
    elig = [r for r in recs if r.get("status") == "ok" and r["id"] not in set(exclude)]
    osm_ids = [r["id"] for r in elig if r["source"] == "osm"]
    other = [r["id"] for r in elig if r["source"] != "osm"]
    k_osm = min(len(osm_ids), max(sp["minOsm"], round(sp["n"] * len(osm_ids) / max(len(elig), 1))))
    chosen = rc.stable_sample(osm_ids, k_osm, seed) + rc.stable_sample(other, sp["n"] - k_osm, seed)
    return rc.stable_sample(chosen, len(chosen), seed + ":order")


def _draw_outline(im, ring, scale, colour):
    from PIL import ImageDraw
    d = ImageDraw.Draw(im)
    d.line([(x * scale, y * scale) for x, y in ring], fill=colour, width=2)


def cmd_crops(args, work):
    """Crops for hand labelling. Does not compute or show any estimate (labels are made blind)."""
    from PIL import Image, ImageDraw
    from shapely.affinity import translate
    params = load("params.json")
    cell = load("cell.json")
    geo = cell_geometry(cell)
    builds, _, _ = cell_buildings(work, cell, geo, params)
    img = load_image(work)
    align = global_alignment(img, builds, params["alignSearchMeters"])
    shift = (align["eastMeters"], align["northMeters"])
    # same eligibility as analyse (footprint window inside the image), without computing any estimate
    recs = [{"id": b["id"], "source": b["source"],
             "status": "ok" if footprint_window(b, img, shift) is not None else "outside"} for b in builds]
    which = args.set
    exclude = ()
    if which == "B":
        exclude = sample_ids(recs, params, "A")
    ids = sample_ids(recs, params, which, exclude)
    by_id = {b["id"]: b for b in builds}
    out_dir = os.path.dirname(work.p(SETS[which][3], "x"))
    prefix = "S" if which == "A" else "B"
    key = []
    tr, res = img["transform"], img["res"]
    rgb = np.dstack([img["r"], img["g"], img["b"]]).astype(np.uint8)
    cir = np.dstack([img["n"], img["r"], img["g"]]).astype(np.uint8)
    panels = []
    for i, bid in enumerate(ids):
        b = by_id[bid]
        poly = translate(b["poly"], xoff=shift[0], yoff=shift[1])
        minx, miny, maxx, maxy = poly.bounds
        m = 6.0
        inv = ~tr
        c0, r0 = inv * (minx - m, maxy + m)
        c1, r1 = inv * (maxx + m, miny - m)
        c0, r0, c1, r1 = max(0, int(c0)), max(0, int(r0)), min(rgb.shape[1], int(c1) + 1), min(rgb.shape[0], int(r1) + 1)
        scale = 300.0 / max(c1 - c0, r1 - r0)
        size = (int((c1 - c0) * scale), int((r1 - r0) * scale))
        ring = [(x - c0, y - r0) for x, y in to_pixels(list(poly.exterior.coords), tr)]
        a = Image.fromarray(rgb[r0:r1, c0:c1]).resize(size, Image.LANCZOS)
        bimg = a.copy()
        _draw_outline(bimg, ring, scale, (255, 255, 0))
        c = Image.fromarray(cir[r0:r1, c0:c1]).resize(size, Image.LANCZOS)
        _draw_outline(c, ring, scale, (255, 255, 0))
        panel = Image.new("RGB", (3 * 300 + 20, 320), (255, 255, 255))
        for j, p in enumerate((a, bimg, c)):
            panel.paste(p, (j * 310, 20))
        ImageDraw.Draw(panel).text((4, 4), f"{prefix}{i + 1:02d}  ({b['poly'].area:.0f} m2; scale bar = 5 m)", fill=(0, 0, 0))
        bar = 5.0 / res * scale
        ImageDraw.Draw(panel).line([(310 + 8, 312), (310 + 8 + bar, 312)], fill=(255, 0, 0), width=3)
        panels.append(panel)
        key.append({"sample": f"{prefix}{i + 1:02d}", "id": bid, "source": b["source"]})
    for s in range(0, len(panels), 3):
        sheet = Image.new("RGB", (panels[0].width, 330 * len(panels[s:s + 3])), (255, 255, 255))
        for j, p in enumerate(panels[s:s + 3]):
            sheet.paste(p, (0, j * 330))
        sheet.save(os.path.join(out_dir, f"sheet_{s // 3 + 1:02d}.png"))
    json.dump(key, open(work.p(SETS[which][1]), "w"), indent=1)
    log(f"[crops] {len(ids)} buildings ({sum(1 for k in key if k['source'] == 'osm')} OSM) -> {out_dir}")


def point_sample(params, shape, seed, n):
    pts = []
    i = 0
    h, w = shape
    while len(pts) < n:
        hsh = hashlib.sha256(f"{seed}:{i}".encode()).digest()
        r = int.from_bytes(hsh[:4], "big") % h
        c = int.from_bytes(hsh[4:8], "big") % w
        pts.append((r, c))
        i += 1
    return pts


def cmd_points(args, work):
    """Contact sheets of random points (crosshair at the point) for a photo-interpreted canopy check."""
    from PIL import Image, ImageDraw
    params = load("params.json")
    img = load_image(work)
    rgb = np.dstack([img["r"], img["g"], img["b"]]).astype(np.uint8)
    pts = point_sample(params, img["shape"], params["sample"]["pointSeed"], params["sample"]["points"])
    half = int(round(7.5 / img["res"]))
    tiles = []
    for k, (r, c) in enumerate(pts):
        pad = np.pad(rgb, ((half, half), (half, half), (0, 0)), mode="constant")
        t = Image.fromarray(pad[r:r + 2 * half + 1, c:c + 2 * half + 1]).resize((200, 200), Image.LANCZOS)
        d = ImageDraw.Draw(t)
        d.line([(100, 80), (100, 94)], fill=(255, 0, 0), width=1)
        d.line([(100, 106), (100, 120)], fill=(255, 0, 0), width=1)
        d.line([(80, 100), (94, 100)], fill=(255, 0, 0), width=1)
        d.line([(106, 100), (120, 100)], fill=(255, 0, 0), width=1)
        d.text((3, 3), f"P{k + 1:03d}", fill=(255, 255, 255))
        tiles.append(t)
    for s in range(0, len(tiles), 25):
        sheet = Image.new("RGB", (5 * 205, 5 * 205), (255, 255, 255))
        for j, t in enumerate(tiles[s:s + 25]):
            sheet.paste(t, ((j % 5) * 205, (j // 5) * 205))
        sheet.save(work.p("points", f"points_{s // 25 + 1}.png"))
    json.dump([{"point": f"P{k + 1:03d}", "row": r, "col": c} for k, (r, c) in enumerate(pts)],
              open(work.p("points_key.json"), "w"), indent=0)
    log(f"[points] {len(pts)} points -> {work.p('points')}")


# ---------------------------------------------------------------- scoring

def _label_rows(work, which, recs, fam_v1):
    labels_path = work.p(SETS[which][2])
    key_path = work.p(SETS[which][1])
    if not (os.path.exists(labels_path) and os.path.exists(key_path)):
        return None
    labels = json.load(open(labels_path))
    key = {k["id"]: k for k in json.load(open(key_path))}
    labelled = {lab["id"] for lab in labels["buildings"]}
    if labelled != set(key):
        raise SystemExit(f"labels for sample {which} do not match its key ({len(set(key) - labelled)} unlabelled)")
    rows = []
    for lab in labels["buildings"]:
        k = key[lab["id"]]
        r = recs.get(k["id"], {})
        col = r.get("colour") or {}
        lab_val = col.get("lab")
        rows.append({"set": which, "source": k["source"], "area": r.get("area", 0.0),
                     "lc": lab["colour"], "lt": lab["roofType"],
                     "pc": col.get("family", "unknown"),
                     "pc1": rc.colour_family(lab_val, fam_v1) if lab_val else "unknown",
                     "pc2": col.get("familyScene", "unknown"),
                     "pt": (r.get("roof") or {}).get("type", "unknown"),
                     "pconf": (r.get("roof") or {}).get("confidence", 0.0),
                     "hidden": lab.get("mostlyHidden", False)})
    return rows


NEAR = {frozenset(p) for p in (("black", "charcoal"), ("charcoal", "grey"), ("grey", "white"), ("brown", "tan"), ("brown", "red"))}


def _acc(rows, lk, pk, order, near=False):
    """Accuracy block: excluding can't-tell labels (estimate 'unknown' = wrong), where both answered,
    and including can't-tell labels (can't-tell = not correct); confusion matrix truth x predicted."""
    told = [x for x in rows if x[lk] != "cant_tell"]
    both = [x for x in told if x[pk] != "unknown"]
    cm, a1, c1, n1 = rc.confusion([(x[lk], x[pk]) for x in told], order + ["unknown"])
    _, a2, c2, n2 = rc.confusion([(x[lk], x[pk]) for x in both], order)
    c_all = sum(1 for x in told if x[lk] == x[pk])
    out = {
        "labelledCantTell": len(rows) - len(told),
        "estimateUnknown": sum(1 for x in rows if x[pk] == "unknown"),
        "excludingCantTell": {"correct": c1, "n": n1, "pct": round(100 * a1, 1) if a1 is not None else None},
        "whereBothAnswered": {"correct": c2, "n": n2, "pct": round(100 * a2, 1) if a2 is not None else None},
        "includingCantTell": {"correct": c_all, "n": len(rows), "pct": round(100 * c_all / len(rows), 1) if rows else None},
        "confusion_truthRows_predictedColumns": {t: {p: v for p, v in row.items() if v} for t, row in cm.items() if any(row.values())},
    }
    if near:
        nm = sum(1 for x in both if x[lk] != x[pk] and frozenset((x[lk], x[pk])) in NEAR)
        # same denominator as excludingCantTell (estimate 'unknown' counts as wrong), so the two compare directly
        out["withNeighbourFamilies"] = {"correct": c2 + nm, "n": n1, "pct": round(100 * (c2 + nm) / n1, 1) if n1 else None,
                                        "neighbours": "black/charcoal, charcoal/grey, grey/white, brown/tan, brown/red"}
    return out


def _evaluate(rows, params, fam_order):
    roof_order = ["flat", "gable", "hip", "complex"]
    thr = params["hints"]["roofTypeMinConfidence"]
    small = params["smallBuildingM2"]
    res = {"n": len(rows), "osm": sum(1 for x in rows if x["source"] == "osm"),
           "mostlyHiddenByCanopyLabelled": sum(1 for x in rows if x["hidden"]),
           "colourRules1Absolute": _acc(rows, "lc", "pc", fam_order, near=True),
           "colourRules1WithoutDarkRule": _acc(rows, "lc", "pc1", fam_order, near=True)["excludingCantTell"],
           "colourRules2SceneRelative": _acc(rows, "lc", "pc2", fam_order, near=True),
           "roofType": _acc(rows, "lt", "pt", roof_order)}
    hi = [x for x in rows if x["lt"] != "cant_tell" and x["pt"] != "unknown" and x["pconf"] >= thr]
    lo = [x for x in rows if x["lt"] != "cant_tell" and x["pt"] != "unknown" and x["pconf"] < thr]
    res["roofType"]["byConfidence"] = {
        "threshold": thr,
        "atOrAbove": {"n": len(hi), "correct": sum(1 for x in hi if x["lt"] == x["pt"])},
        "below": {"n": len(lo), "correct": sum(1 for x in lo if x["lt"] == x["pt"])}}
    for name, sel in (("smallUnder%dm2" % small, lambda x: x["area"] < small), ("mainAtLeast%dm2" % small, lambda x: x["area"] >= small)):
        sub = [x for x in rows if sel(x) and x["lt"] != "cant_tell"]
        res["roofType"][name] = {"n": len(sub), "correct": sum(1 for x in sub if x["lt"] == x["pt"])}
    for key, lk in (("roofType", "lt"), ("colourRules1Absolute", "lc"), ("colourRules2SceneRelative", "lc")):
        told = [x[lk] for x in rows if x[lk] != "cant_tell"]
        if told:
            top = max(sorted(set(told)), key=told.count)
            res[key]["majorityBaseline"] = {"alwaysPredict": top, "correct": told.count(top), "n": len(told),
                                            "pct": round(100 * told.count(top) / len(told), 1),
                                            "note": "trivial baseline from the label distribution itself"}
    res["roofType"]["labelDistribution"] = dist([x["lt"] for x in rows], roof_order + ["cant_tell"])
    res["roofType"]["predictedDistribution"] = dist([x["pt"] for x in rows], roof_order + ["unknown"])
    res["colourLabelDistribution"] = dist([x["lc"] for x in rows], fam_order + ["cant_tell"])
    osm_rows = [x for x in rows if x["source"] == "osm"]
    res["osmOnly"] = {
        "n": len(osm_rows),
        "colourRules1": {"correct": sum(1 for x in osm_rows if x["lc"] != "cant_tell" and x["lc"] == x["pc"]),
                         "labelled": sum(1 for x in osm_rows if x["lc"] != "cant_tell")},
        "colourRules2": {"correct": sum(1 for x in osm_rows if x["lc"] != "cant_tell" and x["lc"] == x["pc2"]),
                         "labelled": sum(1 for x in osm_rows if x["lc"] != "cant_tell")},
        "roofType": {"correct": sum(1 for x in osm_rows if x["lt"] != "cant_tell" and x["lt"] == x["pt"]),
                     "labelled": sum(1 for x in osm_rows if x["lt"] != "cant_tell")}}
    return res


def cmd_score(args, work):
    params = load("params.json")
    fam = load_families()
    fam_v1 = {k: v for k, v in fam.items() if k != "darkAchromatic"}  # rule set before the post-hoc dark rule
    out = {"tool": TOOL_VERSION, "generated": dt.date.today().isoformat(),
           "caveat": "Hand labels are visual judgments by the same AI agent from the same 0.3 m NAIP imagery (crops with "
                     "the footprint outline, RGB and colour-infrared), made before looking at any estimate. They are "
                     "uncertain and not ground truth; colour agreement in particular measures agreement on family "
                     "boundaries for the same pixels, not true roof colour.",
           "protocol": "Sample A (30) was labelled and scored with the a-priori rules. Colour rule set 2 (scene-relative) "
                       "was then designed on sample A, so its sample-A score is optimistic; sample B (30 more, other seed, "
                       "labelled blind before rule set 2 was applied to it) is the honest test of rule set 2. Roof-type and "
                       "colour rule set 1 never changed after scoring, so A+B pooled is a fair test for them."}
    for tag, fname in (("0.3m", "buildings.json"), ("0.6m_degraded", "buildings_0p6.json")):
        recs = {r["id"]: r for r in json.load(open(work.p(fname)))}
        sets = {w: _label_rows(work, w, recs, fam_v1) for w in ("A", "B")}
        res = {}
        for w, rows in sets.items():
            if rows:
                res["sample" + w] = _evaluate(rows, params, fam["order"])
        if sets.get("A") and sets.get("B"):
            res["pooledAB"] = _evaluate(sets["A"] + sets["B"], params, fam["order"])
            res["pooledAB"]["note"] = "colourRules2SceneRelative pooled includes the design sample A (optimistic); use sampleB for rule set 2"
        out[tag] = res
    # canopy point check
    if os.path.exists(work.p("points_labels.json")):
        pl = json.load(open(work.p("points_labels.json")))
        pk = {p["point"]: p for p in json.load(open(work.p("points_key.json")))}
        can = np.load(work.p("canopy_mask.npy"))
        pairs = []
        for p in pl["points"]:
            if p["tree"] == "cant_tell":
                continue
            k = pk[p["point"]]
            pairs.append((bool(p["tree"]), bool(can[k["row"], k["col"]])))
        n = len(pairs)
        tp = sum(1 for t, m in pairs if t and m)
        tn = sum(1 for t, m in pairs if not t and not m)
        fp_ = sum(1 for t, m in pairs if not t and m)
        fn = sum(1 for t, m in pairs if t and not m)
        p_hat = (tp + fn) / n
        se = math.sqrt(p_hat * (1 - p_hat) / n)
        out["canopyPointCheck"] = {
            "points": len(pl["points"]), "cantTell": len(pl["points"]) - n, "n": n,
            "agreementPct": round(100 * (tp + tn) / n, 1),
            "confusion": {"treeLabel_maskTree": tp, "treeLabel_maskNot": fn, "notTreeLabel_maskTree": fp_, "notTreeLabel_maskNot": tn},
            "photoInterpretedCanopyPct": round(100 * p_hat, 1),
            "ci95Pct": [round(100 * (p_hat - 1.96 * se), 1), round(100 * (p_hat + 1.96 * se), 1)],
            "maskCanopyAtPointsPct": round(100 * (tp + fp_) / n, 1),
            "note": "Same-agent photo interpretation of 15 m patches with a crosshair (i-Tree Canopy style random points); normal-approximation 95 % interval.",
        }
    with open(os.path.join(RESULTS, "accuracy.json"), "w") as f:
        json.dump(out, f, indent=1)
    log("[score] results/accuracy.json written")


# ---------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["fetch", "analyse", "crops", "points", "score", "all"])
    ap.add_argument("--work", default=os.environ.get("AERIAL_WORK") or os.path.join(tempfile.gettempdir(), "worldengine-aerial"))
    ap.add_argument("--set", choices=["A", "B"], default="A", help="which labelling sample `crops` draws (B excludes A)")
    args = ap.parse_args()
    work = Work(args.work)
    if args.command in ("fetch", "all"):
        cmd_fetch(args, work)
    if args.command in ("analyse", "all"):
        cmd_analyse(args, work)
    if args.command == "crops":
        cmd_crops(args, work)
    if args.command == "points":
        cmd_points(args, work)
    if args.command == "score" or (args.command == "all" and os.path.exists(work.p("labels.json"))):
        cmd_score(args, work)


if __name__ == "__main__":
    main()
