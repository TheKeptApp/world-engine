# Spatial prototype ordering repair and shadow diagnosis — 2026-10-09

## Scope

R requested attribution of the three failed exact-pixel comparisons, a prototype-only repair, twelve fresh qualification views, and read-only shadow analysis. `?spatialCells=1` remains default OFF. Shipping sources, material/shader values, budgets, crowns and shadow reach are unchanged. Ledger text belongs here for A3; shared ledgers are not edited.

## Attribution

The earlier retained qualification reports and the new read-only ray probes reproduce all three failures. Pixel coordinates are full-resolution 1005×565; report regions are 32-pixel bin origins. Ray probes use the pixel centre and the four conventional rotated-grid MSAA locations; these are geometric witnesses, not a claim to read this GPU's implementation-specific sample locations. Mesh IDs/material IDs below are the IDs in each recorded diagnostic run, not persistent asset IDs. Three r180's common opaque comparator is `(groupOrder, renderOrder, clip-space z, object ID)`; it does **not** sort by material ID. Sort depth uses the source geometry bounding-sphere centre transformed by model and projection matrices, without perspective division.

| Contract/view; bytes/regions | Objects, material and ordering witnesses |
|---|---|
| Bakeoff Lakeview 40 m; 19 bytes; [0,96], [64,96] | Pixels (0,125), (1,125), (5,125), (6,125), (11,125), (64,125), (65,125). `Scene/Pack facade detail tiers/Mesh` (material ID 289, unnamed MeshStandardNodeMaterial, vertex `color`) overlaps `Scene/World/Group/chunk_1_1_lod0` (material ID 290, bakeoff static MeshStandardNodeMaterial, `_paint` slot 55 and `_facade` brick attributes). Building `way/209904591`, original faces 42957/42958. Default facade key (0,0,97.1321488701758,1197), chunk key (0,0,101.0721679866381,32). Pooled facade key (0,0,135.22935360720862,1422), pooled chunk key (0,0,101.0721679866381,1302). Pooling unions facade geometry bounds and reverses the two objects' draw order at coplanar surfaces. |
| Bakeoff Lakeview 150 m; 6 bytes; [256,544] | Pixels (283,546), (285,546), same facade/building and materials. Default facade key (0,0,119.97833095257435,1197), chunk key (0,0,123.91979500764218,32); pooled facade key (0,0,158.08950722635865,1422), chunk key (0,0,123.91979500764218,1302). Same ordering reversal; ray distances on the overlap are 162.08692287674322 and 162.0869239626518 m. |
| Shipping Lakeview 600 m; 3 bytes; [480,320] | Pixel (500,344). `Scene/World/Group/chunk_0_2_lod0`, shipping `world.materials.static` (material ID 16, unnamed MeshStandardNodeMaterial), buildings `way/209906274` and `way/209906288`. Original faces 38583 and 38674 share the same ray depth 773.6429922359656 m at the (.125,.625) probe, `_paint` slot 1, flags 4, AO .72. Source key (0,0,410.92115723618974,18). Cell-pool IDs 2675/2676 share z but submit original face 38674 before 38583, reversing primitive order. This is a building overlap, not a road attribution. Generated ground and boundary are also behind this sample; their ray depths are recorded separately. |

Pre-repair diagnostics: `/private/tmp/a10-spatial-order-diagnostics-lakeview-v1/qualification.json` and `/private/tmp/a10-spatial-order-diagnostics-shipping-lakeview-v1/qualification.json`. Full hit attributes, face indices, positions, model sort keys and image hashes are retained there. These are fresh controls against unchanged default and reproduce the previous 19/6/3 differing bytes exactly.

## General repair

The prototype keeps each static source as an ordering unit; it shares that source's original vertex attributes and bounding-sphere centre. It reconstructs original primitive order from exported feature rows, creating **contiguous ordered runs** whenever a source revisits a 400/800 m cell. Equal-depth runs retain the original source ID then run order. This preserves the ordering contract instead of offsetting geometry, changing depth bias, changing materials, skipping failed pixels or loosening the exact gate. Contiguous runs can increase draws and resident pool objects; measurements below are authoritative and supersede the old counts. Original instance pooling remains unchanged apart from the source-ID tie-break witness. New tests cover a source revisiting a cell with interleaved features, and preservation of a non-default source sphere centre/ID. The read-only diagnostic module is loaded only by an explicitly requested capture probe, never by shipping entry.

## Qualification

