# Region kit draft: denver / sloans-lake

**Sloan's Lake, Denver (committed extract, 1600 m x 1200 m)** - drafted 2026-10-05 by `Tools/regionkit` from template `default` (Sources/WorldGen/Profiles/default.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Accuracy check: the generic default is used so the draft cannot simply copy the reference.

Comparison reference: `front-range` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| sloans-lake-extract | localExtract | - | [39.749, -105.044] | 1.92 | 1399 | 2026-10-05T17:39:35Z | committed extract (read in place, read-only) |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 1399 / 0 |
| houses (generator role) | 779 |
| houses with building:levels | 124 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 12 / 31 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 5400 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | denver-sloans-lake-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 39.749; Koppen BSk (arid): seasonal greenness follows rain/irrigation more than temperature - review |
| trees.deciduousShare | template | 0 | 0.8 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [8, 14] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.2 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.4, oval 0.35, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 778 | smallArea 60.1, largeArea 220, hugeArea 348.8 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 124 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 0 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | template | 0 | - | needs >= 30 houses with roof:shape |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 12 | - | needs >= 30 houses with building:colour or a coloured building:material |
| houseTypes[].colors[roof] | calibrated | 31 | (see measurements.json) | alpha=0.51; L* clamped to [44.2, 45.5], C* to [3.5, 6.1] (template band) |
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

Calibrated from data: `typeThresholds.smallArea/largeArea/hugeArea`, `typeRules.unknown/small/large`, `houseTypes[].colors[roof]`. Everything else is template or rule-based.

## Measurements

- Buildings: 728.6 per km2 (405.7 houses per km2). Roles: house 56% (779), garage 35% (490), shed 6% (85), block 3% (45).
- building=* values: house 55% (769), garage 35% (490), shed 6% (84), yes 1% (15), retail 1% (13), roof 1% (9), commercial 1% (8), apartments 0% (5), office 0% (3), public 0% (1).
- Levels (all buildings, 9% tagged): 1 57% (74), 3 34% (44), 2 9% (12). Houses: 1 55% (68), 3 36% (44), 2 10% (12).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families cream 75% (12), brown 19% (3), tan 6% (1); roof:colour families darkgrey 36% (22), brown 21% (13), grey 21% (13), red 19% (12), tan 3% (2).

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 779 | 94.1 | 107.7 | 136.9 | 183.9 | 234.2 | 1.26-1.99 | 0.81-0.948 |
| garage | 490 | 20.2 | 34.6 | 47.8 | 62.6 | 82.4 | 1.09-1.44 | 0.999-1.0 |
| shed | 85 | 4.4 | 5.5 | 7.4 | 10.3 | 17.5 | 1.08-1.39 | 0.998-0.999 |
| block | 45 | 46.3 | 142.7 | 241.2 | 433.4 | 570.1 | 1.18-1.85 | 0.856-1.0 |

- Probable garages among generator houses: 1 (0% of houses; 50% of the 2 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=778): footprint n 778, mean 152, p10 94.3, p25 107.8, p50 137, p75 183.9, p90 234.4; levels 1 55% (68), 3 36% (44), 2 10% (12); facade-to-curb n 778, mean 12.5, p10 7.82, p25 9.82, p50 12.15, p75 13.88, p90 16.81; long side faces street 38%.
- Footprint classes (houses): orthogonal 52% (404), rectangle 46% (362), irregular 1% (8), nearRectangle 1% (5).
- Situations with template thresholds: unknown 70% (545), large 14% (105), oneFloor 7% (57), threeFloor 6% (44), twoFloorNarrow 2% (12), oneFloorBroad 1% (11), small 1% (5).
- Use mix (non-outbuildings, by count): residential 95% (775), commercial 4% (30), unknown 1% (9), other 0% (1); by footprint area: residential 0.899, commercial 0.063, commercial (tags/POI) 0.025, unknown 0.01, other 0.003.
- Setback (facade to curb, 779 of 779 houses): median 12.16 m, IQR 9.82-13.88 m; centreline 15.17 m median; 0 negative.
- Long side faces the street: 38% of 779 houses with a front edge.
- Coverage proxies: net - (residential landuse 0% of the cell), gross 0.131; water 37%.
- Alleys: 3.508 km/km2; houses within 30 m of an alley 96%; garages adjacent to an alley 90% (engine alley edge 97%); driveways 0.224 km/km2.
- Barriers per km2 / per 100 houses: fence 0.335 km / 82.5 m, wall 0.0 / 0.0, hedge 0.104 / 25.6, retaining wall 0.035 / 8.6.
- Trees: 5400 mapped (2812.5 per km2); tree rows 0.0 km/km2; wood 0%, park 23% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 1.33, footway 11.952, path 4.203, primary 0.625, residential 7.112, service 5.435, tertiary 0.053, track 0.026, unclassified 0.176; sidewalks 10.816.

