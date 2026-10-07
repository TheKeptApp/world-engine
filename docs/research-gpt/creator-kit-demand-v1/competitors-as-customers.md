# Competitors as customers: WorldEngine licensing prospects
Research date: 7 October 2026. Companion: [competitors-as-customers.csv](competitors-as-customers.csv).

## Recommendation first
Prioritize **Terranaut, Mapme and CampusTours** for an optional live-world viewer. They sell public-facing place presentations, have route/content overlays worth preserving, and offer a plausible place for a premium visual mode. Terranaut is the closest product fit; Mapme has broader distribution; CampusTours has a campus storytelling use where approved custom architecture matters. This ranking is an analyst judgment about product fit and switching friction, **not evidence of buying interest**.

Offer a licensed exterior renderer and scene/data bridge beneath their existing product. Most prospects would need a **web SDK and responsive embed**. WorldEngine is described as an iPhone engine; a production web SDK, Android compatibility, global coverage, enterprise support and contracted availability have **not been verified**. These are prerequisites, not capabilities assumed to exist. A US city-only release would sharply narrow every global prospect; site-by-site opt-in could still work.

The strongest promise is recognizable places with live time, sunlight, weather and readable Style B geometry. “Better-looking” is a positioning hypothesis, not an objective conclusion from this research. Several products already offer polished 3D, photorealistic context or custom artwork. Preserve their editor, CMS, tracking, engineering or analytic value rather than rebuild it.

## Evidence and limits
- **Documented:** a named vendor/library in primary product, support or engineering material. Historical evidence is labeled.
- **Inference:** likely switch requirements, prospective deal structure and the ranking. No vendor was contacted.
- **Unverified:** renderer versions, private bills, traffic, customer counts, supplier contracts, willingness to pay and WorldEngine delivery capability.
- **Visual review limitation:** browser security prevented interactive visual inspection. Descriptions below use accessible product documentation, image descriptions and published examples. No screenshots were captured, no phone/frame-rate test was performed, and visual quality assessments are provisional. Linked pages provide the requested visual references. Some dynamically loaded pages and DevSutes feature content were only accessible through indexed material; no access restriction was bypassed.
- A provider is not necessarily the renderer: Mapbox routing does not prove Mapbox GL JS; MapLibre does not imply a Mapbox renderer bill; Google directions do not prove Google 3D Tiles; custom campus artwork does not prove an orbitable live 3D scene. No confirmed Cesium deployment was found among these 13.

## Ranked prospects
| Rank | Prospect | Most plausible licensed addition | Annual commitment hypothesis, USD |
|---:|---|---|---:|
| 1 | Terranaut | Optional urban course/event-village Style B viewer; preserve mountainous terrain and existing route editor. | $3,000–$12,000 |
| 2 | Mapme | Selectable live-world basemap for tourism, events, campuses and property storytelling. | $12,000–$50,000 |
| 3 | CampusTours | Live campus exterior view alongside existing tours and approved map artwork. | $15,000–$60,000 |
| 4 | Racemap | Optional spectator presentation, not replacement of safety tracking/Safemap. | $10,000–$40,000 |
| 5 | DevSutes | Premium live farm/maze exterior, seasonal appearance and visitor view. | $2,000–$8,000 |
| 6 | Hereday | Opt-in paid 3D event overview without changing planning/volunteer workflow. | $1,000–$5,000 |
| 7 | EventDiagram | Outdoor venue context, sun/time and weather around its existing event objects. | $3,000–$12,000 |
| 8 | OnePlan | Optional live surrounding-world layer and public event visitor map. | $25,000–$100,000 |
| 9 | Concept3D | Premium live exterior mode retaining institution-approved custom models and CMS. | $30,000–$120,000 |
| 10 | cmBuilder | Optional clean site surroundings/public presentation layer, retaining surveyed terrain and BIM. | $25,000–$100,000 |
| 11 | RaceJoy | Premium spectator/event-village mode beside the existing operational map. | $20,000–$75,000 |
| 12 | Shadowmap | Display-only Style B mode, or reciprocal sun-data/engine partnership. | $10,000–$40,000 |
| 13 | Felt | Customer-requested optional 3D storytelling connector, not replacement of GIS renderer. | $25,000–$100,000 |

Annual figures are negotiating envelopes for limited, defined portfolios, **not forecast revenue or known budgets**. A minimum is credited against the applicable usage/unit fees. Per-unit, portfolio and revenue-share options are alternatives unless a contract explicitly combines them. A low-volume prospect could reasonably reject any minimum.

## Incumbent cost benchmarks
List-price scenarios, USD/month, checked 7 October 2026; marginal bands applied:
| ID | Meter | 100,000 units/month | 1,000,000 units/month |
|---|---|---:|---:|
| A | Mapbox web GL JS map loads | $250 | $3,050 |
| B | Google Dynamic Maps loads | $630 | $4,970 |
| C | Google Photorealistic 3D Tiles root queries | $594 | $4,734 |
| D | Mapbox native maps MAU | $300 | $2,600 |

