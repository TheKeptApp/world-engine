# Data research and integration notes
Checked **2026-10-07**. GREEN means the cited source establishes an open reuse basis; YELLOW means a specified issue remains. Neither colour verifies that a feed has been integrated or that geometry is complete. Exact files, epochs, hashes and licence metadata must be pinned at ingestion.

| Source | Licence / status | Version and implementation |
|---|---|---|
| 3DBAG | GREEN — CC BY 4.0; credit required | Latest documented release checked: v2025.09.03, published 2025-09-09. Pin tile and input epochs. |
| BAG | GREEN reuse basis; YELLOW metadata harmonisation | Kadaster says Public Domain Mark 1.0; government catalogue says CC0 1.0. These identifiers are different. Record the selected resource's metadata. |
| AHN4 | GREEN — CC0 documented by TU Delft redistributor | Acquisition 2020–2022; select DTM for terrain. |
| AHN5 | YELLOW — attribution required | AHN states changed attribution requirement; redistribution labels CC-BY. Exact formal version for the chosen product remains UNVERIFIED. |
| OSM | GREEN — ODbL, attribution and applicable database obligations | Current local completeness and tag percentages UNVERIFIED. |
| KNMI warnings | GREEN — selected new warning product CC BY 4.0; operational transition pending | New feeds are TEST until planned 2026-11-02 cutover. |
| KNMI observations/radar | YELLOW per-product selection | CC BY observation and radar products are listed, but choose exact IDs, version and freshness before use. |
| NDOV / GVB / NS transit | GREEN upstream CC0 notice; YELLOW selected GTFS chain | Operator directories and aggregate conversion exist. Current GVB/NS inclusion, service dates and archive-specific terms UNVERIFIED. |
| Amsterdam trees | YELLOW | Public stamgegevens table; standard reuse licence unresolved in documentation. |
| Rotterdam trees | GREEN catalogue public-domain declaration | Catalogue metadata checked, updated 2024-10-16. Current service records/fields not sampled. |

