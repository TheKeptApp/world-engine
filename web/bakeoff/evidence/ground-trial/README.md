# Ground / semantic materials trial — A2, 9 October 2026

**R approved the fresh-main rebaseline and inferred regional adapter on 9 October. All seven fresh-main controls and paired cost gates pass; merged default off as `978396b`. No scores.** See [regional adapter and gate decision](REGIONAL-ADAPTER.md). See [current-main evidence](current-main/README.md) and [manifest](manifest.json). Pre-rebase captures and the old `blind/` directory below are superseded; use `current-main/blind/` for A3. `?groundTrial=on` resolves the prepared companion by exported area ID; an explicit `surfaceRoles=<same-origin companion/index.json>` can override its location; absent/off does not import the trial or load a companion. Other look flags remain off for the paired trial.

## Rule and inputs

Restore existing exported semantic distinctions, rather than add a palette or spatial texture. Lawn flag 4 with positive exported lot seed (`extra.w>0`) consumes `mix(lawnA,lawnB,clamp(extra.y,0,1))*paint.y` in linear light, matching `Sources/WorldEngine/Shaders/WorldShaders.metal`. `Sources/WorldGen/Yards/YardGeneration.swift` derives shade/tone/lot seed from the building's stable `random("yard")` stream; `GroundDetail.swift` bakes broad patches, worn edges and soft tree/shrub contact shading. This trial retains those fields and existing bed/paving topology, without a second hash/noise layer, checkerboard, new lawn endpoints or extra contact multiplication. The lot polygons are inferred dressing, not surveyed parcels.

A4's companion is validated by the production `surface-roles.js` reader. The added runtime binding compares a canonical hash of positions and triangle indices to the validated GLB primitive; missing/ambiguous bindings reject. Only **family-inferred roof/wall/trim** triangles stop using the legacy hex-selected facade repaint and instead retain their exported palette assignment. Existing wall course/stone classification stays unchanged while its albedo is restored. Mapped colour provenance, unknown provenance and doors stay unchanged. Shared vertices crossing the changed/unchanged boundary reject rather than leak a colour or duplicate geometry. This is role selection, not a hex replacement table or building-ID palette.

No new geometry, materials, draw submissions, lights, shadow rules, exposure, date weights or global colour grade. Existing building geometry/detail gaps remain. Unseeded park/open-space lawns stay on the existing base colour; the trial does not fabricate parcel variation there. Ground-v1 is a research reference, not approval to import its proposed construction numbers; the implemented numbers come from the existing approved exporter/native path.

## Sources and mocks actually read

- `docs/tracking/DECISIONS.md`, `REFERENCE-MAP.md` Ground/Palette/Facades rows, `STATE.md`, `INDEX.md`, `MOCKS.md`; current owner trial scope overrides earlier scoring instructions.
- `docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md` §§1.1–1.2 (lot palette/seed and beds/access), its README Ground and yards; `docs/execution/ground.md` general rule and numeric contract; `docs/proposals/ground-v1/README.md` Sheets/Authority and `ground-colours.json` construction; `Sources/WorldGen/Yards/{YardGeneration,GroundDetail}.swift`; `Sources/WorldGen/Profiles/{yards,seasonal-palette}.json` lawn/groundContrast.
- `docs/execution/surface-role-implementation.md` Contract and ownership; `house-contrast-v1/README.md` One lighting target, `paintover-values.json` houseTypes; `house-archetypes-v1/README.md` Inherited values, `archetypes-values.json` approvedHouseValues; both STATUS files record R approval.
- Opened ground-v1 `images/03-beds-and-transitions.png`, `04-region-chicago.png`, `05-region-denver.png`, `06-region-miami.png`, including their aerial insets.
- Opened `~/Desktop/world-engine/docs/proposals/house-contrast-v1/images/{denver-hero,lakeview-hero,wilmette-hero}.png` (street scope) and `~/Desktop/world-engine/docs/proposals/house-archetypes-v1/{denver-02-bungalow-sheet,denver-04-ranch-sheet,chicago-02-flats-sheet,chicago-04-foursquare-sheet}.png` (paired aerial/street). Worktree image omissions were resolved from the main checkout, not substituted.

## Historical validation plan / superseded blockers

