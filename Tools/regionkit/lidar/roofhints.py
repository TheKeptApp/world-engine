#!/usr/bin/env python3
"""Lidar roof hints: per-footprint height, eave, pitch class and roof form (with mansard), plus a block roof-mix table.

Offline research tool for WorldEngine's region kit; generator hints, not engine code. Extends the Phase 5B lidar
pilot (lidar.py, roofplanes.py, heights.py) to two committed areas and writes, per area:
  Data/areas/<id>/lidar-roofs.json      one record per classified OSM footprint, keyed "way/123"
  Data/areas/<id>/roof-mix-blocks.json  roof-form shares per street block (privacy floor n >= 5)
Method and formats: docs/research/lidar-roofs.md section 14.

Subcommands (all take --work DIR, outside the repository; per-area subdirectories):
  fetch    read the EPT octree nodes that meet each area box (public usgs-lidar-public bucket), byte ledger
  measure  classify every footprint, write lidar-roofs.json (+ per-building planes in the work dir)
  blocks   build the block faces and write roof-mix-blocks.json from lidar-roofs.json
  mansard  scratch images (work dir only) of mansard-flagged and near-miss roofs for the hand check
  all      fetch + measure + blocks
"""

import argparse
import hashlib
import json
import math
import os
import statistics
import sys
import time
from collections import Counter

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
import roofplanes as rp  # noqa: E402

FORMS = ("flat", "hip", "gable", "mansard", "complex")
PITCH_CLASSES = ("flat", "low", "medium", "steep")


def load_cfg():
    with open(os.path.join(HERE, "data", "roofhints.json")) as f:
        return json.load(f)


def log(*a):
    print(*a, file=sys.stderr, flush=True)


# ---------------------------------------------------------------- pure functions


def pitch_class(deg, pc):
    """flat < 10 deg; low 10 <= p < 25; medium 25 <= p <= 40; steep > 40 (thresholds from `pitchClasses`)."""
    if deg is None:
        return None
    if deg < pc["flatBelow"]:
        return "flat"
    if deg < pc["lowBelow"]:
        return "low"
    if deg <= pc["mediumUpTo"]:
        return "medium"
    return "steep"


def _ang_diff(a, b):
    return abs((a - b + 180.0) % 360.0 - 180.0)


def significant_planes(planes, cls_params):
    total = sum(pl["area"] for pl in planes)
    return [pl for pl in planes if pl["area"] >= max(cls_params["minPlaneM2"], cls_params["minPlaneShare"] * total)]


def mansard_rule(planes, rect, cls_params, mp):
    """Mansard: steep lower planes around a flat or low top (see data/roofhints.json `mansard`).

    planes: plane dicts (area, pitch, aspect, cx, cy in the footprint's metre frame); rect: min_area_rect of the
    footprint (cx, cy, ux, uy, half_long, half_short). Returns {"mansard": bool, "sides": steep-covered sides
    (0-4), "steepShare", "topShare", "steepPitch": area-weighted mean pitch of the steep planes or None}."""
    out = {"mansard": False, "sides": 0, "steepShare": 0.0, "topShare": 0.0, "steepPitch": None}
    sig = significant_planes(planes, cls_params)
    sig_area = sum(pl["area"] for pl in sig)
    if sig_area <= 0:
        return out
    steep = [pl for pl in sig if pl["pitch"] >= mp["steepMinPitch"]]
    tops = [pl for pl in sig if pl["pitch"] < mp["topMaxPitch"]]
    steep_area = sum(pl["area"] for pl in steep)
    out["steepShare"] = round(steep_area / sig_area, 3)
    out["topShare"] = round(sum(pl["area"] for pl in tops) / sig_area, 3)
    if steep:
        out["steepPitch"] = round(sum(pl["pitch"] * pl["area"] for pl in steep) / steep_area, 1)
    if not steep or not tops or steep_area / sig_area < mp["steepMinShare"]:
        return out
    # A mansard is a ring of steep planes (one or two per side) round a top: no other slopes, no extra wings.
    if len(steep) > mp["maxSteepPlanes"] or (steep_area + sum(pl["area"] for pl in tops)) / sig_area < mp["ringMinShare"]:
        return out
    cx, cy, ux, uy, hl, hs = rect
    u, v = np.array([ux, uy]), np.array([-uy, ux])

    def frame(pl):
        d = np.array([pl["cx"] - cx, pl["cy"] - cy])
        return float(d @ u), float(d @ v)
    # A top plane of at least topMinShare, centred inside the roof (not a porch or an addition at one end).
    cen = mp["centralShare"]
    top_ok = False
    for pl in tops:
        a, b = frame(pl)
        if pl["area"] >= mp["topMinShare"] * sig_area and abs(a) <= cen * hl and abs(b) <= cen * hs:
            top_ok = True
    if not top_ok:
        return out
    # Sides 0..3 = +u, +v, -u, -v (the order classify_roof uses); outward azimuth of each.
    side_vec = [u, v, -u, -v]
    covered = [False] * 4
    for pl in steep:
        a, b = frame(pl)
        for k, nrm in enumerate(side_vec):
            az = math.degrees(math.atan2(nrm[0], nrm[1])) % 360.0
            if _ang_diff(pl["aspect"], az) > 45.0:
                continue
            # centroid in the outer 60 % of the rectangle on that side (sideCentroidMin of the half-extent)
            along = (a, b, -a, -b)[k]
            half = (hl, hs, hl, hs)[k]
            if along >= mp["sideCentroidMin"] * half:
                covered[k] = True
    n = sum(covered)
    out["sides"] = n
    if n >= mp["minSides"]:
        out["mansard"] = True
    return out


