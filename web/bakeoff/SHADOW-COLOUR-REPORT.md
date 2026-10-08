# A2 shadow and colour round

Scope: `web/bakeoff/` only. R's latest instruction replaces ΔE grading with A3's visual grade. The current images are **pending A3 review**; neither budget compliance nor a successful capture establishes visual parity or a hold-out visual pass. Frozen sequence: Sloan first, then Lakeview without changing code, data, date, lighting or camera. `evidence/holdout-proof.json` records the hashes; all three tier labels use the same rendering rules. Previous ΔE files are historical and are not this round's grade.

## Rules and provenance

- **Shadows:** `Sources/WorldGen/Profiles/look.json/shadows.rangeM=120` supplies the maximum horizontal caster radius. `shadow-casters.js` uses a separate shadow layer: static triangle bounds and prop origins are tested against that distance; trees use their existing P2 LOD 2 silhouette. Visible geometry is unchanged. If the entire potential shadow submission exceeds R's 150,000-triangle floor, the radius halves until it fits. Halving is a shared budget algorithm, not an authored camera adjustment. Both captures fit at 120 m. All submitted shadow triangles and draws appear in the ledger, including off-camera casters. This trades distant cast shadows and fine tree-shadow lobes for a bounded pass. No scene-name branches.
- **Crowns:** `foliage-seasons-v1/species[].seasonColours` supplies spring/summer/evergreen colour and unmapped-family fallback. The native P2/5A `Sources/WorldGen/Profiles/vegetation.json` regional autumn palettes remain authoritative for its mapped families, matching iOS's `applyingFoliageSummer` precedence. This explicitly resolves a pack conflict: several species in foliage-seasons share gold, whereas the approved native Denver mixture includes orange maple and russet oak. `vegetationRegions[region].slots` suffixes retain linden 0.55, honey locust 0.5 and elm 0.7 of summer green in Denver. `Phenology.swift/treeShiftDays=7`, `timingSalt`, and the regional calendar knots drive stable per-tree timing offsets. Leaf colours are per-instance attributes; bark retains its own palette, and no colour splits add draws. These are climatological art priors, not observed phenology.
- **Water:** `lake-winter-v1/states[id=sloans_lake_clear_wind_10].surfaceValues[0].baseColourHex=#477C8D`; `water.profiles.sloans_lake.shallowColourHex=#668C82`, `shallowBlendWidthM=2`. The shared colour conversion maps those authored colours through the calibration neutral-light witness and the inverse of the existing single exposure/saturation grade. Physical normal/light/shadow response remains. Reflected sky modulates lake luminance rather than replacing its chroma with pale blue. This is a general stylized lake-reflection rule, not physically complete coloured reflection. Reflection weights, roughness and ripple scale remain pack driven. `water.shoreline.linearBaseMultiplier=0.88`, `darkeningWidthM=0.6` darken the water-side shore; the pack explicitly forbids extra land darkening or moving the shoreline. No land recolouring is inferred from the mock.
- **Haze:** unchanged approved regional `haze-visibility-v1` anchors and mountain gate. No visibility boost or mountain relocation.

## Export family coverage

Counts below are unique building IDs across each complete view export, **not visibility/occlusion counts**. Source: `world.json` chunk `scene.json` features with `kind=building`, deduplicated by `id`. No building generator or facade geometry changed this round.

| Export | Not covered by facade-detail-v1 adapter | Unclassified | Covered / adapted |
|---|---|---|---|
| Sloan (1,399 buildings) | modern 199; minimalTraditional 114; splitLevel 83; ranch 81 | 578 | bungalow 300; foursquare 44 |
| Lakeview (2,823 buildings) | victorianRow 475; frameCottage 255; plainBlock 84; brickBungalow 21; cornerMixedUse 15; courtyardMass 6; vintageHighRise 3 | 1,112 | greystoneFacade 329; brickStackedFacade 467; sixFlat 56 (partial adapter) |

`facade-detail-v1/content.families` contains Chicago greystone/two-flat and Denver bungalow/foursquare. `facade-policy.js` maps sixFlat to the brick-two-flat detail vocabulary; **sixFlat is not a native pack family**, and that adaptation does not prove full six-flat coverage. Unclassified export buildings cannot safely be assigned a family from camera appearance. Raw counts: `evidence/shadow-colour/*-families.json`.

## Evidence and limits

Current versus calibration and current versus previous A2: `evidence/shadow-colour/{sloans,lakeview}-{side-by-side,before-after}.png` (local ignored images). A3 grade status: `evidence/shadow-colour/grade.json`. Before metadata is retained beside its captures. The initial complete trial passed the geometry budget but still showed bright cyan water; the final trial changes the shared material conversion and repeats both views. No ΔE score is used to select or accept either trial.

Full per-effect/pass/resource costs: `LAPTOP-BUDGET.md`, `evidence/phone-budget.json` and `evidence/candidate/*.json`. Timings are laptop Chrome, not measurements on an iPhone. Hero/standard budgets and texture ceilings remain unfiled. No laptop-only effect is selected. The pages are frozen fixtures; navigation and dynamic shadow-proxy rebuilding are not qualified for main-viewer integration in this round.
