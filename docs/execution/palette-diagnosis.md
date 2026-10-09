# Palette diagnosis — whole-scene web look

**Read-only diagnosis; palette B below is a hypothesis, not approval or implementation.** Inspected main `afc72bd`; renderer colours/OSM inputs/generator and facade policy match capture revision `1580115`. Context is delivery `c8c361d`, the current post-near-plane batch. No code, pack, image or capture changes; only this document. No new score. Current A3 review remains [crown-v3-ladder-scores](../review/crown-v3-ladder-scores.md).

The strongest colour findings are (1) an explicit, unusually chromatic mapped roof colour passed straight through the general tag-precedence rule; (2) the bake-off's constant lawn replacement bypassing exported lot hue variation; (3) October species colour endpoints plus a grade that expands chroma and clips low channels. No double sRGB conversion or double tone-mapping was found in the inspected path. This does not establish that palette alone will improve an A3 grade.

## Evidence and measurement definitions

Existing source frame: [Sloan 150 m, crown OFF](../lookloop/captures/a7-web-crown-all-near-fix/sloans-150-foliage-off-crown-off-fresh.png), SHA-256 `ea9f9e78f42e471788547a077f14562d1741522fc965596f0a8cdbe086624db6`; matched [manifest](../lookloop/captures/a7-web-crown-all-near-fix/manifest.json). Crown modes share the same building/ground colour path. Camera/date: 1005×565, west 270°, pitch down 45°, FOV 50°, AGL 150 m, 2026-10-15; corrected near 37.5 m. Fixed EV 0.35, gain 1.2745606273192622, contrast 1.06, saturation 1.08. No sceneBudget flag in this frame. Local generated package inspected at `Generated/package/sloans-lake/`; it contains 1,399 detailed building records. These counts describe the export, not visible pixels or the whole distant context. No export was regenerated for this diagnosis.

**All colour tables use CIELAB D65 L*/C*ab**, where C*=sqrt(a*²+b*²), L* nominally 0–100. Hexes are authored sRGB. Decode IEC sRGB, transform linear RGB to XYZ D65, then Lab; no chromatic adaptation. Format `hex (L*/C*)`. These are unlit swatch metrics, not measured screen brightness. Frame metrics below are explicitly separate. C* is not HSV saturation and the grade's 1.08 is not a uniform 8% increase in perceptual C*.

## 1. Where colours come from

