# Look loop: regressions

This run (2026-10-06 13:50, engine `f7ca60b`) against the previous published run (2026-10-06 13:24, engine `8727461`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**14 regression flag(s) in 11 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | palette | 3 | 2 | Desaturated, muddy: olive-yellow lawn beside grey-green verge, mauve house, dull lavender walk; far from the warm restrained golden-hour palette of the target (saturation -72). |
| [showcase-02](sheets/showcase-02.jpg) | softnessAO | 3 | 2 | Trunks and the bench sit on flat lawn with little visible contact darkening; faceted crowns have hard-edged shading and no soft occlusion or bevel. |
| [showcase-04](sheets/showcase-04.jpg) | softnessAO | 3 | 2 | No visible contact darkening at trunk bases, bench or path edges; the one dark oval on the path looks like a pasted blob. |
| [showcase-06](sheets/showcase-06.jpg) | softnessAO | 3 | 2 | Trunks and the bench have no visible contact shading on the lawn, and there are no cast shadows. Surfaces look flat and pasted onto the ground. |
| [showcase-07](sheets/showcase-07.jpg) | houseVariety | 3 | 2 | Only faint, tiny house shapes at the horizon; nothing readable (too small to judge). |
| [showcase-08](sheets/showcase-08.jpg) | adRainReadable | 3 | 2 | Wetness 0.45 shows only faint sheen on the snow and path; there are no readable puddles or darker wet grass, and little sky change. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | softnessAO | 3 | 2 | Trunk and bench bases, path edges have little contact darkening; cast shadows are large hard-edged bands. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | adRegional | 3 | 2 | Generic park with mixed lollipop trees; no Front Range cues, no mountains (correct for ESE) but little Sloan's Lake identity. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | adRainReadable | 3 | 2 | Road is slightly darker with faint sheen and thin streaks, grass not visibly darker, no clear puddles; the dark sky carries most of the rain read. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | adRainReadable | 3 | 2 | Snow reads via overcast sky and sparse flakes, but wet-road sheen is minimal; the road looks pale, no puddles or dark wet contrast. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | v2 /50 | 33.8 | 31.3 | At phone size this reads as a coherent, tidy autumn suburb with correct layout and one consistent sun, but it is muted and repetitive in tree crowns and houses. The biggest gap is the lack of autumn ground richness (leaf |
| [evanston-aerial](sheets/evanston-aerial.jpg) | silhouettes | 4 | 3 | Gabled brick houses, a long flat-roofed block and a few conifers read, but the round lollipop crowns repeat in clusters and most houses share one roof family. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | light | 4 | 3 | One warm afternoon sun with long cool shadows from the buildings; consistent, but the fall warmth is moderate and shadows are mostly large flat blue slabs. |
| [lakeview-street](sheets/lakeview-street.jpg) | softnessAO | 3 | 2 | Little contact shading: big shrub sits on lawn with no base shadow, building base is a flat band, no eave or porch occlusion |

## Same-grader check (Sonnet vs Sonnet, ccb5f77 frames → 35827f6)

| View | Before (ccb5f77, Sonnet) | Now (35827f6, Sonnet) | Commit |
|---|---|---|---|
| [evanston-aerial](sheets/evanston-aerial.jpg) | 36.3 | 31.3 (−5.0) | `35827f6` (5A: context rings). The only view down more than 3 on the same grader; check the ring edge and haze on the sheet. |
