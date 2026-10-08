# Builder event templates v1

Proposal · 7 October 2026 · WorldEngine Style B

Open **index.html** for five aerial/eye-level boards and linked read-only client snapshots. Rules are renderer-neutral metre-based data. The supplied scene art is illustrative, not a render of the rule coordinates, guest counts or bill of materials, and does not certify clearances. No actual site or forecast is represented.

## Deliverables

- Five segment JSON files in `rules/`, each with 100, 500, 2,000 and 10,000 simultaneous-guest cases, required parts, areas, adjacencies and operating rules.
- `common-rules.json`: scoped verified references, explicit assumptions, formulas, weather decision fields and unresolved inputs.
- `parametric-parts.json`: dimensional additions, service envelopes and illustrative power loads. `visual-values.json`: shared approved calibration values and screen-size tiers.
- Five two-view generated boards in `images/`; five client HTML snapshots. Exported views in `mocks/`; responsive checks in `phone-check/`.
- `sources.md`, exact generation `prompts.json`, and the wedding edit prompt in `edit-provenance.json`.

## What is verified, and what is proposed

All per-segment dimensions, densities, ratios, quantities and layout targets are **assumptions**, unless explicitly linked to a scoped verified reference in common rules. Sources were checked on 7 October 2026. UK HSE guidance, US federal accessibility/workplace requirements, model-code excerpts and local Seattle/San Diego examples have different scopes; none is a universal event approval. Indexed code excerpts whose direct page could not be read are identified in the source register. Actual local adoption remains unverified.

IBC occupant-load examples: standing 5 net ft²/person, chairs-only 7, tables/chairs 15. These are design-load factors, not safe operating densities. Proposed crowd target is 1 person/m², review at 1.5, halt admission at 2; a competent crowd plan can require lower limits. Egress uses declared guests + provisional crew for illustrations, while **code design occupant load is unset**. Distribution, travel, downstream dispersal and evacuation time require review.

## Count logic and scale

Default event duration is four hours, no alcohol. Example staff = ceil(10% of guests), so peak example N = guests + staff. Toilets = max(2, ceil(N/75)); duration/alcohol uplift is a provisional 1.5 multiplier. At least 10% accessible, rounded up, and at least one per bank; accessible units are included, not extra. Public handwash is additional to food-service handwash. These are conservative planning defaults, not verified universal restroom ratios.

Medical point counts reserve space only; clinical staffing remains unset. Power sums listed example loads, excludes unprovided catering/large sound loads, and cannot select a generator. No generic ballast mass or tent wind speed is supplied. Manufacturer configuration, anchor plan, measured gust definition and engineer-approved triggers are required.

Wedding inventory includes **two chair sets**, ceremony and reception; each phase seats the same G guests with wheelchair spaces substituted. This does not double-count guests. At 2,000–10,000 guests, use separately serviced districts with independent routes and queues, not a uniformly enlarged tent. The case tables are not geometrically packed floor plans.

## Outdoor wedding

Ceremony and reception use the same guest group in different time phases; do not double-count guests, but retain staff and overlaps. Central aisle target1.8m plus outer cross access; chair-row/gangway rules depend on local adopted code, not this dimension alone. Photo positions tested at ceremony/portrait times, using actual solar model and photographer preference; reflected glare/trees also matter. Catering heat/cooking is separate from dining marquee; no generic kitchen/fire approval. Rain option: approved covered reception layout; severe-weather option: capacity-confirmed building/vehicle plan or early cancellation. At2000/10000, use multiple reception/ceremony districts with separate services, not one giant stretched marquee.

| Guests | Example peak incl. crew | Districts | Toilets (accessible included) | Primary usable m² target | Proposed gates × clear width |
|---:|---:|---:|---:|---:|---|
| 100 | 110 | 1 | 2 (1) | 200 | 2 × 3.0 m |
| 500 | 550 | 5 | 8 (1) | 1,000 | 4 × 3.0 m |
| 2,000 | 2,200 | 20 | 30 (3) | 4,000 | 6 × 3.0 m |
| 10,000 | 11,000 | 100 | 147 (15) | 20,000 | 12 × 5.25 m |

## Concert / festival

Stage facing is solved for event-time sun, audience glare, sound-sensitive boundaries and routes; no fixed compass rule. FOH island cannot pinch evacuation spine or accessible viewing routes; venue acoustics may require different position. Standing area excludes stage/FOH/queues/egress; target1 person/m² is a proposal, not a certified crowd limit. Medical tent count is a parts-list allowance; competent medical provider sets staffing, escalation and ambulance cover. Admission stops at holding/crowd trigger; distress or surge can trigger intervention earlier. At2000/10000 subdivide audience under competent crowd design, coordinate PA/comms and separate service banks.

| Guests | Example peak incl. crew | Districts | Toilets (accessible included) | Primary usable m² target | Proposed gates × clear width |
|---:|---:|---:|---:|---:|---|
| 100 | 110 | 1 | 2 (1) | 100 | 2 × 3.0 m |
| 500 | 550 | 1 | 8 (1) | 500 | 4 × 3.0 m |
| 2,000 | 2,200 | 4 | 30 (3) | 2,000 | 6 × 3.0 m |
| 10,000 | 11,000 | 20 | 147 (15) | 10,000 | 12 × 5.25 m |

## Game-day activation

This G is fan-zone concurrent attendance, NOT stadium capacity; assess simultaneous stadium release and security boundary crowd loads separately. Do not narrow or cross the venue’s existing discharge routes with queues or activation parts. Tailgate vehicles/cooking are outside fan circulation; barriers/service buffer need site traffic and fire approval. No numerical security staffing ratio is implied by number of screening tents. Arrival screening throughput measured locally; independent emergency exit cannot require ticket/bag checks. At10000 use separated gate districts with individual arrival/dispersal plans; stadium operations own access interfaces.

