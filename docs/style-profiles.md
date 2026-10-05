# Regional style profiles and look data

Generated detail (house types, roofs, colors, porches, tree crowns…) and the look (palettes, light, weather) are **data**. Generator code never names a place (VISUAL_DIRECTION C.3). The numbers come from the [v2 visual spec](proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md).

## Files (`Sources/WorldGen/Profiles/`)

| File | What it holds |
|---|---|
| `regions.json` | Regions (lat/lon boxes) → profile ID. First match wins; anything outside every region uses `defaultProfile`. |
| `front-range.json` | Colorado Front Range: bungalow, foursquare, ranch, cottage, modern and duplex house types (v2 §4.2–4.4). |
| `default.json` | Generic temperate profile (v2 §4.5: compact gabled, broad low, two-story hipped, flat roof); the worst-case run in the generalization test. |
| `seasonal-palette.json` | v2 §3.2 surface colors × four seasons (ground, lawn, tufts, four deciduous and two conifer crown colors, bushes, road, sidewalk, curb, water, sand, bark, snow). |
| `base-palette.json` | Season-independent colors: window states (day, shaded, lit at dusk/night), parking, pitch, playground, crossings, metal, lamp glow, bench, foundation, chimney, flowers, backdrop. |
| `time-of-day.json` | v2 §3.3 keys (dawn, morning, noon, golden, dusk, night): sun color and normalized intensity, sky top/horizon, ambient sky/ground, fog color and distances, shadow tint, lit-window share, **exposure**; anchor elevations; R8 fill strengths. |
| `weather.json` | v2 §3.4 weather states and the wet-surface response (hooks; not rendered yet). |

## Profile fields (version 2)

| Field | Meaning |
|---|---|
| `seasons` | Hemisphere and the months of each season (local mean time). |
| `trees.deciduousShare` | Share of trees that are deciduous when OSM has no `leaf_type`; the rest are conifers. |
| `trees.crownWeights` | Weights for the broad / oval / spreading crown archetypes. |
| `trees.heightMeters`, `youngShare`, `youngHeightMeters` | Height range when OSM has no `height`; share of young trees and their range. |
| `houseTypes[]` | One entry per type: `floors` (eligible range), `perFloor` height, `roof` shape weights, `pitch`, `overhang`, `porch` (likelihood, depth, frontage, style), `windows` (bay rhythm, size, optional broad window), `door`, and `colors` (A/B tuples: wall / trim / door / roof). |
| `typeRules` | v2 §4.4: footprint situation (one floor broad, two floors square, narrow…) → weights of house types. |
| `typeThresholds` | Aspect, rectangularity and frontage limits that decide the situation. |
| `garage`, `shed` | Outbuilding sizes and colors. |
| `chimneyLikelihood`, `foundationMeters` | Chance of a chimney on pitched roofs; raised foundation range. |

## Rules
- **OSM tags win:** `roof:shape`, `building:colour`, `roof:colour`, `building:levels`, `height`, `leaf_type`, `height` on trees. The shared package records which choices came from OSM and which from the profile (`scene.json`: `roofShapeFrom`, `floorsFrom`).
- **Choices are seeded by OSM element ID** (`OSMRef.random(salt)`), so a house looks the same on every visit, device and renderer. Different salts keep choices independent.
- **Palette slots are stable:** seasonal surfaces take the first slots in a fixed order, so a season (or later weather) change rewrites only colors, never meshes.
- **New regions are data-only:** add a profile file and a region entry. No code changes. (Proposed regions: `docs/proposals/regions-v1/`, not adopted yet.)
