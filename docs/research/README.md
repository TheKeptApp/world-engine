# Research: regions, data coverage and licensing

Groundwork for phase 5B (Chicagoland test region) and for adding regions later. Written 2026-10-06 in a
session parallel to phase 5A; nothing here changes the engine, the renderers, the profiles or the package
format. All OSM-derived numbers: © OpenStreetMap contributors (ODbL 1.0).

| Document | What it answers |
|---|---|
| [region-kit.md](region-kit.md) | The region kit (`Tools/regionkit/`): what it measures, how to run it, accuracy against the hand-made profiles (Denver, Plano, ChatGPT's 11 Chicagoland/Miami profiles), the zone drafts, zones in the schema, what open data can't supply |
| [data-coverage.md](data-coverage.md) | 46 sample cells (North Shore, Chicago, 11 metros): what OSM and Overture hold, the ranked gaps and how the generator should handle each, the dense-Chicago triangle estimate |
| [licensing.md](licensing.md) | Licensing and attribution checklist (OSM/ODbL, Overture, WeatherKit, HYG stars, Fab), blockers, questions for a lawyer. Not legal advice |
| [live-feeds.md](live-feeds.md) | Live transit (Metra, CTA, Pace, RTD) and aircraft feeds: endpoints, limits, terms, attribution, cost; a small relay design (phones never hold keys) and monthly cost at 1k / 10k users. Research only, no app code |

Tools: [`Tools/regionkit/`](../../Tools/regionkit/README.md) (region kit; drafts in `Tools/regionkit/drafts/`) and
[`Tools/regionkit/audit/`](../../Tools/regionkit/audit/README.md) (coverage audit). Both are offline Python research
tools; nothing is loaded at runtime. No raw map data is committed, only aggregates.

## Findings that cut across the three documents

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
4. **Three generator behaviours matter more than any profile value:** one profile per baked area; `block`
   buildings never enter the house-type lottery (so apartment, courtyard and tower families can't be chosen);
   small `building=yes` footprints by the alleys, very likely detached garages, become houses with doors and
   porches: 30–44 % of the generator's "houses" in three Chicago zones (region kit's heuristic; the audit's
   simpler size-only count gives 28 % of all buildings).
5. **Dense Chicago breaks the triangle budget at full detail** (estimate, nothing built): a whole Loop cell is
   2.2 M static triangles, 97 % of its building triangles are window frames, and curbs cost 12 triangles per
   street metre. Residential cells fit on average but not in the worst views. Facade LOD has to come before
   floors-from-height or towers.
6. **Mapped trees are rare** in most places: 78 per km² in Chicago neighbourhoods,
   0.5 on the North Shore, against 2,812 at Sloan's Lake. The generator places only mapped trees, so
   Chicagoland streets would be nearly treeless.
7. **Live feeds:** transit data is free but every licence is revocable. RTD is the easiest (no key, redistribution
   granted). CTA limits the purpose ("assisting" riders), Pace's static data is "non commercial use" and its live URLs are
   undocumented, and Metra's terms require a relay (unverified: metra.com blocks automated access). Community
   aircraft feeds are non-commercial except adsb.lol (ODbL, ask the operator); commercial aircraft feeds cost about
   $1.6k–18k a month for two metros. Upstream cost scales with active areas and poll interval, not users.
8. **Licensing:** nothing blocks internal development. Before a public release: a credits screen with the ODbL
   "offer", credit burned into exported images/widgets, and Apple Weather attribution. The world package is most
   likely an ODbL Derivative Database, not a Produced Work as `docs/plan-m1.md` §6 assumes.

## Zones

The existing `RegionCatalog` (ordered boxes, first match wins, several boxes per profile) already holds
several zones per region; ChatGPT's catalog uses it with 18 boxes. No schema change is proposed. Real gaps,
each with its smallest fix, are in [region-kit.md §5](region-kit.md#5-zones): per-building profile selection,
block dispatch through the type lottery, a garage role rule, and data-only box fixes. One schema-level gap
stands: profiles have no tree-density field, and generated street trees need one
([data-coverage.md, gap 4](data-coverage.md#biggest-gaps-ranked-and-what-the-generator-should-do)).

## What this means for phase 5B

- **Suburban test (North Shore):** needs a second footprint source (Overture buildings, ODbL, with heights from
  USGS lidar or Microsoft ML) or a different, mapped suburb. Roofs come entirely from the zone profiles.
- **Dense-city test (Chicago):** pick a residential cell (dense north or greystone) inside one zone box, not the
  Loop. Before it: the garage role rule, block dispatch, facade LOD/window distance limit and curb resampling.
  Per-building profile selection is needed only if the test area crosses zone boxes.
- **Street trees by zone** (density field + generation) are needed for either test to read as Chicagoland.
- **Profile values:** correct ChatGPT's default storey mixes with the measured shares before adoption, and decide
  the meaning of `smallArea`/`largeArea` (absolute or relative to the local stock).
- **Not yet covered by any data work:** the L tracks and viaducts (railway geometry was not fetched), half-storeys
  (Chicago stores whole storeys only), rear porches and gangways.
