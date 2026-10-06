#!/usr/bin/env python3
"""Tree-canopy share per committed test area from NAIP (same canopy method as the Wilmette study).

For the profiles' `trees.canopyShare`. Offline research tool; nothing here is loaded at runtime.
Reuses aerial.py's NAIP access (Planetary Computer STAC, anonymous SAS token, windowed COG reads via GDAL
/vsicurl/, byte ledger) and roofcore.canopy_mask, blocks and shares. Streets, parks and water come from the
committed area's osm.json, so no Overpass request is made.

  fetch     windowed NAIP read per area (work directory)
  analyse   canopy mask, area / land / residential-fabric shares, block faces -> results/canopy_areas.json
  points    50 stable random points per area as contact sheets for a photo check (work directory)
  score     point labels (work/<area>/points_labels.json) vs the mask -> added to results/canopy_areas.json

Run from the repository root (see README.md); --work must be outside the repository.
"""

import argparse
import datetime as dt
import hashlib
import json
import logging
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import aerial  # noqa: E402
import roofcore as rc  # noqa: E402

REPO = aerial.REPO
CFG_NAME = "canopy_areas.json"


def area_manifest(a):
    with open(os.path.join(REPO, a["area"], "manifest.json")) as f:
        return json.load(f)


def geometry(a, man):
    """Area rectangle in the NAIP UTM grid (centre and size from the manifest) and its WGS84 box."""
    from rasterio.warp import transform
    lat, lon = man["center"]["latitude"], man["center"]["longitude"]
    xs, ys = transform("EPSG:4326", a["crs"], [lon], [lat])
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    utm = (xs[0] - hw, ys[0] - hh, xs[0] + hw, ys[0] + hh)
    lons, lats = transform(a["crs"], "EPSG:4326", [utm[0], utm[2], utm[2], utm[0]], [utm[1], utm[1], utm[3], utm[3]])
    return {"utm": utm, "wgs": (min(lons), min(lats), max(lons), max(lats))}


