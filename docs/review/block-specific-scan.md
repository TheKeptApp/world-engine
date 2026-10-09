# A8 place-specific behavior scan

Reviewed main `ee66770` (the working tree before the score-lock documentation commit). Read-only code audit; no renderer, exporter, profile, source dataset or capture changed. Names are not automatically violations: observed geographic input and declared regional priors are valid; a hero-driven universal fallback, hidden identifier exception or tuning to one camera is a different claim.

## Scope and method

Scanned source/data declarations under Sources/WorldGen (71 files), WorldEngine (24), WorldEnvironment (18), LiveSky (10), WorldPackage (13), worldbake (6), web/src (11), web/bakeoff (51): 204 Swift/Metal/JS/MJS/JSON files after excluding generated export/evidence directories, node_modules and the duplicated compiled mock-values resource. Followed relevant hits into Apps/WorldLab/BuildingLab and capture scripts. Compiled mock values and generated facade/terrain/instance records were treated as inputs, not searched as millions of apparent code exceptions; their runtime selectors were traced. This is a broad repository source scan, not an exhaustive audit of every historic document, third-party dependency or raw OSM coordinate.

Search families: place names and region aliases; latitude/longitude constructors and Denver/Chicago coordinate literals; OSM node/way/relation literals and long numerical identifiers; profile/area/manifest/ID equality branches; presets and camera eye/target fields; comments about tuning, sampling and measured priors. Reviewed matched code and consumers rather than treating search results as proof. The appendix retains all 202 place-name hits from the primary runtime/data scan; related occurrences are grouped below with their effect, severity and general replacement. Long JSON comments are excerpted only in the appendix; the cited files contain the full text. Additional ID/coordinate/tool/app hits are explicitly listed below.

**Main conclusion:** no runtime branch keyed to a literal OSM ID or one block’s coordinate was found in the requested engine/generator/viewer code. Real risks remain in globally exported timezone metadata, water-profile defaults, hero-driven palette weights, and thinly sampled region priors. Evaluation cameras and geographic datasets are explicitly place-bound and should remain evaluation/data inputs.

## Ranked findings and hit interpretation

