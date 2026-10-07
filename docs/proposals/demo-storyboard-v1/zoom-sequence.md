# Signature take Z — continuous Miami zoom and return

The contact-sheet ladder shows keyframes, not edits. Engine release is a single camera take. Shots 15 and 16 are production annotations within it. The three cuts use separately rendered trajectories with the same anchor and path, rather than jump-cutting intermediate levels.

| Camera phase | 90s master | 30s cut | 15s cut |
|---|---|---|---|
| Street | 64–65s | 13–14s | 5–5.5s |
| Neighbourhood | 65–67s | 14–15.5s | 5.5–6.2s |
| City | 67–69s | 15.5–17s | 6.2–7s |
| Region | 69–71s | 17–18.5s | 7–7.8s |
| Continent | 71–74s | 18.5–20s | 7.8–8.6s |
| Globe | 74–77s | 20–21.5s | 8.6–9.3s |
| Orbit / eased reversal | 77–80s | 21.5–23s | 9.3–10s |
| Return: orbit → globe → continent → region → city → neighbourhood → street | 80–88s | 23–28s | 10–13s |
| Home close hold | 88–90s | 28–30s | 13–15s |

Use a smooth camera spline with ease-in at street and zero velocity at reversal and final settle. Interpolate distance logarithmically so passage through each representation band remains perceptible. All scale levels pass continuously in both directions. The return tables give a shared interval; distribute it smoothly over the same reverse ladder, with no hidden cut. Hold final camera exactly for the closing two seconds.

Scale/style authority: street-to-space-v1 active frames 01–07 day/night and values.json. Illustrative altitude fixtures (not calibrated camera measurements): street 0.0017 km, neighbourhood 0.6, city 12, region 150, continent 1800, globe 12000, orbit 70000. Use the overlapping presentation bands from that pack, projected-size LOD and actual camera geometry; these are ladder cues, not a claim of matching AI frame altitudes.

Anchor is the selected Miami home street, with exact WGS84 coordinates and home camera recorded at capture. No coordinate is invented in this package. At city scale show Miami/Biscayne coast; at region South Florida/Everglades/Atlantic; at continent Florida in North America/Caribbean. No Denver lake or Rockies transferred into Miami. Details aggregate: houses → blocks → urban fraction → categorical land cover. Coastline and world do not move under the camera. Parent coverage remains until child tiles are complete; no blank tile flashes, opaque pop or doubled overlapping cities.

One fixed controlled UTC and world-space sun govern street shadows, cloud tops and globe terminator. Choose an engine fixture with Miami in clear mid-afternoon and westward portions of the visible hemisphere in night; do not animate local time to make the globe night. The approved globe palette/material style is authoritative; incidental sun orientation or example city in those references does not override Miami georeferencing. City glows fade through twilight, remain on night-side land and never cover ocean or sunlit regions. Use diffuse warm clusters informed by NASA Black Marble, no sharp photo radiance grids, no current-night observation claim. Cotton cloud field and exposure adapt coherently; no planet swap or live-state assertion.

One thin orbit line and a small schematic marker remain at globe/orbit. Calculated satellite position requires source orbital elements, epoch and computation time. Marker size is graphical, not physical vehicle scale. Titles and source labels may be composited; geometry, LOD, atmosphere, clouds, terminator, city-light field and complete camera motion require engine rendering.

Release check: run each cut end-to-end as one capture; verify no edit at 15/16 boundary, stable anchor, coherent sun, no LOD pop, true-scale grounding, legible return and no dog/characters/logos. Concept keyframes are not evidence of continuity. If engine cannot do this, block release of the signature claim rather than replacing it with a dissolve.
