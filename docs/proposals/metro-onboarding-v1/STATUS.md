# Status

**Delivered 2026-10-08 (R): filed, not a binding target.** Research and design reference; no approval is implied.

**Owner lane:** P1. **Phase:** City-kit checklist (onboarding).

ChatGPT onboarding research for four US metros: eight proposed 1.5 km test areas, 61 dataset and licence rows, 31 licence quotes, look notes and four block-mix paint-over mocks.

Rules the pack states:
- Observed footprints, elevations and reliable height fields override procedural defaults; never use parcel boundaries as building footprints; reject zero, null and placeholder heights before extrusion.
- OSM and Overture buildings are ODbL: keep attribution and share-alike duties; Overture is not a permissive escape; deduplicate against OSM so buildings are not doubled.
- Licence ratings: GREEN is an affirmative grant, YELLOW needs clarification, RED is restricted without consent; resolve YELLOW rows in writing before distributing; a portal URL or access disclaimer is not a licence.
- Omit logos, exact public-art replicas and branded landmarks (for example Space Needle branding) until cleared; a landmark listing alone does not prove a depiction ban.
- MTA data must go through WorldEngine's server with a notice when realtime lag exceeds one minute; never draw inferred subway positions as measured street-level vehicles.
- Skies and vegetation follow live weather and species: no permanent orange Phoenix haze, no default lake-effect for NYC, Seattle dry summers; every named view is a candidate camera target unless an official viewpoint is cited.

Unverified or authored only: (1) All eight boxes are approximate 1.5 km proposals, not surveyed boundaries; skyline and landmark visibility and occlusion are untested in WorldEngine. (2) OSM and Overture building coverage and height, levels and roof-tag completeness per box: no counts were run, no local percentages. (3) Licences: 40 of 61 dataset rows are YELLOW and 3 RED; no dataset was downloaded and most sizes are unclear. Phoenix footprints and 3D, Valley Metro GTFS-RT, LA Metro feed terms and Seattle SDOT and Assessor reuse remain unresolved. (4) Lidar and terrain project dates, quality and tile coverage inside the boxes (3DEP, NYC 2017, Washington DNR).

Where it differs from R's decisions, or needs a lawyer:
- Needs written clearance or a lawyer: 40 of 61 dataset rows are YELLOW (city, assessor, transit, lidar terms) and 3 are RED (LA Metro logos and art, Phoenix GIS Landbase package, Phoenix website text and photos); resolve before affected data ships.
- ODbL (OSM and Overture): how tile and mesh packaging is classified under share-alike needs review before sublicensing.
- Trademark and public art: Space Needle likeness and branding, NYC and Seattle public art and logos need separate treatment.
- Transit terms: MTA needs server-mediated access; LA Metro (Swiftly vendor terms), Valley Metro and Sound Transit terms are unclear or conditional.
