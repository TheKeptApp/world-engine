# Detailed map size budget (`osm.json`)

Found while checking `winnetka-village-green`: its `osm.json` (layer `all`, 1 km box) was 9.5 MB, 8 to 25 times its neighbours. The cause was one relation.

## Cause

The "all" query selects every `type=multipolygon` relation touching the box and recurses into it with `(._;>;)`. Lake Michigan (relation 1205149, 1,251 members) is matched because some of its member ways touch the box, so all 1,251 member ways and their 82,285 nodes came back: 1,251 of the file's 1,675 ways and 82,285 of its 84,304 nodes, about 8.7 of 9.5 MB. None of it is street-level detail.

## Fix applied

`Tools/regionkit/regionkit.sh osmclip Data/areas/<id>...` (code: `Tools/regionkit/regionkit/osmclip.py`, tests: `tests/test_osmclip.py`, synthetic fixture, no network). For every relation with 300 or more members it keeps the relation unchanged (tags and full member list) and drops member ways whose node bounding box does not intersect the context-ring box (the `context` source's bounds in `manifest.json`), plus the nodes only those ways used. A way is kept if a smaller relation lists it; a node is kept if any kept way or relation uses it. Kept elements are copied byte for byte, and the manifest's `bytes` and `sha256` for `osm.json` are updated. It is idempotent. The area's `NOTICE.md` must say what was clipped (done for `winnetka-village-green`).

Run on all areas, only `winnetka-village-green` held a relation with 300 or more members in its detailed file.

Side effect to know about: the shared feature builder can no longer assemble the clipped relation (member way missing), so it reports one skipped multipolygon and builds no polygon from it. In Winnetka that removed one 56,439 m² water area (the file holds no other water polygon, so it came from this relation; it is not yet checked whether it was real lake or a ring-joining artefact of the 1,251-way assembly, review with `datamap` if the lake edge matters there); the building, road and path counts are unchanged (582 / 137 / 90).

## Sizes (bytes of `osm.json`, area box)

| Area | Box km² | Before: bytes | MB/km² | Nodes / ways / rels | After: bytes | MB/km² | Nodes / ways / rels |
|---|---:|---:|---:|---|---:|---:|---|
| `wilmette-vattmann-park` | 1.00 | 332,989 | 0.33 | 2,163 / 355 / 1 | unchanged | | |
| `kenilworth-station` | 1.00 | 350,413 | 0.35 | 2,308 / 263 / 0 | unchanged | | |
| `winnetka-village-green` | 1.00 | 9,468,942 | 9.47 | 84,304 / 1,675 / 1 | 772,767 | 0.77 | 5,160 / 430 / 1 |
| `evanston-south` | 1.00 | 1,229,794 | 1.23 | 6,812 / 1,448 / 1 | unchanged | | |
| `sloans-lake` | 1.92 | 4,365,836 | 2.27 | 34,815 / 3,706 / 4 | unchanged | | |
| `lakeview-sheil-park` | 1.00 | 3,434,118 | 3.43 | 23,240 / 3,648 / 8 | unchanged | | |

MB are 10^6 bytes. Observed range after the fix: 0.33 to 3.43 MB/km²; the dense Chicago grid (`lakeview-sheil-park`) is the top.

## Budget

- **5 MB per km²** of area box for a detailed `osm.json`: about 1.5 times the densest area so far (Lakeview, 3.43), about 6 times the median (0.8 to 1.2). A 1 km box is then at most 5 MB, the 1.6 x 1.2 km Sloan's Lake box 9.6 MB. Dense blocks with many mapped trees and building parts should stay under it; if a real area legitimately needs more, raise `BUDGET_MB_PER_KM2` in `areacheck.py` and write down why here.
- **No relation with 300 or more members may carry member ways outside the context-ring box.** A clipped stub (the relation plus ways touching the ring box) is fine.

## Check

```
Tools/regionkit/regionkit.sh areacheck [--budget MB_PER_KM2] [--areas-dir DIR]
```

Prints the table above for every `Data/areas/*` (sizes from the files, area from `widthMeters x heightMeters`), lists each problem as `FLAG area/file: reason`, and exits 1 if there is any. Run it after every `worldbake fetch` and before committing area data. Code: `Tools/regionkit/regionkit/areacheck.py`; offline tests in `tests/test_osmclip.py` (`regionkit.sh test`). If it flags a big relation, run `regionkit.sh osmclip Data/areas/<id>`, then update `NOTICE.md`.

## Proposed fetch change (not implemented)

Stop the problem at the source, in the "all" query built in `Sources/worldbake/Fetcher.swift`. Today the multipolygon statement is recursed with `>` whatever its size. Instead, as the context layer already does (`ContextRing.swift`, `memberCap = 300`):

1. Recurse only into multipolygon and building relations with fewer than 300 members: `relation["type"="multipolygon"](bbox)(if: count_members() < 300)` inside the recursed union.
2. Output the big ones outside that union, as stubs: `relation["type"="multipolygon"](bbox)(if: count_members() >= 300); out body;` (tags and member list, no recursion).
3. Add only the member ways that touch the area box (`way(r.big)(bbox); out body;` then `node(w); out body;`), so a shore that really crosses the 1 km box still arrives as open way segments. The feature builder then reports the stub as a skipped multipolygon, exactly as it now does for the clipped Winnetka file, and the shoreline fill can use those segments as the context layer does.
4. After fetching, `worldbake fetch` should run the same size and big-relation checks as `areacheck` and warn.

Result: a re-fetch gives the clipped file directly, so the manifest SHA-256 matches an unmodified response and the "clipped" caveat in NOTICE.md goes away. Until then `osmclip` is the stop-gap.
