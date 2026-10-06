"""Pure functions of the lidar tree-height measurement (numpy + scipy; no I/O, no network).

Unit-tested offline in tests/test_treeheights.py. Conventions:
- a canopy height model (CHM) is a 2-D array [row = iy (north), column = ix (east)] of the maximum height above
  ground, in metres, per `cell`-metre square; 0 where no vegetation point was seen;
- tree tops are (iy, ix, height) triples; crown radius is the radius of the circle with the crown region's
  plan area (equivalent-circle radius).
The watershed (crown regions) imports scikit-image lazily; everything else needs numpy and scipy only.
"""

import math

import numpy as np
from scipy import ndimage

# ---------------------------------------------------------------- canopy height model


def chm_max(x, y, h, x0, y0, nx, ny, cell):
    """Maximum of `h` per cell on an (ny, nx) grid whose lower-left corner is (x0, y0); empty cells are 0."""
    x, y, h = np.asarray(x), np.asarray(y), np.asarray(h)
    ix = np.floor((x - x0) / cell).astype(np.int64)
    iy = np.floor((y - y0) / cell).astype(np.int64)
    ok = (ix >= 0) & (ix < nx) & (iy >= 0) & (iy < ny)
    chm = np.zeros(ny * nx, dtype=np.float32)
    np.maximum.at(chm, iy[ok] * nx + ix[ok], h[ok].astype(np.float32))
    return chm.reshape(ny, nx)


def smooth_chm(chm, sigma_cells):
    """Gaussian smoothing (removes pits and twig-level spikes before tree tops are looked for)."""
    if sigma_cells <= 0:
        return chm.astype(np.float32)
    return ndimage.gaussian_filter(chm.astype(np.float32), sigma_cells, mode="nearest")


def fill_small_holes(mask, max_cells):
    """Fill the holes of a boolean mask that are at most `max_cells` cells and do not touch the border (sparse
    roof points leave gaps inside a roof; a courtyard is a hole too, but a big one)."""
    from scipy import ndimage
    holes, n = ndimage.label(~mask)
    if n == 0:
        return mask.copy()
    sizes = np.bincount(holes.ravel(), minlength=n + 1)
    border = np.unique(np.concatenate([holes[0], holes[-1], holes[:, 0], holes[:, -1]]))
    small = (sizes <= max_cells)
    small[0] = False
    small[border] = False
    return mask | small[holes]


def remove_roof_clutter(chm, chm_bld, cfg):
    """Zero the vegetation cells that belong to a building rather than to a tree.

    The vendor's classes put roof edges, eaves, parapets, chimneys and wall points into "vegetation". Those cells
    lie on a building, so the building class marks the place: the roof zone is the cells at least `minRoofHeight`
    high in `chm_bld`, closed by `closeCells`, with holes of up to `maxHoleCells` filled (a sparse roof; a real
    courtyard is a bigger hole and stays open), grown by `wallCells` to take in the wall line. A vegetation cell
    in the zone is clutter unless it rises more than `bandAboveMeters` above the roof beside it (the nearest
    building cell's height): a crown over a roof does, a wall point or roof edge does not.
    Returns (cleaned CHM, boolean mask of the cells removed)."""
    m = roof_clutter_masks(chm, chm_bld, cfg)
    return m["clean"], m["clutter"]


def roof_clutter_masks(chm, chm_bld, cfg):
    """`remove_roof_clutter` with its working masks: dict of `clean` (CHM without clutter), `clutter` (cells
    removed), `roof` (the closed, hole-filled roof mask, no wall ring) and `roof_h` (height of the highest
    building cell within `heightCells` cells, or of the nearest one if none is that close: the roof beside each
    cell)."""
    from scipy import ndimage
    solid = chm_bld >= cfg["minRoofHeight"]
    if not solid.any():
        z = np.zeros(chm.shape, dtype=bool)
        return {"clean": chm, "clutter": z, "roof": z, "roof_h": np.zeros(chm.shape, dtype=np.float32)}
    three = np.ones((3, 3), dtype=bool)
    closed = ndimage.binary_closing(solid, structure=three, iterations=int(cfg["closeCells"]))
    roof = fill_small_holes(closed, int(cfg["maxHoleCells"]))
    zone = ndimage.binary_dilation(roof, structure=three, iterations=int(cfg["wallCells"]))
    _, idx = ndimage.distance_transform_edt(~solid, return_indices=True)
    nearest = chm_bld[idx[0], idx[1]]
    local = ndimage.maximum_filter(chm_bld, size=2 * int(cfg["heightCells"]) + 1, mode="constant", cval=0.0)
    roof_h = np.maximum(nearest, local).astype(np.float32)
    clutter = zone & (chm > 0) & (chm <= roof_h + cfg["bandAboveMeters"])
    return {"clean": np.where(clutter, np.float32(0), chm), "clutter": clutter, "roof": roof, "roof_h": roof_h}


