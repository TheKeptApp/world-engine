# Feature archetype registry — execution specification

## Decision and scope

Use a small, versioned **semantic registry plus reusable geometry modules**, not a growing collection of individually designed places. Resolve physical building form, current use, site membership and infrastructure independently. A station gets a station classification and only its mapped building/platform geometry; a school football field gets its mapped pitch and any separately mapped stands; a neighborhood bar gets a modest frontage treatment only where its occupied frontage is known. **Unknown never selects a house, a stadium bowl or an invented landmark.** A known former house can retain explicitly mapped house form when its current use is a bar; unknown form cannot acquire that form from size, name or neighborhood alone. Stage 0b below permits explicitly labelled residential-form inference from combined zone, footprint and exclusion evidence; do not remove the existing shortcut wholesale.

Docs only; inspected main `208bf40`, plus [A8 coverage audit](../review/long-tail-feature-coverage-2026-10-08.md) at `e49b2f0`. No implementation, occurrence census, captures or visual score claimed. The 60-entry inventory below is an **estimated high-frequency US shortlist**, balanced across metros, suburbs and small towns, with uncommon but harmful infrastructure retained. It is not a measured national top-60 ranking. Frequency bands are planning hypotheses; do not convert them into generation weights. A future extract census must measure deduplicated physical features, not raw tag counts, and report coverage separately from real-world prevalence.

## 1. Registry contract and precedence

Proposed record fields: `ruleId`, `version`, `matchAll`, `matchAny`, `exclude`, `geometryKinds`, `semanticAxis`, `specificity`, `archetypeId`, `moduleId`, `requiredGeometry`, `fallbackId`, `confidenceEvidence`, `packSheet`, `approvalScope`, `wikiSources`, `tests`. Resolved output retains source reference, matched/contradictory tags, form/use/site separately, confidence, geometry provenance, omitted details/reason, registry version and source licence. Module IDs below are proposed interfaces, not existing Swift symbols.

Classification runs once in shared map/generator preparation before native rendering and web GLB baking. Keep semantic output and diagnostics in package provenance; web must not re-guess from mesh shape or names. Acquisition, classification, geometry and exported visibility are four distinct coverage counters. A successful tag match is not proof the object was fetched or rendered.

Precedence, evaluated per semantic axis:

1. Respect lifecycle/negative tags and geometry validity first. `building=no` cannot create a building; underground visibility precedes surface modules. Disused use is not active use, although a standing building can remain. [OSM lifecycle documentation](https://wiki.openstreetmap.org/wiki/Lifecycle_prefix).
2. Exact component tags and mapped dimensions outrank broad site context. `building:part` assembly and transport bridge/tunnel modifiers are composed, not discarded by the first successful building match. Height/roof/footprint facts beat pack dimensions. `layer` is ordering, not metres.
3. Within an axis, a more specific compatible conjunction beats its generic parent: `leisure=pitch + sport=american_football` beats generic pitch; `building=train_station` beats unclassified building. Match count alone is not priority. Publish explicit parent relationships; ties with contradictory evidence fall back and retain a conflict diagnostic.
4. Current-use tags (`amenity`, `shop`, etc.) select use, not automatic demolition/replacement of known form. A school site does not make every contained structure a school building. A node inside a mixed-use building does not own its whole façade. Associate only explicit memberships or an unambiguous contained building/occupancy relation; ambiguous associations remain unresolved.
5. Regional residential grammar runs after explicit form tags **or the combined residential-form eligibility rule in Stage 0b**. `building=residential` remains a broad residential mass, not proof of detached form. Preserve the existing `building=yes` shortcut until the look gate passes; subsequently gate it rather than deleting it. Zone, footprint or name alone cannot establish eligibility. Unknown buildings outside residential zones get B.
6. Missing module/geometry/approval selects the declared neutral fallback. Private Builder annotations are an explicit overlay and never silently rewrite the shared base. A separately authorized landmark override requires verified identity/geometry and its own approval; the generic registry contains no named landmark entries.

Confidence is evidence provenance, **not a calibrated probability**:

| Level | Meaning and permitted effect |
|---|---|
| `tag-certain` | Direct supported semantic tag; “certain” means tag-explicit, not ground-truth certainty. Geometry prerequisites still apply. Conflicting tags suppress bespoke detail. |
| `tag+name` | A compatible name corroborates an already tag-selected class. It cannot create a class or promote a generic building into a design. Record corroboration separately; it is not stronger than explicit form evidence. |
| `geometry-inferred` | A candidate has compatible footprint/site geometry. Stage 0b alone permits residential-form inference from its full zone + footprint + exclusion conjunction, labelled `geometry-inferred` (not tag-certain or observed use). Otherwise geometry only corroborates a tag-selected class; no religion, school level, capacity or landmark inference. |
| `unknown` | No qualifying class, unresolved conflict or ambiguous association. Plain mapped mass/line/area as appropriate, or diagnostic omission for a point with no geometry. Never house or invented landmark. |

### Existing edit boundary for a future builder

- `Sources/WorldMap/MapFeatureBuilder.swift`: `classifyWay`, `classifyPolygon`, `buildingType`, `areaKind`, `pointKind`, `lineKind`. Preserve form **and** use rather than letting the building early-return erase site/amenity semantics. Relation handling must not duplicate outline/member geometry.
- `Sources/WorldMap/MapFeatures.swift`: retain resolved semantic/provenance fields without treating unknown as residential. Proposed registry data location: `Sources/WorldMap/Resources/feature-archetypes.json`; confirm resource packaging in the implementation handoff, not an existing file claim.
- `Sources/WorldGen/BuildingGenerator.swift`: `role(of:)` currently maps `building=yes` under 250 m² to house; `role(for:)` widens that to profile `hugeArea`, plus inferred garages. Do not remove the shortcut. Stage 0b, blocked until the look gate passes, adds residential-form eligibility to these routes and audits `part != nil ? .house` in `generate`. The census excludes the larger-footprint promotion and split paths: inventory those separately before changing them, rather than assuming the census measures their impact. Preserve existing garage overrides and explicit houses. Keep mapped roof form even for neutral mass.
- `Sources/WorldGen/SceneGenerator.swift`: use registry dispatch for buildings, sites, lines and points; replace unsupported semantic omission with explicit fallback diagnostics. Audit detached-garage inference and any house splitting upstream so they cannot resurrect unknown houses.
- `Sources/WorldGen/Context/ContextFeatures.swift`, `ContextRing.swift`: share classification/visibility semantics across core/context; detail can differ, identity cannot. `Sources/WorldPackage/WorldPackage.swift`: record registry version/coverage for baked web parity. Audit regionkit extraction filters identified by A8 before expanding classes; do not assume every source extract already includes them.

## 2. Packs, fallback vocabulary and current-behavior key

**I:** [infrastructure-kit-v1](../proposals/infrastructure-kit-v1/STATUS.md), all 48 sheets approved for look; geometry comes from mapped facts and street-geometry rules. Sheet stems below are exact `.html` filenames in that pack. A8 finds only roads-08/09 directly consumed and roads-01 partially consumed; other sheets are not implemented by being approved.

**V:** [venues-campuses-v1](../proposals/venues-campuses-v1/STATUS.md), approved **for Builder phase**, after the look gate. Cited sheets are design references, not authorization to import full venues into the engine now. Reuse neutral mapped geometry first; activating architectural modules needs that phase's gate.

**H1:** [house-archetypes-v1](../proposals/house-archetypes-v1/STATUS.md), approved residential look. **H2:** [house-archetypes-v2](../proposals/house-archetypes-v2/README.md), pending R approval in [proposal INDEX](../proposals/INDEX.md); excluded from implementation until approved. **L:** [landmarks-v1](../proposals/landmarks-v1/README.md) and [landmarks-style-b-v2](../proposals/landmarks-style-b-v2/STATUS.md) inspected; literal `landmarks-v2/` is absent. The latter is the located v2 pack, approved for specific landmark studies, not a source of generic site geometry. Its dimensions remain largely unverified and skylines are not sightlines. None of the 60 rules selects a landmark. Missing bar/school/store look sheets are explicitly gaps, not filled by copying a famous building.

Fallback IDs: **B** = plain mass on actual footprint, existing provenance-labelled height estimate if no measured height, mapped roof if known, otherwise minimal neutral roof; no domestic porch/chimney, branded façade, steeple or invented entrances. **A** = mapped area with neutral category surface, no invented site contents. **L** = mapped line/ribbon only when width/elevation is defensible; unresolved vertical structure omitted with diagnostic. **P** = node retained in metadata/diagnostics, no invented footprint or visible category icon. **S** = suppress unsupported underground/invalid structural geometry with reason. A tagged node defaults P unless an independently mapped footprint can be associated safely. A site boundary is not a building footprint. B is a massing fallback, not a claim that its estimated height is surveyed.

Current behavior codes are derived from A8 (not captures): **BH** = generic building if separately `building=*`; `building=yes` may misrender as house; use-only feature otherwise Ø. **G** = existing generic mass/area, no specialized semantic details. **Ø** = no semantic consumer (underlying ground/independent buildings may remain). **Ctx** = optional native context only, absent baked core. **D** = dedicated module. Every “today” cell inherits A8's corresponding row: buildings/other tags for BH/G buildings; ranks 1–10 for infrastructure; partial areas/unused points for surface/prop entries. Web shares baked core, not the optional context supplement. A8 does not separately inspect every amenity below: BH/Ø for those is the **classifier-derived consequence**, not a per-category render test.

**Frequency:** C common across settlement types, M metro/suburban concentration, T town/fringe recurring, E less frequent but high local visual harm. All qualitative/unverified. Rows are grouped, not numeric frequency ranks. Tag expressions use `+` for AND, `/` between values for OR, `*` for any supported value; literal semicolon lists require token parsing, never raw regex. Linked wiki pages document tags/examples; combinations here are reproducible synthetic fixtures assembled from those conventions, **not claimed extracts of named real objects**. The school/stadium relationship requires separate related features, not all tags on one polygon.

| # / id / frequency | OSM pattern and wiki evidence | Existing look sheet (or gap) | Neutral fallback | Today (A8) | Smallest first module |
|---|---|---|---|---|---|
| 01 `unknown-building` C | [building=yes](https://wiki.openstreetmap.org/wiki/Key:building), no more specific class | No typology; calibration materials only | B | BH; house risk | `ResidentialGate` in 0b; B for ineligible unknowns |
| 02 `detached-house` C | [building=house/detached/bungalow](https://wiki.openstreetmap.org/wiki/Key:building) | H1 denver-04-ranch; chicago-01-bungalow, region gated | B | Existing house families | `ResidentialGate`, retain known houses |
| 03 `attached-house` C | [building=terrace/semidetached_house](https://wiki.openstreetmap.org/wiki/Key:building) | H2 nyc-01-brownstone; pending, excluded | B | House grammar, not row proof | `AttachedMass`: preserve shared boundaries |
| 04 `apartments` C | [building=apartments](https://wiki.openstreetmap.org/wiki/Key:building); residential alone stays broad | H1 chicago-02-flats; H2 nyc-04-midrise gated | B | G block; broad residential can house | `ResidentialBlock`, no detached ornament |
| 05 `garage` C | [building=garage/garages/carport](https://wiki.openstreetmap.org/wiki/Key:building) | H1 denver-04-ranch context, no standalone sheet | B | Garage generator; some inferred | `GarageMass`, explicit class first |
| 06 `shed` C | [building=shed](https://wiki.openstreetmap.org/wiki/Key:building) | Gap | B | Shed generator; tiny-area shortcut | `OutbuildingMass`, no tiny-size use inference |
| 07 `shopfront` C | [building=retail + shop=*](https://wiki.openstreetmap.org/wiki/Key:building) | Gap | B/P | BH | `Frontage`, only known occupied edge |
| 08 `grocery` C | [shop=supermarket](https://wiki.openstreetmap.org/wiki/Tag:shop=supermarket) + building=retail when footprint known | Gap | B/P | BH | `RetailMass`; no guessed parking/canopy |
| 09 `neighborhood-bar` C | [amenity=pub/bar](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=retail or known existing form | Gap; no landmark substitute | B/P | BH | `Frontage`, blank understated entrance treatment |
| 10 `food-cafe` C | [amenity=restaurant/cafe/fast_food](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=retail where appropriate | Gap | B/P | BH | `Frontage`; no cuisine-derived architecture |
| 11 `office` C | [building=office](https://wiki.openstreetmap.org/wiki/Key:building) or office=* use on known building | Gap; L towers excluded as defaults | B/P | G/BH | `OfficeMass`, mapped levels only |
| 12 `warehouse` C | [building=warehouse](https://wiki.openstreetmap.org/wiki/Key:building) | Gap | B | G | `ServiceMass`, simple long wall/roof |
| 13 `industrial` M | [building=industrial](https://wiki.openstreetmap.org/wiki/Key:building) | I utility sheets are context, no factory sheet | B | G; industrial land core Ø | `IndustrialMass`, no invented stacks |
| 14 `self-storage` M | [shop=storage_rental](https://wiki.openstreetmap.org/wiki/Tag:shop=storage_rental) + building=commercial on single-building facility | Gap | B/P | BH | `ServiceMass`, mapped rows only |
| 15 `hotel` C | [tourism=hotel + building=hotel](https://wiki.openstreetmap.org/wiki/Tag:tourism=hotel) | Gap | B/P | G/BH | `LodgingMass`, levels/roof not brand grammar |
| 16 `motel` T | [tourism=motel](https://wiki.openstreetmap.org/wiki/Tag:tourism=motel) + building=* | Gap | B/P | BH | `LodgingMass`, no guessed exterior corridor |
| 17 `school` C | [amenity=school + isced:level=3](https://wiki.openstreetmap.org/wiki/Tag:amenity=school); separate building=school | V campus-03-state analogy only, not school scale | B/A/P | BH; no school semantics | `InstitutionMass`, site/building separation |
| 18 `college-campus` M | [amenity=college/university](https://wiki.openstreetmap.org/wiki/Education_features), separate building=university | V campus-01-quad / campus-02-urban / campus-03-state | A/B/P | BH; no campus assembly | `SiteAssembly`, mapped constituents only |
| 19 `childcare` C | [amenity=kindergarten](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | Gap | B/P | BH | `InstitutionMass`, no themed play props |
| 20 `worship` C | [amenity=place_of_worship + building=church](https://wiki.openstreetmap.org/wiki/Tag:amenity=place_of_worship); other explicit forms retained | Gap; L religious landmarks never defaults | B/P | BH | `WorshipMass`, mapped roof/tower parts only |
| 21 `hospital` M | [amenity=hospital](https://wiki.openstreetmap.org/wiki/Key:amenity), separate building=hospital | Gap | B/A/P | BH | `InstitutionMass`, no invented wings/helipad |
| 22 `clinic` C | [amenity=clinic/doctors/dentist](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | Gap | B/P | BH | `Frontage`, preserve host mass |
| 23 `fire-station` C | [amenity=fire_station](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=fire_station | Gap | B/P | BH | `ServiceMass`, bays only from façade evidence |
| 24 `police-station` C | [amenity=police](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | Gap | B/P | BH | `InstitutionMass`, no insignia/security inventions |
| 25 `civic-office` C | [amenity=townhall](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=civic | Gap; L civic monuments excluded | B/P | BH | `InstitutionMass` |
| 26 `library` C | [amenity=library](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | Gap | B/P | BH | `InstitutionMass` |
| 27 `post-office` C | [amenity=post_office](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | Gap | B/P | BH; post_box point also Ø | `ServiceMass`, no agency branding |
| 28 `community-hall` C | [amenity=community_centre](https://wiki.openstreetmap.org/wiki/Key:amenity) + building=* | V venue-02-arena not a hall template; gap | B/P | BH | `InstitutionMass` |
| 29 `football-stadium` M | [leisure=stadium + sport=american_football](https://wiki.openstreetmap.org/wiki/Tag:sport=american_football); school relationship separate | V stadium-05-college / stadium-01-open, Builder gated | A/B/P | Stadium semantics Ø; buildings G | `SportsSite`, never invent bowl/stands |
| 30 `sports-pitch` C | [leisure=pitch + sport=american_football/baseball/soccer](https://wiki.openstreetmap.org/wiki/Key:leisure) | I land-02-sports | A | G pitch cap | `PitchSurface`, fit markings to mapped extent |
| 31 `grandstand` M | [building=grandstand](https://wiki.openstreetmap.org/wiki/Tag:building=grandstand) | V stadium-05-college, gated | B | G block | `StandMass`, mapped footprint/height, no guessed seats |
| 32 `sports-court` C | [leisure=pitch + sport=tennis/basketball](https://wiki.openstreetmap.org/wiki/Key:leisure) | I land-02-sports | A | G pitch cap | `CourtSurface`, no guessed fences |
| 33 `running-track` M | [leisure=track + sport=running](https://wiki.openstreetmap.org/wiki/Key:leisure) | I land-02-sports | A/L | Track semantics Ø | `TrackRibbon`, no inferred oval |
| 34 `swimming-pool` C | [leisure=swimming_pool](https://wiki.openstreetmap.org/wiki/Key:leisure) | V campus context only; dedicated look gap | A/P | D pool water on mapped area | Retain `PoolSurface`, no site expansion |
| 35 `playground` C | [leisure=playground](https://wiki.openstreetmap.org/wiki/Key:leisure), playground=* components separate | I land-07-park context | A/P | G cap; equipment points Ø | `PlaySurface`, mapped equipment later |
| 36 `park` C | [leisure=park](https://wiki.openstreetmap.org/wiki/Key:leisure) | I land-07-park | A | G lawn, not guaranteed mapped trees | `ParkSurface`, reuse mapped paths/trees |
| 37 `cemetery` C | [landuse=cemetery / amenity=grave_yard](https://wiki.openstreetmap.org/wiki/Map_features) | I land-03-cemetery | A | G lawn | `CemeterySurface`, no invented graves |
| 38 `surface-parking` C | [amenity=parking + parking=surface](https://wiki.openstreetmap.org/wiki/Key:amenity) | I land-04-parking-large / land-05-parking-small | A | G cap | `ParkingSurface`, mapped aisles first |
| 39 `parking-structure` M | [amenity=parking + parking=multi-storey](https://wiki.openstreetmap.org/wiki/Key:amenity); building=parking separately | I land-06-stadium-parking context; garage look gap | B/P | G building or generic parking cap | `ParkingMass`, do not flatten building into lot |
| 40 `fuel-station` C | [amenity=fuel](https://wiki.openstreetmap.org/wiki/Tag:amenity=fuel), mapped building=roof canopy separate | Gap | A/B/P | BH; fuel semantics Ø | `CanopyMass`, no invented pumps/brand |
| 41 `rail-station` C | [railway=station + public_transport=station](https://wiki.openstreetmap.org/wiki/Tag:railway=station); building=train_station separate | I rail-05-station | B/P | A8 #7: Ø; BH if building | `StationMass`, ordinary station not landmark |
| 42 `rail-platform` C | [railway=platform + public_transport=platform](https://wiki.openstreetmap.org/wiki/Key:railway) | I rail-02-commuter / rail-05-station | A/L/P | A8 #7: Ø or independent path | `PlatformPad`, mapped extent; no guessed canopy |
| 43 `bus-station` M | [amenity=bus_station + public_transport=station](https://wiki.openstreetmap.org/wiki/Key:amenity) | I rail-05 analogy only; bus sheet gap | A/B/P | Ø/BH | `TransitSite`, mapped pads/buildings |
| 44 `transit-shelter` C | [amenity=shelter + shelter_type=public_transport](https://wiki.openstreetmap.org/wiki/Tag:building=train_station) | Gap | B/P | Ø/BH | `ShelterRoof`, footprint required |
| 45 `rail-corridor` C | [railway=rail/light_rail/tram + service=yard/siding/spur where applicable](https://wiki.openstreetmap.org/wiki/Key:railway) | I rail-01-elevated / rail-02-commuter / rail-03-light / rail-04-yard | L/S | A8 #3: Ø core, G Ctx ribbon | `RailRibbon`, bridge/tunnel composition |
| 46 `bridge` C | [highway=* or railway=* + bridge=yes + layer=1](https://wiki.openstreetmap.org/wiki/Key:bridge) | I bridges-03-girder / roads-03-overpass; ornate families require tags | L/S | A8 #1: flat ribbon | `Deck`, only defensible height/approaches |
| 47 `tunnel` E | [highway=* or railway=* + tunnel=yes](https://wiki.openstreetmap.org/wiki/Key:tunnel) | Infrastructure gap for portal geometry | S | A8 #2: road visible in core; rail Ø | `UndergroundGuard`, no surface strip |
| 48 `stairs` C | [highway=steps + step_count=*](https://wiki.openstreetmap.org/wiki/Tag:highway=steps) | Infrastructure path context; stair sheet gap | L/S | G flat path | `StepRun`, mapped rise needed; no accessibility claim |
| 49 `waterway` C | [waterway=stream/ditch/drain/canal/river + width=*](https://wiki.openstreetmap.org/wiki/Key:waterway) | I water-06-canal; small stream gap | L/S | A8 #5: parsed, Ø core; subset G Ctx | `WaterRibbon`, known or labelled inferred width |
| 50 `boundary-wall` C | [barrier=fence/wall/retaining_wall/guard_rail](https://wiki.openstreetmap.org/wiki/Key:barrier) + height=* | I water-04-riverwall / roads-04-soundwall only where applicable | L/S | A8 #6: parsed, Ø | `BoundaryLine`, no guessed retaining height |
| 51 `pier` E | [man_made=pier](https://wiki.openstreetmap.org/wiki/Key:man_made) | I water-03-pier | A/L/S | A8 #10: parsed, Ø core | `PierDeck`, validate support/elevation |
| 52 `marina` E | [leisure=marina](https://wiki.openstreetmap.org/wiki/Key:leisure), separately mapped piers | I water-02-marina | A/P | Marina semantics Ø | `WaterSite`, no fabricated slips/boats |
| 53 `water-tower` T | [man_made=water_tower + height=*](https://wiki.openstreetmap.org/wiki/Key:man_made) | I utility-04-water-tower | P/B | A8 #8: Ø/BH | `TowerMass`, dimensions required |
| 54 `communications-mast` C | [man_made=mast/tower + tower:type=communication](https://wiki.openstreetmap.org/wiki/Key:man_made) | I utility-05-cell-tower | P/B | A8 #8: Ø/BH | `MastMass`, no inferred guy wires |
| 55 `substation` C | [power=substation + substation=distribution](https://wiki.openstreetmap.org/wiki/Key:power) | I utility-03-substation | A/P | A8 #8: Ø/BH | `UtilitySite`, no guessed transformers |
| 56 `power-corridor` C | [power=line/minor_line; power=tower/pole supports](https://wiki.openstreetmap.org/wiki/Key:power) | I utility-01-lines / utility-02-transmission | L/P/S | A8 #8: Ø | `SupportSpan`, only verified endpoints/clearance |
| 57 `airfield-pavement` E | [aeroway=runway/taxiway/apron](https://wiki.openstreetmap.org/wiki/Key:aeroway) + width=* where applicable | I airports-01-runway / airports-02-taxiway / airports-03-apron | A/L | A8 #9: Ø | `AirfieldSurface`, no operational guidance |
| 58 `airport-building` E | [aeroway=terminal/hangar + building=*](https://wiki.openstreetmap.org/wiki/Key:aeroway) | I airports-04-terminal / airports-06-hangar | B/P | A8 #9: G independent building | `TransportMass`, no guessed control tower |
| 59 `farm-building` T | [building=barn/farm_auxiliary](https://wiki.openstreetmap.org/wiki/Key:building) | I land-08-open-land context; barn sheet gap | B | G; farmland cap Ctx only | `ServiceMass`, mapped roof, no invented silo |
| 60 `building-parts` M | [building:part=yes + height=* + min_height=*](https://wiki.openstreetmap.org/wiki/Key:building:part) under building relation | Mapped geometry; L not a fallback kit | B/S | A8 #4: part-only omitted | `PartAssembly`, no parent/part double volume |

**Three worked resolutions:** (1) Station node alone → `rail-station/tag-certain/P`; separate `building=train_station` polygon → StationMass/B without inventing a terminal. (2) School grounds + separate American-football pitch → school SiteAssembly + PitchSurface; no `leisure=stadium` means no stadium classification, no mapped stands means no bleachers. Even a tagged stadium without stand geometry gets a surface/site, not a bowl. (3) Pub node inside mixed apartments → pub use metadata, apartment form retained; uncertain tenant frontage means no façade alteration. These rules apply identically in a small town and downtown.

## 3. Corroboration, never design-by-name

Name heuristics below remain proposed, uncalibrated and diagnostic-only; they cannot create, switch or specialize a design. Geometry ordinarily corroborates a tag-selected candidate; the explicit Stage 0b residential conjunction is the sole exception, deferred until the look gate passes. Record positive evidence without overriding a negative/contradictory tag. Do not copy source names into visible signs.

| Hint | Required independent tag | False-positive risk and restriction |
|---|---|---|
| “station”, “depot”, “terminal” | Transport station tag | High: restaurants, historic reuse, utility stations. No transport architecture from text. |
| “high school”, “academy” | amenity=school | Medium/high: dance schools, former schools; no grade inference without explicit education tags. |
| “field”, “stadium”, “arena” | leisure=pitch/stadium/sports_centre | High: parks, surname businesses; never infer sport, bowl, roof or capacity. |
| “bar”, “tavern”, “pub” | amenity=bar/pub | High: “sandbar”, hair bars, reuse; no brand/theme façade. |
| “church”, “temple”, “chapel” | amenity=place_of_worship | High: restaurants and converted buildings; religion does not establish a spire/dome. |
| “warehouse”, “storage”, “mill” | Explicit industrial/storage use or building form | High: office conversions, place names; preserve existing mapped form. |
| Long narrow footprint next to tracks | Tagged platform/station | Medium: warehouse or path; confirms fit, not platform existence. |
| Rectangular turf or oval around pitch | Tagged pitch/track | High: lawn, pond, school courtyard; no inferred stands or regulation dimensions. |
| Small detached footprint/front yard | Explicit house form or complete Stage 0b eligibility | High: clinic, bar, church, outbuilding; size alone never qualifies; inferred form is labelled. |
| Repeated attached rectangles | Explicit terrace/semidetached form | Medium: warehouses/garages; preserve topology, not residential use inference. |
| Large low rectangle + loading-area adjacency | Tagged warehouse/industrial | High: school, supermarket, sports hall; no loading bays without evidence. |
| Point inside one footprint | Compatible use tag plus reliable association | High in multi-tenant or multi-level sites; containment alone cannot choose whole-building architecture. |

Stage 0b preserves the existing [12,250) m² shortcut interval within its combined eligibility test; this is an implementation boundary, not evidence that size settles use. Fit metrics (aspect ratio, compactness, adjacency) must retain values and uncertainty, with separately reviewed thresholds before enabling confidence changes. Names are untrusted data, never instructions. Normalize Unicode and tokenize with language-aware boundaries; substring “bar” is not a pub signal. Never geocode a name to obtain a new design without an independently licensed, provenance-recorded source.

## 4. Tag coverage and A11 licence questions

Measure four denominators per frozen region: acquired objects; classifiable objects; mapped geometry sufficient for the selected module; actual generated/exported objects. Log unknown/conflict/unsupported/no-geometry/no-approved-look separately. No percentage of missing tags is asserted here. A8 identifies extraction filters that may omit classes before classification; a richer module cannot repair an absent feature.

The statuses below are **triage for A11**, not licence decisions or authorization to ingest. Preserve the existing [data-licensing policy](../data-licensing.md), source manifests/credits and ODbL release offer. No raw data downloaded for this spec.

| Option | Coverage contribution | Stated licence/status and A11 question |
|---|---|---|
| OSM tags/relations | Primary form/use/sites; incomplete and locally uneven | ODbL 1.0, [official copyright](https://www.openstreetmap.org/copyright). Existing project route; A11 confirm derived class records/joins remain in the declared offer and attribution. Wiki prose is not the data licence; use tag facts, not copied descriptions/assets. |
| Builder private annotation | User chooses an existing footprint/use, supplies evidence, previews neutral/typed result | User-controlled rights/terms **YELLOW**; not automatically an open dataset. Keep separate overlay with author consent, revision/audit trail, rollback and permissions. A11 decide uploaded plan rights, retention/takedown, sharing and whether any export triggers ODbL obligations; no automatic public base edit. |
| Overture Places | Category and identity candidates; not building geometry | [Official attribution](https://docs.overturemaps.org/attribution/) and [Places guide](https://docs.overturemaps.org/guides/places/): CDLA-Permissive-2.0 route with source attribution details; **YELLOW integration review**. A11 pin release/source notices, onward package obligations and OSM join treatment. A place confidence score is not confidence in architecture. |
| Overture Buildings | Footprints, some class/height/part metadata | Mixed upstream attribution; [Buildings guide](https://docs.overturemaps.org/guides/buildings/) and attribution page; **YELLOW**, do not apply Places licence to Buildings. A11 inspect exact release/theme and source licences before mixing. |
| Microsoft US Building Footprints | Missing outlines, not reliable venue/function class | [Official repository](https://github.com/microsoft/USBuildingFootprints) states ODbL; **YELLOW join/offer review**. Distinguish this US product from Global ML products with different notices. Geometry alone remains unknown form. |
| NCES CCD/EDGE public school points | Confirms public-school identity/level/location; not school building or stadium footprint | [CCD](https://nces.ed.gov/ccd/), [official layer metadata](https://nces.ed.gov/arcgis/rest/services/CCD/CCD_Data/MapServer/layers) states public domain for that file. **YELLOW release check**: A11 verify downloaded version/notice and retain source; no student/staff data. Never assume a point is a campus boundary. |
| FEMA USA Structures | Potential outlines and structure attributes, not a guaranteed occupancy classifier | [Official catalogue](https://catalog.data.gov/dataset/usa-structures) reports public access; **YELLOW: exact redistribution licence and per-source restrictions unverified**. A11 examine selected release metadata; public download does not imply public-domain rights. |
| Municipal building-use/assessor GIS | Potential use, year/height/parcel association | **YELLOW per jurisdiction**, no national blanket licence. A11 require exact portal terms, commercial redistribution permission and updates; omit owner names, addresses of individuals and other personal fields. Parcel use is not building architecture. No municipal source selected here. |
| Commercial POI such as Google Places | May identify missing uses but is not an open offline enrichment source | [Official Places policies](https://developers.google.com/maps/documentation/places/web-service/policies) restrict caching/storage and map display. **RED for presumed unrestricted package ingestion; YELLOW only if A11 finds a specific contractual route.** Do not scrape, persist or derive a shadow POI database. No access sought. |

External-source conflicts never silently overwrite map geometry or accepted user annotation. Keep source/version/time and association confidence, show conflicts to a reviewer, and preserve a rollback path. GERS/OSM IDs identify source features; neither proves same occupant or design. No personal data collection, imagery scraping or blocked-site bypass.

## 5. Staged build order and tests

| Stage | Why first / smallest output | Acceptance before expansion |
|---|---|---|
| 0a — tunnel guard + diagnostics; A1, already going | Shared underground visibility guard and unsupported-feature/provenance diagnostics. **No building-role change.** R reports this work underway; the census snapshot itself says not implemented at its inspected SHA. | Tunnel/diagnostic checks; identical building-role counts. Do not claim delivery without A1 implementation evidence. |
| 0b — residential-form eligibility; **blocked until the look gate passes** | Preserve the shortcut behind the conjunction below; use B for ineligible unknowns. Do not start role edits as part of 0a or remove the shortcut wholesale. | Lakeview, Wilmette and Greenville final house counts each within ±2% of matched baseline; A3 blind grade must not drop on any hold-out. Both gates mandatory. |
| 1 — reuse mapped masses/surfaces (low–medium) | Form/use/site separation; station, school, pub Frontage/InstitutionMass/StationMass with conservative geometry. Reuse pitch, parking and park caps. | Three worked resolutions, mixed-use/node-only and source-conflict cases pass; no invented bowl/footprint; every omission explained. |
| 2 — continuity and vertical truth (medium–high) | Shared core/context rail/water/boundary lines; generic bridge deck only with defensible elevations; building-parts assembly. | No at-grade false crossing, duplicate part volume or core/context disappearance; unresolved vertical inputs remain diagnosed. |
| 3 — repeatable missing structures (medium) | Mapped stands/platforms, shelter roofs, airport pavement, tower/mast and pier modules. | Geometry/data sufficiency and approved look tests per family; memory/triangle/draw ledger; no regulatory or operational claims. |
| 4 — optional architectural detail (higher) | Approved Builder-phase venue modules and subsequently approved storefront/civic sheets. Maintain same registry. | A3 gains under matched controls, no hold-out regression; rights/approval gates resolved. No landmark proliferation to cover generic gaps. |

### Stage 0b — residential-form eligibility and census guard

Authority: [A1 house-shortcut census](../data/house-shortcut-census.md), filed in `2ffcf68`, using main `e5a0a3e`. Retained shortcut houses: Sloan’s 6 (0.43%), Lakeview 1,431 (50.69%), Wilmette 780 (61.95%), Greenville 118 (17.33%), West Highland 1 (0.04%). **Those percentages use all loaded non-part buildings as denominator, not all houses.** They are not a removal experiment and exclude >250 m² profile promotions and split-house paths. Preserve that distinction when reporting risk.

After the look gate passes, an unclassified `building=yes` may retain residential-form eligibility only when **all** of these hold:

1. Positive residential context: footprint centroid lies in mapped `landuse=residential`, or the existing zone resolver selects an explicitly residential zone profile with recorded provenance. A generic metro/default profile is insufficient. Conflicting commercial/industrial landuse vetoes inference; do not reinterpret a missing zone as residential.
2. Compatible footprint range: preserve the current static shortcut interval **12 ≤ polygon area <250 m²**. Preserve normal alley/detached-garage overrides after eligibility; count final roles. The existing larger-footprint profile route requires a separately recorded residential-zone-specific range and census before gating it; no arbitrary range expansion to satisfy counts. Split paths likewise require an inventory. All changes remain blocked in 0b.
3. No other tagged use on the building or a reliably associated occupant/site: conflicting `amenity`, `shop`, `office`, industrial, transport or other non-residential use vetoes inference. Ambiguous mixed use stays B pending review; explicit mapped residential form remains distinct from inferred use.
4. Not near commercial/industrial evidence: no intersection with such tagged polygons, and no commercial/industrial feature within **20 m footprint-edge distance** (point-to-edge for points). This is an authored initial guard distance, **unverified**, not a census result; include retail/business use tags, not just landuse. Measure sensitivity at 10/20/30 m in the offline eligibility report before implementation; any adopted distance must be one general rule, fixed before hold-out scoring. Missing nearby-tag coverage cannot be treated as verified absence; report it and block acceptance if evidence is insufficient.

Record `confidence=geometry-inferred`, `reason=residential-zone+footprint+no-conflicting-use+proximity-clear`, zone source, area, nearest conflicting feature/distance and coverage status. This is inferred residential **form**, not observed occupancy or tag certainty. If the conjunction fails, classify unknown form with **fallback B**, including every unknown outside a residential zone. Names never qualify or bypass a veto. Known explicitly tagged houses retain their normal path.

Freeze source hashes, loaded extents and generator options. For each of **lakeview-sheil-park, wilmette-vattmann-park, greenville-downtown**, count all final `.house` roles after zone and garage overrides, once per retained non-part building, before versus after. Require `abs(H_after-H_before)/H_before ≤ 0.02` **individually**, not pooled; separately report split-generated house masses, larger-footprint promotions and changed source IDs so totals cannot conceal a path substitution. A zero baseline requires unchanged zero. Census retained-shortcut counts are not these total-house baselines: measure fresh totals. Report Sloan’s and West Highland too.

A3 scores matched before/after blindly on **every hold-out**, with no decline in overall grade or any aspect; missing frames remain pending. Count preservation does not prove visual preservation, and visual preservation does not waive counts. If either gate fails, retain the current role behavior, report the failing classes/evidence, and keep 0b blocked. Do not add block-specific rules, loosen commercial vetoes or relabel buildings just to reach ±2%. The existing full look gate must pass before role implementation starts; these additional acceptance gates apply afterward.

Synthetic acceptance suite to implement later (not run in this docs task):

| Input / setup | Required result |
|---|---|
| building=yes, 80/249 m², eligible residential zone, no use/proximity veto | After look gate: inferred residential form, normal garage overrides; not tag-certain |
| Same footprints outside residential zone, or commercial tag within 20 m | Unknown/B; no house inference |
| building=yes at 11.9/12/249.9/250/251 m² | Static shortcut only [12,250); larger profile promotion separately inventoried/gated, never silently inferred from this census |
| building=yes + name=“Station House”; residential landuse around it | Name ignored; house only if full Stage 0b conjunction passes, otherwise B; never station from name |
| building=yes + amenity=pub, 80 m² | Pub use + neutral form; no house; known footprint only |
| building=house + amenity=pub | Known house form retained, pub use separate, no invented branded façade |
| building=apartments with café node inside and multiple tenants | Apartment mass; café metadata only until frontage association is known |
| railway=station + public_transport=station node | Station/P, no generated station building |
| building=train_station polygon plus related platform polygon | StationMass and PlatformPad, neither duplicated; no copied landmark |
| amenity=school site + building=school + separate pitch sport=american_football | School building and pitch; no stadium bowl/bleachers |
| leisure=stadium + sport=american_football but no stand polygons | Stadium site only; no grandstand geometry |
| Same stadium plus building=grandstand polygon | One bounded stand, no expanded footprint/capacity inference |
| building=yes + name=“Temple Bar” | Unknown/B, neither worship nor pub without qualifying tags |
| building=church + disused:amenity=place_of_worship | Standing mapped form, no active worship semantics or invented spire |
| building=no + amenity=school site | No building from site boundary; site metadata/A only |
| highway=primary + tunnel=yes | Underground interior suppressed, not drawn as flat surface road |
| highway=primary + bridge=yes + layer=1, no height/approach evidence | No metres inferred from layer; unresolved structural fallback/diagnostic |
| railway=rail + bridge=yes with validated deck geometry | Rail plus deck composed once; no generic road substitution |
| parent building + mapped building:part/min_height/height | Parts assembled without parent overlap; no forced house role |
| unknown tiny building near alley / detachedGarages candidate | Existing garage override only after eligible residential inference; ineligible unknown stays B, alley alone cannot qualify |
| amenities contradict each other, or site/node association ambiguous | Conflict retained, neutral form; deterministic result independent of input order |
| absent module or approved sheet | Declared fallback, unsupported reason; not random house/landmark |
| same normalized tags/geometry in different cities | Same archetype/module; only authorized regional material/detail data varies |
| same feature in core, native context and baked web package | Same semantic ID/provenance; documented LOD difference only |

Rule tests also cover tokenized values, missing/null/malformed heights, relation/member deduplication, name Unicode boundaries, invalid geometry, stable seed and serialization versioning. No numeric confidence probabilities until evaluated against a labelled sample. No guessed site capacity, accessibility, evacuation or structural safety.

## 6. Hold-outs, budget and evidence

No rule contains area ID, lat/lon bounds, individual OSM ID, street name, school/team/business name or hand-tuned camera. A locality may select an approved regional style only after semantics resolve; that selector alone cannot turn unknown into known; the full Stage 0b conjunction may yield explicitly labelled inferred residential form after its gate. Explicit landmark work stays separate. Synthetic fixtures are coordinate-independent and must yield identical identity after translation/rotation.

Freeze before/after on Sloan's and untouched Lakeview/Wilmette, West Highland and Greenville when ready, plus one held-out small-town extract selected **before implementation** with available licensed data. Do not select it because the candidate looks good. Missing school/station/pub examples in a hold-out are coverage gaps, not a pass. Report acquired/classified/generated/exported counts, fallback rates and conflicts per class, plus A3 matched phone frames and all aspect scores for implemented visual modules. Reject focus gains paired with hold-out regressions. A classifier fix can be accepted for correctness without claiming a visual score gain, but its changed appearance still needs A3 review.

Use existing device tiers and stage-specific budgets, not one mesh per registry rule. Reuse module/material batches; record main/shadow triangles, draws, memory and timings. Heavy builds/captures require the existing lock and load <25; this docs task performs none. Implementation updates INTEGRATION/MOCKS with the actual consuming build; registry approval or a look sheet is not proof of consumption.

Builder evidence template: `registryVersion=… | base/candidate SHA=… | rules/modules changed=… | synthetic cases passed/failed=… | source/licence manifests=… | fallback/conflict counts=… | core/context/web parity=… | before/after frames+A3=… | hold-outs=… | budgets=… | A11 outstanding=… | keep/reject/pending=…`.

Used: A1 house-shortcut census (2ffcf68), Stage 0b; A8 long-tail audit; MapFeatureBuilder classification; BuildingGenerator role paths; OSM wiki conventions linked per row. Mock: named I/V/H sheets above, with approval/phase restrictions; no landmark defaults. Deviation: frequency estimates and proposed modules, not measured coverage or implemented rendering; literal landmarks-v2 absent, located landmarks-style-b-v2 reviewed.
Tracker update:
