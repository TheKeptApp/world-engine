#!/usr/bin/env python3
"""Overture building heights vs USGS 3DEP lidar building heights.

Offline research tool for WorldEngine's region kit (not part of the engine or any app). Method and
results: docs/research/overture-source.md, section "Heights vs lidar". Every per-building value stays in
the work directory (outside the repository, refused inside it); only aggregates go to results/.

For each Overture record of a committed test area (a height is not required to measure it, but only
records with a height are compared):
  ground   = median of lidar class-2 points in a 3-8 m ring around the footprint (15 m when the ring has
             too few points, else the 5 m ground model);
  top      = p95 of class-6 (building) points inside the footprint eroded by 0.5 m, minus ground;
  eave     = p15 of class-6 points in the band 0.5-2 m inside the footprint edge, minus ground;
  span     = top - eave (the roof rise as the lidar sees it).
Records with too few building points, or too little roof cover, are counted and left out (they did not
exist in 2017, or the footprint is off).

Subcommands (all take --work DIR, never inside the repository):
  plan      EPT nodes that meet the area box, their sizes (HTTP HEAD, no body) and the depth the byte budget allows
  fetch     read those nodes (LAZ over HTTPS from the public usgs-lidar-public bucket), cached in the work dir
  measure   per Overture record: footprint -> lidar heights (work dir only)
  compare   aggregates -> results/heights-wilmette.json
  all       plan + fetch + measure + compare

Pure functions (no I/O) are tested offline in tests/test_heights.py.
"""

import argparse
import json
import math
import os
import sys
import time
import urllib.request
from collections import Counter

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
RESULTS = os.path.join(HERE, "results")
sys.path.insert(0, HERE)
import roofplanes as rp  # noqa: E402

TOOL_VERSION = "regionkit-lidar-heights 0.1"
MS = "Microsoft ML Buildings"
USGS = "USGS Lidar"
OSM = "OpenStreetMap"
GROUPS = ("msOsmFree", "msOsmMatched", "usgsOsmMatched")


def load_params():
    with open(os.path.join(HERE, "data", "heights.json")) as f:
        return json.load(f)


def log(*a):
    print(*a, file=sys.stderr, flush=True)


# ---------------------------------------------------------------- records and sources


def height_source(rec):
    """(dataset that supplied `height`, basis, matched to OSM) of an Overture record.

    Overture lists, per source, the JSON pointer of the property it supplied (`/properties/height`); the
    entry with no `property` is the geometry source and, by Overture's convention, supplies everything not
    listed elsewhere. So: a `/properties/height` entry names the height's dataset ("property"); otherwise
    the geometry source does ("inferred", not stated by the file). Returns (None, None, osm) with no height.
    """
    srcs = rec.get("sources", [])
    osm = any(s.get("dataset") == OSM for s in srcs)
    if rec.get("height") is None:
        return None, None, osm
    for s in srcs:
        if s.get("property") == "/properties/height":
            return s["dataset"], "property", osm
    root = [s["dataset"] for s in srcs if not s.get("property")]
    non_osm = [d for d in root if d != OSM]
    if non_osm:
        return non_osm[0], "inferred", osm
    return (root[0] if root else None), "inferred", osm


def group_of(dataset, osm_matched):
    """Analysis group: the height dataset, split by whether the record is also an OSM building (then the
    engine drops it: OSM wins)."""
    if dataset == MS:
        return "msOsmMatched" if osm_matched else "msOsmFree"
    if dataset == USGS:
        return "usgsOsmMatched" if osm_matched else "usgsOsmFree"
    return "other"


def record_polygon(rec, lat0, lon0):
    """Shapely geometry (local east/north metres) of an Overture record's MultiPolygon, as the engine's frame."""
    from shapely.geometry import Polygon
    from shapely.ops import unary_union
    polys = []
    for rings in rec["polygons"]:
        conv = []
        for ring in rings:
            e, n = rp.local_en(lat0, lon0, [p[1] for p in ring], [p[0] for p in ring])
            conv.append(list(zip(e.tolist(), n.tolist())))
        if len(conv[0]) >= 4:
            polys.append(Polygon(conv[0], conv[1:]).buffer(0))
    return unary_union(polys) if polys else None