def fetch_area(a, cfg, work):
    """Newest NAIP year at the area; one item if it covers the rectangle, else a mosaic of that year's items."""
    import rasterio
    from rasterio.windows import from_bounds
    wdir = os.path.join("areas", a["id"])
    tif, meta_path = work.p(wdir, "naip.tif"), work.p(wdir, "naip.json")
    if os.path.exists(tif) and os.path.exists(meta_path):
        return json.load(open(meta_path))
    man = area_manifest(a)
    geo = geometry(a, man)
    body = json.dumps({"collections": [cfg["collection"]], "bbox": list(geo["wgs"]), "limit": 200}).encode()
    res = json.loads(aerial.http(cfg["stacSearch"], work, "naip-stac", data=body, headers={"Content-Type": "application/json"}))
    feats = [f for f in res["features"] if f["properties"].get("naip:state") == a["state"]]
    years = sorted({f["properties"].get("naip:year") for f in feats}, reverse=True)
    newest = [f for f in feats if f["properties"].get("naip:year") == years[0]]
    x0, y0, x1, y1 = geo["utm"]

    def covers(f, full=True):
        b = f["properties"]["proj:bbox"]
        if full:
            return b[0] <= x0 and b[1] <= y0 and b[2] >= x1 and b[3] >= y1
        return not (b[2] <= x0 or b[0] >= x1 or b[3] <= y0 or b[1] >= y1)
    whole = [f for f in newest if covers(f) and f["properties"].get("proj:epsg") == int(a["crs"].split(":")[1])]
    items = [sorted(whole, key=lambda f: f["properties"]["datetime"], reverse=True)[0]] if whole else \
        sorted([f for f in newest if covers(f, False)], key=lambda f: f["properties"]["datetime"], reverse=True)
    token = json.loads(aerial.http(cfg["tokenEndpoint"], work, "naip-token"))["token"]
    handler = aerial._GdalBytes()
    lg = logging.getLogger("rasterio")
    lg.setLevel(logging.DEBUG)
    lg.addHandler(handler)
    mosaic, transform_out, used = None, None, []
    with rasterio.Env(CPL_DEBUG="ON", GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif",
                      GDAL_HTTP_MERGE_CONSECUTIVE_RANGES="YES", GDAL_HTTP_USERAGENT=aerial.UA, VSI_CACHE="FALSE"):
        for it in items:
            href = it["assets"]["image"]["href"]
            with rasterio.open(f"/vsicurl/{href}?{token}") as src:
                if src.crs.to_string() != a["crs"]:
                    raise SystemExit(f"{it['id']}: unexpected CRS {src.crs} (expected {a['crs']})")
                if mosaic is None:
                    win = from_bounds(x0, y0, x1, y1, src.transform).round_offsets().round_lengths()
                    transform_out = src.window_transform(win)
                    mosaic = np.zeros((4, int(win.height), int(win.width)), dtype=np.uint8)
                    filled = np.zeros(mosaic.shape[1:], dtype=bool)
                    res_m = src.res[0]
                win = from_bounds(x0, y0, x1, y1, src.transform).round_offsets().round_lengths()
                data = src.read(window=win, boundless=True, fill_value=0)
                if data.shape != mosaic.shape:
                    raise SystemExit(f"{it['id']}: window shape {data.shape} differs from {mosaic.shape} (resolution change)")
                valid = data.any(axis=0) & ~filled
                mosaic[:, valid] = data[:, valid]
                filled |= valid
                used.append({"id": it["id"], "datetime": it["properties"]["datetime"], "gsd": it["properties"].get("gsd"),
                             "pixels": int(valid.sum())})
            if filled.all():
                break
    lg.removeHandler(handler)
    profile = {"driver": "GTiff", "dtype": "uint8", "count": 4, "height": mosaic.shape[1], "width": mosaic.shape[2],
               "crs": a["crs"], "transform": transform_out, "compress": "deflate"}
    with rasterio.open(tif, "w", **profile) as dst:
        dst.write(mosaic)
    work.ledger_add("naip-cog-ranges", f"{a['id']}: " + ", ".join(u["id"] for u in used), handler.total())
    meta = {"area": a["id"], "items": used, "year": years[0], "gsdMeters": res_m, "unfilledPixels": int((~filled).sum()),
            "windowShape": list(mosaic.shape), "rangeBytes": handler.total(), "rangeRequests": len(set(handler.ranges)),
            "olderYearsAtArea": years[1:]}
    json.dump(meta, open(meta_path, "w"), indent=1)
    aerial.log(f"[naip] {a['id']}: {len(used)} item(s) {[u['id'] for u in used]}, {handler.total():,} bytes")
    return meta


# ---------------------------------------------------------------- OSM (committed area file)


def osm_layers(a, cfg, crs):
    """Street centrelines, park polygons and water polygons (UTM) from the committed osm.json."""
    from rasterio.warp import transform
    from shapely.geometry import LineString, Polygon
    from shapely.ops import polygonize, unary_union
    with open(os.path.join(REPO, a["area"], "osm.json")) as f:
        osm = json.load(f)
    nodes = {e["id"]: (e["lon"], e["lat"]) for e in osm["elements"] if e["type"] == "node"}
    ways = {e["id"]: e for e in osm["elements"] if e["type"] == "way"}

    def utm(ids):
        pts = [nodes[i] for i in ids if i in nodes]
        if len(pts) < 2:
            return []
        xs, ys = transform("EPSG:4326", crs, [p[0] for p in pts], [p[1] for p in pts])
        return list(zip(xs, ys))

    def matches(tags, table):
        for k, vals in table.items():
            if k in tags and (not vals or tags[k] in vals):
                return True
        return False
    streets, parks, water = [], [], []
    for w in ways.values():
        t = w.get("tags", {})
        if t.get("highway") in cfg["streetClasses"]:
            c = utm(w["nodes"])
            if len(c) >= 2:
                streets.append(LineString(c))
        closed = len(w["nodes"]) >= 4 and w["nodes"][0] == w["nodes"][-1]
        if closed and (matches(t, cfg["parkTags"]) or matches(t, cfg["waterTags"])):
            c = utm(w["nodes"])
            if len(c) >= 4:
                p = Polygon(c).buffer(0)
                (water if matches(t, cfg["waterTags"]) else parks).append(p)
    for r in (e for e in osm["elements"] if e["type"] == "relation"):
        t = r.get("tags", {})
        if t.get("type") != "multipolygon" or not (matches(t, cfg["parkTags"]) or matches(t, cfg["waterTags"])):
            continue
        outer = [LineString(utm(ways[m["ref"]]["nodes"])) for m in r["members"]
                 if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways and len(utm(ways[m["ref"]]["nodes"])) >= 2]
        inner = [LineString(utm(ways[m["ref"]]["nodes"])) for m in r["members"]
                 if m["type"] == "way" and m.get("role") == "inner" and m["ref"] in ways and len(utm(ways[m["ref"]]["nodes"])) >= 2]
        if not outer:
            continue
        poly = unary_union(list(polygonize(unary_union(outer))))
        if inner:
            poly = poly.difference(unary_union(list(polygonize(unary_union(inner)))))
        (water if matches(t, cfg["waterTags"]) else parks).append(poly)
    parks = [p for p in parks if p.area >= cfg.get("parkMinAreaM2", 0)]
    return streets, parks, water, osm.get("osm3s", {}).get("timestamp_osm_base")


