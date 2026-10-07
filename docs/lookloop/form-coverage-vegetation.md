# Vegetation form coverage: vegetation-v1 pack vs engine

Audit date 2026-10-07. Read-only. Pack: `docs/proposals/vegetation-v1/` (README, vegetation-colours.json, ADDENDUM-Weeping-Willow). Mock images: `~/Desktop/world-engine/docs/proposals/vegetation-v1/images/` (01 North Shore, 02 Denver, 03 Miami, 04 crown construction, 05 shrubs/hedges/beds, 06 phone distance/aerial, 07–09 swatch SVGs, addendum-01 willow seasons, addendum-02 willow swatch SVG). Renders: `.build/lookloop/runs/20261007-062707/raw/`.

Side-by-sides (left render, right mock, each 390 px wide) are local PNGs in `form-sides/vegetation/`.

## Top 10 visible vegetation form gaps

| # | Element | Engine status | Side-by-side | Owner |
|---|---|---|---|---|
| 1 | Crown construction: merged unequal masses, no "balls on a pole" | Partial: lobe tables exist, but default `.solid` style renders 2–7 smooth separate balls; reads as the pack's "too crude" | [crown-construction](form-sides/vegetation/crown-construction.png) | P2 |
| 2 | Sky holes / visible forks inside crown | Partial: limbs exist in skeleton but are hidden inside solid lobes; no readable holes at phone size | [oak-summer-crown](form-sides/vegetation/oak-summer-crown.png) | P2 |
| 3 | Winter bare branch structure (2–3 orders, fan of twigs) | Partial: bare skeleton draws 3–4 thick limbs only; reads as stumps with spikes, not a twig crown | [winter-bare-branches](form-sides/vegetation/winter-bare-branches.png) | P2 |
| 4 | Peak-fall crowns (form + colour per family) | Partial: colours correct per family (data), forms are lollipop balls; fall streets read as orange/yellow balloons | [peak-fall-crowns](form-sides/vegetation/peak-fall-crowns.png) | P2 (form); 5A (crown shading/AO) |
| 5 | Spruce / blue spruce: 7–10 drooping, ragged tiers | Partial: 7 staggered smooth cones; reads as a stacked paper cone with dark stripes, no bough rims at mid distance | [spruce-tiers](form-sides/vegetation/spruce-tiers.png) | P2 |
| 6 | Aerial crown read: asymmetric lobes, internal gaps | Partial: aerial shows one or two spheres per tree | [aerial-crowns](form-sides/vegetation/aerial-crowns.png) | P2 |
| 7 | Trunk root flare + darker ground contact | Partial: flare only in `.puffs` style (not default); default trunk is a plain cylinder meeting grass | [trunk-root-flare](form-sides/vegetation/trunk-root-flare.png) | P2 (flare); 5A (contact darkening) |
| 8 | Foundation shrubs (3–5 merged lobes, flowering + evergreen mix) | Partial: 8 bush variants exist but appear as small grey-green pills at the house base | [foundation-shrubs](form-sides/vegetation/foundation-shrubs.png) | P2 |
| 9 | Elm vase / honey locust airy umbrella (family openness 18% / 25%) | Partial: both drawn with the oak `spreading` lobe table; no distinct silhouette | [elm-vase-honey-locust](form-sides/vegetation/elm-vase-honey-locust.png) | P2 |
| 10 | Denver beds: islands, mulch/gravel, rocks, grass ribbons | Partial: tufts and bushes only; no bounded bed islands or rocks in ordinary-street | [denver-xeric-beds](form-sides/vegetation/denver-xeric-beds.png) | P2 |

Also visible, below the top 10: [crabapple-blossom](form-sides/vegetation/crabapple-blossom.png) (missing; P2 placement + 5A blossom shading), [aspen-pale-trunk](form-sides/vegetation/aspen-pale-trunk.png) (partial; P2), [spruce-winter-snow](form-sides/vegetation/spruce-winter-snow.png) (no conifer in the winter frame to judge; 5A).

## What the engine renders by default

- `PropLibrary.crownStyle` defaults to `.solid` (`Sources/WorldGen/Props.swift` ~l.101): leaf cards are off (`WORLDENGINE_CROWN_STYLE=leafCards` or `WORLDENGINE_LEAF_CARDS=1`), `.puffs` (paintover clusters + root flare) is opt-in.
- Crown archetypes: `treeBroad` (maple), `treeOval` (linden), `treeSpreading` (oak; elm, honey locust, cottonwood share it), `conifer`, `treeWeeping` (willow). One shape variant per kind (`variants`), variation via yaw/stretch only (pack asks 3 skeletons × 2 envelopes per family).
- Species → form and season colours: `Sources/WorldGen/Profiles/vegetation.json` (Chicago 6 + willow, Denver 5; Miami absent). `genusForms` maps OSM genus; `Populus tremuloides` → oval.
- Snow on crowns/conifers/bushes: `Sources/WorldEngine/Shaders/WorldShaders.metal` ~l.452.
- Blossom: no code or data (grep `blossom` = 0 hits).

## Element table

Status legend: built = matches pack at phone size; partial = exists but form/feature diverges; missing = nothing in engine.

### Species × season (64)

Colours are built as data for every Chicago/Denver/willow season (neutralCrownAlbedo in vegetation.json); status below is for **form** as rendered by default.

| Species (region) | Spring | Summer | Peak fall | Winter | Evidence / owner |
|---|---|---|---|---|---|
| Oak (NS) | partial | partial | partial | partial | spreading lobes, solid balls; bare skeleton thin. P2 |
| Maple (NS) | partial | partial | partial | partial | broad lobes. P2 |
| Elm (NS) | partial | partial | partial | partial | uses oak form, no vase/arching limbs. P2 |
| Linden (NS) | partial | partial | partial | partial | oval lobes. P2 |
| Honey locust (NS) | partial | partial | partial | partial | uses oak form, no 25% holes. P2 |
| Spruce (NS) | partial | partial | partial | partial | smooth stacked tiers; winter snow shader exists. P2 / 5A |
| Cottonwood (Denver) | partial | partial | partial | partial | oak spreading form; no tall stout scaffold. P2 |
| Ash (Denver) | partial | partial | partial | partial | oval form. P2 |
| Blue spruce (Denver) | partial | partial | partial | partial | same conifer mesh, blue-green colour. P2 |
| Aspen (Denver) | partial | partial | partial | partial | oval form, pale branch colour #C9C6B5; tagged trees only (not in region slots), no slim 2-trunk group. P2 |
| Crabapple (Denver) | **missing** (blossom) | partial | partial | partial | broad form; no bloom phase. P2 / 5A |
| Royal palm (Miami) | missing | missing | missing | missing | no palm kind, no Miami region. P2 |
| Live oak (Miami) | missing | missing | missing | missing | P2 |
| Sea grape (Miami) | missing | missing | missing | missing | P2 |
| Banyan (Miami) | missing | missing | missing | missing | P2 |
| Weeping willow (NS) | partial | partial | partial | partial | `treeWeeping` lobes + `willowCurtains`; slot deciduous9 / Salix tags / profile prior; not seen in test views. P2 |

### Construction, structure, shrubs, colour (24)

| Element | Status | Evidence | Owner |
|---|---|---|---|
| Crown lobe counts / merged masses | partial | `lobes()` 6–7 lobes per family; solid style shows separate balls | P2 |
| Sky holes per family | partial | targets in comments (5–10%); not readable in renders | P2 |
| Family openness (elm 18%, locust 25%, cottonwood 16%, aspen 20%) | partial | only 4 lobe tables | P2 |
| Spruce tiers 7–10, drooping ragged | partial | Props.swift ~l.1591, 7 tiers, smooth rims at mid | P2 |
| Branch structure / visible forks | partial | `bareSkeleton`, `BranchStyle` per kind; hidden in leafy crowns | P2 |
| Trunk root flare | partial | `.puffs` only (Props ~l.605) | P2 |
| Ground contact darkening | partial | baked AO; not visible as a contact value | 5A |
| Winter bare forms | partial | same skeleton, too few orders | P2 |
| Spring blossom (crabapple) | missing | no data/code | P2 (placement) / 5A (shading) |
| Snow on evergreen boughs | built | WorldShaders.metal snow on crowns/conifers | 5A |
| Aerial crown read | partial | far/skyline icosahedra | P2 |
| Phone-distance LOD bands | built | `lodDistances` 45/160/400, triangle budgets | P2 |
| Golden-hour crowns stay green | built | lighting/grade data, colours are albedo | 5A |
| Foundation shrubs | partial | bush variants 0–7 | P2 |
| Hedges (continuous, irregular crest) | partial | variant 5 hedge segment + `addHedgeTent` | P2 |
| Beds (islands, mulch, rocks) | partial | yards place bushes/tufts; no bed surface/rocks | P2 |
| Denver xeric grasses/juniper | partial | tuft kind, no juniper palette in shrubs | P2 |
| Miami shrubs (broadleaf, coontie, sea grape) | missing | no Miami region | P2 |
| Shrub winter bare twigs | missing | bushes keep body in winter | P2 / 5A |
| Willow hanging curtains | built | `willowCurtains(lod:)` | P2 |
| Chicago swatches | built | vegetation.json chicago-* | 5A |
| Denver swatches | built | denver-* (owner revision 2026-10-07 mixes in maple/oak) | 5A |
| Miami swatches | missing | not imported | 5A |
| Willow swatches | built | chicago-weeping-willow | 5A |

Totals: 88 elements: built 7, partial 60, missing 21.
