# Mock value coverage audit

Date: 2026-10-07. Read-only audit of worktree `p3-lookloop` (HEAD 1736118). Engine paths are relative to repo root; `P/` = `Sources/WorldGen/Profiles/`.
Note: commit 909eed2 (`paintover-grade.json`, paintover-v1 grade as data) is on branch `phase5b` only and is **not** in this tree; everything below reflects this tree.

Method: every `#RRGGBB` in each mock JSON was string-matched against all of `Sources/` (hex hits: paintover-v1 0/31, night-fog-v1 0/23, house-contrast-v1 0/28, lake-winter-v1 2/26 (both incidental), rain-v1 2/7, vegetation-v1 42/553, ground-v1 3/1286 (incidental), house-details-v1 25/141), then named parameters were compared by hand.

## Top 10 biggest visible gaps

| # | Item | Mock value | Engine value (file:line) | Views affected | Lane |
|---|------|-----------|--------------------------|----------------|------|
| 1 | Day sky gradient | paintover ordinary `#8DADC9`→`#C7D3DC` (soft grey-blue); evanston `#9BB5CD`→`#CDD7DF` | noon skyTop `#4F8FD8`, horizon `#9CC4EC` (saturated blue) `P/time-of-day.json:6` | every daytime view | 5A |
| 2 | Golden / blue-hour sky (lavender source) | golden lakeview `#B8B5CC`→`#E7C6A4`; blue-hour (night-fog) 90°`#314D79` 30°`#657FA3` 0°`#A5A8B1` | golden `#7E97E0`/`#F0BCA2`, ambientSky `#969BD0`, shadowTint `#7777AA` `P/time-of-day.json:7`; dusk horizon `#8A82BC` (lavender), ambientSky `#788BBE` `:8`; bible golden shadeTint `#7777AA`, air `#AFACC9` `P/lighting-bible.json:134` | golden, blue hour; lavender ground via ambient/shade tint | 5A |
| 3 | Shadow strength (sun:shade) | shadowToLit 0.62 (strength 38%) ordinary, 0.60 evanston, 0.56 golden | tuned to shade:sun 0.37 (strength ~63%) via direct 0.65 / fill 3.2 `P/grade.json:6-8` (comment line 2) | all sunny views | 5A |
| 4 | Grade: warmth / contrast / exposure | ordinary +0.35 EV, contrast 1.06 (pivot .18 lin), sat 1.08, warmth +4% (RGB 1.02/1/0.98); golden warmth +8% | no warmth term anywhere; contrast 1.03 about 0.5 display `Sources/WorldEngine/PostProcess.swift:11`; sat base 0.99 `:10` × grade.json 1.06 `P/grade.json:7`; exposure = auto to bible luma `Sources/WorldEngine/Environment.swift:60` (no EV offset) | all views | 5A |
| 5 | Crown colours (lime) | paintover ordinary crown light/mid/dark `#9EAC74`/`#738B53`/`#405844`; lakeview `#A8B16E`/`#71824B`/`#36533F` | single albedo per slot, no light/mid/dark swatches: summer maple `#638044`, honey locust `#768E50`, spring maple `#91A552`, honey locust `#A4AE60` `P/seasonal-palette.json:15,37` (from vegetation-v1 neutralCrownAlbedo; lime cast is the spring/locust albedos x fill, not a paintover value) | all views with trees | P2 (colours), 5A (crown shading) |
| 6 | Trunk / bark under warm key | vegetation-v1 golden branch body `#856A4A`, shadow `#66574B`; paintover: "trunks warm brown" | bark `#796B57` all seasons `P/seasonal-palette.json:26` (= mock midday body, used); orange comes from golden directTint `#FFC17B` `P/time-of-day.json:7` with fill 3.2/no warmth balance; mock highlight/shadow swatches not used | golden, low-sun views | 5A (light), P2 (bark) |
| 7 | Road / sidewalk / lawn | ground-v1 chicago road `#666A6D`, sidewalk `#C1B9A8`, lawn `#89985A` | road summer `#898A89` (much lighter) `P/seasonal-palette.json:21`; sidewalk `#D0C8B6` `:22`; lawnA/B `#648146`/`#8C9C59` `:29-30` and `P/yards.json:24-35` | all street views | P2 |
| 8 | Wet path darkening | paintover rain 10% (×0.90), sheen 0.2; rain-v1 steady concrete 10%, asphalt 11% | rain-bible copies rain-v1 exactly, then `darkenScale` 3.8 → ~38–42% `P/look.json:16`; weather.json albedoDarkening 0.18 `P/weather.json:17` | rain views | 5A |
| 9 | Water colour | paintover rain `#718C9A`, smoke `#858F90`, golden `#477884`; lake-winter Sloan's clear base `#477C8D`, shallow `#668C82` | summer water `#638D91` (one per season) `P/seasonal-palette.json:24`; reflect gains `P/look.json:4-9` | lake views (Sloan's, lakefront) | 5A (shading) / P2 (palette) |
| 10 | Night sky, windows, lamps | night sky 90°`#15243C` 30°`#243854` 0°`#344255`; windows warm `#F3D0A0` share 0.30; lamp led-warm `#F0DDC0` | night skyTop `#232A50`, horizon `#404F7A` `P/time-of-day.json:9`; windowLitNight `#DCA967`, lampGlow `#F3D9A4` `P/base-palette.json:7,14`; bible windowCore `#FFD19A` `P/lighting-bible.json:459`, litWindows 0.2–0.3 | night, blue hour | 5A (sky/light), P2 (windows) |

Runner-up: day window glass. house-contrast `#405766`–`#465D6B` vs windowDay `#6A8794` `P/base-palette.json:4` (lighter, reads as flat panel). Lane P2.

## How values flow

No engine code loads any `docs/proposals/` JSON at runtime. The only loader reads bundled `Profiles/*.json` (`Sources/WorldGen/StyleProfile.swift:282`). Two packs reach the engine through generator scripts: rain-v1 → `P/rain-bible.json` (`scripts/rainfix_data.py`, sha-pinned) and look-fix-v1 → `P/lighting-bible.json` (`scripts/lookfix_data.py`). vegetation-v1 crown albedos were hand-copied into `P/vegetation.json`/`P/seasonal-palette.json`. paintover-v1 reaches code only as geometry/AO constants written by hand in `Sources/WorldGen/Props.swift` (root flare 1.15, interior AO 25%). paintover-v1 grade, sky, crown, shadow and water values; night-fog-v1; house-contrast-v1; lake-winter-v1; and ground-v1 colours are not in the engine. Several used values are then scaled by hand-tuned files (`grade.json`, `look.json`), so even "used" packs render differently from the mocks.

## paintover-v1 (approved)

| Parameter | Mock | Status | Engine |
|---|---|---|---|
| grade per view (EV, contrast, sat, warmth); 6 views | EV +0.10…+0.35; contrast 0.94–1.07; sat 0.96–1.08; warmth −3…+8% | conflicts | contrast 1.03 `PostProcess.swift:11`; sat `grade.json:5-15` (e.g. ordinary 1.06, overcast 0.65, rain 0.86); auto exposure; no warmth (not used) |
| shadow strength per view | 38/40/14/16/44/44 % | conflicts | ~63% clear (grade.json:6-8 comment); weather direct 0.15–0.2 `grade.json:11-12` |
| path wet darkening (rain view) | 10%, sheen 0.2 | conflicts | ×3.8 `look.json:16` |
| sky appearance per view | ordinary `#8DADC9/#C7D3DC`, evanston `#9BB5CD/#CDD7DF`, rain `#617B91/#9AAEBB`, smoke `#B2A79B/#C1B4A3`, golden `#B8B5CC/#E7C6A4` | conflicts | time-of-day.json:4-9 (see gap 1-2); weather tints `weather.json` |
| crown light/mid/dark per view | 6 triplets (e.g. ordinary `#9EAC74/#738B53/#405844`, evanston fall `#D7AD61/#B58245/#765338`) | not used | engine has one albedo per slot; no 3-tone swatches |
| water per view | rain `#718C9A`, smoke `#858F90`, golden `#477884`; roughness 0.28/0.40/0.28 | conflicts | `#638D91` `seasonal-palette.json:24`; puddle roughness 0.18 rain-bible |
| common.contact AO (trunks 15%, eaves 12%, floor 0.65) | | unclear | AO present in Props.swift trunkAO; percentages not found by grep |
| common.trees interior AO 25%, root flare 1.15 / 0.12 m | | used | `Sources/WorldGen/Props.swift:605-607,658-661` |
| common.ground lawn variation 5% / clamp 6% | | conflicts (approx.) | lawnShade 0.92–1.07 `P/yards.json:17-20` |
| common.ground roughness dry 0.82 / wet 0.53 | | conflicts | 0.85 / 0.5 `P/weather.json` wetResponse; rain-bible steady concrete 0.53 (used) |
| common.edges MSAA 4, aerial transition 150–300 m, perf | | unclear | not checked in renderer setup |

## rain-v1 (approved)

| Parameter | Status | Engine |
|---|---|---|
| states damp…drying: wetness, darkening, roughness, sheen per surface | used, then scaled | `P/rain-bible.json` (generated, sha pinned); darkening ×3.8 `P/look.json:16` → conflicts on screen |
| puddles (coverage, roughness, sky mix) | used | `P/rain-bible.json` puddles |
| rain streaks (counts, opacity 0.26/0.34/0.40) | used (counts); opacity unclear | rain-bible states |
| fog rainTint `#8F9FAA` 0.22, sun 0.18, start 0.4 / end 0.5 | used | `P/weather.json` rain row |
| lampStreaks colour `#E7BA79` | unclear | hex appears in Sources; not traced to streak code |
| snow counts/stages | unclear | not traced |

## vegetation-v1 (approved)

| Parameter | Status | Engine |
|---|---|---|
| neutralCrownAlbedo per species × season (chicago, denver) | used | `P/vegetation.json:14-60`, `P/seasonal-palette.json:12-37` |
| branch body midday `#796B57` | used | `P/seasonal-palette.json:26` |
| midday/golden highlight & shadow swatches, golden body transform | not used | engine lights albedo; no swatch transform |
| shrubs neutralCrownAlbedo (e.g. `#94A364` spring) | conflicts | bushes `#7F9C72…` `P/seasonal-palette.json` bushes row |
| weeping willow addendum | used | deciduous9 `P/vegetation.json` |
| clusterCount / skyHole fraction | unclear | not traced in Props.swift |

## night-fog-v1 (reference)

| Parameter | Mock | Status | Engine |
|---|---|---|---|
| blue-hour sky gradient | `#314D79/#657FA3/#A5A8B1` | conflicts | dusk `#4A66B8/#8A82BC` `time-of-day.json:8` |
| night sky gradient | `#15243C/#243854/#344255` | conflicts | `#232A50/#404F7A` `time-of-day.json:9` |
| exposure EV blue 0.2 / night 0.35 | | conflicts | bible ev 0.35 / 0.45 `lighting-bible.json` |
| haze hex / sigma | `#8294AE` 0.0015; `#475568` 0.002 | conflicts | fog `#9D9EAF` 200–750 m, `#626E87` 140–600 m (linear, not sigma) |
| morning ground fog (sigma 0.035, top 2.5 m, patches) | | not used | no layered ground fog; weather fog [25,220] m `weather.json:10` |
| windows warm `#F3D0A0`, cool `#C9DDEB`, share 0.3 | | conflicts / partly | `#DCA967` `base-palette.json:7`; litWindows 0.25 time-of-day; no cool windows |
| streetlights led-warm `#F0DDC0`, pools 4.5/9 m | | conflicts / not used | lampGlow `#F3D9A4` `base-palette.json:14`; pool radii not found |
| skyglow, stars, headlights | | not used | none found by hex/name grep |

## house-contrast-v1 (reference)

| Parameter | Status | Engine |
|---|---|---|
| wall/trim per type (e.g. two-flat `#A77960`/`#E2D2B7`) | conflicts (close) | profile colours e.g. `#A97C68`/`#DED6C2` `P/evanston.json:119-120` |
| soffit / eave_shadow / porch_shadow targets | not used | no such surfaces in palettes |
| window_glass_day `#405766`–`#465D6B` | conflicts | `#6A8794` `P/base-palette.json:4` |
| roof `#554E49`–`#60615A` | conflicts | e.g. `#59636B`, `#646363` `P/evanston.json:122,128` |

## lake-winter-v1 (reference)

| Parameter | Status | Engine |
|---|---|---|
| water base `#477C8D`, shallow `#668C82` / `#557F83`, wind roughness 0.18/0.28/0.40 | conflicts / not used | `#638D91` `seasonal-palette.json:24`; no shallow band; no wind states |
| reflection colours per sky (`#8FBDD7` …) | not used | engine reflects its own sky; `look.json:4-9` gains |
| ice `#91ADBA`, coverage states | not used | none found |
| snow `#E4E9EB`, shadow tint `#C3CDD6` | conflicts | `#E8EDF0` `seasonal-palette.json:27` |
| branch snow, old/dirty snow, slush | not used | none found |

## Extra: ground-v1

| Parameter | Status | Engine |
|---|---|---|
| chicago lawn `#89985A`, parkway `#839252` | conflicts | lawnA/B `seasonal-palette.json:29-30`, `yards.json:24-35` |
| sidewalk `#C1B9A8`, curb `#B6B09F` | conflicts | `#D0C8B6`, curb `#C0BCAE` `seasonal-palette.json:22-23` |
| road asphalt `#666A6D` | conflicts | `#898A89` `seasonal-palette.json:21` |
| driveway concrete `#BBB3A2`, mulch `#80684E`, bed soil `#8B775B` | conflicts | driveway `#BDB6A8`, yardBed `#6F5A48` `base-palette.json` |
| denver / miami regional materials | not used | no regional ground override found |
| lawn patch/stripe variants, worn area, overlays, brick addendum | not used | |

## Extra: house-details-v1

25/141 hexes found in Sources (trim, door, lamp-warm swatches via `P/house-families.json` and `Sources/WorldGen/HouseDetails.swift`); treated as partly used. Not audited row by row.
