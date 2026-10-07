# Japan regional kit — Style B v1

**7 October 2026 · Design proposal.** [Gallery](index.html) · [Values JSON](regional-kit-values.json) · [All files ZIP](japan-regional-kit-v1-all-files.zip) · [Prompts](prompts.json)

Nine reference sheets extend the approved **japan-style-b-v1 r2** pack. They use its exact sheet CSS, warm-neutral mid-afternoon lighting block and values conventions: metre envelopes, hex base colours, linear luminance witnesses, palette variants and three phone detail tiers. Rich smooth forms, soft light and gentle material depth; no photo textures. The kit is an art/data proposal, not implementation, surveyed geometry or an engineering specification.

## Sheets

1. [Seasonal street trees](01-seasonal-trees.html): ginkgo, zelkova, sakura and maple. Artwork rows follow that order; columns are spring, summer, peak fall and winter. Broad crown lobes, branching gaps and dark grounding pools carry identity.
2. [Garden plants](02-garden-plants.html): layered pine, contained bamboo, potted foliage/flowers, planters, hedges, moss/ground cover. Street/aerial private-garden context and seasonal supporting vignettes.
3. [Regional landscape](03-regional-landscape.html): rice-paddy edges, bunds and irrigation; cedar/cypress-like mountain forest. Low and aerial views, planted spring / green summer / harvest / fallow winter. These are regional art presets, not nationwide crop calendars or species identification.
4. [Yards and edges](04-yards-edges.html): block walls, timber fences, sliding gates, gravel, tiny gardens and generic balcony laundry/plants. Private recesses, not public lawn strips.
5. [Vehicles](05-vehicles.html): kei-size car/truck, compact car, unmarked generic taxi, delivery scooter, mamachari bicycle, small bus and garbage truck. [Left-hand layout diagram](left-hand-layout.svg) defines travel direction; generated context is illustrative.
6. [Rail families](06-rail-vehicles.html): commuter EMU, subway car, original rounded-nose high-speed concept, local diesel railcar and tram. New generic proportions/palettes, no specific real-model or operator-livery reference.
7. [Track infrastructure](07-track-types.html): elevated concrete viaduct, ground crossing, embedded tram, catenary, sleepers/ballast and generic crossing barriers.
8. [Stations](08-stations.html): elevated station, one-platform local stop, original terminal exterior, screen doors, ticket gates, plaza bus bays and bike racks. Functional silhouettes, not named station copies.
9. [Street furniture](09-street-furniture.html): horizontal traffic signals, blank generic sign shapes, lamps, plain mailbox, vending cabinets, generic manhole covers, transformer poles, crossing hardware and blind-corner mirrors.

Each HTML sheet includes the illustration, item dimensions and palette, placement notes, seasonal values where relevant, tiers and a downloadable complete PNG sheet. The gallery adds density tables by street type. **59 canonical asset/module envelopes** are supplied, not 59 individual generated pictures. Nine artwork boards and nine complete labelled PNG sheets are included.

## Scale, density and provenance

Yanaka/Nishijin lane contexts stay **4–6 m wall-to-wall**, nominal **5 m**, flush gutter/threshold edges, no curb, raised sidewalk or public lawn. Buildings meet the lane and eaves overhang. Keep short gently bending sightlines; avoid repeated house rows. Garden vegetation belongs in private recesses/courtyards. Street trees in narrow public lanes default to **zero**; wider roads need observed planting space before trees are added.

Authored lane density: 1–3 private trees per 10 eligible frontages, 1–3 pots per eligible recess with a visible cap of 12 per 100 m, 0–2 hedge runs and 0–1 vending/mailbox per 100 m. Lamppost target 2–3 per 100 m, pole spacing 25–40 m, but near render detail caps at two poles / three major spans within 30 m. These are optional composition defaults, not measured prevalence. Actual mapped items override caps; simplify their appearance rather than deleting mapped evidence.

Wider local collectors, station plazas, agricultural edges and mountain forest have separate density defaults in the JSON/gallery. Do not apply plaza bus bays or rail corridors to five-metre residential lanes. Large vehicles require actual route and width evidence. A narrow lane can be constrained/shared without a centreline; the six-metre two-way plan diagram is an illustrative layout, not a mandate to split every lane into two traffic lanes.