def tops_on_roofs(iy, ix, h, roof, roof_h, min_above):
    """Which tops lie on a roof (inside the roof mask) without standing at least `min_above` metres above it.
    Rooftop plant, parapets, chimneys, railings and porch posts that the vendor classed as vegetation make tops of
    a few metres above the roof; a tree whose crown tops a roof stands well above it."""
    return roof[iy, ix] & (h < roof_h[iy, ix] + min_above)


# ---------------------------------------------------------------- tree tops


def window_radius(h, win):
    """Search radius (m) around a cell of height h: grows with height (taller crowns are wider), clamped."""
    return np.clip(win["base"] + win["perMeter"] * np.asarray(h, float), win["minRadius"], win["maxRadius"])


def disk(radius_cells):
    r = int(math.ceil(radius_cells))
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    return (xx * xx + yy * yy) <= radius_cells * radius_cells + 1e-9


def local_maxima(chm, cell, win, min_height):
    """Tree tops of a CHM: cells of at least `min_height` that are the highest cell within a disk whose radius
    follows `window_radius` of the cell's own height (height-adaptive window, Popescu and Wynne style).
    Ties on a plateau are broken by cell index so that each plateau yields one top. Returns (iy, ix, h) arrays,
    h from `chm`, sorted from the tallest down."""
    ny, nx = chm.shape
    jitter = (np.arange(ny * nx, dtype=np.float64).reshape(ny, nx) % 9973) * 1e-7
    v = chm.astype(np.float64) + jitter
    cand = chm >= min_height
    rad = window_radius(chm, win) / cell
    rad_c = np.where(cand, np.maximum(np.round(rad * 2) / 2, 1.0), 0.0)  # half-cell classes
    is_top = np.zeros(chm.shape, dtype=bool)
    for r in np.unique(rad_c[cand]):
        fp = disk(r)
        filt = ndimage.maximum_filter(v, footprint=fp, mode="constant", cval=-np.inf)
        is_top |= cand & (rad_c == r) & (v >= filt)
    iy, ix = np.nonzero(is_top)
    h = chm[iy, ix]
    order = np.argsort(-h, kind="stable")
    return iy[order], ix[order], h[order]


# ---------------------------------------------------------------- crowns


def watershed_labels(chm_smooth, iy, ix, min_height):
    """Crown basins: marker-controlled watershed of the inverted smoothed CHM from the tree tops, inside the cells
    of at least `min_height`. Label k + 1 belongs to top k; 0 is background."""
    from skimage.segmentation import watershed  # lazy: only the crown step needs it
    markers = np.zeros(chm_smooth.shape, dtype=np.int32)
    markers[iy, ix] = np.arange(1, len(iy) + 1, dtype=np.int32)
    return watershed(-chm_smooth, markers, mask=chm_smooth >= min_height)


def crown_radius(area_m2):
    """Radius (m) of the circle with the given plan area."""
    return math.sqrt(max(area_m2, 0.0) / math.pi)


