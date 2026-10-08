# Weekend brief — 5A + P2, 8 Oct 2026

## Scoring: one handoff to A3 after each look change

From the implementation checkout, run the capture command below; then hand A3 the printed run directory, commit and previous run stamp. A3 grades §M closeness plus sky/light/saturation/ground/foliage/materials, runs the comparison and publishes. **Capture alone is not a score**; the existing command stops for review (exit 3 means ready to grade). Do not invent a one-command automatic visual grader.

```sh
scripts/heavy.sh "weekend paired look capture" Tools/lookloop/lookloop.sh run ordinary-street-afternoon lakeview-street-afternoon lakeview-postcard-afternoon wilmette-street-afternoon
# A3: inspect frames against calibration-v2; write calGap/aspects and grader into each run/grades JSON.
# Replace RUN_DIR, OLD_STAMP and NEW_STAMP with the actual run paths/stamps:
Tools/lookloop/lookloop.sh finish RUN_DIR
python3 Tools/lookloop/compare_runs.py OLD_STAMP NEW_STAMP
# Budget check, after the shader/prerequisite fix below:
POSTCARD_FILTER=ViewDrawBudgetTests scripts/heavy.sh "view budget" scripts/postcard_mac_check.sh
```

Keep the frozen iOS contract in `docs/lookloop/a3-capture-contract.json`; new areas need explicit frozen cameras. Score Sloan's and each available hold-out separately, with before/after aspect vectors; reject-flag Sloan's gains paired with hold-out losses. Missing views remain pending. Match season/date, weather and renderer; never compare iOS to web as a delta. No ΔE decision substitute. `finish` still needs A3 to complete paired scoreboard columns. A passing four-hero result (all ≥4, every aspect ≥3) still needs the established confirmation run.

**Scope:** map only: Sloan's gate → hold-outs → Builder → jobs game. This brief schedules work, not approvals or successful ports. [A3 iOS baseline](../lookloop/a3-baseline.md): four heroes 3/5, foliage 2 throughout, Lakeview saturation 2. [Web 5c72bad](../lookloop/web-5c72bad.md): Sloan's/Lakeview 2/5, no gain; foliage season changed, limiting causal comparison. No web recipe below has proved the look gate. All web paths below are under `web/bakeoff/`, pinned to `5c72bad` unless stated otherwise.

## 0. Establish reliable tests, branches and HUD first

**Goal/files:** 5A first validates `5a-no-silent-skips` (`scripts/test.sh`, affected fixture/budget tests), then measures current iOS before visual edits. Run `scripts/heavy.sh "weekend full suite" scripts/test.sh`; no silent missing shaders/data. Today's R request: display **fps / tris / draws / mem on R's iPhone 14 Pro**. Existing `Apps/WorldLab/Sources/ContentView.swift` HUD, `Metrics.swift`, `Sources/WorldEngine/WorldDiagnostics.swift` are the starting point; label visible/main counts versus all-pass counts and memory units/coverage.

**Cite/recipe/proof:** visual-v2 §8.1 budgets; web `budget.js`, `gpu-timer.js`, `laptop-report.py` and `LAPTOP-BUDGET.md` provide an allocation/pass ledger, not iPhone timings. Prove HUD values with an actual 14 Pro run, screenshot and warm-run log; record missing metrics honestly. Existing HUD text is implementation evidence, not device validation. **Do not touch:** app gameplay, target budgets, phone installations without R's approval, another lane's heavy lock. No new HUD styling project.

## 1. One general foliage rule — P2 crowns, 5A colour

**Goal/files:** layered/softer crown shading, deterministic variation and regional greens; work in `Sources/WorldGen/Props.swift`, `Foliage.swift`, `Profiles/vegetation.json`; 5A owns `Environment.swift`, `RenderResources.swift`, `Shaders/WorldShaders.metal`, `Look.swift`/`Profiles/look.json` colour wiring.

**Cite:** foliage-seasons-v1 `species[].seasonColours`, `cities[].mix`; calibration-v2 `sharedLook` (lighting/materials/saturation), visual-v2 §R10 crown value shaping. **Recipe:** `foliage.js`, `species-policy.js`, `phenology.js`, `data/p2-crowns.json` reuse P2 `fcda086` lobes/normals and regional species selection; `stable-random.js` keeps selection repeatable. Port the general rule, not yellow October fixture values or WebGL light units.

