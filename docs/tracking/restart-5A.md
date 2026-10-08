Read STATE.md first. Batch 1 only. Report in 10 lines. Stop.

# 5A restart — corrected three-batch plan

Map only. Batch 1: review A10’s native foliage exp1 result after A3 locks its scores and publishes evidence; do not implement a duplicate experiment. Record keep/reject/pending and freeze the reviewed foliage state. Batch 2: water. Batch 3: existing-generator floor budget. Keep pending if A10/A3 evidence is absent.

Web exp1 landed in 4210f1d/c3dbacf, default off, with approved equivalent deciduous identity and structural/arithmetic tests; shader compilation, GPU pixels and A3 scoring remain pending. No duplicate port belongs in 5A’s batches. Saved web 2/5 remains historical, not a gain.

**Superseded for this execution:** prior 5A implementation ownership, constant-rebuilt variants, blanket RenderResources prohibition and street-view capture order. A8 [restart recheck](../review/restart-recheck-2026-10-08.md) §§2,5–7 cites original restart lines 3,25,31,33 and spec lines 21,23,81; the current review procedure below replaces them.

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

**Execution and scoring:** For native frozen-contract captures run `scripts/capture-native.sh [--view VIEW]` directly; it acquires `scripts/heavy.sh` itself—never wrap it in another heavy invocation. Other heavy work still uses `scripts/heavy.sh`; load <25, own lock and disk gates remain. See [STATE native capture instructions](STATE.md#native-capture--one-command-a7) (audit lines 32–48) and [SOURCE-OF-TRUTH evidence rule](SOURCE-OF-TRUTH.md) (audit lines 18–20). The wrapper exposes view/output only (`scripts/capture_native.py:64–65`): do not invent inspection/mode flags; A10’s special set uses its explicitly recorded capture procedure until supported. Rebuild shaders and save source hashes. Preserve frozen cameras, date/weather, atmosphere, tier and drawable size; trace pack keys and RealityKit units (no transplanted web light/ACES values). A3 receives blind-labelled off/remove/layered phone-size frames; the executor keeps the mode key hidden until A3 locks §M closeness, all six aspects and reasons. Record controls and hashes, then reveal the mapping. No ΔE pass. Capture Sloan’s plus all ready untouched hold-outs; missing evidence is pending. Reject Sloan’s gain plus hold-out loss; the experiment additionally requires improved focus foliage, no ready hold-out/aspect regression and budget/correctness checks. No inferred 3/5 or four-hero pass.

## Batch 1 — review A10’s native foliage experiment after A3 scoring

**Ledger/visual binding:** [INTEGRATION.md — Foliage row](INTEGRATION.md) and AO row; [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/research/foliage-exp1-spec.md` §§ Decision and scope, Exact candidate math, Before / after frames and execution order, Predicted appearance and A3 decision. **Mock frames:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png`; retain the other native contract targets for all four heroes.

**Goal/files:** review A10’s native foliage exp1 result after A3 locks its scores and publishes evidence; do not implement a duplicate experiment. Record **keep/reject/pending**, freeze the reviewed foliage state, and retain pending when required evidence is absent. Review `worldFoliageSurface` and only the approved runtime files recorded in [handoffs](handoffs.md) (audit line 273): `Sources/WorldEngine/RenderResources.swift`, WorldLab `Demo.swift` and `ContentView.swift`. This review authorizes no new implementation. Current [A10 strict pixel stop](../research/foliage-exp1-native-pixel-stop.md): branch unmerged, controls fail at 1/255 while baseline repeat is 0; no A3 visual result.

**Controls/proof:** review A10’s default-off launch-selected off/remove/layered experiment and Sloan inspection captures at **40/150/600 m**; require baseline/off pixel identity **0** and non-mask category maximum pixel differences in all modes. Preserve exact pose/fixture/drawable metadata and mode/source hashes; hold-outs remain pending until separately captured/scored. Follow [inspection contract](../experience-inspection.md) (audit lines 11–19). The ≤1/255 camera-repeatability result is not the experiment’s stricter zero-difference acceptance. Use the full approved mask amendment **66aac35**, including resolved slots **3–6 or 24–28**; flowers/bushes, conifers, bark, tufts, skyline and cards remain unchanged controls. The 7e1ea82 eligibility blocker is resolved by approval only; runtime/category/pixel validation is not thereby passed. Preserve geometry, palette, seasonal timing, placement, wind, exposure, key/fill, haze and shadows. A3 scores blind before mode reveal; record actual costs and existing overages.

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

Report ending, per SOURCE-OF-TRUTH:

```text
Used: <doc §>. Mock: <file/frame>. Deviation: <none or why>
Tracker update:
```
