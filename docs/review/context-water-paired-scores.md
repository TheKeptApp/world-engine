# Context masses and far-water/ring — A3 blind review, 9 Oct 2026

**No promotion.** A2 light trial is already scored in [5cc9adc](light-trial-paired-scores.md), so not repeated. Context masses improve ground preference in all three 600 m pairs, but overall preference is inconclusive; the far-water/ring change has no visible look loss in these six-aspect comparisons. A4’s final far-geometry delivery remains pending; its working snapshot is not silently treated as current-main evidence.

## Frozen sources and method

- Context: [A5 README](../../web/bakeoff/evidence/context-buildings/README.md), implementation `0543913`, main-600 manifest capture-base `8f08c42` plus the source hashes in that manifest. OFF versus ON is the **whole mapped ring plus masses**, not masses isolated from a ring-only baseline. Do not attribute the whole visible gain to building masses alone.
- Water/ring: [A5 README](../../web/bakeoff/evidence/far-water-ring/README.md), implementation `d82a68d`, accepted V4 after rebase to `e112565` including finite-wind `b66b146`. Compare BEFORE to combined AFTER, not rejected V1/V2/V3 attempts. Shipping-module fixture differs from the context bakeoff fixture; their grades are not a cross-renderer or cross-build delta.
- All 12 neutral copies match delivered SHA-256 hashes; all source repeat controls match their OFF/BEFORE PNG. Context cameras, atmosphere, date, exposure and projection match within pairs. Water/ring cameras and capture-only shader time=0 match; source-specific package fixtures remain unchanged. [Identity audit](context-water-scoring/identity-audit.json).
- [Paired protocol](paired-preference-protocol.md), GRADING §§M/N: three fresh, separately initialized review contexts without source keys or earlier judgments; 12 conventional grades locked before 14 randomized A/B panels in each session. Each of six pairs appears twice per session, in opposite positions, with no consecutive duplicate pair. Six judgments per pair, three per position; two hidden identical-image controls per session. Panels show the entire frame at equal 390 px widths; original 1005×565 frames inspected for conventional grades. No crops, masks, colour changes, captures or builds.
- **All six identical controls pass on all six aspects**, with consistent roof answers. Every ground ON win splits A=3/B=3. Overall ON votes split A=1/B=1, with four ties, so cannot meet the 5/6 repeatable-preference threshold. Full position/control/roof data in [results](context-water-scoring/results.json); original reasons and lock times in the six session files beside it.
- Reviewers recognized repeated scenes within their own sessions but reported no source/version identity. Three fresh contexts are still same-model judgments, not independent human observers; six votes are a consistency screen, not statistical confidence. Neutral filenames and a separate key cannot remove scene familiarity.
- References: calibration `06-sloans.png` and `01-lakeview.png`; lake-winter `01-water-that-reads.png`, `02-big-lake-vs-city-lake.png`, `06-phone-readability-targets.png`; water-surfaces `images/sloan-summer.png` and `michigan-summer.png` (mechanics only, not colour). All seven opened in each session. These are look/feature references, **not approved camera-matched 600 m compositions**. Autumn pigment is not penalized merely for differing from a summer target. Sky is not visible and stays N/A.

## Per-pair results

Grades below retain session 1/2/3 integers, without averages or invented fractional precision. Counts are **before wins / after wins / ties**; context before=OFF and after=ON. A six-tie result establishes no visible change at this inspection scale, not exact pixel identity.

| Pair | Aspect | Before grades (S1/S2/S3) | After grades (S1/S2/S3) | Before / after / tie | Conclusion |
|---|---|---|---|---|---|
| Context Lakeview600 | light | 1/1/1 | 1/1/1 | 0 / 0 / 6 | repeatable tie |
| Context Lakeview600 | saturation | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Context Lakeview600 | materials | 2/2/1 | 2/2/1 | 0 / 0 / 6 | repeatable tie |
| Context Lakeview600 | ground | 1/1/1 | 2/2/2 | 0 / 6 / 0 | on preferred |
| Context Lakeview600 | foliage | 1/2/1 | 1/2/1 | 0 / 0 / 6 | repeatable tie |
| Context Lakeview600 | overall | 2/2/1 | 2/2/2 | 0 / 2 / 4 | inconclusive |
| Context Sloan600 | light | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Context Sloan600 | saturation | 2/3/2 | 2/3/2 | 0 / 0 / 6 | repeatable tie |
| Context Sloan600 | materials | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Context Sloan600 | ground | 2/2/2 | 2/2/2 | 0 / 6 / 0 | on preferred |
| Context Sloan600 | foliage | 1/2/1 | 1/2/1 | 0 / 0 / 6 | repeatable tie |
| Context Sloan600 | overall | 2/2/2 | 2/2/2 | 0 / 2 / 4 | inconclusive |
| Context Wilmette600 | light | 1/1/1 | 1/1/1 | 0 / 0 / 6 | repeatable tie |
| Context Wilmette600 | saturation | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Context Wilmette600 | materials | 2/2/1 | 2/2/1 | 0 / 0 / 6 | repeatable tie |
| Context Wilmette600 | ground | 1/1/1 | 2/2/2 | 0 / 6 / 0 | on preferred |
| Context Wilmette600 | foliage | 1/2/1 | 1/2/1 | 0 / 0 / 6 | repeatable tie |
| Context Wilmette600 | overall | 2/2/1 | 2/2/2 | 0 / 2 / 4 | inconclusive |
| Water/ring Lakeview600 | light | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Lakeview600 | saturation | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Lakeview600 | materials | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Lakeview600 | ground | 1/2/2 | 1/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Lakeview600 | foliage | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Lakeview600 | overall | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | light | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | saturation | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | materials | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | ground | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | foliage | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Sloan600 | overall | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | light | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | saturation | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | materials | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | ground | 1/2/2 | 1/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | foliage | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |
| Water/ring Wilmette600 | overall | 2/2/2 | 2/2/2 | 0 / 0 / 6 | repeatable tie |