**Proof:** `node web/bakeoff/overnight.test.mjs` checks mechanics; iOS `TreeSpeciesTests`, `TreeColourTests`, `TreeAOTests`, `TreeSilhouetteTests`, `TreeLookTests` plus paired A3 frames must demonstrate improvement. Current A3 foliage remains 2: coarse web lobes are not a successful appearance reference. **Do not touch:** per-building/tree/camera corrections, species abundance claims, exposure to rescue crowns, or pending crown-silhouettes-v2 as an approved target. Keep shared fixture fixed for before/after.

## 2. Port shared web sky + approved visibility — 5A

**Goal/files:** world-angle sky, one transfer/airlight application; `Sources/WorldGen/SkyImage.swift`, `Sources/WorldEngine/Environment.swift`, `Shaders/WorldShaders.metal`, `Sources/WorldEnvironment/Atmosphere.swift` and the consuming look fields.

**Cite:** calibration-v2 `sharedLook`; haze-visibility-v1 `definition`, `regions[].seasons`, `airlight`, `integration.applyOnce`, `mountains`. **Recipe:** `sky.js`, `sky-colour.js` (sky transfer revision `08e2cce`); `atmosphere.js`/`backdrop.js` (MOR implementation `b012b71`, retained at `5c72bad`). Preserve real DEM sightlines; mountain contrast ≥0.05 AND projected height ≥2 px; no enlarged ridge. The web adapter supports homogeneous fixtures and rejects unsupported layers; it is not a complete layered-weather implementation.

**Proof:** `node web/bakeoff/sky-colour.test.mjs` and `node web/bakeoff/atmosphere.test.mjs`; port equivalent checks to iOS `SkyFixtureTests`/`WeatherFixtureTests` and re-score. Tests prove transfer/MOR mechanics; current web sky 3/5 and overall 2/5 do not prove final quality. **Do not touch:** camera fitting, calibration exposure/saturation, water mechanics, sky-cloud-v1 approval (pending), or A6-only sky-seasons-v1 §2.1 phase ranges.

## 3. Weather-moments migration to 5% MOR — 5A

**Goal/files:** update consumers in `Sources/WorldEnvironment/Atmosphere.swift`, `EnvironmentResolver.swift`, `Sources/WorldEngine/Environment.swift` and relevant compiled look fields, not source packs. **Cite:** haze-visibility-v1 `definition.contrastThreshold`, `overrides[pack=weather-moments-v1].paths` and `.momentMigration`; weather-moments `moments[].before/after.fog.sigmaPerM` and `visibilityEquivalentM`.

**Recipe/proof:** `atmosphere.js` at `b012b71`/`5c72bad` demonstrates `sigma=-ln(.05)/visibilityMetres`; its tests assert T(MOR)=.05 and darkness does not increase extinction. All 21 moment migrations still require iOS coverage: recompute equivalents rather than relabel 2% values; add before/after moment fixtures and check local-layer preservation. **Do not touch:** event content, wetness/snow history, local fog bounds/masks, night-fog local 0.035/m without a separate decision, or double-count measured total extinction. No claim that web already migrated all 21 moments.

## 4. Shadow budget — 5A with P2 caster simplification

**Goal/files:** count and reduce actual shadow work generally in `Sources/WorldEngine/World.swift`, `RenderResources.swift`, `PostcardQuality.swift`, `WorldDiagnostics.swift` and P2 geometry/LOD consumers. **Cite:** visual-v2 §8.1 / filed floor: 400k main tris, 150k shadow tris, 100 main draws; calibration-v2 `sharedLook.lighting.shadow.neutralWitnessShadowToLitLinearY` (0.62).

**Recipe/proof:** web `budget.js`, `gpu-timer.js`, `lighting.js`, `LAPTOP-BUDGET.md` at `5c72bad` measure all passes. Sloan shadow **245,154**, Lakeview **322,586**: both FAIL 150k. There is no proven web shadow-budget fix to port. Use general distance/projected-size caster LOD; verify all-pass counters on device and paired A3 light/foliage scores. **Do not touch:** budget ceilings, shadow quality solely for Sloan's, or omit passes to report a pass. Laptop timings do not qualify the 14 Pro.

## 5. Lakeview 414k versus 400k — P2

