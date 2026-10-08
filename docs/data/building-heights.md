# Survey-derived building heights

`Tools/regionkit/lidar/observed_heights.py` writes `Data/areas/<area>/building-heights.json` after a successful survey run. Verification requires its direct parent to own `~/.agent-heavy-lock/owner`; an abandoned lock cannot authorize it. Full-density acquisition is capped at 600 MB and scratch stays outside the repository. The pipeline is area-independent; its data configuration authorizes Sloan's Lake, Lakeview and Greenville Downtown, using identical measurement thresholds. Python/data work is separate from lock-required verification, following CLAUDE.md.

## Contract
The `records` object uses building refs. Roof top is p95 selected roof elevation minus class-2 ring ground from the same survey. Typical roof is p50; eave is the p15 edge-band proxy. Ground is median Z in a 3–8 m ring, expanding to 15 m only when needed. When the area survey has no class-6 returns, its class-1 returns are filtered inside eroded footprints above same-survey ground, then through the existing PCA-normal/region-growing plane extractor. At least 80% of eligible returns must support planes with pitch ≤75°; these are conservative general configuration defaults, not city-tuned or validated thresholds. Such records explicitly say `derived_planar_unclassified` and flag roof-classification uncertainty. No unrelated DEM or default value fills a missing measurement. The existing measurement thresholds, point counts, roof coverage, reason and source metadata are retained.

`evidence_code` is `measured_derived_lidar` only after sample/coverage/ground checks; otherwise `missing` and selected heights are null. These are QA-passing measurements, not an assertion that the 2020 survey represents the building today. Every uncalibrated record is grade D. A/B/C need independent local P90 absolute errors ≤1/3/5 m and passing QA. Confidence intervals remain null without calibration; point quality is not building-height accuracy.

Observed sidecar data remain distinct from OSM reported tags, levels-derived heights and renderer defaults. This data-only step does not overwrite OSM tags or claim the generator consumes the new file; consumption is a P2 handoff with the roof work. `base_elevation_m` is NAVD88 orthometric elevation, not WGS84 ellipsoid height. No geoid transformation is implied.

## Source and licence
USGS CO_DRCOG_2020_B20, delivery CO_DRCOG_2_2020. [Tile metadata](https://thor-f5.er.usgs.gov/ngtoc/metadata/waf/elevation/lidar_point_cloud/laz/CO_DRCOG_2_2020/USGS_LPC_CO_DRCOG_2020_B20_w0495n4399.xml), checked 8 October 2026: acquisition 26 May–12 June 2020, North American Vertical Datum 1988, metres. EPT metadata explicitly gives horizontal EPSG:3857; vertical information is from the linked source tile metadata, not inferred from the horizontal CRS. Dates represent the delivery tile metadata, not per-pulse dates.

[Provider registry](https://registry.opendata.aws/usgs-lidar/), checked 8 October 2026: US Government Public Domain; anonymous public EPT access. GREEN for this ingestion. Acknowledge USGS and describe the modifications; do not imply USGS endorsement. Linked source use constraints warn of temporal change. Output is derived p95/p50/eave AGL statistics and ground median, not raw lidar.

Footprints © OpenStreetMap contributors, ODbL 1.0. Building-linked output stays in the ODbL-enhanced branch; public-domain lidar does not erase footprint obligations. Building parts are currently excluded and must be called out in completeness reporting.

Reference: `docs/research-gpt/building-heights-v1/README.md`. No independent local height validation is claimed.

## General pipeline and hold-outs (R, 8 October)

Only boundaries, authorization and verified source metadata vary by area. `prepare_area.py` accepts an authorized rectangle, preserves its exact approved bounds in the manifest, and fetches OSM with the configured buffer and `out body` (no contributor metadata). It refuses HOLD areas and existing-area replacement. Greenville Downtown is authorized by the later general-pipelines request; Greer remains HOLD. The approved rectangles and 100 m buffer are unchanged.

Cook 2017 and South Carolina Savannah/PeeDee 2019 deliveries have NAVD88 elevations. The original LAS headers are in survey feet, but their EPT deliveries already contain metres. For each source, `observed-heights.json` records the source-header URL and min/max Z, EPT source-list URL and matching bounds: multiplication by 1200/3937 matches both EPT Z bounds within 0.000001 m. No second conversion is applied. This establishes the delivered unit, not height accuracy or survey currency. Greenville's source tile was acquired 5–22 January 2020 despite the 2019 project name; Cook was acquired 16 April–7 May 2017.

Run the same command with each configured area ID:
`python Tools/regionkit/lidar/observed_heights.py all --area AREA --work EXTERNAL_SCRATCH`
Missing values remain null, and uncalibrated grades remain D in every area. OSM buildings added since the survey can therefore remain missing without being imputed.

The common byte cap was raised from 200 MB to 600 MB after Lakeview required 275,805,345 bytes at full density. This changes the resource budget only; no decimation or area-specific cap is allowed. The 8 GB free-disk guard still applies.

## Hold-out results

| Area | Accepted / OSM footprints | Coverage | Null heights | Grades |
|---|---:|---:|---:|---|
| sloans-lake | 407 / 1399 | 29.1% | 992 | All D, uncalibrated |
| lakeview-sheil-park | 2618 / 2799 | 93.5% | 181 | All D, uncalibrated |
| greenville-downtown | 437 / 681 | 64.2% | 244 | All D, uncalibrated |

These are coverage results within available OSM footprints, not completeness against a building census and not measured accuracy. Lakeview uses vendor class-6 returns; Sloan and Greenville use the same conservative class-1 planar fallback. No area-specific thresholds or per-building edits were applied.