def block_faces(streets, utm_box):
    from shapely.geometry import box
    from shapely.ops import polygonize, unary_union
    cell = box(*utm_box)
    faces = []
    for f in polygonize(unary_union(streets + [cell.exterior])):
        c = f.intersection(cell)
        if c.is_empty or c.area < 50:
            continue
        on_edge = f.exterior.intersection(cell.exterior.buffer(0.05)).length
        faces.append({"poly": c, "fullyInside": bool(on_edge < 1.0), "area": c.area})
    return faces


def mask_of(polys, tr, shape):
    from rasterio.features import rasterize
    polys = [p for p in polys if not p.is_empty]
    if not polys:
        return np.zeros(shape, dtype=bool)
    return rasterize([(p, 1) for p in polys], out_shape=shape, transform=tr, fill=0, dtype="uint8").astype(bool)


def block_stats(rows):
    if not rows:
        return None
    vals = [b["canopyPct"] for b in rows]
    areas = [b["areaM2"] for b in rows]
    return {"n": len(rows), "areaM2": round(sum(areas)), "areaWeightedMeanPct": round(float(np.average(vals, weights=areas)), 1),
            "meanPct": round(float(np.mean(vals)), 1),
            "percentiles": {f"p{q}": round(float(np.percentile(vals, q)), 1) for q in (10, 25, 50, 75, 90)}}


