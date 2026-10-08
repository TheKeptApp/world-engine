# Facade detail v2

8 October 2026 · Style B · concept pending approval

Six added families for Sloan’s Lake / Denver and Lakeview / Chicago: multi-unit apartment blocks, courtyard apartments and small mixed-use strips. Every family has near, mid and far construction panels. Two detail sheets cover wall junctions, windows, entry portals, cornices, storefront recesses and fences. Tan and olive stucco/brick options retain the approved calibration look.

[Gallery](index.html) · [Values JSON](values.json) · [Prompts](prompts.json) · [Sources and overlap](sources.md)

This supplements facade-detail-v1; it does not replace it. INDEX and the drop folder were checked first. house-details-v1 already supplies general courtyard principles; v2 makes those principles specific to these six city/family studies.

Denver examples have three full storeys. Chicago apartment and mixed-use examples have four; the courtyard has three residential storeys over a low raised basement. Mixed-use storey counts include the commercial ground floor. These are generic visual families, not mapped replicas or claims that every block contains them.

Keep courtyard wings and the real open court at every distance. Preserve commercial ground-floor identity and a separate residential entrance. At middle distance retain bay/portal mass and repeated floor rhythm; at far distance merge windows and remove small details. The panels present detail tiers at comparable illustration size; they are not measured engine camera captures. Actual LOD thresholds refer to projected drawable pixels in values.json.

Era palettes are authored associations, not surveyed paint samples or a date classifier. Dimensions are unverified visual defaults; real footprint, height and known access geometry take priority. The sharedLook block is inherited unchanged from style-b-calibration-v2, with no city-specific exposure override.

No signs, logos, readable lettering, murals, people, dogs, vehicles or host-app content. Made with built-in image generation; full prompts included. Existing files remain unchanged. No git.

Delivered: 8 reviewed boards, 30 individual panel PNGs, responsive gallery, values JSON, era palette cards, sources, original and correction prompts, and image manifests. Phone checks at 320 and 390 px and desktop check at 1080 px passed with no overflow or missing images. Shared look verified identical to the calibration pack.

[Panel manifest](panels/manifest.json) · [Phone check report](phone-check/report.json) · [Correction prompts](revision-prompts.json)

## Immutable albedo correction · 8 October 2026

Near, mid and far use identical base colour and material assignments. Only detail fades. Distance tint belongs to [haze-visibility-v1](../haze-visibility-v1/README.md), applied after surface lighting. The comparison boards disable haze. Explicit equal material values per LOD are stored in values.json; shaded raster pixels are not a measurement of albedo. Earlier colour-drifting boards and values are retained in superseded/pre-albedo-fix-2026-10-08/.

Coverage of the corrected family list: Chicago plainBlock maps to chicago-apartment, courtyardMass to chicago-courtyard. The strip is not a cornerMixedUse study; that is added in v2b.

## Delivery verification — 8 October 2026

8 boards and 30 separate phone panels. Gallery checked at 320, 390 and 1080 px: no horizontal overflow or missing images. All 6 families pass identical near/mid/far material-albedo checks. Shaded illustrations are qualitative references; values JSON defines exact albedo. See `verification.json` and `phone-check/report.json`.
