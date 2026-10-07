# Realism levels · A / B / C

Open [index.html](index.html) for the same calibration street at three levels side by side, followed by matching 390 × 600 CSS-pixel portrait crops. Individual full-resolution PNGs are in images/. Crop rendering uses CSS object-fit: cover with the same centre position for all three, so it does not synthesize new geometry.

## A) Rich Style B

Japan regional kit level: real proportions, matte broad forms, restrained seams, simplified glass and foliage.

**Phone build difficulty: Medium (judgment).** Preserving convincing silhouettes at low mesh counts; smooth crown shading, stable contact shadows and consistent colour across an entire city. Dense foliage and elevated infrastructure still need instancing and careful LOD.

Strong silhouettes and clean material separation survive shrinking. Near people keep realistic anatomy with no face or identity detail.

## B) Grounded realism

Realistic brick, asphalt, foliage and glass; near-photoreal generic vehicles and anonymous people; buildings slightly simplified.

**Phone build difficulty: High (judgment).** Coherent PBR material authoring and streaming, glass/environment reflections, foliage overdraw, softer indirect light, contact shadows and natural human animation. Control texture frequency to avoid shimmer; use bounded probes rather than a live reflection camera per object.

Fine material detail adds richness nearby but much disappears at phone size. Spend first on silhouettes, lighting and animation.

## C) Full photoreal

Photographic materials, subtle weathering, detailed foliage, realistic sky and reflections; same anonymous people and fictional transport.

**Phone build difficulty: Very high (judgment).** High asset and texture memory, fine geometry, complex foliage, realistic reflections/transparency, indirect light and shadow quality, temporal stability and sustained GPU/thermal load. A photographic still does not establish a viable 60 fps phone renderer.

Many costly differences become subtle at phone size. Do not accept this target from a still image without a moving device test.

Latest owner direction: preserve the accepted vehicle/person realism, remove vehicle make/model cues and facial identity, retain near/mid/far tiers. A remains Japan-kit Style B; B/C are comparison options, not an automatic style change. Prior versions are in ../superseded-photoreal-2026-10-07/ and ../superseded-matte-candidate-2026-10-07/; the ambient archive folders are alongside its gallery.

The scene is a composite, not mapped adjacent Chicago geography. Composition was locked through source-image edits but minor generated differences remain; no exact pixel registration, physical camera, material calibration or GPU test is claimed. Lighting values inherit the bible's approved authored mid-afternoon block. Ratings and implementation suggestions are judgments, not researched or measured performance claims. Generated via the built-in image tool; prompts.json records the process. No git.
