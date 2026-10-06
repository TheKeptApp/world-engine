# Building generation, phase 5B (Chicagoland)

Owner: session P2. Inputs: `docs/proposals/regions-chicagoland-miami/` (spec v1 §2–§5, §12) and
`docs/proposals/visual-v2/` (§4, §8.1). Gate report: [gate-5b.md](gate-5b.md).

## What the generator does now

| Piece | File | Summary |
|---|---|---|
| Roof masses | `Sources/WorldGen/RoofPlanner.swift` | Footprint → up to six rectangular roof masses. The largest is the main roof; every other piece of an orthogonal footprint becomes a wing whose ridge runs away from its parent and reaches back to just short of the parent's ridge, so it meets the parent in valleys. Optional flush crossing gable on single-rectangle footprints for families that call for one (Tudor, Queen Anne, Shingle), kept inside the footprint and below the main ridge. |
| Sealed envelope | `Sources/WorldGen/RoofAssembly.swift` | Visible roof = upper envelope of all masses, computed by convex clipping (no interior faces, valleys and hip intersections exact). Walls rise exactly to the envelope along every footprint edge, which also produces gable-end triangles. Where one roof edge stands above a lower roof, a vertical face closes the step. Soffits are the undersides of the overhang fragments; fascia runs only along free edges. Footprints the rectangles can't cover (slants, chamfers) get one conservative mass cut to the footprint pushed out by the eave, flagged in `roofFallback`. |
| Families | `Sources/WorldGen/HouseFamilies.swift`, `Profiles/house-families.json` | Per-family grammar keyed by the profile's type IDs: preferred frontage aspect, roof recipe (ridge direction, crossing gable, dormers, chimney placement), facade kit. Data, not code: no place names in Swift. |
| Details | `Sources/WorldGen/BuildingDetails.swift` | Chimney (cuboid + cap), gable dormers, cornices and belt courses, Prairie bands, half-timber strips on street gables, attic windows, storefront band, entry pediment, stacked rear porches with stairs, skyline LOD mass. |
| Generator | `Sources/WorldGen/BuildingGenerator.swift` | Role (with alley-garage and large-house evidence), family, colors, heights, roof plan, walls, roof, openings, details, per LOD. |

### Levels of detail

`BuildingLOD` (`generate(_:palette:lod:)`); distances from spec §4: near 0–50 m, mid 50–150 m,
far 150–600 m, skyline beyond (`BuildingLOD.forDistance`). `DetailLevel.full` maps to near and
`.simple` to far, so the current renderer gets the new buildings with its old triangle load
(far ≈ old `.simple` per km²). Mid and skyline need the renderer to switch by distance (5A).

| LOD | Contents |
|---|---|
| near | Everything: banded walls with baked AO, roof assembly with soffits and fascia, chimney with cap, dormers, framed windows, porches, stoops, rear porches with rails and stairs |
| mid | Masses and roof assembly with eaves, chimney body, unframed window rhythm, porch and rear-deck silhouettes; no dormers, rails, steps or frames |
| far | Walls and roof outline only (eaves cut to ≤0.35 m, no soffits, openings or details) |
| skyline | One extruded mass per building at mid-roof height |

### Checks (tests)

- `BuildingGeometryTests`: 12 synthetic footprints (rectangle, narrow, L, T, U, front bay, steps,
  notched corner, trapezoid, chamfer, rotated L, jitter) × 4 profiles × 12 seeds × 4 LODs: no
  inverted triangles, finite positions, sealed shells (rays from inside never escape), stable output.
- `RoofEnvelopeTests`: fragments tile the union of roof outlines exactly once and always lie on the
  highest roof; wall profiles are continuous.
- `BuildingRoleTests`: alley garages, large suburban houses, block-role evidence, family stability.
- `BuildingAreaTests`: every building of `evanston-south`, `lakeview-sheil-park` and `sloans-lake`
  at every LOD, sealing on a sample, and budget limits; prints `BUDGET` lines.
- `BuildingViewBudgetTests`: triangles in view from fixed public-street cameras with LOD by
  distance; must stay within the buildings' 170k share and the 12k optional-roof cap.

### Tools

- `scripts/p2_gate_shots.sh <dir>`: engine captures (BuildingLab in its own simulator);
  `scripts/p2_compose_gate.py <captures> <out>` makes the side-by-side sheets.
