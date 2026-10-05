# WorldEngine Regional Profiles — Proposal v1

**5 October 2026 · Proposal only · Renderer-neutral data and geometry rules**

The first priority is a plausible North Texas suburb without turning every footprint into a Denver bungalow or putting a garage door on every front facade. Regional style should choose among plausible missing details; it must never rewrite mapped geography. The five regional drafts and conservative generic fallback are in [regions-draft.json](regions-draft.json). Six fresh style sheets are linked in §9.

## 1. Evidence, scope and compatibility

**Evidence convention used throughout this document and JSON:** **Verified** means a cited source or inspected repository behavior supports the specific statement, checked **2026-10-05**. **Assumption** means a proposed art-direction value or inference, including every new percentage, color, dimensional range, density, box boundary and performance estimate. These are starting priors, not census results or surveyed property attributes. **User-supplied** describes the Plano counts pending the actual extract. Source IDs resolve in §10 and the JSON source registry. Image content is always illustrative assumption, never evidence of a real property.

**Verified, LOCAL-SCHEMA:** `docs/style-profiles.md` describes the older `houses`/`garages` format. The current `StyleProfile.swift`, `default.json` and `front-range.json` use version 2: `houseTypes`, `typeRules`, `typeThresholds`, singular `garage`, `shed`, `trees`, `seasons`, `chimneyLikelihood` and `foundationMeters`. This proposal follows the current decoder and files. No production data or code has been changed.

**Verified, LOCAL-SCHEMA:** coordinated colors are ordered `[wall, trim, door, roof]`; house-type eligibility supports floors, aspect, rectangularity and broad frontage; the current catalog contains ordered bounding boxes and first match wins. The seasonal surface palette is currently separate and globally loaded. There are no current profile fields for attached-garage placement, fence conventions, yard densities, per-profile lawn palettes or explicit broadleaf evergreen behavior.

**Assumption — bundle contract:** `regions-draft.json` is a review envelope, not a drop-in `StyleProfile` file. Each object in `profiles` matches the current profile schema independently; `regionCatalog` matches the catalog schema. A future integrator would extract these objects into separate profile files after approval. The envelope's `proposedAdditions` is explicitly outside that schema and has no runtime effect. `front-range` remains an external, existing profile dependency; its existing catalog entry is retained without rewriting it. The generic refinement has a new ID so it does not silently overwrite `default`.

**Verified, LOCAL-TREES; important limitation:** the current tree path treats unknown trees as conifers when the `deciduousShare` draw fails, and uses `leaf_type` to select conifer versus broadleaf. Leaf form and annual leaf loss are not equivalent. Portland explicitly inventories both axes (PNW-TREES); Mesa describes semi-evergreen broadleaf desert trees (AZ-TREES). The legacy-compatible values in this draft approximate **non-conifer silhouette share**, with the misleading existing field name unchanged. They must not be cited as measured deciduous percentages. The true proposed leaf-habit shares are separate in §4 and `proposedAdditions`.

**Verified, LOCAL-GENERATOR; adoption gaps:** the current role classifier treats `building=yes` below 250 m² as a house, can treat a tiny tagged dwelling as a shed, rounds fractional floors, and falls back to unfiltered house candidates when eligibility is empty. These behaviors are not fixed by profile data. The new profiles include a flexible plain fallback, but do not solve arbitrary explicit floor counts, half-levels or unknown use. Before a production Plano gate, resolve these generic classifier issues separately: preserve explicit uses/levels, keep uncertain use visibly unclassified, and never force an ineligible family merely to avoid an empty lottery. The current `hugeArea` value is present in the schema but not a separate branch in `situation`; the >huge-area policy below is proposed behavior.

### 1.1 What the area data actually proves

**Verified, LOCAL-OSM:** the committed Sloan’s Lake inventory has 1,399 buildings, only 130 level tags, no roof-shape tags, 5,400 mapped trees and 20.77 km of separately mapped sidewalks. Its richly mapped vegetation and paths cannot establish suitable fallback density for another city. The inspected `docs/data/` and `Data/areas/` contain the Sloan’s Lake material, not a Russell Creek Park extract.

**User-supplied, not independently verified:** the next Plano area has about 1,157 buildings, almost no descriptive tags, 74 mapped trees and few mapped sidewalks. Those numbers describe mapping coverage, not actual tree or sidewalk scarcity. The city park map locates Russell Creek Park near McDermott/Coit/Independence (TX-PARK). The similarly named Russell Creek–Cross Creek neighborhood account is useful nearby evidence, but is not a survey of the target park's immediate blocks. Keep that distinction when validating garages.

**Assumption — input priority:** authoritative supplied overrides with provenance → valid mapped geometry/tags → mapped contextual access and land use → approved area context → profile priors → conservative unknown. Never infer surveyed facts from the art sheet. No landmarks, mountains, terrain, parcels, addresses, houses, pools, alleys or driveways are created just because a regional archetype commonly has them.

## 2. Shared house grammar and footprint rules

**Assumption, preserving LOCAL-V2 §4:** use the actual footprint area A, minimum-area rectangle aspect R (long/short), rectangularity Q (polygon/rectangle area), and a frontage chosen from credible mapped street/access context. Frontage must distinguish a broad ranch from a narrow deep house. No footprint rotation, width stretching or courtyard filling to make a chosen style fit.

1. Explicit garage, shed, apartment, commercial, civic and roof/carport tags bypass the house lottery. `building=yes` needs convincing residential context; area alone does not prove use. A mapped roof/carport stays open, not a walled garage.
2. Valid height/floors and roof tags override profile inference. Fit the facade grammar inside the supplied mass. A half-level is an attic candidate; do not add a full second wall story. A `capeLike` default has one wall story and a roof mass, not an invented occupied attic.
3. For a one-floor house with R ≥1.7 and a long side facing the street, use the `oneFloorBroad` weights. Otherwise use `oneFloor`. For two floors, use `twoFloorSquare` at R ≤1.5 and Q ≥0.78; `twoFloorNarrow` at R ≥1.7; otherwise `twoFloor`. These regional thresholds are assumptions and are explicit in the data.
4. With no levels, apply `small` below 60 m²; `large` above 220 m² (260 m² for DFW); otherwise `unknown`. Filter incompatible types and renormalize. First `floors` value supplies the inferred default only, never a probability distribution. Large Texas footprints may include an attached garage; do not conclude that every large polygon is a two-story mansion.
5. Above 350 m² (420 m² DFW) or for complex concavity, propose a restrained footprint-preserving mass and simple roof sections, with use/height confidence low. Do not turn a mall, school or pavilion into a regional house. Never infer a dwelling count from footprint area alone.
6. Use `semidetached` only with explicit evidence. The fallback is a simple mass, not permission to add a second entrance. Two entrances need unit/access evidence. Touching footprints retain party walls; suppress shared-wall windows and overlapping eaves.

