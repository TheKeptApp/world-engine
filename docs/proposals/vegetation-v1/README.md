# WorldEngine vegetation reference — Style B
**6 October 2026 · Proposal only · Rich stylized / renderer-neutral**

Simplified organic shapes, real light and colour, no photo textures. The [look-fix midday image](../look-fix-v1/images/lighting-03-ordinary-1530.png) anchors the appearance; [visual v2](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) supplies the world and performance constraints. This pack changes no engine code or regional production profiles.

## Reference sheets
| File | What to inspect |
|---|---|
| [01 North Shore / Chicago](images/01-north-shore-chicago.png) | Oak, maple, elm, linden, honey locust, spruce × spring, summer, peak fall, winter; street studies with aerial insets |
| [02 Denver](images/02-denver.png) | Cottonwood, ash, blue spruce, aspen, crabapple × four seasons; street studies with aerial insets |
| [03 Miami](images/03-miami.png) | Royal palm, live oak, sea grape, banyan × four seasonal comparison columns; evergreen winter |
| [04 Crown construction](images/04-crown-construction.png) | Too crude vs target; sky holes, visible forks, ground contact; front/top adaptations and light |
| [05 Shrubs, hedges and beds](images/05-shrubs-hedges-beds.png) | Foundation, hedge, bed and aerial studies for all three regions, plus winter strip |
| [06 Phone distance and aerial](images/06-phone-distance-aerial.png) | Conceptual 5 / 20 / 40 m street views and dedicated aerial view |
| [07 Chicago exact swatches](images/07-chicago-colour-swatches.svg) | Every tree and shrub season under both lighting rigs |
| [08 Denver exact swatches](images/08-denver-colour-swatches.svg) | Every tree and shrub season under both lighting rigs |
| [09 Miami exact swatches](images/09-miami-colour-swatches.svg) | Every tree and shrub season under both lighting rigs |
| [Colour JSON](vegetation-colours.json) | 60 tree-season and 28 shrub-season records, including body/highlight/shadow hex values for both lights; branch and overlay palettes |
| [Prompt set](image-prompts.json) | Built-in image-generation prompts, source paths, one shrub simplification edit, provenance |

Images are generated art-direction references, not screenshots, mesh specifications or measured phone tests. Tree cells normalize composition for comparison; do not infer relative mature size from sheet cell height. The distance board communicates framing and detail loss, not calibrated projection. Botanical identity comes from silhouette and branching before small decorative detail.

**Authority:** numeric construction rules and exact JSON/SVG colours override incidental details in raster images. Raster swatch dots are illustrative only. Fine leaf scalloping, bark grooves, tiny grass and mottling in some generated studies are not requirements to reproduce. Use the major masses, light planes and negative spaces. The shrub edit deliberately reduces such texture; its large leaf-like lobes remain an abstraction, not leaf-scale geometry.

## Evidence and assumptions
All hex values, size bands, counts, density, triangle limits, planting compositions, lighting rigs and seasonal blend suggestions in this pack are **authored design assumptions** for visual prototyping. They are not sampled colour measurements, inventories, planting recommendations or performance measurements. The references below support the explicitly identified botanical constraints only; the user supplied the regional family lists.

**Verified botanical constraints, sources checked 6 October 2026:**

