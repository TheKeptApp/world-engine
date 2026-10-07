# WorldEngine Live Layers API Catalog v1

Research date: **2026-10-07**. 53 source/product entries. Proposal only; no signups, accepted agreements, API-key requests or integrations. Research used primary product documentation, official licensing pages and official vendor support statements. Quotes and links are in [sources.md](sources.md); the comparison matrix is [sources.csv](sources.csv).

**Recommendation: build a rights-audited public-data core, then buy narrowly scoped commercial enrichments. Do not sell an aggregated feed merely because every upstream API is callable.** An application's display license is not a World State API redistribution license.

## Reading the findings

GREEN = positive evidence supports the stated use **within the row's named scope**. YELLOW = permission, provenance, retention or contract unresolved. RED = reviewed standard terms conflict with that use; a negotiated license could change it. Every rating is an author assessment, not a supplier certification. CONDITIONAL fields state the condition; UNVERIFIED means the research did not establish the answer, not that the use is forbidden.

DISPLAY means embedding content in our apps. STORE means persistent cache/archive. RESELL means paid downstream machine-readable raw, normalized or reconstructable supplier data. DERIVE means producing transformations or indices, which can remain contract-restricted. Pass-through also distributes data and requires a valid supplier/customer entitlement. Normalizing a feed, hiding its name, or calling it an index does not grant new rights.

Facts in source entries are verified against linked sources on the research date, except fields explicitly labeled UNVERIFIED, inference, approximately, marketed or ASSUMPTION. Coverage counts are vendor claims, not independent completeness tests. Cadence is not latency: measurement time, transmission, publication, ingestion and response duration differ. No universal end-to-end latency SLA was verified. GREEN government entries exclude third-party inputs and restricted notices; check actual dataset metadata, including worldwide CC0 where available.

## Top 15 layers: value ÷ cost and license safety

This is a reproducible **judgment ranking**, not measured revenue. Value V is 1–5; cost/burden B is 1–5 and includes integration, operation and supplier cost. Safety factor L is 1 for a scoped GREEN output, 0.35 for YELLOW and 0 for RED. Score = V/B × L. Ties ordered by launch relevance. “$0” below means supplier data acquisition, not operating cost.

| Rank | Layer / selected route | V | B | L | Score | Why / gating condition |
|---:|---|---:|---:|---:|---:|---|
| 1 | Own sun, twilight and shadows | 5 | 1 | 1 | 5.00 | Always useful; ownership is an explicit assumption to audit |
| 2 | NWS forecasts and severe alerts | 5 | 1 | 1 | 5.00 | $0 US core; preserve official issue time and notices |
| 3 | NOAA snowpack / SNODAS | 5 | 2 | 1 | 2.50 | Strong seasonal scene signal; modeled grid, not local plowing |
| 4 | NOAA MRMS rain / radar | 5 | 2 | 1 | 2.50 | Immediate world-weather value; whitelist cleared precipitation products |
| 5 | USGS river stage / flow | 4 | 2 | 1 | 2.00 | $0 station truth; modern API, provisional flags |
| 6 | CO-OPS tides / lake levels | 4 | 2 | 1 | 2.00 | $0 coastal state; datum and predicted/observed distinction |
| 7 | NOAA HMS smoke extent | 4 | 2 | 1 | 2.00 | $0 visual haze signal; smoke aloft is not ground AQI |
| 8 | Copernicus CAMS AQ/model fields | 4 | 2 | 1 | 2.00 | Open licensed atmospheric context; product/version attribution |
| 9 | License-cleared direct transit, e.g. BART | 4 | 2 | 1 | 2.00 | Animate real service; every operator needs its own rights audit |
| 10 | Cleared road works, e.g. Caltrans tabular records | 4 | 2 | 1 | 2.00 | Useful street state; permits/feeds are incomplete |
| 11 | Cleared municipal permits, Denver/NYC | 3 | 2 | 1 | 1.50 | Affordable planned change signal; not evidence of active work |
| 12 | Open public events / holidays, NYC + OGL example | 3 | 2 | 1 | 1.50 | Scheduled neighborhood context; not crowd measurement |
| 13 | EPA UV forecast | 3 | 2 | 1 | 1.50 | Practical outdoor context; canopy exposure remains modeled |
| 14 | NASA Black Marble night-light baseline | 3 | 2 | 1 | 1.50 | Regional night/sky-glow reference; not live windows |
| 15 | NOAA marine buoy conditions | 3 | 2 | 1 | 1.50 | $0 marine context; offshore waves differ from beach surf |

