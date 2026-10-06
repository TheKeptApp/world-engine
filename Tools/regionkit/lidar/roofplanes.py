"""Pure functions of the lidar roof-form pilot (numpy + scipy, no I/O, no network).

Unit-tested offline in tests/test_roofplanes.py. Conventions:
- local coordinates are metres east (x), north (y), up (z) on the WGS84 tangent plane at the area centre;
- a "plane" is a dict with plan `area` (m^2, horizontal projection), `pitch` (degrees from horizontal),
  `aspect` (azimuth of the downhill direction, degrees clockwise from north), and its plan centroid `cx`, `cy`;
- a roof "raster" is a set of 0.5 m cells inside the eroded footprint, each labelled with a plane id or -1.
Both sides of the comparison (lidar points and generated meshes) go through the same raster and the same
`classify_roof`, so the categories mean the same thing on both sides.
"""

import hashlib
import math

import numpy as np

R_MERC = 6378137.0
A_WGS, F_WGS = 6378137.0, 1 / 298.257223563
E2_WGS = F_WGS * (2 - F_WGS)
FORMS = ("flat", "gable", "hip", "complex")
SIMPLE = ("flat", "gable", "hip")

# ---------------------------------------------------------------- coordinates


def lonlat_to_merc(lon, lat):
    """WGS84 lon/lat (degrees) -> EPSG:3857 metres."""
    lon, lat = np.asarray(lon, float), np.asarray(lat, float)
    return R_MERC * np.radians(lon), R_MERC * np.log(np.tan(math.pi / 4 + np.radians(lat) / 2))


def merc_to_lonlat(x, y):
    """EPSG:3857 metres -> WGS84 lon/lat (degrees)."""
    x, y = np.asarray(x, float), np.asarray(y, float)
    return np.degrees(x / R_MERC), np.degrees(2 * np.arctan(np.exp(y / R_MERC)) - math.pi / 2)


def _ecef(lat, lon):
    la, lo = np.radians(lat), np.radians(lon)
    n = A_WGS / np.sqrt(1 - E2_WGS * np.sin(la) ** 2)
    return np.stack([n * np.cos(la) * np.cos(lo), n * np.cos(la) * np.sin(lo), n * (1 - E2_WGS) * np.sin(la)], axis=-1)


def local_en(lat0, lon0, lat, lon):
    """Exact WGS84 east/north (m) of lat/lon arrays relative to (lat0, lon0) (as the engine's LocalFrame)."""
    d = _ecef(np.asarray(lat, float), np.asarray(lon, float)) - _ecef(np.array(lat0, float), np.array(lon0, float))
    sl, cl = math.sin(math.radians(lat0)), math.cos(math.radians(lat0))
    so, co = math.sin(math.radians(lon0)), math.cos(math.radians(lon0))
    e = -so * d[..., 0] + co * d[..., 1]
    n = -sl * co * d[..., 0] - sl * so * d[..., 1] + cl * d[..., 2]
    return e, n


def local_to_latlon(lat0, lon0, e, n, iterations=5):
    """Inverse of local_en by fixed-point refinement (sub-millimetre within a few km)."""
    e, n = np.asarray(e, float), np.asarray(n, float)
    lat, lon = np.full(e.shape, float(lat0)), np.full(e.shape, float(lon0))
    for _ in range(iterations):
        ce, cn = local_en(lat0, lon0, lat, lon)
        sl = np.sin(np.radians(lat))
        m = A_WGS * (1 - E2_WGS) / (1 - E2_WGS * sl * sl) ** 1.5
        nn = A_WGS / np.sqrt(1 - E2_WGS * sl * sl)
        lat = lat + np.degrees((n - cn) / m)
        lon = lon + np.degrees((e - ce) / (nn * np.cos(np.radians(lat))))
    return lat, lon


# ---------------------------------------------------------------- EPT octree


