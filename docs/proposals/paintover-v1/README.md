# WorldEngine paint-over pack v1

Appearance proposals, 2026-10-06. Open [the gallery](index.html). All six source frames are included unchanged. Comparisons use 390-pixel-wide phone views; scroll sideways to compare both at full phone width. Numbered markers match the ranked lists below.

## Authority and limits

The captured camera, roads, footprints, shoreline and object inventory govern implementation. AI paint-overs approximate that layout; they are not pixel-exact geometry proofs. Small silhouette/window/leaf variations remain, and the rain puddle retains a slightly rimmed appearance. Do not implement those variations. No new buildings, streets, trees, props or water bodies are authorized. Roofs, lawn and trunks must remain smooth material families; incidental generated grain is not a texture requirement.

All numerical values and contribution ranks are **authored judgments**, not measurements of the generated pixels. Source file dimensions and hashes are verified by the manifest. Existing design rules are repository references, checked 2026-10-06. No new astronomical timing or camera transform has been inferred from screenshots.

## Values and implementation

See [paintover-values.json](paintover-values.json). Exposure is EV relative to the calibrated renderer baseline E0. Contrast is a linear-luminance slope about 0.18, saturation a chroma multiplier, warmth a bounded RGB gain; these are not interchangeable with arbitrary editor sliders. Apply lighting, exposure, contrast, saturation, warmth, then the renderer tone mapper. Crown percentage differences are linear luminance relative to the mid swatch. Preserve each tree’s existing seasonal hue family.

Shadow strength is 1 minus shadow/lit linear luminance. Length is object height × cot(actual sun elevation), directed opposite the true solar azimuth. Capture heights/elevations are unknown: meter lengths are deliberately null; example elevations only illustrate the math. Overcast/smoke have attenuated direct light rather than fabricated hard shadows. Contact darkening affects ambient fill only, with bounded radius and a visibility floor; avoid multiplying overlapping darkening.

Trees use smooth rounded puff clusters, shaded interiors and existing thick trunks branching into the crown. Root flares stay inside existing clearance. Keep existing conifers as conifers. Aerial seam treatment changes contrast, color and distance haze across 150–300 m, never the street grid or context object inventory.

## Performance

Proposal only; no device benchmark. Reuse the visual-v2 buckets and ≤10 ms total GPU budget, with its 7.9 ms planned allocation and 2.1 ms margin. Broad material colors, vertex/instance variation and existing sun shadows should carry the change. Do not add a full-screen AO pass, transparent canopy layers, per-leaf geometry or high-resolution reflection render. Rain uses the rain-v1 cap and reflection approximation; aerial seam uses existing material/fog parameters. Validate in the renderer with fixed source cameras before accepting performance or geography.

## Frames

### Ordinary street · clear afternoon

![Phone-size comparison](images/ordinary-street-comparison.svg)

[Numbered image](images/ordinary-street-callouts.svg)

Exposure **+0.35 EV**; contrast **1.06**; saturation **1.08**; warmth **4%**; shadow strength **38%**; wet-path darkening **0%**.

Crown light / mid / dark: #9EAC74 / #738B53 / #405844. Light Y 67.3%; dark Y -62.67% relative to mid. Water: None.

1. **Daylight and fill** — Lift neutral facade/path and dog fill; retain ordinary afternoon instead of a sunset grade.
2. **Crown volume** — Smooth existing puff clusters; lobe gradients and dark interior joins replace flat ball shading.
3. **Ground families** — Differentiate lawn, concrete and asphalt with quiet broad variation, keeping every boundary.
4. **Contact grounding** — Short ambient pockets beneath shrub row, trunk bases and wall base; no painted crown shadow.
5. **Cast shadows** — Retain captured direction; soften light/shade transitions and keep shadow fill readable.
6. **Trunks and roots** — Thick existing scaffold branches into canopy; root flare confined to original base clearance.
7. **Dog legibility** — Preserve dog silhouette/pose/position; readable dark coat through fill and contact.
8. **Sky and edges** — Neutral blue cloud gradient and antialiased edges; no halo or new source disk.

