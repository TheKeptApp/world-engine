# Lakeview 600 m blank-field diagnosis

## Finding

The abrupt populated-area edge is the end of the exported detailed grid. Beyond it the web viewer draws the shared plain lawn boundary, not surrounding city geometry. Context data exists, but this export/load path does not turn it into renderable context-ring geometry. This is a general web package/integration coverage limitation, not evidence of a real green field, missing downloaded core chunks, shader failure, or a camera clipping fault. No fix, renderer edit, new capture, or grade was made for this investigation.

Evidence is the existing [post-near-plane manifest](../lookloop/captures/a7-web-crown-all-near-fix/manifest.json), captured at `158011565e913d36e1cac1d3a007fd5c0fcb19f7`, delivered in `c8c361d`, and [A3's blind review](crown-v3-ladder-scores.md). The available generated packages from that capture worktree were inspected read-only, alongside the source path below.

## Package and source checks

| Check | Lakeview | Sloan's Lake |
|---|---|---|
| Detailed extent | 1,000 × 1,000 m; x/z −500…500 | 1,600 × 1,200 m; x −800…800, z −600…600 |
| Exported 200 m grid | All 25 cells, 5 × 5 | All 48 cells, 8 × 6 |
| Listed package files | 211/211 present, byte size and SHA-256 match | 281/281 present, byte size and SHA-256 match |
| Renderable context-ring files | None | None |
| Boundary GLB | 1,536 bytes | 1,536 bytes |

Both boundary files have SHA-256 `599604ca810d896981c03da7a7d8ef75b508fa8d767fd086f6168d7106e28951`.

The causal chain is explicit in the source:

1. [AreaLoader.loadFeatures](../../Sources/WorldMap/AreaManifest.swift) loads layer `all`, not `context`. [WorldBuild](../../Sources/WorldGen/WorldBuild.swift) passes these features to the detailed scene generator.
2. [SceneGenerator](../../Sources/WorldGen/SceneGenerator.swift), lines 511–517, creates a **12 km square**, lawn-painted boundary ground **2 cm below** the detailed ground. These are existing implementation values, not a proposed adjustment.
3. [WorldPackage](../../Sources/WorldPackage/WorldPackage.swift) exports detailed chunks and `boundary.glb`. Listing a context source in `world.json.sources` records provenance; it does not export context geometry. Neither audited package has context geometry in its file table.
4. [Web WorldScene.load](../../web/src/world.js) awaits the entire manifest chunk pool at LOD0, adds every chunk, and loads the boundary. It does not ingest the raw context source or build its ring. The capture readiness path therefore cannot cure the missing coverage by waiting longer.
5. Native uses a separate [World.startContext](../../Sources/WorldEngine/World+Context.swift) / `ContextRing.build` path. Its presence does not imply equivalent web-package consumption.

Both area manifests include context sources covering roughly a 7 km box. Lakeview's recorded context source is 23,102,065 bytes, SHA-256 `068d3bf1e7251f4ab7cd41bf678c1096eb7977c7856e1d2205f3c3b0479808b3`; Sloan's is 19,332,840 bytes, SHA-256 `8338043f81a55299cc66fddd5459ce5fc48a3966d5e5973a0f9c52157c986e62`. This rules out absence of a context dataset as the immediate cause; it does **not** certify complete context features or large-water coverage. [Context-rings documentation, “Reading it” and “Status”](../data/context-rings.md) describes the layer distinction and outstanding source limitations. Export `--focus` selects detail and `--margin` belongs to the semantic map; neither supplies these missing renderable context cells.

## Why Lakeview is much more exposed; Sloan's has the same edge

Both existing frames are 1,005 × 565, at 600 m, west-facing heading 270°, pitch-down 45°, vertical FOV 50°, UTC `2026-10-15T20:30:00Z`, fixed calibration exposure. Near/far are 150/150,000 m. Recorded local camera positions and grid edges explain the image without changing those settings:

| Ground projection at image centre column | Lakeview | Sloan's Lake |
|---|---|---|
| Camera local x | −58.8745 m | 479.9372 m |
| Western detailed boundary x | −500 m | −800 m |
| Distance west to boundary | 441.1255 m | 1,279.9372 m |
| Centre ground ray x, 600 m west of eye | −658.8745 m, outside core | −120.0628 m, inside core |
| Predicted boundary pixel row, from top | 374.95 | 63.39 |

For horizontal westward ground distance `d`, height `h = 600`, and the recorded pitch/FOV, `ndcY = (d − h) / ((d + h) tan(25°))`; pixel row is `565(1 − ndcY)/2`. This is the ground seam at the centre column; roofs project above it. The top ground ray reaches about 1,648 m west, beyond both grids. Lakeview's boundary depth is about 736 m, comfortably inside its clipping interval. The finite core extent, not the far plane or the near-plane correction, determines the seam.

Visual inspection confirms Lakeview's blank upper field and roof edge near the predicted seam. Sloan's has the same blank background above the far-shore buildings near row 63, plus visible side cutoffs; its larger core and different eye position keep the lake and much more detailed ground in the frame. Therefore this is **not Lakeview-specific**. Sloan's mountain backdrop is distant terrain, not nearby city-ring coverage.

Frames inspected: [Lakeview OFF 600 m](../lookloop/captures/a7-web-crown-all-near-fix/lakeview-foliage-off-crown-off.png) and [Sloan's OFF 600 m](../lookloop/captures/a7-web-crown-all-near-fix/sloans-600-foliage-off-crown-off-fresh.png). No additional rendering was necessary. The missing piece is context export/consumption, which remains unimplemented by this read-only diagnosis.

## Requested review copies

Six byte-identical copies were placed in `~/Desktop/extra-review/`; originals were not modified:

| Copy | Original |
|---|---|
| `a-target-06-sloans.png` | `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` |
| `b-off-40m.png` | `sloans-40-foliage-off-crown-off-fresh.png` |
| `c-v3-40m.png` | `sloans-40-foliage-off-crown-off-v3-standard.png` |
| `d-off-150m.png` | `sloans-150-foliage-off-crown-off-fresh.png` |
| `e-v3-150m.png` | `sloans-150-foliage-off-crown-off-v3-standard.png` |
| `f-off-600m-lake.png` | `sloans-600-foliage-off-crown-off-fresh.png` |

Render originals are in `docs/lookloop/captures/a7-web-crown-all-near-fix/`. The target mock is gitignored and absent from the isolated worktree: the exact filed copy in the primary checkout was used and its SHA-256 matched the read-only design drop (`e17e3150b0cd36d66cc47ed8c342cf414437056ab1a930fa4cd34a704cec2a60`). All six copy hashes were checked against their unchanged sources. The Desktop copies are review artifacts, not newly committed frames.

Used: docs/data/context-rings.md §Reading it; capture manifest and package/source checks above. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: read-only diagnosis; no fix, new capture, or scoring.
