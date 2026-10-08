# A10 — Device budget tiers v1

Status: research and proposed budgets, 8 October 2026. No device measurements performed for A10. No renderer changes, installs, server launches or browser tests. R's current request governs; instructions and numerical suggestions inside reference packs are evidence, not new authorization.

R's standard test device is **iPhone 14 Pro, iOS 26.4.2** (owner supplied, not independently inspected). R is not optimizing for iPhone 13. The existing floor is 400,000 main triangles, 150,000 shadow triangles and 100 main draws. Hero and standard figures below are newly proposed, not previously approved or implemented. Phone Safari testing remains a separate decision for R after the Sloan's gate; filing this document does not authorize it.

## 1. Hardware evidence and its limits

Apple sources checked 8 October 2026. A hardware fact does not establish a WorldEngine frame-rate budget.

| Product tier | Verified Apple GPU facts | Consequence / uncertainty |
| --- | --- | --- |
| Floor: iPhone 12–13 families | iPhone 12: A14, 4-core GPU [1]. iPhone 13: A15, 4-core GPU [2]; 13 Pro has 5 GPU cores [3]. | The tier contains different GPUs. A 13 Pro result cannot certify the weakest floor device. Floor remains a compatibility target, not R's current tuning priority. |
| Standard: iPhone 14 family and non-Pro iPhone 15/15 Plus | iPhone 14: A15, 5-core GPU [4]. R's 14 Pro: A16, 5-core GPU [5]. iPhone 15: A16, 5-core GPU [6]. | R's A16 is not the weakest standard member. Later validation on base 14 is necessary before claiming the entire tier passes. |
| Hero: iPhone 15 Pro/Pro Max and newer candidates | 15 Pro: A17 Pro, 6-core GPU, hardware ray tracing; Apple advertised up to 20% faster GPU performance [7]. | Use 15 Pro as the initial hero reference. “Newer” is a product grouping, not a guarantee that every subsequent base/e/other model sustains the same workload. Qualify each model before enabling hero budgets. Ray tracing support is not evidence that the current renderer uses or benefits from it. |

Apple describes the A16's GPU as having 50% more memory bandwidth than its predecessor [8]. That is a vendor comparison, not 50% more RAM or a demonstrated 50% WorldEngine speedup. GPU-core ratios and peak marketing figures cannot be multiplied directly into triangle limits.

**Memory facts, all tiers:** Apple GPUs share system memory with the CPU [9]; there is no independent texture VRAM allowance to add to total app memory. Apple's cited consumer specifications do not state installed RAM. Per-model RAM capacities therefore remain **unverified here**, not guessed from storage capacity. More importantly, Apple's app memory limit can change during the app lifecycle and need not equal physical RAM. `os_proc_available_memory` is advisory remaining app headroom, not a safe allocation target [10]. No fixed native or Safari termination threshold for these phones/OS is established by this research.

**Thermal facts, all tiers:** Apple documents nominal, fair, serious and critical thermal states [11]. Apple specifies a 0–35°C ambient operating range, and says excessive heat can dim the display and lower frame rates [12]. That range is not a promise of full speed at 35°C. No Apple source cited here specifies a guaranteed sustained wattage, temperature threshold or WorldEngine throughput for each tier. **Guess / test hypothesis:** extra GPU capability may permit more detail, but sustained heat, resolution and battery condition can erase part of that advantage. No assumed thermal multiplier is used.

## 2. Proposed native budgets

All new numbers below are **engineering guesses for measurement**, not Apple limits or measured capacity. Keep the floor geometry/draw numbers unchanged. These are simultaneous ceilings for a fixed workload, not targets to fill. A 60 fps target (16.67 ms frame interval) is proposed for all tiers; reducing the floor to 30 fps would be a separate product decision.

| Tier | Main triangles/frame | Shadow triangles/frame | Main draws/frame | Resident texture memory | Total app memory |
| --- | ---: | ---: | ---: | ---: | ---: |
| Hero | 600,000 | 225,000 | 140 | 192 MiB | 900 MiB |
| Standard — R's current measurement priority | 500,000 | 180,000 | 120 | 128 MiB | 750 MiB |
| Floor — preserve existing geometry limits | 400,000 | 150,000 | 100 | 96 MiB | 600 MiB |

