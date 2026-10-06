#!/usr/bin/env python3
"""Lidar roof-form pilot: roof forms from USGS 3DEP lidar vs the generator's assigned roof forms.

Offline research tool for WorldEngine's region kit. Not part of the engine or any app. Results and method:
docs/research/lidar-roofs.md. Every per-building value stays in the work directory (outside the repository);
only aggregates go to results/.

Subcommands (all take --work DIR, never inside the repository):
  plan      EPT hierarchy for the area box: nodes, points and bytes per depth (no point data)
  fetch     read the EPT octree nodes that meet the area box (LAZ, HTTP), cached in the work directory
  classify  per OSM building footprint: lidar planes -> roof form (work directory only)
  p2        worldbake export of the area with P2's profile; per building: scene.json roofShape and the same
            plane classifier run on the generated roof triangles (work directory only)
  compare   agreement tables (aggregates) -> results/comparison.json
  handcheck render small point-cloud height images of a stable sample for hand labelling (work directory)
  score     hand labels (work/handcheck_labels.json) vs the lidar classifier -> results/handcheck.json
  vintage   lidar (2017) vs OSM (2026) mismatches, checked against a NAIP scene (--naip) -> results/vintage.json
  all       plan + fetch + classify + p2 + compare (+ score when labels exist, + vintage with --naip)
"""

import argparse
import json
import math
import os
import ssl
import subprocess
import sys
import time
import urllib.request
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.realpath(os.path.join(HERE, "..", "..", ".."))
RESULTS = os.path.join(HERE, "results")
sys.path.insert(0, HERE)
import roofplanes as rp  # noqa: E402

UA = "WorldEngine-regionkit/0.1 (offline research tool)"
TOOL_VERSION = "regionkit-lidar 0.1"


def load(name):
    with open(os.path.join(HERE, "data", name)) as f:
        return json.load(f)


def log(*a):
    print(*a, file=sys.stderr, flush=True)


class Work:
    def __init__(self, root):
        root = os.path.realpath(root)
        if root == REPO or root.startswith(REPO + os.sep):
            sys.exit("refusing a work directory inside the repository (per-building values must stay outside)")
        self.root = root
        os.makedirs(root, exist_ok=True)

    def p(self, *parts):
        path = os.path.join(self.root, *parts)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path

    def ledger_add(self, kind, what, nbytes):
        led = self.ledger()
        led.append({"kind": kind, "what": what, "bytes": nbytes, "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())})
        with open(self.p("ledger.json"), "w") as f:
            json.dump(led, f, indent=0)

    def ledger(self):
        try:
            with open(self.p("ledger.json")) as f:
                return json.load(f)
        except FileNotFoundError:
            return []


def _ssl():
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def http(url, work, kind):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=300, context=_ssl()) as r:
        body = r.read()
    work.ledger_add(kind, url[:200], len(body))
    return body


def cached_json(url, work, name, kind):
    path = work.p("ept", name)
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    body = http(url, work, kind)
    with open(path, "wb") as f:
        f.write(body)
    return json.loads(body)


# ---------------------------------------------------------------- area


def area_manifest(pilot):
    with open(os.path.join(REPO, pilot["area"], "manifest.json")) as f:
        return json.load(f)


def area_box_merc(man, margin):
    """EPSG:3857 rectangle around the area's lat/lon bounds plus `margin` ground metres."""
    b = man["sources"][0]["bounds"]
    lat0 = man["center"]["latitude"]
    k = 1 / math.cos(math.radians(lat0))  # Mercator scale: map metres per ground metre
    x0, y0 = rp.lonlat_to_merc(b["west"], b["south"])
    x1, y1 = rp.lonlat_to_merc(b["east"], b["north"])
    m = margin * k
    return (float(x0) - m, float(y0) - m, float(x1) + m, float(y1) + m)


# ---------------------------------------------------------------- EPT


def hierarchy(pilot, work, box):
    """All hierarchy entries (key -> point count) whose nodes meet the box, following sub-hierarchy files."""
    root_url = pilot["ept"]["root"]
    ept = cached_json(root_url + "ept.json", work, "ept.json", "ept-meta")
    cube = ept["bounds"]
    found = {}
    pending = ["0-0-0-0"]
    while pending:
        hk = pending.pop()
        h = cached_json(root_url + f"ept-hierarchy/{hk}.json", work, f"h-{hk}.json", "ept-hierarchy")
        for key, count in h.items():
            nb = rp.ept_node_bounds(cube, key)
            if rp.rect_overlap_share(nb, box) <= 0:
                continue
            if count == -1:
                pending.append(key)
            else:
                found[key] = count
    return ept, found


def cmd_plan(args, work):
    pilot = load("pilot.json")
    man = area_manifest(pilot)
    box = area_box_merc(man, pilot["marginMeters"])
    ept, nodes = hierarchy(pilot, work, box)
    by_depth = defaultdict(lambda: [0, 0, 0.0])
    for key, count in nodes.items():
        d = int(key.split("-")[0])
        share = rp.rect_overlap_share(rp.ept_node_bounds(ept["bounds"], key), box)
        by_depth[d][0] += 1
        by_depth[d][1] += count
        by_depth[d][2] += count * share
    k = 1 / math.cos(math.radians(man["center"]["latitude"]))
    ground_area = (box[2] - box[0]) * (box[3] - box[1]) / (k * k)
    plan = {"srs": ept["srs"].get("horizontal"), "points": ept["points"], "box3857": box,
            "boxGroundM2": round(ground_area), "depths": {}}
    cum = 0.0
    for d in sorted(by_depth):
        n, pts, inbox = by_depth[d]
        cum += inbox
        plan["depths"][d] = {"nodes": n, "pointsInNodes": pts, "pointsInBoxEstimate": round(inbox),
                             "cumulativeDensityPerM2": round(cum / ground_area, 2)}
    with open(work.p("plan.json"), "w") as f:
        json.dump(plan, f, indent=1)
    print(json.dumps(plan, indent=1))
    return plan


def cmd_fetch(args, work):
    pilot = load("pilot.json")
    man = area_manifest(pilot)
    box = area_box_merc(man, pilot["marginMeters"])
    ept, nodes = hierarchy(pilot, work, box)
    max_depth = args.max_depth if args.max_depth is not None else pilot["ept"]["maxDepth"]
    keys = sorted((k for k in nodes if max_depth is None or int(k.split("-")[0]) <= max_depth),
                  key=lambda k: [int(v) for v in k.split("-")])
    total = sum(e["bytes"] for e in work.ledger() if e["kind"] == "ept-data")
    for i, key in enumerate(keys):
        path = work.p("ept", "data", key + ".laz")
        if os.path.exists(path):
            continue
        if total > pilot["ept"]["maxBytes"]:
            sys.exit(f"byte cap reached ({total:,} bytes); stopping before {key}")
        body = http(pilot["ept"]["root"] + f"ept-data/{key}.laz", work, "ept-data")
        total += len(body)
        with open(path, "wb") as f:
            f.write(body)
        if i % 20 == 0:
            log(f"[fetch] {i + 1}/{len(keys)} nodes, {total / 1e6:.1f} MB")
    log(f"[fetch] {len(keys)} nodes, {total:,} bytes of LAZ")


# ---------------------------------------------------------------- footprints (committed area osm.json)


def footprints(pilot, man):
    """OSM building footprints of the area in local metres: id -> {poly, tags}. Closed building ways and the
    outer rings of building multipolygons (as the engine's MapFeatureBuilder; building:part skipped)."""
    from shapely.geometry import LineString, Polygon
    from shapely.ops import polygonize, unary_union
    with open(os.path.join(REPO, pilot["area"], "osm.json")) as f:
        osm = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in osm["elements"] if e["type"] == "node"}
    ways = {e["id"]: e for e in osm["elements"] if e["type"] == "way"}

    def ring(ids):
        pts = [nodes[i] for i in ids if i in nodes]
        if len(pts) < 3:
            return None
        e, n = rp.local_en(lat0, lon0, [p[0] for p in pts], [p[1] for p in pts])
        return list(zip(e.tolist(), n.tolist()))
    out = {}
    for w in ways.values():
        t = w.get("tags", {})
        if "building" not in t or "building:part" in t or len(w["nodes"]) < 4 or w["nodes"][0] != w["nodes"][-1]:
            continue
        r = ring(w["nodes"])
        if r:
            out[f"way/{w['id']}"] = {"poly": Polygon(r).buffer(0), "tags": t}
    for rel in (e for e in osm["elements"] if e["type"] == "relation"):
        t = rel.get("tags", {})
        if t.get("type") != "multipolygon" or "building" not in t:
            continue
        outer = [LineString(ring(ways[m["ref"]]["nodes"])) for m in rel["members"]
                 if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways and ring(ways[m["ref"]]["nodes"])]
        inner = [LineString(ring(ways[m["ref"]]["nodes"])) for m in rel["members"]
                 if m["type"] == "way" and m.get("role") == "inner" and m["ref"] in ways and ring(ways[m["ref"]]["nodes"])]
        polys = list(polygonize(unary_union(outer))) if outer else []
        if not polys:
            continue
        poly = unary_union(polys)
        if inner:
            poly = poly.difference(unary_union(list(polygonize(unary_union(inner)))))
        out[f"relation/{rel['id']}"] = {"poly": poly, "tags": t}
    return out, osm.get("osm3s", {}).get("timestamp_osm_base")


