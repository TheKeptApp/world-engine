# US regional landscapes v1

[Open gallery](index.html) · [Full landscape values](landscapes-values.json) · [Seasonal land-cover values](land-cover-seasonal-values.json) · [Image prompts](prompts.json)

Ten regional sheets cover terrain/vegetation, seasonal states, farmland/field patterns, small-town forms, rural roads/water edges and street-to-continent reading. Each sheet has street, aerial and far/region primary views plus a four-season strip. Standalone HTML sheets and complete `*-sheet.png` exports use the house/infrastructure typography, metre controls, hex swatches and projected-size tiers. The drawings are composite art proposals, not surveyed locations or species/prevalence estimates.

## Regions and strongest recognition cues

| Region | Recognition first | Important local gate |
|---|---|---|
| Desert Southwest | Exposed basin soil, dry washes, sparse irregular shrubs, low masonry settlement | Separate Sonoran Phoenix/Tucson from Mojave Las Vegas. No default Las Vegas saguaros. |
| Pacific Northwest | Tall conifer mass, rounded forest uplands, rocky coast/estuary | Coastal lowlands stay distinct from inland dry habitats; no automatic sea-level winter snow. |
| California coast/hills | Oak-dotted rounded hills, dry-season straw grass, coastal terrace | Northern forest coast and southern chaparral are separate subprofiles; irrigation keeps some fields green. |
| Rockies/Front Range | Plains–foothill–montane–alpine transition, open pine and aspen pockets | Elevation controls vegetation/snow. Denver plains are not an alpine village. |
| Great Plains | Broad horizon, large fields, sparse shelterbelts, small town/elevator mass | Pivot circles and crop stage require mapped evidence; winter wheat need not be dormant. |
| Midwest | Low rolling field mosaic, shade groves, barn/farm compound, compact brick main street | Crop boundaries, drainage and harvest state take precedence over a decorative grid. |
| Southeast | Mixed pine/hardwood uplands, porch cottage, separate cypress bottomland | Dry upland and wet bottomland are separate masks; do not swamp the whole village. |
| Florida | Flat sawgrass plain, hammock islands, mangrove/lagoon, pale coast | Freshwater Everglades and tidal mangroves differ. Keep farms/towns outside intact natural wetland. |
| Northeast | Rounded wooded ridge, irregular pasture, compact gabled town, lake | Mixed forest phenology varies; no uniform orange canopy or statewide winter-ice assumption. |
| Gulf Coast | Flat delta channels, marsh fingers, barrier sand, developed coastal cottage | Gulf subregions differ. Rice flooding, salinity and raised foundations need local data. |

These are **generator proposals**, not instructions to stamp one look across an entire state. Regional boundaries are ecotones. EPA's framework provides a primary ecological classification; it does not make this ten-group art taxonomy an authoritative map. [EPA ecoregions](https://www.epa.gov/eco-research/ecoregions), [EPA Level III/IV US ecoregions](https://www.epa.gov/eco-research/level-iii-and-iv-ecoregions-continental-united-states).

