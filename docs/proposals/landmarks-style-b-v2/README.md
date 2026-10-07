# Landmarks Style B v2 — wave 2 cities

Open [the phone-size gallery](index.html). Five exterior landmark studies and one skyline far-view per city: **65 landmark sheets + 13 skyline studies across 13 metros**. Each exterior study has street three-quarter, aerial three-quarter and far views, material hex proposals, metres fields, must-be-exact requirements, simplification rules and projected-size tiers. Full layout PNG exports sit beside the HTML sheets; original art remains separate.

**Proportions real. Surfaces simplified. Light soft.** The approved Style B Bible calibration street and current unmarked Denver stadium sheet are the image-generation references. House-archetypes-v1 and infrastructure-kit-v1 supply the established sheet and screen-size conventions. The Bible's complete `sharedLighting` object is inherited verbatim in the values JSON: 40° sun elevation, 225° azimuth, soft shared clear mid-afternoon fixture. Production time/weather can drive the engine independently; these comparisons use one fixture. Images are authored concepts, not proof of photometric calibration.

## What's included

### New York

[Empire State Building](new-york-01.html), [One World Trade Center](new-york-02.html), [Art Deco crown tower](new-york-03.html), [Brooklyn Bridge](new-york-04.html), [Grand Central Terminal](new-york-05.html). [Skyline far-view](new-york-skyline.html).

### Los Angeles

[Griffith Observatory](los-angeles-01.html), [Los Angeles City Hall](los-angeles-02.html), [Hollywood Bowl](los-angeles-03.html), [Folded-metal concert hall](los-angeles-04.html), [Pasadena bowl shell](los-angeles-05.html). [Skyline far-view](los-angeles-skyline.html).

### San Francisco

[Golden Gate Bridge](san-francisco-01.html), [Pyramid tower](san-francisco-02.html), [Coit Tower](san-francisco-03.html), [San Francisco City Hall](san-francisco-04.html), [Palace of Fine Arts](san-francisco-05.html). [Skyline far-view](san-francisco-skyline.html).

### Seattle

[Space Needle](seattle-01.html), [Smith Tower](seattle-02.html), [Columbia Center](seattle-03.html), [Seattle Central Library](seattle-04.html), [Pike Place Market](seattle-05.html). [Skyline far-view](seattle-skyline.html).

### Boston

[Custom House Tower](boston-01.html), [Massachusetts State House](boston-02.html), [Trinity Church](boston-03.html), [Boston Public Library McKim building](boston-04.html), [Boston ballpark shell](boston-05.html). [Skyline far-view](boston-skyline.html).

### Washington DC

[United States Capitol](washington-dc-01.html), [White House historic main shell](washington-dc-02.html), [Washington Monument architectural obelisk](washington-dc-03.html), [Lincoln Memorial exterior shell](washington-dc-04.html), [Jefferson Memorial exterior shell](washington-dc-05.html). [Skyline far-view](washington-dc-skyline.html).

### Philadelphia

[Philadelphia City Hall architectural shell](philadelphia-01.html), [Independence Hall](philadelphia-02.html), [30th Street Station](philadelphia-03.html), [One Liberty Place](philadelphia-04.html), [Philadelphia Museum of Art exterior shell](philadelphia-05.html). [Skyline far-view](philadelphia-skyline.html).

### Atlanta

[Stepped-crown Atlanta tower](atlanta-01.html), [Peachtree cylindrical tower](atlanta-02.html), [Atlanta faceted-roof stadium shell](atlanta-03.html), [Georgia State Capitol](atlanta-04.html), [Fox Theatre architectural shell](atlanta-05.html). [Skyline far-view](atlanta-skyline.html).

### Dallas–Fort Worth

[Reunion Tower](dallas-fort-worth-01.html), [Dallas City Hall](dallas-fort-worth-02.html), [Tarrant County Courthouse](dallas-fort-worth-03.html), [Kimbell cycloid-roof museum](dallas-fort-worth-04.html), [Arlington stadium shell](dallas-fort-worth-05.html). [Skyline far-view](dallas-fort-worth-skyline.html).

### Houston

[Uptown stepped-roof tower](houston-01.html), [Downtown pentagonal tower](houston-02.html), [Historic Houston dome shell](houston-03.html), [Houston City Hall](houston-04.html), [Lovett Hall](houston-05.html). [Skyline far-view](houston-skyline.html).

### Austin

[Texas State Capitol](austin-01.html), [Folded-crown Austin tower](austin-02.html), [Austin campus main tower](austin-03.html), [Pennybacker Bridge](austin-04.html), [Austin Central Library](austin-05.html). [Skyline far-view](austin-skyline.html).

### Nashville

[Twin-spire Nashville tower](nashville-01.html), [Tennessee State Capitol](nashville-02.html), [Nashville Parthenon exterior shell](nashville-03.html), [Ryman Auditorium exterior shell](nashville-04.html), [Keyboard-front museum shell](nashville-05.html). [Skyline far-view](nashville-skyline.html).

### Phoenix

[Arizona State Capitol historic shell](phoenix-01.html), [Phoenix retractable-roof ballpark shell](phoenix-02.html), [Phoenix City Hall](phoenix-03.html), [Burton Barr Central Library](phoenix-04.html), [Taliesin West architectural compound](phoenix-05.html). [Skyline far-view](phoenix-skyline.html).

## Geometry contract

“Must be exact” describes what engineers must preserve when authoring the production asset. It does **not** certify any generated panel as accurate. AI image panels may disagree in roof details or local proportions. Use mapped footprints, roof planes, real height endpoints, orientation, terrain and landmark-specific reference drawings before a production build. All 65 complete meshes/footprints remain **UNVERIFIED**; no surveyed geometry or licensed mesh is supplied.

