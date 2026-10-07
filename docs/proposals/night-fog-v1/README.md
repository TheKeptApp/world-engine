# Night + fog look pack v1

Style B proposal — 2026-10-07. [Open the gallery](index.html). Nine paint-overs: Lakeview, Sloan's Lake and Wilmette, each at blue hour, full night and morning ground fog.

## Source views and limits

The message named attached frames, but no image attachments arrived. After requesting clarification, I used matching repository day frames from look-loop capture **20261007-062707** (started06:27 October7): Lakeview street, showcase01 Sloan's Lake, Wilmette street. Read-only originals are copied into images for comparison; byte identity is verified. These are repository substitutes, not a claim that missing attachments were received.

All edits preserve the broad source camera/layout. They are **AI appearance references, not pixel-exact geometry proofs**: some crown, shrub, window and small facade variation remains. Original footprints, openings, path and shoreline govern implementation. Generated lamp/porch placements are illustrative where input lacked fixtures; survey/scene data must decide actual positions. No new building, road, tree, plant silhouette, window opening or skyline is authorized by generated differences.

The two street night views contain one demo car on the road; lakepath has none. This is a proposed activity cue, not observed traffic. Cars are the explicit exception to the source object inventory requested for headlights. No smoke is depicted, including no invented chimney activity.

**Verified/researched:** source bytes/dimensions, cited municipal/program facts. **Authored assumptions:** all colors, shares, radii, fog coefficients, exposure, directional bearings and cost ranks. Images are not numerical pixel matches. [Sources](sources.md); [prompt log](image-prompts.json); [validation](verification.md).

## Looks and exact values

[night-fog-values.json](night-fog-values.json) is the machine-readable values sheet. All hex colors are sRGB swatches decoded to linear before mixing. Exposure is EV relative to a calibrated daylightE0, after state lighting, not an instruction to brighten a day image by that amount.

| State | Sky zenith / mid / horizon | Exposure | Lit eligible windows | Direct sun |
|---|---|---:|---:|---:|
| Blue hour | #314D79 / #657FA3 / #A5A8B1 | +.20EV | 24% | 0 |
| Full night | #15243C / #243854 / #344255 | +.35EV | 30% | 0 |
| Morning fog | #AABED0 / #D1D5D3 / #E7DCC8 | +.10EV | 5% | .45 of clear time-key |

Blue hour uses **local sunset+20min** as the requested fixture time, but this offset does not establish a fixed sun elevation. The actual solar model, date/location and time zone determine the light key. Full night uses e≤−12°. Morning +5° is illustrative; captured illumination side in artwork is not ephemeris verification. No false direct sun below the horizon or moon without computed altitude/phase.

Night artistic sky fill is .24 and ground fill .08 of reference noon; blue hour .30/.10. These stay within the existing night palette envelopes. Dark walls and green crowns stay readable through fill, not a uniform blue emissive coat. Contact darkening affects ambient only and cannot darken emitters or direct lamp light.

## Streetlights: LED versus sodium

| Type | Artistic color | Illustrative identity | Half-max radius | Support radius |
|---|---|---|---:|---:|
| Warm LED | #F0DDC0 | 3000K | 4.5m | 9m |
| Legacy sodium | #F3B96F | 2000K appearance | 5m | 10m |
| Neutral LED | #D8E4EB | 4000K | 4.5m | 9m |

Hex swatches are authored, not exact CCT conversions or lamp identification from a screenshot. Warm LED is not sodium.

**Lakeview:** warm LED default is grounded in Chicago's large HPS-to-LED conversion; project information specifies≤3000K. Individual pictured fixtures remain unverified. **Wilmette:** warm3000K LED is an assumed demo choice consistent with village dark-sky guidance, not a verified block inventory. **Sloan's Lake:** warm LED demo, exact park inventory unknown; an explicit legacy-sodium override is provided for confirmed fixtures. Do not randomly mix lamp types to imply an unresearched neighborhood history.

