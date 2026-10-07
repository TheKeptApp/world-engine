# Japan Style B v1

[Gallery](index.html) · [All files ZIP](japan-style-b-v1-all-files.zip) · [Values JSON](japan-values.json) · [Prompts](prompts.json)

**7 October 2026 · Design proposal only.** Fictional Japanese typologies and street scenes for WorldEngine. Nothing in this pack is a surveyed address, observed/live scene, approved zoning rule, structural design or imported Japan dataset.

## Contents

- Eight paired street-three-quarter / aerial archetype illustrations, eight HTML specification sheets and eight `*-sheet.png` exports: Tokyo two-storey wooden/siding house; small modern concrete house; four-storey low-rise apartment (“mansion”); shotengai shop-house; Kyoto machiya; generic roofed precinct gate; unbranded corner convenience shop; narrow-lane mixed block.
- [Archetypes board](archetypes-board.html) · [PNG](archetypes-board.png).
- [Street-character board](street-character-board.html) · [PNG](street-character-board.png): narrow lanes, utilities, blank vending cabinet, parked bicycles, pot gardens and blank colour signs.
- [Block-scenes board](scenes-board.html) · [PNG](scenes-board.png): Tokyo residential lane, Kyoto historic street, generic Tokyo river skyline at golden hour and Kyoto night with plain lanterns and lit windows.
- [Seasons board](seasons-board.html) · [PNG](seasons-board.png): the same Kyoto street in sakura spring, summer, momiji autumn and light snow. `kyoto-summer.png` is an exact copy of the original summer base, `kyoto-street.png`.
- `japan-values.json`: metre envelopes, palettes, linear base-colour luminance ratios, screen tiers, street props, seasonal colours, lighting states, provenance and performance proposals. `prompts.json` records built-in image_gen generation and requested seasonal/night edits. `image-manifest.json` records selected outputs.

## Approved daytime target and sheet format

The daytime `sharedLighting` and `approvedHouseValues` blocks are copied **unchanged** from `house-archetypes-v1/archetypes-values.json`, which carries the approved house-contrast-v1 fixture. Sun elevation **40°**, azimuth **225°**, sun **#FFE8C6**; sky **#73A5CC / #A2C4DC / #DBDCD1**; cool-neutral shadow cue **#7F8F99**; exposure **+0.35 EV**, contrast **1.06**, saturation **1.08**. Neutral asphalt **#626A70**, warm-grey concrete **#C5C0B3**. Apply exposure once. No separate Tokyo/Kyoto colour grade, yellow edge lines, purple/lavender sky or ground, or pink haze.

The **original v1 CSS** is copied directly from `denver-01-square.html`. Sheets keep its paired artwork, six geometry fields, four palette variants, three screen tiers, access/yard notes and expandable evidence section. Added Japan surface values remain inside the notes. Typography is rendered by the browser, not generated in the artwork.

Style B uses smooth broad forms and plain matte building surfaces; siding divisions and machiya lattice are sparse structural cues, not photo texture maps. Keep the eave underside, canopy and recessed entry dark enough to read. AI reference images contain illustrative fine roof/foliage detail: do not reproduce those marks as thousands of roof tiles, leaves or grass blades. Artwork is not a material texture source.

Numerical fixture equality is verifiable; image pixels are **not** photometrically calibrated. The approved source's unresolved legacy paint-over #5 identity note is preserved rather than reinterpreted. The actual shared fixture and named Denver visual anchors govern this pack.

`inheritedHouseValues` is the unchanged v1 contrast witness, not a request to give Japan Chicago wall colours. `surfaceValuesProposal` and `colourVariations` give the new Japan palettes. Base-colour luminance is computed by sRGB decoding, then **Y = 0.2126 R + 0.7152 G + 0.0722 B**; relative brightness is Y divided by that archetype's proposed wall Y. These are base-colour ratios, not final illuminated pixels or measured shadow strength. Do not apply the dark recess swatch as a second full-surface shadow overlay.

## Geometry and identity

All dimensions, roof pitches, setbacks, frontages, prop sizes and combinations are authored proposals. Production mapped footprints, floor counts, roof tags, road geometry and access take precedence. No regional prevalence weights or automated architecture classifier are supplied.

The precinct gate has **zero enclosed floors** and is a generic timber roofed portal, not a torii or a copy of a real temple/shrine. No crests, sacred ropes, prayer plaques, statues, icons or other religious emblems. The mixed-block sheet's **26 × 24 m** is a block envelope, not a single house footprint: its houses, shop and apartment have separate 2–3-storey component envelopes. The JSON states that distinction.

The corner shop uses a muted slate-blue accent and plain fascia. Avoid recognizable brand colour-strip combinations or trade dress. Every sign, vending panel and lantern is blank; no imitation Japanese writing. Merchandise, where visible, is generic plain massing. No logos, readable brands, real addresses, people or human silhouettes.

Archetype lot surroundings are illustrative sheet context. They do not mandate lawns or sidewalks across Japan. The narrow-lane street board and block scenes supply the intended street treatment: small parcel gardens and frontage recesses, drainage edges and a continuous clear lane.

## Scene sources and seasonal invariants

No Japan source camera was available in the inspected lookloop captures. Tokyo and Kyoto paint-overs reference the current Lakeview **`20261007-101255/raw/lakeview-postcard-afternoon.png`** composition: an eye-level vanishing-point guide, not a solved Japan camera pose. Lane widths, architecture and sidewalks deliberately change. These are fictional re-designs, not purported Tokyo/Kyoto engine captures. The river skyline is a **new generic concept**, because no Japan river render was available; no real landmark reconstruction or exact geographically validated skyline is claimed.

