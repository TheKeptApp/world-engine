# WorldEngine — Chicagoland and Miami regional proposal v1

**Proposal only · reviewed 2026-10-05 · no runtime activation**

WorldEngine should read as a place before a character is added. Begin with an inland Wilmette or Evanston block, then a dense Lakeview block. Keep the North Shore, Chicago neighborhoods and downtown distinct through building mass, street enclosure and canopy structure. Miami follows once evergreen broadleaf trees, palms and tile-roof silhouettes are supported.

## 1. Evidence, scope and files

**[R]** means researched: a cited external source or inspected repository contract. **[J]** means judgment: an assumption, art prior, proposed parameter or derived calculation. **[M]** would mean measured with a reproducible survey method; **no regional measurements are claimed here**. All sources were checked on **2026-10-05**. Bracketed source IDs resolve to the linked source register at the end and to `sources.json`. Unless a paragraph explicitly says [R], the entire paragraph, table, rule and numerical value inherits **[J]**. An accurate description of an architectural family does not establish its frequency in a municipality.

The user confirmed **phase 5B = one suburban test plus one dense city test**. Downtown, major transit structures and Miami are specified for later. All files in this delivery live in this folder. No production files, other proposal folders or repository history were changed for this expanded delivery.

| File | Purpose |
|---|---|
| `profiles/*.json` | Eleven standalone `StyleProfile` v2 objects, unchanged runtime format |
| `region-catalog.json` | Existing `RegionCatalog` format; 18 explicit review windows |
| `regions-draft.json` | Existing proposal-envelope pattern: profiles, catalog, sources and separately marked `proposedAdditions` |
| `profile-evidence.json` | Exact JSON-pointer provenance for every profile/catalog/proposed-addition scalar and null |
| `fixtures.json` | 21 synthetic dated acceptance cases, seven camera definitions, computed sun directions/events |
| `images/` | Ten generated concept images, with no character |
| `image-manifest.json`, `IMAGE-PROMPTS.md` | Image lineage, selected outputs, limitations, hashes and exact prompts |
| `validation-report.json` | Actual decoder, structural, semantic and reference checks |

## 2. Existing format, zones and adoption gates

**[R: LOCAL-SCHEMA, LOCAL-REGIONS]** `StyleProfile` v2 provides seasons, tree silhouette weights, house types, situation-dependent type weights, garages, sheds, chimneys and foundations. `RegionCatalog` already contains ordered `{id, profile, bounds}` entries; the first containing bounding box wins. Multiple entries may reference one profile. **A new zone schema is unnecessary.** There was no standalone authoritative JSON Schema file to validate against; the Swift Codable declarations are the contract.

Use the catalog's existing entries as named review windows. Dense north-side windows share `chicago-dense-north`; Logan Square, Wicker Park and Lincoln Square share `chicago-greystone-twoflat`. Bungalow and South Side windows have separate profiles. These rectangles are approximate review extents, **not municipal or neighborhood boundaries**, and should not be deployed as comprehensive coverage. Their coordinates are [J], with no claimed survey precision. The order is intentional, including the small Wilmette/Kenilworth overlap. Outside the windows, the catalog depends on the pre-existing proposal profile `generic-temperate-v1`; this is an external dependency, not a file silently supplied or activated here.

Proposed selection precedence: explicit approved test override, then feature representative location through the existing ordered catalog, then default. Record the chosen profile per feature and retain it across camera motion. An engine that currently picks one profile at package center needs **per-feature selection behavior**, not a new JSON layout, before it can represent a package crossing suburb/city/downtown. A building crossing a boundary gets one profile; do not split its roof or interpolate architectural families. Ground/canopy priors may feather over a proposed 50 m boundary band, subject to source geography and stable seeds.

**[R: LOCAL-GEN, LOCAL-SCHEMA]** The current generator's roof repertoire and selection behavior are narrower than this proposal's architecture vocabulary. In particular, the current block path picks a flat-roof type rather than dispatching every apartment/tower family. More family IDs in JSON do not implement a courtyard, a turret or a tower setback. Profile `floors` is an eligibility list whose **first value is the default**, not a weighted height distribution. Colors are `[wall, trim, door, roof]`; roof mix weights describe only gabled, hipped and flat forms.

These JSON files decode today. They are not a claim that all pictured architecture renders today. Keep the following additions outside runtime profiles, in the existing `proposedAdditions` envelope and this document:

- Roof assemblies, dormers, turrets, porch/stair assemblies and material identity beyond a palette.
- Court/rowhouse/institution/tower role dispatch, inner-ring preservation and explicit multi-part heights.
- Leaf habit, palms, species phenology, continuous seasonal weights and surface management.
- Lot/setback priors, eligible dressing cells and street fixture families.

OSM dimensions, outlines, holes, heights, levels, roof tags and material tags outrank every prior. Never stretch footprints to satisfy an architectural ratio, add an unmapped building volume, carve out an invented courtyard, or manufacture a garage from a regional expectation. An unresolved role stays a simple mass at the supported height. Unknown downtown buildings default to a modest `plainBlock`, not a randomly selected skyscraper. Actual tall tags must not be clipped to a profile's default or maximum listed floor count.

## 3. North Shore: building and lot grammar

**[R: EV-ARCH, WIN-FORM, WIL-FORM, KEN-FORM]** Municipal and preservation references support the region's Tudor, revival, Prairie and varied historic vocabulary. Their sampling differs: Wilmette's cited appearance guide and Kenilworth's cited survey concern village-center/business contexts; they do not establish residential shares. The table below is a proposed generator grammar, including all dimensions and prevalence choices [J]. Width/depth describes a dominant mass, not an instruction to resize mapped geography. Roof height comes from supported ridge/span/pitch, rather than a second arbitrary story count.

| Family | Mass and walls | Roof assembly | Identity details to preserve |
|---|---|---|---|
| Tudor Revival | 1–2 wall stories; dominant width/depth 0.65–1.0; brick or cream stucco panels | 40–52° gable; subordinate crossing gable 0.35–0.60 main width; eaves 0.15–0.35 m | One tall chimney, asymmetrical entrance, at most two broad half-timber strips on a near stucco gable; no timber grid texture |
| Colonial / Georgian Revival | Usually 2 stories; width/depth 1.1–1.6; brick or subdued siding; centered entry | 28–40° side gable or hip; eaves 0.25–0.45 m; zero to two near dormers | Symmetrical bay rhythm, modest entry pediment, one or two chimney silhouettes when supported; Georgian reads through order, not applied ornament |
| Prairie School | 1–2 stories; width/depth 1.3–2.0; brick/stucco; strong horizontal bands | 12–22° hip, broad 0.65–0.95 m eaves; one low secondary wing | Low grouped windows, sheltered entry, broad chimney; never turn every broad footprint into a Prairie house |
| Victorian / Queen Anne | 2 wall stories plus roof volume; width/depth 0.7–1.1; siding with restrained accent | 38–50° gable/hip intersections, one prominent cross-gable; optional supported turret | Porch silhouette and asymmetric mass; at most one bay/turret, no lacework, finials or miniature shingles |
| Shingle style | 1–2 wall stories; connected irregular masses; cool gray/olive siding | 35–48° broad gable/hip combination; one secondary ridge | Continuous wall color crossing volumes, deep porch opening, optional broad dormer; no individual shingle pattern |
| Mid-century | 1–2 stories; width/depth 1.3–2.0; muted brick, occasional siding | 12–24° simple gable/hip; long eave | Broad living-room window, low entrance, simple wall planes; attached garage only if supported by mapped volume/access |
| Modern infill | 1–3 stories; compact rectilinear mass, stucco/quiet panels | Flat 0–4° concealed slope, 0.25–0.45 m parapet | Larger openings and one recess; no all-glass mirror walls, invented cantilevers or uniform white cubes |
| Evanston courtyard / downtown mid-rise | Court 2–4 stories, mid-rise review 4–12; masonry or quiet contemporary mass | Predominantly flat with parapet; pitched accent only if supported | Preserve actual court void and entry axis; supported downtown height/density overrides detached-house priors |

### Differences among the four suburbs

All ranges and mix percentages here are [J] starting envelopes, not zoning requirements or measured distributions. “Lot” refers to a hypothetical eligible residential cell when parcel geometry exists; **the engine must not generate cadastral boundaries from these numbers**. The table is descriptive for review, not permission to move roads/buildings or fill every space.

| Area / profile | Selected fallback mix: Tudor / Colonial / Prairie / Queen Anne / Shingle / mid-century / modern | Lot width × depth; front setback | Site character |
|---|---|---|---|
| Evanston | 22 / 26 / 10 / 14 / 8 / 12 / 8 | 10–20 × 30–45 m; 4–8 m | Smaller detached rhythms mixed with apartment masses; paved or unpaved rear access where mapped; smaller hedges and front porches |
| Wilmette | 25 / 27 / 12 / 10 / 8 / 13 / 5 | 12–24 × 35–50 m; 6–10 m | Deep green parkways, varied revival roofs, side/rear garage access; public street lights and brick only where evidence supports them |
| Winnetka | 26 / 25 / 13 / 12 / 10 / 9 / 5 | 18–32 × 40–65 m; 8–15 m | Larger tree/setback scale, more visually connected garden canopy, house silhouettes partially obscured by planting |
| Kenilworth | 30 / 25 / 14 / 10 / 9 / 7 / 5 | 18–30 × 40–60 m; 8–14 m | Restrained Tudor/Prairie/revival priors, mature canopy and generous planting, no assumption of walls around every property |

These are the `unknown` family weights; other existing situation keys filter/weight for supported story and footprint conditions. Apartment/civic roles should not enter a detached-house lottery. Evanston's court and downtown treatments remain role-specific extensions pending the generator gate in §2.

For all four suburbs: retain detached garage footprints when supplied. Use rear/alley or side-drive access evidence to orient a door, otherwise omit invented access detail. Low front hedges 0.6–1.1 m, simple low wood/metal fences 0.7–1.0 m, and rear privacy fences 1.5–1.8 m are review assets; create boundaries only on mapped/evidenced boundaries. Tudor may use a short masonry entry wall, Colonial a short symmetrical hedge, Prairie a low horizontal hedge/wall, Victorian a light porch/front fence, Shingle an informal hedge, mid-century/modern open lawn or a short screen. None is automatic per lot. Do not represent private residents, house numbers, real signs or identifying ornament.

## 4. Roofs: identity before ornament

All construction and triangle targets below are [J]. **[R: LOCAL-V2]** The total main-pass ceiling is 400,000 triangles, shadow ceiling 150,000, and approximately 100 main draws. The existing 35,000-triangle richness allowance is **inside** that main ceiling; it is not an additional roof allowance.

1. Use mapped roof shape, direction, pitch/height and building parts first. Choose one stable primary ridge from a street-facing/footprint solution only where tags are absent. `OSMRef.random(salt)` selects variation; the same feature gets the same result in every renderer and weather state.
2. Simple rectangle: gable = two broad roof planes; hip = four. Keep a thin eave rim only in near view. A roof's ridgeline and overhang silhouette matter more than roof surface subdivision.
3. Cross-gable: main roof plus one subordinate wing aligned with a supported footprint arm. For a complex mapped footprint, allow at most three roof masses near camera. Compute valleys/joins on CPU, eliminate interior faces and seal intersections. A single giant gable over an L-shaped empty corner is not an acceptable shortcut. If decomposition is uncertain, a conservative sealed envelope is preferable to a self-intersecting “historic” roof; flag the fallback for review.
4. Dormers: zero to two per visible near roof, 0.9–1.5 m front width, subordinate ridge below main ridge. Keep dormer face/opening and little roof together as a mesh. Omit tiny or fully occluded dormers. Never scatter them randomly across every roof.
5. Turrets: rare, tied to a mapped/supported bay mass; eight-sided body and conical/hip cap are sufficient. No new tower footprint without evidence. Preserve its silhouette in mid LOD, collapse to the host envelope only once projected size is small. For phase 5B, omit unsupported turret assets rather than imitate them with a stray cylinder.
6. Chimneys: one cuboid plus cap, selected once; second only if supported or the reviewed family permits it. Avoid tall disconnected stacks, indoor point lights and smoke effects. An artistic chimney likelihood is not evidence of a fireplace or combustion.
7. Slate: cool charcoal broad planes; shingles: warm gray broad planes; tile: clay-colored plane with a few rounded **eave-edge** rolls near camera. No per-tile/per-shingle mesh field, normal-map grain, brick courses or roof image textures. Material identity comes from color, eave profile and roof mass.

| Roof addition | Proposed incremental triangle cap per near building | Simplification |
|---|---:|---|
| One secondary gable/hip assembly | 48 | Mid keeps the main secondary silhouette; no interior valley faces |
| Two dormers together | 64 | Mid one simplified merged detail or omitted below 3 px |
| Chimney plus cap | 24 | Mid simple cuboid; no cap beyond 50 m |
| Supported turret cap/bay refinement | 64 | Mid octagonal silhouette; far merged envelope |
| **Combined optional roof detail** | **200 maximum** | Selection skips lower-priority pieces to fit this total |

Cap visible optional roof detail at **12,000 triangles**, within the base-world allocation, not on top of 400,000 and not charged again to the full richness allowance. Distance rules: 0–50 m retain the selected near grammar; 50–150 m retain distinctive ridge/chimney mass only; 150–600 m use body and simple roof; beyond 600 m use skyline mass. Also cull by projected size and occlusion, especially aerially. CPU bake produces meshes/instances; no per-frame CSG, procedural remeshing or roof physics. Shadow LOD omits tiny dormer caps and porch rails first.

## 5. Chicago: five zones, not one city-wide house lottery

**[R: CHI-FLATS, CHI-MIDDLE, CHI-GREY, CHI-COURT]** Flat counts concern dwelling arrangements; a greystone describes a facade/material tradition, and courtyard describes a building form. They overlap. Do not infer apartment counts from stories or facade styling. The zone grammars below are [J] practical priors informed by those categories. Dimensions are review envelopes, not surveyed averages.

### 5.1 Dense north side — Lakeview, Lincoln Park, Rogers Park / Edgewater

Use continuous close-set street enclosure: three-flats and six-flats 2–4 stories; greystone and Victorian rowhouse masses 2–4; court buildings 2–4 around **mapped** open courts; corner mixed-use 2–4; supported vintage high-rises roughly 8–30 for a test vocabulary, with real tags taking precedence. High-rises require tagged height/levels and appropriate location; being in Edgewater does not authorize random towers inland.

Typical review lot pattern is 7.6–10 m frontage × 30–40 m depth, often aggregated for apartments, with 0–4 m front setback and narrow side gaps. Proposed building-width/gap rhythm is 6–9 m / 0.9–2 m where mapped geometry permits. Keep street-facing bays, stoops, a quiet parapet/cornice and repeated window bays. Distinguish paired-entry six-flat fronts from narrow vertical three-flat rhythms without encoding occupancy. Preserve rowhouse party-wall continuity where buildings actually touch. Courtyards need an open mouth, setback entrance and two wings; a filled rectangle loses the identity.

Backs matter: mapped alleys, garage fronts, gangways and simple two- or three-level wooden rear porch/stair silhouettes. Frontage foliage should frame openings without filling every gangway. Mixed-use corners have a larger ground-floor opening and a plain sign panel, never real brands or logos. Lakefront vintage towers are later; phase 5B stays on an inland low-rise block near Sheil Park.

### 5.2 Greystone / two-flat neighborhoods — Logan Square, Wicker Park, Lincoln Square

**[R: CHI-BOULEVARD]** Logan Square's landscaped boulevard system is a distinct spatial feature. [J] Keep separate divided carriageways, medians and park geometry when mapped; do not widen every Chicago street to become a boulevard.

Two-flat and greystone masses are generally 2–3 stories in this grammar, frame worker cottages 1–2, with larger court/mixed-use forms only where supported. A narrow 7.6–10 m frontage rhythm and 30–40 m lot depth make rear access and side gaps legible. Front setbacks 2–5 m allow stoops/small gardens; commercial strips often meet the sidewalk. Two-story storefronts retain one strong ground-floor band and a quieter upper story. A frame cottage uses a modest 25–40° front gable; masonry stacked forms use a low concealed roof/parapet or supported gable. Facade cornice, raised entrance, bay projection and gangway do more work than decorative stone carving.

