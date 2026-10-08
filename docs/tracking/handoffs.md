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