All generated dressing is **inferred/simulated**, never observed or live. Stable feature/cell IDs plus kit revision and object class seed selection; keep the seed across seasons and detail levels. Preserve mapped positions and access. If boundaries/clearances are unknown, omit conflicting decorations. Private laundry is generic fictional dressing, not resident data. Parked vehicles go in confirmed/private bays; inferred on-road parking defaults to zero.

## Values and lighting

`regional-kit-values.json` retains schema envelope `worldengine.house-archetypes.v1`; **regionalKitProposal is an explicitly proposed extension**, not a claim that the current engine accepts these fields. It uses the approved `dimensions`, `colourVariations`, `surfaceValuesProposal` and `detailTiers` conventions. `archetypes` is empty because these are regional objects rather than houses.

The shared lighting block is copied **unchanged**: sun #FFE8C6 at 40° elevation / 225° azimuth; sky #73A5CC / #A2C4DC / #DBDCD1; shadow appearance #7F8F99; exposure +0.35 EV once, contrast 1.06, saturation 1.08. Any inherited lawn/curb swatches are retained solely for exact block equality and must not enable them in lanes. Source hashes identify the approved inputs.

Hexes are **base albedo targets**, not pixel samples or guaranteed output colours. Linear luminance decodes sRGB using the standard piecewise transfer function and Y = .2126R + .7152G + .0722B; relative brightness compares secondary to primary base colour, not lit/shadow contrast. Apply lighting once. Image shadow direction and material pixels are illustrative, not calibrated renderer output.

Seasonal plant/field colours and snow caps are supplied per item. Evergreens retain green form; deciduous winter crowns are bare. Snow is optional, weather-supported in the product, not automatically applied every Japanese winter. Detailed leaf, needle and crop marks visible in artwork are colour/normal/shape cues, not a requirement to model individual leaves, needles, pebbles or rice stems. The base form and silhouette outrank fine generated marks.

## Phone detail and performance

Tiers use **projected longest asset dimension in drawable pixels**, not CSS pixels or distance alone: below 6 px keep silhouette/colour; 6–20 px keep branch, wheel, canopy, recess and broad glass masses; above 20 px allow sparse gaps, seams, baskets and transformer masses. Wires/slats also need roughly 1.5 px projected thickness; otherwise merge/omit decorative strands. Never change actual road/rail geometry to fit a tier.

Proposed visible near-kit carve-out: **35k triangles / 12 draws**, inside the existing scene budget, not additional allowance. No new global passes, shadow maps or daytime lights. No A16 benchmark was performed; draw/shadow submissions and GPU time need measurement before acceptance.

Use opaque clustered foliage; batch family vehicles/props; merge station structures and rail modules. Far trains become one shell, forest becomes canopy masses then landcover. Use shared surface fields for gravel/moss/paddy rows/manhole patterns rather than tiny geometry. Mirrors use a painted reflection cue, not another camera. Train windows/screen doors use dark opaque glazing at most distances. Emission cues do not require a light per vending machine or window. Restrict wires and their shadows to the near treatment. Only two adjacent LOD levels may overlap during 0.3–0.6 s transitions; seasons swap palette/visibility on stable geometry rather than retaining four copies.

## Generic design constraints

No logos, brand names, real operator liveries, readable signage, addresses, real people or religious emblems. Blank sign shapes have no asserted traffic-rule meaning; no pseudo-kanji. Vehicle and rail artwork was requested as original generic form, without real-model reference. That design intent is not legal clearance; final model/livery similarity must be assessed on the implementation. Plain mailbox has no postal insignia; vending cabinets have abstract product colour blocks only.

## Production and verification

Artwork: built-in image_gen, nine individually prompted fresh images using the approved machiya image as a style/lighting reference. Typography, values and sheet exports are authored outside the raster art. Prompts and image/source hashes are included. All exact dimensions, density counts, palettes, seasonal intensity and performance caps are **authored proposals**; no new survey, botanical prevalence, regulatory or engineering claim is made. No map data was imported. No engine code, git commands or changes to other packs.

Final browser/layout and ZIP checks are recorded in `layout-check.json` and `image-manifest.json`.
