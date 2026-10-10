# P2 Batch 2: sidewalk road-clip, commercial evidence (9 Oct 2026)

Both experiments are **default off** and region-independent: `-lookexp roadclip` and `-lookexp commercialpoints` (`Sources/WorldGen/LookExperiments.swift`). No shader, grade, exposure or palette table is touched. Map data © OpenStreetMap contributors.

Capture settings: exposure **pinned at gain 1.0**, capture only. 5A is measuring the real converged exposure and may change that recommendation. Sky clear, wind 0, no character, cameras as [Batch 0](../p2-native-ladder-b0/README.md).

## Controls and budget (6 views)

Each view has `-off`, `-roadclip`, `-commercialpoints` and `-off-control` (a byte copy) frames. Pairs and hashes are in [manifest.json](manifest.json).

**OFF against current main:**
- Byte-identical: Sloan's 40 and Lakeview 40/150/600.
- Sloan's 150 and 600 m: at most 1/255 (42 and 40 bytes).

**Main triangles / draws, OFF → roadclip → commercialpoints:**

| View | OFF | roadclip | commercialpoints |
|---|---|---|---|
| Sloan's 40 | 312,880 / 53 | 312,606 / 53 | 312,880 / 53 |
| Sloan's 150 | 333,744 / 50 | 333,464 / 50 | 333,744 / 50 |
| Sloan's 600 | 228,013 / 43 | 227,999 / 43 | 228,001 / 43 |
| Lakeview 40 | 295,759 / 56 | 295,759 / 56 | 295,196 / 56 |
| Lakeview 150 | 271,763 / 48 | 271,763 / 48 | 271,961 / 48 |
| Lakeview 600 | 194,160 / 35 | 194,160 / 35 | 193,754 / 35 |

Every view stays under the floor budget (<400k triangles, ≤100 draws).

## 1. Sidewalk road-clip (`RoadClip.swift`; `SceneGenerator.generate` mapped sidewalks and non-crossing paths)

Where a mapped sidewalk or path crosses a street carriageway at more than 30°, that span is cut out, one 0.25 m sample beyond the carriageway edge. This mirrors `RoadMarkings.crossingSpans` for crossings.

Crossing runs on the carriageway (sidewalks plus paths, measured on the centreline):

| Area | Before | After |
|---|---|---|
| Sloan's | 164 runs / 1,023 m | **0** |
| Lakeview | 66 runs / 54 m | **0** |
| Wilmette | 27 runs / 19 m | **0** |

**Kept on purpose:** Sloan's 4 runs / 24 m that lie *along* an over-wide carriageway (a width issue, not a crossing). Alleys are outside the rule.

**Correction to the audit:** the two 40 m spots I cited there are not crossings. At Lakeview, the sidewalk crosses an alley mouth (`service=alley`, 22 m from the eye), which is realistic. At Sloan's, a sidewalk ends at the curb. So their 40 m frames barely change; the visible change is at 150 and 600 m.

Close crops: [close-crops.png](close-crops.png).

## 2. Commercial evidence (`SceneGenerator.commercialRefs`, `BuildingGenerator.role(for:)` / `blockFamily`)

The rule: a mapped `shop=*` or restaurant/bar/pub/cafe/ice_cream/fast_food point inside a footprint of **250 m² or more** makes it a commercial block, using the approved mixed-use strip:
- **Lakeview:** the existing `cornerMixedUse` (facade-detail-v2b chicago-cornerMixedUse).
- **Sloan's:** new `denverMixedUse`, built from **facade-detail-v2 `denver-mixed-use`** (approved 8 Oct): 3 storeys, 3.1 m floors, parapet 0.45–0.85, cornice 0.18–0.4, wall #898D72, trim #C6BEAA, accent #B19874, roof #625F59. It reuses the cornerMixedUse grammar (storefront, cornice, tall windows). Its window width and height come from the profile's duplex, since the pack gives none. It is used only when the experiment is on.

Buildings that change:

| Area | Changed | From |
|---|---|---|
| Sloan's | **26** | The plain flat fallback (`modern`). That includes the 21 retail/commercial outlines that had no Denver family. |
| Lakeview | **24** | plainBlock 11, sixFlat 6, victorianRow 4, greystone 2, ranch 1 |
| Wilmette | **0** | — |

Close-ups: [storefront-closeups.png](storefront-closeups.png), from 4 extra captures (one converted building per area, 40 m away, OFF vs ON).

**Gap:** at a 45° pitch the ground-floor storefront bays barely show; the change reads mainly as colour and roof.

**The 17 smaller Lakeview buildings** (shop/food point, 91–234 m², 5.8–15.5 m wide; the 18th holds only a worship point). **Recommendation: do not convert them.**
- 12 of the 17 are 8.6 m wide or less, and 3 are one storey.
- The 3-storey, 16 m chicago-cornerMixedUse would distort their size.
- Instead, keep the house family and add a one-bay ground-floor storefront (3–4.5 m bay, `storefrontBayWidthM`) on the street face. That needs a recipe ruling or brief: no approved pack covers storefronts under 250 m².
- It would affect 17 Lakeview buildings, 0 at Sloan's and 0 at Wilmette.

## 3. What is missing for other kinds (report only)

| Kind | Missing | Buildings affected (Sloan's / Lakeview / Wilmette) |
|---|---|---|
| Worship | A pack (nave and tower massing, roof pitch, window and stone cues) via a ChatGPT brief. No recipe exists. | 0 / 4 / 3 = **7** |
| Civic / school / fire / station | A pack for civic families (school block, fire-station bay doors, station canopy) | 1 / 2 / 5 = **8** |
| Restaurant / bar storefront | R's ruling on food cues (awnings, patio seating, deeper glazing; no signs or brands) plus a small brief. The generic storefront exists. | food features 17 / 37 / 0 (buildings ≤ that) |
| Golf | An area kind plus pack values (fairway/rough/green/bunker tones, mow stripes) | 0 / 0 / 0 in these areas |

**Park vs cemetery** are currently one row in `SceneGenerator` (`.park, .cemetery → ("lawn", GroundLayer.park, 0.97)`). Keys that would separate them:
- `seasonal-palette.json surfaces.cemeteryLawn[4]`
- An area-dressing table: `cemetery.headstoneSpacingM`, `.rowBearing`, `.headstoneSizeM`, `.pathWidthM`
- `park.treeDensityPerHa` and `park.pathMowContrast`

Used: classification-audit README §4/§7; facade-detail-v2 content.families[denver-mixed-use] and v2b chicago-cornerMixedUse (R approved 8 Oct); RoadMarkings.crossingSpans. Mock: facade-detail-v2 denver-mixed-use values (no image consulted for roadclip). Deviation: denverMixedUse window size from the profile duplex; 4 extra close-up captures beyond the 18; storefront bays not legible at 45°.
