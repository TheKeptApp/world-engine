# Map data layer (worldengine.map/2)

The world package's map data layer: the public, static map of a package area for apps (routes, walks, traffic,
transit), next to the visual files. Contract: Neighborhood Jobs' `docs/contracts/world-map-layer-v2.md` and
`contracts/world-map-layer-v2.schema.json` (read-only input; WorldEngine does not change it). Code:
`Sources/WorldPackage/MapLayer/`. Written by `worldbake export` into every package.

| Path | Contents |
|---|---|
| `map/layer.json` | header: frame, sources, credits, ZCTA regions, methods with their confidence definitions, file list |
| `map/network.json` | every `highway=*` way that is not an area, split into segments; nodes with traffic control; barriers; gated areas; turn restrictions |
| `map/buildings.json` | footprints, centroid, type, part flag, house-number and `addr:street` presence flags, frontage |
| `map/lots.json` | front and back yards: outline, area, mowable area, lidar slope, confidence |
| `map/entries.json` | front doors and driveway ends with confidence |
| `map/places.json` | parks, schools, libraries, shops, other amenities and leisure places |
| `map/transit.json` | stops and routes from OSM |
| `mapmeta/ids.json` | source links of IDs that are not plain source identities (below) |
| `mapmeta/provenance.json` | every field labelled observed, inferred or simulated (below) |
| `mapmeta/migration.json` | old ID → new IDs against the previous package (only with `--previous`) |
| `independent/terrain-slope.json` + `.bin` | USGS 3DEP lidar slope grid (no OSM input; `uint16le`), joined by position; separately licensed |
| `independent/lot-slope.json` | each lot's lidar slope, joined by lot ID; separately licensed (not cleanly independent, licensing.md §15) |

world.json gains `mapLayer` (`{schema, header}`), `mapSnapshotID` and `mapMeta` (`{schema, ids, provenance,
migration?}`); the package stays `worldengine.package/1`. Every file is hashed in `files` and listed as ODbL
Derivative Database data.

## Inputs

| Input | File in the area directory | Licence |
|---|---|---|
| OSM extract of the area | `osm.json` | ODbL 1.0 |
| OSM context ring (roads beyond the area: the margin) | `context.json` | ODbL 1.0 |
| OSM turn-restriction and route relations | `osm-relations.json` (`worldbake fetch --layers relations`) | ODbL 1.0 |
| Overture buildings (where present) | `overture-buildings.json` | CDLA-Permissive-2.0 / ODbL per source |
| ZCTA boundaries | `zcta.json` (`Tools/regionkit/zcta`) | U.S. Census, public domain |
| Lidar slope grid | `terrain-slope.json` + `.bin` (`Tools/regionkit/terrain`) | USGS 3DEP, public domain |

## Decisions taken within the contract

- **Margin:** roads and paths reach 400 m beyond the playable area (`area.marginM`), from the area and context
  extracts. The context extract holds only main and residential streets and alleys, so footways and other
  service roads in the margin are missing; every margin segment is flagged `context`.
- **Playable area:** the export's focus rectangle (the whole area by default).
- **Buildings:** those whose centroid is in the playable area or whose footprint reaches into it. Buildings
  whose centroid lies outside the area box are not in the world at all and so not in the layer.
- **Frontage:** the named street the generator's `StreetContext` chose for the front edge; the segment is that
  street's piece nearest the front door. Garages, sheds and parts have none.
- **Lots:** the generator's yard (`GeneratedLot`) split at the front edge's line, with the largest connected
  piece of each part (`droppedArea` in the generator says how much was left out). No lots for a building
  without a front edge. Mowable area: open lawn cells minus walks, driveways, planted front gardens, paved rear
  yards and foundation beds (tree trunks are not subtracted).
- **Slope (contract D-57):** never in `map/lots.json`. `independent/lot-slope.json` holds each lot's steepest 1 m
  lidar cell over its mowable lawn, at least 2 m from the walls (lidar ground next to walls is interpolated), only
  where ground returns cover ≥ 80 % of the lawn cells, joined by lot ID, with `slopeConfidence`.
  `independent/terrain-slope.json` + `.bin` is the grid itself (`uint16le`, 0.01 % units, south-to-north rows,
  origin at the south-west corner, 65535 = no data) with a grid `confidence`; NJ samples it for lots without a
  confident record. Confidence: the share of validation cells whose slope agrees within 2 percentage points (the
  lower of the USGS 1 m DEM comparison and the split-sample test), per slope class for lots (< 15 %, ≥ 15 %) and
  overall for the grid and the method's `defaultConfidence`. Both files are separately licensed (proprietary
  pending legal review; `docs/research/licensing.md` §15) and part of the snapshot ID.
- **Entry points:** front doors (`GeneratedBuilding.entry`) and driveway ends (end of the generated driveway,
  keyed by the house whose yard it crosses). No mailboxes or yard gates: the generator makes none.
