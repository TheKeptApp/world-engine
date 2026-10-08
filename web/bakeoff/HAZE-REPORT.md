# Regional haze migration

This round changes only atmosphere policy, its terrain visibility integration, water's placement of the already-atmospheric reflection contribution, diagnostics and evidence inside `web/bakeoff/`. It does not retune crowns, material palettes, grade, camera, export or mountain geography. Run order remains Sloan then Lakeview without tuning.

## Pack keys and values

| Approved `haze-visibility-v1` key | Value used |
|---|---|
| `definition.contrastThreshold` / `sigmaFormula` | 5% MOR; sigma = −ln(.05)/(1000 × visibilityKm), checked against the supplied rounded coefficients |
| `regions[id=front-range].seasons.summer.clear` | 75 km; **0.000039943097/m** |
| `regions[id=great-lakes].seasons.summer.clear` | 20 km; **0.000149786614/m** |
| `airlight.stateDayHex.clear`, `timeMix.day` | **#BDD0D9**, decoded to linear, time mix **0** |
| `integration.applyOnce`, `sharedWorldTerm` | One homogeneous linear-light airlight mix; sky and already-atmospheric sky reflection bypass it |
| `mountains.retainContrast`, `cullContrast` | **.05**, **.03**; fade between them |
| `mountains.internalDetailContrast` | **.10**; below it omit fold shading using an area-weighted diffuse mean in source terrain distance bands |
| `mountains.minProjectedHeightPx` | **2 px**, using DEM ridge relief; ordinary depth tests preserve terrain/building occlusion |

The actual pre-fog surface luminance supplies initial contrast against airlight; the nominal .5 example is used only in formula tests, never to force mountain visibility. Simplification cannot increase visibility eligibility. Geometry stays in the original WGS84-derived curved-earth positions. The explicit simulated clear fixture supplies no local haze layer or summit-obscuring cloud; unsupported layered inputs are rejected rather than silently rendered as uniform air. The new regional values are authored fallbacks, not measured conditions. The pack's historic pending label is superseded by its owner-approved STATUS.md.

The 256² DEM remains coarse and datum error unquantified. Azimuthal ridge height is a screen-size approximation using `mountain-terrain-v1/lod.horizonImpostor.azimuthSampleDeg=0.1`; actual raster depth handles occlusion. Near/far composition cannot be made to match the painted mock by enlarging or moving the Front Range. No extra blue grade, white overlay, local clear bubble or exposure compensation is applied.

At 1 km the airlight fraction falls from **55.07%** under the old fixture to **3.92%** Front Range / **13.91%** Chicago. At 20 km, Front Range transmittance rises from **1.125×10⁻⁷** to **0.44984**. These analytic changes describe atmospheric wash, not an independent image-quality score. The unchanged colour boxes and before/after screenshots are used to assess the visible result.

## Verified paired result

Sloan completed first across hero, standard and floor labels, then Lakeview with the same input digest and no tuning. Policy, 5% MOR/mountain gates, sky transfer, shader/browser errors, complete-frame counter reconciliation and byte-identical tier-image tests passed. The renderer-input hash is recorded in `evidence/holdout-proof.json`.

| Calibration-v2 region-colour mean ΔE76 (lower is better) | Previous | Regional haze | Change |
|---|---:|---:|---:|
| Sloan (2 fixed boxes) | 16.1288 | 16.6094 | +0.4806, worse |
| Lakeview (6 fixed boxes) | 23.0906 | 22.2580 | −0.8325, better |

**West-facing mountains appear:** the real DEM produces a low pale ridge behind the neighbourhood. The former uniform cyan veil is reduced, revealing far-shore building/tree colours. No enlargement, repositioning, invented snow or contrast boost was used. The visible ridge does not match the mock's tall snowy mountain composition; true geography and unchanged camera take priority. The coarse DEM and screen-size proxy limit precision. CPU eligibility diagnostics are not a count of visible pixels; raster depth and the captured frame determine the visible result.

Sloan's sky box is unchanged at 8.4 ΔE; its sidewalk-labelled box worsens from about 23.9 to 24.8. That box samples lawn-like colour in this different composition, and neither Sloan box measures mountains or far-shore contrast. Lakeview's crown-labelled box improves about 36.5→29.9 while its road-labelled box worsens 40.0→42.3. These fixed medians are imperfect surface matches, not a calibrated art score. This merge is justified by the explicitly approved atmosphere migration and recovered real terrain visibility, **not** a claim of universal ΔE improvement or look-gate passage.

Cyan wash is visibly reduced strongly across Sloan's distant shore and more modestly along Lakeview's street. The near crowns consequently look greener without any foliage palette change; the already documented chunky/angular crown limitation remains. The 75 km versus 20 km regional presets and different scene distances explain the different atmospheric response; nothing was fitted to either camera.

All-pass costs are unchanged: Sloan 658,577 triangles / 159 draws, Lakeview 584,416 / 194. Texture allocations are unchanged. Both still fail the floor shadow-triangle budget. Approximate instrumented laptop frame rates: Sloan 100 fps, Lakeview 92–96 fps; these do not qualify any iPhone tier.

Artifacts: `evidence/sloans-side-by-side.png` and `evidence/lakeview-side-by-side.png` compare current render against mock; `evidence/*-haze-side-by-side.png` compare the exact preceding A2 image against this revision. PNGs remain local and ignored. Numeric scores and the pre-haze metrics are committed.
