# Planes layer: simulated ambient aircraft (and the live ADS-B evaluation)

Code: `Tools/livefeeds/livefeeds/planes/`. Command:
`Tools/livefeeds/livefeeds.sh planes [--time 2026-10-06T10:07:30Z] [--areas ord,den] [--wind-from 90 --wind-mps 5] --pretty`.
Vocabulary (`basis`, `state`, `attribution`): [README.md](README.md).

## 1. Simulated ambient traffic (built)

An implementation of the specification `docs/research/ambient-planes.md` (sections 2 to 7), with no change to
its numbers: invented aircraft fly straight-in arrivals down the real extended runway centrelines (3 degree glide
path, 12 NM corridor, 185 kt slowing to 140-160 kt from 6 NM), land, roll out and dissolve; departures roll,
lift off and climb straight out at 6 degrees. Slots of 150 s per runway and stream, occupancy from the
time-of-day curve, all draws from a Python port of the engine's `StableRandom` in the specified order, so
**position is a closed-form function of time** and every device computes the same sky for the same
area data, time and flow. The flow (ORD west or east, DEN south or north) follows the wind with the
specification's hysteresis rule, or the default flow without wind.

**Areas are data:** `Tools/livefeeds/data/ambient-planes/ord.json` and `den.json` (runway thresholds, headings
and lengths from OpenStreetMap, copied from the specification's table 2.3 with its base timestamps; flows;
model parameters). Each carries `aircraftMode` (`off` stops the generator).

**Midway (MDW) (P1, 2026-10-07).** `data/ambient-planes/mdw.json`: runway table from FAA NASR (cycle 2026-10-01, public
domain, licensing LW13), four flows (04, 13, 22, 31) and a `flowSelection` rule in the file (owner decision): below 4 kt
the default 31; otherwise no flow with more than 5 kt tailwind, least crosswind, and within 1 kt the longer arrival
runway. 13R/31L (1,176 m) is not used. The model copies ORD's assumptions. Credit: the file's `attributionEntry`
("Illustrative air traffic, not live. Runway data: FAA NASR (public domain)."). Earlier note: the brief names O'Hare, Midway and DEN; the specification covers ORD and DEN only,
and deriving Midway's runway table needs one Overpass query, which this cloud session's network policy denies.
With network access: run the specification's section 2.1 query for MDW, add `mdw.json` in the same schema
(flows for Midway are not in the specification and would need the owner's choice).

### Contract

The on-device snapshot of the specification's section 7 (vehicle records of `live-feeds.md` section 8,
schema 1), with these additive fields:

| Field | Meaning |
|---|---|
| top-level `layer` "planes", `basis` "simulated", `label`, `flows`, `visibility` | `flows` names the flow used per airport; `visibility` carries the section 5 rules (30 km airport radius, 12 km aerial and 8 km street range, 8 deg minimum elevation in street view, at most 6 or 3 drawn, no sound, not pickable) for the renderer |
| vehicle `basis` | Always `simulated` |
| vehicle `phase` | `approach`, `flare`, `rollout`, `takeoffRoll`, `climb` |
| vehicle `opacity` | The specification's stateless fades (1.5 NM at corridor ends, 3 s after the roll-out) plus a 3 s fade-in at brake release for departures (the specification has none there; added so a departure never pops in on the runway) |
| vehicle `class`, `hullVariant` | Generic hull choice (medium or heavy; variant 0-2); no airline, livery or type |

`live` is always `false`, `state` always `fresh` (nothing can be late), and the attribution entry is marked
`live: false` so hosts list it as illustrative. Every vehicle carries `label`
"Illustrative air traffic — not live", which the host shows persistently whenever ambient aircraft may be drawn.

Example (2026-10-06 10:07:30Z, the specification's example instant; the aircraft list cut to one):

```json
{
 "schema": 1,
 "layer": "planes",
 "live": false,
 "basis": "simulated",
 "generatedAt": 1791281250,
 "feedTimestamp": null,
 "state": "fresh",
 "stale": false,
 "label": "Illustrative air traffic — not live",
 "flows": {
  "ORD": "west",
  "DEN": "south"
 },
 "visibility": {
  "airportRadiusM": 30000,
  "aerialMaxRangeM": 12000,
  "aerialFadeStartM": 9000,
  "streetMaxRangeM": 8000,
  "streetMinElevationDeg": 8,
  "maxAerial": 6,
  "maxStreet": 3,
  "sound": false,
  "pickable": false
 },
 "vehicles": [
  {
   "id": "amb:ORD:27L:20732:0123",
   "kind": "aircraft-ambient",
   "route": "ORD 27L",
   "routeName": null,
   "lat": 41.983891,
   "lon": -87.823697,
   "heading": 270.0,
   "speedMps": 81.51,
   "stopStatus": null,
   "timestamp": 1791281250,
   "ageSeconds": 0,
   "source": "ambient",
   "altitudeM": 303.0,
   "label": "Illustrative air traffic — not live",
   "basis": "simulated",
   "phase": "approach",
   "opacity": 1.0,
   "class": "heavy",
   "hullVariant": 1
  }
 ],
 "attribution": [
  {
   "source": "ambient",
   "text": "Illustrative air traffic, not live. Runway geometry © OpenStreetMap contributors.",
   "url": "https://www.openstreetmap.org/copyright",
   "live": false,
   "required": true
  }
 ]
}
```

### Tests

`Tools/livefeeds/tests/test_planes.py`: `StableRandom` against the published FNV-1a and SplitMix64 reference
vectors (so a Swift port can be checked against the same numbers), the glide-path table, the 273 s corridor time
and the closed-form timing against numerical integration, 100 s minimum spacing, daily volume, departure quiet
hours, approach and departure profiles and fades, flow choice from wind, `aircraftMode: off`, determinism and labels.

### Open owner decisions from the specification (section 9)

Default state (the spec recommends opt-in per host), density, label wording, whether quiet hours go to zero, and
departures on or off are still the owner's; the data files make each one a data change. Where the generator
lives in the shipped product (engine module, package or host) is also open; this lane only provides the
renderer-neutral reference and contract.

## 2. Live ADS-B: evaluation of adsb.lol (report, nothing built)

The full terms research is in `docs/research/live-feeds.md` section 3 (read 2026-10-06 with an honest client).
This pass could not re-read any adsb.lol page: `api.adsb.lol` is denied by the cloud session's network policy.

| Question | Finding (from live-feeds.md; tags there) |
|---|---|
| Licence | ODbL: commercial use allowed, with attribution and share-alike on any publicly used adapted database. Our relay's snapshot of adsb.lol positions would be such a database, so it would have to be offered under ODbL (licensing Q25). |
| Production use | The API description asks production users to contact the operator first. No SLA, "as is". |
| Access | `GET /v2/point/{lat}/{lon}/{radius}` (up to 250 NM), ADS-B Exchange v2-style JSON; no key today, but the spec says one will be required in future. |
| Rate limits | None published; a third-party report saw limiting at a 4 s poll. |
| Privacy | The feed is unfiltered: LADD and PIA aircraft are present. The relay must drop `dbFlags & 8` (LADD) and `dbFlags & 4` (PIA), never send ICAO addresses, registrations or callsigns to phones, and salt ids daily. |
| Cost | $0 upstream with permission (relay cost as for transit). Commercial alternatives cost about $1.6k to $18.4k per month for two metros. |

**Recommendation: do not build live aircraft yet.** First get the operator's written permission for production
use through our relay (questions in `live-feeds.md` section 6), a statement of acceptable polling (we would poll one
point query per active area every 30 to 60 s), and the owner's decision on the ODbL share-alike consequence for the
relay snapshot. If granted, the build is: an `aircraft` feed in the relay (polite poller, LADD/PIA filter, salted ids,
`kind: "aircraft"`, `live: true`, ODbL attribution), with smoothing by dead reckoning along heading and speed
(`live-feeds.md` 8.6), and per-area `aircraftMode: "live"` replacing `"ambient"` with no silent fallback
(ambient-planes.md section 8).