| Class | Authoritative files and selection rule | Current values / L*/C* |
|---|---|---|
| Roof | `Sources/WorldGen/BuildingGenerator.swift` §family/colours; regional `Profiles/front-range.json`, `HouseArchetypes.swift` resolving `house-archetypes-v1` into profile variants; `Profiles/house-families.json` tone floors for non-archetypes; house-contrast roof defaults where applicable. Stable `OSMRef.random("palette")` picks a tuple, with archetype weights from look.json. Valid mapped `roof:colour` overrides it. **Roof material is not the colour selector here.** | See complete observed roof table below; roof shade 0.96–1.04 multiplies linear albedo. |
| Wall | Same tuple route (`[wall,trim,door,roof]`); mapped `building:colour` wins. Export wall shade 0.97–1.03. Bake-off `facades.js` / `facade-policy.js` subsequently override supported family wall vertices only: mapped building colour, else start_date era palette, else family.wall. Unknown families retain exported colour. | Family defaults/variants below; no location/camera colour override. |
| Lawn/grass | Native `SceneGenerator.withLawnEndpoints`, `Profiles/yards.json`, `Yards/YardGeneration.swift`, `GroundDetail` export per-lot tone/seed/shade. Bake-off `main.js::matte` instead selects `style-b-calibration-v2/sharedLook.materials.groundBaseHex.lawn` for every lawn flag. It uses paint.y but not the lot tone in extra.y. | `#73865B` (53.4/25.7). Front Range exported autumn endpoints `#98945D` / `#B7AA78`; scalar lot shades 0.92–1.07 survive. See explanation below. |
| Foliage | `web/bakeoff/species-policy.js`: mapped/export species wins; otherwise seeded regional form pool. `foliage.js` uses foliage-seasons-v1 seasonColours, **replaces peak_colour with matching vegetation family colours[2]** from `data/p2-crowns.json`, then date/region/individual timing in `phenology.js`; retained green by regional lag. | Six actual resolved species listed below. Bark for these deciduous species is `#796B57` (46.0/13.4), except aspen `#C9C6B5`; no one universal orange. |
| Road | `MockDaytime.swift` applies house-contrast-v1 master to export; bake-off sets named road slot from calibration asphalt. `SceneGenerator.swift` road class chooses geometry and shade: service road 1.06, other road 1.0. No asphalt age/material palette selection. | `#626A70` (44.3/4.7). Narrow low-chroma range is intentional; absence of class/condition variation makes it uniform. |
| Pavement | Export named sidewalk/curb, default paving, and source surface mapping in SceneGenerator. Bake-off overrides all sidewalk-flagged fragments with calibration concrete and sets named curb slot. This also bypasses the base viewer's sidewalk-joint function. Separate brick/setts/cobble slots survive where not given that flag. | Concrete `#C5C0B3` (77.8/7.2), curb `#B9B7AD` (74.3/5.4). Driveway `#BDB6A8`; crossings `#D9D3C4`; lane markings `#E8E2CF`; brick/setts/cobble `#9B6753`/`#8B8981`/`#929084` in base-palette.json. |
| Water | `main.js` resolves lake-winter-v1 `water.profiles[config.waterProfile].shallowColourHex` and `states[config.waterState].surfaceValues[0].baseColourHex`; shoreline distance selects the mix. water-surfaces-v1 owns wave/IOR mechanics. These are target appearance colours, analytically inverted through the grade and neutral irradiance, unlike ordinary albedo. | Sloan profile shallow `#668C82` (55.3/15.5), clear/wind10 deep `#477C8D` (49.1/19.5). Shore multiplier 0.88→1 over 0.60 m; shallow blend 2 m; example deep shore result `#437585`. No single constant final water colour. |

`web/src/materials.js::setPalette` loads exported sRGB slots into a linear Float32 palette. Bake-off is a material replacement, so values/functions in the shared base viewer are not necessarily its effective colour policy. In particular, native Metal mixes lawn slots 18/19 using extra.y; bake-off never does. The base web viewer's broad/fine lawn modulation also is not used by `matte`. Thus lawn scalar shading/AO and geometry still vary, but much of the authored hue/patch structure is lost; “uniform” is an appearance diagnosis, not a claim all pixels equal. Pavement L* is about 33 above asphalt before lighting/grade, explaining a strong outlining tendency without inventing a line effect.

### Current roofs: complete detailed-export colour inventory

Counts are building records, not roof triangles. Most inferred roofs are already low-chroma greys/browns; applying a global desaturation to cure the orange group would unnecessarily affect them.

| Authored roof colour (L*/C*) | Building count | Selection |
|---|---:|---|
| `#67645B` (42.4/5.6) | 295 | family/archetype default (mapped tags can also equal it) |
| `#65676C` (43.6/3.1) | 243 | family/archetype default (mapped tags can also equal it) |
| `#636A70` (44.4/4.5) | 241 | family/archetype default (mapped tags can also equal it) |
| `#555A57` (37.7/2.8) | 183 | family/archetype default (mapped tags can also equal it) |
| `#706B63` (45.4/5.2) | 112 | family/archetype default (mapped tags can also equal it) |
| `#6D6A62` (44.9/4.9) | 81 | family/archetype default (mapped tags can also equal it) |
| `#69665D` (43.2/5.5) | 77 | family/archetype default (mapped tags can also equal it) |
| `#625F59` (40.4/3.9) | 43 | family/archetype default (mapped tags can also equal it) |
| `#676C6A` (45.1/2.4) | 41 | family/archetype default (mapped tags can also equal it) |
| `#686568` (43.1/2.2) | 38 | family/archetype default (mapped tags can also equal it) |
| `#7A5E4A` (42.2/18.0) | 13 | mapped roof:colour |
| `#9A9A97` (63.5/1.7) | 13 | mapped roof:colour |
| `#9F390C` (38.4/61.2) | 12 | mapped roof:colour |
| `#646F5E` (45.5/11.1) | 4 | mapped roof:colour |
| `#585858` (37.4/0.0) | 1 | mapped roof:colour |
| `#D2B48C` (75.0/24.9) | 1 | mapped roof:colour |
| `#C4A886` (70.5/22.0) | 1 | mapped roof:colour |

