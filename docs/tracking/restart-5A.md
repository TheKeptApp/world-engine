# 5A restart — corrected three-batch plan

Map only. R’s latest order is foliage → water → existing-generator budget; the earlier third-batch web experiment port is deferred, not silently added as a fourth batch. R’s corrected order controls this restart; linked older recipes are reference evidence, not extra batches. Coordinate P2 generator changes so they cannot contaminate the material experiment.

**Evidence and boundaries (8 Oct 2026):** [A10, 44183ef](../perf/ios-new-tiles-v1.md), [A8’s seven corrections, 26ca169](../review/verifier-2026-10-08c.md), [A5 experiment spec](../research/foliage-exp1-spec.md), [A2 parity, c34b330](web-ios-parity.md). A2 parity/PORT-LIST’s older pending/5c72bad wording is historical: [web-4127a32](../lookloop/web-4127a32.md) is the completed saved-frame review, Sloan’s/Lakeview **2/5, FAIL 0/2**, sky 3, foliage 2, no closeness gain; fresh capture remains pending. Native historical closeness is 3/5 with foliage 2, not a fresh experiment control or a controlled web/native delta.

**Native input:** iOS loads raw area `manifest.json` through `World.load → WorldBuild.generate → AreaLoader`; it cannot read A1’s adaptive `world.json`/GLBs. No new tiles or native package adapter in these batches.

**Web package/streaming work belongs to A4, not a 5A batch.** [A1 contract](../data/adaptive-tiles.md): unique leaf IDs/actual bounds, non-unique parent grid indices, explicit empty-LOD handling, ≤8 MiB decoded per leaf, ≤2 MiB per primitive, ≤16 MiB two-leaf queue; keep all parent coarse payloads until required children are ready, switch atomically without gaps/double draw. Sloan 48→76 leaves / worst decoded pair 3,756,466 B; Lakeview 25→114 / 4,176,512 B. Geometry/attributes are preserved; repartitioning does not lower total triangles. Export validation proves neither A2 integration nor native/viewer performance.

**Budget authority:** [device tiers](../perf/device-tiers-v1.md), with R’s later provisional approval in [owner log](../decisions/owner-log.md), supersedes the study’s earlier “not previously approved” chronology. Hero/standard are provisional guesses, not measured capacity or browser allocations; floor unchanged.

| Tier | Main triangles | All-pass shadow triangles | Main draws | Textures / total footprint (MiB) |
|---|---|---|---|---|
| Floor | <400,000 in existing native test | 150,000 | ≤100 | 96 / 600, provisional memory allowances |
| Standard, provisional | 500,000 | 180,000 | 120 | 128 / 750 |
| Hero, provisional | 600,000 | 225,000 | 140 | 192 / 900 |

Textures are included in total physical footprint; decoded tile bytes, JS heap and A4’s 48 MiB resident-geometry ledger are different measures. Historical Lakeview ~414k/<400k remains open. Current saved web shadow counters are **5,008 / 67,190**, both below 150k; earlier 245,154/322,586 failures are historical, native still unproven. Radius halving was not exercised in those captures and is an **unapproved experiment**, not a native port prescription: **do not shorten approved reach** or drop low-sun/off-view coverage. Native main-view estimates are not shadow-pass counters; missing telemetry remains pending.

**Facade boundary:** approved [v2](../proposals/facade-detail-v2/STATUS.md)/[v2b](../proposals/facade-detail-v2b/STATUS.md) supplement v1 for classified, supported buildings only; far/mid/near albedo remains identical, haze separate, calibration-v2 owns simplification. Cite v2 `content`, `lod`, `coverageMapping` and v2b `content`, `lod`, `coverage`. Roughly 40% unknown is R’s estimate, not a measured audit. A2 `5a373b7` is earlier-v1 evidence: four-family vocabulary, partial sixFlat and unimplemented hysteresis do not prove v2/v2b coverage. Do not force unknown classifications or duplicate detail.

**Execution and scoring:** run heavy builds/tests/captures only through `scripts/heavy.sh`, require load <25, preserve others’ locks, rebuild shaders and save source hashes. Preserve frozen cameras, date/weather, atmosphere, tier and drawable size; trace pack keys and RealityKit units (no transplanted web light/ACES values). A3 receives blind-labelled off/remove/layered phone-size frames; the executor keeps the mode key hidden until A3 locks §M closeness, all six aspects and reasons. Record controls and hashes, then reveal the mapping. No ΔE pass. Capture Sloan’s plus all ready untouched hold-outs; missing evidence is pending. Reject Sloan’s gain plus hold-out loss; the experiment additionally requires improved focus foliage, no ready hold-out/aspect regression and budget/correctness checks. No inferred 3/5 or four-hero pass.

## Batch 1 — foliage experiment 1 on iOS

