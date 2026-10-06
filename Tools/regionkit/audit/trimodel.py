"""Triangle-count model of the WorldEngine generator (estimate; no Swift build or run).

Ports the *counting* rules of the generator, not its geometry: for every mesh piece the Swift
code emits, we add the same number of triangles. Sources (read at Sources/, commit of this audit):

  WorldGen/BuildingGenerator.swift  walls in AO bands, roofs, door/porch/steps, windows
                                    (6 quads = 12 triangles each), chimney, contact skirt
  WorldGen/Shapes.swift             gabled 30 / hipped 20-22 / slab 12 triangles per roof rect;
                                    flat roof = earcut cap + parapet quads; boxes 10 (no bottom)
  WorldGen/FootprintAnalysis.swift  footprint classes and roof rectangles (ported exactly)
  WorldGen/SceneGenerator.swift     200 m chunks; full detail only in chunks meeting the focus
                                    rectangle (default focus = whole area); curbs, sidewalk
                                    edges and generated lamps only inside the focus rectangle
  WorldGen/Streetscape.swift        curbs resampled every 1 m (6 triangles per metre per side),
                                    generated sidewalks every 2 m, lamps every 38 m
  WorldGen/Props.swift              tree/bush/lamp/bench meshes per LOD (counted below)
  WorldMesh/Primitives.swift        ribbons: 2 triangles per segment; earcut caps n-2+2h

StableRandom (SplitMix64 + FNV-1a salts) is ported bit-exactly so per-building choices (house
type, roof shape, porch, chimney, window sizes) match the generator for the same OSM IDs.
Known approximations (stated in the report): the front edge is guessed from the footprint
(no street lookup), and the ground model
skips ribbon bevel joins.
"""
import json
import math
import os
from collections import Counter, defaultdict

M64 = (1 << 64) - 1


# ---------------------------------------------------------------------------------------------
# StableRandom (Sources/WorldGeo/StableRandom.swift) + helpers (WorldGen/StyleProfile.swift)
# ---------------------------------------------------------------------------------------------

def _mix(x):
    z = x & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)


def _fnv1a(s):
    h = 0xCBF29CE484222325
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x100000001B3) & M64
    return h


class SR:
    def __init__(self, parts, salt):
        h = _fnv1a(salt)
        for p in parts:
            h = _mix(h ^ (p & M64))
        self.state = h

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & M64
        return _mix(self.state)

    def unit(self):
        return (self.next() >> 11) * (2.0 ** -53)

    def range(self, lo, hi):
        return lo + (hi - lo) * self.unit()

    def rangel(self, r):
        return self.range(r[0], r[1]) if len(r) >= 2 else (r[0] if r else 0.0)

    def chance(self, p):
        return self.unit() < p

    def pick(self, items, weight):
        total = sum(max(0.0, weight(i)) for i in items)
        r = self.unit() * total
        for i in items:
            r -= max(0.0, weight(i))
            if r < 0:
                return i
        return items[-1]


def ref_random(ref, salt):
    kind, sid = ref.split("/")
    code = {"node": 1, "way": 2, "relation": 3}[kind]
    return SR([code, int(sid) & M64], salt)


# ---------------------------------------------------------------------------------------------
# Footprint analysis (exact port)
# ---------------------------------------------------------------------------------------------

def _cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def ring_area(r):
    s = 0.0
    n = len(r)
    for i in range(n):
        s += r[i][0] * r[(i + 1) % n][1] - r[(i + 1) % n][0] * r[i][1]
    return s / 2


def ring_contains(r, p):
    inside = False
    j = len(r) - 1
    for i in range(len(r)):
        a, b = r[i], r[j]
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]:
            inside = not inside
        j = i
    return inside


class ORect:
    __slots__ = ("c", "u", "hl", "hw")

    def __init__(self, c, u, hl, hw):
        if hw > hl:
            self.c, self.u, self.hl, self.hw = c, (-u[1], u[0]), hw, hl
        else:
            self.c, self.u, self.hl, self.hw = c, u, hl, hw

    @property
    def area(self):
        return 4 * self.hl * self.hw


def convex_hull(pts):
    p = sorted(pts)
    if len(p) < 3:
        return p
    lower, upper = [], []
    for q in p:
        while len(lower) >= 2 and _cross(_sub(lower[-1], lower[-2]), _sub(q, lower[-2])) <= 0:
            lower.pop()
        lower.append(q)
    for q in reversed(p):
        while len(upper) >= 2 and _cross(_sub(upper[-1], upper[-2]), _sub(q, upper[-2])) <= 0:
            upper.pop()
        upper.append(q)
    return lower[:-1] + upper[:-1]


def min_area_rect(ring):
    hull = convex_hull(ring)
    best, best_a = None, float("inf")
    for i in range(len(hull)):
        d = _sub(hull[(i + 1) % len(hull)], hull[i])
        ln = math.hypot(*d)
        if ln <= 1e-9:
            continue
        u = (d[0] / ln, d[1] / ln)
        v = (-u[1], u[0])
        ss = [p[0] * u[0] + p[1] * u[1] for p in hull]
        ts = [p[0] * v[0] + p[1] * v[1] for p in hull]
        a = (max(ss) - min(ss)) * (max(ts) - min(ts))
        if a < best_a - 1e-9:
            best_a = a
            sc, tc = (min(ss) + max(ss)) / 2, (min(ts) + max(ts)) / 2
            best = ORect((u[0] * sc + v[0] * tc, u[1] * sc + v[1] * tc), u, (max(ss) - min(ss)) / 2, (max(ts) - min(ts)) / 2)
    return best or ORect(ring[0] if ring else (0, 0), (1, 0), 0, 0)


