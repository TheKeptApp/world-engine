# Civic and landmark classification — 9 October 2026

**Recommendation:** use explicit tags with separate building-form, occupant-use and site records; safely associate points to mapped outlines; preserve unknowns. Neither a footprint nor a POI category guarantees recognizable architecture. This is research at main `08fd77b` (P2 audit merged), not a new classifier, approved look, capture or score. The eight held cores are measured below; national completeness and true classification precision remain unmeasured.

Read first: [P2 classification audit](../buildings/classification-audit/README.md), [archetype registry §§1–6](../execution/archetypes.md), [REFERENCE-MAP](../tracking/REFERENCE-MAP.md) (Facades, Ground and Context ring/world edge, plus infrastructure/campus catalogs), [R’s decisions](../tracking/DECISIONS.md). Preserve the existing Stage 0b/look gate; this report does not authorize building-role changes. No named-place classifier rule is proposed.

## 1. Tag and Overture crosswalk

**Geometry key:** **B** = actual building outline (closed way or assembled building multipolygon); **P** = separate node, often inside a footprint; **S** = site/land-use polygon, not a roof footprint; **R** = relation membership/geometry; **L** = mapped line. `building=*` describes form, while `amenity`/`healthcare`/`education` describe use. A former church/hospital can retain that building form without its original activity. A generic `building=civic|public|government` cannot distinguish a court, library or town hall. [OSM building conventions](https://wiki.openstreetmap.org/wiki/Key:building).

Overture columns distinguish **Buildings class**, **Places `taxonomy.primary`** and **Base LandUse/Infrastructure class**; these are different themes and geometry kinds. Classes listed below were checked against schema **v2.0.0** and the **2026-09-23.0 taxonomy CSV** on 9 October; local Buildings files say **2026-09-23.1**. Current Places uses `taxonomy`/`basic_category`; the old `categories` field was removed in September. A Places point is not a building or campus outline. [Buildings classes](https://docs.overturemaps.org/schema/reference/buildings/types/building_class/), [Places schema](https://docs.overturemaps.org/schema/reference/places/place/), [official taxonomy CSV](https://docs.overturemaps.org/taxonomy/2026-09-23.0/taxonomy.csv).

| Type | Exact OSM matches / qualifiers | Overture equivalents / limits | Where the evidence lives |
| --- | --- | --- | --- |
| Church / chapel / cathedral | B: `building=church|chapel|cathedral`; P/B/S: `amenity=place_of_worship` + `religion=christian`; `denomination=*` preserves stated affiliation | B `church|chapel|cathedral`; P `christian_place_of_worship`; S LandUse `religious` | B/P/S/R; religion alone can also describe a school/cemetery and is not a worship match |
| Synagogue | B: `building=synagogue`; P/B/S: `amenity=place_of_worship` + `religion=jewish`; `denomination=*` optional | B `synagogue`; P `jewish_place_of_worship`; S `religious` | B/P/S/R; no inferred faith or façade symbol |
| Mosque | B: `building=mosque`; P/B/S: `amenity=place_of_worship` + `religion=muslim`; `denomination=sunni|shia|*` if supplied | B `mosque`; P `muslim_place_of_worship`; S `religious` | B/P/S/R; minaret/dome requires separate mapped form |
| Other / unspecified worship | `amenity=place_of_worship`; `religion=buddhist|hindu|sikh|shinto|*` if supplied; B `temple|shrine|religious|monastery`; S `landuse=religious` | B `temple|shrine|religious|monastery`; P `place_of_worship` and faith-specific taxonomy; S `religious` | B/P/S/R; a monastery or religious land is not automatically a public congregation |
| Hospital | P/S/B `amenity=hospital` or `healthcare=hospital`; B `building=hospital`; `emergency=*` is a separate service fact | B `hospital`; P `hospital` subtree; S `hospital` | S usually grounds, B constituent roofs; multipolygon/site R can group campuses |
| Clinic / doctor / dental practice | P/B/S `amenity=clinic|doctors|dentist` or `healthcare=clinic|doctor|dentist`; `healthcare:speciality=*` refines service, not shape | No specific B clinic enum: `medical` subtype only; P `outpatient_care_facility` descendants, `urgent_care_clinic|walk_in_clinic`; S `clinic|doctors` | P often tenant-only; do not turn an apartment/office into a hospital |
| Train station / halt | P/S `railway=station|halt`; B `building=train_station`; `public_transport=station` requires rail mode (`train=yes` or railway evidence) | B `train_station`; P `train_station`; Base Infrastructure `railway_station|railway_halt` | B/P/S; R `type=public_transport, public_transport=stop_area` groups stops/platforms; freight-only station possible |
| Rail platform | `railway=platform` or `public_transport=platform` + rail mode; `area=yes`, `covered=*`, `building=roof` only if separately mapped | Base Infrastructure `platform`; no dedicated Places platform category | P/L/S/R; a platform polygon is not a station building |
| Train yard | S `railway=yard` + `landuse=railway`; L `railway=rail|light_rail|narrow_gauge` + `service=yard`; `railway:yard:*` refinements | Base LandUse `railway` is broad corridor/site; no exact rail-yard Places or Buildings class found | S/R + L constituent tracks; `landuse=railway` alone does not prove a yard |
| School / kindergarten | P/S `amenity=school|kindergarten` or `education=school|kindergarten`; B `building=school|kindergarten`; `isced:level=*`, `school:level=*` if explicit; S `landuse=education` broad | B `school|kindergarten`; P `school` subtree (primary), `kindergarten`; S `school|kindergarten|education` | B/P/S/R; broad education land cannot choose school versus university |
| University / college / campus | P/S `amenity=university|college` or `education=university|college`; B `building=university|college`; `campus=*`, `operator=*`; dormitories separately `building=dormitory` | B `university|college|dormitory`; P `college_university`; S `university|college|education` | S/R may span disconnected parcels; libraries, halls and housing keep component identities |
| Fire station | P/B/S `amenity=fire_station`; B `building=fire_station` | B `fire_station`; P `fire_station`; no exact Base LandUse fire-station class | B/P/S/R; no bays, towers or fire-engine props from amenity alone |
| Police station | P/B/S `amenity=police`; `police=*` differentiates facility; B `building=*` is independent | No exact B police-station class: `civic|government|public` broad; P `police_station` | B/P/S/R; no security perimeter or insignia inference |
| Town / city / village hall | P/B `amenity=townhall`; B `building=townhall|civic|public`; `office=government` is broad, `government=*` refines office | No B `townhall` enum; broad `civic|government|public`; P `town_hall`, basic category `government_office` | B/P/S/R; townhall may be community meeting space, not administration |
| Courthouse | P/B/S `amenity=courthouse`; B `building=*` independent | No exact B courthouse enum; `civic|government|public` broad; P `courthouse` | B/P/S/R; no columns, dome or ceremonial stairs without form evidence |
| Library | P/B `amenity=library`; B `building=library`; do not match `amenity=public_bookcase` | B `library`; P `library` | B/P/S/R; a campus/tenant library does not own the whole building |
| Golf course | S `leisure=golf_course`; mapped `golf=hole|tee|green|fairway|bunker|rough|driving_range` components; `sport=golf` corroborates, not a course boundary | Base LandUse `golf_course|fairway|green|rough|driving_range`; P `golf_course`; clubhouse B independent | S/R + L hole/paths and component areas; no invented 18-hole layout |
| Cemetery / graveyard | S `landuse=cemetery` or `amenity=grave_yard`; `religion=*` optional; graves/paths separate | Base LandUse `cemetery|grave_yard`; P `cemetery` | P/S/R; a point cannot supply burial-ground extent |
| Community / cultural building | P/B/S `amenity=community_centre|arts_centre|theatre` or `tourism=museum`; B form independent | P `community_center|museum|theatre_venue`; B broad `civic|public` | B/P/S/R; no thematic exhibition/public-art inference |
| Post office | P/B `amenity=post_office`; B `building=post_office`; `amenity=post_box` excluded | B `post_office`; P `post_office`, basic `shipping_or_delivery_service` | B/P; tenant counter is not a whole postal depot |
| Industrial / warehouse | B `building=industrial|warehouse|factory|manufacture`; S `landuse=industrial`; `industrial=*` or `man_made=works` further evidence | B `industrial|warehouse|factory|manufacture`; Base LandUse `industrial`; P `warehouse` is storage service, not every factory | B/S/R; warehouses and former factories can have other current occupants |
| Utility site / tower | `power=plant|substation`; `man_made=water_tower|water_works|wastewater_plant|pumping_station`; separate `height=*`, `building=*` | Base Infrastructure `plant|substation|water_tower`; no one Places equivalent for all utility structures | P/S/R/B; node identity without surveyed dimensions stays metadata |

Faith metadata never selects religious symbols or a stereotyped roof. `religion`/`denomination` are preserved only with their actual feature; explicitly mapped components determine architecture. Overture’s `religious_organization` is broader than a place of worship. [Religion](https://wiki.openstreetmap.org/wiki/Key:religion), [denomination](https://wiki.openstreetmap.org/wiki/Key:denomination), [worship](https://wiki.openstreetmap.org/wiki/Tag:amenity=place_of_worship).

For grounds versus buildings, follow [hospital](https://wiki.openstreetmap.org/wiki/Tag:amenity=hospital), [school](https://wiki.openstreetmap.org/wiki/Tag:amenity=school), [university](https://wiki.openstreetmap.org/wiki/Tag:amenity=university), [station](https://wiki.openstreetmap.org/wiki/Tag:railway=station), [platform](https://wiki.openstreetmap.org/wiki/Tag:railway=platform), [rail yard](https://wiki.openstreetmap.org/wiki/Tag:railway=yard) and [golf course](https://wiki.openstreetmap.org/wiki/Tag:leisure=golf_course). Preserve explicit [site relations](https://wiki.openstreetmap.org/wiki/Relation:site) and [stop-area relations](https://wiki.openstreetmap.org/wiki/Relation:public_transport); a multipolygon assembles an area, not an occupancy assignment. Overture Base equivalents were verified in [LandUseClass](https://docs.overturemaps.org/schema/reference/base/types/land_use_class/) and [InfrastructureClass](https://docs.overturemaps.org/schema/reference/base/types/infrastructure_class/).

## 2. Measured local coverage

### Scope and denominator

The census reads the **eight manifest cores**, not entire cities or every context-ring source. It uses held `osm.json`, available `osm-relations.json` (3 areas), and Overture Buildings (4 areas), with exact WGS84 ECEF→east/north projection matching `LocalFrame`. Tagged points must lie inside the rectangle; polygons use the centroid of their largest outer component and line features use their vertex mean. **This is an anchor-based census:** a large site intersecting a core whose anchor lies outside is not counted. Core data buffers and the full-extract totals are distinguished below. No national prevalence or unobserved missing-feature estimate follows from these numbers.

Deduplicate each `(OSM type, ID)` and GERS ID; assemble closed outer/inner multipolygon rings; suppress constituent-way duplicates of a classified relation; exclude building parts from whole-building denominator. For the source view retain the richer duplicate when tags do not conflict. A separate last-record-wins run measures the existing parser loss. There are **0 duplicate tag-value conflicts** in these inputs. Overture joins drop records with an OSM source, drop centroids inside any held OSM building/part, retain the largest polygon and require ≥1 m². This reconstructs a census, not `WorldBuild.generate` or its final roles/cleaning. P2’s three whole-building denominators reproduce exactly; other core denominators are not claimed as generated counts.

**B/P/S** counts are unique source records carrying the type, not unique real-world institutions: a school site, its roofs and a labelled node may describe the same institution. We do not add these together as institutional prevalence. **P** means the classification exists only on that separate point, even if the point can be associated to an untagged outline. **S** includes site, land use and platform area without `building=*`; it is not “a building with missing roof geometry.” Points inside footprints and distinct associated-building counts are given separately. Relation geometry failure is not re-labelled as a point/site success.

| Core | All census buildings | OSM | Added Overture | Same census with parser last-wins | Classified point records: unique host / no host |
| --- | --- | --- | --- | --- | --- |
| Sloan | 1399 | 1399 | 0 | 1399 | 4 / 0 |
| Lakeview | 2823 | 2799 | 24 | 2823 | 7 / 0 |
| Wilmette | 1258 | 46 | 1212 | 1258 | 0 / 0 |
| West Highland | 2496 | 2496 | 0 | 2496 | 4 / 0 |
| Greenville | 678 | 678 | 0 | 671 | 10 / 0 |
| Evanston | 887 | 887 | 0 | 887 | 1 / 0 |
| Kenilworth | 816 | 16 | 800 | 816 | 3 / 2 |
| Winnetka | 581 | 48 | 533 | 581 | 8 / 2 |

Census total **10,938 buildings = 8,369 OSM + 2,569 added Overture**; last-wins total **10,931**. All Overture records retained here lack `class`; no new civic/use label is supplied by those extra footprints. The denominator includes generic houses/garages: it is not “potential civic buildings.”

### Every type, every core

Cell format **total tagged records (B/P/S)**. All matched core L and unresolved-X counters are **0**; the missing multipolygon described below is untyped. Zero means no qualifying held record under the stated scope, not no real feature. Clinics/practices include doctors and dentists; subdivisions follow.

| Type | Sloan | Lakeview | Wilmette | West Highland | Greenville | Evanston | Kenilworth | Winnetka |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| worship | 0 (0/0/0) | 4 (2/2/0) | 3 (3/0/0) | 1 (1/0/0) | 16 (12/1/3) | 5 (4/0/1) | 2 (2/0/0) | 4 (1/2/1) |
| hospital | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (1/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| clinic | 3 (0/3/0) | 2 (0/2/0) | 0 (0/0/0) | 4 (0/4/0) | 7 (4/3/0) | 0 (0/0/0) | 1 (0/1/0) | 1 (0/1/0) |
| station | 0 (0/0/0) | 2 (1/1/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 2 (1/1/0) | 2 (1/1/0) |
| platform | 0 (0/0/0) | 2 (0/0/2) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 2 (0/0/2) | 2 (0/0/2) |
| rail-yard | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| school | 0 (0/0/0) | 0 (0/0/0) | 4 (2/0/2) | 2 (1/0/1) | 6 (4/0/2) | 3 (2/0/1) | 2 (1/0/1) | 2 (1/1/0) |
| university | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| fire | 0 (0/0/0) | 0 (0/0/0) | 1 (1/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) |
| police | 0 (0/0/0) | 0 (0/0/0) | 1 (1/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) | 1 (0/1/0) |
| townhall | 1 (1/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) | 0 (0/0/0) | 1 (1/0/0) | 1 (1/0/0) |
| courthouse | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| library | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) | 0 (0/0/0) | 1 (1/0/0) |
| golf | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| cemetery | 0 (0/0/0) | 0 (0/0/0) | 1 (0/0/1) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) |
| culture-community | 0 (0/0/0) | 1 (0/1/0) | 1 (1/0/0) | 0 (0/0/0) | 13 (6/4/3) | 0 (0/0/0) | 2 (1/1/0) | 4 (2/2/0) |
| post-office | 1 (0/1/0) | 1 (0/1/0) | 0 (0/0/0) | 1 (1/0/0) | 1 (1/0/0) | 0 (0/0/0) | 1 (1/0/0) | 0 (0/0/0) |
| industrial | 0 (0/0/0) | 1 (1/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) |
| utility | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 0 (0/0/0) | 1 (0/1/0) | 0 (0/0/0) |

**Worship subtype records** (form or explicit faith within the worship match; do not read these as counts of active congregations):

| Subtype | Sloan | Lakeview | Wilmette | West Highland | Greenville | Evanston | Kenilworth | Winnetka |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| church | 0 | 4 | 3 | 1 | 13 | 3 | 2 | 3 |
| synagogue | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| mosque | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| other | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| unspecified | 0 | 0 | 0 | 0 | 3 | 1 | 0 | 1 |

**Local input extent versus core, and form-only labels:**

| Type | All held core-extract records incl. buffer | Core total | B | P | S | B form-only, no use tag | P uniquely in a footprint | Distinct B or point-host buildings |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| worship | 42 | 35 | 25 | 5 | 5 | 2 | 5 | 29 |
| hospital | 2 | 1 | 1 | 0 | 0 | 1 | 0 | 1 |
| clinic | 24 | 18 | 4 | 14 | 0 | 0 | 13 | 17 |
| station | 6 | 6 | 3 | 3 | 0 | 3 | 1 | 3 |
| platform | 8 | 6 | 0 | 0 | 6 | 0 | 0 | 0 |
| rail-yard | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| school | 32 | 19 | 11 | 1 | 7 | 10 | 1 | 12 |
| university | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| fire | 2 | 2 | 1 | 1 | 0 | 0 | 1 | 2 |
| police | 3 | 3 | 1 | 2 | 0 | 0 | 2 | 3 |
| townhall | 4 | 4 | 3 | 1 | 0 | 0 | 1 | 4 |
| courthouse | 3 | 1 | 0 | 1 | 0 | 0 | 1 | 1 |
| library | 3 | 2 | 1 | 1 | 0 | 0 | 1 | 2 |
| golf | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| cemetery | 4 | 2 | 0 | 1 | 1 | 0 | 0 | 0 |
| culture-community | 29 | 21 | 10 | 8 | 3 | 0 | 8 | 15 |
| post-office | 6 | 5 | 3 | 2 | 0 | 0 | 2 | 5 |
| industrial | 2 | 1 | 1 | 0 | 0 | 1 | 0 | 1 |
| utility | 2 | 1 | 0 | 1 | 0 | 0 | 1 | 1 |

The last column unions typed outlines and their same-class point hosts, so it does not double-count a POI and its outline. It still is not an institution count: several roofs can belong to one site. The source-view **41 classified point records** have **37 unique footprint hosts / 0 ambiguous multiple-footprint hosts / 4 no hosts**; some hosts contain different uses, so unique containment alone does not authorize whole-building decoration. The lone hospital outline has `building=hospital` without a current hospital-use tag: **0 current-use-tagged hospitals in the cores**, not proof there is no hospital.

### Plausible but outline-untagged buildings

**U** is the unique outline count missing the named type tag but having at least one of: a uniquely contained typed point; centroid within a typed site; or a tokenized type-name keyword on that outline. It can already have a different type (conflict), and can be former/reused/tenant-only. This is a reproducible **review queue**, not an estimate of true missing buildings. No shape-only proposal is silently added to a specific type. Religion on a school, broad education land, generic government offices and broad rail land are not automatically worship/university/townhall/yard assignments.

| Type | Sloan | Lakeview | Wilmette | West Highland | Greenville | Evanston | Kenilworth | Winnetka | Total U |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| worship | 0 | 1 | 0 | 0 | 2 | 0 | 0 | 3 | 6 |
| hospital | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| clinic | 3 | 2 | 0 | 4 | 3 | 0 | 0 | 1 | 13 |
| station | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| platform | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| rail-yard | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| school | 0 | 0 | 1 | 2 | 4 | 0 | 1 | 1 | 9 |
| university | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| fire | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| police | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 2 |
| townhall | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| courthouse | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| library | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 2 |
| golf | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| cemetery | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| culture-community | 0 | 2 | 0 | 0 | 3 | 0 | 1 | 0 | 6 |
| post-office | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 2 |
| industrial | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| utility | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 1 |

| Type | Point evidence records | Site-membership candidate incidences | Name candidates | Unique outlines within type |
| --- | --- | --- | --- | --- |
| worship | 5 | 2 | 0 | 6 |
| hospital | 0 | 0 | 1 | 1 |
| clinic | 13 | 0 | 0 | 13 |
| station | 0 | 0 | 0 | 0 |
| platform | 0 | 0 | 0 | 0 |
| rail-yard | 0 | 0 | 0 | 0 |
| school | 1 | 6 | 2 | 9 |
| university | 0 | 0 | 0 | 0 |
| fire | 1 | 0 | 0 | 1 |
| police | 2 | 0 | 0 | 2 |
| townhall | 1 | 0 | 0 | 1 |
| courthouse | 1 | 0 | 1 | 2 |
| library | 1 | 0 | 1 | 2 |
| golf | 0 | 0 | 0 | 0 |
| cemetery | 0 | 0 | 0 | 0 |
| culture-community | 5 | 0 | 1 | 6 |
| post-office | 2 | 0 | 0 | 2 |
| industrial | 0 | 0 | 2 | 2 |
| utility | 1 | 0 | 0 | 1 |

The U table has **48 type/outline pairs across 43 distinct outlines**. Evidence columns overlap; two worship points in one footprint count once in U. Examples requiring multi-use review: `greenville-downtown way/43123066` has different typed occupants; `kenilworth-station way/181912760` has townhall outline evidence plus police/community occupants; `winnetka-village-green way/1021399320` hosts both fire and police points. These are test records, never runtime ID rules.

### Gaps in numbers and acquisition limitations

- **0/8 cores** contain a qualified university/college, rail-yard or golf-course record; **0 mosque / 0 other-faith worship records**, with **1 synagogue**. These classes have no local positive validation. There are **0 local Places files / 0 local Overture Base files** in this measured intake; schema capability is not measured coverage.
- **1 held multipolygon lacks required members**, in Winnetka (`osm.json` relation listed in the reproduction output), so its geometry is unresolved. No classified core match is silently manufactured from it. There are **3/8 supplementary relation files**; the other five are absent, not assumed unnecessary. Core query templates select `type=multipolygon` and `type=building`, not all `type=site` or `public_transport=stop_area` relations. Full site/stop membership coverage is therefore **unmeasured in 8/8**.
- Greenville contains **5 classified records followed by untagged duplicates**: `node/574865305`, `way/45207643`, `way/45207654`, `way/308301735`, `way/41979299`. In-core cultural/community records go **13 source-view → 9 last-wins** (B 6→3, P 4→3, S 3→3); one lost classified way is outside the core. Total whole-building census goes **678→671**, since seven core building tags are lost, not only the four class-tagged ways. This is a parser/intake issue, not absence in OSM. No repair is implemented.
- The four Overture files have **5,622 records, 204 with class** (3.63%). All 204 cite OSM; **0 classified non-OSM records**. ML outlines improve geometry coverage but supply **0 independent landmark labels** here. Do not count their OSM-derived labels as a second confirming source.
- No independent ground-truth inventory was joined: **0 verified type-missing truth labels / 0 independently verified negative labels**. Consequently recall, real-world completeness and true heuristic precision are unknown; U=0 cannot prove completeness.

## 3. Regional reliability and what would improve it

| Region / scope | Supported conclusion | Unknown / operational rule |
| --- | --- | --- |
| Eight held US cores | 3 metropolitan regions (Denver, Chicago/North Shore, Greenville), including small incorporated suburbs. Tags, points and footprints demonstrably differ within this sample. | 8 cores; 0 outside-US cores; 0 nonmetropolitan/rural held extracts. Do not extrapolate a national or small-town recall percentage. |
| US generally | A US building-type study attributes many mistakes to scarce/missing OSM metadata; its output is residential/nonresidential, not the civic subclasses here. | No measured US church/hospital/station/school completeness rate established in this research. Overture coverage of each type needs a reference inventory and independent provenance. |
| Small towns / rural areas | Research finds systematic rural/urban quality differences in peer-produced maps. A well-mapped small town can outperform a poorly mapped city; place size is not confidence. | No universal density cutoff or automatic city-only classifier. Require licensed regional references, report omission rate per class, and retain neutral unknowns. |
| Outside US | Global building-footprint research finds large geographic inequalities; German POI validation also finds category-specific completeness and density effects. | Neither building-footprint completeness nor German shopping/business POI completeness is evidence for these civic tags in another country. Country-specific semantic and architectural validation remains 0 here. |

Sources: [US type extraction, de Arruda et al. (2024)](https://arxiv.org/abs/2409.05692), [urban/rural peer-production study (2019)](https://arxiv.org/abs/1908.10954), [global urban footprint completeness, Herfort et al. (2023)](https://www.nature.com/articles/s41467-023-39698-6), [Klinkhardt et al., POI validation in 49 German survey areas](https://publikationen.bibliothek.kit.edu/1000158824/150739297). These studies support caution about uneven coverage; none supplies a current universal completeness percentage for the classes in this report.

After rights review, compare public schools to the [NCES CCD public-school universe](https://nces.ed.gov/ccd/aboutccd.asp) and higher education to [IPEDS’s primarily Title-IV institutional universe](https://nces.ed.gov/statprog/handbook/ipeds.asp); neither defines roof/campus geometry, and CCD does not cover all private schools. Use appropriately licensed health-facility, transit, municipal and local worship inventories where available; their existence and reuse rights have not been established per region here. Outside the US require the corresponding local authoritative source and language-aware tags/keywords. No new facility records were ingested.

A reliable expansion gate needs a preselected independent sample of urban, suburban/small-town and rural sites in each deployment region, with verified identities, negatives and footprint/site associations. Measure per-class precision/recall, unmatched source points, missing outlines, reused/form-only buildings and conflicting occupants separately. No numeric confidence probability or minimum-device cost claim can be calibrated from the present sample.

## 4. Fallback signal selectivity

These are **offline authored hypotheses**, not engine thresholds: large means ≥1,000 m²; elongated means axis-aligned bounding-box ratio ≥3; nearby parking means footprint centroid inside a tagged parking polygon or ≤100 m from its edge. Neither is height, site ownership or occupied frontage. Axis-aligned elongation is rotation-sensitive and is unsuitable as a production rule; any future fit test must be rotation invariant. Site containment uses actual polygon holes. Names use word boundaries and the exact patterns in the reproduction; only English keywords were measured.

To avoid presenting unlabelled buildings as true negatives, report **conditional tag agreement** on outlines with an explicit form/use label; generic `building=yes` without another supported label is excluded from that denominator. Direct house/garage/retail form labels are negative *tag references*, not independently verified occupancy negatives (a house can host a clinic). Match means predicted type-set intersects explicit type-set. Broad predictions can score a match without resolving which class. This is a selectivity proxy, **not actual precision**; 0 independent truth labels were collected.

| Hypothesis | Candidate outlines | Explicit-label subset | Matches / label subset | Unlabelled candidates | Rating / allowed effect |
| --- | --- | --- | --- | --- | --- |
| large-footprint | 213 | 112 | 25/112 (22.3%) | 101 | Low; review only, never classifies |
| large+parking | 183 | 98 | 12/98 (12.2%) | 85 | Low; school/hospital/store/industry overlap |
| large+elongated | 7 | 5 | 0/5 (0.0%) | 2 | No support; 0 matching known labels |
| name-keyword | 40 | 37 | 33/37 (89.2%) | 3 | Corroboration only; selection bias, reuse and multilingual gaps |
| tagged-site | 22 | 19 | 14/19 (73.7%) | 3 | Limited corroboration; does not give every contained roof the site use |

| Name predicts type | Candidate outlines | Explicit-label subset | Same-type tag agreement |
| --- | --- | --- | --- |
| worship | 20 | 20 | 20/20 |
| hospital | 1 | 1 | 0/1 |
| clinic | 0 | 0 | 0/0 — unmeasured |
| station | 0 | 0 | 0/0 — unmeasured |
| platform | 0 | 0 | 0/0 — unmeasured |
| rail-yard | 0 | 0 | 0/0 — unmeasured |
| school | 3 | 2 | 1/2 |
| university | 0 | 0 | 0/0 — unmeasured |
| fire | 1 | 1 | 1/1 |
| police | 1 | 1 | 1/1 |
| townhall | 2 | 2 | 2/2 |
| courthouse | 1 | 0 | 0/0 — unmeasured |
| library | 2 | 2 | 1/2 |
| golf | 0 | 0 | 0/0 — unmeasured |
| cemetery | 0 | 0 | 0/0 — unmeasured |
| culture-community | 5 | 4 | 4/4 |
| post-office | 3 | 3 | 3/3 |
| industrial | 2 | 2 | 0/2 |
| utility | 0 | 0 | 0/0 — unmeasured |

**Contained typed point:** 37/41 point records have exactly one footprint host; four have none and zero fall inside multiple census outlines. This is association availability, not 90.2% classification precision. Count every occupant; conflicts/multi-use remain separate. Boundary-adjacent points, multiple floors, mall suites, parcel-centroid POIs and inaccurate coordinates require explicit review. Do not select the nearest building for an uncontained point. Names and nearby parking cannot resolve an unlinked point.

**Missing exact tag:** a broad `landuse=education|railway|industrial`, `office=government`, nearby parking, roof shape, footprint size or name can supply context/review evidence but cannot invent school level, university, rail yard, courthouse, religion, doors or architectural detail. Typed campus membership should preserve dormitory/garage/library/plant identities. Reliable private Builder annotations may supply an explicit, reversible type with evidence and rights, kept in an overlay rather than silently rewriting OSM.

## 5. Twelve general looks, precedence and mixed use

This is a proposed **12-family cap including unknown**, with semantic subtypes retained as metadata. It is not approval for new visual recipes. All classes use mapped footprint/parts/heights/roof facts; no regional or place-name rule creates a class. Hospitals/clinics, schools/universities and fire/police share modules rather than proliferating architectural stereotypes.

| Look family | Scope |
| --- | --- |
| 01 Worship | Church/synagogue/mosque/other forms, separately stated use; neutral mapped hall if form unknown |
| 02 Medical | Hospital institution mass or clinic/practice frontage within its known host |
| 03 Education / campus | School/kindergarten/college/university components plus separately bounded grounds |
| 04 Public safety | Fire/police; service-mass variation only with observed bays/geometry |
| 05 Civic / library / postal | Townhall/courthouse/library/post office; institutional mass or tenant frontage |
| 06 Rail station / platform | Mapped station mass and separately mapped platform/shelter |
| 07 Rail yard | Actual yard surface and track layout; no fabricated switch fan or depot |
| 08 Golf | Mapped course and mapped green/fairway/bunker regions; no generic 18-hole pattern |
| 09 Cemetery | Mapped burial grounds/paths; graves only when mapping or approved evidence supplies their extent |
| 10 Community / culture | Community/arts/theatre/museum building or tenant; ordinary civic mass, no public-art replicas |
| 11 Industrial / utility | Mapped warehouse/factory masses and separately mapped plant/substation/tower components |
| 12 Unknown neutral | Actual mass/roof or plain mapped site surface; a geometry-less point remains metadata |

Proposed precedence, **per semantic axis**, not a destructive single winning label:

1. **Validity/lifecycle:** reject invalid geometry and non-buildings; distinguish active use from standing former form and construction. `building=no`, demolished objects and unsupported underground geometry cannot become a surface building. Do not convert disused worship into an active congregation.
2. **Observed geometry/form:** outline/building parts, measured roof/height/entrances and direct `building=*` or rights-cleared Overture Buildings class establish physical form. Parts compose the parent once. Broad `civic|public|transportation|medical` does not select a finer class.
3. **Explicit current use:** direct `amenity`/`healthcare`/`education`/rail use on that footprint establishes use. Apply documented parent-child relationships, e.g. hospital versus generic medical, without letting match count decide priority. Equally specific incompatible uses remain a set plus conflict; unknown form persists.
4. **Explicit membership/occupants:** use site/stop-area/building relations and verified occupant association first. A uniquely contained compatible point is a candidate association; require no unresolved alternate occupants/levels and no contradictory outline evidence before treating it as exclusive use. Overture Places must pass the same association and source-independence checks. Its existence confidence is not association or architectural confidence.
5. **Site context and weak signals:** attach campus/golf/yard membership to the site, preserve independent component uses, and retain name/parking/geometry hypotheses for review only. Never infer faith from region or name. Source disagreement retains both provenances and suppresses bespoke detail; it does not pick OSM or Overture blindly.
6. **Look dispatch:** only after approved recipe + required geometry are available. Otherwise unknown-neutral for the missing axis: mapped mass/roof/site persists; no church spire, medical cross, school playground, civic columns, invented hall, platform or yard. Unknown must never automatically become a house or landmark.

**Multi-use:** keep building form, an ordered set of occupant uses, explicit occupied frontage/floor, and site membership separate. Do not recolor every wall for one contained clinic, library or worship point. A police/fire shared host can keep public-safety metadata but gets no invented bays. Known house form reused as worship keeps its house form; semantically unknown form stays neutral. Public-facing modules require an evidenced frontage; unsupported subdivision stays metadata. Split or mixed-use classification must be deterministic under input reordering and coordinate translation. Store rule/version, IDs, source release/licence, direct/associated/inferred status, conflicts, and missing geometry/look reason for native and baked web equally.

## 6. A11 licensing flag — not legal advice

Using Overture does **not** remove OSM attribution or existing ODbL obligations. The current official page identifies **Buildings and Base as ODbL themes** with upstream notices; Places has provider-specific notices including **CDLA-Permissive-2.0, Apache-2.0 (Foursquare) and CC0 (AllThePlaces)**. It is incorrect to call all Overture or all Places “CDLA.” Pin the exact release/theme/provider, retain property-level source provenance, and include the applicable notices. [Overture attribution/licensing](https://docs.overturemaps.org/attribution/).

CDLA 2.0 §2.1 requires its agreement text with shared Data, while §3.1 treats Results differently; counsel must decide which outputs are Data versus Results and account for other providers’ terms. [CDLA 2.0](https://cdla.dev/permissive-2-0/). ODbL distinguishes collective and derivative databases and has public-use attribution/share-alike/offer provisions; attaching a new class to an OSM outline and distributing that enriched database should **not be assumed** an independent collective layer merely because it began as a separate point source. A11 must assess the actual join and exported product. [ODbL §§1,4](https://opendatacommons.org/licenses/odbl/1-0/), [OSMF collective-database guidance](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline).

**Flag for A11 A1/A3/A4/A7/A8:** confirm notices and class-enrichment/alterations offer for web, iOS and offline packages; classify separate versus conflated databases; decide how private Builder annotations and sensitive-site metadata are retained/exported; check regional building/landmark/output rights. This report neither clears a new source nor changes [A11’s external-release RED gate](../legal/lawyer-brief-v1.md). R’s decision permits private building; external release remains under that brief. No Places/Base records or personal contributor metadata were ingested here.

## 7. Minimum visual cues for the later design brief

These are **recognition hypotheses**, not surveyed facts, approved looks or measured scores. Heights 40/150/600 m refer to the existing oblique ladder; visibility also depends on FOV, angle, object size and occlusion. Preserve real scale; do not enlarge a chapel or add a dome for recognition. Many civic and tenant uses are **not distinguishable from geometry at 600 m**, and some are not distinguishable even at 40 m without forbidden readable signs. The honest far result is broad mapped form/site continuity, not guaranteed identity. Religious symbols, agency logos, readable signs, branded colors and public art are excluded.

| Family | 40 m — checkable cues | 150 m — checkable cues | 600 m — checkable cues / limit | Reference / gap |
| --- | --- | --- | --- | --- |
| 01 Worship | Mapped roof/hall proportions; mapped tower/dome only when supplied; entrance recession only with evidence | Hall versus ancillary masses; major mapped roof silhouette; ground contact | Mapped hall/tower silhouette if it resolves; otherwise ordinary mass, faith unidentifiable | Generic worship sheet missing; religious landmark studies are not generic templates |
| 02 Medical | Hospital wings/entries only when mapped; broad matte façade rhythm; clinic keeps host scale | Mapped connected masses; existing parking/access arrangement; avoid invented helipad | Large complex silhouette/site layout; small clinic has no reliable semantic cue | Medical/clinic generic sheet missing |
| 03 Education / campus | Separate mapped classroom/hall roofs; paths; mapped yard/pitch boundaries | Roof grouping, courtyard/quad only if bounded; building-to-open-space organization | Campus/open-space composition and mass cluster; no invented football stadium | Campus-01/02/03 Builder concepts; school-specific calibrated sheet missing |
| 04 Public safety | Fire bays if evidenced; modest station mass; police keeps ordinary institutional entrance | Mapped service apron and building profile; broad wall/roof separation | Mapped service compound if large enough; fire/police identity generally unresolved | Generic fire/police sheet missing |
| 05 Civic / library / postal | Mapped entrance, window bands and roof; library/postal tenant frontage only where known | Actual public-building mass and forecourt, if mapped; no inferred columns | Actual roof/block profile; specific public service normally indistinguishable | Generic townhall/court/library/postal sheets missing |
| 06 Rail station / platform | Mapped platform edge, rail alignment, station roof; shelter only with footprint | Platform/track/station relationship; repeated mapped shelter rhythm | Long mapped platform and rail corridor continuity; station roof only if visible | Infrastructure rail-05-station and rail-02-commuter, scope preserved |
| 07 Rail yard | Mapped parallel tracks/switches; neutral ballast; separately mapped sheds | Actual track fan and yard extent; industrial roof spacing | Rail corridor/yard pattern; coarse surfaces and major roofs | Infrastructure rail-04-yard; no yard positive in held cores |
| 08 Golf | Mapped green/fairway/bunker contrast; broad mowing tone; mapped paths | Actual hole/rough/water topology; restrained surface boundaries | Large green corridors/rough pattern; coarse mapped greens, no invented course | Infrastructure land-01-golf; no held-core positive |
| 09 Cemetery | Mapped paths and enclosing edge; graves only with supported data; subdued ground palette | Mapped path-grid and tree/open-space grouping; no invented burial rows | Grounds outline/path structure; can remain semantically ambiguous | Infrastructure land-03-cemetery |
| 10 Community / culture | Actual hall/entry/roof; restrained window rhythm; no art replica or theater marquee | Mapped hall versus ancillary masses; mapped forecourt/courtyard | Large hall roof grouping if visible; ordinary civic mass otherwise | Generic community/museum sheet missing; venue concepts are not universal halls |
| 11 Industrial / utility | Mapped shed roof and loading openings only with evidence; utility enclosure/tank/tower facts | Actual long roofs, tanks or tower silhouettes; mapped service surface | Large industrial footprints/tall utility forms; small plant nodes invisible | Infrastructure utility-03-substation / utility-04-water-tower; warehouse/factory generic sheet missing |
| 12 Unknown neutral | Mapped footprint/roof/height estimate with provenance; matte unmarked mass | Broad mass/material families; ground contact; no invented use cues | Mapped silhouettes/site extent and context continuity; no identity promise | Calibration/REFERENCE-MAP mass/material traits only, no semantic target |

[Infrastructure kit README](../proposals/infrastructure-kit-v1/README.md) provides street/aerial/far sheets and sparse real-scale detail. [Venues/campuses STATUS](../proposals/venues-campuses-v1/STATUS.md) is approved **for Builder after the look gate**, not an engine-now campus default. Its aerial concepts are not cadastral plans. No images were opened or created in this task: only the registry, sheet text and approval scope were read. Later implementation needs the full feature-specific mocks, matched aerial/site targets and independent native/web A3 evidence under [DECISIONS](../tracking/DECISIONS.md).

## 8. Source hashes, reproducibility and diagnostic records

All inputs below are read-only held files under `~/Desktop/world-engine/Data/areas/<area>/`. Hashes pin this census; manifests do not substitute for independent truth. Context files were not included. Local raw data remains ignored and is not republished here. Map data © OpenStreetMap contributors; held Overture files retain their recorded ODbL/source credits.

| Held area | Input | SHA-256 |
| --- | --- | --- |
| sloans-lake | manifest.json | `6acbac6bbceb519d42a7d7b45ce41d01e48e164dcefc111ae2f52e5ab08b7958` |
| sloans-lake | osm-relations.json | `cb25189cc7fd6262bc410bd070e2e045b17d01d76b011375dd46c85d3ab91115` |
| sloans-lake | osm.json | `e243d5eeffaa62c1329e4b53eb3d200823c7c7106648c7aeade1e951e280f2e2` |
| lakeview-sheil-park | manifest.json | `722271ac3a595568511a2bad07a80d03725c729c45ece106d3d13335ef6411db` |
| lakeview-sheil-park | osm-relations.json | `f2e60870ffc123c129515686464e6425c53489b89bbce3f66f1d92c6daea1e83` |
| lakeview-sheil-park | osm.json | `459c2e9d6b618480c559192bff31ee82a99ea2858ac9c3d027397c5ab96353d1` |
| lakeview-sheil-park | overture-buildings.json | `a2565932a42988c49d6db33b538d4aa7cf3deb7c96644dcede10ac99d4e203d5` |
| wilmette-vattmann-park | manifest.json | `a9cf314b1e43e700741d115130d556feb7aa71742a71a024cdf0ae27e9ff8f36` |
| wilmette-vattmann-park | osm.json | `caf073adb929029bdd23b07817b59d683601a8b21e0e8e51319135886c778a0c` |
| wilmette-vattmann-park | overture-buildings.json | `5a743f33d5112b722d03b7e170b548f7c1796fb5573fb70aac715e100786aea6` |
| west-highland | manifest.json | `f9f54e254cc743ea93d34612a4afed7784dc25809d5d65ef4196b6662b9bc5fb` |
| west-highland | osm.json | `34b5c95e12301dacf26e1ace5d1ebd6ac2908c954acb7323e8a8e2cea465a112` |
| greenville-downtown | manifest.json | `91d0ca16fd967f903b7466a7ad3d4e5a7cd20d09e4912c5dd6cdfefa5b30ff42` |
| greenville-downtown | osm.json | `0a398a41538f7a936df2bfcede27437c1bd63778468eb9a308237045dddee5dd` |
| evanston-south | manifest.json | `0a2d65fdb85a86c28b83dd806517088e88aa09c135917d9d70558deb07cc4590` |
| evanston-south | osm-relations.json | `4640da6cc792b826609374772a45ca9f394603afb11894150eca6b72e5aa8002` |
| evanston-south | osm.json | `88c434aba48ad002c9b94da94987c6f0347d136982fdc4fbbddcedb9c3bc76ad` |
| kenilworth-station | manifest.json | `09964a08f6ee692f179ef2c46850722aa99c28831ce740c3db36fcdd6c82f6e4` |
| kenilworth-station | osm.json | `4f0ee921a5508cb1387ce55e3bd38112adf593091a3ca586f3ac5334083581fa` |
| kenilworth-station | overture-buildings.json | `4ded5e59390ef7f501053f2fa74fba86fd6a8d415496794bf067eefb7a878b01` |
| winnetka-village-green | manifest.json | `9fd9fd1fde45e2987848842a36c05467b81813bbb0290345e17177772089d683` |
| winnetka-village-green | osm.json | `21437f9384d79fdbb8257d17cd848466b1cee64fa4b34dd84226565eeb082123` |
| winnetka-village-green | overture-buildings.json | `9d88afa98eb6cffa4df39178dbdd255f16fae60546cbc0e0549c418dfdadf477` |

| Area | Manifest core width × height (m) | Missing geometry refs |
| --- | --- | --- |
| sloans-lake | 1600 × 1200 | none |
| lakeview-sheil-park | 1000 × 1000 | none |
| wilmette-vattmann-park | 1000 × 1000 | none |
| west-highland | 1000.0000000004095 × 999.9999999994932 | none |
| greenville-downtown | 1280.4009746213958 × 1885.9423424556935 | none |
| evanston-south | 1000 × 1000 | none |
| kenilworth-station | 1000 × 1000 | none |
| winnetka-village-green | 1000 × 1000 | relation/1205149 |

Taxonomy metadata (no feature records downloaded):

| Official metadata | SHA-256 |
| --- | --- |
| https://docs.overturemaps.org/taxonomy/2026-09-23.0/taxonomy.csv | `59eecbf9e24859bcdab459e8efeea673b7fcbab06b45bd1c7067f215b3bc25d4` |
| https://docs.overturemaps.org/taxonomy/2026-09-23.0/basic_categories.csv | `c0aed53113a825240d71b981746f5296b88a2bb20005528b104045c3c97b7afc` |

**U review identifiers** (provenance/test evidence, not allowed dispatch keys):

| Area | Missing outline type | Candidate source refs |
| --- | --- | --- |
| sloans-lake | clinic | `way/219064060`, `way/219064062`, `way/554051044` |
| sloans-lake | hospital | `way/329063174` |
| sloans-lake | post-office | `way/329065013` |
| lakeview-sheil-park | clinic | `way/209905048`, `way/209906066` |
| lakeview-sheil-park | culture-community | `way/150640081`, `way/209904732` |
| lakeview-sheil-park | post-office | `way/209904706` |
| lakeview-sheil-park | worship | `way/210328808` |
| wilmette-vattmann-park | school | `way/45208027` |
| west-highland | clinic | `way/325875164`, `way/391051763`, `way/413977253`, `way/421499355` |
| west-highland | school | `way/419516004`, `way/804606825` |
| greenville-downtown | clinic | `way/43123062`, `way/43123066`, `way/43592288` |
| greenville-downtown | courthouse | `way/43592303`, `way/809837890` |
| greenville-downtown | culture-community | `way/43123066`, `way/45122738`, `way/48158311` |
| greenville-downtown | industrial | `way/43592301`, `way/306700093` |
| greenville-downtown | library | `way/48158271` |
| greenville-downtown | school | `way/45207674`, `way/302123776`, `way/904324184`, `way/1562985033` |
| greenville-downtown | townhall | `way/45207651` |
| greenville-downtown | worship | `way/43123066`, `way/45207636` |
| evanston-south | library | `relation/17972395` |
| kenilworth-station | culture-community | `way/181912760` |
| kenilworth-station | police | `way/181912760` |
| kenilworth-station | school | `overture/fbac4261-92d0-4bd4-a55d-37ff036f2585` |
| kenilworth-station | utility | `overture/e3f673ec-de1b-41a3-8197-ce55dc2eb4e2` |
| winnetka-village-green | clinic | `overture/11456041-f17f-463c-9c63-fc112d202443` |
| winnetka-village-green | fire | `way/1021399320` |
| winnetka-village-green | police | `way/1021399320` |
| winnetka-village-green | school | `way/763202907` |
| winnetka-village-green | worship | `overture/c75df3fd-b1b1-4abf-a49f-1957a108ff7e`, `way/184364623`, `way/763202907` |

### Reproduce without builds, downloads or captures

Save the fenced Python below to a temporary file, then run:

```sh
python3 /tmp/landmark-census.py ~/Desktop/world-engine/Data/areas source > /tmp/landmark-source.json
python3 /tmp/landmark-census.py ~/Desktop/world-engine/Data/areas last > /tmp/landmark-last.json
```

The output contains count buckets, source hashes, association/candidate refs and all signal rows. It emits no source names, contact fields or contributor metadata. `source` retains richer non-conflicting duplicates; `last` reproduces dictionary overwrite. This is report-contained measurement code, not a committed pipeline/runtime change. English-only name patterns, anchor extent and no independent truth labels are intentional declared limitations.

```python
import json, math, hashlib, re, sys, collections
from pathlib import Path
ROOT=Path(sys.argv[1]).expanduser() if len(sys.argv)>1 else Path.home()/'Desktop/world-engine/Data/areas'
AREAS=['sloans-lake','lakeview-sheil-park','wilmette-vattmann-park','west-highland','greenville-downtown','evanston-south','kenilworth-station','winnetka-village-green']
MODE=sys.argv[2] if len(sys.argv)>2 else 'source'
TYPES=['worship','hospital','clinic','station','platform','rail-yard','school','university','fire','police','townhall','courthouse','library','golf','cemetery','culture-community','post-office','industrial','utility']
KW={'worship':r'\b(church|chapel|cathedral|synagogue|mosque|masjid|temple|worship)\b','hospital':r'\bhospital\b','clinic':r'\b(clinic|medical center|medical centre|health center|health centre|urgent care)\b','station':r'\b(railway station|train station|railroad station|depot)\b','school':r'\b(school|academy)\b','university':r'\b(university|college|campus)\b','fire':r'\b(fire station|fire department|firehouse)\b','police':r'\b(police|sheriff)\b','townhall':r'\b(town hall|townhall|city hall|village hall|municipal hall)\b','courthouse':r'\b(courthouse|court house)\b','library':r'\blibrary\b','golf':r'\bgolf\b','cemetery':r'\b(cemetery|graveyard|grave yard)\b','culture-community':r'\b(museum|community center|community centre|theatre|theater)\b','post-office':r'\bpost office\b','industrial':r'\b(warehouse|factory|manufacturing)\b','utility':r'\b(water tower|substation|power plant|water treatment|wastewater)\b'}
def classes(t):
 a=t.get('amenity');b=t.get('building');h=t.get('healthcare');l=t.get('landuse');r=t.get('railway');out=set()
 if a=='place_of_worship' or b in {'church','chapel','cathedral','synagogue','mosque','temple','shrine','religious','monastery'} or l=='religious':out.add('worship')
 if a=='hospital' or h=='hospital' or b=='hospital':out.add('hospital')
 if a in {'clinic','doctors','dentist'} or h in {'clinic','doctor','dentist'}:out.add('clinic')
 if r in {'station','halt'} or b=='train_station' or (t.get('public_transport')=='station' and (t.get('train')=='yes' or r)):out.add('station')
 if r=='platform' or (t.get('public_transport')=='platform' and (t.get('train')=='yes' or r)):out.add('platform')
 if r=='yard' or (r in {'rail','light_rail','narrow_gauge'} and t.get('service')=='yard'):out.add('rail-yard')
 if a in {'school','kindergarten'} or t.get('education') in {'school','kindergarten'} or b in {'school','kindergarten'}:out.add('school')
 if a in {'university','college'} or t.get('education') in {'university','college'} or b in {'university','college'}:out.add('university')
 if a=='fire_station' or b=='fire_station':out.add('fire')
 if a=='police':out.add('police')
 if a=='townhall' or b=='townhall':out.add('townhall')
 if a=='courthouse':out.add('courthouse')
 if a=='library' or b=='library':out.add('library')
 if t.get('leisure')=='golf_course':out.add('golf')
 if l=='cemetery' or a=='grave_yard':out.add('cemetery')
 if a in {'community_centre','arts_centre','theatre'} or t.get('tourism')=='museum':out.add('culture-community')
 if a=='post_office' or b=='post_office':out.add('post-office')
 if b in {'industrial','warehouse','factory','manufacture'} or l=='industrial':out.add('industrial')
 if t.get('power') in {'plant','substation'} or t.get('man_made') in {'water_tower','water_works','wastewater_plant','pumping_station'}:out.add('utility')
 return out

def active(t):return not any(t.get(k) in {'yes','true','1'} for k in ['disused','abandoned','demolished','razed','construction']) and t.get('building') not in {'no','construction','ruins'} and t.get('historic')!='ruins'
def area(r):return abs(sum(x*y1-x1*y for (x,y),(x1,y1) in zip(r,r[1:]+r[:1])))/2

def centroid(r):
 z=sum(x*y1-x1*y for (x,y),(x1,y1) in zip(r,r[1:]+r[:1]))
 if abs(z)<1e-10:return tuple(sum(p[i] for p in r)/len(r) for i in (0,1))
 return tuple(sum((p[i]+q[i])*(p[0]*q[1]-q[0]*p[1]) for p,q in zip(r,r[1:]+r[:1]))/(3*z) for i in (0,1))
def inside(p,r):
 x,y=p;v=False
 for (a,b),(c,d) in zip(r,r[1:]+r[:1]):
  if (b>y)!=(d>y) and x<(c-a)*(y-b)/(d-b)+a:v=not v
 return v

def contains(p,g):return any(inside(p,o) and not any(inside(p,h) for h in hs) for o,hs in g)
def anchor(g):return centroid(max(g,key=lambda z:area(z[0]))[0])
def size(g):return sum(area(o)-sum(area(h) for h in hs) for o,hs in g)
def bounds(g):
 pts=[p for o,_ in g for p in o];return (min(p[0] for p in pts),min(p[1] for p in pts),max(p[0] for p in pts),max(p[1] for p in pts))
def edge_distance(p,g):
 def dist(a,b):
  v=(b[0]-a[0],b[1]-a[1]);w=(p[0]-a[0],p[1]-a[1]);den=v[0]**2+v[1]**2;t=max(0,min(1,(v[0]*w[0]+v[1]*w[1])/den)) if den else 0
  return math.hypot(w[0]-t*v[0],w[1]-t*v[1])
 return min(dist(a,b) for o,_ in g for a,b in zip(o,o[1:]+o[:1]))
def stitch(parts):
 parts=[list(p) for p in parts];rings=[]
 while parts:
  chain=parts.pop(0)
  while chain[0]!=chain[-1]:
   hit=False
   for i,p in enumerate(parts):
    if chain[-1]==p[0]:chain+=p[1:]
    elif chain[-1]==p[-1]:chain+=p[-2::-1]
    elif chain[0]==p[-1]:chain=p[:-1]+chain
    elif chain[0]==p[0]:chain=p[:0:-1]+chain
    else:continue
    parts.pop(i);hit=True;break
   if not hit:return None
  if len(chain)<4:return None
  rings.append(chain[:-1])
 return rings

def run(name):
 path=ROOT/name;m=json.loads((path/'manifest.json').read_text());lat=m['center']['latitude'];lon=m['center']['longitude'];w=m['widthMeters'];h=m['heightMeters']
 def core(p):return -w/2<=p[0]<=w/2 and -h/2<=p[1]<=h/2
 a=6378137.;e2=(1/298.257223563)*(2-1/298.257223563)
 def ecef(la,lo):
  la=math.radians(la);lo=math.radians(lo);n=a/math.sqrt(1-e2*math.sin(la)**2)
  return n*math.cos(la)*math.cos(lo),n*math.cos(la)*math.sin(lo),n*(1-e2)*math.sin(la)
 origin=ecef(lat,lon);la=math.radians(lat);lo=math.radians(lon)
 def xy(c):
  p=ecef(c[1],c[0]);dx,dy,dz=[p[i]-origin[i] for i in range(3)]
  return -math.sin(lo)*dx+math.cos(lo)*dy,-math.sin(la)*math.cos(lo)*dx-math.sin(la)*math.sin(lo)*dy+math.cos(la)*dz
 files=[path/'osm.json']
 if (path/'osm-relations.json').exists():files.append(path/'osm-relations.json')
 hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [path/'manifest.json',*files]};raw=[]
 for p in files:raw+=json.loads(p.read_text())['elements']
 # Source view retains richer non-conflicting tag records; loader view is last-wins.
 els={};loss=0;tag_conflicts=0;loss_refs=[]
 for e in raw:
  key=(e['type'],e['id'])
  if key in els:
   before=els[key].get('tags',{});after=e.get('tags',{})
   if classes(before)-classes(after):loss+=1;loss_refs.append(f'{key[0]}/{key[1]}')
   conflicts={k for k in set(before)&set(after) if before[k]!=after[k]};tag_conflicts+=bool(conflicts)
   if MODE=='source' and not conflicts and len(before)>len(after):continue
  els[key]=e
 nodes={k[1]:xy((e['lon'],e['lat'])) for k,e in els.items() if k[0]=='node' and 'lon' in e}
 ways={k[1]:e for k,e in els.items() if k[0]=='way'};geoms={};bad=set();memberways=set();relationstats=collections.Counter()
 for key,e in els.items():
  if key[0]!='way':continue
  ids=e.get('nodes',[])
  if len(ids)>=4 and ids[0]==ids[-1]:
   if all(i in nodes for i in ids):geoms[key]=[([nodes[i] for i in ids[:-1]],[])]
   else:bad.add(key)
 for key,e in els.items():
  if key[0]!='relation' or e.get('tags',{}).get('type')!='multipolygon':continue
  relationstats['multipolygon']+=1;parts={'outer':[],'inner':[]};complete=True
  for mem in e.get('members',[]):
   if mem['type']!='way':continue
   we=ways.get(mem['ref']);role=mem.get('role') or 'outer'
   if role not in parts:continue
   if not we or not all(i in nodes for i in we.get('nodes',[])):complete=False;break
   parts[role].append(we['nodes'])
  outer=stitch(parts['outer']) if complete and parts['outer'] else None;inner=stitch(parts['inner']) if complete else None
  if outer is None or inner is None:bad.add(key);continue
  os=[[nodes[i] for i in r] for r in outer];ins=[[nodes[i] for i in r] for r in inner]
  geoms[key]=[(o,[r for r in ins if inside(r[0],o)]) for o in os]
  if e.get('tags',{}).get('building') not in {None,'no'} or classes(e.get('tags',{})):memberways.update(mem['ref'] for mem in e['members'] if mem['type']=='way')
 buildings={}
 for key,g in geoms.items():
  e=els[key];t=e.get('tags',{})
  if t.get('building') not in {None,'no'} and t.get('building:part') is None and active(t) and core(anchor(g)) and not (key[0]=='way' and key[1] in memberways):buildings[key]={'g':g,'t':t,'classes':classes(t),'area':size(g),'source':'OSM'}
 osmcount=len(buildings);overturecount=0;osmdrop=0;inside_osm=0
 osm_footprints=[g for k,g in geoms.items() if els[k].get('tags',{}).get('building') not in {None,'no'} or els[k].get('tags',{}).get('building:part') not in {None,'no'}]
 op=path/'overture-buildings.json';ostats={}
 if op.exists():
  hashes[op.name]=hashlib.sha256(op.read_bytes()).hexdigest();od=json.loads(op.read_text());ostats={'records':len(od['buildings']),'class_present':sum(bool(b.get('class')) for b in od['buildings']),'subtype_present':sum(bool(b.get('subtype')) for b in od['buildings']),'release':od['release']}
  for b in od['buildings']:
   if any(s.get('dataset')=='OpenStreetMap' for s in b.get('sources',[])):osmdrop+=1;continue
   g=[([xy(c) for c in poly[0]],[[xy(c) for c in ring] for ring in poly[1:]]) for poly in b['polygons'] if poly and poly[0]]
   if not g:continue
   g=[max(g,key=lambda v:size([v]))]
   if not core(anchor(g)):continue
   if any(contains(anchor(g),other) for other in osm_footprints):inside_osm+=1;continue
   if size(g)<1:continue
   t={'building':b.get('class') or 'yes'};key=('overture',b['id']);buildings[key]={'g':g,'t':t,'classes':classes(t),'area':size(g),'source':'Overture'};overturecount+=1
 full_source=collections.Counter()
 for key,e in els.items():
  if active(e.get('tags',{})) and not (key[0]=='way' and key[1] in memberways):full_source.update(classes(e.get('tags',{})))
 features=[];counts={c:collections.Counter() for c in TYPES};sub=collections.Counter();excluded=collections.Counter()
 for key,e in els.items():
  t=e.get('tags',{});cs=classes(t)
  if not cs:continue
  if not active(t):excluded['inactive']+=1;continue
  if key[0]=='way' and key[1] in memberways:excluded['relation_member']+=1;continue
  if key[0]=='node':p=nodes.get(key[1]);bucket='P' if p and core(p) else None
  elif key in geoms:p=anchor(geoms[key]);bucket=('B' if key in buildings else 'S') if core(p) else None
  elif key[0]=='way' and all(i in nodes for i in e.get('nodes',[])) and e.get('nodes'):
   pts=[nodes[i] for i in e['nodes']];p=tuple(sum(q[i] for q in pts)/len(pts) for i in (0,1));bucket='L' if core(p) else None
  else:
   # Unassembled relations/missing nodes cannot be assigned confidently to core.
   p=None;bucket='X'
  if bucket is None:continue
  features.append({'key':key,'t':t,'cs':cs,'bucket':bucket,'p':p,'g':geoms.get(key)})
  for c in cs:
   counts[c][bucket]+=1
   if bucket=='B':
    use=classes({k:v for k,v in t.items() if k!='building'})
    counts[c]['form_only' if c not in use else 'use_on_outline']+=1
  if 'worship' in cs:
   b=t.get('building');relig=t.get('religion')
   cat='church' if b in {'church','chapel','cathedral'} or relig=='christian' else 'synagogue' if b=='synagogue' or relig=='jewish' else 'mosque' if b=='mosque' or relig=='muslim' else 'other' if b in {'temple','shrine','monastery'} or relig not in {None,'','christian','jewish','muslim'} else 'unspecified'
   sub[cat]+=1
 for key,b in buildings.items():
  if key[0]=='overture':
   for c in b['classes']:counts[c]['B']+=1
 # Classification-deficient outline candidates, not estimated real-world prevalence.
 candidates={c:collections.Counter() for c in TYPES};unique_candidates={c:set() for c in TYPES};assoc=collections.Counter();signal=[];class_buildings={c:{k for k,b in buildings.items() if c in b['classes']} for c in TYPES}
 sites=[f for f in features if f['bucket']=='S' and f['g']]
 parking=[g for key,g in geoms.items() if els[key].get('tags',{}).get('amenity')=='parking']
 for f in features:
  if f['bucket']!='P':continue
  hits=[key for key,b in buildings.items() if contains(f['p'],b['g'])]
  assoc['point_'+('unique' if len(hits)==1 else 'ambiguous' if hits else 'unlinked')]+=1
  if len(hits)==1:
   for c in f['cs']:
    counts[c]['P_associated']+=1;class_buildings[c].add(hits[0])
    if c not in buildings[hits[0]]['classes']:candidates[c]['point']+=1;unique_candidates[c].add(hits[0])
 for key,b in buildings.items():
  p=anchor(b['g']);siteclasses=set().union(*(f['cs'] for f in sites if contains(p,f['g']))) if sites else set()
  text=' '.join(str(b['t'].get(k,'')) for k in ['name','name:en','official_name','short_name']);names={c for c,rx in KW.items() if re.search(rx,text,re.I)}
  for c in siteclasses-b['classes']:candidates[c]['site']+=1;unique_candidates[c].add(key)
  for c in names-b['classes']:candidates[c]['name']+=1;unique_candidates[c].add(key)
  bbox=bounds(b['g']);ar=max(bbox[2]-bbox[0],bbox[3]-bbox[1])/max(.01,min(bbox[2]-bbox[0],bbox[3]-bbox[1]))
  # Authored hypotheses for measuring selectivity, not runtime classification.
  big=b['area']>=1000;nearpark=any(edge_distance(p,g)<=100 or contains(p,g) for g in parking)
  labelled=bool(b['classes']) or b['t'].get('building') not in {None,'yes','residential','public','civic'} or bool(b['t'].get('amenity') or b['t'].get('shop') or b['t'].get('office'))
  for label,pred,predict in [('large-footprint',big,{'worship','hospital','school','university','fire','police','townhall','courthouse','library','culture-community','industrial'}),('large+parking',big and nearpark,{'hospital','school','university','fire','police','culture-community','industrial'}),('large+elongated',big and ar>=3,{'station','industrial'}),('tagged-site',bool(siteclasses),siteclasses),('name-keyword',bool(names),names)]:
   if pred:signal.append({'signal':label,'known':labelled,'match':bool(b['classes']&predict),'contradict':bool(b['classes']-predict) and not bool(b['classes']&predict),'predicted':sorted(predict),'actual':sorted(b['classes']),'key':key})
 for c in TYPES:candidates[c]['unique']=len(unique_candidates[c])
 return {'area':name,'hashes':hashes,'source_records':len(raw),'full_extract_class_counts':dict(full_source),'unique_source_records':len(els),'duplicate_class_loss':loss,'tag_conflicts':tag_conflicts,'duplicate_class_loss_refs':loss_refs,'mode':MODE,'core_buildings':len(buildings),'osm_buildings':osmcount,'overture_buildings':overturecount,'overture':ostats,'overture_osm_records_skipped':osmdrop,'overture_inside_osm_skipped':inside_osm,'class_buildings':{c:len(v) for c,v in class_buildings.items()},'counts':{c:dict(counts[c]) for c in TYPES},'candidates':{c:dict(candidates[c]) for c in TYPES},'candidate_refs':{c:[f'{k[0]}/{k[1]}' for k in sorted(v)] for c,v in unique_candidates.items() if v},'worship_subtypes':dict(sub),'point_association':dict(assoc),'geometry_missing':len(bad),'geometry_missing_refs':[f'{k[0]}/{k[1]}' for k in sorted(bad)],'excluded':dict(excluded),'signal_rows':signal,'features':[{'ref':f'{f["key"][0]}/{f["key"][1]}','classes':sorted(f['cs']),'bucket':f['bucket'],'tags':{k:v for k,v in f['t'].items() if k in {'building','amenity','healthcare','religion','denomination','landuse','railway','public_transport','education','leisure','tourism','power','man_made','type'} }} for f in features]}
if __name__=='__main__':
 out=[run(a) for a in AREAS]
 print(json.dumps(out,indent=2,sort_keys=True))
```

Used: P2 classification audit, archetypes §§1–6, REFERENCE-MAP Facades/Ground/Context and infrastructure/campus catalogs, DECISIONS, LocalFrame/OSMDocument/MapFeatureBuilder/OvertureSource, held hashes above, official OSM/Overture schemas and linked completeness/licence sources. Mock: registry and text for infrastructure rail-02/04/05, land-01/03, utility-03/04 and venues campus-01/02/03; no images inspected, new civic mock gaps remain. Deviation: research/census only; no code, renderer change, captures, visual score, calibrated precision or legal clearance.

**Build first:** shared provenance-aware outline/point/site association with conflict-preserving neutral fallback, then the approved mapped station/platform family (3 station outlines and 6 platform areas across 3 held cores), before any shape/name-based civic guess.
