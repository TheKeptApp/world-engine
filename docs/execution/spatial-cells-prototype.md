# Lossless spatial-cells prototype — 2026-10-09

**Later ordering repair:** [spatial-order-and-shadow-diagnosis.md](spatial-order-and-shadow-diagnosis.md) supersedes the three failed fixed-view pixel comparisons below: twelve fresh views are exact, with draw-count regressions. This document retains the original prototype evidence; no budget/motion/native promotion follows.

## Contract and scope

Implements the first prototype of [ff4f86e](spatial-cells-design.md): default-off `?spatialCells=1` (`spatialGroup=400|800`, default 800), crown/foliage experiments OFF, Sloan/Lakeview execution only. The normal entry still imports shipping `main.js`; no experiment module or interception is installed unless explicitly requested. Shipping `main.js`, `web/src`, native renderer, shaders, budgets, crowns and the shipping exporter are unchanged.

The opt-in exporter post-stage (`web/bakeoff/tools/export-spatial-cells.mjs`) reads an existing package, parses complete LOD0 feature ranges, and emits an ignored `spatial-cells.json` sidecar: 100 m owner leaves, 200 m page descriptors, compatible 400/800 m group addresses, exact local indices/bounds, prototype/instance ownership and source manifest/file fingerprints. Complete crossing features have a single owner with their full bounds; no clipping or simplification. Instance owner points are storage metadata, not visibility bounds. Sidecar sizes on the existing focused packages are 9,750,553 bytes for Sloan (70 geometry fingerprints, 48 occupied static owner pages) and 9,011,980 bytes for Lakeview (26 fingerprints, 36 pages). These are uncompressed JSON prototype sizes, not a bandwidth target. All placements, geometry and attribute bytes remain in the original package. The sidecar is additive and never modifies its manifest or GLBs.

`spatial-cells.js` consumes those ranges, traverses precomputed page/leaf bounds and selects partial-leaf features. Compatible static vertex arrays are assembled once at load/replacement; selection indices and instance matrices/attributes use bounded reused arrays. Final shader/material/layout/model-transform compatibility is verified at load time; it is not assumed from material names. Static transforms and local instance matrix bytes are retained rather than rebaked to world Float32 coordinates. Whole buffers are not cloned, disposed or reallocated for a camera move. The reported `bufferBytes` counts owned selection/assembled-vertex arrays only; shared prototype vertices, original source assets, textures, targets and driver residency are outside it. Source meshes remain alive for existing LOD/tuft updates, outside the main layer; original shadow proxies remain unchanged. Derived runtime facade/DEM geometry gets cached metadata at initial load/replacement, rather than invented offline provenance.

This prototype loads the entire existing core. The 200 m pages are indexed resident resource groups, **not implemented network streaming/eviction**. Static vertex assembly is still an initialization operation; this is not a new fully premerged GLB format. Dynamic instance LOD replacements can rebuild affected resources; long-path GPU residency/performance remains unqualified. Export-time final material identity and native premerged tile consumption remain future work. These limits must not be presented as delivery of the whole streamed-context design.

## Gates and reproducible commands

Each export/capture invocation takes its own `scripts/heavy.sh` admission, requires load below 25 and releases the lock immediately afterward. At least 8 GiB disk free; no phone installs. Run the standalone exporter post-stage against existing Sloan/Lakeview package directories, then `qualify-spatial-cells.mjs bakeoff sloans|lakeview NEW_DIRECTORY`. For shipping-scoreboard comparisons, use the retained hash-verified `Generated/web-capture/scoreboard-AREA` packages and `qualify-spatial-cells.mjs scoreboard AREA NEW_DIRECTORY`; only the two authorized areas enable the variant, the other six run default.

The lossless gate is **decoded RGBA exactly zero**, across the full 1005×565 screenshot. Independent fresh/default-repeat control is separate: max ≤2/255 normalized (=2 byte levels), mean ≤1e-3 byte units. A noisy control cannot prove equivalence; variant differences are reported even if they fit the control allowance. All differing bytes and every occupied 32-pixel region are retained in JSON. No crop/mask, scoring or promotion. Fixed exposure, original dates, poses and height-dependent near plane remain unchanged.