def analyse_area(a, cfg, params, work):
    import rasterio
    wdir = os.path.join("areas", a["id"])
    meta = json.load(open(work.p(wdir, "naip.json")))
    with rasterio.open(work.p(wdir, "naip.tif")) as s:
        img = s.read().astype(np.float64)
        tr = s.transform
    res = tr.a
    valid = img.any(axis=0)
    veg, can = rc.canopy_mask(img[0], img[3], params["canopy"], res)
    man = area_manifest(a)
    geo = geometry(a, man)
    streets, parks, water, osm_ts = osm_layers(a, cfg, a["crs"])
    shape = can.shape
    park_m = mask_of(parks, tr, shape) & valid
    water_m = mask_of(water, tr, shape) & valid
    land = valid & ~water_m
    fabric = land & ~park_m

    def pct(mask, region):
        s = rc.share(mask, region)
        return None if s is None else round(100 * s, 1)
    faces = block_faces(streets, geo["utm"])
    rows = []
    for f in faces:
        m = mask_of([f["poly"]], tr, shape) & valid
        fm = m & fabric
        if m.sum() == 0:
            continue
        rows.append({"canopyPct": pct(can, m), "areaM2": round(f["area"]), "fullyInside": f["fullyInside"],
                     "parkOrWaterSharePct": round(100 * float((m & ~fabric).sum()) / float(m.sum()), 1),
                     "fabricCanopyPct": pct(can, fm) if fm.sum() else None})
    big = [r for r in rows if r["areaM2"] >= cfg["blockMinAreaM2"]]
    resid = [r for r in big if r["parkOrWaterSharePct"] < 10]
    np.save(work.p(wdir, "canopy_mask.npy"), can)
    return {
        "profile": a["profile"],
        "naip": {"items": [{k: u[k] for k in ("id", "datetime", "gsd")} for u in meta["items"]], "year": meta["year"],
                 "gsdMeters": meta["gsdMeters"], "olderYearsAtArea": meta["olderYearsAtArea"],
                 "unfilledPixels": meta["unfilledPixels"], "rangeBytes": meta["rangeBytes"]},
        "areaM2": round(float(valid.sum()) * res * res),
        "canopyPct": {"wholeArea": pct(can, valid), "land": pct(can, land), "fabricExclParksWater": pct(can, fabric),
                      "inParks": pct(can, park_m) if park_m.sum() else None},
        "vegetationPct": {"wholeArea": pct(veg, valid), "fabricExclParksWater": pct(veg, fabric)},
        "coverPct": {"parks": round(100 * float(park_m.sum()) / float(valid.sum()), 1),
                     "water": round(100 * float(water_m.sum()) / float(valid.sum()), 1)},
        "blocks": {"all": block_stats(rows), "fullyInside": block_stats([r for r in rows if r["fullyInside"]]),
                   "atLeast1ha": block_stats(big), "atLeast1haResidential": block_stats(resid),
                   "note": "faces of OSM street centrelines incl. half the right-of-way; 'residential' = faces of >= 1 ha with < 10 % park or water"},
        "osmTimestamp": osm_ts,
    }


# ---------------------------------------------------------------- points (photo check)


def point_sample(seed, shape, n, valid):
    pts, i = [], 0
    h, w = shape
    while len(pts) < n:
        hsh = hashlib.sha256(f"{seed}:{i}".encode()).digest()
        r, c = int.from_bytes(hsh[:4], "big") % h, int.from_bytes(hsh[4:8], "big") % w
        i += 1
        if valid[r, c]:
            pts.append((r, c))
    return pts


