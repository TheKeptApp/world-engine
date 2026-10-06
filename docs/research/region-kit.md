# Region kit: drafting regional profiles from open data

Research note, 6 October 2026. Tool: [`Tools/regionkit/`](../../Tools/regionkit/README.md). Drafts and per-zone
confidence reports: [`Tools/regionkit/drafts/`](../../Tools/regionkit/drafts/README.md). Nothing here is wired
into the engine; the drafts are review material.

All OSM-derived numbers: © OpenStreetMap contributors (ODbL 1.0). Every number below comes from
`measurements.json` of the named zone (computed by the tool) unless marked *assumption*. All dates and
times are UTC.

## Summary

- The tool works end to end: 15 zone drafts (Denver, Plano, 10 Chicagoland zones incl. 4 North Shore towns
  and a pooled North Shore zone, 3 Miami zones), all schema-valid, each with per-field provenance and a
  confidence report. 71 unit tests pass without network.
- **Open data supplies footprints, streets and (in Chicago) storey counts; almost nothing else.** Across about
  24 sampled km² (22 fetched plus the Denver extract), `roof:shape` is on 0-2.2 % of buildings, `roof:angle` on none,
  colours/materials on almost none, and tree genus/species on at most 1 % of mapped trees in every zone with more
  than 10 trees. So most profile fields stay template values, and the accuracy scores rest on 2-5
  measurable fields per zone.
- **Accuracy (draft vs hand-made reference, agree / measurable):** Denver vs `front-range` 1.0 (2/2, thresholds
  excluded); Plano vs `north-texas-dfw` 0.0 (0/3, only thresholds measurable); Chicago 0.0-0.4; Miami 0.33 and
  0.67; Wilmette, Winnetka and Kenilworth not measurable. Where the data could judge, the **references are
  often the ones contradicted**: e.g. `chicago-bungalow-belt` gives untagged houses 98 % one-storey defaults,
  while the levels-tagged houses of comparable size are 39 % one-storey and 59 % two-storey; the draft gets 52/48.
- **OSM barely maps North Shore houses:** 16-63 buildings per km² in the Wilmette, Winnetka and Kenilworth cells
  (mostly civic/commercial), against 958-2,543 per km² in Chicago's north- and west-side cells. Open data cannot calibrate or test
  the four town profiles.
- **Three generator gaps matter more than any profile value:** (1) one profile per baked area, (2) `block`
  buildings never use the house-type lottery, so apartment/tower families can't be chosen, (3) detached garages
  tagged `building=yes` become houses (30-44 % of generator houses in three Chicago zones are probable garages:
  `building=yes` under 60 m² within 8 m of a service road; definition in §1.3).
- Zones: the existing ordered-box catalog can hold several zones per region; no schema change is needed. Real
  gaps and smallest fixes are in §5.

## 1. Method

### 1.1 Cells

A cell is a 1000 m × 1000 m box around a named public anchor (park, plaza, station, civic building): the
feature's Overpass `out center` position rounded to 4 decimals, ± 500 m (ellipsoidal radii at the centre).
All anchors of a region are resolved in one batched query. Anchors and their OSM IDs are recorded in the
region configs (`Tools/regionkit/regions/*.json`). Denver reads the committed extract
`Data/areas/sloans-lake/osm.json` (1600 m × 1200 m) in place; nothing was fetched for it.

