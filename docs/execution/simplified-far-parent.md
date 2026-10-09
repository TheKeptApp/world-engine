# Simplified far parent — A4 web trial, 9 October 2026

## Decision, contract and limits

R authorizes an additive, default-off Stage 2 web representation at nearest complete-parent distance >=400 m. R withdrew A4 native approval; 5A owns the native plan, pending A3 paired acceptance and 5A/R coordination. No Swift edits. The 9 October decisions/REFERENCE-MAP aerial-target gaps were read; the >=400 m trial is owner-authorized, not a v2/v2b facade migration. This supersedes the old Stage 2 stop for this isolated trial only; it does not promote the earlier spatial runtime or the unconsumed offline ordered-run branch.

The opt-in post-stage `web/bakeoff/tools/export-far-parent.mjs package --far-parent` creates `far-parent.json` and `far-parent.bin`. With no option it refuses to emit; no legacy package file is rewritten. SHA-256 binds world.json, every consumed scene/LOD0/LOD1 input and the far binary. Binary attributes are aligned to four bytes; this Mac exports little-endian typed arrays. The companion's original world/GLB bindings remain valid because those bytes do not change.

The existing exported LOD1 provides building masses, original palette-slot attributes, roof/wall separation and deterministic generator geometry. Only annotated `kind=building` features use it; every ground, road, shore and other static feature retains LOD0 vertices/indices/attributes. Water remains its original separate mesh. Attributes/layouts must match or the stage stops. Compatible static parts are rebased to the package ENU origin and merged into one parent, with unique deterministic feature IDs and complete feature bounds for fine visibility. This is simplified building geometry plus retained ground topology and attribute batching, not a new dataset or a material/look/shader change.

Admission uses the **whole core's union of actual original and simplified bounds**, padded by the existing 0.5 m diagnostic margin. Its nearest 3D distance must be >=400 m. The exporter also records each changed building’s complete original/simplified union bound. Reject the entire swap if any changed bound intersects both the visible frustum and the near plane; bounds fully before the clip plane or wholly outside the frustum have no visible simplification. Unchanged ground can cross the clip plane. This uses the complete visible changed bounds, not a tile-centre or camera-altitude substitute. The conservative whole-core gate avoids changing distant subsets while the eye is near the core: no altitude, area or frozen-camera special case. Children remain exclusive with the parent. Original geometry remains alive; original shadow proxies keep their exact geometry, visibility and reach. Parent main geometry receives existing shadows and adds no casters.

The exported object-space error is the maximum corresponding-building union-box diagonal, a conservative symmetric surface-distance upper bound for nonempty corresponding surfaces. This intentionally loose bound is **not** a silhouette, roof readability, screen-pixel or visual acceptance promise. Camera-space bounds and the spec's projected-error equation are planning evidence only. A3 must judge the paired frames. Streamed parent residency, transitions/fade, phone performance and web/iOS parity are outside this static opt-in qualification.

## Native plan — do not implement yet

After A3 passes this representation **and** the coordinator tells A4 to proceed:

- `Sources/WorldEngine/FarParent.swift` (new): opt-in sidecar reader, world/input/payload SHA validation, supported-layout validation, immutable parent construction and complete parent and per-changed-feature camera-space bound calculation. Fail closed to exact children on mismatch/missing companion. Preserve the original surface-role companion and materials.
- `Sources/WorldEngine/World.swift`: default-off configuration and nearest-complete-bound >=400 m admission, atomic main parent/child swap, unchanged original shadow caster coverage. Keep exact children at near range; no area-specific gate or horizontal-only distance substitution.
- `Tests/WorldEngineTests/FarParentTests.swift` (new): default-off identity, missing/corrupt/binding mismatch, 400 m boundary, camera/near-plane rejection, exact near restoration and exclusive coverage. Fresh native matched 40/150/600 m pairs and real budget counters remain required; web evidence cannot certify native or phone timing.

## Validation and A3 handoff

The measurements below are from the owned heavy-lock run. Preparation first runs the unchanged `export-spatial-cells.mjs` metadata post-stage on the local package copies; its world hash must match before Chrome starts. The capture-only consumer is `qualify-far-parent.mjs` served scoreboard page -> `spatial-far.js` -> existing `installSpatialCells(...mergeSourceRuns:true)`. Both baseline and after use the same source-run grouping, lights, water, clocks, cameras, pixels, original shadows and instance LOD. The after flag is `farParent=1`; default shipping entries and `web/src/world.js` are unchanged. 40/150 m after frames must be decoded-RGBA exactly 0/0 against the baseline, and independent baseline repeats must be 0/0. 600 m changes are intentional and handed to A3 without scores.

## Used / Mock / Deviation

Used: spatial-cells-design.md §§Recommendation, geometric LOD, Exporter contract, Renderer responsibilities; world-edge-options.md (core versus context); spatial-cells-prototype.md §Stage 2; spatial-order-and-shadow-diagnosis.md (ordering and independent casters); offline-ordered-runs.md on unmerged 7ece3d9 (source-run format, deliberately not merged/consumed); budget-tiers.md §Contracts; docs/tracking/INDEX.md and MOCKS.md (source/mocks routing).

Mock: approved style-b-calibration-v2 `frames/06-sloans.png` and `frames/01-lakeview.png` opened as look references; frozen shipping scoreboard 40/150/600 m controls are the actual comparison. No look values were changed; Wilmette is an untuned held-out area, not a new mock.

Deviation: complete-core parent is more conservative than independently switching 400/800 m spatial groups; unchanged LOD0 ground retained rather than simplifying road/shore surfaces; no streaming, native parity, A3 acceptance, scores or phone qualification claimed. Earlier f8ae242/7ece3d9 remain on their branch until A10 consumes them.

### Additional feature references actually read

`docs/tracking/DECISIONS.md`, `docs/INDEX.md`, `docs/tracking/REFERENCE-MAP.md` Facades/Context/Palette and camera-coverage gaps; `docs/execution/facades.md` rule/immutable albedo/near-middle-far; `docs/execution/archetypes.md` semantic precedence and unknown fallback; `docs/buildings/README.md` BuildingLOD table; `mobile-rendering-v1/README.md` Proposed world representation and selection; `facade-detail-v2` and `facade-detail-v2b` README/STATUS/values.json lod/albedo/coverage; v2b coverage.md; `house-archetypes-v1/README.md` authority versus proposed dimensions; `docs/review/paired-preference-protocol.md` freeze/blinding boundaries. None is permission to change palette, classify unknown buildings or promote facade recipes.

Opened the following approved far panels as street-level form/colour references, **not** 600 m calibrated compositions:

- `docs/proposals/facade-detail-v2/panels/03-denver-apartment-block-far.png`
- `docs/proposals/facade-detail-v2/panels/06-denver-courtyard-apartments-far.png`
- `docs/proposals/facade-detail-v2/panels/09-denver-mixed-use-strip-far.png`
- `docs/proposals/facade-detail-v2/panels/12-chicago-apartment-block-far.png`
- `docs/proposals/facade-detail-v2/panels/15-chicago-courtyard-apartments-far.png`
- `docs/proposals/facade-detail-v2/panels/18-chicago-mixed-use-strip-far.png`
- `docs/proposals/facade-detail-v2b/panels/03-denver-ranch-far.png`
- `docs/proposals/facade-detail-v2b/panels/06-denver-minimaltraditional-far.png`
- `docs/proposals/facade-detail-v2b/panels/09-denver-splitlevel-far.png`
- `docs/proposals/facade-detail-v2b/panels/12-denver-modern-far.png`
- `docs/proposals/facade-detail-v2b/panels/15-chicago-victorianrow-far.png`
- `docs/proposals/facade-detail-v2b/panels/18-chicago-framecottage-far.png`
- `docs/proposals/facade-detail-v2b/panels/21-chicago-brickbungalow-far.png`
- `docs/proposals/facade-detail-v2b/panels/24-chicago-cornermixeduse-far.png`
- `docs/proposals/facade-detail-v2b/panels/27-chicago-vintagehighrise-far.png`

The REFERENCE-MAP explicitly records the missing approved 600 m whole-scene and top-down roof/facade targets. A3 paired judgement is pending; references retain their original camera scope. No pending pack is substituted. Original ground topology/attributes are retained through ENU Float32 rebasing; far-ground pixel exactness is not claimed. The binary duplicates resident ground and is too costly to qualify the production memory policy without later shared-resource work.

## Measured web trial — 9 October 2026

Main limits: <400,000 triangles and <=100 draws. Baseline and far both use source-run grouping; these are not the eager shipping-default counts. Counters include sky, original water and instances.

| Area, frozen 600 m | Before main T/D | Far main T/D | Original shadow T/D (both) | Sidecar JSON + binary bytes | Post-stage seconds |
|---|---:|---:|---:|---:|---:|
| sloans-lake | 313,611/106 | 195,293/72 | 75,831/4 | 49,264,633 | 1.099 |
| lakeview-sheil-park | 486,482/54 | 139,666/44 | 2,280/1 | 66,786,122 | 2.206 |
| wilmette-vattmann-park | 211,140/51 | 106,489/42 | 34,776/2 | 46,662,547 | 1.027 |

All three main 600 m submissions meet these arithmetic limits with the far parent actually selected. This is a desktop static counter result, not the whole ship bar, phone FPS, a memory pass or an A3 visual acceptance. Near-range original shadow counts remain over the floor; this trial does not change them.

21/21 focused tests pass. All six 40/150 m ON/OFF pairs and all nine independent OFF repeats are decoded-RGBA max/mean 0/0. Six full-size matched 600 m PNGs were opened; intentional geometry differences remain unscored. No image masking or colour adjustment was used. Source modules and every PNG are hash-bound in [summary.json](../../web/bakeoff/evidence/spatial-cells/far-parent/summary.json); the 360 px side-by-side [review page](../../web/bakeoff/evidence/spatial-cells/far-parent/review.html) links original PNGs and calibration references, without relabelling street mocks as aerial targets.

