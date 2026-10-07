# Tree + city data licence check v1

Checked **October 7, 2026**. Research only, not legal advice. **R decides; the lawyer reviews before distribution.** No raw datasets downloaded, no inventory points loaded, no git operations, and no blocked pages bypassed. Only these research outputs were saved.

## Decision table

GREEN means commercial use and raw/derived redistribution have an explicit basis, subject to the stated conditions. YELLOW means clarification is needed. RED means permission or the exact dataset is unknown—not necessarily that the publisher prohibits it. An unknown permission is never a yes.

| ID | Dataset / policy | Result | Why / next action |
|---|---|---|---|
| DEN-01 | Denver catalog default | YELLOW | CC BY 3.0 grant is real, but incorporates website terms prohibiting commercial reuse without written permission. Clarify which governs data. |
| DEN-02 | Current Parks, Medians, and Parkway Trees | YELLOW | Real current point layer found; Custom License and planning/cartographic purpose wording need reconciliation with the catalog grant. |
| DEN-03 | Colorado mirror of Denver trees | YELLOW | Mirror says public domain; source says CC BY. Mirror record dates are historical, not a current tree snapshot. |
| DEN-04 | Denver Building Outlines 2022 | YELLOW | Exact roofprint release found; same catalog/website tension and item-specific disclaimer. |
| DEN-05 | Denver assessor year-built fields in Parcels | YELLOW | Year-built fields verified; source and mirror licence labels differ. |
| DEN-06 | Denver assessor stories/storeys | RED | No exact licensed structural table verified. The identified 72-column parcel schema has no stories field. |
| CHI-01 | Chicago portal terms | YELLOW | Applications contemplated; redistribution is revocable and IP rights reserved. Commercial database grant is not explicit. |
| CHI-02 | Chicago current citywide street-tree inventory | RED | No public current species-point inventory verified. Not a claim that no internal inventory exists. |
| CHI-03 | Chicago current portal building footprints | YELLOW | Portal terms apply; do not inherit the separate historical MIT release's licence. |
| CHI-04 | Chicago official historical GitHub building release | GREEN | City explicitly licenses the released data under MIT; retain full notice. Freshness remains unverified. |
| EV-01 | Evanston Trees | GREEN | Current portal CC BY 4.0 grant and redistribution provisions verified. **Automated acquisition is separately on hold pending written authorization.** |
| MIA-01 | Miami DDA 2019 downtown assessment | RED | Assessment exists, but a commercial/raw/derived data licence was not found. |
| MDC-01 | Miami-Dade portal default | GREEN | Accepted report explicitly places portal data in public domain unless otherwise noted. Exact CC Universal version not stated. |
| MDC-02 | Miami-Dade 2021 canopy assessment/map | RED | Study exists; licence of underlying linked layers/report not verified. Canopy is not species points. |
| MDC-03 | Miami-Dade current tree-point inventory | RED | Exact authoritative live-tree release and item exception status not verified. |
| MIA-02 | City of Miami tree-project inventory | RED | Operational/project inventories evidenced, but public export and dataset rights not verified. |
| NPN-01 | USA-NPN observation data | GREEN | CC BY 4.0; observation-specific acknowledgment and citation. Confirm authorized automated access separately. |
| NPN-02 | USA-NPN gridded phenology products | GREEN | CC BY 4.0; raster-specific acknowledgment and product citation. Confirm authorized automated access separately. |

**18 rows: 5 GREEN, 7 YELLOW, 6 RED.** Policy rows are not substitutes for checking the actual dataset. No current Chicago species-point inventory is cleared by this check. Denver must not be described as unconditionally licence-cleared for P1 yet.

## What changed the answer

### Denver: the CC BY claim is correct, but not the whole answer

