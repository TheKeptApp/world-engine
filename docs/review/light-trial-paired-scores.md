# Light trial — blind paired scoring, 9 October 2026

**No promotion or gate pass.** ON is preferred for light, materials and overall at Sloan 40/150 m,6/6 each. Sloan 600 m ties on every requested aspect. Lakeview 150 m overall ties6/6; light/materials each split2ON/4ties and are inconclusive. Saturation ties6/6 at every view. Whole-point scores show **no OFF→ON movement** in any session: the paired method detects a small close-view preference within the same score band.

## Evidence and matched controls

A2's [light-trial README](../../web/bakeoff/evidence/light-trial/README.md) records default-off implementation 421b408 and validation 9a6eb0e. The trial combines a shadow-filter change with experimental lower-hemisphere fill; this review cannot attribute its preference separately to either mechanism. Palette/crowns remain OFF. Existing budget overages, shadow reach and caster selection are unchanged. No native/device qualification is inferred from laptop capture timings.

Coordinator verified SHA-256 for all 16 original fresh/repeat files and four post-merge Lakeview files. Eight opaque fresh images supplied in A2's `blind/` folder match their recorded hashes. OFF/ON agree in requested/resolved capture metadata checked by the [identity audit](light-trial-scoring/identity-audit.json): camera, inspection/date, fixture, projection, exposure, crown/palette settings and every per-pass triangle/draw count. All eight mode/view fresh-repeat pairs are byte-identical. The post-merge Lakeview hashes match the originals.

Historical control equality is **world RGB below row 32**, not full-PNG equality: the top 32 credits rows differ and are excluded under R's documented gate. No pixels were excluded from the visual review panels. Sloan 40/150/600 use their matching c8c361d controls. Lakeview 150 uses its saved palette-trial150 m default, not c8c361d's600 m view; the additional600 m identity proof is separate and not scored in this trial. Local original PNGs remain in `/private/tmp/worldengine-a2-bakeoff/web/bakeoff/evidence/light-trial/`; unchanged neutral copies and panels remain in `/private/tmp/a3-light-blind/`.

## Fresh-session method

Three new reviewer sessions inherited **no conversation history, implementation identity, manifest or previous grades**. Coordinator alone read those files to prepare and verify pairing. Each reviewer received eight shuffled neutral source copies, a §M rubric and the same calibration references (06-sloans and01-lakeview). Each locked its whole-point grades before opening ten shuffled spatial panels: four matched pairs in both left/right arrangements, plus two hidden identical-image controls. Panels preserve source pixels and scale, with labels/gutter outside the image; no crop, recolouring or masking. The key stayed separate from reviewers until all outputs were locked.

This follows the [paired protocol 0bd9d52](paired-preference-protocol.md): six judgments per view across three sessions, three ON-left and three ON-right, and no adjacent repeated pair. All **six identical-image controls pass** on every requested aspect and roof-answer consistency. Every6/6 directional win splits 3 left / 3 right. Lakeview's two ON votes split 1 left / 1 right, from one reviewer; other sessions tie. No positional reversal is hidden. Reviewers recognized repeated compositions within their session but reported no known treatment identity. These are fresh contexts of the same model family, not six independent people; consistency is not statistical significance.

[Raw results](light-trial-scoring/results.json), [separate key](light-trial-scoring/blind-key.json), and session [1](light-trial-scoring/session-1-preferences.json), [2](light-trial-scoring/session-2-preferences.json), [3](light-trial-scoring/session-3-preferences.json) retain every judgment/reason, including ties. Whole-point records are separately locked in the corresponding `session-N-grades.json` files. Sky is **N/A**; this task reports light, saturation, materials and overall only. No new captures, render edits or ΔE grading.

## Per-aspect result

Counts are **OFF wins / ON wins / ties**, out of 6. Grades are **session 1/session 2/session 3**, not a mean. A preference needs ≥5/6 and ≥2/3 in each position with controls passed;2ON/4ties is inconclusive, not a majority tie or a demonstrated gain.

| View | Aspect | OFF / ON / tie | OFF grades | ON grades | Conclusion |
|---|---|---|---|---|---|
| sloans-40 | light | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-40 | saturation | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 | materials | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-40 | overall | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-150 | light | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-150 | saturation | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 | materials | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-150 | overall | 0/6/0 | 2/2/2 | 2/2/2 | on preferred |
| sloans-600 | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 | saturation | 0/0/6 | 2/3/3 | 2/3/3 | repeatable tie |
| sloans-600 | materials | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 | overall | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| Lakeview 150 m | light | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| Lakeview 150 m | saturation | 0/0/6 | 3/3/3 | 3/3/3 | repeatable tie |
| Lakeview 150 m | materials | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| Lakeview 150 m | overall | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |

## What changed perceptually, and what did not

**Light:** at 40/150 m the reviewers consistently see slightly deeper shaded crown faces/undersides and more convincing form. They do not claim that this establishes correct physical bounce or approves the experimental use of the AO floor. At600 m there is no defensible preference; at Lakeview the change is too slight for cross-session agreement.

**Materials:** close Sloan crowns read a little less flat through tonal depth. This is a perceived material benefit from the bundled light treatment, not evidence of new material assets. Buildings and ground remain schematic, and rounded/faceted tree blobs remain. Lakeview's2ON/4ties and Sloan 600's6ties do not support a general material improvement across all views.

**Saturation:** all 6/6 ties. The bright autumn pigment and conspicuous orange roofs remain. A deeper shaded face is not automatically a saturation improvement. **Overall:** Sloan 40/150 gain a small paired preference, while Sloan 600 and Lakeview 150 tie; nothing reaches a new whole-point overall band.

All whole-point light/materials/overall scores remain 2/5 in every image and session. Lakeview saturation remains 3/5 OFF and ON; Sloan 600 saturation is 2/3/3 on both sides; Sloan 40/150 saturation stays 2/5. These absolute differences among sessions are grader variation, not treatment movement. The **whole-point scale cannot see the small OFF→ON preference here**, even though balanced pairs can. Historical grades and gate state are unchanged.

The untuned Lakeview overall tie supplies no evidence of a hold-out loss, but also no hold-out gain. Other hold-outs and motion remain untested. No promotion, default change, floor pass or look-gate pass is claimed.

## Next authorized scoring scope

A3 stands by for A4/A5 far-geometry600 m frames once delivered with matched controls and hashes: same paired protocol, three fresh sessions, spatial randomization, identical-image controls/repeats, whole-point grades alongside. No far-geometry frames were scored here; no unattended polling or auto-merge is scheduled.

Used: GRADING.md §M, paired-preference-protocol.md0bd9d52, A2 light-trial README/manifest and verified blind hashes. Mock: calibration-v2/frames/06-sloans.png and01-lakeview.png. Deviation: none from requested review method; same-model repeated judgments remain correlated; no promotion.
