# Facades — classified-family v2/v2b detail migration with immutable albedo

8 October 2026; for the 9 October restart. **Specification only: no renderer edits, builds or captures performed.** Inspected main `4485e18`; recheck execution main and SDK before work. Structure follows [foliage experiment 1](../research/foliage-exp1-spec.md). Inputs: [parity list](../tracking/web-ios-parity.md), [A8 integration audit](../review/integration-audit-2026-10-08.md), and [verifier report at 26ca169](../review/verifier-2026-10-08c.md). Later explicit owner rules and approved pack STATUS override older port-list advice; research is implementation context, not permission to import proposed values.

## One general rule and migration boundary

**For a supported, evidence-classified building, select the approved family’s detail by projected drawable size while keeping its real envelope and base material assignments identical across LODs; unknown buildings keep the existing fallback.** This implements [mobile-rendering-v1 research](../research-gpt/mobile-rendering-v1/README.md), **“Proposed world representation and selection”**, with [facade-detail-v2 README](../proposals/facade-detail-v2/README.md) **“Immutable albedo correction”** and v2b `values.json/coverage` as approved content authorities. Research batching/streaming proposals are not extra implementation scope.

A8 rank 8 and verifier item 7 identify v2/v2b as **not integrated**: existing native grammar and the web v1 adapter are partial evidence, not this migration. **Approved:** facade-detail-v1, corrected root v2 and v2b per their STATUS (which override historical pending labels), calibration-v2 simplification, haze-visibility-v1 atmosphere. v2 supplements v1; v2b adds nine missing families and supplements corrected v2 coverage. **Not approved, excluded:** `street-ground-v1`, `crown-silhouettes-v2`, `sky-cloud-v1`; also exclude `superseded/pre-albedo-fix-2026-10-08/` boards/values from current targets. Do not import the web v1 adapter’s authored masonry coefficients as if approved pack values.

## Exact values, coverage gate and future files

`facade-detail-v2/values.json/lod` and v2b `lod`: near **≥20 drawable px**, middle **≥6 and <20**, far **<6** projected object height; thin features culled below **1 px**; `hysteresisFraction=0.1`. For deterministic hysteresis, use thresholds T×(1+0.1) when entering a more detailed tier, T×(1−0.1) when leaving it; initial selection uses exact 20/6 thresholds. This is the explicit execution interpretation of the pack fraction, not an additional authored look coefficient. Verify consistency with an existing approved native hysteresis implementation before adopting it; conflicting interpretation requires a handoff. Pixel metric uses actual drawable resolution/FOV, not UI points; do not enlarge features.

`lod.albedoPolicy`: `immutableBaseColour=true`, `hueOffsetDeg=0`, `saturationMultiplier=1`, `baseColourMultiplier=[1,1,1]`; identical material-region assignment at near/mid/far. Haze is applied after lighting only. `content.families[id].baseAlbedo`, `materialsByLod`, and all family dimension/detail fields are consumed **verbatim from current root JSON**, not sampled from raster boards or averaged into new dimensions; retain real mapped colour/height/footprint/known geometry ahead of authored defaults. If a required key is absent, stop rather than inventing it.

Classification is a **precondition**, not a second classifier experiment: before edits, count unique exported building IDs by area, classified family, supported/unsupported family and unknown; preserve provenance and reconcile totals. The roughly 40% unknown figure is R's estimate, not an acceptance threshold or a new count. The earlier A2 whole-export audit found Sloan 578/1,399 unknown and Lakeview 1,112/2,823 unknown; those numbers must be recomputed on the frozen execution export. Do not force unknowns into a family, infer era from colour or infer a courtyard from the camera. If required classifications are missing, hand off a separately tested general classifier to P2 and leave this row pending. Improvements in classifier coverage require their own before/after data report, not silent inclusion in the facade look experiment.

