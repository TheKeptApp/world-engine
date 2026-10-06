# Regional style profiles and look data

Generated detail (house types, roofs, colors, porches, tree crowns…) and the look (palettes, light, weather) are **data**. Generator code never names a place (VISUAL_DIRECTION C.3). The numbers come from the [v2 visual spec](proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md).

## Files (`Sources/WorldGen/Profiles/`)

| File | What it holds |
|---|---|
| `regions.json` | Regions (lat/lon boxes) → profile ID. First match wins; anything outside every region uses `defaultProfile`. Front Range first, then non-overlapping Chicagoland boxes for `wilmette`, `evanston` and `chicago-dense-north` (town edges from OSM admin boundaries; each box's `comment` says why it is where it is). |
| `front-range.json` | Colorado Front Range: bungalow, foursquare, ranch, cottage, modern and duplex house types (v2 §4.2–4.4). |
| `default.json` | Generic temperate profile (v2 §4.5: compact gabled, broad low, two-story hipped, flat roof); the worst-case run in the generalization test. |
| `evanston.json`, `wilmette.json`, `chicago-dense-north.json` | Chicagoland profiles adopted from `docs/proposals/regions-chicagoland-miami/`; measured values are marked in their `provenance` object. |
| `seasonal-palette.json` | v2 §3.2 surface colors × four seasons (ground, lawn, tufts, four deciduous and two conifer crown colors, bushes, road, sidewalk, curb, water, sand, bark, snow). |
| `base-palette.json` | Season-independent colors: window states (day, shaded, lit at dusk/night), parking, pitch, playground, crossings, metal, lamp glow, bench, foundation, chimney, flowers, backdrop. |
| `time-of-day.json` | v2 §3.3 keys (dawn, morning, noon, golden, dusk, night): sun color and normalized intensity, sky top/horizon, ambient sky/ground, fog color and distances, shadow tint, lit-window share, **exposure**; anchor elevations; R8 fill strengths. |
| `weather.json` | Atmosphere presets for the nine weather labels (weather v1 §5, extending v2 §3.4) and the wet-surface response; loaded by `WorldEnvironment`. Wetness and snow are modeled, not per-label constants (`docs/environment.md`). |

## Profile fields (version 2)

| Field | Meaning |
|---|---|
| `seasons` | Hemisphere and the months of each season (local mean time). |
| `trees.deciduousShare` | Share of trees that are deciduous when OSM has no `leaf_type`; the rest are conifers. |
| `trees.crownWeights` | Weights for the broad / oval / spreading crown archetypes. |
| `trees.heightMeters`, `youngShare`, `youngHeightMeters` | Height range when OSM has no `height`; share of young trees and their range. |
| `trees.canopyShare` | *Optional.* Measured share (0–1) of the ground covered by tree crowns, zone level, from leaf-on aerial imagery (NAIP canopy mask). Not read by the generator yet. Set only where measured: `wilmette` 0.58. |
| `houseTypes[]` | One entry per type: `floors` (eligible range), `perFloor` height, `roof` shape weights, `pitch`, `overhang`, `porch` (likelihood, depth, frontage, style), `windows` (bay rhythm, size, optional broad window), `door`, and `colors` (A/B tuples: wall / trim / door / roof). |
| `typeRules` | v2 §4.4: footprint situation (one floor broad, two floors square, narrow…) → weights of house types. A `"comment"` string inside is allowed and ignored. |
| `typeThresholds` | Size limits `smallArea` / `largeArea` / `hugeArea` (m²) and the aspect, rectangularity and frontage limits that decide the situation. |
| `typeThresholds.smallAreaPercentile`, `largeAreaPercentile`, `hugeAreaPercentile` | *Optional.* Size thresholds relative to the local houses, as quantiles (0–1) of the area's house footprint areas; expected order small < large < huge. Intended generator rule: if a percentile is present and the area has at least 30 house candidates, that threshold = this percentile of the area's house footprint areas; otherwise the absolute m² value is used. Every engine profile carries 0.02 / 0.865 / 0.99 (where front-range's 60 / 220 / 350 m² sit among Denver's Sloan's Lake houses: 0.021 / 0.865 / 0.990, rounded); the absolute values are unchanged as the fallback. |
| `garage`, `shed` | Outbuilding sizes and colors. |
| `chimneyLikelihood`, `foundationMeters` | Chance of a chimney on pitched roofs; raised foundation range. |

Optional fields are decoded with `decodeIfPresent` (absent or `null` = nil); a profile without them decodes and behaves exactly as before.

**Provenance (documentation only).** A profile may carry a top-level `"comment"` string, a top-level `"provenance"` object and a `typeRules.comment` string. The decoder ignores all three (`StyleProfile.init(from:)` decodes only its `CodingKeys`, and drops non-object `typeRules` values); `StyleProfileSchemaTests` checks this. `provenance` maps a field path to its status and source, e.g. `"typeRules.unknown": {"status": "measured", "source": "OSM building:levels, …", "n": 1756, "osmTimestamp": "…", "date": "2026-10-06"}`. Fields not listed are unmeasured priors. Measured so far:
- `chicago-dense-north`: `typeRules.unknown` and `typeRules.large`, rescaled with `Tools/regionkit/regionkit.sh floors` so houses without levels get default floors 1/2/3+ = 0.10/0.62/0.28 (measured 0.075/0.68/0.245 on 1,756 levels-tagged houses; before 0.28/0.50/0.22).
- `wilmette`: `trees.canopyShare` 0.58 (NAIP 2023, one 500 m cell; `docs/research/aerial.md`).

## Rules
- **OSM tags win:** `roof:shape`, `building:colour`, `roof:colour`, `building:levels`, `height`, `leaf_type`, `height` on trees. The shared package records which choices came from OSM and which from the profile (`scene.json`: `roofShapeFrom`, `floorsFrom`).
- **Choices are seeded by OSM element ID** (`OSMRef.random(salt)`), so a house looks the same on every visit, device and renderer. Different salts keep choices independent.
- **Palette slots are stable:** seasonal surfaces take the first slots in a fixed order, so a season (or later weather) change rewrites only colors, never meshes.
- **New regions are data-only:** add a profile file and a region entry. No code changes. (Proposed regions: `docs/proposals/regions-v1/`, not adopted yet.)
