# Landmarks Style B v1

## Strict Style B revision — 7 October 2026

Hard Rock canopy, South Beach, Wynwood, Brickell and Brickell night now use the `*-style-b-v2.png` images. The pass simplifies surfaces, foliage and water while retaining the approved broad composition and signature elements: clean palm frond solids, smooth crown clusters, plain matte materials, opaque flat glazing and broad water color bands with soft highlights. No photographic sand, asphalt, surface grain or reflective glazing is intended.

Previous images, sheets, Miami board, notes and values are retained under `superseded/miami-expansion-pre-strict-style-b/`; original image files also remain in `images/`. They are superseded rendering references, not deleted history. Existing material hexes, lighting values and descriptive notes are unchanged. `style-b-revision-verification.json` records the checks and image hashes; prompts and revision provenance are in the values JSON. AI editing preserves broad framing, not pixel-exact geometry; small cloud/opening variations remain illustrative. No optional stadium accuracy notes were supplied, so this is rendering-only, not an architectural re-design.

29 exterior concept sheets: eight Chicago, nine Denver, nine Miami landmarks and three Miami districts; three metro boards, three daylight skylines and one Miami night skyline. Open `index.html` locally. Individual HTML sheets contain street-level, aerial and far-silhouette art, massing, material hex targets, screen-size detail tiers, recognition-critical features and permissible simplifications. PNG exports accompany the HTML.

## Miami expansion — 7 October 2026

