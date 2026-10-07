# Canada Style B v1 · Vancouver + Toronto

Open [index.html](index.html) in Safari for the gallery. Each sheet uses the Japan regional kit CSS and provides street / aerial / far artwork, proposed metre envelopes, base hexes and projected-size tiers. Phone view caps the layout at390 CSS pixels. Downloaded PNGs are artwork; HTML holds the authored labels and values.

## Contents

- Vancouver: Special, Craftsman bungalow, West Coast modern, Edwardian wood house, laneway house, tower/podium; residential-lane and waterfront district boards; block concept before/paint-over.
- Toronto: bay-and-gable Victorian, semi pair, Annex house, worker cottage, main-street mid-rise, condo/podium; residential and streetcar district boards; block concept before/paint-over.
- Canada regional: trees, yards/edges, vehicles, generic elevated/streetcar/commuter transit, street furniture, snow states.
- canada-values.json, prompts.json, sources.md and image-manifest.json.

## Style and evidence

Real proportions, grounded rich simplified matte surfaces and approved soft lighting. No photo textures, chrome detail, logos, badges, operator liveries, brands, real murals, dogs or characters. Bilingual sign layouts are two blank bands only. The calibration street is the current visual authority; house-archetypes-v1 sharedLighting is copied exactly, including older provenance limitations. Hexes are base albedos, not generated pixel samples. Apply exposure once; actual world sky/weather/solar data overrides this clear review fixture.

Every dimension, pitch, colour, mixture, district arrangement and snow amount is an authored proposal. Sources establish architectural/vegetation/transit family context, not exact measurements or regional shares. No private address is modelled. No Canadian engine frame was supplied: the block before images are original concept baselines, not current engine output; after images are source-preserving style edits with possible small local drift. Triptych views are illustrative camera compositions, not registered physical cameras or measured LOD tests.

## Phone implementation

Use longest projected extent in drawable pixels: below6 silhouette,6–20 structure,above20 selective details. Thin features need1.5px; cull decorative slats/wires rather than widening them. Keep dimensions, road/rail topology and snow/ground levels true. Tower balconies/window detail merge into bands at distance. Trees are opaque crown clusters with visible gaps, not individual leaves/needles. Glazing stays broad and subdued; no per-window reflection camera.

60fps /10ms total scene GPU remains the target. Proposed regional near carve-out35k triangles /12draws is inside the existing v2 budgets, never extra; buildings retain existing buckets. Add no global pass, shadow map or daytime light. Snow uses ground/roof fields and a few bank meshes, not duplicated whole-scene geometry. No runtime measurements or thermal tests performed.

## Country context

The country-shortlist recommends bounded Vancouver and Toronto pilots and flags ODB roof/height gaps, varying HRDEM coverage and transit/alert rights checks. This art pack does not claim those data problems are solved. Observed OSM/authoritative geometry and tags override fallback envelopes. Street tree placement and transit alignments need real mapped space; do not plant a cherry on every Vancouver frontage or assume all Toronto canopy is maple. Snow/bloom respond to weather/phenology, never a fixed calendar switch.

All files saved here only. No engine code or git operations.
