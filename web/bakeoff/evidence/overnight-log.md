# A2 overnight — 2026-10-08

Scope: `web/bakeoff/` only. Same exported geometry, source cameras, shared rules and fixed calibration-v2 boxes. Sloan always precedes untuned Lakeview; each capture freezes renderer/data/export/mock hashes. Lower mean ΔE76 is better. The boxes are surface-class samples, not image registration or an iOS parity grade.

Start: b012b71; Sloan 16.609379, Lakeview 22.258022. Preserved in `overnight/00-start/`.
Rollback gate: compare each candidate with the last accepted stage; if Sloan improves and Lakeview worsens, retain rejected evidence, restore only this step's implementation, and capture the restored state. No scene-specific rescue adjustments.
Atmosphere: approved `haze-visibility-v1/regions[front-range].seasons.summer.clear`, `regions[great-lakes].seasons.summer.clear`, `airlight.stateDayHex.clear`, `airlight.timeMix.day`, `integration.applyOnce`, `mountains` contrast/height/cloud gates. Trees' date-driven calendar prior is independent of these explicitly requested summer-clear atmosphere fixtures.
Disk guard: 83 GiB available before the first heavy capture (>8 GB). All capture/build verification uses `scripts/heavy.sh`; no other lane's lock is altered.

## 01-haze — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 16.609379 (+0.000000), lakeview ΔE76 22.258022 (+0.000000).
Visual: Low pale real DEM ridge visible west of the shore; haze unchanged from approved prior round. Sloan still has regular water bands; Lakeview keeps the same pale crowns.
Evidence: `overnight/01-haze/`; Hold-out rollback condition did not trigger.

## 02-trees — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 16.609379 (+0.000000), lakeview ΔE76 22.258022 (+0.000000).
Visual: P2 species forms and branches replace angular generic crowns; October calendar prior turns foliage gold. Lakeview still has coarse near lobes. Fixed-box medians are unchanged: Sloan has no crown box, and Lakeview green-mask medians do not reflect the yellow crown change.
Evidence: `overnight/02-trees/`; Hold-out rollback condition did not trigger.

## 03-light — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 19.668067 (+3.058688), lakeview ΔE76 22.283344 (+0.025322).
Visual: Hue-preserving light keeps blue sky and reduces cyan on the lake, but sampled foreground grass diverges further from the mock sidewalk. Lakeview walls become too pale; its crown mask now has too few green pixels (5/6 regions scored), so mean comparisons have reduced coverage.
Evidence: `overnight/03-light/`; Hold-out rollback condition did not trigger.

## 04-water — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 19.668067 (+0.000000), lakeview ΔE76 22.283344 (+0.000000).
Visual: Old crossed-sine bands reduced and 8-bit shore quantization removed; smaller irregular ripples and a continuous shore gradient remain, with restrained sky reflection. Water is still too cyan/flat relative to the mock. Fixed ΔE unchanged because neither view has a water region; Lakeview pixels unchanged.
Evidence: `overnight/04-water/`; Hold-out rollback condition did not trigger.

## 05-facades — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 19.668067 (+0.000000), lakeview ΔE76 22.283344 (+0.000000).
Visual: Pack detail appears on eligible distant frontages, but the dominant near side walls remain unchanged because their exported family is outside the four pack families. No camera-driven family reassignment. The new geometry does not move the fixed-box medians.
Evidence: `overnight/05-facades/`; Hold-out rollback condition did not trigger.

Measurement caveat discovered during this round: Lakeview crown-mask coverage drops from 6/6 total scored regions to 5/6 at the light step; Sloan has only two regions and no water or mountain sample. The means cannot establish parity or quantify tree/water geometry improvements. Failed shader/data attempts were discarded; only complete frozen ordered pairs are archived. Corrected reruns retained the heavy lock after the first full 600-second load wait.

## 06-budget — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 19.668067 (+0.000000), lakeview ΔE76 22.283344 (+0.000000).
Visual: Same final images across hero/standard/floor; no appearance change from instrumentation. Low west-facing ridge persists. All-pass GPU time is measured, but both floor views exceed the shadow-triangle ceiling.
Evidence: `overnight/06-budget/`; Hold-out rollback condition did not trigger.

## Final assessment
All six ordered steps completed; no step triggered the specified Sloan-improves/Lakeview-worsens rollback. Both start-to-end colour means worsened: sloans 16.609379 → 19.668067, lakeview 22.258022 → 22.283344. Lakeview coverage changed from 6 to 5 regions; its apparent mean change understates the regression.
No claim of iOS parity or passing the look gate. Whole-frame GPU timing and every effect/pass are in LAPTOP-BUDGET.md; both floor views fail the 150k shadow ceiling. Main geometry/draw limits pass; no laptop/hero/standard or texture ceiling is invented. All three named tiers have byte-identical PNGs and unchanged frozen inputs.
Before/after: `sloans-overnight-before-after.png`, `lakeview-overnight-before-after.png`; current-vs-mock: `sloans-side-by-side.png`, `lakeview-side-by-side.png`.

## Next round — shadow and colour (2026-10-08)

R replaced ΔE with A3's visual scores as the grade; A3 review is pending. Sloan then untouched Lakeview captured with the same frozen code and all three tier labels. The general 120 m shadow-only caster range and tree LOD 2 bring both shadow passes below 150k; main geometry remains unchanged. Crowns now use individual calendar shifts, native regional autumn colours and lagged greens. The first full trial still showed bright cyan water; the shared neutral-witness/grade conversion was corrected and the entire pair repeated. Final visual note: Sloan water is muted blue-green and crowns are orange/yellow/green; Lakeview's foreground crown is green with yellower trees behind, while its plain facade gaps persist. No visual score or hold-out acceptance is inferred from those observations. Exact pass costs and uncovered export families are linked in SHADOW-COLOUR-REPORT.md.