**Goal/files:** general distance/screen-size thinning in `Sources/WorldGen/Props.swift`, `Foliage.swift`, `BuildingGenerator.swift` and consuming LOD; test `Tests/WorldEngineTests/ViewDrawBudgetTests.swift`. **Cite:** visual-v2 §8.1; calibration-v2 simplification/distance authority; foliage-seasons species forms. **Recipe:** web `foliage.js` near/mid/far envelopes and `facades.js` projected-size tiers at `5c72bad` are references, not a ready-made iOS fix. Static web chunks still use LOD0.

**Proof:** rerun the top budget command on current main to reproduce the historical 414k failure, then require `<400,000` as the test actually asserts, plus unchanged/raised hold-out appearance. Web Lakeview main 265,310 is a different renderer/export and does not clear iOS. **Do not touch:** Lakeview-specific caps, mapped buildings/area bounds, the test threshold, or camera/season to hide the failure.

## 6. Parked branch disposition — verify/rebase one at a time

Fetched 8 Oct: **all six tips below are unmerged**. Proposed order, not permission to bypass tests. Follow current main; preserve both date-ordered entries only for add-only handoff conflicts, stop on other conflicts. Tests below are required, not newly run in this docs task.

| Order / branch tip | Goal / files / packs | Status, risk and required proof; web relation; do not touch |
|---|---|---|
| 1 — `5a-no-silent-skips` `a0f5280` | Shader/prerequisite reliability; `scripts/test.sh`, fixture/budget tests; no new look values | Historical unrun fix. Run full suite first; it can reveal real failures. No web equivalent needed; never suppress failures to merge. |
| 2 — `5a-aerial-lod` `11c936b` (change `fb1fd5a`) | 3D eye-to-cell LOD; `World.swift`, `PostcardExport.swift`, `PostcardQuality.swift`, `BuildingGenerator.swift`, `Look.swift`; calibration-v2 distance simplification | Earlier suite passed except Lakeview budget; stale on main. Run `BuildingLODDistanceTests`, `BuildingLODProjectionTests`, budget suite and paired frames. Web projected-size LOD is an analogy, not the same fix. Resolve/record the known floor failure; never present it as a pass. |
| 3 — `5a-tree-hue` `fe11805` | General colour variation; shader/resources/environment + look fields; `look.json trees.hueJitterDeg`, cited foliage/calibration palettes | ±5° proposal, renderer cap 10°; overlaps foliage work. Review the actual patch (merged ancestry makes broad branch diff misleading), `LookSpecTests` + paired frames. Web deterministic species colours are usable; jitter has no A3 pass. No regional-green replacement or arbitrary new hue range. |
| 4 — `5a-exposure-general` `2e1675c` | One global bible offset; `Environment.swift`, `Look.swift`, `Profiles/look.json`; lighting-bible per-state brightness and calibration-v2 `sharedLook` | Historical 374/374 under old test script; before/after hold-outs missing. Revalidate after sky/foliage; −3.1 Y8 proposal must not fight single calibration exposure. Web `lighting.js` transfers hue, not this offset. Do not stack both corrections or merge without A3 evidence. |
| 5 — `p2/yards` `7f5e8df` | General water-body area/fetch profile; `SceneGenerator.swift`, `ShoreBand.swift`, look fields; lake-winter `water.profiles`, `look.json water.shoreProfiles` | Only remaining delta is explicitly untested WIP. After floor fix, 5A reviews water ownership; run `ShoreBandTests` + paired frames. Web `water.js` proves some mechanics, not this selection policy. Keep haze under haze-visibility; do not merge unrelated water work with foliage. |
| HOLD — `p2/night-windows` `4f25a79` | Seeded warm/cool window flags; `BuildingGenerator.swift`, look fields; night-fog area `windowWarmShare`, `look.json nightWindows` | Explicit R hold; no merge this session. `NightWindowTests` and future night frames needed; no proven A2 recipe. Do not expand daytime map scope or lift R's hold. |

## 7. MetalFX upscaling — later, after native map correctness/budgets

**Goal/files:** feasibility review at the existing `RenderResources.swift` / `PostcardQuality.swift` render-target boundary; no implementation in this brief. **Cite:** visual-v2 §8.1 and calibration-v2 detail/simplification; no pack supplies a MetalFX scale preset. **Web recipe/proof:** none—WebGL2 evidence does not demonstrate MetalFX. Require an iOS integration feasibility check, native-versus-upscaled A3 comparisons (thin branches, distant detail, motion), and 14 Pro GPU/memory/thermal results before choosing a mode. **Do not touch:** native baseline, geometry budgets or map features to hide scaling artefacts; no speculative API wiring or promise RealityKit exposes the required buffers.