Logan Square receives boulevard tree groups only on mapped greenspace. Wicker Park receives a tighter mixed masonry/cottage rhythm; Lincoln Square a similarly mixed low-rise rhythm with park/open-space interruptions. These are selection accents, not claims that each named neighborhood is homogeneous. One shared base profile is appropriate until block audits justify a distinct calibrated profile.

### 5.3 Bungalow belt — Portage Park and selected South Side areas

**[R: CHI-BUNG, CHI-BELT]** The classic Chicago bungalow has a compact brick body, a low hip roof, a raised entrance/basement and an attic roof volume; the cited architectural reference describes the familiar 25 × 125 ft lot context. This equals 7.62 × 38.10 m by unit conversion, not a measurement of every parcel. Bungalow districts occur on both north and south sides.

[J] Preserve 1 wall story plus roof attic, approximately 18–30° hip, broad front window group, offset entrance and basement base. One dormer may be supported; do not convert the attic into a full second wall story. Proposed front setback 4–7 m, narrow side paths, rear detached garage only on mapped footprint, plain brick/stone entry steps. Raised ranch: 1 story over a raised base, 10–22° low hip/gable, broad frontage where geometry supports it, very little ornament. Priors: bungalow 65%, raised ranch 25%, cottage 8%, stacked brick 2% for unknown eligible houses. These weights are judgment, not a city housing inventory. South bungalow windows do not overwrite the distinct South Side profile.

### 5.4 South Side — Hyde Park / Kenwood and Bronzeville

**[R: SOUTH-GOTHIC, SOUTH-BRONZE]** University of Chicago sources establish a campus with Gothic and other architecture; the Black Metropolis district documents a different historic commercial/cultural context. Do not spread university Gothic over Bronzeville or represent the whole South Side as mansions.

[J] Use a mixed low-rise grammar: greystone/stacked masonry 2–4 stories; courtyard apartments 3–5; supported large historic houses 2–3 stories with steep roofs, wider garden setbacks and fewer repeated facade units; institutional buildings 3–6 with supported towers/parts. Kenwood house-review cells may use 12–25 × 35–55 m lots and 5–12 m setbacks; narrow stacked-house cells use the city's 7.6–10 × 30–40 m rhythm. Bronzeville commercial frontage uses sidewalk-facing 2–4-story masses, stoops and restrained stone/brick contrast. All lot envelopes are judgments.

Gothic institution identity is a few large vertical bays, steep 35–50° roof where supported, one arch-shaped entry and a buttress silhouette. No spires on ordinary houses, miniature tracery, or invented towers. Preserve genuine vacant/open lots and parks; never “complete” a historic street wall by adding missing buildings. Canopy placement should follow known planting space, not assumptions about neighborhood wealth or demographics.

### 5.5 Downtown — Loop, River North, Streeterville; build later

**[R: CHI-SCHOOL, CHI-DECO, CHI-BRIDGE, CTA]** Chicago School, Art Deco and later glass towers are distinct useful massing families; movable river bridges and elevated rail are significant infrastructure. [J] Building height, river banks, bridges and rail alignments must come from actual geometry. The aerial concept is a compositional reference, **not a registered map or an accurate landmark arrangement**.

| Family | Review envelope, overridden by mapped height | Stylized identity / LOD |
|---|---|---|
| Chicago School | 5–22 stories; 3.2–4.1 m/floor fallback | Solid base, repeated broad bays, quiet cornice; near shallow window recesses, mid color bands, far silhouette |
| Art Deco | 8–65 stories; 3.2–4.1 m/floor fallback | At most three main stepped masses and one crown; vertical bands merged by distance; no carved relief |
| Modern glass | 5–120 stories eligibility; 3.0–4.0 m/floor fallback | Simple slab/tower plus supported podium; matte blue-gray glass planes, restrained mullion rhythm; no mirror city/reflection pass |
| Low-rise / warehouse / mixed use | 1–6 supported stories | Keep lower neighbors and street edges; no automatic tower substitution on small footprints |

These broad eligible ranges do not authorize random heights. First floor-list entries are safe fallbacks, not skyline statistics. A future role resolver must choose the tower family from supported evidence or explicit review metadata; current `.block` behavior will not do it simply because these type IDs exist.

Downtown lots may be aggregated into 20–60 m or larger mapped masses, with near-zero street setback, podium/tower offsets and plazas kept from source geometry. Preserve separate street elevations/viaducts, the actual river's open space and bridge spans. A river is not an ornamental canal network. Bridge meshes follow real endpoints and deck heights: simple deck, two side trusses where supported, pier/abutment masses; closed bascule geometry by default, no animation/traffic simulation in this proposal. L tracks follow rail `layer`, bridge and alignment evidence; a deck band, repeated support bents and sparse cross-bracing suffice. Do not build a rail line through buildings, across a river without a bridge, or on every elevated road.

Proposed **alternative downtown scene allocation**, all within the existing ceiling: buildings/roofs 170k, streets/river/terrain 70k, trees 45k, bridges/L 45k, existing near richness 35k = **365k main triangles**, leaving 35k geometric headroom. These are caps, not counts measured from a real Chicago package. Budget 150k shadows and 100 main draws across the whole view; repeated windows must not become separate draws. Screen-size-based LOD must preserve major crowns and setbacks, and collapse small windows to vertex/face color. Infrastructure 45k is taken from the base scene allocation; it is not an extra bucket. Stop admission or reduce far detail before exceeding caps; preserve geometry/topology before ornament. Physical-device profiling, streaming and tall-building occlusion remain adoption gates.

### 5.6 City-wide details

Alleys are independent mapped access corridors, not extra roads squeezed behind each block. Proposed widths 3.5–6 m are fallback review values only; keep actual surfaces, widths and gates when known. Rear garage doors and porch stairs face supported access. Gangways stay open negative space; do not bridge them with hedges. Wooden porch assemblies use two/three horizontal decks, posts, one stair run per level and simplified rail bands; no individual baluster field. Preserve stair clearance and real footprint boundaries. Viaducts require vertical separation metadata, never a shadow painted onto a flat crossing. Street lights use a small shared pole/head set; decorative fixtures require evidence. Corner taverns/storefronts use anonymous colored panels, awnings and larger windows, with no invented licensed brands or legible business names. All proposed sizes and fallback choices in this paragraph are [J].

## 6. Palettes and material treatment

**[R: LOCAL-V2]** The visual target is smooth stylized organic forms, deliberate geometry and a restrained palette without image textures. [J] These are sRGB authoring swatches; convert to linear light before weather/time blending. Real supplied material/color tags win. Keep a material enum for future response, not a hidden inference from a hex string. No masonry/tile bitmap, scanned bark, grass noise texture or realistic tiny foliage.

| Area/zone | Wall emphasis | Trim / door accents | Roof emphasis |
|---|---|---|---|
| Evanston | Brick `#A97C68`, warm stone `#C5BEAB`, muted siding `#97A39B` | Cream `#DED6C2`, teal-gray `#52676A` | Charcoal `#59636B`, warm gray `#646363` |
| Wilmette | Brick `#AD9274`, cream stucco `#D2C4AA`, olive-gray siding | Warm ivory `#E6DDC8`, brown `#725F4E` | Quiet gray slate/shingle planes |
| Winnetka / Kenilworth | Same restrained family, more stone/stucco panel opportunities | Cream, dark muted wood; no pure-black trim on every house | Cool slate and warm gray; preserve steep/low silhouette differences |
| Dense north | Brick `#A97C68`, limestone `#C5BEAB`; occasional subdued siding | Stone lintel/entry bands, muted blue-green doors | Flat parapet gray `#5B636A`; supported dark pitched roofs |
| Greystone / two-flat | Limestone `#C5BEAB`, red/tan brick, olive siding for cottages | `#E3DDCD`, `#596D6C` | `#5B636A` / `#616B71` |
| Bungalow belt | Warm brick and tan stone accents | Cream window surround, restrained brown/teal door | Broad warm-gray hip plane, dark eave |
| South historic | Brick/limestone; institution stone `#B9B29F` | Stone `#D9D2BD`, dark muted doors | Charcoal `#5D676B`, supported steep roof accents |
| Downtown | Stone `#C6BDAA`, Deco `#C9C3B0`, glass `#879CA5` | Light mullions `#B8C3C4`, subdued entries | Gray-blue crowns `#69777F` |
| Coral Gables | Stucco `#D9CBB1` / `#D3BEAB` | Ivory `#EEE5D3`, muted green `#657D72` | Clay `#AD7F61` / `#9E7966` |
| Miami Shores | Cream stucco plus quiet modern `#CECBBF` | Ivory, blue-gray `#647C84` | Clay hip/gable or flat parapet gray |

