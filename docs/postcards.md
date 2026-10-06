# Postcards

WorldEngine renders a framed postcard of the world from one camera pose at three sizes and three frame styles. The world is drawn offscreen at each postcard's own picture size, in quality mode by default (a still doesn't need 60 fps), the host's text block goes above it, and the credits are burned in below it. Spec (read-only input): `docs/proposals/postcards-widgets-v1/` (frame studies `frame-<style>-<size>`, `one-page-spec`). Widgets are not covered here.

## API

```swift
let request = PostcardRequest(
    text: PostcardText(placeName: "Evanston", localTime: "Oct 6, 2026 · 2:30 PM CDT",
                       condition: "Clear", temperature: "72°F", demoLabel: "Demo"),
    weather: .demo,                       // or .live(credit:markLight:markDark:)
    sizes: PostcardSize.allCases,         // square, portrait, story
    styles: [.classic],                   // bold, classic, minimal
    post: livePost.settings,              // the live WorldPostProcess's settings, copied now
    quality: .max)                        // or .live: the live view's settings
let postcards = try await world.exportPostcards(pose: pose, request: request)
for p in postcards { try p.pngData().write(to: folder.appendingPathComponent(p.fileName)) }  // postcard-<style>-<size>.png
```

| Type | Where | What |
|---|---|---|
| `World.exportPostcards(pose:request:)` | WorldEngine `PostcardExport.swift` | Renders and frames every requested size × style. One export at a time (`.busy` otherwise). |
| `World.renderStill(pose:width:height:quality:post:)` | WorldEngine | The bare picture, no frame or credit: a test artifact for the look loop (WorldLab `-capturequality`). |
| `PostcardRequest` | WorldEngine | Text, weather, sizes, styles, `appearance` (nil: night when the sun is below −6°), `composedAspect` (16:9), `post`, `quality` (`.max`), `includeCharacters` (false). |
| `PostcardImage` | WorldEngine | `image` (`CGImage`, 1080 px wide, sRGB), `pngData()`, `fileName`, the reframed `pose`, `layout`, `info` (render size, supersample factor, shadow range, tufts, near-detail counts, grade state) and `timing`. |
| `PostcardQuality` | WorldEngine `PostcardQuality.swift` | `.max` and `.live`, or any mix of the settings below. |
| `World.postcardLightState` | WorldEngine | The lighting-bible state of the current light and weather (`PostcardLightState.resolve`). |
| `PostcardText`, `PostcardWeather`, `PostcardSize`, `PostcardStyle`, `PostcardAppearance` | WorldGen `Postcards/PostcardFrame.swift`, re-exported | Plain data from the host. |
| `PostcardFrame.layout(...)`, `.compose(...)`, `.pngData(_:)`, `.imageCredits(...)` | WorldGen | The frame: renderer-neutral CoreGraphics/CoreText, unit-tested on the Mac. |
| `CameraPose.reframed(forAspect:)`, `PostcardReframe` | WorldGen `Postcards/PostcardReframe.swift` | The reframing rule. |
| `PostcardLightState`, `PostcardGrade`, `PostcardGradeTable` | WorldGen `Postcards/PostcardGrade.swift`, `Profiles/postcard-grade.json` | The quality-mode final grade per lighting state. |
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

Layout, top to bottom inside the safe area: place name, details, the picture, credits. The picture takes all the height left between them, so live weather (more credit rows) gives a slightly shorter picture than Demo weather. The picture is a whole number of pixels.

## Reframing

Composed postcard poses are scored in a 16:9 frame at 50° vertical FOV. Each postcard picture is rendered separately for its own aspect ratio; none is a crop. The rule (`PostcardReframe`): **same eye, same look-at point, same diagonal field of view as the composed frame.** A narrower picture trades some width for height instead of losing the sides, so landmarks at the edges of the composition stay in frame, and the look-at point keeps the horizon where the composer put it. The vertical FOV is capped at 75°. The square picture keeps over 95% of the composed horizontal field; the narrowest picture (classic story, about 0.8 wide per 1 high) keeps about three quarters (tested: at least 75% on every size and style).

## Quality mode