Pools use the Gaussian plus soft support taper in JSON, respect surface normals and building occlusion, and leave dark gaps. Maximum6 active pool/headlight field groups total,2 per local region,2 actual nearby unshadowed lights across all emitters. Far lamp heads may be emissive without a real light/pool. The artwork's numerous distant lights do not authorize numerous dynamic lights. No shadow-casting streetlamp maps.

Halos are small: half-radius5CSSpx, support14px at390px phone width, blend≤.08 and aggregate coverage≤2%. Dry night asphalt remains matte; pools are illumination, not wet reflection streaks.

## Windows and headlights

Default30% lit **window apertures**, allowed20–40% as requested. This explicitly extends weather-v1's20–30% household-oriented proposal; adapters must not silently confuse households and apertures. Select by stable world/building/aperture IDs and a stable seeded PRNG, never a random choice each frame. Preserve selected ranks across views/time scrub, and group related floors/households for believable patterns.

Warm #F3D0A0 and cool #C9DDEB:85/15 warm/cool in Lakeview/Denver;90/10 in Wilmette. Existing window surfaces emit, no per-window point lights or detailed interiors. No fake bright window painted into an opaque wall. Keep frames visible and cap bloom. Small sample views need not show exactly30% in image pixels.

One demo car maximum per street image. Paired headlights #E5E7DE, nominal1.3m separation,14m forward footprint and2m half-width. Clip the footprint to its valid road/lane polygon and reject through-wall illumination. No car or headlights on park paths, lawns, lake or nonexistent roads. One paired field group shares the existing field cap; no additional lighting bucket. A live traffic/routing system is separate, high-cost work.

## City skyglow and stars

Directional skyglow is a low-horizon lobe, not a whole-sky orange filter. Lakeview/Wilmette's Chicago direction and Sloan's Lake's Denver direction must come from actual camera/downtown coordinates. JSON world bearings155°/160°/105° are **approximate authored placeholders**; do not treat them as surveyed capture bearings. If the sector is off-frame, keep it off-frame. Never invent a skyline or put a sunset band in an arbitrary screen corner.

Maximum glow weights .10 Lakeview, .08 Denver, .04 Wilmette. City-star multipliers .10/.25/.45, combined with existing weather/cloud/moon and directional skyglow suppression. Actual catalog and sidereal rotation are required; ≤128 visible stars existing cap, only about6 faint points illustrated here. Stars are a minor cue: no Milky Way or identical bright constellation overlay across dates. Blue-hour stars use actual solar gate rather than clock offset. These sparse AI points do not specify astronomical positions.

## Ground fog, patches and lift

Morning ground fog #D0D7D6, warm scatter #E8DCC3, extinction .035/m, top2.5m and upper1m taper. Near5m has an authored ground-fog readability band; haze still applies. Four broad world-stable patches maximum,30–80m scale,8–12m edge fade, demo coverage55%. Crowns emerge above fog, while distant bases and opposite banks lose contrast. No grass carpet, white cloud cards, fog particles or smoke plumes.

Separate distant haze: #C3CED4, .0015/m morning; #8294AE/.0015 atbluehour; #475568/.002 atnight. Combine ground and haze optical depths **once**, then one final fog mix. The JSON specifies height weight, broad patch weight and fallback. Uniform height layers allow closed-form integration; patch mode can use bounded4-sample quadrature within the shallow layer, pending device validation. This is not a full volumetric solver.

Patch placement requires actual park/water domain and layer elevation data; OSM water does not establish local fog. Keep shoreline fixed. A renderer lacking patch/height support must declare a homogeneous fallback, not claim visual parity. Lake reflections in artwork are restrained targets only; no mirror reflection renderer is required.

Demo burn-off takes120s: sigma .035→.007/m, top2.5→.6m, patch coverage55→15%. Live lift requires updated weather evidence, never a fixed10am rule. Dew/dampness are independent: morning concrete−4%, asphalt−5%, lawn−3%, dew grazing sheen≤.025; no automatic puddles. No smoke unless a real chimney and explicit activity are supplied; chimney smoke is disabled in this pack.

