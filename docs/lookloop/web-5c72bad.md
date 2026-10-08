# A3 visual review — web 5c72bad, 8 October 2026

**Pair FAIL 0/2; no closeness gain.** The Sloan's-gain/hold-out-loss reject condition does **not trigger**: both stay 2/5. This is not a look pass; full four-hero gate NOT EVALUATED. No engine rollback is performed. Grader A3-Codex, visual §M only; ΔE is excluded from scoring and decision.

| View | Closeness before → after | Sky | Light | Saturation | Ground | Foliage | Materials |
|---|---|---|---|---|---|---|---|
| Sloan's | 2 → 2 | 3 → 3 | 2 → 2 | 2 → 2 | 2 → 2 | 2 → 2 | 2 → 2 |
| Lakeview | 2 → 2 | 3 → 3 | 2 → 2 | 2 → 2 | 2 → 2 | 2 → 2 | 3 → 3 |

**Sloan's:** water banding is softer than the baseline, but water remains flat/cyan and ground remains broad uniform fills. Sky/cloud modelling lacks the reference's depth; crowns are angular, strongly yellow and poorly shaded internally. A more legible distant ridge does not itself earn look points for geometry. No integer closeness/aspect improvement is established.

**Lakeview:** exposed branch structure is clearer, but coarse crown planes lack soft layered modelling. Walls remain pale and flatly lit; pavement lacks the target's light/shadow richness. Matte material behaviour remains adequate at 3; other gaps remain below the aspect floor. The coarse crowns and pale lighting are qualitative concerns even though the five-point grades do not change.

Do not penalize exact layout, actors, wall hue, missing leaf texture or painted mountain scale. Autumn yellow alone is not a defect: the foliage fixture changed from baseline summer to an explicit 2026-10-08 calendar prior, while atmosphere remains summer-clear. Judge shading and colour relationships without requiring summer greens. This contract change limits causal before/after inference; these are observed baseline/current grades, not a controlled estimate of this one commit's effect. The 08e2cce baseline remains intact. A strictly controlled future delta needs matched seasonal input or a separately labelled October baseline.

## Evidence and untuned hold-out

A3 inspected saved standard-tier Sloan's and Lakeview PNGs against calibration-v2 06-sloans and 01-lakeview. No rendering, tuning or code changes were made by A3. Candidate metadata is byte-identical to the requested commit. The current A2 frozen input hash equals its capture proof (`1933890d007bf559374265617f43f68df9dc4de3e3a69bc0307fddbf0d492295`), with no changed input files; all ordered capture events carry the same digest. This supports unchanged-code Sloan's → Lakeview transfer, not a blind hold-out or independent proof of every implementation choice.

[Grades, capture timestamps, image hashes and pixel-change fractions](web-5c72bad/grades.json), [ordered input proof](web-5c72bad/holdout-proof.json), [current fixture](web-5c72bad/fixture.json). Both cameras and viewports match the original web baseline. Pixel changes use the §N luma >12 threshold; changed frames are not scored as unchanged-frame grader noise. Five-point scores can remain equal despite real pixel changes. Local-only PNGs and phone-size before/after-versus-mock boards: `/private/tmp/worldengine-a3-web-baseline/.build/lookloop/web-5c72bad/`. Images are not committed. No phone-performance conclusion from laptop evidence.

West Highland and Greenville web scoring remain pending suitable capture evidence. No full hold-out clearance is claimed.