def ept_node_bounds(root, key):
    """Cube bounds [xmin, ymin, zmin, xmax, ymax, zmax] of EPT node `key` = "D-X-Y-Z" in a root cube."""
    d, x, y, z = (int(v) for v in key.split("-"))
    size = [(root[3 + i] - root[i]) / (2 ** d) for i in range(3)]
    lo = [root[0] + x * size[0], root[1] + y * size[1], root[2] + z * size[2]]
    return [lo[0], lo[1], lo[2], lo[0] + size[0], lo[1] + size[1], lo[2] + size[2]]


def rect_overlap_share(node, rect):
    """Share of the node's horizontal extent that lies inside rect = (xmin, ymin, xmax, ymax); 0 if disjoint."""
    w = max(0.0, min(node[3], rect[2]) - max(node[0], rect[0]))
    h = max(0.0, min(node[4], rect[3]) - max(node[1], rect[1]))
    return (w * h) / ((node[3] - node[0]) * (node[4] - node[1]))


# ---------------------------------------------------------------- planes from points


def fit_plane(P):
    """Least-squares plane through points (n x 3): unit normal pointing up, offset d (n.p = d), rms distance."""
    c = P.mean(axis=0)
    _, s, vt = np.linalg.svd(P - c, full_matrices=False)
    n = vt[2]
    if n[2] < 0:
        n = -n
    return n, float(n @ c), float(s[2] / math.sqrt(max(1, len(P))))


def pitch_aspect(n):
    """(pitch degrees from horizontal, aspect = downhill azimuth degrees clockwise from north) of an up normal."""
    n = np.asarray(n, float) / np.linalg.norm(n)
    pitch = math.degrees(math.acos(max(-1.0, min(1.0, n[2]))))
    aspect = math.degrees(math.atan2(n[0], n[1])) % 360.0
    return pitch, aspect


def point_normals(P, k):
    """Per-point PCA normals (up) and surface variation (lambda_min / sum) from k nearest neighbours."""
    from scipy.spatial import cKDTree
    k = min(k, len(P))
    _, idx = cKDTree(P).query(P, k=k)
    Q = P[idx] - P[idx].mean(axis=1, keepdims=True)
    C = np.einsum("nki,nkj->nij", Q, Q) / k
    w, v = np.linalg.eigh(C)
    n = v[:, :, 0]
    n[n[:, 2] < 0] *= -1
    return n, w[:, 0] / np.maximum(w.sum(axis=1), 1e-12)


def region_grow(P, normals, variation, params):
    """Region growing on normals: seeds in order of increasing surface variation; a neighbour within
    `radius` joins when its normal is within `maxAngleDeg` of the region normal and it lies within `maxDist`
    of the region plane. Regions under `minPoints` are dropped. Returns labels (-1 = no plane)."""
    from scipy.spatial import cKDTree
    radius, cos_max = params["radius"], math.cos(math.radians(params["maxAngleDeg"]))
    max_dist, min_pts, seed_var = params["maxDist"], params["minPoints"], params["seedMaxVariation"]
    nbrs = cKDTree(P).query_ball_point(P, r=radius)
    labels = np.full(len(P), -1, dtype=int)
    order = np.argsort(variation, kind="stable")
    region = 0
    for s in order:
        if labels[s] != -1 or variation[s] > seed_var:
            continue
        members = [s]
        labels[s] = region
        rn, rc = normals[s].copy(), P[s].copy()
        head = 0
        while head < len(members):
            i = members[head]
            head += 1
            for j in nbrs[i]:
                if labels[j] != -1:
                    continue
                if abs(normals[j] @ rn) < cos_max or abs((P[j] - rc) @ rn) > max_dist:
                    continue
                labels[j] = region
                members.append(j)
            if len(members) in (12, 40, 120, 400):  # refit the region plane as it grows
                rn, d, _ = fit_plane(P[members])
                rc = P[members].mean(axis=0)
        if len(members) < min_pts:
            labels[np.array(members)] = -2  # tried, too small; keep them out of later regions
            continue
        region += 1
    labels[labels == -2] = -1
    return labels


# ---------------------------------------------------------------- rasters


