# Seasonal + holiday life v1

Open [the gallery](index.html). **50 US city seasonal sheets + 4 regional celebration sheets**, each with street and 45-degree aerial, using five fixed base blocks. [One PDF with all images and notes](seasonal-holiday-life-v1-agent-pack.pdf) makes AI handoff easier. [Values JSON](values.json) is the structured specification; [Neighborhood Jobs](jobs.html) lists triggers.

## Look and continuity

Packs own content; style-b-calibration-v2 owns look. Its complete `sharedLook` is copied without per-city exposure/material overrides. Clear-day fixture uses 40-degree sun / 225-degree azimuth; morning, dusk, night and overcast replace this fixture, not layer a second grade. Proportions remain real, surfaces simplified and matte, light soft. No logos, real brands, readable signage, dogs, animals or host-app content. Generic striped/star flags are deliberately allowed for July 4. People appear only where the activity calls for them, with non-identifying faces and natural proportions.

Every US city state edits that city's same paired base block. Roofs, stoops, tree trunks, curbs and street grade remain the continuity anchors. Generated continuity is a visual constraint, not proof of identical engine mesh/camera matrices. Production must keep the same mapped mesh and stored street/45-degree camera. Base blocks are generic city-type proposals with no real addresses; geography and exact camera angles are unverified.

## Participation: proposal, not demographic data

All percentages are conservative art-direction proposals, **not measured prevalence**. The denominator is a residential building exterior/frontage, not a person or household; flats count once per building. Stable cosmetic seeds select sparse frontages without race, religion, income or inferred beliefs. No claim is made about actual resident practices. Different events use different seeds; installed lights and completed jobs persist instead of reshuffling daily. Generic seasonal lights/wreaths do not imply universal Christmas observance.

City targets below already reflect the representative street type. Street multipliers apply only when transferring to another street type: detached yard 1.0, urban flats 0.9, rowhouse/steep rowhouse 0.65, courtyard apartment 0.4, mixed-use 0.25, commercial/highway 0. **Do not apply both adjustments twice.** Yard props require actual eligible private land; no sidewalk pools, invented front lawns or props in the road. Summer rare subtype rates are separate from decorated-house share: 3 active sprinkler, 2 small pool, 1 lemonade stand per 100 eligible frontages, only when their gates pass. A block party needs a verified permit or deliberately authored event and is off by default without one.

| State | Chicago | Denver | Greenville SC | NYC | SF |
|---|---:|---:|---:|---:|---:|
| Spring planting + blossoms | 20% | 20% | 20% | 15% | 15% |
| Summer yard life + block party | 15% | 15% | 15% | 8% | 6% |
| Back to school | 0% | 0% | 0% | 0% | 0% |
| Autumn leaves + leaf piles | 15% | 15% | 15% | 10% | 8% |
| Halloween + trick-or-treat dusk | 40% | 35% | 35% | 25% | 25% |
| Thanksgiving / harvest | 15% | 15% | 15% | 15% | 15% |
| Winter holiday lights | 45% | 40% | 45% | 30% | 30% |
| New Year | 8% | 8% | 8% | 8% | 8% |
| Snow day / observed-weather fallback | 8% | 8% | 8% | 8% | 0% |
| Fourth of July | 15% | 20% | 20% | 10% | 8% |

0% school/hanami means no house decoration, not no people/flowers. Snow/leaf cover is environmental and not this percentage. Tiny illustrated blocks use rounded sparse counts, so drawings cannot establish statistical rates. Summer sheets are deliberately selected event examples; an unusual pool/stand/party combination is not the everyday frequency of every block.

## Date windows and gates

- Spring planting/blossoms: candidate ranges in JSON vary by city, but actual species phenophase, soil and freeze conditions decide activation. USA-NPN spring indices are early-season regional models; they are **not** a universal tree species calendar or an autumn index.
- Summer activity: warm safe weather, private-space eligibility, school/free-time context and local irrigation policy. **Denver sprinkler hardware is off in the sheet.** As checked 2026-10-07, Denver Water's current policy prohibits lawn/spray irrigation from October 1 until further action; older summer schedules cannot override current drought restrictions. Unknown irrigation policy disables active spray.
- Back to school: selected school first day -7 to +14 days; actual term weekday commute times. Verified 2026-27 starts: Chicago K-12 Aug 24, Greenville Aug 11, NYC Sep 10, SFUSD Aug 17. Denver district-wide exact date is unclear here; selected school calendar is required. Do not reset foliage to autumn at school start.
- Autumn leaves/piles: locally observed/modelled species leaf colour/fall, deposition/wind and substrate. Calendar envelope is only a retrieval hint; evergreen trees do not become bare. Retain selected planting-bed leaves instead of every-yard removal.
- Halloween: proposed generic display Oct 01-Nov 07, strongest Oct 20-31. Trick-or-treat actors Oct 31 or verified local alternative, at actual local dusk. No automatic snow or branded costume characters.
- US Thanksgiving/harvest: proposed Nov 01 through holiday +3 days, with Thanksgiving fourth Thursday November. Modest gourds/planters; no every-house display. Canada's harvest window instead follows second Monday October. Other regions get no US Thanksgiving default.
- Winter holiday lights: proposed Nov 20-Jan 06, varied participating homes only; ramps/tapers in JSON. Snow is a separate input, never a holiday prop default.
- New Year: Dec 31-Jan 03 prop/cleanup envelope; small gathering around local Dec 31 evening/Jan 01, not universal fireworks. Retained winter strings keep their own end date.
- Snow days: any date if current depth/cover and moisture support it. Chicago/Denver/NYC sheets illustrate an authored 8-12 cm qualifying event; Greenville illustrates a conditional event, never a winter default. **SF shows the no-snow wet-day fallback**, with no snowmen/sleds. Neither picture is a current observation. Snowfall totals are not current depth; shade/melt and clearing must persist. Unknown snow inputs do not create snow.
- Fourth of July: proposed display Jun 28-Jul 06, peak actual Jul 04; government work-observed date does not shift the celebration. Small generic stripe/star flags and bunting only, no fireworks or logos.
- Día de Muertos: local Mexico example, proposed Oct 27-Nov 03 / strongest Nov 01-02. Marigolds, plain paper bunting and candle-like LEDs; preserve its flower/offerings context, no Halloween substitution, personal portraits or all-country caricature.
- Australia Christmas in summer: proposed Nov 20-Jan 06, actual Dec 25 in temperate southern summer. No snow/European autumn default; northern wet/dry climates need local treatment.
- Kings Day: actual Apr 27, Apr 26 when Apr 27 is Sunday; proposed display event -2 through +1 days. Sparse plain orange accents; local event permissions, no royal portraits or logos.
- Hanami: local bloom onset through petal fall. Country March-May progression is only a search hint; cherry species and actual local bloom govern blossoms. Picnic mats belong in permitted park space; no house decoration/every-tree pink rule.

