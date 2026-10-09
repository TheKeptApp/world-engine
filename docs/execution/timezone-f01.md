# A4 — F01 package civil timezone

Status: timezone validation PASS; 92/92 tests, all 20 road/static hashes unchanged, all three complete package comparisons pass. Remote publication remains blocked by the historical evidence-line guard.

Replaces the universal Denver display timezone with an optional `AreaManifest.timezone` IANA identifier. The exporter validates it through Foundation `TimeZone`; absent or invalid metadata exports the literal `unknown`. No longitude-to-zone approximation, network lookup, device-local timezone or demo fallback. Civil timezone metadata is authored for all eight currently held areas: Denver neighbourhoods America/Denver; Chicago-area municipalities America/Chicago; Greenville SC America/New_York. New areas must supply verified metadata or remain unknown. This changes display metadata only: UTC moments, geographic sun computation, geometry, palettes and rendering stay unchanged.

Compatibility: old manifests decode with nil; optional encoding is additive. The Sloan package must remain byte-identical. For Lakeview/Wilmette, the semantic package difference must be `environment.json.location.timezone` only; `world.json.files[environment.json]` SHA-256/byte count necessarily changes to maintain integrity. External companions bind world.json and must be regenerated for corrected packages. No companion format changes.

Validation completed: requested 87 legacy +3 companion fixtures and two timezone fixtures, 92/92 in 16 suites, 98.775 s, admission load 5.09. All 20 filed before/after road/static hashes match exactly (five areas × two stages × two hashes), admission load 5.39. Full baseline/current package comparisons against 5a7fe5a for Sloan/Lakeview/Wilmette pass. Sloan: all 281 files byte-identical. Lakeview: 212 files; Wilmette: 209 files; only environment.json timezone plus world.json environment integrity entry differ. Every other file and JSON field is identical. Package-job admission 4.95; each build/export also checked actual A4 owner/PID and fresh load <25 (stage loads in evidence). Own wrapper released the lock. Raw evidence is local under `Generated/timezone-evidence/`. Area manifests change only by timezone metadata; their input hashes consequently change, while original source payload hashes must remain unchanged.

Remote status: fetched main af49fd6 did not contain 5a7fe5a. Integrated without conflict (a23ef40); push blocked by the repository evidence guard on historical merge 9712ae2, whose message lacks an evidence line. No hook bypass, force push or rewrite performed.

Touched: Sources/WorldMap/AreaManifest.swift; Sources/WorldPackage/WorldPackage.swift; Tests/WorldPackageTests/TimezoneTests.swift; all eight Data/areas/*/manifest.json files (timezone only); docs/execution/timezone-f01.md; docs/execution/timezone-f01-evidence.json; docs/tracking/STATE.md; docs/tracking/handoffs.md.

Used: docs/review/block-specific-scan.md F01. Mock: none (metadata only). Deviation: integrity checksum changes are required, not unrelated package changes.

## Area metadata

| Area | IANA timezone |
|---|---|
| sloans-lake | America/Denver |
| west-highland | America/Denver |
| lakeview-sheil-park | America/Chicago |
| wilmette-vattmann-park | America/Chicago |
| evanston-south | America/Chicago |
| kenilworth-station | America/Chicago |
| winnetka-village-green | America/Chicago |
| greenville-downtown | America/New_York |

All eight manifest comparisons against the pre-fix tree differ only by this field. Original data payload hashes remain unchanged; the five manifests in the road/static harness have new input hashes solely because this metadata was added. Two new fixtures cover legacy manifest decoding, nil/invalid explicit unknown fallback, valid zones beyond the held regions, held-area values and Codable roundtrip.

## Filed evidence

[Compact evidence](timezone-f01-evidence.json). Baseline/current packages, full file hashes, comparison script and raw logs remain ignored/local under `Generated/timezone-evidence/`. Main advanced during validation from af49fd6 to 75be597; upstream changes are docs/tooling only, no Sources/Tests/Data changes. Preserve original 5a7fe5a ancestry rather than rewriting it.

| Area | Files compared | Semantic difference | Integrity difference |
|---|---:|---|---|
| Sloan’s Lake | 281 | None | None |
| Lakeview | 212 | America/Denver → America/Chicago | environment checksum/byte count in world.json |
| Wilmette | 209 | America/Denver → America/Chicago | environment checksum/byte count in world.json |

`unknown` is an explicit unresolved status, not an IANA timezone identifier. No geographic inference or consumer behavior change is included.
