# Overture buildings as a second footprint source

Owner decision (2026-10-06): use Overture's buildings theme as a second footprint source. OSM is
preferred wherever both have a building; Overture fills the gaps. Every required credit is added.
Background: [data-coverage.md](data-coverage.md) (the North Shore has almost no OSM houses; all the
extra footprints come from Microsoft ML Buildings) and [licensing.md](licensing.md) (O12, V1).

Code: `Sources/WorldMap/OvertureSource.swift` (format, merge, identity, credits),
`Sources/worldbake/OvertureFetcher.swift` and `scripts/data/fetch_overture.py` (fetch). Tests:
`Tests/WorldMapTests/OvertureTests.swift`.

## Fetching

```bash
swift run worldbake fetch Data/areas/<area> --layers overture            # latest release
swift run worldbake fetch Data/areas/<area> --layers overture --release 2026-09-23.1
```

- **One command.** `worldbake` runs `uv run --script scripts/data/fetch_overture.py`. The helper
  declares its one dependency (`duckdb==1.5.6`) inline, so uv installs DuckDB into its own cache the
  first time; nothing is installed system-wide. Needs [uv](https://docs.astral.sh/uv/) on the
  PATH or in one of `~/.local/bin`, `~/.cargo/bin`, `/opt/homebrew/bin` and `/usr/local/bin`. DuckDB's `httpfs` extension goes to `$WORLDBAKE_CACHE/duckdb-extensions`
  when `WORLDBAKE_CACHE` is set, else to DuckDB's default directory.
- **What is read.** The release is the `latest` entry of the STAC catalog
  (`https://stac.overturemaps.org/catalog.json`) unless `--release` is given. From the release's
  `buildings/building` collection, only the GeoParquet files whose STAC box meets the area's box are
  opened. DuckDB `read_parquet` filters on the `bbox` column, so only the matching row groups are
  downloaded: about 4 MB of GeoParquet and 0.1 MB of STAC JSON per 1 km² area (the reference for the
  file selection is the `overture` step of `Tools/regionkit/audit/audit.py`).
- **Left out at fetch time:** underground buildings (`is_underground = true`) and the separate
  `building_part` collection. The owner decision covers buildings, and OSM `building:part`s already
  come from the OSM source.
- **Written:**
  1. `overture-buildings.json` in the area directory (format below).
  2. A manifest source:
     - `format` `overture-buildings-v1`, `path` `overture-buildings.json`, `layers` `["buildings"]`, `license` `ODbL-1.0`;
     - `attribution` built from the datasets in the file (see Credits);
     - `dataTimestamp` = the Overture release;
     - `fetchedAt`, `bytes`, `sha256` as for OSM sources.
     Re-fetching replaces the source.
  3. An `## Overture buildings` section in the area's `NOTICE.md` (replaced on re-fetch; the file is
     created if missing).
- The same release and box give byte-identical files.
- HTTP requests identify the tool (`WorldEngine-worldbake/0.1`). DuckDB's own user agent is kept and
  the tool name is appended.

## File format `overture-buildings-v1`

One JSON object. The header comes first, then `buildings` with one record per line, sorted by GERS ID.

| Key | Meaning |
|---|---|
| `format` | `"overture-buildings-v1"` |
| `release` | Overture release, e.g. `"2026-09-23.1"` |
| `theme`, `type` | `"buildings"`, `"building"` |
| `license` | Theme licence from the STAC collection (`"ODbL-1.0"`) |
| `bbox` | The queried box (`south`, `west`, `north`, `east`); records whose bbox meets it are included |
| `files` | GeoParquet files that were read |
| `datasets` | Every dataset named in any record's `sources`: `dataset`, `license` (as Overture gives it, if any), `records` |
| `buildings[]` | Records (below) |

| Record key | Meaning |
|---|---|
| `id` | GERS ID (a UUID string in current releases) |
| `polygons` | GeoJSON MultiPolygon coordinates: polygons → rings (outer first, then holes, closed) → `[lon, lat]`, 7 decimals |
| `height`, `min_height` | Meters, rounded to 1 cm (omitted when absent) |
| `num_floors` | Integer (omitted when absent) |
| `roof_shape` | Overture value, same vocabulary as OSM `roof:shape` (omitted when absent) |
| `class`, `subtype` | Overture building class and subtype (omitted when absent) |
| `sources[]` | `dataset`, plus `record_id` and `property` (JSON pointer such as `/properties/height`) when Overture has them; no `property` means the geometry source |

The file keeps every record in the box, including those with an OpenStreetMap source. The loader
drops those records. Keeping them makes the file a plain extract and leaves room for a later,
separate decision on Overture heights for OSM buildings (licensing O12).

## Merge rules (`AreaLoader.loadFeatures`)

`AreaLoader.loadDocument` skips `overture-buildings-v1` sources; it still throws for unknown formats.
After `MapFeatureBuilder.build`, `OvertureBuildings.merge` reads every Overture source of the
manifest. It processes the records of each file in GERS ID order (the order is per file, not global
across sources); an ID already seen in an earlier source is skipped.

