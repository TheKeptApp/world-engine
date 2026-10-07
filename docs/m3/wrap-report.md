# 5A wrap + 5B start: report (Prompt "5A wrap + 5B")

Device: iPhone 14 Pro, iOS 26.4.2. Branch: `phase5b`. The official gate is now P3's look loop (independent grading); its scoreboard rows are quoted below.

## 1. Daytime device results
Phone unplugged, Low Power Mode off, Auto-Lock Never, Do Not Disturb on; 57 min of phone time (06:38–07:35 Denver), including two short restarts (Low Power Mode had switched itself back on; a trace path fix on my side). Logs: `docs/perf/m3-daytime/`.

**Ten-minute runs** (Luna on the street loop at golden hour, 50% brightness, 2.5× until heat steps it down):

| Run | Avg fps | 1% low | Worst frame | Frames > 100 ms | Memory peak | Heat | Battery |
|---|---:|---:|---:|---:|---:|---|---|
| Clear | 60.0 | 57.7 | 38.5 ms | 0 | 431 MB | nominal throughout, 2.5× | 75% → 70% |
| Light rain | 59.9 | 57.2 | 47.9 ms | 1 | 487 MB | nominal, "fair" from 9 min 17 s, then 2.25× as designed | 65% → 60% |

Both clear the 60 fps target (avg ≥ 58, 1% low ≥ 50). iOS reports battery in 5% steps: over the whole session the phone went from 85% to 60% in 57 minutes of continuous rendering (≈ 25% per hour). The 232 ms rain stall seen in 5A didn't return.

**GPU time.** The walking-loop trace, taken during the session, measured 15.07 ms per frame at the GPU's medium clock state: 90.5% busy at 60 fps. iOS lowers the GPU clock until a frame just fits, so busy time sits near 15 ms whatever the work. A work measurement needs the clock pinned (Xcode, Device Conditions, GPU Performance State: Maximum). That repeat is waiting for you to set the pin.

The new frame-log hook (§3) gives the first full-clock number without a trace: **9.1 ms per frame on the Sloan's Lake street view** in the first 10 s after launch, before iOS lowers the clock. That is above 8 ms, so per decision 2 the **sun-shadow range is now 60 m instead of 80 m**:
- it's the bottom of the lighting bible's 60–80 m band;
- edge smoothing stays on;
- the shadow map's texels cover 25% less ground, which also sharpens the jagged wall-base strip.

The earlier valid trace numbers still hold:
- cutting the near detail saves 2.97 ms (24%);
- without MSAA the street view takes 8.51 ms at maximum clock.

The pinned repeat (`HUD=1 scripts/device_attribution.sh`, about 15 min) will measure the 60 m saving and every other feature.

**Videos (60 s):** PLACEHOLDER-VIDEOS

## 2. Bug fixes, with before/after look-loop scores
Before: P3's run at 06:39 on engine `651649b` (main with all of 5A): **mean 27.5/50, ordinary days 28.9, 0 of 17 views passing**, worst view the rain aerial (21.3).

Fixes, in the order of your list. "Gate" columns come from P3's declared gate run on main `1b7709b`, which includes every fix up to the 5A-wrap merge. The lighting-bible pass (look-fix-v1, on phase5b after `1b7709b`) is graded in the next run.

| Bug (source) | Fix | Measured on the phone |
|---|---|---|
| Fog (25–220 m) and smoke don't render (P3) | Pass 1: linear fog ramp, veil over the sky, sun, Moon and stars. Bible pass: weather extinction T = exp(−k(d − start)) with 90% gone at the fog end, at the weather's intensity; clear-air fade capped per state (§2.3/§3.2) | Fog frame: saturation 73 → 44 (bible 32) with the extinction; whole-frame mean 151 (bible 147) |
| Tree trunks pure black at night (P3) | Night exposure keys 1.6 (dawn/dusk 1.5); bible night sky and fill tints; exposure solved to the bible's night means (57 moonlit, 43 moonless) | See §2 table; the night floor (§2.4 bands) is still being tuned |
| Clear 15:30 street too dark (88 vs 128–157) (P3) | Post-process auto exposure, now solved against the displayed Y8 mean per state (bible §2.2), plus clear-air fade instead of 96% distance fog | Ordinary-street 101 → 124 (pass 2); bible ordinary state 149 → 140 target after the solve |
| Low sun lacks a warm key and long shadows (P3) | Warm golden key (bible #FFC17B), sun ×1.8 at ≤4°, fading by 25°; true sun direction checked against the bible fixtures (`SunBearingTests`: bearing within 1°, length within 5%) | Golden-hour state 129/130 mean |
| Roofs near-black, walls muddy in shade (P2) | Renderer side: bible sky-fill and shade tints, lift tuning (in progress). Palette side: tone targets sent to P2 (`docs/m3/tone-targets.md`) | Lift 0.17 vs the bible's 0.30–0.38; being fixed with `-tune` sweeps |
| Jagged dark strip along wall bases (P2) | Shadow-map aliasing from foundation shrubs on sunlit wall bases. Sun-shadow range 80 → 60 m: 25% less ground per shadow texel | To confirm on the next phone frames |
| Aerial floats on a flat green plane (P3) | Backdrop beyond the data is the bible's coverage colour (#A9B4A0 summer, #BDC8D4 winter), not lawn; P1's real context ring follows | – |
| Crowns don't read from altitude; identical flat diamonds (P3) | Tree agent: per-tree proportions, two-lobe far crowns (52 triangles), a 12-triangle skyline level beyond 400 m drawn darker; engine: fifth LOD slot by 3D eye distance | Aerial tree triangles 404k → 61k (generator count) |
| Heavy aerial haze (P3, then the reverse regression) | Clear-air fade capped at 30–40% (bible §2.3; aerial core ≤25% by optical depth) instead of the linear fog | – |

GATE-SCORES

**Look-fix pack as data (owner's instruction).** The complete pack is committed unedited (`docs/proposals/look-fix-v1`).
- **Generator.** `scripts/lookfix_data.py` reads `lighting-fixtures.json` and the spec's §2.2–2.4 and §3.1–3.2 tables, and generates `Sources/WorldGen/Profiles/lighting-bible.json` with the sources' SHA-256. Its contents:
  - all twelve states: sun, Moon, weather inputs, Y and saturation targets, key:fill, EV, tints, lift, shade tint, clear-air fade;
  - night ambient, windows and patch bands;
  - wet response and extinction presets.
- **Time-of-day colours.** The script also sets the bible-owned colours in `time-of-day.json`. It reproduced my earlier hand-set values exactly, so nothing on screen changed.
- **Engine.** The engine reads targets from the generated file. `grade.json` now holds only tuning measured on the phone: saturation, direct and fill multipliers.
- **Tests.** They fail if the proposal changes without regenerating (hash check), or if `time-of-day.json` drifts from the bible. The sun-bearing test reads its fixtures from the same data.
- **Not loaded.** `lighting-fixtures.json` itself holds the twelve states' time, weather and sun/Moon only. The appearance numbers come from the spec's tables, parsed by the script.
- **Sky.** `sky-projection-reference.json` will drive a star-placement test (projected catalog positions per night fixture) when sky polish (rank 10) comes up.

## 3. Hooks for P3 (and P2)
All in WorldLab (`Apps/WorldLab/Sources/Demo.swift`, `ContentView.swift`, `Resources/demo.json`) unless noted; on main from `c4cdf0e`.

| Hook | How |
|---|---|
| `-area ID` | Opens another bundled area: `evanston-south` and `lakeview-sheil-park` (P2's test areas) are now inside the app next to `sloans-lake`. `demo.json` → `areas` gives each its focus box, style profile, time zone, place label and named cameras. Other areas have no walking loop or showcase. |
| `-camera NAME` or numbers | Named cameras per area: `northshore-postcard`, `wesley-street`, `evanston-aerial` (Evanston); `lakeview-postcard`, `roscoe-street`, `chicago-alley`, `lakeview-aerial` (Lakeview). The regions fixtures' own locations are approximate references outside these areas, so their compositions (eye 1.65 m, 3° down, 50°) are placed on public streets inside. Explicit: `lat,lon,heading,pitchDown,fov` (eye 1.65 m) or `lat,lon,height,heading,pitchDown,fov`. A named camera with `distance` orbits a ground point (aerial obliques). |
| `-focus S,W,N,E`, `-weatherspec …` | The full-detail box; explicit Demo weather (`label=rain,intensity=0.5,cloud=0.8,rate=2,wetness=0.7,swe=6,…`) for the regions fixtures' weather values. |
| In-view triangles and draws | With `-rendertrace`, a `VIEW t= triangles= draws=` line every second: world triangles and draw calls in entities whose bounds meet the camera frustum (`WorldStats.viewTriangles`, new `viewDrawCalls`). Sky, rain and characters aren't counted. The `RENDER` line is unchanged, so P3's parser keeps working. |
| GPU frame time on device | Metal's own frame log, read from the console: launched with `MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 OS_ACTIVITY_DT_MODE=1` (devicectl `-e`), WorldLab's console carries a `metal-HUD:` line twice a second with every frame's interval and GPU time. `scripts/gpu_hud.py` (new) splits them per view (`-viewlist`), per attribution phase or per 10 s. `scripts/device_views.sh` takes `GPU=1` (GPU time per look-loop view) and `scripts/device_attribution.sh` takes `HUD=1` (feature costs without Instruments traces, which kept dropping over Wi-Fi). RealityView exposes no GPU timing of its own, so the in-app `RENDER` line keeps `gpu=-`. First reading, Sloan's Lake street (v2-01): 9.1 ms per frame for the first 10 s, then 15.2 ms once iOS lowers the GPU clock, at 60.0 fps throughout. The second number is the clock governor, not the work, so work is compared only with the clock pinned (§1). |

## 4. Building LODs
Wired: P2's `BuildingGenerator.generate(_:palette:lod:)` + `BuildingLOD.forDistance` (near < 50 m, mid < 150 m, far < 600 m, skyline beyond).
- Generator (`SceneGenerator.buildingLODs`, on for RealityKit only; the package for three.js is unchanged): every focus building at near/mid/far/skyline and every context building at far/skyline, into ~100 m cells instead of the chunk meshes. Yards and occluders keep using the same per-building result as before.
- Engine: one entity per cell and LOD; `updateLODs` enables one per cell by the camera's distance to the cell (the next coarser level where a cell lacks one). Counted in the view and world stats.
- Tested (`BuildingLODCellTests`): every cell has far and skyline; detail never grows with distance; the same buildings, yards and occluders; Sloan's Lake chunk triangles 221k → 71k as the buildings move into cells.

In-view triangles on the phone (the new `VIEW` line), before → after the building LODs:

| View | Before | After | Draws |
|---|---:|---:|---:|
| Sloan's Lake street (v2-01) | 743k | 663k | 228 |
| Sloan's Lake park (showcase) | 767k | 653k | 195 |
| Sloan's Lake aerial | 870k | 698k | 296 |
| **Lakeview, W Roscoe St** | – | **417k** | 152 |
| Lakeview postcard (Roscoe, east) | – | 270k | 102 |
| Lakeview alley | – | 321k | 116 |
| Lakeview low aerial | – | 278k | 89 |

The Lakeview street view is within 5% of P3's 400k cap. Trees are now the largest share (Sloan's Lake has ~5,400 mapped trees plus ~900 of P2's yard and parkway trees); the cheaper far trees and a new skyline tree level (PLACEHOLDER-TREES) should take every view under 400k. PLACEHOLDER-LODGPU

## 5. Postcard export
PLACEHOLDER-POSTCARD

## 6. My 5B plan
My lane only (rendering, materials, lighting, weather, sky, cameras and postcards, WorldLab, integration, device performance), built against ChatGPT's look-fix pack (`docs/proposals/look-fix-v1`, §8's ranked queue) and its numbers. City test Lakeview first, suburb second. The gate is P3's concept parity at 100% with v2's per-criterion floors. The budget is regions spec §14 and look-fix §7: 60 fps and ≤10 ms GPU per frame on iPhone 13-class hardware. Each step is measured on the phone with `scripts/lighting_bible.py` before P3's loop grades it. About 8 working days:

| Day | Look-fix rank | Work | Done when |
|---|---|---|---|
| 1 (wrap) | 1, 5 | Lighting bible pass 1 (on phase5b): per-state exposure and saturation, clear-air fade, weather extinction, solved auto exposure. Then lift and coloured shade from `-tune` sweeps (key:fill toward 2.2, shade tint #6E7FAC), night floor (trunks, roofs, walls in §2.4 bands) | ≥48 of 60 lighting-bible values in tolerance; gate parity ≥85% |
| 2 | 2, 4 | True sun-bearing check (§2.1 pole capture) and long golden shadows within the 60 m range; wet ground and puddles verified with particles off, cloudy light | Bearings within 1°; rain views AD rain ≥3 |
| 3 | 6, 7 | Lakeview budget: tree skyline level (wired), building shadows from the far level (P1 audit item 5), draw-call grouping. Aerials: P1's context ring with the §4 coverage fade, framing of the true bounds plus 10–15% | Every Lakeview view <400k triangles and ≤100 draws; GPU (pinned clock, scaled to the A15) ≤10 ms; no floating tile |
| 4 | 3 (5A half) | Lawn material for P2's per-lot tones and patches (§1.1), leaf litter from P2's patches with the fall mask (§1.3), bed and soil edges | Ground and AD ground ≥3 on the street views |
| 5 | 8 | Snow separation (§3.3), the bare-tree and night regression sweep, the regions fixtures as weather presets with P3 (lake fog, lake-enhanced snow, snowmelt, spring bloom, summer storm) | Snow views keep roof, lawn and street apart; all 21 fixtures render |
| 6 | – | Postcards: quality mode measured on the phone (<1.5 s on an A15 by scaling), the live-vs-quality loop pair, the bible's per-state grade in the quality path | Quality gap visible in the loop; export timing logged |
| 7 | – | Suburb (Wilmette or Evanston): four-state camera (clear, rain, fall, snow), close, mid and aerial transitions (roof popping, vanishing gangways) | Suburb parity ≥100% |
| 8 | 10 (if time) | v2 device checks on both test areas (10-minute runs, heat, battery, memory), 60-second videos, report. Sky polish (§6) only if ranks 1–8 pass ("if ground still scores 2, do not divert the next day to prettier stars") | Device checks pass on both areas |

## 7. Decisions needed
1. **iPhone 13-class measurements.** The budget (≤10 ms GPU, regions §14 and look-fix §7) is set for iPhone 13-class hardware. Our only phone is a 14 Pro (A16, 5-core GPU). Choose one:
   - (a) I report 14 Pro numbers scaled ×1.25 as the A15 estimate (4-core GPU, lower clock), marked as estimates.
   - (b) An iPhone 13 joins the device checks.
   - I recommend (b) before the 5B device gate, and (a) until then.
2. **look-fix-v1 is on disk but incomplete.** `docs/proposals/look-fix-v1/` appeared untracked at 08:05–08:15:
   - Present: the spec and lighting-fixtures.json.
   - Empty: the `images/` folder.
   - Missing: VALIDATION.md, image-manifest.json, PROMPT-LOG.json and README.md, which the spec links to.
   - Choose: commit it unedited as it is (as with earlier proposals), or wait for the complete delivery. Until then I build against the text and numbers only.
3. **GPU pin (a request, not a decision).** When convenient: Xcode → Window → Devices and Simulators → your iPhone → Device Conditions → Condition "GPU Performance State", Profile "Maximum" → Start, then tell me "GPU pinned". The repeat now takes about 15 minutes and no Instruments traces. Click Stop when I say it's done.

## Appendix: everything touched
Repository: my commits on `phase5b` since the 5A merge (`01b0036`), plus the tree sub-agent's commit (`fd2897f`) and this report. Merges of P1, P2 and P3 work are theirs.

- **Engine (Sources/WorldEngine):** `Sources/WorldEngine/Environment.swift` (changed); `Sources/WorldEngine/GPUTime.swift` (deleted); `Sources/WorldEngine/PostProcess.swift` (changed); `Sources/WorldEngine/RenderControl.swift` (changed); `Sources/WorldEngine/RenderResources.swift` (changed); `Sources/WorldEngine/RendererHost.swift` (deleted); `Sources/WorldEngine/Shaders/WorldShaders.metal` (changed); `Sources/WorldEngine/World.swift` (changed); `Sources/WorldEngine/WorldCamera.swift` (changed); `Sources/WorldEngine/WorldDiagnostics.swift` (changed); `Sources/WorldEngine/WorldView.swift` (changed)
- **Generator and data (Sources/WorldGen, WorldMesh, WorldPackage):** `Sources/WorldGen/Display.swift` (changed); `Sources/WorldGen/Grade.swift` (new); `Sources/WorldGen/Profiles/base-palette.json` (changed); `Sources/WorldGen/Profiles/display.json` (changed); `Sources/WorldGen/Profiles/grade.json` (new); `Sources/WorldGen/Profiles/seasonal-palette.json` (changed); `Sources/WorldGen/Profiles/time-of-day.json` (changed); `Sources/WorldGen/Profiles/weather.json` (changed); `Sources/WorldGen/Props.swift` (changed); `Sources/WorldGen/SceneGenerator.swift` (changed); `Sources/WorldGen/Streetscape.swift` (changed); `Sources/WorldGen/StyleProfile.swift` (changed); `Sources/WorldGen/WorldBuild.swift` (changed); `Sources/WorldPackage/WorldPackage.swift` (changed)
- **WorldLab:** `Apps/WorldLab/Resources/demo.json` (changed); `Apps/WorldLab/Sources/ContentView.swift` (changed); `Apps/WorldLab/Sources/Demo.swift` (changed); `Apps/WorldLab/project.yml` (changed)
- **Tests:** `Tests/WorldGenTests/GradeTests.swift` (new); `Tests/WorldGenTests/SunBearingTests.swift` (new); `Tests/WorldGenTests/TreeSilhouetteTests.swift` (changed); `Tests/WorldGenTests/WorldGenTests.swift` (changed); `Tests/WorldPackageTests/WorldPackageTests.swift` (changed)
- **Scripts:** `scripts/attribution_costs.py` (changed); `scripts/device_attribution.sh` (changed); `scripts/device_checks.sh` (changed); `scripts/device_session.sh` (new); `scripts/device_views.sh` (new); `scripts/gate_videos.sh` (changed); `scripts/gpu_hud.py` (new); `scripts/heavy.sh` (new); `scripts/lighting_bible.py` (new); `scripts/lookloop_viewlist.sh` (new)
- **Web:** `web/src/world.js` (changed)
- **Docs and data:** `docs/environment.md` (changed); `docs/m3/tone-targets.md` (new); `docs/package-format.md` (changed)
- **Results committed as data:** `docs/perf/m3-daytime/` (logs, attribution, runs); `docs/m3/tone-targets.md`
- **Outside the repository:**
  - **iPhone:** WorldLab Release builds installed and run: the daytime session, lighting-bible captures, view captures, the Metal frame-log test. Every run's conditions are logged.
  - **Simulators:** "WorldEngine P0" only, for the videos, shut down afterwards. The shared LookLoop Simulator is P3's; I don't touch it.
  - **The Mac's shared lock:** `~/.agent-heavy-lock`, taken by `scripts/heavy.sh` for my builds and tests. The first version of the helper misread P3's owner file and wrote over it at 08:41 (fixed at 08:58, P3 informed). The lock dirs it later removed were its own or released at P3's request.
  - **Sub-agent worktrees** under `.claude/worktrees/`: tree variety (merged); postcard export (in progress).
  - **Not touched:** P1 (`Tools/regionkit/`, `docs/research/`), P2's building generation, P3 (`Tools/lookloop/`, `docs/lookloop/`). `docs/proposals/` was only read; `look-fix-v1/` is left untracked as it arrived.

