# WorldEngine ground construction pack — Style B
**6 October 2026 · Proposal only · Rich stylized · Renderer-neutral**

Ground should read as a set of living surfaces and useful boundaries at phone size. Start with broad lawn tone, pavement rhythm, worn edges and soft contact shade. Add restrained weather response before decorative microdetail.

Appearance anchors: [look-fix midday](../look-fix-v1/images/lighting-03-ordinary-1530.png), [vegetation pack](../vegetation-v1/README.md), and the [v2 visual specification](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md). All deliverables are in this folder. The pack proposes art direction and data; it supplies no engine implementation or changed production profiles.

## Sheets and data
| File | Contents |
|---|---|
| [01 Lawn: too flat vs target](images/01-lawn-flat-vs-target.png) | Paired 5 / 20 / 40 m studies, tone/stripe/contact hierarchy, edge and leaf details |
| [02 Hard surfaces](images/02-hard-surfaces.png) | Sidewalk, three driveway types, curb/gutter, parkway, alley, road repair and seal |
| [03 Beds and transitions](images/03-beds-and-transitions.png) | Mulch, foundation planting, lawn/walk, lawn/bed, gravel edge, sand/coral stone with aerial insets |
| [04 North Shore / Chicago](images/04-region-chicago.png) | Three street distances, aerial, alley and autumn |
| [05 Denver](images/05-region-denver.png) | Three street distances, aerial, thin edge and xeric gravel bed |
| [06 Miami](images/06-region-miami.png) | Three street distances, aerial, St. Augustine-inspired turf, pale stone and sand bed |
| [07 Dry / light rain / soaked](images/07-weather-dry-rain-soaked.png) | Lawn, concrete/curb, asphalt/brick, mulch/gravel/sand |
| [08 Snow / tracks / banks / leaves](images/08-weather-snow-and-leaves.png) | Fresh, trodden, plowed and litter appearance studies across the same surface families |
| [09 Chicago exact colours](images/09-chicago-exact-colours.svg) | Dry / wet / soaked material hex values and lawn contrast limits |
| [10 Denver exact colours](images/10-denver-exact-colours.svg) | Dry / wet / soaked material hex values and lawn contrast limits |
| [11 Miami exact colours](images/11-miami-exact-colours.svg) | Dry / wet / soaked material hex values and lawn contrast limits |
| [12 Weather and contrast controls](images/12-weather-and-contrast.svg) | Exact overlay colours, paired pavement contrast samples and contact rule |
| [Ground colour JSON](ground-colours.json) | 3 regions × 21 materials × 7 states = 441 material-state records; neutral hex, exact contrast, roughness, lighting references and construction caps |
| [Prompts](image-prompts.json) | Built-in image-generation prompts, style references and edit history |

**Authority:** JSON values and exact SVG charts govern construction. Generated raster sheets communicate composition, broad material relationships and lighting. Their pixels do not prove the printed contrast percentages, physical scale, camera projection or frame rate. Regional distances are conceptual framing studies. Some raster details remain more elaborate than the implementation target, especially grass edges, gravel, enlarged leaves and snow-bank lumps. Use the edited sheets 01/03 for the intended simplified ground abstraction; retain the same discipline in the other sheets.

Every numerical dimension, palette, density, pattern, roughness, contrast and performance subdivision below is an **authored proposal assumption**, unless explicitly identified as an existing v2 constraint. Colours were selected for this pack, not sampled from photographs. Exact arithmetic is verifiable; phone readability still needs an engine/device check.

## Exact contrast definition
Decode sRGB hex to linear RGB. Luminance is:

Y = 0.2126 R + 0.7152 G + 0.0722 B.

Signed contrast relative to the surface's base is:

ΔY% = 100 × (Yfeature − Ybase) / Ybase.

Thus ±5% means excursions to 0.95Y and 1.05Y, a total extrema difference of 10% of base Y. It does not mean five sRGB code values, a five-percent hue adjustment or a measured final-screen contrast. Final screen contrast also depends on illumination, tone mapping, display and geometry.

The JSON provides both the intended multiplier and the achieved contrast after 8-bit hex rounding. Use the multiplier for continuous materials; use the hex for exact palette diagrams. Interpolate in linear light. Do not add contrast percentages independently without the combined clamps.

| Feature | Proposed starting contrast | Phone construction |
|---|---:|---|
| Broad lawn patches | ±5% Y | 1.5–4 m soft irregular areas |
| Fine lawn variation | ±1% Y | 0.25–0.7 m band; part of the same two-band evaluation |
| Mowing stripes | Chicago ±3%; Denver ±2.25%; Miami ±1.95% Y | 0.8 m bands, restrained directional impression |
| All ordinary lawn pattern combined | Clamp ±6% Y | Patch + fine + stripe is bounded; no camouflage carpet |
| Wet lawn pattern strength | 75% of dry amplitude | Ordinary pattern remains quiet through wetness |
| Concrete joints | −15% Y | 8–15 mm physical seams, coverage-filtered |
| Concrete wear | −4% Y | Few 0.3–1.2 m soft patches; do not erase slab rhythm |
| Brick joint | −12% Y | 8 mm seam, approximate 0.20 × 0.10 m pavers |
| Brick-to-brick variation | ±3% Y | Coherent family, no checkerboard colour randomness |
| Asphalt repair vs its road | −12% Y | Irregular 0.5–4 m² local patch |
| Crack seal vs its road | −25% Y | Few 20–50 mm winding paths |
| Mulch / gravel / sand pattern | ±4% / ±3% / ±2% Y | Broad, filtered shape variation, no grain carpet |
| Coral-stone pore accents | −5% Y | Up to 3 quiet near-slab spots |
| Light-rain substrate | −10% Y | Separate roughness change makes wetness visible |
| Soaked substrate | −15% Y | Bounded standing-water mask only where justified |
| Trodden snow vs fresh snow | −27.3842% Y in exported hex | Blue-grey compacted overlay, not a global ground darkener |
| Dirty base vs plowed-bank snow | −40.3987% Y in exported hex | Only the lower dirty band, not the whole bank |
| Tree/hedge contact | −15% **ambient contribution** | Ambient visibility 0.85; direct sunlight is unaffected |
| Curb contact | −12% **ambient contribution** | Soft local cavity, not a black outline |

Charts show the nominal ±3% stripe palette envelope. Regional stripe strength is additionally scaled by 0.75 in Denver and 0.65 in Miami; the effective percentages above and JSON fields are authoritative. Regional differences in maintenance are illustrative, not observed facts about every lawn.

Wear is a separate hue/coverage mask, not another ordinary ±5% noise layer: blend 35% toward the region's soil family, with a starting 2–6% lawn-area coverage. The JSON reports the resulting exact ΔY for each region. Confine it to plausible local edges or supplied wear; do not declare a real property neglected.

## Lawn construction
1. Preserve mapped grass/parkway polygons and the actual walk/drive boundary. Apply material variation within the grass mask only.
2. Use two stable world-space bands, 1.5–4 m and 0.25–0.7 m. Broad patches provide readability; the fine band supports the close view without blades.
3. Add optional mowing bands aligned to the inferred lawn's long direction or supplied mowing direction. Clip to the polygon. Illustrative inferred stripes should occur on at most 35% of eligible lawns, and never across roads, buildings or gravel beds.
4. Combine patch/fine/stripe terms and clamp their total to ±6% linear luminance. Fade stripes from 25–40 m; fade fine variation from 35–50 m; coarsen broad patches from 50–120 m, then average to base. Projected size can suppress them sooner.
5. Place 0.15–0.5 m-wide thinning/wear bands only beside selected driveway entries or known worn desire lines. No automatic fictional footpath through every lawn.
6. Keep lawn/walk edges legible with the boundary, slight height difference and local occlusion. Sparse tufts accent only a few near edges. Most grass is a surface.
7. Under trees and hedges, use existing sun shadows plus bounded ambient contact. The short contact pocket near the trunk/hedge base is not a static crown-shaped shadow.

Combine additional contact with existing AO using the stronger occlusion, e.g. min(existing visibility, new visibility), rather than multiplying both and creating black pools. Maintain the v2 ambient visibility floor 0.65. Trunk contact starts at radius 0.15–0.4 m; hedge contact width 0.1–0.4 m. Broad canopy shade follows the real solar direction. Do not paint permanent dark lawn disks below trees.

Use muted tan for exposed dormant northern turf through regional phenology. Suppress lawn patterns beneath snow. Miami winter does not automatically become a northern dormant tan lawn; drought/health changes require separate supplied or inferred state.

## Hard surfaces
**Sidewalks:** retain geometry and width supplied by the world. Start transverse slab joints at 1.5–2.0 m spacing, 8–15 mm seam width and −15% Y. Expansion seams may appear at 6–8 m spacing. Orient along path tangent/distance; never use a world-axis checkerboard across curving walks. Joints use an analytic or authored mask with antialiasing, not one mesh/draw per seam. Fade 35–60 m or sooner when unresolved. Do not widen a seam to several centimetres to keep it visible.

**Concrete driveways:** same restrained family as sidewalks with larger 2.5–4 m slabs, low-contrast wear and threshold contacts. Surface slope/drive apron must follow supplied geometry. Do not create a new entrance or alter a footprint to fit a decorative pattern.

**Asphalt driveways/roads:** quiet charcoal-grey base, one or two broad wear/repair regions in a visible chunk. Cap repair coverage at 5%; patches have rounded/irregular edges, not tile repetition. Repair/seal feature tones are derived relative to the actual road base. Named road-patch and crack-seal palette colours also exist as standalone material families; do not substitute those independent identity colours when an exact relative repair contrast is required.

**Brick drives:** muted clay family with simple paver rhythm and ±3% variation. Brick material remains flat geometry unless a silhouette/step needs depth. Filter and average when pavers project below approximately 2 pixels; never alias into a crawling red grid.

**Curbs/gutters:** geometric curb rise 0.10–0.15 m and shallow gutter strip 0.25–0.45 m when not supplied. Near bevel 5–15 mm catches light. Keep ramps and crossings usable; never run a raised curb across an accessible crossing. The gutter has a distinct but restrained tone and a small contact cavity. Drainage is not established by a palette.

**Parkway strips:** turf between walk and road where the mapped alignment allows it. Proposed unknown-width band is 1.2–2.5 m; omit when space is absent. Do not shift mapped walks or reduce a road to make one.

**Chicago alleys:** concrete/asphalt material variants and garage thresholds. A restrained paver drainage-strip variant can be shown when mapped/supplied; its actual permeable construction is not inferred from colour. Never invent an alley because the region is Chicago, and do not assume every North Shore suburb has a city alley. The reference is one possible local pattern.

**Crack seal:** 1–2 stable paths per visible road chunk, 20–50 mm width, −25% Y reference. Avoid dense crack webs. Fade 25–45 m, use screen-space filtering, and keep road markings/crossings more legible. These are visual assumptions, not structural road-condition observations.

## Beds and edges
Mulch is a bounded warm brown material with broad ±4% patches. Gravel is a warm neutral material with ±3% patches; sand uses ±2%. Near accents can be a few opaque chip/stone shapes; broad patches do most of the work. Coral-stone accents are large quiet tone spots rather than high-frequency holes.

Foundation beds follow supplied or clearly inferred garden boundaries and use the [vegetation shrub forms](../vegetation-v1/README.md). Their edges matter more than decorative fill. Keep a calm strip around doors, path centre and drive clearance.

- Lawn/walk: physical boundary first; 10–30 mm apparent turf lift where sensible, 20–50 mm soft edge transition. Do not add a dark moat.
- Lawn/bed: shallow 10–30 mm cut edge or a simple small edging strip when supplied. No exaggerated trench.
- Lawn/gravel or sand: clipped boundary plus a few stones; no spill that closes a walk.
- Bed/foundation: warm bed material and restrained existing AO join the plant mass to the wall. Preserve mapped building footprints.
- Bare thin patches blend toward soil; beds blend within their own masks. Do not blur material edges through concrete or crossing geometry.

Raised edging can use geometry for its visible silhouette, but a painted edge/joint/wear mark should use a material mask. Decorative edging is inferred detail, not evidence of a surveyed property boundary.

## Weather states and layer ordering
The JSON enumerates dry, light-rain, soaked, snow-fresh, snow-trodden, snow-plowed and fall-leaves for every regional material. Snow columns describe overlay treatments and exposed substrate; they do not imply that every surface is fully covered or every Miami surface routinely snows. Coverage and palette are independent.

**Composition order:** mapped surface + regional neutral material → stable wear/patterns → wetness on exposed substrate → snow coverage/exposure → traffic/plow modification if supplied → bounded litter where exposed → solar/ambient/contact lighting → shared final grade. Snow occludes wet sheen and covered leaves; exposed melted/cleared areas can remain wet. Wet leaves use the wet leaf palette and remain still. Do not stack snow, puddle and leaf opacity until the same pixel carries every effect.

**Dry:** matte material, full bounded pattern amplitude, no puddles. Lawn roughness starts at 0.90, paving around 0.85–0.92, beds around 0.98.

**Light rain:** substrate RGB multiplied by 0.90 in linear space; roughness drops to 0.55 for concrete/stone, 0.45 for asphalt, around 0.80 for turf and 0.92 for bed aggregates. Use restrained broad daylight sheen. This surface change must be visible at matched lighting even without rain particles. Do not make turf or mulch look like polished plastic.

**Soaked:** substrate multiplier 0.85. Use separate shallow puddle masks only at supplied depressions or an explicitly authored drainage/demo mask. Starting cap: 6 visible puddles, one puddle field at a pixel, ≤4% eligible visible ground area, typical diameter 0.3–2 m. Exclude steep surfaces, planting masses, steps and building interiors. Porous sand/gravel/mulch must not automatically puddle everywhere. A small sky-coloured body plus bounded broad highlight can convey water; no scene mirror, planar-reflection pass or screen-space reflection system is required. Puddle roughness reference is 0.18; exact sky appearance follows time/weather.

**Fresh snow:** opaque pale snow mixture through area coverage, using existing v2 0.4–1.2 m and 2–5 m masks, exposure and upward-facing eligibility. Amount 0.6 means about 60% eligible area, not 60% white opacity everywhere. Starting patchy-lawn coverage 40–70%; full blanket coverage is an authored high-accumulation study. Soft mask edges 0.05–0.15 m. Joints/wear remain on exposed pavement only.

**Trodden snow — Stretch:** supplied recorded footprints/traffic or a labelled demo state drives a compacted blue-grey lane. Individual impressions use masks/normal perturbation near the viewer, approximately 5–20 mm implied depth. Do not infer footsteps from snowfall. An engine walk route alone does not establish all pedestrian/vehicle history. Use broad compacted paths at medium distance; no dense trail of identical geometry craters.

**Plowed banks — Stretch:** supplied clearing/plow history or explicit demo state produces a low opaque ridge beside the cleared path/curb. Proposed bank height 0.15–0.45 m, at most 8 visible sections, small dirty lower strip and exposed wet gutter. The exact dirty-base palette is a strong local contrast and should cover only the bottom 5–15% of bank height. Terrain/clearance and actual snow mass must permit a bank; preserve walk width, ramps and sight lines. No automatic banks from a WeatherKit snowfall code.

**Fall leaves:** region/tree phenology supplies eligibility. Simple opaque leaves 0.06–0.12 m, 4–8 triangles each; 70% in 0.2–0.6 m edge bands, 20% under deciduous crowns, 10% isolated. Existing v2 limits: ≤800 static leaves, cluster peaks ≤20/m², open walk ≤0.5/m²; fade 35–45 m, gone by 50 m. Distant litter becomes broad restrained colour patches, not a confetti field. Images exaggerate individual leaves for explanation; the dimensions here govern. Miami gets sparse evergreen leaf turnover, not the northern autumn carpet. Simulated piles remain Stretch.

Changing weather must preserve stable mask/scatter identity. Snow accumulation, wetness and seasonal state belong to environment data/history; renderer-specific material controls express their appearance. Unknown clearing, drainage, maintenance or traffic history stays unknown.

## Regional choices and evidence
The material selections are **profile assumptions**, subordinate to mapped/supplied surface tags. Regional palette choice never authorizes new geometry or replacement of known paving.

| Region | Proposed ground character |
|---|---|
| North Shore / Chicago | Cooler lush green turf, restrained lawn bands, warm grey slab paving, occasional clay-brick drives, dark brown beds; mapped alleys may use concrete/asphalt variants |
| Denver | Muted olive turf with small straw/thin areas, warm concrete, tan gravel and xeric bed gaps; irrigated lawns can remain fully green |
| Miami | Deeper green/blue-green turf, coarse simplified edge shapes, warm concrete plus optional pale coral-stone paving, warm sand confined to eligible beds |

Sources checked **6 October 2026**:

- **Verified:** St. Augustinegrass is widely used in Florida and has green to blue-green colour; its coarse leaves support a broad turf-edge abstraction. [UF/IFAS Gardening Solutions](https://gardeningsolutions.ifas.ufl.edu/lawns/turf-types/st-augustinegrass/), [UF/IFAS St. Augustinegrass for Florida lawns](https://ask.ifas.ufl.edu/publication/LH010).
- **Verified:** Colorado xeriscape guidance discusses selective turf replacement and gravel mulch for appropriate plants. This supports the availability of a dry-bed palette, not a claim that every Denver yard is xeric. [Colorado State University, retrofit your yard](https://extension.colostate.edu/resource/xeriscaping-retrofit-your-yard/), [PlantTalk Colorado, xeriscape mulches](https://planttalk.colostate.edu/topics/water-wise-xeriscape/1905-xeriscape-mulches/).
- **Verified limited context:** Chicago transportation services include streets, alleys and sidewalks. [Chicago Department of Transportation](https://chicago.gov/CDOT). Alley paving mix, the illustrated paver strip, and applicability to North Shore suburbs remain assumptions in this pack.
- Miami coral-stone/sand styling was requested by the user and is an **assumed optional material family**, not a verified citywide construction prevalence. North Shore lawn species, maintenance, slab sizes and regional wear frequency likewise remain assumptions.

## Texture vs geometry on a phone
Style B excludes photographic surface albedo. A renderer may use an authored or procedurally baked texture **mask** for broad patterns if that is cheaper than evaluating them; using a mask does not require a photograph.

| Treatment | Preferred representation | Why / limit |
|---|---|---|
| Lawn patches and bands | World-space procedural fields or baked low-frequency RG mask | No blade geometry, stable metres, at most two noise bands |
| Concrete joints, brick rhythm | Analytic pattern or authored mask atlas with mips | No separate slab/seam meshes or per-paver draws |
| Wear, repairs, crack seal | Combined bounded mask in the existing surface material | Avoid stacked coplanar decals and extra passes |
| Mulch/gravel/sand colour | Flat material + filtered low-frequency mask | No particle-like geometry for every chip or grain |
| Coral pores | Few soft mask shapes; optional subtle normal | No pore tessellation or sampled photographic detail |
| Curbs, ramps, gutters, raised edging | Actual low-poly geometry | Visible height, silhouette and walk/road separation |
| Trunk/hedge contact | Existing AO/fill path, bounded analytic mask where needed | No baked sun shadow; avoid duplicate darkening |
| Wet surface/puddles | Shared wet material variant and clipped mask | Bounded work; no mirror render pass or transparent layer stack |
| Patchy snow | Existing exposure/coverage shader | No separate plane for every patch |
| Trodden tracks | Authored supplied mask / bounded near normal variation | Stretch; simplify to lane at distance |
| Plow banks | Small opaque low-poly ridge instances | Stretch; ≤8 sections and shared triangle reserve |
| Near stones/chips/tufts/leaves | Sparse opaque instances | Silhouette accents only; distance and projected-size caps |
| Aerial | Base polygons and broad mask groups | Remove detailed joints, leaves, tufts, track marks and tiny pebbles |

Use derivatives or equivalent filtering to average subpixel features. A physical joint narrower than one pixel contributes fractional coverage, not a forced one-pixel black line. Fine features should fade before they shimmer. Near normal maps are optional authored masks, not a reason for high-frequency noise over every pixel.

Optional mask-cache proposal: 256 × 256 RG8 per roughly 16 m chunk, with full mip chain ≈0.167 MiB per layer. Keep the visible working set under 4 MiB including all ground mask layers; budget resident layers and mip chains together, reduce resolution/layers on pressure. No unique photographic material per lot, no unbounded full-city mask allocation. World-space phase must remain continuous across chunks; local masked features use stable feature seeds and an origin independent of camera motion.

## Existing performance budget
The following ceilings and buckets come from [v2 §8.1](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md#81-budget-allocation). They are targets, not measured costs of this pack.

| Ground treatment | Existing bucket, shared with other effects |
|---|---|
| Ordinary ground meshes/materials, curb silhouettes, masks and culling | Base opaque world: 4.25 ms |
| Sun shadows and contact solution | Sun/character shadows: 1.45 ms |
| AO/fill and ground contact modulation | Vertex AO/fill/crown shaping: 0.15 ms |
| Lawn variation, joints, bed pattern, exposed-snow masking | Surface additions: 0.25 ms |
| Near bevels, leaves, tufts, optional accents | Near geometry additions: 0.35 ms |
| Wetness, bounded puddle appearance and existing streak fields | Wet/local-light additions: 0.35 ms |
| Optional airborne leaves/rain/snow | Existing weather-particle allocation: 0.20 ms |
| Shared final grade | Within existing total post-processing allocation: 0.90 ms |

Mowing, gravel and crack patterns must share/simplify the existing surface evaluation, not add independent layers on top of two lawn noise bands and two snow bands. In the snow shader variant, covered snow replaces grass detail. If a combined variant exceeds its bucket, drop fine lawn/gravel pattern, crack detail and pores first. Puddles share the wet evaluation; do not double the existing six local-light streak fields by giving each puddle another light loop.

Keep **≤10 ms GPU/frame, ≤400k main triangles, ≤150k shadow triangles and ≤100 main draws**. The 35k near addition reserve is inside 400k: bevels ≤20k, static leaves ≤6.4k, tufts ≤4k, and the remaining 4.6k is shared by AO support/optional caps and all other embellishments.

Proposed banks/stones/extra bed edging use **≤2k combined additional triangles per view**, strictly a subset of that shared remainder. Reduce vegetation's optional embellishment allocation when needed; do not sum its suggested 4k and this 2k into a nonexistent reserve. Existing curb base geometry still counts in ordinary world geometry. Optional bank shadow geometry also counts in the 150k ceiling; simplify or disable it when needed.

Near tufts keep the existing cap of 200 clusters, 3–5 blades / 12–20 triangles each, within 25 m, fade 20–30 m. All decorative ground geometry is gone by 50 m. LOD transitions count both versions in caps. Instance in small cullable spatial groups; instancing does not eliminate triangle cost. Keep the 2.10 ms safety margin reserved.

**Stretch effects:** standing-water placement, trodden tracks and plowed banks need additional input and measured budget approval before implementation. They are depicted because this construction pack was requested to cover those states; v2's default patchy-snow treatment explicitly does not create footprints or plow banks automatically.

## Phone-size acceptance
Use the actual app viewport/drawable dimensions on iPhone 13-class hardware. Begin with a 1.6 m camera, 55° vertical FOV, fixed exposure and fixed sun. Capture the same surface layout at 5, 20 and 40 m, plus the actual aerial camera. Do not scale the ground or camera to make decorative details survive.

- At 5 m: lawn is dimensional without a blade carpet; joints, worn edge and bed boundary read; the route centre stays quiet.
- At 20 m: broad patches and ground boundaries read; filtered seams and mowing bands remain restrained; leaf identity can simplify.
- At 40 m: broad grouping and material edges carry the scene; stripes, crack webs, individual gravel and leaf geometry disappear.
- In aerial: turf/bed/walk/drive/road shapes and broad shade remain distinct; no shimmering grids or dark outlined parcels.
- At matched illumination: light-rain pavement is visibly darker/smoother than dry; soaked adds bounded low-spot water; snow suppresses covered patterns.
- At golden hour: light warms the same neutral palette. Do not feed the JSON golden-hour display references into albedo and tint them again.

Aim for broad lawn feature regions roughly 12–48 projected pixels wide in the near view. Remove fine pattern components below approximately 2 pixels rather than increasing their physical size. At 40 m, a visible boundary is more valuable than preserving 0.8 m stripe rhythm. These pixel guidelines are assumptions for evaluation, not guaranteed perception thresholds.

Compare effect toggles at identical camera, time, drawable size, warmed caches and thermal state. Measure sustained GPU time during a ten-minute walk and an aerial transition, plus worst frames, triangle/draw totals and memory. Exact contrast charts verify colour arithmetic; the generated sheets do not validate device performance.

## Recommendations
1. Implement broad lawn tone, edge hierarchy and contact before adding any decorative blades.
2. Put joints, repairs and wear in a shared filtered surface mask; use geometry for visible height.
3. Make light rain visible through restrained darkening and roughness, then add bounded puddles only with placement data.
4. Treat footprints, plowing and litter eligibility as supplied/history-driven state, preserving unknowns.
5. Validate the same 5 / 20 / 40 m views on a phone with the existing v2 budget before increasing detail.

Raster sheets were made with the built-in image-generation tool. Sheets 01 and 03 each received one targeted simplification edit; other sheets use their fresh generation. Exact SVG charts were authored as deterministic colour diagrams. Prompts and provenance are included.
