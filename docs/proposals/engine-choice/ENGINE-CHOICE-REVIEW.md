# WorldEngine engine-choice review

**5 October 2026 · Proposal only · No implementation or device benchmarks performed**

## Recommendation

**Choose B as the architectural direction, with A as the first shipping step: finish the RealityKit iPhone renderer, keep generation separate from rendering, and defer the second renderer until interactive web has earned its cost.** Start web sharing with a poster and a rendered recap video. Do not switch the active milestone to Unity, Godot or WKWebView solely to obtain share links.

Confidence is **medium, approximately 70% as a judgment, not a statistical probability**. Native SwiftUI fit, existing investment and the priority of a sustained iPhone experience favor RealityKit. The unknown dog runtime and absence of comparable device measurements prevent high confidence. RealityKit is not yet proven to meet the target either.

The first decision gates are the dog audit and an equivalent RealityKit/WKWebView street test. A portable dog plus a web renderer that passes the full visual, thermal and integration gates would make C a credible winner. A deeply Unity-dependent dog or a funded near-term Android release would make D substantially more attractive.

### Evidence and scope

Reviewed the local [M1 plan](../../plan-m1.md), [binding visual direction](../../VISUAL_DIRECTION.md), [CLAUDE.md](../../../CLAUDE.md), the visual proposals and representative street/noon and aerial images. The plan records 61 tests/89 cases for the Swift foundation; these were **not rerun**. Its older iOS 18 minimum and “rendering not started” status conflict with the current brief and CLAUDE.md; this review uses **iOS 26 minimum and renderer in progress**. The 29–37 working days are the existing plan's estimate, not a newly validated schedule.

The on-disk v2 Markdown was empty when inspected. For v2 content, this review used the user's supplied “WorldEngine Visual Spec — Proposal v2” attachment dated 5 October 2026, together with the existing images, presets and manifest. That file was not repaired as part of this review.

The visual target depends on coherent procedural houses, smooth vegetation, soft fill/contact, stable palettes, fog, wetness, patchy snow and restrained post-processing. None requires a uniquely Unity-only feature. The attractive images are art studies, not proof of GPU cost or exact geography. The earlier three.js mock is encouraging evidence about iteration and appearance, not a sustained workload benchmark.

The plan's approximate 290,000 main-pass triangles, 100,000 shadow triangles, 100-draw ceiling, 200 m chunks and 150/600 m LOD thresholds provide a useful comparison fixture. Street view is the deciding workload; a good aerial result cannot substitute for it. The current character contract accepts a RealityKit Entity, but that is a WorldEngine design choice—not evidence about DogWell's actual dog technology.

## 1. Weighted comparison

**All scores are assumptions/engineering judgments as of 2026-10-05.** They rate fit for this product and its present state, not universal engine quality. 1 = poor fit or major unresolved burden; 3 = workable with meaningful costs; 5 = excellent fit. No renderer gets 5 for iPhone performance without measurements. Native integration includes dog uncertainty, so A/B receive 4 rather than 5.

| Option | iPhone quality, power, thermals 30% | SwiftUI + dog 15% | Interactive web 15% | Agent/code workflow 15% | Switching cost 10% | Future platforms/server 10% | License/lock-in 5% | Weighted /5 | /100 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A. RealityKit only | 4 | 4 | 1 | 4 | 5 | 1 | 3 | **3.30** | 66 |
| **B. RealityKit, neutral output, web later** | **4** | **4** | **4** | **4** | **4** | **3** | **4** | **3.90** | **78** |
| C. Web renderer everywhere | 3 | 3 | 5 | 5 | 2 | 4 | 5 | **3.70** | 74 |
| D. Unity 6 / Unity as a Library | 4 | 2 | 2 | 3 | 2 | 5 | 3 | **3.10** | 62 |
| E. Godot 4.x | 3 | 2 | 2 | 4 | 2 | 4 | 5 | **2.95** | 59 |
| F1. Unreal | 3 | 1 | 1 | 2 | 1 | 4 | 2 | **2.10** | 42 |
| F2. Bevy | 3 | 1 | 2 | 3 | 1 | 3 | 5 | **2.45** | 49 |
| F3. Mapbox + custom 3D hybrid | 3 | 3 | 4 | 3 | 2 | 3 | 2 | **3.00** | 60 |

Total = sum of score × weight; /100 = total × 20. F is split because those alternatives are substantially different. The web column rates eventual interactive reach, not ability to host a video: **every option can support a video share page**. B's 4 assumes the second renderer is eventually funded; it is not a claim that this capability exists today. Its switching/workflow scores account for an export adapter and eventual dual-renderer upkeep.

**Sensitivity:** B leads C by only 0.20. Raising C's measured iPhone score from 3 to 4 raises C to 4.00 and reverses the ranking. If dual-renderer upkeep drops B's workflow score by one, B falls to 3.75. A 0.05 difference is not actionable precision. If web remains video-only, A is the immediate implementation choice and B remains an inexpensive design boundary, not a second product commitment.

### Why these scores

**A / B:** strongest reuse of the tested Swift geometry foundation and current native integration. A permanently sacrifices interactive non-Apple reach; B retains a route to it. Native APIs offer a plausible efficient path, but RealityKit still constrains renderer internals and requires actual profiling of shadows, foliage, custom materials and post-processing. B adds shader and adapter maintenance; it does not make rendering free to port.

**C:** strongest single-source workflow for agents and distribution through URLs. A WKWebView fits into a native app, but SwiftUI lifecycle, touch ownership, process loss, memory, native-to-JavaScript communication and the personalized dog still need integration. Avoid per-frame native bridge traffic: give the viewer route/time state and let it animate locally. Bundled web assets can eliminate network startup inside the app; they do not eliminate runtime/GPU costs. A desktop wrapper adds packaging and platform integration work beyond rendering.

**D:** compelling if a complex Unity dog already exists or native Android is committed. URP can plausibly deliver this visual style, with strong cross-platform asset and animation workflows. The cost here is a native-host integration plus a second build system and reworked renderer. Agents can generate scenes and automate builds; Unity does not inherently require hand-placing every object. However, imports, serialization, render-pipeline settings, signing and library lifecycle make failure recovery more demanding for this owner. Web support exists, but download/startup and mobile performance remain separate gates.

**E:** permissive licensing, readable scripts/resources and a capable general engine. Standalone mobile export is distinct from embedding in an existing SwiftUI app. The upstream/library distinction below makes embedding a real integration risk. Godot's web renderer also differs from its higher-end native rendering paths; one project still requires platform tuning.

