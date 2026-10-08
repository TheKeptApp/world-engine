# Facade detail v2b

8 October 2026 · Style B · concept pending approval

The corrected family request supplements v2. New Denver / Sloan’s families: ranch, minimalTraditional, splitLevel, modern. New Chicago / Lakeview families: victorianRow, frameCottage, brickBungalow, cornerMixedUse, vintageHighRise. Chicago plainBlock is covered by v2’s broad apartment block; courtyardMass by its open U-shaped courtyard apartment. Generic mixed-use strip does not cover the corner condition.

[Gallery](index.html) · [Values](values.json) · [Prompts](prompts.json) · [Coverage](coverage.md)

Each new family has a near/mid/far sheet and a phone-width panel per tier. Detail sheets and grouped era palettes supplement those comparisons. Keep half-floor offsets, row-house bay rhythm, bungalow versus cottage roof shape, wraparound corner shopfronts and high-rise setbacks identifiable at every distance.

**Base colour never changes with LOD.** Near, mid and far use identical base albedo and material assignments; only detail fades. The comparison sheets disable atmospheric haze. [haze-visibility-v1](../haze-visibility-v1/README.md) owns distance tint after surface lighting. This pack does not alter that system or introduce a second haze curve. Identical JSON colour values specify the rule; shaded raster pixels are illustrative and do not prove measured albedo equality.

Lighting and materials inherit style-b-calibration-v2 unchanged. Existing house-archetypes-v1 remains the approved geometry/palette authority where applicable; these are detail and family-recognition studies. Dimensions and era-finish associations are authored, unverified defaults; mapped facts take priority. Era colour is not a construction-date classifier. No engine performance or integration claim.

No signs, logos, readable text, murals, people, dogs, vehicles or host-app content. Built-in image generation used; original/correction prompts included. All deliverables in the drop folder; no project files changed and no git.

## Delivery verification — 8 October 2026

11 boards and 37 separate phone panels. Gallery checked at 320, 390 and 1080 px: no horizontal overflow or missing images. All 9 families pass identical near/mid/far material-albedo checks. Shaded illustrations are qualitative references; values JSON defines exact albedo. See `verification.json` and `phone-check/report.json`.