| Exact exported family → approved recipe | Source |
|---|---|
| Chicago plainBlock → chicago-apartment; courtyardMass → chicago-courtyard | v2 `coverageMapping`; retain real courtyard void |
| Denver ranch, minimalTraditional, splitLevel, modern → denver-<same family> | v2b `coverage.requestedList` and matching `content.families[].id` |
| Chicago victorianRow, frameCottage, brickBungalow, cornerMixedUse, vintageHighRise → chicago-<same family> | v2b `coverage` and matching family IDs; cornerMixedUse is **not** v2’s generic mixed-use strip |
| Existing v1 supported families | Keep their existing supported recipe; sixFlat remains a partial adapter unless a separately traced classification/recipe proves fuller coverage |
| Other v2 families | Use only when a supported classifier maps explicitly to that exact recipe; no new forced six-family assignment from name resemblance |


**facade-detail-v2 exact base-albedo rows** (`content.families[id].baseAlbedo`; same at every LOD):

| ID | Wall | Accent | Trim | Glass | Roof |
|---|---|---|---|---|---|
| denver-apartment | #898D72 | #B19874 | #C6BEAA | #405766 | #625F59 |
| denver-courtyard | #B19874 | #898D72 | #C6BEAA | #405766 | #625F59 |
| denver-mixed-use | #898D72 | #B19874 | #C6BEAA | #405766 | #625F59 |
| chicago-apartment | #AA9271 | #777C65 | #C6BEAA | #405766 | #625F59 |
| chicago-courtyard | #AA9271 | #C6BEAA | #C6BEAA | #405766 | #625F59 |
| chicago-mixed-use | #AA9271 | #898D72 | #C6BEAA | #405766 | #625F59 |

**facade-detail-v2b exact base-albedo rows** (`content.families[id].baseAlbedo`; same at every LOD):

| ID | Wall | Accent | Trim | Glass | Roof |
|---|---|---|---|---|---|
| denver-ranch | #B6A183 | #B6A183 | #D8CCB5 | #405766 | #67645B |
| denver-minimalTraditional | #9A6650 | #9A6650 | #DDD0B6 | #405766 | #67645B |
| denver-splitLevel | #B6A183 | #898D72 | #D8CCB5 | #405766 | #67645B |
| denver-modern | #C9C4B6 | #B19874 | #3F4748 | #405766 | #625F59 |
| chicago-victorianRow | #98664F | #98664F | #DBC8A7 | #405766 | #554E49 |
| chicago-frameCottage | #A6AD99 | #A6AD99 | #DED5C1 | #405766 | #625F59 |
| chicago-brickBungalow | #A77960 | #A77960 | #DBC8A7 | #405766 | #554E49 |
| chicago-cornerMixedUse | #AA9271 | #898D72 | #C6BEAA | #405766 | #625F59 |
| chicago-vintageHighRise | #AA9271 | #C6BEAA | #C6BEAA | #405766 | #625F59 |

| Renderer / owner | Future files and bounded edit |
|---|---|
| Native — P2; 5A material review | `Sources/WorldGen/BuildingGenerator.swift`, `BuildingFacades.swift`, `HouseDetails.swift`, relevant `Profiles/*.json` consumer mappings: add supported recipe detail/LOD without changing source footprint/height or duplicating generated bays/stoops. Keep global light/shader/atmosphere unchanged. Native classifier work is separate if its gate fails. |
| Web — A2 | `web/bakeoff/facade-policy.js`, `facades.js`, `compile-facade-data.py`; add source-hashed copies of approved v2/v2b values under `web/bakeoff/data/` and load them in `main.js`. Export coverage/provenance report and implement tier hysteresis; do not edit shared `web/src/` or A4 streaming. Adapt canonical pack fields explicitly; missing generic fields do not authorize new defaults. |
| Tests — future | Extend `web/bakeoff/overnight.test.mjs` / add focused facade tier/material tests; native generator/facade tests under `Tests/WorldGenTests/` and the existing `ViewDrawBudgetTests`. Record actual test names before execution; no hidden skips. |

## Before / after frames and A3 decision

Freeze main/build/source hashes, package identities, camera, FOV, drawable resolution, date/season, weather, lighting and grade. Baseline is fresh current renderer **before this one change**, not the web legacy `baseline` URL. Save `<run>/<ios|web>/<view>/<before|after>.png` plus metadata and phone-width before/after/mock boards. Use the same inputs and packages before/after; never compare an iOS frame against a web frame as a score delta.

- **Native:** copy all arguments verbatim from [a3-capture-contract.json](../lookloop/a3-capture-contract.json); `ordinary-street-afternoon` (Sloan), then `lakeview-street-afternoon`, `lakeview-postcard-afternoon`, `wilmette-street-afternoon`. Sloan's contract targets are `docs/proposals/house-contrast-v1/images/denver-hero.png` for light/ground and `docs/proposals/house-archetypes-v1/denver-block.png` for building form, with calibration `docs/proposals/style-b-calibration-v2/frames/06-sloans.png`. Hold-out targets are the contract's `house-contrast-v1/images/lakeview-hero.png`, `postcard-hero.png`, `wilmette-hero.png`, plus calibration `style-b-calibration-v2/frames/01-lakeview.png`; do not substitute another camera to resemble these illustrations.
- **Web:** [scenes.json](../../web/bakeoff/scenes.json) Sloan then untouched Lakeview; exact approved targets `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `01-lakeview.png`. Hold the existing `fixture.json` date 2026-10-08, explicit summer-clear atmosphere/day, wind 10 km/h from 225°, standard label, DPR 1, Sloan 390×585 and Lakeview 390×780. Native's contract date differs: preserve each renderer's own matched pair and do not claim cross-renderer causal parity.
- **A3 owns scoring:** §M closeness and all six aspects, §N input/pixel-change controls; no ΔE acceptance substitute. [Completed saved web 4127a32 review](../lookloop/web-4127a32.md) is 2/5 in both views, pair FAIL 0/2; it is not pending and is not tomorrow's fresh control. Native historical 3/5 is context only. Reject-flag Sloan improvement paired with any hold-out loss; do not average away regressions. Any visual regression or unchanged-frame grade movement needs review before acceptance. Required West Highland/Greenville checks stay pending until capture-ready data and frozen cameras exist; absence is not a pass. The full four-hero gate and established confirmation remain required.

## Execution discipline and cost

Work on a branch; one rule per candidate. Run builds, full tests, simulator work and captures through `scripts/heavy.sh`. **Inside the acquired lock, verify its owner/PID belongs to this job, a fresh one-minute load is strictly <25 and free disk is at least 8 GB before starting.** The wrapper can reach its load timeout and continue, so its presence alone does not prove the gate; if high, release/defer and reacquire, never run anyway. If it reports an abandoned lock, do not treat that as ownership: stop this execution, leave other lanes' lock files untouched and report. Use only authorized localhost browser access; no driver workaround for a security denial. Paths in logs use `~`, never a personal home-directory absolute path. No phone install without R's authorization.

Use prerequisite-safe shader/test workflow and the commands in [weekend brief, Scoring and §0](../tracking/weekend-brief.md). Archive each capture before the next; a missing shader, dataset or capture is a blocker, not a skipped pass. Record chip/OS, load, resolution, FPS/frame time, available GPU timing, main triangles/draws, **every shadow and other pass**, texture allocations/staging and total physical footprint with units and missing measures labelled. GPU time cannot be inferred from CPU timers.

[Device tiers §2 and contradictions](../perf/device-tiers-v1.md), with later R approval in the weekend brief §A10, supplies provisional native envelopes: hero 600k main /225k shadow /140 main draws /192 MiB textures /900 MiB total; standard 500k /180k /120 /128 /750; floor 400k /150k /100 /96 /600. Preserve the stricter existing floor test **<400,000 main** and ≤100 main draws; sum all shadow submissions against its limit. Textures are included in total, not additional. Hero/standard are approved provisional guesses, not measured capacity or implemented browser tier allocations. Keep the historical ~414k Lakeview floor failure open until reproduced/resolved; do not relabel it standard. Compare web against its documented floor contract and report all allocations, not native phone capacity claims.

**Adaptive-package boundary (verifier item 1):** [A1 consumer contract](../data/adaptive-tiles.md#consumer-contract-a4-owns-integration) is merged exporter evidence, not proof A2/native consumes it. Unique leaf IDs and actual bounds are authoritative; parent grid indices are not unique; handle empty LODs and atomic parent→children replacement. Limits are ≤8 MiB decoded leaf, ≤2 MiB primitive, ≤16 MiB two-leaf queue. Repartitioning preserves geometry/attributes and does not reduce total triangles. Pin existing packages for this experiment. If a chosen input needs an unimplemented adaptive reader, stop and hand off to its owner rather than adding streaming to this feature change.

## Feature-specific boards, proof and stop conditions

Exact approved family-board files (each contains the near/mid/far triplet; resolve from the current root, not `superseded/`):

| Pack | Board file |
|---|---|
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/01-denver-apartment.png` |
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/02-denver-courtyard.png` |
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/03-denver-mixed-use.png` |
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/04-chicago-apartment.png` |
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/05-chicago-courtyard.png` |
| facade-detail-v2 | `docs/proposals/facade-detail-v2/images/06-chicago-mixed-use.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/01-denver-ranch.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/02-denver-minimalTraditional.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/03-denver-splitLevel.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/04-denver-modern.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/05-chicago-victorianRow.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/06-chicago-frameCottage.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/07-chicago-brickBungalow.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/08-chicago-cornerMixedUse.png` |
| facade-detail-v2b | `docs/proposals/facade-detail-v2b/images/09-chicago-vintageHighRise.png` |