### Current wall selection by detailed-export family

This is the fallback/generated colour inventory before the facade adapter. Primary inferred variants are listed completely; mapped exceptions remain in source records. The twelve orange-roof houses have mapped cream walls `#F5DEB3` (89.4/24.1). Family selection follows classification/footprint/levels and seeded regional priors, not camera. Archetype sheets override profile tuples when linked; naming a family does not prove its material was surveyed.

| Family | Exported default wall variants (L*/C*) | Effective bake-off override |
|---|---|---|
| bungalow | `#CAC4AC` (79.1/13.0); `#C3B798` (74.7/17.3); `#9A6650` (48.2/27.8); `#B9A88B` (69.6/17.3) | family wall #9A6650 unless mapped colour/era |
| foursquare | `#B59865` (64.3/31.1); `#C8BBA0` (76.3/15.4); `#925F48` (45.3/28.2); `#C1B18B` (72.7/21.6) | family wall #B59865 unless mapped colour/era |
| garage | `#A69A84` (64.1/13.2); `#8D9685` (60.9/10.2) | none; keep export |
| minimalTraditional | `#D0CCBF` (82.0/7.0); `#C8BBA0` (76.3/15.4); `#C4BCAB` (76.5/9.6); `#A7785E` (54.5/26.3) | none; keep export |
| modern | `#8A857B` (55.7/6.1); `#454A49` (31.0/2.3); `#D2CCBE` (82.2/7.7); `#A69B89` (64.4/10.9); `#4C5150` (34.0/2.2) | none; keep export |
| ranch | `#B1A68D` (68.4/14.4); `#C9BDA5` (77.0/13.7); `#D1CEC4` (82.7/5.4); `#A17E62` (55.5/22.6) | none; keep export |
| shed | `#AB8E73` (61.0/19.7); `#8B967E` (60.6/14.2) | none; keep export |
| splitLevel | `#AEB5A6` (72.8/8.6); `#92735A` (50.8/20.4); `#C8BBA0` (76.3/15.4); `#C3BEAC` (76.9/9.8) | none; keep export |

Facade supported families: Denver bungalow `#9A6650`, foursquare `#B59865`; Chicago greystone `#AAA99B` (69.0/7.7), brick two-flat/sixFlat `#98664F` (47.9/27.3). Era palettes in `web/bakeoff/data/facade-values.json::content.eraPalettes`: pre-1910 `#92513E/#98664F/#B09373`; 1910–1930 `#9A6650/#B59865/#925F48`; later `#C1B18B/#A77960/#C8BBA0`. `wallColour` picks one with stable `facade-era/<ID>` seed. With no mapped date, family.wall overrides the generator's four variants for covered families—another general source of flattened variation. Source `building:colour` is returned by that adapter directly, while the generator has a narrower supported named-colour vocabulary; these parsers should be reconciled in future work, but this does not explain the mapped hexadecimal roof group.

### Current foliage on this date

Read-only arithmetic replay of existing production species/phenology rules on all 6,228 exported tree/conifer identities (not a capture and not a count of visible trees). 5,649 deciduous trees; 579 blue spruce. Individual timing shift is seeded ±7 days. October 15 is Denver day 288, its authored peak-colour prior; no observation of actual tree phenology is implied. Early_colour exists in the pack but `seasonal` blends bud/summer/peak/bare only. Summer values come from foliage-seasons-v1; peak substitutions and lag come from P2/vegetation data. These apply to OFF, v2 and v3 tints alike.

| Species | Count | Summer → peak endpoint | Green retention at peak | Current mean unlit L*/C* (individual min–max) |
|---|---:|---|---:|---|
| Aspen | 815 | #49664C → #D4B44C | 0 | 73.54/54.86 (L 69.74–74.29; C 50.30–55.75) |
| Norway maple | 2,590 | #4F773C → #CE763C | 0 | 58.05/53.54 (L 56.35–58.42; C 48.65–54.61) |
| Cottonwood | 692 | #49664C → #C8AC46 | 0 | 70.28/53.60 (L 66.81–71.03; C 49.05–54.57) |
| Linden | 847 | #4F773C → #C6B24E | 0.55 | 59.75/43.11 (L 57.89–60.19; C 41.89–43.40) |
| American elm | 705 | #4F773C → #BCAE4D | 0.70 | 54.89/40.28 (L 53.57–55.15; C 39.63–40.41) |
| Blue spruce | 579 | #617A86 throughout | evergreen | 49.71/11.28 (no variation here) |

Thus orange/yellow dominance is partly the seeded population and calendar: maple alone is 41.6% of all trees. The recipe retains variation; it does not collapse to one gold. Aspen/cottonwood peaks are already L*70–74/C*54–56 before light and grade. The dark/mid/light master palette in MockDaytime does not replace these final bake-off species tints.

## 2. The fluorescent orange roof group

All twelve are in `Generated/package/sloans-lake/chunks/6_4/scene.json`, copied from `Data/areas/sloans-lake/osm.json`: **way/556614880, 881, 882, 883, 884, 885, 886, 888, 889, 892, 895, 899** (each suffix after the first expands to way/556614xxx). Each has `building=house`, two mapped levels, `building:colour=#F5DEB3`, `roof:colour=#9f390c`. None supplies roof:material in the inspected tags. Seven infer modern/denver-06-infill (880,882,884,885,888,889,895); five infer splitLevel/denver-05-split (881,883,886,892,899). The common roof colour survives both families, proving it is not their colour-variant selection. Their group is in the lower-right foreground of the 150 m frame. IDs establish provenance without recording residents or addresses.

`BuildingGenerator.hexColor` accepts any valid six-digit hexadecimal tag literally; named “red” instead maps to the restrained `#A4564A`. `generate` then assigns the literal roof tag to tuple[3], protected from subsequent contrast defaults, and paints the roof with a stable 0.96–1.04 factor. Palette.parse stores normalized sRGB; the web palette decodes it correctly. Facade overrides affect wall slots, not roof slots. The raw roof swatch is **L*38.42/C*61.16**, versus C*2–6 for typical inferred roofs. It is a dark, highly chromatic rust input—not an authored fluorescent orange.

**Classification:** general, intentional tag-precedence rule plus a gamut/appearance failure under illumination/grade; no evidence of a Sloan-specific palette bug, wrong slot or double-gamma conversion. Literal mapped sRGB is being treated as diffuse albedo, although a mapper's colour tag is not a calibrated reflectance measurement. Do not relabel these roofs terracotta merely from hue, silently replace source tags, or assert their source colour is wrong without external evidence. Any material-specific appearance guard would be a new general hypothesis, explicitly flagged below.

