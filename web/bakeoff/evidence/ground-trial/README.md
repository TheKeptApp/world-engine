# Ground / semantic materials trial — A2, 9 October 2026

Work in progress; no scores. `?groundTrial=on` resolves the prepared companion by exported area ID; an explicit `surfaceRoles=<same-origin companion/index.json>` can override its location; absent/off does not import the trial or load a companion. Other look flags remain off for the paired trial.

## Rule and inputs

Restore existing exported semantic distinctions, rather than add a palette or spatial texture. Lawn flag 4 with positive exported lot seed (`extra.w>0`) consumes `mix(lawnA,lawnB,clamp(extra.y,0,1))*paint.y` in linear light, matching `Sources/WorldEngine/Shaders/WorldShaders.metal`. `Sources/WorldGen/Yards/YardGeneration.swift` derives shade/tone/lot seed from the building's stable `random("yard")` stream; `GroundDetail.swift` bakes broad patches, worn edges and soft tree/shrub contact shading. This trial retains those fields and existing bed/paving topology, without a second hash/noise layer, checkerboard, new lawn endpoints or extra contact multiplication. The lot polygons are inferred dressing, not surveyed parcels.

A4's companion is validated by the production `surface-roles.js` reader. The added runtime binding compares a canonical hash of positions and triangle indices to the validated GLB primitive; missing/ambiguous bindings reject. Only **family-inferred roof/wall/trim** triangles stop using the legacy hex-selected facade repaint and instead retain their exported palette assignment. Mapped colour provenance, unknown provenance and doors stay unchanged. Shared vertices crossing the changed/unchanged boundary reject rather than leak a colour or duplicate geometry. This is role selection, not a hex replacement table or building-ID palette.

No new geometry, materials, draw submissions, lights, shadow rules, exposure, date weights or global colour grade. Existing building geometry/detail gaps remain. Unseeded park/open-space lawns stay on the existing base colour; the trial does not fabricate parcel variation there. Ground-v1 is a research reference, not approval to import its proposed construction numbers; the implemented numbers come from the existing approved exporter/native path.

## Sources and mocks actually read

- `docs/tracking/DECISIONS.md`, `REFERENCE-MAP.md` Ground/Palette/Facades rows, `STATE.md`, `INDEX.md`, `MOCKS.md`; current owner trial scope overrides earlier scoring instructions.
- `docs/execution/ground.md` general rule and numeric contract; `docs/proposals/ground-v1/README.md` Sheets/Authority and `ground-colours.json` construction; `Sources/WorldGen/Yards/{YardGeneration,GroundDetail}.swift`; `Sources/WorldGen/Profiles/{yards,seasonal-palette}.json` lawn/groundContrast.
- `docs/execution/surface-role-implementation.md` Contract and ownership; `house-contrast-v1/README.md` One lighting target, `paintover-values.json` houseTypes; `house-archetypes-v1/README.md` Inherited values, `archetypes-values.json` approvedHouseValues; both STATUS files record R approval.
- Opened ground-v1 `images/03-beds-and-transitions.png`, `04-region-chicago.png`, `05-region-denver.png`, `06-region-miami.png`, including their aerial insets.
- Opened `~/Desktop/world-engine/docs/proposals/house-contrast-v1/images/{denver-hero,lakeview-hero,wilmette-hero}.png` (street scope) and `~/Desktop/world-engine/docs/proposals/house-archetypes-v1/{denver-02-bungalow-sheet,denver-04-ranch-sheet,chicago-02-flats-sheet,chicago-04-foursquare-sheet}.png` (paired aerial/street). Worktree image omissions were resolved from the main checkout, not substituted.

## Validation plan / remaining gap

OFF controls: exact RGB max/mean 0/0 below the top 32 credit rows against c8c361d Sloan 40/150/600 controls; Lakeview 150 uses the already-qualified matching-pose control, with literal historical Lakeview 600 checked separately. Capture both modes at Sloan 40/150/600, Lakeview 150, Wilmette 150 and frozen West Highland. Greenville is currently rejected by the bakeoff capture adapter: no approved regional haze/phenology/species integration. R has been asked which approved profile to use; no Denver/Chicago substitution is made.

## Wilmette reader correction

First Wilmette ON attempt rejected an identical repeated relation witness in A4's `featureSources`. The failed `web-capture.json` is retained under `wilmette-on-rejected-duplicate-witness/`. The reader now accepts repeated source IDs only when the canonical tag sets match exactly; conflicting provenance still rejects. No exporter, role recovery or source-colour changes. Dedicated positive/negative tests cover this case.

## Ledger text for A3

Initial arithmetic validation passed under heavy admission at load 8.90: ground-trial tests, 28 production-reader positive/rejection checks, palette-B historical source identity and light-trial regression. Sloan OFF ladder captured at load 4.25: 40/150/600 m each exact world-region max/mean 0/0 against c8c361d, and fresh/repeat PNG byte-identical. ON/hold-out captures pending. Target Ground/Materials 2→3; A3 owns scoring. No score assigned by A2.