def dominant_pitch(planes, cls_params, form, mans):
    """pitchDeg: flat -> pitch of the largest significant plane; mansard -> area-weighted mean pitch of the steep
    planes; otherwise pitch of the largest significant sloped plane (>= flatMaxPitch)."""
    sig = significant_planes(planes, cls_params)
    if not sig:
        return None
    if form == "mansard" and mans.get("steepPitch") is not None:
        return mans["steepPitch"]
    if form == "flat":
        return round(max(sig, key=lambda pl: pl["area"])["pitch"], 1)
    sloped = [pl for pl in sig if pl["pitch"] >= cls_params["flatMaxPitch"]]
    pool = sloped or sig
    return round(max(pool, key=lambda pl: pl["area"])["pitch"], 1)


def roof_confidence(cover, density, coverage, form, cf):
    c = (min(1.0, cover) * min(1.0, density / cf["fullDensity"]) * min(1.0, (coverage or 0.0) / 0.9)
         * cf["formFactor"].get(form, 0.8))
    return round(c, 2)


def r1(v):
    return None if v is None else round(float(v), 1)


def make_record(res, planes, rect, hts, extras, cfg, cls_params):
    """One lidar-roofs.json record from the classifier output, planes and height measure, or None (skipped)."""
    mans = mansard_rule(planes, rect, cls_params, cfg["mansard"]) if planes else {"mansard": False}
    form = res["form"]
    if form == "unknown":
        return None
    if mans["mansard"]:
        form = "mansard"
    pitch = dominant_pitch(planes, cls_params, form, mans)
    rec = {
        "topM": r1(hts.get("top")),
        "eaveM": r1(hts.get("eave")),
        "pitchDeg": pitch,
        "pitchClass": pitch_class(pitch, cfg["pitchClasses"]),
        "form": form,
        "points": extras["points"],
        "confidence": roof_confidence(extras["cover"], extras["density"], res.get("coverage"), form, cfg["confidence"]),
    }
    return rec


def block_id(way_ids):
    """Stable block id: 'blk-' + first 8 hex of sha1 over the sorted bounding street way ids joined by commas."""
    key = ",".join(str(i) for i in sorted(int(i) for i in way_ids))
    return "blk-" + hashlib.sha1(key.encode()).hexdigest()[:8]


def assign_to_faces(face_polys, xy):
    """Index of the face containing each point (the smallest face when a point sits on a shared boundary), -1 when
    none. face_polys: shapely polygons; xy: (n, 2) array."""
    import shapely
    xy = np.asarray(xy, float).reshape(-1, 2)
    out = np.full(len(xy), -1, dtype=int)
    best_area = np.full(len(xy), np.inf)
    for i, f in enumerate(face_polys):
        hit = shapely.covers(f, shapely.points(xy[:, 0], xy[:, 1])) if len(xy) else np.zeros(0, bool)
        upd = hit & (f.area < best_area)
        out[upd] = i
        best_area[upd] = f.area
    return out


def mix_of(records, min_n, pc):
    """Roof-mix of a list of lidar-roofs records: n, shares (form and pitch class), median pitch. Shares and
    median are None when fewer than `min_n` records (privacy floor)."""
    n = len(records)
    out = {"nClassified": n, "suppressed": n < min_n}
    if n < min_n:
        out.update({"shares": None, "pitchClassShares": None, "medianPitchDeg": None})
        return out
    fc = Counter(r["form"] for r in records)
    pcc = Counter(r["pitchClass"] for r in records)
    out["shares"] = {f: round(fc.get(f, 0) / n, 3) for f in FORMS}
    out["pitchClassShares"] = {c: round(pcc.get(c, 0) / n, 3) for c in PITCH_CLASSES}
    out["medianPitchDeg"] = round(float(statistics.median(r["pitchDeg"] for r in records if r["pitchDeg"] is not None)), 1)
    return out


# ---------------------------------------------------------------- footprints: OSM plus Overture (the engine's merge)


def overture_ref(gers):
    """The engine's ref of an Overture feature (Sources/WorldMap/OvertureSource.swift `OSMRef.init(overtureID:)`):
    the first 16 hex digits of the GERS id (hyphens ignored) as a UInt64, stored bit for bit in a signed Int64,
    written 'overture/<int64>'. None when the id has fewer than 16 hex digits."""
    hexs = "".join(c for c in gers if c != "-")[:16]
    if len(hexs) != 16:
        return None
    try:
        v = int(hexs, 16)
    except ValueError:
        return None
    if v >= 1 << 63:
        v -= 1 << 64
    return f"overture/{v}"


def osm_building_union(pilot, man, root=None):
    """Every OSM building and building:part footprint of the area's osm.json (also those whose centroid is outside
    the area), as one shapely geometry: the engine drops an Overture footprint whose centroid is inside it."""
    import shapely
    from shapely.geometry import Polygon
    with open(os.path.join(root or REPO, pilot["area"], "osm.json")) as f:
        osm = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in osm["elements"] if e["type"] == "node"}
    polys = []
    for w in osm["elements"]:
        t = w.get("tags", {}) if w["type"] == "way" else {}
        if w["type"] != "way" or not ("building" in t or "building:part" in t) or t.get("area") == "no":
            continue
        if len(w["nodes"]) < 4 or w["nodes"][0] != w["nodes"][-1]:
            continue
        pts = [nodes[i] for i in w["nodes"] if i in nodes]
        if len(pts) < 4:
            continue
        e, n = rp.local_en(lat0, lon0, [p[0] for p in pts], [p[1] for p in pts])
        polys.append(Polygon(list(zip(e.tolist(), n.tolist()))).buffer(0))
    return shapely.union_all(polys) if polys else None


