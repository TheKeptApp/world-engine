# Shared world package (format 1)

The generator (`WorldGen`) is the one decision owner. RealityKit generates in-process through `WorldBuild`; every other renderer loads this package, exported from the same `WorldBuild` by:

```
scripts/export-package.sh            # → Generated/package/<area>/ (git-ignored)
```

Renderers never re-derive roofs, colors, placements or seeds. Code: `Sources/WorldPackage/`. Tests: `Tests/WorldPackageTests/`.

## Layout

| Path | Contents |
|---|---|
| `world.json` | Schema `worldengine.package/1`; generator version (git commit); area; OSM sources with license, attribution, data timestamp and source hash; frame (exact WGS84 ENU, double-precision origin, meters, +X east / +Y up / −Z north, flat terrain); recipe (profile + version, season, date, focus); bounds; chunk index; prototypes; runtime policies; capability requirements; SHA-256 and size of every other file. |
| `chunks/<i>_<j>/lod0.glb`, `lod1.glb` | 200 m chunk meshes. One node translated to the chunk center (float32 vertices relative to it), primitives `worldStatic` and `worldWater`. lod1: every building simple, no curbs or sidewalk edges (≈39% of lod0 triangles). |
| `chunks/<i>_<j>/scene.json` | Feature table: index, identity (`way/123`, `node/…`, `gen:…`), kind, vertex ranges per LOD and primitive, OSM source tags, and for buildings the generated choices (house type, roof shape and whether it came from OSM or the profile, floors, color set and colors, porch style, front edge, garage door edge, eave and top heights). |
| `prototypes/<kind>-<variant>-lod<n>.glb` | Trees (three archetypes + conifer, 3 LODs), bushes and flower bushes (2 shapes, 3 LODs), lamp, bench, tufts. Materials `worldProp` / `worldFoliage`. |
| `instances.json` | Every placed prop: identity, kind, variant, scene position, yaw, scale, 400 m cell. Matrix = translate × rotateY(yaw) × scale. |
| `clutter-tufts.bin` | Edge-tuft candidates, float32 × 4 (x, z, yaw, scale); runtime rule in `world.json` (`clutter.tufts.rule`). |
| `collision.json` | Building hulls (scene x, z) and heights for camera collision. |
| `boundary.glb` | Soft world boundary ground (12 km square, 2 cm below the chunks). |
| `palettes.json` | Every palette slot (sRGB hex, names) for the recipe's season, plus all four seasons of the seasonal slots (slots 0…16, fixed order). |
| `materials.json` | Meaning of the vertex channels and flags, and every shader constant (palette lookup and variants, lawn mottling, sidewalk joints, windows, emissive, foliage value and sway, water ripple, fill, fog, contact shadow, cut-away, grade, bloom, character coat). `WorldShaders.metal` and `web/src/materials.js` implement exactly this. |
| `environment.json` | Location and timezone; resolved light states for named moments (`golden`, `noon`: sun direction, colors, intensities (direct sun fades in over 0–2° elevation), exposure, fog, fill, lit windows, season, sky image); weather (clear); fog policy; the full time-of-day tables (keys interpolate chronologically between the day's anchor crossings); and `experience`: the no-character defaults (composed postcards with scores and reasons, the aerial diorama fit, motion bounds for exploring and route flythrough; experience-v1 §3–4). |
| `sky-<state>.png` | Equirectangular sky (three.js orientation, row 0 = zenith). |
| `profiles/*.json` | The exact source profiles and tables used (provenance). `display.json` is the shared display policy (render scale by device heat, pausing when hidden). |

## Vertex channels (glTF application-specific attributes)

| Attribute | Type | Meaning |
|---|---|---|
| `_PAINT` | float32 VEC4 | palette slot, shade, flags (glass 1, emissive 2, lawn 4, sidewalk 8, road 16, variant-of-4 32, variant-of-2 64, distance fade 128), sway weight |
| `_EXTRA` | float32 VEC4 | baked AO, stable seed (lit windows), meters along a path, meters across |
| `_FEATURE` | uint16/uint32 SCALAR | index into the chunk's `scene.json` features (65535 = none) |

A renderer that can't read these must reject the package rather than draw the fallback materials.

## Guarantees (tested)
- Two exports of the same inputs are byte-identical.
- Every chunk vertex is within 1 cm of the generator's (measured worst: 0.015 mm); every instance within 1 cm (0.07 mm); identities, ranges, paints and indices match the generator exactly; every instance has a prototype.
- A palette-only change (another season) changes `palettes.json` and the manifest's hashes, nothing else.

## Size (Sloan's Lake area B)
188 files, 47.7 MB uncompressed: lod0 258,769 triangles, lod1 100,197; 6,076 instances; 42,671 tuft candidates. Not yet compressed (meshopt or quantization would cut it several-fold before any web sharing).