def roof_raster(poly, params):
    """Cell centres (0.5 m grid) inside the footprint eroded by `footprintErosion`: (eroded, xy0, gx, gy, inside)."""
    import shapely
    er = poly.buffer(-params["footprintErosion"])
    if er.is_empty:
        return None
    x0, y0, x1, y1 = er.bounds
    gx, gy = rp.raster_cells((x0, y0), (x1, y1), params["cell"])
    inside = shapely.contains_xy(er, gx, gy)
    if not inside.any():
        return None
    return er, (x0, y0), gx, gy, inside


def rect_of(geom):
    pts = np.array(geom.exterior.coords) if geom.geom_type == "Polygon" else \
        np.vstack([np.array(g.exterior.coords) for g in geom.geoms])
    return rp.min_area_rect(pts)


# ---------------------------------------------------------------- lidar points


def load_points(work, man, margin):
    """Lidar points in the area box, local metres (float32). Returns dict class -> (n, 3) and stats."""
    import glob
    import laspy
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    hw, hh = man["widthMeters"] / 2 + margin, man["heightMeters"] / 2 + margin
    keep = defaultdict(list)
    stats = Counter()
    for path in sorted(glob.glob(work.p("ept", "data", "*.laz"))):
        las = laspy.read(path)
        x, y, z = np.asarray(las.x), np.asarray(las.y), np.asarray(las.z)
        cls = np.asarray(las.classification)
        lon, lat = rp.merc_to_lonlat(x, y)
        e, n = rp.local_en(lat0, lon0, lat, lon)
        ok = (np.abs(e) <= hw) & (np.abs(n) <= hh)
        stats["pointsRead"] += len(x)
        stats["pointsInBox"] += int(ok.sum())
        for c in np.unique(cls[ok]):
            m = ok & (cls == c)
            stats[f"class{int(c)}"] += int(m.sum())
            if int(c) in (2, 3, 4, 5, 6):
                keep[int(c)].append(np.stack([e[m], n[m], z[m]], axis=1).astype(np.float32))
    pts = {c: np.concatenate(v) for c, v in keep.items()}
    return pts, dict(stats)


