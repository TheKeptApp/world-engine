# World hosting and streaming cost model

Research/arithmetic only. Prices checked **8 October 2026, America/Denver** (9 October 04:36 UTC). USD before taxes. Only this document changes; no code, exports, source downloads, purchases or hosting configuration. Existing export files were read and their listed hashes/sizes verified. This is a scenario model, not a usage forecast or publication clearance.

**Decision:** validate selective LOD delivery and persistent device caching before negotiating bulk storage. In the illustrative mix, one current 10,000 km² version occupies 1.645 TB, costing roughly $16–$25/month for storage alone, while one million users × ten sessions use 1.240 PB/month and cost ~$12,396/month at the cited North America/Europe CDN rate. Neither the application nor its current eager loader has demonstrated the assumed session savings. A zero-egress R2 architecture changes the monetary bottleneck to requests/operations and optional services; it does not remove device/network limits.

## Units, scope and evidence quality

MiB = 1,048,576 bytes; model GB = 1,000,000,000 bytes; TB = 1,000 GB; PB = 1,000,000 GB. Provider lists say GB; verify invoiced byte units before contracting (binary rather than decimal GB changes conversion ~7%). Do not confuse encoded package files with decoded CPU arrays or GPU buffers. One km² means ground area, including park/water inside a core. Three places are proxies, not a world census.

**M — measurement:** bytes, file hashes, extents and recipes in the held exports below. **E — estimate:** arithmetic extrapolation from M plus stated additions; surface-role companions and A5 geometry envelopes are estimates, not delivered measurements. **G — guess:** user behaviour, geography mix, useful-area coverage, cache hits, compression benefit and future LOD delivery fraction; these have no traffic traces. Every projected dollar is E conditional on those guesses, not a provider quote.

## 1. Measured packages and bytes per km²

Package size is `sum(world.json.files[*].bytes) + actual world.json bytes`. Every listed file was checked against its recorded size and SHA-256; all passed. Only manifest-listed payload is counted: no debug/output-directory extras. These are existing uncompressed-on-disk package files, not measured HTTP transfers. Bundle headers/TLS, Brotli/gzip and GLB compression are not measured.

| Proxy / held export | Ground km² | Listed files + world.json | MiB | Measured bytes/km² | MiB/km² |
|---|---:|---:|---:|---:|---:|
| Dense: Lakeview full-focus adaptive | 1.00 | 248,021,427 B | 236.532 | 248,021,427 / 1 = 248,021,427 | 236.532 |
| Suburban: Wilmette capture package | 1.00 | 93,839,030 B | 89.492 | 93,839,030 / 1 = 93,839,030 | 89.492 |
| Park/water mix: Sloan capture package | 1.92 | 93,116,564 B | 88.803 | 93,116,564 / 1.92 = 48,498,210 | 46.251 |
| Dense sensitivity: Lakeview capture package, narrow focus | 1.00 | 80,366,198 B | 76.643 | 80,366,198 / 1 = 80,366,198 | 76.643 |

**Not an apples-to-apples land-type experiment.** Full-focus Lakeview covers [-500,-500,500,500] m; Wilmette focus is [-496.544,-466.496,289.619,311.015]; Sloan focus [-428.541,-260.020,559.956,566.273]; narrow-focus Lakeview [-198.185,-129.952,50.581,92.190]. Outside-focus detail, seasons, profiles and adaptive parent/child duplication differ. The 3.09× Lakeview package-size difference is primarily a warning about recipe dependence, not a measured compression saving. Sloan is not pure empty water; Wilmette/Sloan are not full-detail-per-square-kilometre ceilings. New matched full-focus measurements would be needed before committing to a world inventory, but are outside this task.

Read-only provenance (temporary paths identify existing exports; do not regenerate to reproduce this audit):

| Export | Existing root | world.json SHA-256 |
|---|---|---|
| Lakeview full focus, 492 listed files | `Generated/adaptive-targets/lakeview-sheil-park/` in A1 worktree | `be237920c636ea240e934fe3c491bbaeab5156c31f8029f5e53822cb357a0f57` |
| Sloan, 281 listed files | `/private/tmp/worldengine-a7-sloans-ladder/Generated/package/sloans-lake/` | `2e8962193bb6d34ed79497f7a9eb3dc538c3a335f1cbb7f298a9df68c51323d0` |
| Lakeview narrow focus, 211 listed files | `/private/tmp/worldengine-a7-sloans-ladder/web/bakeoff/generated/lakeview-sheil-park/` | `e9e8c88482893619b13e67222b24353138170a889ab77be225491d2791ca9164` |
| Wilmette, 208 listed files | `/private/tmp/worldengine-a10/Generated/web-capture/wilmette-vattmann-park/` | `fb5c6f99f65dcedac52e8526aa76a5329b8b4470c35d53ba604e3cf5e2fce3ce` |