| ID / severity | File and line | What it does / affected output | General replacement or disposition |
|---|---|---|---|
| F01 — MISLEADS A DECISION | `Sources/WorldPackage/WorldPackage.swift:272`; consumer `web/src/main.js:60` | Writes America/Denver for **every** exported environment, even other regions. Shipping web HUD formats local date/time with it. Sun computation at exporter line 265 still uses real coordinates; this is not evidence that lighting itself is wrong. | Resolve timezone from area metadata/location, with explicit unknown fallback; do not use the demo timezone as universal metadata. |
| F02 — BLOCKS A PORT of general water classification | `Sources/WorldGen/Profiles/look.json:15`–26; `ShoreBand.swift:15`; `MockValues.swift:191` | Maps default/front-range to sloans_lake, Evanston/Wilmette/dense Chicago to lake_michigan. SceneGenerator applies the selected profile to water areas at line 308. Shipping native and exported scenes can give unrelated ponds/rivers the example lake’s shallow-water treatment. Names alone are not the problem; selection is by land style rather than water-body properties. | Select by observed water class, dimensions, depth/turbidity and exposure; retain measured lake recipes only with evidence or explicit fixture assignment; neutral documented fallback otherwise. |
| F03 — MISLEADS A DECISION | `Sources/WorldGen/Profiles/look.json:93`–98; `BuildingGenerator.swift:117`, `:265` | Global Chicago-flat colour weights [1,.25,1,1] were adjusted because the seeded variant appeared on both postcard flats and had a diagnostic ΔE gap. Affects generated shipping buildings of that archetype everywhere, not just the observed two. Comment discloses owner/P3 rationale but not independent population validation. | Use regional material-frequency evidence or a declared general art-direction distribution with matched hold-outs; never use two hero draws or colour-box ΔE alone as validation. |
| F04 — MISLEADS A DECISION | `Sources/WorldGen/Profiles/front-range.json:8`, `:211`; `evanston.json:737`, `:748`, `:768`; `wilmette.json:778`; `chicago-dense-north.json:1330` | Regional canopy/height/roof priors carry provenance from individual Sloan/Evanston/Wilmette/Lakeview samples. Front Range canopyShare .25 applies across a broad corridor although the source explicitly says one mature inner-city area/suburbs may be lower. Shipping generated yards/trees are affected where priors fill missing data. | Stratify by urban fabric/climate/land use with uncertainty and multi-area hold-outs; retain provenance and never interpret single-block calibration as metro-wide measurement. |
| F05 — MISLEADS A DECISION | `Sources/WorldGen/Profiles/vegetation.json:2`, `:176`–193; `Vegetation.swift:44`/`:50`; `web/bakeoff/foliage.js:219` | Denver palette mix/seasonal lags were revised after Sloan’s lemon-yellow regression: linden @.55, honey locust @.5, elm @.7. This is a regional, documented prior affecting native/export and bakeoff, not an OSM-ID exception. Generalization is not established by the motivating hero. | Species/phenology/climate evidence and held-out autumn dates/areas; label authored lags as inferred and retain tagged-species overrides. |
| F06 — MISLEADS A DECISION | `Sources/WorldGen/Profiles/regions.json:2`, `:9`, `:15`, `:21`, `:27`, `:33`, `:39`, `:45`, `:51`, `:57`, `:63`, `:69`; `StyleProfile.swift:200` | First-match rectangular regional selection drives shipping fallback style. Comments explicitly widen windows to include test areas and acknowledge jurisdiction overlap/imprecision. Eleven boxes are regional data, not per-building exceptions, but test-coverage boundaries can become visible style seams. | Administrative/climate/fabric polygons or documented regional selection with boundary hold-outs; use test windows only for evaluation coverage, not to define inferred style limits. |
| F07 — MISLEADS A DECISION | `web/bakeoff/foliage.js:115` | Opt-in v2 elm uses the Denver entry in speciesByCity as the construction recipe wherever an American elm is selected, including other bakeoff regions. Native/shared viewer unaffected. | Species recipe keyed by biological form/species, with explicit regional overrides only where justified. |
| F08 — MINOR | `web/bakeoff/foliage.js:55` | Bark fallback is always Chicago’s bark family when species/family bark is absent. Bakeoff runtime, not just capture tooling. | A species/genus or neutral bark fallback; region context if a regional prior is intended. |
| F09 — MINOR / declared regional dispatch | `web/bakeoff/facade-policy.js:4`; `data/facade-mechanics.json:6`; `facades.js:51` | Explicit Chicago/Denver facade-family table; shared window heights sourced from Chicago brickStackedFacade are reused by facade generation. Bakeoff output only. Real building colour/start date are read separately. | Put family mapping/mechanics in a schema with supported regional coverage and per-family dimensions; do not silently imply universal support. |
| F10 — MISLEADS A DECISION if reused as general renderer | `web/bakeoff/main.js:84`–90; `scenes.json:47`–54; `backdrop.js:5`, `:20` | Water-profile presence enables both Sloan lake shader and Front Range backdrop; DEM omits triangles whose first vertex is within 5 km. Constants are general arithmetic, but feature coupling assumes the two-scene fixture configuration and can fail for another water scene without a backdrop. Bakeoff only. | Independent water/terrain capability selection; coverage-driven DEM seam/blend from actual detailed footprint rather than a universal 5 km hole. Rename geographic function after making the input contract general. |
| F11 — MINOR / evaluation fixture | `web/bakeoff/scenes.json:9`–22, `:33`–46 | Literal Lakeview and Sloan camera eye/target/FOV (47°/35°), viewport and world paths compose comparison scenes. Comment cites way/231141080 as camera evidence only; no renderer lookup or feature override uses that ID. | Preserve immutable capture contracts, separate from default user camera; no replacement with anonymous constants needed. |
| F12 — MINOR / evaluation fixture | `scripts/web_capture_blocks.mjs:25`, `:30`, `:38`, `:43`; `scripts/web_sloans_ladder.json:1`; `web/bakeoff/capture-once.mjs:20`, `:38`, `:44`; `crown-v2-cost.mjs:19` | Named block routes, frozen poses/heights/dates, west-facing Sloan assertion and ordered hold-out capture checks. Affect evaluation selection/capture, not geometry rules. | Keep versioned contracts and explicit area/pose inputs; do not migrate named-camera acceptance checks into runtime scene generation. |
| F13 — MINOR / fixture serving and provenance | `web/bakeoff/serve.mjs:9`; `freeze.mjs:12`–13; `provenance.json:21`, `:29`, `:39`, `:43` | Maps two world URLs, freezes named exports/mocks, records their hashes. No place-specific geometry modification. | Parameterized fixture manifest when adding areas; retain hashes and source identity. |
| F14 — MINOR / host demo behavior | `Apps/WorldLab/Sources/Demo.swift:83`–101; `ContentView.swift:672`; `Apps/BuildingLab/Sources/ContentView.swift:27` | Sloan default enables demo walking/presets/showcase; other areas clear route/showcase. BuildingLab defaults to Sloan. Host apps can deliberately choose demonstrations; native WorldEngine itself is not keyed to that block here. | Keep demo policy in host/config; apply generic route validity checks for a general user-facing app. |
| F15 — MINOR / shipping viewer evaluation option | `web/src/main.js:37`, `:56`–57; `Sources/WorldEngine/WorldCamera.swift:39`, `:89` | Shared web viewer loads demo configuration and special-cases preset v2-04 to noon; native camera supports exact fixed comparison poses. These affect explicit presets, not all runtime coordinates. | Put state+camera into a preset schema and keep presets opt-in; camera fitting from area bounds for arbitrary worlds. |
| F16 — MINOR / declared climate priors | `Sources/WorldEnvironment/Phenology.swift:33`–46; `Sources/WorldEngine/Environment.swift:323`, `:355`, `:428` | Denver/Plano/Seattle/Sydney illustrative knot arrays and Chicagoland calendar fallback; native picks explicit profile ID. These are disclosed city-labelled priors, not observation/live phenology or hardcoded observer coordinates. | Data-owned climate/species calendars with measured validity regions and explicit inferred status; retain actual observer/location inputs. |
| F17 — MINOR / declared regional grammar | `Sources/WorldGen/Look.swift:47`–70; `BuildingGenerator.swift:285`–290; `Profiles/look.json:42`–59 | Chicago-labelled house contrast classes and family mappings apply through building type/material. Denver families can inherit them; archetype palettes override as documented. Native/export output. | Semantic house/material classes with pack provenance; no direct block-name dispatch required. Verify regional hue/contrast on hold-outs. |
| F18 — MINOR / regional style data | `Profiles/front-range.json:32`–159; `Profiles/chicago-dense-north.json:324`–729; `Profiles/archetypes-miami.json:2`; all paths under Sources/WorldGen | Region-labelled archetype IDs, forms and palette proposals. Affects eligible shipping profiles; Miami file presence alone does not prove region selection (no Miami box in regions.json). | Keep archetype/data-driven selection and measured tag precedence; report unsupported regions rather than pretending all profiles are active. |
| F19 — MINOR / contextual comment, general prior | `Sources/WorldGen/Yards/YardGeneration.swift:249`; `Profiles/yards.json:3`, `:139`, `:206`, `:273` | Lakeview 0–20% lawn motivates frontGarden/rearPaving; code actually reads selected profile rules. All areas with that profile are affected. | Urban-fabric/density and mapped surface rules, with region priors where data are absent; no Lakeview-name test in generator. |
| F20 — MINOR / sampled grammar | `Sources/WorldGen/Profiles/house-families.json:3`; `RoofAssembly.swift:6`; `BuildingDetails.swift:7`; `HouseDetails.swift:92` | Roof complexity tuned toward South Evanston lidar; Chicago/Denver pack styles are cited for generic family details. Native/export. Most source occurrences are provenance rather than branches. | Broader style/era cohorts with uncertainty; mapped roof/height tags retain priority. |
| F21 — MINOR / inferred species prior | `Sources/WorldGen/SceneGenerator.swift:540`–547 | Comment says Chicago/North Shore willow prior; code uses profile.trees.weeping, proximity to water/park and seeded ref, not a city test. | Keep the general ecological rule, expand species priors from evidence; no place exception to remove. |
| F22 — MINOR / authored global number | `Sources/WorldGen/Props.swift:1112`–1117 | Trunk-base AO .65, height share .06 is illustrated by Evanston’s median tree height. Applied generally; no Evanston gate. | Document visual hypothesis, validate height-scaled effect across species/areas; use physically/artistically justified height envelope rather than hero-only validation. |
| F23 — MINOR / authored geometry-camera references | `Sources/WorldGen/Profiles/look.json:80`–91; `HouseArchetypes.swift:177`–181; `ArchetypeMassing.swift:18` | Split main share .45 judged from Denver split-level artwork; 565 px/50° are stored reference camera values. Search found declarations/defaults but no runtime reads of tierFrameHeightPx/tierFovDegrees, so no live camera-specialization claim from their presence. | Treat split ratios as general archetype hypotheses; either wire real projected size deliberately or remove obsolete reference fields in owner lane. |
| F24 — MINOR / calibration data | `web/bakeoff/data/sky-correction.json:6`–48; `data/haze-conflict.json:18`; `MockDaytime.swift:13` | Sky adjustment aggregates nine named target images (not only Sloan); haze file records a Chicago-region comparison; native MockDaytime explicitly preserves regional species mix. | Retain cross-frame calibration and distinguish diagnostic comparisons from runtime selectors; no per-camera colour override found. |
| F25 — MINOR / default region convention | `Sources/WorldGen/Profiles/seasonal-palette.json:3`; `Profiles/vegetation.json:136` | Chicago acts as default palette when no regional dressing is available; mapped regional dressing can replace slots. This is not a location lookup but can bias unsupported regions. | Explicit generic/inferred fallback or climate-appropriate profile, with coverage warning. |
| F26 — MISLEADS A DECISION if presented as universal confidence | `Sources/WorldPackage/MapLayer/MapCalibration.swift:11`, `:25` | Confidence bins fitted to Sloan/Evanston/Lakeview and Denver/Cook parcels; no runtime ID special case. Declares hold-out gaps up to .39/.30, so named sample provenance is appropriate but worldwide calibration is not established. | Calibrate/validate by independent region/fabric, report domain and uncertainty; keep source definitions. |

