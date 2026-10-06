# Region kit draft: chicagoland / kenilworth

**Kenilworth (North Shore)** - drafted 2026-10-05 by `Tools/regionkit` from template `northeast-suburbs` (docs/proposals/regions-v1/regions-draft.json#profiles/northeast-suburbs), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Closest existing vocabulary that is NOT the scored reference: detached 1-2 storey suburban houses with steep gabled (Cape/Colonial-like) and broad ranch families, no alleys assumed (regions-v1 northeast-suburbs). The town profiles in docs/proposals/regions-chicagoland-miami are the comparison references, never templates.

Comparison reference: `kenilworth` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| kenilworth-station | Kenilworth | node/7134004731 | [42.087, -87.718] | 1 | 16 | 2026-10-06T04:06:05Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 16 / 0 |
| houses (generator role) | 1 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 0 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-kenilworth-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 42.087 |
| trees.deciduousShare | template | 0 | 0.85 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 17] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.18 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.5, oval 0.3, spreading 0.2 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | template | 1 | smallArea 60, largeArea 220, hugeArea 350 |  |
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

- Buildings: 16.0 per km2 (1.0 houses per km2). Roles: block 94% (15), house 6% (1).
- building=* values: retail 31% (5), yes 19% (3), church 12% (2), public 12% (2), commercial 6% (1), house 6% (1), school 6% (1), train_station 6% (1).
- Levels (all buildings, 0% tagged): -. Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 1 | 234.5 | 234.5 | 234.5 | 234.5 | 234.5 | 1.3-1.3 | 0.89-0.89 |
| block | 15 | 317.3 | 356.2 | 419.4 | 859 | 1089.4 | 1.07-1.8 | 0.698-0.913 |

- Probable garages among generator houses: 0 (0% of houses; -% of the 0 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=1): footprint n 1, mean 234.5, p10 234.5, p25 234.5, p50 234.5, p75 234.5, p90 234.5; levels -; facade-to-curb n 1, mean 15.84, p10 15.84, p25 15.84, p50 15.84, p75 15.84, p90 15.84; long side faces street 0%.
- Footprint classes (houses): nearRectangle 100% (1).
- Situations with template thresholds: large 100% (1).
- Use mix (non-outbuildings, by count): commercial 56% (9), other 38% (6), residential 6% (1); by footprint area: other 0.623, commercial 0.279, commercial (tags/POI) 0.055, commercial (landuse) 0.026, residential 0.017.
- Setback (facade to curb, 1 of 1 houses): median 15.84 m, IQR 15.84-15.84 m; centreline 18.84 m median; 0 negative.
- Long side faces the street: 0% of 1 houses with a front edge.
- Coverage proxies: net 0 (residential landuse 83% of the cell), gross 0.014; water 0%.
- Alleys: 2.112 km/km2; houses within 30 m of an alley 0%; garages adjacent to an alley -% (engine alley edge -%); driveways 0.273 km/km2.
- Barriers per km2 / per 100 houses: fence 0.0 km / 0.0 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.029 / 2942.0.
- Trees: 0 mapped (0.0 per km2); tree rows 0.0 km/km2; wood 0%, park 3% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 0.572, footway 10.357, residential 10.88, secondary 1.184, service 3.339, tertiary 1.659; sidewalks 9.401.

### Tag coverage (% missing)

| tag | buildings (n=16) | houses (n=1) |
|---|---|---|
| building:levels | 100% | 100% |
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

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 234.5-234.5 m2 (median 234.5); aspect p25-p75 1.3-1.3; rectangle short side p25-p75 14.2-14.2 m, long side 18.5-18.5 m; long side faces the street on 0% of houses (narrow end to the street on 100%); facade-to-curb median 15.84 m (IQR 15.84-15.84).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 8.1 km away (elev 192.0 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 8.1 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -4.28 | -2.5 | 2.78 | 8.44 | 14.39 | 19.94 | 23 | 22.33 | 18.28 | 11.5 | 4.89 | -1.17 |
| precip mm | 53.3 | 50.3 | 57.4 | 101.6 | 122.9 | 109.5 | 95 | 105.7 | 90.4 | 91.2 | 66.8 | 59.4 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 9.8 C, MAP 1003.5 mm, warmest 23.0 C, coldest -4.28 C, Pthreshold 33.6 mm.

## Accuracy check against `kenilworth`

Score = agree / (agree + differ) = **-** (0 agree, 0 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.96/0.04/0.00 | 0.65/0.30/0.05 | TVD 0.304 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | - | - | - | 0.15 | 0 | not measurable |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 36.4 | 35.9 | /d/ 0.6 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 60 | 60 | rel 0.00 | 0.15 | 1 | not measurable |
| typeThresholds.largeArea m2 | 220 | 260 | rel 0.15 | 0.15 | 1 | not measurable |
| typeThresholds.hugeArea m2 | 350 | 420 | rel 0.17 | 0.15 | 1 | not measurable |
| trees.deciduousShare (non-conifer share) | 0.85 | 0.92 | /d/ 0.070 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [9, 17] | [12, 20] | /d/ 3.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.18 | 0.18 | /d/ 0.000 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B5B5A8 | #B29982 | dE00 13.3 | 10 | 0 | not measurable |
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
| house roof mix G/H/F vs roof:shape | 0.65/0.30/0.05 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | - | - | 0 | 30 | - | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 0%) |
| trees.deciduousShare vs broadleaved share | 0.92 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [12, 20] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 234.5 | 1 | 30 | rel 2.91 | 0.15 | can't test | share of zone houses below the reference value: 0.000 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 260 | 234.5 | 1 | 30 | rel 0.10 | 0.15 | can't test | share of zone houses below the reference value: 1.000 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 420 | 234.5 | 1 | 30 | rel 0.44 | 0.15 | can't test | share of zone houses below the reference value: 1.000 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 35.9 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B29982 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #616569 | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| kenilworth-station | kenilworth-inland-review | kenilworth | kenilworth | yes | kenilworth 0.529, generic-temperate-v1 0.33, wilmette 0.141 | wilmette-inland-review 14%, kenilworth-inland-review 60% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| wilmette-inland-review | wilmette | 0.137 | 7.3 | 0 | 1 | - | - (0) |
| kenilworth-inland-review | kenilworth | 0.604 | 18.2 | 0.091 | 0.909 | 234.5 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.smallArea/largeArea/hugeArea`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Generator support for the reference families' identity (cross-gables, dormers, steep Tudor roofs with chimneys, broad Prairie eaves, turrets): the profiles now name them, but BuildingGenerator renders one gabled/hipped/flat roof per rectangle; raised ranch / split-level (half-levels are rounded by the generator); courtyard apartments (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
