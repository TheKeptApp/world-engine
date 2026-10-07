# Look loop: latest run

Run 2026-10-07 10:12 · engine `2c8f6c5` · checkout `e29d4c9` on `p3-lookloop` · 17 views (17 rendered, 0 unchanged and reused), 17 graded · run time 7.1 min · graders `claude-sonnet-5-5`

Regression guard: **6 flag(s)** ([regressions.md](regressions.md)).

## Concept parity 86%  ·  gate passes 0/17  ·  end-of-5B gate 0/17

Milestones: end of 5A wrap ≥85%: **met** · end of 5B ≥100%: not yet. Ordinary-day parity 87%. Region buildings & ground (sil, hse, grd, AD grd; P2 target ≥ 3.5): **2.92**.

Approved-mock closeness (GRADING.md §M, 1–5): showcase-01 2, ordinary-street-afternoon 3, wilmette-street-afternoon 3, lakeview-postcard-afternoon 2, lakeview-street-afternoon 3.

Paint-over parity 96% (paintover-v1, beside the gate; view /50 ÷ its own paint-over's calibrated /50): evanston-street 104%, lakeview-street 83%, ordinary-street 93%, showcase-03 104%, showcase-06 102%, v2-06 87%.

look-fix-v1 checks (GRADING.md §H, beside the gate): 28 failed of 71 judged — LF-ground 13, LF-trees 8, LF-light 5, LF-weather 1, LF-aerial 1; 0 not checkable from a still.

Gate per view: parity ≥ 100 % of its calibrated target concept **and** v2's per-criterion floors (no §8.3 score < 3, geography ≥ 4, character ≥ 4 when scored, no hard-gate flags). End-of-5B gate adds every art-direction score ≥ 3 (look-fix §8; 10/17 meet it now). Long-term goal: v2 mean 30.4/50 against 40 · art direction 2.8/5, 10/17 at the art-direction bar.

Parity = view /50 ÷ concept /50 (docs/lookloop/calibration-scores.json). Frame time and triangles are Simulator figures from WorldLab's console: use them for change between runs, not as device performance.

| View | Parity | Gate | /50 | AD | sil | pal | lit | AO | grd | chr | fog | hse | geo | AD grd | AD rain | AD reg | Luma vs target | Tris | Frame ms | Sheet |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v2-01 | **84%** | fail (floors) · 5B ✗ | 29.5 | 3.0 | 3 | 3 | 2 | 2 | 3 | 4 | 3 | 3 | 4 | 3 | – | 3 | 0.498 | 166k | – | [sheet](sheets/v2-01.jpg) |
| v2-06 | **80%** | fail (floors) · 5B ✗ | 27.4 | 2.5 | 3 | 3 | 2 | 2 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.711 | 166k | 16.64 | [sheet](sheets/v2-06.jpg) |
| showcase-01 | **93%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.561 | 166k | 16.81 | [sheet](sheets/showcase-01.jpg) |
| showcase-03 | **90%** | fail (floors) · 5B ✗ | 30.0 | 2.67 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | 3 | 3 | 0.582 | 166k | 16.64 | [sheet](sheets/showcase-03.jpg) |
| showcase-06 | **88%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.477 | 166k | 16.56 | [sheet](sheets/showcase-06.jpg) |
| ordinary-street | **87%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | 3 | 3 | 3 | 4 | 2 | – | 3 | 0.528 | 166k | – | [sheet](sheets/ordinary-street.jpg) |
| ordinary-street-afternoon | – | fail · 5B ✗ | 31.9 | 3.0 | 3 | 3 | 3 | 3 | 3 | 4 | 3 | 3 | 4 | 3 | – | 3 | 0.45 | 166k | 16.67 | [sheet](sheets/ordinary-street-afternoon.jpg) |
| wilmette-street | **91%** | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.657 | 172k | – | [sheet](sheets/wilmette-street.jpg) |
| wilmette-street-afternoon | – | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.531 | 172k | 16.58 | [sheet](sheets/wilmette-street-afternoon.jpg) |
| wilmette-street-fall | **83%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.653 | 172k | – | [sheet](sheets/wilmette-street-fall.jpg) |
| wilmette-aerial | – | fail · 5B ✗ | 32.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 4 | 4 | 3 | – | 3 | 0.771 | 172k | 16.72 | [sheet](sheets/wilmette-aerial.jpg) |
| evanston-street | **86%** | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.633 | 76k | – | [sheet](sheets/evanston-street.jpg) |
| evanston-street-rain | **88%** | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | 3 | 3 | 0.607 | 76k | – | [sheet](sheets/evanston-street-rain.jpg) |
| lakeview-postcard | **86%** | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.601 | 232k | – | [sheet](sheets/lakeview-postcard.jpg) |
| lakeview-postcard-afternoon | – | fail (floors) · 5B ✗ | 30.0 | 3.0 | 3 | 3 | 3 | 2 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.548 | 232k | 16.61 | [sheet](sheets/lakeview-postcard-afternoon.jpg) |
| lakeview-street | **80%** | fail (floors) · 5B ✗ | 28.9 | 2.5 | 3 | 3 | 3 | 2 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.566 | 232k | 16.69 | [sheet](sheets/lakeview-street.jpg) |
| lakeview-street-afternoon | – | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.57 | 232k | 16.72 | [sheet](sheets/lakeview-street-afternoon.jpg) |

## Criterion means

| sil | pal | lit | AO | grd | chr | fog | hse | geo | AD grd | AD rain | AD reg |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3.0 | 3.0 | 2.88 | 2.76 | 2.59 | 3.67 | 3.0 | 3.06 | 4.0 | 2.59 | 3.0 | 3.0 |

## Most-cited fix areas (top fix 3 pts, second 2, third 1)

- **ground** (28 pts): v2-01: Add leaf litter piles at the trunk bases and sidewalk edges, foundation beds with mulch, and soft contact darkening around trunk bases and the dog.; v2-06: Vary field and parcel tones (green/ochre/straw patches, soft low-frequency tint), and give the park lawns, tree rows and path edges stronger tone separation.; showcase-01: Add lawn tone patches, worn edges, foundation-style shrub masses and leaf litter under the crowns, and warm the path
- **light** (22 pts): v2-01: Add a warm low-angle key with long soft shadows falling toward the camera and right (bearing 73 deg) from trunks, house and dog, with warm lit and cool shaded sides.; v2-06: Add warm low-sun grading with raking shadows from the west-southwest, warm highlights on roofs and crowns, cool shaded sides, and a sun glitter patch on the lake's west shore.; ordinary-street: Raise saturation and warm/cool contrast: warmer sunlit surfaces, cooler blue-violet shadows, brighter highlights on walk and wall
- **vegetation** (14 pts): showcase-03: Vary crown size and shape, merge lobes into unequal masses and add contact darkening at trunk bases.; ordinary-street: Vary crown size, shape and openness by family with trunk-base contact darkening; add foundation shrubs as merged lobes; wilmette-street: Vary crown size, shape and open/closed families, and shift foliage from lime to a deeper olive-green with some russet-leaning oak; stop repeating identical spheres.
- **buildings** (12 pts): ordinary-street-afternoon: Give the near house a warm brick or clapboard colour with cream corner boards, window casings, an eave band and a dark plinth, and stronger sunlit/shaded wall contrast.; wilmette-street-afternoon: Shift the main house siding toward muted sage/grey with cream trim and darker slate roofs; lakeview-postcard: Raise near facades to taller three-flat masses with stone bases, stoops and bays, as in the target
- **sky** (9 pts): showcase-01: Shift the sky from violet to a warm gradient with a pale gold horizon glow and soft haze at the tree line; showcase-06: Shift smoke sky and haze from saturated orange-brown to the paint-over's grey-beige with a faint warm tint, lighter near the horizon; ordinary-street-afternoon: Brighten and saturate the sky with white cumulus and a cleaner, warmer sun key and lower haze.
- **fog** (6 pts): showcase-06: Add distinct near/mid/far haze steps and a hazed lake with a visible shoreline edge; wilmette-aerial: Add gentle aerial haze with a warm-to-cool tint so the far blocks desaturate and lighten with distance; evanston-street-rain: Add rain haze that lowers contrast of mid and far houses and trees

## Top fixes per lane (top fix 3 pts, second 2, third 1)

**5A**
- light (22 pts): v2-01: Add a warm low-angle key with long soft shadows falling toward the camera and right (bearing 73 deg) from trunks, house and dog, with warm lit and cool s; v2-06: Add warm low-sun grading with raking shadows from the west-southwest, warm highlights on roofs and crowns, cool shaded sides, and a sun glitter patch on ; ordinary-street: Raise saturation and warm/cool contrast: warmer sunlit surfaces, cooler blue-violet shadows, brighter highlights on walk and wall
- sky (9 pts): showcase-01: Shift the sky from violet to a warm gradient with a pale gold horizon glow and soft haze at the tree line; showcase-06: Shift smoke sky and haze from saturated orange-brown to the paint-over's grey-beige with a faint warm tint, lighter near the horizon; ordinary-street-afternoon: Brighten and saturate the sky with white cumulus and a cleaner, warmer sun key and lower haze.
- fog (6 pts): showcase-06: Add distinct near/mid/far haze steps and a hazed lake with a visible shoreline edge; wilmette-aerial: Add gentle aerial haze with a warm-to-cool tint so the far blocks desaturate and lighten with distance; evanston-street-rain: Add rain haze that lowers contrast of mid and far houses and trees
- weather (5 pts): showcase-03: Raise wet sheen on the path with sky and tree reflections and darken the grass and trunks.; evanston-street-rain: Darken and desaturate grass, sidewalk and verge under rain, add soft sheen on the sidewalk and larger sky-reflecting puddles on the road e
- water (4 pts): v2-06: Make the lake a deeper saturated blue-teal with a gradient from shore to centre, a light sky-reflection band and a faint glitter, and a clearer shore edg; showcase-01: Give the lake the mock's blue-teal body colour, a lighter shallow band at the shore, soft sky reflection and warm glitter streaks toward the sun

**P2** (ground and vegetation shared with 5A for material and LOD)
- ground (28 pts): v2-01: Add leaf litter piles at the trunk bases and sidewalk edges, foundation beds with mulch, and soft contact darkening around trunk bases and the dog.; v2-06: Vary field and parcel tones (green/ochre/straw patches, soft low-frequency tint), and give the park lawns, tree rows and path edges stronger tone separat; showcase-01: Add lawn tone patches, worn edges, foundation-style shrub masses and leaf litter under the crowns, and warm the path
- vegetation (14 pts): showcase-03: Vary crown size and shape, merge lobes into unequal masses and add contact darkening at trunk bases.; ordinary-street: Vary crown size, shape and openness by family with trunk-base contact darkening; add foundation shrubs as merged lobes; wilmette-street: Vary crown size, shape and open/closed families, and shift foliage from lime to a deeper olive-green with some russet-leaning oak; stop repeati
- buildings (12 pts): ordinary-street-afternoon: Give the near house a warm brick or clapboard colour with cream corner boards, window casings, an eave band and a dark plinth, and st; wilmette-street-afternoon: Shift the main house siding toward muted sage/grey with cream trim and darker slate roofs; lakeview-postcard: Raise near facades to taller three-flat masses with stone bases, stoops and bays, as in the target


## Per-view summaries

- **v2-01** (29.5/50): At phone size the street reads as a tidy low-poly autumn boulevard with good crown colours and a clear dog, but the lighting is flat and cool with no cast shadows against a golden-hour target. The biggest gap is the missing warm low-sun key and shadows, which also leaves the palette desaturated and the ground without contact shadow. _vs previous: better: slightly lighter and warmer (mean R +12), with minor scene change._
- **v2-06** (27.4/50): At phone size the scene has the right layout but is flat, desaturated and unlit, reading as a grey-beige map rather than a golden-hour aerial. The biggest gap against the paint-over is light and colour: no warm raking sun, shading or lake glint. _vs previous: unchanged: pixel change 1.7 percent, same luma, saturation and colour; no visible difference._
- **showcase-01** (30.0/50): A readable autumn lake trail with coherent low sun and good gold crown colour, but flat lawn, a dull grey lake and a violet sky keep it near baseline. The biggest gap is the lake and ground richness against the mock. _vs previous: unchanged: histograms and pixels differ by about 1 % from the previous run._
- **showcase-03** (30.0/50): At phone size this is a coherent but flat, minty-green rain scene with readable autumn crowns and a stormy sky. The biggest gap is the sterile lawn and matte path, which lack the wet richness of the paint-over. _vs previous: unchanged: near-identical frame (pixel change 0.97, luma +0.0)._
- **showcase-06** (30.0/50): At phone size the park reads as a stylized autumn smoke scene with good crown colour variety, but a saturated orange wash and a flat lawn separate it from the neutral beige paint-over. The biggest gap is sky/haze colour, followed by empty ground. _vs previous: unchanged: pixel change 0.69 percent, same orange cast and flat lawn._
- **ordinary-street** (30.0/50): At phone size this is a clean but flat stylized autumn street: muted colour, flat lawns and a black dog silhouette. The biggest gap against the paint-over is ground richness and colour/light saturation. _vs previous: unchanged: pixel change 1.01 with luma, saturation and edge deltas near zero_
- **ordinary-street-afternoon** (31.9/50): At phone size the street reads as autumn Denver with coherent light, but it is washed out, with a plain grey house and flat lawns. The biggest gap is house colour and trim contrast plus lawn colour against the approved mock. _vs previous: no previous: view is new in this run._
- **wilmette-street** (31.1/50): At phone size a clean, warm-lit tree-lined North Shore street that is coherent but simple, with repeated lime crowns and flat lawns. The biggest gap is vegetation colour and variety against the target. _vs previous: unchanged: near-identical to the previous run._
- **wilmette-street-afternoon** (31.1/50): Reads as a clean stylized North Shore street at phone size, but warmer and more saturated than the mock. Biggest gap is orange walls and neon lawn with no cool shade or dappling. _vs previous: no previous: first run of this twin view_
- **wilmette-street-fall** (30.0/50): At phone size the street reads as a clean stylized fall scene with strong orange crowns, but the flat saturated lawn and cool flat light keep it below the warm anchor. The biggest gap is the sterile ground. _vs previous: unchanged: pixel change 1.1 percent, same read._
- **wilmette-aerial** (32.1/50): A dense, readable fall suburb at phone size with a consistent sun and varied houses, but flat in depth and with candy-saturated, repeated sphere crowns over summer-green lawns. The biggest gap is the missing atmospheric depth and varied, russet-toned crowns against the anchor. _vs previous: unchanged: pixel change 2.26 %, luma and colour histograms near identical to the 2026-10-07 09:15 run._
- **evanston-street** (31.1/50): At phone size the street reads as a plausible fall afternoon with good orange canopy, but the mint-green flat lawns, low contrast light and the big trunk slab in the foreground keep it well short of the paint-over. The biggest gap is the ground colour and richness, which is cold and flat against the warm canopy. _vs previous: unchanged: previous run frame is virtually identical (pixel change 1.07, dLuma +0.1)._
- **evanston-street-rain** (31.1/50): At phone size the street reads as a rainy suburban block with a dark sky, but the bright flat green lawns and dry-looking sidewalk undercut the weather. The biggest gap is wet ground response and rain haze compared with the target. _vs previous: unchanged: near-identical frame (pixel change 1.07 %), same sky, lawns and puddles._
- **lakeview-postcard** (31.1/50): At phone size the street reads as a pleasant warm stylized Chicago parkway but with low boxy houses, lime sphere crowns and a pink-lavender cast. The biggest gap against the target is the missing tall three-flat masses and the blue-sky colour balance. _vs previous: unchanged: pixel change about 1 percent, same look as the previous run._
- **lakeview-postcard-afternoon** (30.0/50): At phone size a clean, readable stylized Lakeview street with correct sun direction, but flat in light and ground: faint shadows, uniform green, and no contact darkening. The biggest gap is shadow and light contrast, with crown colour variety and facade richness close behind. _vs previous: no previous: first run of this twin view._
- **lakeview-street** (28.9/50): At phone size the street reads as a clean, calm Lakeview block but looks flat next to the paint-over, with muted colour, weak golden-hour light and no ground contact shading. The biggest gap is the lack of warm low-sun lighting and cast shadows. _vs previous: unchanged: pixel change 0.96 and luma and saturation within 1 point._
- **lakeview-street-afternoon** (31.1/50): At phone size the street is readable and coherent with trees, stoops and a sunlit road, but colour is washed: tan walls, pale mint lawn, hazy sky. The biggest gap is the missing saturated red brick and clear blue sky of the approved mock. _vs previous: no previous: first run of this view_

Overview of all frames: [overview.jpg](overview.jpg). Raw grades and signals: [grades.json](grades.json).
