# Milestone 2 report: look pass, web renderer, engine decision (Prompt 4)

Device: iPhone 14 Pro (iOS 26.4.2). Area: Sloan's Lake area B. Branch: `m2/look-web`.

## 1. Housekeeping
- **Disk:** about 16.0 GB freed (15,967 MB): Xcode DerivedData, our old build products and Instruments traces. No unavailable simulators. No DeviceSupport folders outside 26.4.x: 26.4.1 and 26.4.2 (11 GB together) were kept per the rule.
- **Commits:** `docs/proposals/` committed unedited (plus the weather, regional profiles, sky and seasons, and experience proposals as they arrived). `AGENTS.md` replaced. Work commits on `m2/look-web`: post-process repro, look pass, package + web renderer + dog, docs/tools, this report.
- **Push:** origin `https://github.com/TheKeptApp/world-engine` added; `main` and `m2/look-web` pushed; the final merge to `main` is pushed with this report.

## 2. Post-processing crash
- **Reproduced** in a minimal app (`Apps/PostProcessRepro`). Assigning `renderingEffects.customPostProcessing` (or `ARView.renderCallbacks.postProcess`) before the view is in a window traps (EXC_BREAKPOINT) on device and in the Simulator. Assigning it once the view is on screen works (500 and 491 post-process calls on device).
- **Fixed in our code** with that workaround: `WorldView` installs the effect only after the view appears. Grade and emissive bloom now run on device; the post pass's GPU time is 1.65 ms mean, 1.77 ms p95 over 10 minutes.
- **Not fixed in RealityKit:** the underlying bug remains. It counts against RealityKit as you set out.
- **Apple Feedback** is ready: `docs/feedback/realitykit-postprocess-trap.md`, with click-by-click steps for Feedback Assistant, plus `PostProcessRepro.zip`.

## 3. Look pass: before / after
`docs/screenshots/m2/look-before-after.png`: top row is milestone 1, bottom row is now. Same six presets and the same moment (22 Sept 2026, 17:45 MDT). Full-size images: `docs/screenshots/m2/look-after/`.

Done from the v2 spec:
- **Palettes and light as data:**
  - seasonal palette rows and house color tuples
  - time-of-day keys by sun elevation, with a per-key exposure
  - weather modifiers
- **Shading:** baked AO channel (fill only, floor 0.65), sky/ground fill and contact shadow, grade and bloom.
- **Trees:** three crown archetypes of 4–5 smooth lobes, thinner trunks with bark variation, near/mid/far meshes (45 m / 160 m). Bushes get the same three detail levels.
- **Ground:** stylized edge tufts and lawn mottling, sidewalk joints and near-camera bevels.
- **Windows:** v2 window colors with lit states as data.
- **Sky:** gradient from the light state, soft clouds, sun disk in the real direction.
- **Aerial:** its own fog distance policy plus a soft world boundary.
- **Character:** Luna, framed by her projected bounds at 22%.

Triangle budget: a street view submits 169–276k triangles, under the 400k ceiling (frustum count). Trees plus props went from about 320k to 135–185k across the whole area.

## 4. Shared world package
- **Format:** `docs/package-format.md`.
  - `world.json` manifest with file hashes
  - per-chunk `lod0`/`lod1` `.glb` with explicit `_PAINT`, `_EXTRA` and `_FEATURE` channels
  - per-chunk `scene.json`: feature identities, OSM source tags and the generated choices
  - prototypes + `instances.json`
  - palettes, materials, environment, sky images, collision hulls, tuft candidates, source profiles
- **One decision owner:** RealityKit and `worldbake export` both call `WorldBuild`. three.js only reads the package.
- **Tests (pass):**
  - exports are byte-identical
  - every vertex is within 1 cm of the generator (worst 0.015 mm), and so is every instance (worst 0.07 mm)
  - identities, ranges, paints and indices are exact
  - every instance has a prototype
  - a palette-only change touches only `palettes.json`
  - lod1 is lighter

  The package caught a real generator inconsistency: flower bushes had two shapes but were declared with one. Fixed.
- **Size:** 188 files, 47.7 MB uncompressed. Not yet compressed for the web.

## 5. Matched test
Conditions:
- drawable 1179 × 2556 at 3×, MSAA on
- golden hour (2026-10-15 23:44Z)
- 50% brightness, same 985 m loop, street-follow camera, all look features on
- logged on the phone, pulled over Wi-Fi

Full logs: `docs/perf/m2-matched/`. Summary script: `scripts/analyze_runs.py`.

| | RealityKit | three.js WebGPU | three.js WebGL2 |
|---|---|---|---|
| Run | 10 min (18:39) | **10-minute run pending**; two short checks (60 s, 46 s) | 10 min (19:00) |
| Average fps | **48.5** | 59.9 / 58.7 | 19.3 |
| 1% low fps | **23.3** | 38.3 / 43.0 | 7.1 |
| Frames over 16.9 ms | 61.9% | 59.7% / 73.3% ¹ | 100% |
| Missed frames (over 25 ms) | 22.8% | 0.34% / 0.13% | 100% |
| Thermal state | nominal throughout | fair → serious ² | nominal throughout |
| Memory peak | 448 MB | 29 MB ³ | 17 MB ³ |
| Battery used | 0% (100 → 100%) ⁴ | — | 5% (100 → 95%) |
| GPU ms | post pass only: 1.65 mean, 1.77 p95 ⁵ | not exposed | not exposed |

¹ WebKit's frame timestamps are whole milliseconds, so 16/17 ms rounding inflates this column for the web. Missed frames are the reliable jank measure.
² Both short checks ran back to back with a RealityKit check, so the phone started warm. Not a fair thermal reading.
³ App process only. The web renderer's memory lives in WebKit's separate processes, which the app can't measure.
⁴ The battery percentage is too coarse to rely on for 10 minutes. The RealityKit run never left 100%, so it may have been on charge or in iOS's full-charge hold. These runs didn't log charging state or Low Power Mode; they're logged from now on.
⁵ RealityKit exposes no full-frame GPU timing outside Instruments, and Instruments lowers the GPU clock.

**RealityKit underperformed its own earlier check:** 48.5 fps over 10 minutes, against 59.8 fps for the same build in a 60-second check an hour earlier. The thermal state was nominal the whole time, so heat wasn't the cause. A repeat run with conditions logged is the only way to tell.

**Screenshots:** `docs/screenshots/m2/compare/v2-01.png`, `v2-04.png`, `v2-06.png`, each showing the v2 target, RealityKit and three.js side by side. Golden hour and noon for three.js are WebGPU frames captured on the iPhone; the aerial is WebGL2 in the Simulator. The same three.js shaders produce identical frames on both backends.

### Rubric (v2 §8.3, 1–5, scored from these captures)
| Criterion | RealityKit | three.js | Notes |
|---|---|---|---|
| 1. Silhouettes | 3 | 3 | Roof and crown families read; still repetitive |
| 2. Palette | 3 | 3 | Coherent v2 families; RealityKit's noon paving is warmer |
| 3. Light | 3 | 3 | Warm golden, neutral noon, one sun |
| 4. Softness / AO | 3 | 3 | Same AO and contact model; RealityKit's shadow edges are softer, three.js's crisper with slight stair-steps on sidewalk edges |
| 5. Ground richness | 3 | 3 | Mottling, joints, edge tufts; no leaves yet |
| 6. Character | 4 | 4 | Luna fitted to 22%, contact shadow, readable rim |
| 7. Depth and fog | 3 | 3 | Atmospheric separation; soft world boundary in the aerial |
| 8. House variety | 3 | 3 | Six house types with v2 color tuples |
| 9. Geography | 4 | 4 | True OSM data, correct sun bearing, honest gaps |
| 10. Motion | — | — | Needs video; not scored |
| **Total (1–9)** | **29** | **29** | Tie. Both are below v2's 40/50 Target gate |

## 6. Decision (rule E)
Pending the WebGPU 10-minute run. See the summary in chat.

## 7. Decisions needed
See the summary in chat.