The A7 scoreboard uses shipping package lighting/materials and whole-area exports; the earlier spatial model used bakeoff look, focused packages and additional generated detail. Counts from those contracts must not be compared as if they were the same render. All 24 scoreboard views are reported; other six areas are explicitly default-only, not spatial hold-out qualification. Scoreboard V1 repeats failed because the shipping materials use Three's live TSL time for water ripple and crown sway. Those pixel comparisons are superseded. V2 pins `renderer._nodes.nodeFrame.time` and `deltaTime` to zero before the served copy renders both default and variant; this is a capture-only clock override, not a shader/default-route change. Other six areas remain count-only observations with their original live clock. The capture harness modifies only its served copy of the shipping scoreboard page, using layer-1 original-geometry shadow proxies so main selection cannot drop casters. On-disk shipping capture page is unchanged.

## Stage 2 gate

No simplified far parent is enabled by Stage 1. `spatialFar` is rejected until the lossless gate is qualified. A future separate flag must export conservative object-space error E and complete camera-space bounds; projected error is bounded using drawable height, vertical FOV and minimum positive depth, with no simplification across the eye/near plane. `E × height / (2 tan(FOV/2) depthMin)` is a planning estimate, not an exact-pixel guarantee; silhouettes, attributes, roads/water seams and shadows require their own evidence. A3 reviews any later parent variant. No score or promotion is claimed here.

## Evidence

First diagnostic batch v1 is retained in `/private/tmp/a10-spatial-{sloans,lakeview}-v1/`. Its harness stopped the animation loop before applying the existing frozen-time witness, so animated-water differences/noise are not a valid lossless gate. It also preceded the final source-revision guard. The corrected v2 batch applies the shipping worker's two completed animation callbacks with `freeze=true` before stopping and finishing GL; no render code or water behavior changes. The frozen v2 capture revealed 5,520,406,328 owned array bytes on Sloan because terrain vertex arrays were copied per group. That prototype is superseded. V3 shares immutable vertex attributes once per compatibility key (directly reusing source attributes for a single source), keeps group-specific sort centres and reuses only selection indices/instance data. A new test proves multiple groups share the original position attribute and allocate only their bounded index buffers. V3 is the final qualification candidate; previous frames remain intact. Sharing does not imply that the existing full-core/background source arrays disappear from residency. The prototype still needs source-asset and driver accounting, and a paging/eviction implementation, before a memory/device claim. Twenty-two focused regression tests pass (ten new prototype tests, seven existing scene-budget tests and five qualification-helper tests). Focused tests cover default-off validation, negative cell addresses, complete feature bounds, geometry/attribute/matrix preservation, bounded buffer reuse during camera movement, 400/800 grouping and retirement of replacement resources. Ledger text for A3 is retained here, not in the shared integration ledger.

## Corrected capture gate and model comparison

Decision: **lossless-pixel-gate-failed**. All 12 fresh/default-repeat controls are decoded-RGBA exact; the separate control-noise allowance is not used to excuse variant differences. Simplified far parents remain blocked; no promotion or score.

| Area/height | Default T/D | Lossless T/D | Model fine T/D | Max / mean byte diff | Changed bytes; every 32px region origin |
|---|---:|---:|---:|---:|---|
| sloans-40 | 729,101/182 | 49,844/45 | 49,844/45 | 0 / 0 | 0; none |
| sloans-150 | 791,795/251 | 205,349/75 | 205,349/75 | 0 / 0 | 0; none |
| sloans-600 | 624,433/292 | 320,036/112 | 320,036/112 | 0 / 0 | 0; none |
| lakeview-40 | 320,733/112 | 47,686/43 | 47,686/43 | 46 / 0.00031303658697662132 | 19; [[0, 96], [64, 96]] |
| lakeview-150 | 323,901/131 | 150,628/64 | 150,628/64 | 42 / 9.598027561308502e-05 | 6; [[256, 544]] |
| lakeview-600 | 209,528/101 | 72,065/32 | 72,065/32 | 0 / 0 | 0; none |

All six bakeoff count projections match the calibrated model exactly. Equal triangle/draw counts do not establish exact pixels. Pooling changes primitive/object ordering and bounds used for render sorting; this is a possible cause, not proven attribution. No shader or tolerance change hides a failure. Sloan 600 m remains **112 >100 draws**.

