# Survey roof forms — data contract

`Tools/regionkit/lidar/observed_roofs.py` consumes the configured full-density survey and accepted `building-heights.json` evidence. It emits `Data/areas/<area>/building-roofs.json`, keyed by the same OSM references. It does not change the renderer or building generator. The area allow-list is shared with the heights driver: Sloan’s Lake, Lakeview and Greenville Downtown are authorized; Greer remains on hold.

The existing lidar pilot's `params.json` supplies erosion, normal estimation, plane segmentation, raster coverage and classification thresholds. The driver preserves unsupported roofs as null, maps complex to `other`, and emits flat/gable/hip where supported. Pitch is degrees from horizontal; ridge bearing is modulo 180 clockwise from true north, inferred from the principal footprint axis and roof-plane orientation rather than traced ridge endpoints. Flat/other/missing have no ridge. Plane area and footprint coverage are retained as diagnostics.

`confidence.support_score` multiplies significant-plane coverage (clamped to 0–1) by planar-point share when inferred from class-1 returns. This is an explicitly uncalibrated support indicator, not a probability or independently measured accuracy. All grades remain D; `calibrated_probability` is null. Source dates, NAVD88 datum, GREEN public-domain source and ODbL footprint provenance travel with the sidecar. The source survey is older than the footprints; changed buildings and vegetation can invalidate apparent roof planes.

P2: do not treat missing roof records as flat, or grade D as validated truth. Preserve observed versus generated estimates and source vintage. Heights and roof form share a source; the sidecar records the height-file digest to detect mismatched versions. Consumer wiring and any visual validation belong to P2.

The classifier runs unchanged for each area. Acquisition dates are copied from source metadata, including Cook 2017 and Greenville January 2020; there is no fixed city or survey-year assumption in the method. The final ridge axis is reduced modulo 180 after classifier rounding, preventing a near-north/south axis from escaping the [0,180) contract. All three outputs are regenerated from point data; no building-specific corrections are applied. `compare_roofs.py` checks method equality (apart from source dates), height-file linkage, missingness, pitch/ridge ranges and uncalibrated confidence for an arbitrary authorized area list under the heavy lock.

## Hold-out results

| Area | Known / OSM footprints | Coverage | Flat | Gable | Hip | Other | Unknown |
|---|---:|---:|---:|---:|---:|---:|---:|
| sloans-lake | 407 / 1399 | 29.1% | 113 | 77 | 66 | 151 | 992 |
| lakeview-sheil-park | 2563 / 2799 | 91.6% | 1425 | 246 | 290 | 602 | 236 |
| greenville-downtown | 419 / 681 | 61.5% | 269 | 26 | 14 | 110 | 262 |

Every result remains grade D; these coverage fractions do not measure classification accuracy. The same classifier and parameters were used in all areas, without per-building edits.
