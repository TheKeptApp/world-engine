# Sources and evidence log — street trees by metro v1

Research snapshot: October 7, 2026. Sources are provenance, not endorsement. Regional notes below preserve survey scope, source age, access failures and uncertainty. Search-preview candidates are not verified top-ten rankings.

## Lead-agent sources and methods

- [Census metro table](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html) and [Vintage2025 CSV](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/metro/totals/cbsa-est2025-alldata.csv): read public CSV in memory, filtered Metropolitan Statistical Area, sorted POPESTIMATE2025. Las Vegas is supplementary, not in top25.
- [USA-NPN terms](https://www.usanpn.org/about/terms): directly read data CC BY4.0 and separate site/protocol conditions. No site images used.
- [Spring Index documentation](https://usanpn.org/data/maps/spring): directly read regional early-season reference-plant model, grid and baseline. No metro-specific raster extracted.
- [Observation portal](https://data.usanpn.org/observations/) opened; dynamic interface exposed no observation rows in text. [Programmatic documentation](https://usanpn.org/data/code) opened; no species/date analysis performed.
- [Phenophase definitions2.1](https://www.usanpn.org/files/npn/reports/USA-NPN_Plant_and_Animal_Phenophase_Definitions_v2.1.pdf) directly opened: observation-state methodology, not regional timing norms.
- [NOAA autumn mechanisms](https://www.noaa.gov/stories/cool-autumn-weather-reveals-nature-s-true-hues) and [NWS fall-color guidance](https://www.weather.gov/dvn/climate_fall_colors) directly opened. Neither establishes precise dates for all cities.
- [USA-NPN research summaries](https://www.usanpn.org/news/article?page=11) opened: chilling complicates a simple warm-year rule. Linked Nature papers returned inaccessible authorization redirects; full papers were not read/bypassed.
- [UF/IFAS live oak](https://ask.ifas.ufl.edu/publication/ST564) opened via ordinary edis-to-ask redirect; supports the species form, not a metro prevalence rate.
- [SNWA century plant](https://www.snwa.com/landscapes/plants/?id=14665) directly opened: rosette dimensions, color description and long flowering interval; local suitability is not abundance.
- [NPS saguaro](https://www.nps.gov/sagu/learn/nature/saguaro.htm) and [growth/flowers](https://www.nps.gov/sagu/learn/nature/saguaro-growth.htm) directly opened: Sonoran regional botany, not Phoenix census or Las Vegas presence. No mature crown spread invented.
- [PhenoCam policy lead](https://phenocam.nau.edu/webcam/fairuse_statement/) failed direct opening. No reuse permission assumed.
- [eLife tree-data lead](https://elifesciences.org/articles/77891) direct opening returned a client challenge; Denver percentages from previews/secondary sites were not banked. No bypass attempted.
- NYC public aggregate API direct opening was inaccessible in the tool. No counts inferred from it.

## Consolidation and verification boundaries

City names/CBSA keys retain regional scope. Scientific hybrid notation x/× was normalized; genera, infraspecific taxa and horticultural hybrids retain their resolution. One botanical profile per canonical taxon is selected, preferring cited dimensions over generic art drafts. Conflicting size profiles were not averaged. Flowering follows the selected source geography unless a local source explicitly says otherwise.

Sourced mature ranges are not local measured dimensions. All hexadecimal palettes remain authored sRGB art estimates. Calendar windows remain heuristic unless explicitly supported by local dated observations. Missing shares, traits, species resolution and licences were not filled by assumption.

Only the requested research folder was written. Regional intermediate files were consolidated into the requested deliverables; no engine, repo or git operations.

## Regional research logs

# Northern and eastern metros: sources and limits

Accessed 2026-10-07. This file documents research, not an ingested engine dataset. All 90 species rows are candidates; blank rank/share fields are intentional. None establishes a current combined metropolitan street-and-private-yard top ten. CBSA codes identify requested metro buckets, not source sampling boundaries.

## Chicago priority: three distinct populations

[Chicago’s Urban Forest](https://research.fs.usda.gov/nrs/articles/chicagos-urban-forest), USDA Forest Service, January 30, 2026, directly opened. Summarizes 2019 Urban FIA sample published in 2025. All-city public/private trees at least one inch DBH: buckthorn 41.5%, white mulberry 13.1%, Siberian elm 6.6%, boxelder 5.5%, Norway maple 5%. Of trees at least five inches, Norway maple, silver maple, honeylocust are most common. These figures must not be used as street/yard weights: saplings and unmanaged land strongly affect the denominator.

[Chicago’s urban forest, 2019](https://research.fs.usda.gov/treesearch/69755), USFS NRS-RB-135, 2025: landing directly opened. [PDF](https://research.fs.usda.gov/download/treesearch/69755.pdf) attempted directly; reader refused 49,555,816-byte content. Search previews were not used as verified quantitative table extraction.

[Urban trees and forests of the Chicago region](https://research.fs.usda.gov/treesearch/44566), USFS NRS-RB-84, 2013, 2010 regional sample: landing directly opened. Seven-county Illinois study is not the full CBSA. [PDF](https://www.fs.usda.gov/nrs/pubs/rb/rb_nrs84.pdf) directly returned 403. No bypass or mirror of that blocked document was attempted. Modern ash decline means historic green/white ash prominence cannot describe today's canopy.

[Chicago’s Urban Forest Ecosystem: Results of the Chicago Urban Forest Climate Project](https://www.csu.edu/cerc/documents/ChicagosUrbanForestEcosystem-ResultsoftheChicagoUrbanForestClimateProject.pdf), USFS GTR NE-186, 1994, independently different historical study hosted by Chicago State University: directly opened. Table 11 describes street trees separately in Chicago, suburban Cook and DuPage. Some taxa are grouped, including green/white ash and linden. OCR loses numeric columns; screenshot returned cache miss. Candidates retain historical presence, not claimed modern ranks. General tree and street-tree denominators differ.

[Most Common Maple Trees in Chicago?](https://web.extension.illinois.edu/askextension/thisQuestion.cfm?AskSiteID=87&ThreadID=23339&catID=192), University of Illinois Extension: directly opened. Forestry specialist gives an ornamental maple ordering but no denominator; not a full ranked inventory.

## New York

[2015 Street Tree Census - Tree Data](https://data.cityofnewyork.us/Environment/2015-Street-Tree-Census-Tree-Data/uvpi-gqnh/about_data), NYC Open Data: directly opened but dynamic content blank. Volunteer/staff census has species, diameter and health information according to indexed catalogue. Live urban-tree map and this snapshot are different datasets. Private yards and the metropolitan suburbs are absent.

[NEW YORK CITY, NEW YORK](https://www.nycgovparks.org/sub_your_park/trees_greenstreets/images/NYC_STRATUM_report_2007.pdf), 2007 municipal forest resource analysis: direct PDF attempt returned405. Ten candidate names follow indexed Table1 historical street list, with no verified rank or share copied. Do not present them as contemporary top ten. [Tree Counts](https://storymaps.arcgis.com/stories/36b2aa13104d4fe98ea40f48e4ac0804) directly opened but no extractable text. Public API aggregate URL was inaccessible; no alternate retrieval used.

## Boston

[Urban Forestry](https://content.boston.gov/urban-forestry), City of Boston, updated September11 2026: directly opened. Almost40,000 street trees; recommended species list supports ten planting candidates. A recommended palette is not observed prevalence.

[Boston's Urban Tree Data Now Available Through Analyze Boston](https://content.boston.gov/news/bostons-urban-tree-data-now-available-through-analyze-boston), City of Boston: directly opened. Street inventory completed2021; park trees ongoing; daily inventory update stated. Municipal public trees exclude private yards. Dataset licence/schema/download remain unverified.

[URBAN FOREST PLAN](https://www.boston.gov/sites/default/files/file/2022/09/NeighborhoodStrategies_2022.pdf), 2022 neighborhood strategies: direct open returnediframe only. Indexed neighborhood top-ten lists were not promoted to metro-wide ranking.

## Philadelphia

[Philadelphia Tree Inventory](https://opendataphilly.org/datasets/philadelphia-tree-inventory/), city-linked catalogue: directly opened. 2021–2025 snapshots; CSV/SHP/GeoJSON/API offered. Catalogue description says alltrees but street/municipal labels do not prove private-yard census coverage. City reserves database rights; licence link [Metadata Catalog](https://metadata.phila.gov/) returns generic catalogue. Commercial use and redistribution not verified.

[2025 inventory query](https://services.arcgis.com/fLeGjb7u4uXqeF9q/arcgis/rest/services/ppr_tree_inventory_2025/FeatureServer/0/query?outFields=*&where=1%3D1) directly opened and exposes queryform; layer endpoint inaccessible. No abundance aggregation performed.

[The urban forests of Philadelphia](https://research.fs.usda.gov/treesearch/53315), USFS NRS-RB-106, 2016, 2012 sample: landing attempted twice and timed out. Indexed abstract/figure supports candidates from city forest abundance and leaf area, not a street+yard ranking. Sycamore aggregates include London planetree; no species-specific share derived. Candidate evidence explicitly unverified preview.

## Washington DC

[Street Tree Archive](https://catalog.data.gov/dataset/street-tree-archive), District of Columbia official federal catalogue: directly opened. Annual changes from2014; updatedFebruary12 2025; dataset metadata expressly identifies CC BY4.0. Commercial use and redistribution allowed subject to attribution, licence link and change indication. Do not generalize licence to other DC datasets.

[Layer: Street Tree Archive (ID:13)](https://maps2.dcgis.dc.gov/DCGIS/rest/services/DCGIS_DATA/Urban_Tree_Canopy/FeatureServer/13), directly opened: SCI_NM, CMMN_NM, GENUS_NAME, YEAR, TBOX_STAT, CONDITION, DBH. It is a nonspatial archive table; selectone year and valid occupied/live tree states before deriving a species denominator.

[Master Street Tree Plan, Exhibit C](https://ddot.dc.gov/sites/default/files/dc/sites/ddot/publication/attachments/regulation.pdf), DDOT document, revisedMarch1 2000: directly opened, pages42–44 PDF. Ten documented corridor planting taxa selected as historical candidates. Plan entries are not current inventory or prevalence. Source has a ginkgo/Acer rubrum mismatch in one entry; botanical name corrected from other ginkgo entries, not counted as red maple.

## Baltimore

[Baltimore Cooperating Experimental Forest](https://research.fs.usda.gov/nrs/forestsandranges/locations/baltimore), USFS, updatedJune2 2023: directly opened. Forest remnants/vacant/residential sites and regional riparian forest support ten ecological proxy candidates. Population includes unmanaged forest; these are not ranked maintained street/yard species.

[Baltimore's Urban Forest,2020](https://research.fs.usda.gov/download/treesearch/69884.pdf), USFS: direct attempt failed because63MB content exceeds reader limit. No numerical species table accepted from indexed preview.

[Baltimore City Street Tree Species List](https://bcrp.baltimorecity.gov/sites/default/files/StreetTreeSpeicesList_BaltimoreCity_4-20-2016_FINAL.pdf), April20 2016: directly opened as four-page PDF with no extractable text; screenshot cachemiss. Not used to claim measured frequencies. Dataset access/licence not established.

## Detroit

[Forestry Division](https://detroitmi.gov/departments/general-services-department/forestry-division), City of Detroit: public ROW/parks/property and inventory management directly verified; private-yard responsibility separate. Public full inventory download not established.

[DWSD Green Infrastructure Program Progress Report](https://detroitmi.gov/sites/detroitmi.localhost/files/2018-05/gi_progress2011.pdf), June1 2011: directly opened. Eleven planted types in CSO tributary area street/urban-stormwater forest program; ten selected candidates. Not a city/metro prevalence survey. Winter King hawthorn maps to Crataegus viridis cultivar; source's generic serviceberry excluded to avoid unsupported species resolution.

[Detroit region urban forest vulnerability assessment and synthesis](https://research.fs.usda.gov/treesearch/68092), USFS GTR218, 2024: landing directly opened; [PDF](https://research.fs.usda.gov/download/treesearch/68092.pdf) too large19.7MB. Climate vulnerability is not abundance.

[East Davison Village Edging Framework Plan](https://detroitmi.gov/sites/detroitmi.localhost/files/2020-12/East%20Davison%20Village%20Edging%20Framework%20Plan%20Final%20Report.pdf) direct attempt returned403. No quantitative60%claim accepted from preview.

## Minneapolis

[Trees & the Urban Forest](https://www.minneapolisparks.org/park-care-improvements/trees/), MPRB: directly opened. Nearly200,000 boulevardtrees and400,000 parktrees are administrative scope figures; privateyards excluded. Emerald ashborer discovery2010 makes historic ash prevalence unreliable.

[Case studies for tree trenches and tree boxes](https://stormwater.pca.state.mn.us/case_studies_for_tree_trenches_and_tree_boxes), Minnesota Pollution Control Agency: directly opened. MARQ2 2009 and GreenLine2013 named planting species support ten local candidates, not top-ten metropolitan prevalence. Source incorrectly associates Greenspire withTilia americana; use explicit Boulevard/Redmond entries forAmericanlinden. Cultivar-dependent form differs from species default.

## St Louis

[Street Tree Information](https://www.stlouis-mo.gov/government/departments/parks/forestry/documents/upload/Street-Tree-Information1.pdf), City Forestry, June2016: directly opened. List explicitly identifies common planted street species and says it is not exhaustive; ten selected candidates. No measured ranking.

[Web Map Service - API/Web Service | City Trees (Planting Sites)](https://www.stlouis-mo.gov/data/datasets/distribution.cfm?id=209), City open data: directly opened. WMS city/ForestPark trees advertised; species feature schema, currency, commercial and redistribution terms unverified. Empty planting sites must not count as trees.

## Botanical and art data

North Carolina Extension Gardener Plant Toolbox individual pages below were directly opened and botanical fields inspected. Ranges converted using1ft=0.3048m; not metro inventory measurements. Species default can differ greatly from urban cultivars/pruning. Winter silhouettes and everyhex are rendering heuristics/original art approximations, never measured colors. Ginkgo is a deciduous gymnosperm and has no flowers; dawnredwood is a deciduous conifer. Evergreen=false for regional winter model; lacebarkelm may be semievergreen in warm climates. Some dry leaves can persist on deciduous oaks/beech/hornbeam. NC floweringmonth examples are not imported into northeastern metro calendars.

- [Acer platanoides — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-platanoides/)
- [Acer saccharinum — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-saccharinum/)
- [Gleditsia triacanthos — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/gleditsia-triacanthos/)
- [Fraxinus pennsylvanica — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/fraxinus-pennsylvanica/)
- [Fraxinus americana — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/fraxinus-americana/)
- [Tilia cordata — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/tilia-cordata/)
- [Tilia americana — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/tilia-americana/)
- [Ulmus americana — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/ulmus-americana/)
- [Ulmus pumila — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/ulmus-pumila/)
- [Acer saccharum — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-saccharum/)
- [Platanus × acerifolia — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/platanus-x-acerifolia/)
- [Quercus palustris — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-palustris/)
- [Ginkgo biloba — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/ginkgo-biloba/)
- [Zelkova serrata — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/zelkova-serrata/)
- [Quercus rubra — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-rubra/)
- [Liquidambar styraciflua — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/liquidambar-styraciflua/)
- [Acer rubrum — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-rubrum/)
- [Carpinus betulus — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/carpinus-betulus/)
- [Celtis occidentalis — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/celtis-occidentalis/)
- [Gymnocladus dioicus — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/gymnocladus-dioicus/)
- [Koelreuteria paniculata — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/koelreuteria-paniculata/)
- [Liriodendron tulipifera — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/liriodendron-tulipifera/)
- [Nyssa sylvatica — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/nyssa-sylvatica/)
- [Juglans nigra — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/juglans-nigra/)
- [Prunus serotina — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/prunus-serotina/)
- [Ailanthus altissima — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/ailanthus-altissima/)
- [Acer negundo — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-negundo/)
- [Morus alba — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/morus-alba/)
- [Quercus alba — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-alba/)
- [Ulmus parvifolia — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/ulmus-parvifolia/)
- [Quercus phellos — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-phellos/)
- [Fagus grandifolia — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/fagus-grandifolia/)
- [Robinia pseudoacacia — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/robinia-pseudoacacia/)
- [Quercus montana — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-montana/)
- [Quercus bicolor — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/quercus-bicolor/)
- [Betula nigra — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/betula-nigra/)
- [Crataegus viridis — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/crataegus-viridis/)
- [Acer × freemanii — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/acer-x-freemanii/)
- [Syringa reticulata — NC Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/syringa-reticulata/)

No source photography was copied. Individual NC Extension image licences vary and include noncommercial/no-derivatives restrictions; botanical references do not license images for commercial reuse.

## Seasonal heuristics

[Status of Spring](https://usanpn.org/data/maps/spring), USA National Phenology Network, directly opened: Spring Index uses lilac/honeysuckle early spring indicators, not allstreettrees. Broad metro windows here are explicit rendering heuristics, not observed climatological percentiles.

[Cool autumn weather reveals nature’s true hues](https://www.noaa.gov/stories/cool-autumn-weather-reveals-nature-s-true-hues), NOAA, directly opened: weather/drought/wind affect color and persistence. Warm/cold shifts are qualitative; noinvented day offsets. Fall timing is not a universalinverse of springtemperature.



# South street-tree research — evidence and limits

Research date: 2026-10-07. CBSA is a metro identifier only; city or county samples are never relabeled as metro-wide street-and-yard abundance.

## Species basis
- Miami: ten **candidates**, not actual top ten, from [Miami-Dade's street plan](https://www.miamidade.gov/publicworks/library/planting_on_ROW/Street%20Tree%20Master%20Plan%20FINAL.pdf) and [UF South Florida native trees](https://ask.ifas.ufl.edu/publication/EH157), with royal poinciana supported by [UF ST228](https://ask.ifas.ufl.edu/publication/ST228). Include palms as separate growth forms. [Miami DDA](https://www.miamidda.com/Urban-Planning/Resilience/Downtown-Tree-Inventory) describes an inventory but does not expose a verified downloadable species table in the inspected overview.
- [UF Miami-Dade assessment](https://ask.ifas.ufl.edu/publication/FR347) was inspected: the narrative says its ten leading taxa total54%, but its four percentages42+13+6+4 already total65%. These are presented as tree-number shares in the narrative. No attempt was made to resolve the apparent contradiction from a raster figure; those shares are omitted. The study includes natural/vacant land, so it is unsuitable as a direct yard/street ranking even if corrected.
- Tampa: ten taxa occur in the [Glen Avenue report](https://www.tampa.gov/sites/default/files/project-doc/2024-02/glen_avenue_tree_inventory_report.doc.pdf); corridor presence is the evidence, not city abundance. The report restricts reuse to proposal purposes. This pack does not redistribute its raw inventory records. [Current city canopy analysis](https://www.tampa.gov/document/city-tampa-tree-canopy-and-urban-forest-analysis-2021-132846) is a newer lead whose species table was not extracted.
- Orlando: [2009 municipal resource report](https://research.fs.usda.gov/download/treesearch/60591.pdf), Table2 and Table6, supports the historical ten highest named taxon groups and percentages using68,211 public street trees in2007. Ilex remains genus-level. Counts do not establish current metro/yard shares. Scientific species resolution for Mexican fan palm follows the named taxon; contemporary Washingtonia plantings may be hybrids and must not be silently assigned from silhouette.
- Atlanta: [UGA Georgia native woody plants](https://fieldreport.caes.uga.edu/publications/B987/native-plants-for-georgia-part-i-trees-shrubs-and-woody-vines/) gives regional botanical/landscape candidates. No city frequency ranks verified. [City reports](https://www.atlantaga.gov/government/departments/city-planning/metrics-reporting/tree-reports-and-data) were discovered but direct opening returned an internal error.
- Charlotte: [City tree manual](https://www.charlottenc.gov/files/sharedassets/city/v/1/growth-and-development/getting-started/documents/ctm-1.0-initial-version.pdf) native/heritage list identifies locally common taxa; it is not a frequency census or the approved planting list.
- Dallas: official master-plan PDF returned an internal error. Ten explicitly weak regional Texas candidates are supported by [Austin's species guide](https://www.austintexas.gov/sites/default/files/files/Development_Services/forestry/Tree_Species_Information_English.pdf); their Dallas occurrence/frequency is unverified.
- Houston: [USFS abstract](https://research.fs.usda.gov/treesearch/54109) names five common city taxa. Five further regional candidates are included with no rank/share. Linked full report failed direct opening.
- San Antonio: [City tree guide](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) supports local candidates and some botanical details, not abundance.
- Austin: [City educational page](https://www.austintexas.gov/climate/programs/urban-forest-youth-education) names five common trees; [botanical guide](https://www.austintexas.gov/sites/default/files/files/Development_Services/forestry/Tree_Species_Information_English.pdf) supplies candidates. The page's generic hackberry does not resolve to sugarberry, so the sugarberry row is a candidate and should not be interpreted as a directly verified top-five species. The2014 USDA PDF search result names sugarberry but direct opening failed.

## Botanical forms and colors
Dimensions preserve the full published source ranges in metres wherever both bounds were inspected; single values represent a source point estimate or maximum as noted. They are not an expected mean. Blanks mean unverified. NC source flowering seasons are general to its source geography, not exact dates in Florida/Texas metros. Palms remain leafy through winter; individual old fronds senesce, with royal palm self pruning and queen palm retaining dead fronds. [UF royal palm](https://gardeningsolutions.ifas.ufl.edu/plants/trees-and-shrubs/palms-and-cycads/royal-palm/), [UF queen palm](https://ask.ifas.ufl.edu/publication/ST609), [UF palm table](https://ask.ifas.ufl.edu/publication/EP009). Conifer pollen cones must not be rendered as showy flowers.

All hexadecimal colors are authored art choices, not measured color data. A single fall swatch cannot represent cultivar differences, drought, multi-color foliage, or leafless crown. Gray-brown winter swatches refer to bare wood for deciduous taxa. Evergreen winter swatches do not imply unchanging individual leaves.

Individual extension botanical sources directly opened:
- Quercus virginiana: [source](https://ask.ifas.ufl.edu/publication/ST564) — botanical_source_partial; art_heuristic
- Roystonea regia: [source](https://gardeningsolutions.ifas.ufl.edu/plants/trees-and-shrubs/palms-and-cycads/royal-palm/); [source](https://hort.ifas.ufl.edu/database/documents/pdf/tree_fact_sheets/ROYSPPA.pdf) — botanical_source_partial; art_heuristic
- Sabal palmetto: [source](https://ask.ifas.ufl.edu/publication/EP009) — botanical_source_partial; art_heuristic
- Bursera simaruba: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Swietenia mahagoni: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Conocarpus erectus: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Coccoloba uvifera: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Coccoloba diversifolia: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Cordia sebestena: [source](https://ask.ifas.ufl.edu/publication/EH157) — botanical_source_partial; art_heuristic
- Delonix regia: [source](https://ask.ifas.ufl.edu/publication/ST228) — botanical_source_partial; art_heuristic
- Quercus laurifolia: [source](https://plants.ces.ncsu.edu/plants/quercus-laurifolia/) — botanical_source_partial; art_heuristic
- Syagrus romanzoffiana: [source](https://ask.ifas.ufl.edu/publication/ST609) — botanical_source_partial
- Prunus caroliniana: [source](https://plants.ces.ncsu.edu/plants/prunus-caroliniana/) — botanical_source_partial; art_heuristic
- Koelreuteria paniculata: [source](https://plants.ces.ncsu.edu/plants/koelreuteria-paniculata/) — botanical_source_partial; art_heuristic
- Bauhinia × blakeana: [source](https://www.tampa.gov/sites/default/files/project-doc/2024-02/glen_avenue_tree_inventory_report.doc.pdf) — unverified_botanical_fields
- Pinus palustris: [source](https://plants.ces.ncsu.edu/plants/pinus-palustris/) — botanical_source_partial; art_heuristic
- Quercus nigra: [source](https://plants.ces.ncsu.edu/plants/quercus-nigra/) — botanical_source_partial; art_heuristic
- Schefflera actinophylla: [source](https://ask.ifas.ufl.edu/publication/ST585) — botanical_source_partial
- Lagerstroemia indica: [source](https://plants.ces.ncsu.edu/plants/lagerstroemia-indica/) — botanical_source_partial; art_heuristic
- Ulmus parvifolia: [source](https://plants.ces.ncsu.edu/plants/ulmus-parvifolia/) — botanical_source_partial; art_heuristic
- Magnolia grandiflora: [source](https://plants.ces.ncsu.edu/plants/magnolia-grandiflora/) — botanical_source_partial; art_heuristic
- Acer rubrum: [source](https://plants.ces.ncsu.edu/plants/acer-rubrum/) — botanical_source_partial; art_heuristic
- Ilex spp.: [source](https://research.fs.usda.gov/download/treesearch/60591.pdf) — unverified_botanical_fields
- Quercus shumardii: [source](https://plants.ces.ncsu.edu/plants/quercus-shumardii/) — botanical_source_partial; art_heuristic
- Washingtonia robusta: [source](https://plants.ces.ncsu.edu/plants/washingtonia-robusta/) — botanical_source_partial; art_heuristic
- Quercus alba: [source](https://plants.ces.ncsu.edu/plants/quercus-alba/) — botanical_source_partial; art_heuristic
- Quercus rubra: [source](https://plants.ces.ncsu.edu/plants/quercus-rubra/) — botanical_source_partial; art_heuristic
- Quercus falcata: [source](https://plants.ces.ncsu.edu/plants/quercus-falcata/) — botanical_source_partial; art_heuristic
- Quercus phellos: [source](https://plants.ces.ncsu.edu/plants/quercus-phellos/) — botanical_source_partial; art_heuristic
- Liquidambar styraciflua: [source](https://plants.ces.ncsu.edu/plants/liquidambar-styraciflua/) — botanical_source_partial; art_heuristic
- Liriodendron tulipifera: [source](https://plants.ces.ncsu.edu/plants/liriodendron-tulipifera/) — botanical_source_partial; art_heuristic
- Pinus taeda: [source](https://plants.ces.ncsu.edu/plants/pinus-taeda/) — botanical_source_partial; art_heuristic
- Platanus occidentalis: [source](https://plants.ces.ncsu.edu/plants/platanus-occidentalis/) — botanical_source_partial; art_heuristic
- Ulmus crassifolia: [source](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) — botanical_source_partial; art_heuristic
- Carya illinoinensis: [source](https://plants.ces.ncsu.edu/plants/carya-illinoinensis/) — botanical_source_partial; art_heuristic
- Juniperus virginiana: [source](https://plants.ces.ncsu.edu/plants/juniperus-virginiana/) — botanical_source_partial; art_heuristic
- Quercus macrocarpa: [source](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) — botanical_source_partial; art_heuristic
- Celtis laevigata: [source](https://plants.ces.ncsu.edu/plants/celtis-laevigata/) — botanical_source_partial; art_heuristic
- Ilex vomitoria: [source](https://plants.ces.ncsu.edu/plants/ilex-vomitoria/) — botanical_source_partial; art_heuristic
- Triadica sebifera: [source](https://plants.ces.ncsu.edu/plants/triadica-sebifera/) — botanical_source_partial; art_heuristic
- Ligustrum sinense: [source](https://plants.ces.ncsu.edu/plants/ligustrum-sinense/) — botanical_source_partial; art_heuristic
- Ligustrum japonicum: [source](https://plants.ces.ncsu.edu/plants/ligustrum-japonicum/) — botanical_source_partial; art_heuristic
- Quercus muehlenbergii: [source](https://plants.ces.ncsu.edu/plants/quercus-muehlenbergii/) — botanical_source_partial; art_heuristic
- Chilopsis linearis: [source](https://plants.ces.ncsu.edu/plants/chilopsis-linearis/) — botanical_source_partial; art_heuristic
- Quercus laceyi: [source](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) — botanical_source_partial
- Prunus mexicana: [source](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) — botanical_source_partial
- Neltuma glandulosa: [source](https://www.sa.gov/Directory/Initiatives/Urban-Forestry/Discover-the-Trees) — botanical_source_partial
- Juniperus ashei: [source](https://www.austintexas.gov/sites/default/files/files/Development_Services/forestry/Tree_Species_Information_English.pdf) — partial_unverified_botanical_fields
- Diospyros texana: [source](https://www.austintexas.gov/sites/default/files/files/Development_Services/forestry/Tree_Species_Information_English.pdf) — partial_unverified_botanical_fields
- Quercus stellata: [source](https://plants.ces.ncsu.edu/plants/quercus-stellata/) — botanical_source_partial; art_heuristic

## Phenology
All metro month windows are broad authored rendering heuristics and remain **unvalidated**. They are not derived observations, forecasts, or species-specific calendar rules. Miami has no single temperate autumn canopy peak. Tropical deciduous behavior and evergreen exchange need species/site handling. The [USA-NPN spring index](https://www.usanpn.org/data/maps/spring) models lilac/honeysuckle early spring, not all street trees. [NOAA autumn explanation](https://www.noaa.gov/stories/cool-autumn-weather-reveals-nature-s-true-hues) supports temperature/drought/wind qualifications, not these exact metro windows. Warm/cold shifts have qualitative direction for spring only, contingent on chilling; fall is variable. No invented day offset.

## Inventory access and rights
Public visibility, ArcGIS query support, and government hosting do not establish an open license. Every inventory's commercial use and redistribution remain unknown unless restrictions are expressly found. Tampa Glen Avenue has an explicit purpose restriction. USDA report hosting does not establish the license of underlying municipal raw records. [Charlotte work-order MapServer](https://gis.charlottenc.gov/arcgis/rest/services/Cityworks/PlantTrees/MapServer) supports JSON/geoJSON/PBF, but complete species schema, key requirements beyond landing page, and licensing were not inspected. It is planting work orders, not a complete existing-tree census. Photos/images were not downloaded or licensed for redistribution.


# Western metros evidence and limitations

Research date: 2026-10-07. CBSA identifiers label the requested metros; they do not imply source data covers the CBSA. All 80 species rows have form rows. Blank abundance, date, dimensions or rights fields mean unverified. Candidate row order is not a frequency rank.

## Denver priority

Actual inventory discovered: [Tree Inventory Denver](https://data.colorado.gov/Natural-Resources/Tree-Inventory-Denver/wz8h-dap6). Search metadata describes species_common, species_botanic, inventory_date and roughly 374K records. Direct catalog open returned only a heading. The normal public aggregate endpoint could not be accessed. No counts or species shares were manufactured. The 2022 assessment URL found in search returned an internal error; the city 16th Street appendices were too large for the browser. These access failures were not bypassed.

Denver's ten rows therefore are explicit regional planting candidates from [CSU Selecting Large Deciduous Trees](https://extension.colostate.edu/resource/selecting-large-deciduous-trees/), directly opened. They are not an actual top ten, nor evidence of current street/yard prevalence. The inventory should be analyzed after authorized access becomes available. CSU tree shapes and selected fall/flower traits support only relevant morphology; generic form drafts are labeled.

## Verified bounded abundance

[Phoenix city Urban Forest page](https://web-prod.phoenix.gov/administration/departments/parks/about-us/phoenixs-urban-forest.html) was directly opened. Its Common Tree Types section states ten percentages for city parks and city street landscapes. Numeric denominator count and observation year are not stated there. These percentages do not cover private yards or the metropolitan region. California fan palm is 3.8%, Mexican fan palm 3.1%; mesquite 8.8% and blue palo verde 6.8%. The paired 3.1% records are a tie; row order follows source.

[San Francisco April 2013 Resource Analysis](https://default.sfplanning.org/plans-and-programs/planning-for-the-city/urban-forest-plan/UrbanForestPlan_StreetTreeCensus_FullReport_apr2013.pdf) was directly opened. Figure 2 and population table support ten ranks/shares. The denominator is 24,858 inventoried trees collected in 2012 in four neighborhoods and commercial corridors. Historical sample only; not a current citywide or CBSA census. Report names Ficus retusa ssp. nitida and Tristania conferta were normalized to Ficus microcarpa and Lophostemon confertus. Species key spelling uses report-linked London plane concept. Palms collectively are about 3% in this historical sample, not a species-specific palm share.

## Southern California candidates and inventory metadata

[Avolio et al. 2015 original research](https://www.frontiersin.org/journals/ecology-and-evolution/articles/10.3389/fevo.2015.00073/full) directly opened: survey covers 37 neighborhoods in Los Angeles, Orange and Riverside counties, collected 2010-2011. Street versus residential tree communities differ. Figure 2 lists candidate taxa; aggregate common palms cannot be turned into LA or Riverside metro ranks. LA and Riverside ten-row palettes are explicit candidates, with blank shares/ranks. Syagrus romanzoffiana normalizes the paper's Arecastrum romanzoffianum.

[StreetsLA inventory](https://streets.lacity.gov/resources/tree-inventory) directly opened confirms arborist inventory of street trees, stumps and vacant sites, linking street/park TreeKeeper. [Riverside official ArcGIS layer](https://mapriverside.riversideca.gov/server/rest/services/Arboriculture/UrbanForestry/MapServer/1) directly opened documents botanical/common fields, TreeCount and approximately May 2020 migration of 127,750 features. These are metadata only; no extracted abundance.

[San Diego Street Trees layer](https://webmaps.sandiego.gov/arcgis/rest/services/DSD/Environment/MapServer/20) directly opened. [City-hosted 2024 contractor PDF](https://www.sandiego.gov/sites/default/files/2024-01/cw-2241135.pdf) has a searchable species-frequency excerpt, but direct open failed; its values are deliberately not promoted into verified percentages. Six rows reflect that excerpt; four additional candidates are search-only local policy/palette leads. San Diego candidate coverage remains incomplete and must be validated.

## Seattle and Las Vegas

[Seattle inventory map](https://seattle.gov/transportation/projects-and-programs/programs/trees-and-landscaping-program/seattle-tree-inventory-map) search metadata indicates a city-maintained subset; direct open failed. [Seattle past plantings](https://seattle.gov/trees/past-plantings) returned 403; ten yard-program candidates are marked search-only. No city ranking claim.

[Las Vegas sustainability resources](https://www.lasvegasnevada.gov/Government/Initiatives/Sustainability/Sustainability-Resources) directly opened links the municipal TreeKeeper inventory; the viewer timed out. [UNR FS-10-64 PDF](https://naes.agnt.unr.edu/PMS/Pubs/2010-3409.pdf) directly opened provides palm suitability, not frequency. Las Vegas is supplementary to the Census top 25. Its palms are palette candidates; Parkinsonia florida is a desert-tree supplementary candidate. UNR explicitly considers queen palms and jelly palms poor choices for southern Nevada, so they were not included as Las Vegas planting candidates. UNR's copyright notice requires written permission for reproducing its publication; this is not a municipal inventory license.

## Forms and season

[ASU blue palo verde profile](https://www.asu.edu/lib/camartin/plants/Plant%20html%20files/parkinsoniaflorida.html) directly opened supports a rounded/open crown, roughly 30 feet height with equal-or-greater spread, partial/drought deciduous behavior and early-mid April yellow flowers in Phoenix. Irrigation affects vigor and density. ASU cautions against its naturally low crown as a conventional street/lawn tree; Phoenix's existing city-street prevalence is not a recommendation.

[UF/IFAS Mexican fan palm](https://ask.ifas.ufl.edu/publication/ST670) directly opened supports height 70-100 feet and fan leaves. [CSU Evergreen Trees](https://extension.colostate.edu/resource/evergreen-trees/) directly opened supports selected landscape mature dimensions (converted feet × 0.3048) and retained canopy with old-needle turnover. These Colorado landscape sizes are not Seattle wild-tree maximum sizes. All other blank numeric dimensions are explicit missing research. Uncited generic silhouettes, evergreen classifications, flower sketches and seasonal HEX palettes are labeled unverified art drafts; they must not be mistaken for sourced botanical measurements.

All eight metro calendar windows are explicitly rendering heuristics, not observation-based phenology. Coastal/inland, altitude, irrigation and species require separate calibration. Earlier warm spring/later cold spring are heuristic directions only; chilling and frost complicate response. No fixed day offsets or simplistic fall-temperature shift was asserted. [USA-NPN spring maps](https://www.usanpn.org/data/maps/spring) are a calibration lead, not evidence every tree follows a lilac/honeysuckle index.

## Botanical form upgrade

Follow-up verification replaced 26 generic form records with directly opened university/USDA botanical profiles. The forms file now has 29 taxa with at least one sourced height/spread field, and 30 taxa with some directly sourced botanical traits. This does not make all 60 taxa complete. Missing widths/flower details remain explicit. Winter silhouettes are interpretations of sourced leaf habit and branching; HEX values remain artist approximations. Feet were converted with 0.3048; reported typical ranges are not wild maximum sizes. Where OSU's parenthetical metric range conflicts with feet, the foot range was converted consistently.

Denver's ten candidate taxa now have specific crown/leaf/flower evidence, rather than generic rounded-tree drafts. Directly opened OSU profiles: [American elm](https://landscapeplants.oregonstate.edu/plants/ulmus-americana), [hackberry](https://landscapeplants.oregonstate.edu/plants/celtis-occidentalis), [northern catalpa](https://landscapeplants.oregonstate.edu/plants/catalpa-speciosa), [bur oak](https://landscapeplants.oregonstate.edu/plants/quercus-macrocarpa), [red oak](https://landscapeplants.oregonstate.edu/plants/quercus-rubra), [littleleaf linden](https://landscapeplants.oregonstate.edu/plants/tilia-cordata), [Norway maple](https://landscapeplants.oregonstate.edu/plants/acer-platanoides), [English oak](https://landscapeplants.oregonstate.edu/plants/quercus-robur), [Japanese pagoda tree](https://landscapeplants.oregonstate.edu/plants/styphnolobium-japonicum), [chinkapin oak](https://landscapeplants.oregonstate.edu/plants/quercus-muehlenbergii). Botanical profiles do not establish Denver frequency rankings. CSU supplies only specifically labeled supplementary fall/flower traits.

Directly opened palm profiles: [UF queen palm](https://ask.ifas.ufl.edu/publication/ST609), [UF Canary Island date palm](https://ask.ifas.ufl.edu/publication/ST439), [UF South Florida palm table](https://ask.ifas.ufl.edu/publication/EP009), [OSU windmill palm](https://landscapeplants.oregonstate.edu/plants/trachycarpus-fortunei), [OSU California fan palm](https://landscapeplants.oregonstate.edu/plants/washingtonia-filifera). These support dimensions, fan versus feather texture, single versus clumping/trunkless habit and flower colors when stated. UF typical sizes are Florida landscape references, not measured western-city maximums. Queen palm bloom calendar is Florida spring/summer, not verified Las Vegas timing. Canary date palm's orange flower stalks must not be interpreted as orange flowers. Dwarf palmetto is trunkless/shrub-like and Mediterranean fan palm clumps; do not render every palm as a tall single pole.

Additional directly opened profiles: [USDA/UC Davis velvet mesquite](https://plants.usda.gov/DocumentLibrary/plantguide/pdf/cs_prve.pdf), [OSU Aleppo pine](https://landscapeplants.oregonstate.edu/plants/pinus-halepensis), [Chinese elm](https://landscapeplants.oregonstate.edu/plants/ulmus-parvifolia), [sweetgum](https://landscapeplants.oregonstate.edu/plants/liquidambar-styraciflua), [southern magnolia](https://landscapeplants.oregonstate.edu/plants/magnolia-grandiflora), [London plane](https://landscapeplants.oregonstate.edu/plants/platanus-acerifolia), [Italian cypress](https://landscapeplants.oregonstate.edu/plants/cupressus-sempervirens), [Chinese pistache](https://landscapeplants.oregonstate.edu/plants/pistacia-chinensis). Mesquite is deciduous with crooked spreading limbs; Aleppo pine becomes umbrella/globose; Chinese elm can retain leaves; Italian cypress cultivated forms differ from wild spreading forms. Dates in general profiles are not metro-specific observed phenology.

Attempts at ASU palo brea and mesquite, Cal Poly palo brea, OSU Arizona ash/jacaranda/blue palm, and Australian National Botanic Gardens shoestring acacia were inaccessible or cache failures. A USFS mesquite page returned 403 and was not bypassed. These attempted URLs were not promoted as verified traits.

## Rights

Public access, government hosting and public JSON endpoints do not establish public-domain or commercial redistribution rights. Inventory licenses and commercial/redistribution terms remain unverified in every municipal inventory row. Do not ingest bulk data commercially until the dataset-specific terms are checked. Research summaries and artist-selected HEX values are distinct from redistribution of source datasets or images.
