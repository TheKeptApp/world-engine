# Region kit draft: chicagoland / evanston

**Evanston (North Shore)** - drafted 2026-10-05 by `Tools/regionkit` from template `northeast-suburbs` (docs/proposals/regions-v1/regions-draft.json#profiles/northeast-suburbs), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Closest existing vocabulary that is NOT the scored reference: detached 1-2 storey suburban houses with steep gabled (Cape/Colonial-like) and broad ranch families, no alleys assumed (regions-v1 northeast-suburbs). The town profiles in docs/proposals/regions-chicagoland-miami are the comparison references, never templates.

Comparison reference: `evanston` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| evanston-lovelace-park | Lovelace Park | way/23609354 | [42.068, -87.726] | 1 | 26 | 2026-10-06T03:56:50Z | https://overpass-api.de/api/interpreter |
| evanston-smith-park (extra) | Smith Park | way/168243511 | [42.05, -87.693] | 1 | 160 | 2026-10-06T04:27:36Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 186 / 0 |
| houses (generator role) | 94 |
| houses with building:levels | 2 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 7 / 0 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-evanston-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 42.059 |
| trees.deciduousShare | template | 0 | 0.85 | needs >= 30 trees with leaf_type or a known genus |
| trees.heightMeters | template | 0 | [9, 17] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.18 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.5, oval 0.3, spreading 0.2 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 86 | smallArea 48.8, largeArea 215.1, hugeArea 1064.8 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.5, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | template | 2 | - | needs >= 30 houses with building:levels |
| typeRules.(levels situations) | template | 0 | - | oneFloor*/twoFloor*/threeFloor/semidetached weights kept |
| houseTypes[].perFloor | template | 0 | - | needs >= 20 houses with height and levels (and roof:height or a flat roof) |
| houseTypes[].roof | template | 0 | - | needs >= 30 houses with roof:shape |
| houseTypes[].pitch | template | 0 | - | needs >= 20 houses with roof:angle |
| houseTypes[].colors[wall] | template | 1 | - | needs >= 30 houses with building:colour or a coloured building:material |
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

- Buildings: 93.0 per km2 (47.0 houses per km2). Roles: house 50% (94), block 48% (90), garage 1% (2).
- building=* values: yes 56% (104), house 10% (18), apartments 7% (13), church 6% (12), retail 6% (11), commercial 3% (6), roof 2% (4), office 2% (3), public 2% (3), residential 2% (3).
- Levels (all buildings, 2% tagged): 5+ 50% (2), 2 25% (1), 3 25% (1). Houses: 2 50% (1), 5+ 50% (1).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material brick 100% (1); building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 94 | 58 | 105.7 | 144.6 | 176.5 | 234.2 | 1.28-2.28 | 0.917-1.0 |
| garage | 2 | 44.4 | 47.3 | 52.2 | 57.1 | 60 | 1.14-1.24 | 0.999-1.0 |
| block | 90 | 180.4 | 297.7 | 645.1 | 1324 | 2039.8 | 1.23-2.58 | 0.771-0.978 |

- Probable garages among generator houses: 8 (8% of houses; 80% of the 10 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=86): footprint n 86, mean 207.9, p10 84.9, p25 121.6, p50 150.3, p75 183.5, p90 238.2; levels 2 50% (1), 5+ 50% (1); facade-to-curb n 83, mean 15.63, p10 8.73, p25 10.46, p50 12.94, p75 17.05, p90 33.13; long side faces street 24%.
- Footprint classes (houses): rectangle 78% (73), orthogonal 17% (16), irregular 3% (3), nearRectangle 2% (2).
- Situations with template thresholds: unknown 76% (71), large 12% (11), small 11% (10), threeFloor 1% (1), twoFloorSquare 1% (1).
- Use mix (non-outbuildings, by count): residential 63% (113), commercial 13% (24), unknown 12% (22), other 12% (21); by footprint area: residential 0.293, other 0.207, residential (landuse) 0.193, unknown 0.158, commercial 0.128, commercial (tags/POI) 0.016, commercial (landuse) 0.005.
- Setback (facade to curb, 91 of 94 houses): median 13.14 m, IQR 10.72-18.15 m; centreline 16.73 m median; 0 negative.
- Long side faces the street: 24% of 91 houses with a front edge.
- Coverage proxies: net 0.011 (residential landuse 72% of the cell), gross 0.051; water 0%.
- Alleys: 5.055 km/km2; houses within 30 m of an alley 84%; garages adjacent to an alley 50% (engine alley edge 50%); driveways 0.262 km/km2.
- Barriers per km2 / per 100 houses: fence 0.255 km / 542.1 m, wall 0.0 / 0.0, hedge 0.0 / 0.0, retaining wall 0.0 / 0.0.
- Trees: 7 mapped (3.5 per km2); tree rows 0.0 km/km2; wood 0%, park 7% of the cell. leaf_type tagged: -; leaf_cycle tagged: -; with genus fallback: type -, cycle -. Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): cycleway 0.597, footway 18.121, path 0.046, residential 7.748, secondary 3.566, secondary_link 0.009, service 9.118, steps 0, tertiary 1.702; sidewalks 15.287.

### Tag coverage (% missing)

| tag | buildings (n=186) | houses (n=94) |
|---|---|---|
| building:levels | 98% | 98% |
| height | 100% | 100% |
| roof:shape | 100% | 100% |
| roof:levels | 100% | 100% |
| roof:height | 100% | 100% |
| roof:angle | 100% | 100% |
| roof:material | 100% | 100% |
| roof:colour | 100% | 100% |
| building:material | 100% | 99% |
| building:colour | 100% | 100% |
| start_date | 100% | 99% |

### Family signature hints

Principal houses (generator houses minus probable garages): -% 1-storey, 50% 2-storey, 50% 3+ (of 2 houses with levels, 2% of houses); footprints p25-p75 121.6-183.5 m2 (median 150.3); aspect p25-p75 1.33-2.32; rectangle short side p25-p75 7.7-11.2 m, long side 13.5-20.9 m; long side faces the street on 24% of houses (narrow end to the street on 76%); 8 generator 'houses' (8%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 12.94 m (IQR 10.46-17.05).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 11.0 km away (elev 192.0 m). Snow: USC00111497 CHICAGO BOTANIC GARDEN, IL US, 11.0 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -4.28 | -2.5 | 2.78 | 8.44 | 14.39 | 19.94 | 23 | 22.33 | 18.28 | 11.5 | 4.89 | -1.17 |
| precip mm | 53.3 | 50.3 | 57.4 | 101.6 | 122.9 | 109.5 | 95 | 105.7 | 90.4 | 91.2 | 66.8 | 59.4 |
| snow mm | 287 | 196 | 142 | 28 | 0 | 0 | 0 | 0 | 0 | 3 | 48 | 150 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 9.8 C, MAP 1003.5 mm, warmest 23.0 C, coldest -4.28 C, Pthreshold 33.6 mm.

## Accuracy check against `evanston`

Score = agree / (agree + differ) = **0** (0 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.92/0.06/0.02 | 0.62/0.29/0.09 | TVD 0.304 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.70/0.30/0.00 | 0.13/0.87/0.00 | TVD 0.569 | 0.15 | 2 | not measurable (truth 0.00/0.14/0.86 (bins covering 8% of untagged houses); TVD to truth: draft 0.857, reference 0.857) |
| perFloor m (usage-weighted midpoint) | 3.05 | 3 | /d/ 0.05 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 35.4 | 35.1 | /d/ 0.3 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 48.8 | 60 | rel 0.19 | 0.15 | 86 | differ |
| typeThresholds.largeArea m2 | 215.1 | 260 | rel 0.17 | 0.15 | 86 | differ |
| typeThresholds.hugeArea m2 | 1064.8 | 420 | rel 1.54 | 0.15 | 86 | differ |
| trees.deciduousShare (non-conifer share) | 0.85 | 0.92 | /d/ 0.070 | 0.05 | 0 | not measurable |
| trees.heightMeters (midpoint) | [9, 17] | [10, 18] | /d/ 1.0 | 2 | 0 | not measurable |
| trees.youngShare | 0.18 | 0.18 | /d/ 0.000 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.10/0.30 | 0.60/0.10/0.30 | TVD 0.000 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B4B5A8 | #B29A84 | dE00 13.3 | 10 | 1 | not measurable |
| roof colour (usage-weighted mean) | #636970 | #61666A | dE00 2.0 | 10 | 0 | not measurable |
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
| house roof mix G/H/F vs roof:shape | 0.62/0.29/0.09 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.13/0.87/0.00 | 0.00/0.14/0.86 | 2 | 30 | TVD 0.857 | 0.15 | can't test | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 8%) |
| trees.deciduousShare vs broadleaved share | 0.92 | - | 0 | 30 | - | 0.05 | can't test |  |
| trees.heightMeters vs tagged heights p25-p75 | [10, 18] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 44.8 | 86 | 30 | rel 0.25 | 0.15 | contradicts | share of zone houses below the reference value: 0.035 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 260 | 213.4 | 86 | 30 | rel 0.18 | 0.15 | contradicts | share of zone houses below the reference value: 0.919 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 420 | 1314.2 | 86 | 30 | rel 2.13 | 0.15 | contradicts | share of zone houses below the reference value: 0.919 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 35.1 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #B29A84 | #A9735F | 1 | 30 | dE00 14.8 | 10 | can't test | top families: red 1 |
| roof colour vs measured colour/material (mean) | #61666A | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| evanston-lovelace-park | wilmette-inland-review | wilmette | evanston | NO | wilmette 0.72, generic-temperate-v1 0.28 | wilmette-inland-review 72% |
| evanston-smith-park | evanston-inland-review | evanston | evanston | yes | evanston 0.98, generic-temperate-v1 0.02 | evanston-inland-review 98% |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| evanston-inland-review | evanston | 0.98 | 163.2 | 0.55 | 0.444 | 144.6 | 0.75 (4) |
| wilmette-inland-review | wilmette | 0.722 | 16.6 | 0.417 | 0.583 | 169.6 | - (0) |

## Needs a human eye

- Template-only (no open data): `trees.deciduousShare`, `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.unknown/small/large`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Generator support for the reference families' identity (cross-gables, dormers, steep Tudor roofs with chimneys, broad Prairie eaves, turrets): the profiles now name them, but BuildingGenerator renders one gabled/hipped/flat roof per rectangle; raised ranch / split-level (half-levels are rounded by the generator); courtyard apartments (role block always takes the first flat-roof type).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- building:levels is missing on 98% of houses: storey defaults come from the house-type lottery.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
