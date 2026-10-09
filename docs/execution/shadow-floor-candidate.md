# Shadow-floor candidate — 2026-10-09

## Authority and inputs

R approved merge of 5d6cf40, lossless finite wind bounds, an independent approximate-shadow fallback if required, the candidate bundle and consumption of A4 far geometry only after its report. Web and iOS must be qualified together; no native acceptance is inferred from web results.

Read: spatial-order-and-shadow-diagnosis.md §§General repair, Reconciled shadow categories and distance, Native transfer boundary; shadow-and-draw-floor.md §§Implementation, Qualification, Source-run concatenation; budget-tiers.md §Contracts and scope; docs/tracking/INDEX.md feature rows (requested docs/INDEX.md is absent); docs/tracking/MOCKS.md M-CAL-SLOANS/M-CAL-LAKEVIEW; docs/lookloop/GRADING.md §§M, N, C, E, PP. A3 owns scoring, including R-authorized paired scoring; no A10 scores.

Mocks opened: ~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/frames/06-sloans.png and frames/01-lakeview.png. These govern appearance, not aerial geography. Fixed shipping and bakeoff controls govern the lossless gate.

## Merge and wind envelope

The approved branch rebased without conflict and merged as 6e76ca7. 21 focused tests passed before merge. Existing scoreboard was launched after merge, admitting each heavy build/export/capture separately.

For the known foliage position node, InstanceNode precedes wind displacement. Let B be its highp interval transformed through the instance matrix. With maximum positive _paint.w S and Y=max(abs(B.min.y),abs(B.max.y)), each horizontal displacement has magnitude at most float32(.0025)*S*Y. Expand X/Z by that amplitude times (1+16*2^-23), plus 1e-5 model metres; leave Y unchanged. Then propagate existing gamma8 highp model-view/projection intervals; the first affine stage reserves its eighth operation for the wind coordinate addition (three products, three partial additions plus translation otherwise use seven). The trig mathematical range is [-1,1]; the 16-ulp/1e-5 numerical slack is explicitly stated and R-authorized, not a universal proof of every GPU trigonometric implementation. Unknown deformation/nonfinite values/insufficient highp still retain the complete source. Actual exact image+depth captures remain the acceptance test. No fixed half-metre assumption, reach change, simplification or shader edit.

## Initial exact results (remaining matrix in progress)

Shipping Sloan 40 m: original 560,465/111 shadow T/D → conservative unbounded version 206,614/101 → finite wind 26,164/40. Shipping Sloan 150 m: 572,162/113 → 223,517/105 → 43,729/38. These save an additional 180,450/179,788 shadow triangles versus the approved unbounded version; both are below 150k. Shipping Sloan 600 m: 75,831/4 → 12,578/1 → 0/0, with a depth-clear control and exact unchanged pixels, not a shortened reach. All three fresh/repeat and OFF/ON image/depth comparisons are exactly 0/0, differing bytes 0. No shadow-only freeze or LOD fallback is needed for these fixed views. Final acceptance still requires all twelve fixed and twelve stress comparisons.

A temporary batch wrapper used the status spelling `complete` instead of the capture tool's `completed`, and stopped before running any remaining batch. The accepted Sloan capture itself completed and passed; the wrapper spelling was corrected, then remaining batches resumed. No failed render is hidden or counted.

## Pending producer boundary

A4 reported its **plan**, not a completed far sidecar: existing package LOD1, additive hash-bound companion, complete-parent nearest-bound >=400 m, original near geometry and shadow casters retained. Consumption is not started. A5's water/ring prototype is also in progress. The final consumer must also keep the entire 40/150 m view on original transforms/order; a distance-only predicate cannot silently enable far rebaking in those views. Target-pose altitude and complete-parent distance are independent safeguards.

## Native change boundary — proposed, not edited

To consume the same general visibility/caster rule natively, shared files would be required: Sources/WorldEngine/World.swift (feature/instance caster entities and selected geometry); Sources/WorldEngine/RenderResources.swift (stable shadow-only resources); a new Sources/WorldEngine/ShadowCells.swift and Tests/WorldEngineTests/ShadowCellsTests.swift (native wind envelope and selection tests). The native deformation is different: WorldShaders.metal:497–528 `worldFoliageGeometry` uses weather windStrength, foliageSway, pow(clamp(modelY,0,1),1.5), distance fade and world wind direction, rotated/scaled back into model space. Its seasonal leaf-drop path can collapse a lobe to model point (0,.5,0), which must also be enclosed. Reuse that exact native formula and bound its sine; do not copy the web .0025 amplitude. RealityKit automatic projection/cascades are not exposed as this web orthographic frustum. Prove conservative native light bounds without reducing approved reach, or retain original casters; separately count every submitted shadow pass. No shared Swift/native files have been edited. R's file gate applies before implementing this plan.

## Ledger text for A3

