# Sources

Checked 2026-10-07. Provider documentation/marketing is verified as a published claim, not independent coverage, accuracy or latency testing. Published contract versions may differ from an eventual order. No signups.

## FA-PRICE

**Verified** — Published minimums: Standard $100/month, Premium $1,000/month; usage by 15-record result sets and progressive discounts. These are not custom 3D/API redistribution quotes.

[FA-PRICE](https://www.flightaware.com/commercial/aeroapi/)

## FA-STANDARD

**Verified, published November 2022 version** — Consumer embedded use and derived works allowed; raw storage <=30 days. Situational displays excluded and other live-feed combinations require permission.

[FA-STANDARD](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf)

Short quote: “commercial aircraft situational displays”

## FA-PREMIUM

**Verified, published January 2024 version** — Adds B2B embedded/derived distribution, including paid permitted distribution; raw resale is not granted. Same situational-display/mixing limits and raw retention cap; derivative retention permitted.

[FA-PREMIUM](https://uk.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2024.pdf)

Short quote: “Derivative Works may be stored in perpetuity.”

## FA-FIREHOSE

**Verified provider documentation** — Streams positions, surface positions and gate/terminal events through separately licensed layers; major-US surface coverage claimed, exact airport scope unverified; pricing depends on layers and redistribution.

[FA-FIREHOSE](https://www.flightaware.com/commercial/firehose/documentation)

## FA-LATENCY

**Verified provider claim, not measured SLA** — Sub-second event delivery is claimed for Firehose; source-to-client aircraft-position age is not guaranteed by that statement.

[FA-LATENCY](https://blog.flightaware.com/where-flightaware-data-goes-to-work)

## FA-FAQ

**Verified website behavior only** — Public website delay and update cadence must not be treated as an AeroAPI/Firehose latency SLA.

[FA-FAQ](https://www.flightaware.com/about/faq/)

## CIRIUM-STATUS

**Verified schema/product documentation** — Status includes equipment, terminals, gates and baggage. No six-airport gate accuracy measurement established.

[CIRIUM-STATUS](https://developer.cirium.com/apis/cirium-sky-api/flight-status)

## CIRIUM-TRACK

**Verified schema/product documentation** — Tracks/bounding-box positions; raw and derived options. Derived fills coverage gaps and must not be presented as observed.

[CIRIUM-TRACK](https://developer.cirium.com/apis/cirium-sky-api/flight-track)

## CIRIUM-PRICE

**Verified plan categories; unverified unit rates** — Trial and pay-as-you-go advertised; usable price cells and signed display/store/resell terms not verified without account/quote.

[CIRIUM-PRICE](https://developer.cirium.com/apis/cirium-sky-api/subscriptions)

## CIRIUM-COVER

**Verified marketing claim** — Global commercial coverage advertised; this is not proof of surface/stand coverage or airport-specific latency.

[CIRIUM-COVER](https://www.cirium.com/analytics-services/data-cloud-api/)

## OAG-STATUS

**Verified, updated August 2026** — Flight Info API v2 Status adds gates, terminals, actual/estimated times and tail data.

[OAG-STATUS](https://knowledge.oag.com/docs/flight-info-api-migration-fvxml)

## OAG-COVER

**Verified marketing claim** — 3,600+ airports and 6,000+ status updates/minute advertised. These are network totals, not per-flight cadence.

[OAG-COVER](https://developers.oag.com/)

## OAG-ALERT

**Verified** — Near-real-time schedule/status change delivery advertised. Live aircraft coordinates are not established by this status product.

[OAG-ALERT](https://developers.oag.com/apis/flight-info-alerts-v1)

## ADSB-PRODUCT

**Verified provider claim** — Live position options 5 s/500 ms/250 ms; localized operations context; annual subscription commitments. Cadence is not measured end-to-end latency.

[ADSB-PRODUCT](https://www.adsbexchange.com/data-products/)

## ADSB-LICENSE

**Verified** — Commercial entity use requires a commercial license even if free/internal; detailed retention and redistribution rights require contract.

[ADSB-LICENSE](https://support.adsbexchange.com/hc/en-us/articles/37363886073613-I-m-building-a-project-for-my-company-but-we-aren-t-making-money-off-of-it-can-I-get-a-free-API-key)

## ADSB-COMMUNITY

**Verified** — $10/month community 10,000 requests does not supply production commercial rights.

[ADSB-COMMUNITY](https://www.adsbexchange.com/community/developer-hub/)

## ADSB-FIELDS

**Verified schema** — Position age/type fields and optional PIA/LADD flags support filtering; missing flags are not proof of unblocked status.

[ADSB-FIELDS](https://www.adsbexchange.com/api/aircraft/v2/docs)

## AE-PRODUCT

**Verified provider claim** — Regular monthly $299/30k, $599/100k, $1,499/500k calls; introductory $7/$15/$39 only first month. Flight tracker refreshes every few minutes and can fill gaps with schedules; timetables include gates.

[AE-PRODUCT](https://aviation-edge.com/premium-api/)

## AE-TERMS

**Verified, effective June 30 2025** — Own-app/internal use allowed, but resale/distribution and derivative databases forbidden. Retention/cache boundaries and 3D app fanout need clarification.

[AE-TERMS](https://aviation-edge.com/api-terms-of-service/)

Short quote: “Resell, sublicense, lease, lend, or distribute the data”

## FAA-LADD

**Verified** — Participating FAA SWIM vendors must filter LADD aircraft from public display; FAA-source and subscriber filtering differ.

[FAA-LADD](https://www.faa.gov/pilots/ladd)

## FAA-PIA

**Verified** — LADD does not stop ADS-B broadcasts; PIA reduces rapid identification. This is not a universal prohibition on all independently received ADS-B.

[FAA-PIA](https://www.faa.gov/air_traffic/technology/equipadsb/privacy)

## OSM-GATE

**Verified** — Passenger boarding gate, often terminal-side; not automatically a nose-wheel stand.

[OSM-GATE](https://wiki.openstreetmap.org/wiki/Tag:aeroway=gate)

## OSM-STAND

**Verified** — A parking-position node is nose-wheel stop; way endpoint/direction gives stop/alignment; stand ref may differ from gate.

[OSM-STAND](https://wiki.openstreetmap.org/wiki/Tag:aeroway=parking_position)

Short quote: “Put a node where the nose wheel stops.”

## OSM-LICENSE

**Verified** — ODbL permits reuse with attribution and applicable database obligations; independently licensed flight layer needs separate permissions.

[OSM-LICENSE](https://www.openstreetmap.org/copyright)

## OSM-API

**Verified API reference** — Small bbox map extracts support a research inventory, not a production streaming backend.

[OSM-API](https://wiki.openstreetmap.org/wiki/API_v0.6)

## CDA-MAPS

**Verified official reference** — Midway passenger map reference for gate naming; public viewing does not establish mesh-tracing/redistribution permission.

[CDA-MAPS](https://www.flychicago.com/midway/map/Pages/printablemap.aspx)

## CDA-GATES

**Verified dated January 2025 count** — Published ORD 201 and MDW 43 gates; stale reference denominators, not a current 2026 completeness guarantee.

[CDA-GATES](https://flychicago.com/business/CDA/factsfigures/Pages/facility.aspx)

## DEN-MAP

**Verified official reference** — Distinct terminal and A/B/C concourses. Gate/terminal geometry should not be conflated.

[DEN-MAP](https://www.flydenver.com/about-den/facilities/)

## GSP-MAP

**Verified official reference** — Terminal map available for manual naming comparison; reuse rights not established.

[GSP-MAP](https://gspairport.com/before-you-fly/)

## JFK-MAP

**Verified official reference** — Use current airport map during construction; do not rely on old terminal PDF labels.

[JFK-MAP](https://www.jfkairport.com/explore-jfk)

## SFO-MAP

**Verified official reference** — Official terminal/gate maps; a public map is not an open stand-geometry license.

[SFO-MAP](https://www.flysfo.com/vi/maps/interactive-maps)

## ICAO-TYPES

**Verified designator-system reference** — Doc8643 distinguishes aircraft type designators; bulk database redistribution rights not established. Generic model assignment below is authored.

[ICAO-TYPES](https://cfapps.icao.int/doc8643/Fo.en.pdf)
