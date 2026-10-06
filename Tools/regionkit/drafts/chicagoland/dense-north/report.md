# Region kit draft: chicagoland / dense-north

**Chicago dense north side (Lakeview, Lincoln Park, Edgewater)** - drafted 2026-10-05 by `Tools/regionkit` from template `front-range` (Sources/WorldGen/Profiles/front-range.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Front-range is the only profile with flat-roof 2-3 storey families (modern, duplex) plus a steep gabled cottage, the nearest vocabulary for two/three-flats and frame workers' cottages on narrow lots. Its bungalow/foursquare/ranch families will mostly be filtered out by aspect/levels.

Comparison reference: `chicago-dense-north` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| lakeview-gill-park | Gill Park | way/1103063291 | [41.952, -87.65] | 1 | 958 | 2026-10-06T04:06:05Z | https://overpass-api.de/api/interpreter |
| lincoln-park-oz-park | Oz Park | way/28292473 | [41.921, -87.646] | 1 | 2232 | 2026-10-06T04:07:02Z | https://overpass-api.de/api/interpreter |
| edgewater-broadway-armory-park | Broadway Armory Park | way/1509645561 | [41.989, -87.66] | 1 | 1405 | 2026-10-06T04:07:02Z | https://overpass-api.de/api/interpreter |

Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 4595 / 72 |
| houses (generator role) | 3558 |
| houses with building:levels | 1758 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 409 / 24 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-dense-north-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 41.954 |
| trees.deciduousShare | template | 24 | 0.9 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 15] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.15 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.45, oval 0.3, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 2438 | smallArea 43.3, largeArea 182.3, hugeArea 250.1 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.4, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 1756 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
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
| garage.roof | template | 0 | gabled 0.6, hipped 0.05, flat 0.35 | needs >= 20 garages with roof:shape |
| garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters | template | 0 | - | no open data |
| shed | template | 0 | - | no open data |
| chimneyLikelihood | template | 0 | - | no open data |
| foundationMeters | template | 0 | - | no open data |

Calibrated from data: `typeThresholds.smallArea/largeArea/hugeArea`, `typeRules.unknown/small/large`. Everything else is template or rule-based.

## Measurements

- Buildings: 1531.7 per km2 (1186.0 houses per km2). Roles: house 77% (3558), block 22% (998), garage 0% (24), shed 0% (15).
- building=* values: yes 92% (4206), apartments 4% (191), retail 1% (26), terrace 1% (26), garage 0% (22), house 0% (14), residential 0% (14), roof 0% (14), commercial 0% (13), church 0% (9).
- Levels (all buildings, 54% tagged): 2 46% (1130), 3 41% (1019), 4 5% (113), 1 4% (110), 5+ 4% (98). Houses: 2 58% (1021), 3 37% (655), 4 2% (44), 1 2% (38).
- Metres per level (houses, wall): n 0; all buildings total: n 2, mean 3.94, p10 3.1, p25 3.42, p50 3.94, p75 4.47, p90 4.79.
- Heights (houses): n 2, mean 3, p10 3, p25 3, p50 3, p75 3, p90 3; blocks: n 3, mean 60.57, p10 7, p25 10, p50 15, p75 88.35, p90 132.36.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material brick 75% (3), limestone,brick 25% (1); building:colour families grey 40% (2), orange 20% (1), tan 20% (1), white 20% (1); roof:colour families blue 100% (1).

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 3558 | 37.6 | 45.9 | 101.6 | 141.9 | 178.6 | 1.21-2.76 | 0.893-0.99 |
| garage | 24 | 27.4 | 37.2 | 47.7 | 67.6 | 135.2 | 1.07-1.43 | 0.984-0.999 |
| shed | 15 | 4.9 | 6.1 | 6.8 | 10.8 | 18.5 | 1.26-2.31 | 0.975-0.994 |
| block | 998 | 260.8 | 304.1 | 443.8 | 752.3 | 1368.4 | 1.42-2.54 | 0.771-0.938 |

