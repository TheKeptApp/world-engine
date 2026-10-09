# House-shortcut census and tunnel status — 8 October 2026

Read-only census of main `e5a0a3e246c0a3e80658142e34bba69aeafa9fe4`; no engine, generator, renderer or input data changed. Evidence: `Data/quality/house-shortcut-census.json` includes source/input SHA-256 values and every selected footprint ID/area.

## Method

Called the existing AreaLoader.loadFeatures, BuildingGenerator.role(of:), BuildingGenerator.role(for:), ZoneProfiles and SceneGenerator.detachedGarages from a temporary Swift analysis executable under scripts/heavy.sh (load 6.89; 61 GiB free). No generate/render call. Denominator: all loaded non-part buildings, including Overture merge results, using each manifest’s normal extent and centroid inclusion. Building parts are separately excluded (Lakeview 1; Greenville 27). These are generator-loader populations, not lidar-sidecar populations.

“Only” means the entry into static .house is the building=yes/area shortcut, without an explicit house-type tag; it is not a counterfactual removal experiment. role(of:) first excludes area <12 m² as sheds; the candidate interval is therefore [12,250) m². The reported final subset remains .house after normal zone selection and alley/detached-garage overrides in role(for:). The separate >250 m² profile promotion and split-house path are excluded. Footprint is polygon area in local metres, summed once per retained building; it is not floor area or a claim of observed residential use.

| Area | Buildings | Static shortcut | Garage overrides | Retained houses | Share | Retained footprint m² |
|---|---:|---:|---:|---:|---:|---:|
| sloans-lake | 1399 | 9 | 3 | 6 | 0.43% | 839.32 |
| lakeview-sheil-park | 2823 | 2498 | 1067 | 1431 | 50.69% | 187336.52 |
| wilmette-vattmann-park | 1259 | 1196 | 416 | 780 | 61.95% | 112802.22 |
| west-highland | 2495 | 1 | 0 | 1 | 0.04% | 16.90 |
| greenville-downtown | 681 | 144 | 26 | 118 | 17.33% | 16193.14 |

## Tunnel guard / unsupported-feature diagnostics status

Not implemented on the inspected main. A8’s long-tail feature coverage review ranks this first, and docs/execution/archetypes.md stage 0 specifies UndergroundGuard/diagnostics; neither document establishes delivery. MapFeatureBuilder records isTunnel, but SceneGenerator’s core road loop still emits all roads without an isTunnel condition. Existing tunnel filtering in optional context and experience selection is partial and is not a shared core guard. No new unsupported-feature diagnostic implementation was found in the map/package/export paths. This turn confirms status only, as requested; no code or rendering changed.

Used: docs/review/long-tail-feature-coverage-2026-10-08.md ranking/row 2; BuildingGenerator.swift role(of:)/role(for:). Mock: none (read-only census). Deviation: none.
