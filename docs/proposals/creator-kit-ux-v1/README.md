# WorldEngine Creator Kit UX v1

Open `index.html` in a browser. No install, account, network dependency or git is required. `screen-boards.html` presents all ten screens; PNG boards and individual screens are included.

## Interaction flow
1. **Start:** enter a place and select Race village, Wedding, Farm visit, Open house or Campus event. Create opens Simple mode. Search and templates establish the intended flow; the example scene remains Lakeview.
2. **Simple:** click or tap a kit part to add it; desktop also supports drag from the tray. Drag placed objects to move them, snapping to a 2% screen-space grid. Keyboard arrows move focused items; Delete removes one. Draw route enables successive world taps; Finish exits drawing. Undo restores the last placement or route change. Time, weather and camera zoom demonstrate view controls.
3. **Assistant:** two water-table placements appear as outlined previews. Accept adds them, Discard removes the preview, Undo restores the prior plan. Type a request and Preview to create another sample proposal. The sun suggestion proposes a tent placement. Voice uses browser speech recognition where supported and permission is granted; type instead when unavailable.
4. **Advanced:** switch scenarios, show or hide kit and route layers, inspect coordinates/dimensions, select import files, preview a camera animation, and inspect bindings, team roles, versions and analytics. Return to Simple with the back link.
5. **Share:** review guest access, copy a local Viewer link or inspect embed markup. No public publishing occurs. Embedding requires hosting these files at a URL.
6. **Viewer:** the shared-link concept exposes destinations, route and environment without editing controls. Destination buttons highlight a place; Show route highlights the sample path.

## Visual direction and reference provenance
The calm ivory/sage interface keeps the existing rich Style B street artwork dominant. The backdrop is copied unchanged from `house-contrast-v1/images/postcard-hero.png`: brick massing, recessed glass, trim, stoops, mature irregular tree crowns, blue sky, neutral roads and cool shade. `house-archetypes-v1/README.md` informed silhouette/detail priorities and regional consistency. No new architectural rendering or approval claim is made. Reference assets were read only. No dogs, people, host-app content, real brands or logos were added.

Kit illustrations are small authored SVG parts over a reference image. This is a UX prototype, not a navigable 3D renderer. Screen-space snapping is not surveyed placement. Camera zoom is a 2D demonstration. Weather and time treatments are visual samples, not solar calculations or live forecasts. AI responses and shade suggestions use deterministic samples, not reasoning about terrain. Station spacing every 2 km requires route-distance processing in production. Imports are selected but not parsed; coordinates and dimensions are demonstrated without geographic transforms. Building/tree layers are baked into the artwork. Roles, versions, analytics and data bindings demonstrate UI states without service integrations. State is session-only and resets on reload. Copied links do not carry edits or persist a plan.

## Screens and boards
- `screens/desktop-*.png`: all five modes at 1440 × 960.
- `screens/phone-*.png`: all five modes at 390 × 844; Start scrolls naturally.
- `desktop-board.png` and `phone-board.png`: labelled overview boards.
- `screen-boards.html`: zoomable, portable screen gallery.

## Validation
Browser export verified all ten screens load without JavaScript errors or document horizontal overflow. Checked kit add/undo, route drawing, AI acceptance/undo and share dialog. Phone and desktop screenshots were inspected. Live services, real GIS/3D integration and device performance are outside this design prototype.
