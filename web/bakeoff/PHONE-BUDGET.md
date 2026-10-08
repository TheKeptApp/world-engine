> Historical phone-budget round. Current shadow/colour counts and all-pass floor results: [LAPTOP-BUDGET.md](LAPTOP-BUDGET.md), `evidence/phone-budget.json`, [SHADOW-COLOUR-REPORT.md](SHADOW-COLOUR-REPORT.md).

# Phone-budget audit

R's clarification (8 October): hero = 15 Pro+, standard = 14–15, floor = 12–13. Floor uses **400,000 main triangles, 150,000 shadow triangles, 100 main draws**. Every pass must be counted. Hero/standard numeric limits and texture limits are not filed. `visual-v2` §8.1 supplies the original separate main/shadow contract. We report main, shadow and post separately and reconcile their sum against the renderer's complete-frame counters; shadow work is never hidden in a main-only pass claim. Research proposals in `web-stack-v1` are not treated as owner-approved limits.

All three labels deliberately use the same code, effects, DPR 1 and existing phone-size compositions (390×585 Sloan, 390×780 Lakeview). They do not simulate different GPUs or native-resolution phone displays. This is a structural budget audit in headed laptop Chrome, not an iPhone benchmark, GPU millisecond measurement, thermal/sustained test or native iOS 26 qualification. No device installation occurred.

## Every active effect and its cost model

| Effect | Actual cost charged / source | Desktop-only? |
|---|---|---|
| Exported buildings, roofs, road, sidewalks, varied lots and static props | `main/opaque world`; shadow submissions separately charged. Original package batching/instancing and distance LOD. Matte palette lookup; calibration-v2 materials. | No intentional desktop-only effect; phone performance unverified. |
| Species crowns and branches | `main/foliage` plus `shadow/foliage`. Opaque vertex-colour geometry, no alpha layers. foliage-seasons-v1 crown descriptions/counts/holes; geometry radii derived because no numeric lobe sizes are supplied. | Same on every tier. |
| Near tufts | `main/tufts`; existing distance fade and nearest-200 cap. No shadows. | Same on every tier. |
| Real Front Range DEM | `main/DEM`, no shadow pass. Same USGS geometry and mountain-terrain-v1 rock material. Haze may obscure it but submitted work still counts. | Same on every tier. |
| Sky gradient and sparse cumulus | Background submission, one 2048×1024 RGBA32F texture: **32 MiB**, no mips. Procedural once at load; one lookup per background fragment. Calibration-v2 and weather-moments-v1. | Same on every tier; not claimed phone-qualified. |
| Sun + hemispheric fill, matte shading and vertex AO/contact tint | Included in main geometry shaders; no extra draw or texture beyond palette. Vertex AO is interpolated, not an SSAO pass. Calibration-v2 witness ratio and foliage pack contact darkening. | Same on every tier. |
| Soft sun shadows | All `shadow/*` submissions; 2048² shadow target(s), actual formats/bytes in allocation ledger; PCF filter applied to main receivers. | Same on every tier. |
| Shared exponential haze | One analytic extinction term within affected material shaders; no extra texture/draw. Exact lake pack **0.0008/m**, including DEM; unchanged for this frozen comparison; see merge-time pack arrival below. | Same on every tier. |
| Water shore-to-deep colour and shoreline darkening | `main/water`; 1024² RGBA8 shore field **4 MiB**. lake-winter-v1 colours/shore values. | Same on every tier. |
| Water ripples, sun glint and broken sky reflection | Same water draw: four analytic wave terms with derivative/distance fade, physical rough specular and analytic reflected-sky modulation. No mirror, SSR or reflection render target. water-surfaces-v1 mechanics, lake pack colour/roughness. | Same on every tier. |
| Exposure, ACES, saturation/contrast and output conversion | One fullscreen post composite; one shared grade, no repeated exposure/saturation. Actual scene colour/depth targets and MSAA renderbuffers separately recorded. | Same on every tier. |
| Antialiasing | Four-sample render-target attachment storage when allocated by the pinned renderer; resolved textures counted separately. Default browser framebuffer memory is excluded/unavailable. | Same on every tier. |

No bloom, SSAO, depth of field, volumetric clouds/rays, precipitation, dynamic local lights, animated characters or transparent leaf cards are active. Their cost is zero in this run. The capture/allocation instrumentation is a **desktop diagnostic harness**, not a runtime tier feature. Per-effect GPU milliseconds remain unmeasured: draw counts and allocation bytes cannot establish shader time or fill-rate cost.

