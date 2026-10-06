"""Pure functions of the aerial roof study (numpy only, no I/O, no network).

Everything here is deterministic and unit-tested offline (tests/test_roofcore.py):
colour conversion and colour families, the minimum-area rectangle and footprint shape features,
the roof-type heuristic on a luminance patch, and vegetation / canopy shares.

Conventions: images are numpy arrays indexed [row, col]; pixel centres are at (col + 0.5, row + 0.5);
"rect" = (cx, cy, angle, length, width) in pixel units with length >= width and angle the direction of
the long axis (radians, x = col to the right, y = row downwards).
"""

import math

import numpy as np

# ---------------------------------------------------------------- colour

_M_RGB_XYZ = np.array([[0.4124564, 0.3575761, 0.1804375],
                       [0.2126729, 0.7151522, 0.0721750],
                       [0.0193339, 0.1191920, 0.9503041]])
_M_XYZ_RGB = np.linalg.inv(_M_RGB_XYZ)
_WHITE_D65 = np.array([0.95047, 1.0, 1.08883])


def srgb_to_lab(rgb):
    """sRGB (uint8 or 0..255 floats, shape (..., 3)) -> CIE L*a*b* (D65)."""
    c = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    xyz = lin @ _M_RGB_XYZ.T / _WHITE_D65
    eps, kappa = 216 / 24389, 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (kappa * xyz + 16) / 116)
    L = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def lab_to_srgb(lab):
    """CIE L*a*b* (D65) -> sRGB 0..255 floats (clipped)."""
    lab = np.asarray(lab, dtype=np.float64)
    fy = (lab[..., 0] + 16) / 116
    fx = fy + lab[..., 1] / 500
    fz = fy - lab[..., 2] / 200
    eps, kappa = 216 / 24389, 24389 / 27

    def finv(t):
        t3 = t ** 3
        return np.where(t3 > eps, t3, (116 * t - 16) / kappa)

    xyz = np.stack([finv(fx), np.where(lab[..., 0] > kappa * eps, fy ** 3, lab[..., 0] / kappa), finv(fz)], axis=-1)
    lin = (xyz * _WHITE_D65) @ _M_XYZ_RGB.T
    lin = np.clip(lin, 0, 1)
    c = np.where(lin <= 0.0031308, 12.92 * lin, 1.055 * lin ** (1 / 2.4) - 0.055)
    return np.clip(c * 255.0, 0, 255)


def lch(lab):
    """(L, C, h_degrees) of one Lab triple."""
    L, a, b = (float(x) for x in lab)
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360.0


def hex_from_rgb(rgb):
    r, g, b = (int(round(float(x))) for x in rgb)
    return "#%02X%02X%02X" % (r, g, b)


def rgb_from_hex(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def robust_colour(rgb_pixels):
    """Per-channel median in Lab of an (n, 3) pixel list -> (lab, hex). None if empty."""
    px = np.asarray(rgb_pixels).reshape(-1, 3)
    if px.shape[0] == 0:
        return None, None
    lab = np.median(srgb_to_lab(px), axis=0)
    return lab, hex_from_rgb(lab_to_srgb(lab))


def _hue_in(h, rng):
    lo, hi = rng
    return lo <= h < hi if lo <= hi else (h >= lo or h < hi)


def colour_family(lab, families):
    """Map one Lab colour to a family name using the rules in data/roof_families.json.

    Rules: if chroma < achromaticMaxChroma (or L* and chroma are below the `darkAchromatic` limits, or the hue
    falls in an `achromaticHues` sector below its chroma limit) the colour is achromatic and is classified by
    L* bands; otherwise the first chromatic rule whose hue sector, chroma and L* limits match wins. Falls back
    to the achromatic bands.
    """
    L, C, h = lch(lab)

    def by_lightness():
        for band in families["achromatic"]:
            if L < band["maxL"]:
                return band["family"]
        return families["achromatic"][-1]["family"]

    if C < families["achromaticMaxChroma"]:
        return by_lightness()
    dark = families.get("darkAchromatic")
    if dark and L < dark["maxL"] and C < dark["maxChroma"]:
        return by_lightness()
    for sector in families.get("achromaticHues", []):
        if _hue_in(h, sector["hue"]) and C < sector["maxChroma"]:
            return by_lightness()
    for rule in families["chromatic"]:
        if not _hue_in(h, rule["hue"]):
            continue
        if C < rule.get("minChroma", 0) or L < rule.get("minL", -1) or L >= rule.get("maxL", 101):
            continue
        return rule["family"]
    return by_lightness()


def scene_neutral(labs):
    """Grey-world neutral of a scene's roofs: median (a*, b*) of the roof colours."""
    arr = np.asarray(labs, dtype=np.float64).reshape(-1, 3)
    return float(np.median(arr[:, 1])), float(np.median(arr[:, 2]))


def colour_family_relative(lab, neutral, rules):
    """Rule set 2: colour family from chroma and hue measured relative to the scene's neutral roof colour.

    `rules` is the `sceneRelative` block of data/roof_families.json. Achromatic when the relative chroma is
    below achromaticMaxRelChroma or the relative hue is a cool cast (coolCast sector, below its chroma
    limit); then by L* bands. Otherwise the first matching chromatic rule (hue sector, minChroma on the
    relative chroma, L* limits).
    """
    L = float(lab[0])
    da, db = float(lab[1]) - neutral[0], float(lab[2]) - neutral[1]
    C = math.hypot(da, db)
    h = math.degrees(math.atan2(db, da)) % 360.0

    def by_lightness():
        for band in rules["achromatic"]:
            if L < band["maxL"]:
                return band["family"]
        return rules["achromatic"][-1]["family"]

    if C < rules["achromaticMaxRelChroma"]:
        return by_lightness()
    cool = rules.get("coolCast")
    if cool and _hue_in(h, cool["hue"]) and C < cool["maxRelChroma"]:
        return by_lightness()
    for rule in rules["chromatic"]:
        if not _hue_in(h, rule["hue"]):
            continue
        if C < rule.get("minChroma", 0) or L < rule.get("minL", -1) or L >= rule.get("maxL", 101):
            continue
        return rule["family"]
    return by_lightness()


# ---------------------------------------------------------------- geometry

def convex_hull(points):
    """Andrew's monotone chain; returns hull vertices counter-clockwise (no repeat)."""
    pts = sorted(set((float(x), float(y)) for x, y in points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def polygon_area(ring):
    """Absolute shoelace area of a ring (list of (x, y); closing point optional)."""
    a = 0.0
    n = len(ring)
    for i in range(n):
        x1, y1 = ring[i]
        x2, y2 = ring[(i + 1) % n]
        a += x1 * y2 - x2 * y1
    return abs(a) / 2.0


def min_area_rect(points):
    """Minimum-area enclosing rectangle by rotating the hull edges.

    Returns (cx, cy, angle, length, width): centre, direction of the long side (radians in [0, pi)),
    long and short side lengths.
    """
    hull = convex_hull(points)
    if len(hull) < 3:
        raise ValueError("degenerate polygon")
    best = None
    n = len(hull)
    for i in range(n):
        x1, y1 = hull[i]
        x2, y2 = hull[(i + 1) % n]
        ang = math.atan2(y2 - y1, x2 - x1)
        c, s = math.cos(ang), math.sin(ang)
        us = [x * c + y * s for x, y in hull]
        vs = [-x * s + y * c for x, y in hull]
        umin, umax, vmin, vmax = min(us), max(us), min(vs), max(vs)
        area = (umax - umin) * (vmax - vmin)
        if best is None or area < best[0] - 1e-9:
            best = (area, ang, umin, umax, vmin, vmax)
    _, ang, umin, umax, vmin, vmax = best
    c, s = math.cos(ang), math.sin(ang)
    uc, vc = (umin + umax) / 2, (vmin + vmax) / 2
    cx, cy = uc * c - vc * s, uc * s + vc * c
    du, dv = umax - umin, vmax - vmin
    if dv > du:
        ang += math.pi / 2
        du, dv = dv, du
    return cx, cy, ang % math.pi, du, dv


def shape_features(ring):
    """Footprint shape features from the outer ring (any consistent unit, e.g. metres)."""
    ring = [tuple(p) for p in ring]
    if len(ring) > 1 and ring[0] == ring[-1]:
        ring = ring[:-1]
    area = polygon_area(ring)
    cx, cy, ang, length, width = min_area_rect(ring)
    rect_area = length * width
    return {
        "area": area,
        "length": length,
        "width": width,
        "aspect": length / width if width > 0 else float("inf"),
        "rectangularity": area / rect_area if rect_area > 0 else 0.0,
        "vertices": len(ring),
        "rect": (cx, cy, ang, length, width),
    }


# ---------------------------------------------------------------- roof type

def facet_labels(shape, rect, model):
    """Integer facet label per pixel of an image of `shape` for a planar roof model inside `rect`.

    Models: "gable_long" (ridge along the long axis: 2 planes split by the long centre line),
    "gable_short" (ridge along the short axis), "hip" (4 planes: each pixel belongs to the facet of its
    nearest rectangle side, which is exactly the plan view of a hip roof with equal pitches).
    """
    cx, cy, ang, length, width = rect
    rows, cols = np.indices(shape, dtype=np.float64)
    x, y = cols + 0.5 - cx, rows + 0.5 - cy
    c, s = math.cos(ang), math.sin(ang)
    u = x * c + y * s          # along the long axis
    v = -x * s + y * c         # along the short axis
    if model == "gable_long":
        return (v > 0).astype(np.int8)
    if model == "gable_short":
        return (u > 0).astype(np.int8)
    if model == "hip":
        to_short_edge = length / 2 - np.abs(u)
        to_long_edge = width / 2 - np.abs(v)
        side = np.where(v > 0, 0, 1)
        end = np.where(u > 0, 2, 3)
        return np.where(to_long_edge <= to_short_edge, side, end).astype(np.int8)
    raise ValueError(model)


def facet_r2(values, labels):
    """Share of the variance of `values` explained by per-facet means (R^2), and adjusted R^2."""
    v = np.asarray(values, dtype=np.float64)
    lab = np.asarray(labels)
    n = v.size
    if n < 3:
        return 0.0, 0.0
    sst = float(((v - v.mean()) ** 2).sum())
    if sst <= 0:
        return 0.0, 0.0
    sse = 0.0
    k = 0
    for f in np.unique(lab):
        sel = v[lab == f]
        if sel.size:
            k += 1
            sse += float(((sel - sel.mean()) ** 2).sum())
    r2 = 1 - sse / sst
    adj = 1 - (1 - r2) * (n - 1) / max(n - k, 1)
    return r2, adj


def robust_std(values):
    q75, q25 = np.percentile(values, [75, 25])
    return float(q75 - q25) / 1.349


def classify_roof(lum, valid, rect, shape, params):
    """Roof-type guess from a luminance patch (L*), its valid-pixel mask and the footprint rectangle.

    Returns (label, confidence, diagnostics); label in flat / gable / hip / complex / unknown.
    Heuristic (documented in README.md and docs/research/aerial.md):
      1. too few visible pixels -> unknown (hidden by canopy or too small);
      2. fit three planar facet models (gable along the long axis, gable along the short axis, hip) to the
         luminance; R^2 = share of luminance variance explained by the facet means;
      3. low texture (robust std of L*) and no model explaining much -> flat;
      4. a non-rectangular footprint (rectangularity below the limit: L, T, U and wings) -> complex;
      5. hip if its adjusted R^2 beats the best gable by a margin, otherwise gable; if no model explains
         enough variance on a textured roof -> complex.
    `shape` holds the footprint features (shape_features) and `params` the thresholds (data/params.json).
    """
    p = params
    n_valid = int(valid.sum())
    diag = {"validPixels": n_valid}
    if n_valid < p["minPixels"]:
        return "unknown", 0.0, diag
    values = lum[valid]
    std = robust_std(values)
    fits = {}
    for model in ("gable_long", "gable_short", "hip"):
        labels = facet_labels(lum.shape, rect, model)[valid]
        fits[model] = facet_r2(values, labels)
    gable_model = max(("gable_long", "gable_short"), key=lambda m: fits[m][1])
    g_adj, h_adj = fits[gable_model][1], fits["hip"][1]
    best_adj = max(g_adj, h_adj)
    diag.update({"stdL": round(std, 2), "r2": {m: round(fits[m][1], 3) for m in fits},
                 "rectangularity": round(shape["rectangularity"], 3), "aspect": round(shape["aspect"], 2)})
    if std < p["flatMaxStdL"] and best_adj < p["flatMaxR2"]:
        conf = min(1.0, (p["flatMaxStdL"] - std) / p["flatMaxStdL"] + 0.3)
        return "flat", round(conf, 2), diag
    if shape["rectangularity"] < p["complexMaxRectangularity"]:
        conf = min(1.0, (p["complexMaxRectangularity"] - shape["rectangularity"]) / 0.15 + 0.3)
        return "complex", round(conf, 2), diag
    if best_adj < p["planarMinR2"]:
        return "complex", 0.3, diag
    margin = h_adj - g_adj
    if margin > p["hipMinGain"]:
        conf = min(1.0, 0.4 + margin / 0.2)
        return "hip", round(conf, 2), diag
    conf = min(1.0, 0.4 + (p["hipMinGain"] - margin) / 0.2)
    diag["ridge"] = "long" if gable_model == "gable_long" else "short"
    return "gable", round(conf, 2), diag


# ---------------------------------------------------------------- vegetation and canopy

def ndvi(red, nir):
    r = np.asarray(red, dtype=np.float64)
    n = np.asarray(nir, dtype=np.float64)
    den = n + r
    return np.where(den > 0, (n - r) / np.where(den > 0, den, 1), 0.0)


def box_mean(arr, radius):
    """Mean over a (2r+1)^2 window with edge replication (integral image)."""
    a = np.pad(np.asarray(arr, dtype=np.float64), radius + 1, mode="edge")
    ii = a.cumsum(0).cumsum(1)
    k = 2 * radius + 1
    s = ii[k:, k:] - ii[:-k, k:] - ii[k:, :-k] + ii[:-k, :-k]
    h, w = np.asarray(arr).shape
    return s[:h, :w] / (k * k)


def local_std(arr, radius):
    m = box_mean(arr, radius)
    m2 = box_mean(np.asarray(arr, dtype=np.float64) ** 2, radius)
    return np.sqrt(np.maximum(m2 - m * m, 0))


def masked_local_std(arr, mask, radius):
    """Local standard deviation of `arr` over the `mask` pixels only, in a (2r+1)^2 window."""
    a = np.asarray(arr, dtype=np.float64)
    m = np.asarray(mask, dtype=np.float64)
    cnt = box_mean(m, radius)
    safe = np.where(cnt > 0, cnt, 1)
    mean = box_mean(a * m, radius) / safe
    mean2 = box_mean(a * a * m, radius) / safe
    return np.where(cnt > 0, np.sqrt(np.maximum(mean2 - mean * mean, 0)), 0.0)


def canopy_mask(red, nir, params, pixel_m):
    """Vegetation and tree-canopy masks from the red and near-infrared bands.

    vegetation = NDVI > vegNdvi. NDVI alone cannot split trees from lawns (both ~0.5 in leaf-on NAIP), so
    canopy = vegetation AND local NIR texture > textureMinStd, where the texture is the standard deviation
    of NIR over the vegetation pixels of a small window (lawns are smooth in NIR, crowns are lumpy with
    sunlit and shaded leaves; restricting to vegetation pixels avoids flagging lawn edges along paving).
    A morphological opening then removes thin bands (texture along lawn/shadow edges) and a majority filter
    removes isolated pixels. Thresholds live in data/params.json; this is a documented heuristic, not a
    trained classifier, and the NIR threshold is in raw digital numbers of the imagery it was set on.
    """
    v = ndvi(red, nir)
    veg = v > params["vegNdvi"]
    radius = max(1, int(round(params["textureRadiusMeters"] / pixel_m)))
    tex = masked_local_std(nir, veg, radius)
    can = veg & (tex > params["textureMinStd"])
    open_r = int(round(params["openingRadiusMeters"] / pixel_m))
    if open_r > 0:
        can = opening(can, open_r)
    smooth_r = max(1, int(round(params["majorityRadiusMeters"] / pixel_m)))
    can = box_mean(can.astype(np.float64), smooth_r) > 0.5
    return veg, can


def erode(mask, radius):
    """Binary erosion with a (2r+1)^2 square (pixels outside the image count as unset)."""
    m = np.pad(np.asarray(mask, dtype=np.float64), radius, mode="constant")
    out = box_mean(m, radius) > 1 - 1e-9
    return out[radius:-radius, radius:-radius] if radius > 0 else out


def dilate(mask, radius):
    return box_mean(np.asarray(mask, dtype=np.float64), radius) > 1e-9


def opening(mask, radius):
    return dilate(erode(mask, radius), radius)


def share(mask, region):
    """Share of `region` pixels that are set in `mask` (None if the region is empty)."""
    region = np.asarray(region, dtype=bool)
    n = int(region.sum())
    if n == 0:
        return None
    return float(np.asarray(mask, dtype=bool)[region].sum()) / n


# ---------------------------------------------------------------- stable sampling

def stable_sample(ids, n, seed):
    """Deterministic sample: the n ids with the smallest sha256(seed + ':' + id). Order-independent."""
    import hashlib
    keyed = sorted(ids, key=lambda i: hashlib.sha256(f"{seed}:{i}".encode()).hexdigest())
    return keyed[:n]


def suppress_small(stat, min_n):
    """Privacy rule for committed aggregates: a statistic that describes fewer than `min_n` buildings (it has an
    "n" field) is replaced by its count only, so no single roof's value can be read from the results."""
    if stat is None:
        return None
    n = stat.get("n", 0)
    if n < min_n:
        return {"n": n, "suppressed": f"n < {min_n}"}
    return stat


def confusion(pairs, labels):
    """Confusion matrix {truth: {pred: count}} over the given label order, plus accuracy."""
    m = {t: {p: 0 for p in labels} for t in labels}
    for truth, pred in pairs:
        m.setdefault(truth, {p: 0 for p in labels})
        m[truth][pred] = m[truth].get(pred, 0) + 1
    n = len(pairs)
    correct = sum(1 for t, p in pairs if t == p)
    return m, (correct / n if n else None), correct, n