## Night, scale and detail

Authored starting values: 70% warm-white / 20% muted mixed-colour / 10% cool-white light sets among selected lit frontages; warm `#FFD6A0`, cool `#CEDFFF`, muted red/green/amber/blue in JSON. String length 4-18 m, bulb spacing 0.2-0.4 m, nominal 1-4 lm per bulb with 160 lm whole-string cap, surface spill target <=2 lux at 1 m. These are renderer-independent proposals, not measured residential lighting. Use photometric or relative-emission controls once, not both as cumulative boosts. Local sun below -3 degrees enables strings; default off at 23:00, optional New Year exception 01:30. No strobe, giant bloom or city-wide orange grade.

Under 6 px: regional canopy/ground state and sparse grouped light cue; cull standalone props/actors. 6-20 px: grouped porch/pile/pool voids and a few light points. Over 20 px: plain real-scale object geometry; no text, brands or detailed identifying faces. Dimensions in JSON are metre-scale design proposals.

## Neighborhood Jobs

Hang lights: chosen display window, selected participating frontage, not already installed, daylight/dry safe access; record installed style and separate removal task. Rake: actual loose leaf deposition/coverage on eligible path/lawn, selective piles and local collection rules. Shovel: current accumulation on an uncleared eligible walk; forecast can queue, not render actual snow/completion. Mow: actively growing living turf reaches 1.5 times the species target and dry safe conditions permit; remove no more than one third at once. Gravel/xeriscape/paved fronts never get mowing jobs. Thresholds such as 2 cm snow and 20% leaf-path cover are gameplay proposals; local legal deadlines remain unclear until verified by jurisdiction. Extra setup, planting, watering and cleanup are explicit separate tasks.

## International notes

### Canada

No single Canadian season: choose local climate/species; coastal rain is not prairie snow. Thanksgiving is second Monday October; Canada Day July 1, not July 4. Halloween Oct 31 and optional varied late-Nov/Dec lights; no inferred beliefs. School starts from province/district calendars.

### UK

Species and wet/dry weather decide foliage and turf tasks. Local councils/schools decide terms; England/Wales, Scotland and Northern Ireland can differ. No US Thanksgiving or July 4 default. Sparse Halloween and optional varied Dec lights; community-confirmed events only.

### Netherlands

Local weather and tree species govern leaf/snow. Kings Day exception handled explicitly. No US Thanksgiving/July 4 default. Generic winter lights cannot be used to infer household religion; local Dec events require local calendars.

### Mexico

Climate varies strongly by elevation/latitude; wet/dry dynamics can replace four-season assumptions. Día de Muertos is a locally specific tradition with flower/offerings context, never a whole-country caricature. No US Thanksgiving/July 4 default.

### Australia

Temperate southern seasons reverse northern timing; northern wet/dry climates need another model. Christmas summer illustration applies to a temperate suburb, not every Australian place. No automatic snowy holiday ground or leaf change by hemisphere alone.

### Japan

Bloom and leaf fall are species/local-weather driven, with strong geographic progression. Hanami is a permitted blossom-viewing activity in suitable parks, not household decoration. School calendars and local holiday customs must be checked; no US holiday overlay.

## Files and verification

`values.json`: windows, percentages, types, density, lighting, environment states and job triggers. `prompts.json`: reference/image-generation instructions. `<city>-base.png`: fixed comparison blocks. `<scene>.png`: paired visual. `<scene>.html`: full specification sheet. `index.html`: local phone-size gallery with city/state filters and street/aerial crop views. `jobs.html`: task handoff. `sources.md`: primary-source facts and limitations. `phone-check.json` and phone PNGs record layout checks. The PDF packages all 54 images with selectable notes and sources for another AI. No existing world-engine project or calibration pack was modified; no git operations.

### Completed checks

All 54 scene images decoded. Gallery, filters and camera modes passed at 390 px and 1440 px with no horizontal overflow or browser errors. All 54 full specification sheets have PNG exports. Seasonal artwork was visually reviewed and density/snow/skyline corrections were applied; exact mesh/camera identity still requires engine verification. PDF: 60 pages, 54 embedded images, selectable notes, approximately 22 MB; representative pages rendered and checked. This is a browser phone-size check, not a device performance test. Winter-light/New Year examples are snow-free; dedicated snow sheets use the explicitly authored 10 cm input, except SF's 0 cm rain fallback.
