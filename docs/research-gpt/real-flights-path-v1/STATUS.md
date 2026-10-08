# Status

**Delivered 2026-10-08 (R): filed, not a binding target.** Research and design reference; no approval is implied.

**R's decision (2026-10-08):** Live flights are ON at launch via the adsb.lol hosted feed (ODbL; coordinate with the operator before building); the flight database layer is kept separate; airliners only, no tail numbers, LADD and PIA aircraft suppressed; a lawyer opinion comes before launch (licensing Q54); airport gates later via a paid feed or FAA SWIM; estimated cost about $7-25 a month at 1k monthly users and $35-150 at 100k.

**Owner lane:** L1. **Phase:** Launch (live flights).

ChatGPT research on a low-cost route to real aircraft: one Denver ADS-B receiver for proof, then the adsb.lol feed (ODbL) through a pooled backend, FAA SWIM surface data later, and no actual gate assignments.

Rules the pack states:
- ODbL (adsb.lol): keep notices and attribution; a publicly used derivative database is share-alike with a free machine-readable offer, published before launch; keep this layer separate from proprietary or FAA data.
- Privacy: commercial airliners only; no tail numbers, owner lookup, private-aircraft alerts or identity reconstruction; suppress known LADD and PIA aircraft entirely, not just labels; keep receiver home coordinates private.
- Legal: get a narrow US opinion on public commercial redistribution under 18 USC 2511 and 47 USC 605 before public launch; receive-only, no transmitter.
- Feed: adsb.lol only after production coordination; one approved regional query per 5 s, cached by region, deltas fanned out, never one upstream subscription per phone. adsb.fi, Airplanes.live and ADSBHub not without written agreement; OpenSky excluded.
- Gates: show unknown stands blank and never fill a gate from a schedule guess; output is estimated stand occupancy, not assigned gate; assigned gates wait for an airport, airline or licensed status feed.
- Cost: infrastructure-only ranges of $7-23 (1k monthly users), $35-147 (100k), $243-777 (1M); they exclude labour, legal, tax, SLA and gate data; a free API is not an SLA.

Unverified or authored only: (1) Whether public commercial redistribution of ADS-B data is lawful under 18 USC 2511 and 47 USC 605 (neither is an ADS-B-specific ruling), and what LADD duties bind independent receivers. (2) adsb.lol production rate limits, coverage, latency, SLA and any fee or support terms; no contact made, email unsent. (3) FAA SWIM: full SDD section 4.5 terms, approval for consumer display and API resale, per-airport surface coverage and latency (including Denver), public provenance wording. (4) Commercial data rights for adsb.fi (contact needed), Airplanes.live (no grant found) and ADSBHub (noncommercial downloads only).

Where it differs from R's decisions, or needs a lawyer:
- Sequencing: the pack puts a seven-day Denver receiver proof first, treats adsb.lol as a limited commercial phase with no SLA, and adds receiver redundancy or a licensed fallback in phase 3. R's decision says live flights on at launch via adsb.lol and mentions no receiver or fallback.
- Needs a lawyer: public commercial redistribution of ADS-B data under 18 USC 2511 and 47 USC 605 (before launch, as R decided); ODbL packaging of tiles, meshes and the flight database; FAA SWIM redistribution terms and LADD blocking duties if FAA data is used.
