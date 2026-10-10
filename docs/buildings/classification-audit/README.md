# Business and landmark classification + sidewalk overlap: P2 audit (9 Oct 2026)

Report only: no code, defaults, shaders or palette changed. Counts come from main `5ded499`. Sources:
- Engine output: a temporary test, not committed, ran `WorldBuild.generate` with zone profiles and UTC 2026-10-15.
- OSM source: each area's `Data/areas/*/osm.json`. Point-in-polygon tests use OSM building ways; multipolygon buildings are not included.

Map data © OpenStreetMap contributors. Crops: [crops.png](crops.png).

**Short answer:** no. The engine reads business tags only on the building outline, and only for large "block" buildings. It ignores shop/amenity points inside buildings, and it has no worship, civic, industrial or golf look.

## 1. What the engine draws (unique buildings)

| Area | Total | House | Apartment | Mixed-use / commercial | Civic / worship | Industrial | Unknown fallback (plain block) | Garage / shed |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Sloan's Lake | 1,399 | 779 (55.7%) | 0 | 0 | 0 | 0 | 42 (3.0%) | 578 (41.3%) |
| Lakeview | 2,823 | 1,547 (54.8%) | 65 (2.3%) | 15 (0.5%) | 0 | 0 | 84 (3.0%) | 1,112 (39.4%) |
| Wilmette | 1,258 | 816 (64.9%) | 0 | 0 | 0 | 0 | 21 (1.7%) | 421 (33.5%) |

- Lakeview "house" includes the flat families brickStackedFacade (583) and greystoneFacade (269).
- Wilmette is 1,212 Overture footprints plus 46 OSM buildings.
- Sloan's 13 retail and 8 commercial outlines all land in the fallback: the front-range profile has no commercial family.

## 2. Tags in the source data

| Area | Shop / food tag on building outline | Point inside a building | Point with no building | Worship | Golf |
|---|---|---|---|---|---|
| Sloan's | shop 2, food 6 | shop 19, food 11 | 0 | 0 | 0 |
| Lakeview | shop 6, food 3 | shop 17, food 34 | 1 shop area | 2 outline + 2 points | 0 |
| Wilmette | shop 2 | 0 | 1 shop point | 3 church outlines | 0 |

"Food" means restaurant, bar, pub, cafe, ice_cream or fast_food.

Other areas:
- Parks: Sloan's 1, Lakeview 3, Wilmette 4.
- Cemeteries: Wilmette 1.
- No `leisure=golf_course` in any of the three areas.

## 3. Tags the engine reads and ignores

**Read:**
- `BuildingGenerator.blockEvidence` (`Sources/WorldGen/HouseFamilies.swift`). On **block-role outlines only** it reads `building=commercial|retail|mixed_use`, `shop=*`, `building:use`, and `amenity` ∈ {restaurant, cafe, bar, pub, fast_food, bank, pharmacy}.
- `YardGeneration` (`Sources/WorldGen/Yards/YardGeneration.swift:128`): `shop` on an outline means no yard.
- `MapFeatureBuilder.areaKind` (`Sources/WorldMap/MapFeatureBuilder.swift`): park, cemetery and grave_yard become lawn (`SceneGenerator` areas, shade 0.97). Golf only reaches lawn in the distant context ring (`ContextFeatures.swift`).

**Ignored:**
- Shop/amenity points, in the generator. They appear only as map labels (`WorldPackage/MapLayer`).
- `amenity=ice_cream` and `place_of_worship`, and `building=church`, which becomes a plain block.
- `leisure=golf_course` in the core world.
- Any business tag on a house-role outline: `building=yes` under 250 m², or `building=house`.

## 4. Plain buildings hiding an ignored shop/amenity point (the key number)

These are `building=yes` or `house` outlines with no business tag of their own, but with a shop/food/worship point inside:

| Area | Buildings | Points inside them |
|---|---:|---|
| Sloan's | **1** | 8 |
| Lakeview | **39** | 14 shop, 14 restaurant, 4 fast_food, 4 cafe, 4 bar, 1 pub, 1 ice_cream, 2 worship |
| Wilmette | **0** | — |

