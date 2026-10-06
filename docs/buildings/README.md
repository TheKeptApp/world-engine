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
| Facades | `Sources/WorldGen/BuildingFacades.swift` | Facade pass (gate gaps 1 and 5): family window sizes, symmetric Colonial fronts, entry kits (portico, Tudor vestibule, arched surround), masonry sills and lintels, mapped street bays dressed, shallow inferred street bays where the space in front is clear, long side-wall window rhythm. All switched on per family in `house-families.json`. |
| Generator | `Sources/WorldGen/BuildingGenerator.swift` | Role (with alley-garage and large-house evidence), family, colors, heights, roof plan, walls, roof, openings, details, per LOD. |

### Levels of detail

`BuildingLOD` (`generate(_:palette:lod:)`); distances from spec §4: near 0–50 m, mid 50–150 m,
far 150–600 m, skyline beyond (`BuildingLOD.forDistance`). `DetailLevel.full` maps to near and
`.simple` to far, so the current renderer gets the new buildings with its old triangle load
(far ≈ old `.simple` per km²). Mid and skyline need the renderer to switch by distance (5A).

| LOD | Contents |
|---|---|
| near | Everything: banded walls with baked AO, roof assembly with soffits and fascia, chimney with cap, dormers, framed windows, porches, stoops, rear porches with rails and stairs, portico columns and steps, vestibule surround and roof undersides, masonry sills and lintels, bay fascia and window frames |
| mid | Masses and roof assembly with eaves, chimney body, unframed window rhythm, porch and rear-deck silhouettes, portico platform + beam + pediment, vestibule and bay masses with glass; no dormers, rails, steps, columns, sills, lintels or frames |
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
- `FacadeKitTests`: porticos and vestibules stand only in front of the front wall, along it and at
  most 1.6 m out (+0.12 m rake), with no columns at mid; inferred bays project ≤0.6 m, are 2.4–3.2 m
  wide, are sealed (rays from inside the bay hit something), exist at near and mid only, and vanish
  when a neighbor stands 1.5 m in front; mapped bays are dressed and never doubled.
- `BuildingAreaTests` also holds the facade-pass budget against the pre-pass averages per house
  (near ≤ +45 %, mid ≤ +25 %, far and skyline unchanged) and prints bay and entry-kit counts.

### Tools

- `scripts/p2_gate_shots.sh <dir>`: engine captures (BuildingLab in its own simulator);
  `scripts/p2_compose_gate.py <captures> <out>` makes the side-by-side sheets.
- `scripts/building_shots.sh <out.png> [args]`: one BuildingLab capture (`-area`, `-profile`,
  `-date`, `-focus`, `-look LAT,LON,H,HEADING,PITCH,FOV`, `-overview LAT,LON,DIST,PITCH,YAW,FOV`, `-frame16x9`).
- `swift run -c release buildingviz …`: CPU debug renderer for building close-ups in under a second
  (`--area/--profile/--center/--radius/--lod/--yaw/--pitch/--dist`, or `--gallery --profile ID`;
  `--gallery … --local X,Y` aims at one cell: footprints start at x = 25 × column, y = −48 × row).

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
15. **Family window sizes are data** (`windowWidth`/`windowHeight`, own salt `window-size`, so the
    old openings stream is unchanged): Colonial 1.0–1.2 × 1.5–1.8 m; Tudor 0.65–0.8 × 1.3–1.5 m
    casements in mullioned pairs on street walls ≥ 5 m; Prairie 0.8–0.95 × 1.0–1.25 m in ribbons of
    three (`windowGroup`), as many ribbons as fit with ≥ 1.2 m of wall between; Queen Anne
    0.9–1.05 × 1.5–1.75; Shingle 0.95–1.15 × 1.35–1.6; frame cottage 0.85–1.0 × 1.4–1.65; Victorian
    row 0.85–1.0 × 1.7–1.95; stacked, greystone and six-flat 0.95–1.1 × 1.75–2.0 (clamped by the
    story to about 1.9). v2 §4.2 spacing still rules: 0.45 m corners, 0.35 m between, fewer
    windows before smaller ones. These exceed v2's ordinary 0.8–1.2 × 1.1–1.5 m on purpose: the
    concepts (01, 03, 05) show tall revival and city windows; requested in the P2 facade brief.
16. **Symmetric fronts** (Colonial, six-flat): window columns mirrored about the centered door, the
    same columns on every story, clear of the entry, spread evenly to 0.6 m from the corners, and
    one window over the door upstairs unless the portico pediment reaches its sill.
17. **Entry kits** (`entry`, `entryChance`; covered porches take precedence). *Portico* (Colonial,
    75 %): platform at foundation height with steps, two square 0.22 m posts (four on fronts
    ≥ 13 m, 35 %), entablature beam closed underneath, 24° pediment; 2.0–3.6 m wide, 1.3–1.55 m
    deep. Flat roof when the main eave leaves no room for the pediment; none below 2.3 m clear.
    *Vestibule* (Tudor, 70 %; chosen over an arched-entry surround because it carries the steep
    gable of concept 01/03): 1.7–2.3 m wide, 1.0–1.3 m deep, 48–54° gable with a stucco gable
    panel, arched (pointed) door in a stone surround; when its gable would reach the main eave the
    ridge runs back under the main roof inside the footprint, otherwise it ends at the wall.
    Both need the ground in front clear of the own footprint, other buildings, roads (+0.6 m) and
    mapped sidewalks; a portico that doesn't fit falls back to the old pediment, a vestibule to
    the arched surround alone. Mid keeps platform, beam and pediment (portico) or the vestibule
    mass and door; columns, steps and the surround are near only.
