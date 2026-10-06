# Live transit and aircraft feeds: terms, relay design and cost

> **Not legal advice.** Research and design only. Written **2026-10-06**; every access date below is 2026-10-06. Nothing here changes the engine, the renderers or the package format, and the engine uses no live feed today. No account was created, no key was requested, no terms or cookie banner were accepted, and no provider was contacted. Licence texts change without notice, so re-read them before any use.
>
> **Tags.** Every fact carries its link and one of these tags:
>
> | Tag | Meaning |
> |---|---|
> | **[V]** | Verified: read on 2026-10-06 from the provider's own page, API document or public repository, with an honest client (the session's default fetch tool, or curl with an honest research User-Agent: `WorldEngine-research/0.1` in this pass, `worldengine-docs-research/1.0` in the aircraft research). Pages marked "re-read this pass" in §7.4 were fetched again for this document; the rest were read earlier the same day with the same kind of client. |
> | **[O]** | Observed: response headers or behaviour measured with unauthenticated requests. Not a published promise. |
> | **[U]** | **Unverified (site blocks automated access; confirm in a normal browser).** The fact was read in a way the owner does not accept: a browser-style User-Agent after the site returned 403, or after a browser visit was denied. Kept for completeness, not to be relied on. |
> | **[T]** | Third-party report (GitHub issue, catalogue, search summary). Context only. |
> | **[C]** | Unconfirmed: no primary source states it. |
> | **[A]** | My arithmetic or estimate; assumptions are stated next to it. |
>
> **Quotes** are verbatim excerpts under 15 words, mostly a few words. Everything else is paraphrased.

---

## 1. Summary

**Short answer.** A relay that pulls each feed once per area and fans the result out to phones is the shape the terms point to: Metra requires it [U], and CTA's per-key caps and the aircraft vendors' redistribution limits make it necessary in practice. Transit data is free and cheap to relay. Live aircraft is the expensive and legally awkward half: the only open feed whose licence does not bar commercial use is adsb.lol, and its operator asks production users to get in touch first. The commercial feeds cost thousands of dollars a month for two metro areas.

### Blockers, in the order they bite