At Lakeview, 18 of the 39 are under 250 m² and are drawn as houses; the other 21 are larger. Separately, Sloan's other 29 inside points sit in retail/commercial outlines, which draw as the fallback (item 1).

## 5. Golf courses, parks and cemeteries

- Parks and cemeteries are flat lawn, the same as grass (crops: Sloan's lakeshore park, Wilmette parks).
- The Wilmette cemetery cannot be told apart from the parks: no headstones or paths.
- No golf course exists in these areas to show.

## 6. Proposed rules (not built, region-independent, unknown fallback unchanged)

| Rule | Tag → look | Reuses | Buildings changed |
|---|---|---|---|
| R1 | Shop/food point **inside** an outline counts as outline evidence, for any role. Add `ice_cream` and `place_of_worship` to the read list. Commercial → small mixed-use strip / storefront. | `cornerMixedUse` (house-families.json) and facade-detail-v2 "small mixed-use strips" (approved 8 Oct). Each region profile needs a commercial family entry, which is a data change. | Sloan's ≈22 (1.6%), Lakeview ≈37 (1.3%), Wilmette ≈3 |
| R2 | Worship (`place_of_worship`, `building=church/chapel`) → a gabled tall block | **No recipe exists (gap).** Would need a pack or R's ruling; the interim is the plain block. | Lakeview 4, Wilmette 3 |
| R3 | `leisure=golf_course` → a lawn area kind with mown fairway shade | Existing lawn slot | 0 in these areas |

## 7. Sidewalks and driveways over the road

**Generator counts** (street carriageways only; alleys excluded):

| Area | Mapped sidewalk runs on the carriageway | Other mapped paths |
|---|---|---|
| Sloan's | 137 runs / 880 m | 30 runs / 178 m |
| Lakeview | 62 runs / 59 m | 0 |
| Wilmette | 25 runs / 20 m | 0 |

**Driveways: 0 of 1,168** end inside a carriageway. `YardGeneration.march` stops them at the road or walkway raster.

**Visible in the frames:**
- Lakeview 40 m: 2 sidewalks run unbroken across the side street.
- Sloan's 40 m: 2–3 stair-stepped sidewalk corner blocks step into the junction.
- These are counted by eye at 40 m. At 150 m they are too small to count.

**Cause: draw order plus missing clipping. It is not width/offset overlap, and not driveways.**
- `SceneGenerator.generate` draws mapped `features.sidewalks` (`addLines`, 1.6 m, `GroundLayer.sidewalk` 0.06) and non-crossing paths (0.05) over the road (0.04).
- Only `isCrossing` paths are cut to the carriageway (`RoadMarkings.crossingSpans`).
- So any mapped sidewalk that continues across a side street, or meets it at a corner, paints concrete over the asphalt.
- Generated sidewalks (`Streetscape.generatedSidewalks`) already keep 2 m clear of other roads.

**Fix (P2, `Sources/WorldGen/SceneGenerator.swift`):**
- Subtract street carriageway spans (centreline distance < width/2) from mapped sidewalks and non-crossing paths, using the same subtraction already used for crossings.
- On the carriageway, leave bare asphalt, or crosswalk paint where `RoadMarkings` gives it.
- This is region-independent, with no new geometry budget. Pixels change, so it would ship default off for A3 scoring.

**Recommendation:** next build the sidewalk carriageway clip (fixes R's phone bug in every area), then R1 (point-inside-outline commercial evidence, ≈37 Lakeview buildings).

Used: docs/execution/archetypes.md, facades.md, docs/buildings/README.md, facade-detail-v2/v2b README/STATUS, house-archetypes-v1/README.md, REFERENCE-MAP.md, DECISIONS.md. Mock: none (audit; crops from Batch 1 OFF frames and 5A wilmette-600). Deviation: multipolygon buildings and Overture outlines not used for point-in-polygon; frame overlap counts are visual at 40 m.
