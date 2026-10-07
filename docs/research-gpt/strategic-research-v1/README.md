# WorldEngine strategic + data research v1

Research snapshot: October 7, 2026. Analysis and planning only; no engine changes, data ingestion, accounts, purchases or git operations.

## Executive judgment

Build a dependable **local-world compiler and runtime**, not a competing satellite globe. A compiler turns source data into a reproducible world package—for example the same Chicago footprints become consistent building meshes, identifiers and app interaction surfaces. The commercially useful combination is recognizable rich-stylized places, bounded phone cost, explicit observed-versus-inferred geometry, persistent semantic identities, and reusable app/export workflows. None of those components alone is a defensible novelty claim. Google, Mapbox, Cesium/Bentley, Esri, Blackshark and weather vendors already cover significant portions of this territory; see [the competitive evidence](ws1-differentiation.csv) and [Weather Company's existing 3D city/sky products](https://www.weathercompany.com/media/).

The 2–3-year moat should be validated generation and refresh operations, performance engineering, a recognizable regional art grammar, curated exceptions and customer workflow integration. It should **not** be exclusive ownership of OSM-derived city data. The repo's existing licensing decision treats generated package data as an ODbL derivative database and keeps proprietary engine code separate. ODbL is a database share-alike licence: publicly using a modified OSM database creates obligations concerning the derivative database, not automatically the renderer's source code. Obtain legal confirmation for each mixed-source product before public delivery. [ODbL text](https://opendatacommons.org/licenses/odbl/1-0/), [Overture theme/source attribution](https://docs.overturemaps.org/attribution/).

Start with Chicago/Denver reliability, a Miami coastal/terrain pilot and **one paid workflow experiment**. Do not make all twenty metros, every live feed, broadcast integration, WebGPU and AI world generation simultaneous launch dependencies. A WebGPU renderer uses a browser GPU interface; it is not a drop-in RealityKit renderer. Likewise, a live feed refreshing every thirty seconds does not prove its positions are thirty seconds old. [three.js WebGPURenderer](https://threejs.org/docs/pages/WebGPURenderer.html), [Metrolink documentation](https://metrolinktrains.com/about/gtfs/gtfs-rt-access/).

## What is in this folder

| File | Scope |
| --- | --- |
| [ws1-differentiation.csv](ws1-differentiation.csv) | 18 competitor/product comparisons and 10 ranked differentiators |
| [ws2-technology.csv](ws2-technology.csv) | 29 standards/techniques, maturity, licences, effort estimates and recommendations |
| [ws3-places.csv](ws3-places.csv) | Agency/source inventory, Census metro reference, 20 proposed places in each of 11 categories—220 places total—plus legal/ranking methods |
| [ws4-live-layers.csv](ws4-live-layers.csv) | 28 source rows, twenty-metro transit coverage matrix, scoring method and one supplementary metro |
| [ws5-natural-world.csv](ws5-natural-world.csv) | US/global terrain, hydrography, land cover, trails and shorelines; phone-scale rendering recommendations |
| [ws6-buyers.csv](ws6-buyers.csv) | Seven buyer segments, published competitor price anchors, uncertain enterprise pricing and three proposed paid pilots |
| [VERIFY-FIRST.md](VERIFY-FIRST.md) | Fifteen human checks that should precede consequential integration, commercial or accuracy claims |

Every CSV uses the same 24 columns. `source_urls` contains primary URLs separated by semicolons or pipes. `unclear` means the claim was not established, not that permission is granted or a feature is absent. `not applicable` is distinct from missing evidence. `evidence_status` distinguishes provider statements, analytical recommendations, proposed rankings and access limitations. Planning effort is not a measured delivery quote. Prices retain original currencies, exclude unspecified taxes/hardware/implementation, and must be reconfirmed before procurement.

## Top 15 recommendations: impact versus effort

Scores are our judgment, not experimental measurements: impact 1–5, effort 1–5 (5 = greatest). Ordering balances upside, dependencies and downside avoidance rather than using a spurious precise ROI calculation. Work estimates assume an experienced small team and exclude source licensing delays.

| Rank | Recommendation | Impact / effort | Why / evidence |
| --- | --- | --- | --- |
| 1 | Finish the source-rights and public derivative-data offer before selling/exporting city packs. Keep live overlays separately licensed. | 5 / 2 | Removes a product-level blocker; repository policy already selects ODbL package separation. [ODbL](https://opendatacommons.org/licenses/odbl/1-0/), [Overture attribution](https://docs.overturemaps.org/attribution/) |
| 2 | Publish repeatable minimum-iPhone performance gates: frame-time percentiles, thermal soak, peak memory, cold start and chunk upload stalls. | 5 / 3 | Sixty fps allows roughly 16.7 ms for the whole frame; the repo's narrower rendering budget is not the total system budget. Measure rather than infer from a demo. [RealityKit LowLevelMesh](https://developer.apple.com/documentation/realitykit/lowlevelmesh) |
| 3 | Add per-feature source date, source ID, observed/inferred status and release pinning. | 5 / 2 | A realistic-looking procedural roof must not become a surveyed roof. [GERS identifiers](https://docs.overturemaps.org/gers/), [STAC metadata](https://stacspec.org/en/) |
| 4 | Make metric coordinates and vertical datums a first-class contract before Miami. | 5 / 3 | A datum is a height/position reference; mixing an ellipsoid height with a tide-gauge sea level can misplace coastlines. [PROJ transformation documentation](https://proj.org/en/stable/usage/transformation.html), [NOAA CO-OPS API](https://api.tidesandcurrents.noaa.gov/api/dev) |
| 5 | Ship bounded streaming, three useful LODs and offline-first packages; preserve a renderer-neutral semantic source. | 5 / 3 | LOD means level of detail: nearby roofs can have shape while distant blocks use simpler meshes. Adapt standards' ideas without forcing a full native 3D Tiles implementation now. [3D Tiles standard](https://docs.ogc.org/cs/22-025r4/22-025r4.html) |
| 6 | Test one paid course-preview or district-embed pilot before broad licensing claims. | 4 / 2 | Established map/event products provide price anchors, not proof customers will buy WorldEngine. [Racemap pricing](https://go.racemap.com/pricing), [Mapme pricing](https://mapme.com/pricing/) |
| 7 | Use freshness-aware federal overlays first: weather, tides/water and earthquakes; label forecast versus observation. | 4 / 2 | Low acquisition cost and explicit timestamps; do not represent illustrative water height or weather as hazard guidance. [NWS API](https://www.weather.gov/documentation/services-web-api), [USGS earthquake feeds](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php), [NOAA tides](https://api.tidesandcurrents.noaa.gov/api/dev) |
| 8 | Audit CTA/RTD and every new agency's purpose, redistribution, attribution and actual rail coverage before marketing national live transit. | 5 / 3 | Public endpoints do not confer general resale rights; vehicle positions, predictions and schedules are different evidence. [CTA licence](https://www.transitchicago.com/downloads/sch_data/developers_license_agreement.htm), [RTD realtime feeds](https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds) |
| 9 | Prioritize places with stable agency IDs; curate commercial venues rather than invent a comprehensive open national directory. | 4 / 2 | FAA, IPEDS and CMS have defined universes; malls and convention centers need a steward/contract and deduplication. [FAA NASR](https://www.faa.gov/air_traffic/flight_info/aeronav/aero_data/NASR_Subscription/), [IPEDS downloads](https://nces.ed.gov/ipeds/use-the-data/download-access-database), [CMS hospitals](https://data.cms.gov/provider-data/dataset/xubh-q36u) |
| 10 | Combine 3DEP bare-earth terrain with explicit water polygons/shorelines and hydrography; do not confuse elevation surface types. | 4 / 3 | A DSM includes canopy/buildings; a bare-earth DTM does not. Use the suitable surface for each task. [USGS 3DEP](https://www.usgs.gov/3d-elevation-program), [3DHP](https://www.usgs.gov/3d-hydrography-program) |
| 11 | Build the web parity slice around one existing city package; benchmark meshopt and texture formats separately for native and web. | 4 / 3 | Compression helps bandwidth, but documented glTF web support does not prove direct RealityKit decoding. [glTF](https://www.khronos.org/gltf/), [GLTFLoader](https://threejs.org/docs/pages/GLTFLoader.html), [Apple entity loading](https://developer.apple.com/documentation/realitykit/loading-entities-from-a-file) |
| 12 | Attach GERS/agency IDs to regional art and app graphs; persist a crosswalk through rebuilds. | 4 / 3 | IDs are useful join keys, not universal coverage or a guarantee that geometry/semantics never change. [GERS](https://docs.overturemaps.org/gers/) |
| 13 | Introduce AirNow/smoke, bike share and charger overlays only with explicit quality/rights notes and user-visible age. | 3 / 2 | A charger inventory is not real-time occupancy; a smoke model is not a street sensor; GBFS is a format, not one universal feed licence. [AFDC API](https://developer.nlr.gov/docs/transportation/alt-fuel-stations-v1/), [GBFS FAQ](https://www.gbfs.org/documentation/faq/), [AirNow data guidelines](https://docs.airnowapi.org/docs/DataUseGuidelines.pdf) |
| 14 | Prototype source-aware newsroom export, not a wholesale broadcast weather replacement. | 4 / 4 | Incumbents already offer city, sky, radar and editorial workflows; compete on local storytelling/production time. [Weather Company media](https://www.weathercompany.com/media/), [Baron Lynx](https://baronweather.com/baron-lynx-for-broadcast) |
| 15 | Keep Gaussian splats, generative world models and AR as bounded experiments, not geography or launch dependencies. | 3 / 2 for experiments; 5 for production expansion | A capture representation is not a semantic road/door graph; generation is not geographic truth; implementation licences differ from format licences. [Gaussian splatting reference licence](https://github.com/graphdeco-inria/gaussian-splatting/blob/main/LICENSE.md?plain=1), [Genie 3](https://deepmind.google/blog/genie-3-a-new-frontier-for-world-models/), [ARKit geographic anchors](https://developer.apple.com/documentation/arkit/tracking-geographic-locations-in-ar) |

## Suggested six-month sequence

Dates are a proposal from this research snapshot, not a commitment or roadmap edit.

**Month 1, October 2026 — prove the foundation.** Inventory package rights and finish attribution/download offer; pin source manifests and IDs; define coordinate/datum transforms; repeat sustained performance tests on Chicago and Denver. Validate existing transit commercial purpose and feed age. Select one paid pilot prospect. Exit: reproducible packages, documented rights, measured device budget, a buyer-owned use case.

**Month 2, November — smallest weather story.** Add timestamped NWS/approved WeatherKit inputs, forecast/observation labels and explicit stale-feed behavior. Prove a Miami coastline/terrain slice without implying flood depth. Deliver a course-preview or district-embed pilot. Exit: one useful story/export with provenance, bounded resource cost and written customer feedback.

**Month 3, December — web parity and refresh.** Load the same semantic package in three.js; compare web/native materials and identities; test mesh compression rather than blanket-transcoding everything. Add source diffs, bounded rebuilds and rollback. Exit: one paired native/web district, repeatable refresh and traffic/cost measurements.

**Month 4, January 2027 — place-quality expansion.** Add agency-ID-backed priority sites and owner-reviewed venue exceptions; test water/tide/earthquake overlays; expand a small set of metro slices based on source quality and paid demand, not population alone. Exit: measured generation/QA cost per district, documented missing geometry and data ages.

**Month 5, February — one repeatable buyer workflow.** Test branded embeds or newsroom video templates; add contracts for export/display rights, data attribution and refresh service. Add AirNow/GBFS/chargers only after quality/legal checks. Exit: renewal or second paid customer and a demonstrated production-time benefit.

**Month 6, March–early April — decide scale.** Compare revenue, refresh cost and device/web budgets; expand toward twenty metros only if the measured pipeline supports it. Decide full 3D Tiles interchange, AR, or landmark splats from actual partner demand. Exit: explicit go/no-go for national expansion; do not confuse twenty source-covered metros with twenty quality-assured deliverable worlds.

## Important scope and evidence boundaries

### Existing project context

`~/Desktop/world-engine/docs/roadmap.md` was **not present**. Read `docs/design-registry.md`, repository `AGENTS.md`/`CLAUDE.md`, `docs/plan-m1.md` and `docs/data-licensing.md` as the available context. They document rich-stylized generation, deterministic identities, chunk/LOD budgets and the package/code licensing separation. The user reports 60 fps; this research did not independently run or benchmark the app. No repo files were changed.

### Twenty metros and priority-place ranking

The metro reference is the **July 1, 2025 Census MSA population estimates** available at this snapshot, not combined statistical areas or city-proper populations. An MSA is a metropolitan statistical area—for example New York–Newark–Jersey City includes counties across state lines. Riverside is in this top twenty; Charlotte is not. See the exact CBSA identifiers/populations in WS3 and [Census CSV](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/metro/totals/cbsa-est2025-alldata.csv).

The requested top-twenty lists are interpreted as **twenty proposed priority places per category across these twenty metros**, not twenty of every category in every metro (which would be 4,400 entries). These are curator recommendations, not computed national importance rankings. Coverage is uneven and some metros have no shortlisted feature in a particular category. Rural national parks outside the metro universe remain an important separate destination expansion. WS3 supplies agency IDs/ranking methods and 220 source links. Of these, 156 operator URLs fetched successfully and had titles checked; 64 had blocked, timeout, encoding or other unresolved access states, recorded row by row. A cited URL is not a claim that inaccessible page contents were read.

Exact current US counts for several categories remain **unclear** pending processing of the defined datasets; do not replace them with scraped search counts. The verified CMS number is 5,419 dataset rows, not all healthcare campuses. PAD-US's over 436,000 units overlap and are not a count of unique parks; the separate NPS system count is 433 units. WS3 states scopes and exceptions explicitly. [CMS](https://data.cms.gov/provider-data/dataset/xubh-q36u), [PAD-US](https://www.usgs.gov/programs/gap-analysis-project/science/pad-us-data-overview), [NPS units](https://www.nps.gov/aboutus/national-park-system.htm).

### Licence and live-data caution

Format licences and data licences are separate: GBFS/GTFS specify structure, not unrestricted permission for every operator's feed. Federal provenance is not universal public-domain provenance: partner buoy data, linked WZDx feeds and mixed protected-area datasets need their own terms checked. Amtrak's terms restrict automated retrieval and redistribution absent permission; Pollen.com is not a safe default commercial pollen feed. These are acquisition gates, not incidental footnotes. [Amtrak terms](https://www.amtrak.com/web-notices-terms-of-use), [Pollen terms](https://www.pollen.com/help/tou), [WZDx registry](https://data.transportation.gov/Roadways-and-Bridges/Work-Zone-Data-Feed-Registry/69qe-yiui).

### Buyer prices and pilots

Published prices are **anchors**, not proof of WorldEngine demand. Quote-only broadcast, venue, campus and property enterprise prices are left unclear. Cesium's $149/month individual Commercial plan is not an automatic outside-organization resale licence; its pricing page directs such integrations to sales. [Cesium pricing](https://cesium.com/platform/cesium-ion/pricing/).

Three proposed offers in WS6: (1) one-market weather-story pilot, **$9,500 for three months**; (2) neighborhood discovery embed, **$5,300 for three months**; (3) course-preview event, **$2,500/event**. These are testable offers, not observed market prices, and exclude premium rights/tax/extra scope. Treat a paid signature and renewal as evidence; polite interest is not. For comparison, [Mapme](https://mapme.com/pricing/) publishes annual-billing equivalents $30–$110/month across its named non-enterprise tiers; [Racemap](https://go.racemap.com/pricing) publishes €25 per seven-day Map event cycle plus usage/add-ons. Neither includes WorldEngine's proposed deliverables.

## What not to claim yet

No exclusive OSM city-data ownership; no surveyed inferred roofs/interiors/doors; no guaranteed accessible route from map geometry alone; no street-level weather measurement from a regional forecast; no real-time charger occupancy from AFDC; no flood warning from stylized tides; no general transit resale right from a working endpoint; no guaranteed native codec support from a web loader; no customer willingness-to-pay finding without procurement evidence. Open questions are intentionally carried into [VERIFY-FIRST.md](VERIFY-FIRST.md).
