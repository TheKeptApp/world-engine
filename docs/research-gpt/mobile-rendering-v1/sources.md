# Mobile rendering v1 — sources and evidence ledger

Checked **2026-10-07**. Publication dates are included when available; “current documentation” describes a page inspected on the check date, not a known publication date. No source demonstrates WorldEngine performance. All workload-specific gains remain estimates or vendor claims with scope. Links are primary developer, engine, product or conference sources.

## Source register

### S01 — Apple Maps: new 3D city experience

- Publication/version: 2021-09-27; checked 2026-10-07.
- Source: [Apple Maps: new 3D city experience](https://www.apple.com/newsroom/2021/09/apple-maps-introduces-new-ways-to-explore-major-cities-in-3d/).
- Evidence and limitation: Verified shipping iPhone 3D cities and night presentation. No public proof here of its LOD, batching, shadow or cache implementation.

### S02 — Google Photorealistic 3D Tiles

- Publication/version: Documentation; updated 2026-10-05; checked 2026-10-07.
- Source: [Google Photorealistic 3D Tiles](https://developers.google.com/maps/documentation/tile/3d-tiles).
- Evidence and limitation: Verified root tileset and tile requests by compatible renderers. This is a data API, not documentation of Google Maps app internals.

### S03 — CesiumJS Cesium3DTileset

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [CesiumJS Cesium3DTileset](https://cesium.com/learn/cesiumjs/ref-doc/Cesium3DTileset.html).
- Evidence and limitation: Verified screen-space-error selection, cache/overflow controls, memory-adjusted error and sibling loading. Defaults are not iPhone memory recommendations.

### S04 — Cesium Native selection algorithm

- Publication/version: Current technical documentation; checked 2026-10-07.
- Source: [Cesium Native selection algorithm](https://cesium.com/learn/cesium-native/ref-doc/selection-algorithm-details.html).
- Evidence and limitation: Verified hierarchical selection, frustum/fog tests and refinement behavior. Portable policy; integrating the native renderer into RealityKit is a different project.

### S05 — CesiumJS Fog

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [CesiumJS Fog](https://cesium.com/learn/cesiumjs/ref-doc/Fog.html).
- Evidence and limitation: Verified terrain culling and reduced terrain detail using fog. Extending this to WorldEngine buildings is an authored proposal.

### S06 — Cesium for Unreal occlusion culling

- Publication/version: 2022-08-18; checked 2026-10-07.
- Source: [Cesium for Unreal occlusion culling](https://cesium.com/blog/2022/08/18/occlusion-culling-cesium-for-unreal/).
- Evidence and limitation: Verified occlusion-informed tile selection in the Unreal integration. Not a verified public RealityKit capability.

### S07 — Mapbox GL JS v2.3 terrain and fog

- Publication/version: 2021-06-03; checked 2026-10-07.
- Source: [Mapbox GL JS v2.3 terrain and fog](https://www.mapbox.com/blog/mapbox-gl-js-v2-3-0-distance-fog-elevation-querying-and-terrain-performance-improvements).
- Evidence and limitation: Verified vendor account of distance fog reducing requests and shared terrain render buffers. Reported gains are particular terrain workloads, not A16 city benchmarks.

### S08 — Mapbox RasterSource prefetchZoomDelta

- Publication/version: Versioned iOS 11.7.0-rc.1 API documentation; checked 2026-10-07.
- Source: [Mapbox RasterSource prefetchZoomDelta](https://docs.mapbox.com/ios/maps/api/11.7.0-rc.1/documentation/mapboxmaps/rastersource/prefetchzoomdelta/).
- Evidence and limitation: Verified lower-resolution raster prefetch. Applying coarse-first loading to 3D is a proposal, not a claim that this property streams 3D meshes.

### S09 — Mapbox tile cache budget

- Publication/version: Current iOS API documentation; checked 2026-10-07.
- Source: [Mapbox tile cache budget](https://docs.mapbox.com/ios/maps/api/latest/documentation/mapboxmaps/tilecachebudgetsize/).
- Evidence and limitation: Verified tile cache budget API. A tile cache alone does not account for every CPU/GPU allocation.

### S10 — Mapbox rendering performance evaluation

- Publication/version: 2024-03-25; checked 2026-10-07.
- Source: [Mapbox rendering performance evaluation](https://www.mapbox.com/blog/new-advanced-tools-for-map-rendering-performance-evaluation).
- Evidence and limitation: Verified performance tooling for representative map interactions. Motivates repeatable camera routes rather than one still frame.

### S11 — Pokémon GO Download All Assets

- Publication/version: Current official help; checked 2026-10-07.
- Source: [Pokémon GO Download All Assets](https://niantic.helpshift.com/hc/en/6-pokemon-go/faq/3589-download-all-assets/?hl=e&l=en&p=web).
- Evidence and limitation: Verified gradual asset downloads and optional bulk download. Does not document world-tile LOD or GPU behavior.

### S12 — Pokémon GO Battery Saver

- Publication/version: Current official help; checked 2026-10-07.
- Source: [Pokémon GO Battery Saver](https://niantic.helpshift.com/hc/en/6-pokemon-go/faq/2472-what-is-the-battery-saver-setting/?s=general).
- Evidence and limitation: Verified display behavior when the phone points down. No verified claim of rendering shutdown or a particular frame-rate cap.

### S13 — Snap Map launch

- Publication/version: 2017-06-21; checked 2026-10-07.
- Source: [Snap Map launch](https://newsroom.snap.com/introducing-snap-map).
- Evidence and limitation: Verified shipped map product. Streaming, 3D LOD and thermal internals remain unverified.

### S14 — Microsoft Flight Simulator model LODs

- Publication/version: MSFS 2020 SDK documentation; checked 2026-10-07.
- Source: [Microsoft Flight Simulator model LODs](https://docs.flightsimulator.com/html/Asset_Creation/3D_Models/LODs.htm).
- Evidence and limitation: Verified authored LOD guidance, draw-call tradeoffs and grouping/culling limitations. Desktop aircraft/world recommendations are not mobile budgets.

### S15 — MSFS 2024 LOD selection

- Publication/version: MSFS 2024 SDK documentation; checked 2026-10-07.
- Source: [MSFS 2024 LOD selection](https://docs.flightsimulator.com/msfs2024/flighting/models-and-textures/modeling/lods/lod-selection-system/).
- Evidence and limitation: Verified projected bounding-sphere screen ratio for selection. Package/version behavior differs.

### S16 — Microsoft Flight Simulator 2024 preview

- Publication/version: 2024-09-19; checked 2026-10-07.
- Source: [Microsoft Flight Simulator 2024 preview](https://news.xbox.com/en-us/2024/09/19/microsoft-flight-simulator-2024-preview/).
- Evidence and limitation: Verified vendor description of a thin client streaming needed world data. No transferable A16 performance result.

### S17 — Sunset Overdrive city streaming

- Publication/version: GDC 2015; checked 2026-10-07.
- Source: [Sunset Overdrive city streaming](https://www.gdcvault.com/play/1022268/Streaming-in-Sunset-Overdrive-s).
- Evidence and limitation: Verified session abstract on streaming a shipped stylized city. Linked slide PDF did not fully open in research; no detailed memory or timing result is treated as verified.

### S18 — Horizon Zero Dawn vegetation

- Publication/version: GDC 2018; checked 2026-10-07.
- Source: [Horizon Zero Dawn vegetation](https://www.gdcvault.com/play/1025530/Between-Tech-and-Art-The).
- Evidence and limitation: Verified session; primary slide extract supports aggressive plant LOD. Full PDF inspection unavailable; numerical slide extract is labeled accordingly in README.

### S19 — Horizon procedural placement

- Publication/version: 2017-03-01; checked 2026-10-07.
- Source: [Horizon procedural placement](https://www.guerrilla-games.com/read/gpu-based-procedural-placement-in-horizon-zero-dawn).
- Evidence and limitation: Verified developer account of GPU placement around the active vicinity. Console technique, not an iPhone implementation recipe.

### S20 — Ghost of Tsushima atmosphere

- Publication/version: SIGGRAPH Advances in Real-Time Rendering 2021; checked 2026-10-07.
- Source: [Ghost of Tsushima atmosphere](https://advances.realtimerendering.com/s2021/jpatry_advances2021/index.html).
- Evidence and limitation: Verified developer atmosphere/cloud presentation. LUTs and amortized work are transferable concepts; PS4 timings are not A16 predictions.

### S21 — Unreal hierarchical LOD

- Publication/version: Current engine documentation; checked 2026-10-07.
- Source: [Unreal hierarchical LOD](https://dev.epicgames.com/documentation/unreal-engine/hierarchical-level-of-detail-in-unreal-engine?lang=en-US).
- Evidence and limitation: Verified distant actor replacement by proxy meshes/materials. Does not establish availability in RealityKit.

### S22 — Fortnite draw-call reduction

- Publication/version: Current UEFN documentation; checked 2026-10-07.
- Source: [Fortnite draw-call reduction](https://dev.epicgames.com/documentation/fortnite/reducing-draw-calls-in-fortnite).
- Evidence and limitation: Verified stylized-world guidance on material slots and custom LODs. Not evidence that Nanite is available in WorldEngine.

### S23 — three.js InstancedMesh

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [three.js InstancedMesh](https://threejs.org/docs/pages/InstancedMesh.html).
- Evidence and limitation: Verified repeated geometry/material instancing and bounds APIs. Does not reduce geometry per instance.

### S24 — three.js BatchedMesh

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [three.js BatchedMesh](https://threejs.org/docs/pages/BatchedMesh.html).
- Evidence and limitation: Verified different meshes sharing material, per-object culling and multidraw-oriented batching. Hardware draw count depends on backend/extensions.

### S25 — three.js LOD

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [three.js LOD](https://threejs.org/docs/pages/LOD.html).
- Evidence and limitation: Verified distance-based levels and hysteresis. Screen-error selection needs application policy.

### S26 — three.js shadows

- Publication/version: Current manual; checked 2026-10-07.
- Source: [three.js shadows](https://threejs.org/manual/pages/shadows.html).
- Evidence and limitation: Verified additional shadow rendering and cheap fake/blob shadow examples. Contact-shadow render passes are not free.

### S27 — three.js cascaded shadow maps

- Publication/version: Current addon documentation; checked 2026-10-07.
- Source: [three.js cascaded shadow maps](https://threejs.org/docs/pages/CSM.html).
- Evidence and limitation: Verified cascade configuration. More cascades add work; this is a quality distribution technique, not an inherent optimization.

### S28 — three.js fog

- Publication/version: Current manual; checked 2026-10-07.
- Source: [three.js fog](https://threejs.org/manual/pages/fog.html).
- Evidence and limitation: Verified visual fog. Rendering fog does not automatically stop distant object submission.

### S29 — three.js glTF loading

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [three.js glTF loading](https://threejs.org/docs/pages/GLTFLoader.html).
- Evidence and limitation: Verified Draco/meshopt/BasisU and other supported extensions with configured decoders/loaders. Compression of transfer bytes need not reduce decoded geometry memory.

### S30 — three.js KTX2Loader

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [three.js KTX2Loader](https://threejs.org/docs/pages/KTX2Loader.html).
- Evidence and limitation: Verified GPU-format detection/transcoding and worker controls. Format support and decode cost need device testing.

### S31 — RealityKit mesh instancing

- Publication/version: Current API documentation / WWDC 2025; checked 2026-10-07.
- Source: [RealityKit mesh instancing](https://developer.apple.com/documentation/realitykit/meshinstancescomponent).
- Evidence and limitation: Verified native instance API; installed SDK declares iOS 26 availability. Instance-level culling behavior still needs measurement.

### S32 — RealityKit CPU utilization

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [RealityKit CPU utilization](https://developer.apple.com/documentation/realitykit/reducing-cpu-utilization-in-your-realitykit-app).
- Evidence and limitation: Verified batching/flattening guidance and loss of culling from oversized merged meshes. Sharing a mesh resource is not proof of one draw.

### S33 — RealityKit LevelOfDetailComponent

- Publication/version: Current online API documentation / WWDC 2026; checked 2026-10-07.
- Source: [RealityKit LevelOfDetailComponent](https://developer.apple.com/documentation/realitykit/levelofdetailcomponent).
- Evidence and limitation: Verified online native authored LOD API. Absent from installed iOS 26.4 SDK; exact deployment floor unverified. Not automatic mesh simplification or world streaming.

### S34 — RealityKit BillboardComponent

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [RealityKit BillboardComponent](https://developer.apple.com/documentation/realitykit/billboardcomponent).
- Evidence and limitation: Verified camera-facing entity API; installed SDK declares iOS 18. Per-instance orientation within an instance group is not established.

### S35 — RealityKit CustomMaterial

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [RealityKit CustomMaterial](https://developer.apple.com/documentation/realitykit/modifying-realitykit-rendering-using-custom-materials).
- Evidence and limitation: Verified material customization. Installed SDK declares iOS 15 and unavailable on visionOS; shader hooks do not confer ownership of all render passes.

### S36 — RealityKit directional shadows

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [RealityKit directional shadows](https://developer.apple.com/documentation/realitykit/directionallightcomponent/shadow).
- Evidence and limitation: Verified projection controls; installed SDK supports iOS 18 automatic/fixed projection and culling override. maximumDistance is deprecated from iOS 18.

### S37 — RealityKit Cascades

- Publication/version: Current online API documentation; checked 2026-10-07.
- Source: [RealityKit Cascades](https://developer.apple.com/documentation/realitykit/directionallightcomponent/shadow/cascades-swift.struct).
- Evidence and limitation: Verified online cascade API. Absent from installed iOS 26.4 SDK; deployment floor unverified. No assumption of arbitrary shadow caching/resolution control.

### S38 — RealityKit dynamic shadow participation

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [RealityKit dynamic shadow participation](https://developer.apple.com/documentation/realitykit/dynamiclightshadowcomponent).
- Evidence and limitation: Verified component; installed SDK declares iOS 18. Use caster participation to limit unnecessary work.

### S39 — RealityKit LightmapComponent

- Publication/version: Current online API documentation; checked 2026-10-07.
- Source: [RealityKit LightmapComponent](https://developer.apple.com/documentation/realitykit/lightmapcomponent).
- Evidence and limitation: Verified online native lightmap API. Absent from installed iOS 26.4 SDK; deployment floor unverified. Fixed-sun bakes conflict with changing solar direction.

### S40 — RealityKit LowLevelMesh

- Publication/version: Current API documentation / WWDC 2024; checked 2026-10-07.
- Source: [RealityKit LowLevelMesh](https://developer.apple.com/documentation/realitykit/lowlevelmesh).
- Evidence and limitation: Verified low-level CPU/GPU mesh update facility; installed SDK declares iOS 18. Not a tile loader or automatic batching system.

### S41 — RealityKit async entity loading

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [RealityKit async entity loading](https://developer.apple.com/documentation/realitykit/entity/init(contentsof:withname:)).
- Evidence and limitation: Verified async loading initializer. Does not promise zero decode/upload/scene-attachment hitches.

### S42 — RealityKit app performance

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [RealityKit app performance](https://developer.apple.com/documentation/realitykit/improving-the-performance-of-a-realitykit-app).
- Evidence and limitation: Verified ARView contentScaleFactor guidance. Equivalent phone RealityView controls unverified; visionOS adaptation is not proof for iPhone.

### S43 — Foundation ProcessInfo

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [Foundation ProcessInfo](https://developer.apple.com/documentation/foundation/processinfo).
- Evidence and limitation: Verified thermal state and related notifications; Low Power Mode is also exposed. Application quality tiers are a proposal.

### S44 — Available process memory

- Publication/version: Current API documentation; checked 2026-10-07.
- Source: [Available process memory](https://developer.apple.com/documentation/os/os_proc_available_memory).
- Evidence and limitation: Verified advisory process-memory availability. Neither physical RAM nor this changing value is a universal safe cache allowance.

### S45 — Metal optimization

- Publication/version: WWDC 2019 session 606; checked 2026-10-07.
- Source: [Metal optimization](https://developer.apple.com/videos/play/wwdc2019/606/?time=160).
- Evidence and limitation: Verified Apple advice to optimize under serious thermal conditions and examine memory/bandwidth. No device-specific FPS guarantee.

### S46 — Metal GPU-driven rendering

- Publication/version: WWDC 2020 session 10602; checked 2026-10-07.
- Source: [Metal GPU-driven rendering](https://developer.apple.com/videos/play/wwdc2020/10602/).
- Evidence and limitation: Verified GPU culling/indirect-command principles. Advanced custom Metal renderer work is separate from RealityKit entity control.

### S47 — Xcode Metal performance analysis

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [Xcode Metal performance analysis](https://developer.apple.com/documentation/xcode/analyzing-the-performance-of-your-metal-app).
- Evidence and limitation: Verified capture/performance analysis workflow. Use it to establish pass costs rather than infer bottlenecks from draw counts alone.

### S48 — Xcode launch time

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [Xcode launch time](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time).
- Evidence and limitation: Verified first-frame launch measurement and launch-work guidance. A usable 3D scene needs an additional application metric.

### S49 — Metal GPU memory bandwidth

- Publication/version: Current documentation; checked 2026-10-07.
- Source: [Metal GPU memory bandwidth](https://developer.apple.com/documentation/xcode/measuring-the-gpus-use-of-memory-bandwidth?changes=_7).
- Evidence and limitation: Verified GPU bandwidth analysis and resource-read considerations. Useful for shadow/foliage/texture bottlenecks.

### S50 — Metal feature-set tables

- Publication/version: 2026-05-21 PDF; checked 2026-10-07.
- Source: [Metal feature-set tables](https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf).
- Evidence and limitation: Verified official feature matrix source. Gate advanced paths by actual GPU family and OS; no blanket A16 support claim for newer sparse/Metal 4 features.

### S51 — WWDC 2026 RealityKit

- Publication/version: WWDC 2026 session 279; checked 2026-10-07.
- Source: [WWDC 2026 RealityKit](https://developer.apple.com/videos/play/wwdc2026/279/).
- Evidence and limitation: Verified announcement of new RealityKit capabilities. Installed SDK inspection is kept separate from online documentation.


## Supporting primary artifacts and access limitations

- [Horizon vegetation slides, GDC 2018](https://media.gdcvault.com/gdc2018/presentations/gilbert_sanders_between_tech_and.pdf): full PDF open failed during research. The indexed primary extract provides the LOD numbers used once in README. Treat detailed slide interpretation beyond that extract as unverified.
- [Sunset Overdrive slides, GDC 2015](https://media.gdcvault.com/gdc2015/presentations/Ruskin_Elan_SunsetOverdriveStreaming.pdf): full PDF open failed. Only session-level claims in the accessible GDC abstract are used.
- [Ghost Recon Wildlands terrain tools, GDC 2017](https://media.gdcvault.com/gdc2017/Presentations/WERLE_MARTINEZ_GRWterrainTechnologyTools.pdf): additional primary streaming/quadtree precedent found; not used to assign WorldEngine gains.
- [RealityKit instancing session, WWDC 2025](https://developer.apple.com/videos/play/wwdc2025/287/): supporting native instancing announcement. Do not transfer visionOS workload budgets to A16.
- [RealityKit immersive environment guidance](https://developer.apple.com/documentation/realitykit/construct-an-immersive-environment-for-visionos): supporting instance/material guidance; its platform is visionOS, not the iPhone baseline.
- [Foundation Low Power Mode](https://developer.apple.com/documentation/foundation/processinfo/islowpowermodeenabled): supports LPM quality policy.
- [Metal recommendedMaxWorkingSetSize](https://developer.apple.com/documentation/metal/mtldevice/recommendedmaxworkingsetsize): GPU working-set guidance; platform availability must be verified before use. It is not a universal jetsam/app RAM allowance.

No blocked or paywalled source was bypassed. Sources with inaccessible full slides are explicitly restricted above. Apple Maps / Google Maps app / Snap Map / Pokémon GO internal renderer architecture was not established by screenshots, product announcements or adjacent SDKs.

## Read-only local SDK evidence

Inspected SDK: **iPhoneOS 26.4**, checked 2026-10-07. Local SDK version from SDKSettings.json. Declaration source:

`/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/RealityFoundation.framework/Modules/RealityFoundation.swiftmodule/arm64e-apple-ios.swiftinterface`

| Symbol / declaration | Approximate inspected line | Finding |
|---|---:|---|
| Directional shadow projection controls | 95–113 | iOS 18 fixed/automatic projection and culling override; maximumDistance deprecated |
| LowLevelMesh | 9524 | iOS 18 / visionOS 2 |
| BillboardComponent | 10011 | iOS 18 / visionOS 2 |
| DynamicLightShadowComponent | 10616 | iOS 18 / visionOS 2 |
| CustomMaterial | 10712 | iOS 15; unavailable on visionOS in this SDK |
| LowLevelInstanceData | 11145 | iOS 26 / visionOS 26 |
| MeshInstancesComponent | 11163 | iOS 26 / visionOS 26 |
| LevelOfDetailComponent, LightmapComponent, Shadow.Cascades | Not found | Online API existence verified; exact deployment floors unverified. Absence from this installed SDK does not establish absence from newer SDKs. |

Line numbers are local inspection references and can change with Xcode. Compile against the chosen shipping SDK and check availability annotations before committing a baseline to new APIs.

## Claim status rules

- **Verified mechanism:** primary documentation or a developer conference source describes it. “Who ships it” distinguishes a product implementation from a library capability or conceptual precedent.
- **Vendor result:** an explicitly scoped result reported by the vendor; not reproduced here or used as an A16 gain prediction.
- **Derived arithmetic:** triangle/draw/pixel ratios calculated from stated examples; not measured GPU-time improvements.
- **Assumption / proposal:** ranks, cost levels, cell sizes, LOD thresholds, quality ladders, headroom goals and experiment durations are authored recommendations.
- **Unverified:** missing target-app internals, deployment floors, per-instance culling, phone RealityView resolution control, native glTF extension handling and WorldEngine timings. CSV gain fields explicitly remain unmeasured even where the mechanism is verified.
