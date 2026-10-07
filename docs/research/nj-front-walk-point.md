# Proposal for Neighborhood Jobs: deliver to a "front walk point" instead of the front door (2026-10-07)

Report only. Nothing was changed in neighborhood-jobs; NJ decides. Numbers come from NJ's own route generator
(`DailyRouteService`, read-only scratch copy of neighborhood-jobs at b92fdc6) run on WorldEngine's map layer exports.

## Problem

Paper and Pizza need a confident front door (NJ's floor is 0.7). WorldEngine's front-door confidence is **0.36**:
the wall is right for 51 of 58 checked houses, but the position along it is a seeded pick from the regional house type,
and no open source in these areas says where entrances are (`docs/research/door-sources.md`: city, county and Overture
address points sit at building centroids; OSM has no mapped house walks). So no Paper or Pizza route can start in any of
the three test areas today.

## Proposal

Let Paper and Pizza deliver to a **front walk point**: the point on the house's frontage street opposite its door, at
the curb or sidewalk edge, i.e. the frontage segment at `offsetM`, set back to the house's `side` by half the carriageway
plus 1.5 m. What makes a delivery right is then "the right house, from its own street", and that is what the frontage
confidence already measures (the share of houses whose frontage street is their addressed street: 0.99 for houses that
are not on a corner, 0.84 overall; `docs/research/map-confidence.md`). The point's position along the street inherits
the door's ±½-wall uncertainty, which stays inside the house's own street frontage.

Two ways to carry it, NJ's choice:

1. **NJ computes it** from the existing contract: `buildings[].frontage` (segment, `offsetM`, `side`, `confidence`)
   plus the segment's geometry and `widthM`. No contract change.
2. **WorldEngine exports it** as a new entry kind (e.g. `front_walk`) with the frontage confidence. Adding a value to
   the closed `kind` enumeration is a breaking change under the contract's §14, so this needs NJ's agreement.

## Route counts with the walk point at the 0.7 floor

Seven days (2026-10-05 … 11) per tier; "ok" = days a route was generated. Today = the current door (0.36).

| Area | Job | Today | With the walk point | Remaining failures |
|---|---|---|---|---|
| Sloan's Lake (Denver) | Paper (short / standard / long / rush) | 0 / 0 / 0 / 0 | **5 / 5 / 5 / 5** | major-road cap on 2 days |
| | Pizza | 0 / 0 / 0 / 0 | **7 / 7 / 6 / 6** | major-road cap |
| Evanston South | Paper | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | insufficient subscribers (NJ's dwelling rules) |
| | Pizza | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | insufficient orders |
| Lakeview (Chicago) | Paper | 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 | insufficient subscribers |
| | Pizza | 0 / 0 / 0 / 0 | **4 / 7 / 7 / 7** | major-road cap on 3 days (short) |

Lawn is unchanged by this (it uses lots): Sloan's Lake 0 / 2 / 5 / 5, Evanston 0 / 0 / 2 / 4, Lakeview none.

Households whose frontage is below 0.7 (corner houses facing the "wrong" street) stay excluded: 242 of 1,399 in Sloan's
Lake, 108 of 887 in Evanston, 289 of 2,823 in Lakeview.

## Not explained by doors

In Evanston and Lakeview Paper still finds too few subscribers (and Evanston Pizza too few orders) with confident
delivery points. That is NJ's customer selection (its dwelling-type list R-06 and subscriber rules), not WorldEngine's
data: most houses there are mapped `building=yes` in OSM (2,000 of the 2,881 checked frontages), which NJ may not count
as dwellings. Worth checking on NJ's side; WorldEngine exports the raw `building` value and can add the generator's own
classification (house vs garage) if NJ wants it.

## How the counts were made

`scratchpad/walkpoint.py` copied each export and moved every house's `front_door` entry to its frontage walk point with
the frontage confidence (3,062 points), re-hashed `map/entries.json` in world.json, and NJ's `WERealExportTests` harness
ran the reader, adapter and `DailyRouteService` on the copies. Nothing of this is in a shipped package.
