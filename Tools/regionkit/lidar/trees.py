#!/usr/bin/env python3
"""Tree heights and crown radii from USGS 3DEP lidar for committed WorldEngine test areas.

Offline research tool for the region kit; not part of the engine or any app. Method and results:
docs/research/lidar-roofs.md ("Tree heights"). Per-tree values stay in the work directory (outside the
repository); only aggregates go to results/trees.json.

Subcommands (all take --work DIR, never inside the repository; one sub-directory per area):
  plan      EPT hierarchy for each area box: nodes, points and density per depth (no point data)
  fetch     read the EPT octree nodes that meet each area box (LAZ over HTTPS), shared byte cap
  measure   canopy height model -> tree tops -> crown regions -> per-area statistics (aggregates to
            results/trees.json with --write; per-tree values to the work directory); also counts the
            area's mapped OSM trees that carry a height tag; --sensitivity adds a parameter sweep
  crops     scratch-only CHM and side-view crops of a stable sample of trees for visual validation
            (work directory, never committed)
"""

import argparse
import copy
import glob
import hashlib
import json
import math
import os
import sys
import time
from collections import defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lidar as ld  # noqa: E402  (network, EPT hierarchy, footprints, ground model, work directory)
import roofplanes as rp  # noqa: E402
import treeheights as th  # noqa: E402

RESULTS = os.path.join(HERE, "results")


def cfg():
    return ld.load("trees.json")


def area_pilot(conf, aid):
    """A `pilot`-shaped dict (what lidar.py's helpers expect) for one configured area."""
    return {"area": conf["areas"][aid]["area"], "ept": conf["ept"], "marginMeters": conf["marginMeters"]}


def area_work(work, aid):
    return ld.Work(os.path.join(work.root, aid))


def total_bytes(work, ids):
    return sum(e["bytes"] for aid in ids for e in area_work(work, aid).ledger())


# ---------------------------------------------------------------- plan / fetch


def cmd_plan(args, work, conf):
    out = {}
    for aid in args.areas:
        pilot = area_pilot(conf, aid)
        man = ld.area_manifest(pilot)
        box = ld.area_box_merc(man, conf["marginMeters"])
        w = area_work(work, aid)
        ept, nodes = ld.hierarchy(pilot, w, box)
        k = 1 / math.cos(math.radians(man["center"]["latitude"]))
        ground_area = (box[2] - box[0]) * (box[3] - box[1]) / (k * k)
        by_depth = defaultdict(lambda: [0, 0, 0.0])
        for key, count in nodes.items():
            d = int(key.split("-")[0])
            share = rp.rect_overlap_share(rp.ept_node_bounds(ept["bounds"], key), box)
            by_depth[d][0] += 1
            by_depth[d][1] += count
            by_depth[d][2] += count * share
        cum, depths = 0.0, {}
        for d in sorted(by_depth):
            n, pts, inbox = by_depth[d]
            cum += inbox
            depths[d] = {"nodes": n, "pointsInNodes": pts, "cumulativeDensityPerM2": round(cum / ground_area, 2)}
        # EPT dataset bounds in degrees (is the area inside?)
        cb = ept.get("boundsConforming", ept["bounds"])
        lo, la = rp.merc_to_lonlat(cb[0], cb[1])
        hi_lo, hi_la = rp.merc_to_lonlat(cb[3], cb[4])
        out[aid] = {"nodesTotal": len(nodes), "pointsTotalInNodes": sum(nodes.values()), "depths": depths,
                    "boxGroundM2": round(ground_area),
                    "eptConformingBoundsDeg": {"west": float(lo), "south": float(la), "east": float(hi_lo), "north": float(hi_la)}}
        print(aid, json.dumps(out[aid], indent=1))
    return out


def cmd_fetch(args, work, conf):
    cap = conf["ept"]["maxBytesTotal"]
    max_depth = args.max_depth if args.max_depth is not None else conf["ept"]["maxDepth"]
    ids = list(conf["areas"])
    for aid in args.areas:
        pilot = area_pilot(conf, aid)
        man = ld.area_manifest(pilot)
        box = ld.area_box_merc(man, conf["marginMeters"])
        w = area_work(work, aid)
        ept, nodes = ld.hierarchy(pilot, w, box)
        keys = sorted((k for k in nodes if int(k.split("-")[0]) <= max_depth),
                      key=lambda k: [int(v) for v in k.split("-")])
        for i, key in enumerate(keys):
            path = w.p("ept", "data", key + ".laz")
            if os.path.exists(path):
                continue
            tot = total_bytes(work, ids)
            if tot > cap:
                sys.exit(f"byte cap reached ({tot:,} bytes of {cap:,}); stopping before {aid} {key}")
            body = ld.http(pilot["ept"]["root"] + f"ept-data/{key}.laz", w, "ept-data")
            with open(path, "wb") as f:
                f.write(body)
            if i % 25 == 0:
                ld.log(f"[fetch {aid}] {i + 1}/{len(keys)} nodes, total {total_bytes(work, ids) / 1e6:.1f} MB")
        ld.log(f"[fetch {aid}] {len(keys)} nodes done; all areas so far {total_bytes(work, ids):,} bytes")


# ---------------------------------------------------------------- points, footprints, rasters