`PostcardQuality.max` (the default) renders each still at maximum quality; `.live` uses the live view's settings (for comparison: WorldLab `-postcardquality live`). Everything acts on the offscreen copy of the world; the live entities and the live view's settings never change (tested on the Mac: the live world's entities, instance counts, light receivers and shadow settings are identical before and after both kinds of export).

| Setting (`.max`) | What it does |
|---|---|
| `supersample` 2, `maxRenderPixels` 4 MP | The picture is rendered at up to 2× its size with 4× MSAA on top, then filtered down with a separable Lanczos-2 filter (negative lobes clamped). Grade, bloom and exposure run at the rendered size; the bloom is measured against the picture size so the glow keeps its on-screen width, and exposure is metered per picture. The cap comes from measured memory (below): square and portrait render at 2×, story at about 1.8×. |
| `maxShadowDistance` 160 m | The copy's sun shadow reaches the farthest building or tree in frame (live range 80 m at least, 160 m at most, never past the fog's end) through a fitted orthographic box (`.fixed`): the view slice out to that distance (heights 0–40 m) plus 200 m toward the sun, the copy's sun turned about its own axis so the box lines up with the view. On the Mac the box out to 160 m kept edges as crisp as RealityKit's automatic fit at 80 m (`orthographicScale` is the box's full size: read as half, the tree shadow at the frame's edge went missing). The box side is reported (`info.shadowBox`). |
| `nearDetail` | Every tree and bush in frame uses the near mesh with the opaque material (slot 1; the cut-away slot 0 stays empty: postcards have no cut-away); out-of-frame ones keep distance detail for the shadows they throw in. Every building cell in frame uses `BuildingLOD.near` where it has it, else its finest level. |
| `tuftRange` 80 m | Edge tufts on every visible lawn edge out to 80 m (shrinking away over the last 20 m), instead of the live ≤ 200 within 25 m of the look-at point. |
| `ambientOcclusion` 0.15, `groundBounce` 0.25, `shadeLift` 0.08 | Softer light: the baked contact AO takes 15% more of the ambient fill (bible §2.3: another 10–20% within a contact; open surfaces unchanged); the ground-coloured fill from below × 1.25; the sky fill × 1.08 (a slight lift in shade). Fill scales are written into the copy's frozen globals texture; the AO share is globals texel 29, read only by a quality-mode branch in `WorldShaders.metal` (zero on screen, so the live path is unchanged). |
| `finalGrade` | The final grade for the world's lighting state, after `WorldPostProcess`: lift/gamma/gain, saturation and a shade-tint push toward the bible's shade tint, from `Profiles/postcard-grade.json` (keys: morning, midday, ordinary, golden, blue, overcast, light-rain, storm, fog, snow, moon-night, moonless-night; identity until tuned). Targets: look-fix-v1 §2.2 (per-state tints, key:fill, EV, Y and saturation) and §2.3 (shade tints) in `docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md`. One small kernel at the picture size, combined with the sRGB encode. |
| `settleFrames` 1 | One frame before the first picture of a copy (later pictures none): on the Mac a fresh copy's first frame already matched one drawn after two settle frames (mean difference 0.002 levels). |

