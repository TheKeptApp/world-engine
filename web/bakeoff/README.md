# A2 web look bake-off

Two isolated pages reuse `web/src/world.js`, real exported geometry and the existing package format. Production viewer and generator code are unchanged.

## Current result

The approved [regional haze migration](HAZE-REPORT.md) now uses Front Range summer clear **75 km MOR / 0.000039943097 per metre**, Chicago summer clear **20 km / 0.000149786614 per metre**, and one linear-light airlight mix from `haze-visibility-v1`. The old 0.0008/m conflict is resolved. Real west-facing mountains now appear as a low pale ridge; far-shore cyan wash is reduced. No camera, terrain positions, crowns, calibration grade or palette was tuned.

| Scene | Previous mean ΔE76 | Current | All-pass triangles / draws |
|---|---:|---:|---:|
| Sloan first | 16.1288 | 16.6094 (worse) | 658,577 / 159 |
| Lakeview untuned | 23.0906 | 22.2580 (better) | 584,416 / 194 |

Sloan's two colour boxes exclude the mountains and its sidewalk box samples lawn-like pixels in this composition. Fixed-box means are diagnostics, not visual gate scores. Current images still lack the mock's mountain composition, foliage realism and façade detail. All shader/browser, regional policy, mountain-rule, colour-transfer, frozen-input and tier-identity checks passed. The earlier [phone-budget audit](PHONE-BUDGET.md) remains valid for geometry/memory: both floor views still fail shadow triangles; hero/standard numeric limits and texture ceilings remain unfiled. This is not an iPhone timing pass.

## Rules, sources and limits

- [RULES.md](RULES.md) records the owner’s general-rule and Sloan-first hold-out instructions. `policy.js` takes packs and one simulated fixture, never a camera or scene ID. Geographic camera fixtures are unchanged from the earlier revision; no matrices were supplied with the painted mocks. Lakeview has been seen previously, so this is an unchanged-code transfer test, not a blind trial.
- `style-b-calibration-v2/sharedLook` owns sun, materials, exposure 1.2745606273, saturation 1.08 and contrast 1.06. The shared sky uses the R-approved `look-v2-sky-from-frames` correction required by its STATUS.md: #7AAFE2 / #8FBAE7 / #A0C8F2. No city-specific look override exists. Direct/fill units are derived from the pack’s neutral witness ratio; one ACES/post pass applies the grade.
- `weather-moments-v1/inherited.sharedLighting.sky` supplies the world-elevation gradient anchors and partly-cloudy policy. Calibration owns colours and 18% coverage target. A shared 2048×1024 seeded cumulus panorama has smooth coverage edges. Appearance-valued sky colours are analytically encoded through the inverse ACES/grade transfer before that single post pass, avoiding a double colour transform. No camera-specific cloud placement.
- `foliage-seasons-v1/species[].crown` owns lobe tiers, species silhouettes, sky-hole and contact-darkening proposals; `cities[].mix` selects inferred regional candidates and `seasonColours` supplies the fixture colours. Layered opaque smooth lobes and branch gaps replace the jagged masses, retaining exported positions and envelopes. They are still stylized and costly; they do not establish foliage conformance. `stable-random.js` ports the repository SplitMix64/FNV1a arithmetic.
- `water-surfaces-v1/waveModelProposal` owns spectral normalization, and `lake-winter-v1/water` owns body/shallow colours, wind roughness, shoreline darkening and projected-wave fade. Shore distance derives from exported mesh boundaries. There are no extra reflection captures or mirrors. Wind/season are simulated fixtures, not live observations.
- `haze-visibility-v1/regions[].seasons.summer.clear`, `definition`, `airlight.stateDayHex.clear`, `timeMix.day`, `integration.applyOnce` and `mountains` now control atmosphere. `data/haze-values.json` is a source-hashed subset. All land/water/vegetation uses the same regional ray term; the sky and already-atmospheric reflection contribution bypass duplicate fog. Terrain uses the same term with actual pre-fog luminance contrast, .03–.05 fade, 2 px minimum relief and coarse fold shading below .10 contrast. Geocentric depth preserves sightlines; no local layer or summit-obscuring cloud is supplied by this explicitly simulated clear fixture. See [HAZE-REPORT.md](HAZE-REPORT.md) for values, limitations and evidence.
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

## Overnight round, 8 October

Latest ordered work and rejected/accepted decisions: [overnight log](evidence/overnight-log.md).
Sources, pack keys, inferred inputs and limitations: [overnight sources](OVERNIGHT-SOURCES.md).
Actual all-pass laptop/tier cost: [laptop budget](LAPTOP-BUDGET.md).
Run `TIERS=hero,standard,floor bash scripts/heavy.sh 'A2 verification' bash web/bakeoff/verify.sh` from the repository root; the script resolves ignored assets from the primary checkout and enforces the 8 GB guard. After capture, `python3 web/bakeoff/laptop-report.py` regenerates the cost report.
The branch merge keeps this work isolated; neither production web files nor P2/5A sources are modified. This experiment has not passed the iOS parity/look gate.