def stratum(area, edges, names):
    """Footprint-area stratum name: edges = [45, 90] -> under45 / 45to90 / 90plus."""
    for e, n in zip(edges, names):
        if area < e:
            return n
    return names[len(edges)]


# ---------------------------------------------------------------- measuring one footprint


def cover_share(P, er, prm):
    """Share of 0.5 m cells inside the eroded footprint with a building point within fillDist."""
    import shapely
    from scipy.spatial import cKDTree
    if len(P) == 0 or er.is_empty:
        return 0.0
    x0, y0, x1, y1 = er.bounds
    gx, gy = rp.raster_cells((x0, y0), (x1, y1), prm["cover"]["cell"])
    inside = shapely.contains_xy(er, gx, gy)
    if not inside.any():
        return 0.0
    d, _ = cKDTree(P[:, :2]).query(np.stack([gx[inside], gy[inside]], axis=1), distance_upper_bound=prm["cover"]["fillDist"])
    return float(np.isfinite(d).mean())


def ground_level(ground, poly, ring):
    """Median z of class-2 points in the ring [innerM, outerM] around the footprint; widens once to wideOuterM
    when there are fewer than minPoints. Returns (z or None, n points, mode 'ring' | 'wide' | 'none')."""
    import shapely
    if len(ground) == 0:
        return None, 0, "none"
    inner = shapely.contains_xy(poly.buffer(ring["innerM"]), ground[:, 0], ground[:, 1])
    n = 0
    for mode, outer_m in (("ring", ring["outerM"]), ("wide", ring["wideOuterM"])):
        m = shapely.contains_xy(poly.buffer(outer_m), ground[:, 0], ground[:, 1]) & ~inner
        n = int(m.sum())
        if n >= ring["minPoints"]:
            return float(np.median(ground[m, 2])), n, mode
    return None, n, "none"


def measure(poly, roof, ground, prm, fallback_ground=None):
    """Lidar heights of one footprint. `poly`: shapely polygon in local metres. `roof`: (n, 3) class-6 points
    (already above `minHeightAboveGround`), `ground`: (n, 3) class-2 points, both near the footprint.
    Returns a dict; `status` is one of tooSmall, eroded, noBuilding (no roof points and no cover: not there
    in 2017 or not classed building), fewPoints, partial (cover below minRoofCover), noGround, ok."""
    import shapely
    out = {"area": round(poly.area, 1)}
    if poly.area < prm["minFootprintM2"]:
        out["status"] = "tooSmall"
        return out
    er = poly.buffer(-prm["footprintErosion"])
    if er.is_empty:
        out["status"] = "eroded"
        return out
    P = roof[shapely.contains_xy(er, roof[:, 0], roof[:, 1])] if len(roof) else roof[:0]
    out["points"] = int(len(P))
    out["cover"] = round(cover_share(P, er, prm), 3)
    if len(P) < prm["minBuildingPoints"]:
        out["status"] = "noBuilding" if out["cover"] < prm["noBuildingMaxCover"] else "fewPoints"
    elif out["cover"] < prm["minRoofCover"]:
        out["status"] = "partial"
    else:
        out["status"] = "ok"
    if len(P) < 3:
        return out
    g, gn, mode = ground_level(ground, poly, prm["groundRing"])
    if g is None:
        g, mode = fallback_ground, "model"
    out.update({"groundN": gn, "groundMode": mode})
    if g is None:
        out["status"] = "noGround" if out["status"] == "ok" else out["status"]
        return out
    z = P[:, 2] - g
    out.update({
        "top": float(np.percentile(z, prm["topPercentile"])),
        "p50": float(np.percentile(z, 50)),
        "p99": float(np.percentile(z, 99)),
        "mean": float(z.mean()),
    })
    eb = prm["eaveBand"]
    core = poly.buffer(-eb["toEdgeM"])
    inband = ~shapely.contains_xy(core, P[:, 0], P[:, 1]) if not core.is_empty else np.ones(len(P), bool)
    out["bandN"] = int(inband.sum())
    if inband.sum() >= eb["minPoints"]:
        zb = z[inband]
        out["eave"] = float(np.percentile(zb, eb["percentile"]))
        out["eaveP10"] = float(np.percentile(zb, 10))
        out["eaveP20"] = float(np.percentile(zb, 20))
        out["span"] = out["top"] - out["eave"]
    return out


# ---------------------------------------------------------------- statistics (pure)


def quantiles(vals, qs=(10, 25, 50, 75, 90)):
    v = np.asarray(vals, float)
    return {"n": int(len(v)), **{f"p{q}": round(float(np.percentile(v, q)), 2) for q in qs}} if len(v) else {"n": 0}


def ols(x, y):
    """(slope, intercept) of y on x by least squares; (None, None) when x has no spread or n < 3."""
    x, y = np.asarray(x, float), np.asarray(y, float)
    if len(x) < 3 or float(np.ptp(x)) < 1e-9:
        return None, None
    s, i = np.polyfit(x, y, 1)
    return float(s), float(i)


def spearman(x, y):
    """Rank correlation (average ranks for ties); None when n < 3 or either side has no spread."""
    from scipy.stats import rankdata
    x, y = np.asarray(x, float), np.asarray(y, float)
    if len(x) < 3 or x.std() == 0 or y.std() == 0:
        return None
    return float(np.corrcoef(rankdata(x), rankdata(y))[0, 1])


def error_stats(ov, ref, within=1.5):
    """Overture height `ov` against a lidar reference `ref` (same buildings, metres)."""
    ov, ref = np.asarray(ov, float), np.asarray(ref, float)
    n = len(ov)
    if n == 0:
        return {"n": 0}
    d = ov - ref
    k = int((np.abs(d) <= within).sum())
    s_ov, i_ov = ols(ref, ov)
    s_ref, i_ref = ols(ov, ref)
    r = float(np.corrcoef(ov, ref)[0, 1]) if n >= 3 and ov.std() > 0 and ref.std() > 0 else None
    rnd = lambda v: None if v is None else round(v, 3)
    return {"n": n, "bias": round(float(d.mean()), 2), "medianError": round(float(np.median(d)), 2),
            "medianAbsError": round(float(np.median(np.abs(d))), 2), "rmse": round(float(np.sqrt((d ** 2).mean())), 2),
            "withinShare": round(k / n, 3), "within95ci": rp.wilson(k, n),
            "pearsonR": rnd(r), "spearmanRho": rnd(spearman(ov, ref)), "slopeOvOnRef": rnd(s_ov), "interceptOvOnRef": rnd(i_ov),
            "slopeRefOnOv": rnd(s_ref), "interceptRefOnOv": rnd(i_ref)}


def low_high(ov, ref, low=6.0, high=7.5):
    """How often Overture says < low where lidar says >= high, and how many Overture heights < low are really >= high."""
    ov, ref = np.asarray(ov, float), np.asarray(ref, float)
    hi, lo = ref >= high, ov < low
    both = int((hi & lo).sum())
    return {"lidarHighN": int(hi.sum()), "overtureLowGivenLidarHigh": both,
            "overtureLowGivenLidarHighShare": round(both / int(hi.sum()), 3) if hi.sum() else None,
            "overtureLowN": int(lo.sum()),
            "lidarHighGivenOvertureLowShare": round(both / int(lo.sum()), 3) if lo.sum() else None,
            "lidarHighGivenOvertureLowCI": rp.wilson(both, int(lo.sum())),
            "overtureLowGivenLidarHighCI": rp.wilson(both, int(hi.sum()))}


def binned_conditional(ov, ref, edges, min_n=5, high=7.5):
    """For each Overture-height bin: n, lidar quantiles and the share of lidar tops >= high."""
    ov, ref = np.asarray(ov, float), np.asarray(ref, float)
    out = []
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (ov >= lo) & (ov < hi)
        label = f"{lo:g}-{hi:g}" if hi < 100 else f"{lo:g}+"
        row = {"overtureBin": label, "n": int(m.sum())}
        if m.sum() >= min_n:
            row.update({"lidarP10": round(float(np.percentile(ref[m], 10)), 2), "lidarMedian": round(float(np.median(ref[m])), 2),
                        "lidarP90": round(float(np.percentile(ref[m], 90)), 2), "lidarHighShare": round(float((ref[m] >= high).mean()), 3)})
        else:
            row["suppressed"] = True
        out.append(row)
    return out


def suppress(stat, n, min_n):
    """A statistic over fewer than min_n buildings is replaced by its count only (privacy floor)."""
    return stat if n >= min_n else {"n": n, "suppressed": True}


def round_half_up(v):
    return int(math.floor(v + 0.5))


def floors_from_height(h, rise, per_floor, min_floors=1):
    """The generator's mapping as the coordinator states it: round((height - roof rise) / perFloor), at least 1."""
    return max(min_floors, round_half_up((h - rise) / per_floor))


def fold_ids(n, folds):
    """Deterministic cross-validation fold of each of n items (by position)."""
    return np.arange(n) % folds


def cv_linear(ov, ref, folds):
    """Out-of-fold prediction of `ref` from `ov` by a line fitted on the other folds."""
    ov, ref = np.asarray(ov, float), np.asarray(ref, float)
    f = fold_ids(len(ov), folds)
    pred = np.empty(len(ov))
    for k in range(folds):
        tr, te = f != k, f == k
        s, i = ols(ov[tr], ref[tr])
        pred[te] = (i + s * ov[te]) if s is not None else float(np.median(ref[tr]))
    return pred


def cv_binned(ov, ref, edges, folds, min_n=5):
    """Out-of-fold prediction of `ref` from `ov`: the median `ref` of the training items in the same ov bin."""
    ov, ref = np.asarray(ov, float), np.asarray(ref, float)
    f = fold_ids(len(ov), folds)
    b = np.clip(np.digitize(ov, edges) - 1, 0, len(edges) - 2)
    pred = np.empty(len(ov))
    for k in range(folds):
        tr, te = f != k, f == k
        glob = float(np.median(ref[tr]))
        meds = {}
        for j in np.unique(b[te]):
            m = tr & (b == j)
            meds[j] = float(np.median(ref[m])) if m.sum() >= min_n else glob
        pred[te] = [meds[j] for j in b[te]]
    return pred


def floors_eval(eff, rise, truth, fallback, per_floor, min_floors=1):
    """Floors the generator would derive from effective heights `eff` (None = no height: `fallback` floors)
    against the floors the lidar implies (`truth`). Returns shares with Wilson intervals."""
    derived = [fallback if h is None else floors_from_height(h, r, per_floor, min_floors) for h, r in zip(eff, rise)]
    n = len(derived)
    d = np.array(derived)
    t = np.asarray(truth)
    exact, lower, higher = int((d == t).sum()), int((d < t).sum()), int((d > t).sum())
    dist = lambda a: {"1": int((a == 1).sum()), "2": int((a == 2).sum()), "3plus": int((a >= 3).sum())}
    return {"n": n, "heightKeptShare": round(sum(h is not None for h in eff) / n, 3) if n else None,
            "exactShare": round(exact / n, 3) if n else None, "exact95ci": rp.wilson(exact, n),
            "lowerThanLidarShare": round(lower / n, 3) if n else None, "higherThanLidarShare": round(higher / n, 3) if n else None,
            "floorsDistribution": dist(d)}


# ---------------------------------------------------------------- work directory, EPT


def work_dir(path):
    import lidar as L
    return L.Work(path)


def head_size(url, L):
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": L.UA})
    with urllib.request.urlopen(req, timeout=120, context=L._ssl()) as r:
        return int(r.headers["Content-Length"])


def node_sizes(prm, work, nodes, L):
    path = work.p("node_sizes.json")
    sizes = json.load(open(path)) if os.path.exists(path) else {}
    todo = [k for k in nodes if k not in sizes]
    for i, k in enumerate(todo):
        sizes[k] = head_size(prm["ept"]["root"] + f"ept-data/{k}.laz", L)
        if i % 50 == 0:
            log(f"[plan] HEAD {i + 1}/{len(todo)}")
    with open(path, "w") as f:
        json.dump(sizes, f)
    return sizes


