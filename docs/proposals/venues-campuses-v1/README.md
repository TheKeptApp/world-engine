# Venues + Campuses — Style B V1

Open `index.html` for the searchable board. Each of the 17 archetypes has a three-view artwork, a full annotated PNG sheet and an individual HTML sheet. The board contains 51 concept views.

## Approved references

The Style B Bible calibration street governs grounded proportions and lighting. The Empower Field landmark sheet guides stadium structure and material treatment; infrastructure-kit-v1 governs circulation and detail tiers; house-archetypes-v1 provides the shared lighting values. Reference images take precedence over inconsistent numeric sky values: use clear blue sky and soft white clouds. The reference files were not modified.

## Crowd decision

Owner clarification: “Anonymous simple crowd figures; no featured characters.” Event overlays use small anonymous figures without facial or personal detail. No dogs, mascots, logos, team, school or sponsor names, or readable signs. Base views show the permanent place without event infrastructure; incidental anonymous figures may remain.

## Builder contract

Permanent place and temporary event overlays are separate layers. Persist object transforms against real street / terrain coordinates. Keep gates, ordinary circulation, accessible routes and service connections clear. Respect water and dune boundaries. Tent, barrier, stage and site dimensions in the JSON are authored proposals, not surveyed, certified or image-measured values. Stadium roof state is a parameter; this sheet shows the domed / retractable type closed.

The aerial views communicate planning intent and are not cadastral plans. Before engine implementation, reconstruct consistent geometry across views, verify street/terrain anchors and asset scale, validate collisions, then review accessibility, evacuation, structural loads and site-specific permissions with the relevant professionals. No capacity, code compliance or event approval is claimed.

## Deliverables and limitations

`venues-campus-values.json` stores the inherited lighting block, proposed dimensions and palettes, event components, recognition geometry and detail tiers. `prompts.json` records the generation prompts and reference paths. `images/` contains three-panel AI concept art; `*-sheet.png` and the matching HTML pages add review labels and builder notes. Images approximate the approved appearance; exact photometric equality is not measured. No engine meshes, animation, runtime performance or surveyed reconstruction were produced. No git was used.
