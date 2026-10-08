# Status

**R approved – 2026-10-08.** Approved.

**Owner lane:** P2, P1. **Phase:** US metro expansion, after the look gate.

Style B concept art and authored values for 12 more US metros: four house archetypes and two district boards each, plus one block before and paint-over per metro.

Binding rules from the pack:
- Real mapped geometry, material and species evidence, access and terrain override every fallback value; no metro-wide prevalence is assigned.
- All dimensions, pitches, hexes, planting, ground cover and district arrangements are proposals, not measurements or abundance claims; tree lists are candidates, never current shares.
- Lighting is a clear-day review fixture (sun elevation 40 degrees, azimuth 225, +0.35 EV applied once); production sun and weather replace it; no added global pass, shadow map or day light.
- Phone detail by projected building height: under 6 px silhouette, 6 to 20 px primary structure, over 20 px selective detail, drop features under 2 px; keep roof and porch topology, foundations, terrain contact and party walls; omit brick joints, siding lines, tile ridges and leaf geometry.
- No people, dogs, brands, logos, real murals or readable signs (no casino signs); no overhead wires without geometry; district boards show relationships, not surveyed adjacency or citywide stereotypes.
- Keep the 60 fps and 10 ms total scene GPU target on the existing v2 buckets; camera, LOD and performance still need engine and device verification.

Authored or unverified: (1) Every house dimension, pitch, hex, setback and lot width, plus ground, planting and district arrangements (48 houses, 24 districts), is authored. Only some local family presence has a source; the README calls the rest plausible proposals needing district survey. (2) St Louis, Kansas City, New Orleans, Portland and Salt Lake City had no catalog rows: each rests on one or two official excerpts that support forms or settings, not shares. In the JSON, Las Vegas has no architecture rows (one design guide, four palm candidates). (3) Tree lists are candidate or historical evidence, never shares. San Diego tree rows are search evidence only (direct source inaccessible); Las Vegas palm ranks unknown. Minneapolis foursquare local verification is still open, and Minneapolis sources do not establish St Paul details. (4) Lighting is an authored review fixture: +0.35 EV, shadow-to-lit 0.62 and the sky and sun values are not pixel-sampled or renderer-calibrated; shadow bearings are illustrative.

Flags for R:
- Incomplete against R's approval (8 Oct): 96 PNGs planned, 94 present, 92 intact. Missing: salt-lake-city-district-02.png, san-diego-block-paintover.png. Truncated: new-orleans-block-paintover.png, salt-lake-city-district-01.png. README names image-manifest.json, which is absent. README scope says 24 district boards and 12 paint-overs; the folder holds 23 and 11 (10 intact). The registry (7 Oct) advised asking ChatGPT to re-file before anyone builds from it.
- Look blocks differ from approved style-b-calibration-v2, which owns look. Sky stops are the pale house-contrast JSON (#73A5CC, #A2C4DC, #DBDCD1); calibration corrects them from its frames (#7AAFE2, #8FBAE7, #A0C8F2). surfacePolicy roughness (wall 0.86, trim 0.8, roof 0.9, glass 0.5, asphalt 0.92, sidewalk 0.9, foliage 0.9) differs from calibration (hard surfaces 0.82, foliage 0.92, glass 0.28) and was copied from wave2 (pending R approval). Sun, fill, shadow, exposure, contrast and saturation match. Do not compile these blocks.
- surfacePolicy water values (waterRoughness01 0.28, waterReflectionStrength01 0.3) conflict with R's 8 Oct water decision: the lake pack's values stand (roughness floor 0.18, ice 0.32, reflection 0.12 normal and 0.55 grazing). 0.28 is the water-surfaces-v1 minimum that R did not adopt. Do not compile.

Compiled into `mock-values.json` under `style-b/metros-wave3` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`).