All **12/12 variant comparisons and 12/12 fresh-repeat controls are exact**: max 0, mean 0, differing bytes 0, no differing regions. The three previous failures reproduce before repair and disappear after preserving ordering. No tolerance is used to pass the variant. Every shipping shadow counter pair remains equal.

| Contract/area/height | Default main T/D | Repaired prototype T/D | Prior prototype draws | Pixel max/mean |
|---|---:|---:|---:|---:|
| bakeoff/sloans/40 | 729,101/182 | 49,844/47 | 45 | 0/0 |
| bakeoff/sloans/150 | 791,795/251 | 205,349/79 | 75 | 0/0 |
| bakeoff/sloans/600 | 624,433/292 | 320,036/114 | 112 | 0/0 |
| bakeoff/lakeview/40 | 320,733/112 | 47,686/76 | 43 | 0/0 |
| bakeoff/lakeview/150 | 323,901/131 | 150,628/181 | 64 | 0/0 |
| bakeoff/lakeview/600 | 209,528/101 | 72,065/131 | 32 | 0/0 |
| scoreboard/sloans-lake/40 | 656,467/169 | 54,974/42 | 41 | 0/0 |
| scoreboard/sloans-lake/150 | 785,361/238 | 203,078/72 | 70 | 0/0 |
| scoreboard/sloans-lake/600 | 502,798/285 | 313,611/111 | 109 | 0/0 |
| scoreboard/lakeview-sheil-park/40 | 1,057,862/210 | 38,224/86 | 37 | 0/0 |
| scoreboard/lakeview-sheil-park/150 | 1,181,951/224 | 323,705/234 | 81 | 0/0 |
| scoreboard/lakeview-sheil-park/600 | 936,137/203 | 486,482/163 | 56 | 0/0 |

The exact repair **regresses draw counts**, especially Lakeview: 150 m now exceeds 100 draws in both contracts (181 bakeoff, 234 shipping). All 600 m views exceed 100; shipping Lakeview additionally remains 486,482 main triangles. No floor pass/promotion is claimed. This supersedes the earlier failed-pixel evidence only, not the broader motion/hold-out qualification.

New frames and full source hashes: `/private/tmp/a10-spatial-order-bakeoff-{sloans,lakeview}-v2/{40,150,600}-{default,repeat,lossless}.png` and `/private/tmp/a10-spatial-order-scoreboard-{sloans-lake,lakeview-sheil-park}-v1/{40,150,600}-{default,repeat,lossless}.png`; each directory contains `qualification.json`. Read-only probes and reconciled summary are retained in [order-shadow.json](../../web/bakeoff/evidence/spatial-cells/order-shadow.json). `summarize-spatial-order.mjs` requires all four reports, exact controls/variant gates and exact shadow-category reconciliation before writing that summary.

Pre-rebase V1 resources: bakeoff Sloan has 10,372 resident runs (formerly 2,246), 13,398,272 owned buffer bytes, 463.5–485.8 ms initialization; Lakeview has 1,100 runs (formerly 131), 5,726,212 owned bytes, 290.3–309.5 ms initialization. Shipping Sloan has 184 runs /14,302,892 owned bytes; Lakeview 1,128 /25,314,128. Shipping `updateMs` is a later LOD update witness (5.5–22 ms), not comparable to bakeoff initialization. Phone-size default/variant comparisons were inspected at `/private/tmp/a10-spatial-order-phone-{sloans,lakeview}.png`; the full-resolution exact byte gate is authoritative. GPU arrays remain bounded/reused; CPU span/index metadata, originals, textures and driver residency are excluded. Rebased bakeoff initialization ranges are 468.8–486.3 ms Sloan and 280.1–305.9 ms Lakeview, with unchanged capacities/owned bytes. Ordered runs should be emitted offline to avoid the new initialization work, but that exporter revision is not implemented here. Sustained motion/driver residency remain unqualified.

## Shadow diagnosis method and limits

The requested 560k–996k totals are the shipping-scoreboard shadow contract. Bakeoff's separate pre-existing caster filter uses a different light/map/caster policy; its lower counts are not evidence for a shipping or native fix. Shipping `web/src/lighting.js` keeps a 2048² map, ±40 m orthographic extent about the camera **target**, near 1/far 400; source meshes are all LOD0 and props use current main-camera LOD. Shadow submission uses the mesh/group bounding sphere, then submits all its indices/instances. `web/src/world.js` sets static chunks and instances as casters, with BackSide shadow materials; flat upward-facing ground is submitted but produces no BackSide shadow fragments for this above-horizon sun.