def orthogonality(ring, u):
    total = aligned = 0.0
    tol = math.sin(math.radians(10))
    for i in range(len(ring)):
        d = _sub(ring[(i + 1) % len(ring)], ring[i])
        ln = math.hypot(*d)
        if ln <= 1e-9:
            continue
        c = abs(_cross(u, (d[0] / ln, d[1] / ln)))
        s = abs(u[0] * d[0] / ln + u[1] * d[1] / ln)
        if c < tol or s < tol:
            aligned += ln
        total += ln
    return aligned / total if total > 0 else 0


def decompose(ring, fr):
    v = (-fr.u[1], fr.u[0])
    local = [((p[0] - fr.c[0]) * fr.u[0] + (p[1] - fr.c[1]) * fr.u[1],
              (p[0] - fr.c[0]) * v[0] + (p[1] - fr.c[1]) * v[1]) for p in ring]

    def clusters(vals):
        out = []
        for x in sorted(vals):
            if out and x - out[-1] < 0.35:
                continue
            out.append(x)
        return out

    xs, ys = clusters([p[0] for p in local]), clusters([p[1] for p in local])
    if not (2 <= len(xs) <= 24 and 2 <= len(ys) <= 24):
        return None
    nx, ny = len(xs) - 1, len(ys) - 1
    inside = [[ring_contains(local, ((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2)) for j in range(ny)] for i in range(nx)]
    roofs, flats = [], []
    while True:
        best = None
        for i0 in range(nx):
            for j0 in range(ny):
                if not inside[i0][j0]:
                    continue
                max_j = ny - 1
                for i1 in range(i0, nx):
                    if not inside[i1][j0]:
                        break
                    j1 = j0
                    while j1 + 1 <= max_j and inside[i1][j1 + 1]:
                        j1 += 1
                    max_j = j1
                    a = (xs[i1 + 1] - xs[i0]) * (ys[j1 + 1] - ys[j0])
                    if a > (best[4] if best else 0):
                        best = (i0, i1, j0, j1, a)
        if best is None:
            break
        i0, i1, j0, j1, a = best
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                inside[i][j] = False
        hl, hw = (xs[i1 + 1] - xs[i0]) / 2, (ys[j1 + 1] - ys[j0]) / 2
        rect = ORect((0, 0), fr.u, hl, hw)
        if a >= 6 and len(roofs) < 6:
            roofs.append(rect)
        elif a >= 0.5:
            flats.append(rect)
    return roofs, flats


class Footprint:
    def __init__(self, outer, holes):
        area = abs(ring_area(outer)) - sum(abs(ring_area(h)) for h in holes)
        self.area = area
        self.obb = min_area_rect(outer)
        self.rect = area / self.obb.area if self.obb.area > 0 else 0
        self.orth = orthogonality(outer, self.obb.u)
        self.roof_rects, self.flat_rects = [], []
        if area < 12.0:
            self.kind = "tiny"
        elif holes:
            self.kind = "irregular"
        elif self.rect >= 0.9:
            self.kind = "rectangle"
            self.roof_rects = [self.obb]
        else:
            dec = decompose(outer, self.obb) if self.orth >= 0.85 else None
            if dec and dec[0]:
                self.kind = "orthogonal"
                self.roof_rects, self.flat_rects = dec
            elif self.rect >= 0.75 and area <= 400.0:
                self.kind = "nearRectangle"
                self.roof_rects = [self.obb]
            else:
                self.kind = "irregular"


# ---------------------------------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------------------------------

def load_profile(path):
    with open(path) as f:
        p = json.load(f)
    p["_types"] = {t["id"]: t for t in p["houseTypes"]}
    return p


def _parse_num(raw):
    if raw is None:
        return None
    try:
        n = float(str(raw).split(";")[0].strip().replace(",", "."))
    except ValueError:
        return None
    return n if 0 <= n <= 500 else None


# ---------------------------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------------------------

HOUSE_TYPES = {"house", "detached", "semidetached_house", "bungalow", "residential", "terrace", "cabin"}
GARAGE_TYPES = {"garage", "garages", "carport"}
SHED_TYPES = {"shed", "hut", "kiosk", "toilets"}
METERS_PER_LEVEL = 3.2


def role_of(btype, area):
    if btype in GARAGE_TYPES:
        return "garage"
    if btype in SHED_TYPES or area < 12.0:
        return "shed"
    if btype in HOUSE_TYPES or (btype == "yes" and area < 250):
        return "house"
    return "block"


def _edges(ring):
    out = []
    n = len(ring)
    for i in range(n):
        p, q = ring[i], ring[(i + 1) % n]
        d = _sub(q, p)
        ln = math.hypot(*d)
        out.append((p, (d[0] / ln, d[1] / ln) if ln > 0 else (1, 0), ln))
    return out


def guess_front_edge(ring, fp):
    """Stand-in for StreetContext.frontEdge (needs streets): narrow deep footprints (aspect >= 2.2,
    urban lots) face the street with a short side, others with a long side. Edges < 2.5 m ignored."""
    o = fp.obb
    aspect = o.hl / o.hw if o.hw > 0 else 1
    best, best_len = None, 0
    for i, (_, d, ln) in enumerate(_edges(ring)):
        if ln < 2.5:
            continue
        along_u = abs(d[0] * o.u[0] + d[1] * o.u[1]) > 0.85
        want = (not along_u) if aspect >= 2.2 else along_u
        if want and ln > best_len:
            best, best_len = i, ln
    if best is None:
        lens = [ln for (_, _, ln) in _edges(ring)]
        best = max(range(len(ring)), key=lambda i: lens[i])
    return best


def building_tris(ref, tags, outer, holes, profile, detail, floors_policy="engine"):
    """Triangles the generator emits for one building polygon. Returns a dict breakdown.

    floors_policy "engine": floors = OSM levels, else the chosen type's first floor count
    (BuildingGenerator); "height": like engine, but untagged levels with a height tag become
    round(height / 3.2) (a possible estimator, for comparison only)."""
    from audit import parse_length
    btype = tags.get("building") or tags.get("building:part") or "yes"
    fp = Footprint(outer, holes)
    role = role_of(btype, fp.area)
    ring = outer
    edges = _edges(ring)
    front = guess_front_edge(ring, fp) if role in ("house", "block", "shed") else None
    garage_edge = guess_front_edge(ring, fp) if role == "garage" else None
    levels = _parse_num(tags.get("building:levels"))
    osm_levels = max(1, int(round(levels))) if levels and levels > 0 else None
    h_tag = parse_length(tags.get("height"))

    # House type (BuildingGenerator.houseType) ---------------------------------------------
    types = profile["houseTypes"]
    ttype = None
    if role == "house":
        o = fp.obb
        aspect = o.hl / o.hw if o.hw > 0 else 1
        broad = False
        if front is not None:
            d = edges[front][1]
            broad = abs(d[0] * o.u[0] + d[1] * o.u[1]) > 0.85
        th = profile["typeThresholds"]
        if btype == "semidetached_house":
            key = "semidetached"
        elif osm_levels:
            if osm_levels == 1:
                key = "oneFloorBroad" if aspect >= th["broadAspect"] and broad else "oneFloor"
            elif osm_levels == 2:
                if aspect <= th["squareAspect"] and fp.rect >= th["squareRectangularity"]:
                    key = "twoFloorSquare"
                else:
                    key = "twoFloorNarrow" if aspect >= th["narrowAspect"] else "twoFloor"
            else:
                key = "threeFloor"
        elif fp.area < th["smallArea"]:
            key = "small"
        elif fp.area > th["largeArea"]:
            key = "large"
        else:
            key = "unknown"
        rules = profile["typeRules"]
        weights = rules.get(key) or rules.get("unknown") or {}
        weights = {k: v for k, v in weights.items() if isinstance(v, (int, float))}

        def eligible(t):
            if osm_levels and osm_levels not in t["floors"]:
                return False
            if t.get("minAspect") is not None and aspect < t["minAspect"]:
                return False
            if t.get("maxAspect") is not None and aspect > t["maxAspect"]:
                return False
            if t.get("minRectangularity") is not None and fp.rect < t["minRectangularity"]:
                return False
            if t.get("broadFrontage") is True and not broad:
                return False
            return True

        allc = [(profile["_types"][k], weights[k]) for k in sorted(weights) if k in profile["_types"]]
        cand = [c for c in allc if eligible(c[0])]
        r = ref_random(ref, "house-type")
        ttype = r.pick(cand if cand else allc, lambda c: c[1])[0]
    elif role == "block":
        ttype = next((t for t in types if t["roof"]["flat"] >= 1), types[-1])

    rng = ref_random(ref, "building")
    rng.unit()  # wall shade
    rng.unit()  # roof shade
    # Roof shape
    if role == "garage":
        mix = profile["garage"].get("roof") or {"gabled": 1, "hipped": 0, "flat": 0}
    elif role == "shed":
        mix = {"gabled": 0, "hipped": 0, "flat": 1}
    else:
        mix = ttype["roof"] if ttype else {"gabled": 0, "hipped": 0, "flat": 1}
    rs = tags.get("roof:shape")
    if rs in ("gabled", "saltbox", "gambrel", "mansard"):
        roof = "gabled"
    elif rs in ("hipped", "pyramidal", "half-hipped", "side_hipped"):
        roof = "hipped"
    elif rs == "flat":
        roof = "flat"
    elif rs == "skillion":
        roof = "slab"
    else:
        r = ref_random(ref, "roof-shape")
        roof = r.pick([("gabled", mix["gabled"]), ("hipped", mix["hipped"]), ("flat", mix["flat"])], lambda c: c[1])[0]
    if role == "shed" or fp.kind == "tiny":
        roof = "slab"
    elif fp.kind == "irregular":
        roof = "flat"
    if roof in ("gabled", "hipped") and not fp.roof_rects:
        roof = "flat"
    pitched = roof in ("gabled", "hipped")

    if role == "garage":
        pitch_r, over_r = profile["garage"]["pitch"], profile["garage"]["overhang"]
    elif role == "shed":
        pitch_r, over_r = profile["shed"]["pitch"], profile["shed"]["overhang"]
    else:
        pitch_r = ttype["pitch"] if ttype else [20, 30]
        over_r = ttype["overhang"] if ttype else [0.3, 0.5]
    pitch = rng.rangel(pitch_r)
    overhang = rng.rangel(over_r)
    if role == "house":
        F = rng.rangel(profile["foundationMeters"])
    else:
        F = {"garage": 0.12, "shed": 0.05, "block": 0.3}[role]
    main = max(fp.roof_rects, key=lambda r_: r_.area) if fp.roof_rects else fp.obb
    rise = main.hw * math.tan(math.radians(pitch)) if pitched else 0.0
    floors = 1
    if role == "garage":
        H = osm_levels * 2.9 if osm_levels else rng.rangel(profile["garage"]["wallHeight"])
    elif role == "shed":
        H = rng.rangel(profile["shed"]["wallHeight"])
    else:
        if osm_levels:
            floors = osm_levels
        elif floors_policy == "height" and h_tag:
            floors = max(1, int(round(h_tag / METERS_PER_LEVEL)))
        else:
            floors = ttype["floors"][0] if ttype else 1
        per_floor = rng.rangel(ttype.get("perFloor", [3.0, 3.2]) if ttype else [3.0, 3.2])
        if h_tag is not None:
            H = max(F + 2.6, h_tag - rise)
        else:
            H = F + floors * per_floor
    parapet = rng.rangel((ttype or {}).get("parapet") or [0.3, 0.4]) if (roof == "flat" and role != "shed") else 0.0
    full = detail == "full"

    out = Counter()
    rings = [outer] + list(holes)
    nedges = sum(sum(1 for (_, _, ln) in _edges(rg) if ln > 1e-6) for rg in rings)
    # Walls.
    top = H + parapet
    z0 = F if full else 0
    if full and F > 0.05:
        out["walls"] += 2 * nedges
    if full and pitched and top - z0 > 1.2:
        out["walls"] += 4 * nedges
    else:
        out["walls"] += 2 * nedges
    # Roof.
    if roof == "gabled":
        out["roof"] += 30 * len(fp.roof_rects)
    elif roof == "hipped":
        out["roof"] += sum(22 if r_.hl - r_.hw > 0.01 else 20 for r_ in fp.roof_rects)
    elif roof == "flat":
        nv = sum(len(rg) for rg in rings)
        out["roof"] += max(0, nv - 2 + 2 * len(holes))
        if parapet > 0:
            out["roof"] += 2 * nedges
    else:
        out["roof"] += 12
    if pitched:
        out["roof"] += 12 * len(fp.flat_rects)

    windows = 0
    if full:
        orng = ref_random(ref, "openings")
        win = (ttype or {}).get("windows") or {"bay": [2.8, 3.2], "width": [0.9, 1.2], "height": [1.2, 1.5], "broad": None}
        bay = orng.rangel(win["bay"])
        win_w = orng.rangel(win["width"])
        win_h = orng.rangel(win["height"])
        stories = 1 if role == "garage" else max(1, floors)
        story_h = (H - F) / stories
        door_span = None
        if role in ("house", "block") and front is not None:
            p, d, ln = edges[front]
            dr = ref_random(ref, "door")
            door_at = dr.pick(ttype["door"], lambda _: 1) if ttype else 0.5
            door_s = min(ln - 0.7, max(0.7, ln * door_at))
            porch = (ttype or {}).get("porch")
            style = porch["style"] if porch else "canopy"
            wants = dr.chance(porch["likelihood"] if porch else 0.3) and ln >= 3.5
            out["door"] += 4
            steps = max(1, int(round(F / 0.18))) * 10 if F > 0.12 else 0
            if wants and style == "covered":
                depth = dr.rangel(porch["depth"])
                width = min(ln - 0.4, max(2.4, ln * dr.rangel(porch["frontage"])))
                s0 = max(0.2, min(ln - 0.2 - width, door_s - width / 2))
                door_span = (front, s0 - 0.3, s0 + width + 0.3)
                out["porch"] += 10 + 20 + 12
                out["steps"] += steps
            else:
                door_span = (front, door_s - 1.0, door_s + 1.0)
                if porch:
                    dr.rangel(porch["depth"])
                out["porch"] += 10 + (12 if (wants or style == "canopy") else 0)
                out["steps"] += steps
        if role == "garage" and garage_edge is not None:
            out["door"] += 10
        if role == "shed" and front is not None and edges[front][2] >= 1.2:
            out["door"] += 2
        do_windows = role in ("house", "block") or (role == "garage" and orng.chance(0.4))
        if do_windows:
            for e, (p, d, ln) in enumerate(edges):
                if role == "garage" and e == garage_edge:
                    continue
                is_front = e == front
                bay_here = bay if is_front else bay * (2.5 if role == "garage" else 1.7)
                if ln < 2.0:
                    continue
                if ln < 3.0:
                    count = 1 if orng.chance(0.5) else 0
                else:
                    count = max(1, int(ln / bay_here))
                if role == "garage":
                    count = min(count, 1)
                if count <= 0:
                    continue
                for story in range(stories):
                    zz0 = F + story * story_h + (0.85 if story == 0 else 0.8)
                    zz1 = min(zz0 + win_h, F + (story + 1) * story_h - 0.35, H - 0.3)
                    if zz1 - zz0 <= 0.6:
                        continue
                    widths = [win_w] * count
                    if is_front and story == 0 and win.get("broad") and count >= 2:
                        widths[0] = orng.rangel(win["broad"])
                    while widths and sum(widths) + (len(widths) - 1) * 0.35 > ln - 0.9:
                        widths.pop()
                    if not widths:
                        continue
                    step = (ln - 0.9) / len(widths)
                    for k, w in enumerate(widths):
                        sc = 0.45 + step * (k + 0.5)
                        if story == 0 and door_span and door_span[0] == e and sc + w / 2 > door_span[1] and sc - w / 2 < door_span[2]:
                            continue
                        if min(w, step - 0.35) > 0.4:
                            windows += 1
        out["windows"] += 12 * windows
        if role == "house" and pitched:
            cr = ref_random(ref, "chimney")
            if cr.chance(profile["chimneyLikelihood"]):
                out["chimney"] += 10
        out["skirt"] += 2 * sum(1 for (_, _, ln) in edges if ln > 0.05)
    bushes = 0
    if full and role in ("house", "block") and front is not None and door_span:
        p, d, ln = edges[front]
        br = ref_random(ref, "bushes")
        s = 0.8
        while s < ln - 0.6:
            if not (door_span[1] - 0.5 < s < door_span[2] + 0.5) and br.chance(0.7):
                bushes += 1
            s += br.range(1.5, 2.3)
    return {"role": role, "roof": roof, "floors": floors, "floorsFromOSM": osm_levels is not None, "H": H,
            "windows": windows, "bushes": bushes, "parts": dict(out), "total": sum(out.values()),
            "type": ttype["id"] if ttype else None, "kind": fp.kind}


# ---------------------------------------------------------------------------------------------
# Props (WorldGen/Props.swift): triangles per mesh
# ---------------------------------------------------------------------------------------------

def _cyl(sides, cap=True):
    return 2 * sides + (sides - 2 if cap else 0)


def _branches(lobes, lod):
    """Phase 5A crown branches (Props.deciduous): one limb per lobe (3 at lod 2), 5 sides at lod 0
    and 3 otherwise; two 3-sided twigs per limb at lod 0. addBranch = 2 triangles per side."""
    limbs = min(3, lobes) if lod == 2 else lobes
    return limbs * 2 * (5 if lod == 0 else 3) + (limbs * 2 * 2 * 3 if lod == 0 else 0)


TREE_TRIS = {  # kind: (near, mid, far); deciduous crowns: broad/oval 4 lobes, spreading 5
    "treeBroad": (_cyl(7, False) + _branches(4, 0) + 4 * 80, _cyl(5, False) + _branches(4, 1) + 2 * 80, _cyl(3, False) + _branches(4, 2) + 8),
    "treeOval": (_cyl(7, False) + _branches(4, 0) + 4 * 80, _cyl(5, False) + _branches(4, 1) + 2 * 80, _cyl(3, False) + _branches(4, 2) + 8),
    "treeSpreading": (_cyl(7, False) + _branches(5, 0) + 5 * 80, _cyl(5, False) + _branches(5, 1) + 2 * 80, _cyl(3, False) + _branches(5, 2) + 8),
    "conifer": (_cyl(6, False) + 3 * (10 + 8), _cyl(3, False) + 3 * (7 + 5), _cyl(3, False) + (5 + 3)),
}
# Before phase 5A (commit b76580c): broad/oval 334/170/14, spreading 434/186/14 (two branches only
# on spreading crowns at lod 0-1). Kept for the record of the earlier estimate.
TREE_TRIS_PRE_5A = {"treeBroad": (334, 170, 14), "treeOval": (334, 170, 14), "treeSpreading": (434, 186, 14),
                    "conifer": TREE_TRIS["conifer"]}
BUSH_TRIS = (80, 20, 8)
LAMP_TRIS = 3 * _cyl(8) + _cyl(8) + (8 + 6)  # base, pole, ring, glow, cone = 102
BENCH_TRIS = 6 * 12  # seat, back, four legs (boxes of 6 quads) = 72
TUFT_TRIS = 17       # World.swift counts clutter at 17 triangles per tuft, up to 200 tufts
LOD_DISTANCES = (45.0, 160.0)


def tree_mix(profile, table=None):
    """Average triangles per tree at each LOD for a profile's species/crown mix."""
    table = table or TREE_TRIS
    t = profile["trees"]
    dec = t["deciduousShare"]
    cw = t["crownWeights"]
    tot = sum(cw.values())
    out = []
    for lod in range(3):
        d = sum(cw[k] / tot * table[{"broad": "treeBroad", "oval": "treeOval", "spreading": "treeSpreading"}[k]][lod] for k in cw)
        out.append(dec * d + (1 - dec) * table["conifer"][lod])
    return out


# ---------------------------------------------------------------------------------------------
# Ground (SceneGenerator / Streetscape / Primitives counting)
# ---------------------------------------------------------------------------------------------

VEHICULAR = {"motorway", "trunk", "primary", "secondary", "tertiary", "unclassified", "residential",
             "living_street", "service", "road", "busway", "track"}
STREET = {"residential", "living_street", "unclassified", "tertiary", "secondary", "primary", "trunk"}
LAMP_ROADS = {"residential", "living_street", "unclassified", "tertiary"}
DEFAULT_WIDTH = {"motorway": 14, "trunk": 13, "primary": 12, "secondary": 10, "tertiary": 8, "residential": 6,
                 "unclassified": 6, "living_street": 5, "road": 6, "busway": 6, "service": 4, "track": 3,
                 "pedestrian": 4, "cycleway": 2.5, "footway": 2, "path": 2, "bridleway": 2.5, "steps": 2,
                 "corridor": 2}


def hw_kind(tag):
    base = tag[:-5] if tag.endswith("_link") else tag
    return base if base in DEFAULT_WIDTH else "other"


def road_width(kind, tags):
    from audit import parse_length
    w = parse_length(tags.get("width"))
    if w is not None and w <= 60:
        return w
    if kind in VEHICULAR:
        try:
            lanes = int(str(tags.get("lanes", "")).split(";")[0])
        except ValueError:
            lanes = 0
        if 0 < lanes < 12:
            return lanes * 3.3
    return DEFAULT_WIDTH.get(kind, 3)


def clip_segment(p0, p1, r):
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    t0, t1 = 0.0, 1.0
    for p, q in ((-dx, p0[0] - r[0]), (dx, r[2] - p0[0]), (-dy, p0[1] - r[1]), (dy, r[3] - p0[1])):
        if p == 0:
            if q < 0:
                return None
        else:
            t = q / p
            if p < 0:
                if t > t1:
                    return None
                t0 = max(t0, t)
            else:
                if t < t0:
                    return None
                t1 = min(t1, t)
    return ((p0[0] + dx * t0, p0[1] + dy * t0), (p0[0] + dx * t1, p0[1] + dy * t1))


def clip_polyline(line, r):
    pieces, cur = [], []
    for i in range(len(line) - 1):
        s = clip_segment(line[i], line[i + 1], r)
        if s is None:
            if len(cur) >= 2:
                pieces.append(cur)
            cur = []
            continue
        a, b = s
        if cur and cur[-1] == a:
            cur.append(b)
        else:
            if len(cur) >= 2:
                pieces.append(cur)
            cur = [a, b]
    if len(cur) >= 2:
        pieces.append(cur)
    return pieces


def clip_ring(ring, r):
    """Sutherland-Hodgman clip of a ring to rect r = (x0, y0, x1, y1)."""
    def clip(pts, inside, inter):
        out = []
        for i in range(len(pts)):
            a, b = pts[i - 1], pts[i]
            ia, ib = inside(a), inside(b)
            if ib:
                if not ia:
                    out.append(inter(a, b))
                out.append(b)
            elif ia:
                out.append(inter(a, b))
        return out

    def ix(x):
        return lambda a, b: (x, a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]))

    def iy(y):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]), y)

    pts = ring
    for inside, inter in ((lambda p: p[0] >= r[0], ix(r[0])), (lambda p: p[0] <= r[2], ix(r[2])),
                          (lambda p: p[1] >= r[1], iy(r[1])), (lambda p: p[1] <= r[3], iy(r[3]))):
        if not pts:
            break
        pts = clip(pts, inside, inter)
    return pts


