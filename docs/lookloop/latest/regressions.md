**Owner rule (> 3 parity points, same rubric, 393ed1e vs d373566):** v2-01 81 → 72 % · lakeview-street 86 → 80 % · light-rain-street 81 → 76 % · showcase-08 90 → 85 % · v2-06 69 → 65 %. Commit: `393ed1e` (P2 trees 1/4, crowns and trunks). lakeview-street's reviewer names a floating foreground trunk with no contact darkening (trees 3/4 target); v2-01 cites flat light and ground; the others are within the swing seen run to run. Re-check after trees 2/4.

# Look loop: regressions

This run (2026-10-06 20:44, engine `b8ee81a`) against the previous published run (2026-10-06 19:45, engine `babcfe4`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**26 regression flag(s) in 13 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | v2 /50 | 28.6 | 25.2 | At phone size the frame is a flat, hazy and desaturated street with good autumn tree colours but no golden-hour light, shadow or warmth on the ground and house. The biggest gap is light: there is no warm key and no shado |
| [v2-01](sheets/v2-01.jpg) | palette | 3 | 2 | Autumn crowns are differentiated, but the ground is desaturated olive and grey-green, the sidewalk is grey-lilac and the house is flat pink-beige; far from the warm golden-hour anchor, saturation -74 vs target. |
| [v2-01](sheets/v2-01.jpg) | characterReadability | 4 | 3 | Dog is a near-black glossy silhouette, readable on the pale walk and contact is intact, but it reads as black with a grey patch rather than a coat, and is small (about 15% of frame height). |
| [v2-01](sheets/v2-01.jpg) | houseVariety | 3 | 2 | Near house is a single plain box with stock windows and no porch or steps; distant houses are a repeated long yellow block. |
| [v2-06](sheets/v2-06.jpg) | palette | 3 | 2 | Muted grey-beige and desaturated blue water with a dull olive park ring; saturation is far below the golden-hour target and the autumn colour is only in small speckles. |
| [showcase-02](sheets/showcase-02.jpg) | softnessAO | 3 | 2 | Trunk bases have almost no contact darkening and the spruce has hard black wedges between tiers; the bench and path edges lack occlusion. |
| [showcase-03](sheets/showcase-03.jpg) | adRainReadable | 3 | 2 | Dark sky and faint rain streaks, one small puddle on the path; the path is not visibly glossy and the grass does not darken, so a dry day is only slightly different. |
| [showcase-08](sheets/showcase-08.jpg) | light | 4 | 3 | One low sun with long soft shadows streaking the path, warm glint on the right; coherent, but the warm/cool contrast is weak and the sun is a small white dot. |
| [showcase-08](sheets/showcase-08.jpg) | groundRichness | 3 | 2 | Large flat snow and olive-grey lawn planes with a plain pale path; few tone patches, sparse tiny grass tufts, no melt patches or shrubs; the path has odd faceted shading. |
| [showcase-09](sheets/showcase-09.jpg) | depthFog | 3 | 2 | Lake is a thin dark strip at right with no shoreline separation or moon glitter; horizon band is a flat dark line of tiny houses; little night haze layering. |
| [light-rain-street](sheets/light-rain-street.jpg) | v2 /50 | 31.0 | 29.0 | At phone size the street reads as a tidy autumn street under a storm sky, but the walk and lawns look dry and bright. The biggest gap is rain readability and ground richness. |
| [light-rain-street](sheets/light-rain-street.jpg) | softnessAO | 3 | 2 | Shrubs and trunk bases have little contact darkening; building foundation is a hard dark band and the dog has only a faint shadow. |
| [light-rain-street](sheets/light-rain-street.jpg) | groundRichness | 3 | 2 | Two flat lawn colours, sparse repeated grass tufts and very little leaf litter; sidewalk is clean and uniform. |
| [light-rain-street](sheets/light-rain-street.jpg) | adGroundRich | 3 | 2 | Only a few foundation shrubs; lawn is flat colour patches with sparse tufts and no beds, worn edges or litter. |
| [wilmette-street](sheets/wilmette-street.jpg) | groundRichness | 3 | 2 | Foreground lawn is two near-flat green bands with a hard-edged grey slab path; no tone patches, beds or litter at phone size; sparse grass tufts only. |
| [wilmette-street](sheets/wilmette-street.jpg) | adGroundRich | 3 | 2 | Some foundation shrubs on the far houses, but the near lawn is flat with no beds, worn edges or leaf litter; hard path edges. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | groundRichness | 3 | 2 | Foreground lawn is large flat bands of near-identical green with hard edges and a bare paving strip; little tone variation, no beds or litter. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | adRainReadable | 3 | 2 | Road shows a slight cool sheen and sky is dark with faint streaks, but sidewalk and grass are not visibly wet, no puddles or reflections. |
| [evanston-postcard](sheets/evanston-postcard.jpg) | geography | 4 | 3 | Street runs east with sun behind the camera at 268 deg; shadows fall away/forward as expected, but the shadow bearing is hard to confirm from the stripes on the road, so something is doubtful but not clearly wrong. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | softnessAO | 3 | 2 | Little darkening at trunk bases or under eaves; foreground trunk and shrubs sit with weak contact shading. |
| [lakeview-street](sheets/lakeview-street.jpg) | v2 /50 | 31.1 | 28.9 | At phone size the street reads as a plausible Lakeview golden-hour scene with correct bearing, but it is flat and desaturated with a big plain wall and flat lawns. The biggest gap is ground richness and contact shading,  |
| [lakeview-street](sheets/lakeview-street.jpg) | softnessAO | 3 | 2 | Foreground trunk ends in a hard cut above the lawn with no contact darkening (reads floating); no occlusion at the building base or steps. |
| [lakeview-street](sheets/lakeview-street.jpg) | groundRichness | 3 | 2 | Lawns are near-flat single tones with hard edges; only a few tufts and low hedges; no litter or patches. |
| [lakeview-street](sheets/lakeview-street.jpg) | adGroundRich | 3 | 2 | Single-tone lawns, a few foundation shrubs in the distance, no beds, no patches or worn edges in the foreground. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | groundRichness | 3 | 2 | Lawns are mostly one flat green with little tone variation, no leaf litter, no visible beds; sidewalks and asphalt are clean and sterile. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | adGroundRich | 3 | 2 | Some lawn patches and a few trees along the street, but flat green with no beds, shrubs, worn edges or leaf litter under crowns. |