## What makes night alive — ranked build cost

Ranks and costs are author judgment, not an estimate from implementation review. **Low:** existing parameters/material flags. **Medium:** bounded shader/data integration plus spatial correctness checks. **High:** new simulation/rendering subsystem or substantial source-data integration. Costs do not establish person-days.

| Rank | Feature | Must / polish | Build cost | Alive / dead cue |
|---:|---|---|---|---|
| 1 | Readable cool ambient fill | must | low | Unlit walls, path and crown interiors retain material identity. / Black shapes punctuated by white dots. |
| 2 | Localized streetlight pools with dark gaps | must | medium | Ground pools align with fixture locations and respect curbs/building occlusion. / Lamp heads glow but illuminate nothing, or whole street uniformly orange. |
| 3 | Stable sparse lit windows | must | low | 20–40% eligible apertures seeded, mostly warm, varied by building. / Every window dark or every facade fully glowing. |
| 4 | Grounding and crown volume at night | must | low | Trunks, eaves and shrubs have short contact shading; crown interiors retain form. / Trees float or become flat black balls. |
| 5 | Directional skyglow and geographic depth | must | medium | Horizon glow points toward supplied downtown bearing, distant city fades coherently. / Uniform black sky or orange dome with arbitrary invented skyline. |
| 6 | Headlights restricted to roads | conditional must when cars exist | medium | Small moving paired emitters and clipped forward footprint on valid roadlanes. / Lights on lawns, sidewalk, lake or through walls. |
| 7 | Small restrained emitter bloom | polish | low | Soft halo helps small lamps read at390px. / Huge floating orbs and blownout white windows. |
| 8 | Sparse city-dimmed real stars | polish | low | Only strongest catalogstars survive darkestsky sectors. / Ruralstarblanket overdensecity or random constellationpositions. |
| 9 | Patchy shallow ground fog and gradual lift | must for fog state | medium | Trunk bases fade while crowns emerge, clear gaps and coherentwater/land attenuation. / Smoke plume, whitecloudcards or uniformgrayfilter. |
| 10 | Dynamic shadowed lights, volumetric shafts, detailed interiors | defer | high | Not required for thistarget. / Extraeffects cannot repair missing fill/pools/windows. |

Build ranks1–5 first. Add headlights only where vehicles and road masks exist. Fog state needs rank9. Do not defer readable fill/pools/windows while building expensive volumetric effects.

## Phone performance and acceptance

Existing visual-v2 target:60fps, ≤10ms GPU on iPhone13-class hardware, iOS26+,7.9ms content and2.1ms reserved margin. Material fog/sky/stars stay inside base-world4.25ms; wet/local light fields inside.35ms; restrained bloom inside existing.35ms bloom budget. No extra full-screen fog pass, no per-window real lights, no new lamp shadow maps. Numbers are provisional envelopes, not measurements.

Verify on a physical phone at390px presentation width and fixed drawable resolution: dark wall/path separation; lamps aligned with real positions; window share/count; road-only headlights; no glow through walls; crowns above lowfog; skyglow bearing; exact retained geometry. Run10min across night/fog/lift and record worst/p95 GPU, thermal and frame stalls. Neither generated images nor this pack are a lookloop/performance pass.

## Files

Nine paint-over PNGs, three unchanged day-source PNGs, nine390px original/edit comparison SVGs and three four-state sheets. README.md, night-fog-values.json, image-prompts.json, sources.md, index.html, manifest.json and verification.md. SVGs embed unmodified raster bytes; no raster manipulation was used. Generated size differs from1005×565 source; all sheets fit the full source aspect ratio without cropping.

All authored deliverables saved only in this folder. Built-in imagegen cache is tool-managed. No git commands or engine edits.
