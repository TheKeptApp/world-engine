**Owner rule (> 3 parity points, same rubric, c25b6dc vs 393ed1e):** v2-04 87 → 79 % · showcase-05 95 → 90 % · wilmette-street-fall 87 → 83 %. Commits in range: `8434b65` (5A overcast cloud edges), `c25b6dc` (5A wet paving), `e7be7c3` (P1 LiveSky test only). All three are dry, non-overcast views (summer noon, fog, fall afternoon), so neither 5A change reaches them; treated as grader noise and re-checked next run.

# Look loop: regressions

This run (2026-10-06 22:03, engine `c25b6dc`) against the previous published run (2026-10-06 20:44, engine `b8ee81a`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**21 regression flag(s) in 13 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-04](sheets/v2-04.jpg) | v2 /50 | 31.0 | 28.1 | At phone size the frame reads as a clean but flat stylized street with correct noon light and a legible black dog, yet the ground is two flat lawn colours and the house is a blank wall. The biggest gap is ground and buil |
| [v2-04](sheets/v2-04.jpg) | softnessAO | 3 | 2 | Dark band at the wall base, small contact under shrubs, but no tree-base occlusion, no eave/porch occlusion; hard-edged flat shading |
| [v2-04](sheets/v2-04.jpg) | characterReadability | 4 | 3 | Black dog reads clearly on pale sidewalk at about 20% frame height; flat silhouette, weak contact shadow, no coat detail |
| [v2-04](sheets/v2-04.jpg) | houseVariety | 3 | 2 | One large blank grey wall with windows foreground, a beige apartment block in distance; no porches, roof profiles or entries visible |
| [v2-04](sheets/v2-04.jpg) | adRegional | 3 | 2 | Generic suburban street; no low western mountain band despite facing west, no clear bungalow or foursquare families or conifers |
| [showcase-03](sheets/showcase-03.jpg) | softnessAO | 3 | 2 | Trunk bases have little contact darkening and no crown shadows or occlusion on the lawn; surfaces look flat. |
| [showcase-05](sheets/showcase-05.jpg) | depthFog | 4 | 3 | Trees fade with distance and fog is readable, but sky is a dark grey wall, lake is barely visible and the near lawn stays saturated. |
| [showcase-07](sheets/showcase-07.jpg) | adRegional | 3 | 2 | Generic park with bare trees and spruce, no Denver cues such as the distant skyline or the cottonwoods and bungalows. |
| [showcase-10](sheets/showcase-10.jpg) | depthFog | 3 | 2 | No rain haze or distance fade; the world ends in flat plates at the frame edges, with no atmospheric separation. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | softnessAO | 3 | 2 | Trunk bases sit on flat lawn with little contact darkening; bench and spruce base have no occlusion; shadows are the only depth cue. |
| [light-rain-street](sheets/light-rain-street.jpg) | adRainReadable | 3 | 2 | The sky is dark and the road is darker, but there are no visible puddles or sheen on the road or walk, and the walk is a dry light grey; the faint streaks are barely visible. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | softnessAO | 3 | 2 | Trunk bases and shrubs have almost no contact darkening; shrubs and houses look pasted on flat lawn. |
| [wilmette-street-fall](sheets/wilmette-street-fall.jpg) | light | 4 | 3 | One coherent low sun with soft shadow bands on the left lawn, but little warm/cool golden contrast; walls and lawn look evenly lit and not golden-hour. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | houseVariety | 4 | 3 | Several believable kit families (brick foursquares, gables, detached garages) but many near-identical dark-roof boxes repeat. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | adRegional | 4 | 3 | Brick North Shore houses, gridded blocks, a mix of fall maples and elms and a park read as Chicago suburb; the land-use pattern is generic and street trees are uniformly sparse. |
| [evanston-street](sheets/evanston-street.jpg) | groundRichness | 3 | 2 | Lawn is nearly one green with sparse orange leaf dots on the walk and verge; one small shadow band on the left lawn, no patches, beds or worn edges; the pole-like trunk dominates. |
| [evanston-street](sheets/evanston-street.jpg) | adGroundRich | 3 | 2 | Single lawn tone with leaf dots; a few foundation shrubs on the left but no beds, mulch or lawn patches; hard grass-to-walk edges. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | groundRichness | 3 | 2 | Large near-uniform white snow with one olive patch and a few grass tufts; no patchy melt, lawn tone variation or leaf litter like the anchor's snow/dry-grass mix. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | adGroundRich | 3 | 2 | Few foundation shrubs as simple blobs, little bed or lawn variation under the snow, one lone shrub in foreground; mostly flat white. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | adRainReadable | 3 | 2 | Wet flag set; snow reads as snow but no visible falling particles, road is fully snow-covered with no wet sheen or dark wet surface contrast; overcast sky is the only weather cue. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | houseVariety | 4 | 3 | Several kit families (gabled brick, apartment slab, pale siding, large flat-roof block) with mixed footprints, but facades and roof colours repeat and many roofs are the same slate grey. |
