# Core tunnel guard and unsupported-feature diagnostics — 8 October 2026

## Implementation

R-authorized safety guard; A8 long-tail review row 2 and archetypes stage 0 provide the requirement. MapFeatureBuilder marks tunnel values other than no, or layer<0, as underground. SceneGenerator omits only underground carriageway strips and their generated street detail; RoadMarkings omits underground road paint. Ways, tags, centerlines, map-network edges and StreetContext inputs remain present. Existing railway/context filtering is unchanged. No portal, terrain cut, bridge structure, new look value or other feature geometry was added.

WorldBuild collects diagnostics after generation and prints one summary line. The generic `worldbake diagnostics <area-dir> [<area-dir> ...] --date 2026-07-15T20:00:00Z --season 1 --output Data/quality/unsupported-features.json` command writes a deterministic aggregate for the supplied areas. Native builds calculate/log the same report without writing repository files.

Counts are unique OSM object IDs per key=value/reason (never clipped pieces); categories can overlap. `notDrawn` means no feature-range, nonempty building mesh or mapped instance owns that exact source ID. `flatRoadFallback` separately counts bridges emitted as flat carriageways; it is not a claim of total invisibility. `undergroundSuppressed` is intentional guard behavior. Objects drawn through another path are excluded from missing counts. Includes raw loaded nodes/ways/relations as well as typed features, within manifest bounds by point, line intersection, polygon containment or retained typed geometry. Objects absent from source extracts, unlocatable objects with missing coordinates and unexpanded nested relations are not a completeness claim. Outline/member IDs may differ from the emitted parent relation; these are object-provenance counts, not a count of missing physical structures.

## Five-area before/after

Baseline: df3adf8 snapshot; fixed date/season and full manifest extent, unchanged inputs. No camera or image capture. Evidence: `Data/quality/tunnel-guard-comparison.json` (source hashes, graph hashes, static-geometry hashes, totals); diagnostics: `Data/quality/unsupported-features.json`.

| Area | Road strip triangles before → after | Road-bearing mesh batches | Static mesh batches | Graph unchanged |
|---|---:|---:|---:|---|
| sloans-lake | 2544 → 2540 | 37 → 37 | 48 → 48 | yes |
| lakeview-sheil-park | 2088 → 2088 | 25 → 25 | 25 → 25 | yes |
| wilmette-vattmann-park | 1136 → 1136 | 25 → 25 | 25 → 25 | yes |
| west-highland | 1888 → 1888 | 25 → 25 | 30 → 30 | yes |
| greenville-downtown | 7301 → 7279 | 70 → 70 | 70 → 70 | yes |

Sloan’s expected zero change is contradicted by saved source data: way/1190535410 and way/1190535414 are service roads tagged tunnel=building_passage. Their two quads account for exactly four removed triangles. No area-specific exception was introduced. Greenville loses 22 road triangles; the other three areas have byte-identical full static geometry. All road graph hashes are unchanged. In both changed areas, the total static triangle reduction equals the road-strip reduction. Mesh batches describe merged package geometry; actual renderer draws remain camera/LOD/runtime dependent and were not measured.

## Validation

Synthetic tests cover yes/building_passage/culvert/negative layer, visible controls, retained road-index connectivity and raw map-network node IDs; diagnostic fixtures cover all requested categories, flat-bridge distinction and deduplication. All 85 selected tests passed. The diagnostics CLI passed on an isolated synthetic area, producing exactly one summary line and the expected tunnel/ditch records. Builds and measurements run only under scripts/heavy.sh with disk guard.

Used: docs/review/long-tail-feature-coverage-2026-10-08.md row 2; docs/execution/archetypes.md stage 0. Mock: none (underground visibility safety rule). Deviation: Sloan’s source contains two underground ways, so four triangles are removed instead of the expected zero.