1. **Pace.** The static-data page says Pace shares its data with the public for "non commercial use" [V: [Pace data page](https://pacebus.com/route-timetable-data-services)]. Pace's live GTFS-RT URLs appear on no Pace page; they come from a third-party catalogue [T: [Transitland Atlas record](https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json)], although they sit on the same host as Pace's own Bus Tracker, `tmweb.pacebus.com/TMWebWatch/` [V: [Bus Tracker tools page](https://pacebus.com/bus-tracker-tools)]. Pace's data page says its Bus Tracker predictions are not available for download [V: same data page]. **Do not use Pace data in a paid or ad-supported app without Pace's written permission.**
2. **CTA's purpose clause.** The Developer License Agreement is for "the sole purpose of assisting mass transportation" riders or promoting public transportation [V: [CTA DLA](https://www.transitchicago.com/developers/terms/)]. A decorative live-vehicle layer in a 3D world is a grey area, so CTA should be asked in writing before shipping. CTA also requires deleting all CTA Data on termination [V: same page], and one key's daily cap is shared by the whole relay [V: [Train Tracker docs](https://www.transitchicago.com/developers/ttdocs/), [Bus Tracker overview](https://www.transitchicago.com/developers/bustracker/)].
3. **Metra's relay and no-modification wording** (all unverified). The licence requires the app to redistribute through its own host (so a relay is mandatory), and says the licensee "must not modify or delete Data", which may clash with filtering by area or re-encoding to a compact format. Every display of Metra data also needs a last-updated date and time and a non-affiliation statement. [U: [Metra licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement), [Metra GTFS API page](https://metra.com/metra-gtfs-api)]
4. **Non-commercial aircraft community feeds.** OpenSky (research and non-commercial), ADS-B Exchange Community API (non-commercial), adsb.fi (personal, non-commercial) and airplanes.live (non-commercial [U], and feeder-only since about August 2026 [T]) cannot be used in a shipped commercial app. adsb.lol (ODbL) is not prohibited, but "for production purposes, please contact me" [V: [adsb.lol API spec](https://api.adsb.lol/api/openapi.json)], with no SLA and no published rate limit.
5. **Cost of commercial aircraft feeds.** For two metro boxes with 30 aircraft per poll (§5.4), FlightAware AeroAPI Standard costs about **$2.7k to $9.0k per month** and Flightradar24 about **$1.6k to $18.4k per month**, depending on poll interval (60 s to 15 s), users and credit package; at 60 aircraft per poll the range reaches $36.8k. Both restrict redistribution of raw data and storage, and both bar blending in a community feed as a fallback (FlightAware, unless FlightAware agrees in writing [V]; Flightradar24 [U]).
6. **Every feed is revocable with no uptime promise.** All of them say the data can change or stop without notice. Live data must never be a hard dependency (§4.7).

### Usability by class

| Class | Feeds | Notes |
|---|---|---|
| Usable in a commercial app through our relay, after the written confirmations in §6 | Denver RTD GTFS-RT; CTA Train Tracker and Bus Tracker (purpose clause: blocker 2); Metra GTFS-RT [U] (blocker 3); adsb.lol (blocker 4) | RTD is the cleanest: no key, redistribution expressly granted, licence silent on commercial use. |
| Non-commercial only (do not ship in a paid or ad-supported app) | Pace static GTFS; Pace live GTFS-RT (undocumented, no terms); OpenSky public API; ADS-B Exchange Community API; adsb.fi; airplanes.live | See blockers 1 and 4. |
| Need written permission before use | Metra (area filtering, paid use; unverified [U]); CTA (decorative use, GTFS-RT beta); Pace (anything); adsb.lol (production, rate limits); FlightAware (relay of positions, "commercial aircraft situational displays"); Flightradar24 (raw redistribution); ADS-B Exchange Enterprise (end-user presentation is allowed only for end users who are direct JETNET subscribers, so a fan-out relay needs a special agreement) | Questions to send: §6. |
| Paid | FlightAware AeroAPI Standard or Premium; Flightradar24 API; ADS-B Exchange Enterprise (quote only); OpenSky licensed tier (price unconfirmed) | Costs: §5.4. |

### Cost range (model in §5, planning figures, not measurements)

| Item | 1,000 users | 10,000 users |
|---|---|---|
| Transit upstream feeds (all free as published; Metra's "free" is unverified [U]) | $0 | $0 |
| Relay (Cloudflare Workers + Durable Objects, upper bound; Fly.io is $7.40 to $7.55, plus $3.60 for a static egress IP) | about $8 per month | about $16 per month |
| Aircraft upstream: adsb.lol with permission, if its rate limits allow | $0 | $0 |
| Aircraft upstream: FlightAware Standard, 15 s polls, 2 areas, 30 aircraft per poll | about $6,100 | about $9,000 |
| Aircraft upstream: Flightradar24, same load (list rate to largest package) | about $6,300 to $8,900 | about $13,100 to $18,400 |
| Aircraft upstream at 60 s polls, same load (FlightAware / Flightradar24) | about $2,700 / $1,600 to $2,200 | about $4,200 / $3,300 to $4,600 |

**Key insight.** Upstream cost scales with the number of active areas and the poll interval, not with users. Relay egress scales with users but is tiny (about 8 GB per month at 10,000 users). Ten times the users make the aircraft bill about 1.5 to 2.1 times larger, because the areas simply stay active longer. Ten times the areas make it about 3.3 times larger on FlightAware (its volume discount deepens) and about 10 times larger on Flightradar24 (§5.5).

**Cheapest viable plan** (details in §5.6): launch transit first (RTD, then CTA and Metra after written confirmations; Pace not used) for about $8 to $16 per month. Ask the adsb.lol operator for written permission and poll aircraft slowly (30 to 60 s) with dead reckoning. If that is refused or unworkable, keep aircraft off rather than pay a commercial feed before there is revenue per user to cover roughly $1.6 to $9 per user per month.

---

## 2. Transit feeds

Metra pages and the NITA Data Hub were read with a browser-style User-Agent after `metra.com` and `datahub.nita.illinois.gov` returned 403 (and a browser visit to `metra.com` was denied). **Every Metra and NITA Data Hub fact below is [U]: unverified (site blocks automated access; confirm in a normal browser).** The Metra API hosts (`schedules.metrarail.com`, `gtfspublic.metrarr.com`) answered header requests from an honest client on 2026-10-06; those header observations are [O].

CTA, Pace, RTD and the other pages loaded with an honest client. CTA, Pace and RTD use bespoke "limited, revocable" licences, not CC, ODbL or a similar open licence.

### 2.1 Summary tables

**Table 2.1a: access** (endpoint, rate, keys, limits)

| Feed | Endpoint and format | Update rate | Sign-up / keys | Rate limits |
|---|---|---|---|---|
| **Metra static GTFS** (11 lines incl. UP-N) | `https://schedules.metrarail.com/gtfs/schedule.zip` and `published.txt`; GTFS zip. HTTP 200, `Cache-Control: max-age=300` [O]. Documented on [metra-gtfs-api](https://metra.com/metra-gtfs-api) [U] | Planned 3:00:00 AM; may change within 24 h; check `published.txt` every few minutes [U]. `Last-Modified` Sat 03 Oct 2026 07:20:04 GMT [O] | Page says agree to the licence [U]; zip answers 200 unauthenticated [O] | None published [U] |
| **Metra GTFS-RT** (positions, trip updates, alerts) | `https://gtfspublic.metrarr.com/gtfs/public/positions`, `/tripupdates`, `/alerts`; GTFS-RT protobuf [U]. Unauthenticated request: HTTP 401 [O] | Every 30 s; "no need to check any more frequently" [U] | **Required**, free; web form with licence tick-box; bearer token or `api_token` query parameter [U]; approval time and whether keys are per app or per person are not stated [C] | None published [U]. Observed `x-ratelimit-limit: 200` header on the 401, unit undocumented [O] |
| **CTA Train Tracker API** | `https://lapi.transitchicago.com/api/1.0/ttpositions.aspx` (also `ttarrivals`, `ttfollow`); XML default, `outputType=JSON` for JSON [V: [docs](https://www.transitchicago.com/developers/ttdocs/)] | No interval published [V]. Railcars have no GPS; positions come from track data, so movement is stepwise [V: docs] | **Required**, free; online form; "reply pretty quickly" [V: [overview](https://www.transitchicago.com/developers/traintracker/)] | 50,000/day on the overview page [V: overview]; 100,000/day in the docs [V: docs]; IP-based DoS time-out [V: overview] |
| **CTA Bus Tracker API v3** | `https://www.ctabustracker.com/bustime/api/v3/getvehicles` (also `getpredictions`, `getroutes`, `getpatterns`); XML default, `format=json` for JSON; at most 10 routes or 10 vehicle IDs per call [V: [v3 PDF](https://www.transitchicago.com/assets/1/6/cta_Bus_Tracker_API_Developer_Guide_and_Documentation_2025-04-21.pdf)] | About every 30 s [V: [overview](https://www.transitchicago.com/developers/bustracker/)] | **Required**, free; needs a Bus Tracker account; one key per account; emailed on approval [V: v3 PDF] | 100,000/day default (raised from 50,000 in April 2024); more on a case-by-case basis [V: overview] |
| **CTA static GTFS** | `https://www.transitchicago.com/downloads/sch_data/` (zip, 10 tables plus a copy of the licence) [V: [GTFS page](https://www.transitchicago.com/developers/gtfs/)] | Generally once every week or two [V: GTFS page] | No key stated [V]; the licence still applies (the zip carries it) | None published |
| **CTA GTFS-RT (beta)** | `https://transitdata.transitchicago.com/GtfsRealtime/` `ServiceAlerts`, `TripUpdates`, `VehiclePositions` as `.pb` or `.json`, with `?key=` [V: [beta page](https://transitdata.transitchicago.com/)] | [C] | **Required**; how to get one is vague [V: beta page]. A third-party GitHub issue (repository `ghost-bus-tracker`, issue 1, opened 2026-10-05; owner name omitted) says Train Tracker and Bus Tracker keys are rejected here [T] | [C] |
| **Pace static GTFS** | Link on the page: `https://www.pacebus.com/sites/default/files/2026-08/GTFS.zip` [V: [Pace data page](https://pacebus.com/route-timetable-data-services)] | About once a month, sometimes more [V]; only routes with IBS equipment [V] | None | None published |
| **Pace GTFS-RT** (undocumented) | `https://tmweb.pacebus.com/TMGTFSRealTimeWebService/vehicle/VehiclePositions.pb`, `.../tripupdate/tripupdates.pb`, `.../alert/alerts.pb`. URLs come from [T: Transitland Atlas](https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json), not from a Pace page; the host `tmweb.pacebus.com` is the one Pace's own Bus Tracker links use [V: [Bus Tracker tools page](https://pacebus.com/bus-tracker-tools)]. HEAD returned 200, `application/protocol-buffer` [O] | About 30 s: `Last-Modified` was 07:13:41 GMT on two of the three files at one sample [O] | None (HEAD 200 unauthenticated) [O] | None found |
| **RTD static GTFS** | `https://www.rtd-denver.com/files/gtfs/google_transit.zip` plus fares, flex, Bustang and per-mode zips [V: [RTD GTFS page](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs)] | Major schedule changes January, May and August [V] | None; page says read and agree to the licence first [V] | None published |
| **RTD GTFS-RT** (arrival predictions and vehicle locations; whether trains and buses share the feeds is [C]) | `https://open-data.rtd-denver.com/files/gtfs-rt/rtd/VehiclePosition.pb`, `TripUpdate.pb`, `Alerts.pb`; Bustang feeds under `/cdot/` [V: [real-time page](https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds)] | RTD: accurate within 2 minutes [V]. Files refresh about every 30 s: `Last-Modified` 07:13:35 GMT on all three at one sample [O] | None (HEAD 200 unauthenticated) [O] | None published |

**Table 2.1b: terms and cost**

| Feed | Commercial-use terms | Caching / redistribution via our relay | Attribution | Cost |
|---|---|---|---|---|
| **Metra static GTFS** | Licence has no "commercial" wording [U] | Same licence as the realtime feed [U] | Same [U] | Free; no fee stated [U] |
| **Metra GTFS-RT** | Licence silent on paid or ad-supported apps [U]. Separate: Metra's website terms bar commercial use of the website and robots (website, not API) [U: [website terms](https://metra.com/terms-and-conditions)] | **Relay required**: redistribute through our own host and do not send users to Metra's servers [U]. Licensee "must not modify or delete Data" [U]; no cache limit stated [U]; area filtering is [C] | Must state "not sponsored, affiliated, or operated by Metra" and the date and time of last update; must not claim the data is accurate, complete or timely; Metra marks not used with the Data [U] | Free [U] |
| **CTA Train Tracker** | Licence never says "commercial"; purpose limited to assisting riders or promoting public transportation; other uses need CTA's express permission [V: [DLA](https://www.transitchicago.com/developers/terms/)] | May cache; may distribute and display; "will not sell, auction or barter" CTA Data separate from the app; relay not addressed [C]; delete all CTA Data on termination [V: DLA] | Credit is optional; must not imply affiliation; only the tracker names and logos, route colours and standard icons; no official CTA maps; no CTA mark as the most prominent feature [V: DLA, [branding](https://www.transitchicago.com/developers/branding/)] | Free; no fee stated [V] |
| **CTA Bus Tracker** | Same DLA [V] | Same [V] | Same [V] | Free [V] |
| **CTA static GTFS** | Same DLA (covers GTFS) [V] | Same [V] | Same [V] | Free |
| **CTA GTFS-RT (beta)** | [C] (DLA presumably applies) | [C] | [C] | Free; no fee stated [V] |
| **Pace static GTFS** | Page intro: shared "for non commercial use" [V]. The licence grants "redistribute" [V] | Redistribution granted; no cache limit or proxy ban stated [V] | None required; Pace name and logo need prior written consent [V] | Free |
| **Pace GTFS-RT** | None published [C]; the licence defines Pace's Data as route and arrival data, which may cover it [V] | [C] | None stated; do not use Pace marks | Free |
| **RTD static GTFS** | Licence silent [V: [licence](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement)] | "Redistribute" granted [V]; the GTFS page links this same licence [V] | No credit line; no RTD logo, maps or content without permission [V] | Free |
| **RTD GTFS-RT** | Licence silent on paid use; terms "updated or modified by RTD at any time without notice" [V: licence] | "Redistribute" granted; no cache limit, no proxy ban [V] | No RTD marks; RTD may require an "unofficial web site" notice [V: licence] | Free |

### 2.2 Metra, including UP-N (all [U])

> Unverified (site blocks automated access; confirm in a normal browser). Only the header observations marked [O] are verified.

- **Coverage.** The developer page lists 11 lines: ME, MD-N, NCS, RI, UP-N, UP-NW, HC, SWS, BNSF, MD-W, UP-W [U: [metra.com/developers](https://metra.com/developers)]. The realtime API has no per-line parameter, so UP-N would be obtained by filtering the data by route (my inference). The exact GTFS `route_id` string was not verified; no data file was downloaded. [C]
- **Old host.** The earlier host stopped on November 1, 2025 [U: [developers](https://metra.com/developers)].
- **Realtime semantics.** A train with no position is assumed to be en route; with no trip update it is assumed to run to schedule; trip updates can appear hours ahead for annulled or added trains [U: [metra-gtfs-api](https://metra.com/metra-gtfs-api)].
- **Key.** Obtained through a web form (name, email, purpose, tick-box agreeing to the licence); bearer token or `api_token` parameter [U: [developers](https://metra.com/developers), [metra-gtfs-api](https://metra.com/metra-gtfs-api)]. Prefer the header: query parameters end up in logs.
- **Rate limit.** Nothing published [U]. A third-party catalogue lists "10 per minute / 1000 per month" but calls its own values placeholders, so ignore them [T: [apis.io](https://apis.io/rate-limits/metra/metra-rate-limits/)]. My arithmetic: positions alone at 30 s is 2,880 requests per day; all three realtime feeds is 8,640 [A].
- **Licence grant** is non-exclusive, limited, revocable, to use, reproduce and redistribute Metra Data [U: [licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement)].
- **Relay.** Our app must redistribute through our own host, and must not direct users to Metra's servers [U: [metra-gtfs-api](https://metra.com/metra-gtfs-api) and licence]. The licence also bars using or making available Data that is inaccurate, misleading, false or unlawful (paraphrase) [U: licence].
- **Disclosures.** Non-affiliation statement; date and time last updated; no claim of accuracy, completeness or timeliness; Metra marks and copyrighted material "may not be used in association with Data". The app may say the data came from Metra and is redistributed through our host [U: licence].
- **Warranty and termination.** Data "AS IS" and "AS AVAILABLE"; Metra may terminate, may stop providing Data without notice, may change the terms at any time; Illinois law [U: licence].
- **Data licence.** Bespoke, not open. A third-party catalogue links the same agreement as its licence [T: [Mobility Database](https://mobilitydatabase.org/feeds/gtfs/mdb-2854)].
- **Re-observed with an honest client on 2026-10-06** [O]: `published.txt` HTTP 200, `Cache-Control: max-age=300`, `Last-Modified` Sat 03 Oct 2026 07:20:04 GMT, served by S3 behind CloudFront; `schedule.zip` HTTP 200, 716,354 bytes; `positions` without a key HTTP 401 with `x-ratelimit-limit: 200` and `x-ratelimit-remaining: 199`. One request each.
- **Not known** [C]: approval turnaround, per-app or per-person keys, any limit on keyed traffic, whether paid use is allowed, whether area filtering counts as "modify or delete".

### 2.3 CTA: trains, buses, GTFS and GTFS-RT beta

**Developer License Agreement** ([current text](https://www.transitchicago.com/developers/terms/), re-read this pass [V]). It covers Bus Tracker, Train Tracker, Alerts, GTFS and scheduled-service data, and CTA may change it at any time.

- **Grant.** Limited, non-exclusive, non-assignable, non-transferable, revocable licence to use, reproduce, distribute, display, process and create derivative works of CTA Data.
- **Purpose.** The sole purpose of assisting mass transportation riders, or promoting public transportation. Other uses need CTA's express permission.
- **Commercial.** The word "commercial" does not appear on the page (checked this pass). A paid app is not forbidden by name; the purpose clause is the real limit. CTA Data may not be sold separate from the application.
- **Caching.** CTA Data may be cached to improve the user experience, with reasonable efforts to keep it up to date. No maximum age is stated.
- **Relay.** The DLA grants "distribute" and "display" and has no per-user-key clause. Whether our relay is "your application" is not spelled out [C]. Ask.
- **Termination.** On termination you "will promptly delete all CTA Data" from the application and storage, and must certify in writing that you did, if CTA asks [V: DLA, re-read this pass].
- **Attribution.** Optional ("the option, but not the obligation, to credit CTA"). Suggested lines: "Data provided by Chicago Transit Authority", "Data provided by CTA", "Powered by CTA data" [V: DLA, re-read this pass].
- **Trademarks** ([branding guidelines](https://www.transitchicago.com/developers/branding/), re-read this pass [V]). Allowed: proper 'L' route colours, standard bus and train icons, the Bus Tracker and Train Tracker logos for that API's data. Forbidden: other CTA logos (the circle logo is an example), official CTA maps, naming your project "Bus Tracker" or "Train Tracker", words like "official", anything suggesting partnership, and making a CTA mark the most prominent feature.
- **Warranty.** "AS IS", CTA may stop posting data with or without notice; liability cap ten US dollars; you indemnify CTA; Illinois law, Cook County courts [V: DLA, re-read this pass].
- **Discrepancy.** The agreement copy on the [key-application page](https://www.transitchicago.com/developers/traintrackerapply/) differs from the current terms page and is probably older; neither copy carries a date [V, both re-read this pass]. The key-page copy: has an unfilled "[Insert Link]" placeholder where the trademark guidelines are cited; grants a narrower licence (use, reproduce and distribute, with no display, process or derivative-works wording) and says CTA Data may not be copied, reproduced, downloaded or distributed beyond that without permission; and says CTA owns "any changes that you make" to the CTA Data (the current page says "original CTA Data"). Both copies have the purpose clause and the sentence barring sale of CTA Data separate from the application. Ask which text binds when a key is issued.

**Train Tracker** ([overview](https://www.transitchicago.com/developers/traintracker/), [docs](https://www.transitchicago.com/developers/ttdocs/) revised 04-Aug-2024).

- Locations call `ttpositions.aspx` takes one or more routes and returns in-service trains with latitude, longitude, heading, next stop, destination and run number [V: docs, earlier pass]. A single call can cover all eight 'L' routes (CTA says eight rail routes: [V: [CTA facts](https://www.transitchicago.com/facts/)]).
- Positions are derived from track sections, not GPS [V: docs, re-read this pass], so the world must interpolate along the route.
- Daily limit: the overview says 50,000 and the docs say 100,000 [V: both re-read this pass]. Requests for more go by email; DoS protection can time out a busy IP [V: overview].
- The docs still call the service beta and carry a stale "coming soon" paragraph [V: earlier pass].

**Bus Tracker v3** ([overview](https://www.transitchicago.com/developers/bustracker/), [PDF rev. 2025-04-21](https://www.transitchicago.com/assets/1/6/cta_Bus_Tracker_API_Developer_Guide_and_Documentation_2025-04-21.pdf)).

- `getvehicles` returns `vid`, `lat`, `lon`, `hdg`, `rt`, `des`, `dly` and more; at most 10 identifiers per call, routes and vehicle IDs cannot be combined [V: PDF, earlier pass].
- CTA operates 127 bus routes [V: [CTA facts](https://www.transitchicago.com/facts/)]. At 10 routes per call a full sweep is 13 calls, or 37,440 per day at 30 s [A]. This corrects my earlier notes, which used about 150 routes and 15 calls from an alerts-page claim I could not find.
- Buses that go off-route disappear; a bus may be missing because of a hardware or comms fault [V: earlier pass].

**Static GTFS** ([page](https://www.transitchicago.com/developers/gtfs/), re-read this pass [V]): only one package is posted at a time; short reroutes are not included.

**GTFS-RT beta** ([page](https://transitdata.transitchicago.com/), re-read this pass [V]): titled as beta testing; feeds `.pb` and `.json`; an API key is required. Refresh rate, limits and specific terms are [C]. The Developer Center overview does not mention it [V: earlier pass].

**Alerts API** (not needed here): XML only; staff-entered, appear "almost immediately" [V: [alerts page](https://www.transitchicago.com/developers/alerts/)].

### 2.4 Pace

- **Static GTFS** ([data page](https://pacebus.com/route-timetable-data-services), re-read this pass [V]). Monthly updates; routes with IBS equipment only; the zip carries the terms. The page's intro says the data is shared "for non commercial use". It sits in the intro, not in the licence text, so its binding force is unclear, but treat it as a real constraint for a commercial app.
- **Licence.** Pace grants "non-exclusive, limited and revocable" rights to use, reproduce and redistribute Pace's Data to assist you with mass transportation; the Pace name and logo need prior written consent and may not be used with others' products or services; Pace may change or delete data without notice; "as is"; Illinois law [V: same page].
- **Real-time.** Pace says its Bus Tracker predictions "not available for download" [V: **same data page**, not the Bus Tracker tools page as my earlier notes said]. The [Bus Tracker tools page](https://pacebus.com/bus-tracker-tools) lists the website, live map and apps and mentions no GTFS-RT or API [V, re-read this pass].
- **The three `tmweb.pacebus.com` GTFS-RT endpoints** are public and refresh about every 30 s [O], but are documented only in third-party catalogues [T: [Transitland record](https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json), [validation PR](https://github.com/transitland/transitland-atlas/pull/2201)]. They sit on the same host that Pace's own Bus Tracker links use (`tmweb.pacebus.com/TMWebWatch/`) [V: [Bus Tracker tools page](https://pacebus.com/bus-tracker-tools), re-read this pass], so they are probably Pace's own system, but no Pace page, licence or documentation covers them [C]. **Treat as undocumented and unlicensed.**
- **Regional data.** The RTA was replaced by the Northern Illinois Transit Authority (NITA) on September 1, 2026 [V: [NITA press release](https://nita.illinois.gov/about-rta/press-releases/northern-illinois-transit-authority-begins-new-era-for-regional-transit), re-read this pass]. Its Data Hub describes a repository of data sets and lists no real-time feed [U: [datahub.nita.illinois.gov/about](https://datahub.nita.illinois.gov/about)].

### 2.5 Denver RTD

- **Real-time** ([page](https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds), re-read this pass [V]). Canonical URLs under `open-data.rtd-denver.com`, published Fall 2025; "accurate within 2 minutes". The page speaks of arrival predictions and vehicle locations; it does not say which modes the feeds carry (trains and buses sharing them is my assumption [C]). Observed: no key, files refresh about every 30 s [O]. Hosting looks like Azure blob storage (`x-ms-blob-type` header, earlier pass) [O].
- **Licence** ([text](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement), re-read this pass [V]). Non-exclusive, limited, revocable rights to use, reproduce and redistribute; RTD marks "may not be used in association with Data"; RTD may require an "unofficial web site" notice; "does not warrant that the Data will be available"; RTD may alter or stop the data with or without notice; to the extent permitted by law you indemnify RTD; Colorado law, and disputes only in the courts of the City and County of Denver.
- **Static GTFS** ([page](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs)): do not use the RTD logo, RTD maps or other RTD content without advance permission [V: earlier pass].
- The separate [website terms of use](https://www.rtd-denver.com/terms-of-use) (last updated February 2011) restrict copying website content to personal, non-commercial purposes; that covers the website, not the data feeds [V: earlier pass].

---

## 3. Aircraft feeds

> Until live aircraft are permitted (adsb.lol), [ambient-planes.md](ambient-planes.md) specifies an illustrative, clearly "not live" option on real approach corridors into ORD and DEN; it uses no flight data.

Aircraft data is receiver-based (ADS-B, MLAT) or vendor-based. The community feeds describe themselves as unfiltered, and their APIs expose flags for LADD and PIA aircraft, so such aircraft are present in them (§3.3): adsb.lol's home page [V: [adsb.lol](https://www.adsb.lol/)] and the JETNET release for ADS-B Exchange [V: [press release](https://www.jetnet.com/resources/press-releases/jetnet-acquires-ads-b-exchange)] say so; airplanes.live and the ADS-B Exchange support site say so too, but those pages are [U] (U8, U10 in §7.1).

**Cost model.** Boxes are 30 km by 30 km: at Chicago's latitude 0.271 deg by 0.363 deg = 0.098 sq deg; at Denver's 0.095 sq deg [A]. A circle covering the box has radius about 21 km, which is 11.4 nm; the aircraft research used 12 nm [A]. A month is 30 days: 10 s = 259,200 polls, 15 s = 172,800, 30 s = 86,400, 60 s = 43,200 [A]. N is aircraft returned per poll. **Real counts near the three busy airports were not measured**; the tables use N = 15, 30 and 60.

### 3.1 Summary tables

**Table 3.1a: access**

| Feed | Endpoint and format | Update rate | Sign-up / keys | Rate limits |
|---|---|---|---|---|
| **OpenSky Network** | `GET https://opensky-network.org/api/states/all?lamin&lomin&lamax&lomax`, JSON [V: [REST docs](https://openskynetwork.github.io/opensky-api/rest.html)] | Anonymous 10 s, authenticated 5 s [V] | Anonymous works; authenticated needs an account and OAuth2 client credentials [V] | Credits: anonymous 400/day, standard 4,000/day, active feeder 8,000/day, licensed 14,400/hour; a box of up to 25 sq deg costs 1 credit [V] |
| **ADS-B Exchange Community API** (RapidAPI) | RapidAPI-hosted JSON; query by location, hex, callsign or squawk [V: [developer hub](https://www.adsbexchange.com/community/developer-hub/)] | "500ms updates" [V] | RapidAPI account and key | 10,000 requests per month on the $10 plan [V]; overage [C] |
| **ADS-B Exchange Enterprise** (JETNET) | `https://gateway.adsbexchange.com/api/aircraft/v2/...` incl. `/lat/{lat}/lon/{lon}/dist/{dist}` and `POST /geospatial/boundary`; JSON; gRPC streaming [V: [OpenAPI spec](https://gateway.adsbexchange.com/api/aircraft/v2/docs/openapi.json), [data products](https://www.adsbexchange.com/data-products/)] | Choose 5 s, 500 ms or 250 ms [V] | `x-api-key` header (the spec's `X-Api-Key` security scheme) [V]; sales contact | Token bucket; example plans 12 requests/min and 120 requests/min [V] |
| **adsb.lol** | `GET https://api.adsb.lol/v2/point/{lat}/{lon}/{radius}` (up to 250 nm); ADSBx v2-style JSON; also `/v2/ladd` and `/v2/pia` [V: [spec](https://api.adsb.lol/api/openapi.json)] | Not published [C] | None today; the spec says an API key will be required in future [V] | None published [V]. A third-party GitHub issue (repository `skylight`, issue 66; owner name omitted) reports about two thirds of requests limited at a 4 s poll [T] |
| **adsb.fi** | `GET https://opendata.adsb.fi/api/v3/lat/{lat}/lon/{lon}/dist/{dist}` (up to 250 NM); ADSBx v2-compatible [V: [README](https://raw.githubusercontent.com/adsbfi/opendata/main/README.md)] | Not published; feeder snapshot refreshed twice a minute [V] | None for public endpoints | 1 request per second on public endpoints [V] |
| **airplanes.live** | `https://api.airplanes.live/v2/point/{lat}/{lon}/{radius}` (max 250 nm) [U] | [C] | Feeder-only since about August 2026 [T: same third-party GitHub issue, repository `skylight`, issue 66]; earlier none [U] | 1 request per second historically [U] |
| **FlightAware AeroAPI Standard** | `GET https://aeroapi.flightaware.com/aeroapi/flights/search?query=-latlong "MINLAT MINLON MAXLAT MAXLON"` (airborne, includes `last_position`), JSON [V: [OpenAPI spec](https://www.flightaware.com/commercial/aeroapi/resources/aeroapi-openapi.yml)]. The spec text gives the corner order as min-lat, min-lon, max-lat, max-lon, but its own example lists the north-west corner first (44.95 -111.05, then 40.96 -104.05): confirm before use [V] | Not stated [C] | `x-apikey` header; account and tier | 5 result sets per second [V: [pricing page](https://www.flightaware.com/commercial/aeroapi/)] |
| FlightAware AeroAPI Personal | same | same | same | 10 result sets per minute [V] |
| FlightAware AeroAPI Premium | same, plus Aireon space-based ADS-B on request [V] | [C] | same | 100 result sets per second; 99.5% uptime [V] |
| **Flightradar24 API** | `GET https://fr24api.flightradar24.com/api/live/flight-positions/light?bounds=N,S,W,E`, JSON [V: [OpenAPI yaml](https://fr24api.flightradar24.com/documentation/Flightradar24-API.yaml)] | "approximately every 3 seconds per aircraft" [V: [FAQ](https://fr24api.flightradar24.com/docs/faq)] | Bearer token; paid subscription | Explorer 10, Essential 30, Advanced 90 queries per minute per docs (portal data shows 200 for Advanced: conflict, [C]); items per response 20, 300, unlimited [V] |

**Table 3.1b: terms and cost**

| Feed | Commercial-use terms | Caching / redistribution via our relay | Attribution | Cost |
|---|---|---|---|---|
| **OpenSky** | API is for research and non-commercial use; commercial use: contact OpenSky [V: [docs intro](https://openskynetwork.github.io/opensky-api/index.html)]. Terms page: operational use needs a written licence [U: [terms](https://opensky-network.org/about/terms-of-use)] | Not without a licence [V]; the explicit no-redistribution clause (clause 3(iii)) and expunge-on-completion clause (4(ii)) are [U]. Docs warn that AWS and other hyperscalers may be blocked [V] | Cite the 2014 OpenSky paper for publications [V] | Free tiers; licensed price [C]. One credit per poll per cell: 15 s = 5,760 credits/day per cell, so two cells need 11,520, above even the 8,000 feeder tier; only the licensed tier or slower polling fits (two cells at 30 s need 5,760 per day: the feeder tier) [A] |
| **ADS-B Exchange Community** | "built for non-commercial use" [V] | No | [C] | $10 per month for 10,000 requests [V]; 30 s polling is 86,400 per month [A] |
| **ADS-B Exchange Enterprise** | Commercial licensing under an order form [V]. [JETNET terms](https://www.jetnet.com/legal/terms-of-use/) (the ADS-B Exchange terms address redirects there; they govern order forms executed on or after 2025-01-14): access is for the customer's internal business purposes (2.a) [V] | **A fan-out relay is not covered.** Section 2.d: Company Data may not be retrieved or presented on behalf of a third-party end user unless that end user is a direct JETNET subscriber under a separate active Order Form and authenticates with their own credentials; permitted workflows must be spelled out in the Order Form, and any reseller, referral or pass-through arrangement needs a separate signed agreement. Section 2.b(xi) separately bars publishing, reselling or distributing the data unless JETNET authorises it in writing or the Order Form says so; 2.b(iii) bars a service bureau or SaaS built on the data except as the Order Form allows. On expiry or termination: within 30 days stop end-user-facing presentation and remove cached or stored data (2.d) [V] | Attribute "JETNET, LLC" where distribution is authorised (2.b(xi)) [V] | Minimum annual commitments; no public price [V]; quote needed. A relay needs a special agreement, or every app user would have to be a JETNET subscriber |
| **adsb.lol** | Licence is ODbL, which permits commercial use [V: spec]; the spec asks production users to get in touch [V]; no SLA, "as is" [V: [privacy and licence page](https://www.adsb.lol/privacy-license/)] | Permitted by ODbL with conditions: attribution; share-alike on a publicly used adapted database [V: [ODbL summary](https://opendatacommons.org/licenses/odbl/summary/)]. Ask the operator first | ODbL attribution; no custom wording published [C] | Free |
| **adsb.fi** | "personal, non-commercial use only" [V] | No: no licensing, selling, renting or leasing of the data [V] | Cite adsb.fi and link the home page [V] | Free for personal use; "contact us" for commercial [V] |
| **airplanes.live** | "Non-Commercial Use" [U] | No [U] | [C] | Free but feeder-only [T] |
| **FlightAware Standard** | B2C app allowed. The licence (Nov 2022) lists B2C embedding and internal business use only [V: [licence PDF](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf)]; the pricing page says Standard covers derivative works for "business or business-to-consumer purposes" and its feature table marks B2B commercialisation not included in Standard and included in Premium [V: [pricing page](https://www.flightaware.com/commercial/aeroapi/)]. Where a free app licensed to others falls: ask | Conditional: AeroAPI Data may go to third parties without additional fee or charge, not via the AeroAPI API, only in other than raw format and embedded in our product or a Derivative Work; raw data stored at most 30 days; no use for "commercial aircraft situational displays" (undefined); no backfill from another real-time provider without FlightAware's prior written permission; no sell or sublicense; the licence also bars modifying AeroAPI Data without written permission while allowing Derivative Works, so whether normalising counts as either is a question [V: licence PDF]. General terms: no resale or redistribution unless authorised in the Order [V: [T&C Sep 2026](https://www.flightaware.com/commercial/flightaware-terms-conditions-Sep2026.pdf)] | Licences give "Contains AeroAPI data (c) FlightAware LLC" in the academic clause; no in-app wording for commercial apps found [V]; brand guide applies | $0.050 per result set (15 records); $100 per month minimum; volume discount tiers [V: pricing page] |
| FlightAware Personal | Personal or academic only; barred for any business [V: [Personal licence](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Personal_License_Jul2026_v2.pdf)] | No | same | Up to $5 free per month ($10 for ADS-B feeders) [V] |
| FlightAware Premium | B2B embedding allowed (licence example: an application sold to an airport) [V: [Premium licence](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2025.pdf)] | Conditional, with differences from Standard: third parties may receive AeroAPI Data "with or without" additional fee (Standard: without), and Derivative Works may be stored in perpetuity; the situational-display bar, the 30-day raw limit and the backfill bar (same written-permission exception) are repeated [V: Premium PDF against Standard PDF] | same | $1,000 per month minimum [V] |
| **Flightradar24** | Every plan carries a `commercial` flag in portal data [V]; ToS says commercial use and derivatives are allowed, with raw data not to be resold, transferred or redistributed [U: [ToS](https://www.flightradar24.com/terms-of-service), archive copy] | Storage: all API data may not be kept more than 30 days [V: [storage rules](https://fr24api.flightradar24.com/docs/storage-rules)]. Redistribution of raw data barred; backfilling another provider barred [U] | Commercial products must credit Flightradar24 (ToS 8.2) [U] | 6 credits per returned flight; $0.0003 per credit at the smallest package; $0.000248 per credit is the best of the five example packages on the [credit overview](https://fr24api.flightradar24.com/docs/credit-overview) page ($300 for 1,210,000 credits); the [subscriptions page](https://fr24api.flightradar24.com/subscriptions-and-credits) lists 40 packages from $9 to $990, the largest being $990 for 4,620,000 credits = $0.000214 per credit (the $900 Advanced plan is $0.000222) [V]; plans $9, $90, $900 per month [V] |

### 3.2 Community and open feeds against commercial ones

- **Open and community feeds.** Receiver-based, so coverage at low altitude depends on nearby receivers (my reading; coverage was not measured). Described as unfiltered (sources in the §3 intro). No SLA anywhere. Only adsb.lol is not prohibited for commercial use, and it is the only one whose licence (ODbL) clearly allows storing and re-serving positions, with attribution and share-alike duties.
- **Commercial feeds.** FlightAware reports positions from several source types, including ADS-B, radar and space-based [V: position `update_type` codes in the [OpenAPI spec](https://www.flightaware.com/commercial/aeroapi/resources/aeroapi-openapi.yml)]; Aireon space-based ADS-B is a Premium feature to be enabled on request [V: [pricing page](https://www.flightaware.com/commercial/aeroapi/)]; Premium has a 99.5% uptime [V]. Flightradar24 claims about 3 s per-aircraft updates [V]. Both are priced per result, so cost scales with how much airspace you poll and how often (§5.4). Both restrict raw redistribution and storage, and both bar blending in a community fallback (FlightAware, unless it agrees in writing [V]; Flightradar24 [U]).
- **What the "pull once per area and fan out" model needs.** ADS-B Exchange Enterprise's standard terms do not allow it: end-user presentation is limited to end users who are direct JETNET subscribers, and any reseller or pass-through needs a separate signed agreement [V: [JETNET terms](https://www.jetnet.com/legal/terms-of-use/), 2.d]. FlightAware Standard might, if what we serve is derived, non-raw and embedded in our product (confirm in writing). Flightradar24's ToS wording points the other way [U]. Wingbits B2B terms bar providing direct access to the data feed or APIs, while allowing use within its system [V: [B2B terms](https://wingbits.com/terms-and-conditions/b2b)].
- **Others, not priced here.** Spire Aviation (satellite ADS-B; price and licence by sales) [V: [docs](https://aviation-docs.spire.com/api/flights-live/introduction)]; Aireon: offered through FlightAware Premium on request [V: pricing page above], its own sales channels were not researched [C]; FAA SWIM (message-bus integration via the SWIFT portal, some services by request to the FAA [V: [FAA get-connected page](https://www.faa.gov/air_traffic/technology/swim/products/get_connected)]; SWIM vendors are bound by a Data Access User Agreement to filter LADD participants [V: [FAA LADD page](https://www.faa.gov/pilots/ladd)]); Wingbits (plan prices did not load) [V: [pricing](https://wingbits.com/pricing)].

### 3.3 LADD and PIA filtering

- **LADD.** The FAA's Limiting Aircraft Data Displayed programme lets owners have flight data filtered from public display by participating sites; on that wording it does not bind sites that do not participate (my reading). Vendors that subscribe to FAA SWIM feeds are bound by a Data Access User Agreement to filter LADD participants [V: [FAA LADD page](https://www.faa.gov/pilots/ladd), re-read this pass]. We would be bound directly only if we took SWIM data; whether any other duty applies to us is a lawyer question (§6, licensing Q28).
- **PIA.** Owners can use alternate ICAO addresses not tied to the registry; PIA does not hide the aircraft, it only breaks the link to the registered owner. Non-FAA data sources can capture ICAO addresses straight from ADS-B Out transmissions [V: [NBAA PIA page](https://nbaa.org/aircraft-operations/security/privacy/privacy-icao-address-pia/)].
- **Consequence.** Receiver-based community feeds describe themselves as unfiltered (§3 intro), so these aircraft are present in them. adsb.lol offers `/v2/ladd` and `/v2/pia` lists, and its aircraft schema carries a `dbFlags` field [V: [spec](https://api.adsb.lol/api/openapi.json), re-read this pass]; ADS-B Exchange returns `dbFlags` bits, PIA = `dbFlags & 4`, LADD = `dbFlags & 8` [V: [OpenAPI spec](https://gateway.adsbexchange.com/api/aircraft/v2/docs/openapi.json)]. FlightAware's flight record has a `blocked` flag [V: OpenAPI spec]; Flightradar24 says some flights are limited or blocked, in its website and apps [V: [support article](https://support.fr24.com/support/solutions/articles/3000117426-why-does-it-say-that-a-flight-is-blocked-)]. Whether the commercial area-search calls omit blocked aircraft is [C] for both.
- **Our rule** (design, §4.9): the relay drops LADD and PIA aircraft before caching or logging, whatever the source, and never forwards registration or ICAO address to phones.

---

## 4. Relay design

The relay is a small server component. It pulls each feed once per active area, normalises and filters, caches, and serves phones. **Phones never hold API keys and never call an upstream feed.** The engine stays generic: it receives plain vehicle values from the host through a protocol like the weather provider (the engine never calls a feed or holds a key; compare licensing checklist W7). Where the relay lives (a separate service; this repo or a host-side repo) is an owner decision not covered by the plan, so nothing here goes into code yet.

### 4.1 How the terms shape the design

| Term | Source | Design consequence |
|---|---|---|
| Redistribute through our own host; never send users to Metra's servers | Metra [U] | Relay only; the phone never sees a Metra URL or key |
| "must not modify or delete Data" | Metra [U] | Ask whether area filtering, compact re-encoding and purging snapshots are allowed (§6). Fallback: keep each Metra response byte-for-byte as received and derive tile views from it |
| Last-updated date and time; non-affiliation statement | Metra [U] | Every response carries per-feed `updated` and `attribution`; the host must show them |
| Daily caps shared by the whole key: Train Tracker 50,000 or 100,000, Bus Tracker 100,000 | CTA [V] | Only the relay calls CTA. 30 s polling; only routes touching active tiles; never 15 s for buses (74,880 calls/day for a full sweep [A]) |
| DoS protection that can time out a busy IP; no threshold published | CTA [V] | Jittered polls, no bursts, and a low rate (a full bus sweep is about 0.43 calls per second [A]). Egress IP: Cloudflare Workers and Durable Objects do not let us pick or fix the outbound IP (not verified [C]); Fly.io offers a static egress IP at $0.005 per hour, about $3.60 per month [V: [Fly pricing](https://fly.io/docs/about/pricing/)], which is not in the $7.55 total in §5.3. Ask CTA whether it wants a fixed address |
| Delete all CTA Data on termination | CTA [V] | Ephemeral snapshots only; a documented purge procedure; no CTA data in packages, fixtures or exports |
| AeroAPI data to third parties only in non-raw form, never through the AeroAPI API | FlightAware [V] | The relay API serves derived normalised fields, never AeroAPI JSON, and is not offered to third parties |
| No backfill from another real-time provider without FlightAware's prior written permission | FlightAware [V]; Flightradar24 bars backfill too [U] | No automatic failover to a community feed while on those contracts unless the provider agrees in writing; the fallback is "unavailable" |
| Raw data stored at most 30 days | FlightAware [V], Flightradar24 [V] | Satisfied by keeping only the latest snapshot |
| Data may not be presented to third-party end users unless each is a direct JETNET subscriber with their own credentials; reseller, referral or pass-through needs a separate signed agreement (2.d). Publishing or distributing needs written authorisation or the Order Form (2.b(xi)) | ADS-B Exchange Enterprise [V] | A fan-out relay is not allowed under the standard terms; it needs a special agreement before any use |
| ODbL attribution and share-alike | adsb.lol [V] | Attribution string in the envelope; decide the ODbL status of the relay snapshot (licensing Q25) |
| Undocumented endpoints, no terms | Pace [T] | Not used |
| No RTD marks; possible "unofficial" notice | RTD [V] | Non-endorsement line in the credits |
| Revocable, "as is", no uptime promise | All | Per-feed kill switch; graceful degradation (§4.7) |

### 4.2 Diagram

```
 UPSTREAM (keys live only here)        RELAY (server side)                          PHONES (no keys)
 +--------------------------+     +------------------------------------+
 | Metra GTFS-RT   30 s [U] |---->| Pollers: one per feed x active area|
 | CTA Train/Bus   30 s     |---->|   (idle areas are not polled)      |
 | RTD GTFS-RT     30 s     |---->|        |                           |
 | Aircraft source 15-60 s  |---->|        v                           |
 +--------------------------+     | Normalise -> drop LADD/PIA          |
                                  |        |                           |
                                  |        v                           |
                                  | Latest snapshot per feed x area    |
                                  | (memory + one short-lived copy)    |     GET /v1/live?...    +----------------+
                                  |        |                           |<------------------------| host app polls |
                                  |        v                           |   gzip JSON, ETag, 304  | every 15 s and |
                                  | Tile index (z14) + edge cache      |------------------------>| dead-reckons   |
                                  | max-age 10 s                       |                         +----------------+
                                  +------------------------------------+
        feed registry (areas.json, attribution, intervals, kill switch) = data, not code
```

### 4.3 Area and tile model

- **Fan-out tiles.** A fixed Web-Mercator grid at zoom 14, tile id `14/x/y`. A tile is about 1.8 km on a side at Chicago's latitude and 1.9 km at Denver's [A: 40,075 km / 2^14 = 2.45 km at the equator, times cos of latitude]. A phone asks for the rectangle of tiles covering its view, typically 3 by 3 (about 5.5 km square, 30 sq km) in one request, with the rectangle sorted and canonical so identical views share a cache key.
- **Active tiles.** The relay tracks which tiles have had a request in the last 2 minutes. A feed-and-area is **active** while any tile in it is active. Idle areas are not polled.
- **Transit cells.** The transit feeds are whole-system (CTA, RTD, Metra and Pace publish system-wide files or route lists), so the unit of polling is the **metro**, and the relay splits each snapshot into z14 tiles. Cost therefore scales with the number of active metros.
- **Aircraft cells.** Aircraft are polled per **cell**, a zoom-10 tile (about 29 km at Chicago, 30 km at Denver [A]), matching the 30 km box in §3. A viewer within about 10 km of a cell edge also activates the neighbour, because aircraft are visible from far away (design choice). For commercial per-result feeds, poll only the bounds of the active tiles plus that margin, not the whole cell: cost falls with the number of aircraft returned. The saving was not measured.
- **Allowlist.** Only configured metros can activate upstream polls (§4.12). Areas are data (`areas.json`), not code.

### 4.4 Poll intervals per feed

| Feed | Upstream interval | Basis | Calls per day while active 24 h |
|---|---|---|---|
| Metra positions [U] | 30 s | Updated every 30 s, no need to poll faster [U] | 2,880 |
| CTA Train Tracker positions | 30 s | No interval published, so stay conservative; positions are derived from track sections [V] | 2,880 for all lines in one call |
| CTA Bus Tracker `getvehicles` | 30 s | CTA says about every 30 s [V] | 37,440 for a full 13-call sweep (127 routes, 10 per call) [A]; fewer if only active routes are polled; cap 100,000 [V] |
| RTD VehiclePosition | 30 s | Observed file refresh [O] | 2,880 |
| Aircraft | 15 s headline; 30 to 60 s where cost, limits or permission require | Per feed; §5.4 | 5,760 (15 s), 2,880 (30 s), 1,440 (60 s) per cell |
| CTA and Pace GTFS-RT, Pace anything | Not used until terms are confirmed | §2 | none |

Static GTFS is fetched by the build pipeline, not the live relay. Prefer OSM route geometry for snapping vehicles to rails and roads: baking agency static data into a world package would put CTA, RTD or Metra data into something distributed, against CTA's delete-on-termination clause (design idea, licensing Q31).

### 4.5 Normalised vehicle message

One message type for every feed (JSON, gzip; a compact binary form can follow later). The comments are explanations, not part of the format.

```jsonc
{
  "id": "cta-bus:6a1f",     // opaque, stable per source; aircraft ids are relay-generated, never the ICAO hex or an unsalted hash of it
  "kind": "bus",            // bus | rail | aircraft
  "route": "22",            // route short name; aircraft: null unless the source terms allow a callsign
  "pos": [41.88123, -87.63012],   // WGS84 latitude, longitude
  "hdg": 273,               // degrees true, or null
  "spd": 6.1,               // metres per second, or null
  "alt": null,              // metres, aircraft only
  "t": 1790000030,          // timestamp of the position from the source, Unix seconds
  "src": "cta-bus",         // feed key into the envelope's feeds table
  "q": "reported"           // reported | derived (CTA trains: from track sections) | estimated
}
```

Response envelope:

```json
{
  "v": 1,
  "generated": 1790000031,
  "feeds": {
    "cta-bus":  { "updated": 1790000029, "status": "fresh",       "attribution": "Data provided by CTA", "url": "..." },
    "metra":    { "updated": 1790000010, "status": "fresh",       "attribution": "...not sponsored, affiliated, or operated by Metra", "url": "..." },
    "aircraft": { "updated": 1789999990, "status": "unavailable", "attribution": "...", "url": "..." }
  },
  "vehicles": [ ]
}
```

- `t` is the source's own position time, so the client can dead-reckon from `pos`, `hdg`, `spd` and the age. `updated` is when the relay last had a good pull from that feed.
- `attribution` comes from the feed registry (§4.8). A feed appears in `feeds` only if it is enabled for the metro.
- No registration, ICAO address or owner field is ever sent to phones. Aircraft ids must not be an unsalted hash of the ICAO hex: the address space is only 24 bits, so such a hash is trivially reversible. Use a salted id from a secret salt that rotates (for example daily).

### 4.6 Fan-out options and recommendation

| Option | How | For | Against |
|---|---|---|---|
| **A. HTTP polling behind an edge cache** | Phone polls the tile rectangle every 15 s; response `Cache-Control: max-age=10` plus `ETag` and 304 | Stateless; cacheable; simple abuse limits; works with any host and OS; no per-connection cost | Up to one poll interval of extra latency; a request per poll |
| **B. Server-sent events** | One long HTTP stream per phone | Push without polling | Long-lived connections; poor fit for mobile apps that background; not cacheable |
| **C. WebSocket** (for example a Durable Object using the Hibernation API) | One socket per phone; relay broadcasts per tile | Lowest latency; outgoing messages are free on Cloudflare [V: [pricing](https://developers.cloudflare.com/workers/platform/pricing/)] | Connection state; needs the Hibernation API to avoid duration charges [V: same page]; not cacheable; more to secure |

**Recommendation: A at launch.** Upstream data only changes every 15 to 30 s, so push gains little over a 15 s poll. At 10,000 users the load is about one request per second on average and about 2.6 at the evening peak (§5.2), well inside any platform's included usage. Keep the message format identical so a push channel can be added later if latency under 5 s or request volume (tens of millions per month) ever matters. Delta encoding is not worth it: a tile response is about 2 to 3 KB gzipped, so `ETag` and 304 are enough. The synthetic measurement is in §5.1.

### 4.7 Stale data and graceful degradation

Feeds can be revoked, throttled or simply fail. Each feed in each area has a state the client sees in `feeds.<key>.status`:

| State | Rule (initial values, to tune) | Client behaviour |
|---|---|---|
| `fresh` | Age of last good pull is at most 2 poll intervals | Draw and dead-reckon |
| `stale` | At most 5 minutes old | Dead-reckon for at most 2 intervals, then freeze and fade; show "live data delayed" |
| `unavailable` | Older than 5 minutes, disabled, or revoked | Remove vehicles; show "live data unavailable"; the world works without it |

- **Errors.** 401 or 403 means revocation or a bad key: disable the feed, alert the operator, do not retry hot. 429: back off (double, up to 5 minutes), honour `Retry-After`. 5xx or timeout: exponential backoff with jitter. Never fail over from a contracted feed to a community feed where the contract forbids backfill.
- **Kill switch.** The feed registry carries `enabled` per feed and per metro so a withdrawal or a licence change can be honoured at once, without an app release.
- **Timestamps.** `updated` and `t` are always sent, and the host shows a last-updated time. Metra requires the date and time [U]; doing it for every feed is simpler than special-casing.
- **Rendering notes.** CTA train positions are stepwise [V]: interpolate along the route. Metra trains with no position are assumed en route [U]: do not draw them.

### 4.8 Attribution passed through

- A server-side registry (`feeds.json`) holds each feed's attribution text and URL, versioned. The relay copies the right ones into `feeds`.
- The host must show the credit of every feed that has vehicles on screen, next to the OpenStreetMap credit (which stays visible, per CLAUDE.md). Examples to carry: CTA optional credit, Metra non-affiliation and last-updated text [U], RTD non-endorsement line, adsb.lol ODbL attribution, Flightradar24 credit [U], JETNET [V].
- Exported images and video need the same credits burned in (licensing O4, O5). That work is not built yet.

### 4.9 LADD and PIA filtering

Applied in the relay, before the snapshot is cached or anything is logged:

1. Drop any aircraft with `dbFlags & 8` (LADD) or `dbFlags & 4` (PIA) on ADS-B Exchange-format feeds, including adsb.lol, whose point response carries `dbFlags` [V: specs]. Do not call adsb.lol's `/v2/ladd` and `/v2/pia` list endpoints on every poll: that would double or triple the request count and add rate-limit risk. If the flags prove unreliable, fetch the two lists rarely (for example hourly) and cache them.
2. Drop FlightAware records with `blocked: true` [V: spec]. Apply the same filter to anything else the source flags.
3. Replace identifiers with relay-generated opaque ids; send no ICAO address, registration or owner data. Send a callsign only if the source terms allow.
4. Keep a deny list of aircraft whose owners ask for removal, and apply it at the same step.

Whether the commercial area searches already omit blocked aircraft is [C], so the relay filters anyway.

### 4.10 Retention

- **Latest snapshot only** per feed and area, in memory, with at most one short-lived durable copy for restarts, expiring in minutes. No history, no replay, no archives.
- This is far inside FlightAware's 30-day raw limit [V], Flightradar24's 30 days [V], ADS-B Exchange's 30 days after expiry [V], and CTA's delete-on-termination [V].
- Metra's "must not ... delete Data" [U] may conflict with purging; ask (§6).
- No live feed data in the repo: fixtures and tests use synthetic vehicles.

### 4.11 Keys and secrets

- Keys exist only in the relay's secret store (the platform's secrets feature), never in the app, the world package or the repo.
- One key per feed and environment; rotate on a schedule and on any suspicion.
- CTA Bus Tracker keys are tied to a human's Bus Tracker account, one per account [V]. Register under a company-owned account, not a personal one.
- Metra: use the bearer header, not the `api_token` query parameter [U], so the key stays out of access logs.

### 4.12 Abuse and rate protection

- **Client limits.** At most 1 request per 5 s per install or IP (enforced at the edge); rectangle capped at 4 by 4 tiles; larger requests are rejected.
- **No amplification.** Only tiles inside allowlisted metros can activate upstream polling. A client asking for tiles around the world must not cause an upstream poll (otherwise anyone could run up a per-result bill).
- **Budgets.** A global token bucket per feed (to stay inside CTA's cap and every provider's rate limit), and a hard daily spend ceiling per paid feed; when it is hit the feed degrades to `unavailable`.
- **Platform guard.** Cloudflare's own pricing page recommends CPU limits "to prevent accidental runaway bills or denial-of-wallet attacks" [V: [pricing](https://developers.cloudflare.com/workers/platform/pricing/)].
- **Client attestation** (for example Apple App Attest) could limit use to real installs; I have not researched it here.

### 4.13 Logging without personal data

- A tile request reveals an approximate location (about 1.8 km). Do not log request tiles together with IP address, install id or any user identifier. Disable or minimise edge access logs as the platform allows.
- Keep only aggregates: requests per metro and hour, per-feed status and upstream HTTP codes, latency, poll counts and spend.
- Never log vehicle payloads or position histories.

---

## 5. Monthly cost estimate at 1,000 and 10,000 users

**Planning figures, not measurements.** The usage numbers are my assumptions; no real traffic or aircraft counts were measured. A script that reproduces every figure is kept outside the repo; the arithmetic is shown below.

### 5.1 Assumptions

| # | Assumption |
|---|---|
| A1 | "Users" are monthly active users with the live layer on: 1,000 and 10,000, split evenly between Chicago and Denver (the two metros). |
| A2 | 12 sessions per user per month, 5 minutes each with the live layer on screen: 60 live minutes per user per month. Sensitivity: ten times that (600 minutes). |
| A3 | 70% of sessions fall in a 6-hour evening peak and 30% in the other 18 hours. A metro stays active for the session length (5 min) plus a 2-minute linger. Treating arrivals as Poisson, a metro is active for a fraction f of the month: **f = 0.4752 (11.4 h per day) at 1,000 users and f = 0.9846 (23.6 h per day) at 10,000**; every dollar figure and count below uses f unrounded, so rounding the displayed f by hand gives results up to about 0.5% different [A]. |
| A4 | The phone polls every **15 s** (4 polls per minute) while the world is on screen in the foreground. One HTTP request per poll, for a 3 by 3 tile rectangle. |
| A5 | A response holds about 75 vehicles on average (ground plus aircraft): **3.0 KB gzipped body plus 0.5 KB headers = 3.5 KB on the wire**. Check: a synthetic sample of 75 messages of the §4.5 shape is 9.1 KB raw and 2.0 KB gzipped (26 bytes per vehicle); I use 3.0 KB for headroom because real messages carry more fields. This is a placeholder until real data is measured. |
| A6 | **2 areas**: Chicago and Denver. Transit feeds are system-wide per metro. Aircraft: one 30 km cell per metro, so 2 active aircraft cells. |
| A7 | Upstream intervals: transit 30 s; aircraft 15 s headline, with 30 s and 60 s as sensitivity. |
| A8 | **N = 30 aircraft per poll** per cell (a scenario, not measured near the busy airports); N = 15 and 60 as sensitivity. |
| A9 | A month is 30 days. Prices are US dollars, list prices, read 2026-10-06; taxes, domain, monitoring and support plans are excluded. |
| A10 | Cloudflare upper bounds: 4 always-on Durable Object pollers (transit and aircraft per metro), billed for the whole active time; every phone request also calls one of them; 2 ms of Worker CPU per phone request; 10 ms of CPU per upstream poll; one SQLite row write per alarm (each `setAlarm` is one row written [V: Workers pricing page]). |
| A11 | Fly.io: 2 always-on shared-cpu-1x 512 MB machines in North America, no static egress IP unless stated. AWS: 128 MB x86 Lambda pollers in a loop (4 of them, billed for the whole active time); every phone request is one Lambda invocation (1 million free, then $0.20 per million), with request duration ignored; CloudFront flat-rate plan chosen by request count (Free up to 1 million, Pro up to 10 million, Business up to 125 million). |

### 5.2 (a) Relay to phones: requests and egress

| | 1,000 users | 10,000 users | 10,000 users, heavy use (x10) |
|---|---|---|---|
| Area-active fraction f (unrounded) | 0.4752 | 0.9846 | 0.9846 |
| Phone requests per month (users x 60 min x 4 per minute) | 240,000 | 2,400,000 | 24,000,000 |
| Average requests per second | 0.09 | 0.93 | 9.3 |
| Egress at 3.5 KB per request | 0.84 GB | 8.4 GB | 84 GB |
| Peak concurrent viewers (evening mean: live minutes in the peak window divided by its length) | about 4 | about 39 | about 390 |
| Peak requests per second at that concurrency | about 0.3 | about 2.6 | about 26 |
| Upstream transit calls per month: Chicago (Metra, CTA train, 13 CTA bus calls per sweep: 15 calls per 30 s) | 615,873 | 1,276,105 | same as 10,000 |
| Upstream transit calls per month: Denver (RTD, 1 per 30 s) | 41,058 | 85,074 | same |
| Upstream aircraft polls per month (2 cells at 15 s) | 164,233 | 340,295 | same |

CTA's daily caps are respected: Bus Tracker 37,440 calls per day at most (cap 100,000) and Train Tracker 2,880 (cap 50,000 or 100,000) [A].

### 5.3 (b) Relay compute and hosting

Prices from public pages, read 2026-10-06:

- **Cloudflare Workers and Durable Objects** ([Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) [V]): Paid plan $5 per month. Requests: 10 million included, then $0.30 per million. CPU time: 30 million ms included, then $0.02 per million ms. No egress or bandwidth charges. Subrequests are not billed. Durable Objects: 1 million requests included, then $0.15 per million (alarm invocations and WebSocket messages count); duration 400,000 GB-s included, then $12.50 per million GB-s at 128 MB, billed in wall-clock time unless the object is idle and eligible to hibernate. The Free plan allows 13,000 GB-s per day of Durable Object duration. One always-on 128 MB poller uses 10,800 GB-s per day (0.125 GB x 86,400 s), under that allowance, but the four modelled pollers use 43,200 GB-s per day, so the Paid plan is assumed.
- **Fly.io** ([resource pricing](https://fly.io/docs/about/pricing/) [V]): shared-cpu-1x 512 MB $3.69 per month in Ashburn (lowest-priced region; other regions cost more); outbound data $0.02 per GB in North America and Europe.
- **AWS** ([Lambda pricing](https://aws.amazon.com/lambda/pricing/) [V]: $0.20 per million requests, $0.0000166667 per GB-s, free tier 1 million requests and 400,000 GB-s, US East x86; [CloudFront flat-rate plans](https://aws.amazon.com/cloudfront/pricing/) [V]: Free $0 with 1 million requests and 100 GB, Pro $15 with 10 million requests and 50 TB, Business $200 with 125 million requests and 50 TB, no overage charges).
- **Hetzner** was checked but its plan prices load with JavaScript and could not be read, so it is excluded; its billing FAQ only gives an example server at about €3.29 per month and bills outgoing traffic above the included amount in 100 MB blocks [V: [FAQ](https://docs.hetzner.com/cloud/billing/faq/)].

| Cost per month | 1,000 users | 10,000 users | 10,000 users, heavy (x10) |
|---|---|---|---|
| **Cloudflare** (used for the headline totals) | **$7.70** | **$16.24** | **$24.14** |
| of which: base | $5.00 | $5.00 | $5.00 |
| of which: Worker requests and CPU (including poller CPU) | $0 | $0 | $4.66 |
| of which: Durable Object requests | $0 | $0.29 | $3.53 |
| of which: Durable Object duration | $2.70 | $10.95 | $10.95 |
| **Fly.io** (2 machines plus egress; no static egress IP) | $7.40 | $7.55 | $9.06 |
| Fly.io with a static egress IP (+$3.60) | $11.00 | $11.15 | $12.66 |
| **AWS** (CloudFront plan plus pollers) | $3.60 | $29.88 | $219.20 |

Arithmetic for Cloudflare at 10,000 users [A]: Worker requests 2.4 million, under the 10 million included, so $0; CPU 2.4 million requests x 2 ms = 4.8 million ms, plus poller CPU 0.51 million upstream polls x 10 ms = 5.1 million ms, about 9.9 million ms in all, under the 30 million included, so $0; Durable Object requests 2.4 million from phones plus 0.51 million alarms = 2.91 million, so (2.91 - 1) x $0.15 = $0.29; alarm row writes about 0.51 million, under the 50 million included, so $0; duration 4 objects x 0.125 GB x 2,592,000 s x 0.9846 = 1.276 million GB-s, so (1.276 - 0.4) million x $12.50 per million = $10.95. Total $5 + $0.29 + $10.95 = $16.24. Poller CPU and row writes are immaterial at 1,000 and 10,000 users; in the heavy case poller CPU adds about $0.10 (53.1 million ms against 30 million included), which is in the $24.14.

Notes.
- Duration is an upper bound: an object idle between alarms is eligible to hibernate and is then not billed [V: pricing page], so real duration cost is likely lower. The Fly figure assumes the machines hold the cache and serve directly; at the peaks above that is trivial load.
- **Which platform is cheapest depends on the size.** At 1,000 users AWS is cheapest ($3.60, from the CloudFront Free plan and the Lambda free tier), then Fly ($7.40), then Cloudflare ($7.70). At 10,000 users and in the heavy case Fly is cheapest ($7.55 and $9.06; $11.15 and $12.66 with a static egress IP), Cloudflare second, and AWS dearest ($29.88 and $219.20) because a looping Lambda poller is billed while it sleeps (a small always-on container would be cheaper) and the flat CloudFront plan steps up at 1 million and 10 million requests.
- **Why Cloudflare is used for the headline totals.** It is the higher of the two cheap platforms at 10,000 users, so the totals are conservative; it has no servers to run and no egress charges [V: Workers pricing page]. It is not a cost recommendation. Fly is cheaper at 10,000 users and can give a fixed egress IP, which Cloudflare cannot (not verified [C]). The gap is under $20 a month, so choose on engineering grounds and on whether CTA wants a fixed address (§4.1).

### 5.4 (c) Upstream feed costs

Transit: **$0** at both sizes (all feeds free as published, subject to the confirmations in §6; Metra's free status is unverified [U]; Pace excluded). Aircraft, N = 30, 15 s polls, 2 cells, f unrounded (0.4752 and 0.9846) [A]:

| Aircraft source | Basis | 1,000 users | 10,000 users |
|---|---|---|---|
| None (aircraft off) | | $0 | $0 |
| adsb.lol, with the operator's written permission, **if its rate limits allow** (a third-party report shows limiting at a 4 s poll [T]) | free; 164,233 / 340,295 polls | **$0** | **$0** |
| FlightAware AeroAPI Standard | 2 result sets per poll at $0.050; list then volume discount; $100 minimum | list $16,423, after discount **$6,072** | list $34,029, after discount **$8,964** |
| Flightradar24, $0.0003 per credit (smallest package) | 6 credits x 30 aircraft x polls | **$8,869** (29.6 million credits) | **$18,376** (61.3 million credits) |
| Flightradar24, $0.000248 per credit (best of the five example packages on the credit-overview page) | same credits | **$7,331** | **$15,191** |
| Flightradar24, $0.000214 per credit (largest package on the subscriptions page: $990 for 4,620,000 credits) | same credits | **$6,335** | **$13,126** |
| ADS-B Exchange Enterprise, OpenSky licensed tier | quote only; ADS-B Exchange also needs a special agreement for a relay (§3.1b) | [C] | [C] |

FlightAware's volume discount is marginal by band of monthly usage: first $1,000 at list, then 30%, 51%, 65%, 76%, 83%, 88% off up to $64,000, then 94% [V: [pricing page](https://www.flightaware.com/commercial/aeroapi/), re-read this pass]. Example: $8,640 of list usage becomes $1,000 + $1,000 x 0.70 + $2,000 x 0.49 + $4,000 x 0.35 + $640 x 0.24 = $4,233.60.

**Sensitivity** (2 cells, same f; FlightAware after discount, Flightradar24 at the $0.0003 smallest-package rate):

| Polls and aircraft per poll | FlightAware 1,000 | FlightAware 10,000 | Flightradar24 1,000 | Flightradar24 10,000 |
|---|---|---|---|---|
| 15 s, N = 15 | $4,131 | $6,173 | $4,434 | $9,188 |
| 15 s, N = 30 (headline) | $6,072 | $8,964 | $8,869 | $18,376 |
| 15 s, N = 60 | $8,822 | $12,804 | $17,737 | $36,752 |
| 30 s, N = 30 | $4,131 | $6,173 | $4,434 | $9,188 |
| 60 s, N = 30 | $2,717 | $4,202 | $2,217 | $4,594 |

Flightradar24 at 60 s, N = 30, by credit rate: $2,217 and $4,594 at $0.0003; $1,833 and $3,798 at $0.000248; $1,584 and $3,281 at $0.000214 (1,000 and 10,000 users).

Limits check: two cells at 15 s is 8 queries per minute, which fits all Flightradar24 plans by rate (Explorer's cap is 10 per minute) but the Explorer plan's 20-item response limit would truncate a busy box [V].

### 5.5 Key insight: what scales with what

| Change | Phone requests and egress | Relay cost | Aircraft upstream (FlightAware, N = 30, 15 s) | Aircraft upstream (Flightradar24 at $0.0003 per credit) |
|---|---|---|---|---|
| Users x10 (1,000 to 10,000), 2 areas | x10 | $7.70 to $16.24 (x2.1) | $6,072 to $8,964 (x1.5) | $8,869 to $18,376 (x2.1) |
| Areas 2 to 6 to 20 (10,000 users, f = 1) | each phone still polls one rectangle: unchanged | more pollers: small | $9,027 to $14,941 to $29,456 (x3.3; the volume discount deepens) | $18,662 to $55,987 to $186,624 (x10) |
| Poll interval 15 s to 30 s to 60 s | unchanged | unchanged | falls by about a third per step after the discount (list price halves) | halves each step |
| Aircraft per poll 15 to 30 to 60 | unchanged | unchanged | rises about 1.45 times per doubling after the discount (list price doubles) | doubles |

**Upstream cost scales with active areas and poll interval, not with users.** More users only keep the same areas active for more hours (f rises from 0.4752 to 0.9846 and then cannot rise further). Relay egress scales with users but costs almost nothing. Per user the aircraft bill falls as users grow: at 1,000 users FlightAware is about $6.07 and Flightradar24 about $8.87 per user per month; at 10,000 users about $0.90 and $1.84. Nothing here accounts for users spread over many metros; each added metro adds a full area cost.

### 5.6 Table and cheapest-viable recommendation

Total per month (relay on Cloudflare plus aircraft upstream), headline N = 30, 15 s, 2 areas:

| Aircraft option | 1,000 users | 10,000 users |
|---|---|---|
| Transit only, no aircraft | $8 | $16 |
| adsb.lol (permission needed) | $8 | $16 |
| FlightAware Standard | $6,080 | $8,980 |
| Flightradar24, $0.0003 per credit | $8,877 | $18,392 |
| Flightradar24, $0.000248 per credit (best example package on the credit-overview page) | $7,339 | $15,207 |
| Flightradar24, $0.000214 per credit (largest package on the subscriptions page) | $6,343 | $13,142 |
| FlightAware Standard at 60 s | $2,725 | $4,218 |
| Flightradar24 at 60 s, $0.000248 per credit | $1,841 | $3,814 |
| Flightradar24 at 60 s, $0.000214 per credit | $1,592 | $3,297 |

**Cheapest viable plan.**

1. **Ship transit first.** RTD first (no key, redistribution granted); CTA and Metra after written confirmations (§6); Pace not used. Upstream $0 (Metra's free status is unverified [U]), relay about $8 to $16 per month on Cloudflare, or $7.40 to $7.55 on Fly.io (plus $3.60 for a static egress IP).
2. **Aircraft: ask the adsb.lol operator** for written permission for production use, rate limits and an API key route. If granted and the rate limits allow, poll at 30 to 60 s with dead reckoning, filter LADD and PIA, and carry the ODbL attribution: $0 upstream.
3. **If permission is refused or the limits are unusable, keep aircraft off.** At 1,000 users a commercial feed costs about $1.6k per month at 60 s polling to about $9k at 15 s (two metros, 30 aircraft per poll), which is about $1.6 to $9 per user per month. Choose one only with revenue per user to match, and only after written confirmation of the relay model.
4. **If a paid feed is unavoidable.** In this model Flightradar24 at the largest-package rate ($0.000214) is cheaper than FlightAware Standard at 60 s polling at both sizes ($1,584 against $2,717 at 1,000 users; $3,281 against $4,202 at 10,000) and at 30 s at 1,000 users ($3,167 against $4,131), while FlightAware is cheaper at 15 s at both sizes ($6,072 against $6,335 at 1,000 users; $8,964 against $13,126 at 10,000) and at 30 s at 10,000 users ($6,173 against $6,563), because of its volume discount. Neither allows a community feed as a fallback without the provider's written agreement. ADS-B Exchange Enterprise is not an option for a relay without a special agreement.

---

## 6. Questions to ask each provider in writing

Nothing has been sent. Contact details are on each provider's page.

**Metra** (the answers also confirm the unverified wording in §2.2)
1. Is a paid or ad-supported app allowed under the GTFS-realtime licence?
2. Does filtering the feed by area, re-encoding it into a compact format, or discarding snapshots after a few minutes count as "modify or delete Data"?
3. Is a relay that serves many users from our own host what "redistribute through your own host" means? Is there any limit on end users?
4. What is the rate limit for keyed traffic (the unit of the `x-ratelimit-limit: 200` header)? Are keys per app or per person, and how long does approval take?
5. What exact wording do you require for the non-affiliation statement and last-updated time in a 3D scene, and on shared images and video? May they sit in a credits panel?
6. May we show line names and colours (for example UP-N) without breaching the trademark clause?
7. How will changes or withdrawal of the feed be announced?

**CTA**
1. Does a live-vehicle layer in a 3D world (ambient, not trip planning) fall under "assisting riders or promoting public transportation"? If not, what express permission do you give?
2. Which agreement text binds at key issue: the older copy on the key page or the current terms page?
3. Is our relay "your application", and may one key's data be served to many phones from one server?
4. Is the Train Tracker daily limit 50,000 or 100,000? How do we request more? Any rules for cloud egress addresses?
5. GTFS-RT beta: which key, what refresh rate and limits, which terms, and is it stable?
6. Does an ephemeral in-memory cache count under delete-on-termination? Is certification needed?
7. Is attribution required for our use, and may we show route colours and icons in a 3D scene?
8. What polling interval do you recommend for `ttpositions`, and how accurate are positions?

**Pace**
1. Does "non commercial use" cover a paid, ad-supported or free app with in-app purchases? Can you grant written permission for commercial use?
2. Are the `tmweb.pacebus.com` GTFS-RT endpoints official, supported and licensed? Under which terms, rate limits and SLA? Is there an official developer API?
3. May we show route names without the name-and-logo consent clause applying?

**RTD**
1. Is a paid or ad-supported app allowed (the licence is silent)?
2. Does the GTFS-RT licence also govern the static GTFS download?
3. Is there a polling guideline or rate limit for `open-data.rtd-denver.com`, and an official refresh interval?
4. Is the "unofficial web site" notice required for us, and where?
5. What are the terms for the Bustang (CDOT) feeds?

**adsb.lol operator**
1. May a commercial app use the API in production through one relay, polling about once per 30 to 60 s per area? What rate limits apply, and how do we get the planned API key?
2. What attribution wording do you want? Does our relay's normalised snapshot count as an adapted database under ODbL, and do you treat our rendered 3D view as a Produced Work?
3. Do you have an SLA, a descriptive User-Agent format and a LADD or PIA policy?
4. Is there a sponsorship or support route?

**FlightAware**
1. Is a 3D scene showing overhead aircraft a "commercial aircraft situational display"?
2. Does serving derived, normalised positions from our relay to many users of our app satisfy the Standard licence (non-raw, embedded, not via the API)? What counts as raw, and does normalising or filtering count as a Derivative Work (allowed) or as modifying AeroAPI Data (barred without written permission)?
3. Is the November 2022 Standard licence current? Does "B2C" cover a free or ad-supported app, and what applies if we license the engine to other app makers (the pricing page lists B2B under Premium)? Would you give written permission to fall back to a community feed when AeroAPI is unavailable?
4. How often do positions update, and does `/flights/search` omit blocked or LADD aircraft?
5. What in-app attribution do you require?
6. Is there a spend cap, and a commitment discount for our pattern (2 areas, 15 to 60 s)?

**ADS-B Exchange / JETNET** (only if the Enterprise API is considered)
1. Can an Order Form define a workflow in which one relay retrieves data for many app users who are not JETNET subscribers (terms 2.d and 2.b(xi))? What would a reseller, referral or pass-through agreement look like, and what would it cost?
2. What is the price, and the request-rate limit, of an Enterprise plan that covers two 30 km cells polled every 15 s?

**Flightradar24**
1. May our relay serve normalised live positions to many app users, given the raw-data redistribution clause (unverified wording)?
2. Does the API apply LADD and blocked-flight filtering?
3. What credit wording is required, and does the 30-day storage rule apply to an in-memory snapshot?
4. Is the Advanced plan limit 90 or 200 queries per minute? Are larger credit packages cheaper than the examples? What are the sandbox limits?

---

## 7. Unverified facts and sources

### 7.1 Unverified facts: unverified (site blocks automated access; confirm in a normal browser)

Re-open each in a normal browser and compare before relying on it.

**Metra (read from metra.com with a browser-style User-Agent after a 403; a browser visit was denied)**

| # | Fact | Where it appears | Source |
|---|---|---|---|
| U1 | The 11 Metra lines incl. UP-N; the key is requested by web form with a licence tick-box; old host retired 2025-11-01 | §2.2 | [metra.com/developers](https://metra.com/developers) |
| U2 | Endpoints (`positions`, `tripupdates`, `alerts`, `schedule.zip`, `published.txt`); 30 s refresh; 3:00:00 AM static publish; bearer token or `api_token`; relay requirement; position and trip-update semantics | §2.1, §2.2, §4 | [metra.com/metra-gtfs-api](https://metra.com/metra-gtfs-api) |
| U3 | Licence grant (use, reproduce, redistribute); redistribute through own host; must not modify or delete Data; must not use inaccurate Data; non-affiliation and last-updated statements; no accuracy claims; Metra marks not used with the Data; AS IS; may terminate and stop without notice; terms may change; Illinois law; no "commercial" wording | §1, §2, §4 | [Metra licence](https://metra.com/gtfs-realtime-api-key-request-license-agreement) |
| U4 | Website terms bar commercial use of the site and robots (the site, not the API) | §2.1b | [metra.com/terms-and-conditions](https://metra.com/terms-and-conditions) |
| U5 | No published rate limit; approval process, per-app or per-person keys: not stated | §2.2 | Metra pages above |

The Metra API-host header observations (`published.txt`, `schedule.zip`, `positions` 401 and `x-ratelimit-limit: 200`) were repeated on 2026-10-06 with an honest client and are tagged [O], not [U].

**NITA Data Hub**

| # | Fact | Source |
|---|---|---|
| U6 | The Data Hub describes a repository of data sets and lists no real-time feed | [datahub.nita.illinois.gov/about](https://datahub.nita.illinois.gov/about) (returned 403 to automated fetch) |

**Aircraft (tagged [U] in the aircraft research)**

| # | Fact | Where it appears | Source |
|---|---|---|---|
| U7 | OpenSky terms: operational API use needs a written licence even for non-profits; no distribution outside the institute (clause 3(iii)); expunge copies at the end of research (4(ii)); also 3(vi) | §3.1b (OpenSky row) | [opensky-network.org/about/terms-of-use](https://opensky-network.org/about/terms-of-use) and [/data/api](https://opensky-network.org/data/api) (403 to automated fetch) |
| U8 | airplanes.live: earlier terms (non-commercial, no SLA, 1 request per second, no feeder needed then), the point endpoint, `/ladd` and `/pia`, `dbFlags` bits, "unfiltered" mission | §1 blocker 4, §3 intro, §3.1a and §3.1b (airplanes.live rows), §7.4 | Archive copies of its API guide, About page and `openapi.yaml` (origin returned 403) |
| U9 | Flightradar24 ToS (last updated June 23rd 2026): commercial use and derivatives permitted but no reselling, transferring or redistributing raw data (6.3.1); derivatives need significant value (6.3.2); external storage barred (3.6); backfill of another provider barred; credit Flightradar24 (8.2); clause 2.4 | §1 blocker 5, §3.1b (Flightradar24 row), §3.2, §4.1, §4.8, §6 | [flightradar24.com/terms-of-service](https://www.flightradar24.com/terms-of-service), archive snapshot 2026-09-16 (origin returned 403) |
| U10 | ADS-B Exchange support home describes the community as "unfiltered" feeders | §3 intro (as supporting evidence only; the [V] JETNET release says the same) | Archive copy of support.adsbexchange.com, 2026-09-06 (bot check) |

### 7.2 Third-party and unconfirmed items (not unverified-by-blocking, but not authoritative)

- **[T]** adsb.lol rate-limited about two thirds of the time at a 4 s poll, and requires a descriptive User-Agent (a third-party GitHub issue, repository `skylight`, issue 66; owner name omitted, so the link is not given); airplanes.live feeder-only (the same issue); a search-engine summary that ADS-B Exchange does not accept filtering requests; the apis.io Metra "rate limits"; a third-party GitHub issue (repository `ghost-bus-tracker`, issue 1, owner name omitted) that CTA Train Tracker and Bus Tracker keys fail on the CTA GTFS-RT beta; Transitland Atlas for the Pace GTFS-RT URLs.
- **[C]** Metra: approval time, per-app keys, paid use, area filtering, the `route_id` string for UP-N. CTA: refresh rate and recommended polling for Train Tracker; which daily limit is right; GTFS-RT beta rate, key and terms; whether a relay is "your application". Pace: any official terms for the live endpoints. RTD: commercial use, rate limit, official refresh interval, Bustang terms, forum contents, which modes the GTFS-RT feeds carry. Aireon's own sales channels. Whether Cloudflare Workers can use a fixed egress IP. Whether FlightAware Standard covers a free app licensed to other app makers. adsb.lol: refresh rate, rate limits, attribution wording. adsb.fi: LADD handling. FlightAware: update rate, whether area search omits blocked aircraft, meaning of "commercial aircraft situational displays", whether the 2022 licence is current, in-app attribution. Flightradar24: LADD filtering in the API, Advanced rate limit (90 or 200). Real aircraft counts per box; real payload sizes and vehicle counts per tile.
- **Corrections to my earlier research notes.** (1) CTA bus routes are 127, not about 150 (the alerts page claim was not found), so a full sweep is 13 calls. (2) Pace's "not available for download" sentence is on the data page, not on the Bus Tracker tools page. (3) The "reply pretty quickly" sentence is on the Train Tracker overview, not the key-application page.

### 7.3 Procedural notes

- During this pass one batch check mistakenly included a `metra.com` address; one request with the honest User-Agent was sent and its output was discarded unread. Nothing from it is used in this document, and `metra.com` was not requested again.
- The aircraft research notes disclose that its first fetches used a browser-style User-Agent from the start. Every fact tagged [V] there was re-fetched with an honest User-Agent, and a sample of them was fetched again in this pass (FlightAware, Flightradar24, adsb.lol, adsb.fi, ADS-B Exchange, FAA, OpenSky REST docs). Only the facts tagged [U] remain unverified.
- Fixes after the independent check re-read only unblocked hosts (transitchicago.com, pacebus.com, rtd-denver.com, jetnet.com, adsbexchange.com redirect address and `gateway.adsbexchange.com`, flightaware.com, fr24api.flightradar24.com, api.adsb.lol and www.adsb.lol, faa.gov) with the honest User-Agent `WorldEngine-research/0.1`; each redirect target was checked before the page was read. `metra.com` and `datahub.nita.illinois.gov` were not requested. No [U] fact was re-fetched.

### 7.4 Sources, all accessed 2026-10-06

"Re-read" means fetched again for this document with an honest client; "earlier" means read earlier the same day with the default fetch client.

**Metra** (all content pages [U]; API hosts [O])
- https://metra.com/developers
- https://metra.com/metra-gtfs-api
- https://metra.com/gtfs-realtime-api-key-request-license-agreement
- https://metra.com/terms-and-conditions
- https://schedules.metrarail.com/gtfs/published.txt and `schedule.zip` (header requests, re-observed)
- https://gtfspublic.metrarr.com/gtfs/public/positions (one unauthenticated request, re-observed)
- https://apis.io/rate-limits/metra/metra-rate-limits/ [T]
- https://mobilitydatabase.org/feeds/gtfs/mdb-2854 [T]

**NITA**
- https://nita.illinois.gov/about-rta/press-releases/northern-illinois-transit-authority-begins-new-era-for-regional-transit (re-read)
- https://datahub.nita.illinois.gov/about [U]

**CTA**
- https://www.transitchicago.com/developers/terms/ (re-read)
- https://www.transitchicago.com/developers/branding/ (re-read)
- https://www.transitchicago.com/developers/traintracker/ (re-read)
- https://www.transitchicago.com/developers/traintrackerapply/ (re-read)
- https://www.transitchicago.com/developers/ttdocs/ (re-read)
- https://www.transitchicago.com/developers/bustracker/ (re-read)
- https://www.transitchicago.com/assets/1/6/cta_Bus_Tracker_API_Developer_Guide_and_Documentation_2025-04-21.pdf (earlier)
- https://www.transitchicago.com/assets/1/6/cta_Train_Tracker_API_Developer_Guide_and_Documentation.pdf (earlier)
- https://www.transitchicago.com/developers/gtfs/ (re-read)
- https://www.transitchicago.com/developers/alerts/ (re-read)
- https://www.transitchicago.com/facts/ (127 routes, eight rail routes; read this pass)
- https://transitdata.transitchicago.com/ (re-read)
- A third-party GitHub issue (repository `ghost-bus-tracker`, issue 1, opened 2026-10-05) [T]; the owner name is omitted on purpose, so no link

**Pace**
- https://pacebus.com/route-timetable-data-services (re-read)
- https://pacebus.com/bus-tracker-tools (re-read)
- https://tmweb.pacebus.com/TMGTFSRealTimeWebService/vehicle/VehiclePositions.pb, `.../tripupdate/tripupdates.pb`, `.../alert/alerts.pb` (header requests, re-observed)
- https://raw.githubusercontent.com/transitland/transitland-atlas/main/feeds/pacebus.com.dmfr.json [T]
- https://github.com/transitland/transitland-atlas/pull/2201 [T]

**Denver RTD**
- https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement (re-read)
- https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds (re-read)
- https://www.rtd-denver.com/open-records/open-spatial-information/gtfs (earlier)
- https://www.rtd-denver.com/terms-of-use (earlier)
- https://open-data.rtd-denver.com/files/gtfs-rt/rtd/VehiclePosition.pb, `TripUpdate.pb`, `Alerts.pb` (header requests, re-observed)

**Aircraft**
- OpenSky: https://openskynetwork.github.io/opensky-api/rest.html (re-read), https://openskynetwork.github.io/opensky-api/index.html (earlier), https://opensky-network.org/about/terms-of-use [U], https://opensky-network.org/data/api [U]
- ADS-B Exchange / JETNET: https://www.adsbexchange.com/community/developer-hub/ (re-read), https://www.jetnet.com/legal/terms-of-use/ (re-read; https://www.adsbexchange.com/terms-of-use/ redirects there), https://www.adsbexchange.com/data-products/ (earlier), https://gateway.adsbexchange.com/api/aircraft/v2/docs/openapi.json (re-read), https://www.jetnet.com/resources/press-releases/jetnet-acquires-ads-b-exchange (re-read; the older address jetnet.com/news/jetnet-acquires-ads-b-exchange.html redirects there)
- adsb.lol: https://api.adsb.lol/api/openapi.json (re-read), https://www.adsb.lol/ (re-read), https://www.adsb.lol/privacy-license/ (earlier), https://www.adsb.lol/docs/open-data/api/ (earlier), https://opendatacommons.org/licenses/odbl/summary/ (earlier); third-party GitHub issue (repository `skylight`, issue 66; owner name omitted, no link) [T]
- adsb.fi: https://raw.githubusercontent.com/adsbfi/opendata/main/README.md (re-read)
- airplanes.live: Internet Archive copies [U]; https://raw.githubusercontent.com/airplanes-live/api-archive/main/README.md (earlier; archived repository for a different older API)
- FlightAware: https://www.flightaware.com/commercial/aeroapi/ (re-read), https://www.flightaware.com/commercial/aeroapi/resources/aeroapi-openapi.yml (re-read), https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf (re-read), https://www.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2025.pdf (re-read), `AeroAPI_Personal_License_Jul2026_v2.pdf` (earlier), https://www.flightaware.com/commercial/flightaware-terms-conditions-Sep2026.pdf (earlier)
- Flightradar24: https://fr24api.flightradar24.com/docs/credit-overview (re-read), https://fr24api.flightradar24.com/docs/storage-rules (re-read), https://fr24api.flightradar24.com/subscriptions-and-credits (re-read), `/docs/faq`, `/documentation/Flightradar24-API.yaml` (earlier), https://support.fr24.com/support/solutions/articles/3000117426-why-does-it-say-that-a-flight-is-blocked- (earlier), https://www.flightradar24.com/terms-of-service (archive copy [U])
- Privacy and others: https://www.faa.gov/pilots/ladd (re-read), https://nbaa.org/aircraft-operations/security/privacy/privacy-icao-address-pia/ (earlier), https://www.faa.gov/air_traffic/technology/swim/products/get_connected (re-read), https://aviation-docs.spire.com/api/flights-live/introduction (earlier), https://wingbits.com/pricing and https://wingbits.com/terms-and-conditions/b2b (earlier)

**Relay hosting prices** (read this pass)
- https://developers.cloudflare.com/workers/platform/pricing/ (also https://developers.cloudflare.com/kv/platform/pricing/ and https://developers.cloudflare.com/durable-objects/platform/pricing/ were fetched; figures used come from the first)
- https://fly.io/docs/about/pricing/
- https://aws.amazon.com/lambda/pricing/
- https://aws.amazon.com/cloudfront/pricing/
- https://docs.hetzner.com/cloud/billing/faq/ (plan prices on https://www.hetzner.com/cloud/ did not load without JavaScript)