def load_area_points(w, man, margin):
    """All lidar points of the area box plus margin as local metres: dict e, n, z (float32), cls (uint8).
    Cached as points.npz in the area's work directory."""
    import laspy
    cache = w.p("points.npz")
    if os.path.exists(cache):
        z = np.load(cache)
        return {k: z[k] for k in ("e", "n", "z", "cls")}
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    hw, hh = man["widthMeters"] / 2 + margin, man["heightMeters"] / 2 + margin
    E, N, Z, C = [], [], [], []
    for path in sorted(glob.glob(w.p("ept", "data", "*.laz"))):
        las = laspy.read(path)
        lon, lat = rp.merc_to_lonlat(np.asarray(las.x), np.asarray(las.y))
        e, n = rp.local_en(lat0, lon0, lat, lon)
        ok = (np.abs(e) <= hw) & (np.abs(n) <= hh)
        E.append(e[ok].astype(np.float32))
        N.append(n[ok].astype(np.float32))
        Z.append(np.asarray(las.z)[ok].astype(np.float32))
        C.append(np.asarray(las.classification)[ok].astype(np.uint8))
    pts = {"e": np.concatenate(E), "n": np.concatenate(N), "z": np.concatenate(Z), "cls": np.concatenate(C)}
    np.savez(cache, **pts)
    return pts


def building_polys(conf, aid, man):
    """Building footprints of the area in local metres: the committed OSM buildings and, where the area has one,
    the Overture buildings. Used for diagnostics only (which tops lie inside a footprint)."""
    from shapely.geometry import Polygon
    pilot = area_pilot(conf, aid)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    polys = []
    files = conf["areas"][aid]["footprintFiles"]
    if "osm.json" in files:
        fps, _ = ld.footprints(pilot, man)
        polys += [f["poly"] for f in fps.values()]
    if "overture-buildings.json" in files:
        with open(os.path.join(ld.REPO, pilot["area"], "overture-buildings.json")) as f:
            ov = json.load(f)
        for b in ov["buildings"]:
            for poly in b["polygons"]:
                rings = []
                for ring in poly:
                    lon = [p[0] for p in ring]
                    lat = [p[1] for p in ring]
                    e, n = rp.local_en(lat0, lon0, lat, lon)
                    rings.append(list(zip(e.tolist(), n.tolist())))
                if len(rings[0]) >= 4:
                    polys.append(Polygon(rings[0], rings[1:]).buffer(0))
    return polys


def park_water_polys(conf, aid, man):
    """Parks (of at least fabric.parkMinAreaM2) and water polygons of the area in local metres, from the committed
    osm.json, with the aerial canopy study's tag tables."""
    from shapely.geometry import LineString, Polygon
    from shapely.ops import polygonize, unary_union
    fab = conf["fabric"]
    pilot = area_pilot(conf, aid)
    with open(os.path.join(ld.REPO, pilot["area"], "osm.json")) as f:
        osm = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in osm["elements"] if e["type"] == "node"}
    ways = {e["id"]: e for e in osm["elements"] if e["type"] == "way"}

    def ring(ids):
        p = [nodes[i] for i in ids if i in nodes]
        if len(p) < 2:
            return []
        e, n = rp.local_en(lat0, lon0, [q[0] for q in p], [q[1] for q in p])
        return list(zip(e.tolist(), n.tolist()))

    def matches(tags, table):
        return any(k in tags and (not vals or tags[k] in vals) for k, vals in table.items())
    parks, water = [], []
    for wy in ways.values():
        t = wy.get("tags", {})
        closed = len(wy["nodes"]) >= 4 and wy["nodes"][0] == wy["nodes"][-1]
        if closed and (matches(t, fab["parkTags"]) or matches(t, fab["waterTags"])):
            c = ring(wy["nodes"])
            if len(c) >= 4:
                (water if matches(t, fab["waterTags"]) else parks).append(Polygon(c).buffer(0))
    for rel in (e for e in osm["elements"] if e["type"] == "relation"):
        t = rel.get("tags", {})
        if t.get("type") != "multipolygon" or not (matches(t, fab["parkTags"]) or matches(t, fab["waterTags"])):
            continue
        outer = [LineString(ring(ways[m["ref"]]["nodes"])) for m in rel["members"]
                 if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways and len(ring(ways[m["ref"]]["nodes"])) >= 2]
        inner = [LineString(ring(ways[m["ref"]]["nodes"])) for m in rel["members"]
                 if m["type"] == "way" and m.get("role") == "inner" and m["ref"] in ways and len(ring(ways[m["ref"]]["nodes"])) >= 2]
        if not outer:
            continue
        poly = unary_union(list(polygonize(unary_union(outer))))
        if inner:
            poly = poly.difference(unary_union(list(polygonize(unary_union(inner)))))
        (water if matches(t, fab["waterTags"]) else parks).append(poly)
    return [p for p in parks if p.area >= fab["parkMinAreaM2"]], water


def raster_of(polys, x0, y0, nx, ny, cell, buffer):
    """Boolean (ny, nx) raster, rows increasing northwards, of the polygons grown by `buffer` metres (negative
    shrinks)."""
    from affine import Affine
    from rasterio import features as rfeat
    from shapely.ops import unary_union
    geoms = [p.buffer(buffer) for p in polys]
    geoms = [g for g in geoms if not g.is_empty]
    if not geoms:
        return np.zeros((ny, nx), dtype=bool)
    img = rfeat.rasterize([(unary_union(geoms), 1)], out_shape=(ny, nx), transform=Affine(cell, 0, x0, 0, cell, y0),
                          fill=0, dtype="uint8")
    return img.astype(bool)


def prepare_area(work, conf, aid):
    """Everything per area that does not depend on the detection parameters: points with height above ground, the
    vegetation CHM and the building CHM, and the area, footprint and fabric masks."""
    params = conf["params"]
    cell = params["chmCell"]
    pilot = area_pilot(conf, aid)
    man = ld.area_manifest(pilot)
    w = area_work(work, aid)
    margin = conf["marginMeters"]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    pts = load_area_points(w, man, margin)
    e, n, z, cls = pts["e"], pts["n"], pts["z"], pts["cls"]
    g = cls == params["groundClass"]
    gm = ld.ground_model(np.stack([e[g], n[g], z[g]], axis=1), params["groundCell"])
    hag = z - gm(e, n).astype(np.float32)
    x0, y0 = -(hw + margin), -(hh + margin)
    nx, ny = int(math.ceil(2 * (hw + margin) / cell)), int(math.ceil(2 * (hh + margin) / cell))
    lim = (hag >= params["minHeightAboveGround"]) & (hag <= params["maxHeightAboveGround"])
    veg_cls = np.isin(cls, params["vegetationClasses"])
    v_sel = lim & veg_cls
    b_sel = lim & (cls == params["buildingClass"])
    chm = th.chm_max(e[v_sel], n[v_sel], hag[v_sel], x0, y0, nx, ny, cell)
    chm_b = th.chm_max(e[b_sel], n[b_sel], hag[b_sel], x0, y0, nx, ny, cell)
    cx = (np.arange(nx) + 0.5) * cell + x0
    cy = (np.arange(ny) + 0.5) * cell + y0
    in_box = (np.abs(cx) <= hw)[None, :] & (np.abs(cy) <= hh)[:, None]
    polys = building_polys(conf, aid, man)
    fp_buf = raster_of(polys, x0, y0, nx, ny, cell, params["footprintBuffer"])
    fp_core = raster_of(polys, x0, y0, nx, ny, cell, -1.0)
    parks, water = park_water_polys(conf, aid, man)
    nonfabric = raster_of(parks + water, x0, y0, nx, ny, cell, 0.0)
    read_m2 = (2 * (hw + margin)) * (2 * (hh + margin))
    jx = np.clip(np.floor((e - x0) / cell).astype(np.int64), 0, nx - 1)
    jy = np.clip(np.floor((n - y0) / cell).astype(np.int64), 0, ny - 1)
    in_bld = fp_buf[jy, jx]
    table = {}
    for lo in (2.0, 3.0):
        sel = (hag >= lo) & (hag <= params["maxHeightAboveGround"]) & ~in_bld
        table[f"above{lo:g}m_outsideFootprints"] = {int(c): int((sel & (cls == c)).sum()) for c in np.unique(cls[sel])}
    info = {"readInBoxPlusMargin": int(len(z)), "groundPoints": int(g.sum()),
            "classTableAboveGround": table,
            "densityAllClassesPerM2": round(len(z) / read_m2, 2),
            "densityVegetationPerM2": round(float(veg_cls.sum()) / read_m2, 2),
            "densityGroundPerM2": round(float(g.sum()) / read_m2, 2),
            "footprints": len(polys), "parkPolygons": len(parks), "waterPolygons": len(water)}
    from scipy import ndimage
    near_b = ndimage.maximum_filter((chm_b >= params["roofClutter"]["minRoofHeight"]).astype(np.uint8),
                                    size=2 * int(params["clearCells"]) + 1) > 0
    return {"man": man, "w": w, "pts": pts, "hag": hag, "x0": x0, "y0": y0, "nx": nx, "ny": ny, "chm": chm, "chm_b": chm_b,
            "near_b": near_b,
            "in_box": in_box, "fp_core": fp_core, "fp_buf": fp_buf, "nonfabric": nonfabric, "info": info,
            "area_m2": man["widthMeters"] * man["heightMeters"]}


# ---------------------------------------------------------------- detection


def detect(chm, params, in_box, fp_core, on_roof=None, support=None):
    """Tree tops, heights and crowns on a (cleaned) CHM. Returns (per-tree arrays of the trees kept, counts, smoothed
    CHM, watershed labels, per-top arrays for every top found). Only tops inside `in_box` (the area itself, not
    the reading margin) are kept, only crowns of at least `minCrownCells` cells whose top layer is at least
    `minTopThicknessCells` thick (wires and poles are not), no top that `on_roof` (a function of iy, ix, h
    returning a boolean array) marks as rooftop clutter, and only tops with at least `minCrownPoints` vegetation
    points (counted by `support`) in their upper crown."""
    cell = params["chmCell"]
    sm = th.smooth_chm(chm, params["smoothSigma"] / cell)
    iy, ix, _ = th.local_maxima(sm, cell, params["window"], params["minTreeHeight"])
    # Height of a tree = highest raw cell within one cell of the smoothed top (smoothing flattens peaks).
    pad = np.pad(chm, 1, mode="constant")
    h = np.max([pad[iy + 1 + dy, ix + 1 + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)], axis=0)
    counts = {"topsFound": int(len(iy))}
    labels = th.watershed_labels(sm, iy, ix, params["crown"]["minAbsoluteHeight"])
    cm = th.crown_measures(sm, labels, iy, ix, h, cell, params["crown"])
    keep = in_box[iy, ix]
    counts["outsideAreaBox"] = int((~keep).sum())
    tiny = keep & (cm["cells"] < params["minCrownCells"])
    counts["crownUnderMinCells"] = int(tiny.sum())
    keep &= ~tiny
    thin = keep & (cm["thick"] < params["minTopThicknessCells"])
    counts["thinTopsWiresPoles"] = int(thin.sum())
    keep &= ~thin
    if on_roof is not None:
        roof_top = keep & on_roof(iy, ix, h)
        counts["topsOnRoofs"] = int(roof_top.sum())
        keep &= ~roof_top
    crown_pts = np.zeros(len(iy), dtype=np.int32)
    if support is not None and params.get("minCrownPoints"):
        idx = np.nonzero(keep)[0]
        crown_pts[idx] = support(iy[idx], ix[idx], h[idx])
        weak = keep & (crown_pts < params["minCrownPoints"])
        counts["fewPointsInCrownTop"] = int(weak.sum())
        keep &= ~weak
    counts["kept"] = int(keep.sum())
    counts["keptInsideBuildingFootprint"] = int((keep & fp_core[iy, ix]).sum())
    out = {k: v[keep] for k, v in cm.items()}
    out.update({"iy": iy[keep], "ix": ix[keep], "h": h[keep]})
    every = dict(cm, iy=iy, ix=ix, h=h, keep=keep, inBox=in_box[iy, ix], inBuilding=fp_core[iy, ix], crownPts=crown_pts)
    return out, counts, sm, labels, every