def overture_footprints(pilot, man, root=None):
    """Overture buildings the engine adds on top of OSM (OvertureBuildings.merge): records with no OpenStreetMap
    source, a footprint centroid inside the area and outside every OSM building or part; ids sorted, a repeated
    ref (two GERS ids sharing 16 hex digits) keeps the first. A record with several polygons keeps its largest
    polygon (one key per ref). Returns ({ref: {"poly", "tags"}}, report)."""
    from shapely.geometry import Polygon
    import shapely
    with open(os.path.join(root or REPO, pilot["area"], "overture-buildings.json")) as f:
        ov = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    union = osm_building_union(pilot, man, root)
    out, seen_ids, seen_refs = {}, set(), {}
    rep = Counter()
    for r in sorted(ov["buildings"], key=lambda r: r["id"]):
        if r["id"] in seen_ids:
            continue
        seen_ids.add(r["id"])
        rep["records"] += 1
        if any(s.get("dataset") == "OpenStreetMap" for s in r["sources"]):
            rep["droppedOsmSource"] += 1
            continue
        ref = overture_ref(r["id"])
        if ref is None:
            rep["skipped"] += 1
            continue
        if ref in seen_refs and seen_refs[ref] != r["id"]:
            rep["refCollision"] += 1
            continue
        seen_refs[ref] = r["id"]
        best, inside_osm, outside = None, False, False
        for rings in r["polygons"]:
            conv = []
            for ring in rings:
                e, n = rp.local_en(lat0, lon0, [c[1] for c in ring], [c[0] for c in ring])
                conv.append(list(zip(e.tolist(), n.tolist())))
            if len(conv[0]) < 4:
                continue
            poly = Polygon(conv[0], conv[1:]).buffer(0)
            if poly.is_empty:
                continue
            c = poly.centroid
            if not (abs(c.x) <= hw and abs(c.y) <= hh):
                outside = True
                continue
            if union is not None and shapely.contains_xy(union, c.x, c.y):
                inside_osm = True
                continue
            if poly.area < 1.0:
                continue
            if best is None or poly.area > best.area:
                best = poly
        if best is None:
            rep["droppedInsideOsm" if inside_osm else "droppedOutsideBounds" if outside else "skipped"] += 1
            continue
        out[ref] = {"poly": best, "tags": {"overture:id": r["id"]}}
        rep["added"] += 1
        if len(r["polygons"]) > 1:
            rep["multiPolygonRecords"] += 1
    return out, dict(rep)


def all_footprints(L, pilot, man, area):
    """OSM footprints (L.footprints) plus, when the area lists `overture`, the Overture ones the engine adds.
    Returns (fps, osm_timestamp, overture report or None)."""
    fps, osm_ts = L.footprints(pilot, man)
    if not area.get("overture"):
        return fps, osm_ts, None
    ov, rep = overture_footprints(pilot, man)
    for k, v in ov.items():
        fps[k] = v
    return fps, osm_ts, rep


# ---------------------------------------------------------------- area pipeline


def area_cfg(cfg, area):
    return {"area": area["area"], "ept": cfg["ept"], "marginMeters": area.get("marginMeters", cfg["marginMeters"])}


def cmd_fetch(args, cfg, area, work):
    import lidar as L
    pilot = area_cfg(cfg, area)
    man = L.area_manifest(pilot)
    box = L.area_box_merc(man, pilot["marginMeters"])
    ept, nodes = L.hierarchy(pilot, work, box)
    depth = cfg["ept"]["maxDepth"]
    keys = sorted((k for k in nodes if int(k.split("-")[0]) <= depth), key=lambda k: [int(v) for v in k.split("-")])
    total = sum(e["bytes"] for e in work.ledger() if e["kind"] == "ept-data")
    for i, key in enumerate(keys):
        path = work.p("ept", "data", key + ".laz")
        if os.path.exists(path):
            continue
        if total > cfg["ept"]["maxBytesPerArea"]:
            sys.exit(f"byte cap reached ({total:,} bytes); stopping before {key}")
        body = L.http(cfg["ept"]["root"] + f"ept-data/{key}.laz", work, "ept-data")
        total += len(body)
        with open(path, "wb") as f:
            f.write(body)
        if i % 20 == 0:
            log(f"[fetch {area['id']}] {i + 1}/{len(keys)} nodes, {total / 1e6:.1f} MB")
    log(f"[fetch {area['id']}] {len(keys)} nodes, {total:,} bytes of LAZ")


