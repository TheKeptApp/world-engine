# Form coverage audit (non-vegetation packs)

Date 2026-10-07. Read-only. Worktree `p3-lookloop`. Renders: `.build/lookloop/runs/20261007-062707/raw/`. Mocks: `~/Desktop/world-engine/docs/proposals/<pack>/`. Colours are in `mock-coverage.md`; this covers forms/elements only. vegetation-v1 is audited separately.
Side-by-sides (render left, full mock right, 390 px each) are local PNGs; mocks are whole sheets, not tight crops.

## Top 10 visible form gaps (excluding vegetation)

| # | Element | Status | Side-by-side | Owner |
|---|---|---|---|---|
| 1 | Streetlight light pools on ground at night (lamp heads emissive only) | missing | [night](form-sides/night-fog-v1/streetlight-pools-lit-windows.png) | 5A |
| 2 | Real puddles (reflective water shapes) vs global sky-mix sheen | partial | [rain](form-sides/rain-v1/puddles-reflective.png) | 5A |
| 3 | Lake ice sheets / ice edges / shore ice | missing | [ice](form-sides/lake-winter-v1/ice-sheets-edges.png) | 5A |
| 4 | Old-snow piles, plow windrows, slush at curbs | missing | [old snow](form-sides/lake-winter-v1/old-snow-piles-slush.png) | P2 (forms) + 5A (shading) |
| 5 | Ground-fog layer (low height fog band) | missing (distance fog only) | [fog](form-sides/night-fog-v1/ground-fog-layer.png) | 5A |
| 6 | Water bands / wave texture on big lake (only 0.95–1.03 noise) | partial | [water](form-sides/lake-winter-v1/water-bands-waves.png) | 5A |
| 7 | Brick streets and stone paving (OSM `surface=`) | missing | [brick](form-sides/ground-v1/brick-stone-streets.png) | P2 |
| 8 | Hero-house porch/trim/eave depth to paint-over level | partial | [Denver](form-sides/house-contrast-v1/hero-denver.png), [Wilmette](form-sides/house-contrast-v1/hero-wilmette.png), [Lakeview](form-sides/house-contrast-v1/hero-lakeview.png) | P2 |
| 9 | Snow load on roofs/boughs as forms (mask on up-faces only) | partial | [boughs](form-sides/lake-winter-v1/snow-on-boughs.png) | 5A |
| 10 | Elevated rail / trains | missing | [rail](form-sides/live-world-v1/elevated-rail.png) | L1 |

## ground-v1 (+ brick/stone addendum) — built 4, partial 3, missing 2
| Element | Status | Evidence |
|---|---|---|
| Sidewalk joints/rhythm | built | WorldShaders.metal:393 R7 joints every 1.75 m |
| Worn edges beside walks/drives | built | Yards/GroundDetail.swift wornShade/wornTone |
| Lawn patches / mow variation | built | YardRules.lawnPatches, shader patchv mix (metal:367) |
| Beds + mulch along foundations | built | YardRules mulched bed, YardGeneration:413 |
| Curb forms (height, lip, drive cuts) | partial | curbs generated (SceneGenerator:344); no drop-curb/apron form seen. [side](form-sides/ground-v1/curb-forms-worn-edges.png) P2 |
| Bed/lawn transitions (edging, shrub clumps) | partial | [side](form-sides/ground-v1/beds-mulch-transitions.png) P2 |
| Snow/leaf ground weather | partial | snowMask (metal:154), leafLitter; no drifts/edges. [side](form-sides/ground-v1/snow-on-ground-leaves.png) 5A |
| Brick streets/alleys | missing | no `surface=paving_stones/sett/brick` handling (only gravel list SceneGenerator:330). [side](form-sides/ground-v1/brick-stone-streets.png) P2 |
| Stone paving / flagstone walks | missing | same. P2 |

## house-details-v1 — built 7, partial 3, missing 0
Built: porches with posts/rails (HouseDetails.swift), stoops, cornices (BuildingDetails:204), eaves/soffits/fascia (RoofAssembly, HouseDetails), trim/corner boards/frieze/casings, shutters, chimneys+dormers (BuildingDetails:11), 17 families (house-families.json). Partial: window forms (casings only, no muntins/bay depth at mid LOD), roof form variety (gable/hip/flat envelope; no mansard/gambrel), gutters/downspouts (none found). [porches](form-sides/house-details-v1/porches-trim-families.png), [Denver urban](form-sides/house-details-v1/urban-denver-families.png). Owner P2.

