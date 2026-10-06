# Phase 5A report: performance, no-character experience, living world (Prompt 5)

Device: iPhone 14 Pro, iOS 26.4.2. Area: Sloan's Lake, Denver. Branch: `phase5a`. Engine decision (final): iPhone = RealityKit; computers/web = three.js reading the same package. The fair-rematch addendum was cancelled before any three.js work.

## 1. Housekeeping, disk, WeatherKit
- **DeviceSupport 26.4.1 deleted** (5.7 GB). Only 26.4.2 (your phone) remains.
- **Disk report (read-only; nothing else deleted).** Largest folders:

  | Folder | Size | Notes |
  |---|---:|---|
  | `~/Library` | 118.9 GB | |
  | `~/Library/Developer` | 80.1 GB | |
  | `~/Library/Developer/CoreSimulator` (Devices) | 66.3 GB | simulator devices; largest single item |
  | `~/Desktop` | 43.8 GB | |
  | `~/robwoodbury-com` | 24.2 GB | |
  | `~/Library/Application Support` | 22.5 GB | Claude 13.3 GB, Notion 2.6 GB, Google 2.0 GB |
  | `~/.codex` | 17.1 GB | |
  | `~/Library/Developer/Xcode` | 13.8 GB | DeviceSupport 26.4.2 5.5 GB; DerivedData 5.1 GB (Kept 2.3, WeeklyDinners 2.0, stretchrun 0.3) |
  | `~/Library/Caches` | 12.6 GB | Spotify 2.6 GB, Codex 2.1 GB, ShipIt 1.9 GB |
  | `~/Downloads` | 8.3 GB | |
  | `~/.npm` | 5.9 GB | |
  | `~/Movies` | 3.2 GB | |
  | `~/.claude` | 3.1 GB | |
  | `~/.cache` | 1.8 GB | |
  | `~/Library/Containers` | 1.6 GB | CoreDeviceService 0.8 GB |

  iOS backups: none (`MobileSync/Backup` does not exist). Several `robwoodbury-*` repositories are 0.6–1.5 GB each.
- **Low Power Mode and charging** are logged in every WorldLab test run: CSV header, and the summary at start and end. The device scripts also stop a sequence if a run starts on the charger or in Low Power Mode. That check caught two problems this phase (§6).
- **WeatherKit:** WorldLab now signs with the explicit App ID (`com.lincolnlabs.worldlab`, WeatherKit entitlement); the device build signs and installs. One live request from the Simulator, for the Plano city centre snapped to the 0.05° grid (cell `c005-2460-1666`, centre 33.025, −96.675), **succeeded**: clear, cloud 0.00, 22.4 °C, wind 2.0 m/s from 29°, visibility 43 km, 0.00 mm/h; valid 02:22:10 UTC, expires 5 minutes later; attribution "Apple Weather" with the legal-attribution URL. Nothing was stored. One fix was needed: an iOS resource bundle may not contain a folder named `Resources` (codesign rejects it), so the star catalogue moved to `Catalog/`.

## 2. Performance (section A)
Device runs: Low Power Mode off, unplugged, heat nominal unless noted; street loop at golden hour with Luna following (the matched-test setup), 60 s each. Logs: `docs/perf/m3-phase5a/` and `docs/perf/m3-phase5a-gate/`. Runs that started on the charger or in Low Power Mode were discarded (§6).

**Resolution (decision 2).** RealityView has no resolution API; the view behind it is an `ARView`, whose `contentScaleFactor` (public UIKit API) sets the drawable. WorldView finds that view and applies the shared display policy (`Profiles/display.json`, also exported in the package): **2.5×** at nominal heat, **2.25×** at fair, **2.0×** at serious or critical; it steps down at once and back up only after 60 s cooler. On the phone 2.5× is 982×2130 (from 1179×2556). In the rain gate loop the phone reached "fair" at 33 s and the view stepped to 2.25× (884×1917) as designed.

| Before the environment work (clean) | Avg fps | 1% low | Over 25 ms | Worst frame | Memory | Post GPU |
|---|---:|---:|---:|---:|---:|---:|
| 3.0× (native) | 59.8 | **46.6** | 0.12% | 35.9 ms | 454 MB | 1.64 ms |
| **2.5×** | **60.0** | **58.9** | 0.00% | 17.3 ms | 395 MB | 1.16 ms |
| 2.0× | 60.0 | 58.7 | 0.00% | 17.2 ms | 341 MB | 0.76 ms |

Target (avg ≥ 58, 1% low ≥ 50) **met at 2.5×**; native 3× still misses the 1% low, as in the earlier check. **No cuts were needed** for this target (shadows, LODs and bloom unchanged).

**Visual difference** (`docs/screenshots/m3/scale/`, same preset at each scale, crop at full size): 2.5× softens thin edges slightly (the dog's outline and collar, sidewalk joints, grass tufts); at phone viewing distance it is hard to see. 2.25× is visibly softer up close; 2.0× is soft on fine lines and textures. The heat steps only drop to 2.25×/2.0× when the phone warms.

**Calm mode (30 fps when still): not achievable with RealityView.** Calm detection works (camera and moving entities still for 1.5 s; any touch wakes it), but RealityKit ignores the only frame-rate control behind RealityView (`ARView.__preferredFrameRate`, an undocumented property), on the phone and in the Simulator, with and without automatic frame rate, and after re-attaching the view: still 60 fps. I prototyped the alternative, drawing the world with `RealityRenderer` (public RealityKit API) into a Metal layer WorldEngine owns: its image matched RealityView (mean pixel difference 1.9/255) and calm mode then ran at exactly 30.0 fps, but walking it managed only 55.3 fps average with a 23.9 fps 1% low (RealityView: 60.0 / 58.9). It stays an off-by-default experiment (`WorldRenderSettings.host`); see decisions. Heat effect of calm mode: in two 2-minute idle runs on that host heat stayed nominal either way, and a sound GPU-time comparison wasn't possible with that host (its own timing brackets measured the pipeline, not the GPU).

**Pause when hidden: works.** Paused = the RealityView leaves the hierarchy (no public pause exists): 0 fps while paused, the same world and post-processing come back on resume. Triggers: app in background, view off screen, or the host's `isPaused`; Control Center or an alert over the app (inactive) keeps rendering. The phone checks found one bug and it is fixed: after returning from the background, frame updates fired twice (a torn-down view keeps ticking briefly; its subscription is now cancelled).

**GPU frame time (RealityKit).** Measured with Instruments' Metal System Trace on the phone, but with the GPU at its own clocks: Xcode's stock template pins the GPU to its **minimum** clock while tracing (that is what inflated the milestone 2 numbers); `scripts/make_gpu_template.py` writes a copy with the performance state set to "Default" (or "Maximum"). Street loop, 2.5×, with all of section C on:

| GPU time per frame | Mean | Worst 1% | Max |
|---|---:|---:|---:|
| Clear, golden hour, GPU at its own clocks | 14.07 ms | 14.65 ms | 14.96 ms |
| Clear, golden hour, GPU pinned at maximum clock | 14.04 ms | 14.53 ms | 14.63 ms |
| Light rain, GPU at its own clocks (stepped to 2.25× at 33 s) | 15.06 ms | 19.75 ms | 22.00 ms |

**The 8 ms aim (≥ 2 ms free of the 10 ms budget) was not met: about 14 ms of GPU work per frame**, with weather already included. 60 fps still holds because 14 ms fits in the 16.7 ms frame (the GPU is about 84% busy), but there is no headroom. Attaching Instruments disturbs frame pacing, so traced runs are not used for the fps numbers.

**Where the time goes (GPU attribution, overnight, §6).** A fixed street view (Luna standing, golden hour, 2.5×), each feature switched off for a minute between two all-on minutes, and GPU time split by pass:
- **The main pass's pixel shading is three quarters of the frame**; the rest is the sun's shadow map (~10%), post-processing (~7%), geometry (~5%), the final composite (~3%) and Luna's skinning (~1.5%).
- **Sun shadows: about a third of the frame** (5.6 of 15.2 ms at the same clock): drawing the shadow map is the small part; sampling it in every shaded pixel is the large one.
- **Trees: about a quarter of the main pass**, mostly because every tree used the cut-away's transparent pipeline, so the GPU shaded every overlapping lobe instead of only the visible one.
- MSAA about 8%, the surface extras (lawn patches, litter, puddles, snow) about 1%, and sky pixels cost more than ground pixels (the dome was lit by RealityKit for nothing).
- Caveat: these runs were on the charger at "serious" heat, where the GPU ignores the requested clock and changes speed with the load, so only comparisons at the same clock are kept (most of the second run's comparisons were not). The daytime session repeats them unplugged.

**Changes made from it, none visible:**
- **Trees and bushes beyond 20 m use an opaque material**; only those near the camera (where the cut-away can apply) keep the transparent one. **Measured: the old set-up cost 3 ms more per frame (24%)** in the test view, at the same clock.
- The sky dome and stars are unlit (their colour is all ours).
- Flat ground, water, the boundary ground and grass tufts no longer draw into the sun's shadow map.
- Not yet measured cleanly; the daytime session will give the new total for the walking loop.

**What was cut or changed:** nothing visible was cut. Changed: render scale 3.0× → 2.5× (heat steps to 2.25×/2.0×); the experimental RealityRenderer host was not adopted; the invisible GPU savings above. Visible cuts that would close the rest of the gap (shorter shadow range, MSAA off) are a decision for you (§9).

## 3. Experience modes (section B)
WorldLab now opens on a **composed postcard with no character**, live clock and Demo weather (`docs/experience.md`).
- **Composition is shared and renderer-neutral** (WorldGen, `Experience/`). The experience-v1 §4 heuristic runs while the world is prepared (≈ 0.5 s for Sloan's Lake):
  - Candidates every ~10 m on public paths and park edges (never in water, buildings or private ways; ≤ 256), 24 headings, ≤ 32 coarse rays per pose against building hulls, tree crowns and a classified ground grid.
  - Scores open depth, geographic interest, composition (water 15–40%, sky 25–45%, layered depth, no trunk in the centre third), light fit at three real sun positions, weather fit and coverage, with the spec's weights; the best 12 are refined.
  - Output: the top 8 postcards with scores, frame shares and reasons, stored in the package's `environment.json` (`experience`), so three.js reads the same choice. `worldbake compose` prints them.
  - At Sloan's Lake all eight are waterfront views (the best: water, park, architecture; score 0.78). Deterministic, tested.
- **Camera modes** (shared rigs in WorldGen, applied by RealityKit's `WorldCamera`), with eased 1.2 s transitions:
  - **Postcard:** static; "Next postcard" cycles the composed set.
  - **Aerial diorama:** bounds + 10%, 55° (45–65°), pan / pinch distance / two-finger heading, centre kept on the data.
  - **Free explore:** 1.65 m eye, thumb pad + look-drag, 1.4 m/s, ≤ 1.5 m/s², ≤ 60°/s, blocked by buildings, water and the data edge.
  - **Route flythrough:** 2 m eye, look-ahead clamp(2 + 2v, 4, 18) m, ≤ 30°/s, ≤ 1 m/s², slows before sharp turns, shortens its look at hairpins; foliage near the eye cuts away.
  - **Character follow:** the existing street camera; offered when a character is present.
  - Tests check the spec's aerial pose exactly and the explore/route limits.
- **Character slot:** zero, one or many host entities (`World.characters`); WorldLab switch None / Luna / Capsule.
- **Overlay:**
  - Weather strip: condition icon and text, temperature, precipitation, wind, place, local time, a **Demo** badge, and a reserved slot for the Apple Weather mark and legal link (shown with live data in 5B).
  - Time scrubber above the OSM credit: sunrise/sunset markers, day/week steps, Return to live.
  - "Clean view" hides the controls but never the OSM credit.

## 4. Environment on screen (section C)
Everything is driven by the shared `EnvironmentDocument` (`World.apply(_:)`; `docs/environment.md`):
- **Light:** sun colour, intensity and shadows; fog colour and distances with the weather tint; sky/ground fill with moonlight; lit windows.
- **Sky** (camera-centred dome):
  - gradient, horizon haze into the fog;
  - clouds by cover, with a calibrated threshold, billowed and darker under rain;
  - sun disk and glow;
  - the **Moon as an analytic disk lit from its real Sun direction** (1.5× display). In the clear-night state it lands at the spec's computed position (0.172, 0.059 of the frame).
  - **≤ 128 catalogue stars**, hidden behind cloud.
  - Smoke, haze and dust veil the sky in their own colour.
- **Seasons:**
  - continuous palettes in linear light, with per-tree ±7-day offsets;
  - autumn leaf drop lobe by lobe; dropped lobes collapse in the vertex stage, so January trees are bare over real branches;
  - **leaf litter** under real crowns (a canopy map baked from the tree positions), rising through leaf drop and gone by mid-December.
- **Weather:**
  - **Rain:** streaks (RealityKit's rain preset, budget counts, light-rain floor 240, in a box ahead of the camera; switched off above 60 m, so the aerial shows rain through wet streets, cloud and fog, per experience-v1 §10); **darker wet paving (asphalt up to 34%) and grass**; a sheen; **puddles** that grow with wetness and mirror the sky with Fresnel.
  - **Snow:** flakes, and patchy accumulation on upward surfaces (0.8 m, 3.5 m and 18 m patterns, fading with distance; from the air, broad 140 m patches with soft edges instead of fine speckle).
  - Fog, haze, smoke and dust variants. **Fog is measured along optical depth** (haze thins with height), so the aerial diorama keeps a clear centre with only its far edge softened, as experience-v1 image 10 asks; street views are unchanged.
  - **Thunderstorm:** dark deck, short fog, heavy rain.
  - **Wind:** sway per R10, with direction and strength from the model.
- **Weather and time controls:** WorldLab's menu has eight Demo presets plus showcase states 01–12; the scrubber covers time and date.
- **Spec notes (decision 5):**
  - 0–2° sun fade, applied once and shared with the web through the package;
  - wetness and snow from the model;
  - blowing snow without ground snow shows no particles;
  - the January reset is fixed (the calendar wraps);
  - seasons use the calendar priors;
  - no Astronomy Engine port.
- **Also changed:** time-of-day keys now blend chronologically between the day's anchor crossings (weather v1 §5). With explicit scenario intensities, **all eleven experience-v1 states resolve to the spec's fog, direct-light, tint and snow-cover values** (tested).
- **Art-direction decisions logged:** the rain look goes past the weather spec's "≤ 12% darkening, no mirror reflections" (darker streets, mirrored-sky puddles; no reflected scene geometry), and light rain gets a particle floor.

## 5. Gate (section D)
**Screenshots, now from the phone** (on-device RealityKit snapshots, iPhone 14 Pro at 2.5×, 982×553 16:9 views; the "© OpenStreetMap contributors" credit is drawn on as the app shows it, because a snapshot holds the world view only): `docs/screenshots/m3/gate/` and side-by-side with the targets in `docs/screenshots/m3/compare/` (experience-v1 01–11 targets; visual v2 01/04/06 targets), contact sheet `gate-sheet.png`. They replace the earlier Simulator captures (in git history), which were taken before tonight's tree, aerial and sky changes. Twelve states: the eleven experience-v1 states at the spec's cameras plus **12, a clear ordinary afternoon** (Oct 15, 15:30 MDT, mostly clear), added per the art direction note, and v2 01/04/06 with Luna. All weather is synthetic **Demo** data.

**Rubric** (visual v2 §8.3, 1–5). The clear afternoon (12) and light rain (03) are scored as strictly as fall (01) and snow (07/08); each criterion takes the weakest of those four where they differ.

| Criterion | Score | Evidence |
|---|---:|---|
| 1. Silhouettes | 3 | Trees now read in every season: lobed crowns, real bare branching in winter (07–09), round far crowns. Held at 3 because houses are still plain boxes (v2 shots; P2's area) |
| 2. Palette | 4 | Coherent families through golden, noon, rain, snow and night; ordinary-afternoon lawn still a little uniform |
| 3. Light | 4 | Warm golden hour, neutral noon/overcast, cool readable night, distinct low winter morning; one coherent sun |
| 4. Softness / AO | 3 | Contact and soft shadows, crown AO; no eave or porch occlusion yet |
| 5. Ground richness | 3 | Lawn patches, leaf litter, joints, puddles, patchy snow; still no shrub/hedge types or garden beds, so ordinary days stay plain |
| 6. Character | 4 | Luna readable, contact shadow, ~22% framing (v2 01/04) |
| 7. Depth and fog | 4 | Good street depth and fog/storm/smoke separation; aerials now crisp in the centre with only the far edge softened (10, 11, v2 06) |
| 8. House variety | 3 | Unchanged v2 kit families (P2's area from here) |
| 9. Geography | 4 | Real OSM shoreline and paths, postcards composed from map data, sun and Moon positions verified numerically |
| 10. Motion | 3 | Videos: steady walking and flythrough, stable world-space snow/litter/puddles; dithered cut-away visible on a conifer, some LOD pops |
| **Total** | **35 / 50** (was 34) | **Gate (≥ 36) not met, one point short** |

**Top five gaps:** (1) ordinary-day ground and greenery: shrub and hedge types, garden beds, leaf litter that reads as leaves rather than flecks (12 is still plain); (2) house silhouettes and variety: boxes without eaves, porches or roof shapes (P2); (3) softness: eave, porch and base occlusion; (4) aerial composition: the detailed area sits on an empty plain, because the data stops at its edge (the specs forbid a made-up backdrop; a real lower-detail context ring is in the 5B estimate); (5) motion: some LOD pops and a visible dithered cut-away in the videos. Tree silhouettes and aerial haze, gaps 2 and 3 last time, are fixed.

**P3's look loop** isn't on main yet, so there are no look-loop scores in this report; I'll run it after the next visual change once it lands.

**Videos (60 s each, Simulator, golden hour):** `docs/videos/m3/street-loop.mp4` (Luna on the loop, follow camera) and `docs/videos/m3/route-flythrough.mp4` (no character). Recorded before tonight's changes; the Simulator was too overloaded tonight to re-record them (load average 300–600 from the parallel sessions' simulators).

**Ten-minute device runs (clear and rain):** not yet run. Per your speed-mode rules they're bundled into one daytime request (unplugged, Low Power Mode off) together with the real heat and battery runs. The WorldLab launcher has both buttons ready.

**Web:** `scripts/web_check.sh` rebuilds the package and the web bundle, serves them and loads the page in headless Chrome. It **passed**: WebGL2 rendered 914,914 triangles of the latest package (`5371b2b+changes`) at "golden", 2026-10-15T23:44:01Z, America/Denver, sun 6.001°, autumn, `sky-golden.png`. It takes about 11 minutes because headless Chrome renders WebGL2 in software, so it is a gate-time check, not a per-build one. The same page in a GPU browser (WebGPU) shows the same values (`docs/screenshots/m3/web-check-webgpu.jpg`). The web reads time, sky and season from the package's `environment.json`, with the 0–2° sun fade and chronological keys now inside those light states; no weather effects on the web, per decision 4.

## 6. Device results
iPhone 14 Pro, iOS 26.4.2, Release builds over Wi-Fi. Every run logs Low Power Mode, charging and battery level at start and end (and every 10 s in the console); a run is only used if it started unplugged with Low Power Mode off and nothing changed during it.

| Session (Oct 5–6, Denver time) | Conditions | Used for | Logs |
|---|---|---|---|
| 1. First checks, 20:52–20:57 | **Discarded.** On the charger for the first ~2 minutes, then WorldLab went to the background while you changed Settings (your heads-up); these runs predate the conditions line | nothing | `docs/perf/m3-phase5a/discarded/` |
| 2. Probe, 21:20 | **Discarded.** Low Power Mode was on (most likely switched on by the new Do Not Disturb Focus); the script stopped itself, and you turned it off | nothing | same folder, `probe-lpm-on.log` |
| 3. Clean runs, 21:23–21:34 (after a 10-minute rest) | Unplugged, Low Power Mode off, heat nominal throughout | §2 scale table, calm mode and pause, the RealityRenderer host comparison | `docs/perf/m3-phase5a/` (`console/sequence.txt` lists every run and its arguments) |
| 4. Gate loops, 23:19–23:24 | Unplugged, Low Power Mode off; nominal, then "fair" from 33 s in the rain loop | §2 GPU frame time, gate fps with section C on | `docs/perf/m3-phase5a-gate/` |
| 5. Overnight, Oct 6 from 00:42 | **On the charger (functional runs per your overnight rule)**, Low Power Mode off, heat "serious" most of the time | GPU cost by feature, rain hitch checks, on-device gate captures (below); no heat or battery conclusions | `docs/perf/m3-phase5a-attribution/`, `docs/screenshots/m3/` |

**Clean runs (session 3, street loop with Luna, golden hour, 60 s, before the section C work):**

| Run | Avg fps | 1% low | Worst frame | Memory | Notes |
|---|---:|---:|---:|---:|---|
| RealityView 2.5× | 60.0 | 58.9 | 17.3 ms | 395 MB | chosen |
| RealityView 3.0× (native) | 59.8 | 46.6 | 35.9 ms | 454 MB | misses the 1% low |
| RealityView 2.0× | 60.0 | 58.7 | 17.2 ms | 341 MB | |
| RealityRenderer host 2.5×, walking | 55.3 | 23.9 | 44.7 ms | 445 MB | experimental host |
| RealityRenderer host, idle postcard, calm off | 52.3 | 23.4 | 75.9 ms | 437 MB | |
| RealityRenderer host, idle postcard, calm on | 30.0 | 30.0 | 33.4 ms | 437 MB | calm mode works only on this host |
| RealityView pause test | 0 fps while paused | | | | resumes with the same world and post-processing |

Battery moved less than the 5% step iOS reports in any of these 60–120 s runs, and heat stayed nominal, so neither gives a heat or battery difference between settings; that needs the 10-minute runs.

**Gate loops with all of section C on (session 4, 2.5×, 60 s, Instruments attached for 8 s at about 40 s):**

| Run | Avg fps | 1% low | Worst frame | Memory | Notes |
|---|---:|---:|---:|---:|---|
| Clear | 59.6 | 36.5 | 65.1 ms | 401 MB | **60 fps with no frame over 17 ms for the 38 s before Instruments attached**; every dip falls inside the trace window |
| Light rain | 58.9 | 21.2 | 231.8 ms | 459 MB | one **232 ms stall at 9 s** (not reproduced since; below), then steady until the trace; stepped to 2.25× at 33 s ("fair") |

The traced seconds aren't representative (attaching Instruments stalls frames), so the fps verdict for section C comes from the untraced part and from the 10-minute runs still to do.

**GPU attribution (session 5, on the charger, functional only).** All runs at a fixed 2.5×; traces of 5–8 s at the requested maximum clock; details and method in `docs/perf/gpu-attribution.md`.

| Run | What it showed | Kept? |
|---|---|---|
| Walking loop, one feature off per 100 s | GPU time changed from 11 to 15 ms along the street with every feature on, so each phase measured a different stretch of street | No (moved to `discarded/`); the camera is now fixed |
| Fixed street view, old materials (`street-run1/`) | Shadows ≈ 37% of the frame, trees ≈ 28% of the main pass, MSAA ≈ 8%, surface extras ≈ 1%, sky pixels dearer than ground (clock-matched pairs only) | Yes, as shares |
| Fixed street view, opaque trees beyond 20 m (`street/`) | The old transparent trees cost 3.0 ms (24%) more per frame at the same clock. Every other pair ran while the GPU scaled its clock to the load (busy time ≈ 15.3 ms whatever was switched off), so those pairs say nothing | Only the tree result |

Heat was "serious" for almost all of it (the phone had been rendering on the charger for hours), and the trace shows the GPU at its minimum or medium clock although maximum was asked for. Attaching Instruments also drops frames, so none of these runs give fps numbers.

**Other functional checks tonight:**
- Two 50 s light-rain runs with a hitch log: **no frame over 100 ms after loading** (the 232 ms stall in the gate rain loop didn't recur). That loop also ran the test logger, which wrote to a file on the main thread every frame; those writes are now buffered and done off the main thread. The 10-minute rain run will confirm.
- On-device snapshots (new tool, `scripts/device_snapshots.sh`) work: RealityKit's capture matches the screen's own composite, post-processing included.

**Not yet run:** the two 10-minute RealityKit runs (clear and rain) and the heat and battery runs. They need the phone unplugged with Low Power Mode off, so they're bundled into one daytime request (§9).

## 7. Phase 5B estimate
Updated for the new test region: Chicago's North Shore, **Wilmette first** (residential, away from the lakefront), **then Lakeview**, using `docs/proposals/regions-chicagoland-miami/` and your art direction. **Building generation (house families, roofs incl. cross-gables/dormers/turrets, facades, rear porches, courtyard buildings) now belongs to P2** and is not in this estimate. Mine, in working days:

| Work | Days |
|---|---:|
| Live WeatherKit: provider (cell switching, 30/15-min refresh, memory cache), hourly history into the accumulation model within the storage rules, Apple Weather mark + legal link + modified-data notice, "Live" label; the Plano connection test stays | 3 |
| Wilmette area: OSM fetch (`out body`), manifest, region/profile selection from the proposal's catalogue, Chicago phenology prior (dense mature deciduous canopy, strong fall colour) | 1.5 |
| Ordinary-day richness (art direction): several shrub and hedge types, garden beds, leaf litter that reads as leaves near the camera, richer lawn | 4 |
| Lived-in details, sparse and within budget: bins, bikes, planters (placement rules only where evidence allows) | 2 |
| Chicago signatures: alleys (paving, edges, access from OSM), evidence-gated snow piles/curb banks; back porches coordinated with P2 | 2.5 |
| Lakeview: dense north-side street character (parkway trees, boulevards), courtyard landscaping inside P2's courts | 2 |
| GPU budget: from ~14 ms toward the 8 ms aim (attribution-led cuts; see §2) | 3–4 |
| Rain, second pass: lamp and window reflections on wet streets at dusk/night, puddle ripples | 1.5 |
| Aerial context: a lower-detail ring of real streets, blocks and water around the detailed area, so the aerial diorama isn't a data square on a plain (the specs forbid a fabricated backdrop) | 1.5 |
| Gate: screenshots, P3 look-loop scores, daytime heat/battery runs | 1.5 |
| **Total** | **≈ 22.5–23.5** |

Web weather parity is not included (see §8).

## 8. Platform options for computers and the web
| Option | What it is | Days to build | Upkeep |
|---|---|---:|---|
| **a) Full web weather parity** | Port section C to three.js: sky dome with Moon and stars, seasons with per-tree offsets and leaf drop, wet/puddle/snow shading, particles, display policy; keep both renderers in lockstep from the shared package | 10–12 | High: every look change is done twice; expect +40–60% on visual work, plus a second GPU budget to hold |
| **b) Web page with recorded postcards and videos** | Render postcards and short videos from RealityKit (device or Mac) per time/weather and publish a static page | 2–3 | Low: re-render after look changes; not interactive and no live weather |
| **c) Native Mac app reusing RealityKit** | WorldEngine already builds for macOS; add a Mac WorldLab target (window sizing, mouse/keyboard for explore and aerial, post-processing on macOS) | 4–6 | Low–moderate: same engine and look; Mac only (no Windows or browser) |

My recommendation: **c** for computers, and **b** if a public web link is needed, until the iPhone look is approved. **a** only if a live, interactive browser version is a product requirement.

## 9. Decisions needed
1. **Calm mode (Prompt 5 asked for 30 fps when still).** RealityView ignores every frame-rate control, so calm mode can't be done with it. Options:
   - **(a) No calm mode for now; pause when hidden stays (recommended).** No cost, no risk. I'd also file an Apple Feedback asking for a frame-rate control on RealityView, and re-test on each iOS release.
   - (b) Switch the idle postcard to the RealityRenderer host. Calm mode works there (30.0 fps), but that host walks at 55.3 fps with a 23.9 fps 1% low, and swapping hosts when the camera starts moving would likely hitch. About 2 days to make it seamless, and it might still not be.
2. **GPU budget (the 8 ms aim).** Before tonight the walking loop needed about 14 ms. The opaque trees saved about a quarter of the frame in the test view, and the other invisible savings are in; the daytime session gives the new walking-loop number. If it is still above 8 ms, what's left is visible:
   - **Shadow range** (now 80 m): shadows are about a third of the frame. A shorter range drops distant shadows (long golden-hour shadows across the street would end sooner); I'll measure 50 m and 30 m in the daytime session.
   - **MSAA off**: about 8%; edges of roofs, wires and trunks would shimmer slightly at 2.5×.
   - **Longer-term, no visible loss** (5B budget work): baked ground shadows and occlusion for static geometry, cheaper lighting for distant trees.
   - My recommendation: decide after the daytime numbers; if a cut is needed, the shadow range first.
3. **Platform for computers and the web (§8):** a, b or c. I recommend **c** (a native Mac app on RealityKit), plus **b** if you need a public web link before the iPhone look is approved.
4. **5B scope with P2:** please confirm the split in §7. P2 owns all building generation (house families, roofs, facades, porches, courtyard buildings). I take live WeatherKit, the Wilmette and Lakeview areas, ordinary-day ground and greenery, alleys, snow piles, sparse lived-in details, the GPU budget and the second rain pass.
5. **Rain look beyond the weather spec.** Per your art direction, rain now darkens asphalt by up to 34% (the weather spec says ≤ 12%), and puddles mirror the sky (the spec says no mirror reflections; I reflect only the sky, not the city). Keep it?
6. **Daytime device session, about 40 minutes of your phone,** when convenient:
   - Unplugged, Low Power Mode off, Auto-Lock Never, Do Not Disturb on, after 10 minutes off the charger.
   - The two 10-minute RealityKit runs (clear, then rain; the WorldLab launcher buttons).
   - A repeat of the GPU attribution unplugged at nominal heat.
   - Short heat and battery comparisons of the render scales.
   - I'll run everything; you only need to unplug the phone and tell me when it has rested.

## Appendix: everything touched in Phase 5A

Repository, `b76580c..phase5a` (plus this report):

- **Engine (`Sources/WorldEngine`):** `Sources/WorldEngine/Environment.swift` (new); `Sources/WorldEngine/Experience+World.swift` (new); `Sources/WorldEngine/GPUTime.swift` (new); `Sources/WorldEngine/PostProcess.swift` (changed); `Sources/WorldEngine/PublicTypes.swift` (changed); `Sources/WorldEngine/RenderControl.swift` (new); `Sources/WorldEngine/RenderResources.swift` (changed); `Sources/WorldEngine/RendererHost.swift` (new); `Sources/WorldEngine/Shaders/WorldShaders.metal` (changed); `Sources/WorldEngine/World.swift` (changed); `Sources/WorldEngine/WorldCamera.swift` (changed); `Sources/WorldEngine/WorldDiagnostics.swift` (changed); `Sources/WorldEngine/WorldView.swift` (changed)
- **Shared generator and data (`Sources/WorldGen`, `WorldMesh`, `WorldEnvironment`, `WorldPackage`, `worldbake`):** `Sources/WorldEnvironment/Catalog/STARS-NOTICE.md` (moved); `Sources/WorldEnvironment/Catalog/stars-hyg-v41-bright256.json` (moved); `Sources/WorldEnvironment/EnvironmentResolver.swift` (changed); `Sources/WorldEnvironment/EnvironmentState.swift` (changed); `Sources/WorldEnvironment/Phenology.swift` (changed); `Sources/WorldEnvironment/Stars.swift` (changed); `Sources/WorldEnvironment/SyntheticWeather.swift` (new); `Sources/WorldGen/Display.swift` (new); `Sources/WorldGen/Experience/CameraRigs.swift` (new); `Sources/WorldGen/Experience/ExperienceDefaults.swift` (new); `Sources/WorldGen/Experience/PostcardComposer.swift` (new); `Sources/WorldGen/Experience/RayWorld.swift` (new); `Sources/WorldGen/Lighting.swift` (changed); `Sources/WorldGen/Palette.swift` (changed); `Sources/WorldGen/Profiles/display.json` (new); `Sources/WorldGen/Props.swift` (changed); `Sources/WorldGen/StyleProfile.swift` (changed); `Sources/WorldGen/WorldBuild.swift` (changed); `Sources/WorldMesh/MeshBuffers.swift` (changed); `Sources/WorldPackage/WorldPackage.swift` (changed); `Sources/worldbake/main.swift` (changed)
- **WorldLab app:** `Apps/WorldLab/Resources/demo.json` (changed); `Apps/WorldLab/Sources/ContentView.swift` (changed); `Apps/WorldLab/Sources/Demo.swift` (changed); `Apps/WorldLab/Sources/EnvironmentController.swift` (new); `Apps/WorldLab/Sources/ExperienceOverlay.swift` (new); `Apps/WorldLab/Sources/Metrics.swift` (changed); `Apps/WorldLab/Sources/ViewDiagnostics.swift` (new); `Apps/WorldLab/Sources/WeatherKitProbe.swift` (new); `Apps/WorldLab/Sources/WorldLabApp.swift` (changed); `Apps/WorldLab/project.yml` (changed)
- **Web:** `web/src/main.js` (changed)
- **Tests:** `Tests/WorldEnvironmentTests/EnvironmentRuleTests.swift` (changed); `Tests/WorldEnvironmentTests/ShowcaseFixtureTests.swift` (new); `Tests/WorldEnvironmentTests/SkyFixtureTests.swift` (changed); `Tests/WorldGenTests/ExperienceTests.swift` (new); `Tests/WorldGenTests/TreeSilhouetteTests.swift` (new); `Tests/WorldGenTests/WorldGenTests.swift` (changed); `Tests/WorldMeshTests/WorldMeshTests.swift` (changed)
- **Scripts:** `scripts/attribution_costs.py` (new); `scripts/compose_gate.py` (new); `scripts/device_attribution.sh` (new); `scripts/device_checks.sh` (new); `scripts/device_gate.sh` (new); `scripts/device_snapshots.sh` (new); `scripts/encode_video.swift` (new); `scripts/gate_shots.sh` (new); `scripts/gate_videos.sh` (new); `scripts/gpu_attribution.py` (new); `scripts/gpu_frames.py` (changed); `scripts/gpu_sample.sh` (changed); `scripts/gpu_states.py` (new); `scripts/make_gpu_template.py` (new); `scripts/scale_compare.sh` (new); `scripts/web_check.sh` (new)
- **Docs:** `docs/perf/gpu-attribution.md` (changed); `docs/m3/report.md` (new, this report); `docs/environment.md` (changed); `docs/experience.md` (new); `docs/package-format.md` (changed)
- **Repo files:** `.gitignore` (changed); `Package.swift` (changed); `README.md` (changed)
- **Results committed as data:** `docs/perf/m3-phase5a/` (27 files); `docs/perf/m3-phase5a-attribution/` (8 files); `docs/perf/m3-phase5a-gate/` (12 files); `docs/screenshots/m3/` (36 files); `docs/videos/m3/` (2 files)
- **Proposals committed unedited (ChatGPT's, read-only):** `docs/proposals/regions-chicagoland-miami/`; `docs/proposals/regions-northshore-chicago-miami/`
- **Outside the repository:**
  - Xcode DeviceSupport 26.4.1 deleted (5.7 GB, §1); nothing else deleted outside the repo.
  - Your iPhone: WorldLab Release builds installed and run (device checks, gate loops, attribution, snapshots); every run's conditions are logged (§6).
  - Simulators: created "WorldEngine P0" for this session (shut down tonight to ease the Mac's load); the shared "iPhone 17 Pro" was used before that.
  - Sub-agent worktrees under `.claude/worktrees/` (tree silhouettes, device snapshots): merged, then removed with their branches.
  - Not touched: P1 (`tools/regionkit/`, `docs/research/`), P2 (building generation), P3 (`tools/lookloop/`), `docs/proposals/` (read only; `postcards-widgets-v1/` appeared tonight from another session and was left alone).
