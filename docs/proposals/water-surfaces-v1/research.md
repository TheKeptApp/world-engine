# Water research + renderer-neutral design

Research checked 7 October 2026. **Verified** below means the cited primary documentation supports the mechanism or service capability; **Proposal** means WorldEngine art/engineering judgement. Sources and access failures are also recorded in sources.md and water-values.json. No actual current weather, water quality, station coverage or iPhone shader was verified by these concept sheets.

## Why water has colour

**Verified:** pure water absorbs the red part of visible light preferentially; dissolved organic matter, algae and suspended sediment change natural water colour. Blue sky is not the sole cause of blue water. [NOAA](https://oceanservice.noaa.gov/facts/oceanblue.html), [USGS](https://www.usgs.gov/water-science-school/science/water-color).

**Proposal:** separate body colour, shallow bottom contribution and surface reflection. Light travelling through deeper/turbid water reveals less bottom contribution; use `bottomWeight=exp(-K_water*depth)` only where depth/attenuation are supported. Unknown bathymetry gets an explicitly inferred distance-to-bank colour transition. This is an appearance approximation, not a spectral water-quality retrieval. Miami sandbar turquoise requires a shallow-bottom mask; a coastline alone does not locate a sandbar. Suspended sediment changes body colour rather than adding a photographic texture. Sun direction/view angle control broad broken glint; do not multiply orange sun into body colour and then light it orange again.

The proposed colour families are blue-grey for Michigan, green-grey for Chicago River, restrained blue-green for Sloan, turquoise shallows/deeper blue for Miami, muted green-grey for SF, grey-blue for NYC and olive-green for the canal. These are regional art assumptions, **not measured local water colours**. Summer and winter use the same material families unless actual source conditions change them. The storm palette is a review endpoint; turbidity must not automatically increase solely because it rains.

**Proposal:** shade body/reflection/foam once, then apply the shared atmospheric term and exposure. Water-column absorption `K_water` is distinct from air extinction `sigma_air`: one affects light inside water, the other the camera-to-surface path. Atmospheric appearance is `L=T*L_surface+(1-T)*L_air`, with `T=exp(-integral(sigma_air ds))`. Either the shared post pass or the material owns this integration, never both. SF’s bank is a spatial fog field integrated once across every affected object, not an extra water haze sheet. Reuse weather-moments-v1’s exposure owner once; no water-only EV, warmth or white brightness floor at night.

## Free inputs and their limits

| Input | Source/capability verified | WorldEngine use and limits (proposal) |
|---|---|---|
| Wind, gusts, waves, temperature | [NDBC measurement definitions](https://www.ndbc.noaa.gov/faq/measdes.shtml): WSPD m/s, WVHT significant height, DPD peak-energy period, directions from true north | Choose a representative basin/exposure station, preserve QC/time. Seasonal buoy gaps and missing fields stay unknown. Direct fetch returned 403; indexed documentation was readable. Current delivery route and station IDs remain verify-first. |
| Land wind and forecast | [NWS API](https://www.weather.gov/documentation/services-web-api) is free open data | /points discovers station/grid context. A land station is wind support, not an observed wave-height feed. Forecast valid times remain distinct from observations. |
| Michigan ice + water temperature | [GLERL](https://www.glerl.noaa.gov/data/ice/) daily GLSEA and ice-chart archive since 1973 | Use spatial concentration and metadata/history; cloud-obscured temperature can be prior-map smoothing. Lake-wide percentages cannot locate a seawall shelf. No GLERL coverage assumed for Sloan/Chicago River. |
| Coastal water level/tide/current | [CO-OPS API](https://api.tidesandcurrents.noaa.gov/api/prod/), [free access](https://tidesandcurrents.noaa.gov/cms/wp-content/uploads/2025/07/The-Current-July-31-2025.pdf) | Observation and prediction are separate; use metric UTC and named datum. Tie to the world vertical datum before geometry moves. Product/station coverage differs; water level does not imply current vector or wave height. |
| Great Lakes water level | [NOAA lake-level explanation](https://oceanservice.noaa.gov/facts/gltides.html) | Meteorological fluctuations/seiches matter more than small astronomical tides. Do not apply coastal ocean tide amplitude to Michigan, Chicago River or Sloan. |
| Netherlands preview | [Rijkswaterstaat discovery](https://rijkswaterstaatdata.nl/data-zoeken/), [open data](https://www.rijkswaterstaat.nl/zakelijk/open-data) | Waterinfo services include level/wind/waves/temperature. Managed urban canal may lack a local station; exact coverage, datum and dataset terms remain unverified. Nearby coastal tide cannot substitute for a managed canal level. |

**Verified:** NOAA describes its data as broadly public domain. This is not blanket confirmation of every partner-supplied record; preserve dataset provenance and check its terms. [NOAA reuse FAQ](https://www.noaa.gov/office-education/outreach-communication/faq). **Proposal:** provider data cost can be zero for these public feeds, while backend requests/storage/bandwidth still cost money. No subscription savings figure or endpoint service guarantee is claimed.

**Proposal:** cache server-side per station/product/water body, not per camera/user. Coalesce observations every 15 minutes, daily ice fetches every six hours and forecasts at their published cadence, respecting cache headers/rate limits. Suggested stale limits are two hours for observations and 36 hours for daily ice, shortened by product policy if needed. Missing QC values or fields are null, never zero. Store raw units and source timestamps before conversion; retain observation/forecast/history/simulated/demo mode. The gallery itself makes no live requests. API adapters, actual station selection and data parsing are a later implementation step.

## Wind into waves

**Verified:** wave growth depends on wind, duration and fetch, with swell from distant wind adding an independent contribution. [NWS analysis](https://www.weather.gov/media/wrh/online_publications/TAs/ta0306.pdf). NDBC significant wave height is a statistical sea-state quantity, not the height of every individual crest. [Definitions](https://www.ndbc.noaa.gov/faq/measdes.shtml).

**Proposal:** representative observed/modelled Hs, period and direction take priority. If absent, use the explicitly simulated formula in JSON:

`Hs_visual=min(cap, 0.20*U²/g * sqrt(min(1,F/max(1,100*U²))) * min(1,D/7200))`

Here U is m/s, F metres upwind open-water fetch and D seconds coherent wind duration. This is an **authored limiter, not a calibrated marine forecast**. Default fetch/duration are profile fixtures, not inferred observations. Fetch rays stop at bank/shore; exposure/shadow matters. Keep separate ocean swell/wake reservoirs, so calm local wind can retain motion. Raw observed height remains stored even when a device visual cap is lower. Storm in a canal is a wind-art fixture, not an ocean-breaker or hazard prediction.

NDBC directions are FROM true north; propagation uses `(from+180) mod360`. Do not apply that conversion blindly to current vectors without checking metadata. Filter wind over about 120 seconds and blend wave parameters over about 180 seconds (proposal), with continuous deterministic phases. Store source, timestamp, phases and model version for walk recap; changing camera origin must not restart waves.

Use four decorrelated sine components with normalized amplitudes `Ai=(Hs/4)*sqrt(2)*wi/sqrt(sum(wj²))`, and `eta=sum Ai*sin(ki·x-omega_i*t+phi_i)`. This normalization matches the sine-sum variance convention; setting amplitude equal to Hs is incorrect. For known depth, solve `omega²=g*k*tanh(k*h)`; use deep-water `lambda=g*T²/(2*pi)` only in its valid regime. Unknown depth receives an authored wavelength fixture, clearly inferred. Display controls should preserve actual source status rather than implying the capped art predicts sea conditions.

## Cheap phone material

**Verified technique:** geometric wave sums and smaller-scale normal waves are established real-time methods. GPU Gems documents a shipped use in Uru; it does not prove today’s iPhone performance. [GPU Gems chapter](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models).

**Proposal v1:** one opaque water surface, four geometric sine terms near and analytic normal gradients; two small normal terms. Shore foam, wet contact and sandbar colour are masks in the same material. Geometry wavelengths must span at least four vertex spacings; shorter ripples are normal-only and fade below 1.5 projected pixels. Preserve real wave dimensions instead of enlarging them. Aerial uses two terms and a coarse mesh; far removes wave normals/wakes and retains mean colour, roughness, extent and the shared extinction. Camera-relative coordinates plus stable tile phase offsets avoid rebase seams and planet-scale float jitter.

Reflection uses the shared blurred environment and capped stylized angle blend; it does not duplicate a second PBR Fresnel lobe. The IOR/F0 reference is separate from art blend weights. No SSR, planar reflection camera, per-ripple light, per-frame cubemap or screen refraction in v1. Broken broad river building colours can be authored/inferred masks, never sharp repeated facades. Foam is short phase-broken segments at breaking/shore interactions, not a permanent white border. Deep-water foam coverage caps are illustrative; no measured whitecap relation is claimed. Existing rain wetness and the inherited shoreline 12% cap must have one owner.

**Verified API capabilities:** Apple documents geometry modifiers/surface shaders; three.js ShaderMaterial provides custom shader/uniform paths for WebGLRenderer. [Apple](https://developer.apple.com/videos/play/wwdc2021/10075/), [three.js](https://threejs.org/docs/pages/ShaderMaterial.html). **Inference/proposal:** these can express the shared wave/colour schema; actual WorldEngine material hooks, shadow behaviour and exposure plumbing were not checked. WebGPU needs a corresponding node/material adapter. Renderer-specific parameter binding is separate from the common world data.

The proposed water/shore foam/ice envelope is <=12k triangles, <=6 draws, <=4 MiB and <=0.8 ms GPU, **inside** the scene allowance. This is unbenchmarked. Count shadow/depth/material passes and transient targets, not just main-view mesh triangles. Water fills the screen: prioritize opaque fill rate and eliminate stacked alpha. Optional splash pool <=64 particles must fit the same envelope. Caustics, spectral FFT, interacting floes and boat fluid solvers are later work only after profiling.

## Ice and shore history

**Verified:** GLERL documents substantial interannual ice variability and temperature/ice observations/history; current spatial products are not centimetre-scale shelf surveys. [GLERL](https://www.glerl.noaa.gov/data/ice/).

**Proposal:** never freeze from month, snowfall or one cold reading. Supported spatial concentration/model plus cold/water-temperature history controls coverage. Local shelves additionally require local evidence or explicit inferred/demo status. Air temperature history alone does not establish ice thickness, shelf width or safety. No universal freezing-degree-day-to-shelf formula is supplied. Saline water needs salinity-aware freeze physics; freshwater 0°C must not be reused for NYC/SF/Miami sea water. Missing history means unknown, with open visible water and an unknown label; last supported ice may persist marked stale.

Shelf fragments are stationary opaque matte geometry; wave amplitude is damped by local ice fraction. Snow-on-ice is a separate snow reservoir. Far coverage is a spatial mask, never a lake-wide percentage evenly spread. The sheets show conditional small freshwater examples, not a current winter observation. Exposed storm waves can coexist with sheltered stationary shelves; do not melt the shelf merely by choosing the storm column.

## Phases and verification before implementation

1. **Now, low/medium effort proposal:** immutable shoreline/water IDs, datum/status metadata, one atmosphere/exposure owner, opaque material fallback, camera-relative phase coordinates, source/raw/render value separation. Test dry clear scene and night without bright-water floors.
2. **First implementation, medium:** four-wave near / two-wave aerial / flat far, masks, input cache and per-body fetch mapping. Profile fullscreen water with and without shadows on target devices; inspect seams/rebase continuity and subpixel shimmer. Do not promise the proposed .8 ms before measuring.
3. **Live history, medium/high:** verify NDBC route and representative station mappings; CO-OPS datum alignment; GLERL ice cells/temperature history; cache/QC/staleness tests; recap recording. Sloan and managed canals need their own supported sources or explicit simulation.
4. **Later, high or Stretch:** surveyed bathymetric sandbars, calibrated sediment palettes, flowing wakes from live vessel tracks, sparse splashes, local observed shelves. Reflections/refraction/spectral simulation remain contingent on budget and Style B value.

Open questions: actual bathymetry source/rights per water body; vertical datum relationship to exported terrain; latest material hook capabilities in renderer; local river/canal ice evidence; acceptable depiction caps during extreme real waves; allocation left after current scene/shadow costs.

## Shore construction at phone distance (proposal)
Seawall: keep a continuous parapet and supported top height; a dark water-side contact strip and occasional broken spray are enough. Riprap: cluster large matte blocks with clear silhouette breaks, not thousands of individual pebbles. Beach: broad sand/wet-sand bands and supported or inferred shallow surf; no grain noise. Marsh: grouped emergent stems/low lobes, irregular bank edge and very small sheltered ripples; avoid a uniform foam outline. Marina: real pier/pile spacing, opaque decks, discrete pile contact and boat wakes only when supplied or marked simulated.

At street scale, keep shore-contact and low-frequency waves visible; in the 45° aerial tier retain shoreline geometry, shallow-body colour contrast and major foam bands. At far scale collapse riprap/reeds/piles into a coherent shoreline edge and retain extent. Camera distance alone does not choose LOD: projected size does, with fades over a screen-size band. No floating contact shadows detached from shore and no water transparency revealing missing underwater ground. Proposed widths, pitches and colour hexes are in water-values.json and are not civil-engineering dimensions or surveyed asset geometry.