## house-contrast-v1 (current target) — built 2, partial 3, missing 0
Built: family assignment per block, trim contrast colour slot. Partial: porch/eave shadow depth, window reveal depth, foundation/stoop massing vs paint-overs. Sides: [Denver](form-sides/house-contrast-v1/hero-denver.png), [Wilmette](form-sides/house-contrast-v1/hero-wilmette.png), [Lakeview](form-sides/house-contrast-v1/hero-lakeview.png). P2 (forms), 5A (shadow/AO).

## lake-winter-v1 — built 1, partial 3, missing 3
Built: shoreline fill (Context/ShorelineFill.swift). Partial: water bands/depth (sky reflect + noise only, metal:519) [side](form-sides/lake-winter-v1/water-bands-waves.png); snow on boughs/roofs (up-face mask) [side](form-sides/lake-winter-v1/snow-on-boughs.png); big-lake vs city-lake distinction (one `water` material). Missing: waves/whitecaps, ice sheets & edges [side](form-sides/lake-winter-v1/ice-sheets-edges.png), old-snow piles/slush [side](form-sides/lake-winter-v1/old-snow-piles-slush.png). Owner 5A (piles: P2).

## night-fog-v1 — built 1, partial 1, missing 2
Built: lit-window fraction (metal:406, Lighting.litWindows). Partial: lit-window pattern (random per window, no room/porch-light logic). Missing: streetlight ground pools, porch lights [side](form-sides/night-fog-v1/streetlight-pools-lit-windows.png); ground-fog layer (fog is distance-only, metal:198) [side](form-sides/night-fog-v1/ground-fog-layer.png). Owner 5A.

## rain-v1 — built 3, partial 2, missing 0
Built: per-surface wet darkening/roughness/sheen (Rain.swift, rain-bible.json, metal:238), rain streaks (Environment.swift:443), lake rain ripples (metal:533). Partial: puddles (puddle cover mixes sky in shader; no discrete reflective shapes) [side](form-sides/rain-v1/puddles-reflective.png); wet sheen/lamp streak reflections at night [side](form-sides/rain-v1/wet-sheen-streaks.png); snow stages [side](form-sides/rain-v1/snow-stages.png). Owner 5A.

## look-fix-v1 — built 3, partial 1, missing 1
Built: shrub families (Props.swift bush 0–7, hedge segment), ground continuation, lighting states. Partial: North Shore ground forms [side](form-sides/look-fix-v1/ground-north-shore.png) (P2). Missing: moon reflection path on water [side](form-sides/look-fix-v1/moon-water.png) (5A).

## live-world-v1 (rail/planes) — built 0, partial 0, missing 5
Missing: rail vehicles, elevated structure/portals, buses, aircraft (scale/lights), aerial live objects. No vehicle prop kinds (Props.swift:8). [rail](form-sides/live-world-v1/elevated-rail.png), [aerial](form-sides/live-world-v1/aerial-live-world.png). Owner L1.

## landmarks-v1 — Phase 3, all "not due yet"
Denver: State Capitol, Red Rocks, Sloan's Lake, Central Library, others in pack. Chicago: Soldier Field, Riverwalk bridges, Northwestern lakefront, Water Tower, Merchandise Mart, Grant Park, Lower Wacker, Lake Shore Drive, others in pack. All not due yet (only a `landmark` hint in PostcardReframe/default.json).

## Rest (brief)
- paintover-v1: grade-only target; forms same as house-contrast gaps. built in grade (paintover-grade.json).
- night-v1: windows/porches (partial), streetlight pools under trees (missing), moon states (built, sky), night rain/snow (partial). 5A.
- fog-v1: light/moderate/dense distance fog (built), low-sun fog shafts and aerial fog layer/lifting (missing). 5A.
- regions-chicagoland-miami: three-flats/greystones (built families), alley snow [side](form-sides/regions-chicagoland-miami/alley-snow.png) (missing piles, P2/5A), Miami/Coral Gables forms (not in test areas; profiles absent).
