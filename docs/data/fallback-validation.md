# GREEN fallback validation — 8 October 2026

R approved the generic GREEN-only ladder and West Highland's proposed 1 km rectangle. R required Lakeview comparison on buildings with observed heights, including tree-overhang cases, before using any rung in an export. The following table was shown in the chat before export work. No rung is accepted or applied. Observed nulls are preserved.

The unchanged, area-parameterized validation command is `Tools/regionkit/lidar/fallback_validation.py`; settings are in `lidar/data/fallback-validation.json`, individual results in `Data/quality/lakeview-fallback-validation.json`. GREEN sources: existing OSM/Overture ODbL branch and USGS public-domain lidar. Overture requires explicit height-property lineage from an allowlisted dataset and a unique footprint match (IoU ≥0.8). Geometry lineage is insufficient. Candidate parameters were fixed before evaluation; no fitted offsets or block tuning.

All values in metres. “Median” and “p90” are absolute errors; bias is mean(candidate minus observed). Each rung is evaluated independently, not conditional on an earlier rung failing.

| Rung | Stratum | N | Median | p90 | Bias |
|---|---|---:|---:|---:|---:|
| DSM minus DTM | all | 2618 | 0.28 | 2.92 | +0.99 |
| DSM minus DTM | vegetation-overlap proxy | 2579 | 0.30 | 2.99 | +1.01 |
| DSM minus DTM | no overlap proxy | 39 | 0.07 | 0.14 | +0.04 |
| Vetted Overture height | all | 2045 | 1.09 | 2.97 | −0.97 |
| Vetted Overture height | vegetation-overlap proxy | 2024 | 1.10 | 2.97 | −0.97 |
| Vetted Overture height | no overlap proxy | 21 | 0.19 | 1.13 | −0.47 |
| OSM levels plus explicit roof allowance | all / overlap | 0 | — | — | — |

Levels alone are wall-height estimates: 1,335 values have median 3.17 m, p90 6.53 m and bias −4.03 m against roof-top heights. They are a diagnostic only, not eligible total-building-height predictions. The 3 m floor assumption is the existing `heights.json#floors.perFloor`; no fitting. An explicit roof height takes precedence over roof shape; missing or invalid roof height is not silently zeroed.

## Limits and gate

The reference is uncalibrated grade-D lidar, not independent ground truth. DSM and reference share the same survey; the USGS-derived Overture heights may too. This measures agreement, not independent accuracy. Success on observed buildings would not establish success on the harder observed-null buildings.

Tree-overhang is screened using vendor vegetation classes 3–5 inside the footprint (at least 20 returns and 5% of surface returns). This flags 2,579/2,618 reference buildings. It is a deliberately broad vegetation-overlap proxy, not a manually verified overhang label. Non-overlap samples are small. Surface estimation retains vegetation returns; the proxy does not clean the prediction. Actual tree-overhang accuracy remains unconfirmed.

R was asked whether acceptance should require median ≤1 m, p90 ≤3 m and absolute mean bias ≤0.5 m, including the overlap stratum. This is a proposal, not an approved threshold. Neither numeric rung meets that proposed bias limit; the levels rung has no eligible samples. `approvedRungs` remains empty and `exportEnabled` false. Every candidate is a separate inferred field, grade D, with `selectedRung: null` and `exportEligible: false`. No candidate changed an observed height or export. Independent/verified overhang validation and a confirmed acceptance rule are still needed before promotion.
