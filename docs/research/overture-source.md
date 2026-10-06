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

## Heights vs lidar

Measured 2026-10-06 on `Data/areas/wilmette-vattmann-park` (Overture release 2026-09-23.1). Tool:
`Tools/regionkit/lidar/heights.py` (README there; thresholds in `data/heights.json`, fixed before any
Overture-vs-lidar comparison; offline tests in `tests/test_heights.py`). Aggregates only:
`Tools/regionkit/lidar/results/heights-wilmette.json`. **Status:** the planned comparison is complete for this
one area. The work was stopped early at the owner's request, so there is no second area and the 45–90 m²
stratum was not examined further. Nothing in the engine, the merge, the profiles or `Data/` was changed; the
rule below is a recommendation for the coordinator.

**Question.** The 1,276 Overture heights in this area have median 5.72 m (p10 2.90, p90 7.54). That is far below
what two-storey suburban houses measure, so the floors the generator derives from them come out low. Are the
Microsoft heights systematically low, and what should the data side do?

### What the file says about where a height came from

| Records | Height source | How known |
|---|---|---|
| 1,230 | Microsoft ML Buildings, no OSM source | **Inferred.** `sources` holds one entry, the geometry source, with no `property`. By Overture's convention that source supplies every property not listed elsewhere, so the height is Microsoft's. The file does not say so in words. |
| 19 | Microsoft ML Buildings, record also has an OSM source | `property` = `/properties/height` |
| 27 | USGS Lidar, record also has an OSM source | `property` = `/properties/height` |
| 3 | none (OSM only) | no height |

Two consequences. (1) All 27 USGS-lidar heights, and 19 Microsoft ones, sit on records with an OSM source, which the
merge drops (OSM wins). So **no height the engine draws from Overture in this area comes from USGS lidar**: all
1,230 drawn Microsoft footprints carry Microsoft's own height. (2) OSM has no `height` tag on any of its 49 buildings
here and one `building:levels` (a school, 2), so OSM tags give no third reference. How Microsoft derives its heights
was not checked (no web lookup was made); the comparison treats them as a black box.

### Method

Lidar: USGS 3DEP `USGS_LPC_IL_4County_Cook_2017_LAS_2019` (flight April–May 2017, leaf-off), EPT octree nodes to depth 10
that meet the area box plus 15 m (301 nodes, 20.97 M points read, 16.88 M in the box; 3.65 M class 2, 0.94 M class 6).
One global lidar-to-footprint shift (−1.0 m east, +1.0 m north; overlap of building-class cells with footprints
0.64 → 0.73), as in the roof pilot. Per Overture record, from its footprint in the engine's local frame:

- **ground** = median of class-2 points in a 3–8 m ring (15 m when fewer than 8 points; else the 5 m ground model);
- **top** = p95 of class-6 points inside the footprint eroded by 0.5 m, minus ground (also p50, mean, p99);
- **eave** = p15 of class-6 points 0.5–2 m inside the footprint edge, minus ground (reads about 0.3–0.5 m above a true
  eave on a 35° roof, because of the erosion); **span** = top − eave.

Left out and counted: footprints under 15 m² (7); under 20 building points and almost no cover (42: not a building in the
2017 data, built since, or not classed); under 20 points with some cover (1); roof cover under 0.5 (8). The 21 records whose
centroid is outside the area are not analysed, as in the merge. Analysed: 1,154 of 1,212 drawn Microsoft footprints (95 %),
18 of 18 and 25 of 25 of the OSM-matched ones. Raising the point floor to 50 changes nothing visible (n 1,140, bias −2.34 m).
Footprint-area strata (set in advance): under 45 m² (sheds, garages), 45–90 m², 90 m² and up (houses).

### Statistics (Overture height minus lidar top)

| Height source | n | Overture median | Lidar top median | Bias | Median abs. error | Within ±1.5 m (95 % CI) | Slope (Ov on lidar) | r | Overture < 6 m where lidar ≥ 7.5 m |
|---|---|---|---|---|---|---|---|---|---|
| Microsoft ML, drawn (no OSM source) | 1,154 | 5.72 | 8.05 | −2.35 m | 2.18 m | 35 % (32–38) | 0.29 | 0.57 | 248 of 651 = 38 % (34–42) |
| Microsoft ML on OSM footprints | 18 | 5.71 | 9.19 | −3.36 m | 3.40 m | 0 % | 0.46 | 0.78 | 11 of 16 |
| USGS Lidar on OSM footprints | 25 | 8.30 | 7.71 | +0.21 m | 0.40 m | 92 % (75–98) | 1.08 | 0.99 | 0 of 16 |

