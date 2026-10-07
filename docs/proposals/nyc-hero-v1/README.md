# NYC HERO PACK v1

Rich Style B, leaning real: attached New York streetwalls, credible floor proportions, restrained matte materials, organic street trees and soft light. Open **index.html** for the responsive gallery. Each study has street-level, intended 45° aerial and far views. On a phone, individual sheet panels stack vertically instead of shrinking into an unreadable three-column strip.

## Contents

- **26 native PNG triptychs / 78 view panels** in `images/`.
- **26 individual sheets** in `sheets/` (HTML and presentation PNG exports).
- **5 category boards** in `boards/` (HTML and PNG exports): archetypes, districts, infrastructure, bridges/water, light.
- **values.json**: versioned, metre-based authoring targets; storeys, floor heights, frontage/depth, palettes, street allocation, tree spacing, bridge masses and light states.
- **prompts.json**: final prompt set, with exact first-sheet prompt; **generation-manifest.json** records the local reference and original generated file for each asset.
- **sources.md**: primary references and the distinction between sourced typology and authored dimensions.
- **checks/**: phone-width captures and layout verification results.

## Coverage

Archetypes: Brooklyn brownstone; Upper West Side prewar co-op; Manhattan tenement walk-up with exterior fire escapes; Queens attached brick rowhouse; Bronx Art Deco apartment; glass tower/podium; cast-iron SoHo loft.

Districts: Park Slope; Upper West Side; East Village; SoHo; Midtown canyon; Astoria; Financial District. The districts are representative visual compositions, not reconstructions of specific addresses. Astoria carries outer-borough elevated transit; Manhattan districts do not.

Infrastructure: side-street and avenue allocations, protected bike lane, generic subway entrance, steam vent, scaffolding shed, hydrant and sidewalk tree pits; a separate elevated-transit study preserves the steel viaduct’s scale and location.

Bridges/water: stone-tower suspension, steel-tower suspension and rigid steel cantilever are separate structural families. East River esplanade and rectangular Hudson piers are separate waterfront studies. These are generic type studies, not landmark studies; bridge names in descriptions indicate inspiration, not exact reproduction.

Light: midday canyon shade with brighter cross-street openings; Manhattanhenge-style cross-street sunset; winter low sun; rainy night with restrained reflections; snow on brownstone stoops. Each light state replaces the relevant clear-day conditions. Do not add the clear-day sun/exposure underneath night or overcast states.

## Scale and modeling handoff

Use **values.json**, not image pixels, as the dimensional authority. Values are representative authored kit presets, not measured NYC inventory or construction specifications. Generated raster architecture and the requested camera angles are illustrative and may vary between panels. This pack contains art direction and numeric targets, not metric meshes or an engine scene.

Storeys mean full above-grade floors. Raised basements are explicit separate fields; the brownstone has three full above-grade floors plus one visible raised-basement level. Overall heights include the stated starting elevation and cornice/parapet. Lot width means frontage, and larger apartment buildings use assembled lots. Public right-of-way includes carriageway plus both sidewalks; private stoops/setbacks are additional. Bike allocations are subdivisions of the carriageway, not extra road width.

Near detail carries stoop treads, metal rails, actual fire-escape flights, cast-iron profiles and tree pits. Mid detail preserves bays, cornices and bridge structure. Far detail preserves block rhythm, roofline, material families and tower silhouettes. Keep full-scale modeling units across all three tiers.

Palette hex values are appearance targets, not measured material albedo. The approved house-contrast shared-light block is retained as a reference in JSON; the generator does not demonstrate exact exposure, shadow bearing or material calibration. Non-reflective materials remain matte; glass and wet paving are deliberate exceptions. Do not make every surface glossy at night.

## Generation and review

Created with the built-in image-generation tool, using the approved house-archetypes / house-contrast visual references. First sheet references the Chicago two-flat sheet; subsequent sheets reference the generated brownstone triptych for a consistent richer finish. No external image-generation API or git was used. Full prompts and provenance are included.

Review focuses on typology, locality, three-distance readability and the requested exclusions. No characters, dogs, logos, signage, copied murals or public art are intended. Skyline towers are generic silhouettes. Browser checks cover the local HTML at desktop and 390×844 phone width; they do not establish a mobile 3D performance benchmark.