Profile tuples are the concrete current-schema subset. The table includes later material-panel options; it is not a promise of separate stucco/stone panels on every current house. Stable per-building tuple selection should vary across a street without creating random saturated stripes. Weather changes light and wetness, not the chosen architectural palette.

## 7. Vegetation and seasons

**[R: EV-TREES, CG-TREES, FALL, SPRING]** Regional sources support varied oak/maple/elm/linden canopy vocabulary, spring flowering trees and species-dependent fall timing. Morton Arboretum describes substantial autumn variation across weather, species and years. Its reports are not a guarantee of peak color on the dates selected here. All mixes, timing envelopes and densities below are [J].

Proposed Chicagoland fallback species mix: oak 18%, maple 22%, elm 14%, linden 12%, honey locust 18%, other broadleaf 12%, conifer 4%. This is a **design mixture, not a municipal tree inventory**. Add hackberry, Kentucky coffeetree, hickory, ornamental serviceberry, crabapple and redbud within suitable “other” and flowering subsets after local evidence review. Species tags win. Oaks read as spreading crowns, maples as broad rounded masses, elm as a higher vase/spread, linden as an oval, honey locust as a lighter open crown. Use smooth blended forms, not faceted cones or thousands of leaves. Existing crown weights approximate silhouette only; they do not identify a species.

Suburban trees use reviewed 10–20 m mature height ranges and more eligible garden canopy. City fallback trees use 8–15 m ranges and fewer inferred candidates. Proposed spacing is 18 m in suburban eligible planting strips, 17 m in city strips, 22 m downtown; those spacings are conditional on eligible space and include mapped trees. Overall city density is lower because there are fewer planting/garden cells: roughly 0.65 yard-tree candidates per eligible city residential cell versus 1.4 in suburbs, and 0.35 downtown. Do not mistake spacing for a claim that every city road has more trees. Count mapped equivalents first; no tree may overlap a building, drive, crossing, gangway or rail clearance.

Hedges are smooth connected low masses, not miniature trees at every property edge. Lawns follow mapped or approved inferred green space; do not replace an unmapped asphalt courtyard with grass. No scattered trees in a park's open sports field. All inference is marked `origin=inferred`, tied to parent OSM reference, rule/version and stable seed, and cannot be used for navigation or parcel boundaries.

| Phenophase | Chicagoland fallback envelope [J] | Rendering behavior |
|---|---|---|
| Bare winter | December–March, with weather-driven transitions | Most deciduous crown mass absent; fine twig noise omitted; evergreens retained; tan/olive grass, snow only from supported state |
| Spring bloom | Mid-April–mid-May, species-specific | Sparse serviceberry/redbud/crabapple bloom colors; bloom may precede full leaf-out; no all-tree pink phase |
| Green-up / leaf-out | Late April–late May | Gradual crown opacity/geometry variant and spring palette blend, cool-season grass greens earlier where temperatures permit |
| Summer | June–August into early September | Full crown volume, muted deeper greens; drought can dull grass without forcing autumn foliage |
| Early autumn | Late September–mid-October | Some maples/early-changing trees color before late oak groups; retain many green trees |
| Broad peak-color review | Mid–late October | Maples red/orange, linden/locust/elm primarily yellow/ochre, oak later russet; mixtures rather than one orange switch |
| Leaf drop | Late October–November | Color and retention separated; some trees bare while others remain colored; optional sparse retained oak leaves |

The color order above is a review rule, not a reliable species diagnosis or dated phenology forecast. Use the sky/seasons proposal's climate/date/chilling/temperature support where available; never invent recent temperature history. Missing species/climate/history falls back with explicit quality. Add deterministic per-tree onset offsets, suggested ±7 days, and independent modest retention offsets from semantic salts. Express continuous spring/summer/autumn/winter palette weights that sum to one, separate leaf retention and flowering; interpolate colors in linear light. Month arrays in today's profiles are compatibility defaults only. They cannot deliver this behavior without the planned seasonal resolver. Irrigated versus unirrigated lawn requires data or remains unknown.

**Miami gate:** today's `deciduousShare` is documented as deciduous versus conifer. The Miami profiles' 0.98 is only a **broad-crown silhouette placeholder**; it is ecologically wrong if treated as 98% deciduous. Do not activate Miami seasonal behavior on that basis. Future leaf-habit metadata uses roughly 90% evergreen/semi-evergreen broadleaf, 8% deciduous and 2% conifer as a judgment before a separately declared palm share. Palm is a form/leaf-habit category, not a conifer. Evergreen trees may shed/renew leaves without a synchronized bare northern winter.

## 8. Street character and geography

**[R: WIL-STREET, WIL-BRICK, EV-ALLEYS]** Wilmette documents brick streets and green street-lantern character, including brick under asphalt; Evanston maintains unpaved alleys as part of a varied alley network. [J] Default unknown road surfaces to the ordinary regional road material, never regional brick everywhere. Brick appearance can be a warm color family and extremely restrained existing surface-seam treatment, without individual bricks. Use mapped sidewalk runs, widths and crossings first. A missing sidewalk tag is not proof of no sidewalk, nor permission to draw one through buildings.

Suburban review streets: road 8–10 m, sidewalks 1.5–2 m, planting strips 1.5–3.5 m where data is absent and an inference is explicitly approved. City review streets: road 9–14 m, planting strips 1–2.5 m; commercial sidewalks may differ. These dimensions are judgments, not replacements for mapped widths. Maintain true scale and connectivity. Alleys, boulevards, parkways, streetlights and tree planting all require location-aware data; the palette should not carry geography by itself.

## 9. Weather, snow and fixture contract

**[R: LAKE-EFFECT, LAKE-ENHANCED, FOG]** NWS examples support geographically uneven lake-effect snowfall and lake enhancement of larger storms. NWS explains fog formation when warm moist air crosses colder water. These mechanisms do not establish conditions at a specific street or hour. Gray winter light, summer storms and lake fog are useful test cases, not daily regional defaults. Do not synthesize snow because the place is Chicago, or fog because it is close to Lake Michigan.

Use the existing weather resolver unchanged for tint, fog and accumulated surfaces. **[R: LOCAL-WEATHER]** Full-intensity rain uses tint `#8F9FAA` at .22 linear weight, direct multiplier .18, fog start/end ×.40/.50; snow uses `#CDD6DF`/.20, direct .30, ×.35/.45; storm uses rain tint, direct .12, ×.35/.45; cloudy uses `#BEC8D0`/.15, direct .40, ×.85/.85. Street fog is 25/220 m before visibility caps. Intensity interpolates once from clear; cloud/direct use the minimum, not compounded multipliers. Aerial clear baseline is 900/2500 m. Geographic sun direction never changes to beautify a picture.

**[R: LOCAL-WEATHER]** Ground snow is independent of current flakes. For supplied snow-water-equivalent reservoir S, eligible coverage is `1−exp(−S/6)`, retaining patchy tan grass and exposure masks. No accumulated state without history/checkpoint/explicit override; null is unknown, not zero. Persistent wetness is not instantly set by a rain label. Particle caps remain 600 rain / 300 snow, with a shared 600 total including at most 12 airborne leaves; transparent coverage also needs its existing cap. No new lightning or splash pass.

### Plowed banks — explicit exception proposal, not inferred weather

The weather proposal explicitly forbids inferred banks/plowed routes. Keep that rule. Add a **future surface-management override** only when curb segments, clearance and an observation/approved authored test state are supplied. Default unknown management to **banks off**. A fixture may deliberately supply a synthetic override; its provenance remains judgment. Never infer that every city street is plowed or every alley is unplowed.