def crown_point_counter(ctx, params):
    """A function (iy, ix, h) -> number of vegetation points within `supportRadius` m (horizontal) of each top that
    lie in its upper `supportDepth` m. A crown top has dozens, even leaf-off (branches); a wire, a stray point or a
    roof-edge sliver has a handful. The k-d tree is built once per area."""
    from scipy.spatial import cKDTree
    if "veg_tree" not in ctx:
        pts, hag = ctx["pts"], ctx["hag"]
        veg = (np.isin(pts["cls"], params["vegetationClasses"]) & (hag >= params["minHeightAboveGround"])
               & (hag <= params["maxHeightAboveGround"]))
        ctx["veg_xyz"] = (pts["e"][veg], pts["n"][veg], hag[veg])
        ctx["veg_tree"] = cKDTree(np.stack([ctx["veg_xyz"][0], ctx["veg_xyz"][1]], axis=1))
    ve, vn, vh = ctx["veg_xyz"]
    radius, depth, cell = params["supportRadius"], params["supportDepth"], params["chmCell"]

    def count(iy, ix, h):
        te = (ix + 0.5) * cell + ctx["x0"]
        tn = (iy + 0.5) * cell + ctx["y0"]
        near = ctx["veg_tree"].query_ball_point(np.stack([te, tn], axis=1), r=radius)
        return np.array([int((vh[np.asarray(idx, dtype=np.int64)] >= h[k] - depth).sum()) if idx else 0
                         for k, idx in enumerate(near)], dtype=np.int32)
    return count


def run_detection(ctx, params):
    """Roof clutter removal, then detection."""
    rc = params.get("roofClutter")
    if rc:
        m = th.roof_clutter_masks(ctx["chm"], ctx["chm_b"], rc)
        chm, clutter = m["clean"], m["clutter"]

        def on_roof(iy, ix, h):
            return th.tops_on_roofs(iy, ix, h, m["roof"], m["roof_h"], rc["topOnRoofMinAboveMeters"])
    else:
        chm, clutter, on_roof = ctx["chm"], np.zeros(ctx["chm"].shape, dtype=bool), None
    support = crown_point_counter(ctx, params) if params.get("minCrownPoints") else None
    det, counts, sm, labels, every = detect(chm, params, ctx["in_box"], ctx["fp_core"], on_roof, support)
    counts["vegCellsRemovedAsRoofClutter"] = int((clutter & ctx["in_box"]).sum())
    return det, counts, sm, labels, every, chm


def summarise(h, r, free, params):
    """The per-area statistics block: heights, young share, mature heights, crown radii, ratio fits."""
    ps, mn = params["percentiles"], params["minGroupN"]
    young = params["youngBelowMeters"]
    mature = h >= young
    out = {
        "trees": int(len(h)),
        "height": th.percentile_summary(h, ps, mn),
        "shareBelowYoung": round(th.share_below(h, young), 4) if len(h) else None,
        "youngBelowMeters": young,
        "heightMature": th.percentile_summary(h[mature], ps, mn),
        "crownRadius": th.percentile_summary(r, ps, mn),
        "crownRadiusFreeStanding": th.percentile_summary(r[free], ps, mn),
        "crownRadiusMature": th.percentile_summary(r[mature], ps, mn),
        "freeStandingShare": round(float(free.mean()), 4) if len(h) else None,
        "radiusVsHeight": th.fit_ratio(h, r),
        "radiusVsHeightFreeStanding": th.fit_ratio(h[free], r[free]),
        "radiusVsHeightMature": th.fit_ratio(h[mature], r[mature]),
        "radiusVsHeightMatureFreeStanding": th.fit_ratio(h[mature & free], r[mature & free]),
    }
    bins = []
    for lo, hi in [(3, 7), (7, 12), (12, 17), (17, 22), (22, 99)]:
        m = (h >= lo) & (h < hi)
        row = {"heightRange": [lo, hi if hi < 99 else None], "n": int(m.sum())}
        if m.sum() >= mn:
            row["medianRadius"] = round(float(np.median(r[m])), 3)
            row["medianRadiusOverHeight"] = round(float(np.median(r[m] / h[m])), 4)
            row["freeStandingMedianRadiusOverHeight"] = round(float(np.median(r[m & free] / h[m & free])), 4) \
                if (m & free).sum() >= mn else None
        bins.append(row)
    out["byHeightClass"] = bins
    return out


