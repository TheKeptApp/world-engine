# WorldEngine landmarks research v1
**Research date: 7 October 2026. Proposal only.**

100 search destinations across the 20 largest metropolitan statistical areas (MSAs), with 44 entries in Chicago, Denver and Miami. There are **98 build candidates and two reference-only artworks**. Every candidate remains pending geometry and rights verification. No meshes, branding assets or code are included.

This is a curated demand hypothesis, not an empirically measured list of the 100 most-searched places. Selection and build priority are **ASSUMPTIONS**. Validate demand through opt-in aggregate searches after launch, without collecting home coordinates.

## Files
- [landmarks.csv](landmarks.csv): 100 records with coordinates, proposed geometry routes, licence guidance, architecture and trademark triage, difficulty, build order and citations.
- [verify-first.md](verify-first.md): the unresolved questions, acquisition checks and a specific next action for every entry.

## What is verified
**VERIFIED, 2026-10-07:** All 100 latitude/longitude pairs were returned by Wikipedia's public MediaWiki coordinates API. Each row links to the corresponding page. These are community-maintained search anchors, not independent survey control. Coordinate precision preserves the source value and is not a claim of positional accuracy. Building origins, parcel boundaries, footprints, campus extents and elevations are **UNVERIFIED**.

Lake Shore Drive uses the Outer Drive Bridge point as an explicitly selected representative corridor anchor. Lower Wacker uses the Wacker Drive page's road anchor; its lower deck is not independently located. Campus points can refer to an institution or one campus, so a point never substitutes for a campus polygon. The site scope is an **ASSUMPTION** documented in each row.

