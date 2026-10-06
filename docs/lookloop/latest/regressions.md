# Look loop: regressions

This run (2026-10-06 14:28, engine `24491e5`) against the previous published run (2026-10-06 13:50, engine `f7ca60b`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 32 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

**22 regression flag(s) in 14 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-01](sheets/v2-01.jpg) | v2 /50 | 27.8 | 24.3 | At phone size the street reads as a flat, washed-out dusk-grey scene rather than autumn golden hour, with the dog readable but ground and house detail sparse. The biggest gap is the missing warm directional light and cas |
| [v2-01](sheets/v2-01.jpg) | softnessAO | 3 | 2 | Only faint foundation darkening and a small shrub row; no tree or house cast shadows on lawn or walk, dog has barely any contact shadow. |
| [v2-01](sheets/v2-01.jpg) | houseVariety | 3 | 2 | Near house is a plain pink wall with one window; the distant row is a uniform cream block with repeated windows. |
| [v2-01](sheets/v2-01.jpg) | geography | 4 | 3 | Street runs west with a pink low-sky glow ahead, but shadows are too faint to verify the 73 degree bearing; nothing clearly contradicted. |
| [v2-04](sheets/v2-04.jpg) | houseVariety | 3 | 2 | Only one near house wall and a repeated tan block row across the street; no porches, entries or varied mass. |
| [v2-06](sheets/v2-06.jpg) | v2 /50 | 26.3 | 22.1 | At phone size the aerial is a desaturated, hazy beige plan view with a correct lake and grid layout but little golden-hour light or colour. The biggest gap is light and palette versus the warm, saturated target. |
| [v2-06](sheets/v2-06.jpg) | palette | 3 | 2 | Everything outside the core is a washed grey-beige plane; lake is a flat grey-blue; saturation 51 vs target 134. Only the house core carries warm colour. |
| [v2-06](sheets/v2-06.jpg) | softnessAO | 3 | 2 | Little visible contact shading or soft shadows; footprints sit as flat blocks. |
| [v2-06](sheets/v2-06.jpg) | depthFog | 3 | 2 | Uniform grey-beige haze flattens the distance; no horizon, but little separation between near and far and no lake/shore atmosphere. |
| [v2-06](sheets/v2-06.jpg) | adRegional | 3 | 2 | Lake plus bungalow grid reads loosely as Sloan's Lake, but the surrounding land-use is a generic beige plain with no Front Range cues. |
| [showcase-03](sheets/showcase-03.jpg) | adRegional | 3 | 2 | Cottonwood-like autumn crowns and conifers are plausible for the Front Range, but there are no bungalows, mountain band or park cues; reads generic. |
| [showcase-05](sheets/showcase-05.jpg) | softnessAO | 3 | 2 | Trunks and bench sit on the lawn with almost no contact shading; path edges are hard and bare, nothing under crowns. |
| [showcase-06](sheets/showcase-06.jpg) | palette | 3 | 2 | Saturated mid-green lawn and teal conifers stay vivid under a heavy orange sky; smoke does not desaturate or unify the near field, so sky and ground split into two palettes (target is a uniform beige haze). |
| [showcase-07](sheets/showcase-07.jpg) | adRainReadable | 3 | 2 | Snow cover and a dark overcast sky read as wintry, but falling snow is barely visible and the path has no wet or ice sheen. |
| [showcase-08](sheets/showcase-08.jpg) | houseVariety | 3 | 2 | Houses are tiny and distant, and read as a dark roof strip with a few red or white boxes; little family variety is visible. |
| [showcase-11](sheets/showcase-11.jpg) | palette | 3 | 2 | Grey-lilac blotchy snow and flat slate lake; low saturation and colourfulness vs the anchors' crisp blue water and warm tones, orange edge glints look like noise. |
| [ordinary-street](sheets/ordinary-street.jpg) | houseVariety | 3 | 2 | Near house is a featureless mauve box with two windows and no roof or entry visible; distant yellow block is the only other type. |
| [light-rain-street](sheets/light-rain-street.jpg) | softnessAO | 3 | 2 | Hedge blobs at the foundation have little contact shading; the house base is a flat dark band; the large boulder-like shrub floats on the lawn. |
| [wilmette-street](sheets/wilmette-street.jpg) | groundRichness | 3 | 2 | Large near lawns are two flat green tones split by a walk; little patch, wear or litter variation; foreground shrub is a single blob. |
| [wilmette-street](sheets/wilmette-street.jpg) | adGroundRich | 3 | 2 | Lawns are nearly flat green with hard edges at walks; foundation shrubs exist but beds, worn edges and leaf litter are missing. |
| [lakeview-alley-winter](sheets/lakeview-alley-winter.jpg) | adRainReadable | 3 | 2 | Snow view marked wet: overcast sky and cool tone read as winter weather, but no visible wet or slush surface contrast, no sheen or puddles, and no falling flakes at phone size. |
| [lakeview-aerial](sheets/lakeview-aerial.jpg) | depthFog | 3 | 2 | Almost no atmospheric perspective; far blocks are as crisp and saturated as near ones, and the frame is cut off at the top with no soft distance. |

## Same-grader check (Sonnet, §S rubric, ccb5f77 frames → 1c15fba)

| View | Before (ccb5f77) | Now (1c15fba) | Commit |
|---|---|---|---|
| [v2-06](sheets/v2-06.jpg) | 25.3 | 22.1 (−3.2) | One of 35827f6..1c15fba (5A: context ring, lawns dcd3eb6, saturation 1c15fba). The only view down more than 3; the ring raised it to 26.3 at 35827f6 on the old rubric, so check the 1c15fba saturation and lawn-tone changes on this golden-hour aerial. |
