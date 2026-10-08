#!/usr/bin/env python3
"""Which building, archetype and palette variant is behind the walls of a hero frame, and does the wall face the sun?

Usage: python3 Tools/lookloop/wall_variants.py STAMP [VIEW ...]        (STAMP under .build/lookloop/runs/; default views = the four afternoon heroes)

The wall dE to a mock mixes three things: the albedo the generator drew (archetype and paletteVariant), whether that wall
is lit or in shade at the view's sun, and the grade. This separates them. It bakes the area with the release `worldbake`
(about 6 s, written to a temp folder, only the building features of scene.json are kept), casts a grid of rays from the
named camera into the OSM and Overture footprints, keeps wall-coloured pixels of the frame (not sky or foliage), groups
them by building and by sun-facing or shade, and prints the lit colour against the generated albedo (scene.json
colors[0]) with lit/albedo per channel in sRGB and linear. Sun-facing = wall normal . sun > 0.15 at the view's UTC time;
cast shadows of trees and eaves are NOT modelled, so a sunlit pixel can still be shadowed. Needs `.build/release/worldbake`
(build it under the heavy lock: swift build -c release --product worldbake); never builds it itself.
"""
import collections
import datetime
import glob
import json
import math
import os
import shutil
import statistics as st
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RUNS = os.environ.get("LOOKLOOP_RUNS") or os.path.join(ROOT, ".build/lookloop/runs")
ASPECT = 1005 / 565  # every look-loop frame is 1005 x 565
VFOV = 50.0
VIEWS = {  # view id -> area and its named WorldLab camera (Apps/WorldLab/Resources/demo.json), or the v2-01 street fixture
    "lakeview-street-afternoon": {"area": "lakeview-sheil-park", "camera": "roscoe-street"},
    "lakeview-postcard-afternoon": {"area": "lakeview-sheil-park", "camera": "lakeview-postcard"},
    "wilmette-street-afternoon": {"area": "wilmette-vattmann-park", "camera": "northshore-postcard"},
    "ordinary-street-afternoon": {"area": "sloans-lake", "preset": "v2-01"},
}


def sun_position(lat, lon, utc):
    """NOAA solar azimuth (degrees clockwise from north) and elevation (degrees) at a UTC datetime."""
    n = utc.timetuple().tm_yday
    hour = utc.hour + utc.minute / 60 + utc.second / 3600
    g = 2 * math.pi / 365 * (n - 1 + (hour - 12) / 24)
    eqt = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g) - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g)
            + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    ha = math.radians((hour * 60 + eqt + 4 * lon) / 4 - 180)
    la = math.radians(lat)
    zen = math.acos(max(-1, min(1, math.sin(la) * math.sin(decl) + math.cos(la) * math.cos(decl) * math.cos(ha))))
    az = math.atan2(math.sin(ha), math.cos(ha) * math.sin(la) - math.tan(decl) * math.cos(la)) + math.pi
    return math.degrees(az) % 360, 90 - math.degrees(zen)


def ray_hit(polys, eye, az_deg, pitch_deg, u, v, sun):
    """First building a ray from the origin hits, for the pixel (u, v) in fractions of the frame.
    polys: [(id, [(x, y) metres east/north of the camera], top height m)]. Returns (distance, id, wall normal . sun) or None."""
    tv = math.tan(math.radians(VFOV) / 2)
    th = tv * ASPECT
    az, p = math.radians(az_deg), math.radians(pitch_deg)
    f = (math.cos(p) * math.sin(az), math.cos(p) * math.cos(az), -math.sin(p))
    r = (math.cos(az), -math.sin(az), 0.0)
    up = (r[1] * f[2] - r[2] * f[1], r[2] * f[0] - r[0] * f[2], r[0] * f[1] - r[1] * f[0])
    x, y = 2 * u - 1, 1 - 2 * v
    d = [f[k] + x * th * r[k] + y * tv * up[k] for k in range(3)]
    dh = math.hypot(d[0], d[1])
    slope = d[2] / dh
    ux, uy = d[0] / dh, d[1] / dh
    best = None
    for wid, pts, top in polys:
        for a in range(len(pts) - 1):
            (x1, y1), (x2, y2) = pts[a], pts[a + 1]
            ex, ey = x2 - x1, y2 - y1
            den = ux * ey - uy * ex
            if abs(den) < 1e-9:
                continue
            t = (x1 * ey - y1 * ex) / den
            s = (x1 * uy - y1 * ux) / den
            if t <= 0.3 or s < 0 or s > 1:
                continue
            z = eye + slope * t
            if z < 0 or z > top:
                continue
            if best is None or t < best[0]:
                nx, ny = ey, -ex
                n = math.hypot(nx, ny)
                nx, ny = nx / n, ny / n
                if nx * ux + ny * uy > 0:  # the wall normal faces the camera
                    nx, ny = -nx, -ny
                best = (t, wid, nx * sun[0] + ny * sun[1])
    return best


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


