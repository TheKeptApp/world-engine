# Terrain slope grids (USGS 3DEP lidar)

Per-area 1 m terrain slope grids from USGS 3DEP lidar ground points, so the engine can report, for example,
the steepest lawn slope in a yard. Offline research tool for the region kit; not part of the engine or any
app. Writes `Data/areas/<id>/terrain-slope.bin` and `terrain-slope.json`; point clouds, DEM windows and
intermediate grids stay in the work directory, which the tool refuses inside the repository.

## How to run

The owner does not use Terminal; an agent runs these from the repository root. Data fetches need no heavy-job
lock. A full run reads about 615 MB of lidar (Evanston 290 MB, Lakeview 272 MB, Sloan's Lake 52 MB; full EPT
depth) plus about 5.6 MB of 1 m DEM per area for `validate` (windowed COG reads, block-size estimate).

```sh
UV_CACHE_DIR=/tmp/lidar-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
  --with certifi --with numpy --with scipy --with rasterio --with "laspy[lazrs]" \
  python Tools/regionkit/terrain/slope.py all --work /tmp/claude-terrain-work
```

Delete the work directory when done. Tests (offline; numpy and scipy only):

```sh
UV_CACHE_DIR=/tmp/lidar-uv uv run --no-project --python python3 --with numpy --with scipy \
  python -m unittest discover -s Tools/regionkit/terrain/tests -v
```

| Subcommand | What it does |
|---|---|
| `plan` | EPT octree nodes that meet each area box (+10 m), points per depth, node sizes by HTTP HEAD; picks the full depth if it fits the per-area byte cap (600 MB) |
| `fetch [--allow-partial]` | Reads those nodes as LAZ over HTTPS from the public `usgs-lidar-public` bucket. Stops if full density would exceed the cap unless `--allow-partial` |
| `grid` | Ground points -> DTM -> slope -> uint8 codes; split-sample check; building/water occupancy for the validation mask |
| `validate` | Compares with the USGS 3DEP 1 m DEM of the same lidar project (TNM API lookup, windowed reads of the public prd-tnm COGs) |
| `emit` | Writes the `.bin` and `.json` into `Data/areas/<id>/` |
| `all` | All of the above |

`--areas id …` limits any step to some areas. Areas, EPT projects, metadata and caps: `data/areas.json`.

## Method

1. Ground points: vendor classification 2, every EPT depth (full density), inside the area box plus 10 m,
   converted to the area's local frame with the exact WGS84 ENU math of the engine's `LocalFrame`
   (`roofplanes.local_en`).
2. DTM on a 1 m grid covering x in [-width/2, width/2], y in [-height/2, height/2]: mean z of the ground
   points in each cell. Empty cells: inverse-distance weighting (power 2, up to 12 neighbours) of ground points
   within 2 m of the cell centre. No ground point within 2 m: no data (buildings, water, never invented).
3. 3x3 mean over the valid cells of each window (no-data cells stay no-data), then Horn 3x3 slope,
   slope % = 100 |grad z|. Any no-data cell in the Horn window (centre included) or the grid edge gives no data.
4. Encoding: `floor(slope% x 2 + 0.5)` capped at 253 for slopes below 127 %, 254 for >= 127 %, 255 for no
   data. Row-major, row 0 = southernmost row (y from -height/2), column 0 = westernmost. Raw DEFLATE (no zlib
   header), which Apple's Compression framework (`COMPRESSION_ZLIB`) reads directly.

## Header (`terrain-slope.json`)

Pretty-printed, sorted keys, final newline. Fields: `format` (`worldengine-slope-grid-v1`), `frame.origin`
(manifest centre), `cellM`, `minX`, `minY`, `cols`, `rows`, `encoding`, `quantization`, `binFile`,
`binSha256`, `binBytes`, `method`, `source` (id, title, attribution, license, licenseURL, EPT url,
collection dates, quality level, vertical accuracy from project metadata), `groundPointsPerM2`,
`noDataShare`, `validation`.

## Validation

`validation.vsReference1mDEM`: the encoded slope against the same 3x3 mean + Horn slope of the USGS 3DEP 1 m
DEM (bilinear-sampled at our cell centres), on cells at least 2 m from lidar building (6) or water (9) points;
median and 90th-percentile absolute difference in percentage points and the share within 2 and 5 points, split
at 15 % (by the DEM slope). The DEM is made from the same lidar, so this measures the gridding method, not the
lidar's own accuracy. `heightMedianOffsetM`, `heightResidualMadM` and `bestIntegerShiftCells` check that the
two grids line up. `validation.splitSample`: slopes rebuilt from alternate halves of the ground points (each at
half density), an upper bound on point-noise error, split by our own slope.

## Credits and licence

Lidar and DEM: U.S. Geological Survey, 3D Elevation Program; public domain ("Map services and data downloaded
from The National Map are free and in the public domain", USGS FAQ on terms of use; AWS Open Data registry
entry `usgs-lidar`: "US Government Public Domain"). USGS requests the acknowledgement "Data available from U.S.
Geological Survey, National Geospatial Program." Entwine Point Tiles by Hobu, Inc. on AWS Open Data. See
`docs/research/licensing.md` row N2.
