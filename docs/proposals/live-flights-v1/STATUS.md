# Status

**Delivered 2026-10-08 (R): filed, not a binding target.** Research and design reference; no approval is implied.

**R's decision (2026-10-08):** Live flights are ON at launch via the adsb.lol hosted feed (ODbL; coordinate with the operator before building); the flight database layer is kept separate; airliners only, no tail numbers, LADD and PIA aircraft suppressed; a lawyer opinion comes before launch (licensing Q54); airport gates later via a paid feed or FAA SWIM; estimated cost about $7-25 a month at 1k monthly users and $35-150 at 100k.

**Owner lane:** L1, P1. **Phase:** Launch (live flights are ON at launch).

ChatGPT research and three mocks for showing licensed real aircraft in the 3D world: provider rights and cost comparison, gate inventories for six airports from OpenStreetMap, privacy rules and a phased plan. It recommends a paid FlightAware contract and never evaluates adsb.lol.

Rules the pack states:
- Privacy: class silhouettes only; no tail numbers, carrier marks, owner lookup, identity overlay or persistent identifying trail.
- LADD and PIA: apply the supplier's suppression before fan-out and omit those aircraft entirely, not just their labels; never rebuild identities; a missing LADD flag does not mean safe to show.
- Gates: a scheduled gate is not an occupied gate; an unknown stand means no parked aircraft; live taxi needs observed surface data; reconstructed taxi is labelled and never exported as observed.
- Provider: no personal or community tier at launch; the signed order must name consumer 3D display, fan-out, retention and exports; one licensed source, no blending until licensed.
- ODbL: OSM airport geometry keeps its OpenStreetMap contributors credit and ODbL duties, stays separate from proprietary flight data, and the combined distribution needs review.
- Cost: poll per geographic cell, never per user; the dollar figures are assumptions from FlightAware list prices, not quotes.

Unverified or authored only: (1) Whether a non-operational 3D map falls inside FlightAware's published exclusion for commercial aircraft situational displays, and whether normalised records can be resold through an API; needs written contract terms. (2) End-to-end position age and latency for every provider; the sub-second Firehose figure is a marketing claim, not an SLA. (3) Gate accuracy, gate-change latency and stand-occupancy accuracy at the six airports; OSM completeness percentages are null and counts come from bounded extracts. (4) Production prices and retention or resale rights for Firehose, Cirium, OAG and ADS-B Exchange at 1k, 100k and 1M users (quote only).

Where it differs from R's decisions, or needs a lawyer:
- Feed choice: recommends a scoped FlightAware Firehose contract as the first production bid, AeroAPI only as a prototype after written 3D-display approval, Cirium as fallback. adsb.lol, adsb.fi, Airplanes.live and FAA SWIM are never evaluated as feeds. R chose the adsb.lol hosted feed.
- Cost: its priced scenarios use the AeroAPI list benchmark: about $1,358 a month at 1k users, $7,907 at 100k, $72,483 at 1M (Firehose unpriced, quote only). R's estimate is about $7-25 at 1k and $35-150 at 100k.
- Launch posture: says no live launch until a signed order explicitly covers the use, and starts with labelled simulated approach demos. R has live flights on at launch.
- Needs a lawyer or contract text: FlightAware's published Standard and Premium licences exclude commercial aircraft situational displays; API resale of normalised records, other jurisdictions' privacy law and the combined OSM plus flight distribution need review. It does not raise the ADS-B interception-law opinion (18 USC 2511, 47 USC 605) that R wants before launch.