### Tag coverage (% missing)

| tag | buildings (n=1399) | houses (n=779) |
|---|---|---|
| building:levels | 91% | 84% |
| height | 100% | 100% |
| roof:shape | 100% | 100% |
| roof:levels | 100% | 100% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 96% | 96% |
| building:material | 100% | 100% |
| building:colour | 99% | 98% |
| start_date | 100% | 100% |

### Family signature hints

Principal houses (generator houses minus probable garages): 55% 1-storey, 10% 2-storey, 36% 3+ (of 124 houses with levels, 16% of houses); footprints p25-p75 107.8-183.9 m2 (median 137.0); aspect p25-p75 1.26-1.99; rectangle short side p25-p75 8.3-12.4 m, long side 13.4-19.1 m; long side faces the street on 38% of houses (narrow end to the street on 62%); 1 generator 'houses' (0%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 12.15 m (IQR 9.82-13.88).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00052223 DENVER WATER DEPT, CO US, 3.8 km away (elev 1593.5 m). Snow: USC00052223 DENVER WATER DEPT, CO US, 3.8 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | 1.61 | 1.89 | 6.5 | 10.06 | 15.22 | 21.44 | 24.78 | 23.78 | 19 | 11.44 | 5.39 | 1.11 |
| precip mm | 10.9 | 15.2 | 28.7 | 50.3 | 67.3 | 43.9 | 48.3 | 46 | 30.5 | 29.5 | 19.8 | 12.2 |
| snow mm | 140 | 213 | 234 | 127 | 23 | 0 | 0 | 0 | 0 | 64 | 112 | 122 |

Koppen-Geiger: **BSk** (0 C C/D threshold; BSk with the -3 C variant). MAT 11.85 C, MAP 402.6 mm, warmest 24.78 C, coldest 1.11 C, Pthreshold 51.7 mm.

## Accuracy check against `front-range`

Score = agree / (agree + differ) = **1** (2 agree, 0 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.59/0.25/0.16 | 0.57/0.22/0.21 | TVD 0.047 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.82/0.18/0.00 | 0.75/0.25/0.00 | TVD 0.072 | 0.15 | 124 | agree (truth 0.68/0.10/0.22 (bins covering 92% of untagged houses); TVD to truth: draft 0.218, reference 0.218) |
| perFloor m (usage-weighted midpoint) | 3.05 | 3.18 | /d/ 0.13 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 26.5 | 27.8 | /d/ 1.3 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 60.1 | 60 | rel 0.00 | 0.15 | 778 | excluded (calibrated on Denver (percentile transfer is an identity here)) |
| typeThresholds.largeArea m2 | 220 | 220 | rel 0.00 | 0.15 | 778 | excluded (calibrated on Denver (percentile transfer is an identity here)) |
| typeThresholds.hugeArea m2 | 348.8 | 350 | rel 0.00 | 0.15 | 778 | excluded (calibrated on Denver (percentile transfer is an identity here)) |
| trees.deciduousShare (non-conifer share) | 0.8 | 0.9 | /d/ 0.100 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [8, 14] | [9, 15] | /d/ 1.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.2 | 0.15 | /d/ 0.050 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.05/0.35 | TVD 0.050 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B8AD97 | #B3927C | dE00 11.9 | 10 | 12 | not measurable |
| roof colour (usage-weighted mean) | #6A696B | #5F6165 | dE00 3.7 | 10 | 31 | agree |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

3 supported, 2 contradicted, 7 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.57/0.22/0.21 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.75/0.25/0.00 | 0.68/0.10/0.22 | 124 | 30 | TVD 0.218 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 92%) |
| trees.deciduousShare vs broadleaved share | 0.9 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [9, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 60.1 | 778 | 30 | rel 0.00 | 0.15 | supports | share of zone houses below the reference value: 0.019 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 220 | 778 | 30 | rel 0.00 | 0.15 | supports | share of zone houses below the reference value: 0.865 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 348.7 | 778 | 30 | rel 0.00 | 0.15 | supports | share of zone houses below the reference value: 0.990 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.05/0.35 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3.18 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 27.8 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B3927C | #F5DEB3 | 12 | 30 | dE00 21.4 | 10 | can't test | top families: cream 12 |
| roof colour vs measured colour/material (mean) | #5F6165 | #8C5C47 | 31 | 30 | dE00 20.4 | 10 | contradicts | top families: red 12, darkgrey 9, brown 5 |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- `seasons`: meteorological seasons from latitude 39.749; Koppen BSk (arid): seasonal greenness follows rain/irrigation more than temperature - review
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 84% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