def ground_model(ground, cell):
    """Median ground height per `cell` m square (class 2); empty cells filled from the nearest filled cell."""
    from scipy import ndimage
    x0, y0 = float(ground[:, 0].min()), float(ground[:, 1].min())
    ix = ((ground[:, 0] - x0) // cell).astype(int)
    iy = ((ground[:, 1] - y0) // cell).astype(int)
    nx, ny = int(ix.max()) + 1, int(iy.max()) + 1
    key = iy * nx + ix
    order = np.lexsort((ground[:, 2], key))
    key, zs = key[order], ground[order, 2]
    grid = np.full(nx * ny, np.nan)
    starts = np.flatnonzero(np.r_[True, key[1:] != key[:-1]])
    ends = np.r_[starts[1:], len(key)]
    grid[key[starts]] = zs[(starts + ends) // 2]
    grid = grid.reshape(ny, nx)
    miss = np.isnan(grid)
    if miss.any():
        idx = ndimage.distance_transform_edt(miss, return_distances=False, return_indices=True)
        grid = grid[tuple(idx)]

    def height(x, y):
        jx = np.clip(((np.asarray(x) - x0) // cell).astype(int), 0, nx - 1)
        jy = np.clip(((np.asarray(y) - y0) // cell).astype(int), 0, ny - 1)
        return grid[jy, jx]
    return height


class PointIndex:
    """Points bucketed on a square grid for fast footprint queries."""

    def __init__(self, P, cell=10.0):
        self.P, self.cell = P, cell
        self.x0, self.y0 = float(P[:, 0].min()), float(P[:, 1].min())
        ix = ((P[:, 0] - self.x0) // cell).astype(np.int64)
        iy = ((P[:, 1] - self.y0) // cell).astype(np.int64)
        self.nx = int(ix.max()) + 1
        key = iy * self.nx + ix
        self.order = np.argsort(key, kind="stable")
        self.keys = key[self.order]

    def query(self, bounds):
        x0, y0, x1, y1 = bounds
        jx0, jx1 = int((x0 - self.x0) // self.cell), int((x1 - self.x0) // self.cell)
        jy0, jy1 = int((y0 - self.y0) // self.cell), int((y1 - self.y0) // self.cell)
        out = []
        for jy in range(max(jy0, 0), jy1 + 1):
            a = np.searchsorted(self.keys, jy * self.nx + max(jx0, 0), "left")
            b = np.searchsorted(self.keys, jy * self.nx + min(jx1, self.nx - 1), "right")
            out.append(self.order[a:b])
        return np.concatenate(out) if out else np.zeros(0, dtype=np.int64)


def classify_raster(planes, comp, ras, params):
    er, _, gx, gy, inside = ras
    cell = params["cell"]
    return rp.classify_roof(planes, np.stack([gx[inside], gy[inside]], axis=1), comp[inside], rect_of(er),
                            float(inside.sum()) * cell * cell, params["classify"])


def lidar_roof(P, ras, params):
    """Planes from the building points of one footprint (region growing), rastered, then classified."""
    er, xy0, gx, gy, inside = ras
    return rp.roof_from_points(P, gx, gy, inside, rect_of(er), params)


def global_shift(bld, fps, hw, hh, params):
    """One east/north shift for all lidar points that maximises the overlap of building-class cells with the
    OSM footprints (footprints and lidar disagree by a metre or so; one shift for the area, not per building)."""
    from affine import Affine
    from rasterio import features as rfeat
    from scipy import ndimage
    from shapely.ops import unary_union
    px = params["align"]["cell"]
    nx, ny = int(math.ceil(2 * hw / px)), int(math.ceil(2 * hh / px))
    occ = np.zeros((ny, nx), dtype=bool)
    cx, cy = np.floor((bld[:, 0] + hw) / px).astype(int), np.floor((hh - bld[:, 1]) / px).astype(int)
    ok = (cx >= 0) & (cx < nx) & (cy >= 0) & (cy < ny)
    occ[cy[ok], cx[ok]] = True
    occ = ndimage.binary_closing(occ, iterations=2)
    fpm = rfeat.rasterize([(unary_union([f["poly"] for f in fps.values()]), 1)], out_shape=(ny, nx),
                          transform=Affine(px, 0, -hw, 0, -px, hh), fill=0, dtype="uint8").astype(bool)
    dx, dy, iou0, iou = rp.best_shift(occ, fpm, int(round(params["align"]["searchMeters"] / px)))
    return {"eastMeters": dx * px, "northMeters": -dy * px, "iouAtZero": round(iou0, 4), "iouAtBest": round(iou, 4)}


def cmd_classify(args, work):
    import shapely
    pilot, params = load("pilot.json"), load("params.json")
    man = area_manifest(pilot)
    fps, osm_ts = footprints(pilot, man)
    pts, stats = load_points(work, man, pilot["marginMeters"])
    log(f"[classify] points {stats}")
    ground_h = ground_model(pts[2], params["groundCell"])
    bld = pts[6]
    bld = bld[(bld[:, 2] - ground_h(bld[:, 0], bld[:, 1])) >= params["minHeightAboveGround"]]
    veg = np.concatenate([pts[c] for c in (3, 4, 5) if c in pts])
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    shift = global_shift(bld, fps, hw, hh, params)
    log(f"[classify] global lidar shift {shift}")
    for arr in (bld, veg):
        arr[:, 0] += shift["eastMeters"]
        arr[:, 1] += shift["northMeters"]
    bidx, vidx = PointIndex(bld), PointIndex(veg)
    out = {}
    t0 = time.time()
    for i, (fid, fp) in enumerate(sorted(fps.items())):
        poly = fp["poly"]
        c = poly.centroid
        if not (abs(c.x) <= hw and abs(c.y) <= hh):
            continue
        rec = {"area": round(poly.area, 1), "building": fp["tags"].get("building")}
        ras = roof_raster(poly, params) if poly.area >= params["minFootprintM2"] else None
        if ras is None:
            rec.update({"form": "unknown", "simple": "unknown", "complex": False, "reasons": ["small footprint"]})
            out[fid] = rec
            continue
        er = ras[0]
        cand = bidx.query(er.bounds)
        P = bld[cand][shapely.contains_xy(er, bld[cand, 0], bld[cand, 1])] if len(cand) else np.zeros((0, 3), np.float32)
        vc = vidx.query(er.bounds)
        nveg = int(shapely.contains_xy(er, veg[vc, 0], veg[vc, 1]).sum()) if len(vc) else 0
        n_cells = int(ras[4].sum())
        cover = 0.0
        if len(P):
            # Roof cover: share of eroded cells with a building point within fillDist (vintage / occlusion check).
            from scipy.spatial import cKDTree
            d, _ = cKDTree(P[:, :2]).query(np.stack([ras[2][ras[4]], ras[3][ras[4]]], axis=1),
                                            distance_upper_bound=params["fillDist"])
            cover = float(np.isfinite(d).mean())
        res, planes = lidar_roof(P, ras, params)
        rec.update(res)
        rec.update({"points": int(len(P)), "vegPoints": nveg, "roofCover": round(cover, 3),
                    "density": round(len(P) / (n_cells * params["cell"] ** 2), 2),
                    "roofHeight": round(float(np.percentile(P[:, 2] - ground_h(P[:, 0], P[:, 1]), 95)), 2) if len(P) else None,
                    "planes": [{k: round(v, 2) for k, v in pl.items()} for pl in planes]})
        out[fid] = rec
        if i % 100 == 0:
            log(f"[classify] {i}/{len(fps)} ({time.time() - t0:.0f} s)")
    # Lidar buildings with no OSM footprint (demolished since the flight, or never mapped): building-class
    # clusters of at least 30 m^2 on a 1 m grid, outside every footprint grown by 1.5 m.
    from affine import Affine
    from rasterio import features as rfeat
    from scipy import ndimage
    from shapely.ops import unary_union
    n = int(math.ceil(2 * hw))
    occ = np.zeros((n, n), dtype=bool)
    cx, cy = np.floor(bld[:, 0] + hw).astype(int), np.floor(hh - bld[:, 1]).astype(int)
    ok = (cx >= 0) & (cx < n) & (cy >= 0) & (cy < n)
    occ[cy[ok], cx[ok]] = True
    occ = ndimage.binary_closing(occ, iterations=1)
    fp_mask = rfeat.rasterize([(unary_union([f["poly"].buffer(1.5) for f in fps.values()]), 1)], out_shape=(n, n),
                              transform=Affine(1.0, 0, -hw, 0, -1.0, hh), fill=0, dtype="uint8").astype(bool)
    lab, k = ndimage.label(occ & ~fp_mask)
    sizes = ndimage.sum(np.ones(lab.shape), lab, index=np.arange(1, k + 1)) if k else []
    unmatched = sorted(int(s) for s in sizes if s >= 30)
    meta = {"pointStats": stats, "osmTimestamp": osm_ts, "buildingPointsAboveGround": int(len(bld)), "globalShift": shift,
            "lidarBuildingClustersOutsideOSM": {"count": len(unmatched), "areasM2": unmatched}}
    with open(work.p("lidar_buildings.json"), "w") as f:
        json.dump({"meta": meta, "buildings": out}, f)
    log(f"[classify] {len(out)} footprints; {Counter(r['form'] for r in out.values())}; "
        f"{len(unmatched)} lidar building clusters outside OSM footprints")


# ---------------------------------------------------------------- generator side (P2)


def glb_triangles(path):
    """(triangles (n, 3, 3) in scene coordinates relative to the node, feature id per triangle) of a chunk GLB."""
    import struct
    with open(path, "rb") as f:
        data = f.read()
    off, gltf, binary = 12, None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        gltf = json.loads(chunk) if ctype == 0x4E4F534A else gltf
        binary = chunk if ctype == 0x004E4942 else binary
        off += 8 + clen
    dt = {5123: np.uint16, 5125: np.uint32, 5126: np.float32}
    ncomp = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}

    def acc(i):
        a = gltf["accessors"][i]
        v = gltf["bufferViews"][a["bufferView"]]
        arr = np.frombuffer(binary, dtype=dt[a["componentType"]], count=a["count"] * ncomp[a["type"]],
                            offset=v.get("byteOffset", 0) + a.get("byteOffset", 0))
        return arr.reshape(a["count"], -1) if ncomp[a["type"]] > 1 else arr
    tris, feats = [], []
    for mesh in gltf["meshes"]:
        for p in mesh["primitives"]:
            if gltf["materials"][p["material"]]["name"] != "worldStatic":
                continue
            idx = acc(p["indices"]).astype(np.int64).reshape(-1, 3)
            pos = acc(p["attributes"]["POSITION"]).astype(np.float64)
            tris.append(pos[idx])
            feats.append(acc(p["attributes"]["_FEATURE"])[idx[:, 0]].astype(np.int64))
    return (np.concatenate(tris), np.concatenate(feats)) if tris else (np.zeros((0, 3, 3)), np.zeros(0, np.int64))


def mesh_roof(T, ras, params):
    """The generator's roof triangles of one building through the same raster and classifier as the lidar."""
    er, xy0, gx, gy, inside = ras
    T = T[T[:, :, 2].max(axis=1) >= params["minHeightAboveGround"]]
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    ln = np.linalg.norm(n, axis=1)
    ok = ln > 1e-9
    T, n = T[ok], n[ok] / ln[ok, None]
    n[n[:, 2] < 0] *= -1
    up = n[:, 2] >= params["mesh"]["minUp"]
    T, n = T[up], n[up]
    best = rp.triangles_top_grid(T, gx, gy, params["mesh"]["minUp"])
    best[~inside] = -1
    used = np.unique(best[best >= 0])
    if len(used) == 0:
        return {"form": "unknown", "simple": "unknown", "complex": False, "reasons": ["no roof triangles"]}, []
    offs = np.einsum("ij,ij->i", n[used], T[used, 0])
    pid = rp.cluster_planes(n[used], offs, params["mesh"]["planeAngleDeg"], params["mesh"]["planeOffset"])
    plane_of_tri = dict(zip(used.tolist(), pid.tolist()))
    grid = np.full(best.shape, -1, dtype=int)
    m = best >= 0
    grid[m] = [plane_of_tri[t] for t in best[m]]
    comp = rp.components(grid)
    rep = {}
    for t, p in plane_of_tri.items():
        rep.setdefault(p, n[t])
    comp_plane = {int(c): int(np.bincount(grid[comp == c]).argmax()) for c in np.unique(comp[comp >= 0])}
    planes = rp.planes_from_grid(comp, gx, gy, lambda c: rep[comp_plane[c]], params["cell"])
    return classify_raster(planes, comp, ras, params), planes


def worldbake_cmd():
    built = os.path.join(REPO, ".build", "release", "worldbake")
    return [built] if os.path.exists(built) else ["swift", "run", "-c", "release", "worldbake"]


def cmd_p2(args, work):
    pilot, params = load("pilot.json"), load("params.json")
    man = area_manifest(pilot)
    fps, _ = footprints(pilot, man)
    pkg = work.p("package")
    if not os.path.exists(os.path.join(pkg, "world.json")):
        area_copy = work.p("area")
        if not os.path.exists(os.path.join(area_copy, "osm.json")):
            import shutil
            shutil.copytree(os.path.join(REPO, pilot["area"]), area_copy, dirs_exist_ok=True)
        head = subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
        subprocess.run(worldbake_cmd() + ["export", area_copy, pkg, "--date", pilot["exportDate"], "--profile", pilot["profile"],
                                          "--version", args.commit or head or "unknown"], check=True)
    with open(os.path.join(pkg, "world.json")) as f:
        world = json.load(f)
    decisions, tris = {}, defaultdict(list)
    for ch in world["chunks"]:
        with open(os.path.join(pkg, ch["scene"])) as f:
            scene = json.load(f)
        ids = {ft["index"]: ft["id"] for ft in scene["features"]}
        for ft in scene["features"]:
            if ft["kind"] == "building" and "generated" in ft:
                decisions[ft["id"]] = {k: ft["generated"].get(k) for k in
                                       ("role", "roofShape", "roofShapeFrom", "houseType", "footprintClass", "floors", "eaveHeight", "topHeight")}
        T, fid = glb_triangles(os.path.join(pkg, ch["lods"][0]))
        ox, oz = ch["origin"][0], ch["origin"][2]
        L = np.stack([T[:, :, 0] + ox, -(T[:, :, 2] + oz), T[:, :, 1]], axis=2)  # local east, north, up
        for f in np.unique(fid):
            key = ids.get(int(f))
            if key in decisions or (key and key.startswith(("way/", "relation/"))):
                tris[key].append(L[fid == f])
    out = {}
    for bid, d in decisions.items():
        rec = dict(d, simpleFromShape=rp.p2_simple(d["roofShape"]))
        fp = fps.get(bid)
        ras = roof_raster(fp["poly"], params) if fp and fp["poly"].area >= params["minFootprintM2"] else None
        if ras is None or bid not in tris:
            rec["mesh"] = {"form": "unknown", "simple": "unknown", "complex": False, "reasons": ["no footprint or mesh"]}
        else:
            res, planes = mesh_roof(np.concatenate(tris[bid]), ras, params)
            rec["mesh"] = res
            rec["meshPlanes"] = len(planes)
        out[bid] = rec
    with open(work.p("p2_buildings.json"), "w") as f:
        json.dump({"package": {"profile": world["recipe"]["profile"], "profileVersion": world["recipe"]["profileVersion"],
                               "generator": world["generator"]}, "buildings": out}, f)
    log(f"[p2] {len(out)} buildings; roofShape {Counter(r['roofShape'] for r in out.values())}; "
        f"mesh {Counter(r['mesh']['form'] for r in out.values())}")


# ---------------------------------------------------------------- comparison (aggregates only)


def table(pairs, labels, min_n):
    m = rp.confusion(pairs, labels)
    n = sum(m[a][b] for a in labels for b in labels)
    k = sum(m[a][a] for a in labels)
    per = {}
    for a in labels:
        row = sum(m[a].values())
        col = sum(m[b][a] for b in labels)
        per[a] = {"n": row, "recall": round(m[a][a] / row, 3) if row >= min_n else None,
                  "recall95ci": rp.wilson(m[a][a], row) if row >= min_n else None,
                  "precision": round(m[a][a] / col, 3) if col >= min_n else None}
    return {"n": n, "agree": k, "agreement": round(k / n, 4) if n else None, "agreement95ci": rp.wilson(k, n),
            "kappa": rp.kappa(m, labels), "matrix": m, "perClass": per}


def pct_stats(vals, min_n):
    if len(vals) < min_n:
        return {"n": len(vals), "suppressed": True}
    return {"n": len(vals), **{f"p{q}": round(float(np.percentile(vals, q)), 1) for q in (10, 25, 50, 75, 90)}}


def cmd_compare(args, work):
    params = load("params.json")
    pilot = load("pilot.json")
    min_n = params["minGroupN"]
    with open(work.p("lidar_buildings.json")) as f:
        L = json.load(f)
    with open(work.p("p2_buildings.json")) as f:
        G = json.load(f)
    lb, gb = L["buildings"], G["buildings"]
    vin = params["vintage"]
    ids = sorted(set(lb) & set(gb))
    status = Counter()
    rows = []
    for i in ids:
        l, g = lb[i], gb[i]
        if "small footprint" in l.get("reasons", []):
            status["footprint too small or eroded away"] += 1
            continue
        if l.get("roofCover", 0) < vin["newBuildingMaxShare"]:
            status["no lidar roof (built after the flight, footprint off, or not classed building)"] += 1
            continue
        if l["form"] == "unknown":
            status["lidar roof partly seen (coverage below threshold)"] += 1
            continue
        status["classified"] += 1
        rows.append((i, l, g))
    by_role = defaultdict(list)
    for r in rows:
        by_role[r[2]["role"]].append(r)
    out = {"tool": TOOL_VERSION, "generated": time.strftime("%Y-%m-%d"),
           "privacy": "Aggregates only; per-building values stay in the work directory. Groups under %d buildings report counts only." % min_n,
           "area": pilot["area"], "profile": pilot["profile"], "generator": G["package"],
           "lidar": {"dataset": pilot["ept"]["dataset"], "maxDepth": pilot["ept"]["maxDepth"], "pointStats": L["meta"]["pointStats"],
                     "lidarBuildingClustersOutsideOSM": {"count": L["meta"]["lidarBuildingClustersOutsideOSM"]["count"]}},
           "osmTimestamp": L["meta"]["osmTimestamp"],
           "buildings": {"inBoth": len(ids), "onlyLidarSide": len(set(lb) - set(gb)), "onlyGeneratorSide": len(set(gb) - set(lb)),
                         "status": dict(status), "classifiedByRole": {k: len(v) for k, v in by_role.items()}},
           "params": params["classify"]}

    def views(rs):
        if not rs:
            return None
        simple = table([(r[1]["simple"], r[2]["simpleFromShape"]) for r in rs if r[1]["simple"] in rp.SIMPLE], list(rp.SIMPLE), min_n)
        four = table([(r[1]["form"], r[2]["mesh"]["form"]) for r in rs if r[2]["mesh"]["form"] in rp.FORMS], list(rp.FORMS), min_n)
        cx = Counter((r[1]["complex"], r[2]["mesh"]["complex"]) for r in rs if r[2]["mesh"]["form"] != "unknown")
        lid_c = sum(v for (a, b), v in cx.items() if a)
        gen_s = sum(v for (a, b), v in cx.items() if not b)
        both_n = sum(cx.values())
        return {
            "n": len(rs),
            "simpleForm_lidarVsP2roofShape": simple,
            "fourClass_lidarVsP2mesh": four,
            "complexFlag": {"n": both_n, "lidarComplex": lid_c, "p2MeshComplex": sum(v for (a, b), v in cx.items() if b),
                            "lidarComplex_p2Simple": cx[(True, False)], "lidarSimple_p2Complex": cx[(False, True)],
                            "bothComplex": cx[(True, True)], "bothSimple": cx[(False, False)],
                            "shareLidarComplexWhereP2Simple": round(cx[(True, False)] / gen_s, 3) if gen_s else None,
                            "shareLidarComplexWhereP2Simple95ci": rp.wilson(cx[(True, False)], gen_s)},
            "lidarMix": {"form": dict(Counter(r[1]["form"] for r in rs)), "simple": dict(Counter(r[1]["simple"] for r in rs))},
            "p2Mix": {"roofShape": dict(Counter(r[2]["roofShape"] for r in rs)), "meshForm": dict(Counter(r[2]["mesh"]["form"] for r in rs))},
            "lidarPitchBySimple": {s: pct_stats([r[1]["pitch"] for r in rs if r[1]["simple"] == s and r[1].get("pitch") is not None], min_n)
                                   for s in ("gable", "hip")},
            "p2MeshPitchBySimple": {s: pct_stats([r[2]["mesh"]["pitch"] for r in rs if r[2]["mesh"]["simple"] == s and r[2]["mesh"].get("pitch") is not None], min_n)
                                    for s in ("gable", "hip")},
            "lidarComplexReasons": dict(Counter(x.split(" ")[-1] if x[0].isdigit() else x for r in rs for x in r[1].get("reasons", []))),
        }
    out["all"] = views(rows)
    out["byRole"] = {k: (views(v) if len(v) >= min_n else {"n": len(v), "suppressed": True}) for k, v in sorted(by_role.items())}
    # Generator self-check: the classifier on P2's own meshes vs the roofShape P2 assigned (known geometry).
    self_pairs = [(r[2]["simpleFromShape"], r[2]["mesh"]["simple"]) for r in rows if r[2]["mesh"]["simple"] in rp.SIMPLE]
    out["classifierCheckOnP2Meshes"] = table(self_pairs, list(rp.SIMPLE), min_n)
    out["classifierCheckOnP2Meshes"]["note"] = "rows: P2 roofShape (truth for the generated geometry); columns: classifier on the generated roof triangles"
    # Ridge orientation where lidar and the P2 mesh both see a gable.
    diffs = []
    for _, l, g in rows:
        if l["simple"] == "gable" and g["mesh"]["simple"] == "gable" and l.get("ridge") is not None and g["mesh"].get("ridge") is not None:
            d = abs(l["ridge"] - g["mesh"]["ridge"]) % 180
            diffs.append(min(d, 180 - d))
    out["ridgeOrientationBothGable"] = {"n": len(diffs), "within20deg": sum(1 for d in diffs if d <= 20),
                                       "share": round(sum(1 for d in diffs if d <= 20) / len(diffs), 3) if diffs else None,
                                       "share95ci": rp.wilson(sum(1 for d in diffs if d <= 20), len(diffs))}
    # Lidar roof mix by P2 house family (profile-level statistic; families under min_n suppressed).
    fam = defaultdict(list)
    for _, l, g in rows:
        if g["role"] == "house":
            fam[g.get("houseType") or "none"].append(l)
    out["lidarFormByP2HouseFamily"] = {k: ({"n": len(v), "form": dict(Counter(x["form"] for x in v)),
                                            "simple": dict(Counter(x["simple"] for x in v))} if len(v) >= min_n else {"n": len(v), "suppressed": True})
                                       for k, v in sorted(fam.items())}
    led = work.ledger()
    out["bytesDownloaded"] = {"total": sum(e["bytes"] for e in led),
                              "byKind": {k: sum(e["bytes"] for e in led if e["kind"] == k) for k in sorted({e["kind"] for e in led})}}
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, "comparison.json"), "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    a = out["all"]
    log(f"[compare] classified {len(rows)}; simple agreement {a['simpleForm_lidarVsP2roofShape']['agreement']} "
        f"4-class {a['fourClass_lidarVsP2mesh']['agreement']}; self-check {out['classifierCheckOnP2Meshes']['agreement']}")


# ---------------------------------------------------------------- hand check (work directory only)


def cmd_handcheck(args, work):
    """Point-cloud images of a stable sample for blind hand labelling. Shows no classifier output."""
    from PIL import Image, ImageDraw
    pilot, params = load("pilot.json"), load("params.json")
    man = area_manifest(pilot)
    fps, _ = footprints(pilot, man)
    with open(work.p("lidar_buildings.json")) as f:
        lb = json.load(f)["buildings"]
    elig = [i for i, r in lb.items() if r["form"] != "unknown" and r.get("roofCover", 0) >= params["vintage"]["newBuildingMaxShare"]]
    sample = rp.stable_sample(elig, params["handCheck"]["n"], params["handCheck"]["seed"])
    with open(work.p("lidar_buildings.json")) as f:
        shift = json.load(f)["meta"]["globalShift"]
    pts, _ = load_points(work, man, pilot["marginMeters"])
    ground_h = ground_model(pts[2], params["groundCell"])
    for c in pts:
        pts[c][:, 0] += shift["eastMeters"]
        pts[c][:, 1] += shift["northMeters"]
    from scipy import ndimage
    from scipy.spatial import cKDTree
    bidx = PointIndex(pts[6])
    veg = np.concatenate([pts[c] for c in (3, 4, 5) if c in pts])
    vidx = PointIndex(veg)
    key = []
    px, up = 0.5, 12  # 0.5 m cells drawn 12 px wide (24 px per metre)
    for k, bid in enumerate(sample):
        poly = fps[bid]["poly"]
        x0, y0, x1, y1 = poly.buffer(4).bounds
        P = pts[6][bidx.query((x0, y0, x1, y1))]
        P = P[(P[:, 0] >= x0) & (P[:, 0] <= x1) & (P[:, 1] >= y0) & (P[:, 1] <= y1)]
        h = P[:, 2] - ground_h(P[:, 0], P[:, 1])
        P, h = P[h >= 1.0], h[h >= 1.0]
        V = veg[vidx.query((x0, y0, x1, y1))]
        V = V[(V[:, 0] >= x0) & (V[:, 0] <= x1) & (V[:, 1] >= y0) & (V[:, 1] <= y1)]
        W, H = int((x1 - x0) / px) + 1, int((y1 - y0) / px) + 1
        gx, gy = np.meshgrid(x0 + (np.arange(W) + 0.5) * px, y1 - (np.arange(H) + 0.5) * px)
        dsm = np.full((H, W), np.nan)
        if len(P):
            # Height surface: inverse-distance mean of the building points within 0.9 m of each cell centre.
            tree = cKDTree(P[:, :2])
            q = np.stack([gx.ravel(), gy.ravel()], axis=1)
            nb = tree.query_ball_point(q, r=0.9)
            vals = [float(np.mean(h[j])) if len(j) else np.nan for j in nb]
            dsm = np.array(vals).reshape(H, W)
        # Facet colours from the surface gradient: hue = downhill direction, saturation = slope, grey = flat.
        filled = np.where(np.isnan(dsm), np.nanmin(dsm) if np.isfinite(dsm).any() else 0, dsm)
        sm = ndimage.uniform_filter(filled, 3)
        gyy, gxx = np.gradient(sm, px)  # gyy: change per row (southwards), gxx: per column (eastwards)
        slope = np.degrees(np.arctan(np.hypot(gxx, gyy)))
        aspect = (np.degrees(np.arctan2(-gxx, gyy)) % 360.0)  # downhill azimuth, clockwise from north
        hsv = np.zeros((H, W, 3))
        hsv[..., 0] = aspect / 360.0
        hsv[..., 1] = np.clip((slope - 8) / 25, 0, 1)
        hsv[..., 2] = 0.55 + 0.45 * np.clip(sm / max(np.nanmax(dsm) if np.isfinite(dsm).any() else 1, 1), 0, 1)
        from PIL import Image as _I
        rgb = np.asarray(_I.fromarray((hsv * 255).astype(np.uint8), "HSV").convert("RGB")).copy()
        rgb[np.isnan(dsm)] = (0, 0, 0)
        img = Image.fromarray(rgb).resize((W * up, H * up), Image.NEAREST)
        d = ImageDraw.Draw(img)
        for vx, vy in V[:, :2]:
            X, Y = (vx - x0) / px * up, (y1 - vy) / px * up
            d.point((X, Y), fill=(0, 140, 0))
        rings = [poly] if poly.geom_type == "Polygon" else list(poly.geoms)
        for g in rings:
            d.line([((x - x0) / px * up, (y1 - y) / px * up) for x, y in g.exterior.coords], fill=(255, 255, 255), width=2)
        # Compass: hue legend for downhill directions.
        for name, az in (("N", 0), ("E", 90), ("S", 180), ("W", 270)):
            col = _I.fromarray(np.array([[[int(az / 360 * 255), 255, 255]]], np.uint8), "HSV").convert("RGB").getpixel((0, 0))
            d.text((5 + 22 * (az // 90), 5), name, fill=col)
        # Side views along the footprint rectangle's axes (building points only), 24 px per metre.
        cx, cy, ux, uy, hl, hs = rect_of(poly)
        hmax = max(float(np.percentile(h, 99)) if len(h) else 8, 8) + 1
        panels = []
        for ax, name in (((ux, uy), "along long axis"), ((-uy, ux), "along short axis")):
            s = (P[:, 0] - cx) * ax[0] + (P[:, 1] - cy) * ax[1]
            span = max(hl, hs) + 3
            pw, ph = int(2 * span * 24), int(hmax * 24)
            pan = Image.new("RGB", (pw, ph), (25, 25, 25))
            dd = ImageDraw.Draw(pan)
            for sv, hv in zip(s, h):
                X, Y = (sv + span) * 24, (hmax - hv) * 24
                dd.ellipse((X - 1, Y - 1, X + 1, Y + 1), fill=(240, 210, 130))
            dd.text((4, 4), name, fill=(200, 200, 200))
            panels.append(pan)
        sw = max(img.width, panels[0].width, panels[1].width)
        sheet = Image.new("RGB", (sw, 24 + img.height + panels[0].height + panels[1].height + 8), (0, 0, 0))
        sheet.paste(img, (0, 24))
        sheet.paste(panels[0], (0, 24 + img.height + 4))
        sheet.paste(panels[1], (0, 24 + img.height + panels[0].height + 8))
        ImageDraw.Draw(sheet).text((3, 5), f"H{k + 1:02d}  footprint {poly.area:.0f} m2  ({len(P)} building points; green = vegetation)",
                                    fill=(255, 255, 255))
        sheet.save(work.p("handcheck", f"H{k + 1:02d}.png"))
        key.append({"label": f"H{k + 1:02d}", "id": bid})
    with open(work.p("handcheck_key.json"), "w") as f:
        json.dump(key, f, indent=0)
    log(f"[handcheck] {len(key)} images in {work.p('handcheck')}")


def cmd_score(args, work):
    """Hand labels {"H01": {"form": flat|gable|hip|complex|?, "simple": flat|gable|hip|?}} vs the lidar classifier."""
    path = work.p("handcheck_labels.json")
    if not os.path.exists(path):
        log("[score] no handcheck_labels.json in the work directory")
        return
    with open(path) as f:
        labels = json.load(f)
    with open(work.p("handcheck_key.json")) as f:
        key = {k["label"]: k["id"] for k in json.load(f)}
    with open(work.p("lidar_buildings.json")) as f:
        lb = json.load(f)["buildings"]
    form_pairs, simple_pairs, cx, cant = [], [], Counter(), 0
    for lab, bid in key.items():
        hl = labels.get(lab)
        if not hl or hl.get("form") == "?":
            cant += 1
            continue
        r = lb[bid]
        form_pairs.append((hl["form"], r["form"]))
        if hl.get("simple") in rp.SIMPLE:
            simple_pairs.append((hl["simple"], r["simple"]))
        cx[(hl["form"] == "complex", r["complex"])] += 1
    out = {"tool": TOOL_VERSION, "generated": time.strftime("%Y-%m-%d"), "sample": len(key), "cantTell": cant,
           "note": "Hand labels by the agent from point-cloud height images (hillshade, height colour, two side views), "
                   "labelled before looking at the classifier output; same pixels as the classifier, so not ground truth.",
           "fourClass_handVsLidar": table(form_pairs, list(rp.FORMS), 1),
           "simple_handVsLidar": table(simple_pairs, list(rp.SIMPLE), 1),
           "complexFlag": {"handComplex_lidarComplex": cx[(True, True)], "handComplex_lidarSimple": cx[(True, False)],
                           "handSimple_lidarComplex": cx[(False, True)], "handSimple_lidarSimple": cx[(False, False)]}}
    with open(os.path.join(RESULTS, "handcheck.json"), "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    log(f"[score] 4-class {out['fourClass_handVsLidar']['agreement']} simple {out['simple_handVsLidar']['agreement']} (n={len(form_pairs)})")


def cmd_vintage(args, work):
    """Lidar (2017) vs OSM (2026) mismatches, checked against a NAIP scene (e.g. 2023) when --naip is given:
    OSM footprints without a lidar roof, and building-class lidar clusters outside every OSM footprint.
    A mismatch whose NAIP NDVI is below the vegetation threshold has a non-vegetated surface in the NAIP year."""
    import rasterio
    from affine import Affine
    from rasterio import features as rfeat
    from rasterio.warp import transform as wtransform
    from scipy import ndimage
    from shapely.ops import unary_union
    pilot, params = load("pilot.json"), load("params.json")
    man = area_manifest(pilot)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    fps, _ = footprints(pilot, man)
    with open(work.p("lidar_buildings.json")) as f:
        L = json.load(f)
    shift = L["meta"]["globalShift"]
    pts, _ = load_points(work, man, pilot["marginMeters"])
    gh = ground_model(pts[2], params["groundCell"])
    bld = pts[6]
    bld = bld[(bld[:, 2] - gh(bld[:, 0], bld[:, 1])) >= params["minHeightAboveGround"]]
    bld[:, 0] += shift["eastMeters"]
    bld[:, 1] += shift["northMeters"]
    hw, hh = man["widthMeters"] / 2, man["heightMeters"] / 2
    n = int(math.ceil(2 * hw))
    occ = np.zeros((n, n), dtype=bool)
    cx, cy = np.floor(bld[:, 0] + hw).astype(int), np.floor(hh - bld[:, 1]).astype(int)
    ok = (cx >= 0) & (cx < n) & (cy >= 0) & (cy < n)
    occ[cy[ok], cx[ok]] = True
    occ = ndimage.binary_closing(occ, iterations=1)
    tr = Affine(1.0, 0, -hw, 0, -1.0, hh)
    fp_mask = rfeat.rasterize([(unary_union([f["poly"].buffer(1.5) for f in fps.values()]), 1)], out_shape=(n, n),
                              transform=tr, fill=0, dtype="uint8").astype(bool)
    lab, k = ndimage.label(occ & ~fp_mask)
    sizes = ndimage.sum(np.ones(lab.shape), lab, index=np.arange(1, k + 1)) if k else np.zeros(0)
    keep = [i + 1 for i, s in enumerate(sizes) if s >= 30]
    missing = [i for i, r in L["buildings"].items() if r.get("roofCover", 1) < params["vintage"]["newBuildingMaxShare"]
               and "small footprint" not in r.get("reasons", [])]
    out = {"tool": TOOL_VERSION, "lidarAcquisition": pilot["ept"]["acquired"], "osmTimestamp": L["meta"]["osmTimestamp"],
           "footprintsWithoutLidarRoof": len(missing),
           "lidarClustersOutsideOSM": {"count": len(keep), "areaM2Total": int(sum(sizes[i - 1] for i in keep)),
                                       "areaM2Percentiles": {f"p{q}": round(float(np.percentile([sizes[i - 1] for i in keep], q)), 1)
                                                             for q in (25, 50, 75)} if keep else None}}
    if args.naip:
        with rasterio.open(args.naip) as src:
            red, nir = src.read(1).astype(float), src.read(4).astype(float)
            inv, crs = ~src.transform, src.crs
        ndvi = np.where(nir + red > 0, (nir - red) / np.maximum(nir + red, 1), 0)

        def sample(e, nn):
            la, lo = rp.local_to_latlon(lat0, lon0, e, nn)
            xs, ys = wtransform("EPSG:4326", crs, lo.tolist(), la.tolist())
            col, row = inv * (np.array(xs), np.array(ys))
            col, row = col.astype(int), row.astype(int)
            ok = (row >= 0) & (row < ndvi.shape[0]) & (col >= 0) & (col < ndvi.shape[1])
            return ndvi[row[ok], col[ok]]
        thr = 0.2
        standing = 0
        for i in keep:
            rr, cc = np.nonzero(lab == i)
            v = sample(-hw + cc + 0.5, hh - rr - 0.5)
            standing += int(len(v) and np.median(v) < thr)
        built = 0
        for i in missing:
            er = fps[i]["poly"].buffer(-params["footprintErosion"])
            if er.is_empty:
                continue
            c = er.representative_point()
            gx, gy = rp.raster_cells(er.bounds[:2], er.bounds[2:], 1.0)
            import shapely
            m = shapely.contains_xy(er, gx, gy)
            v = sample(gx[m], gy[m]) if m.any() else sample(np.array([c.x]), np.array([c.y]))
            built += int(len(v) and np.median(v) < thr)
        side = os.path.join(os.path.dirname(args.naip), "naip.json")
        scene = os.path.basename(args.naip)
        if os.path.exists(side):
            with open(side) as f:
                scene = ", ".join(f"{i['id']} ({i['datetime'][:10]}, {i['gsd']} m)" for i in json.load(f)["items"])
        out["naipCheck"] = {"scene": scene, "ndviThreshold": thr,
                            "clustersNonVegetatedInNaip": standing, "clustersVegetatedInNaip": len(keep) - standing,
                            "missingFootprintsNonVegetatedInNaip": built, "missingFootprintsVegetatedInNaip": len(missing) - built,
                            "note": "non-vegetated = median NDVI below the threshold (roof or pavement); vegetated = trees or lawn in the NAIP year"}
    with open(os.path.join(RESULTS, "vintage.json"), "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    log(f"[vintage] {json.dumps(out)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["plan", "fetch", "classify", "p2", "compare", "handcheck", "score", "vintage", "all"])
    ap.add_argument("--work", required=True, help="work directory outside the repository")
    ap.add_argument("--max-depth", type=int, help="fetch: deepest EPT level to read (default data/pilot.json)")
    ap.add_argument("--naip", help="vintage: a NAIP GeoTIFF (R, G, B, NIR) covering the area, e.g. from aerial/canopy_areas.py fetch")
    ap.add_argument("--commit", help="p2: generator commit to record (default: git HEAD of this checkout)")
    args = ap.parse_args()
    work = Work(args.work)
    steps = ["plan", "fetch", "classify", "p2", "compare", "score"] + (["vintage"] if args.naip else []) \
        if args.command == "all" else [args.command]
    for s in steps:
        globals()["cmd_" + s](args, work)


if __name__ == "__main__":
    main()