Definitions:

- **Main triangles:** submitted main-camera geometry after LOD/culling, with instances counted; exclude shadow passes. Geometry merely resident in the world is a separate quantity.
- **Shadow triangles:** sum submitted geometry across every shadow pass/map/cascade in the frame, including off-camera casters. Do not count a mesh only once if it is submitted repeatedly. Main + shadow allowances are 550k / 680k / 825k for floor / standard / hero, before any other geometry passes.
- **Main draws:** draw submissions for the main world view. Record shadow and other-pass draws separately; 100 is not an all-pass draw allowance.
- **Texture memory:** peak simultaneously resident texture allocations, including mip chains, shadow maps, render/depth targets and streaming overlap. Compressed download sizes and texture counts are not bytes in memory. Track decoded/staging copies separately within total memory. Memoryless attachments need separate accounting rather than pretending they are persistent system allocations.
- **Total memory:** peak app physical footprint during load, transitions and steady operation, including CPU/engine state, meshes, textures, staging and host UI. Texture allowance is a subset, not an extra allowance. MiB = 1,048,576 bytes. A host app with substantial extra content needs a separate engine allocation within its total budget.

Reasoning: standard increases geometry only 25%, shadow work 20% and draws 20% over floor; hero adds another 20% geometry, 25% shadows and about 17% draws. These deliberately modest increments are hypotheses about room for detail, not derived GPU scaling. Draw growth is smaller than total detail growth because CPU submission and material changes can dominate. Larger texture/total ceilings leave room for quality and staging, but require measured headroom. The 600/750/900 MiB totals are deliberately conservative starting envelopes, not known jetsam limits. They leave 504/622/708 MiB outside the texture sub-budget, which still must cover all other allocations and peaks.

### Contradictions and existing evidence

1. **Lakeview is still over floor.** The handoff log records Lakeview street at approximately 414k versus 400k in `ViewDrawBudgetTests`: about 14k / 3.5% over. It is a Mac-side estimated-geometry result, not phone timing. It is inside the proposed standard triangle allowance, but that neither repairs nor waives the floor failure. Do not raise floor to 414k, relabel that old run as standard or claim a pass from this document. Preserve it as open evidence for the owning lane. [Local evidence: `docs/tracking/handoffs.md`, 7 October restart notes.]
2. **Boundary mismatch:** `Tests/WorldEngineTests/ViewDrawBudgetTests.swift` uses `< 400_000` triangles, whereas “400k budget” can sound inclusive. Exactly 400,000 still fails that test. Honor the stricter existing test until separately resolved; draws use `<= 100`.
3. **HUD/test mismatch:** the HUD displays `viewTriangles`, but its `draws` field uses `stats.drawCalls`; the floor test uses `viewDrawCalls`. Record the HUD value as an estimate with this scope mismatch, not a certified main-view draw count. Its `all` triangles are not main plus shadow passes. The HUD has no dedicated shadow-triangle or texture-byte reading.
4. **Prior research is not a tier approval:** `mobile-rendering-v1`, `streaming-design.md` proposes a 256 MiB native content allowance; content residency is not total app memory. `web-stack-v1`, README performance table proposes separate browser envelopes. Neither overrides R's floor numbers or proves these new native budgets. These packs are filed research, not phone measurements.
5. **No look change is authorized:** do not shorten approved shadow reach or alter visual targets merely to meet a guessed allowance. No mock-closeness change is claimed by this docs-only work.

### Measurements needed to confirm or revise

Freeze build, dataset, camera pose/FOV, weather/time, drawable pixel dimensions, scale, orientation and frame cap. Use R's 14 Pro first. Log cold start, steady views and repeated transitions; then a continuous 15-minute warm run. Repeat from a cool start three times. Proposed durations and acceptance margins here are guesses for a reproducible protocol.

