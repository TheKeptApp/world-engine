# A2 web look bake-off

Two isolated pages reuse `web/src/world.js`, real exported geometry and the existing package format. Production viewer and generator code are unchanged.

## Current result

Sloan’s Lake ran first, then Lakeview with the identical hashed code, packs, weather fixture, exports and fixed cameras. Mean fixed-box ΔE76 against calibration v2 improved from 25.0 to **16.1** in Sloan (2 boxes) and from 25.4 to **23.1** in Lakeview (6 boxes), relative to the preceding A2 revision. The two means have different sample sets and are not cross-city rankings. The fixed boxes can include the wrong surface; scores are diagnostics, not passing 1–5 art grades. The full visual target remains unmet.

Final Chrome 154 / Apple M1 Max measurements, DPR 1, approximately ten seconds after warm-up under the shared lock:

| Scene | Viewport | FPS | Draws | Triangles |
|---|---|---:|---:|---:|
| Sloan | 390×585 | 100.0 | 160 | 1,442,985 |
| Lakeview | 390×780 | 90.0 | 194 | 1,068,448 |

All four candidate/control renders, policy tests, sky colour round-trip tests, browser/shader checks and hold-out hash checks passed after rebasing on main. These are laptop measurements, not phone benchmarks. PNGs remain local/ignored: `evidence/sloans-side-by-side.png` and `evidence/lakeview-side-by-side.png`. Numerical evidence and ordered input hashes are committed in `evidence/`.

## Rules, sources and limits

- [RULES.md](RULES.md) records the owner’s general-rule and Sloan-first hold-out instructions. `policy.js` takes packs and one simulated fixture, never a camera or scene ID. Geographic camera fixtures are unchanged from the earlier revision; no matrices were supplied with the painted mocks. Lakeview has been seen previously, so this is an unchanged-code transfer test, not a blind trial.
- `style-b-calibration-v2/sharedLook` owns sun, materials, exposure 1.2745606273, saturation 1.08 and contrast 1.06. The shared sky uses the R-approved `look-v2-sky-from-frames` correction required by its STATUS.md: #7AAFE2 / #8FBAE7 / #A0C8F2. No city-specific look override exists. Direct/fill units are derived from the pack’s neutral witness ratio; one ACES/post pass applies the grade.
- `weather-moments-v1/inherited.sharedLighting.sky` supplies the world-elevation gradient anchors and partly-cloudy policy. Calibration owns colours and 18% coverage target. A shared 2048×1024 seeded cumulus panorama has smooth coverage edges. Appearance-valued sky colours are analytically encoded through the inverse ACES/grade transfer before that single post pass, avoiding a double colour transform. No camera-specific cloud placement.
- `foliage-seasons-v1/species[].crown` owns lobe tiers, species silhouettes, sky-hole and contact-darkening proposals; `cities[].mix` selects inferred regional candidates and `seasonColours` supplies the fixture colours. Layered opaque smooth lobes and branch gaps replace the jagged masses, retaining exported positions and envelopes. They are still stylized and costly; they do not establish foliage conformance. `stable-random.js` ports the repository SplitMix64/FNV1a arithmetic.
- `water-surfaces-v1/waveModelProposal` owns spectral normalization, and `lake-winter-v1/water` owns body/shallow colours, wind roughness, shoreline darkening and projected-wave fade. Shore distance derives from exported mesh boundaries. There are no extra reflection captures or mirrors. Wind/season are simulated fixtures, not live observations.
- **Unresolved haze conflict:** lake pack extinction remains **0.0008/m**. At 20 km its transmittance is only **1.125×10⁻⁷**; the clear-weather Front Range cannot retain visible contrast. The real DEM is unchanged and is not exempted from haze. [data/haze-conflict.json](data/haze-conflict.json) records the conflict. The separate mountain pack’s 0.00001/m clear value was not substituted or tuned. Source-pack precedence needs resolution.
- `mountain-terrain-v1` supplies rock treatment. Terrain comes from public-domain USGS 3DEP; `data/terrain-source.json` records licence, credit, actual bounds and retrieval hash. Geocentric curvature is retained. The 256² DEM is coarse and its orthometric-to-ellipsoid error is unquantified. No snow history was supplied, so no snow mask is invented.
- Exported footprints, height hints, simple roofs, lawns and paths are reused. Missing building measurements and tree inventories remain inferred. The evaluation exports are frozen; they were not regenerated when main received new height data.
- [FACADE-AUDIT.md](FACADE-AUDIT.md) reports brick, bays, stoops and fences and their owning packs. It distinguishes genuinely missing detail from existing family/LOD/clearance-dependent generators. No façade or yard generation was built or altered.

## Preview and reproduce

From the repository root, using existing three.js and the compiled exporter:

```sh
HEAVY_AGENT='Astra A2' scripts/heavy.sh 'A2 export' bash web/bakeoff/export.sh
node web/bakeoff/serve.mjs
```

Open http://127.0.0.1:8782/. For an isolated checkout, set `WORLDENGINE_ASSETS` to the main repository containing the reference packs, existing Sloan export and `web/node_modules/three`. New exports stay in this folder’s ignored `generated/`. The server is loopback-only.

With the preview running, validate using `HEAVY_AGENT='Astra A2' scripts/heavy.sh 'A2 verification' bash web/bakeoff/verify.sh`. Installed headed Chrome and the bundled Playwright runtime are used; `PLAYWRIGHT_ROOT` can select another existing runtime. `verify.sh` forces Sloan then Lakeview. `freeze.mjs` hashes all look inputs before/after every capture and aborts on changes. `score.py` runs the unmodified `Tools/lookloop/region_colours.py` computation with calibration-v2 frames/boxes, plus `compare_runs.py`; no art grades are invented.

The existing-viewer control shares the fixed camera but retains its original materials, lighting and post; it is not the historical iOS calibration baseline. Source credits remain visible outside ground sampling boxes. Wider untouched hold-outs and independent art review remain prerequisites for production adoption.
