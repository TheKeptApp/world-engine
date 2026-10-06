# Aerial roof study (NAIP)

Feasibility study: can public aerial imagery (USDA NAIP, 4-band, leaf-on) give the generator roof colours,
roof types and tree canopy? Offline research tool for the region kit; not part of the engine or any app, and
nothing here is loaded at runtime.

Results, accuracy and the recommendation: [`docs/research/aerial.md`](../../../docs/research/aerial.md).
Short version: canopy per block works. Roof colour is usable only as a profile-level lightness mix, and it
underestimates warm (brown/tan) roofs. The roof-type guess has not been shown to beat a constant guess, so it is
not used per building.

## How to run

The owner does not use Terminal; an agent runs these from the repository root. One command. On the first run
it downloads about 23 MB of data, about 50 MB of Python wheels and DuckDB's `httpfs` extension (16 MB on disk),
all cached outside the repository:

```sh
UV_CACHE_DIR=/tmp/aerial-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
  --with numpy --with pillow --with shapely --with rasterio --with duckdb \
  python Tools/regionkit/aerial/aerial.py all --work /tmp/aerial-work
```

`all` = `fetch` + `analyse` (+ `score` if hand labels exist in the work directory). Use a Python that has
wheels for these packages (3.12 to 3.14 work). Tests (offline, numpy only):

```sh
UV_CACHE_DIR=/tmp/aerial-uv uv run --no-project --python python3 --with numpy \
  python -m unittest discover -s Tools/regionkit/aerial/tests -v
```

| Subcommand | What it does | Writes |
|---|---|---|
| `fetch` | One Overpass request (OSM buildings and street centrelines, `out body geom`), Overture buildings for the cell (DuckDB over the release's GeoParquet file picked through the Overture STAC catalog, bbox-filtered), and a windowed NAIP read (COG byte ranges via GDAL `/vsicurl/`, anonymous Planetary Computer SAS token). Byte ledger. | work dir |
| `analyse` | Footprint merge, one global footprint-to-image shift, per-building colour and roof-type estimates, a 0.6 m degraded rerun, canopy mask, block faces, aggregates | per-building values: work dir only; aggregates: `results/summary.json` |
| `crops [--set A\|B]` | Stable random sample (30, at least 5 OSM) and crops with the footprint outline (RGB, RGB + outline, colour infrared) for hand labelling. Shows no estimate. | work dir only |
| `points` | 100 stable random points as 15 m contact sheets with a crosshair, for a photo-interpreted canopy check | work dir only |
| `score` | Compares the hand labels (`labels.json`, `labels_B.json`, `points_labels.json` in the work dir) with the estimates | `results/accuracy.json` |

**Canopy of the committed test areas** (phase 5B, for the profiles' `trees.canopyShare`):
`canopy_areas.py fetch | analyse | points | score --work DIR [--only AREA ...]`. It reads each area listed in
`data/canopy_areas.json` (committed `Data/areas/*`: manifest rectangle, streets, parks and water from its
`osm.json`; no Overpass request). It fetches the newest NAIP window, mosaicking quarter-quads when one doesn't
cover the area (about 55 MB per km² at 0.3 m). It applies the unchanged canopy mask and writes area, land,
residential-fabric and block shares to `results/canopy_areas.json`. `points` makes 50 stable random points per
area as contact sheets for a photo check; `score` reads `areas/<id>/points_labels.json` (`{"P01": "tree" |
"not" | "?"}`) from the work dir. Same command line as above, with `canopy_areas.py` in place of `aerial.py`.

`canopy_areas.py blocks --work DIR` (after `fetch`) writes `Data/areas/<id>/canopy-blocks.json`: per-block canopy
share, tree counts, spacing and confidence (format: `docs/research/aerial.md` 13.9; pure functions in `blockmath.py`).
Areas with a `calibration` entry in `data/canopy_areas.json` (wilmette, winnetka, kenilworth) use a calibrated effective
crown area and method version `canopy-blocks 2` (`docs/research/aerial.md` 13.10).

The work directory defaults to `$AERIAL_WORK` or `<system temp>/worldengine-aerial`; the tool refuses a work
directory inside the repository. Delete it when done: it holds imagery, crops, per-building estimates and labels.

## Files

- `aerial.py`: pipeline (network, raster and geometry I/O).
- `roofcore.py`: pure functions (colour conversion and families, minimum-area rectangle and shape features,
  facet models and the roof-type heuristic, NDVI, canopy mask, morphology, stable sampling, confusion
  matrices). Unit-tested in `tests/test_roofcore.py`.
- `data/cell.json`: the study cell (500 m square centred on a public park, as in `regions/chicagoland.json`)
  and data endpoints, pinned Overture release.
- `data/roof_families.json`: colour families as data. Rule set 1 (absolute L\*a\*b\* rules, written before any
  labelling, plus one dark-cast rule added before scoring) and rule set 2 (`sceneRelative`: chroma and hue
  relative to the scene's median roof colour), plus suggested render colours per family.
- `data/params.json`: every threshold (footprint erosion, vegetation and shadow masks, roof heuristic, canopy
  texture, sample sizes and seeds, hint confidence thresholds).
- `canopy_areas.py`, `data/canopy_areas.json`, `results/canopy_areas.json`: canopy per committed test area
  (phase 5B); area and block aggregates and the point-check counts, no imagery or masks.
- `results/summary.json`, `results/accuracy.json`: aggregates only. No building IDs, no per-building values,
  no geometry. Any colour or distribution statistic over fewer than 5 buildings (`minGroupN`) is replaced by
  its count only.

## Privacy

Per-building estimates, crops and hand labels never enter the repository. The protection is the work
directory: `aerial.py` refuses one inside the repository, and everything per-building is written there.
`.gitignore` is only a backstop, and it applies within this directory only. It blocks image, raster and mask
files (`*.png`, `*.tif`, `*.npy`) and `__pycache__`. It does not catch per-building JSON, so never point
`--work` into the repository. Results are distributions, accuracy tables and per-block canopy shares without
geometry, with the n < 5 floor above. `docs/research/aerial.md` describes the format a per-building hint layer
could take; none is produced.

## Credits

NAIP imagery provided by USDA Farm Service Agency (public domain). Building footprints and streets
© OpenStreetMap contributors (ODbL 1.0); Overture Maps Foundation buildings, Microsoft ML Building
Footprints (ODbL 1.0).
