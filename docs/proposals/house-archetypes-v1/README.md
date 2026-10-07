# House archetypes v1 — Chicago, Denver, Miami

[Open the phone-size gallery](index.html) · [Generator values](archetypes-values.json)

## Boards and sheets

- Chicago: [interactive board](chicago-board.html), [PNG board](chicago-board.png). Brick bungalow; two-/three-flat; worker cottage; Foursquare; postwar ranch/split-level.
- Denver: [interactive board](denver-board.html), [PNG board](denver-board.png). Denver Square; Craftsman bungalow; Minimal Traditional; postwar/raised ranch; split-level; contemporary infill/duplex.
- Miami: [interactive board](miami-board.html), [PNG board](miami-board.png). Masonry ranch; Mediterranean Revival; wood-frame cottage; MiMo low-rise; later stucco suburban/townhouse.

Each archetype has an HTML sheet, a complete `*-sheet.png` specification sheet, and a paired-view artwork PNG. Street 3/4 is on the left; aerial 3/4 on the right. Each sheet includes four colour variations with exact hex labels, roof family/pitch, dimensions, setback, access, yard treatment and the three requested screen-size tiers. Combined archetypes use a representative main form; alternate forms are specified in the JSON and sheet notes rather than shown as additional buildings.

## Method and evidence

The regional catalogue supplies the house families, qualitative street character and cited evidence. Exact dimensions, selected pitches, subtype controls, palette combinations and block mixes are design proposals unless explicitly inherited from the approved contrast pack. Catalogue pitch and setback ranges are themselves proposal ranges, not measured metropolitan statistics. Shares are not asserted as empirical prevalence. Evidence URLs and licence notes accompany each archetype in the JSON and expandable HTML notes. New details unsupported by the catalogue are labelled proposals.

Readability priority: roof silhouette and massing; wall/roof colour; porch, bay and carport voids; then dormers and openings. Under 6 px retain silhouette and colour. At 6–20 px add porch/bay/carport voids. Above 20 px add dormers and openings. These thresholds are proposed design controls, not a device benchmark. Incidental fine masonry, foliage and grass in the illustrations are not runtime geometry requirements.

## Approved lighting and values

The `sharedLighting` object and the four approved `houseTypes` values were copied unchanged from `house-contrast-v1/paintover-values.json`; original house values are preserved under `approvedHouseValues`, with relevant inherited values attached to archetypes. Shared clear mid-afternoon sun: elevation 40°, azimuth 225°; exposure +0.35 EV, contrast 1.06, saturation 1.08. No metro-specific lighting grade is introduced. Units are metres, pitch degrees from horizontal, and hex colours sRGB appearance targets.

The imagery targets that same approved Style B lighting using the approved images as references. AI illustrations do not establish exact renderer exposure, photometric equality, camera matrices or pixel-level hex matches. Generator values are the numerical authority. The source pack’s legacy anchor-mapping ambiguity remains documented in JSON; it has not been silently reinterpreted.

## Block paint-overs

Chicago and Denver use the available current repository render compositions from lookloop run `20261007-062707`; paths and hashes are in JSON. Camera/road/sidewalk composition is a reference, not a solved camera or surveyed preservation guarantee. Each block shows a locally plausible proposed mix, not all city house families forced together.

No available Miami engine capture was found. Miami therefore uses the Denver street-camera composition with proposed Miami buildings and landscape. It is explicitly a proposed Miami scene, not a captured Miami block.

## Provenance and use

Artwork was generated/refined with the built-in image-generation tool. The complete prompt set and reference paths are saved in `archetypes-values.json` under `generation.promptSet`; input and artwork hashes support review. Boards and specification-sheet PNGs are browser exports of the same local HTML layout. No logos or real addresses are included. Underlying map attribution: [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright). Source data licence requirements remain applicable; these illustrations do not grant additional rights to underlying datasets.

## Verification

Checked: 16 archetypes, 3 street scenes, four colour variants per archetype, three screen tiers, selected pitches/setbacks within their declared catalogue proposal ranges, and unchanged approved lighting/house-value objects. Phone gallery checked at 390 px width for image loading and horizontal overflow. PNG boards and complete specification sheets are exported alongside the HTML. No engine integration, GPU, thermal or on-device performance claim is made.