Saguaros belong to the Sonoran Desert rather than a generic all-desert palette. [NPS saguaro range](https://www.nps.gov/sagu/learn/nature/saguaro.htm). Everglades habitat families include freshwater wetland and marine/estuarine settings, with mangrove habitat treated separately. [NPS Everglades habitats](https://home.nps.gov/ever/learn/nature/habitats.htm), [NPS mangroves](https://www.nps.gov/ever/learn/nature/mangroves.htm). Other regional family names, dimensions and visual defaults in this pack are art proposals for source-backed local selection, not newly researched geographic inventories.

## Approved style and lighting

The controlling reference is `style-b-bible-v1/STYLE-B-RULE.md` and its approved calibration street: **proportions real, surfaces simplified, light soft**. Organic crowns stay irregular and smoothly shaded; no toy architecture, identical balloon trees, miniature diorama bases, photoreal terrain, saturated orange wash, glossy surfaces or fine leaf/grass/grain patterns. House/infrastructure families inherit the corresponding packs. Japan regional landscape supplies layout/realism continuity, not Japanese houses or rice paddies in US scenes. No transport subjects were needed; any future vehicles must follow the Bible's Japan transport anchor.

The complete Bible `sharedLighting` object is copied unchanged into `landscapes-values.json`. All primary and seasonal images target the same clear mid-afternoon fixture: 40° elevation, 225° azimuth, sun #FFE8C6, neutral fill #AEBCCA, +0.35 EV, contrast 1.06, saturation 1.08 and no added warmth. Seasonal thumbnails change vegetation/crop/soil and justified snow state; they do not introduce separate golden-hour lighting. Production live sun/weather replaces this illustrative fixture as one state, never stacks exposure or grades.

Artwork is generated with the **built-in image-generation tool**, using the three local references recorded in the JSON/prompts. It is a visual target, not a calibrated engine render: exact camera bearings, dimensions, snowfall extent, hex pixels and photometric equality are unverified. Numerical values govern implementation; illustrated context is not source geometry. No logos, badges, brands, real murals, dogs, people or characters are permitted.

## Seasonal values at region and continent zoom

`land-cover-seasonal-values.json` includes four seasonal palettes for each region with the same eight street-to-space land classes: grass, forest, cropland, dry plains, bare rock, urban, snow/ice and wetland. Lake/ocean colours, urban and snow base swatches remain inherited. New seasonal/ecological variants are labelled authored proposals. Four displayed season swatches show grass/forest/cropland/wetland; the JSON contains the complete palette plus near soil/bark/beach accents and explicit crop-stage colours.

Do not use calendar season to paint an entire region green, gold or white. Climate, elevation, local phenology, crop stage, irrigation, tide, wetland hydroperiod and actual snow coverage override the fallback. South Florida uses wet/dry progression. California rainfed hills differ from irrigated crops. Temperate forest leaf-off must preserve evergreen patches. Regional forest autumn colour is an aggregate mixture, not a command to change every conifer to ochre.

Crop states are independent: bare → emergent → green → ripe where appropriate → harvested stubble. Not every crop becomes golden; winter crops can remain green in calendar winter. Broad cropland season colour is the final fallback. Near row direction and field perimeter derive from actual geometry; far removes row marks and tiny farm objects.

For each output cell, aggregate actual land-cover fractions in equal-area space, decode sRGB to linear RGB, blend class colours weighted by fractions, then encode once. Region and continent use the **same palette and source fractions** at progressively coarser resolution. Snow is a separate coverage fraction overlay. Ecotones mix coverage, not abrupt metro/state colours. If data is missing, keep inherited neutral class fields and record inference; never invent species, irrigation or inundation.

The street-to-space day and night region contracts are copied for review. These seasonal values are day/base appearance swatches. The inherited night palette remains the explicit fallback: do not multiply day colours by an improvised night tint, bake shadows into albedo, duplicate wet darkening or add exposure twice. No additional custom seasonal night palette has been calibrated.

## Zoom and detail

- **Street:** terrain grade, true tree/house scale, a readable ditch/bank/porch form. Keep broad materials and sparse useful recesses.
- **Aerial/neighbourhood:** field and settlement footprints, canopy groups, drainage and coast connectivity. No miniature scale exaggeration.
- **Region:** broad softly shaded relief plus flat class colour fields. No individual tree/house/crop geometry, dotted canopy texture or road-grain noise.
- **Continent:** area-aggregate the same cover fractions, keep clean coastline and major resolved water shapes; no satellite/Blue Marble texture substitution or luminous outlines.

Screen tiers refer to **projected local component size in drawable pixels**: under 6 px silhouette/colour; 6–20 px major form/footprint; over 20 px sparse recognition-critical geometry. A huge region's bounding box must not keep subpixel trees or rows alive. The far/seasonal image panels illustrate intent; they are not controlled pixel-size tests. Existing engine density/budget thresholds remain authoritative; this pack adds no measured performance promise.

## Values and use

All range controls are **metres** and proposals: road/shoulder width, vegetation height, house/floor width-height, field width, channel width, relief, barn/silo and occasional pivot radius. They are not cadastral reconstruction, building standards, navigation clearance or species-height surveys. Source elevation/building footprint/hydrography/land-use masks win. A proposed raised cottage floor is never proof of flood safety.

Preserve true source road grade, field shapes, bridge/culvert connectivity, wetland boundaries and settlement placement before dressing. Select archetypes by observed land use, habitat and building information. Never fill wilderness with invented houses, apply a farm grid to swamps, or infer population/activity from a regional appearance label. The kit contains no individual data.

No git operations, repository edits or unrelated deliverable folders. Only the requested kit holds final outputs; source packs remain unchanged. Underlying local style references may derive from OSM: retain [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright) with their source material. This pack supplies no additional data licence for future external maps or imagery.

## Final verification

All ten artworks and ten complete specification PNGs are saved. The phone gallery loads ten images with 30 primary view labels and 40 season labels; at a 390 px viewport, document width is 390 px with no script errors. All 320 seasonal class hexes, metre ranges and three detail tiers per region pass structural checks. The approved lighting object, street-to-space base palettes and style contract pass exact JSON equality. All final artwork was visually reviewed for regional form, far-view simplification and excluded characters/brands. Full initial prompts are in `prompts.json`; twelve refinement prompts are in `correction-prompts.json`. This verifies artifact completeness and display, not renderer photometric equality or measured device performance.