class Area:
    def __init__(self, name):
        self.name = name
        d = json.load(open(os.path.join(ROOT, "Data/areas", name, "osm.json")))
        nodes = {e["id"]: (e["lat"], e["lon"]) for e in d["elements"] if e["type"] == "node"}
        self.footprints = {}  # scene id -> [(lat, lon)]
        for e in d["elements"]:
            if e["type"] == "way" and "building" in (e.get("tags") or {}):
                ll = [nodes.get(n) for n in e["nodes"]]
                if all(ll):
                    self.footprints[f"way/{e['id']}"] = ll
        ov = os.path.join(ROOT, "Data/areas", name, "overture-buildings.json")
        if os.path.exists(ov):
            for b in json.load(open(ov))["buildings"]:
                self.footprints[f"overture/{b['id'].replace('-', '')[:16]}"] = [(p[1], p[0]) for p in b["polygons"][0][0]]
        self.scene = {}

    def bake(self, demo, utc, worldbake):
        """Bake the area into a temp folder with the demo recipe and keep only the buildings' generated blocks."""
        cfg = demo["areas"].get(self.name) or demo
        f = cfg["focus"]
        tmp = tempfile.mkdtemp(prefix="wallbake-")
        try:
            cmd = [worldbake, "export", os.path.join(ROOT, "Data/areas", self.name), tmp, "--date", utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                   "--focus", f"{f['south']},{f['west']},{f['north']},{f['east']}"]
            if cfg.get("profile"):
                cmd += ["--profile", cfg["profile"]]
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            for p in glob.glob(os.path.join(tmp, "chunks/*/scene.json")):
                for ft in json.load(open(p))["features"]:
                    if ft.get("kind") == "building":
                        self.scene[ft["id"]] = ft.get("generated") or {}
        finally:
            shutil.rmtree(tmp, ignore_errors=True)

    def polygons(self, lat0, lon0, radius=200):
        k = math.cos(math.radians(lat0))
        out = []
        for wid, ll in self.footprints.items():
            pts = [((lo - lon0) * k * 111320.0, (la - lat0) * 110574.0) for la, lo in ll]
            cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
            if cx * cx + cy * cy <= radius * radius:
                out.append((wid, pts, self.scene.get(wid, {}).get("topHeight", 8.0)))
        return out


def camera(demo, spec):
    """(lat, lon, eye height m, heading deg, pitch down deg) of a view's camera."""
    if "camera" in spec:
        c = demo["areas"][spec["area"]]["cameras"][spec["camera"]]
        return c["lat"], c["lon"], c.get("height", 1.65), c["heading"], c.get("pitchDown", 3)
    fx = demo["fixtures"]  # v2-01: the dog at the anchor, camera 2.6 m east and 1.25 m up, looking west at the dog
    off, tgt = fx["streetCameraOffset"], fx["streetTargetOffset"]
    lat = fx["streetAnchor"]["lat"]
    lon = fx["streetAnchor"]["lon"] + off[0] / (111320 * math.cos(math.radians(lat)))
    return lat, lon, off[1], 270.0, math.degrees(math.atan2(off[1] - tgt[1], off[0]))