**Assumption — geometry and colors:** all new type dimensions and exact tuples below are art choices. The JSON contains full per-floor, eave, porch, window and door ranges. Keep wall/roof planes quiet: brick, stucco and siding are **color families**, with no brick courses, clapboard grooves, shingles or tile microgeometry. Select each four-color tuple as a unit with the existing stable palette salt. Mapped wall or roof color overrides only that component; preserve provenance. Material hints can restrict a color family after the proposed addition is supported; they do not authorize authored textures. One secondary wall plane may occupy ≤25% of a facade, following v2.

**Verified local requirement, LOCAL-V2:** windows stay at least 0.45 m from corners and 0.35 m apart; fewer openings are preferable to tiny compressed windows. No window grid on every wall. Garages have 2.5–3.0 m default wall height, a 2.4–3.0 m single or 4.8–5.5 m double door only where it fits. These are visual dimensions, not construction advice. New profiles reuse the existing outbuilding shape vocabulary.

## 3. Regional architecture profiles

All mixes are **assumed priors for eligible unknown-floor houses**, before footprint filtering; the actual result will differ. They are not claims about regional housing-stock percentages. Exact existing-schema situation maps are in the JSON; equal weights in a map mean equal probability after eligibility filtering. Explicit three-floor houses use the flexible flat mass until a supported pitched multi-floor grammar exists. That is a conservative rendering fallback, not a regional architectural claim.

### 3.1 North Texas / DFW suburban draft

**Verified pattern:** nearby Russell Creek–Cross Creek describes brick exteriors, traditional houses and ranches with rear-facing garages and alleys (TX-NEIGHBORHOOD). This supports an alley-aware Plano hypothesis, not a metro-wide rear-garage percentage. **Assumption:** emphasize broad brick-color masses, moderate hipped/gabled roofs, shallow entries and restrained two-story traditional forms. No exaggerated Victorian or Tudor ornament.

**Assumption — garages/fences:** if a mapped driveway connects a rear facade to a mapped alley, select that rear face and keep the front facade free of a fake garage door. A front or side driveway beats the regional preference. A nearby service road is not sufficient: require an approach connection that does not cross another building or incompatible area. With no access evidence, leave the garage location unknown; do not create an alley or a detached garage mass. Attached-garage facades require an existing plausible wing/face and enough clear width. Wood privacy fence color is a regional art prior; rear/side continuous fences require actual boundary evidence. Keep fronts open. Proposed 1.5–1.8 m privacy panels and warm brown colors are assumptions, not a local fence-code claim.

**Assumption — Plano priority:** allow evidence-supported infill lawns and yard shade trees; restrict continuous streetside planting to adequate planting strips. Large live-oak-like spreading crowns should remain leafy without becoming pines when the leaf-habit extension is adopted. Inspect at least three target blocks with and without mapped alleys before tuning any garage frequency.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `brickRanch` | 35% | [1] | 0.35/0.65/0 | [18, 28] | [0.3, 0.5] | 25% / [0.8, 1.3] |
| `traditionalTwo` | 35% | [2] | 0.65/0.35/0 | [27, 38] | [0.3, 0.5] | 35% / [0.8, 1.3] |
| `suburbanHip` | 25% | [1, 2] | 0.2/0.8/0 | [22, 34] | [0.3, 0.5] | 25% / [0.8, 1.3] |
| `compactGable` | 5% | [1, 2] | 1/0/0 | [25, 38] | [0.3, 0.5] | 35% / [0.8, 1.3] |
| `plainFallback` | Evidence/fallback only | [1, 2, 3] | 0/0/1 | [0, 5] | [0.05, 0.15] | 15% / [0.8, 1.3] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `brickRanch` | brick / brick | #AE7962 / #E4D8C0 / #596E68 / #666460 | #C2AA87 / #E9DFC9 / #735C4E / #69696D |
| `traditionalTwo` | brick / brick | #B99474 / #E9DFC9 / #4D6668 / #60646A | #A87763 / #DFD0B8 / #73594D / #65615E |
| `suburbanHip` | brick / brick | #B6A080 / #E5DAC4 / #657569 / #62656A | #C0A68C / #E4D9C5 / #78604D / #6C655F |
| `compactGable` | brick / brick | #B08C72 / #E5D7BE / #526E70 / #64656B | #C8B797 / #E9DFC8 / #7B6150 / #62656A |
| `plainFallback` | brick | #C9C7BA / #E1DED3 / #698080 / #606A72 | #C9C7BA / #E1DED3 / #698080 / #606A72 |


### 3.2 Pacific Northwest west-side lowland suburban draft

**Verified pattern:** Portland's urban-form guide distinguishes older bungalow/foursquare neighborhoods from outer areas with Cape and ranch forms, describes planted residential front setbacks, and documents detached garages in its historic-development account (PNW-FORM). **Assumption:** this profile applies to west-of-Cascades lowland suburbs, not eastern Washington/Oregon or an entire mountain forest. Craftsman porches coexist with broad ranches, restrained two-story gables and simple contemporary infill.

**Assumption — garages/fences:** older small-house grammar may use a detached side-drive/rear garage when mapped; ranch/newer suburban grammar may use attached front/side access. These are evidence-gated options, not measured shares; the cited form source supports detached garages but does not prove a regional garage majority. Wood-color rear privacy panels and short hedges are optional only where space/boundaries support them. No blanket alley preference. Deep eaves on the Craftsman family are a proportion cue; never extend across a shared wall or path.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `craftsman` | 30% | [1, 2] | 1/0/0 | [24, 36] | [0.5, 0.75] | 80% / [1.4, 2.1] |
| `lowRanch` | 30% | [1] | 0.65/0.35/0 | [14, 25] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `gabledTwo` | 25% | [2] | 0.85/0.15/0 | [27, 40] | [0.3, 0.5] | 60% / [1.4, 2.1] |
| `contemporary` | 15% | [1, 2, 3] | 0/0/1 | [0, 5] | [0.05, 0.15] | 25% / [0.8, 1.3] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `craftsman` | siding / siding | #869780 / #E1DCCB / #987348 / #606972 | #A69E89 / #E6DDC9 / #527378 / #59636B |
| `lowRanch` | siding / siding | #A8ACA0 / #E0DECE / #70604F / #5E6666 | #A89883 / #E4DCC9 / #4F7070 / #626A71 |
| `gabledTwo` | siding / siding | #81979C / #E4DFD0 / #A07B50 / #59636D | #B3B1A1 / #E8E2D1 / #5E7670 / #61666B |
| `contemporary` | siding / siding | #C1BCAF / #E3DFD4 / #84705B / #58636A | #A6A79C / #DDDCD0 / #5A7775 / #55626A |