The read-only probe reconstructs the same shadow frustum and checks object visibility, caster flag, layer and object-frustum acceptance. Its per-object sums must equal the actual backend draw ledger before any category analysis is accepted. Static triangle ownership is resolved from each chunk's `scene.json` LOD0 vertex ranges; per-instance costs use actual selected geometry. Distance bands are horizontal camera-eye distance to feature/instance bounds centre: 0–50, 50–150, 150–400 and ≥400 m. They are accounting bins, not new reach thresholds. Category triangles and distances partition **submitted** geometry, including casters outside the map.

A padded per-feature/per-instance light-frustum bound gives a conservative model for potentially useful geometry. An additional ground-projected bounding volume/main-frustum test identifies potential visible-ground-shadow influence, not actual depth ownership. Building receivers above ground, PCF footprints, bias, terrain height and foliage deformation mean it cannot prove which overlapping caster wins a shadow texel. Whole-feature triangle retention overestimates light-clipped costs; bounds overlap alone must never be called an observed visible shadow. Back-facing counts use geometric winding and the existing sun direction; those counts are a model, not another capture. No caster, shadow LOD, bias or reach is changed here.

## Reconciled shadow categories and distance

All four read-only object inventories and feature/instance partitions reconcile exactly to the actual backend ledger. Sloan 40/150 m: static chunks 355,074 triangles/12 shared draws at both heights, plus instances 205,391/99 and 217,088/101. Lakeview: static chunks 844,253/13 and 905,862/14, plus instances 80,232/110 and 90,322/135. Static draws contain multiple feature categories; assigning the same shared draw separately to buildings, ground and fences would double-count it. Water-material meshes cast no shadow, but water-labeled polygons in the static primitive can still be submitted.

| Area/height | Shadow T/D | 0–50 m | 50–150 m | 150–400 m | ≥400 m |
|---|---:|---:|---:|---:|---:|
| sloans-lake/40 | 560,465/111 | 8,639 | 152,638 | 354,780 | 44,408 |
| sloans-lake/150 | 572,162/113 | 8,639 | 152,618 | 366,170 | 44,735 |
| lakeview-sheil-park/40 | 924,485/123 | 9,333 | 121,418 | 555,798 | 237,936 |
| lakeview-sheil-park/150 | 996,184/149 | 12,987 | 125,818 | 568,611 | 288,768 |

Category grouping below is exhaustive. Trees include conifer; shrubs include bush/flowerBush; street props include lamp/bench; raised ground includes sidewalk/generated-sidewalk/curb; flat surfaces include other roads, paths, markings, lots, grass, beds, paving and generated ground. The JSON preserves every original kind separately. **In-map** is full geometry retained by padded individual bounds; **potential visible** is a ground-shadow influence bound, not observed shadow pixels.

