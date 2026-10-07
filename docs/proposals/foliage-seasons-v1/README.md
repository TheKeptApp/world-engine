# City foliage + seasons · Style B v1

Proposal only. 32 species, eight four-species library boards, 12 city four-season boards and five planting boards covering ten landscape regions. Open index.html. Individual species pages isolate their row without changing the original artwork.

## What governs the look
The sharedLighting block is copied exactly from the Style B Bible and matches house-archetypes-v1. Grounded real proportions, smooth matte crown masses, cool-neutral soft shadows and blue afternoon sky. No photo textures, people, dogs, logos or brands. Raster colours are illustrative, not measured renderer output; JSON material albedo values govern implementation.

## Tree library
Columns: summer near, summer mid, summer far, bud/leaf-out, early colour, peak colour, winter bare/evergreen. The first column supplies the summer state in the five-state data ladder. Illustrations compare simplification at similar display size; they are not calibrated camera distances. Species pages give authored crown forms, metres and five hexes. Palms retain crowns year-round: the sparse growth specimen is a new-frond schematic, not a palm-wide seasonal leaf-off. Crabapple is a family, Bradford a cultivar; individual cultivar/site geometry remains unresolved. Existing ash and Bradford specimens are depictions, not planting recommendations.

## Seasons follow conditions
Use observations first, then validated species/site models, then clearly inferred weather heuristics. Regional CSV date windows are context only. Chilling, heat forcing, day length, frost and moisture affect leaf-out/colour/drop; species model thresholds remain unset until validated. Drought may thin crowns or change colour independently. Evergreen turnover, palm growth and tropical wet/dry flush never inherit a universal temperate orange autumn. Flower masks have their own phenophases. Snow is a weather accumulation layer, never a winter switch.

Keep continuous leaf, flower and colour fractions on a stable branch scaffold; interpolate albedo in linear RGB. Proposed inferred-state persistence is three days; observations may override. Preserve input provenance/confidence and model version for recap replay. Unknown irrigation remains unknown.

## City and planting scope
City compositions are fictional representative streets, not current surveyed repo renders. Six-species mixes preserve inventory/proxy scope in JSON; supplemental taxa are explicitly unverified candidates. No normalized metro-wide percentage or national top-32 ranking is claimed. Four-season panels approximate the same camera and geometry; production must use exact stable IDs. Denver is Front Range, Miami is Florida, Austin uses a warm-season/xeric Gulf-context residential variant, not coastal habitat. Planting sheets cover lawns, xeriscape, shrubs, hedges, beds and ground cover with seasonal hexes and dimensions.

Regional landscape class palettes are inherited unchanged. New near residential palettes are art proposals; lawn dormancy and plant coverage require temperature/moisture/site support. Never move mapped data. Generate in unoccupied plot/frontage masks using stable feature IDs; retain access/utility clearances and mark inferred. Do not paint every city with uniform canopy or grass.

## Phone detail and budget
Near crown >=20 projected pixels: smooth opaque lobes with gaps and primary branches. Mid 6–20 pixels: fewer lobes, silhouette retained. Far <6 pixels: one to three masses or area-weighted canopy class. These foliage thresholds do not replace Bible ambient-object thresholds. No individual leaf/grass geometry, phototextures or blanket alpha leaf cards. Use shared palette instances and stable seeds. Proposed foliage allocation is <=35k triangles and <=12 draws carved out of the scene allowance, not added to it; no device benchmark is claimed. Fade geometry only when both representations fit; use hysteresis to avoid flicker. Snow/litter/grass patterns are material masks. Actual live sun/weather overrides the hero lighting.

## Evidence
See sources.md and verbatim sourceRecord fields. Botanical source ranges and existing CSV records are distinguished from authored urban display ranges, silhouette choices, swatches and density. Blank or single-point source dimensions do not become verified bounds. Bigleaf maple spread, generic crabapple and several conifer/cherry display ranges remain assumptions.

## Files
25 PNG artwork boards in images/, 32 individual species HTML sheets, 25 board HTML sheets, index.html, foliage-values.json, image-manifest.json, prompts.json, sources.md and verification.md. The complete ZIP includes all these files and opens offline.