- `scripts/building_shots.sh <out.png> [args]`: one BuildingLab capture (`-area`, `-profile`,
  `-date`, `-focus`, `-look LAT,LON,H,HEADING,PITCH,FOV`, `-overview LAT,LON,DIST,PITCH,YAW,FOV`, `-frame16x9`).
- `swift run -c release buildingviz …`: CPU debug renderer for building close-ups in under a second
  (`--area/--profile/--center/--radius/--lod/--yaw/--pitch/--dist`, or `--gallery --profile ID`).

## Decisions (spec-covered, logged)

1. **Suburban test area is South Evanston, not Wilmette.** Wilmette's review window has 74 mapped
   buildings in OSM (Kenilworth 47, Winnetka 85); residential houses are essentially unmapped.
   Spec §11 (5B-1) names an inland Evanston block as the alternative. `Data/areas/evanston-south`
   (1 km², 899 buildings, public parks: Crown, Grey, Larimer) is inside the spec's
   `evanston-inland-review` window. Lakeview: `Data/areas/lakeview-sheil-park` (1 km² around Sheil
   Park, 2,861 buildings).
2. **Profiles adopted verbatim, not activated by location.** `wilmette`, `evanston` and
   `chicago-dense-north` are byte-identical copies of the proposal profiles in
   `Sources/WorldGen/Profiles/`. Per spec §16.1 the review rectangles stay out of `regions.json`;
   test areas pick the profile by explicit override (spec §2 precedence: test override first).
3. **Family grammar lives in data** (`house-families.json`), keyed by profile type IDs; families the
   file doesn't know get the plain default (old behavior).
4. **Roof = upper envelope of masses.** Wings reach back to the parent's ridge minus their overhang;
   all masses share one eave-edge height so eaves meet in clean valleys; subordinate ridges are kept
   ≥0.25 m below the main ridge by lowering wing pitch (minimum 12°). At most six masses; pieces
   under 6 m² get small hips (bay roofs). Spec §4.3: “a conservative sealed envelope is preferable
   … flag the fallback” — implemented as `roofFallback`.
5. **Flush crossing gable** (Tudor 85%, Queen Anne 90%, Shingle 35%) only on a single rectangle whose
   long side faces the street, inside the footprint (no added plan volume), width 35–60% of the
   facade (spec §3 table: “subordinate crossing gable 0.35–0.60 main width”).
6. **Turrets omitted** (spec §4.5: “for phase 5B, omit unsupported turret assets”).
7. **Dormers** only on the main roof's street slope, near LOD, 1–2 per family recipe, 0.9–2.4 m
   wide (bungalow/Shingle broad dormer), never over a wing.
8. **Optional roof detail cap 200 triangles per building** (spec §4 table), in priority order
   crossing gable → chimney → dormers; measured average is far lower (see gate report).
9. **Rear porches** (stacked wooden decks, posts, one stair run per level, solid rail bands) only on
   a rear wall that faces a mapped alley within 45 m and only if the porch rectangle is clear of
   other buildings, the alley and roads (spec §5.1, §5.6). Never on suburban families.
10. **Alley garages from evidence**: a `building=yes` of 14–75 m², at most one level, within 9 m of a
    mapped alley and not near a street, is a garage with its door on the alley (geometry + mapped
    access, not a regional expectation; spec §2). Tagged houses are never reclassified.
11. **Large `building=yes` houses** up to the profile's `hugeArea` (Evanston/Wilmette 420 m²,
    others 350 m²) and ≤3 levels stay houses instead of plain blocks (v2 §4.4 row 8). Above that,
    blocks pick a family only from tag evidence: `tall` (≥5 levels or ≥16 m), `court` (mapped inner
    ring), `commercial` (shop/amenity/commercial tags), `apartments` (apartment tags, or
    `yes` + 2–4 levels + ≥220 m²); otherwise the plain block (spec §2: unresolved roles stay simple).
12. **Greystone fronts**: street-facing walls use the profile's limestone tuple, other walls a brick
    from the family grammar (spec §5.2 “limestone facade band”).
13. **Family fit**: profile weights × soft fit of frontage aspect to the family's range (spec §3
    width/depth table); families without a range get a neutral 0.6, so narrow lots don't all
    become flat modern infill.
14. **Porch override per family**: Queen Anne (covered, 75%), Shingle (covered, 50%) and frame
    cottages (covered, 35%), because the profiles only carry one porch style (spec §3: “porch
    silhouette” is Queen Anne identity).
