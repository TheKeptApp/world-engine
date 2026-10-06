#!/usr/bin/env python3
"""Measured triangle counts from exported world packages (Tools/regionkit/audit).

The pre-P2 estimate (`trimodel.py`) ported the generator's counting rules. This tool measures
instead: it runs `worldbake export` for each configured run (`pkgruns.json`), reads the chunk
meshes of the package (GLB accessor counts and positions, `_FEATURE` ids), the instance table and
the prototype meshes, and feeds those measured numbers into the audit's street-view method
(`audit.wedge_hits_rect`: 25 camera positions at the chunk centres x 8 headings, portrait 9:19.5,
50 deg vertical field of view, culling per chunk entity and per instanced-prop entity, plus 200
tufts), as `World.estimateViewTriangles` does.

Steps:
  run      init-area + fetch (Overpass, one request at a time, >= 10 s apart) for cells that have no
           area folder yet, then export and measure every run, delete each package after reading
           it, and write results/triangles_p2.json
  measure  measure one existing package directory (prints JSON; for checks)

Only aggregates are written (per-run totals, per-kind sums, view statistics); no geometry, no
feature IDs. Needs numpy. Work folders (areas, packages) must be outside the repository.
"""
import argparse
import json
import math
import os
import shutil
import statistics
import struct
import subprocess
import sys
import time
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
RESULTS = os.path.join(HERE, "results")
sys.path.insert(0, HERE)
import audit  # noqa: E402  (wedge_hits_rect, VIEW_HALF_FOV, load_cells)

FLAT_Y = 0.3          # World.splitFlatGround: a triangle with every corner below 0.3 m is flat ground
LOD_NEAR, LOD_MID = 45.0, 160.0   # PropLibrary.lodDistances
TUFTS, TUFT_TRIS = 200, 17        # World.estimateViewTriangles: up to 200 tufts x 17
SHADOW_DISTANCE = 80.0            # World.shadowDistance
BOUNDARY_TRIS = 2


# ------------------------------------------------------------------------------------- GLB

COMPONENTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
DTYPES = {5123: np.uint16, 5125: np.uint32, 5126: np.float32}


def read_glb(path):
    """Returns (gltf JSON, binary chunk) of a .glb file."""
    with open(path, "rb") as f:
        data = f.read()
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2:
        raise ValueError(f"{path}: not a glTF 2 binary")
    off, gltf, binary = 12, None, b""
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif ctype == 0x004E4942:
            binary = chunk
        off += 8 + clen
    return gltf, binary


def accessor(gltf, binary, i):
    a = gltf["accessors"][i]
    v = gltf["bufferViews"][a["bufferView"]]
    n = COMPONENTS[a["type"]]
    arr = np.frombuffer(binary, dtype=DTYPES[a["componentType"]], count=a["count"] * n,
                        offset=v.get("byteOffset", 0) + a.get("byteOffset", 0))
    return arr.reshape(a["count"], n) if n > 1 else arr


