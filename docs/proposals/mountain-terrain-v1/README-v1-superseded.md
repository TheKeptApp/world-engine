# Mountain terrain v1

Open [index.html](index.html). Ten sheets provide street/trail, 45° aerial and far views; the last sheet instead compares 20/50/100 km. Four Front Range seasonal scenarios, foothills town, canyon road, ski area, elevation transition and mountain lake are included. HTML stacks full-size panels on phones; sheets/ contains poster PNG exports.

Use the unchanged calibration-v2 sharedLook and inherited terrain-slope rules in [values.json](values.json). Buildings never tilt. Roads use cut/fill and retaining geometry. Snowline is history/observation-driven and aspect-dependent, never selected from the month. Far mountains retain true silhouettes with linear-light extinction and no surface texture.

## Build order and cost

- Low: broad landcover fields, seasonal phenology palette, simple snow masks with timestamps, far haze shader, projected detail culling.
- Medium: 3DEP hierarchy and stitched heightfields, mapped cut/fill roads, stepped foundations, shore geometry, tree/scree mass LOD, history-driven uncertain snow cover.
- High: robust datum/curved-Earth viewsheds, canonical infrastructure profiles, depth-bearing horizon impostors with observer-dependent regeneration, validated snow redistribution and ski operator integration.

General mountain kit: retain geometry/LOD/atmosphere rules but replace regional geology, vegetation bands, snow sources and treeline guides. Do not export Colorado’s elevations as global ecological rules.

## Evidence and limits

[research.md](research.md) links primary sources and marks all authored rendering targets and unknowns. Exact local DEM coverage and profiles remain unverified. The images are visual concepts, not georegistered DEM renders, camera-calibrated multi-views or current snow observations. Seasonal scenes are independent concept viewpoints, not pixel-registered time-lapse renders. Artwork includes illustrative small foliage/rock detail; implementation must follow the simpler JSON tiers. Phone checks are browser viewport checks, not iPhone GPU or Safari benchmarks.

All files are confined to this output folder. No project files edited; no git used. Prompts and original generated-image provenance are in prompts.json.

## Final checks

All 11 HTML pages passed at 320, 390 and 1440 CSS pixels: 33 checks, all scene images loaded, no horizontal overflow. Canyon phone layout visually inspected. Ten poster PNGs exported. JSON parsed and sharedLook equality checked against calibration-v2. Phone screenshots and report are in phone-check/. Desktop Chrome simulation only; no physical-device or GPU validation.
