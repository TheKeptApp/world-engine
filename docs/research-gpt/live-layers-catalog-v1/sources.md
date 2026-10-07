# Live layers: source evidence

Checked 2026-10-07. All ratings are research judgments under the named public terms; see README for definitions and cost assumptions. UNVERIFIED fields identify missing evidence. Vendor counts and refresh claims are attributed product claims, not independently measured accuracy. Government rights apply only to agency-produced or explicitly licensed records. $0 excludes infrastructure and does not imply unlimited requests.

## nws — NWS API

**Category:** weather. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US forecasts, alerts and observations. **Freshness / latency:** Product-dependent; cache-aware API; unpublished generous limits; no latency SLA.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NWS source and issue time; no endorsement; altered data not official.

**Limitations / unverified:** Partner observations and logos excluded from blanket clearance. Historical completeness not guaranteed.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> may be used without charge for any lawful purpose

**Primary evidence:**

- [Source 1 — www.weather.gov](https://www.weather.gov/documentation/services-web-api)
- [Source 2 — www.weather.gov](https://www.weather.gov/disclaimer)

## mrms — NOAA MRMS precipitation / radar

**Category:** weather. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** CONUS operational multi-radar products. **Freshness / latency:** Selected reflectivity and precipitation products every 2 minutes; publication latency not verified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA/NSSL; product and valid time.

**Limitations / unverified:** Whitelist NOAA-produced precipitation/radar outputs. NLDN/private lightning inputs and separate lightning products require rights audit.

**Primary evidence:**

- [Source 1 — www.nssl.noaa.gov](https://www.nssl.noaa.gov/projects/mrms/operational/tables.php)
- [Source 2 — www.weather.gov](https://www.weather.gov/disclaimer)

## snow — NOHRSC / SNODAS

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** CONUS modeled snow depth, SWE, melt. **Freshness / latency:** 1 km model with hourly timestep, daily assimilation/analyses; public delivery latency unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA/NOHRSC; model date.

**Limitations / unverified:** Model output is not measured neighborhood snow, grooming or ski quality; raw partner inputs excluded.

**Primary evidence:**

- [Source 1 — www.nohrsc.noaa.gov](https://www.nohrsc.noaa.gov/technology/)
- [Source 2 — www.nohrsc.noaa.gov](https://www.nohrsc.noaa.gov/help/)
- [Source 3 — www.weather.gov](https://www.weather.gov/disclaimer)

## sun — WorldEngine sun / shadow

**Category:** sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Worldwide position and timing. **Freshness / latency:** Computed for requested time; no upstream delay.

**Monthly data cost at 1k / 100k / 1M users:** $0 supplier fee / $0 supplier fee / $0 supplier fee. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ASSUMPTION: internally owned outputs |
| STORE | ASSUMPTION: internally owned outputs |
| RESELL | ASSUMPTION: internally owned outputs |
| DERIVE | ASSUMPTION: internally owned outputs |

**Attribution:** WorldEngine.

**Limitations / unverified:** User-supplied stack context; algorithm/library IP audit not performed. GREEN depends on ownership.

**Evidence:** user-provided stack description; ownership assumption, no external license verified.

## coops — NOAA CO-OPS

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US coasts and Great Lakes station water levels, tides, currents. **Freshness / latency:** 6-minute water levels; some 1-minute stations; monthly verification; latency station-dependent.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA CO-OPS; datum, units, timezone, observed vs predicted.

**Limitations / unverified:** latest lookup within 18 minutes is not a latency SLA. Request-span caps; partner station rights separate.

**Primary evidence:**

- [Source 1 — api.tidesandcurrents.noaa.gov](https://api.tidesandcurrents.noaa.gov/api/dev)
- [Source 2 — tidesandcurrents.noaa.gov](https://tidesandcurrents.noaa.gov/web_services_info.html)
- [Source 3 — oceanservice.noaa.gov](https://oceanservice.noaa.gov/disclaimer.html)

## usgs — USGS modern Water Data

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US river stage, discharge, monitoring sites and water quality. **Freshness / latency:** Typically 15-minute measurements, often hourly transmission; station-dependent receipt delay.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** USGS; provisional/approved flag and station provider.

**Limitations / unverified:** Use modern OGC API; legacy WaterServices retirement Q1 2027. Free key increases limits; partner records require separate clearance.

**Primary evidence:**

- [Source 1 — api.waterdata.usgs.gov](https://api.waterdata.usgs.gov/docs/)
- [Source 2 — www.usgs.gov](https://www.usgs.gov/faqs/how-often-are-real-time-streamflow-data-updated)
- [Source 3 — www.usgs.gov](https://www.usgs.gov/data-management/data-licensing)
- [Source 4 — waterdata.usgs.gov](https://waterdata.usgs.gov/blog/api-waterservices-decom/)

## nwps — NWS National Water Prediction Service

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US gauge observations, flood forecasts and thresholds; modeled reaches. **Freshness / latency:** Gauge and forecast-issuance dependent; no universal cadence or SLA.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NWS; original gauge provider; forecast issue time.

**Limitations / unverified:** Main API is not a historical observation archive. Experimental NWM guidance is not official forecast or 24/7 supported; partner raw observations audited separately.

**Primary evidence:**

- [Source 1 — water.noaa.gov](https://water.noaa.gov/about/api)
- [Source 2 — api.water.noaa.gov](https://api.water.noaa.gov/nwps/v1/docs/)
- [Source 3 — www.weather.gov](https://www.weather.gov/disclaimer)

## ndbc — NOAA NDBC

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US and ocean buoy / C-MAN marine stations. **Freshness / latency:** Most hourly reports available by :25; station-dependent.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA/NDBC and actual station operator.

**Limitations / unverified:** Shared HTTP retrieval preferred; realtime files approximately 45 days. Offshore wave data does not directly describe breaking waves on a beach.

**Primary evidence:**

- [Source 1 — www.ndbc.noaa.gov](https://www.ndbc.noaa.gov/faq/rt_data_access.shtml)
- [Source 2 — www.weather.gov](https://www.weather.gov/disclaimer)

## snotel — NRCS SNOTEL / AWDB

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Western US and Alaska snow and climate stations. **Freshness / latency:** Hourly; GOES often :40, cellular :05; PST year-round; snow courses monthly.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** USDA NRCS; station/network operator.

**Limitations / unverified:** Hourly readings generally unedited; daily QA differs. AWDB external networks excluded from blanket rights.

**Primary evidence:**

- [Source 1 — www.nrcs.usda.gov](https://www.nrcs.usda.gov/state-offices/montana/montana-snow-survey/frequently-asked-snow-survey-questions-montana)
- [Source 2 — www.usda.gov](https://www.usda.gov/about-usda/policies-and-links)

## ski — Mountain News / OnTheSnow partner API

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global resort-reported snow, trail and lift status. **Freshness / latency:** Marketed realtime; reports generally daily/seasonal; inspect updatedDt.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** UNVERIFIED: partner contract.

**Limitations / unverified:** Fee-based API. Website access is not redistribution permission; grooming/lift truth requires resort timestamps.

**Primary evidence:**

- [Source 1 — partner.docs.onthesnow.com](https://partner.docs.onthesnow.com/)
- [Source 2 — partner.docs.onthesnow.com](https://partner.docs.onthesnow.com/api-reference/resorts/batch-apis/snowreports-and-snowfall-api)

## beach_chicago — Chicago beach lab / swim conditions

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Chicago beaches in swim season. **Freshness / latency:** Daily samples sunrise–08:30; lab 3–4 hours; quality status by 13:30; flags as needed.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: portal download/display |
| STORE | CONDITIONAL: portal analysis |
| RESELL | UNVERIFIED: dataset license unspecified |
| DERIVE | UNVERIFIED: commercial derivatives |

**Attribution:** Chicago Park District / City dataset and sample date.

**Limitations / unverified:** Offseason is stale by design. Separate sample result, prediction and official advisory.

**Primary evidence:**

- [Source 1 — www.chicagoparkdistrict.com](https://www.chicagoparkdistrict.com/beach-faqs)
- [Source 2 — www.chicagoparkdistrict.com](https://www.chicagoparkdistrict.com/beach-dashboard)
- [Source 3 — data.cityofchicago.org](https://data.cityofchicago.org/Parks-Recreation/Beach-Lab-Data-Culture-Tests-For-Plenario/84eh-sf3p)

## beacon — EPA BEACON / Water Quality Portal

**Category:** environment. **Checked:** 2026-10-07. **Our apps:** GREEN: federal subset. **World State API:** YELLOW: aggregate partners.

**Coverage:** US beach advisory history and multi-agency discrete water samples. **Freshness / latency:** Seasonal/reporting-dependent; not a guaranteed live beach advisory feed.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** EPA/USGS and contributor; query date/DOI where required.

**Limitations / unverified:** Whole collection rights unresolved. Old WQX2.2 UI omits USGS additions after March 11 2024; use current WQX3/modern services.

**Primary evidence:**

- [Source 1 — www.epa.gov](https://www.epa.gov/waterdata/fact-sheet-beach-act-locational-data)
- [Source 2 — www.waterqualitydata.us](https://www.waterqualitydata.us/)
- [Source 3 — pasteur.epa.gov](https://pasteur.epa.gov/license/sciencehub-license-non-epa-generated.html)

## mobilitydb — MobilityDatabase

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** GREEN: metadata / YELLOW: feeds. **World State API:** GREEN: metadata / YELLOW: feeds.

**Coverage:** 6000+ GTFS/GTFS-rt/GBFS feeds in 99+ countries; catalog not universal entitlement. **Freshness / latency:** Catalog checked daily; realtime freshness depends on each operator.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: CC0 catalog metadata; feeds separate |
| STORE | ALLOWED: CC0 metadata; feeds separate |
| RESELL | ALLOWED: CC0 metadata; feeds UNVERIFIED |
| DERIVE | ALLOWED: CC0 metadata; feeds separate |

**Attribution:** Metadata credit optional; operator-specific attribution.

**Limitations / unverified:** GTFS-rt is a format, not a nationwide license. Catalog coverage does not ensure active feed or accurate positions.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> All metadata generated by MobilityData is licensed under CC0

**Primary evidence:**

- [Source 1 — mobilitydatabase.org](https://mobilitydatabase.org/faq)
- [Source 2 — mobilitydatabase.org](https://mobilitydatabase.org/terms-and-conditions)

## transitland — Transitland

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global aggregate static/realtime transit, US all-state discovery. **Freshness / latency:** Static daily; realtime operator-dependent; archive features plan-specific.

**Monthly data cost at 1k / 100k / 1M users:** $250 monthly Pro; or $200/month annual prepay / Quote: above 200k REST plan / Quote: above 200k REST plan. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** Transitland name/logo, terms link and source operator.

**Limitations / unverified:** Free 10k REST; Pro 200k; feed downloads count. Aggregator plan does not clear source feed storage/resale.

**Primary evidence:**

- [Source 1 — www.transit.land](https://www.transit.land/plans-pricing/)
- [Source 2 — www.transit.land](https://www.transit.land/terms)
- [Source 3 — www.transit.land](https://www.transit.land/documentation/rest-api/feeds)

## bart — BART direct

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** San Francisco Bay Area BART schedules/realtime/alerts. **Freshness / latency:** Realtime numeric cadence and observation lag unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: revocable developer license |
| STORE | ALLOWED: reproduce subject freshness |
| RESELL | ALLOWED: redistribute under agreement |
| DERIVE | CONDITIONAL: broad use; derivative scope inferred |

**Attribution:** BART credit/link requested; trademarks/maps separate.

**Limitations / unverified:** No universal SLA; read operator agreement and preserve freshness.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> rights to use, reproduce, and redistribute BART Data

**Primary evidence:**

- [Source 1 — www.bart.gov](https://www.bart.gov/schedules/developers/developer-license-agreement)
- [Source 2 — www.bart.gov](https://www.bart.gov/schedules/developers/gtfs-realtime)

## cta — CTA direct

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW: ambient use; GREEN: rider use. **World State API:** RED: standalone resale.

**Coverage:** Chicago bus/train realtime, schedules and alerts. **Freshness / latency:** Bus Tracker 30-second updates; other products vary; observed lag unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: transit assistance/promotion purpose |
| STORE | CONDITIONAL: fresh application cache; delete on termination |
| RESELL | PROHIBITED: standalone CTA data resale |
| DERIVE | CONDITIONAL: transit-purpose derivatives |

**Attribution:** CTA developer branding conditions; no endorsement.

**Limitations / unverified:** Current-stack audit: integration does not establish World State resale rights. Cross-domain derivatives need permission.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> You will not sell, auction or barter any CTA Data separate from your application.

**Primary evidence:**

- [Source 1 — www.transitchicago.com](https://www.transitchicago.com/downloads/sch_data/developers_license_agreement.htm)
- [Source 2 — www.transitchicago.com](https://www.transitchicago.com/developers/bustracker/)

## rtd — RTD direct

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** YELLOW.

**Coverage:** Denver regional transit GTFS and realtime. **Freshness / latency:** Major schedules January/May/August; realtime cadence/lag unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: limited revocable agreement |
| STORE | ALLOWED: reproduction under agreement |
| RESELL | CONDITIONAL: explicit redistribution; paid sublicense not expressly described |
| DERIVE | CONDITIONAL: use grant; derivative details unverified |

**Attribution:** No RTD trademarks/copyrighted materials without permission; no endorsement.

**Limitations / unverified:** Broader than CTA; agreement reserves ownership and may revoke/change. Paid API resale scope needs confirmation before GREEN.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> rights to use, reproduce, and redistribute the Data

**Primary evidence:**

- [Source 1 — www.rtd-denver.com](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs)
- [Source 2 — www.rtd-denver.com](https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement)

## tomtom — TomTom Traffic

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global supported markets; flow/incidents/tiles. **Freshness / latency:** As frequently as 30 seconds in supported areas; not observation SLA.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** TomTom and underlying provider attribution; exact contract unverified.

**Limitations / unverified:** Monthly free: flow 20k, incidents 2.5k, tiles 200k. Current paid tariff not verified. Intermediate Traffic server feed does not itself grant redistribution.

**Primary evidence:**

- [Source 1 — docs.tomtom.com](https://docs.tomtom.com/pricing)
- [Source 2 — docs.tomtom.com](https://docs.tomtom.com/intermediate-traffic-service/documentation/introduction)
- [Source 3 — docs.tomtom.com](https://docs.tomtom.com/legal/terms-and-conditions)

## here — HERE Traffic v7

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED: standard terms.

**Coverage:** 70+ countries; flow and incidents. **Freshness / latency:** Flow 1 minute; incidents 2 minutes; 200ms response metric is not observation latency.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: licensed app |
| STORE | UNVERIFIED: retention contract |
| RESELL | PROHIBITED: standard non-sublicensable rights unless expressly permitted |
| DERIVE | CONDITIONAL: approved application derivation; warehouse not cleared |

**Attribution:** HERE and third-party notices.

**Limitations / unverified:** Base plan excluded use cases apply; obtain express distribution rights.

**Primary evidence:**

- [Source 1 — docs.here.com](https://docs.here.com/traffic-api/docs/real-time-traffic-here-traffic-api-v7-concepts)
- [Source 2 — legal.here.com](https://legal.here.com/us-en/terms/here-platform-terms)
- [Source 3 — www.here.com](https://www.here.com/get-started/pricing/rps-limits-excluded-use-cases)

## inrix — INRIX traffic / parking

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED: standard terms.

**Coverage:** Global contractual territories; traffic and parking products. **Freshness / latency:** Numeric cadence, observation lag and SLA UNVERIFIED.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: Order Form permitted use |
| STORE | CONDITIONAL: Order Form permitted use |
| RESELL | PROHIBITED: sublicense outside named End Users |
| DERIVE | PROHIBITED: derivatives unless expressly authorized |

**Attribution:** INRIX copyright/logo and underlying provider notices.

**Limitations / unverified:** Data combination restrictions; distinguish modeled parking probability from measured occupancy.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Licensee may sub-license the INRIX Products only to those End Users identified in the Order Form.

**Primary evidence:**

- [Source 1 — docs.inrix.com](https://docs.inrix.com/)
- [Source 2 — inrix.com](https://inrix.com/products/ai-traffic/)
- [Source 3 — inrix.com](https://inrix.com/wp-content/uploads/2023/08/INRIX-Standard-License-Terms-and-Conditions-v.8-General-2023.0807.pdf)

## parkopedia — Parkopedia

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** 90M spaces, 20k cities, 90 countries marketed. **Freshness / latency:** Dynamic occupancy cadence/US granularity and SLA UNVERIFIED.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** UNVERIFIED: contract.

**Limitations / unverified:** API/feed available; observed vs predicted occupancy must be labeled. Coverage totals do not mean realtime sensors everywhere.

**Primary evidence:**

- [Source 1 — business.parkopedia.com](https://business.parkopedia.com/home)
- [Source 2 — business.parkopedia.com](https://business.parkopedia.com/analytics)

## google_routes — Google Routes Pro

**Category:** mobility. **Checked:** 2026-10-07. **Our apps:** RED: OSM world overlay. **World State API:** RED.

**Coverage:** Global supported routing; traffic-aware ETA, not bulk traffic field. **Freshness / latency:** Request-time route; underlying traffic observation age UNVERIFIED.

**Monthly data cost at 1k / 100k / 1M users:** $250 / $13,150 / $37,900. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | PROHIBITED: mapped Routes results on OSM; Google Map required |
| STORE | RESTRICTED: limited exceptions; no general persistent cache |
| RESELL | PROHIBITED: independent raw resale |
| DERIVE | UNVERIFIED: independent traffic dataset not cleared |

**Attribution:** Google Maps and third-party notices; nonmap allowed with attribution.

**Limitations / unverified:** Costs baseline 30 calls/user/month and current graduated Pro tiers. Matrix bills elements. At 1800 calls/user/month: $9550/$150400/$1365400; polling routes not recommended.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Routes API results displayed on a map must be shown on a Google Map

**Primary evidence:**

- [Source 1 — developers.google.com](https://developers.google.com/maps/billing-and-pricing/pricing)
- [Source 2 — developers.google.com](https://developers.google.com/maps/documentation/routes/policies)
- [Source 3 — cloud.google.com](https://cloud.google.com/maps-platform/terms)

## opensky — OpenSky

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global receiver-dependent aircraft positions; uneven low-altitude coverage. **Freshness / latency:** Cadence/credits depend on entitlement; commercial latency SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** Commercial license attribution UNVERIFIED.

**Limitations / unverified:** Free research/personal access is not commercial operational permission.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> requires a written license from OpenSky Network.

**Primary evidence:**

- [Source 1 — opensky-network.org](https://opensky-network.org/about/terms-of-use)
- [Source 2 — opensky-network.org](https://opensky-network.org/about/faq)

## adsbx — ADS-B Exchange Enterprise

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global receiver-dependent ADS-B/MLAT. **Freshness / latency:** Community stream 500ms claim is not enterprise observation SLA.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** Contract UNVERIFIED.

**Limitations / unverified:** Annual minimum commitments; personal $10/10k community offer is not company production pricing.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> minimum annual commitments.

**Primary evidence:**

- [Source 1 — www.adsbexchange.com](https://www.adsbexchange.com/data-products/)
- [Source 2 — www.adsbexchange.com](https://www.adsbexchange.com/community/developer-hub/)

## flightaware — FlightAware AeroAPI

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN: Standard scope. **World State API:** RED: Standard raw API.

**Coverage:** 185+ countries; positions/status/gates; Premium space-based coverage. **Freshness / latency:** Position updates approximately minute-scale; endpoint/provider-dependent.

**Monthly data cost at 1k / 100k / 1M users:** $1,500 illustrative position-search batches / $150,000 illustrative position-search batches / $1,500,000 illustrative position-search batches. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: Standard embedded B2C application |
| STORE | CONDITIONAL: no longer than 30 days under Standard |
| RESELL | PROHIBITED: Standard raw B2B resale; negotiate Premium |
| DERIVE | CONDITIONAL: licensed derivatives; mixing restrictions |

**Attribution:** Contains AeroAPI data © FlightAware LLC [year].

**Limitations / unverified:** Illustration $0.05 per 15-record result batch, one batch per baseline request; not universal endpoint tariff. Mixing/backfill with other live providers requires written permission.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> for a period longer than thirty (30) days.

**Primary evidence:**

- [Source 1 — www.flightaware.com](https://www.flightaware.com/commercial/aeroapi/)
- [Source 2 — www.flightaware.com](https://www.flightaware.com/commercial/aeroapi/AeroAPI_Standard_License.pdf)

## awc — NOAA Aviation Weather Center

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Global airport METAR/TAF weather; not aircraft movement. **Freshness / latency:** METAR typically hourly; cached files 1 minute, TAF files 10 minutes; 100 requests/min.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA/NWS and observation origin.

**Limitations / unverified:** Cached file refresh does not mean every airport measured each minute; partner records separately audited.

**Primary evidence:**

- [Source 1 — aviationweather.gov](https://aviationweather.gov/data/api/)
- [Source 2 — www.weather.gov](https://www.weather.gov/disclaimer)

## faa — FAA NAS airport status

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** YELLOW.

**Coverage:** US ground stops/delays/closure summaries; no individual flight tracks. **Freshness / latency:** Summary page 5-minute updates; XML feed cadence/SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: explicit XML reuse |
| STORE | CONDITIONAL: federal-origin inference |
| RESELL | UNVERIFIED: third-party origin and commercial redistribution |
| DERIVE | CONDITIONAL: federal-origin inference |

**Attribution:** FAA; unofficial source and update time.

**Limitations / unverified:** Airport operational status is not individual airline schedule or movement data.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Our airport status information is available in XML format.

**Primary evidence:**

- [Source 1 — www.fly.faa.gov](https://www.fly.faa.gov/fly/FAQ/faq)
- [Source 2 — www.fly.faa.gov](https://www.fly.faa.gov/ois/oisedit/summary_pub)
- [Source 3 — www.faa.gov](https://www.faa.gov/web_policies/linking_policy)

## schiphol — Schiphol Airport Flight API

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** RED: generic WorldEngine. **World State API:** RED.

**Coverage:** Single airport arrival/departure schedule and status. **Freshness / latency:** Cadence/latency entitlement-dependent; unverified.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | PROHIBITED: generic ambient world use; traveler/pickup purpose only |
| STORE | CONDITIONAL: 24-hour retention |
| RESELL | PROHIBITED: distribution/sale/sharing |
| DERIVE | CONDITIONAL: cannot bypass purpose restriction |

**Attribution:** Airport contractual requirements.

**Limitations / unverified:** Airport ownership does not establish unrestricted feed rights. Portal migration in 2026; no signup performed.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> not allowed to distribute, sell or otherwise share data

**Primary evidence:**

- [Source 1 — developer.schiphol.nl](https://developer.schiphol.nl/apis/flight-api/conditions)

## airnow — AirNow

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** YELLOW.

**Coverage:** US and partner reporting-area AQI, observations and forecasts. **Freshness / latency:** Hourly reports typically 10–30 minutes after hour; reporting-area files twice/hour.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: agency AQI guidance |
| STORE | ALLOWED: bulk-file database |
| RESELL | UNVERIFIED: paid downstream API; agencies own inputs |
| DERIVE | CONDITIONAL: preserve official advisories and distinguish derived values |

**Attribution:** AirNow/EPA and contributing agencies; AQI colors; preliminary status.

**Limitations / unverified:** API caps not increased; bulk files preferred. Surface AQI is different from aloft smoke. Do not assume all partner data EPA-owned.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> should be disseminated as received.

**Primary evidence:**

- [Source 1 — docs.airnowapi.org](https://docs.airnowapi.org/faq)
- [Source 2 — docs.airnowapi.org](https://docs.airnowapi.org/account/request/)

## purpleair — PurpleAir

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global community PM sensors; uneven coverage. **Freshness / latency:** Near realtime; recommended bulk polling approximately minute-scale.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | UNVERIFIED: current license |
| STORE | CONDITIONAL: database storage guidance |
| RESELL | UNVERIFIED: rehosting concerns; obtain current contract |
| DERIVE | UNVERIFIED: commercial corrected/derived API scope |

**Attribution:** Current license/contract UNVERIFIED.

**Limitations / unverified:** Point costs and current $/point not verified; 2023 pricing is not a 2026 quote. Historical staff posts do not substitute for current license.

**Primary evidence:**

- [Source 1 — community.purpleair.com](https://community.purpleair.com/t/api-pricing/4523)
- [Source 2 — community.purpleair.com](https://community.purpleair.com/t/how-do-i-calculate-my-api-calls-point-cost/8736)
- [Source 3 — community.purpleair.com](https://community.purpleair.com/t/any-legal-issues-with-re-using-or-re-hosting-purple-air-data/1743)
- [Source 4 — www.purpleair.com](https://www.purpleair.com/license)

## hms — NOAA HMS smoke

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** North America analyst smoke extent; smoke can be aloft. **Freshness / latency:** Day analysis about 11–12 ET and 19–20 ET; not continuous PM measurement.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** NOAA HMS; analysis valid time.

**Limitations / unverified:** 2026 manual fire-verification retirement is separate from smoke product. Never convert smoke polygon into verified ground exposure.

**Primary evidence:**

- [Source 1 — www.ospo.noaa.gov](https://www.ospo.noaa.gov/products/land/hms.html)
- [Source 2 — www.ospo.noaa.gov](https://www.ospo.noaa.gov/data/messages/2026/03/MSG_20260312_1400.html)

## cams — Copernicus CAMS

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Global atmospheric composition; European AQ/pollen approximately 10km. **Freshness / latency:** Daily forecasts with hourly forecast steps; model latency not SLA.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: applicable product license |
| STORE | ALLOWED: applicable product license |
| RESELL | ALLOWED: CC BY/current product license |
| DERIVE | ALLOWED: attribution and changes |

**Attribution:** Copernicus/CAMS; product/version, license, modifications.

**Limitations / unverified:** Europe pollen is not global street-level pollen. Operational download account/key needed, none created. Inspect license attached to exact dataset.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> There is no restriction on use, reproduction and redistribution

**Primary evidence:**

- [Source 1 — ads.atmosphere.copernicus.eu](https://ads.atmosphere.copernicus.eu/datasets/cams-europe-air-quality-forecasts?tab=overview)
- [Source 2 — cds.climate.copernicus.eu](https://cds.climate.copernicus.eu/licences/licence-to-use-copernicus-products)

## google_pollen — Google Pollen

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW: OSM use audit. **World State API:** RED: raw API.

**Coverage:** 65+ countries; 1km; 3 types, 15 species; 5-day forecast. **Freshness / latency:** Daily forecast; modeled values not local sensors.

**Monthly data cost at 1k / 100k / 1M users:** $250 / $8,150 / $22,650. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: Google map/attribution policies; nonmap presentation possible |
| STORE | CONDITIONAL: today's data up to 365 days; future/heatmaps 24 hours |
| RESELL | PROHIBITED: independent raw resale under standard terms |
| DERIVE | ALLOWED: specified environmental indices/insights/forecasts with attribution |

**Attribution:** Google Maps / Source: Includes pollen data from Google; exact presentation per terms.

**Limitations / unverified:** Specific caching clauses override generic rules; do not generalize across Google SKUs. Derived permission does not clear a reconstructable raw feed.

**Primary evidence:**

- [Source 1 — developers.google.com](https://developers.google.com/maps/documentation/pollen/policies)
- [Source 2 — cloud.google.com](https://cloud.google.com/maps-platform/terms/maps-service-terms)
- [Source 3 — developers.google.com](https://developers.google.com/maps/billing-and-pricing/pricing)

## google_aq — Google Air Quality

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW: OSM use audit. **World State API:** RED: raw API.

**Coverage:** 100+ countries; 500m; current/history/forecast. **Freshness / latency:** Hourly modeled/current product; observation age varies.

**Monthly data cost at 1k / 100k / 1M users:** $100 / $4,050 / $11,300. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: map/attribution policies |
| STORE | CONDITIONAL: current/forecast 1 hour; historical until termination per service terms |
| RESELL | PROHIBITED: independent raw resale |
| DERIVE | ALLOWED: specified environmental indices/insights with attribution |

**Attribution:** Google Maps and required source notices.

**Limitations / unverified:** Read product-specific terms; modeled grid is not a sensor at every 500m cell.

**Primary evidence:**

- [Source 1 — developers.google.com](https://developers.google.com/maps/documentation/air-quality/reference/rest)
- [Source 2 — cloud.google.com](https://cloud.google.com/maps-platform/terms/maps-service-terms)
- [Source 3 — developers.google.com](https://developers.google.com/maps/billing-and-pricing/pricing)

## ambee — Ambee Pollen

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global land coverage; 30+ allergens; approximately 5km, finer by contract. **Freshness / latency:** Present hourly; forecast daily; history from 2015 marketed.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** Contract UNVERIFIED.

**Limitations / unverified:** Product claims verified as marketing; accuracy, SLA, independent retention and resale rights require contract.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Present conditions refresh hourly. Forecasts refresh daily.

**Primary evidence:**

- [Source 1 — www.getambee.com](https://www.getambee.com/api/pollen)
- [Source 2 — www.getambee.com](https://www.getambee.com/pricing)
- [Source 3 — www.getambee.com](https://www.getambee.com/terms-and-conditions)

## uv — EPA Envirofacts UV

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** US city/ZIP UV forecasts. **Freshness / latency:** Hourly/daily forecast products; publication cadence/SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: identified agency-produced data |
| STORE | ALLOWED: identified agency-produced data |
| RESELL | ALLOWED: identified agency-produced data; check worldwide CC0 metadata |
| DERIVE | ALLOWED: label modifications |

**Attribution:** EPA; forecast date and location.

**Limitations / unverified:** Federal-origin subset only; forecast not measured street-level UV or canopy exposure.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> all data produced by the U.S EPA is by default in the public domain

**Primary evidence:**

- [Source 1 — www.epa.gov](https://www.epa.gov/enviro/web-services)
- [Source 2 — pasteur.epa.gov](https://pasteur.epa.gov/license/sciencehub-license-non-epa-generated.html)

## celestrak — CelesTrak GP / SupGP

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Global tracked satellite orbital elements. **Freshness / latency:** GP generally 2 hours; SupGP varies; respect two-hour retrieval policy.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | UNVERIFIED: commercial operational grant |
| STORE | CONDITIONAL: retrieval/cache policy; long-term rights unverified |
| RESELL | UNVERIFIED: commercial downstream redistribution |
| DERIVE | UNVERIFIED: paid derived ephemeris grant |

**Attribution:** CelesTrak and element source; requested time and element epoch.

**Limitations / unverified:** Elements are not measured realtime positions. Propagate with SGP4; use OMM/JSON/CSV for larger catalog IDs. Public access is not an explicit resale license.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Only download the data you need

**Primary evidence:**

- [Source 1 — www.celestrak.org](https://www.celestrak.org/usage-policy.php)
- [Source 2 — celestrak.org](https://celestrak.org/NORAD/documentation/gp-data-formats.php)
- [Source 3 — www.celestrak.org](https://www.celestrak.org/software/tutorials/sgp4.php)

## blackmarble — NASA Black Marble

**Category:** air_sky. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Global approximately 500m nighttime lights. **Freshness / latency:** Daily corrected composites plus monthly/yearly products; not live windows.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: NASA-produced dataset; metadata exceptions |
| STORE | ALLOWED: NASA-produced dataset |
| RESELL | ALLOWED: NASA-produced dataset / CC0 metadata |
| DERIVE | ALLOWED: NASA-produced dataset |

**Attribution:** NASA/Black Marble; DOI, version and date.

**Limitations / unverified:** NASA hosting does not clear third-party data. Use as baseline sky glow/light pollution proxy, not realtime electrical activity.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> There are no restrictions on the usage of these data.

**Primary evidence:**

- [Source 1 — science.data.nasa.gov](https://science.data.nasa.gov/about/license)
- [Source 2 — science.gsfc.nasa.gov](https://science.gsfc.nasa.gov/earth/terrestrialinfo/projects/586/)
- [Source 3 — data.nasa.gov](https://data.nasa.gov/dataset/viirs-npp-daily-gridded-day-night-band-500m-linear-lat-lon-grid-night)

## ticketmaster — Ticketmaster Discovery API

**Category:** events. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED: standard resale.

**Coverage:** 230k+ international music/sports and other events. **Freshness / latency:** No verified freshness SLA; documented 5k/day; conflicting 5 vs 2 RPS guidance.

**Monthly data cost at 1k / 100k / 1M users:** $0 within 5k/day; commercial approval unresolved / Partner quote / quota increase / Partner quote / quota increase. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: application terms and commercial approval |
| STORE | CONDITIONAL: reasonable service period; removal within 24h |
| RESELL | PROHIBITED: standard sale/sublicense restrictions |
| DERIVE | UNVERIFIED: commercial crowd derivative rights |

**Attribution:** Purchase URLs and branding requirements; general attribution not conclusively verified.

**Limitations / unverified:** 30k/month can fit daily quota only if distributed; 100k/1M user baseline exceeds it. Deep paging capped at 1000; event schedule is not observed attendance.

**Primary evidence:**

- [Source 1 — developer.ticketmaster.com](https://developer.ticketmaster.com/products-and-docs/apis/discovery/v2/)
- [Source 2 — developer.ticketmaster.com](https://developer.ticketmaster.com/support/faq/)
- [Source 3 — developer.ticketmaster.com](https://developer.ticketmaster.com/support/terms-of-use/)

## ticketmaster_feed — Ticketmaster Discovery Feed

**Category:** events. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED: standard resale.

**Coverage:** Country event CSV/JSON feeds. **Freshness / latency:** Hourly per FAQ; approved-partner access requirements ambiguous publicly.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: approved partner |
| STORE | CONDITIONAL: licensed indexing and retention |
| RESELL | PROHIBITED: standard resale absent separate grant |
| DERIVE | UNVERIFIED: crowd/API derivative grant |

**Attribution:** Contract and purchase links.

**Limitations / unverified:** Public feed documentation does not itself clear partner eligibility or downstream distribution.

**Primary evidence:**

- [Source 1 — www.developer.ticketmaster.com](https://www.developer.ticketmaster.com/products-and-docs/apis/discovery-feed/)
- [Source 2 — developer.ticketmaster.com](https://developer.ticketmaster.com/support/faq/)
- [Source 3 — developer.ticketmaster.com](https://developer.ticketmaster.com/support/terms-of-use/)

## seatgeek — SeatGeek API

**Category:** events. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED.

**Coverage:** Ticketed event inventory; exact global boundaries unverified. **Freshness / latency:** Cadence, quota and SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: approved application and linked logo |
| STORE | PROHIBITED: systematic permanent storage |
| RESELL | PROHIBITED: third-party service access |
| DERIVE | RESTRICTED: AI/ML forbidden; other derivatives unverified |

**Attribution:** Linked SeatGeek logo.

**Limitations / unverified:** March 17 2025 terms; no unofficial marketplace price used.

**Primary evidence:**

- [Source 1 — seatgeek.com](https://seatgeek.com/api-terms)
- [Source 2 — support.seatgeek.com](https://support.seatgeek.com/hc/en-us/articles/4409765051283-Can-I-Use-SeatGeek-Data-or-an-API)
- [Source 3 — portal.seatgeek.com](https://portal.seatgeek.com/)

## predicthq — PredictHQ

**Category:** events. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** RED: standard raw API.

**Coverage:** Global events across 19 categories; attendance predictions. **Freshness / latency:** Marketed near realtime; daily sync recommended, more frequent unscheduled changes; no numeric SLA.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: Order Form permitted app |
| STORE | CONDITIONAL: written retention agreement |
| RESELL | PROHIBITED: standard raw redistribution absent Order Form grant |
| DERIVE | CONDITIONAL: approved Data Enrichment and AI permissions |

**Attribution:** UNVERIFIED: contract.

**Limitations / unverified:** Predicted attendance is not measured crowd. Delete/sync behavior and historical retention must be negotiated.

**Primary evidence:**

- [Source 1 — www.predicthq.com](https://www.predicthq.com/pricing)
- [Source 2 — www.predicthq.com](https://www.predicthq.com/legal/terms)
- [Source 3 — docs.predicthq.com](https://docs.predicthq.com/integrations/integration-guides/keep-data-updated-via-api)

## mlb — MLB Stats API

**Category:** events. **Checked:** 2026-10-07. **Our apps:** RED. **World State API:** RED.

**Coverage:** MLB schedules and game data. **Freshness / latency:** Public endpoint availability is not a commercial SLA or license.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | PROHIBITED: public terms individual noncommercial only |
| STORE | PROHIBITED: bulk commercial use |
| RESELL | PROHIBITED: commercial redistribution |
| DERIVE | PROHIBITED: commercial derivatives under reviewed public grant |

**Attribution:** Commercial license requirements unverified.

**Limitations / unverified:** Negotiate official commercial feed; do not infer open rights from callable endpoints.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> Only individual, non-commercial, non-bulk use of the Materials

**Primary evidence:**

- [Source 1 — gdx.mlb.com](https://gdx.mlb.com/components/copyright.txt)

## nyc_events — NYC permitted events

**Category:** events. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Forthcoming permitted street and park events. **Freshness / latency:** Historically daily next-month dataset; current cadence unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: public nonpersonal city data |
| STORE | ALLOWED: public nonpersonal city data |
| RESELL | ALLOWED: city open-data scope; third-party exceptions |
| DERIVE | ALLOWED: distinguish planned event from crowd |

**Attribution:** NYC source, dataset and retrieval date.

**Limitations / unverified:** Permits omit unofficial/unpermitted gatherings; cancellations and coverage gaps must be handled.

**Primary evidence:**

- [Source 1 — dev.socrata.com](https://dev.socrata.com/foundry/data.cityofnewyork.us/tvpp-9vvx)
- [Source 2 — data.cityofnewyork.us](https://data.cityofnewyork.us/stories/s/Terms-of-Use/k9k7-3cje)
- [Source 3 — www.nyc.gov](https://www.nyc.gov/opendata/get-started/FAQs)

## seattle_events — Seattle city calendar

**Category:** events. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Moderated events within approximately 30 miles. **Freshness / latency:** Moderation three times weekly; weekend lag; no accuracy guarantee.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** City/source event credit; actual license unverified.

**Limitations / unverified:** Public webpage viewing is free, but automated ingestion/store/resale not conclusively granted.

**Primary evidence:**

- [Source 1 — www.seattle.gov](https://www.seattle.gov/event-calendar)
- [Source 2 — www.seattle.gov](https://www.seattle.gov/event-calendar/policy-and-disclaimer)

## uk_holidays — GOV.UK bank holidays

**Category:** events. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** UK nations; JSON and ICS. **Freshness / latency:** As announced; schedule baseline, not live crowds.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: OGL scope |
| STORE | ALLOWED: OGL scope |
| RESELL | ALLOWED: OGL commercial reuse |
| DERIVE | ALLOWED: OGL attribution |

**Attribution:** Source and Open Government Licence; no endorsement.

**Limitations / unverified:** Exclude restricted third-party content. Useful global schema exemplar, not US event coverage.

**Primary evidence:**

- [Source 1 — www.api.gov.uk](https://www.api.gov.uk/gds/bank-holidays/)
- [Source 2 — www.gov.uk](https://www.gov.uk/help/terms-conditions)
- [Source 3 — www.nationalarchives.gov.uk](https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/open-government-licence/)

## wzdx — USDOT WZDx / Connected Work Zones registry

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Multiple US jurisdictions; not all roads or all states. **Freshness / latency:** Publisher-specific; versions/schema evolve; no nationwide freshness SLA.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | UNVERIFIED: each feed license; spec is CC0 |
| STORE | UNVERIFIED: each feed license |
| RESELL | UNVERIFIED: each feed license |
| DERIVE | UNVERIFIED: each feed license |

**Attribution:** Publisher-specific; specification credit optional.

**Limitations / unverified:** FeedInfo license URL must gate ingestion. CC0 project/schema license does not license every published road-work record.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> The WZDx project is in the worldwide public domain

**Primary evidence:**

- [Source 1 — data.transportation.gov](https://data.transportation.gov/stories/s/Work-Zone-Data-Initiative-Partnership/jixs-h7uw/)
- [Source 2 — github.com](https://github.com/usdot-jpo-ode/wzdx)

## 511mtc — 511 MTC

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** GREEN: agreement scope. **World State API:** RED: raw standalone / YELLOW: transformed.

**Coverage:** San Francisco Bay Area highway incidents/closures and local work zones. **Freshness / latency:** 60 requests/hour/key; increases on request; publication latency unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: registered agreement |
| STORE | ALLOWED: agreement caching |
| RESELL | PROHIBITED: standalone as-received sale without written agreement |
| DERIVE | CONDITIONAL: transformed uses; sublicense agreement requirements |

**Attribution:** powered by 511.org or data provided by 511.org, linked near data.

**Limitations / unverified:** Approved shared quota needed. Current linked agreement retrieved 2026-10-07, not assumed to be a 2026-issued contract.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> The Provided Data shall not be sold as received on a standalone basis without the prior written agreement of MTC.

**Primary evidence:**

- [Source 1 — 511.org](https://511.org/open-data/token)
- [Source 2 — 511.org](https://511.org/sites/default/files/pdfs/511_Data_Agreement_Final.pdf)

## caltrans — Caltrans CWWP2

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** California 12 highway districts; lane/chain controls, signs and weather. **Freshness / latency:** QuickMap displays mostly 1 minute, some 5/10 minutes; feed SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: indicated public-domain records |
| STORE | ALLOWED: indicated public-domain records |
| RESELL | ALLOWED: indicated public-domain records |
| DERIVE | ALLOWED: indicated public-domain records |

**Attribution:** Caltrans; source and time; no endorsement.

**Limitations / unverified:** GREEN only selected tabular records; photographs/CCTV and third-party inputs not automatically cleared.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> information presented on this website, unless otherwise indicated, is considered in the public domain.

**Primary evidence:**

- [Source 1 — cwwp2.dot.ca.gov](https://cwwp2.dot.ca.gov/)
- [Source 2 — dot.ca.gov](https://dot.ca.gov/conditions-of-use)
- [Source 3 — quickmap.dot.ca.gov](https://quickmap.dot.ca.gov/trafficMapFaqMobile.html)

## cotrip — COtrip / CDOT

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Colorado highway conditions, closures and incidents. **Freshness / latency:** Catalog expected 15 minutes; actual endpoints/provider lag unverified.

**Monthly data cost at 1k / 100k / 1M users:** UNVERIFIED / quote / UNVERIFIED / quote / UNVERIFIED / quote. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: contracted application |
| STORE | UNVERIFIED: retention contract |
| RESELL | UNVERIFIED: explicit downstream redistribution grant required |
| DERIVE | UNVERIFIED: derivative output grant required |

**Attribution:** UNVERIFIED: developer agreement.

**Limitations / unverified:** Public API portal exists; client-rendered current agreement not verified. Do not infer all third-party traffic rights or zero commercial fee.

**Primary evidence:**

- [Source 1 — manage-api.cotrip.org](https://manage-api.cotrip.org/)
- [Source 2 — data.colorado.gov](https://data.colorado.gov/Transportation/CDOT-Real-Time-Data-Feed-XML-/j3ch-zsvz/about_data)
- [Source 3 — maps.cotrip.org](https://maps.cotrip.org/help/section/for-developers.html)

## chicago_permits — Chicago CDOT permits

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** YELLOW. **World State API:** YELLOW.

**Coverage:** Chicago authorized transportation work, current/future permits. **Freshness / latency:** Cadence and publication SLA unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | CONDITIONAL: public portal display |
| STORE | CONDITIONAL: public portal analysis |
| RESELL | UNVERIFIED: applicable commercial grant |
| DERIVE | UNVERIFIED: commercial derivative grant |

**Attribution:** Chicago CDOT; permit and issue date.

**Limitations / unverified:** Authorization is not proof of active closure or construction. Do not generalize special terms of unrelated police datasets.

**Primary evidence:**

- [Source 1 — data.cityofchicago.org](https://data.cityofchicago.org/Transportation/Transportation-Department-Permits/pubx-yq2d)
- [Source 2 — chicago.github.io](https://chicago.github.io/dev.cityofchicago.org/open%20data/data%20portal/2015/11/11/new-department-of-transportation-permits-dataset.html)

## denver_permits — Denver residential construction permits

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** Denver residential permits. **Freshness / latency:** Cadence/latency metadata unverified.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: catalog CC BY 3.0 scope |
| STORE | ALLOWED: catalog CC BY 3.0 scope |
| RESELL | ALLOWED: catalog CC BY 3.0 scope |
| DERIVE | ALLOWED: attribute changes |

**Attribution:** City of Denver Open Data Catalog; CC BY 3.0; modifications.

**Limitations / unverified:** Verify license follows selected dataset/version. Omit contact names and unnecessary contractor/personal fields; permit is not live activity.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> You are free to copy, distribute, transmit and adapt the data

**Primary evidence:**

- [Source 1 — opendata-geospatialdenver.hub.arcgis.com](https://opendata-geospatialdenver.hub.arcgis.com/)
- [Source 2 — opendata-geospatialdenver.hub.arcgis.com](https://opendata-geospatialdenver.hub.arcgis.com/datasets/geospatialDenver::residential-construction-permits/explore)

## nyc_permits — NYC DOT construction permits

**Category:** civic. **Checked:** 2026-10-07. **Our apps:** GREEN. **World State API:** GREEN.

**Coverage:** NYC street construction permits 2022–present. **Freshness / latency:** Daily automated metadata; last seen update September 18 2026, freshness check required.

**Monthly data cost at 1k / 100k / 1M users:** $0 data fee; shared ingestion / $0 data fee; shared ingestion / $0 data fee; shared ingestion. See baseline and shared-ingestion caveats in README.

| Right | Finding |
|---|---|
| DISPLAY | ALLOWED: city open-data scope |
| STORE | ALLOWED: city open-data scope |
| RESELL | ALLOWED: city open-data scope; exceptions checked |
| DERIVE | ALLOWED: nonpersonal factual outputs |

**Attribution:** NYC DOT; dataset, permit dates and retrieval date.

**Limitations / unverified:** Avoid PII; scheduled permit validity is not confirmation crews are on site. Older last update despite daily metadata must be surfaced.

**Short source excerpt** (linked primary evidence below; not the complete grant):

> data sets must be available without registration requirement, license requirement, or usage restrictions

**Primary evidence:**

- [Source 1 — data.cityofnewyork.us](https://data.cityofnewyork.us/Transportation/Street-Construction-Permits-2022-Present-/tqtj-sjs8)
- [Source 2 — cityofnewyork.github.io](https://cityofnewyork.github.io/opendatatsm/publicpolicies.html)
