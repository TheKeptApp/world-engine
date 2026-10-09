# Budget-aware American elm prototype

R's “CROWN: FIT STANDARD BUDGET + CLEAN BRANCH” authorizes this revision of `aa3a068`. Fresh branch `astra-a2-elm-budget` from main `855babe`; only web/bakeoff files carried across. No tracking files edited. Default remains off. Select `?crownV2=standard` (also `on` or bare flag) or `?crownV2=floor`; `off`/absent preserves the old renderer. Invalid values error. No captures, scores or GPU measurements.

## General allocation rule

Only American elm (`ulmus_americana`) uses the crown-silhouettes-v2 scaffold/layers. Start every elm at far detail, then upgrade nearest-first, with stable identity tie-breaking, to the pack's desired projected-size level. The complete loaded elm population gets a triangle allowance of floor(N×217) for standard, floor(N×75) for floor (R's requested targets); this includes offscreen trees, not only the camera's visible subset. No tree is removed, resized, repositioned or recoloured. Allocate no more than the allowance; report an error if minimum topology alone exceeds it. This is a crown allocation cap, not a universal guarantee for arbitrarily large non-elm worlds.

Near/middle retain the prototype's 24/9 branch-connected lobes. Far keeps three coarse fan masses, using octahedra rather than icosahedra: 66 triangles including scaffold, enough room under the floor average for selective upgrades. Four stable seed variants are instanced across cells rather than drawing each cell's variant separately. This reduces batch count without changing other content. As a consequence large batch bounds can submit offscreen elm instances; the CPU accounting includes those submissions. Shared light, exposure, saturation, date-derived colours, haze and other content are unchanged. Shadow selection remains the existing far LOD2 with the same 120 m reach in both scenes; no halving triggered or code changed.

`content.speciesByCity[American elm]`, `content.construction`, `lod` and panels 01/14/17–22 own shape direction. LOD thresholds 20/6 drawable pixels and 10% hysteresis remain desired-detail limits, not permission to exceed the allocation. Numeric branch interpolation and seeded variant pool are authored prototype mechanics in `foliage.js`, not measured pack coordinates. Existing foliage dimensions and trunk ratios supply scale. Opaque primary lobes are the allowed fallback; secondary clusters/cards remain absent. Full appearance fidelity is unproven, especially the far silhouette. This task does not implement execution/ao.md or alter default foliageExp1 shading.

## Crown costs

Fixture 2026-10-08; per crown including wood. A standalone crown takes one main draw and one in-range shadow draw; shared batches amortize draws. Near/middle/far triangles are **2,606 / 910 / 66**; shadow triangles are **66** at every main level under existing far-caster policy, zero outside reach. Deterministic four-seed costs are in `crowns.json`.

## Whole-scene CPU submission model

Same source loader, scene cameras, viewport, fixture, seasonal/species selection, façade and DEM geometry for all cases. Sloan's first, then Lakeview unchanged. Main counts include Three's 1,984-triangle background sphere and its draw. Post is separately one triangle/one draw in every case. Shadows are conservative pre-frustum upper bounds from the actual caster selection, not GPU counters. Main uses mesh/instance-batch frustum bounds; shader discard does not remove submitted topology. No frame time, GPU residency, pixel identity or visual grade is inferred.

| Scene / crown mode | Main triangles | Main draws | Shadow triangles upper bound | Shadow draws upper bound | Elm average triangles | Own tier gate |
|---|---:|---:|---:|---:|---:|---|
| Sloan OFF | 347,177 | 99 | 5,052 | 18 | legacy | floor PASS |
| Sloan standard | 489,507 | 101 | 5,206 | 21 | 216.11 | standard PASS |
| Sloan floor | 383,481 | 96 | 5,206 | 21 | 74.40 | floor PASS |
| Lakeview OFF | 265,310 | 81 | 67,190 | 81 | legacy | floor PASS |
| Lakeview standard | 303,842 | 83 | 67,300 | 84 | 215.62 | standard PASS |
| Lakeview floor | 275,968 | 80 | 67,300 | 84 | 73.85 | floor PASS |

Standard criterion: main ≤500k/120 draws, as R requests; floor: main <400k/≤100 draws. All cases also satisfy the stricter 150k shadow triangle ceiling. Main and shadow budgets are separate; do not compare sum-of-passes triangles against main-only ceiling. Post cost remains explicit above. Every-pass upper totals (triangles/draws), OFF/standard/floor: Sloan 352,230/118; 494,714/123; 388,688/118. Lakeview 332,501/163; 371,143/168; 343,269/165.

Sloan has 705 elms: standard near/middle/far 41/2/662; floor 2/1/702. Lakeview has 215: standard 12/2/201; floor 0/2/213. These are results of one nearest-first rule, not scene-specific settings. `scene-costs.json` records counters, input code/pack hashes, limits and LOD counts. Exports: `~/Desktop/world-engine/Generated/package/sloans-lake` and this checkout's `web/bakeoff/generated/lakeview-sheil-park`, as mounted by serve.mjs.

## Validation

Main advanced with documentation only to `1e5edfb`; rebase was conflict-free. Full post-rebase checks repeated at load 8.50 after A7 released the heavy lock; all six counts unchanged. Heavy admissions at loads 12.82, 10.08 and 8.50, disk guard ≥8 GB passed, own locks released. No browser/server/capture/score. Tests pass: 1,056 current-base default-off geometry cases plus material/instance identity; 1,056 pre-exp1 controls; excluded bush/conifer control graphs; seeded repeatability and variation; exact level triangle counts; stable nearest-first allocation and cap; actual pooled instance uniqueness/transforms/counts; repeated and moving-camera updates; six whole-scene tier assertions. Existing policy, overnight, atmosphere, sky-colour arithmetic and syntax/diff checks pass. CPU input identity is not GPU pixel readback.

Reproduce from repo root under `scripts/heavy.sh` and load <25 with `WORLDENGINE_ASSETS=~/Desktop/world-engine`: `node web/bakeoff/crown-v2.test.mjs` then `node web/bakeoff/crown-v2-cost.mjs`. The cost script reads local files only and creates no server/GPU context. A3 owns future captures and scoring; budget fit does not establish a shape improvement.

## Ledger text for A3

A2 web foliage shape: partial, American elm only, default-off crownV2 standard/floor. Consumer `main.js` → `foliage.js` (`buildElmV2`, `allocateCrownBudget`, pooled instancing); target crown-silhouettes-v2 approved by R. Implementation revision: commit introducing this report on `astra-a2-elm-budget`; control `855babe`, supersedes unmerged `aa3a068`. Both scenes fit their requested CPU tier criteria with unchanged shadow reach. Default-off identity and allocation tests pass; GPU counts/pixels, secondary details, hold-out appearance and A3 grade remain pending. Current capture/scoring status unchanged. No INTEGRATION/STATE edits made per R's explicit routing instruction.

Used: crown-silhouettes-v2 §content.speciesByCity/content.construction/lod; R's 217/75 nearest-first budget decision; foliage-exp1-spec §Approved native eligibility amendment. Mock: panels 01/14/17–22, images/03-lobe-construction.png and 04-distance-fade.png. Deviation: budget-limited detail and opaque coarse far fallback; CPU costs only, no captures/scores.
