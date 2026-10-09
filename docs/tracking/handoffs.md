# Cross-lane handoffs — A3

A3 is the only filing lane; Claude P3 is paused (R, 8 Oct 2026). Main's existing filing from P3 (`f3fb595` and subsequent updates) is authoritative. This log adds missing coordination records; it does not change pack approvals, STATUS files or compiled values. Dates below are the owner decision/report dates.

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-07 | P2 → 5A / A3 | Species crowns and city fallback mixes | Merged `fcda086` / `262dd22`; inferred fallback remains labelled. No new scoring claim here. |
| 2026-10-07 | 5A → P2 / A3 | Wet-ground sheen and rain darkening exception | Merged `7fcb580`; main's closed exception retained. |
| 2026-10-07 | 5A → P2 / A3 | Lake colour and water mechanics | Merged `22a1dee`; lake-winter-v1 owns colour, water-surfaces-v1 mechanics. |
| 2026-10-08 | P3 → A3 | Sole ownership of filing, trackers, roadmap, owner log and handoff log | Accepted on R's instruction. P3's main filing wins; duplicate A3 filing/STATUS/index/value edits discarded from the replacement change. |
| 2026-10-08 | R → A1 (Astra) | Data lane | OSM/Overture, heights/roofs, assessor, terrain/DEM, licences and QA in the existing data area. |
| 2026-10-08 | R → A2 (Astra) | Web bake-off lane | Confined to web/bakeoff/; water permitted only there. iOS water/shader/compiled water wiring remain with 5A. |
| 2026-10-08 | R → A3 (Astra) | Filing + trackers lane | Docs only, no code. A3 is the only filing lane; P3 paused. Mirrored lane map in AGENTS.md and CLAUDE.md; every other main rule retained. |
| 2026-10-08 | A3 → A1 | metro-data-coverage-v1 | A1 owns coverage/source/licence QA; canonical research already filed on main. No duplicate proposal copy needed. |
| 2026-10-08 | A3 → A1 (live-world later) | live-flights-v1 and real-flights-path-v1 | A1 owns source/privacy/freshness verification now; live-world later. Hosted adsb.lol launch decision and lawyer gate remain as main records them. |
| 2026-10-08 | A3 → A2 web/W1 | licensing-demo-v1 | Web licensing-demo owner, after the look gate. Main's filed design remains authoritative. |
| 2026-10-08 | 5A → A3 | Calibration v2 colour tune | Main `9884994`; no new look-loop scoring in this docs-only task. |
| 2026-10-08 | P3 → A3 | Slim runtime mock bundle | Main `cb7ac4a`; main's full reference/slim runtime split retained unchanged. A3's duplicate aggregate is not included in this change. |
| 2026-10-08 | A3 → R | ZIP relocation | 12 source ZIPs listed in zips-for-r.md; awaiting R's external-drive move. None copied, committed, moved or deleted. |
| 2026-10-08 | R → A3 | Upkeep mode | No recurring automation or auto-merges. Update trackers when R asks or after lane reports; no schedule created. |
| 2026-10-08 | R → A3 | Holds | Somewhere remains unfiled; Southern awaits R. |
| 2026-10-08 | A3 → R | Missing-pack audit | All 28 earlier requested/earlier-research packs already exist on main, including research-gpt locations and the transit CSV. No new pack filing required. |

P3's remaining handoff items (Friday cleanup plan, source sweeps, open lawyer questions) remain in docs/decisions/owner-log.md, 2026-10-08; this task does not execute them. Add future handoffs with date, from → to, item and status, grounded in lane reports or R's request.

Verification for this narrowed change: only these two tracking files and the mirrored instruction files differ from main; no proposal, STATUS, source, compiler, test or mock-value changes. No new visual-closeness claim applies to this documentation-only change.

