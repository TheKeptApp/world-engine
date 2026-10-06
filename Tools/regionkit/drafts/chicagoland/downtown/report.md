# Region kit draft: chicagoland / downtown

**Chicago downtown (Loop, River North) - lower priority, towers come later** - drafted 2026-10-05 by `Tools/regionkit` from template `default` (Sources/WorldGen/Profiles/default.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Generic profile: only its flatRoof family is relevant (blocks take the first flat-roof type). No profile has towers.

Comparison reference: `chicago-downtown` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| loop-daley-plaza | Daley Plaza | relation/1969327 | [41.884, -87.63] | 1 | 437 | 2026-10-06T04:13:00Z | https://overpass-api.de/api/interpreter |
| river-north-montgomery-ward-park | Montgomery Ward Park | way/153561199 | [41.894, -87.642] | 1 | 396 | 2026-10-06T04:14:15Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 833 / 171 |
| houses (generator role) | 234 |
| houses with building:levels | 37 |
| houses with roof:shape | 1 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 481 / 175 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-downtown-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 41.889 |
| trees.deciduousShare | calibrated | 175 | 0.971 | generator treats this as NON-CONIFER share (SceneGenerator: !chance(deciduousShare) -> conifer); true leaf cycle is reported separately |
| trees.heightMeters | template | 0 | [8, 14] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.2 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.4, oval 0.35, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 223 | smallArea 21.1, largeArea 220.7, hugeArea 1293.6 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 35 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 0 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | template | 1 | - | needs >= 30 houses with roof:shape |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 1 | - | needs >= 30 houses with building:colour or a coloured building:material |
| houseTypes[].colors[roof] | template | 1 | - | needs >= 30 houses with roof:colour or a coloured roof:material |
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

Calibrated from data: `trees.deciduousShare`, `typeThresholds.smallArea/largeArea/hugeArea`, `typeRules.unknown/small/large`. Everything else is template or rule-based.

## Measurements

- Buildings: 416.5 per km2 (117.0 houses per km2). Roles: block 66% (554), house 28% (234), shed 5% (42), garage 0% (3).
- building=* values: yes 36% (304), office 17% (143), roof 12% (104), apartments 9% (74), house 4% (34), commercial 4% (31), hotel 3% (27), terrace 3% (23), service 2% (21), retail 2% (15).
- Levels (all buildings, 45% tagged): 5+ 70% (264), 4 8% (31), 2 8% (29), 3 7% (27), 1 6% (24). Houses: 2 43% (16), 5+ 19% (7), 3 16% (6), 1 14% (5), 4 8% (3).
- Metres per level (houses, wall): n 0; all buildings total: n 79, mean 4.02, p10 3.26, p25 3.58, p50 4, p75 4.24, p90 4.65.
- Heights (houses): n 1, mean 153, p10 153, p25 153, p50 153, p75 153, p90 153; blocks: n 83, mean 130.84, p10 73.2, p25 93.2, p50 125, p75 158.5, p90 196.4.
- roof:shape on houses (0%): raw flat 100% (1); mapped flat 100% (1). Garages: -.
- Materials/colours: roof:material tar_paper 60% (3), concrete 40% (2); building:material brick 30% (10), glass 18% (6), concrete 12% (4), cement_block 9% (3), marble 6% (2), metal 6% (2), stone 6% (2), granite 3% (1); building:colour families tan 39% (7), beige 22% (4), brown 11% (2), cream 11% (2), black 6% (1), grey 6% (1), white 6% (1); roof:colour families beige 50% (2), green 25% (1), grey 25% (1).

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 234 | 24.2 | 67.8 | 99.3 | 176.5 | 238.5 | 1.59-3.15 | 0.919-0.991 |
| garage | 3 | 2144.2 | 2146.6 | 2150.6 | 2637.7 | 2930 | 1.16-1.27 | 0.882-0.975 |
| shed | 42 | 3.8 | 4.7 | 5.8 | 10.1 | 11.4 | 1.15-2.71 | 0.991-0.999 |
| block | 554 | 47.4 | 295.3 | 803.6 | 1768.7 | 2894 | 1.31-2.55 | 0.92-0.995 |

- Probable garages among generator houses: 11 (5% of houses; 28% of the 39 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=223): footprint n 223, mean 161.8, p10 33.4, p25 68.5, p50 100.8, p75 179.3, p90 239.7; levels 2 46% (16), 5+ 20% (7), 1 14% (5), 3 11% (4), 4 9% (3); facade-to-curb n 223, mean 7.55, p10 2.36, p25 4.5, p50 6.1, p75 8.04, p90 11.91; long side faces street 56%.
- Footprint classes (houses): rectangle 81% (189), orthogonal 10% (24), irregular 6% (14), nearRectangle 3% (7).
- Situations with template thresholds: unknown 58% (137), small 16% (37), large 10% (23), threeFloor 7% (16), twoFloorNarrow 6% (14), oneFloor 1% (3), oneFloorBroad 1% (2), twoFloor 1% (2).
- Use mix (non-outbuildings, by count): commercial 48% (339), residential 34% (243), other 9% (61), mixed 5% (33), unknown 4% (31); by footprint area: commercial 0.509, other 0.168, residential 0.11, mixed 0.065, commercial (tags/POI) 0.046, commercial (landuse) 0.043, residential (landuse) 0.041, unknown 0.019.
- Setback (facade to curb, 233 of 234 houses): median 6.13 m, IQR 4.51-8.22 m; centreline 9.44 m median; 2 negative.
- Long side faces the street: 54% of 213 houses with a front edge.
- Coverage proxies: net 0.104 (residential landuse 15% of the cell), gross 0.438; water 7%.
- Alleys: 4.438 km/km2; houses within 30 m of an alley 42%; garages adjacent to an alley 67% (engine alley edge 0%); driveways 1.194 km/km2.
- Barriers per km2 / per 100 houses: fence 2.351 km / 2009.1 m, wall 0.708 / 605.2, hedge 0.0 / 0.0, retaining wall 3.79 / 3239.2.
- Trees: 481 mapped (240.5 per km2); tree rows 0.0 km/km2; wood 0%, park 2% of the cell. leaf_type tagged: broadleaved 100% (175); leaf_cycle tagged: -; with genus fallback: type broadleaved 100% (175), cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): construction 1.31, corridor 0.044, cycleway 1.867, elevator 0.231, footway 34.803, motorway 0.018, motorway_link 1.069, path 0.017, pedestrian 0.065, residential 2.958, secondary 11.274, secondary_link 0.303, service 9.785, steps 1.099, tertiary 1.743, track 0.632, trunk 1.089, unclassified 0.228; sidewalks 24.295.