class SegIndex:
    def __init__(self, lines, cell=40.0):
        self.cell = cell
        self.b = defaultdict(list)
        for li, line in enumerate(lines):
            for a, c in zip(line, line[1:]):
                if a == c:
                    continue
                for x in range(int(math.floor(min(a[0], c[0]) / cell)), int(math.floor(max(a[0], c[0]) / cell)) + 1):
                    for y in range(int(math.floor(min(a[1], c[1]) / cell)), int(math.floor(max(a[1], c[1]) / cell)) + 1):
                        self.b[(x, y)].append((li, a, c))

    def nearest(self, p, radius, include=None):
        best = None
        r = int(math.ceil(radius / self.cell))
        kx, ky = int(math.floor(p[0] / self.cell)), int(math.floor(p[1] / self.cell))
        for x in range(kx - r, kx + r + 1):
            for y in range(ky - r, ky + r + 1):
                for li, a, c in self.b.get((x, y), ()):
                    if include and not include(li):
                        continue
                    dx, dy = c[0] - a[0], c[1] - a[1]
                    l2 = dx * dx + dy * dy
                    t = min(1, max(0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / l2)) if l2 > 0 else 0
                    q = (a[0] + dx * t, a[1] + dy * t)
                    dist = math.dist(p, q)
                    if dist <= radius and (best is None or dist < best[1]):
                        best = (li, dist, q, (dx / math.sqrt(l2), dy / math.sqrt(l2)) if l2 > 0 else (1, 0))
        return best


