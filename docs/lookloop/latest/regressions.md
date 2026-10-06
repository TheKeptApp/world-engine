# Look loop: regressions

This run (2026-10-06 16:45, engine `72b8e3b`) against the previous published run (2026-10-06 16:07, engine `d0c0e6b`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**19 regression flag(s) in 10 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-06](sheets/v2-06.jpg) | silhouettes | 3 | 2 | Houses are tiny uniform boxes and tree crowns are orange dots; no readable roof or crown families from the air |
| [v2-06](sheets/v2-06.jpg) | softnessAO | 3 | 2 | Flat-shaded blocks, no visible contact occlusion or soft shadows at this scale |
| [v2-06](sheets/v2-06.jpg) | houseVariety | 3 | 2 | Neighbourhood grid reads as repeated small boxes; only a few distinct larger buildings |
| [showcase-02](sheets/showcase-02.jpg) | softnessAO | 3 | 2 | No visible contact occlusion at trunk bases, bench or path edges; objects sit on the lawn without grounding. |
| [showcase-07](sheets/showcase-07.jpg) | houseVariety | 3 | 2 | Only a few tiny, hazy house shapes are visible in the distance; no family can be read. |
| [showcase-07](sheets/showcase-07.jpg) | adRegional | 3 | 2 | A lake trail with spruces and bare trees is generic; no recognisable Front Range cues, and the mountain band is correctly absent. |
| [light-rain-street](sheets/light-rain-street.jpg) | adGroundRich | 3 | 2 | Few foundation shrubs and a worn edge strip, but the lawns are single flat colours with sparse tufts and little leaf litter. |
| [wilmette-street](sheets/wilmette-street.jpg) | v2 /50 | 34.2 | 30.0 | At phone size this reads as a clean stylized golden-hour street with coherent colour but flat lawns and weak key light. The biggest gap is the sterile foreground ground. |
| [wilmette-street](sheets/wilmette-street.jpg) | palette | 4 | 3 | Coherent warm brick, green lawn and lilac sky; lawn is a flat saturated green and crowns a uniform lime-yellow, less rich than the target |
| [wilmette-street](sheets/wilmette-street.jpg) | light | 4 | 3 | Warm low sun with long glow on walk and crowns reads golden hour, but the key is weak on facades and shadows are soft blobs; target is warmer and punchier |
| [wilmette-street](sheets/wilmette-street.jpg) | groundRichness | 3 | 2 | Foreground lawn is nearly one flat green with a stark detached paving strip; few patches, no worn edges or litter |
| [wilmette-street](sheets/wilmette-street.jpg) | adGroundRich | 3 | 2 | A few shrubs and a hedge, but lawn is a single tone with hard edges and no beds or litter |
| [wilmette-street-snow](sheets/wilmette-street-snow.jpg) | adRainReadable | 3 | 2 | Snow view marked wet: the road shows a slightly darker, glossy tone and small puddle-like patches, but falling snow is barely visible and wetness is hard to read at a glance. |
| [evanston-postcard](sheets/evanston-postcard.jpg) | groundRichness | 3 | 2 | Near lawn is one flat grey-green tone with no patches, beds or litter; the sidewalk is a thin line and the road a large empty plane |
| [evanston-postcard](sheets/evanston-postcard.jpg) | adGroundRich | 3 | 2 | Foundation hedges exist but the lawns are a single flat tone and have no beds, worn edges or leaf litter |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | softnessAO | 3 | 2 | Only a few thin dark seams at house bases; trunks, shrubs and the sidewalk edge have little contact occlusion, and the shadow blob on the walk is a hard-edged stamp under an overcast sky. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | silhouettes | 4 | 3 | Gabled houses, a long flat-roofed apartment block and conifers read, but lollipop deciduous crowns repeat in near-identical orange/yellow balls |
| [evanston-aerial](sheets/evanston-aerial.jpg) | adRegional | 4 | 3 | Fall maple/oak mix, brick two-flats and tree-lined grid streets read as North Shore/Evanston suburb, though generic in house detail |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | depthFog | 3 | 2 | Almost no atmospheric separation: the far rows have the same contrast and saturation as the near ones, and the top edge ends in a hard crop of rooftops with no haze or edge treatment. |

## Same-grader check (Sonnet, §S): d0c0e6b → 4b979d4

| View | Before (d0c0e6b) | Now (4b979d4) | Commit |
|---|---|---|---|
| [wilmette-street](sheets/wilmette-street.jpg) | 34.2 | 30.0 (−4.2) | `4b979d4` (P2 road widths, the only change). The near-lawn tree shadows are gone (trees re-placed by the wider carriageway / clamping?); it lost its gate pass. |
