# P2 Batch 3: sidewalk end-short, retail ground, parking, Denver apartments, sports fields (10 Oct 2026)

All five are **default off** and region-independent: `-lookexp sidewalkendshort,retailground,parkingarea,denverapartments,sportsfields`. No shader, grade, exposure or palette-table change; only existing keys are used. Map data © OpenStreetMap contributors.

Capture settings: exposure **pinned at gain 1.0**, because 5A's settled-gain capture mode is not on main (`scripts/capture_native.py` has no settled option at `165ed6e`). Clear sky, wind 0, ladder cameras as Batch 0. Frames, the all-five-ON frame, byte-copy controls and hashes are in [manifest.json](manifest.json). OFF/ON crops: [off-vs-on-crops.png](off-vs-on-crops.png).

## Controls and budget (rebased on main `165ed6e`, 5A's streaming/shadow-cells commit)

Tests: **432/432** pass.

**OFF against main:**
- Byte-identical: Sloan's 40 and Lakeview 40/150/600.
- Sloan's 150 and 600 m: at most 1/255 (60 and 190 bytes).

**Main triangles / draws, OFF → all-five-ON:**

| View | OFF | ON |
|---|---|---|
| Sloan's 40 | 312,880 / 53 | 313,038 / 53 |
| Sloan's 150 | 333,744 / 50 | 334,185 / 50 |
| Sloan's 600 | 228,013 / 43 | 228,626 / 43 |
| Lakeview 40 | 295,759 / 56 | 296,008 / 56 |
| Lakeview 150 | 271,763 / 48 | 272,012 / 48 |
| Lakeview 600 | 194,160 / 35 | 194,295 / 35 |

Every view stays under the floor budget (<400k triangles, ≤100 draws).

## Per item: features changed (Sloan's / Lakeview / Wilmette) and what the 150 m view shows

**1. sidewalkendshort** (`RoadClip.endShort`, includes roadclip)
- Mapped sidewalk ends whose 0.8 m ribbon reached a street carriageway they approach at more than 30° are pulled back in 0.1 m steps, at most 4 m.
- Curb ends: **223 → 2 / 134 → 0 / 63 → 0**.
- Gap: the 2 Sloan's ends would need more than 4 m (capped, so a sidewalk is never deleted).
- At 150 m: the white stubs at the curb disappear (sub-metre, hard to see).

**2. retailground**
- `landuse=retail|commercial` areas are drawn as paved commercial ground (seasonal key `commercial`, park layer, no lawn mottling).
- Areas: **5 / 17 / 3**.
- At 150 m: gray-green paving replaces base lawn behind the Southport shops. Most visible at Lakeview 40 m.

**3. parkingarea**
- Lots keep the `parking` key, gain a 0.3 m kerb edge (`curb`), and underground/rooftop/multi-storey lots are no longer drawn as ground.
- Lots: **24 / 16 / 5**; not at ground: **0 / 1 / 0**.
- At 150 m: lots read as edged paved rectangles.
- Gap: no stall lines; the current generator has none.

**4. denverapartments**
- Front-range `denverApartment` / `denverCourtyard` from **facade-detail-v2 `denver-apartment` / `denver-courtyard`** (approved 8 Oct): 3 storeys × 3.1 m, parapet 0.45–0.85, cornice 0.18–0.4, wall/trim/accent/roof hex from the pack.
- Grammar mirrors Chicago `sixFlat` / `courtyardMass`; porch and window sizes come from the Chicago entries (the pack gives none).
- Uses only the existing `blockEvidence` (apartments / court).
- Buildings: **5 / 0 / 0** (`modern → denverApartment`).
- Gap: `building=terrace` townhome rows have no Denver family.

**5. sportsfields** (`SportsLook.swift`; tracks read from the source document)

| Kind | Look | Sloan's / Lakeview / Wilmette |
|---|---|---|
| Courts (tennis, basketball, multi…) | `parking` hard surface plus `laneMarking` lines | 13 / 1 / 3 |
| Fields (soccer, football…) | `pitch` plus lines | 3 / 0 / 0 |
| Baseball/softball diamonds | Infield square (27.4 / 18.3 m) in `playground`, home plate at the field's sharpest corner | 1 of 1 / 0 / 1 of 5 placed |
| `leisure=track` | Ribbon in `pavingBrick` (`parking` for cycling) | 1 / 0 / 0 |

- Gap: 4 Wilmette diamonds have no corner sharp enough or are too small.
- Gap: a dedicated track/clay key would be a **palette ruling for A2**; `pavingBrick` is reused.
- None of the sports fields are inside the six ladder frames.

Used: feature-types-audit README (ranks 1–4); facade-detail-v2 denver-apartment / denver-courtyard; base-palette keys. Mock: facade-detail-v2 values (no image for ground types). Deviation: one combined ON frame per view (per-item counts from tests); pinned gain 1.0; track reuses `pavingBrick`.
