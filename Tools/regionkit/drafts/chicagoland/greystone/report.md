# Region kit draft: chicagoland / greystone

**Chicago greystone / two-flat neighbourhoods (Logan Square, Wicker Park, Lincoln Square)** - drafted 2026-10-05 by `Tools/regionkit` from template `front-range` (Sources/WorldGen/Profiles/front-range.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Same reasoning as dense-north: front-range's flat-roof modern/duplex families are the nearest stand-in for two-flats and greystones; cottage covers frame cottages.

Comparison reference: `chicago-greystone-twoflat` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| logan-square-centennial-monument | Illinois Centennial Monument | way/163901343 | [41.928, -87.707] | 1 | 2050 | 2026-10-06T04:08:02Z | https://overpass-api.de/api/interpreter |
| wicker-park-park | Wicker Park | way/5732180 | [41.908, -87.676] | 1 | 2543 | 2026-06-01T08:52:28Z | https://overpass.private.coffee/api/interpreter |
| lincoln-square-giddings-plaza | Giddings Plaza | way/112536216 | [41.968, -87.688] | 1 | 2429 | 2026-10-06T04:11:10Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 7022 / 1 |
| houses (generator role) | 4835 |
| houses with building:levels | 2776 |
| houses with roof:shape | 77 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 2 |
| houses with building:colour / roof:colour | 1 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 128 / 1 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-greystone-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 41.935 |
| trees.deciduousShare | template | 1 | 0.9 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 15] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.15 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.45, oval 0.3, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 3383 | smallArea 62.2, largeArea 169.3, hugeArea 397.8 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.4, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 2774 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 2 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | calibrated | 70 | (see measurements.json) | target after shrinkage {'gabled': 0.621, 'hipped': 0.052, 'flat': 0.327}; achieved {'gabled': 0.347, 'hipped': 0.029, 'flat': 0.624}; residual TVD 0.296; zero w |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 8 | - | needs >= 30 houses with building:colour or a coloured building:material |
| houseTypes[].colors[roof] | template | 8 | - | needs >= 30 houses with roof:colour or a coloured roof:material |
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

Calibrated from data: `typeThresholds.smallArea/largeArea/hugeArea`, `typeRules.unknown/small/large`, `houseTypes[].roof`. Everything else is template or rule-based.

## Measurements

- Buildings: 2340.7 per km2 (1611.7 houses per km2). Roles: house 69% (4835), block 17% (1204), garage 14% (964), shed 0% (19).
- building=* values: yes 57% (4014), garage 14% (948), residential 13% (932), apartments 10% (693), detached 3% (189), retail 1% (76), house 1% (69), garages 0% (16), roof 0% (16), commercial 0% (14).
- Levels (all buildings, 53% tagged): 2 63% (2331), 3 23% (866), 1 11% (423), 4 2% (87), 5+ 0% (14). Houses: 2 73% (2026), 3 16% (431), 1 11% (301), 4 1% (18).
- Metres per level (houses, wall): n 2, mean 2.91, p10 2.9, p25 2.91, p50 2.91, p75 2.92, p90 2.92; all buildings total: n 6, mean 3.61, p10 2.99, p25 3.26, p50 3.57, p75 3.92, p90 4.27.
- Heights (houses): n 6, mean 7.96, p10 7.05, p25 7.69, p50 8.07, p75 8.29, p90 8.75; blocks: n 0.
- roof:shape on houses (2%): raw gabled 65% (50), flat 18% (14), many 5% (4), round 4% (3), mansard 3% (2), pyramidal 3% (2), half-hipped 1% (1), hipped 1% (1); mapped gabled 68% (52), flat 18% (14), hipped 5% (4), ignored(many) 5% (4), ignored(round) 4% (3). Garages: -.
- Materials/colours: roof:material slate 62% (5), tar_paper 25% (2), metal 12% (1); building:material brick 86% (6), concrete 14% (1); building:colour families brown 100% (1); roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 4835 | 38.5 | 47.9 | 107.4 | 134 | 166.1 | 1.21-2.63 | 0.888-0.99 |
| garage | 964 | 33.1 | 37.3 | 42.9 | 48.1 | 58.5 | 1.05-1.25 | 0.982-0.995 |
| shed | 19 | 3.8 | 5.8 | 7.3 | 10.2 | 26.6 | 1.2-1.77 | 0.97-0.99 |
| block | 1204 | 106.7 | 132.3 | 258.7 | 470.6 | 772.1 | 1.68-3.06 | 0.847-0.989 |