Microsoft heights on drawn footprints, by footprint area:

| Footprint | n | Overture median | Lidar top median | Bias | Median abs. error | Within ±1.5 m | r | Overture < 6 m where lidar ≥ 7.5 m | Lidar ≥ 7.5 m among Overture < 6 m |
|---|---|---|---|---|---|---|---|---|---|
| under 45 m² | 124 | 4.08 | 4.16 | −1.29 | 1.34 | 57 % | 0.35 | 16 of 25 | 16 % of 99 |
| 45–90 m² | 333 | 3.66 | 4.51 | −1.65 | 1.38 | 55 % | 0.46 | 32 of 62 | 11 % of 286 |
| 90 m² and up | 697 | 6.17 | 8.94 | −2.87 | 2.78 | 22 % | 0.35 | 200 of 564 | 69 % of 290 |

On house-sized footprints, 69 % of the Microsoft heights under 6 m have a lidar top of 7.5 m or more. For Overture heights of
6–7 m (the busiest bin, 311 footprints in all) the lidar median is still 9.2 m and 85 % are 7.5 m or more: the shortfall is spread
over the whole range, not just the low tail. On house-sized footprints the Microsoft heights are squeezed into a narrow band
(p10–p90 5.1–7.6 m against 6.6–10.9 m of lidar tops), have no rank correlation with footprint area (0.01) and weak correlation with the
lidar top (r 0.35): they carry little information about one house's height. The lidar tops (median 8.94 m) match the 8–11 m
expected for two-storey houses.

**USGS-lidar heights agree with this lidar reading** (bias +0.21 m, 92 % within 1.5 m, r 0.99, n 25). That supports the method: they
are top-of-building heights, and a 2017 reading is a fair stand-in for them.

### Eave or top?

Same buildings (1,154 drawn Microsoft footprints), Overture height against each lidar statistic:

| Lidar statistic | Bias | Median abs. error | Within ±1.5 m | r |
|---|---|---|---|---|
| top p99 | −3.22 | 2.63 | 28 % | 0.58 |
| top p95 | −2.35 | 2.18 | 35 % | 0.57 |
| roof median | −0.51 | 1.26 | 59 % | 0.65 |
| roof mean | −0.55 | 1.17 | 63 % | 0.67 |
| midway between eave and top | −0.71 | 1.11 | 63 % | 0.64 |
| eave p15 | +0.94 | 1.07 | 64 % | 0.56 |

Microsoft's height is **not the top**. It sits between the eave estimate and the mean roof height, and the eave, the midpoint and
the roof mean fit about equally well (the eave estimate itself reads a few tenths high), so eave and mean-roof cannot be told apart
here. House-sized footprints give the same picture (eave +0.95 m, midway −0.96 m, mean −0.94 m, top −2.87 m). A fair reading is
"roughly mean or mid-roof height", about 2.3 m under the top, near half the median roof span of houses (3.1 m).

### What the floors would be

The generator's mapping as stated for this task: floors = round((height − roof rise) / perFloor), at least 1. The rise here is each
building's own lidar span (capped at 5 m) on both sides, so only the height error differs; perFloor 3.0 m (the profile range is
2.8–3.2; both ends are in the JSON and give the same ordering). Truth = floors from the lidar top. When a height is dropped the
fallback is the profile's floors for Wilmette house types, modelled as 2 (first-listed floor count; in the `unknown` rule 87 % of
the weight is 2 and 13 % is 1). House-sized footprints, n 697:

| Rule | Heights kept | Floors match lidar | Fewer than lidar | More than lidar | Derived 1 / 2 / 3+ |
|---|---|---|---|---|---|
| lidar truth | | | | | 220 / 403 / 74 (32 % / 58 % / 11 %) |
| keep Overture heights (today) | 100 % | 41 % | 56 % | 3 % | 581 / 112 / 4 (83 % one-storey) |
| drop Overture < 6 m | 58 % | 42 % | 36 % | 22 % | 297 / 396 / 4 |
| drop Overture < 7 m | 20 % | 56 % | 14 % | 30 % | 61 / 632 / 4 |
| drop Overture < 8 m | 7 % | 57 % | 11 % | 32 % | 15 / 679 / 3 |
| **drop all Microsoft heights** | 0 % | **58 %** | 11 % | 32 % | 0 / 697 / 0 (profile default) |
| add 3 m to every height | 100 % | 49 % | 18 % | 33 % | 153 / 428 / 116 |
| line fitted on the other folds (5-fold) | 100 % | 50 % | 20 % | 31 % | 163 / 444 / 90 |
| bin medians from the other folds (5-fold) | 100 % | 51 % | 23 % | 26 % | 207 / 438 / 52 |

