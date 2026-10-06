# WorldEngine web renderer (three.js)

Loads the shared world package (`docs/package-format.md`) and renders it with three.js r180's `WebGPURenderer`: WebGPU when available, WebGL2 when asked (`backend=webgl2`) or when WebGPU is missing. Same camera rig, presets, walking loop and look as the RealityKit renderer in WorldLab.

## Build and run
`scripts/generate.sh` builds everything WorldLab bundles (dog conversion, package export, this bundle). On its own:

```
scripts/build-web.sh            # npm ci on first use, then web/dist
node web/serve.mjs              # http://127.0.0.1:8765/?backend=webgpu  (Safari on the Mac)
```

In WorldLab the bundle, the package and the dog are app resources served by a loopback server (`Apps/WorldLab/Sources/LocalServer.swift`), so WebGPU gets a secure, cross-origin-isolated context.

URL parameters: `backend=webgpu|webgl2`, `preset=v2-01|v2-04|v2-06|street-mid|corner|lake-path|aerial-low`, `state=golden|noon`, `frame16x9=1`, `hud=0`, `post=0`, `shadows=0`; calibration overrides `sun=`, `env=`, `bg=`, `tm=aces|neutral|agx`.

## Modules (`src/`)
| File | Role |
|---|---|
| `main.js` | Boot, renderer, frame loop (same order as RealityKit: camera, motion, world, globals), presets, gestures |
| `world.js` | Package loading: chunks, prototypes, per-cell instancing with near/mid/far detail, tufts, collision hulls |
| `materials.js` | TSL port of `Sources/WorldEngine/Shaders/WorldShaders.metal` (palette, AO fill, fog, mottling, joints, windows, sway, cut-away, contact shadow) |
| `lighting.js` | Light state → sun, shadows, sky background, diffuse sky light (spherical harmonics), fog policy; calibration constants |
| `camera.js` | Port of `WorldCamera`: street follow with projected-bounds framing, occlusion, recenter; fixed and overview modes |
| `motion.js`, `geo.js` | Route walking and exact WGS84 local frame, ported from Swift |
| `dog.js` | Luna (`dog/luna_light.glb`): walk clip, coat material matching `DogCoat.metal` |
| `post.js` | Tone curve, emissive bloom, grade (matches `PostProcess.swift`) |
| `metrics.js` | Frame intervals to WorldLab's TestRun through the `worldlab` message handler |

## Known differences from RealityKit
- Shadows: one 2048² map over ±40 m that follows the view (RealityKit: cascades to 80 m); back faces cast, so flat ground never self-shadows. Edges are crisper.
- Sky light is diffuse only (spherical harmonics of the sky image); RealityKit's image-based light also adds faint speculars.
- Depth: three.js r180 has no reversed depth buffer, so the near plane scales with camera height (0.31 m at street level, ~370 m in the aerial) to keep centimeter-spaced ground layers stable.
- Frame timestamps in WebKit are whole milliseconds, so ">16.9 ms" counts are inflated by rounding; missed frames (>25 ms) are the reliable jank measure.
