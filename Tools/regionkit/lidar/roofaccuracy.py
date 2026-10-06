#!/usr/bin/env python3
"""Roof-form evaluation: hand labels from NAIP imagery against the lidar roof classifier.

Offline research tool for WorldEngine's region kit. Protocol and results: docs/research/lidar-roofs.md section 15.

  sample   draw the test and tuning sets (stable, seeded, documented in data/roofaccuracy.json) from a
           lidar-roofs.json and freeze the classifier output ("before") next to them        -> work dir
  crops    NAIP 0.3 m windows (windowed COG reads, Planetary Computer, anonymous) plus a lidar height
           image for every roof of a set, as contact sheets and a key. Shows no classifier output -> work dir
  score    hand labels (labels_<set>_<area>.json in the work dir) against a classifier output
           ('before', 'after' = each area's committed lidar-roofs.json, or a file): overall, per class,
           simple-called-complex rate                                                       -> work dir
  report   before / after for both sets, per area and pooled                    -> results/roofaccuracy.json (aggregates)

Per-building labels, crops and predictions never enter the repository (the work directory must be outside it).
"""

import argparse
import hashlib
import json
import logging
import math
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "aerial"))
import roofplanes as rp  # noqa: E402

CLASSES = ("flat", "gable", "hip", "complex", "mansard")
SIMPLE = ("flat", "gable", "hip")


def load_cfg():
    with open(os.path.join(HERE, "data", "roofaccuracy.json")) as f:
        return json.load(f)


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def ref_filter(refs, cfg):
    """Evaluation population: OSM-keyed records that existed before this change (way/ and relation/ refs)."""
    return [r for r in refs if r.startswith(("way/", "relation/"))]


def draw_sets(refs, cfg, area_id):
    """Evaluation set (seed A) and tuning set (seed B, disjoint from it): the n smallest sha256(seed|area|ref)."""
    pool = sorted(ref_filter(refs, cfg))
    ev = rp.stable_sample([f"{area_id}|{r}" for r in pool], cfg["test"]["n"], cfg["test"]["seed"])
    ev = [e.split("|", 1)[1] for e in ev]
    rest = [r for r in pool if r not in set(ev)]
    tn = rp.stable_sample([f"{area_id}|{r}" for r in rest], cfg["tune"]["n"], cfg["tune"]["seed"])
    tn = [e.split("|", 1)[1] for e in tn]
    return ev, tn


def cmd_sample(args, cfg, work):
    out = {}
    for a in cfg["areas"]:
        path = os.path.join(REPO, a["area"], "lidar-roofs.json")
        with open(args.roofs_dir and os.path.join(args.roofs_dir, a["id"] + ".json") or path) as f:
            lr = json.load(f)
        refs = list(lr["buildings"])
        ev, tn = draw_sets(refs, cfg, a["id"])
        before = {r: lr["buildings"][r] for r in ev + tn}
        out[a["id"]] = {"test": ev, "tune": tn, "before": before, "methodVersion": lr["header"]["methodVersion"],
                        "classified": len(refs), "population": len(ref_filter(refs, cfg))}
        log(f"[{a['id']}] population {out[a['id']]['population']} -> eval {len(ev)}, tune {len(tn)}")
    p = work.p("sets.json")
    if os.path.exists(p) and not args.force:
        sys.exit(f"{p} exists: the frozen sets are not redrawn (use --force to overwrite)")
    with open(p, "w") as f:
        json.dump(out, f, indent=1)
    log("wrote", p, hashlib.sha256(open(p, "rb").read()).hexdigest())


# ---------------------------------------------------------------- NAIP windows


