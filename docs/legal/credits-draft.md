# Data credits — draft for app and web viewer

**DRAFT ONLY — not connected to any build.** Reviewed 2026-10-08 against [data-licence-inventory-v1.md](data-licence-inventory-v1.md). Do not publish with unresolved placeholders. This is one shared data-attribution document; it does not replace separately required software licence notices or provider agreements.

Only show conditional sections when that exact source/version contributes to the displayed world. Retain the same applicable notices in offline exports and data bundles. Legal provider names below identify the source; there are no logos, promotional marks or personal records. No endorsement is claimed.

## Core map data

[© OpenStreetMap contributors](https://www.openstreetmap.org/copyright)

Map data is available under the [Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/). Geometry and related world data have been selected, combined and transformed for this viewer.

**World data download: [RELEASE BLOCKER — insert the working, free, version-matched derivative-database download link].**

The data download must include the applicable ODbL data files, source notices and version information, and provide an unrestricted copy where distribution restrictions require one. This draft does not claim that the download already exists.

Keep the linked OSM credit visible with the world. For non-interactive exported images, use:

> © OpenStreetMap contributors · openstreetmap.org/copyright

## Building data — when Overture Buildings is used

Building data: [Overture Maps Foundation](https://docs.overturemaps.org/attribution/), release [EXACT RELEASE]. Building data is licensed under [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/).

For the existing manifest source combination, retain:

> © OpenStreetMap contributors, Overture Maps Foundation; Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program

Data has been filtered and transformed into world geometry. **[RELEASE BLOCKER: reconcile all contributing records with that release's source register; append each applicable upstream notice and licence link.]** The line above does not cover every possible worldwide Overture contributor. The current direct building-footprint release's different licence does not replace the ODbL grant for this Overture copy.

## Elevation and imagery — when used

> Data available from U.S. Geological Survey, National Geospatial Program.

USGS 3D Elevation Program. Source project, acquisition dates and transformation details: **[PIN THE SHIPPED PROJECT METADATA]**. Elevation, slope, roof and canopy estimates are derived measurements; missing features may be inferred. [National Map use policy](https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map).

> NAIP imagery provided by USDA Farm Service Agency

Tree-canopy estimates use NAIP imagery. Imagery dates, sampled areas and processing method: **[PIN THE SHIPPED PROVENANCE]**. [Use policy](https://www.fsa.usda.gov/help/policies-and-links).

These are source acknowledgements; source public-domain status does not remove the ODbL obligations of an OSM-derived joined database.

## Stars, night lights and boundaries — when used

Stars: [Yale Bright Star Catalogue, 5th revised edition, via NASA HEASARC](https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html). Catalogue subset and values transformed for rendering. [Data policy](https://heasarc.gsfc.nasa.gov/docs/heasarc/data_policy.html). Courtesy institutional credit; no individual author details reproduced.

**Star-name labels: HOLD.** The exact IAU attribution grant and required notice must be verified before using this draft to credit those labels. Do not assume the catalogue's public-domain treatment clears separately sourced labels.

Night lights: NASA Black Marble (VIIRS Day/Night Band), NASA Goddard Space Flight Center. [VNP46A4.002](https://doi.org/10.5067/VIIRS/VNP46A4.002). Derived radiance estimates; **[PRODUCT CITATION, SOURCE YEAR, SUBSET AND ACCESS DATE PENDING]**. Hold this section for release until the exact policy and citation are verified.

Boundary data: U.S. Census Bureau, TIGER/Line ZIP Code Tabulation Areas (2020). Selected and clipped for geographic classification. [Citation guidance](https://www.census.gov/about/policies/citation.html). **[VERIFY PRODUCT GRANT AND SHIPPED SUBSET]**. Courtesy draft, not a verified mandatory sentence.

## Conditional country credits — keep only cleared, contributing sources

### Netherlands: 3DBAG

[© 3DBAG by tudelft3d and 3DGI](https://docs.3dbag.nl/en/copyright/)

Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Changes: selected, simplified and converted for interactive display **[REPLACE WITH THE ACTUAL TRANSFORMATIONS AND RELEASE]**.

The linked credit must also appear at the bottom right of a browsable electronic map; listing it only in this document is insufficient under the provider's stated placement rule.

### Netherlands: AHN4 DEM

Elevation: Actueel Hoogtebestand Nederland, AHN4. [Identified DEM collection](https://portal.opentopography.org/datasetMetadata?otCollectionID=OT.012026.28992.1), [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Courtesy credit; this identified item's data licence imposes no attribution requirement. **[RECORD THE ACTUAL DISTRIBUTION AND VERSION]**. Do not reuse this statement for AHN5 or unidentified point clouds.

### England: EA 2022 lidar composites

> © Environment Agency copyright and/or database right 2022. All rights reserved.

[Source metadata](https://www.data.gov.uk/dataset/01b3ee39-da3f-47b6-83da-dc98e73a461f/lidar-composite-dtm-2022-1m). Licensed under the [Open Government Licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/). Changes: **[ACTUAL PROCESSING]**. **HOLD: full legal text unreadable in this audit; confirm before publication.** Use the actual item statement for other survey vintages.

### UK: OS OpenData

> Contains OS data © Crown copyright and database right [SOURCE YEAR]

[OpenData attribution guidance](https://www.ordnancesurvey.co.uk/products/product-support), [Open Government Licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/). **HOLD: pin the product and year, verify full terms and any additional supplier statements.** This section does not clear premium products or address products.

### Toronto

> Contains information licensed under the Open Government Licence – Toronto.

[Licence](https://open.toronto.ca/open-data-licence/). **[LIST THE CONTRIBUTING CITY DATASETS AND RELEASES; REPLACE THE DEFAULT LINE IF THEIR METADATA SPECIFIES ANOTHER STATEMENT]**. No endorsement by the data provider is implied. This notice does not cover the restricted Toronto Lidar 2015 collection.

### Canada: HRDEM

> Contains information licensed under the Open Government Licence – Canada.

[Licence](https://open.canada.ca/en/open-government-licence-canada). High Resolution Digital Elevation Model, Natural Resources Canada. **HOLD: legal text was blocked; verify the exact product credit, tile metadata and source version before use.** The quoted generic line is reported by prior research, not freshly verified here.

### Mexico: INEGI

Fuente: INEGI, [EXACT PRODUCT NAME], [UPDATE DATE]. [Terms](https://www.inegi.org.mx/inegi/terminos.html).

Information has been selected and transformed by this application's publisher; the transformation is not an official analysis by INEGI. **[DESCRIBE THE ACTUAL CHANGES AND RETAIN THE SOURCE METADATA]**. The required provider template is in the inventory; these placeholders must be filled for the selected RNC/elevation product.

### Australia: agency-owned elevation material

> © Commonwealth of Australia (Geoscience Australia) 2026

[Policy](https://www.ga.gov.au/copyright), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). **[EXACT DATASET, SOURCE NOTICE/YEAR AND CHANGES]**. Hold until the selected project's licence is confirmed; third-party ELVIS projects may have different terms.

### Japan: PLATEAU

**HOLD for the exact municipal release.** Required source and modification notices must identify the municipality, source page, licence and actual processing. The central website's example credit does not settle each city's supplied notices or Survey Act procedures. [Policy](https://www.mlit.go.jp/plateau/site-policy/).

### Other country and municipal sources

**HOLD until selected.** For every contributing source in the inventory annex, insert its verified exact notice, source/release, licence link and actual change statement here. A generic “open data” credit does not clear Mexico, Australia, Japan, Vancouver, municipal trees/parcels, transit providers or other sources. No dataset is represented as used merely because it appears in a research pack.

## Conditional live data credits

### NOAA / National Weather Service

Weather data: NOAA / National Weather Service. [Use policy](https://www.weather.gov/disclaimer). **[SOURCE PRODUCT, OBSERVATION/ISSUE TIME AND AGE]**. Derived surface conditions are estimates. Preserve official alert text and distinguish it from our interpretation. Exclude third-party fields unless separately cleared. This sentence is a courtesy draft, not a universal provider-mandated wording.

### adsb.lol

Contains information from [adsb.lol](https://www.adsb.lol/docs/open-data/api/), available under the [Open Database License 1.0](https://opendatacommons.org/licenses/odbl/1-0/). Flight data has been filtered for the displayed view. **[SEPARATE FLIGHT-DATABASE OFFER LINK; FEED TIME AND AGE]**.

**HOLD:** operator coordination, counsel review, permitted redistribution and privacy suppression must be complete. This is a proposed ODbL source notice, not a custom sentence prescribed by the operator. Do not display aircraft identifiers or personal flight histories in credits. Do not claim an inactive or stale feed is live.

### Transit

For an expressly cleared CTA use, its optional attribution is:

> Data provided by Chicago Transit Authority

[Terms](https://www.transitchicago.com/developers/terms/). **HOLD for decorative use until express permission exists.** Attribution is not permission.

For RTD, proposed optional notice:

Data: Regional Transportation District. This is an unofficial service, not endorsed by, sponsored by or affiliated with RTD. Views expressed are not those of RTD. [Terms](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement). **[DATA TIME AND AGE]**. This is draft wording; the licence may require an unofficial-site notice but does not impose a default credit sentence.

Other transit sources require their own verified notices before inclusion; no blanket transit attribution applies.

### Illustrative aircraft

Illustrative air traffic — not live.

Where corridors use OSM, retain the core OSM credit and data-offer obligations. Where corridors use FAA NASR, retain the runway source and cycle date. This does not credit or imply use of a live aircraft feed.

### Host weather and satellite services

**HOLD:** insert the host provider's exact runtime legal attribution only after terms review. This text-only draft cannot satisfy a mandatory visual provider mark. Satellite-element attribution and commercial relay rights also remain unresolved. Exclude uncleared services rather than claim this document satisfies their terms.

## Before publishing this draft

Resolve all HOLD and bracketed fields; retain only sources actually used; verify mandatory placement as well as wording; attach required full licence/NOTICE texts to the exported data; test all offer links offline/online as applicable; and audit the signed application and the actual web export. No build integration is authorized by this draft.
