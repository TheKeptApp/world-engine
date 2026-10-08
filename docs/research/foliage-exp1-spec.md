# Foliage experiment 1 — ready-to-run specification for 5A

8 October 2026; execution planned for 9 October. **Spec only: no render edits or captures performed.** Inspected main `293abbcc0391bd1e6a7c89e9668989ac04f47f75`. Recheck the named functions against tomorrow's main before executing. This isolates the first recommendation in [foliage-rendering-v1](foliage-rendering-v1.md): layered opaque crown shading. All new coefficients below are **fixed experimental guesses**, not approved pack values. Expected scores are predictions, never results. `crown-silhouettes-v2` remains concept pending approval.

## Decision and scope

Test whether removing native leaf self-emission and redistributing existing broad crown occlusion gives clearer layers without adding leaf detail. **Replacement emissive coefficient is exactly 0.00, not another glow term.** This is an occlusion/material experiment, not physically based translucency. Directional light-through is deferred because a correct shadow-visibility input has not been established across both renderers. Do not invent an unshadowed backlight.

Limit the experiment to **living opaque deciduous crown surfaces at near/middle/far LOD**, with no geometry, palette, seasonal timing, tree placement, wind, exposure, key/fill, haze or shadow-policy changes. Keep bark, conifers, bushes, tufts and skyline twig masses as controls. This narrow eligibility avoids guessing native leaf identity from the material alone. Bush/conifer rollout and regional colour correction are separate experiments; no claim that this one solves every foliage weakness.

## Exact future implementation files

| Renderer | File / insertion point | Required edit |
|---|---|---|
| iOS / 5A | `Sources/WorldEngine/Shaders/WorldShaders.metal`, `worldFoliageSurface` | Preserve the original material initialization as baseline. After leaf-drop and bare-skyline handling, immediately before `finish`, apply the candidate below only to eligible crown fragments. Do not modify shared `finish`, `worldFoliageGeometry` or water/sky functions. |
| Web / A2-compatible implementation | `web/bakeoff/foliage.js`, `build`, `colour`, and `applySpecies` | Add scalar `exp1AO` and `exp1Mask` geometry attributes, with defaults 1 and 0 on every piece before merging. Populate eligible deciduous leaf vertices as specified below; route through existing shared `MeshStandardNodeMaterial.colorNode` and `aoNode`. Keep native-independent web baseline unchanged when experiment is off. |
| Web experiment selection | `web/bakeoff/main.js`, `applySpecies` call | Pass an explicit `foliageExp1` mode from query parameter, allowed values `off`, `remove`, `layered`; absent defaults to `off`, invalid value errors. Existing `baseline` viewer comparison must stay untouched; it is not the experiment's control. |
| Web capture selection | `web/bakeoff/capture-once.mjs`, candidate URL and evidence output | Read `FOLIAGE_EXP1=off|remove|layered` (validate; default off), append `&foliageExp1=` to candidate URLs, record it in JSON and route experiment output to `evidence/foliage-exp1/<mode>/<tier>/`. Leave legacy baseline capture unchanged. |
| Web arithmetic checks | new `web/bakeoff/foliage-exp1.test.mjs` | Test the numeric witnesses below, mask exclusion and unchanged bark values. This is a future test file, not created by this spec. |

Native mode selection: one local integer constant in the named surface function, **0=off, 1=remove, 2=layered**, default 0. Use separate capture builds/commits for modes; record shader source hash and selected constant for each. No native runtime configuration plumbing or compiled look JSON changes for this first experiment. Rebuild shaders using the established prerequisite-safe workflow; changing a constant without a rebuilt shader is not a valid candidate.

No changes to `Props.swift`, `RenderResources.swift`, `Environment.swift`, `lighting.js`, `phenology.js`, source packs or export data. Existing crown AO is read from P2; no pending-concept values are imported. Any additional renderer file required by tomorrow's implementation must be named in the handoff before expanding scope.

## Approved native eligibility amendment — 8 October 2026 (R, A10)

R approved retaining the original eligibility predicate and additionally requiring existing deciduous palette slots **3, 4, 5, 6, 24, 25, 26, 27, 28**. Flower-bush petals (`Sources/WorldGen/Props.swift:394,539`) carry `extra=(1,0.9,0,0)` and unflagged flower paint, so the original predicate alone also selected those non-crown controls. Fixed slot identities come from `SeasonalPalette.order` (`Sources/WorldGen/StyleProfile.swift`) and `crownPaint` (`Props.swift`), not appearance or RGB colour.

Exact final native mask, evaluated after leaf-drop and bare-skyline handling, using the existing resolved `slot=paletteSlot(paint,origin)`:

```cpp
extra.y > 0.0 && extra.z < 0.5 && !su.leafCut &&
(uint(paint.z + 0.5) & 512u) == 0u &&
((slot >= 3u && slot <= 6u) || (slot >= 24u && slot <= 28u))
```

