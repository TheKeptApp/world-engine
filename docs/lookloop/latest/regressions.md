# Look loop: regressions

This run (2026-10-07 12:36, engine `9a73324`) against the previous published run (2026-10-07 11:45, engine `1e40260`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**8 regression flag(s) in 5 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | light | 3 | 2 | Sun is 6 degrees up and 17 degrees left of centre, hidden behind the near house. The sky is pale pink and one warm streak crosses the road, but the walk, lawns and walls are evenly cool-shaded with no warm key and no cas |
| [v2-01](sheets/v2-01.jpg) | softnessAO | 3 | 2 | The house plinth, foundation shrubs on mulch and the dog's soft shadow give basic contact. Trunk bases are bare cylinders on the grass with no darkening or flare, tree and house shadows never reach the lawns or walk, and |
| [v2-01](sheets/v2-01.jpg) | adGroundRich | 3 | 2 | Four olive foundation shrubs on a mulch strip and a darker lawn edge band, but no lawn patches, wear or shade tone, no beds or hedges elsewhere, and leaf litter nearly absent under the street trees; far below the varied  |
| [v2-06](sheets/v2-06.jpg) | houseVariety | 3 | 2 | Lot sizes, block grid and alley lines are plausible, but at phone size houses are bright-edged specks under orange crowns and roof/wall families do not separate, so no kit families read; only a few civic and industrial b |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | houseVariety | 4 | 3 | Several believable families (brick cross-gable with arched garage and entry canopies, tan side-gable, peach hip, cream gable-front, flat-roof boxes) and rear garages on alleys, but roofs are almost all one warm grey, mid |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | softnessAO | 3 | 2 | The tan house has a soft eave gradient and a dark foundation strip, but trunk bases end in a hard flat cut with no darkening on the lawn, the barrel shrub at left floats with no ground contact, the steps and shrubs have  |
| [lakeview-street](sheets/lakeview-street.jpg) | softnessAO | 3 | 2 | Contact occlusion is mostly missing: the big foreground trunk ends in a flat cut with no root flare and no darkening on the lawn, and the other trunk bases, the tan wall plinth, the stoop and the curb show none either. O |
| [lakeview-street](sheets/lakeview-street.jpg) | adGroundRich | 3 | 2 | One flat lawn tone on each side with hard edges against the walk. Planting is limited to about four foundation-shrub lobes over a mulch strip beside the wall, a flat-crested hedge and two single shrubs across the road, p |

**P3 note (commit 9a73324, P2 crowns and ground):** 8 counted flags in 5 views whose frames changed; none is about colour (contact shading on lakeview-street, evanston-street-rain and v2-01; lawn flatness on lakeview-street and v2-01; house variety on v2-06 and wilmette-aerial). No view is down more than 3 points on /50 (v2-06 23.2 → 23.7, wilmette-aerial 29.5 → 32.6). The mock-closeness flag is in the scoreboard (12:36).
