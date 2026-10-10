# Image review and delivery limits

All23 selected generated sheets were visually inspected through the built-in image tool output. Four initial issues received targeted edits: retail building removed from parking-02; parking-03 entrance kerb opened; baseball-02 connected dirt infield replaced with isolated clay patches; bridge-04 false upper-deck crossing lines removed. Bridge01–03 were simplified away from photographic ground noise. Baseball bottom panels received top-view edits; they still have slight perspective, so16 orthographic SVG schematic plans are supplied separately. Original tool images were retained outside the repo; selected hashes are in image-manifest.json.

| Scope | Present | Limit to preserve |
|---|---|---|
| Parking01–04 | All3 views; distinct size/layout/material; kerbs/islands/markings; retail poles/corrals; worn stripes | parking01 island placement/entrance count and retail row count vary between views; rebuild from spec and mapped access, never trace AI pixels. |
| Soccer01–02 | Grass versus synthetic, two goals, field lines, separate apron treatment;3 views | Intended camera/HEX/scale approximate; runoff proportions not a measurement. |
| Baseball01–02 | Grass/dirt versus synthetic/isolated clay;3 views plus true orthographic schematic SVGs | Bottom AI view still not fully vertical; dirt art01 has grass interior rather than solid dirt; fences/trees are optional illustration context, not inferred source data. Site envelopes corrected in specs to145×115 and135×110 to fit the radii. |
| Court01–02 | Twin tennis / single basketball;3 views; distinct palettes and parts | This treats “tennis/basketball court” as one type with two looks; tennis art includes a fence, only build if mapped. |
| Track01–02 | Red synthetic six-lane proposal / cinder four-lane proposal;3 views | AI line count is not certified to equal lane count; generate offsets from specs/data. Worn look uses illustration texture, engine surfacePolicy still excludes added grain. |
| Playground01–04 | Four different pad layouts/materials/equipment compositions;3 views | Some equipment silhouettes/posts drift between panels. Planting/equipment placements are illustrative, not surveyed or safety-certified. |
| Bridge01–04 | Concrete creek/rail truss/pedestrian/highway;2 views; readable decks and side rails | AI truss bays differ from8-bay spec; local bank planting remains illustrative; no actual measured deck heights. |
| Station01–03 | Brick+canopy/open shelters/hip depot;2 views | AI adds lamps/chimneys/trim, which are optional only with evidence; no certified platform dimensions or camera height. |

No readable labels, place names, logos, signs, people or animals were observed in selected art. Region labels remain outside images in the index. Matte muted warm look is intent; no pixel colour equality, native/web render comparison, score gain, structural conformance or device-budget pass is claimed. No engine/default/export changed. New recipes await R approval.

Generation reproducibility: prompts contain the final intended recipe; image-manifest preserves revision text. Initial baseball prompts used smaller site boxes before the geometry correction. All generated cameras/HEX values are approximate; rerunning a prompt is not byte-deterministic. SHA-256 identifies delivered bytes, not a promised regeneration hash.