## Buildings: 3DBAG and BAG
[3DBAG copyright](https://docs.3dbag.nl/nl/copyright/) identifies CC BY 4.0 for data and requires the credit “© 3DBAG door tudelft3d en 3DGI”, a licence link and indication of modifications. Its digital-display guidance includes a linked attribution; implement that in the product's credits/map attribution layer, not as a logo inside these concept frames. Software licences are separate.

The [release notes](https://docs.3dbag.nl/nl/overview/release_notes/) distinguish release ID from publication date: v2025.09.03 was released 9 September 2025. The [layer schema](https://docs.3dbag.nl/en/schema/layers/) provides LoD1.2, 1.3 and 2.2 representations. Use LoD2.2 roof geometry rather than extruding a 2D footprint to one height. Keep ground and roof elevations in the documented RD/NAP coordinate system; subtract ground elevation when local building height is needed. Input AHN epochs vary by location.

[BAG's publisher](https://www.kadaster.nl/zakelijk/producten/adressen-en-gebouwen/bag-ogc-api-s) labels the dataset Public Domain Mark 1.0, while the [government catalogue](https://data.overheid.nl/en/dataset/0ff83e1e-3db5-4975-b2c1-fbae6dd0d8e0) labels it CC0. Public-domain reuse is supported, but do not rewrite one identifier as the other. BAG supplies building/address identifiers and footprints; a mooring record is not a surveyed houseboat hull. Exact BAG snapshot UNVERIFIED.

[PDOK's January 2026 BAG announcement](https://www.pdok.nl/-/nieuwe-bag-ogc-api-features) describes new Features/Vector Tiles services and a July migration deadline. Its old/new URL wording is ambiguous. Inspect actual collections and schema at ingestion rather than inferring compatibility from the announcement.

## Terrain: AHN4 and AHN5
[AHN's data room](https://www.ahn.nl/dataroom) distinguishes terrain DTM, surface DSM and classified points, with tile acquisition dates. Use DTM for ground; DSM includes roofs and vegetation. Preserve RD/NAP alignment with 3DBAG.

[AHN4](https://www.ahn.nl/ahn-4) was acquired in 2020–2022. A [TU Delft AHN4 tile record](https://geotiles.citg.tudelft.nl/tiles/html/68HZ1.html) explicitly records CC0. The [first AHN5 release notice](https://www.ahn.nl/eerste-deel-van-ahn-5-is-beschikbaar) says attribution became mandatory and describes processing changes. A [TU Delft AHN5 record](https://geotiles.citg.tudelft.nl/tiles/html/78FZ2.html) labels it CC-BY without identifying the version. **UNVERIFIED: exact formal licence version per selected AHN5 resource.** Do not copy AHN4's CC0 label or generalise a differently licensed derived river product to nationwide AHN5. AHN4/5 are requested inputs, not a claim that they are the newest national releases.

## OpenStreetMap
[OSM's copyright page](https://www.openstreetmap.org/copyright) establishes ODbL and attribution obligations. Keep OSM-derived database provenance distinct from differently licensed building and terrain sources.

The [Dutch BAG import documentation](https://wiki.openstreetmap.org/wiki/Import/Catalogue/Netherlands_Buildings_Addresses) explains the building/address import, but does not establish present-day completeness. Dutch [cycleway guidance](https://wiki.openstreetmap.org/wiki/NL%3ATag%3Ahighway%3Dcycleway) and [road tagging guidance](https://wiki.openstreetmap.org/wiki/NL%3ATagging_van_Nederlandse_wegen) distinguish mapped sidepaths and access rules. Do not assume bicycle/moped permissions from red colour alone.

**UNVERIFIED: numerical completeness for each city or nationwide.** Before choosing fallbacks, run a dated bounding-box audit for each test district: road/path object counts; presence of width, lanes, sidewalk, cycleway, surface, oneway, bridge and layer; separately mapped cycle-path matches; comparison with BAG footprints and municipal inventories. Report denominator and object type. Never interpret an absent width tag as a wide US carriageway. Prefer measured width, then mapped geometry/local profile, then the explicitly unverified values in this pack. Do not render duplicate red lanes where a separate cycleway already supplies the track.

## KNMI: weather and warning transition
[KNMI's deprecation notice](https://developer.dataplatform.knmi.nl/deprecation-warnings) dated 5 October 2026 lists waarschuwingen_nederland_48h/1.0, potential_weather_warnings_upcoming_week/1 and possibly_dangerous_weather/1.0 as deprecated. The planned replacement is **2 November 2026**, subject to the announced transition conditions.

The new KNMI-public-weather-warnings/1.0 supplies CAP and JSON; KNMI-public-weather-warnings-extended/1.0 supplies professional JSON including additional lower-likelihood information. Areas become flexible polygons rather than only province units. The [public warning dataset](https://dataplatform.knmi.nl/dataset/knmi-public-weather-warnings-1-0) records CC BY 4.0 and explicitly warns that replacement data are **TEST until the transition**. Never show those as live alerts. Confirm the actual cutover; retain feed version, issue time, expiry and polygon. No warning feed was connected in this pack.

[KNMI API documentation](https://developer.dataplatform.knmi.nl/open-data-api) describes registered access, file retrieval and notifications. Check licence per selected dataset: the platform also contains [non-commercial products](https://dataplatform.knmi.nl/dataset/?license_id=CC-BY-NC-4.0). [CC BY observation listings](https://dataplatform.knmi.nl/organization/fbb79c86-9c3d-41a3-a5fd-c800d55f88fb?_tags_limit=0&license_id=CC-BY-4.0&tags=Precipitation&tags=Radiation&tags=Temperature&tags=Visibility) and [precipitation listings](https://dataplatform.knmi.nl/dataset/?groups=precipitation&license_id=CC-BY-4.0) identify candidate open inputs, not an implemented selection.

Use observed precipitation/radar for rain; station visibility/humidity for fog hints; temperature/dew point plus surface conditions for frost; cloud and wind for storm appearance. These do not directly prove local street wetness or hail. Weather presets remain authored visual settings. [KNMI's news page](https://developer.dataplatform.knmi.nl/news) includes a September disruption notice; validate timestamps and stale-data handling rather than assuming every endpoint is fresh.

## GVB / NS / GTFS
[NDOV's licence file](https://data.ndovloket.nl/LICENTIE-CC0.TXT) provides CC0 text. The [GVB directory](https://data.ndovloket.nl/netex/gvb/?order=N) exposes **NeTEx**, not a direct GTFS file. The [NS directory](https://data.ndovloket.nl/ns/) is a separate upstream source.

[OVapi's GTFS directory](https://gtfs.ovapi.nl/) publishes gtfs-nl.zip. Its [publisher README](https://gtfs.ovapi.nl/README) describes conversion from Dutch source formats, free use and best-effort operation. Respect identification and conditional-download guidance; do not impersonate an operator. **UNVERIFIED:** current GVB and NS agency inclusion, calendar dates, route mapping, converter-specific licence chain and any realtime source terms. Inspect agency.txt, routes.txt, calendar/calendar_dates and feed_info in the chosen dated archive before using it. Do not transfer upstream CC0 automatically to every API product.

[NS API terms](https://apiportal.ns.nl/voorwaarden) govern a separate service, with call/service conditions and restrictions including NS logo use. They are not a blanket CC0 declaration. Transit vehicles in this kit use generic liveries without names or logos.

## Open tree inventories
[Amsterdam's tree documentation](https://api.data.amsterdam.nl/v1/docs/datasets/bomen.html) covers municipally managed trees, not every private tree. Public stamgegevens includes point geometry and species; some growth-site management tables have restricted access. [Version v2 documentation](https://api.data.amsterdam.nl/v1/docs/datasets/bomen%40v2.html) allows a pinned schema. Its licence wording is not a standard CC licence: **YELLOW, exact reuse terms/per-table permissions UNVERIFIED**. Public access alone is insufficient.

[Rotterdam's tree catalogue](https://data.overheid.nl/dataset/6098-bomen-rotterdam) declares public domain and describes asset-management trees; metadata was updated 16 October 2024. The [municipal ArcGIS endpoint](https://diensten.rotterdam.nl/arcgis/rest/services/SB_Infra/Bomen/MapServer/0/query) exists. Current record counts, field mapping and refresh epoch were not sampled. Preserve species and location when verified; never extrapolate the illustrative elm/plane/linden mix as an inventory statistic.

## Vinex and visual boundaries
[Utrecht's Leidsche Rijn policy](https://omgevingsvisie.utrecht.nl/gebiedsbeleid/gebiedsbeleid-wijk-leidsche-rijn) documents its Vinex development. The [municipal neighbourhood listing](https://www.utrecht.nl/wonen-en-leven/wijken/leidsche-rijn) supports the selected districts. Boards are inspired by these areas, not surveyed street reconstructions. Kings Day uses temporary orange dressing without logos, crowds or permanent orange facades.

## Unverified work before engine use
Resolve AHN5 licence identifier and Amsterdam tree terms; inspect selected GTFS and realtime archives; pin BAG/3DBAG/AHN epochs and transforms; run local OSM completeness audits; validate dimensions, bridges, tree species and cadastral setbacks. Confirm warning-feed cutover and freshness. Generated cameras, block identity across views, tree placements and skyline geometry need engine-side geographic review.