## What moved, what did not

Context ground: Lakeview and Wilmette rise **1→2 in all three sessions**; Sloan remains **2→2**, despite 6/6 ON preference. Mapped roads/ground/masses reduce the empty flat surround. Overall ON is preferred only 2/6 per site with four ties, so **inconclusive**. Sloan overall stays 2/2/2; Lakeview/Wilmette overall OFF=2/2/1, ON=2/2/2: only one session moves a point. Report that disagreement, not a consensus whole-point gain. Light, saturation, materials and foliage tie 6/6 at every context site. Pale/flat lighting, angular disconnected crowns, Sloan granular water glare and a finite coarse band remain. Light=1 in all context Lakeview/Wilmette sessions; foliage=1/2/1 at all three sites. These are current blind-session observations, not retroactive changes to earlier grades.
Far-water/ring: all six aspects and overall tie 6/6 at Sloan, Lakeview and Wilmette. Overall is **2→2 in every session**; unchanged Lakeview/Wilmette ground grades vary 1/2/2 between sessions. No new visible look loss, but the milky/flat lake, ochre ground and dark coarse masses are not cured. Independent decoded-RGBA comparison confirms Sloan **4 differing bytes, max 1/255**, Lakeview/Wilmette **0**. The latter two have no selected detailed water in these views: they witness ring batching, not a second water-surface test.
Untuned hold-outs: no preference or within-session whole-point loss in Lakeview/Wilmette. No focus-gain/hold-out-loss reject flag in the reviewed pairs. West Highland and Greenville visual comparison is not supplied here; A5’s technical no-op/control evidence for those sites is not an A3 grade. None of the six AFTER views reaches overall 3; some aspects are below2. No ship-bar pass or default promotion.

## Budget and pending A4 delivery

Context ON main T/D: Sloan **360,036/118**, Lakeview **112,061/38**, Wilmette **385,868/81**. Ring shadows add zero. Sloan exceeds floor draws even though all fit provisional standard; this is not a device pass. Water/ring AFTER main T/D: Sloan **353,611/82**, Lakeview **526,478/56**, Wilmette **485,157/62**, shadows 0/0 in these exact static views. Lakeview/Wilmette fail strict <400k; desktop counters do not qualify the minimum device. No totals from the two fixture families are combined.
A4 working snapshot `web/bakeoff/evidence/spatial-cells/far-parent/summary.json` in `/private/tmp/worldengine-a4-surface` contains six hash-matching 600 m PNGs. It remains uncommitted/revalidation-in-progress in that checkout at this audit; captured source hashes differ from the checkout for `web/bakeoff/spatial-cells.js`, `web/bakeoff/spatial-cells-entry.js`, and `web/bakeoff/entry.js`. Its report says a rebased-source check is separate. **Pending final A4 delivery/current provenance, no A4 score assigned.** [Exact pending-source audit](context-water-scoring/pending-a4.json). Once delivered, score the exact six hashes with three fresh sessions, report all six aspects and whether overall≥3/no aspect<2; intentional ≥400 m look changes use paired scoring plus budget, not an inappropriate lossless-image demand.
A5’s recorded post-merge shipping-default scoreboard at `d82a68d` completed 24/24 frames with failures: all24 floor/standard budget failures, seven of eight600m blank flags and retained tunnel flags. That technical scoreboard tests defaults, not these opt-in pairs; it is not a look score. This scoring-only filing runs no new capture/scoreboard rendering.

## Evidence and scope

Locked raw grades/preferences, neutral-to-source key, all votes, position splits, roof judgments, source identity checks and reasons are in [context-water-scoring](context-water-scoring/results.json). Original PNGs remain untouched in A5’s local ignored evidence; neutral copies/panels remain in `/private/tmp/a3-context-water-blind/`. No images are committed.
Used: GRADING §§M/N; paired-preference protocol; world-edge-options §§Recommendation/Integration; water execution brief §§Research/Cost; budget-tiers §Contracts; shadow-and-draw-floor §Qualification; A5 source READMEs/manifests; DECISIONS and REFERENCE-MAP. Mock: the seven exact registered references listed above. Deviation: no approved matched 600 m whole-scene mock; separate fixture families; A4 final delivery pending; no promotion.
Tracker update:
