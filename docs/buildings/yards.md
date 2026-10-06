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
   - **Hedges** (`frontHedge`, `sideHedge`): rows of the existing bush prop (one variant per row,
     ~1.05 m spacing) behind the sidewalk and along one side lot line in the front yard. The spec only
     allows boundaries on mapped/evidenced lines; the owner asked for hedges along lot lines, so they
     are profile-driven, low (scale 0.9–1.05), and part of the inferred dressing.
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
`hedgeBushes`, `yardTrees`, `streetTrees`, `yardMillis`).
