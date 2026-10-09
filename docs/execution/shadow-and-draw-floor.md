# Shadow selection and ordered-source draw reduction — 2026-10-09

## Stop for R

**Not merged.** Shadow qualification is complete; the draw target is not. The opt-in shipping Sloan 600 m view remains **313,611 main triangles / 106 draws**, six above the limit. R explicitly requested a stop if exact draw reduction cannot reach the target. No ordering relaxation, shader transform change, new capture or post-merge scoreboard follows that stop. The existing scoreboard remains pending because there has been no merge. No floor promotion is claimed.

The proposed code remains default OFF on `astra/a10-shadow-floor-exact`, based on `8f08c42`. `?shadowCells=1` enables shadow-only selection. `?spatialCells=1&spatialMergeRuns=1` enables source-run concatenation; add `&shadowCells=1` for the qualified combined shipping variant. Default entry still imports the same shipping main module. No native, shader, palette, budget, crown, LOD or shadow-reach changes. Shared ledgers are untouched.

## Shadow padding proof

The selector retains complete original per-source exported feature rows or instances. Feature provenance survives the loader’s `_feature` deletion in a WeakMap; bakeoff clones are matched to their original position stream. Missing provenance retains the whole source. Original indices, winding, instance matrices/attributes, material and instance-buffer capacity are preserved. The baseline’s broad-source light-frustum eligibility is retained; the option filters its caster set rather than adding casters the baseline omitted. Camera visibility is never used to reject a shadow caster.

Rigid Float32 vertex attributes are represented exactly in CPU bounds. Quantize uniform coefficients to Float32, then apply interval transforms separately for instance, model-view and projection stages. Use `u=2^-23`, `gamma8=8u/(1-8u)` times the sum of absolute products for each four-term dot product, plus `8*2^-126` for subnormal flushing. This covers highp multiply/add rounding, cancellation and interval evaluation for the measured finite transforms. Nonfinite intervals fail closed. With the existing orthographic camera, w=1 and clip bounds are [-1,1]^3. A disjoint enclosing interval proves no complete primitive in that feature/instance can rasterize map depth. No arbitrary metre margin is used. Receiver normal bias and PCF sampling do not expand the caster clip volume.