**Positions and sightlines come from the map.** No artwork supplies coordinates, camera bearings, occlusion or visibility distances. Skylines are composition studies, not geographically calibrated engine renders. Dallas and Fort Worth use distinct panes, as do downtown Houston and Uptown; unrelated clusters must not be collapsed into a fictional adjacent skyline. Distant skyline mountains and visibility are contextual proposals, not guaranteed sightlines. Never copy background buildings from a style-reference image into production geography.

Unknown dimension fields are `null`. Published numeric dimensions are supplied only when a primary reference and an explicit endpoint are recorded; conversion is 0.3048 metres per foot. Rounded UI values are for reading; JSON retains more precision. Bridge tower height above water is not interchangeable with structural height above foundation. Vault dimensions are modules, not the full museum footprint. Capitol length/width are published bounding dimensions, and width includes approaches. No heights are inferred from storey counts.

Six selected assets have a published height with a stated endpoint: Empire State Building, One World Trade Center, Golden Gate Bridge towers above water, Space Needle, Washington Monument and Lincoln Memorial. The others remain null. The US Capitol's published total reaches an excluded statue, so its sculpture-free shell height stays null. LA City Hall, Coit Tower and Smith Tower have unresolved endpoint or source conflicts documented in the JSON and sources list.

Colour hexes, matte material treatment and recess depths are **PROPOSALS**, not measured albedo or survey dimensions. A major recess depth of 0.25–0.6 m and a glazing band depth of 0.06–0.15 m are generic authored controls; never use them to scale the structure. Engine modelling must derive dimensions from the map/survey evidence.

## Detail tiers

- **Under 6 px projected landmark height:** silhouette and primary colour; retain defining dome, crown, void or bridge topology.
- **6–20 px:** major setbacks, grouped columns, porch-like recesses, roof opening, bowl and structural portals.
- **Over 20 px:** useful openings, ribs and major members, when they survive at least two projected pixels. Never add signs, brands, figures or public-art detail.

These component tiers do not alter the existing engine-wide LOD or ambient detail budgets. The height thresholds are a starting proposal: long bridges/low stadiums also need projected-width and screen-coverage tests. Preserve defining negative space before adding repeated surface information. At very small scale, use map-authored impostors or silhouettes rather than physically scaling the building shorter.

## Exclusions and scope

There are no visual logos, team/sponsor names, readable signs, badges, dogs or characters. Stadiums are unmarked exterior/bowl shells; retractable roofs use a documented concept pose and require current venue verification. Source URLs and internal research names identify the studied structure; public gallery labels avoid current sponsor/team names. These descriptive research references are not texture assets.

All figurative architectural sculpture, statues, fountains designed as artworks, murals, seals and sculpted friezes are excluded. Philadelphia City Hall loses its rooftop figure and sculptural reliefs; US, Texas, Georgia and Arizona capitol rooftop figures are omitted; Grand Central's rooftop statuary and Chrysler's projecting eagle sculptures are omitted. Lincoln and Jefferson Memorial interiors are dark and empty, with no statue replicas. The Parthenon and museum shells contain no pediment sculpture. Taliesin West excludes the dragon sculpture. Nothing about public-domain status overrides the user's exclusion.

**Statue of Liberty: reference only, needs rights review. No sheet; no skyline replica.** Other public artworks receive the same exclusion. The Washington Monument is included as a hollow architectural masonry obelisk, not a figurative sculpture; verify architectural scope before production.

The White House study is the historic main residence shell, not a claim about changing annex construction. Kimbell covers the Kahn building only, not the later pavilion. Taliesin West is a bounded low architectural compound, not a complete campus survey. “Most recognizable” is an editorial design selection, not a popularity measurement.

Removing logos or art does not clear architectural design, trademark or distinctive-shape rights. Existing research's pending verification flags are inherited where subjects overlap. Before publishing/licensing, verify geometry and project rights for the intended interactive 3D use; this kit supplies art direction, not legal clearance. See [sources](sources.md).

## Engineer handoff

1. Resolve mapped object IDs, dated terrain/LiDAR and measured endpoint-specific dimensions. Do not treat a research place-search coordinate as a surveyed anchor.
2. Build the silhouette and negative spaces first; compare street and aerial cameras against the same mesh.
3. Apply the copied lighting fixture and broad material hex proposals once; keep glazing restrained and surfaces matte.
4. Check recognition at 5, 12 and 32 px projected height, adjusting grouped columns and structural details without compressing real proportions.
5. Remove all text/marks/figurative art from geometry, textures, impostors and distant silhouettes. Test map-placed visibility, occlusion and skyline cluster separation.

## Files

`landmarks-values.json` contains 65 exterior specifications, 13 skyline intents, sources, dimensions and uncertainty. `prompts.json` preserves generation instructions and reference paths. `sources.md` records primary references and verification gaps. Each `<id>.png` is original concept art; `<id>.html` is the complete design/view sheet; `<id>-sheet.png` is its export. `index.html` is a local searchable gallery; `phone-gallery-preview.png` and `layout-check.json` document the layout checks. No network dependencies are needed to view the gallery; external source links require internet.

## Delivery checks

All 78 gallery images loaded at 390 px phone width and 1440 px desktop width without horizontal overflow or browser errors. City and text filters passed. All 78 complete sheet PNGs exported. The full shared-lighting JSON equals the approved Bible fixture; raster images are concepts, not measured photometric renders. Unknown heights and all rendered geometry remain explicitly unverified.

[Source availability audit](source-audit.json) records blocked/unavailable pages without bypassing them. [Correction prompts](correction-prompts.json) record removal of figurative ornament, inappropriate reference-city background towers and stadiums, and geometry corrections. Sources were used as references, not licensed image downloads.
