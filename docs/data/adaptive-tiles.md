# Adaptive exporter tiles — A1 → A4, 8 October 2026

Implementation: `Sources/WorldPackage/AdaptiveTilePacker.swift`; CLI: `Sources/worldbake/main.swift` → `worldbake pack <existing-package-directory> <new-output-directory>`. This is an export-stage packer over the exact exported GLBs, not a new generator or renderer. Destination must not exist. Example after the shared load/lock admission:

```
.build/debug/worldbake pack Generated/package/AREA Generated/adaptive/AREA
```

It accepts any unpacked `worldengine.package/1` area with the exporter-controlled GLB subset. One fixed default policy for every area: ≤8,388,608 decoded attribute/index bytes per independently decoded leaf/LOD and ≤2,097,152 decoded bytes per primitive/upload part, ensuring any two leaves fit the 16,777,216-byte decoded queue. A separate conservative ≤2,097,152-byte whole-GLB cap remains; it is not used as a substitute for either decoded-byte check. Source: `docs/research-gpt/mobile-rendering-v1/streaming-design.md` §7, A4's `765a2d1` tile-packer.md/REPORT.md, and the explicit targets in `web/stream/targets.md` at `939d04f`. No per-tile triangle allowance is invented from the separate 400k whole-view limit.

## Deterministic rule and preservation

For an over-budget parent, split all LOD triangle references at the median along the widest X/Z centroid extent; ties use the other coordinate, then LOD, primitive and original triangle index. Recurse until both LODs meet byte budgets. Degenerate positions still terminate via stable index tie-breaks. A budget unable to hold one triangle plus metadata fails explicitly. Child IDs append the binary split path to the original parent ID.

Triangles are assigned whole, never clipped, simplified, moved or regenerated. The packer copies source vertex-channel bytes, winding, material JSON and node origin exactly. Vertex deduplication is local to each primitive/leaf; boundary vertices can be duplicated across leaves, but triangles are neither duplicated nor lost. Feature indices remain stable and scene vertex ranges are rebuilt. Source/generated feature metadata stays unchanged. Palettes, look/material files, environment, prototypes, instances, collision, map data and all other non-chunk files are copied byte-for-byte. Source file hashes must match the original manifest; new files receive new hashes.

## Consumer contract (A4 owns integration)

- `tileLayout.type = adaptive-budget-bvh/1` is an explicit required capability. Fixed-grid-only consumers must not silently treat these leaves as 200 m cells.
- Use each chunk's unique `id`, `lods`, `scene`, actual `bounds`, and `origin`. `index` is the original parent grid index and is **not unique**; `chunkSize`/`parentChunkSizeM` describe the parent grid, not a leaf extent. `parentID` provides lineage.
- Bounds enclose both LODs and may overlap because whole triangles can cross the split. Load by bounds, not by reconstructing a grid or clipping triangles again. Node translation stays at the original parent origin to avoid new floating-point error.
- `emptyLODs` explicitly lists valid empty geometry at that LOD. Skip decode/draw and count it as known empty coverage, not a missing tile; retain the normal independently selected detail policy. A4's strict decoder currently rejects an empty mesh, so its consumer must handle this metadata before decoding. Neither measured area produced empty LODs.
- `decodedBytes` is the exact attribute/index-array sum per LOD. `parts[lod]` lists primitive index, material, decoded bytes, triangle count and vertex count; `glbBytes[lod]` separately records encoded file size. Admission must still enforce the queue budget. The packer does not implement the viewer's LRU, release CPU arrays, schedule uploads, certify the 0.5 ms upload budget, or establish A16 performance.
- `replacementGroups` retains each 200 m parent's original LOD1 triangles as bounded `coarsePayloads`, separately hashed and indexed with actual bounds, decoded costs, primitive costs, GLB sizes and scene feature joins. Keep ALL parent coarse payloads until ALL required child LODs are ready, then replace the group atomically. Do not draw parent and children together. This preserves coarse coverage without duplicating houses; A4 owns implementing the switch.
- `featureOwnership` records a stable 100 m building cell, independent of child payload partitions: floor(source LOD0 feature bounding-box centre / 100 m), in the package's local east/north frame. Original feature identity and source-parent lineage are retained. Ground remains on the original 200 m parent grid; this does not impose a uniformly smaller world grid. Adaptive payloads may contain geometry from multiple logical cells.
- `world.json.tilePacking` contains source manifest SHA, budgets, per-leaf before/after bytes/triangles and counts. No wall-clock timestamp or random seed affects output.

