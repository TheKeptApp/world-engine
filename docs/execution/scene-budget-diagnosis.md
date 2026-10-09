# Scene-budget diagnosis — 2026-10-08

## Conclusion and evidence scope

The saved OFF aerial frames exceed every proposed main-pass tier. At 150 m, finer visibility selection followed by compatible spatial pooling models **205,349 triangles / 89 draws**, below the strict floor triangle limit and within its draw limit. This is a conditional CPU estimate, not an implemented optimization, new capture, GPU measurement or device certification. No renderer, shader, tile, geometry, placement or budget was changed.

Read [STATE](../tracking/STATE.md) and [budget tiers](budget-tiers.md). The authoritative observations are [A7's manifest](../lookloop/captures/a7-web-crown-ladder/manifest.json), capture commit `fd99b9d5ad76217ce6c0f210d1f89f808c8637e0`. A read-only Node/Three scene reconstruction at analysis main `48a687d` reproduces all three saved main triangle/draw totals exactly. Source hashes for bakeoff main, shadow casters, policy and calibration match the saved manifest. It uses the frozen A7 package, original LOD0, OFF species selection, October phenology, facades, DEM, tufts and sky; it does not render pixels.

Ladder pose: lat 39.7511195, lon -105.0389, heading 270°, pitch 45°, FOV 50°, altitudes 40/150/600 m above the package datum; 1005×565, DPR 1. Date metadata: 2026-10-15T20:30:00Z; web lighting remains its fixture, not a solar-time calculation. The saved street camera is a separate fixture. Fresh/repeat ladder controls have zero saved pixel difference. Estimates below retain this pose and selection.

## Observed pass accounting

Values are triangles / draws, main only unless marked otherwise. Postprocessing is separate.

| Pass | 40 m | 150 m | 600 m |
|---|---:|---:|---:|
| Sky | 1,984 / 1 | 1,984 / 1 | 1,984 / 1 |
| Opaque world | 390,298 / 110 | 434,457 / 148 | 339,981 / 166 |
| Facades | 3,996 / 2 | 4,512 / 4 | 2,052 / 3 |
| Water material | 86 / 2 | 371 / 12 | 762 / 27 |
| Tree foliage | 199,993 / 65 | 221,327 / 85 | 150,510 / 94 |
| Tufts | 3,600 / 1 | 0 / 0 | 0 / 0 |
| DEM | 129,144 / 1 | 129,144 / 1 | 129,144 / 1 |
| **Main total** | **729,101 / 182** | **791,795 / 251** | **624,433 / 292** |
| Shadow, separate | 69,639 / 62 | 67,961 / 42 | 0 / 0 |
| Post, separate | 1 / 1 | 1 / 1 | 1 / 1 |

The 600 m shadow zero describes this web capture's light/frustum only. It is not a native or general shadow-budget waiver. Street main is 347,177 / 99: a floor main pass, with shadows and sustained device performance still needing their own evidence.

## Requested semantic layers

A material draw can contain several semantic layers. Each cell below is **triangles; exclusive draws + shared-draw participation**. Shared participation is non-additive: one draw may appear in several rows. There are 18 / 29 / 48 distinct mixed draws; exclusive draws plus these distinct mixed draws equal 182 / 251 / 292. Assigning an integer draw exclusively to each layer would fabricate a split.

| Layer | 40 m | 150 m | 600 m |
|---|---:|---:|---:|
| Buildings | 240,641; 2 + 16 | 267,905; 4 + 18 | 208,014; 3 + 21 |
| Roads and paved surfaces | 30,870; 0 + 16 | 35,936; 0 + 20 | 33,447; 0 + 27 |
| Terrain and ground | 184,392; 2 + 18 | 191,285; 6 + 29 | 176,152; 9 + 48 |
| Water features | 266; 0 + 8 | 493; 5 + 18 | 824; 8 + 39 |
| Props, including shrubs | 67,355; 93 + 12 | 72,865; 121 + 13 | 53,502; 129 + 11 |
| Tree foliage | 199,993; 65 + 0 | 221,327; 85 + 0 | 150,510; 94 + 0 |
| Other: sky and tufts | 5,584; 2 + 0 | 1,984; 1 + 0 | 1,984; 1 + 0 |

For an additive attribution only, triangle-weighted draw-equivalents for buildings/roads/terrain/water/props/tree foliage/other are respectively: 40 m **11.548 / 3.292 / 5.388 / 0.953 / 93.819 / 65 / 2**; 150 m **14.824 / 4.612 / 13.584 / 10.116 / 121.863 / 85 / 1**; 600 m **14.206 / 9.996 / 24.447 / 18.637 / 129.713 / 94 / 1**. These are attribution fractions, not independently submitted draw counts.

GLB feature IDs classify buildings, roads/path/crossing/sidewalk/curb/markings/parking/paving, ground/grass/park/garden/shore, water/pools, and props; prototype instances retain their kind. Semantic water includes water-tagged static bed/skirts, so it differs from the water-material pass. Foliage is shown separately instead of hiding the dominant tree contribution inside props. Terrain includes DEM; other includes charged sky and tufts.

A2's “non-foliage” means **main minus the tree-foliage pass**, yielding exactly 529,108 / 117, 570,468 / 166 and 473,923 / 198. It still includes bush/flower-bush triangles (29,571 / 29,509 / 16,258) and 3,600 tuft triangles at 40 m. Excluding those too leaves 495,937 / 540,959 / 457,665 triangles: still above floor. Do not assign shrubs to non-foliage when calculating a biological foliage allowance F.

## General rules and estimated savings

### Fine visibility, then compatible pooling

The model tests features within already submitted static meshes and individual instances against the camera frustum. Static feature AABBs come from exact world-space triangle vertices; instance bounds transform their prototype AABBs. DEM is partitioned virtually into 2 km patches, retaining each triangle's complete vertices. Every bound receives **0.5 m padding**. This margin is a diagnostic hypothesis, not a proven maximum shader deformation; an implementation must derive conservative deformation bounds and retain intersecting features. No in-frustum occlusion rejection is credited.

| Main-only step | 40 m | 150 m | 600 m |
|---|---:|---:|---:|
| Original triangles / draws | 729,101 / 182 | 791,795 / 251 | 624,433 / 292 |
| Fine-frustum savings | 679,257 / 122 | 586,446 / 103 | 304,397 / 18 |
| After fine selection | 49,844 / 60 | 205,349 / 148 | 320,036 / 274 |
| After compatible 800 m pooling | 49,844 / 41 | 205,349 / 89 | 320,036 / 129 |

Triangle savings by semantic layer:

| Layer | 40 m | 150 m | 600 m |
|---|---:|---:|---:|
| Buildings | 219,552 | 181,737 | 84,602 |
| Roads | 30,151 | 22,601 | 5,736 |
| Terrain | 180,746 | 171,480 | 147,966 |
| Water | 266 | 378 | 0 |
| Props | 63,377 | 47,548 | 18,456 |
| Tree foliage | 181,889 | 162,702 | 47,637 |
| Other | 3,276 | 0 | 0 |

The entire 129,144-triangle DEM is outside these three frusta under patch bounds, although its whole-mesh bound passes. This is a general loose-bound false positive, not permission to disable mountains at a named camera. Put patches back whenever visible. Main visibility and shadow reach must be independent: retain off-camera casters in shadow passes. A fragment discard or depth rejection does not remove submitted triangles.

Pooling happens **after fine selection** and preserves geometry, transforms, materials and per-instance leaf tint/origin. Pool only matching material, vertex layout and exact prototype geometry; static vertices retain world transforms. Spatial bin sizes 200/400/800/1600 m model draws of **87/57/41/41** at 40 m, **276/139/89/89** at 150 m and **482/232/129/129** at 600 m. Small bins can increase draws. Replacing fine visibility with a giant merged bound would undo the triangle savings. CPU selection, upload bandwidth, allocations and frame churn are unmeasured costs. Global exact-compatible lower bounds are 40/58/48 draws; these are not an implemented packing strategy.

At **150 m**, fine selection removes 586,446 triangles and 103 draws; pooling removes another 59 draws without removing visible triangles. The combined modeled result **205,349 / 89** saves 586,446 triangles / 162 draws, leaving 194,650 triangles to the largest strict-floor integer (399,999) and 11 draws to the inclusive limit. This reaches the requested numbers without foliage thinning or a camera-specific exception. It still needs a rendered equivalence test and measured CPU/GPU cost. At 600 m, 129 modeled draws still fails floor and standard: additional compatible pooling or fewer projected-size LOD classes needs testing; do not silently promote overview to hero.

### Distance LOD, independently estimated

[web/src/world.js](../../web/src/world.js), lines 120–136, loads `c.lods[0]`; [WorldPackage.swift](../../Sources/WorldPackage/WorldPackage.swift), lines 147–148, exports both LODs. Substituting each submitted primitive's existing LOD1 when nearest 3D camera-to-chunk-bound distance is at least 400 m gives:

| Independent LOD rule, before fine culling | 40 m | 150 m | 600 m |
|---|---:|---:|---:|
| Eligible old triangles → LOD1 | 10,036 → 2,347 | 50,534 → 11,026 | 304,755 → 73,997 |
| Triangle savings | 7,689 | 39,508 | 230,758 |
| Resulting main, same draw count | 721,412 / 182 | 752,287 / 251 | 393,675 / 292 |

These savings overlap fine culling; **do not add them**. 150 m LOD alone fails both limits; 600 m LOD alone passes triangles but fails draws. Package-wide LOD0/LOD1 totals are 451,993/133,245, not camera savings. Check silhouette, roads, shore coverage, hysteresis and hold-outs before adopting the substitution.

Web prop LOD (`world.js:204–222`) uses horizontal x/z distance and an 8 m rebucket threshold. Changing altitude alone can retain near meshes beneath an aerial camera. General projected-size or 3D-distance selection, with hysteresis and FOV/viewport changes, addresses this. Its additional savings are **unmeasured**, not bankable. Facades already use projected-size LOD (`web/bakeoff/facades.js:40–64`); their 4,512 triangles / 4 draws at 150 m are a small contributor.

### Hidden and duplicate geometry

Hidden ground beneath buildings/water and rear surfaces require depth/occlusion evidence; frustum intersection alone cannot identify them. At 150 m the remaining terrain plus roads is 33,140 triangles, an upper candidate pool, **not a demonstrated occlusion saving**. Credit zero until coverage/depth/shadow requirements are established. Transparent water may need underlying ground.

An exact opaque static-triangle check, using world positions, all shipping vertex attributes and material identity, found only **2 / 2 / 4** repeated triangles at 40/150/600 m. It excludes instances, transparent water and DEM and uses no rounding. No whole-draw saving is established; credit zero. Coincident footprints are not proof of duplicate geometry. Verify source identity and depth/shadow roles before removal.

## iPhone / RealityKit applicability

These are transferable rules, not transferable savings. Current native code already differs substantially from web:

- `Sources/WorldEngine/World.swift:828–896` has widened-frustum visibility and shadow-caster union; `:871` already uses **3D** distance for props/foliage. Measure whether loose batch bounds or main submission of shadow-only casters remain. The web horizontal-distance prop correction is already present natively.
- `World.swift:559–592` building LOD uses horizontal camera-footpoint distance to bounds. Projected-size/altitude-aware selection can help; native buildings already have near/middle/far/skyline paths, so web's LOD0-only diagnosis is not its loader behavior.
- `World.swift:430–476` already merges ground/raised tiles: four 200 m cells (800 m), a **40,000** triangle ceiling. `:480–600` has building merging and a 2,000-triangle building allowance. `:737` onward groups props by kind/variant across the world. Audit existing boundaries before adding pooling; web's 59-draw saving cannot be promised natively.
- `World.swift:906–929` and `World+Context.swift:185` estimate visible batch triangles/draws from CPU bounds. SCENEREADY's completed Metal frames prove readiness, not exact per-layer RealityKit submissions. No equivalent 129,144-triangle web DEM was identified in native ground code; do not claim that native saving.

Measure matched street and 40/150/600 m poses, FOV, resolution, full context, date and capture exposure after scene-ready. Record **actual** main and every shadow pass's indices × instances, material draws, per-layer N/U/F classification, bounds rejects, denied LOD promotions and selected detail. Compare CPU estimates with Metal/RealityKit submissions and images; retain caster reach and alpha/depth coverage. Benchmark selection/upload costs, full-frame CPU/GPU p50/p95/p99, texture/mesh/render-target memory and peak resident memory. On R's **14 Pro / iOS 26.4.2**, measure sustained unplugged performance, thermal state and memory warnings. Simulator or desktop counts cannot qualify a device tier. This task ran no native capture or phone installation.

Historical [native summer BEFORE evidence](../research/crown-native-summer-before-evidence.md) reports CPU estimates 308,805/53, 331,895/50 and 227,442/43. Those use July conditions and another build, so they cannot validate the October web savings or substitute for matched native measurements.

## Camera classes and tier contracts

Use device-qualified quality tiers; altitude must not automatically raise a budget. All limits below are main triangles / shadow triangles / main draws from budget-tiers, not measured hardware capacity.

| Camera class | Recommended target | Reason |
|---|---|---|
| Saved street / ordinary navigation | Floor: **<400k / ≤150k / ≤100** | Saved 347,177/99 main already fits; retain shadow/performance checks. |
| 40 m close inspection | Floor fallback; optional qualified standard **≤500k / ≤180k / ≤120** | Prioritize nearby silhouettes/detail; exact original 729,101/182 fits neither. Fine visibility can avoid wasting allowance. |
| 150 m aerial inspection | **Floor** acceptance target | Requested general-rule model reaches 205,349/89; no tier increase required. |
| 600 m overview | **Floor** with coarse projected detail and a draw allowance | Wide coverage needs fewer detail classes and compatible batches, not a larger altitude-based tier. Modeled 129 draws is still unresolved. |
| Explicit beauty/archive mode | Hero proposal **≤600k / ≤225k / ≤140**, only after qualification | Optional quality setting, never a workaround for default camera failures. Original ladder totals all exceed its main limits. |

Standard is a prototype hypothesis tested on R's 14 Pro, not certified phone capacity; hero is experimental. Floor hardware intent is iPhone 12–13; R is not optimizing specifically for iPhone 13. The historical Lakeview 414k versus 400k overshoot remains a floor failure; this Sloan's model does not resolve it. `CrownLODAllocator.swift:58` currently applies strict `<150k` shadows and `<100` draws, unlike the inclusive shadow/draw contract here. Flag for a separate implementation decision; this document changes neither helper nor budgets.

## Reproduction and validation record

The temporary CPU analysis script is `~/`-independent at `/private/tmp/a10-budget-diagnose.mjs`, SHA-256 `0a96ada6f43c88eec5496a6fa7cfe8f2b69a7418ac9105246f443ab808903503`; results `/private/tmp/a10-budget-diagnosis-results.json`, SHA-256 `3ab82a1addd187b12a406b8ae6aff4c6a2e5ea9310d6eea11916cf8468511027`. Temporary files are not durable repository artifacts; the rules and numerical tables above are the retained evidence. Node v24.12.0 uses existing Three dependencies and frozen A7 assets. Analysis retains package feature IDs in memory solely for semantic attribution; shipping loader/source stays unchanged.

CPU model runs used `scripts/heavy.sh`, each releasing admission afterward; final padded run admitted at load **5.75**, below 25, exited 0. No heavy lock is held by this task. Arithmetic checks verify semantic sums, exclusive-plus-distinct-mixed draw totals, pass totals, all sequential savings and the strict-floor result. Docs-only merge requires no new capture, build or full suite.

## Ledger text for A3

A10 diagnosis: October web OFF ladder exceeds main budgets because loose scene bounds submit off-screen static features/instances and DEM, while props/foliage dominate draw fragmentation. Exact saved totals reconstructed; finer padded visibility plus compatible 800 m pooling models 150 m 205,349 triangles/89 draws, not an implemented or native-qualified pass. LOD savings overlap culling; hidden/duplicate savings unproven/negligible. 600 m draw floor remains unresolved. Native already has several analogous rules; actual per-pass/device measurements remain pending. No ledger or render code edited.
