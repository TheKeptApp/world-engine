# Chicago + Denver districts — strict Style B v1

Seven sheets: six daytime districts plus the Chicago River / Loop at full night. Open `index.html` locally; all artwork is local and the gallery needs no internet. Each sheet has hero street, pitched aerial and far-view panels, signature elements, hex swatches, exact-versus-simplifiable requirements and the approved projected-height detail tiers.

## Style and format authority

The layout/CSS comes unchanged from the approved Miami Brickell sheet in `../landmarks-style-b-v1/miami-brickell.html`. Images use the current approved `miami-brickell-style-b-v2.png` as the style reference, with flat glazing, smooth matte walls, simplified water and clean tree crowns. The night art uses the approved Miami night reference and the corrected Chicago day triptych. The house-contrast hero image contains old grass detail and a dog; neither is a permitted content/style transfer here. Only its JSON lighting is copied.

The complete `sharedLighting` and `approvedHouseValues` are copied unchanged from house-contrast-v1. Source metadata retains its historical reference-number ambiguity; this request's approval of the Miami sheets defines the current visual authority. No new approval is needed. Day lighting: sun #FFE8C6 at the illustrative 40° / 225° fixture, +0.35 EV applied once, contrast 1.06, saturation 1.08, neutral witness shadow/lit linear Y 0.62 and AO visibility floor 0.65. Live solar position overrides the illustrative fixture. No per-view yellow/purple grading or new light/pass budget.

The full-night state and window, streetlight, star, fog, surface and performance blocks are copied unchanged from night-fog-v1, with source hashes. Night uses sky #15243C / #243854 / #344255, sky/ground fill 0.24/0.08 of noon, direct sun 0, +0.35 EV, haze #475568 at 0.002/m, no ground fog. Eligible window share target 0.30, permitted range 0.20–0.40; warm #F3D0A0, cool #C9DDEB; bloom weight max 0.035. Window selection uses stable aperture IDs, no per-window point lights. Shared maximum is two actual unshadowed local lights and six pool/headlight fields, with no extra shadow maps/full-screen passes. These remain source proposal constraints, not a measured GPU result.

The authored Loop night adapter deliberately has no fixed skyglow bearing: derive it from camera and mapped city clusters. It does not reuse Lakeview's 155° direction. Day illumination/exposure is replaced by the night state, never added to it. Window proportions and exposure in AI images are illustrative; production must enforce the exact JSON values.

## District reads

- **The Loop + Chicago River**: Dense mixed-height river canyon, Chicago-type bascule bridges, stone river walls and the inland elevated L. The Loop elevated rectangle is inland south of the main river branch. Bridge types differ by crossing; do not duplicate one bascule archetype everywhere.
- **Lakefront**: Lake Shore Drive, broad park belt, beaches, lakefront paths, harbor docks and an open Lake Michigan horizon. Lake is east of the city; lakefront road/park/beach ordering varies along shore and must be checked locally. Do not substitute a canal for a harbor or invent a distant shore.
- **Wrigleyville / Lakeview**: Narrow-lot greystones and three-flats, raised stoops, cornices, rear alleys and generic nearby rooftop bleacher forms. A roof bleacher is an optional mapped feature, not an automatic Lakeview roof decoration. The sports shell stays near its real footprint; no team identity is drawn.
- **LoDo / Union Station**: Brick warehouse blocks, pale historic station frontage, plaza, white train canopy and rail-platform edge behind the station. Rail infrastructure stays behind the historic frontage; it is not a plaza ornament. Downtown towers, rail edge and any mountain visibility are camera/map decisions.
- **Highlands / Sloan’s Lake**: Low porch bungalows and taller hip-roof Denver Squares; neighborhood grid beside Sloan’s Lake park and broad city-lake water. Treat Highlands and Sloan’s Lake as adjacent context selections, not one continuous waterfront block. Lakeward and westward mountain views require separate solved cameras.
- **Front Range edge**: Western foothill terrain, tilted red sandstone fins, amphitheater context, dry grass/scrub and a distant mountain backdrop. Morrison/Red Rocks is a western foothill context. This sheet does not move it into downtown Denver. Outcrop inclination and far ridges come from terrain, not repeated decorative triangles.
- **The Loop + Chicago River — night**: The same river/bridge/tower district in full night, with readable cool architecture, sparse grouped warm windows and restrained fragmented river highlights. The Loop elevated rectangle is inland south of the main river branch. Bridge types differ by crossing; do not duplicate one bascule archetype everywhere.

## Exact geography and simplification

Every far view reads **“concept – positions and sightlines come from the map”**. No image is a survey, true-scale mesh, engine screenshot or solved visibility test. Per-building heights, camera coordinates and far-view distances remain null when not supplied. Do not infer dimensions from the art or floor counts. Bridges require actual span type, leaf/pivot axes, deck clearance and open/closed state; elevated rail must follow the map rather than scenic repetition. Union Station's canopy and detailed roof need reconciliation with source geometry. Sloan's Lake outline and Red Rocks outcrop/ridge profiles require mapped terrain. Snow on distant peaks in the concept is not a live weather observation.

At **under 6 CSS px** projected asset/cluster height, preserve land/water/topology and roof/ridge silhouette. At **6–20 px**, preserve the first three signature masses. At **over 20 px**, retain the family-defining forms; omit every sub-2-pixel detail. Screen size is projected logical height, not camera distance or phone drawable resolution. Public art, marks, lettering, people, dogs and characters remain excluded at every tier.

Geometry simplification must preserve footprint, roof envelope, bridge articulation and terrain silhouette. Optional authored bevels are 0.02–0.06 m on building edges, 0.02 m on curbs and 0.01 m on steel, maximum two segments near; drop below 2 projected px. These are shading/LOD proposals, not measurements. Keep masonry, sand, lawns and rock as broad plain solids. No individual brick/grass/leaf geometry or photographic texture. A roughness 0.90, opacity 1, transmission 0, zero-reflection flat-glazing proxy avoids glass realism.

Water is an authored strict-style display adapter: broad color bands, roughness 0.78, sheen 0.04, no mirror/SSR or animated wave geometry. Broad highlight blend caps are 0.08 day / 0.10 night, shoreline color transition 1.2 m where applicable. Band length 4–12 m, width 0.8–2.4 m; these control broad shape size, not a wave physics model. River walls retain their hard built edge; the color transition does not round off surveyed masonry. Numeric hexes are sRGB appearance targets/initial material proxies with decoded linear RGB supplied; do not decode the supplied linear values a second time. They are not calibrated albedo or sampled AI pixels.

## Files

- `index.html`: responsive local gallery.
- Seven individual HTML sheets and matching `*-sheet.png` exports, matching the Miami sheet structure.
- `images/`: seven final three-view district artworks.
- `districts-values.json`: materials, copied day/night authorities, geography/LOD policies, camera nulls and provenance.
- `image-prompts.json`: original generation, surface cleanup and night prompts, generated with the built-in image tool.
- `verification.json`: layout, local asset loading, copied-value equality and image hashes.

## Verification and limits

All final artwork is visually inspected for strict style and prohibited content. Initial fine masonry/grass detail was simplified; the river-edge elevated line was removed in a targeted correction. The artwork still contains illustrative building/bridge/roof/terrain shapes, so must-be-exact items are future build requirements rather than claims of current map compliance. PNG layout exports are not renderer or physical-iPhone tests. No source project/reference files were modified and no git commands were run.

## Geography references

These primary pages support broad district context; they do not supply surveyed geometry:

- [The Loop + Chicago River — source](https://webapps1.chicago.gov/landmarksweb/web/tourdetails.htm?touId=21)
- [The Loop + Chicago River — source](https://www.transitchicago.com/maps/system/)
- [Lakefront — source](https://www.chicagoparkdistrict.com/facilities/harbors)
- [Lakefront — source](https://www.chicagoparkdistrict.com/facilities/paths-trails)
- [LoDo / Union Station — source](https://www.denver.org/travel-trade/itineraries/downtown-denver/)
- [Highlands / Sloan’s Lake — source](https://www.denver.org/neighborhoods/highlands/)
- [Front Range edge — source](https://www.redrocksonline.com/our-story/)
- [The Loop + Chicago River — night — source](https://webapps1.chicago.gov/landmarksweb/web/tourdetails.htm?touId=21)
- [The Loop + Chicago River — night — source](https://www.transitchicago.com/maps/system/)
- [Red Rocks geology — tilted Fountain Formation and rock context](https://www.redrocksonline.com/our-story/geology/)
