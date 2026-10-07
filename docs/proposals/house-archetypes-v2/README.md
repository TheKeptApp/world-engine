# House + street archetypes v2 — NYC, LA, Phoenix, Seattle

[Open the gallery](index.html) · [Generator values](archetypes-values-v2.json) · [Prompt set](prompts.json)

**7 October 2026 · Design proposals, not implemented engine rules, surveyed blocks or zoning standards.** Each metro has four paired street/aerial archetypes, full specification sheets and one proposed block-mix paint-over.

## Boards

| Metro | Board | Archetypes |
|---|---|---|
| NYC | [HTML](nyc-board.html) · [PNG](nyc-board.png) | Brownstone/brick rowhouse; brick tenement; Queens Tudor/Storybook row; urban mid-rise |
| Los Angeles | [HTML](la-board.html) · [PNG](la-board.png) | Spanish Colonial Revival; California Craftsman bungalow; postwar ranch; dingbat/stucco-box apartment |
| Phoenix | [HTML](phoenix-board.html) · [PNG](phoenix-board.png) | Stucco/masonry ranch; Southwest flat-parapet; tile-roof subdivision; midcentury low-gable/carport |
| Seattle | [HTML](seattle-board.html) · [PNG](seattle-board.png) | Craftsman bungalow; Tudor/English cottage; postwar rambler; modern townhouse cluster |

The artwork PNG for each archetype is the paired-view illustration. Its `*-sheet.png` is the complete browser-exported specification sheet, matching v1's header, paired view, six geometry fields, four palette variants and three detail tiers. Each metro's `*-board.png` includes its street scene, street-character notes and all four sheets. HTML versions retain expandable source and approved contrast-witness notes.

## Locked style, lighting and schema

`sharedLighting` and `approvedHouseValues` are copied unchanged from approved `house-archetypes-v1/archetypes-values.json`. The shared hero fixture remains sun elevation 40°, azimuth 225°, sun colour #FFE8C6, blue sky #73A5CC / #A2C4DC / #DBDCD1, cool-neutral shadows, exposure +0.35 EV, contrast 1.06 and saturation 1.08. Asphalt #626A70, concrete #C5C0B3 and the natural-lawn baseline #73865B remain unchanged. Dry gravel, mulch or stressed grass are surface choices, not per-metro lighting grades.

The values file deliberately retains the **`worldengine.house-archetypes.v1` schema identifier and v1 top-level structure**; “v2” is the pack/version filename, not an incompatible schema. Existing archetype field names and screen-size tier structure are retained. `inheritedHouseValues` preserves approved contrast witness values; `colourVariations` supplies the new archetype's proposed wall/trim/roof/glass swatches. These are not measured albedos or observed colour frequencies. The witness's original wall hex is not a mandate to recolour every metro building alike.

The image generation used the approved Denver bungalow paired view and Denver hero as visual anchors. Style B means readable matte massing, real light and colour, recessed windows, dark porch/eave voids and broad trim; illustration detail is not a demand for runtime brick/tile/grass geometry. No yellow rim outlines, purple/lavender grade, photoreal photo textures, logos, house numbers, real addresses or people.

Numerical fixture equality is checked in JSON. AI illustrations cannot establish pixel-exact hex equality, photometric calibration or a solved camera matrix. The legacy approval-number ambiguity recorded in v1 is preserved verbatim; this pack uses its actual shared fixture rather than introducing a new interpretation.

## Street character and access

- **NYC:** paved stoops/areaways and tree pits on attached blocks; small lawns only in the Queens row treatment. Broad deciduous crowns, no palms. Concrete sidewalk baseline with supported bluestone/granite exceptions. No speculative front garages or curb cuts.
- **LA:** small lawns mixed with drought planting, mulch and gravel; broad shade trees plus occasional palms, rather than palms on every frontage. Side drives suit older forms; front aprons are conditional for ranches. Dingbat parking is a broad shadow void with separate pedestrian access, not a structural-engineering model.
- **Phoenix:** dry yards and desert-adapted shade coexist with irrigated lawn pockets. Airy desert crowns, restrained optional palms, block/stucco privacy walls. Historic low ranch/carport and later tile-roof forms have different roof and entry rhythms.
- **Seattle:** natural green lawns and layered shrubs with deciduous street trees and selected rear conifers. Stoop/retaining edges follow actual grade. Townhouse paths/courts remain distinct from detached rambler driveways. No palms.

All exact widths, spacing, mix weights and physical envelopes are proposals. Mapped trees, sidewalk/curb geometry, footprints, floors, roofs and driveway access override defaults. Unknown utility evidence means **overhead wires off**. The JSON and boards state this explicitly; a city's architectural era does not locate poles or spans. An optional inferred art mode would require clear inferred labels and its own approval.

Screen tiers use v1's proposed building-height measure: **<6 px** silhouette and broad colour; **6–20 px** entry/porch/areaway/carport voids; **>20 px** large openings, cornices and supported dormers. They are unbenchmarked design controls. Preserve geometric silhouette at every tier; flatten fine brick joints, roof tile ridges, brackets and railings to material/colour cues when subpixel.

