# Native Batch 1 — memory, shadow count, streaming slice 1, extent spec (5A, 9 Oct 2026)

No look, shader or palette change. Phone: iPhone 14 Pro (R's, USB, approved in the Batch 1 prompt). Raw logs, frames and SVG charts stay local (`scratchpad/{b1,b1cap,pan,poses}`); the numbers are here.

## 1. Memory (gate: ≥10 % below 600 MiB = ≤540 MiB, same-pose frames max 1/255)

Sloan's street view (`-preset v2-01`, `-memreport`), phone, MiB:

| Category | Before | After | How measured |
|---|---:|---:|---|
| Process footprint (phys_footprint) | **603.6** | **510.3** | task_vm_info |
| GPU allocations, total | 383.4 | 389.7 | MTLDevice.currentAllocatedSize |
| — world geometry (vertex/index buffers) | 175.9 | 175.9 | uploaded bytes |
| — of which merged building tiles (duplicate copies at mid/far/skyline) | 67.4 | 67.4 | |
| — RealityKit render targets, shadow maps, IBL, post textures (not separable without a GPU capture) | 207.5 | 213.8 | GPU total − geometry |
| CPU copies of generated geometry kept after upload | **92.3** | **0** | MeshBuffers arrays |
| Other (RealityKit/CPU heap, code, OSM-derived data) | 127.5 | 120.1 | remainder |

Fix: the CPU copies of chunk, building-cell and boundary meshes are freed once uploaded (`World.releaseLoadOnlyGeometry`; nothing reads them afterwards; `-diag keepLoadGeometry` keeps them for A/B). **Gate: met at the street view (510 MiB, 15 % below).** Same-pose frames, 7 ladder views vs Batch 0: five byte-identical, Sloan 150 m max 1/255 (39 bytes), Sloan 600 m max 2/255 — a same-build repeat also gives max 2 (run noise); Batch 0 frame vs Batch 1 repeat max 1/255 (29 bytes). **Gap:** Lakeview is still at the floor: 598–608 MiB at its ladder poses (geometry 355 MiB); Sloan's/Wilmette ladder poses 397–411 MiB. The unstreamed pan (below) peaks at 616 MiB while LOD rebuilds run.

## 2. Shadow pass per ladder view (analytic; floor ≤150k)

RealityKit exposes no shadow counters, cascade count or map size. Model (`World.shadowEstimate`, logged on every VIEWSHOT): the shadow map covers the view frustum from the near plane to the applied range (120 m, approved reach unchanged), seen along the sun; a caster is drawn when its bounds overlap that region across the light and it is not wholly beyond the receivers. Casters: raised chunk geometry, building cells/tiles at their active level, instanced trees/bushes/props (an instanced batch spans the whole world, so all its instances are submitted). Flat ground, water, context ring, tufts and sky do not cast. One map; RealityKit's cascades redraw shared casters per cascade (up to × cascade count, not exposed).

| View | Main tris/draws | Shadow tris/draws (one map) | Split (tris/draws) | Floor 150k |
|---|---:|---:|---|---|
| Sloan 40 m | 312,880/53 | **224,435/58** | foliage 147,807/42, buildings 55,508/14, chunks 21,120/2 | fail ×1.5 |
| Sloan 150 m | 333,744/50 | **184,893/46** | foliage 119,665/35, buildings 44,108/9, chunks 21,120/2 | fail ×1.2 |
| Sloan 600 m | 228,013/43 | 0/0 | no receiver within 120 m | pass |
| Lakeview 40 m | 295,759/56 | **244,767/63** | chunks 108,282/5, buildings 86,941/18, foliage 49,544/40 | fail ×1.6 |
| Lakeview 150 m | 271,763/48 | **214,423/44** | chunks 108,282/5, buildings 63,965/11, foliage 42,176/28 | fail ×1.4 |
| Lakeview 600 m | 194,160/35 | 0/0 | as Sloan 600 m | pass |
| Wilmette 600 m | 235,885/36 | 65,802/8 | foliage 52,064/7, chunks 13,738/1 | pass |

Web for comparison: Sloan shadow 560k → 26k with finite-wind culling (exact); saved web counters 5,008/67,190. Native lacks per-cell instancing, so whole-world tree batches dominate Sloan's; Lakeview's raised chunk tiles (800 m) dominate there. **GPU ms on the phone, per pose (Metal HUD, 10 s windows): 14.6–15.1 ms median at 60 fps everywhere** — unpinned clock (iOS slows the GPU to just fit 16.7 ms), so it shows no headroom, not cost; a pinned capture needs R in Xcode (steps in handoffs). Memory per pose in §1.

## 3. Streaming slice 1 (default OFF: `-diag streamCells`)

`Sources/WorldEngine/CellStreaming.swift`: building cells' near level (34 MiB of Sloan's GPU geometry) lives in a temporary disk cache written at load; cells within 90 m of the camera are loaded, beyond 140 m released, under a hard 16 MiB cap; a cell draws its mid level until its near mesh is complete (atomic switch, coarse kept until fine is ready). A4-review rules: the whole upload step is timed per frame (not one API call); one job at a time; a fixed pool of 14 mesh slots (buffers + resource, created at load, 16.6 MiB incl. staging) is reused, so nothing is allocated, abandoned or left undisposed while streaming; release returns a slot only after its entity stops drawing it; a cancelled job returns its slot at once. Copies go CPU → shared staging buffer in slices, then one GPU blit (`LowLevelMesh.replace(bufferIndex:using:)`) — CPU writes into `LowLevelMesh` buffers cost in proportion to the whole buffer (1.1 ms per access measured), so they are avoided.

Scripted pan (`-mode route -pantest`): lawnmower rows 250 m apart over the whole 1,600 × 1,200 m package at street eye height, 30 m/s, 8.5 km, phone:

| Pan time (s) | Off: footprint MiB | On: footprint MiB |
|---:|---:|---:|
| 0–30 | 467–616 | 438–447 |
| 30–60 | 533–615 | 438–450 |
| 60–90 | 538–576 | 446–459 |
| 90–120 | 539–547 | 452–459 |
| 120–150 | 543–548 | 453–459 |
| 150–180 | 540–555 | 461–482 |
| 180–210 | 553–556 | 471–483 |
| 210–240 | 550–602 | 476–481 |
| 240–270 | 550–569 | 471–483 |
| 270–300 | 542–569 | 473–483 |

All 53 streamed cells loaded and released (reads 53, failures 0, cancelled 0; resident peak 7.1 MiB). **Upload gate: 158 of 159 upload frames ≤0.5 ms** (copy ≤0.21 ms, replace ≤0.02, parts ≤0.25, attach ≤0.26 ms, each in its own frame); **one outlier 1.07 ms** (a GPU copy frame; command-buffer creation/commit) — gap, not yet closed. Frame time (worst frame per second): off median/p95/max 17.6/44.3/49.3 ms, on 21.0/48.6/54.6 ms; spikes occur in both runs (LOD rebuilds while panning at 30 m/s), not from uploads. Near-view identity under streaming is not proven (a cell shows mid until its near mesh arrives), hence default OFF. Memory rises ~40 MiB over the on-run (481 vs 438 MiB) — not attributed yet.

## 4. Extent spec — "move fully around Sloan's Lake"

Lake (OSM relation "Sloan's Lake"), from the area centre 39.7494,−105.0445: x −733…663 m, y −592…363 m. **Target box = lake + 400 m: S 39.740489, N 39.756254, W −105.057738, E −105.032080 (2,196 × 1,755 m, 3.85 km², ×2.01 the current package).** Current package ±800 × ±600 m. **Missing data strips: west 333 m, east 263 m, south 392 m, north 163 m** (Batch 0 omitted north). Grid: 200 m chunks, 12 × 9 = 108 (current 48).

Detail rings (general rule, any lake/park): (1) shoreline band — everything within 150 m of the water polygon plus all paths around it: full street detail (current focus-box level); (2) neighbourhood — the rest of the box: street detail at mid level, near level streamed; (3) context ring beyond the box to ~3 km: coarse context (existing ring), no streaming. Expected sizes from Sloan's measurements: GPU geometry 3.7 MiB per 200 m chunk on average (176 MiB / 48), far + skyline only ~0.9 MiB per chunk, near level ~0.7 MiB per chunk inside the focus area; raw input ~1.9 MB per chunk (89 MB / 48). Per chunk (Sloan's split): ground 0.36 MiB, mid buildings + mid tiles 1.1 MiB, far + skyline 0.9 MiB, near 0.7 MiB. All-resident full extent ≈ 354 MiB geometry → ~600 MiB footprint (Lakeview today: at the floor), so streaming is required. Resident at once (estimate): ground 108 × 0.36 = 39 + far/skyline 108 × 0.9 = 97 + mid for the ~12 chunks within 300 m × 1.1 = 13 + near ≤16 MiB cap ≈ **165 MiB geometry**, about Sloan's today (176 MiB → 510 MiB footprint), i.e. est. ~500 MiB footprint; streaming mid as well as near brings far/skyline + ground (136 MiB) to the main fixed cost. Data lane needs: OSM (out body) and building heights/roofs for the four strips; context ring re-cut around the new box; terrain if any.

## Recommendation for Batch 2
Roam the full extent with mid- and near-level streaming on the existing generator (per-chunk disk cache, same slot pool), plus per-cell tree instancing so shadow and main passes only draw nearby trees; the shadow and far-parent ports are needed (shadow 185–245k at 40/150 m fails the floor; Lakeview memory at the floor).

Used: docs/perf/native-ladder-batch0.md; docs/review/a4-streaming-review-2026-10-08.md §§3–4,9; docs/data/adaptive-tiles.md consumer contract; docs/tracking/restart-5A.md budget table. Mock: none (no look change). Deviation: shadow counts analytic (no RealityKit counters); one 1.07 ms upload frame; streaming default OFF (near identity unproven); Lakeview memory at the floor.