Recipe dates/seasons: Sloan 2026-10-15T23:44:01Z/2, Lakeview 2026-07-15T20:00:00Z/1, Wilmette 2026-09-15T19:56:00Z/2. These are simulated recipe conditions, not source capture or export creation dates. Generator version strings are `dev`; file hashes, not that string, pin the measured artifacts. A1 adaptive evidence is also filed in [adaptive-tiles](../data/adaptive-tiles.md) and Data/quality/adaptive-tile-packing.json.

Add R-supplied **estimated** surface-role companions: Sloan 1.149 MiB, Lakeview 2.971 MiB per their whole core, not per tile. No Wilmette companion measurement supplied: reserve **2.971 MiB/km² as an explicit guess**, not an observed value.

- Dense D = `(248,021,427 + 2.971×1,048,576)/1` = **251,136,746 B/km² = 239.503 MiB/km²**.
- Suburban D = `(93,839,030 + guessed 2.971×1,048,576)/1` = **96,954,349 B/km² = 92.463 MiB/km²**.
- Park/water D = `(93,116,564 + 1.149×1,048,576)/1.92` = **49,125,718 B/km² = 46.850 MiB/km²**.
- Illustrative mix, **G**: 50% dense + 30% suburban + 20% park/water. D = **164,479,821 B/km² = 156.860 MiB/km²**. This is a traffic/inventory scenario, not an estimate of Earth's composition.

The companions add 1.26% to full-focus Lakeview and 1.29% to Sloan. They are not the first-order hosting cost. Whole-package division repeats shared assets/prototypes across area units; cross-area deduplication could reduce storage, but no such reduction is claimed.

## 2. Current public prices and storage

