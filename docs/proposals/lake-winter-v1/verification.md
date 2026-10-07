# Verification — lake + winter v1

7 October 2026

Passed 178 file, arithmetic, bounds and reference assertions. These are structural/data checks, not renderer or device performance tests.

- Six final PNG posters decoded successfully; selected artwork visually inspected after corrections.
- JSON parses;31 unique material states and35 panel references resolve. Every scalar darkening multiplier and sRGB output was recomputed in linear light. Fresh-snow comparison luminance deltas recomputed independently.
- Both exact SVG charts parse as XML; authored reference palette and swatch values come from JSON arithmetic.
- Four summary scene crop boxes fit the1024×1536 source; review page local links exist. PNGs were copied intact; CSS crops do not alter bitmaps.
- Prompts include initial generation, all six first corrections and two second targeted edits. SHA256 hashes and image dimensions recorded in image-manifest.json; manifest excludes itself and this later verification file.
- Reference rain-v1 files were read only. No git or production engine edits. All delivered files are in the single requested folder.

Unrun: browser visual preview, actual390/320px device render, calibrated cameras, animated wave/shedding transitions, production JSON loader compatibility, shader/tonemapper parity, measured GPU timings and thermal tests. Poster distances, coverage and material appearance are authored targets, not reconstructed numerical output.

Known art limits: some residual canopy/snow surface grain, branch detail, geometric-looking reflection silhouettes and illustrative snow cap/bank thickness survive generation. The lake masks are conceptual; the same street is preserved in composition rather than surveyed pixel-identical geometry. Exact JSON/flat SVG swatches govern adoption. The second tree edit establishes visible shedding; the second old-snow edit adds the dark basal band and fixes the0.30m bank/0.45m pile caption.
