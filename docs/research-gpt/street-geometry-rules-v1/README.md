# Street geometry rules v1

Research date: **7 October 2026**. Lead synthesis plus regional sub-agent research for US/Canada, UK/Netherlands and France/Japan. Design/data research only; no git or engine edits.

`rules.csv` contains **36 country × street-class profiles**. Every number is a proposed rendering fallback unless explicitly described as an official source bound. These are not measured national medians, universal engineering standards or assertions that a facility exists. “Typical” cannot be established for all requested fields from the available evidence. Sources anchor plausible dimensions; unverified prevalence, lighting and utilities are explicitly labelled. [Source register](sources.md).

## Geometry contract

Use **country → municipality/region → urban/rural → street function → actual tags/geometry**. Country alone is a last-resort prior. Ordinary urban street profiles below do not cover every historical centre, suburb, bus corridor or rural road.

All dimensions are metres. **Moving surface** is motor-traffic space (or the whole flexible unmarked surface on narrow/shared streets). **Carriageway** is kerb-to-kerb/edge-to-edge and includes allocated on-road parking, cycle lanes and shoulders once; it excludes sidewalks and separated cycle tracks. The motorway figures in the tables include an illustrative 3m outer +1m inner shoulder; these allocations are authored/optional, not surveyed. Motorway lane count/width applies to **one mapped directional carriageway**, not the whole divided highway. Median reserve between separate ways is external and is never added twice.

`carriageway_default_m = moving_surface_default_m + parking_allocated_sides × parking_allocated_width_per_side_m + outer_shoulder_allocated_m + inner_shoulder_allocated_m`. No default on-road cycle lane or internal median is allocated here. Conditional facilities are added only after activation and width reconciliation. On-road bike lanes are inside carriageway; separated tracks, buffers, sidewalks and tree strips are outside it. Do not subtract/add already-accounted facilities twice. The range columns describe moving-surface plausibility, not statistical percentiles or total right-of-way width.

A “flow/slot” is not always a painted traffic lane. Blank `lane_default_m` means no lane subdivision, particularly UK/NL/FR access streets and Japan’s narrow residential streets. Canadian residential 8.5m is a flexible parking/travel surface; do not fit two 3m lanes plus two 2.1m parking strips into it. Legal ROW, footway width, nominal design width and measured pavement width are different observations.

## Source precedence and conflict handling

1. Preserve observed source-qualified geometry and explicit tag values, including negative values such as `sidewalk=no`, `cycleway=no`, `parking:both=no` and `lit=no`.
2. Prefer a valid, attributable local road-width/edge/polygon source when semantics, date and segment matching are stronger than an ambiguous width tag. Log conflicts rather than silently replacing OSM. A documented width from OSM is not automatically surveyed; retain `source:width`, `check_date`, source date and confidence.
3. Infer missing components from explicit lanes and side-specific facilities. Apply country lane priors only to the missing dimension; never let a default overwrite a tagged width or lane count.
4. Use the regional profile for remaining unknown fields; label each value `inferred` or `simulated`. Absent tags remain `unknown`, not observed absence. Utilities have **no automatic pole generation** in this pack.
5. If lane/component sum exceeds width, flag a conflict, retain the measured envelope and reduce/omit inferred optional features first. Do not shrink observed sidewalks, create overlapping lanes or force a US layout. Unmarked narrow roads permit opposing vehicles to yield; they need not satisfy two independent lane-width minima.

One-way roads change direction/flow allocation, not automatically width. `oneway=-1` reverses legal travel but does not redefine OSM left/right. An explicit six-lane arterial uses six, not the profile’s two/four. Shared streets require legal/access evidence (`living_street`, pedestrian access, local designation), not just narrowness. Crossings and legal parking restrictions are generated only at evidenced locations. Do not create a crosswalk at every graph node. Maintain the standing mock rule: no dogs, characters or host-app content unless explicitly requested.

## Country fallback tables

