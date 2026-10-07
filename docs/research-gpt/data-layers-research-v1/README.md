# WorldEngine: data layers and map technology — v1
Research checked 7 October 2026. Official/primary sources only. Research was divided among parallel agents for municipal portals, nature/history/water, and map technology, with the remaining layers researched and integrated centrally.

**Recommendation:** build the physical-world foundation first: terrain, hydrography, building massing, licensed place records, park amenities and species-aware seasons. Then add dated station observations and restrained sound. Rural layers score unusually well because their government metadata offers clear reuse rights; that does not make rural fields a higher-priority Chicago downtown feature.

## Files and reading guide

- **layers.csv:** 76 source/layer entries across all eleven requested categories, ranked scores, coverage, update frequency, commercial use, redistribution/cache obligations, attribution, cost, access, size, subtle rendering, app fit, privacy and unresolved claims.
- **maptech.csv:** 19 engineering/service entries, including two explicitly calculated hosting scenarios for 10k/100k/1M monthly active users.
- **city-portals.csv:** 200 entries: ten for each of twenty metros, with official dataset/item URLs and licence declarations.
- **README.md:** this decision guide, top twenty layers, ten tech recommendations, three-month sequence and fifteen verification priorities.

Each CSV row's `source_urls` field supplies the primary citations for factual metadata in that row; dataset and portal links provide more precise provenance in Part C. Semicolons separate URLs. Design proposals, ordinal scores and calculated scenarios are our judgments, not published source claims. “Unclear” means the reviewed primary evidence did not establish the claim; it never means free or permitted. Public viewing, an API, a disclaimer, a file timestamp and a government host do not independently establish commercial redistribution, a refresh promise or all third-party rights.

“Size” means published product/file bytes when stated. ArcGIS hosted-item storage sizes are labelled as such; they are **not** exported ZIP sizes. Reference-item sizes of a few bytes have been rejected as meaningless payload estimates. Local extract sizes, GPU memory, completeness and latency remain unclear where not measured.

## Top twenty layers

Scores are subjective 1–5: **V** visual/experience value, **Q** data quality, **L** licence safety, **E** implementation effort. Higher E means harder. Rank = V × Q × L ÷ E; ties use V, then alphabetical layer name. L=5 is an unusually clear selected-product reuse route, 4 means licence obligations/source exceptions, and 1–2 means permission barriers or unresolved rights. A high score is not rights clearance. Scope is the complete world, including rural fringes/coasts; choose the layers geographically relevant to each launch scene.

|Rank|Layer / primary source|Score calculation|How it appears subtly — design proposal|
|---|---|---|---|
| 1 | [Annual crop type](https://www.nass.usda.gov/Research_and_Science/Cropland/Release/index.php) | 5 × 4 × 5 ÷ 2 = **50** | Crop-specific field palettes and structure |
| 2 | [Seasonal phenology](https://www.usanpn.org/about/terms) | 5 × 4 × 5 ÷ 2 = **50** | Smooth buds, flowering and leaf fullness within species bounds |
| 3 | [Water bodies and streams](https://www.usgs.gov/3d-hydrography-program/access-3dhp-data-products) | 5 × 4 × 5 ÷ 2 = **50** | Real pond/stream edges and coherent drainage |
| 4 | [Terrain and slope](https://www.usgs.gov/3d-elevation-program/about-3dep-products-services) | 5 × 5 × 5 ÷ 3 = **41.67** | Streets/paths sit on real terrain; distant relief uses coarse LOD |
| 5 | [Tides and water levels](https://api.tidesandcurrents.noaa.gov/api/dev) | 5 × 5 × 5 ÷ 3 = **41.67** | Water/beach intersection shifts gently with datum-aligned levels |
| 6 | [Building footprints and heights](https://www.arcgis.com/sharing/rest/content/items/04e5069b4cf843d2bfe15ad0d1c66e00?f=json) | 5 × 4 × 4 ÷ 2 = **40** | Measured massing; neutral fallback geometry |
| 7 | [Business places](https://docs.overturemaps.org/guides/places/) | 5 × 4 × 4 ÷ 2 = **40** | Neutral storefront/place cards from licensed records |
| 8 | [Park amenities](https://data.cityofchicago.org/d/5yyk-qt9y) | 5 × 4 × 4 ÷ 2 = **40** | Real play areas, benches and dog destinations |
| 9 | [Estimated field boundaries and rotations](https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/index.php) | 4 × 4 × 5 ÷ 2 = **40** | Coherent field edges rather than arbitrary rectangles |
| 10 | [Planting and harvest progression](https://www.nass.usda.gov/Surveys/Guide_to_NASS_Surveys/Crop_Progress_and_Condition/) | 4 × 4 × 5 ÷ 2 = **40** | Probabilistic bare→green→golden→stubble regional seasonal progression |
| 11 | [River stage and streamflow](https://api.waterdata.usgs.gov/) | 4 × 4 × 5 ÷ 2 = **40** | River surface height at representative gauge, datum-aligned |
| 12 | [Rip currents and marine forecasts](https://www.weather.gov/documentation/services-web-api) | 3 × 5 × 5 ÷ 2 = **37.5** | Optional officialdated beachcard; mood never contradictwarning |
| 13 | [Sea-surface temperature](https://www.ncei.noaa.gov/products/optimum-interpolation-sst) | 3 × 5 × 5 ÷ 2 = **37.5** | Optional regionalwater-temperature readout |
| 14 | [Buoy waves and temperature](https://www.ndbc.noaa.gov/faq/rt_data_access.shtml) | 5 × 4 × 5 ÷ 3 = **33.33** | Smooth wave energy/period from representative buoy summaries |
| 15 | [Coastal bathymetry](https://www.ncei.noaa.gov/products/coastal-elevation-models) | 5 × 4 × 5 ÷ 3 = **33.33** | Soft depthtint and shallows, artistic not waterquality |
| 16 | [Great Lakes wave forecast](https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/wavemodels.php) | 5 × 4 × 5 ÷ 3 = **33.33** | LakeMichigan wave amplitude/direction follow forecast |
| 17 | [On-demand public-data audio briefs](https://aws.amazon.com/polly/pricing/) | 4 × 4 × 4 ÷ 2 = **32** | Brief grounded in dated public data; cache common regional summaries |
| 18 | [Historical topo](https://www.usgs.gov/programs/national-geospatial-program/topographic-maps) | 4 × 4 × 5 ÷ 3 = **26.67** | Sparse historical roads/water/settlement baseline |
| 19 | [Lake Michigan bathymetry](https://www.ncei.noaa.gov/products/great-lakes-bathymetry) | 4 × 4 × 5 ÷ 3 = **26.67** | Conservative lakebed and shallows colour |
| 20 | [Ocean wave forecast](https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/wavemodels.php) | 4 × 4 × 5 ÷ 3 = **26.67** | Optional forecast-time offshore wave mood |

Species-specific street trees, sidewalks/curbs and bike facilities are strategically valuable despite lower scores caused by unresolved municipal rights or incomplete coverage. Denver's tree inventory covers DPR-managed areas, and its curb-ramp dataset expressly does not establish ADA accessibility. Miami-Dade's sidewalk inventory covers county-maintained roads and dates to 2008–2010 with no updates planned. Treat these as targeted local additions after permission and coverage checks, rather than citywide truth. [Denver trees](https://www.arcgis.com/sharing/rest/content/items/f90e355dd3874744a25c30fd2ddfd45b?f=json), [Denver ramps](https://www.arcgis.com/sharing/rest/content/items/7a286f9cd36f41e382696db4eeffebc2?f=json), [Miami sidewalks](https://www.arcgis.com/sharing/rest/content/items/3b8f8359b0aa4fc08702da57a384d6e9?f=json).

## Representation and product policy

This is a proposed WorldEngine policy:

1. Physical details belong in the default world; statistical context belongs in dated, optional views or restrained hidden simulation priors.
2. No individual people, observers, residents, applicants, voters, anonymous trip trajectories or cast-vote records. Public availability does not change this rule. Strip personal fields before ingest; prefer server-side aggregates. Suppress small cells and sensitive categories in 311/activity products.
3. No demographic/race overlays in consumer apps, no political colouring of everyday neighbourhoods, no stereotypes or reputation labels. Election maps are an explicitly activated TV/news workflow.
4. Keep observed, forecast, historical and simulated states distinct in provenance and UI. Unknown geometry gets a neutral fallback. Unknown conditions do not become invented live events.
5. Show source, observation/valid time and uncertainty in optional detail cards. Keep normal scenes tasteful: small colour changes, modest props, sparse ambience and a few seasonal cues.
6. Rights travel with data: source ID, version, licence, attribution, cache/retention permission, geographic resolution, timestamps and transformation notes. Separate raw-data resale, generated-world licensing and app-user display permissions.

### Census and civic uses

Use aggregate population/household counts as neutral density priors. ACS commute shares can adjust **simulated** pedestrian/car/transit weighting, while housing-age distributions can guide a broad era mix where actual building age is unavailable. B08301 contains transport-to-work estimates and margins of error; B25034 contains housing year-built categories. Annual ACS five-year results are not live hourly crowds or passenger loads. Use actual transit/service data for observed schedules and positions, and label any occupancy-by-hour estimate as a model. [ACS access/geographies](https://www.census.gov/data/developers/data-sets/acs-5year.html), [commute table](https://api.census.gov/data/2024/acs/acs5/groups/B08301.html), [housing-age table](https://api.census.gov/data/2024/acs/acs5/groups/B25034.html).

For B2B, offer opt-in dated tract/block-group statistics for real estate and tourism, and official aggregate election results against matching historical boundaries for TV. The verified MIT county presidential dataset is historical 2000–2024 data under CC0; its version 20 was released in February 2026. It is not an election-night live feed, and its licence cannot be carried over to an unverified precinct dataset. Live election-night delivery needs verified board/feed access, timestamps, unofficial/certified state and correction handling. [MIT catalogue](https://electionlab.mit.edu/data), [county dataset metadata and licence](https://dataverse.harvard.edu/api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/VOQCHQ), [Denver archive](https://www.denvergov.org/Government/Agencies-Departments-Offices/Agencies-Departments-Offices-Directory/Clerk-and-Recorder/Elections-Division/Data-and-Maps?lang_update=638716965197553458), [Miami-Dade results archive](https://www.miamidade.gov/global/elections/election-results-archive.page).

The Census API requires this notice:
> This product uses the Census Bureau Data API but is not endorsed or certified by the Census Bureau.

Also observe its respondent reidentification and source-integrity conditions. Current ACS developer documentation says queries require a key; verify each selected endpoint's registration and limits. [Census API terms](https://www.census.gov/data/developers/about/terms-of-service.html), [ACS developer guidance](https://www.census.gov/data/developers/data-sets/acs-5year.html).

### Rights and realism traps

- **Overture is not one licence.** Buildings and Places have different source/licence paths; Places includes CDLA-Permissive, Apache and CC0 constituents, while Buildings invokes ODbL. Preserve actual release/source notices. OSM data rights are also distinct from OSM public tile-server access. [Overture attribution](https://docs.overturemaps.org/attribution/), [OSM licence](https://www.openstreetmap.org/copyright), [tile policy](https://operations.osmfoundation.org/policies/tiles/).
- **Google cannot be used as a casually copied gap-fill database.** Places policies restrict caching and mapped display; Pollen policies prohibit non-Google-map visualisation under the cited standard policy. Use cleared Overture/OSM/municipal records and merchant-authorised corrections. No official quantitative Chicago/Denver/Miami quality comparison with Google was established. [Places rules](https://developers.google.com/maps/documentation/places/web-service/policies), [Pollen rules](https://developers.google.com/maps/documentation/pollen/policies).
- **Nature platforms need record/product checks.** Raw eBird commercial use requires explicit permission; Status and Trends currently disallows commercial use. iNaturalist defaults are noncommercial, and observation licences differ from media licences. Only aggregate commercially eligible records; preserve sensitive-species restrictions. [eBird terms](https://support.ebird.org/en/support/solutions/articles/48001078113), [Status and Trends FAQ](https://science.ebird.org/eu/atlasva/status-and-trends/faq), [iNaturalist licences](https://help.inaturalist.org/en/support/solutions/articles/151000175695).
- **“Your street in 1950” needs actual dated evidence.** LOC's online Sanborn collection is reusable public-domain material, but later proprietary editions and archival photographs require their own checks. Denver library reproduction agreements are usage-specific and do not clear every underlying copyright. Georeference maps/aerials and label reconstruction uncertainty. [Sanborn rights](https://www.loc.gov/collections/sanborn-maps/about-this-collection/rights-and-access/), [LOC copyright guide](https://www.loc.gov/legal/security-copyright-and-privacy/understanding-copyright/), [Denver image terms](https://history.denverlibrary.org/about/conditions-and-image-permissions).
- **Environmental resolution matters.** DOT's noise product is not appropriate for noise at an individual place/time; Landsat temperature is surface temperature, not doorway air temperature. Water-stage values require datum alignment. Buoy significant wave height is not exact beach surf, and a five-minute file refresh does not make observations five-minute measurements. [DOT noise limitations](https://www.bts.gov/geospatial/national-transportation-noise-map), [Landsat temperature](https://www.usgs.gov/landsat-missions/landsat-collection-2-surface-temperature), [CO-OPS API](https://api.tidesandcurrents.noaa.gov/api/dev), [NDBC cadence](https://www.ndbc.noaa.gov/faq/rt_data_access.shtml).
- **Audio rights are separate from metadata.** Freesound requires clip licence filters and separate commercial API review. BBC recordings require commercial clearance; a stream URL does not license public-radio rebroadcast. Public-data briefs should be grounded, dated and rights-cleared. Polly lists unrestricted storage/reuse of generated speech; input data/text and onward contractual rights still matter. [Freesound API terms](https://freesound.org/help/tos_api/), [BBC licensing](https://sound-effects.bbcrewind.co.uk/licensing), [NPR authorised distribution](https://npr.github.io/content-distribution-service/), [Polly FAQ](https://aws.amazon.com/polly/faqs/).

## Top ten map-tech recommendations

These are proposed engineering choices informed by the linked primary documentation, not guaranteed vendor performance:

1. **One source pipeline, two asset outputs.** Native RealityKit USD/custom buffers; web glTF/codecs. Prove decoding/upload before choosing a canonical phone payload. [Apple loading](https://developer.apple.com/documentation/realitykit/loading-entities-from-a-file), [LowLevelMesh](https://developer.apple.com/videos/play/wwdc2024/10104/).
2. **Bounded spatial tiles with coarse parents.** Camera-prioritised requests, bounded resident cache and screen-space/geometric error. Adopt useful 3D Tiles semantics without assuming RealityKit supports the whole standard. [3D Tiles 1.1](https://docs.ogc.org/cs/22-025r4/22-025r4.html).
3. **Prebake static geometry; generate lightweight live/seasonal state locally.** Isolate dynamic buffers from static meshes and test cold start as well as sustained work. [LowLevelMesh](https://developer.apple.com/videos/play/wwdc2024/10104/).
4. **Instance repeated props; batch within tiles.** Share materials and preserve useful visibility culling. Verify MeshInstancesComponent and new 2026 LOD APIs on the actual supported iPhone SDK/OS. [WWDC25 instancing](https://developer.apple.com/videos/play/wwdc2025/287/), [WWDC26 RealityKit](https://developer.apple.com/videos/play/wwdc2026/279/).
5. **Start with meshopt and benchmark Draco.** Compare transfer bytes, precision, CPU decode, upload, GPU memory and thermal cost on actual scenes. [meshoptimizer](https://github.com/zeux/meshoptimizer), [Draco](https://github.com/google/draco).
6. **KTX2/Basis for the web; verify native texture path.** Include mipmaps and choose transcoding targets based on actual device features. [Khronos KTX](https://www.khronos.org/ktx/), [Basis Universal](https://github.com/BinomialLLC/basis_universal).
7. **Regional PMTiles for stable semantic layers; versioned shards for updates.** PMTiles is read-only, so rebuild changed archives/shards and atomically switch a manifest; use HTTP validators for small mutable metadata. [PMTiles](https://docs.protomaps.com/pmtiles/), [HTTP caching](https://www.rfc-editor.org/rfc/rfc9111).
8. **Compare R2 custom-domain delivery and Bunny CDN using representative mobile traffic.** Check Range, CORS, ETag and cache behaviour. The cheap arithmetic does not establish latency or a WorldEngine traffic forecast. [R2 prices](https://developers.cloudflare.com/r2/pricing/), [R2 production delivery](https://developers.cloudflare.com/r2/buckets/public-buckets/), [Bunny prices](https://bunny.net/pricing/).
9. **Sustained thermal behaviour is an acceptance criterion.** React to Low Power Mode/thermal notifications; reduce optional detail, shadows and background work. 60fps is approximately 16.7ms/frame by arithmetic, not proof of sustained phone performance. [Apple power guidance](https://developer.apple.com/documentation/xcode/responding-to-power-notifications), [RealityKit performance](https://developer.apple.com/documentation/realitykit/improving-the-performance-of-a-realitykit-app).
10. **WebGPU with capability checks; rights-cleared restrained spatial audio.** Safari 26 ships WebGPU, but adapter/device support must be checked. Use licensed mono near-source sounds, controlled ambience and streaming for long assets; do not assume Vision Pro-specific reverb features apply to iPhone. [Safari 26](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/), [WebGPU standard](https://www.w3.org/TR/webgpu/), [RealityKit audio](https://developer.apple.com/videos/play/wwdc2024/111801/).

### Hosting calculation — hypotheses, not a forecast

Assume **100GB stored**, fewer than 1M writes/month, **200 origin GETs and 100MB delivered per MAU/month**, zero edge-cache hits, decimal units and Bunny North America Standard delivery. R2 Standard includes 10GB storage, 1M Class A operations and 10M Class B operations monthly; its storage is $0.015/GB-month, reads $0.36/million and egress free. Bunny Standard North America delivery is $0.01/GB; one-region HDD storage is $0.01/GB-month with a $1 minimum. [R2](https://developers.cloudflare.com/r2/pricing/), [Bunny CDN](https://bunny.net/pricing/), [Bunny storage](https://bunny.net/pricing/storage/).

|MAU|Delivered data|Origin GETs|Calculated R2 storage+reads|Calculated Bunny delivery+storage|
|---|---|---|---|---|
|10,000|1TB|2M|$1.35/mo|$11/mo|
|100,000|10TB|20M|$4.95/mo|$101/mo|
|1,000,000|100TB|200M|$69.75/mo|$1,001/mo|

R2 formula: max(100−10,0) × .015 + max(GETs−10M,0)/1M × .36. Bunny: delivered GB × .01 + $1 storage. The CSV also contains a ten-times-heavier 1GB/MAU scenario. Both exclude compute/builds, live API subscriptions, taxes, auth, analytics, premium products, replication and optional discounts. Requests can dominate when shards are tiny; measured bytes/requests per session and cache behaviour must replace these assumptions.

## City portals and geographic scope

“Top twenty” uses Census Vintage 2025 metropolitan statistical-area populations, sorted descending; the CSV preserves that rank. Orlando is twentieth. This is an MSA list, not combined statistical areas or a list of city populations. The source is linked from Census's metro population tables. [Ranking data](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/metro/totals/cbsa-est2025-alldata.csv), [Census tables](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html).

|MSA rank|Primary portal used|Platform|
|---|---|---|
|1|[New York](https://data.cityofnewyork.us)|Socrata|
|2|[Los Angeles](https://data.lacity.org)|Socrata|
|3|[Chicago](https://data.cityofchicago.org)|Socrata|
|4|[Dallas–Fort Worth](https://www.dallasopendata.com)|Socrata|
|5|[Houston](https://data.houstontx.gov)|CKAN + city ArcGIS Hub|
|6|[Atlanta](https://dpcd-coaplangis.opendata.arcgis.com)|ArcGIS Hub|
|7|[Washington DC](https://opendata.dc.gov)|ArcGIS Hub|
|8|[Miami–Fort Lauderdale–West Palm Beach](https://opendata.miamidade.gov)|ArcGIS Hub|
|9|[Philadelphia](https://phl.maps.arcgis.com)|City ArcGIS Online + official directory|
|10|[Phoenix](https://www.phoenixopendata.com)|CKAN/OpenGov|
|11|[Boston](https://data.boston.gov)|CKAN/OpenGov|
|12|[Riverside–San Bernardino](https://gis.rivco.org)|ArcGIS Hub|
|13|[San Francisco–Oakland](https://data.sf.gov)|Socrata|
|14|[Detroit](https://data.detroitmi.gov)|ArcGIS Hub|
|15|[Seattle](https://data.seattle.gov)|Socrata + federated ArcGIS|
|16|[Minneapolis–St Paul](https://opendata.minneapolismn.gov)|ArcGIS Hub|
|17|[Tampa–St Petersburg](https://city-tampa.opendata.arcgis.com)|ArcGIS Hub|
|18|[San Diego](https://data.sandiego.gov)|Custom official catalogue|
|19|[Denver](https://opendata-geospatialdenver.hub.arcgis.com)|ArcGIS Hub|
|20|[Orlando](https://data.cityoforlando.net)|Socrata|

These portals generally cover the central city/county rather than the entire metro. Miami-Dade does not cover Broward/Palm Beach; DC does not cover Maryland/Virginia; Riverside County does not cover San Bernardino. Add surrounding jurisdictions explicitly. Philadelphia's official city directory and city-owned ArcGIS items are primary sources; the independent OpenDataPhilly catalogue is not treated as a government publisher. [Miami-Dade GIS](https://wwwx.miamidade.gov/global/service.page?Mduid_service=ser1495571905689513), [DC portal](https://opendata.dc.gov), [Riverside GIS](https://gis.rivco.org), [Philadelphia official directory](https://www.phila.gov/departments/office-of-innovation-and-technology/resources/open-data-applications/).

Dataset-level declarations are recorded separately from portal terms: CC0/PDDL rows provide much clearer data reuse than blank metadata or as-is disclaimers. These declarations do not clear public-art objects, archive images or personal information. The ten entries per metro are a practical shortlist from verified catalogues, not a claim that every metro publishes every requested inventory.

## Three-month sequence — proposed

**Month 1 / weeks 1–4: establish a trustworthy foundation.** Select representative Chicago city/lakefront and Denver neighbourhood/rural-fringe tiles. Inventory licences and source versions; resolve Denver/Miami redistribution first. Ingest cleared terrain, hydrography, massing and place records; add selected Chicago park amenities. Create provenance manifests and attribution UI. Measure compressed/downloaded bytes, decoded GPU memory, cold-start time, request count and sustained performance on the oldest supported iPhone. Implement bounded cache and native/web output separation.

**Month 2 / weeks 5–8: add subtle local truth and seasonal change.** Implement regional PMTiles and native shards, instancing, LOD fallback and compression comparisons. Add rights-cleared street-tree species, park fixtures, existing bike facilities and sidewalk geometry where coverage is verified. Combine USA-NPN phenology with species rules, and CDL/CSB with simulated state-level crop progression for rural areas. Add one representative USGS river and Chicago water/buoy feed with quality/age/datum checks. Compare R2/Bunny mobile Range delivery. Do not feed restricted sightings, art or radio into this release.

**Month 3 / weeks 9–12: production updates and Miami preparation.** Add changed-shard rebuilds, atomic manifests, rollback and rights/version monitoring. Test sustained thermal behaviour and background/power transitions. Pilot Miami topobathymetry and CO-OPS water-level geometry after local coverage/datum checks. Add one cleared sound layer and grounded, dated audio briefs. Build a WebGPU prototype from the shared source model. Keep historical/election/statistical products as separate optional B2B pilots. Expansion gates: documented reuse, measured payload/thermal budgets, current coverage and visible attribution.

## Verify first — fifteen highest-impact claims

These are implementation checks, not permission requests sent by this research.

1. **Denver/Miami municipal commercial and onward rights:** current item disclaimers do not establish them. Obtain dataset-specific clarification for planned geometry delivery. [Denver metadata](https://www.arcgis.com/sharing/rest/content/items/04e5069b4cf843d2bfe15ad0d1c66e00?f=json), [Miami metadata](https://www.arcgis.com/sharing/rest/content/items/d511e9ebc5aa4f49a23ff5fa2fb99786?f=json).
2. **Overture release/source licensing and ODbL architecture:** generated app scenes and downstream databases need the proper constituent notices and obligations. [Attribution](https://docs.overturemaps.org/attribution/).
3. **Native phone decoding and new LOD/instancing availability:** prove USD/custom-buffer import, texture uploads and exact iPhone deployment availability; do not inherit a visionOS demo's platform guarantees. [Apple loaders](https://developer.apple.com/documentation/realitykit/loading-entities-from-a-file), [WWDC26](https://developer.apple.com/videos/play/wwdc2026/279/).
4. **Sustained device budget and actual traffic:** benchmark oldest supported phones outdoors; measure bytes/origin requests per MAU before adopting the CDN totals. [Apple performance](https://developer.apple.com/documentation/realitykit/improving-the-performance-of-a-realitykit-app), [R2 pricing](https://developers.cloudflare.com/r2/pricing/).
5. **PMTiles behaviour and delta correctness:** reader support, Range/CORS/ETags, immutable archive URLs, changed-shard topology and rollback. No in-place archive patches. [PMTiles](https://docs.protomaps.com/pmtiles/).
6. **Tree/sidewalk completeness and accessibility:** DPR trees are not complete Denver street trees; canopy is not species; curb ramps are not ADA certification; Miami sidewalks are limited and stale. [Denver trees](https://www.arcgis.com/sharing/rest/content/items/f90e355dd3874744a25c30fd2ddfd45b?f=json), [Miami sidewalks](https://www.arcgis.com/sharing/rest/content/items/3b8f8359b0aa4fc08702da57a384d6e9?f=json).
7. **eBird permissions:** raw commercial use requires approval; modelled Status and Trends currently does not permit commercial applications. Ensure permission covers derived scenes and licensing to other apps. [Raw terms](https://support.ebird.org/en/support/solutions/articles/48001078113), [model FAQ](https://science.ebird.org/eu/atlasva/status-and-trends/faq).
8. **iNaturalist observation/media whitelist:** default noncommercial licences are unsuitable; aggregation must not reconstruct protected/obscured sightings. [Licences](https://help.inaturalist.org/en/support/solutions/articles/151000175695), [API practices](https://www.inaturalist.org/pages/api+recommended+practices).
9. **CDL and seasonal inference:** current native CDL is 10m from 2024, with a separate resampled 30m product. CSB is an estimate and state progress is not an individual field's operational status. [CDL release](https://www.nass.usda.gov/Research_and_Science/Cropland/Release/index.php), [CSB](https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/index.php), [Crop Progress](https://www.nass.usda.gov/Surveys/Guide_to_NASS_Surveys/Crop_Progress_and_Condition/).
10. **Water datum and representativeness:** select actual stations/tiles; distinguish tides, observed levels, Great Lakes datum, significant wave height and beach surf. [CO-OPS](https://api.tidesandcurrents.noaa.gov/api/dev), [NDBC](https://www.ndbc.noaa.gov/faq/measdes.shtml).
11. **NOAA partner-product rights and hazard semantics:** exact GLERL/SIR rights remain unclear; P-Surge is a 10%-exceedance preparation surface, not deterministic property depth. [Ice products](https://coastwatch.glerl.noaa.gov/statistics/great-lakes-ice-concentration/), [SIR](https://www.aoml.noaa.gov/phod/sargassum_inundation_report/), [P-Surge](https://www.nhc.noaa.gov/templates/graphics_inundation_inc.shtml).
12. **GBFS operator terms and operational freshness:** spec openness does not grant every operator's product/onward rights; Miami terms need clarification; station counts are allowed design inputs only after clearance, never rider traces. [GBFS](https://gbfs.org/documentation/reference/), [Divvy](https://divvybikes.com/data-license-agreement), [Miami](https://citibikemiami.com/data-policy).
13. **Google pollen/place restrictions and archive/art/media rights:** no non-Google pollen map assumption, no copied Google POI database, no blanket 1950/archive/art copyright assumption. [Pollen](https://developers.google.com/maps/documentation/pollen/policies), [Places](https://developers.google.com/maps/documentation/places/web-service/policies), [LOC](https://www.loc.gov/legal/security-copyright-and-privacy/understanding-copyright/).
14. **Civic feed licence, vintage and sensitivity:** county MIT CC0 does not establish precinct rights or live coverage; official boards need verified production terms. ACS estimates/MOEs cannot establish current hourly occupancy; maintain aggregate-only professional controls. [MIT dataset](https://doi.org/10.7910/DVN/VOQCHQ), [Census terms](https://www.census.gov/data/developers/about/terms-of-service.html).
15. **Actual operational access before dependency lock-in:** use modern USGS water APIs ahead of the legacy February 2027 retirement; check fresh 3DHP versus retired NHD, current AMS directory API, EV provider terms, numeric rate limits where available and audio rebroadcast/output agreements. [USGS legacy notice](https://waterservices.usgs.gov/), [3DHP](https://www.usgs.gov/3d-hydrography-program/access-3dhp-data-products), [AMS](https://www.usdalocalfoodportal.com/fe/datasharing/), [AFDC](https://afdc.energy.gov/data_download), [NPR](https://npr.github.io/content-distribution-service/).

Radio Browser offers a documented searchable station directory/API, useful for discovery. Directory metadata does not itself establish station rebroadcast, caching, logo or onward-app rights; the catalogue records those terms as unclear. Prefer official public-radio listen pages and negotiated station/network agreements. [Radio Browser API](https://api.radio-browser.info/), [API reference](https://docs.radio-browser.info/).

## Explicit research gaps

No production permission was requested or granted by this work. Unclear items remain explicit in the CSVs: complete Chicago street-tree inventory; initial-city light/hydrant coverage; downloadable Denver/Miami year-built coverage; national live aggregate foot traffic; initial-city live parking; current Denver scooter/bike operator feed agreements; exact current local school-calendar feeds beyond CPS; selected NOAA joint/partner product rights; current AMS bulk/API agreement; radio embedding/rebroadcast and audio onward rights; item-level historical-year coverage; local extract sizes and phone memory/battery budgets. Some primary pages were blocked or lacked current operational terms, which is recorded rather than substituted with secondary claims.

For licensing WorldEngine to others, deliver only layers whose permission explicitly covers the intended downstream product, carry required attribution and licence manifests, and avoid offering raw restricted datasets. An apparently acceptable consumer display route can still be unsuitable for sublicensing or long-term caching.
