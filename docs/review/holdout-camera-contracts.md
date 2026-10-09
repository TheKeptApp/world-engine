# Held-area camera contract audit — 9 October 2026

The retained Wilmette bakeoff ladder is mislabeled: its 45° annotation accompanies a resolved 3° camera. This is a tooling adapter error, not renderer behavior. `northshore-postcard` legitimately remains 3° for the native street hero. Only the aerial ladder overrides it to 45°. All original PNGs, native contracts and earlier scoreboard JSON remain untouched.

Reproduce the read-only audit with `node scripts/audit_camera_contracts.mjs`. [Full measured rows](holdout-camera-audit.json) include 24 shipping-module scoreboard views, 22 retained bakeoff ladder frames and three saved non-ladder web cameras. [Archived retained camera metadata](holdout-camera-retained.json) preserves A10's original paths and PNG hashes without requiring its local reports to rerun the audit. Headings use clockwise north; positive pitch means down; height is scene y above the existing flat ground. Numeric mismatches use 0.001°/m for auditing; the runtime ladder rejection is strictly more than 2° from both the annotation and the shared 45° contract.

| Held area | Scoreboard annotation pitch / heading / FOV / heights | Resolved scoreboard pose | Other retained contract |
|---|---|---|---|
| Evanston South | 45 / 270 / 50 / 40,150,600 m | matches all four fields | no retained web ladder |
| Greenville Downtown | 45 / 270 / 50 / 40,150,600 m | matches all four fields | no retained web ladder |
| Kenilworth Station | 45 / 270 / 50 / 40,150,600 m | matches all four fields | no retained web ladder |
| Lakeview | 45 / 270 / 50 / 40,150,600 m | matches all four fields | retained bakeoff ladder also matches; saved street pair is not a ladder |
| Sloan's Lake | 45 / 270 / 50 / 40,150,600 m | matches all four fields | all 16 post-near-fix bakeoff frames match; saved street pair is not a ladder |
| West Highland | 45 / 270 / 50 / 40,150,600 m | matches all four fields | separate frozen 350 m aerial: pitch37.868 / heading0 / FOV47, eye-target-defined, no 45° claim |
| Wilmette | 45 / 270 / 50 / 40,150,600 m | matches all four fields | **bakeoff ladder mismatches below**; different retained eye/heading/date from scoreboard |
| Winnetka Village Green | 45 / 270 / 50 / 40,150,600 m | matches all four fields | no retained web ladder |

## Mismatches and correction

| Wilmette height | Annotation pitch / heading / FOV / height | Old resolved pitch / heading / FOV / height | New contract |
|---|---|---|---|
| 40 m | 45 / 90 / 50 / 40 | 3.000000002 / 90.002342724 / 50 / 40 | 45 / 90 / 50 / 40 |
| 150 m | 45 / 90 / 50 / 150 | 3.000000002 / 90.002342724 / 50 / 150 | 45 / 90 / 50 / 150 |
| 600 m | 45 / 90 / 50 / 600 | 3.000000002 / 90.002342724 / 50 / 600 | 45 / 90 / 50 / 600 |

The corrected ladder retains eye **42.074933,-87.719996**, heading90, FOV50, September15 `2026-09-15T19:56:00Z`, viewport1005×565 and the existing focus/margin recipe. Targets are recomputed in the exported package's actual local frame, removing the small heading drift. No scene, look, exporter or native camera changes. Native hero/postcard poses and the saved pair are separate compositions, not ladder contracts; their differing pitches are preserved.

Old frames: `/private/tmp/a10-qual-wilmette-off/wilmette-{40,150,600}-foliage-off-crown-off.png` and corresponding ON qualification frames remain pre-camera-correction evidence, not comparable to the replacement ladder. New frames: `docs/lookloop/captures/a7-holdout-camera-fix/wilmette-{40,150,600}-foliage-off-crown-off.png`. The earlier A7 retained baseline is likewise historical; nothing is overwritten. Changing this camera invalidates transferring its old 600 m budget result to the corrected ladder. The scoreboard's centre-based Wilmette views remain a distinct, valid contract.

## Verification

Capture command: `HEAVY_AGENT='A7 corrected Wilmette ladder' scripts/capture-web.sh --block wilmette --screen --output NEW_OUTPUT_DIRECTORY`. The command owns heavy admission; do not nest it. `--screen` records separate main/shadow budgets and the same 81×45 structural blank-ground probe used by the scoreboard (blank >35% fails; instance occlusion excluded, upper bound). PNG size/non-flat checks remain independent. Tests reject historical 3° resolution, accept inclusive 43°/47° boundaries and reject drift beyond them; the real scoreboard and capture workers invoke this resolved-pose guard before accepting a frame.

Only Wilmette was recaptured, all three views first-attempt. Capture workload **139.216 s**, admitted at load **21.88**, after 210 s waiting for load; its lock released at exit0. [Replacement manifest](../lookloop/captures/a7-holdout-camera-fix/manifest.json) records measured pitch45.00000000007°, heading89.99999999942°, FOV50 and exact40/150/600 m. All three PNGs pass dimensions/non-flat; no score assigned.

| Height | Main tris / draws | Shadow tris / draws | Floor / standard | Blank fraction (>35% fails) |
|---|---:|---:|---|---:|
| 40 m | 574,352 / 225 | 68,059 / 47 | FAIL / FAIL | 3.6488% PASS |
| 150 m | 624,169 / 246 | 66,723 / 38 | FAIL / FAIL | 3.7586% PASS |
| 600 m | 605,666 / 297 | 5,918 / 1 | FAIL / FAIL | 53.5528% FAIL |

All 49 regression tests (32 Node +17 Python) passed under heavy admission at load5.48; both owned locks released.

The old 600 m 43,549/12 budget result was for the erroneous nearly-horizontal view. It does not describe the corrected 45° ladder. These results are bakeoff submissions with the retained September fixture/focus; they do not replace shipping-module scoreboard centre-based measurements. Renderer/exporter/look files are unchanged.

Used: world-scoreboard.md §Renderer and frozen ladder; scene-budget-qualification.md §Hold-outs; a3-capture-contract.json Wilmette. Mock: retained A10 Wilmette OFF frames and style-b-calibration-v2/01-lakeview. Deviation: correct a mislabeled tooling camera; existing non-ladder/native cameras preserved.