| Area/height; category | Submitted T | 0–50 | 50–150 | 150–400 | ≥400 | In-map T | Potential visible T |
|---|---:|---:|---:|---:|---:|---:|---:|
| sloans-lake/40; buildings | 251,708 | 4,777 | 45,128 | 178,602 | 23,201 | 10,938 | 4,799 |
| sloans-lake/40; flat surfaces | 61,830 | 1,153 | 10,014 | 43,402 | 7,261 | 2,902 | 1,205 |
| sloans-lake/40; raised ground | 17,394 | 32 | 902 | 10,036 | 6,424 | 282 | 70 |
| sloans-lake/40; fences | 24,142 | 120 | 2,912 | 14,914 | 6,196 | 894 | 60 |
| sloans-lake/40; shrubs | 33,278 | 152 | 12,920 | 20,206 | 0 | 1,480 | 156 |
| sloans-lake/40; trees | 158,037 | 1,997 | 78,212 | 77,828 | 0 | 9,659 | 3,824 |
| sloans-lake/40; street props | 14,076 | 408 | 2,550 | 9,792 | 1,326 | 408 | 0 |
| sloans-lake/150; buildings | 251,708 | 4,777 | 45,128 | 178,602 | 23,201 | 14,325 | 10,782 |
| sloans-lake/150; flat surfaces | 61,830 | 1,153 | 10,014 | 43,402 | 7,261 | 3,446 | 2,413 |
| sloans-lake/150; raised ground | 17,394 | 32 | 902 | 10,036 | 6,424 | 1,512 | 164 |
| sloans-lake/150; fences | 24,142 | 120 | 2,912 | 14,914 | 6,196 | 1,768 | 660 |
| sloans-lake/150; shrubs | 35,499 | 152 | 12,900 | 22,396 | 51 | 3,672 | 1,868 |
| sloans-lake/150; trees | 167,513 | 1,997 | 78,212 | 87,028 | 276 | 19,844 | 14,552 |
| sloans-lake/150; street props | 14,076 | 408 | 2,550 | 9,792 | 1,326 | 612 | 408 |
| lakeview-sheil-park/40; buildings | 709,845 | 7,183 | 95,074 | 409,694 | 197,894 | 16,141 | 2,763 |
| lakeview-sheil-park/40; flat surfaces | 58,002 | 462 | 5,939 | 35,379 | 16,222 | 1,825 | 349 |
| lakeview-sheil-park/40; raised ground | 4,964 | 42 | 528 | 3,240 | 1,154 | 450 | 102 |
| lakeview-sheil-park/40; fences | 71,442 | 678 | 6,844 | 45,106 | 18,814 | 1,608 | 0 |
| lakeview-sheil-park/40; street props | 16,746 | 708 | 1,758 | 10,914 | 3,366 | 306 | 0 |
| lakeview-sheil-park/40; shrubs | 36,408 | 260 | 5,580 | 30,082 | 486 | 1,394 | 100 |
| lakeview-sheil-park/40; trees | 27,078 | 0 | 5,695 | 21,383 | 0 | 2,659 | 1,805 |
| lakeview-sheil-park/150; buildings | 760,052 | 7,183 | 95,074 | 419,168 | 238,627 | 35,827 | 14,295 |
| lakeview-sheil-park/150; flat surfaces | 62,852 | 462 | 5,939 | 36,075 | 20,376 | 2,241 | 1,206 |
| lakeview-sheil-park/150; raised ground | 5,328 | 42 | 528 | 3,336 | 1,422 | 478 | 180 |
| lakeview-sheil-park/150; fences | 77,630 | 678 | 6,844 | 46,550 | 23,558 | 506 | 200 |
| lakeview-sheil-park/150; street props | 16,746 | 708 | 1,758 | 10,914 | 3,366 | 624 | 0 |
| lakeview-sheil-park/150; shrubs | 40,001 | 2,160 | 6,840 | 30,182 | 819 | 2,124 | 200 |
| lakeview-sheil-park/150; trees | 33,575 | 1,754 | 8,835 | 22,386 | 600 | 4,538 | 976 |

Most submissions are 150–400 m from the camera eye, with Lakeview additionally submitting 238k–289k beyond 400 m because a broad chunk/group sphere intersects the light volume. Those are distance-accounted submissions, not a request to shorten reach. Objects whose padded bounds miss the existing light volume cannot supply shadow-map depth. Flat front-only polygons rasterize no BackSide depth for this sun; raised sidewalk/curb edges and fences do contribute back-facing triangles. Buildings and crowns have closed/raised surfaces and potentially intersect visible receiver regions, so their shadows must be retained. Occlusion by another caster, actual receiver height and PCF ownership remain unmeasured; the supplied potential-visible counts intentionally do not prove every retained caster is useful.

## Proposed options — models only, no implementation

| Area/height | Individual bounds, full geometry | + static back-face selection | + vegetation LOD2 | + 12-triangle building boxes |
|---|---:|---:|---:|---:|
| sloans-lake/40 | 26,563 | 16,748 | 10,165 | 5,870 |
| sloans-lake/150 | 45,179 | 31,668 | 13,612 | 7,718 |
| lakeview-sheil-park/40 | 24,383 | 12,755 | 10,266 | 3,172 |
| lakeview-sheil-park/150 | 46,338 | 23,807 | 18,373 | 2,888 |

These are cumulative, **hypothetical shadow submissions**, not captured variants or pixel-qualified/native counts.

