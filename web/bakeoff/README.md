# A2 web look bake-off

Two isolated pages reuse `web/src/world.js`, real exported geometry and the existing package format. Production viewer and generator code are unchanged.

## Current result

The [phone-budget audit](PHONE-BUDGET.md) lists every effect, actual all-pass costs, texture allocations, tier definitions and remaining gaps. **Both floor views fail the shadow budget**, although their main views fit 400k triangles / 100 draws. Hero and standard have no filed numeric limits; all three labels currently render identical effects at DPR 1. This is a laptop structural audit, not an iPhone performance pass.

| Scene | Main tris / draws | Shadow tris / draws | All-pass tris / draws | Content + target + MSAA MiB | Mean ΔE76 |
|---|---:|---:|---:|---:|---:|
| Sloan first | 382,040 / 91 | 276,536 / 67 | 658,577 / 159 | 36.004 + 34.611 + 10.444 | 16.1288 |
| Lakeview untuned | 262,138 / 67 | 322,277 / 126 | 584,416 / 194 | 32.004 + 35.481 + 13.925 | 23.0906 |

All-pass totals include the one-triangle post composite. Texture budgets are unfiled, not passed. Mean colour scores remain identical to previous A2: the fixed colour boxes are insensitive to the changed crown silhouettes. Crowns use fewer, asymmetric lobes derived from pack counts and crown volume, but remain chunky and far lobes visibly angular. Haze is held at 0.0008/m. No production viewer code changed.

Frozen inputs and byte-identical images across all three tier labels were verified; Sloan completed before Lakeview with no tuning. Browser, policy, colour-transfer and pass/texture accounting checks passed. PNGs stay local/ignored in `evidence/`; numerical evidence and ordered hashes are committed. The full visual target remains unmet.

## Rules, sources and limits

- [RULES.md](RULES.md) records the owner’s general-rule and Sloan-first hold-out instructions. `policy.js` takes packs and one simulated fixture, never a camera or scene ID. Geographic camera fixtures are unchanged from the earlier revision; no matrices were supplied with the painted mocks. Lakeview has been seen previously, so this is an unchanged-code transfer test, not a blind trial.
- `style-b-calibration-v2/sharedLook` owns sun, materials, exposure 1.2745606273, saturation 1.08 and contrast 1.06. The shared sky uses the R-approved `look-v2-sky-from-frames` correction required by its STATUS.md: #7AAFE2 / #8FBAE7 / #A0C8F2. No city-specific look override exists. Direct/fill units are derived from the pack’s neutral witness ratio; one ACES/post pass applies the grade.
- `weather-moments-v1/inherited.sharedLighting.sky` supplies the world-elevation gradient anchors and partly-cloudy policy. Calibration owns colours and 18% coverage target. A shared 2048×1024 seeded cumulus panorama has smooth coverage edges. Appearance-valued sky colours are analytically encoded through the inverse ACES/grade transfer before that single post pass, avoiding a double colour transform. No camera-specific cloud placement.
- `foliage-seasons-v1/species[].crown` owns lobe tiers, species silhouettes, sky-hole and contact-darkening proposals; `cities[].mix` selects inferred regional candidates and `seasonColours` supplies the fixture colours. Layered opaque smooth lobes and branch gaps replace the jagged masses, retaining exported positions and envelopes. They are still stylized and costly; they do not establish foliage conformance. `stable-random.js` ports the repository SplitMix64/FNV1a arithmetic.
- `water-surfaces-v1/waveModelProposal` owns spectral normalization, and `lake-winter-v1/water` owns body/shallow colours, wind roughness, shoreline darkening and projected-wave fade. Shore distance derives from exported mesh boundaries. There are no extra reflection captures or mirrors. Wind/season are simulated fixtures, not live observations.
- **Historical haze retained for this frozen audit:** haze-visibility-v1 was filed during merging and now supersedes this value; integration is not included in these results. Lake pack extinction remains **0.0008/m**. At 20 km its transmittance is only **1.125×10⁻⁷**; the clear-weather Front Range cannot retain visible contrast. The real DEM is unchanged and is not exempted from haze. [data/haze-conflict.json](data/haze-conflict.json) records the conflict. The separate mountain pack’s 0.00001/m clear value was not substituted or tuned. The new precedence is filed; renderer migration remains open.
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

With the preview running, validate using `HEAVY_AGENT='Astra A2' TIERS=hero,standard,floor scripts/heavy.sh 'A2 verification' bash web/bakeoff/verify.sh`. Installed headed Chrome and the bundled Playwright runtime are used; `PLAYWRIGHT_ROOT` can select another existing runtime. `verify.sh` forces Sloan then Lakeview. `freeze.mjs` hashes all look inputs before/after every capture and aborts on changes. `score.py` runs the unmodified `Tools/lookloop/region_colours.py` computation with calibration-v2 frames/boxes, plus `compare_runs.py`; no art grades are invented.

The existing-viewer control shares the fixed camera but retains its original materials, lighting and post; it is not the historical iOS calibration baseline. Source credits remain visible outside ground sampling boxes. Wider untouched hold-outs and independent art review remain prerequisites for production adoption.