[Cloudflare R2 Standard pricing](https://developers.cloudflare.com/r2/pricing/): $0.015/GB-month, Class A $4.50/million, Class B $0.36/million, no retrieval or egress charge. Monthly free allowance: 10 GB-month, 1 million A, 10 million B; billable usage rounds upward to GB/million units. R2 table below applies unused free storage and whole-GB rounding; no account sharing assumed. [Public-bucket documentation](https://developers.cloudflare.com/r2/buckets/public-buckets/) requires custom-domain configuration for caching; r2.dev is rate-limited development access. Production cache policy, optional services and contractual capacity still need validation.

[Bunny Standard HDD storage](https://bunny.net/pricing/storage/): $0.01/GB-month for one region, $1 monthly minimum, no API fees, free transfer to Bunny CDN; two regions $0.02/GB, three $0.025/GB. [Bunny Standard CDN](https://bunny.net/pricing/cdn/): EU/North America $0.01/GB, Asia/Oceania $0.03, South America $0.045, Middle East/Africa $0.06; $1 monthly minimum, no request fees. Rates are the provider's own current lists, not competitor-comparison graphics. Standard above 100 TB/month invites a sales discussion; extrapolated list-price arithmetic is not a capacity/discount quote. Volume Network has different PoPs/tiering and is not assumed equivalent here.

Storage formulas, one current copy held all month: `S_GB = km²×D/10^9`; Bunny component `max($1,0.01×S_GB)`; R2 `0.015×max(0,ceil(S_GB)−10)`. Rows are alternative inventories, not amounts to add together.

| Proxy | km² | Storage GB | Bunny one-region/month | R2 Standard/month |
|---|---:|---:|---:|---:|
| Dense | 1 | 0.251 | $1.00 | $0.00 |
| Dense | 100 | 25.114 | $1.00 | $0.24 |
| Dense | 10,000 | 2,511.367 | $25.11 | $37.53 |
| Suburban | 1 | 0.097 | $1.00 | $0.00 |
| Suburban | 100 | 9.695 | $1.00 | $0.00 |
| Suburban | 10,000 | 969.543 | $9.70 | $14.40 |
| Park/water mix | 1 | 0.049 | $1.00 | $0.00 |
| Park/water mix | 100 | 4.913 | $1.00 | $0.00 |
| Park/water mix | 10,000 | 491.257 | $4.91 | $7.23 |
| Illustrative mix | 1 | 0.164 | $1.00 | $0.00 |
| Illustrative mix | 100 | 16.448 | $1.00 | $0.105 |
| Illustrative mix | 10,000 | 1,644.798 | $16.45 | $24.525 |

Storage table excludes source archives, historical versions, backups and context additions. Use `S_total = S_current×retainedVersions×independentCopyCount + sourceArchives + addedContext`, applying provider replication pricing instead of also multiplying copies for the same replica. Three separately retained mixed versions are 4.934 TB before archives, not 1.645 TB. ODbL offer/archive retention can outlast client updates; it is a real additional inventory, not automatically a second full copy if the served objects themselves satisfy the offer.

**A5 context estimates, E:** [world-edge-options](world-edge-options.md) offers urban band geometry **1.2–9.6 decimal MB**, or building-free terrain/water/land **0.24–2.88 MB**, not measured GLBs, not per km². Do not add the alternatives or multiply either by 10,000 as though each were a km². A Lakeview 7×7 km box minus 1 km² core is 48 km²: illustrative urban division gives **0.025–0.200 MB/km²**; building-free **0.005–0.060 MB/km²**. That normalization is a guess about uniform coarse coverage, not proof the geometry exists or covers buildings (held building band is only 500 m). If it held over 10,000 km² without overlapping duplicates, extra urban storage would be 0.25–2 GB, small versus detailed storage. Terrain rasters, extra textures, multiple LODs and overlapping rings can invalidate that estimate.

## 3. Ten-minute session model

These are **future selective-delivery scenarios**, not today's eager loader. No HTTP compression saving assumed (`compression ratio=1`). Export totals contain all stored LODs and semantic/global files; D is an inventory-based proxy for transferable detail, not a measured mode payload. Existing LOD1/LOD0 GLB byte ratios are approximately Lakeview-full 26.6%, Sloan-capture 31.4%, Wilmette 18.5%; they motivate testing a 30% aerial fraction but do not validate it for complete packages or all camera motion.

Explicit guesses common to both modes: 4 MiB bootstrap reserve each session (conservative extra beyond shared assets already diluted into D); 25% useful-content reuse from **device** cache; 10% transfer amplification for partial-tile overfetch, retries and protocol/metadata uncertainty. CDN cache hits do not reduce client bytes. Persistent data versioning and cache reuse are not established. Urban context allowance is one A5 midpoint band **5.4 MB** per session; it does not buy unlimited panning or a complete 150 km skyline.

- **Aerial, G:** ten minutes explores **4 km² unique ground coverage**, fetching **30%** of the detailed inventory proxy through coarse LOD selection. This is an area assumption, not speed×time; repeated orbiting reuses tiles. Arbitrary free flight could exceed it greatly.
- **Route, G:** walking at **5 km/h** for ten minutes gives 0.8333 km. A 400 m-wide corridor plus a 400×400 m starting square covers `0.8333×0.4 + 0.4² = 0.493333 km²`, without self-overlap. Detail fraction **100%**. Driving/cycling, teleports and long-range side views are not this scenario.

Formula in bytes: **B = 1.10 × [4×1,048,576 + (1−0.25)×(D×uniqueArea×detailFraction + 5,400,000)]**.

| Geography proxy | Aerial MiB/session | Route MiB/session |
|---|---:|---:|
| Dense only | 245.756 | 106.126 |
| Suburban only | 100.187 | 46.281 |
| Park/water mix only | 55.030 | 27.717 |
| 50/30/20 mix | **163.940** | **72.491** |
| Mixed, cold device cache instead | 217.120 | 95.188 |

Mixed Aerial arithmetic: `1.1×[4,194,304 + .75×(164,479,821.460×4×.30 + 5,400,000)] = 171,903,758 B` (171.904 decimal MB). Route is **76,012,022 B**. At $0.01/GB, delivery-only cost is **$0.001719/Aerial session** or **$0.000760/Route session**, before monthly minimum/storage. Byte-average of 50% of each mode is **123,957,890 B/session**. Session mode share is another guess, not analytics.

## 4. Monthly bandwidth and CDN cost

Low/mid/high engagement = **2 / 10 / 30 ten-minute sessions per monthly active user**, fixed in every table. Hold geography, cache and per-session behaviour constant so only engagement changes. Formula `traffic_GB = users×sessions×B/10^9`; CDN cost `max($1, traffic_GB×$0.01)` at EU/NA Standard. Cells below are **GB / USD** per month; “mixed” means half Aerial, half Route. These are end-user delivery bytes, not origin-cache-miss traffic.

| Monthly users | Sessions/user | All Aerial GB / cost | All Route GB / cost | Mixed GB / cost |
|---|---:|---:|---:|---:|
| 1,000 | 2 low | 343.8 / $3.44 | 152.0 / $1.52 | 247.9 / $2.48 |
| 1,000 | 10 mid | 1,719.0 / $17.19 | 760.1 / $7.60 | 1,239.6 / $12.40 |
| 1,000 | 30 high | 5,157.1 / $51.57 | 2,280.4 / $22.80 | 3,718.7 / $37.19 |
| 100,000 | 2 low | 34,380.8 / $343.81 | 15,202.4 / $152.02 | 24,791.6 / $247.92 |
| 100,000 | 10 mid | 171,903.8 / $1,719.04 | 76,012.0 / $760.12 | 123,957.9 / $1,239.58 |
| 100,000 | 30 high | 515,711.3 / $5,157.11 | 228,036.1 / $2,280.36 | 371,873.7 / $3,718.74 |
| 1,000,000 | 2 low | 343,807.5 / $3,438.08 | 152,024.0 / $1,520.24 | 247,915.8 / $2,479.16 |
| 1,000,000 | 10 mid | 1,719,037.6 / $17,190.38 | 760,120.2 / $7,601.20 | 1,239,578.9 / $12,395.79 |
| 1,000,000 | 30 high | 5,157,112.7 / $51,571.13 | 2,280,360.7 / $22,803.61 | 3,718,736.7 / $37,187.37 |

For Bunny one-region origin plus CDN, add the storage component, not an origin-egress fee: illustrative 10,000 km² mixed inventory + one million users/mid sessions is **$16.45 + $12,395.79 = $12,412.24/month** before excluded services. Minima shown conservatively as separate service components; confirm account-level aggregation. No tax, app/API compute, logs, database, traffic abuse, authentication, build farm, source licences, source retention or support included.

World traffic is not all North America. With **guessed** destination shares 60% EU/NA, 25% Asia/Oceania, 10% South America, 5% ME/Africa, effective rate is `.60×.01+.25×.03+.10×.045+.05×.06 = $0.021/GB`: **2.1×** table delivery costs, or **$26,031.16/month** for the one-million/mid mixed case. Users' viewing location is not their billing geography. Reprice with real regional traffic and contracted tiers; do not extrapolate the lowest regional rate as a worldwide promise.

**R2 alternative:** same client traffic, $0 R2 byte-egress charge; storage/reads/writes still bill. Illustrative request model, G: mean payload object 1 MiB, `ceil(B/MiB)+10` requests/session = Aerial 174, Route 83, mixed **128.5**. With 90% edge hit rate, one million users × ten sessions generates **128.5 million origin reads**. After 10 million free and rounded billing: `ceil((128.5−10)/1)×$0.36 = $42.84/month` Class B. With zero edge hits it is **1,285 million reads → $459.00/month**. At 30 sessions and 90% hits it is **$135.36/month**. Upload/list/write Class A and optional Workers/paid cache/security plans are additional; no all-in “free CDN” claim or deployment approval. A hypothetical full refresh of 1.645 TB in 1 MiB objects is ~1.57 million PUTs, costing ~$4.50 beyond unused free A allowance with rounding; actual object/HEAD/list counts must replace this guess. Cache hits reduce origin requests, not the end-user bandwidth in the main table.

## 5. Where the curve breaks, and what moves it

**Operationally first:** today the web eagerly loads detailed chunks; there is no demonstrated world-scale selective streamer or complete context export. Startup download, decode/upload peaks and frame-time can fail before a large hosting bill. [Adaptive tile evidence](../data/adaptive-tiles.md) verifies ≤8 MiB decoded leaves, ~2 MiB primitive parts and ≤16 MiB worst two-leaf queue for tested packages; these are memory bounds, not 2 MiB wire objects or reduced total geometry. Lakeview leaf count rose 25→114: scheduling improved but request count can increase.

**Financially with a per-GB CDN:** usage/coverage growth outruns storage. For 10,000 km² mixed storage, ~$16.45 equals only ~1,327 mixed sessions of delivery at $0.01/GB. At ten sessions/user that is ~133 users; it is a cost crossover, not a solvency threshold. At one million users/high engagement, mixed delivery is ~3.72 PB/month and ~$37.2k EU/NA or ~$78.1k under the guessed world mix. Under zero-egress R2, storage/versioning, request amplification, optional compute and service capacity become more salient; device bytes remain a problem.

Sensitivity at one million users × ten sessions, same geography/mode split and EU/NA price:

| Change from baseline | Mixed CDN/month | Interpretation |
|---|---:|---|
| Baseline selective LOD/cache model | $12,395.79 | Conditional estimate |
| Aerial fetches 100% rather than 30% detail | $31,393.21 | LOD selection avoids ~$18,997; biggest immediate structural lever in this scenario |
| Hypothetical 50% reduction in detail bytes only | $6,651.33 | Compression/geometry encoding saving unmeasured; bootstrap/context unchanged |
| Device reuse rises 25%→75% | $4,439.51 | Large saving only if revisits, stable content hashes and sufficient local cache actually occur |

Bounded adaptive tiles reduce overfetch and peak memory; they do not automatically compress data. Avoid tiny-object proliferation and excess parent+child overlap; test transfer bytes and request count together. Content-addressed immutable URLs, shared prototypes and version-scoped manifests reduce invalidations and repeated downloads. CDN caching improves latency/origin load; only device cache/reduced payload reduces metered client delivery on the per-GB plan. Decode cost and quality preservation constrain geometry/texture compression; no 2:1 benefit is measured here.

Aerial unique-area exploration, driving speed/corridor width and cold-cache frequency can dominate all of these. Doubling visited area approximately doubles detail bytes; a 50 km/h Route trip has ~3.493 km² corridor coverage instead of 0.493, roughly seven times the detail component. “World scale” requires on-demand coverage and measured reuse, not preloading the 150 km far-plane radius or multiplying one park sample across all land.

## Limits and next evidence, no implementation

Measure network bytes by mode/LOD, unique tiles/km², compressed bytes, canceled/repeated requests, device/edge cache hit rates, immutable-version churn, shared-asset fraction and device decode/upload peaks on the same recipe across the three blocks. Obtain a true full-focus Wilmette/Sloan comparison and a Wilmette surface companion estimate. Replace the guessed session areas with traces before budget commitments. A5 ranges are not exports and surface companions are not verified payloads. Existing ODbL public-offer/attribution gates remain; this cost model authorizes no publication. No build or heavy lock was needed for document research, hash checks and arithmetic.

## Ledger text for A3

A1 hosting model filed: existing package byte/hash measurements with explicit focus/profile caveats; surface companions estimated; A5 context envelopes retained as estimates. Illustrative 10,000 km² mix is 1.645 TB, ~$16–$25/month storage; one million users × ten sessions, half Aerial/Route, is 1.240 PB/month and ~$12.4k EU/NA delivery at current cited list rate. Behaviour/cache/LOD inputs are guesses, not captured traffic; R2 zero-egress alternative separately accounts for origin operations. No code, export, dataset acquisition or hosting change.

Used: held package manifests/hashes above; R surface-role estimates; world-edge-options; current official Bunny and Cloudflare price lists (8 October 2026 Denver). Mock: none (research/arithmetic). Deviation: no matched full-focus three-block export exists in this measurement set; recipe differences and missing Wilmette companion are explicit.

## 6. Compute throughput — measured stages, missing timers and purchase decision

Added 8 October 2026 (Denver). **Recommendation: neither a second-Mac purchase nor a cloud migration yet.** Existing logs prove automated stages can be short and the local lock can delay them, but they do not measure end-to-end ingest, judgment hours or accepted metros/week. The numbers below separate observed timers from an explicit planning scenario. No new ingest, export, capture, benchmark, code or cloud job was run for this extension.

### 6.1 What the saved timers actually measure

Read-only evidence: `/private/tmp/a7-web-run{1,2,3}.log` and corresponding `/private/tmp/worldengine-a7-web-run{1,2,3}/.build/lookloop/proof/web-capture.json`; current three-height controls `/private/tmp/a10-scene-budget-off-control/web-capture.json` and `/private/tmp/a10-qual-lakeview-off/web-capture.json`. Export recipes are the narrow/focused capture packages in §1, not the full-focus adaptive Lakeview package. These are small historical samples under varying load, not a benchmark distribution. The present host reports Apple M1 Max, 10 CPU cores, 32 GiB memory; the logs do not independently embed hardware inventory. New-Mac and cloud speed ratios remain unmeasured.

| Stage | Sloan block: measured wall time | Lakeview block: measured wall time | Machine versus judgment share: what is known |
|---|---|---|---|
| Fresh source ingest (acquire, validate, LiDAR/DEM processing, joins) | **Not separately timed** | **Not separately timed** | Both network/CPU and rights/source/QA judgment; percentages **unknown**, not zero. Existing A1 logs record data quantities/results without start/end timers. |
| Warm local ingest/parse | Included inside export below; no separate timer | Included inside export below; no separate timer | Automated read/parse, but its CPU/I/O split and fraction of export are unknown. Do not add it again. |
| Export, excluding compiler and lock queue | 3.9 / 3.8 / 3.8 s; median **3.8 s** | 3.5 / 3.5 / 3.4 s; median **3.5 s** | Measured interval is automated execution; no judgment occurs inside the synchronous command. This does **not** mean all elapsed time is CPU-bound, or that authoring/QA costs zero. |
| Web capture, one saved OFF ladder at 40/150/600 m | **19.560 s** total; frame timers 5.837 / 6.261 / 6.271 s | **34.022 s** total; frame timers 11.962 / 16.949 / 3.583 s | Automated navigation/load/render/readiness/readback plus close/report overhead. GPU/CPU/I/O/wait percentages unprofiled; camera choice and evidence acceptance outside timer. |
| One opposite-area hold-out ladder, when this block is candidate | Lakeview control above: **34.022 s** | Sloan control above: **19.560 s** | Reusing existing measured capture component, not a measured new end-to-end hold-out run. No separately timed complete five-area QA/review sequence. Do not count this twice if both blocks are already in the batch. |
| Scoring (blind rubric, source comparison, acceptance/reject) | **No elapsed timer** | **No elapsed timer** | Agent/human judgment dominates the decision; helper computation exists, but split and hours are **unmeasured**. File timestamps, token counts and grade publication gaps are not substitutes. |

Timer boundary checked in `Sources/worldbake/main.swift`: `Date()` wraps `WorldPackage.export`, including its data loading, generation and writing. Swift compiler time is separate. Export log label says MB but divides by 1,048,576; §1 correctly uses MiB. Capture report `seconds` starts within its script and excludes outer heavy-lock admission; per-frame timers cover navigation through screenshot/evidence collection. No claim of measured pure GPU time or frames per second follows.

Supporting repeated machine measurements:

- Three fresh-worktree two-block/six-frame web commands: outer wall **172.09 / 324.95 / 137.28 s**; script totals **171.442 / 144.214 / 136.543 s**. Compile components **106.21 / 105.92 / 99.39 s** (median **105.92 s**) are inside script totals, not additive to them. The three modes are OFF/remove/layered at one pose, not the three-height ladder above.
- Summed frame intervals by block in those runs: Sloan **21.663 / 14.277 / 13.918 s**; Lakeview **31.490 / 10.641 / 10.688 s**. Totals minus frame sums still include preparation, compile/export and browser lifecycle; do not label the remainder “judgment.”
- Second command emitted three held-lock waits; wrapper minus script time is **180.736 s**, consistent with about **180 s queued** plus process overhead. This was **55.6%** of its 324.95 s outer wall. The other two differences were 0.648/0.737 s. It is evidence of one queue incident, not measured average utilization or permanently recoverable capacity.
- Native reliability runs for `ordinary-street-afternoon`: build **241.71 / 257.60 / 240.03 s**; capture **138.95 / 39.88 / 38.64 s**; total **380.91 / 297.74 / 278.94 s**. Native build/capture costs and readiness noise cannot be replaced by the faster web timers. There is no matched Lakeview-native stage timing in this selected evidence.

Saved evidence hashes:

| File | SHA-256 |
|---|---|
| a7-web-run1.log | `df8eed25ce7e3375479c2196a53b00b9bfc2478a2345f21aab9d23f7718e0939` |
| a7-web-run2.log | `d127b4e3cafd094ac5be9e3e4df697c80efa3af3225895c3582eb9af9be4adfc` |
| a7-web-run3.log | `95064253432c9be260ea2cae7a0f0c096eb3743775cdc563ecbed31408542e31` |
| a10-scene-budget-off-control/web-capture.json | `ef12b536bbb41bc2d7a299f25936be23e85e32d5990447e089e9c5b2c96b31b2` |
| a10-qual-lakeview-off/web-capture.json | `3d956127a3a8579360108da0b3cddbba8aaadb3c9babd4ad26f905267cad88f5` |

### 6.2 What the heavy lock serializes

The actual wrapper is `scripts/heavy.sh`: load gate below 25, one owner on this Mac, wait before acquisition, release on exit/interruption. Swift/Xcode builds, full test suites, Simulator work and capture/look-loop jobs serialize. Existing capture wrappers hold it across preparation/export/server/browser or native build/install/capture. Heavy export/geometry jobs stay wrapped. Do not nest a capture wrapper inside another lock holder. Keep ≥8 GiB free; release after every active job. Nothing here loosens the protocol.

Bounded Python analysis, documentation, Git and source fetches do not inherently require that lock, although a batch may put its own QA/data job inside it. Download service quotas, shared network/disk and source licence gates remain independent bottlenecks. Scoring judgment can overlap a machine job but cannot be replaced by another Mac. A second machine needs its **own local lock, checkout, data cache, simulator and environment validation**; it does not grant two simultaneous heavy jobs on the first machine. Git integration/approval remains coordinated.

For the observed queued web command, an idle equivalent second machine could conditionally reduce turnaround from ~325 s to ~145 s, saving ~180 s (2.24× faster turnaround for that one job), assuming assets/environment were ready. That is not a 2.24× throughput benchmark. Best case is two independent heavy slots, nearly 2× machine-job throughput; dependent stages in one block, one reviewer, provider limits and capture parity constrain the result. If Mac 2 already exists and is configured, testing it avoids a purchase; this audit did not establish its availability or run remote work.

### 6.3 Defined metro scenario and capacity arithmetic

A “metro” has no supplied area/acceptance definition. For a comparable **planning batch only**, define one metro batch as **100 representative cores: 50 Sloan-sized + 50 Lakeview-sized (~146 km² total), one three-height web ladder each, plus four additional hold-out ladders**. This is not complete metropolitan coverage, native qualification, multi-season confirmation, repair iteration or an accepted shipping city.

Inputs tagged G unless explicitly timed: **10 minutes/block automated preparation/ingest allowance**, **6 minutes/block scoring/judgment**, **1 hour/metro coordination/rights review allowance**, one compiler run per metro (measured median 105.92 s), four extra held-out exports/ladders at the two-block mean. Fresh LiDAR acquisition and municipal rights disputes can exceed these guesses by orders of magnitude; no metro/week measurement exists. Assume 40 productive machine-hours/week **per worker** and one reviewer with 40 judgment-hours/week; no 24/7 unattended operation is authorized or assumed.

Mean measured export E = `(3.8+3.5)/2 = 3.65 s`; mean measured web ladder C = `(19.559972625+34.0224825)/2 = 26.791228 s`.

- Automated demand M = `[100×(600+E+C) + 105.92 + 4×(E+C)]/3600` = **17.5755 machine-hours/metro**. Most of this is the guessed ingest allowance, not measured export work; treating it as one worker slot is conservative even where network wait could overlap.
- Judgment demand J = `100×6/60+1` = **11 hours/metro**, entirely an allowance, not a measured labor total. Scenario time share M/(M+J) = **61.5% automated / 38.5% judgment**; these percentages are **G/E**, not observed stage percentages.
- Pipelined steady-state capacity = `min(workers×40/M, 40/J)`. Sequential first-metro completion and pipeline output are different: M+J = 28.576 h before queues in this scenario. More hardware does not halve J.

| Configuration | Machine-only metro batches/week | With one 40 h reviewer | Machine cost/metro, conditional |
|---|---:|---:|---:|
| Existing 1 Mac | 2.276 | **2.276** | **$0.28 marginal electricity**, or **$2.81** including illustrative replacement depreciation |
| 2 equal-speed Macs | 4.552 | **3.636**, ~60% above one Mac | **$3.45** including depreciation of both machines and active electricity at this reviewer-limited output |
| 1 cloud macOS worker | 2.276 at assumed equal speed | **2.276** | **$65.38** runner compute before rounding/allowances/artifacts |
| 4 cloud macOS workers | 9.104 at assumed equal speed | **3.636** | **$65.38** active compute per metro before extras; reviewer prevents 4× accepted output |

All rows are scenario estimates, **not measured or guaranteed metro throughput**. With already-prepared data and zero ingest allowance, the same machine portion falls to **0.909 h/metro**, leaving the reviewer dominant even on one Mac. At 30 minutes ingest/block it rises to **50.909 h** and one/two-Mac capacity falls to **0.786/1.571 metro batches/week** before review. This uncertainty is larger than the purchasing effect. Real new-metro source/rights and correction demand are not bounded by these examples.

### 6.4 Compute prices, cost boundaries and break-even

Prices checked 8 October 2026 Denver. [Apple's US Mac mini page](https://www.apple.com/mac-mini/) lists **from $899**; this is a base purchase-price reference, not a recommendation that its RAM/storage equals the observed 32 GiB M1 Max host. Use **$899 capital**, three years/156 weeks straight-line depreciation, no residual value, as a low-end cost scenario. Additional RAM/SSD, setup, tax and warranty are excluded. Guessed active power **80 W** at guessed **$0.20/kWh** gives **$0.016/hour**, not measured wattage or the user's tariff. Existing hardware capital is sunk for a marginal-cost comparison.

[GitHub Actions public runner prices](https://docs.github.com/en/billing/reference/actions-runner-pricing) list standard macOS **$0.062/minute = $3.72/hour**, rounding each job up to a minute. Use it as the cloud price reference, not a demonstrated replacement: its 3/4-core machines differ from this Mac, concurrency depends on account plan, and native GPU/Simulator/capture parity is unverified. No workflow uploaded or cloud service used. Existing included minutes, transfers, artifact/cache storage, setup and agent/API tokens excluded. At 0.5×–2× local throughput, compute cost is roughly **$130.76–$32.69/metro**, before rounding, for the same scenario; capacity changes correspondingly. Small per-frame jobs would pay rounding repeatedly, so batch amortization matters. Generic Linux is not a verified substitute for macOS/Metal qualification. EC2 Mac is another option, but its [24-hour minimum host allocation](https://aws.amazon.com/ec2/instance-types/mac/) makes short burst arithmetic different; no unverified EC2 hourly rate is substituted.

Local formulas: replacement weekly cost `$899/156 = $5.763`; one-Mac allocated capital per metro `$5.763/2.276`, plus `17.5755×$0.016`, gives **$2.81**. Two-Mac capital `$11.526/3.636` plus the same active machine-hours' electricity gives **$3.45**. They are utilization-dependent accounting costs, not spending quotes; idle power excluded. At only one metro/week, the capital per metro is higher. Add actual judgment cost separately: `11×reviewer_hourly_cost`, plus actual agent-token cost. At an explicitly hypothetical $50/hour this is **$550/metro** before hardware, illustrating why a cheap machine is not the whole delivery cost.

**Hardware-versus-cloud break-even, not “buy now”:** `$899/($3.72−$0.016) = 242.7 equivalent busy hours`, or **13.81 → 14 scenario metros** of work shifted from paid equal-speed cloud to the new Mac. A $1,500 configured purchase would be **405.0 hours / ~24 scenario metros**. This only applies to work that would otherwise be paid cloud work; keeping today's Mac incurs no avoided cloud bill. Cloud half/double-speed changes the $899 threshold to roughly **121–488 local-equivalent hours**. At 10 useful shifted hours/week, base payback would take **24.3 weeks**; at 40, **6.1 weeks**. Setup, storage, power/price changes and performance validation move it.

**Hardware-versus-waiting break-even:** if saved *non-overlappable* reviewer time is worth a hypothetical $50/hour, $899 requires **18 hours genuinely saved** (before electricity/setup). The single observed 180 s queue event is 0.05 h; it would take roughly **360 such unrecoverable waits**, not merely 360 background jobs. Waiting while useful independent work proceeds has no demonstrated $50/hour loss. No measured weekly recurrence or recovered judgment time supports claiming this threshold is reached.

Therefore **neither now**, conditional recommendation: first time source ingest, active judgment and queue wait separately across a representative batch and verify a second-machine/cloud capture once separately authorized. Prefer an already-owned configured Mac for independent heavy work before buying. Buy when sustained useful demand exceeds the current worker and either verified avoided cloud workload exceeds ~243 equivalent hours at the cited base price or valuable unrecoverable waits exceed the chosen labor threshold. Use a paid cloud pilot for genuinely temporary excess demand only after runtime/rights approval; do not migrate native visual qualification on a price estimate. This document does not authorize purchases, cloud uploads or unattended jobs.

### 6.5 Ledger text for A3 — compute addendum

Measured existing warm exports Sloan/Lakeview median 3.8/3.5 s; saved three-height web ladders 19.56/34.02 s; fresh ingest and scoring timers absent. One web job had ~180 s queue wait, not a general utilization metric. Metro capacity/cost scenario explicitly assumes 100 cores (~146 km²), 10 min/block ingest and 6 min/block judgment: one/two Macs 2.28/3.64 batches/week with one reviewer; cloud equal-speed projection separately qualified. Recommendation neither purchase nor migration until bottleneck timing; base $899 versus $0.062/min cloud break-even ~243 equivalent hours/~14 scenario metros. No benchmark, code, export or hosting change.

Used: saved A7/A10 timers and hashes in §6.1; exporter/capture timer boundaries; scripts/heavy.sh; current official Apple/GitHub/AWS pages. Mock: none (compute accounting). Deviation: ingest/scoring stage times and machine-versus-judgment percentages are not measured in existing evidence; projections are explicitly conditional, not filled with invented measurements.
