# Elevation handoff contract

`Tools/regionkit/terrain/elevation.py` preserves source-native USGS 3DEP 1 m GeoTIFF windows around the authorized area with a 100 m halo. No resampling occurs in these clips. Their affine transforms and horizontal CRS remain intact; they contain bare-earth elevations, not the pre-existing slope-bin field. Adjacent source tiles can overlap; consumers must respect the georeferencing and nodata mask when mosaicking.

The generic pipeline reads `mountain-terrain-v1/values.json#demByDistance` for range and spacing. Bands use 10 m samples from 1/3 arc-second sources through 2 km, then 30/60/120/240 m samples from native 1 arc-second sources through 20/50/100/200 km. Source resolution remains explicitly separate from output spacing. Each compressed NPZ holds three float32 arrays: `elevation_m` (nearest native sample), `minimum_m` and `maximum_m` (full native pixel envelopes). Arrays are north-up with affine transform and shape in metadata; -9999 marks unrequested or missing cells. Band limits are radial and half-open. Source-native extrema are retained separately for ridge/silhouette construction, not substituted into the terrain surface.

The files are NAVD88 orthometric metres. **No ellipsoid/geoid conversion has been applied.** 5A must not interpret these values as WGS84 ellipsoid heights or combine incompatible vertical datums. Publication dates are recorded separately from unknown acquisition dates for the seamless products. Native 1 m clips select the verified survey project from area configuration; source URLs and metadata links are retained. This is surveyed terrain provenance, not a current-surface guarantee or independent error calibration.

Rights: the official USGS catalogues linked in `Tools/regionkit/terrain/data/elevation.json#sourceEvidence` specify public domain and NAVD88/metres for these CONUS product families (checked 8 October 2026). The pipeline uses verified TLS, bounded native window reads, one processing thread and an 8 GB disk guard. It fetches only configured areas: Sloan’s Lake, Lakeview and Greenville Downtown. Greer remains on hold. No terrain source is OSM-derived.

5A owns loading, vertical-frame reconciliation, terrain meshing, LOD transitions and visual validation. Distance guides are not claimed to satisfy screen-space error automatically. Missing samples stay missing; there is no invented shoreline, building-pad correction, slope-to-height conversion or water-code change. The identical distance policy, native halo and processing limits apply to the hold-outs; only area boundaries and source selection vary.

`audit_elevation.py` and `verify_elevation.py` run under the heavy lock. Read-back checks verify file digests, native metre-resolution rasters, finite values, requested native-rectangle coverage, radial masks, covered-cell counts and minimum/surface/maximum consistency. Coverage gaps are explicit flags with `PASS_WITH_GAPS`; corrupt values, mismatched hashes or broken envelopes fail. A coverage pass is not independent accuracy calibration. The native coverage check warps only a binary mask; saved native elevation clips remain unresampled. HTTP 200 catalogue error payloads and transient HTTP failures are retried within a fixed bound and are never cached as valid empty coverage.

## Verified hold-out comparison

| Area | Native 1 m rectangle + 100 m halo | All distance bands through 200 km | Read-back |
|---|---:|---:|---|
| Sloan’s Lake | 100% | 100% | PASS |
| Lakeview | 100% | 100% | PASS |
| Greenville Downtown | 100% | 100% | PASS |

`Data/quality/elevation-holdouts.json` records the common-policy comparison. Sixteen terrain tests pass, including source-native peak preservation, incomplete catalogue handling and rejection of false coverage metadata. Raster digests, finite values, band masks and envelopes pass in all three areas. This is not independent elevation-error calibration.
