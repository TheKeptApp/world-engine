"""Calibration of the map data layer's confidence numbers (worldengine.map/2 §3, docs/research/map-confidence.md).

Offline research tool. Inputs are a package export's calibration diagnostics (`worldbake export … --map-diagnostics
FILE`: per-record features and geometry in the area's plan metres) and validation ground truth that never enters the
repository: parcel polygons (yards), OSM `addr:street` (frontage) and blind hand labels on NAIP 0.3 m crops (front doors,
driveway ends). Per-record outcomes stay in the work directory (outside the repo); only aggregate bin tables are
written to `results/`.

  lots     --diag D --parcels P.geojson --area-dir A --work W    yard IoU against the parcel minus the footprint, split at
                                                                 the same front line; outcome IoU >= 0.6
  frontage --diag D --area-dir A --package PKG --work W          outcome: the frontage segment's name is the building's
                                                                 addr:street (buildings with addr:street only)
  sheets   --diag D --area-dir A --kind door|driveway --n N --work W [--seed S]
                                                                 blind labelling sheets (NAIP crop, footprints, scale);
                                                                 the generated point is not drawn
  score    --work W --kind door|driveway                         labels.json + sheets.json -> outcomes (door within 2 m
                                                                 along the front edge; driveway end within 3 m)
  fit      --work W [W2 …] --out results/calibration.json        pooled bin tables

Run with uv (cache outside the repo):
  UV_CACHE_DIR=/tmp/mapconf-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
    --with numpy --with shapely --with rasterio --with pillow python Tools/regionkit/mapconf/mapconf.py …
"""
import argparse
import hashlib
import json
import math
import os
import re
import ssl
import sys
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lidar"))

UA = "WorldEngine regionkit (research)"
LOT_IOU = 0.6
DOOR_M = 2.0
DRIVEWAY_M = 3.0


def load_json(p):
    with open(p) as f:
        return json.load(f)


def write_json(p, obj):
    os.makedirs(os.path.dirname(os.path.abspath(p)), exist_ok=True)
    with open(p, "w") as f:
        json.dump(obj, f, indent=2, sort_keys=True)
        f.write("\n")


def refuse_repo(work):
    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    if os.path.abspath(work).startswith(repo + os.sep):
        sys.exit("the work directory must be outside the repository (per-record outcomes stay out of it)")


def manifest_origin(area_dir):
    m = load_json(os.path.join(area_dir, "manifest.json"))
    return m["id"], m["center"]["latitude"], m["center"]["longitude"]


# ------------------------------------------------------------------ lots


def front_halfplane(edge, big=2000.0):
    """The generator's front side of the footprint's front edge: (p - a) . n > 0.5, n outward (ring CCW)."""
    from shapely.geometry import Polygon
    (ax, ay), (bx, by) = edge
    dx, dy = bx - ax, by - ay
    L = math.hypot(dx, dy)
    nx, ny = dy / L, -dx / L
    ux, uy = dx / L, dy / L
    ox, oy = ax + nx * 0.5, ay + ny * 0.5
    return Polygon([(ox - ux * big, oy - uy * big), (ox + ux * big, oy + uy * big),
                    (ox + ux * big + nx * big, oy + uy * big + ny * big), (ox - ux * big + nx * big, oy - uy * big + ny * big)])


def cmd_lots(a):
    import numpy as np
    from shapely.geometry import Polygon, shape
    from shapely.strtree import STRtree
    from roofplanes import local_en
    refuse_repo(a.work)
    area, lat0, lon0 = manifest_origin(a.area_dir)
    parcels = []
    for f in load_json(a.parcels)["features"]:
        g = shape(f["geometry"])
        for poly in getattr(g, "geoms", [g]):
            lon, lat = np.array(poly.exterior.coords).T
            e, n = local_en(lat0, lon0, lat, lon)
            p = Polygon(list(zip(e, n))).buffer(0)
            if p.area > 0:
                parcels.append(p)
    tree = STRtree(parcels)
    diag = load_json(a.diag)["records"].get("lots", [])
    out = []
    for r in diag:
        if "frontEdge" not in r:
            continue
        fp = Polygon(r["footprint"]).buffer(0)
        gen = Polygon(r["polygon"]).buffer(0)
        cands = [parcels[i] for i in tree.query(fp)]
        if not cands:
            out.append({**feat(r), "outcome": None, "why": "no parcel"})
            continue
        parcel = max(cands, key=lambda p: p.intersection(fp).area)
        share = parcel.intersection(fp).area / max(fp.area, 1e-9)
        if share < 0.5 or parcel.area < 100:
            out.append({**feat(r), "outcome": None, "why": "building not mostly in one parcel" if share < 0.5 else "sliver parcel"})
            continue
        yard = parcel.difference(fp)
        half = front_halfplane(r["frontEdge"])
        real = yard.intersection(half) if r["part"] == "front" else yard.difference(half)
        union = gen.union(real).area
        iou = gen.intersection(real).area / union if union > 0 else 0.0
        out.append({**feat(r), "iou": iou, "outcome": iou >= LOT_IOU, "parcelM2": parcel.area})
    write_json(os.path.join(a.work, f"lots-{area}.json"), {"area": area, "kind": "lots", "records": out})
    scored = [o for o in out if o["outcome"] is not None]
    print(f"{area}: {len(out)} lots, {len(scored)} with ground truth, IoU>=0.6: "
          f"{sum(o['outcome'] for o in scored)}/{len(scored)}")