**VERIFIED, 2026-10-07:** Venue identity corrections are supported by owner/operator pages: [Rate Field](https://www.mlb.com/whitesox/ballpark/information), [Daikin Park](https://www.mlb.com/astros/ballpark), and [Reliant Stadium](https://www.houstontexans.com/stadium/). Retain older sponsor names as search aliases, never as model signage. Other row names are verified against Wikipedia identity pages; a complete current official naming audit is **UNVERIFIED**.

**VERIFIED, 2026-10-07:** The [City of Detroit describes a proposed Renaissance Center redevelopment](https://detroitmi.gov/departments/planning-and-development-department/community-benefits-ordinance/current-cbo-engagements/renaissance-center-and-east-riverfront-projects). Its proposed design must not silently replace the currently surveyed towers.

## Metro coverage
Use MSAs rather than city populations or combined statistical areas. This includes suburban sites such as Evanston, Wilmette, Arlington, Pasadena, Inglewood, Tempe and Coral Gables. Riverside–San Bernardino is its own MSA; do not merge it into Los Angeles. San Jose is outside this top 20 even though it shares a CSA with San Francisco.

**VERIFIED publication, 2026-10-07:** Census's latest completed series is [Vintage 2025, released March 2026](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html). **SECONDARY-SOURCE VERIFIED ordering:** the 2025-estimate table on [Metropolitan statistical area](https://en.wikipedia.org/wiki/Metropolitan_statistical_area) was retrieved through MediaWiki and supplies the ranks below. Independent reconciliation with the Census spreadsheet is **UNVERIFIED**: the direct Census request returned HTTP 403; it was not bypassed. Scope is the 50 states and DC. No demand rank is inferred from population.

| 2025 population rank | Metro shorthand | Entries |
| --- | --- | ---: |
| 1 | New York | 6 |
| 2 | Los Angeles | 5 |
| 3 | Chicago | 20 |
| 4 | Dallas–Fort Worth | 4 |
| 5 | Houston | 3 |
| 6 | Atlanta | 4 |
| 7 | Washington | 3 |
| 8 | Miami | 12 |
| 9 | Philadelphia | 3 |
| 10 | Phoenix | 3 |
| 11 | Boston | 4 |
| 12 | Riverside–San Bernardino | 2 |
| 13 | San Francisco | 4 |
| 14 | Detroit | 3 |
| 15 | Seattle | 3 |
| 16 | Minneapolis | 3 |
| 17 | Tampa | 2 |
| 18 | San Diego | 2 |
| 19 | Denver | 12 |
| 20 | Orlando | 2 |

## Open geometry strategy
The CSV's “best” source is a **recommended acquisition route**, not proof that a usable asset has been downloaded. All per-place object IDs, roof measurements, survey vintages and coverage remain **UNVERIFIED**. OSM map links are inspection locations, not references to confirmed building objects. An OSM lookup timed out, including smaller geographic queries; no coverage was inferred from the failure.

**VERIFIED licence, 2026-10-07:** [OSM data is ODbL 1.0](https://www.openstreetmap.org/copyright). Preserve contributor attribution and assess the database share-alike obligations of an adapted world database. OSM is normally useful for footprints, campus boundaries, paths and road topology; that suitability is an **ASSUMPTION** until each feature is inspected. It is not automatically a complete landmark mesh.

**VERIFIED licence, 2026-10-07:** [USGS National Map data](https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map) and the [3DEP point-cloud registry](https://registry.opendata.aws/usgs-lidar/) state public-domain availability. Check the selected project's metadata. Use [LidarExplorer](https://apps.nationalmap.gov/lidar-explorer/) to identify acquisition date, point density, classifications and CRS. **ASSUMPTION:** roof returns plus ground elevations are the most useful nationwide supplement for landmark heights and terrain. A bare-earth DEM removes buildings and cannot supply a stadium roof. Airborne lidar does not resolve Lower Wacker, interiors or hidden facades. Retractable roofs reflect the survey's pose, not a live state.

**VERIFIED dataset existence, 2026-10-07:** [Chicago Building Footprints](https://catalog.data.gov/dataset/building-footprints) is a municipal alternative; the catalogue lists an update of 12 June 2025. Its specific commercial reuse terms are **UNVERIFIED**. Evanston and Wilmette are outside Chicago's city footprint coverage.

**VERIFIED dataset existence, 2026-10-07:** [NYC's 3D model metadata](https://www.nyc.gov/assets/planning/download/pdf/data-maps/open-data/nyc-3d-model-metadata.pdf) describes 2014 aerial-survey geometry and an August 2018 metadata update. It could offer better roof shapes for New York candidates. Commercial redistribution terms are **UNVERIFIED**; [NYC's general terms](https://www.nyc.gov/main/terms-of-use) reserve intellectual-property rights. Public download availability does not itself establish an open licence. Keep the OSM/3DEP route until dataset-specific terms are established.

**VERIFIED portal existence, 2026-10-07:** [Miami-Dade Open Data](https://opendata.miamidade.gov/) is a candidate local source. Individual building/lidar dataset licence, vintage and landmark coverage are **UNVERIFIED**. No verified city-issued 3D alternative was established for Denver in this pass.

**ASSUMPTION:** Hand-author simplified, true-scale exterior silhouettes from licensed geometric facts, with two or more levels of detail. Municipal or lidar geometry is measurement evidence, not permission to reproduce third-party design, art, brands or proprietary textures. Do not extract proprietary globe meshes or copy owner photographs into textures.

## Architecture, art and marks
**VERIFIED legal framework, 2026-10-07:** [Copyright Office Circular 41](https://www.copyright.gov/circs/circ41.pdf) describes eligibility for architectural designs created from 1 December 1990, with a transitional rule for certain earlier unbuilt designs. Buildings and technical drawings are separate works. Bridges and walkways are not registrable as architectural works under the Office's stated building definition. This does not clear artwork, engineering drawings or other attached works.

[17 USC §120(a)](https://www.govinfo.gov/content/pkg/USCODE-2024-title17/html/USCODE-2024-title17-chap1-sec120.htm) permits certain pictorial representations of constructed buildings visible from public places. Whether a particular distributable interactive 3D asset is covered is **UNVERIFIED** here. No candidate is marked legally cleared.

CSV protection classes are **ASSUMPTIONS**, not registry findings:
- **Legacy design candidate:** believed to have an older original shell. Original fixation date, renovations and separately protected details need verification; “old” does not mean every component is public domain.
- **Likely protected architectural design:** modern or potentially transition-eligible design. Actual protection, ownership, licences and applicable exceptions are unverified.
- **Mixed-age:** modern additions, remodels or multiple buildings need separate evaluation.
- **Landscape/infrastructure:** examine individual structures and attachments rather than treating an entire site as one architectural work.
- **Artwork:** Cloud Gate and Chicago Picasso are **REFERENCE_ONLY_NEVER_BUILD**, independent of their actual copyright status. No mesh, texture, proxy sculpture or merchandise depiction. They receive no build-order number. Apply the same exclusion to fountains, statuary, murals and public artworks inside every candidate's boundary.

**VERIFIED general trademark framework, 2026-10-07:** [USPTO infringement guidance](https://www.uspto.gov/page/about-trademark-infringement) discusses source/sponsorship confusion and famous-mark dilution. Per-place trademark and trade-dress risk levels are **ASSUMPTIONS**; no comprehensive searches were completed. No team, university, operator, sponsor logos, mascots, seals, advertisements or identity signage belong in the assets. Names in this research CSV identify destinations; permission for consumer search labels and aliases needs separate review. Avoid implied endorsement. No-logo treatment alone does not settle distinctive shape rights.

## Proposed build order
Difficulty is an **ASSUMPTION** for a phone-ready exterior scene, not a measured effort estimate:
1 = simple single mass; 2 = simple landscape/geometry; 3 = characteristic silhouette and repetitive facade; 4 = complex shell, bowl or several connected volumes; 5 = campus/district, layered infrastructure, elaborate ornament, terrain reconstruction or operable roof.

Build order is editorial: prove silhouette recognition in the priority metros first, finish their remaining candidates, then expand by metro population rank. Within later groups, favor simpler assets. Rights or geometry failure can hold a candidate without promoting an uncleared asset into release.

| Order | Prototype | Metro | Difficulty |
| ---: | --- | --- | ---: |
| 1 | Willis Tower | Chicago | 3 |
| 2 | Colorado State Capitol | Denver | 3 |
| 3 | Freedom Tower (Miami) | Miami | 3 |
| 4 | Chicago Water Tower | Chicago | 3 |
| 5 | Daniels & Fisher Tower | Denver | 3 |
| 6 | Lummus Park (Miami Beach) | Miami | 2 |
| 7 | 875 North Michigan Avenue | Chicago | 3 |
| 8 | Miami Tower | Miami | 3 |
| 9 | Merchandise Mart | Chicago | 3 |
| 10 | Brown Palace Hotel (Denver, Colorado) | Denver | 3 |
| 11 | Ball Arena | Denver | 3 |
| 12 | United Center | Chicago | 3 |

- **1–12:** silhouette prototypes across Chicago, Denver and Miami.
- **13–42:** remaining build candidates in those three metros.
- **43–98:** the other 17 top-20 metros.
- **Excluded:** the two public artworks. “100 records” does not mean 100 permissible builds.

**ASSUMPTION:** Stage large university records as a boundary plus 3–5 recognizable buildings, then expand. The current difficulty-5 scope includes the eventual campus exterior, not an unlimited first-release build.

## Five recommendations
1. Start with Willis Tower, the Colorado State Capitol and Miami's Freedom Tower as three silhouette prototypes, after their verification tasks.
2. Establish one reusable OSM + dated 3DEP measurement workflow before producing many arenas or campuses.
3. Keep acquisition licence, design rights, artwork exclusion and branding review as separate per-asset records.
4. Version roofs, renovations and redevelopment by capture date; alias changing venue names separately from the mesh.
5. Use aggregate launch search demand to reorder this hypothesis list, while keeping home locations private.

## Readiness and limits
All 100 records have source-linked coordinates, a source recommendation and a difficulty estimate. Build candidates have unique orders 1–98; artworks have blank orders. Source-level licences and general rights guidance were researched. Asset-level geometry coverage, exact bounds, licences for local alternatives, architecture registrations, rights-holder permissions and shape marks remain open as explicitly marked. Blocked sites were not bypassed. This pack is a research proposal, not construction or release approval.
