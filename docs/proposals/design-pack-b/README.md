# Design pack B — storefronts

10 October 2026 · A12 · proposed design input, pending R approval · 27 fictional variants.

[Specification rows](specs.md) · [Build contract](build-spec.md) · [Every pair: sameness check](sameness-check.md) · [Machine-readable variants](variants.json) · [Gallery](index.html) · [Evidence and limitations](evidence.md).

Eight restaurant/bar variants, six cafe/ice-cream/pizza variants, four barber/salon/service variants, five grocery/convenience/fuel variants and four retail strips. Each has one two-view sheet: street view requested at 40 m and aerial at 150 m, both 45° to frontage; aerial elevation 45°. Images are illustrations, not camera-calibrated geometry or measurements. The JSON and build contract control dimensions and material assignments.

All 351 pairs are listed; the 65 pairs within a type pass the authored variation requirement: ≥3 differences among width, height/levels, roof/parapet, wall material, colour family and awning/entrance; no pair shares both silhouette and colour family. Cross-type comparisons are included for completeness and are informational. Commonness scores are guesses within the region, not occurrence counts or automatic weights. Regions are palette associations, not architectural identity inferred from location. Dimensions are illustrative defaults; actual mapped footprint, levels, roof and evidence-backed material always prevail.

This pack supplies form/frontage alternatives under existing registry IDs; it does not change classifier logic, engine code or public-map facts. Type selection requires a supported use tag and a known occupied frontage. Width or colour alone cannot establish restaurant, salon or fuel use. A business point with unresolved host stays fallback P; ambiguous whole-building assignment stays neutral B. Cuisine never selects a cultural architecture. Converted-house and garage variants require explicit form/reuse evidence. Rooftop decks, patios, fuel roofs and lots require mapped geometry or a confirmed private project input; they are never invented from the use tag.

## Reference look

Use `style-b-calibration-v2/sharedLook` for simplified matte material response, dark restrained glazing and warm muted albedos. Inspected calibration frames: `06-sloans.png`, `01-lakeview.png`. Facade-detail-v2 panels are used only for structural detail density, selective trim/recesses and unchanged near/far albedo. Its building type is not copied. Surface texture/noise is omitted; images may imperfectly depict the prompt.

User-requested clear afternoon west light uses azimuth **270°**, elevation **40°** for these design sheets. This is an explicit illustration-fixture deviation from the calibration's 225° southwest azimuth; no shared engine lighting value changes. Do not import illustrations' brightness or shadows into materials. No regional exposure/saturation override. No readable text, businesses, logos, signs, branded canopy shapes or barber poles; accents are plain colour blocks and simple awnings. No people/vehicles/animals are required.

## Registry mapping

Existing specification archetypes: `shopfront` (07), `grocery` (08), `neighborhood-bar` (09), `food-cafe` (10), `fuel-station` (40); mixed use composes `apartments` (04) with known shopfront occupancy. Explicit conversions preserve `detached-house` (02) or `garage` (05) form. These are registry-spec IDs, not a claim that every module ships.

Proposed extensions are flagged per row: ice-cream use under food-cafe; convenience use under grocery; hairdresser/beauty/service frontage under shopfront; new `walkup-kiosk`, `small-service-frontage`, `retail-strip-mass` geometry modules. None creates a new auto-classifier without owner approval and supported tag/host tests. For the bar R01/R06 choices, current restaurant versus bar tag chooses semantic use; shape does not. No named landmarks.

## Delivery and use

Images stay local under `images/` per repository policy; tracked prompts/specs/manifests keep the pack reproducible. A fresh clone must regenerate or obtain those image files; the README does not imply images are on GitHub. Every variant's exact image-generation prompt is in `prompts/<ID>.txt`. [Per-sheet visual review](visual-review.md), [image manifest](manifest.json) and [validation](validation.json) record drift and integrity checks. The gallery identifies each illustration and links its spec; do not measure the pixels. Approval, runtime implementation and score/budget acceptance are separate later steps. No look-score gain or performance result is claimed.