The lighting state (`PostcardLightState.resolve`, also `World.postcardLightState`): night below −6° (moon-night when the Moon is up, at least a quarter lit and the cloud under 0.6, else moonless-night); otherwise weather first (thunderstorm or rain ≥ 0.6 intensity → storm, rain → light-rain, snow → snow, fog/haze/smoke/dust → fog, cloudy or cloud ≥ 0.8 → overcast); then the sun: −6°…0° blue, 0°…10° golden, above that by the share of daylight gone (before 0.38 morning, after 0.62 ordinary, else midday; without sunrise and sunset, by the sun's side of the sky).

**Not done, and why.**
- Screen-space AO from depth: `RealityRenderer.CameraOutput` takes colour textures only and there is no public depth output, so AO uses the baked contact AO instead (above).
- Building detail beyond the focus box: those cells were generated with far and skyline levels only; more detail would mean generating at export time, which is out of scope.
- Shadow map resolution and cascades: RealityKit offers `.automatic(maximumDistance:)` and `.fixed(zNear:zFar:orthographicScale:)`, one shadow map per light, and no control of the map's size, so texel density is the box side over an unknown map size (2048 texels would give about 8 cm at a 160 m box).
- Pausing the live view during a capture: a RealityView only pauses by leaving the hierarchy (a black frame and a re-registration of every mesh on return), so the live view keeps drawing while the copy renders.

## Timing

Every image carries `timing` (`PostcardTiming`); WorldLab prints `POSTCARD timing <file> clone=… settle=… render=… post=… frame=… total=… ms png=… ms` and `POSTCARD info <file> render=WxH ss=… shadow=…m tufts=… near=… cells=… grade=…`. `clone` (camera state, world copy, quality work, renderer set-up) is charged to the first picture of an export; `settle` includes the rain or snow warm-up.

Measured on the Mac (M1 Max, 24-core GPU, shared and loaded machine), classic style, three sizes in one export, after the set-up fix (tree bounds computed once per group, not per instance):

| Quality | Picture (rendered) | clone | settle | render | post | frame | total |
|---|---|---:|---:|---:|---:|---:|---:|
| live | square 970 × 752 | 90 | 52 | 5.6 | 65 | 4.8 | 218 ms |
| live | portrait / story | 0 | 0 | 7–9 | 2–3 | 5 | 15–17 ms |
| max | square (1940 × 1504) | 92 | 36 | 8.2 | 167 | 3.9 | 306 ms |
| max | portrait (1940 × 2044) / story (1782 × 2245) | 0 | 0 | 11–13 | 5–6 | 4 | 20–23 ms |

Whole export: live 0.27 s, quality 0.37 s. `clone` splits into prepare 0.1, copy ~33, quality ~48, set-up ~9–40 ms. The first picture's `post` includes compiling the export's post kernels (once per process). Rain or snow add a warm-up (~135 ms).

Metal memory at each picture (process total, Mac; the live world is ~530 MB): 1× 539–555 MB, 1.5× 556–714 MB, 2× 704–730 MB. Uncapped 2× story (1940 × 2444) peaked at ~1000 MB, hence the 4 MP cap (story then renders at 1.84×, 727 MB). After an export the extra is released down to ~670 MB (RealityKit keeps some).

iPhone figures: not measured here (no device or Simulator). GPU steps should take several times the Mac's GPU time; CPU steps (copy, quality) roughly 1.5–2×. Expected per capture on an iPhone 13: about 0.4–0.7 s, inside the 1.5 s target, to be confirmed with the `POSTCARD timing` lines.

## Attribution (burned into every image)

| Credit | When | Drawn as | Source |
|---|---|---|---|
| `© OpenStreetMap contributors · openstreetmap.org/copyright` | always, first line | P1's credit line from `Profiles/credits.json`, via `CreditBurnIn` | CLAUDE.md; decision 6c (no credit-free exports); one-page spec "Attribution": "© OpenStreetMap contributors stays visible whenever world imagery appears" |
| Other manifest sources (e.g. Overture) | when their licence asks for credit | their own attribution lines (`CreditsCatalog.merged`) | decisions 6a–6c |
| Weather provider mark | live weather | the image the host loaded from WeatherKit's `combinedMarkLightURL` (light plates) or `combinedMarkDarkURL` (dark plates), 14 pt high, aspect kept, colours untouched | one-page spec "Attribution": "Use official Apple Weather combinedMarkLightURL / combinedMarkDarkURL, unmodified and proportional" |
| Legal page as readable text | live weather | the host's `legalPageURL` without its scheme, beside the mark | one-page spec: "Static images print a readable legal URL" |
| "Weather visualization modified from Apple Weather data." | live weather | the provider's modified-data notice (the standard wording when the host gives none) | one-page spec "Weather transformation" |
| "Demo weather" | Demo weather | a small outlined label where the mark would be; no provider mark | brief for this feature; experience-v1 (Demo weather is always labeled) |

The engine never bundles or draws a provider logo of its own: marks are runtime inputs (`PostcardWeather.live(credit:markLight:markDark:)`). Credit wording comes from P1's credits data and is not changed here. The share page that travels with an image (spec: "travel with a linked detail page") is host work. `renderStill` pictures (look-loop test artifacts, like the live snapshots) carry no credit.

## Offscreen rendering

RealityView has no offscreen API, and an entity can belong to only one scene. Moving the live world's root entity into a second renderer would pull it out of the live view's scene: RealityKit stops a host character's animations when its entity leaves a scene, rain and snow restart, and the live view has to register every mesh again. So the live entities are never moved:

1. **Camera state for the pose.** `World.update` runs once for the export camera (detail levels, near-camera tufts, sky dome, precipitation box, shader globals), with host motions held and, unless characters are included, no contact shadow. When the live view already shows that pose without a character this changes nothing; otherwise the live view's next frame, whose update always runs before it draws, puts its own state back.
2. **A copy of the world.** Every entity under the world's root is cloned, except the camera-collision hulls and (by default) host characters. Meshes, materials and textures are shared resources, so the copy costs entities, not geometry. The copy gets its own instance data (tree and bush detail levels, tufts, stars), a frozen copy of the palette/globals texture (with the quality-mode fill and AO settings), and light receivers pointing at its own image-based light. Quality mode then works on the copy (near detail, tufts, shadow range). Nothing the live view does afterwards reaches it (tested on the Mac: switching the live world to a debug view after the copy is taken leaves the copy's render unchanged; a new copy shows it).
3. **RealityRenderer.** RealityKit's public `RealityRenderer` draws the copy into a Metal texture with 4× multisampling and tone mapping (the set-up the Phase 5A renderer-host experiment matched against RealityView: mean difference 1.9/255), at the supersampled size. Rain and snow are simulated for up to 8.5 s first, so the air is full.
4. **Post.** The same `WorldPostProcess` kernels as on screen (its own instance, the host's settings, exposure metered on the picture), the Lanczos-2 downsample, the final grade with the sRGB encode, read-back.
5. **Frame.** `PostcardFrame.compose` draws plate, picture (one pixel per pixel), type, and burns in the credits.

The main thread is never blocked on the GPU (waits run off the main actor).

**Checked on the Mac.** RealityKit's `RealityRenderer` exists on macOS too, so `scripts/postcard_mac_check.sh` compiles the engine's shaders for the Mac (`swift build` copies the Metal source uncompiled), renders real postcards of the Sloan's Lake demo world in both quality modes and a rainy night, and runs every postcard test. It is a heavy job: run it through `scripts/heavy.sh`. Mac times are not iPhone times.

**Limits.**
- Not run on an iPhone yet. WorldLab compiles for iOS; the package builds and its tests pass on the Mac.
- Host characters are not drawn by default; `includeCharacters: true` clones them in their current pose (whether a mid-animation pose survives the clone is unverified).
- When the export pose differs from the live camera, or a character's contact shadow is hidden, the world's shared state changes for the time it takes to copy it (one main-thread turn); whether the live view can pick that up for one frame depends on RealityKit internals and is unverified.
- Exports happen in the foreground; the GPU is not available in the background.
- Rain and snow streaks did not show in the Mac renders, even after the copy's emitter is restarted and the air simulated by drawn frames (wet surfaces, sky and fog do show). Whether RealityRenderer draws particle emitters on iOS is unverified.

## WorldLab

- Menu (…) → **Export postcard**: pick Bold, Classic or Minimal, export the current postcard pose (the camera's postcard view, else the composed postcard the Postcard mode shows) in all three sizes in quality mode, see the files, share them. Files go to the app's Documents as `postcard-<style>-<size>.png`.
- `-exportpostcard STYLE [-postcardquality live|max]` (default max): once the world has loaded and settled (4 s), exports and prints the timing and info lines and `POSTCARD saved postcard-<style>-<size>.png` for each file, or `POSTCARD failed <why>`.
- `-viewlist` views with `-capturequality` in their args save the quality-mode render of the current camera at the live capture's size as `Documents/views/<id>.png` instead of the live snapshot (`VIEWSHOT … source=quality`), so the look loop can pair live and quality views.
- Weather is Demo weather today: postcards carry "Demo weather" and the "Demo" tag. `PostcardExports.appleWeather()` (WeatherKit attribution and marks) is wired for live data and unused until then.

## Tests

`Tests/WorldGenTests/PostcardTests.swift` and `PostcardGradeTests.swift` (macOS, `swift test`): safe areas on every size × style × day/night × Demo/live with long text and an extra source credit; story bands; the OSM credit first and burned in on every postcard; Demo label vs provider mark (mark proportional, unmodified pixels, the right mark for the plate, legal URL and notice); night plate and contrast; type sizes and tabular figures; deterministic pixels and PNG bytes; the reframing rule; the grade table (every bible state, identity) and the light-state mapping.

`Tests/WorldEngineTests` (macOS): the Lanczos-2 downsample against a CPU reference (flat colour kept, pixel stripes averaged), the final grade against `PostcardGrade.apply` and identity byte-for-byte, quality defaults; and, with the Mac shader library (`scripts/postcard_mac_check.sh`), real offscreen exports in both modes that leave the live world unchanged, a rainy night in quality mode, and copy independence.