### 3.3 Phoenix / Mesa low-desert suburban draft

**Verified pattern:** a Phoenix historic survey documents low-gabled vernacular/ranch forms and some stucco/parapet variants (AZ-FORM); another survey discusses ranch carports and their later enclosure (AZ-GARAGE). Mesa promotes grass-to-xeriscape conversion (AZ-YARD). These sources do not establish a current metro-wide roof or gravel-yard percentage. **Assumption:** Phoenix/Mesa lowland suburbs mix low ranch, stucco hip, two-story stucco and a small flat/parapet family. Avoid making every house an adobe stereotype. Terracotta roof color suggests a material family without individual roof tiles.

**Assumption — garages/fences:** favor front/side attached garage facades only where a credible drive reaches them. Use an open carport only with mapped or approved evidence. Earth-tone masonry-color rear/side privacy walls are a tuning option with boundary evidence, not a universal property rule. Gravel beds do not mean bare lifeless yards: retain open-spreading shade trees. Palms, saguaros and desert rock landmarks are not automatic decoration.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `desertRanch` | 30% | [1] | 0.5/0.5/0 | [12, 24] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `stuccoHip` | 40% | [1, 2] | 0.35/0.65/0 | [18, 28] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `stuccoTwo` | 20% | [2] | 0.45/0.55/0 | [18, 30] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `desertModern` | 10% | [1, 2, 3] | 0/0/1 | [0, 5] | [0.05, 0.15] | 20% / [0.8, 1.3] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `desertRanch` | stucco / stucco | #CDB995 / #E7DCC6 / #78624D / #AA8165 | #C5AD94 / #E1D3BC / #5F7974 / #817C72 |
| `stuccoHip` | stucco / stucco | #CDB18F / #E9D9BD / #72604E / #B08767 | #D0BEA1 / #EADFCB / #5A7472 / #887F71 |
| `stuccoTwo` | stucco / stucco | #C7AB8A / #E6D6BA / #657872 / #A17F65 | #CFBCA2 / #E8DDCB / #81634E / #817B71 |
| `desertModern` | stucco / stucco | #C9B998 / #E5DCC8 / #62807A / #8B877B | #C1AC96 / #E7DBCA / #7C6354 / #777C78 |


### 3.4 Northeast temperate suburban draft

**Verified pattern:** the Massachusetts architecture reference distinguishes Cape, Colonial and ranch massing (NE-FORM); a Library of Congress documented postwar suburban ranch includes an attached garage (NE-GARAGE). These establish vocabulary and a garage example, not regional prevalence. **Assumption:** begin with compact Cape-like roof masses, restrained two-story Colonial-like forms and broad ranches. Split-level houses are acknowledged but need elevation/section evidence; do not manufacture half-levels from a rectangle.

**Assumption — garages/fences:** mix attached front/side garage facades with mapped detached side-drive garages. An alley is never presumed. Prefer mostly open front lawns, short wood-color fence fragments or low hedges; property enclosure needs evidence. Use cream, gray, muted blue and brick/sage tuples. No obligatory white picket boundary or oversized historical portico.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `capeLike` | 25% | [1] | 1/0/0 | [35, 45] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `colonialLike` | 35% | [2] | 0.9/0.1/0 | [28, 40] | [0.3, 0.5] | 40% / [0.8, 1.3] |
| `broadRanch` | 30% | [1] | 0.65/0.35/0 | [15, 26] | [0.3, 0.5] | 25% / [0.8, 1.3] |
| `compactGable` | 10% | [1, 2] | 1/0/0 | [27, 38] | [0.3, 0.5] | 40% / [0.8, 1.3] |
| `plainFallback` | Evidence/fallback only | [1, 2, 3] | 0/0/1 | [0, 5] | [0.05, 0.15] | 15% / [0.8, 1.3] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `capeLike` | siding / siding | #ADB0A3 / #E7E1CF / #617886 / #636B72 | #C1B8A3 / #E8DFCE / #77624D / #67686A |
| `colonialLike` | siding / siding | #C9C4AF / #E8E2D1 / #586F7C / #626972 | #A4B1B0 / #E8E3D4 / #7B5D51 / #606872 |
| `broadRanch` | brick / siding | #A48F7A / #E2D9C4 / #58746F / #666B69 | #AAB19D / #E5DFCD / #846C55 / #616A6C |
| `compactGable` | siding / siding | #91A4AB / #E6E2D4 / #6D7868 / #626B75 | #B8AA98 / #E6DECC / #647B80 / #666971 |
| `plainFallback` | siding | #C9C7BA / #E1DED3 / #698080 / #606A72 | #C9C7BA / #E1DED3 / #698080 / #606A72 |


### 3.5 Southeast inland Piedmont suburban draft

**Verified pattern:** a Georgia context study documents brick-veneer ranches and mixed exterior materials (SE-FORM). DeKalb History Center describes attached garages/carports and a local neighborhood with very limited sidewalks (SE-GARAGE). **Assumption:** this draft covers inland Piedmont suburbs around Atlanta and the Carolinas; it must not masquerade as coastal, mountain or Florida architecture. Mix brick-color ranches, porch-front traditional houses and compact cottages with newer suburban two-story forms.