The explicit slot list is `{3,4,5,6,24,25,26,27,28}`. A2 must match **deciduous crown identity**, plus the same live/opaque/non-skyline/non-card conditions, on web; colour similarity does not establish identity. Preserve bushes/flowers, conifers, bark, tufts and skyline/card controls. This amendment changes eligibility only; the candidate math and 0.00 emissive rule remain exact.

R also authorizes launch-argument selection for this native execution (`off/remove/layered`, default off), replacing the older build-only mode selection above, and Sloan’s `-inspectionpose` captures at 40/150/600 m replacing the old street-view order for this requested set. Off-vs-baseline pixel difference must be 0. Bush, conifer and other non-mask category pixel checks must report maximum differences against baseline in all three modes. A3 scores; A10 does not. Hold-outs and other visual gates remain pending until separately captured/scored.

## Exact candidate math, linear-light material inputs

Definitions: `B` is the existing decoded, seasonally mixed and instance-varied base colour, before weather/atmosphere. `A` is broad crown AO, not shadow-map visibility. `smoothstep(a,b,x)` means `t*t*(3-2*t)` where `t=clamp((x-a)/(b-a),0,1)`.

Native eligibility, evaluated after existing leaf handling: `extra.y > 0 && extra.z < 0.5 && !su.leafCut && (flags & 512u) == 0`. This selects leaf-threshold-bearing opaque crowns and excludes skyline markers/cards. It deliberately does not use `paint.w` alone, which also labels other foliage. If generator semantics differ at execution time, stop and reconcile the mask; do not widen it by appearance.

| Mode | Eligible native crown | Eligible web crown |
|---|---|---|
| off | Original `B`, original `su.ao=extra.x`, original `su.emissive=B*0.05*extra.x` | Original `colorNode`; no new AO node or emission; new attributes have no rendering effect |
| remove | Original `B`, original AO; set `su.emissive=0` | Identical to off: there is no existing tree emissive term to remove. This is an identity control, not a fabricated web improvement. |
| layered | Set `su.base=B*M`, `su.ao=A1`, `su.emissive=0` | Existing leaf colour multiplied by `M`; `aoNode=A1`; emissive remains zero |

For layered mode only:

```text
A0 = clamp(A, 0.65, 1.00)
t  = smoothstep(0.65, 1.00, A0)
A1 = 0.65 + 0.35*t
M  = 0.94 + 0.06*t
```

This preserves the existing ambient floor of **0.65** while adding at most **6%** broad material darkening in deep crown regions. It steepens the AO transition around its midpoint without multiplying a second AO into albedo. `M` is the only added base-colour multiplier. It is an authored occlusion approximation, not a new sun-colour or saturation grade. Native `finish` retains its existing fill, contact, AO, weather and single atmosphere application. Its existing final AO/IBL behaviour is unchanged except for the input remap. Roughness/specular remain native **0.95/0.1** and web's existing calibrated material values. No extra emissive, wrap, light, texture or noise term.

Numeric witnesses (approximately, tolerance 0.0001):

| A input | t | A1 | M |
|---:|---:|---:|---:|
| 0.50 or 0.65 | 0 | 0.65 | 0.94 |
| 0.75 | 0.198251 | 0.719388 | 0.951895 |
| 0.825 | 0.5 | 0.825 | 0.97 |
| 0.90 | 0.801749 | 0.930612 | 0.988105 |
| 1.00 | 1 | 1 | 1 |

**Web AO adapter:** existing A2 species geometry has no P2 `extra.x`. In `build`, on deciduous crown vertices only, evaluate the existing P2 `bakeCrownAO` recipe before the final width scale, after the current normal blend: `rel=(position.y-s.crown[1])/s.radii[1]`; `A=min(0.66+0.34*smoothstep(-1,0.7,rel), 1-0.25*smoothstep(0.2,0.8,-normal.y))`; for each active crown lobe containing the vertex within `0.98*radius`, multiply A by **0.86**. Use the selected LOD's actual lobe centres/radii; far shell uses no lobe-overlap factors, matching P2 far-shell bake intent. Store A in `exp1AO`, mask 1. Set mask 0 for wood, conifers and `lod>=3`. Attributes must survive `toNonIndexed`, merge and `mergeVertices`; do not change positions, normals or index count. These adapter constants come from [P2 bakeCrownAO](../../Sources/WorldGen/Props.swift), not a new artistic proposal. Web tessellation/lobes differ, so this is not a claim of pixel-equivalent native AO.

Web shader blends `originalColor` to `originalColor*M` with `exp1Mask`, and sets AO to `mix(1,A1,exp1Mask)`. Existing leaf tint/mask and identity-based seasons remain intact. This is TSL/node-material wiring: A2 uses `three/webgpu` with a forced WebGL backend. Do not paste classic `onBeforeCompile` hooks into it, or paste its light/ACES units into RealityKit. [Apple surface material parameters](https://developer.apple.com/documentation/realitykit/custommaterial/surfaceshader), [three NodeMaterial AO](https://threejs.org/docs/pages/NodeMaterial.html). If this backend does not visibly consume AO on its hemisphere lighting, retain M, report that limitation and **do not** compensate by changing global lights or multiplying AO into colour a second time; that result does not prove native parity.

## Before / after frames and execution order

1. Freeze execution-main SHA, shader/JS hashes, source assets and [native camera contract](../lookloop/a3-capture-contract.json). Run off and capture anew; historical scores below are context, not tomorrow's baseline. Use the same renderer/build options and approved calibration-v2 targets. Never use the web's separate legacy `baseline` URL as the off frame.
2. Native captures: `ordinary-street-afternoon` (Sloan's), `lakeview-street-afternoon`, `lakeview-postcard-afternoon`, `wilmette-street-afternoon`, in that order. Copy every camera/date/weather argument from the contract; no new framing. Run off → remove → layered. Rebuild each shader variant. Save full frames and identical phone-width comparisons for each.
3. Web captures: existing `sloans` and `lakeview` scenes/cameras, off → remove → layered. Pin `fixture.json` date **2026-10-08**, clear summer atmosphere, day, wind **10 km/h from 225°**, same tier and drawable size. Capture harness must preserve and record the experiment URL parameter; verify mode from captured metadata/source hash, not merely the URL typed. Archive each run before the next because existing evidence paths can be overwritten. Current saved web review is [4127a32 series](../lookloop/web-4127a32.md).
4. Use the existing [restart capture commands](../tracking/weekend-brief.md) and [web verify workflow](../../web/bakeoff/README.md), under `scripts/heavy.sh`; do not bypass failed shader prerequisites, browser blocks or another lane's lock. Use the specified capture-once.mjs adapter, with `MODES=candidate TIERS=standard FOLIAGE_EXP1=off`, then remove and layered. Run existing web arithmetic tests and `foliage-exp1.test.mjs` first; use `scripts/heavy.sh "foliage exp1 web capture" node web/bakeoff/capture.mjs` for each mode with the loopback server running. Capture both scenes each time. Do not run the old score.py against its unrelated legacy output paths; A3 reads the explicitly named experiment paths. Current unmodified capture scripts do not yet select these modes.
5. After the main pair is inspected, use the same existing scene/view for paired night, overcast and bare-season controls, with identical inputs between off/layered. Save the selected control inputs. Require no new leaf glow at night, no altered bark/skyline twig mass, no snow becoming grey from a post-weather tint. Ready West Highland/Greenville hold-outs are required when available; otherwise pending, not a pass. No new site tuning.

Artifact naming convention for the executor: `<run>/<renderer>/<view>/<off|remove|layered>.png`, metadata beside each including SHA, mode, target hash, camera and full environmental inputs. This spec creates none of those files and claims no before/after image exists yet.

## Predicted appearance and A3 decision

**Prediction:** layered mode has less uniform leaf glow, readable lighter tops and darker lobe interiors, with no added leaf texture. Deep shade may become too heavy: if it produces black seams, flat dark crowns or loses autumn colour, reject the candidate rather than tuning per city. Removal-only may do little or make crowns too dark. On the web, added broad AO should provide more internal modelling, but it cannot fix coarse silhouette geometry.

| Frame group | Last recorded score, not a fresh control | Hypothesized layered result |
|---|---|---|
| Four native afternoon heroes | Overall closeness 3/5; foliage 2/5 in [A3 baseline](../lookloop/a3-baseline.md) | Foliage **3/5** is the experiment target; overall closeness likely **still 3/5**. All other aspects unchanged is the expectation. |
| Web Sloan's / Lakeview | Overall 2/5, foliage 2/5 in saved 4127a32 review | Foliage **3/5** is the target, with **2/5 still plausible** because geometry remains coarse; overall expected **2/5**. |

A3 scores blind-labelled off/remove/layered phone-size pairs against calibration-v2 using §M and unchanged-frame/noise controls in [GRADING](../lookloop/GRADING.md). Record each actual aspect vector and visual reasons. No ΔE-derived pass or fabricated integer uplift. Keep the candidate only if actual foliage improves on the focus view, no ready hold-out/aspect regresses, and the budget/correctness checks pass. Sloan's gain plus hold-out loss is reject-flagged. A foliage 3 does not pass the overall four-hero closeness≥4/full-confirmation gate. Missing captures mean pending.

## Cost and stop conditions

Expected native increment: **0 triangles, 0 draws, 0 textures**; a few material arithmetic operations. Web: **0 triangles/draws/textures**, two float32 attributes = **8 bytes per resident vertex** (100k vertices = 0.763 MiB before copies/alignment); log actual buffer duplication. No shadow geometry/atlas/LOD changes; same shadows receive a different material response only. Frame time remains unmeasured.

Verify arithmetic witnesses, off-mode identity, non-leaf exclusion, equal topology/counts and mode provenance before visual scoring. Run existing relevant shader and web tests, then record main/shadow triangles, draws, memory and available GPU timing. Floor remains <400k main /150k shadow /100 main draws; provisional standard/hero unchanged ([tier study](../perf/device-tiers-v1.md)). Existing overages stay explicit. Stop for input drift, missing shader compilation, wrong eligibility, unexpected geometry changes or cross-renderer assumptions; do not add a card renderer, change pack values or broaden this experiment to make the predicted score happen.