The [GLSL ES 3.20 specification §4.7.1](https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html#range-and-precision) bounds highp basic-operation errors but leaves sine/cosine numerical precision undefined. Shipping foliage wind uses them. Positive-sway foliage, unknown position/vertex/shadow deformation, morph/skinning, batched meshes, instance colours, grouped instance attributes, material arrays and unsupported precision retain complete original sources with **unbounded conservative padding**. Known zero-sway foliage can use the rigid bound. This is a safe fallback, not a claim to have proved a finite wind amplitude margin. The old .5 m model is superseded: Sloan’s unbounded submissions alone are 191,315 triangles at 40 m and 203,012 at 150 m, already above 150k.

## Shadow qualification

All **12 fixed views + 12 stress views**, and all 24 fresh-repeat controls, are exact: image max/mean/count **0/0/0** and sampled shadow-depth byte max/mean/count **0/0/0**. The readback encodes the exact Float32 depth values consumed by texture sampling, not underlying integer depth-storage bits. It runs after the screenshot and completed GPU work, then the page closes. No shipping shader or readback path is altered. Some 600 m maps are clear in the baseline; those are limited witnesses, not evidence of visible shadow coverage.

Fixed captures use the registered 40/150/600 m ladder, heading 270°, pitch down 45°, FOV 50°, 1005×565, 2026-10-15T20:30:00Z. Sloan is 39.7511195,-105.0389. Lakeview bakeoff is 41.945182,-87.66432; shipping-scoreboard Lakeview is 41.94567,-87.66361. These are distinct registered contracts, not interchangeable cameras. Shipping time/delta time are pinned to zero in the served capture-only page; bakeoff uses its existing freeze hook.

| Contract/area/height | Default shadow T/D | Selected shadow T/D | Triangle/draw delta |
|---|---:|---:|---:|
| scoreboard/sloans-lake/40 | 560,465/111 | 206,614/101 | -353,851/-10 |
| scoreboard/sloans-lake/150 | 572,162/113 | 223,517/105 | -348,645/-8 |
| scoreboard/sloans-lake/600 | 75,831/4 | 12,578/1 | -63,253/-3 |
| scoreboard/lakeview-sheil-park/40 | 924,485/123 | 83,662/110 | -840,823/-13 |
| scoreboard/lakeview-sheil-park/150 | 996,184/149 | 112,279/136 | -883,905/-13 |
| scoreboard/lakeview-sheil-park/600 | 2,280/1 | 2,280/1 | +0/+0 |
| bakeoff/sloans/40 | 69,639/62 | 61,209/60 | -8,430/-2 |
| bakeoff/sloans/150 | 67,961/42 | 21,291/32 | -46,670/-10 |
| bakeoff/sloans/600 | 0/0 | 0/0 | +0/+0 |
| bakeoff/lakeview/40 | 76,124/79 | 67,505/76 | -8,619/-3 |
| bakeoff/lakeview/150 | 73,212/62 | 26,436/51 | -46,776/-11 |
| bakeoff/lakeview/600 | 0/0 | 0/0 | +0/+0 |

The bakeoff route already has its own caster selection and far geometry; those existing choices are preserved. The new option introduces no additional LOD or reach reduction. Shipping Sloan remains above 150k at 40/150 m; all fixed Lakeview shipping heights meet the shadow-triangle cap. Owned new shadow buffers are 7,667,780 bytes Sloan / 19,460,356 Lakeview shipping and 676,108 / 802,816 bakeoff. Shared vertex data, originals, textures, driver allocations and native cascades are excluded; these are not total device-memory measurements.

Stress recipes are general: `light-edge` offsets latitude by 40/111320° from the registered 150 m pose; `offscreen-caster` uses heading 90° and FOV 25° at 150 m; `low-sun` uses 8 m, horizontal pitch and a synthetic 6.5° directional-light elevation, preserving azimuth, light distance, map settings and projection/reach. The low-sun lighting is explicitly synthetic, not a solar/date claim. The frame must contain non-clear depth; edge/off-screen variants must contain corresponding light-frustum bounds witnesses. These witnesses do not claim individual depth ownership.

| Stress contract/view | Default → selected shadow T/D | Edge / off-screen instance witnesses | Non-clear depth texels |
|---|---:|---:|---:|
| scoreboard/sloans-lake/light-edge | 526,080/118 → 246,251/112 | 70 / 130 | 2,765,087 |
| scoreboard/sloans-lake/offscreen-caster | 581,616/117 → 232,395/111 | 87 / 93 | 2,483,136 |
| scoreboard/sloans-lake/low-sun | 579,573/126 → 255,580/120 | 129 / 387 | 2,689,167 |
| scoreboard/lakeview-sheil-park/light-edge | 1,003,011/147 → 116,571/138 | 19 / 105 | 2,771,275 |
| scoreboard/lakeview-sheil-park/offscreen-caster | 933,875/146 → 114,457/133 | 29 / 57 | 3,169,049 |
| scoreboard/lakeview-sheil-park/low-sun | 995,299/145 → 147,398/138 | 46 / 116 | 2,734,448 |
| bakeoff/sloans-light-edge | 68,282/41 → 22,466/29 | 46 / 236 | 521,754 |
| bakeoff/sloans-offscreen-caster | 68,081/42 → 21,411/32 | 41 / 182 | 523,296 |
| bakeoff/sloans-low-sun | 69,639/62 → 63,106/62 | 34 / 560 | 701,764 |
| bakeoff/lakeview-light-edge | 74,353/67 → 27,552/45 | 12 / 82 | 456,832 |
| bakeoff/lakeview-offscreen-caster | 73,308/62 → 26,532/51 | 4 / 100 | 451,572 |
| bakeoff/lakeview-low-sun | 76,124/79 → 69,672/76 | 5 / 252 | 729,921 |

## Draw reduction and exact limit

`spatialMergeRuns=1` concatenates a single original source’s contiguous ordered runs into one reusable index buffer. Per-feature selection is independent; retained indices remain in original primitive order. Source material, model transform, source sphere/sort centre and source ID are unchanged. Different original sources remain separate ordering units. No geometry simplification, vertex rebake, depth offset or ordering relaxation is used. Merely emitting the same runs offline changes startup work, not these draw counts. A4’s separate offline-run emission is not consumed or merged here.

All **six shipping combined views + six repeat controls** are exact against fresh default in both image and sampled depth. They are also exact image 0/0/0 against the previous repaired ordered-run frames. Main triangle counts are unchanged by concatenation. Bakeoff draw qualification is pending after the required stop; do not extrapolate shipping draw counts to it.

| Shipping view | Prior ordered-run main T/D | Concatenated main T/D | Draw delta |
|---|---:|---:|---:|
| sloans-lake/40 | 54,974/42 | 54,974/41 | -1 |
| sloans-lake/150 | 203,078/72 | 203,078/68 | -4 |
| sloans-lake/600 | 313,611/111 | 313,611/106 | -5 |
| lakeview-sheil-park/40 | 38,224/86 | 38,224/35 | -51 |
| lakeview-sheil-park/150 | 323,705/234 | 323,705/76 | -158 |
| lakeview-sheil-park/600 | 486,482/163 | 486,482/54 | -109 |

Lakeview 150 m reaches 76 draws, saving **158 draws** versus ordered runs; Lakeview 600 m reaches 54, saving 109. Sloan 600 m reaches 106, saving only five. Its remaining pass breakdown is **36 opaque-world + 27 water + 42 instances + 1 sky/composite**. Shipping Lakeview 600 m also remains **486,482 main triangles**, 86,482 above 400k (the strict `<400k` gate requires at least 86,483 fewer). Sloan shipping shadow overshoots remain **56,614 / 73,517 triangles** at 40/150 m. The floor target is therefore not achieved.

### Adjacent-state probe: no compatible groups

A bounded prototype examined adjacent already-sorted opaque submissions, preserving actual primitive order and requiring identical material, attribute representation, model transform, clipping state and other render state. It allocated resources only at setup and excluded shadow/post cameras. Five focused tests passed, including raw interleaved/normalized attribute copying and stable buffers through reordered runs. The shipping Sloan captures remained exact, but the probe found **zero compatible static families**, zero pooled bytes and **zero draw saving** at every height; 600 m stayed 106. It was removed from the proposed runtime rather than retained as dead complexity. Source and tests are preserved at `/private/tmp/a10-adjacent-draws-rejected/`; full capture evidence is `/private/tmp/a10-shadow-draw-scoreboard-sloans-v3/qualification.json`.

The exported chunks have distinct model translations, e.g. `chunk 0_0 lod0` [-700,0,500], `chunk 0_1 lod0` [-700,0,300], `chunk 0_2 lod0` [-700,0,100]. Static and water use different materials. The current shader binds one source model-view transform per ordinary draw. Adjacent run concatenation cannot collapse those distinct states while preserving that compiled transform evaluation.

An ordinary per-material cross-cell pool would relax the current depth/source ordering of interleaved submissions and require rebaking different chunk translations, risking changed Float32 transform evaluation. **Ordering relaxation alone is insufficient** to remove the distinct transform states. Neither rebaking nor material-first reordering is authorized, and no evidence proves either preserves 0/0. A new matrix-preserving batching mechanism could be investigated under a new instruction, but is unproved. Zero-raster/occlusion culling, native batching and other renderer designs were not tested; this is a limit of the requested ordinary ordered-run pooling, not a proof of impossibility for every renderer. R’s stop gate is invoked; the pixel gate remains exact.

## Evidence and validation

Reconciled machine evidence: [shadow-draw-floor.json](../../web/bakeoff/evidence/spatial-cells/shadow-draw-floor.json), generated by `summarize-shadow-draw-floor.mjs` from four shadow-only, four stress and two combined reports. It rejects incomplete batches, nonzero image/depth differences, counter mismatches, reach/LOD changes and missing stress witnesses. Its draw gate is explicitly **failed**; it reports remaining floor failures rather than suppressing them. It retains ordered-run deltas and the rejected adjacent probe. Images and 2048² sampled-depth binary files stay out of Git.

Accepted report directories (each has `qualification.json` and frames):

- `/private/tmp/a10-shadow-cells-scoreboard-{sloans,lakeview}-v3`
- `/private/tmp/a10-shadow-cells-bakeoff-sloans-v4` and `...-lakeview-v5`
- `/private/tmp/a10-shadow-stress-{scoreboard,bakeoff}-{sloans,lakeview}-v1`
- `/private/tmp/a10-shadow-draw-scoreboard-{sloans,lakeview}-v1`

Normal frames are `{40,150,600}-{default,repeat,lossless}.png`; stress frames are `{light-edge,offscreen-caster,low-sun}-{default,repeat,lossless}.png`. Matching sampled-depth files end `.shadow-depth.bin`. Phone-size default/variant pairs were inspected at `/private/tmp/a10-shadow-draw-phone-{sloans,lakeview}.png`; raw pixels, rather than resized previews, determine the gate. Mock closeness is unchanged by exact pixels; no new score is claimed.

All captures used `scripts/heavy.sh` with admissions below 25, releasing A10’s lock after each run. Accepted loads: 4.24/7.98/7.68/5.76 (fixed shadows), 4.97/5.08/4.83/5.47 (stress), 7.20/5.55 (combined). A5/A7 waits were respected. One sandboxed admission could not read system load and timed out without starting; the system-load access retry admitted normally. No other lock was modified. Disk stayed above 8 GB.

Recovered failures remain archived: first static proxy creation failed with `Cannot set properties of null (setting name)`; bakeoff then exposed an undefined optional sphere (`reading center`); both were fixed and regression-tested. One Lakeview batch was rejected because the capture harness changed during its run, despite exact frames; its frozen-source V5 rerun passed. No failed batch is counted as accepted.

**21 retained focused tests pass**: 7 shadow interval/provenance/capacity/null-bound tests and 14 spatial selection/order/buffer tests, including the two new source-concatenation tests. Capture modules pass syntax checks; diff whitespace checks pass. The rejected adapter’s five tests are separate. No new capture follows the stop. Final retained core files match the accepted combined V1 source hashes byte-for-byte. Shipping `web/bakeoff/main.js`, all `web/src/` and native shaders are unchanged versus branch base. SHA-256:

- `web/bakeoff/main.js`: `2e1d8a6729dc6c7c4b38980016c2741a962a8229bfeeef209d496cec50efa44b`
- `web/src/world.js`: `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`
- `web/src/materials.js`: `9256b5c5114bb5cfe6af915251ffcd6f3a6648c68d013dbbc86900bbe0a41883`
- `Sources/WorldEngine/Shaders/WorldShaders.metal`: `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`

Native RealityKit performance, moving-camera image equivalence, sustained CPU/GPU cost and total memory remain unqualified. The six shipping measurements do not prove all 24 scoreboard views. Main merge and the requested post-merge existing scoreboard are pending R’s decision.

## Ledger text for A3

A10 branch only, no promotion/merge: conservative original-caster selection passes 12 fixed + 12 edge/offscreen/low-sun comparisons and 24 repeats at exact image/sampled-depth 0/0. Shadow counts and the proven rigid/highp interval plus unbounded-deformation fallback are above. Shipping Sloan 40/150 remains 206,614/223,517 shadow triangles. Same-source ordered-run concatenation passes six shipping views and repeats at exact 0/0; Lakeview 150 draws 234→76, Lakeview 600 163→54, Sloan 600 111→106. No compatible cross-source ordinary draw groups remain; halted for R without ordering or transform relaxation. Shipping Lakeview 600 still 486,482 main triangles. Default OFF, shipping/native sources unchanged; shared ledger and existing post-merge scoreboard remain pending.

Used: spatial-order-and-shadow-diagnosis.md §§General repair, Proposed option 1; GLSL ES 3.20 §4.7.1. Mock: retained matched default ladder/scoreboard frames. Deviation: floor not achieved; stopped for R, not merged, post-merge scoreboard pending.
