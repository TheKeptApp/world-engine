# Live Flights v1 — recommendation and research
Checked **2026-10-07**. V = verified primary-source statement (provider claims are not independently measured); A = authored assumption/recommendation; U = unverified. Sources are linked by ID in sources.md. This is a licensing/design assessment, not a signed grant of rights. No signup, purchase or provider contact was made.

## Recommendation
**A:** Make **FlightAware the first commercial procurement candidate**, with **Firehose** as the intended production position/surface feed and gate/terminal layers from the same supplier. Use AeroAPI only for a narrowly scoped prototype after written confirmation of permitted 3D display. Cirium is the fallback bid for commercial status/gates plus a licensed raw-position stream. Do not launch under a personal/community tier or assume Premium resolves all restrictions.

**V — [FA-STANDARD](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf) / [FA-PREMIUM](https://uk.flightaware.com/commercial/aeroapi/AeroAPI_Premium_License_Jan2024.pdf):** The published licenses allow embedded consumer use; Premium adds B2B embedded/derived distribution. Both prohibit commercial aircraft situational displays, cap raw retention at 30 days, and require permission to combine another live provider. **U:** Whether WorldEngine's non-operational 3D map falls inside that display exclusion, and whether normalized environment/API records qualify for paid derived redistribution, needs explicit contract language. Premium is not a blanket raw-feed resale license. **A:** Ask for an order/addendum naming consumer 3D scenes, widgets/screenshots, backend fanout, exports, World State API clients, retention, interpolation, third-party mixing and privacy filtering. Prefer one licensed source initially.

## Provider comparison
| Provider | Coverage / freshness | Gates / surface | DISPLAY | STORE | RESELL / API | DERIVE | Published cost / decision |
|---|---|---|---|---|---|---|---|
| FlightAware AeroAPI | V global multi-source query service; U end-to-end position-age SLA. Do not reuse public-website delay as API promise | V gate/terminal data; U exact surface entitlement and accuracy at six airports | V embedded B2C allowed, but situational-display exclusion; A YELLOW pending clarification | V raw <=30 days | V Standard excludes B2B; Premium permits bounded paid embedded/derived use, not raw resale; A YELLOW | V permitted; mixing needs written permission | V $100 Standard /$1,000 Premium monthly minima, usage extra subject to minimum; A prototype only after display approval |
| FlightAware Firehose | V position/status stream, global layers; V sub-second events marketing, U capture-to-client position latency | V ExtendedFLIFO gate data and major-US surface layer; U airport-specific stand accuracy | U signed display scope | U retention | U licensed redistribution scope | U derivative/mixing scope | V fixed monthly negotiated by layers/use; A preferred production bid, YELLOW until order |
| Cirium Sky API / Stream | V commercial global offering; tracks have raw/derived choices and bounding-box query; U position cadence/age SLA | V terminal/gate fields; U continuous surface tracks and stand precision | U application-specific contract | U cache/history limits | U redistribution / resale | U normalized/derived rights | V PAYG advertised; U usable unit rates and production quote; A fallback bid, YELLOW |
| OAG Flight Info / Alerts | V schedules/status across advertised 3,600+ airports, event updates; U live coordinate feed in this product | V gates/terminals; U aircraft surface tracks | U contract | U retention | U redistribution | U derived rights | U current rate card/quote; A status alternative, not standalone plane tracker, YELLOW |
| ADS-B Exchange commercial | V receiver-network global position feed, selected 5s/500ms/250ms cadence; U end-to-end age/airport ground coverage | V operations context; U gate assignments, no demonstrated stand source | V commercial license needed, U specific public display scope | U contract | U resale/fanout | U derived rights | V annual commitment; U enterprise quote. $10 community is not commercial entitlement. A fast-position alternative, YELLOW |
| Aviation Edge | V tracker updates every few minutes; ADS-B plus schedule gap filling; U observed-vs-estimated granularity | V timetable gate fields; U six-airport accuracy and continuous taxi support | V own-app/internal use, U distributive 3D fanout interpretation | U caching duration; V derivative database prohibition | V prohibited resale/distribution under public terms; A RED for World State API without replacement terms | V derivative databases forbidden; U transient interpolation | V regular $299/30k, $599/100k, $1,499/500k calls; unlimited quote. A backup delayed consumer layer, YELLOW; RED for API |

Rights ratings are this pack's assessment, **not provider certification**. No provider is fully GREEN for the requested app plus downstream API without a fit-for-purpose agreement. OAG's update totals are aggregate throughput, not per-flight latency. Cirium derived positions and Aviation Edge schedule-filled gaps must be distinguished from observations. See sources.md for exact evidence/status.

## Phased plan
**A — Phase 1: approach paths only.** Build aircraft forms, runway/approach corridor rendering and privacy/provenance handling at MDW and DEN. Use authored demonstration trajectories labelled simulated; published procedure/maps are not automatically licensed geometry. Once schedule rights exist, a schedule-inspired approach remains a simulation, not a real aircraft location. Never claim a runway is active from scheduled destination or wind alone.

**A — Phase 2: observed live positions.** Commission a small-area feed with explicit consumer 3D rights, then expand to ORD/MDW/DEN/GSP/JFK/SFO. Centralize polling/stream subscriptions per geographic cell, not per user. Retain observedAt, receivedAt, provider/source type, position age and confidence. Start airborne only. Surface display is enabled separately per airport after evidence shows sufficient freshness and usable taxi geometry. Do not blend providers until licensed.

**A — Phase 3: gates, not merely gate labels.** Pilot GSP's small labelled inventory and MDW's curated stand map, then DEN; large evolving hubs later. Resolve airport + terminal/concourse + gate label to a curated stand (nose-wheel position, stop heading, compatible wingspan, geometry version). Only render occupancy with in-block evidence or credible stationary surface observations consistent with that stand. Scheduled gate assignment alone means planned gate, not occupied gate. An arriving flight's gate does not prove its next flight or turnaround duration.

**A:** Gate changes update metadata immediately but never teleport a plane across the apron. If taxi observations are lost, fade the observed aircraft; a separately labelled reconstructed taxi animation may follow a validated taxi graph, but must not be exported as observed. Refuse impossible simultaneous occupancy, ambiguous labels and missing stand headings. Do not park at a passenger gate's terminal-side coordinates.

## Gate assignment accuracy
**V — [CIRIUM-STATUS](https://developer.cirium.com/apis/cirium-sky-api/flight-status), [OAG-STATUS](https://knowledge.oag.com/docs/flight-info-api-migration-fvxml), [FA-FIREHOSE](https://www.flightaware.com/commercial/firehose/documentation), [AE-PRODUCT](https://aviation-edge.com/premium-api/):** These sources expose gate-related information. **U:** No independently verified airport-specific gate accuracy percentage, change latency, aircraft-stand occupancy accuracy or gate-to-stand geometry precision was found for the six requested airports. ADS-B Exchange gate assignment is unverified. A schema field is not an accuracy guarantee.

**A — acceptance trial before gates:** Sample at least 100 arriving/departing flight legs per airport over 7 days including disrupted periods. Match operating flight instance, date, destination and terminal, deduplicate codeshares. Compare gate revisions and in/out events against a permitted airport/airline reference. Measure non-null share, exact normalized match among known cases, mismatches, update lag and false occupied stands; report denominator and timing. Aim >=95% matched occupied stands among independently validated eligible cases with all mismatches suppressed; target is a proposal, not a vendor performance fact. Never infer ground occupancy solely from landed status.

## Airport geometry audit
A dated **measured OSM response inventory** is saved in airport-gates.json and six raw .osm extracts. Counts are objects in bounded extracts, not certified active gates, parking capacity or complete airport coverage. Several extracts use smaller terminal bounds after broad queries failed. Historical official ORD/MDW counts are comparison clues, not current denominators.

OSM gates mark passenger boarding locations. Parking-position nodes mark nose-wheel stops; directed parking-position ways can supply stopping point and alignment. Gate and stand refs may differ. **V — [OSM-GATE](https://wiki.openstreetmap.org/wiki/Tag:aeroway=gate) / [OSM-STAND](https://wiki.openstreetmap.org/wiki/Tag:aeroway=parking_position).** Thus high gate count does not provide parking poses. A labelled stand way still needs geometry, duplicate and terminal validation.

Per-airport measured table, ref gaps and specific risks are in airport-audit.md. Missing fields commonly relevant to WorldEngine include stop heading for isolated nodes, apron elevation, stand dimensions, jet-bridge pose, gate aliases, temporary closures, remote stand links and current occupancy; **A/U:** check rather than assume absent everywhere.

**V — [OSM-LICENSE](https://www.openstreetmap.org/copyright):** Retain OSM attribution/ODbL obligations for geometry. **A:** Keep proprietary flight observations separate from OSM-derived airport databases; have database distribution obligations reviewed for the combined product. Official airport passenger maps are references, not automatically reusable commercial meshes. Do not trace third-party aerial imagery or airport maps without rights. Store every stand's evidence, timestamp, terminal namespace and confidence.

## Cost model
**A:** Users below mean illustrative monthly active users. User count alone cannot determine provider spend: viewed regions, aircraft density, backend deduplication, sessions, subscription entitlements and fanout drive it. Workload assumptions: 30-day month, backend position queries every30s, status/gate every120s, one poll per airport region, and small bounded response windows. Position pages must include all visible aircraft; imposing max_pages to save cost can make coverage incomplete.

**V — [FA-PRICE](https://www.flightaware.com/commercial/aeroapi/):** Model uses $0.05 per position-search result set and $0.005 per airport arrival/departure result set; 15 records/set. Current tier minima are $100/$1,000 and progressive usage discount bands are applied in cost-estimate.json. **A:** Four gate result sets per polling cycle are a combined arrival/departure-window assumption, not one magically complete airport endpoint. Costs exclude metadata lookups, retries, archives, taxes, custom rights and hosting. Query eligibility/pagination must be confirmed in a trial. Price calculations do not establish legality.

| Illustrative MAU | Pooled regions / daily enabled hours | Position sets/cycle | Total queries/month | AeroAPI list usage | Discounted usage/month | Aviation Edge regular capacity illustration |
|---:|---|---:|---:|---:|---:|---|
| 1,000 | 1 /4h | 2 | 18,000 | $1,512 | $1,358.40 | $299 Developer |
| 100,000 | 6 /12h | 2 | 324,000 | $27,216 | $7,906.72 | $1,499 Business Gold |
| 1,000,000 | 60 /24h | 4 | 6,480,000 | $1,062,720 | $72,483.20 | Unlimited quote |

These are **A** scenarios, not empirical MAU forecasts or vendor quotes. Aviation Edge capacity comparison is not an equivalent freshness/quality/rights offer; its data may update only every few minutes, so repeated30s calls are wasteful. At the same 6 regions/12h footprint, 1M users could keep upstream query usage equal to the100k case, but delivery costs/license fees may change. A per-user10minute session with20s polling would create30 calls/person/month: 30k/3M/30M calls respectively before pagination—avoid that architecture.

**U — Cirium, OAG, ADS-B Exchange enterprise, Firehose:** Full production cost at1k/100k/1M users is quote-only or not verified, so no numeric vendor fee is invented. Request common scenario quotes including B2C/B2B fanout, geographic extent, positions/status/surface layers and storage. **A:** Use the AeroAPI benchmark as a compare-to ceiling for seeking a scoped streaming offer, not a prediction of Firehose pricing. Hosting/CDN/websocket egress cannot be credibly priced without concurrency and payload measurements; budget separately. Phase1 authored demonstration has $0 live-data fee, but development/maps/hosting still cost money.

## Tail numbers, LADD and privacy
**V — [FAA-LADD](https://www.faa.gov/pilots/ladd) / [FAA-PIA](https://www.faa.gov/air_traffic/technology/equipadsb/privacy):** FAA SWIM participating vendors must filter LADD aircraft from public display. LADD does not prevent independent ADS-B broadcasts; PIA changes identification exposure. Therefore neither a universal ban on all independent reception nor blanket permission to publish all tails follows. **U:** Other jurisdiction-specific privacy law and the negotiated supplier's suppression terms need review.

**A — WorldEngine default:** Show commercial-flight class silhouettes with no painted tail numbers, carrier markings, owner lookup, identity overlay or persistent personally identifying trail. Apply supplier suppression before client/API delivery; omit blocked/PIA/sensitive aircraft entirely rather than merely removing their labels. This is a chosen conservative product policy, not a claim that all anonymous coordinates are lawful. Do not try to reconstruct PIA identities from registry joins, schedules or other feeds. Obtain a current supported suppression mechanism; absent optional LADD flags do not mean safe-to-display. Generic white livery alone does not satisfy filtering. Flight numbers can be licensed later for eligible public commercial services; public N-number lookup is not a license to republish tracking.

## Aircraft type → generic model
**V — [ICAO-TYPES](https://cfapps.icao.int/doc8643/Fo.en.pdf):** Type designators are a distinct namespace; IATA equipment codes must not be interpreted directly as ICAO codes. **A:** Normalize with provenance using supplier-licensed metadata, then map configuration to a small class library. Do not redistribute ICAO's whole reference database without verified rights.

| Generic model | Example input families (authored mapping) | Representative design length × span, m |
|---|---|---|
| Narrowbody twin underwing jet | A320/A321/B737 family ICAO variants | 38 ×36 |
| Regional jet, underwing | E170/E190 family | 32 ×28 |
| Regional jet, rear-engine | CRJ family variants | 32 ×25 |
| Widebody twin | B777/B787/A330/A350 variants | 65 ×62 |
| Widebody four-engine | B747/A380 variants | 72 ×72 |
| Twin turboprop | AT72/DH8D | 30 ×28 |
| Small prop | C172 and similar | 9 ×11 |
| Business jet | licensed descriptor identifies rear jet | 20 ×19 |
| Helicopter | rotary-wing descriptor | 13 ×12 rotor diameter |

All sizes and assignments in this table are **A representative authored defaults**, not exact type dimensions. For true scale use licensed type-specific dimensions when available, with class-range checks and a matching collision footprint. Do not scale a generic mesh independently along all axes until it no longer resembles a plausible aircraft. Unknown equipment remains unknown; a class fallback is visibly approximate, not an asserted narrowbody.

**A — animation/rendering:** Airborne use measured ground track for motion; heading is a separate quantity. Bank/pitch inferred from velocity changes are aesthetic estimates, not telemetry. Gear deployment based on approach state is inferred unless measured; contrails need altitude/weather conditions, not all flights. Preserve altitude units/source: barometric altitude is not interchangeable with geometric/DEM height; require datum-aware conversion before ground contact. Surface wheels meet apron elevation; never clamp an airborne aircraft to terrain to conceal bad heights. Stop pose anchors nose wheel, not mesh centre; apply model-specific offsets.

Suggested projected tiers: >=64px longest dimension near mesh <=4k triangles;16–64px mid<=800;4–16px far<=120; below4px cull, no artificial enlargement. Initial scene target <=12k aircraft triangles and <=8 aircraft draws within existing visual-v2 world/shadow ceilings; these are **A unbenchmarked subcaps**. Avoid full-scene aircraft shadows; only nearby apron casters. Three.js/RealityKit consume the same metres, class ID, pose, timestamps and provenance.

**A — proposed freshness policy:** distinguish observation age, provider processing lag and interpolation delay. Airborne interpolate between samples; extrapolate at most10s, mark stale after30s and hide after120s. Ground extrapolate at most2s, freeze/fade after10s stale, hide after30s. Tune using measured airport feeds; stale threshold is not provider SLA. Never let extrapolation carry aircraft through terminals or runway transitions. Continuous taxi is not viable with minutes-old observations.

## Risks / go-no-go
1. **A high:** contract ambiguity, especially situational-display exclusion and raw/normalized API resale. GO research/design; NO-GO live launch until the actual order explicitly covers use.
2. **A high:** missing/estimated positions and altitude datums. GO airborne observed-first with age/provenance; NO-GO pretend exact live taxi from delayed status.
3. **A high:** gate label != stand occupancy, aliases and construction. GO curated limited-airport trial; NO-GO automatic parking from gate text.
4. **A medium/high:** privacy filtering and provider mixing. GO supplier-supported suppression and one source; NO-GO re-identification or silent backfill.
5. **A medium:** polling pagination, dense airports, egress and licensed fanout. GO pooled subscriptions with measured budget; NO-GO per-user flight polling.
6. **A medium:** generated mock geography is illustrative. These three views are not evidence of real gate geometry, flight paths, live position or aircraft assignment.

## Deliverable views
Chicago approach, Midway taxi toward a gate, Denver terminal apron. All use generic white aircraft, no airline logos, and calibration-v2 matte lighting. They illustrate intended appearance; production must use measured airport layout and licensed observations. Prompts and manifest are included.
