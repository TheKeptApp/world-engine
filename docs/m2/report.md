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
| Run | 10 min (18:39) | 10 min (19:18) | 10 min (19:00) |
| Average fps | 48.5 | **29.8** | 19.3 |
| 1% low fps | 23.3 | 18.5 | 7.1 |
| Frames over 16.9 ms | 61.9% | 100% | 100% |
| Missed frames (over 25 ms) | 22.8% | 99.8% | 100% |
| Thermal state | nominal throughout | nominal throughout | nominal throughout |
| Memory peak | 448 MB | 17 MB ¹ | 17 MB ¹ |
| Battery used | 0% (100 → 100%) ² | 0% (90 → 90%) ² | 5% (100 → 95%) |
| GPU ms | post pass only: 1.65 mean, 1.77 p95 ³ | not exposed | not exposed |
| Last 2 min vs minutes 2–3 (median frame time) | −3.9% | 0% | −1.9% |
| Short checks earlier (60 s) | 59.8 avg, 46.1 1% low | 59.9 avg, 38.3 1% low (and 58.7 / 43.0 over 46 s) | 20.0 avg |

¹ App process only. The web renderer's memory lives in WebKit's separate processes, which the app can't measure.
² The battery percentage is too coarse to rely on over 10 minutes. These runs didn't log charging state or Low Power Mode; they're logged from now on.
³ RealityKit exposes no full-frame GPU timing outside Instruments, and Instruments lowers the GPU clock.

**These runs look throttled, most likely by Low Power Mode, so treat them as invalid for the decision.**
- **WebGPU was capped, not slow.** It ran at exactly 30 fps for the whole 10 minutes: 99.1% of frames at 33–34 ms, heat nominal. A struggling GPU scatters frame times; a flat 30 is a cap. WebKit halves animation frames to 30 fps in Low Power Mode.
- **The short checks disagree with the 10-minute runs.** The same build ran WebGPU at 59.9 fps and RealityKit at 59.8 fps in my short checks earlier the same evening.
- **RealityKit also fell short** of its own check, to 48.5 fps, with no heat.

The protocol required Low Power Mode off. The build that records it in every log is committed, not yet installed.

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
**On the recorded data, RealityKit.** three.js's better mode, WebGPU, fails every performance gate:
- average 29.8 fps (gate 58)
- 1% low 18.5 fps (gate 50)
- battery not comparable

It passes:
- never reached "serious" (nominal throughout)
- rubric ≥ RealityKit's (a tie, 29 each)

**Provisional:** both 10-minute runs show throttling (see §5), probably Low Power Mode. A clean re-run of both with the condition logging could change the WebGPU result. Its earlier 60-second checks reached 59.9 fps, but with 1% lows of 38–43, still under 50. No renderer is retired until you confirm.

**Next phase on RealityKit (about 10 working days):**
- **Hold 60 fps at native resolution, 3 days:**
  - one Instruments GPU capture (click steps provided once)
  - shadow distance and cascades
  - quarter-resolution bloom
  - LOD distances
  - an optional render-scale setting (e.g. 2.5×)
  - goal: average ≥ 59.4 fps and 1% low ≥ 50 on the matched loop
- **Weather on screen from `environment.json`, 4 days:** wet surfaces, patchy snow, rain/snow particles, fog/tint/direct light, Moon disk, stars, lit windows.
- **Generalization on Plano (Russell Creek Park), 2 days:** re-fetch the data and the same presets, no retuning.
- **Ten-minute device runs and a video for rubric item 10, 1 day.**

## 7. Decisions needed
1. **Re-run both 10-minute tests?** It would mean installing the build that logs Low Power Mode and charging state. Low Power Mode must be off (Settings → Battery) and the phone unplugged, with a 15-minute rest between runs.
2. **Confirm the engine** after that, or accept RealityKit on this provisional result. Nothing is retired until you say so.
3. **Render scale:** must the 60 fps target hold at the native 3× drawable, or may RealityKit render at a lower scale (e.g. 2.5×) and upscale?
4. **Delete the iOS 26.4.1 DeviceSupport folder (about 5.5 GB)?** Your phone is on 26.4.2; the rule kept all of 26.4.x.
