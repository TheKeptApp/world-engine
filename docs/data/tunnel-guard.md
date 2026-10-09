# Core tunnel guard and unsupported-feature diagnostics — 8 October 2026

## Implementation

R's A8-audit correction separates source semantics from a narrow core render policy. `MapFeatureBuilder` sets `isTunnel` exactly as before the original guard: a `tunnel` tag other than `no`; layer alone never sets it. `WayFeature.suppressesSurfaceRendering` recognizes exactly `tunnel=yes`, `tunnel=building_passage`, and `tunnel=culvert`. Negative layer alone, `tunnel=no`, and `covered=yes` alone do not trigger it; unreviewed tunnel values are not added by inference. Layer-only negative roads remain visible in the core and are diagnosed as `layer-only, review`.

| Consumer | Policy after correction |
|---|---|
| SceneGenerator core carriageway strips | New explicit suppression predicate |
| SceneGenerator generated curbs, sidewalks and lamps | Same new predicate |
| RoadMarkings road paint | Same new predicate |
| YardGeneration / GroundDetail road exclusions | Existing semantic `isTunnel` and bridge/kind checks; no consumer rewrite |
| RayWorld road occupancy | Existing semantic `isTunnel` and bridge checks |
| PostcardComposer pedestrian candidates | Existing semantic `isTunnel` |
| ContextFeatures roads | Existing `!isTunnel && (layer >= 0 || isBridge)`; restored negative-layer bridge exception through corrected semantics |
| Context railway filter | Existing raw-tag policy, unchanged |
| Mapped core path/sidewalk ribbons | Existing behavior; new predicate is not applied here |

No portal, terrain cut, bridge structure, new look value or other feature module was added. The synthetic controls establish the listed tag policies; the measured geometry/road-hash comparisons below apply only to the five supplied areas, not arbitrary regions, context-ring scenes, complete routing graphs or runtime equivalence.

WorldBuild collects diagnostics after generation and prints one summary line. The generic `worldbake diagnostics <area-dir> [<area-dir> ...] --date 2026-07-15T20:00:00Z --season 1 --output Data/quality/unsupported-features.json` command writes a deterministic aggregate for the supplied areas. Native builds calculate/log the same report without writing repository files.

Counts are unique OSM object IDs per key=value/reason (never clipped pieces); categories can overlap. `notDrawn` means no feature-range, nonempty building mesh or mapped instance owns that exact source ID. `flatRoadFallback` separately counts bridges emitted as flat carriageways; it is not a claim of total invisibility. `undergroundSuppressed` records the explicit core predicate; `layer-only, review` records negative-layer roads without a semantic tunnel tag, without suppressing them. Objects drawn through another path are excluded from missing counts. Includes raw loaded nodes/ways/relations as well as typed features, within manifest bounds by point, line intersection, polygon containment or retained typed geometry. Objects absent from source extracts, unlocatable objects with missing coordinates and unexpanded nested relations are not a completeness claim. Outline/member IDs may differ from the emitted parent relation; these are object-provenance counts, not a count of missing physical structures.

## Five-area before/after

Baseline: df3adf8 snapshot; fixed date/season and full manifest extent, unchanged inputs. No camera or image capture. Evidence: `Data/quality/tunnel-guard-comparison.json` (source hashes, graph hashes, static-geometry hashes, totals); diagnostics: `Data/quality/unsupported-features.json`.

| Area | Road strip triangles before → after | Road-bearing mesh batches | Static mesh batches | Graph unchanged |
|---|---:|---:|---:|---|
| sloans-lake | 2544 → 2540 | 37 → 37 | 48 → 48 | yes |
| lakeview-sheil-park | 2088 → 2088 | 25 → 25 | 25 → 25 | yes |
| wilmette-vattmann-park | 1136 → 1136 | 25 → 25 | 25 → 25 | yes |
| west-highland | 1888 → 1888 | 25 → 25 | 30 → 30 | yes |
| greenville-downtown | 7301 → 7287 | 70 → 70 | 70 → 70 | yes |

Sloan’s expected zero change is contradicted by saved source data: way/1190535410 and way/1190535414 are service roads tagged tunnel=building_passage. Their two quads account for exactly four removed triangles. No area-specific exception was introduced. Greenville now loses 14 road triangles; the three layer-only ways 311413668, 757360129 and 757360130 are restored (8 triangles) and listed as `layer-only, review`. The other three areas have identical canonical static position/index bytes. Loaded road identifier/centerline hashes match the pre-guard baseline in these five areas. In the measured Sloan’s and Greenville areas, the total static triangle reduction equals the road-strip reduction. Mesh batches describe merged package geometry; actual renderer draws remain camera/LOD/runtime dependent and were not measured.

## Validation

Synthetic tests cover yes/building_passage/culvert suppression; negative-layer bridge, layer-only, tunnel=no and covered=yes visible controls; restored context bridge behavior; road occupancy and postcard-path semantic policy; retained road-index and raw map-network node IDs. Diagnostic fixtures cover the requested categories, flat-bridge distinction, layer-only review and deduplication. All 87 tests in the expanded map, tunnel, road-marking and map-layer selection pass. The diagnostics CLI passed on an isolated synthetic area, producing exactly one summary line and the expected tunnel/ditch records. Builds and measurements run only under scripts/heavy.sh with disk guard.

Used: docs/review/a1-tunnel-guard-audit-2026-10-08.md (1e5edfb), source semantics/scope/hash findings; R’s correction. Mock: none (tag-policy safety fix). Deviation: none; measured Sloan −4 and Greenville −14 as requested.

## Filed measurement harness and serialization (version 2)

`Tools/regionkit/qa/road_guard_measurement.py` compiles `RoadGuardMeasurement.swift` against a clean source snapshot at the baseline ref and then the current source. Both runs read the same area inputs. Run directly under the wrapper (no background schedule):

```
HEAVY_AGENT='A1 tunnel audit' scripts/heavy.sh 'five-area tunnel comparison' python3 Tools/regionkit/qa/road_guard_measurement.py --baseline-ref df3adf8 --areas sloans-lake lakeview-sheil-park wilmette-vattmann-park west-highland greenville-downtown --date 2026-07-15T20:00:00Z --season 1 --output Data/quality/tunnel-guard-comparison.json --diagnostics Data/quality/unsupported-features.json
```

The runner verifies its direct parent owns the heavy lock, enforces 8 GiB free, snapshots only build sources, and removes only its own temporary snapshot. Any area IDs can be supplied; there are no area-specific pipeline branches. Reports include input and harness/implementation SHA-256 hashes.

Road hash: SHA-256 of Foundation JSONSerialization with sorted keys, an array in loader order of `{ref, points:[[east,north],...]}` for loaded clipped roads. This measures these identifiers/centerlines, not connectivity of a complete exported routing graph or equivalence of all semantic attributes. Synthetic MapNetwork tests separately exercise retained node sequences.

Static geometry v2 hash: UTF-8 domain prefix `WorldEngine-static-position-index-v2` plus a NUL byte; then each generated chunk in generation order: UInt32 little-endian ID byte length, UTF-8 chunk ID, UInt32 little-endian position count and index count, each position's x/y/z Float32 bit pattern as three little-endian UInt32 words, then each index as little-endian UInt32. No SIMD padding is included. Only static mesh positions/indices are measured: not colours, normals, water meshes, instances or GPU draws. Both baseline and corrected hashes are regenerated with this same filed version; prior static hashes used host SIMD bytes and must not be compared numerically to v2.

Road triangles are those whose three vertex indices belong to one road feature range. Batch counts are merged static meshes/road-bearing chunks, not hardware draw-call captures. No result here establishes all-area, full connectivity or complete renderer equivalence.

## Ledger text for A3

A1 tunnel correction: source tunnel semantics and the context negative-layer bridge exception restored. Separate explicit-tag suppression applies to carriageways, generated curbs/sidewalks/lamps and paint; yards, occupancy and postcard candidates retain semantic policy. Five measured areas: Sloan −4, Greenville −14, Lakeview/Wilmette/West Highland zero road-triangle change versus df3adf8. Three Greenville layer-only ways stay visible and listed for review. Filed harness regenerates road identifier/centerline and canonical static position/index hashes; no GPU draw, full routing or visual-equivalence claim. Native captures and scoring remain pending; no look values changed.
