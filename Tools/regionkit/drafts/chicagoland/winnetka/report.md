# Region kit draft: chicagoland / winnetka

**Winnetka (North Shore)** - drafted 2026-10-05 by `Tools/regionkit` from template `northeast-suburbs` (docs/proposals/regions-v1/regions-draft.json#profiles/northeast-suburbs), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Closest existing vocabulary that is NOT the scored reference: detached 1-2 storey suburban houses with steep gabled (Cape/Colonial-like) and broad ranch families, no alleys assumed (regions-v1 northeast-suburbs). The town profiles in docs/proposals/regions-chicagoland-miami are the comparison references, never templates.

Comparison reference: `winnetka` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| winnetka-village-green | Village Green | way/184364632 | [42.105, -87.729] | 1 | 49 | 2026-10-06T04:05:05Z | https://overpass-api.de/api/interpreter |

Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 49 / 0 |
| houses (generator role) | 13 |
| houses with building:levels | 0 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 2 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-winnetka-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 42.105 |
| trees.deciduousShare | template | 0 | 0.85 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 17] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.18 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.5, oval 0.3, spreading 0.2 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | template | 13 | smallArea 60, largeArea 220, hugeArea 350 |  |
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

- Buildings: 49.0 per km2 (13.0 houses per km2). Roles: block 71% (35), house 26% (13), garage 2% (1).
- building=* values: yes 33% (16), retail 16% (8), house 14% (7), commercial 12% (6), public 6% (3), apartments 4% (2), barn 2% (1), church 2% (1), civic 2% (1), garage 2% (1).
- Levels (all buildings, 6% tagged): 1 67% (2), 2 33% (1). Houses: -.
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 13 | 26.9 | 50.9 | 174.8 | 205.4 | 248.7 | 1.1-1.69 | 0.946-0.997 |
| garage | 1 | 52.9 | 52.9 | 52.9 | 52.9 | 52.9 | 1.01-1.01 | 0.869-0.869 |
| block | 35 | 234.5 | 314.3 | 646.4 | 945 | 1169 | 1.22-2.11 | 0.693-0.928 |

- Probable garages among generator houses: 0 (0% of houses; 0% of the 4 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=13): footprint n 13, mean 148.2, p10 26.9, p25 50.9, p50 174.8, p75 205.4, p90 248.7; levels -; facade-to-curb n 13, mean 23.14, p10 8.2, p25 12.89, p50 22.88, p75 28.19, p90 42.7; long side faces street 54%.
- Footprint classes (houses): rectangle 77% (10), orthogonal 15% (2), irregular 8% (1).
- Situations with template thresholds: unknown 54% (7), small 31% (4), large 15% (2).
- Use mix (non-outbuildings, by count): commercial 46% (22), residential 19% (9), unknown 19% (9), other 17% (8); by footprint area: commercial 0.415, other 0.224, residential 0.132, unknown 0.119, commercial (landuse) 0.11.
- Setback (facade to curb, 13 of 13 houses): median 22.88 m, IQR 12.89-28.19 m; centreline 25.88 m median; 0 negative.
- Long side faces the street: 54% of 13 houses with a front edge.
- Coverage proxies: net 0.002 (residential landuse 74% of the cell), gross 0.03; water 0%.
- Alleys: 0.34 km/km2; houses within 30 m of an alley 8%; garages adjacent to an alley 0% (engine alley edge 100%); driveways 1.18 km/km2.
- Barriers per km2 / per 100 houses: fence 0.359 km / 2758.1 m, wall 0.0 / 0.0, hedge 0.039 / 300.0, retaining wall 0.0 / 0.0.
- Trees: 2 mapped (2.0 per km2); tree rows 0.0 km/km2; wood 0%, park 2% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 0.995, footway 9.234, path 0.025, residential 8.858, secondary 1.372, service 3.815, steps 0.135, tertiary 2.582; sidewalks 7.65.

### Tag coverage (% missing)

| tag | buildings (n=49) | houses (n=13) |
|---|---|---|
| building:levels | 94% | 100% |
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

Principal houses (generator houses minus probable garages): no building:levels on houses; footprints p25-p75 50.9-205.4 m2 (median 174.8); aspect p25-p75 1.1-1.69; rectangle short side p25-p75 5.3-15.9 m, long side 9.5-18.0 m; long side faces the street on 54% of houses (narrow end to the street on 46%); facade-to-curb median 22.88 m (IQR 12.89-28.19).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 6.1 km away (elev 192.0 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 6.1 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -4.28 | -2.5 | 2.78 | 8.44 | 14.39 | 19.94 | 23 | 22.33 | 18.28 | 11.5 | 4.89 | -1.17 |
| precip mm | 53.3 | 50.3 | 57.4 | 101.6 | 122.9 | 109.5 | 95 | 105.7 | 90.4 | 91.2 | 66.8 | 59.4 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 9.8 C, MAP 1003.5 mm, warmest 23.0 C, coldest -4.28 C, Pthreshold 33.6 mm.

## Accuracy check against `winnetka`

Score = agree / (agree + differ) = **-** (0 agree, 0 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.92/0.03/0.05 | 0.62/0.32/0.06 | TVD 0.297 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | - | - | - | 0.15 | 0 | not measurable |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 37.1 | 35.2 | /d/ 2.0 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 60 | 60 | rel 0.00 | 0.15 | 13 | not measurable |
| typeThresholds.largeArea m2 | 220 | 260 | rel 0.15 | 0.15 | 13 | not measurable |
| typeThresholds.hugeArea m2 | 350 | 420 | rel 0.17 | 0.15 | 13 | not measurable |
| trees.deciduousShare (non-conifer share) | 0.85 | 0.91 | /d/ 0.060 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [9, 17] | [12, 20] | /d/ 3.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.18 | 0.18 | /d/ 0.000 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B6B6A8 | #B39A84 | dE00 13.4 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #636970 | #616669 | dE00 2.5 | 10 | 0 | not measurable |
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
| house roof mix G/H/F vs roof:shape | 0.62/0.32/0.06 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | - | - | 0 | 30 | - | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 0%) |
| trees.deciduousShare vs broadleaved share | 0.91 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [12, 20] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 22.5 | 13 | 30 | rel 0.63 | 0.15 | can't test | share of zone houses below the reference value: 0.308 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 260 | 230.4 | 13 | 30 | rel 0.11 | 0.15 | can't test | share of zone houses below the reference value: 0.923 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 420 | 296.1 | 13 | 30 | rel 0.29 | 0.15 | can't test | share of zone houses below the reference value: 1.000 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 35.2 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B39A84 | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #616669 | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| winnetka-village-green | (none: defaultProfile) | generic-temperate-v1 | winnetka | NO | generic-temperate-v1 0.59, winnetka 0.41 | winnetka-inland-review 41% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| winnetka-inland-review | winnetka | 0.409 | 117.4 | 0.25 | 0.729 | 152 | 0 (3) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.smallArea/largeArea/hugeArea`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Generator support for the reference families' identity (cross-gables, dormers, steep Tudor roofs with chimneys, broad Prairie eaves, turrets): the profiles now name them, but BuildingGenerator renders one gabled/hipped/flat roof per rectangle; raised ranch / split-level (half-levels are rounded by the generator); courtyard apartments (role block always takes the first flat-roof type).
- Data flags: large area relation not fetched (>= 300 members): natural=water, water=lake, name=Lake Michigan.
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 100% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