def plan_depths(nodes, sizes, budget):
    """Cumulative LAZ bytes by depth for the nodes found; returns (per-depth table, deepest depth within budget)."""
    by = {}
    for k in nodes:
        d = int(k.split("-")[0])
        by.setdefault(d, [0, 0])
        by[d][0] += 1
        by[d][1] += sizes[k]
    table, cum, best = {}, 0, None
    for d in sorted(by):
        cum += by[d][1]
        table[d] = {"nodes": by[d][0], "bytes": by[d][1], "cumulativeBytes": cum}
        if cum <= budget:
            best = d
    return table, best


def cmd_plan(args, work):
    import lidar as L
    prm = load_params()
    man = L.area_manifest(prm)
    box = L.area_box_merc(man, prm["marginMeters"])
    ept, nodes = L.hierarchy(prm, work, box)
    sizes = node_sizes(prm, work, list(nodes), L)
    table, best = plan_depths(nodes, sizes, prm["ept"]["nodeBudgetBytes"])
    plan = {"nodes": len(nodes), "depths": table, "deepestWithinBudget": best, "budgetBytes": prm["ept"]["nodeBudgetBytes"]}
    with open(work.p("plan.json"), "w") as f:
        json.dump(plan, f, indent=1)
    print(json.dumps(plan, indent=1))
    return plan


def cmd_fetch(args, work):
    import lidar as L
    prm = load_params()
    man = L.area_manifest(prm)
    box = L.area_box_merc(man, prm["marginMeters"])
    ept, nodes = L.hierarchy(prm, work, box)
    sizes = node_sizes(prm, work, list(nodes), L)
    table, best = plan_depths(nodes, sizes, prm["ept"]["nodeBudgetBytes"])
    depth = args.max_depth if args.max_depth is not None else min(best if best is not None else 0, prm["ept"]["maxDepth"])
    keys = sorted((k for k in nodes if int(k.split("-")[0]) <= depth), key=lambda k: [int(v) for v in k.split("-")])
    need = sum(sizes[k] for k in keys)
    if need > prm["ept"]["budgetBytes"]:
        sys.exit(f"depth {depth} needs {need:,} bytes, over the budget of {prm['ept']['budgetBytes']:,}")
    total = 0
    for i, key in enumerate(keys):
        path = work.p("ept", "data", key + ".laz")
        if os.path.exists(path):
            continue
        body = L.http(prm["ept"]["root"] + f"ept-data/{key}.laz", work, "ept-data")
        total += len(body)
        with open(path, "wb") as f:
            f.write(body)
        if i % 20 == 0:
            log(f"[fetch] {i + 1}/{len(keys)} nodes, {total / 1e6:.1f} MB")
    log(f"[fetch] depth <= {depth}: {len(keys)} nodes; {need:,} bytes planned, {total:,} downloaded this run")
    with open(work.p("fetch.json"), "w") as f:
        json.dump({"depth": depth, "nodes": len(keys), "bytesPlanned": need}, f)


# ---------------------------------------------------------------- measure (per record, work directory only)


def cmd_measure(args, work):
    import lidar as L
    import shapely
    prm = load_params()
    man = L.area_manifest(prm)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    with open(os.path.join(REPO, prm["area"], prm["overtureFile"])) as f:
        ov = json.load(f)
    osm_fps, _ = L.footprints(prm, man)
    osm_union = shapely.union_all([f["poly"] for f in osm_fps.values()]) if osm_fps else None
    pts, stats = L.load_points(work, man, prm["marginMeters"])
    log(f"[measure] points {stats}")
    ground_h = L.ground_model(pts[2], prm["groundCell"])
    bld = pts[6]
    shift_in = bld[(bld[:, 2] - ground_h(bld[:, 0], bld[:, 1])) >= prm["shiftMinHeightAboveGround"]]

    rows = {}
    for rec in ov["buildings"]:
        poly = record_polygon(rec, lat0, lon0)
        if poly is None or poly.is_empty:
            continue
        ds, basis, osm = height_source(rec)
        c = poly.centroid
        rows[rec["id"]] = {"poly": poly, "dataset": ds, "basis": basis, "osm": osm, "group": group_of(ds, osm) if ds else "noHeight",
                           "height": rec.get("height"), "inBox": bool(abs(c.x) <= hw and abs(c.y) <= hh),
                           "insideOsm": bool(osm_union is not None and osm_union.contains(c)),
                           "multi": len(rec["polygons"]) > 1, "klass": rec.get("class")}
    shift = L.global_shift(shift_in, {k: {"poly": r["poly"]} for k, r in rows.items() if r["inBox"]}, hw, hh, prm)
    log(f"[measure] global lidar shift {shift}")
    for arr in (pts[2], bld):
        arr[:, 0] += shift["eastMeters"]
        arr[:, 1] += shift["northMeters"]
    ground_h = L.ground_model(pts[2], prm["groundCell"])
    bld = bld[(bld[:, 2] - ground_h(bld[:, 0], bld[:, 1])) >= prm["minHeightAboveGround"]]
    bidx, gidx = L.PointIndex(bld), L.PointIndex(pts[2])
    wide = prm["groundRing"]["wideOuterM"]
    out = {}
    t0 = time.time()
    for i, (rid, r) in enumerate(sorted(rows.items())):
        rec = {k: v for k, v in r.items() if k != "poly"}
        if r["inBox"] and r["group"] != "noHeight":
            poly = r["poly"]
            cb = bidx.query(poly.buffer(1).bounds)
            cg = gidx.query(poly.buffer(wide).bounds)
            c = poly.centroid
            rec.update(measure(poly, bld[cb], pts[2][cg], prm, fallback_ground=float(ground_h(c.x, c.y))))
        out[rid] = rec
        if i % 200 == 0:
            log(f"[measure] {i}/{len(rows)} ({time.time() - t0:.0f} s)")
    meta = {"pointStats": stats, "globalShift": shift, "release": ov["release"], "records": len(ov["buildings"]),
            "osmFootprints": len(osm_fps)}
    with open(work.p("heights_buildings.json"), "w") as f:
        json.dump({"meta": meta, "buildings": out}, f)
    log(f"[measure] {len(out)} records; status {Counter(r.get('status') for r in out.values())}")


# ---------------------------------------------------------------- compare (aggregates only)


def analysed(r, prm, min_points=None, min_cover=None):
    """A record enters the statistics when it has a height, is in the area, and lidar saw a building:
    at least `minBuildingPoints` building points in the eroded footprint and roof cover >= minRoofCover."""
    if r.get("status") not in ("ok", "partial", "fewPoints", "noBuilding") or r.get("top") is None:
        return False
    return (r.get("points", 0) >= (min_points or prm["minBuildingPoints"])
            and r.get("cover", 0) >= (min_cover or prm["minRoofCover"]))


def status_counts(rows, prm, **kw):
    c = Counter()
    for r in rows:
        if "status" not in r:
            c["notMeasured"] += 1
        elif analysed(r, prm, **kw):
            c["analysed"] += 1
        else:
            c[r["status"] if r["status"] != "ok" else "fewPoints"] += 1
    return dict(c)


def arrays(rows, key):
    return np.array([r[key] for r in rows if r.get(key) is not None], float)


def group_stats(rows, prm, tag):
    """All aggregates for one set of analysed records."""
    tol = prm["tolerance"]
    n = len(rows)
    ov, top = arrays(rows, "height"), arrays(rows, "top")
    out = {"n": n}
    if n == 0:
        return out
    out["overtureHeight"] = quantiles(ov)
    out["lidarTop"] = quantiles(top)
    out["errorVsTop"] = error_stats(ov, top, tol["within"])
    out["lowHigh"] = low_high(ov, top, tol["lowOverture"], tol["highLidar"])
    # Does the Overture height follow the footprint size instead of the building? (rank correlations with area)
    area = arrays(rows, "area")
    rho = lambda a, b: None if spearman(a, b) is None else round(spearman(a, b), 3)
    out["areaSpearman"] = {"overtureHeight": rho(ov, area), "lidarTop": rho(top, area)}
    out["binned"] = binned_conditional(ov, top, prm["heightBinsM"], prm["minGroupN"], tol["highLidar"])
    # Which lidar statistic does the Overture height resemble? Same buildings (those with an eave estimate).
    both = [r for r in rows if r.get("eave") is not None]
    refs = {}
    if both:
        o = arrays(both, "height")
        for name, key in (("top_p95", "top"), ("top_p99", "p99"), ("roofMedian", "p50"), ("roofMean", "mean"), ("eave_p15", "eave")):
            refs[name] = error_stats(o, arrays(both, key), tol["within"])
        mid = (arrays(both, "top") + arrays(both, "eave")) / 2
        refs["midway_top_eave"] = error_stats(o, mid, tol["within"])
        refs["n"] = len(both)
        refs["lidarEave"] = quantiles(arrays(both, "eave"))
        refs["lidarSpan"] = quantiles(arrays(both, "span"))
    out["referenceComparison"] = refs
    return out


def rule_table(rows, prm, per_floor):
    """Floors the generator would derive under each data-side rule, for the given analysed rows."""
    tol, rules, fl = prm["tolerance"], prm["rules"], prm["floors"]
    ov, top = arrays(rows, "height"), arrays(rows, "top")
    area = arrays(rows, "area")
    rise = np.clip([r.get("span") if r.get("span") is not None else 0.0 for r in rows], 0, fl["riseCapM"])
    truth = np.array([floors_from_height(t, s, per_floor, fl["minFloors"]) for t, s in zip(top, rise)])
    fb = fl["defaultFallbackFloors"]
    res = {"lidarFloorsDistribution": {"1": int((truth == 1).sum()), "2": int((truth == 2).sum()), "3plus": int((truth >= 3).sum())}}
    cands = {"keepOvertureHeights": list(ov), "dropAllOvertureHeights": [None] * len(ov)}
    for t in rules["dropBelowM"]:
        cands[f"dropBelow{t:g}"] = [None if h < t else h for h in ov]
    cands[f"dropBelow{rules['dropHouseBelowM']:g}IfFootprintAtLeast{rules['houseMinAreaM2']:g}"] = [
        None if (h < rules["dropHouseBelowM"] and a >= rules["houseMinAreaM2"]) else h for h, a in zip(ov, area)]
    cands[f"dropAllIfFootprintAtLeast{rules['houseMinAreaM2']:g}"] = [None if a >= rules["houseMinAreaM2"] else h for h, a in zip(ov, area)]
    for c in rules["offsetsM"]:
        cands[f"plus{c:g}m"] = [h + c for h in ov]
    if len(ov) >= 2 * rules["cvFolds"]:
        cands["linearCorrectionCV"] = list(cv_linear(ov, top, rules["cvFolds"]))
        cands["binnedCorrectionCV"] = list(cv_binned(ov, top, prm["heightBinsM"], rules["cvFolds"], prm["minGroupN"]))
    cands["lidarTop (ceiling)"] = list(top)
    for name, eff in cands.items():
        e = floors_eval(eff, rise, truth, fb, per_floor, fl["minFloors"])
        kept = [(h, t) for h, t in zip(eff, top) if h is not None]
        if kept:
            e["keptHeightMedianAbsErrorM"] = round(float(np.median([abs(h - t) for h, t in kept])), 2)
        res[name] = e
    return res


def cmd_compare(args, work):
    prm = load_params()
    with open(work.p("heights_buildings.json")) as f:
        D = json.load(f)
    rows = list(D["buildings"].values())
    meta = D["meta"]
    min_n = prm["minGroupN"]
    out = {"tool": TOOL_VERSION, "generated": time.strftime("%Y-%m-%d"),
           "privacy": "Aggregates only; per-building values stay in the work directory. Groups under %d buildings report counts only." % min_n,
           "area": prm["area"], "overtureRelease": meta["release"],
           "lidar": {"dataset": prm["ept"]["dataset"], "acquired": prm["ept"]["acquired"], "pointStats": meta["pointStats"],
                     "globalShift": meta["globalShift"]},
           "thresholds": {k: prm[k] for k in ("footprintErosion", "minFootprintM2", "minHeightAboveGround", "groundRing", "eaveBand",
                                              "topPercentile", "minBuildingPoints", "minRoofCover", "noBuildingMaxCover", "tolerance",
                                              "strataAreaM2", "floors", "rules")}}
    # Records and sources.
    out["records"] = {
        "total": len(rows),
        "byHeightSource": dict(Counter(f"{r['dataset']} ({r['basis']}){' + OSM' if r['osm'] else ''}" for r in rows if r["dataset"])),
        "withoutHeight": sum(1 for r in rows if not r["dataset"]),
        "centroidOutsideArea": sum(1 for r in rows if not r["inBox"]),
        "multipolygon": sum(1 for r in rows if r["multi"]),
    }
    groups = {}
    for g in GROUPS:
        gr = [r for r in rows if r["group"] == g and r["inBox"]]
        if g == "msOsmFree":
            gr_engine = [r for r in gr if not r["insideOsm"]]
            out["records"]["msOsmFreeInsideOsmFootprint"] = len(gr) - len(gr_engine)
            gr = gr_engine
        groups[g] = gr
    groups["msAll"] = groups["msOsmFree"] + groups["msOsmMatched"]
    out["coverage"] = {g: status_counts(gr, prm) for g, gr in groups.items()}
    out["coverageMinPoints50"] = {g: status_counts(gr, prm, min_points=50) for g, gr in groups.items()}
    out["groups"] = {}
    for g, gr in groups.items():
        an = [r for r in gr if analysed(r, prm)]
        entry = {"candidates": len(gr), "analysed": len(an)}
        if len(an) >= min_n:
            entry["all"] = group_stats(an, prm, g)
            entry["byFootprintArea"] = {}
            for name in prm["strataNames"]:
                sub = [r for r in an if stratum(r["area"], prm["strataAreaM2"], prm["strataNames"]) == name]
                entry["byFootprintArea"][name] = group_stats(sub, prm, g) if len(sub) >= min_n else {"n": len(sub), "suppressed": True}
        else:
            entry["suppressed"] = True
        out["groups"][g] = entry
    # Floors under rules, for the engine-relevant group (and its house-sized stratum), three perFloor values.
    out["rules"] = {}
    for g in ("msOsmFree",):
        an = [r for r in groups[g] if analysed(r, prm)]
        houses = [r for r in an if r["area"] >= prm["rules"]["houseMinAreaM2"]]
        out["rules"][g] = {}
        for label, sel in (("all", an), ("houseSized", houses)):
            if len(sel) < min_n:
                continue
            out["rules"][g][label] = {"n": len(sel)}
            for pf in [prm["floors"]["perFloor"]] + prm["floors"]["perFloorSensitivity"]:
                out["rules"][g][label][f"perFloor{pf:g}"] = rule_table(sel, prm, pf)
    # Sensitivity of the headline numbers to the point-count threshold.
    out["sensitivity"] = {}
    for mp in (10, 50):
        an = [r for r in groups["msOsmFree"] if analysed(r, prm, min_points=mp)]
        if len(an) >= min_n:
            o, t = arrays(an, "height"), arrays(an, "top")
            out["sensitivity"][f"minBuildingPoints{mp}"] = {"n": len(an), "errorVsTop": error_stats(o, t, prm["tolerance"]["within"]),
                                                          "lowHigh": low_high(o, t, prm["tolerance"]["lowOverture"], prm["tolerance"]["highLidar"])}
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, "heights-wilmette.json"), "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    log(f"[compare] wrote results/heights-wilmette.json; analysed "
        + ", ".join(f"{g} {e['analysed']}/{e['candidates']}" for g, e in out["groups"].items()))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["plan", "fetch", "measure", "compare", "all"])
    ap.add_argument("--work", required=True, help="work directory outside the repository")
    ap.add_argument("--max-depth", type=int, help="fetch: deepest EPT level to read (default: the deepest within the byte budget)")
    args = ap.parse_args()
    work = work_dir(args.work)
    steps = ["plan", "fetch", "measure", "compare"] if args.command == "all" else [args.command]
    for s in steps:
        globals()["cmd_" + s](args, work)


if __name__ == "__main__":
    main()
