**Owner rule (> 3 parity points, same rubric, d373566 vs b2a23a7):** evanston-street-winter 75 → 69 % · wilmette-street-rain 88 → 80 %. Commit: `d373566` (P2 planting masses). Both views swung the other way in the previous run (69 → 75, 80 → 88), so this is most likely Sonnet noise; re-check next run. Last run's flags showcase-06, evanston-street-rain and v2-06 recovered; showcase-10 stays at 65.

# Look loop: regressions

This run (2026-10-06 19:45, engine `babcfe4`) against the previous published run (2026-10-06 19:03, engine `a353b2d`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**27 regression flag(s) in 15 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | groundRichness | 3 | 2 | Two flat lawn tones, sparse identical grass tufts, almost no leaf litter; sidewalk is a clean pale slab. |
| [v2-01](sheets/v2-01.jpg) | adGroundRich | 3 | 2 | Few small shrubs at the foundation, no beds, tone patches are only two big lawn colours, no leaf litter under crowns. |
| [showcase-04](sheets/showcase-04.jpg) | softnessAO | 3 | 2 | Trunk bases and the bench have almost no contact darkening and nothing sits in the lawn; crowns read as flat unshaded forms. |
| [showcase-06](sheets/showcase-06.jpg) | softnessAO | 3 | 2 | Trunks meet the lawn with no visible contact darkening and no soft crown shadows; the lawn and path are flat and the bench and lamp are barely grounded. |
| [showcase-07](sheets/showcase-07.jpg) | houseVariety | 3 | 2 | Only tiny, hazy house shapes at the horizon, barely distinguishable; none of the target's bungalow families read. |
| [showcase-07](sheets/showcase-07.jpg) | adRegional | 3 | 2 | Spruce, bare trees, lake and bench give a generic park; the Denver bungalow/cottonwood cues and the low mountain band are not readable, and the target's houses are missing. |
| [showcase-08](sheets/showcase-08.jpg) | houseVariety | 3 | 2 | Only tiny, distant house clusters on the horizon, with no readable families; nothing close enough to judge beyond low variety. |
| [showcase-08](sheets/showcase-08.jpg) | adRainReadable | 3 | 2 | Wet 0.45 but the path shows only a faint pale sheen and one small puddle; no clear wet-vs-dry contrast on grass or darker ground, and the sky does not change. |
| [showcase-09](sheets/showcase-09.jpg) | houseVariety | 3 | 2 | Distant houses are tiny dark slivers with no readable families and no lit windows; too small to judge variety. |
| [showcase-10](sheets/showcase-10.jpg) | adRegional | 3 | 2 | Lake with park ring and bungalow grid is plausible for Sloan's Lake, but land use is generic and lacks cottonwood/conifer and autumn mix. |
| [showcase-11](sheets/showcase-11.jpg) | palette | 3 | 2 | Blotchy grey-purple and brown camouflage patches over the whole plane; snow reads as noise, not a restrained snow/gold-grass/blue-water palette like the target. Water is a flat slate blue. |
| [ordinary-street](sheets/ordinary-street.jpg) | groundRichness | 3 | 2 | Large flat lawns with sparse identical grass tufts, minimal leaf litter on the walk; little low-frequency variation. |
| [ordinary-street](sheets/ordinary-street.jpg) | adGroundRich | 3 | 2 | Few foundation shrubs near the house, otherwise flat two-tone lawns with no beds, worn edges or shade tone. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | v2 /50 | 31.1 | 28.4 | At phone size this is a clean stylized Wilmette street under a stormy sky, but surfaces look dry and bright and the distance is crisp. The biggest gap is missing rain haze, wet sheen and ground richness compared with the |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | softnessAO | 3 | 2 | Trunk base and house/hedge contact have almost no occlusion; hedges and shrubs sit on the lawn without darkening. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | depthFog | 3 | 2 | Distant houses and trees stay crisp and saturated; little rain haze compared with the target's misty receding street. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | adGroundRich | 3 | 2 | Few foundation shrubs, no beds or mulch, lawns mostly one green with hard edges, little leaf litter. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | depthFog | 3 | 2 | No visible atmospheric haze: far blocks at the top are as crisp and saturated as the near ones, so depth separation is weak. No horizon, which is correct. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | v2 /50 | 31.1 | 28.9 | A coherent but flat overcast snow street whose snow, houses and distance read acceptably, yet the road is a flat white plane and a giant plain trunk dominates the foreground. The biggest gap is the weak snow and wet weat |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | silhouettes | 3 | 2 | Bare trees are plain forked sticks on straight untapered trunks with a few repeated crown shapes; the huge flat grey trunk slab in the foreground reads as a pillar, not a tree. Houses are readable gabled boxes but repeti |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | softnessAO | 3 | 2 | Trunk bases and shrubs have little contact darkening; shrubs and trunk sit on the snow with almost no occlusion. Only a few dark blotches on the snow. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | v2 /50 | 36.3 | 34.2 | A clean, warm fall oblique that reads clearly as a North Shore block at phone size, with good colour and a coherent sun. The biggest gap is repetitive round lollipop crowns and a flat lawn base lacking contact shading an |
| [evanston-aerial](sheets/evanston-aerial.jpg) | silhouettes | 4 | 3 | Gable, hip and flat-roof houses plus the long brick block read as families, but crowns are mostly round lollipop balls on thin poles with repeated two-ball stacks; one spruce cone stands out, few elms or oaks differ in o |
| [evanston-aerial](sheets/evanston-aerial.jpg) | houseVariety | 4 | 3 | Several kit families (brick colonials, gabled homes, long flat-roofed block, siding houses), but massing repeats and facades are simple. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | adRegional | 4 | 3 | Midwest street grid, brick and gabled houses, fall tree mix and parkway trees read as North Shore; land use is generic and tree families are not clearly oak/elm/maple. |
| [lakeview-alley-winter](sheets/lakeview-alley-winter.jpg) | adRainReadable | 3 | 2 | Wet flag set but only a faint darker spot or two on the snow; no wet pavement through melt, no puddles or sheen, and no visible falling snow in this frame. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | depthFog | 3 | 2 | Distance is crisp and flat; no haze, no tone shift toward the top of frame, and no lake or backdrop edge, so depth rests on perspective alone. |
