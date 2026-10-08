# A12 — Builder MVP v1

Research and planning only · 8 October 2026 · target: five real users by 21–31 December 2026.

## Recommendation and authority

Sell a small, assisted Denver **new-construction massing and building-shadow study**: compare an existing site with a proposed building, review uncertain neighbors, and share a reproducible study. Start with five qualified sites, not automatic trustworthy coverage of all Denver. The value hypothesis is reduced preparation and review time with visible evidence, not attractive rendering. Final WorldEngine styling is unnecessary for this scope.

The current A12 request governs this document. Earlier roadmap sequencing, Easy/Pro designs and event-template packs are context, not instructions to implement them. This is not code, a launch authorization, outreach, or a change to those documents. All dates, acceptance targets and proposed prices below are planning hypotheses, not approved commitments. No customer research has yet been conducted for this document.

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

**Commercial hypothesis (guess):** test $149 per site for a 30-day assisted pilot, one editor, up to three massing alternatives, read-only reviewers and study exports; later test $49/month for repeat users. These are research anchors, not a pricing decision. Log operator preparation time: if ordinary sites need more than two hours of unrecoverable manual cleanup, the $149 hypothesis likely fails. Do not include survey procurement in that price. Cheap diagramming and existing sun tools make “3D in a browser” an insufficient differentiator.

## 2. Smallest sellable product

**Customer/job:** a Denver homebuilder, small developer, architect or planning consultant needs to explain how a new volume affects building shade on a neighboring yard, facade or outdoor area before detailed design. Commercial project sites only; no personal-home profiling. Planning staff can assess usefulness, but are not presumed buyers or approval authorities.

**One workflow:** open a prequalified Denver site → inspect context and unresolved neighbors → draw measured massing → compare baseline/proposal at a chosen local date/time → save a version → share or export the same version.

| Required capability | Bounded MVP behavior / acceptance |
|---|---|
| Web only | Desktop browser editing; read-only browser link. Test current Chrome and Safari on actual pilot laptops. No native application. R can prepare site packages manually. |
| Denver only | Five eligible Denver sites; reject unsupported sites explicitly. Initial area can be about 1 km square, but shadow-caster coverage determines its necessary extent; a fixed radius is not an accuracy guarantee. |
| White-model massing | Draw/edit a polygon; enter dimensions, height, base elevation and rotation; combine simple volumes for setbacks and roof-height envelopes. Numeric metres/feet input with explicit conversion. Distinguish existing, demolished-for-scenario and proposed volumes. Undo and reset. No decorative geometry changes analytical dimensions. |
| Real-sun study | Date and time with America/Denver civil time, displayed UTC offset and true north. Reject nonexistent DST times and disambiguate repeated times. Initially validate 2026–2027; outside the validated range show unsupported. Baseline/proposal toggle and saved comparison views; clear-sky geometric building shadows, not weather prediction. |
| Trust review | Click each relevant neighbor for source, age, height definition and status; supply or confirm evidence-backed geometry. Missing influential geometry makes the study incomplete. |
| Save | One editor account; server-side private project storage, named versions and reload without geometric changes. Keep a local recovery copy until save succeeds. |
| Share | Revocable, unguessable, read-only link to a pinned version. Explicit owner action; no public gallery or indexing. Show identical time, geometry and uncertainty to the author. |
| Export | PNG plus a printable study sheet (browser print-to-PDF acceptable). Include baseline/proposal, dimensions/scale bar, north, local/UTC time, version, source dates, uncertainty, coverage and attribution. An incomplete study may export only with a prominent incomplete label; never as a validated result. |
| Payment/support | Manual invoice and manually activated access suffice for five users; no card handling in Builder. Automated subscriptions can wait. No payment collection is performed by this research task. |

**Explicitly out:** final Style B look; Easy/Pro product tiers; worldwide/citywide self-service coverage; mobile editing; BIM/CAD import/export and round trips; detailed architecture, textures, interiors and photorealism; automatic zoning/code/permit conclusions; certified shadow reports; annual solar-energy/daylight analysis; weather, clouds, moon, live feeds and flights; traffic, crowds, events, seating and Cvent replacement; real-time coediting; organization administration/SSO; AI design generation; public marketplace; bulk geographic/raw-model export. Trees are excluded from the primary **building-only** study and explicitly disclosed. Sites whose decision depends on canopy shade are not eligible for this pilot unless a separately validated canopy method is added later.

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
| Product services | No complete Builder account/payment/storage workflow established in inspected viewer/modules | Invite accounts and authorization; private durable versioned storage and recovery; revocable share links; study sheet export; manual payment entitlement and support. Automated checkout is deferrable. |