## No block-specific fixes — R, 8 Oct 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | R → all look/data/generator lanes | General data/region-driven rules only; no place/building/camera tuning | Binding rule added verbatim to AGENTS.md and CLAUDE.md. Every new mock exception requires R's written approval. |
| 2026-10-08 | A3 → capture/scoring lane (P3 paused) | Untuned hold-out protocol | Required after every look merge: Lakeview, a fixed other Denver neighbourhood (not Sloan's Lake), Greenville Downtown; name/freeze the second Denver block and capture IDs before comparison. No new captures claimed by this docs task. |
| 2026-10-08 | A3 → A1 | Unchanged pipeline hold-out coverage/quality | Required alongside Sloan's for data reports; include area/source/configuration evidence. |
| 2026-10-08 | A3 → look-loop code owner (P3 paused) | finish.py legacy scoreboard row | Code update queued, not performed by A3. Until then A3 fills the two new columns manually from lane evidence after each look merge; missing results stay pending. |
| 2026-10-08 | look lanes → A3 | Sloan's score and hold-out score | Report both with merge/run evidence after every look merge. A3 records individual hold-out scores and rejects Sloan's gains accompanied by hold-out losses. |

## A1 → P2 — Sloan's Lake survey roofs, 8 October 2026

Prepared data: `Data/areas/sloans-lake/building-heights.json` and `building-roofs.json`; contract: `docs/data/building-roofs.md`. 407/1,399 buildings have accepted candidate roof heights; types: 77 gable, 66 hip, 113 flat, 151 other; 992 missing. All D and uncalibrated. Source is the 2020 USGS survey; ground and roof share that survey, NAVD88 metres. No class-6 points exist locally, so explicitly labelled planar class-1 candidates are used. Treat confidence as support, not probability; retain nulls and keep estimates separate. P2 owns consumer wiring and visual validation. Tests/merge pending; no live engine change claimed. R deferred Lakeview and Greenville; approved Greenville bounds remain HOLD.

### P2 state note (2026-10-08, stopped by R for budget)
- Branch: p2/yards (pushed); main has all P2 merges through 0bdb88d (infrastructure stage 1). Parked, pushed, unmerged: p2/night-windows (night-fog warm/cool flags, on hold per R).
- Done: house contrast + gaps, archetypes (conformance 164/164), lake shore band, daytime-master colours, wall variant weights, species crowns (foliage-seasons-v1), lane markings/crosswalks where mapped.
- Unfinished: water profile per water body by area/fetch (WIP commit on p2/yards, untested); Lakeview street 414k > 400k triangles (ViewDrawBudgetTests, only measured with the Mac shader build: POSTCARD_FILTER=ViewDrawBudgetTests scripts/postcard_mac_check.sh).
- Next: run that budget test, fix with a general distance/screen-size thinning rule, verify Sloan's + hold-outs; then test and merge the water-profile change.

## 5A state at stop (R, 8 Oct)

- Branches (all on GitHub, none merged): 5a-aerial-lod (option A, 3D eye-to-cell distance), 5a-exposure-general (proposal 1, one -3.1 Y8 offset on the bible), 5a-no-silent-skips (test.sh builds the shader library; prerequisites fail instead of skipping).
- Done: aerial LOD suite passed except the known Lakeview budget (414k > 400k, P2's); exposure suite 374/374 under the old script; no-silent-skips not yet run.
- Unfinished: LOD rerun on current main (stopped while queued); exposure hold-out renders (Sloan's + Lakeview, before/after) and A3 score; proposal 2 (key/fill solved on a neutral patch) not started; autumn hue jitter (5a-tree-hue) unmerged.
- Next step: run 5a-no-silent-skips' full suite, merge it; rerun 5a-aerial-lod and merge if only the Lakeview budget fails; hold-out-render 5a-exposure-general, merge if Sloan's and Lakeview both hold, ask A3 to score; then proposal 2.

## Look-scoring takeover — R, 8 Oct 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | R / paused P3 → A3 | Look capture, calibration scoring and reporting | Accepted. A3 establishes a new baseline from current main before grading later changes. Historical P3 scores remain intact. See ../lookloop/a3-baseline.md. |
| 2026-10-08 | A3 → A1 | Second Denver hold-out data | Proposed West Highland. Main contains only Sloan's Lake as a dedicated Denver area; broad context data is not a validated neighbourhood capture. Prepare an area with the unchanged pipeline and report coverage/quality; camera must be frozen before look testing. Recorded handoff, not a claim that another lane has been messaged. |
| 2026-10-08 | A3 → A1 | Greenville Downtown hold-out | Deferred until data exists (R). No score, no pass inferred. |
| 2026-10-08 | 5A / P2 / A2 → A3 | Every subsequent look merge | Provide merge SHA, affected views and before/after evidence; A3 scores Sloan's plus individual untuned hold-outs and records reject flags. A2 needs its own renderer-specific baseline and matched conditions; iOS scores do not establish web performance. No recurring automation or auto-merges. |
| 2026-10-08 | A3 → A3 | Paired scoreboard columns | Manually maintain both columns after scoring; finish.py still emits 15 fields. Preserve individual hold-out results, missing-data states and grader identity. |
| 2026-10-08 | A3 → R / look lanes | Current-main A3 baseline | Completed fresh run `20261007-225009` on main `0b9d255`: 3/5 closeness on all four heroes, FAIL 0/4. Foliage 2 throughout; Lakeview saturation 2. New grader baseline, not a cross-grader regression claim. Full paired clearance pending Denver/Greenville data. Evidence: ../lookloop/a3-baseline.md. |
| 2026-10-08 | A2 → A3 | Web bake-off merge `9b7403e` | Main advanced with isolated web/bakeoff work. iOS baseline inputs unchanged; separate A3 web/hold-out scoring remains pending, no web pass inferred from the iOS baseline. |
| 2026-10-08 | R / A3 → P2, 5A | Foliage gap | Foliage 2/5 in all 4 views, Lakeview saturation 2/5. Needs ONE general rule: layered/softer crown shading + region-driven greens. Owners: P2 (crowns), 5A (colour). Waiting for Claude restart. |

### A1 → A3: general height pipeline and Downtown hold-out (8 Oct)

The height step now runs unchanged on Sloan's Lake, Lakeview and Greenville Downtown. Accepted / OSM footprint coverage: 407/1399 (29.1%), 2618/2799 (93.5%), 437/681 (64.2%); all grades D, not independently calibrated. Source metadata distinguishes vendor building classes from planar candidates. `Data/quality/height-holdouts.json` verifies identical methods and no evidence invariant errors; lock-protected suite: 124 tests, 3 skips. Greenville Downtown's approved rectangle plus 100 m fetch buffer is now present; Greer remains HOLD. No render/look/water change or renderer-consumption claim. Preserve the same frozen area definition for future look comparisons. Heights commits: f58ab89, 2449804; subsequent merge supplies the comparison report.

### A1 → P2 / A3: common roof evidence on three areas (8 Oct)

`building-roofs.json` now exists for Sloan, Lakeview and Greenville Downtown. Known forms / OSM footprints: 407/1399 (29.1%), 2563/2799 (91.6%), 419/681 (61.5%). All grades D; support scores are not calibrated probabilities. Pitch is degrees from horizontal; ridge is an approximate north-clockwise axis in [0,180), not a traced segment. Preserve source ages, observed versus generated estimates, and unknown/null forms. The shared ridge normalization is regenerated from point data in all areas; no per-building edits. `Data/quality/roof-holdouts.json` reports identical methods and no evidence errors under the heavy lock. Commit 285678f; this handoff/report follows. P2 owns consumer wiring and visual validation; A3 owns frozen look comparisons. No render/look/water files changed.

## Web baseline and map-only order — R, 8 October 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | A2 → A3 | Current web candidate `08e2cce` | Independent A3 baseline filed: Sloan's 2/5, Lakeview 2/5; pair FAIL 0/2. Verified saved captures, separate from iOS. Candidate not merged on main at review. See [report](../lookloop/web-baseline.md). |
| 2026-10-08 | A2 / A3 → 5A, P2 | Shared look rules on restart | Read [A2 RULES.md snapshot](A2-RULES.md), byte-identical to A2 `08e2cce`, including general sky/crown rules and unresolved haze precedence. Filed for restart visibility; no engine handoff or rule override implied. |
| 2026-10-08 | A2 → A3 | Each subsequent A2 merge | Supply merge SHA and frozen Sloan's + Lakeview captures/proof. Record before/after closeness and six aspects; reject-flag Sloan's gain with hold-out loss. [Tracker](look-gate.md). No unattended automation. |
| 2026-10-08 | A1 → A2 / A3 | Remaining web hold-outs | West Highland pending data/export/camera. Greenville A1 height/roof data received; web export and frozen camera pending. No visual pass from data checks. |
| 2026-10-08 | R → all lanes | Map-only order | [Sloan's gate → hold-outs → Builder Easy + Pro → jobs game](roadmap.md). |

**Publication update (8 Oct):** A2 `08e2cce` reached main while this report was being filed. Its captured look inputs are identical to the reviewed baseline. This is the initial A3 web baseline on that merge: Sloan's 2/5, Lakeview 2/5; no comparable pre-merge A3 web score exists, so the reject comparison remains N/A, not a pass.

## Haze visibility — R, 8 Oct 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | R / A3 → A2 | Consume haze-visibility-v1 now | [Approved pack and precedence](../proposals/haze-visibility-v1/STATUS.md) filed. A2 consumes now in web/bakeoff; integration completion pending A2 evidence. Use 5% MOR, not 2%, overriding the named background haze fields in lake-winter-v1, weather-moments-v1, mountain-terrain-v1 and night-fog-v1. Mountains: contrast ≥0.05 AND projected height ≥2 px, with valid DEM sightline. Report merge and paired Sloan's/Lakeview captures to A3. |
| 2026-10-08 | R / A3 → 5A | Migrate weather-moments on restart | Waiting for 5A restart. Apply values.json/overrides and its 21 moment migrations; recompute visibility equivalents under 5% MOR. Preserve local fog layers and unrelated light, palette, water and event fields. [Source specification](../proposals/haze-visibility-v1/README.md). |

## Facade detail — R, 8 Oct 2026

| Date | From → to | Item | Status / evidence / next step |
|---|---|---|---|
| 2026-10-08 | R / A3 → A2, P2 | Consume facade-detail-v1 | [Approved by R (8 Oct 2026)](../proposals/facade-detail-v1/STATUS.md). Tiers: **far massing/colour bands; mid bays/trim; near geometry; calibration-v2 owns simplification**. Filed; implementation pending lane evidence. Use general data/region-driven rules and report look merges for paired scoring. |
| 2026-10-08 | A3 → R | sky-cloud-v1, street-ground-v1, crown-silhouettes-v2 | FILED with status **concept pending approval**. Await R’s approval; no consumption authorization or replacement of approved targets inferred. |

## A3 visual scoring and owner rules — 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A3 → A2 | 5c72bad visual §M review | Sloan's 2 → 2, Lakeview 2 → 2; FAIL 0/2. Reject condition not triggered; no closeness gain flagged. Seasonal fixture changed; preserve matched conditions for future deltas. [Report](../lookloop/web-5c72bad.md). |
| 2026-10-08 | R → A6 | sky-seasons-v1 §2.1 phase ranges | Approved for A6 only. No whole-pack or other-lane approval inferred. |
| 2026-10-08 | R → all lanes | Add-only handoff conflicts | Keep both entries in date order in handoffs.md; all other conflicts still stop. Mirrored in AGENTS.md and CLAUDE.md. |
### A1 → 5A / A3: generic native elevation and distance backdrop (8 Oct)

`Data/areas/{sloans-lake,lakeview-sheil-park,greenville-downtown}/elevation/metadata.json` indexes native unresampled 1 m GeoTIFF clips and the identical mountain-terrain-v1 distance policy through 200 km. Native rectangle plus 100 m halo and every radial band have verified 100% coverage in all three areas; 16 terrain tests and complete read-back audits pass under the heavy lock. `Data/quality/elevation-holdouts.json` is the comparison; per-area `qa.json` links metadata digests. Arrays are orthometric NAVD88 metres (EPSG:5703), not ellipsoid heights. NPZ grids contain surface/minimum/maximum arrays, affine transforms and -9999 nodata. Native local clips overlap coarser bands; prefer the native local source there. The Sloan outer envelope retains 4395.916 m Front Range elevations; do not substitute envelope maxima for the terrain surface. 5A owns datum reconciliation, loading, meshing/LOD and visual acceptance; no render/look/water edits were made. Terrain commits are size-limited groups on astra-a1-general-terrain.

## Weekend restart — R, 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A3 → 5A, P2 | Ordered map-only restart | [Weekend brief](weekend-brief.md): scoring commands, foliage/sky/MOR, shadow and Lakeview floor, six branch dispositions, later MetalFX. Today's HUD request: fps/tris/draws/mem on R's 14 Pro. Docs only; tests/device proof remain required. |

2026-10-08 — R / A3 → 5A, P2: [Before porting any Astra value](weekend-brief.md#before-porting-any-astra-value): verify source and RealityKit units, render/compare with A3, and stop/log any untraceable value; do not guess.

## Architecture and city runbook — R, 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A3 → data/generator/renderer lanes | Architecture and city onboarding | [Architecture](../architecture.md) and [add-a-city runbook](../runbooks/add-a-city.md) filed from existing contracts and A5/A1 evidence. No new readiness or ingestion claims. A7 ownership remains conditional on R explicitly saying “yes A7”; no lane-map change made. |

## Generalization panel — R, 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A3 → A1 / render lanes | [Ten-block variety panel](../lookloop/generalization-panel.md) | Docs-only proposal; fixed panel, failure-only smoke, unseen blind checks and reject-rule connection filed. GREEN source evidence is scoped; West Highland and expansion block readiness remain unconfirmed. No data downloads. A1 must clear/freeze missing inputs before running them. |

## A2 → A4 one-time streaming capture — R, 8 Oct 2026

R explicitly authorized A2 to read A4's `web/stream/` without edits, use headed Chrome on localhost under the shared heavy lock at load <25, run Sloan at 60 and 600 m/s for 60 seconds each, then load Lakeview unchanged, and file evidence plus this handoff. A2 located the A4 source at `0dcf2f8` in the primary checkout and read its REPORT/README/server. **Blocked before execution:** REPORT.md and overnight-progress.json record an administrator-enforced browser-policy verification denial; A2 did not bypass it with another driver. No browser measurements, server or heavy job started; no stream files changed. [Evidence and missing measurements](../../web/bakeoff/evidence/stream/REPORT.md), [source hashes and null results](../../web/bakeoff/evidence/stream/blocked.json). Resume only after the administrator-policy check is restored for an authorized browser route; this filing does not validate or merge A4's viewer.

## Facade extensions and proposed policy review — R, 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | R / A3 → A2, P2 | facade-detail-v2 and v2b | Approved by R; [v2](../proposals/facade-detail-v2/STATUS.md), [v2b](../proposals/facade-detail-v2b/STATUS.md). Classified buildings only; far albedo identical to near, haze separate. Roughly 40% unclassified remains P2's general classification task in [weekend brief](weekend-brief.md). Filing is not integration. |
| 2026-10-08 | R / A3 → architecture / legal review | User corrections, private projects and world access | [Architecture sections](../architecture.md) all PROPOSED; [lawyer agenda](../research/licensing.md#proposed-lawyer-review-agenda--r-8-oct-2026) added. No implementation, legal clearance or game-dynamics restart. |

## West Highland camera and cohort — 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A1 / R → A3 / capture lanes | [West Highland hold-out](../lookloop/west-highland-holdout.md) | Proposed camera confirmed unchanged before scored comparison; frozen camera/shared fixture contract must be saved with capture. Separate data-poor cohort: 19.1% heights, 19.0% roofs. No capture/score claimed. |
| 2026-10-08 | A1 → A3 | Sparse-density test | PENDING; ladder NOT PROMOTED. Supply test definition, coverage/count/source QA and unchanged-method evidence. |

## Contributor onboarding — R, 8 Oct 2026

| Date | From → to | Item | Status |
|---|---|---|---|
| 2026-10-08 | A3 → all contributors | [Lane onboarding](../CONTRIBUTING-lanes.md) | Ownership/scope, session notes, standing rules, prompt template, Sonnet/Opus guidance, external-input locations and Mac requirements filed. Shared versioned pack store proposed only; no movement/upload. Missing artifacts and A7 formal ownership uncertainty remain explicit. |

## A8 / A9 / A10 / A11 filing — R, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A8 → A1 / A3 | `48a6ec0` verification | [Filed review](lane-reviews.md). West Highland elevation read-back and web bundle NOT delivered, pending A4 lock; Lakeview 2,823 vs 2,799 has no ID crosswalk. Supply actual artifacts and reconcile populations before delivery/coverage claims. |
| 2026-10-08 | A9 → A1 / source-rights review | `ed9a43f` independent height references | Filed; no height reference GREEN, licences unresolved. No ingestion or independent-validation clearance. |
| 2026-10-08 | A10 / R → 5A, P2 / A3 | `19a627c` device tiers | Hero/standard budgets approved only as provisional guesses; floor unchanged. Lakeview ~414k vs 400k open; HUD requires -debughud, no in-app switch. Native/device proof pending. |
| 2026-10-08 | A11 → A1 / app and web release owners / A3 | `9cdc184` licence inventory and credits draft | [Filed review](lane-reviews.md). Web export and app build **RED for public release**: ODbL offer is a placeholder; credits draft is not wired. Supply a working offer and artifact-specific credits evidence before release clearance. |

## Generated haze status follow-up — R, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A3 → A7 → A3 | Generated haze supersession | A7 received exact failure: only `docs/lookloop/mock-conflicts.md` differs from compiler output in blocked `06d9dfb`; both generated JSON files match. Existing haze STATUS/INDEX already records the 5% MOR override, but compiler approval parsing and conflict rendering do not carry it through. R directs independent filings to land now, with generated file unchanged. After A7 reports the fix, A3 pulls/regenerates and lands the haze status separately; guard stays enabled, no script edits by A3. |

## Generated haze status closed — A3, 8 Oct 2026

| Date | From → to | Item | Status / evidence |
|---|---|---|---|
| 2026-10-08 | A7 → A3 → A2 / 5A | `df81ad8` source-driven haze resolution | **FILED / freshness confirmed.** A7 already landed the regenerated [mock-conflicts report](../lookloop/mock-conflicts.md) on main. A3 pulled it and ran `python3 -B Tools/lookloop/compile_mocks.py --check`: PASS. Approved haze-visibility-v1 uses 5% MOR and recomputes legacy 2% equivalents; scoped overrides preserve weather-moments localLayerExtinctionPerM unless independently recalibrated, night-fog ground fog 0.035/m and spatial layers/patches. Darkness alone does not raise extinction. Earlier generator-blocked status above is historical and closed. No script, source-pack or renderer changes by A3; no integration or visual pass claimed. |

## Web scoring attempt — A3, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A3 → R / A2 | [4127a32-series visual review](../lookloop/web-4127a32.md) | Saved standard-tier Sloan’s/Lakeview captures reviewed: closeness 2/2, all six aspects unchanged from web baseline; no gain, pair FAIL. Fresh capture blocked by browser connection failure before navigation. No bypass, no render/look edits; resume fresh capture when tooling recovers and heavy lock is free. |
| 2026-10-08 | A3 → A1 / A2 | West Highland frozen hold-out | Data-poor cohort stays pending: current bake-off has no West Highland scene/server mount; tracker has no completed read-back/web bundle delivery. Supply capture-ready package/scene with frozen camera/fixture, then A3 scores; no inferred grade or ladder promotion. |

## A5 / A12 and Builder decisions — R / A3, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A5 / R → 5A restart / P2 / A3 | `e9dc90c` foliage research | [Filed](lane-reviews.md): layered crown shading/colour → silhouette/LOD allocation → conditional sparse leaf cards. Native leaf-atlas shader integration missing. Replace rather than stack the constant `0.05 × AO` emissive contribution. Hypothesis only; no score claimed. 5A restart input, not implementation acceptance. |
| 2026-10-08 | A12 / R → Builder planning / A3 | `dd0af9a` shared outdoor planner | Events/activations-first hypothesis pending five conversations; construction is a layer on the same product. Implementation/conversations not started. Data rights, ODbL offer and independent shadow validation remain release gates. No outreach authorized by this filing. |
| 2026-10-08 | R → Builder / legal review | Private uploads and two-step AI | Private user-owned logo/brand uploads allowed; engine ships no brands. Plan/map underlay with manual placement first; AI proposes layout for user approval second. Product decisions recorded in owner log; rights/sharing/takedown/retention and invite-only ODbL offer sent to the lawyer list Q62–Q63 as questions, not clearance. |

## A1 → P2 / 5A / A3 — approved West Highland and fallback review, 8 October 2026

R approved the proposed West Highland 1 km rectangle and GREEN-only inferred fallback ladder, requiring a Lakeview observed-height comparison (including tree-overhang) before any export use. Exact approved bounds are saved; unchanged height/roof/DEM pipelines have run. See `docs/data/west-highland.md` for source, coverage and fixed-camera proposal, and `docs/data/fallback-validation.md` for the table already shown to R. No new fallback rung is selected or exported; observed nulls remain intact. Proposed error limits are awaiting R, and the tree-overhang stratum is a vegetation-overlap proxy rather than independently verified labels.

P2: `Data/areas/west-highland/building-heights.json` has 476/2496 accepted heights (19.1%); `building-roofs.json` has 474/2496 forms (19.0%), all D. Same GREEN 2020 Denver survey and generic planar-candidate method; 2020 height nulls and 2022 roof nulls. Consumer wiring stays with P2; no generator edits. 5A: native 1 m NAVD88 metre clips and all distance bands to 200 km report full coverage; final read-back audit is queued under the heavy lock. Current generator does not consume these observations.

A3: proposed camera `west-highland-aerial-north-01` is recorded before any capture; confirm/freeze it before scoring. A standard web package plus separately indexed observed sidecars is prepared as an area-independent export command, but no export or visual pass is claimed yet. A4's human-operated validation server holds the shared lock while R completes browser flights. A1's final rebased QA/export waits; no other lane's lock was altered. Initial verification: 151 Python tests passed, 3 skipped, and 69 map/package tests passed. Main moved and A1 rebased cleanly; final checks and merge are pending lock access.

A1 checkpoint: its own waiting wrapper was cancelled; A4's server/lock was untouched. Final verification/export is ready to resume once the lock is free; merge remains pending. No background export is left queued.

## A1 → A4 / A3 / A8 — real artifact delivery and adaptive packer, 8 October 2026

West Highland read-back is now present at `Data/areas/west-highland/elevation/qa.json` (99.9167% native requested mask, one edge row flagged; five bands 100%; no invariant errors). The actual bundle is `~/Desktop/world-engine/.claude/worktrees/astra-a1-data/Generated/west-highland-web-2026-10-08.zip`; payload hashes, JSON reads, observed-sidecar equality and ZIP CRC passed. See `docs/data/west-highland.md` for the exact hash and limits. This supersedes earlier absent-artifact status, not A8's valid historical finding. Observations are separate from generated mesh; no population crosswalk or independent reference licence is claimed.

A4: adaptive packer exists at `Sources/WorldPackage/AdaptiveTilePacker.swift`, commit `a9e1d87`, CLI `worldbake pack <existing-package-dir> <new-output-dir>`. Usage/consumer contract: `docs/data/adaptive-tiles.md`. Exact measured source packages were read unchanged; outputs are `~/Desktop/world-engine/.claude/worktrees/astra-a1-data/Generated/adaptive/sloans-lake` and `.../lakeview-sheil-park`. Sloan 48→76 leaves, Lakeview 25→114; all GLBs ≤2 MiB. Worst two LOD0 decoded arrays: 3,756,466 B and 4,176,512 B, respectively. Use IDs/actual bounds and explicit emptyLODs; parent grid index is not unique. No look values or A4 files changed. Focused tests pass; complete independent audit/repeat is queued behind A4's 10:22:46 human long-flight lock. This is not a runtime upload/frame-time or retained-memory pass.

A3: sparse-density test achieved median 3.4891 returns/m² against the same full-density grade-D reference and frozen vegetation-overlap groups; full table in `docs/data/fallback-validation.md`, no correction/promotion. Merge waits for R's approval of the add-only a1-data.md conflict; handoffs.md's existing exception alone does not cover it.

## A1 → A4 — target 939d04f alignment, 8 October 2026

R relayed the exact decoded limits. The packer now separately enforces 8 MiB decoded per leaf and 2 MiB decoded per primitive, publishes per-LOD/part costs, and retains bounded coarse parent payloads under atomic replacementGroups. Original 200 m ground parents and stable 100 m building-cell identities remain separate from adaptive payload leaves; no new uniform grid or look values. Contract: docs/data/adaptive-tiles.md. Updated focused tests and a two-area audit/repeat job are queued under scripts/heavy.sh behind A4's human long-flight server; the new revision is not yet verified. Existing measured Lakeview children total at most 4,176,512 decoded bytes for the worst two LOD0 leaves, below 16 MiB; that earlier measurement is not substituted for the new revision's audit. No A4 files edited. Merge also remains blocked on R's pending a1-data.md add-only conflict approval.

## A1 → A4 / A8 — full adaptive audit verified, 8 October

Read-only input exports remain unchanged. Verified outputs in A1 worktree Generated/adaptive-targets/{sloans-lake,lakeview-sheil-park}; independent evidence Data/quality/adaptive-tile-packing.json. All 73 map/package tests passed; complete geometry/channel, scene joins, hashes, parent coarse coverage and byte-identical repeat checks passed. Sloan 48→76 leaves, worst two decoded arrays 3,756,466 bytes; Lakeview 25→114, 4,176,512 bytes (original 17,332,572). Every leaf ≤8 MiB, primitive ≤2 MiB, worst pair ≤16 MiB. See docs/data/adaptive-tiles.md for replacementGroups and featureOwnership contracts. This is export validation, not viewer/A16 performance. No A4, look or generator files changed. Merge remains stopped because tracker “NOT delivered yet” and completed-delivery entries conflict under R's latest conditional approval.

## Corrected restart files — R / A3, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A10 / A8 / A5 / A2 / R → 5A, P2 | [5A restart](restart-5A.md), [P2 restart](restart-P2.md) | Three batches and one STOP line each. 5A: native A5 exp1 off/remove/layered with blind A3 scoring; existing-generator Lakeview budget; web exp1 port. P2: preserve/verify experiment controls; general existing-generator thinning/LOD; classified v2/v2b facades. A10 confirms native raw-area input, no adaptive package reader. A4 owns web package/streaming. A8’s seven corrections included: scoped adaptive contract, unapproved shadow halving/approved reach, current saved web grade, current shadow counters, provisional envelopes and later approval chronology, facade boundary. No implementation, capture or score claimed. |

## Source-of-truth handover — R / A3, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A8 / R → all builders / A3 | [Current state](STATE.md), [source protocol](SOURCE-OF-TRUTH.md), [input index](INDEX.md), [integration](INTEGRATION.md), [mocks](MOCKS.md) | Docs-only audit-to-ledger filing; no runtime or score improvement claimed. Every build updates consumption/row/mock citation together, then rewrites STATE after report. Any model may run a lane with the same checks and current handoff. 5A batches: foliage → water → raw-generator budget; web exp1 deferred. P2 keeps controls → budget → classified facades. A3 current branch: astra-a3-source-of-truth, base bcfc8aa; no owned lock/server; next: builder reads STATE and assigned batch, captures under strict load/lock and submits blind evidence. |

## Pre-restart audit corrections — A3, 8 Oct 2026

| Date | From → to | Item | Status / next step |
|---|---|---|---|
| 2026-10-08 | A8 / R → 5A, P2, A2 | Mock-content audit `8f97697` §§5,7–9 | Docs corrected: foliage → water → budget; classifier repair separate prerequisite; CSS-pixel water conversion; witness sun separate from native fixture; halving superseded/unapproved; completed web-4127a32 grade; five bounded consumers; seven spec-only briefs; literal evidence line; ground/AO partial pending build proof. No implementation or score claimed. |
| 2026-10-08 | A3 → 5A / A7 | Native smoke `smoke-20261008-native`, main `3f6f8df` | One attempt through heavy wrapper, admitted load 6.09; Xcode exit 65 before capture: `error: The file “package” couldn’t be opened because there is no such file. (in target 'WorldLab' from project 'WorldLab')`. Own lock released. Stopped; web and West Highland not attempted, no fresh score. Local logs: `/private/tmp/worldengine-a3-web-baseline/.build/lookloop/smoke-20261008-native/`. Build/capture prerequisite needs repair in its owning lane. |

## Web foliage experiment 1 implementation — A2, 8 Oct 2026

R explicitly authorized web implementation now, superseding the deferred web schedule. Branch `astra-a2-foliage-exp1`, control `fc439aadce9a560a6f46fd1c5a81d972ce5e32d6`. Renderer scope: `web/bakeoff/foliage.js`, `main.js`, `capture-once.mjs`, new `foliage-exp1.test.mjs`. Default/absent off; invalid modes error; remove is the web identity control. Layered alone uses the spec AO remap and sole base multiplier. New attributes are remapped through the original weld indices; lights, palette, exposure, topology, shadows, haze and placement stay unchanged. Pending crown-silhouettes-v2 excluded.

Arithmetic suite passed under `scripts/heavy.sh`, admitted load 14.77, disk guard passed, own lock released: exp1 numeric witnesses/mask/bark; policy, overnight, atmosphere, sky-colour tests; JS syntax and diff checks. 1,056 species/region/date/LOD cases match control geometry bytes and bounds; absent/off/remove retain exact material graphs and instance inputs. This is structural render-input identity, **not GPU pixel readback**. Layered shader compilation and visible hemisphere AO remain unverified. Added buffers are 8 bytes per vertex before copies; synthetic fixture aggregate 886,800 bytes is not scene residency or measured GPU memory. No captures, browser, server or scoring run; no new score claimed.

A3 after capture repair: use `MODES=candidate TIERS=standard FOLIAGE_EXP1=off`, then remove/layered via the spec capture workflow; Sloan's then Lakeview unchanged. Outputs route to `web/bakeoff/evidence/foliage-exp1/<mode>/<tier>/`, with mode provenance and hold-out proof. Archive each run. Legacy baseline remains separate and unchanged; do not use old `verify.sh`/`score.py` legacy candidate paths for experiment scoring. Verify GPU default-off pixel identity against control and layered compilation before blind scoring. No approval of native parity or performance inferred from arithmetic.

Used: docs/research/foliage-exp1-spec.md, Exact candidate math / Web AO adapter / Cost and stop conditions. Mock: style-b-calibration-v2/frames/06-sloans.png and frames/01-lakeview.png. Deviation: no captures per R; off proof is structural, rendered pixels and shader response pending A3.


### A10 → A3: WorldLab inspection camera (8 October 2026)

R requested app-only free-camera controls and reproducible poses. Aerial/Explore consume `InspectionCamera` through the existing postcard API; one-finger orbit, two-finger pan, pinch, 8–1,500 m clearance, Reset view, Debug → Camera pose (off by default), copy launch argument, and `-inspectionpose lat,lon,alt,heading,pitch`. Rendering/shaders/budgets/tile inputs unchanged. See [experience-inspection §1–3](../experience-inspection.md) for conventions, capture recipe and local files. Seven focused tests (including seven invalid-input cases), simulator build, three Sloan’s zoom screenshots and same-pose repeated-frame check (≤1/255 RGB difference) pass under heavy lock. No device install, A3 score, or web parity claim. Earlier harness timeout was corrected by reading simulator-local log paths. Main advanced with A7 capture/preflight tooling during the task; rebased and camera checks rerun before merge.

Used: docs/experience-inspection.md §1–3 (R’s A10 request). Mock: docs/proposals/style-b-calibration-v2/frames/06-sloans.png (unchanged-world reference). Deviation: controls per R; simulator evidence only, no visual scoring.


### A10 native foliage experiment 1 — eligibility reconciliation pending (8 October 2026)

Execution-main `a77c4e4`. Read `docs/research/foliage-exp1-spec.md` and `docs/execution/ao.md`; no AO/finish edits are included in this task. Shader baseline `WorldShaders.metal:468–490` remains unchanged, including `su.emissive=su.base*0.05h*half(extra.x)`. R now explicitly requests launch-argument mode selection and Sloan’s inspection poses at 40/150/600 m, superseding the spec’s build-only mode selection and frozen street-camera capture order. Implementation has not started.

The exact spec mask selects a non-crown control: `Props.swift:392–394` adds flower-bush accents, `:538–539` assigns unflagged flower paint and `extra=(1,0.9,0,0)`. At full leaf these meet `extra.y>0 && extra.z<0.5 && !su.leafCut && !(flags&512)`. The spec explicitly says to keep bushes as controls and “If generator semantics differ at execution time, stop and reconcile the mask; do not widen it by appearance.” No shader changes, builds, captures, scores or pixel-diff claims were made.

Concrete reconciliation proposed for R: retain the exact predicate and additionally require `(slot>=3 && slot<=6) || (slot>=24 && slot<=28)`, using the already-resolved `paletteSlot`, with provenance `StyleProfile.swift:222–232` (`SeasonalPalette.order`) and `Props.swift:950–960` (`crownPaint`, restricted deciduous family slots). This narrows eligibility to existing deciduous crown identities, excluding flowers without changing geometry or palette. Awaiting R’s decision rather than guessing a replacement for the exact spec mask.

R’s runtime selection also requires app option parsing and material/uniform transport, beyond the spec’s build-only local constant. Before implementation, name those additional files in the handoff; change no other shader function, AO merge, budget or tile logic. Use A7’s merged single capture command when available, with baseline/off identity required to be exactly zero, 3 heights × 3 modes and source/mode provenance; A3 scores, not A10.

Read-only coordination: A4’s chat was idle with its own latest validation stopped; A7 owned the heavy lock (`native capture: prepare, build, install and collect`), sampled load 169.85. No A4/A7 process or lock touched, and no heavy work started. Recheck A4 status, load <25, lock and disk before execution; idle chat alone does not authorize concurrent browser benchmarking.

Used: foliage-exp1-spec.md Decision and scope / Exact candidate math / Cost and stop conditions; execution/ao.md Authority. Mock: style-b-calibration-v2/frames/06-sloans.png (reference only, no new capture). Deviation: stopped for mask reconciliation; R-requested runtime selection and inspection capture order supersede the older spec workflow.


### A10 — approved foliage mask / runtime wiring (8 October 2026)

R approved the corrected mask: exact spec predicate plus deciduous slots 3–6 or 24–28. Dated amendment is in foliage-exp1-spec.md. Additional runtime files named before implementation: `RenderResources.swift` adds a default-zero mode to `ShaderGlobals` and unused row-1 texel 52; WorldLab `Demo.swift` parses `-foliageexp1 off|remove|layered`, and `ContentView.swift` validates and sets it before environment application. Environment retains existing globals, so no Environment/World/Props changes are required. Only `worldFoliageSurface` reads the new texel; default local constant is 0. Separate focused tests cover arithmetic, generated eligibility and isolated native category pixels, without production geometry changes. Capture baseline/off exact identity and 3 heights × 3 modes remain required before merge; no score inferred. Heavy admission must stop after ten minutes without acquisition and report the current lock holder.

## Web exp1 approved identity correction — A2, 8 Oct 2026

Consumed spec amendment `66aac35` in `web/bakeoff/foliage.js`; regressions in `foliage-exp1.test.mjs`. Web rebuilds crowns without native palette indices, so the equivalent to crownPaint's deciduous1..9 (slots 3–6/24–28) is an explicit whitelist of P2 deciduous crown generators plus non-evergreen identity, existing live-leaf omission, opaque-only geometry and LOD <3. No RGB inference, new palette or geometry. Bush/flower groups bypass rebuilding; conifers now retain the original material graph in every mode. Default remains off. Tests caught and fixed a Three material-clone roughness reset before merge; explicit control initialization preserves the original calibrated value.

Under heavy lock at load 4.69 and ≥8 GB disk guard: exp1 numeric/mask/control tests, policy, overnight, atmosphere and sky-colour all pass; 1,056 baseline geometry cases unchanged. Bush/flower/conifer legacy geometry buffers compare byte-for-byte and canonical material graphs match pre-experiment `fc439aa` in off/remove/layered. This proves render inputs, not GPU pixels; no captures/scoring and no visual gain claimed. Own lock released. A3 still owns GPU/capture validation.

Used: docs/research/foliage-exp1-spec.md §Approved native eligibility amendment / Web AO adapter. Mock: style-b-calibration-v2/frames/06-sloans.png and frames/01-lakeview.png. Deviation: web uses the approved equivalent crown identity; GPU pixel comparisons pending, no captures run.


### A10 — native foliage strict pixel stop (8 October 2026)

See [failure evidence](../research/foliage-exp1-native-pixel-stop.md). Approved mask amendment remains merged; native implementation `bba0a3a` stays unmerged. Arithmetic/generated-mask tests and Metal compilation pass. Bush, conifer and other non-mask controls each differ by max 1/255 in all three modes; unchanged baseline repeat is exactly 0. Separate baseline-return candidate still fails. Heavy admission load 8.83, no lock bypass; job failed and released. No Sloan’s capture or self-score. Further implementation must resolve exact identity before capture/merge.

Used: foliage-exp1-spec.md Mask / Exact candidate math / Cost and stop conditions; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: required pixel identity failed; implementation and captures stopped.

### A3 — A8 restart recheck applied (8 October 2026)

Applied [165d5e1 recheck](../review/restart-recheck-2026-10-08.md) §§2–8, preserving its original file/line citations: restart-5A:3,25,31,33 / STATE:9,26 ownership; restart-P2:3,31,33,41,43 coordination; both restarts:23 capture and evidence; spec:1,15–23,39,45,81,83 superseded owner/mode/files/order/mask/web status; STATE:14 versus 18,32–48 historical failure versus 3/3 readiness. Both restart files now start with the batch-1-only instruction. 5A reviews A10 after A3 scoring (keep/reject/pending), then water, then existing-generator budget. P2 preserves controls and waits for both comparisons before thinning. Native strict-pixel failure remains pending/unmerged; web 4210f1d/c3dbacf remains default-off with pixels/scores pending. No code, captures or scores changed.


### A10 — separate-build variant / amended gate stop (8 October 2026)

R approved and spec records separate build-time variants with shipping source byte-identical to main, amended non-mask ≤1/255 gate and baseline-repeat zero. Branch `astra/a10-foliage-build-variant`, head `9c4b054`, compiles; arithmetic/generated-mask and five capture CLI tests pass. Baseline-repeat and remove are max/mean 0 for all seven categories; layered skyline at full leaf has max 2/255 and fails. Both equivalent flow layouts fail. All category maximum/mean measurements and shipping SHA-256 are in [evidence](../research/foliage-exp1-native-variant-stop.md). No Sloan’s capture, A3 score or native code integration. Additional branch files are the variant generator, native/mac build scripts, capture worker/tests, WorldLab batch-pose/provenance parsing and focused native tests; no RenderResources or runtime uniforms changed. Heavy jobs use load <25 and release their locks.

Used: foliage-exp1-spec.md Approved native build-variant / pixel gate amendment; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: layered skyline max 2/255 fails amended gate; captures and native code merge stopped.

### A10 — R-approved separate native build variant (8 October 2026)

R supersedes the pixel gate as amended in the spec. Shipping Metal source stays unchanged; generated `scripts/foliage_variant.py` inserts only the approved rule into worldFoliageSurface in a temporary source. Additional build files: `scripts/build-native.sh` and `scripts/postcard_mac_check.sh` compile explicit FOLIAGE_EXP1_BUILD remove/layered variants; default off compiles shipping source. `scripts/capture_native.py` and its focused tests select build mode, freeze inspection poses and record compiled source/library hashes. WorldLab Demo.swift / ContentView.swift parse mode for capture provenance and apply inspection pose in batch views. No runtime material/uniform transport, RenderResources, Props, Environment, geometry, budget or tile changes. Native arithmetic/mask/category fixture is Tests/WorldEngineTests/FoliageExperimentTests.swift. Validation and captures pending; A3 scores.


### A10 → A3 / 5A: FINAL native foliage variant and nine frames (8 October 2026)

Capture build `ec14fed`; separate build-time remove/layered constants 1/2, default shipping source unchanged (SHA-256 in evidence). Generator→native build→engine resource bundle→unchanged RenderResources.init is the reachable native path. No Props/Environment/render-source/budget/tile changes, no runtime uniform transport. FINAL category gate passes at both leaf fractions for all seven categories; repeat/remove max/mean/differing bytes exactly 0; layered max 2/255, worst mean 9.34600830078e-5 byte units, largest differing count 98. Exact per-category/fraction table: [final evidence](../research/foliage-exp1-native-final-evidence.md).

One heavy admission (load 5.62, no wait) ran tests then immediately the nine-frame batch. All baseline/remove/layered × 40/150/600 m Sloan’s frames succeed, 1005×565 RealityKit captures, zero crashes; observed poses and frame/library hashes checked. Images/JSON/logs remain ignored in `/private/tmp/worldengine-a10/.build/a10-foliage-final/`; keep this worktree until A3 consumes them. Main docs link every frame and provenance. No self-score; A3 scores, 5A reviews only after scores; hold-out and confirmation gates unchanged/pending. Source/build/test/capture changes listed in the evidence.

Used: foliage-exp1-spec.md FINAL native non-mask gate amendment / Exact candidate math; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: owner-approved variant/FINAL gate; Simulator evidence only, no score or hold-out pass.

### A3 → 5A / A10 / A4 — native exp1 blind scores, 8 Oct 2026

[Nine-frame review](../lookloop/foliage-exp1-native-scores.md): baseline/remove/layered at 40/150/600 m all foliage 2, overall 2, no 2→3 uplift. Faceted crown blobs persist at 40 m. Layered 600 m lacks the baseline/remove outer road/ground grid: investigate loading/visibility before causal comparison; no code diagnosis or fix asserted. Do not promote layered as a demonstrated improvement. Native category tolerance pass retained; historical street hero 3 unchanged. A3 preserved source PNGs and checked all hashes; no captures, builds or heavy lock. Hold-outs Wilmette, Lakeview street/postcard, West Highland data-poor and Greenville wait until A4 finishes and missing native contracts/fixtures are ready; one gated batch command filed in review.

### R → P2 / 5A / A3 — crown-shape approval, 9 Oct 2026

Crown-silhouettes-v2 approved for every block; foliage research is the shape direction. STATUS changed: crown-silhouettes-v2 and foliage-seasons-v1 (existing binding foliage target, reconfirmed); vegetation-v1 unchanged because STATUS.md absent. Exp1 shading 7e800f7 stays 2/5 across all nine, not the lever; shape is the next lever, unbuilt/unscored. P2 builds one American elm all-block recipe with layered lobes/scaffold/near-middle-far, whole-scene <400k main / ≤150k shadow / ≤100 draws; if it does not fit, report per-crown cost and stop. 5A reviews colour/shading; A3 blind before/after at 40/150/600 m under A10’s delivered procedure, then hold-outs. Freeze shape before thinning and retain water freeze before budget. fd0eaa5’s other boundaries, batch-1-only opening, three batches, STOP and report template retained; no code or capture in this filing.

### R / A10 → A3 / P2 / 5A — coverage attribution correction, 9 Oct 2026

R’s 9 Oct correction, relaying A10: the 600 m layered coverage loss was a capture loading race, not a variant defect. Original frames/grades remain unchanged; no repeat capture or new score is claimed. Current STATE/INTEGRATION/MOCKS and both restarts corrected; historical score observations retained with an explicit later correction. Crown-silhouettes-v2 and foliage-seasons-v1 approvals/reconfirmation remain filed; vegetation-v1 unchanged (no STATUS.md). P2 one American elm all-block recipe, whole-scene floor and per-crown-cost stop; 5A review → water → budget; A3 blind before/after and later hold-outs remain unchanged.

### R → A3 / P2 / 5A — vegetation-v1 filing complete, 9 Oct 2026

Created vegetation-v1 STATUS under explicit approval for every block; original README/JSON/images untouched. Proposals INDEX, input/mock/consumption ledgers and STATE updated. Native vegetation profile/Props references remain partial; no direct web file consumer or per-sheet visual acceptance claimed. [Related pack status inventory](foliage-approval-review.md) records approval recommendations without changing other packs. Only vegetation-v1 received a new status in this filing; no additional approval blocks the American elm trial.

### A10 → A3 — blocked matched-batch validation (8 Oct report; filed after 9 Oct directions)

A10 `74eac73`: new baseline/SCENEREADY native validation and nine-frame replacement batch **pending valid heavy admission**, not delivered. All six triangle/draw categories (including context) and snapshot-vs-SCENEREADY counters must match; ten lightweight tests pass, native app/GPU proof unproved. A10 cancelled only its queued wrapper after 10m18s behind A4’s live lock; no build/capture or new batch directory. Original frames and A3 scores preserved. Evidence: [investigation, matched-batch preparation](../research/foliage-exp1-600m-coverage-investigation.md#matched-batch-validation-preparation--2026-10-08). Reported A4 owner PID 86011, job “A4 last-round confirming pair server”, start 2026-10-08 16:45:35; cancellation at 17:11:02, load 16.98. This preserves the report’s timing, not a live lock claim. No new frame paths or scoring request; A3 performed docs-only filing and did not inspect or alter locks.

## A1 → R / A3 / P2 — house shortcut census, 8 October

Read-only evidence: docs/data/house-shortcut-census.md and Data/quality/house-shortcut-census.json. Counts use building=yes static shortcut candidates that remain house after contextual garage overrides, with non-part loader buildings as denominator; no rendered-use or lidar-coverage claim. Tunnel guard/unsupported diagnostics status is specified but not implemented in core; existing context suppression is partial. No generator/render/input edits.

### A10 BEFORE readiness ledger — source 5d159ff

Verbatim A10 delivery status (the final no-new-score sentence describes A10’s delivery; A3’s subsequent two-frame grades follow separately):

A10: capture-only SCENEREADY natively built and exercised in nine validation captures plus six BEFORE controls. At each of 40/150/600 m, three validation runs match all geometry/category/context counts: 313,022/53; 333,886/50; 228,159/43 main triangles/draws. Completed-frame threshold ≥3 passes; 40 m logged completion counts are 3/3/4, not exact equality. All 15 logs prove readiness before snapshot, no crashes, unchanged shipping shader/default off, per-run heavy releases. BEFORE repeats: 40 m max/mean/count 0/0/0; 150 m 1/0.0000303791/69; 600 m 7/3.1852701096/1,694,760 decoded-byte differences. STOP: 600 m control noise; allocator and AFTER candidate not started. Exposure convergence is suspected but unproved, and needs capture-only investigation before a valid crown comparison. A3 scores/hold-outs unchanged; no new score or phone-performance claim.

**A3 follow-up:** [Fresh 40/150 m BEFORE grades](../lookloop/crown-native-before-scores.md): overall 2 and each visible §M aspect 2; sky N/A. 600 m not scored. Existing historical grades preserved; no AFTER or hold-out result.

## A1 → R / A3 / P2 / 5A — core tunnel guard and diagnostics, 8 October

R-authorized changes in Sources/WorldGen/SceneGenerator.swift, RoadMarkings.swift and WorldBuild.swift plus WorldMap classification/diagnostics and worldbake CLI. Underground carriageways/paint/generated street detail suppressed; data/network preserved; no railway, look, portal or other feature geometry change. Data/quality/unsupported-features.json and tunnel-guard-comparison.json delivered; docs/data/tunnel-guard.md explains unique-object counts, fallback distinction and reproduction. 85 tests and CLI pass. Road triangles: Sloan 2544→2540 (two tagged building_passage ways), Lakeview 2088 unchanged, Wilmette 1136 unchanged, West Highland 1888 unchanged, Greenville 7301→7279. All graph hashes and mesh batch counts unchanged; unaffected areas have identical full static geometry hashes. A3: only Sloan/Greenville underground strips expected to disappear after rebuilding; no capture/score or hardware draw proof claimed. Used: A8 long-tail row 2 / archetypes stage 0. Mock: none (safety guard). Deviation: Sloan expected zero contradicted by mapped passages.

### A3 — A10/A1 ledger and input-index reconciliation

A10 5d159ff exact ledger text and two fresh BEFORE blind scores already filed in 9650d7c; retained without duplicate grading, original 40/150 m hashes rechecked. Overall and light/saturation/ground/foliage/materials each 2, sky N/A; 600 m excluded, no hold-outs. A1 855babe tunnel results were already delivered in these trackers; pinned implementation SHA instead of “this commit”. Road-strip triangles Sloan 2544→2540 (two building_passage ways), Greenville 7301→7279, Lakeview 2088, Wilmette 1136, West Highland 1888 unchanged. All graphs/mesh batch counts unchanged; unaffected full static geometry byte-identical. 85 tests + CLI passed per A1; these are generation results, not measured renderer draws or a visual pass. Added budget-tiers.md (cecd8c9) and community-builds.md (ca2141c) as proposal-only index entries with no consumer/build claim. Other lane rows preserved; docs only.

### A2 → A3 — web crown ledger, 8 October 2026

Verbatim [A2 crown report](../../web/bakeoff/evidence/crown-v2/REPORT.md#ledger-text-for-a3):

A2 web foliage shape: partial, American elm only, default-off crownV2 standard/floor. Consumer `main.js` → `foliage.js` (`buildElmV2`, `allocateCrownBudget`, pooled instancing); target crown-silhouettes-v2 approved by R. Implementation revision: commit introducing this report on `astra-a2-elm-budget`; control `855babe`, supersedes unmerged `aa3a068`. Both scenes fit their requested CPU tier criteria with unchanged shadow reach. Default-off identity and allocation tests pass; GPU counts/pixels, secondary details, hold-out appearance and A3 grade remain pending. Current capture/scoring status unchanged. No INTEGRATION/STATE edits made per R's explicit routing instruction.

Implementation is on main as `0c0316e`; native ownership/status and historical scores are unchanged. Requested Sloan’s OFF/standard/floor × 40/150/600 m captures and provenance are not yet filed on main. All nine overall/six-aspect grades, foliage ≥3 at 40/150 m, aspect regressions and comparison to the saved web pair (2/5) remain pending. No hold-outs run; the reject rule cannot be evaluated without their evidence. No capture, build or render-code change in this filing.

## A1 → R / A3 / P2 / 5A — tunnel audit correction, 8 October 2026

Supersedes the initial negative-layer policy and Greenville −22 claim above. R/A8 correction restores source isTunnel semantics (any tunnel value other than no), with a separate yes/building_passage/culvert render predicate for carriageways, generated curbs/sidewalks/lamps and paint. Context negative-layer bridge exception restored; yards, occupancy and postcard candidates retain semantic policy. Layer-only Greenville ways 311413668, 757360129, 757360130 remain drawn and diagnosed as layer-only, review. 87 tests pass under the heavy wrapper, including negative bridge, tunnel=no, layer-only, covered, occupancy and postcard controls. Filed generic Python/Swift harness regenerated baseline df3adf8 and corrected five-area hashes: Sloan 2544→2540, Lakeview 2088→2088, Wilmette 1136→1136, West Highland 1888→1888, Greenville 7301→7287 road triangles; merged batch counts unchanged. Road identifier/centerline hashes match in these five areas; canonical static position/index hashes match in the three zero-change areas. No full routing, GPU draw, arbitrary-area or visual equivalence claim. Evidence and serialization: docs/data/tunnel-guard.md; Data/quality/tunnel-guard-comparison.json and unsupported-features.json. Used: A8 audit 1e5edfb, semantics/scope/hash findings. Mock: none (tag-policy safety fix). Deviation: none.

A3: rebuilding restores the three Greenville layer-only strips (8 triangles versus 855babe); Sloan building passages remain suppressed. Native capture/scoring remains a separate pending check; no look values changed.

### A10 → A3 → R — summer BEFORE season check, 8 October 2026

[Summer season check](../lookloop/crown-native-summer-scores.md), evidence ae0e110 / capture 0600748: July 15 pinned BEFORE 40/150/600 m each overall/foliage 2; light/saturation/ground/materials 2, sky N/A. No grade change against historical October 40/150 m; October 600 m remains unscored. Summer green mock is a look/form reference, not a literal October pigment target. Auto-exposed October versus pinned July is not a season-only control. No gate-date change recommended or applied; no hold-outs. A10’s 150 m control max 1/255, mean 0.000213093822921 byte units, 484 differing bytes; original frames preserved. Report only; no render/fixture edits or new captures.

### R → A3 — private metro reference collection, 8 October 2026

[Metro reference folder](../screenshots/metro-reference/README.md) established: city-state subfolders on delivery, coordinate/heading filenames when known and private per-metro metadata covering location, capture date/time and R ownership. Metro contents are gitignored; no images supplied, moved or published. INDEX and hold-out protocols now require matched-view blind skyline height/massing PASS/FAIL plus tallest-ten building evidence, with missing inputs pending and no gate threshold change.

### A7 → A3 → A2 / R — web crown ladder grades, 8 October 2026

[A3 web crown ladder review](../review/crown-web-ladder-scores.md), delivery 2fba43a / capture fd99b9d: all 18 blind-graded. OFF/standard/floor foliage 2 at every height; overall 2 at 40/150 m, 1 at 600 m due to shared lake bands/striping. July OFF/standard have no whole-point seasonal grade delta. All ladder modes fail main triangle/draw tiers; shadows ≤70,497. No hold-outs or promotion; real-render provenance/hashes checked. A2 follow-up evidence: main non-foliage alone 529,108/117, 570,468/166, 473,923/198 triangles/draws at 40/150/600 m; whole-scene floor cannot be certified from the elm allowance. Shared 600 m water/ground rectangles and striping need a separately authorized general investigation; no code or new capture by A3.

### 2026-10-08 — A3 → A2/A7/5A/P2: current crown ladder grades

[Post-near-plane blind review](../review/crown-v3-ladder-scores.md), delivery c8c361d / capture 1580115: 16 PNGs, 12 unique hashes; OFF repeats and identical v2 600 m aliases scored once. Sloan OFF/v2 standard/v2 floor/v3 standard foliage and overall 2 at 40/150/600 m; lake bands gone, historical 600 m overall 1 → 2 from projection correction. v3 does not reach foliage 3; clearer scaffolds but thin repeated sprays, no whole-point aspect gain/drop versus v2. Lakeview 600 m overall 1, foliage 2, ground 1; no matched prior score, reject-rule comparison pending. Sky N/A; popping untested. No promotion, code, captures or builds.

Used: GRADING.md §§M/N. Mock: calibration-v2/frames/06-sloans.png. Deviation: unobservable sky; motion and matched hold-out comparisons pending.

### 2026-10-08 — A3 → builders/reviewers: proposed comparison and NYC audit protocols

A3 protocol-only update: [paired preferences](../review/paired-preference-protocol.md) proposed beside GRADING §M (six balanced judgments, identity/position controls; not validated reliability or a gate change). [NYC audit](../review/nyc-wrongness-audit-protocol.md) retains five fixed cells/taxonomy/counting and adds sceneBudget=1 web measurement; Midtown result unknown pending registered scene/data. No captures, code or scoring.

Used: GRADING.md §§M/N; archetypes.md; scene-budget-variant.md. Mock: future registered approved pair targets. Deviation: protocols only, unvalidated proposed repetition thresholds.

### 2026-10-08 — A3 → A7/A10/A2/5A: native/web matching limits

[Native/web comparison](../review/native-vs-web-matched-comparison.md): requested-pose/date pairs reviewed with six balanced presentation orders, but resolved native eye +0.16 m, unmatched exposure/wind and noisy native600 exclude every pair from fully matched acceptance. Exploratory native preferences, saturation ties at40/150; no platform/gate gain. Protocol limitations (same context, sequential rather than spatial A/B, recognizable identities) disclosed. No captures/code.

Used: native BEFORE evidence and paired protocol. Mock: calibration 06-sloans. Deviation: unmatched inputs; no accepted matched score.

## 2026-10-08 — R-authorized A4 surface companion → P2 / A1 / A2

R explicitly authorized A4 to implement the export-only companion from `989f3c9`, including the minimal generator changes P2 owns. Scope: semantic paint annotations only in BuildingGenerator/BuildingFacades/BuildingDetails, an opt-in task-local recorder in WorldMesh, and separate companion serialization/CLI in WorldPackage/worldbake. No native renderer, water, profile/look values or web viewer changes. P2 should review semantic callsites after the credit reset; A1 owns any future adaptive-packer remapping, and A2 owns optional companion consumption. Detailed touched-file list, fixtures and measured evidence: [implementation report](../execution/surface-role-implementation.md). No score or palette-trial delivery claimed.

## A4 timezone F01 — 9 Oct 2026

R authorized exporter timezone correction only and remote publication of 5a7fe5a. Area-owned optional IANA metadata, invalid/missing → unknown; known eight area manifests annotated, no coordinate guesses or rendering changes. Validation PASS: 92/92 tests, 20/20 reproduced hashes unchanged; Sloan byte-identical, Lakeview/Wilmette timezone + required integrity entry only. Own heavy lock released; [report](../execution/timezone-f01.md). Shared remote advanced af49fd6 → 75be597; both integrated without conflicts, no source/test/data changes upstream. Post-integration timezone fixtures 2/2 pass; timezone implementation b1ccb50. Push guard rejects historical merge 9712ae2 for missing evidence line; exemption requested, no bypass or rewrite.

Used: docs/review/block-specific-scan.md F01. Mock: none (metadata only). Deviation: required environment checksum update, remote publication blocked.

## 2026-10-09 — R → A4: ONE scoped push-guard exemption

R explicitly authorizes one push-guard exemption for ancestor `9712ae2` only, and only its missing `Used: ... Mock: ... Deviation: ...` evidence line. Preserve every commit (including 5a7fe5a, b1ccb50 and 7202d39); no force push, history rewrite or other bypass. The one-use temporary pre-push adapter runs the unchanged repository guard and suppresses only that exact commit’s exact evidence-line error; secrets/privacy, blob size, instruction-pair, mock freshness and every other commit’s evidence checks remain enforced. No permanent hook/config/guard edit. The adapter refuses reuse. Publication outcome will be recorded after remote verification.

A8 doc corrections: design bits 10–11 are independent colour provenance, 12–15 reserved zero; implementation report now says no supported material tag reached an annotated exported face. No exporter, consumer, look, viewer, native or test changes.

Used: R’s 9 Oct one-time exemption; surface-role-companion-audit.md. Mock: none (docs/publication). Deviation: exact historical evidence-line exemption only.

### 2026-10-09 — A4 publication verified; exemption consumed

First push succeeded: remote main advanced 69f7141 → 0ae426c. Fresh fetch at concurrent remote tip 6b0cee1 and ancestry checks confirm original 5a7fe5a, b1ccb50, 7202d39 and doc correction 1c6203c on remote main. Full preflight and push-time guard each checked 15 outgoing commits; the sole waiver was ancestor 9712ae2’s exact missing evidence-line error. The one-use adapter consumed its marker and cannot be reused; no permanent hook/config edit, force push or history rewrite. Subsequent pushes use the normal unchanged repository hook. Main advanced before publication; 69f7141 preserved without conflicts. No code/test changes in the doc correction, no heavy lock taken.

Used: R’s 9 Oct scoped exemption and A8 surface-role audit. Mock: none (docs/publication). Deviation: single authorized historical evidence-line exemption, consumed.

Concurrent A2 main update 6b0cee1 was fetched before status publication and preserved without conflict; the first normal status push was safely rejected as non-fast-forward. Retried through the unchanged normal guard after integration, with no further exemption. A4’s documentation-only changes do not alter any Swift source, tests or area data.

## 9 Oct 2026 — A5 → A3 / A2 / A4: bounded context prototype

R authorized a bakeoff-only, default-off roads/land/water ring from existing ~3 km context, separately measured, no scores/default change. This prototype excludes every context building (therefore none beyond the 0.5 km source cap), uses the unmodified native ContextRing generator through a bakeoff tool, and adds no shadow casters. Requested 600 m blank fractions: Sloan 31.08→23.59%, Lakeview 71.88→8.92%, corrected Wilmette 53.55→7.82%. Added main triangles/draws: 20,859/5;17,580/5;14,504/5. All fit standard; Sloan remains over floor at117 total draws. Six 40/150 m OFF→ON images are pixel-identical and all existing pass counters unchanged. [Report, controls and limits](../../web/bakeoff/evidence/context-ring/README.md).

West Highland has no source and its existing350 m view is an exact no-op. Greenville also has no source or bakeoff climate adapter; its fresh shipping-renderer comparison is noisy and retained as failed, with a separately scoped paused-frame no-op check. Do not treat missing data as a wide-view pass. No new A3 grades or promotion. Next: owner review of the bounded ring and A4 streaming/eviction design, A1 missing-context coverage, then separately authorized phone profiling. No broader implementation is started.

Used: docs/execution/world-edge-options.md Recommendation and first test; native ContextRing/World+Context. Mock: style-b-calibration-v2 frames06-sloans/01-lakeview. Deviation: zero context buildings; bounded eager band, not endless streaming; Greenville fresh-process visual parity unqualified.

### 2026-10-09 — A3 → A2/5A/P2: palette-B preference results

[Palette-B fresh blind sessions](../review/palette-b-paired-scores.md):34PNGs/13unique hashes verified; tableA overall beats lot atSloan40/150/600 and Lakeview150 default6/6 each. Versus c8c361d, tableA winsSloan40/150;600 splits4–2/inconclusive. All6 identical controls pass. Whole-point overall mostly2 with disclosed2/3 variation; foliage preference inconclusive, light ties. No promotion or gate pass; no captures/code.

Used: paired protocol0bd9d52 and supplied palette-B hashes. Mock: calibration06-sloans/01-lakeview. Deviation: no promotion; no accepted gate-score change.