All rows are authored priors. “CW” = carriageway including the listed baseline on-road parking and motorway shoulders; “M” = moving surface. Sidewalk widths are unobstructed walking widths **per side**, not total sidewalk/furniture zone. Optional planting widths and track widths do not enter CW. K = exposed kerb height; F = footway surface level above road (Japan may differ). Lamp spacing applies only if lighting presence is known or explicitly simulated; every spacing is **UNVERIFIED as a country typical**. Parking/cycling/tree/median defaults are inferred/conditional, never mapped facts.

### United States (US)

Design anchor: [US-G1](https://www.fhwa.dot.gov/policy/23cpr/chap4.cfm). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|11.32 / 7.32; 7.32–14.64|3.66 / 2 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|13.4 / 13.4; 6.1–26|3.35 / 4 (total flow slots)|both inferred urban; 2.4m|vertical concrete gutter; K0.15 / F0.15|none generated unknown presence|
|collector|10.6 / 6.1; 6.1–9.5|3.05 / 2 (total flow slots)|both inferred urban; 1.8m|vertical concrete gutter; K0.15 / F0.15|2 × 2.25m|
|residential|10.6 / 6.1; 4.5–7.7|3.05 / 2 (total flow slots)|both inferred urban; 1.5m|vertical concrete gutter; K0.15 / F0.15|2 × 2.25m|
|lane/alley|4.5 / 4.5; 3–6|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|5.5 / 5.5; 4–8|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|60m **U**; no distribution poles at traffic edge **U**|
|arterial|unknown no dedicated geometry|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|double yellow centre white same direction dashes; white continental or ladder|40m **U**; older districts overhead newer underground unverified **U**|
|collector|unknown no dedicated geometry|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|yellow centre white same direction where marked; white continental or ladder|40m **U**; older districts overhead newer underground unverified **U**|
|residential|mixed traffic|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|50m **U**; older districts overhead newer underground unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|60m **U**; older districts overhead newer underground unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; older districts overhead newer underground unverified **U**|

### Canada (CA)

Design anchor: [CA-G1](https://www.toronto.ca/wp-content/uploads/2025/11/96f5-ecs-specs-roaddg-Lane-Widths-Guideline-Version-3.0-Nov2025.pdf). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|11.4 / 7.4; 7–14.8|3.7 / 2 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|12.6 / 12.6; 6–25|3.15 / 4 (total flow slots)|both inferred urban; 2.1m|vertical concrete gutter; K0.15 / F0.15|none generated unknown presence|
|collector|10.4 / 6.2; 6–9.8|3.1 / 2 (total flow slots)|both inferred urban; 1.8m|vertical concrete gutter; K0.15 / F0.15|2 × 2.1m|
|residential|8.5 / 8.5; 7.2–10.5|unlaned / 2 (total flow slots)|both inferred urban; 1.8m|vertical concrete gutter; K0.15 / F0.15|flexible curb parking no reserved lane allocation|
|lane/alley|4.5 / 4.5; 3–6|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|5.5 / 5.5; 4–8|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|60m **U**; no distribution poles at traffic edge **U**|
|arterial|unknown no dedicated geometry|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|yellow centre white same direction where marked; white transverse pair or local zebra|40m **U**; older districts overhead newer underground unverified **U**|
|collector|unknown no dedicated geometry|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|yellow centre white same direction where marked; white transverse pair or local zebra|40m **U**; older districts overhead newer underground unverified **U**|
|residential|mixed traffic|conditional urban planting strip; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|50m **U**; older districts overhead newer underground unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|60m **U**; older districts overhead newer underground unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; older districts overhead newer underground unverified **U**|

### United Kingdom (GB)

Design anchor: [GB-G1](https://www.gov.uk/government/publications/manual-for-streets). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|14.95 / 10.95; 7.3–14.6|3.65 / 3 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|7 / 7; 6.5–7.3|3.5 / 2 (total flow slots)|both inferred urban; 2.5m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|collector|6 / 6; 5.5–6.5|3 / 2 (total flow slots)|both inferred urban; 2m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|residential|5 / 5; 4.8–5.5|unlaned / 2 (total flow slots)|both inferred urban; 2m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|lane/alley|3 / 3; 2.5–3.7|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|4.8 / 4.8; 4–5.5|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|45m **U**; no distribution poles at traffic edge **U**|
|arterial|unknown no dedicated geometry|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; zebra with zigzags or signal crossing|35m **U**; urban underground telecom poles possible unverified **U**|
|collector|unknown no dedicated geometry|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; zebra with zigzags or signal crossing|30m **U**; urban underground telecom poles possible unverified **U**|
|residential|mixed traffic|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|25m **U**; urban underground telecom poles possible unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; urban underground telecom poles possible unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; urban underground telecom poles possible unverified **U**|

### Netherlands (NL)

Design anchor: [NL-G1](https://kennisbank.crow.nl/public/gastgebruiker/WOBI/ASVV_2021/Wegvakvoorzieningen_op_erftoegangswegen/113086). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|14.5 / 10.5; 7–14|3.5 / 3 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|6.5 / 6.5; 6–7|3.25 / 2 (total flow slots)|both inferred urban; 2.1m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|collector|6 / 6; 5.5–6.5|3 / 2 (total flow slots)|both inferred urban; 2.1m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|residential|4.8 / 4.8; 4.8–5.8|unlaned / 2 (total flow slots)|both inferred urban; 1.8m|raised stone or concrete; K0.125 / F0.125|none generated unknown presence|
|lane/alley|3 / 3; 2.5–3.5|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|4.5 / 4.5; 3.8–5.8|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|45m **U**; no distribution poles at traffic edge **U**|
|arterial|conditional distributor red separate track; 2 × 2.5m + 0.5m separator per side|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|35m **U**; underground appearance prior unverified **U**|
|collector|conditional distributor red separate track; 2 × 2m + 0.5m separator per side|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|30m **U**; underground appearance prior unverified **U**|
|residential|mixed traffic|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|25m **U**; underground appearance prior unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; underground appearance prior unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 1m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; underground appearance prior unverified **U**|

### France (FR)

Design anchor: [FR1](https://www.cerema.fr/fr/actualites/8-recommandations-reussir-votre-piste-cyclable). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|11 / 7; 6.5–10.5|3.5 / 2 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|6.5 / 6.5; 6–13|3.25 / 2 (total flow slots)|both inferred urban; 2.5m|raised stone or concrete; K0.15 / F0.15|none generated unknown presence|
|collector|6 / 6; 5.5–7|3 / 2 (total flow slots)|both inferred urban; 2m|raised stone or concrete; K0.15 / F0.15|none generated unknown presence|
|residential|5 / 5; 4.5–6|unlaned / 2 (total flow slots)|both inferred urban; 1.5m|raised stone or concrete; K0.15 / F0.15|none generated unknown presence|
|lane/alley|3 / 3; 2.5–4|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|4.5 / 4.5; 3.5–6|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|40m **U**; no distribution poles at traffic edge **U**|
|arterial|unknown no dedicated geometry|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|30m **U**; urban underground village overhead unverified **U**|
|collector|unknown no dedicated geometry|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|30m **U**; urban underground village overhead unverified **U**|
|residential|mixed traffic|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|25m **U**; urban underground village overhead unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; urban underground village overhead unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; urban underground village overhead unverified **U**|

### Japan (JP)

Design anchor: [JP1](https://www.mlit.go.jp/road/sign/pdf/kouzourei_full.pdf). Complete local bounds, marking evidence and limitations are in [sources.md](sources.md).

|Class|CW / M (m); M range|Lane width / flow slots|Sidewalks / clear width per side|Kerb K; footway F|Parking baseline|
|---|---|---|---|---|---|
|motorway|11 / 7; 6.5–10.5|3.5 / 2 (per direction)|none; 0m|none shoulder barrier; K0 / F0|none|
|arterial|6.5 / 6.5; 6–13|3.25 / 2 (total flow slots)|both inferred urban; 2m|raised kerb semi flat sidewalk; K0.15 / F0.05|none generated unknown presence|
|collector|6 / 6; 5.5–7|3 / 2 (total flow slots)|both inferred urban; 2m|raised kerb semi flat sidewalk; K0.15 / F0.05|none generated unknown presence|
|residential|4 / 4; 3–5.5|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none generated unknown presence|
|lane/alley|3 / 3; 2–4|unlaned / 1 (total flow slots)|none; 0m|flush or gutter; K0 / F0|none|
|shared/street|4 / 4; 3–5|unlaned / 1 (total flow slots)|integrated shared surface no separate sidewalk; 0m|flush or gutter; K0 / F0|mapped bays only|

|Class|Cycling|Tree/verge optional width|Median|Markings / crossing if evidenced|Lamp spacing if lit / utilities|
|---|---|---|---|---|---|
|motorway|no facility motorway|grass verge no roadside trees; 2m|external divided reserve conditional; optional 3m|white dashed lanes white edge; none|40m **U**; no distribution poles at traffic edge **U**|
|arterial|unknown no dedicated geometry|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|35m **U**; overhead appearance prior central underground unverified **U**|
|collector|unknown no dedicated geometry|none default optional pits or local verge; 1.5m|none unless mapped divided or turn lane; optional 2m|white broken centre white same direction; white zebra or signal crossing|30m **U**; overhead appearance prior central underground unverified **U**|
|residential|mixed traffic|none default optional pits or local verge; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; unmarked unless explicit crossing then country style|25m **U**; overhead appearance prior central underground unverified **U**|
|lane/alley|mixed traffic|none; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; overhead appearance prior central underground unverified **U**|
|shared/street|mixed traffic|none default optional pits or local verge; 0m|none unless mapped divided or turn lane; optional 2m|no longitudinal markings; none|25m **U**; overhead appearance prior central underground unverified **U**|

## Country interpretation and overrides

- **US:** freeway lane3.66m and arterial/collector3.05–3.66m are design-guidance anchors; wider urban carriageways often allocate parking. Baseline collector/residential parking in this pack is an inferred urban profile, not legal permission. Rural profiles drop inferred sidewalks/parking/kerbs in favour of local shoulders/ditches. The FHWA mileage-by-lane-width table supplies real national distributions, but not individual curb-to-curb widths. [FHWA lane guidance](https://www.fhwa.dot.gov/policy/23cpr/chap4.cfm), [HM-53](https://www.fhwa.dot.gov/policyinformation/statistics/2023/hm53.cfm).
- **Canada:** Toronto urban lanes3.0–3.3m contrast with BC rural freeway3.7m and collector/local3.6m guidance. Canada is not one Toronto profile. The arterial average3.15m means two inner3.0 and two curb3.3m lanes. Snow storage/boulevard space is municipality-specific; no universal extra winter width. [Toronto guideline](https://www.toronto.ca/wp-content/uploads/2025/11/96f5-ecs-specs-roaddg-Lane-Widths-Guideline-Version-3.0-Nov2025.pdf), [BC guide](https://www2.gov.bc.ca/assets/gov/driving-and-transportation/funding-engagement-permits/grants-funding/cycling-infrastructure-funding/active-transportation-guide/2019-06-14_bcatdg_section_f.pdf).
- **UK:** left-driving; compact residential carriageways and context-dependent hierarchy. GB data excludes Northern Ireland. White centre/lane lines; yellow restrictions only when evidenced. Zebra crossings include approach zig-zags; signal crossings are different assets. Utility assumptions are not verified. [Manual for Streets](https://www.gov.uk/government/publications/manual-for-streets), [DfT marking reference](https://www.gov.uk/government/publications/know-your-traffic-signs/road-markings).
- **Netherlands:** distinguish stroomweg, gebiedsontsluitingsweg (distributor) and erftoegangsweg (access). Urban two-way access surfaces4.8–5.8m are combined mixed-traffic space, not two independent painted lanes. Red separated tracks are a guarded distributor prior; collector/access ambiguity should keep cycle geometry unknown unless local evidence resolves it. Rural access profiles have different widths and often no sidewalks. White/yield/zebra legal vocabulary remains unverified against current RVV/BABW in this pack. [CROW access-road table](https://kennisbank.crow.nl/public/gastgebruiker/WOBI/ASVV_2021/Wegvakvoorzieningen_op_erftoegangswegen/113086), [rural runner guidance](https://www.fietsberaad.nl/CROWFietsberaad/media/Kennis/Bestanden/Factsheet_Rijlopers.pdf?ext=.pdf).
- **France:** pedestrian design minimum1.4m is not an observed street width; recommended2.5m is a design target. White zebra vocabulary and shared zones differ from US crossings. A zone de rencontre can retain raised sidewalks; do not force flush surfaces without evidence. Cycle track one-way2m minimum/2.5 desirable; conditional widths above are not prevalence claims. [Cerema walking guidance](https://www.cerema.fr/fr/actualites/quels-amenagements-pietons-lors-phase-deconfinement-0), [cycle guidance](https://www.cerema.fr/fr/actualites/8-recommandations-reussir-votre-piste-cyclable).
- **Japan:** left-driving, narrow unlaned neighbourhood roads, normally no two-sided parking-lane fallback. MLIT Japanese design tables anchor arterial3.25m and collector3m; the English table contains an apparent inconsistent entry, so Japanese source takes precedence. Semi-flat sidewalk surface5cm is separate from exposed kerb height; crossing transitions need their own roughly2cm design treatment, not ordinary kerb extrusion. Older streets need not meet new-build standards. Utility overhead is a regional appearance prior; no current national prevalence percentage asserted. [Japanese road-structure guidance](https://www.mlit.go.jp/road/sign/pdf/kouzourei_full.pdf), [semi-flat guidance](https://www.mlit.go.jp/kisha/kisha05/06/060203_.html), [crossing accessibility](https://www.mlit.go.jp/road/road/traffic/barrier/barrier2.htm).

## Reading OpenStreetMap tags

The OSM wiki documents community conventions, not proof a specific object is correct. Keep the raw tags and source metadata alongside normalized values.

|Tag family|Interpretation and handling|
|---|---|
|`width`, `width:carriageway`, `est_width`|Width is kerb-to-kerb or edge-to-edge; includes on-road parking/cycle lanes/shoulders, excludes sidewalks and separated tracks. Old usage is ambiguous. Prefer explicit semantics/source; retain estimated status for `est_width`. Parse metres by default, explicit units and feet/inches; reject nonnumeric `narrow`, negative/zero widths and ranges as exact scalar values. `maxwidth` is a legal vehicle-width limit, not road geometry. Never relabel a legal ROW as carriageway. [Width convention](https://wiki.openstreetmap.org/wiki/Key:width).|
|`lanes`, `lanes:forward/backward/both_ways`, `width:lanes`|`lanes` normally counts full-width motor lanes, not bicycle or parking strips. Reconcile directional sum and central reversible/turn lanes; preserve pipe-delimited per-lane ordering and empty entries. Bus lanes can be full-width lanes. Some narrow two-way roads have no marked lanes: do not infer painted lines from nominal flow count; consult `lane_markings=no`. `lanes` on a divided one-way way applies to that carriageway. [Lanes convention](https://wiki.openstreetmap.org/wiki/Key:lanes).|
|`sidewalk`, `sidewalk:left/right/both`, width subkeys|Support both/left/right/no/none/yes/separate and explicit side-specific overrides. `yes` does not locate a side. Left/right is relative to OSM way digitization. `separate` means find the associated `highway=footway` + `footway=sidewalk` geometry; do not create a duplicate sidewalk. Missing tag is unknown. Clear-width vs whole-footway-width semantics may need inspection. [Sidewalk convention](https://wiki.openstreetmap.org/wiki/Key:sidewalk).|
|`cycleway`, side-specific type/width/oneway/lane keys|`lane` is painted on-carriageway; `track` is physically separated; `shared_lane` marks shared traffic; `separate` signals independent geometry. Handle advisory vs exclusive lanes, contraflow, `oneway:bicycle` and side-specific bicycle direction. Do not count cycle lanes in ordinary motor `lanes` or duplicate adjacent `highway=cycleway`/designated paths. Country track defaults cannot override explicit no. [Cycleway convention](https://wiki.openstreetmap.org/wiki/Key:cycleway).|
|Current `parking:left/right/both=*`; legacy `parking:lane:*`|Normalize both schemas; modern `lane` is inside carriageway, `street_side`/bays can be outside its edge. Orientation parallel/diagonal/perpendicular changes footprint. Use side width subkeys only with appropriate semantics; a bay2m wide is not a perpendicular parking depth. Prefer specific current tags; flag conflicting legacy/current values. `no` or restrictions do not establish a width; conditional access can change use over time. Parking strips do not count as motor lanes. [Street-parking convention](https://wiki.openstreetmap.org/wiki/Street_parking).|
|`highway`, `service`, access/speed/oneway|Functional rank is not a guaranteed cross-section. Provisional mapping: motorway→motorway; trunk/primary/secondary→arterial with country/local overrides; tertiary→collector; residential→residential; service+alley→lane/alley; living_street→shared. `unclassified` is not “unknown”: use its local network function, often a minor through road. Links/ramps, driveways, parking aisles, pedestrian ways, tracks and paths need separate profiles. Do not apply full arterial width to every `_link`. [Classification](https://wiki.openstreetmap.org/wiki/Highway:International_equivalence).|

Also read `shoulder`, `verge`, `surface`, `smoothness`, `lit`, `highway=street_lamp`, `barrier=kerb`, `kerb:height`, crossings, `crossing:markings`, `traffic_calming`, utility/power geometry and bridge/tunnel/layer. Connect evidence by source identity and topology, not nearest line alone. Separate sidewalks/tracks need an actual association or validated matching; roads beside unrelated paths must not steal them.

**Worked width reconciliation:** a two-way street with `width=10`, `lanes=2`, both on-road parking lanes2m and both on-road cycle lanes1.5m leaves3m for two motor lanes: inconsistent with ordinary two-lane operation. Preserve the10m observation, flag the conflicting components, and inspect semantics/source; do not render a17m road. Conversely `width=10`, `lanes=2`, both parking2m leaves6m, yielding two 3m lanes; sidewalks remain outside. A4m Japanese residential road without lane tags is one shared unmarked surface with possible opposing flows, not two 3m lanes.

## Real-world OSM completeness by country

**Unresolved evidence gap:** no reproducible 2026 countrywide audit of parsable width, lanes, sidewalk, cycling and parking attributes was completed. No defensible numerical country ranking is supplied. This is not proof all six are equally complete. Tag presence, correct attribute values, separate mapped facility completeness and road-network completeness are four different measures.

|Country|Verified evidence available|Current countrywide attribute completeness|
|---|---|---|
|US|A 2022 primary study examines sidewalk coverage across 50+ US cities and detailed Seattle/Chicago/NYC histories; city findings cannot establish 2026 national completeness|Width/lanes/sidewalk/cycleway/parking: **UNVERIFIED**|
|Canada|No representative national attribute study verified here; municipal inventories can enrich selected cities|All requested attributes: **UNVERIFIED**|
|UK|GB centreline availability says nothing about OSM width/sidewalk tags; independent paths require counting separately|All requested attributes: **UNVERIFIED**|
|Netherlands|BGT/NWB are non-OSM sources, not an OSM tag audit; separate cycle paths can leave road `cycleway` absent|All requested attributes: **UNVERIFIED**|
|France|IGN/Paris data availability is not an OSM completeness metric|All requested attributes: **UNVERIFIED**|
|Japan|National road-edge/model data and mapping imports do not prove attribute coverage; narrow streets require distinct semantics|All requested attributes: **UNVERIFIED**|

Primary research: [US sidewalk study](https://arxiv.org/abs/2210.02350). A 2017 global study, with a 2019 correction, estimates **road-network coverage**, not these attributes; its headline percentage must not be reused as width/sidewalk completeness. [Network study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0180698). Regional Taginfo API attempts for Canada/NL were inaccessible during this research; no values from those endpoints were used.

A defensible next audit uses dated country PBFs, a frozen country boundary and drivable public-road denominators, split by class, urban/rural and city. Report **way-count and road-length weighted** coverage for: parsable width (separate estimated), lanes/directional lanes; explicit sidewalk positive/negative/unknown/separate; cycle facility positive/negative/separate; and both parking schemas. Side-specific tag unions must count each road once. Include affiliated separate footway/cycleway geometry as a separate association metric; don't call it a tag percentage. Count invalid/conflicting values separately. Validate association samples against licensed local inventories/edges to estimate omission and commission with uncertainty. Split carriageways, imports and border cuts bias naive counts. An audit without ground truth measures tagged coverage, not real-world truth completeness. [Taginfo API semantics](https://taginfo.openstreetmap.org/taginfo/apidoc).

## Best open width and geometry sources

See the **dataset register in sources.md** for links and per-distribution licences. Recommended order: directly documented paved-width attribute → documented road-surface polygons/paired edges → centreline plus valid width attribute → plain centreline for matching only. Derive cross-sections in a local metric CRS, perpendicular to road tangent and away from junction flares, driveways and roundabouts; calculate robust mid-block distributions and retain uncertainty rather than one misleading global buffer. Separate roadbeds, shoulders, medians, cycling and sidewalks before interpreting width. Polygon-derived widths remain derived, not surveyed field observations.

Key limitations: NYC LION `StreetWidth_Min` is minimum paved width in feet and raw-data licence remains unverified here; Vancouver ROW is explicitly property-to-property; OS Open Roads is approximate GB centreline without measured width; Netherlands BGT supplies derivable physical surface geometry; IGN BD TOPO width is generalized/estimated; France national-network widths do not cover every city; Japan PLATEAU road fields vary by city and GSI edges require pairing. Source date, measurement definition and licence must travel with each selected value.

## CSV schema and evidence statuses

UTF-8 RFC4180 CSV, one row per country/class; scalar dimensions in metres, semicolon-separated source IDs, numeric blanks = not meaningful/unallocated—not zero width. Zero means no baseline geometry for that component; optional dimensions are candidates, never existence claims. Presence/policy fields carry the distinction. `flow_or_lane_slots` is a rendering count, not an OSM edit. `moving_surface_range_*` is an authored plausibility interval. All rows have `profile_status=proposed_fallback_not_measured_country_typical`.

`source_ids` identifies design/visual anchors, not proof of every cell. Component status fields explicitly flag inferred presence, unverified median/tree prevalence, unverified lighting spacing, utility appearance and the OSM audit gap. Municipal standards validate a bound or vocabulary within their scope; they do not validate national prevalence. `carriageway_inclusions` makes width accounting explicit. `streetlight_spacing_if_lit_m` does not place lights unless its presence policy activates them. Utility generation stays unknown without assets/local evidence despite a regional character hint. Retain per-property provenance in engine output: observed/inferred/simulated, source ID/date, method, confidence and override chain.

For one-way and divided-road updates, resolve actual lane counts and shoulders rather than halving full cross-section blindly. Country presets are deterministic style/geometry priors, not permission to fabricate observed facilities. Trees, parking, medians and track separators must fit the available envelope and avoid junction/access conflicts. This research proposes rules; no renderer implementation or benchmark is claimed.
