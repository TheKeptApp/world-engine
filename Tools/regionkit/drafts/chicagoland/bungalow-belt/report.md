# Region kit draft: chicagoland / bungalow-belt

**Chicago bungalow belt (Portage Park)** - drafted 2026-10-05 by `Tools/regionkit` from template `front-range` (Sources/WorldGen/Profiles/front-range.json), shrinkage k = 30. This is a starting point for human review, not a finished profile.

Template choice: Front-range has the only bungalow family (1 floor, mostly gabled); the Chicago brick bungalow is a different form (hipped, 1.5 storeys, narrow side to the street) but the nearest existing vocabulary.

Comparison reference: `chicago-bungalow-belt` (a hand-made prior, itself unmeasured).

## Sample cells

| cell | anchor | OSM feature | centre | km2 | buildings | OSM base | source |
|---|---|---|---|---|---|---|---|
| portage-park-park | Portage Park | way/208236541 | [41.955, -87.765] | 1 | 2451 | 2026-10-06T04:12:11Z | https://overpass-api.de/api/interpreter |
| jefferson-park-park (extra) | Jefferson Park | way/27861631 | [41.969, -87.764] | 1 | 1676 | 2026-10-06T04:12:11Z | https://overpass-api.de/api/interpreter |

## Confidence: sample sizes and what was calibrated

| measure | n |
|---|---|
| buildings (outlines) / building:part | 4127 / 0 |
| houses (generator role) | 3849 |
| houses with building:levels | 1895 |
| houses with roof:shape | 0 |
| houses with roof:angle | 0 |
| houses with height + levels (wall m/level) | 0 |
| houses with building:colour / roof:colour | 0 / 0 |
| garages with roof:shape | 0 |
| trees / with leaf type (tag or genus) / with height | 53 / 53 / 0 |

| field | status | n | value | note |
|---|---|---|---|---|
| id | default | 0 | chicagoland-bungalow-belt-draft | region-zone-draft |
| seasons | default | 0 | hemisphere north, spring [3, 4, 5], summer [6, 7, 8], autumn [9, 10, 11], winter [12, 1, 2] | meteorological seasons from latitude 41.962 |
| trees.deciduousShare | calibrated | 53 | 0.964 | generator treats this as NON-CONIFER share (SceneGenerator: !chance(deciduousShare) -> conifer); true leaf cycle is reported separately |
| trees.heightMeters | template | 0 | [9, 15] | needs >= 30 tagged heights |
| trees.youngShare | template | 0 | 0.15 | needs >= 30 tagged heights |
| trees.crownWeights | template | 0 | broad 0.45, oval 0.3, spreading 0.25 | no open data on crown form; review visually |
| trees.youngHeightMeters | template | 0 | [4, 7] |  |
| typeThresholds.smallArea/largeArea/hugeArea | calibrated | 2139 | smallArea 61.6, largeArea 167.8, hugeArea 229.7 | reference distribution is Denver's; in the Denver check these fields are excluded from the score |
| typeThresholds.aspect/rectangularity | template | 0 | broadAspect 1.7, squareAspect 1.4, squareRectangularity 0.78, narrowAspect 1.7 |  |
| typeRules.unknown/small/large | calibrated | 1894 | (see measurements.json) | principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin  |
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

Calibrated from data: `trees.deciduousShare`, `typeThresholds.smallArea/largeArea/hugeArea`, `typeRules.unknown/small/large`. Everything else is template or rule-based.

## Measurements

- Buildings: 2063.5 per km2 (1924.5 houses per km2). Roles: house 93% (3849), block 6% (239), shed 0% (22), garage 0% (17).
- building=* values: yes 97% (4020), retail 1% (24), apartments 0% (16), garage 0% (16), commercial 0% (10), roof 0% (8), public 0% (7), church 0% (5), detached 0% (5), school 0% (3).
- Levels (all buildings, 50% tagged): 1 52% (1060), 2 44% (905), 3 4% (76), 4 0% (4), 5+ 0% (4). Houses: 1 54% (1016), 2 44% (844), 3 2% (34), 4 0% (1).
- Metres per level (houses, wall): n 0; all buildings total: n 0.
- Heights (houses): n 0; blocks: n 0.
- roof:shape on houses (0%): raw -; mapped -. Garages: -.
- Materials/colours: roof:material -; building:material -; building:colour families -; roof:colour families -.

