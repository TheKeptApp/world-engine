# Region kit

Drafts a regional style profile (`StyleProfile` version 2, exactly the schema in
`Sources/WorldGen/StyleProfile.swift`) per zone from open data, so adding a region is mostly
automatic and a person only has to review test pictures. Offline research tool: Python 3 standard
library only, not part of the engine or any app, nothing here is loaded at runtime.

Method, results and discussion: [`docs/research/region-kit.md`](../../docs/research/region-kit.md).
Current drafts: [`drafts/README.md`](drafts/README.md).

## How to run

The owner does not use Terminal; an agent runs these from the repository root.

| Command | What it does |
|---|---|
| `Tools/regionkit/regionkit.sh draft regions/chicagoland.json [--zone greystone]` | Drafts every zone of a region config (or one zone) |
| `Tools/regionkit/regionkit.sh draft --id REGION --zone ZONE --center LAT,LON --radius M --template ID [--reference ID]` | One ad-hoc cell (`--bbox S,W,N,E` instead of centre/radius also works) |
| `Tools/regionkit/regionkit.sh all` | Drafts every config in `regions/`, then writes `drafts/README.md` and `drafts/zone-signatures.json` |
| `Tools/regionkit/regionkit.sh compare` | Accuracy summary for every zone with a `reference` profile (writes `drafts/accuracy.json`) |
| `Tools/regionkit/regionkit.sh test` | Unit tests (no network) |
| `Tools/regionkit/regionkit.sh validate [FILE...]` | Validates profiles; without arguments: every engine/proposal profile and every draft |
| `Tools/regionkit/regionkit.sh floors regions/chicagoland.json --zone dense-north --profile chicago-dense-north` | Recalibrates an existing profile's `typeRules` unknown/small/large on a zone's cells with the drafting floor fit; prints before/after default floors, the measured truth, the residual and the new weights as JSON (writes nothing) |
| `Tools/regionkit/regionkit.sh anchors regions/X.json --write` | Resolves the named public anchors of a config (one batched Overpass query) and writes their centres |
| `Tools/regionkit/regionkit.sh find --bbox S,W,N,E --tag leisure=park` | Lists named public features to choose anchors from |
| `Tools/regionkit/regionkit.sh fetch regions/X.json` | Fetches (or confirms cached) data without drafting |

Environment: `REGIONKIT_CACHE` (cache directory; default `Tools/regionkit/.cache/`, git-ignored),
`REGIONKIT_OFFLINE=1` (no network at all), `REGIONKIT_NO_OVERPASS=1` (no Overpass, NOAA allowed),
`REGIONKIT_PROPOSALS_ROOT` (another checkout of this repository to read proposal folders that are not
committed in this one, read-only; not needed since `docs/proposals/regions-chicagoland-miami/` was committed
with the phase 5A merge).

## Adding a region

Write `regions/<region>.json`: `region`, `name`, `anchorSearch.bbox`, and `zones` (each: `id`, `name`,
`template` profile ID, optional `reference` profile ID to score against, `cells`). A cell is
`{"id", "anchor": {"name" | "names", "match", "near"}, "radiusMeters": 500}` (centre resolved by
`anchors --write`), or `{"id", "bbox": [S, W, N, E]}`, or `{"id", "center": [lat, lon], "radiusMeters"}`,
or `{"id", "localExtract": "Data/areas/<area>"}` (committed extract, read in place). A zone with
`poolZones` drafts from the cells of other zones. Places live only in these files, never in code.
Templates are resolved from `Sources/WorldGen/Profiles/<id>.json`, the `profiles` array of
`docs/proposals/regions-v1/regions-draft.json`, or `docs/proposals/regions-chicagoland-miami/profiles/<id>.json`
(all read in place, never copied or modified).

## Outputs (per zone, `drafts/<region>/<zone>/`)

- `profile.json`: the draft, schema-pure; passes the validator (which mirrors the Swift decoder).
- `measurements.json`: every statistic (zone and per cell), the climate normals and Koppen class,
  per-field provenance (status `calibrated` / `template` / `default`, sample size, source, template
  and measured values), OSM base timestamps, cell definitions and the exact Overpass queries,
  accuracy check and catalog check. Aggregates only, never per-building data.
- `report.md`: the confidence report (sample sizes, % missing per tag, what was calibrated vs kept,
  family signature hints, accuracy tables, what still needs a human eye).

## What it measures

Per cell and pooled per zone (definitions in `measurements.json` → `definitions`):
building counts by generator role (exact port of `BuildingGenerator.role(of:)`) and by `building=*`;
densities; `building:levels` / `height` / `roof:levels` distributions by role; metres per level;
`roof:shape` (raw and mapped to gabled/hipped/flat/slab), `roof:material`, `roof:colour`,
`building:material`, `building:colour` (normalised to colour families); footprint area, aspect and
rectangularity percentiles by role (port of `FootprintAnalysis` minimum-area rectangle and footprint
classes); house counts per generator situation; probable garages among generator houses;
residential / commercial / mixed-use share; facade-to-curb setback and long-side-to-street share
(port of `StreetContext.frontEdge`); lot-coverage proxies; alley density and alley adjacency;
fence / wall / hedge lengths; trees (density, leaf type and cycle from tags or genus, top genera,
heights, palm share); tag coverage. Climate: NOAA 1991-2020 monthly normals of the nearest station(s)
and a Koppen-Geiger class computed from them.

## Drafting rules

Template + calibration + shrinkage `(n * measured + k * template) / (n + k)`, `k = 30` (`--k`).
Gates: roof mix and tree leaf type/heights n >= 30, typeRules n >= 30 houses with levels, perFloor and
pitch n >= 20, colours n >= 30, garage roof n >= 20. Roof mixes are fitted by iterative proportional
fitting (zero weights stay zero); typeRules weights are scaled per default-floor group until the expected
default floors after the generator's eligibility filter match the size-stratified measured shares;
absolute thresholds use a percentile transfer from Denver's Sloan's Lake houses. Every draft also gets the
relative thresholds `typeThresholds.smallAreaPercentile` / `largeAreaPercentile` / `hugeAreaPercentile` =
0.02 / 0.865 / 0.99 (owner decision: thresholds relative to the local houses; Denver calibration
0.021 / 0.865 / 0.990, rounded), unless the template already has them; the absolute m² values stay as the
fallback for areas with fewer than 30 house candidates. `floors` applies the same floor fit to an existing
profile, splitting area classes with the profile's relative thresholds (quantiles of the zone's principal
houses) where present. The committed `drafts/` predate the relative thresholds; the next `all` run writes
them. Details and caveats: `docs/research/region-kit.md`.

## Tests

`regionkit.sh osmclip Data/areas/<id>...` clips relations with 300 or more members in an area's `osm.json`
to its context-ring box and `regionkit.sh areacheck` checks every area's `osm.json` against the size
budget (see `docs/data/area-size-budget.md`).

`regionkit.sh test` runs `tests/` (Python `unittest`, no network): Overpass JSON parsing and
multipolygon assembly on synthetic fixtures; polygon area, centroid, clipping, rasterised union areas;
minimum-area rectangle, aspect, rectangularity and footprint classes (ported Swift test cases);
`role()` / `situation()` / eligibility / tag-parsing parity with the Swift rules; shrinkage, IPF and the
floor-group fit; relative thresholds and the `floors` check; Koppen on O'Hare normals and constructed cases;
validator on every known profile plus broken variants and the optional fields (`trees.canopyShare` and the
area percentiles: types, 0-1 ranges, small < large < huge; `provenance` as a documentation key); cache keys
and offline cache hits; an end-to-end measurement of a synthetic cell.

## Data sources and licences

- **OpenStreetMap** via the Overpass API (`https://overpass-api.de/api/interpreter`, fallback
  `https://overpass.private.coffee/api/interpreter`). Data (c) OpenStreetMap contributors, Open Database
  License 1.0 (https://www.openstreetmap.org/copyright). All statistics in `drafts/` are derived from
  OSM and must carry the attribution **"© OpenStreetMap contributors"**. Queries use `out body` /
  `out center` / `out bb` / `out tags` only (never `out meta`: no contributor names, IDs or
  timestamps); one request at a time, identifying User-Agent, >= 5 s between requests, a status check
  before each request, >= 60 s back-off on HTTP 429/504, every response cached by a hash of the query.
  The Denver check reads the committed extract `Data/areas/sloans-lake/osm.json` in place.
- **NOAA NCEI U.S. Climate Normals 1991-2020, monthly**: station inventory
  `https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/doc/inventory_30yr.txt`, per-station CSV
  `https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/access/<STATION>.csv` (deg F, inches).
  NOAA's dataset metadata (gov.noaa.ncdc:C01620) asks users to cite Palecki, M., Durre, I., Applequist, S.,
  Arguez, A., Lawrimore, J. (2021), U.S. Climate Normals 2020: U.S. Monthly Climate Normals (1991-2020),
  NOAA NCEI, https://doi.org/10.25921/wck8-er13, and states use/distribution liability disclaimers
  (no warranty); it states no licence restriction. Only derived monthly means are stored.
- Lookup tables in `data/` (genus habit, colour names, materials, use classes) are hand-written
  assumptions, documented in each file.

Raw downloads stay in the cache and are never committed.