Actual heavy owner PID/load verified at admission: 18:32:54 UTC, 6.45. Fresh pre-area loads: Sloan 6.00, Lakeview 7.47, Wilmette 6.48, each <25. Wrapper exit 0 released only this lane’s lock; capture servers and Chrome instances closed. Raw log: `Generated/a4-far-parent/final.log`. A further rebased-source check is recorded separately after main moved.

Repeat JSON and binary hashes match in every area. All 281 Sloan, 212 Lakeview and 209 Wilmette original capture-package files remain unchanged (spatial metadata and the two additive far files excluded). Separate original companion regression fixtures retain the world binding, all 271/159 referenced GLB hashes, and their companion payload hashes. Those companion fixtures have different world hashes from the camera packages; no false same-package claim.

Cost: binary alone is 40,877,040 / 55,218,180 / 39,419,208 bytes; full sidecar is 46.98 / 63.69 / 44.50 MiB. Original resources remain resident, so the Lakeview far binary alone exceeds 48 MiB. This is deliberately an offline/static trial; production needs shared ground resources and streamed parent residency. Post-stage times above do not repeat or replace the previous 3.8/3.5 s native full exports. Original surface companions are 1,089,142 / 3,847,048 bytes; they are not rewritten or combined with the far payload.

Traceable discarded attempts: local dependency symlink blocked by server path security; missing spatial metadata 404; a source-mutation guard rejected a batch modified during capture. They remain under `Generated/a4-far-parent/`. The earlier valid whole-core near-plane trial retained Lakeview/Wilmette original geometry at 600 m; complete changed-building bounds now reject only visible near-plane crossings, while full-core distance and atomic coverage remain mandatory. No area/camera exceptions.

Touched: `web/bakeoff/tools/export-far-parent.mjs`, `web/bakeoff/spatial-far.js`, `web/bakeoff/tools/far-parent.test.mjs`, `web/bakeoff/tools/qualify-far-parent.mjs`, `web/bakeoff/evidence/spatial-cells/far-parent/{summary.json,review.html}`, this report, and `docs/tracking/{STATE.md,INTEGRATION.md,handoffs.md}`. No Swift, native renderer, water, shader, palette or approved look file changed.

Native plan is handed to 5A; R withdrew A4 native approval. A4 must not edit native files. A3 paired acceptance and 5A/R coordination remain necessary. This report assigns no scores. `f8ae242` and `7ece3d9` remain off main.

### Rebase verification

After main moved to 294a89b, the same 21 tests and 27-frame matrix completed again under verified PID23613 at 18:47:33 UTC. Loads before Sloan/Lakeview/Wilmette were 8.01 / 24.69 / 17.63 (<25). All main and shadow counts, six near exact comparisons, nine repeat controls and actual 600 m admissions agree with the first batch. The summary/review now use these `*-rebased-frames` originals. The capture wrapper exited0 and released its lock.

Full PNGs differ between the two batches in the attribution strip: 600 m far frames have 1,389 changed bytes, max65/66/66, mean0.0375415/0.0373949/0.0373949, all within x8–454/y8–24. No world pixels differ in these three checks. This is **not** a cross-batch full-image0/0 claim; no mask is used to excuse a failed within-batch control. Each fresh OFF repeat and near ON/OFF remains exact. A3 must compare the fresh matched pair, not mix batches.

## Merge blocker — stopped, main unchanged by A4

Main moved again to 18352e3 (A10 candidate bundle and A3 scoring). The code-only branch rebase succeeded; restoring the saved completed proof/tracker edits produced content conflicts in `docs/tracking/STATE.md` and `docs/tracking/handoffs.md`. AGENTS.md standing conflict rule says “All other conflicts still stop and must be reported”; only add-only handoff conflicts may be resolved by keeping both dated entries. Because STATE is conflicted, no resolution or merge/push was attempted. Final source corrections and evidence remain saved in this worktree and the retained stash `A4 completed rebased far-parent proof`. This is tested branch work, not a completed main delivery. Native files remain untouched.

The fresh captures consumed unchanged WorldScene/material/light/post/sidecar consumer sources; A10’s latest entry-only bundle routing is not loaded by the served scoreboard page. No final post-merge scoreboard was run because no merge occurred. No lock, browser or server is held while awaiting R’s conflict instruction.

## Owner-authorized resolution — 9 October 2026

R subsequently authorized the two tracker conflict resolutions, preserving both lanes’ entries and all earlier A4 evidence. The historical stop above remains recorded; this authorization permits the web-only default-off delivery. Native approval is withdrawn, with the full plan filed for 5A in docs/tracking/handoffs.md. Tests will be rerun before merge and the existing scoreboard run after merge.
