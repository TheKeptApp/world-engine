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

## Sparse-density experiment — R request, 8 October

Protocol fixed before results: retain each return when a deterministic uniform number is below 3.5/27.65 (12.6582278481%). Point identity is EPT node key plus zero-based LAZ record index. SHA256 of `worldengine-density-thinning-v1:` plus node key supplies the little-endian 64-bit seed; SplitMix64 mixes seed and record index with unsigned 64-bit wraparound. The upper 53 bits divided by 2^53 supply the uniform number. No geometry, class, roof height, building identity or area-specific decision enters selection. Source LAZ hashes are recorded, caches are not rewritten, and the same mask thins ground and surface.

The 27.65 and 3.46 values are medians of non-noise return density over building footprints, not area-wide means. The requested target is approximately 3.5 returns/m². The report measures the achieved footprint median over all original buildings and separately over buildings with observed references. Noise classes 7 and 18 are excluded only from this density diagnostic; estimator class rules are unchanged.

All three rungs retain their existing settings. Reference SHA, OSM SHA, rung configuration, building population and individual full-density reference heights must match the saved baseline. Vegetation-overlap labels are frozen from that baseline, so thinning cannot relabel difficult cases out of the stratum. Each rung reports absolute median/p90, signed mean bias and null count/rate against the same eligible population. No averaging between rungs, bias subtraction, new promotion or inferred export. Overture and OSM source tables are not lidar point clouds: their unchanged predictions are controls, not sparse-lidar accuracy evidence.

Random thinning tests density sensitivity only; it does not reproduce Denver flight geometry, occlusion, vegetation season or unclassified returns. The reference is still uncalibrated grade D from the same lidar family. An independent check would use surveyed roof surfaces and ground elevations, matched to the same height statistic and footprint, with verified vegetation-overlap labels; include both observed and currently null buildings, and verify GREEN rights before loading. The queued experiment subsequently completed under the owned heavy lock after A4 released it; A4 files/server/lock were untouched.

### Sparse results (completed)

Achieved median 3.4891 non-noise returns/m² over the original building footprints, from fixed retention 3.5/27.65. Same 2,618 full-density observed references and 2,579 frozen vegetation-overlap labels.

| Rung | Stratum | N | Median absolute m | p90 absolute m | Signed mean bias m | Null rate |
|---|---|---:|---:|---:|---:|---:|
| DSM−DTM | all | 2616 | 0.1384 | 2.3270 | +0.7659 | 2/2618 (0.0764%) |
| DSM−DTM | overlap | 2577 | 0.1418 | 2.3854 | +0.7777 | 2/2579 (0.0775%) |
| Vetted Overture | all | 2045 | 1.0930 | 2.9700 | −0.9653 | 573/2618 (21.8869%) |
| Vetted Overture | overlap | 2024 | 1.1000 | 2.9700 | −0.9705 | 555/2579 (21.5200%) |
| Roof-aware OSM levels | all | 0 | — | — | — | 2618/2618 (100%) |
| Roof-aware OSM levels | overlap | 0 | — | — | — | 2579/2579 (100%) |

DSM−DTM remains computationally viable at the thinned density, with only two nulls, but is **not established as usable for export**: +0.77 m mean bias remains, including +0.78 m in the overlap proxy. Reduced error after thinning does not establish improved truth: the surface upper quantile and canopy sampling change while the reference is shared-family grade-D lidar. Independent roof-and-ground survey with verified canopy labels is still needed. Overture/OSM are unchanged controls. No rung averaging, bias correction or promotion. Full per-building output: Data/quality/lakeview-sparse-fallback-validation.json.