**Assumption — garages/fences:** front/side attached access and evidenced carports are options; mapped access decides. Do not add rear alleys. Wood-color privacy panels may appear behind the front facade where a boundary is known. Covered porches are restrained and fit the footprint; no plantation-colonnade shorthand. Older blocks may have no sidewalks: sparse mapping alone is insufficient reason to draw a continuous sidewalk.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `brickRanch` | 35% | [1] | 0.55/0.45/0 | [15, 25] | [0.3, 0.5] | 45% / [0.8, 1.3] |
| `porchTraditional` | 30% | [2] | 0.85/0.15/0 | [26, 38] | [0.3, 0.5] | 75% / [1.4, 2.1] |
| `porchCottage` | 20% | [1, 2] | 1/0/0 | [25, 38] | [0.3, 0.5] | 70% / [1.4, 2.1] |
| `suburbanTwo` | 15% | [2] | 0.65/0.35/0 | [25, 38] | [0.3, 0.5] | 40% / [0.8, 1.3] |
| `plainFallback` | Evidence/fallback only | [1, 2, 3] | 0/0/1 | [0, 5] | [0.05, 0.15] | 15% / [0.8, 1.3] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `brickRanch` | brick / brick | #A8715E / #E8DCC6 / #5A726D / #606766 | #B09276 / #E8DDC6 / #7D6250 / #63696E |
| `porchTraditional` | siding / siding | #C8C1A7 / #EBE3D0 / #536E6C / #5D676C | #ACB49E / #E8E1CB / #7B6050 / #60696D |
| `porchCottage` | siding / siding | #94A28B / #E8DFCA / #637D81 / #606A6D | #B3A28A / #E9DCC5 / #506F70 / #696B68 |
| `suburbanTwo` | siding / siding | #B19A7C / #E7DDC5 / #576E70 / #62676B | #B5B5A2 / #EBE2CC / #886951 / #626970 |
| `plainFallback` | siding | #C9C7BA / #E1DED3 / #698080 / #606A72 | #C9C7BA / #E1DED3 / #698080 / #606A72 |


### 3.6 Generic temperate conservative regional fallback draft

**Verified local basis, LOCAL-V2 §4.5:** the existing neutral vocabulary is compact gabled 50%, broad low 25%, two-story hipped 15%, flat mass 10%. **Assumption — refinement:** retain those core proportions and tuples, reduce unsupported dressing, and require positive sidewalk/access evidence. Do not let the default inherit Denver alleys, brick dominance, mountainous scenery or a climate it does not know. It is a temperate US fallback, not a claim of accuracy in Alaska, Hawaii, desert rural areas or tropical places. Unknown region/climate should lower confidence and ornament, not force regional stereotypes.

**Assumption — family parameters:** pitches in degrees, eaves/porch depth in meters. The default number of wall floors is first in the floors list. G/H/F are gabled/hipped/flat weights.

| Family | Unknown mix | Floors | G/H/F | Pitch | Eave | Porch chance / depth |
|---|---:|---|---|---|---|---|
| `compactGabled` | 50% | [1, 2] | 1.0/0/0 | [20, 35] | [0.3, 0.5] | 30% / [0.8, 1.3] |
| `broadLow` | 25% | [1] | 0.5/0.5/0 | [12, 25] | [0.3, 0.6] | 25% / [0.8, 1.2] |
| `twoStoryHipped` | 15% | [2] | 0/1.0/0 | [22, 35] | [0.3, 0.5] | 35% / [1.2, 1.8] |
| `flatRoof` | 10% | [1, 2, 3] | 0/0/1.0 | [0, 5] | [0.05, 0.15] | 30% / [0.6, 1.0] |

**Assumption — coordinated colors**, A/B alternatives, wall / trim / door / roof. Family labels guide palette interpretation; they add no surface pattern.

| Family | Wall family A/B | Tuple A | Tuple B |
|---|---|---|---|
| `compactGabled` | neutralWall | #B5A58E / #E1D8C6 / #5A7373 / #666B70 | #B5A58E / #E1D8C6 / #5A7373 / #666B70 |
| `broadLow` | neutralWall | #9AA28E / #DDD9C8 / #82634E / #686D68 | #9AA28E / #DDD9C8 / #82634E / #686D68 |
| `twoStoryHipped` | neutralWall | #C1B298 / #E4DCCB / #637479 / #666973 | #C1B298 / #E4DCCB / #637479 / #666973 |
| `flatRoof` | neutralWall | #C9C7BA / #E1DED3 / #698080 / #606A72 | #C9C7BA / #E1DED3 / #698080 / #606A72 |

## 4. Yards, vegetation and street cross-sections

**Assumption:** percentages below are tuning shares, not landscape survey statistics. Ground shares apply only to the inferred, plantable portion of an eligible residential yard cell after all known surfaces are removed. They must never repaint mapped grass as gravel. Leaf shares sum to 100%; broadleaf evergreen includes semi-evergreen for this first draft, with retention explicit rather than assuming winter bareness. The current-compatible `deciduousShare` differs for the reason in §1.

| Profile | Lawn / bed / gravel | Broadleaf deciduous / broadleaf evergreen or semi / evergreen conifer | Crown broad / oval / spreading | Mature height m | Young share | Residential road / sidewalk width m |
|---|---|---|---|---|---|---|
| north-texas-dfw | 80% / 15% / 5% | 72% / 23% / 5% | 45% / 20% / 35% | [7, 13] | 22% | [8.5, 10.5] / [1.5, 1.8] |
| pacific-northwest | 60% / 30% / 10% | 64% / 6% / 30% | 40% / 35% / 25% | [9, 17] | 20% | [8, 10] / [1.5, 1.8] |
| desert-southwest | 15% / 15% / 70% | 48% / 50% / 2% | 15% / 20% / 65% | [5, 10] | 30% | [8, 10] / [1.5, 1.8] |
| northeast-suburbs | 75% / 20% / 5% | 83% / 2% / 15% | 50% / 30% / 20% | [9, 17] | 18% | [8, 10] / [1.5, 1.8] |
| southeast-suburbs | 75% / 20% / 5% | 65% / 15% / 20% | 45% / 25% / 30% | [9, 16] | 20% | [8, 10] / [1.5, 1.8] |
| generic-temperate-v1 | 65% / 25% / 10% | 78% / 2% / 20% | 40% / 35% / 25% | [8, 14] | 20% | [8, 10] / [1.5, 1.8] |

**Verified vegetation cues:** Plano's urban-forest report identifies elm, sugarberry and live oak as important canopy contributors and maintained turf as substantial ground cover (TX-FOREST); this does not make every yard a live-oak lot. The recommended planting list includes deciduous trees and evergreen broadleaves (TX-TREES). Mesa's tree program distinguishes palo verde/mesquite semi-evergreen behavior from deciduous desert willow and evergreen acacia (AZ-TREES). Pennsylvania red maple is deciduous (NE-TREES); UGA distinguishes broadleaf evergreens such as holly from needleleaf pine (SE-TREES). These support silhouette/season categories, not exact fractions above.