### Evanston · fall afternoon

![Phone-size comparison](images/evanston-street-comparison.svg)

[Numbered image](images/evanston-street-callouts.svg)

Exposure **+0.25 EV**; contrast **1.07**; saturation **1.07**; warmth **6%**; shadow strength **40%**; wet-path darkening **0%**.

Crown light / mid / dark: #D7AD61 / #B58245 / #765338. Light Y 72.386%; dark Y -60.625% relative to mid. Water: None.

1. **Fall crown light and depth** — Round existing orange/ochre puffs with soft interior darkening and graded sun-facing lobes.
2. **Facade/roof hierarchy** — Cream neutral walls, plain restrained slate roof; retain every existing opening.
3. **Warm/cool lighting** — Warm fall daylight and cool filled shade, without a universal sepia overlay.
4. **Ground and leaf restraint** — Quiet lawn patches and existing leaf scatter only; preserve walkway intersection.
5. **Trunk shading/root flare** — Keep enormous obstructing trunk; add smooth volume and modest base flare, not bark grain.
6. **Contact under plants/eaves** — Small fill-only darkening at existing shrub/house/tree contacts.
7. **Shadow softness** — Follow source cast-shadow bearings, lift rather than erase the shaded lawn.
8. **Sky/edge finish** — Soft sky/cloud gradient, clean silhouette antialiasing without changing geometry.

### Sloan’s Lake · rain

![Phone-size comparison](images/showcase-03-comparison.svg)

[Numbered image](images/showcase-03-callouts.svg)

Exposure **+0.15 EV**; contrast **0.94**; saturation **0.96**; warmth **-3%**; shadow strength **14%**; wet-path darkening **10%**.

Crown light / mid / dark: #9AA36D / #727E55 / #445546. Light Y 78.379%; dark Y -57.358% relative to mid. Water: #718C9A.

1. **Wet concrete sheen** — Darken exposed path 10% linear substrate; add bounded broad sky sheen instead of simply grey paint.
2. **Shallow water marks** — Keep original puddle locations/envelopes; brighter reflected sky, flush edge, no crater lip.
3. **Rain and overcast sky** — Sparse camera-local streaks and coherent cloud/fog tone; no bright sun gap.
4. **Tree/crown volume** — Soft diffuse lobe gradients and dark interior joins; retain round trees and triangular conifers.
5. **Contact grounding** — Local ambient pockets at trunks and bench feet, not hard sunny silhouettes.
6. **Lake appearance** — Muted blue-grey and restrained broad reflection within exact existing shoreline.
7. **Lawn hierarchy** — Diffuse wet green, broad patches, no specular grass carpet.
8. **Soft depth/edges** — One distance haze term; clean near geometry, soft far tree contrasts.

### Sloan’s Lake · smoke haze

![Phone-size comparison](images/showcase-06-comparison.svg)

[Numbered image](images/showcase-06-callouts.svg)

Exposure **+0.1 EV**; contrast **0.94**; saturation **1.02**; warmth **2%**; shadow strength **16%**; wet-path darkening **0%**.

Crown light / mid / dark: #B0AA76 / #888958 / #5C6650. Light Y 64.865%; dark Y -48.144% relative to mid. Water: #858F90.

1. **Depth-dependent smoke** — Replace uniform orange grade with warm-neutral extinction that increases with distance.
2. **Near material identity** — Keep path pale cream, lawn muted green and trunks warm brown despite haze.
3. **Crown/trunk shading** — Rounded diffuse lobes and readable branch interiors; preserve all tree locations/forms.
4. **Sky coupling** — Taupe-grey sky agrees with smoke-scattered light, no clear sun or rain.
5. **Contact grounding** — Soft local contact stays visible even when distant contrasts fade.
6. **Lake color** — Hazed blue-grey, same lake strip, no saturated clear-weather blue.
7. **Weak cast shadows** — Reduce direct-light contrast coherently with smoke; no sunset-length invented shadow.
8. **Edges** — Near edges clean, distant silhouettes softly attenuated; no full-frame blur.

### Sloan’s Lake · golden aerial

![Phone-size comparison](images/v2-06-comparison.svg)

[Numbered image](images/v2-06-callouts.svg)

Exposure **+0.15 EV**; contrast **1.05**; saturation **1.04**; warmth **8%**; shadow strength **44%**; wet-path darkening **0%**.

Crown light / mid / dark: #B0B17A / #788758 / #435F4F. Light Y 91.048%; dark Y -54.861% relative to mid. Water: #477884.

1. **Core/context edge harmony** — Match existing outer parcels/blocks in palette and fill; fade detail contrast smoothly without new geometry.
2. **Lake color and sheen** — Muted teal-blue lake with a small source-aligned warm highlight; exact shore/island preserved.
3. **Golden light, cool fill** — Warm facing planes and cool shadow planes replace uniformly bright yellow outlines.
4. **Neighborhood material hierarchy** — Quiet roof/wall/road families let existing dense buildings read as masses rather than confetti.
5. **Park tree grouping** — Round and shade only existing projected crowns; no outside-context tree additions.
6. **Contact/depth** — Small existing-building/tree contact shadow; no black outline around the detailed tile.
7. **LOD transition** — 150–300 m material/detail transition only where coverage allows; preserve all intersections.
8. **Silhouette antialiasing** — Stable filtered tiny roofs/crowns; no horizon or geographic blur.

### Lakeview · golden hour

![Phone-size comparison](images/lakeview-street-comparison.svg)

[Numbered image](images/lakeview-street-callouts.svg)

Exposure **+0.2 EV**; contrast **1.06**; saturation **1.06**; warmth **8%**; shadow strength **44%**; wet-path darkening **0%**.

Crown light / mid / dark: #A8B16E / #71824B / #36533F. Light Y 104.638%; dark Y -63.322% relative to mid. Water: None.

1. **Golden light/cool shade** — Warm cream-facing walls and filled lavender-blue shade; keep source shadow bearings.
2. **Crown lighting and lobes** — Round green puffs, rich interior shade, modest warm-facing highlights without luminous outline.
3. **Facade shading/contacts** — Existing brick-color plane, window/trim hierarchy and soft eave/base pockets; no courses or added fence.
4. **Ground palette** — Natural green lawn, cream-grey concrete and quiet road; existing footprint borders unchanged.
5. **Trunks/roots** — Keep blocking foreground trunk exactly; smooth form shading and modest root flare.
6. **Long cast shadow finish** — Preserve source lengths/direction; soften boundaries, maintain cool light in shade.
7. **Shrub contacts** — Local fill occlusion below existing shrub row, no new hedge objects.
8. **Sky/edge finish** — Restrained warm/cool sky and clean silhouettes; no visible invented sun disk.

## References

- [LOOK-FIX-SPEC.md](../look-fix-v1/LOOK-FIX-SPEC.md) — repository design authority, checked 2026-10-06
- [README.md](../vegetation-v1/README.md) — repository design authority, checked 2026-10-06
- [README.md](../ground-v1/README.md) — repository design authority, checked 2026-10-06
- [README.md](../rain-v1/README.md) — repository design authority, checked 2026-10-06
- [WorldEngine-Visual-Spec-Proposal-v2.md](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) — repository design authority, checked 2026-10-06

## Deliverables

Six original PNGs, six paint-over PNGs, six embedded-image comparison SVGs, six numbered SVGs; index.html; this README; paintover-values.json; image-prompts.json; manifest.json; verification.md. SVGs are presentation wrappers around unmodified bitmap bytes. Generated images have tool-selected dimensions and are displayed in the full source aspect ratio without cropping.
