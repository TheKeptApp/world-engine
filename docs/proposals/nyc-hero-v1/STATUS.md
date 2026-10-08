# Status

**R approved – 2026-10-08.** Approved.

**Owner lane:** P2, 5A, P1. **Phase:** Hero market New York, after the look gate.

Rich Style B art direction plus metre-based authoring targets for New York: seven building types, seven districts, a street and transit kit, bridge and waterfront types and five light states, each drawn at street level, 45-degree aerial and far.

Binding rules from the pack:
- values.json, not image pixels, is the dimensional authority; values are representative authored presets, not measured NYC inventory or construction specs; raster geometry and camera angles are illustrative.
- Definitions: storeys are full above-grade floors (raised basement separate); overall height includes starting elevation and cornice or parapet; lot width is frontage; right-of-way is carriageway plus both sidewalks (private stoops and setbacks extra); bike lanes subdivide the carriageway.
- Keep full-scale modelling units across near, mid and far tiers. Palette hex values are appearance targets, not measured albedo. Non-reflective materials stay matte; glass and wet paving are the only deliberate exceptions.
- Each light state replaces the relevant clear-day conditions; never add clear-day sun or exposure under night or overcast states. The copied house-contrast block is reference only.
- Elevated transit only in the outer-borough Astoria study, never in Midtown, SoHo or Park Slope. Three bridge families stay structurally distinct (the cantilever has no suspension cables); generic types, not landmark studies.
- No people or characters, dogs or animals, logos, signage, real murals or public art, app content or literal landmark towers; skyline towers are generic silhouettes.

Authored or unverified: (1) All numbers (dimensions, palettes, district mixes, street and bike allocations, tree spacing and pits, light angles) are authored proposals; sources support typology only. No survey, code compliance, bridge engineering, statistical district mix or exact site reconstruction. (2) Tree pit and spacing values: the NYC Parks planting-standards PDF could not be retrieved, and sources.md marks them Unverified. (3) Manhattanhenge bearing (sun 299 deg, avenue 29 deg) is representative, with no ephemeris or date check; winter-low-sun (15 deg, 155 deg) claims no date or time. (4) Copied house-contrast block: anchor approvedFileIdentity is still UNRESOLVED; exact engine equivalence and exposure, shadow and material calibration are not demonstrated; its appliesTo lists lakeview, denver, wilmette and postcard, not NYC.

Flags for R:
- Material response: materials.dryMasonryRoughness 0.9, glassRoughness 0.18 and foliageRoughness 0.85 versus style-b-calibration-v2 sharedLook roughness 0.82 (masonry, plaster, wood, concrete, asphalt), 0.92 (foliage) and 0.28 (glass). Calibration-v2 owns matte material response with no per-city override, so its table should win; this pack's own copied ground block already uses 0.82 and 0.92. Leaf names differ, so compile_mocks.py's conflict search will not pair them.
- Sky stops in approvedReferenceSharedLighting are the pale house-contrast JSON (#73A5CC, #A2C4DC, #DBDCD1). R's images-beat-JSON corrections (Tools/lookloop/mock-corrections.json) replace them: house-contrast now has 4 stops (#6FAFE4, #6FAFE4, #91C4ED, #A7CFED) and calibration-v2 uses #7AAFE2, #8FBAE7, #A0C8F2. Do not use this copy; the generic compile view already drops it.
- Finish: the pack targets Rich Style B leaning real, and the opened panels show visible masonry grain and detailed foliage, while its prompts ask only for restrained fine texture and a brick-scale suggestion at near tier. Calibration-v2, which owns look, calls for simplified matte albedo with no photo textures or brick grain. The pack states no precedence; calibration-v2's STATUS says it owns look.
- Light states differ from weather-moments-v1's NYC pairs, approved with it: winter low sun 15 deg / 155 deg here, 8 deg / 225 deg there (before state 25 deg); snow-stoops directSun 0 here, 0.08 there; rainy-night wetRoadRoughness 0.2-0.35 here, rain-v1 steady_rain (asphalt 0.52, patch-only reflections) there. Neither pack states precedence.

Compiled into `mock-values.json` under `style-b/nyc-hero` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). The pack's `materials` roughness block is not compiled (calibration v2 owns material response).
