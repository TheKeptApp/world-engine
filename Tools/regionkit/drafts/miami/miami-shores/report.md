# Region kit draft: miami / miami-shores

**Miami Shores** - drafted 2026-10-05 by `Tools/regionkit` from template `desert-southwest` (docs/proposals/regions-v1/regions-draft.json#profiles/desert-southwest), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Nearest warm-climate vocabulary: stucco walls, low hipped/gabled ranches, a flat-roof modern family and a terracotta roof colour slot. Not a desert, so its tree priors (and gravel yards in the proposal) are wrong for Miami and must be reviewed.

Comparison reference: `miami-shores` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| miami-shores-village-hall | Miami Shores Village Hall | node/367826075 | [25.868, -80.194] | 1 | 674 | 2026-10-06T04:21:33Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 674 / 0 |
| houses (generator role) | 435 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 0 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | miami-miami-shores-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 25.868; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW |
| trees.deciduousShare | template | 0 | 0.98 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [5, 10] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.3 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.15, oval 0.2, spreading 0.65 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [2.5, 5] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 408 | smallArea 60.6, largeArea 234.7, hugeArea 256.2 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
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

- Buildings: 674.0 per km2 (435.0 houses per km2). Roles: house 64% (435), block 36% (239).
- building=* values: yes 99% (666), residential 1% (8).
- Levels (all buildings, 0% tagged): -. Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 411, mean 4.59, p10 3.4, p25 4, p50 4.4, p75 4.9, p90 5.9; blocks: n 227, mean 5.45, p10 4.1, p25 4.3, p50 4.7, p75 5.3, p90 8.08.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 435 | 77.7 | 152.3 | 189.8 | 219.5 | 237.8 | 1.1-1.48 | 0.719-0.885 |
| block | 239 | 259.7 | 272.8 | 298.7 | 354 | 446.2 | 1.09-1.55 | 0.693-0.846 |

- Probable garages among generator houses: 27 (6% of houses; 77% of the 35 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=408): footprint n 408, mean 187, p10 132, p25 163, p50 193.1, p75 221.3, p90 238.5; levels -; facade-to-curb n 408, mean 15.05, p10 10.96, p25 12.98, p50 15.12, p75 16.28, p90 17.52; long side faces street 57%.
- Footprint classes (houses): orthogonal 77% (333), rectangle 22% (94), irregular 2% (8).
- Situations with template thresholds: unknown 67% (292), large 25% (108), small 8% (35).
- Use mix (non-outbuildings, by count): unknown 98% (658), commercial 1% (8), residential 1% (8); by footprint area: unknown 0.917, commercial (tags/POI) 0.07, residential 0.013.
- Setback (facade to curb, 435 of 435 houses): median 15.22 m, IQR 13.03-16.52 m; centreline 18.63 m median; 0 negative.
- Long side faces the street: 57% of 435 houses with a front edge.
- Coverage proxies: net - (residential landuse 0% of the cell), gross 0.168; water 0%.
- Alleys: 9.182 km/km2; houses within 30 m of an alley 88%; garages adjacent to an alley -% (engine alley edge -%); driveways 0.15 km/km2.
- Barriers per km2 / per 100 houses: fence 0.0 km / 0.0 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 0 mapped (0.0 per km2); tree rows 0.0 km/km2; wood 0%, park 0% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): footway 6.009, residential 12.301, secondary 2.718, service 11.756, tertiary 1.512, tertiary_link 0.147; sidewalks 5.326.

### Tag coverage (% missing)

| tag | buildings (n=674) | houses (n=435) |
|---|---|---|
| building:levels | 100% | 100% |
| height | 5% | 6% |
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

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 163.0-221.3 m2 (median 193.1); aspect p25-p75 1.1-1.48; rectangle short side p25-p75 11.5-15.7 m, long side 16.0-19.5 m; long side faces the street on 57% of houses (narrow end to the street on 43%); 27 generator 'houses' (6%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 15.12 m (IQR 12.98-16.28).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00092811 MIAMI BEACH, FL US, 9.1 km away (elev 0.3 m). Snow: USW00092811 MIAMI BEACH, FL US, 9.1 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | 19.67 | 20.56 | 21.61 | 23.72 | 25.67 | 27.39 | 28.28 | 28.39 | 27.83 | 26.11 | 23.22 | 21.28 |
| precip mm | 59.2 | 57.7 | 62.7 | 87.4 | 125.5 | 197.1 | 151.9 | 190.8 | 214.6 | 164.8 | 83.6 | 57.1 |
| snow mm | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Koppen-Geiger: **Am** (0 C C/D threshold; Am with the -3 C variant). MAT 24.48 C, MAP 1452.4 mm, warmest 28.39 C, coldest 19.67 C, Pthreshold 63.0 mm.

## Accuracy check against `miami-shores`

Score = agree / (agree + differ) = **0.667** (2 agree, 1 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.34/0.53/0.14 | 0.34/0.51/0.15 | TVD 0.012 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | - | - | - | 0.15 | 0 | not measurable |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 23.1 | 17.9 | /d/ 5.2 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 60.6 | 60 | rel 0.01 | 0.15 | 408 | agree |
| typeThresholds.largeArea m2 | 234.7 | 220 | rel 0.07 | 0.15 | 408 | agree |
| typeThresholds.hugeArea m2 | 256.2 | 350 | rel 0.27 | 0.15 | 408 | differ |
| trees.deciduousShare (non-conifer share) | 0.98 | 0.98 | /d/ 0.000 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [5, 10] | [8, 15] | /d/ 4.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.3 | 0.18 | /d/ 0.120 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #CCB697 | #D5C5B1 | dE00 5.4 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #96816E | #9D7A66 | dE00 5.7 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

2 supported, 1 contradicted, 9 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.34/0.51/0.15 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | - | - | 0 | 30 | - | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 0%) |
| trees.deciduousShare vs broadleaved share | 0.98 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 60.6 | 408 | 30 | rel 0.01 | 0.15 | supports | share of zone houses below the reference value: 0.020 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 235.8 | 408 | 30 | rel 0.07 | 0.15 | supports | share of zone houses below the reference value: 0.735 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 249.3 | 408 | 30 | rel 0.29 | 0.15 | contradicts | share of zone houses below the reference value: 0.995 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 17.9 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #D5C5B1 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #9D7A66 | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| miami-shores-village-hall | miami-shores-inland-review | miami-shores | miami-shores | yes | miami-shores 1 | miami-shores-inland-review 100% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| miami-shores-inland-review | miami-shores | 1 | 674 | 0.645 | 0.355 | 189.8 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- `seasons`: meteorological seasons from latitude 25.868; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW
- Still missing (needs generator work, not data): palms: no tree archetype (the generator draws conifer or a broadleaf crown); evergreen broadleaf leaf habit is not expressible (deciduousShare is a non-conifer share); barrel-tile roof identity (only colour; no tile eave/ridge geometry); low-rise condo / balcony bands (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