- Honey locust has fine/lacy foliage, light dappled shade and yellow autumn colour: [Morton Arboretum, thornless honey locust](https://mortonarb.org/plant-and-protect/trees-and-plants/thornless-honey-locust/). This supports an open crown rather than individually modeled leaflets.
- Aspen autumn timing depends on local conditions: [Colorado State Forest Service, aspen fall colours](https://csfs.colostate.edu/forests-trees/aspen-fall-colors/). A four-season sheet is a set of appearance keys, not a fixed calendar.
- Ash autumn colour varies with selected tree/cultivar: [Colorado State University, fall and winter interest](https://planttalk.colostate.edu/topics/trees-shrubs-vines/1705-fall-winter-interest/). The gold ash in this pack is a green-ash visual exemplar, not a rule for every ash.
- Royal palm has a crownshaft and evergreen foliage: [UF/IFAS, royal palm](https://ask.ifas.ufl.edu/publication/ST574), [UF/IFAS, palm leaf structure](https://gardeningsolutions.ifas.ufl.edu/plants/trees-and-shrubs/palms-and-cycads/palm-leaf-structure/). The proposed 10–14 ribbons are rendering clusters, not a botanical frond census.
- Live oak retains a leafy appearance while replacing old leaves around spring and has broad horizontal branching: [UF/IFAS, live oak plant guide](https://irrecenvhort.ifas.ufl.edu/gardentool/plants/Quercus%20virginiana/), [UF/IFAS, live oaks](https://gardeningsolutions.ifas.ufl.edu/plants/trees-and-shrubs/trees/live-oaks/).
- Sea grape is evergreen, often multistemmed, with bronze new foliage and some leaves reddening before shedding: [UF/IFAS, sea grape](https://ask.ifas.ufl.edu/publication/ST175). The sheet represents scattered turnover, not a northern mass autumn change.
- Banyan is a large evergreen with a fluted trunk and aerial roots: [UF/IFAS plant directory](https://plant-directory.ifas.ufl.edu/plant-directory/ficus-benghalensis/). Use this as a distinctive mapped/observed landmark form, not a default small yard tree.
- Regional tree and shrub reference background: [Morton Northern Illinois species list](https://mortonarb.org/app/uploads/2022/09/Northern-Illinois-Tree-Species-List_092022-1.pdf), [CSU trees and shrubs for mountain areas](https://extension.colostate.edu/resource/trees-and-shrubs-for-mountain-areas/), [UF/IFAS low-maintenance South Florida landscape plants](https://edis.ifas.ufl.edu/publication/EP107/pdf). These are context, not evidence that a particular lot contains an illustrated planting.

## Crown construction: near street and aerial
Start with the branch skeleton and outer envelope. Place unequal, intersecting masses around branch endpoints. Merge the reading of adjacent masses; avoid separate balls perched on poles, stacked spheres, uniform scallops, leaf noise, and a single flat green blob.

The following are **proposed near-view design parameters**. Counts refer to primary mass groups; broad smooth surface variation does not add leaf geometry. Sky-hole fraction is approximate visible background area inside the projected crown envelope, measured in a representative three-quarter summer view, excluding space outside the silhouette. It is a design target, not a literal transparency setting.

| Family | Silhouette and construction | Primary groups | Sky holes | Visible structure |
|---|---|---:|---:|---|
| Oak | Unequal spreading shoulders; one dominant off-centre upper mass | 7–10 lobes | 10% | Thick fork and 2–3 reaching branches |
| Maple | Upright rounded crown; uneven height, concave waist | 6–9 lobes | 6% | Main fork and short lower branch glimpses |
| Elm | High open vase; arched branches form the silhouette | 7–11 lobes | 18% | At least 3 arching structural limbs |
| Linden | Tapered oval with broader lower shoulders | 5–8 lobes | 5% | Trunk and low fork; mostly enclosed interior |
| Honey locust | Airy irregular umbrella; gaps distributed across canopy | 8–12 small lobes | 25% | Fine-looking but simplified branching |
| Spruce | Irregular taper with drooping staggered tiers | 7–10 tiers | 6% | Trunk glimpses between lower tiers |
| Cottonwood | High spreading crown, thick irregular scaffold | 7–10 lobes | 16% | Tall stout trunk and heavy forks |
| Ash | Upright oval, moderate internal openings | 6–9 lobes | 13% | Repeated ascending forks, unequal spacing |
| Blue spruce | Narrow blue-grey cone; broken tier lengths | 7–10 tiers | 6% | Dark trunk recessed behind boughs |
| Aspen | Airy upright oval over slim pale trunk | 5–8 lobes | 20% | Pale trunk remains a strong identity cue |
| Crabapple | Small broad crown; low irregular branching | 5–7 lobes | 10% | Low fork, 2–3 visible limbs |
| Royal palm | Radial arching folded ribbons, several unequal droops | 10–14 ribbons | 38% | Light trunk, green crownshaft; no woody crown branches |
| Live oak | Broad, low horizontal limbs; canopy wider than tall | 8–12 lobes | 12% | Thick horizontal scaffold underneath |
| Sea grape | Multistem vase; coarse broad masses | 5–8 lobes | 8% | Several stout low stems |
| Banyan | Wide flattened umbrella with irregular edge | 9–14 lobes | 10% | Fluted trunk plus 3–5 selected prop-root structures |

Proposed urban asset size bands are in the JSON. They span chosen ordinary asset ages, not botanical maximums: mapped height/crown diameter and known maturity override them. In particular, large live oak and banyan landmarks can exceed these bands. Never shrink a tree to fit a street-view frame or move a mapped tree to improve composition.

**Light:** one coherent solar key illuminates upper/facing surfaces; the lower crown receives cooler sky/ambient fill. Broad light-to-shadow transitions express volume. Use gentle vertex ambient occlusion in intersections and under the crown, not dark outlines around every lobe. Ground contact should be a restrained 10–20% ambient reduction within approximately 0.15–0.4 m of the trunk base, adapted to trunk size; no black ring or floating trunk. A cast crown shadow is separate from contact darkening.

**Variation:** stable feature seed plus purpose-specific salt selects 3 skeletons × 2 envelope variants per family. Suggested within-family width ±20%, height ±15%, yaw, lean 0–7°, and mass asymmetry 8–18%; constrain lean/width against clearances. Colour variation stays small: hue ±5° and value ±6%, lobe-to-lobe value ≤3%. These are art-direction limits, not independent random draws every frame. Preserve identity across season, lighting and LOD changes.

**Bare branches:** keep the same skeleton as the leafy tree. Remove leaf masses; use 2–3 branching orders near the camera, simplifying twig density before sacrificing main forks. Do not substitute coral-like dense noise. Oak leaf retention is an optional species/age-specific extension; the sheet's bare red-oak exemplar is not a rule that every oak always sheds every leaf.

## Four seasons and weather
The seasonal keys are appearance endpoints, not equal three-month bins. Blend leaf coverage and pigments over local phenology; use weather/history if available, otherwise mark regional calendar timing inferred. Preserve feature identity throughout.

- North Shore/Chicago: fresh lighter spring foliage; full summer leaf masses; differentiated autumn russet oak, orange-red maple, yellow elm/linden/honey locust; bare winter broadleaves. Spruce stays green.
- Denver: cottonwood, green-ash exemplar and aspen use differentiated gold/yellow autumn; crabapple adds a small orange-gold family. Blue spruce remains blue-green. Aspen's white bark provides winter identity.
- Crabapple spring flowers are a short optional bloom phase, not the entire spring season. JSON includes a blossom accent; keep the underlying foliage colour independently available. Cultivar-specific fruit is optional, not universal.
- Miami: all four families retain green crowns across the seasonal comparison columns. Live oak spring turnover can slightly open the canopy; sea grape may show scattered bronze/red accents. Do not apply a northern “peak fall” orange transformation. The winter column intentionally has no snow.
- Northern winter is **bare or snow-covered depending on actual weather**. Snow is a separate exposure/accumulation overlay on upward-facing boughs and ground, not white foliage and not guaranteed all winter. Evergreen branches remain legible through patchy snow. Do not use the whole winter crown as an opaque snowball.

## Shrubs, hedges and beds
The regional planting compositions are **visual assumptions**, not inferred factual landscaping on a real parcel. Seven palette families in the JSON cover deciduous foundation shrubs, northern evergreen hedges, Denver juniper, Miami broadleaf hedge, coontie-like clumps and sea-grape shrubs.

- Foundation planting: 0.4–1.2 m ordinary height; groups of 3–5 unequal merged lobes per shrub. Keep windows, entries, path width and facade base legible. Larger specimens require actual clearance.
- Hedges: 0.8–1.8 m ordinary height; one continuous envelope with an irregular crest, broken into 1.5–3 m cullable sections. Adjacent shrubs overlap visually; never a string of identical balls. Mapped hedge line stays fixed.
- Beds: cluster 3–7 plants into 2–3 islands with approximately 25–40% visible ground. Use bounded solid-colour mulch or gravel, a few rocks, and broad tufts; no photographic gravel or individual grass-blade carpet.
- Chicago: deciduous flowering masses mixed with evergreen hummocks/hedges; bare winter twigs in the deciduous groups, evergreen structure maintained.
- Denver: more separated shrub/juniper groups and dry-bed gaps; 8–12 folded grass ribbons per near clump at most. Keep illustrative xeric styling an inference, not a claim about every Denver yard.
- Miami: broadleaf masses, coontie-like radial clumps and sea-grape forms; evergreen winter. Red ornamental accents are optional design accents, not a required botanical type or a reason to tint every plant red.
- At 20–40 m remove separate flowers, decorative leaves and grass ribbons first. At aerial scale retain bed boundary, broad colour grouping and asymmetrical planting spacing.

Do not move mapped vegetation. Add inferred planting only where the regional dressing policy permits, mark its provenance, preserve traversable surfaces and visibility at intersections, and do not place large roots or trunks inside buildings/paths.

## Exact colours and lighting
The three SVG charts are vector swatch diagrams, readable at any zoom. Each family has four season rows and six exact hex swatches: midday body/highlight/shadow and golden-hour body/highlight/shadow. Bare winter rows explicitly display **branch** colours; crown fields are null. The JSON also carries snow, blossom, bronze new growth, flower accents, dry grass, lawn, mulch and gravel under both lights.

The JSON is a **new reference schema proposal**, not a drop-in promise of compatibility with an existing renderer. Hex values use sRGB. Decode before interpolation; encode only for presentation. The JSON documents the exact authored linear-light palette transform so the charts are reproducible.

Use neutralCrownAlbedo for the season's authoring input. Golden-hour swatches are appearance targets, not replacement albedos: applying their warmth to the material and then applying warm sunlight would double-tint the tree. Shadow/highlight swatches are visual comparison references, not three required materials or painted textures. Both renderers should use their normal lighting pipelines and match the overall relationships.

Canonical comparison rigs use sun azimuth 315°, elevation 60° for midday and 6° for golden hour. These are studio comparison assumptions, not solar predictions for any date/location. Production uses the engine's solar model. Tone mapping/exposure must be held consistent when comparing renderers; the supplied colour transform is not a physical lighting simulation or a prediction of exact framebuffer pixels.

## Phone readability and performance
Proposed evaluation camera: eye height 1.6 m, vertical FOV 55°, fixed exposure, same tree/ground across 5, 20 and 40 m. For a centred 10 m object at constant depth, the approximate projected height fraction is H / (2d tan(FOV/2)): 1.92 at 5 m (cropped), 0.48 at 20 m, 0.24 at 40 m. This is a framing check, not a measurement of image 06. Repeat the test in the actual portrait and landscape app viewports.

| View | Proposed geometry/readability |
|---|---|
| 5–15 m | Trunk, forks, primary lobes and contact read; optional broad silhouette notches. Tree total starting target 450–900 triangles, no extra leaf meshes by default |
| 15–40 m | Same silhouette and sky-hole hierarchy, fewer interior branches; approximately 180–450 triangles/tree |
| 50–150 m | Simplified crown groups and trunk; 80–180 triangles/tree; no leaf/flower/tuft details |
| 150–600 m | Varied smooth opaque silhouettes, approximately 24–60 triangles/tree; no diamond-shaped placeholders |
| Aerial crown >24 px | Asymmetric lobes and broad internal gaps; simplify using distance as well |
| Aerial crown 8–24 px | 24–60 triangles; retain family silhouette |
| Aerial crown 2–8 px | 8–16 triangles; broad colour and ground placement |
| Below 2 px | Aggregate distant vegetation coverage while retaining mapped positions in source data; no relocation |

Use approximately 24–80 triangles per near shrub, 8–24 at medium distance and 8–12 per distant hedge section where appropriate. Palm ribbons can use 4–8 triangles each; trunk included in the complete tree count. These counts are **initial mesh targets**, not entitlements per visible tree. Cap aggregate cost and cull/LOD before filling the screen with near assets. Crossfade with controlled short transitions only if the renderer's overdraw budget supports it; a stable screen-size hysteresis band is preferable to constant threshold chatter.

Charge these effects to the existing [v2 §8.1 budget](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md#81-budget-allocation), never as extra budget:

| Effect | Existing bucket |
|---|---|
| Tree/shrub meshes, materials, culling and instances | Base opaque world: 4.25 ms |
| Cast shadows and trunk ground contact | Sun/character shadows: 1.45 ms; contact increment ≤0.10 ms inside it |
| Crown shading, vertex AO and ambient fill | 0.15 ms |
| Snow exposure mask | Surface additions: 0.25 ms shared with other surface effects |
| Optional near decorative leaf/flower/tuft geometry | Near additions: 0.35 ms shared, not a new allocation |
| Seasonal colour selection | Existing material/opaque path; no extra pass |
| Shared final colour grade | Existing post-processing allocation; no vegetation-only post pass |

Keep the total scene ceiling **400k main triangles, 150k shadow triangles, 100 main draws, ≤10 ms GPU/frame**. The v2 35k near-detail reserve is inside the 400k ceiling. Any optional new shrub/flower embellishment should use at most 4k of the remaining shared reserve and displace other details if necessary; ordinary shrubs remain base-world geometry. Do not consume the 2.10 ms safety margin to improve this sheet's decorative fidelity. Opaque crowns, instanced variants, bounded spatial batches, no per-leaf shadows, no alpha-card leaf clouds, no per-frame AO solve. Snow uses the existing shared surface path.

Acceptance still requires actual iPhone 13-class measurements at the app's real drawable resolution over a sustained walk, with thermals and shadow load recorded. These concept sheets establish appearance, not a frame-rate claim.

## Review and acceptance
1. At 40 m and aerial scale, can oak/elm/spruce/palm be distinguished by silhouette without reading a label?
2. Are shaded crowns dimensional and readable, with branches visible through intentional gaps?
3. Does winter preserve evergreen foliage, remove deciduous crowns, and keep snow weather-dependent?
4. Does the same green crown receive warm golden-hour light without becoming an autumn tree?
5. Are contact, beds and shrubs simplified enough to preserve the world budget and route clarity?

Saved outputs: six PNG sheets, three SVG swatch charts, this README, colour JSON and prompt JSON. All deliverables are under this folder. Built-in image generation created the raster sheets; a single targeted simplification edit was applied to the shrub sheet. SVGs are exact authored colour diagrams, not substitutes for the illustrated sheets.

## Addendum — Weeping willow

**6 October 2026.** [Construction, assumptions and performance notes](ADDENDUM-Weeping-Willow.md). Exact colors extend the existing color JSON. Original entries and images are preserved.

- [addendum-01-weeping-willow-seasons.png](images/addendum-01-weeping-willow-seasons.png)
- [addendum-02-willow-exact-colours.svg](images/addendum-02-willow-exact-colours.svg)

[Generation prompts](addendum-prompts.json). Raster artwork is illustrative; exact JSON/SVG references govern.
