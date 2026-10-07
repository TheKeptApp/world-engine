# Primary sources and verification ledger
Checked 7 October 2026. All links below are primary provider, government, official product/support, or original research sources. IDs are used in sources.csv; direct citations also appear beside claims in README.md and competitor-notes.md.

VERIFIED describes documentary support, not successful API calls or independent forecast accuracy. HISTORICAL_ONLY is not a current service guarantee. UNVERIFIED, CONDITIONAL and RECHECK flags identify missing current prices, rights, metadata or conflicting documents. Private agreements may supersede public pages; accepted plan terms must be checked before procurement.

|ID|Source|Status|Supports / qualification|
|---|---|---|---|
|G01|[NWS API](https://www.weather.gov/documentation/services-web-api)|VERIFIED|Grid forecasts, free access, caching, unpublished rate limits|
|G02|[NWS data policy](https://www.weather.gov/disclaimer)|VERIFIED|Public-domain policy, third-party exceptions, derived products|
|G03|[NDFD directive](https://www.weather.gov/media/directives/010_pdfs/pd01002001curr.pdf)|VERIFIED|Native spatial resolutions by US domain|
|G04|[NDFD XML](https://digital.weather.gov/xml/rest.php)|VERIFIED|Updates and point-query constraints|
|G05|[MRMS overview](https://www.nssl.noaa.gov/projects/mrms/)|VERIFIED|Radar system and software/data distinction|
|G06|[MRMS products](https://www.nssl.noaa.gov/projects/mrms/operational/tables.php)|VERIFIED|Product-specific cadence and QPE latency|
|G07|[MRMS NOAA cloud dataset](https://registry.opendata.aws/noaa-mrms-pds/)|VERIFIED|Public data access, attribution request|
|G08|[NOAA open datasets](https://www.noaa.gov/nodd/datasets)|VERIFIED|Documented cloud distribution rather than graphics scraping|
|G09|[HRRR products](https://www.nco.ncep.noaa.gov/pmb/products/hrrr/)|VERIFIED|3 km runs, horizon and subhourly files|
|G10|[HRRR overview](https://rapidrefresh.noaa.gov/hrrr/)|VERIFIED|Hourly model and graphics access warning|
|G11|[Prototype NOAA nowcast](https://www.weather.gov/owp/oh_hrl_hag_empe_mpn)|HISTORICAL_ONLY|HPN prototype, not verified current nationwide service|
|G12|[NOHRSC snowfall products](https://www.nohrsc.noaa.gov/snowfall_v2/)|VERIFIED|Recent snowfall analyses|
|G13|[Snowfall description](https://www.nohrsc.noaa.gov/technology/pdf/PDD_National_Gridded_Snowfall_Analysis.pdf)|VERIFIED|6/24/48/72 h and revision schedule|
|G14|[Snowfall historical design](https://www.nohrsc.noaa.gov/technology/pdf/Proposal_for_National_Snowfall_Analysis_Phase_II.pdf)|HISTORICAL_ONLY|2.5 km design; current grid unverified|
|G15|[SNODAS](https://nsidc.org/data/g02158/versions/1)|VERIFIED|1 km daily snowpack/melt, citation and support status|
|G16|[SNODAS DOI](https://doi.org/10.7265/N5TB14TC)|VERIFIED|Required dataset citation|
|G17|[NOHRSC snow technology](https://www.nohrsc.noaa.gov/technology/)|VERIFIED|Hourly internal model versus daily download|
|G18|[RRFS](https://gsl.noaa.gov/rrfs/)|VERIFIED_DESCRIPTION|3 km planned model capability|
|G19|[NWS service notices](https://www.weather.gov/notification)|DATE_RECHECK_REQUIRED|Oct 2 notice lists Nov 3 2026 implementation; feed/search discrepancy|
|G20|[Radar virga](https://inside.nssl.noaa.gov/mrms/2018/03/when-radar-observed-precipitation-does-not-reach-the-ground/)|VERIFIED|Radar precipitation may evaporate before surface|
|G21|[Winter precipitation research](https://www.nssl.noaa.gov/research/winter/)|VERIFIED|Winter radar limitations and liquid equivalent|
|G22|[HRRR soil evaluation](https://repository.library.noaa.gov/view/noaa/53800)|VERIFIED_STUDY|Soil model bias; not pavement observation|
|C01|[WeatherKit capabilities and prices](https://developer.apple.com/weatherkit/)|VERIFIED|Quotas, published USD tiers and attribution|
|C02|[Apple WeatherKit legal](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)|VERIFIED|Attachment 8/9 storage, derived databases and monetization|
|C03|[WeatherKit REST](https://developer.apple.com/documentation/weatherkitrestapi)|VERIFIED|Availability and weather datasets|
|C04|[WeatherKit WWDC](https://developer.apple.com/videos/play/wwdc2022/10003/)|VERIFIED_API_SHAPE|Bundled datasets in one REST request; billing multiplicity unverified|
|C05|[Apple sources attribution](https://developer.apple.com/weatherkit/data-source-attribution/)|VERIFIED|Legal data-source link|
|C06|[Tomorrow timesteps](https://docs.tomorrow.io/reference/weather-data-layers)|VERIFIED_FIELD_DEPENDENT|1 min to 6 h, paid history and field availability|
|C07|[Tomorrow limits](https://support.tomorrow.io/hc/en-us/articles/20273728362644-Free-API-Plan-Rate-Limits)|VERIFIED|Evaluation quotas|
|C08|[Tomorrow terms](https://www.tomorrow.io/legal/terms-of-service/)|VERIFIED|Commercial Order and attribution; evaluation restrictions|
|C09|[Tomorrow snow fields](https://docs.tomorrow.io/reference/data-layers-core)|VERIFIED|Snowfall and snow depth availability|
|C10|[Tomorrow land fields](https://docs.tomorrow.io/reference/land)|VERIFIED|Soil temperature/moisture|
|C11|[Tomorrow snow interpretation](https://support.tomorrow.io/hc/en-us/articles/43215043291028-Snow-Data-on-the-Tomorrow-io-Platform)|VERIFIED_VENDOR_DESCRIPTION|Snow depth, melt/compaction and snowfall conversion|
|C12|[Open-Meteo pricing](https://open-meteo.com/en/pricing)|QUOTAS_VERIFIED_PRICE_UNVERIFIED|1M/5M/50M+ quotas; current USD omitted|
|C13|[Open-Meteo terms](https://open-meteo.com/en/terms)|VERIFIED|Data CC BY 4.0 versus paid commercial service|
|C14|[Open-Meteo model docs](https://open-meteo.com/en/docs/gfs-api)|VERIFIED|US HRRR and model-specific grid|
|C15|[Open-Meteo variables](https://open-meteo.com/en/docs)|VERIFIED|15 min fields, snow/soil/irradiance and call weights|
|C16|[Open-Meteo historical price announcement](https://openmeteo.substack.com/p/api-subscriptions-for-commercial)|HISTORICAL_ONLY|2023 $29/$99; not current verified prices|
|C17|[AccuWeather pricing](https://developer.accuweather.com/pricing)|QUOTAS_VERIFIED_PRICE_UNVERIFIED|Core packages; MinuteCast separate|
|C18|[AccuWeather MinuteCast](https://developer.accuweather.com/minutecast/geoposition-minutecast)|VERIFIED|120 min minute output|
|C19|[AccuWeather terms](https://developer.accuweather.com/documentation/terms-of-use)|VERIFIED|April 28 2026 restrictions; custom rights needed|
|C20|[AccuWeather freshness](https://developer.accuweather.com/documentation/best-practices)|VERIFIED_GUIDANCE|Endpoint lifecycle; not a fixed global cadence|
|C21|[Xweather plans](https://www.xweather.com/products/weather-api)|ALLOWANCE_VERIFIED_PRICE_UNVERIFIED|15k free accesses; US/Canada PAYG|
|C22|[Xweather conditions](https://www.xweather.com/docs/weather-api/endpoints/conditions)|VERIFIED|Interpolated conditions, minutely filtering and access accounting|
|C23|[Xweather credits](https://www.xweather.com/docs/weather-api/resources/credits)|VERIFIED|Source attribution|
|C24|[Xweather map units](https://www.xweather.com/docs/maps/getting-started/accesses)|VERIFIED|Per-tile per-layer units and map cache cadence|
|C25|[Xweather legal](https://www.xweather.com/legal)|API_RIGHTS_UNVERIFIED|Linked general terms not sufficient to establish archive licence|
|C26|[Visual Crossing plans](https://www.visualcrossing.com/weather-data-pricing/)|PARTIAL_VERIFICATION|LLX price/capacity; storage and counting need plan confirmation|
|C27|[Visual Crossing LLX](https://www.visualcrossing.com/resources/news/visual-crossing-launches-timeline-llx-weather-api-providing-ultra-low-latency-weather-data-for-next-gen-applications/)|VERIFIED_VENDOR_RELEASE|LLX distinct from ordinary Timeline record pricing|
|C28|[Visual Crossing Timeline](https://www.visualcrossing.com/resources/documentation/weather-api/timeline-weather-api/)|VERIFIED|Endpoint features; minute-nowcast eligibility unresolved|
|C29|[Weatherbit minute API](https://www.weatherbit.io/api/weather-forecast-minutely)|VERIFIED_VENDOR_SPEC|Approx 1 km radar and next 60 min|
|C30|[Weatherbit plans](https://www.weatherbit.io/pricing)|QUOTAS_VERIFIED_PRICE_UNVERIFIED|Paid tiers and retention conditions|
|C31|[Weatherbit cadence](https://www.weatherbit.io/)|VERIFIED_VENDOR_SPEC|Current/forecast update claims; no independent skill test|
|C32|[Weatherbit terms](https://www.weatherbit.io/terms)|VERIFIED|Commercial/retention terms apply|
|C33|[OpenWeather current prices](https://openweathermap.org/price)|VERIFIED|One Call 4 $0.0015 beyond 1000 calls/day|
|C34|[OpenWeather API](https://openweathermap.org/api)|VERIFIED_VENDOR_SPEC|Minute/15 min/hour/day families|
|C35|[OpenWeather FAQ](https://openweathermap.org/faq)|VERIFIED|One Call 4 and default daily account limit|
|C36|[OpenWeather 4 endpoint docs](https://openweather.uk/api/one-call-4)|INDEXED_ONLY_DIRECT_INACCESSIBLE|Separate timelines/pagination; live metering unverified|
|C37|[OpenWeather licence explainer](https://openweathermap.org/storage/app/media/documents/License_explainer_25%20Feb_25.pdf)|OLD_PRODUCT_APPLICABILITY_UNVERIFIED|2025 explainer references One Call 3; confirm 4 licence|
|P01|[Apple Weather coverage](https://support.apple.com/en-gb/105038)|VERIFIED|Next-hour regions and national-service inputs|
|P02|[WeatherKit minute probability](https://developer.apple.com/documentation/weatherkit/minuteweather/precipitationchance)|VERIFIED|Minute probability 0..1|
|P03|[CARROT providers](https://support.meetcarrot.com/weather/)|VERIFIED|Provider selection, stations and premium features|
|P04|[CARROT product](https://meetcarrot.com/weather/)|VERIFIED_FEATURE|Rain notifications and radar|
|P05|[Weather Underground data](https://www.wunderground.com/about/data)|MIXED_CURRENT_HISTORICAL|BestForecast/stations; old grid/cadence unverified|
|P06|[Weather Underground stations](https://www.wunderground.com/pws/overview)|VERIFIED_VENDOR_CLAIM|400k+ PWS claim; rights not inferred|
|P07|[Tomorrow consumer launch](https://www.tomorrow.io/blog/climacell-launches-its-consumer-weather-app/)|HISTORICAL_ONLY|2019 hyperlocal product description|
|P08|[RainViewer app](https://www.rainviewer.com/)|VERIFIED_VENDOR_CLAIM|App nowcast and radar-detail claims|
|P09|[RainViewer limitations](https://www.rainviewer.com/faq.html)|VERIFIED|Radar gaps and drizzle|
|P10|[RainViewer transition](https://www.rainviewer.com/api/transition-faq.html)|OFFICIAL_CONFLICT_RECHECK|Jan 1 2026 public nowcast removal and personal-use limits|
|P11|[RainViewer API](https://www.rainviewer.com/api.html)|OFFICIAL_CONFLICT_RECHECK|Conflicts with transition FAQ|
|P12|[MyRadar listing](https://apps.apple.com/us/app/myradar-accurate-weather-radar/id322439990)|VERIFIED_FEATURE_NOT_SKILL|Rain alerts and Live Activities|
|P13|[MyRadar RainCheck](https://go.myradar.com/myradar-raincheck)|VERIFIED_FEATURE|User-confirmation campaign|
|P14|[Weather Strip support](https://www.weatherstrip.app/support/)|VERIFIED|Probability/intensity distinction, separate short-term provider and age|
|P15|[Foreca uncertainty](https://business.foreca.com/newsroom/foreca-weather-api-update-visualizing-forecast-uncertainty-with-ensemble-statistics)|VERIFIED_DAILY_ONLY|Sept 23 2026 daily ensemble percentiles|
|R01|[Probabilistic nowcasting research](https://www.nature.com/articles/s41586-021-03854-z)|VERIFIED_STUDY|Radar nowcast uncertainty; not vendor comparison|
|R02|[NowcastNet research](https://www.nature.com/articles/s41586-023-06184-4)|VERIFIED_STUDY|Heavy precipitation/growth limits; not provider guarantee|
|R03|[NWS dual-pol](https://www.weather.gov/jan/dualpolupgrade-applications)|VERIFIED|Bright band and atmospheric phase interpretation|
|R04|[NWS rainfall limitations](https://www.weather.gov/mrx/radarrainfallestimates)|VERIFIED|Radar estimates versus surface rain|
|S01|[NOAA solar reference](https://gml.noaa.gov/grad/solcalc/calcdetails.html)|VERIFIED|Calculator no longer maintained|
|S02|[NOAA solar equations](https://gml.noaa.gov/grad/solcalc/solareqns.PDF)|VERIFIED|Local solar calculation reference|
|S03|[Solar Position Algorithm](https://midcdmz.nlr.gov/spa/)|VERIFIED_ALGORITHM_CODE_RIGHTS_RECHECK|Solar angles; code licence requires review|
|C38|[Visual Crossing LLX docs](https://www.visualcrossing.com/resources/documentation/weather-api/timeline-llx-weather-api/)|VERIFIED_API_SPEC; METERING_PARTIAL|Bundled response, recent history and optional minute data|
|C39|[Visual Crossing terms](https://www.visualcrossing.com/weather-services-terms/)|VERIFIED_TERMS_SCOPE_MAPPING_UNRESOLVED|Storage permission depends purchased licence|
|C40|[OpenWeather terms](https://openweather.co.uk/api/files/file/OpenWeather_T&C_of_sale.pdf)|GENERAL_TERMS_VERIFIED; ONECALL4_MAPPING_UNVERIFIED|CC BY-SA/ODbL general terms; product-specific scope confirm|
|C41|[OpenWeather official docs link](https://openweathermap.org/api/one-call-4-desciption)|DIRECT_FETCH_INACCESSIBLE|Official linked page; indexed alternate-domain details provisional|
|C42|[Apple programme enrollment](https://developer.apple.com/programs/enroll/)|VERIFIED|99USD annual membership; existing membership not incremental|
|P16|[AccuWeather historical GIS brochure](https://afb.accuweather.com/hubfs/Brochures/GIS%20Data%20Services%20Guide.pdf)|HISTORICAL_ONLY|Old resolution/cadence differs current 120 min developer product|

## Unresolved access and conflicting material
- OpenWeather's official linked One Call 4 documentation failed direct retrieval; alternate-domain documentation was available through search-indexed text but direct retrieval returned an error. Alternate-domain ownership and live API/pagination/metering were not established. Neither route was bypassed. Endpoint-count costs are scenarios.
- Open-Meteo's current rendered pricing verifies capacities but omits numeric subscription fees. The 2023 announcement is labelled historical; current USD prices are not asserted.
- Tomorrow, AccuWeather, Xweather and Weatherbit current production rates were quote-only or absent from accessible current content. Quotas and free allowances do not establish production commercial rights.
- Xweather's linked general legal content did not establish API-specific caching/archive/redistribution scope. LLX licence-to-shared-storage mapping also remains unresolved; public viewing is different from raw downloading.
- RainViewer public API page and 2026 transition FAQ conflict. The consumer app's nowcast is not evidence of public commercial nowcast access.
- RRFS service notice indexing includes conflicting dates. Current notice listing reports Nov 3,2026 after an Oct 2 update; exact implementation must be rechecked before migrating from HRRR.
- Prototype NOAA HPN/FFP descriptions are historical. No current nationwide ready-made minute endpoint was verified.
- Solar calculator references are explanatory, not a maintained runtime service. SPA algorithm documentation does not waive its software download licence.

No authentication, paywall, access block, site throttling or protected API was bypassed. No live weather keys or paid account were used; no API-response tests, vendor contacts or purchases occurred. Provider marketing for resolution or accuracy is labelled accordingly. Legal findings summarize specific published terms; interpretation of Blocklight's implementation and any negotiated exceptions remains unresolved.

## Independent accuracy evidence
R01/R02 are original research on probabilistic/heavy-precipitation nowcasting. They support limitations and methodology, not an Apple-versus-Tomorrow-versus-AccuWeather ranking. No current matched US street-onset benchmark was verified. Product probability, native grid size, rendered-pixel spacing and timestep are distinct metrics.
