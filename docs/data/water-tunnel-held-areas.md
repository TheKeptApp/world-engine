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

Kenilworth `way/206236052` (tunnel=yes, layer −1) loses 2 triangles; Winnetka `way/323015881` (tunnel=yes, layer −2) loses 4. The same ways remain in loaded path data. Static position/index hashes are unchanged for the other six areas. All static chunk-batch totals remain unchanged. The West Highland covered underground source way lies about 48 m south of this held core (local north −547.59…−547.55 m; core edge −500 m); it is covered by synthetic controls, not counted as a measured core removal. Lakeview’s three ground-level building passages remain drawn.

Lakeview and Wilmette have no core water geometry on either side: their identical core water hashes are a geometry control, not a lake-appearance score. Native context appearance changes as explained above; coarse geometry is untouched. Sloan’s retained lake still selects profile 1 / 2 m band; its four other water bodies and pool use neutral. Greenville’s river/pond/basin/pools and West Highland’s pools lose the erroneous Sloan profile. No source-water outline is deleted.

Validation so far: nine focused water/tunnel tests passed under the wrapper at load 12.10; eight-area paired measurement completed under its own wrapper and released the lock. After rebase onto f021865: 64 tests in 10 affected suites passed (35.795 s test execution), native Metal compile and metallib link both passed; wrapper admitted at load 3.78 and exited 0/released lock. The completed independent post-merge scoreboard is filed below.

## Post-merge 24-frame scoreboard

Implementation merged as **591e4be**. Independent shared run at **1fcb233** (a descendant of that merge) completed all eight held areas at 40/150/600 m, then was filed on main in **a1bc333**. [Canonical report](../../web/bakeoff/evidence/context-holdouts/post-merge-scoreboard.md) and [JSON](../../web/bakeoff/evidence/context-holdouts/post-merge-scoreboard.json); [reuse receipt and local PNG hashes](water-tunnel-scoreboard-provenance.json). All **147 scoreboard code files**, all **29 held inputs**, and native/map implementation hashes matched A1 exactly. All 24 image hashes were checked and the images preserved locally under `.build/a1-water-tunnel-scoreboard/` (ignored; no PNGs committed). A1 stopped its duplicate run after Evanston while queued for Greenville; no other lane’s process, files or lock were changed.

Comparable BEFORE is the filed far-water scoreboard at **d82a68d**, not the older `world-scoreboard-v0` JSON: all 24 comparison-input objects (source, harness, camera, date, viewport and recipe) match. The older v0 has different source/harness hashes and is not used for quantitative deltas. Kenilworth/Winnetka tunnel flags are **6 → 0** across the six affected frames; all 24 AFTER frames have zero tunnel surface ranges. Existing failures remain: **24 floor, 24 standard, seven blank-ground**. No look grade, floor promotion, native frame-equivalence claim or unrelated fix.

