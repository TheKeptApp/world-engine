# Region kit draft: north-texas / plano

**Plano suburban residential (west, central, east)** - drafted 2026-10-05 by `Tools/regionkit` from template `default` (Sources/WorldGen/Profiles/default.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Accuracy check: the generic default is used so the draft cannot simply copy the reference.

Comparison reference: `north-texas-dfw` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| plano-west-parkwood-green-park | Parkwood Green Park | way/429910615 | [33.034, -96.826] | 1 | 367 | 2026-10-06T03:49:51Z | https://overpass-api.de/api/interpreter |
| plano-central-buckhorn-park | Buckhorn Park | way/288927122 | [33.046, -96.76] | 1 | 669 | 2026-05-06T03:25:00Z | https://overpass.private.coffee/api/interpreter |
| plano-east-clearview-park | Clearview Park | way/518592663 | [33.051, -96.704] | 1 | 654 | 2026-05-06T03:25:00Z | https://overpass.private.coffee/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 1690 / 0 |
| houses (generator role) | 1641 |
| houses with building:levels | 1 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 35 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | north-texas-plano-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 33.044 |
| trees.deciduousShare | template | 0 | 0.8 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [8, 14] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.2 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.4, oval 0.35, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 1641 | smallArea 175.7, largeArea 431.8, hugeArea 539.7 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | template | 1 | - | needs >= 30 houses with building:levels |
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

- Buildings: 563.3 per km2 (547.0 houses per km2). Roles: house 97% (1641), block 3% (49).
- building=* values: house 95% (1612), terrace 2% (27), yes 1% (16), warehouse 1% (12), commercial 0% (6), retail 0% (6), parking 0% (3), office 0% (2), roof 0% (2), school 0% (2).
- Levels (all buildings, 0% tagged): 1 43% (3), 2 43% (3), 5+ 14% (1). Houses: 2 100% (1).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 1641 | 213.4 | 239.1 | 331.2 | 400.9 | 449.8 | 1.07-1.28 | 0.831-0.996 |
| block | 49 | 293.6 | 530.3 | 984.7 | 3146.5 | 5464.2 | 1.3-3.17 | 0.754-0.983 |

- Probable garages among generator houses: 0 (0% of houses; -% of the 0 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=1641): footprint n 1641, mean 327.1, p10 213.4, p25 239.1, p50 331.2, p75 400.9, p90 449.8; levels 2 100% (1); facade-to-curb n 1641, mean 12.91, p10 9.52, p25 11.04, p50 12.66, p75 14.04, p90 16.14; long side faces street 35%.
- Footprint classes (houses): orthogonal 54% (887), rectangle 45% (739), irregular 1% (14), nearRectangle 0% (1).
- Situations with template thresholds: large 86% (1410), unknown 14% (230), twoFloorSquare 0% (1).
- Use mix (non-outbuildings, by count): residential 97% (1643), commercial 2% (25), other 1% (19), unknown 0% (1); by footprint area: residential 0.81, other 0.093, commercial 0.073, commercial (landuse) 0.015, commercial (tags/POI) 0.005, unknown 0.002, residential (landuse) 0.002.
- Setback (facade to curb, 1641 of 1641 houses): median 12.66 m, IQR 11.04-14.04 m; centreline 15.8 m median; 0 negative.
- Long side faces the street: 35% of 1641 houses with a front edge.
- Coverage proxies: net 0.26 (residential landuse 69% of the cell), gross 0.221; water 0%.
- Alleys: 7.898 km/km2; houses within 30 m of an alley 94%; garages adjacent to an alley -% (engine alley edge -%); driveways 0.735 km/km2.
- Barriers per km2 / per 100 houses: fence 0.06 km / 10.9 m, wall 0.005 / 0.9, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 35 mapped (11.7 per km2); tree rows 0.0 km/km2; wood 0%, park 3% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): construction 0.5, footway 1.895, motorway 0.829, motorway_link 0.325, path 0.447, residential 8.515, secondary 0.829, secondary_link 0.056, service 14.238, tertiary 2.046, tertiary_link 0.032, unclassified 0.016; sidewalks 1.142.

### Tag coverage (% missing)

| tag | buildings (n=1690) | houses (n=1641) |
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

Principal houses (generator houses minus probable garages): -% 1-storey, 100% 2-storey, 0% 3+ (of 1 houses with levels, 0% of houses); footprints p25-p75 239.1-400.9 m2 (median 331.2); aspect p25-p75 1.07-1.28; rectangle short side p25-p75 15.0-19.7 m, long side 18.2-23.0 m; long side faces the street on 35% of houses (narrow end to the street on 65%); facade-to-curb median 12.66 m (IQR 11.04-14.04).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00417588 RICHARDSON, TX US, 5.6 km away (elev 206.7 m). Snow: USC00413370 FRISCO, TX US, 16.8 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | 7.67 | 9.89 | 14.5 | 18.39 | 22.83 | 27 | 29.33 | 29.28 | 25.11 | 19.33 | 13.28 | 8.67 |
| precip mm | 70.6 | 85.6 | 90.4 | 89.4 | 131.6 | 97.3 | 56.4 | 63 | 83.8 | 133.6 | 77.2 | 85.6 |
| snow mm | 5 | 33 | 10 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 15 |

Koppen-Geiger: **Cfa** (0 C C/D threshold; Cfa with the -3 C variant). MAT 18.77 C, MAP 1064.5 mm, warmest 29.33 C, coldest 7.67 C, Pthreshold 51.5 mm.

## Accuracy check against `north-texas-dfw`

Score = agree / (agree + differ) = **0** (0 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.59/0.30/0.11 | 0.54/0.46/0.00 | TVD 0.157 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.00/1.00/0.00 | 0.46/0.54/0.00 | TVD 0.462 | 0.15 | 1 | not measurable (truth 0.00/1.00/0.00 (bins covering 25% of untagged houses); TVD to truth: draft 0.000, reference 0.462) |
| perFloor m (usage-weighted midpoint) | 3.05 | 3.05 | /d/ 0.00 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 27.7 | 30.8 | /d/ 3.1 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 175.7 | 60 | rel 1.93 | 0.15 | 1641 | differ |
| typeThresholds.largeArea m2 | 431.8 | 260 | rel 0.66 | 0.15 | 1641 | differ |
| typeThresholds.hugeArea m2 | 539.7 | 420 | rel 0.29 | 0.15 | 1641 | differ |
| trees.deciduousShare (non-conifer share) | 0.8 | 0.95 | /d/ 0.150 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [8, 14] | [7, 13] | /d/ 1.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.2 | 0.22 | /d/ 0.020 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #BAAD96 | #B69377 | dE00 10.9 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #656A71 | #646465 | dE00 4.2 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

0 supported, 3 contradicted, 9 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.54/0.46/0.00 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.46/0.54/0.00 | 0.00/1.00/0.00 | 1 | 30 | TVD 0.462 | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 25%) |
| trees.deciduousShare vs broadleaved share | 0.95 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [7, 13] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 177.8 | 1641 | 30 | rel 1.96 | 0.15 | contradicts | share of zone houses below the reference value: 0.000 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 260 | 435.7 | 1641 | 30 | rel 0.68 | 0.15 | contradicts | share of zone houses below the reference value: 0.343 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 420 | 543.1 | 1641 | 30 | rel 0.29 | 0.15 | contradicts | share of zone houses below the reference value: 0.818 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3.05 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 30.8 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B69377 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #646465 | - | 0 | 30 | - | 10 | can't test |  |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
