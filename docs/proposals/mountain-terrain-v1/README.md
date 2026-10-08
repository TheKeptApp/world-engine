# Mountain terrain v1 · r2 + hiking trails v1

Open [index.html](index.html). The current catalog has 20 active sheets: the existing terrain kit with five revised sheets, plus 10 trail/season/state/overlay sheets. All original scene images and poster PNGs remain; replaced HTML sheets show a SUPERSEDED notice. Original metadata copies use `-v1-superseded`; pristine original HTML copies use `-v1-original` and are listed as superseded in [supersession.json](supersession.json). Nothing was deleted.

- Sloan’s Lake: four seasonal r2 sheets add explicitly labelled west/east far-overview pairs. West reads lake→west neighbourhoods→foothills→Front Range, with no downtown tower cluster. East reads lake→downtown→flat eastern sky, with no mountain backdrop. Original street/aerial panels are retained below the corrected pair.
- Ski area: original street panel retained; aerial/far re-rendered for calibration-v2 volumetric depth, lighting, forest shade and haze.
- Trails: foothills, forest, aspen summer, aspen fall, alpine, creek bridge/boardwalk, steep switchbacks and trailhead. Each has walker’s eye, 45° aerial and far view. Shared four-state atlas covers dry summer, rain mud, supported snow and golden hour. Race sheet adds a private Builder course/aid-station overlay.

[values.json](values.json) preserves the original terrain values and exact sharedLook, adding Sloan view direction constraints and the trails section: widths/metres, surface hex/roughness/sheen, edge wear, known-structure spacing, overlapping elevation/vegetation guides, mud history, snow-data gates and projected-size tiers. Existing map/DEM/observed measurements override all unverified authoring targets. Trail widths are never inflated to keep a far route visible. Roots, drainage bars and cairns do not spawn automatically from interval/elevation defaults.

Snow only renders with valid observed/analysed snow data and timestamp; month, elevation and cold air alone never make snow. Current conditions were not fetched for these fictional concept scenes. Daily ~1 km SNODAS cannot establish metre-scale tread cover or clearance. Mud parameters are uncertain visual heuristics; golden hour changes physical sun/shadow while shared grade stays fixed.

[trails-research.md](trails-research.md) links OSM tags, Colorado completeness limitations, USFS/NPS licences, COTREX and vegetation sources. Colorado completeness is UNVERIFIED/null, not an invented percentage. USFS catalog lists CC BY4.0 for its National Forest System Trails layer; NPS public-domain policy has exceptions requiring dataset metadata review. OSM attribution/ODbL requirements are documented. **AllTrails is proprietary and excluded as data; no tracks/content were imported.** No blocked source was bypassed.

Low build cost: broad tread fields, edge blending, projected-size culling and source/status storage. Medium: terrain-conforming ribbons, local banks, bridge/boardwalk anchors, vegetation ecotones and history-driven masks. High: verified source reconciliation, maintenance structures, reliable subcell conditions and event service-envelope/site validation. These are authoring visuals, not surveyed trail geometry, construction specifications or navigation certification.

Built-in image generation created/revised the artwork; prompt/provenance records are in [prompts.json](prompts.json). Poster PNGs are in sheets/. Browser phone checks and report are in phone-check/; they do not establish iPhone GPU/Safari performance. No project files edited; no git used.

## Original v1 notes, retained

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

## Final revision verification

81 checks passed: 21 active pages and 6 superseded pages at 320 px, 390 px and 1440 px. All images loaded without horizontal overflow. Fifteen new poster PNGs were exported; key phone crops were visually inspected. This is desktop viewport simulation, not physical iPhone performance validation.

All 10 original scene-image files, the five unchanged HTML sheets and their five poster files retain their original hashes. Original values remain intact; the revision adds geography and trail settings. Superseded originals are retained. Trail scenes are visual concepts, not surveyed routes or current snow observations.
