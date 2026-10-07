# Japan infrastructure kit v1 — grounded Style B

**7 October 2026 · Proposals only.** [Gallery](index.html) · [Values JSON](infrastructure-values.json) · [Download all files](japan-infrastructure-kit-v1-all-files.zip) · [Prompts](prompts.json)

Twelve infrastructure family sheets cover every requested subject, using the existing infrastructure kit's **street 3/4 / aerial 3/4 / far** layout. Each has a three-panel artwork, standalone HTML specification and full PNG sheet, four hex palette options, metre dimensions and three projected-size tiers. Related submodules are grouped rather than generating a separate sheet for every wall or crossing arm.

## Coverage

| Sheet | Subjects |
|---|---|
| [Elevated urban expressway](roads-01-expressway.html) | Connected elevated deck, entry ramp, piers, highway sound walls. |
| [Mountain road](roads-02-mountain.html) | Retaining walls, guardrail, tunnel portal and hillside cut. |
| [Paddy road](roads-03-paddy.html) | Narrow farm route, passing recess, bunds, irrigation channel and access slab. |
| [River embankment](water-01-river.html) | Crest/lower paths, revetment, stepped bank and access flight. |
| [Small bridges](water-02-bridges.html) | Small river girder and canal slab bridges with connected approaches. |
| [Coastal protection](water-03-coast.html) | Seawall, crest path and generic four-arm concrete wave-break blocks. |
| [Port and fishing harbour](water-04-port.html) | Working quay/warehouse, smaller sheltered basin, breakwaters and generic boats. |
| [Crossing and overpass](transit-01-crossing.html) | Ground-level rail crossing gates, warning hardware, pedestrian bridge and stairs. |
| [Bus stop and taxi stand](transit-02-stops.html) | Left-side boarding berth, plain shelter and separate taxi bays. |
| [Station plaza](transit-03-plaza.html) | Bus bays, separate pedestrian forecourt and two-level bicycle parking. |
| [Coin parking](other-01-parking.html) | Small urban lot, stalls, access aisle, wheel-lock plates and generic payment cabinet. |
| [Utilities](other-02-utilities.html) | Lane-edge distribution poles/transformers and regional power pylons. |

## Style authority

The **current approved Style B Bible calibration street** and `STYLE-B-RULE.md` control realism: real proportions, simplified smooth matte surfaces, gentle material/recess depth and soft light. Do not use the older faceted/chunky infrastructure render language where it conflicts. `house-archetypes-v1` controls sheet typography and lighting; `infrastructure-kit-v1` controls the three-view schema/layout. `japan-regional-kit-v1` vehicles are the controlling transport proportion/material reference, including for the generic harbour boats.

The precise `sharedLighting` object is copied unchanged, and compared for equality against the Bible, house-archetypes and infrastructure values: sun #FFE8C6, elevation 40°, azimuth 225°, sky #73A5CC / #A2C4DC / #DBDCD1, neutral fill #AEBCCA, shadow cue #7F8F99, exposure +0.35 EV applied once, contrast 1.06 and saturation 1.08. Inherited source-anchor ambiguity remains intact. This is an authored review fixture; actual place/time/weather replaces it in the product. AI images do not establish exact metre geometry, shadow bearings or photometric equivalence.

No logos, badges, brands, real murals, operator liveries, readable signage, dogs, people, animals or characters. All contextual vehicles/boats are generic original-design intent, without a real model or operator reference. References containing people or badges are used for style only; their subjects are not requested in the new scenes. Plain payment/stop information surfaces and generic safety patterns are not operational signage. Four-arm coastal blocks are original generic wave-break concepts, not a licensed proprietary product model. Design intent is not legal clearance for a later implementation.

## Japan context and scale

`japan-showcase-v1` and corrected `japan-style-b-v1` define the pilot contexts: **Yanaka Ginza / Yanaka–Sendagi lanes** and **Nishijin / Itsutsuji-dori–Omiya-dori vicinity**. The kit's lane scenes are fictional area-inspired studies, not surveyed street replicas or georeferenced cameras. Exact pilot bounds remain unverified in the source pack. Mixed traditional and modern infill, small frontage changes and short gentle bends are preferred over an endless repeated historic street.

Lane target: **4–6 m wall-to-wall**, nominal 5 m, buildings at the edge, 0–0.3 m frontage setbacks, 0.45–0.8 m eave overhang examples; no public lawn, curb or raised sidewalk. Private pots/gardens stay inside recesses. Near utilities: two detailed poles / three major wire spans within 30 m. Mapped positions remain authoritative; caps simplify detail rather than erase mapped evidence.

Mountain, paddy, coast, port, expressway and station-plaza contexts have their own larger envelopes and do not claim to occur inside Yanaka/Nishijin. A narrow farm route is illustrated at 3 m with a passing recess, not a two-lane urban street. Protected bridge margins, bus waiting footpaths and plazas do not authorize adding sidewalks to adjoining narrow lanes.

