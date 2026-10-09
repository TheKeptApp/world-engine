# A3 blind web crown ladder review — 8 October 2026

**Result: no foliage 3/5 at 40 m AND 150 m for standard or floor. Every captured ladder view exceeds its applicable main geometry/draw budget.** This is a failed crown acceptance result, not a hold-out or four-hero pass. Captures are real web renderer screenshots, not mock panels; provenance checks are described below. No code changed and no capture/build run by A3.

## Method and locked grades

Read STATE and GRADING.md first. Use the same §M overall/six-aspect rubric as the native BEFORE filing carried by `bce13d6`, with §S rich-stylized and §V seasonal interpretation; ΔE is not a grade. Target: `docs/proposals/style-b-calibration-v2/frames/06-sloans.png`. Do not score exact street layout, wall hue or missing photographic leaf/brick detail. Appropriate October orange/yellow is not penalized merely for differing from the mock’s summer green.

All 18 source PNGs were copied byte-for-byte into `/private/tmp/a3-web-crown-blind/frame-01.png` … `frame-18.png`, shuffled with system randomness. The source key was written separately and neither the key nor manifest.json was opened until all grades/reasons were locked. STATE was read as requested and contained aggregate delivery facts, but no neutral-label mapping. Height and season are visually inferable; mode/build identity remained concealed. No per-frame metadata was read before locking. [Locked scores](crown-web-ladder-blind-scores.json) retain the timestamp and neutral names; [separate unblinding key](crown-web-ladder-blind-key.json) records source hashes, manifest hash and capture revision.

**Sky is N/A in every downward view**, matching bce13d6’s treatment of unseen sky; assigning a 1–5 sky grade would invent evidence. All assessable scores are 1–5. Overall is a visual judgment, not an arithmetic mean. Ground/materials fall to 1 in the high-altitude images because broad rectangular bands and fine striping destroy the coherent lake/ground surface appearance; foliage remains independently 2. This is an observed artifact, not a diagnosis of which render mechanism caused it.

| Blind frame | Sky | Light | Saturation | Ground | Foliage | Materials | Overall | Locked one-line reason |
|---|---|---|---|---|---|---|---|---|
| frame-01 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Some crowns have finer lobes, but dominant orange masses remain smooth balloons or sharp polygons; flat ground and hard shadow edges limit depth. |
| frame-02 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | Rectangular green bands and striping break the lake surface; tiny angular crowns and flat surrounding land lack calibrated depth. |
| frame-03 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | A few clustered crowns add variation, but the canopy still reads as repeated angular chips above flat lawns and simple roofs. |
| frame-04 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | Large rectangular interruptions and striping dominate the lake; foliage remains small simplified flecks with little volumetric depth. |
| frame-05 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Green crowns fit the summer reference family, but large lobes remain balloon-like or faceted and the lawns/materials stay flat. |
| frame-06 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Broad orange/yellow crown chips and planar ground dominate; simplified material response and rigid shadow boundaries remain distant from the target. |
| frame-07 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | The lake is visibly fragmented by green rectangles and stripes; distant vegetation stays simplified rather than demonstrating richer crown form. |
| frame-08 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Near crowns combine smooth round clumps with sharply faceted upper masses; weak lobe contact shading and flat surfaces keep closeness low. |
| frame-09 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Several trees have more articulated clusters, but most canopy masses remain coarse and shading/material depth is limited. |
| frame-10 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Repeated angular autumn crowns and largely uniform planar surfaces dominate; small crown differences do not restore natural massing. |
| frame-11 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | Green rectangular interruptions and fine stripes break continuous water response; the landscape and distant crowns remain schematic. |
| frame-12 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Large round clumps and pointed planar crowns persist together; hard shadows and simple lawns lack the target’s layered response. |
| frame-13 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Some green crowns show lobes and scaffold openings, but foreground balloon masses, angular neighbours and weak contact depth still dominate. |
| frame-14 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | The canopy remains dominated by orange polygonal masses; flat lawns and simple material response outweigh isolated crown detail. |
| frame-15 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | The greener canopy changes the palette but not the broken rectangular/striped lake or the flat landscape response. |
| frame-16 | N/A | 2 | 2 | 1 | 2 | 1 | 1 | Small green crown flecks are present, but lake rectangles/stripes and weak ground/material depth dominate overall wrongness. |
| frame-17 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Greener clustered crowns offer some variety, yet large planar crown families and uniform ground keep the rich-stylized target unmet. |
| frame-18 | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Some crowns have dense lobes and branch openings, but large smooth orange balloons and hard planar neighbours still dominate the scene. |

## Unblinded table

Delivery `2fba43a`; renderer capture revision `fd99b9d5ad76217ce6c0f210d1f89f808c8637e0`, including A2 runtime fix `3a63b3a`. Dates below are 2026; heights are metres above the export’s explicit flat-ground datum. Click the source for the unchanged render. All use foliageExp1 OFF; crown modes are separate.

