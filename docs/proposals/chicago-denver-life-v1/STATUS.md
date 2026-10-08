# Status

**R approved – 2026-10-08.** Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.

**Owner lane:** P2, 5A, L1. **Phase:** Ambient life layer, after the look gate (test locations Chicago and Denver).

Nine AI-generated image boards plus a data file for everyday street life in Chicago and Denver (vendors, alleys, trains, game days, snow, lake paths): what to show, how many per 100 m, and when it may switch on.

Binding rules from the pack:
- One actor pool: food queues, transit crowds, patio patrons and walkers share it. Never sum all table rows onto one block; clamp to space and the shared city budget.
- Event people replace that site's baseline before the multiplier; never add a second crowd. Game-day crowds need a validated venue start and end plus walkable routes, never a fixed 6pm game or jersey colours.
- OFF by default until a verified schedule, event or history, or a labelled demo, enables them: festival tents, opened hydrants (heat alone never opens one), farmers markets, chairs in shoveled spaces, plows, salt trucks, snow piles, game-day crowds. 10 of 39 records are OFF.
- Season multipliers are allowed-weather eligibility, not proof an event is active. Mapped geometry and schedules win: food fronts, vendors and taverns need eligible sites; poles are mapped only; garbage trucks need a collection schedule.
- Transit and boats stay on mapped routes, tracks, channels and docks with active service: no L in every street, no light rail on the lake path, water taxi is river context only, scooters in permitted lanes only.
- Keep mapped access and at least the authored 1.8 m pedestrian corridor (not a local-code claim). No detailed faces, logos, team marks, brands, readable signs, agency insignia, real murals or public art, dogs, animals on leads or host-app content.

Authored or unverified: (1) All sizes, speeds, 06/12/18/23 h counts, season and game-day multipliers are authored fallback targets (status authored_fallback_unverified on all 39 records); no census, footfall, vendor inventory or pole map was used. (2) Track-level geometry, collection schedules, vendor permits, rooftop features, game times and local poles need independent mapped evidence; none was supplied. (3) Images are authored composites, not surveyed geometry. No meshes, route solver, live crowd or event feed, engine acceptance, legal clearance or device benchmark; the 1.8 m corridor is not a code claim. (4) Lighting: sharedLighting is the inherited master; its anchor approvedFileIdentity is marked UNRESOLVED and its sky stops are the pre-correction JSON values; authored, not pixel-sampled or renderer-calibrated.

Flags for R:
- sharedLighting copies the daytime master verbatim, including pre-correction sky stops (#73A5CC, #A2C4DC, #DBDCD1) that the repo's compiled look already corrects from images (calibration v2 to #7AAFE2, #8FBAE7, #A0C8F2). It is not a look source; say 'copied lighting block not compiled', as the infrastructure-kit-v1 STATUS does.
- Board finish is near-photographic: panels such as the beef counter and the paleta and tamale vendors show readable facial features, and close food panels show photographic texture, richer than calibration v2's matte, no-photo-texture look and non-identifying near tier. R's decision gives look to calibration v2, so use the boards for content only.
- Count face is 100 m of one side here; nyc-life-v1 counts per 150 m. One actor pool across packs needs a single unit.
- README calls the Bible calibration street and Empower Field 'approved'; INDEX still lists style-b-bible-v1 and landmarks-style-b-v1 (both in referenceManifest) as pending R approval. house-archetypes-v1 is approved.

Compiled into `mock-values.json` under `style-b/life-chicago-denver` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). Game-day and event keys carry `gatedBy: events-off-unless-verified`.
