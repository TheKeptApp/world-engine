# Default-off light trial

R requested 9 October 2026: light only, no caster-selection edits. Entry: `?lightTrial=on`; absent/`off` retain the prior render path, invalid modes fail. Crown and palette remain off in the comparison. Target views: Sloan 40/150/600 m and unchanged Lakeview 150 m. A3 scores; this report claims no score.

Rule: sample the existing shadow map over calibration-v2 `sharedLook.lighting.shadow.filterDrawablePx[1]` = 2 drawable pixels, using a 4×4 equal-area grid and shadow-UV derivatives; retain the existing 16 depth comparisons of three.js PCFSoftShadowFilter. Lower-hemisphere fill is existing sky fill × `ambientVisibilityFloor` = 0.65, upper fill unchanged. This lower-bounce interpretation is **experimental**, not an approved physical meaning of the AO floor. Horizontal neutral witness remains 0.62. No extra light, shadow/colour pass or map allocation; per-fragment derivative/arithmetic cost is measured through capture timing, not assumed free. No geometry, caster, reach, bias, grade or palette changes. Existing overages remain existing overages.

Controls: exact world RGB max/mean 0/0 against c8c361d for its matching saved Sloan views, excluding credit rows 0–31 by R's approved gate. Lakeview 150 m has no historical c8c361d control; use the saved palette-trial default pair at that pose, whose source identity traces c8c361d, and separately verify Lakeview 600 m against its actual c8c361d control. Keep these distinct.

## Ledger text for A3

Captures complete; tests and merge tracked below. Judge blind matched OFF/ON pairs and untuned Lakeview, not a self-reported aspect score. Calibration references: style-b-calibration-v2/frames/06-sloans.png and 01-lakeview.png. Used: calibration-v2 sharedLook.lighting and R light-trial instruction. Deviation: lower-hemisphere interpretation is a trial; no score or promotion.

## Measured evidence

All 16 requested frames (fresh/repeat OFF/ON at four views) pass input and per-pass coverage equality; all historical matching controls have world max/mean 0/0. Lakeview 150 matches the saved unchanged 150 m default exactly; additional Lakeview 600 capture matches c8c361d exactly. `manifest.json` contains every pass, raw timers and exact comparisons; `blind/` holds eight opaque-labelled fresh PNGs, with `blind-key.json` for the scoring coordinator only. No images or scores are committed.

| View | Main tris/draws OFF = ON | Shadow tris/draws OFF = ON | GPU mean ms OFF → ON (fresh) |
|---|---:|---:|---:|
| sloans-40 | 729,101/182 | 69,639/62 | 2.686 → 2.707 |
| sloans-150 | 791,795/251 | 67,961/42 | 2.691 → 3.016 |
| sloans-600 | 624,433/292 | 0/0 | 2.663 → 2.848 |
| lakeview | 323,901/131 | 73,212/62 | 2.896 → 2.186 |

One post pass adds one triangle/draw in every view. Existing main-budget overages are unchanged (standard ≤500k main /180k shadow /120 main draws). Timers are whole-frame laptop observations, not isolated filter timings or phone qualification; no budget was raised. Shadow caster source bytes equal starting main.
