# Look loop: regressions

This run (2026-10-07 09:15, engine `4263b3f`) against the previous published run (2026-10-06 23:45, engine `463e06c`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 13 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**10 regression flag(s) in 5 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | softnessAO | 3 | 2 | Shrubs at the foundation sit with little contact darkening, there are no shadow pockets under the crowns and trunks, and the house base is a flat band. |
| [v2-06](sheets/v2-06.jpg) | v2 /50 | 28.4 | 23.2 | At phone size the aerial reads as a correct but flat, desaturated map with a slate lake and no golden-hour light compared with the warm paint-over. The biggest gap is light and colour: no warm raking sun, lake glint or d |
| [v2-06](sheets/v2-06.jpg) | palette | 3 | 2 | Frame is desaturated grey-beige with a slate-grey lake (saturation -79 vs target 1); fields and lake lack the paint-over's warm gold and deep blue; autumn orange only in tiny crowns. |
| [v2-06](sheets/v2-06.jpg) | softnessAO | 3 | 2 | Little visible contact shading around buildings, crowns or lakeshore; houses look pasted on flat ground. |
| [v2-06](sheets/v2-06.jpg) | depthFog | 3 | 2 | No atmospheric haze or tonal gradient with distance; far fields as bright as near; lake and shore edge are continuous and no horizon. |
| [v2-06](sheets/v2-06.jpg) | houseVariety | 3 | 2 | Neighbourhood grids are tiny orange/grey clutter; roof families barely differentiate and no modern/old mix reads. |
| [ordinary-street](sheets/ordinary-street.jpg) | houseVariety | 3 | 2 | Near house is a bare box with large window and no trim, porch or roof; the far yellow building is a generic block. Little variation or detail compared with the mock's brick and trim contrast. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | silhouettes | 4 | 3 | Gabled and hipped roofs and a few dark spruces read, but deciduous crowns are repeated lollipop clusters of 2-3 spheres on thin poles; families differ mainly by colour. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | groundRichness | 3 | 2 | Lawns are near-uniform flat green with only faint tone patches; walk is clean, sparse grass tufts only; target has beds, mulch and varied lawn. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | adGroundRich | 3 | 2 | Mostly flat lawn, a few small shrubs at foundations, no beds with mulch, no litter; hard edges at walk. |

**P3 loop flag (more than 3 points down, owner rule):** v2-06 28.4 → 23.2 /50 at engine `4263b3f` (P2 house contrast pass). The reviewer's reasons are palette, haze and contact shading on the aerial, not house colours. It counts under GRADING §N only if the next core run confirms it (> 5 twice). Lane to watch: 5A (aerial light and haze) unless the next run ties it to the house colours.