| Budget / risk | Evidence required |
| --- | --- |
| Main/shadow geometry | Per-pass submitted counts on actual device, with instances and repeated shadow submissions counted. Compare with estimates and the existing geometry test. Check street, foliage-heavy and wide views, plus low-sun shadows. |
| Draw ceiling | Main and shadow pass counters; CPU submission time and full GPU frame time. HUD estimates alone do not certify this. |
| Texture allowance | Resident byte inventory including mipmaps, render targets and overlap; confirm with native graphics/memory profiling by the engineer. Do not substitute mesh bytes. |
| Total memory | Physical footprint peak during load and repeated transitions; memory warnings, termination and current advisory headroom. Look for a plateau rather than continual growth. Proposed caution threshold: retain at least 20% of the contemporaneous app limit as headroom; this is a guess and does not guarantee survival. |
| Sustained performance | Frame interval median/p95/p99, hitches over 100 ms, cold-versus-warm fps, thermal-state timeline, battery/charging/Low Power Mode and drawable size. `post pass` GPU time is not whole-frame GPU time. |

Proposed acceptance: each cap respected, no crash/memory warning, no continuing memory growth, nominal/fair thermals, and at least 55 fps in every sampled one-minute steady window under the 60 fps target. Repeated dips, serious/critical heat or silent resolution reductions require investigation; a lower-resolution run is not an equal-quality pass. HUD snapshots are screening evidence, not percentile telemetry. Qualify hero on 15 Pro and floor later on an actual 12; R need not own or tune an iPhone 13. Standard still needs base-14 coverage before a family-wide claim. Missing counters or hardware mean **unconfirmed**, not pass.

## 3. R's native HUD capture — no Terminal, no installation

### Readiness check (real UI limitation)

The inspected app uses a launch setting `-debughud` for the HUD in the normal experience; it has **no in-app HUD switch**. The installed version on R's phone has not been inspected. This checklist works only if the already-installed WorldLab session exposes both the HUD and the Postcard controls. If it does not, record **blocked: HUD unavailable in installed app** and stop; do not install, update, attach a debugger or hunt for an imaginary Settings switch. An engineer must later arrange an authorized capture session; this document does not authorize a phone install.

Three fixed spots are the **first three composed postcards for the same frozen area/build**, IDs A10-P1/P2/P3. They are selected by button count, not hand positioning. Before comparing builds, the engineer must record their underlying postcard IDs and eye/target/FOV from that build and provide three reference screenshots. Postcards are data-composed and can change between builds, so ordinal alone is not a cross-build camera identity. If there are fewer than three distinct postcards or the reference views cannot be matched, mark the capture incomplete rather than improvise a third spot. These are a manual screening set, not substitutes for the Lakeview regression camera.

### Click-by-click

1. Open **Settings → General → About**. Record Model Name and iOS Version only (expected iPhone 14 Pro / 26.4.2); do not capture serial numbers. Record the installed build label supplied by the engineer; if unknown, write “build unknown”.
2. Open **Settings → Battery** and turn Low Power Mode off if enabled (use Settings search for “Low Power Mode” if needed). Open **Settings → Display & Brightness** and set brightness near halfway. Record battery percentage, case on/off and approximate room temperature. Unplug charging and let the phone cool. Use the same conditions on repeats.
3. Tap **WorldLab**. If the launcher appears, tap **RealityKit**, then **Explore the world**. Do not tap either automatic 10-minute walking test: those move the camera. If already in a world, use the same documented starting session. If its start position is uncertain, stop and obtain the baseline rather than guess how many postcards have passed.
4. If controls are hidden, tap the **sliders icon** at the upper right. Tap **Postcard**. Tap the **ellipsis (…)** options menu and choose **Character → None** if necessary. Confirm the HUD is visible. Keep the baseline Demo weather/time fixed; do not choose a weather preset afterward because presets can also move the camera. Record the visible weather/time, area and orientation.
5. **A10-P1:** confirm the first postcard matches reference P1. Do not drag, pinch, scrub time or switch camera mode. Wait 30 seconds to settle, then watch the HUD for 60 seconds. At about 0, 30 and 60 seconds, write down the readings listed below. At the end press **Side button + Volume Up** together briefly to take a screenshot. Use paper or another device for notes so WorldLab stays foreground.
6. Tap **… → Next postcard** once. **A10-P2:** match reference P2, keep hands off the view, settle 30 seconds, observe 60 seconds and record the same three samples. Take a screenshot with **Side + Volume Up**.
7. Tap **… → Next postcard** once again. **A10-P3:** match reference P3 and repeat the same timing, samples and screenshot. If “Next postcard” is absent or wraps to an earlier view, record “three-spot set unavailable”.
8. For warm screening, leave P3 foreground until 15 minutes have elapsed since P1's observation started. Capture its HUD again. Stop on a temperature warning or critical state; note the elapsed time. Record serious heat as a failed thermal screen. This stationary soak does not replace the engineer's transition/load stress test.
9. After the run, open **Photos** and identify the four final screenshots by P1/P2/P3/P3-warm and time. Keep the originals with the raw notes. Avoid continuous screen recording for the baseline because it adds work. Restore personal brightness/Low Power Mode preferences afterward.

