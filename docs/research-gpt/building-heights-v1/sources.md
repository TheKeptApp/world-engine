# Sources and evidence — building heights v1

Checked 7 October 2026. This register includes data products, candidate surveys and inference methods. Primary links support specific facts, not wholesale accuracy/completeness guarantees. CSV has one row per source/method and separate commercial, redistribution and derivative-right fields. Cost ranges are unbenchmarked.

## Important corrections from lead review

- NRCan HRDEM catalog was successfully retrieved by the lead: OGL Canada, southern lidar DSM/DTM at 1–2m, CGVD2013; project seams are not edge-matched. Its licence is verified, while coverage and roof error remain unverified. [Official catalog](https://open.canada.ca/data/en/dataset/957782bf-847c-4644-a757-e383c0057995?res_page=1).
- Google Global South coverage is not a default for the five mainland markets; Caribbean US-territory inclusion needs an extent audit. Do not treat a geographic region name as a checked tile boundary.
- Scottish portal policy is OGL v3 unless otherwise stated; coverage still requires tile inventory. [Portal](https://remotesensingdata.gov.scot/about). Northern Ireland has a lidar archive candidate but no nationwide rights/coverage determination was made. [Official archive](https://admin.opendatani.gov.uk/tl/dataset/?_res_format_limit=0&res_format=LAS).
- 3DBAG absolute roof elevations need ground subtraction; model-fit quality is not independent roof-height accuracy. [Layer semantics](https://docs.3dbag.nl/en/schema/layers/).

## Source-by-source comparison

### OVERTURE — Overture Buildings

**Coverage:** Global footprints; optional height completeness unverified. **Accuracy:** Mixed upstream; no height error guarantee. **Vintage:** Monthly; 2026-09-23.1.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** Mixed/unknown.

**Licence:** ODbL. **Commercial:** Yes with obligations. **Redistribution:** Adapted database obligations apply. **Derivatives:** Adapted database obligations apply.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://docs.overturemaps.org/guides/buildings/) · [Licence / terms evidence](https://docs.overturemaps.org/attribution/) · [Method / metadata](https://docs.overturemaps.org/schema/reference/buildings/building/).

### MICROSOFT — Microsoft GlobalMLBuildingFootprints

**Coverage:** Global footprint tiles; partial North America/Western Europe heights. **Accuracy:** Height RMSE unverified; confidence only footprints. **Vintage:** 2026-08-13 release; imagery varies to 2025.

**Method / definition:** Neural image model mean over polygon; -1 missing; footprint confidence not height confidence. **Label:** inferred_imagery_ml.

**Licence:** CDLA Permissive 2.0. **Commercial:** Yes. **Redistribution:** Data sharing includes license; results unrestricted by section 3. **Derivatives:** Data sharing includes license; results unrestricted by section 3.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://github.com/microsoft/GlobalMLBuildingFootprints) · [Licence / terms evidence](https://cdla.dev/permissive-2-0/) · [Method / metadata](https://cdla.dev/permissive-2-0/).

### GOOGLE — Google Open Buildings Temporal V1

**Coverage:** Africa, South/Southeast Asia, Latin America, Caribbean; not default mainland US/CA/NL/UK/JP; PR/USVI extent applicability unverified. **Accuracy:** Effective 4 m; country height error unverified. **Vintage:** 2016–2023 annual.

**Method / definition:** ML predicted building-height raster; effective 4m not stored 0.5m resolution. **Label:** inferred_imagery_ml.

**Licence:** CC BY 4.0 or ODbL. **Commercial:** Yes via selected license. **Redistribution:** CC BY attribution/changes; ODbL obligations if chosen. **Derivatives:** CC BY attribution/changes; ODbL obligations if chosen.

**Metro processing:** UNBENCHMARKED estimate: 4–30 vCPUh/1000km2 raster zonal processing; not a mainland target-country source.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://developers.google.cn/earth-engine/datasets/catalog/GOOGLE_Research_open-buildings-temporal_v1?hl=en) · [Licence / terms evidence](https://sites.research.google/gr/open-buildings/) · [Method / metadata](https://sites.research.google/gr/open-buildings/).

### 3DBAG — Netherlands 3DBAG

**Coverage:** National BAG buildings; gaps/failures flagged. **Accuracy:** Reconstruction QA available; AHN precision not model error. **Vintage:** v2025.09.03; AHN3/4/5 per tile.

**Method / definition:** Absolute RD/NAP roof part elevations minus b3_h_maaiveld (ground p05 in 4m surroundings); LoD1 roof p70 extrusion; preserve other roof stats. **Label:** observed_lidar_derived.

**Licence:** CC BY 4.0. **Commercial:** Yes. **Redistribution:** Redistribution/adaptation with attribution and changes. **Derivatives:** Redistribution/adaptation with attribution and changes.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://3dbag.nl/download) · [Licence / terms evidence](https://docs.3dbag.nl/nl/copyright/) · [Method / metadata](https://docs.3dbag.nl/nl/overview/release_notes/).

### ODB — Canada StatCan ODB

**Coverage:** 14.4M footprints v3; optional supplied height. **Accuracy:** Source-specific; no national height accuracy. **Vintage:** April 2025 release; upstream vintage varies.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** source_reported_unknown.

**Licence:** OGL Canada. **Commercial:** Yes. **Redistribution:** Commercial copy/adapt/distribute with attribution/exceptions. **Derivatives:** Commercial copy/adapt/distribute with attribution/exceptions.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www150.statcan.gc.ca/n1/pub/34-26-0001/2018001/metadata-eng.htm) · [Licence / terms evidence](https://open.canada.ca/en/open-government-licence-canada) · [Method / metadata](https://open.canada.ca/en/frequently-asked-questions).

### VANCOUVER — Vancouver 2009 building footprints

**Coverage:** City only; components/heights. **Accuracy:** LiDAR derived; height error unverified. **Vintage:** 2009 capture.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** observed_lidar_derived.

**Licence:** OGL Vancouver. **Commercial:** Yes. **Redistribution:** Copy/adapt/distribute with attribution/exceptions. **Derivatives:** Copy/adapt/distribute with attribution/exceptions.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://opendata.vancouver.ca/explore/dataset/building-footprints-2009/) · [Licence / terms evidence](https://opendata.vancouver.ca/pages/licence/) · [Method / metadata](https://opendata.vancouver.ca/pages/licence/).

### PLATEAU — Japan PLATEAU

**Coverage:** 306 listed locations 2026-05-11; not nationwide. **Accuracy:** City/LOD-specific; numeric error unverified. **Vintage:** Package/capture-specific.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** source_reported_unknown until method established.

**Licence:** CC BY/government terms/ODC BY/ODbL per package. **Commercial:** Yes generally; package check. **Redistribution:** Redistribute/adapt with credits and exact terms; Survey Act check. **Derivatives:** Redistribute/adapt with credits and exact terms; Survey Act check.

**Metro processing:** UNBENCHMARKED estimate: 4–30 vCPUh/1M buildings CityGML parse/extract; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www.mlit.go.jp/plateau/open-data/) · [Licence / terms evidence](https://www.mlit.go.jp/plateau/site-policy/) · [Method / metadata](https://www.mlit.go.jp/plateau/site-policy/).

### OS — UK OS MasterMap/NGD building heights

**Coverage:** GB access; NI separate; complete height coverage unverified. **Accuracy:** Official product; quantitative error unverified. **Vintage:** Quarterly catalog; observation vintage per product.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** source_reported_unknown.

**Licence:** Commercial contract; not verified open. **Commercial:** Negotiated. **Redistribution:** Redistribution/derivation rights unverified; contract required. **Derivatives:** Redistribution/derivation rights unverified; contract required.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://docs.os.uk/osngd) · [Licence / terms evidence](https://docs.os.uk/osngd) · [Method / metadata](https://www.data.gov.uk/dataset/7624f5d0-899e-4f38-93a6-22f6b915befe/os-mastermap-building-height-attribute).

### NYC — NYC BUILDING municipal height

**Coverage:** NYC only; roof height + ground. **Accuracy:** Controlled imagery/plans; error unverified. **Vintage:** 2026-09 portal update; observation date varies.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** observed_source_reported when method confirmed.

**Licence:** NYC portal terms; exact exceptions unverified. **Commercial:** Public resource generally; verify terms. **Redistribution:** Exact redistribution/derived rights unverified in pass. **Derivatives:** Exact redistribution/derived rights unverified in pass.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://data.cityofnewyork.us/City-Government/BUILDING/5zhs-2jue) · [Licence / terms evidence](https://www.nyc.gov/assets/doitt/downloads/pdf/nyc_open_data_tsm.pdf) · [Method / metadata](https://github.com/CityOfNewYork/nyc-geo-metadata/blob/main/Metadata/Metadata_BuildingFootprints.md).

### GBA — GlobalBuildingAtlas

**Coverage:** Global ML heights and LoD1. **Accuracy:** ML; accuracy not investigated for production. **Vintage:** 2025 publication.

**Method / definition:** Source height convention requires ingest audit; see sources.md. **Label:** inferred_imagery_ml.

**Licence:** CC BY-NC 4.0 dataset; separate code Commons Clause. **Commercial:** NO without separate permission. **Redistribution:** Noncommercial only; OSM compatibility issue documented. **Derivatives:** Noncommercial only; OSM compatibility issue documented.

**Metro processing:** UNBENCHMARKED estimate: 1–8 vCPUh/1M buildings vector subset and scalar extraction; staff/storage/transfer extra.

**Verification:** Primary docs checked; specific gaps marked unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://tubvsig-so2sat-vm1.srv.mwn.de/terms_of_use.html) · [Licence / terms evidence](https://tubvsig-so2sat-vm1.srv.mwn.de/terms_of_use.html) · [Method / metadata](https://osmfoundation.org/wiki/Licensing_Working_Group/Minutes/2025-11-10).

### usgs_3dep — USGS 3DEP lidar and bare-earth DEM

**Coverage:** National baseline 99% available OR in progress FY2025; includes Alaska IfSAR; metro roof-cloud coverage requires inventory. **Accuracy:** QL2 point RMSEz 0.10m and >=2 pulses/m2; building height accuracy unverified. **Vintage:** Project-specific acquisition windows; not publication date.

**Method / definition:** Roof cloud/derived DSM minus same-survey terrain. **Label:** observed_derived/lidar if QC passes.

**Licence:** Free without use restrictions per USGS; commercial redistribution derivatives supported. **Commercial:** Yes under stated provider policy; exact package/external partner exceptions check. **Redistribution:** Free without use restrictions per USGS; commercial redistribution derivatives supported. **Derivatives:** Free without use restrictions per USGS; commercial redistribution derivatives supported.

**Metro processing:** Estimated medium/high; 20–200 vCPUh per 1000km2 simple QL2 pipeline; UNVERIFIED.

**Verification:** Program license/QL verified; all-metro availability and building error unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www.usgs.gov/3d-elevation-program) · [Licence / terms evidence](https://www.usgs.gov/3d-elevation-program) · [Method / metadata](https://www.usgs.gov/3d-elevation-program).

### canada_hrdem — NRCan HRDEM DSM/DTM

**Coverage:** Regional expanding coverage; no all-metro guarantee. **Accuracy:** 1–2m raster sampling; project accuracy and building error require metadata. **Vintage:** Project acquisition window; mosaic mixed vintage.

**Method / definition:** Paired lidar DSM minus DTM; exclude unpaired satellite products. **Label:** observed_derived/lidar with project metadata.

**Licence:** Open Government Licence - Canada (official catalog verified by lead). **Commercial:** Yes with OGL terms. **Redistribution:** Yes with attribution and terms/exclusions. **Derivatives:** Adaptation/commercial derivatives allowed with OGL terms.

**Metro processing:** Estimated low/medium raster; UNVERIFIED.

**Verification:** Official catalog licence/resolution/datum verified by lead; coverage/roof error unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://open.canada.ca/data/en/dataset/957782bf-847c-4644-a757-e383c0057995?res_page=1) · [Licence / terms evidence](https://open.canada.ca/en/open-government-licence-canada) · [Method / metadata](https://natural-resources.canada.ca/maps-tools-publications/satellite-elevation-air-photos/national-elevation-data-strategy).

### canada_lidar — NRCan LiDAR Point Clouds

**Coverage:** Regional expanding; launch page nearly 60000km2 is not current audited coverage. **Accuracy:** Project-specific; height error unverified. **Vintage:** Acquisition-specific.

**Method / definition:** Ground-normalized roof point extraction. **Label:** observed_derived/lidar.

**Licence:** Open Government Licence; commercial redistribution derivatives with attribution. **Commercial:** Yes under stated provider policy; exact package/external partner exceptions check. **Redistribution:** Open Government Licence; commercial redistribution derivatives with attribution. **Derivatives:** Open Government Licence; commercial redistribution derivatives with attribution.

**Metro processing:** Estimated medium/high; UNVERIFIED.

**Verification:** License verified; present coverage unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://natural-resources.canada.ca/science-data/science-research/geomatics/new-lidar-point-clouds-product-canada-you-ve-never-seen) · [Licence / terms evidence](https://open.canada.ca/en/open-government-licence-canada) · [Method / metadata](https://natural-resources.canada.ca/science-data/science-research/geomatics/new-lidar-point-clouds-product-canada-you-ve-never-seen).

### ahn_lidar — AHN DTM DSM LAZ

**Coverage:** National multi-cycle; latest tile availability inspect. **Accuracy:** AHN2–4 points <=0.05m stochastic and <=0.05m systematic; building error unverified. **Vintage:** AHN3 2014–2019; AHN4 2020–2022; newer cycles tile-specific.

**Method / definition:** Use 3DBAG first; AHN normalized clouds/paired 0.5m rasters for refresh. **Label:** observed_derived/lidar.

**Licence:** Official AHN says open without conditions; exact CC0 metadata unverified. **Commercial:** Yes under stated provider policy; exact package/external partner exceptions check. **Redistribution:** Official AHN says open without conditions; exact CC0 metadata unverified. **Derivatives:** Official AHN says open without conditions; exact CC0 metadata unverified.

**Metro processing:** Estimated low/medium raster; higher roof reconstruction; UNVERIFIED.

**Verification:** Product policy/older point accuracy verified; newest complete coverage/license identifier unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www.ahn.nl/dataroom) · [Licence / terms evidence](https://www.ahn.nl/over-het-programma-ahn) · [Method / metadata](https://www.ahn.nl/dataroom).

### ea_lidar — Environment Agency Composite DSM/DTM

**Coverage:** ~99% England DSM 1m; not whole UK. **Accuracy:** Input surveys +/-0.15m RMSE; building height error unverified. **Vintage:** 2022 composite includes surveys 2000-06-06 to 2022-04-02; inspect survey index.

**Method / definition:** Prefer timestamped paired surveys; DSM-DTM roof statistics. **Label:** observed_derived/lidar.

**Licence:** OGL; commercial redistribution derived permitted with EA attribution. **Commercial:** Yes under stated provider policy; exact package/external partner exceptions check. **Redistribution:** OGL; commercial redistribution derived permitted with EA attribution. **Derivatives:** OGL; commercial redistribution derived permitted with EA attribution.

**Metro processing:** Estimated low/medium raster; UNVERIFIED.

**Verification:** Coverage/license/input accuracy verified; building error unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www.data.gov.uk/dataset/cf3f1137-c12b-44a1-a835-e80fe4a60b92/lidar-composite-dsm-2022-1m) · [Licence / terms evidence](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) · [Method / metadata](https://www.data.gov.uk/dataset/cf3f1137-c12b-44a1-a835-e80fe4a60b92/lidar-composite-dsm-2022-1m).

### wales_lidar — Welsh Government lidar DSM DTM

**Coverage:** Official NRW says whole Wales 1m; inspect tile gaps. **Accuracy:** 1m sampling; project vertical/building accuracy unverified. **Vintage:** 2020–2022 plus historic archive.

**Method / definition:** Paired DSM/DTM COG/tile processing. **Label:** observed_derived/lidar.

**Licence:** OGL in Data Map Wales; commercial redistribution derived with attribution. **Commercial:** Yes under stated provider policy; exact package/external partner exceptions check. **Redistribution:** OGL in Data Map Wales; commercial redistribution derived with attribution. **Derivatives:** OGL in Data Map Wales; commercial redistribution derived with attribution.

**Metro processing:** Estimated low/medium raster; UNVERIFIED.

**Verification:** Viewer license/access verified; current coverage QA needed; older NRW download note conflicts. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://datamap.gov.wales/maps/lidar-viewer/) · [Licence / terms evidence](https://datamap.gov.wales/maps/lidar-viewer/) · [Method / metadata](https://datamap.gov.wales/maps/lidar-viewer/).

### gsi_lidar — GSI high precision DEM1A and point clouds

**Coverage:** Regional published extents; no national building coverage claim. **Accuracy:** DEM1A 1m grid; point density/roof classification/error unverified. **Vintage:** DEM1A introduced 2023-11; DEM scope expanded 2026-07-31; point-cloud scope expanded 2026-09-30; acquisition dates must inspect.

**Method / definition:** PLATEAU first; regional clouds as future gap fill; DEM alone gives no roof height. **Label:** observed_derived/lidar only after QC/legal verification.

**Licence:** UNVERIFIED reuse/redistribution/derived and Survey Act workflow for downloaded cloud. **Commercial:** UNVERIFIED for downloaded cloud and Survey Act workflow. **Redistribution:** UNVERIFIED reuse/redistribution/derived and Survey Act workflow for downloaded cloud. **Derivatives:** UNVERIFIED reuse/redistribution/derived and Survey Act workflow for downloaded cloud.

**Metro processing:** Estimated medium/high cloud; UNVERIFIED.

**Verification:** Current publication availability verified; license/density/building accuracy unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://www.gsi.go.jp/gazochosa/gazochosa41022.html) · [Licence / terms evidence](UNVERIFIED) · [Method / metadata](https://www.gsi.go.jp/gazochosa/gazochosa41022.html).

### osm_height_levels — OpenStreetMap height / building:levels

**Coverage:** Buildings with volunteered tags; completeness varies, not universal. **Accuracy:** Unknown per-building; explicit height tag is not proof of measurement; 3 m per level is a renderer fallback, not a measured accuracy. **Vintage:** OSM edit timestamp is not measurement date; retain source:height and source survey date if present.

**Method / definition:** Inference/reported tag semantics; see source evidence and README. **Label:** explicit tag=reported_unknown unless measurement provenance; levels conversion=inferred_levels.

**Licence:** ODbL 1.0. **Commercial:** Allowed with obligations. **Redistribution:** OSM and derivative databases under ODbL; attribution. **Derivatives:** Height-enhanced OSM database generally derivative; produced-work requirements apply.

**Metro processing:** UNVERIFIED planning estimate: 1M tagged footprints parse/convert 1–10 CPU-hours plus I/O, excluding acquisition and spatial joins.

**Verification:** Verified tag semantics/licence; actual metro coverage/accuracy/cost unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://wiki.openstreetmap.org/wiki/Key:building:levels) · [Licence / terms evidence](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ) · [Method / metadata](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ).

### urban_form_xgboost — Milojevic-Dupont et al. 2020 urban-form inference

**Coverage:** Predicts where usable footprints/features exist; not a ready guaranteed US dataset. **Accuracy:** 1.47 m MAE averaged four validation areas; held-out Brandenburg 1.72 m; Berlin 2.98 m; tall-building errors worse. **Vintage:** 2020 publication; outputs inherit input imagery/footprint dates.

**Method / definition:** Inference/reported tag semantics; see source evidence and README. **Label:** inferred_ml.

**Licence:** Article CC BY; input datasets retain their own licences; code/output licence must be checked separately. **Commercial:** Method can be implemented; input rights required. **Redistribution:** Input/output licence dependent; paper licence is not data licence. **Derivatives:** OSM-feature augmentation retains ODbL obligations; independently derived geometry has different analysis.

**Metro processing:** Paper training on full dataset: XGBoost hours on single CPU; current metro cost UNVERIFIED.

**Verification:** Verified research results; deployment rights/performance/cost unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0242010) · [Licence / terms evidence](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines) · [Method / metadata](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines).

### germany_xgboost_2024 — Dabrock et al. 2024 height imputation methodology

**Coverage:** Nationwide mixed measured/reported/derived/imputed workflow; missing heights filled using XGBoost. **Accuracy:** ML component 1.78 m MAE national, 1.52–3.47 m by state; mixed final-dataset accuracy must not be quoted as ML accuracy. **Vintage:** Published 2024; training raw model data reference years differ.

**Method / definition:** Inference/reported tag semantics; see source evidence and README. **Label:** inferred_ml for imputed records; preserve reported/observed source labels elsewhere.

**Licence:** Article CC BY 4.0; input/output data licences separate. **Commercial:** Method implementable; input rights required. **Redistribution:** Dataset and code terms require separate verification. **Derivatives:** Provenance follows original source; imputation does not remove ODbL.

**Metro processing:** UNVERIFIED planning estimate: feature generation/inference for 1M buildings 10–100 CPU-hours, 16–64 GB RAM; local training/QA extra.

**Verification:** Verified research results; requested-country deployment unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://publications.rwth-aachen.de/record/992601/files/992601.pdf) · [Licence / terms evidence](https://creativecommons.org/licenses/by/4.0/) · [Method / metadata](https://creativecommons.org/licenses/by/4.0/).

### biljecki_rf_2017 — Biljecki et al. 2017 cadastral / footprint inference

**Coverage:** Rotterdam/Leeuwarden; data-rich attribute scenarios, not universal heights. **Accuracy:** Best scenario MAE 0.8 m; cannot claim footprint-only model universally achieves 0.8 m. **Vintage:** 2017 paper; output inherits cadastral vintage.

**Method / definition:** Inference/reported tag semantics; see source evidence and README. **Label:** inferred_ml or inferred_archetype.

**Licence:** Author manuscript CC BY-NC-ND; method is a research description; dataset/input/code licences separate. **Commercial:** Do not redistribute manuscript commercially under NC terms; independent method implementation requires usable data rights. **Redistribution:** Input/output terms require separate review. **Derivatives:** Source-dependent.

**Metro processing:** UNVERIFIED planning estimate: archetype/levels baseline 1–10 CPU-hours per 1M rows; feature joins dominate.

**Verification:** Verified research result; input/code/output rights and transfer performance unverified. **Unverified:** Metro completeness; building-height error/calibration; actual compute cost; acquisition metadata; package exceptions unless explicitly established in sources.md.

[Provider / primary evidence](https://3d.bk.tudelft.nl/news/2017/01/17/inferring-heights-ceus-paper.html) · [Licence / terms evidence](https://filipbiljecki.com/publications/2017_ceus_inferring_heights.pdf) · [Method / metadata](https://filipbiljecki.com/publications/2017_ceus_inferring_heights.pdf).

### scotland_lidar — Scottish Remote Sensing Portal

**Coverage:** Public-sector lidar tiles; national and metro coverage unverified. **Accuracy:** UNVERIFIED local height error; resolution/spec is not building error. **Vintage:** Per survey/input; unverified until metadata audit.

**Method / definition:** Inspect paired DSM/DTM or normalized clouds by tile. **Label:** measured_derived_lidar only after QA.

**Licence:** OGL v3 unless otherwise stated; per-package exception check. **Commercial:** Yes under OGL terms unless exception. **Redistribution:** OGL terms and attribution unless exception. **Derivatives:** OGL derivatives allowed unless exception.

**Metro processing:** UNBENCHMARKED: paired raster 4–30 vCPUh/1000km2; cloud 20–200 vCPUh at QL2-like density; not a provider benchmark.

**Verification:** Portal policy verified; coverage/error/cost unverified. **Unverified:** Exact tile/metro coverage, observation vintage, local roof error, exceptions, actual cost.

[Provider / primary evidence](https://remotesensingdata.gov.scot/about) · [Licence / terms evidence](https://remotesensingdata.gov.scot/about) · [Method / metadata](https://remotesensingdata.gov.scot/about).

### ni_lidar — Northern Ireland lidar project inventory

**Coverage:** Partial project archive candidate; all-metro coverage UNVERIFIED. **Accuracy:** UNVERIFIED local height error; resolution/spec is not building error. **Vintage:** Per survey/input; unverified until metadata audit.

**Method / definition:** Candidate LAS surveys only; footprint and ground coverage audit needed. **Label:** measured_derived_lidar only after QA.

**Licence:** UNVERIFIED per project; no blanket redistribution permission established. **Commercial:** UNVERIFIED exact inputs/package rights. **Redistribution:** Input/package dependent; UNVERIFIED. **Derivatives:** Input-dependent; no rights laundering through inference.

**Metro processing:** UNBENCHMARKED: paired raster 4–30 vCPUh/1000km2; cloud 20–200 vCPUh at QL2-like density; not a provider benchmark.

**Verification:** Candidate/proposed method; indicated items UNVERIFIED. **Unverified:** Exact tile/metro coverage, observation vintage, local roof error, exceptions, actual cost.

[Provider / primary evidence](https://admin.opendatani.gov.uk/tl/dataset/?_res_format_limit=0&res_format=LAS) · [Licence / terms evidence](https://admin.opendatani.gov.uk/tl/dataset/?_res_format_limit=0&res_format=LAS) · [Method / metadata](https://admin.opendatani.gov.uk/tl/dataset/?_res_format_limit=0&res_format=LAS).

### archetype_prior — WorldEngine proposed levels/vintage/archetype fallback

**Coverage:** Any footprint with usable evidence; no universal error guarantee. **Accuracy:** UNVERIFIED local height error; resolution/spec is not building error. **Vintage:** Per survey/input; unverified until metadata audit.

**Method / definition:** Country/use/era/roof-conditioned floor-height and roof-allowance distribution. **Label:** inferred_levels or inferred_archetype.

**Licence:** Implementation/input/model licences separately checked. **Commercial:** UNVERIFIED exact inputs/package rights. **Redistribution:** Input/package dependent; UNVERIFIED. **Derivatives:** Input-dependent; no rights laundering through inference.

**Metro processing:** UNBENCHMARKED: 1–10 vCPUh/1M rows; calibration/training/QA extra.

**Verification:** Candidate/proposed method; indicated items UNVERIFIED. **Unverified:** Exact tile/metro coverage, observation vintage, local roof error, exceptions, actual cost.

[Provider / primary evidence](https://wiki.openstreetmap.org/wiki/Key:building:levels) · [Licence / terms evidence](https://wiki.openstreetmap.org/wiki/Key:building:levels) · [Method / metadata](https://wiki.openstreetmap.org/wiki/Key:building:levels).

## Detailed research notes and additional primary links

The following notes retain each track’s reasoning. The corrections above and README supersede the initial HRDEM fetch caveat and blanket Google target-country exclusion. All temporary working-file references are removed from the deliverable.

### Open height data findings — checked 2026-10-07

#### Decision
Use permissive raw footprints and national/municipal measured data for a licensable master. Keep OSM/Overture enrichment in a separate provenance and licensing track. A source publishing footprints globally does not mean its height field covers every building. No examined source establishes measured heights for every US metro.

#### Overture
Global buildings with optional `height` (lowest-to-highest in meters), `num_floors`, `roof_height`, parts; monthly releases. Latest guide lists 2026-09-23.1. Buildings are ODbL because they include OSM; commercial use is possible, but attribution and applicable adapted-database share-alike/open obligations matter. Preserve per-property sources, not just footprint source. No verified national height completeness or height-error guarantee. Label height method unknown unless upstream provenance establishes measurement versus inference. GeoParquet bbox queries permit metro subsets; processing estimate 1–8 CPU-hours / $1–20 for a million-building join, excluding engineering and data egress; UNBENCHMARKED.
Sources: [Primary source](https://docs.overturemaps.org/guides/buildings/) ; [Primary source](https://docs.overturemaps.org/schema/reference/buildings/building/)

#### Microsoft GlobalMLBuildingFootprints
Raw data under CDLA Permissive 2.0; height above ground is neural-network inference averaged over each polygon; -1 means missing. Confidence is explicitly footprint confidence, NOT height confidence. Includes North America and Western Europe heights; current metro completeness requires tile inventory, no verified height RMSE. Release 2026-08-13; source imagery varies, some 2026 US additions from 2021–2025. Older README totals/vintage text conflict with update log; avoid treating old 174M height count as current. Quadkey gzipped GeoJSONL; estimate 1–8 CPU-hours / $1–20 per million buildings; UNBENCHMARKED. Retain license text on sharing raw/modified data; results have no license condition under section 3. Label `inferred_imagery_ml`.
Sources: [Primary source](https://github.com/microsoft/GlobalMLBuildingFootprints) ; [Primary source](https://cdla.dev/permissive-2-0/)

#### Google Open Buildings
Footprints v3 are separate from Open Buildings 2.5D Temporal V1 height rasters. Temporal data cover Africa, South/Southeast Asia, Latin America and Caribbean, annual 2016–2023; effective 4 m despite 0.5 m stored pixels. Not a primary solution for the five mainland markets; Caribbean US territories need explicit extent checks. CC BY 4.0 or ODbL choice; direct cloud download avoids confusing open data license with Earth Engine commercial platform terms. Height model output is inference, not measured DSM. No country-specific error verified here. For covered regions raster zonal statistics estimate 4–30 CPU-hours / $5–100 per 1,000 km², UNBENCHMARKED.
Sources: [Primary source](https://developers.google.cn/earth-engine/datasets/catalog/GOOGLE_Research_open-buildings-temporal_v1?hl=en) ; [Primary source](https://sites.research.google/gr/open-buildings/)

#### Netherlands 3DBAG
National 3D building reconstruction from BAG and AHN; CC BY 4.0. Download release v2025.09.03; release notes show AHN5 incorporated since 2024.12.16, so AHN3/4-only sources documentation is stale. Tile-specific acquisition metadata and quality attributes essential. Elevation attributes are not automatically height above local terrain; normalize roof minus ground using schema definitions. AHN point precision is not reconstructed building accuracy. Label `observed_lidar_derived` with roof statistic and capture date; failed reconstruction remains unknown. LoD1/2 CityJSON/GeoPackage/3D Tiles available. Estimate 1–8 CPU-hours / $1–30 for million-building scalar extraction, UNBENCHMARKED.
Sources: [Primary source](https://3dbag.nl/download) ; [Primary source](https://docs.3dbag.nl/nl/overview/release_notes/) ; [Primary source](https://docs.3dbag.nl/en/schema/attributes/) ; [Primary source](https://docs.3dbag.nl/nl/overview/sources/)

#### Canada ODB and Vancouver
StatCan ODB v3 approximately 14.4M buildings, OGL Canada; height/floors/year_built attributes are supplied by upstream sources, optional coverage and method vary. Release April 15 2025. No nationwide height completeness/accuracy claim verified; audit upstream provenance. Label `source_reported_unknown` until method established. Vancouver 2009 footprints provide LiDAR-derived component top/base/HGT_AGL and average heights, OGL Vancouver (commercial, distribute, adapt with attribution). Useful methodology and validation baseline but 2009 vintage too old as sole current city source. Estimate each vector subset 1–8 CPU-hours / $1–30, UNBENCHMARKED.
Sources: [Primary source](https://www150.statcan.gc.ca/n1/pub/34-26-0001/2018001/metadata-eng.htm) ; [Primary source](https://www150.statcan.gc.ca/n1/daily-quotidien/250415/dq250415d-eng.htm) ; [Primary source](https://opendata.vancouver.ca/explore/dataset/building-footprints-2009/) ; [Primary source](https://opendata.vancouver.ca/pages/licence/) ; [Primary source](https://open.canada.ca/en/frequently-asked-questions)

#### Japan PLATEAU
Official open-data list last updated 2026-05-11 counts 306 locations; does NOT imply complete Japan or all metro outskirts. CityGML models and attributes; city/LOD-specific methods, accuracy and acquisition dates must be audited. Generally CC BY 4.0/government terms, also ODC BY/ODbL variants, so use exact package license. Commercial reuse, modification and redistribution with credit explicitly supported; Survey Act and excluded third-party content may require checking. Label measured photogrammetry/airborne-derived only when documented, otherwise `source_reported_unknown`. Extract LoD1 vertical bounds/ground or documented measuredHeight, preserving height convention. Estimate 4–30 CPU-hours / $5–100 per million buildings for XML parsing and scalar extraction; UNBENCHMARKED.
Sources: [Primary source](https://www.mlit.go.jp/plateau/open-data/) ; [Primary source](https://www.mlit.go.jp/plateau/start-guide/) ; [Primary source](https://www.mlit.go.jp/plateau/site-policy/) ; [Primary source](https://www.mlit.go.jp/report/press/toshi03_hh_000078.html)

#### UK OS heights
OS MasterMap building-height attributes exist; NGD access is for OS Partners/PSGA members. These official sources do not establish an open redistribution right. Treat as commercial negotiated source; raw redistribution/derived rights, price and country/metro coverage UNVERIFIED pending contract. Great Britain != whole UK; Northern Ireland separately audited. Do not infer OGL from a data.gov.uk catalog entry (licence there is 'Not set'). Prefer open national lidar plus permissive footprints for default. Source: [Primary source](https://docs.os.uk/osngd) ; [Primary source](https://www.data.gov.uk/dataset/7624f5d0-899e-4f38-93a6-22f6b915befe/os-mastermap-building-height-attribute)

#### NYC representative municipal heights
NYC BUILDING roof-height and ground-elevation fields; current portal September 13 2026, but edit time is not measurement vintage. Official metadata identifies plan/as-built and controlled aerial/terrestrial measurement sources; direct roof height is above-ground, ensure unit conversion (US-foot CRS alone does not prove attribute unit). Attribute unit, accuracy, individual observation date and exact redistribution terms remain UNVERIFIED in this pass. Portal policy states public resource without restriction/licensing requirements, subject to terms and agency exceptions. Vector estimate 1–8 CPU-hours / $1–30; UNBENCHMARKED.
Sources: [Primary source](https://data.cityofnewyork.us/City-Government/BUILDING/5zhs-2jue) ; [Primary source](https://github.com/CityOfNewYork/nyc-geo-metadata/blob/main/Metadata/Metadata_BuildingFootprints.md) ; [Primary source](https://www.nyc.gov/assets/doitt/downloads/pdf/nyc_open_data_tsm.pdf)

#### Exclude from commercial baseline: GlobalBuildingAtlas
Global height/LoD1 product is ML-derived; dataset terms CC BY-NC 4.0. Its code license adds Commons Clause restriction and is separate from dataset rights. OSM Foundation minutes also document a rights compatibility issue involving commercial imagery and OSM; do not assume 'open' marketing means commercial redistribution. Do not train commercial production inference with it without separate permission. Sources: [Primary source](https://tubvsig-so2sat-vm1.srv.mwn.de/terms_of_use.html) ; [Primary source](https://github.com/zhu-xlab/GlobalBuildingAtlas/blob/main/LICENSE) ; [Primary source](https://osmfoundation.org/wiki/Licensing_Working_Group/Minutes/2025-11-10)


### Lidar-derived building heights: evidence and recommended method
Research checked 2026-10-07. Recommendations and compute budgets below are engineering estimates, not provider guarantees or measured benchmarks.

#### United States
[USGS 3DEP](https://www.usgs.gov/3d-elevation-program) states all program products are free without use restrictions: commercial reuse, redistribution and derived heights are supported. Keep project metadata and provenance anyway. External state/local files outside the 3DEP distribution require their own license check.

[USGS program status](https://www.usgs.gov/3d-elevation-program/what-3dep) reports 99% of the nation had baseline data **available or in progress** at FY2025 end. That is not 99% downloadable roof lidar: Alaska baseline includes IfSAR; availability, coverage gaps and completed release must be checked in each metro. [Work Unit spatial metadata / access](https://www.usgs.gov/3d-elevation-program) and [coverage viewers](https://www.usgs.gov/faqs/what-coverage-3d-elevation-program-3dep-dems) provide project-level discovery. Use acquisition dates, not publication dates. Current repeat collection is uneven; there is no nationally synchronous current roof survey. [Next-generation plan](https://pubs.usgs.gov/publication/cir1553/full) discusses repeat acquisition where existing data is five or more years old.

[Quality levels](https://www.usgs.gov/3d-elevation-program/topographic-data-quality-levels-qls): QL2 minimum density 2 pulses/m², 10 cm vertical RMSEz, typical 1m DEM; QL1 8 pulses/m² and 10 cm; QL0 8 pulses/m² and 5cm. These describe sensor/terrain positional quality, **not** guaranteed building-height error. Download the per-project report. Some older material uses 9.25cm for QL2; current table uses 10cm. [Current LBS](https://www.usgs.gov/ngp-standards-and-specifications/lidar-base-specification-online) is 2025 rev. A. Do not assume every point cloud has building class 6; [historic detailed building classification is an optional upgrade](https://pubs.usgs.gov/tm/11b4/pdf/tm11-B4.pdf), and [revision history](https://www.usgs.gov/ngp-standards-and-specifications/LiDAR-base-specification-revision-history) distinguishes required classification and optional additional classes. Inspect actual class distribution.

#### Method (engineering recommendation)
1. Inventory footprints, survey extents and acquisition windows; reject footprints built after the survey or whose geometry moved. Read CRS, vertical datum, units and class quality. Process tiles with halo buffers and deduplicate overlapping flight returns.
2. Prefer normalized point clouds: roof Z minus local ground interpolation from class 2. [PDAL height-above-ground filter](https://pdal.org/en/latest/stages/filters.hag_delaunay.html) uses classified ground and triangulated local ground interpolation, with edge/extrapolation behavior that must be controlled. A roof interpolated over a large ground gap is uncertain.
3. Alternatively produce a roof DSM and ground DTM from the **same survey** on the same grid. USGS 1m DEM is generally bare earth, not a roof DSM: a DSM must be derived from cloud points unless supplied. Subtract DSM−DTM before footprint aggregation. Same-epoch/same-datum pairing prevents systematic errors. Avoid mixing coarse global terrain with high-resolution roofs.
4. Remove withheld/noise/water and vegetation contamination; use building classes if validated, otherwise robust planarity/roof classification. An eroded footprint interior limits boundary mixing; do not erase tiny buildings. Store valid coverage fraction and sample count. Trees over roofs, narrow terraces, small sheds, glass/metal roofs, rooftop plant, sloped sites and partial scans need flags.
5. Store several height definitions: roof median/p50, roof p95, eave estimate if supported, and ground-reference elevation; preserve roof range and building-part heights. P95 is a robust upper roof proxy, not necessarily ridge height or the legal building maximum. The raw maximum may be a chimney, antenna, tree or noise. A single scalar extrusion cannot reproduce stepped towers or pitched roofs.
6. QA against independent measured heights or held-out official 3D models, stratified by low-rise/high-rise/industrial/trees/slope/vintage. Report median bias, MAE, RMSE and p90 absolute error plus missingness. Do not advertise 10cm roof-height accuracy from QL2 metadata.

Uncertainty: for independent roof and ground positional errors, sqrt(sigma_roof²+sigma_ground²) is a useful lower-bound propagation model; shared systematic survey error may cancel. Classification, interpolation, footprint mismatch and vintage error dominate many buildings and invalidate that bound. Working acceptance targets of 0.5–1m for clean roofs and 1–3m for contaminated/problem cases are **UNVERIFIED planning targets** until local evaluation. Failed cases must fall back to inferred or unknown rather than being labelled observed.

Label successful extraction `observed_derived/lidar`, with acquisition window, processing version, roof/ground statistic, footprint source/version, point count, valid fraction, CRS/datum and QA flags. Derived from measurement is distinct from directly surveyed authoritative height and from learned inference. Roof extraction with unsupported ground or stale/mismatched geometry gets downgraded.

#### Compute at metro scale (UNVERIFIED engineering budget)
For 1,000km²: QL2 nominally implies 2 billion pulses (all returns can exceed this), QL1 8 billion. A pair of 1m float32 raster layers is 8GB uncompressed before masks/overviews; 0.5m is 32GB. LAZ storage depends strongly on density, returns and attributes; reserve 50–250GB input+scratch at QL2 and several times that at QL1, and benchmark before procurement. Raster subtraction/zonal statistics are low-to-medium cost; cloud classification/roof fitting are medium-to-high. Initial placeholder budget 20–200 vCPU-hours plus storage/transfer for simple QL2 tile processing; denser clouds, reclassification and geometry QA may multiply this. This is **not measured** and is not a dollar quote. Use actual provider rates and a 25–100km² pilot. Metro areas can exceed 10,000km², so scale by processed area and density, and stream only covered footprint tiles. Separate engineering and manual QA labor from compute cost.

#### Canada
[NRCan elevation strategy](https://natural-resources.canada.ca/maps-tools-publications/satellite-elevation-air-photos/national-elevation-data-strategy) provides HRDEM at 1–2m including DSM and, for lidar projects, DTM. Regional project products have acquisition-level provenance; the national mosaic is convenient for discovery but can mix vintages. Coverage is expanding, not a guaranteed all-metro roof product. [NRCan point clouds](https://natural-resources.canada.ca/science-data/science-research/geomatics/new-lidar-point-clouds-product-canada-you-ve-never-seen) are under Open Government Licence; the page's nearly 60,000km² launch-era figure is not verified current coverage. [HRDEM catalog](https://open.canada.ca/data/en/dataset/957782bf-847c-4644-a757-e383c0057995?res_page=1) provides product specifications; the initial fetch failed, but the lead subsequently verified the catalog licence as Open Government Licence - Canada. Project-specific accuracy and coverage still require metadata checks before ingest. Provincial/municipal portals may have additional cover and differing licenses; a [2026 NRCan newsletter](https://publications.gc.ca/collections/collection_2026/rncan-nrcan/m45/M45-160-2026-eng.pdf) explicitly warns some partner lidar can have restricted licenses. Government OGL permits adaptation and redistribution for lawful use with attribution; [government guidebook](https://publications.gc.ca/collections/collection_2024/sct-tbs/BT22-278-2023-eng.pdf) confirms source identification on derived products. Use paired lidar DSM/DTM first, cloud extraction next, inference only in gaps. Satellite HRDEM is not equivalent to lidar and may lack paired ground surface.

#### Netherlands
[AHN data](https://www.ahn.nl/dataroom) supplies national 0.5m/5m DTM and surface rasters and LAZ clouds; AHN3+ classifications can distinguish buildings. [AHN policy](https://www.ahn.nl/over-het-programma-ahn) says fully open without conditions; commercial/redistribution/derived use is supported by that statement, but archive the exact dataset license metadata (CC0 identification not independently verified here). [Quality](https://www.ahn.nl/kwaliteitsbeschrijving) gives AHN2–4 point vertical standard deviation ≤5cm and systematic deviation ≤5cm; this is not a roof-height guarantee. Acquisition cycles are tile-specific (AHN3 2014–2019, AHN4 2020–2022); do not assume latest AHN5/6 national release or density from these older quality statements. Prefer prebuilt 3DBAG models (covered by dataset agent) and use AHN for gaps/refreshes. Raster cost low-to-medium, cloud roof reconstruction higher.

#### United Kingdom
[EA DSM catalog](https://www.data.gov.uk/dataset/cf3f1137-c12b-44a1-a835-e80fe4a60b92/lidar-composite-dsm-2022-1m) reports ~99% **England**, 1m raster, survey dates 2000-06-06 through 2022-04-02 and ±15cm input vertical RMSE. Last/only-return DSM includes buildings/vegetation; use same-survey DTM and metadata index rather than treating publication/update date as survey vintage. Building-height accuracy must be evaluated. [OGL v3](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) permits commercial exploitation, redistribution and adaptation with attribution; retain EA attribution. England is not whole UK. [Welsh official viewer](https://datamap.gov.wales/maps/lidar-viewer/) supplies 2020–2022 tile links plus DTM/DSM COGs under OGL; [NRW](https://www.naturalresourceswales.gov.uk/evidence-and-data/maps/peatland-data-portal-map-layers/?lang=en) says 1m whole Wales collection but its download note conflicts with current viewer, so prefer current tile inspection. Scotland and Northern Ireland availability/licensing need a separate metro inventory; national completeness not verified. Cost low-to-medium for paired rasters, plus footprint licensing and QA.

#### Japan
[GSI high precision elevation](https://www.gsi.go.jp/gazochosa/gazochosa41022.html) now distributes airborne-lidar DEM and point clouds: DEM1A began Nov2023, 1m DEM coverage expanded Jul31 2026, pointcloud extent expanded Sep30 2026. Avoid outdated claim that all Japan elevation is only 5m. Coverage is regional; current cloud density, roof classification, download rights/Survey Act procedures and roof-height accuracy are **UNVERIFIED** here. [DEM5A source-year viewer](https://maps.gsi.go.jp/legend/attension_dem5a_area.html) shows terrain-source acquisition year, not roof height. Prefer PLATEAU where available; investigate GSI point clouds as regional gap fill only after metadata and reuse terms pass. Do not use terrain DEM alone as building height.


### Inference findings (2026-10-07)
#### Recommended fallback ladder
After compatible measured/city-model/lidar heights: accept explicit height only with provenance and definition checks; use observed floor counts to infer height; use locally calibrated tabular ML; then an explicitly low-confidence archetype default. A footprint alone does not identify vertical extent; never market an imputed roof as a measurement.

#### Tag semantics
[OSM height](https://wiki.openstreetmap.org/wiki/Key:height) represents maximum roof height above the lowest terrain contact, including roof but excluding mounted equipment. [min_height](https://wiki.openstreetmap.org/wiki/Key:min_height) is the feature bottom above ground; top height is not reduced by it. [building:levels](https://wiki.openstreetmap.org/wiki/Key:building:levels) includes ground floor, excludes roof and underground levels. Treat floor counts as evidence, with the metric height inferred. Parse explicit units; check part/parent overlap, roof height double counting, levels/min-level inconsistency, fractional/invalid levels, slope and podium/tower mismatch. A literal 3 m/storey fallback is a visualization convention. Use h = ground_floor_height + (levels-1)*typical_storey_height + roof_allowance where valid; fit these distributions to matched local measurements by use/era/roof type. Warehouse/sports halls require separate treatment. Suggested constants without validation remain UNVERIFIED.

#### Evidence and limits
[Biljecki et al. (2017)](https://3d.bk.tudelft.nl/news/2017/01/17/inferring-heights-ceus-paper.html): best 2D/cadastral attribute scenario achieved 0.8 m MAE; it is not a universal footprint-only guarantee.
[Milojevic-Dupont et al. (2020)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0242010): urban-form XGBoost 1.47 m MAE over geographically separate European validation areas; transfer Brandenburg 1.72 m, Berlin 2.98 m; tall buildings were difficult and adding local observations improved results. Single-CPU training took hours for XGBoost. Article CC BY does not license all inputs.
[Dabrock et al. (2024)](https://publications.rwth-aachen.de/record/992601/files/992601.pdf): German XGBoost imputation 1.78 m MAE overall, 1.52–3.47 m across states. Separate mixed-dataset final accuracy from inference accuracy. No US/Canada/UK/Japan guarantee.

#### Legal partition
[ODbL text](https://opendatacommons.org/licenses/odbl/1-0/) and [OSMF FAQ](https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ) allow commercial use, require attribution and share-alike for distributed derivative databases, and impose derivative database availability for public produced works. Height enrichment of OSM buildings is an enhanced database; a separately stored height table is not by itself a legal escape.
[OSMF ML attribution guideline](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines) says substantial OSM training extracts are derivative databases, models require attribution, and fresh-imagery predictions are generally not implicated unless reconstructing OSM. This specific example does not establish that height predictions attached to OSM geometries shed ODbL. For proprietary licensing prefer independent footprints/measurements under permissive terms, keep OSM derivatives in a documented ODbL branch, and review exact conflation/distribution design.

#### Proposed confidence record (engineering proposal)
Separate evidence class from quality: observed_sensor, observed_survey, reported_authoritative, reported_unknown, inferred_levels, inferred_ml, inferred_archetype, missing. Preserve source IDs, input licences, acquisition/reference dates, footprint date, height definition/statistic (ridge/eave/P95/mean), ground reference, model/version, matching IoU, vegetation/roof QC, and conflict flags. Explicit OSM height with no provenance is reported_unknown.
Store h_best plus calibrated p05/p95 (or documented 90% interval), and confidence_reason. Do not manufacture a numerical probability from a source class. Unknown uncertainty must remain null. Proposed display grades: A = locally validated measured/authoritative source and strong geometric match; B = valid source with minor issues or calibrated levels; C = calibrated inference; D = uncalibrated/out-of-domain/default. Grades are policy proposals, not accuracy guarantees.

#### Validation
Use independent held-out spatial blocks and leave-one-metro-out tests; split by acquisition campaign to prevent nearby-roof leakage. Report coverage, MAE, RMSE, median bias, P90/P95 absolute error, ±1/±3/±5 m rates, interval coverage and width, stratified by height/use/era/density/terrain. Compare roof-height definitions before scoring. Sample skyscrapers, malls, warehouses, sloped homes, vegetation, courtyards and new builds separately. Prefer quantile models plus held-out/conformal calibration where exchangeability is defensible; inspect drift/out-of-domain features and refuse high confidence outside calibration range.

#### Cost planning (UNVERIFIED, not benchmarked or supplier quotes)
For 1M buildings, simple levels/archetype conversion: 1–10 CPU-hours including ordinary table handling but excluding acquisition; spatial urban-form feature generation and inference: 10–100 CPU-hours, approximately 16–64 GB working RAM with tiled joins. Training, city data integration and QA are separate. At an assumed $0.05–$0.15 per vCPU-hour this is $0.05–$1.50 or $0.50–$15 compute only; storage, egress and staff time can dominate. Benchmark one representative metro before budgeting the country. All values are planning assumptions; real performance depends strongly on joins, feature count, geometry complexity and implementation.