Proposed bank geometry: low smooth curb-following lumps 0.2–0.6 m high and 0.5–1.0 m wide, retaining mapped driveway/crosswalk/entrance gaps and visibility triangles. Cap at 3,000 near triangles carved out of the existing near-geometry allowance; skip banks before exceeding that budget. No bank blocks an accessible path or intersects parked geometry. This is a visual override, not mass-conserving snow transport. No lake ice, footprints or wheel tracks follow automatically. The alley concept shows patchy snow without an asserted plowing operation.

### Dated cases

All 21 cases in `fixtures.json` are **synthetic overrides [J]**, not observed or forecast weather. Dates are chosen to test the annual range; recent temperatures/climate series were not fetched. Sun direction and events are calculated from an arithmetic transcription of the inspected `SolarPosition.swift`; the current model is cross-checked during validation. Sunrise/set use a −0.833° center threshold on a flat horizon; seconds aid repeatability, not a seconds-level accuracy claim. Time zones and UTC offsets are explicit. The 6° descending crossing defines the two golden-hour camera cases.

The first ten fixtures bind the ten reference images; the remaining eleven cover spring bloom, green-up, unknown winter snow, melt, summer storm, lake fog, enhanced snow, explicit plowed banks, leaf drop and Miami dry/wet seasonal contrast. Ground W/S values are independent synthetic checkpoints at the fixture instant, not computed by multiplying the current rain/snow rate. Moon/star behavior is inherited from sky/seasons; this set makes no new night-image or lunar ephemeris claim.

| Fixture | Local time / zone offset | State | Sun elevation / azimuth | Seasonal state |
|---|---|---|---|---|
| 01-northshore-golden | 2026-09-15T18:23:26-05:00 | clear | 6.00° / 268.25° | summer |
| 02-northshore-rain | 2026-09-15T12:00:00-05:00 | rain | 49.42° / 162.16° | summer |
| 03-northshore-fall | 2026-10-22T15:00:00-05:00 | clear | 27.17° / 220.60° | peakFall |
| 04-northshore-snow | 2026-01-15T12:00:00-06:00 | snow | 26.90° / 179.90° | bareWinter |
| 05-chicago-three-flat | 2026-09-15T18:23:12-05:00 | clear | 6.00° / 268.27° | summer |
| 06-chicago-alley-snow | 2026-01-15T12:00:00-06:00 | snow | 27.04° / 179.97° | bareWinter |
| 07-chicago-boulevard-fall | 2026-10-22T15:00:00-05:00 | clear | 27.27° / 220.67° | peakFall |
| 08-downtown-aerial | 2026-10-22T12:00:00-05:00 | clear | 36.28° / 169.35° | peakFall |
| 09-coral-gables | 2026-02-15T16:00:00-05:00 | clear | 27.22° / 238.86° | evergreenDry |
| 10-miami-shores-storm | 2026-07-15T15:00:00-04:00 | thunderstorm | 68.23° / 263.14° | evergreenWet |
| 11-evanston-spring-bloom | 2026-04-25T10:00:00-05:00 | clear | 43.62° / 115.51° | bloom |
| 12-winnetka-leafout | 2026-05-10T10:00:00-05:00 | cloudy | 46.94° / 111.47° | leafout |
| 13-kenilworth-gray-winter | 2026-12-10T12:00:00-06:00 | cloudy | 24.85° / 184.11° | bareWinter |
| 14-portage-snowmelt | 2026-03-10T13:00:00-05:00 | clear | 44.15° / 179.57° | dormant |
| 15-hyde-kenwood-summer-storm | 2026-07-15T16:00:00-05:00 | thunderstorm | 46.58° / 256.55° | summer |
| 16-rogers-park-lake-fog | 2026-05-20T08:00:00-05:00 | fog | 26.57° / 86.25° | leafout |
| 17-edgewater-lake-enhancement | 2026-02-10T12:00:00-06:00 | snow | 33.83° / 178.57° | bareWinter |
| 18-bronzeville-plowed-banks | 2026-01-16T11:00:00-06:00 | cloudy | 25.81° / 164.34° | bareWinter |
| 19-south-bungalow-late-fall | 2026-11-10T11:00:00-06:00 | rain | 30.41° / 170.38° | leafdrop |
| 20-miami-shores-dry-season | 2026-03-15T10:00:00-04:00 | clear | 32.24° / 110.57° | evergreenDry |
| 21-coral-gables-wet-season | 2026-08-15T14:00:00-04:00 | rain | 75.63° / 215.89° | evergreenWet |

## 10. Miami, after the Chicagoland tests

**[R: CG-FORM, CG-DESIGN, MS-HISTORY]** Coral Gables explicitly identifies Mediterranean design as part of its architectural vocabulary; the cited design booklet is a draft reference, not a statement of current law. Miami Shores' history includes Italian-influenced development. The modern mixture, dimensions and weights below are judgments, not municipal surveys.

| Family | Geometry / site review prior [J] | Roof and details [J] |
|---|---|---|
| Mediterranean Revival | 1–2 stories; width/depth 1.0–1.6; cream/pale ochre stucco; one recessed entry | 15–25° hip or gable, clay tile hue, one arch-shaped opening, optional shallow loggia; simplified chimney on a small minority |
| Stucco ranch | 1 story; width/depth 1.4–2.2; low broad mass, large front window | 12–22° hip/gable, clay or muted roof color, modest eave, minimal ornament |
| Modern infill | 1–3 stories, restrained rectilinear volumes, large simple openings | Flat 0–4° concealed roof, parapet, one recessed entrance; avoid glass-box caricature |
| Low-rise condo | Supported 2–4 stories, larger mapped footprint, shared entry | Flat parapet or supported tile hip; broad stacked balcony band at near LOD only, no per-baluster mesh |

Coral Gables eligible detached-house unknown weights: Mediterranean 45%, stucco ranch 40%, modern 15%. Miami Shores: 25/60/15. `plainBlock` retains supported low-rise buildings; current profiles do not independently implement condos or balconies. Neither profile creates towers from unknown height.

Coral Gables review cells: 18–30 × 35–50 m lot envelope, 6–10 m front setback. Miami Shores: 15–25 × 30–45 m, 5–9 m setback. These are aesthetic review envelopes only. Side/attached/rear garages need mapped volume and supported driveway/access. Low stucco garden walls 0.5–0.9 m and smooth hedges 0.7–1.2 m are optional boundary-evidenced assets; privacy walls 1.5–1.8 m only with mapped/approved boundary evidence. No invented gated compounds. Sidewalk continuity must follow mapping/verified public corridors rather than the symmetrical concept composition.

Tile roofs are the main new roof asset: broad hip/gable geometry, one ridge roll, optional rounded eave edge segments only within 50 m. Do not build rows of individual barrels or apply tile textures. Cap optional tile-edge geometry at 64 triangles per near building within §4's combined 200 cap. Flat roofs retain a simple parapet, not visible rooftop clutter without data. Mediterranean arches can use 8–12 segments near camera, becoming a dark entry shape at mid LOD. No ornate historical replica requirement.

**[R: CG-TREES]** The Coral Gables guide includes broadleaf shade-tree vocabulary such as live oak, gumbo limbo and mahogany; palms alone are not enough to communicate the landscape. [J] Start with a mixed evergreen shade canopy, palms as intermittent vertical accents, and smooth hedges/planting masses. A proposed 15% palm share among eligible inferred tree-form candidates must be evaluated separately from the broadleaf/conifer mix, with the latter renormalized over non-palms. Treat transfer of this vocabulary to Miami Shores as a climate/design assumption until its public-tree inventory is reviewed. Palm fronds should be broad opaque folded ribbons, not transparent leaflet cards; a near palm target is ≤300 triangles, mid ≤100, far a simplified 24–48-triangle silhouette, sharing existing tree materials and shadows.

**[R: MIAMI-WET]** South Florida has a pronounced warm wet season, broadly mid-May to mid-October in the cited Miami-Dade context. [J] Maintain green evergreen structure in winter, with mild dry-season olive lawn variation rather than northern tan/bare winter. Rainfall/temperature/irrigation data should control grass response; dates alone never create a thunderstorm, flooding, hurricane or drought. Wet-season fixtures test gray rain light, limited wet sheen and subdued sun behind cloud. Dry-season fixtures test clear warm light and retained evergreen canopy. Use the same weather caps, no extra tropical effect pass. Snow remains unsupported unless real forcing/explicit test metadata supplies it; the Miami fixture set contains none.