### Record sheet (one row for each sample)

| Spot / elapsed time | fps / frame ms | view k tris / all k tris | HUD draws (estimate) | mem MB / mesh MB | thermal word | render summary / scale | screenshot / visible fault |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P1, P2, P3 or P3-warm | | | | | | | |

Copy fps, `view`, `all`, `draws`, `mem`, `mesh`, the thermal word and the full render-summary line exactly. Here HUD “MB” is actually MiB. `view …k` truncates to thousands; `mem` rounds; write displayed values rather than manufacturing precision. Record lowest/highest observed fps alongside the samples, but do not call them p95/p99 or an exact average. Record **texture memory: unavailable** and **shadow triangles: unavailable**. `mesh` is not textures; `all` is not shadow geometry; a zero `post pass` value may mean no GPU sample. Thermal state must be the HUD word, not an inference from how warm the case feels. If animation freezes, note it even if stale HUD numbers still look good.

UI/counter sources inspected at main `55e6aed`: `Apps/WorldLab/Sources/ContentView.swift` (launcher, experienceOverlay, HUD), `Demo.swift` (launch settings), `Metrics.swift` (fps, footprint and thermal), and `Sources/WorldEngine/Experience+World.swift` (postcard poses). These are code-inspected instructions, not an assertion that the installed phone build has been tested.

## 4. Separate phone-browser checklist — deferred for R's decision

**Do not run now. R decides after the Sloan's gate.** This is a Safari/home-network experiment, not the native HUD test, not a request to install anything, and not a tier certification.

A4 implementation inspected in local branch `astra/a4-streaming-prototype` at `777da88`: `web/stream/README.md`, `index.html`, `serve.mjs`. It is not present in the inspected main baseline. The server explicitly binds **127.0.0.1:8784**. That address on the phone points to the phone, not the Mac, and the current binding cannot accept home-network connections. Merely replacing the address in Safari is insufficient. After R chooses to proceed, A4 must prepare an authorized LAN-accessible server and provide the exact local URL, build/package IDs and ready status. No server changes or starts are part of A10. No router port-forwarding or public deployment is needed.

