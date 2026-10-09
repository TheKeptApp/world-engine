# Water — execution brief, after the frozen crown comparison

**One general rule:** use the approved lake profile with one coherent normal/light/reflection response and a mapped shoreline transition for every eligible water body; never tune a lake by block ID or move its boundary to match a painting. One candidate rule per batch, one renderer comparison at a time. No code or captures delivered by this brief. Inspected main `cecd8c9`; supersedes the earlier combined water brief, not the approved packs. Keep foliage and general budget work frozen during each water comparison.

## Research, approvals and exact targets

Implements [web/iOS parity](../tracking/web-ios-parity.md) item 2 and [A8 integration audit](../review/integration-audit-2026-10-08.md), water gap: broken reflection/light response and missing separate wet-bank transition. Uses [crowns.md](crowns.md) for before/repeat/after discipline and [foliage-exp1-spec](../research/foliage-exp1-spec.md) for control provenance. Those documents establish method, not an accepted water score.

- [lake-winter-v1 STATUS](../proposals/lake-winter-v1/STATUS.md): approved; `lake-winter-values.json` owns colour, reflection, roughness and shoreline. Exact visual targets are the pack's `01-water-that-reads.png`, `02-big-lake-vs-city-lake.png`, and `06-phone-readability-targets.png` as located by its `image-manifest.json`/index under `~/Desktop/world-engine/docs/proposals/lake-winter-v1/`; hash the actual files before capture. The targets show broad broken sky response, muted blue-green depth, restrained highlights and soft shore transitions, not a mirror, cyan swimming pool or textured ocean.
- [water-surfaces-v1 STATUS](../proposals/water-surfaces-v1/STATUS.md): **mechanics only** (four-wave model, shoreline types, live-input/ice gating and performance proposals). Its colour, reflection caps, roughness floor, exposure and copied lighting are **excluded**. Do not use `reflectionLimits.nearBlendCap/farBlendCap` as lake authority even though current web code reads them.
- [MOCKS](../tracking/MOCKS.md): overall style judged against `~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/frames/06-sloans.png`; Lakeview/Wilmette regional calibration `frames/01-lakeview.png`. Images govern look, mapped geometry governs location/scale; no copying concept shore topology.
- Existing approved haze-visibility policy stays unchanged. The old lake `0.0008/m` fixture is superseded; do not add another haze mix to compensate water. `sky-cloud-v1` and `street-ground-v1` remain excluded pending concepts; crown approval does not authorize changing foliage in this task.

Authoritative numeric witnesses from lake pack: Sloan clear deep **#477C8D**, shallow **#668C82**, blend **2 m**; Michigan deep **#315F7F**, shallow **#557F83**, blend **4 m**. Wind 0/10/25 km/h roughness **0.18/0.28/0.40**, normal amplitude **0/0.08/0.16**. Reflection `k=0.12+(0.55-0.12)*(1-clamp(abs(N·V),0,1))^5`, aerial multiplier **0.65**; exponent 5. Water-side darkening width **0.60 m**, linear base multiplier **0.88**; `0.88+0.12*smoothstep(0,0.60,d)` gives 0.88/0.94/1 at d=0/0.30/0.60 m. Land-side wet transition width **0.40 m**, separate from water-side shallow depth proxy. Hex is decoded once; web appearance-to-radiance compensation is renderer-specific and must not be pasted into native.

Keys: `water.profiles`, `water.windStates`, `water.reflection`, `water.shoreline`, `water.lod`, `states[id=sloans_lake_clear_wind_10].surfaceValues[0]`. Mechanics `waveModelProposal.fourWaveWeights=[0.62,0.45,0.32,0.23]`; retain current mechanics unless a later isolated batch explicitly changes them. Normal detail fade **35–100 m**, aerial normal scale **0.5**, minimum projected wave width **1.5 CSS px**. On native map CSS-pixel analogue to logical UIKit points, then actual drawable/view-bounds ratio; record scale. Do not silently reinterpret as 1.5 drawable pixels. These witnesses are constraints for the relevant batch, not permission to change every value simultaneously.

## Current drawing paths and ownership

All findings below are source-derived, not new pixel verification. Existing exported packages can lag generator code.