def prepare_points(cfg, area, work):
    """Load, shift and index the lidar of one area. Returns a dict of everything the per-footprint loop needs."""
    import lidar as L
    import heights as H
    pilot = area_cfg(cfg, area)
    params = L.load("params.json")
    hprm = H.load_params()
    man = L.area_manifest(pilot)
    fps, osm_ts, ov_report = all_footprints(L, pilot, man, area)
    if ov_report:
        log(f"[{area['id']}] overture footprints: {ov_report}")
    pts, stats = L.load_points(work, man, pilot["marginMeters"])
    log(f"[{area['id']}] points {stats}")
    ground_h = L.ground_model(pts[2], params["groundCell"])
    bld_all = pts[6]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    shift_in = bld_all[(bld_all[:, 2] - ground_h(bld_all[:, 0], bld_all[:, 1])) >= params["minHeightAboveGround"]]
    shift = L.global_shift(shift_in, fps, hw, hh, params)
    log(f"[{area['id']}] global lidar shift {shift}")
    for arr in (pts[2], bld_all):
        arr[:, 0] += shift["eastMeters"]
        arr[:, 1] += shift["northMeters"]
    ground_h = L.ground_model(pts[2], params["groundCell"])
    height = bld_all[:, 2] - ground_h(bld_all[:, 0], bld_all[:, 1])
    return {"L": L, "H": H, "params": params, "hprm": hprm, "man": man, "fps": fps, "osm_ts": osm_ts, "overture": ov_report, "stats": stats,
            "ground": pts[2], "ground_h": ground_h, "shift": shift, "hw": hw, "hh": hh,
            "bld2": bld_all[height >= params["minHeightAboveGround"]],
            "bld1": bld_all[height >= hprm["minHeightAboveGround"]]}


def cmd_measure(args, cfg, area, work):
    """Per footprint: points, cover, height measure and the plane raster (planes, cells, cell->plane), pickled in
    the work directory (`raster_dump.pkl`); then `emit` writes lidar-roofs.json from it."""
    import pickle
    import shapely
    from scipy.spatial import cKDTree
    D = prepare_points(cfg, area, work)
    L, H, params, hprm = D["L"], D["H"], D["params"], D["hprm"]
    idx2, idx1, gidx = L.PointIndex(D["bld2"]), L.PointIndex(D["bld1"]), L.PointIndex(D["ground"])
    wide = hprm["groundRing"]["wideOuterM"]
    hw, hh = D["hw"], D["hh"]
    items, skipped = {}, Counter()
    n_fp = 0
    t0 = time.time()
    for i, (fid, fp) in enumerate(sorted(D["fps"].items())):
        poly = fp["poly"]
        c = poly.centroid
        if not (abs(c.x) <= hw and abs(c.y) <= hh):
            continue
        n_fp += 1
        if poly.area < params["minFootprintM2"]:
            skipped["tooSmallFootprint"] += 1
            continue
        ras = L.roof_raster(poly, params)
        if ras is None:
            skipped["erodedAway"] += 1
            continue
        er, _, gx, gy, inside = ras
        cb = idx2.query(er.bounds)
        P = D["bld2"][cb][shapely.contains_xy(er, D["bld2"][cb, 0], D["bld2"][cb, 1])] if len(cb) else np.zeros((0, 3), np.float32)
        n_cells = int(inside.sum())
        cover = 0.0
        if len(P):
            d, _ = cKDTree(P[:, :2]).query(np.stack([gx[inside], gy[inside]], axis=1), distance_upper_bound=params["fillDist"])
            cover = float(np.isfinite(d).mean())
        if len(P) < cfg["skip"]["minPoints"]:
            skipped["noLidarBuilding" if cover < hprm["noBuildingMaxCover"] else "tooFewPoints"] += 1
            continue
        if cover < cfg["skip"]["minRoofCover"]:
            skipped["partialCover"] += 1
            continue
        rect = L.rect_of(er)
        pl = rp.planes_from_points(P, gx, gy, inside, params)
        cbh = idx1.query(poly.buffer(1).bounds)
        cg = gidx.query(poly.buffer(wide).bounds)
        hts = H.measure(poly, D["bld1"][cbh], D["ground"][cg], hprm, fallback_ground=float(D["ground_h"](c.x, c.y)))
        extras = {"points": int(len(P)), "cover": cover, "density": len(P) / (n_cells * params["cell"] ** 2)}
        items[fid] = {"raster": None if pl is None else {"planes": pl[0], "cells": pl[1].astype(np.float32), "cellPlane": pl[2].astype(np.int32), "area": pl[3]},
                      "rect": rect, "hts": hts, "extras": extras, "footprintM2": float(poly.area)}
        if i % 400 == 0:
            log(f"[{area['id']}] {i}/{len(D['fps'])} ({time.time() - t0:.0f} s)")
    meta = {"nFp": n_fp, "skipped": dict(skipped), "shift": D["shift"], "osmTs": D["osm_ts"], "overture": D["overture"]}
    with open(work.p("raster_dump.pkl"), "wb") as f:
        pickle.dump({"items": items, "meta": meta}, f)
    log(f"[{area['id']}] raster dump: {len(items)} footprints with a plane raster, skipped {dict(skipped)}")


def classify_items(items, cfg, rules):
    """Run the classifier and the record builder on pickled rasters. Returns (records, skipped counter, per-ref detail
    {baseForm, reasons, mansard, planes})."""
    cls_params = load_params()["classify"]
    records, skipped, detail = {}, Counter(), {}
    for fid, it in sorted(items.items()):
        ras = it["raster"]
        if ras is None:
            skipped["unclassifiable"] += 1
            continue
        res = rp.classify_roof(ras["planes"], ras["cells"], ras["cellPlane"], it["rect"], ras["area"], cls_params, rules)
        if res["form"] == "unknown":
            skipped["unclassifiable"] += 1
            continue
        rec = make_record(res, ras["planes"], it["rect"], it["hts"], it["extras"], cfg, cls_params)
        if rec is None or rec["topM"] is None:
            skipped["noHeight"] += 1
            continue
        records[fid] = rec
        detail[fid] = {"baseForm": res["form"], "reasons": res["reasons"], "simple": res["simple"],
                       "mansard": mansard_rule(ras["planes"], it["rect"], cls_params, cfg["mansard"])}
    return records, skipped, detail