| role | n | area p10 | p25 | p50 | p75 | p90 | aspect p25-p75 | rectangularity p25-p75 |
|---|---|---|---|---|---|---|---|---|
| house | 3849 | 37.5 | 44.6 | 92.3 | 139.6 | 160.6 | 1.11-2.29 | 0.962-0.996 |
| garage | 17 | 30.1 | 33.7 | 43.5 | 50.3 | 65.5 | 1.03-1.46 | 0.998-0.999 |
| shed | 22 | 4.5 | 5 | 6.1 | 8.6 | 11.9 | 1.33-2.0 | 0.966-0.999 |
| block | 239 | 260.1 | 288 | 399 | 593.8 | 1138 | 1.46-2.8 | 0.79-0.988 |

- Probable garages among generator houses: 1710 (44% of houses; 98% of the 1738 small building=yes houses sit next to a service road). The generator gives them house families, doors and windows.
- Principal houses (n=2139): footprint n 2139, mean 135.1, p10 92.3, p25 116.2, p50 136.2, p75 154.6, p90 174; levels 1 54% (1016), 2 44% (843), 3 2% (34), 4 0% (1); facade-to-curb n 2132, mean 12.68, p10 8.11, p25 10.36, p50 11.69, p75 12.89, p90 14.47; long side faces street 16%.
- Footprint classes (houses): rectangle 92% (3547), orthogonal 8% (291), nearRectangle 0% (9), irregular 0% (2).
- Situations with template thresholds: small 45% (1734), oneFloor 24% (914), twoFloorNarrow 20% (774), unknown 6% (211), oneFloorBroad 3% (102), twoFloor 1% (51), threeFloor 1% (35), twoFloorSquare 0% (19), large 0% (9).
- Use mix (non-outbuildings, by count): residential 95% (3861), commercial 3% (122), unknown 2% (74), other 0% (22), mixed 0% (2); by footprint area: residential (landuse) 0.771, commercial 0.064, other 0.055, commercial (landuse) 0.033, commercial (tags/POI) 0.029, unknown 0.022, residential 0.022, mixed 0.005.
- Setback (facade to curb, 3840 of 3849 houses): median 13.69 m, IQR 11.15-36.67 m; centreline 16.77 m median; 0 negative.
- Long side faces the street: 26% of 3828 houses with a front edge.
- Coverage proxies: net 0.267 (residential landuse 66% of the cell), gross 0.255; water 0%.
- Alleys: 8.8 km/km2; houses within 30 m of an alley 99%; garages adjacent to an alley 100% (engine alley edge 100%); driveways 0.371 km/km2.
- Barriers per km2 / per 100 houses: fence 0.692 km / 35.9 m, wall 1.24 / 64.4, hedge 0.0 / 0.0, retaining wall 0.685 / 35.6.
- Trees: 53 mapped (26.5 per km2); tree rows 0.0 km/km2; wood 0%, park 12% of the cell. leaf_type tagged: broadleaved 100% (53); leaf_cycle tagged: deciduous 100% (53); with genus fallback: type broadleaved 100% (53), cycle deciduous 100% (53). Top genus: -. Palm share (trees with genus): -. Heights: n 0.
- Streets (km/km2): busway 0.613, footway 28.033, motorway 0.941, motorway_link 0.231, path 0.668, pedestrian 0.576, platform 0.17, primary 0.5, residential 9.52, secondary 2.442, secondary_link 0.019, service 12.063, steps 0.048, tertiary 0.388; sidewalks 23.528.

### Tag coverage (% missing)

| tag | buildings (n=4127) | houses (n=3849) |
|---|---|---|
| building:levels | 50% | 51% |
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

Principal houses (generator houses minus probable garages): 54% 1-storey, 44% 2-storey, 2% 3+ (of 1894 houses with levels, 88% of houses); footprints p25-p75 116.2-154.6 m2 (median 136.2); aspect p25-p75 2.0-2.49; rectangle short side p25-p75 7.5-8.4 m, long side 15.9-19.7 m; long side faces the street on 16% of houses (narrow end to the street on 84%); 1710 generator 'houses' (44%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here; facade-to-curb median 11.69 m (IQR 10.36-12.89).

## Climate (NOAA NCEI 1991-2020 normals)

Temperature/precipitation: USW00094846 CHICAGO OHARE INTL AP, IL US, 14.5 km away (elev 200.6 m). Snow: USW00094846 CHICAGO OHARE INTL AP, IL US, 14.5 km.

|  | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mean temp C | -3.78 | -1.78 | 3.89 | 9.83 | 15.89 | 21.44 | 24.11 | 23.22 | 19.06 | 12.22 | 5.17 | -0.83 |
| precip mm | 50.5 | 50 | 62.2 | 95.2 | 114 | 104.1 | 94.2 | 107.9 | 81 | 87.1 | 61.5 | 53.6 |
| snow mm | 287 | 272 | 140 | 33 | 0 | 0 | 0 | 0 | 0 | 5 | 46 | 193 |

Koppen-Geiger: **Dfa** (0 C C/D threshold; Dfa with the -3 C variant). MAT 10.7 C, MAP 961.3 mm, warmest 24.11 C, coldest -3.78 C, Pthreshold 35.4 mm.

## Accuracy check against `chicago-bungalow-belt`

Score = agree / (agree + differ) = **0.4** (2 agree, 3 differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests.

| field | draft | reference | metric | tolerance | n | verdict |
|---|---|---|---|---|---|---|
| house roof mix G/H/F (expected on zone houses) | 0.51/0.10/0.39 | 0.47/0.43/0.10 | TVD 0.327 | 0.1 | 0 | not measurable |
| default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses) | 0.52/0.48/0.00 | 0.98/0.02/0.00 | TVD 0.462 | 0.15 | 1894 | differ (truth 0.39/0.59/0.02 (bins covering 94% of untagged houses); TVD to truth: draft 0.131, reference 0.593) |
| perFloor m (usage-weighted midpoint) | 3.16 | 3 | /d/ 0.16 | 0.15 | 0 | not measurable |
| pitch deg (usage-weighted midpoint, pitched families) | 30.1 | 27.2 | /d/ 2.8 | 4 | 0 | not measurable |
| typeThresholds.smallArea m2 | 61.6 | 60 | rel 0.03 | 0.15 | 2139 | agree |
| typeThresholds.largeArea m2 | 167.8 | 220 | rel 0.24 | 0.15 | 2139 | differ |
| typeThresholds.hugeArea m2 | 229.7 | 350 | rel 0.34 | 0.15 | 2139 | differ |
| trees.deciduousShare (non-conifer share) | 0.964 | 0.94 | /d/ 0.024 | 0.05 | 53 | agree |
| trees.heightMeters (midpoint) | [9, 15] | [8, 15] | /d/ 0.5 | 2 | 0 | not measurable |
| trees.youngShare | 0.15 | 0.22 | /d/ 0.070 | 0.05 | 0 | not measurable |
| garage.roof G/H/F | 0.60/0.05/0.35 | 0.60/0.10/0.30 | TVD 0.050 | 0.15 | 0 | not measurable |
| wall colour (usage-weighted mean) | #B89B87 | #AA927D | dE00 3.9 | 10 | 0 | not measurable |
| roof colour (usage-weighted mean) | #5E6266 | #60666A | dE00 1.7 | 10 | 0 | not measurable |
| trees.crownWeights | - | - | - | - | 0 | not measurable (template only) |
| trees.youngHeightMeters | - | - | - | - | 0 | not measurable (template only) |
| typeThresholds aspect/rectangularity | - | - | - | - | 0 | not measurable (template only) |
| porch/windows/door/overhang/parapet | - | - | - | - | 0 | not measurable (template only) |
| chimneyLikelihood | - | - | - | - | 0 | not measurable (template only) |
| foundationMeters | - | - | - | - | 0 | not measurable (template only) |
| garage wallHeight/pitch/colours, shed | - | - | - | - | 0 | not measurable (template only) |
| seasons (hemisphere + months) | north | north | equal | - | 0 | not scored (rule-based from latitude, not data) |

### Reference values tested directly against the measurements (no shrinkage)

1 supported, 4 contradicted, 7 can't be tested (sample below the gate).

| reference value | reference | measured | n | gate | metric | tolerance | verdict | note |
|---|---|---|---|---|---|---|---|---|
| house roof mix G/H/F vs roof:shape | 0.47/0.43/0.10 | - | 0 | 30 | - | 0.1 | can't test | tagged houses may not be representative |
| default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile) | 0.98/0.02/0.00 | 0.39/0.59/0.02 | 1894 | 30 | TVD 0.593 | 0.15 | contradicts | tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover 94%) |
| trees.deciduousShare vs broadleaved share | 0.94 | 1 | 53 | 30 | /d/ 0.060 | 0.05 | contradicts |  |
| trees.heightMeters vs tagged heights p25-p75 | [8, 15] | - | 0 | 30 | - | 2 | can't test |  |
| typeThresholds.smallArea vs footprint quantile at Denver's percentile | 60 | 61.7 | 2139 | 30 | rel 0.03 | 0.15 | supports | share of zone houses below the reference value: 0.014 (front-range 60 is the 0.021 quantile in Denver) |
| typeThresholds.largeArea vs footprint quantile at Denver's percentile | 220 | 167.1 | 2139 | 30 | rel 0.24 | 0.15 | contradicts | share of zone houses below the reference value: 0.983 (front-range 220 is the 0.865 quantile in Denver) |
| typeThresholds.hugeArea vs footprint quantile at Denver's percentile | 350 | 228 | 2139 | 30 | rel 0.35 | 0.15 | contradicts | share of zone houses below the reference value: 1.000 (front-range 350 is the 0.990 quantile in Denver) |
| garage.roof vs garage roof:shape | 0.60/0.10/0.30 | - | 0 | 20 | - | 0.15 | can't test |  |
| perFloor vs measured wall height per level (median) | 3 | - | 0 | 20 | - | 0.15 | can't test |  |
| pitch vs roof:angle (median) | 27.2 | - | 0 | 20 | - | 4 | can't test |  |
| wall colour vs measured colour/material (mean) | #AA927D | - | 0 | 30 | - | 10 | can't test |  |
| roof colour vs measured colour/material (mean) | #60666A | - | 0 | 30 | - | 10 | can't test |  |

