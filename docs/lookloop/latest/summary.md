# Look loop: latest run

Run 2026-10-07 09:15 · engine `4263b3f` · checkout `4263b3f` on `p3-lookloop` · 13 views (13 rendered, 0 unchanged and reused), 13 graded · run time 9.7 min · graders `claude-sonnet-5-5`

Regression guard: **10 flag(s)** ([regressions.md](regressions.md)).

## Concept parity 84%  ·  gate passes 0/13  ·  end-of-5B gate 0/13

Milestones: end of 5A wrap ≥85%: not yet · end of 5B ≥100%: not yet. Ordinary-day parity 87%. Region buildings & ground (sil, hse, grd, AD grd; P2 target ≥ 3.5): **2.68**.

Approved-mock closeness (GRADING.md §M, 1–5): showcase-01 2, ordinary-street 3, wilmette-street 3, lakeview-postcard 2, lakeview-street 3.

Paint-over parity 93% (paintover-v1, beside the gate; view /50 ÷ its own paint-over's calibrated /50): evanston-street 104%, lakeview-street 83%, ordinary-street 93%, showcase-03 104%, showcase-06 102%, v2-06 73%.

look-fix-v1 checks (GRADING.md §H, beside the gate): 27 failed of 55 judged — LF-ground 13, LF-trees 6, LF-light 4, LF-weather 3, LF-aerial 1; 0 not checkable from a still.

Gate per view: parity ≥ 100 % of its calibrated target concept **and** v2's per-criterion floors (no §8.3 score < 3, geography ≥ 4, character ≥ 4 when scored, no hard-gate flags). End-of-5B gate adds every art-direction score ≥ 3 (look-fix §8; 4/13 meet it now). Long-term goal: v2 mean 29.8/50 against 40 · art direction 2.69/5, 4/13 at the art-direction bar.

Parity = view /50 ÷ concept /50 (docs/lookloop/calibration-scores.json). Frame time and triangles are Simulator figures from WorldLab's console: use them for change between runs, not as device performance.

| View | Parity | Gate | /50 | AD | sil | pal | lit | AO | grd | chr | fog | hse | geo | AD grd | AD rain | AD reg | Luma vs target | Tris | Frame ms | Sheet |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v2-01 | **81%** | fail (floors) · 5B ✗ | 28.6 | 3.0 | 3 | 3 | 2 | 2 | 3 | 3 | 3 | 3 | 4 | 3 | – | 3 | 0.483 | 166k | – | [sheet](sheets/v2-01.jpg) |
| v2-06 | **68%** | fail (floors) · 5B ✗ | 23.2 | 2.5 | 3 | 2 | 2 | 2 | 2 | – | 2 | 2 | 4 | 2 | – | 3 | 0.711 | 166k | 16.61 | [sheet](sheets/v2-06.jpg) |
| showcase-01 | **93%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.561 | 166k | 16.56 | [sheet](sheets/showcase-01.jpg) |
| showcase-03 | **90%** | fail (floors) · 5B ✗ | 30.0 | 2.33 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | 2 | 3 | 0.582 | 166k | 16.75 | [sheet](sheets/showcase-03.jpg) |
| showcase-06 | **88%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.477 | 166k | 16.67 | [sheet](sheets/showcase-06.jpg) |
| ordinary-street | **87%** | fail (floors) · 5B ✗ | 30.0 | 3.0 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 2 | 4 | 3 | – | 3 | 0.527 | 166k | – | [sheet](sheets/ordinary-street.jpg) |
| wilmette-street | **88%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.657 | 172k | – | [sheet](sheets/wilmette-street.jpg) |
| wilmette-street-fall | **83%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.653 | 172k | – | [sheet](sheets/wilmette-street-fall.jpg) |
| wilmette-aerial | – | fail · 5B ✗ | 35.3 | 3.5 | 3 | 4 | 4 | 3 | 3 | – | 3 | 4 | 4 | 3 | – | 4 | 0.771 | 172k | 16.67 | [sheet](sheets/wilmette-aerial.jpg) |
| evanston-street | **86%** | fail · 5B ✗ | 31.1 | 3.0 | 3 | 3 | 3 | 3 | 3 | – | 3 | 3 | 4 | 3 | – | 3 | 0.633 | 76k | – | [sheet](sheets/evanston-street.jpg) |
| evanston-street-rain | **85%** | fail (floors) · 5B ✗ | 30.0 | 2.67 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | 3 | 3 | 0.605 | 76k | – | [sheet](sheets/evanston-street-rain.jpg) |
| lakeview-postcard | **83%** | fail (floors) · 5B ✗ | 30.0 | 2.5 | 3 | 3 | 3 | 3 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.601 | 232k | – | [sheet](sheets/lakeview-postcard.jpg) |
| lakeview-street | **80%** | fail (floors) · 5B ✗ | 28.9 | 2.5 | 3 | 3 | 3 | 2 | 2 | – | 3 | 3 | 4 | 2 | – | 3 | 0.566 | 232k | 16.89 | [sheet](sheets/lakeview-street.jpg) |

## Criterion means

| sil | pal | lit | AO | grd | chr | fog | hse | geo | AD grd | AD rain | AD reg |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3.0 | 3.0 | 2.92 | 2.77 | 2.31 | 3.0 | 2.92 | 2.92 | 4.0 | 2.31 | 2.5 | 3.08 |

## Most-cited fix areas (top fix 3 pts, second 2, third 1)

- **ground** (27 pts): v2-01: Raise lawn saturation and add warm lawn patches, leaf litter under the crowns and a mulched bed along the house, plus darker shade tone at the trunk bases.; showcase-01: Add lawn tone patches (sun-warmed vs shade), worn path edges, shrub clumps and a few fallen-leaf scatters under crowns; warm the path colour.; showcase-03: Vary the lawn with darker and yellower tone patches, worn edges along the path, and a few shrub masses or beds near the trunks.
- **light** (19 pts): v2-01: Add a warm low-sun key: tint lit lawn, walk and house faces gold-orange and cast long soft crown and trunk shadows across the walk and lawns toward the camera and right.; v2-06: Warm the golden-hour key: warm gold on fields and roofs, long cool shadows toward 73 degrees, and a sun glint on the lake's western part.; ordinary-street: Strengthen the afternoon key: a clear blue sky gradient, warmer sunlit surfaces with cooler shadows, and dappled tree-shade patches across lawns and sidewalk, as in the mock.
- **vegetation** (8 pts): wilmette-street: Vary crown size, openness and tone between trees, with thicker branching, instead of repeated round balls on thin trunks.; wilmette-street-fall: Vary crown shapes into merged unequal masses with visible branch skeletons and some openness, and add darker russet and bare-ish trees.; wilmette-aerial: Merge crowns into larger unequal masses with family differences (open oak, closed maple) and thicken trunks with some branching; vary hue within families toward russet and olive.
- **water** (5 pts): v2-06: Deepen the lake to a saturated blue with sky-tinted gradient and glint, instead of slate grey.; showcase-01: Give the lake a blue-lilac body with a warm glitter band toward the sun side, a lighter shore band and a soft sky reflection at 20-100 m instead of flat grey.
- **weather** (5 pts): showcase-03: Add a wet gloss to the path with sky reflection and darker streaks, a larger flush sky-reflecting puddle, and darker saturated wet grass with a faint sheen.; evanston-street-rain: Darken and desaturate wet grass and the sidewalk, add sheen on the walk and more puddles on the road reflecting the sky
- **fog** (4 pts): v2-06: Add gentle warm distance haze and tonal separation so far fields recede, and vary field colours (gold, green) more.; showcase-06: Build distance haze in layers so near trees keep colour, mid trees fade and far trees dissolve; add soft contact darkening at trunk bases.; wilmette-aerial: Add gentle warm haze and desaturation toward the upper frame so distant blocks separate from the foreground.

## Top fixes per lane (top fix 3 pts, second 2, third 1)

**5A**
- light (19 pts): v2-01: Add a warm low-sun key: tint lit lawn, walk and house faces gold-orange and cast long soft crown and trunk shadows across the walk and lawns toward the c; v2-06: Warm the golden-hour key: warm gold on fields and roofs, long cool shadows toward 73 degrees, and a sun glint on the lake's western part.; ordinary-street: Strengthen the afternoon key: a clear blue sky gradient, warmer sunlit surfaces with cooler shadows, and dappled tree-shade patches across lawn
- water (5 pts): v2-06: Deepen the lake to a saturated blue with sky-tinted gradient and glint, instead of slate grey.; showcase-01: Give the lake a blue-lilac body with a warm glitter band toward the sun side, a lighter shore band and a soft sky reflection at 20-100 m instead of
- weather (5 pts): showcase-03: Add a wet gloss to the path with sky reflection and darker streaks, a larger flush sky-reflecting puddle, and darker saturated wet grass with a fai; evanston-street-rain: Darken and desaturate wet grass and the sidewalk, add sheen on the walk and more puddles on the road reflecting the sky
- fog (4 pts): v2-06: Add gentle warm distance haze and tonal separation so far fields recede, and vary field colours (gold, green) more.; showcase-06: Build distance haze in layers so near trees keep colour, mid trees fade and far trees dissolve; add soft contact darkening at trunk bases.; wilmette-aerial: Add gentle warm haze and desaturation toward the upper frame so distant blocks separate from the foreground.
- post (3 pts): showcase-06: Neutralise the smoke grade to a grey-tan haze like the paint-over: keep crowns' own greens and golds visible and stop the orange wash on sky and la

**P2** (ground and vegetation shared with 5A for material and LOD)
- ground (27 pts): v2-01: Raise lawn saturation and add warm lawn patches, leaf litter under the crowns and a mulched bed along the house, plus darker shade tone at the trunk base; showcase-01: Add lawn tone patches (sun-warmed vs shade), worn path edges, shrub clumps and a few fallen-leaf scatters under crowns; warm the path colour.; showcase-03: Vary the lawn with darker and yellower tone patches, worn edges along the path, and a few shrub masses or beds near the trunks.
- vegetation (8 pts): wilmette-street: Vary crown size, openness and tone between trees, with thicker branching, instead of repeated round balls on thin trunks.; wilmette-street-fall: Vary crown shapes into merged unequal masses with visible branch skeletons and some openness, and add darker russet and bare-ish trees.; wilmette-aerial: Merge crowns into larger unequal masses with family differences (open oak, closed maple) and thicken trunks with some branching; vary hue withi
- buildings (3 pts): ordinary-street: Give the near house brick or siding colour contrast with cream trim, window casing, eave and porch details and a darker foundation band.; lakeview-street: Break up the near brick slab with bay, cornice, stoop and entry relief and brick-tone variation; add trunk flare and base darkening to the fore


## Per-view summaries

- **v2-01** (28.6/50): At phone size this reads as a clean stylized autumn street with good crown colour, but it is cool and flat, with no golden-hour key or cast shadows. The single biggest gap is the missing warm low-sun light and shadow. _vs previous: better: luma is up about 11 and colour slightly warmer than the previous run, but the lighting remains flat._
- **v2-06** (23.2/50): At phone size the aerial reads as a correct but flat, desaturated map with a slate lake and no golden-hour light compared with the warm paint-over. The biggest gap is light and colour: no warm raking sun, lake glint or distance haze. _vs previous: unchanged: pixel change 2.8%, luma and saturation within 2 points._
- **showcase-01** (30.0/50): At phone size it reads as a clean stylized autumn park with a coherent low sun, but the ground is flat and desaturated and the lake is an empty grey plane. The biggest gap is water and ground richness against the golden-hour targets. _vs previous: unchanged: near-identical frame, slightly higher saturation and colourfulness, same flat lawn and lake._
- **showcase-03** (30.0/50): At phone size the frame reads as a clean stylized autumn lakeside park with good crown colour variety, but the lawn and path are flat and dry-looking under a bluish sky, so light rain barely registers. The biggest gap against the paint-over is wet-surface response (glossy path, reflective puddle, dark wet grass) and neutral overcast grading. _vs previous: unchanged: near-identical composition and light, slightly more saturated greens (pixel change 4 %), no new wet or ground detail._
- **showcase-06** (30.0/50): At phone size it reads as a stylized autumn lake park under an orange smoke wash, with decent tree families but a flat lawn. The biggest gap against the paint-over is the over-saturated uniform orange cast and the sterile ground. _vs previous: unchanged: near-identical (pixel change 2.3), slightly more saturated._
- **ordinary-street** (30.0/50): At phone size the frame reads as a coherent autumn street but hazy, desaturated and flat compared with the paint-over and the daytime mock. The biggest gap is the missing crisp sunlight, blue sky and shade patterns, plus a plain box house. _vs previous: unchanged: pixel change 2.6%, luma and colour histograms near identical to the previous run._
- **wilmette-street** (30.0/50): At phone size it is a coherent stylized street with warm light and clear house colours, but the sky is purple, crowns are lime and lollipop-like, and the lawn is flat. The biggest gap is sterile ground richness against the mock and look-fix references. _vs previous: unchanged: near-identical frame, slightly warmer and more saturated (dSat +11.8) with similar structure._
- **wilmette-street-fall** (30.0/50): At phone size the street reads as a clean stylized North Shore autumn with good orange crowns, but the flat summer-green lawns and ball-on-pole trees keep it below the anchor. The biggest gap is ground richness and autumn lawn colour. _vs previous: unchanged: same composition and crown colours, slightly more saturated; ground still flat._
- **wilmette-aerial** (35.3/50): At phone size it reads as a warm, coherent autumn North Shore block with good colour and lighting. The biggest gap is repeated lollipop crowns and thin contact and ground detail versus the stylized target. _vs previous: better: crowns now show differentiated orange and yellow instead of the previous pale olive-yellow wash, with higher saturation; structure unchanged._
- **evanston-street** (31.1/50): At phone size the street reads as a clean stylized fall afternoon with correct sun direction and fall foliage, but it is muted and flat compared with the paint-over: grey-lilac sky, uniform green lawn and flat facades. The biggest gap is warm light and colour richness on the ground and walls. _vs previous: unchanged: composition and geometry are the same, with slightly higher saturation (+11.5) and a little more warmth in the foliage._
- **evanston-street-rain** (30.0/50): At phone size the frame reads as a clean stylized wet street with a stormy sky, but the lawns look dry and flat. The biggest gap is ground richness and wet-surface response on grass and walks. _vs previous: unchanged: composition and layout are the same; slightly less saturated sky and puddles on the road are now visible._
- **lakeview-postcard** (30.0/50): At phone size it reads as a warm stylized golden-hour residential street with decent geography, but the foreground is flat and the sky and trunk colours are over-saturated. The biggest gap is ground richness. _vs previous: unchanged: nearly the same composition and look as the 2026-10-06 capture, with slightly lighter tree crowns._
- **lakeview-street** (28.9/50): At phone size it reads as a clean stylized Lakeview street with a warm sky, but the ground is flat and the near facade and trunk lack contact shading and light modelling. The biggest gap against the mock is the ground richness and the sunlit/shadow contrast on the facade and lawn. _vs previous: unchanged: near-identical composition; slightly warmer sky and building, trunk and foliage similar._

Overview of all frames: [overview.jpg](overview.jpg). Raw grades and signals: [grades.json](grades.json).
