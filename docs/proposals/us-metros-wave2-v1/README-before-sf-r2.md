# US metros wave 2 — Style B

Open [index.html](index.html) for the nine current metro packs, with SF first. Current set: **38 archetype sheets, 20 district boards, 9 block paint-overs and 6 SF supplemental studies**, each with an editable HTML sheet and PNG artwork. Full-sheet PNG exports include the metres, hexes and detail tiers. The house and district artwork uses matching street / aerial / far panels.

The approved Style B Bible is the main authority: real proportions, simplified matte materials, coherent soft light. House-archetypes-v1 supplies sheet structure and projected-size tiers; Japan regional kit supplies the real-proportion transport standard; infrastructure kit supplies ground and utility discipline. The imported `sharedLighting` object is copied unchanged from the Bible, including its historical provenance notes. This does not revive an old unresolved lighting approval: the current user instruction selects the approved Bible as the authority.

## Calibration and numbers

`metro-values.json` contains all nine metros, exact authored dimensions, source records, palette variants, sRGB hex / linear RGB / linear luminance / roughness, street-character notes, camera proposals, map priorities and projected-size detail tiers. Values are **design proposals, not surveys or measured metro prevalence**. No universal building-size or tree-frequency claim is made. Mapped/surveyed data wins; unknown utilities remain off.

Sun 40° elevation / 225° true-north clockwise azimuth; +0.35 EV; contrast 1.06; saturation 1.08; no additional warmth. Sun #FFE8C6, sky fill #AEBCCA, neutral shadow appearance #7F8F99. Apply shared exposure once. Real sun/time/weather replaces this review fixture. Materials: wall roughness 0.86, roof 0.90, sidewalk 0.90, opaque glass 0.50; no texture maps or invented fine joints. Use selective 25 mm primary / 8 mm trim bevels, preserving real roof silhouettes and access geometry. Values are renderer targets; images are illustrative and not exact pixel samples.

House detail tiers use projected building height: below6 px preserve silhouette and contrast; 6–20 px retain porch/bay/entry masses; above20 px add broad opening and trim rhythm. Drop features below2 drawable pixels. Never enlarge windows, trees, cars or stairs to keep them visible. No engine integration or device performance benchmark is claimed.

## Geographic and source limits

**Positions and sightlines come from the map.** These are character studies, not captures of named physical intersections. District layouts and heights are plausible authored envelopes; map footprints, DEM, waterways, setbacks, building heights and road widths override them. Dallas downtown and Fort Worth Fairmount are separate places; no merged skyline. DFW tree references come from the catalog’s Dallas/regional candidates, not a verified Fort Worth inventory. Washington DC uses a mid-rise core rather than a generic skyscraper canyon.

Each block paint-over edits an existing WorldEngine engine camera. Boston, Philadelphia and DC use `lakeview-postcard.png`; the five other metros use `ordinary-street.png`. These are camera frameworks, not actual source captures of these eight metros. Buildings, planting and materials are regional adaptations. Original files are untouched; source paths and SHA-256 hashes are in JSON. No supplied real metro screenshot has been claimed.

Regional catalog and street-tree references provide seven metros. Nashville is newly authored from scoped local guidance; its exact geometry and street dimensions are proposals. Tree lists are candidate visual palettes, not citywide abundance ranks. Historic planting plans and search-preview evidence retain their limitations in the source records. Existing invasive-species inventory mentions are not planting recommendations; rendered candidate palettes avoid those choices.

## Metro selection and street character

### Boston

Archetypes: Triple-decker; Masonry rowhouse / brownstone / Second Empire; Colonial / Colonial Revival detached; Cape Cod / postwar Cape-family detached.

Districts: Downtown / Financial District; Dorchester triple-decker blocks.

Concrete and locally evidenced brick walks; granite curb cue. Small garden or planted frontage; never blanket gravel. Compact fenced front yards on row streets. Candidate tree palette: red maple, honeylocust, ginkgo. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Philadelphia

Archetypes: Compact brick workingman rowhouse; Streetcar townhouse / porch-front row; Postwar Airlite / straight-through row; Federal / Georgian town row.

Districts: Center City; South Philadelphia row blocks.

Compact paved frontage on row streets; selective tree pits, concrete sidewalks and stone steps. Small rear yards. Do not turn tight row blocks into suburban parkways. Candidate tree palette: London plane, northern red oak, red maple. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Washington DC

Archetypes: Victorian bay-front brick rowhouse; Porch-front brick rowhouse; Semi-detached urban-edge pair; Metro detached suburban fallback.

Districts: Downtown / Penn Quarter; Capitol Hill row streets.

Concrete walks and real stone/brick stoops; front gardens within low fences. Tree-lined avenues differ from tighter side streets. Utilities only when evidenced. Candidate tree palette: willow oak, ginkgo, red maple. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Atlanta

Archetypes: Craftsman bungalow; Minimal traditional / American small house; Brick ranch; Split-level / split foyer.

Districts: Midtown corridors; Grant Park residential streets.

Lush lawn and planted yards; rolling terrain from elevation data. Concrete sidewalk presence varies. Mature broadleaf canopy with locally evidenced pine; no constant invented hill. Candidate tree palette: white oak, tulip poplar, loblolly pine. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Dallas–Fort Worth

Archetypes: Broad ranch; Later traditional detached; Craftsman bungalow; Tudor/English Revival cottage.

Districts: Dallas downtown; Fort Worth / Fairmount.

Lawn and broad yards; concrete walks where mapped and actual sidewalk gaps. Dallas core and Fort Worth residential are separate locations, never merged skylines. Candidate tree palette: cedar elm, southern live oak, Shumard oak. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Houston

Archetypes: Traditional ranch; Mid-century ranch/carport; Craftsman bungalow; Compact townhouse/patio-home infill.

Districts: Downtown Houston; Houston Heights bungalow blocks.

Lush humid lawns and planting; retain bayou/drainage grades. Concrete sidewalks and real gaps. No desert gravel default. Overhead utility depiction is a scoped illustrative option. Candidate tree palette: southern live oak, southern magnolia, loblolly pine. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Austin

Archetypes: Ranch; Mid-century Contemporary; Craftsman bungalow; Modern gabled townhouse/duplex.

Districts: Downtown / Lady Bird Lake edge; Hyde Park residential streets.

Mixed lawn, leaf-litter beds and selective limestone/gravel planting; do not make all lots xeric. Concrete walks with mapped continuity, live oak shade, actual slope and utility evidence. Candidate tree palette: southern live oak, cedar elm, pecan. Overhead utilities: mapped/surveyed geometry only; off when unknown.

### Nashville

Archetypes: Craftsman bungalow; Queen Anne cottage; English Revival cottage; Classical Revival / four-square.

Districts: Downtown / Second Avenue edge; East Nashville / Lockeland Springs.

Leafy lawns and planted yards, modest rolling grades from DEM; concrete sidewalks only where known. Candidate trees from city planting guidance, not measured inventory prevalence. Candidate tree palette: white oak, red maple, tulip poplar. Overhead utilities: mapped/surveyed geometry only; off when unknown.

## Reference files and added sources

- Local authority: `../style-b-bible-v1/bible-values.json`, `images/01-calibration-scene.png` and `STYLE-B-RULE.md`.
- Local dimensional/format reference: `../house-archetypes-v1/archetypes-values.json` and `chicago-02-flats.html`.
- Local scale reference: `../japan-regional-kit-v1/05-vehicles.png`; US driving sides and generic vehicle classes replace Japan-specific rules.
- Local ground reference: `../infrastructure-kit-v1/roads-06-residential.png` and `infrastructure-values.json`.
- Local regional evidence: `../regional-look-catalog-v1/metros.csv`, `street-character.csv` and `../street-trees-by-metro-v1/species-by-metro.csv`, `species-forms.csv`. Source URLs and scoped evidence are retained in JSON.
- [Nashville historic district guidelines](https://www.nashville.gov/departments/historic-preservation/programs/districts-and-design-guidelines): district names and linked guidance. [Consolidated neighborhood conservation guidance](https://www.nashville.gov/sites/default/files/2024-06/NCZO_TOC_Part_II_addRWE.pdf?ct=1718899579) search preview supports Queen Anne, Classical Revival, bungalow and English Cottage in Lockeland Springs–East End. **Full PDF unverified here:** fetch exceeded the tool's document-size limit. Four-square massing is an authored representative Classical Revival option, not a claim about every district house.
- [Nashville recommended tree list](https://www.nashville.gov/departments/codes/construction-and-permits/land-use-and-zoning-information/urban-forestry/tree-and-shrub-list) supports white oak, red maple and tulip poplar as planting candidates; not prevalence.
- [Nashville Public Library: Second Avenue history](https://library.nashville.gov/blog/2021/02/market-2nd-ave-look-back-one-nashvilles-oldest-streets-part-2) supports historic warehouse-corridor character. No literal branded facade or art is reproduced.

## Files and review

`*-house-*.png`, `*-district-*.png`, `*-block.png` are the artwork; matching `.html` files are the complete sheets. `*-sheet.png` are exported full specification sheets. `*-board.html` presents a complete metro; index links all eight. `prompts.json` records generation instructions/references and final file provenance. `verification.json` records file, layout and value checks. No logos, badges, brands, real murals, dogs or characters are part of the design brief. No git operations or project-source edits.


## Approved follow-up — SF and Southern differentiation v2

[SF priority pack](sf/index.html) adds6 archetypes,4 district boards,1 block paint-over and6 slope/transit/weather/bridge studies. Its full [README](sf/README.md) and [values](sf/sf-values.json) describe MSL marine layers, real slope witness versus authored grades, map-bound bridge sightlines and generic transit.

The five Southern packs now use revised archetypes and blocks: Austin limestone/native beds/Hill Country grades; Houston low-relief humid ground/raised cottage/newer stucco; Dallas broad brick ranch lots (Fort Worth's narrower bungalow remains separate); Nashville brick/rolling grades; Atlanta dense tall canopy/hillside foundations. These are selected-block treatments, not universal city conditions or prevalence estimates. Root JSON retains scoped catalog evidence and updates authored dimensions/materials/terrain targets. Northern packs remain approved and unchanged. The original Southern district context boards remain available; revised house/block material and terrain treatment is the current authority.

Previous Southern house/block images, sheets and overview pages are retained with `-superseded-v1` names; previous values/prompts likewise. Current gallery links point only to current artwork. No git or synced-project edits.


Current follow-up verification: `verification-v2.json` checks 42 new/revised sheets and the current galleries at 390 CSS pixels. The original `verification.json` describes the previously approved baseline. Supplemental fog, transit and bridge boards have effect-specific detail tiers.
