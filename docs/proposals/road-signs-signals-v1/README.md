# Road signs + signals v1

Seven country sheets: US, Canada (Ontario baseline), UK (GB baseline), Netherlands, Mexico, Australia (Queensland baseline), Japan. Each includes street and 45° aerial views plus sign and signal/crossing catalogues. Open index.html; a country page selects any of its four panels at phone size.

## Look and meaning
Style-b-calibration-v2 owns look. Its sharedLook is copied unchanged into road-signs-values.json: 40°/225° clear afternoon sun fixture, matte simplified surfaces, neutral asphalt, one exposure. Time/weather replaces that fixture. Signs remain true size; shape and colour carry character rather than readable text. No real names, brands, numbers or pseudo-writing. Standard pictograms are allowed. Blank boards intentionally omit legal legends; this pack is visual world dressing, not navigation or a compliant traffic-control plan.

Country data must retain jurisdiction/local overrides. Japan uses a triangular stop family; its slow reference must not be imported as a universal yield sign. Mexico's speed symbol belongs on a square regulatory board. UK signal crossings and zebras are distinct variants. Highway guide families differ by road class. Mast-arm/post and head orientation must follow site data; optional hardware cannot be assumed everywhere. Normal vertical lamp order is red/amber/green; Japanese horizontal reference is green/amber/red. Specific signal assemblies and their normative drawings remain verify-first where not obtained.

## Values and placement
JSON contains per-country sign dimensions, mounting heights, lens/assembly sizes, pole reach and corner spans, palette, driving/placement side, marking and school/rail families, evidence notes and official links. All hexes and assembly dimensions are authored proposals unless a separate verifiedAnchor says otherwise. A colour class from a manual is not a certified screen hex. Mounting means underside, not pole top. Sign clearance and signal clearance are different fields.

Do not repeat signal poles at a fixed interval: corners, sightlines, crossing position and road span determine them. Preserve mapped positions and orientation. Inferred dressing has deterministic stable IDs and provenance; missing mapped signal control cannot become a live light. Simulated states must avoid conflicting greens; unknown real state stays unknown/dark. School warning alone does not set a speed, and no real school hours are invented.

## Phone/performance proposal
Near signs retain visors/borders/pictograms; mid removes small hardware; far keeps only real-size shape/colour; below 2 projected pixels cull ambient dressing. No sign or lamp inflation and no readable sign texture. Instance shared heads/posts, use one opaque palette atlas, put road markings in the road material and avoid a point light per signal. Proposed envelope: 16k triangles, four batches, 1 MiB atlas, 0.25 ms GPU inside the scene budget. These are allocation targets, not measured A16 results. Gallery phone checks do not test an engine shader.

## Files
- images/: seven full-resolution PNG sheets.
- index.html and country pages: gallery with four panel selectors.
- road-signs-values.json: profiles, dimensions, sharedLook and source status.
- sources.md: official references, access limits and verify-first list.
- prompts.json / manifest.json: built-in imagegen provenance and image hashes.
- verification.md / verification.json / phone-check/: layout and image review.
- road-signs-signals-v1.zip: complete pack.

Research/design only. Generated cameras are approximate, not surveyed or exact engine projections. No project files, builds or git operations.