The allocation ledger records the pinned WebGL backend's actual texture creation dimensions, format, mip levels and destruction; renderbuffer storage includes samples. It deduplicates live resources. Logical byte totals exclude driver padding, browser/default framebuffer, CPU copies and process overhead. It aborts the report on unknown formats. Texture and target totals have **no filed pass/fail limit**. Complete per-effect draws/triangles and each allocation are in the candidate JSONs; `evidence/phone-budget.json` provides reconciled totals and tier status.

## Measured result

All three labels produced byte-identical frozen images and identical geometry/memory counts. Sloan completed before Lakeview. No Lakeview tuning. Main, shadow and post totals reconcile exactly with complete-frame renderer counters; zero unknown allocation formats.

| View (hero / standard / floor identical) | Main tris / draws | Shadow tris / draws | Post tris / draws | All tris / draws | Floor geometry |
|---|---:|---:|---:|---:|---|
| sloans | 382,040 / 91 | 276,536 / 67 | 1 / 1 | 658,577 / 159 | **FAIL: shadows** |
| lakeview | 262,138 / 67 | 322,277 / 126 | 1 / 1 | 584,416 / 194 | **FAIL: shadows** |

Both main views pass 400k triangles / 100 draws. Both shadow passes exceed 150k triangles, even before foliage is included: opaque-world shadows alone are 179,172 Sloan and 237,617 Lakeview. No pass is excluded from totals. Hero/standard acceptance remains unset.

| View | Content textures MiB | Target textures MiB | MSAA renderbuffers MiB | Accounted sum MiB |
|---|---:|---:|---:|---:|
| sloans | 36.004 | 34.611 | 10.444 | 81.059 |
| lakeview | 32.004 | 35.481 | 13.925 | 81.410 |

Shadow colour + depth consume 32 MiB per view. The scene colour/depth pair consumes 2.611 MiB Sloan / 3.481 MiB Lakeview, plus 10.444 / 13.925 MiB MSAA storage. Sky consumes 32 MiB, palette 0.00390625 MiB, shoreline adds 4 MiB only when water is present. No filed texture ceiling: **ungraded**, not a memory pass.

| Actual effect submission category | Sloan triangles / draws | Lakeview triangles / draws |
|---|---:|---:|
| main/sky/composite | 1,984 / 1 | 1,984 / 1 |
| shadow/opaque world | 179,172 / 41 | 237,617 / 87 |
| shadow/foliage | 97,364 / 26 | 84,660 / 39 |
| main/opaque world | 127,747 / 48 | 212,186 / 47 |
| main/water | 309 / 6 | 0 / 0 |
| main/foliage | 120,588 / 34 | 44,368 / 18 |
| main/tufts | 2,268 / 1 | 3,600 / 1 |
| main/DEM | 129,144 / 1 | 0 / 0 |
| post/sky/composite | 1 / 1 | 1 / 1 |

The separate foliage pack proposal of 35k main triangles / 12 draws is also exceeded (120,588 / 34 Sloan; 44,368 / 18 Lakeview). It is carved from, not added to, the world budget.

### Look result and remaining gap

Mean fixed-box ΔE76 is unchanged: Sloan **16.1288 → 16.1288**, Lakeview **23.0906 → 23.0906**. Neither moves less than the other this time. Those boxes measure colour medians, not silhouette topology: Sloan has only sky and sidewalk boxes, and Lakeview’s crown box does not reliably overlap the visible near crown. The unchanged medians cannot prove crown quality. In the preceding sky revision, sky was one of two Sloan regions but one of six Lakeview regions, so the means also weighted that improvement differently.

The new crowns are more irregular and anisotropic, with fewer polygon submissions (all-pass reductions **54.4% Sloan, 45.3% Lakeview** versus previous A2), but remain chunky and distant low-detail lobes are visibly angular. This is not a visual-gate pass. The bake-off merge preserves those limitations as reviewable evidence; it does not promote the implementation into the production viewer. Haze remains unchanged.

Browser error, policy, sky-transfer, hash consistency, tier image identity and pass accounting checks passed. Laptop timing was about 100 fps Sloan / 92–95 fps Lakeview under heavy shared-system load; it cannot qualify any iPhone tier. Phone GPU timings, sustained thermals and the full art gate remain unverified.

### Merge-time pack arrival

Main advanced to `6ce875f` during this audit and filed `haze-visibility-v1`. Rebase was clean; every rendering-input hash remained identical. This particular crown/budget comparison deliberately retains its already-frozen 0.0008/m baseline. The newly filed pack supersedes that coefficient for the next atmosphere integration; it is **not consumed by this run**, and the old coefficient must not be represented as the current production target. No new haze comparison or visibility-conformance claim is made here.

Haze follow-up: the migration requested by R is now implemented; see HAZE-REPORT.md. This document preserves the preceding crown/budget round as history. Its geometry and memory counts remain unchanged in the haze run, while its old extinction and colour scores are superseded.