class Naip:
    """Windowed reads of the newest NAIP year at an area; byte count from GDAL's debug log."""

    def __init__(self, a, cfg, work, man):
        import aerial
        import rasterio
        from rasterio.warp import transform
        self.aerial, self.rio, self.a, self.cfg, self.work = aerial, rasterio, a, cfg, work
        self.man = man
        lat, lon = man["center"]["latitude"], man["center"]["longitude"]
        self.transform = transform
        hw, hh = man["widthMeters"] / 2 + 60, man["heightMeters"] / 2 + 60
        dlat, dlon = hh / 111320.0, hw / (111320.0 * math.cos(math.radians(lat)))
        bbox = [lon - dlon, lat - dlat, lon + dlon, lat + dlat]
        body = json.dumps({"collections": ["naip"], "bbox": bbox, "limit": 200}).encode()
        res = json.loads(aerial.http(cfg["naip"]["stacSearch"], work, "naip-stac", data=body, headers={"Content-Type": "application/json"}))
        feats = [f for f in res["features"] if f["properties"].get("naip:state") == a["state"]]
        years = sorted({f["properties"].get("naip:year") for f in feats}, reverse=True)
        self.year = years[0]
        self.items = [f for f in feats if f["properties"].get("naip:year") == self.year]
        self.token = json.loads(aerial.http(cfg["naip"]["tokenEndpoint"], work, "naip-token"))["token"]
        self.handler = aerial._GdalBytes()
        lg = logging.getLogger("rasterio")
        lg.setLevel(logging.DEBUG)
        lg.addHandler(self.handler)
        self.env = rasterio.Env(CPL_DEBUG="ON", GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".tif",
                                GDAL_HTTP_MERGE_CONSECUTIVE_RANGES="YES", GDAL_HTTP_USERAGENT=aerial.UA, VSI_CACHE="FALSE")
        self.env.__enter__()
        self.ds = {}
        self.used = {}

    def open(self, item):
        if item["id"] not in self.ds:
            self.ds[item["id"]] = self.rio.open(f"/vsicurl/{item['assets']['image']['href']}?{self.token}")
        return self.ds[item["id"]]

    def window(self, lat, lon, half_m):
        """RGB window (3, h, w) uint8 around a point (half_m each side, UTM metres), the CRS pixel size and the
        window's UTM bounds, or None when no item covers it."""
        from rasterio.windows import from_bounds
        for it in sorted(self.items, key=lambda f: f["properties"]["datetime"], reverse=True):
            crs = f"EPSG:{it['properties']['proj:epsg']}"
            xs, ys = self.transform("EPSG:4326", crs, [lon], [lat])
            b = it["properties"]["proj:bbox"]
            x0, y0, x1, y1 = xs[0] - half_m, ys[0] - half_m, xs[0] + half_m, ys[0] + half_m
            if b[0] <= x0 and b[1] <= y0 and b[2] >= x1 and b[3] >= y1:
                src = self.open(it)
                win = from_bounds(x0, y0, x1, y1, src.transform).round_offsets().round_lengths()
                data = src.read([1, 2, 3], window=win)
                self.used[it["id"]] = it["properties"]["datetime"]
                t = src.window_transform(win)
                return data, abs(t.a), (t.c, t.f), (xs[0], ys[0])
        return None

    def bytes(self):
        return self.handler.total()

    def close(self):
        for d in self.ds.values():
            d.close()
        self.env.__exit__(None, None, None)


def hillshade_height(P, h, bounds, px):
    """Height-and-hillshade image (PIL RGB) of building points over bounds (x0, y0, x1, y1), px metres per cell, north up."""
    from PIL import Image
    from scipy import ndimage
    from scipy.spatial import cKDTree
    x0, y0, x1, y1 = bounds
    W, H = max(int((x1 - x0) / px), 2), max(int((y1 - y0) / px), 2)
    gx, gy = np.meshgrid(x0 + (np.arange(W) + 0.5) * px, y1 - (np.arange(H) + 0.5) * px)
    dsm = np.full((H, W), np.nan)
    if len(P):
        tree = cKDTree(P[:, :2])
        nb = tree.query_ball_point(np.stack([gx.ravel(), gy.ravel()], axis=1), r=0.8)
        dsm = np.array([float(np.max(h[j])) if len(j) else np.nan for j in nb]).reshape(H, W)
    holes = np.isnan(dsm)
    fill = np.where(holes, np.nanmin(dsm) if (~holes).any() else 0.0, dsm)
    sm = ndimage.gaussian_filter(fill, 0.7)
    gyy, gxx = np.gradient(sm, px)
    # light from the north-west, 45 deg above the horizon
    az, alt = math.radians(315), math.radians(45)
    slope = np.arctan(np.hypot(gxx, gyy))
    aspect = np.arctan2(-gxx, gyy)
    shade = np.sin(alt) * np.cos(slope) + np.cos(alt) * np.sin(slope) * np.cos(az - aspect)
    shade = np.clip(shade, 0, 1)
    hn = np.clip(sm / max(float(np.nanmax(fill)), 1.0), 0, 1)
    rgb = np.zeros((H, W, 3))
    rgb[..., 0] = 0.35 + 0.65 * shade * (0.55 + 0.45 * hn)
    rgb[..., 1] = 0.35 + 0.65 * shade * (0.75 + 0.25 * hn)
    rgb[..., 2] = 0.45 + 0.55 * shade
    rgb = (np.clip(rgb, 0, 1) * 255).astype(np.uint8)
    rgb[holes] = (20, 20, 20)
    return Image.fromarray(rgb)


def cmd_crops(args, cfg, work):
    from PIL import Image, ImageDraw
    import roofhints as RH
    with open(work.p("sets.json")) as f:
        sets = json.load(f)
    rcfg = RH.load_cfg()
    for a in cfg["areas"]:
        if args.area and a["id"] != args.area:
            continue
        refs = sets[a["id"]][args.set]
        awork = work.sub(a["id"])
        area = next(x for x in rcfg["areas"] if x["id"] == a["id"])
        D = RH.prepare_points(rcfg, area, awork)
        L, man = D["L"], D["man"]
        lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
        naip = Naip(a, cfg, work, man)
        from scipy import ndimage  # noqa: F401
        bidx = L.PointIndex(D["bld1"])
        rows, key = [], []
        PX = 360
        for n, ref in enumerate(refs):
            poly = D["fps"][ref]["poly"]
            cx0, cy0 = poly.centroid.x, poly.centroid.y
            x0, y0, x1, y1 = poly.bounds
            half = max(x1 - x0, y1 - y0) / 2 + cfg["crop"]["marginM"]
            half = max(half, cfg["crop"]["minHalfM"])
            lat, lon = rp.local_to_latlon(lat0, lon0, np.array([cx0]), np.array([cy0]))
            win = naip.window(float(np.ravel(lat)[0]), float(np.ravel(lon)[0]), half)
            # lidar panel in the footprint frame (points were shifted onto the footprints)
            bnds = (cx0 - half, cy0 - half, cx0 + half, cy0 + half)
            P = D["bld1"][bidx.query(bnds)]
            P = P[(P[:, 0] >= bnds[0]) & (P[:, 0] <= bnds[2]) & (P[:, 1] >= bnds[1]) & (P[:, 1] <= bnds[3])]
            h = P[:, 2] - D["ground_h"](P[:, 0], P[:, 1]) if len(P) else np.zeros(0)
            lid = hillshade_height(P, h, bnds, 0.5).resize((PX, PX), Image.NEAREST)
            if win is None:
                rgb = Image.new("RGB", (PX, PX), (60, 0, 0))
                gsd = None
            else:
                data, gsd, _, _ = win
                rgb = Image.fromarray(np.moveaxis(data, 0, -1)).resize((PX, PX), Image.LANCZOS)
            # contrast stretch the image a little for reading (same stretch for plain and outlined)
            arr = np.asarray(rgb).astype(float)
            lo, hi = np.percentile(arr, 1), np.percentile(arr, 99)
            rgb = Image.fromarray(np.clip((arr - lo) / max(hi - lo, 1) * 255, 0, 255).astype(np.uint8))
            out = rgb.copy()
            d = ImageDraw.Draw(out)
            sc = PX / (2 * half)
            rings = [poly] if poly.geom_type == "Polygon" else list(poly.geoms)
            for g in rings:
                d.line([((x - bnds[0]) * sc, (bnds[3] - y) * sc) for x, y in g.exterior.coords], fill=(255, 255, 0), width=1)
            tag = f"{a['id'][:4]}-{'t' if args.set == 'test' else 'u'}{n + 1:02d}"
            panel = Image.new("RGB", (PX * 3 + 8, PX + 16), (0, 0, 0))
            for k, im in enumerate((rgb, out, lid)):
                panel.paste(im, (k * (PX + 4), 16))
            ImageDraw.Draw(panel).text((3, 2), f"{tag}   window {2 * half:.0f} m   (plain | outline | lidar height, light NW)", fill=(255, 255, 255))
            rows.append(panel)
            key.append({"id": tag, "ref": ref, "footprintM2": round(poly.area), "windowM": round(2 * half, 1), "gsd": gsd})
        per = cfg["crop"]["roofsPerSheet"]
        for s in range(0, len(rows), per):
            chunk = rows[s:s + per]
            sheet = Image.new("RGB", (chunk[0].width, sum(r.height for r in chunk) + 4 * len(chunk)), (0, 0, 0))
            y = 0
            for r in chunk:
                sheet.paste(r, (0, y))
                y += r.height + 4
            sheet.save(work.p("sheets", f"{args.set}_{a['id']}_{s // per + 1:02d}.png"))
        with open(work.p("sheets", f"key_{args.set}_{a['id']}.json"), "w") as f:
            json.dump(key, f, indent=1)
        meta = {"area": a["id"], "year": naip.year, "items": naip.used, "rangeBytes": naip.bytes()}
        work.ledger_add("naip-cog-ranges", f"{a['id']} {args.set}: " + ", ".join(sorted(naip.used)), naip.bytes())
        with open(work.p("sheets", f"naip_{args.set}_{a['id']}.json"), "w") as f:
            json.dump(meta, f, indent=1)
        log(f"[{a['id']}] {len(rows)} roofs, NAIP {naip.year} {sorted(naip.used)}, {naip.bytes():,} bytes")
        naip.close()


# ---------------------------------------------------------------- scoring


def score_pairs(pairs):
    """pairs: [(hand, predicted)]. hand 'cant_tell' is excluded from every figure and counted."""
    usable = [(h, p) for h, p in pairs if h in CLASSES]
    n_ct = sum(1 for h, _ in pairs if h not in CLASSES)
    n = len(usable)
    ok = sum(1 for h, p in usable if h == p)
    per = {}
    for c in CLASSES:
        rows = [(h, p) for h, p in usable if h == c]
        per[c] = {"nHand": len(rows), "correct": sum(1 for h, p in rows if h == p),
                  "recall": round(sum(1 for h, p in rows if h == p) / len(rows), 3) if len(rows) else None,
                  "nPredicted": sum(1 for _, p in usable if p == c),
                  "precision": round(sum(1 for h, p in usable if p == c and h == c) / max(sum(1 for _, p in usable if p == c), 1), 3)
                  if any(p == c for _, p in usable) else None}
    simple_rows = [(h, p) for h, p in usable if h in SIMPLE]
    cx_rows = [(h, p) for h, p in usable if h == "complex"]
    wl = rp.wilson(ok, n)
    out = {"nLabelled": len(pairs), "nCantTell": n_ct, "n": n, "correct": ok,
           "accuracy": round(ok / n, 3) if n else None, "wilson95": list(wl),
           "perClass": per,
           "simpleCalledComplex": {"nSimpleByHand": len(simple_rows),
                                   "calledComplex": sum(1 for _, p in simple_rows if p == "complex"),
                                   "rate": round(sum(1 for _, p in simple_rows if p == "complex") / len(simple_rows), 3) if simple_rows else None},
           "complexCalledSimple": {"nComplexByHand": len(cx_rows),
                                   "calledSimple": sum(1 for _, p in cx_rows if p in SIMPLE),
                                   "rate": round(sum(1 for _, p in cx_rows if p in SIMPLE) / len(cx_rows), 3) if cx_rows else None},
           "confusion": rp.confusion([(h, p) for h, p in usable], CLASSES)}
    # "simple form" agreement: flat/gable/hip roofs only, predicted exactly right
    out["simpleFormAccuracy"] = {"n": len(simple_rows), "correct": sum(1 for h, p in simple_rows if h == p),
                                 "rate": round(sum(1 for h, p in simple_rows if h == p) / len(simple_rows), 3) if simple_rows else None}
    return out


def cmd_score(args, cfg, work):
    with open(work.p("sets.json")) as f:
        sets = json.load(f)
    res = {}
    for a in cfg["areas"]:
        if args.area and a["id"] != args.area:
            continue
        labp = work.p(f"labels_{args.set}_{a['id']}.json")
        with open(labp) as f:
            labels = json.load(f)
        with open(work.p("sheets", f"key_{args.set}_{a['id']}.json")) as f:
            key = {k["id"]: k["ref"] for k in json.load(f)}
        if args.pred == "before":
            pred = {r: v["form"] for r, v in sets[a["id"]]["before"].items()}
        else:
            path = os.path.join(REPO, a["area"], "lidar-roofs.json") if args.pred == "after" else args.pred
            with open(path) as f:
                pred = {r: v["form"] for r, v in json.load(f)["buildings"].items()}
        pairs, missing = [], 0
        for tag, lab in sorted(labels.items()):
            r = key[tag]
            if r not in pred:
                missing += 1
                continue
            pairs.append((lab, pred[r]))
        res[a["id"]] = score_pairs(pairs)
        res[a["id"]]["notClassifiedAfter"] = missing
        res[a["id"]]["labelsSha256"] = hashlib.sha256(open(labp, "rb").read()).hexdigest()
    both = []
    for a in cfg["areas"]:
        if a["id"] in res:
            pass
    out_path = args.out or work.p(f"score_{args.set}_{args.pred.replace('/', '_')}.json")
    with open(out_path, "w") as f:
        json.dump(res, f, indent=1)
    for k, v in res.items():
        log(f"[{k}] n={v['n']} acc={v['accuracy']} {v['wilson95']} cantTell={v['nCantTell']} simple->complex={v['simpleCalledComplex']}")
    log("wrote", out_path)


