#!/usr/bin/env python3
"""Cuts a NASA Black Marble annual tile (VNP46A4, HDF5) to a box plus a margin and writes GDAL-style XYZ text
("lon lat value" per cell centre) for `Tools/livefeeds/livefeeds.sh sky-radiance`.

    python3 black_marble_xyz.py OUT.xyz TILE.h5 [TILE.h5 ...] --bbox S,W,N,E [--margin-km 50] [--block 2]
        [--layer NearNadir_Composite_Snow_Free]

Needs h5py and numpy (bake-time only, e.g. in a scratch venv; the relay itself stays standard-library).
--block N averages N x N native 15-arc-second cells (fill cells ignored; all-fill blocks stay fill), so 2 gives a
30-arc-second grid (about 0.9 km), which keeps each area's JSON small while staying far finer than the 50 km
skyglow kernel. Fill (-999.9) is written as 65535 so grid_from_xyz turns it into null. Several tiles are
mosaicked on the shared 15-arc-second grid; the box plus margin must be covered (10 x 10 degree tiles: Chicago
h09v04; Denver h07v05 + h07v04, it crosses 40 N; Miami h09v06 + h10v06, it crosses 80 W). Cells not covered by
any given tile are an error, not silently filled.
"""
import argparse
import math

import h5py
import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument("out")
ap.add_argument("tiles", nargs="+")
ap.add_argument("--bbox", required=True, help="S,W,N,E in degrees")
ap.add_argument("--margin-km", type=float, default=50.0)
ap.add_argument("--block", type=int, default=2)
ap.add_argument("--layer", default="NearNadir_Composite_Snow_Free")
a = ap.parse_args()

s, w, n, e = (float(x) for x in a.bbox.split(","))
dlat_m = a.margin_km / 111.32
dlon_m = a.margin_km / (111.32 * math.cos(math.radians((s + n) / 2)))
s, n, w, e = s - dlat_m, n + dlat_m, w - dlon_m, e + dlon_m

STEP = 15.0 / 3600.0
# Global 15" cell indices of the box (cell centres sit at half steps from the tile edges).
r_lo, r_hi = math.floor((90.0 - n) / STEP), math.ceil((90.0 - s) / STEP)
c_lo, c_hi = math.floor((w + 180.0) / STEP), math.ceil((e + 180.0) / STEP)
b = a.block
nr, nc = ((r_hi - r_lo) // b) * b, ((c_hi - c_lo) // b) * b
v = np.full((nr, nc), np.nan)
covered = np.zeros((nr, nc), dtype=bool)
layer = None
for path in a.tiles:
    f = h5py.File(path, "r")
    g = f["HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields"]
    ds = g[a.layer]
    fill = float(ds.attrs["_FillValue"][0])
    scale = float(ds.attrs.get("scale_factor", [1.0])[0])
    tr0 = int(round((90.0 - g["lat"][0]) / STEP - 0.5))
    tc0 = int(round((g["lon"][0] + 180.0) / STEP - 0.5))
    rr0, rr1 = max(r_lo, tr0), min(r_lo + nr, tr0 + ds.shape[0])
    cc0, cc1 = max(c_lo, tc0), min(c_lo + nc, tc0 + ds.shape[1])
    if rr0 >= rr1 or cc0 >= cc1:
        continue
    x = ds[rr0 - tr0:rr1 - tr0, cc0 - tc0:cc1 - tc0].astype(np.float64)
    v[rr0 - r_lo:rr1 - r_lo, cc0 - c_lo:cc1 - c_lo] = np.where(x == fill, np.nan, x * scale)
    covered[rr0 - r_lo:rr1 - r_lo, cc0 - c_lo:cc1 - c_lo] = True
if not covered.all():
    raise SystemExit("box plus margin is not covered by the given tiles")
blocks = v.reshape(nr // b, b, nc // b, b)
with np.errstate(invalid="ignore"):
    mean = np.nanmean(blocks, axis=(1, 3))
blat = 90.0 - (r_lo + np.arange(nr // b) * b + b / 2.0) * STEP
blon = -180.0 + (c_lo + np.arange(nc // b) * b + b / 2.0) * STEP
with open(a.out, "w") as out:
    for i, la in enumerate(blat):
        for j, lo in enumerate(blon):
            x = mean[i, j]
            out.write("%.9f %.9f %s\n" % (lo, la, "65535" if np.isnan(x) else "%.2f" % x))
print("%d x %d cells, layer %s, box %.4f,%.4f,%.4f,%.4f" % (len(blat), len(blon), a.layer, s, w, n, e))