AirNow is high-value for our apps (GREEN) but its multi-agency resale scope remains YELLOW, so it does not outrank cleared API outputs. Commercial flights, traffic, parking and events are valuable optional layers; unknown redistribution pricing makes their value/cost scores premature.

## Requested head-to-head choices

| Category | Comparison and recommendation |
|---|---|
| Flights | OpenSky needs written commercial operational permission; ADS-B Exchange needs enterprise terms. FlightAware Standard supports embedded B2C use but limits storage to 30 days and does not clear a raw B2B API. Airport-owned feeds can be purpose-restricted: Schiphol is not a generic ambient-world grant. FAA airport status is a cheaper operational-status layer, not flight tracks; NOAA airport weather is not flight movement. Request comparable enterprise quotes for positions, historical archive, derived ephemerides and downstream tenants. |
| Traffic | TomTom offers a server-feed product, but paid tariff and downstream rights were not cleared. HERE and INRIX standard sublicensing restrictions conflict with a generic resale API. Google Routes supplies route/ETA results, not a bulk traffic layer, and mapped results must use a Google Map: RED for the OSM overlay. Evaluate TomTom/HERE/INRIX only against a specific redistribution Order Form. |
| Events | Ticketmaster is a useful discovery product but standard resale is restricted; its feed may need partner approval. SeatGeek prohibits systematic storage and third-party service access under reviewed terms. PredictHQ is the strongest stated enrichment fit, but raw API resale and retention need an Order Form. Start with explicitly open local event data; licensed official sports schedules are a separate procurement, not an assumption that league endpoints are open. |
| Air quality | AirNow offers shared bulk files and app display with agency guidance; paid API resale is unresolved. PurpleAir supports database workflows but current point pricing and rehosting rights were not verified. CAMS is a stronger license-cleared modeled foundation. Label model, regulatory station, community sensor and AQI aggregation distinctly. |
| Pollen | CAMS European pollen is open licensed but geographically limited/coarse. Google Pollen has public billing and specific cache/derivative allowances, yet raw resale remains restricted and OSM presentation needs audit. Ambee markets global pollen but requires a contract for storage/resale. No verified global zero-cost, unrestricted street-level pollen source was established. |
| Parking / crowds | Parkopedia and INRIX need territorial coverage, occupancy methodology and distribution quotes. Predicted availability is not a parking sensor. Events and predicted attendance do not establish current crowd counts. No sufficiently licensed nationwide realtime crowd feed was established. |

These conclusions reference the corresponding detailed entries in [sources.md](sources.md), which include the primary links and evidence.

## Cost model: users are not upstream requests

Prices are USD/month, excluding tax, infrastructure, egress and negotiated discounts. Planning assumption S = **30 origin requests per monthly active user**: 30,000 / 3,000,000 / 30,000,000 requests at 1k / 100k / 1M users. For continuously polled premium data, a sensitivity case of 30 minutes/day at 30-second refresh is **1,800 requests/user/month**: 1.8M / 180M / 1.8B. These are explicit workload assumptions, not demand forecasts.

| Public tariff example | 1k users | 100k users | 1M users | Billing caveat |
|---|---:|---:|---:|---|
| Google Routes Pro | $250 | $13,150 | $37,900 | Graduated tier calculation; matrices bill elements |
| Google Pollen | $250 | $8,150 | $22,650 | Baseline S requests; caching must obey specific service terms |
| Google Air Quality | $100 | $4,050 | $11,300 | Baseline S requests; endpoint/trigger choices matter |
| FlightAware illustrative position search | $1,500 | $150,000 | $1,500,000 | $0.05/15-record result batch; assumed one batch/request, before volume contracts |