## Inputs and camera provenance

The requested `metro-onboarding-v1` folder initially did not exist, then appeared while this work was in progress. Its `metros.csv`, `datasets.csv` and `sources.md` were read and hashed, together with `regional-look-catalog-v1` and the approved v1 values. Target-metro onboarding rows are retained as source context in the JSON; they are proposed test-area guidance, not observed rendered geometry.

Recommended onboarding areas are Brooklyn Heights/Cobble Hill, Angelino Heights/Echo Park, Coronado and Queen Anne. The block pictures are **typological examples, not claims that every illustrated family exists in those proposed 1.5 km test boxes**. Phoenix's broader archetype menu intentionally includes later subdivisions that should not be forced into the historic Coronado first tile. Seattle's flat substitute camera cannot validate Queen Anne's slope treatment.

No NYC, LA, Phoenix or Seattle engine captures were found in the inspected repository fixture/capture lists. Each paint-over uses a current composition from the latest inspected lookloop run **20261007-101255**:

| Target metro | Substitute current render camera | Selected local mix |
|---|---|---|
| NYC | Lakeview `lakeview-postcard-afternoon.png` | Dense brownstone/brick rows; occasional tenement and distant mid-rise; Queens type excluded from this block |
| LA | Denver `ordinary-street-afternoon.png` | Spanish/Craftsman with selected ranch and distant dingbat |
| Phoenix | Denver `ordinary-street-afternoon.png` | Low ranch/flat-parapet, occasional tile-roof house; dry and irrigated planting variation |
| Seattle | Lakeview `lakeview-postcard-afternoon.png` | Craftsman/Tudor rhythm, modest townhouse infill and distant wider-lot rambler |

Exact source paths/hashes and `cameraPixelExact: false` are in `streetScenes`. Preserve camera perspective/road corridor as composition references; the AI paint-over is not a pixel-perfect edit, geospatial capture or projected-engine render of the target metro. No new engine renders or builds were run. Source captures remain untouched.

## Evidence and limits

Regional family and street-character context is inherited from the catalogue's cited city/district sources. This does not establish metro-wide architectural prevalence. Every exact dimension, pitch, palette, setback, frontage, entry depth and mix weight in this pack is a proposal; actual geometry wins.

Checks on 2026-10-07: [NYC LPC's Queens Tudor/Storybook designation](https://www.nyc.gov/site/lpc/about/pr2022/lpc-designates-two-historic-districts-in-cambria-heights-queens.page) and [NYC sidewalk guidance](https://www.nyc.gov/site/designcommission/design-review/design-guidelines/distinctive-sidewalks.page) were accessible. The [Seattle townhouse paper](https://seattle.gov/Documents/Departments/OPCD/Vault/Multifamily/TownhousesWhitePaper.pdf) is an **April 2006 staff draft**, useful for historical typology rather than today's code; the new flat-roof cluster is a contemporary design proposal. SurveyLA's [multifamily context](https://planning.lacity.gov/odocument/1a7b1647-4516-45da-9cff-db2db3b9b440/Multi-FamilyResidentialDevelopment_1910-1980.pdf) identifies Dingbat/Stucco Box in indexed official text; direct PDF fetch timed out. The Spanish Revival PDF also timed out. The inherited Phoenix flat-parapet PDF returned 404, and the Washington ranch page returned 403: those inherited links were **not reverified**, and no blocks were bypassed. These families remain clearly labelled proposals where fresh verification is incomplete.

The onboarding review flags the older King County residential-building route as non-public. Seattle detection now points to the authoritative assessor download route, still pending source-specific permission/access review. No owner, resident or contact fields are included in archetype rules. City/source licences and ODbL requirements remain applicable to any future actual map integration; generated reference images do not grant rights to external plans, assets or datasets.

## Generation and verification

Built-in image_gen generated each paired-view artwork and camera paint-over. `prompts.json` and the JSON `generation.promptSet` record prompts and references; targeted corrections, if any, are recorded separately. At most one edit pass per asset. PNG sheets/boards are rendered from the matching HTML layout, not AI-generated typography. Original approved packs and input images are unchanged.

Verified: 16 final paired-view archetype images, 16 exported specification sheets, four block paint-overs and four exported metro boards. All 20 gallery images load at a 390 px viewport, with no horizontal overflow or page errors; phone preview and selected exported sheets/boards were visually inspected. All 221 local HTML/README file references resolve. JSON parses; v1 top-level schema keys and archetype fields are retained; shared lighting and approved house values are exactly equal to v1. The two NYC correction drafts are preserved in `drafts/` and their edit records are in the values file.

No GPU/device benchmark, solved camera pose, measured hex equality or neighbourhood validation is claimed. Runtime dimensions and light settings come from the JSON, not measurements taken from the concept art. The illustrations share the approved visual target; fine tree/brick/grass detail must simplify at phone distance.