| Area / metres | Main triangles B → A | Main draws B → A | Shadow triangles B → A | Shadow draws B → A | Tunnel ranges B → A |
|---|---:|---:|---:|---:|---:|
| evanston-south/40 | 544177 → 544177 | 214 → 214 | 419142 → 419142 | 125 → 125 | 0 → 0 |
| evanston-south/150 | 506058 → 506058 | 204 → 204 | 424718 → 424718 | 150 → 150 | 0 → 0 |
| evanston-south/600 | 342496 → 342496 | 211 → 211 | 56720 → 56720 | 4 → 4 | 0 → 0 |
| greenville-downtown/40 | 417590 → 417520 | 111 → 111 | 307703 → 307703 | 35 → 35 | 0 → 0 |
| greenville-downtown/150 | 461301 → 461065 | 171 → 170 | 312464 → 312464 | 70 → 70 | 0 → 0 |
| greenville-downtown/600 | 429835 → 429771 | 199 → 199 | 0 → 0 | 0 → 0 | 0 → 0 |
| kenilworth-station/40 | 430028 → 430026 | 198 → 198 | 264349 → 264347 | 108 → 108 | 1 → 0 |
| kenilworth-station/150 | 425114 → 425112 | 216 → 216 | 345470 → 345468 | 138 → 138 | 1 → 0 |
| kenilworth-station/600 | 361786 → 361784 | 213 → 213 | 49127 → 49127 | 4 → 4 | 1 → 0 |
| lakeview-sheil-park/40 | 1057862 → 1057862 | 210 → 210 | 924485 → 924485 | 123 → 123 | 0 → 0 |
| lakeview-sheil-park/150 | 1181951 → 1181951 | 224 → 224 | 996184 → 996184 | 149 → 149 | 0 → 0 |
| lakeview-sheil-park/600 | 936137 → 936137 | 203 → 203 | 2280 → 2280 | 1 → 1 | 0 → 0 |
| sloans-lake/40 | 656467 → 656455 | 169 → 169 | 560465 → 560465 | 111 → 111 | 0 → 0 |
| sloans-lake/150 | 785361 → 785315 | 238 → 238 | 572162 → 572162 | 113 → 113 | 0 → 0 |
| sloans-lake/600 | 502798 → 502656 | 285 → 285 | 75831 → 75831 | 4 → 4 | 0 → 0 |
| west-highland/40 | 818648 → 818648 | 233 → 233 | 678189 → 678189 | 138 → 138 | 0 → 0 |
| west-highland/150 | 747771 → 747771 | 239 → 239 | 790133 → 790133 | 146 → 146 | 0 → 0 |
| west-highland/600 | 599781 → 599781 | 222 → 222 | 147346 → 147346 | 9 → 9 | 0 → 0 |
| wilmette-vattmann-park/40 | 553853 → 553853 | 191 → 191 | 410139 → 410139 | 114 → 114 | 0 → 0 |
| wilmette-vattmann-park/150 | 534459 → 534459 | 207 → 207 | 454124 → 454124 | 154 → 154 | 0 → 0 |
| wilmette-vattmann-park/600 | 366066 → 366066 | 197 → 197 | 34776 → 34776 | 2 → 2 | 0 → 0 |
| winnetka-village-green/40 | 326717 → 326713 | 180 → 180 | 224875 → 224875 | 102 → 102 | 1 → 0 |
| winnetka-village-green/150 | 324009 → 324005 | 197 → 197 | 253587 → 253587 | 130 → 130 | 1 → 0 |
| winnetka-village-green/600 | 236963 → 236959 | 202 → 202 | 0 → 0 | 0 → 0 | 1 → 0 |

Lakeview/Wilmette web main/shadow counts stay unchanged in all six views. Greenville and Sloan’s main-triangle reductions reflect removal of falsely assigned shallow bands; Greenville150 loses one draw. Their source water outlines remain loaded. Native context-water appearance changes are explained in the rule section and are not scored by this shipping-web run.

## Ledger text for A3

R’s explicit F02/tunnel instruction scopes these shared-generator and minimal native sentinel edits. The former land-region→example-lake fallback is replaced; ground-level pedestrian passages stay visible and underground mapped paths lose their surface strips. This is correctness evidence, not an improved water-look score or a floor-budget pass. Untuned held-area scoreboard and source hashes accompany delivery; A3 grades remain separate and must not be inferred from technical counters. Tree scan performs no municipal intake.

Used: `docs/tracking/REFERENCE-MAP.md` Water, Ground, Context ring/world edge rows; `docs/review/block-specific-scan.md` F02; `docs/data/tunnel-guard.md`; `docs/execution/water.md` classification and approved recipe witnesses; `docs/execution/ground.md`; `docs/data/context-rings.md`; `docs/execution/world-edge-options.md`; `docs/data-licensing.md`; street-trees-by-metro-v1 inventory provenance. Mock: lake-winter-v1 `02-big-lake-vs-city-lake.png`, ground-v1 `images/02-hard-surfaces.png`, look-fix-v1 `images/aerial-01-continuation-clear.png`. Deviation: no new water-look batch, no native visual grade or new world-edge implementation; unknown water uses the pre-existing generic response, not measured optical properties.

Mock file SHA-256: lake-winter 02 `59b11ddbafb3bde155b701037642ed3be7274ca1df0863981253281da8024be9`; ground hard surfaces `c3d08fd042fce1f5ffa316caf243716154be245ac273876599003c6cba7674c6`; look-fix aerial continuation `5f837bae4edbca3a8d5944bbc88cb2e436c42e44d280b806bd3ed7661a972e9d`.
