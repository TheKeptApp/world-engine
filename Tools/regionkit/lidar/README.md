# Lidar roof-form pilot (USGS 3DEP)

Pilot: roof forms (flat, gable, hip, complex; pitch and ridge direction) from USGS 3DEP lidar for every OSM
building footprint of a committed test area, compared with the roof forms the generator assigns. Offline
research tool for the region kit; not part of the engine or any app, and nothing here is loaded at runtime.

Results, accuracy and the recommendation: [`docs/research/lidar-roofs.md`](../../../docs/research/lidar-roofs.md).

## How to run

The owner does not use Terminal; an agent runs these from the repository root. The work directory must be
outside the repository (the tool refuses one inside it). A first run reads about 118 MB of lidar (EPT octree
nodes that meet the area box, depth ≤ 10) plus about 75 MB of Python wheels.

```sh
UV_CACHE_DIR=/tmp/lidar-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
  --with numpy --with scipy --with shapely --with pillow --with rasterio --with "laspy[lazrs]" \
  python Tools/regionkit/lidar/lidar.py all --work /tmp/lidar-work
```

`all` needs a built `worldbake` (`swift build -c release --product worldbake`; otherwise it falls back to
`swift run`). Tests (offline; numpy, scipy, shapely):

```sh
UV_CACHE_DIR=/tmp/lidar-uv uv run --no-project --python python3 --with numpy --with scipy --with shapely \
  python -m unittest discover -s Tools/regionkit/lidar/tests -v
```

| Subcommand | What it does | Writes |
|---|---|---|
| `plan` | EPT hierarchy for the area box: nodes, points and estimated density per depth | work dir |
| `fetch [--max-depth N]` | Reads the octree nodes that meet the area box (LAZ over HTTPS from the public `usgs-lidar-public` bucket), byte ledger, cap in `data/pilot.json` | work dir |
| `classify` | Per OSM footprint: building-class points in the eroded footprint → region growing on normals → plane raster → `classify_roof`. One global lidar-to-footprint shift. Also counts building-class clusters outside every footprint | per-building values: work dir only |
| `p2 [--commit SHA]` | `worldbake export` of the area with the generator's profile (the commit recorded defaults to the checkout's HEAD); per building: `scene.json` roofShape and role, and the same raster and classifier run on the generated roof triangles (lod0 chunk GLBs) | work dir only |
| `compare` | Agreement tables (simple form, four classes, complex flag), roof mixes, pitch, ridge direction, by role | `results/comparison.json` |
| `handcheck` | Stable sample (30) of point-cloud images (facet-coloured height surface, footprint outline, two side views) for blind labelling. Shows no classifier output | work dir only |
| `score` | Hand labels (`handcheck_labels.json` in the work dir) vs the classifier | `results/handcheck.json` |
| `vintage --naip TIF` | Lidar-vs-OSM mismatches (footprints with no lidar roof; lidar buildings outside OSM), each checked for a non-vegetated surface in a NAIP scene (e.g. the GeoTIFF that `aerial/canopy_areas.py fetch` leaves in its work dir) | `results/vintage.json` |

## Heights: Overture building heights vs lidar

`heights.py` compares the `height` of every Overture building record of a committed area (and which dataset
supplied it) with the building height the same lidar gives: ground = median class-2 point in a 3-8 m ring,
top = p95 of class-6 points in the footprint eroded by 0.5 m, eave = p15 of class-6 points 0.5-2 m inside the
edge. Reuses `lidar.py` (EPT reader, ground model, global shift). About 131 MB of lidar for 1 km². Method,
results and the data-side rule: [`docs/research/overture-source.md`](../../../docs/research/overture-source.md),
section "Heights vs lidar". Thresholds (set before comparing): `data/heights.json`. Aggregates only:
`results/heights-wilmette.json`.

```sh
UV_CACHE_DIR=/tmp/lidar-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
  --with numpy --with scipy --with shapely --with rasterio --with "laspy[lazrs]" \
  python Tools/regionkit/lidar/heights.py all --work /tmp/heights-work
```

Subcommands: `plan` (EPT nodes and their sizes by HTTP HEAD, no body), `fetch`, `measure` (per record, work
directory only), `compare` (aggregates), `all`. Tests: `tests/test_heights.py`.

## Files

- `lidar.py`: pipeline (network, LAZ, footprints, package reading, images).
- `roofplanes.py`: pure functions (Web Mercator and local-frame conversions, EPT node bounds, plane fits,
  point normals, region growing, plane rasters, upper envelope of a triangle soup, minimum-area rectangle, the
  roof classifier, global shift, Wilson intervals, kappa, stable sampling). Tested in `tests/test_roofplanes.py`
  with synthetic gable, hip, flat and cross-gable roofs as point clouds.
- `data/pilot.json`: area (a committed test area, read-only), profile, EPT dataset and byte cap.
- `data/params.json`: every threshold (erosion, region growing, raster, classifier, vintage, hand-check sample,
  privacy floor), set before the hand check and before comparing with the generator.
- `results/`: aggregates only (`comparison.json`, `handcheck.json`, `vintage.json`). No building IDs, no
  per-building values, no geometry; any distribution over fewer than 5 buildings (`minGroupN`) is replaced by its
  count.

## Privacy

Per-building classifications, point clouds, images and hand labels never enter the repository: they live in
the work directory, which `lidar.py` refuses inside the repository. `.gitignore` blocks point clouds, images
and GLBs here as a backstop. Delete the work directory when done.

## Credits

Lidar: U.S. Geological Survey, 3D Elevation Program (3DEP), project IL_4_County_QL1_LiDAR_2016_B16, via the
`usgs-lidar-public` Entwine Point Tiles (Hobu, Inc., AWS Open Data); US Government public domain (AWS Open Data
registry entry). Footprints © OpenStreetMap contributors (ODbL 1.0). NAIP imagery (vintage check) provided by
USDA Farm Service Agency.
