# Opt-in web scene-budget variant — 2026-10-08

## Result

`?sceneBudget=1` enables feature/instance frustum selection and draw pooling in **web bakeoff only**, with every crown and foliage experiment OFF. Default is OFF. The actual 150 m main pass is **205,349 triangles / 75 draws**, meeting **<400k / ≤100**. No distance LOD, v3 integration, allocator, thinning, shader, palette, geometry recipe, placement or native changes were needed.

| Height | OFF main triangles / draws | Flag ON main triangles / draws | Main floor |
|---|---:|---:|---|
| 40 m | 729,101 / 182 | 49,844 / 45 | Pass |
| 150 m | 791,795 / 251 | 205,349 / 75 | Pass |
| 600 m | 624,433 / 292 | 320,036 / 112 | **Draw failure: 112 > 100** |

These are measured WebGL submissions from the existing ledger, including the main sky. Shadow totals are unchanged: 69,639 / 62, 67,961 / 42 and 0 / 0; post remains 1 / 1. No native/device timing or wider camera/hold-out acceptance is claimed. The requested 150 m acceptance does not turn the 600 m result into a pass.

## Exact image equivalence

Baseline is **c8c361d**, [current near-corrected OFF controls](../lookloop/captures/a7-web-crown-all-near-fix/README.md), captured on merged source 1580115. All three new default-path controls, final variant fresh captures and independent variant repeats are **encoded-PNG and decoded-RGBA byte-identical** to those controls.

| Height | Maximum byte difference | Mean absolute byte difference | Differing bytes / pixels | Every differing region |
|---|---:|---:|---:|---|
| 40 m | 0 | 0 | 0 / 0 | **None** |
| 150 m | 0 | 0 | 0 / 0 | **None** |
| 600 m | 0 | 0 | 0 / 0 | **None** |

All 2,271,300 RGBA bytes per frame were compared, with no excluded region, threshold, blurred comparison or masked credit overlay. Normalized max/mean are also zero. Pose, fixture, exposure, requested/resolved camera, projection and each shadow/post bucket match. The viewer query remains `tier=standard` to replay the saved contract; acceptance is explicitly evaluated against **floor main limits**, without changing the contract or budgets. Near planes remain 10/37.5/150 m. Fixed exposure is the existing calibration gain 1.2745606273192622, contrast 1.06 and saturation 1.08. Calendar date is October 15, with existing web afternoon-light fixture, not a newly calculated solar light.

Final fresh paths (repeats replace `fresh` with `repeat`):

- `/private/tmp/a10-scene-budget-on-verified/sloans-40-foliage-off-crown-off-scene-budget-fresh.png`
- `/private/tmp/a10-scene-budget-on-verified/sloans-150-foliage-off-crown-off-scene-budget-fresh.png`
- `/private/tmp/a10-scene-budget-on-verified/sloans-600-foliage-off-crown-off-scene-budget-fresh.png`

Default controls are in `/private/tmp/a10-scene-budget-off-control/`. These temporary capture files remain local; images are not added to git. Their hashes are retained in the [evidence manifest](../../web/bakeoff/evidence/scene-budget/manifest.json), and the already tracked c8c361d PNGs contain the identical image bytes. Original controls and initial diagnostic captures are preserved.

## General implementation rules

`web/bakeoff/{sloans,lakeview}.html` routes through `entry.js`. With the flag absent or `0`, it imports **only the unchanged shipping `main.js`**; the experiment modules and hooks are not loaded. With `1`, `scene-budget-entry.js` rejects baseline, crownV2, crownV3 and foliage experiment combinations. It retains GLB feature IDs in a WeakMap as the original loader deletes their GPU attributes. The temporary loader/deletion hooks are restored after load. A one-time animation-loop hook installs the separate variant after materials, facades, species, LOD selection, DEM and shadow proxies are ready; the hook then restores itself.

`scene-budget.js` groups static triangles by package feature ID and DEM triangles by general 2 km x/z patches. Bounds include every triangle vertex, including cross-patch triangles. Instance bounds use the complete selected prototype and exact transform. Reject only padded bounds fully outside the current main frustum; **0.5 m** is the conservative diagnostic margin from the diagnosis. The selected OFF materials do not displace vertices; no shader-motion bounds are substituted for future experiments. Camera/projection, selected counts, transforms and replacement facade geometry trigger reselection. Tests cover camera movement and resize-created/removed sources.

The original main objects stay on unused layer 2 so their identities and existing LOD updates survive. Main replacements receive shadows but never cast; layer-1 shadow proxies remain untouched. No off-camera shadow caster is removed. Pool only compatible material, vertex layout, exact prototype geometry, render order and accounting category. Preserve all per-instance attributes, including individual tint and origin, plus matrices. Static pools keep exact original model matrices and original vertex values, avoiding a world-space float rebake. Transparent objects retain their source ordering/identity. Static pools use 800 m bins; **compatible visible instances pool across cells**. Fine visibility happens first, so cross-cell pooling cannot bring rejected instances back into the main pass.

This is a CPU selection/packing prototype, not a pre-baked tile change. Rebuild/upload, GPU allocation and full-frame runtime costs require sustained measurement before default adoption. It does not change shipping exposure or add a camera/block exception.

## What the CPU diagnosis got wrong

The [diagnosis](scene-budget-diagnosis.md) predicted triangles exactly at all three heights, despite using the older near-plane controls. The final padded selection remains 49,844 / 205,349 / 320,036 triangles with the corrected projection.

Its 800 m pooling estimates **41 / 89 / 129 draws** were optimistic. The first actual conservative implementation yielded **45 / 102 / 186**: the model's static pooling key omitted exact model matrices, vertex-layout compatibility, accounting categories and transparent source ordering. Those distinctions cannot be discarded just to reproduce a predicted count. Initial captures were still exactly pixel-identical, but **150 m failed the draw gate**.

Pooling compatible **visible instances** across cells reduced actual main draws to **45 / 75 / 112** while preserving identical pixels and triangles. Thus only the two requested rule families are used; adding distance LOD would introduce an unnecessary image-equivalence risk. The diagnosis's global pooling lower bound is not asserted as an achieved count.

## Source identity and validation

Shipping `web/bakeoff/main.js`, `web/src/world.js`, `web/bakeoff/foliage.js`, `web/bakeoff/shadow-casters.js` and all shared/native renderer files remain byte-identical versus the starting main and c8c361d. Main SHA-256: `55b0834efc482a33a320e008c3c58d8a533dd9bdbc9b1b723fdc19a7e25e76d5`; world loader: `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`. The manifest records experiment/default source hashes. HTML entry routing and capture CLI metadata are the intentional integration changes.

Capture commands, each owning and releasing its own admission:

```sh
HEAVY_AGENT=A10 scripts/capture-web.sh --block sloans-ladder --output /private/tmp/a10-scene-budget-off-control
HEAVY_AGENT=A10 scripts/capture-web.sh --block sloans-ladder --sceneBudget --repeat --output /private/tmp/a10-scene-budget-on-verified
```

The worker adds `sceneBudget=1`, records resolved variant metadata, checks activation and uses its existing readiness, fixed-exposure freeze, GPU finish, capture and repeat guards. It does not relax coverage or repeat checks. Final capture admission load was **5.56 <25**; every job released its lock. The evidence verifier is `web/bakeoff/scene-budget-capture.test.mjs VARIANT_DIR DEFAULT_DIR`: exact PNG/RGBA, hashes, camera/fixture/exposure, shadow/post equality, repeats and 150 m floor assertions. It reads finished captures and does not render or score.

Focused tests cover eligibility, complete feature bounds, main/shadow separation, camera updates, compatible instance matrices/tints, incompatible geometry/material refusal, default routing and resize replacement. All **30 Node suite/test entries pass**, including existing policy, atmosphere, sky, foliage/v2/v3 and capture/camera regressions with their documented local asset prerequisites (1,056 legacy geometry and 228 v3 witnesses). Final regression admission load was **5.67 <25**. Initial environment failures (`WORLDENGINE_ASSETS` missing, then missing Lakeview `instances.json`) are retained as setup failures; no production or test assertion was weakened. Lakeview's existing export recipe prepares that regression fixture without changing render code or capturing a hold-out.

## Ledger text for A3

A10 web scene-budget variant, default OFF: consumers HTML → `entry.js` → opt-in `scene-budget-entry.js` / `scene-budget.js`; captured with `scripts/capture-web.sh --sceneBudget`. OFF crowns only. 150 m floor main passes at 205,349 triangles / 75 draws; 40 m 49,844/45; 600 m 320,036/112 still fails the draw floor. All three flag-on frames and repeats exactly match c8c361d OFF controls; default controls and shipping source unchanged. No differing regions, LOD, allocator, native result or scoring. General culling and compatible visible-instance pooling implemented; sustained costs and hold-outs remain pending. No INTEGRATION, STATE or handoff edit by A10.

Used: scene-budget-diagnosis.md §Fine visibility, then compatible pooling; budget-tiers.md contracts; R's opt-in request. Mock: c8c361d corrected OFF frames at 40/150/600 m. Deviation: web-only technical acceptance at the requested 150 m; 600 m draw floor and device/hold-out qualification remain unresolved.