- Probable garages among generator houses: 1120 (32% of houses; 86% of the 1300 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=2438): footprint n 2438, mean 132, p10 65.2, p25 98.4, p50 128, p75 157.9, p90 193.5; levels 2 58% (1020), 3 37% (654), 4 2% (44), 1 2% (38); facade-to-curb n 2437, mean 12.94, p10 7, p25 8.87, p50 10.76, p75 12.71, p90 24.63; long side faces street 17%.
- Footprint classes (houses): rectangle 73% (2608), orthogonal 24% (866), nearRectangle 2% (64), irregular 1% (20).
- Situations with template thresholds: small 36% (1296), twoFloorNarrow 25% (879), threeFloor 20% (699), unknown 13% (474), twoFloor 3% (99), twoFloorSquare 1% (42), oneFloor 1% (37), large 1% (30), oneFloorBroad 0% (1), semidetached 0% (1).
- Use mix (non-outbuildings, by count): residential 92% (4156), commercial 6% (294), other 1% (47), mixed 1% (33), unknown 0% (13); by footprint area: residential (landuse) 0.578, residential 0.15, other 0.078, commercial (tags/POI) 0.072, commercial 0.042, commercial (landuse) 0.04, mixed 0.033, unknown 0.006.
- Setback (facade to curb, 3556 of 3558 houses): median 12.26 m, IQR 9.71-35.51 m; centreline 15.33 m median; 0 negative.
- Long side faces the street: 24% of 3432 houses with a front edge.
- Coverage proxies: net 0.172 (residential landuse 68% of the cell), gross 0.362; water 0%.
- Alleys: 8.217 km/km2; houses within 30 m of an alley 96%; garages adjacent to an alley 92% (engine alley edge 96%); driveways 0.709 km/km2.
- Barriers per km2 / per 100 houses: fence 0.643 km / 54.2 m, wall 0.613 / 51.7, hedge 0.0 / 0.0, retaining wall 0.454 / 38.3.
- Trees: 409 mapped (136.3 per km2); tree rows 0.0 km/km2; wood 0%, park 4% of the cell. leaf_type tagged: broadleaved 100% (24); leaf_cycle tagged: deciduous 100% (9); with genus fallback: type broadleaved 100% (24), cycle deciduous 100% (10). Top genus: Ginkgo 100% (1). Palm share (trees with genus): 0. Heights: n 0.
- Streets (km/km2): busway 0.022, cycleway 0.275, footway 27.157, motorway 0.503, motorway_link 0.172, path 0.113, pedestrian 0.067, platform 0.09, primary 0.666, residential 8.399, secondary 2.241, service 12.266, services 0.034, steps 0.048, tertiary 1.545; sidewalks 23.668.

### Tag coverage (% missing)

| tag | buildings (n=4595) | houses (n=3558) |
|---|---|---|
| building:levels | 46% | 51% |
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

