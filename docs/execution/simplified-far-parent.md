# Simplified far parent — A4 web trial, 9 October 2026

## Decision, contract and limits

R authorizes an additive, default-off Stage 2 web representation at nearest complete-parent distance >=400 m. Native must wait for A3's paired acceptance and a coordinator instruction. No Swift edits. This supersedes the old Stage 2 stop for this isolated trial only; it does not promote the earlier spatial runtime or the unconsumed offline ordered-run branch.

The opt-in post-stage `web/bakeoff/tools/export-far-parent.mjs package --far-parent` creates `far-parent.json` and `far-parent.bin`. With no option it refuses to emit; no legacy package file is rewritten. SHA-256 binds world.json, every consumed scene/LOD0/LOD1 input and the far binary. The companion's original world/GLB bindings remain valid because those bytes do not change.

The existing exported LOD1 provides building masses, original palette-slot attributes, roof/wall separation and deterministic generator geometry. Only annotated `kind=building` features use it; every ground, road, shore and other static feature retains LOD0 vertices/indices/attributes. Water remains its original separate mesh. Attributes/layouts must match or the stage stops. Compatible static parts are rebased to the package ENU origin and merged into one parent, with unique deterministic feature IDs and complete feature bounds for fine visibility. This is simplified building geometry plus exact ground batching, not a new dataset or a material/look/shader change.

Admission uses the **whole core's union of actual original and simplified bounds**, padded by the existing 0.5 m diagnostic margin. Its nearest 3D distance must be >=400 m, and every camera-space corner must remain beyond the near plane. The conservative whole-core gate avoids changing distant subsets while the eye is near the core: no altitude, area or frozen-camera special case. Children remain exclusive with the parent. Original geometry remains alive; original shadow proxies keep their exact geometry, visibility and reach. Parent main geometry receives existing shadows and adds no casters.

The exported object-space error is the maximum corresponding-building union-box diagonal, a conservative symmetric surface-distance upper bound for nonempty corresponding surfaces. This intentionally loose bound is **not** a silhouette, roof readability, screen-pixel or visual acceptance promise. Camera-space bounds and the spec's projected-error equation are planning evidence only. A3 must judge the paired frames. Streamed parent residency, transitions/fade, phone performance and web/iOS parity are outside this static opt-in qualification.

## Native plan — do not implement yet

After A3 passes this representation **and** the coordinator tells A4 to proceed:

- `Sources/WorldEngine/FarParent.swift` (new): opt-in sidecar reader, world/input/payload SHA validation, supported-layout validation, immutable parent construction and complete camera-space bound calculation. Fail closed to exact children on mismatch/missing companion. Preserve the original surface-role companion and materials.
- `Sources/WorldEngine/World.swift`: default-off configuration and nearest-complete-bound >=400 m admission, atomic main parent/child swap, unchanged original shadow caster coverage. Keep exact children at near range; no area-specific gate or horizontal-only distance substitution.
- `Tests/WorldEngineTests/FarParentTests.swift` (new): default-off identity, missing/corrupt/binding mismatch, 400 m boundary, camera/near-plane rejection, exact near restoration and exclusive coverage. Fresh native matched 40/150/600 m pairs and real budget counters remain required; web evidence cannot certify native or phone timing.

## Validation and A3 handoff

Measurements and paired-frame paths will be appended after the owned heavy-lock run. The capture-only consumer is `qualify-far-parent.mjs` served scoreboard page -> `spatial-far.js` -> existing `installSpatialCells(...mergeSourceRuns:true)`. Both baseline and after use the same source-run grouping, lights, water, clocks, cameras, pixels, original shadows and instance LOD. The after flag is `farParent=1`; default shipping entries and `web/src/world.js` are unchanged. 40/150 m after frames must be decoded-RGBA exactly 0/0 against the baseline, and independent baseline repeats must be 0/0. 600 m changes are intentional and handed to A3 without scores.

## Used / Mock / Deviation

Used: spatial-cells-design.md §§Recommendation, geometric LOD, Exporter contract, Renderer responsibilities; world-edge-options.md (core versus context); spatial-cells-prototype.md §Stage 2; spatial-order-and-shadow-diagnosis.md (ordering and independent casters); offline-ordered-runs.md on unmerged 7ece3d9 (source-run format, deliberately not merged/consumed); budget-tiers.md §Contracts; docs/tracking/INDEX.md and MOCKS.md (source/mocks routing).

Mock: approved style-b-calibration-v2 `frames/06-sloans.png` and `frames/01-lakeview.png` opened as look references; frozen shipping scoreboard 40/150/600 m controls are the actual comparison. No look values were changed; Wilmette is an untuned held-out area, not a new mock.

Deviation: complete-core parent is more conservative than independently switching 400/800 m spatial groups; unchanged LOD0 ground retained rather than simplifying road/shore surfaces; no streaming, native parity, A3 acceptance, scores or phone qualification claimed. Earlier f8ae242/7ece3d9 remain on their branch until A10 consumes them.
