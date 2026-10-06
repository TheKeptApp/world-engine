# Look loop: regressions

This run (2026-10-06 16:07, engine `d0c0e6b`) against the previous published run (2026-10-06 15:38, engine `bed615b`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**26 regression flag(s) in 13 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-04](sheets/v2-04.jpg) | groundRichness | 3 | 2 | Two flat lawn tones with sparse grass tufts; no beds, litter or worn edges in the foreground. |
| [v2-04](sheets/v2-04.jpg) | adGroundRich | 3 | 2 | Only a few foundation shrubs; lawns are flat colour blocks with hard edges at the walk. |
| [showcase-07](sheets/showcase-07.jpg) | v2 /50 | 31.1 | 28.9 | At phone size it reads as a clean, cool overcast snow scene with a believable lake edge, but it is sparse and monochrome next to the targets. The biggest gap is the flat, uniform snow ground with no melt patches, plantin |
| [showcase-07](sheets/showcase-07.jpg) | softnessAO | 3 | 2 | Trunks and benches sit on the snow with little contact darkening; shadow patches are hard-edged olive blobs rather than soft occlusion. |
| [showcase-07](sheets/showcase-07.jpg) | groundRichness | 3 | 2 | Large near-white snow carpet with a smooth path; only a few tiny grass tufts and no patchy melt, shrubs, shore edge or tone variation. |
| [showcase-07](sheets/showcase-07.jpg) | adRainReadable | 3 | 2 | Heavy overcast sky helps, but no visible falling snow particles, no wet/slushy sheen on the path and no wet contrast. |
| [showcase-08](sheets/showcase-08.jpg) | softnessAO | 3 | 2 | Conifers and trunks have little base occlusion; the bench and trunks sit on the ground with minimal contact shadow |
| [showcase-10](sheets/showcase-10.jpg) | v2 /50 | 28.9 | 23.7 | At phone size this reads as a flat grey-teal map with a correctly shaped lake, not the canopied autumn rain aerial of the target. The biggest gap is the flat, uniform ground and missing tree canopy and wet-surface respon |
| [showcase-10](sheets/showcase-10.jpg) | light | 3 | 2 | Flat overcast light with almost no key direction or shadow; the large pale grey ground plane washes out and architecture is not modelled. |
| [showcase-10](sheets/showcase-10.jpg) | groundRichness | 3 | 2 | Outside the lake corridor the ground is a uniform grey-blue plane with a road grid; only the park fringe has some lawn variation. |
| [showcase-10](sheets/showcase-10.jpg) | depthFog | 3 | 2 | Little atmospheric separation toward the top edge; the far grid is as crisp and the same flat grey as the near. The grey plane ends hard at the frame corners and reads as a tile, not a continuous world. |
| [showcase-10](sheets/showcase-10.jpg) | houseVariety | 3 | 2 | Houses read as dark rectangles of near-identical tone; some commercial and industrial blocks differ but no residential kit families are visible. |
| [showcase-10](sheets/showcase-10.jpg) | adGroundRich | 3 | 2 | Land outside the park is one flat grey colour with hard parcel edges; few visible beds or shrubs, some leaf specks near the lake. |
| [showcase-10](sheets/showcase-10.jpg) | adRegional | 3 | 2 | The lake and the bungalow grid are right, but the land-use pattern (flat grey plane, regular fields) reads generic, with no Front Range tree canopy or autumn cottonwood mass like the target. |
| [showcase-11](sheets/showcase-11.jpg) | palette | 3 | 2 | Snow is a blue-grey mottled camo of pale and dark patches; lake is a flat slate. Flat and muddy versus the bright white and blue-teal of the targets; no clipping. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | softnessAO | 3 | 2 | Trunks and bench sit on the lawn with almost no contact darkening; large hard-edged shadow shapes, no base occlusion. |
| [ordinary-street](sheets/ordinary-street.jpg) | softnessAO | 3 | 2 | House base is a dark flat band, shrubs sit as blobs, sidewalk has little edge occlusion; dog contact shadow is faint. |
| [ordinary-street](sheets/ordinary-street.jpg) | houseVariety | 3 | 2 | Only a plain mauve box in foreground and one yellow block in distance; no porches, bungalow/foursquare profiles or entries visible. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | groundRichness | 3 | 2 | Large near lawns are nearly flat green with a hard-edged walk slab; only a few tufts and shrubs, no beds, litter or tonal patches. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | adGroundRich | 3 | 2 | Foreground lawns are one flat green with a hard-edged walk; a few shrubs and a hedge row at the back, no beds, worn edges or litter. |
| [wilmette-street-snow](sheets/wilmette-street-snow.jpg) | groundRichness | 3 | 2 | Foreground is a large near-uniform white snow plane with one faint paving band; no patchy snow over straw lawn like the target; tiny stubble dots only. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | light | 4 | 3 | One coherent sun with shadows falling toward upper-right, consistent with the 40.6 deg bearing; however the light is fairly neutral, with little warm/cool contrast or glow as in the anchor. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | adRegional | 4 | 3 | Mid-century North Shore blocks with brick houses, mixed deciduous and conifer trees and peak-fall colour read as suburban Chicagoland; lawn green and low-pitch roofs are more generic than the anchor. |
| [evanston-street](sheets/evanston-street.jpg) | adGroundRich | 3 | 2 | Mostly one flat green lawn with a few leaf specks and one lone shrub at left. There are no beds, foundation planting or worn edges. |
| [lakeview-postcard](sheets/lakeview-postcard.jpg) | adRegional | 3 | 2 | Reads as a generic tree-lined suburban street; lacks Lakeview's dense three-flats with bays and stoops, and the sparse boulevard-less setting is not the target's dense look. |
| [lakeview-alley](sheets/lakeview-alley.jpg) | softnessAO | 3 | 2 | Few contact shadows or eave occlusion; garage bases sit on the ground without dirt seams and the long walls are smooth planes. |

## Same-grader check (Sonnet, §S): bed615b → d0c0e6b

| View | Before (bed615b) | Now (d0c0e6b) | Commit |
|---|---|---|---|
| [showcase-10](sheets/showcase-10.jpg) | 28.9 | 23.7 (−5.2) | `d0c0e6b` (P2 ground pass 1, the only change). Back to its ccb5f77 baseline (23.7); reviewer: flat grey-teal ground, no canopy, no wet response. Likely grader spread on this aerial as much as the merge; recheck on the next run. |
| [showcase-08](sheets/showcase-08.jpg) | 32.6 (ccb5f77) | 27.9 (−4.7 vs baseline) | Range 35827f6..d0c0e6b; −1.0 vs bed615b. |
