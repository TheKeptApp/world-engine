# Look loop: regressions

This run (2026-10-07 18:49, engine `c49ecb0`) against the previous published run (2026-10-07 16:47, engine `debec74`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**4 regression flag(s) in 3 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | light | 3 | 2 | Golden hour shows only in the blush sky, a warm rim on far crowns and pale warm bands across the road; the near field (lawns, walk, wall, dog) is flat cool shade, the frame mean RGB is neutral (118, 121, 117) against the |
| [v2-01](sheets/v2-01.jpg) | adRegional | 3 | 2 | Reads as a generic autumn suburb: mostly orange maple-like crowns where Denver should be gold cottonwood, ash and aspen, boxy stucco houses with no bungalow or foursquare porches, and only one blue-spruce cone far down t |
| [lakeview-street](sheets/lakeview-street.jpg) | light | 3 | 2 | One coherent low western sun (east-facing walls in shade, sunlit road patch with a soft shadow edge along the street axis, warm rims on crown tops) but the key is weak and flat: no cast shadows or warm light on lawns and |
| [lakeview-street-afternoon](sheets/lakeview-street-afternoon.jpg) | light | 4 | 3 | One coherent sun: shadows fall right and toward the camera (NE bearing for az 225, el 41), shade is 0.53 (road) and 0.58 (lawn) of lit against the pack's 0.62, cool tint, no double tint; held at 3 by the missing warm key |

**Not counted: 8 flag(s) in 7 view(s) whose frame did not change since the previous run** (under 0.5% of pixels differ by more than 12 levels), so the move is grader variance, not a regression: evanston-street, ordinary-street, showcase-01, showcase-03, wilmette-aerial, wilmette-street-afternoon, wilmette-street-fall.

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [showcase-01](sheets/showcase-01.jpg) | depthFog | 3 | 2 | Distance is flat: the far tree row keeps saturation 0.86-0.89 (mid yellow crowns 0.89) and the same contrast as the mid band (std 59 against 59) with no tint toward the sky, so the far shore is a crisp yellow stripe; the |
| [showcase-03](sheets/showcase-03.jpg) | depthFog | 4 | 3 | Useful separation: crisp near trunks and crowns, full-colour mid trees, a hazed pastel far tree band, lawn lightening toward the horizon, and a continuous far shore across the lake with no fog seam. The haze is a thin un |
| [ordinary-street](sheets/ordinary-street.jpg) | characterReadability | 4 | 3 | The black Lab reads clearly on the pale walk (ears, collar line, legs, soft contact shadow), about 19 % of frame height. The coat is near-flat black with a hard-edged grey sheen patch on the back, the hips read as a dark |
| [ordinary-street](sheets/ordinary-street.jpg) | houseVariety | 3 | 2 | Visible buildings are near-identical beige and cream boxes with blue windows: the left wall has one window and a door, the far blocks differ mainly in window rhythm, and a small grey-green gable is the only different roo |
| [wilmette-street-afternoon](sheets/wilmette-street-afternoon.jpg) | depthFog | 3 | 2 | Depth reads only through perspective, scale and converging tree rows: far houses, rooflines and tree rows stay crisp and fully saturated, and the sky pales only slightly (zenith #369ACC to #6FABCC) with no pale horizon b |
| [wilmette-street-fall](sheets/wilmette-street-fall.jpg) | adGroundRich | 3 | 2 | Lawn is one flat tone with hard edges to the walk and slab, shrubs are a few pale-olive capsules (no merged lobes) plus one long hedge, no beds or mulch, no leaf litter under the real crowns; the only variation is a shad |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | groundRichness | 3 | 2 | Lawns are almost one flat mid-green: sunlit lawn blocks span only value 0.57-0.68 and saturation stdev 0.02, so only cast shadows vary them. Sidewalks, driveway slabs and alleys add seams, but there is no leaf litter und |
| [evanston-street](sheets/evanston-street.jpg) | depthFog | 3 | 2 | Depth comes from perspective and overlapping layers only: the far road (about 150,156,160) matches the near road (152,157,156), the far sidewalk does not lighten, and far crowns keep saturation 0.8 to 0.95, with no warm  |
