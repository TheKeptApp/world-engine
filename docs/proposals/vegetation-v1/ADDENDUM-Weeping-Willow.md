# Vegetation v1 addendum — Weeping willow

**6 October 2026 · Style B · Proposal only**

Adds a Chicago/North Shore **weeping Salix** visual family in four seasons, with street/aerial studies and the existing crown-construction comparison.

- [Season and construction sheet](images/addendum-01-weeping-willow-seasons.png)
- [Exact color chart](images/addendum-02-willow-exact-colours.svg)
- [Color JSON](vegetation-colours.json): new trees entry chicago-weeping-willow; optional construction details in weepingWillowAddendum
- [Prompts](addendum-prompts.json)

## Evidence and identity

**Verified:** broad crowns, hanging branches, green foliage with greyer undersides and greenish-yellow or gold fall color characterize weeping willows. Northern cultivated examples may be hybrids; silhouette does not establish Salix babylonica. [Oregon State University, checked 6 October 2026](https://landscapeplants.oregonstate.edu/plants/salix-babylonica).

**Assumption:** use this visual family only for a supported mapped or authored willow. This is neither an abundance estimate nor a planting recommendation. Exact species, size and mapped location take precedence. All construction, palette and performance numbers below are design assumptions.

## Crown and seasons

A broad, uneven scaffold supports **7–10 joined upper lobes** and **6–10 tapered hanging curtain groups**. Existing clusterCount means upper merged lobes only; curtains are separate proposed metadata. Keep **15–22% sky holes**, nominal 18%. Show the trunk and two or three arching limbs between drapes. Initial size band: 10–20 m height, 10–22 m crown width; supplied dimensions override it. Curtains fall 3–7 m, constrained to site clearance.

**Too crude:** a smooth mushroom on a pole, identical spaced drapes or dangling leaf cards. **Target:** irregular top masses, scalloped tapering curtains, lit tops and cooler shaded folds, gaps and visible branches. Leaf suggestions belong in mass shading rather than individual leaf geometry.

- **Spring:** fresh muted yellow-green, lighter curtain fullness, exposed scaffold.
- **Summer:** grey olive green, fuller drapes with openings.
- **Peak fall:** greenish yellow to pale gold; no default orange/red.
- **Winter:** remove all foliage. Keep the same scaffold and simplified hanging twig bundles; optional snow rests on supported upper branches and ground, never an evergreen-like white dome.

Stable mapped-object seeding preserves identity through seasons. Never move mapped trunks. Contact target: localized **15–20% linear-luminance reduction**, radius **0.15–0.40 m**, within the existing contact policy. Avoid black disks or counting both baked contact and renderer AO twice. Golden-hour swatches are display references, not warm albedos to light again.

## Phone and aerial construction

Near **600–900 triangles**, medium **200–450**, far **80–180**, small aerial **24–60**, tiny projected trees **8–16**. These replace existing vegetation allocations. Winter twig bundles obey the same limits.

At medium distance reduce to 3–5 upper masses and 2–4 drooping groups. At 20–40 m and aerial, retain the broad uneven hanging perimeter rather than an oak or ball silhouette. Remove subpixel winter twigs and preserve a few readable hanging arcs. Use projected size for switching and existing LOD transitions; avoid a season or distance switch that rerolls the scaffold.

Opaque joined curtain meshes reuse vegetation materials. No per-curtain draw call, alpha leaf-card overdraw, bones or special simulation. Static willow is acceptable; optional sway reuses bounded existing vertex wind, with scaffold less mobile than curtain tips. No additional wind budget.

Crown/trunk share 4.25 ms opaque, shadows 1.45 ms, crown/contact shaping 0.15 ms. World limits remain 400k scene triangles, 150k shadow triangles, 100 draws and 10 ms GPU. These are design allocations, not profiling results.

## Exact palette and review

Spring #91A46A; summer #7A9160; peak fall #B3AD5C; winter crown **null**. Branch base #7A7159; optional twig accent #A28B52; snow reuses #E3E8E7. JSON/SVG provide midday and golden-hour body/highlight/shadow triads. Rasters illustrate the look and show more fine leaf/twig detail than phone assets should retain.

Review at 5/20/40 m plus aerial. Reject orange autumn crowns, leafy winter silhouettes, solid umbrellas, transparent curtain grids and oversized contact disks. Existing trees, shrubs, palettes and images remain intact.