The diagnostic roof-pixel subset is integer crop x∈[580,940), y∈[450,565), further restricted to R>200, 30<G<130, B<40 (8-bit). It selects **22,537 pixels**, excludes cream walls/most crowns, but is an image colour mask, not a GPU material-ID mask. Median display RGB **[228,76,0]** (`#E44C00`), mean observed L*/C* **53.70/85.97**. **99.86% have B=0**; only 0.044% have R=255. This is overwhelmingly blue-channel clipping, not just blown red highlights. 99.90% hit at least one endpoint; the pre-clamp colour cannot be uniquely recovered. The input-to-frame C* increase includes lighting, tone curve, grade and clipping; it must not be attributed entirely to saturation.

## 3. Colour management and measured grade effect

Trace for ordinary materials: authored sRGB hex → `Palette.parse`/exported `palettes.json.srgb` → **one** IEC decode in `web/src/materials.js::setPalette` → Float32 DataTexture with `NoColorSpace` → linear material/light/fog → custom luminance filmic pass → contrast/saturation → clamp → **one** explicit linear-to-sRGB output conversion. Bake-off overrides/foliage `new THREE.Color(hex)` also decode once into Three's default linear working space. They write linear components directly, not into an sRGB-tagged texture. No automatic second palette decode is selected.

`main.js` sets `post.outputColorTransform=false`. Installed Three 0.180 `PostProcessing.render` temporarily sets NoToneMapping and linear working output space; its false branch does not call renderOutput. Renderer defaults to NoToneMapping. The imported `acesFilmicToneMapping` is unused on this path. So there is one custom curve and one explicit final encoding, not a second ACES/output transform. This is source-path verification, not a new GPU attachment inspection. Water/sky additionally use appearanceToRadiance to compensate the grade by design; that is a different value semantic, not gamma conversion.

Actual arithmetic (`Y=0.2126R+0.7152G+0.0722B`, linear RGB):

- `x = Y × 1.2745606273192622 / 0.6`; `F(x)=(x(x+0.0245786)−0.000090537)/(x(0.983729x+0.432951)+0.238081)`.
- `M = RGB × max(F(x),0)/max(Y,0.000001)`; this preserves RGB ratios before gamut clipping, rather than compressing each channel independently.
- `G = clamp((mix(luma(M),M,1.08)−0.5)×1.06+0.5,0,1)`, then sRGB encode.

EV and gain are the same instruction: 2^0.35=1.27456; EV is not applied again. The curve's inherited `/0.6` contributes another 1.6667 scale to its argument (combined 2.1243); it is not a second use of EV 0.35. Luminance-only mapping can push a high-chroma colour outside the output gamut, and the final clamp changes hue/chroma. Saturation and contrast expand linear distance from grey by 1.08×1.06=1.1448 before clamp. That algebra is not a measured perceptual percentage.

### Measurement from the existing frame, not a guessed render

Exclude top 32 pixel rows (credits): **535,665 pixels**. For each pixel, decode the PNG to linear; undo contrast, undo saturation, solve the quadratic inverse of F to recover source radiance; reapply F with one control neutralized. Keep only pixels with every 8-bit channel >1 and <254 and nonnegative reconstructed radiance: **469,924 pixels (87.73%)**. 12.27% are excluded, predominantly clipped/saturated pixels. No PNG is edited or new frame synthesized/saved. These are analytical counterfactuals on measured samples, holding pre-post radiance fixed, not actual alternative captures. Quantization and antialiasing limit precision. The inverse→original forward round trip's maximum linear-channel error is 6.7e−16 on eligible samples, an arithmetic consistency check, not proof of recovered clipped values.

| Same eligible pixels | Mean L* | Mean C* | Current minus alternative ΔL*/ΔC* |
|---|---:|---:|---:|
| Current recorded frame | 68.35 | 26.65 | — |
| Saturation 1.00; other controls current | 68.35 | 24.03 | +0.00 / +2.62 |
| Contrast 1.00; other controls current | 68.90 | 24.27 | −0.56 / +2.37 |
| EV 0 / gain 1.00; same curve/other controls | 61.57 | 25.28 | +6.78 / +1.37 |
| All three neutral: gain/saturation/contrast 1 | 62.67 | 20.41 | +5.67 / +6.23 |

