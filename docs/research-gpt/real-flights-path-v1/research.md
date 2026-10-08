# Research and phased decision
V = source verified, A = interpretation/design/estimate, U = unresolved. All sources checked 2026-10-07.

## 1. ADS-B and privacy
**V:** US aeronautical interception has an exception in 18 USC 2511(2)(g)(ii)(IV). **U:** this is not an ADS-B-specific commercial-display ruling. Section 605 separately addresses radio publication/use and exceptions. **A:** ordinary receive-only ADS-B experimentation is a sensible starting point; obtain a narrow US legal opinion on public commercial redistribution under both statutes before launch. No transmitter is proposed. [18 USC 2511](https://uscode.house.gov/view.xhtml?edition=prelim&num=0&req=granuleid%3AUSC-prelim-title18-section2511); [47 USC 605](https://uscode.house.gov/view.xhtml?edition=prelim&num=0&req=granuleid%3AUSC-prelim-title47-section605).

**V:** LADD limits participating FAA-derived displays; it does not prevent RF reception. PIA substitutes an aircraft address to reduce identity linkage. **A:** default to commercial airliners only; omit tail numbers, owner lookup, private-aircraft alerts and identity reconstruction. Suppress known LADD/PIA aircraft entirely rather than merely hiding labels. Independent receiver operators are not automatically parties to FAA feed agreements; once FAA data is consumed, apply the agreement's blocking rules across the merged product. Exact independent-receiver obligations remain U. [FAA LADD](https://www.faa.gov/pilots/ladd); [FAA ADS-B privacy](https://www.faa.gov/air_traffic/technology/equipadsb/privacy).

## 2. adsb.lol
**V:** public API data is ODbL; inbound feeder contributions are CC0 where possible. These are different grants. The production request says “please contact me so I do not break your application by accident.” **A:** operational coordination, not evidence of a commercial prohibition or paid contract. Production rate limits, coverage latency and SLA are U. Contact info@adsb.lol; the draft is unsent. [adsb.lol API](https://api.adsb.lol/docs); [adsb.lol licensing](https://www.adsb.lol/privacy-license/).

**V:** ODbL allows commercial use. Preserve notices and attribution; publicly used derivative databases must be share-alike. Section 4.6 requires a machine-readable database or complete alterations/method including added contents, free online. Produced works need attribution; software itself is excluded. Independent collective databases need not all adopt ODbL. Additional downstream restrictions cannot defeat licensed rights. **A:** treat normalization, filtering, history and enrichment as potentially derivative; keep this layer separate from proprietary or incompatible FAA data. Publish the compliant offer before launch. Charging for service does not make the underlying data exclusive. [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/).

**A:** relay one approved regional query per five seconds, cache by region, fan out deltas; never give every phone an upstream subscription. Keep timestamp, source, position method, quality and privacy state. Hide stale aircraft after a short timeout; interpolation is animation, not new measured data. All thresholds require field validation. Feeder-only reAPI has separate IP access rules: [adsb.lol reAPI](https://www.adsb.lol/docs/feeders-only/re-api/).

## 3. FAA SWIM / surface data
**V:** FAA FAQ states “Currently there is no cost for data.” Interface costs fall to consumers. Request an organizational account through the agreement portal, select SMES and relevant flight services, then arrange SCDS/SWIFT access and approved filters. Do not assume immediate approval. [FAA SWIM FAQ](https://www.faa.gov/air_traffic/technology/swim/questions_answers); [SWIFT support](https://support.swim.faa.gov/hc/en-us).

**V:** actual **STDDS Surface Movement Event acknowledgment v1.4**, WSDD NAS-JMSDD-4307-003, covers tracks/events at selected towers. It recognizes marketed secondary products; redistribution must not be characterized as FAA data. Businesses are bound; additional SDD §4.5 terms apply. LADD blocking includes protected historical intervals, downstream consumers, and monthly list updates within five business days. No ownership transfer or reliability warranty. **U:** full current SDD §4.5, World State API resale approval, airport availability and public provenance wording. Obtain them before integration. [FAA STDDS SMES agreement v1.4](https://aa.data.faa.gov/data/service.jsf?uuid=4ad245f2-038f-47c0-be25-5e3b77ed748b).

**V:** SCDS adds cloud-access requirements; duplicate subscriptions require internal redistribution. This is not public-resale permission. [SCDS access agreement v1.0](https://support.swim.faa.gov/hc/en-us/article_attachments/29623502764692); [SCDS guidelines v1.1](https://www.faa.gov/sites/faa.gov/files/air_traffic/technology/swim/governance/SCDS-Guideline-Document_v1.1_09.11.2024).
**V:** STDDS aggregates ASDE-X/ASSC and other tower sources. Its overall airport count must not be treated as surface-track coverage. **U:** end-to-end latency and apron coverage for a specific airport, including Denver, require approved sample testing. [FAA STDDS](https://www.faa.gov/air_traffic/technology/swim/stdds).
**A:** ask FAA explicitly about consumer entertainment display, retained observations, commercial API redistribution, secondary-consumer contracts, suppression audit and attribution. SWIM is a US path, not a global replacement.

## 4. Other feeds
**V:** adsb.fi self-service data is personal/noncommercial; commercial use requires contact. [adsb.fi data terms](https://github.com/adsbfi/opendata/blob/main/README.md).
**U:** Airplanes.live commercial data rights: retrieved terms page had no substantive grant. API/spec Apache-2.0 does not establish a flight-data license. [Airplanes.live terms](https://airplanes.live/terms-of-use/).
**V/U:** ADSBHub website downloads are noncommercial; separate commercial live-feed rights were not established. [ADSBHub disclaimer](https://www.adsbhub.org/disclaimer.php).
**A:** airport/operator feeds may be economical under individual written permission, but are not a verified nationwide free solution. Do not scrape airport screens or assume public access permits reuse. Own receivers and adsb.lol are the practical candidates; SWIM is the conditional public-service candidate. OpenSky is deliberately excluded from this commercial launch recommendation.

## 5. Gates without a paid feed
**A:** possible output is estimated stand occupancy, not assigned gate. OSM gate/parking-position geometry supplies location only; stand labels, terminal connections and georeferencing need validation. Use fresh surface positions, repeated stationary observations, heading, aircraft dimensions and uncertainty containment inside a vetted stand polygon. Reject ambiguous adjacent stands. A stopped taxiway aircraft is not a gate arrival.
**A:** candidate starting thresholds: speed <1 knot for 60 seconds, position age <10 seconds, 95% uncertainty footprint inside stand, no overlapping candidate. They are unvalidated and must not be advertised as measured accuracy.
**U:** real gate assignment, passenger gate changes, jet-bridge state and authoritative in-block/out-block times cannot be guaranteed from RF reception or SMES alone. Radio silence means unknown, not empty. Show unknown stands blank; never populate a gate by schedule guess. A Denver home receiver cannot promise terminal-apron reception.
OSM definitions: [gate](https://wiki.openstreetmap.org/wiki/Tag:aeroway%3Dgate), [parking position](https://wiki.openstreetmap.org/wiki/Tag:aeroway%3Dparking_position). Definitions are reference links; current airport completeness is not newly audited here.

## 6. Phases [A]
1. Local proof: one receiver, one Denver view, seven-day coverage/latency log; local raw observations separated from aggregator-returned/MLAT data. Legal interpretation and privacy design reviewed before public launch.
2. Limited commercial live sky: production-coordinated adsb.lol, ODbL offer and attribution; only approved regions, stale-data handling and no gates. Wider user reach must not increase upstream polling per user.
3. Reliability: independent receiver redundancy, negotiated community capacity or licensed fallback; operational monitoring. No free-feed SLA claimed.
4. US surface pilot: approved SWIM subscriptions, full service terms, LADD pipeline and one validated airport. Keep FAA data separate from ODbL derivatives unless compatibility is established.
5. Estimated occupancy: validated stands and confidence labels. Actual assigned gates wait for an airport/airline or licensed status feed.

## 7. Cost limits
See cost-estimate.json. MAU is not simultaneous viewers. The figures are incremental flight-layer infrastructure estimates, not aircraft-provider quotations. Free published data prices exclude negotiated production support, integration labor, legal work, staff, worldwide receivers and authoritative gate feeds. A one-million-user nationwide/global SLA remains U.
