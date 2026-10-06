# Postcards

WorldEngine renders a framed postcard of the world from one camera pose at three sizes and three frame styles. The world is drawn offscreen at each postcard's own picture size with the same grade and bloom as on screen, the host's text block goes above it, and the credits are burned in below it. Spec (read-only input): `docs/proposals/postcards-widgets-v1/` (frame studies `frame-<style>-<size>`, `one-page-spec`). Widgets are not covered here.

## API

```swift
let request = PostcardRequest(
    text: PostcardText(placeName: "Evanston", localTime: "Oct 6, 2026 · 2:30 PM CDT",
                       condition: "Clear", temperature: "72°F", demoLabel: "Demo"),
    weather: .demo,                       // or .live(credit:markLight:markDark:)
    sizes: PostcardSize.allCases,         // square, portrait, story
    styles: [.classic],                   // bold, classic, minimal
    post: livePost.settings)              // the on-screen grade and bloom; nil for none
let postcards = try await world.exportPostcards(pose: pose, request: request)
for p in postcards { try p.pngData().write(to: folder.appendingPathComponent(p.fileName)) }  // postcard-<style>-<size>.png
```

| Type | Where | What |
|---|---|---|
| `World.exportPostcards(pose:request:)` | WorldEngine `PostcardExport.swift` | Renders and frames every requested size × style. One export at a time (`.busy` otherwise). |
| `PostcardRequest` | WorldEngine | Text, weather, sizes, styles, `appearance` (nil: night when the sun is below −6°), `composedAspect` (16:9), `post`, `includeCharacters` (default false). |
| `PostcardImage` | WorldEngine | `image` (`CGImage`, 1080 px wide, sRGB), `pngData()`, `fileName`, the reframed `pose` and the `layout`. |
| `PostcardText`, `PostcardWeather`, `PostcardSize`, `PostcardStyle`, `PostcardAppearance` | WorldGen `Postcards/PostcardFrame.swift`, re-exported by WorldEngine | Plain data from the host. |
| `PostcardFrame.layout(...)`, `.compose(...)`, `.pngData(_:)`, `.imageCredits(...)` | WorldGen | The frame: renderer-neutral CoreGraphics/CoreText, unit-tested on the Mac. |
| `CameraPose.reframed(forAspect:)`, `PostcardReframe` | WorldGen `Postcards/PostcardReframe.swift` | The reframing rule. |
| `CreditBurnIn.block(for:...)`, `CreditBurnIn.burn(_:block:color:mark:)` | WorldGen `CreditBurnIn+Block.swift` | P1's burn-in helper, extended with a credit block for framed exports. |

## Sizes, styles and type

| Size | Canvas | Safe area (type, credits, picture) |
|---|---|---|
| square | 1080 × 1080 | the style's margin from every edge |
| portrait | 1080 × 1350 | the style's margin from every edge |
| story | 1080 × 1920 | margin left and right; 240 px top and bottom kept free (spec: "Story reserve 240 px top/bottom") |

| Style | Margin | Day plate / type | Night plate / type |
|---|---|---|---|
| bold | 32 px | `#152F38` / white | same |
| classic | 55 px | `#F5F0E5` / `#303942` | `#2A2724` / white |
| minimal | 32 px | white / `#303942` | `#16191D` / white |

Day colours and margins are the frame studies'. Night scenes (sun below −6°, or `appearance: .night`) get white type on a quiet, opaque dark plate (spec: "Night text white on a quiet opaque plate"); every combination has a contrast ratio of at least 7:1 (tested).

Type is the system font (SF on Apple platforms) at 2 px per point, the scale of the frame studies: place name 27 pt (54 px) bold, in capitals, shrinking to 20 pt before it is cut with "…"; details ("local time  ·  condition · temperature") 15 pt (30 px) with tabular figures; the host's optional label (e.g. "Demo") 11 pt bold in an outlined capsule after the details; credits 12 pt (24 px), shrinking to 11 pt before a line wraps. Credits never truncate.

Layout, top to bottom inside the safe area: place name, details, the picture, credits. The picture takes all the height left between them, so live weather (more credit rows) gives a slightly shorter picture than Demo weather. The picture is a whole number of pixels and is rendered at exactly that size.

## Reframing

Composed postcard poses are scored in a 16:9 frame at 50° vertical FOV. Each postcard picture is rendered separately for its own aspect ratio; none is a crop. The rule (`PostcardReframe`): **same eye, same look-at point, same diagonal field of view as the composed frame.** A narrower picture trades some width for height instead of losing the sides, so landmarks at the edges of the composition stay in frame, and the look-at point keeps the horizon where the composer put it. The vertical FOV is capped at 75°. The square picture keeps over 95% of the composed horizontal field; the narrowest picture (classic story, about 0.8 wide per 1 high) keeps about three quarters (tested: at least 75% on every size and style).

## Attribution (burned into every image)