The four Kyoto seasons and night use **one generated summer base**. Preserve camera, facade order, eaves, road and drains, poles, bicycle, pots and tree trunk bases. Spring blossoms belong to the original right-hand cherry; the left maple remains spring green. Autumn brings maple reds/ochres and modest edge litter; light snow caps roofs and pots with a mostly clear central lane. No blanket cherry-tree tunnel, extra houses or changed sun fixture. Seasonal occurrence and snow cover are authored examples, not forecasts or calendar promises. AI edits may vary small details; the JSON/base composition remain authoritative.

## Golden hour and night

Golden hour is a separate **authored proposal**, not another approved afternoon preset: sun elevation **15°**, azimuth **225°**, sun **#FFD9A3**, sky **#6E9CC3 / #AFC3D0 / #E8CDA7**, exposure **+0.35 EV**. Replace the daytime sun/sky; keep plain material colours. No second warm post-grade. Actual WorldEngine solar calculations override illustrative fixture angles in live/recap use.

Night copies the exact `night-fog-v1` **night state**, window block and shared streetlight budget: sky **#15243C / #243854 / #344255**, direct sun **0**, sky fill **0.24** and ground fill **0.08** relative to noon, exposure **+0.35 EV**, haze **#475568**, extinction **0.002 / m**, **no ground fog**. About **30% of eligible window apertures**, rather than 30% of buildings, are lit; warm emission **#F3D0A0**, relative level **1.1**. Seed selection from stable building/aperture IDs; no per-frame flicker. Replace hero lighting, never sum EV or keep the day sun on.

Japan lantern diameter **0.35 m**, height **0.6 m** and placement are new art assumptions. Reuse window warm emission and capped halo; avoid point lights for individual windows/lanterns. Night shares **at most six local pool fields** and **two actual unshadowed lights** across lamps, lanterns and any future vehicles. Occlude halos with scene depth; no new full-screen bloom or shadow maps. No invented moon/star catalog or religious lantern markings.

## Phone construction priorities

1. Preserve distinctive massing, roof/eave silhouette and deep entry voids.
2. Use broad balcony bands, sparse machiya slats and blank storefront fascia; keep the gate passage open.
3. Render utilities as a few merged, capped camera-near spans; their locations are **inferred concept dressing**, not observed infrastructure or engineering clearances. Fade cables below about 0.7 projected pixels rather than vibrating thin lines; suppress distant/aerial wire clutter. No cable shadows or one draw per strand.
4. Batch pot/bicycle/vending variants and keep walking routes and doors clear. Simplify spokes, vending products and lattice before increasing the geometry budget.
5. Keep night fill and a few grounded light pools; add no independent light per glowing object.

Screen thresholds retain v1's proposed **building height in drawable pixels**: **<6 px** silhouette/broad colour; **6–20 px** entry/eave shadow and balcony/open-gate voids; **>20 px** broad trim, windows and sparse slats. These are unbenchmarked design tiers. No additional daytime lights, full-screen passes or shadow maps are allocated. Fit all new props inside the existing world budgets; this pack does not establish an A16 frame-time result.

## Evidence

Research checks **2026-10-07**, limited to context rather than numerical defaults:

- [GO TOKYO's neighbourhood shopping-street guide](https://www.gotokyo.org/en/story/guide/neighborhood-shopping-streets/index.html) supplies official shotengai context. It does not validate these shop-house dimensions or street mixes.
- [Kyoto's official accommodation guide](https://kyoto.travel/en/accommodations/) describes machiya as traditional wooden homes. The [official machiya guide](https://plus.kyoto.travel/entry/kyomachiya) provides typological context. Lattice spacing, roof pitches, materials and the fictional depicted block remain proposals.
- [MLIT Road 2023](https://www.mlit.go.jp/road/road_e/pdf/Road2023web.pdf), official indexed text, discusses utility-pole removal. It does not locate this pack's poles or justify engineering clearances. No Japan-wide overhead-wire prevalence claim is made.

No third-party photography, plans or Japan map data are imported. Later map integration must retain source attribution, provenance and source-specific licence requirements.

## Verification

All **16 unique generated artworks** were visually inspected; summer is a byte-identical alias of the Kyoto base, giving 17 named artwork files. Eight full sheet PNGs and four board PNGs were exported from v1-format HTML. Selected full-sheet, season-comparison and phone previews were inspected. At **390 px**, all **17 gallery images load**, with no horizontal overflow or page errors. 168 local HTML/README references were checked; the download ZIP is created at final packaging.

Shared daytime lighting matches both approved house-contrast-v1 and house-archetypes-v1 **exactly as JSON**. The copied night state, windows and streetlight settings match night-fog-v1 exactly. Source file hashes remain unchanged. Eight archetypes each have four palette variants and three detail tiers, with valid hex colours. No corrective re-generation was needed; four requested seasonal/night edits used the same base. Built-in image_gen was used throughout.

No device/GPU benchmark, pixel-exact photometry, solved Japan camera pose or surveyed neighbourhood validation is claimed. Use the numeric values for runtime envelopes/light settings, and simplify fine illustration marks at phone distance. Original packs and repository captures remain unchanged; no git commands or builds were run.