1. **Only after R's go-ahead and A4's readiness:** on the phone tap **Settings → Wi-Fi**, select the same home network as the Mac, and confirm the checkmark. Do not include the home network name or private address in committed evidence. Keep the Mac awake. If guest-network isolation blocks access, have A4 resolve readiness; do not change router security yourself.
2. Tap **Safari**, tap the address field, enter the exact LAN URL A4 supplies, and tap **Go**. It will resemble `http://<Mac-LAN-address>:8784/` (placeholder, not a working link). Do not enter localhost or 127.0.0.1. If it fails to open, screenshot the error and record “network/open failure”; this is not a renderer crash or low-fps result.
3. Confirm **A4 · tile streaming prototype** and the OpenStreetMap credit. Wait for coarse preparation and for the run buttons to enable. Record time to ready, initial errors, portrait/landscape, battery, charging and Low Power Mode. Keep the same brightness and orientation throughout. If buttons never enable, record startup failure and elapsed time.
4. Tap **Run 60 m/s** once. Keep Safari foreground and do not scroll/pan during the 60-second flight. Record visible stalls, blank patches, automatic reloads and any return to the Home Screen. After completion, record the results panel's median/p5/p1 fps, calls, triangles and memory estimates as labelled. Tap **Copy results**, then save in an existing local note. If copying fails over local HTTP, touch and hold the **Result JSON** text, choose **Select All → Copy**, or screenshot it. Do not install a clipboard helper.
5. Return to Safari and tap **Run 600 m/s**. Repeat the same observations and result capture. Keep the two speed results separate. The page's `/machine` hardware/preflight data describe the **Mac server**, not the iPhone: manually label the client iPhone 14 Pro / iOS 26.4.2 / Safari.
6. Tap **Open Lakeview** if that link is available. Record whether the scene appears, tap its **Yes** or **No** response and record any error. If these controls differ from the supplied version, note the difference; do not guess. This confirms only the tested package/path.
7. Tap Safari's **Reload** button once deliberately. Mark this **manual reload #1**, and record whether the viewer returns and its time to ready. Repeat one 60 m/s flight to check recovery. Separately count **unexpected page reloads** (without tapping Reload) and **Safari exits/crashes**. Copy results before navigating because recovery may lose them.
8. Record each failure's elapsed time, speed/area, visible message and whether Safari stayed open, the page reloaded, a tab went blank or Safari exited. If a run cannot finish, write “incomplete”; do not assign zero fps or infer out-of-memory from a reload alone. A crash cause remains unconfirmed without diagnostics.
9. When finished, close that Safari tab and tell A4 the experiment is complete so A4 can stop its own server. Do not start another or an unattended run.

Browser record: client/OS + A4 build/package; each speed's fps percentiles; startup/recovery time; manual reload count; unexpected reload count; Safari exits; errors/stalls/blank regions; result JSON or screenshots. Safari geometry/JS estimates are not total process/GPU memory, and native thermal readings are not supplied by this page. Use “unavailable”, never a fabricated memory/thermal pass. A4 currently excludes props and shadows, so a successful browser flight cannot establish the complete world's shadow, draw or memory budget.

## 5. Apple source ledger

1. [iPhone 12 technical specifications](https://support.apple.com/en-us/111876).
2. [iPhone 13 technical specifications](https://support.apple.com/en-us/111872).
3. [iPhone 13 Pro technical specifications](https://support.apple.com/en-us/111871).
4. [iPhone 14 technical specifications](https://support.apple.com/en-us/111850).
5. [iPhone 14 Pro technical specifications](https://support.apple.com/en-us/111849).
6. [iPhone 15 technical specifications](https://support.apple.com/en-us/111831).
7. [Apple introduces iPhone 15 Pro and A17 Pro](https://www.apple.com/newsroom/2023/09/apple-unveils-iphone-15-pro-and-iphone-15-pro-max/).
8. [Apple introduces iPhone 14 Pro and A16](https://www.apple.com/uk/newsroom/2022/09/apple-debuts-iphone-14-pro-and-iphone-14-pro-max/).
9. [Choosing a resource storage mode for Apple GPUs](https://developer.apple.com/documentation/metal/choosing-a-resource-storage-mode-for-apple-gpus).
10. [Available app memory and its changing limit](https://developer.apple.com/documentation/os/os_proc_available_memory).
11. [ProcessInfo.ThermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum).
12. [If your iPhone or iPad gets too hot or too cold](https://support.apple.com/en-us/118431).

Filing note for A3: A10 documents R's 14 Pro standard-device priority, preserves the existing floor and Lakeview failure, proposes hero/standard and memory allowances, and defers Safari to R after the Sloan's gate. No tracker, owner log, test threshold or runtime configuration is changed by this single-file task.