1. **First choice: spatial caster bounds without simplification or reach changes.** Keep complete original features/instances whose padded bounds intersect the existing light frustum, with original shadow material, winding, order and transforms; draw-pool compatible casters. Model 24,383–46,338 triangles already fits 150k, saving 527k–950k submitted triangles. Conservative clipping can preserve depth pixels, but .5 m padding is an analysis value, not a proven worst-case deformation/PCF bound. Validate light-frustum-edge shadows, off-screen casters and low-sun poses before adoption. A large receiver/object must not be culled by camera visibility alone.
2. **Static caster back-face/flat-surface pruning.** At this fixed sun, keep only winding that the existing BackSide map rasterizes; full vegetation/props remain. Modeled cost 12,755–31,668. No geometric LOD; risks include winding errors, sun changes, deformation and grazing faces. An exporter should label provably flat non-casting parts separately, retaining curb/fence/wall edges. Native already does flat/raised splitting, so this is not a new native saving.
3. **Independent vegetation shadow LOD.** Use measured package LOD2 triangle costs for tree/bush/flowerBush instances accepted by the same light bounds; keep current geometry when LOD2 is not cheaper. Costs come from actual prototype `triangles[2]`, not native cap hypotheses. Conifer/lamp/bench costs remain unchanged in this model. Combined modeled cost 10,165–18,373. Risks: lost branch/leaf silhouettes, changed crown porosity and detached shadows; PCF does not prove equivalence. Choose transitions using projected **shadow-map** error/texel size, not eye-distance alone. Compare against the full-caster reference before enabling.
4. **Closed building proxies, separate flag.** Twelve triangles per accepted building bounds box, current reach, prior vegetation option; modeled cost 2,888–7,718. This is deliberately coarse and can over-shadow gaps/roof setbacks, lose gable/hip/porch detail and alter contact shadows. Footprint-extruded or roof-preserving proxies would be preferable but their costs have not been measured; box counts do not establish a quality gate. Do not adopt merely because they fit.

Recommend investigating option 1 first: its conservative geometric model fits the floor without a shadow-LOD or reach concession. Counts at other dates/poses, depth-pixel equivalence, steady CPU cost, pooling draws and native cascade/GPU cost remain unproven. No implementation, capture of a shadow variant, shadow-budget change or reach change was made.

## Native transfer boundary

RealityKit already splits flat and raised chunk buffers in `Sources/WorldEngine/World.swift:434–455`, with `DynamicLightShadowComponent(castsShadow: false)` on flat groups. Its `Environment.swift:136–154` uses automatic maximum shadow distance, low-sun reach and far crown shadow globals; these are not the web orthographic camera. No native source changes were made. Small caster bounds, independent caster LOD and closed proxies are renderer-neutral ideas; Three's layer separation, custom render sort and BackSide triangle model cannot be copied as RealityKit pass counts. 5A must measure all submitted shadow passes/cascades, instance counts and selected LODs at the same pose/date, validate visible shadows/long low-sun reach, and measure GPU time and shadow-map allocations. The web ledger/model is not phone evidence. R alone authorizes any reach change.

## Source integrity and validation

Original capture-base `web/bakeoff/main.js` SHA-256 `55b0834efc482a33a320e008c3c58d8a533dd9bdbc9b1b723fdc19a7e25e76d5`; rebased main includes A2’s unrelated default-off palette trial, SHA-256 `2e1d8a6729dc6c7c4b38980016c2741a962a8229bfeeef209d496cec50efa44b`, byte-identical to rebased `origin/main`; `web/src/world.js` SHA-256 `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`, unchanged versus branch main base. No native/shader/budget/crown/shadow-policy file changes. Final twelve-view batches admitted separately at load 14.79, 8.12, 8.82 and 11.43, all <25; each lock released. A5/A1/P0 waits were respected; no other agent lock modified. An initial focused-test command used a nonexistent test registration file and failed before tests; the corrected command runs directly from `web` and all twelve prototype tests pass. After main advanced 23 commits, rebase completed without conflicts. All 51 related prototype/capture-contract tests pass under heavy admission at load 5.04. The six affected bakeoff views and six repeats were re-run on rebased main at load 12.10/9.63: all exact 0/0, and every decoded default/repeat/variant frame is pixel-identical to its pre-rebase counterpart. Prior V1 frames remain intact. Shipping source/prototype modules are unchanged across that rebase; their completed six-view evidence remains valid. Final diff and commit-size checks pass; no default/source/budget/shader/native changes in A10’s diff.

## Ledger text for A3

A10 repaired prototype ordering: all twelve fixed bakeoff/shipping comparisons and twelve repeat controls exact 0/0. Default route/shipping sources and all shadow submissions unchanged. Ordering preservation regresses Lakeview 150 m draws to 181 bakeoff/234 shipping, and every 600 m view exceeds 100; no floor promotion. Reconciled Sloan/Lakeview shadow breakdown attributes 560,465–996,184 submissions to broad LOD0 chunks/instance groups. Existing-frustum individual-bounds model is 24,383–46,338; back-face/LOD/proxy models and visible-risk limits are documented above. Shadow models remain unimplemented/unqualified; reach unchanged and any change requires R. A3 applies this text to the shared ledger.

Used: spatial-cells-prototype.md §§Corrected capture gate, Unchanged shadow cost; spatial-cells-design.md §Renderer responsibilities. Mock: retained matched default ladder/scoreboard frames. Deviation: shadow usefulness is conservative geometric modeling, not shadow depth ownership or a native measurement.