**Assumption — crown rules:** use the same three smooth broadleaf crown archetypes as v2, with 3–5 asymmetrical lobes and visible trunks; no region-specific leaf meshes. Crown archetype weights are conditional on the broadleaf branch; conifers use their existing separate silhouette. Crown diameter initially 0.45–0.65 of mature height, constrained by available space; young diameter 2–4 m. DFW leans broad/spreading; PNW includes taller conifers without filling every frontage with firs; desert leans open-spreading smaller crowns; Northeast emphasizes broad deciduous forms; Southeast mixes rounded canopy and pine forms. A mapped `leaf_type`, `leaf_cycle`, height or crown diameter wins on its own axis. Do not infer deciduous versus evergreen solely from `broadleaved`. Drought-deciduous/seasonal desert retention needs a future policy; the v1 semi-evergreen retention proxy is explicitly approximate.

**Assumption — lawn colors:** the following sRGB colors are per-profile seasonal art baselines, spring / summer / autumn / winter. Apply wetness/snow separately from the weather specification. A tan lawn is dormancy or dryness, not proof of precipitation history. New per-profile palettes are proposed additions; the current globally loaded seasonal palette cannot consume them directly.

| Profile | Seasonal lawn colors | Climate treatment |
|---|---|---|
| north-texas-dfw | #98AC77 / #91A26C / #A6A071 / #B5A581 | Warm-season winter straw; retain possible irrigated variation |
| pacific-northwest | #87A473 / #96A47B / #929B73 / #7F946F | Wet-season muted green; allow dry-summer straw blend |
| desert-southwest | #9EA777 / #A6A077 / #ABA17F / #B5A888 | Small irrigated patches only; avoid perpetual neon green |
| northeast-suburbs | #91AA77 / #8FA271 / #A1A074 / #ABA58C | Muted summer green; autumn/winter olive-tan under snow |
| southeast-suburbs | #91AA71 / #88A068 / #A4A273 / #B3A47E | Warm-season green to winter straw; do not assume all turf is the same species |
| generic-temperate-v1 | #94A67A / #95A078 / #A3A080 / #AAA68E | Neutral low-saturation palette; unknown climate remains unknown |

**Verified climate direction:** Texas A&M describes winter dormancy in warm-season bermudagrass (TX-GRASS); OSU explains that unwatered western Oregon turf can brown in summer (PNW-GRASS); UGA identifies winter dormancy of warm-season turf (SE-GRASS). **Assumption:** exact dates/colors, a PNW summer dry blend of 0.35, and universal dry tint `#B5A27D` are visual priors. Irrigation/grass species are usually unknown; do not represent the tint as a field observation.

**Assumption — widths:** the table is an inferred residential paved cross-section, not right-of-way width, zoning standards or measured street dimensions. Explicit width/lanes and mapped parallel curb/path geometry take precedence. Initial alley width, only for an already mapped alley lacking width, is 4.5–6 m; collector 10–14 m and arterial 14–22 m only after lane/direction context, never applied to every `highway` indiscriminately. Footways are 1.5–1.8 m defaults, park shared paths 2.5–3.5 m if their use is known. Tree-lawn strip 1.2–2.5 m where available; desert 0–1.8 m. Keep a too-narrow mapped gap narrow and omit a tree rather than moving a path. Curb visual rise 0.10–0.15 m, width 0.12–0.18 m, following v2; do not cross an accessible ramp or mapped crossing with a decorative curb.

## 5. Sparse-data dressing for Plano and later areas

Everything in this section is an **assumption/proposed rule** constrained by mapped-first v2 requirements. No generator implementation is supplied. Counts describe desired **total** plausible trees, including mapped equivalents, not an additional quota placed on top.

### 5.1 Candidate space and densities

Construct candidate space from mapped residential land use, house frontage, street edges and exclusions. Use parcels only when genuinely supplied. Without parcels, create a **temporary support cell**, not a cadastral lot: the near-frontage wedge of a confidently residential building, clipped at equidistance to neighboring buildings, roads, paths and other mapped surfaces. Limit its inferred depth to 8 m from the facade and to available space before the sidewalk. Label the cell inferred; never export it as property ownership. Unclassified land use yields zero yard-tree candidates. Where there is no residential polygon, corroborated repeated house tags may support a short frontage cell; a lone `building=yes` does not.

| Profile | Street-tree target spacing on eligible frontage | Yard trees per eligible residential support cell |
|---|---:|---:|
| north-texas-dfw | 18 m | 1.2 |
| pacific-northwest | 16 m | 1.4 |
| desert-southwest | 24 m | 0.9 |
| northeast-suburbs | 18 m | 1.5 |
| southeast-suburbs | 20 m | 1.6 |
| generic-temperate-v1 | 24 m | 0.5 |

With parcel evidence, sample `floor(density)` plus one Bernoulli draw for the fractional remainder, capped at three total yard trees. Without parcel evidence cap at **one total inferred-or-mapped yard tree per support cell**; empty small cells get none. For street trees, target count is eligible frontage length / spacing, stochastically rounded; subtract mapped trees assigned to that frontage before accepting new candidates. Use deterministic ±15% spacing variation. A mapped yard tree near the curb can satisfy both frontage appearance and yard coverage; do not count it twice when allocating additions. Global candidate arbitration deduplicates overlapping categories.

Commercial frontage uses half the residential street-tree density, industrial one-quarter, only in known plantable strips; no invented parking islands or residential lawns. Park **open interiors, sports pitches and playground surfaces get zero generated trees**. Corroborated non-sports park-edge vegetation may use up to 15 trees/hectare in a 10 m edge band, with a 6 m minimum spacing, after subtracting mapped trees. Mapped woodland may use 60 trees/hectare as a sparse, budgeted representation, not a botanical density claim; grass is not woodland. Agricultural/unknown/water/parking surfaces get no automatic residential dressing.

**Plano count interpretation:** if all 1,157 footprints were eligible homes, which is not established, a no-parcel one-tree ceiling would be at most 1,157 total support-cell trees before subtracting mapped equivalents and conflict rejection. Do not subtract all 74 mapped trees indiscriminately: some may belong to the park. Do not use this ceiling as a target or multiply 1,157 by an assumed lot area. Street-tree totals require actual eligible frontage length; park totals require actual area/land-cover exclusions.

### 5.2 Placement and mapped-data precedence

Freeze all mapped positions before inference. Exclude building polygons plus 3 m for tree trunks; path edges plus 1 m; curb plus 0.75 m; drives/crossings plus 2 m; intersection corner zones within 8 m; water, pitches, parking and known utility corridors entirely. These conservative clearances are visual assumptions, not arboricultural or legal setback standards. Use full crown volumes when rejecting facade/roof conflicts; modest crown overhang above an open walk is allowed if trunk clearance remains. If a mapped tree conflicts, retain its exact position and flag the conflict; never silently move it or falsify a mapped crown/height. An inferred candidate can be shrunk within its allowed size range or rejected, never push an observed feature aside.

Mapped trees are always retained and credited against nearby density. Reject an inferred trunk within `max(4 m, 0.6 × sum of crown radii)` of another accepted trunk. Existing conflicts among mapped trees stay visible in diagnostics. For all candidate classes, use stable priority ranks rather than whichever tile or house happened to generate first. Do not retry indefinitely until a quota is full: use at most eight candidate slots per parent and accept that real constrained space may remain empty.

**Lawns:** only fill eligible residual ground polygons; carve out every known building, water body, road, footway, drive, pitch, parking area and mapped land-cover patch. No uniform green rectangle per building. Use a broad material mask and sparse v2 edge tufts. In desert areas, gravel is a single calm color/noise field, not millions of pebbles. In Plano, no invented sportsfield trees or garden paths. An unmapped lawn/bed boundary is inferred decorative coverage, not a geographic fact.

**Fences:** mapped lines first, with original coordinates. A known parcel/boundary may support an inferred rear/side panel if entrances and mapped paths stay open. Without boundary evidence, omit continuous privacy fences even when the regional style sheet shows them. At most one short 1–3 m entry-adjacent decorative segment where clear, with provenance; this does not establish ownership. No fence across an inferred support-cell bisector. Garage door approaches always remain unobstructed.

### 5.3 Sidewalk inference without false routing

Priority is a separately mapped sidewalk/path → explicit side-specific sidewalk tags → approved local context → absence/unknown. `sidewalk=none/no` or the side-specific equivalent forbids generation. `sidewalk=separate` means look for the mapped path, not add a second one. Resolve side-specific tags before a general `both` value; inconsistent inputs are flagged.

1. Associate nearby mapped sidewalks by side of road, parallel direction and continuous coverage; suppress inferred duplicates in a 3 m matching corridor. Simple proximity is insufficient at intersections or a parallel park trail.
2. For a positive sidewalk tag with missing geometry, propose an offset from the existing road edge with inferred width. Never move the road centerline to fit it.
3. For untagged Plano residential blocks, a connected mapped sidewalk run or approved public-area context may justify continuation. A gap no longer than 30 m may be filled where endpoints, side and grade are plausible. Longer continuous unknown runs require area review; the nearby neighborhood article alone does not establish every target block.
4. PNW/desert new-subdivision templates still need corroboration. Northeast/Southeast untagged older blocks default to no generated path until positive or connected-run evidence exists. Generic default requires positive evidence. Do not invent a safe crossing, curb ramp or accessibility claim at an intersection.
5. Mark generated geometry `origin=inferred`, `navigationUseAllowed=false`. It may visually support a recap but never supply a routing edge or move a recorded route onto it. If no room exists, omit and flag the gap.

### 5.4 Stable identities, seeds and provenance

Use existing `OSMRef.random(salt)` / `StableRandom`, never process-dependent hashes or unseeded randomness (verified repository rule). A proposed synthetic ID is `inferred:<parent-kind>:<parent-id>:<rule-id>:<canonical-side>:<slot>`. Parent may be a building, road or land-cover OSM reference. Canonicalize polygon winding/start vertex and road orientation before assigning sides; preserve historical source IDs where possible. Candidate slots are fixed in parent-local metric space; increasing density selects more existing ranked candidates rather than moving them. If an OSM way is split/replaced, explicitly accept an identity migration unless an approved lineage map exists.

Use separate salts for type, tuple, roof, crown, ground coverage and each dressing category. Keep profile/version metadata but do not put every profile version into every random salt: a palette revision should not reshuffle roofs and trees. Bump an explicit rule-seed version only for an intentional reroll. Sort candidates by stable ID/rank before collision arbitration; tile order, thread scheduling, camera and device must not affect placement. Evaluate candidates in neighboring tile halos, but emit each from one canonical owner tile. Source changes may legitimately suppress an inferred object; never preserve it by moving a mapped object.

Store origin, parent/source references, dataset timestamp, profile ID/version, rule ID, rule-seed version, confidence and resolved parameters with each inferred output in world-package scene metadata. Keep OSM namespace distinct: fabricated negative or ordinary OSM IDs are not acceptable. Offer an inferred-layer diagnostic toggle and report accepted/rejected counts by reason. Rendering LOD can reduce detail but must not change provenance or move positions.

## 6. Data-defined region selection and borders

**Verified current behavior, LOCAL-SCHEMA:** catalog boxes are ordered, first match wins, with `defaultProfile` outside every box. **Assumption:** the draft catalog keeps Front Range first, then a small Plano review vicinity before the broader DFW box, followed by west-side PNW lowland, Phoenix/Mesa and selected Northeast/Piedmont metro boxes. The boxes are **provisional review extents**, not state, climate, city or architecture boundaries. A suburban profile applies only after building-use context; a metro box never converts downtown apartments to suburban houses.

Use a stable representative point for each source feature (polygon interior point/centroid policy fixed by version, point coordinate for trees). Do not select from the moving camera or a changing bake center. A street segment crossing a border may be cut for inferred dressing ownership only; keep the original mapped centerline. If current packaging resolves one profile for a whole area, per-feature selection is a proposed integration change, not magically enabled by the catalog.

For initial compatibility, categorical selection uses the existing first-match rule and no blending. For a future polygon selector, include priority, geometry, optional elevation/land-use applicability, and versioned coverage confidence. The draft intentionally does not claim all of the US is covered. Rural areas, unmatched metros and ambiguous climate use the conservative generic profile. Mountainous parts of a coarse metro box need explicit exclusion/override before activation.

Optional proposed border policy: within 1 km of an adjacent **approved** profile boundary, blend only continuous ground/foliage palette and density parameters by smoothstep of signed distance. Pick architecture/roof/leaf habit categorically with a stable feature seed using the same weights; never morph a roof as the camera moves. Never blend in an uncovered neighbor or over a water/coast exclusion. All outputs record the contributing profile versions and weight. Prefer a reviewed neighborhood override to a long blurred transition through incompatible climates.

## 7. Proposed additions, separate from compatible profiles

The JSON `proposedAdditions` is a review specification only. No current decoder behavior is claimed for it.

