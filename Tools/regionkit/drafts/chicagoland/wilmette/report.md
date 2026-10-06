# Region kit draft: chicagoland / wilmette

**Wilmette (North Shore)** - drafted 2026-10-05 by `Tools/regionkit` from template `northeast-suburbs` (docs/proposals/regions-v1/regions-draft.json#profiles/northeast-suburbs), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Closest existing vocabulary that is NOT the scored reference: detached 1-2 storey suburban houses with steep gabled (Cape/Colonial-like) and broad ranch families, no alleys assumed (regions-v1 northeast-suburbs). The town profiles in docs/proposals/regions-chicagoland-miami are the comparison references, never templates.

Comparison reference: `wilmette` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| wilmette-vattmann-park | Vattmann Park | way/23609352 | [42.078, -87.714] | 1 | 63 | 2026-10-06T04:05:05Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 63 / 0 |
| houses (generator role) | 24 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 0 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-wilmette-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 42.078 |
| trees.deciduousShare | template | 0 | 0.85 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 17] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.18 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.5, oval 0.3, spreading 0.2 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | template | 24 | smallArea 60, largeArea 220, hugeArea 350 |  |
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

Calibrated from data: nothing. Everything else is template or rule-based.

## Measurements

- Buildings: 63.0 per km2 (24.0 houses per km2). Roles: block 60% (38), house 38% (24), garage 2% (1).
- building=* values: yes 44% (28), retail 21% (13), roof 6% (4), office 5% (3), public 5% (3), residential 5% (3), apartments 3% (2), church 3% (2), fire_station 2% (1), garage 2% (1).
- Levels (all buildings, 5% tagged): 1 33% (1), 2 33% (1), 3 33% (1). Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 24 | 106.8 | 132.9 | 161.6 | 205.1 | 346.1 | 1.5-1.88 | 0.866-0.961 |
| garage | 1 | 115.8 | 115.8 | 115.8 | 115.8 | 115.8 | 1.19-1.19 | 0.998-0.998 |
| block | 38 | 175.5 | 293.9 | 452.3 | 1049.4 | 2189.3 | 1.3-2.05 | 0.807-0.965 |

- Probable garages among generator houses: 0 (0% of houses; 0% of the 1 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=24): footprint n 24, mean 190.2, p10 106.8, p25 132.9, p50 161.6, p75 205.1, p90 346.1; levels -; facade-to-curb n 24, mean 16.34, p10 8.82, p25 11.51, p50 14.52, p75 17.9, p90 23.98; long side faces street 22%.
- Footprint classes (houses): rectangle 54% (13), orthogonal 42% (10), nearRectangle 4% (1).
- Situations with template thresholds: unknown 71% (17), large 25% (6), small 4% (1).
- Use mix (non-outbuildings, by count): residential 47% (27), commercial 34% (20), other 16% (9), mixed 2% (1), unknown 2% (1); by footprint area: commercial 0.358, other 0.294, residential (landuse) 0.116, mixed 0.094, residential 0.094, commercial (landuse) 0.037, commercial (tags/POI) 0.006, unknown 0.001.
- Setback (facade to curb, 24 of 24 houses): median 14.52 m, IQR 11.51-17.9 m; centreline 17.58 m median; 0 negative.
- Long side faces the street: 22% of 23 houses with a front edge.
- Coverage proxies: net 0.005 (residential landuse 78% of the cell), gross 0.04; water 0%.
- Alleys: 6.789 km/km2; houses within 30 m of an alley 38%; garages adjacent to an alley 100% (engine alley edge 100%); driveways 0.549 km/km2.
- Barriers per km2 / per 100 houses: fence 0.0 km / 0.0 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 0 mapped (0.0 per km2); tree rows 0.0 km/km2; wood 0%, park 4% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 0.962, footway 10.403, path 0.086, residential 9.982, secondary 1.707, service 9.941, steps 0.006, tertiary 0.973; sidewalks 9.126.

### Tag coverage (% missing)

| tag | buildings (n=63) | houses (n=24) |
|---|---|---|
| building:levels | 95% | 100% |
| height | 100% | 100% |
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

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 132.9-205.1 m2 (median 161.6); aspect p25-p75 1.5-1.88; rectangle short side p25-p75 8.9-10.8 m, long side 15.6-19.4 m; long side faces the street on 22% of houses (narrow end to the street on 78%); facade-to-curb median 14.52 m (IQR 11.51-17.9).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 9.1 km away (elev 192.0 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 9.1 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -4.28 | -2.5 | 2.78 | 8.44 | 14.39 | 19.94 | 23 | 22.33 | 18.28 | 11.5 | 4.89 | -1.17 |
| precip mm | 53.3 | 50.3 | 57.4 | 101.6 | 122.9 | 109.5 | 95 | 105.7 | 90.4 | 91.2 | 66.8 | 59.4 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 9.8 C, MAP 1003.5 mm, warmest 23.0 C, coldest -4.28 C, Pthreshold 33.6 mm.

## Accuracy check against `wilmette`

Score = agree / (agree + differ) = **-** (0 agree, 0 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.94/0.06/0.01 | 0.63/0.32/0.05 | TVD 0.303 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | - | - | - | 0.15 | 0 | not measurable |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 35.6 | 34.4 | /d/ 1.2 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 60 | 60 | rel 0.00 | 0.15 | 24 | not measurable |
| typeThresholds.largeArea m2 | 220 | 260 | rel 0.15 | 0.15 | 24 | not measurable |
| typeThresholds.hugeArea m2 | 350 | 420 | rel 0.17 | 0.15 | 24 | not measurable |
| trees.deciduousShare (non-conifer share) | 0.85 | 0.92 | /d/ 0.070 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [9, 17] | [11, 19] | /d/ 2.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.18 | 0.18 | /d/ 0.000 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B4B5A8 | #B19781 | dE00 14.4 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #636970 | #616569 | dE00 2.2 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

0 supported, 0 contradicted, 12 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.63/0.32/0.05 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | - | - | 0 | 30 | - | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 0%) |
| trees.deciduousShare vs broadleaved share | 0.92 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [11, 19] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 44.4 | 24 | 30 | rel 0.26 | 0.15 | can't test | share of zone houses below the reference value: 0.042 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 260 | 245.7 | 24 | 30 | rel 0.06 | 0.15 | can't test | share of zone houses below the reference value: 0.875 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 420 | 484.3 | 24 | 30 | rel 0.15 | 0.15 | can't test | share of zone houses below the reference value: 0.917 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 34.4 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B19781 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #616569 | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| wilmette-vattmann-park | wilmette-inland-review | wilmette | wilmette | yes | wilmette 0.56, generic-temperate-v1 0.44 | wilmette-inland-review 56% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| wilmette-inland-review | wilmette | 0.558 | 5.4 | 0.333 | 0.667 | 29.8 | 0 (1) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.smallArea/largeArea/hugeArea`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Generator support for the reference families' identity (cross-gables, dormers, steep Tudor roofs with chimneys, broad Prairie eaves, turrets): the profiles now name them, but BuildingGenerator renders one gabled/hipped/flat roof per rectangle; raised ranch / split-level (half-levels are rounded by the generator); courtyard apartments (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
