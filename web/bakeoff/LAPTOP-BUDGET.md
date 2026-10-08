# Laptop budget — shadow and colour round

Measured in headed Chrome on the GPU named below, at the unchanged calibration portrait viewport. Warmed 2.5 s then sampled 10 s per capture (capture-once.mjs); frame intervals include scheduling/display pacing. GPU timer values are reported only when the browser exposes the extension. These are not phone timings or a thermal qualification.

No separate laptop, hero or standard numeric allocations are filed. Reference floor limits are 400,000 main triangles, 150,000 shadow triangles, 100 main draws (R device-tier clarification; visual-v2 §8.1). Count every pass; texture allocation limit is unfiled.

| View | Frame mean / p95 ms | GPU mean / p95 ms | Main tri / draws | Shadow tri / draws | Post tri / draws | All tri / draws | Content / targets / MSAA MiB | Floor |
|---|---|---|---|---|---|---|---|---|
| sloans | 10.00 / 10.94 | 1.67 / 1.75 | 347,177 / 99 | 5,008 / 17 | 1 / 1 | 352,186 / 117 | 34.00 / 34.61 / 10.44 | PASS |
| lakeview | 10.00 / 10.66 | 1.44 / 1.51 | 265,310 / 81 | 67,190 / 81 | 1 / 1 | 332,501 / 163 | 32.00 / 35.48 / 13.93 | PASS |

GPU: ANGLE (Apple, ANGLE Metal Renderer: Apple M1 Max, Unspecified Version). Texture totals exclude the default framebuffer, driver padding and CPU copies (budget.js allocation ledger).

## Every active effect and measured pass cost

| Effect | Sloan main tri/draw; shadow tri/draw | Lakeview main tri/draw; shadow tri/draw | Resource / rule |
|---|---|---|---|
| opaque world | 127,747/48; 2,566/8 | 212,186/47; 62,880/64 | Exported buildings, lawns, roads, walks, existing details, shrubs and props; shared matte key/fill + existing AO in these draws; palette 0.0039 MiB. |
| foliage | 84,741/40; 2,442/9 | 27,728/28; 2,310/14 | P2 species layouts + date-derived colours; shared instancing, no leaf textures. |
| tufts | 2,268/1; 0/0 | 3,600/1; 0/0 | Existing export grass accents; no shadow pass. |
| water | 309/6; 0/0 | 0/0; 0/0 | Lake gradient, normal ripples, pigment-preserving sky-luminance reflection and physical sun response in the same water draws; 2 MiB R16F shore field; shares sky texture. |
| facade details | 984/2; 0/0 | 19,812/4; 2,000/3 | Pack bays, stoops, cornices and eligible fences; courses/tones in opaque-world shader, no additional texture. |
| DEM | 129,144/1; 0/0 | 0/0; 0/0 | Real 3DEP mountain grid; contrast/size extinction gate in the same pass, no shadow draw. |
| sky/composite | 1,984/1; 0/0 | 1,984/1; 0/0 | 32 MiB float procedural sky gradient/cumulus; shared single exposure/saturation/luminance curve in post (1 triangle/1 draw). |

Homogeneous airlight is a single material fog mix; DEM uses its one explicit gated mix and reflected sky bypasses re-fog. No extra haze pass. Soft shadow-map work is included above, with its allocation in the target texture ledger; MSAA is included separately. Per-effect GPU milliseconds are not measured.

Laptop-only effects: none are selected by a laptop flag. All effects currently run on every named tier; portability is not phone qualification. Both floor views must satisfy all three geometry caps; failing shadows cannot be hidden by main-view headroom.

Hero = iPhone 15 Pro+, standard = 14–15, floor = 12–13. Phone-budget JSON lists actual counts for all three, without invented hero/standard or texture ceilings.

Sources: evidence/candidate/*.json, evidence/phone-budget.json, main.js, budget.js, data/p2-crowns.json, data/facade-values.json, data/facade-mechanics.json, and the pack-key table in OVERNIGHT-SOURCES.md.