def cmd_points(args, cfg, params, work):
    import rasterio
    from PIL import Image, ImageDraw
    for a in selected(cfg, args):
        wdir = os.path.join("areas", a["id"])
        with rasterio.open(work.p(wdir, "naip.tif")) as s:
            img = s.read()
            res = s.transform.a
        rgb = np.dstack([img[0], img[1], img[2]]).astype(np.uint8)
        pts = point_sample(f"worldengine-canopy-points-{a['id']}", rgb.shape[:2], args.n, img.any(axis=0))
        half = int(round(7.5 / res))
        pad = np.pad(rgb, ((half, half), (half, half), (0, 0)), mode="constant")
        tiles = []
        for k, (r, c) in enumerate(pts):
            t = Image.fromarray(pad[r:r + 2 * half + 1, c:c + 2 * half + 1]).resize((200, 200), Image.LANCZOS)
            d = ImageDraw.Draw(t)
            for seg in (((100, 80), (100, 94)), ((100, 106), (100, 120)), ((80, 100), (94, 100)), ((106, 100), (120, 100))):
                d.line(seg, fill=(255, 0, 0), width=1)
            d.text((3, 3), f"P{k + 1:02d}", fill=(255, 255, 255))
            tiles.append(t)
        for s0 in range(0, len(tiles), 25):
            sheet = Image.new("RGB", (5 * 205, 5 * 205), (255, 255, 255))
            for j, t in enumerate(tiles[s0:s0 + 25]):
                sheet.paste(t, ((j % 5) * 205, (j // 5) * 205))
            sheet.save(work.p(wdir, "points", f"points_{s0 // 25 + 1}.png"))
        json.dump([{"point": f"P{k + 1:02d}", "row": r, "col": c} for k, (r, c) in enumerate(pts)],
                  open(work.p(wdir, "points_key.json"), "w"), indent=0)
        aerial.log(f"[points] {a['id']}: {len(pts)} points")


def score_area(a, work):
    """Labels: {"P01": "tree" | "not" | "?"} in work/areas/<id>/points_labels.json."""
    wdir = os.path.join("areas", a["id"])
    path = work.p(wdir, "points_labels.json")
    if not os.path.exists(path):
        return None
    labels = json.load(open(path))
    key = json.load(open(work.p(wdir, "points_key.json")))
    can = np.load(work.p(wdir, "canopy_mask.npy"))
    m = {"tree": {"tree": 0, "not": 0}, "not": {"tree": 0, "not": 0}}
    unread = 0
    for k in key:
        lab = labels.get(k["point"], "?")
        if lab not in m:
            unread += 1
            continue
        m[lab]["tree" if can[k["row"], k["col"]] else "not"] += 1
    n = sum(m[a_][b] for a_ in m for b in m[a_])
    agree = m["tree"]["tree"] + m["not"]["not"]
    trees = m["tree"]["tree"] + m["tree"]["not"]
    from math import sqrt
    p = trees / n if n else None
    ci = None
    if n:
        z = 1.96
        den = 1 + z * z / n
        c = (p + z * z / (2 * n)) / den
        h = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
        ci = [round(100 * (c - h), 1), round(100 * (c + h), 1)]
    return {"n": n, "cantTell": unread, "confusion(label->mask)": m, "agreementPct": round(100 * agree / n, 1) if n else None,
            "labelCanopyPct": round(100 * p, 1) if n else None, "labelCanopy95ciPct": ci,
            "maskCanopyAtPointsPct": round(100 * (m["tree"]["tree"] + m["not"]["tree"]) / n, 1) if n else None}


def selected(cfg, args):
    return [a for a in cfg["areas"] if not args.only or a["id"] in args.only]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["fetch", "analyse", "points", "score"])
    ap.add_argument("--work", required=True)
    ap.add_argument("--only", nargs="*")
    ap.add_argument("--n", type=int, default=50, help="points per area for the photo check")
    args = ap.parse_args()
    work = aerial.Work(args.work)
    cfg = aerial.load(CFG_NAME)
    params = aerial.load("params.json")
    out_path = os.path.join(aerial.RESULTS, "canopy_areas.json")
    if args.command == "fetch":
        for a in selected(cfg, args):
            fetch_area(a, cfg, work)
    elif args.command == "points":
        cmd_points(args, cfg, params, work)
    else:
        prev = json.load(open(out_path)) if os.path.exists(out_path) else {"areas": {}}
        if args.command == "analyse":
            for a in selected(cfg, args):
                prev["areas"][a["id"]] = analyse_area(a, cfg, params, work)
                aerial.log(f"[analyse] {a['id']}: {prev['areas'][a['id']]['canopyPct']}")
        else:
            for a in selected(cfg, args):
                s = score_area(a, work)
                if s:
                    prev["areas"][a["id"]]["pointCheck"] = s
        led = work.ledger()
        prev.update({
            "tool": aerial.TOOL_VERSION + " canopy_areas", "generated": dt.date.today().isoformat(),
            "method": "canopy = NDVI > %.2f AND NIR texture (std over vegetation pixels, %.1f m window) > %.0f DN, opening %.1f m, majority %.1f m (data/params.json canopy, set on the 2023 Illinois scene)"
                      % (params["canopy"]["vegNdvi"], params["canopy"]["textureRadiusMeters"], params["canopy"]["textureMinStd"],
                         params["canopy"]["openingRadiusMeters"], params["canopy"]["majorityRadiusMeters"]),
            "privacy": "Area and block aggregates only; no imagery, masks or point labels in the repository.",
            "licence": "NAIP imagery provided by USDA Farm Service Agency (public domain); streets and parks (c) OpenStreetMap contributors (ODbL 1.0)",
            "bytesDownloaded": {"total": sum(x["bytes"] for x in led),
                                "byKind": {k: sum(x["bytes"] for x in led if x["kind"] == k) for k in sorted(set(x["kind"] for x in led))}},
        })
        os.makedirs(aerial.RESULTS, exist_ok=True)
        with open(out_path, "w") as f:
            json.dump(prev, f, indent=1, sort_keys=True)
        aerial.log(f"wrote {out_path}")


if __name__ == "__main__":
    main()