The [catalog's own terms](https://opendata-geospatialdenver.hub.arcgis.com/) explicitly license data under CC BY 3.0 and incorporate [DenverGov terms](https://www.denvergov.org/Terms-of-Use). The latter's Copyright Notice restricts copying, modification and commercial reuse. It may concern website materials rather than separately licensed data; that is a plausible interpretation, **not a resolution verified here**. Get written clarification of the specific dataset grant and precedence.

The [current tree item](https://opendata-geospatialdenver.hub.arcgis.com/datasets/f90e355dd3874744a25c30fd2ddfd45b_241/about) shows a September 29, 2026 data update and quarterly cadence. Its 359,263 catalog records are not a count of living trees. The [roofprints item](https://opendata-geospatialdenver.hub.arcgis.com/datasets/04e5069b4cf843d2bfe15ad0d1c66e00_111/about) derives from 2022 imagery; its service timestamp does not establish fresh observation dates.

For assessor fields, the [source Parcels item](https://opendata-geospatialdenver.hub.arcgis.com/datasets/7c53bd0894134e80ae1e478c0789bf49_245/about) and [Colorado mirror](https://data.colorado.gov/Government/Denver-Parcels/tsdg-z9uy/about_data) were inspected. All 72 schema fields were checked: `res_orig_year_built` and `com_orig_year_built` exist; stories does not. The source reports an October 7 update, the mirror October 5. Daily/continual and Never cadence statements coexist in mirror metadata. Do not substitute another county's structural data or collect owner names to obtain building age.

### Chicago: current inventory availability is still a gap

The [live portal tree search](https://data.cityofchicago.org/browse?q=tree) returned 14 results: service requests, recycling, open-space information and metrics—not a current citywide species inventory. Searches also surfaced the older Openlands inventory in the City's open-space application; it is not evidence of a current comprehensive municipal inventory. Confirm with Streets and Sanitation before claiming absence or coverage.

The [current footprint map metadata](https://data.cityofchicago.org/Buildings/Building-Footprints-current-/hz9b-7nh8/about) explicitly points to the [portal terms](https://www.chicago.gov/city/en/narr/foia/data_disclaimer.html). These require the **entire prescribed USE OF DATA disclaimer** at the application's access/download location, plus department notices. The short quote below is not that complete required notice. The terms reserve termination rights and impose indemnity. By contrast, the [City's separate GitHub release](https://github.com/Chicago/osd-building-footprints) expressly licenses its data under MIT. This is a rights-cleared historical alternative, not proof the present portal release is MIT or current.

### Evanston: usable licence, important access and age caveats

The [Trees item's custom licence](https://data.cityofevanston.org/datasets/845a3acb3dc0442a80b219691889f992_8/about) links the [current portal terms](https://data.cityofevanston.org/pages/terms), effective May 13, 2025. Preserve metadata, credit derivatives, and obtain written authorization before automated extraction. A July 3, 2025 item update accompanies a warning that the initial 2014 collection is not current. Do not label all 35,750 records living trees. The older 2017 public-domain policy is not used to erase the present portal conditions.

### Miami: three publishers, three separate checks

The [DDA page](https://www.miamidda.com/Urban-Planning/Resilience/Downtown-Tree-Inventory) describes a 2019 E Sciences survey of 11,500 public trees in its downtown area. No usable data-reuse grant was found; its footer copyright link did not provide one. DDA/consultant rights are not automatically County rights.

The [County's current policy page](https://gis-mdc.opendata.arcgis.com/pages/open-data-policy) links [File 161424](https://www.miamidade.gov/govaction/matter.asp?file=true&fileAnalysis=false&matter=161424&yearFolder=Y2016), accepted October 5, 2016. Item 5 supplies the default public-domain basis. The earlier R-881-15 directed preparation of a report; it is not alone the operative permission. The report does not specify a CC0 version, so this check does not invent one. Check exceptions and retain the [County disclaimer](https://www.miamidade.gov/global/disclaimer/disclaimer.page).

The [2021 canopy assessment](https://www.miamidade.gov/global/service.page?Mduid_service=ser1540499461234959) links a map but does not establish rights in all university/report/layer material. The [City's Southwest project](https://www.miami.gov/My-Government/Departments/Planning/Urban-Design-Main-Landing-Page/Neighborhood-Revitalization-Districts/Southwest-SW-Streetscape-and-Street-Tree-Master-Plan) describes GPS inventory work. Its [data-resource page](https://www.miami.gov/Maps-Data/Data-Explorer/Data-Documents-Resources) links the City GIS hub; the [copyright page](https://www.miami.gov/Glossary/Copyright-Policy) is an infringement-notice procedure, not a licence. City and County dynamic search pages did not render usable results during this check; no bypass was attempted. Miami Beach and West Miami inventories are not substitutes for City of Miami data.

### USA-NPN: attribution must match the product

Use CSV NPN-01's acknowledgment; raster credits instead follow A.3. [Terms](https://www.usanpn.org/about/terms) require product-specific citations and written automation approval. [Spring products](https://www.usanpn.org/data/maps/spring) are modeled phenology, not each tree's observed dates.

## Exact-quote register

The CSV references these IDs to avoid duplicating quotations. Permission interpretations are separate from the quoted text. When a grant was not found, the CSV says so—there is no fabricated supporting quotation. Dataset dates and cadence are recorded separately from terms dates. Quotations are deliberately short; links identify the complete conditions.

| Reference | Exact excerpt | Official source / location |
|---|---|---|
| Q-DEN-GRANT | “copy, distribute, transmit and adapt” | [Denver catalog](https://opendata-geospatialdenver.hub.arcgis.com/), Attribution |
| Q-DEN-CREDIT | “City of Denver Open Data Catalog” | Same page, required credit |
| Q-DEN-WEB | “Commercial use of the materials is prohibited without the written permission of the City.” | [DenverGov](https://www.denvergov.org/Terms-of-Use), Copyright Notice |
| Q-CC3 | “for any purpose, even commercially” | [CC BY 3.0 deed](https://creativecommons.org/licenses/by/3.0/), both Share and Adapt; attribution conditions below |
| Q-DEN-TREE | “planning and design purposes and cartographic purposes only” | [Denver trees](https://opendata-geospatialdenver.hub.arcgis.com/datasets/f90e355dd3874744a25c30fd2ddfd45b_241/about), purpose text |
| Q-DEN-BLDG | “NOT FOR ENGINEERING PURPOSES.” | [Denver roofprints](https://opendata-geospatialdenver.hub.arcgis.com/datasets/04e5069b4cf843d2bfe15ad0d1c66e00_111/about), Custom License modal |
| Q-CO-TREE | “Public Domain” | [Colorado tree mirror](https://data.colorado.gov/Natural-Resources/Tree-Inventory-Denver/wz8h-dap6), indexed official licence metadata; direct item detail unverified |
| Q-CO-PARCEL | “Public Domain” | [Colorado parcel mirror](https://data.colorado.gov/Government/Denver-Parcels/tsdg-z9uy/about_data), live Licensing and Attribution |
| Q-CHI-USE | “secondary or derivative application” | [Chicago terms](https://www.chicago.gov/city/en/narr/foia/data_disclaimer.html), USE OF DATA; contemplated use, not a complete commercial database grant |
| Q-CHI-STOP | “terminate any and all display, distribution or other use” | Same page, USE OF DATA |
| Q-CHI-IP | “any title or right” | Same page, RESERVATION OF RIGHTS |
| Q-CHI-DISCLAIMER | “data that has been modified” | Same page, start of required disclaimer; obtain full wording there before distribution |
| Q-CHI-MIT-DATA | “This data is released under the MIT License.” | [Official City README](https://github.com/Chicago/osd-building-footprints), License |
| Q-CHI-MIT | “use, copy, modify, merge, publish, distribute, sublicense, and/or sell” | [Official City licence](https://github.com/Chicago/osd-building-footprints/blob/master/LICENSE.txt), permission paragraph |
| Q-CHI-MIT-NOTICE | “included in all copies or substantial portions” | Same licence, notice condition |
| Q-EV-GRANT | “share and adapt the material for any purpose, even commercially” | [Evanston terms](https://data.cityofevanston.org/pages/terms), Copyright |
| Q-EV-AUTO | “unless authorized in writing by the City of Evanston” | Same page, Acceptable Use, automated-tools prohibition |
| Q-CC4-SHARE | “copy and redistribute the material in any medium or format for any purpose, even commercially” | [CC BY 4.0 deed](https://creativecommons.org/licenses/by/4.0/), Share |
| Q-CC4-ADAPT | “remix, transform, and build upon the material” | Same deed, Adapt |
| Q-CC4-ATTR | “indicate if You modified the Licensed Material” | [CC BY 4.0 legal code](https://creativecommons.org/licenses/by/4.0/legalcode.en), §3(a); also retain supplied credits/notices, material and licence links |
| Q-CC4-DB | “extract, reuse, reproduce, and Share” | Same legal code, §4(1), applicable database rights |
| Q-MDC-PD | “Unless otherwise noted, the data on the portal is public domain” | [Accepted County report](https://www.miamidade.gov/govaction/matter.asp?file=true&fileAnalysis=false&matter=161424&yearFolder=Y2016), item 5 Current Status |
| Q-MDC-GRANT | “share, use, and build upon County-published data” | Same report, item 5 |
| Q-NPN-ACK | Exact contemporary acknowledgment is printed once in CSV NPN-01 | [USA-NPN terms](https://www.usanpn.org/about/terms), Data Attribution A.1 |

CC BY 3.0 and 4.0 permit licensed adaptations with credit; neither is a share-alike licence requiring WorldEngine code to be opened. Preserve the source's applicable rights/notices and do not impose restrictions that defeat recipients' licensed freedoms. MIT likewise requires notice preservation, not an open-source release of WorldEngine. These statements do not resolve Denver's competing incorporated conditions or clear unrelated imagery, logos, photographs or private rights.

## Written-clarification drafts — YELLOW publishers

Drafts only; **none sent**. A publisher's silence is not permission.

### Denver — Open Data / Technology Services / Parks / Assessor

Subject: Written confirmation of Denver data rights for WorldEngine

We are evaluating the exact Parks, Medians, and Parkway Trees, Building Outlines 2022 and Parcels releases linked above for a commercial stylized map product. Please confirm that the catalog CC BY 3.0 grant permits commercial use, redistribution of raw subsets and derived databases, and packaged/offline geometry. Does that specific grant control over DenverGov's incorporated copyright restrictions? Are the item Custom License and cartographic-purpose statements additional limits? Please confirm required credit, partner exceptions, and the licensed table containing assessor stories/floors. We will not load or distribute pending clarification.

### Colorado Information Marketplace — Business Intelligence Center

Subject: Authority and release covered by Denver mirror licence labels

Your Denver trees and parcels mirrors label the data public domain, while the linked Denver source has a CC BY 3.0 catalog grant and custom constraints. Please identify the authority and exact releases covered by the public-domain designation, confirm commercial raw/derived redistribution, and explain the conflicting Never versus Daily update metadata. Which source should control downstream rights and currentness? Please provide written confirmation before we use the mirrors.

### Chicago — Data Portal / Buildings / Streets and Sanitation

Subject: Commercial redistribution permission and current tree inventory

WorldEngine would use the current building footprint release and a current street-tree species-point inventory in a commercial map, including offline derived geometry and raw subsets. Please confirm commercial and redistribution rights, applicable department notices, and the effect of the termination clause. We will display the complete prescribed disclaimer. Is there an exact current public tree inventory item? Separately, does MIT apply to any current footprint release, or only the City's historical GitHub data? Please identify the applicable release and terms in writing.

## Additional access/RED clarification drafts

These are not substitute approvals; they help resolve the remaining blockers.

### Evanston — Open Data / Information Technology

Subject: Authorized automated access to Trees

Your portal permits CC BY 4.0 reuse, but requires written permission for automated extraction. Please authorize or identify the approved public API/bulk route for a single tree snapshot and periodic refreshes. We will preserve original metadata and credit derivative metadata. Which release reflects current living trees rather than the initial 2014 collection?

### Miami-Dade — GIS (gis@miamidade.gov)

Subject: Exact tree inventory item and exception status

Please identify a current species/lifecycle tree-point dataset and the underlying 2021 canopy data items. Does the accepted report's public-domain default apply to each exact item without override, including commercial raw and derived redistribution? Please identify the Creative Commons Universal instrument, university/contractor exceptions, required credit and currentness. We have not downloaded anything.

### Miami DDA — inventory owner

Subject: Licence for the 2019 downtown tree inventory

Please provide the exact inventory release and written rights for commercial visualization, raw subset redistribution and derived databases. Do DDA's rights include the consultant's tables, maps and data? Please identify attribution, exceptions, and whether a later inventory exists. Public availability of the project description is not being treated as permission.

### City of Miami — GIS / Urban Forestry / Planning

Subject: Public tree inventory release and commercial reuse rights

Please identify the public species/lifecycle export for the Southwest inventory or City planting inventory and its applicable licence. Please confirm commercial raw and derived redistribution, contractor rights, credit requirements and the latest release. We have found project descriptions but no verified dataset-level grant.

### USA-NPN — data services

Subject: Authorized service access and app acknowledgment

We intend to use licensed observation/gridded products in a commercial offline map. Please confirm the approved automated data-service access route under the website conduct terms, and how product-specific acknowledgment/citation should appear in an app. We will keep observation and raster credits distinct.

## Verification limits and handoff

`licence-check.csv` contains every requested permission, freshness field, exception, evidence reference and open question. Unknown dates are explicit. A portal update or copyright footer is not an observation date or a licence revision. Incomplete search rendering, failed direct web reads and absent grants were not replaced with assumptions. The live browser successfully resolved several JavaScript-only official terms pages; security restrictions were not bypassed.

Next action is clarification and legal review—not point loading, an importer, an engine change, or a distribution approval. This research does not authorize P1 to acquire data through a prohibited automation route.