## Checked and found clean, within this scan

- **Literal source-ID exceptions:** none in runtime Swift/Metal/JS searched. SceneGenerator’s `gen:lamp:way/123:4` at line 57 is a documentation example; the Sloan way ID occurs as camera provenance in scenes.json. Actual OSM refs select stable random draws and retain source identity, not specially drawn buildings/trees.
- **Native render/shader coordinates:** WorldCamera, World+Context, rendering/material/shader paths contain no Sloan/Lakeview latitude/longitude test. Environment constructs SkyObserver from supplied coordinate/timezone; geodesy constants and shader noise seed 41.0 are not Chicago coordinates.
- **Core generator:** building eligibility/massing, roof assembly, mapped roads/tunnel predicate, stream/bridge diagnostics, tree stretch and context clipping use tags, bounds, profile rules and stable seeds. No block equality or hardcoded camera eye discovered. Local-profile overfitting risks remain those listed above.
- **Shared web loading/materials/near plane:** WorldScene and LocalFrame read package coordinates; camera-near logic uses altitude/FOV-style inputs, not named blocks. No OSM-ID-based mesh/material replacement found. Preset and timezone findings are explicitly not included in this clean claim.
- **New prototypes:** crown-v3.js, scene-budget.js, scene-budget-entry.js and entry.js contain no block/camera-name/coordinate dispatch; dimensions/visibility depend on species, geometry and current projection. Their other correctness problems remain in the separate A8 audits; “clean of block logic” is not a render-quality pass.
- **Physical/data constants:** WGS84 ellipsoid, stable RNG multipliers, tone-map coefficients, sun transforms and normalized geometry ratios were inspected as non-geographic literals; long numbers alone are not hidden OSM IDs.
- **Research/pack references:** names in comments such as regions-chicagoland-miami or denver-05-split usually identify the source design, not a runtime location test. Bundled compiled mock values and generated facade records are intentionally geographic assets; consuming them through a generic schema is not itself a violation.

## Reproduction and limits

Use `rg -n -i` across the listed roots for `sloan|lakeview|wilmette|greenville|highland|denver|chicago|evanston|plano|seattle|sydney|miami|new.?orleans|san.?francisco|brooklyn|manhattan|midtown|front-range|north-shore`, then separate searches for `GeoCoordinate`, `latitude`, `longitude`, literal `way/`, `node/`, `relation/`, `.id ==`, `profile.id`, `manifest.id`, `preset`, camera `eye/target`, `variantWeights`, `canopyShare`. Include Swift/Metal/JS/MJS/JSON; exclude node_modules, evidence, generated export bulk and duplicated mock-values for the primary source scan; follow matching selectors into referenced data. Tests/capture scripts are evaluated as fixtures, never used to assert a shipping exception.

