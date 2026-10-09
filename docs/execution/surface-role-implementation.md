# Opt-in surface-role companion — A4 implementation

Implements the design at `989f3c9`, [surface-role-attribute.md](surface-role-attribute.md), on the locally available current source `243a41f`. R explicitly authorized these P2-owned semantic callsite edits. No rendering/look/water/palette-consumer changes. This is exporter delivery, not a palette trial or a score.

## Contract and ownership

`worldbake export AREA PACKAGE --date ISO --surface-roles-to EXTERNAL-DIR` enables capture. The option defaults to nil. Companion destinations inside or enclosing the package (including existing symlink aliases) are refused. The exporter writes only `index.json`, `triangles.u16le`, and a companion `LICENSE-DATA.md` outside the package. Package summary counts remain legacy-only. Native builds never enable the task-local recorder; native paint packing, hash/equality, mesh rendering channels and geometry remain unchanged.

One little-endian UInt16 per final indexed triangle: role bits 0–2 (`other=0, roof=1, wall=2, trim=3, door=4`); material class bits 3–7; material provenance bits 8–9; **independent colour provenance bits 10–11**; bits 12–15 reserved zero. Both provenance channels use `none=0, mapped_tag=1, family_inference=2`. This uses two of the design's reserved bits to meet R's mapped `roof:colour` fixture without treating colour as physical material evidence. No family-to-material rule is invented: material provenance is mapped only for an explicitly supported `building:material` or `roof:material`; otherwise class unknown/provenance none. Raw source tags remain in the companion's `featureSources`. The fixed material table is embedded in the index; unsupported source values stay unknown.

Building semantic paints are assigned where the generator knows wall, roof, trim and door roles. Shading copies preserve these words. Canopy covering is roof even when it uses trim colour; gable panels are wall, facade half-timber/sign bands trim. Glass, foundations, stairs, chimney bodies and unannotated nonbuilding/prototype geometry are conservatively other/unknown/none. No colour/normal-based role recovery. Per-vertex words survive mesh append/partition/repaint (including flat roof caps); final triangle corners must agree or export fails rather than inventing a role. Every GLB primitive (including other/unknown prototypes/boundary) has an aligned payload slice. Index binds SHA-256 of exact `world.json`, each GLB and payload, with mesh/primitive/count/offset/LOD identifiers. Consumers must reject hash/schema/count mismatches. **Repacking changes this binding: regenerate/remap a companion before consuming it with packed tiles.** Adaptive companion remapping is not implemented by this exporter option.

P2 review after the credit reset: semantic tagging in the three building generator files, especially new geometry helpers added later. A1: future adaptive-packer annotation remapping; source material normalization remains explicit. A2: optional reader and mismatch rejection, per-triangle GPU role handling. 5A/native: no changes, ignore external companion. Nothing else is scheduled or waits for a guessed reset time.

## Validation and outputs

**PASS:** final 87 existing map/tunnel/road-marking/map-layer tests plus 3 new fixtures: 90/90, 98.996 s, heavy admission load 5.13. Reproduced all 20 filed before/after road/static hashes and all 17 input hashes unchanged, admission load 4.64. Fresh clean-source baseline `243a41f` and current exporter generated each area three ways: baseline, default-off, enabled/external. All 281 Sloan files and all 212 Lakeview files match byte-for-byte across those variants; their normalized tar archives also match. Final export stage loads: 9.17, 10.67, 10.67, 9.24, 9.22, 10.83, 10.66, 10.47. Every stage verified actual A4 owner/PID and fresh load <25; wrapper released its own lock on completion. Shared main advanced during work; integrated through `c70c7eb` without conflict; no upstream source/test/area-input changes affected these checks.

| Area | Identical legacy files | All-GLB triangles | Payload bytes | Index bytes | Notice bytes | Total companion bytes |
|---|---:|---:|---:|---:|---:|---:|
| sloans-lake | 281 | 456,225 | 912,608 | 176,283 | 251 | 1,089,142 (1.039 MiB) |
| lakeview-sheil-park | 212 | 1,797,471 | 3,595,048 | 251,749 | 251 | 3,847,048 (3.669 MiB) |

