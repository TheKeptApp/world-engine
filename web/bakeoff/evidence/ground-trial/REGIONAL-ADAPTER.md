# Regional adapter and approved rebaseline — R, 9 October 2026

R authorized current-main OFF as the control, with trial OFF == unmodified main exactly. c8c361d images remain historical only. Credit rows are still reported separately by the comparison tool; the new captures additionally require complete PNG byte equality. The earlier 600 m difference was isolated to upstream main: `591e4be` replay equals trial OFF byte-for-byte. Do not relabel that historical failure as a historical pass.

The branch rebased cleanly from `591e4be` to `f7fdfe1`. The latter changes only inactive candidate/context modules and documentation; default `main.js` and export sources are unchanged. Fresh `*-main` controls replay `f7fdfe1:main.js` with all trial flags off, identical current assets and dependencies. Existing qualified OFF/ON pairs are reusable only if those fresh controls match exactly. Greenville is a newly enabled scene: both control and trial use the same declared regional data adapter, never a different city/camera/grade.

## Inputs and inferred gaps

- `greenville-sc-v1/STATUS.md`: approved 7 Oct; earlier blocking text incorrectly conflated an absent compiled adapter with absent pack approval. Read README Look authority/Coverage/Values, values trees/seasonalLawns/weather. Opened `images/07-downtown.png`, `13-trees.png`, `16-seasonal-lawns.png` from the main checkout; downtown and tree sheets include aerial insets. These are authored targets, not surveys or identical cameras.
- `haze-visibility-v1/regions[id=southeast-inland].locations` explicitly lists Greenville SC, Atlanta and Nashville. Consume that region's approved season/state preset without modifying values. Summer clear is 25 km; 5% MOR and airlight are unchanged. Current frozen fixture remains summer clear/day despite the calendar-demo date, matching the shared inspection protocol.
- `foliage-seasons-v1/cities.atlanta.mix`: inferred same-climate species proxy (Atlanta is in the same approved haze region), not a Greenville inventory. P2 `data/p2-crowns.json/foliageSeasons.nearest` supplies botanical display proxies, e.g. loblolly→ponderosa. Missing exported form families retain existing P2 scaffold forms with regional species colours. Evergreen broadleaves retain evergreen biology; their missing scaffold uses the existing rounded shape, labelled inferred. Every proxy is recorded in each capture report. This does not claim implementation of all five Greenville tree families or authored shares.
- No calibrated Greenville calendar knots exist in the baked inputs. `foliage-seasons-v1/phenologyPolicy` requires local evidence; retain neutral summer with `phenologyQuality=unknown`, explicitly inferred. Do not infer autumn from latitude alone. The same fallback principle was read in `sky-seasons-v1` §5.1 as research, not permission to consume pending values. Existing Chicago/Denver knots and dates remain byte-identical.
- No facade-detail family is classified for this regional adapter: retain exported buildings/materials. Ground trial still acts only on validated roles and exported lot fields. No Greenville-only facade colour, terrain, planting placement or river effect is added.
- `regional-adapter.mjs` accepts region metadata (climate, species proxy, latitude); no area IDs, camera inputs, numeric palette overrides or new lighting values. Missing approved inputs reject. The capture contract alone names the area and reuses `world_scoreboard.py`'s manifest-centre 150 m / heading 270 / pitch 45 / FOV 50 recipe. Source data latitude is recorded, not used to fabricate seasonal fractions.

## Validation

12 arithmetic/reader suites plus 16 capture tests passed under load 4.35. Adapter tests cover deterministic resolution, all exported crown forms, unchanged existing regional states, immutable input packs, rejected missing climate, approved MOR, and the unknown seasonal prior. First numeric haze witness incorrectly expected 35 km; corrected to the actual approved summer-clear 25 km before the successful complete run. No pack value was adjusted.

## Ledger text for A3

R decisions: rebaseline on fresh current-main OFF, exact trial-OFF equality; inferred data-driven regional gaps allowed, pending packs excluded. Ground/Materials 2→3 remains a target only. Review `current-main/blind/` for Sloan 40/150/600 and all four hold-outs, with `blind-key.json` kept separate. No scores or promotion by A2. This document supersedes earlier blocked-status notes once all captures and merge complete.

### Capture clock correction

Greenville's first OFF repeat differed by at most 2/255 (43,822 RGBA components; counters identical). Difference pixels followed the river. `web/src/materials.js:151` uses Three's `time` for shared water ripples, whereas the harness previously froze only bakeoff's separate `now` uniform. Freeze the existing Three `time` render callback to zero at the same capture boundary, for every scene and mode. This is capture tooling only; no renderer/material/animation values change in ordinary use. Preserve the failed batch under `greenville-off-rejected-live-water-clock/`. Repeat validation and all fresh-main comparisons use both clocks frozen. Prior pairs are reused only where exact fresh-control comparison proves unchanged pixels.

Fresh `f7fdfe1` controls for Sloan 40/150/600 and Lakeview 150 have now proven full PNG-byte equality to the qualified trial OFF pairs (world max/mean 0/0). The old c8c361d Sloan600 difference remains historical only.

## Final pre-merge evidence

All seven views pass the approved current-main control gate: full PNG-byte equality and world max/mean 0/0. Every fresh/repeat check is exact in the accepted batches. Every main/shadow/post cost bucket is identical OFF/ON; post is 1 triangle / 1 draw in each view. Absolute overages remain unpromoted.

| View | Main triangles/draws OFF=ON | Shadow triangles/draws OFF=ON | Added triangles/draws |
|---|---:|---:|---:|
| sloans-40 | 729,089 / 182 | 69,639 / 62 | 0 / 0 |
| sloans-150 | 791,749 / 251 | 67,961 / 42 | 0 / 0 |
| sloans-600 | 624,291 / 292 | 0 / 0 | 0 / 0 |
| lakeview | 323,901 / 131 | 73,212 / 62 | 0 / 0 |
| wilmette-150 | 624,169 / 246 | 66,723 / 38 | 0 / 0 |
| west-highland | 1,044,327 / 209 | 25,875 / 5 | 0 / 0 |
| greenville-150 | 467,370 / 174 | 30,459 / 26 | 0 / 0 |

The original four-area pairs are reused after exact fresh-main comparisons; Greenville adds new accepted pairs. `current-main/blind/` and `blind-key.json` now include all seven views. No scores.

## Merge and scoreboard

Merged default off as `978396b`. The post-merge existing scoreboard completed 24 frames/eight areas, with budget-floor and budget-standard failures in all 24 and blank-ground in seven. It measures shipping web modules, not this look trial; no visual score or promotion follows. The original scoreboard comparison target is non-comparable due to source/contract drift. Full report is adjacent in `post-merge-scoreboard.json` / `.md`.