| Platform / exact file and function | Today | Owner / permitted future boundary |
|---|---|---|
| Shared `Sources/WorldGen/SceneGenerator.swift`, `generate` area loop | `.water/.pool` triangulated caps enter chunk `waterMesh`, y=0.03; native water attributes include shore/profile values. Water adds a separate inward band at +0.004 m and a 1.6 m sand-coloured bank ribbon. This ribbon is not a verified 0.40 m wet-land blend. | **P2**, geometry/data only, explicit 5A handoff for batch W3. No line-waterway work. |
| `Sources/WorldGen/ShoreBand.swift`, `profile(for:)`, `mesh` | Profile selected through style-profile mapping; open water sentinel1000; extra.z metres to shore, extra.w profile. Mitred ring strip, including holes. Current profile selection is not observed per-water-body bathymetry. | **P2**, shore attributes/topology; preserve map boundary. Missing body profile provenance is reported, not a per-block fix. |
| Native `Sources/WorldEngine/RenderResources.swift`, initializer / globals upload; `Environment.swift`, `apply` | `CustomMaterial("worldWaterSurface")`; lake globals in texels44–50 and weather/wind state. | **5A** only; uniform wiring if needed, no palette/global-light rewrite. |
| Native `Sources/WorldEngine/Shaders/WorldShaders.metal`, `worldWaterSurface`, `finish` | Lake shallow/darkening, four-wave normal for reflected direction, analytic sky and emissive sun glint. `finish` reads geometry normal; ripple normal is not visibly passed into that lighting path. Calm retains procedural perturbation; separate generic-water/rain-ring path exists. | **5A**, isolated W1 normal/light coherence. Shared `finish` change must be water-gated; preserve all non-water pixels. |
| Web `web/src/world.js`, `WorldScene` material/load path | Exported GLB `worldWater` is assigned a water material; baked geometry is the input, not new OSM interpretation. | **A2** material owner; **A4** export/load handoff only if a demonstrated attribute delivery gap blocks W3. No streaming rewrite. |
| Web `web/bakeoff/main.js`, `main`, `if(config.waterProfile&&!baseline)` | `MeshPhysicalNodeMaterial`: analytic perturbed `normalNode`, lake deep/shallow radiance, wind roughness, custom reflected-sky luminance blend via `outputNode`. Reads excluded mechanics-pack reflection caps. Branch is conditional on scene water profile; don't claim every water body uses it. | **A2**, W2 reflection cap authority; 5A reviews colour/light intent. Native is not A2's edit lane. |
| Web `web/bakeoff/water.js`, `shorelineField(meshes)` | Cancels paired exported edges, builds one1024² R16F distance field, capped32 m, no mipmaps. Distance is a shore/depth proxy, not bathymetry. Export `_extra.z` is not assumed to mean native shore metres. | **A2**, W3 mask adapter only. Diagnose seams/holes/overlap before changing topology. |

P2 changes neither shader; 5A changes no export/data topology without P2 handoff; A2 does not port TSL/Three light units to Metal. A3 owns blinded scoring and reports, A1 owns data provenance/extraction questions, A4 owns delivered web data. This brief assigns no source acquisition or new stream generation.

## Ranked gaps and isolated candidates

Rank is expected visual impact, not measured score gain. At the start of each batch verify the gap still exists on its frozen base; skip with evidence if already resolved. Do not combine W1/W2/W3 into one before/after claim.

| Rank / batch | One candidate rule | Expected change / exact scope | Stop or defer |
|---|---|---|---|
| 1 / W1 native | Use the existing computed lake ripple normal consistently for the lake's direct-light response and reflection, with correct coordinate transformation. | `worldWaterSurface` plus water-only handoff into `finish`; retain existing waves, reflection weights, colour and sun-glint constants. Hypothesis: coherent broad highlights rather than a lit flat plane beneath unrelated reflection. Web already sets perturbed normalNode: **web control only**, not a duplicate rewrite. | Stop if coordinate-space ownership cannot be proven, non-water lighting changes, glint doubles, shimmer appears or A3 gain is absent. No new reflection pass/SSR. |
| 2 / W2 web | Remove the mechanics-pack reflection cap from lake reflection weighting; lake pack alone owns the blend. | In `main` replace only the excluded `.min(mix(water.reflectionLimits...))` cap; retain current lake-based reflection formula and pigment-preserving reflected-light path. Do not simultaneously change aerial scaling, palette transfer or sky texture. Native has no equivalent cap: **native control only**. | Stop for bleaching/mirror appearance or no blind improvement. Record aerial-scale discrepancy separately for a later single-rule candidate; do not expand this batch. |
| 3 / W3 native then web separately | Apply the approved 0.40 m land-side transition to the existing eligible wet-bank endpoint using mapped shore distance. | P2 supplies mask/eligibility; 5A/A2 consume it in their existing land material. Water profile/colour/reflection unchanged. Start only after wet-bank endpoint and water/land intersection are traced. | Missing wet-bank material/provenance is blocked, not permission to paint a dark stripe. Do not blanket-convert sand, seawalls, park paths or whole shore ribbons. No extra water darkening or boundary shift. |
| 4 / deferred diagnostics | Calm residual noise, profile-by-style limitation, aerial scaling and CSS/drawable filtering differences | Record approved-value mismatches and phone-distance symptoms for a later separately authorized candidate. | No wave-spectrum/foam/ice/haze overhaul in W1–W3. |

W1 is an implementation hypothesis, not proof that normal mismatch explains the grade; W2 is a traced authority mismatch, not proof its removal looks better. If a correctness repair fails the visual gate, retain evidence and escalate the rule conflict; do not hide it with a colour adjustment.

**Waterway diagnostics only:** [A8 long-tail audit](../review/long-tail-feature-coverage-2026-10-08.md) row5 finds stream/ditch/drain/canal/river lines parsed but not consumed by the core generator; optional context covers a subset. For every hold-out, report fetched line counts, classified counts and missing visible consumers, distinguishing absent data from missing code. These are **not work items** in any water batch. Do not add ribbons, infer widths, fetch replacements or route them through the lake shader to improve coverage. A missing Greenville stream is not a water-material failure or proof of no water.

## Cost, floor and standard

[Budget decision brief](budget-tiers.md) separates recorded counters from models. Floor **<400k main /≤150k all-shadow tris /≤100 main draws**; standard prototype **≤500k/180k/120**. Keep floor gaps visible even if R evaluates the prototype against standard. All costs below are hypotheses until the builder measures actual submissions.

| Batch | Incremental main tris / draws | Incremental shadow tris / draws | Memory and timing |
|---|---|---|---|
| W1 | 0 /0 expected | 0 /0 expected | No new textures/targets; shader arithmetic cost unmeasured. Preserve caster policy. |
| W2 | 0 /0 expected | 0 /0 expected | No new allocation; GPU effect unmeasured. |
| W3 existing-geometry attribute/mask route | 0 /0 only if existing meshes/material batches suffice | 0 /0 expected for a land-material mask | Existing web field is2 MiB base, no mipmaps. Any new mask resolution/format must be separately costed; not free. |
| W3 if new shore strip proves unavoidable | **Blocked pending P2 cost handoff**; n simple edge quads would add2n triangles before clipping and potentially occupied chunk/material draws | Unmeasured until actual caster flags/passes accounted | No fixed “cheap strip” claim; reject double surfaces/z-fighting. |

Saved web Sloan main **347,177/99**, observed shadow **5,008**; Lakeview **265,310/81**, shadow **67,190**, all on M1 Max desktop at saved cameras. These are not the proposed altitude frames or phone performance. Native Lakeview historical ~414k main estimate already exceeds floor; current matched-camera native shadow counts remain unmeasured. Freeze fresh counts at40/150/600 for each renderer. Count instanced main submissions, all shadow passes/cascades, occupied main draws and other draws separately. Unmeasured is not zero/pass. Stop on standard overage, new unexplained draw/material split, or an unaccounted shadow increase; preserve baseline floor debt explicitly. No thinning, reduced reach or hidden resolution changes to fund water.

## Matched frames and capture protocol

For **each renderer and candidate**, nine focus frames: BEFORE, independent BEFORE-REPEAT, AFTER × **40/150/600 m AGL**. No off/remove/layered shading matrix. Use fresh current-base controls, retain all hashes and archive unique paths. At each altitude pin identical horizontal position, heading, pitch, FOV, drawable size, loaded tile IDs, water-body/profile identity, water/land mesh hashes, sun/date/weather, wind and animation time. Freeze or reproducibly replay wave/cloud time; arbitrary screenshot delay cannot establish a material comparison. Control-repeat noise must pass GRADING §N before A3 attributes a change.

Native focus pose from [crown capture contract](crowns.md): **39.7511195,-105.0389,ALT,270,45**, ALT40/150/600; **2026-10-15T20:30:00Z**, clear/cloud0, wind0, character none, HUDoff, RealityKit, **1005×565**, original inspection FOV. First verify water is visible and resolves in each frame; if not, A3 freezes an additional water witness **before** candidate work and captures all three states there. Do not shift only AFTER to find a better reflection. Wind0 is the primary control; a separately frozen wind10 km/h witness and golden-hour control may test the effect after the main matrix, never pooled with it.

```sh
HEAVY_LOAD=25 scripts/capture-native.sh --view ordinary-street-afternoon \
  --inspectionpose '39.7511195,-105.0389,ALT,270,45' \
  --foliageexp1 off --output .build/lookloop/UNIQUE-RUN
```

Replace ALT/RUN; capture script translates to app `-inspectionpose` and owns the heavy lock—**do not nest heavy.sh**. Record actual shader mode/hash: same default-off foliage on every side. Verify fully loaded coverage, especially600 m (prior mismatch was a loading race). Requested pose alone is insufficient; archive observed pose/state. No phone install authorized.

Web: `web/bakeoff/scenes.json` currently has frozen street cameras, **not a proven 40/150/600 inspection adapter**. A2 must hand off equivalent geodetic pose→local-world transforms, AGL elevation datum, FOV/aspect and fixed animation clock to A3 before running this matrix. Do not invent query switches. Use `capture.mjs`/`capture-once.mjs` with the **candidate renderer on both sides**, never the unrelated `baseline` renderer. Existing entry command is `HEAVY_LOAD=25 scripts/heavy.sh "water web matched capture" node web/bakeoff/capture.mjs`; existing scene/tier selections and outputs must be inspected/pinned by A2. This command alone does not create altitude support. Missing adapter/settled-state proof means **web matrix pending**, not passed. Preserve original street fixtures as supplementary controls; no cross-renderer numerical score delta when fixtures differ.

Archive `<batch>/<renderer>/<block>/<alt>/<before|before-repeat|after>` plus metadata: build/source/input/mock hashes, camera matrix and geo pose, actual drawable/logical size and scale, timestamp, wind/cloud/sun, animation time, feature coverage, material/profile values, main/shadow/other counters, memory and timing provenance. Heavy jobs require actual 1-minute load<25, ≥8 GB free and only their own lock. No missing-data workaround or render capture is performed by this docs task.

## Hold-outs and A3 acceptance

| Hold-out | Purpose and method | Missing-water/data handling |
|---|---|---|
| Lakeview street + postcard | Untouched Chicago materials/lighting regression; frozen contracts. Pair BEFORE/AFTER at40/150/600 where inspection adapter exists, plus existing calibrated street. | Not a Lake Michigan water witness merely because it is in Chicago. If no visible water, non-water regression only; water test N/A. |
| Wilmette | Untouched north-shore regional profile/non-water check at matched altitudes and frozen street. | Do not invent a lake in the loaded area; water-profile validation remains pending without visible mapped water. |
| West Highland | Denver data-poor hold-out, same rules and altitudes, fixed preselected contract. | Export/pose/data readiness must be verified; absence is pending, not success. |
| Greenville | Different region/shore materials; matched altitudes after native/web data and camera readiness. | Missing line streams are diagnostic-only; use mapped visible polygons if present, never create new water for the test. |

A3 randomizes pair labels and locks grades before revealing state/build; includes BEFORE-REPEAT control. Score closeness and all existing aspects under [GRADING §M/§N](../lookloop/GRADING.md), with phone-size images and identical water crops for inspection. There is no invented official “water aspect”: log a separate qualitative water checklist (broken reflection, correct depth/chroma, coherent light, soft eligible bank, no shimmer/seams) without adding it to the rubric.

**Acceptance for each candidate:** at water-visible40 and150 m, at least one predeclared relevant existing aspect (materials or light) improves by **≥1 point**, with none declining; it need not be the same aspect at both heights. If baseline is already5, keep5 and require A3's explicit checklist improvement; do not claim numerical gain. At600 m and all untouched hold-outs, no overall or aspect decline. W3 additionally needs a resolvable near-shore witness proving0.40 m in world units; a subpixel bank at600 m is not a failed width test. If the focus frames do not contain resolvable water, accept no water-quality conclusion without the predeclared supplementary witness. Noise, absent frames, unresolved counters or missing hold-outs mean pending. Standard costs pass, floor gaps reported; the full look gate remains separate.

Stop for non-water pixel changes outside repeat noise in W1/W2, cyan bleaching, white mirror/glow, lost shore boundary, duplicate haze, chunk seams, island-hole errors, z-fighting, repeat instability, shifted cameras/coverage or any hold-out loss. Reject focus-only improvement; no per-block rescue. Verify d=0/0.3/0.6 darkening witnesses only in a batch that touches that term; do not write redundant tests for frozen math. Native unit/normal-space tests, web cap-authority tests and W3 shore-mask boundary/hole tests belong to their respective builders, alongside actual captures.

## Builder evidence and report template

Per-frame table: `batch | renderer | block/altitude | blind ID/state | water visible/profile | input+coverage hashes | A3 closeness/all aspects | water checklist | main/shadow tris | main/shadow/other draws | memory/timing provenance | floor gap | standard pass | stop reason`. Then untouched hold-outs, missing diagnostics and keep/reject/pending. Only implementation commits update consumption ledgers; this spec claims no new consumption or score.

`feature=water | batch=W1/W2/W3 | owner/files=… | baseSHA=… candidateSHA=… | one rule=… | pack keys/mock hashes=… | nine-frame manifests=… | before-repeat noise=… | A3 blind 40/150/600=… | shore witness=… | hold-outs=pass/reject/pending(reason) | main/shadow/other costs=… | standard=… floor gaps=… | heavy-lock/load=… | line-water diagnostics only=… | decision=…`

Required last evidence line before `Tracker update:`:

`Used: water.md batch …; lake-winter keys …; mechanics-only keys … . Mock: exact file/frame/hash … . Deviation: …; matched frames/A3/cost/hold-out evidence … .`
