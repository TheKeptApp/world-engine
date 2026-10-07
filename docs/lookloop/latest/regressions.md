**Owner rule (> 3 parity points, same rubric, bcd2b98 vs 71ed246):** showcase-03 87 → 83 %. Commit: `bcd2b98` (P2 house details 2/3, Chicago only); showcase-03 is the Sloan's Lake trail in rain with no Chicago houses, so noise. Last run's flags on untouched views (showcase-10, showcase-07, v2-01, wilmette-street-rain) recovered.

**Owner rule (> 3 parity points, same rubric, 71ed246 vs 792f864):** showcase-10 80 → 65 % · v2-04 87 → 79 % · showcase-05 92 → 87 % · showcase-07 77 → 72 % · v2-01 78 → 73 % · wilmette-street-rain 82 → 78 %. Commit: `71ed246` (P2 house details 1/3, North Shore only). Five of the six are Sloan's Lake views with no North Shore houses, so the change cannot reach them; wilmette-street-rain's reviewer cites wet surfaces and haze, not houses. Treated as grader noise; re-check next run.

**Owner rule (> 3 parity points, same rubric, 792f864 vs 96fd68a):** v2-06 82 → 65 % · evanston-street-rain 88 → 84 %. Commits: `5497805` (P2 Denver tree colours), `eb45154` (P1 map data layer v2). v2-06's reviewer calls the frame unchanged and lists light, haze and ground colour (5A areas); evanston-street-rain is a North Shore view the Denver change does not reach. Both treated as grader noise; re-check next run. **Resolved:** the 96fd68a Sloan's Lake regression (five views back to walk-clearance level).

**Owner rule (> 3 parity points, same rubric, 96fd68a vs a2c818b):** showcase-01 93 → 80 % · showcase-08 88 → 73 % · v2-01 81 → 70 % · showcase-11 68 → 61 % · showcase-10 69 → 65 %. Commit: `96fd68a` (P2 tree stack, species/season colours by region). **Likely real, not noise:** all five are Sloan's Lake (Denver) views, and the reviewers' palette reasons change from "coherent gold/orange/russet crowns" to "single saturated lemon yellow, no russet/orange differentiation" (palette 3 → 2 on showcase-01 and v2-01). Points at the Denver autumn crown colours from vegetation-colours.json; North Shore views do not drop. Reported to P2.

**Owner rule (> 3 parity points, same rubric, a2c818b vs c25b6dc):** showcase-10 78 → 69 % · light-rain-street 79 → 72 % · showcase-01 98 → 93 %. Commit: `a2c818b` (P2 walk clearance). showcase-10 is an aerial and showcase-01 a lake-trail view without walk-side generated trees, so clearance cannot reach them; light-rain-street's reviewer cites dry-looking ground under rain, not trees. Treated as grader noise; re-check after the tree stack.

# Look loop: regressions

This run (2026-10-06 23:45, engine `463e06c`) against the previous published run (2026-10-06 22:03, engine `c25b6dc`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**18 regression flag(s) in 9 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [showcase-01](sheets/showcase-01.jpg) | light | 4 | 3 | Long low shadows and warm rim on crowns suit golden hour, but the sky is a flat lilac with no sun glow and the ground reads dull, not warm-lit. |
| [showcase-02](sheets/showcase-02.jpg) | softnessAO | 3 | 2 | Trunk bases show little or no contact darkening; spruce has hard black wedge tiers; the bench and trunks sit on the lawn with minimal occlusion. |
| [showcase-04](sheets/showcase-04.jpg) | adRainReadable | 3 | 2 | Sky is dark and a few faint streaks and one small puddle on the path exist, but the path and grass show no wet sheen or darkening; it reads close to a dry day under a dark sky. |
| [showcase-07](sheets/showcase-07.jpg) | adRainReadable | 3 | 2 | Falling snow is barely visible (a few specks) and the dark overcast sky is the main weather cue; no wet sheen, slush or melt contrast on the path. |
| [showcase-10](sheets/showcase-10.jpg) | v2 /50 | 26.8 | 23.7 | At phone size the frame reads as a flat, desaturated map with correct lake and grid but no canopy, haze or wet readability. The biggest gap is the missing autumn tree and colour richness that carries the target. |
| [showcase-10](sheets/showcase-10.jpg) | silhouettes | 3 | 2 | Houses read as tiny uniform specks in grid blocks; no distinct crown or roof families at aerial scale, trees barely visible. |
| [showcase-10](sheets/showcase-10.jpg) | softnessAO | 3 | 2 | No visible occlusion or soft shadow; buildings and parcels look like flat extrusions. |
| [showcase-10](sheets/showcase-10.jpg) | houseVariety | 3 | 2 | Dense blocks show only a few colours at tiny size; no readable mass variety; a lone red building stands out oddly. |
| [showcase-10](sheets/showcase-10.jpg) | adRainReadable | 3 | 2 | Overall grey cast and slightly darker lake suggest wet, but no sheen, puddles or sky change is readable. |
| [showcase-11](sheets/showcase-11.jpg) | adRegional | 3 | 2 | The lake outline reads, but the surrounding Denver bungalow grid, park ring and cottonwood/conifer mix do not; the land-use pattern looks generic. |
| [ordinary-street](sheets/ordinary-street.jpg) | groundRichness | 3 | 2 | Two broad flat lawn tones with sparse identical grass tufts, a clean slab sidewalk and little leaf litter; no worn edges, patches, beds or layering in the foreground. |
| [ordinary-street](sheets/ordinary-street.jpg) | adGroundRich | 3 | 2 | Lawns are flat colour blocks with minimal tone variation, only a short row of foundation shrubs and scattered litter; hard edges between grass, verge and sidewalk. |
| [light-rain-street](sheets/light-rain-street.jpg) | v2 /50 | 30.0 | 27.6 | At phone size this reads as a calm, flat overcast autumn street with a clear dog and trees, but little rain or wet-surface mood. The biggest gap is weather readability and light: the dry-looking pale sidewalk and bright  |
| [light-rain-street](sheets/light-rain-street.jpg) | light | 3 | 2 | Flat, even overcast with no readable key or wet-sky luminance. The wall and sidewalk have almost no tonal direction, and the pale grey ground sits mid-value everywhere, so the afternoon rain mood of the targets is missin |
| [light-rain-street](sheets/light-rain-street.jpg) | groundRichness | 3 | 2 | Two large flat lawn colours with sparse identical grass tufts and a few leaf specks. A little tone variation, but no beds, worn edges or leaf litter. The ground reads as a sterile carpet. |
| [light-rain-street](sheets/light-rain-street.jpg) | adGroundRich | 3 | 2 | Foundation shrubs are present (a short row of 3-4 merged lobes) but the lawns are flat with no beds, mulch or patches, and the verge is a uniform green strip. |
| [lakeview-postcard](sheets/lakeview-postcard.jpg) | groundRichness | 3 | 2 | Large flat mauve road fills the foreground and parkway lawn is a single green; only sparse grass tufts and dark bed rectangles on the right. |
| [lakeview-postcard](sheets/lakeview-postcard.jpg) | adGroundRich | 3 | 2 | One flat lawn tone, bare beds, few shrubs and no foundation planting or leaf litter in the foreground; Lakeview should be denser. |
