# Weather alerts (NWS): `worldengine.live.alerts/1`

Official National Weather Service alerts in force for the live-world areas (Chicago, Denver, Miami), passed through
unaltered. Code: `Tools/livefeeds/livefeeds/alerts/nws.py`; areas: `Tools/livefeeds/data/alerts-areas.json` (data);
tests: `Tools/livefeeds/tests/test_alerts.py`. Built by P1 on 2026-10-07 from L1's plan
(`docs/handoff/l1-live-world.md`, session 5).

```
python3 -m livefeeds alerts [--areas chicago,denver,miami] [--cache DIR] [--time ISO] [--offline] [--pretty]
```

## Rules

- **Official and unaltered.** `event`, `severity`, `certainty`, `urgency`, `headline`, `description`, `instruction`,
  `senderName`, `areaDesc`, `response`, `category` are the NWS values verbatim. Nothing is summarised, shortened,
  translated or re-ranked; a renderer may lay the text out but must not change it. Every alert carries
  `label` ("Official weather alert (National Weather Service)"), `source: "nws"`, `basis: "observed"`,
  `official: true` and `link` (the alert's official `@id` URL on api.weather.gov).
- **Never shown as active when it is not.** An alert is emitted only while in force at the snapshot instant:
  `status` is `Actual` (no Test, Exercise, Draft), `messageType` is not `Cancel`, the instant is at or after
  `effective` (else `onset`, else `sent`) and before `ends` (else `expires`). This is checked at every snapshot, also
  from a stale cache, so an alert that has expired disappears even when no new response arrived.
- **Placement.** An alert belongs to an area when its polygon overlaps the area box; an alert without a polygon is
  placed by its affected zones' geometry (`placedBy: "zones"`).
- **State.** `fresh` when the last good response is under 15 minutes old, `stale` when older (renderers show it marked
  as not current, never as live), `unavailable` when there is none. `error` carries the last fetch problem.

## Polite client (api.weather.gov guidance)

- User-Agent `WorldEngine-livefeeds-prototype/0.1 (weather alerts layer); contact: <address>`. The address comes only
  from configuration: environment variable `NWS_CONTACT`, else `"nwsContact"` in the git-ignored
  `.local/livefeeds.json`. Without it the layer refuses to fetch. Never in shared code or commits.
- One request for all areas: `/alerts/active?area=IL,IN,CO,FL` (`Accept: application/geo+json`), conditional on
  `Last-Modified`; the next request waits for the response's `Cache-Control: max-age` / `Expires`, at least 60 s.
- Zone geometry (`/zones/...`) is fetched once per zone and kept 30 days.
- A refused request (4xx) stops fetching for an hour and reports `needsHuman`; `Retry-After` is honoured. No mirrors,
  no retries around a refusal.

## Contract

```json
{
  "schema": "worldengine.live.alerts/1", "layer": "alerts", "live": true, "basis": "observed", "official": true,
  "generatedAt": 1791377792, "feedTimestamp": 1791377791, "state": "fresh", "stale": false, "error": null,
  "label": "Official weather alert (National Weather Service)", "areas": ["chicago", "denver", "miami"],
  "alerts": [{
    "id": "https://api.weather.gov/alerts/urn:oid:…", "link": "https://api.weather.gov/alerts/urn:oid:…",
    "areas": ["miami"], "event": "Coastal Flood Statement", "severity": "Minor", "certainty": "…", "urgency": "…",
    "headline": "…", "description": "…", "instruction": "…", "senderName": "…", "areaDesc": "…", "response": "…",
    "category": "…", "status": "Actual", "messageType": "Alert",
    "sent": 0, "effective": 0, "onset": 0, "expires": 0, "ends": null,
    "geometry": null, "affectedZones": ["https://api.weather.gov/zones/…"], "placedBy": "zones",
    "basis": "observed", "official": true, "source": "nws", "label": "Official weather alert (National Weather Service)"
  }],
  "attribution": [{"source": "nws", "text": "Weather alerts: National Weather Service (weather.gov). Official text, unaltered.",
                   "url": "https://www.weather.gov/", "live": true, "required": true}]
}
```

Times are POSIX seconds; `geometry` is the alert's GeoJSON polygon (WGS84 lon/lat) when it has one.

## Licence

NWS information is in the public domain unless noted otherwise and may be used for any lawful purpose provided it is
not claimed as one's own or misrepresented (https://www.weather.gov/disclaimer, read 2026-10-07). Licensing row LW14.

## First live run (2026-10-07)

13 alerts active in IL, IN, CO and FL; 1 in the three boxes (Miami, Coastal Flood Statement, placed by zones); 36 zone
geometries cached; the response's `max-age` was 30 s (the client waits at least 60 s).
