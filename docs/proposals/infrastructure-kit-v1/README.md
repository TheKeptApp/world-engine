# Infrastructure kit Style B v1

[Open the phone-size gallery](index.html) · [Values and prompts](infrastructure-values.json)

48 generic infrastructure sheets across seven groups. Each asset has a three-panel artwork PNG and a standalone HTML design sheet with street 3/4, aerial 3/4 and far views, four hex-palette options, metre dimensions and three screen-size tiers. Complete specification-sheet PNG exports accompany the HTML as `*-sheet.png`. The visual layout, typography, swatches and tier rows follow `house-archetypes-v1`, expanded to three views.

## Contents

| Group | Sheets |
|---|---|
| Roads (9) | Highway/interchange; on/off ramp modules; overpass; sound wall; arterial; residential street; alley; US lane-marking library; US crosswalk library. |
| Bridges (6) | Generic double-leaf bascule; steel truss; concrete girder; cable-stayed; suspension; pedestrian. |
| Rail (5) | Elevated steel rail structure; commuter rail with catenary; embedded light rail; rail yard; generic station modules. |
| Airports (6) | Runway/markings; taxiway/holding position; apron/stands; terminal/concourse; control tower; hangar. |
| Water (7) | Harbour basin; marina; pier; river wall; navigation lock; canal; seawall. |
| Utility (7) | Distribution poles/lines; transmission tower; substation; water tower; cell tower; wind turbine; solar farm. |
| Parks/open land (8) | Golf course modules; soccer/football/baseball field library; cemetery; large parking lot; small parking lot; stadium parking; neighbourhood park; meadow/open land. |

The highway sheet combines an interchange and its grade separation; the ramp, overpass and sound-wall sheets expose reusable submodules. Library sheets include related pattern variants rather than treating every dash/field as a separate infrastructure family. Generic contextual buildings do not imply specific branded designs. No dogs, people, characters, logos, real addresses or named-landmark replicas are part of the kit.

## Style and lighting

Use restrained faceted geometry, matte colour blocks, readable massing and sparse broad detail. Water is a quiet surface, paving is a broad plane, and vegetation is context. Individual foliage, grass, gravel, rivets and dense wire geometry are not runtime requirements. Large land-use layers should use material regions/decals rather than individually modelled repeated surface detail. Preserve real-scale proportions; do not enlarge supports/cables to imitate miniature toys.

The approved `house-contrast-v1/paintover-values.json` **sharedLighting object is copied unchanged** into the values file. All sheets target its clear mid-afternoon fixture: sun elevation 40°, azimuth 225°, warm sun #FFE8C6, cool fill #AEBCCA, exposure +0.35 EV, contrast 1.06 and saturation 1.08. Asphalt #626A70, concrete #C5C0B3 and lawn #73865B are inherited dry-base references. The visual references are the approved Denver hero and the existing bungalow sheet; their source paths and hashes are retained. The source object's legacy anchor ambiguity is inherited verbatim, not silently resolved.

Images were produced with the **built-in image-generation tool**. They target the approved lighting and Style B but are not calibrated renderer outputs. Exact sunlight bearing, pixel hex values, geometry dimensions and photometric equality are not established by generated images. The JSON is the numerical authority; observed map geometry and production live weather/time override illustrative defaults.

## Values, units and variants

All new dimensions, palette variants, component arrangements and tier controls are authored **proposals**, not surveyed prevalence, engineering standards or approved physical designs. Distances are metres. Keys explicitly ending in `Deg` are degrees; count/spacing/ratio controls are distinguished in the sheet. Track counts, runway threshold-bar count, blade count and bridge span counts are counts rather than metres; football endzone depth remains metres. Each asset's palette labels primary, secondary and accent roles; the artwork shows one representative treatment, not four rendered variants.

Lengths, widths, deck heights, spans, pole spacing, platform sizes, water-level differences and site footprints are practical generator examples. They do not assert load ratings, navigation clearance, airport certification, electrical safety, accessibility compliance or structural feasibility. Use authoritative geometry and infrastructure attributes when available. Do not turn a generic module size into a hardcoded size for all real infrastructure.

Detail tiers use the projected **asset/component bounding-box extent in drawable pixels**, not metres, distance or CSS pixels:

- **Under 6 px:** major silhouette, surface colour and landform only. Cull subpixel cables, lines, grave markers, ties and fixtures.
- **6–20 px:** deck/void/support rhythm, pylon shape, platform masses, basin/dock footprint and other major distinguishing forms; retain lines only if resolved.
- **Over 20 px:** restrained openings, major truss diagonals, lane/runway markings, station columns, dock fingers and other useful coarse detail. Still omit microscopic repetition.

Huge facilities must make detail decisions on local modules (bridge span, terminal bay, parking block or rail segment), rather than using an entire multi-kilometre bounding box that would keep every tiny fixture visible. A proposed 2 px hysteresis band is included to reduce LOD flicker. Far panels communicate simplification intent; they are not controlled camera-distance or measured pixel-size tests. No device/GPU/thermal benchmark is claimed.

## Connectivity and reuse

Keep road/ramp connectivity and grade separation independent of art detail. Maintain rail gauge and track/turnout topology from reliable source geometry. Respect shoreline elevation and the lock's upstream/downstream level difference; boats or operating gates would need separately validated states. The bascule sheet intentionally shows closed near/aerial views and an open far-state variant. Cable-stayed bridges use straight stays to pylons; suspension bridges use sagging main cables and hangers. These are distinct generator families.

For instancing, split long infrastructure into reusable modules: road ribbon/cross section; ramp/merge; bridge span/pier/abutment; rail segment/bent/catenary mast; platform/canopy bay; apron/stand; dock/finger/gangway; pole/pylon; solar table; parking block; park path/land patch. Values define design controls, not mesh files or executable generator code. No engine implementation or repository changes are included.

## US marking references

Road pattern intent follows US flow separation: yellow for opposing-flow/median-side boundaries, white for same-direction divisions and outer edges. The crosswalk library demonstrates longitudinal bars, ladder and transverse-line forms. FHWA identifies the current MUTCD as the 11th Edition with Revision 1, December 2025. Exact installation dimensions and state/local exceptions need their applicable standards; kit line widths/dash lengths are proposals. [Official FHWA edition](https://mutcd.fhwa.dot.gov/kno_11th_Editionr1.htm), [FHWA marking chapter reference](https://mutcd.fhwa.dot.gov/htm/2009r1r2r3/part3/part3a.htm).

Airport colour intent follows the FAA AIM: runway markings white, taxiway and holding-position markings yellow. The proposed 45 m runway uses the FAA's twelve-threshold-stripe pattern as a reference; individual painted dimensions still need applicable specifications. Holding-position groups are separate from road crosswalks. Runway designator zones are left blank in illustrations because no real airport heading is assigned: production designators must derive from magnetic runway direction and actual runway metadata. [FAA airport markings](https://www.faa.gov/air_traffic/publications/atpubs/aim_html/chap2_section_3.html), [FAA AC 150/5340-1](https://www.faa.gov/airports/resources/advisory_circulars/index.cfm/go/document.current/documentNumber/150_5340-1).

Generated markings are visual concepts, not operational signs or navigation aids. Use the structured marking rules and resolved decals to implement correctly. If generated paint or ties differ from numeric controls, the JSON and authoritative source geometry win.

## Provenance and verification

The full canonical design prompts are saved under `assets[].prompt`; targeted correction prompts are retained under generation provenance. Image hashes and inherited reference hashes support review. Validation covers 48 asset IDs, seven groups, three views per sheet, four palettes per asset, units/tier fields, linked images and unchanged approved lighting values. Phone-size gallery and representative specification exports are checked for image loading and overflow. PNG sheet exports preserve the same layout as the HTML.

The infrastructure is generic and contains no geographic input dataset. Visual style references include OSM-derived house renders; retain their [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright) attribution in this pack. The kit does not grant extra rights to any future map, imagery or third-party data source. No git operations or unrelated folders were created.

Final checks: 48 artworks and 48 full specification PNGs; 48 loaded images and 144 view labels in a 390 px phone viewport, with 390 px document width and no script errors. The shared lighting object passes exact equality against the approved pack. All artwork was visually reviewed after targeted corrections. Runway paint in perspective remains illustrative; threshold-bar counts must use the structured twelve-bar rule rather than be traced from the image.
