# WorldEngine transit-feed research

Research date: 2026-10-06 (America/Denver). Scope: all 32 requested entries; MTA NYC Transit, LIRR and Metro-North are separate rows.

## Reading the CSV

The CSV is UTF-8, with one header and 32 agency rows. Each factual field cites its supporting official URL in square brackets. An endpoint inside a field is not automatically a licence source; the bracketed URL identifies its evidence. Abbreviations: TU = trip updates; VP = vehicle positions. Where several filenames share a URL directory, the full directory is provided.

**unclear** means the reviewed official sources did not establish the answer, or access prevented verification. It does not mean the agency has no feed, no rate limit, or prohibits use. A working unauthenticated download alone does not establish permission to redistribute. A grant to use data is not treated as an express commercial-use declaration unless the source addresses that use. Licence scope may differ between static GTFS, realtime APIs, and branding.

This is documentation research with selected direct download checks, not an end-to-end integration test. No developer accounts were registered, keys requested, or agencies contacted. Published shared keys are referenced through agency resource pages; private credentials are not included. Only these two requested deliverables were saved; no Git operations were performed.

## Shared Swiftly conditions

LA Metro, Miami-Dade Transit and MTA Maryland direct developers to an agency-specific [Swiftly access request](https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform). Approval is not guaranteed.

