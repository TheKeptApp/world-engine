# Current October web crown controls — shared near plane plus v3

**Use this batch for A3 re-scoring.** Captured from merged main `1580115`: 12 Sloan's primary mode/height frames (OFF, v2 standard, v2 floor, v3 standard × 40/150/600 m), three independent OFF repeats, and Lakeview OFF at 600 m. [Manifest](manifest.json) records every PNG hash, pose/date/exposure, resolved flags, query, near/far planes, pass counts, source identity and coverage evidence. No scores or budget acceptance.

The conflicts with A2 `34f8a7f` were resolved by retaining all A2 query handling, lazy `crown-v3.js` import, installation/fragment logic, metadata and v3 filename suffixes, then adding the shared near-plane calls and capture projection/exposure metadata. Removing only the near import/calls makes bakeoff main.js byte-identical to A2's commit; crown-v3.js and shadow-casters.js are byte-identical. A2's strict identity regression now enumerates those exact camera additions and additionally asserts full v3-source identity. The shipping viewer still delegates the identical old arithmetic and 5% hysteresis to the shared helper; no shader or material changes.

## A2 OFF comparison and submitted costs

The original A2 OFF PNG hashes were retained. Cameras, fixed exposure, fixture, exported scene inputs and every submitted pass agree with the new OFF controls. All three heights change pixels; **none is unchanged**. The new OFF PNGs also match A7's earlier near-corrected control hashes, providing a second control that the v3-off merge did not add a rendered change beyond the camera correction. Decoded RGBA byte differences versus A2: **877 at 40 m, 52,784 at 150 m, 650,933 at 600 m**; compressed PNG differences are reported separately in the manifest and are not pixel-change counts. Near planes change 0.2 → 10/37.5/150 m. All new OFF fresh/repeat encoded PNG and decoded RGBA differences are zero.

| Height | OFF main triangles/draws | V3 standard main triangles/draws | Near plane |
|---|---|---|---|
| 40 m | 729,101 / 182 | 610,961 / 131 | 10 m |
| 150 m | 791,795 / 251 | 1,210,739 / 192 | 37.5 m |
| 600 m | 624,433 / 292 | 847,545 / 229 | 150 m |

Every OFF/v3 main/shadow/post submission matches A2's corresponding recorded pass, not just the listed main totals. All non-foliage passes match across the four modes; expected foliage deltas are retained. Coverage identity now includes crownV3 so an intentional v3 mode cannot masquerade as an OFF repeat; repeats and non-foliage equality remain strict. Whole-scene budgets still fail; these unchanged counts are not a new performance pass.

## Validation and clipping

Passed 16 A7 Node tests, all 46 scripts Python tests, A2 policy/overnight/atmosphere/sky-colour/foliage-exp1/v2/v3 regression suites, 1,056 legacy geometry witnesses, 228 v3 witnesses and A2's historical capture regression. All six A2 headless GPU startup cases passed on merged code (Sloan/Lakeview × OFF/v2 standard/v2 floor), each with its own lock. A2's unchanged capture regression also passed on this batch's fresh/repeat OFF and v3 standard frames. All 16 PNG hashes, 1005×565 dimensions, non-flat technical screens, strict OFF repeats and all-mode coverage passed.

The earlier six OFF/v2 geometry audits found no extra clipping at 40/150 m. New v3 audits on merged main likewise find zero newly clipped triangles, with conservative nearest geometry depths 25.7521/118.4113 m versus near 10/37.5 m. The audit clips transformed submitted triangles/instances to the original 0.2 m view frustum, testing surviving geometry against the new plane; distant DEM is excluded from nearby-content checks. V3's own projected fragment report also records zero near-clipped triangle omissions at all three heights. No extra clamp needed for these scenes; no guarantee for future terrain/tall geometry.

Capture durations OFF/v2 standard/v2 floor/v3 standard/Lakeview: 41.94/20.14/19.67/19.14/8.09 s. Every actual job admitted under load 25, with disk above 8 GiB, and released its own lock. Main advanced with A8/A10 documentation while work proceeded; those changes were retained. The pinned capture source remains merged main 1580115. All earlier comparison batches are superseded by this delivery.

## Earlier batches: pre-fix, not comparable controls

- Original [18-frame A7 set](../a7-web-crown-ladder/README.md): genuinely pre-near-fix. PNGs, original manifest and historical A3 grades remain unchanged.
- Prior [13-frame A7 set](../a7-web-crown-near-fix/README.md): pre-current-integrated-fix and not comparable for new crown acceptance. It already used the near-plane correction, but predates the combined v3/main capture. Do not misdescribe it as having near=0.2.
- A2 [before/OFF/candidate v3 evidence](../../../../web/bakeoff/evidence/crown-v3/REPORT.md): pre-near-fix, historical prototype evidence only. Its original files and report are preserved; use this matched post-fix batch for new v3 comparisons.

No old score is carried across the projection change and no grading is performed here. Fine water noise and main-scene budget overages remain separate from the corrected rectangular lake bands. A3 owns re-scoring; no hold-out visual acceptance or phone timing is claimed.

Used: R's authorized A7 conflict/all-mode request; lake-banding-diagnosis.md; CameraRig.updateNear; A2 crown-v3 REPORT.md and regression tests. Mock: calibration-v2 06-sloans/01-lakeview and crown panels 01/14/17–22, unchanged inputs. Deviation: technical capture/camera proof only; historical batches superseded, no scores or budget acceptance.
