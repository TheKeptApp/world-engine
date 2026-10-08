# A2 web look bake-off

Two isolated pages use `web/src/world.js` and the existing world package format. No production viewer files are modified.

## Preview and reproduce

Run from the repository root, with the existing `web/node_modules/three` and compiled `worldbake` available:

```sh
HEAVY_AGENT='Astra A2' scripts/heavy.sh 'A2 export' bash web/bakeoff/export.sh
node web/bakeoff/serve.mjs
```

Open http://127.0.0.1:8782/. In an isolated checkout, set `WORLDENGINE_ASSETS` to the owner's repository for the existing Sloan export, reference packs and three.js dependency. All new exports are in this folder's ignored `generated/` directory. The server is loopback-only and rejects paths escaping its mounts.

`capture.mjs` runs installed, headed Chrome on this laptop (Playwright package path can be set with `PLAYWRIGHT_ROOT`). Run captures under the shared heavy lock. `SCENES` and `MODES` can restrict diagnosis to one scene or baseline/candidate. The matched-camera baseline uses the existing viewer's materials, lighting and post-processing; its summer palette is shared and its environment uses the export’s noon state when present, otherwise its default state, so it is not the historical iOS afternoon baseline. `?capture&still` fixes candidate animation time for reproducible screenshots. The capture runner measures animated frames after warm-up, then freezes the candidate for its screenshot.

`WORLDENGINE_ASSETS=... python3 web/bakeoff/score.py` runs the repository's `Tools/lookloop/region_colours.py` implementation with calibration-v2 reference frames instead of the old hard-coded hero images. Evidence includes the exact boxes, numerical colour errors, and phone-size render/mock PNGs. Fixed-box colour distances can be confounded by composition; missing surfaces are not zero error. These are not independent art-direction grades.

## Current rule

See [RULES.md](RULES.md): Sloan first, then an immutable Lakeview hold-out. All look inputs and exports are hashed before and after both scenes. No camera or colour tuning occurs between them. Earlier numerical results below are historical until superseded by the current evidence files.

## Values and provenance

- `style-b-calibration-v2/values.json`: one sun and sky policy, exposure gain 1.2745606273, saturation 1.08 and contrast 1.06, applied once in one post pass. Matte roughness and ground base colours come from this same shared object. The sky uses the shared pack values directly. No city exposure, sky or saturation override.
- `foliage-seasons-v1/foliage-values.json`: regional candidate species selected by exported crown class and variant, using seasonal albedos. Assignments are inferred, not surveyed trees. Export positions, yaw and scale remain intact; silhouettes use deterministic lobes and branches.
- `water-surfaces-v1/water-values.json`: four-wave energy-normalized spectrum, subpixel normal fade, bounded soft sky reflection, no planar mirror or extra reflection capture. No claimed live wind, bathymetry or observed wave height.
- `lake-winter-v1/lake-winter-values.json`: Sloan body #477C8D, shallow #668C82, 2 m shore transition, roughness 0.28 for the 10 km/h fixture. The distance field comes from exported water boundaries, with shared edges cancelled across chunks; 1024² sampling limits very narrow shore detail.
- Lakeview: repository OSM/Overture footprints and available height/roof hints through the existing exporter. Unmeasured heights and roof forms remain generator inference; this is not a claim that every building height is surveyed. Existing data notices and credits apply.
- Sloan: existing exported lake, shore and neighbourhood. Front Range uses public-domain USGS 3DEP elevations (256² samples, roughly 300–400 m spacing) with geocentric curvature. `data/terrain-source.json` records the GREEN licence gate, credit, retrieval date and hash. `fetch-terrain.py` reproduces the window and reads the actual GeoTIFF bounds. Orthometric heights are treated consistently as relative elevations without a geoid transform; datum error is unquantified. No observed snow mask was supplied, so none is invented. `mountain-terrain-v1/palettes.summer.graniteHex`, rock roughness, and the shared lake-pack weather extinction provide the distant treatment; calibration owns scatter colour.

## Camera and limitations

The calibration pack explicitly provides no camera matrices. The two portrait cameras are visual fits in the real coordinate frame. Real geometry is never distorted to imitate a painted building or shoreline. The mock's enlarged mountains and ambient runners are not evidence of geography; actors are outside this two-scene request. The surface-class baseline in `docs/lookloop/calibration-baseline.md` must not be treated as a pixel-aligned reference for these new cameras.