A: first 50k free; paid bands $5/$4/$3 per thousand through 1M. D: first 25k free; subsequent bands $4/$3.20/$2.40. Mapbox tile, routing and other API meters differ. MapLibre users should not automatically be costed as GL JS users. [Mapbox pricing](https://www.mapbox.com/pricing).

B: first 10k free; bands $7/$5.60/$4.20. C: first 1k free; bands $6/$5.10/$4.20. Google's native Maps SDK and Embed SKUs have unlimited free usage; other services remain separately metered. [Google price list](https://developers.google.com/maps/billing-and-pricing/pricing).

C bills a root session, valid up to three hours, rather than each child tile; one page opening is only an illustrative session assumption. Default daily root quotas can require increases for million-query monthly volume. [Tile billing and quotas](https://developers.google.com/maps/documentation/tile/usage-and-billing).

For example, A at 1M is 50×5 + 100×4 + 800×3 = $3,050. C at 1M is 99×6 + 400×5.10 + 500×4.20 = $4,734. These compare different products and meters. They exclude geocoding, routing, weather, hosting, model preparation, tax, contractual discounts and support. **They do not reveal any prospect's actual bill.** Native Google SDK zero base-map cost makes a pure cost-saving pitch particularly weak for RaceJoy.

## Common switch and contract requirements
These are proposed requirements for WorldEngine, not verified customer procurement checklists:
1. **Developer surface:** versioned JavaScript SDK and embeddable viewer; camera, picking, route/polyline, marker and time/weather controls; documented scene schemas and callbacks. Rendering layers must accept customer overlays without forcing a new editor.
2. **Data compatibility:** stable feature identifiers, WGS84 plus explicit local-coordinate and vertical-datum transforms; customer-owned buildings/site geometry; API import and update paths. Small errors in elevations can invalidate engineering layouts.
3. **Coverage:** list supported regions, terrain/building completeness, source update age and the behavior outside coverage. Custom campus/farm/site assets remain recognizable and privately controlled. Global coverage cannot be inferred from WorldEngine's Denver/Chicago work.
4. **Distribution:** cross-browser support, Android as well as iPhone viewing, origin-restricted embeds, accessible text/2D alternatives and graceful weak-network behavior. Native iOS/Android SDKs become necessary for true replacement inside RaceJoy; most other prospects can start with the browser.
5. **Reliability:** the per-prospect availability percentages below are proposed negotiating targets. At 30 days, 99.9% permits 43.2 minutes and 99.95% 21.6 minutes of downtime before exclusions. Specify the measurement boundary, credits, planned maintenance, event support, CDN failover and capacity limits. A monthly SLA alone does not make race-day downtime acceptable.
6. **Weather/clock semantics:** timestamp and label observed versus forecast weather; allow fixed event-date previews; show stale-data status; never present decorative weather as a site-safety or sunlight-analysis result. Weather provider redistribution/display rights and costs need their own coverage.
7. **OEM commercial terms:** explicit resale/sublicensing and white-label rights; defined session/active-site meters and included quotas; annual cap/burst allowance; no charge per animation frame, marker update or passive CMS record. Separate custom model onboarding from runtime fees. Revenue share must specify attributable premium revenue, refunds, reporting and minimums.
8. **Operating economics:** every price hypothesis requires a margin check against actual geometry/CDN/weather/compute consumption and support. Prices here intentionally do not pretend those costs or negotiated contracts are known.

## Source-rights traps
Google's terms restrict extracting, caching and creating content based on Google Maps content except where specifically permitted. Do not assume a license to view Google 3D Tiles lets WorldEngine convert that mesh into a stylized asset library. Preserve required attribution and get counsel to review the exact service-specific integration. [Google terms](https://cloud.google.com/maps-platform/terms).

Mapbox pricing includes commercial application licensing considerations for some business uses. Account/API access does not automatically grant OEM resale or unrestricted caching. Obtain the applicable product and contract terms. [Mapbox pricing](https://www.mapbox.com/pricing), [Mapbox terms](https://www.mapbox.com/legal/tos).

Mapme's standard multiple-map offer is not a resale license. Its restrictions concern that subscription; a separately negotiated WorldEngine engine license would need its own OEM terms. [Mapme multiple-map plans](https://mapme.com/pricing-multiple-maps/).

## Individual teardowns

### 1. Terranaut
**Apparent stack.** Mapbox provider/style integration documented; exact browser rendering library/version unverified. Its series offering explicitly accepts the customer's Mapbox style and key. RaceMap Studio is the former name of Terranaut; it is not Racemap's live-tracking service. [Primary reference 1](https://www.terranaut.io/), [Primary reference 2](https://www.racemap.studio/about).

**Visuals today.** Terrain-led 3D course presentation, colored routes, elevation profiles, aid-station markers and sponsor placements. Its own examples show embedded course pages and flyovers. This is already a visual product; Style B would offer a different neighborhood/event-village look, not fix an obviously broken map. Published visual examples: [Primary reference 1](https://www.terranaut.io/examples). The review limitation above applies.

**What a switch needs (inference).** Optional urban course/event-village Style B viewer; preserve mountainous terrain and existing route editor. Web: Iframe plus JavaScript SDK; camera/route animation controls and event callbacks. Mobile: Safari first; native iOS optional, Android browser parity essential. API/data: GPX/KML/GeoJSON ingestion, stable POI IDs, route chainage/elevation, sponsor links and downloadable routes. Coverage: Global race corridors, trails, rural terrain and elevation; Denver/Chicago alone cannot replace it. Proposed availability target: **99.9%**. Pre-event cache warming, event-day burst capacity and instant existing-map fallback.

**Retail anchor.** $599/event/year; published monthly view allowance 30,000; series quoted. [Published pricing/product source](https://www.racemap.studio/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** Per upgraded event-year, or a credited OEM annual minimum; alternative 10–20% of the incremental premium feature's net receipts. $60–120 is roughly 10–20% of $599 retail. It must buy an explicitly capped view allowance, not unlimited traffic. Per-view billing can exceed retail if the full 30k monthly allowance is used year-round. Incumbent comparison: benchmark **A** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Closest fit to a premium branded 3D embed, clear importing workflow and public race pages. Small budgets and global terrain are the main limits.

**Still unverified.** Customer count, traffic, current Mapbox bill, revenue, willingness to switch and WorldEngine global terrain support.

### 2. Mapme
**Apparent stack.** MapLibre browser rendering documented; configurable MapTiler/Esri/Mapbox styles and Google basemaps. Provider and renderer are separate. Its support article names MapLibre and describes compatible Mapbox style versions. Custom-basemap guidance lists providers. MapLibre's sponsorship announcement independently corroborates use. [Primary reference 1](https://mapme.com/support/knowledgebase/how-to-configure-mapbox-styles-for-use-with-mapme/), [Primary reference 2](https://mapme.com/support/knowledgebase/custom-basemap-styles/), [Primary reference 3](https://maplibre.org/news/2024-06-28-mapme-announcement/).

**Visuals today.** Configurable cartographic maps, markers, media panels, category filters, drawings and optional 3D buildings. The example gallery includes campuses, showgrounds, stadiums and property guides. More polished than a bare pin map, but its core is information presentation rather than a weather-lit street scene. Published visual examples: [Primary reference 1](https://mapme.com/interactive-map-examples/), [Primary reference 2](https://viewer.mapme.com/hampton-classic-demo-map). The review limitation above applies.

**What a switch needs (inference).** Selectable live-world basemap for tourism, events, campuses and property storytelling. Web: SDK integrated into existing viewer/editor, plus unchanged iframe and public URLs. Mobile: Phone browser/WebView first; native iOS secondary. API/data: MapLibre layer/coordinate bridge; CSV/Sheets/CMS updates, feature picking, category filters and stable deep links. Coverage: Global places and customer custom sites; first release can be opt-in only where coverage is verified. Proposed availability target: **99.9%**. Accessibility fallback, analytics parity, tenant isolation and origin-restricted embeds.

**Retail anchor.** Annual-billed plans $30/$55/$110 per month equivalent; monthly plans $50/$90/$180. [Published pricing/product source](https://mapme.com/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $5–20 per upgraded published map/month, with a credited $12–50k annual OEM minimum; alternative 5–15% of incremental upgrade receipts. A base $30/month tier cannot absorb a $20 cost unless a separate premium upgrade pays for it. Charge only selected 3D maps; define usage caps and pass-through data costs. Incumbent comparison: benchmark **A (tiles only if Mapbox data is retained; MapLibre itself is not billed as Mapbox GL JS)** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Strong distribution across multiple place-marketing segments and existing provider choices. Larger integration than Terranaut, but a reusable visual option.

**Still unverified.** Active paid maps versus created maps, API partner access, exact data contracts and upgrade demand. Standard multi-map accounts forbid resale; negotiate a separate OEM contract.

### 3. CampusTours
**Apparent stack.** Proprietary AnyMap/AnyTour CMS and graphical-map system; Google walking-directions integration documented. Underlying renderer and 3D data provider unverified. AnyMap supports varied map artwork. July 2025 version 8.0 release documents GoogleMaps walking directions, accessibility and mobile changes; this does not establish Google 3D Tiles or a Google basemap renderer. [Primary reference 1](https://campustours.com/anymap), [Primary reference 2](https://campustours.com/press25-anymap-anytour-8).

**Visuals today.** A mix of campus artwork, vector 3D depictions, satellite/photorealistic presentations, media and panoramic tours. Its AnyTour examples span several aesthetics, so describing all offerings as static or flat would be misleading. A unified live-time campus appearance is the proposed addition. Published visual examples: [Primary reference 1](https://campustours.com/anytour). The review limitation above applies.

**What a switch needs (inference).** Live campus exterior view alongside existing tours and approved map artwork. Web: Embed and SDK retaining campus URLs, tour chapters and CMS controls. Mobile: Mobile Safari first; native app integration only if requested by institution. API/data: Building IDs, parking and accessible routes; existing media/tour metadata; customer models and georeferenced artwork. Coverage: Institutions worldwide; campus-by-campus quality approval, recognizable landmark buildings and maintained closures. Proposed availability target: **99.9%**. Keyboard and screen-reader alternatives, text map-layer descriptions, move-in traffic bursts and stable archival links.

**Retail anchor.** Quote required; no current numeric platform price verified. [Published pricing/product source](https://campustours.com/anymap). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $300–1,500 per premium campus/year; credited portfolio minimum $15–60k/year. Illustrative 20–50 campus portfolio, not a verified installed-base estimate. Artwork/model conversion and maintenance are separately priced; no retail margin can be inferred from a quote-only product. Incumbent comparison: benchmark **B for a retained Google web basemap; provider choice unverified** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Campus storytelling and differentiated graphics fit Style B. Existing artwork and accessibility requirements slow adoption but give it a credible premium use.

**Still unverified.** Renderer, data sources, public pricing, paid installation count, partner appetite and model ownership.

### 4. Racemap
**Apparent stack.** Mapbox basemap/styles documented; proprietary tracking/API layer. Exact GL JS/native rendering implementation unverified. Product pages show Mapbox attribution/styles; URL parameters use Mapbox zoom conventions. API documents cover current athlete positions and GeoJSON geographic elements. [Primary reference 1](https://go.racemap.com/), [Primary reference 2](https://docs.racemap.com/live-tracking/url-parameters), [Primary reference 3](https://docs.racemap.com/api/current), [Primary reference 4](https://docs.racemap.com/api/geo-elements).

**Visuals today.** Route-centric tracking maps with participant markers, elevation/race-flow information and geographic basemap context. The useful visual hierarchy is athlete position and route visibility; cinematic lighting must never obscure either. Published visual examples: [Primary reference 1](https://go.racemap.com/). The review limitation above applies.

**What a switch needs (inference).** Optional spectator presentation, not replacement of safety tracking/Safemap. Web: SDK/embed that accepts batched live marker updates, replay clock and route styling. Mobile: Web first for spectators; existing iOS/Android tracking integrations must remain functional. API/data: GeoJSON, altitude, position timestamps, delay/interpolation metadata, replay and persistent athlete IDs. Coverage: Global race courses including remote terrain and water; modest-city-only coverage rules out a full replacement. Proposed availability target: **99.95%**. Event-window load tests, stale-position labels, failover 2D viewer and low marker-update latency.

**Retail anchor.** €25/map/7-day event plus device and map-load usage charges. [Published pricing/product source](https://go.racemap.com/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** Usage contract $3–8/1,000 premium 3D viewer sessions with credited $10–40k/year minimum; alternative event package priced separately. At 100k premium sessions/month, variable cost is $300–800/month, or $3,600–9,600/year before a higher minimum. Do not charge every tracking device or every marker update. Incumbent comparison: benchmark **A** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Clear live data integration and shareable race viewing; budgets and race-day reliability are harder than for static course previews.

**Still unverified.** Viewer sessions, retention of proprietary tracking controls, Mapbox volume discounts and customer demand.

### 5. DevSutes
**Apparent stack.** Custom farm-map web application; satellite/custom graphic map inputs documented. Basemap provider and renderer unverified. Agritourism pricing distinguishes satellite, supplied-image and custom-graphic plans. Familiar Google/Apple gestures do not prove use of either provider. [Primary reference 1](https://devsutes.com/agritourism/pricing/), [Primary reference 2](https://devsutes.com/agritourism/features/).

**Visuals today.** Property-scale visitor maps using satellite imagery or supplied/commissioned graphics, GPS location and game destinations. Potentially close to an illustrated farm aesthetic. This description comes from vendor product material; the current runtime imagery was not directly inspected. Published visual examples: [Primary reference 1](https://devsutes.com/agritourism/features/). The review limitation above applies.

**What a switch needs (inference).** Premium live farm/maze exterior, seasonal appearance and visitor view. Web: Very small QR-opened mobile embed; keep lightweight 2D fallback. Mobile: Safari/Android browser essential; installing a native app should not be required. API/data: Customer property geometry, georeferenced art, temporary maze paths, attraction statuses and location-dot overlay. Coverage: Individual rural farm sites and customer-defined attractions, not just public road/building data. Proposed availability target: **99.9%**. Weak-network resilience, authorized offline cache, seasonal updates and no misleading maze directions.

**Retail anchor.** $220 satellite/$330 supplied image/$660 custom graphic per year; games add $400/year. [Published pricing/product source](https://devsutes.com/agritourism/pricing/). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $40–120 per upgraded farm/year; credited annual minimum $2–8k. Alternative 10–20% of premium-option receipts. Upper range is viable only on a premium tier, not necessarily the $220 satellite plan. Include a small explicit view allowance; custom site modeling is additional. Incumbent comparison: benchmark **A/B only as external alternatives; actual provider unknown** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Good farm aesthetic/season fit and a manageable private overlay. A small economical deal, not an enterprise revenue anchor.

**Still unverified.** Current runtime, map providers, customer volume, weak-network rendering and margin available for 3D.

### 6. Hereday
**Apparent stack.** Mapbox turn-by-turn routing documented; basemap/renderer unverified. FAQ states that route drawing uses Mapbox routing to follow roads and trails. Routing evidence alone does not identify GL JS, MapLibre, Leaflet or a terrain engine. [Primary reference 1](https://hereday.io/faq).

**Visuals today.** Course-planning presentation with route lines, start/finish, water/sponsor markers, elevation and event information. Homepage image description presents a Crystal Lake 5K loop. A 3D village or route preview could add appeal, but its main value is inexpensive event coordination. Published visual examples: [Primary reference 1](https://hereday.io/), [Primary reference 2](https://hereday.io/getting-started). The review limitation above applies.

**What a switch needs (inference).** Opt-in paid 3D event overview without changing planning/volunteer workflow. Web: Shareable viewer and small SDK integration into existing event page. Mobile: Browser first; native iOS not a prerequisite. API/data: Route/waypoint bridge, elevation, event IDs, POIs and existing forecast handoff. Coverage: Global roads/trails and organizer-drawn event villages. Proposed availability target: **99.9%**. Low download size, clear volunteer routes and fallback on older phones.

**Retail anchor.** Free tier and $49/event offering. [Published pricing/product source](https://hereday.io/). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $5–15 per published 3D event, credited $1–5k annual minimum; or 10–20% of a separate premium add-on's net receipts. A $15 engine cost consumes 31% of the $49 event price before their other costs. This needs premium pricing, a lower wholesale rate or constrained use; never claim obvious willingness to pay. Incumbent comparison: benchmark **A for candidate rendering; routing is separately billed** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Small integration and meaningful event overlay fit, but tight price ceiling makes it a modest prospect.

**Still unverified.** Basemap renderer, event volume, Mapbox routing usage and paid upgrade adoption.

### 7. EventDiagram
**Apparent stack.** Own browser-based 3D scene generated from the same dimensioned event plan; exact graphics library unverified. 3D feature page describes direct plan-to-3D rendering and camera views. Roadmap lists richer materials and outdoor terrain/trees/tents/sky as future work, not all shipped features. [Primary reference 1](https://eventdiagram.com/features/3d-event-diagram/), [Primary reference 2](https://eventdiagram.com/roadmap/).

**Visuals today.** Dimensioned venue layouts and 3D tables, chairs, stages and screens. This is spatial event previsualization rather than a geospatial neighborhood map. Materials/lighting improvements are on its roadmap; visual claims here do not certify current rendering quality. Published visual examples: [Primary reference 1](https://eventdiagram.com/), [Primary reference 2](https://eventdiagram.com/features/3d-event-diagram/). The review limitation above applies.

**What a switch needs (inference).** Outdoor venue context, sun/time and weather around its existing event objects. Web: SDK scene module with shared editing/view state; embed remains compatible. Mobile: Phone web first; roadmap native phone/iPad capability should not be assumed shipped. API/data: Dimensioned object schema, units, camera/picking, georeferenced site origin and persistent seat/table IDs. Coverage: Private lawns, terraces, vineyards and venue terrain with customer geometry. Proposed availability target: **99.9%**. Keep counts, dimensions and sightlines authoritative; customer overlays private; reliable printable 2D plan.

**Retail anchor.** $9 Solo/$18 Pro 3D/$49 Starter Property/$149 Venue per month. [Published pricing/product source](https://eventdiagram.com/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $2–6 per premium workspace/month, or $10–25 per outdoor venue/month; credited $3–12k annual minimum. At $18/month Pro pricing, the upper workspace rate is a large cost share. Outdoor venue plans are a more plausible buyer than all Pro users; indoor 3D is already built. Incumbent comparison: benchmark **A/B for outdoor context only; neither is proven in existing product** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Explicit outdoor roadmap creates a possible build-versus-license opening. Needs a true scene SDK, not just a separate scenic iframe.

**Still unverified.** Graphics runtime, exact scene export/API, outdoor roadmap timing, paid users and procurement budget.

### 8. OnePlan
**Apparent stack.** Esri/ArcGIS, Google and Mapbox map sources documented; custom Venue Twin product. Venue Twin graphics runtime unverified. Maps page names all three providers. Support lists Google Street/Satellite and three Mapbox canvases. Venue Twin combines venue 3D and plans; no primary evidence here establishes Cesium/Unity/Unreal. [Primary reference 1](https://www.oneplan.io/maps/), [Primary reference 2](https://support.oneplan.io/using-different-map-canvases-in-oneplan), [Primary reference 3](https://www.oneplan.io/features-old/venue-twin/).

**Visuals today.** Operational objects over cartographic or satellite canvases, alongside detailed venue-twin presentations. Style B is a possible surrounding context/visitor presentation, not automatically better than a photorealistic venue twin for operational review. Published visual examples: [Primary reference 1](https://www.oneplan.io/maps/), [Primary reference 2](https://www.oneplan.io/features-old/venue-twin/). The review limitation above applies.

**What a switch needs (inference).** Optional live surrounding-world layer and public event visitor map. Web: SDK integrated with existing object tools, plan layers and controlled shared links. Mobile: Web/tablet authoring and phone viewing; native iOS secondary. API/data: Object catalogue IDs, local CAD coordinates, WGS84 transform, measurements, terrain clipping and plan export. Coverage: Global venues plus exact customer-supplied site/CAD data. Proposed availability target: **99.95%**. Dedicated support, authoritative operation layers, coordinate regression checks and public/private separation.

**Retail anchor.** Pro $99/month or $984/year; Team $90/seat/month or $900/seat/year; enterprise quoted. [Published pricing/product source](https://www.oneplan.io/pricing/). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $25–100 per premium site/month or $25–100k annual defined-portfolio license; alternatives, not additive. Higher price justified only for a paid module/customer use, not every low-tier seat. Existing multiple providers lower conceptual switching friction but not object/model integration cost. Incumbent comparison: benchmark **A/B/C depending on retained provider** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Potential deal size and mature workflows; deeper integration and an existing 3D product weaken early sales speed.

**Still unverified.** Venue Twin renderer, supplier rights, partner API availability, active site counts and actual provider bills.

### 9. Concept3D
**Apparent stack.** Custom campus renderings over OSM or Google map tiles documented; current live 3D runtime and geometry provider unverified. Map-platform overview describes base tiles under custom renderings. Update documentation explains rendering/model changes. Q1 2026 release adds 2D/3D/360 basemap toggles; this alone does not prove Google 3D Tiles or Cesium. [Primary reference 1](https://help.concept3d.com/hc/en-us/articles/360017771254-Concept3D-Map-Platform-Overview), [Primary reference 2](https://help.concept3d.com/hc/en-us/articles/360001865534-How-Do-I-Make-Map-Updates), [Primary reference 3](https://help.concept3d.com/hc/en-us/articles/48374183587603-2026-Q1-Interactive-Map-Release-Notes).

**Visuals today.** Bespoke campus renderings, POI/category navigation and linked panoramic experiences. Already sells a polished, branded place representation. Live weather/time is a potential extension; generic procedurally modeled houses would not replace recognizable campus architecture. Published visual examples: [Primary reference 1](https://concept3d.com/concept3d-vs-google-maps/). The review limitation above applies.

**What a switch needs (inference).** Premium live exterior mode retaining institution-approved custom models and CMS. Web: Hosted embed/SDK with current deep links, navigation and authenticated institution controls. Mobile: Responsive web first; native integration optional. API/data: Building/POI IDs, existing model and media assets, closures/routes, CMS updates and camera state. Coverage: Maintained customer campuses globally; landmark fidelity and licensed custom geometry required. Proposed availability target: **99.95%**. WCAG-compatible text/route alternatives, SSO where applicable, institutional support and backward-compatible URLs.

**Retail anchor.** Interactive map plans are quote-only. [Published pricing/product source](https://concept3d.com/interactive-virtual-experiences/pricing/). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $500–2,000 per premium campus/year or $30–120k annual portfolio license. Retail is unknown; this is an OEM price hypothesis, not a measured percentage of their subscriptions. Existing artwork conversion/model upkeep is separate. Incumbent comparison: benchmark **B for Google tile deployments; OSM data does not establish hosting cost** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Relevant distribution and potential higher budgets, but their visual product is core differentiation and replacement carries considerable migration cost.

**Still unverified.** Live renderer versus rendered artwork by deployment, installed paid campuses, contractual model rights and switching appetite.

### 10. cmBuilder
**Apparent stack.** Mapbox terrain/flat maps and Google 3D Tiles explicitly documented; own construction scene tools, graphics runtime unverified. August 2026 support names both sources and warns that switching changes scenario elevations. September 2026 display guidance distinguishes textured satellite/cartographic maps, surrounding massings and extended Google context. [Primary reference 1](https://support.cmbuilder.io/hc/en-us/articles/15373918808859-0-4-Update-Map-Data), [Primary reference 2](https://support.cmbuilder.io/hc/en-us/articles/15339756676251-0-2-1-Display-Settings).

**Visuals today.** Engineering site scenes with BIM/resources/excavations and either white surrounding building masses or Google photorealistic context. This is already 3D/4D. WorldEngine could supply a clearer contextual presentation, but exact site geometry matters more than attractive neighborhood scenery. Published visual examples: [Primary reference 1](https://www.cmbuilder.io/), [Primary reference 2](https://support.cmbuilder.io/hc/en-us/articles/15339756676251-0-2-1-Display-Settings). The review limitation above applies.

**What a switch needs (inference).** Optional clean site surroundings/public presentation layer, retaining surveyed terrain and BIM. Web: SDK embedded in existing scene/presentation; do not replace construction simulation. Mobile: Desktop/tablet authoring and smartphone viewing; native iOS not primary. API/data: Local origin/vertical datum/UTM transforms, clipping, exact BIM/scan overlays, 4D schedule and picking. Coverage: Global construction sites, including custom survey terrain beyond map-provider coverage. Proposed availability target: **99.95%**. Regional hosting/SSO requirements, geometry/elevation compatibility, export rights and enterprise support.

**Retail anchor.** Standard $416/month and Premium $816/month, billed annually, each including five active projects; enterprise quoted. [Published pricing/product source](https://www.cmbuilder.io/). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $20–75 per upgraded active project/month; credited $25–100k annual OEM license. Five projects imply $100–375/month engine expense, substantial against $416 Standard. Needs an additional paid presentation tier or volume discount; don't imply savings against Google without traffic. Incumbent comparison: benchmark **A/C; both provider integrations verified** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Budget and existing source integration are promising, but they've already solved 3D and exact elevation migration is expensive. Style B may be a niche presentation mode.

**Still unverified.** Runtime, provider volumes/discounts, rights to derived geometry, demand for stylized surroundings and integration effort.

### 11. RaceJoy
**Apparent stack.** Google native maps documented in a 2024 RunSignup presentation; current 2026 native map library/version unverified. RunSignup's 2024 roadshow material describes native Google maps on Apple/Android phones. Current RaceJoy pages document GPS tracking, course creation and timer workflows; do not infer current stack solely from a historical deck. [Primary reference 1](https://info.runsignup.com/wp-content/uploads/sites/3/2024/05/Presentation.2024-05-29.RunSignup-Roadshow-Pittsburgh-compressed.pdf), [Primary reference 2](https://www.racejoy.net/raceadmin).

**Visuals today.** GPS race tracking with course maps, participant location, progress and spectator functions. Current publisher app-store screenshots are linked for review; this research did not directly inspect their pixels. A dramatic 3D course scene is secondary to a readable, dependable tracker. Published visual examples: [Primary reference 1](https://play.google.com/store/apps/details?hl=en&id=com.racejoy.racejoy), [Primary reference 2](https://www.racejoy.net/raceadmin). The review limitation above applies.

**What a switch needs (inference).** Premium spectator/event-village mode beside the existing operational map. Web: Spectator embed useful; native viewer SDK needed for a genuine in-app switch. Mobile: Native iOS AND Android integration essential for replacement; background GPS/battery handling unchanged. API/data: Live positions/progress/route IDs, replay, MeetUp/spectator interactions and certified timer setup. Coverage: All supported race areas and routes, including remote terrain; fallback where 3D coverage fails. Proposed availability target: **99.95%**. Race-day escalation and burst capacity; stale GPS indicators; native crash/battery tests; 2D fallback.

**Retail anchor.** Event tiers $750/$1,500/$2,500/$5,000/$7,500 by participation band; includes broader race services. [Published pricing/product source](https://www.racejoy.net/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $0.005–0.02 per premium active 3D viewer per event, credited $20–75k annual minimum. At 100k qualifying viewer-events/month, $500–2,000/month variable cost. Broader race package retail is not renderer budget; Google native base Maps SDK SKU has no usage charge. Incumbent comparison: benchmark **D** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** High potential distribution but native cross-platform integration, operational risk and a free incumbent base-map SKU make it a difficult first license.

**Still unverified.** Current stack, native SDK integration cost, viewer counts and willingness to charge a premium.

### 12. Shadowmap
**Apparent stack.** Historical company job posting says engine uses three.js; current runtime unverified. Product lists several terrain providers and Google 3D buildings. Company-authored recruiting PDF names three.js. Current comparison lists Nextzen variants, Mapbox, Esri and Stadia terrain. Studio includes Google 3D buildings; no claim that all geometry is Google-derived. [Primary reference 1](https://www.cg.tuwien.ac.at/sites/default/files/news/9272/Shadowmap%20Job%20Offer%20-%20Senior%203D%20Developer.pdf), [Primary reference 2](https://shadowmap.org/learn/shadow-analysis-tools-comparison), [Primary reference 3](https://shadowmap.org/pricing).

**Visuals today.** Global analytical sun/shadow views, editable buildings/objects and optional Google 3D context. Shadows communicate obstruction and solar access. Softly stylized display geometry could be attractive, but cannot substitute for physically correct occluders in its analysis. Published visual examples: [Primary reference 1](https://shadowmap.org/), [Primary reference 2](https://shadowmap.org/pricing). The review limitation above applies.

**What a switch needs (inference).** Display-only Style B mode, or reciprocal sun-data/engine partnership. Web: Scene SDK plus analytical API bridge; existing analytical renderer retained. Mobile: Web first; iOS integration secondary. API/data: Separate exact occluder geometry, UTC/location/height, solar queries with confidence/update metadata; weather only as separately labeled atmosphere. Coverage: Global sun analysis and supported buildings/terrain; no silent gaps or visual mesh substitutions. Proposed availability target: **99.9%**. Analysis/display version separation, licensed source chain and explicit weather versus geometric shadow semantics.

**Retail anchor.** Studio page displays 60/month or 600/year and additional projects from 25/month; currency symbol not verified in accessible text. [Published pricing/product source](https://shadowmap.org/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $10–40k/year for a limited display module, or 10–20% of attributable display-upgrade receipts; reciprocal API licensing may fit better. They themselves offer a solar API and have an established engine. Treat as a potential complementary supplier/co-seller rather than assume they want to buy a replacement. Incumbent comparison: benchmark **C where Google content retained; other data bills unknown** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Strong visual overlap but weak buy-versus-build case; analysis could be harmed by styling. More plausible partner than early customer.

**Still unverified.** Current graphics runtime, proprietary analysis economics, Google-content rights and desire for an external display layer.

### 13. Felt
**Apparent stack.** MapLibre rendering, Tippecanoe/PMTiles-related tooling and proprietary Felt Style Language documented; not proven Mapbox GL JS billing. Its 2023 engineering article describes migration to MapLibre and translating Felt styles. Current about page names MapLibre and Tippecanoe. Exact current package versions unverified. [Primary reference 1](https://felt.com/blog/maplibre-rendering-engine), [Primary reference 2](https://felt.com/about), [Primary reference 3](https://www.felt.com/open-source).

**Visuals today.** Data-led cartographic/vector/raster mapping with configurable thematic layers, labels and shared analytics. The value is reliable exploration of geographic data, not lifelike houses. Style B could be an optional spatial story view, but may make dense GIS content harder to interpret. Published visual examples: [Primary reference 1](https://felt.com/), [Primary reference 2](https://www.felt.com/compare/mapbox). The review limitation above applies.

**What a switch needs (inference).** Customer-requested optional 3D storytelling connector, not replacement of GIS renderer. Web: Authenticated SDK/embed extension retaining query/picking and existing layer grammar. Mobile: Web plus compatibility with its field/mobile workflows; iOS-only offer insufficient. API/data: Vector/raster layers, projections, FSL semantics, query/SQL/API connections, data permissions and exports. Coverage: Global customer GIS extents, own datasets and regional compliance requirements. Proposed availability target: **99.95%**. Tenant access controls, residency/security, large-layer performance, analytics parity and enterprise support.

**Retail anchor.** Commercial plans quote-based, annual starting team structure described as ten seats/unlimited viewers; Personal free is noncommercial. [Published pricing/product source](https://www.felt.com/pricing). This is their customer-facing offering, not what they spend on mapping.

**Likely deal shape (unverified hypothesis).** $25–100k annual optional enterprise connector; alternative $100–500 per upgraded customer tenant/year. No verified retail dollar price or 3D module demand. An engineering-heavy company on an open renderer needs a specific customer requirement before these ranges are actionable. Incumbent comparison: benchmark **A only for retained Mapbox data services; open renderer license itself is not a GL JS bill** above. Geometry onboarding, special support and weather/data pass-through are outside these illustrative rates unless explicitly included. No evidence of an actual quote or purchase intent.

**Rank rationale.** Least compelling engine buyer: mature rendering team, different visual priorities and heavy GIS integration. Could distribute an extension if customers explicitly require it.

**Still unverified.** 3D product roadmap, paying tenants, partner SDK appetite, actual infrastructure costs and demand.

## How to read the companion CSV
One row per prospect, ranked 1–13. Dollar ranges are numeric USD license hypotheses; retail text retains published currencies and uncertainty. Null unit rates mean no unit price was proposed, not zero/free. All availability targets and switch requirements are authored suggestions. Evidence URLs distinguish stack, visual and retail sources; benchmark IDs refer to the table above. “Visual review status” is deliberately explicit.

This addendum contains no interview script or pilot plan. It changes none of the earlier demand-research files.