The severity labels concern generalization, not authorization: some choices explicitly record R’s approval. No approved pack was edited or treated as permission to rewrite render code. This audit establishes concrete source paths and risks, not real-world accuracy of every regional prior. No new performance/visual/rights claim follows.

## Primary place-name hit ledger

Each occurrence below points to the row defining effect, output scope, severity and general replacement; grouped references retain each file/line without duplicating lengthy JSON comments.

| File:line | Finding | Matched declaration/comment excerpt |
|---|---|---|
| `web/bakeoff/foliage.js:55` | F08 | const family=Object.values(data.vegetation).find(f=>f.packSpecies===species.id),fallback=data.vegetation[data.vegetationRegions.chicago.bark],bark=new T.Color(species.bark /  / … |
| `web/bakeoff/foliage.js:115` | F07 | const recipe=pack.content.speciesByCity.denver.find(s=>s.name==='American elm'); |
| `Sources/WorldEngine/Environment.swift:355` | F16 | public static let phenologyProfiles: [PhenologyProfile] = [.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo, .chicagoland] |
| `web/bakeoff/scenes.json:2` | F11 | "lakeview": { |
| `web/bakeoff/scenes.json:3` | F11 | "world": "/world/lakeview/", |
| `web/bakeoff/scenes.json:4` | F11 | "mock": "01-lakeview", |
| `web/bakeoff/scenes.json:22` | F11 | "cameraEvidence": "Visual composition fit to style-b-calibration-v2/scenes/01-lakeview; camera matrices unavailable. Cornelia Avenue, south sidewalk.", |
| `web/bakeoff/scenes.json:23` | F11 | "region": "chicago", |
| `web/bakeoff/scenes.json:26` | F11 | "sloans": { |
| `web/bakeoff/scenes.json:27` | F11 | "world": "/world/sloans/", |
| `web/bakeoff/scenes.json:28` | F11 | "mock": "06-sloans", |
| `web/bakeoff/scenes.json:46` | F11 | "cameraEvidence": "Visual composition fit to style-b-calibration-v2/scenes/06-sloans; west-facing from mapped path way/231141080 on the eastern shore; camera matrices unavailabl… |
| `web/bakeoff/scenes.json:47` | F10 | "waterProfile": "sloans_lake", |
| `web/bakeoff/scenes.json:48` | F10 | "waterState": "sloans_lake_clear_wind_10", |
| `web/bakeoff/scenes.json:49` | F10 | "waterMechanicsProfile": "sloan", |
| `web/bakeoff/scenes.json:54` | F10 | "region": "denver", |
| `web/bakeoff/facade-policy.js:4` | F09 | const id=region==='chicago'?({greystoneFacade:'chicago-greystone-two-flat',brickStackedFacade:'chicago-brick-two-flat',sixFlat:'chicago-brick-two-flat'}[f]):region==='denver'?({… |
| `web/bakeoff/provenance.json:21` | F13 | "path": "Generated/package/sloans-lake/world.json", |
| `web/bakeoff/provenance.json:29` | F13 | "path": "web/bakeoff/generated/lakeview-sheil-park/world.json", |
| `web/bakeoff/provenance.json:39` | F13 | "path": "docs/proposals/style-b-calibration-v2/frames/01-lakeview.png", |
| `web/bakeoff/provenance.json:43` | F13 | "path": "docs/proposals/style-b-calibration-v2/frames/06-sloans.png", |
| `Sources/WorldGen/ArchetypeMassing.swift:18` | F23 | /// Split-level massing (house-archetypes-v1 'buildingPartsProposal', e.g. denver-05-split): the mapped footprint |
| `web/bakeoff/data/haze-conflict.json:18` | F24 | "chicagoKey": "regions[id=great-lakes].seasons.summer.clear", |
| `Sources/WorldGen/Look.swift:47` | F17 | /// Family ID → house-contrast-v1 type; "flat" = chicago_two_flat below three storeys, chicago_three_flat from three. |
| `Sources/WorldGen/Look.swift:49` | F17 | /// Chicago brick families whose walls take the pack's brick wall swatches (seeded per building). |
| `Sources/WorldGen/Look.swift:65` | F17 | ["chicago_three_flat", "chicago_two_flat", "chicago_bungalow", "workers_cottage"].compactMap { values($0) }.filter(\.brick).map(\.wall) |
| `Sources/WorldGen/Look.swift:70` | F17 | return values(id == "flat" ? (floors >= 3 ? "chicago_three_flat" : "chicago_two_flat") : id) |
| `web/bakeoff/data/facade-mechanics.json:6` | F09 | "windowHeightM": "Sources/WorldGen/Profiles/chicago-dense-north.json/families[brickStackedFacade].windows.height", |
| `web/bakeoff/data/sky-correction.json:6` | F24 | "method": "Sampled the nine calibrated frames in frames/ (01-lakeview, 02-brooklyn, 03-midtown, 04-san-francisco, 05-alley, 05-train, 06-sloans, 07-new-orleans, 08-miami). Sky p… |
| `web/bakeoff/data/sky-correction.json:8` | F24 | "01-lakeview": [ |
| `web/bakeoff/data/sky-correction.json:13` | F24 | "02-brooklyn": [ |
| `web/bakeoff/data/sky-correction.json:18` | F24 | "03-midtown": [ |
| `web/bakeoff/data/sky-correction.json:23` | F24 | "04-san-francisco": [ |
| `web/bakeoff/data/sky-correction.json:38` | F24 | "06-sloans": [ |
| `web/bakeoff/data/sky-correction.json:43` | F24 | "07-new-orleans": [ |
| `web/bakeoff/data/sky-correction.json:48` | F24 | "08-miami": [ |
| `Sources/WorldGen/SceneGenerator.swift:540` | F21 | /// ('trees.weeping'; Chicago/North Shore only) near a water edge, else inside a park. Its own salt, |
| `Sources/WorldGen/BuildingDetails.swift:7` | F20 | // Family details on top of walls and roofs (regions-chicagoland-miami §3–§5, §12). All seeded per |
| `Sources/WorldGen/Profiles/vegetation.json:2` | F05 | "comment": "Tree species families and their regions (look-fix-v1 §5, vegetation-v1). Colours are vegetation-v1 vegetation-colours.json neutralCrownAlbedo per season (spring, sum… |
| `Sources/WorldGen/Profiles/vegetation.json:4` | F25 | "chicago-oak": { |
| `Sources/WorldGen/Profiles/vegetation.json:15` | F25 | "chicago-maple": { |
| `Sources/WorldGen/Profiles/vegetation.json:26` | F25 | "chicago-elm": { |
| `Sources/WorldGen/Profiles/vegetation.json:37` | F25 | "chicago-linden": { |
| `Sources/WorldGen/Profiles/vegetation.json:48` | F25 | "chicago-honey-locust": { |
| `Sources/WorldGen/Profiles/vegetation.json:59` | F25 | "chicago-spruce": { |
| `Sources/WorldGen/Profiles/vegetation.json:69` | F25 | "denver-cottonwood": { |
| `Sources/WorldGen/Profiles/vegetation.json:80` | F25 | "denver-ash": { |
| `Sources/WorldGen/Profiles/vegetation.json:91` | F25 | "denver-blue-spruce": { |
| `Sources/WorldGen/Profiles/vegetation.json:102` | F25 | "denver-aspen": { |
| `Sources/WorldGen/Profiles/vegetation.json:113` | F25 | "denver-crabapple": { |
| `Sources/WorldGen/Profiles/vegetation.json:124` | F25 | "chicago-weeping-willow": { |
| `Sources/WorldGen/Profiles/vegetation.json:136` | F25 | "chicago": { |
| `Sources/WorldGen/Profiles/vegetation.json:138` | F25 | "evanston", |
| `Sources/WorldGen/Profiles/vegetation.json:139` | F25 | "wilmette", |
| `Sources/WorldGen/Profiles/vegetation.json:140` | F25 | "chicago-dense-north", |
| `Sources/WorldGen/Profiles/vegetation.json:144` | F25 | "deciduous1": "chicago-linden", |
| `Sources/WorldGen/Profiles/vegetation.json:145` | F25 | "deciduous2": "chicago-maple", |
| `Sources/WorldGen/Profiles/vegetation.json:146` | F25 | "deciduous3": "chicago-oak", |
| `Sources/WorldGen/Profiles/vegetation.json:147` | F25 | "deciduous4": "chicago-elm", |
| `Sources/WorldGen/Profiles/vegetation.json:148` | F25 | "deciduous5": "chicago-oak", |
| `Sources/WorldGen/Profiles/vegetation.json:149` | F25 | "deciduous6": "chicago-elm", |
| `Sources/WorldGen/Profiles/vegetation.json:150` | F25 | "deciduous7": "chicago-honey-locust", |
| `Sources/WorldGen/Profiles/vegetation.json:151` | F25 | "deciduous8": "chicago-oak", |
| `Sources/WorldGen/Profiles/vegetation.json:152` | F25 | "conifer1": "chicago-spruce", |
| `Sources/WorldGen/Profiles/vegetation.json:153` | F25 | "conifer2": "chicago-spruce", |
| `Sources/WorldGen/Profiles/vegetation.json:154` | F25 | "deciduous9": "chicago-weeping-willow" |
| `Sources/WorldGen/Profiles/vegetation.json:156` | F25 | "bark": "chicago-oak", |
| `Sources/WorldGen/Profiles/vegetation.json:176` | F05 | "denver": { |
| `Sources/WorldGen/Profiles/vegetation.json:181` | F05 | "deciduous1": "chicago-maple", |
| `Sources/WorldGen/Profiles/vegetation.json:182` | F05 | "deciduous2": "denver-crabapple", |
| `Sources/WorldGen/Profiles/vegetation.json:183` | F05 | "deciduous3": "denver-ash", |
| `Sources/WorldGen/Profiles/vegetation.json:184` | F05 | "deciduous4": "chicago-linden@0.55", |
| `Sources/WorldGen/Profiles/vegetation.json:185` | F05 | "deciduous5": "denver-cottonwood", |
| `Sources/WorldGen/Profiles/vegetation.json:186` | F05 | "deciduous6": "chicago-oak", |
| `Sources/WorldGen/Profiles/vegetation.json:187` | F05 | "deciduous7": "chicago-honey-locust@0.5", |
| `Sources/WorldGen/Profiles/vegetation.json:188` | F05 | "deciduous8": "chicago-elm@0.7", |
| `Sources/WorldGen/Profiles/vegetation.json:189` | F05 | "conifer1": "denver-blue-spruce", |
| `Sources/WorldGen/Profiles/vegetation.json:190` | F05 | "conifer2": "denver-blue-spruce", |
| `Sources/WorldGen/Profiles/vegetation.json:191` | F05 | "deciduous9": "chicago-weeping-willow" |
| `Sources/WorldGen/Profiles/vegetation.json:193` | F05 | "bark": "denver-cottonwood", |
| `Sources/WorldGen/Profiles/vegetation.json:364` | F25 | "chicago": { |
| `Sources/WorldGen/Profiles/vegetation.json:365` | F25 | "city": "chicago", |
| `Sources/WorldGen/Profiles/vegetation.json:367` | F25 | "chicago-dense-north" |
| `Sources/WorldGen/Profiles/vegetation.json:370` | F05 | "denver": { |
| `Sources/WorldGen/Profiles/vegetation.json:371` | F05 | "city": "denver", |
| `Sources/WorldGen/RoofAssembly.swift:6` | F20 | // Sealed roof assemblies (regions-chicagoland-miami §4): a roof is a few rectangular masses, each |
| `Sources/WorldGen/StyleProfile.swift:94` | F18 | /// house-archetypes-v1 archetype ID (e.g. "denver-01-square"). When set, the archetype's values (read by key |
| `Sources/WorldGen/BuildingGenerator.swift:15` | F17 | /// Building level of detail by distance (regions-chicagoland-miami §4, v2 §8.1). |
| `Sources/WorldGen/BuildingGenerator.swift:285` | F17 | // Archetype types keep their palette variant's trim and roof (house-archetypes-v1 per type; for the Chicago |
| `Sources/WorldGen/BuildingGenerator.swift:290` | F17 | // Chicago brick families: one of the pack's brick wall swatches per building, unless the wall colour is mapped. |
| `Sources/WorldGen/Profiles/look.json:19` | F02 | "sloans_lake" |
| `Sources/WorldGen/Profiles/look.json:22` | F02 | "evanston": "lake_michigan", |
| `Sources/WorldGen/Profiles/look.json:23` | F02 | "wilmette": "lake_michigan", |
| `Sources/WorldGen/Profiles/look.json:24` | F02 | "chicago-dense-north": "lake_michigan", |
| `Sources/WorldGen/Profiles/look.json:25` | F02 | "default": "sloans_lake", |
| `Sources/WorldGen/Profiles/look.json:26` | F02 | "front-range": "sloans_lake" |
| `Sources/WorldGen/Profiles/look.json:42` | F17 | "comment": "Generator (P2), house-details families: house-contrast-v1 (R approved, binding) per house type, read by key from Profiles/mock-values.json (generated by Tools/looklo… |
| `Sources/WorldGen/Profiles/look.json:46` | F17 | "greystoneFacade": "chicago_three_flat", |
| `Sources/WorldGen/Profiles/look.json:47` | F17 | "sixFlat": "chicago_three_flat", |
| `Sources/WorldGen/Profiles/look.json:48` | F17 | "courtyardMass": "chicago_three_flat", |
| `Sources/WorldGen/Profiles/look.json:49` | F17 | "cornerMixedUse": "chicago_three_flat", |
| `Sources/WorldGen/Profiles/look.json:50` | F17 | "brickBungalow": "chicago_bungalow", |
| `Sources/WorldGen/Profiles/look.json:51` | F17 | "tudor": "chicago_bungalow", |
| `Sources/WorldGen/Profiles/look.json:52` | F17 | "prairie": "chicago_bungalow", |
| `Sources/WorldGen/Profiles/look.json:53` | F17 | "midCentury": "chicago_bungalow", |
| `Sources/WorldGen/Profiles/look.json:58` | F17 | "victorianRow": "chicago_two_flat", |
| `Sources/WorldGen/Profiles/look.json:59` | F17 | "bungalow": "chicago_bungalow", |
| `Sources/WorldGen/Profiles/look.json:80` | F23 | "comment": "Generator (P2), house-archetypes-v1 (R approved 2026-10-07, binding): the archetype values themselves are read by key from Profiles/mock-values.json; this block hold… |
| `Sources/WorldGen/Profiles/look.json:93` | F03 | "comment": "P2 judgment (R item 1, 7 Oct), measured by P3 against style-b-calibration-v2: weights for an archetype's colourVariations draw (default equal). chicago-02-flats vari… |
| `Sources/WorldGen/Profiles/look.json:94` | F03 | "chicago-02-flats": [ |
| `Sources/WorldGen/Profiles/house-families.json:3` | F20 | "comment": "House family grammar, keyed by profile house type IDs (regions-chicagoland-miami spec \u00a73-\u00a75, \u00a712). Profiles choose families, weights, pitches, eaves a… |
| `Sources/WorldGen/Profiles/house-families.json:391` | F20 | "pack": "denver_ranch (nearest pack family)", |
| `Sources/WorldGen/Profiles/house-families.json:623` | F20 | "pack": "denver_victorian (nearest: small porch, slim posts); Chicago frame cottage is not a pack family", |
| `Sources/WorldGen/Profiles/house-families.json:688` | F20 | "pack": "queen_anne / denver_victorian (trim, casings); Chicago Victorian row is not a pack family", |
| `Sources/WorldGen/Profiles/house-families.json:802` | F20 | "pack": "denver_bungalow", |
| `Sources/WorldGen/Profiles/house-families.json:836` | F20 | "pack": "denver_bungalow (porch); foursquare is not a pack family", |
| `Sources/WorldGen/Profiles/house-families.json:885` | F20 | "pack": "denver_ranch", |
| `Sources/WorldGen/Profiles/house-families.json:930` | F20 | "pack": "denver_victorian", |
| `Sources/WorldGen/Profiles/house-families.json:994` | F20 | "pack": "denver_ranch (nearest pack family; minimal traditional is not a house-details-v1 family)", |
| `Sources/WorldGen/Profiles/house-families.json:1034` | F20 | "pack": "denver_ranch (nearest pack family; split-level is not a house-details-v1 family)", |
| `Sources/WorldGen/HouseDetails.swift:92` | F20 | /// sheets: dark metal rails on Chicago bungalow and flat stoops, painted rails on worker cottages. |
| `Sources/WorldGen/Yards/YardGeneration.swift:249` | F19 | // City lots (look-fix §1.2: Lakeview 0–20 % lawn): a planted front garden and/or a paved |
| `Sources/WorldGen/Profiles/archetypes-miami.json:2` | F18 | "comment": "house-archetypes-v1 (R approved 2026-10-07) Miami archetypes as engine house types: DATA ONLY, NOT USED. There is no Miami region profile or test area yet; a future … |
| `Sources/WorldGen/Profiles/archetypes-miami.json:3` | F18 | "metro": "Miami", |
| `Sources/WorldGen/Profiles/archetypes-miami.json:23` | F18 | "archetype": "miami-01-ranch" |
| `Sources/WorldGen/Profiles/archetypes-miami.json:41` | F18 | "archetype": "miami-02-mediterranean" |
| `Sources/WorldGen/Profiles/archetypes-miami.json:59` | F18 | "archetype": "miami-03-cottage" |
| `Sources/WorldGen/Profiles/archetypes-miami.json:78` | F18 | "archetype": "miami-04-mimo" |
| `Sources/WorldGen/Profiles/archetypes-miami.json:96` | F18 | "archetype": "miami-05-suburban" |
| `Sources/WorldGen/Profiles/evanston.json:2` | F04 | "id": "evanston", |
| `Sources/WorldGen/Profiles/evanston.json:4` | F04 | "name": "Evanston regional proposal", |
| `Sources/WorldGen/Profiles/evanston.json:738` | F04 | "area": "Data/areas/evanston-south (1 km2)", |
| `Sources/WorldGen/Profiles/evanston.json:749` | F04 | "area": "Data/areas/evanston-south (1 km2)", |
| `Sources/WorldGen/Profiles/evanston.json:760` | F04 | "area": "Data/areas/evanston-south (1 km2)", |
| `Sources/WorldGen/Profiles/evanston.json:768` | F04 | "source": "USGS 3DEP lidar (EPT USGS_LPC_IL_4County_Cook_2017_LAS_2019, flight April-May 2017), roof-plane classification of 650 houses in Data/areas/evanston-south (docs/resear… |
| `Sources/WorldGen/MockValues.swift:191` | F02 | try LakeWater(mockValues(), order: LookSpec.bundled?.water.shoreProfiles?.order ?? ["lake_michigan", "sloans_lake"]) |
| `Sources/WorldGen/Profiles/regions.json:2` | F06 | "comment": "Regions select a style profile by location. Data only: generator code never names a place. First match wins; areas outside every region use the default profile. The … |
| `Sources/WorldGen/Profiles/regions.json:12` | F06 | "id": "wilmette", |
| `Sources/WorldGen/Profiles/regions.json:13` | F06 | "profile": "wilmette", |
| `Sources/WorldGen/Profiles/regions.json:14` | F06 | "comment": "Wilmette's main part (east of -87.733). South edge just north of the Evanston-Wilmette town line (about Isabella St; OSM 42.0688-42.0696), so the box never reaches i… |
| `Sources/WorldGen/Profiles/regions.json:18` | F06 | "id": "wilmette-west", |
| `Sources/WorldGen/Profiles/regions.json:19` | F06 | "profile": "wilmette", |
| `Sources/WorldGen/Profiles/regions.json:20` | F06 | "comment": "Wilmette west of Evanston (OSM: Wilmette spans 42.0650-42.0849 here), ending 50 m west of Evanston's west line (-87.7324).", |
| `Sources/WorldGen/Profiles/regions.json:24` | F06 | "id": "evanston", |
| `Sources/WorldGen/Profiles/regions.json:25` | F06 | "profile": "evanston", |
| `Sources/WorldGen/Profiles/regions.json:26` | F06 | "comment": "Evanston from Howard St (Chicago line) to the Wilmette line, from the city's west line (OSM -87.7086 to -87.7099) to the lake. Holds the committed test area Data/are… |
| `Sources/WorldGen/Profiles/regions.json:30` | F06 | "id": "evanston-northwest", |
| `Sources/WorldGen/Profiles/regions.json:31` | F06 | "profile": "evanston", |
| `Sources/WorldGen/Profiles/regions.json:32` | F06 | "comment": "Evanston's northwest part, where the city line runs west to -87.7274 (north of 42.0575): Lovelace Park.", |
| `Sources/WorldGen/Profiles/regions.json:36` | F06 | "id": "evanston-far-northwest", |
| `Sources/WorldGen/Profiles/regions.json:37` | F06 | "profile": "evanston", |
| `Sources/WorldGen/Profiles/regions.json:38` | F06 | "comment": "The strip of Evanston west of -87.7274 between 42.0635 and the Wilmette line (city line at -87.7324).", |
| `Sources/WorldGen/Profiles/regions.json:42` | F06 | "id": "evanston-lakefront-north", |
| `Sources/WorldGen/Profiles/regions.json:43` | F06 | "profile": "evanston", |
| `Sources/WorldGen/Profiles/regions.json:44` | F06 | "comment": "Evanston's lakefront corner north of the Isabella St line, where the town line jogs north along -87.6828 to 42.0717.", |
| `Sources/WorldGen/Profiles/regions.json:48` | F06 | "id": "chicago-rogers-park", |
| `Sources/WorldGen/Profiles/regions.json:49` | F06 | "profile": "chicago-dense-north", |
| `Sources/WorldGen/Profiles/regions.json:50` | F06 | "comment": "Rogers Park, from the review window (west edge -87.681) south to the Edgewater box; north edge just south of Evanston's Howard St line (the review window reached 42.… |
| `Sources/WorldGen/Profiles/regions.json:54` | F06 | "id": "chicago-edgewater-uptown", |
| `Sources/WorldGen/Profiles/regions.json:55` | F06 | "profile": "chicago-dense-north", |
| `Sources/WorldGen/Profiles/regions.json:60` | F06 | "id": "chicago-lakeview", |
| `Sources/WorldGen/Profiles/regions.json:61` | F06 | "profile": "chicago-dense-north", |
| `Sources/WorldGen/Profiles/regions.json:62` | F06 | "comment": "Lakeview, from the review window widened west to just past Ashland Ave (-87.672) and north to Montrose Ave, east to the lake. Holds the committed test area Data/area… |
| `Sources/WorldGen/Profiles/regions.json:66` | F06 | "id": "chicago-lincoln-park", |
| `Sources/WorldGen/Profiles/regions.json:67` | F06 | "profile": "chicago-dense-north", |
| `Sources/WorldGen/Profiles/seasonal-palette.json:2` | F25 | "comment": "v2 spec §3.2 seasonal material palettes; backdrop (the land beyond the data) from the lighting bible look-fix-v1 §4: #A9B4A0 summer, #BDC8D4 winter (sRGB authoring c… |
| `Sources/WorldGen/Profiles/yards.json:3` | F19 | "comment": "Yard and street-tree rules per style profile ID (profiles without an entry use 'default'). Densities, lawn endpoint colours and bed areas follow look-fix-v1 §1.1-§1.… |
| `Sources/WorldGen/Profiles/yards.json:139` | F19 | "evanston": { |
| `Sources/WorldGen/Profiles/yards.json:206` | F19 | "wilmette": { |
| `Sources/WorldGen/Profiles/yards.json:273` | F19 | "chicago-dense-north": { |
| `Sources/WorldGen/MockDaytime.swift:13` | F24 | ///   (species colours, the Denver mix) are unchanged. |
| `Sources/WorldGen/Profiles/wilmette.json:2` | F04 | "id": "wilmette", |
| `Sources/WorldGen/Profiles/wilmette.json:4` | F04 | "name": "Wilmette regional proposal", |
| `Sources/WorldGen/Profiles/wilmette.json:778` | F04 | "area": "Data/areas/wilmette-vattmann-park (1 km2)", |
| `Sources/WorldGen/Profiles/wilmette.json:789` | F04 | "area": "Data/areas/wilmette-vattmann-park (1 km2)", |
| `Sources/WorldGen/Profiles/wilmette.json:800` | F04 | "area": "Data/areas/wilmette-vattmann-park (1 km2)", |
| `Sources/WorldGen/Profiles/front-range.json:32` | F18 | "archetype": "denver-02-bungalow" |
| `Sources/WorldGen/Profiles/front-range.json:52` | F18 | "archetype": "denver-01-square" |
| `Sources/WorldGen/Profiles/front-range.json:72` | F18 | "archetype": "denver-04-ranch" |
| `Sources/WorldGen/Profiles/front-range.json:90` | F18 | "archetype": "denver-03-minimal" |
| `Sources/WorldGen/Profiles/front-range.json:109` | F18 | "archetype": "denver-05-split" |
| `Sources/WorldGen/Profiles/front-range.json:140` | F18 | "archetype": "denver-06-infill" |
| `Sources/WorldGen/Profiles/front-range.json:159` | F18 | "archetype": "denver-06-infill", |
| `Sources/WorldGen/Profiles/front-range.json:164` | F18 | "comment": "v2 §4.4 priority rules. Keys are footprint situations; values are type weights before eligibility filtering. Archetypes (house-archetypes-v1, R approved 2026-10-07; … |
| `Sources/WorldGen/Profiles/front-range.json:211` | F04 | "area": "Data/areas/sloans-lake (1.92 km2; fabric value, the lake is 37 % of the area)", |
| `Sources/WorldGen/Profiles/front-range.json:219` | F18 | "added": "minimalTraditional (denver-03-minimal) and splitLevel (denver-05-split; two-storey main block plus one-storey wing from the pack's buildingPartsProposal); ranch minAsp… |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:2` | F18 | "id": "chicago-dense-north", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:4` | F18 | "name": "Chicago dense north side proposal", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:324` | F18 | "archetype": "chicago-01-bungalow" |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:411` | F18 | "archetype": "chicago-02-flats" |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:562` | F18 | "archetype": "chicago-03-cottage" |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:644` | F18 | "archetype": "chicago-04-foursquare" |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:729` | F18 | "archetype": "chicago-05-ranch" |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1126` | F04 | "comment": "unknown and large: measured (OSM building:levels, 1,756 levels-tagged principal houses in three Chicago dense-north cells; regionkit floors, 2026-10-06), so houses w… |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1252` | F04 | "comment": "Documentation only; the profile decoder ignores this object. Fields not listed here are unmeasured proposal values (docs/proposals/regions-chicagoland-miami).", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1262` | F04 | "source": "OSM building:levels on principal houses (generator houses minus probable garages) in the region kit's Chicago dense-north cells lakeview-gill-park, lincoln-park-oz-pa… |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1263` | F04 | "method": "Tools/regionkit/regionkit.sh floors regions/chicagoland.json --zone dense-north --profile chicago-dense-north: families grouped by their first floors value, generator… |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1330` | F04 | "area": "Data/areas/lakeview-sheil-park (1 km2)", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1352` | F04 | "area": "Data/areas/lakeview-sheil-park (1 km2)", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1363` | F04 | "area": "Data/areas/lakeview-sheil-park (1 km2)", |
| `Sources/WorldGen/Profiles/chicago-dense-north.json:1371` | F04 | "added": "foursquare (chicago-04-foursquare) and ranch (chicago-05-ranch, minAspect 1.3 so the sheet's 12.4 x 8.7 m footprint is eligible) from the front-range types' shape fiel… |
| `Sources/WorldGen/Props.swift:1116` | F22 | /// tree (Evanston median), 0.25–0.35 m on young 4–6 m trees. |

Used: cited runtime/data/fixture sources on ee66770; general-rule requirement in AGENTS.md. Mock: no new comparison; named mock references inspected as provenance. Deviation: static source scan, no builds, captures or code changes.
Tracker update:
