# Map data coverage audit

Measures what OpenStreetMap and Overture Maps provide for 3-D buildings and trees in 46 sample cells (1 km × 1 km around named public places), and estimates the triangles the current generator would produce for dense Chicago cells. Findings: [`docs/research/data-coverage.md`](../../../docs/research/data-coverage.md).

## Re-run (one command)

```
uv run --with duckdb==1.5.6 python3 Tools/regionkit/audit/audit.py all --dense loop-daley-plaza river-north-montgomery-ward-park lincoln-park-oz-park edgewater-broadway-armory-park
```

Every response is cached in `Tools/regionkit/audit/.cache/` (git-ignored; `--cache DIR` or `$AUDIT_CACHE` moves it), so a second run downloads nothing. Delete the cache to re-fetch current data. `audit.py bytes` prints what was downloaded.

Optional: `--zone-profiles DIR` adds a comparison with proposed zone profiles (a folder holding `region-catalog.json` and `profiles/*.json`, such as the Chicagoland/Miami proposal).

## Steps

| Step | Does | Network |
|---|---|---|
| `resolve` | Finds each cell's anchor: one batched Overpass query per metro, `out center tags`, centre rounded to 4 decimals, box ±500 m. Writes `center`/`osm`/`resolved` into `cells.json`. Same rule as `Tools/regionkit` (cells line up). | Overpass |
| `osm` | Per cell: buildings and `building:part`s (ways + `type=multipolygon` relations, `out geom` so relations carry their member geometry) and `natural=tree` / `tree_row` counts (`out count`). Engine rule (`MapFeatureBuilder`): one building per closed way and one per assembled outer polygon, each counted when its own centroid (raw outer ring) lies in the exact ±500 m local rectangle; no de-duplication of a way that is also a relation outer (counted in `dupWayAlsoRelationOuter`); `type=building` relations are not counted. Overpass responses with data older than 3 days (stale mirrors) are rejected. | Overpass |
| `overture` | Per cell: Overture buildings from the public GeoParquet, latest release (`OVERTURE_RELEASE` in `audit.py`). Files are chosen from the release's STAC collection (per-file bounding boxes), then DuckDB reads only the row groups whose `bbox` statistics meet the cell, in one session. Needs `duckdb`. | STAC + S3 range reads |
| `tris` | Triangle-count model (`trimodel.py`, a port of the generator's counting rules), checked against the recorded Sloan's Lake numbers, then applied to every cell (buildings only) and to the `--dense` cells as full worlds (ground, curbs, props, view and shadow estimates). Local only, except one extra Overpass query per dense cell for roads/areas/trees/lamps. | Overpass (dense cells) |
| `report` | `results/cells.csv`, `main_table.md`, `detail_table.md`, `summary.json` (`bytes` writes `downloads.json`). | none |

## Files

- `cells.json`: the cell list (data). Anchor rule, names, tag filters, `why` for each choice, resolved centres.
- `audit.py`: the steps above. Standard library only, except `duckdb` for `overture`.
- `trimodel.py`: triangle counting (ports `StableRandom`, `FootprintAnalysis`, the building, roof, opening, curb, sidewalk and lamp rules; tree meshes as of phase 5A, with the earlier costs kept as `TREE_TRIS_PRE_5A`).
- `results/`: aggregate numbers only (no geometry, no raw data): `osm_metrics.json`, `overture_metrics.json`, `triangles.json` (calibration incl. the phase 5A gate-run check, every cell's building triangles, the dense worlds), `summary.json` (tiers and the overall figures quoted in the report), `downloads.json` (bytes per kind), `cells.csv`, `main_table.md`, `detail_table.md`.

## Etiquette and privacy

- Overpass: one request at a time, User-Agent `WorldEngine-regionkit/0.1 (offline research tool)`, ≥ 5 s between requests, status check for a free slot first, ≥ 60 s back-off on 429/504, primary `overpass.private.coffee`, fallback `overpass-api.de` (an endpoint that doesn't answer its status page is skipped for 10 minutes). Never `out meta`.
- Overture: only each cell's bounding box is read (HTTP range requests); no whole files.
- Cells are centred on public places; results are per-cell aggregates. Nothing identifies a private address.
- Data licences: OSM © OpenStreetMap contributors, ODbL 1.0. Overture buildings theme: ODbL 1.0 (it contains OSM). Raw data is never committed.