- **Hard Rock Stadium, Miami Gardens:** unmarked shell, open rectangular canopy ring, four corner spires, cable-support hierarchy and suburban far context. Published spire height is 357 ft = 108.8136 m from the [project builder](https://aecom.com/projects/hard-rock-stadium-renovations-roof-addition/); roof/bowl endpoints remain unresolved. [Structural engineer](https://www.thorntontomasetti.com/project/hard-rock-stadium) corroborates the canopy structure. The illustrations are not engineering models.
- **Miami Beach / South Beach:** hero street, aerial and far coastal views; Deco frontage, dunes/beach, palms, original generic lifeguard shelters and turquoise-to-deep-blue water. The taller Collins corridor is inland. Generic shelters do not replicate specific real towers.
- **Wynwood:** inland warehouses, industrial streets, string lights and trees. Every painted wall uses original simple abstract color blocks; no real mural, artist imitation, figurative artwork or lettering. These colors are art direction, not observed facade data.
- **Brickell:** glass canyon, bay edge, Brickell Key and causeway, simple generic Metromover beam/train, palms and wide sidewalks. Transit clearance, shoreline, island outline and tower placement must be sourced from the map.
- **Brickell + Biscayne Bay night:** warm grouped window patterns, readable cool fill and restrained fragmented bay reflections. Full-night state, window, streetlight, fog and performance values are copied unchanged from `night-fog-v1/night-fog-values.json` into the JSON with its source hash. A separate Miami adapter is labelled authored, not measured. No Chicago/Denver skyglow bearing is reused.

Daylight sharedLighting and approvedHouseValues remain unchanged. The new artwork was generated with the built-in image tool; all five prompts, visual checks and source-image references are retained in `landmarks-values.json`. Numerical swatches and lighting are renderer targets, not pixel-exact AI compliance. Star points, window share and bloom in the night illustration are not measured acceptance tests; production must enforce the copied limits.

All new far views carry “concept – positions and sightlines come from the map”. District screen tiers refer to the projected height of a selected district cluster, not a geographic distance. Their heights remain per-building map inputs, not a single district height. No new surveyed geography or rights clearance is asserted.

## Test-area anchors and geography revision

Wrigley belongs to the Lakeview test area. The Bahá’í House of Worship belongs to Wilmette. Exact coverage polygons remain map-authoritative. Denver now includes the unmarked Empower Field at Mile High shell, with a far concept from Sloan's Lake approximately 2 km west/northwest, looking east/southeast. Its open-air horseshoe structure is corroborated by the [official venue guide](https://www.empowerfieldatmilehigh.com/plan-your-visit/fan-guide-a-z); structural height is unresolved.

Every far-silhouette view is labelled “concept – positions and sightlines come from the map”. This delegates placement and occlusion to the map; it does not claim the illustrations were map-solved. Chicago Water Tower's far panel has an inland Michigan Avenue street foreground, not lakefront water.

## Style authority

`landmarks-values.json` copies the complete shared lighting and house-type values unchanged from the approved house-contrast-v1 values file. Reference images from house-contrast-v1 and house-archetypes-v1 guided the generated art. The source's reference-5 ambiguity remains unchanged. AI-generated pixels are not proof of exact lighting or colour calibration; the JSON is the renderer authority. Materials are authored sRGB targets, not sampled survey data.

## Selection

- Chicago: Willis Tower; 875 North Michigan Avenue; Chicago Water Tower; Merchandise Mart; Field Museum; Art Institute historic main building; Bahá’í House of Worship; Wrigley exterior shell.
- Denver: Colorado Capitol; Union Station; Daniels & Fisher Tower; Brown Palace; Art Museum Hamilton Building; Central Library; Red Rocks; downtown arena shell.
- Miami: Freedom Tower; Miami Tower; Vizcaya villa; Fontainebleau original curved wing; existing Brickell City Centre; closed-roof ballpark; waterfront arena; Ocean Drive Art Deco corridor.

Recognizability is editorial judgment, not measured popularity. Branded venues are rendered as unmarked architectural shells. No logos, sponsor/team lettering or public-art subjects are included. Excluding marks is not legal clearance for architecture or derivative artwork. Source rights remain a pre-release review gate.

## Limits before building

Nine records have referenced numerical height values; twenty retain null heights because endpoints conflict, measurements are missing, or a complex/terrain/district feature has no meaningful single height. OSM-tagged and secondary values are explicitly weaker than primary architectural measurements. Never infer height from floor count. All missing heights need resolution before true-scale modelling.

Skyline images are constructed concept views, **not literal paint-overs**: no engine captures were supplied. Their camera distances, context positions and terrain are illustrative. Far silhouettes exaggerate readability and are not geographic line-of-sight tests or phone benchmarks.

Union Station canopy, Daniels & Fisher adjoining context, Central Library roof geometry, Fontainebleau wing geometry, Brickell component positions, Miami waterfront placement and Ocean Drive's final individual-building selection require reconciliation. The JSON and sheet notes retain these limitations. `mustBeExact` is a future build requirement, not a claim that AI art already meets it.

## Files and checks

- `index.html`: local gallery, no external dependencies.
- `chicago-board`, `denver-board`, `miami-board`: HTML and PNG metro boards.
- 29 individual `*-sheet.png` exports and matching HTML sheets, including the three Miami districts.
- `images/`: 29 current three-view studies, three daylight skylines and a Miami night skyline.
- `landmarks-values.json`: metadata, provenance, height conflicts, style values and generation prompts.
- `verification.json`: layout/image loading checks and style-data equality check.

Generated art was visually inspected; a Vizcaya rooftop figure was removed in a targeted revision. HTML export checks do not validate architectural accuracy. No source research or house-style files were modified. No git operations.

## Original Miami sheets — strict Style B revision

The original eight Miami landmark sheets and daytime skyline now match the approved Miami expansion: matte surfaces, flat glazing, simplified palms and flat water bands. Existing numerical values and notes are unchanged. Prior versions are retained in `superseded/miami-originals-pre-strict-style-b`. Compositions are visually retained, not pixel-exact map or geometry proofs. Prompts are recorded in `landmarks-values.json`.

## Binding Miami look — rich Style B

All 14 Miami image assets (12 sheets, daytime skyline and Brickell night) use rich Style B, matching the approved Empower Field and house references: smooth simplified forms, natural soft shade, gentle material depth, soft sky-tinted glass and gradient water with gentle highlights. Prior passes remain superseded. The flat pass is retained separately as [Style C – Illustrated (concept, not binding)](style-c-illustrated/miami-board.html), not binding. Existing numerical values and notes are unchanged; previous flat-rendering sections above describe historical revisions, not the current binding look. Prompts are saved in `landmarks-values.json`.