def load_params():
    with open(os.path.join(HERE, "data", "params.json")) as f:
        return json.load(f)


def load_dump(work):
    import pickle
    with open(work.p("raster_dump.pkl"), "rb") as f:
        return pickle.load(f)


def cmd_emit(args, cfg, area, work):
    """lidar-roofs.json from the raster dump with the classifier chosen by --classifier (v2 default, v1 = the 1.0 rules)."""
    dump = load_dump(work)
    rules = None if args.classifier == "v1" else cfg["classifier"]["rules"]
    records, skipped, _ = classify_items(dump["items"], cfg, rules)
    meta = dump["meta"]
    sk = Counter(meta["skipped"])
    sk.update(skipped)
    write_lidar_roofs(cfg, area, meta, records, sk, meta["nFp"], args.classifier)


def hand_check_numbers():
    with open(os.path.join(HERE, "results", "handcheck.json")) as f:
        hc = json.load(f)
    mans = None
    p = os.path.join(HERE, "results", "mansard-handcheck.json")
    if os.path.exists(p):
        with open(p) as f:
            mans = json.load(f)
    return hc, mans


def footprints_header(area, D):
    note = ("closed building ways and building multipolygons whose centroid is inside the area; keys are OSM refs "
            "(way/<id>, relation/<id>)")
    out = {"source": f"{area['area']}/osm.json", "osmTimestamp": D["osmTs"], "note": note}
    if D.get("overture"):
        out["source"] = [f"{area['area']}/osm.json", f"{area['area']}/overture-buildings.json"]
        out["overtureMerge"] = D["overture"]
        out["note"] = (note + "; plus the Overture buildings the engine adds (no OpenStreetMap source, centroid in the area and outside every "
                       "OSM building or part), keyed by the engine's ref: overture/<signed int64 of the first 16 hex digits of the GERS id> "
                       "(Sources/WorldMap/OvertureSource.swift OSMRef.init(overtureID:))")
    return out


def hand_check_header(area_id, mans):
    """Header block on how well the forms were checked. 2.0: the NAIP hand check of results/roofaccuracy.json (test set,
    per area), the pilot's check, and the mansard rule, which stays UNVALIDATED."""
    out = {}
    p = os.path.join(HERE, "results", "roofaccuracy.json")
    if os.path.exists(p):
        with open(p) as f:
            acc = json.load(f)
        t = acc["sets"]["test"]
        row = lambda d: {  # noqa: E731
            "n": d["n"], "cantTell": d["nCantTell"], "accuracy": d["accuracy"], "wilson95": d["wilson95"],
            "simpleCalledComplexRate": d["simpleCalledComplex"]["rate"], "complexCalledSimpleRate": d["complexCalledSimple"]["rate"]}
        out["roofAccuracy"] = {
            "what": "forms hand-labelled from NAIP 0.3 m imagery (roofs the 1.0 classifier had classified, stable seeded sample of about 50 per area, labels frozen before the rule changed); accuracy = share of labelled roofs whose lidar form equals the hand label, roofs the labeller could not read excluded",
            "methodVersions": acc["methodVersions"],
            "thisArea": ({"before": row(t[area_id]["before"]), "after": row(t[area_id]["after"])} if area_id in t else
                         "not hand-checked: no NAIP sample was labelled here; the rule was checked on evanston-south and lakeview-sheil-park (pooled below)"),
            "pooledEvanstonAndLakeview": {"before": row(t["pooled"]["before"]), "after": row(t["pooled"]["after"])},
            "target": 0.8,
            "details": "Tools/regionkit/lidar/results/roofaccuracy.json; docs/research/lidar-roofs.md section 15",
        }
    out["pilotCheck"] = "30 South Evanston roofs (houses and garages), labelled from the lidar points themselves, 1.0 rules: simple form 26 of 30, four classes 24 of 30 (docs section 4)"
    out["mansard"] = ("UNVALIDATED. The mansard rule (steep planes round a flat or low top) is unchanged from 1.0 and was set on a single flagged roof "
                      "(a truncated hip, not a classic mansard); no independent mansard sample exists, so its precision and recall are unknown")
    out["scope"] = "hand-labelled areas: South Evanston (houses, garages) and Lakeview (flat-roofed rows and courtyard buildings); the suburban areas Wilmette, Winnetka and Kenilworth were not hand-checked"
    return out