- Probable garages among generator houses: 1452 (30% of houses; 98% of the 1482 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=3383): footprint n 3383, mean 135.3, p10 82.1, p25 103.9, p50 123.8, p75 145, p90 186.2; levels 2 73% (2026), 3 16% (431), 1 11% (299), 4 1% (18); facade-to-curb n 3382, mean 12.17, p10 7.18, p25 8.82, p50 10.38, p75 12.05, p90 15.5; long side faces street 14%.
- Footprint classes (houses): rectangle 73% (3521), orthogonal 24% (1146), nearRectangle 3% (136), irregular 1% (32).
- Situations with template thresholds: twoFloorNarrow 39% (1891), small 31% (1491), unknown 11% (514), threeFloor 9% (449), oneFloor 6% (290), twoFloor 2% (90), large 1% (54), twoFloorSquare 1% (39), oneFloorBroad 0% (11), semidetached 0% (6).
- Use mix (non-outbuildings, by count): residential 90% (5401), commercial 8% (477), mixed 1% (70), unknown 1% (45), other 1% (35); by footprint area: residential (landuse) 0.399, residential 0.319, commercial (tags/POI) 0.087, commercial (landuse) 0.058, commercial 0.054, mixed 0.036, other 0.033, unknown 0.014.
- Setback (facade to curb, 4834 of 4835 houses): median 11.66 m, IQR 9.48-32.86 m; centreline 14.85 m median; 2 negative.
- Long side faces the street: 21% of 4666 houses with a front edge.
- Coverage proxies: net 0.225 (residential landuse 71% of the cell), gross 0.338; water 0%.
- Alleys: 12.085 km/km2; houses within 30 m of an alley 98%; garages adjacent to an alley 96% (engine alley edge 99%); driveways 0.358 km/km2.
- Barriers per km2 / per 100 houses: fence 0.478 km / 29.7 m, wall 0.049 / 3.0, hedge 0.0 / 0.0, retaining wall 0.339 / 21.1.
- Trees: 128 mapped (42.7 per km2); tree rows 0.0 km/km2; wood 0%, park 2% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type broadleaved 100% (1), cycle -. Top genus: Quercus 100% (1). Palm share (trees with genus): 0. Heights: n 0.
- Streets (km/km2): busway 0.044, cycleway 1.041, footway 30.271, living_street 0.072, path 0.012, platform 0.012, primary 0.333, residential 10.166, secondary 2.967, secondary_link 0.017, service 14.453, steps 0.09, tertiary 1.538, tertiary_link 0.017; sidewalks 26.695.

### Tag coverage (% missing)

| tag | buildings (n=7022) | houses (n=4835) |
|---|---|---|
| building:levels | 47% | 43% |
| height | 100% | 100% |
| roof:shape | 98% | 98% |
| roof:levels | 98% | 99% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 100% | 100% |
| building:material | 100% | 100% |
| building:colour | 100% | 100% |
| start_date | 100% | 100% |

### Family signature hints

