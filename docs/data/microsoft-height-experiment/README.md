# Microsoft heights: internal experiment, 8 October 2026

**Neither area passes the proposed thresholds. No promotion, package change, manifest change or production estimator change.** `approvedRungs` remains empty and `exportEnabled` remains false. Permission is the direct current Global ML release under CDLA Permissive 2.0, scoped to internal analysis by R and [A11's check](../../legal/height-sources-check.md) at fdf19ec. Municipal Denver heights, assessor records and legacy USBuildingFootprints were not acquired or used.

## Exact source and retained agreement

Current provider release: **2026-08-13**, not the February release inspected in the earlier research. [Provider README](https://github.com/microsoft/GlobalMLBuildingFootprints/blob/c691ea1a09dfe9bd91b8e1db7ee31e7b6b3c7fbe/README.md) and LICENSE pinned to **c691ea1a09dfe9bd91b8e1db7ee31e7b6b3c7fbe**; [catalogue](https://bfppub.blob.core.windows.net/%24web/2026-08-13/dataset-links.csv). Release date is not imagery acquisition date; per-building imagery epoch is unavailable in these records. Full [CDLA agreement](CDLA-Permissive-2.0.txt), pinned provider README/LICENSE and catalogue are retained alongside local raw tiles in ignored `Generated/ms-height-experiment/`. Agreement is also retained with this report. Source permission is GREEN for this internal use; shipped combined data remain blocked.

Only the catalogue tiles intersecting each core osm.json source extent were downloaded: Sloan `023101030` (81,873,016 bytes), Lakeview `030222231` (128,158,761 bytes). Catalogue tiles exceed the small study extents; no neighbouring/non-intersecting tiles downloaded. [Aggregate report](report.json) records exact tile URLs, byte sizes, SHA-256 hashes, catalogue/agreement/provider hashes, reference hashes and local join hashes. Raw tiles and per-building join records remain local and gitignored; only aggregate evidence, agreement and reproducible analysis code enter the repository.

## Fixed method

The standalone `Tools/regionkit/experiments/microsoft_heights.py` uses existing frozen LiDAR-reference footprint IDs and the same existing footprint loader/projection: local WGS84 tangent-plane east/north metres. No shape shifts, geometry repair of Microsoft polygons, height calibration, area-specific constants or height-aware matching. Compare full polygons by intersection-over-union **≥0.70** (proposed rule in [research, Join contract](../../research/height-sources-us.md#join-contract-and-quality-limits)). Require exactly one eligible source per target and one eligible target per source; reject ambiguity in either direction. This is a conservative unique reciprocal match. Source polygons with invalid geometry are rejected. Duplicate source geometry and shared candidates are counted before matching, never resolved using height agreement.

A usable height is finite, numeric and strictly positive metres; `-1`, absent and all other invalid/nonpositive values remain missing. Microsoft height is inferred modelled average AGL; LiDAR reference is existing accepted `roof_top_agl_m`, p95 selected roof minus same-survey ground. Signed bias is **mean(Microsoft − LiDAR)**; quantiles use NumPy's default linear percentile rule. All matched heights are included without outlier trimming or bias correction.

| Area | Frozen footprints / accepted LiDAR | Geometry matches | Usable heights | LiDAR-null receiving height | Compared observed subset | Median absolute / p90 / signed bias (m) |
|---|---:|---:|---:|---:|---:|---:|
| Sloan's Lake | 1,399 / 407 | 743 (53.1%) | 641 (45.8%) | 418 / 992 (42.1%) | 223 / 407 | 0.814 / 1.881 / −0.745 |
| Lakeview | 2,799 / 2,618 (93.5%) | 933 (33.3%) | 933 (33.3%) | 8 / 181 (4.4%) | 925 / 2,618 | 2.602 / 4.750 / −2.469 |

Sloan's has 102 geometry matches with missing Microsoft heights; Lakeview has zero. The 184/407 Sloan and 1,693/2,618 Lakeview accepted LiDAR buildings without a usable match are excluded from difference statistics, not treated as zero error. No eligible IoU match: Sloan 656, Lakeview 1,866. Both have **zero** exact duplicate geometry records in the local candidate set, multiple eligible sources, shared eligible sources and accepted source reuse. Counts refer to this rule and these extents, not a provider-wide duplicate assessment.

Proposed, still-unapproved thresholds: median absolute ≤1 m, p90 ≤3 m, absolute signed mean bias ≤0.5 m. Sloan passes the first two but **fails bias**. Lakeview **fails all three**. No rung promoted. Greater candidate coverage on unobserved buildings is not proof of their accuracy.

The reference is uncalibrated **grade D**, not ground truth. Roof-statistic differences, model error, footprint selection and differing acquisition epochs all contribute; the observed subsets cannot validate the missing-height populations. Microsoft is a different method/source from the USGS reference, but independent building-level truth and acquisition lineage are not established. A separately surveyed roof/ground check (or rights-cleared independent height sample with matching height convention/epoch) is needed for calibration. No observed null is overwritten.

## Reproduction and checks

Using Python with numpy 2.5.3 and shapely 2.2.0, download the pinned catalogue, README/LICENSE and the linked full agreement into ignored `Generated/ms-height-experiment/`. Save the provider commit API response as `provider-commit.json`. Select catalogue entries intersecting each manifest's core osm.json bounds with `selected_rows`; download only those URLs as `<QuadKey>.gz` and verify hashes against report.json. Then run:

```
python Tools/regionkit/experiments/microsoft_heights.py --areas sloans-lake lakeview-sheil-park
HEAVY_AGENT='A1 internal height experiment' scripts/heavy.sh 'Microsoft join controls' python -m unittest discover -s Tools/regionkit/experiments -p test_microsoft_heights.py -v
```

Five controls pass: unique/low overlap, duplicate source rejection, shared-source rejection, missing-height/signed-error calculations and tile bounds. Test wrapper released normally; no Swift build or generator run needed. Single-process bounded data analysis completed with >8 GiB free. Source data, references, production ladder, area manifests and generator files are unchanged. Local output joins and report have `internalOnly=true`, `approvedRungs=[]`, `exportEnabled=false`.

## Ledger text for A3

A1 internal-only Microsoft Global ML heights experiment uses pinned 2026-08-13 direct release and retained CDLA2 agreement. Sloan 641/1399 usable, including 418/992 LiDAR nulls; observed comparison n=223, median/p90/bias 0.814/1.881/−0.745 m. Lakeview 933/2799 usable, 8/181 nulls; n=925, 2.602/4.750/−2.469 m. Both fail the proposed gate, with no promotion or rendered change. Five join controls pass. Product ladder/estimator/manifests/generators untouched; no visual or shipping clearance.

Used: height-sources-check.md at fdf19ec, Decision/N1; height-sources-us.md at 97138fa, National N1/Join contract; pinned Microsoft release and aggregate report. Mock: none (internal data experiment). Deviation: none; current August release replaces the research note's older February release identity.
