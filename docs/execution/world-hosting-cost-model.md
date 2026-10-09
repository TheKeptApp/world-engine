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
