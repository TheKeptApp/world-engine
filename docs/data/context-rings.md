# Context rings (real ground to the horizon)

An area's detailed data (`osm.json`, layer `all`) covers only the area box. Aerial views need real ground beyond it, and the visual specs forbid invented backdrops. The **context ring** is a second OSM extract per area: the same Overpass JSON, the same parser, at low detail, covering the area box plus 3 km on every side.

```
swift run worldbake fetch  <area-dir> --layers context [--building-band-km 1.5|1.0|0.5] [--max-mb 25] [--probe 1] [--split 1] [--no-split 1] [--cache-dir PATH] [--dry-run 1]
swift run worldbake stats  <area-dir> --layers context      # element counts, loader checks (Markdown)
```

Code: `Sources/worldbake/ContextRing.swift`. Test: `Tests/WorldMapTests/ContextRingTests.swift`.

## Files per area

| File | Contents |
|---|---|
| `context.json` | Unmodified Overpass JSON (`out body qt`: no usernames, user IDs or edit times). |
| `context.overpassql` | The exact query that produced it. |
| `manifest.json` | One extra source: `format: "osm-overpass-json"`, `path: "context.json"`, `layers: ["context"]`, `bounds` = the ring box, plus data timestamp, fetch time, bytes, SHA-256, `license: "ODbL-1.0"`, `attribution: "© OpenStreetMap contributors"`. |
| `NOTICE.md` | A "Context ring" paragraph: unmodified ODbL extract, purpose, band, coastline and large-lake notes. |

## What is in it

Ring box = the manifest's bounds expanded by 3 km on every side (the core is included). Statements use explicit per-statement boxes and recursion `(._;>;); out body qt;`, so features crossing the edge come back complete.

| Group | Selection |
|---|---|
| Roads | `highway` motorway, trunk, primary, secondary, tertiary (and their `_link`), unclassified, residential, living_street; `highway=service` with `service=alley` |
| Rail | `railway` rail, light_rail, subway, tram, narrow_gauge, monorail |
| Coast | `natural=coastline` ways |
| Water | `natural=water` ways; `type=multipolygon` + `natural=water` relations with fewer than 300 members; `waterway` river, canal, stream |
| Land | `landuse=*`; `natural` wood, scrub, grassland, wetland, beach, sand; `leisure` park, golf_course, pitch, playground, garden, nature_reserve, recreation_ground; `amenity=grave_yard` (ways, plus multipolygon relations of these with fewer than 300 members) |
| Buildings | `building=*` ways and `building` multipolygon relations (fewer than 300 members), only inside the **building band**: the area's own bounds expanded by up to 1.5 km |

No POI nodes beyond what recursion brings. Relations with 300 or more members are never recursed (`(if: count_members() < 300)`).

Decisions the spec did not cover (logged, change them in `ContextRing.swift`):

- **`landuse=grass` ways with a perimeter under 200 m are left out** (`way["landuse"="grass"](…)(if: length() >= 200)`). Some cities map every lawn: one ring had 34,800 such ways (38 MB for the land group alone), 1,071 of them at 200 m or more. All other `landuse` values are kept.
- The size cap applies to the whole file (25,000,000 bytes). The building band is the only thing stepped down to meet it.
- Multipolygon relations of every group use the same 300-member cap (the spec named water and landuse; buildings follow suit).

### Size cap and the building band

A `context.json` must stay at or under 25 MB. If the result is larger the tool re-fetches with the building band stepped down (1.5 km, then 1.0, then 0.5) and logs it. `--probe 1` prints building counts per band without downloading the data. The band used is visible in `context.overpassql` (the building box) and in the NOTICE paragraph.

