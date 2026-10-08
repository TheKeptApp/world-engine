# Feature evidence index — 8 Oct 2026

One row per feature, drawn only from existing reports. “Last build commit” records the latest implementation/evidence revision explicitly identified by the cited report, **not** proof of the latest runtime build or a native pass. Unknown provenance is `unknown`; research/filing SHAs are not build SHAs. Calibration PNGs are gitignored local reference assets: absence in a clone is not permission to invent a target. The [report evidence line](../CONTRIBUTING-lanes.md#build-evidence--r-8-oct-2026) must name the source/section and actual frame used.

| Feature | Research doc | Mock/calibration target | Owning lane | Current status | Last build commit | Consumed by |
|---|---|---|---|---|---|---|
| Foliage | [foliage-exp1-spec](../research/foliage-exp1-spec.md), Exact candidate math / Before-after execution; [foliage-rendering-v1](../research/foliage-rendering-v1.md) §1 | calibration-v2 `frames/06-sloans.png`, `frames/01-lakeview.png` | 5A native shading; P2 crowns; A2 web; A3 blind scores | Native-first off → remove → layered specified, not built. Historical native/web foliage 2; no predicted gain claimed. | Web `355c6fb` per [PORT-LIST](../../web/bakeoff/PORT-LIST.md) §§2–3; native/exp1: unknown | Sources/WorldGen/Props.swift; Sources/WorldEngine/Shaders/WorldShaders.metal; web/bakeoff/foliage.js (existing mechanisms; exp1: none) |
| Water | [web-ios-parity](web-ios-parity.md) item 2; [PORT-LIST](../../web/bakeoff/PORT-LIST.md) §5; lake-winter-v1 / water-surfaces-v1; [Execution brief](../execution/water.md): spec-only, not started for proposed change | calibration-v2 `frames/06-sloans.png`; lake-winter-v1 water values | 5A native (Opus); A2 inside bakeoff | Web partial; native colour/reflection equivalence unproven; shared look grade 2 is not water integration proof. | Web `355c6fb` colours, `80ed32c` shore; native: unknown | Sources/WorldEngine/Shaders/WorldShaders.metal; Sources/WorldGen/ShoreBand.swift; web/bakeoff/main.js |
| Ground | [web-ios-parity](web-ios-parity.md) item 3; [Execution brief](../execution/ground.md): spec-only, not started for proposed change | calibration-v2 `frames/06-sloans.png`, `frames/01-lakeview.png` | 5A shader; P2 lot data; A2 web | Web partial; shared lawn base misses native lot variation. Saved web ground 2. | unknown | Sources/WorldEngine/Shaders/WorldShaders.metal; web/bakeoff/main.js (partial) |
| AO | [foliage-exp1-spec](../research/foliage-exp1-spec.md), Exact candidate math; [web-ios-parity](web-ios-parity.md) item 4; [Execution brief](../execution/ao.md): spec-only, not started for proposed change | calibration-v2 `frames/06-sloans.png`, `frames/01-lakeview.png` | 5A native; P2 baked crown AO; A2 web | Web crown AO gap overlaps foliage; exp1 is specified only, no double-AO or glow term. | unknown | Sources/WorldEngine/Shaders/WorldShaders.metal; web/bakeoff/main.js (static only; exp1: none) |
| Sky | [web-ios-parity](web-ios-parity.md) item 5; weather-moments-v1 shared sky; [Execution brief](../execution/sky.md): spec-only, not started for proposed change | calibration-v2 `frames/06-sloans.png`, `frames/01-lakeview.png` | 5A native; A2 bakeoff; A6 separate live-sky demo | Bakeoff partial; saved sky 3. A6 demo is separate, not bakeoff parity; pending cloud concepts not approved. | unknown | Sources/WorldGen/SkyImage.swift; web/bakeoff/sky.js |
| Shadows | [device-tiers-v1](../perf/device-tiers-v1.md), budget policy; [A8 verifier](../review/verifier-2026-10-08c.md) items 2,4–6; [Execution brief](../execution/shadows.md): spec-only, not started for proposed change | calibration-v2 frames 06-sloans / 01-lakeview; `sharedLook.lighting.shadow.neutralWitnessShadowToLitLinearY` | 5A native; P2 caster geometry; A2 web | Saved web 5,008 / 67,190 below 150k; native unproven. Halving unapproved; preserve approved reach. Hero/standard provisional. | Web `355c6fb`, saved evidence `4127a32` per PORT-LIST §4; native: unknown | Sources/WorldEngine/Environment.swift; web/bakeoff/shadow-casters.js |
| Haze | [web-ios-parity](web-ios-parity.md) item 7; [haze-visibility-v1 STATUS](../proposals/haze-visibility-v1/STATUS.md), Precedence / Mountain rule; [Execution brief](../execution/haze.md): spec-only, not started for proposed change | calibration-v2 `frames/06-sloans.png`; haze-visibility-v1 `definition` (5% MOR), regional clear fixture | 5A native migration; A2 web | Web frozen-clear fixture implemented; native 5% MOR migration and broader local-layer parity pending. Preserve local fog. | Web `b012b71`, retained `355c6fb` per PORT-LIST §1; native: unknown | web/bakeoff/atmosphere.js (homogeneous); native 5% MOR: none |
| Facades | [web-ios-parity](web-ios-parity.md) item 8; [A8 verifier](../review/verifier-2026-10-08c.md) item 7; v2/v2b STATUS; [Execution brief](../execution/facades.md): spec-only, not started for proposed change | calibration-v2 `frames/01-lakeview.png`; approved facade-detail-v2/v2b `content`, `lod`, coverage keys | P2 generators; A2 web; 5A shared look | v2/v2b approved, classified supported buildings only; v1 web adapter not full coverage, far albedo unchanged. | Web `5a373b7` per PORT-LIST §7; native v2/v2b: unknown | Sources/WorldGen/BuildingGenerator.swift; web/bakeoff/facade-policy.js (existing/v1; v2/v2b: none) |
| Streaming | [adaptive-tiles](../data/adaptive-tiles.md), Consumer contract; [ios-new-tiles-v1](../perf/ios-new-tiles-v1.md), Loader compatibility; [A8 runtime audit](../review/verifier-2026-10-08b.md) items 6–8 | unknown (package/coverage budgets are tests, not an approved visual mock) | A4 web consumer; A1 package/data | Export verified; native reads raw areas, not adaptive packages. Runtime evidence has provenance limits; no visual/native pass. | unknown (A8 says saved runtime lacks cryptographic build identity) | Sources/WorldEngine/World.swift; web/src/world.js (prior path; adaptive renderer: none) |
| Builder | [builder-mvp-v1](../research/builder-mvp-v1.md), Recommendation / §5; [owner log](../decisions/owner-log.md) private assets / two-step AI | `docs/proposals/creator-kit-ux-v3/sheets/06-example-wedding.html`, `07-example-activation.html` (concept references, not implemented acceptance) | A12 research/planning; implementation lane unknown; R customer decisions | Events-first hypothesis; conversations and implementation not started. Manual underlay first, AI proposals second; rights/ODbL/independent shadows gate release. | unknown | none |

Calibration frame shorthand resolves under `docs/proposals/style-b-calibration-v2/`. Latest completed saved web grade: [web-4127a32](../lookloop/web-4127a32.md), Sloan’s/Lakeview 2/5, FAIL 0/2; fresh captures pending. West Highland export delivery does not establish a visual grade. See [5A restart](restart-5A.md) and [P2 restart](restart-P2.md) for per-batch sources/frames.

## Written input consumption inventory

Authority: [A8 integration audit](../review/integration-audit-2026-10-08.md), pinned to `8d7c582`; this is a conservative trace, not a new code audit. `none` means no file-specific renderer/build consumer is established, not proof that analogous code cannot exist. Pack-level consumers do not prove every constituent file is used. Compiled JSON, tests, filing, an image gallery or a comment alone do not establish renderer consumption. Pending/unapproved inputs are unavailable to builds even when related older mechanisms exist. Update individual consumption in the implementation commit; retain these rows.

### Packs (pack-level trace)

| Spec / pack / research input | Scope and evidence | Consumed by |
|---|---|---|
| `docs/proposals/ambient-life-kit-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/app-ideas` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/builder-event-templates-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/building-heights-v1` | Ground / data prerequisites; iOS not started*; web not started* | none |
| `docs/proposals/canada-style-b-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/canada-style-b-v2` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/chicago-denver-life-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/country-shortlist-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/creator-kit-ux-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/creator-kit-ux-v3` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/crown-silhouettes-v2` | Foliage; iOS not started*; web not started* | none |
| `docs/research-gpt/data-layers-research-v1` | Ground / data prerequisites; iOS not started*; web not started* | none |
| `docs/research-gpt/data-licence-check-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/demo-storyboard-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/districts-chi-den-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/engine-choice` | Streaming; iOS integrated; web integrated | `Sources/WorldEngine/World.swift`; `web/src/world.js`; `web/bakeoff/main.js` |
| `docs/proposals/event-sitemap-ai-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/experience-v1` | Sky; iOS partial; web partial | `Sources/WorldEngine/Environment.swift`; `Sources/WorldEnvironment/EnvironmentResolver.swift`; `Sources/WorldGen/SkyImage.swift`; `web/src/lighting.js`; `web/bakeoff/main.js` |
| `docs/proposals/facade-detail-v1` | Facades; iOS not started*; web partial | `Sources/WorldGen/BuildingFacades.swift`; `web/bakeoff/facade-policy.js`; `web/bakeoff/facades.js` |
| `docs/proposals/facade-detail-v2` | Facades; iOS not started*; web not started* | none |
| `docs/proposals/facade-detail-v2b` | Facades; iOS not started*; web not started* | none |
| `docs/proposals/fog-v1` | Haze; iOS partial; web partial | `Sources/WorldEngine/Shaders/WorldShaders.metal`; `Sources/WorldEngine/Environment.swift`; `web/live/sky-state.mjs` |
| `docs/proposals/foliage-seasons-v1` | Foliage; iOS partial; web partial | `Sources/WorldGen/Foliage.swift`; `Sources/WorldGen/SceneGenerator.swift`; `Sources/WorldGen/Props.swift`; `web/bakeoff/foliage.js` |
| `docs/proposals/greenville-sc-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/ground-v1` | Ground; iOS integrated; web partial | `Sources/WorldGen/SceneGenerator.swift`; `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/main.js` |
| `docs/proposals/haze-visibility-v1` | Haze; iOS not started*; web partial | `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/atmosphere.js`; `web/live/visibility.mjs` |
| `docs/proposals/house-archetypes-v1` | Facades; iOS partial; web partial | `Sources/WorldGen/HouseArchetypes.swift`; `Sources/WorldGen/BuildingGenerator.swift`; `Sources/WorldGen/HouseDetails.swift`; `Sources/WorldGen/WorldBuild.swift`; `web/src/world.js` |
| `docs/proposals/house-archetypes-v2` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/house-contrast-v1` | Sky; iOS partial; web partial | `Sources/WorldGen/MockValues.swift`; `Sources/WorldGen/MockDaytime.swift`; `Sources/WorldEngine/Environment.swift`; `web/bakeoff/main.js` |
| `docs/proposals/house-details-v1` | Facades; iOS partial; web partial | `Sources/WorldGen/HouseArchetypes.swift`; `Sources/WorldGen/BuildingGenerator.swift`; `Sources/WorldGen/HouseDetails.swift`; `Sources/WorldGen/WorldBuild.swift`; `web/src/world.js` |
| `docs/research-gpt/hyperlocal-weather-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/infrastructure-kit-v1` | Ground; iOS partial; web partial | `Sources/WorldGen/RoadMarkings.swift`; `Sources/WorldGen/SceneGenerator.swift`; `web/src/world.js` |
| `docs/proposals/japan-infrastructure-kit-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/japan-regional-kit-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/japan-showcase-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/japan-style-b-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/lake-winter-v1` | Water; iOS partial; web partial | `Sources/WorldGen/MockValues.swift`; `Sources/WorldGen/ShoreBand.swift`; `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/main.js` |
| `docs/research-gpt/landmarks-research-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/landmarks-style-b-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/landmarks-style-b-v2` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/landmarks-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/licensing-demo-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/live-aircraft-research` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/live-flights-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/live-layers-catalog-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/live-world-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/look-fix-v1` | AO; iOS partial; web partial | `Sources/WorldGen/Props.swift`; `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/main.js` |
| `docs/proposals/mascots-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/master-trackers-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/metro-data-coverage-v1` | Ground / data prerequisites; iOS not started*; web not started* | none |
| `docs/proposals/metro-onboarding-v1` | Ground / data prerequisites; iOS not started*; web not started* | none |
| `docs/proposals/mexico-australia-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/mobile-rendering-v1` | Streaming; iOS partial; web partial | `Sources/WorldEngine/World.swift`; `Sources/WorldPackage/AdaptiveTilePacker.swift`; `web/src/world.js` |
| `docs/proposals/mountain-terrain-v1` | Ground; iOS not started*; web partial | `Sources/WorldEngine/World.swift`; `web/bakeoff/main.js`; `web/bakeoff/backdrop.js` |
| `docs/proposals/neighborhood-product-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/netherlands-style-b-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/night-fog-v1` | Haze; iOS partial; web partial | `Sources/WorldEngine/Shaders/WorldShaders.metal`; `Sources/WorldEngine/Environment.swift`; `web/live/sky-state.mjs` |
| `docs/proposals/night-v1` | Haze; iOS partial; web partial | `Sources/WorldEngine/Shaders/WorldShaders.metal`; `Sources/WorldEngine/Environment.swift`; `web/live/sky-state.mjs` |
| `docs/proposals/nyc-hero-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/nyc-life-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/osm-licence-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/paintover-v1` | Foliage; iOS partial; web partial | `Sources/WorldGen/Props.swift`; `Sources/WorldGen/MockValues.swift`; `web/bakeoff/main.js` |
| `docs/proposals/postcards-widgets-v1` | Other / non-hero scope; iOS partial; web partial | `Sources/WorldGen/Postcards/PostcardFrame.swift`; `Sources/WorldGen/WorldBuild.swift`; `web/src/camera.js` |
| `docs/proposals/race-organizer-ops-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/rain-v1` | Ground; iOS partial; web not started* | `Sources/WorldEngine/Shaders/WorldShaders.metal`; `Sources/WorldEngine/Environment.swift`; `web/bakeoff/main.js` |
| `docs/research-gpt/real-flights-path-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/regional-car-mix-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/regional-look-catalog-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/regions-chicagoland-miami` | Facades; iOS partial; web partial | `Sources/WorldGen/HouseArchetypes.swift`; `Sources/WorldGen/BuildingGenerator.swift`; `Sources/WorldGen/HouseDetails.swift`; `Sources/WorldGen/WorldBuild.swift`; `web/src/world.js` |
| `docs/proposals/regions-northshore-chicago-miami` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/regions-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/road-signs-signals-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/seasonal-holiday-life-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/sf-life-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/sky-cloud-v1` | Sky; iOS not started*; web not started* | none |
| `docs/proposals/sky-seasons-v1` | Sky; iOS partial; web partial | `Sources/LiveSky/Sky/Astro.swift`; `Sources/WorldEnvironment/Phenology.swift`; `web/live/sky-state.mjs` |
| `docs/research-gpt/strategic-research-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/research-gpt/street-geometry-rules-v1` | Ground; iOS partial; web partial | `Sources/WorldGen/RoadMarkings.swift`; `Sources/WorldGen/Look.swift`; `web/src/world.js` |
| `docs/proposals/street-ground-v1` | Ground; iOS not started*; web not started* | none |
| `docs/proposals/street-to-space-v1` | Streaming; iOS not started*; web not started* | none |
| `docs/research-gpt/street-trees-by-metro-v1` | Foliage; iOS not started*; web not started* | none |
| `docs/proposals/style-b-bible-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/style-b-calibration-v2` | Shadows; iOS partial; web partial | `Sources/WorldGen/MockValues.swift`; `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/main.js`; `web/bakeoff/lighting.js` |
| `docs/proposals/terrain-slope-v1` | Ground; iOS not started*; web not started* | none |
| `docs/proposals/uk-style-b-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/us-metros-wave2-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/us-metros-wave3-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/us-regional-landscapes-v1` | Ground; iOS not started*; web not started* | none |
| `docs/proposals/vegetation-v1` | Foliage; iOS partial; web partial | `Sources/WorldGen/Foliage.swift`; `Sources/WorldGen/SceneGenerator.swift`; `Sources/WorldGen/Props.swift`; `web/bakeoff/foliage.js` |
| `docs/proposals/venues-campuses-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/visual-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/visual-v2` | Shadows; iOS partial; web partial | `web/bakeoff/budget.js` |
| `docs/proposals/water-surfaces-v1` | Water; iOS partial; web partial | `Sources/WorldGen/MockValues.swift`; `Sources/WorldEngine/Shaders/WorldShaders.metal`; `web/bakeoff/main.js` |
| `docs/proposals/weather-block-design-v1` | Other / non-hero scope; iOS not started*; web not started* | none |
| `docs/proposals/weather-moments-v1` | Sky; iOS not started*; web partial | `web/bakeoff/sky.js` |
| `docs/proposals/weather-v1` | Sky; iOS partial; web partial | `Sources/WorldEngine/Environment.swift`; `Sources/WorldEnvironment/EnvironmentResolver.swift`; `Sources/WorldGen/SkyImage.swift`; `web/src/lighting.js`; `web/bakeoff/main.js` |
| `docs/research-gpt/web-stack-v1` | Streaming; iOS not started*; web partial | `web/src/world.js`; `web/bakeoff/main.js` |

### Individual written inputs

Inventory covers tracked textual docs, packs, specs and research (Markdown, JSON, CSV, text and HTML), excluding this index; capture/score files are evidence, not implementation. HTML can also be a mock; its renderer-consumption status is separate from visual citation. Each row is file-specific; follow the pack row for aggregate scope.

| Spec / pack / research document | Evidence scope | Consumed by |
|---|---|---|
| `docs/CONTRIBUTING-lanes.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/VISUAL_DIRECTION.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/architecture.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/gate-5b.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/ground-diagnosis.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/infrastructure.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/yards-visibility.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/buildings/yards.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data-licensing.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data-sources/live-aircraft-checks.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data-sources/metro-transit.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/adaptive-tiles.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/area-size-budget.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/building-heights.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/building-roofs.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/context-rings.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/elevation.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/fallback-validation.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/height-null-diagnosis.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/map-layer.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/sloans-lake-street-data.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/data/west-highland.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/decisions/owner-log.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/decisions/style-target.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/design-registry.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/environment.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/experience.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/feedback/realitykit-postprocess-trap.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/handoff/l1-live-world.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/handoff/p0.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/handoff/p1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/handoff/p2-world-engine.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/handoff/p3-lookloop.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/legal/credits-draft.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/legal/data-licence-inventory-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/alerts.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/deploy.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/planes.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/satellites.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/sky.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/live-world/transit.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/look-spec-changes.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/m2/report.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/m3/report.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/m3/tone-targets.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/milestone1/m1b-gate-report.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/outreach.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/pack-usage.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/package-format.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/device-tiers-v1.md` | A8: iOS partial, web partial | `web/bakeoff/budget.js` |
| `docs/perf/gpu-attribution.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/ios-new-tiles-v1.md` | A8: iOS not started*, web not started* | none |
| `docs/perf/m2-matched/realitykit-20261005-174330-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/realitykit-20261005-174330-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/realitykit-20261005-174330-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/realitykit-20261005-183941-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/realitykit-20261005-183941-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/realitykit-20261005-183941-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-174628-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-174628-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-174628-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-190031-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-190031-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgl2-20261005-190031-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174458-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174458-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174458-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174910-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174910-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-174910-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-191838-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-191838-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m2-matched/threejs-webgpu-20261005-191838-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street-run1/attribution.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street-run1/costs.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street-v3/costs.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street-v3/noMSAA-maxclock-gpu.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street-v3/traces.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street/costs.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-attribution/street/traces.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/loop-clear-gpu.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/loop-rain-gpu.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/maxclock-clear-gpu.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-231905-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-231905-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-231905-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-232127-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-232127-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a-gate/realitykit-20261005-232127-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/console/sequence.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212357-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212357-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212357-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212519-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212519-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212519-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212641-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212641-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212641-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212803-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212803-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212803-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212957-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212957-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-212957-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-213218-frames.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-213218-seconds.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/m3-phase5a/realitykit-20261005-213218-summary.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/perf/walk-10min/metrics.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/plan-m1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/postcards.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/INDEX.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/ambient-life-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/style-c-illustrated-concept/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/style-c-illustrated-concept/STYLE-C-NOTE.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/style-c-illustrated-concept/ambient-life-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/style-c-illustrated-concept/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/style-c-illustrated-concept/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-matte-candidate-2026-10-07/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-matte-candidate-2026-10-07/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-photoreal-2026-10-07/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-photoreal-2026-10-07/SUPERSEDED.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-photoreal-2026-10-07/ambient-life-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-photoreal-2026-10-07/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ambient-life-kit-v1/superseded-photoreal-2026-10-07/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/client-01-wedding.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/client-02-festival.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/client-03-game-day.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/client-04-activation.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/client-05-community.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/common-rules.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/edit-provenance.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/parametric-parts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/rules/01-wedding.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/rules/02-festival.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/rules/03-game-day.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/rules/04-activation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/rules/05-community.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/templates.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/builder-event-templates-v1/visual-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-01-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-02-yards.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-03-vehicles.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-04-transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-05-furniture.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-06-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/canada-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-01-baygable.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-02-semi.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-03-annex.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-04-workers.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-05-midrise.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-06-condo.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/toronto-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-01-special.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-02-craftsman.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-03-westcoast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-04-edwardian.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-05-laneway.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-06-podium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v1/vancouver-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/evidence/ca-toronto-gtfs.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/evidence/ca-toronto-massing.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/evidence/ca-toronto-trees.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/montreal-archetypes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/montreal-plateau.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/montreal-rowhouses.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/phone-check/results.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/promptset.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/street-details.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/toronto-annex.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/toronto-archetypes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/toronto-block-paintover.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/toronto-leslieville.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/trees-seasons.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/vancouver-archetypes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/vancouver-block-paintover.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/vancouver-false-creek.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/vancouver-west-end.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/canada-style-b-v2/weather-moments.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/chicago-denver-life-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/VERSIONS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/screen-boards.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/assets/THREE-LICENSE.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/component-sheet.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/design-tokens.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/design-tokens.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/reference-provenance.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/screen-boards.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v1/v2/validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/board-validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/boards.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/design-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/reference-provenance.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/screen-boards.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/01-mode-switch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/02a-easy-desktop.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/02b-easy-phone.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/03-pro-workspace.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/04-shared-client.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/05-example-race.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/06-example-wedding.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/07-example-activation.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/sheets/08-segments.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/creator-kit-ux-v3/world-look-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/revision-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/superseded/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/crown-silhouettes-v2/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/image-prompt.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/script.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/shots.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/storyboard-board.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/SUPERSEDED.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/image-prompt.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/script.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/shots.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-orbit-terminator/storyboard-board.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/SUPERSEDED.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/image-prompt.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/script.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/shots.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/superseded/v1-original/storyboard-board.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/demo-storyboard-v1/zoom-sequence.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/01-chicago-loop-river.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/02-chicago-lakefront.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/03-chicago-lakeview.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/04-denver-lodo.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/05-denver-highlands-sloan.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/06-denver-front-range.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/07-chicago-loop-river-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/districts-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/districts-chi-den-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/engine-choice/ENGINE-CHOICE-REVIEW.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/FOLLOWUPS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/competitors.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/feasibility.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/assets/THREE-LICENSE.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/design-tokens.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/example-approved-scene.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/flow-states.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/screen-boards.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/import-review/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-parts.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/barrier.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/canopy-tent.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/catalog.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/commands.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/finish-arch.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/gate.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/generator.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/instances.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/sign.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/sponsor-booth.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/stage.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/toilet-block.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/examples/water-table.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/kit.schema.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/requirements.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/parametric-schema/validation-report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/segments.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/event-sitemap-ai-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/experience-v1/IMAGE-PROMPTS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/experience-v1/WorldEngine-Experience-Spec-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/experience-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/experience-v1/night-sky-reference.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/experience-v1/showcase-presets.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/albedo-correction-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/revision-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/SUPERSEDED.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/revision-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/superseded/pre-albedo-fix-2026-10-08/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/coverage.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/revision-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/facade-detail-v2b/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/fog-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/fog-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-atlanta.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-austin.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-boston.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-chicago.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-dc.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-denver.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-la.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-miami.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-nyc.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-phoenix.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-seattle.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/city-sf.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/foliage-values.json` | Partial, bounded web consumption: species/season fallback via applySpecies; native regional data retains precedence; visual acceptance unknown. A8 mock-content audit §5. | `web/bakeoff/serve.mjs` pack mount → `web/bakeoff/main.js` fetch/render consumers (355c6fb, saved evidence 4127a32); no whole-pack acceptance |
| `docs/proposals/foliage-seasons-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/planting-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/planting-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/planting-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/planting-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/planting-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-acer_macrophyllum.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-acer_platanoides.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-acer_rubrum.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-acer_saccharinum.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-acer_saccharum.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-fraxinus_pennsylvanica.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-ginkgo_biloba.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-gleditsia_triacanthos.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-lagerstroemia_indica.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-magnolia_grandiflora.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-malus_ornamental.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-parkinsonia_florida.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-phoenix_dactylifera.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-picea_pungens.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-pinus_ponderosa.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-platanus_x_acerifolia.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-populus_deltoides.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-populus_tremuloides.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-prosopis_velutina.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-prunus_serrulata.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-pseudotsuga_menziesii.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-pyrus_calleryana_bradford.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-quercus_palustris.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-quercus_virginiana.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-roystonea_regia.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-sabal_palmetto.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-syagrus_romanzoffiana.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-thuja_plicata.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-tilia_cordata.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-ulmus_americana.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-washingtonia_robusta.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/species-zelkova_serrata.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-07.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/trees-08.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/foliage-seasons-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/checks/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/01-mill-cottage.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/02-bungalow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/03-brick-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/04-craftsman.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/05-infill-townhouse.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/06-mixed-use.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/07-downtown.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/08-north-main.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/09-augusta-road.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/10-mill-village.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/11-block-base.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/12-piedmont.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/13-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/14-summer-storm.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/15-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sheets/16-seasonal-lawns.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/greenville-sc-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ground-v1/ADDENDUM-Brick-Streets-and-Stone-Paving.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ground-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ground-v1/addendum-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ground-v1/ground-colours.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/ground-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/haze-visibility-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/haze-visibility-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/haze-visibility-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/archetypes-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-01-bungalow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-02-flats.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-03-cottage.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-04-foursquare.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-05-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/chicago-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-01-square.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-02-bungalow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-03-minimal.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-04-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-05-split.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-06-infill.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/denver-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-01-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-02-mediterranean.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-03-cottage.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-04-mimo.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-05-suburban.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v1/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/archetypes-values-v2.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/la-01-spanish.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/la-02-craftsman.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/la-03-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/la-04-dingbat.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/la-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/nyc-01-brownstone.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/nyc-02-tenement.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/nyc-03-queens.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/nyc-04-midrise.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/nyc-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/phoenix-01-ranch.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/phoenix-02-parapet.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/phoenix-03-tile.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/phoenix-04-lowgable.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/phoenix-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/seattle-01-craftsman.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/seattle-02-tudor.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/seattle-03-rambler.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/seattle-04-townhouse.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-archetypes-v2/seattle-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/README.pre-hero.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/draft-before-paintovers/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/draft-before-paintovers/minimum-detail.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/draft-before-paintovers/paintover-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/hero-image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/hero-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/image-prompts.pre-hero.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/index.pre-hero.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/lighting-conflicts.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/manifest.pre-hero.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/minimum-detail.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/paintover-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-contrast-v1/paintover-values.pre-hero.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-details-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-details-v1/house-details-colours.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-details-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-details-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/house-details-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-01-runway.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-02-taxiway.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-03-apron.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-04-terminal.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-05-tower.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/airports-06-hangar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-01-bascule.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-02-truss.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-03-girder.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-04-cable.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-05-suspension.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/bridges-06-pedestrian.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/infrastructure-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-01-golf.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-02-sports.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-03-cemetery.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-04-parking-large.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-05-parking-small.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-06-stadium-parking.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-07-park.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/land-08-open-land.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/rail-01-elevated.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/rail-02-commuter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/rail-03-light.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/rail-04-yard.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/rail-05-station.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-01-highway.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-02-ramps.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-03-overpass.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-04-soundwall.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-05-arterial.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-06-residential.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-07-alley.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-08-markings.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/roads-09-crosswalks.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-01-lines.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-02-transmission.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-03-substation.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-04-water-tower.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-05-cell-tower.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-06-wind.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/utility-07-solar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-01-harbor.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-02-marina.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-03-pier.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-04-riverwall.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-05-lock.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-06-canal.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/infrastructure-kit-v1/water-07-seawall.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/infrastructure-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/other-01-parking.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/other-02-utilities.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/roads-01-expressway.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/roads-02-mountain.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/roads-03-paddy.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/transit-01-crossing.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/transit-02-stops.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/transit-03-plaza.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/water-01-river.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/water-02-bridges.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/water-03-coast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-infrastructure-kit-v1/water-04-port.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/01-seasonal-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/02-garden-plants.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/03-regional-landscape.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/04-yards-edges.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/05-vehicles.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/06-rail-vehicles.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/07-track-types.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/08-stations.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/09-street-furniture.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-regional-kit-v1/regional-kit-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/archetypes-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/japan-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-01-wooden.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-02-concrete.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-03-mansion.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-04-shop-house.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-05-machiya.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-06-gate.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-07-corner.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/jp-08-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/scenes-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/seasons-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/street-character-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/SUPERSEDED.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/archetypes-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/japan-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-01-wooden.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-02-concrete.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-03-mansion.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-04-shop-house.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-05-machiya.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-06-gate.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-07-corner.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/jp-08-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/scenes-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/seasons-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/street-character-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/superseded/r1-us-scale/variant-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/japan-style-b-v1/variant-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/lake-winter-values.json` | Partial, bounded web consumption: selected water profiles, wind/state/shore and policy inputs; visual acceptance unknown. A8 mock-content audit §5. | `web/bakeoff/serve.mjs` pack mount → `web/bakeoff/main.js` fetch/render consumers (355c6fb, saved evidence 4127a32); no whole-pack acceptance |
| `docs/proposals/lake-winter-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/lake-winter-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM001.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM002.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM007.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM011.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM012.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM018.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM019.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-LM020.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/chicago-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM-DEN-STADIUM.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM021.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM023.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM024.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM026.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM027.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM028.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM029.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-LM031.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/denver-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-board-v4-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-looks-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-originals-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-rich-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-style-b-v4-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-b-revision-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-originals-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-looks-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-originals-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-rich-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-v3-concept/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/style-c-illustrated/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-expansion-pre-strict-style-b/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM001.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM002.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM007.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM011.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM012.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM018.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM019.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-LM020.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/chicago-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM-DEN-STADIUM.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM021.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM023.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM024.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM026.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM027.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM028.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM029.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-LM031.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/denver-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/style-b-revision-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-originals-pre-strict-style-b/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM001.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM002.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM007.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM011.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM012.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM018.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM019.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-LM020.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/chicago-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM-DEN-STADIUM.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM021.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM023.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM024.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM026.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM027.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM028.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM029.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-LM031.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/denver-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-originals-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/style-b-revision-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-rich-style-b-v3/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM001.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM002.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM007.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM011.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM012.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM018.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM019.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-LM020.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/chicago-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM-DEN-STADIUM.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM021.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM023.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM024.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM026.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM027.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM028.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM029.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-LM031.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/denver-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM033.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM034.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM035.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM039.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM040.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM042.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM043.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-LM044.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-brickell-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-brickell.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-looks-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-originals-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-rich-style-b-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-south-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-stadium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/miami-wynwood.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/style-b-revision-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/superseded/miami-pre-style-b-v4/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/atlanta-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/austin-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/boston-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/correction-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/dallas-fort-worth-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/houston-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/landmarks-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/los-angeles-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/nashville-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/new-york-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/philadelphia-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/phoenix-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/san-francisco-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/seattle-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/source-audit.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-style-b-v2/washington-dc-skyline.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/landmarks-colours.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/landmarks-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/assets/style-b-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/assets/weather-snapshot.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/configure.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/event.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/explorer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/listing.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/phone-check/downloaded-mock-config.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/phone-check/integrity.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/phone-check/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/research.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/licensing-demo-v1/story.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/airport-audit.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/airport-gates.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/cost-estimate.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/providers.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-flights-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-world-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-world-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/live-world-v1/live-style.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/PROMPT-LOG.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/VALIDATION.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/lighting-fixtures.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/look-fix-v1/sky-projection-reference.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mascots-v1/README-first-pass.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mascots-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mascots-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mascots-v1/index-first-pass.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mascots-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/CHANGES-2026-10-07.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/RESEARCH-INDEX.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/UPDATE-RULES.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/coverage-by-country-Cities.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/coverage-by-country-Countries.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/coverage-by-country-Data-sources.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/monuments-tracker-Summary.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/monuments-tracker.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/snapshots/2026-10-07-before-landmarks-style-b-v2/monuments-tracker-Summary.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/snapshots/2026-10-07-before-landmarks-style-b-v2/monuments-tracker.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/snapshots/2026-10-08-before-filing-pass/coverage-by-country-Cities.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/master-trackers-v1/snapshots/2026-10-08-before-filing-pass/coverage-by-country-Countries.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/block-mix-gallery.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/block-mix-notes.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/block-mix-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/datasets.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/metros.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/metro-onboarding-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/checks/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/research.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-01-terrace.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-02-federation.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-03-weatherboard.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-04-brick-walkup.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-05-infill.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-06-sydney-terraces.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-07-sydney-suburb.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-08-melbourne.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-09-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-10-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-11-seasons.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-12-furniture.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-13-signals.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-14-transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-15-weather.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/au-16-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-01-courtyard.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-02-art-deco.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-03-modern-midrise.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-04-tapatio-house.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-05-guadalajara-infill.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-06-roma-condesa.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-07-coyoacan.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-08-guadalajara.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-09-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-10-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-11-seasons.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-12-furniture.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-13-signals.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-14-transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-15-weather.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/sheets/mx-16-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mexico-australia-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/01-front-range-spring-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/01-front-range-spring-v1-original.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/01-front-range-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/02-front-range-summer-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/02-front-range-summer-v1-original.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/02-front-range-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/03-front-range-autumn-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/03-front-range-autumn-v1-original.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/03-front-range-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/04-front-range-winter-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/04-front-range-winter-v1-original.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/04-front-range-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/05-foothills-town.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/06-canyon-road.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/07-ski-area-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/07-ski-area-v1-original.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/07-ski-area.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/08-elevation-transition.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/09-mountain-lake.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/10-distant-horizon.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/11-foothills-trail.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/12-forest-trail.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/13-aspen-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/14-aspen-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/15-alpine-trail.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/16-creek-crossing.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/17-trail-switchbacks.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/18-trailhead.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/19-trail-states.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/20-trail-race-overlay.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/README-v1-superseded.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/active-sheets.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/image-manifest-v1-superseded.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/index-v1-superseded.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/phone-check/report-r2.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/prompts-v1-superseded.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/research-v1-superseded.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/sources-v1-superseded.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/supersession.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/trails-research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/values-v1-superseded.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/mountain-terrain-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/competitive-scan.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/concepts.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/concept.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/job-catalogue.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/job-catalogue.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/phone-check/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/privacy.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/prototype-90-days.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/07.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/08.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/09.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/10.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/11.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/12.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/13.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/screens/14.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/jobs-game/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/phone-check/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/privacy-and-ux.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/prototype-90-days.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/07.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/08.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/09.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/screens/10.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/neighborhood-product-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/FILE-LIST.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/crop-jobs.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/crop-preview.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/netherlands-style-b-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/night-fog-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-fog-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/night-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/night-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/boards/archetypes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/boards/bridges-water.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/boards/districts.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/boards/infrastructure.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/boards/light.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/checks/layout-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/generation-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/01-brooklyn-brownstone.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/02-uws-prewar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/03-tenement-fire-escape.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/04-queens-rowhouse.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/05-bronx-deco.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/06-glass-podium.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/07-soho-cast-iron.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/08-park-slope.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/09-upper-west-side.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/10-east-village.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/11-soho.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/12-midtown-canyon.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/13-astoria.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/14-financial-district.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/15-street-surfaces.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/16-elevated-transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/17-stone-suspension.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/18-steel-suspension.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/19-cantilever.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/20-east-river-esplanade.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/21-hudson-piers.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/22-midday-shadow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/23-manhattanhenge.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/24-winter-low-sun.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/25-rainy-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sheets/26-snow-stoops.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-hero-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/rhythms.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/shops.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/vehicles.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/vendors.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/waterfront.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/boards/workers.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/checks/data-and-links.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/checks/layout-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/generation-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/01-pizza-slice.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/02-bodega.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/03-laundromat.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/04-newsstand.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/05-diner.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/06-chinatown-produce.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/07-food-cart.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/08-hot-dog-cart.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/09-fruit-stand.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/10-christmas-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/11-mail-carrier.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/12-delivery-ebikes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/13-sanitation.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/14-doorman.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/15-construction.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/16-yellow-taxi.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/17-city-bus.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/18-box-trucks.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/19-ice-cream-truck.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/20-fire-engine.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/21-ambulance.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/22-horse-carriage.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/23-pedicab.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/24-trash-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/25-morning-commute.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/26-lunch-queues.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/27-stoop-evening.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/28-street-sweeper.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/29-snow-plow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/30-window-ac.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/31-commuter-ferry.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sheets/32-rowboats.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/nyc-life-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/paintover-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/paintover-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/README.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/created-files.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/prompt-log.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/sources.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/postcards-widgets-v1/validation-report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/builder-workflow.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/checklists.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/chicago-layout.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/denver-layout.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/greenville-layout.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/layouts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/look-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/rules.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/rules.schema.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/sources.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/race-organizer-ops-v1/validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/rain-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/rain-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/01-chicago.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/02-denver.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/03-greenville-sc.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/04-nyc.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/05-sf.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/06-miami.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/07-canada.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/08-uk.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/09-netherlands.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/10-mexico.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/11-australia.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/12-japan.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/13-weather-states.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regional-car-mix-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/IMAGE-PROMPTS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/WorldEngine-Regions-Chicagoland-Miami-Spec-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/fixtures.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/generation-log.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profile-evidence.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/chicago-bungalow-belt.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/chicago-dense-north.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/chicago-downtown.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/chicago-greystone-twoflat.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/chicago-south-historic.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/coral-gables.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/evanston.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/kenilworth.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/miami-shores.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/wilmette.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/profiles/winnetka.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/region-catalog.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/regions-draft.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/semantic-validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/sources.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-chicagoland-miami/validation-report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profile-evidence.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/coral-gables.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/edgewater.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/evanston.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/kenilworth.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/lincoln-square.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/miami-shores.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/rogers-park.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/wilmette.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/profiles/winnetka.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-northshore-chicago-miami/regions-draft.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-v1/WorldEngine-Regional-Profiles-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-v1/images/image-generation-record.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/regions-v1/regions-draft.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/australia.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/canada.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/japan.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/mexico.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/netherlands.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/road-signs-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/uk.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/us.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/road-signs-signals-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/australia-summer-christmas.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-halloween.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-harvest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-july4.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-lights.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-newyear.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-school.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/chicago-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/correction-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-halloween.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-harvest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-july4.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-lights.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-newyear.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-school.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/denver-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-halloween.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-harvest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-july4.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-lights.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-newyear.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-school.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/greenville-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/japan-hanami.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/jobs.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/mexico-muertos.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nl-kingsday.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-halloween.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-harvest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-july4.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-lights.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-newyear.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-school.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/nyc-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/pdf-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/phone-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-autumn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-halloween.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-harvest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-july4.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-lights.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-newyear.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-school.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-snow.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-spring.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sf-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/seasonal-holiday-life-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/01-cable-car.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/01-transit.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/02-tech-city.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/02-trolleybus.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/03-historic-streetcar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/03-shops-food.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/04-commuter-ferry.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/04-workers.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/05-hills.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/05-robotaxi.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/06-tech-shuttle.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/06-water-fog.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/07-shared-scooters.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/08-hill-cyclists.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/09-mission-taqueria.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/10-corner-store.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/11-cafe-parklet.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/12-chinatown-lanterns.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/13-waterfront-market.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/14-mail-carrier.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/15-delivery-riders.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/16-turntable-crew.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/17-curbed-wheels.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/18-angled-hill-parking.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/19-stair-street.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/20-bay-traffic.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/21-sea-lion-dock.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/22-fog-horn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/sf-life-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sf-life-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/revision-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/superseded/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-cloud-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-seasons-v1/WorldEngine-Sky-Seasons-Spec-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/sky-seasons-v1/sky-seasons-fixtures.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/panels/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-ground-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/WORLDENGINE-MOCK-RULES.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/SUPERSEDED.txt` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/superseded/v1-before-strict-style-b/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/street-to-space-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/STYLE-B-RULE.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/bible-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/realism-levels/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/realism-levels/comparison-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/realism-levels/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/realism-levels/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-matte-candidate-2026-10-07/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-matte-candidate-2026-10-07/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/STYLE-B-RULE.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/SUPERSEDED.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/bible-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-bible-v1/superseded-photoreal-2026-10-07/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/phone-check/source-integrity.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/phone-check/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/07.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sheets/08.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/source-selection.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/01-lakeview.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/02-brooklyn.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/03-midtown.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/04-san-francisco.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/05-alley.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/05-train.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/06-sloans.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/07-new-orleans.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/sources/08-miami.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/style-b-calibration-v2/values.json` | Partial, bounded web consumption: shared look/policy, materials, lighting and AO floor; visual acceptance unknown. A8 mock-content audit §5. | `web/bakeoff/serve.mjs` pack mount → `web/bakeoff/main.js` fetch/render consumers (355c6fb, saved evidence 4127a32); no whole-pack acceptance |
| `docs/proposals/terrain-slope-v1/01-gentle.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/02-moderate.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/03-steep.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/04-corner.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/05-stair-street.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/06-retaining.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/07-canyon.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/phone-check/report.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/terrain-slope-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/checks/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/research.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-01-victorian.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-02-georgian.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-03-council.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-04-docklands.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-05-semi.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-06-mill.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-07-worker-terrace.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-08-tenement.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-09-new-town.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-10-bloomsbury.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-11-islington.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-12-docklands.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-13-ancoats.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-14-manchester-terraces.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-15-edinburgh.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-16-london-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-17-edinburgh-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-18-bus-cab.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-19-underground.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-20-crossing.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-21-furniture.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-22-trees.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-23-seasons.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-24-drizzle.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-25-fog.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-26-frost.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-27-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/sheets/uk-28-night.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/uk-style-b-v1/values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/README-before-sf-r2.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-block-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-board-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-01-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-02-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-03-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-04-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/atlanta-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-block-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-board-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-01-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-02-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-03-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-04-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/austin-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/boston-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-block-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-board-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-01-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-02-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-03-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-04-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/dallas-fort-worth-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-block-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-board-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-01-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-02-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-03-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-04-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/houston-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/index-before-sf-r2.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/index-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/metro-values-before-sf-r2.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/metro-values-superseded-v1.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/metro-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-block-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-board-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-01-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-02-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-03-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-04-superseded-v1.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/nashville-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/philadelphia-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/prompts-before-sf-r2.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/prompts-superseded-v1.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-bridge-silhouettes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-cable-car.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-district-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-district-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-fog-advection.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-fog-offshore-sunset.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-house-06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-june-gloom.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-steep-geometry.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-streetcar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/sf-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf-r2/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/SUPERSEDED.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-bridge-silhouettes.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-cable-car.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-district-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-district-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-05.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-house-06.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-marine-layer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-steep-geometry.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-streetcar.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-surface-fog.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/sf-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/sf/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/verification-v2.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave2-v1/washington-dc-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/charlotte-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/detroit-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/kansas-city-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/las-vegas-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/metro-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/minneapolis-st-paul-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/new-orleans-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/orlando-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/portland-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/salt-lake-city-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/san-diego-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/st-louis-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-block.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-board.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-district-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-district-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-house-01.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-house-02.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-house-03.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-metros-wave3-v1/tampa-house-04.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/01-desert-southwest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/02-pacific-northwest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/03-california-coast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/04-rocky-front-range.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/05-great-plains.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/06-midwest.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/07-southeast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/08-florida.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/09-northeast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/10-gulf-coast.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/correction-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/land-cover-seasonal-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/landscapes-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/layout-check.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/us-regional-landscapes-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/vegetation-v1/ADDENDUM-Weeping-Willow.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/vegetation-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/vegetation-v1/addendum-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/vegetation-v1/image-prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/vegetation-v1/vegetation-colours.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/campus-01-quad.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/campus-02-urban.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/campus-03-state.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/catalog.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-01-fairgrounds.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-02-festival.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-03-marathon.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-04-race-village.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-05-market.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/event-06-beach.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-01-open.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-02-roof.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-03-classic.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-04-modern.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-05-college.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/stadium-06-soccer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/venue-01-amphitheatre.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/venue-02-arena.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/venues-campuses-v1/venues-campus-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v1/WorldEngine-Visual-Spec-Proposal-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v1/images-original/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v2/IMAGE-PROMPTS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v2/comparison-presets.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v2/data-grounding.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/visual-v2/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/beach-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/beach-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/canal-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/canal-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/marina-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/marina-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/marsh-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/marsh-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/miami-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/miami-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/michigan-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/michigan-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/nyc-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/nyc-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/research.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/riprap-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/riprap-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/river-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/river-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/seawall-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/seawall-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/sf-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/sf-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/sloan-summer.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/sloan-winter.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/sources.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/water-surfaces-v1/water-values.json` | Partial, bounded web consumption: selected water mechanics and current reflection fields; consumption does not approve fields excluded by mechanics-only STATUS; visual acceptance unknown. A8 mock-content audit §5. | `web/bakeoff/serve.mjs` pack mount → `web/bakeoff/main.js` fetch/render consumers (355c6fb, saved evidence 4127a32); no whole-pack acceptance |
| `docs/proposals/weather-block-design-v1/PRODUCT-LOGIC.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/VALIDATION.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/design-values.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-block-design-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/README.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/STATUS.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/image-manifest.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/nyc-verification.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/prompts.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-moments-v1/values.json` | Partial, bounded web consumption: inherited sky gradient elevations via createSkyTexture; not all weather moments or superseded haze; visual acceptance unknown. A8 mock-content audit §5. | `web/bakeoff/serve.mjs` pack mount → `web/bakeoff/main.js` fetch/render consumers (355c6fb, saved evidence 4127a32); no whole-pack acceptance |
| `docs/proposals/weather-moments-v1/verification.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-v1/WorldEngine-Weather-Spec-v1.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/proposals/weather-v1/weather-fixtures.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/repo-size.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/app-ideas/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/app-ideas/ideas.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/building-heights-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/building-heights-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/building-heights-v1/sources.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/building-heights-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/country-shortlist-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/country-shortlist-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/country-shortlist-v1/countries.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/country-shortlist-v1/datasets.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/country-shortlist-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1/competitors-as-customers.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/creator-kit-demand-v1/competitors-as-customers.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1/competitors.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/creator-kit-demand-v1/pricing.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/creator-kit-demand-v1/segments.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/creator-kit-demand-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/creator-kit-demand-v1/trust-models.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/data-layers-research-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/data-layers-research-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/data-layers-research-v1/city-portals.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/data-layers-research-v1/layers.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/data-layers-research-v1/maptech.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/data-licence-check-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/data-licence-check-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/data-licence-check-v1/licence-check.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/hyperlocal-weather-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/hyperlocal-weather-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/hyperlocal-weather-v1/competitor-notes.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/hyperlocal-weather-v1/cost-model.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/hyperlocal-weather-v1/sources.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/hyperlocal-weather-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/japan-showcase-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/japan-showcase-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/japan-showcase-v1/datasets.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/japan-showcase-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/landmarks-research-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/landmarks-research-v1/build-effort.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/landmarks-research-v1/campus-scopes.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/landmarks-research-v1/landmarks.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/landmarks-research-v1/verify-first.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/landmarks-research-v1/verify-results.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/live-aircraft-research/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/live-aircraft-research/aircraft-sources.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/live-layers-catalog-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/live-layers-catalog-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/live-layers-catalog-v1/sources.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/live-layers-catalog-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/metro-data-coverage-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/metro-data-coverage-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/metro-data-coverage-v1/metro-data-coverage.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/mobile-rendering-v1/README-followup.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/mobile-rendering-v1/README.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/mobile-rendering-v1/STATUS.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/mobile-rendering-v1/compatibility.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/mobile-rendering-v1/sources.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/mobile-rendering-v1/streaming-design.md` | A8: iOS partial, web partial | `Sources/WorldPackage/AdaptiveTilePacker.swift` |
| `docs/research-gpt/mobile-rendering-v1/techniques.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/osm-licence-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/osm-licence-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/cost-estimate.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/real-flights-path-v1/index.html` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/real-flights-path-v1/permission-email.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/prompts.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/receiver-guide.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/research.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/sources.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/real-flights-path-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/real-flights-path-v1/validation.json` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/regional-look-catalog-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/regional-look-catalog-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/regional-look-catalog-v1/metros.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/regional-look-catalog-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/regional-look-catalog-v1/street-character.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/strategic-research-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/strategic-research-v1/VERIFY-FIRST.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/strategic-research-v1/ws1-differentiation.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/ws2-technology.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/ws3-places.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/ws4-live-layers.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/ws5-natural-world.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/strategic-research-v1/ws6-buyers.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/street-geometry-rules-v1/README.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/street-geometry-rules-v1/STATUS.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/street-geometry-rules-v1/rules.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/street-geometry-rules-v1/sources.md` | A8: iOS partial, web partial | none |
| `docs/research-gpt/street-trees-by-metro-v1/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/street-trees-by-metro-v1/STATUS.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/street-trees-by-metro-v1/inventories.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/street-trees-by-metro-v1/phenology.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/street-trees-by-metro-v1/sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research-gpt/street-trees-by-metro-v1/species-by-metro.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/street-trees-by-metro-v1/species-forms.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/transit-feeds-top20.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/web-stack-v1/README.md` | A8: iOS not started*, web partial | none |
| `docs/research-gpt/web-stack-v1/STATUS.md` | A8: iOS not started*, web partial | none |
| `docs/research-gpt/web-stack-v1/options.csv` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/research-gpt/web-stack-v1/sources.md` | A8: iOS not started*, web partial | none |
| `docs/research/README.md` | A8: iOS not started*, web not started* | none |
| `docs/research/aerial.md` | A8: iOS not started*, web not started* | none |
| `docs/research/ambient-planes.md` | A8: iOS not started*, web not started* | none |
| `docs/research/builder-mvp-v1.md` | A8: iOS not started*, web not started* | none |
| `docs/research/country-readiness-v1.md` | A8: iOS not started*, web not started* | none |
| `docs/research/data-coverage.md` | A8: iOS partial, web partial | `Sources/WorldGen/WorldBuild.swift`; `Sources/WorldGen/BuildingGenerator.swift` |
| `docs/research/door-sources.md` | A8: iOS not started*, web not started* | none |
| `docs/research/foliage-exp1-spec.md` | A8: iOS not started*, web not started* | none |
| `docs/research/foliage-rendering-v1.md` | A8: iOS not started*, web not started* | none |
| `docs/research/height-reference-v1.md` | A8: iOS not started*, web not started* | none |
| `docs/research/licensing.md` | A8: iOS partial, web partial | none |
| `docs/research/lidar-roofs.md` | A8: iOS not started*, web not started* | none |
| `docs/research/live-feeds.md` | A8: iOS not started*, web not started* | none |
| `docs/research/map-confidence.md` | A8: iOS not started*, web not started* | none |
| `docs/research/nj-front-walk-point.md` | A8: iOS not started*, web not started* | none |
| `docs/research/overture-source.md` | A8: iOS integrated, web integrated | `Sources/WorldMap/AreaManifest.swift`; `Sources/WorldMap/OvertureSource.swift`; `Sources/WorldGen/WorldBuild.swift`; `web/src/world.js` |
| `docs/research/region-kit.md` | A8: iOS partial, web partial | `Sources/WorldGen/WorldBuild.swift` |
| `docs/research/snow-history.md` | A8: iOS not started*, web not started* | none |
| `docs/review/integration-audit-2026-10-08.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/review/verifier-2026-10-08.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/review/verifier-2026-10-08b.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/review/verifier-2026-10-08c.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/roadmap.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/runbooks/add-a-city.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/style-profiles.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tooling/a7-scoring-and-push-guard.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/A2-RULES.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/a1-data.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/handoffs.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/lane-reviews.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/look-gate.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/restart-5A.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/restart-P2.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/roadmap.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/storage-report.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/web-ios-parity.md` | A8: iOS partial existing baseline; proposed batches not started*, web partial existing baseline; proposed batches not started* | none |
| `docs/tracking/weekend-brief.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/zips-for-r.md` | File-specific consumer untraced; see pack/feature row where applicable | none |
| `docs/tracking/SOURCE-OF-TRUTH.md` | Operational documentation; no renderer consumer | none |
| `docs/tracking/STATE.md` | Operational documentation; no renderer consumer | none |
| `docs/tracking/INTEGRATION.md` | Operational documentation; no renderer consumer | none |
| `docs/tracking/MOCKS.md` | Operational documentation; no renderer consumer | none |
| `docs/lookloop/GRADING.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/README.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/evidence.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/lakeview-postcard-afternoon.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/lakeview-street-afternoon.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/measurements.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/ordinary-street-afternoon.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/signals.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-baseline/wilmette-street-afternoon.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/a3-capture-contract.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/calibration-baseline.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/calibration-baseline.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/calibration-scores.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/calibration.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/colour-prescreen-fit.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/daytime-master-changes.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/form-coverage-other.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/form-coverage-vegetation.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/form-coverage.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/generalization-panel.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/latest/grades.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/latest/regressions.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/latest/run.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/latest/summary.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/mock-conflicts.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/mock-coverage.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/mock-exceptions.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/paintover-input/README.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/scoreboard.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-4127a32.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-4127a32/grades.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-4127a32/holdout-proof.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-5c72bad.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-5c72bad/fixture.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-5c72bad/grades.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-5c72bad/holdout-proof.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-baseline.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-baseline/fixture.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-baseline/grades.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-baseline/holdout-proof.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/web-baseline/scenes.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/west-highland-capture-contract.json` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/lookloop/west-highland-holdout.md` | File-specific consumer untraced; capture/score files are evidence, not implementation | none |
| `docs/review/a4-streaming-review-2026-10-08.md` | Later A8 branch review `4cff16b`; upload FAIL and buffer-lifetime concerns, not implemented fixes | none |

## Execution brief inventory — A8 audit follow-up

| Input | Status / scope | Consumed by |
|---|---|---|
| [docs/execution/water.md](../execution/water.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/ground.md](../execution/ground.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/ao.md](../execution/ao.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/sky.md](../execution/sky.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/shadows.md](../execution/shadows.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/haze.md](../execution/haze.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
| [docs/execution/facades.md](../execution/facades.md) | Spec-only; proposed change not started; older mechanisms do not prove this brief delivered | none |