**F:** Unreal is disproportionate to this stylized recap and existing SwiftUI host; reserve it for a materially different high-end desktop product. Its commercial model also depends on product/revenue classification ([Epic licensing](https://www.unrealengine.com/license), checked 2026-10-05). Bevy's Rust/code-first design is appealing, but its own documentation warns of missing features and recurring breaking changes; that migration burden outweighs its benefits here ([Bevy introduction](https://bevy.org/learn/quick-start/introduction/), checked 2026-10-05). A Mapbox hybrid is attractive for a route map or aerial event preview, but custom street-level houses, the dog, occlusion and weather remain substantial work. Mapbox demonstrates Metal custom layers; it does not supply this art direction ([Mapbox custom layer example](https://docs.mapbox.com/ios/maps/examples/custom-layer/), checked 2026-10-05). Do not replace WorldEngine with a mapping SDK merely to draw a recap route.

### Switching cost, expressed honestly

These are **planning assumptions**, not quotations or measured estimates:

| Choice | What carries over | New/reworked work | Planning consequence |
|---|---|---|---|
| A | Swift modules and renderer in progress | Finish current renderer and dog integration | Smallest immediate disruption; keep the existing schedule as a baseline only |
| B, staged | Same as A; one authoritative generator | Versioned export boundary, then a web adapter/shaders later | Budget a 1–2 day format proof now if needed; a production second renderer is additional work measured in weeks, not included in the M1 estimate |
| C | OSM fixtures, algorithms, profiles, meshes if exported | Renderer, shader pipeline, dog animation integration, WKWebView lifecycle; generator port only if runtime generation is required in JS | Assume several weeks of disruption until a prototype produces a bottom-up estimate |
| D / E | Data and algorithm specifications; Swift generator can remain an offline producer | Engine adapter or ports, shaders/materials, animation and host bridge, automated builds | Also several weeks; do not count the 61 Swift tests as tests of a C#/GDScript rewrite |

Keeping Swift generation outside the renderer avoids discarding all foundation work under C/D/E. It requires a practical export/build pipeline; it does not let another engine execute arbitrary Swift modules automatically. Do not add a speculative Linux generator port to M1: macOS automation can initially produce neutral assets.

## 2. Dated fact register

**“Verified” means the cited primary documentation or original benchmark author states it, checked 2026-10-05. It does not mean reproduced on DogWell. “Assumption” includes estimates, inference and project-specific unknowns.** Versions are named where evidence is version-specific. Living documentation and benchmark tables may change after this review.

### Unity web: size, startup and Safari

| Status | Finding and date | Source / decision impact |
|---|---|---|
| Verified — documented support | Unity 6.3 documentation lists iOS Safari 15+ as supported, including browser, WebView and PWA deployment. Checked 2026-10-05. | [Unity 6.3 browser compatibility](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/webgl/intro/browsercompatibility). “Unity web does not support mobile” is outdated for this version. Support is not a 60 fps guarantee. |
| Verified — author-reported sample, not our measurement | Johannes Deml's small loading-test project lists Unity **6000.3.19f1** at **3.51 MB** for built-in/WebGL2, **8.67 MB** for URP/WebGL2 and **6.76 MB** for URP minimum-size/WebGL2. The project uses Brotli. Table checked 2026-10-05. | [Original benchmark project and build settings](https://github.com/JohannesDeml/UnityWebGL-LoadingTest). These are a small sample's published build sizes, not WorldEngine size or a universal Unity overhead. Shader stripping and pipeline choice materially change results. |
| Assumption — unmeasured | No comparable iPhone 13/iOS 26 cold-start time or ten-minute WorldEngine performance result was established in this review. | The [same project's live builds](https://deml.io/experiments/unity-webgl/) are test candidates, not a controlled Safari result. Do not turn a desktop demo into an iPhone loading claim. |

For scale, **calculated transfer-only lower bounds** at 10 megabits/second are 2.81 seconds for 3.51 decimal MB, 5.41 seconds for 6.76 MB, and 6.94 seconds for 8.67 MB. This assumes those bytes must transfer before interaction at a sustained 10 Mbps. It excludes latency, parsing, Wasm compilation, shader startup and scene assets. Caching, progressive loading and overlap can change the critical path. These are arithmetic illustrations, **not measured load times**.

### Unity as a Library inside SwiftUI

**Verified, Unity 6.0 manual checked 2026-10-05:** iOS library integration is supported; ordinary iOS/Android embedding supports full-screen rendering only, with possible Industry differences. The manual reports **80–180 MB retained after unloading**. This is not initial loaded memory, peak memory or app download size. One runtime instance is supported; after fully quitting Unity on iOS, it cannot restart within the same app session. [Unity as a Library limitations](https://docs.unity3d.com/6000.0/Documentation/Manual/UnityasaLibrary.html).

**Assumption/inference:** a SwiftUI wrapper can present a full-screen native Unity session, but an arbitrary small scrolling recap card is not established by that support contract. Community resizing techniques are not equivalent to supported embedding. Confirm whether DogWell wants a full-screen recap before choosing D.

**Assumption/unmeasured:** no defensible fixed incremental app-size or loaded-memory number applies to DogWell. Native stripping, architecture, render pipeline, packages and assets affect it. Measure a signed release archive against the identical SwiftUI host without Unity; report device-thinned compressed download delta, installed size and runtime memory separately. A raw project folder or debug IPA is not the answer.

### Safari / WKWebView graphics on iOS 26

| Status | Finding and date | Source / implication |
|---|---|---|
| Verified | Safari 26.0 shipped WebGPU on 15 September 2025. WebKit describes its closer mapping to Metal than WebGL. | [Safari 26.0 release](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/). API availability does not establish WorldEngine speed. |
| Verified — narrower evidence | A June 2025 reply in Apple's developer forum states that Safari feature flags do not enable features throughout WKWebView and that WebGPU is enabled by default in iOS 26 beta. Checked 2026-10-05. | [WKWebView WebGPU discussion](https://developer.apple.com/forums/thread/770862). Combined with the shipped WebKit release, this supports testing WebGPU in iOS 26 WKWebView without private flags; it is not an app-specific compatibility test. |
| Verified | WebGL2 is available in Safari 15+; iOS 26 is not WebGPU-only. | [Unity's browser requirements](https://docs.unity.com/en-us/engine/6000.3/manual/platform-specific/webgl/intro/browsercompatibility), checked 2026-10-05. |
| Verified | WebGPU exposes its entry point in secure contexts. | [W3C WebGPU specification](https://www.w3.org/TR/webgpu/), checked 2026-10-05. Test the actual bundled/hosted origin; do not assume file URLs or a custom URL scheme behave like HTTPS. |
| Assumption — requires device proof | WebGPU should be a candidate for iOS 26, with WebGL2 as a separately tested browser fallback. Adapter creation, required limits/features and device-loss recovery must pass in the real WKWebView configuration. | Availability alone is insufficient; experiment 2 is the gate. |
| Assumption — no comparative measurement | Neither “WebGPU matches native Metal” nor a fixed percentage battery/thermal penalty is established here. | WebKit's API explanation is not a matched RealityKit comparison. Browser scheduling, validation/process overhead, resolution, allocation, shader complexity and GPU fill all matter. Native can also throttle. |

The important caveat is **sustained equivalent work**. A capped-resolution web scene may beat an inefficient native one; a full-resolution translucent canopy and multi-pass blur can overwhelm either. Measure CPU, presentation and GPU separately. JavaScript requestAnimationFrame intervals are not GPU timings. Lack of usable GPU timing makes the 10 ms gate inconclusive, not passed.

### Godot web and native embedding

| Status | Finding and date | Source / implication |
|---|---|---|
| Verified — author-reported sample | Deml's Godot loading-test table lists **4.6.2 release/WebGL2 at 6.33 MB**; its build pipeline uses precompression and Wasm optimization. Checked 2026-10-05. | [Original Godot loading-test project](https://github.com/JohannesDeml/Godot-Web-LoadingTest). This is a small sample, not a WorldEngine build. Device startup remains unmeasured. |
| Verified — historical reference only | Godot's May 2024 web report gives approximately 40 MB uncompressed / 5 MB Brotli for the 4.3 Wasm binary. | [Godot web report](https://godotengine.org/article/progress-report-web-export-in-4-3/). Do not label this a current 4.x total download: it excludes other files/assets and describes an older release. |
| Verified — current documentation | The stable web-export guide specifies WebGL2/Compatibility rendering, not Forward+/Mobile or WebGPU; it describes single-threaded export as the default and a better compatibility choice for iOS. Godot 4 C# web export is unsupported in that guide. Checked 2026-10-05. | [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html). A native rendering feature cannot automatically be promised on web. |
| Verified — upstream status | Stable FAQ says experimental LibGodot arrived in 4.6 for Windows/macOS/Linux; Android/iOS support is planned. Checked 2026-10-05. | [Godot FAQ](https://docs.godotengine.org/en/stable/about/faq.html). Standalone iOS export is not the same feature. |
| Verified — separate implementation evidence | Migeran documents an iOS SwiftUI embedding sample. Its author described wider embedding/restart patches still being merged at GodotCon on 24 April 2026. | [Migeran implementation](https://github.com/migeran/libgodot), [author's 2026 talk](https://talks.godotengine.org/godotcon-ams-2026/talk/DQXZZC/). Embedding is possible; this does not establish a turnkey, supported upstream iOS library distribution. |
| Assumption | The precise maintained branch, device/simulator support, lifecycle and packaging needed by DogWell remain unaudited. | Pin and test a specific distribution before committing. Do not infer that a talk's patches have shipped merely because the talk is recent. |

### Small-studio licensing and costs

All prices below are **USD as displayed on 2026-10-05**, excluding tax, hosting, assets and optional services.

| Status | Engine/library | Verified terms and project implication |
|---|---|---|
| Verified; product classification unknown | Unity | Personal is free for qualifying gaming/entertainment use below the $200,000 revenue/funding threshold. Pro is advertised from **$2,310/year**, or **$210/month**; monthly payment should not be read as month-to-month cancellation. Industry applications cannot use Personal; Industry becomes required above $1 million total finances, while eligible smaller Industry users may use Pro/Enterprise. Client-service eligibility can depend on client finances. DogWell wellness and sponsor-map work need classification before assuming free use. [Unity pricing/eligibility](https://unity.com/products). |
| Verified | Unity runtime fee | Unity canceled the Runtime Fee in September 2024. Do not budget a per-install Runtime Fee under the reviewed model. [Unity announcement](https://unity.com/blog/unity-is-canceling-the-runtime-fee). |
| Verified | Godot | MIT; no engine seat fee or royalty. Preserve required notices and review bundled third-party notices. [Godot license](https://godotengine.org/license/). |
| Verified | three.js | MIT; no engine seat fee or royalty; preserve license/copyright notice. [three.js license](https://github.com/mrdoob/three.js/blob/dev/LICENSE). |
| Verified | Babylon.js | Apache 2.0; no engine seat fee or royalty; follow license/notice and modification requirements. [Babylon.js license](https://github.com/BabylonJS/Babylon.js/blob/master/license.md). |

Open-source licenses reduce vendor dependence but do not pay for upgrades, hosting or renderer maintenance. RealityKit's principal lock-in is Apple's platform and proprietary rendering API. B reduces dependence in the world assets, not in the native renderer itself.

## 3. What changes the recommendation

| Finding | Decision change |
|---|---|
| Dog already uses RealityKit with working customization/animations | B/A confidence rises; use the host's Entity directly and keep WorldEngine dog-agnostic |
| Dog uses SceneKit, USDZ or another portable mesh/rig format | “Not RealityKit” alone is insufficient reason to switch. Test one real personalized dog, all essential animation clips, morphs and materials in RealityKit first |
| Dog is fundamentally a Unity runtime with proprietary customization, animator logic or shaders | Prototype D immediately. If conversion is costly and a full-screen recap is acceptable, sharing Unity's runtime can outweigh current WorldEngine rework |
| Dog is already a production three.js/Babylon scene | C becomes a leading candidate, conditional on WKWebView performance and native lifecycle. Avoid keeping the dog in a separate overlaid 3D view: depth, shadows, occlusion and lighting need one coherent scene |
| Dog's assets are portable but behavior is engine-specific | Separate geometry/rig conversion from behavior conversion; a GLB export does not reproduce a controller or customization system |
| Android becomes a funded release within roughly six months | Reweight the platform criterion before final renderer commitment. Favor D for demanding native iOS/Android if embedding fits; favor C if measured quality/thermals pass and web/mobile share a product. B would otherwise need a web Android wrapper or a third native renderer |
| Steam remains “maybe later” | Do not switch for it. Steam distribution requires more than a desktop renderer, and is not the first revenue opportunity |
| Server-rendered sponsor videos become contracted work | Neutral assets retain value. Evaluate a GPU-backed web or Unity render worker against actual throughput/cost; a headless simulation/server build is not automatically an image renderer. Initial recaps may be captured on-device, avoiding a render farm |
| RealityKit misses budget at accepted quality after bounded optimization, while C passes | Switch to C; sunk cost should not override measurements |
| Both fail | Revisit scene/shadow/post-process budgets before another engine migration; changing engines does not remove fill rate or geometry costs |

These are decision changes, not claims about DogWell's unaudited implementation. No DogWell or other repository was inspected for this proposal.

## 4. B's platform-neutral world package

**Proposal, not an implemented format.** Keep one authoritative Swift generator initially. It resolves OSM facts, regional profiles, overrides and stable random choices once. Renderers consume the resulting geometry and resolved scene recipe. They must not independently guess roofs, porches, colors or tree placements from raw OSM.

Use a versioned manifest plus independently addressable **glTF 2.0 binary meshes (`.glb`) and JSON**. glTF defines geometry, transforms and standard material/animation data; it does not standardize WorldEngine weather shaders or generator rules. [Khronos glTF 2.0 specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), checked 2026-10-05.

| Proposed output | Contents and purpose |
|---|---|
| `world.json` | Schema/generator/profile versions, content hashes, source dates and attribution, geographic bounds, geodetic reference/origin, units and axes, chunk index, capability requirements and fallback policy |
| `chunks/<id>/lod0.glb`, `lod1.glb`, `lod2.glb` | Positions, normals, indices, UVs, standard fallback materials and optional colors; stable primitive-to-feature mapping. Static houses, ground, sidewalks, curbs and backdrop geometry. Keep chunks independently loadable |
| `chunks/<id>/scene.json` | Resolved OSM feature identities, source vs inferred attributes, final house family/roof/porch choice, palette slot, collision proxies, surface categories, bounds, LOD references and instance placements |
| `prototypes/*.glb` plus instance tables | Reusable trees, lamps, leaves, benches and clutter. Transforms, prototype IDs, palette variants, wind phase and deterministic seed. Start with JSON; move large tables to specified binary buffers without changing semantics |
| `profiles/*.json`, `palettes.json`, `materials.json` | The exact versioned source profiles for provenance plus resolved material parameters: linear-light interpretation, roughness, snow/wet response, emissive behavior, fog and grade. Renderer-facing materials reference stable IDs, never engine objects |
| `environment.json` | Location/timezone, horizon sectors, camera presets, sun/light state, weather/season parameters, transition timing and quality limits. Saved recaps freeze a timestamped state for repeatability; live use supplies updated neutral state |
| Optional terrain payload | Versioned height grid/mesh reference, vertical datum and sampling rule; absent in flat M1. Avoid encoding “all ground is y=0” into the package contract |
| Separate host-owned `recap.json` | Route/time samples, playback speed, camera track and character asset/customization reference. Contains only what playback needs; keep private app logic outside the public world package |
| Optional character package | Portable rig/mesh, clips and supported morphs where exportable, plus semantic clip names, bounds and orientation. DogWell owns it. The existing RealityKit Entity remains an allowed native-only adapter input |

### Rules that prevent a second generator

1. **One decision owner.** The generator emits the final roof, facade, placement and color selections, as well as profile versions. A renderer does not re-run regional inference. A house override changes generator inputs and regenerates affected chunks.
2. **Determinism is portable.** Use typed OSM identities such as `way:123`, stable seed strings and a specified random/hash algorithm with fixtures. Do not silently put 64-bit IDs or seeds into JavaScript's limited exact integer range. Prefer baked choices whenever runtime randomness is unnecessary.
3. **Coordinates are explicit.** One metre per unit; right-handed local frame with +X east, +Y up and −Z north. Store a double-precision geodetic anchor and chunk offsets; keep local mesh vertices float32. Document projection and vertical reference. Rebase origins for long routes. Never compress real geography to fit a camera.
4. **Material meaning is shared; shader implementation is not automatically shared.** Define fog, palette interpolation, snow masks, wetness and wind mathematically with parameters and golden fixtures. Bake static occlusion/masks where useful. Specify custom vertex channels explicitly; do not pretend arbitrary AO/palette indices are standard glTF color semantics. Apple Metal, web WGSL/GLSL or a node system still need renderer-specific implementation and comparison.
5. **No engine-native canonical file.** A RealityKit archive, Unity prefab or Godot scene may be a derived cache, keyed by source hash and adapter version. They are not the source of truth.
6. **Fallbacks are deliberate.** Baseline web can omit aerial blur and reduce distant clutter; it must preserve positions, identity, character readability and seasonal meaning. Unknown required capabilities cause a clear fallback/rejection, not silent wrong rendering.

RealityKit should consume the generator's neutral buffers directly during M1, with an export adapter producing GLB; requiring a GLB encode/decode round trip every native launch would add needless work. For external packages, a RealityKit adapter decodes meshes into mesh resources. Apple's [LowLevelMesh API](https://developer.apple.com/documentation/realitykit/lowlevelmesh) supports custom vertex data; do not assume RealityKit automatically imports all glTF extensions. Instancing data can be translated into each renderer's instancing API. Apple's [WWDC25 RealityKit session](https://developer.apple.com/videos/play/wwdc2025/287/) verifies the iOS 26 generation's instancing and RealityView post-processing capabilities, but does not validate this project's budget.

### three.js or Babylon.js later?

**Default to three.js for a narrow recap viewer**, because the earlier mock offers a starting point and the viewer need not become a full game. Keep that choice provisional until the dog audit. Babylon.js deserves preference if its animation/material tooling removes more custom work for the actual dog or a broader interactive product.

Three's current WebGPURenderer targets WebGPU with a WebGL2 fallback; custom effects still need compatibility checks ([three.js documentation](https://threejs.org/docs/pages/WebGPURenderer.html)). Babylon maintains WebGPU and WebGL paths side by side ([Babylon WebGPU documentation](https://github.com/BabylonJS/Documentation/blob/master/content/setup/support/webGPU.md)). Both checked 2026-10-05. Neither turns existing Metal shader code into portable glTF material code. Do not maintain both web libraries.

## 5. Cheapest decision experiments

**Proposals only; none were run.** Each is capped at two working days. The coding agent prepares builds, instrumentation and a short result sheet; the founder only installs/opens the build, follows the device run and judges images. Do not require the founder to operate a terminal or manually reconstruct editor settings. If setup consumes the timebox, return “inconclusive” with the blocker rather than calling an empty scene proof of production performance.

All thresholds below, except the owner's 60 fps / 10 ms / ten-minute requirements, are **proposed acceptance policies**, not published platform limits. Record engine/library version, OS, device, build mode, viewport, quality settings, fixture hash and measurement method. A pass screens an option into the next stage; it is not production certification.

### Experiment 1 — Actual dog audit (half a day; maximum one day)

With separate access authorization, inspect DogWell's real dog asset/runtime and its customization path. Document formats, skinning, morphs, animation/controller dependencies, materials, licenses, current native platforms and desired recap presentation.

**Pass for continuing A/B without a migration investigation:** existing RealityKit dog works, or one representative personalized dog can be shown in RealityKit with all required clips/morphs/material features, correct scale/bounds, and no missing required behavior. Check three contrasting coat/customization presets. **Fail:** any required feature is tied to a different runtime and cannot be demonstrated within the day. Failure triggers a costed migration/native-runtime comparison; it does not automatically select that runtime.

### Experiment 2 — Matched street in RealityKit and WKWebView (two days)

Use an already exportable Sloan's Lake street fixture and the current native harness. Test the same route, animated dog or identical proxy, camera, geometry, shadows and weather in RealityKit and three.js inside WKWebView on a physical iPhone 13. Use WebGPU first; test WebGL2 separately. Include the plan's representative street workload, not just a few boxes: approximately 290k main triangles, 100k shadow triangles, instanced vegetation, contact/occlusion treatment, fog and wet/snow states. If the fixture/harness is not ready, defer this test rather than spend the two days building an engine.

Fix the same rendered pixel dimensions (record them), antialiasing, shadow resolution, visible distance and accepted quality. Do not let adaptive resolution conceal a comparison. Capture noon, golden hour, rainy dusk and winter; exercise aerial transition as a secondary check. Run three ten-minute sessions per backend, alternating order and cooling to the same nominal starting state. Use identical brightness, unplugged power, Low Power Mode off, 20–24°C room, and the same battery range. Include one run using the minimum supported iOS 26.0 if available, and separately record the shipping patch version.

**Pass for replacing the native renderer:** every backend claimed as the full native replacement must satisfy all of these:

- Average presentation rate at least **59.4 fps**, at least **99% of presented frame intervals ≤16.9 ms**, and no >100 ms stall after warm-up.
- **Every sampled steady-state GPU frame ≤10 ms**, reporting maximum, p95 and p99 separately. Exclude only the documented first five seconds from this steady-state gate; report startup separately.
- No serious/critical thermal state; final two-minute median frame time no more than **10% worse** than minutes 2–3. Report observed clock/power throttling where instruments expose it; no such observation is not absolute proof of no throttling outdoors.
- Peak incremental memory attributable to the viewer **≤500 MB**, no memory warning/process loss; account for WebContent/GPU processes without double-counting shared memory.
- Measured energy for the ten-minute run **≤120% of the equivalent native baseline**, using the same energy measurement method. Battery-percentage ticks alone are too coarse; if comparable energy or GPU measurements cannot be obtained, mark those gates inconclusive.
- The same required visual checklist passes in all four fixtures: true geography, dog at 20–25% screen height, readable coat/face, grounded contact, no camera clipping, stable houses/palettes, smooth vegetation, legible weather, coherent lighting and no disruptive flicker. Founder acceptance plus side-by-side captures; a faster scene with removed required effects fails equivalence.

Also require **20/20** successful background/foreground and open/close cycles, working native overlay touches, pause/resume and zero blank frames lasting >0.5 seconds after resumption. Log unsupported WebGPU features and device-loss recovery. If web fails only the energy gate but is otherwise good, it may still qualify for a short optional browser recap; it does not qualify for C's sustained native role. Native failure remains a real failure, not a default pass.

### Experiment 3 — Unity as a Library in a SwiftUI host (two days, conditional)

Run only if the dog audit favors Unity or Android is committed. Build the identical minimal host with and without one Unity scene. Use a full-screen presentation, native dismiss/overlay controls and a real device. Measure release/thinned compressed app-size delta, installed delta, load latency, loaded peak, and residual footprint after unload. Test 20 open/unload/reopen cycles and background transitions; do not use Quit when testing reload.

**Pass:** compressed device-targeted app delta **≤60 MB**; incremental loaded footprint **≤250 MB**; post-unload residual **≤180 MB**; residual growth from cycles 5 to 20 **≤20 MB**; first interactive frame **≤2 seconds warm / ≤4 seconds cold**; **20/20** successful lifecycle cycles; all native touches/dismiss controls correct. These memory caps are product gates, not Unity guarantees. Record installed size even though the download delta is the size gate.

If DogWell requires an inline card, ordinary full-screen-only integration **fails the required architecture** unless a supported alternative is concretely demonstrated and costed. A passing hello-world proves embedding overhead only; add the dog and run experiment 2's sustained criteria before choosing D.

### Experiment 4 — One neutral chunk, two consumers (one to two days)

Export one real chunk and a small prototype/instance table from existing generator output. Load it in a native adapter and a minimal web viewer. Change one palette and one source profile once, regenerate, and reload both. No renderer-specific building inference is allowed.

**Pass:** identical feature IDs/instance counts; maximum position discrepancy **≤1 cm** against the generator output; all repeated seeds/choices stable across three exports; no missing primitives; bounds/units/orientation correct; three fixed camera captures agree on silhouettes and placement. One palette edit reaches both without changing renderer source. Reject unsupported required material semantics explicitly. **Fail:** the web viewer needs its own OSM-to-house logic or engine objects leak into the canonical package. This establishes the boundary, not complete visual parity.

### Experiment 5 — Web sharing size/startup (one day; two if comparing engine exports)

First test a poster/video recap page. If interactive sharing has a concrete use, add a fixed-route web replay using the same small fixture. Measure five cold-cache runs on physical iPhone 13 Safari, at **10 Mbps / 100 ms round-trip latency**, followed by five warm runs. Log actual transferred bytes, not ZIP size. Optional Unity/Godot exports use the same fixture and host conditions; compare their own totals rather than published sample sizes.

**Video-page pass:** poster/meaningful content **≤1.5 seconds in every run**, poster **≤200 KB**, and playback begins **≤2.5 seconds after a tap** in every run. **Interactive pass:** meaningful static fallback **≤1.5 seconds**, first controllable scene **≤5 seconds cold / ≤2 seconds warm** in every run; critical initial payload **≤3 MB**, complete demonstration payload **≤8 MB**, and at least **30 fps over a 60-second playback** without a crash. The lower browser fps gate is explicitly for optional shared recaps, not the native 60 fps target. A browser failure must leave a useful poster/video.

If Unity/Godot cannot meet that critical payload with an actual useful first scene, record a fail for instant interactive sharing, not for their native engines. Never present a loader animation as “interactive.”

### Experiment 6 — Godot embedding proof (two days, only if still a finalist)

Pin a specific upstream or Migeran distribution and attempt the real SwiftUI presentation on iPhone, with a scriptable repeatable build. Record exactly which patches are outside upstream and who maintains them.

**Pass:** required full-screen/inline presentation works, **20/20** lifecycle/restart cycles, no crash/touch conflict, post-cycle residual growth **≤20 MB**, compressed app delta **≤60 MB**, loaded incremental memory **≤250 MB**, and a second clean build succeeds without manual project repair. **Fail for this milestone:** requires an unbounded engine fork/debugging effort or misses the two-day timebox. Passing still requires the street test and does not establish web feature parity.

### Order and stop rule

Run experiment 1 first. Continue the existing native milestone while obtaining a representative fixture. Run experiment 2 when it is ready. Run 4 only to answer the export-boundary risk, and 5 when sharing is next. Run 3 or 6 only if a real contender remains after the dog audit; do not spend two days on every engine by default. A failed prototype is evidence to stop or narrow that path, not permission for an open-ended rewrite.

## 6. Is web worth having?

**Yes, as distribution for recaps. An interactive web engine is not yet proven worth maintaining.** A link that opens instantly, shows the user's dog, replays a short walk and invites the recipient into DogWell supports the paid iPhone product. That link can use a poster and video rendered by the native app. It does not require recipients to download an engine or the full neighborhood.

Recommended progression:

1. **First:** native walk recap, with an exportable video/still and a lightweight share page. User controls what is shared; world assets remain separate from private route/dog data.
2. **Then:** an optional interactive replay if recipients demonstrably want camera movement or playback exploration. Keep it constrained to a recorded route and bounded region, with a video fallback. This is B's first web renderer, not full DogWell.
3. **Marketing:** use the same small viewer if already built; otherwise use video. Do not create a second large renderer just for a landing-page animation.
4. **Full web DogWell:** reconsider only with a concrete acquisition/retention case and a dog/runtime audit. Authentication, payments, customization, offline behavior and device QA are additional product work beyond rendering.
5. **B2B:** treat sponsor maps, stills and recap videos as output products. A neutral scene package supports later automated rendering, but renderer/server operating costs should follow a paying use case.

The immediate commitment should therefore be: **ship the native scene, audit the dog, preserve a small neutral generation boundary, and test one equivalent web street before deciding on a renderer migration.** Web sharing is worthwhile now; maintaining two full interactive products is not justified by the current evidence.