18. **Masonry sills and lintels** (`lintels`: brick bungalow, stacked brick, greystone, six-flat),
    near only, on street walls and bay faces: sill 0.13 m high projecting 0.10 m, lintel 0.28 m
    projecting 0.07 m, both in the trim (stone) color and 0.14–0.18 m wider than the opening each
    side; skipped on faces too narrow for them. Side walls keep the plain trim frame.
19. **Mapped street bays** (`mappedBays`): a street-parallel face 0.9–5 m long between two short
    (≤ 2.2 m) side or 45° faces, standing 0.25–1.8 m in front of the walls beside it, and not the
    front-door edge (that is an entry projection). Each narrow face gets one window per story
    (lintels where they fit) and the flat-roof cornice and belt course wrap the bay. Mapped bays
    are full height by construction (walls to the roof envelope; small bay masses get hips).
20. **Inferred street bays** (`bay`; a user-requested exception to spec §4.5/v2 "no unmapped
    volume", kept shallow and logged): only on the front edge, only when the footprint has no
    mapped street bay, in the larger room beside the entry, 2.4–3.2 m wide and ≤ 0.6 m deep
    (three-sided 45° or box), and only where 2.5 m in front of it is clear of other footprints
    (`obstacles`), road surface + 3 m (sidewalk band) and mapped sidewalks. Stacked brick (70 %)
    and greystone (80 %, three-sided) run full height up to the cornice; Queen Anne (80 %,
    three-sided) one or two stories under the eave with a hip cap. Windows on every face, fascia
    band under the cap, foundation band; a closed shell against the wall. Recorded per building in
    `GeneratedBuilding.inferredBays` (plan outlines) and exported as `inferredFacade` in
    scene.json decisions. Measured: 78 in South Evanston, 141 in Lakeview (most narrow city fronts
    lack the room beside the stoop or the 2.5 m clear space).
21. **Long side walls** (`sideRhythm`, all Chicagoland house families): non-street walls ≥ 12 m get
    groups of one to three windows (mostly pairs, 0.4 m apart) at the same positions on every
    story, one group per ~6.5 m with a seeded chance of a longer blank stretch, windows 0.85× the
    front width; no openings where another building touches the wall (v2 §4.2: suppress openings
    on shared walls). Shorter side walls keep the old sparse rhythm.

## Facade pass (gaps 1 and 5), measured

Average triangles per house (`BuildingAreaTests`, all buildings of each 1 km² area):

| Area | Near before → after | Mid | Far | Skyline | Near tris/km² (all buildings) |
|---|---|---|---|---|---|
| South Evanston | 401 → 416 (+4 %) | 142 → 143 | 45 → 45 | 11 → 11 | 318k → 328k |
| Lakeview (Sheil Park) | 511 → 542 (+6 %) | 167 → 168 | 53 → 53 | 14 → 14 | 1.08M → 1.16M |
| Sloan's Lake (Denver) | 429 → 429 | 191 → 191 | 91 → 91 | 19 → 19 | unchanged |

Limits held by the test: near ≤ +45 %, mid ≤ +25 %, far and skyline unchanged. Lakeview W Roscoe St
view: 48.5k → 49.8k building triangles. Largest house near 1,630. Release generation time per km²
unchanged within noise.

Before / after (`buildingviz`, same camera):

| View | Sheet |
|---|---|
| South Evanston, Wesley Ave (gate camera) | ![](facades/evanston-street.jpg) |
| Colonial fronts: portico, 5-bay symmetric windows | ![](facades/colonial-gallery.jpg) |
| Tudor: vestibule with arched door, paired casements | ![](facades/tudor-gallery.jpg) |
| Lakeview three-flats: box and three-sided bays, stone lintels and sills, larger windows | ![](facades/lakeview-three-flats.jpg) |

## Decisions: zones and yards (round 2)

22. **Per-building zone profiles.** Without a forced profile, each building takes the `regions.json`
    zone profile at its centroid (`ZoneProfiles`, one generator per profile); the area profile still
    drives season and mapped trees. A forced `WorldRecipe.profileID` remains the test override.
23. **Yards are inferred lots** ([yards.md](yards.md)): nearest-building yard cells that never cross
    roads, walkways or blocked land; dressing only, marked `origin: inferred`.
24. **Driveways only from mapped garages**; walks only from the door to the first sidewalk/street.
25. **Hedges along inferred lot lines** at owner request (spec allows boundaries only on evidence):
    profile-driven likelihood, low, one row per shared line.
26. **Parkway trees by zone spacing** in the curb–sidewalk strip; mapped trees count first.
27. **Yard ground 2 cm over the base lawn** (5A: no z-fighting at 2.5x); new palette names `yardBed`,
    `driveway`.
