# Metro data coverage v1

**Checked 7 October 2026 (America/Denver). Research inventory, with verified facts separated from unresolved coverage and rights.**

For the next US expansion, start with **New York**: building heights, tax-lot characteristics and a substantial public street-tree baseline can support more observed detail than footprints alone. For an international geometry pilot, **Amsterdam** is the strongest candidate found: national, openly licensed LoD2.2 buildings. **Toronto** has a useful open combination of massing, street trees and TTC schedules, but the old lidar collection inspected here is explicitly not open. These are research recommendations, not measured citywide completeness rankings.

## Files and scope

- `metro-data-coverage.csv`: **381 source/layer records, 28 columns, 38 metros/cities**. Filter by `metro`, then `layer`. There are ten required layer categories per city, plus a separate restricted Phoenix GIS source route.
- This README: suggested build order, red flags, methods and remaining verification work.

The US selection is the **30 largest metropolitan statistical areas by July 2025 population**, using the Census Bureau's March 2026 Vintage 2025 release, not an arbitrary list of famous cities. Metro Divisions and Puerto Rico were excluded. Greenville SC is an additional requested city. Toronto, Vancouver, London, Amsterdam, Mexico City, Sydney and Tokyo are the seven international additions. The CSV preserves the Census metro name; a source that covers only its central municipality does **not** become metro-wide data.

