# Water identity and pedestrian tunnel corrections — A1, 9 October 2026

R requested F02 and the eight-area tunnel correction, plus the bounded [tree coverage/rights scan](held-area-tree-scan.md). This is a general data-driven correction, not the separate water-look redesign in the execution brief. Baseline is `294a89b`; all areas retain their held data and normal regional selection. No source records are removed or changed.

## Rule and consumer scope

**Water:** `ShoreBand.profile(for:)` reads the water feature’s observed `water=lake` class and identity (`wikidata`, then stable OSM relation identity) through a data registry in `look.json`. Approved lake recipes are retained only for their actual water bodies, independent of block, camera or surrounding architecture. Lake Michigan, including a clipped feature at Soldier Field, cannot inherit Sloan’s settings. Unknown lakes, rivers, ponds, basins and pools get index **−1**, no inferred shallow-depth band, and the native shader’s existing generic water response. No new colours, roughness, wave parameters or thresholds are invented. Identity aliases are data, not code branches; names alone never select a recipe. This is identity-based classification, not a measured depth/turbidity estimate. Approved lake-winter blend widths remain Michigan 4 m and Sloan 2 m. `MockValues`’ two-slot ordering is unchanged and is not a water-body fallback.

Consumers: shared `SceneGenerator` writes the index in water vertex `extra.w`; `MeshUpload` preserves it as signed Float32; native `worldWaterSurface` uses the negative sentinel to enter its existing generic branch, including generic roughness. Exported GLB extras retain it. Shipping web keeps its existing generic water material; this change does not add native lake mechanics to web. Authored bakeoff fixtures remain unchanged. Native coarse context water carries coverage bounds in `uv3`, not lake-profile indices; the shader now excludes the context flag (256) from named-lake selection and uses the generic response. Previously a positive coverage-bound value could select Sloan’s. Context geometry/export bytes stay unchanged; native context-water appearance is expected to change, including Lakeview/Wilmette. Context identity classification is not claimed. No world-edge geometry, approved palette values or compiled mock values change.

**Tunnels:** the missing guard was in separately mapped path and sidewalk generation, rather than the carriageway loop. `suppressesPedestrianSurfaceRendering` suppresses explicit `tunnel=yes`/`culvert`, and affirmative tunnel values with negative layer (including `covered` and underground building passages). A ground-level `tunnel=building_passage` retains its walkable floor; negative layer alone, `tunnel=no`, and ground-level `covered=yes` remain visible. The semantic `isTunnel` flag is unchanged. Carriageways/generated street detail retain their existing yes/building_passage/culvert predicate. Mapped path strips, mapped sidewalk strips and crossing-path paint use the new pedestrian predicate. Road occupancy, yards, routing inputs, postcard candidates, railway filtering and the context bridge exception retain their previous policy. Diagnostics include suppressed pedestrian refs. No ID-specific exceptions exist in this rule.

## Reproduction and measurement limits

`Tools/regionkit/qa/road_guard_measurement.py` compiles the same filed Swift harness against archived baseline and the candidate under `scripts/heavy.sh`; eight unchanged manifests/sources and implementation hashes are in [the measurement](water-tunnel-held-areas.json). Recipe: 2026-10-15T18:00:00Z, season 2 (autumn), full manifest core. Existing road metrics remain; added pedestrian triangles count triangles whose three vertices share a mapped path/sidewalk feature range. Chunk-batch counts are CPU geometry batches, **not GPU draws**. Road and pedestrian hashes cover loaded clipped refs/centerlines, not complete routing equivalence. Water hash covers per-chunk vertex counts, Float32 positions/extras and indices. Tree counts exclude generated trees and way-centroid trees. Baseline/current measurements are not broad source audits.

Command (owned active heavy lock required):

```sh
HEAVY_AGENT=A1 scripts/heavy.sh 'A1 eight-area water/tunnel comparison' python3 Tools/regionkit/qa/road_guard_measurement.py --baseline-ref 294a89b --areas evanston-south greenville-downtown kenilworth-station lakeview-sheil-park sloans-lake west-highland wilmette-vattmann-park winnetka-village-green --date 2026-10-15T18:00:00Z --season 2 --output docs/data/water-tunnel-held-areas.json --diagnostics Data/quality/unsupported-features.json
```

## Results

| Area | Carriageway triangles before → after | Pedestrian triangles before → after | Pedestrian-bearing batches | Road/path hashes unchanged | Core water unchanged |
|---|---:|---:|---:|---|---|
| evanston-south | 1544 → 1544 | 6626 → 6626 | 25 → 25 | yes / yes | yes |
| greenville-downtown | 7287 → 7287 | 35163 → 35163 | 70 → 70 | yes / yes | no; classification corrected |
| kenilworth-station | 1350 → 1350 | 2476 → 2474 | 18 → 18 | yes / yes | yes |
| lakeview-sheil-park | 2088 → 2088 | 8504 → 8504 | 25 → 25 | yes / yes | yes |
| sloans-lake | 2540 → 2540 | 8954 → 8954 | 39 → 39 | yes / yes | no; classification corrected |
| west-highland | 1888 → 1888 | 12522 → 12522 | 30 → 30 | yes / yes | no; classification corrected |
| wilmette-vattmann-park | 1136 → 1136 | 2426 → 2426 | 22 → 22 | yes / yes | yes |
| winnetka-village-green | 1330 → 1330 | 3289 → 3285 | 17 → 17 | yes / yes | yes |

Kenilworth `way/206236052` (tunnel=yes, layer −1) loses 2 triangles; Winnetka `way/323015881` (tunnel=yes, layer −2) loses 4. The same ways remain in loaded path data. Static position/index hashes are unchanged for the other six areas. All static chunk-batch totals remain unchanged. The West Highland covered underground source way lies outside this held core; it is covered by synthetic controls, not counted as a measured core removal. Lakeview’s three ground-level building passages remain drawn.

Lakeview and Wilmette have no core water geometry on either side: their identical core water hashes are a geometry control, not a lake-appearance score. Native context appearance changes as explained above; coarse geometry is untouched. Sloan’s retained lake still selects profile 1 / 2 m band; its four other water bodies and pool use neutral. Greenville’s river/pond/basin/pools and West Highland’s pools lose the erroneous Sloan profile. No source-water outline is deleted.

Validation so far: nine focused water/tunnel tests passed under the wrapper at load 12.10; eight-area paired measurement completed under its own wrapper and released the lock. After rebase onto f021865: 64 tests in 10 affected suites passed (35.795 s test execution), native Metal compile and metallib link both passed; wrapper admitted at load 3.78 and exited 0/released lock. Post-merge scoreboard remains pending below.

## Ledger text for A3

R’s explicit F02/tunnel instruction scopes these shared-generator and minimal native sentinel edits. The former land-region→example-lake fallback is replaced; ground-level pedestrian passages stay visible and underground mapped paths lose their surface strips. This is correctness evidence, not an improved water-look score or a floor-budget pass. Untuned held-area scoreboard and source hashes accompany delivery; A3 grades remain separate and must not be inferred from technical counters. Tree scan performs no municipal intake.

Used: `docs/tracking/REFERENCE-MAP.md` Water, Ground, Context ring/world edge rows; `docs/review/block-specific-scan.md` F02; `docs/data/tunnel-guard.md`; `docs/execution/water.md` classification and approved recipe witnesses; `docs/execution/ground.md`; `docs/data/context-rings.md`; `docs/execution/world-edge-options.md`; `docs/data-licensing.md`; street-trees-by-metro-v1 inventory provenance. Mock: lake-winter-v1 `02-big-lake-vs-city-lake.png`, ground-v1 `images/02-hard-surfaces.png`, look-fix-v1 `images/aerial-01-continuation-clear.png`. Deviation: no new water-look batch, no native visual grade or new world-edge implementation; unknown water uses the pre-existing generic response, not measured optical properties.

Mock file SHA-256: lake-winter 02 `59b11ddbafb3bde155b701037642ed3be7274ca1df0863981253281da8024be9`; ground hard surfaces `c3d08fd042fce1f5ffa316caf243716154be245ac273876599003c6cba7674c6`; look-fix aerial continuation `5f837bae4edbca3a8d5944bbc88cb2e436c42e44d280b806bd3ed7661a972e9d`.