| Credit | When | Drawn as | Source |
|---|---|---|---|
| `© OpenStreetMap contributors · openstreetmap.org/copyright` | always, first line | P1's credit line from `Profiles/credits.json`, via `CreditBurnIn` | CLAUDE.md; decision 6c (no credit-free exports); one-page spec "Attribution": "© OpenStreetMap contributors stays visible whenever world imagery appears" |
| Other manifest sources (e.g. Overture) | when their licence asks for credit | their own attribution lines (`CreditsCatalog.merged`) | decisions 6a–6c |
| Weather provider mark | live weather | the image the host loaded from WeatherKit's `combinedMarkLightURL` (light plates) or `combinedMarkDarkURL` (dark plates), 14 pt high, aspect kept, colours untouched | one-page spec "Attribution": "Use official Apple Weather combinedMarkLightURL / combinedMarkDarkURL, unmodified and proportional" |
| Legal page as readable text | live weather | the host's `legalPageURL` without its scheme, beside the mark | one-page spec: "Static images print a readable legal URL" |
| "Weather visualization modified from Apple Weather data." | live weather | the provider's modified-data notice (the standard wording when the host gives none) | one-page spec "Weather transformation" |
| "Demo weather" | Demo weather | a small outlined label where the mark would be; no provider mark | brief for this feature; experience-v1 (Demo weather is always labeled) |

The engine never bundles or draws a provider logo of its own: marks are runtime inputs (`PostcardWeather.live(credit:markLight:markDark:)`). Credit wording comes from P1's credits data and is not changed here. The share page that travels with an image (spec: "travel with a linked detail page") is host work.

## Offscreen rendering

RealityView has no offscreen API, and an entity can belong to only one scene. Moving the live world's root entity into a second renderer would pull it out of the live view's scene: RealityKit stops a host character's animations when its entity leaves a scene, rain and snow restart, and the live view has to register every mesh again. So the live entities are never moved:

1. **Camera state for the pose.** `World.update` runs once for the export camera (detail levels, near-camera tufts, sky dome, precipitation box, shader globals), with host motions held and, unless characters are included, no contact shadow. When the live view already shows that pose without a character this changes nothing; otherwise the live view's next frame, whose update always runs before it draws, puts its own state back.
2. **A copy of the world.** Every entity under the world's root is cloned, except the camera-collision hulls and (by default) host characters. Meshes, materials and textures are shared resources, so the copy costs entities, not geometry. The copy gets its own instance data (tree and bush detail levels, tufts, stars), a frozen copy of the palette/globals texture, and light receivers pointing at its own image-based light. Nothing the live view does afterwards reaches it.
3. **RealityRenderer.** RealityKit's public `RealityRenderer` draws the copy into a Metal texture of the picture's size with 4× multisampling and tone mapping (the set-up the Phase 5A renderer-host experiment matched against RealityView: mean difference 1.9/255). Three frames per picture; the first two settle the renderer. Rain and snow are simulated for up to 8.5 s first, so the air is full.
4. **Grade and bloom.** The same `WorldPostProcess` kernels as on screen (its own instance, the host's settings), then an sRGB encode and read-back.
5. **Frame.** `PostcardFrame.compose` draws plate, picture (one pixel per pixel), type, and burns in the credits.

The main thread is never blocked on the GPU (waits run off the main actor).

**Limits.**
- Not run yet: the offscreen path needs a device (the Mac build has no compiled Metal library, so `World` can't be built in `swift test`). Built for iOS only; layout, credits, colours, reframing and determinism are tested on the Mac.
- Host characters are not drawn by default; `includeCharacters: true` clones them in their current pose (whether a mid-animation pose survives the clone is unverified).
- When the export pose differs from the live camera, or a character's contact shadow is hidden, the world's shared state changes for the time it takes to copy it (same main-thread turn); whether the live view can pick that up for one frame depends on RealityKit internals and is unverified.
- Exports happen in the foreground; the GPU is not available in the background.

## WorldLab

- Menu (…) → **Export postcard**: pick Bold, Classic or Minimal, export the current postcard pose (the camera's postcard view, else the composed postcard the Postcard mode shows) in all three sizes, see the files, share them. Files go to the app's Documents as `postcard-<style>-<size>.png`.
- `-exportpostcard STYLE`: once the world has loaded and settled (4 s), exports and prints `POSTCARD saved postcard-<style>-<size>.png` for each file (then `POSTCARD done ...`), or `POSTCARD failed <why>`.
- Weather is Demo weather today: postcards carry "Demo weather" and the "Demo" tag. `PostcardExports.appleWeather()` (WeatherKit attribution and marks) is wired for live data and unused until then.

## Tests

`Tests/WorldGenTests/PostcardTests.swift` (macOS, `swift test`): safe areas on every size × style × day/night × Demo/live with long text and an extra source credit; story bands; the OSM credit first and burned in (text pixels in its box) on every postcard; Demo label vs provider mark (mark proportional, unmodified pixels, the right mark for the plate, legal URL and notice); night plate and contrast; type sizes and tabular figures; deterministic pixels and PNG bytes; the reframing rule.
