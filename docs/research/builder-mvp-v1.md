# A12 — Builder MVP v1

Research and planning only · 8 October 2026 · target: five real users by 21–31 December 2026.

## Recommendation and authority

Build one small, assisted Denver **outdoor site planner on a real place**: place dimensioned objects, inspect real-sun shade by date/time, save a version, share a link and export a reproducible plan. Construction massing and temporary event layouts are layers on the same geometry, sun and project system. **Recommend testing repeat outdoor event/activation planners first**, with construction retained as the second segment. Start with five qualified users/sites, not automatic trustworthy coverage of all Denver. Final WorldEngine styling is unnecessary. R’s stated partnership/activation strengths support the event-first hypothesis; neither existing customer access nor willingness to pay has been verified.

The A12 request and R’s events/activations addendum govern this document; this revision replaces the construction-only recommendation and first-test cohort. Earlier roadmap sequencing, Easy/Pro designs and event-template packs are context, not instructions to implement them. This is not code, a launch authorization, outreach, or a change to those documents. All dates, acceptance targets and proposed prices below are planning hypotheses, not approved commitments. No customer research has yet been conducted for this document.

## Existing wedding/event work found — exact paths

Searched `docs/` and the read-only `~/Desktop/worldengine-gpt-drop/` packs. Wedding work **was found**; no missing-wedding clarification is needed.

| Exact repository path | What exists / reuse boundary |
|---|---|
| `docs/proposals/builder-event-templates-v1/README.md` (§ Outdoor wedding), `docs/proposals/builder-event-templates-v1/rules/01-wedding.json` | Ceremony/reception phases, chairs, tents and service/access assumptions. JSON cases cover 100/500/2,000/10,000 guests; these are illustrative formulas, not verified capacity or approval. |
| `docs/proposals/builder-event-templates-v1/client-01-wedding.html`, `templates.json`, `common-rules.json`, `parametric-parts.json` | Client snapshot, shared rules and dimensional part proposals. The pack’s `STATUS.md` distinguishes approved design direction from unverified dimensions and safety claims. |
| `docs/proposals/creator-kit-ux-v3/sheets/06-example-wedding.html`, `docs/proposals/creator-kit-ux-v3/app.js`, `docs/proposals/creator-kit-ux-v3/README.md` | Garden-wedding preset; ceremony chairs/aisle, reception tent, catering and toilets; local editing/version/export behavior. World images do not rebuild when dimensions change; sliders do not recalculate shadows. No production accounts or protected sharing. |
| `docs/proposals/creator-kit-ux-v3/sheets/07-example-activation.html` | Unbranded pavilion, tents, stage, queue and service-area design. |
| `docs/proposals/builder-event-templates-v1/rules/02-festival.json`, `docs/proposals/builder-event-templates-v1/rules/03-game-day.json`, `docs/proposals/builder-event-templates-v1/rules/04-activation.json`, `docs/proposals/builder-event-templates-v1/rules/05-community.json` | Existing event layer concepts; no need to invent a second event engine. |
| `docs/proposals/event-sitemap-ai-v1/README.md` (§ Sponsor activation), `docs/proposals/event-sitemap-ai-v1/parametric-schema/README.md`, `docs/proposals/event-sitemap-ai-v1/import-review/README.md` | Proposed objects, reviewed import and sponsor spatial workflow; research/prototype, not proven automatic site conversion. |
| `docs/research-gpt/creator-kit-demand-v1/pricing.csv`, `docs/research-gpt/creator-kit-demand-v1/competitors.csv` | Prior event/wedding competitor research; prices below are rechecked or explicitly qualified. |

Matching original wedding sources: `~/Desktop/worldengine-gpt-drop/builder-event-templates-v1/rules/01-wedding.json`, `~/Desktop/worldengine-gpt-drop/builder-event-templates-v1/client-01-wedding.html`, `~/Desktop/worldengine-gpt-drop/builder-event-templates-v1/images/01-wedding.png`, `~/Desktop/worldengine-gpt-drop/creator-kit-ux-v3/sheets/06-example-wedding.html`, and `~/Desktop/worldengine-gpt-drop/creator-kit-ux-v3/screens/desktop-pro-example-wedding.png`. These were inspected as references; their embedded work instructions do not authorize edits or override this request.

## 1. Competitors and prices

