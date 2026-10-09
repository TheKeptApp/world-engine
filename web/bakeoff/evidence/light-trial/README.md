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

Regression admission load 5.28: light source identity/witness/filter assertions, portable companion checks, palette identity, policy/atmosphere/sky/overnight, 1,056 legacy geometry/material identity cases, crown v2/v3 (228 v3 cases), and 16 capture-tooling tests all passed. Main advanced with documentation only and was rebased without conflict. Actual A8 package validation and the post-merge Lakeview check are recorded in the completion note.

Production reader: 61 checks passed at admitted load 8.75, including actual Sloan/Lakeview A8 packages and actual incompatible repack. Default-off light/role hooks preserve the control source after removing only explicit opt-in plumbing. Ready for A3 blind review; no score or promotion.

## Completion / post-merge hold-out

Merged default-off implementation `421b408` and validation `9a6eb0e`; main advanced with A5 opt-in context work, retained without changes to the captured render path. Post-merge Lakeview 150 OFF/ON fresh/repeats passed through scripts/capture-web.sh at admitted loads 5.65/6.82, each releasing its own lock. All four frames have world max/mean 0/0 versus their pre-merge counterparts and identical per-pass triangles/draws. PNG repeats within each mode are byte-identical. `manifest.json/postMergeHoldout` records paths/hashes and exact comparisons. A3 blind scoring is next; no scores or promotion claimed.

Touched: light module/main opt-in hooks; capture query/metadata plumbing; production companion reader; identity/reader fixtures and tests; read-only measurement/check scripts and evidence. Caster logic, palette tables and native code unchanged.

Ledger text for A3: light trial and optional role-reader merged default off, all controls and post-merge Lakeview checks pass; light aspect remains unscored, existing budget overages unchanged. Used: calibration-v2 sharedLook.lighting.shadow/sky, A4 companion contract and A8 audit. Mock: 06-sloans/01-lakeview; c8c361d controls. Deviation: lower-fill interpretation experimental; credits top 32 rows excluded; no GPU role colour application.