Principal houses (generator houses minus probable garages): 11% 1-storey, 73% 2-storey, 16% 3+ (of 2774 houses with levels, 82% of houses); footprints p25-p75 103.9-145.0 m2 (median 123.8); aspect p25-p75 2.09-2.8; rectangle short side p25-p75 6.7-8.1 m, long side 15.6-20.6 m; long side faces the street on 14% of houses (narrow end to the street on 86%); roof:shape on 77 houses: gabled 68%, flat 18%, hipped 5%, ignored(many) 5%; 1452 generator 'houses' (30%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 10.38 m (IQR 8.82-12.05).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00014819 CHICAGO MIDWAY AP, IL US, 17.3 km away (elev 186.5 m). Snow: USW00094846 CHICAGO OHARE INTL AP, IL US, 21.2 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -3.33 | -1.28 | 4.22 | 10.33 | 16.39 | 22 | 24.61 | 23.61 | 19.72 | 12.72 | 5.56 | -0.39 |
| precip mm | 37.6 | 37.1 | 47.8 | 90.7 | 103.9 | 101.9 | 90.2 | 101.3 | 70.4 | 88.4 | 59.7 | 45.5 |
| snow mm | 287 | 272 | 140 | 33 | 0 | 0 | 0 | 0 | 0 | 5 | 46 | 193 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 11.18 C, MAP 874.5 mm, warmest 24.61 C, coldest -3.33 C, Pthreshold 36.4 mm.

## Accuracy check against `chicago-greystone-twoflat`

Score = agree / (agree + differ) = **0.4** (2 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.22/0.04/0.74 | 0.35/0.06/0.59 | TVD 0.144 | 0.1 | 70 | differ |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.23/0.77/0.00 | 0.37/0.62/0.01 | TVD 0.154 | 0.15 | 2774 | differ (truth 0.12/0.72/0.17 (bins covering 97% of untagged houses); TVD to truth: draft 0.167, reference 0.257) |
| perFloor m (usage-weighted midpoint) | 3.12 | 3 | /d/ 0.12 | 0.15 | 2 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 33.5 | 33.3 | /d/ 0.2 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 62.2 | 60 | rel 0.04 | 0.15 | 3383 | agree |
| typeThresholds.largeArea m2 | 169.3 | 220 | rel 0.23 | 0.15 | 3383 | differ |
| typeThresholds.hugeArea m2 | 397.8 | 350 | rel 0.14 | 0.15 | 3383 | agree |
| trees.deciduousShare (non-conifer share) | 0.9 | 0.94 | /d/ 0.040 | 0.05 | 1 | not measurable |
| trees.heightMeters (midpoint) | [9, 15] | [8, 15] | /d/ 0.5 | 2 | 0 | not measurable |
| trees.youngShare | 0.15 | 0.22 | /d/ 0.070 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.05/0.35 | 0.60/0.10/0.30 | TVD 0.050 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #C0B09F | #B1A08C | dE00 4.8 | 10 | 8 | not measurable |
| roof colour (usage-weighted mean) | #5C636A | #5F656A | dE00 1.3 | 10 | 8 | not measurable |
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
| house roof mix G/H/F vs roof:shape | 0.35/0.06/0.59 | 0.74/0.06/0.20 | 70 | 30 | TVD 0.394 | 0.1 | contradicts | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.37/0.62/0.01 | 0.12/0.72/0.17 | 2774 | 30 | TVD 0.257 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 97%) |
| trees.deciduousShare vs broadleaved share | 0.94 | 1 | 1 | 30 | /d/ 0.060 | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 62.2 | 3383 | 30 | rel 0.04 | 0.15 | supports | share of zone houses below the reference value: 0.015 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 168.9 | 3383 | 30 | rel 0.23 | 0.15 | contradicts | share of zone houses below the reference value: 0.951 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 398.2 | 3383 | 30 | rel 0.14 | 0.15 | supports | share of zone houses below the reference value: 0.987 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | 2.91 | 2 | 20 | /d/ 0.09 | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 33.3 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B1A08C | #A57865 | 8 | 30 | dE00 15.6 | 10 | can't test | top families: red 6, grey 1, brown 1 |
| roof colour vs measured colour/material (mean) | #5F656A | #62666C | 8 | 30 | dE00 1.5 | 10 | can't test | top families: darkgrey 7, grey 1 |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| logan-square-centennial-monument | logan-square-review | chicago-greystone-twoflat | chicago-greystone-twoflat | yes | chicago-greystone-twoflat 0.9, generic-temperate-v1 0.1 | logan-square-review 90% |
| wicker-park-park | wicker-park-review | chicago-greystone-twoflat | chicago-greystone-twoflat | yes | chicago-greystone-twoflat 1 | wicker-park-review 100% |
| lincoln-square-giddings-plaza | lincoln-square-review | chicago-greystone-twoflat | chicago-greystone-twoflat | yes | chicago-greystone-twoflat 0.86, generic-temperate-v1 0.14 | lincoln-square-review 86% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| logan-square-review | chicago-greystone-twoflat | 0.9 | 1986.7 | 0.739 | 0.105 | 116.9 | 0.217 (902) |
| wicker-park-review | chicago-greystone-twoflat | 1 | 2543 | 0.613 | 0.298 | 95.1 | 0.387 (1416) |
| lincoln-square-review | chicago-greystone-twoflat | 0.865 | 2370.5 | 0.665 | 0.105 | 112.2 | 0.167 (1068) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Role dispatch for apartments: buildings with role `block` (building=apartments, yes >= 250 m2, ...) always use the FIRST flat-roof house type, so sixFlat / courtyardMass / cornerMixedUse / vintageHighRise in the reference profiles are never chosen for them; two/three-level rear porches and gangways, stoops, cornices (no geometry support); Chicago brick bungalow attic/dormer and raised basement (one roof per rectangle, no dormers).
- roof:shape is missing on 98% of houses: roof mix stays a prior; check roofs on test pictures.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