| Proposed field group | Purpose | Compatibility/fallback |
|---|---|---|
| `leafHabitWeights`, retention, crown semantics | Separate broadleaf/conifer form from deciduous/evergreen cycle | Current `deciduousShare` retains approximate silhouette only; do not ship it as accurate winter Texas/desert behavior |
| `materialFamilyByType` | Parallel family labels for each existing color tuple | Existing tuples still render; validate array lengths; material facts win |
| Garage access/attached facade rules | Allow region preferences only after mapped access and geometry | Existing garage orientation is generic code; the data alone does not add attached garage doors |
| Ground cover weights, seasonal lawn colors, fence family | Climate-sensitive inferred yard treatment | Existing global palette remains unchanged until future support |
| Densities, exclusions, provenance, no-navigation flag | Deterministic optional missing-data dressing | No current support asserted; do not fabricate OSM features to bypass this |
| Polygon regions, per-feature selection and borders | Prevent broad boxes and camera motion from recoloring areas | Ordered boxes remain the compatible path |

**Assumption — implementation order:** leaf-form/cycle separation and evidence-based role/access classification come before a full procedural-yard system. Region names must remain in data. Required generic algorithms may be added later by the coding agent under separate authorization; no place-name switch statements are needed.

## 8. Performance envelope and validation gates

**Verified local targets, LOCAL-V2 §8.1:** main triangles ≤400,000 (about 290,000 current plan target), shadow triangles ≤150,000, main draws ≤100, 60 fps and ≤10 ms GPU on iPhone 13 class. The 35,000-triangle richness reservation is **inside** the 400,000 ceiling. No extra regional budget is created. These are acceptance targets, not measurements of this proposal.

**Assumption — resource rules:** every regional profile reuses the same house mesh grammar, three broadleaf crown families, conifer family, garage/shed vocabulary and palette-driven materials. No new material draw per color or per house. Brick/stucco/siding add neither texture samples nor passes. Trees and fence panels use spatially bounded batches; instancing does not eliminate triangle or overdraw cost. Attached garages add a facade opening only when support exists, not an extra unseen interior or extra building footprint.

| Existing GPU bucket | Regional charge | Allowance ms |
|---|---|---:|
| Base opaque world/character | Regional house masses, inferred tree trunks/crowns, broad fence panels, lawns/sidewalks, existing fog | 4.25 |
| Sun/contact shadows | Nearby trees, architecture and fence casters inside bounded shadow region | 1.45 |
| Vertex AO/fill/crown shaping | Same scalar AO and crown shaping across every profile | 0.15 |
| Surface patterns | Broad lawn/gravel variation, sidewalk joints; shared with snow masks | 0.25 |
| Near geometry | Existing bevels, bounded leaves/tufts; no regional extra allowance | 0.35 |
| Wet surface/local lights | Existing weather effects only | 0.35 |
| Weather particles | Existing weather allocation, no regional particle vegetation | 0.20 |
| Post processing | Existing grade/bloom/aerial blur | 0.90 |
| Reserved headroom | Remains reserved, not spent on inferred trees | 2.10 |
| Total | Same ceiling | 10.00 |

**Assumption — illustrative caps, not benchmark results:** an ordinary near house should target 500–1,200 triangles including restrained facade details; a near crown/trunk 300–600, mid 100–200, far 24–60. Use existing smooth normals and fewer lobes in distant LOD. A 1,157-building whole-area view at 80 triangles/building would cost about 92,560 triangles; 1,200 visible far trees at 48 each add 57,600. Those 150,160 triangles are only those two categories, not the total scene. At 1,000 triangles/building the same view would already exceed the ceiling; full-detail aerial rendering is prohibited. Do not force the world to contain exactly 1,200 trees because of this example.

Use full near architecture at 0–50 m, simplify microdetail after 50 m, retain family identity to 150 m, roof/body/crown masses at 150–600 m and silhouettes beyond. Aerial uses projected-size LOD and culling, including shadow LOD. Keep mapped trees represented; when crowded, reduce their LOD first and reduce optional inferred detail/density subsets using stable ranks. Do not remove mapped features to afford speculative fences. Profiles keep identical budget policy; lush regions cannot borrow safety margin.

Before activation, test: (1) data-only profile swap with identical source geometry; (2) explicit OSM tag wins including fractional floors and unsupported roof forms; (3) no eligible type fallback preserves mapped mass; (4) Plano mapped front-drive and rear-alley examples; (5) unchanged mapped positions and mapped-only view; (6) stable dressing after tile-order/device changes; (7) no trees in pitches/water/drives, no duplicated sidewalks; (8) all four seasons including Texas live oak and desert semi-evergreen; (9) border traversal and offline reload; (10) ten-minute street/aerial device run with triangles, draws, GPU worst/p95 and thermal state. Schema/data consistency can be checked now; renderer/device performance cannot be verified by a proposal.

## 9. Style sheets and image review

All images are illustrative assumptions: fresh built-in image generation, with no more than one edit pass per image. The v2 image 07 is a visual reference, not a map or asset to be placed on houses. Six vignettes per sheet show typical masses, a garage/access example and yard/fence treatment on a neutral background without text. The generic sheet is included as a fallback comparison. Prompts and pass counts are recorded in `images/image-generation-record.json`.

- [North Texas / DFW style sheet](images/01-north-texas-dfw.png)
- [Pacific Northwest style sheet](images/02-pacific-northwest.png)
- [Desert Southwest style sheet](images/03-desert-southwest.png)
- [Northeast suburbs style sheet](images/04-northeast-suburbs.png)
- [Southeast suburbs style sheet](images/05-southeast-suburbs.png)
- [Generic default style sheet](images/06-generic-default.png)

The sheets do not establish counts or placement: fences depict an evidenced-boundary scenario, and attached garages depict supported wings/access. The North Texas lower-center panel is a **rear-garage approach detail**; it must not be copied onto a home's front facade. Concept foliage and color are not species identification. Specific residual exceptions after the permitted edit: faint surface lines remain in parts of the North Texas/Southeast sheets; the PNW porch piers retain some masonry detail; the Southeast lower-center panel reads as a detached side-drive garage rather than the intended side-entry door; several house views are shallow three-quarter and several trees are larger than the conservative kit target. These are concept-image limitations, not requirements. Any residual fine surface lines, decorative railings, overly tall trees or facade shading remain image artifacts; the calm-plane and budget rules above govern implementation. No textures are to be extracted from these images.

## 10. Source register

Sources were checked on **2026-10-05**. Local paths are relative to the repository root; links below resolve from this proposal. Web references support only the qualitative statements explicitly attributed to them; numeric tuning remains assumption. Large PDF sources with indexed excerpts are not claimed to have been reviewed page by page. No commercial neighborhood source is used as technical evidence of OSM coverage or code behavior.

