# First 12 verification results

**Research date: 7 October 2026. Proposal and evidence register; no assets built.** This follows the first twelve entries by build order in the original [verify-first.md](verify-first.md). The original README, CSV and queue remain unchanged.

## Result and meaning of status

All twelve exact OSM identities were matched by Wikidata ID. Each selected way is a closed ring and all referenced nodes were present in the retrieved public OSM map extract. This verifies source geometry availability, not survey accuracy, complete building parts, current roof form or a releasable mesh. USGS catalogue queries returned a lidar tile intersecting a small search box at each original coordinate; selected project/tile identifiers are below. No LAZ roof returns were downloaded or measured. Full asset bounds may need neighboring tiles.

**VERIFIED** means the checked identity/source item is supported. **CHANGED** means new evidence changes the original modeling input or scope. **UNVERIFIABLE IN THIS PASS** means a required item remains unresolved, not that data or rights do not exist. 7 entries are changed; 5 have verified source/identity findings. Every entry still has unverifiable physical measurements and rights items.

OSM extracts came from the ordinary public main API, not the previously timed-out Overpass route. Access failures were never bypassed. Coordinates remain discovery anchors from the original CSV; no survey validation is claimed.

## Shared source and release limits

- **VERIFIED source policy:** [OpenStreetMap copyright and ODbL](https://www.openstreetmap.org/copyright). These extracts are OSM data under ODbL 1.0, with contributor attribution and applicable database obligations. An imagery-source tag does not license that imagery for reuse.
- **VERIFIED discovery:** [USGS API documentation](https://apps.nationalmap.gov/tnmaccess/) and [LidarExplorer](https://apps.nationalmap.gov/lidar-explorer/). Per-place catalogue responses supply the selected tile IDs below. [USGS public lidar registry](https://registry.opendata.aws/usgs-lidar/) documents public access/public-domain data; retain product metadata and check for any separately supplied material. Original [National Map terms](https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map) were checked in the baseline; this follow-up's web request returned an internal error and was not treated as new confirmation.
- **UNVERIFIABLE IN THIS PASS for every tile:** exact acquisition interval, horizontal/vertical CRS and datum, point density, usable roof classifications, complete footprint coverage and roof-height extraction. Catalogue publication date is not acquisition date. Chicago project labels include 2016 and a Cook 2017 path; reconcile metadata before assigning a capture year. Denver uses the catalogue's DRCOG 2020 project rather than the older 2008 return. Miami uses the Miami-Dade D23/LID2024-labelled project; the label alone is not a verified collection date.
- **VERIFIED legal framework, individual outcome UNVERIFIABLE:** [Copyright Office Circular 41](https://www.copyright.gov/circs/circ41.pdf) distinguishes architectural design from drawings and identifies date-dependent protection. [17 USC 120](https://www.govinfo.gov/content/pkg/USCODE-2024-title17/html/USCODE-2024-title17-chap1-sec120.htm) must be evaluated for the actual interactive/distributable asset use. Building age, a heritage listing and an open data licence do not establish permission for every component. No comprehensive trademark search, owner permission or legal determination was obtained.
- **USER RULE:** no logos, ads, team/university/sponsor marks, public artworks or replicas. Cloud Gate and Chicago Picasso remain reference only and never built. Historical source photos, drawings and campus maps are reference evidence, not licensed model/texture inputs.
- **ASSUMPTION / proposed build convention:** snapshot date 2026-10-07 unless a separately versioned historical recap requests otherwise. Use measured footprint and ground-relative roof elevations, separate roof/antenna/finial endpoints, then stylize material and detail while preserving scale. Do not convert floors to metres as if measured.

## Effort-register interpretation

[build-effort.csv](build-effort.csv) covers all 100 original rows, including the two excluded artworks. Ratings are assumptions for a modeling agent after source availability and rights questions are resolved: **low** means a single simple reusable mass; **med** means an articulated but repeatable building or bounded landscape; **high** means multiple buildings, complex shells, terrain/corridors or substantial component coordination. No hours or throughput are calibrated. A rating does not promise automatic generation. No candidate in this selection currently merits low effort under those definitions. Excluded artworks use n/a, not zero effort.

The first twelve have exact OSM and lidar catalogue references; all other rows are proposed geometry/height routes, explicitly UNVERIFIED. Each row separates broad aerial silhouette from necessary street facade detail. Color/recognition cues are art-direction assumptions rather than verified material measurements. Campus boundary routes are described in [campus-scopes.md](campus-scopes.md).

## Findings

### 1. LM001 — Willis Tower: CHANGED

**Verified footprint/boundary:** [OSM way 380868216](https://www.openstreetmap.org/way/380868216); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud IL_4_County_QL1_LiDAR_2016_B16 LAS_17258975](https://www.sciencebase.gov/catalog/item/64828f01d34ef77fcafcbbf8), product ID `64828f01d34ef77fcafcbbf8`, catalogue publication 2019-08-19. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM parent has no height. CTBUH: 442.1 m architectural; 527 m tip.

**Finding (CHANGED):** The tower footprint is available, but the current base must include the renovated Catalog podium. The owner's history dates completion of the renovations to 2022; the selected Chicago lidar project is older. Sources: [primary identity/history](https://willistower.com/about), [additional evidence](https://www.skyscrapercenter.com/building/id/169); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Separate tube setbacks, roof, antenna tips and modern podium. Obtain newer open evidence for the podium; confirm architectural-height endpoint before fitting roof returns.

**Unverifiable in this pass:** Historic tower and modern podium require separate component reviews; neither is cleared. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 2. LM021 — Colorado State Capitol: CHANGED

**Verified footprint/boundary:** [OSM way 34008043](https://www.openstreetmap.org/way/34008043); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud CO_DRCOG_2020_B20 w0501n4398](https://www.sciencebase.gov/catalog/item/61c5749cd34e2ca389dbb33f), product ID `61c5749cd34e2ca389dbb33f`, catalogue publication 2021-12-23. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM height=23 m on main footprint; legislature gives 272 ft = 82.9056 m ground to dome top.

**Finding (CHANGED):** A single 23 m extrusion would omit the dome. The source values are verified; the interpretation of the OSM tag as a base-only value is an inference, not a surveyed component measurement. Sources: [primary identity/history](https://content.leg.colorado.gov/sites/default/files/images/capitol_building_at_a_glance-accessible.pdf); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Fit wings, drum and dome separately. Use 82.9056 m only for the documented dome-top endpoint; verify base and drum dimensions from open measurements.

**Unverifiable in this pass:** Original building history is documented; design protection, later alterations and decorative rights remain unverified. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 3. LM033 — Freedom Tower (Miami): CHANGED

**Verified footprint/boundary:** [OSM way 290629021](https://www.openstreetmap.org/way/290629021); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud FL_MiamiDade_D23 LID2024_318451_0901](https://www.sciencebase.gov/catalog/item/68b8e541d4be0247d9626c6c), product ID `68b8e541d4be0247d9626c6c`, catalogue publication 2025-09-02. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM 84.5 m; CTBUH architectural 86.3 m; museum history 289 ft = 88.0872 m. Conflict unresolved.

**Finding (CHANGED):** The institution confirms a 1925 building and a 2025 reopening after restoration. Three published/tagged heights disagree. No average is justified; the measurement endpoints have not been reconciled. Sources: [primary identity/history](https://moadmdc.org/freedom-tower/history-of-the-freedom-tower), [additional evidence](https://www.skyscrapercenter.com/building/freedom-tower/18895); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Resolve height endpoint using a section or ground/roof lidar measurement. Compare restored exterior with the earlier catalogued project; do not substitute OSM ele for building height.

**Unverifiable in this pass:** Review legacy architecture and restored components separately; no modern restoration permission established. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 4. LM007 — Chicago Water Tower: CHANGED

**Verified footprint/boundary:** [OSM way 130147025](https://www.openstreetmap.org/way/130147025); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud IL_4_County_QL1_LiDAR_2016_B16 LAS_17509050](https://www.sciencebase.gov/catalog/item/64828d2fd34ef77fcafcabfa), product ID `64828d2fd34ef77fcafcabfa`, catalogue publication 2019-08-19. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM 55.4 m; HABS describes a 154 ft (46.9392 m) central stone tower. Endpoint conflict unresolved.

**Finding (CHANGED):** The OSM tower is distinct from the pumping station. HABS provides a primary historic description; the difference between the stone tower and total roof height may explain the height discrepancy, but this pass does not prove that. Sources: [primary identity/history](https://tile.loc.gov/storage-services/master/pnp/habshaer/il/il0000/il0097/supp/il0097supp.pdf), [additional evidence](https://webapps1.chicago.gov/landmarksweb/web/districtdetails.htm?disId=23); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Model the Water Tower only. Reconcile stone, roof and finial endpoints against measured elevations; do not merge the pumping station footprint.

**Unverifiable in this pass:** Historical record does not clear all ornament or later changes; current protection remains unverified. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 5. LM026 — Daniels & Fisher Tower: VERIFIED

**Verified footprint/boundary:** [OSM way 36729544](https://www.openstreetmap.org/way/36729544); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud CO_DRCOG_2020_B20 w0499n4399](https://www.sciencebase.gov/catalog/item/61c57350d34e2ca389db9ed7), product ID `61c57350d34e2ca389db9ed7`, catalogue publication 2021-12-23. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM 100 m; CTBUH 99.1 m architectural and 113.4 m to tip. Different endpoints must remain distinct.

**Finding (VERIFIED):** The matched OSM footprint and historic tower identity are verified. CTBUH distinguishes architectural and tip heights. The historic clock-tower mass is a build candidate; projected artwork is outside scope. Sources: [primary identity/history](https://historicdenver.org/daniels-and-fisher-clock-tower/), [additional evidence](https://www.skyscrapercenter.com/building/daniels-fisher-tower/17101), [scope/change evidence](https://www.denvertheatredistrict.com/night-lights-denver); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Preserve clock-stage openings and roof silhouette; measure the tower body separately from the tip. Omit Night Lights projections.

**Unverifiable in this pass:** Historic status is not asset-use clearance; projection works excluded. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 6. LM041 — Lummus Park (Miami Beach): VERIFIED

**Verified footprint/boundary:** [OSM way 76677464](https://www.openstreetmap.org/way/76677464); closed ring with complete referenced nodes in the retrieved extract. This is a park area, not a building footprint.

**Verified catalogue availability:** [USGS Lidar Point Cloud FL_MiamiDade_D23 LID2024_318455_0901](https://www.sciencebase.gov/catalog/item/68b8e524d4be0247d9626b6c), product ID `68b8e524d4be0247d9626b6c`, catalogue publication 2025-09-02. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** N/A for park boundary. Terrain, paths and canopy elevations require separate data; do not assign building height zero.

**Finding (VERIFIED):** The Miami Beach parks directory places this Lummus Park between Ocean Drive and the Atlantic, from 5 Street to 14 Place. OSM provides a matching closed park boundary; surveyed current paths and trees are not established. Sources: [primary identity/history](https://www.miamibeachfl.gov/city-hall/parks-and-recreation/parks-facilities-directory/lummus-park/); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Keep Miami Beach distinct from other places called Lummus Park. Validate shoreline/path alignment and terrain; mark generated palms and ground dressing inferred.

**Unverifiable in this pass:** Landscape data licence checked separately from any structures, sculpture or artworks; no comprehensive clearance. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 7. LM019 — 875 North Michigan Avenue: VERIFIED

**Verified footprint/boundary:** [OSM way 31064573](https://www.openstreetmap.org/way/31064573); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud IL_4_County_QL1_LiDAR_2016_B16 LAS_17759050](https://www.sciencebase.gov/catalog/item/64828ab9d34ef77fcafc9488), product ID `64828ab9d34ef77fcafc9488`, catalogue publication 2019-08-19. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM 343 m; CTBUH 343.7 m architectural. Operator quotes 457.2 m including antennae; antenna endpoint agreement unverified.

**Finding (VERIFIED):** Identity and tapered tower footprint are verified. Architectural roof height must be separate from antennas. Large exterior X-braces are the proposed recognition cue, rather than fine window detail. Sources: [primary identity/history](https://www.skyscrapercenter.com/building/john-hancock-center/345), [additional evidence](https://360chicago.com/our-story); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Measure taper/roof and antenna pair separately. Resolve antenna endpoints before using the operator's total height; keep braces broad enough for phone views.

**Unverifiable in this pass:** No building-shape or other trademark clearance; logo-free depiction is not a legal conclusion. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 8. LM042 — Miami Tower: VERIFIED

**Verified footprint/boundary:** [OSM way 300232867](https://www.openstreetmap.org/way/300232867); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud FL_MiamiDade_D23 LID2024_318751_0901](https://www.sciencebase.gov/catalog/item/68b8e58dd4be0247d9626eea), product ID `68b8e58dd4be0247d9626eea`, catalogue publication 2025-09-02. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM height='191 m', levels=47. Owner leasing brochure: 625 ft = 190.5 m, 47 stories; small endpoint/rounding difference unresolved.

**Finding (VERIFIED):** The matched tower footprint and owner identity are verified. The OSM height contains an explicit unit string. The proposed model needs three receding curved tiers and a separate podium, with generic lighting. Sources: [primary identity/history](https://www.miamitower.net/), [additional evidence](https://images2.loopnet.com/d2/4cyRtWd9M6kzII7z7HuZ8i3bVUbPuUHRu_OLC8z5nEo/document.pdf); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Normalize the unit string, then fit tier breaks and podium roof heights; brochure is historical reference, not surveyed geometry or a current materials specification.

**Unverifiable in this pass:** Modern architecture/design and trade-dress status unverified. Branded lighting campaigns excluded. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 9. LM020 — Merchandise Mart: CHANGED

**Verified footprint/boundary:** [OSM way 28293211](https://www.openstreetmap.org/way/28293211); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud IL_4_County_QL1_LiDAR_2016_B16 LAS_17259025](https://www.sciencebase.gov/catalog/item/64828eb7d34ef77fcafcb9a6), product ID `64828eb7d34ef77fcafcb9a6`, catalogue publication 2019-08-19. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM has levels=18 but no height. Owner leasing site describes 25 stories overall; stepped component heights unverified.

**Finding (CHANGED):** The footprint is verified, but the main block and taller central mass cannot be represented by one 18-story extrusion. A floor count is not a measured height. Sources: [primary identity/history](https://martofficespace.squarespace.com/about), [additional evidence](https://www.themart.com/wp-content/uploads/2023/05/MART-ShowroomResidential.pdf); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Extract block, setbacks and center-tower heights. Keep pier/window rhythm at street level; omit Art on the MART projections.

**Unverifiable in this pass:** Review original and altered components; projected artwork excluded; legal status unresolved. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 10. LM027 — Brown Palace Hotel (Denver, Colorado): VERIFIED

**Verified footprint/boundary:** [OSM way 458038539](https://www.openstreetmap.org/way/458038539); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud CO_DRCOG_2020_B20 w0501n4398](https://www.sciencebase.gov/catalog/item/61c5749cd34e2ca389dbb33f), product ID `61c5749cd34e2ca389dbb33f`, catalogue publication 2021-12-23. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM height=44 m and levels=9; physical height unmeasured. Heritage accounts describe eight stories; floor-count reconciliation pending.

**Finding (VERIFIED):** The matched footprint and 1892 opening are verified. Retain the triangular block, recessed entrance, bay rhythm and cornice as proposed recognition cues. The height tag is evidence of a recorded value, not proof of physical accuracy. Sources: [primary identity/history](https://www.historichotels.org/us/hotels-resorts/the-brown-palace-hotel-and-spa-autograph-collection/history), [additional evidence](https://sah-archipedia.org/buildings/CO-01-DV025); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Resolve counted levels and roof/cornice height without guessing a per-story multiplier. Exclude interiors and branded awnings/signage.

**Unverifiable in this pass:** Historic architecture, alterations and trademark uses need separate review; none cleared here. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 11. LM031 — Ball Arena: CHANGED

**Verified footprint/boundary:** [OSM way 25312645](https://www.openstreetmap.org/way/25312645); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud CO_DRCOG_2020_B20 w0498n4399](https://www.sciencebase.gov/catalog/item/61c573acd34e2ca389dba3ec), product ID `61c573acd34e2ca389dba3ec`, catalogue publication 2021-12-23. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM height=22 m; building:parts=yes. Roof profile, part heights and true physical height unverified.

**Finding (CHANGED):** The operator confirms the existing arena identity and 1999 opening. Renovation was announced in September 2026; completion is unverified. Sources: [primary identity/history](https://www.ballarena.com/arena-information/about-ball-arena/), [additional evidence](https://www.nba.com/nuggets/news/ball-arena-to-undergo-massive-renovation); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Freeze the existing exterior at the selected snapshot. Treat the announcement as a change flag, not geometry. Resolve roof/component measurements from dated evidence.

**Unverifiable in this pass:** Modern venue architecture and alterations unverified; omit sponsor graphics, teams and public art. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

### 12. LM010 — United Center: CHANGED

**Verified footprint/boundary:** [OSM way 205221993](https://www.openstreetmap.org/way/205221993); closed ring with complete referenced nodes in the retrieved extract. This is the parent outline; separate building parts were not comprehensively validated.

**Verified catalogue availability:** [USGS Lidar Point Cloud IL_4_County_QL1_LiDAR_2016_B16 LAS_16258975](https://www.sciencebase.gov/catalog/item/64828d19d34ef77fcafcaae0), product ID `64828d19d34ef77fcafcaae0`, catalogue publication 2019-08-19. Candidate height/terrain source only; usable roof returns and acquisition metadata remain unverified.

**Height evidence:** OSM levels=8, no height. Main arena and five-story east addition require separate measured heights.

**Finding (CHANGED):** The operator dates opening to 1994 and the east addition to March 1, 2017. Include the addition only after checking current geometry; exclude the Michael Jordan statue and proposed future district construction. Sources: [primary identity/history](https://www.unitedcenter.com/venue/blueprint/), [additional evidence](https://www.unitedcenter.com/venue/frequently-asked-questions/), [scope/change evidence](https://www.rios.com/projects/united-center-the-1901-project/); checked 2026-10-07. Source values are verified as published or tagged; conflicting physical heights remain unresolved.

**Next build action (proposal):** Check lidar capture dates against the addition; verify its separate footprint and atrium. Keep proposed redevelopment distinct from the present arena.

**Unverifiable in this pass:** Modern arena/addition protection and shape marks unverified; sculpture and all marks excluded. Full current footprint/parts, survey accuracy and roof measurements also remain unresolved. No logos or artworks may be substituted for recognition details.

## Recommended next decisions (assumptions)

1. Resolve the Capitol dome, Freedom Tower and Water Tower height endpoints before modeling true scale. Keep source values and uncertainty rather than averaging conflicts.
2. Use the twelve verified OSM parent rings as initial outlines, then obtain building parts and all intersecting lidar tiles. Validate units, ground elevation, capture date and roof returns before extrusion.
3. Version the Willis podium, Freedom Tower restoration and United Center addition separately from historical cores. Record the Ball Arena change flag without assuming future geometry is built.
4. Prototype one simple tower, one articulated historic building and one park at phone size before calibrating effort ratings in [build-effort.csv](build-effort.csv).
5. Review modern components and distinctive building shapes for the actual distribution use. Keep the original release queue open; this research is not asset clearance.