**Left-hand road traffic** is the design convention. A generic Japan bus boards on its left; proposed driver placement is right. The [authored plan diagram](left-hand-layout.svg) defines direction: looking down the road, oncoming traffic is viewer right and receding traffic viewer left. This corrects the reversed viewer-direction labels in the inherited regional-kit diagram; that source pack is left unchanged. Do not mirror train/platform direction or vessel operation from this road rule.

Markings are illustrative: white same-direction separators, plain edge lines and a yellow opposing separator in the mountain example. There is no blanket US yellow-median/white-edge recipe, and narrow lanes/farm routes may omit a centreline. Installation-specific line colours, patterns, access and controls must come from applicable source data; these pictures are not traffic-rule standards or paint-tracing templates. Closed crossing gates mean no vehicles pass across the tracks. The example rail gauge is not a universal Japanese railway gauge.

## Values and reuse

`infrastructure-values.json` follows existing schema **worldengine.infrastructure-kit.v1**: `assets`, `dimensionsM`, `palette`, `detailTiers`, `imageViews`, prompts and shared-light references. New `japanContextProposal`, `surfaceValuesProposal`, placement/performance and rights fields are **proposed additions**, not assertions of a supported runtime parser. Dimension keys are metres except those explicitly ending `Count`, which are unitless counts. These are generator examples, never a fixed size for every real object.

Four palettes are options, not four separate rendered versions. Hexes are base-colour swatches, not sampled rendered pixels. Linear luminance uses sRGB decoding and Y = .2126R + .7152G + .0722B; relative brightness compares each base surface to primary, not a lighting/shadow ratio.

All new dimensions, palette choices, widths, spans, field/basin/site footprints, levels, density caps and arrangements are **authored proposals**. None assert surveyed prevalence, road/rail certification, flood/navigation safety, loading capacity, accessibility or electrical clearance. Actual source geometry, tags and elevations win. No geographic dataset was imported.

Reusable parts: road/ramp ribbons, deck spans/piers and wall panels; terrain cuts/portals; irrigation channel/bund/access slabs; embankment/path/step strips; bridge deck/abutments; quay/breakwater/coastal block band; rail segments/crossing/stairs; stop/plaza/parking bays; pole/transformer/pylon families. Keep roads and ramps connected at the correct grade, water openings unobstructed, tide/water planes coherent and stairs/paths grounded.

## Phone tiers and performance

Match the infrastructure kit's component extent tiers: **<6 px** silhouette/colour; **6–20 px** primary voids, supports, connected paths/bays and broad rhythm; **>20 px** sparse resolved paint, openings, rails, stairs and useful coarse details. Pixels are drawable/projected, not CSS pixels or metres. Large sites evaluate local modules (one span, wall panel group, crossing or parking block), so a kilometre-scale extent never forces every wire to remain detailed. Inherited 2 px hysteresis reduces flicker. The Bible's separate ambient-object 48/16/5 px system remains unchanged; this infrastructure kit does not rewrite it.

Never shrink bridges, inflate piers/wires or collapse grade separation to make details readable. Far views communicate composition/simplification intent, not a measured LOD test. The JSON is the authority for suppressing individual wires, cycles, cars, crop stalks, wave-block repetition and surface detail at distance. Fine visual marks in generated art are not instructions to model them individually.

Proposed near-visible infrastructure allocation: **35k triangles / 12 draws**, carved out of the existing scene budget, never added on top of other kits. No extra global pass, shadow map or daytime light. Instance span/pier/panel/pole modules; merge static plaza structures; use material regions/decals for paint, paving, sleepers and crops. Use the existing water material without planar reflection cameras or spray effects. Far infrastructure becomes connected terrain ribbons and simplified structure silhouettes. Keep at most two LOD levels overlapping during 0.3–0.6 s stable-ID transitions, with bounded updates. No runtime meshes, device/GPU/thermal benchmark or engineering implementation is supplied.

## Production and verification

Built-in image_gen generated twelve fresh three-view artwork boards from two approved style/transport references. Final prompts, any targeted correction prompts and selected image hashes are retained. Labels, numerical values and PNG sheet exports are authored outside the artwork. Source files are read only and hashed. Style references include underlying OSM-derived house renders: [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright). Future map/data integration retains its own source licences.

Final artwork review, exact lighting equality, source-hash checks, 390 px layout checks, all local links and ZIP integrity are recorded in the values/manifest and `layout-check.json`. No git commands, builds, engine changes or edits to other packs.

Final checks passed: twelve selected three-view artworks and twelve full-sheet PNG exports; thirteen phone-width pages with all images loaded, no horizontal overflow or page errors. Four palette options and three tiers per asset validated. Approved numeric lighting matches all three source values files exactly; referenced source hashes remain unchanged. Six single correction passes removed incidental vehicles in selected scenes; bus/taxi/plaza bays are intentionally empty so the infrastructure layout stays clear.