- **Coverage:** `partial` only for a known data gap (no relations extract: no turn restrictions or routes).
- **Traffic control:** a node's own `highway=traffic_signals|stop|give_way`; a sign mapped on a way within
  30 m (signals 20 m) of a junction is assigned to that junction, with the approach (`direction=*` picks the end).
- **Places:** `leisure=park`, `amenity=school|library`, `shop=*`, and as `other` every `amenity`, `leisure` and
  `tourism` element except street furniture and parking geometry (`MapLayer.placeAmenityNoise`).
- **Snapshot ID:** the contract's definition, `wem2-` + 16 hex of SHA-256 over `"<path> <sha256>\n"` of
  `map/*.json` and `independent/*`. `map/layer.json` carries `generator.version` (it must equal world.json's), so the ID changes
  whenever the export's version string changes, even for renderer-only changes. Exports meant to keep a
  snapshot should keep the version string.

## IDs: stable engine IDs and their source links

Every exported feature has a stable engine ID, linked to its source identity:

| Collection | Engine ID | Source link |
|---|---|---|
| nodes, barriers | `node/<osm id>` | the OSM node itself |
| segments | `way/<osm way id>:<k>` | way + node index range `[k0, k1]` of the full node list, end nodes (`mapmeta/ids.json`) |
| gated areas, turn restrictions, places, stops, routes | the OSM element (`node/…`, `way/…`, `relation/…`) | itself |
| buildings (OSM) | `way/…`, `relation/…` | itself |
| buildings (Overture) | `overture/<first 16 hex digits of the GERS ID>` | full GERS ID and footprint dataset (`mapmeta/ids.json`) |
| lots | `gen:lot:<building id>:<front\|back>` | the building |
| entry points | `gen:entry:<building id>:<kind>[:<n>]` | the building |

The Overture form changed on 2026-10-06 from `overture/<signed int64>` to 16 hex digits (the contract's pattern);
scene.json identities, lidar roof hints and lot/entry IDs use the same form. One building per GERS ID: an
Overture record with several polygons keeps its largest.

**Stability.** The same inputs give the same IDs and bytes. An ID changes only when its own source element
changes: a segment when a new junction or barrier splits its way (piece indices shift), a building when its
OSM element or GERS ID changes, a lot or entry point only with its building.

## Migration rules (old ID → new ID per snapshot)

`worldbake export … --previous <old package>` writes `mapmeta/migration.json`: for every ID of the old layer
that no longer exists, the new IDs that now carry its object, with the kind of change; IDs that still exist mean
the same object and are not listed; new IDs are listed under `added`. Matching is geometric in the shared frame
(the old package must have the same origin):

| Source change | Collections | Rule | `change` |
|---|---|---|---|
| a way gains or loses a junction or barrier | segments | new pieces of the same way within 1.5 m of ≥ 20 % of the old piece's 2 m samples | `renumbered` (one piece) or `split` |
| ways joined | segments | several old pieces → one new | `merged` |
| way replaced (new way ID, same street) | segments | as above, different way | `replaced` |
| way deleted | segments | no match | `deleted` |
| node replaced | nodes | the new node within 1 m | `replaced` / `deleted` |
| building redrawn, replaced, Overture → OSM | buildings | footprint IoU ≥ 0.5 or ≥ 50 % coverage either way | `replaced` |
| buildings joined / divided | buildings | several old → one new / one old → several new | `merged` / `split` |
| building deleted | buildings | no match | `deleted` |
| (follows the building) | lots, entries | same part or kind on the mapped building | `replaced` / `deleted` |
| place re-mapped | places | same `class` within 15 m | `replaced` / `deleted` |

Apps keyed on IDs (NJ's customer book, beats) apply the map once when they move to the new snapshot.

## Provenance: observed, inferred, simulated

`mapmeta/provenance.json` labels every field, with per-record exceptions:

- **observed**: mapped or measured by a source (OSM, Overture survey or authoritative data, Census ZCTA, USGS
  lidar), or computed exactly from such values (lengths, centroids, containment, parsed units).
- **inferred**: estimated from observed data by a fixed rule, not checked record by record: frontage street and
  side, lot outlines, driveway ends, the wall a door is on, stop-sign approaches, and Overture footprints traced
  by machine learning (per-record exceptions).
- **simulated**: a seeded draw from regional distributions: the door's position along its wall (so frontage
  `offsetM` too), and the planting choices that set mowable area.

Confidence numbers themselves are observed: calibrated shares of a validation sample
(`docs/research/map-confidence.md`).

## Privacy

No house numbers, street values, residents or user data: presence flags only, `addr:*` stripped from every
verbatim tag set, `containsUserData: false`. Every building is treated the same way; nothing singles out a home.
Calibration ground truth (parcels, labels) never enters the repository or a package.