1. A record with any `OpenStreetMap` source is dropped (OSM already has the building).
2. For each polygon of a remaining record:
   1. The centroid must lie inside `manifest.localBounds`. Buildings are kept whole, as for OSM.
   2. The centroid must not lie inside any OSM `building` or `building:part` footprint in the OSM
      document. This includes OSM buildings whose own centroid is outside the area: if one of those
      overlaps the area edge, an Overture copy of it is not drawn.
   3. The footprint is cleaned like an OSM footprint (`Polygon2D.cleaned(minArea: 1.0)`: closing point
      dropped, near-duplicate and collinear points removed, outer ring CCW, holes CW). A footprint that
      doesn't survive is reported in `LoadReport.skipped` as "degenerate footprint".
3. The surviving polygons become `Building`s with `isPart = false`. They are appended after all OSM
   buildings, so OSM features and their order are unchanged. A MultiPolygon record gives one building
   per polygon, all with the same ref.

`LoadReport.overture` counts the records read, dropped (OSM source, inside OSM, outside the area),
unusable, added, and the buildings appended. `worldbake stats` prints these counts. Without an
Overture source nothing is read and loading is exactly as before (regression tests on the fixture,
`sloans-lake` and `evanston-south`).

Reproduced on the committed Wilmette area (`wilmette-vattmann-park`): 1,279 records − 49 OSM-sourced −
0 inside OSM − 18 outside the area = 1,212 added. No added footprint has a vertex inside an OSM
footprint (0 vertex overlaps), and none contains an OSM centroid (0). So the centroid rule is enough
there, as the audit found for 45 of 46 cells.

## Tags and heights

| Tag | From |
|---|---|
| `building` | `class` mapped to an OSM value (`semi` → `semidetached_house`, `bridge_structure` → `bridge`, `dwelling_house` → `house`; every other Overture class already is an OSM value), else `yes` |
| `height` | `height` (m) |
| `min_height` | `min_height` (m) |
| `building:levels` | `num_floors` |
| `roof:shape` | `roof_shape` |
| `overture:id` | Full GERS ID |
| `overture:sources` | Distinct datasets, comma-joined, in source order |

Heights go through the same `HeightRules.resolve` call as OSM buildings: tag, then levels, then
type default with the seeded jitter. There is no Overture-specific height code, and custom rules
passed to `loadFeatures` apply to both sources.

## Identity

- `OSMRef.Kind.overture`. Its `random()` kind code is 4 (node 1, way 2, relation 3).
- `id` = the first 16 hex digits of the GERS ID (hyphens ignored), parsed as `UInt64` and stored
  with `Int64(bitPattern:)`. IDs can be negative. `description` is `overture/<id>`. This is the
  feature ID in packages (`scene.json`) and the seed for all generated detail.
- Current GERS IDs are random UUIDs (60 random bits in the first 16 hex digits), so collisions inside
  one area are practically impossible. If two IDs in one load share their first 16 hex digits, the
  first in ID order wins and the other is reported as skipped.
- The ref is as stable as the GERS ID. GERS IDs are meant to stay the same across releases, so a
  re-fetch should keep the seeds. This was not checked across releases here.

## Credits

The manifest `attribution` is `© OpenStreetMap contributors, Overture Maps Foundation` (Overture's
own line for OSM-based data) followed by a credit for each non-OSM dataset in the file, sorted and
separated by `; `. Wording follows [Overture's attribution page](https://docs.overturemaps.org/attribution/#buildings)
(checked 2026-10-06; page footer "Last updated on May 15, 2026").

| Overture `dataset` | Credit |
|---|---|
| `Microsoft ML Buildings` | Microsoft Global ML Building Footprints (ODbL) |
| `Esri Community Maps` | Esri Community Maps contributors (CC BY 4.0) |
| `Google Open Buildings` | Google Open Buildings (CC BY 4.0) |
| `USGS Lidar` | USGS 3D Elevation Program (listed by Overture with no licence or wording) |
| anything else | `<dataset> (<licence from the file>)`; `worldbake fetch` prints a note to add proper wording to `OvertureBuildings.datasetCredits` |

The dataset names `Microsoft ML Buildings`, `USGS Lidar` and `OpenStreetMap` were seen in the data.
`Esri Community Maps` comes from the coverage audit. `Google Open Buildings` is assumed from
Overture's documentation and has not been seen in a record. The East Asian buildings dataset,
IGN Spain (whose required wording is "Work derived from BTN 2024 ign.es") and City of Vancouver
datasets have no entry yet. Their credit falls back to name plus licence until an area needs them.

The package exporter copies each manifest source's `license` and `attribution` into `world.json`
`sources`, so the Overture source and its credits appear there with no exporter change. The NOTICE
paragraph is:

> Building footprints in `overture-buildings.json` come from the Overture Maps Foundation buildings
> theme (release R), licensed under ODbL 1.0: © OpenStreetMap contributors, Overture Maps Foundation.
> Contains <dataset credits>. OpenStreetMap buildings take precedence; Overture fills only footprints
> OSM lacks.

## Licence note (ODbL)

The buildings theme is ODbL because it contains OpenStreetMap data. Merging non-OSM footprints into
an OSM area is not a trivial transformation (licensing.md O12 and V1), so the merged area data, and
any package or derivative database built from it, is ODbL. The same duties apply as for OSM:

- keep "© OpenStreetMap contributors" visible whenever the world is on screen;
- credit Overture and the datasets above in the credits and in data notices;
- offer the data under ODbL.

The CC BY 4.0 datasets (Esri, Google) are used under Overture's ODbL distribution and still need
their credit. That is why the attribution lists every dataset in the file. The list is a superset of
what is drawn: records that are dropped still count.
