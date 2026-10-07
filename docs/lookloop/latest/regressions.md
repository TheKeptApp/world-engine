**Owner rule (> 3 parity points, same rubric, b2a23a7 vs 656123f):** showcase-10 74 → 65 % · evanston-street-rain 85 → 78 % · showcase-06 85 → 78 % · v2-06 69 → 65 %. Commit: `b2a23a7` (P2 hedges). None of these frames feature hedges; reasons are aerial autumn colour, smoke haze, rain light and golden-hour warmth, so they are flagged for re-check on the next run rather than attributed to the hedges.

# Look loop: regressions

This run (2026-10-06 19:03, engine `a353b2d`) against the previous published run (2026-10-06 17:55, engine `3202e69`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**25 regression flag(s) in 16 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | palette | 3 | 2 | Autumn crown colours (russet, orange, yellow) are present, but grass is flat green/olive and the road is cool violet-grey; overall desaturated versus the warm anchor, little warm/cool coherence. |
| [v2-04](sheets/v2-04.jpg) | adRegional | 3 | 2 | Generic American street; no Front Range cues such as bungalows, cottonwoods, conifers or a western mountain band despite facing west. |
| [v2-06](sheets/v2-06.jpg) | light | 3 | 2 | Warm tint appears only on house and tree tops; ground, lake and surroundings are neutral and flat, with no visible long golden-hour shadows or warm/cool balance. |
| [showcase-03](sheets/showcase-03.jpg) | adRainReadable | 3 | 2 | Sky is dark and thin streaks are faintly visible, but the path and grass show no wet sheen and no reflective puddles; the dark blob reads as a shadow, not a puddle. |
| [showcase-06](sheets/showcase-06.jpg) | v2 /50 | 28.9 | 26.8 | At phone size the frame reads as a clean stylized lakeside park with correct autumn crowns, but the smoke is just an orange sky with little distance haze, so the saturated green lawn and crisp lake break the wildfire moo |
| [showcase-06](sheets/showcase-06.jpg) | palette | 3 | 2 | Autumn crowns (olive, gold, russet) are right, but the saturated mid-green lawn is unaffected by smoke and the sky is a flat brick-orange; the target is a restrained, uniformly hazed beige-olive. Lawn and sky fight each  |
| [showcase-06](sheets/showcase-06.jpg) | depthFog | 3 | 2 | Distant trees fade only slightly into an orange band; near, mid and far contrast barely differs for 1200 m visibility, the lake is a clear blue strip, and the horizon is crisp. The target has strong layered haze. |
| [showcase-08](sheets/showcase-08.jpg) | adRegional | 3 | 2 | Cones and bare trees with lake and distant houses read as generic park; little Front Range character, no mountain band visible (correct for ESE) and no bungalow/foursquare cues. |
| [showcase-09](sheets/showcase-09.jpg) | softnessAO | 3 | 2 | Trunk bases and bench sit on the ground with minimal contact darkening; surfaces are flat and lack the soft occlusion and rim light of the targets. |
| [showcase-10](sheets/showcase-10.jpg) | v2 /50 | 25.3 | 22.1 | At phone size this reads as a flat, desaturated map with the right lake and grid layout but little autumn colour, rain readability or building and tree character. The biggest gap is missing differentiated autumn vegetati |
| [showcase-10](sheets/showcase-10.jpg) | palette | 3 | 2 | Flat grey-teal wash with muted green blocks; the target's russet/orange/yellow autumn crowns are mostly absent, only faint speckle along the lake edge. |
| [showcase-10](sheets/showcase-10.jpg) | light | 3 | 2 | Even, flat overcast light is plausible for rain but there is no tonal modelling of rooftops or park; reads as a diffuse map rather than lit rainy afternoon. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | softnessAO | 3 | 2 | No visible darkening at trunk bases, bench or lamp; trunks look planted on a flat plane. Only the cast shadows add depth. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | adRegional | 3 | 2 | Generic park: lake, a bench and trees; no Front Range cues such as bungalows, cottonwood and conifer mix or a western mountain band (none expected facing ESE). |
| [light-rain-street](sheets/light-rain-street.jpg) | softnessAO | 3 | 2 | Little contact darkening at house base, shrub bases or trunks; the dog shadow is a detached blob |
| [wilmette-street](sheets/wilmette-street.jpg) | groundRichness | 3 | 2 | Lawns are near-uniform flat green with a hard-edged walk and few tone patches, beds or litter; sparse grass tufts only at the verge. |
| [wilmette-street](sheets/wilmette-street.jpg) | adGroundRich | 3 | 2 | Few round shrubs and one hedge, but lawns have one tone, no beds or mulch, no leaf litter, hard path edges. |
| [evanston-postcard](sheets/evanston-postcard.jpg) | softnessAO | 3 | 2 | Foreground trunk is a flat slab with no base darkening or contact; hedges and eaves show little occlusion. |
| [evanston-street](sheets/evanston-street.jpg) | groundRichness | 3 | 2 | Near-uniform green lawn strip with sparse orange leaf dabs; few tone patches, beds or worn edges |
| [evanston-street](sheets/evanston-street.jpg) | adGroundRich | 3 | 2 | Flat lawn colour, few foundation shrubs (small isolated blobs), no beds, hard grass/path edges |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | v2 /50 | 30.0 | 27.4 | At phone size the street reads as a wet suburban block with a moody sky, but lawns are flat, light is inconsistent and contact shading is missing. The biggest gap is ground richness and soft diffuse rain light compared w |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | light | 3 | 2 | Overcast midday rain but a hard-edged blob shadow sits on the sidewalk, contradicting diffuse light; dark storm sky is heavier than light rain. |
| [evanston-street-rain](sheets/evanston-street-rain.jpg) | softnessAO | 3 | 2 | Only a thin dark strip at house bases and none at trunk bases or under shrubs; trunks sit on the lawn with no contact darkening. |
| [evanston-street-winter](sheets/evanston-street-winter.jpg) | adRainReadable | 3 | 2 | Snow view flagged wet: no visible wet sheen on the road, which is covered in white, and no visible falling streaks or particles; only the dark sky reads. |
| [lakeview-street](sheets/lakeview-street.jpg) | softnessAO | 3 | 2 | Trunk bases and building foot have almost no contact darkening, the foreground trunk ends in a hard flat base on the lawn, and the facade lacks eave or step occlusion. |