Google prices: [official pricing](https://developers.google.com/maps/billing-and-pricing/pricing). Routes Pro calculation uses 5k free, then $10/$8/$6/$3/$0.75 per 1k at 100k/500k/1M/5M thresholds. Pollen uses 5k free then $10/$8/$4/$1/$0.25; Air Quality uses 10k free then $5/$4/$2/$0.50/$0.10 at those thresholds. FlightAware's illustration is not a complete endpoint mix or enterprise quote; see its source entry.

For legally reusable public data, **ingest once per region/station/grid and serve many users**. 100 areas hourly × 720 hours/month = 72k upstream fetches, independent of user count, before batching and pagination. Six-minute polling multiplies that by 10. This cannot bypass a supplier license that charges per end user or forbids shared caching. $0 data fee at all three user counts is not an unlimited-request promise.

Downstream baseline S with a 10KB response implies roughly 0.3GB / 30GB / 300GB outbound payload/month before protocol overhead. This is arithmetic, not a hosting quote. Budget CPU, raster processing, archive growth, database, CDN/egress and availability separately after regions, payloads and concurrency are known. Contract-only sources are marked quote/UNVERIFIED, never assigned invented prices.

## Current-stack audit

| Current source | Decision |
|---|---|
| NWS | GREEN for identified NWS outputs; partner/branding exceptions |
| MRMS | GREEN for audited precipitation/radar products; private lightning-related inputs are not blanket cleared |
| NOHRSC / SNODAS | GREEN NOAA model products; preserve model date and separate raw observations |
| Own sun/shadow | GREEN assumption of owned implementation/output; audit dependencies |
| CTA | YELLOW for ambient app purpose; RED standalone resale under published terms |
| RTD | GREEN application use; YELLOW paid API scope despite explicit redistribution grant |
| CelesTrak | YELLOW commercial resale/derived API rights until positive grant established |
| NASA Black Marble | GREEN NASA-produced dataset with metadata audit; use as baseline, not realtime light activity |

## API product rules and implementation decisions

1. Maintain a versioned rights registry **per dataset/endpoint/product and operator**, not just supplier. Record display/store/raw redistribution/derivation separately; retention, territory, attribution, sublicensing, account ownership, costs and revocation.
2. Permit shared caching only when STORE and downstream rights allow it. Keep commercial pass-through in a tenant-entitled adapter; a user-provided key alone does not establish that adapter's distribution rights.
3. Return observedAt, issuedAt, validAt/validUntil, ingestedAt, source, sourceRecordId, quality/provisional flag, observed/forecast/scheduled/predicted classification and rightsProfile version. Geometry/location uncertainty also matters. Do not silently replace an unavailable observation with a forecast.
4. “Any place and time” must return explicit unsupported, unavailable, stale or unlicensed status. Store historical data only inside retention grants; future events and forecasts have different uncertainty. Many feeds cover only selected stations, cities or currently operating seasons.
5. Derived outputs should carry source lineage and cannot expose reconstructable protected data without permission. Supplier-specific attribution must propagate to API clients and final app surfaces.
6. Separate street closures from work permits, measured crowds from predicted attendance, surface AQI from aloft smoke, live snow from model snowpack, beach advisories from old lab samples, and propagated satellites from measured aircraft positions.
7. Monitor source schema, rights-page changes, source age and provenance. USGS WaterServices migration, WQP old-UI gaps, CelesTrak catalog formats and seasonal resort/beach feeds need lifecycle checks.
8. First procurement questions: explicit paid API redistribution? raw vs normalized vs aggregates? global territories? tenant/end-user counts? archive and termination deletion? derived/AI use? attribution propagation? blend restrictions? minimum commitments and real observation-latency SLA?

## Remaining uncertainties

No commercial contracts were inspected beyond public standard terms. Public paid rates were not verified for TomTom, HERE, INRIX, Parkopedia, OpenSky, ADS-B Exchange, PredictHQ, Ambee or ski feeds. PurpleAir current price/point rules and license remained unresolved. Several city datasets have public access but unclear commercial redistribution. Nationwide transit, parking, road closures, crowds, pollen and ski conditions are not single uniformly licensed datasets. These gaps are explicitly YELLOW, except specific standard prohibitions marked RED.

## Files

- README.md — ranked layers, comparisons, cost model, current-stack audit and recommendations.
- sources.csv — 53 rows, separate rights and app/API ratings, costs, freshness, attribution and sources.
- sources.md — human-readable evidence with short quotations and links.