Selection source: [Census metropolitan population tables](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html), [actual Vintage 2025 workbook](https://www2.census.gov/programs-surveys/popest/tables/2020-2025/metro/totals/cbsa-met-est2025-pop.xlsx). The workbook was read and the MSA population column sorted. International boundaries were not standardized to a common metro definition.

## Best data cities to build next

**Decision rubric (assumption):** prioritize reusable building shape/height, useful tree observations, terrain, and physical building attributes; then reduce priority for stale surveys, unresolved asset licences, fragmented metro coverage and missing roof geometry. No synthetic numeric score is used: availability, age, permissions and field completeness have not all been measured on equal terms.

| Order | City | Why it is a strong candidate | Gate before committing |
|---:|---|---|---|
| 1 | Amsterdam | Verified 3DBAG LoD2.2; BAG building identities/construction year; national lidar-derived terrain. Best roof-geometry pilot. | Pin 3DBAG/AHN versions; verify tree and transit grants; BAG is not a parcel/storeys database. |
| 2 | New York | BUILDING height schema, PLUTO age/floor characteristics, historical street-tree census, public 3D data. Best US observed-detail pilot. | Tax-lot joins and stale tree census; most DCP model is LOD1.5, not citywide LOD2; exact 3D artifact terms and MTA rules. |
| 3 | Toronto | Open 3D Massing, Street Tree Data and TTC GTFS with explicit OGL links. | Massing roof detail and field completeness; find separately reusable terrain. The inspected 2014–15 lidar is Not Open. |
| 4 | Vancouver | Open 2022 lidar and maintained public-tree offering; open footprint height attributes. | Footprint geometry is from **2009**; a current building update and roof derivation are needed; city/UBC is not all Metro Vancouver. |
| 5 | Boston | BPDA downloadable 3D model and public street-tree data, plus federal terrain products nearby. | Explicit commercial model redistribution permission and actual roof LOD/age; metropolitan municipalities need their own layers. |
| 6 | San Francisco / Oakland | SF footprints include lidar-derived height statistics, plus street-tree and transit sources. | Footprint height basis is old; SF city data does not cover Oakland or the wider Bay Area; each transit agency has separate terms. |
| 7 | Washington DC | Strong managed street-tree discovery and a rich municipal GIS ecosystem; federal terrain inventory near the centre. | Pin current building/assessor items and their grants; DC-only coverage leaves Maryland/Virginia gaps. |
| 8 | Philadelphia | Open footprint offering, documented OPA year/stories fields and tree inventory releases. | Full City of Philadelphia licence, tree dictionary and geometry age; no verified citywide open LOD2 product. |
| 9 | Detroit | Actual municipal footprint schema includes `MedHeight`; building/parcels base-unit system. | Confirm units, valid-height share and current reuse grant; no verified roof-resolved model or open tree point export. |
| 10 | Seattle | Building outlines, substantial SDOT observations, lidar routes and explicitly permitted King County transit storage/derivation. | Eagleview-derived outline rights, exact SDOT item licence, replacement assessor download; no verified open LOD2 city model. |
| 11 | Portland | Regional RLIS building-footprint/average-height and taxlot infrastructure can reduce municipality-by-municipality assembly. | RLIS database EULA/share-alike and source vintages; open geometry must be separated from subscriber-only attributes. |
| 12 | Tokyo | PLATEAU is a compelling roof-aware, ward-specific geometry candidate and fits the Japan art work already prepared. | Chosen ward's actual licence and survey/LOD inventory; catalogue returned 403; trees, 1 m terrain meshes and operator feeds remain unresolved. |

These rankings compare **data opportunity**, not market size or art readiness. Denver and Chicago remain useful existing product/calibration areas, but this audit does not establish them as the strongest new-data expansions. Miami is strategically useful for a different climate and building vocabulary; its observed tree and roof inputs need more verification before it receives a high data-readiness rank.

Primary evidence supporting the first five candidates: [3DBAG CityJSON LODs](https://docs.3dbag.nl/nl/delivery/cityjson/), [3DBAG licence and credit placement](https://docs.3dbag.nl/en/copyright/); [NYC footprints metadata](https://github.com/CityOfNewYork/nyc-geo-metadata/blob/main/Metadata/Metadata_BuildingFootprints.md), [PLUTO dictionary](https://www.nyc.gov/assets/planning/download/pdf/data-maps/open-data/pluto_datadictionary.pdf), [NYC 3D metadata](https://www.nyc.gov/assets/planning/download/pdf/data-maps/open-data/nyc-3d-model-metadata.pdf); [Toronto massing](https://open.toronto.ca/dataset/3d-massing/), [Toronto trees](https://open.toronto.ca/dataset/street-tree-data/), [Toronto TTC feed](https://open.toronto.ca/dataset/merged-gtfs-ttc-routes-and-schedules/); [Vancouver lidar](https://opendata.vancouver.ca/explore/dataset/lidar-2022/information/), [Vancouver 2009 footprints](https://opendata.vancouver.ca/explore/dataset/building-footprints-2009/), [Vancouver public trees](https://opendata.vancouver.ca/explore/dataset/public-trees/); [BPDA urban-design resources](https://www.bostonplans.org/urban-design/urban-design-resources) and [3D documentation](https://maps.bostonplans.org/3d/3D_Data_Documentation.pdf).

## Licence colours: operational gates, not data quality

| Status | Meaning for proprietary WorldEngine distribution |
|---|---|
| GREEN | An explicit permissive/public-domain route was found for the named dataset or release. Attribution, change notices and product-specific exceptions still apply. GREEN does not assert complete coverage, accurate geometry or current survey dates. |
| YELLOW | Conditional/share-alike/custom licence, or an exact permission/coverage link has not been verified. Commercial use may be entirely lawful, but the relevant obligations must be resolved and retained before distribution. |
| RED | A scoped source explicitly is not open or restricts the intended redistribution without further permission. This does not label the entire city, all agency data or independently sourced alternatives RED. |

The CSV contains **117 GREEN / 259 YELLOW / 5 RED records**. These are source rows with repeated global options, **not percentages of cities cleared for release**. Do not rank cities by counting GREEN rows.

**Current direct Microsoft ≠ Overture licence.** The direct [Microsoft Global ML Building Footprints repository](https://github.com/microsoft/GlobalMLBuildingFootprints) now specifies CDLA-Permissive-2.0; its current direct offering is GREEN. Heights are partial, and no city-specific height coverage was counted. The [Overture Buildings theme](https://docs.overturemaps.org/attribution/) remains ODbL, as does [OSM](https://www.openstreetmap.org/copyright): YELLOW here because the proprietary package/API design must accommodate attribution and applicable database obligations. They are not prohibited commercial sources. An old Microsoft-derived city layer can have older terms; a newer repository licence cannot simply be assumed to relicense that city artifact.

## Main red flags

1. **Toronto terrain rights.** The university catalogue explicitly labels [Toronto Lidar 2015](https://mdl.library.utoronto.ca/collections/geospatial-data/toronto-lidar-2015) **Not Open**, with Airborne Imaging copyright. Acquisition was in April/May 2014 and April 2015; 1 m grids and LAS exist, but availability is not a distribution grant. RED for this route; not a finding that all Toronto terrain is closed.
2. **Clark County warehouse.** The [GIS products page](https://www.clarkcountynv.gov/government/departments/geographic_info_systems/services/data-and-products) describes a paid company-use subscription with resale restrictions. RED for this warehouse route, not for separately released free layers. Do not turn a paid subscription into a distributable WorldEngine parcel/building package without permission.
3. **Tampa consultant tree survey.** The [Glen Avenue report](https://www.tampa.gov/sites/default/files/project-doc/2024-02/glen_avenue_tree_inventory_report.doc.pdf) is corridor-specific and has a proposal-purpose restriction (earlier same-day audit, page 3). It is not an open citywide tree inventory. RED for raw survey reuse.
4. **Phoenix GIS DVD route.** The [city request/licence packet](https://www.phoenix.gov/streetssite/documents/eas_pdf_gis_request_packet.pdf) restricts assignment/licensing/distribution without consent. This is a separate RED source route; it does not automatically govern the city's public REST items or USGS terrain.
5. **Portal timestamps can hide old surveys.** Vancouver footprint geometry is 2009; NYC 3D metadata identifies 2014 aerial source and 2018 data update; SF building-height statistics use older lidar. Retain acquisition, publication and metadata dates separately.
6. **LOD2 claims need a roof check.** Footprint+height extrusions, “3D massing,” textured viewers and procurement announcements are not proof of an open citywide LOD2 asset. NYC DCP documents mostly LOD1.5 with about 100 iconic LOD2 buildings. Boston and Toronto roof completeness was not measured. PLATEAU varies by ward/year/object.
7. **GTFS is a format, not a universal licence.** [CTA](https://www.transitchicago.com/downloads/sch_data/developers_license_agreement.htm), [SEPTA](https://www3.septa.org/developer/), [SFMTA](https://www.sfmta.com/reports/gtfs-transit-data), [TransLink](https://www.translink.ca/about-us/doing-business-with-translink/app-developer-resources/gtfs/gtfs-data) and [King County](https://kingcounty.gov/en/dept/metro/rider-tools/mobile-and-web-apps) have agency conditions. A paid transit-rider app, a decorative world and a resold World State API may have different permitted-purpose implications. Static schedules are not realtime positions. The CDMX catalogue describes a 2022 feed: check its actual service window before showing it as current.
8. **Survey grid size, point spacing and accuracy differ.** A dense lidar cloud is not proof of a published 1 m bare-earth DEM. INEGI's inspected lidar model offering is 5 m; Tokyo GSI now describes 1/5/10 m products nationally, but this does not prove 1 m coverage for every Tokyo mesh. NSW product specifications are not a tile coverage audit.
9. **AHN licence changes with version.** The inspected [AHN4 DEM metadata](https://portal.opentopography.org/datasetMetadata?otCollectionID=OT.012026.28992.1) is CC0 and 0.5 m. An [AHN technical report](https://cuatro.sim-cdn.nl/ahn/uploads/3a_classificatieverschillen_ahn_en_beeldmateriaal_dense_matching_puntenwolken_1_0.pdf?cb=4_ejTWzb) says attribution becomes mandatory from AHN5. Archive the exact licence with the selected release; do not blanket-label all AHN CC0.
10. **Privacy and identity joins.** Parcel ownership/contact fields add no visual value. Construction year and storeys may be tax-lot statistics, estimated, or attached to one of several buildings. Preserve nulls and estimate flags. Sydney planning-control storeys are not observed existing storeys; BAG year is not a cadastral assessor record.
11. **Trees and OSM denominators.** Street-tree inventories omit private yards, can contain dead trees/stumps/vacant sites, and can represent maintenance responsibility rather than all visible trees. Tree canopy rasters and species planting guides are not point inventories. An OSM tag count has no independently validated completeness denominator.
12. **Blocked/unavailable pages remain unresolved.** The chosen PLATEAU ward catalogue and TfL terms returned 403; MBTA's site was robots-blocked; the older Sydney tree catalogue link returned 404; several modern portals expose metadata poorly in text readers. No bypass was used and no licence was inferred from those failures.

## Verification methods and limits

### Federal terrain: actual API queries for all 31 US areas

The [USGS National Map API](https://tnmaccess.nationalmap.gov/api/v1/datasets) was queried for **both 1 m DEM and Lidar Point Cloud collections**, once per central-city box, approximately ±0.02° longitude/latitude. The CSV stores each reproducible query URL and the bbox/count/project-title results in `sample_metrics`. API results are bounding-box intersections; no DEM pixels, LAS files, exact flight ranges or full metropolitan coverage polygons were downloaded/validated. Product counts can include overlapping projects and many tiles. The per-query response was capped at 100; catalogue totals larger than 100 are retained.

All 31 samples returned lidar catalogue products. Thirty returned at least one 1 m DEM catalogue product; **Tampa returned zero** for this central sample. This is not evidence that Tampa has no lidar or no 1 m terrain elsewhere. For Tampa, inspect SWFWMD/local project products and their extents next. [USGS data delivery](https://www.usgs.gov/the-national-map-data-delivery/gis-data-download) and [USGS copyrights/credits](https://www.usgs.gov/information-policies-and-instructions/copyrights-and-credits) support the product route; exact third-party notices and vertical datums remain per-project checks.

`acquisition_date` deliberately says unverified when only a project-year label was found. `publication_or_update_date` is the catalogue's publication date. **Neither a 2026 publication nor “B23” establishes a 2026 or 2023 flight.**

### OSM: five usable central samples, not a nationwide completeness score

Small count-only [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) requests ran sequentially. New York timed out; LA, Chicago, Dallas, Houston and Atlanta returned counts; the next DC request returned HTTP 429 and the run stopped. No retries, parallel query flood or alternative-host workaround followed. The other 33 city rows remain locally unmeasured (including the failed New York/DC attempts).

| Sample | Building objects | Height OR levels tagged | Tagged share | Tree nodes | Highway ways | Sidewalk-tagged highway ways | Footway ways |
|---|---:|---:|---:|---:|---:|---:|---:|
| Los Angeles | 7,097 | 6,770 | 95.39% | 769 | 12,237 | 64 | 6,826 |
| Chicago | 5,076 | 2,218 | 43.70% | 12,107 | 18,863 | 919 | 10,443 |
| Dallas | 2,868 | 567 | 19.77% | 1,012 | 13,513 | 627 | 6,962 |
| Houston | 8,677 | 370 | 4.26% | 1,264 | 11,827 | 57 | 5,557 |
| Atlanta | 7,186 | 704 | 9.80% | 516 | 13,634 | 17 | 7,131 |

These are **tag-presence signals**, not completeness or quality percentages. Building node/way/relation objects were not deduplicated; `building:levels` can exist without a measured height; highway ways include footways and other classes; explicit `sidewalk` tags can be absent when sidewalks are separately mapped. Dense LA height tags do not prove correct measurements. The boxes sample city centres, not residential suburbs. OSM base timestamps are in UTC; some are 8 October UTC while the local research date remains 7 October Denver.

### What “unverified” means here

- **Not found/verified is not absent.** A city row with a generic discovery portal is a research lead, not a verified downloadable source. This is particularly common for LOD2, assessor physical-field exports, and full tree inventories.
- A licence may be verified while local feature coverage is not. Conversely, an actual schema may be observed while a commercial redistribution grant is unresolved.
- Full city files and all transit feeds were not downloaded. No metro-wide Microsoft/Overture counts or height-validity shares were measured. No street-tree prevalence was computed.
- Several same-day primary-source findings from the existing metro-onboarding/tree inventories were reused; those rows explicitly identify this provenance and retain their earlier uncertainty. No previous file was changed.
- The CSV's `available_fields`, `height_status`, `year_built_status`, `storeys_status`, `licence_verified`, `verification_status` and `next_check` keep these separate. Blank/unverified never means zero, no coverage or permission denied.

## Per-city terrain inventory and acquisition follow-up

The table below is a compact navigation aid; every row's query and project publication dates are in the CSV. **Project names are survey-year clues, not verified acquisition dates.** Core samples for DFW, Riverside–San Bernardino, SF–Oakland and Minneapolis–St Paul were centred on Dallas, Riverside, SF and Minneapolis respectively. Do not generalize them to the companion cities.

| US order | Core sample | 1 m DEM catalogue count | Lidar catalogue count | Example DEM project / publication (not flight) |
|---:|---|---:|---:|---|
| 1 | New York | 3 | 24 | [USGS 1 Meter 18 x58y451 NJ_NE6County_B23](https://www.sciencebase.gov/catalog/item/6aac9d8b1ba49b6a17badefa) — published 2026-09-17 |
| 2 | Los Angeles | 4 | 65 | [USGS 1 Meter 11 x38y377 CA_LosAngeles_B23](https://www.sciencebase.gov/catalog/item/689bf41fd4be0276bfcb20af) — published 2025-08-11 |
| 3 | Chicago | 1 | 35 | [USGS 1 Meter 16 x44y464 IL_4_County_QL1_LiDAR_2016_B16](https://www.sciencebase.gov/catalog/item/673d532ad34e6b795de6b661) — published 2024-11-18 |
| 4 | Dallas-Fort Worth | 2 | 16 | [USGS 1 Meter 14 x70y363 TX_Pecos_Dallas_2018_D19](https://www.sciencebase.gov/catalog/item/619c3847d34eb622f69322b1) — published 2021-11-18 |
| 5 | Houston | 4 | 34 | [USGS 1 Meter 15 x26y330 TX_Houston_B24](https://www.sciencebase.gov/catalog/item/6a427d311ba49b09ad176533) — published 2026-06-18 |
| 6 | Atlanta | 2 | 45 | [USGS 1 Meter 16 x73y374 GA_Statewide_2018_B18_DRRA](https://www.sciencebase.gov/catalog/item/629ae799d34ec53d276f4bb6) — published 2022-05-31 |
| 7 | Washington DC | 6 | 15 | [USGS 1 Meter 18 x32y431 MD_Central_Processing_D24](https://www.sciencebase.gov/catalog/item/69e6ddedb66b01f903b6b296) — published 2026-04-04 |
| 8 | Miami | 7 | 42 | [USGS 1 Meter 17 x57y285 FL_MiamiDade_D23](https://www.sciencebase.gov/catalog/item/69423b63d4be02297efc2c72) — published 2025-12-15 |
| 9 | Philadelphia | 2 | 28 | [USGS one meter x48y443 DE DelawareValley HD 2015](https://www.sciencebase.gov/catalog/item/5eaa4db882cefae35a22052e) — published 2020-03-30 |
| 10 | Phoenix | 4 | 25 | [USGS 1 Meter 12 x39y370 AZ_MaricopaPinal_2020_B20](https://www.sciencebase.gov/catalog/item/6413f4dbd34eb496d1cea1ff) — published 2023-01-14 |
| 11 | Boston | 12 | 36 | [USGS 1 Meter 19 x32y469 MA_CentralEastern_2021_B21](https://www.sciencebase.gov/catalog/item/63c78d01d34e06fef14edce7) — published 2023-01-15 |
| 12 | Riverside-San Bernardino | 1 | 24 | [USGS one meter x46y376 CA SoCal Wildfires B1 2018](https://www.sciencebase.gov/catalog/item/5eaa4cfa82cefae35a2200d3) — published 2020-03-30 |
| 13 | San Francisco-Oakland | 17 | 130 | [USGS 1 Meter 10 x54y418 CA_CaliforniaGaps_B23](https://www.sciencebase.gov/catalog/item/68ad17a6d4be0220fe21695e) — published 2025-08-20 |
| 14 | Detroit | 4 | 49 | [USGS one meter x32y469 MI WayneCo 2017](https://www.sciencebase.gov/catalog/item/5eacec1282cefae35a24a747) — published 2020-03-30 |
| 15 | Seattle | 2 | 12 | [USGS 1 Meter 10 x54y528 WA_KingCounty_2021_B21](https://www.sciencebase.gov/catalog/item/640825e7d34e76f5f75e422f) — published 2023-03-03 |
| 16 | Minneapolis-St Paul | 4 | 107 | [USGS 1 Meter 15 x47y498 MN_CentralMissRiver_B22](https://www.sciencebase.gov/catalog/item/66bd6514d34e03388281d413) — published 2024-07-25 |
| 17 | Tampa | 0 | 12 | No sample product; local follow-up needed |
| 18 | San Diego | 5 | 88 | [USGS 1 Meter 11 x48y362 CA_SanDiegoCo_D24](https://www.sciencebase.gov/catalog/item/6aa9fad11ba49b23655bd43b) — published 2026-09-15 |
| 19 | Denver | 8 | 48 | [USGS 1 Meter 13 x49y440 CO_DRCOG_2020_B20](https://www.sciencebase.gov/catalog/item/620de525d34e6c7e83baa064) — published 2022-02-10 |
| 20 | Orlando | 1 | 16 | [USGS 1 Meter 17 x46y316 FL_Peninsular_FDEM_2018_D19_DRRA](https://www.sciencebase.gov/catalog/item/63fd9e36d34e70052b9b69e8) — published 2023-02-10 |
| 21 | Charlotte | 2 | 53 | [USGS 1 Meter 17 x51y390 NC_Phase_4_CentralWestNC_GEIGER_A16](https://www.sciencebase.gov/catalog/item/66692c2bd34e9bcc607bd595) — published 2024-06-10 |
| 22 | Baltimore | 12 | 45 | [USGS 1 Meter 18 x35y435 MD_4County_D24](https://www.sciencebase.gov/catalog/item/6a03dda2b66b01cc610ddabc) — published 2026-05-11 |
| 23 | St Louis | 6 | 33 | [USGS 1 Meter 15 x74y429 IL_10CountyNRCS_D23](https://www.sciencebase.gov/catalog/item/69e6de71b66b01f903b6ba18) — published 2026-04-04 |
| 24 | San Antonio | 2 | 12 | [USGS one meter x54y326 TX Central B2 2017](https://www.sciencebase.gov/catalog/item/5eacfa3782cefae35a250016) — published 2020-03-30 |
| 25 | Austin | 4 | 12 | [USGS one meter x61y335 TX Central B1 2017](https://www.sciencebase.gov/catalog/item/5eacfe5b82cefae35a251a4c) — published 2020-03-30 |
| 26 | Portland | 4 | 61 | [USGS 1 Meter 10 x52y504 OR_PortlandMetro_B24](https://www.sciencebase.gov/catalog/item/69e6ddf9b66b01f903b6b346) — published 2026-04-02 |
| 27 | Sacramento | 11 | 35 | [USGS 1 Meter 10 x63y427 CA_FEMALevee_D23](https://www.sciencebase.gov/catalog/item/67590552d34edfeb87103a3a) — published 2024-11-25 |
| 28 | Pittsburgh | 1 | 44 | [USGS 1 Meter 17 x58y448 PA_WesternPA_2019_D20](https://www.sciencebase.gov/catalog/item/61a5bf36d34eb622f697557d) — published 2021-11-22 |
| 29 | Las Vegas | 2 | 36 | [USGS 1 Meter 11 x66y401 NV_Las_Vegas_Region_2016_A16](https://www.sciencebase.gov/catalog/item/696afde6d4be0208a7d3eefa) — published 2026-01-16 |
| 30 | Cincinnati | 4 | 146 | [USGS 1 Meter 16 x71y433 OH_Statewide_Phase3_2021_B21](https://www.sciencebase.gov/catalog/item/68ca18aad4be0274ff4eafba) — published 2025-09-14 |
| Additional | Greenville SC | 1 | 38 | [USGS 1 Meter 17 x37y386 SC_SavannahPeeDee_2019_B19](https://www.sciencebase.gov/catalog/item/6279f4c6d34e8d45aa6e439d) — published 2022-05-06 |

## Before a build lane imports any city

1. Pick three independently defined sample areas: centre, typical residential block and outer-metro edge. Choose current source releases and save extent polygons, exact licences, attribution strings and survey dates.
2. Measure actual coverage against independently licensed truth: footprint omissions, valid height share and error, roof LOD/validity, tree-coordinate/species/diameter completeness, road/sidewalk connectivity. Do not use source row counts as a completeness denominator.
3. Verify physical building joins: building ID versus parcel/lot versus address, multiple structures, estimated age, zero/default heights and storeys, demolition/new build dates. Keep observed and inferred values separate.
4. For transit, enumerate all relevant operators and modes, validate feed service windows and routes, then review storage, derivative display, paid-app and API resale rights. Archive agreed terms; no operator logos/liveries are part of this research pack.
5. Prioritize a small, reproducible import for the top candidates instead of attempting a uniform “whole metro” asset where the sources only cover one municipality.

No world-engine project files were written. No git commands or builds were run.

## International terrain/date checkpoint

| City | Verified source finding | What is still unverified |
|---|---|---|
| Toronto | 1 m grids and LAS from 2014-04-20–05-06 and 2015-04-03–04-25 collection; **Not Open** catalogue. | A separately open, current Toronto/GTA terrain route. |
| Vancouver | City/UBC 2022 lidar: 7 and 9 September; OGL. | Published 1 m raster product, local datum/quality and full metropolitan coverage. |
| London | EA National LIDAR Programme: 1 m products, OGL, phase-1 winter 2017–February 2023. | Acquisition dates and repeat-survey vintage for actual London blocks. |
| Amsterdam | AHN4 distributor: 0.5 m DEM, CC0, national survey range 2019-11-22–2022-03-25; distributor publication 2026-01-15. | Local Amsterdam flight/tile vintage, current AHN/3DBAG alignment; newer AHN version terms. |
| Mexico City | INEGI elevation discovery includes 5 m lidar-model offering. | Local dates, actual raw lidar and open 1 m coverage; exact product terms. |
| Sydney | NSW Spatial elevation/ELVIS route exists. | Specific Sydney lidar/1 m tiles, flights, datum and chosen project licence. |
| Tokyo | GSI national DEM product families now include 1 m, 5 m and 10 m; general PDL1.0 terms. | Tokyo 1 m mesh extents/dates and Survey Act procedures for intended derived distribution. |

Additional primary sources: [EA programme](https://www.data.gov.uk/dataset/f0db0249-f17b-4036-9e65-309148c97ce4/national-lidar-programme), [INEGI elevation portal](https://www.inegi.org.mx/app/geo2/elevacionesmex/index.jsp), [NSW elevation products](https://www.spatial.nsw.gov.au/what_we_do/the_natural_environment/elevation_and_depth), [GSI DEM FAQ](https://www.gsi.go.jp/kiban/faq.html), [GSI use terms](https://web2.gsi.go.jp/ENGLISH/page_e30286.html), [MLIT PLATEAU licence FAQ](https://www.mlit.go.jp/plateau/faq/), [London public realm tree metadata](https://data.london.gov.uk/dataset/london-public-realm-trees-2r45m), [Sydney tree map availability](https://www.cityofsydney.nsw.gov.au/strategies-action-plans/greening-sydney-strategy), [CDMX GTFS licence/date](https://datos.cdmx.gob.mx/dataset/gtfs), [ODPT provider-specific licences](https://www.odpt.org/2021/06/01/news20210601_1/).