def scan(vid, area, demo, view, im, step=0.025):
    lat, lon, eye, heading, pitch = camera(demo, VIEWS[vid])
    utc = datetime.datetime.strptime(view["utc"], "%Y-%m-%dT%H:%M:%SZ")
    saz, sel = sun_position(lat, lon, utc)
    sun = (math.sin(math.radians(saz)), math.cos(math.radians(saz)))
    polys = area.polygons(lat, lon)
    W, H = im.size
    groups = collections.defaultdict(list)
    j = 0.0
    while j < 0.62:  # the lower part of every frame is ground
        i = 0.0
        while i < 1.0:
            hit = ray_hit(polys, eye, heading, pitch, i, j, sun)
            if hit:
                t, wid, dot = hit
                px = im.getpixel((min(W - 1, int(i * W)), min(H - 1, int(j * H))))
                if px[0] >= px[1] - 3 and px[1] >= px[2] - 3 and sum(px) > 60:  # warm or neutral: wall, not sky or foliage
                    groups[(wid, "sun" if dot > 0.15 else "shade")].append((px, t))
            i += step
        j += step
    rows = []
    for (wid, face), items in groups.items():
        if len(items) < 6 or wid not in area.scene:
            continue
        g = area.scene[wid]
        lit = tuple(int(st.median(c)) for c in zip(*[p for p, _ in items]))
        rows.append(dict(id=wid, face=face, n=len(items), dist=st.median(t for _, t in items), lit="#%02X%02X%02X" % lit,
                         albedo=(g.get("colors") or ["#000000"])[0], arch=g.get("archetype") or g.get("family") or g.get("role"),
                         variant=g.get("paletteVariant"), colorSet=g.get("colorSet"), floors=g.get("floors")))
    rows.sort(key=lambda r: -r["n"])
    return rows, (saz, sel)


def main():
    from PIL import Image
    args = sys.argv[1:]
    if not args:
        raise SystemExit(__doc__)
    stamp, ids = args[0], args[1:] or list(VIEWS)
    worldbake = next((p for p in (os.environ.get("WORLDBAKE"), os.path.join(ROOT, ".build/release/worldbake"),
                                  os.path.join(ROOT, ".build/arm64-apple-macosx/release/worldbake")) if p and os.path.exists(p)), None)
    if not worldbake:
        raise SystemExit("worldbake release build not found: run `swift build -c release --product worldbake` under the heavy lock first")
    demo = json.load(open(os.path.join(ROOT, "Apps/WorldLab/Resources/demo.json")))
    views = {v["id"]: v for v in json.load(open(os.path.join(HERE, "views.json")))["views"]}
    areas = {}
    for vid in ids:
        spec = VIEWS[vid]
        if spec["area"] not in areas:
            areas[spec["area"]] = Area(spec["area"])
            areas[spec["area"]].bake(demo, datetime.datetime.strptime(views[vid]["utc"], "%Y-%m-%dT%H:%M:%SZ"), worldbake)
        im = Image.open(os.path.join(RUNS, stamp, "raw", f"{vid}.png")).convert("RGB")
        rows, sp = scan(vid, areas[spec["area"]], demo, views[vid], im)
        print(f"\n{vid}: sun az {sp[0]:.0f} el {sp[1]:.0f} at the view's time")
        for r in rows[:8]:
            al, li = hexrgb(r["albedo"]), hexrgb(r["lit"])
            srgb = "/".join(f"{li[k] / max(1, al[k]):.2f}" for k in range(3))
            linr = "/".join(f"{lin(li[k]) / max(1e-4, lin(al[k])):.2f}" for k in range(3))
            print(f"  {r['id']:27s} {r['face']:5s} {r['n']:3d} px ~{r['dist']:3.0f} m  {str(r['arch']):17s} variant {r['variant']} set {r['colorSet']}  "
                  f"albedo {r['albedo']} lit {r['lit']}  lit/albedo sRGB {srgb} linear {linr}")


if __name__ == "__main__":
    main()