def crown_measures(chm_smooth, labels, iy, ix, h, cell, crown):
    """Per tree: crown plan area and equivalent radius, and whether the crown is free-standing.

    The crown is the part of the tree's watershed basin that is at least max(crown.minAbsoluteHeight,
    crown.minRelativeHeight x the tree's height) high and 4-connected to the top (the basin's low skirt of
    shrubs, lawn edge and the neighbours' flanks is cut off). "Free-standing" means at most 10 % of the crown's
    boundary cells touch another tree's basin, i.e. the crown was not squeezed by neighbours.
    Returns dict of arrays: area, radius, free, cells, thick (thickness of the top layer, in cells)."""
    n = len(iy)
    area = np.zeros(n)
    free = np.zeros(n, dtype=bool)
    cells = np.zeros(n, dtype=np.int64)
    thick = np.zeros(n)
    slices = ndimage.find_objects(labels, max_label=n)
    four = ndimage.generate_binary_structure(2, 1)
    for k in range(n):
        sl = slices[k]
        if sl is None:
            continue
        pad = tuple(slice(max(s.start - 1, 0), s.stop + 1) for s in sl)
        lab = labels[pad]
        sub = chm_smooth[pad]
        thr = max(crown["minAbsoluteHeight"], crown["minRelativeHeight"] * float(h[k]))
        mine = (lab == k + 1) & (sub >= thr)
        comp, _ = ndimage.label(mine, structure=four)
        ty, tx = iy[k] - pad[0].start, ix[k] - pad[1].start
        if not (0 <= ty < mine.shape[0] and 0 <= tx < mine.shape[1]) or comp[ty, tx] == 0:
            continue
        own = comp == comp[ty, tx]
        cells[k] = int(own.sum())
        area[k] = cells[k] * cell * cell
        # Thickness of the crown's top layer: the part of the crown within `topLayerMeters` of the smoothed top, and
        # the largest distance (in cells) from one of its cells to the outside. A wire or a pole is one or two cells
        # wide (about 1), a crown cap is several cells across.
        layer = own & (sub >= sub[ty, tx] - crown["topLayerMeters"])
        comp2, _ = ndimage.label(layer, structure=four)
        if comp2[ty, tx] > 0:
            top_layer = np.pad(comp2 == comp2[ty, tx], 1)
            thick[k] = float(ndimage.distance_transform_edt(top_layer).max())
        ring = ndimage.binary_dilation(own, structure=four) & ~own
        if ring.any():
            neighbours = ring & (lab > 0) & (lab != k + 1)
            free[k] = neighbours.sum() <= 0.10 * ring.sum()
        else:
            free[k] = True
    return {"area": area, "radius": np.sqrt(area / math.pi), "free": free, "cells": cells, "thick": thick}


# ---------------------------------------------------------------- statistics


def percentile_summary(values, percentiles, min_n):
    """{"n", "mean", "pNN"...} of a sample, or only {"n"} when it holds fewer than `min_n` values (privacy floor
    and common sense: no distribution over a handful of trees)."""
    v = np.asarray(values, float)
    v = v[np.isfinite(v)]
    out = {"n": int(len(v))}
    if len(v) < min_n:
        return out
    out["mean"] = round(float(v.mean()), 3)
    for p, q in zip(percentiles, np.percentile(v, percentiles)):
        out[f"p{int(p)}"] = round(float(q), 3)
    return out


def share_below(values, limit):
    """Share of values strictly below `limit` (nan for an empty sample)."""
    v = np.asarray(values, float)
    return float((v < limit).sum() / len(v)) if len(v) else float("nan")


def fit_ratio(h, r):
    """Crown radius against height. Through-origin least squares r = k h (k = sum(h r) / sum(h^2)), the median and
    mean of r / h, and a free linear fit r = a + b h with its Pearson correlation."""
    h, r = np.asarray(h, float), np.asarray(r, float)
    ok = np.isfinite(h) & np.isfinite(r) & (h > 0)
    h, r = h[ok], r[ok]
    out = {"n": int(len(h))}
    if len(h) < 3:
        return out
    ratio = r / h
    b, a = np.polyfit(h, r, 1)
    out.update({
        "throughOrigin": round(float((h * r).sum() / (h * h).sum()), 4),
        "medianRatio": round(float(np.median(ratio)), 4),
        "meanRatio": round(float(ratio.mean()), 4),
        "rmsRatio": round(float(math.sqrt((ratio ** 2).mean())), 4),
        "linearSlope": round(float(b), 4),
        "linearIntercept": round(float(a), 4),
        "pearson": round(float(np.corrcoef(h, r)[0, 1]), 4),
    })
    return out


def mesh_radius_ratio(crown_weights, lobe_radius):
    """Mean crown radius per metre of tree height of the generator's meshes for the archetype mix:
    sum(weight x lobe radius x 1.15) / sum(weight); also the root-mean-square (what crown AREA follows)."""
    tot = sum(crown_weights.values())
    mean = sum(w * lobe_radius[k] * 1.15 for k, w in crown_weights.items()) / tot
    rms = math.sqrt(sum(w * (lobe_radius[k] * 1.15) ** 2 for k, w in crown_weights.items()) / tot)
    return mean, rms