These are **ordinary exports**, 48 Sloan chunks and 25 Lakeview chunks, not the adaptive packed exports used for the design's estimates. All GLB primitives/prototypes/boundary are counted; exact recipe/flag lists and package/archive SHA-256 bindings are in [surface-role-evidence.json](surface-role-evidence.json). Sloan date 2026-10-15T23:44:01Z with the existing package-test focus; Lakeview date 2026-07-15T20:00:00Z, season 1, geographic corners corresponding to ±500 m around its origin. Generator version held constant at `surface-role-legacy-recheck` for all byte comparisons. No new data or profile edits.

**No material guesses:** all 456,225 Sloan and 1,797,471 Lakeview triangle records remain material `unknown` / material provenance `none` because no supported explicit tags are available. Sloan has 3,740 triangles with mapped colour provenance; Lakeview colour provenance is inferred/none. Roles remain independent of palette-slot/hex deduplication.

Generated companions and their bound packages are retained in this worktree under `Generated/surface-roles-evidence/sloans-lake/{enabled,companion}` and `Generated/surface-roles-evidence/lakeview-sheil-park/{enabled,companion}`. `recheck-exports.py`, raw logs and canonical archives stay local/ignored. The initial broad-suite fixture case comparison was corrected; that failed broad run was stopped, then the final requested 87+3 selection was rerun successfully. The first clean-baseline snapshot omitted Package.swift's required `Apps/WorldLab/Sources` path; the snapshot inputs were corrected without changing legacy code, and the complete comparison reran successfully.

 Raw local logs, comparison packages, normalized deterministic tar archives and companions are retained under `Generated/surface-roles-evidence/`; no binary package or screenshot is committed. The 20-hash harness proves road identifiers/centerlines and static positions/indices only, as bounded in [tunnel-guard.md](../data/tunnel-guard.md#filed-measurement-harness-and-serialization-version-2); full package byte comparisons additionally cover legacy paints/normals/water/environment and other serialized files for the two exported recipes. Canonical tar comparisons hold metadata fixed; arbitrary external ZIP timestamps are outside exporter control (the exporter has no archive command).

## Every touched file

- `Sources/WorldMesh/SurfaceAnnotation.swift`: opt-in task-local flag, role IDs and explicit material table/word encoding.
- `Sources/WorldMesh/MeshBuffers.swift`: export-only words, paint annotation/shading, append/partition/repaint propagation, legacy equality/hash/packed channels preserved.
- `Sources/WorldGen/BuildingGenerator.swift`: semantic paints at tuple resolution and shade/covering callsites only.
- `Sources/WorldGen/BuildingFacades.swift`: preserve annotations through three existing shaded paints.
- `Sources/WorldGen/BuildingDetails.swift`: preserve trim semantics through shaded paints; half-timber/sign bands trim even when door colour is reused.
- `Sources/WorldPackage/SurfaceCompanion.swift`: separate hash-bound writer and triangle consistency validation.
- `Sources/WorldPackage/WorldPackage.swift`: default-off destination, capture scope, chunk annotation collection, external write.
- `Sources/worldbake/main.swift`: opt-in CLI option/help only.
- `Tests/WorldGenTests/SurfaceRoleTests.swift`: same-hex roof/door, mapped roof colour vs unknown material, geometry/palette identity, partition/append/no task-local leakage.
- `Tests/WorldPackageTests/SurfaceCompanionTests.swift`: option-off/on byte identity, hash bindings, alignment/counts and destination exclusion.
- `docs/execution/surface-role-implementation.md`: this report and P2 handback.
- `docs/execution/surface-role-evidence.json`: compact measured export/recheck evidence.
- `docs/tracking/handoffs.md`: explicit R authorization and handback scope.
- `docs/tracking/INTEGRATION.md`: companion delivery/consumer status only.
- `docs/tracking/STATE.md`: A4 companion state only; streaming state retained.
