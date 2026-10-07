# WorldEngine live aircraft sources

Research checked 2026-10-06. Scope: aircraft positions around ORD, MDW and DEN, then 20 US metros; consumer display and supplying other apps. Only provider/government documentation and the official ODbL license were used. No accounts were created, paid feeds subscribed to, or sales inquiries sent.

`aircraft-sources.csv` compares nine options: the seven requested providers, plus FlightAware Firehose and adsb.fi. FAA's row distinguishes SCDS transport from STDDS terminal/surface and SFDPS en-route services. Each factual CSV cell includes its source URL or is marked **unclear**; the source column collects the official references. “Unclear” means the reviewed documentation does not establish the answer, rather than permission being implied.

## Recommendations: our own apps

1. **ADS-B Exchange Enterprise — first production candidate.** Its regional feeds and selectable update intervals suit a metropolitan aircraft layer. Request a regional subscription or stream covering Chicago and Denver. This is a recommendation to obtain a suitable contract, not a finding that the standard policy already allows public display: the default restrictions need explicit overrides for WorldEngine's consumer product, caching and end-user distribution. Price and production quotas require a quote. [Enterprise product](https://www.adsbexchange.com/products/enterprise-api/); [acceptable-use policy](https://www.adsbexchange.com/acceptable-use-policy/).
2. **adsb.lol — first budget candidate if ODbL obligations are acceptable.** It offers a free API under an explicitly commercial-capable open database license. Confirm production traffic with its operator and test coverage/availability before committing. This is less certain operationally than a contracted enterprise service: a numeric production quota and freshness SLA are unclear. [API specification](https://api.adsb.lol/api/openapi.json); [published data license](https://www.adsb.lol/docs/open-data/api/); [ODbL](https://opendatacommons.org/licenses/odbl/1-0/).

These rankings are WorldEngine-specific judgments: they favor regional position retrieval and workable consumer distribution over flight itinerary features. They assume an entertainment/information layer and a shared backend. They do not assume any provider has complete surface coverage at the three airports.

## Recommendations: supplying or licensing other apps

1. **ADS-B Exchange Enterprise with an expressly negotiated downstream agreement.** It is the strongest commercial procurement candidate for a regional/global position service, but the default policy prohibits resale and service-bureau/SaaS distribution. The contract must name both WorldEngine's own app and customer apps, including whether customers receive raw coordinates, rendered views, an SDK or a data API. Until such an agreement is offered, downstream rights and price remain unclear. [Enterprise offering](https://www.adsbexchange.com/products/enterprise-api/); [default restrictions](https://www.adsbexchange.com/acceptable-use-policy/).
2. **FAA SWIM through SCDS, using appropriate STDDS/SFDPS services — best US-focused alternative if integration effort is acceptable.** The SAA explicitly contemplates secondary products and indirect consumers. The feed fee is zero, but approval, per-service conditions, messaging ingestion, aircraft blocking and current coverage verification remain necessary. License WorldEngine's processing/software/service layer without claiming ownership of FAA data or treating every service as freely redistributable. [SAA, definitions and sections 3–4](https://support.swim.faa.gov/hc/en-us/article_attachments/29623502764692); [SCDS standards](https://www.faa.gov/sites/faa.gov/files/air_traffic/technology/swim/governance/SCDS-Guideline-Document_v1.1_09.11.2024); [service connection process](https://www.faa.gov/air_traffic/technology/swim/products/get_connected).

**Open-license alternative:** adsb.lol can support a paid service with ODbL compliance, but it cannot supply exclusive proprietary rights over the underlying database. Recipients obtain ODbL rights; derivative database obligations can apply. [ODbL sections 4.4–4.8](https://opendatacommons.org/licenses/odbl/1-0/).

## Why the other options rank lower here

- **OpenSky:** written commercial/operational permission is required. Public free quotas are inadequate for continuous ten-second regional retrieval; contract pricing and downstream rights are unclear. [terms](https://opensky-network.org/about/terms-of-use); [REST quotas](https://openskynetwork.github.io/opensky-api/rest.html).
- **AeroAPI:** published embedded-app rights are useful, but its Standard and Premium licenses both prohibit commercial aircraft situational displays. Whether WorldEngine falls within that category needs written resolution. Premium B2B permission does not authorize raw-data resale. [Standard license](https://uk.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License_Jan2025.pdf); [Premium license](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2025.pdf).
- **Flightradar24:** the API allows commercial use subject to conditions, but raw/enriched-raw redistribution and mixing/backfilling with another live feed are prohibited. The derivative-product test and competing-service restriction need resolution for WorldEngine. [terms, section 6.3](https://www.flightradar24.com/terms-of-service).
- **airplanes.live:** the rendered API docs show Apache-2.0, but its applicability to the returned position data is unclear. The reviewed Terms page did not provide operative permissions; commercial display, resale, retention, pricing and production quotas remain unclear. [API docs](https://airplanes.live/api-docs/); [Terms page](https://airplanes.live/terms-of-use/).
- **adsb.fi:** the public feed is for personal/noncommercial use, with commercial access available only through contact; no eligible commercial tariff or redistribution agreement was established. [official open-data documentation](https://github.com/adsbfi/opendata/blob/main/README.md).
- **Firehose:** a better FlightAware product to investigate for situational displays, with a regional stream and fixed monthly quote. It is not a turnkey resale license. The September 2026 general terms prohibit third-party redistribution without an expressly permitting Order, and impose additional, non-negotiable Aireon restrictions on data-service use. A suitable terrestrial-only product and Order may be worth quoting. [Firehose](https://www.flightaware.com/commercial/firehose/); [current terms, articles 3–4](https://www.flightaware.com/commercial/termsandconditions).

## Cost assumptions and arithmetic

All amounts below are USD, illustrative calculations rather than vendor quotes, excluding taxes, application hosting and engineering. A month is assumed to be **30 days**, continuously operating. Ten-second retrieval produces:

| Geographic queries | Fetches/day | Fetches/30-day month | Mean fetch rate |
|---|---:|---:|---:|
| 1 metro | 8,640 | 259,200 | 0.1/second |
| Chicago + Denver: 2 metros | 17,280 | 518,400 | 0.2/second |
| Separate ORD, MDW, DEN queries | 25,920 | 777,600 | 0.3/second |
| 20 metros | 172,800 | 5,184,000 | 2/second |

These are calculations from the requested cadence. Treat ORD and MDW as one Chicago query only if the chosen region covers both; separate airport queries can overlap and be billed twice. The model assumes one shared backend retrieval per region, independent of the number of app users. Backend fan-out still needs distribution rights.

### FlightAware AeroAPI scenarios

The position-search list rate is **$0.050 per result set of 15 records**. The following uses the advertised incremental volume discounts, assuming all usage is position-search billing and the displayed discount schedule applies to that account. It excludes other endpoints and special negotiated rates. Standard/Premium minimum monthly bills are below these examples. These prices do not solve the display-license restriction. [AeroAPI pricing](https://www.flightaware.com/commercial/aeroapi/).

| Result sets per complete snapshot | Illustrative aircraft count per region | 1 metro/month | 2 metros/month | 20 metros/month |
|---:|---|---:|---:|---:|
| 1 | 1–15 | $5,270.40 | $7,686.40 | $24,272.00 |
| 4 | 46–60 | $11,100.80 | $14,940.80 | $70,928.00 |
| 7 | 91–105 | $14,163.20 | $19,606.40 | $117,584.00 |

Formula: list usage = monthly snapshots × result sets/snapshot × $0.050, followed by incremental tier discounts. The one-page scenario has list usage of $12,960 per metro; after those discounts, $5,270.40. Three separate airport queries at one page each calculate to $9,545.60/month.

A complete multi-page snapshot requires extra pagination requests, so it exceeds one physical HTTP request per ten seconds per metro. Aircraft counts, empty-result treatment and the actual bill remain unclear without sample queries and a vendor-confirmed billing model. At 20 metros × seven sets/snapshot, the average is 14 sets/second, above Standard's published 5/second; Premium publishes 100/second. [pricing and rate limits](https://www.flightaware.com/commercial/aeroapi/).

### Flightradar24 API scenarios

Light positions consume **6 credits per returned aircraft**; full positions consume 8, and an empty result consumes 1. Let A be the mean returned aircraft count per snapshot. Light monthly credits are 259,200 × metros × 6 × A, with empty responses charged separately. [credit rules](https://fr24api.flightradar24.com/docs/credit-overview).

Using the entry top-up rate of $9/30,000 = **$0.0003/credit**, the table is a reference purchase-value calculation before included credits, promotions and volume discounts. It is **not an exact monthly invoice or a guaranteed worst-case bill**. A is a scenario input, not an observed count at ORD/MDW/DEN. [plans and top-ups](https://fr24api.flightradar24.com/subscriptions-and-credits).

| A: mean returned aircraft/region | 1 metro: credits / reference USD | 2 metros: credits / reference USD | 20 metros: credits / reference USD |
|---:|---:|---:|---:|
| 1 | 1,555,200 / $466.56 | 3,110,400 / $933.12 | 31,104,000 / $9,331.20 |
| 15 | 23,328,000 / $6,998.40 | 46,656,000 / $13,996.80 | 466,560,000 / $139,968.00 |
| 60 | 93,312,000 / $27,993.60 | 186,624,000 / $55,987.20 | 1,866,240,000 / $559,872.00 |

Full-position credits are 4/3 of light for equal returned counts. Actual tier/top-up costs depend on response caps, aircraft counts, discounts and credits included in the selected plan. The CSV records standard bundles and the current double-credit promotion; do not assume promotional quantities continue after the qualifying 2026 cycles. [pricing](https://fr24api.flightradar24.com/subscriptions-and-credits); [promotion terms](https://fr24api.flightradar24.com/double-credits-deal-terms).

### Quoted, free and streaming options

- ADS-B Exchange Enterprise, OpenSky commercial and Firehose: eligible prices are **unclear**, requiring a contract/quote. Their personal/research tariffs should not be extrapolated into commercial production. [Exchange enterprise](https://www.adsbexchange.com/products/enterprise-api/); [OpenSky terms](https://opensky-network.org/about/terms-of-use); [Firehose](https://www.flightaware.com/commercial/firehose/).
- FAA SCDS: **$0 feed fee**; compute/bandwidth/integration costs are unclear. A persistent stream is not billed as ten-second REST polling. [SCDS standards, section 3.4](https://www.faa.gov/sites/faa.gov/files/air_traffic/technology/swim/governance/SCDS-Guideline-Document_v1.1_09.11.2024).
- adsb.lol: nominal **$0 published API fee**, conditional on the operator accepting production traffic. No published numeric production quota or paid SLA was established. [API specification](https://api.adsb.lol/api/openapi.json).
- airplanes.live and commercial adsb.fi: **unclear** eligible pricing. [airplanes.live docs](https://airplanes.live/api-docs/); [adsb.fi documentation](https://github.com/adsbfi/opendata/blob/main/README.md).

## Retention, attribution and remaining uncertainties

**FlightAware retention conflict:** January 2025 AeroAPI licenses allow raw data for 30 days and derivative works indefinitely. The September 2026 general terms default to 24 hours, permit different storage in the Order, and specify how negotiated clauses override conflicting terms. Effective retention for a new WorldEngine agreement is **unclear** until the signed Order resolves this. Firehose also needs that Order. [Standard license](https://uk.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License_Jan2025.pdf); [Premium license](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2025.pdf); [September 2026 terms, articles 1 and 3](https://www.flightaware.com/commercial/termsandconditions).

**FR24 retention:** all API endpoints require permanent deletion of accumulated API data after 30 days from first receipt. Do not infer indefinite derived-data retention from the marketing language. [storage rules](https://fr24api.flightradar24.com/docs/storage-rules).

**adsb.lol attribution:** an ODbL-compliant example is: “Contains information from adsb.lol, which is made available here under the Open Database License (ODbL).” Link the source name to the database and the license name to the license. Public use of a derivative database can trigger share-alike and a machine-readable database/changes offer. The license does not automatically require WorldEngine's application code to be open source. [ODbL sections 2.3 and 4](https://opendatacommons.org/licenses/odbl/1-0/). Its feeder-input CC0 notice does not replace the outgoing ODbL license. [input privacy/license](https://www.adsb.lol/privacy-license/); [outgoing API license](https://www.adsb.lol/docs/open-data/api/).

**FAA conditions:** direct and indirect consumers must apply LADD blocking, including relevant historical records, and update their systems within five business days of the monthly list. Downstream recipients need the obligations passed through. The SAA also says redistributed information must not be characterized as FAA data. No general storage TTL or fixed positive attribution text was established. [SAA](https://support.swim.faa.gov/hc/en-us/article_attachments/29623502764692).

**Airport coverage:** official historical FAA material lists ORD, MDW and DEN among surface-surveillance airports as of November 2017. This is not proof that the needed current STDDS product is accessible in SCDS at all three today. Current service/site availability, filters and actual usable position coverage remain **unclear**. [FAA historical deployment report](https://www.faa.gov/sites/faa.gov/files/2022-01/PL_115-254_Sec_502_Air_Traffic_Control_Modernization_NextGen_COMPLETE.pdf); [STDDS overview](https://www.faa.gov/air_traffic/technology/swim/stdds). SFDPS provides en-route data from continental centers; it is not a substitute for terminal/surface coverage verification. [SFDPS overview](https://www.faa.gov/air_traffic/technology/swim/sfdps).

**Real versus estimated positions:** FR24 documents estimated sources; airplanes.live exposes rough estimated and last-known coordinates alongside live position-age fields. Filter by source and age rather than assuming every coordinate is a fresh measured position. Rendering movement between observations is WorldEngine interpolation, not a new measured observation. [FR24 FAQ](https://fr24api.flightradar24.com/docs/faq); [airplanes.live endpoint/schema](https://airplanes.live/api-docs/).

**Freshness:** provider update cadence, HTTP response duration, receiver-to-provider delay and displayed position age are different measurements. No airport-specific end-to-end freshness guarantee was established for ORD/MDW/DEN. A ten-second client refresh does not establish a ten-second-old position.

Before procurement, resolve only the remaining commercial facts: exact regional coverage, observed position-age distribution, traffic quota, consumer coordinate delivery, customer-app/API/SDK distribution, storage/deletion, permitted source mixing, attribution, and complete quoted monthly fees. The comparison records every missing item as unclear; no missing public term has been treated as permission.

## Official source index

The CSV embeds URLs alongside claims. The following collects the main official documents, including pages rendered in a browser when text extraction was incomplete.

- OpenSky: [FAQ](https://opensky-network.org/about/faq); [terms](https://opensky-network.org/about/terms-of-use); [REST documentation](https://openskynetwork.github.io/opensky-api/rest.html).
- ADS-B Exchange: [developer hub](https://www.adsbexchange.com/community/developer-hub/); [enterprise product](https://www.adsbexchange.com/products/enterprise-api/); [acceptable-use policy](https://www.adsbexchange.com/acceptable-use-policy/).
- FlightAware: [AeroAPI product/pricing](https://www.flightaware.com/commercial/aeroapi/); [Standard license, January 2025](https://uk.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License_Jan2025.pdf); [Premium license, January 2025](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2025.pdf); [current general terms, September 2026](https://www.flightaware.com/commercial/termsandconditions); [Firehose](https://www.flightaware.com/commercial/firehose/).
- Flightradar24: [plans](https://fr24api.flightradar24.com/subscriptions-and-credits); [credits](https://fr24api.flightradar24.com/docs/credit-overview); [FAQ](https://fr24api.flightradar24.com/docs/faq); [API account setup](https://fr24api.flightradar24.com/docs/getting-started); [storage](https://fr24api.flightradar24.com/docs/storage-rules); [terms](https://www.flightradar24.com/terms-of-service); [promotion](https://fr24api.flightradar24.com/double-credits-deal-terms).
- FAA: [connect to SWIM](https://www.faa.gov/air_traffic/technology/swim/products/get_connected); [SAA](https://support.swim.faa.gov/hc/en-us/article_attachments/29623502764692); [SCDS standards v1.1](https://www.faa.gov/sites/faa.gov/files/air_traffic/technology/swim/governance/SCDS-Guideline-Document_v1.1_09.11.2024); [STDDS](https://www.faa.gov/air_traffic/technology/swim/stdds); [SFDPS](https://www.faa.gov/air_traffic/technology/swim/sfdps); [historical airport report](https://www.faa.gov/sites/faa.gov/files/2022-01/PL_115-254_Sec_502_Air_Traffic_Control_Modernization_NextGen_COMPLETE.pdf).
- adsb.lol: [open-data API policy](https://www.adsb.lol/docs/open-data/api/); [current API specification](https://api.adsb.lol/api/openapi.json); [feeder-input license](https://www.adsb.lol/privacy-license/); [official ODbL text](https://opendatacommons.org/licenses/odbl/1-0/).
- airplanes.live: [about](https://airplanes.live/about/); [FAQ](https://airplanes.live/faq/); [rendered API documentation](https://airplanes.live/api-docs/); [Terms page](https://airplanes.live/terms-of-use/).
- adsb.fi: [provider's official open-data repository](https://github.com/adsbfi/opendata/blob/main/README.md).

Access notes: FR24 pricing/storage and airplanes.live API docs required browser rendering. No operative airplanes.live data-use terms were established. The FR24 pricing page displayed numeric request limits, but the time unit was unclear in the accessible text. Prices and terms above are the documents visible on the research date; contract-specific exceptions remain unverified.