## All 24 A7 scoreboard views

| View | A7 prior T/D | Fresh default T/D | Prototype T/D | Default delta T/D | Scope |
|---|---:|---:|---:|---:|---|
| evanston-south/40 | 544,177/214 | 544,177/214 | OFF | 0/0 | default-only |
| evanston-south/150 | 506,058/204 | 506,058/204 | OFF | 0/0 | default-only |
| evanston-south/600 | 342,496/211 | 342,496/211 | OFF | 0/0 | default-only |
| greenville-downtown/40 | 417,590/111 | 417,590/111 | OFF | 0/0 | default-only |
| greenville-downtown/150 | 461,301/171 | 461,301/171 | OFF | 0/0 | default-only |
| greenville-downtown/600 | 429,835/199 | 429,835/199 | OFF | 0/0 | default-only |
| kenilworth-station/40 | 430,028/198 | 430,028/198 | OFF | 0/0 | default-only |
| kenilworth-station/150 | 425,114/216 | 425,114/216 | OFF | 0/0 | default-only |
| kenilworth-station/600 | 361,786/213 | 361,786/213 | OFF | 0/0 | default-only |
| lakeview-sheil-park/40 | 1,057,862/210 | 1,057,862/210 | 38,224/37 | 0/0 | prototype |
| lakeview-sheil-park/150 | 1,181,951/224 | 1,181,951/224 | 323,705/81 | 0/0 | prototype |
| lakeview-sheil-park/600 | 936,137/203 | 936,137/203 | 486,482/56 | 0/0 | prototype |
| sloans-lake/40 | 656,467/169 | 656,467/169 | 54,974/41 | 0/0 | prototype |
| sloans-lake/150 | 785,361/238 | 785,361/238 | 203,078/70 | 0/0 | prototype |
| sloans-lake/600 | 502,798/285 | 502,798/285 | 313,611/109 | 0/0 | prototype |
| west-highland/40 | 818,648/233 | 818,648/233 | OFF | 0/0 | default-only |
| west-highland/150 | 747,771/239 | 747,771/239 | OFF | 0/0 | default-only |
| west-highland/600 | 599,781/222 | 599,781/222 | OFF | 0/0 | default-only |
| wilmette-vattmann-park/40 | 553,853/191 | 553,853/191 | OFF | 0/0 | default-only |
| wilmette-vattmann-park/150 | 534,459/207 | 534,459/207 | OFF | 0/0 | default-only |
| wilmette-vattmann-park/600 | 366,066/197 | 366,066/197 | OFF | 0/0 | default-only |
| winnetka-village-green/40 | 326,717/180 | 326,717/180 | OFF | 0/0 | default-only |
| winnetka-village-green/150 | 324,009/197 | 324,009/197 | OFF | 0/0 | default-only |
| winnetka-village-green/600 | 236,963/202 | 236,963/202 | OFF | 0/0 | default-only |

Other six areas were freshly observed on unchanged default, not extrapolated or given prototype sidecars. The complete JSON includes package-lighting camera/exposure metadata, every default/repeat/variant image hash and pass breakdown, variant pixel differences and every occupied 32px region. The additive prototype does not promote the old scoreboard or its still-failing default floor budgets.

### Scoreboard prototype pixels and 600 m failures

| View | Max / mean byte diff | Changed bytes; regions | Main floor |
|---|---:|---|---|
| lakeview-sheil-park/40 | 0 / 0 | 0; none | PASS |
| lakeview-sheil-park/150 | 0 / 0 | 0; none | PASS |
| lakeview-sheil-park/600 | 2 / 2.2013824681900235e-06 | 3; [[480, 320]] | FAIL |
| sloans-lake/40 | 0 / 0 | 0; none | PASS |
| sloans-lake/150 | 0 / 0 | 0; none | PASS |
| sloans-lake/600 | 0 / 0 | 0; none | FAIL |


## Unchanged shadow cost

All six shipping prototype/default shadow pass counters match exactly. Main-only floor PASS entries above do not imply whole-scene compliance: every shipping prototype view still fails a required main or shadow limit.

| View | Shadow triangles/draws | Whole-scene floor |
|---|---:|---|
| lakeview-sheil-park/40 | 924,485/123 | FAIL |
| lakeview-sheil-park/150 | 996,184/149 | FAIL |
| lakeview-sheil-park/600 | 2,280/1 | FAIL |
| sloans-lake/40 | 560,465/111 | FAIL |
| sloans-lake/150 | 572,162/113 | FAIL |
| sloans-lake/600 | 75,831/4 | FAIL |

## Resource and handoff limits

Final measured initialization: sloans: 13,868,288 owned array bytes, 2246 allocated pool objects, 2118 resident page bounds / 2227 leaves (including the unchanged large background on Sloan); lakeview: 15,686,764 owned array bytes, 131 allocated pool objects, 36 resident page bounds / 100 leaves (including the unchanged large background on Sloan). Each stationary run records one initialization rebuild and zero subsequent resource rebuilds. Initial update including setup is 159.6–170.2 ms Sloan /103–106.6 ms Lakeview; this is not a steady-motion CPU timing. Owned buffer capacities and initialization rebuild counts are recorded per frame in the JSON. Unit tests prove bounded reuse for camera-only updates; no sustained GPU driver-residency or phone performance claim follows. Full core residency, JSON sidecar size and runtime-derived facade groups remain prototype limitations. Export schema and stable resources need an implementation review before a streamed-context adapter or RealityKit translation. Context and crowns remain separate and unchanged.

[Machine-readable evidence](../../web/bakeoff/evidence/spatial-cells/manifest.json). Local frames remain in `/private/tmp/a10-spatial-{sloans,lakeview}-v3/` and `/private/tmp/a10-spatial-scoreboard-AREA-{v1,v2}/`; old ladders and live-clock scoreboard pairs are preserved. V2 is the frozen-clock scoreboard gate for Sloan/Lakeview; the other six areas are V1 default-count observations only. Images are not committed. Phone-size side-by-sides are retained at `/private/tmp/a10-spatial-sloans-v3/phone-comparison.png` and `/private/tmp/a10-spatial-lakeview-v3/phone-comparison.png`; full-resolution bytes, not the scaled previews, determine the gate.

## Validation and source integrity

All final export/capture jobs admitted at load 4.36–11.43 (<25), with separate lock releases and watchdogs. The focused prototype/qualification tests pass 22/22; after rebasing onto current main, the expanded prototype, capture-contract and scoreboard checks pass 48/48 under heavy admission at load 3.44. Main moved with documentation and the unrelated Wilmette camera-contract correction; no affected renderer source changed. All 24 default submission counts exactly reproduce A7; six focused bakeoff predictions exactly reproduce the model; all 12 repeat controls are exact; all six shipping shadow counter pairs match. The exact variant pixel gate still fails and is not replaced by the control-noise allowance.

Shipping `web/bakeoff/main.js` SHA-256 remains `55b0834efc482a33a320e008c3c58d8a533dd9bdbc9b1b723fdc19a7e25e76d5`; `web/src/world.js` remains `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`, both byte-identical to the branch's main base. The additive entry change retains the same default import and no default hooks. Captures record the exact experiment source hashes; the later clock-pin addition affects the scoreboard branch of the harness only. No shader, default route behavior, budget, crown or native changes.

## Ledger text for A3

A10 spatial-cells exporter/runtime prototype is opt-in and unpromoted, lossless pixel gate FAIL on bakeoff Lakeview 40/150 m and shipping Lakeview 600 m. All 12 independent repeat controls exact; default scoreboard counts reproduced 24/24. Sloan 600 m stays 112 draws bakeoff /109 shipping; shipping Lakeview 600 m stays 486,482 triangles. Stage 2 is blocked by the exactness gate. Default shipping renderer, budgets and crowns unchanged. Final capture gates, scoreboard counts and remaining limitations are recorded above; no adoption or score follows from a triangle/draw reduction.

Used: spatial-cells-design.md §§Recommendation, Model, Exporter contract, Renderer responsibilities. Mock: matched retained default ladder/scoreboard frames. Deviation: additive sidecar and resident-core prototype; streamed eviction and simplified far parents not delivered.
