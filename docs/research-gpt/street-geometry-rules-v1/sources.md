# Sources and evidence register

Access/research date: 7 October2026. Primary official guidance, data-producer pages, OSM community documentation and original research. Verified means a researcher checked the cited claim on the linked source; it does not certify every fallback value. Municipal/historical/design scopes are recorded. URLs may redirect. No national “typical” prevalence is inferred from a construction standard. All source licences below concern their stated data distribution, not the whole assembled OSM database.

## Common OSM and completeness sources

- OSM-W: [width](https://wiki.openstreetmap.org/wiki/Key:width): road width envelope and unit/source ambiguity.
- OSM-L: [lanes](https://wiki.openstreetmap.org/wiki/Key:lanes): motor lane count and directional/per-lane fields.
- OSM-S: [sidewalk](https://wiki.openstreetmap.org/wiki/Key:sidewalk): side/separate mapping; missing is not explicit no.
- OSM-C: [cycleway](https://wiki.openstreetmap.org/wiki/Key:cycleway): lane/track/separate/advisory distinctions and way-relative sides.
- OSM-P: [street parking](https://wiki.openstreetmap.org/wiki/Street_parking): modern side scheme and legacy parking:lane forms.
- OSM-H: [country classification equivalence](https://wiki.openstreetmap.org/wiki/Highway:International_equivalence): classification is contextual, not a physical lane-width contract.
- OSM-T: [Taginfo API](https://taginfo.openstreetmap.org/taginfo/apidoc): joint key counts support tagged-coverage analysis only; general global key counts are not country/class prevalence. Canada/NL endpoints could not be read here.
- OSM-Q1: [Omar et al.,2022 sidewalk study](https://arxiv.org/abs/2210.02350):50+ US cities, detailed three-city evaluation; not national2026 attribute rates.
- OSM-Q2: [Barrington-Leigh/Millard-Ball2017 network study](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0180698): network completeness only; [2019 correction](https://doi.org/10.1371/journal.pone.0224742). No headline percentage is applied to width/lanes/sidewalk.
- OSM-LIC: [OSM copyright and licence](https://www.openstreetmap.org/copyright): ODbL1.0 for OSM data, attribution and applicable share-alike/database obligations; documentation has its own licence. Keep source licence/provenance and dataset boundaries; compatibility must be checked before combining/distributing derived databases. This pack does not determine a specific future data-merger legal classification.

## US and Canada

## Verified sources and exactly supported claims
- US-G1 https://www.fhwa.dot.gov/policy/23cpr/chap4.cfm — FHWA cites AASHTO guidance: freeway lane 12 ft, arterial/collector 10–12 ft, local 9–12 ft. It is design guidance, not national typical width.
- US-G2 https://www.fhwa.dot.gov/policyinformation/statistics/2023/hm53.cfm — Highway Statistics 2023 table of rural/urban road mileage by lane-width categories and functional class; stronger national distribution evidence, not curb-to-curb data.
- US-G3 https://safety.fhwa.dot.gov/saferjourney1/library/pdf/Facilities.pdf — clear sidewalk widths local/collector 5 ft, arterial 6–8 ft; planting strip guidance local/collector 2–4 ft, arterial 5–6 ft, ideal 6 ft. Historic guidance, not current accessibility legal determination.
- US-G4 https://mutcd.fhwa.dot.gov/pdfs/11th_Edition/mutcd11thedition.pdf — 2023 edition, colour and marking reference. Check current revisions before implementation; cite colour rules only.
- US-G5 https://sfplanning.org/resource/better-streets-plan — SF official streetscape source; local total sidewalk zones are substantially wider than clear walking width.
- CA-G1 https://www.toronto.ca/wp-content/uploads/2025/11/96f5-ecs-specs-roaddg-Lane-Widths-Guideline-Version-3.0-Nov2025.pdf — Toronto urban through lanes 3.0–3.3; curb lanes target 3.3; parking 2.0–2.4; urban shoulder 1.2–2.0 target 1.5; two-way residential collectors often unmarked and measured by pavement width rather than lanes. Do not nationalize Toronto.
- CA-G2 https://www.toronto.ca/wp-content/uploads/2018/02/94f3-LP_EXECUTIVE_SUMMARY1.compressed1.pdf — Toronto local reconstruction examples 7.2 m pavement, collector 8.5 m; considered local 7.2 or 8.5 with one/no sidewalk. Existing narrower streets are real, not every Canadian local road is 10.4 m.
- CA-G3 https://vancouver.ca/files/cov/engineering-design-manual.pdf — indexed 2019 manual table residential local/collector/arterial min sidewalk 1.8 m. Official overview https://vancouver.ca/streets-transportation/street-design-construction-resources.aspx says July 2026 manual now effective; PDF fetch timeout means current detailed dimensions not fully verified. Mark this dimension historical/local.
- CA-G4 https://documents.ottawa.ca/en/file/3002/download?token=fIiYcXUx — Ottawa collector design guidelines: 2 lanes; urban boulevard 0–3 or 0–3.5 m. Historical/local.
- CA-G5 https://www.toronto.ca/services-payments/streets-parking-transportation/road-maintenance/pavement-markings-signs/ — Toronto yellow opposing, white same direction/parking/bike lane delineation.
- CA-G6 https://www.ontario.ca/document/official-mto-drivers-handbook/pavement-markings — Ontario white transverse crosswalk pair, intersections not always marked; colour and broken/solid explanations. Local province, not national regulatory claim.
- CA-G7 https://vancouver.ca/streets-transportation/streetscape-design-guidelines.aspx — different localized lighting and sidewalk families; supports municipal/district override, no numeric spacing.

## Open width datasets, important caveats and licences
1. NYC LION: https://www.nyc.gov/content/planning/pages/resources/datasets/lion ; dictionary https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/bytes/lion_metadata.pdf . `StreetWidth_Min` is narrowest paved street width in feet, formerly StreetWidth. Very useful direct centerline attribute; distinguish minimum from representative mid-block width, multiple roadbeds and generic centerlines. NYC raw LION licence was not verified; do not assert CC0 or tile licence applies. Licence status must be marked UNVERIFIED before redistribution.
2. NYC roadbed polygons: https://data.cityofnewyork.us/d/i36f-5ih7 . Official capture rules https://github.com/CityOfNewYork/nyc-planimetrics/blob/main/Capture_Rules.md define roadbed as polygon inside pavement edge, with intersections/shoulders/driveways subtypes and median exceptions. Polygon perpendicular transects can estimate actual constructed width. Raw dataset licence not verified. https://maps.nyc.gov/tiles/ explicitly CC BY 4.0 applies to TILE SETS; do not transfer this to raw polygons.
3. San Francisco Sidewalk Widths (2014): https://data.sf.gov/d/4g86-grxu ; official federal catalog metadata https://catalog.data.gov/dataset/sidewalk-widths-2014 confirms PDDL 1.0 http://opendatacommons.org/licenses/pddl/1.0/ . Joined street centerlines, sidewalk presence/width; negative values mean variable, most zero values unknown. Not carriageway width. Dataset updated later but measurements 2014.
4. Vancouver legal ROW widths: https://opendata.vancouver.ca/explore/dataset/right-of-way-widths/ . Explicitly NOT curb-to-curb, property-line-to-property-line approximate legal widths. Weekly extract. Open Government Licence – Vancouver, https://opendata.vancouver.ca/pages/licence/ , commercial use with attribution. Use as outer corridor bound, never highway width override.
5. Toronto Sidewalk Inventory: https://open.toronto.ca/dataset/sidewalk-inventory/ . Open Government Licence – Toronto. Sidewalk presence based on 2015 orthoimages; refreshed 2019, possible errors and stale centerline. Presence enrichment not actual carriageway width. Toronto commercial use / attribution licence explanation https://open.toronto.ca/docs/frequently-asked-questions/ .
6. Ontario ORN Composite: https://data.ontario.ca/en/dataset/ontario-road-network-orn-composite — OGL Ontario; network reference and surface/pavement status, not verified actual pavement-width field.
No Canada open centerline constructed-width attribute was verified in this research; prefer explicit gap to presenting legal ROW as pavement width.

## OSM completeness
Country-level numerical attribute completeness for width/lanes/sidewalk/cycleway/parking in US and Canada is UNVERIFIED: no reproducible national extract audit undertaken, no primary national attribute assessment found in search. Road existence/topological completeness is a different question. Absence is unknown, never no sidewalk/bike/parking. Recommended audit: dated country PBF, public road ways by highway class, report segment-count and length-weighted % with parsable width, lanes, sidewalk or separate sidewalk evidence, cycleway or separate track evidence, both parking schemas; distinguish motorways split carriageways, imports, rural vs urban and cities.

## Additional confirmed sources
- CA-G8 https://www2.gov.bc.ca/assets/gov/driving-and-transportation/funding-engagement-permits/grants-funding/cycling-infrastructure-funding/active-transportation-guide/2019-06-14_bcatdg_section_f.pdf — BC Active Transportation Design Guide Table F-25 quotes provincial MOTI standards: rural freeway/expressway lane 3.7 m, shoulder 3.0 m; rural collector/local lanes 3.6 m, shoulders 1.5/1.0 m; lower-volume lanes 3.25–3.6 m. Thus Canada motorway 3.7 m has verified provincial design support, still authored national default, not observed typical. Strong evidence rural override must differ from Toronto urban 3.0 m.
- US-G6 https://www.txdot.gov/manuals/des/rdw/chapter-4--basic-design-criteria/4-10-cross-sectional-elements/4-10-12-curbs-and-curb-gutter.html — TxDOT vertical curbs defined as vertical/nearly vertical >=6 in (0.1524 m); mountable <6 in, preferably <=4 in for traversable locations. Curbs not desirable on high-speed traffic lanes except mountable at outer shoulder where needed. US 0.15 curb is approximately supported as low-end vertical curb concept, but not nationwide measured typical.

## UK and Netherlands

Drive left. UK is four jurisdictions; DfT sources and a Scottish council illustrate practice, not a uniform UK engineering standard. Existing urban roads often narrower than new-build standards.

Evidence: East Lothian council gives typical carriageway bands 6.5–7.3+, 5.5–6.5, 4.8–5.5m (3.7 short constrained sections), with verge/shared-use-path conditions; supports width ranges but exact classes above are authored mapping. https://www.eastlothian.gov.uk/roads-parking-and-transport/transport-infrastructure-new-developments/21-policy-and-plans/22-functions-roads

Manual for Streets §7.2 and §6.3 supports context-based dimensions, not rigid hierarchy: https://www.gov.uk/government/publications/manual-for-streets

Current accessibility source: https://www.gov.uk/government/publications/inclusive-mobility-making-transport-accessible-for-passengers-and-pedestrians (2022). Do not cite withdrawn 2002 version as current.

UK arterial/collector/residential kerb 0.125m is authored general fallback; current DfT floating-bus-stop guidance specifically specifies desired 125mm/min50mm cycle-track-to-footway difference, not all road kerbs: https://www.gov.uk/government/publications/floating-bus-stops-provision-and-design/floating-bus-stops-provision-and-design . Same source specifies one-way cycle track 2m ideal/1.5m min and footway 2m ideal/1.5m min at bus bypass; special-case geometry, not national inventory statistic.

Motorway widths: CD127 cross sections, national technical standard, 3.65m conventional lanes; smart-motorway configurations differ. Official CD127 revision link https://www.standardsforhighways.co.uk/tses/attachments/66f2661f-959d-4b13-8139-92fbd491cbcf?inline=true specifically smart-conversion example has 3.65/3.50/3.40/3.20 lane widths. Ordinary 3.65m rendering choice should not imply all motorway lanes equal.

Marking/crossing verified national vocabulary: white centre, lane, hatching; yellow parking restrictions; UK zebra black/white stripes with zig-zag approaches; signal crossings vary. https://www.gov.uk/government/publications/know-your-traffic-signs/road-markings ; https://www.gov.uk/government/publications/know-your-traffic-signs/pedestrian-cycle-and-equestrian-crossings ; detailed specifications https://www.gov.uk/government/publications/traffic-signs-manual . Geometry renderer should not fabricate legal restrictions.

Cycling guidance: https://www.gov.uk/government/publications/cycle-infrastructure-design-ltn-120 . Existing cycle facility absence cannot be inferred from recommendation for protected facilities.

Open geometry: OS Open Roads is open high-level APPROXIMATE centreline, not measured road width; https://www.data.gov.uk/dataset/65bf62c8-eae0-4475-9c16-a2e81afcbdb0/os-open-roads . OGL official confirmation https://www.ordnancesurvey.co.uk/products/open-data . Covers Great Britain, not all UK. No verified freely licensed national measured carriageway-width dataset found; OS premium highway width/topographic products are not OGL merely because Open Roads is. Local council polygon/width datasets need individual checking before adoption. This is a research gap, not proof none exist.

Drive right. Separate functional classes stroomweg / gebiedsontsluitingsweg / erftoegangsweg are more meaningful than translating US hierarchy. Arterial+collector map to distributor profiles conditionally, residential to access. Major 30km/h distributor roads now exist; do not derive bike provision from speed alone.

CROW ASVV2021 public table verified access-road widths: one-way car+bike ideal3.85/min3.40; one-way car/two-way bike ideal4.40/min3.85; two-way cars+bikes ideal5.80/min4.80. These are combined mixed-traffic widths, not additive two marked lanes. https://kennisbank.crow.nl/public/gastgebruiker/WOBI/ASVV_2021/Wegvakvoorzieningen_op_erftoegangswegen/113086 . Parking contrasting paving preferred to painted markings. These dimensions anchor residential range only; arterial/collector numbers are authored/unverified national-typical estimates.

CROW functional classes: https://www.crow.nl/Onderwerpen/wegontwerp-en-weginrichting/duurzaam-veilig-wegontwerp/ . 

Municipal LIOR has sidewalk preferred>=1.80 one-way,>=2.10 two-way/min1.50/1.80, raised or separated sidewalks: https://lokaleregelgeving.overheid.nl/CVDR743258/1 . This is municipal specification, not national prevalence.

Municipal LIOR2023 kerb exposed height min0.10/max0.125m supports curb choice: https://lokaleregelgeving.overheid.nl/CVDR703356/1 ; concrete curb units 13/15x25 are unit dimensions, NOT exposed kerb height.

Municipal published cycling specification uses one-way segregated >=2.50m and two-way3.50–4.50m: https://zoek.officielebekendmakingen.nl/gmb-2024-473137.pdf . Do not treat this as all existing cycle tracks.

Motorway standard 3.50m referred to in official A27 review https://zoek.officielebekendmakingen.nl/blg-216415.pdf (older source, conventional motorway fallback only; constrained plus lanes narrower).

Rural access profile should be separate: CROW factsheet access typeI pavement4.50–6.20m/central runner3–4.5m; typeII<4.50m no markings. https://www.fietsberaad.nl/CROWFietsberaad/media/Kennis/Bestanden/Factsheet_Rijlopers.pdf?ext=.pdf . Do not apply urban sidewalks to rural access roads.

Best open ACTUAL GEOMETRY: BGT road-surface polygons, nationwide 1:500–1:5000 mapping; distinguish rijbaan, voetpad, fietspad functions, derive local widths from cross-sections after matching centreline and removing junction mouths. PDOK current OGC API landing explicitly CC0 1.0: https://api.pdok.nl/kadaster/bgt/ogc/v1?f=html&lang=nl . Older data.overheid listing says CC-BY4: https://data.overheid.nl/dataset/43122-basisregistratie--grootschalige-topografie--bgt---donl- . Cite license attached to downloaded distribution, record retrieval date, do not silently collapse mismatch. PDOK says metadata leading: https://www.pdok.nl/veel-gestelde-vragen-pdok . BGT widths are DERIVED, not direct road width fields.

NWB roads centreline, named/numbered publicly managed roads, CC0 1.0, monthly update: https://api.pdok.nl/rws/nationaal-wegenbestand-wegen/ogc/v1?f=html&lang=nl . Centreline alone does not prove physical width; combine BGT polygons.

## France and Japan

## Primary sources and evidence scope
- FR1 https://www.cerema.fr/fr/actualites/quels-amenagements-pietons-lors-phase-deconfinement-0 — legal unobstructed path minimum 1.40 m; Cerema sidewalk recommendation 2.50 m. These are design/accessibility bounds, not existing widths.
- FR2 https://www.cerema.fr/fr/actualites/8-recommandations-reussir-votre-piste-cyclable — one-way track desirable 2.5/min2 m; two-way desirable3.5/min3 m; separator curb15 cm,20–50 cm width.
- FR3 https://www.cerema.fr/fr/system/files?file=documents%2F2026%2F05%2F2024_02_08_fiche_01_bien_definir_ac.pdf — local Alsace technical sheet, lane recommended2/min1.5 m excluding markings; not nationwide prevalence.
- FR4 https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000049319436 and https://www.cerema.fr/fr/activites/mobilites/securite-routiere-deplacements/securite-rues-routes/signalisation-routiere/signalisation-horizontale — official zebra band geometry/white colour.
- FR5 https://www.cerema.fr/fr/system/files?file=documents%2F2017%2F12%2FCinq-ans-apres-la-mise-en-place-des-ZdR_cle0f48f1.pdf — shared zones20 km/h; varied design, existing sidewalk possible.
- FR6 https://www.cerema.fr/fr/actualites/officialisation-du-marquage-routes-etroites — 2023 optional white axial guidance on rural narrow roads<5.2 m; avoid assuming all narrow roads marked.
- FR7 https://www.cerema.fr/system/files/documents/2017/10/doc_reamenagements_pietons_quinzaine_uv_2015.pdf — example urban carriageway4.8–5.5 m;6 m for regular heavy-vehicle crossing.
- JP1 https://www.mlit.go.jp/road/road_e/q4_standard.html — expressway lane3.5 m; rural class5 unlaned carriageway4 m or3 m exceptional; major roads stopping lanes2.5 m(reducible1.5), cycle tracks>2 m(reducible1.5). New/reconstructed design standard, not a census. English Type4 class1 table is suspect; verify Japanese current ordinance https://laws.e-gov.go.jp/law/345CO0000000320 before deriving urban lane standards. Keep attributed summary under200 words.
- JP2 https://www.mlit.go.jp/road/road_e/r1_standard_2.html — sidewalk>2 m ordinary/>3.5 busy; planting standard1.5 m. Requirements have exceptions.
- JP3 https://www.mlit.go.jp/kisha/kisha05/06/060203_.html — semi-flat5 cm sidewalk level; legacy mount-up15 cm.
- JP4 https://www.mlit.go.jp/road/road/traffic/barrier/barrier2.htm — crossing step standard2 cm.
- JP5 https://www.mlit.go.jp/common/001087356.pdf — LED retrofits discuss existing lighting spacing roughly40 m, not residential spacing census. https://www.mlit.go.jp/report/press/road01_hh_001999.html — revised LED-standard lighting guidance applies2026-04-01; don't promote historical tables as current universally applicable spacing.
- JP6 https://www.mlit.go.jp/sogoseisaku/inter/keizai/gijyutu/pdf/road_design_j2.pdf — primary MLIT road marking diagrams, yellow lines and white zebra. Regulations index https://www.mlit.go.jp/road/sign/kijyun/kukaku/ss-kukaku-index.html .
- JP7 https://www.mlit.go.jp/road/road/traffic/chicyuka/ — utility undergrounding programme. Historical percentages in older MLIT pages are stale and denominators differ; no numeric2026 claim justified.

## Open actual geometry sources
- France national IGN BD TOPO road centerline `TRONCON_DE_ROUTE`, `largeur` attribute: https://geoservices.ign.fr/bdtopo ; technical definition https://geoservices.ign.fr/sites/default/files/2021-11/DC_BDTOPO_3-0_1.pdf . Width is generalized/estimated, not curb-to-curb engineering survey for every segment. Some width values represent bins; inspect version-specific dictionary. Licence Ouverte Etalab2.0 verified by https://www.ign.fr/institut/des-donnees-et-logiciels-ouverts-au-service-de-la-nation .
- France national road-network measured attribute: https://www.data.gouv.fr/datasets/largeur-de-routes-sur-le-reseau-routier-national — 2025 CSV/shapefile; Licence Ouverte/Open Licence; narrow national-network scope, no city-street universality.
- Paris Plan de Voirie sidewalk polygons: https://www.data.gouv.fr/datasets/plan-de-voirie-trottoirs-emprises — ODbL; measured geometry for sidewalk widths by normal cross-sections, not direct centerline width field; available2026-09-30. Width near junctions must be filtered. Related carriageway polygon layer is a candidate but its individual listing/licence was not verified.
- Japan PLATEAU road model `uro:width` and `uro:widthType`: https://www.mlit.go.jp/plateaudocument02/tocD/tocD_03/_413c6878-68e4-aaa2-ff7e-d05a18d1eecf/_1c3c101c-5e15-7d6f-305e-9ca91f8df2ea/ — schema instructs use road-register widths and urban basic-survey width classification; not every city/model has road width. Use city-specific catalogue manifest. Current licence PDL1.0 with CC BY4.0-compatible reuse permission: https://www.mlit.go.jp/plateau/site-policy/ ; see source citation and Survey Act notes. This is road polygon/3D data rather than universal centerline.
- Japan GSI Fundamental Geospatial Data road-edge line geometry: https://service.gsi.go.jp/kiban/app/help/ ; measure paired edges only where surveyed. GSI default PDL1.0 https://www.gsi.go.jp/ENGLISH/page_e30286.html ; survey-law reproduction permissions and excluded third-party material require checking dataset use. Direct city centerline-width/licence pair not verified here.

## OSM completeness
No current representative country-level empirical width/lanes/sidewalk completeness figures verified for France or Japan. Report UNKNOWN; do not infer completeness from road-network presence or a single city import. Measure dated country extracts with drivable highway denominator and road-length weighted plus way-count tagged coverage, class/urban strata, unique linked footway/cycleway edges accounted separately. Missing tags mean unknown, not absence; Japan's small streets particularly require unlaned model instead of US two full lanes.

## Verification addendum: corrected Japanese lane table
Japanese MLIT explanatory document https://www.mlit.go.jp/road/sign/pdf/kouzourei_full.pdf (page35) verifies Type4 urban class1 ordinary road3.25 m(3.5 exception), class2/3 ordinary3 m; Type3 rural classes1/2/3/4=3.5/3.25/3/2.75 m. Therefore the arterial3.25 and collector3 m priors have a direct design-standard anchor. Prefer this Japanese source over the erroneous English HTML table. Same source framework minor road4 m matches ordinary Type3class5/Type4class4, exceptional3 m.
Japanese bike lane minimum1.5 m (exceptional1 m) verified https://www.mlit.go.jp/road/sign/pdf/kouzourei_3-2.pdf page54 and https://www.mlit.go.jp/report/press/road01_hh_001163.html . These are construction/design standards, not prevalence. Blue lane rendering is optional local treatment, not universally required.

## UK/NL CSV source-ID mapping

- GB-G1: [Manual for Streets](https://www.gov.uk/government/publications/manual-for-streets), contextual geometry; [East Lothian road functions](https://www.eastlothian.gov.uk/roads-parking-and-transport/transport-infrastructure-new-developments/21-policy-and-plans/22-functions-roads), localized carriageway bands.
- GB-G2: [CD127 official attachment](https://www.standardsforhighways.co.uk/tses/attachments/66f2661f-959d-4b13-8139-92fbd491cbcf?inline=true), motorway configurations; 3.65m is a conventional rendering choice, narrower lanes also exist.
- GB-G3: [Inclusive Mobility2022](https://www.gov.uk/government/publications/inclusive-mobility-making-transport-accessible-for-passengers-and-pedestrians), accessibility guidance; [floating bus stops](https://www.gov.uk/government/publications/floating-bus-stops-provision-and-design/floating-bus-stops-provision-and-design), special-case footway/track/level dimensions.
- GB-G4: [markings](https://www.gov.uk/government/publications/know-your-traffic-signs/road-markings), [crossings](https://www.gov.uk/government/publications/know-your-traffic-signs/pedestrian-cycle-and-equestrian-crossings), [LTN1/20](https://www.gov.uk/government/publications/cycle-infrastructure-design-ltn-120).
- NL-G1: [CROW ASVV access-road table](https://kennisbank.crow.nl/public/gastgebruiker/WOBI/ASVV_2021/Wegvakvoorzieningen_op_erftoegangswegen/113086), combined mixed-traffic widths4.8–5.8m for two-way access.
- NL-G2: [municipal LIOR footways](https://lokaleregelgeving.overheid.nl/CVDR743258/1), preferred clear footway dimensions; local not national.
- NL-G3: [municipal LIOR kerbs](https://lokaleregelgeving.overheid.nl/CVDR703356/1), exposed0.10–0.125m; curb unit dimensions are not exposed height.
- NL-G4: [municipal cycling specification](https://zoek.officielebekendmakingen.nl/gmb-2024-473137.pdf), one-way2.5m; [A27 review](https://zoek.officielebekendmakingen.nl/blg-216415.pdf), older conventional motorway3.5m anchor.
- JP8: [Japanese road-structure explanatory document](https://www.mlit.go.jp/road/sign/pdf/kouzourei_full.pdf), page35 supports urban3.25m/3m lanes; use instead of inconsistent English table. [Cycle-lane amendment](https://www.mlit.go.jp/road/sign/pdf/kouzourei_3-2.pdf), page54.

## Dataset shortlist and licence decision

|Country|Best verified geometry lead|What it measures|Licence evidence / unresolved gap|
|---|---|---|---|
|US|[NYC LION](https://www.nyc.gov/content/planning/pages/resources/datasets/lion) / [dictionary](https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/bytes/lion_metadata.pdf)|Minimum paved street width in feet, not a typical midpoint or legal ROW|Raw LION licence **UNVERIFIED**; do not borrow CC BY licence from tile sets|
|US|[NYC roadbed polygons](https://data.cityofnewyork.us/d/i36f-5ih7)|Physical roadbed boundaries, derive widths away from intersections|Raw-layer licence **UNVERIFIED**; capture rules linked above|
|US|[SF sidewalk widths2014](https://data.sf.gov/d/4g86-grxu)|Sidewalk presence/width, negative variable and zero often unknown; not carriageway|PDDL1.0 per [official catalog](https://catalog.data.gov/dataset/sidewalk-widths-2014)|
|Canada|[Vancouver ROW](https://opendata.vancouver.ca/explore/dataset/right-of-way-widths/)|Approximate legal property-to-property width; cannot supply curb-to-curb|[OGL Vancouver](https://opendata.vancouver.ca/pages/licence/), attribution; no actual paved-width lead verified nationally|
|Canada|[Toronto sidewalk inventory](https://open.toronto.ca/dataset/sidewalk-inventory/) / [Ontario ORN](https://data.ontario.ca/en/dataset/ontario-road-network-orn-composite)|Presence/network matching; actual carriageway-width field not verified|OGL Toronto / OGL Ontario; inspect dated metadata and historical imagery scope|
|UK|[OS Open Roads](https://www.data.gov.uk/dataset/65bf62c8-eae0-4475-9c16-a2e81afcbdb0/os-open-roads)|Approximate Great Britain centreline, no measured width; NI excluded|OGL per [OS open data](https://www.ordnancesurvey.co.uk/products/open-data); premium widths not covered|
|Netherlands|[BGT road-surface polygons](https://api.pdok.nl/kadaster/bgt/ogc/v1?f=html&lang=nl), paired with [NWB](https://api.pdok.nl/rws/nationaal-wegenbestand-wegen/ogc/v1?f=html&lang=nl)|Derived physical road/foot/cycle surface widths; NWB centreline alone insufficient|Current PDOK distributions CC0; older BGT catalogue CC-BY4 discrepancy—retain exact download licence metadata|
|France|[IGN BD TOPO](https://geoservices.ign.fr/bdtopo)|Generalized/estimated `largeur` on road sections; inspect version semantics, not universal survey|Licence Ouverte Etalab2.0, producer open-data page above|
|France|[National road-network width dataset](https://www.data.gouv.fr/datasets/largeur-de-routes-sur-le-reseau-routier-national)|Width attributes on the national network, narrower scope than all city streets|Licence Ouverte/Open Licence per catalogue|
|France|[Paris sidewalk polygons](https://www.data.gouv.fr/datasets/plan-de-voirie-trottoirs-emprises)|Derived sidewalk widths; carriageway companion remains a candidate|ODbL for this layer; do not extend licence claim to uninspected companion layers|
|Japan|[PLATEAU width schema](https://www.mlit.go.jp/plateaudocument02/tocD/tocD_03/_413c6878-68e4-aaa2-ff7e-d05a18d1eecf/_1c3c101c-5e15-7d6f-305e-9ca91f8df2ea/)|Road-register width/width class only in available city road models; not every model/city|[PDL1.0 current policy](https://www.mlit.go.jp/plateau/site-policy/) with CC BY4.0-compatible reuse; city manifest/source exceptions and Survey Act notes still require checks|
|Japan|[GSI fundamental geometry](https://service.gsi.go.jp/kiban/app/help/)|Road-edge lines; widths derived only where valid opposite edges exist|[GSI PDL1.0](https://www.gsi.go.jp/ENGLISH/page_e30286.html); third-party exclusions/Survey Act conditions retained|

**Unverified register:** national observed distributions for most dimensions; all country lighting-spacing typicals; all utility-inventory prevalence; most country curb-height prevalence; NL legal marking specification; countrywide OSM attribute completeness; raw NYC licence; Canada and UK freely licensed actual paved-width centreline leads; city-specific Japanese width coverage; BGT distribution licence discrepancy. Do not treat these as checked facts.

## Current US marking edition update

The initial US-G4 colour research used the superseded 2023 PDF. [FHWA’s current edition](https://mutcd.fhwa.dot.gov/kno_11th_Editionr1.htm) is the 11th Edition with Revision 1, December 2025, adopted effective 5 March 2026. Use that edition for implementation. These profiles provide rendering vocabulary, not complete regulatory marking specifications.
