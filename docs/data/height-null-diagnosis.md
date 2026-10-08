# Height nulls and West Highland proposal — 8 October 2026

Status: prior terrain/QA delivery merged to main as `8dcd910`. The diagnosis is read-only. The fallback and West Highland rectangle below await R; neither changes production data or code. All existing observed nulls are preserved.

## Why Sloan differs from Lakeview

The same accepted measurement rules produce 407/1,399 heights (29.1%) in Sloan and 2,618/2,799 (93.5%) in Lakeview. The surveys have different classification support: Denver has **zero class-6 building returns**, so the generic method must extract planar candidates from class-1 unclassified returns; Cook has vendor-classified class-6 returns. The unclassified branch additionally requires at least 80% of elevated candidates to belong to accepted planes.

Mutually exclusive rejection causes, applying the existing 15 m² size gate first (otherwise small buildings would be counted twice):

| Result / rejection cause | Sloan | Lakeview |
|---|---:|---:|
| Accepted height | 407 | 2,618 |
| Below 80% accepted-plane support | 876 | 0 (vendor class-6 branch does not use this gate) |
| Footprint below 15 m² | 104 | 4 |
| Fewer than 20 usable roof points | 11 | 143 |
| Roof spatial support below 50% | 1 | 34 |
| **Total null** | **992** | **181** |

The planar rule accounts for 88.3% of Sloan's nulls. Its rejected candidates have a median planar share of 61.3%. This is a method rejection, not proof that those buildings do not exist.

Coverage and density checks used the same read-only procedure on both areas: all cached EPT hierarchy depths; all non-noise return classes; point-in-footprint counts in the unchanged OSM polygons; existing class-2 ground-ring diagnostics. Classes 7 and 18 were excluded from the raw-support count. Every footprint in both areas contains non-noise returns and has at least eight ground-ring points. Thus **no entirely unsurveyed footprint or complete building-scale coverage hole explains these nulls**. This does not rule out local occlusion, partial gaps, or buildings changing since acquisition.

Median raw non-noise returns per square metre of footprint: **Sloan 3.46; Lakeview 27.65**. Among null footprints: 3.57 and 63.27 respectively. Density is substantially lower in Sloan and can affect plane detection, but this analysis does not isolate a causal density effect from classification, vegetation or roof complexity. Only 11 size-eligible Sloan nulls are explicitly rejected for fewer than 20 elevated candidates. Do not relabel the other 876 as a survey hole or a proven density failure.

The surveys are USGS CO_DRCOG_2020_B20 (2020-05-26–06-12) and IL_4_County_QL1_LiDAR_2016_B16 (Cook acquisition 2017-04-16–05-07), GREEN public-domain data. OSM footprints retain ODbL attribution. These are historical observations, not live data. All grades remain D, without independent accuracy calibration.

Evidence: `Data/quality/height-null-diagnosis.json` contains per-building raw-return counts, ground support, first rejection cause, planar share and source-sidecar hashes. Analysis did not modify any measurement parameter, sidecar or generator. Existing thresholds are from `Tools/regionkit/lidar/data/heights.json` and `observed-heights.json`; these are method thresholds, not accuracy guarantees.

## Proposed GENERAL fallback — not implemented or applied

Keep the observed fields and their nulls. Add a separate inferred candidate field with method, original source, acquisition/release date, licence, units, height definition, ground/datum reference and rejection reason. Candidate grades stay D; calibrated intervals remain null until validated. No defaults for missing levels, no forced fill, no synthetic roof type/pitch from a height.

1. **Same-survey DSM minus DTM:** use robust elevated-surface statistics within the footprint and class-2 ground from the same acquisition. Require sufficient support and vegetation/occlusion checks; do not substitute unrelated ground or silently relax the existing 80% gate. If roof versus canopy cannot be distinguished, retain null. Validate this separate estimator across all approved areas before enabling it.
2. **Provenance-vetted Overture height:** only a GREEN source with an unambiguous building/part match, original source lineage, finite positive height and compatible geometry. Preserve the source's height definition; do not treat lowest-to-highest height as identical to our p95-minus-ground-ring statistic. A same-source Overture value is not independent validation. [Overture building schema](https://docs.overturemaps.org/schema/reference/buildings/building/) defines optional height and source fields.
3. **OSM levels as a last-resort estimate:** multiply explicit above-ground levels by a documented, region/use-calibrated floor-height assumption. This gives a wall-height estimate. A total roof-top estimate additionally requires explicit roof-height information or an approved calibrated roof allowance; otherwise keep total height null. [OSM building:levels](https://wiki.openstreetmap.org/wiki/Key:building:levels) excludes roof levels. No assumed two-storey default.

This is a proposed precedence, not an accuracy ranking established by this analysis. Evaluate errors and coverage against independent references on Sloan, Lakeview and the approved second Denver hold-out with identical code and parameters. Do not predict a recovery percentage before that evaluation. **Await R before implementing or applying any fallback.**

## West Highland rectangle — awaiting R

The existing areas have different sizes: Sloan is 1,600 × 1,200 m; Lakeview is 1,000 × 1,000 m. Propose **1,000 × 1,000 m, matching Lakeview**, centred at **39.764000, -105.040000**, between Tennyson and Lowell, north of W 29th Avenue and south of W 38th Avenue. [West Highland Neighborhood Association boundaries](https://www.westhighlandneighborhood.org/wp-content/uploads/2021/05/WHNA-Bylaws-2008.pdf) place the neighborhood between W 29th/W 38th and Sheridan/Federal. The proposed rectangle is a hold-out subset, not the neighborhood boundary.

| Boundary | Coordinate |
|---|---:|
| South | 39.759496717 |
| North | 39.768503283 |
| West | -105.045835184 |
| East | -105.034164816 |

Proposed processing halo: 100 m; the following measured coverage refers to the core rectangle, not the halo. Bounds use WGS84 local metre dimensions; displayed coordinates are rounded.

**Coverage assessment only:** unchanged source-frame conversion and all EPT hierarchy depths from the same GREEN Denver 2020 source. Read 180 nodes, 54,804,765 compressed bytes, within the same 600 MB budget and 8 GB disk guard. All **10,000/10,000 ten-metre cells contain non-noise lidar returns (100%)**. **9,893/10,000 contain class-2 ground (98.93%)**. Mean return density is 4.085/m²; classes 1 and 2 only. This does not imply continuous 1 m coverage, usable roofs, or 100% height acceptance; the same unclassified-roof limitation as Sloan applies.

`Data/planned-areas/west-highland-proposal.json` is explicitly HOLD. No production manifest, footprint import, height sidecar, roof sidecar or DEM was created for this area. The map uses sourced OSM street, park and lake geometry from the existing 2026-10-06 context extract, © OpenStreetMap contributors. **Await R before preparing this rectangle.**