def feat(r):
    keep = ("id", "source", "building", "part", "areaM2", "droppedShare", "frontageM", "footprintM2", "family", "confidence",
            "role", "frontEdgeM", "lengthM", "distanceM", "corner", "otherStreetM", "kind")
    return {k: r[k] for k in keep if k in r}


# ------------------------------------------------------------------ frontage

ABBR = {"st": "street", "ave": "avenue", "av": "avenue", "blvd": "boulevard", "rd": "road", "dr": "drive", "ct": "court",
        "pl": "place", "ln": "lane", "pkwy": "parkway", "ter": "terrace", "cir": "circle", "hwy": "highway",
        "n": "north", "s": "south", "e": "east", "w": "west"}


def norm_street(s):
    words = re.sub(r"[^a-z0-9 ]", " ", s.lower()).split()
    return " ".join(ABBR.get(w, w) for w in words)


def osm_addr_streets(area_dir):
    """Building element id -> normalized addr:street (kept in memory only; never written)."""
    out = {}
    d = load_json(os.path.join(area_dir, "osm.json"))
    for e in d["elements"]:
        t = e.get("tags") or {}
        if e["type"] in ("way", "relation") and "building" in t and "addr:street" in t:
            out[f"{e['type']}/{e['id']}"] = norm_street(t["addr:street"])
    return out


def cmd_frontage(a):
    refuse_repo(a.work)
    area, _, _ = manifest_origin(a.area_dir)
    addr = osm_addr_streets(a.area_dir)
    net = load_json(os.path.join(a.package, "map", "network.json"))
    seg_name = {s["id"]: norm_street(s["name"]) for s in net["segments"] if "name" in s}
    out = []
    for r in load_json(a.diag)["records"].get("frontage", []):
        if r["id"] not in addr:
            continue
        name = seg_name.get(r["segment"])
        out.append({**feat(r), "outcome": name == addr[r["id"]]})
    write_json(os.path.join(a.work, f"frontage-{area}.json"), {"area": area, "kind": "frontage", "records": out})
    print(f"{area}: {len(out)} frontages with addr:street, agree: {sum(o['outcome'] for o in out)}")


# ------------------------------------------------------------------ labelling sheets


CTX = ssl.create_default_context(cafile="/etc/ssl/cert.pem")
STAC = "https://planetarycomputer.microsoft.com/api/stac/v1/search"
TOKEN = "https://planetarycomputer.microsoft.com/api/sas/v1/token/naip"


def http(url, data=None, headers=None):
    """GET/POST with the project's User-Agent. A 5xx gateway error is retried twice, 10 s apart; any other error
    (including 4xx: refusals) is raised at once."""
    import time
    import urllib.error
    for attempt in range(3):
        req = urllib.request.Request(url, data=data, headers={"User-Agent": UA, **(headers or {})})
        try:
            with urllib.request.urlopen(req, timeout=120, context=CTX) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code < 500 or attempt == 2:
                raise
            time.sleep(10)


def naip_item(lat, lon):
    body = json.dumps({"collections": ["naip"], "intersects": {"type": "Point", "coordinates": [lon, lat]}, "limit": 100}).encode()
    feats = json.loads(http(STAC, body, {"Content-Type": "application/json"}))["features"]
    feats = [f for f in feats if f["properties"].get("gsd", 1) <= 0.6]
    feats.sort(key=lambda f: f["properties"]["datetime"], reverse=True)
    return feats[0]


def stable_sample(records, n, seed):
    key = lambda r: hashlib.sha256(f"{seed}:{r['id']}".encode()).hexdigest()
    return sorted(records, key=key)[:n]


def cmd_sheets(a):
    import numpy as np
    import rasterio
    from rasterio.warp import transform
    from rasterio.windows import from_bounds
    from PIL import Image, ImageDraw
    from roofplanes import local_to_latlon
    refuse_repo(a.work)
    area, lat0, lon0 = manifest_origin(a.area_dir)
    recs = [r for r in load_json(a.diag)["records"].get("entries", []) if r["kind"] == ("front_door" if a.kind == "door" else "driveway_end")]
    if a.kind == "door":
        recs = [r for r in recs if "frontEdge" in r]
    sample = stable_sample(recs, a.n, a.seed)
    lots = {r["building"]: r for r in load_json(a.diag)["records"].get("lots", []) if r.get("part") == "front"}
    outdir = os.path.join(a.work, f"sheets-{a.kind}-{area}")
    os.makedirs(outdir, exist_ok=True)
    token = json.loads(http(TOKEN))["token"]
    only = set(a.only.split(",")) if a.only else None
    # NAIP comes in quarter-quad tiles: each sheet reads the newest tile that contains its whole
    # window (an area can span several), found once and cached.
    items, datasets = [], {}

    def dataset_for(lat, lon):
        pad = 0.0004  # about 30-45 m: the window's half-size plus a margin
        for it in items:
            w, s, e, n = it["bbox"]
            if w + pad <= lon <= e - pad and s + pad <= lat <= n - pad:
                break
        else:
            it = naip_item(lat, lon)
            items.append(it)
        if it["id"] not in datasets:
            datasets[it["id"]] = rasterio.open(f"/vsicurl/{it['assets']['image']['href']}?{token}")
        return it, datasets[it["id"]]
    size = 40.0
    scale = 6
    sheets = []
    env = dict(GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif", GDAL_HTTP_MERGE_CONSECUTIVE_RANGES="YES",
               GDAL_HTTP_USERAGENT=UA, GDAL_CURL_CA_BUNDLE="/etc/ssl/cert.pem")
    with rasterio.Env(**env):
        for k, r in enumerate(sample):
            if a.kind == "door":
                (ax, ay), (bx, by) = r["frontEdge"]
                cx, cy = (ax + bx) / 2, (ay + by) / 2
            else:
                cx, cy = (r["position"][0] + r["start"][0]) / 2, (r["position"][1] + r["start"][1]) / 2
            la, lo = local_to_latlon(lat0, lon0, np.array([cx]), np.array([cy]))
            item, src = dataset_for(float(la[0]), float(lo[0]))
            xs, ys = transform("EPSG:4326", src.crs, [float(lo[0])], [float(la[0])])
            h = size / 2
            win = from_bounds(xs[0] - h, ys[0] - h, xs[0] + h, ys[0] + h, src.transform).round_offsets().round_lengths()
            data = src.read(indexes=[1, 2, 3], window=win, boundless=True)
            wt = src.window_transform(win)
            img = Image.fromarray(np.transpose(data, (1, 2, 0)).astype("uint8")).resize((data.shape[2] * scale, data.shape[1] * scale), Image.NEAREST)
            d = ImageDraw.Draw(img)

            def px(x, y):
                la2, lo2 = local_to_latlon(lat0, lon0, np.array([x]), np.array([y]))
                X, Y = transform("EPSG:4326", src.crs, [float(lo2[0])], [float(la2[0])])
                col, row = ~wt * (X[0], Y[0])
                return col * scale, row * scale

            fp = [px(x, y) for x, y in (r["footprint"] if "footprint" in r else [])]
            if len(fp) >= 3:
                d.line(fp + [fp[0]], fill=(255, 230, 0), width=2)
            sheet = {"sheet": f"{k:03d}.png", "id": r["id"], "kind": a.kind, "naip": item["id"]}
            if a.kind == "door":
                A, B = px(ax, ay), px(bx, by)
                d.line([A, B], fill=(255, 40, 40), width=4)
                L = math.hypot(bx - ax, by - ay)
                for m in range(0, int(L) + 1):
                    t = m / L
                    P = (A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t)
                    d.ellipse([P[0] - 3, P[1] - 3, P[0] + 3, P[1] + 3], fill=(255, 255, 255))
                    if m % 2 == 0:
                        d.text((P[0] + 5, P[1] + 5), str(m), fill=(255, 255, 255))
                d.text((A[0] - 14, A[1] - 14), "A", fill=(255, 40, 40))
                gen_t = ((r["position"][0] - ax) * (bx - ax) + (r["position"][1] - ay) * (by - ay)) / (L * L)
                sheet.update({"edgeLengthM": L, "genAlongM": gen_t * L})
            else:
                # Grid every 2 m with labelled lines, local plan axes (east, north) about the crop centre.
                for g in range(-20, 21, 2):
                    p1, p2 = px(cx + g, cy - 20), px(cx + g, cy + 20)
                    q1, q2 = px(cx - 20, cy + g), px(cx + 20, cy + g)
                    col = (255, 255, 255) if g % 10 == 0 else (200, 200, 200)
                    d.line([p1, p2], fill=col, width=1)
                    d.line([q1, q2], fill=col, width=1)
                    if g % 4 == 0:
                        d.text((p1[0] + 2, p1[1] - 12), f"x{g}", fill=(255, 255, 0))
                        d.text((q1[0] + 2, q1[1] - 12), f"y{g}", fill=(0, 255, 255))
                G = px(*r["start"])
                d.ellipse([G[0] - 6, G[1] - 6, G[0] + 6, G[1] + 6], outline=(255, 40, 40), width=3)
                sheet.update({"centre": [cx, cy], "genOffset": [r["position"][0] - cx, r["position"][1] - cy]})
            if only is None or sheet["sheet"] in only:
                img.save(os.path.join(outdir, sheet["sheet"]))
            sheets.append(sheet)
    for ds in datasets.values():
        ds.close()
    write_json(os.path.join(outdir, "sheets.json"), {"area": area, "kind": a.kind,
                                                      "naip": [{"item": it["id"], "datetime": it["properties"]["datetime"]} for it in items],
                                                      "sheets": sheets})
    print(f"wrote {len(sheets)} sheets to {outdir}")


def cmd_score(a):
    refuse_repo(a.work)
    for name in sorted(os.listdir(a.work)):
        if not name.startswith(f"sheets-{a.kind}-"):
            continue
        d = os.path.join(a.work, name)
        if not os.path.exists(os.path.join(d, "labels.json")):
            continue
        sheets = load_json(os.path.join(d, "sheets.json"))
        labels = {l["sheet"]: l for l in load_json(os.path.join(d, "labels.json"))["labels"]}
        diag_by_id = {}
        out = []
        for s in sheets["sheets"]:
            l = labels.get(s["sheet"])
            if l is None or l.get("visible") is False:
                out.append({"id": s["id"], "outcome": None, "why": "not visible" if l else "unlabelled"})
                continue
            if a.kind == "door":
                if l.get("onEdge") is False:
                    ok, err = False, None
                else:
                    err = abs(float(l["alongM"]) - s["genAlongM"])
                    ok = err <= DOOR_M
            else:
                dx, dy = float(l["x"]) - s["genOffset"][0], float(l["y"]) - s["genOffset"][1]
                err = math.hypot(dx, dy)
                ok = err <= DRIVEWAY_M
            out.append({"id": s["id"], "outcome": ok, "errorM": err})
        area = sheets["area"]
        write_json(os.path.join(a.work, f"{a.kind}-{area}.json"), {"area": area, "kind": a.kind, "records": out})
        sc = [o for o in out if o["outcome"] is not None]
        print(f"{area} {a.kind}: {len(sc)} labelled, within tolerance {sum(o['outcome'] for o in sc)}")


# ------------------------------------------------------------------ fit


def wilson(k, n, z=1.0):
    if n == 0:
        return 0.0
    p = k / n
    den = 1 + z * z / n
    c = p + z * z / (2 * n)
    r = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (c - r) / den, (c + r) / den


def cmd_fit(a):
    """Pools outcome files by kind and prints success shares by the candidate features (for choosing bins)."""
    pools = {}
    for w in a.work:
        for name in sorted(os.listdir(w)):
            if name.endswith(".json") and "-" in name and not name.startswith("sheets"):
                d = load_json(os.path.join(w, name))
                if "records" in d and "kind" in d:
                    for r in d["records"]:
                        if r.get("outcome") is not None:
                            pools.setdefault(d["kind"], []).append({**r, "area": d["area"]})
    summary = {}
    for kind, recs in sorted(pools.items()):
        k = sum(r["outcome"] for r in recs)
        summary[kind] = {"n": len(recs), "success": k, "byArea": {}}
        for area in sorted({r["area"] for r in recs}):
            rr = [r for r in recs if r["area"] == area]
            summary[kind]["byArea"][area] = {"n": len(rr), "success": sum(r["outcome"] for r in rr)}
        print(kind, summary[kind])
    write_json(a.out, summary)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("lots"); s.add_argument("--diag"); s.add_argument("--parcels"); s.add_argument("--area-dir"); s.add_argument("--work")
    s = sub.add_parser("frontage"); s.add_argument("--diag"); s.add_argument("--area-dir"); s.add_argument("--package"); s.add_argument("--work")
    s = sub.add_parser("sheets"); s.add_argument("--diag"); s.add_argument("--area-dir"); s.add_argument("--kind", choices=["door", "driveway"])
    s.add_argument("--n", type=int, default=60); s.add_argument("--seed", default="mapconf-v1"); s.add_argument("--work")
    s.add_argument("--only", help="comma-separated sheet names to (re)write; sheets.json always lists all")
    s = sub.add_parser("score"); s.add_argument("--work"); s.add_argument("--kind", choices=["door", "driveway"])
    s = sub.add_parser("fit"); s.add_argument("--work", nargs="+"); s.add_argument("--out")
    a = p.parse_args()
    {"lots": cmd_lots, "frontage": cmd_frontage, "sheets": cmd_sheets, "score": cmd_score, "fit": cmd_fit}[a.cmd](a)


if __name__ == "__main__":
    main()