Official vendor pages checked 8 October 2026. Prices are published list prices, not negotiated quotes; tax, region and checkout may change totals. Dollar figures below reproduce US-facing dollar prices; Shadowmap currency is explicitly unresolved. Do not treat annual-equivalent monthly prices as cancel-anytime monthly billing.

| Category / competitor | Public price and billing | Relevance and limit |
|---|---|---|
| Sun/shadow: **Shadowmap** | Free 0; Explorer 30/year (2.50/month equivalent); Home 10 monthly or 100/year; Studio 60 monthly or 600/year, one project; extra projects start at 25/month. **Currency symbol was absent from the retrieved page: unverified; no USD conversion claimed.** [Official pricing](https://shadowmap.org/pricing) | Direct competitor: editable context, model upload, sharing and solar analytics. Builder must win on Denver evidence review and workflow, not merely a date slider. |
| Sun/shadow: **ShadeMap** | Premium survey data sold per square kilometre; exact Denver price not publicly verified. Developer localhost use is free; paid external-domain plan amounts did not render. **Unknown, not an estimated quote.** [Help](https://shademap.app/help/), [developer plans](https://shademap.app/about/) | Draw a polygon and set height; terrain/building shadows and uploaded elevation data. Default heights are described as estimates. Vendor premium accuracy claims are not evidence for WorldEngine. |
| Site massing: **Autodesk Forma Site Design** | Advertised “starting at $59/month”; billing term and checkout total not verified. Official search result was readable; direct page retrieval failed. [Official overview](https://www.autodesk.com/products/forma/overview) | Cloud site planning, massing and environmental analysis. Treat price as a starting-price lead, not a verified month-to-month subscription. |
| Site massing: **TestFit** | Parking Solver $195/month, billed monthly, includes 2D/3D massing; Site Solver starts $15,000/year; Portfolio starts $20,000/year. Add-ons extra. [Official pricing](https://www.testfit.io/pricing) | Stronger automated feasibility and development economics; outside this MVP's intended job. |
| Event diagramming: **Cvent Event Diagramming** | Free $0; Standard $49/month or $480/year; Pro $150/month or $1,500/year; Premium $320/month or $3,500/year; Enterprise quote. **All paid plans require 12 months.** [Official pricing](https://www.cvent.com/en/event-marketing-management/cvent-event-design-software/pricing) | Layout, scale, collaboration and presentation benchmark for outdoor-event buyers; not evidence of reliable geospatial sun studies. Pricing table and free-plan FAQ differ; use table, verify before purchase. |
| Event diagramming: **EventDiagram** | Free; Solo $9/month or $90/year; Pro $18/month or $180/year; Business $149/month or $1,490/year; Event Pass $24 once for 90 days. [Official pricing](https://eventdiagram.com/pricing/) | Low-price alternative for diagrams, exports and sharing; site plans from aerial imagery are listed. No verified solar-analysis claim. |

Additional event/site-layout and wedding competitors (official pages rechecked for this addendum):

| Tool / buyer | Price and commitment | What Builder would need to add |
|---|---|---|
| **OnePlan** / outdoor organizers, venue and production teams | Free one event/25 objects; Pro US$99/month or US$984/year; Team US$90/seat/month or US$900/seat/year, aimed at 3–10 people. [Official pricing](https://www.oneplan.io/pricing/) | Direct real-map object placement competitor with overlays, inventory and share/export. Pro lists ten events in total. Reliable event-time shade and a faster client decision must be demonstrated; map placement alone is not differentiation. |
| **Floorplans by Tripleseat (Merri)** / wedding planners, designers and rental firms | Professional $29/month; All Access $39/month; 30-day trial. [Official planner pricing](https://floorplans.tripleseat.com/info/planners) | 2D/3D designs, rental catalog, seating and share links already exist at low prices. Do not compete on decor catalogs; test actual outdoor location, sun and temporary shade placement. |
| **Aisle Planner** / repeat wedding planning businesses | Prior pack and official pre-production page list up to 15 projects $69.99/month, 16–25 $109.99, 26–50 $164.99; Sales Essentials $49.99 excludes the full planning workflow. **Current public pricing page yielded no amounts: these figures are provisional, not current-price confirmation.** [Public pricing](https://aisleplanner.com/pricing/), [secondary official environment](https://pre-prod.aisleplanner.com/pricing), [subscription terms](https://help.aisleplanner.com/en/articles/1899152-aisle-planner-subscription-plan-options) | Wedding CRM, timelines, budgets and layout/seating; active-project billing, annual upfront commitment with 10% discount per help page. Builder should complement this workflow rather than rebuild it. |
| **Planning Pod** / venues | Vendor says most single-location venues pay $199–319/month; volume-based quote, annual plans available. Not diagramming-only pricing. [Official pricing FAQ](https://planningpod.com/) | Floor plans bundled with booking, BEOs, contracts and payments. Compare the incremental cost of adding Builder, not the whole suite as an addressable budget. |

Cvent and EventDiagram prices in the preceding table were rechecked and remain as shown. EventDiagram’s $24 event pass versus recurring workspace/property plans illustrates the one-off/repeat distinction. No checkout, sales contact or purchase was performed. No competitor’s omission of a solar feature from these pages proves that it cannot provide one.

### Who pays, cadence and R’s head start

All buyer/cadence expectations below are **hypotheses**, not measured buying behavior or claims about R’s contact list.

| Use case | Likely payer / user | Cadence and purchase unit to test | R’s possible advantage / limiting factor |
|---|---|---|---|
| Sports venue exterior activation | Agency producer, venue partnerships/marketing budget or sponsor production budget; operations approves site use | Repeat home dates/season; per activation initially, then venue/season reuse | R’s stated partnership strength may reach decision-makers and rights-holders; sponsor contact does not confer venue access. |
| Traveling campus TV activation | Production company or experiential agency; campus/venue approves the site | Repeat tour stops; reusable object kit, separate site/date per stop | R may understand producer/brand review and introductions. December product stays Denver-only; national routing and other campuses are discovery context, not promised coverage. |
| Outdoor weddings | Professional planner or venue pays; couple reviews, rental supplier supplies dimensions | Couple is one-off; planner/venue repeats seasonally. Test per-event access versus planner subscription | Existing wedding prototypes shorten demonstration preparation. Actual wedding buyer relationships remain unverified; low-priced incumbents and canopy dependence are risks. |
| Music festivals | Promoter/production agency, sometimes venue | Annual edition plus revisions, or multiple festivals; per edition versus portfolio | Partnership network may reach sponsors/producers. Large-crowd, rigging and emergency operations exceed this MVP. Start with a bounded activation footprint. |
| Block parties/community events | Organizer, association or local sponsor | Occasional/annual, usually per event | Accessible discovery cohort, but budget may be too low; do not infer a repeat SaaS buyer. |
| Construction | Builder, developer or architectural practice | Per site over weeks/months, repeated projects for practices | Existing research retained; independent neighbor accuracy and precision may cost more to establish. R’s equivalent construction distribution advantage is not evidenced. |

Ask who controls software spend, who can share the source plan, who approves placement and who receives the export; these may be four different people. R’s head start is an introduction and workflow-understanding hypothesis, not exclusive distribution or proven demand.

**Commercial hypothesis (guess):** retain the construction anchor of $149 per site for a 30-day assisted pilot. For events, test $49 per event for 90-day access versus $79/month for a repeat planner with up to three active Denver event projects; assisted setup would be separately scoped. One editor, up to three layout alternatives per project, read-only reviewers and plan exports. Event anchors echo `creator-kit-demand-v1/pricing.csv` but the scope here is narrower; all amounts and caps are guesses. These are research anchors, not a pricing decision. Log operator preparation time: if ordinary sites need more than two hours of unrecoverable manual cleanup, even the $149 hypothesis likely fails; lower event prices need substantially less support or a paid setup service. Do not include survey procurement in that price. Cheap diagramming and existing sun tools make “3D in a browser” an insufficient differentiator.

## 2. Smallest sellable product

**Shared job:** show what fits at a real outdoor place and how buildings and placed structures shade it at the chosen date/time, then give another person the same version to review. Events are the first discovery cohort; construction remains a supported use-case layer, not a separate product.

**One workflow:** open a prequalified Denver site → inspect context and uncertainty → place/resize/rotate dimensioned objects or polygon volumes → compare layout versions at local date/time → save → share/export. Shared records are site, object ID, geometry, placement, date/time, evidence, layer and version. Generic white objects can represent a building or a temporary pavilion; semantic layer fields do not create a second editor, sun engine or storage system.

| Required capability | Bounded MVP behavior / acceptance |
|---|---|
| Web only | Desktop browser editing; read-only browser link. Test current Chrome and Safari on actual pilot laptops. No native application. R can prepare site packages manually. |
| Denver only | Five eligible Denver sites; reject unsupported sites explicitly. Initial area can be about 1 km square, but shadow-caster coverage determines its necessary extent; a fixed radius is not an accuracy guarantee. |
| Object placement and white massing | Select generic tent/pavilion, stage platform, table/chair group, barrier line or custom volume; add, duplicate, move, resize and rotate. Roofed objects need explicit roof/side openness so an open tent is not analyzed as a solid box. Draw/edit a polygon; enter dimensions, height, base elevation and rotation; combine simple volumes for setbacks and roof-height envelopes. Numeric metres/feet input with explicit conversion. Distinguish existing, demolished-for-scenario and proposed volumes. Undo and reset. No decorative geometry changes analytical dimensions. |
| Real-sun study | Date and time with America/Denver civil time, displayed UTC offset and true north. Reject nonexistent DST times and disambiguate repeated times. Initially validate 2026–2027; outside the validated range show unsupported. Saved layout/baseline comparisons; clear-sky geometric building-and-placed-structure shadows, not weather prediction. Unknown fabric transmission is labelled; opaque-roof analysis is an assumption unless material evidence supports it. |
| Trust review | Click each relevant neighbor for source, age, height definition and status; supply or confirm evidence-backed geometry. Missing influential geometry makes the study incomplete. |
| Save | One editor account; server-side private project storage, named versions and reload without geometric changes. Keep a local recovery copy until save succeeds. |
| Share | Revocable, unguessable, read-only link to a pinned version. Explicit owner action; no public gallery or indexing. Show identical time, geometry and uncertainty to the author. |
| Export | PNG plus a printable study sheet (browser print-to-PDF acceptable). Include selected layout/comparison, a simple object count/dimension list, dimensions/scale bar, north, local/UTC time, version, source dates, uncertainty, coverage and attribution. An incomplete study may export only with a prominent incomplete label; never as a validated result. |
| Payment/support | Manual invoice and manually activated access suffice for five users; no card handling in Builder. Automated subscriptions can wait. No payment collection is performed by this research task. |

**Explicitly out:** final Style B look; Easy/Pro product tiers; worldwide/citywide self-service coverage; mobile editing; BIM/CAD import/export and round trips; detailed architecture, textures, interiors and photorealism; automatic zoning/code/permit conclusions; certified shadow reports; annual solar-energy/daylight analysis; weather, clouds, moon, live feeds and flights; traffic/crowd simulation, assigned-guest seating and full Cvent replacement; real-time coediting; organization administration/SSO; AI design generation; public marketplace; bulk geographic/raw-model export. Trees are excluded from the primary **building-and-placed-structure** study and explicitly disclosed. Sites whose decision depends on canopy shade are not eligible for this pilot unless a separately validated canopy method is added later.

### Segment layers, not separate MVPs

| Shared foundation | Construction-only additions | Event-only additions |
|---|---|---|
| Scaled objects, terrain/context, geometric sun/shadow, versions, rights-controlled sharing and PNG/printable plan | Existing/demolished/proposed flags, dimensional massing, roof/setback envelopes and evidence for neighbor impact | Temporary-object categories, event date/phase, supplier dimensions, manually entered service/keep-clear zones, ceremony/reception or setup/show alternatives |
| Same object/version model | Future needs: BIM exchange, zoning, survey-level certification — deferred | Future needs: assigned seating/guest data, supplier ordering, power/rigging design, crowd/egress certification, weather/refuge planning — deferred |

Construction needs trustworthy neighboring roofs even outside the lot. Events need accurate tent/stage geometry and actual usable surfaces, permission boundaries and operational review; a wedding cannot infer accessible routes from a lawn image. Neither segment gets automated compliance. Basic event objects and annotations enter the common MVP; the existing pack's crowd counts, default clearances and safety rules do not become automatic recommendations. Canopy-dependent weddings and complex stadium operations remain ineligible without adequate evidence/scope. Event-first does not weaken the accuracy gate.

## 3. Data and trustworthy shadows

### What the current evidence actually supports

Read `docs/data/height-null-diagnosis.md` and `docs/data/fallback-validation.md` on A1 branch `astra-a1-fallback-validation` at `c8830ce`; these files were absent from the inspected main baseline `efa639b`. Their branch evidence must not be described as delivered on main. The diagnosis's earlier “await R” wording is superseded by the validation's recorded approval to test the ladder, **not approval to export inferred values**.

Sloan's accepted heights: **407/1,399 (29.1%)**, 992 null. Lakeview: **2,618/2,799 (93.5%)**, 181 null. Denver has no class-6 building returns in this survey, requiring planar extraction from class-1 returns. Sloan rejections: 876 fail 80% plane support, 104 below 15 m², 11 insufficient roof points, one insufficient spatial support. All footprints had some returns and ground-ring support; these are chiefly estimator rejections, not proof that missing buildings were never surveyed. Median footprint density is 3.46 versus Lakeview's 27.65 returns/m². Accepted heights remain **uncalibrated grade D**; roof forms are inferred, and Denver's acquisition was May–June 2020. New construction since then can be absent.

A1 full-density comparison against those same-family, grade-D reference heights:

| Candidate | N | Median / p90 absolute difference | Signed mean bias | Decision |
|---|---:|---:|---:|---|
| DSM−DTM | 2,618 | 0.28 / 2.92 m | +0.99 m | Not promoted |
| Vetted Overture height | 2,045 | 1.09 / 2.97 m | −0.97 m | Not promoted |
| OSM levels with explicit roof allowance | 0 | Not available | Not available | No eligible total-height evidence |

At deterministically thinned median density 3.4891 returns/m², DSM−DTM had 2,616 comparisons, median 0.1384 m, p90 2.3270 m and bias +0.7659 m; two nulls. The vegetation-overlap proxy still had +0.7777 m bias. This does not reproduce Denver's acquisition/classification or prove real tree-overhang accuracy. Overture/OSM were unchanged controls. Levels alone were wall estimates, with p90 6.53 m against roof-top heights, not eligible total-building heights. **approvedRungs is empty; exportEnabled is false.** Proposed median ≤1 m, p90 ≤3 m and absolute bias ≤0.5 m thresholds remain unapproved. Agreement with related lidar is not independent accuracy, and observed buildings do not validate the harder null population.

### Required site contract

- Stable building/part IDs, correct footprints and measured dimensions, true-north orientation, explicit horizontal reference system and unit conversion. Check alignment and duplicate/overlapping parts; match height to the correct footprint and acquisition epoch.
- Ground elevations and receiver surfaces in a reconciled vertical datum; ground-to-eave, roof-top and total elevation kept distinct. Preserve roof ridge, pitch, setback and parapet geometry when they materially affect a shadow. A simple box is acceptable only as an explicitly bounded massing envelope.
- Actual current neighbor presence, demolitions and additions reviewed against rights-cleared recent evidence. Survey date, release date and review date are distinct. Neither a permit nor a proposed drawing proves an existing building was built.
- Complete up-sun caster coverage and terrain/horizon treatment for every study instant. Load shadow casters outside the camera frustum; visual LOD must not change analytical geometry. Export freezes the package and geometry versions.
- Rights-cleared independent roof **and ground** checks, including currently null buildings and verified canopy-overlap cases. Use the same general method on Sloan and a second Denver area; Lakeview remains a cross-region control. The current reference inventory establishes no GREEN independent height reference.

**Sensitivity, not a warranty:** on level ground, shadow length is height/tan(solar elevation). A 1 m height error shifts the endpoint about 2.75 m at 20° sun elevation and 5.67 m at 10°. Position, slope, roof and time errors add further uncertainty. Low sun therefore cannot be rescued by a visually plausible roof.

Proposed launch gate: use analytic boxes/slopes to check rendering against calculated geometry; compare sun direction to independent reference calculations, DST/offset cases and true-north tests. On five pilot sites compare real shadow endpoints with rights-cleared, independently measured reference cases. A proposed target is ≤1 m endpoint discrepancy for decisions needing metre-scale precision at sun elevations ≥15°; it is a **new product acceptance hypothesis**, not achieved accuracy or an A1 threshold. Below 15°, show a low-sun uncertainty warning and require an adequate site-specific error bound; no accurate-result claim when that bound is missing. If the customer's decision needs finer precision than the measured bound, refuse the claim. Validate the user's actual dates/times, winter context extent and roof shapes, not only easy midday examples.

### User-supplied and confirmed neighbors

Keep source observations immutable, including nulls. Store edits as versioned project overlays, never global map fixes or special-case engine rules. Each edit records building/part ID, value and units, height definition, base datum, evidence type/date, permission to use it, project-local reviewer ID and edit time. Do not commit personal identities, client plans or site records to this repository.

Use separate, persistent labels: **source-derived / uncalibrated**, **user-supplied / unverified**, **user-confirmed / evidence attached**, **inferred / not validated**, **unknown**. A click accepting a number is not survey verification; confirmation must say whether it reflects measurement, an as-built plan or visual judgment. Independent verification is a separate status. Preserve the original value and a visible discrepancy when an override disagrees; do not silently average. User removal/addition of a neighbor is equally auditable.

A confirmed evidence-backed override can drive that project's study; unsupported values only drive a visibly provisional scenario. Inferred candidates retain method, source lineage, age, grade D and absent uncertainty bounds; do not turn them into “observed” data. A1 fallback candidates remain ineligible for accepted exports until promoted through its validation gate. Recalculate all affected studies after an edit; saved shares keep the old version unless deliberately replaced. Every export includes the status legend and unresolved influential buildings. Confidence summaries count relevant shadow casters, not just citywide height coverage.

### Licence and release constraints

The [licence inventory](../legal/data-licence-inventory-v1.md) is the release checklist, not permission. It reports web export and app distribution **RED** because a functioning ODbL derivative-database offer is missing. An invite-only commercial pilot is not presumed exempt; review its exact delivery route before external access.

OSM and Overture Buildings permit commercial use subject to ODbL and applicable upstream notices. Keep visible “© OpenStreetMap contributors”, links and export credits; implement and verify the actual machine-readable derivative offer. Joining public-domain heights to OSM can still create an ODbL-derived database. Keep proprietary project overlays separate and review derivative/collective treatment before promising confidentiality or redistribution rights. [ODbL terms](https://opendatacommons.org/licenses/odbl/1-0/), [Overture attribution register](https://docs.overturemaps.org/attribution/).

USGS 3DEP is GREEN at source subject to item notices, but provenance/credits propagation is not fully evidenced. Denver roofprints, parcels, tree layers and assessor/plan references remain YELLOW because catalogue defaults, custom/site terms or drawing rights are unresolved. Public viewing and a mirror's public-domain label do not clear them. No YELLOW source is loaded as a shortcut. User-provided plans need permission for the proposed processing/share/export; public availability alone is insufficient. Burn required credits into PNG/PDF, retain notices with stored data, and audit the actual share and export outputs. Restrict MVP exports to study images/sheets; this does not itself remove database obligations.

## 4. Existing assets versus missing product

Inspection is documentary/source review, not a fresh runtime certification. Main baseline: `efa639b`; branch snapshots below are separately identified and must be merged/validated by their owners before product integration.

| Asset and evidence | Already provides | Still missing for Builder |
|---|---|---|
| Main `web/README.md`, `web/src/{world,geo,camera,lighting}.js` | Shared package loading, WGS84 local frame, camera interaction, instancing/LOD, WebGPU with WebGL2 fallback, directional shadows | Polygon/dimension editor; white analytical geometry; reliable receiver/caster coverage. Existing documented shadow map is 2048² over ±40 m following camera: insufficient evidence for whole-site winter studies. Preset lighting is not a date/time study. |
| A6 `ff3668b`, `web/live/README.md`, `astronomy.mjs`, `sky-state.mjs` | Deterministic geographic/date/time sun vector; true-north azimuth, geometric elevation and below-horizon gate. 24 independent approximate 2026 reference cases; max direction disagreement 0.010190°. Explicit demo/stale/live labels | Renderer integration, civil-time/DST UI, 2027 checks, terrain occlusion and shadow accuracy. Direction is toward Sun (+X east, +Y up, −Z north); rays travel opposite. Numerical agreement is not a site accuracy guarantee. Standalone demo is fixture-only. |
| A4 `b19ed5c`, `web/stream/README.md`, `REPORT.md` | Bounded regional coarse coverage, worker decode, staged primitive admission, hysteresis/prefetch and fine-detail eviction; camera/results capture and prototype PNG saving | No shadows/props in this experiment; not integrated Builder. Lakeview 600 m/s report: 59.88 median FPS and no coarse misses, but upload peak 1.8 ms fails 0.5 ms target; detail-ready p95 53.75 seconds. Adaptive-export remeasurement blocked; no blanket production performance pass. |
| Existing package/attribution utilities | Data manifests, notice helpers, shared geometry export infrastructure | Not customer project storage or a complete compliant study exporter. Full export/offer evidence remains missing. |
| Product services | No complete Builder account/payment/storage workflow established in inspected viewer/modules; creator-kit-ux-v3 has local click-through editing/export only | Invite accounts and authorization; private durable versioned storage and recovery; revocable share links; study sheet export; manual payment entitlement and support. Automated checkout is deferrable. |

Prefer bounded per-project loading for five sites if reliable; do not make global streaming completion a December dependency. Shadow-caster residency must be correct independently of visual streaming. Reuse A4 mechanisms only after their integration checks. Preserve source-level provenance through every conversion.

## 5. Test events/activations first — five conversations, plan only

**Recommendation (inference):** test repeat professional event/activation planners before construction. R explicitly identifies partnership/activation as a strength, existing wedding/activation prototypes give tangible material to discuss, and repeat producers can reuse a bounded site/object kit. Construction's unresolved neighbor validation may raise preparation cost. Events still have data, venue access and precision requirements; this is a distribution/workflow hypothesis, not proof of easier engineering or a larger market. Start with exterior, manageable Denver sites. Do not begin by promising an entire stadium, national TV tour or festival safety plan.

R would conduct five 35–45 minute conversations across independent organizations, seeking an upcoming Denver project or permission to rehearse a recent one. No outreach, posts or conversations are performed here. Ask about the last actual plan and current tools before showing a mock; do not lead with a polished image. This five-person event cohort replaces the original construction-first cohort; construction interviews are a later comparison, not five additional conversations hidden in this test.

| Conversation | Questions / task | Evidence that confirms / kills |
|---|---|---|
| 1. Sports/experiential agency producer | “Walk through the last exterior activation revision. Who paid, approved the site and changed the objects? Would timed shade change a placement?” | Confirms: repeated revisions, budget holder and rights-holder path. Kills: only a bespoke brand film or unrestricted stadium detail is valuable. |
| 2. Traveling campus-show field/activation producer | “What repeats between stops? What must be rebuilt? Who supplies a dimensioned plan? Could you test one Denver stop?” | Confirms: reusable kit plus a real local test. Kills December fit: value requires national coverage, broadcast engineering or live operational control. |
| 3. Professional outdoor wedding planner | Use the existing ceremony/reception concept: move a tent, choose ceremony time, inspect shade and export. “What can your current tool already do? Does a white model help? What about trees?” | Confirms: a paid recurring workflow and useful geometry/shade without decor polish. Kills: only guest lists/photoreal decor matter or canopy uncertainty makes the answer unusable. |
| 4. Outdoor wedding/venue operations manager | “Who may share this plan? How often do you reuse it? Which access/keep-clear constraints must appear? Who signs off?” | Confirms: reusable site, permission and source dimensions. Kills: clearance cannot be obtained or venue refuses any proposed sharing model. |
| 5. Festival/community-event production lead | Rebuild one small activation zone, not a whole festival. “What changed last time? What time/cost does this save? Is payment per edition or repeat season?” | Confirms: measurable revision cost and a bounded paid task. Kills: negligible budget, or purchase depends on crowd, permit or emergency certification. |

Common closing questions: “Who controls this spend? What would you stop using or doing? Would $49/event for 90 days or $79/month for three active projects fit your actual cadence? What would stop you? Which real project and next decision date can you name?” Show the same scope with both price units; record reasons rather than count agreeable reactions. Separate setup cost from software. These prices are guesses, not offers or established willingness to pay.

**Proposed decision gates:** at least 3/5 recount a recent material layout/review problem and can use the bounded workflow; at least two actual budget holders identify a concrete paid-pilot next step, with at least one repeat-use case; enough eligible sites to support five later users. All later test users must distinguish inferred from confirmed geometry and reopen/share the same version; at least four should complete placement/time/export within 20 minutes after onboarding. Compare against their existing tool/time, including manual preparation. These are proposed gates, not research results. Friendly network feedback is not payment evidence. Stop/narrow if incumbent tools already solve the problem, source/access rights are unavailable, canopy dominates, or most need excluded features. If events fail, test the retained construction hypothesis rather than claiming either market confirmed.

### Constraints to flag for R — no policy decision made

| Constraint | Proposed boundary for later decision | What remains open |
|---|---|---|
| User-uploaded sponsor logos | Engine ships no brands. **Proposal only:** host-app, project-scoped asset layer for customer-owned/authorized logos; private by default, explicit asset permission for each reviewer/export, revocation/deletion and no global catalog or training reuse. Generic placeholders until an exception is approved. | R must decide an exception to current no-brand output rules; private use alone does not grant trademark/copyright rights. Review upload rights, sharing/export authorization and whether logo handling belongs in the first pilot. No exception is enacted here. |
| Stadiums and sensitive sites | **Proposal only:** exterior planning only; venue-specific licensed plans/assets supplied through rights-holders. Exclude interiors, security systems, restricted/back-of-house areas and sensitive operational detail; no access inference from a public map. | R/venue owners must define eligibility, authorization proof, reviewer access and allowed exports. Stadium and campus data licences are separate from permission to run an event. December scope need not include these venues. |
| Data licences | Carry forward §3 and the inventory's RED release gate; evaluate each map, imagery, plan, supplier asset and customer overlay for display, derivative and export rights. | Who provides rights-cleared venue context and fulfills required notices/ODbL offer? Invite-only access does not automatically cure the gate. |
| Time zones and daylight saving | The `web/live` API takes an offset-bearing timestamp (or UTC/epoch), not an IANA-zone local-time form. **Proposed adapter:** store site zone `America/Denver`, intended wall date/time, resolved offset and UTC instant; pass explicit offset to API and show it on shares/exports. Resolve each date independently, never use the laptop zone or a fixed Denver offset. | Reject spring-gap times; require explicit choice for repeated fall times. Test 2026-03-08 02:30 (nonexistent) and 2026-11-01 01:30 (two instants), plus cross-midnight event phases. Decide correction/version behavior after time-zone-rule changes. This is an integration need, not a change to A6 in this task. |

### Boundary with R’s separate partnership-execution concept

No standalone specification explicitly named “partnership-execution platform” was found in searched `docs/` or the drop's text packs. Related evidence exists in `docs/proposals/event-sitemap-ai-v1/README.md` (§ Sponsor activation) and `docs/research-gpt/app-ideas/README.md` (§ Partner activations). The separate concept's existence comes from R's request; the following boundary is **proposed**, not a claim about its implemented features.

Builder owns the spatial plan: place, dimensioned footprint, date/time, layout versions, shade/evidence, permitted assets, restricted view link and plan export. The partnership platform should own commercial relationships, rights inventory, proposals/contracts, exclusivity, budgets/payments, deliverable assignments, deadlines, approval workflow and proof-of-fulfillment/ROI records. The overlap is an activation/site/slot identity and the plan being reviewed.

Initially hand over a stable project/version ID and permission-controlled plan link or PDF; optionally record an external activation ID. A later integration can send “layout version ready for review” and receive a decision tied to that exact version. Do not build a second CRM, sponsor inventory marketplace or task/payment system in Builder. A spatial approval is not contract fulfillment; simulated shade or map views do not establish impressions, attendance or ROI. Do not embed private contract terms in share links. Confirm this boundary against R's separate specification before implementation; research can proceed without inventing it.

## 6. Path to late December and decision gates

| Window (2026) | Proposed work / exit condition |
|---|---|
| 8–23 October | Five event/activation conversations when separately authorized; establish payer, repeat cadence, deliverable and error tolerance. Confirm five potential eligible sites, evidence rights and source availability. Decide whether the paid-pilot hypothesis merits building. |
| 26 October–13 November | Resolve release-route licences/ODbL offer; independent Denver geometry checks; integrate sun and bounded white objects/massing; preserve the construction layer. If reliable neighbors cannot be obtained, stop the accuracy promise rather than fill nulls. |
| 16 November–4 December | Complete edit/save/reload/share/export and account isolation. Manual invoicing plan. Verify dimensions, dates, caster boundaries and credits end to end. |
| 7–18 December | Rehearse with five prepared sites; validate intended decision times and laptop browsers; recovery and link-revocation checks. Fix trust failures before cosmetic work. |
| 21–31 December | Target five real users on eligible projects, ideally scheduled by 23 December to avoid holiday attrition. Access and conversations require later execution authorization; this document performs neither. |

Feasibility assumes one focused web/product implementer plus bounded data/validation support and R's customer time; staffing and effort are **unvalidated estimates**. Full WorldEngine look and global streaming are not critical-path gates for this A12 plan. Independent geometric evidence, lawful sharing and reproducible study output are. If those gates fail, report a blocked pilot or a clearly provisional internal demo, not a sellable accuracy product.

Only this research document is changed. Tracker handoff content: A12 shared outdoor planner and event-first scope/pricing/customer-test plan complete; implementation and five conversations not started; accuracy, independent references, data rights and integration remain gates. Trackers themselves are intentionally untouched.