**Ledger/visual binding:** [INTEGRATION.md — Foliage row](INTEGRATION.md) and AO row; [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/research/foliage-exp1-spec.md` §§ Decision and scope, Exact candidate math, Before / after frames and execution order, Predicted appearance and A3 decision. **Mock frames:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png`; retain the other native contract targets for all four heroes.

**Goal/files:** execute [A5’s exact spec](../research/foliage-exp1-spec.md) in `Sources/WorldEngine/Shaders/WorldShaders.metal`, `worldFoliageSurface` only. Fresh native **off → remove → layered**, separate rebuilt shader variants with selected constant/source hash recorded. Off preserves baseline; remove sets eligible crown emissive to zero; layered also applies A5’s exact A0/t/A1/M remap. Replace the constant `0.05 × AO` emissive term; do not stack fill or invent backlighting. Coefficients are experimental guesses, not approved pack values.

**Controls/proof:** eligibility and mask exactly per A5; living opaque deciduous near/middle/far crowns only. Bark, conifers, bushes, tufts, skyline and cards stay controls. No geometry, palette, season timing, placement, wind, exposure, key/fill, haze or shadow changes; no Props.swift/RenderResources.swift/Environment.swift edits. Check numeric witnesses, off identity, non-leaf exclusion, equal topology/counts and mode provenance. Capture `ordinary-street-afternoon`, `lakeview-street-afternoon`, `lakeview-postcard-afternoon`, `wilmette-street-afternoon` using [native contract](../lookloop/a3-capture-contract.json), then specified night/overcast/bare controls and ready additional hold-outs. A3 scores blind before mode reveal. Expected zero added triangles/draws/textures is a hypothesis; log actual costs and existing overages.

## Batch 2 — native water reflection/light and wet bank

**Ledger/visual binding:** [INTEGRATION.md — Water row](INTEGRATION.md); [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/review/integration-audit-2026-10-08.md` ranked item 2 / Water; `docs/tracking/web-ios-parity.md` item 2; `web/bakeoff/PORT-LIST.md` §5. **Spec/keys:** approved lake-winter-v1 `water` colour/shore/wind; water-surfaces-v1 `waveModelProposal` mechanics only; calibration-v2 `sharedLook`; haze-visibility-v1 owns background haze separately. **Mock frame:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png`, with untouched Lakeview calibration control.

**Goal/files:** 5A improves general native water light/reflection response and separate wet-bank treatment, starting from `Sources/WorldEngine/Shaders/WorldShaders.metal` water surface. Inspect `Sources/WorldGen/ShoreBand.swift` as existing input; generator changes need P2 handoff before edits. The A8 rank is expected impact, not a new numeric recipe. Use existing approved values; trace any missing design decision before implementing. A2 water at `355c6fb`/`80ed32c` is partial reference evidence, not native parity or a finished look.

**Proof/boundary:** freeze batch-1 foliage state, camera/fixture and lake palette; fresh before/after native Sloan’s plus untouched hold-outs, all six aspects, and reflection/shore correctness plus all-pass costs. No extra global grade, second haze, copied web light units, local water tuning, new package loader or pending water-colour authority. Feature closure needs consuming renderer file and updated ledger; no gain is assumed.

## Batch 3 — Lakeview native ~414k versus <400k

**Ledger/visual binding:** [INTEGRATION.md — Streaming row](INTEGRATION.md) (native existing-generator budget scope; this does not authorize adaptive integration), with Foliage/Facades rows for changed detail; [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/perf/ios-new-tiles-v1.md` §§ Loader compatibility, Measurements and floor comparison; `docs/research/foliage-rendering-v1.md` § Budget contract. **Mock frames:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png` for unchanged-look/hold-out review; the numeric budget test is separate from mock closeness.

**Goal/files:** measure and address the open floor budget using the **existing raw-area generator**, coordinating P2’s general thinning/LOD allocation work in `Sources/WorldGen/Props.swift` and relevant existing generator consumers. 5A owns `Sources/WorldEngine/World.swift`, `WorldDiagnostics.swift` and native measurement support; scope additional files in a handoff first. No adaptive tiles, GLB loader or package integration.

**Proof/boundary:** use `Tests/WorldEngineTests/ViewDrawBudgetTests.swift` under the established prerequisite-safe heavy workflow, report main triangles <400k and main draws ≤100 at frozen views, and separately establish shadow accounting against 150k (unavailable is pending). Preserve mapped geometry, stable identities, species/region rules and approved shadow reach; no Lakeview-specific constants or tier relabelling. Freeze the chosen batch-1 foliage and batch-2 water states before budget comparisons; validate unchanged Sloan’s/hold-out coverage and A3 grades. A1’s smaller GLBs cannot fix this native test.


STOP — input/mode/mask drift, failed shader/browser prerequisites, missing budget evidence, hold-out regression or any needed scope expansion: preserve evidence, log the exact blocker in handoffs.md and wait; no guessed values, bypasses or silent extra batches.