Extra cells (allowed by the brief): Jefferson Memorial Park (second bungalow-belt cell) and Smith Park,
Evanston (inside ChatGPT's `evanston-inland-review` box, which the Lovelace Park cell misses). Total fetched
area 22 km² in 22 cells (+1.92 km² Denver extract).

Two cells reach Lake Michigan although their anchors are inland: the shoreline runs 411-479 m east of the
Broadway Armory Park centre (Edgewater) and 213-488 m east of the Village Green Park centre (Winnetka)
(checked with a member-way query). The lake relation is too large to fetch, so its water is not subtracted:
per-km² densities and gross coverage are slightly understated in those two cells. The cells were kept so the
canonical rule matches the coverage audit.

### 1.2 Fetching

One Overpass query per cell, in the shape of `Sources/worldbake/Fetcher.swift` (per-statement boxes,
`(._;>;); out body qt;`): building outlines and parts, highways (box enlarged by 100 m so edge houses find
their street), barriers, `natural=tree`, land use/leisure/natural/amenity areas, shop/office/amenity/craft
nodes. Area multipolygons with ≥ 300 members are listed with `out tags` instead of fetched (Lake Michigan).
Etiquette as briefed (one request at a time, status check, ≥ 5 s spacing, 60 s back-off on 429/504, cache keyed
by query hash, never `out meta`). overpass-api.de returned repeated 504s (and once a 429); three cells came from the fallback mirror
overpass.private.coffee, whose data was older: Plano Buckhorn Park and Clearview Park (OSM base
2026-05-06T03:25:00Z) and Wicker Park (2026-06-01T08:52:28Z). All other fetched cells have OSM bases of
2026-10-06 (03:49-04:27). Each cell's endpoint and OSM timestamp are in its measurements.

### 1.3 Measures (exact definitions in `measurements.json` → `definitions`)

Buildings are outlines whose centroid lies in the cell (the engine's rule), cleaned like `Polygon2D.cleaned`.
`building:part`-only features are counted but excluded from statistics. Roles, situations, eligibility,
roof mapping, footprint analysis and street frontage are line-by-line ports of `BuildingGenerator.swift`,
`FootprintAnalysis.swift`, `StreetContext.swift` and `TagParsing.swift` (parity tests in `tests/`).

Added diagnostic: a **probable garage** is a generator "house" with `building=yes`, under 60 m² and within 8 m
of a service/unnamed road; shares are given as a share of generator houses (the coverage audit's 27.8 % uses a different definition: `building=yes` under 60 m² without levels, as a share of all buildings in its 7 Chicago neighbourhood cells, with no road test). **Principal houses** = generator houses minus probable garages. Footprint
percentiles, setbacks, family signatures, threshold transfer, the floor calibration and all comparisons use
principal houses; raw role counts still follow the generator exactly.

Setback = footprint boundary to the nearest residential…primary centreline (≤ 60 m) minus half the
carriageway (`width`, else lanes × 3.3 m, else the engine's `RoadRules` default: 6 m residential). The brief
said ~3.2 m per lane; the engine's 3.3 m was used so measurements match what the generator renders.

### 1.4 Climate

NOAA NCEI U.S. Climate Normals 1991-2020, monthly (inventory and per-station CSV URLs in the tool README;
units °F / inches per the NCEI documentation). Nearest station with complete temperature and precipitation
normals among the 12 nearest stations; snowfall from the nearest station that has it, searching up to 40
stations within 50 km (dense north and greystone take snowfall from stations 21-23 km away). Köppen-Geiger is computed per Peel et al. (2007), the criteria also used by Beck et al.
(2018): 0 °C C/D threshold; the original −3 °C variant is reported too; for C/D the `s` test runs before `w`.

### 1.5 Drafting

Draft = template + calibration, shrunk toward the template: `(n·measured + k·template)/(n + k)`, k = 30.
Below a field's gate the template is kept. Status per field: `calibrated`, `template` or `default`.

| Field | Rule | Gate |
|---|---|---|
| `trees.deciduousShare` | broadleaved share (`leaf_type`, else genus via `data/genus_leaf.json`); means non-conifer share in the generator | 30 trees (gate added, see Decisions) |
| `trees.heightMeters`, `youngShare` | p25-p75 of tagged heights; share < 7 m | 30 |
| `houseTypes[].perFloor` | p25-p75 of (height − roof:height)/levels (flat roofs: height/levels), clamped 2.6-3.8 m | 20 houses |
| `houseTypes[].roof` | IPF over families × shapes so the usage-weighted mix matches the measured house mix; zero weights stay zero; residual reported | 30 houses |
| `houseTypes[].pitch` | p25-p75 of `roof:angle`, pitched families only | 20 |
| `houseTypes[].colors` (wall, roof slot) | shift toward measured colour/material families (`data/materials.json`), then clamp L* and C* into the template's own band | 30 |
| `typeRules.unknown/small/large` | families grouped by default (first) floor count; weights scaled per group until the expected default floors **after the generator's eligibility filter** match the measured shares of levels-tagged principal houses, post-stratified by footprint-area bin to the untagged houses (tagging depends on size) | 30 houses with levels |
| `typeThresholds.small/large/hugeArea` | percentile transfer: the ECDF of front-range's 60/220/350 m² in Sloan's Lake houses (0.021 / 0.865 / 0.990), applied to the zone's principal houses | 30 |
| `garage.roof` | measured garage `roof:shape` | 20 |
| seasons | hemisphere from latitude, meteorological months; flagged for Köppen A (no real winter) and B | rule |
| everything else | template, listed under "needs a human eye" | - |

The validator mirrors the Swift decoder (required keys and JSON types, integral `floors`/months, a
`typeRules` value that would be silently dropped is an error) and adds semantic checks (type IDs exist,
4 × `#RRGGBB` tuples, non-negative weights, `[lo, hi]` ranges). It passes on `default`, `front-range`, all six
regions-v1 profiles, all eleven `regions-chicagoland-miami` profiles and every draft.

### 1.6 Accuracy check

Templates are never the scored reference (Denver and Plano use `default`; North Shore uses regions-v1
`northeast-suburbs`; Chicago city zones `front-range`; downtown `default`; Miami `desert-southwest`).
Each comparable field is judged only if the draft value was calibrated; template-only fields are "not
measurable". Expected values (roof mix, default floors, usage-weighted perFloor/pitch/colours) are evaluated
for both profiles on the zone's own principal houses with the generator's rules. Default floors are tested on
levels-tagged houses with the tag hidden, per footprint bin, weighted like the untagged houses, so the
"truth" is real data. Tolerances: roof mix TVD 0.10, floors TVD 0.15, perFloor 0.15 m, pitch 4°, thresholds 15 %,
shares 0.05, tree height 2 m, garage roof TVD 0.15, colours ΔE00 10. A separate "direct test" checks each
reference value against raw measurements (no shrinkage): supports / contradicts / can't test.

Both original references are hand-made priors (`front-range` from the v2 spec; `north-texas-dfw` explicitly
"assumption" values), as are all eleven Chicagoland/Miami profiles ("no regional measurements are claimed"
in their spec, §1). A difference can therefore mean the reference is wrong.

## 2. How to run

`Tools/regionkit/regionkit.sh all` (drafts everything, writes the index), `… draft regions/<region>.json
[--zone Z]`, `… compare`, `… test`. Details: [tool README](../../Tools/regionkit/README.md).

## 3. Accuracy results

### 3.1 Denver (Sloan's Lake) vs `front-range`: score 1.0 (2 of 2)

1,399 buildings, 779 generator houses; 124 of the houses (16 %) carry `building:levels` (130 of all 1,399
buildings, 9 %); no `roof:shape`, no heights, 5,400 trees with no species or leaf tags. Köppen BSk (Denver Water Dept, USC00052223, 3.8 km: MAT 11.85 °C,
MAP 402.6 mm, below 10 × P-threshold 517 mm).

| Field | Draft | front-range | Verdict |
|---|---|---|---|
| default floors 1/2/3+ (size-stratified) | 0.82/0.18/0 | 0.75/0.25/0 | agree (TVD 0.072); truth 0.68/0.10/0.22, both TVD 0.218 from it |
| roof colour (usage-weighted) | #6A696B | #5F6165 | agree (ΔE00 3.7, n = 31) |
| thresholds | 60.1 / 220 / 348.8 | 60 / 220 / 350 | excluded (calibrated on Denver) |
| roof mix, perFloor, pitch, trees, garage roof, wall colour | - | - | not measurable (no tags) |

Direct tests: front-range's default floors are contradicted (no family defaults to 3 floors, yet 44 of the 124
tagged houses have 3 levels, plausibly townhouse infill); its roof colour is contradicted by 31 tagged roofs
whose mean is #8C5C47 (12 roofs share one saturated tag `#9f390c`). The draft's roof colour agrees with
front-range mainly because the colour shift is clamped to the template's muted band.

### 3.2 Plano vs `north-texas-dfw`: score 0.0 (0 of 3)

Three cells: Parkwood Green Park (west), Buckhorn Park (central), Clearview Park (east), all small (2-4 ha)
neighbourhood parks, two of them tagged as operated by Plano Parks and Recreation. 1,690 buildings, 1,641 houses (97 %), 1 house with levels, no roof shapes,
heights, colours or garages as separate buildings, 35 trees without species. Köppen Cfa (Richardson
USC00417588, 5.6 km). Only thresholds are measurable:

| Field | Draft | north-texas-dfw | Verdict |
|---|---|---|---|
| smallArea | 175.7 | 60 | differ |
| largeArea | 431.8 | 260 | differ |
| hugeArea | 539.7 | 420 | differ |

What the data says: Plano principal-house footprints are p25/p50/p75 239/331/401 m² (attached garages are
inside the outline), aspect 1.07-1.28. With the reference's 260 m², 66 % of Plano houses fall in the `large`
situation, so the reference's `unknown` weights apply to about a third of houses; with the template's 220 m²,
86 % are `large`. The disagreement is about **threshold semantics** (absolute sizes vs. "relatively small/large
for this area"), not noise; see Decisions. Data that supports the reference's qualitative claims: 7.9 km of
mapped alleys per km² and 94 % of houses within 30 m of an alley (rear-alley pattern); no detached garage
buildings.

### 3.3 Chicagoland and Miami vs ChatGPT's `regions-chicagoland-miami` profiles

| Zone (cells) | Reference | Score | Measurable fields (verdict) |
|---|---|---|---|
| dense-north (3) | chicago-dense-north | 0.0 (0/4) | floors differ; small/large/huge differ |
| greystone (3) | chicago-greystone-twoflat | 0.4 (2/5) | roof mix differ; floors differ; small agree, large differ, huge agree |
| bungalow-belt (2) | chicago-bungalow-belt | 0.4 (2/5) | floors differ; small agree, large/huge differ; deciduousShare agree |
| south-side (2) | chicago-south-historic | 0.25 (1/4) | floors differ; large agree, small/huge differ |
| downtown (2) | chicago-downtown | 0.4 (2/5) | floors differ; large agree, small/huge differ; deciduousShare agree |
| evanston (2) | evanston | 0.0 (0/3) | thresholds only (86 principal houses), all differ |
| wilmette, winnetka, kenilworth (1 each) | town profiles | not measurable | 24, 13 and 1 houses mapped |
| coral-gables (1) | coral-gables | 0.33 (1/3) | large agree; small/huge differ |
| miami-shores (1) | miami-shores | 0.67 (2/3) | small, large agree; huge differ |

Per-value tables (draft, reference, metric, n, verdict) are in each zone's `report.md`.

**Default floors are the most informative field** (n = 458-2,774 tagged principal houses in the four residential
city zones, 35 downtown).
TVD to the size-stratified truth, draft vs reference:

| Zone | Truth 1/2/3+ | Draft (TVD) | Reference (TVD) | Closer |
|---|---|---|---|---|
| dense-north | 0.08/0.68/0.25 | 0.29/0.71/0 (0.245) | 0.44/0.39/0.17 (0.367) | draft |
| greystone | 0.12/0.72/0.17 | 0.23/0.77/0 (0.167) | 0.37/0.62/0.01 (0.257) | draft |
| bungalow-belt | 0.39/0.59/0.02 | 0.52/0.48/0 (0.131) | 0.98/0.02/0 (0.593) | draft |
| south-side | 0.03/0.49/0.48 | 0.36/0.64/0 (0.477) | 0.15/0.69/0.16 (0.313) | reference |
| downtown | 0.19/0.53/0.28 | 0.86/0.14/0 (0.664) | 0/0/1.00 (0.720) | draft (both far off) |

The draft can never produce 3+ defaults with `front-range` or `default` families (none has 3 as its first
`floors` entry); that alone explains the south-side loss. Chicago's data holds almost only integer storeys
(among houses, one fractional `building:levels` value in greystone, none in dense north, bungalow belt or South Side), so
1.5-storey bungalows appear as 1 or 2.

**Thresholds:** in dense-north the Denver-percentile transfer gives 43/182/250 m² vs the reference's
60/220/350: 60 m² sits at the 7.5th percentile of dense-north principal houses but at the 2.1st in Denver. `hugeArea` has no effect in the current
generator (`situation()` has no huge branch), so its "differ" verdicts (e.g. downtown 1,294 m² after shrinkage; the raw 99th-percentile value of only
223 houses is 1,420.5 m²) carry no rendering consequence.

**Roof mix (greystone only):** 77 houses (1.6 %) carry `roof:shape`; 70 of them map to gabled/hipped/flat
(the other 7 are shapes the generator ignores or skillion): 74 % gabled, 6 % hipped, 20 % flat; the reference
expects 0.35/0.06/0.59 on the same houses. Contradicted, but the tagged 1.6 % are probably biased toward
distinctive pitched cottages. The draft's IPF could only reach gabled 0.35 (target 0.62 after shrinkage):
front-range's flat-only `modern`/`duplex` take most of the usage on narrow two-storey footprints.

### 3.4 Which reference values the data supports, contradicts or can't test

- **Supported** (reference value vs the zone's footprint quantile at Denver's percentile): smallArea 60 in
  greystone (62.2), bungalow belt (61.7) and Miami Shores (60.6); largeArea 220 in Miami Shores (235.8),
  south-side (223.4), downtown (220.8) and Coral Gables (236.9); hugeArea 350 in greystone (398.2); Denver's
  own thresholds (identity); downtown `deciduousShare` 0.96 vs 175 trees, all broadleaved.
- **Contradicted:** default floors in every city zone and in Denver (above); bungalow-belt 0.94
  `deciduousShare` vs 53 trees all broadleaved (|d| 0.06, tolerance 0.05, a marginal call); greystone roof mix;
  Denver's (front-range) roof colour (#5F6165 vs measured mean #8C5C47, n = 31). Thresholds: dense north
  small/large/huge (43.1 / 181.9 / 248.8 vs 60 / 220 / 350); greystone large (168.9 vs 220); bungalow belt
  large/huge (167.1 / 228.0); south-side small/huge (49.0 / 886.2); downtown small/huge (15.9 / 1,420.5);
  Evanston small/large/huge (44.8 / 213.4 / 1,314.2 vs 60 / 260 / 420); Coral Gables small/huge (29.8 / 941.2);
  Miami Shores huge (249.3); Plano small/large/huge (177.8 / 435.7 / 543.1 vs 60 / 260 / 420).
- **Can't test anywhere:** pitch (0 `roof:angle`), perFloor (at most 2 houses with height and levels in any zone),
  wall colour, and roof colour outside Denver (Denver's roof colour was tested, n = 31; ≤ 8 tagged houses per
  Chicago zone), tree heights, garage roofs, porches/windows/chimneys,
  crown weights; and every value of the Wilmette, Winnetka and Kenilworth profiles.

### 3.5 Catalog box check (`region-catalog.json`, first match at the cell centre)

- Centre in the expected box: Oz Park, Broadway Armory Park, Logan Square, Wicker Park, Giddings Plaza,
  Portage Park, Nichols Park, Daley Plaza, Montgomery Ward Park, Smith Park (Evanston), Vattman Park,
  Kenilworth station, Venetian Pool, Miami Shores Village Hall.
- Centre outside its zone's box (resolves to `generic-temperate-v1`): Gill Park (only 26 % of the cell is in
  `lakeview-review`, whose north edge is 41.95), Ellis Park (32 % in `bronzeville-review`, whose east edge −87.612
  is about 100 m west of the park's centre), Winnetka Village Green Park (41 % in `winnetka-inland-review`; centre about 90 m east of it), and the extra
  Jefferson Memorial Park cell (centre 41.9686, north of `portage-park-review`'s north edge 41.963; no box
  overlaps the cell, so 100 % of it resolves to `generic-temperate-v1`).
- **A box crossing a town line:** `wilmette-inland-review` covers 72 % of the Lovelace Park cell. Lovelace Park
  itself is tagged `operator=Evanston Parks & Recreation`, `addr:city=Evanston`, so the Wilmette box extends
  south into Evanston. `wilmette-inland-review` and `kenilworth-inland-review` overlap; 14 % of the Kenilworth
  cell resolves to `wilmette` because Wilmette is listed first.
- Box signatures (sampled parts only) match their zones' character where data exists (e.g. `lincoln-park-review`
  2,232 buildings/km², 52 % of tagged buildings ≥ 3 storeys; `portage-park-review` 2,451/km², 1.5 %), except
  `bronzeville-review`'s sampled 0.32 km², which has 198 buildings/km², far below every other city box.

## 4. Per-zone drafts (headline statistics and confidence)

Confidence: **low** = template except thresholds; **medium** = floors and thresholds calibrated on large n.

| Zone | Cells / km² | Buildings | Levels tagged | roof:shape | Trees/km² | Köppen | Calibrated | Confidence |
|---|---|---|---|---|---|---|---|---|
| denver/sloans-lake | 1 / 1.92 | 1,399 | 9 % | 0 % | 2,813 (no species) | BSk | thresholds, floors, roof colour | low-medium |
| north-texas/plano | 3 / 3 | 1,690 | 0.4 % | 0 % | 12 | Cfa | thresholds | low |
| chicagoland/dense-north | 3 / 3 | 4,595 | 54 % | 0.1 % | 136 | Dfa | thresholds, floors | medium |
| chicagoland/greystone | 3 / 3 | 7,022 | 53 % | 2.2 % | 43 | Dfa | thresholds, floors, roof mix | medium |
| chicagoland/bungalow-belt | 2 / 2 | 4,127 | 50 % | 0 % | 27 | Dfa | thresholds, floors, trees | medium |
| chicagoland/south-side | 2 / 2 | 1,461 | 43 % | 0 % | 5 | Dfa | thresholds, floors | medium |
| chicagoland/downtown | 2 / 2 | 833 (171 parts) | 45 % | 1 % | 241 | Dfa | thresholds, floors, trees | low |
| chicagoland/evanston | 2 / 2 | 186 | 2 % | 0 % | 4 | Dfa | thresholds (n = 86) | low |
| chicagoland/wilmette | 1 / 1 | 63 | 5 % | 0 % | 0 | Dfa | nothing | template |
| chicagoland/winnetka | 1 / 1 | 49 | 6 % | 0 % | 2 | Dfa | nothing | template |
| chicagoland/kenilworth | 1 / 1 | 16 | 0 % | 0 % | 0 | Dfa | nothing | template |
| chicagoland/north-shore (pooled) | 5 / 5 | 314 | 3 % | 0 % | 2 | Dfa | thresholds | low |
| miami/coral-gables | 1 / 1 | 621 | 0 % (97 % height) | 0 % | 1 | Am | thresholds | low |
| miami/miami-shores | 1 / 1 | 674 | 0 % (95 % height) | 0 % | 0 | Am | thresholds | low |
| miami/residential (pooled) | 2 / 2 | 1,295 | 0 % | 0 % | 0.5 | Am | thresholds | low |

Family signature hints (principal houses; full text in each report). Shares "within 30 m of an alley" below
are for principal houses (the reports' Measurements lists give the all-generator-house value, slightly higher):

- **Dense north:** 58 % two-storey, 37 % three-storey (of 1,756 tagged); footprints 98-158 m² (p25-p75), aspect
  1.87-2.98, rectangle short side 6.6-8.3 m: narrow deep two/three-flats; narrow end faces the street on 83 %;
  facade-to-curb median 10.8 m; 8.2 km alleys/km², 94 % of principal houses within 30 m of an alley; 31.5 % of
  generator houses are probable garages (definition in §1.3; not the coverage audit's 27.8 %, which counts
  small untagged `building=yes` among all buildings); gross coverage 0.36.
- **Greystone / two-flat:** 73 % two-storey, 16 % three, 11 % one (of 2,774); 104-145 m², aspect 2.09-2.8, short
  side 6.7-8.1 m; narrow end to the street 86 %; alleys 12.1 km/km², 97 % of principal houses within 30 m; probable garages 30 %.
- **Bungalow belt:** 54 % one-storey, 45 % two (of 1,894); 116-155 m², aspect 2.0-2.49, short side 7.5-8.4 m
  (consistent with 25-ft = 7.6 m lots); narrow end to the street 84 %; alleys 8.8 km/km², 98 % of principal houses within 30 m; probable garages
  44 %; 3+ storeys under 2 %.
- **South Side:** 54 % two-storey, 40 % three (of 458); 78-154 m², wider spread (p90 252 m²); alleys only
  3.9 km/km², 46 % of principal houses within 30 m (52 % of all generator houses).
- **Downtown:** 554 blocks of 833 buildings, 171 `building:part`s, heights on 10 % (83 blocks, median 125 m);
  48 % commercial, 34 % residential by count.
- **Plano:** footprints 239-401 m², nearly square (aspect 1.07-1.28), long side faces the street on 35 %;
  facade-to-curb 12.7 m (IQR 11.0-14.0).
- **Coral Gables:** 99 % `building=yes`, 62 % become `block` (≥ 250 m²), house heights p50 4.5 m, block heights
  p50 5.1 m (one-to-two storeys): the large villas render as flat-roof blocks today.
- **Miami Shores:** footprints 163-221 m², aspect 1.10-1.48, house height p50 4.4 m (one storey), 9.2 km
  alleys/km² and 87 % of principal houses within 30 m of an alley.
- **North Shore:** too few houses mapped for signatures (24 in Wilmette, 13 in Winnetka, 1 in Kenilworth).

## 5. Zones

**Answer:** yes. One region can hold several zones with different house families and densities using the
existing format: ordered `RegionCatalog` boxes, each pointing at its own profile, several boxes may share a
profile (ChatGPT's catalog already does this with 18 boxes). Confirmed in code: `RegionCatalog.profileID(at:)`
returns the first containing box, else `defaultProfile` (`StyleProfile.swift` lines 159-162); profiles have no
density fields and no inheritance. No schema change is proposed.

Do the zones separate on measured signatures? Leave-one-out nearest-centroid on buildings/km², house share,
block share, principal-house footprint, gross coverage, alley density and share of ≥ 3-storey buildings:
9 of 12 Chicago city cells are assigned to their own zone (0.75). Misses: Oz Park (dense north, nearest
greystone), Nichols Park (south side → dense north), Montgomery Ward Park (downtown → south side). Dense north
and greystone separate cleanly on alley density (6.4-9.5 vs 11.3-13.1 km/km² per cell); their shares of
3+-storey tagged buildings overlap (0.356-0.661 vs 0.162-0.387). North Shore
cells separate only by being unmapped. The city zones are real but overlapping gradients.

Real gaps (gap, evidence, smallest fix):

1. **One profile per baked area.** `WorldBuild.generate` picks one profile at `manifest.center`
   (`WorldBuild.swift` line 41 on main after the phase 5A merge; line 39 before). Evidence: the Gill Park cell resolves to the generic default at its centre
   while 26 % of it lies in `lakeview-review`; Edgewater splits 63/37 between two profiles, River North 61/39,
   Kenilworth three ways (53/33/14). Smallest fix: resolve the profile per building (footprint centroid)
   through the existing `RegionCatalog.profileID(at:)`, caching decoded profiles. No schema change.
2. **`block` buildings bypass the house-type lottery.** Blocks take the first flat-roof type
   (`BuildingGenerator.swift` lines 143-144). Evidence: blocks are 998 of 4,595 buildings in dense north,
   554 of 833 downtown and 386 of 621 in Coral Gables (`building=yes` ≥ 250 m², heights p50 5.1 m: mostly large
   houses). ChatGPT's `sixFlat`, `courtyardMass`, `cornerMixedUse`, `vintageHighRise` and tower families can
   never be selected. Smallest fix: run blocks through the same weighted, eligibility-filtered pick with a new
   situation key (for example `block`); `typeRules` is already a free map, so existing JSON still decodes.
3. **Detached garages tagged `building=yes` become houses** (`role(of:)`: `yes` < 250 m² → house). Evidence:
   probable garages are 31.5 % (dense north), 30 % (greystone) and 44 % (bungalow belt) of generator houses
   (the coverage audit's 27.8 % uses a different definition: `building=yes` under 60 m² without levels, as a share of all buildings in its 7 Chicago neighbourhood cells, with no road test);
   86-98 % of the small `building=yes` houses sit within 8 m of a service road. They get doors, windows and
   porches. Smallest fix: in `role(of:)`, treat `building=yes` under about 60 m² with an edge on an
   alley/service road as a garage (`StreetContext.alleyEdge` already finds that edge).
4. **Rectangles and first-match order.** Evidence: §3.5 (a Wilmette box reaching into Evanston, overlapping
   boxes, a box west of its anchor). Smallest fix: data-only, smaller/more boxes in priority order.
   Polygons would be a schema change and are not proposed.
5. **Not gaps today:** density and dressing values (alleys from 0.3 km/km² in Winnetka to 12.1 in greystone,
   setbacks, fences, trees per km²)
   have no consumer in the engine, so they stay in `measurements.json` (`notExpressibleInSchema`) rather than
   in profiles. Leaf cycle / palms (Miami) are already covered by regions-v1 `proposedAdditions`; there is no
   tree species data in the Miami cells (1 tree mapped) to size them.

**Update after P2 buildings (main `91ed01c`, merged 2026-10-06, after this analysis of `772ff24`).** P2 added an alley-garage rule to the generator (`BuildingGenerator.role(for:)`: `building=yes` of 14–75 m², at most 1.5 levels, a mapped alley edge within 9 m and no street front within 9 m becomes a garage), keeps large `building=yes` below the profile's `hugeArea` with ≤ 3 levels as houses, picks block families from tag evidence (`HouseFamilies.blockFamily`: tall, court, commercial, apartments, else the plain block), and adds roof assemblies (cross-gables, dormers, chimneys) and rear porches toward mapped alleys (`docs/buildings/README.md`). It also adopted `chicago-dense-north`, `evanston` and `wilmette` unchanged. So gaps 2 and 3 above are addressed on main; gap 1 (one profile per baked area) and gap 4 remain. The region kit's role port and situation counts follow the pre-P2 `role(of:)`; its probable-garage diagnostic (≤ 60 m², ≤ 8 m from a service road) approximates P2's rule but is not identical. The accuracy comparisons against those three profiles now apply to engine profiles.

## 6. What Chicagoland needs that open data can't supply

| Need | What OSM has (measured) | How the generator should handle it |
|---|---|---|
| North Shore house outlines | 16-63 buildings/km² in Wilmette, Winnetka, Kenilworth cells | A second footprint source after licence review (*assumption:* county GIS or Overture building footprints). Until then, test areas must stay in mapped blocks |
| Roof shapes, complex suburban roofs (cross-gables, dormers, Tudor) | 0-2.2 % `roof:shape`, 0 `roof:angle` | Keep roof as a family property (profile priors) and add roof assemblies in code; data won't calibrate it |
| Storeys | 43-54 % `building:levels` per Chicago city zone (34-60 % per cell), 0-6 % in the North Shore, Plano and Miami zones (Denver 9 %); almost only integers | Use levels where tagged; calibrated defaults elsewhere; half-storeys need a family flag (attic) rather than data |
| Heights / downtown tower detail | heights on 10 % of downtown buildings, 171 parts in 2 km² | Tag-driven only; podium/setback massing from `building:part` where present, plain blocks otherwise |
| Alleys and rear garages | Alleys well mapped (8.2-12.1 km/km² per north/west-side zone; 6.4-13.1 per cell); garages mostly `building=yes` | Classify garages (gap 3) and face their doors to the alley (already in `StreetContext`) |
| Rear porches, gangways, stoops | not mapped | Facade kits chosen by family and alley proximity, no data needed |
| Colours, materials (brick vs greystone) | ≤ 8 tagged houses per city zone | Palette tuples per family; review on test pictures |
| Tree species, leaf habit, heights | 409 trees in dense north (24 with leaf type), 128 in greystone (none), 53 in the bungalow belt (all with leaf type), 10 or fewer in the South Side and North Shore zones; genus/species on at most 1 % of trees in zones with more than 10 trees (the South Side has 1 of 10); no tree heights | Profile priors; a municipal tree inventory under a compatible licence would be needed to measure |
| The L, bridges, viaducts | not measured here (railways were not fetched) | A separate structure generator driven by railway geometry, `layer` and `bridge` tags |

## 7. Weak spots of the tool

- **Sparse tags:** most fields remain template values; scores rest on 2-5 fields and must not be read as
  overall profile quality.
- **Tagging bias:** levels and roof shapes are tagged on non-random buildings. Size bias is corrected by
  footprint bins; other biases (mapper interest, import scope) are not.
- **Probable-garage heuristic** (≤ 60 m², ≤ 8 m from a service road) is unvalidated; it misses garages without a
  mapped alley and may catch small cottages.
- **Template structure limits:** the draft keeps the template's families, `floors` orders and zero roof weights,
  so measured three-storey stock or gabled two-flats can be unreachable; residuals are reported, not hidden.
- **Threshold transfer** depends on Denver's distribution and on house definitions; `hugeArea` is unused by the
  generator.
- **Colour clamp:** shifts stay inside the template's lightness/chroma band (muted look by design), so a strongly
  coloured local stock can't be expressed.
- **Lake water not subtracted** in two cells; one-cell zones carry sampling noise; three cells come from an older
  mirror (two Plano cells about five months older, Wicker Park about four); climate stations are up to 20 km away (snowfall stations up to 23 km).
- **Use mix** depends on building tags and landuse; 96-98 % of Miami buildings are "unknown" (`building=yes`, no
  residential landuse).

## 8. Decisions for the owner

1. **Threshold meaning:** absolute m² (ChatGPT's profiles) or relative to the local stock (the brief's percentile
   transfer)? Plano shows the two disagree by a factor of up to three.
2. **Garages:** approve the `role(of:)` garage rule (gap 3)? The drafts already exclude probable garages from
   calibration and comparison.
3. **Generator work before more profile tuning:** per-feature profile selection (gap 1) and block dispatch (gap 2).
4. **North Shore data source:** OSM can't support the four town profiles; choose whether to add another
   footprint source (licence review needed) or test only in mapped areas.
5. Choices I made conservatively (reversible): `deciduousShare` gated at n ≥ 30 (the brief gave no gate);
   `building:part` excluded from statistics; lane width 3.3 m (engine) instead of ~3.2 m; Köppen `s` before `w`;
   canonical cells kept despite lake slivers; the three mirror-fetched cells (two Plano, Wicker Park) kept; per-town North Shore zones plus a
   pooled zone (per the scope update); extra cells at Jefferson Memorial Park and Smith Park.

## 9. Data sources

- OpenStreetMap via Overpass API (overpass-api.de; fallback overpass.private.coffee), queried 2026-10-06; OSM
  base timestamps 2026-10-06 except Plano Buckhorn Park and Clearview Park (2026-05-06T03:25:00Z) and Wicker Park
  (2026-06-01T08:52:28Z), all three from the fallback mirror. © OpenStreetMap contributors, ODbL 1.0.
  Denver: committed extract, OSM base 2026-10-05T17:39:35Z.
- NOAA NCEI U.S. Climate Normals 1991-2020, monthly, accessed 2026-10-06:
  https://www.ncei.noaa.gov/data/normals-monthly/1991-2020/ (inventory `doc/inventory_30yr.txt`, per-station
  `access/<ID>.csv`). Cite as Palecki et al. (2021), doi:10.25921/wck8-er13 (NCEI metadata
  gov.noaa.ncdc:C01620, which states use/distribution liability disclaimers and no licence restriction).
  Stations used: USC00052223 Denver Water Dept; USC00417588 Richardson and USC00413370 Frisco (snow);
  USW00094846 Chicago O'Hare; USW00014819 Chicago Midway and USC00111577 Midway 3SW (snow);
  USC00111497 Chicago Botanic Garden; USW00012859 Miami WSO City; USW00092811 Miami Beach; USC00083909 Hialeah.
- Köppen-Geiger criteria: Peel, Finlayson & McMahon (2007), Hydrol. Earth Syst. Sci. 11, 1633-1644; Beck et al.
  (2018), Scientific Data 5, 180214.
- Reference profiles (read-only): `Sources/WorldGen/Profiles/front-range.json`, `docs/proposals/regions-v1/`,
  `docs/proposals/regions-chicagoland-miami/` (profiles, region-catalog.json, spec v1).
- Lookup tables in `Tools/regionkit/data/` are hand-written assumptions.
