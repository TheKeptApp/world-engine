# Status

**R approved – 2026-10-08.** Approved, including the San Francisco revision 2 (SF r2); files marked superseded stay superseded.

**Owner lane:** P2, P1, 5A. **Phase:** US metro expansion; San Francisco is a hero market (SF r2); after the look gate.

Style B looks for nine US metros: house archetypes, district boards and a block paint-over for each, plus San Francisco slope, fog, transit and bridge studies (SF hero revision r2) and revised Southern metros (v2).

Binding rules from the pack:
- Positions, sightlines, footprints, DEM, waterways, setbacks, heights and road widths come from the map and override every authored value; unknown utilities stay off; missing data stays explicit.
- All dimensions, hex values, pitches, grades and weights are authored proposals, not surveys or measured prevalence; tree lists are candidate palettes, not abundance ranks.
- The shared clear-afternoon fixture (sun 40 deg / 225 deg, +0.35 EV, contrast 1.06, saturation 1.08, no added warmth) is a review fixture applied once; live sun, time and weather replace it; weather states replace, never stack.
- Detail follows projected height (below 6 px silhouette and contrast; 6 to 20 px porch, bay and entry masses; above 20 px broad openings and trim); drop features under 2 drawable pixels; never enlarge windows, trees, cars or stairs.
- Floors level, walls vertical, foundations and stairs step; no uniform steep grade (Marina, Mission, Embarcadero near flat); SF attached rows have zero open side gaps (7.6 m review frontage, real parcel width wins); fog bands are MSL metres.
- Dallas downtown and Fort Worth Fairmount stay separate (no merged skyline); DC keeps a mid-rise core; SF bridges only in separate map-bound sightlines; use Southern v2 and sf-r2 files, never anything named superseded or in sf/.

Authored or unverified: (1) All numbers are authored proposals: dimensions, palette hexes, pitches, setbacks, lot widths, grades and generator weights (sums 75 to 100 for seven metros; Nashville has none). No survey, no measured metro prevalence; Southern v2 grades (0.3 to 8%) are selected-block treatments, not city conditions. (2) Nashville is newly authored: the consolidated neighbourhood-conservation PDF was never read in full (search preview only), four-square massing is an authored option, street-character source records are empty, tree-form profiles cite NC Extension botanical ranges. (3) SF r2 numbers are authored rendering targets: the 25% block and 30% witness are unnamed illustrative hills (published witnesses: Filbert 31.5%, Hyde cable car 21%); fog bands, visibility and extinction are not meteorological data; 22 m tree spacing and 60% treeless runs are review targets. (4) Images are illustrative: pixels are not calibrated to the numbers; no engine integration or device benchmark; checks are offline layout, link and file checks at 390 px. Block paint-overs adapt engine cameras (lakeview-postcard.png for Boston, Philadelphia, DC; ordinary-street.png for the five Southern) and are not captures.

Flags for R:
- style-b-calibration-v2 owns look (no per-city material override) and differs from surfacePolicy: wall 0.86 here vs masonry/plaster/wood 0.82; asphalt 0.92 vs 0.82; sidewalk 0.90 vs concrete 0.82; foliage 0.90 vs 0.92; glass 0.50 vs 0.28. Do not compile this pack's look; compile content only (precedent: house-archetypes-v1, infrastructure-kit-v1).
- sharedLighting sky stops (#73A5CC, #A2C4DC, #DBDCD1) are the pale house-contrast-v1 values that calibration-v2 corrects from its frames to #7AAFE2, #8FBAE7, #A0C8F2 (R: images beat JSON). The copy itself equals the daytime master, so no conflict with house-contrast-v1 or house-archetypes-v1 (same px tiers and lighting).
- R's water decision (8 Oct): the lake pack owns water roughness (floor 0.18, ice 0.32), so surfacePolicy waterRoughness01 0.28 and waterReflectionStrength01 0.30 here (single fixed values) should not be compiled.
- Stale fields inside the SF r2 block: dimensionsProposal.gradePercentProposal is 12 (pre-r2) while terrain, text and README say 25%; the sheet still says 'Source camera: lakeview-postcard.png' although prompts show a new generation from sf/sf-district-04.png and JSON says camera reframed at crest, not registered. Use 25%; the camera claim is unclear.

Compiled into `mock-values.json` under `style-b/metros-wave2` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). Per-house `surfaceValues` (roughness) are not compiled.