def write_lidar_roofs(cfg, area, D, records, skipped, n_fp, classifier="v2"):
    _, mans = hand_check_numbers()
    forms = Counter(r["form"] for r in records.values())
    classes = Counter(r["pitchClass"] for r in records.values())
    n = len(records)
    header = {
        "format": "lidar-roofs/1",
        "area": area["id"],
        "source": {
            "dataset": cfg["ept"]["dataset"],
            "usgsProject": cfg["ept"]["tnmProject"],
            "delivery": cfg["ept"]["tnmDelivery"],
            "access": "Entwine Point Tiles, public usgs-lidar-public bucket (AWS Open Data), anonymous HTTPS, octree depth <= " + str(cfg["ept"]["maxDepth"]),
            "flightDates": cfg["flight"]["dates"],
            "flightDatesNote": cfg["flight"]["source"],
            "points": "vendor building class (6) at least 2 m above a 5 m ground grid (classification) / 1 m (heights); about 4 points per m2 of roof",
        },
        "licence": cfg["licence"]["name"],
        "credit": cfg["licence"]["courtesy"],
        "licenceNote": cfg["licence"]["note"],
        "footprints": footprints_header(area, D),
        "methodVersion": cfg["methodVersion"],
        "method": "docs/research/lidar-roofs.md sections 14 and 15",
        "complexRule": {"version": cfg["methodVersion"], "rules": cfg["classifier"]["rules"],
                        "summary": "2.0 complex rule: touching planes of one slope merged, sloped planes under minorShare of the roof ignored (dormers, porches, chimneys), mixed flat/sloped from a flat share of mixedMinShare, no-opposite-pair needs noPairMinPlanes major planes; fitted on tuning sets, checked on a frozen NAIP hand-labelled test set (handCheck)"},
        "lidarShiftMeters": {"east": D["shift"]["eastMeters"], "north": D["shift"]["northMeters"]},
        "handCheck": hand_check_header(area["id"], mans),
        "pitchClasses": "flat < 10 deg; low 10 to < 25; medium 25 to 40; steep > 40 (pitchDeg = dominant plane slope)",
        "fields": {
            "topM": "roof top above ground, m (95th percentile of building points, ground = median class-2 ring 3 to 8 m around the footprint)",
            "eaveM": "eave height above ground, m (15th percentile of points within 0.5 to 2 m of the footprint edge); null when too few points",
            "pitchDeg": "slope of the dominant plane, degrees; mansard = mean slope of the steep lower planes",
            "pitchClass": "flat / low / medium / steep",
            "form": "flat / gable / hip / mansard / complex (mansard is UNVALIDATED: rule unchanged since 1.0, no independent mansard sample)",
            "points": "building-class lidar points inside the footprint eroded by 0.75 m",
            "confidence": "heuristic 0-1 score (point cover, density, plane coverage, form factor); not a probability",
        },
        "counts": {
            "footprintsInArea": n_fp,
            "classified": n,
            "skipped": dict(sorted(skipped.items())),
            "skippedTotal": int(sum(skipped.values())),
        },
        "shares": {
            "form": {f: round(forms.get(f, 0) / n, 3) for f in FORMS} if n else {},
            "pitchClass": {c: round(classes.get(c, 0) / n, 3) for c in PITCH_CLASSES} if n else {},
        },
    }
    out = {"header": header, "buildings": {k: records[k] for k in sorted(records)}}
    path = os.path.join(REPO, area["area"], "lidar-roofs.json")
    with open(path, "w") as f:
        json.dump(out, f, indent=1)
        f.write("\n")
    log(f"[{area['id']}] wrote {path}: {n} of {n_fp}; {dict(forms)}; skipped {dict(skipped)}")


# ---------------------------------------------------------------- blocks


def street_lines(cfg, area, man):
    """Street centrelines of the area's osm.json in local metres: [(way id, LineString)]."""
    from shapely.geometry import LineString
    with open(os.path.join(HERE, "..", "aerial", "data", "canopy_areas.json")) as f:
        classes = set(json.load(f)["streetClasses"])
    with open(os.path.join(REPO, area["area"], "osm.json")) as f:
        osm = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in osm["elements"] if e["type"] == "node"}
    out = []
    for w in osm["elements"]:
        if w["type"] != "way" or w.get("tags", {}).get("highway") not in classes:
            continue
        pts = [nodes[i] for i in w["nodes"] if i in nodes]
        if len(pts) < 2:
            continue
        e, n = rp.local_en(lat0, lon0, [p[0] for p in pts], [p[1] for p in pts])
        out.append((w["id"], LineString(list(zip(e.tolist(), n.tolist())))))
    return out


def block_faces(streets, box_xy, min_area):
    """Faces of the street network plus the area rectangle, clipped to it (aerial/canopy_areas.block_faces)."""
    from shapely.geometry import box
    from shapely.ops import polygonize, unary_union
    cell = box(*box_xy)
    faces = []
    for f in polygonize(unary_union([ln for _, ln in streets] + [cell.exterior])):
        c = f.intersection(cell)
        if c.is_empty or c.area < min_area:
            continue
        if c.geom_type != "Polygon":
            c = max(c.geoms, key=lambda g: g.area)
        on_edge = f.exterior.intersection(cell.exterior.buffer(0.05)).length
        faces.append({"poly": c, "clipped": bool(on_edge >= 1.0)})
    return faces


def bounding_ways(face_poly, streets, bcfg):
    """Street way ids that run along the face boundary (>= idMinSharedLengthM of a way within idBoundaryBufferM)."""
    ring = face_poly.exterior.buffer(bcfg["idBoundaryBufferM"])
    ids = []
    for wid, ln in streets:
        shared = ln.intersection(ring).length
        if shared >= min(bcfg["idMinSharedLengthM"], 0.8 * ln.length):
            ids.append(wid)
    return ids


