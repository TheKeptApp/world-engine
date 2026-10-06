# Region kit draft: miami / residential

**Miami residential pooled (Coral Gables, Miami Shores)** - drafted 2026-10-05 by `Tools/regionkit` from template `desert-southwest` (docs/proposals/regions-v1/regions-draft.json#profiles/desert-southwest), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Nearest warm-climate vocabulary: stucco walls, low hipped/gabled ranches, a flat-roof modern family and a terracotta roof colour slot. Not a desert, so its tree priors (and gravel yards in the proposal) are wrong for Miami and must be reviewed.

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| coral-gables-venetian-pool | Venetian Pool | way/297000205 | [25.746, -80.273] | 1 | 621 | 2026-10-06T04:21:33Z | https://overpass-api.de/api/interpreter |
| miami-shores-village-hall | Miami Shores Village Hall | node/367826075 | [25.868, -80.194] | 1 | 674 | 2026-10-06T04:21:33Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 1295 / 24 |
| houses (generator role) | 670 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 1 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | miami-residential-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 25.807; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW |
| trees.deciduousShare | template | 0 | 0.98 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [5, 10] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.3 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.15, oval 0.2, spreading 0.65 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [2.5, 5] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 642 | smallArea 32.3, largeArea 235.7, hugeArea 282 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | template | 0 | - | needs >= 30 houses with building:levels |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 0 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | template | 0 | - | needs >= 30 houses with roof:shape |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 0 | - | needs >= 30 houses with building:colour or a coloured building:material |
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

- Buildings: 647.5 per km2 (335.0 houses per km2). Roles: house 52% (670), block 48% (625).
- building=* values: yes 99% (1281), residential 1% (8), terrace 0% (3), apartments 0% (1), detached 0% (1), house 0% (1).
- Levels (all buildings, 0% tagged): -. Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 639, mean 4.78, p10 3.3, p25 4, p50 4.4, p75 5.05, p90 7.2; blocks: n 603, mean 6.31, p10 4.1, p25 4.4, p50 4.9, p75 6.9, p90 8.98.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 670 | 49.5 | 137.3 | 188.5 | 221.5 | 238.5 | 1.11-1.56 | 0.733-0.917 |
| block | 625 | 262.9 | 281.9 | 330.6 | 405.9 | 522.6 | 1.12-1.59 | 0.665-0.827 |

- Probable garages among generator houses: 28 (4% of houses; 32% of the 89 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=642): footprint n 642, mean 181.1, p10 60.9, p25 147.8, p50 191.2, p75 222.4, p90 238.9; levels -; facade-to-curb n 642, mean 16.57, p10 10.74, p25 12.67, p50 14.79, p75 16.64, p90 31.01; long side faces street 53%.
- Footprint classes (houses): orthogonal 71% (477), rectangle 27% (179), irregular 2% (12), nearRectangle 0% (2).
- Situations with template thresholds: unknown 60% (403), large 27% (178), small 13% (89).
- Use mix (non-outbuildings, by count): unknown 97% (1254), residential 2% (33), commercial 1% (8); by footprint area: unknown 0.924, commercial (tags/POI) 0.032, residential 0.027, residential (landuse) 0.017.
- Setback (facade to curb, 670 of 670 houses): median 14.97 m, IQR 12.75-16.93 m; centreline 18.42 m median; 0 negative.
- Long side faces the street: 53% of 670 houses with a front edge.
- Coverage proxies: net 0.097 (residential landuse 2% of the cell), gross 0.181; water 0%.
- Alleys: 5.002 km/km2; houses within 30 m of an alley 58%; garages adjacent to an alley -% (engine alley edge -%); driveways 0.158 km/km2.
- Barriers per km2 / per 100 houses: fence 0.24 km / 71.8 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 1 mapped (0.5 per km2); tree rows 0.0 km/km2; wood 0%, park 1% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): footway 15.062, path 0.015, residential 11.749, secondary 1.359, service 6.972, tertiary 3.343, tertiary_link 0.143, unclassified 0.043; sidewalks 14.115.

### Tag coverage (% missing)

| tag | buildings (n=1295) | houses (n=670) |
|---|---|---|
| building:levels | 100% | 100% |
| height | 4% | 5% |
| roof:shape | 100% | 100% |
| roof:levels | 100% | 100% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 100% | 100% |
| building:material | 100% | 100% |
| building:colour | 100% | 100% |
| start_date | 100% | 100% |

### Family signature hints

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 147.8-222.4 m2 (median 191.2); aspect p25-p75 1.12-1.56; rectangle short side p25-p75 10.6-15.4 m, long side 15.3-19.9 m; long side faces the street on 53% of houses (narrow end to the street on 47%); 28 generator 'houses' (4%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 14.79 m (IQR 12.67-16.64).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00083909 HIALEAH, FL US, 5.4 km away (elev 3.7 m). Snow: USC00083909 HIALEAH, FL US, 5.4 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | 19.67 | 21 | 22.28 | 24.39 | 26.17 | 27.78 | 28.5 | 28.61 | 27.83 | 26.22 | 23.28 | 21.22 |
| precip mm | 51.6 | 58.2 | 71.4 | 96.8 | 154.4 | 290.8 | 201.2 | 253.5 | 292.9 | 209 | 101.6 | 71.1 |
| snow mm | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Koppen-Geiger: **Am** (0 C C/D threshold; Am with the -3 C variant). MAT 24.75 C, MAP 1852.5 mm, warmest 28.61 C, coldest 19.67 C, Pthreshold 63.5 mm.

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| coral-gables-venetian-pool | coral-gables-inland-review | coral-gables | - | NO | coral-gables 1 | coral-gables-inland-review 100% |
| miami-shores-village-hall | miami-shores-inland-review | miami-shores | - | NO | miami-shores 1 | miami-shores-inland-review 100% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| coral-gables-inland-review | coral-gables | 1 | 621 | 0.378 | 0.622 | 187.6 | - (0) |
| miami-shores-inland-review | miami-shores | 1 | 674 | 0.645 | 0.355 | 189.8 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- `seasons`: meteorological seasons from latitude 25.807; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW
- Still missing (needs generator work, not data): palms: no tree archetype (the generator draws conifer or a broadleaf crown); evergreen broadleaf leaf habit is not expressible (deciduousShare is a non-conifer share); barrel-tile roof identity (only colour; no tile eave/ridge geometry); low-rise condo / balcony bands (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