## 11. Public test areas and likely mapping gaps

The public anchors in this table are researched where a source ID is shown; proposed review windows, street extents, sequencing and likely gaps are judgments. No Overpass inventory or parcel survey was performed for this proposal. “Likely missing” is an audit checklist, not a finding about current OSM completeness. Do not include contributor usernames, private residence addresses or identifying household information in test records.

| Order | Area to review from public space | What the first package should establish |
|---|---|---|
| **5B-1** | Wilmette public streets near Vattmann Park [WIL-PARK], away from lakefront; alternatively an inland Evanston public block/park edge | A 250–400 m block-scale package: mapped footprints, roof silhouette variation, parkway, continuous sidewalk and seasonal crown response |
| **5B-2** | Lakeview public streets around Sheil Community Center Park [CHI-PARK]; choose an accessible public sidewalk with dense low-rise frontage | Three-flat/greystone rhythm, stoops, actual gangways, rear alley/garage access and one supported court if data permits |
| Later suburb | Hubbard Woods Park public edges, Winnetka [WIN-PARK]; Townley Field public edges, Kenilworth [KEN-PARK] | Larger canopy/setback scale; avoid sports-field tree infill; no lakefront imagery |
| Later city | Logan boulevard public sidewalks/medians [CHI-BOULEVARD], Portage Park public edges, Hyde Park/Kenwood public streets, Bronzeville commercial streets | Distinguish boulevard, bungalow, institutional and historic-commercial contexts without private-residence portraits |
| Later downtown | Public riverwalk/street/bridge viewpoints in Loop / River North / Streeterville | Actual river/bridge/rail topology, supported heights, multi-level streets and aerial LOD; no arbitrary landmark placement |
| Later Miami | Coral Gables public streets and park edges; Miami Shores public civic/park edges | Confirm sidewalk/access mapping, tile/flat roof grammar and evergreen/palm behavior before larger areas |

Expected audit gaps: `building:levels`, true height, roof direction/shape/pitch/parts, material/color, dormers and chimneys, inner courtyard rings, building-use distinctions, garages versus sheds, rear porch/stair geometry, fences/hedges, precise tree position/species/leaf habit, streetlights, sidewalk widths and driveway crossings. Downtown additionally needs bridge deck heights, bascule components, viaduct levels, rail `layer`/bridge topology, podiums and roof setbacks. Miami additionally needs palms versus broadleaf evergreens, irrigation/grass context, tile versus flat roof evidence and driveway layouts. A missing tag remains unknown.

**[R: EV-GIS]** Evanston exposes planimetric GIS layers that may assist a later audit. No layer was imported here. Review licensing, date and alignment before using any external geometry. For initial implementation, use explicit package/test overrides and inspect all inferred additions visually. Do not “fix” holes in mapping with guessed private buildings, invented boundaries or synthetic streets.

## 12. New assets and rollout priorities

All priorities and size targets are [J]. Reuse Denver materials, tree infrastructure, simple gable/hip roofs and weather machinery where possible. “New” means a needed asset/grammar capability, not necessarily a new material or draw call. **P0** is essential for the selected test; **P1** follows after that test; **P2** is later scope. Evidence-dependent details can be omitted when unsupported.

| Area / capability | New asset or generator support beyond the Denver baseline | Priority / phase |
|---|---|---|
| North Shore | Cross-gable/hip assembly with sealed valleys; restrained steep Tudor and low Prairie silhouette; one chimney cap | **P0 / 5B suburb** |
| North Shore | One/two dormer module, subdued Colonial entry and broad Prairie eave | **P0 / 5B suburb**, with combined roof budget |
| North Shore | Supported Queen Anne bay/turret, Shingle compound roof, uncommon entry wall/lantern variants | P1 after suburb; no speculative turret footprint |
| Evanston | Courtyard inner-ring preservation and supported mid-rise role | P1; required before claiming courtyard fidelity, not necessary on a detached-only initial block |
| Dense north side | Stacked masonry facade rhythm, stoop, bay/cornice silhouette, six-flat/court role distinction | **P0 / 5B city**; use only supported forms in selected block |
| Dense north side | Two/three-level rear porch/stair kit; alley garage frontage and gangway clearance | **P0 / 5B city** where supported; no invented access corridors |
| Greystone / two-flat | Limestone facade band, frame-cottage pitched roof, anonymous storefront; boulevard tree/median placement | P1 after dense test; reuse city modules |
| Bungalow belt | Raised-base brick bungalow, low hip/attic dormer, raised-ranch variant | P1 after dense test |
| South historic | Large historic-house roof assembly, court variant; institution-only Gothic entry/buttress | P1 for reused houses/courts, P2 for institutional Gothic |
| Downtown | Chicago School / Deco / glass tower mass hierarchies, podiums/crowns, height-aware screen LOD | **P2 / later** |
| Downtown infrastructure | Bascule bridge static kit, mapped elevated rail bents/deck, viaduct level handling | **P2 / later**; do not require for 5B |
| Shared Chicagoland | Leaf-retention variants, deciduous bare crown, smooth hedge, flowering subset; provenance-aware sparse dressing | **P0 / 5B** for tested seasons; no new leaf particle allowance |
| City snow management | Evidence-gated low curb-bank mesh and clearance mask | P1, after weather support; not automatic 5B scope |
| Coral Gables | Tile eave/ridge silhouette, simple arch/loggia, evergreen spreading shade crown and palm | **P2 / Miami** |
| Miami Shores | Stucco ranch / flat infill / supported low-rise condo facade, shared palm and evergreen assets | **P2 / Miami** |

Do not expand renderer-specific APIs to encode Chicago. Bake these choices into shared geometry/material/instance data and resolved environmental scalars. Profiles remain place data; the renderer sees no municipality names in shader branches.

## 13. Cameras, concepts and review limits

All camera numbers are [J] reproducible **targets**. Coordinates in `fixtures.json` are approximate public-area astronomical references; local scene framing is an anonymous composite and is not georegistered to an individual property. Image generation does not expose a calibrated camera, so identical framing requests do not prove numeric camera fidelity. Use the fixture cameras for a later engine capture; compare composition, not generated pixels as a geometry oracle.

| Camera | Position / target in local meters | Heading / downward pitch | Vertical FOV / aspect |
|---|---|---|---|
| North Shore, all four states | eye `(0,1.65,0)`, target `(29.958886,0.079921,0)` | 90° / 3° | 50° / 16:9 |
| Three-flat street | same local pose, separate Lakeview reference | 90° / 3° | 50° / 16:9 |
| Alley snow | eye `(0,1.65,0)`, target `(0,0.079921,-29.958886)` | 0° / 3° | 50° / 16:9 |
| Logan boulevard | street pose, separate boulevard composition | 90° / 3° | 50° / 16:9 |
| Downtown aerial | eye `(0,900,630.186785)`, target `(0,0,0)` | 0° / 55° | 50° / 16:9 |
| Coral Gables / Miami Shores | street pose with each area's reference coordinate | 90° / 3° | 50° / 16:9 |

Axes are east +X, up +Y, north −Z; roll 0°, near 0.1 m, far 3,000 m. Runtime clearance and loaded-geometry coverage must be checked before accepting any pose. Do not use invented atmospheric fog to hide an unloaded shoreline. The four North Shore views share the same source composition; other scenes use that image as style reference only. The prompt log records generation/variant/cleanup lineage rather than claiming ten independent engine renders.

The generated images are **concept art**, with no characters and no targeted private residences. Material cleanup emphasizes smooth untextured forms. Remaining limitations: decorative leaf shapes may read oversized; some snow/road micro-detail and simplified stair/rail construction remain; city greenery is more regular/generous than production should assume. The downtown image contains schematic/invented landmark placement and river/bridge relationships. Do not copy that topology into a world package. Numeric light/fog/wetness, actual geography, triangle budgets and 60 fps are not certified by an image. The final fixture values take precedence over preliminary numerical prose in generation prompts.