Approved lossless shadow/source-run branch merged 6e76ca7. Web is default off; native transfer remains unimplemented/unqualified. The old stop-at-draw-budget requirement is superseded by R's latest approximate-shadow/far-geometry decisions; historical failed budget measurements remain preserved.

## Final finite-wind qualification

All 24 comparisons (12 fixed + 12 stress) and 24 fresh/repeat controls pass exact decoded image and sampled 2048² shadow depth: max 0, mean 0, differing bytes 0. Matched source hashes are enforced by summarize-finite-wind.mjs; shadow counters reconcile to actual backend submissions. Light-edge and off-screen witnesses are present and low-sun maps contain non-clear depth. [Machine evidence](../../web/bakeoff/evidence/spatial-cells/finite-wind.json).

| Contract / view | Original shadow T/D | Finite-wind shadow T/D | Image/depth max, mean |
|---|---:|---:|---|
| scoreboard/sloans-lake/40 | 560,465/111 | 26,164/40 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/150 | 572,162/113 | 43,729/38 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/600 | 75,831/4 | 0/0 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/40 | 924,485/123 | 23,935/41 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/150 | 996,184/149 | 45,313/39 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/600 | 2,280/1 | 0/0 | 0, 0 / 0, 0 |
| bakeoff/sloans-40 | 69,639/62 | 61,209/60 | 0, 0 / 0, 0 |
| bakeoff/sloans-150 | 67,961/42 | 21,291/32 | 0, 0 / 0, 0 |
| bakeoff/sloans-600 | 0/0 | 0/0 | 0, 0 / 0, 0 |
| bakeoff/lakeview-40 | 76,124/79 | 67,505/76 | 0, 0 / 0, 0 |
| bakeoff/lakeview-150 | 73,212/62 | 26,436/51 | 0, 0 / 0, 0 |
| bakeoff/lakeview-600 | 0/0 | 0/0 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/light-edge | 526,080/118 | 43,637/42 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/offscreen-caster | 581,616/117 | 29,444/41 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/low-sun | 579,573/126 | 86,468/97 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/light-edge | 1,003,011/147 | 47,521/40 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/offscreen-caster | 933,875/146 | 50,363/38 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/low-sun | 995,299/145 | 87,157/101 | 0, 0 / 0, 0 |
| bakeoff/sloans-light-edge | 68,282/41 | 22,466/29 | 0, 0 / 0, 0 |
| bakeoff/sloans-offscreen-caster | 68,081/42 | 21,411/32 | 0, 0 / 0, 0 |
| bakeoff/sloans-low-sun | 69,639/62 | 63,106/62 | 0, 0 / 0, 0 |
| bakeoff/lakeview-light-edge | 74,353/67 | 27,552/45 | 0, 0 / 0, 0 |
| bakeoff/lakeview-offscreen-caster | 73,308/62 | 26,532/51 | 0, 0 / 0, 0 |
| bakeoff/lakeview-low-sun | 76,124/79 | 69,672/76 | 0, 0 / 0, 0 |

24 focused tests pass (10 shadow bounds/fail-closed/resource tests +14 spatial tests). Accepted admissions: 5.95, 6.89, 9.26, 5.95, 7.54, 6.64, 7.54, 6.50; all <25; locks released after each run. Batch coordinator was suspended at a release boundary to give A4/A5 a turn, without interrupting their or our captures or editing any lock.

## Post-merge default scoreboard

All 24 default shipping frames completed after merge 6e76ca7, wall time 1259.9 s including admission waits. 0/24 floor and 0/24 provisional standard budget passes; unchanged default route remains over budget. This is the required existing scoreboard, not the candidate bundle and not a visual score. Full per-frame T/D, floor/standard and structural checks: [post-merge scoreboard](../../web/bakeoff/evidence/spatial-cells/approved-postmerge-scoreboard.json). The new finite wind module was OFF in that run.

## Default source integrity

The following shipping sources match current main byte-for-byte:

- `web/bakeoff/main.js` SHA-256 `7ca8bb66947cfcce503f6a1de3f741e08419333cf1160d1e07ba92bff0fbc188`.
- `web/src/world.js` SHA-256 `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`.
- `web/src/materials.js` SHA-256 `9256b5c5114bb5cfe6af915251ffcd6f3a6648c68d013dbbc86900bbe0a41883`.
- `Sources/WorldEngine/Shaders/WorldShaders.metal` SHA-256 `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`.

## Ledger text for A3 — finite-wind result

Default-off web shadowCells now includes the bounded known wind envelope. Exact gate passes 24/24 comparisons +24/24 controls. Sloan 40/150 shadow costs 26,164/40 and 43,729/38, saving 180,450 and 179,788 triangles versus the approved unbounded selector. No approximate fallback is required for those fixed views; no reach change. Default shipping/native shaders unchanged. Raw OFF/ON paths for scoring/review are in finite-wind.json; A10 assigns no score. The full candidate bundle, producer far/water integration and native counterpart remain pending; do not record floor adoption from this shadow-only evidence.
