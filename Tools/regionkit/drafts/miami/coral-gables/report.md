# Region kit draft: miami / coral-gables

**Coral Gables** - drafted 2026-10-05 by `Tools/regionkit` from template `desert-southwest` (docs/proposals/regions-v1/regions-draft.json#profiles/desert-southwest), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Nearest warm-climate vocabulary: stucco walls, low hipped/gabled ranches, a flat-roof modern family and a terracotta roof colour slot. Not a desert, so its tree priors (and gravel yards in the proposal) are wrong for Miami and must be reviewed.

Comparison reference: `coral-gables` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| coral-gables-venetian-pool | Venetian Pool | way/297000205 | [25.746, -80.273] | 1 | 621 | 2026-10-06T04:21:33Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 621 / 24 |
| houses (generator role) | 235 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 1 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | miami-coral-gables-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 25.746; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW |
| trees.deciduousShare | template | 0 | 0.98 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [5, 10] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.3 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.15, oval 0.2, spreading 0.65 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [2.5, 5] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 234 | smallArea 33.3, largeArea 235, hugeArea 874 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
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

- Buildings: 621.0 per km2 (235.0 houses per km2). Roles: block 62% (386), house 38% (235).
- building=* values: yes 99% (615), terrace 0% (3), apartments 0% (1), detached 0% (1), house 0% (1).
- Levels (all buildings, 0% tagged): -. Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 228, mean 5.11, p10 3.07, p25 3.7, p50 4.5, p75 6.53, p90 7.93; blocks: n 376, mean 6.83, p10 4.2, p25 4.4, p50 5.1, p75 7.53, p90 9.3.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 235 | 39.9 | 64.7 | 187.6 | 224.5 | 239.2 | 1.16-1.64 | 0.758-0.997 |
| block | 386 | 265.6 | 296.9 | 351.4 | 439.2 | 535.8 | 1.14-1.62 | 0.652-0.812 |

- Probable garages among generator houses: 1 (0% of houses; 2% of the 54 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=234): footprint n 234, mean 170.9, p10 39.9, p25 65, p50 187.8, p75 224.5, p90 239.2; levels -; facade-to-curb n 234, mean 19.23, p10 10.36, p25 12.46, p50 13.48, p75 29.59, p90 36.28; long side faces street 48%.
- Footprint classes (houses): orthogonal 61% (144), rectangle 36% (85), irregular 2% (4), nearRectangle 1% (2).
- Situations with template thresholds: unknown 47% (111), large 30% (70), small 23% (54).
- Use mix (non-outbuildings, by count): unknown 96% (596), residential 4% (25); by footprint area: unknown 0.929, residential 0.039, residential (landuse) 0.032.
- Setback (facade to curb, 235 of 235 houses): median 13.49 m, IQR 12.46-29.87 m; centreline 16.74 m median; 0 negative.
- Long side faces the street: 48% of 235 houses with a front edge.
- Coverage proxies: net 0.097 (residential landuse 3% of the cell), gross 0.195; water 0%.
- Alleys: 0.822 km/km2; houses within 30 m of an alley 4%; garages adjacent to an alley -% (engine alley edge -%); driveways 0.167 km/km2.
- Barriers per km2 / per 100 houses: fence 0.481 km / 204.6 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 1 mapped (1.0 per km2); tree rows 0.0 km/km2; wood 0%, park 2% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): footway 24.116, path 0.03, residential 11.197, service 2.189, tertiary 5.173, tertiary_link 0.14, unclassified 0.086; sidewalks 22.905.

### Tag coverage (% missing)

| tag | buildings (n=621) | houses (n=235) |
|---|---|---|
| building:levels | 100% | 100% |
| height | 3% | 3% |
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

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 65.0-224.5 m2 (median 187.8); aspect p25-p75 1.16-1.64; rectangle short side p25-p75 6.8-13.9 m, long side 9.8-20.4 m; long side faces the street on 48% of houses (narrow end to the street on 52%); 1 generator 'houses' (0%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 13.48 m (IQR 12.46-29.59).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00012859 MIAMI WSO CITY, FL US, 3.4 km away (elev 4.6 m). Snow: USW00012859 MIAMI WSO CITY, FL US, 3.4 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | 20.61 | 21.83 | 22.83 | 24.44 | 26.28 | 27.78 | 29.06 | 28.83 | 28.17 | 26.72 | 23.94 | 21.89 |
| precip mm | 59.2 | 57.7 | 51.6 | 65 | 117.3 | 221.5 | 106.7 | 148.6 | 186.7 | 151.4 | 66.3 | 62.2 |
| snow mm | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Koppen-Geiger: **Am** (0 C C/D threshold; Am with the -3 C variant). MAT 25.2 C, MAP 1294.2 mm, warmest 29.06 C, coldest 20.61 C, Pthreshold 64.4 mm.

## Accuracy check against `coral-gables`

Score = agree / (agree + differ) = **0.333** (1 agree, 2 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.34/0.53/0.14 | 0.37/0.49/0.15 | TVD 0.042 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | - | - | - | 0.15 | 0 | not measurable |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 22.9 | 18.6 | /d/ 4.3 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 33.3 | 60 | rel 0.45 | 0.15 | 234 | differ |
| typeThresholds.largeArea m2 | 235 | 220 | rel 0.07 | 0.15 | 234 | agree |
| typeThresholds.hugeArea m2 | 874 | 350 | rel 1.50 | 0.15 | 234 | differ |
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

1 supported, 2 contradicted, 9 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.37/0.49/0.15 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | - | - | 0 | 30 | - | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 0%) |
| trees.deciduousShare vs broadleaved share | 0.98 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 29.8 | 234 | 30 | rel 0.50 | 0.15 | contradicts | share of zone houses below the reference value: 0.226 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 236.9 | 234 | 30 | rel 0.08 | 0.15 | supports | share of zone houses below the reference value: 0.701 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 941.2 | 234 | 30 | rel 1.69 | 0.15 | contradicts | share of zone houses below the reference value: 0.987 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 18.6 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #D5C5B1 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #9D7A66 | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| coral-gables-venetian-pool | coral-gables-inland-review | coral-gables | coral-gables | yes | coral-gables 1 | coral-gables-inland-review 100% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| coral-gables-inland-review | coral-gables | 1 | 621 | 0.378 | 0.622 | 187.6 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- `seasons`: meteorological seasons from latitude 25.746; Koppen Am (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW
- Still missing (needs generator work, not data): palms: no tree archetype (the generator draws conifer or a broadleaf crown); evergreen broadleaf leaf habit is not expressible (deciduousShare is a non-conifer share); barrel-tile roof identity (only colour; no tile eave/ridge geometry); low-rise condo / balcony bands (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