**Yes, the fixed grade contributes:** on the reversible samples, combined mean C* is **30.54% higher** and mean L* **5.67 higher** than the same tone curve with those three controls neutral. Saturation alone raises mean C* by 10.90%. Contributions are nonlinear and not additive. This is not a recommendation for global desaturation, nor a full-frame causal estimate: the 12.27% excluded pixels are the very high-chroma tail. Full observed world-crop means, including them, are L*68.28/C*32.43. The roof mask has only 22 eligible pixels, so no defensible exact “grade added X to the orange roofs” statistic is inferred from that unrepresentative subset. A pre-grade HDR attachment or approved paired grade capture would be needed for the clipped pixels; neither was requested or taken.

Changing the real grade configuration would also feed water/sky inverse compensation, unlike this post-pass-only analysis. Keep those mechanisms fixed during a future material-palette trial; otherwise the comparison would mix two interventions.

## 4. Palette B — every entry is an unapproved hypothesis

Keep current lighting, grade, exposure, geometry, shadows, weather and species/date distribution. Change **material-role albedos/endpoints only**, selected by available source material, family and season. Do not resaturate/desaturate the finished frame. Preserve original mapped values/provenance in the export; a flag-specific appearance override must be separately recorded. These suggested values are not pack replacements or calibrated physical measurements. Roof shape alone does not prove roof material. For unknown material, retain the family fallback and labelled inference; no camera, block, colour-group coordinates or per-city gains.