def sensitivity(ctx, params):
    """How much the headline numbers move with the detection settings (one at a time)."""
    variants = {"base": {}}
    for v in (0.08, 0.18):
        variants[f"window.perMeter={v}"] = {"window": {"perMeter": v}}
    for v in (0.5, 1.5):
        variants[f"smoothSigma={v}"] = {"smoothSigma": v}
    for v in (0.2, 0.45):
        variants[f"crown.minRelativeHeight={v}"] = {"crown": {"minRelativeHeight": v}}
    variants["minTreeHeight=4"] = {"minTreeHeight": 4.0}
    variants["roofClutter=off"] = {"roofClutter": None}
    variants["allClutterRulesOff"] = {"roofClutter": None, "minTopThicknessCells": 0.0, "minCrownPoints": 0}
    variants["minTopThicknessCells=0"] = {"minTopThicknessCells": 0.0}
    variants["minCrownPoints=0"] = {"minCrownPoints": 0}
    variants["minCrownPoints=100"] = {"minCrownPoints": 100}
    out = {}
    for name, change in variants.items():
        p = copy.deepcopy(params)
        for k, v in change.items():
            if isinstance(v, dict):
                p[k].update(v)
            else:
                p[k] = v
        det, counts, *_ = run_detection(ctx, p)
        h, r, free = det["h"], det["radius"], det["free"]
        ps = np.percentile(h, [25, 50, 75]) if len(h) else [float("nan")] * 3
        fit = th.fit_ratio(h, r)
        cl = ~ctx["near_b"][det["iy"], det["ix"]]
        pc = np.percentile(h[cl], [25, 50, 75]) if cl.any() else [float("nan")] * 3
        out[name] = {"trees": int(len(h)), "p25": round(float(ps[0]), 2), "p50": round(float(ps[1]), 2), "p75": round(float(ps[2]), 2),
                     "shareBelow7": round(th.share_below(h, p["youngBelowMeters"]), 4),
                     "clearOfBuildings": {"trees": int(cl.sum()), "p25": round(float(pc[0]), 2), "p50": round(float(pc[1]), 2),
                                          "p75": round(float(pc[2]), 2), "shareBelow7": round(th.share_below(h[cl], p["youngBelowMeters"]), 4)},
                     "ratioThroughOrigin": fit.get("throughOrigin"),
                     "ratioFreeStanding": th.fit_ratio(h[free], r[free]).get("throughOrigin"),
                     "crownPlanAreaShare": round(float(det["cells"].sum() * p["chmCell"] ** 2) / ctx["area_m2"], 4)}
    return out


def cmd_measure(args, work, conf):
    from scipy import ndimage
    params = conf["params"]
    cell = params["chmCell"]
    validation = ld.load("trees_validation.json")
    results = {}
    if args.merge and os.path.exists(os.path.join(RESULTS, "trees.json")):
        results = json.load(open(os.path.join(RESULTS, "trees.json")))
    for aid in args.areas:
        t0 = time.time()
        ctx = prepare_area(work, conf, aid)
        pilot = area_pilot(conf, aid)
        ld.log(f"[{aid}] prepared in {time.time() - t0:.0f} s: {json.dumps(ctx['info'])}")
        det, counts, sm, labels, every, chm = run_detection(ctx, params)
        h, r, free = det["h"], det["radius"], det["free"]
        stats = summarise(h, r, free, params)
        area_m2 = ctx["area_m2"]
        in_box = ctx["in_box"]
        # The same statistics on the built fabric only (without parks of at least 1,000 m2 and water).
        fab = ~ctx["nonfabric"][det["iy"], det["ix"]]
        fabric_stats = summarise(h[fab], r[fab], free[fab], params)
        # Trees with no building-class cell within `clearCells` cells: where wires, porch posts and rooftop plant
        # cannot pass for trees (the validation crops show the remaining false tops stand next to buildings).
        clear = ~ctx["near_b"][det["iy"], det["ix"]]
        every["nearBuilding"] = ctx["near_b"][every["iy"], every["ix"]]
        clear_stats = summarise(h[clear], r[clear], free[clear], params)
        fabric_area = float((in_box & ~ctx["nonfabric"]).sum()) * cell * cell

        # Cover check: leaf-off lidar vegetation cover against the leaf-on NAIP canopy share of the same area.
        solid = chm >= params["crown"]["minAbsoluteHeight"]
        solid_raw = ctx["chm"] >= params["crown"]["minAbsoluteHeight"]
        fabric_cells = in_box & ~ctx["nonfabric"]
        cover = {
            "vegCellsAtLeast2_5m_wholeArea": round(float((solid_raw & in_box).sum()) / float(in_box.sum()), 4),
            "vegCellsAtLeast2_5m_afterRoofClutter_wholeArea": round(float((solid & in_box).sum()) / float(in_box.sum()), 4),
            "vegCellsClosedOnce_afterRoofClutter_wholeArea": round(float((ndimage.binary_closing(solid, iterations=1) & in_box).sum()) / float(in_box.sum()), 4),
            "vegCellsAtLeast2_5m_fabric": round(float((solid & fabric_cells).sum()) / float(fabric_cells.sum()), 4),
            "detectedCrownsPlanAreaShare_wholeArea": round(float(det["cells"].sum() * cell * cell) / area_m2, 4),
            "detectedCrownsPlanAreaShare_fabric": round(float(det["cells"][fab].sum() * cell * cell) / fabric_area, 4),
            "fabricShareOfArea": round(fabric_area / area_m2, 4),
        }

        with open(os.path.join(ld.REPO, pilot["area"], "osm.json")) as f:
            osm = json.load(f)
        mapped = [x for x in osm["elements"] if x["type"] == "node" and x.get("tags", {}).get("natural") == "tree"]
        osm_trees = {"naturalTreeNodes": len(mapped),
                     "withHeightTag": sum(1 for x in mapped if any(k in x["tags"] for k in ("height", "est_height")))}

        res = {
            "profile": conf["areas"][aid]["profile"], "area": pilot["area"],
            "points": ctx["info"],
            "detection": dict(counts, treesPerHa=round(counts["kept"] / (area_m2 / 1e4), 2),
                              treesPerHaFabric=round(int(fab.sum()) / (fabric_area / 1e4), 2)),
            "stats": stats,
            "statsFabric": fabric_stats,
            "statsClearOfBuildings": dict(clear_stats, shareOfTrees=round(float(clear.mean()), 4),
                                          clearCells=params["clearCells"]),
            "cover": cover,
            "osmTrees": osm_trees,
        }
        # Proposed profile values. The generator draws a tree young with probability youngShare (from
        # youngHeightMeters) and otherwise uniformly from heightMeters, so heightMeters describes the trees that are
        # not young: p25 and p75 of the trees at least `youngBelowMeters` high. The p25/p75 of all trees is kept
        # beside it. The subset (all detected trees, or those clear of buildings) is set per area in data/trees.json.
        sub = stats if conf["areas"][aid]["proposalSubset"] == "all" else clear_stats
        res["proposal"] = {
            "subset": conf["areas"][aid]["proposalSubset"],
            "heightMeters": [round(sub["heightMature"]["p25"] + 1e-9, 1), round(sub["heightMature"]["p75"] + 1e-9, 1)],
            "heightMetersFromAllTreesP25P75": [round(sub["height"]["p25"] + 1e-9, 1), round(sub["height"]["p75"] + 1e-9, 1)],
            "youngShare": round(sub["shareBelowYoung"] + 1e-9, 2),
            "youngShareUnrounded": sub["shareBelowYoung"],
            "youngMedianHeightMeters": None,
        }
        young = every["h"][every["keep"]]
        young = young[~ctx["near_b"][every["iy"][every["keep"]], every["ix"][every["keep"]]]] if sub is clear_stats else young
        young = young[young < params["youngBelowMeters"]]
        res["proposal"]["youngMedianHeightMeters"] = round(float(np.median(young)), 2) if len(young) >= params["minGroupN"] else None
        if args.sensitivity:
            res["sensitivity"] = sensitivity(ctx, params)
            sens = res["sensitivity"]
            key = "clearOfBuildings" if sub is clear_stats else None
            lows = [(v["clearOfBuildings"] if key else v) for name, v in sens.items() if name != "allClutterRulesOff"]
            res["proposal"]["sensitivityRange"] = {
                "p25": [min(v["p25"] for v in lows), max(v["p25"] for v in lows)],
                "p75": [min(v["p75"] for v in lows), max(v["p75"] for v in lows)],
                "shareBelow7": [min(v["shareBelow7"] for v in lows), max(v["shareBelow7"] for v in lows)],
                "note": "all trees (not only the trees at least 7 m high); over the base run and the 11 one-at-a-time settings in `sensitivity` (each clutter rule on its own switched off or tightened), without the run that switches all clutter rules off"}
        if aid in validation["areas"]:
            res["validation"] = validation["areas"][aid]
        results[aid] = res
        # Per-tree values stay in the work directory.
        np.savez(ctx["w"].p("trees.npz"), **every)
        np.savez(ctx["w"].p("chm.npz"), chm=ctx["chm"], clean=chm, sm=sm, labels=labels.astype(np.int32), fp=ctx["fp_buf"])
        ld.log(f"[{aid}] {counts} in {time.time() - t0:.0f} s")
        ld.log(json.dumps({k: stats[k] for k in ("trees", "height", "shareBelowYoung", "heightMature", "crownRadius", "radiusVsHeight",
                                                  "radiusVsHeightFreeStanding")}, indent=1))
        ld.log(json.dumps(cover))
        if args.sensitivity:
            ld.log(json.dumps(res["sensitivity"], indent=1))
    results["_meta"] = {"tool": "regionkit-lidar trees 0.1", "ept": {k: v for k, v in conf["ept"].items() if k != "maxBytesTotal"},
                        "marginMeters": conf["marginMeters"], "params": params,
                        "note": "Aggregates only. Leaf-off lidar (April-May 2017); see docs/research/lidar-roofs.md, Tree heights."}
    if args.write:
        os.makedirs(RESULTS, exist_ok=True)
        with open(os.path.join(RESULTS, "trees.json"), "w") as f:
            json.dump(results, f, indent=1, sort_keys=True)


# ---------------------------------------------------------------- validation crops (scratch only)

CLASS_RGB = {1: (240, 220, 40), 2: (150, 150, 150), 3: (140, 220, 140), 4: (60, 190, 80), 5: (20, 120, 50),
             6: (230, 60, 60), 7: (230, 60, 230)}


def height_rgb(v):
    """Colour ramp for heights above ground (m): grey ground, blue low, green mid, yellow, red tall."""
    stops = [(0, (40, 40, 40)), (2.5, (30, 50, 120)), (6, (40, 130, 160)), (10, (60, 170, 70)), (15, (200, 210, 60)),
             (20, (240, 150, 40)), (28, (230, 60, 50)), (40, (255, 255, 255))]
    v = float(v)
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        if v <= b:
            t = (v - a) / (b - a) if b > a else 0
            return tuple(int(ca[i] + t * (cb[i] - ca[i])) for i in range(3))
    return stops[-1][1]