All selected images retain the visible “© OpenStreetMap contributors” footer as the required world-view placement concept. It does **not** assert that the generated geography came from an OSM reconstruction. These synthetic images do not display WeatherKit observations; a later live view must use the weather proposal's actual provider-returned Apple Weather mark/legal-link metadata and keep OSM credit visible. Do not invent a generic Apple logo inside a generated scene.

### Image gallery

The images below are linked to local final files; manifests identify their fixture and camera.

**01-northshore-golden** — concept [J]; fixture `01-northshore-golden`.

![01-northshore-golden](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/01-northshore-golden.png)

**02-northshore-rain** — concept [J]; fixture `02-northshore-rain`.

![02-northshore-rain](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/02-northshore-rain.png)

**03-northshore-fall** — concept [J]; fixture `03-northshore-fall`.

![03-northshore-fall](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/03-northshore-fall.png)

**04-northshore-snow** — concept [J]; fixture `04-northshore-snow`.

![04-northshore-snow](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/04-northshore-snow.png)

**05-chicago-three-flat** — concept [J]; fixture `05-chicago-three-flat`.

![05-chicago-three-flat](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/05-chicago-three-flat.png)

**06-chicago-alley-snow** — concept [J]; fixture `06-chicago-alley-snow`.

![06-chicago-alley-snow](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/06-chicago-alley-snow.png)

**07-chicago-boulevard-fall** — concept [J]; fixture `07-chicago-boulevard-fall`.

![07-chicago-boulevard-fall](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/07-chicago-boulevard-fall.png)

**08-downtown-aerial** — concept [J]; fixture `08-downtown-aerial`.

![08-downtown-aerial](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/08-downtown-aerial.png)

**09-coral-gables** — concept [J]; fixture `09-coral-gables`.

![09-coral-gables](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/09-coral-gables.png)

**10-miami-shores-storm** — concept [J]; fixture `10-miami-shores-storm`.

![10-miami-shores-storm](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/10-miami-shores-storm.png)

## 14. Performance and acceptance

**[R: LOCAL-V2, LOCAL-WEATHER]** Target 60 fps and ≤10 ms GPU/frame on iPhone 13-class hardware, minimum iOS 26.0. The existing 7.90 ms content budget plus 2.10 ms margin is unchanged. [J] These remain targets; this proposal did not run a device benchmark or produce renderer meshes.

| Existing v2 allocation | This proposal's use, within that allocation |
|---|---|
| Base world 4.25 ms | Regional geometry, sky, fog term, instanced material groups; roof/bridge/L geometry displaces other base detail |
| Shadows 1.45 ms | Simplified roof/building/tree shadow LOD; no tiny rail/dormer-cap casters at distance |
| AO / fill .15 ms | Existing contact treatment, no new region-specific AO pass |
| Surface pattern .25 ms | Existing lawn/snow/seam treatment only; no individual masonry or tile texture work |
| Near geometry .35 ms | Existing bevel/leaves/tufts/caps, with any supported snow banks consuming part of the same allocation |
| Wetness .35 ms | Existing restrained darkening/roughness/streaks; no new planar reflection system |
| Particles .20 ms | Existing shared rain/snow/leaves caps and projected-coverage limits |
| Post .90 ms | Existing tone/color/bloom only |
| Reserved margin 2.10 ms | Not spendable architectural ornament budget |

Profile selection, stable variation, roof assembly and LOD generation happen on the CPU during bake/load; cache by source geometry plus profile/rule version. Phenology and sky keyframes update at the sky/weather proposal's cadence, not per-tree per-frame network or physics work. Runtime gets shared meshes/instances, material parameters and interpolated scalar environment values. Under pressure, drop distant ornament, particle density and near optional caps before lowering geographic fidelity. Instancing must group material/mesh/LOD, not create a separate material per window or house. Measure CPU time, memory/streaming and draw submission as well as triangles; a triangle limit alone cannot guarantee frame rate.

Phase 5B acceptance: both public packages retain real footprints, streets and access; exact date/location sun direction; deterministic roof/palette choices across renderer/camera/weather changes; no forced seasonal uniformity; no unsupported snow reservoir. Review clear, rain, fall and snow using the four-state suburban camera, then three-flat frontage and rear-access city views. Check close, mid and aerial transitions for roof popping, sealed valleys, court holes and vanishing gangways. Run the whole scene's v2 device checks before adding later zones. Miami cannot pass until evergreen and palm behavior survives a January/July comparison. Downtown cannot pass until river/bridge/L alignment and height data are audited.

## 15. Lake Michigan shoreline — later, no images

Use the actual shoreline and open-horizon water extent, with true beach/park/trail geometry and elevation. Beaches require mapped sand boundaries; do not widen them to fill a composition. Bluffs need terrain evidence; do not assume a continuous bluff along the full urban shore. Maintain the lakefront trail's real alignment, crossings and grade separation. Preserve long water sightlines with a proper loaded backdrop/horizon policy; never close the horizon with an invented opposite bank. Water color, fog and wave appearance follow supported weather. Shore ice, beach closures and navigation conditions are out of scope. This is a [J] later-work design note, not a survey of shoreline coverage.

## 16. Open questions and recommended decisions

1. **Adopt Wilmette → Lakeview as the phase 5B pair.** Owner scope is confirmed; the precise public block bounds still need a mapping audit and engine camera capture. Keep approximate review rectangles out of production activation until then.
2. **Keep the existing profile/catalog format.** Confirm whether production selection is already per feature across a mixed-zone package; if not, implement that behavior before broadening coverage. Preserve the documented first-match overlap rule.
3. **Prioritize roof mass and rear-access geometry.** Confirm the base-world triangle share available for 12k optional roof detail. Unsupported dormers/turrets should remain absent; no ornamental work should precede a correct courtyard hole or gangway.
4. **Approve richer role and leaf-habit support separately.** A decodable family ID is not a completed generator feature. Agree on explicit role evidence for courts/towers and evergreen/palm metadata before claiming Miami or downtown readiness.
5. **Keep weather evidence independent of regional identity.** Treat all supplied fixtures as overrides; approve any future snow-bank input contract explicitly and retain unknown/off behavior. Decide which local climate/tree inventory data can legally and reliably replace the initial judgment priors.

Further unresolved implementation choices: exact primitive/mesh representation across RealityKit and three.js; package streaming scale for tall skyline views; authoritative neighborhood boundaries if broad coverage is needed; permitted historic building-part sources; how to represent existing public stairs/porches without manufacturing private geometry; how to retain botanical diversity within a small shared asset set. No renderer choice or runtime implementation is made here.

## 17. Source register

Every entry below was reviewed **2026-10-05**. Local source verification establishes what the current file says, not that a proposal target has been measured. External citations support the narrowly stated vocabulary/phenomenon; numerical art tuning remains [J]. `sources.json` preserves scope and retrieval limitations, including the two search-index-only documents. No private-residence addresses from source inventories are reproduced.