def glb_primitives(path):
    """Per primitive: material name, triangle indices (n x 3), positions (m x 3), feature ids (m)."""
    gltf, binary = read_glb(path)
    out = []
    for mesh in gltf.get("meshes", []):
        for p in mesh["primitives"]:
            idx = accessor(gltf, binary, p["indices"]).astype(np.int64).reshape(-1, 3)
            pos = accessor(gltf, binary, p["attributes"]["POSITION"])
            feat = accessor(gltf, binary, p["attributes"]["_FEATURE"]) if "_FEATURE" in p["attributes"] else None
            out.append({"material": gltf["materials"][p["material"]]["name"], "indices": idx, "positions": pos,
                        "features": feat, "count": gltf["accessors"][p["indices"]]["count"] // 3})
    return out


def glb_bounds(path):
    gltf, _ = read_glb(path)
    lo, hi = [math.inf] * 3, [-math.inf] * 3
    for mesh in gltf.get("meshes", []):
        for p in mesh["primitives"]:
            a = gltf["accessors"][p["attributes"]["POSITION"]]
            lo = [min(x, y) for x, y in zip(lo, a["min"])]
            hi = [max(x, y) for x, y in zip(hi, a["max"])]
    return lo, hi


# ------------------------------------------------------------------------------------- package

def kind_group(kind):
    if kind == "building":
        return "buildings"
    if kind == "generated-curb":
        return "curbs"
    if kind in ("road", "path", "crossing"):
        return "roadsPaths"
    if kind in ("sidewalk", "generated-sidewalk", "generated-sidewalkEdge", "generated-sidewalk-edge"):
        return "sidewalks"
    if kind == "generated-ground":
        return "ground"
    return "areasOther"


def measure_chunk(pkg, ch, lod):
    scene = ch["_scene"]
    kinds = {f["index"]: f["kind"] for f in scene["features"]}
    roles = {f["index"]: f["generated"]["role"] for f in scene["features"] if "generated" in f}
    res = {"tris": 0, "raised": 0, "flat": 0, "water": 0, "byKind": Counter(), "raisedByKind": Counter(), "buildingByRole": Counter()}
    ox, oz = ch["origin"][0], ch["origin"][2]
    boxes = {"flat": [], "raised": []}

    def add_box(part, pos, idx):
        if len(idx):
            v = pos[np.unique(idx)]
            # Scene x east, z south (relative to the chunk origin) -> local rectangle (x east, y north).
            boxes[part].append((float(v[:, 0].min()) + ox, -(float(v[:, 2].max()) + oz), float(v[:, 0].max()) + ox, -(float(v[:, 2].min()) + oz)))
    for p in glb_primitives(os.path.join(pkg, ch["lods"][lod])):
        n = p["count"]
        res["tris"] += n
        if p["material"] == "worldWater":
            res["water"] += n
            add_box("flat", p["positions"], p["indices"])  # World.swift draws water with the flat ground entity
            continue
        y = p["positions"][:, 1][p["indices"]]
        flat = np.all(y < FLAT_Y, axis=1)
        add_box("flat", p["positions"], p["indices"][flat])
        add_box("raised", p["positions"], p["indices"][~flat])
        res["flat"] += int(flat.sum())
        res["raised"] += int((~flat).sum())
        fid = p["features"][p["indices"][:, 0]].astype(np.int64)
        for f, c in zip(*np.unique(fid, return_counts=True)):
            g = kind_group(kinds.get(int(f), "none"))
            res["byKind"][g] += int(c)
            if int(f) in roles:
                res["buildingByRole"][roles[int(f)]] += int(c)
        for f, c in zip(*np.unique(fid[~flat], return_counts=True)):
            res["raisedByKind"][kind_group(kinds.get(int(f), "none"))] += int(c)
    for part, bs in boxes.items():
        res[part + "Rect"] = (min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs)) if bs else None
    res["flatTris"] = res["flat"] + res["water"]
    return res


def load_package(pkg):
    with open(os.path.join(pkg, "world.json")) as f:
        world = json.load(f)
    for ch in world["chunks"]:
        with open(os.path.join(pkg, ch["scene"])) as f:
            ch["_scene"] = json.load(f)
        b = ch["bounds"]
        # Mesh bounds in scene coordinates (x east, z south) -> local (x east, y north) rectangle.
        ch["_rect"] = (b[0][0], -b[1][2], b[1][0], -b[0][2]) if b else tuple(ch["_scene"]["rect"])
    with open(os.path.join(pkg, "instances.json")) as f:
        inst = json.load(f)["instances"]
    protos = {}
    for p in world["prototypes"]:
        lo, hi = glb_bounds(os.path.join(pkg, p["lods"][0]))
        r = max(abs(lo[0]), abs(hi[0]), abs(lo[2]), abs(hi[2]))
        protos[(p["kind"], p["variant"])] = {"tris": p["triangles"], "radius": r, "isTree": p["isTree"]}
    return world, inst, protos


def measure_package(pkg):
    world, inst, protos = load_package(pkg)
    chunks = {}
    for ch in world["chunks"]:
        m0 = measure_chunk(pkg, ch, 0)
        m1 = measure_chunk(pkg, ch, 1)
        if m0["tris"] != ch["triangles"][0] or m1["tris"] != ch["triangles"][1]:
            raise ValueError(f"{ch['id']}: GLB triangles {m0['tris']}/{m1['tris']} != world.json {ch['triangles']}")
        chunks[ch["id"]] = {"rect": ch["_rect"], "gridRect": tuple(ch["_scene"]["rect"]), "detail": ch["detail"], "lod0": m0, "lod1": m1}
    return world, inst, protos, chunks


# ------------------------------------------------------------------------------------- view

def prop_view(inst, protos, cam, heading, half_fov=audit.VIEW_HALF_FOV, far=5000.0):
    """Instanced props as World.swift culls them: per kind/variant/400 m cell, one entity per LOD
    slot (trees and bushes; bucket by distance) or one entity (lamps, benches); an entity counts
    whole when its bounds meet the view wedge."""
    groups = defaultdict(list)
    for i in inst:
        pr = protos[(i["kind"], i["variant"])]
        x, z = i["position"][0], -i["position"][2]
        if len(pr["tris"]) == 3:
            d = math.hypot(x - cam[0], z - cam[1])
            lod = 0 if d < LOD_NEAR else (1 if d < LOD_MID else 2)
        else:
            lod = 0
        groups[(i["kind"], i["variant"], i["cell"][0], i["cell"][1], lod)].append((x, z, pr["radius"] * i["scale"]))
    out = Counter()
    for (kind, var, _, _, lod), ps in groups.items():
        r = (min(p[0] - p[2] for p in ps), min(p[1] - p[2] for p in ps), max(p[0] + p[2] for p in ps), max(p[1] + p[2] for p in ps))
        if audit.wedge_hits_rect(cam, heading, half_fov, r, far=far):
            pr = protos[(kind, var)]
            label = "trees" if pr["isTree"] else ("bushes" if len(pr["tris"]) == 3 else "lampsBenches")
            out[label] += len(ps) * pr["tris"][lod]
    return out


def rect_distance(r, p):
    dx = max(r[0] - p[0], 0, p[0] - r[2])
    dy = max(r[1] - p[1], 0, p[1] - r[3])
    return math.hypot(dx, dy)


def view_rows(chunks, inst, protos, cams, heads, chunk_tris=None, grid_culling=False):
    """grid_culling=True culls each chunk by its 200 m grid square (the pre-P2 audit's method) instead of the
    flat and raised entities' mesh bounds (World.buildChunks)."""
    rows = []
    for ci, cam in enumerate(cams):
        for h in heads:
            st = 0
            for cid, c in chunks.items():
                m = chunk_tris(cid, c, cam) if chunk_tris else c["lod0"]
                # Two entities per chunk, as World.buildChunks: flat ground (+ water) and raised geometry.
                for part, n in (("flatRect", m["flatTris"]), ("raisedRect", m["raised"])):
                    rect = c["gridRect"] if grid_culling else m[part]
                    if m[part] and audit.wedge_hits_rect(cam, h, audit.VIEW_HALF_FOV, rect):
                        st += n
            props = prop_view(inst, protos, cam, h)
            total = st + sum(props.values()) + TUFTS * TUFT_TRIS + BOUNDARY_TRIS
            sh_wedge = sum(c["lod0"]["raised"] for c in chunks.values() if c["lod0"]["raisedRect"]
                           and audit.wedge_hits_rect(cam, h, audit.VIEW_HALF_FOV, c["lod0"]["raisedRect"], far=SHADOW_DISTANCE))
            sh_radius = sum(c["lod0"]["raised"] for c in chunks.values() if c["lod0"]["raisedRect"]
                            and rect_distance(c["lod0"]["raisedRect"], cam) <= SHADOW_DISTANCE)
            trees80 = sum(protos[(i["kind"], i["variant"])]["tris"][0 if math.hypot(i["position"][0] - cam[0], -i["position"][2] - cam[1]) < LOD_NEAR else 1]
                          for i in inst if protos[(i["kind"], i["variant"])]["isTree"]
                          and math.hypot(i["position"][0] - cam[0], -i["position"][2] - cam[1]) <= SHADOW_DISTANCE)
            rows.append({"cam": ci, "heading": round(math.degrees(h)), "static": st, "trees": props["trees"],
                         "bushes": props["bushes"], "lampsBenches": props["lampsBenches"], "total": total,
                         "shadowRaisedWedge80": sh_wedge, "shadowRaisedRadius80": sh_radius, "shadowTrees80": trees80})
    return rows


def pctl(values, q):
    v = sorted(values)
    return v[int(q * (len(v) - 1))]


def summarize(world, chunks, rows, cams):
    def tot(lod, key):
        return sum(c[lod][key] for c in chunks.values())

    def kinds(lod, key="byKind"):
        k = Counter()
        for c in chunks.values():
            k.update(c[lod][key])
        return dict(k)
    centre = len(cams) // 2
    return {
        "chunks": len(chunks), "fullDetailChunks": sum(1 for c in chunks.values() if c["detail"] == "full"),
        "focus": world["recipe"]["focus"], "profile": world["recipe"]["profile"],
        "lod0": {"tris": tot("lod0", "tris"), "raised": tot("lod0", "raised"), "flat": tot("lod0", "flat"),
                 "water": tot("lod0", "water"), "byKind": kinds("lod0"), "raisedByKind": kinds("lod0", "raisedByKind"),
                 "buildingByRole": kinds("lod0", "buildingByRole")},
        "lod1": {"tris": tot("lod1", "tris"), "raised": tot("lod1", "raised"), "byKind": kinds("lod1"),
                 "buildingByRole": kinds("lod1", "buildingByRole")},
        "chunkMaxLod0": max(c["lod0"]["tris"] for c in chunks.values()),
        "chunkMaxRaisedLod0": max(c["lod0"]["raised"] for c in chunks.values()),
        "chunkMaxRaisedLod1": max(c["lod1"]["raised"] for c in chunks.values()),
        "view": {
            "n": len(rows),
            "totalMean": round(statistics.mean(r["total"] for r in rows)),
            "totalP90": pctl([r["total"] for r in rows], 0.9),
            "totalMax": max(r["total"] for r in rows), "totalMin": min(r["total"] for r in rows),
            "staticMean": round(statistics.mean(r["static"] for r in rows)),
            "treesMean": round(statistics.mean(r["trees"] for r in rows)),
            "bushesMean": round(statistics.mean(r["bushes"] for r in rows)),
            "lampsBenchesMean": round(statistics.mean(r["lampsBenches"] for r in rows)),
            "tufts": TUFTS * TUFT_TRIS,
            "centreMean": round(statistics.mean(r["total"] for r in rows if r["cam"] == centre)),
            "shadowRaisedWedge80Mean": round(statistics.mean(r["shadowRaisedWedge80"] for r in rows)),
            "shadowRaisedWedge80Max": max(r["shadowRaisedWedge80"] for r in rows),
            "shadowRaisedRadius80Mean": round(statistics.mean(r["shadowRaisedRadius80"] for r in rows)),
            "shadowRaisedRadius80Max": max(r["shadowRaisedRadius80"] for r in rows),
            "shadowTrees80Mean": round(statistics.mean(r["shadowTrees80"] for r in rows)),
        },
    }


def cameras(world):
    """Chunk centres of the area (25 for a 1 km cell) x 8 headings, as the pre-P2 audit."""
    cams = sorted({(round(c["origin"][0], 3), round(-c["origin"][2], 3)) for c in world["chunks"]}, key=lambda p: (p[0], p[1]))
    return cams, [k * math.pi / 4 for k in range(8)]


def measure(pkg, whatif_lod1=None):
    world, inst, protos, chunks = measure_package(pkg)
    cams, heads = cameras(world)
    rows = view_rows(chunks, inst, protos, cams, heads)
    out = summarize(world, chunks, rows, cams)
    grid = [r["total"] for r in view_rows(chunks, inst, protos, cams, heads, grid_culling=True)]
    out["viewGridCulling"] = {"totalMean": round(statistics.mean(grid)), "totalP90": pctl(grid, 0.9), "totalMax": max(grid),
                              "note": "same measured counts, chunks culled by their 200 m grid squares as in the pre-P2 audit"}
    out["instances"] = dict(Counter(i["kind"] for i in inst))
    out["prototypeTris"] = {f"{k}-{v}": p["tris"] for (k, v), p in sorted(protos.items())}
    if whatif_lod1:
        # What-if (not current behaviour): lod0 (full) chunks within 150 m of the camera, lod1 beyond.
        totals = [r["total"] for r in view_rows(chunks, inst, protos, cams, heads,
                                                chunk_tris=lambda cid, c, cam: c["lod0"] if rect_distance(c["gridRect"], cam) <= 150 else c["lod1"])]
        out["whatIfDistanceLod150m"] = {"viewMean": round(statistics.mean(totals)), "viewP90": pctl(totals, 0.9), "viewMax": max(totals),
                                        "note": "full-detail chunk within 150 m of the camera, lod1 beyond; props as current"}
    return out, chunks


# ------------------------------------------------------------------------------------- geodesy (focus boxes)

A, F = 6378137.0, 1 / 298.257223563
E2 = F * (2 - F)


def _ecef(lat, lon):
    la, lo = math.radians(lat), math.radians(lon)
    n = A / math.sqrt(1 - E2 * math.sin(la) ** 2)
    return (n * math.cos(la) * math.cos(lo), n * math.cos(la) * math.sin(lo), n * (1 - E2) * math.sin(la))


def enu(lat0, lon0, lat, lon):
    """Exact WGS84 east/north of (lat, lon) relative to (lat0, lon0), as LocalFrame.enu."""
    p, p0 = _ecef(lat, lon), _ecef(lat0, lon0)
    d = [a - b for a, b in zip(p, p0)]
    sl, cl = math.sin(math.radians(lat0)), math.cos(math.radians(lat0))
    so, co = math.sin(math.radians(lon0)), math.cos(math.radians(lon0))
    return (-so * d[0] + co * d[1], -sl * co * d[0] - sl * so * d[1] + cl * d[2])


def latlon_at(lat0, lon0, e, n):
    """Inverse of `enu` by fixed-point refinement (sub-millimetre after a few steps)."""
    lat, lon = lat0, lon0
    for _ in range(6):
        ce, cn = enu(lat0, lon0, lat, lon)
        sl = math.sin(math.radians(lat))
        m = A * (1 - E2) / (1 - E2 * sl * sl) ** 1.5
        nn = A / math.sqrt(1 - E2 * sl * sl)
        lat += math.degrees((n - cn) / m)
        lon += math.degrees((e - ce) / (nn * math.cos(math.radians(lat))))
    return lat, lon


def focus_box(lat0, lon0, half_e, half_n):
    s, w = latlon_at(lat0, lon0, -half_e, -half_n)
    nl, e = latlon_at(lat0, lon0, half_e, half_n)
    return f"{s:.7f},{w:.7f},{nl:.7f},{e:.7f}"


# ------------------------------------------------------------------------------------- run

def worldbake_cmd(path):
    if path:
        return [path]
    built = os.path.join(REPO, ".build", "release", "worldbake")
    return [built] if os.path.exists(built) else ["swift", "run", "-c", "release", "worldbake"]


def ensure_area(run, cfg, work, wb):
    area = os.path.join(work, "areas", run["area"])
    if os.path.exists(os.path.join(area, "osm.json")):
        return area
    if "copyFrom" in cfg["areas"][run["area"]]:
        shutil.copytree(os.path.join(REPO, cfg["areas"][run["area"]]["copyFrom"]), area)
        return area
    cell = next(c for _, c in audit.all_cells(audit.load_cells()) if c["id"] == cfg["areas"][run["area"]]["cell"])
    lat, lon = cell["center"]
    subprocess.run(wb + ["init-area", area, "--id", run["area"], "--name", cell["id"], "--lat", str(lat), "--lon", str(lon),
                         "--width", str(cfg["sizeMeters"]), "--height", str(cfg["sizeMeters"])], check=True)
    time.sleep(10)  # Overpass etiquette: one request at a time, well apart
    subprocess.run(wb + ["fetch", area], check=True)
    return area


def git_head():
    try:
        return subprocess.run(["git", "-C", REPO, "rev-parse", "--short", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return "unknown"


def cmd_run(args):
    with open(os.path.join(HERE, "pkgruns.json")) as f:
        cfg = json.load(f)
    work = os.path.abspath(args.work)
    if work.startswith(REPO + os.sep):
        sys.exit("refusing a work directory inside the repository")
    wb = worldbake_cmd(args.worldbake)
    commit = args.commit or git_head()
    out = {"method": "measured: worldbake export per run, GLB accessor counts per chunk and LOD, instances.json + prototype "
                     "triangles, audit street-view culling (pkgtris.py)",
           "generatorCommit": commit, "date": cfg["date"], "runs": {}}
    for run in cfg["runs"]:
        if args.only and run["area"] not in args.only:
            continue
        area = ensure_area(run, cfg, work, wb)
        with open(os.path.join(area, "manifest.json")) as f:
            man = json.load(f)
        lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
        for focus_name in run["focus"]:
            pkg = os.path.join(work, "pkgs", f"{run['area']}-{run['profile'] or 'auto'}-{focus_name}")
            cmd = wb + ["export", area, pkg, "--date", cfg["date"], "--version", commit]
            if run["profile"]:
                cmd += ["--profile", run["profile"]]
            if focus_name != "whole":
                fz = cfg["focusBoxes"][focus_name]
                cmd += ["--focus", focus_box(lat0, lon0, fz["halfEastMeters"], fz["halfNorthMeters"])]
            r = subprocess.run(cmd, capture_output=True, text=True, check=True)
            res, _ = measure(pkg, whatif_lod1=(focus_name == "whole"))
            res["worldbake"] = r.stdout.strip().split(": ", 1)[-1]
            res["osmTimestamp"] = next((s.get("dataTimestamp") for s in man.get("sources", [])), None)
            key = f"{run['area']}:{res['profile']}:{focus_name}"
            out["runs"][key] = res
            print(f"{key}: lod0 {res['lod0']['tris']:,} lod1 {res['lod1']['tris']:,} view mean {res['view']['totalMean']:,} "
                  f"p90 {res['view']['totalP90']:,} max {res['view']['totalMax']:,}", flush=True)
            if not args.keep:
                shutil.rmtree(pkg)
    os.makedirs(RESULTS, exist_ok=True)
    path = os.path.join(RESULTS, "triangles_p2.json")
    prev = {}
    if args.only and os.path.exists(path):
        with open(path) as f:
            prev = json.load(f)
        prev.get("runs", {}).update(out["runs"])
        out["runs"] = prev["runs"]
    with open(path, "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)
    print("wrote", path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--work", required=True, help="folder for area copies and packages (outside the repository)")
    r.add_argument("--worldbake", help="path to a built worldbake (default .build/release/worldbake, else swift run)")
    r.add_argument("--commit", help="generator commit to record (default: git HEAD)")
    r.add_argument("--only", nargs="*", help="limit to these area ids")
    r.add_argument("--keep", action="store_true", help="keep the packages")
    m = sub.add_parser("measure")
    m.add_argument("package")
    args = ap.parse_args()
    if args.cmd == "run":
        cmd_run(args)
    else:
        res, _ = measure(args.package, whatif_lod1=True)
        print(json.dumps(res, indent=1, sort_keys=True))


if __name__ == "__main__":
    main()