The bake-off can inform shared material/post, crown and water work only after review. It does not silently replace the main viewer's existing lighting or scene loading.

The validation entry point is `HEAVY_AGENT="Astra A2" scripts/heavy.sh "A2 browser validation" bash web/bakeoff/verify.sh`; it captures both pages, runs both look-loop comparison tools, and checks all bake-off JavaScript syntax. Both pages and both existing-viewer baselines must render without browser or shader errors and return finite measurements. Failed captures are retried at most four times with a fresh browser, then stop the check. The local preview must already be running.

The 8 October hold-out rule is a prerequisite for promoting these experimental treatments into the shared production viewer: Lakeview, another Denver neighbourhood, and Greenville Downtown, all without tuning. This experiment changes no production viewer, generator, area data or profile. Its merge does not claim that broader gate has passed.

The shared browser lighting adapter uses ACES with direct radiance π × directRelative and ambient radiance derived from the calibration neutral-witness shadow/lit ratio. Sky has no additional gain. Exposure and saturation remain the exact shared values above. These are analytic shared conversions, not camera fits. Performance samples cover approximately ten seconds after warm-up at DPR 1; they are laptop portrait-viewport measurements, not a phone benchmark.

Required source credits stay visible at the top of captured frames, away from calibration ground boxes. The upstream sky filter excludes the neutral overlay. Ground boxes remain fixed to the calibration frame: if a real sidewalk does not occupy a box, its colour error is a composition warning rather than a pure material score.

## Previous result (before the 8 October hold-out revision)

This is an isolated experiment, not a calibration pass. The fixed-box mean colour error improved in Lakeview (32.3 to 19.4 ΔE76 over five available boxes) but worsened in Sloan’s Lake (13.8 to 18.7 over two boxes). Lakeview crowns are unsampled; its road box still intersects lawn, and the Sloan sidewalk box intersects lawn. These figures cannot establish visual conformance. The strongest improvement is the warmer, brighter building treatment. The largest gaps are façade detail, coarse crowns, overly regular water bands and camera/shoreline composition. True-scale mountains differ sharply from the painted reference.

Both candidates and both matched-camera controls passed browser/shader checks, and the repository’s region_colours and compare_runs tools completed. Chrome 154 / Apple M1 Max measured Lakeview at 96.1 fps, 194 draws, 877,056 triangles (390×780); Sloan at 100.0 fps, 157 draws, 1,134,793 triangles (390×585). Approximately ten seconds, DPR 1, headed browser, shared heavy lock; not a mobile-device performance claim.

The existing loader is reused unchanged. Shared grading/material wiring, boundary-derived water colour and the measurement harness are candidates for further main-viewer review. Crown cost and visual treatment, water reflections and all hold-outs need work before production adoption. The merge stores the comparison and its mixed result in separate pages; it does not substitute the experiment for the production look.

## Sloan-first frozen hold-out result — 8 October

The order was Sloan baseline → Sloan candidate → Lakeview baseline → Lakeview candidate. Before and after all four captures, the input hash matched: `790d11e9411252f09212a50972266cff2e6f354f44d470a866177f46d27c0721`. The two cameras and viewports were unchanged. The same shared code and pack fixture ran in both cities; only source region/data selected content. `evidence/holdout-proof.json` contains the complete input list and capture order.

Mean calibration-frame ΔE76: Sloan 25.0 (2 boxes), Lakeview 25.4 (6 boxes). These scores do not pass visual calibration. The pale sky is the largest shared regression, and the lake-pack haze removes distant mountain contrast. Lakeview was not retuned after seeing this result. Its earlier existing-viewer control has only five usable boxes, so its mean is not a like-for-like six-box comparison. Fixed boxes can include the wrong surface; these remain numerical diagnostics, not reviewer grades.

The invariant/unit checks and all four browser renders passed without browser or shader errors. The final rebased run measured Sloan at 100.0 fps and Lakeview at 94.5 fps on Apple M1 Max/Chrome 154 at the frozen portrait sizes. Only the isolated bake-off changes; the main viewer has not adopted this treatment. Shared-rule compliance is established; acceptable visual generalization is not.
