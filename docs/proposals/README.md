# WorldEngine visual proposals

**Current: [Visual Proposal v2](visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md)** — 5 October 2026. Art-direction proposals for review; the coding agent owns the implementation and final specification.

| Folder | Contents | Status |
|---|---|---|
| [visual-v2](visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) | Complete updated spec; nine target PNGs; richness parameters; Baseline/Target/Stretch ladder; iOS 26 effects; numeric camera/light fixtures; 10 ms allocation; ten-criterion rubric; image limitations and data provenance | **Current proposal / M1 Target** |
| [visual-v1](visual-v1/WorldEngine-Visual-Spec-Proposal-v1.md) | Original v1 spec and five cleaned concept PNGs, unchanged | Historical proposal / minimum visual Baseline |
| [visual-v1/images-original](visual-v1/images-original/README.md) | Six recovered original-resolution drafts: richer autumn, winter, rain, aerial, house sheet, plus faceted low-poly variant; checksums and provenance | Historical references, preserved byte-for-byte, not regenerated |

## V2 images

[01 Hero](visual-v2/images/01-autumn-golden-hour.png) · [02 Winter](visual-v2/images/02-winter-morning.png) · [03 Rain](visual-v2/images/03-rainy-dusk.png) · [04 Noon](visual-v2/images/04-summer-noon.png) · [05 Night](visual-v2/images/05-clear-night.png) · **[06 Aerial](visual-v2/images/06-aerial-golden-hour.png)** · [07 Houses + rear alley](visual-v2/images/07-house-style-sheet.png) · [08 Dog coats](visual-v2/images/08-dog-readability.png) · [09 Data-grounded street](visual-v2/images/09-data-grounded-street.png).

## Supporting review files

[Camera/light presets](visual-v2/comparison-presets.json), [local data observations](visual-v2/data-grounding.json), [image manifest](visual-v2/image-manifest.json), [complete prompt record](visual-v2/IMAGE-PROMPTS.md).

The PNGs are illustrative rather than measured geometry or render benchmarks. V2 images are native 1672 × 941 despite the highest-resolution request; not upscaled. The spec lists remaining camera/shadow/style deviations. Numeric presets, actual map data and device measurements outrank the art. The steep aerial correctly omits a horizon; the western mountains are outside that camera’s frustum.

**[Download the complete visual-review ZIP](visual-v2/WorldEngine-Visual-Review-v1-v2.zip)** — both proposals, all original/clean/target images, provenance, map and inventory reference. No implementation files.
[Engine-choice review](engine-choice/ENGINE-CHOICE-REVIEW.md) — 5 October 2026. Weighted engine comparison, dated sources, shared world format and bounded decision experiments.
