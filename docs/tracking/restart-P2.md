# P2 restart — corrected three-batch plan

Map only. P2 supports the native-first experiment and existing-generator budget work; coordinate with [5A’s three batches](restart-5A.md), without running geometry changes concurrently with its material comparison.

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

## Batch 1 — verify generator controls for iOS foliage experiment 1

**Ledger/visual binding:** [INTEGRATION.md — Foliage row](INTEGRATION.md) and AO row; [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/research/foliage-exp1-spec.md` §§ Decision and scope, Exact candidate math (native eligibility), Cost and stop conditions. **Mock frames:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png`; preserve every additional native contract target.

**Goal/files:** read `Sources/WorldGen/Props.swift` crown AO and `extra`/flag semantics against [A5’s spec](../research/foliage-exp1-spec.md). Verify that the native eligibility mask selects opaque deciduous near/middle/far crowns and excludes bark, conifers, bushes, tufts, skyline and cards. Preserve geometry, normals/AO, palettes, placement, stable identities, LODs and all export data while 5A executes **off → remove → layered** in its shader.

**Proof/boundary:** provide existing generator tests and mask/attribute evidence to 5A; A3 blind-scores frozen native variants before unmasking. Use approved foliage-seasons-v1 `species[].seasonColours`/`cities[].mix` and calibration-v2 `sharedLook` as unchanged authorities; pending crown-silhouettes-v2 grants no approval. This batch does not implement cards, native atlas bindings, regional recolouring or a second AO/emissive term. Any mismatch is a handoff, not permission to rewrite eligibility by appearance.

## Batch 2 — general thinning / LOD allocation on the existing native generator

**Ledger/visual binding:** [INTEGRATION.md — Streaming row](INTEGRATION.md) (native existing-generator budget scope; this does not authorize adaptive integration), with Foliage/Facades rows for changed detail; [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/research/foliage-rendering-v1.md` §§ Budget contract, Proven techniques and bounded cost estimates; `docs/perf/ios-new-tiles-v1.md` § Measurements and floor comparison. **Mock frames:** `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png`; no budget pass inferred from the images.

**Goal/files:** after the experiment evidence is frozen, address Lakeview’s historical ~414k versus strict <400k using general, data/region/projected-size rules in existing `Props.swift` and relevant existing building/detail consumers, with exact touched files named before edits. Native continues from raw area data. Stable IDs, real footprints/heights and mapped placements remain authoritative; use detail allocation, not arbitrary removal of mapped buildings or a per-block constant.

**Proof/boundary:** use existing generator/LOD tests and native `ViewDrawBudgetTests` with 5A, main draws ≤100, separate 150k shadow accounting, unchanged coverage and A3 paired Sloan’s/untouched hold-outs. Do not stack this into the material experiment, claim new-tile savings, shorten approved shadow reach, or promote floor failures into provisional standard/hero passes. Save measured counts by category/area; all unseen views use the same rule.

## Batch 3 — classified facade v2 / v2b migration

**Ledger/visual binding:** [INTEGRATION.md — Facades row](INTEGRATION.md); [MOCKS M-CAL-SLOANS](MOCKS.md#m-cal-sloans) and [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview). Update the consumed feature row and citing build in the same commit.

**Research:** `docs/tracking/web-ios-parity.md` item 8 (Facades); `docs/review/verifier-2026-10-08c.md` item 7; approved facade-detail-v2/v2b STATUS and values keys cited below. **Mock frame:** `docs/proposals/style-b-calibration-v2/frames/01-lakeview.png`; untuned Sloan’s hold-out frame `docs/proposals/style-b-calibration-v2/frames/06-sloans.png`. These calibrate appearance, not exact building inventory.

**Goal/files:** inspect `Sources/WorldGen/BuildingGenerator.swift`, `BuildingFacades.swift`, `HouseDetails.swift` and regional classification profiles; name the minimal actual changes in the handoff. Implement general classification/coverage handling and approved family detail within the v2/v2b boundary above. Keep unknowns explicit; first measure total/classified/supported/unknown by area rather than treating the ~40% estimate as data.

**Cite/proof:** v2 `content`/`lod`/`coverageMapping`, v2b `content`/`lod`/`coverage`, calibration-v2 simplification and haze-visibility-v1 atmosphere. A2 `facade-policy.js`, `facades.js`, `compile-facade-data.py` at `5a373b7` are v1 reference evidence only. Test classification/mapped-data precedence, supported-family coverage, near/mid/far albedo equality, detail budgets and actual drawable-pixel transitions/hysteresis; A3 scores paired native views. Do not change base colour by LOD, duplicate bays/trim, invent classifications or report unsupported web families as ported. This follows the budget batch; it is not a shadow/package task.

STOP — input/mask drift, untraceable rules, missing controls or budget evidence, hold-out regression, or any required work outside these three batches: log the exact handoff and wait; no per-block fixes, guessed coverage, bypasses or unapproved scope expansion.
