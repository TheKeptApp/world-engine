# Crown v3 — opt-in prototype, ungraded

Default is OFF. `?crownV3=standard` selects the single candidate; invalid values or simultaneous crownV2/v3 are errors. R explicitly authorized proceeding despite the existing whole-scene ladder overage, reporting deltas rather than waiting for A10's separate scene-budget diagnosis. No standard/floor pass or visual improvement is claimed. Implementation is the commit introducing this report; base `4c9eb26`. No native/production web renderer files changed. The small `scripts/capture_web.mjs` adapter adds v3 query/metadata/filename handling only; A7's watchdog, lock traps, ladder, exposure, readiness and coverage logic are unchanged.

## Reconciliation

A3's `48a687d` ladder numbers are correct; the older A2 489,507/101 standard and 383,481/96 floor are correct for the saved street camera, not this ladder. A7's ladder is 1005×565, FOV 50°, eye 39.7511195,-105.0389, west 270°, pitch down 45°, AGL 40/150/600 m. It shows a larger scene. All numbers here are measured main submissions, with shadow/post separated; this discrepancy is not the earlier main/all-pass confusion.

| Mode | 40 m main tris/draws | 150 m | 600 m |
|---|---:|---:|---:|
| Crown OFF | 729,101 / 182 | 791,795 / 251 | 624,433 / 292 |
| Prior v2 standard | 854,677 / 179 | 916,331 / 246 | 757,707 / 284 |
| Prior v2 floor | 756,593 / 178 | 811,215 / 241 | 650,901 / 280 |

Source: A7 ladder manifest, rechecked in `reconciliation.json`; OFF independently re-captured here and matches. Standard limits 500k main /180k shadow /120 main draws; floor <400k /150k /100. Every ladder mode above fails its main tier. Non-foliage alone is 529,108/117, 570,468/166, 473,923/198; changing crowns cannot independently clear this scene. Crown floor is not a whole-view floor switch.

## One candidate and exact mechanics

`main.js` imports `crown-v3.js` only when enabled. It installs one data-driven deciduous recipe after the unchanged `foliage.js` adapter. The approved deciduous identity kinds are treeRounded/Pyramidal/Vase/Open/Upright; evergreen, bushes and flower petals are excluded. All 5,649 mapped eligible identities remain. Five species assets share the recipe and instance by species/LOD; existing individual scale, yaw, stretch and phenology tint stay attached to identity. No per-city/camera overrides, exposure change, tree thinning or other feature edit.

R's authored starting allocations are exact full-leaf caps: near **160 wood +240 interior +600 patch =1,000**, middle **24+56+120=200**, far **12+24+64=100**, tiny **8 patch triangles**. Each occupied species/LOD has one instanced main draw, not one per tree. Existing far-caster policy uses 100 tris/crown before frustum accounting. Compared with crowns.md's native 1,200/360/80/12, these are -200/-160/+20/-4; neither list is a measured capacity guarantee. Partial/bare dates remove foliage according to the existing phenology prior; wood remains.

Seeded 5–9 unequal primary lobes occupy three height layers with a displaced centre, nonuniform branch angles and open spaces. Species dimensions/P2 trunk proportions own the envelope. Explicit prototype construction ratios are documented in `crown-v3.js`: golden-angle placement, center offset ±0.05 normalized tree height, reach/spread 0.24–0.36, lobe radius/spread 0.13–0.20, interior radius 0.62 of patch lobe, interior AO 0.88 once, sun-facing transmission amplitude 0.035 linear. They are authoring choices under R's v3 instruction, not numbers claimed to be measured from the pack. Palette/roughness and shared grade are unchanged. Smooth lobe normals, opaque interiors, opaque alpha-cutout patches (`alphaTest=.5`, depth writes on, blending off); no atlas/texture memory added. Tiny fallback is two crossed fitted four-triangle fans.

LOD uses projected height: ≥20 px near, ≥6 middle, ≥2 far, below 2 tiny (crowns.md/pack projected thresholds). Conservative per-tree bounding spheres cull only outside the camera frustum before filling pooled buffers. Whole tree population and existing 120 m caster eligibility remain. No nearest-budget denial is applied in this comparison, so 150 m's 555 near trees cost more than OFF. Variant storage follows the existing viewer's 256/1001 capacity rule to avoid WebGL's 16 KiB uniform-block limit. First candidate attempt failed that limit; fixed storage, no shape change. Initial uncullled pooling counts are superseded by the final captures below.

## Measured absolute costs and deltas versus OFF

Fresh installed Chrome 155.0.8059.39, sandbox enabled, WebGL2 on the local Mac. `candidate.json` records actual render pass counters. Deltas include all changed deciduous crowns, retained wood and batching/culling. Negative values are savings. They do not imply a crown-only shape improvement.

| AGL | OFF main tri/draw | V3 main tri/draw | Δ main tri/draw | OFF shadow tri/draw | V3 shadow tri/draw | Δ shadow tri/draw | V3 all-pass tri/draw |
|---|---:|---:|---:|---:|---:|---:|---:|
| 40 m | 729,101/182 | 610,961/131 | -118,140/-51 | 69,639/62 | 84,423/57 | +14,784/-5 | 695,385/189 |
| 150 m | 791,795/251 | 1,210,739/192 | +418,944/-59 | 67,961/42 | 83,273/41 | +15,312/-1 | 1,294,013/234 |
| 600 m | 624,433/292 | 847,545/229 | +223,112/-63 | 0/0 | 0/0 | 0/0 | 847,546/230 |

Post remains 1 triangle/1 draw at every height. **All three main budgets FAIL; shadow triangle budgets PASS.** 600 m's zero is the unchanged measured shadow counter, not proof of satisfactory shadows. No phone speed claim. Submitted v3 near/middle/far/tiny populations: 40 m 78/0/0/0; 150 m 555/403/2/0; 600 m 0/1423/861/12. All 5,649 identities are either in these populations or conservatively frustum-culled; shadow membership is independent. Every non-foliage pass equals OFF exactly.

## Fragment estimate — not a GPU counter

The requested crops are the full **1005×565 drawable frames** at 40 and 150 m. `estimateFragments` clips every patch triangle in homogeneous camera space, rasterizes pixel centres, applies the same perspective-correct cutout field, and sums layers. No near-plane triangles are omitted. It ignores MSAA/helper fragments, scene occlusion, patch depth rejection and opaque interiors; counts are a **patch-only projected upper estimate before depth occlusion**, not measured GPU invocations or total scene fragments. Polygon-edge/sample conventions may differ from GPU rasterization.

| AGL | Before alpha cutout | After alpha cutout | Covered pixels | Average surviving card layers | Pixels >6 layers | Maximum |
|---|---:|---:|---:|---:|---:|---:|
| 40 m | 306,749 | 227,061 | 96,812 | 2.345 | 2,044 (2.11%) | 13 |
| 150 m | 313,521 | 239,216 | 108,149 | 2.212 | 1,727 (1.60%) | 17 |
| 600 m | 44,329 | 39,547 | 22,644 | 1.746 | 60 (0.26%) | 9 |

40/150 average passes the 2–3 target. **FLAG: local overlaps exceed six** at both heights; these include overlaps between trees. Depth writes reduce actual shaded work but do not erase this reported risk. The candidate uses 3 patch planes/lobe near/middle, 2 far, and 2 crossed tiny planes.

## Captures, identity and tests

Run from repo root: `HEAVY_AGENT='A2 crown v3' HEAVY_LOAD_WAIT=0 bash scripts/capture-web.sh --block sloans-ladder --crownV3 standard --output /private/tmp/UNIQUE`. Wrapper owns admission; do not nest it. Same pose/date (2026-10-15)/fixed EV 0.35, linear gain 1.2745606273192622, contrast 1.06 and saturation 1.08 as A7. No scores.

Local originals: `/private/tmp/a2-crown-v3-before`, `/private/tmp/a2-crown-v3-off`, `/private/tmp/a2-crown-v3-final`. Copies and manifests are beside this report (`before.json`, `off.json`, `candidate.json`); PNGs remain gitignored. `summary.json` pins source hashes and pass deltas. Three unmodified controls and three post-change default-off frames are **PNG-byte-identical**, including 40/150/600 m; source `foliage.js` itself is unchanged. Candidate assets do not load with the flag absent/off. Existing 1,056 default geometry/material cases, v2 seed/allocation/instancing controls, 228 v3 geometry witnesses, v3 pooled/culling/alpha/fragment controls, three-view capture identity/coverage tests, 12 A7 web tests, and policy/overnight/atmosphere/sky-colour arithmetic all pass. The identity test removes only enumerated flag plumbing before comparing unrelated main source.

Final heavy admissions: baseline 4.56, OFF 7.23, candidate 4.52, regression 4.23; load <25, disk >8 GiB, own lock released after each actual run. Failed attempts are retained at `/private/tmp/a2-crown-v3-candidate` (uniform limit) and `/private/tmp/a2-crown-v3-candidate-2` (pre-cull diagnostics); no rejected pixels presented as final. No screenshots generated by an image model. No A3 score or untouched-holdout acceptance is claimed.

## Ledger text for A3

A2 crown v3: opt-in/default OFF, one seeded deciduous lobe/opaque-interior/cutout recipe, species/LOD instancing and conservative per-tree frustum culling; full mapping and non-foliage unchanged. Nine before/off/candidate ladder frames retained, three default-off byte comparisons pass. Final 40/150/600 costs and deltas in summary.json; main fails standard at all heights, shadows pass; local >6 layer hotspots flagged. R authorized prototype despite existing scene overage; no score/promotion, no A10 budget fix mixed in. Consumers main.js → crown-v3.js and v3-only alpha shadow material; native untouched. A3 to grade against crown/calibration references. Tracking files not edited.

Used: R crown-v3 recipe and delta-budget approval; crowns.md §Budget; crown-silhouettes-v2 construction/panels; foliage-seasons-v1/P2 data. Mock: crown panels 01/14/17–22, images 03/04; calibration-v2/06-sloans. Deviation: prototype numeric authoring recorded; whole-scene main overage and >6-layer hotspots; no scores or hold-out acceptance.