- **LOCAL-SCHEMA — Verified source:** [Current Codable schema, not older guide](../../../Sources/WorldGen/StyleProfile.swift). Checked 2026-10-05.
- **LOCAL-GENERATOR — Verified source:** [Eligibility, role classification and garage access behavior](../../../Sources/WorldGen/BuildingGenerator.swift). Checked 2026-10-05.
- **LOCAL-TREES — Verified source:** [Current leaf_type/conifer classification](../../../Sources/WorldGen/SceneGenerator.swift). Checked 2026-10-05.
- **LOCAL-V2 — Verified source:** [Binding visual grammar and budgets](../../../docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md). Checked 2026-10-05.
- **LOCAL-OSM — Verified source:** [Denver inventory only; no Plano extract found](../../../docs/data/sloans-lake-street-data.md). Checked 2026-10-05.
- **TX-NEIGHBORHOOD — Verified source:** [Secondary nearby-area account: brick, ranch/traditional, rear garages; NOT a survey of Russell Creek Park blocks](https://www.homes.com/local-guide/plano-tx/russell-creek-cross-creek-neighborhood/). Checked 2026-10-05.
- **TX-PARK — Verified source:** [City Russell Creek Park location map](https://content.civicplus.com/api/assets/d5718a52-3f89-47c2-bcf9-0c0ff33c7ecd?q=307e4d73-1917-23a0-9f2d-3acce03bf19e&version=0). Checked 2026-10-05.
- **TX-FOREST — Verified source:** [City urban forest: elm, sugarberry, live oak and maintained turf](https://www.planotomorrow.org/DocumentCenter/View/851). Checked 2026-10-05.
- **TX-TREES — Verified source:** [Plano recommended tree list; suitability is not prevalence](https://content.civicplus.com/api/assets/d3c00b34-7fcc-4726-9bdf-b3901645f1de). Checked 2026-10-05.
- **TX-GRASS — Verified source:** [Warm-season lawn winter dormancy](https://agrilifeextension.tamu.edu/wp-content/uploads/2023/08/ESC-042-bermudagrass-lawn-management-calendar.pdf). Checked 2026-10-05.
- **PNW-FORM — Verified source:** [Portland residential forms, green front setbacks; indexed source excerpt](https://www.portland.gov/sites/default/files/2020-01/urb_form_complete_web_1009.pdf). Checked 2026-10-05.
- **PNW-TREES — Verified source:** [Leaf form and leaf cycle are separate tree classifications](https://www.portland.gov/trees/get-involved/documents/citywide-street-tree-inventory-report-2017/download). Checked 2026-10-05.
- **PNW-GRASS — Verified source:** [Unwatered western Oregon lawn can brown in summer](https://extension.oregonstate.edu/catalog/em-9125-conserving-water-your-yard-garden). Checked 2026-10-05.
- **AZ-FORM — Verified source:** [2005 local survey supports low-gabled ranch/vernacular and some stucco/parapet; not a metro frequency census](https://www.phoenix.gov/pddsite/Documents/HP/pdd_hp_pdf_00211.pdf). Checked 2026-10-05.
- **AZ-GARAGE — Verified source:** [Historic Phoenix ranch carports and later enclosure](https://www.phoenix.gov/pddsite/Documents/HP/Avenida%20Rio%20Salado%20Historic%20Structures%20%26%20Districts%20including%20inventory%20forms%20%282010%29.pdf). Checked 2026-10-05.
- **AZ-YARD — Verified source:** [Mesa grass-to-xeriscape incentive; not measured yard prevalence](https://apps.mesaaz.gov/xeriscape/). Checked 2026-10-05.
- **AZ-TREES — Verified source:** [Palo verde, mesquite, desert willow, broadleaf evergreen and seasonal behavior](https://www.mesaaz.gov/Environment-Sustainability/Living-Green/All-About-Trees/Mesa-Neighborhood-Shade-Tree-Program). Checked 2026-10-05.
- **NE-FORM — Verified source:** [Cape/Colonial/ranch form vocabulary, not frequency](https://www.mass.gov/info-details/re14r25-architecture). Checked 2026-10-05.
- **NE-GARAGE — Verified source:** [Documented postwar suburban ranch with attached garage; example not prevalence](https://www.loc.gov/item/md1761/). Checked 2026-10-05.
- **NE-TREES — Verified source:** [Deciduous red maple seasonal behavior](https://extension.psu.edu/native-plants-of-pa-red-maple-acer-rubrum). Checked 2026-10-05.
- **SE-FORM — Verified source:** [Georgia ranch survey: brick veneer, picture windows, mixed materials](https://dlg.usg.edu/record/dlg_ggpd_s-ga-bt700-pe5-bm1-b2010-bl6-belec-p-btext). Checked 2026-10-05.
- **SE-GARAGE — Verified source:** [Local ranch features include attached garage/carport; some neighborhoods lack most sidewalks](https://dekalbhistory.org/blog-posts/the-ranch-house-in-dekalb-county-belvedere-park/). Checked 2026-10-05.
- **SE-TREES — Verified source:** [Broadleaf evergreen and pine distinction](https://extension.uga.edu/publications/detail.html?number=B987&title=native-plants-for-georgia-part-i-trees-shrubs-and-woody-vines). Checked 2026-10-05.
- **SE-GRASS — Verified source:** [Warm-season turf winter dormancy](https://extension.uga.edu/publications/detail.cfm?number=B978). Checked 2026-10-05.

## 11. Open questions and five recommendations

Open questions: obtain the exact Plano extract and classify residential use/access confidence; establish target-block rear/front garage proportions from public mapped evidence; choose whether the first release supports broadleaf evergreen cycles; decide who supplies reviewed region polygons and parcel/boundary data; and measure whether inferred vegetation fits the existing renderer budget. The exact current neighborhood age mix and actual lawn irrigation are unknown. No regional draft is asserted to be nationally representative.

1. **Ship Plano's evidence-gated roof, color and house mix first.** Rear-entry garages matter, but mapped access must decide each facade; do not infer an alley from the regional label.
2. **Separate leaf form from leaf cycle before regional winter rendering.** Live oaks, magnolias and semi-evergreen desert trees must not become conifers or automatic bare winter trees.
3. **Keep schema additions explicit.** Current-compatible house data is ready for review; yards, fences, attached garages, local lawn palettes and per-feature selection need deliberate generic support.
4. **Fill sparse data conservatively and label every inference.** No invented parcel boundaries, unsafe routing sidewalks or trees across sports fields; preserve every mapped coordinate.
5. **Use reviewed local coverage and the existing performance ceiling.** Start with metro review extents, generic fallback elsewhere, and the same triangle/draw/GPU gates across profiles.