| Frame | Source | Crown mode / control | Date | Height | Foliage | Overall |
|---|---|---|---|---|---|---|
| frame-01 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-40-foliage-off-crown-floor.png) | FLOOR | 2026-10-15 | 40 | 2 | 2 |
| frame-02 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-600-foliage-off-crown-standard.png) | STANDARD | 2026-10-15 | 600 | 2 | 1 |
| frame-03 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-150-foliage-off-crown-standard.png) | STANDARD | 2026-10-15 | 150 | 2 | 2 |
| frame-04 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-600-foliage-off-crown-off-repeat.png) | OFF repeat | 2026-10-15 | 600 | 2 | 1 |
| frame-05 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-40-foliage-off-crown-off.png) | OFF fresh | 2026-07-15 | 40 | 2 | 2 |
| frame-06 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-150-foliage-off-crown-off-fresh.png) | OFF fresh | 2026-10-15 | 150 | 2 | 2 |
| frame-07 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-600-foliage-off-crown-floor.png) | FLOOR | 2026-10-15 | 600 | 2 | 1 |
| frame-08 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-40-foliage-off-crown-off-fresh.png) | OFF fresh | 2026-10-15 | 40 | 2 | 2 |
| frame-09 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-150-foliage-off-crown-off.png) | OFF fresh | 2026-07-15 | 150 | 2 | 2 |
| frame-10 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-150-foliage-off-crown-off-repeat.png) | OFF repeat | 2026-10-15 | 150 | 2 | 2 |
| frame-11 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-600-foliage-off-crown-off-fresh.png) | OFF fresh | 2026-10-15 | 600 | 2 | 1 |
| frame-12 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-40-foliage-off-crown-off-repeat.png) | OFF repeat | 2026-10-15 | 40 | 2 | 2 |
| frame-13 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-40-foliage-off-crown-standard.png) | STANDARD | 2026-07-15 | 40 | 2 | 2 |
| frame-14 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-150-foliage-off-crown-floor.png) | FLOOR | 2026-10-15 | 150 | 2 | 2 |
| frame-15 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-600-foliage-off-crown-off.png) | OFF fresh | 2026-07-15 | 600 | 2 | 1 |
| frame-16 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-600-foliage-off-crown-standard.png) | STANDARD | 2026-07-15 | 600 | 2 | 1 |
| frame-17 | [PNG](../lookloop/captures/a7-web-crown-ladder/jul-sloans-150-foliage-off-crown-standard.png) | STANDARD | 2026-07-15 | 150 | 2 | 2 |
| frame-18 | [PNG](../lookloop/captures/a7-web-crown-ladder/oct-sloans-40-foliage-off-crown-standard.png) | STANDARD | 2026-10-15 | 40 | 2 | 2 |

## Answers and visual limits

- **Standard: NO. Floor: NO.** October OFF, standard and floor each score foliage 2 at 40 and 150 m; July OFF and standard also score 2. July floor was not supplied and is not inferred. Added elm lobes/scaffold are visible in parts of the candidate frames, but the scene remains dominated by coarse angular or balloon-like crowns, weak contact depth, flat surfaces and rigid shadow edges. An improved individual tree is not a scene-wide foliage 3.
- **October versus July:** palette visibly changes from orange/yellow to green, but no whole-point aspect or overall grade changes for OFF or standard at matched heights. Both dates use the same fixed web calibration exposure and summer-clear atmosphere; date drives authored calendar phenology, not astronomical sunlight. This is a web date replay comparison, not the earlier native auto-versus-pinned exposure comparison or evidence of real seasonal observations. No gate-date change.
- Overall remains **2 at 40/150 m**, numerically the same as the historical saved web pair; that saved street-camera pair is not a controlled before/after for these ladder cameras. **All six 600 m frames score overall 1**, ground/materials 1, foliage 2: the lake bands/striping occur in OFF and candidates, including both exact OFF repeats. They are not a crown-specific regression or evidence of new trouble relative to an unmeasured pre-ladder state. Cause is unresolved; no water fix was attempted.
- All three October OFF fresh/repeat pairs received identical grade vectors. Their PNG hashes are equal within each pair, and A7 reports zero encoded and decoded byte differences. October standard and floor at 600 m are also PNG-identical. This supports stable repeated grading here, not a universal zero-noise claim.
- No candidate-specific whole-point aspect drop is observed within a matched date/height. No hold-outs were captured/scored here, so the focus-gain/hold-out-loss reject rule remains unevaluated. The focus foliage criterion and budgets already fail; no promotion/clearance is supported.

## Manifest triangle/draw accounting

