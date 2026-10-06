# Research: regions, data coverage and licensing

Groundwork for phase 5B (Chicagoland test region) and for adding regions later. Written 2026-10-06 in a
session parallel to phase 5A; nothing here changes the engine, the renderers, the profiles or the package
format. All OSM-derived numbers: © OpenStreetMap contributors (ODbL 1.0).

| Document | What it answers |
|---|---|
| [region-kit.md](region-kit.md) | The region kit (`Tools/regionkit/`): what it measures, how to run it, accuracy against the hand-made profiles (Denver, Plano, ChatGPT's 11 Chicagoland/Miami profiles), the zone drafts, zones in the schema, what open data can't supply |
| [data-coverage.md](data-coverage.md) | 46 sample cells (North Shore, Chicago, 11 metros): what OSM and Overture hold, the ranked gaps and how the generator should handle each, the dense-Chicago triangle estimate |
| [licensing.md](licensing.md) | Licensing and attribution checklist (OSM/ODbL, Overture, WeatherKit, star catalog, Fab), blockers, questions for a lawyer. Not legal advice |
| [live-feeds.md](live-feeds.md) | Live transit (Metra, CTA, Pace, RTD) and aircraft feeds: endpoints, limits, terms, attribution, cost; a small relay design (phones never hold keys) and monthly cost at 1k / 10k users. Research only, no app code |
| [ambient-planes.md](ambient-planes.md) | Specification (no code) of an "ambient planes" option, the stand-in until adsb.lol permits live aircraft: illustrative aircraft clearly labelled "not live" on real approach corridors into ORD and DEN (runways and true headings from OSM, 3° glide path, wind-picked flow, seeded traffic model, `aircraft-ambient` records generated on device). No flight data, no feed licence |
| [overture-source.md](overture-source.md) | Overture buildings as a second footprint source (owner decision 2026-10-06): `worldbake fetch --layers overture`, the `overture-buildings-v1` file, merge rules (OSM wins), identity (`overture/<id>`), credits and the ODbL note |
| [aerial.md](aerial.md) | Feasibility of reading roofs and tree canopy from USDA NAIP aerial imagery (proof of concept on a 0.25 km² Wilmette cell): licence and small-area access, method, hand-checked accuracy, recommendation. Aggregates only |
| [lidar-roofs.md](lidar-roofs.md) | Phase 5B pilot: roof forms (flat/gable/hip/complex, pitch, ridge) from USGS 3DEP lidar for South Evanston, hand-checked, compared with the roof forms P2's generator assigns; vintage check; recommendation and North Shore scaling. Aggregates only |

Tools: [`Tools/regionkit/`](../../Tools/regionkit/README.md) (region kit; drafts in `Tools/regionkit/drafts/`) and
[`Tools/regionkit/audit/`](../../Tools/regionkit/audit/README.md) (coverage audit). Both are offline Python research
tools; nothing is loaded at runtime. No raw map data is committed, only aggregates.

**Code baseline.** The measurements and generator analysis were made against main at `772ff24` (phase 5A).
P2 buildings landed afterwards (`91ed01c`): alley garages, large houses vs blocks, block families from tag
evidence, roof assemblies (cross-gables, dormers, chimneys), rear porches, and the `evanston`, `wilmette` and
`chicago-dense-north` profiles adopted unchanged from ChatGPT's proposal. Notes below say where that changes a finding.

## Findings that cut across the documents

1. **OSM is good in Chicago and nearly empty on the North Shore.** Chicago's city import gives near-complete
   footprints and storey counts on about half the buildings; Overture adds only 0.2–0.9 % per cell. The four North Shore cells
   hold 154 OSM buildings against 3,601 in Overture (all extras from Microsoft ML footprints). From OSM alone these
   cells would show a few landmarks on otherwise empty blocks.
2. **Almost every descriptive tag is missing everywhere:** `roof:shape` on 2.6 % of buildings (0 % on the North
   Shore), no `roof:angle`, colours/materials on 2.3 %, tree species on ≤ 1 % of mapped trees. Most profile
   values (roof mixes, pitches, colours, porches, windows) cannot be measured; they stay art direction.
3. **Where the data can judge, ChatGPT's priors are often contradicted.** Default storey counts are the one
   strongly measurable field (458–2,774 tagged houses per Chicago city zone). Example: `chicago-bungalow-belt`
   gives untagged houses about 98 % one-storey defaults; comparable tagged houses are 39 % one-storey, 59 %
   two-storey. Thresholds are supported in several zones; roof mix is contradicted in the greystone zone.
   Since P2 adopted `chicago-dense-north`, `evanston` and `wilmette` unchanged, the dense-north storey defaults
   (reference 0.44/0.39/0.17 vs measured 0.08/0.68/0.25 for 1/2/3+) now sit in an engine profile.
4. **Generator behaviours mattered more than any profile value.** At `772ff24`: one profile per baked area;
   `block` buildings never entered the house-type lottery (apartment, courtyard and tower families couldn't be
   chosen); small `building=yes` footprints by the alleys, very likely detached garages, became houses with doors
   and porches: 30–44 % of the generator's "houses" in three Chicago zones (region kit's heuristic; the audit's
   simpler size-only count gives 28 % of all buildings). **P2 has since fixed the garage and block points**
   (an alley-garage rule from size and mapped alley access; block families from tag evidence). Still open on
   main: one profile per baked area and `building:part` skipped. The duplicate multipolygon outer and the
   `type=building` relation buildings were fixed by P2 in `1085568`.
