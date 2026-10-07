# WorldEngine Creator Kit / UX v2

**Web first. Desktop primary. Tablet capable. Phone optimized for review.**

Open `index.html` directly in a modern browser with WebGL support. Everything needed for rendering is bundled; no installation, hosting, account or network request is required. Start at `#start`. The version-one files remain in the parent folder and are superseded by this folder.

## Deliverables
- `index.html` — interactive 3D prototype; `app.js`, `world.js`, `style.css` and `assets/` are required companions.
- `screen-boards.html` — screen gallery with prototype links and full-resolution images.
- `desktop-board.png` — eight desktop frames at **1440 × 900** each.
- `tablet-board.png` — five tablet frames at **1024 × 768** each.
- `phone-board.png` — six phone frames at **390 × 844** each.
- `component-sheet.html` and `component-sheet.png` — toolbar, library, assistant, Pro drawer, selection controls and share dialog.
- `design-tokens.html`, `design-tokens.png` and `design-tokens.json` — short visual-system reference.
- `screens/` — 19 individual screens in the exact requested sizes.
- `validation.json` — browser QA results.

## Main flow
**AI-first start → draft → edit → Pro → share → guest view**

1. **Describe your event.** The prompt is the primary entry point, with browser voice recognition and three example chips. Place search and the five requested templates are secondary. Build a draft progressively populates the 3D scene, then pauses with highlighted objects. Accept commits the draft; Edit selects a proposal so it can be moved; Undo removes unaccepted previews. Search and template recognition demonstrate the proposed UX without geocoding or actual layout generation.
2. **Edit in one canvas.** The parts library stays left, the assistant stays right, and the central aerial view remains the working surface. There are no Simple/AI/Advanced mode tabs. “Walk it” changes the same 3D camera to eye height. Wheel zoom works in the canvas. The floating toolbar exposes selection, move, rotate, routes, zones, measure and undo/redo. Click a draw tool again to finish a drawing. Selection and movement share the same drag gesture; rotation applies 15° increments.
3. **Add in three ways.** Search or filter the categorized parts library, then click or drag a part into the scene. Objects use metre dimensions and 0.5 m snapping. AI requests produce highlighted proposals with Accept/Edit/Undo; covered-weather and shade moves demonstrate context-aware suggestions. Route, area and measure tools intersect the actual ground plane; route distance is calculated in scene metres and signs are added on segments at 50 m intervals. Areas become translucent ground meshes. “Paths” share the route tool’s geometry; production would distinguish path surface and route semantics.
4. **Arrange precisely.** Click objects to select. Shift-click selects multiple objects. Drag moves the selection with alignment guides; arrow keys nudge by 0.5 m. Duplicate adds copies, Group links a local selection, Align uses a common ground axis, and Repeat creates three copies at the chosen metre interval (default 50 m). Grouped members can be moved together; group IDs are stored locally.
5. **Preview sun and weather.** Scrub event time along the bottom; the directional light and actual object/tree shadows update. Clear/rain changes illumination. Time is displayed in Chicago event time (CDT), independently of the viewer’s device timezone. The scene uses an approximate October solar trajectory at Chicago’s latitude, not a validated astronomical model. Forecast values and shade suggestions are illustrative. Real weather, shading certainty and ephemeris integration remain production work.
6. **Open Pro without leaving the place.** Header toggle opens a dark slide-out drawer with Scene/Data/Team/Publish sections. X/Z position, dimensions, rotation and elevation update actual selected meshes; lat/lon fields are reference metadata. Layer toggles, sun/rain scenarios, dated phases, file selection, camera paths, binding settings, comments, roles, rollback, analytics, embed settings and demo API-key controls demonstrate the requested information architecture. Imports accept GPX/KML/GeoJSON/CAD/DXF/GLB/USDZ for selection but do not parse those formats. Data validation never contacts a supplied URL. Team invitations are not sent. Roles, analytics and API keys do not connect to services.
7. **Share and embed.** Header Share opens a dialog containing the guest link, password and expiry settings, four size presets, iframe code and a partner-site preview. Copy controls and guest navigation work. Passwords and expiry are presented as publishing settings and are not enforced locally. A file URL is a local preview; host the folder at an HTTPS URL for a usable public link. Edits are saved only in the browser’s local storage, not encoded in links or uploaded. Opening the same hosted link on another device does not carry the editor’s local changes.
8. **Guest viewer.** `#guest` opens a mobile-first full-screen 3D guide without editor chrome or account gates. Places, schedule, event weather, camera controls and sample walking directions are available. Location asks for browser permission before showing a demonstration dot; coordinates and directions are a UX demonstration against an illustrative site, not surveyed navigation. Follow event signs and on-site instructions. No editing is available.

## Phone builder
`#review` provides the canvas, selected-object quick moves and Share. `#ai` opens a bottom assistant panel for request/voice review and Accept/Undo. `#comments` shows a localized comment thread. Add opens a bottom library sheet. Full layout work is intended for desktop/tablet, so long lists, precision forms and wide toolbars do not dominate the phone experience. The phone Pro drawer is available for inspection; the primary phone task remains review. Six phone exports cover Start, Review, Assistant, Comments, Share and Guest.

## Visual system & Style B
Warm-neutral paper panels, a sage/forest action accent, soft borders and floating controls frame the world. Typography, colour, spacing, radius and elevation are defined in `style.css` and the token sheets. Pro uses a deep green-grey surface. Icon controls are authored line vectors; **kit parts in the scene are real three-dimensional meshes, never screen-space icon overlays**. Thumbnails are rendered from those same meshes.

Procedural park and house geometry is **reference-inspired and proposed**, not an approved engine rendering or verified depiction of Lincoln Park. The street-edge houses include roof silhouettes, trim, recessed window planes, canopies and steps. Trees use matte clustered canopies with branching gaps. Objects include 6 × 6 m tents, 1.8 × 0.75 m water tables with modeled cups, 2.4 m barriers, an 8 m arch, an 8 × 5 m stage, benches, signs, a generic van, a shade tree and a utility cabinet. The reference packs were read only:
- `house-contrast-v1`: softly warm sun, neutral roads, cool-neutral shade and house-detail authority.
- `house-archetypes-v1`: real massing proportions and silhouette/detail priorities.
- `japan-regional-kit-v1`: smooth matte richness, irregular crowns and metre-based prop envelopes. Its Japanese street dimensions, density and left-hand traffic are **not** transplanted into a Chicago park.

No dogs, characters, host-app content, real brands or logos appear. WorldEngine is the requested product name; Parkside Events is a fictional embed host.

## Implemented vs represented
**Implemented:** actual 3D object placement, metre-based transforms, selection, snapping, multi-selection, duplicate, repeat, alignment, route/zone geometry, measurement, undo/redo for objects and drawings, preview/accept proposals, camera switching, time-driven shadows, local plan storage, weather scenario lighting, comments, share code/copy, guest guide, and a 5-second browser fly-through/video capture where supported.

**Represented:** AI reasoning, place geocoding/terrain ingestion, production weather and timing feeds, verified solar ephemeris and shade analysis, robust accessibility routing, format import/registration, synced teams, published versions, analytics, enforced link passwords/expiry and issued API keys. Voice may use the browser’s speech service and requires permission; all other drafting requests stay local. WebGL and video capture support vary by browser. No device performance or thermal benchmark is claimed.

## Verification
Screen exports use a desktop browser at the three requested viewport sizes. Checked scene rendering without JavaScript errors, document overflow, kit addition, undo/redo, AI proposal acceptance, walk view, Pro transforms, sharing and guest directions. Screens and component sheets were visually inspected. No git, engine repository writes or edits to synced project references were used.

## Bundled renderer
Three.js 0.180.0, MIT licensed. `assets/three.js` is a browser wrapper of the CommonJS build. `assets/THREE-LICENSE.txt` preserves its licence. The prototype works with local files without ES module fetching.