def crop_panel(i, aid, k, T, C, ctx, params, half=22, px=8):
    """One validation tile: plan view of the raw vegetation CHM (tops, crown outline, footprints) and a side view of
    the lidar points in a 5 m strip through the top. Returns a PIL image."""
    from PIL import Image, ImageDraw, ImageFont
    from scipy import ndimage
    cell = params["chmCell"]
    chm, sm, lab, fp = C["chm"], C["sm"], C["labels"], C["fp"]
    pts, hag = ctx["pts"], ctx["hag"]
    iy, ix, h = int(T["iy"][k]), int(T["ix"][k]), float(T["h"][k])
    y0, y1, x0, x1 = iy - half, iy + half, ix - half, ix + half
    W = 2 * half
    img = Image.new("RGB", (W * px * 2 + 8, W * px), (20, 20, 20))
    plan = np.zeros((W, W, 3), dtype=np.uint8)
    for yy in range(W):
        for xx in range(W):
            gy, gx = y1 - 1 - yy, x0 + xx  # image row 0 = north
            if 0 <= gy < chm.shape[0] and 0 <= gx < chm.shape[1]:
                plan[yy, xx] = height_rgb(chm[gy, gx])
    im = Image.fromarray(np.kron(plan, np.ones((px, px, 1), dtype=np.uint8)))
    d = ImageDraw.Draw(im)
    sub_fp = np.zeros((W, W), dtype=bool)
    ys, ye = max(y0, 0), min(y1, chm.shape[0])
    xs, xe = max(x0, 0), min(x1, chm.shape[1])
    sub_fp[(y1 - ye):(y1 - ys), (xs - x0):(xe - x0)] = fp[ys:ye, xs:xe][::-1]
    edge = sub_fp & ~ndimage.binary_erosion(sub_fp)
    for yy, xx in zip(*np.nonzero(edge)):
        d.rectangle([xx * px, yy * px, xx * px + px - 1, yy * px + px - 1], outline=(255, 255, 255))
    # the focal crown (cyan outline) = connected part of the watershed basin above the crown threshold
    thr = max(params["crown"]["minAbsoluteHeight"], params["crown"]["minRelativeHeight"] * h)
    lbl = int(lab[iy, ix])
    sl = (slice(max(iy - 3 * half, 0), iy + 3 * half), slice(max(ix - 3 * half, 0), ix + 3 * half))
    mine = (lab[sl] == lbl) & (sm[sl] >= thr)
    comp, _ = ndimage.label(mine)
    own = comp == comp[iy - sl[0].start, ix - sl[1].start]
    cedge = own & ~ndimage.binary_erosion(own)
    for ey, ex in zip(*np.nonzero(cedge)):
        gy, gx = ey + sl[0].start, ex + sl[1].start
        yy, xx = y1 - 1 - gy, gx - x0
        if 0 <= yy < W and 0 <= xx < W:
            d.rectangle([xx * px, yy * px, xx * px + px - 1, yy * px + px - 1], outline=(0, 255, 255))
    for a in range(len(T["iy"])):  # all tops: kept = red ring, not kept = orange ring
        ty, tx = int(T["iy"][a]), int(T["ix"][a])
        if y0 <= ty < y1 and x0 <= tx < x1:
            cx, cy = (tx - x0) * px + px // 2, (y1 - 1 - ty) * px + px // 2
            col = (255, 40, 40) if T["keep"][a] else (255, 160, 0)
            r = 5 if a == k else 3
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=2)
    font = ImageFont.load_default(size=13)
    d.text((4, 3), f"#{i} {aid} h={h:.1f} m r={float(T['radius'][k]):.1f} m {'free' if T['free'][k] else 'touching'}"
           f"{' IN-FOOTPRINT' if T['inBuilding'][k] else ''}{'' if T['keep'][k] else ' NOT-KEPT'} "
           f"thick={float(T['thick'][k]):.1f} pts={int(T['crownPts'][k]) if 'crownPts' in T else -1}", fill=(255, 255, 255), font=font)
    img.paste(im, (0, 0))
    # side view: 5 m strip north-south through the top
    e0 = (ix + 0.5) * cell + ctx["x0"]
    n0 = (iy + 0.5) * cell + ctx["y0"]
    sel = (np.abs(pts["e"] - e0) <= half * cell) & (np.abs(pts["n"] - n0) <= 2.5)
    pe, ph, pc = pts["e"][sel], hag[sel], pts["cls"][sel]
    sd = ImageDraw.Draw(img)
    ox = W * px + 8
    sd.rectangle([ox, 0, ox + W * px - 1, W * px - 1], fill=(15, 15, 25))
    for m in range(0, 40, 5):
        yy = W * px - int(m * px)
        if 0 <= yy < W * px:
            sd.line([ox, yy, ox + W * px, yy], fill=(50, 50, 70))
            sd.text((ox + 2, yy - 12), f"{m}", fill=(120, 120, 140), font=font)
    for a in np.argsort(pc):  # ground first, then the rest on top
        xx = ox + int((pe[a] - (e0 - half * cell)) / (2 * half * cell) * W * px)
        yy = W * px - int(ph[a] * px)
        if 0 <= yy < W * px:
            sd.point([(xx, yy), (xx + 1, yy)], fill=CLASS_RGB.get(int(pc[a]), (200, 200, 200)))
    r = float(T["radius"][k])
    xa = ox + int((half * cell - r) / (2 * half * cell) * W * px)
    xb = ox + int((half * cell + r) / (2 * half * cell) * W * px)
    yy = W * px - int(h * px)
    sd.line([xa, yy, xb, yy], fill=(0, 255, 255), width=2)
    sd.line([xa, yy, xa, yy + 6], fill=(0, 255, 255), width=2)
    sd.line([xb, yy, xb, yy + 6], fill=(0, 255, 255), width=2)
    sd.text((ox + 4, 3), "side view (5 m strip): green veg, grey ground, red building, yellow unclassified",
            fill=(220, 220, 220), font=ImageFont.load_default(size=11))
    return img


def cmd_crops(args, work, conf):
    from PIL import Image
    params = conf["params"]
    out_dir = os.path.join(work.root, "crops")
    os.makedirs(out_dir, exist_ok=True)
    idx = 0
    manifest = []
    for aid in args.areas:
        ctx = prepare_area(work, conf, aid)
        w = ctx["w"]
        T = dict(np.load(w.p("trees.npz")))
        C = dict(np.load(w.p("chm.npz")))

        def order(ids):
            return sorted(ids, key=lambda a: hashlib.sha256(f"{args.seed}/{aid}/{T['iy'][a]}/{T['ix'][a]}".encode()).hexdigest())
        kept = np.nonzero(T["keep"])[0]
        pick = [(int(a), "kept") for a in order(kept)[:args.n]]
        if args.near_buildings:
            near = np.nonzero(T["keep"] & ctx["near_b"][T["iy"], T["ix"]])[0]  # a building-class cell within clearCells
            near = [a for a in near if a not in {p[0] for p in pick}]
            pick += [(int(a), "near-building") for a in order(near)[:args.near_buildings]]
        if args.in_footprint:
            inside = np.nonzero(T["keep"] & T["inBuilding"])[0]
            pick += [(int(a), "in-footprint") for a in order(inside)[:args.in_footprint]]
        sources = {"kept": (T, C), "near-building": (T, C), "in-footprint": (T, C), "thin": (T, C), "few-points": (T, C)}
        if args.thin:
            thin = np.nonzero(T["inBox"] & ~T["keep"] & (T["cells"] >= params["minCrownCells"])
                              & (T["thick"] < params["minTopThicknessCells"]))[0]
            pick += [(int(a), "thin") for a in order(thin)[:args.thin]]
        if args.few_points:
            few = np.nonzero(T["inBox"] & ~T["keep"] & (T["crownPts"] > 0) & (T["crownPts"] < params["minCrownPoints"]))[0]
            pick += [(int(a), "few-points") for a in order(few)[:args.few_points]]
        if args.removed:
            # Tops that exist without the roof-clutter rule but have no kept top within 2 cells with it.
            p_off = copy.deepcopy(params)
            p_off["roofClutter"] = None
            _, _, sm_off, lab_off, T_off, _ = run_detection(ctx, p_off)
            from scipy.spatial import cKDTree
            tree = cKDTree(np.stack([T["iy"][T["keep"]], T["ix"][T["keep"]]], axis=1))
            dist, _ = tree.query(np.stack([T_off["iy"], T_off["ix"]], axis=1))
            T_off = dict(T_off)
            gone = np.nonzero(T_off["keep"] & (dist > 2.0))[0]
            T_off["keep"] = T_off["keep"] & (dist <= 2.0)  # draw the vanished tops as not kept
            C_off = {"chm": C["chm"], "sm": sm_off, "labels": lab_off, "fp": C["fp"]}
            sources["removed"] = (T_off, C_off)
            T_rm = T_off

            def order_rm(ids):
                return sorted(ids, key=lambda a: hashlib.sha256(f"{args.seed}/{aid}/rm/{T_rm['iy'][a]}/{T_rm['ix'][a]}".encode()).hexdigest())
            pick += [(int(a), "removed") for a in order_rm(gone)[:args.removed]]
        tiles, first = [], idx + 1
        for a, kind in pick:
            idx += 1
            Ts, Cs = sources[kind]
            tiles.append(crop_panel(idx, aid, a, Ts, Cs, ctx, params))
            manifest.append({"i": idx, "area": aid, "kind": kind, "h": round(float(Ts["h"][a]), 2), "r": round(float(Ts["radius"][a]), 2)})
        for s in range(0, len(tiles), 3):
            grp = tiles[s:s + 3]
            sheet = Image.new("RGB", (grp[0].width, grp[0].height * len(grp) + 4 * (len(grp) - 1)), (0, 0, 0))
            for j, t in enumerate(grp):
                sheet.paste(t, (0, j * (t.height + 4)))
            sheet.save(os.path.join(out_dir, f"sheet_{aid}_{first + s:03d}.png"))
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    ld.log(f"[crops] {len(manifest)} tiles in {out_dir}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["plan", "fetch", "measure", "crops"])
    ap.add_argument("--work", required=True, help="work directory outside the repository")
    ap.add_argument("--areas", nargs="*", help="area keys from data/trees.json (default: all)")
    ap.add_argument("--max-depth", type=int, help="fetch: deepest EPT level to read (default data/trees.json)")
    ap.add_argument("--n", type=int, default=8, help="crops: kept trees sampled per area")
    ap.add_argument("--near-buildings", type=int, default=0, help="crops: extra kept trees within 3 cells of a building-class cell")
    ap.add_argument("--in-footprint", type=int, default=0, help="crops: extra kept trees whose top lies inside a footprint")
    ap.add_argument("--thin", type=int, default=0, help="crops: extra tops rejected as wires or poles (top layer too thin)")
    ap.add_argument("--few-points", type=int, default=0, help="crops: extra tops rejected for too few points in the crown top")
    ap.add_argument("--removed", type=int, default=0, help="crops: extra tops that only exist without the roof-clutter rule")
    ap.add_argument("--seed", default=None, help="crops: sample seed (default data/trees.json validationSeed)")
    ap.add_argument("--write", action="store_true", help="measure: write results/trees.json (aggregates)")
    ap.add_argument("--merge", action="store_true", help="measure: keep the areas already in results/trees.json")
    ap.add_argument("--sensitivity", action="store_true", help="measure: also sweep the detection settings")
    args = ap.parse_args()
    conf = cfg()
    args.areas = args.areas or list(conf["areas"])
    args.seed = args.seed or conf["params"]["validationSeed"]
    work = ld.Work(args.work)
    globals()["cmd_" + args.command](args, work, conf)


if __name__ == "__main__":
    main()
