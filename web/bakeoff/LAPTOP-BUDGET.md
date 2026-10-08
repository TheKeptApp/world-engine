# Laptop budget — overnight A2

Measured in headed Chrome on the GPU named below, at the unchanged calibration portrait viewport. Warmed 2.5 s then sampled 10 s per capture (capture-once.mjs); frame intervals include scheduling/display pacing. GPU timer values are reported only when the browser exposes the extension. These are not phone timings or a thermal qualification.

No separate laptop, hero or standard numeric allocations are filed. Reference floor limits are 400,000 main triangles, 150,000 shadow triangles, 100 main draws (R device-tier clarification; visual-v2 §8.1). Count every pass; texture allocation limit is unfiled.

| View | Frame mean / p95 ms | GPU mean / p95 ms | Main tri / draws | Shadow tri / draws | Post tri / draws | All tri / draws | Content / targets / MSAA MiB | Floor |
|---|---|---|---|---|---|---|---|---|
| sloans | 10.01 / 11.36 | 2.08 / 3.22 | 347,177 / 99 | 245,154 / 70 | 1 / 1 | 592,332 / 170 | 34.00 / 34.61 / 10.44 | FAIL |
| lakeview | 11.69 / 20.01 | 2.00 / 3.18 | 265,310 / 81 | 322,586 / 155 | 1 / 1 | 587,897 / 237 | 32.00 / 35.48 / 13.93 | FAIL |

GPU: ANGLE (Apple, ANGLE Metal Renderer: Apple M1 Max, Unspecified Version). Texture totals exclude the default framebuffer, driver padding and CPU copies (budget.js allocation ledger).

## Every active effect and measured pass cost

| Effect | Sloan main tri/draw; shadow tri/draw | Lakeview main tri/draw; shadow tri/draw | Resource / rule |
|---|---|---|---|
| opaque world | 127,747/48; 179,172/41 | 212,186/47; 237,617/87 | Exported buildings, lawns, roads, walks, existing details, shrubs and props; shared matte key/fill + existing AO in these draws; palette 0.0039 MiB. |
| foliage | 84,741/40; 64,434/28 | 27,728/28; 58,677/62 | P2 species layouts + date-derived colours; shared instancing, no leaf textures. |
| tufts | 2,268/1; 0/0 | 3,600/1; 0/0 | Existing export grass accents; no shadow pass. |
| water | 309/6; 0/0 | 0/0; 0/0 | Lake gradient, normal ripples, Fresnel sky reflection and physical sun response in the same water draws; 2 MiB R16F shore field; shares sky texture. |
| facade details | 984/2; 1,548/1 | 19,812/4; 26,292/6 | Pack bays, stoops, cornices and eligible fences; courses/tones in opaque-world shader, no additional texture. |
| DEM | 129,144/1; 0/0 | 0/0; 0/0 | Real 3DEP mountain grid; contrast/size extinction gate in the same pass, no shadow draw. |
| sky/composite | 1,984/1; 0/0 | 1,984/1; 0/0 | 32 MiB float procedural sky gradient/cumulus; shared single exposure/saturation/luminance curve in post (1 triangle/1 draw). |

Homogeneous airlight is a single material fog mix; DEM uses its one explicit gated mix and reflected sky bypasses re-fog. No extra haze pass. Soft shadow-map work is included above, with its allocation in the target texture ledger; MSAA is included separately. Per-effect GPU milliseconds are not measured.

Laptop-only effects: none are selected by a laptop flag. All effects currently run on every named tier; portability is not phone qualification. Both floor views must satisfy all three geometry caps; failing shadows cannot be hidden by main-view headroom.

Hero = iPhone 15 Pro+, standard = 14–15, floor = 12–13. Phone-budget JSON lists actual counts for all three, without invented hero/standard or texture ceilings.

Sources: evidence/candidate/*.json, evidence/phone-budget.json, main.js, budget.js, data/p2-crowns.json, data/facade-values.json, data/facade-mechanics.json, and the pack-key table in OVERNIGHT-SOURCES.md.
