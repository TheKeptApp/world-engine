# Look loop: regressions

This run (2026-10-07 16:47, engine `debec74`) against the previous published run (2026-10-07 16:13, engine `43db743`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**4 regression flag(s) in 2 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [evanston-street](sheets/evanston-street.jpg) | groundRichness | 3 | 2 | Lit lawn is one flat tone (luma 155-157 across y 390-440, lot and verge within about 3 deg hue) with hard polygon edges to the walk; the only richness is sparse orange leaf flecks, small grass tufts, faint sidewalk joint |
| [evanston-street](sheets/evanston-street.jpg) | adGroundRich | 3 | 2 | Lawn is effectively one colour with the cast shadow as its only variation, and there are no beds, mulch, worn edges or tone patches; foundation shrubs are few and crude (one faceted capsule at the left edge that reads as |
| [lakeview-postcard-afternoon](sheets/lakeview-postcard-afternoon.jpg) | silhouettes | 3 | 2 | Roofs read as three families (flat parapet flats, one pale front-gable house, porch hoods and hips) but repeat; crowns are stacked/lollipop faceted spheres (left pair is 4-5 balls on bare poles, right ones separate dark  |
| [lakeview-postcard-afternoon](sheets/lakeview-postcard-afternoon.jpg) | adGroundRich | 3 | 2 | Lawns are flat single-tone fields (bright parkway, darker front lawns); shrubs are single blobs and pills, the left hedge is a smooth loaf, beds are bare mulch strips; no lawn patches, worn edges, tree-pit mulch or leaf  |

**Not counted: 3 flag(s) in 3 view(s) whose frame did not change since the previous run** (under 0.5% of pixels differ by more than 12 levels), so the move is grader variance, not a regression: evanston-street-rain, lakeview-postcard, showcase-01.

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [showcase-01](sheets/showcase-01.jpg) | light | 4 | 3 | One coherent low sun: lawn shadow edges mapped onto the ground plane average -26.7 deg from the heading, exactly the data's 73.3 deg bearing for heading 100, with trunks and lobes lit on the right and a warm lit wedge ag |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | silhouettes | 3 | 2 | Roofs read as three families (grey cross-gable, tan side-gable with entry hood, low brick hip), but every tree is the same faceted stacked-ball crown on a straight, untapered prism trunk with antler-like spikes, no forks |
| [lakeview-postcard](sheets/lakeview-postcard.jpg) | groundRichness | 3 | 2 | The road is one grey-mauve tone with no markings or wear, the parkway and front lawns are flat one-tone olive green with a few small grass tufts, and the walks are one flat peach tone with crisp edges; there are no lawn  |
