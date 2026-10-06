"""Pure functions for the per-block canopy file (Data/areas/<id>/canopy-blocks.json). Stdlib only, offline-testable.

Formulas and assumptions are documented in docs/research/aerial.md section 13.9.
"""

import hashlib
import math

METHOD_VERSION = "canopy-blocks 1"
METHOD_VERSION_CALIBRATED = "canopy-blocks 2"   # crown area is a calibrated effective mask-canopy area per tree (aerial.md 13.10)
MIN_FACE_M2 = 500.0          # slivers below this are not written (under about 5,500 NAIP pixels at 0.3 m)
SMALL_FACE_M2 = 10000.0      # confidence falls off below 1 ha
EDGE_CUT_FACTOR = 0.85       # face closed by the area edge: the real block continues outside the window
PARK_WATER_FACTOR = 0.80     # >= 10 % park or water: the residential-fabric assumptions of the check do not hold
PARK_WATER_LIMIT_PCT = 10.0
SIZE_FLOOR = 0.5


def block_id(street_way_ids, taken=()):
    """Stable block id: 'cb-' + first 8 hex of SHA-256 over the sorted OSM way ids of the street ways that
    bound the face. Independent of geometry edits, area size and block order; changes only if the street
    network around the block changes. Faces bounded by identical way sets get '-2', '-3' ... in the order
    they are resolved (callers resolve in order of descending face area, then centroid)."""
    key = "|".join(str(i) for i in sorted({int(i) for i in street_way_ids}))
    base = "cb-" + hashlib.sha256(key.encode()).hexdigest()[:8]
    cand, n = base, 1
    while cand in taken:
        n += 1
        cand = f"{base}-{n}"
    return cand


def tree_estimate(canopy_share, land_area_m2, crown_area_m2, frontage_m, crown_range_m2=None):
    """Tree count and spacing from canopy cover.

    trees         = canopy_share * land_area / crown_area   (crown_area: lidar mean non-overlapping crown plan area)
    treesPerHa    = canopy_share * 10,000 / crown_area
    gridSpacingM  = sqrt(10,000 / treesPerHa)   (square grid over the land: tree-to-tree distance)
    frontageSpacingM = frontage / trees         (all trees in one row along the street frontage: the spacing
                                                 of a street-tree row that alone would make this canopy)
    crown_range_m2 = (small, large) crown areas -> treesPerHaRange (large crowns -> fewer trees).
    Returns None when there is no canopy or no land."""
    if canopy_share is None or land_area_m2 <= 0 or canopy_share <= 0 or crown_area_m2 <= 0:
        return None
    n = canopy_share * land_area_m2 / crown_area_m2
    per_ha = canopy_share * 10000.0 / crown_area_m2
    out = {"trees": n, "treesPerHa": per_ha, "gridSpacingM": math.sqrt(10000.0 / per_ha),
           "frontageSpacingM": (frontage_m / n) if (frontage_m and frontage_m > 0 and n >= 1) else None}
    if crown_range_m2:
        lo_a, hi_a = crown_range_m2
        out["treesPerHaRange"] = (canopy_share * 10000.0 / hi_a, canopy_share * 10000.0 / lo_a)
    return out


def block_confidence(area_agreement, face_area_m2, fully_inside, park_water_pct):
    """Heuristic 0-1 confidence of a block's canopy and tree numbers (not a measured per-block accuracy).

    base       = the area's photo-check agreement per point (fraction, e.g. 0.86)
    size       = min(1, sqrt(face_area / 10,000 m2)), floored at 0.5   (faces under 1 ha)
    edge       = x 0.85 if the face is cut by the area edge
    park/water = x 0.80 if the face is at least 10 % park or water
    Returns (value, tier) with tier high >= 0.75, medium >= 0.6, else low."""
    size = max(SIZE_FLOOR, min(1.0, math.sqrt(face_area_m2 / SMALL_FACE_M2)))
    v = area_agreement * size
    if not fully_inside:
        v *= EDGE_CUT_FACTOR
    if park_water_pct >= PARK_WATER_LIMIT_PCT:
        v *= PARK_WATER_FACTOR
    tier = "high" if v >= 0.75 else "medium" if v >= 0.6 else "low"
    return round(v, 2), tier


# ---------------------------------------------------------------- calibration (docs/research/aerial.md 13.10)


def wilson_interval(k, n, z=1.96):
    """Wilson score interval (low, high) for k successes in n trials, as fractions. (None, None) for n = 0."""
    if n <= 0:
        return None, None
    p = k / n
    den = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / den
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return centre - half, centre + half


def ratio_of_sums(nums, dens):
    """Ratio estimator sum(nums) / sum(dens), e.g. trees counted per hectare of mask canopy over plots."""
    d = sum(dens)
    return sum(nums) / d if d else None


def _rng(seed):
    import random
    return random.Random(int(hashlib.sha256(str(seed).encode()).hexdigest()[:16], 16))


def cluster_bootstrap(clusters, stat, n_boot=10000, seed="canopy-calibration", alpha=0.05):
    """Percentile bootstrap of stat(list_of_clusters), resampling whole clusters (plots, or points) with
    replacement. Deterministic for a given seed (SHA-256-seeded random.Random). Returns (stat of the data, low, high)."""
    rng = _rng(seed)
    n = len(clusters)
    vals = []
    for _ in range(n_boot):
        v = stat([clusters[rng.randrange(n)] for _ in range(n)])
        if v is not None:
            vals.append(v)
    vals.sort()
    lo = vals[int((alpha / 2) * len(vals))]
    hi = vals[min(len(vals) - 1, int((1 - alpha / 2) * len(vals)))]
    return stat(list(clusters)), lo, hi


def paired_difference_bootstrap(a, b, n_boot=10000, seed="canopy-points", alpha=0.05):
    """Mean of (a_i - b_i) over paired 0/1 observations, with a percentile bootstrap interval over the points.
    Used for label-tree minus mask-tree at the same points (negative = the mask over-calls canopy)."""
    pairs = [(float(x), float(y)) for x, y in zip(a, b)]
    return cluster_bootstrap(pairs, lambda s: sum(x - y for x, y in s) / len(s) if s else None, n_boot, seed, alpha)


def effective_crown_area(canopy_m2, trees):
    """Mask-canopy area per tree (m2): sum of canopy area / sum of tree counts over the plots. Leaf-on crowns
    overlap and the mask also takes in some shade, so this is not a crown size: it is the factor that turns this
    mask's canopy area into a tree count."""
    return ratio_of_sums(canopy_m2, trees)
