# Water surfaces v1 · WorldEngine rich Style B

Open index.html. Seven water settings (Lake Michigan, Chicago River, Sloan’s Lake, Miami ocean, SF bay, NYC harbour, Netherlands canal) and five shore families (seawall, riprap, beach, marsh, marina). Each has summer/winter nine-panel sheets: street / 45° aerial / far rows and calm / breezy / storm columns. Each page also selects a single panel at phone size. 24 generated PNGs, 24 sheet pages, values JSON, research, sources, prompts and verification.

## Design decisions
Keep real scale, smooth matte surroundings, broad readable water colour and broken restrained highlights. No sharp mirrored buildings, photographic sea textures or dense sparkling noise. Clear/breezy columns share the approved afternoon fixture; storm and actual time override it coherently. Weather-moments-v1 current sharedLighting is copied unchanged. Its Bible snapshot and precedence differences are retained rather than silently choosing an earlier light. Exposure, contrast and saturation are each owned once. One integrated atmospheric extinction field covers water and every object; SF marine fog is not an extra water haze multiplier.

Water colour reflects depth/bottom, dissolved/suspended matter and illumination/view angle. Regional hexes are artist proposals, not observed water quality. The Miami sandbar is a shallow-water design mask, not live surveyed bathymetry. Winter has no automatic water tint, freeze or snow. Shown freshwater shelves and ice pockets are cold-supported demo possibilities; production defaults unknown ice to open water with unknown provenance, and requires spatial/history evidence. Never read a whole-lake percentage as the exact Chicago shore shelf.

Use representative wave observations or a model before the wind-only visual fallback. Preserve raw Hs/period, because artistic caps do not mean real waves are small. Small canals and sheltered docks cannot inherit ocean breakers. Calm local wind does not remove swell/wakes. NOAA wind/wave direction is parsed as FROM true north; propagation uses TO. Tides need source vertical datum tied to the world, and predictions stay labelled forecast. Do not animate Chicago/Sloan with an ocean tide.

## Rendering and phone detail
Four smooth geometry waves near, two aerial, flat mean far; small ripples become normal detail and fade below 1.5 projected pixels. Opaque clipped water, coarse shared environment, one material foam mask, no FFT, planar mirror, SSR or additional scene capture in v1. Keep shore geometry fixed; surf is masked to supported/inferred shallow bands. One inherited 12% water-side contact-darkening owner, not another rain darkening pass. Shore profiles provide dry/wet endpoints and metres; broad masks replace sand grains, wood grain and individual reeds.

The proposed total water/foam/ice envelope is <=12k triangles, <=6 draws, <=4 MiB and <=0.8 ms GPU, carved out of the existing scene budget. These are targets, not measured A16 passes. Full-screen fill rate and overdraw are the first device checks. Material paths and wave math can be adapted to RealityKit/Metal and three.js; current repo integration was not inspected or edited. No code implementation, builds or git.

## Evidence and files
research.md explains mechanisms, free feed selection, caching, shader formula and implementation phases. water-values.json preserves inherited controls and separates numeric proposals from source-backed mechanisms. sources.md records documentation checked 7 October 2026, including NDBC direct-fetch 403 limitations. Missing input, station coverage, local ice geometry and exact bathymetry remain explicit unknowns. Generated cameras match approximately, not pixel-exact or surveyed. Art panel values are not renderer calibration.

Top recommendations: build the one-owner water material first; retain raw and depicted wave values separately; select feeds by basin/exposure; gate ice with spatial/history evidence; test full-screen water fill rate before adding reflections or splashes.

## Reading the art
These sheets are qualitative references. The weather columns illustrate separate scenarios; they are not a temporal sequence or proof that the wind changed an ice reservoir. Shelf shapes and shoreline extents are illustrative, and cross-panel ice differences must never become a runtime wind-to-ice rule. The JSON history policy controls the implementation. Wave count and foam coverage in generated art are approximate; the numerical caps are the implementation target. Single-panel phone previews preserve the sheet aspect ratio and select all nine combinations.

## File index
- index.html and 24 sheet pages: browsable gallery and phone panel controls.
- images/: 24 full-resolution PNG boards (216 panels).
- water-values.json: colours, wind/wave formulas, foam, reflections, ice, live-data policy and resource targets.
- research.md and sources.md: mechanisms, data sources, limits and implementation phases.
- prompts.json and manifest.json: generation provenance, dimensions and image hashes.
- verification.md / verification.json and phone-*.png: gallery checks and representative screenshots.
- water-surfaces-v1.zip: complete downloadable pack.
