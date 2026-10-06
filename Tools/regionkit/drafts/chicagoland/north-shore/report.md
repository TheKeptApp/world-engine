# Region kit draft: chicagoland / north-shore

**North Shore suburbs pooled (Evanston, Wilmette, Winnetka, Kenilworth)** - drafted 2026-10-05 by `Tools/regionkit` from template `northeast-suburbs` (docs/proposals/regions-v1/regions-draft.json#profiles/northeast-suburbs), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Closest existing vocabulary that is NOT the scored reference: detached 1-2 storey suburban houses with steep gabled (Cape/Colonial-like) and broad ranch families, no alleys assumed (regions-v1 northeast-suburbs). The town profiles in docs/proposals/regions-chicagoland-miami are the comparison references, never templates.

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| evanston-lovelace-park | Lovelace Park | way/23609354 | [42.068, -87.726] | 1 | 26 | 2026-10-06T03:56:50Z | https://overpass-api.de/api/interpreter |
| evanston-smith-park (extra) | Smith Park | way/168243511 | [42.05, -87.693] | 1 | 160 | 2026-10-06T04:27:36Z | https://overpass-api.de/api/interpreter |
| wilmette-vattmann-park | Vattmann Park | way/23609352 | [42.078, -87.714] | 1 | 63 | 2026-10-06T04:05:05Z | https://overpass-api.de/api/interpreter |
| winnetka-village-green | Village Green | way/184364632 | [42.105, -87.729] | 1 | 49 | 2026-10-06T04:05:05Z | https://overpass-api.de/api/interpreter |
| kenilworth-station | Kenilworth | node/7134004731 | [42.087, -87.718] | 1 | 16 | 2026-10-06T04:06:05Z | https://overpass-api.de/api/interpreter |

Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 314 / 0 |
| houses (generator role) | 132 |
| houses with building:levels | 2 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 9 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-north-shore-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 42.078 |
| trees.deciduousShare | template | 0 | 0.85 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 17] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.18 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.5, oval 0.3, spreading 0.2 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 124 | smallArea 39.2, largeArea 231.1, hugeArea 1053.6 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | template | 2 | - | needs >= 30 houses with building:levels |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 0 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | template | 0 | - | needs >= 30 houses with roof:shape |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 1 | - | needs >= 30 houses with building:colour or a coloured building:material |
| houseTypes[].colors[roof] | template | 0 | - | needs >= 30 houses with roof:colour or a coloured roof:material |
| houseTypes[].porch | template | 0 | - | no open data; review visually |
| houseTypes[].windows | template | 0 | - | no open data; review visually |
| houseTypes[].door | template | 0 | - | no open data; review visually |
| houseTypes[].overhang | template | 0 | - | no open data; review visually |
| houseTypes[].parapet | template | 0 | - | no open data; review visually |
| houseTypes[].floors | template | 0 | - | no open data; review visually |
| houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage | template | 0 | - | no open data; review visually |
| houseTypes[].colors[trim/door] | template | 0 | - | no open data; review visually |
| garage.roof | template | 0 | gabled 0.6, hipped 0.1, flat 0.3 | needs >= 20 garages with roof:shape |
| garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters | template | 0 | - | no open data |
| shed | template | 0 | - | no open data |
| chimneyLikelihood | template | 0 | - | no open data |
| foundationMeters | template | 0 | - | no open data |

Calibrated from data: `typeThresholds.smallArea/largeArea/hugeArea`. Everything else is template or rule-based.

## Measurements

- Buildings: 62.8 per km2 (26.4 houses per km2). Roles: block 57% (178), house 42% (132), garage 1% (4).
- building=* values: yes 48% (151), retail 12% (37), house 8% (26), apartments 5% (17), church 5% (17), commercial 4% (13), public 4% (11), roof 2% (8), office 2% (7), residential 2% (6).
- Levels (all buildings, 3% tagged): 1 30% (3), 2 30% (3), 3 20% (2), 5+ 20% (2). Houses: 2 50% (1), 5+ 50% (1).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material brick 100% (1); building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 132 | 51.5 | 111.2 | 151.5 | 191.7 | 246.5 | 1.24-2.13 | 0.892-0.999 |
| garage | 4 | 45.6 | 50.3 | 57.5 | 75.4 | 99.7 | 1.07-1.22 | 0.965-0.999 |
| block | 178 | 190 | 316.7 | 588.5 | 1076.8 | 1990.4 | 1.24-2.25 | 0.768-0.968 |