### Tag coverage (% missing)

| tag | buildings (n=833) | houses (n=234) |
|---|---|---|
| building:levels | 55% | 84% |
| height | 90% | 100% |
| roof:shape | 99% | 100% |
| roof:levels | 99% | 99% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 99% | 100% |
| roof:colour | 100% | 100% |
| building:material | 96% | 100% |
| building:colour | 98% | 100% |
| start_date | 98% | 100% |

### Family signature hints

Principal houses (generator houses minus probable garages): 14% 1-storey, 46% 2-storey, 40% 3+ (of 35 houses with levels, 16% of houses); footprints p25-p75 68.5-179.3 m2 (median 100.8); aspect p25-p75 1.63-3.16; rectangle short side p25-p75 6.5-8.5 m, long side 11.3-22.4 m; long side faces the street on 56% of houses (narrow end to the street on 44%); roof:shape on 1 houses: flat 100%; 11 generator 'houses' (5%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 6.1 m (IQR 4.5-8.04).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00014819 CHICAGO MIDWAY AP, IL US, 14.9 km away (elev 186.5 m). Snow: USC00111577 CHICAGO MIDWAY AP 3SW, IL US, 20.5 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -3.33 | -1.28 | 4.22 | 10.33 | 16.39 | 22 | 24.61 | 23.61 | 19.72 | 12.72 | 5.56 | -0.39 |
| precip mm | 37.6 | 37.1 | 47.8 | 90.7 | 103.9 | 101.9 | 90.2 | 101.3 | 70.4 | 88.4 | 59.7 | 45.5 |
| snow mm | 318 | 257 | 145 | 25 | 0 | 0 | 0 | 0 | 0 | 3 | 38 | 201 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 11.18 C, MAP 874.5 mm, warmest 24.61 C, coldest -3.33 C, Pthreshold 36.4 mm.

## Accuracy check against `chicago-downtown`

Score = agree / (agree + differ) = **0.4** (2 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.15/0.25/0.60 | 0.00/0.00/1.00 | TVD 0.404 | 0.1 | 1 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.86/0.14/0.00 | 0.00/0.00/1.00 | TVD 1.000 | 0.15 | 35 | differ (truth 0.19/0.53/0.28 (bins covering 87% of untagged houses); TVD to truth: draft 0.664, reference 0.720) |
| perFloor m (usage-weighted midpoint) | 3.08 | 3 | /d/ 0.08 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 26.4 | - | - | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 21.1 | 60 | rel 0.65 | 0.15 | 223 | differ |
| typeThresholds.largeArea m2 | 220.7 | 220 | rel 0.00 | 0.15 | 223 | agree |
| typeThresholds.hugeArea m2 | 1293.6 | 350 | rel 2.70 | 0.15 | 223 | differ |
| trees.deciduousShare (non-conifer share) | 0.971 | 0.96 | /d/ 0.011 | 0.05 | 175 | agree |
| trees.heightMeters (midpoint) | [8, 14] | [8, 15] | /d/ 0.5 | 2 | 0 | not measurable |
| trees.youngShare | 0.2 | 0.22 | /d/ 0.020 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #C2BCAA | #AB876E | dE00 18.8 | 10 | 1 | not measurable |
| roof colour (usage-weighted mean) | #636A71 | #5F6367 | dE00 3.1 | 10 | 1 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

2 supported, 3 contradicted, 7 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.00/0.00/1.00 | 0.00/0.00/1.00 | 1 | 30 | TVD 0.000 | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.00/0.00/1.00 | 0.19/0.53/0.28 | 35 | 30 | TVD 0.720 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 87%) |
| trees.deciduousShare vs broadleaved share | 0.96 | 1 | 175 | 30 | /d/ 0.040 | 0.05 | supports |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 15.9 | 223 | 30 | rel 0.74 | 0.15 | contradicts | share of zone houses below the reference value: 0.130 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 220.8 | 223 | 30 | rel 0.00 | 0.15 | supports | share of zone houses below the reference value: 0.857 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 1420.5 | 223 | 30 | rel 3.06 | 0.15 | contradicts | share of zone houses below the reference value: 0.919 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | - | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #AB876E | #A9735F | 1 | 30 | dE00 8.3 | 10 | can't test | top families: red 1 |
| roof colour vs measured colour/material (mean) | #5F6367 | #636466 | 1 | 30 | dE00 1.8 | 10 | can't test | top families: darkgrey 1 |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| loop-daley-plaza | downtown-river-review | chicago-downtown | chicago-downtown | yes | chicago-downtown 1 | downtown-river-review 100% |
| river-north-montgomery-ward-park | downtown-river-review | chicago-downtown | chicago-downtown | yes | chicago-downtown 0.611, generic-temperate-v1 0.389 | downtown-river-review 61% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| downtown-river-review | chicago-downtown | 1.606 | 447.8 | 0.266 | 0.682 | 85.7 | 0.892 (324) |

## Needs a human eye

- Template-only (no open data): `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Tower role dispatch and massing (setbacks, podiums, crowns): chicagoSchoolMass / artDecoMass / modernGlassMass exist as IDs but blocks always take the first flat-roof type; elevated rail (the L) structure, bascule bridges, multi-level streets (not buildings; no generator object).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 84% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