The [Swiftly API agreement](https://www.goswift.ly/api-license-agreement) permits integration/display within an application but restricts standalone API distribution, content transfer/resale, and incremental charges for the content or integration. Preserve proprietary notices and pass the relevant obligations to app users. Call limits refer to developer documentation; a public numeric quota and cache TTL were not established. WorldEngine's proposed redistribution model requires clarification against these restrictions. Static agency feeds and Maryland's open MARC/alert feeds need their own applicable terms.

## Open questions and source conflicts

- **MTA:** [Realtime portal](https://api.mta.info/) states accounts and keys are no longer required for its subway/rail feeds; [Bus Time](https://bustime-classic.mta.info/wiki/Developers/Index) separately requires a key. The portal's current public text was verified in its served JavaScript, despite retained older key-related code. Do not apply the rail policy to buses.
- **LA Metro:** [Swiftly documentation](https://developer.metro.net/api/) and the separate [Metro API site](https://api.metro.net/) coexist. Use the agency-specific access documentation for the selected feed; terms for the other API should not be assumed identical. The [static page](https://developer.metro.net/gtfs-schedule-data/) recommends the bus weekly-updated-service branch; the table supplies its published master download.
- **DART:** [Official announcement](https://www.dart.org/about/news-and-events/newsreleases/newsrelease-detail/dart-begins-sharing-gtfs-realtime-feed-to-google-and-transit-apps) establishes GTFS-RT sharing with partner apps, but does not establish a public developer URL, key policy or licence.
- **Trinity Metro:** The [published static feed](https://ridetrinitymetro.org/gtfs-data/) timed out during retrieval. Its publication is confirmed; current download availability is unclear. Bicycle GBFS is not used as evidence of transit GTFS-RT.
- **WMATA:** [Portal](https://developer.wmata.com/) identifies a combined bus/rail static API. Its dynamic operation documentation did not expose a precise download URL or numerical quota in the accessible text.
- **SEPTA:** [API catalogue](https://app.septa.org/) documents realtime feeds; the [developer licence](https://www3.septa.org/developer/) describes trip-planning data. Realtime licence coverage needs clarification.
- **MARTA:** The [rail EULA](https://itsmarta.com/developer-reg-rtt.aspx) permits transfer with recipient acceptance and notice to MARTA. Do not assume it also covers the separately published bus GTFS-RT or static GTFS.
- **Broward:** [Official planning report](https://www.broward.org/BCT/Documents/BCT_2024-2033_TDPAnnualUpdate.pdf) mentions GTFS; public developer access/terms remain unclear. The legacy [ZIP candidate](https://www.broward.org/bct/documents/google_transit.zip) returned HTML, so it is not listed as a confirmed feed.
- **Phoenix:** [Realtime dataset](https://www.phoenixopendata.com/dataset/general-transit-feed-specification) describes buses and labels its licence Creative Commons Attribution. The linked [licence-family page](http://www.opendefinition.org/licenses/cc-by) lists multiple versions; a specific RT version is unclear. The static [ODC link](http://www.opendefinition.org/licenses/odc-by) points to ODC-BY 1.0. Rail coverage is unclear.
- **Metrolink:** [Access page](https://metrolinktrains.com/about/gtfs/gtfs-rt-access/) specifically describes alerts as keyless but also contains broader all-request/each-user key wording. Server-side versus end-user key handling needs clarification. The mentioned Creative Commons licence covers the GTFS-RT specification, not necessarily Metrolink's data.
- **DDOT, SMART, QLine:** [DDOT](https://detroitmi.gov/departments/detroit-department-transportation), [SMART](https://www.smartbus.org/) and [QLine](https://www.qlinedetroit.com/) rider information does not establish a public developer API or reuse licence. DDOT's legacy official static ZIP was retrieved, but schedule currency was not established.
- **Sound Transit:** [OTD downloads](https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/otd-downloads) announces consolidated GTFS retirement at the end of 2026. OBA agency 40 realtime covers 1/2/T Lines and ST Express; Sounder vehicle/trip realtime is unclear there. Rail alerts include N/S Lines. Direct King County data has its separate agency terms.
- **MTS:** The [general developer page](https://www.sdmts.com/business-center/app-developers) says realtime is forthcoming, while its [dedicated realtime page](https://www.sdmts.com/business-center/app-developers/real-time-data) supplies active endpoints and a key request. The table follows the dedicated page and records the conflict.
- **NCTD/HART:** [NCTD vendor report](https://lfportal.nctd.org/WebLink/0/doc/220158/Page1.aspx) and [HART rider tracking](https://www.gohart.org/Pages/maps-real-time.aspx) do not establish public developer entitlement. Hosting/provider identification alone is insufficient to infer access.
- **PSTA:** The [legacy API page](https://www.psta.net/developers/ridepsta_API.php) and [legacy static ZIP](https://www.psta.net/latest/Google_transit.zip) returned agency missing-page HTML. Current feed URLs, access and licence remain unclear.
- **Metra:** [Developers](https://metra.com/developers), [GTFS/API page](https://metra.com/metra-gtfs-api) and [key/licence request](https://metra.com/gtfs-realtime-api-key-request-license-agreement) returned 403. The [GTFS portal](https://gtfspublic.metrarr.com/) redirected to sign-in. Feed format, key issuance, current download URL and terms could not be verified.
- **Rate limits:** Refresh intervals are not request quotas. Only documented numerical quotas are recorded. Unknown limits are not interpreted as unlimited access.
- **Attribution:** Where the licence requires acknowledgement without fixed wording, the CSV describes that duty and marks the exact phrase unclear. Logos and other brand assets may have separate restrictions.

## MTA subway endpoint list

These endpoints are published in the [official realtime portal](https://api.mta.info/). They use the base URL `https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/`:

| Lines | Path |
| --- | --- |
| A/C/E | `nyct%2Fgtfs-ace` |
| B/D/F/M | `nyct%2Fgtfs-bdfm` |
| G | `nyct%2Fgtfs-g` |
| J/Z | `nyct%2Fgtfs-jz` |
| N/Q/R/W | `nyct%2Fgtfs-nqrw` |
| L | `nyct%2Fgtfs-l` |
| Numbered lines / shuttle group shown in portal | `nyct%2Fgtfs` |
| Staten Island Railway | `nyct%2Fgtfs-si` |

## Agency source index

The following are the official evidence URLs cited by each CSV row. Agency-linked hosting services and their own agreements count as primary sources; no third-party feed directories were used as evidence.


### MTA — NYC Transit

- [https://bustime-classic.mta.info/wiki/Developers/GTFSRt](https://bustime-classic.mta.info/wiki/Developers/GTFSRt)
- [https://api.mta.info/](https://api.mta.info/)
- [https://bustime-classic.mta.info/wiki/Developers/Index](https://bustime-classic.mta.info/wiki/Developers/Index)
- [https://www.mta.info/developers](https://www.mta.info/developers)
- [https://www.mta.info/developers/terms-and-conditions](https://www.mta.info/developers/terms-and-conditions)

### MTA — LIRR

- [https://api.mta.info/](https://api.mta.info/)
- [https://www.mta.info/developers](https://www.mta.info/developers)
- [https://www.mta.info/developers/terms-and-conditions](https://www.mta.info/developers/terms-and-conditions)

### MTA — Metro-North

- [https://api.mta.info/](https://api.mta.info/)
- [https://www.mta.info/developers](https://www.mta.info/developers)
- [https://www.mta.info/developers/terms-and-conditions](https://www.mta.info/developers/terms-and-conditions)

### LA Metro

- [https://developer.metro.net/api/](https://developer.metro.net/api/)
- [https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform](https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform)
- [https://www.goswift.ly/api-license-agreement](https://www.goswift.ly/api-license-agreement)
- [https://developer.metro.net/gtfs-schedule-data/](https://developer.metro.net/gtfs-schedule-data/)
- [https://developer.metro.net/terms-conditions/](https://developer.metro.net/terms-conditions/)

### DART

- [https://www.dart.org/about/news-and-events/newsreleases/newsrelease-detail/dart-begins-sharing-gtfs-realtime-feed-to-google-and-transit-apps](https://www.dart.org/about/news-and-events/newsreleases/newsrelease-detail/dart-begins-sharing-gtfs-realtime-feed-to-google-and-transit-apps)
- [https://www.dart.org/transitdata/latest/google_transit.zip](https://www.dart.org/transitdata/latest/google_transit.zip)

### Trinity Metro

- [https://ridetrinitymetro.org/gtfs-data/](https://ridetrinitymetro.org/gtfs-data/)

### METRO Houston

- [https://api-portal.ridemetro.org/](https://api-portal.ridemetro.org/)
- [https://www.ridemetro.org/about/business-to-business/developer-portal](https://www.ridemetro.org/about/business-to-business/developer-portal)

### WMATA

- [https://www.wmata.com/about/developers.html](https://www.wmata.com/about/developers.html)
- [https://developer.wmata.com/license](https://developer.wmata.com/license)
- [https://developer.wmata.com/](https://developer.wmata.com/)

### SEPTA

- [https://app.septa.org/](https://app.septa.org/)
- [https://www3.septa.org/developer/](https://www3.septa.org/developer/)

### MARTA

- [https://itsmarta.com/app-developer-resources.aspx](https://itsmarta.com/app-developer-resources.aspx)
- [https://itsmarta.com/developer-reg-rtt.aspx](https://itsmarta.com/developer-reg-rtt.aspx)

### Miami-Dade Transit

- [https://www.miamidade.gov/global/transportation/open-data-feeds.page](https://www.miamidade.gov/global/transportation/open-data-feeds.page)
- [https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform](https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform)
- [https://www.goswift.ly/api-license-agreement](https://www.goswift.ly/api-license-agreement)

### Broward County Transit

- [https://www.broward.org/BCT/Documents/BCT_2024-2033_TDPAnnualUpdate.pdf](https://www.broward.org/BCT/Documents/BCT_2024-2033_TDPAnnualUpdate.pdf)

### Tri-Rail

- [https://gtfsr.tri-rail.com/](https://gtfsr.tri-rail.com/)
- [https://gtfs.tri-rail.com/gtfs.zip](https://gtfs.tri-rail.com/gtfs.zip)

### Valley Metro (Phoenix)

- [https://www.phoenixopendata.com/dataset/general-transit-feed-specification](https://www.phoenixopendata.com/dataset/general-transit-feed-specification)
- [https://www.phoenixopendata.com/dataset/valley-metro-bus-schedule](https://www.phoenixopendata.com/dataset/valley-metro-bus-schedule)
- [http://www.opendefinition.org/licenses/odc-by](http://www.opendefinition.org/licenses/odc-by)
- [https://opendatacommons.org/licenses/by/1-0/](https://opendatacommons.org/licenses/by/1-0/)

### MBTA

- [https://github.com/mbta/gtfs-documentation/blob/master/reference/gtfs-realtime.md](https://github.com/mbta/gtfs-documentation/blob/master/reference/gtfs-realtime.md)
- [https://www.mbta.com/developers/v3-api](https://www.mbta.com/developers/v3-api)
- [https://www.mass.gov/doc/massdot-developers-relationship-principles-11132009/download](https://www.mass.gov/doc/massdot-developers-relationship-principles-11132009/download)
- [https://cdn.mbta.com/sites/default/files/2023-08/mbta-massdot-develop-license-agreement.pdf](https://cdn.mbta.com/sites/default/files/2023-08/mbta-massdot-develop-license-agreement.pdf)
- [https://www.mbta.com/developers/gtfs](https://www.mbta.com/developers/gtfs)

### RTA (Riverside)

- [https://www.riversidetransit.com/index.php/riding-the-bus/buswatch-transit-apps](https://www.riversidetransit.com/index.php/riding-the-bus/buswatch-transit-apps)
- [https://www.riversidetransit.com/google_transit.zip](https://www.riversidetransit.com/google_transit.zip)

### Omnitrans

- [https://www.omnitrans.org/google/gis/gis-files-download.html](https://www.omnitrans.org/google/gis/gis-files-download.html)

### Metrolink

- [https://metrolinktrains.com/about/gtfs/gtfs-rt-access/](https://metrolinktrains.com/about/gtfs/gtfs-rt-access/)
- [https://metrolinktrains.com/about/gtfs/](https://metrolinktrains.com/about/gtfs/)

### BART

- [https://www.bart.gov/schedules/developers/gtfs-realtime](https://www.bart.gov/schedules/developers/gtfs-realtime)
- [https://www.bart.gov/schedules/developers/api](https://www.bart.gov/schedules/developers/api)
- [https://www.bart.gov/schedules/developers/developer-license-agreement](https://www.bart.gov/schedules/developers/developer-license-agreement)
- [https://www.bart.gov/dev/schedules/google_transit.zip](https://www.bart.gov/dev/schedules/google_transit.zip)

### SFMTA Muni / 511 SF Bay

- [https://511.org/open-data/transit](https://511.org/open-data/transit)
- [https://511.org/open-data/token](https://511.org/open-data/token)
- [https://511.org/sites/default/files/pdfs/511_Data_Agreement_Final.pdf](https://511.org/sites/default/files/pdfs/511_Data_Agreement_Final.pdf)
- [https://511.org/open-data](https://511.org/open-data)

### DDOT

- [https://www.detroitmi.gov/Portals/0/docs/deptoftransportation/pdfs/ddot_gtfs.zip](https://www.detroitmi.gov/Portals/0/docs/deptoftransportation/pdfs/ddot_gtfs.zip)

### SMART (Detroit)

- [https://apps1.smartbus.org/gtfs/smart_gtfs.zip](https://apps1.smartbus.org/gtfs/smart_gtfs.zip)

### QLine

- [https://www.qlinedetroit.com/](https://www.qlinedetroit.com/)

### King County Metro

- [https://kingcounty.gov/en/dept/metro/rider-tools/mobile-and-web-apps](https://kingcounty.gov/en/dept/metro/rider-tools/mobile-and-web-apps)
- [https://metro.kingcounty.gov/gtfs/](https://metro.kingcounty.gov/gtfs/)

### Sound Transit

- [https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/otd-downloads](https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/otd-downloads)
- [https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/transit-data-terms-use](https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/transit-data-terms-use)

### Metro Transit (Minneapolis)

- [https://svc.metrotransit.org/](https://svc.metrotransit.org/)

### MTS (San Diego)

- [https://www.sdmts.com/business-center/app-developers/real-time-data](https://www.sdmts.com/business-center/app-developers/real-time-data)
- [https://www.sdmts.com/business-center/app-developers/terms-and-conditions](https://www.sdmts.com/business-center/app-developers/terms-and-conditions)
- [https://www.sdmts.com/business-center/app-developers](https://www.sdmts.com/business-center/app-developers)

### NCTD

- [https://lfportal.nctd.org/WebLink/0/doc/220158/Page1.aspx](https://lfportal.nctd.org/WebLink/0/doc/220158/Page1.aspx)
- [https://www.gonctd.com/google_transit.zip](https://www.gonctd.com/google_transit.zip)

### HART

- [https://www.gohart.org/google/google_transit.zip](https://www.gohart.org/google/google_transit.zip)
- [https://www.gohart.org/Pages/maps-real-time.aspx](https://www.gohart.org/Pages/maps-real-time.aspx)

### PSTA

- [https://www.psta.net/developers/ridepsta_API.php](https://www.psta.net/developers/ridepsta_API.php)

### MTA Maryland

- [https://www.mta.maryland.gov/developer-resources](https://www.mta.maryland.gov/developer-resources)
- [https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform](https://docs.google.com/forms/d/e/1FAIpQLScy9Jye91QPSTS3WVEU-13es0A1rT9Ep5JhAmXUZEiop7fmIw/viewform)
- [https://www.goswift.ly/api-license-agreement](https://www.goswift.ly/api-license-agreement)

### Metra

- [https://metra.com/developers](https://metra.com/developers)