All values below come from [A7 manifest](../lookloop/captures/a7-web-crown-ladder/manifest.json), not the older saved-camera CPU report. Each cell is **triangles / draws**. July OFF/standard counts exactly equal October at the corresponding mode/height; all October OFF repeats equal fresh, so these nine rows cover all 18 frames. Main + shadow + post sums were independently checked against all-pass totals for every frame. Post is **1 / 1** throughout.

| Crown mode | Height | Dates / controls covered | Main tris / draws | Shadow tris / draws | All-pass tris / draws | Geometry/draw verdict |
|---|---|---|---|---|---|---|
| OFF | 40 | Oct fresh+repeat; July fresh | 729,101 / 182 | 69,639 / 62 | 798,741 / 245 | FAIL main triangles + draws |
| OFF | 150 | Oct fresh+repeat; July fresh | 791,795 / 251 | 67,961 / 42 | 859,757 / 294 | FAIL main triangles + draws |
| OFF | 600 | Oct fresh+repeat; July fresh | 624,433 / 292 | 0 / 0 | 624,434 / 293 | FAIL main triangles + draws |
| STANDARD | 40 | Oct + July | 854,677 / 179 | 70,497 / 61 | 925,175 / 241 | FAIL main triangles + draws |
| STANDARD | 150 | Oct + July | 916,331 / 246 | 68,907 / 42 | 985,239 / 289 | FAIL main triangles + draws |
| STANDARD | 600 | Oct + July | 757,707 / 284 | 0 / 0 | 757,708 / 285 | FAIL main triangles + draws |
| FLOOR | 40 | Oct only | 756,593 / 178 | 70,497 / 61 | 827,091 / 240 | FAIL main triangles + draws |
| FLOOR | 150 | Oct only | 811,215 / 241 | 68,907 / 42 | 880,123 / 284 | FAIL main triangles + draws |
| FLOOR | 600 | Oct only | 650,901 / 280 | 0 / 0 | 650,902 / 281 | FAIL main triangles + draws |

**Cannot confirm within-tier: all fail.** Standard/OFF viewer comparison is main ≤500,000 triangles / ≤120 draws; the crown FLOOR target is strictly <400,000 / ≤100. Floor captures still used `viewerTier=standard`: crown allocation state is not a whole-view tier switch. They fail even the looser standard limits. Maximum measured shadow triangles are 70,497, below the stricter 150,000 floor cap (and provisional standard 180,000); that partial pass cannot offset main failures. Reported shadow zero at 600 m is a recorded counter, not proof of correct shadow visibility. All-pass draws are listed separately and never substituted for main draws. Limits: [device-tiers-v1 §2](../perf/device-tiers-v1.md), strict floor boundary and [A2 runtime accounting](../../web/bakeoff/evidence/crown-v2/RUNTIME.md).

The allocation allowance covers elm geometry, not the whole scene. Subtracting `main/foliage` from main totals gives non-foliage alone **529,108 / 117 draws at 40 m; 570,468 / 166 at 150 m; 473,923 / 198 at 600 m**. Thus crown detail reduction alone cannot establish the requested whole-scene floor. This arithmetic is not authorization to remove other content. The older A2 saved-camera standard 489,507/101 and floor 383,481/96 passed there; they do not describe these wider ladder submissions. No phone FPS, thermal, memory or residency qualification is implied.

## Real-render provenance

**Confirmed from supplied capture evidence and inspected capture path: these are rendered WebGL2 canvas screenshots, not calibration/mock panels.** A7 records Chromium/Playwright, stable renderer updates, requested/resolved camera, modes, pass ledgers and per-frame SHA-256. All 18 PNG hashes match the manifest and neutral copies; four declared source hashes match `git show fd99b9d:<path>`; none is the calibration PNG. The capture worker navigates the live scene page, waits for `window.bakeoff` metrics/readiness, freezes the running scene, calls WebGL `finish()`, then takes `page.screenshot`. `sloans.html` supplies canvas `#c`; main.js renders scene/post-processing into that canvas. The mock is an aside link, not the displayed scene. Visible geometry, attribution strip and mode/date changes agree with that path. A3 did not witness or rerun the original browser session; this is provenance verification of delivered renders, not an independent recapture or proof that the rendered lake is correct.

Freeze facts: 1005×565, DPR 1; eye 39.7511195,-105.0389, heading 270°, pitch down 45°, FOV 50°; heights 40/150/600 m; fixed exposure relative EV 0.35 / linear gain 1.2745606273192622, contrast 1.06, saturation 1.08; summer-clear/day, wind 10 km/h from 225°. Calendar dates October/July 15, full requested 20:30 UTC metadata. These differ from native weather/exposure contracts; no native gain is inferred.

Used: GRADING.md §M/§S/§V/§N; 2fba43a manifest; crown-v2/RUNTIME.md; device-tiers-v1 §2. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: sky N/A; no July floor or hold-outs; failed whole-scene budgets and shared 600 m lake artifacts.
Tracker update:
