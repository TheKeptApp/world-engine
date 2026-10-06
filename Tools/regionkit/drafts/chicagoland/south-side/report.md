# Region kit draft: chicagoland / south-side

**Chicago South Side (Hyde Park, Bronzeville)** - drafted 2026-10-05 by `Tools/regionkit` from template `front-range` (Sources/WorldGen/Profiles/front-range.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Greystones, brick flats, row houses and large period houses; front-range's flat-roof multi-storey families plus foursquare are the nearest vocabulary.

Comparison reference: `chicago-south-historic` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| hyde-park-nichols-park | Nichols Park | way/217621413 | [41.797, -87.594] | 1 | 1194 | 2026-10-06T04:12:11Z | https://overpass-api.de/api/interpreter |
| bronzeville-ellis-park | Ellis Park | way/35332716 | [41.829, -87.611] | 1 | 267 | 2026-10-06T04:13:00Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 1461 / 2 |
| houses (generator role) | 1107 |
| houses with building:levels | 460 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 10 / 10 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-south-side-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 41.813 |
| trees.deciduousShare | template | 10 | 0.9 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 15] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.15 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.45, oval 0.3, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 995 | smallArea 49.3, largeArea 223.3, hugeArea 870.6 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.4, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 458 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
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

- Buildings: 730.5 per km2 (553.5 houses per km2). Roles: house 76% (1107), block 21% (307), garage 2% (34), shed 1% (13).
- building=* values: yes 53% (768), residential 20% (296), apartments 7% (105), house 7% (104), garage 2% (33), semidetached_house 2% (30), terrace 2% (29), retail 2% (28), detached 2% (26), church 1% (10).
- Levels (all buildings, 43% tagged): 3 46% (288), 2 41% (261), 1 5% (33), 5+ 5% (31), 4 3% (18). Houses: 2 54% (250), 3 39% (181), 1 4% (17), 4 2% (11), 5+ 0% (1).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 1107 | 50.1 | 72.3 | 97.6 | 144.5 | 242.2 | 1.56-2.42 | 0.878-0.993 |
| garage | 34 | 29.7 | 38.7 | 51.2 | 70.1 | 99.4 | 1.09-1.42 | 0.976-0.998 |
| shed | 13 | 5.8 | 6 | 6.5 | 8.2 | 10.3 | 1.1-1.47 | 0.955-0.998 |
| block | 307 | 256.9 | 316.7 | 423.8 | 894.6 | 1436.9 | 1.35-2.37 | 0.765-0.92 |

- Probable garages among generator houses: 112 (10% of houses; 76% of the 148 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=995): footprint n 995, mean 156, p10 65.8, p25 78.4, p50 103.1, p75 154.3, p90 252.4; levels 2 54% (248), 3 40% (181), 1 4% (17), 4 2% (11), 5+ 0% (1); facade-to-curb n 974, mean 15.8, p10 7.41, p25 9.16, p50 11.56, p75 15.31, p90 37.14; long side faces street 24%.
- Footprint classes (houses): rectangle 69% (761), orthogonal 29% (320), nearRectangle 1% (15), irregular 1% (11).
- Situations with template thresholds: unknown 39% (427), twoFloorNarrow 18% (197), threeFloor 17% (191), small 14% (150), large 5% (56), twoFloor 3% (36), semidetached 3% (30), oneFloor 1% (16), twoFloorSquare 0% (3), oneFloorBroad 0% (1).
- Use mix (non-outbuildings, by count): residential 94% (1327), commercial 3% (46), other 2% (24), mixed 1% (13), unknown 0% (2); by footprint area: residential 0.388, residential (landuse) 0.288, commercial 0.161, other 0.108, mixed 0.049, commercial (tags/POI) 0.004, commercial (landuse) 0.001, unknown 0.
- Setback (facade to curb, 1082 of 1107 houses): median 12.19 m, IQR 9.36-18.85 m; centreline 15.2 m median; 0 negative.
- Long side faces the street: 25% of 1025 houses with a front edge.
- Coverage proxies: net 0.123 (residential landuse 64% of the cell), gross 0.209; water 0%.
- Alleys: 3.928 km/km2; houses within 30 m of an alley 52%; garages adjacent to an alley 79% (engine alley edge 97%); driveways 1.414 km/km2.
- Barriers per km2 / per 100 houses: fence 0.034 km / 6.2 m, wall 0.375 / 67.7, hedge 0.0 / 0.0, retaining wall 0.027 / 4.8.
- Trees: 10 mapped (5.0 per km2); tree rows 0.0 km/km2; wood 0%, park 10% of the cell. leaf_type tagged: broadleaved 100% (10); leaf_cycle tagged: deciduous 100% (1); with genus fallback: type broadleaved 100% (10), cycle deciduous 100% (1). Top genus: Ulmus 100% (1). Palm share (trees with genus): 0. Heights: n 0.
- Streets (km/km2): cycleway 1.41, emergency_bay 0.089, footway 27.065, living_street 0.08, motorway 0.521, path 0.574, pedestrian 0.067, residential 8.847, secondary 1.263, service 12.125, steps 0.009, tertiary 2.071, track 0.696; sidewalks 21.184.

### Tag coverage (% missing)

| tag | buildings (n=1461) | houses (n=1107) |
|---|---|---|
| building:levels | 57% | 58% |
| height | 100% | 100% |
| roof:shape | 100% | 100% |
| roof:levels | 93% | 94% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 100% | 100% |
| building:material | 100% | 100% |
| building:colour | 100% | 100% |
| start_date | 100% | 100% |

### Family signature hints

Principal houses (generator houses minus probable garages): 4% 1-storey, 54% 2-storey, 42% 3+ (of 458 houses with levels, 46% of houses); footprints p25-p75 78.4-154.3 m2 (median 103.1); aspect p25-p75 1.7-2.55; rectangle short side p25-p75 6.2-9.1 m, long side 12.5-20.9 m; long side faces the street on 24% of houses (narrow end to the street on 76%); 112 generator 'houses' (10%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 11.56 m (IQR 9.16-15.31).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00014819 CHICAGO MIDWAY AP, IL US, 12.8 km away (elev 186.5 m). Snow: USC00111577 CHICAGO MIDWAY AP 3SW, IL US, 16.8 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -3.33 | -1.28 | 4.22 | 10.33 | 16.39 | 22 | 24.61 | 23.61 | 19.72 | 12.72 | 5.56 | -0.39 |
| precip mm | 37.6 | 37.1 | 47.8 | 90.7 | 103.9 | 101.9 | 90.2 | 101.3 | 70.4 | 88.4 | 59.7 | 45.5 |
| snow mm | 318 | 257 | 145 | 25 | 0 | 0 | 0 | 0 | 0 | 3 | 38 | 201 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 11.18 C, MAP 874.5 mm, warmest 24.61 C, coldest -3.33 C, Pthreshold 36.4 mm.

## Accuracy check against `chicago-south-historic`

Score = agree / (agree + differ) = **0.25** (1 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.21/0.08/0.71 | 0.39/0.07/0.54 | TVD 0.176 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.36/0.64/0.00 | 0.15/0.69/0.16 | TVD 0.208 | 0.15 | 458 | differ (truth 0.03/0.49/0.48 (bins covering 98% of untagged houses); TVD to truth: draft 0.477, reference 0.313) |
| perFloor m (usage-weighted midpoint) | 3.12 | 3 | /d/ 0.12 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 29.6 | 37.6 | /d/ 8.0 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 49.3 | 60 | rel 0.18 | 0.15 | 995 | differ |
| typeThresholds.largeArea m2 | 223.3 | 220 | rel 0.02 | 0.15 | 995 | agree |
| typeThresholds.hugeArea m2 | 870.6 | 350 | rel 1.49 | 0.15 | 995 | differ |
| trees.deciduousShare (non-conifer share) | 0.9 | 0.94 | /d/ 0.040 | 0.05 | 10 | not measurable |
| trees.heightMeters (midpoint) | [9, 15] | [8, 15] | /d/ 0.5 | 2 | 0 | not measurable |
| trees.youngShare | 0.15 | 0.22 | /d/ 0.070 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.05/0.35 | 0.60/0.10/0.30 | TVD 0.050 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #BEAD9C | #B29F8A | dE00 4.3 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #5C636A | #5E656A | dE00 1.4 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

1 supported, 3 contradicted, 8 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.39/0.07/0.54 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.15/0.69/0.16 | 0.03/0.49/0.48 | 458 | 30 | TVD 0.313 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 98%) |
| trees.deciduousShare vs broadleaved share | 0.94 | 1 | 10 | 30 | /d/ 0.060 | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 49 | 995 | 30 | rel 0.18 | 0.15 | contradicts | share of zone houses below the reference value: 0.043 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 223.4 | 995 | 30 | rel 0.02 | 0.15 | supports | share of zone houses below the reference value: 0.861 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 886.2 | 995 | 30 | rel 1.53 | 0.15 | contradicts | share of zone houses below the reference value: 0.927 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 37.6 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B29F8A | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #5E656A | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| hyde-park-nichols-park | hyde-kenwood-review | chicago-south-historic | chicago-south-historic | yes | chicago-south-historic 0.98, generic-temperate-v1 0.02 | hyde-kenwood-review 98% |
| bronzeville-ellis-park | (none: defaultProfile) | generic-temperate-v1 | chicago-south-historic | NO | generic-temperate-v1 0.684, chicago-south-historic 0.316 | bronzeville-review 32% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| hyde-kenwood-review | chicago-south-historic | 0.982 | 1212.9 | 0.785 | 0.186 | 95.2 | 0.507 (534) |
| bronzeville-review | chicago-south-historic | 0.318 | 198.2 | 0.762 | 0.238 | 147.7 | 0.75 (32) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Role dispatch for apartments: buildings with role `block` (building=apartments, yes >= 250 m2, ...) always use the FIRST flat-roof house type, so sixFlat / courtyardMass / cornerMixedUse / vintageHighRise in the reference profiles are never chosen for them; two/three-level rear porches and gangways, stoops, cornices (no geometry support); Chicago brick bungalow attic/dormer and raised basement (one roof per rectangle, no dormers).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
