> **SUPERSEDED:** Use [SF r2](../sf-r2/index.html). All files here are preserved historical versions; earlier Chicago contamination and mild slopes are rejected.

# San Francisco Bay Area — priority Style B pack

Open [index.html](index.html). Six archetypes: Painted Lady Victorian, Edwardian flats, Marina-style stucco over garage, Sunset row house, Oakland Craftsman, modern mid-rise. Four districts: Pacific Heights / Alamo Square slope families, Mission, SoMa / downtown towers, Embarcadero waterfront. Extras: steep-street geometry, generic cable car, generic electric streetcar, overhead marine layer, surface marine fog, separate bridge silhouettes, and a block paint-over. Every artwork has an HTML/PNG specification sheet with metres, hexes and projected-size tiers.

## Geometry and map fidelity

Positions and sightlines come from the map. Pacific Heights and Alamo Square are separate neighborhoods, not a fabricated shared intersection. SF and Oakland are distinct contexts. Generic bridge silhouettes are isolated sightline witnesses: Golden Gate, western Bay Bridge, eastern Bay Bridge. No simultaneous bridge/street panorama is implied. Embarcadero's optional far Bay Bridge belongs to a plausible mapped southeast sightline; Golden Gate is not inserted there.

Published historic SFMTA witness: Hyde between Bay and Francisco has a21% maximum cable-car route grade, equal to11.8598° and21m rise/100m horizontal run. This is **not** the measured grade of the Alamo Square or Pacific Heights illustrations. Other numerical grade profiles are authored review fixtures; actual DEM/survey samples determine the production road. Longitudinal grade is percent rise/run, not degrees. Floor planes remain horizontal, walls vertical, foundations and thresholds step parcel by parcel. Curbs/sidewalks conform; crest/intersection transitions use terrain profiles rather than abrupt rotated road slabs. Accessibility, drainage and structural engineering are outside this visual specification.

The block paint-over adapts an existing WorldEngine camera; no verified SF street capture was supplied. Source composition is retained, terrain and architecture intentionally changed. Do not treat the concept as a surveyed intersection.

## Weather states

Clear uses the approved Bible lighting object copied unchanged. Overhead stratus review: base120m MSL, top350m MSL, street20m MSL,95% cloud coverage, direct sun .25×clear, exposure +.15EV replacingclear+.35EV; illustrative contrast visibility2000m. Surface fog review: base0m/top200m MSL, direct sun .15×clear, exposure+.15EV, visibility220m with5m near-clear and sigma=ln(20)/(220−5)=.01393363848/m. Heights, opacity and visibility are authored scenarios, not Bay Area climate statistics or current observations. Weather observations/model profiles replace these values. The overhead deck is not a2.5m ground-fog sheet; hill elevations can intersect the marine layer while lower streets remain beneath it.

Use inherited fog-v1 exponential contrast convention; integrate only along a ray inside the layer, in linear light. MSL height and camera height are separate. Maintain the same physical fog layer in street/aerial/far views. No independent aerial visibility override, stacked fade, forced morning fog, fixed-time clearing or automatic bridge placement.

## Transit and materials

Generic cable car: authored8.8×2.4×3.4m, narrow-gauge proposal1.067m, central underground cable slot, no overhead trolley apparatus. Generic streetcar: authored14.3×2.55×3.4m, standard-gauge proposal1.435m, overhead pole/wire, no cable slot. Dimensions are usable asset targets, not a certified fleet survey or replica. Routes and wires come from the map. No official liveries, route numbers, badges, text, riders or brands.

Simplified matte materials and opaque glazing;25mm primary edge bevel,8mm trim. Preserve Victorian bay/gable silhouette, Edwardian floor rhythm, Marina garage/stucco/parapet, Sunset horizontal window/garage row, Oakland usable porch/yard and mid-rise floor count. No fine ornament, individual leaves, brick/stone joints, photo texture or toy proportions. Exact JSON is authoritative; illustrations are not pixel-measured renderer calibration.

## Evidence

- [sfplanning.org](https://sfplanning.org/project/sf-histories-historic-context-statements)
- [sfplanning.org](https://sfplanning.org/es/node/432)
- [sfplanning.s3.amazonaws.com](https://sfplanning.s3.amazonaws.com/commissions/hpcpackets/2013.1334U.pdf)
- [commissions.sfplanning.org](https://commissions.sfplanning.org/cpcpackets/2019-014071DRP.pdf)
- [sfplanning.org](https://sfplanning.org/fil/node/1544)
- [generalplan.sfplanning.org](https://generalplan.sfplanning.org/NE_Waterfront.htm)
- [www.sfmta.com](https://www.sfmta.com/getting-around/muni/historic-streetcars)
- [archives.sfmta.com](https://archives.sfmta.com/cms/rhomemu/genmuinfo.htm)
- [www.weather.gov](https://www.weather.gov/media/sgx/marine/BoatersWeatherBooklet.pdf)
- [www.goldengate.org](https://www.goldengate.org/bridge/history-research/statistics-data/design-construction-stats/)
- [NOAA marine layer explanation](https://www.noaa.gov/jetstream/ocean/marine-layer): physical distinction between inversion/cloud and ground-intersecting fog; no numeric layer targets derived from it.

The SF planning sources support scoped district/form character, not prevalence or exact authored dimensions. Golden Gate published witnesses:1280m main span and227m tower above water from bridge operator. Bay Bridge west main spans are each 2310 ft / 704.088 m, with four suspension towers, from the bridge builder; east pylon is 525 ft / 160.02 m from MTC. Other dimensions and positions remain mapped model inputs. Street tree candidates are illustrative, not a verified inventory ranking.

`sf-values.json` is the full metro and environment specification. `prompts.json` records built-in imagegen generation/edit instructions and source provenance; no CLI image API. Previous Southern versions are superseded in the parent folder.

Additional primary bridge sources: [American Bridge construction record](https://americanbridge.net/san-francisco-oakland-bay-bridge/), [MTC east-span construction account](https://mtc.ca.gov/news/bay-bridge-uses-google-earth-showcase-iconic-east-span-construction-process). Published historic dimensions are silhouette witnesses, not replacement map geometry.