def cmd_blocks(args, cfg, area, work):
    import lidar as L
    pilot = area_cfg(cfg, area)
    man = L.area_manifest(pilot)
    bcfg = cfg["blocks"]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    with open(os.path.join(REPO, area["area"], "lidar-roofs.json")) as f:
        lr = json.load(f)
    fps, _, _ = all_footprints(L, pilot, man, area)
    streets = street_lines(cfg, area, man)
    faces = block_faces(streets, (-hw, -hh, hw, hh), bcfg["minAreaM2"])
    polys = [f["poly"] for f in faces]
    all_ids = sorted(k for k, fp in fps.items() if abs(fp["poly"].centroid.x) <= hw and abs(fp["poly"].centroid.y) <= hh)
    xy = np.array([[fps[k]["poly"].centroid.x, fps[k]["poly"].centroid.y] for k in all_ids])
    which = assign_to_faces(polys, xy)
    per_face = {i: [] for i in range(len(faces))}
    unassigned = 0
    for k, w in zip(all_ids, which):
        if w < 0:
            unassigned += 1
        else:
            per_face[int(w)].append(k)
    # Stable ids; a collision (two faces with the same bounding-street set) gets -2, -3 ... in order of centroid (north, then east).
    rows = []
    for i, f in enumerate(faces):
        ways = bounding_ways(f["poly"], streets, bcfg)
        c = f["poly"].representative_point() if not f["poly"].centroid.within(f["poly"]) else f["poly"].centroid
        rows.append({"i": i, "ways": ways, "c": c, "base": block_id(ways)})
    seen = Counter()
    for r in sorted(rows, key=lambda r: (r["base"], -round(r["c"].y, 1), round(r["c"].x, 1))):
        seen[r["base"]] += 1
        r["id"] = r["base"] if seen[r["base"]] == 1 else f"{r['base']}-{seen[r['base']]}"
    blocks = []
    for r in sorted(rows, key=lambda r: r["id"]):
        i = r["i"]
        fp_ids = per_face[i]
        recs = [lr["buildings"][k] for k in fp_ids if k in lr["buildings"]]
        cen = faces[i]["poly"].centroid
        lat, lon = rp.local_to_latlon(lat0, lon0, np.array([cen.x]), np.array([cen.y]))
        b = {"id": r["id"], "centroid": {"lat": round(float(np.ravel(lat)[0]), 6), "lon": round(float(np.ravel(lon)[0]), 6)},
             "areaM2": round(faces[i]["poly"].area), "clippedByAreaEdge": faces[i]["clipped"],
             "boundingStreetWays": sorted(r["ways"]), "nBuildings": len(fp_ids)}
        b.update(mix_of(recs, bcfg["minBuildings"], cfg["pitchClasses"]))
        blocks.append(b)
    all_recs = list(lr["buildings"].values())
    pub = [b for b in blocks if not b["suppressed"]]
    summary = {
        "buildingsInArea": len(all_ids), "buildingsOutsideAnyBlock": unassigned, "buildingsClassified": len(all_recs),
        "blocks": len(blocks), "blocksWithShares": len(pub), "blocksSuppressed": len(blocks) - len(pub),
        "blocksClipped": sum(1 for b in blocks if b["clippedByAreaEdge"]),
        "buildingsInPublishedBlocks": sum(b["nClassified"] for b in pub),
    }
    summary.update(mix_of(all_recs, 1, cfg["pitchClasses"]))
    summary["note"] = "area-level mix over every classified footprint (not only those in published blocks)"
    h = lr["header"]
    out = {"header": {
        "format": "roof-mix-blocks/1", "area": area["id"], "derivedFrom": "lidar-roofs.json (same directory)",
        "source": h["source"]["dataset"], "flightDates": h["source"]["flightDates"], "licence": h["licence"], "credit": h["credit"],
        "methodVersion": cfg["methodVersion"],
        "blocks": "faces of the OSM street centrelines (highway classes as Tools/regionkit/aerial canopy_areas.json streetClasses) plus the area rectangle, clipped to it; faces under 50 m2 dropped",
        "blockId": "blk- + first 8 hex of sha1 over the sorted OSM way ids of the street ways running along the face boundary, comma-joined; a repeat of the same set gets -2, -3; changes if OSM splits or merges those ways",
        "assignment": "a building is in the face that contains its footprint centroid",
        "privacyFloor": f"shares, pitchClassShares and medianPitchDeg are null when fewer than {bcfg['minBuildings']} classified buildings (suppressed: true)",
        "shares": "fractions of nClassified (buildings with a lidar form), keys flat/hip/gable/mansard/complex",
    }, "summary": summary, "blocks": blocks}
    path = os.path.join(REPO, area["area"], "roof-mix-blocks.json")
    with open(path, "w") as f:
        json.dump(out, f, indent=1)
        f.write("\n")
    log(f"[{area['id']}] wrote {path}: {summary}")


# ---------------------------------------------------------------- mansard hand-check images (scratch only)


