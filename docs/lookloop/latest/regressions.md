# Look loop: regressions

This run (2026-10-06 15:38, engine `bed615b`) against the previous published run (2026-10-06 14:28, engine `24491e5`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**20 regression flag(s) in 10 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [showcase-06](sheets/showcase-06.jpg) | softnessAO | 3 | 2 | Trunks and the bench sit on the lawn with little contact shading; the path edge is a hard flat shape and crowns have no underside occlusion. |
| [showcase-08](sheets/showcase-08.jpg) | groundRichness | 3 | 2 | Large smooth snow and grey-olive planes with a few thin tufts; no tan dormant-lawn patches, no beds or shrubs, and the path is a featureless pale slab with no seams. |
| [showcase-09](sheets/showcase-09.jpg) | v2 /50 | 30.0 | 27.9 | At phone size this is a calm, coherent but dark and flat moonlit park: correct layout and Moon position, but no warm accents, lake glitter or ground richness. The biggest gap is the flat, uniform ground and lack of light |
| [showcase-09](sheets/showcase-09.jpg) | softnessAO | 3 | 2 | Trunks and the bench sit on the ground with no visible contact darkening; the conifer base and path edges look pasted on flat ground. |
| [showcase-09](sheets/showcase-09.jpg) | houseVariety | 3 | 2 | Only a thin row of tiny dark red-brown roofs on the horizon, with no lit windows; houses cannot be told apart at phone size. |
| [showcase-11](sheets/showcase-11.jpg) | geography | 4 | 3 | The lake shape and north-up layout broadly resemble Sloan's Lake with the island, but the blocky rectangular detail boundary and the street-grid scale in the ring are doubtful. Shadows are too soft to check the 308 degre |
| [ordinary-street](sheets/ordinary-street.jpg) | groundRichness | 3 | 2 | Lawns are near-flat colour with sparse identical grass tufts; large flat green carpet right of the walk, no beds, worn edges or leaf litter beyond a few specks. |
| [ordinary-street](sheets/ordinary-street.jpg) | characterReadability | 4 | 3 | Black dog reads against the pale walk with contact intact, but it is small (~15% of frame height, below 20-25%) and almost a silhouette with little coat detail. |
| [ordinary-street](sheets/ordinary-street.jpg) | adGroundRich | 3 | 2 | Two lawn tones and a few foundation shrubs, but the right lawn is a flat green plane and the left bush is a lone blob; no planting beds, worn edges or leaf litter. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | v2 /50 | 31.1 | 28.9 | At phone size this is a clean stylized rain street with a dark sky, but the lawn is flat and dry-looking and the houses are flat. The biggest gap is weak rain readability and ground richness compared with the North Shore |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | softnessAO | 3 | 2 | Houses and trunks sit on lawn with little base or eave occlusion; one hard blob shadow on the walk is odd under overcast |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | groundRichness | 3 | 2 | Large flat lawn in one tone, plain walks, few small shrubs along the far foundations, no beds or streaks |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | adGroundRich | 3 | 2 | Mostly one lawn colour with a few small shrubs; no beds, worn edges, shade tone or litter |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | adRainReadable | 3 | 2 | Dark sky and a slightly sheened road read as weather, but walks and lawn look dry, no puddles, and streaks are barely visible |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | groundRichness | 3 | 2 | Large near-uniform white snow plane, one olive shadow blob and a few tiny sprigs; no patchy snow, no exposed lawn, no litter, quiet sidewalk is just a seam. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | adGroundRich | 3 | 2 | One flat snow tone with a few foundation shrubs on the left; no patchy lawn, beds or fences, hard-edged walk. |
| [evanston-aerial](sheets/evanston-aerial.jpg) | houseVariety | 4 | 3 | Several kit families (brick two-storey, gabled, apartment) but repetitive roof colours and similar massing across the block. |
| [lakeview-street](sheets/lakeview-street.jpg) | groundRichness | 3 | 2 | Lawns are near-uniform flat green with only a few sparse tufts; no patches, worn edges or leaf litter; road and walk are plain. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | houseVariety | 4 | 3 | Several kit families (courtyard blocks, rowhouses, gabled houses, a teal-roofed one) read; many large brick boxes look alike. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | adRegional | 4 | 3 | Dense Chicago grid with alleys, brick courtyard blocks and street trees in fall colours read as Lakeview; the three-flat and greystone character is thin. |

## Same-grader check (Sonnet, §S, ccb5f77 frames → bed615b)

| View | Before (ccb5f77) | Now (bed615b) | Commit |
|---|---|---|---|
| [v2-06](sheets/v2-06.jpg) | 25.3 | 22.1 (−3.2) | Since 1c15fba (5A dcd3eb6/1c15fba range); bed615b (greener ring) did not recover it. |
| [showcase-08](sheets/showcase-08.jpg) | 32.6 | 28.9 (−3.7) | One of 35827f6..bed615b (5A rain/snow/saturation merges, P2 side walls); within ±3 of 1c15fba, so check whether it is grader noise before acting. |