def offset_line(l, d):
    if len(l) < 2:
        return l

    def n(k):
        vx, vy = l[k + 1][0] - l[k][0], l[k + 1][1] - l[k][1]
        ln = math.hypot(vx, vy) or 1
        return (-vy / ln, vx / ln)
    out = []
    for i in range(len(l)):
        if i == 0:
            nn = n(0)
            out.append((l[0][0] + nn[0] * d, l[0][1] + nn[1] * d))
        elif i == len(l) - 1:
            nn = n(i - 1)
            out.append((l[i][0] + nn[0] * d, l[i][1] + nn[1] * d))
        else:
            a, b = n(i - 1), n(i)
            m = (a[0] + b[0], a[1] + b[1])
            ln = math.hypot(*m)
            if ln < 1e-6:
                out.append((l[i][0] + b[0] * d, l[i][1] + b[1] * d))
                continue
            mu = (m[0] / ln, m[1] / ln)
            scale = min(2.5, 1 / max(0.2, mu[0] * b[0] + mu[1] * b[1]))
            out.append((l[i][0] + mu[0] * d * scale, l[i][1] + mu[1] * d * scale))
    return out


def resample(l, step):
    out = []
    for a, b in zip(l, l[1:]):
        dx, dy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dy)
        if ln <= 1e-6:
            continue
        n = max(1, int(math.ceil(ln / step)))
        for k in range(n):
            out.append(((a[0] + dx * k / n, a[1] + dy * k / n), (dx / ln, dy / ln)))
    if len(l) >= 2:
        dx, dy = l[-1][0] - l[-2][0], l[-1][1] - l[-2][1]
        ln = math.hypot(dx, dy) or 1
        out.append((l[-1], (dx / ln, dy / ln)))
    return out