## Catalog check (`docs/proposals/regions-chicagoland-miami/region-catalog.json`)

| cell | first-match box at centre | profile at centre | expected | match | cell area by resolved profile | overlapping boxes (share of cell) |
|---|---|---|---|---|---|---|
| portage-park-park | portage-park-review | chicago-bungalow-belt | chicago-bungalow-belt | yes | chicago-bungalow-belt 1 | portage-park-review 100% |
| jefferson-park-park | (none: defaultProfile) | generic-temperate-v1 | chicago-bungalow-belt | NO | generic-temperate-v1 1 | - |

| box (sampled part only) | profile | sampled km2 | buildings/km2 | house share | block share | house footprint p50 | 3+ levels share (n) |
|---|---|---|---|---|---|---|---|
| portage-park-review | chicago-bungalow-belt | 1 | 2451 | 0.962 | 0.029 | 94.3 | 0.015 (1236) |

## Needs a human eye

- Template-only (no open data): `trees.heightMeters`, `trees.youngShare`, `trees.crownWeights`, `trees.youngHeightMeters`, `typeThresholds.aspect/rectangularity`, `typeRules.(levels situations)`, `houseTypes[].perFloor`, `houseTypes[].roof`, `houseTypes[].pitch`, `houseTypes[].colors[wall]`, `houseTypes[].colors[roof]`, `houseTypes[].porch`, `houseTypes[].windows`, `houseTypes[].door`, `houseTypes[].overhang`, `houseTypes[].parapet`, `houseTypes[].floors`, `houseTypes[].minAspect/maxAspect/minRectangularity/broadFrontage`, `houseTypes[].colors[trim/door]`, `garage.roof`, `garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters`, `shed`, `chimneyLikelihood`, `foundationMeters`.
- Still missing (needs generator work, not data): Role dispatch for apartments: buildings with role `block` (building=apartments, yes >= 250 m2, ...) always use the FIRST flat-roof house type, so sixFlat / courtyardMass / cornerMixedUse / vintageHighRise in the reference profiles are never chosen for them; two/three-level rear porches and gangways, stoops, cornices (no geometry support); Chicago brick bungalow attic/dormer and raised basement (one roof per rectangle, no dormers).
- roof:shape is missing on 100% of houses: roof mix stays a prior; check roofs on test pictures.
- Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).

---
OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 (https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, Palecki et al. (2021), doi:10.25921/wck8-er13.