| Area | Ring box | Band used | Size | Elements (nodes / ways / relations) | Building ways |
|---|---|---|---:|---|---:|
| `sloans-lake` | 7.6 x 7.2 km | 0.5 km (1.0 km was 26.7 MB) | 19.3 MB | 140,370 / 17,545 / 40 | 7,640 |
| `evanston-south` | 7.0 x 7.0 km | 1.5 km | 12.3 MB | 79,649 / 12,626 / 64 | 7,479 |
| `lakeview-sheil-park` | 7.0 x 7.0 km | 0.5 km (1.0 km was 33.1 MB) | 22.9 MB | 157,616 / 19,372 / 185 | 9,870 |

Building ways cost roughly 0.85 to 1.0 KB each in this format, so dense cities fit only a thin band.

### Large water: coastline is not enough

The spec assumed a very large lake would appear as `natural=coastline` ways. **It does not for the Great Lakes**: OSM maps them only as a multipolygon relation (Lake Michigan: relation 1205149, 1,251 members) and has no `natural=coastline` ways there, so the 300-member cap leaves the lake out entirely. In the committed files `natural=coastline` is 0 in all three areas, and the beaches are present but the water beside them is not.

Open sea shorelines do come as `natural=coastline` ways. OSM convention: land is on the left of the way direction, water on the right.

Measured fix (not yet in the committed files, see Status): the lake relation without recursion (tags and member list) plus only its member ways that touch the ring box. For the Evanston ring that is 5 ways and 721 nodes, about 60 KB. `query()` in `ContextRing.swift` now emits it (`.bigwater`): the relation is output outside the union that is recursed with `>`, because `>` would pull all 1,251 members. A renderer gets the shoreline as open way segments, finds them through the relation's member list (role `outer`), and fills the lake side: the side away from the area. Member direction is not guaranteed for multipolygon outers.

## Reading it

`AreaLoader.loadFeatures` (the detailed world) asks only for layer `all`, so it never loads the context source. Building counts and every generated feature are unchanged (`worldbake stats <area>` before and after: identical).

Read the ring with `AreaLoader.loadDocument(dir, manifest:, layers: ["context"])` and the existing `OSMDocument`. `loadDocument` always also loads sources whose layers contain `all`, so that call returns the context elements merged (de-duplicated by OSM ID) with the detailed ones, which is what a renderer drawing core plus ring wants. To read the context file alone, pass a manifest copy whose `sources` holds only the context source (`worldbake stats --layers context` does this).

`worldbake ring-stats` ignores the context source (`Stats.ring` loads only the detailed layers). `worldbake stats` and `datamap` use `loadFeatures`, so they are unaffected. The exported world package lists the context source in `world.json` `sources` (it is a manifest source), with layer `context`.

If `fetch --layers all` is re-run later, `osm.json`'s entry moves after the context entry in `manifest.sources`; `stats` and `datamap` print the first source's path and timestamp in their headers.

## Etiquette

One Overpass request at a time, at least 5 s apart, the same User-Agent as `Fetcher`, a back-off of at least 65 s after HTTP 429 or 504, and the documented endpoint fallbacks only (five tries on the main server, one on each mirror). A 504 is mostly "the server is probably too busy" and clears on retry. A 403 stops the run. If the single query cannot complete it is split into the four groups above (at most four sub-queries) and the responses are merged by element ID (numbers re-serialised); `--no-split 1` refuses that and fails instead, so the file stays a single unmodified response. `--cache-dir` keeps finished sub-query responses so a re-run resumes.

## Status

The committed `context.json` files were fetched with the query that has no large-lake shoreline (the `.bigwater` statements). Re-fetch each area to add it (the band stays as above):

```
.build/debug/worldbake fetch Data/areas/evanston-south      --layers context --no-split 1
.build/debug/worldbake fetch Data/areas/sloans-lake          --layers context --no-split 1 --building-band-km 0.5
.build/debug/worldbake fetch Data/areas/lakeview-sheil-park  --layers context --no-split 1 --building-band-km 0.5
.build/debug/worldbake stats Data/areas/lakeview-sheil-park  --layers context
```

`stats` then lists the large water relation, its member ways present, and how the shared `MapFeatureBuilder` reads the context document.
