# Sources · checked 7 October 2026

Claims below are verified at the documentation level, not proof of an operational adapter, local station coverage or current conditions. Direct-access limitations are recorded, with no bypass.

## NOAA: why the ocean is blue
[colour-noaa](https://oceanservice.noaa.gov/facts/oceanblue.html)

Verified: water absorbs red wavelengths; suspended particles influence appearance.

## USGS Water Color
[colour-usgs](https://www.usgs.gov/water-science-school/science/water-color)

Verified: dissolved organic material and suspended sediment/algae influence colour.

## NDBC measurement descriptions
[ndbc](https://www.ndbc.noaa.gov/faq/measdes.shtml)

Verified: search-index documentation verifies WSPD m/s, WVHT significant height, DPD seconds and directions from true north.

Access limitation: direct fetch returned 403; no bypass; indexed documentation read, adapter and live endpoint not tested.

## NDBC real-time access
[ndbc-access](https://www.ndbc.noaa.gov/faq/rt_data_access.shtml)

Verified: indexed access documentation located.

Access limitation: direct fetch 403; exact current delivery route and cadence must be verified before implementation.

## NWS wind-wave growth analysis
[wave-growth](https://www.weather.gov/media/wrh/online_publications/TAs/ta0306.pdf)

Verified: wind speed, fetch and duration affect wave growth; distant swell contributes independently.

## GLERL Great Lakes ice cover
[glerl](https://www.glerl.noaa.gov/data/ice/)

Verified: daily GLSEA temperature/ice products; history since 1973; ice charts available in grid/shapefile/image forms; missing cloud-free temperature retrieval uses prior-map smoothing.

## CO-OPS Data Retrieval API
[tides](https://api.tidesandcurrents.noaa.gov/api/prod/)

Verified: observed water levels and tide/current predictions; required units/datum/time-zone parameters and request-span limits.

## CO-OPS free API access
[tides-free](https://tidesandcurrents.noaa.gov/cms/wp-content/uploads/2025/07/The-Current-July-31-2025.pdf)

Verified: official publication identifies free access to data APIs.

## NOAA Great Lakes tides
[lakes-level](https://oceanservice.noaa.gov/facts/gltides.html)

Verified: Great Lakes tides are small relative to weather-driven level fluctuations; seiches matter.

## NWS API documentation
[nws](https://www.weather.gov/documentation/services-web-api)

Verified: open data free to use; forecasts/station observations; cache and rate-limit design required.

## Rijkswaterstaat open data
[rws](https://www.rijkswaterstaat.nl/zakelijk/open-data)

Verified: open reuse described; per-dataset terms must still be checked.

## Rijkswaterstaat data discovery
[rws-water](https://rijkswaterstaatdata.nl/data-zoeken/)

Verified: Waterinfo/WaterWebservices provide water height, wind, waves, temperature, tides and currents; not every urban canal monitored.

## GPU Gems: Effective Water Simulation
[gpu](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models)

Verified: geometric wave sums plus finer normal detail used in Uru; not a current phone benchmark.

## Apple WWDC21 advanced RealityKit rendering
[apple](https://developer.apple.com/videos/play/wwdc2021/10075/)

Verified: geometry modifier and surface shader hooks; exact current engine integration untested.

## three.js ShaderMaterial
[three](https://threejs.org/docs/pages/ShaderMaterial.html)

Verified: custom shader/uniform path for WebGLRenderer; WebGPU needs an equivalent node/material adapter.

## NOAA education reuse FAQ
[rights](https://www.noaa.gov/office-education/outreach-communication/faq)

Verified: NOAA data broadly public domain; third-party supplied products need provenance/terms review.

All regional water hexes, coastal sandbar masks, wave caps/heuristics, foam/reflection limits and phone budgets are authored assumptions. No live station measurements or water-quality samples were downloaded. NOAA federal data are broadly public domain; check named product and partner provenance rather than treating every linked product as identical licence. Rijkswaterstaat reuse is open in general; specific dataset licence and local canal coverage remain verify-first.