All drawn footprints (n 1,154, sheds and garages included): keep 54 %, binned correction 59 %, drop everything 40 %, and
**drop on footprints of 90 m² and up, keep the rest: 65 %** (63 % at perFloor 2.8 and at 3.2). Small footprints are low in lidar too
(median top 4.2–4.5 m), so the Microsoft heights are roughly right there (bias −1.3 to −1.7 m, 55–57 % within ±1.5 m) and dropping them
would lose. (Small buildings are garages and sheds in the generator, whose wall heights come from the profile or from the lower of
height and profile range, not from floors.)

Fitted corrections do not beat the profile default on houses. The slope of lidar on Overture is 1.1 with r 0.57 overall and r 0.35 on
houses, so a correction mostly adds noise around a constant; the profile floors do as well and need no fitted numbers.

### Recommendation

1. **Data-side rule: ignore a Microsoft ML `height` on house-sized footprints (area ≥ 90 m²); keep it on smaller ones.** Key it on the
   dataset that supplied the height (the `/properties/height` source, else the geometry source, as in the table above), not on the
   value. Heights reach `HeightRules` through `OvertureBuildings.tags(for:)`; without a `height` tag a house gets its profile
   floors (2 for 87 % of the Wilmette types). Expected effect on house-sized footprints in this area: one-storey houses fall from about
   83 % to the profile's 13 %; floors match the lidar-implied count for 58 % instead of 41 %. What remains is real one- and
   three-storey houses (32 % and 11 % by lidar) that the profile cannot know. The file stays a plain extract (this document says it keeps
   every record); the rule belongs where tags are built, or in a small data policy the merge reads.
2. **Keep `USGS Lidar` heights** (they match to 0.4 m). In this area none is on a drawn footprint: all 27 are on OSM buildings that the
   merge drops. They matter only if Overture heights are later applied to OSM buildings (licensing O12). Microsoft heights on OSM
   buildings are as low as on the drawn ones (n 18, bias −3.4 m) and need the same rule.
3. **Do not use a plain height threshold.** "Drop under 6 m" keeps 58 % of the house heights and does worse than dropping them all
   (42 % vs 58 %), because the 6–8 m values are low as well. "Under 8 m" only matches "drop all".
4. **No temporary generator guard is needed once rule 1 is in the data path.** If a guard is wanted before that, it must be
   "ignore Overture heights on house-sized footprints" (the same rule, in the generator), not "ignore heights under about 6 m".
5. Larger gain, out of scope here: lidar tops are accurate (Overture's own USGS heights agree with this measurement), and the lidar
   eave would give floors per house. A region-kit step that stamps lidar tops or eaves onto footprints in lidar-covered areas is the real
   fix for the 32 % one-storey and 11 % three-storey houses.

### Limits

- One area (1 km², a North Shore suburb), one lidar delivery. The 90 m² line and all thresholds were fixed before the comparison.
- The flight is 2017 and the footprints are 2026. Teardowns and additions since then make the lidar reading wrong for some buildings; only
  42 footprints (3.5 %) show up as absent in 2017, so the rest of the drift is invisible here. Newer houses tend to be larger and taller,
  which would widen the gap, not close it.
- Lidar top = p95 of class-6 points (a chimney or dormer can raise it, missed points can lower it). Eave = p15 of edge-band points, about
  0.3–0.5 m high on pitched roofs. "Floors from lidar" uses these and is itself an estimate.
- How Microsoft derives its heights is unverified here, and "Microsoft" for the 1,230 drawn records is inferred from `sources`.
- This branch (main at `6a4b5f6`) derives the eave height (top − rise) from a `height` tag and takes floors from the house type; floors
  from height are as stated by the coordinator and modelled here, not read from code.
- Downloaded: 131,698,496 bytes from the public `usgs-lidar-public` bucket (131,479,560 bytes of LAZ in 301 nodes, 218,936 bytes of EPT
  metadata; node sizes by HTTP HEAD, no body), plus Python wheels (numpy, scipy, shapely, rasterio, laspy; uv cache 174 MB on disk).
  No block or refusal was met. Requests carry the honest `WorldEngine-regionkit/0.1` User-Agent.
