# Creator Kit UX v3 — Easy + Pro

Open [index.html](index.html#mode) for the mode choice, or [screen-boards.html](screen-boards.html) for the complete design sheets. Race villages are the lead use case. The package is saved independently; v2 is preserved untouched at `../creator-kit-ux-v1/v2/`.

The decision changes v2’s single canvas and Pro drawer into **two presentations of one plan**. Easy is guided and works on a phone. Pro is a dedicated desktop workspace. Both keep the same place, object IDs, dimensions, positions, selection, event date, versions and share settings. Switching to Easy changes the controls; it never replaces precise Pro values or silently generates a new layout. A shared client view contains a read-only version snapshot.

## Sheets

1. Mode choice and switching — Easy recommended first; Pro stays one tap away.
2. Easy flow — eight screens, exported separately for desktop and phone: place/upload → confirm site → event details → AI proposal → adjust → sun/weather → final look → share.
3. Pro workspace — part library, exact metre fields, rotation, local X/Z, snapping, locked base-map layer, event layers, measurement, service envelopes, event-time sun controls, versions and export.
4. Shared client view — read-only layout, version, place/date, walkthrough, places, event weather and review note.
5. Race village — six tents, start/finish chute, small stage, toilets and proposed parking/service area. Village first; full course planning can follow.
6. Outdoor wedding — ceremony chairs/aisle, reception tent, catering and screened toilets.
7. Unbranded activation — pavilion, demonstration tents, presentation stage, queue and service access.
8. Six-segment template sheet — races, weddings, concerts, experiential marketing, stadiums/venues and brands.

Each sheet has HTML and export PNG companions. `screens/` contains eight Easy desktop captures and eight Easy phone captures plus mode, Pro, versions, export, shared-view and example screens. `images/` holds eight Style B world studies and `prompts.json` the exact built-in imagegen inputs and hashes.

## Easy behaviour

Big buttons and plain words take the organizer from an existing site map or place choice to a proposed layout. Site confirmation appears before layout generation: use three visible anchor points and one known distance; uncertain registration needs a correction path. The design does not turn map upload into an automatically trusted location. AI suggestions remain a proposal until “Use this layout.” Individual changes use tap, move, turn, remove and undo; adding a part remains optional.

No CAD words, layer list, axis fields or service-envelope settings dominate Easy. Event details ask only date, time, people and a short note. Review keeps the practical item list visible. Sharing creates a version snapshot rather than exposing the private editor. A later edit does not mutate the previously shared layout.

## Pro behaviour

The desktop workspace keeps library/layers on the left, the world in the middle, and the selected part’s dimensions on the right. Part sizes and local coordinates use metres. Snapping offers 0.1 / 0.25 / 0.5 / 1 m. The service envelope is an editable planning allowance: footprint plus a margin on all sides, with supplier-provided values taking priority. It is not a clearance certification. A locked verified place layer stays separate from customer event parts.

Named versions support restore without throwing away the current plan. Exports include the layout data and a parts list; scaled PDF/CAD and georeferenced output are specified production features. Brands use reusable part palettes and layouts across sites; venue teams use repeatable event versions. These are the same primitives, not six separate editors.

## Shared view and weather

The client receives a read-only snapshot, a clear version label and event date/time. “At event time” and “Weather now” are separate views. A real implementation must compute sun from latitude, longitude, date and time zone; weather must show its source, issue time and valid time. Beyond the forecast horizon, use explicitly named scenarios, never invented forecasts. Place geometry and event overlays remain separate. Client notes require separate permission from viewing; a shared link alone never grants editing.

## Visual system

The warm paper and forest-green interface evolves v2’s visual tokens. Easy’s large controls and short prompts are deliberately quieter than Pro’s dense inspector. The eight selected world artworks reference `style-b-calibration-v2/frames/06-sloans.png` for look only; event geography and layout are illustrative. `world-look-values.json` inherits calibration v2’s `sharedLook` unchanged: matte simplified albedo fields, broad glazing, natural generic proportions, warm direct/cool fill light and projected-size detail bands. No logos, real brands, dogs, public art or unrelated app/host imagery appear in the world.

## Implemented and represented

This is a **UX design package and local click-through**, not an integrated WorldEngine build. The world viewports use raster visual studies rather than a live 3D renderer. Exact UI text and touch targets come from HTML, not generated screenshots of text.

Working locally: mode/step navigation; all six template choices; event details; file selection and filename feedback; proposal acceptance; selection; changes to stored part position/size/rotation; add/remove/duplicate/undo; snapping arithmetic; layer/envelope UI; local versions/restore; JSON and parts-list export; immutable read-only preview links with encoded plan snapshots. These operations update the plan and inspector/selection guide. **Raster world geometry does not rebuild to reflect edited part data.**

Represented design intent: geocoding, site-map parsing and registration, AI layout generation, real 3D placement/snapping/measurements, service collision tests, terrain and map ingest, astronomical shadows, live weather, cloud publishing, permissions, guest notes and surveyed exports. Time sliders change the selected time label; they do not recalculate shadows in the raster image. Sun/rain switches select example visual scenarios. No real people, fleets or venue operations are inferred. No network calls, messages, accounts, invitations or publications occur.

The local preview link includes its snapshot; treat it as visible data, not a secret/protected plan. It is a file link, not a public hosted URL. Production sharing must enforce access controls server-side and use a hosted URL. Local saving is only browser storage. PDF selection does not parse the uploaded file; georegistration is shown as a proposed screen.

## Verification

[validation.json](validation.json) records screen and layout checks, mode preservation, exact-value editing, undo, versions, snapshot isolation and local exports. Phone checks cover 320 and 390 CSS pixels, with tablet width checked at 768 and desktop at 1440. Preview screenshots are in `phone-check/`. Browser verification is for UX and local data behaviour, not engine/device performance, physical clearance or production weather accuracy.

No git. No files were written to the world-engine project or its docs/proposals.