- Probable garages among generator houses: 8 (6% of houses; 53% of the 15 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=124): footprint n 124, mean 198.4, p10 72.9, p25 121.9, p50 154.7, p75 194.4, p90 247.2; levels 2 50% (1), 5+ 50% (1); facade-to-curb n 121, mean 16.58, p10 8.07, p25 10.9, p50 13.33, p75 18.78, p90 33.85; long side faces street 27%.
- Footprint classes (houses): rectangle 73% (96), orthogonal 21% (28), irregular 3% (4), nearRectangle 3% (4).
- Situations with template thresholds: unknown 72% (95), large 15% (20), small 11% (15), threeFloor 1% (1), twoFloorSquare 1% (1).
- Use mix (non-outbuildings, by count): residential 50% (150), commercial 25% (75), other 15% (44), unknown 11% (32), mixed 0% (1); by footprint area: other 0.26, commercial 0.235, residential 0.203, residential (landuse) 0.131, unknown 0.106, commercial (landuse) 0.031, mixed 0.02, commercial (tags/POI) 0.014.
- Setback (facade to curb, 129 of 132 houses): median 13.55 m, IQR 11.03-20.44 m; centreline 16.88 m median; 0 negative.
- Long side faces the street: 27% of 128 houses with a front edge.
- Coverage proxies: net 0.006 (residential landuse 76% of the cell), gross 0.037; water 0%.
- Alleys: 3.87 km/km2; houses within 30 m of an alley 67%; garages adjacent to an alley 50% (engine alley edge 75%); driveways 0.505 km/km2.
- Barriers per km2 / per 100 houses: fence 0.174 km / 657.7 m, wall 0.0 / 0.0, hedge 0.008 / 29.5, retaining wall 0.006 / 22.3.
- Trees: 9 mapped (1.8 per km2); tree rows 0.0 km/km2; wood 0%, park 4% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 0.745, footway 13.247, path 0.04, residential 9.043, secondary 2.279, secondary_link 0.004, service 7.066, steps 0.028, tertiary 1.724; sidewalks 11.35.

### Tag coverage (% missing)

| tag | buildings (n=314) | houses (n=132) |
|---|---|---|
| building:levels | 97% | 98% |
| height | 100% | 100% |
| roof:shape | 100% | 100% |
| roof:levels | 100% | 100% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 100% | 100% |
| building:material | 100% | 99% |
| building:colour | 100% | 100% |
| start_date | 100% | 99% |

### Family signature hints

Principal houses (generator houses minus probable garages): -% 1-storey, 50% 2-storey, 50% 3+ (of 2 houses with levels, 2% of houses); footprints p25-p75 121.9-194.4 m2 (median 154.7); aspect p25-p75 1.32-2.18; rectangle short side p25-p75 8.0-11.3 m, long side 13.5-20.3 m; long side faces the street on 27% of houses (narrow end to the street on 73%); 8 generator 'houses' (6%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 13.33 m (IQR 10.9-18.78).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 9.0 km away (elev 192.0 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 9.0 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -4.28 | -2.5 | 2.78 | 8.44 | 14.39 | 19.94 | 23 | 22.33 | 18.28 | 11.5 | 4.89 | -1.17 |
| precip mm | 53.3 | 50.3 | 57.4 | 101.6 | 122.9 | 109.5 | 95 | 105.7 | 90.4 | 91.2 | 66.8 | 59.4 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 9.8 C, MAP 1003.5 mm, warmest 23.0 C, coldest -4.28 C, Pthreshold 33.6 mm.

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| evanston-lovelace-park | wilmette-inland-review | wilmette | - | NO | wilmette 0.72, generic-temperate-v1 0.28 | wilmette-inland-review 72% |
| evanston-smith-park | evanston-inland-review | evanston | - | NO | evanston 0.98, generic-temperate-v1 0.02 | evanston-inland-review 98% |
| wilmette-vattmann-park | wilmette-inland-review | wilmette | - | NO | wilmette 0.56, generic-temperate-v1 0.44 | wilmette-inland-review 56% |
| winnetka-village-green | (none: defaultProfile) | generic-temperate-v1 | - | NO | generic-temperate-v1 0.59, winnetka 0.41 | winnetka-inland-review 41% |
| kenilworth-station | kenilworth-inland-review | kenilworth | - | NO | kenilworth 0.529, generic-temperate-v1 0.33, wilmette 0.141 | wilmette-inland-review 14%, kenilworth-inland-review 60% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| evanston-inland-review | evanston | 0.98 | 163.2 | 0.55 | 0.444 | 144.6 | 0.75 (4) |
| wilmette-inland-review | wilmette | 1.417 | 11.3 | 0.375 | 0.625 | 127.2 | 0 (1) |
| winnetka-inland-review | winnetka | 0.409 | 117.4 | 0.25 | 0.729 | 152 | 0 (3) |
| kenilworth-inland-review | kenilworth | 0.604 | 18.2 | 0.091 | 0.909 | 234.5 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Generator support for the reference families' identity (cross-gables, dormers, steep Tudor roofs with chimneys, broad Prairie eaves, turrets): the profiles now name them, but BuildingGenerator renders one gabled/hipped/flat roof per rectangle; raised ranch / split-level (half-levels are rounded by the generator); courtyard apartments (role block always takes the first flat-roof type).
- Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan.
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 98% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