| Material / general selector | Current input | Proposed B sRGB (L*/C*) | Status / reason |
|---|---|---|---|
| Roof: inferred asphalt/shingle family, no mapped colour | #67645B / #625F59 / #6D6A62 / #706B63 | `#555A58` (37.7/2.5) | **Hypothesis** — Lower-value neutral roof; retain stable modest per-building shade. |
| Roof: explicit membrane/flat-roof family fallback, no mapped colour | #555A57 / #636A70 / #65676C | `#606460` (41.9/3.0) | **Hypothesis** — Muted neutral; modern default may brighten slightly to keep material separation, not universally darken. |
| Roof: explicit clay/tile or other warm roof material | #7A5E4A; high-chroma mapped warm #9F390C requires separate appearance policy | `#805B4B` (42.1/20.0) | **Hypothesis** — A representative muted warm swatch, not a claim the orange group is clay. |
| Roof: explicit metal/zinc; otherwise no material inference | #676C6A / #686568 or tagged colour | `#666C6A` (45.1/2.7) | **Hypothesis** — Restrained cool-grey metal, no invented specular boost. |
| Wall: brick family | #9A6650 / #98664F | `#926B58` (48.7/21.2) | **Hypothesis** — Retain brick hue; reduce chroma while leaving measured/mapped colour provenance intact. |
| Wall: plaster/render/stucco family; mapped bright cream appearance candidate | #F5DEB3 or light family plaster | `#B8B09E` (72.0/10.2) | **Hypothesis** — Reduce very bright cream and avoid white-looking blocks; mapped guard is separately gated. |
| Wall: stone/greystone | #AAA99B | `#A3A295` (66.4/7.2) | **Hypothesis** — Small lightness reduction; no universal wall grey. |
| Lawn: seasonal base | #73865B | `#69765C` (47.9/16.2) | **Hypothesis** — Lower both lightness and chroma. |
| Lawn endpoint A: dry/cool-season lower endpoint | Front Range fall #98945D | `#5F6C53` (43.9/15.9) | **Hypothesis** — Use existing per-lot extra.y to mix endpoints in linear light; keep season/region selection. |
| Lawn endpoint B: companion higher endpoint | Front Range fall #B7AA78 | `#748066` (52.0/15.8) | **Hypothesis** — Maintain lot variation instead of constant fill; both endpoints below the current base L*/C*. |
| Grass tufts: dry-season grass | #B8AA76 autumn exported slot | `#727A5B` (49.8/18.3) | **Hypothesis** — Do not apply road/lawn brightness to every grass primitive. |
| Road asphalt | #626A70 | `#5D6468` (41.9/3.7) | **Hypothesis** — Slightly darker; preserve service-road shade, source material and markings. |
| Sidewalk concrete | #C5C0B3 | `#ABA99E` (69.1/6.1) | **Hypothesis** — Reduce bright outlines while retaining sidewalk identity. |
| Curb concrete | #B9B7AD | `#AAA89E` (68.8/5.5) | **Hypothesis** — Keep curb near pavement value; no broad white border. |
| Broadleaf summer (maple/linden/elm) | #4F773C | `#46603D` (37.9/24.1) | **Hypothesis** — Darker green endpoint, no altered timing or green-retention fraction. |
| Aspen/cottonwood summer | #49664C | `#445D48` (37.0/16.9) | **Hypothesis** — Keep species family distinction and darker interior read. |
| Maple peak autumn | #CE763C | `#A16E42` (50.8/35.9) | **Hypothesis** — Earthier orange, not fluorescent red/orange. |
| Aspen peak autumn | #D4B44C | `#AC974B` (62.9/42.4) | **Hypothesis** — Lower gold lightness and chroma. |
| Cottonwood peak autumn | #C8AC46 | `#A28F49` (59.7/39.5) | **Hypothesis** — Distinct subdued yellow-gold. |
| Linden peak autumn | #C6B24E | `#A49650` (61.9/38.7) | **Hypothesis** — Retain existing 55% green prior at peak. |
| Elm peak autumn | #BCAE4D | `#9A9150` (59.6/36.0) | **Hypothesis** — Retain existing 70% green prior at peak. |
| Spruce evergreen | #617A86 | `#526A70` (43.2/9.6) | **Hypothesis** — Darker blue-green, not the deciduous palette. |
| General bark | #796B57 | `#6C6151` (41.7/10.9) | **Hypothesis** — Subtle darker brown; keep aspen light bark exception. |
| Open-water deep appearance target | #477C8D | `#4C707A` (45.0/13.9) | **Hypothesis** — Restrained chroma/value; preserve lake profile semantics and inverse-grade path. |
| Open-water shallow appearance target | #668C82 | `#637F74` (50.8/12.8) | **Hypothesis** — Distinct shore-to-deep colours; keep 0.88 shore multiplier and transition mechanics. |

Mapped colour guard, **hypothesis only**: material-role-specific limits in Lab (e.g. roof C*≤25, L*35–50; plaster C*≤18, L*≤75), preserving mapped hue and recording the original input plus applied appearance rule. Apply to roof/plaster roles, never arbitrary same-RGB slots shared with doors, leaves or signs. This is a new visual interpretation of mapped colour, not correction of the OSM record. It requires R/pack approval before implementation. Without that approval, leave explicit roof:colour untouched and report the remaining orange-group gap. Exact hex-to-hex overrides for #9F390C or the twelve IDs would be a block-specific workaround and are explicitly excluded.

The table is a starting material study, not a universal “darker is better” rule. Keep other material families (sand, snow, glass, painted doors, markings, brick paving) unchanged pending evidence. Foliage summer/peak endpoints change, not season/date weights. Grass/lawn endpoint rows illustrate a dry/cool-season pair; extend a shared season schema explicitly rather than imposing October values year-round. No visual gain or phone-memory/performance result is inferred.

## 5. Default-off flag and shared native data plan — not implemented

Propose `?paletteB=on`, absent or `off` preserving the exact current path; reject other values. Use the existing bake-off entry mechanism to lazily load a small palette adapter only when enabled. Do not create a forked full renderer or edit the shipping default material path. Resolve the table once before material/instance-colour construction, and expose table hash, selector provenance, resolved values and mode in capture metadata. Keep crown mode and sceneBudget independently recorded, with a controlled compatibility test; the comparison must hold them fixed.

