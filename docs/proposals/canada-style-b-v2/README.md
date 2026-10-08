# Canada · Style B v2

Open **index.html** for the responsive local gallery. This pack supersedes canada-style-b-v1 visual concepts and inherits the exact sharedLook object from style-b-calibration-v2. It contains 16 generated PNG boards, dated source research, authored values and the complete built-in imagegen promptset.

- Eleven archetypes: Toronto bay-and-gable, semi-detached, Annex and condo/podium; Vancouver Special, character house, West End tower and laneway house; Montréal outdoor-stair plex, Plateau walk-up and attached row house.
- Six district boards: Annex, Leslieville, West End, False Creek, Plateau and Rosemont-inspired row houses. Each uses street / 45° aerial / far columns.
- Two block paint-overs with preserved earlier concept baselines for comparison.
- Three-view transit and street-detail sheets; four-season maple, Norway maple, Vancouver cherry and lawn rows; Toronto snow, Vancouver rain/cloud mountains, Montréal deep winter/removal convoy, autumn colour; three-city night strip.

Archetype row labels and view controls sit outside the artwork. Open each board to enlarge a single panel on a phone. Trees/seasons uses spring, summer, autumn, winter columns. Night uses Toronto street, Vancouver aerial and Montréal far columns. Whole-sheet inspection remains available.

## Implementation contract

values.json contains storeys, lot widths, setbacks, palettes, proposed tree mixes, street dimensions, snow masks and RIGHT driving. Numeric ranges are **authored proposals**, not surveys, zoning or city standards. Observed geometry takes priority. Calibration lighting/exposure applies once; weather replaces the clear-day fixture. Local material colours do not justify separate city exposure grades.

Use ../road-signs-signals-v1/ as the sign/signal reference. Blank coloured sign panels suggest bilingual layouts without words. Generated signal lamps are illustrative and can appear simultaneously bright: do not copy these as valid live traffic phases. Ontario examples require verified BC/Québec overrides. No logos, readable legends, dogs, unrelated app content, real murals or public art appear intentionally in the artwork.

These are **reference concepts, not renderer captures or exact reconstructions**. The 45° designation is an art-directed camera intention, not a measured camera calibration. Backdrop geography, seasonal phenology and snow removal are schematic. Generated detail occasionally exceeds the simplified runtime target; remove brick/road microtexture and dense distant leaf geometry when implementing. Paint-overs retain the supplied block composition approximately, not pixel-perfect registration.

## Data and review

research.md distinguishes verified publisher evidence from unverified ingestion, current OSM completeness and rights details. Important: Vancouver lidar uses CGVD28GVRD while HRDEM uses CGVD2013. Toronto trees can be address-geocoded. TTC GTFS is static scheduling data. MSC has its own August 2026 licence and special alert-integrity requirements.

phone-check/ contains viewport results and screenshots: 51 page/viewport checks at 320, 390 and 1440 px passed without horizontal overflow or broken images; panel controls were exercised and three phone screenshots visually reviewed. Browser emulation checks layout and panel controls; it does not establish performance on physical Safari/iPhone hardware. Original reference packs and world-engine project were untouched. No git was used.