- **DESIGN** — [This proposal and owner scope](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/WorldEngine-Regions-Chicagoland-Miami-Spec-v1.md). All chosen weights, dimensions, colors, dates, cameras, approximate bounds and performance allocations are review assumptions, not surveys. Phase 5B scope confirmed by owner.
- **LOCAL-SCHEMA** — [StyleProfile and RegionCatalog Codable v2](/Users/robwoodbury/Desktop/world-engine/Sources/WorldGen/StyleProfile.swift). Local source read; actual decoder contract, no standalone JSON Schema found.
- **LOCAL-GEN** — [BuildingGenerator](/Users/robwoodbury/Desktop/world-engine/Sources/WorldGen/BuildingGenerator.swift). Local source read; basic roof forms and block dispatch limitations.
- **LOCAL-SOLAR** — [SolarPosition](/Users/robwoodbury/Desktop/world-engine/Sources/WorldGeo/SolarPosition.swift). Local NOAA-style geometric solar model; source accuracy comment is not an independent measurement.
- **LOCAL-REGIONS** — [Regional profiles v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/regions-v1/WorldEngine-Regional-Profiles-v1.md). Existing profile conventions and proposed-additions envelope.
- **LOCAL-V2** — [Visual v2](/Users/robwoodbury/Desktop/world-engine/docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md). Style, camera conventions and performance ceilings.
- **LOCAL-WEATHER** — [Weather v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/weather-v1/WorldEngine-Weather-Spec-v1.md). Weather tint/fog/particles/accumulation rules; targets are proposal assumptions.
- **LOCAL-SKY** — [Sky and seasons v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/sky-seasons-v1/WorldEngine-Sky-Seasons-Spec-v1.md). Continuous phenology and sun/moon conventions.
- **LOCAL-EXPERIENCE** — [Experience v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/experience-v1/WorldEngine-Experience-Spec-v1.md). Character-free cameras and concept manifest conventions.
- **EV-ARCH** — [Evanston landmark inventory](https://www.cityofevanston.org/Documents/Departments/Community%20Development/Planning%20and%20Zoning/Historic%20Preservation/Evanston%20Landmarks/EvanstonLandmarksInventory_Complete.pdf?t=202601161453210). Examples establish vocabulary, not stock frequencies; private residence addresses excluded.
- **EV-TREES** — [Evanston tree preservation guidance](https://www.cityofevanston.org/Documents/Departments/Public%20Works/Services/Forestry%20and%20Tree%20Preservation/Tree%20Preservation%20Permits/PvtTreePres2026.pdf?t=202602091708540). Species vocabulary, not a sampled canopy mixture.
- **WIN-FORM** — [Winnetka residential design handbook in meeting packet](https://www.villageofwinnetka.org/AgendaCenter/ViewFile/Agenda/_01122021-239). Search-indexed handbook material; full-file retrieval unavailable in this review. No numerical stock claims.
- **WIL-FORM** — [Wilmette appearance review guide](https://www.wilmette.gov/DocumentCenter/View/1618). Village-center style examples, not residential census; residential transfer is judgment.
- **KEN-FORM** — [Kenilworth downtown historic survey](https://vok.org/DocumentCenter/View/6581). Business-district Tudor context only; residential mixture is judgment.
- **CHI-BUNG** — [Chicago Architecture Center: Chicago bungalow](https://www.architecture.org/online-resources/buildings-of-chicago/chicago-bungalow/). Bungalow form and classic narrow lot context.
- **CHI-FLATS** — [Workers Cottage Initiative: two-flats](https://workerscottage.org/twoflats.html). Two-flat as dwelling arrangement across styles; no occupancy inference from facade.
- **CHI-COURT** — [Edgewater Historical Society: courtyard buildings](https://www.edgewaterhistory.org/ehs/local/courtyard-buildings). Search-indexed courtyard description; full-page retrieval unavailable in this review.
- **CHI-GREY** — [CTA RPM historic resources survey](https://www.transitchicago.com/assets/1/6/RP_CWC_JP_RPM_PH1_RPB_Appendix_D_20150519_Part2.pdf). Greystone facade and neighborhood building vocabulary; omit private addresses.
- **CHI-MIDDLE** — [Chicago Architecture Center: missing middle infill](https://www.architecture.org/online-resources/missing-middle-infill-housing). Rowhouses, six-flats and courtyards as distinct forms.
- **CHI-BELT** — [Chicago Bungalow Association: historic districts](https://www.chicagobungalow.org/historic-districts). Multiple north and south bungalow districts; does not imply uniform South Side.
- **CHI-BOULEVARD** — [City of Chicago: Logan Square boulevards district](https://webapps1.chicago.gov/landmarksweb/web/districtdetails.htm?disId=146). Landscaped boulevard system and varied buildings.
- **SOUTH-GOTHIC** — [University of Chicago architecture](https://architecture.uchicago.edu/). Campus architecture; Gothic applies to supported institution parcels only.
- **SOUTH-BRONZE** — [City of Chicago: Black Metropolis district](https://webapps1.chicago.gov/landmarksweb/web/districtdetails.htm?disId=6). Cultural/commercial district context; not a uniform house style.
- **CHI-SCHOOL** — [Library of Congress: Reliance Building HABS](https://tile.loc.gov/storage-services/master/pnp/habshaer/il/il0000/il0041/data/il0041data.pdf). Chicago School reference vocabulary, not a landmark replica instruction.
- **CHI-DECO** — [Chicago Architecture Center: Board of Trade](https://www.architecture.org/online-resources/buildings-of-chicago/chicago-board-of-trade-building/). Art Deco massing reference; numerical envelope here is judgment.
- **CHI-BRIDGE** — [Chicago Architecture Center: movable bridges](https://www.architecture.org/online-resources/stories-of-chicago/chicagos-movable-bridges). Bascule bridge reference; alignment requires mapped geometry.
- **CTA** — [CTA Loop track renewal](https://www.transitchicago.com/chicago-transit-board-approves-contractor-for-the-loop-track-renewal-project/). Elevated Loop structure context; topology must come from rail data.
- **WIL-STREET** — [Wilmette community](https://www.wilmette.gov/31/Community). Brick streets and green lantern vocabulary.
- **WIL-BRICK** — [Wilmette brick street policy](https://www.wilmette.gov/DocumentCenter/View/207/Brick-Street-Policy-PDF). Some brick is under asphalt; do not color all roads brick.
- **EV-ALLEYS** — [Evanston alley maintenance](https://www.cityofevanston.org/departments/public_works/services/alley_maintenance.php). Unpaved alley maintenance confirms alley surface diversity.
- **EV-GIS** — [Evanston planimetric GIS service](https://maps.cityofevanston.org/arcgis/rest/services/OpenData/ArcGISOpenData3Planimetric/MapServer). Possible audit source, not imported; license and alignment review still needed.
- **EV-DOWNTOWN** — [Evanston downtown plan](https://www.cityofevanston.org/departments/community_development/planning_zoning/area_planning/downtown_plan.php). Downtown is a distinct planning context.
- **WIL-PARK** — [Wilmette Park District public facilities](https://wilmettepark.org/freedom-of-information-act/). Vattmann Park public test anchor; coordinates here approximate.
- **WIN-PARK** — [Hubbard Woods Park](https://www.winpark.org/beach_park/hubbard-woods-park/). Public park anchor.
- **KEN-PARK** — [Townley Field](https://kenilworthparkdistrict.org/parks/townley-field/). Public park anchor.
- **CHI-PARK** — [Sheil Community Center Park](https://www.chicagoparkdistrict.com/parks-facilities/sheil-bernard-community-center-park?page=0). Public Lakeview anchor for phase 5B dense-city review.
- **FALL** — [Morton Arboretum: when leaves change](https://mortonarb.org/blog/when-do-leaves-change-color-in-fall/). Broad late-September/October variability and species differences; no fixed peak-date guarantee.
- **SPRING** — [Morton Arboretum spring bloom report](https://mortonarb.org/explore/activities/explore-grounds/spring-bloom-report/). Spring bloom phenophases; selected fixture dates are judgment, not reported 2026 observations.
- **LAKE-EFFECT** — [NWS Chicago November 9–10 2025 lake-effect event](https://www.weather.gov/lot/2025_11_10_LakeEffectSnow). Spatially variable lake-effect event, not fixture hourly forcing.
- **LAKE-ENHANCED** — [NWS Chicago February 9 2010 snow](https://www.weather.gov/lot/2010feb09). Lake enhancement of a broader storm.
- **FOG** — [NWS fog over water](https://www.weather.gov/safety/fog-water). Warm moist air over colder water can form fog and move inland.
- **MIAMI-WET** — [Miami-Dade local mitigation strategy: flooding](https://www.miamidade.gov/fire/library/OEM/local-mitigation-strategy-part-7-flooding-nfip-and-crs.pdf). South Florida wet-season context; selected storm dates/intensities are synthetic.
- **CG-FORM** — [Coral Gables Mediterranean design](https://www.coralgables.com/department/development-services/board-architects/mediterranean-design). Municipal Mediterranean design context, not a universal style claim.
- **CG-DESIGN** — [Coral Gables design best practices draft](https://www.coralgables.com/sites/default/files/2023-10/Design-Best-Practices-2021sm-EK.pdf). October 2021 draft design reference; not asserted current building law.
- **MS-HISTORY** — [Miami Shores story](https://www.msvfl.gov/departments/community/TheMiamiShoresStory). Historic Italian-influenced development context; present ranch share is judgment.
- **CG-TREES** — [Coral Gables tree guide](https://www.coralgables.com/sites/default/files/2022-05/TreeGuide.pdf). Suitable broadleaf species and palms; not local abundance measurements.