def runs(points, keep, min_len):
    out, cur = [], []

    def length(c):
        return sum(math.dist(a, b) for a, b in zip(c, c[1:]))
    for p, k in zip(points, keep):
        if k:
            cur.append(p)
        else:
            if len(cur) >= 2 and length(cur) >= min_len:
                out.append(cur)
            cur = []
    if len(cur) >= 2 and length(cur) >= min_len:
        out.append(cur)
    return out


class BuildingIndex:
    def __init__(self, polys, cell=25.0):
        self.cell = cell
        self.polys = polys
        self.b = defaultdict(list)
        for i, ring in enumerate(polys):
            xs, ys = [p[0] for p in ring], [p[1] for p in ring]
            self_b = (min(xs), min(ys), max(xs), max(ys))
            for x in range(int(math.floor(self_b[0] / cell)), int(math.floor(self_b[2] / cell)) + 1):
                for y in range(int(math.floor(self_b[1] / cell)), int(math.floor(self_b[3] / cell)) + 1):
                    self.b[(x, y)].append((i, self_b))

    def contains(self, p, margin=0.0):
        for i, bb in self.b.get((int(math.floor(p[0] / self.cell)), int(math.floor(p[1] / self.cell))), ()):
            if not (bb[0] - margin <= p[0] <= bb[2] + margin and bb[1] - margin <= p[1] <= bb[3] + margin):
                continue
            ring = self.polys[i]
            if ring_contains(ring, p):
                return True
            if margin > 0:
                for j in range(len(ring)):
                    a, c = ring[j], ring[(j + 1) % len(ring)]
                    dx, dy = c[0] - a[0], c[1] - a[1]
                    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / max(dx * dx + dy * dy, 1e-12)))
                    if math.dist(p, (a[0] + dx * t, a[1] + dy * t)) < margin:
                        return True
        return False


