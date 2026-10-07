# WorldEngine regional look catalogue v1

Research date: 7 October 2026. Eight regional research assignments, coordinated by a lead and executed in waves. Chicago, Denver and Miami are the first implementation priorities.

This is a sourced archetype catalogue and a proposed generator specification. It is **not a measured census of architectural styles**. Empirical metro-wide shares are unverified unless a row explicitly gives a denominator and geography. Every generator weight, hex approximation, numeric pitch, setback, lot width and procedural tree spacing is a **proposal**, except a measurement explicitly labelled sourced. Do not publish these controls as facts about residents or neighborhoods.

## Files and scope

- [metros.csv](metros.csv): one row per metro × low-rise residential archetype; documented local forms plus explicit fallback proposals.
- [street-character.csv](street-character.csv): one row per metro, including landscape, street, downtown and phone-distance priorities.
- [sources.md](sources.md): primary source ledger, claims, limits, licensing and inaccessible-source notes.

The top 25 are Metropolitan Statistical Areas ranked by Census Vintage 2025 population, using the official [population tables](https://www.census.gov/data/tables/time-series/demo/popest/2020s-total-metro-and-micro-statistical-areas.html) and [CBSA dataset](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/metro/totals/cbsa-est2025-alldata.csv). Chicago, Denver and Miami already fall within that top25. Municipal guides cover only their stated districts or city; suburbs and other counties remain explicit coverage gaps.

## Ranked findings for Style B

These impact ranks are lead design judgments to test on phones, not measured user-study results.

| Rank | Generator feature | Recommended treatment |
|---:|---|---|
| 1 | Real footprint, height and attached/detached topology | Keep measured geometry. A rowhouse block, three-flat and broad ranch must have different volumes before textures. |
| 2 | Roof family, pitch and orientation | Hip, front/side gable, parapet, mansard and flat roof change silhouette. Numeric ranges in the CSV are starting controls. |
| 3 | Terrain, shoreline and skyline spacing | Use real elevation and building heights; retaining steps and slope contact matter more than decorative trim. |
| 4 | Setback, frontage and garage/access pattern | Respect parcel/road geometry. A rear alley garage should not become a front suburban apron. |
| 5 | Canopy and crown silhouette | Use inventory/canopy evidence. Shade crowns versus palms versus low-water trees need locality, not a metro-wide stereotype. |
| 6 | Roof/wall colour blocks and material family | Use muted palettes as art approximations; avoid repeating a single “city colour.” |
| 7 | Porch, stoop, carport and entry recess | Model broad shadow shapes and raised bases; shallow relief suffices at middle distance. |
| 8 | Ground moisture, planting and exposed soil | Drive lawn state from weather/phenology and vegetation evidence; irrigation uncertainty stays explicit. |
| 9 | Sidewalk/parkway/curb and boundary geometry | Preserve gaps and widths. Never turn design standards into measured inventory. |
| 10 | Dormers, bays and large parapet profiles | Add where evidence supports them and they occupy enough pixels. Brick joints, tile ridges, cables and ornate trim are close-view detail. |

Proposed screen-space policy: below 6 px building height, retain roof/wall silhouette and colour only; 6–20 px add major porch/bay/carport voids; above 20 px add dormers and simplified openings; small texture detail only when its own projected size exceeds about 2 px. These thresholds require calibration with WorldEngine's actual camera, resolution, lighting and 60 fps budget. Projected physical size can be calculated using camera projection; no fixed metre-distance rule is valid across zoom levels.

## Chicago, Denver and Miami first

**Chicago:** prioritize narrow frontage, low hipped brick bungalows, worker cottages and stacked two-/three-flat masses; use mapped alley access. The [Chicago Bungalow Association](https://www.chicagobungalow.org/chicago-bungalow) reports more than 80,000 standing bungalows and nearly one-third of **city single-family homes**. That is not a metro/all-building share and does not justify a 30% universal map prior. The [Chicago Architecture Center](https://www.architecture.org/online-resources/buildings-of-chicago/chicago-bungalow) documents the 25 × 125 ft lot association (7.62 × 38.10 m), brick variants and characteristic roof/entry forms.

**Denver:** combine yellow-brick two-storey hipped Squares, porch bungalows and broader postwar ranch/split-level candidates, with actual South Platte/foothill relief. [University of Colorado Denver](https://news.ucdenver.edu/what-is-a-denver-square/) documents the Square form, hip roof, porch and early twentieth-century context. Colours and ranges in the CSV are proposals. Denver's [catalogue terms](https://opendata-geospatialdenver.hub.arcgis.com/?q=property) specify CC BY 3.0 and credit “City of Denver Open Data Catalog”; check selected-item exceptions and suburban sources. The terms were verified in the official indexed page; the dynamic page did not expose parsed text.

**Miami:** prioritize pale rendered masonry, low hip/flat roofs, tile accents where evidenced, carport/loggia shadows and a mixed canopy rather than palms everywhere. [Miami-Dade architectural history](https://www.miamidade.gov/global/economy/historic-preservation/county-architectural-history.page) documents local vernacular, Mediterranean and postwar types. The [2021 canopy report](https://www.miamidade.gov/govaction/matter.asp?file=true&fileAnalysis=false&matter=230560&yearFolder=Y2023) reports 20.1% inside the Urban Development Boundary, not a metro-wide or street-tree figure.

## How engineers should use the numbers

Generator weights total100 per metro within the **listed fallback low-rise archetypes only**. They are proposed art direction, not housing prevalence; they do not include every apartment, tower, manufactured home or unlisted type. Filter candidates by actual use, vintage, height, geometry and local district evidence first, then renormalize eligible weights. Never assign the same list uniformly throughout a metro. Detached, attached and stacked-unit variants require topology/use evidence.

The roof angles are degrees from horizontal, not rise/run. Proposed defaults must fit the actual footprint and height. A 1.5-storey architectural label often represents one full floor plus occupied roof space; it is not an instruction to write a fractional OSM building:levels tag. [OSM Simple 3D Buildings](https://wiki.openstreetmap.org/wiki/Simple_3D_buildings) distinguishes above-ground floors, roof floors, roof height and building parts.

Setback means building-to-front parcel boundary; if a source/rule uses curb distance, record that distinction. Lot width means street frontage rather than an arbitrary bounding-box dimension. Parkway means planted curb-to-sidewalk band, not the entire curb-to-property-line setback. Preserve actual parcels and sidewalks instead of resizing mapped buildings to the defaults.

All hex values are approximate proposed sRGB art colours. They are not measured local reflectance. Resolve under Style B lighting, then test seasonal weather and shade. A source describing “brick” does not verify a specific red/brown/yellow material ratio.

## Detection pipeline and licence boundaries

1. Use explicit OSM or approved building-source geometry/height/roof/material fields first. [OSM documentation](https://wiki.openstreetmap.org/wiki/Simple_3D_buildings) supports these tags; completeness is unverified locally. [building:architecture](https://wiki.openstreetmap.org/wiki/Key:building:architecture) can help where populated, but is not a uniform national survey.
2. Join approved assessor **structural** fields spatially: original year built, use/units, storeys and footprint. Keep effective/remodel year separate. Exclude owners, mailing addresses, occupants, exemptions, valuations and household attributes.
3. Combine actual vintage, footprint elongation/compactness, shared walls, roof observation and licensed historic-survey style labels. Date and geometry alone do not confirm Tudor, Craftsman, Colonial, shotgun interior plans or split-level floor arrangements.
4. Preserve “unknown” and confidence/provenance. A proposed starting review rule is two independent structural cues before assigning a specific style; validate against a licensed, representative aggregate sample.
5. Use [ACS B25024](https://api.census.gov/data/2024/acs/acs5/groups/B25024.html) and [B25034](https://api.census.gov/data/2024/acs/acs5/groups/B25034.html) only for broad units-in-structure and vintage calibration. Neither reports architectural styles; units, buildings and parcels are different denominators.
6. [Overture building schema](https://docs.overturemaps.org/schema/reference/buildings/building/) offers optional floor/height/roof/facade fields. Geometry can be roofprint rather than ground footprint. Do not assume those fields are populated everywhere or join personal address data.
7. [OSM licensing](https://www.openstreetmap.org/copyright) and [Overture attribution](https://docs.overturemaps.org/attribution/) require ODbL/source treatment. Open municipal download access does not by itself authorize commercial redistribution. Check each dataset and joined product separately.

Guidelines are evidence for architecture, not permission to redistribute their photographs or illustrations. Produce original simplified procedural geometry. No logos, real addresses, protected artworks or individual-level data are included.

## Verify first

1. Whole-MSA coverage, including suburban counties and interstate metro portions.
2. Empirical shares with a defined building/use denominator; historic-district samples are biased.
3. Original versus effective year-built semantics in each assessor source.
4. Structural-field commercial use, raw redistribution and derivative-database obligations.
5. Roof form and pitch from licensed observations rather than date alone.
6. Actual parcel frontage/setback distributions; the proposed ranges are unvalidated.
7. Actual street-tree spacing and crown/species mix; canopy area is not tree density.
8. Sidewalk/curb gaps, parkway widths and adopted versus draft street standards.
9. Mapped garage, driveway and alley connections before generating access.
10. Downtown materials and current skyline heights; many material mixes remain unverified.
11. Palm, wall, lawn/gravel and overhead-wire proportions; avoid city-wide presets.
12. Climate/species/irrigation-dependent lawn state; no universal brown-lawn calendar.
13. Colour palette under actual phone lighting and zoom levels.
14. Style-classifier confusion rates, especially ranch/minimal-traditional and revival variants.
15. Source-specific historical imagery/photo permission and any paid raw-parcel resale restrictions.

## Uncertainty and access

“Unverified” means not established by this bounded primary-source pass. “Proposal” means an explicit engineering/art choice. “Indexed extract” means only the official search-indexed passage was inspected; it has less context than the full document. Draft standards remain drafts. Sources that returned blocked/403 responses were not bypassed and are not supporting evidence. The ledger records these limitations.

Street rows include downtown palette/silhouette proposals where no primary material survey was found. They must not be promoted to claims of dominant tower material percentages. This v1 is ready for generator experiments and source-specific verification, not calibrated statistical realism.

## Metro coverage and catalogue navigation

120 house-type rows and 25 street profiles across eight region groups. The entries below are researched local archetypes/fallback candidates, not a verified dominance ranking. Full scope, sources and uncertainty are in each CSV row.

| Census rank | Metro | Region | Archetypes in catalogue |
|---:|---|---|---|
| 3 | Chicago | Midwest | Chicago brick bungalow; Brick two-/three-flat; Worker's cottage; American Foursquare; Postwar ranch / split-level |
| 19 | Denver | Mountain West | Denver Square / American Foursquare; Craftsman bungalow; Minimal Traditional; Postwar ranch / raised ranch; Split-level suburban; Contemporary detached / duplex / narrow infill |
| 8 | Miami | Southeast/Florida | Postwar masonry ranch / minimal-traditional; Mediterranean Revival; Wood-frame vernacular cottage / bungalow; Postwar modern / MiMo low-rise residential; Later stucco suburban house / townhouse |
| 1 | New York | Mid-Atlantic/Northeast | Brownstone / brick urban rowhouse; Urban tenement / flats block; Queens Tudor / Storybook row; Metro detached suburban fallback |
| 2 | Los Angeles | Pacific | Craftsman / California bungalow; Spanish Colonial Revival; Ranch; Tudor / English cottage |
| 4 | Dallas–Fort Worth | Texas/South Central | Broad ranch; Later traditional detached; Minimal Traditional cottage; Craftsman bungalow; Tudor/English Revival cottage |
| 5 | Houston | Texas/South Central | Traditional ranch; Mid-century ranch/carport; Craftsman bungalow; Folk cottage; Compact townhouse/patio-home infill |
| 6 | Atlanta | Southeast/Florida | Craftsman bungalow; Minimal traditional / American small house; Brick ranch; Split-level / split foyer; Later two-storey suburban traditional |
| 7 | Washington DC | Mid-Atlantic/Northeast | Victorian bay-front brick rowhouse; Porch-front brick rowhouse; Semi-detached urban-edge pair; Metro detached suburban fallback |
| 9 | Philadelphia | Mid-Atlantic/Northeast | Compact brick workingman rowhouse; Streetcar townhouse / porch-front row; Postwar Airlite / straight-through row; Federal / Georgian town row; Detached suburban metro fallback |
| 10 | Phoenix | Southwest | Craftsman / California bungalow; Spanish Colonial Revival; Southwest flat-parapet vernacular; Postwar masonry ranch; Midcentury contemporary low-gable; Later stucco tile-roof subdivision house |
| 11 | Boston | New England | Triple-decker; Masonry rowhouse / brownstone / Second Empire; Colonial / Colonial Revival detached; Queen Anne / Shingle Victorian detached; Cape Cod / postwar Cape-family detached |
| 12 | Riverside–San Bernardino | Pacific | California bungalow; Mediterranean Period Revival; Postwar vernacular cottage; California Ranch |
| 13 | San Francisco–Oakland | Pacific | Victorian wood row/raised-basement house; Edwardian / early revival flats; Sunset revival / streamline tract house; East Bay Craftsman bungalow |
| 14 | Detroit | Midwest | Side-gabled bungalow; Brick Colonial Revival; Tudor-influenced brick house; Minimal Traditional; Ranch |
| 15 | Seattle | Pacific | Craftsman bungalow; Tudor / English cottage; WWII / Minimal Traditional cottage; Ranch / rambler |
| 16 | Minneapolis–St Paul | Midwest | Craftsman bungalow; Queen Anne / late Victorian; Tudor / Period Revival house; Postwar ranch; Split-level / split-foyer |
| 17 | Tampa–St Petersburg | Southeast/Florida | Craftsman / Florida bungalow; Florida frame-vernacular cottage; Mediterranean Revival; Postwar masonry ranch; Later stucco suburban house |
| 18 | San Diego | Pacific | Craftsman bungalow; Spanish Colonial / later revival; Minimal Traditional cottage; Tract Ranch |
| 20 | Orlando | Southeast/Florida | Craftsman bungalow; Frame-vernacular farmhouse/cottage; Mediterranean / Spanish eclectic; Minimal traditional / early ranch; Later stucco suburban house / townhouse |
| 21 | Charlotte | Southeast/Florida | Streetcar-suburb bungalow; American small house / cottage; Brick ranch; Split-level; Later two-storey suburban traditional |
| 22 | Baltimore | Mid-Atlantic/Northeast | Early Federal / Greek Revival row; Italianate flat-roof brick row; Late-Victorian swell-front / bay-front row; Daylight porch-front row; Detached suburban metro fallback |
| 23 | St Louis | Midwest | Shaped-parapet brick single-family; Two-family flat; Brick bungalow / side-gabled bungaloid; Shotgun / narrow vernacular cottage; Postwar suburban ranch |
| 24 | San Antonio | Texas/South Central | Ranch; Minimal Traditional; Craftsman bungalow; Spanish Eclectic; Vernacular/Folk cottage |
| 25 | Austin | Texas/South Central | Ranch; Mid-century Contemporary; Craftsman bungalow; National Folk/transitional cottage; Modern gabled townhouse/duplex |

Boston licence verification priority: the [MassGIS FAQ](https://www.mass.gov/info-details/massgis-frequently-asked-questions) describes public-domain data usable for any purpose with credit, while the [digital parcel standard](https://www.mass.gov/doc/standard-for-digital-parcels-and-related-data-sets-version-3/download) prescribes a restriction on charging beyond reproduction costs for raw parcel redistribution. Clarify the selected parcel metadata and paid raw-data licensing path before resale. This catalogue does not settle that ambiguity.