Principal houses (generator houses minus probable garages): 2% 1-storey, 58% 2-storey, 40% 3+ (of 1756 houses with levels, 72% of houses); footprints p25-p75 98.4-157.9 m2 (median 128.0); aspect p25-p75 1.87-2.98; rectangle short side p25-p75 6.6-8.3 m, long side 14.5-22.2 m; long side faces the street on 17% of houses (narrow end to the street on 83%); 1120 generator 'houses' (32%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 10.76 m (IQR 8.87-12.71).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00014819 CHICAGO MIDWAY AP, IL US, 20.4 km away (elev 186.5 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 23.4 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -3.33 | -1.28 | 4.22 | 10.33 | 16.39 | 22 | 24.61 | 23.61 | 19.72 | 12.72 | 5.56 | -0.39 |
| precip mm | 37.6 | 37.1 | 47.8 | 90.7 | 103.9 | 101.9 | 90.2 | 101.3 | 70.4 | 88.4 | 59.7 | 45.5 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 11.18 C, MAP 874.5 mm, warmest 24.61 C, coldest -3.33 C, Pthreshold 36.4 mm.

## Accuracy check against `chicago-dense-north`

Score = agree / (agree + differ) = **0** (0 agree, 4 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.16/0.06/0.78 | 0.40/0.07/0.53 | TVD 0.254 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.29/0.71/0.00 | 0.44/0.39/0.17 | TVD 0.327 | 0.15 | 1756 | differ (truth 0.08/0.68/0.25 (bins covering 95% of untagged houses); TVD to truth: draft 0.245, reference 0.367) |
| perFloor m (usage-weighted midpoint) | 3.12 | 3 | /d/ 0.12 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 33.7 | 38.8 | /d/ 5.2 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 43.3 | 60 | rel 0.28 | 0.15 | 2438 | differ |
| typeThresholds.largeArea m2 | 182.3 | 220 | rel 0.17 | 0.15 | 2438 | differ |
| typeThresholds.hugeArea m2 | 250.1 | 350 | rel 0.29 | 0.15 | 2438 | differ |
| trees.deciduousShare (non-conifer share) | 0.9 | 0.95 | /d/ 0.050 | 0.05 | 24 | not measurable |
| trees.heightMeters (midpoint) | [9, 15] | [8, 15] | /d/ 0.5 | 2 | 0 | not measurable |
| trees.youngShare | 0.15 | 0.22 | /d/ 0.070 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.05/0.35 | 0.60/0.10/0.30 | TVD 0.050 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #C1B2A1 | #AFA08D | dE00 5.3 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #5B636A | #5F666B | dE00 1.6 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

0 supported, 4 contradicted, 8 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.40/0.07/0.53 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.44/0.39/0.17 | 0.08/0.68/0.25 | 1756 | 30 | TVD 0.367 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 95%) |
| trees.deciduousShare vs broadleaved share | 0.95 | 1 | 24 | 30 | /d/ 0.050 | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 43.1 | 2438 | 30 | rel 0.28 | 0.15 | contradicts | share of zone houses below the reference value: 0.075 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 181.9 | 2438 | 30 | rel 0.17 | 0.15 | contradicts | share of zone houses below the reference value: 0.950 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 248.8 | 2438 | 30 | rel 0.29 | 0.15 | contradicts | share of zone houses below the reference value: 0.994 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 38.8 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #AFA08D | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #5F666B | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| lakeview-gill-park | (none: defaultProfile) | generic-temperate-v1 | chicago-dense-north | NO | generic-temperate-v1 0.74, chicago-dense-north 0.26 | lakeview-review 26% |
| lincoln-park-oz-park | lincoln-park-review | chicago-dense-north | chicago-dense-north | yes | chicago-dense-north 1 | lincoln-park-review 100% |
| edgewater-broadway-armory-park | edgewater-review | chicago-dense-north | chicago-dense-north | yes | chicago-dense-north 0.63, generic-temperate-v1 0.37 | edgewater-review 63% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| lakeview-review | chicago-dense-north | 0.256 | 1020.8 | 0.682 | 0.318 | 126.4 | 0.703 (158) |
| lincoln-park-review | chicago-dense-north | 1 | 2232 | 0.868 | 0.121 | 101 | 0.519 (1072) |
| edgewater-review | chicago-dense-north | 0.633 | 1871.7 | 0.838 | 0.156 | 95 | 0.249 (659) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Role dispatch for apartments: buildings with role `block` (building=apartments, yes >= 250 m2, ...) always use the FIRST flat-roof house type, so sixFlat / courtyardMass / cornerMixedUse / vintageHighRise in the reference profiles are never chosen for them; two/three-level rear porches and gangways, stoops, cornices (no geometry support); Chicago brick bungalow attic/dormer and raised basement (one roof per rectangle, no dormers).
- Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan.
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
