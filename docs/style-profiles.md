# Regional style profiles

Generated detail (roofs, siding, porches, tree types…) follows a **regional style profile**. A profile is a JSON data file. Generator code never names a place (VISUAL_DIRECTION C.3).

## Files (`Sources/WorldGen/Profiles/`)

| File | What it holds |
|---|---|
| `regions.json` | Regions (lat/lon boxes) → profile ID. First match wins; anything outside every region uses `defaultProfile`. |
| `default.json` | Generic temperate profile; also the worst-case run in the generalization test. |
| `front-range.json` | Colorado Front Range (Denver-area bungalows, Denver squares, Tudors, ranches). |
| `base-palette.json` | Colors shared by all regions (lawn, asphalt, concrete, water, glass, plants…). |

## Profile fields

| Field | Meaning |
|---|---|
| `trees.deciduousShare` | Share of trees that are deciduous when OSM has no `leaf_type`; the rest are conifers. |
| `houses.roofMix` | Weights for gabled / hipped / flat roofs when OSM has no `roof:shape`. |
| `houses.roofPitchDegrees` | [min, max] roof pitch. |
| `houses.overhangMeters` | [min, max] eave overhang. |
| `houses.porchLikelihood` | Chance a house gets a front porch (else a stoop with a small canopy). |
| `houses.chimneyLikelihood` | Chance a pitched-roof house gets a chimney. |
| `houses.foundationMeters` | [min, max] raised foundation height (steps are added to reach the door). |
| `houses.windowSpacingMeters` | [min, max] window spacing along walls. |
| `houses.sidingPalette` / `trimPalette` / `roofPalette` / `doorPalette` | Weighted colors. |
| `garages.doorFacing` | `alleyThenStreet`: garage doors face the nearest alley/service road, else the street. |
| `garages.doubleDoorMinWidthMeters` | Garage walls at least this long get a double door. |
| `garages.roofMix`, `garages.wallHeightMeters` | Garage roof mix and wall height range. |

## Rules
- **OSM tags win:** `roof:shape`, `building:colour`, `roof:colour`, `building:levels`, `height`, `leaf_type`, `height` on trees.
- **Choices are seeded by OSM element ID** (`OSMRef.random(salt)`), so a house looks the same on every visit and every device. Different salts ("siding", "roof", "chimney", "bushes"…) keep choices independent.
- **New regions are data-only:** add a profile file and a region entry. No code changes.