Selection must be semantic: feature/generated family and source tags for wall/roof, paint flags/named slots for ground, species/season for foliage, water profile/state for appearance colours. Palette slots are deduplicated by hex, so changing a shared slot solely because it equals an orange/brown hex could recolour unrelated parts. Roof/wall role information must survive the adapter (derive from exporter metadata/geometry paint assignments with a validated role, or add an explicitly owned export semantic field); do not guess from triangle position or hard-code a feature ID. Lawn consumes the existing extra.y lot tone; keep paint.y shade. Only unsupported roles retain current fallback.

**One table can drive native and web without duplicated colour constants.** After approval, A3 files one canonical pack with material keys, `colourSpace: sRGB`, separate `valueSemantic: albedo | displayAppearance`, units, source priority, species/season endpoints and hypothesis/approval provenance. Existing `Tools/lookloop/compile_mocks.py` can compile those same keys into `Resources/look/mock-values.json` and the native bundled `Sources/WorldGen/Profiles/mock-values.json`; web reads the same data/hash. P2 owns native generator/material-role routing; 5A owns native renderer/water interpretation. Swift/JS still need thin consumers, but neither should contain a second hand-maintained hex table or fork the selection rules. Shared fixture vectors must prove identical key selection, IEC decode and linear interpolation; native/web tone response must be checked separately. Water appearance values cannot be treated as ordinary albedo just because both are hex strings.

Future approval/build validation: default absent/off geometry/material/PNG identity; no tree/scene membership change; source-tag precedence/provenance witnesses; material-role isolation (same hex on roof and door); same seeded lot/species inputs; exactly one sRGB decode/encode and unchanged grade. Then matched controls/candidate at the three frozen ladder heights plus untouched Lakeview, same crown mode/date/exposure, before/after with A3 scoring. Stop for lost semantic classification, unintended material changes, clipped-colour growth, default drift or a hold-out loss. This task performs none of those future captures/builds.

## Reproduction details and limits

Read-only calculations used bundled Python/NumPy/Pillow on the existing PNG and JSON. Palette L*/C* uses IEC decode and the RGB→XYZ matrix rows `(0.4124564,0.3575761,0.1804375)`, `(0.2126729,0.7151522,0.0721750)`, `(0.0193339,0.1191920,0.9503041)`, D65 white `(0.95047,1,1.08883)`, standard Lab transition δ=6/29. Mean C* is mean per-pixel chroma, not chroma of the mean RGB. Round displayed results to two decimals; no claim beyond PNG quantization.

To reproduce the grade inversion for eligible pixels: decode sRGB output O; `U=(O−0.5)/1.06+0.5`; `y=dot(U,w)`; `M=y+(U−y)/1.08`; solve `(1−0.983729y)x²+(0.0245786−0.432951y)x−0.000090537−0.238081y=0` for positive x; source `S=M×(0.6x/1.2745606273192622)/y`. Evaluate the forward equations above with each alternative control, retaining the original eligibility mask. Exclude clipped samples rather than inventing lost radiance. Measurements are analytic post-process attribution, not visual grades or newly rendered alternatives.

No renderer, pack, tracker, capture or image file was changed. No heavy build/capture was run or lock acquired. Findings and hypotheses are for R/A3/5A/P2 review; palette B remains unapproved/default not implemented.

Used: current material/generator sources and c8c361d/1580115 existing frame; calibration-v2, foliage-seasons-v1, vegetation, house archetype/contrast and lake packs. Mock: style-b-calibration-v2/06-sloans; measured current Sloan 150 m OFF PNG. Deviation: clipped pixels cannot yield exact grade attribution; palette B is hypothesis only, no code or new capture.
Tracker update:
