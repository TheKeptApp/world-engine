# Existing context coverage and rights — A1, 8 October 2026

Read-only audit of repository sources at `0d6a222`, using [world-edge-options](../execution/world-edge-options.md) (`4548a25`), [context-rings](context-rings.md), the saved area files, and A11's existing rights audit. No new geographic data fetched, code changed, build run, capture made or package exported. Only this document changes. Repository sync is not a source-data acquisition.

**Finding:** both areas hold selected land/road/water context about 3 km beyond every core edge, but systematic building acquisition is only 500 m beyond it. Lakeview's frozen 600 m west-facing view exceeds that building source band; Sloan's top-centre ray fits, but its top corners do not. Lake Michigan local shoreline is already present: the context-rings document's “not yet in committed files” status is stale for these two snapshots. Source existence still does not supply web renderable context, and publishing even a building-free OSM-derived tier remains blocked by the unresolved ODbL offer.

## 1. Distances and what “coverage” means

Distances below are **selection-envelope** distances beyond the exact core, in local metres east/north; they are not proof of continuous land polygons, every road class, or all buildings. Read the saved `context.overpassql` boxes, transform each cardinal midpoint using the existing WGS84 tangent-plane function `roofplanes.local_en` at the manifest centre, and subtract core half-width/half-height. Rounded to nearest metre. Geographic boxes introduce metre-scale asymmetry. Recursion returns crossing features whole, so isolated coordinates outside these boxes do not establish wider surveyed coverage.

| Area / existing source category | West | East | South | North |
|---|---:|---:|---:|---:|
| Lakeview land | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Lakeview roads | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Lakeview water / local shoreline | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Lakeview building selection | 500 m | 500 m | 500 m | 500 m |
| Sloan land | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Sloan roads | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Sloan water | 2,998 m | 3,002 m | 3,001 m | 2,999 m |
| Sloan building selection | 500 m | 500 m | 500 m | 500 m |

Core sizes: Lakeview 1,000×1,000 m; Sloan 1,600×1,200 m. Source boxes (south, west, north, east), as saved in the queries:

- Lakeview context `(41.9141511,-87.7057980,41.9771732,-87.6213805)`; buildings `(41.9366662,-87.6756679,41.9546725,-87.6515487)`.
- Sloan context `(39.7169677,-105.0888173,39.7818152,-105.0001412)`; buildings `(39.7394918,-105.0596661,39.7593062,-105.0293296)`.

Actual saved building-way counts: Lakeview **9,870**, Sloan **7,640**. Their polygon-centroid maxima beyond the core, W/E/S/N, are Lakeview **509/1,612/2,480/568 m**, Sloan **509/507/547/524 m**. These maxima are deliberately NOT used as complete coverage distances. For example, Lakeview ways 210685652 and 210685779 occur far southeast through the broader extract/recursion; two isolated records do not fill a 2.5 km building band. Extent-crossing footprints can also put centroids slightly outside the selection box.

Selection limitations remain: only the road classes listed in context-rings are selected (not every path/service road); short grass ways under 200 m perimeter are omitted; land/building multipolygons with ≥300 members are omitted; unmapped land is not evidence of lawn. Water has the separate large-relation path verified below. No full polygon-area coverage percentage or OSM real-world completeness claim was measured here.

## 2. Missing directions at the frozen 600 m view

Use [A7's pinned camera evidence](../review/lakeview-600m-blank-field.md) and its saved capture manifest: heading 270°, pitch 45°, vertical FOV 50°, 1,005×565 pixels. Local east/north eye positions are Lakeview `(-58.8745,-54.2030)` m and Sloan `(479.9372,190.9308)` m. On flat ground, the top-centre ray reaches **1,648.486 m west**; top corners have lateral offsets **±1,318.759 m**. Calculation: forward `600/tan(20°)`; lateral `600*tan(25°)*(1005/565)/(sin(45°)-cos(45°)*tan(25°))`. Terrain and roofs change intersections; these are source-accounting requirements, not new renders.

| Area | Top-centre beyond western core | Systematic west-building shortfall | Top-corner extent beyond south / north core | Systematic south / north shortfall |
|---|---:|---:|---:|---:|
| Lakeview | 1,207 m | **707 m** | 873 / 765 m | **373 / 265 m** |
| Sloan | 369 m | **none; ~131 m margin** | 528 / 910 m | **28 / 410 m** |

Thus **west, northwest and southwest** are unsupported by Lakeview's systematic building source band. Sloan's **northwest and slightly southwest corners** exceed its building source band, though the centre-column west ray is covered. No eastward deficit is inferred for this west-facing frame; a free-rotation camera needs a separate all-heading envelope. All these ground rays fit inside the stored broad context selection envelope.

The 0.5 km limit is a **fetch-time source-size compromise**, not merely a renderer clipping fully held 3 km buildings: context-rings records that 1 km building-band responses exceeded the 25 MB cap (Lakeview 33.1 MB; Sloan 26.7 MB). Those wider responses are historical measurements, not verified available complete sources in this audit. Beyond the stored selected band, absence here does not prove absence in global OSM. No other held dataset was silently substituted for context.

Two additional, separate causes remain:

- Native `Sources/WorldGen/Context/ContextRing.swift` uses a 300 m low-building transition, a 100 m aerial slab band, and tall/large-building exceptions (15 m / 1,500 m²). These can omit **already-held** low buildings; they are not the 500 m acquisition cap. `ContextFeatures.swift` bounds buildings by coverage and applies road/feature filters.
- A7 verified that web packages contain detailed chunks and boundary, but no renderable context ring; raw-source provenance in world.json is not context geometry. Therefore even the available first 500 m of buildings is absent from that web path. This audit did not regenerate or inspect a new export.

## 3. Water: concrete checks against held bytes

**Lakeview / Lake Michigan:** current context includes relation **1205149**, tagged natural=water / water=lake, with **1,251 members**, **11 present outer member ways** and **704 unique referenced nodes**, with **zero missing nodes** for those ways. Both saved queries contain `.bigwater`, output its relation without recursion, then request member ways touching the context box and their nodes. The whole lake polygon is intentionally incomplete (1,240 relation members are not present), but it is **not lost entirely to the 300-member cap**.

Present ways: `846600460, 846603561, 1295014955, 692331529, 688479083, 1301218815, 950105573, 846602681, 846602682, 846312458, 692343693`. I resolved all their node IDs, constructed lon/lat lines and used Shapely `linemerge`: all eleven form **one continuous LineString**, endpoints `(-87.6117192,41.8939109)` and `(-87.6542362,41.9889091)`. Clipping this line to the recorded context bounds yields one continuous line from the **south edge** `(-87.62325185,41.91415113)` to the **north edge** `(-87.64645478,41.97717318)`, with no interior break. Zero natural=coastline ways is expected here and does not mean missing lake. This establishes a continuous local shoreline across the ring, not a complete all-lake multipolygon, verified lake-side fill, islands outside the subset or rendered-water correctness. `ContextFeatures` has a partial-water `ShorelineFill` path; its side selection, clipping and holes still need the proposed offline test.

**Sloan's Lake:** relation **4049789** appears in both core and context, with exactly **two members**, both present: outer way **25673621** (173 node references) and inner/island way **93544950** (16). Both rings are closed, all referenced nodes exist, and both raw polygons are valid. Outer bounds `(west,south,east,north)=(-105.0530619,39.7440833,-105.0367503,39.7526625)`; inner bounds `(-105.0452666,39.7470003,-105.0440919,39.7480184)`. It is a complete held source multipolygon, below the relation cap; no source-level lake loss found. Assembly/rendering, duplicate core/context water and clipping correctness remain separate tests.

## 4. Rights: conditional source permission, no publication clearance

Under [A11 inventory](../legal/data-licence-inventory-v1.md), “ODbL” and “OSM extracts, Overpass, context rings” rows, these extracts have **GREEN ODbL source rights**, including commercial reuse. A coarse building-free tier can be made from them subject to ODbL; removing buildings does not erase the source licence or automatically make the derivative unrestricted. **Cannot publish today under the repository release gate:** credits still contain `odbl-offer`, `placeholder: true`, `ODBL_OFFER_URL_PENDING`.

Apply [data-licensing §§1–3](../data-licensing.md): retain source/licence notices and visible © OpenStreetMap contributors with copyright/licence links, burn attribution into image exports, identify modifications, and provide the required free machine-readable version-matched derivative data offer plus unrestricted parallel access where restrictions/technical measures apply. The repository's standing treatment is an ODbL Derivative Database; do not relabel simplified geometry as a licence-free Produced Work to bypass it.

Still unresolved before publication: counsel confirmation of the exact coarse tier's database/Produced Work classification and offer file set; live versioned hosting, retention and tested offer links; context.json/query/NOTICE provenance included in the actual offered version (the older offer example lists core extracts); final app/web/archive attribution and licence propagation; app-store/DRM terms and unrestricted parallel copy; separate rights/provenance/credits if any terrain or non-OSM input is added. This audit uses no new legal web lookup and makes no new legal clearance: it reports A11's filed obligations and the current local placeholder. Building-free is a geometry choice, not a shipping exemption.

## 5. First offline accounting test — proposed, not run

**Inputs already held:** Lakeview core osm.json **3,434,118 bytes** + context.json **23,102,065** = **26,536,183**; Sloan core **4,365,836** + context **19,332,840** = **23,698,676**. Combined raw JSON **50,234,859 bytes**, excluding small manifests, queries and notices. Lakeview manifest/query/NOTICE are 2,716/2,433/5,398 bytes; Sloan 2,008/2,475/3,715. Use the frozen 600 m camera records, local-frame/core bounds, existing source notices, current context classification/simplification rules and pinned shared material definitions. These are source bytes, not decoded memory, GPU residency or projected GLB sizes. No new DEM/imagery/buildings needed for a first flat context accounting test; adding terrain would require separately accounting its held inputs/datum.

1. Under the existing heavy wrapper for any build/test, with load admission and ≥8 GiB free, pin file hashes and only read the held data. Merge core/context by typed OSM ID; count missing node/member references and exact duplicate features. Separate a building-free ledger from the held-building-band ledger; mark unsupported exterior coverage, never stretch the 500 m band.
2. Clip context geometry **outside the exact core**, preserving boundary-crossing roads, lake shore, holes and shared coordinates. Check boundary overlap/gaps and typed-ID duplication; exclude core duplicates. Verify Lake Michigan land/water side, continuous north-to-south shore and no land fill over lake. Verify Sloan outer/inner-ring area and core/context water joins. Record rejected/ambiguous geometry rather than filling unknown land with lawn.
3. Measure raw/retained feature and vertex counts, simplification error, triangles, shared material groups and per-LOD/per-cell bytes. Estimate index bytes plus vertex attributes explicitly; if later authorized, measure actual encoded bytes rather than presenting planning envelopes as results. Record entire band and frozen-frustum-visible subsets, including corners, and unresolved building coverage.
4. Separate transfer bytes, decoded arrays, maximum concurrent old/new decode/upload memory, GPU resident bytes, main/shadow geometry and draw estimates. No device frame-time or visual-pass claim follows from offline counts. Lakeview sceneBudget baseline is still unmeasured in the world-edge brief; do not borrow Sloan's headroom as its budget.
5. Deliver a deterministic accounting report and input hashes first. Any exporter implementation, rendered before/after, new source acquisition or public release needs its own authorization. Release the lock immediately after each active heavy step. No such step was run here.

## Snapshot evidence and reproduction

| Held context | OSM timestamp | Nodes / ways / relations | SHA-256 |
|---|---|---|---|
| Lakeview | 2026-10-06T17:59:36Z | 157,616 / 19,372 / 186 | `068d3bf1e7251f4ab7cd41bf678c1096eb7977c7856e1d2205f3c3b0479808b3` |
| Sloan | 2026-10-06T18:02:40Z | 140,370 / 17,545 / 40 | `8338043f81a55299cc66fddd5459ce5fc48a3966d5e5973a0f9c52157c986e62` |

These hashes match A7's pinned source evidence. To repeat without fetching/building: read the saved JSON into dictionaries keyed by type/id; use saved query boxes and manifest centres/core dimensions for the distance calculation above; select relation 1205149 or 4049789, resolve member ways then nodes, count missing references, test ring closure/Polygon validity and line-merge/box-intersection as described. Only local in-memory JSON/geometry inspection was used. Source completeness in the world, missing offshore features and rendered fill are not established by these checks.

## Ledger text for A3

A1 existing-context check: broad selection ~3 km all directions, systematic buildings ~500 m; Lakeview west and both top corners exceed source band at frozen 600 m, Sloan west-centre fits but north/south top corners exceed it. Existing Lake Michigan partial relation/local shoreline is present and continuous across the ring; Sloan lake outer/island rings are complete. Older context-rings missing-bigwater status is stale. Web export gap and native low-building filters are separate. ODbL source permission is GREEN; publication remains blocked by absent verified offer. No new source, export, code, capture or grade.

Used: world-edge-options 4548a25; context-rings; A7 camera/source evidence; held context queries/JSON; A11 inventory ODbL/OSM rows and data-licensing §§1–3. Mock: none (read-only accounting). Deviation: stale large-water documentation corrected in this report only.