| Guests | Example peak incl. crew | Districts | Toilets (accessible included) | Primary usable m² target | Proposed gates × clear width |
|---:|---:|---:|---:|---:|---|
| 100 | 110 | 1 | 2 (1) | 120 | 2 × 3.0 m |
| 500 | 550 | 1 | 8 (1) | 600 | 4 × 3.0 m |
| 2,000 | 2,200 | 4 | 30 (3) | 2,400 | 6 × 3.0 m |
| 10,000 | 11,000 | 20 | 147 (15) | 12,000 | 12 × 5.25 m |

## Experiential activation

Peak G is concurrent visitors; daily visitors do not size holding areas without dwell/arrival model. Pavilion/demo capacity derives from actual exhibit furniture and clear exits, not external roof footprint. Queue turns target1.8m and lanes1.5m; all public areas connect via firm paths; ropes/ballast stay out of route. Keep staff replenishment movement outside guest queue; no hidden delivery through accessible entry. Brand palette consists only of generic material colours, never a copied real company’s identity/trade dress. At500/2000/10000 use multiple independent pavilion clusters and schedule arrivals; do not make a single endless switchback.

| Guests | Example peak incl. crew | Districts | Toilets (accessible included) | Primary usable m² target | Proposed gates × clear width |
|---:|---:|---:|---:|---:|---|
| 100 | 110 | 1 | 2 (1) | 150 | 2 × 3.0 m |
| 500 | 550 | 5 | 8 (1) | 750 | 4 × 3.0 m |
| 2,000 | 2,200 | 20 | 30 (3) | 3,000 | 6 × 3.0 m |
| 10,000 | 11,000 | 100 | 147 (15) | 15,000 | 12 × 5.25 m |

## Corporate / community

Loose-chair layout needs locally reviewed row length/gangway rules; fixed-seat ADA table is a reference, not automatic certification of loose chairs. Registration queues offset from entrance/discharge; equivalent service and seating choices integrated with audience. Audio amplification triggers assistive-listening scope review; do not count a wheelchair space as the whole accessibility plan. Screens checked for event-time sun glare; stage access and cables cannot create a step-only path. Primary seated guests move to breakout/catering in phases; track actual concurrency per zone. At2000/10000 use district registration and AV distribution; authorities/provider review evacuation and communications.

| Guests | Example peak incl. crew | Districts | Toilets (accessible included) | Primary usable m² target | Proposed gates × clear width |
|---:|---:|---:|---:|---:|---|
| 100 | 110 | 1 | 2 (1) | 130 | 2 × 3.0 m |
| 500 | 550 | 5 | 8 (1) | 650 | 4 × 3.0 m |
| 2,000 | 2,200 | 20 | 30 (3) | 2,600 | 6 × 3.0 m |
| 10,000 | 11,000 | 100 | 147 (15) | 13,000 | 12 × 5.25 m |

## Weather, sun, sound and accessibility

Use the engine solar model at the actual event location/time. Calibration sun (40° elevation, 225° azimuth) is an art fixture only. Photo elevation preferences are assumptions. Stage orientation balances audience glare, heat, receiver noise and site access; no universal compass direction. Point-source distance attenuation is a simplified illustration, not a boundary-noise prediction. OSHA workplace limits are not audience targets or local noise permits.

Weather labels must distinguish observed, forecast and simulated, with issue/valid time and stale status. Wind trigger, heat trigger and refuge capacity remain unset until an accountable planner enters them. Lightning refuge must be a substantial building or hard-topped vehicle, not a tent; NWS recommends waiting at least 30 minutes after the last thunder before resuming. Covered rain layouts must be capacity checked independently. Heat plans require shade, water, rest, WBGT/risk monitoring and medical input.

Accessible route proposal: 1.8 m clear connecting arrival, activities, toilets and services, with a wider 3 m primary spine. ADA technical minima are scoped separately. Firm, stable, slip-resistant surfaces, slope/cross-slope, integrated seating, accessible service counters, cable crossings and accessible refuge need actual-site checks. Do not treat artwork grass or tent placement as evidence of access compliance.

## UX and phone use

Warm paper/forest UI follows creator-kit-ux-v3; all views share the same named template. Client pages are read-only version-1 snapshots; changing the view changes presentation only. Alternate guest cases are in JSON, not fabricated image changes. No upload registration, interactive 3D, forecast connection, approval or comment backend is implemented.

Phone checks cover 320/390 px, tablet 768 px and desktop 1440 px. Raster panels crop the generated two-view boards in browser layout; they are not regenerated geometry. Small people, ropes and exit details do not resolve at phone width, so safety-critical information remains in text/data. Art shows generic anonymous visitors, not real people or branded events.

## Top five recommendations

1. Make these guided starting plans, never automatic capacity approvals.
2. Keep code occupant load, actual concurrent count and guest attendance separate.
3. Require named suppliers and wind/anchoring/refuge decisions before weather-ready status.
4. Scale into serviced districts at large counts, with queues outside circulation.
5. Share immutable client versions with clear weather provenance and unresolved-review labels.

## Validation result

24 browser checks passed: six pages at 320, 390, 768 and 1440 px; no horizontal overflow, missing images or button targets below 44 px. The wedding client screenshot was visually inspected. All JSON parsed, all 20 case populations and accessible-toilet inclusion checked. These checks validate the deliverable, not event safety.
