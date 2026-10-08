# A2 shared-look and hold-out rule — R, 8 October 2026

Sloan’s Lake is evaluated first. Lakeview follows with identical code and no tuning. Every look decision is a general rule driven by source data, region, season or time. No object, colour, light, haze, wave or material is placed or adjusted to improve one camera.

`policy.js` receives pack data and a shared simulated fixture, never a camera or scene ID. `fixture.json` supplies one summer/clear/10 km/h fixture to both views. The sun, sky, exposure, saturation, matte materials and neutral witness ratio come from `style-b-calibration-v2/sharedLook`. Renderer light units are derived from the Lambert factor and witness ratio instead of the earlier visually fitted 2.3/4.0 intensities and 0.55 sky multiplier. No per-city colour correction remains.

`lake-winter-v1/water.haze.fixtureExtinctionPerM` now applies once to all geometry in both scenes, including distant terrain. The previous separate mountain haze is removed. This fixture may obscure real distant mountains; geometry is not enlarged or shifted to compensate. Water roughness, shore darkening and projected-wave fade use the lake pack. `water-surfaces-v1/waveModelProposal` owns spectral normalization. Fixed dimensionless sampling patterns are renderer algorithms, not spatial scene edits.

Foliage candidate species come from `foliage-seasons-v1/cities[].mix`; prototype class and variant select deterministically. These are explicitly inferred candidates, not surveyed inventories or verified frequencies. Exported positions, scale and geometry bounds remain the spatial source. Existing geographic DEM data remains unchanged.

Both camera fixtures and viewports are frozen from the previous commit. A camera defines the evaluation view, not the appearance policy; camera query overrides are removed. Physically necessary view dependence (projection, Fresnel, LOD, shadow coverage) is not a camera-specific appearance adjustment.

`verify.sh` forces Sloan then Lakeview. `freeze.mjs` hashes renderer files, scene/fixture data, shared viewer sources, packs, calibration frames/boxes and both exported worlds before and after every capture. Any change aborts the run. `evidence/holdout-proof.json` records the ordered timestamps and identical digest. No Lakeview feedback is used to revise the frozen look in that run.

The hold-out is not blind: Lakeview was seen in earlier work. This test establishes unchanged-code transfer, not statistical independence or a passing visual grade. Region-colour scores are against the calibration-v2 images and fixed boxes; the matched-camera existing viewer is a separate control. Missing sample coverage stays missing.
