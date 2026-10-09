# Context-ring experiment — frozen plan

R's scope: bakeoff only, default off, existing ~3 km context, roads/land/water, no buildings past the 0.5 km source band. This implementation excludes **all** context buildings, stricter than the cap. No native or shared exporter/render code changes. No score or default promotion.

Implements `docs/execution/world-edge-options.md` Recommendation and first test. Consumes the **unmodified** native `ContextRing.generate` through a bakeoff-only Swift adapter. The native `World+Context` non-casting path is the reference. It is a bounded first band of option (a), not infinite streaming, and no building-complete city claim.

- Fixed native aerial parameters: area tolerance 6 m, road tolerance 5 m, min area 8,000 m²; water tolerance 3 m and native water minimum; 200 m edge fade. One explicit all-area experiment override: mapped minor roads extend throughout the existing context coverage rather than stopping 400 m beyond the core. Rail excluded from this roads/land/water test.
- Ground receives calibration-v2 ground base colours and masonry roughness; named other land slots come from the existing exported palette. Water uses the existing world's water material. The existing once-applied haze, lighting, exposure and post grade remain unchanged. No pending sky/cloud/street-ground pack used.
- Four pooled land/road quadrants and one water batch, no shadow casting, no added textures. Triangle clipping excludes detailed core and bounds source coverage. No whole-area uniform land fill: unmapped ground remains unknown and stays in the blank numerator.
- `?contextRing=1` explicitly opts in; `?sceneBudget=1` supplies the requested budget basis. Scene-budget pooling excludes context, which has dedicated cost categories. OFF never imports the context module or downloads its data.
- OFF, fresh-process OFF-repeat, ON at fixed contracts. Sloan and Lakeview existing 40/150/600 m ladders; Wilmette corrected 45°/90° ladder; West Highland existing 350 m contract. No camera tuning. Greenville adapter/data limits must be explicit.
- 81×45 structural ray mask, same pixel centres/denominator as scoreboard. Boundary and generated-ground hits are blank; only real mapped context triangles can replace them. Instances excluded as before. Strict gate `<35%`; all-pass main/shadow ledgers and context-only counts reported. Repeat control must be exact, added shadow must be zero.
- Cost envelope: <=40k incremental main triangles and <=8 draws (20–40k /4–8 planning range, not a minimum geometry requirement). Whole-scene floor <400k/150k/100 and standard <=500k/180k/120 reported separately. Mac captures cannot qualify iPhone performance.

Mocks opened: `~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `01-lakeview.png`. These own light/material appearance, not map geometry or the 600 m camera.
