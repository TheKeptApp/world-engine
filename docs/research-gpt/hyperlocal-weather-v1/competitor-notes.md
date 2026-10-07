# Competitor notes — hyperlocal weather
Checked 7 October 2026. Official feature documentation and vendor marketing are distinguished from independent forecast validation. Competitor private pipelines, contracts and cache policies were not inferred.

## What existing apps disclose
|App|Documented approach / presentation|What remains unverified|Lesson for Blocklight|
|---|---|---|---|
|Apple Weather|Next-hour precipitation/notifications in US, Australia, Ireland, Japan and UK; national-service inputs. WeatherKit includes minute chance and intensity.|Native grid, refresh SLA and onset-error distribution.|Good available iPhone implementation; query location availability instead of assuming universal support.|
|AccuWeather|MinuteCast minute-by-minute start/end/type/intensity,120 minute developer horizon; direct coordinates.|Current native resolution and calibrated timing error. Older 0.6sqmi/five-minute/four-hour enterprise brochure is a different historical product.|Useful timing UI, but separate commercial licence and MinuteCast purchase are required.|
|CARROT|Foreca default, premium provider choices and personal stations; rain notifications and radar.|Exact backend for each alert; selected general provider need not power every product.|Polished weather apps can assemble licensed inputs rather than build forecasts.|
|Weather Underground|BestForecast combines forecasts and quality-controlled neighbourhood observations; closest station supplies conditions.|Old 4 km/hourly generation/15 min refresh table's current applicability; nearby-station representativeness.|Local observations can improve an app without becoming one sensor per block.|
|Tomorrow consumer app|2019 announcement advertised street-by-street rain/snow timing and start/stop alerts.|Current consumer app grid, cadence and probability calibration.|Product promise does not establish a reusable/API-entitled dataset.|
|RainViewer|App advertises 100m detail,2 min radar updates and two-hour nowcast updated 10 min; FAQ admits drizzle/gaps.|Independent skill and native information at 100m; public API conflicts.|App capability is not the public API contract. Exclude until current commercial rights are explicit.|
|MyRadar|Official listing describes hyperlocal rain alerts and precipitation Live Activities; RainCheck solicits real-world confirmations.|Universal best-accuracy claims; calibrated error distribution; API entitlement.|Useful countdown/Live Activity benchmark, not evidence of freely reusable data.|
|Weather Strip|Explains probability versus intensity, radar nowcast versus hourly-model disagreement; shows forecast age and “Light rain in 18 minutes”; separate short-term provider.|Calibrated onset confidence bounds.|Best documented explanatory UX example; expose age and product provenance.|
|Foreca app|Sept 23,2026 daily ensembles: temperature shaded 50/80% ranges; precipitation median and 80% bars.|Minute rain-arrival confidence interval.|Copy the idea of uncertainty visualization, not daily intervals as minute-onset bounds.|

Primary feature links:
- Apple: [coverage and sources](https://support.apple.com/en-gb/105038), [minute probability](https://developer.apple.com/documentation/weatherkit/minuteweather/precipitationchance).
- AccuWeather: [developer MinuteCast](https://developer.accuweather.com/minutecast/geoposition-minutecast), [historical GIS brochure](https://afb.accuweather.com/hubfs/Brochures/GIS%20Data%20Services%20Guide.pdf). Treat brochure specifications as historical, not the current API guarantee.
- CARROT: [provider support](https://support.meetcarrot.com/weather/), [product](https://meetcarrot.com/weather/).
- Weather Underground: [data explanation](https://www.wunderground.com/about/data), [PWS network](https://www.wunderground.com/pws/overview). Current vendor 400k+ network claim supersedes older 250k+ count; neither is independent coverage proof.
- Tomorrow: [2019 launch announcement](https://www.tomorrow.io/blog/climacell-launches-its-consumer-weather-app/).
- RainViewer: [app claims](https://www.rainviewer.com/), [limitations](https://www.rainviewer.com/faq.html), [2026 transition](https://www.rainviewer.com/api/transition-faq.html), [conflicting API page](https://www.rainviewer.com/api.html).
- MyRadar: [publisher-controlled App Store listing](https://apps.apple.com/us/app/myradar-accurate-weather-radar/id322439990), [RainCheck](https://go.myradar.com/myradar-raincheck).
- Weather Strip: [support and uncertainty explanations](https://www.weatherstrip.app/support/).
- Foreca: [ensemble announcement](https://business.foreca.com/newsroom/foreca-weather-api-update-visualizing-forecast-uncertainty-with-ensemble-statistics).

## RainViewer discrepancy
The official transition FAQ says public future frames stopped January 1,2026, remaining use is personal/educational, maximum zoom 7 and 100 requests/IP/min. The main API page still discusses future frames/different limits. No protected page or throttling was bypassed. Treat this as conflicting official documentation; require a current commercial agreement. A map tile advertised at 100m does not by itself disclose native radar information, and a consumer app's two-hour forecast does not authorize a startup to use that forecast.

## Minute timing and uncertainty
No matched independent US test was verified showing Apple, Tomorrow, AccuWeather or another listed vendor consistently wins for arrival on a real city block. “Minute-by-minute” describes output spacing. Precision in coordinates, interpolated forecast output, radar-pixel display and “hyperlocal” marketing describe different things.

Physical problems include new storm initiation, growth/decay, advection changes, virga, radar beam height, bright-band snow and precipitation phase beneath the beam. Primary research addresses probabilistic approaches but does not eliminate these problems or validate the listed commercial products head to head. [Probabilistic nowcasting research](https://www.nature.com/articles/s41586-021-03854-z), [NowcastNet](https://www.nature.com/articles/s41586-023-06184-4), [NWS phase explanation](https://www.weather.gov/jan/dualpolupgrade-applications), [NWS radar limits](https://www.weather.gov/mrx/radarrainfallestimates).

Illustrative calculation, not measured provider error: at storm translation 10m/s,1 km displacement corresponds to roughly 1.7 minutes and 3 km to 5 minutes. Initiation/decay can break the simple displacement calculation entirely. A rendered 100m street is more spatially precise than these upstream grids; the animation must not imply weather was observed for every roof.

Proposed Blocklight language:
- Supported fresh nowcast: “Rain may arrive near your block around 12 min.” Show minute intensity and source age.
- If minute probability is available: label it as chance of precipitation at the displayed time, not confidence in start time.
- If a calibrated arrival interval is available: “Rain likely in 10–20 min.” Do not manufacture that interval from a single minute probability.
- No supported feed, radar gap or stale product: “Rain timing unavailable.” Never convert missing data into “No rain.”
- Ground material: “Estimated wet ground” or “Snowpack estimate.” Weather history does not observe salt, plowing or every shaded curb.

Use probability, intensity, accumulation, arrival estimate and data age as separate fields. Correlated minute probabilities cannot be multiplied as if independent. When hourly rain chance and radar onset disagree, explain they use different inputs/time scales; do not hide the disagreement behind a single certainty label.

## Quality evaluation proposal
Before vendor selection by accuracy, obtain rights for testing and retention. Use a held-out city/season/storm sample including Denver convective/virga events and Chicago winter/lake-effect events. Record source issue time, arrival threshold and station/sensor representativeness. Compare onset absolute error, missed/false events, intensity and probability calibration by lead-time band. A neighbourhood station is not a perfect truth label for every block. AccuWeather standard terms restrict evaluation/algorithmic uses, so use a custom agreement for such a test.

No tests, subscriptions, vendor messages, private API access or independent forecast rankings were performed for this pack.