Prefer bounded per-project loading for five sites if reliable; do not make global streaming completion a December dependency. Shadow-caster residency must be correct independently of visual streaming. Reuse A4 mechanisms only after their integration checks. Preserve source-level provenance through every conversion.

## 5. Five-conversation customer test — plan only

R would conduct five 35–45 minute conversations, one person per conversation, preferably across five independent organizations with a real Denver new-construction decision in the next 90 days. No recruitment, messages, posts or customer data collection is authorized or performed here. Later records should be anonymized, with permission for any project materials. Ask about the last actual project before showing the concept; record behavior and budgets rather than compliments.

| Conversation | Questions / task | Confirms / kills |
|---|---|---|
| 1. Small infill homebuilder / owner | “Show the last neighbor-shadow question. Who answered it, how long did it take, and did it change the design? What deadline is next?” Show a baseline/proposal white model. | Confirms: recurring costly question and an imminent site. Kills this segment: purely decorative interest or no decision affected by shade. |
| 2. Small developer / acquisition or project lead | “What did the last feasibility study cost? Who authorizes a $149 site expense? Would this replace a task or add another report?” | Confirms: named budget holder and a concrete replacement task. Kills: willingness only if free, or required yield/zoning economics outside scope. |
| 3. Residential architect | Ask them to enter a dimensioned volume, correct a neighbor and create a dated study. “Where would this fit beside your present tool? What error would reverse your advice?” | Confirms: measurable setup-time saving and acceptable white-model output. Kills: mandatory BIM round trip or precision that this data cannot support. |
| 4. Architect / urban designer on a different building type | Show an inferred height and a conflicting user measurement. “Which would you trust and why? What evidence can you provide? Would you share this caveat with a client?” | Confirms: understands uncertainty and can supply usable evidence. Kills: disclaimers routinely ignored, or reliable context requires unaffordable survey work. |
| 5. Planning consultant or development-review planner | “How would you use this sheet in an early discussion? What makes it misleading? What is missing from the information you need?” Ask who buys/prepares the study. | Confirms: useful early discussion artifact and clear boundary from formal submissions. Kills claimed positioning: only a certified submission is useful, or municipal acceptance is required to buy. |

Common closing questions: “Which upcoming project would you use? Who else must agree? Would you buy this defined 30-day pilot for $149, subject to the demonstrated accuracy limits? What would stop you?” A hypothetical yes is weak evidence; stronger evidence is consent to nominate an eligible project and schedule a later paid-pilot decision. No deposits or outreach in this task.

**Precommitted decision proposal:** proceed only if at least 3/5 describe a recent material problem, at least 3/5 can use the bounded workflow without excluded features, and at least 2 budget holders commit to a concrete paid-pilot next step. Across five later sessions, require all users to distinguish inferred from confirmed heights, reopen saved work and interpret/export the same study; at least four should complete the core task within 20 minutes after onboarding. These are proposed gates, not results or statistical market proof. Stop or narrow if fewer than two credible payers emerge, most require BIM/certified reports, influential neighbors cannot be verified, or uncertainty is misunderstood. A planner's approval does not substitute for buyer demand.

## 6. Path to late December and decision gates

| Window (2026) | Proposed work / exit condition |
|---|---|
| 8–23 October | Five conversations when separately authorized; establish buyer, deliverable and error tolerance. Confirm five potential eligible sites, evidence rights and source availability. Decide whether the paid-pilot hypothesis merits building. |
| 26 October–13 November | Resolve release-route licences/ODbL offer; independent Denver geometry checks; integrate sun and a bounded white-massing study. If reliable neighbors cannot be obtained, stop the accuracy promise rather than fill nulls. |
| 16 November–4 December | Complete edit/save/reload/share/export and account isolation. Manual invoicing plan. Verify dimensions, dates, caster boundaries and credits end to end. |
| 7–18 December | Rehearse with five prepared sites; validate intended decision times and laptop browsers; recovery and link-revocation checks. Fix trust failures before cosmetic work. |
| 21–31 December | Target five real users on eligible projects, ideally scheduled by 23 December to avoid holiday attrition. Access and conversations require later execution authorization; this document performs neither. |

Feasibility assumes one focused web/product implementer plus bounded data/validation support and R's customer time; staffing and effort are **unvalidated estimates**. Full WorldEngine look and global streaming are not critical-path gates for this A12 plan. Independent geometric evidence, lawful sharing and reproducible study output are. If those gates fail, report a blocked pilot or a clearly provisional internal demo, not a sellable accuracy product.

Only this research document is changed. Tracker handoff content: A12 scope/pricing/customer-test plan complete; implementation and five conversations not started; accuracy, independent references, data rights and integration remain gates. Trackers themselves are intentionally untouched.