def labelled_pairs(work, sets, area_id, set_name, pred):
    """[(hand label, predicted form)] for one area and set; roofs the classifier no longer classifies are counted."""
    with open(work.p(f"labels_{set_name}_{area_id}.json")) as f:
        labels = json.load(f)
    with open(work.p("sheets", f"key_{set_name}_{area_id}.json")) as f:
        key = {k["id"]: k["ref"] for k in json.load(f)}
    return [(lab, pred[key[tag]]) for tag, lab in sorted(labels.items()) if key[tag] in pred], \
        sum(1 for tag in labels if key[tag] not in pred), \
        hashlib.sha256(open(work.p(f"labels_{set_name}_{area_id}.json"), "rb").read()).hexdigest()


def cmd_report(args, cfg, work):
    """results/roofaccuracy.json: before / after accuracy on the test and tuning sets, per area and pooled
    (aggregates only: counts, rates, confusion matrices; no refs, labels or imagery)."""
    import roofhints as RH
    rcfg = RH.load_cfg()
    with open(work.p("sets.json")) as f:
        sets = json.load(f)
    out = {"format": "roof-accuracy/1",
           "methodVersions": {"before": next(iter(sets.values()))["methodVersion"], "after": rcfg["methodVersion"]},
           "rules": rcfg["classifier"]["rules"],
           "protocol": {"labels": cfg["labelProtocol"], "testSet": cfg["test"], "tuneSet": cfg["tune"],
                        "population": {a: {"classifiedBefore": sets[a]["classified"], "osmKeyedBefore": sets[a]["population"]} for a in sets}},
           "sets": {}}
    for set_name in ("test", "tune"):
        block = {}
        pooled = {"before": [], "after": []}
        for a in cfg["areas"]:
            aid = a["id"]
            before = {r: v["form"] for r, v in sets[aid]["before"].items()}
            with open(os.path.join(REPO, a["area"], "lidar-roofs.json")) as f:
                after = {r: v["form"] for r, v in json.load(f)["buildings"].items()}
            pb, mb, sha = labelled_pairs(work, sets, aid, set_name, before)
            pa, ma, _ = labelled_pairs(work, sets, aid, set_name, after)
            pooled["before"] += pb
            pooled["after"] += pa
            block[aid] = {"labelsSha256": sha, "before": score_pairs(pb), "after": score_pairs(pa), "notClassifiedAfter": ma}
        block["pooled"] = {"before": score_pairs(pooled["before"]), "after": score_pairs(pooled["after"])}
        out["sets"][set_name] = block
    with open(os.path.join(HERE, "results", "roofaccuracy.json"), "w") as f:
        json.dump(out, f, indent=1)
        f.write("\n")
    for set_name, block in out["sets"].items():
        for k, v in block.items():
            b, af = v["before"], v["after"]
            log(f"[{set_name} {k}] n={b['n']} accuracy {b['accuracy']} -> {af['accuracy']}; simple->complex {b['simpleCalledComplex']['rate']} -> {af['simpleCalledComplex']['rate']}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["sample", "crops", "score", "report"])
    ap.add_argument("--work", required=True)
    ap.add_argument("--area")
    ap.add_argument("--set", choices=["test", "tune"], default="test")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--roofs-dir", help="sample: directory of <area>.json copies of lidar-roofs.json to draw from (the frozen 'before' files)")
    ap.add_argument("--pred", default="before", help="score: 'before' (the classifier output frozen in sets.json), 'after' (each area's committed lidar-roofs.json), or a lidar-roofs.json path (one area)")
    ap.add_argument("--out")
    args = ap.parse_args()
    import lidar as L
    cfg = load_cfg()
    work = L.Work(args.work)
    work.sub = lambda name: L.Work(os.path.join(work.root, name))
    {"sample": cmd_sample, "crops": cmd_crops, "score": cmd_score, "report": cmd_report}[args.cmd](args, cfg, work)


if __name__ == "__main__":
    main()
