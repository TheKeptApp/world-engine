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