def sidewalk_states(t):
    def st(v):
        if v is None:
            return None
        if v in ("no", "none"):
            return "none"
        if v == "separate":
            return "separate"
        return "tagged"
    left = right = "unknown"
    s = t.get("sidewalk")
    if s in ("both", "yes"):
        left = right = "tagged"
    elif s == "left":
        left, right = "tagged", "none"
    elif s == "right":
        left, right = "none", "tagged"
    elif s in ("no", "none"):
        left = right = "none"
    elif s == "separate":
        left = right = "separate"
    b = st(t.get("sidewalk:both"))
    if b:
        left = right = b
    if st(t.get("sidewalk:left")):
        left = st(t.get("sidewalk:left"))
    if st(t.get("sidewalk:right")):
        right = st(t.get("sidewalk:right"))
    return left, right


def ground_tris(roads, paths, sidewalks, areas, buildings_rings, bounds, focus, chunk=200.0, lod=0, lamp_spots=()):
    """Static non-building triangles per chunk. roads/paths/sidewalks: dicts with kind, tags,
    width, line (already clipped to bounds). areas: (kind, outer, holes) already in bounds."""
    nx = int(math.ceil((bounds[2] - bounds[0]) / chunk))
    ny = int(math.ceil((bounds[3] - bounds[1]) / chunk))
    chunks = {}
    for i in range(nx):
        for j in range(ny):
            chunks[(i, j)] = (bounds[0] + i * chunk, bounds[1] + j * chunk,
                              min(bounds[2], bounds[0] + (i + 1) * chunk), min(bounds[3], bounds[1] + (j + 1) * chunk))
    tri = Counter()

    def key_of(p):
        return (int(math.floor((p[0] - bounds[0]) / chunk)), int(math.floor((p[1] - bounds[1]) / chunk)))

    def lines(line, width, label):
        for k, r in chunks.items():
            for piece in clip_polyline(line, r):
                tri[(k, label)] += 2 * (len(piece) - 1)

    for k in chunks:
        tri[(k, "ground")] += 2
    for kind, outer, holes in areas:
        style = kind in ("park", "grass", "garden", "meadow", "recreation", "cemetery", "wood", "scrub", "pitch",
                         "playground", "sand", "parking", "pedestrianArea", "water", "pool")
        if not style:
            continue
        for k, r in chunks.items():
            o = clip_ring(outer, r)
            if len(o) < 3 or abs(ring_area(o)) < 0.2:
                continue
            hs = [clip_ring(h, r) for h in holes]
            hs = [h for h in hs if len(h) >= 3]
            tri[(k, "water" if kind in ("water", "pool") else "areas")] += len(o) + sum(len(h) for h in hs) - 2 + 2 * len(hs)
        if kind == "water":
            for rg in [outer] + list(holes):
                lines(rg + [rg[0]], 1.6, "shore")
    for rd in roads:
        lines(rd["line"], rd["width"], "roads")
    for p in paths:
        lines(p["line"], max(1.6, p["width"]), "paths")
    for sw in sidewalks:
        lines(sw["line"], 1.6, "sidewalks")
        xs, ys = [q[0] for q in sw["line"]], [q[1] for q in sw["line"]]
        if lod == 0 and not (max(xs) < focus[0] or min(xs) > focus[2] or max(ys) < focus[1] or min(ys) > focus[3]):
            k = key_of(sw["line"][0])
            if k in chunks:
                tri[(k, "sidewalkEdges")] += 8 * (len(sw["line"]) - 1)
    # Streetscape in the focus region.
    road_idx = SegIndex([r["line"] for r in roads])
    sw_idx = SegIndex([s["line"] for s in sidewalks])
    bidx = BuildingIndex(buildings_rings)

    def blocked(p, own, extra):
        hit = road_idx.nearest(p, 12 + extra, include=lambda li: li != own)
        return hit is not None and hit[1] < roads[hit[0]]["width"] / 2 + extra

    lamps = 0
    spot_grid = defaultdict(list)

    def add_spot(q):
        spot_grid[(int(math.floor(q[0] / 20)), int(math.floor(q[1] / 20)))].append(q)

    def spots_near(q):
        kx, ky = int(math.floor(q[0] / 20)), int(math.floor(q[1] / 20))
        for x in (kx - 1, kx, kx + 1):
            for y in (ky - 1, ky, ky + 1):
                yield from spot_grid.get((x, y), ())
    for q in lamp_spots:
        add_spot(q)
    for i, rd in enumerate(roads):
        for piece in clip_polyline(rd["line"], focus):
            if rd["kind"] in STREET and lod == 0:
                for side in (-1.0, 1.0):
                    edge = offset_line(piece, side * rd["width"] / 2)
                    samples = [s[0] for s in resample(edge, 1.0)]
                    keep = [not blocked(s, i, 0.6) for s in samples]
                    for run in runs(samples, keep, 2):
                        k = key_of(run[0])
                        if k in chunks:
                            tri[(k, "curbs")] += 6 * (len(run) - 1)
            if rd["kind"] in STREET and rd["kind"] not in ("primary", "trunk"):
                left, right = sidewalk_states(rd["tags"])
                for side, state in ((1.0, left), (-1.0, right)):
                    if state in ("none", "separate"):
                        continue
                    line = offset_line(piece, side * (rd["width"] / 2 + 2.2))
                    samples = resample(line, 2.0)
                    keep = []
                    for p, d in samples:
                        if blocked(p, i, 2.0) or bidx.contains(p, 0.5):
                            keep.append(False)
                            continue
                        if state == "tagged":
                            keep.append(True)
                            continue
                        rp = road_idx.nearest(p, rd["width"] + 10, include=lambda li, i=i: li == i)
                        if rp is None:
                            keep.append(True)
                            continue
                        hit = sw_idx.nearest(p, 15.0)
                        if hit and abs(hit[3][0] * d[0] + hit[3][1] * d[1]) > 0.7 and \
                                (hit[2][0] - rp[2][0]) * (p[0] - rp[2][0]) + (hit[2][1] - rp[2][1]) * (p[1] - rp[2][1]) > 0:
                            keep.append(False)
                        else:
                            keep.append(True)
                    for run in runs([s[0] for s in samples], keep, 8):
                        lines(run, 1.5, "genSidewalks")
                        if lod == 0:
                            k = key_of(run[0])
                            if k in chunks:
                                tri[(k, "sidewalkEdges")] += 8 * (len(run) - 1)
            if rd["kind"] in LAMP_ROADS and rd["tags"].get("name"):
                # Streetscape.generatedLamps (exact port): every 38 m, alternating sides, skipped
                # near other roads, inside/near buildings or within 20 m of another lamp.
                rng = ref_random(rd["ref"], "lamps")
                along = rng.range(0, 38.0 / 2)
                side = 1.0 if rng.chance(0.5) else -1.0
                samples = resample(piece, 1.0)
                traveled = 0.0
                for k in range(1, max(1, len(samples))):
                    traveled += math.dist(samples[k - 1][0], samples[k][0])
                    if traveled < along:
                        continue
                    p, d = samples[k]
                    nrm = (-d[1] * side, d[0] * side)
                    spot = (p[0] + nrm[0] * (rd["width"] / 2 + 0.7), p[1] + nrm[1] * (rd["width"] / 2 + 0.7))
                    ok = (not blocked(p, i, 9)) and (not bidx.contains(spot, 1.0)) and \
                        not any(math.dist(e, spot) < 20 for e in spots_near(spot))
                    if ok:
                        add_spot(spot)
                        lamps += 1
                        along = traveled + 38.0
                        side = -side
                    else:
                        along = traveled + 4
    return chunks, tri, lamps