## Verification and local handoff

The exact original input packages are A4's Sloan 48-tile export in the primary checkout's Generated/package/sloans-lake and Lakeview 25-tile export in web/stream/generated/lakeview-sheil-park. A4 source files are read-only. Verified outputs are in the A1 worktree's Generated/adaptive-targets/{sloans-lake,lakeview-sheil-park}; no existing package is overwritten and no A4 file is edited.

`Tools/regionkit/qa/adaptive_package.py` independently decodes every GLB, validates every manifest digest, checks scene feature ranges and child bounds, and compares per-parent/per-LOD multisets of triangle material, origin and all vertex bytes. It checks both byte limits and verifies non-chunk files are unchanged. Repeat packing is checked byte-for-byte. Results are saved in Data/quality/adaptive-tile-packing.json after completion. Focused Swift tests cover deterministic splits, exact channels/triangles, coincident centroids, explicit empty LODs and impossible budgets. No look or water artifact fix is claimed.

### Independently audited before/after (full packages)

| Area | LOD | Tiles before → after | Files above 2 MiB before → after | Largest GLB after | Worst two decoded tiles before → after |
|---|---:|---:|---:|---:|---:|
| Sloan's Lake | 0 | 48 → 76 | 10 → 0 | 1,913,204 B | 10,399,800 → 3,756,466 B |
| Sloan's Lake | 1 | 48 → 76 | 0 → 0 | 1,080,580 B | 2,512,230 → 2,109,800 B |
| Lakeview | 0 | 25 → 114 | 25 → 0 | 2,094,388 B | 17,332,572 → 4,176,512 B |
| Lakeview | 1 | 25 → 114 | 0 → 0 | 398,956 B | 2,595,662 → 766,250 B |

Independent triangle totals are unchanged: Sloan 451,997 / 133,249 (LOD0/1); Lakeview 1,370,373 / 164,560. These are package totals, not simultaneous visible triangles or a whole-view performance pass. All 73 map/package tests passed, including four packer tests. Independent full-package triangle/channel/feature audits and byte-identical repeat packing passed for both areas after A4 released the lock. No A4 file was changed. Merge remains stopped by contradictory current delivery wording in the tracker; R's conditional additive-only approval does not permit silently revising that wording.

### Alignment to A4 939d04f

R explicitly requested the decoded targets. The new implementation checks leaf and primitive decoded bytes separately, publishes their costs, and adds bounded coarse replacement payloads and immutable building-cell ownership. The conservative whole-file cap remains. Updated Swift tests exercise primitive caps independently of file-size caps, coarse triangle preservation, replacement-group membership and ownership invariance under different split budgets. Updated full-data audit checks the same costs and parent coarse triangle multiset; it also computes the worst two leaves using each leaf's maximum LOD decoded cost.

Verification completed successfully under the heavy wrapper (load admission 4.67; disk above 8 GB). Data/quality/adaptive-tile-packing.json records targetCommit 939d04f and PASS for both complete areas. Outputs are Generated/adaptive-targets/{sloans-lake,lakeview-sheil-park}. The independent audit also verified all 48 Sloan and 25 Lakeview coarse replacement payloads exactly preserve original LOD1 coverage.

### Claim reconciliation — R review, 8 October

A4's original Lakeview LOD0 export has 25 tiles; its largest two decoded attribute/index-array payloads sum to 17,332,572 bytes (`web/stream/tile-packer.md`). The earlier A1 packed output has 114 leaves; its exporter-reported largest pair is 4,176,512 bytes. These use the same measure but different partitions of the complete source package: the smaller figure is from the new packer, not a new memory definition or a partial source export. Neither figure measures total CPU/GPU residency. The independent audit has now traversed every original and packed GLB in both areas and verified exact triangle/channel preservation. It reproduces both figures, including the 4,176,512-byte worst pair when allowing each leaf its largest LOD. This passes the 16,777,216-byte decoded queue target; all leaves and primitive parts also meet their separate targets. It does not certify viewer residency, GPU uploads or frame time.
