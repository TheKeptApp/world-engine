# Status

**R approved – 2026-10-08.** Approved for the Builder phase.

**Owner lane:** Builder, P2. **Phase:** Builder phase (after the engine look gate).

A library of 17 generic, reusable place archetypes (6 stadiums, 2 venues, 3 campuses, 6 event grounds), each drawn as a base place, the same camera on event day, and an aerial planning view, plus a shared temporary event kit of tents, barriers, a small stage and blank signs.

Binding rules from the pack:
- No logos, team, school or sponsor names, mascots, readable signs, dogs, featured characters or identifying faces. Event signs are blank panels (1.2 x 0.8 m, no content). Crowds are small anonymous adult figures only (owner clarification), in event and aerial views; the base view has no event crowd, only incidental passers-by.
- Real scale: proportions real, surfaces simplified, light soft. Never enlarge people or props for visibility. Site envelopes (260 to 1200 m long) and mass heights (8 to 68 m) are authored proposals; actual venue footprints and heights override.
- Event kit sizes (proposed): small tent 3 x 3 m, peak 3.2 m; large tent 6 x 6 m, peak 4.2 m; barrier 2 m long, 1.1 m high; small stage deck 8 x 6 m, 1 m high, canopy 5 m; start/finish truss span 12 m, height 5 m, fitted to the real road.
- Permanent place and temporary event overlay are separate layers; the base is immutable. Persist transforms against real street and terrain coordinates. Keep gates, circulation, accessible routes, service connections and through paths clear. Never place in water or dunes; resolve ground contact; avoid building and tree intersections.
- Light is the shared clear mid-afternoon block (sun 40 deg, azimuth 225 deg, +0.35 EV applied once, contrast 1.06, saturation 1.08, no extra warmth). Where images and numeric sky values disagree follow the images: clear blue sky, soft white clouds. Live sun and weather override the fixture.
- Detail follows projected extent: under 6 px silhouette and land cover; 6 to 20 px massing, plaza layout, event clusters; over 20 px gate recesses, roof forms, resolvable overlay shapes. Roof state is a parameter (only the closed domed roof is drawn). No capacity, egress, code or permit claim; a preview is not permission.

Authored or unverified: (1) All site and height envelopes, event-kit sizes, palettes and tier thresholds are authored proposals, not surveyed, certified or image-measured. (2) The three views per archetype are AI broad-framing consistency only; same-camera correspondence and geometry across views are unverified, and aerials show planning intent, not cadastral plans. (3) Lighting match to the master is numeric; pixel, colour and photometric equality are not measured (flag is false), and the inherited anchor file identity ('approved paintover number 5') is unresolved. (4) The pack itself requires, before engine use: consistent geometry across views, verified street and terrain anchors and scale, collision checks, then accessibility, evacuation, structural and permit review by professionals. None done; no meshes, animation or performance data exist.

Flags for R:
- style-b-calibration-v2 STATUS: its sky stops (the same pale values as this pack's sharedLighting: #73A5CC, #A2C4DC, #DBDCD1) were corrected from its frames to zenith #7AAFE2, mid #8FBAE7, horizon #A0C8F2 under R's images-beat-JSON rule (originals in Tools/lookloop/mock-corrections.json). The venues README already says follow the images, so use the corrected stops and do not compile this pack's sky numbers.

Not compiled into `mock-values.json`: this content is for the Builder phase, and the engine stays generic (CLAUDE.md).