OFF controls: exact RGB max/mean 0/0 below the top 32 credit rows against c8c361d Sloan 40/150/600 controls; Lakeview 150 uses the already-qualified matching-pose control, with literal historical Lakeview 600 checked separately. Capture both modes at Sloan 40/150/600, Lakeview 150, Wilmette 150 and frozen West Highland. Greenville is currently rejected by the bakeoff capture adapter: no approved regional haze/phenology/species integration. R has been asked which approved profile to use; no Denver/Chicago substitution is made.

## Wilmette reader correction

First Wilmette ON attempt rejected an identical repeated relation witness in A4's `featureSources`. The failed `web-capture.json` is retained under `wilmette-on-rejected-duplicate-witness/`. The reader now accepts repeated source IDs only when the canonical tag sets match exactly; conflicting provenance still rejects. No exporter, role recovery or source-colour changes. Dedicated positive/negative tests cover this case.

## Historical ledger text (superseded by REGIONAL-ADAPTER.md)

Default-off ground/semantic-material trial implemented on `astra-a2-ground-trial`, rebased onto `591e4be`; not merged. Current-main pairs: Sloan 40/150/600, Lakeview 150, Wilmette 150, frozen West Highland, each fresh/repeat. All paired main/shadow/post cost deltas are 0 triangles / 0 draws. Arithmetic/reader suites and 16 capture-tooling tests pass. Mapped colours remain unchanged; no new palette values or geometry. Target Ground/Materials 2→3 is unscored; A3 owns grading. Sloan 600 m historical c8c361d gate fails after main's upstream water correction, while bare-main versus trial-OFF is PNG-exact. R's baseline decision and Greenville regional adapter are pending. No merge, promotion, or post-merge scoreboard is claimed.

Touched: `web/bakeoff/{main.js,ground-trial.js,ground-trial.test.mjs,surface-roles.js,surface-roles.test.mjs,surface-roles-fixture.mjs,palette-b-identity.mjs,light-trial.test.mjs,prepare-ground-companions.mjs,evidence/ground-trial/}` and minimal ground-mode/control-replay additions to `scripts/capture_web.mjs`; watchdog/lock-release and camera ladder unchanged.

## Current completion record

See [approved rebaseline and regional adapter](REGIONAL-ADAPTER.md) for current status; historical blocked notes above are superseded. Accepted OFF/ON pairs cover Sloan 40/150/600, Lakeview 150, Wilmette 150, West Highland frozen view and Greenville 150. All accepted repeats are PNG-exact; all fresh-main controls equal trial OFF byte-for-byte. All rendering-pass deltas are zero.

Additional touched files: `regional-adapter.mjs`, `regional-adapter.test.mjs`, `phenology.js`, `scripts/web_capture_blocks.mjs`; capture tooling freezes the shared material clock as well as the bakeoff clock. Existing approved look values, mapped materials and camera recipes remain unchanged.

## Post-merge scoreboard and handoff

Merged to main as `978396b`; current-main OFF gate exact for all seven views. Existing `scripts/world-scoreboard.sh` completed after merge: **24 frames / eight held areas**, `completed-with-failures`, 474.6 seconds. Floor and standard budget flags occur in all 24 rows; blank-ground coverage in seven. Four additional areas would be needed to reach the scoreboard’s twelve-area inventory goal. This is the shipping-web-module scoreboard, not a bakeoff visual grade. The default previous scoreboard (`ee66770`) is marked non-comparable by its own source/contract check; no improvement/regression claim is inferred from that diff. See [JSON](post-merge-scoreboard.json) and [report](post-merge-scoreboard.md).

### Ledger text for A3

Ground trial merged default OFF as `978396b`. R approved a fresh-current-main OFF baseline (exact trial-OFF equality; c8c361d historical only) and an inferred general regional adapter where approved regional inputs are missing. Approved Southeast haze is consumed without tuning; same-climate foliage proxies, missing scaffold forms and unknown calendar timing are labelled. No pending pack values. Review Sloan 40/150/600 and untouched Lakeview 150, Wilmette 150, West Highland frozen view, Greenville 150 in [blinded gallery](current-main/review.html); coordinator key is `current-main/blind-key.json`. All seven controls are full-PNG exact and every paired rendering-pass triangle/draw delta is zero. A3 owns paired visual scoring and tracker filing; A2 assigns no score or promotion. Complete sources/mock citations and deviations: [regional adapter](REGIONAL-ADAPTER.md) plus sources above.