5. **Dense Chicago breaks the triangle budget at full detail** (estimate for the `772ff24` generator, nothing
   built): a whole Loop cell is 2.2 M static triangles, 97 % of its building triangles are window frames, and
   curbs cost 12 triangles per street metre. Residential cells fit on average but not in the worst views. Facade
   LOD has to come before floors-from-height or towers. **Measured after P2** (generator `b8f6c71`, exported
   packages): the estimate held for what it modelled. Whole cells are 0.69–2.24 M static triangles
   (`chicago-dense-north` adds 19–28 %), and P2's new parkway and yard trees add 23–61 k to the average view. With
   a WorldLab-sized focus the mean view is 96–271 k. The Loop and Lakeview break the 400 k ceiling at p90, and
   every dense-north cell breaks it in its worst view (464–605 k). One Loop chunk alone casts 181 k shadow
   triangles, over the 150 k ceiling ([data-coverage.md](data-coverage.md#triangle-counts-for-a-dense-chicago-cell)).
6. **Mapped trees are rare** in most places: 78 per km² in Chicago neighbourhoods,
   0.5 on the North Shore, against 2,812 at Sloan's Lake. The generator places only mapped trees, so
   Chicagoland streets would be nearly treeless.
7. **Live feeds:** transit data is free but every licence is revocable. RTD is the easiest (no key, redistribution
   granted). CTA limits the purpose ("assisting" riders), Pace's static data is "non commercial use" and its live URLs are
   undocumented, and Metra's terms require a relay (unverified: metra.com blocks automated access). Community
   aircraft feeds are non-commercial except adsb.lol (ODbL, ask the operator); commercial aircraft feeds cost about
   $1.6k–18k a month for two metros. Upstream cost scales with active areas and poll interval, not users.
8. **Aerial imagery (NAIP, public domain, 0.3 m, leaf-on):** tree canopy per block works (mask agrees with
   photo-interpreted points 85 %, canopy 58 % in the Wilmette cell). Roof colour is usable only as a zone-level
   lightness mix (60–65 % exact on hand-checked roofs; black/white untested; warm roofs underestimated). Roof type
   was not shown to beat a constant guess, so no per-building roof hints from NAIP; USGS 3DEP lidar (public domain,
   readable by area) is the better source for roof form. **Phase 5B:**
   - Canopy measured for the test areas: residential fabric South Evanston 47 %, Lakeview 18 %, Sloan's Lake 25 %,
     Wilmette 55 % (`aerial.md` §13).
   - The lidar pilot reads South Evanston's roofs right 87 % of the time on simple form. P2's per-building roof
     forms agree with lidar only at chance level (48 %). Real houses are more often hipped and complex, with
     flatter gables than the `evanston` profile draws ([lidar-roofs.md](lidar-roofs.md)).
9. **Licensing:** nothing blocks internal development. Before a public release: a credits screen with the ODbL
   "offer", credit burned into exported images/widgets, and Apple Weather attribution. The world package is most
   likely an ODbL Derivative Database, not a Produced Work as `docs/plan-m1.md` §6 assumes.

## Zones

The existing `RegionCatalog` (ordered boxes, first match wins, several boxes per profile) already holds
several zones per region; ChatGPT's catalog uses it with 18 boxes. No schema change is proposed. Real gaps,
each with its smallest fix, are in [region-kit.md §5](region-kit.md#5-zones): per-building profile selection,
block dispatch and a garage role rule (both addressed by P2 since), and data-only box fixes. One schema-level gap
stands: profiles have no tree-density field, and generated street trees need one
([data-coverage.md, gap 4](data-coverage.md#biggest-gaps-ranked-and-what-the-generator-should-do)).

## What this means for phase 5B

- **Suburban test (North Shore):** needs a second footprint source (Overture buildings, ODbL, with heights from
  USGS lidar or Microsoft ML) or a mapped block. P2 chose the second (`Data/areas/evanston-south`, an inland
  Evanston block, and "Wilmette not faked"). Roofs come entirely from the zone profiles and P2's roof assemblies.
- **Dense-city test (Chicago):** pick a residential cell (dense north or greystone) inside one zone box, not the
  Loop. P2's test area `Data/areas/lakeview-sheil-park` fits that. Garages and block families are done (P2);
  still to check against current main: facade LOD / window distance limit and curb resampling. Per-building
  profile selection is needed only if the test area crosses zone boxes.
- **Street trees by zone** (density field + generation) are needed for either test to read as Chicagoland.
- **Profile values:** correct ChatGPT's default storey mixes with the measured shares before adoption, and decide
  the meaning of `smallArea`/`largeArea` (absolute or relative to the local stock).
- **Not yet covered by any data work:** the L tracks and viaducts (railway geometry was not fetched), half-storeys
  (Chicago stores whole storeys only), gangways. (P2 adds rear porches toward mapped alleys.)