def raster_cells(xy_min, xy_max, cell):
    """Cell-centre coordinates of a grid covering the box (row-major), and its shape."""
    nx = max(1, int(math.ceil((xy_max[0] - xy_min[0]) / cell)))
    ny = max(1, int(math.ceil((xy_max[1] - xy_min[1]) / cell)))
    xs = xy_min[0] + (np.arange(nx) + 0.5) * cell
    ys = xy_min[1] + (np.arange(ny) + 0.5) * cell
    gx, gy = np.meshgrid(xs, ys)
    return gx, gy


def majority_label_grid(xy, labels, xy_min, shape, cell):
    """Label per cell = most common plane label among the points falling in it (-1 when none)."""
    ny, nx = shape
    ix = np.floor((xy[:, 0] - xy_min[0]) / cell).astype(int)
    iy = np.floor((xy[:, 1] - xy_min[1]) / cell).astype(int)
    ok = (ix >= 0) & (ix < nx) & (iy >= 0) & (iy < ny) & (labels >= 0)
    grid = np.full(shape, -1, dtype=int)
    if not ok.any():
        return grid
    flat = iy[ok] * nx + ix[ok]
    lab = labels[ok]
    nl = lab.max() + 1
    counts = np.zeros((ny * nx, nl), dtype=np.int32)
    np.add.at(counts, (flat, lab), 1)
    has = counts.sum(axis=1) > 0
    g = grid.reshape(-1)
    g[has] = counts[has].argmax(axis=1)
    return grid


def nearest_label_grid(xy, labels, gx, gy, max_dist):
    """Label per cell = label of the nearest plane point within max_dist (-1 when none). Works at any point
    density, unlike a per-cell vote, which leaves cells without points empty."""
    from scipy.spatial import cKDTree
    grid = np.full(gx.shape, -1, dtype=int)
    ok = labels >= 0
    if not ok.any():
        return grid
    d, i = cKDTree(xy[ok]).query(np.stack([gx.ravel(), gy.ravel()], axis=1), distance_upper_bound=max_dist)
    hit = np.isfinite(d)
    g = grid.reshape(-1)
    g[hit] = labels[ok][i[hit]]
    return grid


def best_shift(occupied, target, max_cells):
    """Integer (dx, dy) cell shift of boolean raster `occupied` that maximises its intersection-over-union with
    `target` (np.roll semantics: +dx moves content to higher column index). Returns (dx, dy, iou0, iou)."""
    best, iou0 = None, None
    for dy in range(-max_cells, max_cells + 1):
        for dx in range(-max_cells, max_cells + 1):
            sh = np.roll(np.roll(occupied, dy, 0), dx, 1)
            union = (sh | target).sum()
            iou = float((sh & target).sum() / union) if union else 0.0
            if dx == 0 and dy == 0:
                iou0 = iou
            if best is None or iou > best[2]:
                best = (dx, dy, iou)
    return best[0], best[1], iou0, best[2]


def components(grid):
    """Splits each plane label into 4-connected components; returns a grid of component ids (-1 none)."""
    from scipy import ndimage
    out = np.full(grid.shape, -1, dtype=int)
    nxt = 0
    for lab in np.unique(grid[grid >= 0]):
        cc, n = ndimage.label(grid == lab)
        for c in range(1, n + 1):
            out[cc == c] = nxt
            nxt += 1
    return out


def triangles_top_grid(tri, gx, gy, min_up):
    """Upper envelope of a triangle soup on cell centres: for each cell the index of the highest
    upward-facing triangle covering it (-1 none). tri: (n, 3, 3) array of corners (x east, y north, z up)."""
    best = np.full(gx.shape, -1, dtype=int)
    top = np.full(gx.shape, -np.inf)
    for t, T in enumerate(tri):
        n = np.cross(T[1] - T[0], T[2] - T[0])
        ln = np.linalg.norm(n)
        if ln < 1e-9:
            continue
        n = n / ln
        if n[2] < 0:
            n = -n
        if n[2] < min_up:
            continue
        x0, x1 = T[:, 0].min(), T[:, 0].max()
        y0, y1 = T[:, 1].min(), T[:, 1].max()
        sel = (gx >= x0) & (gx <= x1) & (gy >= y0) & (gy <= y1)
        if not sel.any():
            continue
        px, py = gx[sel], gy[sel]
        (ax, ay), (bx, by), (cx, cy) = T[0, :2], T[1, :2], T[2, :2]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        l1 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / den
        l2 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / den
        l3 = 1 - l1 - l2
        inside = (l1 >= -1e-9) & (l2 >= -1e-9) & (l3 >= -1e-9)
        z = l1 * T[0, 2] + l2 * T[1, 2] + l3 * T[2, 2]
        idx = np.flatnonzero(sel)
        upd = inside & (z > top.reshape(-1)[idx])
        top.reshape(-1)[idx[upd]] = z[upd]
        best.reshape(-1)[idx[upd]] = t
    return best


def cluster_planes(normals, offsets, max_angle_deg, max_offset):
    """Greedy grouping of (unit up normal, offset) pairs into planes; returns a plane id per input."""
    ids = np.full(len(normals), -1, dtype=int)
    reps = []
    cos_max = math.cos(math.radians(max_angle_deg))
    for i, (n, d) in enumerate(zip(normals, offsets)):
        for k, (rn, rd) in enumerate(reps):
            if n @ rn >= cos_max and abs(d - rd) <= max_offset:
                ids[i] = k
                break
        else:
            reps.append((n, d))
            ids[i] = len(reps) - 1
    return ids


def planes_from_grid(comp, gx, gy, normal_of, cell):
    """Plane dicts from a component grid; normal_of(component id) gives its unit up normal."""
    planes = []
    for c in np.unique(comp[comp >= 0]):
        m = comp == c
        pitch, aspect = pitch_aspect(normal_of(int(c)))
        planes.append({"id": int(c), "area": float(m.sum() * cell * cell), "pitch": pitch, "aspect": aspect,
                       "cx": float(gx[m].mean()), "cy": float(gy[m].mean())})
    return planes


# ---------------------------------------------------------------- footprint frame


def min_area_rect(xy):
    """Minimum-area oriented rectangle of points: (cx, cy, ux, uy, half_long, half_short) with u along the long side."""
    from scipy.spatial import ConvexHull
    pts = np.asarray(xy, float)
    hull = pts[ConvexHull(pts).vertices] if len(pts) >= 3 else pts
    best = None
    for i in range(len(hull)):
        e = hull[(i + 1) % len(hull)] - hull[i]
        le = np.linalg.norm(e)
        if le < 1e-9:
            continue
        u = e / le
        v = np.array([-u[1], u[0]])
        a, b = hull @ u, hull @ v
        area = (a.max() - a.min()) * (b.max() - b.min())
        if best is None or area < best[0]:
            best = (area, u, v, a, b)
    _, u, v, a, b = best
    ca, cb = (a.max() + a.min()) / 2, (b.max() + b.min()) / 2
    c = u * ca + v * cb
    hl, hs = (a.max() - a.min()) / 2, (b.max() - b.min()) / 2
    if hs > hl:
        u, v, hl, hs = v, -u, hs, hl
    return float(c[0]), float(c[1]), float(u[0]), float(u[1]), float(hl), float(hs)


# ---------------------------------------------------------------- classification


def _ang_diff(a, b):
    return abs((a - b + 180.0) % 360.0 - 180.0)


def classify_roof(planes, cells_xy, cell_plane, rect, eroded_area, params):
    """Roof form from planes (both sides of the comparison use this).

    planes: plane dicts (ids match cell_plane); cells_xy (m, 2) and cell_plane (m) = the roof raster inside the
    eroded footprint; rect = min_area_rect of the footprint; eroded_area = plan area of the eroded footprint.
    Returns form (flat/gable/hip/complex/unknown), simple (flat/gable/hip/unknown), complex (bool), reasons,
    pitch (area-weighted mean of the significant sloped planes), ridge (bearing 0-180 of the main ridge for a
    gable or hip simple form) and side shares.
    """
    p = params
    total = sum(pl["area"] for pl in planes)
    out = {"form": "unknown", "simple": "unknown", "complex": False, "reasons": [], "pitch": None, "ridge": None,
           "nPlanes": 0, "coverage": 0.0, "flatShare": None, "sideShares": None}
    if total <= 0 or eroded_area <= 0:
        out["reasons"].append("no planes")
        return out
    sig = [pl for pl in planes if pl["area"] >= max(p["minPlaneM2"], p["minPlaneShare"] * total)]
    sig_area = sum(pl["area"] for pl in sig)
    out["coverage"] = round(sig_area / eroded_area, 3)
    out["nPlanes"] = len(sig)
    if out["coverage"] < p["minCoverage"]:
        out["reasons"].append("low coverage")
        return out
    flat = [pl for pl in sig if pl["pitch"] < p["flatMaxPitch"]]
    sloped = [pl for pl in sig if pl["pitch"] >= p["flatMaxPitch"]]
    flat_share = sum(pl["area"] for pl in flat) / sig_area
    out["flatShare"] = round(flat_share, 3)
    if not sloped or flat_share >= p["flatMinShare"]:
        out["form"] = out["simple"] = "flat"
        return out
    sl_area = sum(pl["area"] for pl in sloped)
    out["pitch"] = round(sum(pl["pitch"] * pl["area"] for pl in sloped) / sl_area, 1)
    # Side shares: for each side of the footprint rectangle, the share of roof cells within `sideBand` metres
    # of that side that belong to a significant sloped plane facing out over it (aspect within 45 deg).
    cx, cy, ux, uy, hl, hs = rect
    u, v = np.array([ux, uy]), np.array([-uy, ux])
    rel = np.asarray(cells_xy, float) - np.array([cx, cy])
    a, b = rel @ u, rel @ v
    side_normals = [u, v, -u, -v]
    side_dist = [hl - a, hs - b, hl + a, hs + b]
    aspect_of = {pl["id"]: pl["aspect"] for pl in sloped}
    shares = []
    for nrm, dist in zip(side_normals, side_dist):
        band = (dist <= p["sideBand"]) & (cell_plane >= 0)
        if band.sum() == 0:
            shares.append(0.0)
            continue
        az = math.degrees(math.atan2(nrm[0], nrm[1])) % 360.0
        facing = np.array([pid in aspect_of and _ang_diff(aspect_of[pid], az) <= 45.0 for pid in cell_plane[band]])
        shares.append(float(facing.mean()))
    out["sideShares"] = [round(s, 2) for s in shares]
    hit = [s >= p["sideMinShare"] for s in shares]
    long_pair, end_pair = hit[1] and hit[3], hit[0] and hit[2]
    if flat_share >= 0.5:
        simple = "flat"
    elif sum(hit) == 4 or (sum(hit) == 3 and (long_pair or end_pair)):
        simple = "hip"
    elif long_pair or end_pair:
        simple = "gable"
    else:
        # Neither pair is covered on both sides (mono-pitch or broken roofs): the dominant pair decides.
        simple = "gable" if max(shares[1] + shares[3], shares[0] + shares[2]) > 0 else "unknown"
    out["simple"] = simple
    if simple in ("gable", "hip"):
        # Ridge runs along the rectangle axis whose sides are not (or less) covered by facing planes.
        along_u = (shares[1] + shares[3]) >= (shares[0] + shares[2])
        d = u if along_u else v
        out["ridge"] = round(math.degrees(math.atan2(d[0], d[1])) % 180.0, 1)
    # Complex: more than the simple form explains.
    reasons = []
    if p["mixedMinShare"] <= flat_share < p["flatMinShare"]:
        reasons.append("mixed flat and sloped")
    expected = {"gable": 2, "hip": 4}.get(simple, 2)
    if len(sloped) > expected:
        reasons.append(f"{len(sloped)} sloped planes")
    axis = (math.degrees(math.atan2(u[0], u[1])) % 90.0)
    if any(min(_ang_diff(pl["aspect"] % 90.0, axis), 90 - _ang_diff(pl["aspect"] % 90.0, axis)) > p["axisTolDeg"]
           for pl in sloped):
        reasons.append("off-axis plane")
    if not (long_pair or end_pair):
        reasons.append("no opposite pair")
    out["reasons"] = reasons
    out["complex"] = bool(reasons)
    out["form"] = "complex" if reasons else simple
    return out


def roof_from_points(P, gx, gy, inside, rect, params):
    """Lidar path: region growing on point normals -> nearest-point label raster on the eroded footprint ->
    connected planes -> classify_roof. P: (n, 3) building points inside the eroded footprint.
    Returns (classification dict, planes)."""
    cell = params["cell"]
    if len(P) < params["regionGrow"]["minPoints"]:
        return {"form": "unknown", "simple": "unknown", "complex": False, "reasons": ["too few points"]}, []
    P = np.asarray(P, dtype=np.float64)
    normals, var = point_normals(P, params["normals"]["k"])
    labels = region_grow(P, normals, var, params["regionGrow"])
    grid = nearest_label_grid(P[:, :2], labels, gx, gy, params["fillDist"])
    grid[~inside] = -1
    comp = components(grid)
    lab_normal = {int(lab): fit_plane(P[labels == lab])[0] for lab in np.unique(labels[labels >= 0])}
    comp_label = {int(c): int(np.bincount(grid[comp == c]).argmax()) for c in np.unique(comp[comp >= 0])}
    planes = planes_from_grid(comp, gx, gy, lambda c: lab_normal[comp_label[c]], cell)
    res = classify_roof(planes, np.stack([gx[inside], gy[inside]], axis=1), comp[inside], rect,
                        float(inside.sum()) * cell * cell, params["classify"])
    return res, planes


def p2_simple(roof_shape):
    """P2 scene.json roofShape -> simple form: gabled -> gable, hipped -> hip, flat and slab -> flat."""
    return {"gabled": "gable", "hipped": "hip", "flat": "flat", "slab": "flat"}.get(roof_shape, "unknown")


# ---------------------------------------------------------------- statistics


def wilson(k, n, z=1.96):
    """Wilson score interval (lo, hi) for k successes out of n."""
    if n == 0:
        return (None, None)
    ph = k / n
    den = 1 + z * z / n
    c = (ph + z * z / (2 * n)) / den
    h = z * math.sqrt(ph * (1 - ph) / n + z * z / (4 * n * n)) / den
    return (round(c - h, 4), round(c + h, 4))


def confusion(pairs, labels):
    """Confusion matrix as nested dict truth -> predicted -> count (rows: first element of each pair)."""
    m = {a: {b: 0 for b in labels} for a in labels}
    for a, b in pairs:
        if a in m and b in m[a]:
            m[a][b] += 1
    return m


def kappa(matrix, labels):
    """Cohen's kappa of a square confusion matrix (dict of dicts)."""
    n = sum(matrix[a][b] for a in labels for b in labels)
    if n == 0:
        return None
    po = sum(matrix[a][a] for a in labels) / n
    pe = sum((sum(matrix[a][b] for b in labels) / n) * (sum(matrix[b][a] for b in labels) / n) for a in labels)
    return round((po - pe) / (1 - pe), 4) if pe < 1 else None


def stable_sample(ids, n, seed):
    """Deterministic sample: the n ids with the smallest sha256(seed|id)."""
    return sorted(ids, key=lambda i: hashlib.sha256(f"{seed}|{i}".encode()).hexdigest())[:n]


def suppress_small(stat, n, min_n):
    """A statistic over fewer than min_n buildings is replaced by its count only (privacy floor)."""
    return stat if n >= min_n else {"n": n, "suppressed": True}
