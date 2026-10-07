# WorldEngine web stack v1 — sources and evidence limits

Research accessed 7 October 2026 unless noted. IDs in README.md and options.csv refer to the entries below; ranges (e.g. E01–E07) mean inclusive IDs. Duplicate URLs remain under lane-specific IDs to keep traceability. Current docs/source branches can change: pin and inspect exact production releases.

Engine, MapLibre, performance/streaming and packaging lanes used primary vendor, maintainer and standards sources. MDN supplies browser implementation guidance, not normative specs or WorldEngine benchmarks. Local reports were read first as requested, but their underlying code and earlier test context were not revalidated. No devices, partner accounts, quotes or prototype were tested. All numeric performance budgets, WorldEngine pricing, commercial margin inputs and effort estimates are authored proposals. Published vendor rates are dated snapshots with non-equivalent meters and separate terms. Google meter wording and maplibre-gl-three v3 licence remain unverified.

## E01 — three.js WebGLRenderer documentation

[Open source](https://threejs.org/docs/pages/WebGLRenderer.html)

- Date: accessed 2026-10-07
- Evidence status: primary documentation
- Supports and limitations: WebGL2 only; WebGL1 removed r163; existing WebGL2 context; resetState for shared libraries; renderer counters; context loss tools

## E02 — WebKit Features in Safari 26.0

[Open source](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/)

- Date: 2025-09-15; accessed 2026-10-07
- Evidence status: primary shipped release announcement
- Supports and limitations: WebGPU shipped Safari26 on iOS/iPadOS/macOS/visionOS; compute and WGSL

## E03 — GPUWeb Implementation Status

[Open source](https://github.com/gpuweb/gpuweb/wiki/Implementation-Status)

- Date: updated 2026-10-02; accessed 2026-10-07
- Evidence status: primary working-group living status matrix; not device benchmark
- Supports and limitations: Android ARM/Qualcomm/Intel Android12+ Chrome121; Imagination Android16+ Chrome139; Samsung Xclipse TBD; Safari26 enabled by default

## E04 — Khronos WebGL2 pervasive support

[Open source](https://www.khronos.org/blog/webgl-2-achieves-pervasive-support-from-all-major-web-browsers)

- Date: 2022-02-09; accessed 2026-10-07
- Evidence status: primary standards-group announcement
- Supports and limitations: WebGL2 Safari15 macOS/iOS; major browser reach; instancing/transform feedback/MRT/UBO

## E05 — three.js WebGPURenderer documentation

[Open source](https://threejs.org/docs/pages/WebGPURenderer.html)

- Date: accessed 2026-10-07
- Evidence status: primary documentation; application parity unverified
- Supports and limitations: Default WebGPU backend; WebGL2 fallback

## E06 — Babylon official WebGPU documentation source

[Open source](https://github.com/BabylonJS/Documentation/blob/master/content/setup/support/webGPU.md)

- Date: accessed 2026-10-07
- Evidence status: primary documentation repository; web documentation page returned JS shell
- Supports and limitations: WebGPU in main; async initialization; continued WebGL support; backend selected before scene/resources

## E07 — What's New in WebGPU Chrome121

[Open source](https://developer.chrome.com/blog/new-in-webgpu-121)

- Date: accessed 2026-10-07
- Evidence status: primary browser vendor release note; superseded for expanded device matrix by E03
- Supports and limitations: Initial Android12+ ARM/Qualcomm default enablement; conditional timestamp-query feature

## E08 — WHATWG HTML Canvas Standard

[Open source](https://html.spec.whatwg.org/multipage/canvas.html#dom-canvas-getcontext-dev)

- Date: accessed 2026-10-07
- Evidence status: primary standard
- Supports and limitations: Canvas has one bound context type; requesting different context type returns null

## E09 — three.js MIT licence

[Open source](https://github.com/mrdoob/three.js/blob/dev/LICENSE)

- Date: accessed 2026-10-07
- Evidence status: primary repository licence
- Supports and limitations: MIT permission for commercial use/distribution and retained notice condition

## E10 — Babylon.js Specifications

[Open source](https://www.babylonjs.com/specifications/)

- Date: accessed 2026-10-07
- Evidence status: primary engine vendor specification
- Supports and limitations: Integrated renderer/scene tools; WebGPU; thin instances; glTF; node material

## E11 — WorldEngine prior mobile rendering research and compatibility followup

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/compatibility.md)

- Date: 2026-10-07; read 2026-10-07
- Evidence status: user-supplied local research; underlying code not revalidated
- Supports and limitations: Prior code-derived native/current-export findings; counters and LOD; no device tests this task

## E12 — Competitors as customers addendum

[Open source](~/Desktop/worldengine-gpt-drop/creator-kit-demand-v1/competitors-as-customers.md)

- Date: read 2026-10-07
- Evidence status: user-supplied local research; partner intent unverified
- Supports and limitations: Web/SDK fit, retained authoritative data, feature IDs, partner requirements and pricing hypotheses

## E13 — Babylon.js Apache2 licence

[Open source](https://github.com/BabylonJS/Babylon.js/blob/master/license.md)

- Date: accessed 2026-10-07
- Evidence status: primary repository licence
- Supports and limitations: Apache2 software licence

## ML01 — MapLibre CustomLayerInterface

[Open source](https://maplibre.org/maplibre-gl-js/docs/API/interfaces/CustomLayerInterface/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Shared GL context, depth, prerender, lifecycle and state contract; inline callback sample conflicts with typedef

## ML02 — MapLibre CustomRenderMethod

[Open source](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/CustomRenderMethod/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: render(gl,options) current documented typedef

## ML03 — MapLibre source CustomRenderMethod

[Open source](https://raw.githubusercontent.com/maplibre/maplibre-gl-js/main/src/style/style_layer/custom_style_layer.ts)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Source confirms two-argument render; source can move

## ML04 — MapLibre CustomRenderMethodInput

[Open source](https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/CustomRenderMethodInput/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: mainMatrix Mercator limitations, projection shaders, experimental terrain-height rendering

## ML05 — MapLibre v5 to v6 migration

[Open source](https://maplibre.org/maplibre-gl-js/docs/guides/v5-to-v6-migration-guide/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: v6 ESM only, WebGL2 required, worker/CSP changes, map.transform removed

## ML06 — MapLibre MercatorCoordinate

[Open source](https://maplibre.org/maplibre-gl-js/docs/API/classes/MercatorCoordinate/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Normalized world coordinate and latitude-dependent meter conversion

## ML07 — Three WebGLRenderer

[Open source](https://threejs.org/docs/pages/WebGLRenderer.html)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Shared context resetState, autoClear, render-target behavior

## ML08 — MapLibre real Three 3D Tiles example

[Open source](https://maplibre.org/maplibre-gl-js/docs/examples/add-3d-tiles-3d-objects-and-models-using-threejs/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Current official example uses maplibre-gl-three

## ML09 — MapLibre Three raycasting example

[Open source](https://maplibre.org/maplibre-gl-js/docs/examples/raycast-3d-tiles-using-threejs/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Globe + terrain + 3D Tiles + local/ECEF ray conversions; example pins 6.13.0, Three 0.186.1, bridge 3.0.0

## ML10 — maplibre-gl-three principles

[Open source](https://maplibre-gl-three.readthedocs.io/latest/principles/)

- Date: 2026-10-07
- Evidence status: Primary indexed only; full fetch failed
- Supports and limitations: Indexed maintainer documentation: per-map manager and local/ECEF/elevation treatment; full page fetch failed

## ML11 — MapLibre licence

[Open source](https://github.com/maplibre/maplibre-gl-js/blob/main/LICENSE.txt)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: BSD-3-Clause

## ML12 — maplibre-gl-three maintainer docs

[Open source](https://maplibre-gl-three.readthedocs.io/latest/)

- Date: 2026-10-07
- Evidence status: Primary inspected
- Supports and limitations: Bridge API documented; exact v3 package licence not verified

## F01 — three.js GLTFLoader

[Open source](https://threejs.org/docs/pages/GLTFLoader.html)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: GLTFLoader supports meshopt, KTX2/Basis and GPU instancing extensions with configured decoders; ImageBitmap lifetime needs explicit care.

## F02 — three.js KTX2Loader

[Open source](https://threejs.org/docs/pages/KTX2Loader.html)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: KTX2Loader detects renderer format support, transcodes and provides worker-limit/disposal APIs. Final formats depend on device.

## F03 — 3DTilesRendererJS repository

[Open source](https://github.com/NASA-AMMOS/3DTilesRendererJS)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Apache-2.0 renderer; hard item/byte caps may stop new tile loading. Monitor refused tiles/cached bytes and coarsen; extension support has exceptions.

## F04 — 3DTilesRendererJS core API

[Open source](https://raw.githubusercontent.com/NASA-AMMOS/3DTilesRendererJS/master/src/core/renderer/API.md)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Byte LRU accounting, min/max byte sizes, queue controls, screen-space error and active/visible/refusal statistics. Library defaults are not phone budgets.

## F05 — 3DTilesRendererJS plugin API

[Open source](https://raw.githubusercontent.com/NASA-AMMOS/3DTilesRendererJS/master/src/three/plugins/API.md)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: GLTFExtensionsPlugin takes meshopt/KTX2 configuration. Metadata support has incomplete 64-bit integer handling; preserve canonical string IDs.

## F06 — 3DTilesRendererJS usage

[Open source](https://raw.githubusercontent.com/NASA-AMMOS/3DTilesRendererJS/master/USAGE.md)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Camera resolution, material lifecycle, shared queues/caches and render-on-change integration.

## F07 — MDN WebGL best practices

[Open source](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: No portable maximum VRAM query; app byte budgets, smaller backbuffers, batching/compressed textures and nonblocking operations. Numeric targets here are authored.

## F08 — three.js WebGLRenderer

[Open source](https://threejs.org/docs/pages/WebGLRenderer.html)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: renderer.info resets per render unless autoReset=false; memory fields count objects rather than bytes. Existing WebGL2 context supported; powerPreference is a hint.

## F09 — three.js resource disposal

[Open source](https://threejs.org/manual/pages/how-to-dispose-of-objects.html)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Explicit geometry, material, texture and render-target disposal. ImageBitmap CPU close is separate; shared resource lifetime belongs to application.

## F10 — W3C Compute Pressure Level1

[Open source](https://www.w3.org/TR/compute-pressure/)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Compute Pressure Level 1 is CPU pressure, not portable device temperature; implementation support is not an interoperable iOS/Android thermal baseline.

## F11 — MDN WEBGL_lose_context

[Open source](https://developer.mozilla.org/en-US/docs/Web/API/WEBGL_lose_context)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: WEBGL_lose_context simulates context loss and restoration for recovery tests.

## F12 — MDN performance.memory

[Open source](https://developer.mozilla.org/en-US/docs/Web/API/Performance/memory)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: performance.memory is nonstandard/deprecated heap information, not total browser process/GPU memory.

## F13 — OGC 3D Tiles standard

[Open source](https://www.ogc.org/standards/3dtiles/)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: 3D Tiles open standard for spatial hierarchy and massive geospatial streaming; no phone performance certification or dataset licence.

## F14 — Khronos glTF2 specification

[Open source](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: glTF runtime payload format does not supply a world-scale hierarchy or network scheduling.

## F15 — meshoptimizer

[Open source](https://github.com/zeux/meshoptimizer)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: MIT geometry optimization, quantization, compression and decoding; compression alone does not reduce submitted triangle counts.

## F16 — Khronos KHR_texture_basisu

[Open source](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_texture_basisu/README.md)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: KHR_texture_basisu supplies KTX2/Basis Universal textures; final GPU residency depends on the transcode target.

## F17 — Basis Universal licence

[Open source](https://github.com/BinomialLLC/basis_universal/blob/master/LICENSE)

- Date: 2026-10-07
- Evidence status: primary source inspected; current docs not pinned production release
- Supports and limitations: Basis Universal Apache-2.0 software licence; asset rights remain separate.

## F18 — WorldEngine mobile-rendering-v1 pack

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/)

- Date: 2026-10-07
- Evidence status: read-only local prior research; not runtime verified
- Supports and limitations: Required prior mobile pack read: native context is not a web benchmark; custom GLB semantics, local cells, globe precision and prior native-plus-web estimates.

## F19 — Competitors as customers

[Open source](~/Desktop/worldengine-gpt-drop/creator-kit-demand-v1/competitors-as-customers.md)

- Date: 2026-10-07
- Evidence status: read-only local prior research; not runtime verified
- Supports and limitations: Required partner addendum read: prospective embed/SDK workflows, routes/markers, customer models, accessibility and weak-network constraints; interest is unverified.

## P01 — Mapbox pricing

[Open source](https://www.mapbox.com/pricing)

- Date: accessed 2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: GLJS 50k free monthly loads; first paid band USD5/1k then4/3; map initialization meter

## P02 — Mapbox third-party-tool pricing

[Open source](https://docs.mapbox.com/accounts/guides/pricing/sections/third-party-tools/)

- Date: accessed 2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Mapbox-hosted tiles with third-party renderer bill by requests, not GLJS loads

## P03 — MapTiler pricing

[Open source](https://www.maptiler.com/cloud/pricing/)

- Date: accessed 2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: USD30/month Flex; 25k sessions/500k requests included; extra USD2.50/1k map sessions,0.15/1k requests; GeoSplats USD6/1k 3D sessions; not generic MapLibre meter

## P04 — MapTiler sessions vs requests

[Open source](https://docs.maptiler.com/guides/account/sessions-vs-requests/)

- Date: accessed 2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: SDK sessions vs third-party requests; session up to6 hours/10k requests or page refresh

## P05 — Cesium ion pricing

[Open source](https://cesium.com/platform/cesium-ion/pricing/)

- Date: accessed 2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Commercial USD149/month individual or524 team; 150GB/month streaming; hosted service distinct from open renderer

## P06 — Cesium ion terms

[Open source](https://cesium.com/legal/terms-of-service)

- Date: major2025-08-20 minor2025-08-27;accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Commercial sublicensing needs integration licence; standard plan not blanket OEM rights

## P07 — Google global price list

[Open source](https://developers.google.com/maps/billing-and-pricing/pricing)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: USD6/1k Photorealistic3D billable events after1k free, first paid tier; 2D tiles USD0.60/1k after100k free

## P08 — Google Map Tiles billing/quota

[Open source](https://developers.google.com/maps/documentation/tile/usage-and-billing)

- Date: updated2026-10-05;accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: 3D root requests quota; up to3 hours child-tile requests; 2D per tile

## P09 — Google Map Tiles GA announcement

[Open source](https://mapsplatform.google.com/resources/blog/build-immersive-maps-at-scale-with-photorealistic-3d-2d-and-street-view-tiles-now-in-ga/)

- Date: 2023;accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Explicit root request billing akin session; current SKU-details generic wording needs check

## P10 — MapLibre licence

[Open source](https://github.com/maplibre/maplibre-gl-js/blob/main/LICENSE.txt)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: BSD3-Clause-style renderer licence plus incorporated notices

## P11 — 3DTilesRendererJS licence

[Open source](https://github.com/NASA-AMMOS/3DTilesRendererJS/blob/master/LICENSE)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Apache2; Caltech2020

## P12 — meshoptimizer licence

[Open source](https://github.com/zeux/meshoptimizer/blob/master/LICENSE.md)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: MIT

## P13 — Basis Universal licence

[Open source](https://github.com/BinomialLLC/basis_universal/blob/master/LICENSE)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Apache2; inspect actual packaged transcoders and notices

## P14 — WHATWG cross-document messaging

[Open source](https://html.spec.whatwg.org/multipage/web-messaging.html#crossDocumentMessages)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: postMessage exact origin; verify origin and data

## P15 — W3C CSP3

[Open source](https://w3c.github.io/webappsec-csp/)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: frame-ancestors; worker-src; connect-src; script-src/WASM policy

## P16 — W3C Geolocation

[Open source](https://www.w3.org/TR/geolocation/)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Secure context,user permission,iframe Permissions Policy/privacy

## P17 — Chrome SharedArrayBuffer isolation

[Open source](https://developer.chrome.com/blog/enabling-shared-array-buffer/)

- Date: accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: SharedArrayBuffer cross-origin isolation; embedding impact

## P18 — W3C WCAG2.2

[Open source](https://www.w3.org/TR/WCAG22/)

- Date: 2024-12-12;accessed2026-10-07
- Evidence status: primary source; exact release dependency audit unverified
- Supports and limitations: Text alternatives,keyboard,no trap,focus,pause,drag alternatives; reduced interaction animation AAA

## P19 — Competitors-as-customers local addendum

[Open source](~/Desktop/worldengine-gpt-drop/creator-kit-demand-v1/competitors-as-customers.md)

- Date: read2026-10-07
- Evidence status: user-provided prior research; hypotheses
- Supports and limitations: Prior OEM hypotheses; event/campus/map fit; no confirmed demand

## L01 — Prior mobile rendering README

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/README.md)

- Date: read 2026-10-07
- Evidence status: prior local research; underlying code and device claims not revalidated
- Supports and limitations: Native targets and optimization inventory; not browser benchmarks.

## L02 — Prior mobile rendering follow-up

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/README-followup.md)

- Date: read 2026-10-07
- Evidence status: prior local research; underlying code and device claims not revalidated
- Supports and limitations: Owner look requirements and compatibility caveats; see streaming design for mandatory globe contract.

## L03 — Prior streaming design

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/streaming-design.md)

- Date: read 2026-10-07
- Evidence status: prior local research; underlying code and device claims not revalidated
- Supports and limitations: Immutable generated geometry, bounded proposed streaming, parent coverage, double ECEF coordinates and street-to-space design; prior estimate includes native and web work.

## L04 — Prior techniques inventory

[Open source](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/techniques.csv)

- Date: read 2026-10-07
- Evidence status: prior local research; underlying code and device claims not revalidated
- Supports and limitations: LOD/instancing/batching, export and shader compatibility; proposed versus already implemented distinctions.

## L05 — MDN Storage quotas and eviction

[Open source](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria)

- Date: accessed 2026-10-07
- Evidence status: browser documentation inspected
- Supports and limitations: Storage quotas and eviction describe persistent browser storage, not available RAM/VRAM; caching is not an offline guarantee.
