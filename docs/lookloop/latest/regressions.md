# Look loop: regressions

This run (2026-10-06 17:55, engine `3202e69`) against the previous published run (2026-10-06 17:24, engine `ec7a62a`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**37 regression flag(s) in 14 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-04](sheets/v2-04.jpg) | softnessAO | 3 | 2 | Dark band at house base and a few shrubs have contact darkening, but trunks meet the lawn with no base darkening and the house base is a hard dark slab; no eave or crown occlusion. |
| [v2-06](sheets/v2-06.jpg) | v2 /50 | 30.0 | 23.7 | At phone size the aerial reads as a flat, desaturated map with a warm speckled neighbourhood, not a golden-hour scene. The biggest gap is colour and ground richness across the large grey-beige context. |
| [v2-06](sheets/v2-06.jpg) | silhouettes | 3 | 2 | Houses are small boxes with orange speckle crowns; no roof or tree families readable at aerial scale, outer blocks are flat grey slabs. |
| [v2-06](sheets/v2-06.jpg) | palette | 3 | 2 | Surroundings are a desaturated beige-grey wash with muddy olive fields; only the east neighbourhood carries autumn orange. Saturation about 53 vs target 134; lake is flat grey-blue. |
| [v2-06](sheets/v2-06.jpg) | groundRichness | 3 | 2 | Large flat grey-beige plane with a grid of road lines; park around the lake is a flat olive green with little tone variation. |
| [v2-06](sheets/v2-06.jpg) | depthFog | 3 | 2 | Shore is continuous, but the distance is flat with no atmospheric gradient or warm haze, and no focus/depth separation as in the target. |
| [v2-06](sheets/v2-06.jpg) | houseVariety | 3 | 2 | East blocks show many small similar lots with some tone variety; west and outer areas are uniform grey boxes. Little mass or family variety visible. |
| [showcase-04](sheets/showcase-04.jpg) | v2 /50 | 30.0 | 27.4 | At phone size the stormy sky is convincing but the lawn and path stay bright and flat, so the scene does not read as a wet thunderstorm. The biggest gap is ground-level storm lighting and wet response, plus a flat single |
| [showcase-04](sheets/showcase-04.jpg) | light | 3 | 2 | Sky is dark and stormy but the ground is lit as if under flat bright light; the lawn is as bright as a fair day, so the scene contradicts the thunderstorm sky. Target is uniformly dim and cool. |
| [showcase-04](sheets/showcase-04.jpg) | softnessAO | 3 | 2 | Trunk bases have little contact darkening and the lawn is flat; the only dark marks are blobby shadow shapes on the path. |
| [showcase-05](sheets/showcase-05.jpg) | depthFog | 4 | 3 | Trees fade with distance and the horizon dissolves into haze, but near-to-mid contrast is nearly uniform and the sky is a flat grey wall. |
| [showcase-06](sheets/showcase-06.jpg) | softnessAO | 3 | 2 | Trunks sit on the lawn with little visible contact darkening and no under-crown shade; bench and spruce have no grounding. |
| [showcase-08](sheets/showcase-08.jpg) | groundRichness | 3 | 2 | Large smooth snow and grey-olive lawn planes with a few patches; no shrubs, litter or tone variation in the foreground, so the ground feels sterile. |
| [showcase-08](sheets/showcase-08.jpg) | adRainReadable | 3 | 2 | Wet surface only shows as a sun sheen on the lake side snow; no puddles, no darker wet walk contrast, and the sky has no post-snow clearing character. |
| [showcase-10](sheets/showcase-10.jpg) | depthFog | 3 | 2 | Top of frame is as crisp as the bottom with no atmospheric falloff; far blocks are flat and the world edge reads as a tiled plane. |
| [ordinary-street](sheets/ordinary-street.jpg) | v2 /50 | 31.0 | 29.0 | At phone size this is a tidy but flat and desaturated stylized street, with a good autumn tree palette but sterile lawns and a black cutout dog. The biggest gap is ground richness and contact softness against the warm, l |
| [ordinary-street](sheets/ordinary-street.jpg) | softnessAO | 3 | 2 | Foundation shrubs have weak contact, the black dog has barely any ground contact shadow, and the trunk bases show no occlusion. |
| [ordinary-street](sheets/ordinary-street.jpg) | groundRichness | 3 | 2 | Two near-uniform lawn colours with sparse identical grass tufts; the sidewalk is a clean grey strip with only a few specks of litter; no patches, worn edges or beds. |
| [ordinary-street](sheets/ordinary-street.jpg) | adGroundRich | 3 | 2 | Only a few foundation shrub lumps by the house; lawns lack tone patches, there are no beds or fence plantings, and almost no leaf litter under the autumn crowns. |
| [light-rain-street](sheets/light-rain-street.jpg) | groundRichness | 3 | 2 | Two flat lawn colours, sparse repeated grass tufts, very little litter; no leaf litter under crowns, no visible wet streaks on the walk. |
| [light-rain-street](sheets/light-rain-street.jpg) | houseVariety | 3 | 2 | One large plain box nearby and a similar cream block with identical window grid in the distance; no porches or roof families visible. |
| [light-rain-street](sheets/light-rain-street.jpg) | adGroundRich | 3 | 2 | Flat lawn colours, a few foundation shrubs, no beds, worn edges or leaf litter; hard lawn/walk edge. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | v2 /50 | 31.1 | 28.4 | At phone size it reads as a clean stylized rainy suburban street with a dark sky and wet road, but flat lawns and hard shadows under overcast keep it below the target. The biggest gap is light and contact softness. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | light | 3 | 2 | Heavy overcast sky yet crisp blob tree shadows on the sidewalk contradict diffuse rain light; overall exposure is flat. |
| [wilmette-street-rain](sheets/wilmette-street-rain.jpg) | softnessAO | 3 | 2 | Little contact darkening at trunk bases, shrubs and house foundations; shrubs look pasted on the lawn. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | v2 /50 | 36.3 | 32.6 | At phone size this is a coherent warm peak-fall suburban oblique with a good colour mix and clear block structure, but flat light, a bright uniform lawn green and repetitive lollipop crowns hold it near the middle. The b |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | silhouettes | 4 | 3 | Roof families (gables, hips, garages) and crown colours differ, but crowns are repeated two-to-three-ball stacks on thin poles and many look alike; teal conifers are the only other archetype. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | light | 4 | 3 | One coherent warm afternoon key with soft shadows falling away to the upper right, consistent with the 40.6 deg bearing; exposure is a little flat and neutral, without the anchor's warm/cool contrast or a lit-versus-shad |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | houseVariety | 4 | 3 | Several kit families (brick two-storey with gabled bays, hip bungalows, small garages) in varied orientations; roofs are mostly the same slate grey and wall colours repeat. |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | adRegional | 4 | 3 | Tight North Shore grid with brick houses, alleys and a mixed autumn canopy reads as Chicago suburb from the air; tree mix is generic and no lake or other regional anchor is visible. |
| [evanston-postcard](sheets/evanston-postcard.jpg) | groundRichness | 3 | 2 | Large flat grass verges and a single smooth road; only sparse tufts, no lawn tone patches, beds or leaf litter in the foreground. |
| [evanston-postcard](sheets/evanston-postcard.jpg) | adGroundRich | 3 | 2 | Hedges are present, but lawns are one flat colour with hard edges and no beds or foundation planting in the foreground. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | groundRichness | 3 | 2 | Lawns are near-uniform flat green with no tone patches, litter or beds; the sidewalk is clean grey with only slab joints; only the road has some puddle patches. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | adGroundRich | 3 | 2 | One flat lawn colour, a few small shrub clumps, no beds, no worn edges and hard grass-to-path edges. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | v2 /50 | 31.1 | 28.9 | At phone size the frame reads as a clean but flat overcast snow street with plain trunks and a sterile white ground. The biggest gap is ground and planting richness (shrubs, tan lawn patches, contact shading) against the |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | softnessAO | 3 | 2 | Trunks are plain grey prisms with no base darkening, and the foreground trunk is a flat slab; foundations and shrubs have weak contact shading. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | groundRichness | 3 | 2 | Snow is a mostly uniform white sheet with a few dark soft blotches and sparse grass tufts; no patchy melt, tan lawn or leaf litter as in the target. |

## Same-grader check (Sonnet, §S + §V): ec7a62a → 656123f

| View | Before | Now | Commit |
|---|---|---|---|
| [v2-06](sheets/v2-06.jpg) | 27.9 | 23.7 (−4.2) | `656123f` (P2 ground pass 3, the only engine change). Steep aerial where 0.3–0.7 m walk strips are sub-pixel; this view has swung 22–28 across runs, so likely spread. |
