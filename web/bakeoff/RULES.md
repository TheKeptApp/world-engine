# A2 shared-look and hold-out rule — R, 8 October 2026

Sloan’s Lake is evaluated first. Lakeview follows with identical code and no tuning. Every look decision is a general rule driven by source data, region, season or time. No object, colour, light, haze, wave or material is placed or adjusted to improve one camera.

`policy.js` receives pack data and a shared simulated fixture, never a camera or scene ID. `fixture.json` supplies one summer/clear/10 km/h fixture to both views. The sun, sky, exposure, saturation, matte materials and neutral witness ratio come from `style-b-calibration-v2/sharedLook`. Renderer light units are derived from the Lambert factor and witness ratio instead of the earlier visually fitted 2.3/4.0 intensities and 0.55 sky multiplier. No per-city colour correction remains.

`lake-winter-v1/water.haze.fixtureExtinctionPerM` now applies once to all geometry in both scenes, including distant terrain. The previous separate mountain haze is removed. This fixture may obscure real distant mountains; geometry is not enlarged or shifted to compensate. Water roughness, shore darkening and projected-wave fade use the lake pack. `water-surfaces-v1/waveModelProposal` owns spectral normalization. Fixed dimensionless sampling patterns are renderer algorithms, not spatial scene edits.

Foliage candidate species come from `foliage-seasons-v1/cities[].mix`; prototype class and variant select deterministically. These are explicitly inferred candidates, not surveyed inventories or verified frequencies. Exported positions, scale and geometry bounds remain the spatial source. Existing geographic DEM data remains unchanged.

Both camera fixtures and viewports are frozen from the previous commit. A camera defines the evaluation view, not the appearance policy; camera query overrides are removed. Physically necessary view dependence (projection, Fresnel, LOD, shadow coverage) is not a camera-specific appearance adjustment.

`verify.sh` forces Sloan then Lakeview. `freeze.mjs` hashes renderer files, scene/fixture data, shared viewer sources, packs, calibration frames/boxes and both exported worlds before and after every capture. Any change aborts the run. `evidence/holdout-proof.json` records the ordered timestamps and identical digest. No Lakeview feedback is used to revise the frozen look in that run.

The hold-out is not blind: Lakeview was seen in earlier work. This test establishes unchanged-code transfer, not statistical independence or a passing visual grade. Region-colour scores are against the calibration-v2 images and fixed boxes; the matched-camera existing viewer is a separate control. Missing sample coverage stays missing.

## Sky, haze and crown revision

Sky appearance targets are encoded through the inverse of the installed ACES/grade transfer, then rendered through the existing single post pass. This corrects a colour-domain error; exposure, saturation and the pack swatches are unchanged. `weather-moments-v1/inherited.sharedLighting.sky.gradient` defines 0°/30°/90° world-elevation anchors; calibration-v2 owns the corresponding horizon/mid/zenith swatches and 18% cloud coverage. One StableRandom-seeded cumulus panorama serves both cameras; no view-specific cloud placements exist.

Crown topology follows `foliage-seasons-v1/species[].crown.description`, lobe-count tiers, sky-hole proposal and contact-darkening proposal. Opaque smooth lobes retain separate layered silhouettes and branch gaps. Geometry is fitted back to the original exported envelope, and the local StableRandom port uses the repository’s SplitMix64/FNV1a arithmetic.

The haze coefficient remains exactly `lake-winter-v1/water.haze.fixtureExtinctionPerM = 0.0008`. At 20 km, T = exp(-16) = 1.125×10⁻⁷; at 50 km, T = exp(-40) = 4.248×10⁻¹⁸. This contradicts a clear, visible Front Range and the calibration mock. `mountain-terrain-v1` separately proposes clear extinction 0.00001/m, but this revision does not substitute it or tune the lake value. See `data/haze-conflict.json`; source-pack precedence must be resolved. Mountains are neither enlarged nor exempted from shared haze.

`FACADE-AUDIT.md` records which façade capabilities already exist and which details are absent. It is a report only; no generator or exported geometry was modified.

The sky revision also restores the existing R-approved `Tools/lookloop/mock-corrections.json` entry `look-v2-sky-from-frames`, explicitly required by calibration-v2/STATUS.md. Its sky stops are #7AAFE2 / #8FBAE7 / #A0C8F2, shared across all views. The previous literal pale JSON stops were an implementation error, not a reason to resample or tune either camera. The correction is copied verbatim into `data/sky-correction.json`, and both files are included in the hold-out hash. Cumulus uses a compact lobe field with azimuth-stratified deterministic seeds and coverage from the shared pack.

## Phone-budget follow-up (R, 8 October)

Hero means iPhone 15 Pro and up, standard 14–15, floor 12–13. R clarified that no separate numeric tier budgets are filed: apply the documented 400k main-view triangles / 150k shadow triangles / 100 main draws to FLOOR, account for every pass including shadows, and report actual hero/standard counts without inventing limits. No texture ceiling is filed. The same effects, resolution and code run at all three labels; a label does not simulate its phone GPU. Haze stays at the pack value until the new pack is filed. The shared declaration is in `budget.js`.

For this revision, `foliage-seasons-v1/species[].crown` selects the low end of the near/mid lobe-count ranges and three far masses to retain vertical layering. The pack has no numeric lobe radii: occupied crown volume divided by lobe count supplies a derived radius, with spreading/vase flattening and seeded low-frequency asymmetry. That algorithm is an implementation interpretation, not a new botanical measurement. Lower-poly opaque smooth lobes replace dense sphere meshes; exported positions/envelopes and all colour/light/haze values remain fixed. Every effect's actual pass counts and GPU texture/renderbuffer allocation ledger are recorded. Millisecond costs require real-device GPU profiling and are not inferred from desktop FPS.

The initial Sloan-only preview rejected a far-LOD disc collapse. All LODs now derive vertical lobe radius from crown depth as well as width; far masses preserve layers instead of reducing to one flattened patch. No Lakeview result was used to select the correction.

Merge-time note: main `6ce875f` filed approved haze-visibility-v1 after this phone-budget run was frozen. The current comparison preserves its frozen coefficient to isolate crown costs; migration to the newly controlling haze pack remains a separate, explicitly uncompleted integration. It is no longer accurate to describe the new pack as unfiled.

## Approved haze migration (R, 8 October)

R explicitly requested this migration after the budget round. `haze-visibility-v1` now supersedes the old 0.0008/m fixture: `regions[id=front-range].seasons.summer.clear` (75 km MOR, 0.000039943097/m) and `regions[id=great-lakes].seasons.summer.clear` (20 km MOR, 0.000149786614/m). Climate region is scene data; a shared resolver takes region/season/state/time, never camera or score. Compiled `data/haze-values.json` preserves the two regional tables plus definition/airlight/mountain/integration rules and the source hash. These are simulated authored fallbacks, not live measurements.

`airlight.stateDayHex.clear` (#BDD0D9) is decoded to linear light; `timeMix.day=0`. The current panorama is authored, not a calibrated physical directional sky model, so this implementation chooses the pack fallback. There is one homogeneous `T*lit + (1-T)*airlight` mix. `integration.applyOnce` excludes the sky and already-atmospheric sky-reflection contribution. Calibration exposure, saturation, materials, crown shapes, terrain positions, cameras and viewports are unchanged.

`mountains.retainContrast=.05`, `cullContrast=.03`, `internalDetailContrast=.10`, `minProjectedHeightPx=2` govern the real DEM. Per-fragment contrast uses pre-fog lit luminance; alpha fades .03–.05 and discards below .03 or the projected-size gate. Below .10, diffuse shading is averaged within the existing mountain pack distance bands; averaged shading cannot rescue a previously failing silhouette. Geocentric terrain and world depth occlusion preserve sightlines; no refraction or summit-obscuring cloud layer is supplied by this explicit clear fixture. Azimuthal DEM ridge relief uses the existing mountain pack's 0.1° horizon sampling for the projected-size test. The 256² source is coarse, so neither this nor the mock establishes survey-grade sightlines.