Calibration frames above grade overall look. Additionally use approved **corrected root** `docs/proposals/facade-detail-v2/index.html` and `facade-detail-v2b/index.html`/their `panels/manifest.json` to select the exact family near/mid/far panel filenames; record those filenames and hashes before implementation, not the old superseded boards. These are qualitative construction references, not measured albedo. For the immutable-material witness, follow `lod.albedoPolicy.boardFixture`: haze disabled, identical light and material assignments; compare source albedo/material IDs directly as shaded pixels vary with geometry. This diagnostic is separate from the hero, whose approved atmosphere stays on.

Require area totals = classified + unknown and classified = supported + unsupported; list counts per family and all migration skips. Prove real envelope/courtyard/ground-floor identity unchanged, no duplicate details, unknown fallback untouched, and every base-albedo component/material-region assignment equal at all LODs. Sweep 20/6/1 px and hysteresis boundaries in both directions and at different drawable resolutions. Before/after side-by-sides: Sloan first, Lakeview street **and postcard** as decisive facade hold-outs, Wilmette unchanged; missing wider hold-outs stay pending. Do not predict a Sloan score increase merely from richer distant detail.

Measure added main/shadow triangles/draws, texture and staging memory and frame/GPU time; compare identical packages and report supported-family coverage alongside cost. No new photographic texture, per-brick geometry, LOD whitening or extra fog pass. A future detail optimization may not shrink mapped dimensions or remove approved silhouette merely to meet an envelope.

Stop for a missing family mapping/required dimension, insufficient classifier evidence, totals that do not reconcile, unknowns forced into families, LOD base-colour/material drift, courtyard infill, duplicate bays/stoops, rejected floor checks, or a hold-out regression. A partially covered area remains partial. Stop on prerequisite, load/lock/disk/browser failure or non-add-only merge conflict. Do not claim v2/v2b migration complete until every supported mapped recipe is verified and all unsupported/unknown counts are explicitly reported.

## Builder evidence-line template

`Used: docs/research-gpt/mobile-rendering-v1/README.md — Proposed world representation and selection; facade-detail-v2/README.md — Immutable albedo correction; facade-detail-v2b/values.json — coverage/content/lod; docs/execution/facades.md. Mock: docs/proposals/style-b-calibration-v2/frames/06-sloans.png + 01-lakeview.png; <native contract targets and exact corrected family-panel files>; <before/after runs, coverage totals, material-equality checks, A3 grades, costs>. Deviation: <none or reason; unknown/unsupported families and missing gates>.`
