# Mexico + Australia · Style B v1

Open index.html. Each country has 16 responsive sheets: five archetypes, three districts, a block paint-over, trees, seasonal lawns, street furniture, signals, transit, weather and night. Principal sheets contain street-level, intended 45° aerial and far-context views; lawns use four seasonal comparisons. The Australia transit sheet intentionally combines Melbourne tram and Sydney ferry contexts. This is five archetypes and three districts per country, split across the two requested cities.

style-b-calibration-v2 owns the common light, colour, exposure and material response. Its sharedLook JSON is inherited exactly, with source hash. Regional wall/roof/turf colours are authored albedo targets. Weather/night replace the daytime light fixture; exposure and wetness apply once. Calibration approval status is inherited, not newly certified by this pack.

Built-in image generation produced the sheets. prompts.json preserves prompts and reference roles; image-manifest.json records native output dimensions and hashes. Block paint-overs use generated neutral source concepts, edited with approximate retained geometry/cameras; no user-supplied photograph or surveyed block is implied. Native raster images and presentation PNG exports are included. These are visual studies, not engine meshes, measured-scale assets or navigational maps.

values.json supplies storeys, floor heights, lot widths, setbacks, palettes, illustrative tree mixes, street widths and driving side. All numerical regional targets are UNVERIFIED, representative choices, not city averages or zoning. Setbacks refer to hypothetical parcel boundaries. Tree shares sum to one by specimen count, not canopy area. Seasonal turf depends on irrigation, species and recent rain; Mexico highland wet/dry seasons differ from Sydney/Melbourne, and Australian seasons are Southern Hemisphere. Tree sheets show identifying silhouettes/flowering characteristics together, not synchronized phenology.

Australia drives LEFT; Mexico RIGHT. Signal sheets link to the existing sibling road-signs-signals-v1 country pages. Blank sign plates preserve the no-readable-signage constraint. Concept traffic placement needs engineering review before reuse as a real road plan.

research.md / research.html cite primary-source candidates for footprints, heights, elevation, OSM, weather reuse and transit. Availability is separated from verified permission and coverage. No live weather/transit or downloaded geospatial data is integrated in these images. BOM permission is product-specific; SMN feed commercial reuse remains unverified. No OSM completeness percentages are invented.

No logos, signage text, real murals/public art, dogs or app/host content. Landmark shapes are generic context only. Reference packs remain unchanged. Saved only to the designated output folder; no world-engine project changes or git.

## Files

- index.html: country gallery, responsive navigation.
- sheets/: individual HTML boards and presentation PNGs.
- images/: native generated finals and two neutral block sources.
- values.json: calibration inheritance and authored regional targets.
- research.md / research.html: cited research and unverified items.
- prompts.json / image-manifest.json: generation provenance.
- checks/: phone captures and browser-layout results.

## Verification

All 32 sheets checked at 1440px and 390px; gallery and research at 1440px, 390px and 320px: 70 browser checks passed, no horizontal overflow, missing images or page errors. Representative phone screenshots visually reviewed. All local links, image hashes, tree-share totals and calibration inheritance checked. Australia LEFT / Mexico RIGHT placement visually reviewed. PNG exports are responsive presentation sheets, not fixed camera-resolution assets.
