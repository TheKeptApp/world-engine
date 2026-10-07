# Yards, lots, walks and street trees (generator side)

Owner: P2. A general engine feature: any area with mapped buildings and streets gets inferred yards,
entry walks, driveways where a garage gives evidence, planting and street trees, all from data rules
per style profile. Output is generator data and instances only; materials and lighting stay with the
renderer (5A).

## Pipeline (`Sources/WorldGen/Yards/`)

1. **Ground-use raster** (`LotRaster`, 1 m): roads (mapped width), walkways (mapped sidewalks, paths,
   generated sidewalks), blocked land (parks, water, pitches, parking, playgrounds, cemeteries,
   commercial landuse, woods), buildings (scanline fill).
2. **Lots**: open cells go to the nearest yard-owning building by 8-neighbour shortest path that never
   crosses a road, walkway or blocked cell and stops at the profile's `maxLotDepth`. Houses and
   residential blocks own yards; other buildings (shops, churches, schools) claim a 6 m margin so houses
   don't take their surroundings; garages and sheds are obstacles inside lots.
   Lots are **inferred**: `GeneratedLot.origin == "inferred"`, a dressing aid only, never a parcel
   boundary and never used for navigation (regions spec §3, §7). Outlines are traced on cell borders
   and simplified (staircases become straight lines).
3. **Dressing per lot** (all seeded by the house's `OSMRef` with yard salts):
   - **Lawn** polygon at `GroundLayer.yard` (2 cm over the base lawn) with the lawn slot and `.lawn`
     flag, a per-lot shade (`lawnShade` range) and `extra.y` = lawn care 0–1 (renderer hook for
     dry/lush tone). Seasonal colour stays the palette's job.
   - **Front walk** (`frontWalk` likelihood): straight from the door (`GeneratedBuilding.entry`, set at
     every LOD) to the first sidewalk or street, 1.1 m, sidewalk paint. Inferred lot lines don't stop it.
   - **Driveways**: only from a mapped garage's door (alley apron ≤ 12 m, street drive ≤ 40 m), never
     invented without a garage (spec §3: no invented access). `driveway` palette colour.
   - **Foundation bed** (`beds`): mulch strip along the front wall, skipping the door (`yardBed` colour).
   - **Shrubs** (`shrubs`): a flowering pair at the walk, a few more along front lot edges.
   - **Hedges** (`frontHedge`, `sideHedge`): straight rows of 1 m hedge segments (bush variant 5,
     yawed to the row; see the look-fix section) behind the sidewalk and along one side lot line in the front yard. The spec only
     allows boundaries on mapped/evidenced lines; the owner asked for hedges along lot lines, so they
     are profile-driven, ~0.95–1 m high (scale 1.0–1.06), and part of the inferred dressing.
   - **Specimen trees** (`yardTreesPerHouse`): back yard preferred, ≥3.5 m from walls, ≥7 m from other
     trees, species and size from the zone profile's tree rules.
4. **Parkway trees** (`streetTreeSpacing`, `minParkway`): along vehicular streets (not service, track,
   motorway, bridges, tunnels), centred in the strip between curb and sidewalk when it is wide enough,
   else 2.2 m from the curb where there is no sidewalk; never near intersections, drives, walks,
   buildings or existing trees (mapped trees count first).
5. **Litter hints** (`GeneratedScene.litterHints`): curb lines, hedge rows, walk edges with weights.

Shrubs, hedges and beds are made only near the focus region; lawns, walks, drives and trees everywhere.

## Data

`Sources/WorldGen/Profiles/yards.json`, keyed by style profile ID (`default` fallback). Seeded from the
regions proposal's `proposedAdditions` (street-tree spacing 18 m suburbs / 17 m city, yard trees 1.4 /
0.65 per house). P1's measured `trees.canopyShare` is the calibration target when present.

Zones: `ZoneProfiles` resolves the profile per building centroid through `regions.json` when no
profile is forced (`WorldRecipe.profileID == nil`); yards use each building's profile.

## Outputs

`GeneratedScene.lots`, `GeneratedScene.litterHints`, yard meshes in chunk static meshes (features
`gen:lot:`, `gen:walk:`, `gen:driveway:`, `gen:bed:`), instances with sources `gen:shrub:`, `gen:hedge:`,
`gen:yardtree:`, `gen:streettree:`, stats (`lots`, `walks`, `driveways`, `beds`, `shrubs`,
`hedgeSegments`, `yardTrees`, `streetTrees`, `yardMillis`).

## Look-fix v1 (§1, §2) — round 3

Densities and colours now follow `docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md` §1 (ceilings/priors per
region, not quotas), in `Profiles/yards.json`:

| Zone (profile) | Street-tree spacing | Yard trees / lot (cap) | Extra shrubs | Bed area | Lawn endpoints |
|---|---:|---:|---|---|---|
| North Shore (`evanston`, `wilmette`) | 15.5 m | mean 1.6 (≤3) | 5–9 + foundation | 12–26 m² | North Shore row |
| Lakeview (`chicago-dense-north`) | 18.5 m, strips ≥0.8 m | mean 0.3 (≤1) | 1–3 | 2–6 m² | Lakeview row |
| Denver (`front-range`), `default` | 17 m | mean 1.0 (≤2) | 3–6 + foundation | 8–18 m² | Denver row |

- **Lawn**: four value steps per zone (`lawnShade`, 5 % apart); neighbouring lots (cells touching or one
  cell apart) get steps one or two apart, never equal (4–10 % value difference, no stripes). Vertex
  `extra.y` = the lot's tone t (0…1) between the season's endpoint pair, exported as the seasonal
  palette keys `lawnA` / `lawnB` (overridden per area profile from `lawnEndpoints`); the renderer mixes
  `base = mix(lawnA, lawnB, t)`. `extra.w` = a per-lot seed for the renderer's analytic patch field.
  `GeneratedLot` carries `lawnShade`, `tone`, `seed`, `ruleVersion` = 2.
- **Beds**: depth 0.6–1.2 m toward the zone's bed area along the front wall (door kept clear), plus
  side returns at the front corners when the front alone is short; ±2.5 % value per bed.
- **Shrubs**: placed on front-yard lot edges and foundation positions (counts per lot unchanged, from
  `shrubs`). The site picks the form (bush/flowerBush variants, `SceneGenerator.shrubVariant`, seeded per
  shrub): **cushions** (2, 6, 7: low rounded, wide two-mound, compact four-lobe) in foundation beds and
  front gardens; **upright** (4, ~1.35 m, narrow) beside the walk and at lot corners (two cell sides
  leave the lot) and house corners (footprint vertex within 2.2 m); lot-edge shrubs a mix of **loose**
  (3, leaning ~7°, 40 %) and cushions. The original round bushes (0, 1) are no longer placed in yards.
- **Hedges**: each row is a straight line through the row's cells, built from **hedge segments**
  (variant 5, 1 m along the segment's +X) laid end to end every 1 m, yaw = row direction (half turned
  end for end), scale 1.0–1.06. Stat `hedgeSegments` (was `hedgeBushes`).
- **Shrub triangles**: near 72 (80 with flowers), mid 20 (hedge 16), far 8 (hedge 6), skyline 3–4; the
  old round bushes were 80/20/8. Generated shrub+hedge triangles in view (YardTests street cameras)
  went from 19 610 / 12 584 / 13 082 / 11 312 / 17 444 to 18 444 / 11 108 / 11 810 / 10 520 / 15 820
  (Lakeview street / alley / block centre, Evanston street, Wilmette street), −9 % overall.
- **Trees**: per-lot caps apply to yard and canopy-calibration trees; generated trees avoid repeating
  the variant of the nearest three of the same form (no-op while tree kinds have one mesh variant; the
  renderer varies crowns by per-tree stretch).
- **Leaf litter** (`GeneratedScene.litterPatches`): 1–3 patches per deciduous tree inside its crown,
  radius 0.4–1.2 m, three tones (#AA753F / #BD914F / #8C7145), never on carriageways or buildings; the
  renderer's fall season weight shows them (zero in January).

**Tones (§2, `docs/m3/tone-targets.md`)**: a guard in `house-families.json` `toneFloors` keeps
generated roof base colours at or above #303942 (Y8 56) and walls at or above Y8 80, gains 1.0. Every
current profile colour already meets both (roofs Y8 90–112, walls 128+), so **no hex changes**; the
dark rendered roofs are the renderer's shade lift (0.17 vs 0.30–0.38), which 5A is fixing.

## Known gaps (logged for later)

- **Chicago red-brick and cobblestone streets** (owner, 2026-10-06; ground-v1 pack): some Chicago
  alleys and side streets are brick or cobble. Needs a mapped `surface=paving_stones|sett|unhewn_cobblestone|bricks`
  road surface treatment; not built.
- **Chicago willow family** (owner, 2026-10-06; vegetation-v1): a weeping-willow crown family for
  Chicago-area water edges and parks; not built.
- Ground passes stopped after pass 3 (worn edges): lawn micro-detail doesn't read at phone size.
  Remaining ground work uses `docs/proposals/ground-v1` for large value/colour/contrast changes only.
