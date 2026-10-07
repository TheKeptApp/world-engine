# Infrastructure, stage 1: lane markings and crosswalks

P2 (generation), 7 Oct 2026. Builds to infrastructure-kit-v1 (R approved, binding): sheets `roads-08-markings` (US lane-marking library) and `roads-09-crosswalks` (US crosswalk library). Geometry rules: `docs/research-gpt/street-geometry-rules-v1` (R: it owns geometry, the kit owns look). Code: `Sources/WorldGen/RoadMarkings.swift`, wired in `SceneGenerator.generate()`; tests: `Tests/WorldGenTests/RoadMarkingsTests.swift`.

## What is painted (only where mapped, R 7 Oct)

- **Lane lines** on through roads (motorway, trunk, primary, secondary, tertiary) only when the lane count is mapped: `lanes`, `lanes:forward/backward`, `turn:lanes*`. Two-way: double yellow at the flow boundary (`lanes:forward/backward` move it off-centre); `lanes:both_ways=1`: yellow solid/broken pair on each side of the centre turn lane. Same-direction lanes: broken white (3 m dash, 9 m gap). One-way motorway/trunk carriageways: white outer edge, yellow median edge. No per-class default paint on untagged roads.
- **Local streets, alleys, service roads:** never, unless `lane_markings=yes`. `lane_markings=no` always wins. (street-geometry-rules-v1 US residential: no longitudinal markings; OSM `lanes` there counts flows, not paint.)
- **Bike lanes:** `cycleway[:left|:right|:both]=lane` (or `opposite_lane`) on any road: solid white line between the bike lane and traffic, the bike lane sitting next to parking. If it does not fit, untagged (assumed) parking is dropped from the paint layout first, then the bike line (counted as a conflict). The road width never changes.
- **Crosswalks** only at mapped crossings: `footway=crossing` ways (paint spans curb to curb where the way crosses the road) and `highway=crossing` nodes with no crossing way (across the road at the node). Style from `crossing:markings` (`zebra*` → longitudinal bars; `ladder*` → bars + two transverse lines; `lines`/`dashes`/`dots` → two transverse lines; `no`/`surface` → none), else legacy `crossing=zebra`/`crossing_ref=zebra` → bars; `crossing=marked|uncontrolled|traffic_signals` with no style → bars, labelled inferred; `crossing=unmarked` → none; a crossing with no `crossing*` tag → none (unknown is not evidence). Bars run along the traffic direction. On the carriageway the old solid crossing band is replaced by the paint (bare asphalt when unmarked); the band stays off-road.
- **No invented crossings:** nothing at junctions or traffic signals without a mapped crossing.
- **Stop bars** only ahead of a signalised mapped crossing (`crossing=traffic_signals` / `crossing:signals=yes`): across the approach lanes, on the side away from an adjacent junction (both sides mid-block; one-way roads only on their legal approach).
- **Cut-backs:** lines stop at junction boxes (the crossing street's half-width from a shared node, junctions of three or more non-service arms; alley mouths do not cut) and at crosswalks (plus the stop-bar setback where signalised).
- **Wear:** each dash, line piece or bar darkens by a seeded 0–12 % (`OSMRef.random`); deterministic.

## Values

From the shared mock values (`Profiles/mock-values.json`, by key; `MarkingValues`):

| Key (`style-b/infrastructure/assets.` …) | Value |
|---|---|
| `roads-08-markings.dimensionsM.lineWidth` | 0.15 m |
| `roads-08-markings.dimensionsM.dashLength` | 3 m |
| `roads-08-markings.dimensionsM.dashGap` | 9 m |
| `roads-08-markings.dimensionsM.doubleLineGap` | 0.15 m |
| `roads-08-markings.dimensionsM.stopBarWidth` | 0.3 m |
| `roads-08-markings.palette.Base.secondaryHex` (white paint) | #EEE9D9 |
| `roads-08-markings.palette.Base.accentHex` (yellow paint) | #F0D067 |
| `roads-09-crosswalks.dimensionsM.crossingWidthAlongRoad` | 3 m |
| `roads-09-crosswalks.dimensionsM.stripeWidth` | 0.5 m |
| `roads-09-crosswalks.dimensionsM.stripeGap` | 0.6 m |
| `roads-09-crosswalks.dimensionsM.transverseLineWidth` | 0.3 m |
| `roads-09-crosswalks.palette.Base.secondaryHex` (crosswalk paint) | #EEE9D9 |

Not in the kit, in `Profiles/look.json` `markings` with sources: `wearShadeMax` 0.12 (authored; the kit gives no wear), `stopBarSetbackM` 1.2 (MUTCD 11th ed., stop line ≥ 4 ft ahead of the crosswalk; the kit names a stop-bar offset without a number), `bikeLaneWidthM` 1.8 (rules.csv `us_arterial` `cycle_optional_width_m`), lane widths for counting lanes when only `lane_markings=yes` is mapped and for the bike-lane fit: `highwayLaneWidthM` 3.66, `arterialLaneWidthM` 3.35, `minLaneWidthM` 3.05 (rules.csv `lane_default_m` for US motorway, arterial, residential; the kit's lane widths are superseded for geometry). Carriageway widths stay `RoadRules` (tags, lanes, parking); conflict noted, not resolved: kit residential carriageway 10.2 m vs rules 10.6 m.

## Rendering budget

Paint is baked into each chunk's existing static mesh (one `gen:markings` feature range per chunk, palette slots, `road` flag so it wets with the asphalt): **no new draws**. Layer `GroundLayer.marking` = 0.045 m, one 5 mm step over the road (0.04), the existing crossing step; the solid crossing band no longer lies under it on the carriageway, so nothing coplanar overlaps. Full-detail (focus) chunks only.

Lakeview (Sheil Park, `lakeview-sheil-park`, focus 1.0 km²): 1,707 marks, 199 mapped crossings at roads (198 painted, 1 `unmarked`), 2 bike-lane fit conflicts, **3,598 triangles ≈ 3.6 k tris/km²** (phone budget 400 k in view). Test bound: < 25 k tris/km².

## Evidence

Phone size (1005×565) CPU renders (`buildingviz --scene`, Lakeview, profile chicago-dense-north) beside the pack artwork panels (images not in the repo: `~/Desktop/world-engine/docs/proposals/infrastructure-kit-v1/roads-08-markings.png`, `roads-09-crosswalks.png`):

- `infrastructure/markings-vs-roads-08.jpg`: Ashland Ave (one-way, `lanes=2/3`, white dashes), Addison St (`lanes=2`, double yellow), Addison/Southport aerial.
- `infrastructure/crosswalks-vs-roads-09.jpg`: Addison zebra crossing at street level, Addison/Southport crossings with stop bars from the air, the brief's residential camera (41.943402,-87.66075, yaw 270: unmarked street, tagged bike-lane line).

## Gaps (not in this stage)

- Turn arrows (`turn:lanes`) are not painted yet (lanes are counted from them); the kit gives no arrow geometry.
- No curb ramps/landings, no parking-lane lines (the arterial sheet shows none), no sharrows (`shared_lane`).
- Ashland's two one-way carriageways are mapped close together, so their ribbons overlap; no median is drawn (geometry stage).
- Highways/ramps/overpasses, bridges, elevated rail, water edges, sports fields, utilities: later stages.
- RealityKit phone capture not taken (CPU renderer only, no simulators per lane rules); thin far lines may alias on device (the kit's < 6 px tier would suppress them; no distance fade yet).
