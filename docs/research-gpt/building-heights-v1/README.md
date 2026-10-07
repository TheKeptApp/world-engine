# Building heights at scale — WorldEngine v1

Research date: **7 October 2026**. Primary-source desk research by a lead agent and three research agents: open datasets, lidar extraction, and inference. No datasets were downloaded or benchmarked; no all-metro completeness audit was run. **VERIFIED** means a provider document or primary paper supports the stated fact. **UNVERIFIED** means a specific right, coverage, accuracy or implementation detail remains unresolved. All compute budgets and proposed quality gates are **ESTIMATES**, not measured results.

## Recommendation

Build a height service from **permissively licensed measurements and independent footprints**, then fill gaps with explicitly labeled inference. For the US, use USGS 3DEP point clouds as the main measurement backbone, compatible municipal measurements where fresher/better, and Microsoft imagery-derived heights as a provisional fallback after local validation. Keep OSM/Overture enrichment in an explicit ODbL branch. This supports both a commercial application and partner redistribution without pretending every derived database can receive an exclusive proprietary licence.

No examined source establishes current, measured heights for every building in every US metro. “Every metro” is an inventory and gap-filling target, not an existing nationwide accuracy guarantee. A metrically positioned world can have estimated heights; expose that distinction in product claims and per-building metadata.

| Country | Recommended first path | Gap / refresh path | Main limitation |
|---|---|---|---|
| US | 3DEP roof points normalized to same-survey terrain; compatible city height/3D products | Validated Microsoft height; local levels/archetype/ML; explicit unknown | Acquisition years vary; completed roof coverage and new buildings need inventory |
| Canada | Documented city/ODB heights and paired lidar HRDEM DSM/DTM or NRCan clouds | Provincial/municipal sources with checked terms, then validated inference | ODB height fields optional; lidar coverage and survey dates vary |
| Netherlands | 3DBAG LoD1.2/1.3 for scalar/part heights, LoD2.2 for roofs | Newer AHN for stale/failed buildings; labeled inference last | Reconstruction failures, height conventions and roof/ground datum must be handled |
| UK | England EA lidar, Wales paired DSM/DTM, Scottish public-sector tiles | Northern Ireland project inventory; compatible municipal sources; validated inference | England coverage is not UK coverage; OS height redistribution needs a contract |
| Japan | PLATEAU per-city packages with method/LOD/date/terms checked | GSI regional lidar where rights and roof quality pass; local inference | Listed PLATEAU locations are not complete national coverage; GSI reuse workflow unresolved |

The source register is [sources.csv](sources.csv); detailed evidence, links, licence notes and method limitations are [sources.md](sources.md).

## What the headline datasets actually provide

- **Overture:** global buildings with optional height-related fields and mixed upstream provenance, not a global measured-height guarantee. Buildings are ODbL. Track sources at the height-property level. [Provider guide](https://docs.overturemaps.org/guides/buildings/).
- **Microsoft GlobalML:** raw footprints under CDLA Permissive 2.0; heights are neural-network estimates averaged inside polygons. Missing height is represented by −1. Footprint confidence is not height confidence. North American/Western European height availability must be audited by tile. [Provider repository](https://github.com/microsoft/GlobalMLBuildingFootprints).
- **Google Open Buildings Temporal:** inferred annual 2016–2023 height rasters, effective 4 m resolution; principally Global South coverage. It is not the default solution for mainland US/Canada/NL/UK/Japan; Caribbean US territories require explicit extent checks. Stored pixel size is not effective resolving power. [Official catalog](https://developers.google.cn/earth-engine/datasets/catalog/GOOGLE_Research_open-buildings-temporal_v1?hl=en).
- **3DEP:** USGS says 99% baseline data available **or in progress** at FY2025 end, including Alaska IfSAR. That does not mean 99% downloadable roof lidar. QL2's 0.10 m vertical RMSE and ≥2 pulses/m² describe point quality, not building-height error. [Program](https://www.usgs.gov/3d-elevation-program), [quality levels](https://www.usgs.gov/3d-elevation-program/topographic-data-quality-levels-qls).
- **3DBAG:** a national reconstructed building product, preferable to rerunning Dutch roof reconstruction from scratch. The reviewed download is v2025.09.03; newer acquisition cycles are tile-specific. [Downloads](https://3dbag.nl/download), [release history](https://docs.3dbag.nl/nl/overview/release_notes/).
- **PLATEAU:** official listing reports 306 locations as of 11 May 2026; coverage, observation methods and terms are package-specific. [Open-data list](https://www.mlit.go.jp/plateau/open-data/).
- **GlobalBuildingAtlas:** useful research context, but its dataset is CC BY-NC. Exclude from the commercial baseline and production training unless separate permission covers the intended use. [Dataset terms](https://tubvsig-so2sat-vm1.srv.mwn.de/terms_of_use.html).

## Licence architecture for partner licensing

Choose the actual distribution product first: rendered video/images, interactive service, height API, vector database, or 3D asset download. Rights can differ by product.

ODbL permits commercial use. Public derivative databases have share-alike duties; public works from those derivatives can trigger access to the derivative or alteration file, as well as attribution. Independent collective databases are treated differently. Separate storage alone does not establish independence. Review conflation and public-use design against the licence before promising proprietary redistribution. [ODbL text](https://opendatacommons.org/licenses/odbl/1-0/).

Maintain a permissive measurement/footprint master with reproducible derivation, and a clearly identified ODbL-enhanced branch for OSM/Overture-linked output. Do not silently feed OSM-derived geometry or substantial attributes into the permissive branch and declare the result unrestricted. WorldEngine's existing use of OSM must be assessed together with height enrichment, rather than only inspecting the height file in isolation.

CDLA 2.0 allows sharing data with its licence text and places no obligations on qualifying computational Results. Re-shared raw/enhanced footprints remain data, not automatically Results. CC BY permits commercial adaptations/redistribution with attribution and changes indicated. Canada/UK OGL allow commercial reuse subject to their terms/exclusions. Archive the exact package licence, notices, terms snapshot and access conditions. A paper's licence does not license its training data, code or output. [CDLA](https://cdla.dev/permissive-2-0/), [CC BY](https://creativecommons.org/licenses/by/4.0/), [Canada OGL](https://open.canada.ca/en/open-government-licence-canada), [UK OGL](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

OS commercial datasets, municipal exceptions and Japanese Survey Act requirements remain source-specific review items. Do not scrape heights from consumer 3D map products or rely on a portal being publicly viewable as a redistribution permission. This report identifies a workable rights path; it is not a determination that an unreviewed merged database can be relicensed exclusively.

## US pipeline for every metro

1. **Define the inventory.** Freeze a versioned Census/OMB metropolitan-area list and boundaries, including territories where in scope. Census's current delineation page points to July 2023 delineations. Distinguish metropolitan areas from micropolitan areas and city limits. Process footprint-bearing tiles within each area; rural counties in a metro can greatly inflate area. [Census delineations](https://www.census.gov/programs-surveys/metro-micro/about/delineation-files.html).
2. **Choose footprint branch.** Use raw Microsoft or locally compatible footprints for permissive partner products, auditing gaps, merged roofs and duplicate geometry. Use OSM/Overture in the ODbL branch where they add value. Record footprint capture/reference year separately from edit/release date. Footprint completeness is its own metric.
3. **Inventory real observations.** Intersect footprint-bearing tiles with completed 3DEP survey/work-unit extents, acquisition dates, density, class distribution, vertical datum and reports. Add city height/model packages only after definitions and rights pass. Compare observation freshness and QA, not a rigid “government always wins” rule. City limits alone do not cover suburban metro counties.
4. **Derive roof and ground.** Prefer roof point heights above local classified ground. Alternatively derive DSM and DTM from the same survey on identical grid/datum, subtract them, then aggregate validated roof samples by building part. 3DEP's usual bare-earth DEM is not a roof DSM. Do not subtract unrelated terrain rasters from roof elevations without alignment and datum checks.
5. **Pass geometry/roof QA.** Remove noise, vegetation and rooftop equipment where appropriate. Building class 6 cannot be assumed present. Inspect actual classifications, planar roof support, valid fraction, roof sample count, footprint boundary contamination and ground interpolation gaps. Handle small sheds without eroding them away; preserve separate podium/tower parts. Use halo processing and deduplicate overlaps.
6. **Resolve conflicts.** A changed footprint or building newer than the survey invalidates the old measurement for that object. Flag outlier differences rather than averaging old and new sources. A high rise, stadium, warehouse, tree-covered roof or steep site deserves stronger validation than an ordinary flat roof.
7. **Fill gaps honestly.** Prefer documented height/floor evidence, then locally validated imagery height or feature models, then an archetype distribution. All floor conversion remains inferred. Missing or out-of-domain cases can remain unknown; a low-confidence default is only for rendering continuity.
8. **Publish versioned results.** Keep inputs/algorithms, source dates, uncertainty, licences and branch identifiers. Incrementally refresh survey tiles and changed/new buildings. Publish metro coverage tables by evidence class; never collapse imputed coverage into measured coverage.

Chicago, Denver and Miami are recommended pilot metros because they exercise WorldEngine's current story, not because their present height completeness has been audited. Include low-rise neighbourhoods, skyline towers, stadiums, industrial buildings, slopes and tree cover. Manual authoritative overrides for signature landmarks should preserve the same provenance schema.

## Height definitions and lidar error

WorldEngine should retain `roof_top_agl_m`, `roof_typical_agl_m`, optional `eave_agl_m`, `base_elevation_m`, part geometry and the original height convention. A lidar p95 is an upper-roof proxy; a raw maximum can be a tree, antenna or chimney. OSM roof maximum, a model's mean height, eave height, absolute roof elevation and a legal planning height are not interchangeable. Do not convert between them without sufficient roof/ground evidence.

Use a named local terrain reference on slopes. AGL means above ground, but ground could mean lowest contact, surrounding percentile, or interpolated terrain under each roof sample. Preserve vertical CRS/datum and unit transformations. Base/top conventions also affect buildings on stilts or podiums. Metres must be explicit; a projected CRS in feet does not alone prove an attribute's units.

For independent positional uncertainties, `sqrt(sigma_roof² + sigma_ground²)` illustrates propagation; covariance matters when the same survey supplies both. This does not account for classification, roof definition, interpolation, geometry mismatch or building change. Point RMSE cannot become a per-building confidence interval by fiat. Validate derived heights against independent observations using the same height definition. [PDAL ground normalization](https://pdal.org/en/latest/stages/filters.hag_delaunay.html).

## Inference and expected error

For usable level counts, fit `ground_floor_height + (levels−1) × storey_height + roof_allowance` by country, use, era and roof type. Ground and upper storeys differ; roof and underground levels must not be double counted. Warehouses and sports halls cannot share a residential constant. A universal 3 m/storey rule is a rendering convention, not measured geometry. [OSM levels semantics](https://wiki.openstreetmap.org/wiki/Key:building:levels).

Tabular inference can combine footprint area/shape, independent land-use/use class, local density, parcel context, construction vintage, roof archetype and compatible measured neighbours. Vintage alone is not height evidence; unknown era/use must propagate into uncertainty. Footprint-only height is underdetermined. A model trained on low-rise stock must not confidently invent towers or transfer one country's floor heights to another.

Published results show what locally evaluated inference can achieve, not a WorldEngine guarantee: a 2020 European urban-form study reports 1.47 m MAE across validation areas but 2.98 m in held-out Berlin; a 2024 German study reports 1.78 m national ML MAE and 1.52–3.47 m across states. Tall buildings are a known difficult group. [2020 paper](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0242010), [2024 paper](https://publications.rwth-aachen.de/record/992601/files/992601.pdf).

Train only on rights-compatible inputs. Spatial/acquisition-block holdouts and leave-one-metro-out tests prevent nearby-roof leakage. Evaluate MAE, RMSE, median bias, P90/P95 absolute error, ±1/±3/±5 m rates and interval calibration by building type, height, region, slope, tree cover and age. Do not replace all these with R². The cost of labeling/validation can exceed inference compute.

## Confidence and product labels — proposed schema

Evidence, numerical uncertainty, freshness and legal eligibility are separate dimensions.

| Evidence code | Meaning | Short product label |
|---|---|---|
| `measured_survey` | Documented roof/ground or direct survey with known definition | Surveyed height · year |
| `measured_derived_lidar` | Roof extraction/reconstruction from real lidar, QA passed | Lidar-derived height · year |
| `measured_derived_photogrammetry` | Reconstruction from documented observed imagery | Image-derived measurement · year |
| `reported_authoritative` | Published official value, method not fully established | Source-reported height · year |
| `reported_unknown` | Explicit tag/value without adequate measurement provenance | Reported height · method unknown |
| `inferred_levels` | Converted floor count | Estimated from floors |
| `inferred_ml` | Learned imagery or tabular prediction, including Microsoft heights | Model-estimated height |
| `inferred_archetype` | Locally fitted/default building-form prior | Archetype estimate |
| `missing` | No usable height | Height unavailable |

Store a selected value plus a **locally calibrated 90% interval**, if justified; otherwise interval fields stay null. A prediction interval concerns an individual building, not confidence in a mean. A model's footprint confidence or a source's reputation does not supply a height probability. Do not interpret MAE as ±MAE at 90% confidence.

Proposed quality gates (not validated): A = independently evaluated group with P90 absolute error ≤1 m and passing matching/roof QA; B ≤3 m; C ≤5 m; D = worse, uncalibrated or out-of-domain. Store measured metrics/sample counts and reasons beside the grade. Evidence code remains unchanged: accurate calibrated inference is still inference; stale measured data can be downgraded or rejected. Thresholds should be tuned to WorldEngine use cases after pilots, not shipped as assumed performance.

Required record: building/part ID, selected height and statistic, original value/units, ground reference, vertical CRS, source and property provenance, acquisition range, release/edit/reference dates, footprint source/date, method/model/version, input licences and output branch, interval/calibration group, point count/valid roof fraction, geometry match diagnostics, vegetation/slope/change/conflict flags, quality grade and reason. Record rejected alternatives too.

## Per-country implementation details

**Canada:** harmonize StatCan ODB optional height/floors/year_built with upstream metadata; OGL national product is useful, but a supplied height is not automatically measured. Prefer documented current municipal models or paired southern HRDEM lidar DSM/DTM; preserve CGVD2013 and project boundaries. The official HRDEM catalog licence was verified by the lead agent after the lidar agent's initial fetch failed. Separate partner original files may have other terms. Vancouver 2009 component heights are useful for methodology, not a sole current city source. [HRDEM catalog](https://open.canada.ca/data/en/dataset/957782bf-847c-4644-a757-e383c0057995?res_page=1).

**Netherlands:** preserve BAG IDs, roof parts and 3DBAG quality fields. The 2D roof elevations are absolute in RD/NAP; subtract `b3_h_maaiveld` for AGL. That ground is the 5th percentile of surrounding ground points within 4 m; LoD1 extrusions use the roof's 70th percentile. Retain p50/maximum separately. Model-fit RMSE is not an independent height-error guarantee. Check version-specific bugs and AHN capture dates; do not reuse old releases without QA. [3DBAG layer definitions](https://docs.3dbag.nl/en/schema/layers/).

**UK:** EA's ~99% 1 m DSM figure is England only; its 2022 composite includes surveys from 2000–2022. Prefer matched survey-specific DSM/DTM over independently composited latest surfaces. Wales has 2020–2022 downloads; Scotland has OGL tiles unless exceptions apply. Northern Ireland coverage, accuracy and exact licence were not established here. OS MasterMap/NGD is a negotiated option, not the open default; explicitly contract for raw/derived height redistribution, caching and API delivery. [EA catalog](https://www.data.gov.uk/dataset/cf3f1137-c12b-44a1-a835-e80fe4a60b92/lidar-composite-dsm-2022-1m), [Scotland](https://remotesensingdata.gov.scot/about).

**Japan:** ingest PLATEAU CityGML by city/package with explicit measuredHeight/geometry semantics and date; simplify LOD without throwing away building parts. Per-city package terms and Survey Act requirements need checking. GSI now publishes regional 1 m DEM1A and point clouds, with point-cloud publication expansion on 30 September 2026; terrain alone provides no roof height. Current roof classification, density and reuse workflow remain unverified. [GSI publication page](https://www.gsi.go.jp/gazochosa/gazochosa41022.html).

## Processing cost at metro scale — unbenchmarked planning

Two different denominators matter: number of buildings for table operations, and surveyed area/point density for lidar. A million-building vector task cannot be compared directly with a 1,000 km² roof-point task. Published acquisition is free for many sources; downloading, processing, storage and engineering are not.

| Task / planning unit | Compute assumption | Working data / exclusions |
|---|---|---|
| Vector subset, normalize and join / 1M buildings | 1–8 vCPU-hours | XML/complex geometry can exceed this; egress/QA excluded |
| PLATEAU CityGML parse/extract / 1M buildings | 4–30 vCPU-hours | Parts, validation and XML size drive cost |
| Levels/archetype fill / 1M buildings | 1–10 vCPU-hours | Acquisition and training excluded |
| Spatial features + tabular inference / 1M buildings | 10–100 vCPU-hours | Roughly 16–64 GB working RAM with tiling; training/QA extra |
| Paired DSM/DTM subtraction + zonal QA / 1,000 km² | 4–30 vCPU-hours | Broad planning range; I/O may dominate |
| Simple QL2 cloud normalization/roof extraction / 1,000 km² | 20–200 vCPU-hours | Reclassification/reconstruction may multiply cost |

These ranges are engineering placeholders, not provider performance claims. At an **assumed**, not quoted, $0.10/vCPU-hour, 20–200 vCPU-hours is $2–20 compute alone. Use actual chosen-service rates and add storage, transfer, orchestration, failed tiles, engineering and manual validation. No exact nationwide dollar estimate is supportable from this research.

Arithmetic sizing: 1,000 km² at 1 m gives 1 billion cells; two float32 rasters occupy 8 GB uncompressed, or 32 GB at 0.5 m, before masks/overviews. QL2 nominal density gives 2 billion pulses and potentially more returns. An initial QL2 input/scratch reservation of 50–250 GB is an unverified placeholder; inspect real LAZ bytes per area before provisioning. Some metros exceed 10,000 km². Stream only needed tiles and retain compact derived heights/provenance rather than full country clouds in the engine.

Pilot 25–100 km² per chosen metro across strata before extrapolating. Measure wall time, CPU time, read/write bytes, peak memory, egress, failure/retry rate and manual review time. Cache intermediate roof/ground products and recompute only changed surveys/footprints. Country roll-out cost is the sum of heterogeneous tile workloads, not one benchmark multiplied by building count.

## Remaining verification and release criteria

- Actual measured/inferred/missing height fractions for each US metro and the other countries: **UNVERIFIED**. Run the versioned inventory, including source-age distributions and footprint completeness.
- Local building-height errors and inference interval calibration: **UNVERIFIED**. Paper results and point specs do not establish them.
- Microsoft current height availability and capture year by tile; Google Caribbean territory applicability: **UNVERIFIED** until extent audit.
- Exact NYC terms/unit/observation dates; OS partner redistribution rights; PLATEAU package exceptions/Survey Act; GSI cloud reuse; Northern Ireland lidar: **UNVERIFIED**. Exclude unresolved sources from redistribution-ready output until cleared.
- Provider updates after 7 October 2026, current national AHN cycle completion and local new-construction coverage: not assumed.
- CPU/storage dollar totals and operational engineering effort: **UNBENCHMARKED**.

Proceed first with a three-metro US pilot plus one NL 3DBAG ingestion to establish definitions and QA. Then Canada/England/Wales/Scotland and selected PLATEAU cities. Release claims should report the achieved measured fraction, dates and validated error by class. Keep unknowns visible rather than claiming universal observed true scale.
