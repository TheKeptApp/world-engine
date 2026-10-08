# haze-visibility-v1 — STATUS

**APPROVED by R — 8 Oct 2026.** Binding field-level haze/visibility target. This owner approval supersedes the delivered README/JSON's historical pending-approval label; source files are preserved byte-for-byte. Approval does not establish engine integration or measured regional climatology.

## Precedence

Use `values.json` → `definition`: **5% meteorological optical range (MOR), not 2%**. `sigmaPerM = -ln(0.05)/(1000 × visibilityKm)`; recompute legacy visibility equivalents, never merely relabel them. Exact paths and the 21 weather-moment migrations are in `overrides`.

| Prior pack | Fields overridden | Preserved scope |
|---|---|---|
| lake-winter-v1 | Background `/water/haze/fixtureExtinctionPerM` and transmittance formula | Water colour, waves, ice, shore and snow mechanics |
| weather-moments-v1 | Inherited background haze, homogeneous before/after `fog.sigmaPerM`, and `visibilityEquivalentM` conversion | Event content, light/time intent, wetness, snow history and independently specified local layers |
| mountain-terrain-v1 | Background clear, summer-haze and storm extinction profiles | DEM, LOD, curvature, terrain and snow rules |
| night-fog-v1 | Background/far haze coefficients | Local ground fog 0.035/m, layer bounds and patch masks; darkness alone does not increase density |

This is field-level precedence, not replacement of those packs. Prior pack files and images remain unchanged. Calibration-v2 exposure, saturation and matte materials remain controlling.

## Mountain rule

`mountains.retainContrast = 0.05` and `mountains.minProjectedHeightPx = 2`: retain a real map/DEM-positioned silhouette only with **retained horizon contrast ≥0.05 AND projected height ≥2 px**, an unblocked curved-earth sightline and no summit-obscuring cloud. Fade through contrast 0.03–0.05; omit internal folds below 0.10. Integrate layered atmosphere along the ray; MOR is not a hard geometry cutoff. Never brighten, enlarge or move mountains to compensate.

## Consumers and phase

- **A2 now:** consume inside `web/bakeoff/` for the current map/look gate; integration and paired Sloan's/Lakeview scoring remain lane deliverables.
- **5A on restart:** migrate weather-moments and the shared background atmosphere, preserving local fog and unrelated pack fields.
- **A3:** filing and tracker handoff only; no renderer or compiled engine-value changes in this filing.

The expanded values JSON is reference data; consumers should select/compile needed fields, not load the complete derived reference into the engine. Regional/seasonal envelopes remain authored, unverified fallbacks. Observation freshness and censored visibility handling are specified in the source pack. Smoke remains parked; filing its conditional values does not activate it.