def cmd_mansard(args, cfg, area, work):
    """Scratch images for the mansard hand check: the flagged roofs and the highest near-misses (height surface by
    facet colour plus two side views). Work directory only."""
    from PIL import Image, ImageDraw
    from scipy import ndimage
    from scipy.spatial import cKDTree
    D = prepare_points(cfg, area, work)
    L = D["L"]
    _, _, dump = classify_items(load_dump(work)["items"], cfg, cfg["classifier"]["rules"])
    flagged = [k for k, v in dump.items() if v["mansard"]["mansard"]]
    near = sorted((k for k, v in dump.items() if not v["mansard"]["mansard"] and v["mansard"]["steepShare"] > 0.12),
                  key=lambda k: -dump[k]["mansard"]["steepShare"])
    pick = [r for r in (args.refs or "").split(",") if r in dump] or flagged[: args.n] + near[: args.n]
    bidx = L.PointIndex(D["bld1"])
    key = []
    px, up = 0.5, 10
    for k in pick:
        poly = D["fps"][k]["poly"]
        x0, y0, x1, y1 = poly.buffer(3).bounds
        P = D["bld1"][bidx.query((x0, y0, x1, y1))]
        P = P[(P[:, 0] >= x0) & (P[:, 0] <= x1) & (P[:, 1] >= y0) & (P[:, 1] <= y1)]
        h = P[:, 2] - D["ground_h"](P[:, 0], P[:, 1])
        W, Hh = int((x1 - x0) / px) + 1, int((y1 - y0) / px) + 1
        gx, gy = np.meshgrid(x0 + (np.arange(W) + 0.5) * px, y1 - (np.arange(Hh) + 0.5) * px)
        dsm = np.full((Hh, W), np.nan)
        if len(P):
            tree = cKDTree(P[:, :2])
            nb = tree.query_ball_point(np.stack([gx.ravel(), gy.ravel()], axis=1), r=0.9)
            dsm = np.array([float(np.mean(h[j])) if len(j) else np.nan for j in nb]).reshape(Hh, W)
        filled = np.where(np.isnan(dsm), np.nanmin(dsm), dsm)
        sm = ndimage.uniform_filter(filled, 3)
        gyy, gxx = np.gradient(sm, px)
        slope = np.degrees(np.arctan(np.hypot(gxx, gyy)))
        aspect = (np.degrees(np.arctan2(-gxx, gyy)) % 360.0)
        hsv = np.zeros((Hh, W, 3))
        hsv[..., 0] = aspect / 360.0
        hsv[..., 1] = np.clip((slope - 8) / 25, 0, 1)
        hsv[..., 2] = 0.55 + 0.45 * np.clip(sm / max(np.nanmax(dsm), 1), 0, 1)
        rgb = np.asarray(Image.fromarray((hsv * 255).astype(np.uint8), "HSV").convert("RGB")).copy()
        rgb[np.isnan(dsm)] = (0, 0, 0)
        img = Image.fromarray(rgb).resize((W * up, Hh * up), Image.NEAREST)
        d = ImageDraw.Draw(img)
        rings = [poly] if poly.geom_type == "Polygon" else list(poly.geoms)
        for g in rings:
            d.line([((x - x0) / px * up, (y1 - y) / px * up) for x, y in g.exterior.coords], fill=(255, 255, 255), width=2)
        cx, cy, ux, uy, hl, hs = L.rect_of(poly)
        hmax = max(float(np.percentile(h, 99)) if len(h) else 8, 8) + 1
        panels = []
        for ax in ((ux, uy), (-uy, ux)):
            s = (P[:, 0] - cx) * ax[0] + (P[:, 1] - cy) * ax[1]
            span = max(hl, hs) + 3
            pan = Image.new("RGB", (int(2 * span * 20), int(hmax * 20)), (25, 25, 25))
            dd = ImageDraw.Draw(pan)
            for sv, hv in zip(s, h):
                X, Y = (sv + span) * 20, (hmax - hv) * 20
                dd.ellipse((X - 1, Y - 1, X + 1, Y + 1), fill=(240, 210, 130))
            panels.append(pan)
        sw = max(img.width, panels[0].width, panels[1].width)
        sheet = Image.new("RGB", (sw, 20 + img.height + panels[0].height + panels[1].height + 8), (0, 0, 0))
        sheet.paste(img, (0, 20))
        sheet.paste(panels[0], (0, 20 + img.height + 4))
        sheet.paste(panels[1], (0, 20 + img.height + panels[0].height + 8))
        name = f"{area['id']}_{len(key) + 1:02d}"
        ImageDraw.Draw(sheet).text((3, 4), name, fill=(255, 255, 255))
        sheet.save(work.p("mansard", name + ".png"))
        key.append({"image": name, "ref": k, "flagged": k in flagged, "mansard": dump[k]["mansard"], "baseForm": dump[k]["baseForm"],
                    "footprintM2": round(poly.area)})
    with open(work.p("mansard", f"key_{area['id']}.json"), "w") as f:
        json.dump(key, f, indent=1)
    log(f"[{area['id']}] flagged {len(flagged)}; {len(key)} images in {work.p('mansard')}")


# ---------------------------------------------------------------- main


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["fetch", "measure", "emit", "blocks", "mansard", "all"])
    ap.add_argument("--classifier", choices=["v1", "v2"], default="v2", help="emit/all: v1 = the 1.0 complex rule (reproduces the first committed files), v2 = the current one")
    ap.add_argument("--work", required=True)
    ap.add_argument("--area", help="one area id (default: all in data/roofhints.json)")
    ap.add_argument("--refs", help="mansard: comma-separated OSM refs to render instead of the flagged and near-miss roofs")
    ap.add_argument("--n", type=int, default=12, help="mansard: images per group (flagged, near-miss)")
    args = ap.parse_args()
    import lidar as L
    cfg = load_cfg()
    work_root = args.work
    fns = {"fetch": [cmd_fetch], "measure": [cmd_measure], "emit": [cmd_emit], "blocks": [cmd_blocks], "mansard": [cmd_mansard],
           "all": [cmd_fetch, cmd_measure, cmd_emit, cmd_blocks]}[args.cmd]
    for area in cfg["areas"]:
        if args.area and area["id"] != args.area:
            continue
        work = L.Work(os.path.join(work_root, area["id"]))
        for fn in fns:
            fn(args, cfg, area, work)


if __name__ == "__main__":
    main()
