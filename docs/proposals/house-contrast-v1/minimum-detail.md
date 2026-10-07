# Minimum house detail that reads at phone distance

Design proposal • iOS 26.0 minimum • one-page guide

Ranked by expected visual impact per implementation cost; qualitative estimates, not device measurements. Judge the complete unchanged view at actual phone display size, without zoom. Pixel targets below are display pixels at that review size, not meters or an instruction to enlarge footprints.

| Rank | Detail and minimum readable treatment | Cost | Purpose |
|---|---|---|---|
| 1 | Separate wall, light trim, dark glass and roof into four coherent value groups; use the supplied house-type swatches. | Very low: shared material assignments | Makes openings and material identity survive downsampling. |
| 2 | Continuous dark soffit plus eave/cornice shadow band, approximately 2–4 visible pixels on nearby houses; keep fascia distinct. | Low: existing face colors, or narrow merged strip | Gives the roof a supported edge and the facade depth. |
| 3 | Preserve two or three stacked window rows on flats; regular tall openings, with trim visibly framing dark glass at roughly 1–2 pixels nearby. | Low: grouped facade faces | The three-row rhythm is the primary three-flat cue; do not infer storeys solely from palette. |
| 4 | Porch roof: light top/fascia, dark underside and clear horizontal contact line; retain a readable recessed entry. | Low: face assignment and existing porch geometry | Prevents the porch becoming a wall-colored lump. |
| 5 | Type-specific roof silhouette: three-flat flat/parapet with cornice; two-flat follows source roof; cottage narrow gable; bungalow broad low hip and deep eaves. | Medium: reusable roof variants | Establishes identity before ornament. Preserve footprint, height and source roof where known. |
| 6 | One coherent projecting bay, where supported: lit front and darker side returns, with windows stacked through storeys. | Medium: reusable merged geometry | Strong depth and residential character; a painted rectangle cannot substitute for projection. |
| 7 | Cornice as a broad cap with dark lower reveal; one readable profile step. | Low–medium: strip/profile | Gives brick flats their upper termination without tiny brackets. |
| 8 | Distinguish brick from siding by broad value/color and edge treatment; siding lighter in this exemplar. | Very low: palette; optional sparse courses | Material separation matters more than individual bricks. Real observed colors override this exemplar. |
| 9 | Simple stoop/entry recess and bungalow porch supports, only when visible. | Medium: a few merged solids | Anchors entrance and scale. Retain negative space beneath roofs. |
| 10 | Sills or a single broad lintel band. Skip brick grids, thin muntins, dentils and siding grooves that shimmer or vanish. | Low per detail; cumulative cost | Finish only after the main silhouette and value hierarchy pass. |

**Type check:** three-flat = three stacked opening rows + tall brick mass + cornice; two-flat = two rows + entry/porch rhythm; cottage = narrow gable + low body + porch; bungalow = broad low roof + deep eave + substantial porch. Use source-supported features; do not turn every building into every type.

**Acceptance:** compare source and paint-over full frame and in grayscale at phone size. Roof edge, opening rhythm and porch underside must remain visible. Retain camera, lighting, trees, street and all non-house content. Fade details smoothly when they project below about one display pixel; retain broad bands and type silhouettes. Merge opaque detail into existing chunks/material families; cost rankings require later device profiling. No real house numbers, logos or people.
