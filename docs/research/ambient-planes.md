# Ambient planes: illustrative aircraft on real approach corridors (specification)

> **Specification only. No code, no flight data, nothing live.** Written **2026-10-06**. It proposes an optional "ambient planes" layer for areas near Chicago O'Hare (ORD) and Denver International (DEN). It stands in for live aircraft until the adsb.lol operator gives permission (`live-feeds.md` §1 blocker 4, §5.6), and it never presents itself as real traffic. Nothing here changes the engine, the renderers or the package format. Per CLAUDE.md, every design choice below is a proposal until the owner approves it (§9). No provider was contacted.
>
> **Tags** (as in `live-feeds.md`): **[V]** read this pass from the source with an honest client; **[O]** observed in a measurement I made; **[U]** unverified, because the site blocked automated access (confirm in a normal browser); **[T]** third-party or search-engine summary, context only; **[C]** unconfirmed; **[A]** my arithmetic, design choice or assumption. **Every model parameter in §4 is [A]**: a design choice, not a measurement of real traffic.
>
> **Runway data in §2** is derived from OpenStreetMap: **© OpenStreetMap contributors** (ODbL 1.0).

---

## 1. Purpose and labelling

**Purpose.** Planes in the sky make a stylized 3D place feel inhabited, and approach corridors are among the few places where aircraft are reliably overhead. Live aircraft cannot ship yet: the only candidate is adsb.lol, which asks production users to get in touch first, and the aircraft budget is $0 (`live-feeds.md` §1, §5.6). Ambient planes are the stand-in: invented aircraft that fly **real geometry** (the extended runway centrelines) at plausible times and speeds.

**Rules, all binding on the option:**

1. **Illustrative only, never presented as real flights.** No copy anywhere says or implies "live", "now", "overhead right now" or "flights near you".
2. **A persistent on-screen label** whenever the option is on and the camera is inside an area where an ambient aircraft could be drawn (not only while one is in frame, so the label can never be missing when one appears). Proposed text, carried in the data itself (§7): **"Illustrative air traffic — not live"**. It sits next to the OpenStreetMap credit and is not dismissable. The same text appears in the credits panel (the standard credits data file is `Sources/WorldGen/Profiles/credits.json`, `docs/data-licensing.md` §1), and is burned into any exported image or video that has an ambient aircraft in frame (same mechanism as the OSM credit, `CreditBurnIn`; not built for this yet).
3. **No identity.** No flight numbers, airlines, registrations, callsigns or aircraft type names, and no livery, airline colours or tail logos. Aircraft are generic, unmarked hulls in two classes (medium and heavy; §4). Nothing in the record or the scene can be used to look up a real flight.
4. **No tap-to-identify.** Ambient aircraft are not pickable, have no detail card, and carry a generic accessibility label ("illustrative aircraft").
5. **No sound.**
6. **The relay and engine data-contract kind is `"aircraft-ambient"`** (the name the data-contract section of `live-feeds.md` uses), with `live: false` (§7).

---

## 2. Real geometry

### 2.1 Source and method

One small Overpass query per airport, to `overpass-api.de`, with the User-Agent `WorldEngine-research/0.1`, JSON output, `out geom` (geometry and tags; **never `out meta`**). Result: no element carried a `version`, `user`, `uid` or `timestamp` key (checked [O]). Raw responses were kept outside the repo; only the derived table below is recorded.

| Airport | Query | OSM base timestamp (`timestamp_osm_base`) |
|---|---|---|
| ORD | `[out:json][timeout:25];way["aeroway"="runway"](41.93,-87.99,42.03,-87.85);out geom;` | **2026-10-06T14:13:27Z** [O] |
| DEN | `[out:json][timeout:25];way["aeroway"="runway"](39.78,-104.78,39.93,-104.56);out geom;` | **2026-10-06T14:15:32Z** [O] |

Request log, for honesty: ORD took one request. The first two DEN requests (a slightly larger box, `(39.77,-104.80,39.95,-104.55)`, 45 s apart) returned HTTP 504 with the server's "probably too busy" dispatcher timeout, not a block; the status page showed free slots, and the third request with the tighter box above succeeded. One status request (`/api/status`) was made. Requests were at least 8 s apart.

**Method.** For each runway way: the two end nodes are the physical pavement ends; the true heading of a landing is the **WGS84 geodesic initial azimuth** from the landing's near end to the far end; the threshold is the near end. Intermediate nodes lie within 2.1 m of the straight chord at ORD and 0.8 m at DEN [O], so a straight line between the end nodes is faithful.

**Caveats.**

- **OSM way ends are pavement ends, not landing thresholds.** Displaced thresholds are not modelled; a real touchdown can be several hundred metres further on. This is small next to a 12 NM corridor [A].
- **Designator numbers are not used.** The number times ten is a rounded *magnetic* heading and can be stale. Measured example [O]: ORD's `09x/27x` and `10x/28x` families are parallel (true headings 90.0 and 89.9) although their numbers differ by one. DEN shows the same pattern: the OSM `16/34` and `17/35` pairs (and `07/25` against `08/26`) have the same true heading within 0.2 degrees, though their numbers differ by one. I could not reconcile that with a primary source (FAA documents returned 403 to the fetch tool; §10), so **the DEN headings are OSM-derived and should be checked against the FAA airport diagram in a normal browser [U]** before shipping. The model uses only geometry, never the designator, so a different true heading would only shift the corridor.
- **Stale tag.** OSM way 4357998 (ORD `04L/22R`) carries `end_date=7/21/2016` and `old_ref`, which looks like a leftover from a lifecycle edit. ORD's own Fly Quiet manual (updated February 2026) lists `4L-22R` among its eight runways in use [V], so it is kept.
- **Excluded.** Two DEN-box ways (OSM 82147518 and 1163750274) lie about 10 km south-east of DEN's nearest runway end: a separate small airfield, not DEN. They are left out.

### 2.2 Corridor construction

**Centreline.** For an arrival on runway *r* with threshold *T* and true landing heading ψ, a point at ground distance *d* before the threshold lies on the geodesic from *T* with bearing ψ + 180°. In local metres: east = −d · sin ψ, north = −d · cos ψ.

**Altitude against distance (3° glide path).** Height above the threshold elevation:

```
h(d) = TCH + d · tan(3°)        TCH = 15 m (50 ft);  tan(3°) = 0.052408
```

Per nautical mile (1 NM = 1,852 m) that is 97.06 m (318.4 ft) of height. Check values [A]:

| d from threshold | 1 NM | 2 NM | 3 NM | 5 NM | 6 NM | 8 NM | 10 NM | 12 NM | 15 NM |
|---|---|---|---|---|---|---|---|---|---|
| h (m) | 112 | 209 | 306 | 500 | 597 | 791 | 986 | 1,180 | 1,471 |
| h (ft) | 368 | 686 | 1,005 | 1,641 | 1,960 | 2,597 | 3,234 | 3,870 | 4,826 |

A 3° glide path is the standard ILS slope and 50 ft a nominal threshold crossing height [T: search-engine summary; the FAA AIM page returned 403 to the fetch tool, so confirm in a browser [U]]. At 150 kt ground speed the descent rate is about 800 ft per minute [A].

**Length.** Default **12 NM (22.2 km)**, configurable 10 to 15 NM per airport. At 12 NM the aircraft is at about 3,900 ft above the threshold. Support: the Fly Quiet manual has an advisory descent item asking arrivals to be no lower than 4,000 ft MSL when turning onto final; it states no hours and is not a nighttime procedure [V: [Fly Quiet manual](https://www.flychicago.com/SiteCollectionDocuments/Community/ArchivedPDFs/Noise/OHare/FQ/ORD_FQ_Manual_2026_ADA.pdf), read 2026-10-06]. On a 3° path that is about 10 NM out if the field is about 670 ft MSL (field elevation not verified here [C]), so a 10 to 15 NM final matches how these arrivals are flown [A].

**Straight-in only (chosen), no downwind/base pattern.** Justification:

- Large-airport jet arrivals are vectored onto a long straight final. A downwind-and-base circuit is a light-aircraft idiom here, and the real downwind and base legs depend on controller vectors and the day's flow, which OSM cannot supply.
- The only real thing we can compute from data is the extended centreline. Anything off it would be invented geometry presented next to real streets, which is exactly what "illustrative" must not blur.
- Fewer parameters, simpler culling (§5), and a corridor that is a straight line is trivial to test.
- Cost: all arrivals look alike. Accepted. A later refinement, if wanted: a seeded lateral join offset of up to ±2 NM that fades to zero by 8 NM (join angle under 30°); not part of this spec.

**Past the threshold.** Touchdown 300 m beyond the threshold [A]; ground speed falls linearly in time from V_app − 5 kt to 30 kt over about 1,700 m; then the aircraft dissolves over 3 s. **No taxiing, no gates, no aprons**: ground movements next to real buildings would read as real operations.

**Departures (optional).** From the departure runway's threshold in its own heading: roll with constant acceleration to 150 kt over 1,800 to 2,400 m (seeded; at most runway length − 800 m), lift off, climb straight out along the extended centreline at 6° (tan 0.1051) at 170 kt ground speed (about 1,800 ft per minute) to the corridor end 12 NM beyond the runway's far end (altitude about 2.3 km there), capped at 3,000 m. **No turns**: real departures follow procedures with turns that OSM does not give [A].

### 2.3 Runway tables

**Derived from OpenStreetMap data (`aeroway=runway` ways with `ref`), base timestamps above. © OpenStreetMap contributors (ODbL 1.0).** One row per landing direction. Threshold = the near end node (WGS84, 5 decimals, about 1 m). True heading = geodesic initial azimuth from the threshold along the runway. Length = geodesic length between the end nodes (OSM `length` tags agree within 2 m where present). "Use" is the default role in §3: `arr`/`dep` for arrival/departure in west (W), east (E), south (S) or north (N) flow; "not used" runways are kept in the data but not drawn.

**ORD** (8 ways; 16 landing directions)

| Landing | Threshold lat, lon | True heading (deg) | Length (m) | OSM way | Use |
|---|---|---|---|---|---|
| 04L | 41.98166, -87.91393 | 39.5 | 2,285 | 4357998 | not used |
| 04R | 41.95334, -87.89942 | 41.5 | 2,460 | 4357995 | not used |
| 09C | 41.98832, -87.93158 | 90.0 | 3,427 | 599431864 | dep E |
| 09L | 42.00283, -87.92668 | 90.0 | 2,286 | 27347454 | not used |
| 09R | 41.98390, -87.93158 | 90.0 | 3,430 | 807922883 | arr E |
| 10C | 41.96570, -87.93151 | 89.9 | 3,290 | 188230191 | dep E |
| 10L | 41.96900, -87.93154 | 89.9 | 3,961 | 4368525 | arr E |
| 10R | 41.95721, -87.92787 | 89.9 | 2,285 | 673227833 | not used |
| 22L | 41.96993, -87.87976 | 221.5 | 2,460 | 4357995 | not used |
| 22R | 41.99754, -87.89639 | 219.5 | 2,285 | 4357998 | not used |
| 27C | 41.98832, -87.89023 | 270.0 | 3,427 | 599431864 | dep W |
| 27L | 41.98391, -87.89019 | 270.0 | 3,430 | 807922883 | arr W |
| 27R | 42.00284, -87.89909 | 270.0 | 2,286 | 27347454 | not used |
| 28C | 41.96577, -87.89182 | 269.9 | 3,290 | 188230191 | dep W |
| 28L | 41.95726, -87.90030 | 269.9 | 2,285 | 673227833 | not used |
| 28R | 41.96908, -87.88375 | 269.9 | 3,961 | 4368525 | arr W |

**DEN** (6 ways; 12 landing directions; the two excluded ways are not DEN)

| Landing | Threshold lat, lon | True heading (deg) | Length (m) | OSM way | Use |
|---|---|---|---|---|---|
| 07 | 39.84094, -104.72666 | 90.5 | 3,655 | 20199112 | not used |
| 08 | 39.87755, -104.66223 | 90.5 | 3,656 | 20199011 | not used |
| 16L | 39.89702, -104.68681 | 180.5 | 3,656 | 20199004 | arr S |
| 16R | 39.89578, -104.69610 | 180.5 | 4,874 | 20199001 | arr S |
| 17L | 39.86494, -104.64131 | 180.6 | 3,655 | 20199006 | dep S |
| 17R | 39.86126, -104.66018 | 180.5 | 3,657 | 20199008 | dep S |
| 25 | 39.84065, -104.68396 | 270.5 | 3,655 | 20199112 | not used |
| 26 | 39.87724, -104.61950 | 270.6 | 3,656 | 20199011 | not used |
| 34L | 39.85189, -104.69660 | 0.5 | 4,874 | 20199001 | dep N |
| 34R | 39.86409, -104.68720 | 0.5 | 3,656 | 20199004 | dep N |
| 35L | 39.82832, -104.66056 | 0.5 | 3,657 | 20199008 | arr N |
| 35R | 39.83202, -104.64173 | 0.6 | 3,655 | 20199006 | arr N |

A runway's two ends share one OSM way, so each way appears twice. Lengths agree with the usual published figures for these runways (for example about 3,961 m is 13,000 ft; DEN's 4,874 m is 16,000 ft), but I did not verify them against an FAA source [C].

---

## 3. Flow configurations

**General picture.** Aircraft land and take off into the wind, so large airports run in a small number of "flows" that follow the wind and change only occasionally.

- **ORD.** Eight runways, used at different times "depending primarily upon the prevailing airfield conditions, and air traffic conditions" [V: Fly Quiet manual above]; the flows below follow the wind in practice [A]. The two main flows are **west flow** (arrivals come from the east and land westward on the 27/28 runways; departures leave to the west) and **east flow** (the reverse, on 09/10). A search-engine summary of an older O'Hare noise FAQ puts west flow at about 70 percent of the time and east flow at about 30 percent [T: page not opened here]. The two diagonal runways (04/22, true headings about 40 and 220 degrees, §2.3) point north-east and south-west and are **not used in v1**. The Fly Quiet programme has a voluntary, advisory list of preferential runways, reported in an earlier pass as 10L-28R, 9R-27L, 4L-22R and 4R-22L: **unverified [U]**, because the list could not be extracted from the PDF (confirm in a normal browser). The manual's 22:00 to 07:00 hours apply to reverse thrust only, not to runway choice [V: same manual]. Not modelled; the model's own quiet hours are an assumption (§4.5).
- **DEN.** Four parallel north-south runways and two east-west runways. The **south flow** (arrivals from the north, landing southward) is the most common, the **north flow** next, and the east-west "crosswind" runways are used a small share of the time; a search-engine summary of Denver airport noise material gives about 68, 30 and 2 percent [T: the airport's own document, `cdn.flydenver.com/app/uploads/2023/09/20162330/210_noise-1.pdf`, returned 403 to the fetch tool, so this is unverified [U]]. The same summaries say arrivals land on the two runways on one side and departures use the two on the other, and that runways 25 and 26 are noise-sensitive and avoided when possible [T]. East-west runways are **not used in v1**.
- **Everything about real runway assignment is [T] or [A].** I could not open the FAA's own DEN community-engagement boards or capacity profile (both 403 to the fetch tool; §10). The default arrival and departure runway sets below are **chosen for visual spread, not copied from operations**, and the option never claims they match what the airport is doing.

**Flow table (default sets; data, owner may change).**

| Airport | Flow | Landing heading (true) | Arrivals | Departures |
|---|---|---|---|---|
| ORD | west (default) | 270.0 | 27L, 28R | 27C, 28C |
| ORD | east | 90.0 | 09R, 10L | 09C, 10C |
| DEN | south (default) | 180.5 | 16L, 16R | 17L, 17R |
| DEN | north | 0.5 | 35L, 35R | 34L, 34R |

Arrival and departure sets are disjoint, so arrivals and departures never share a runway. The ORD arrival runways (27L and 28R in west flow; 09R and 10L in east flow) happen to be the two pairs `9R-27L` and `10L-28R` on the Fly Quiet preferential-runway list as reported in an earlier pass (**unverified [U]**, §3); that is a coincidence of the visual-spread choice, not a claim about operations.

**Choosing the flow from wind.** If the weather provider supplies wind for the instant being shown, the option picks the flow with the better headwind. The engine already carries the needed fields: `WeatherSample.windFromDegrees` (direction the wind blows *from*, treated as degrees true as METAR reports it) and `windSpeedMps` (`Sources/WorldEnvironment/WeatherSample.swift`, `MetarAdapter`). Whether every provider reports true rather than magnetic direction is [C]; convert if not.

```
V_kt      = windSpeedMps * 1.94384
headwind(F) = V_kt * cos(windFromDegrees - landingHeading(F))        // positive = into the wind
use flow F_other instead of F_default  iff
        windSpeed >= 4 kt   AND   headwind(F_other) - headwind(F_default) >= 2 kt
```

- **Stateless and deterministic.** The rule prefers the default unless the other flow is clearly better, so a veering wind near a crosswind does not flip the flow back and forth. The wind sample's valid hour is used, so the flow changes at most once per hour. A flow change needs no special case: each aircraft belongs to the flow of the hour that contains its threshold time, so for a few minutes around the change both flows have aircraft on their corridors, which is plausible.
- **Defaults when no wind is available** (provider silent, scrubbed time or past date, calm under 4 kt, variable): **west flow at ORD, south flow at DEN**, the most common flows in the [T] figures above.
- **Never claim the real current configuration.** The wind makes the pictured flow *plausible*; nothing in the UI, label or credits says it is the airport's current configuration, and the traffic on it is invented.
- **Cross-device caveat.** Two devices that fetched different weather can pick different flows for the same hour; everything else is identical (§4).

---

## 4. Traffic model

All values are **[A]**, defaults held in area data (§7), per airport, so a different airport or a different taste changes data, not code.

### 4.1 Parameters at a glance

| Parameter | Value | Note |
|---|---|---|
| Corridor length | 12 NM (22.2 km) | configurable 10 to 15 NM |
| Glide path | 3.00 degrees, TCH 15 m | §2.2 |
| Slot length Δ | 150 s | one possible aircraft per runway per slot (max 24 per hour per runway) |
| Slot jitter J | ±25 s around the slot centre | guarantees at least 100 s between successive aircraft on one runway |
| Peak slot occupancy, arrivals P_arr | 0.6 | at most 14.4 arrivals per hour per arrival runway (28.8 per airport with two) |
| Peak slot occupancy, departures P_dep | 0.4 | at most 9.6 departures per hour per departure runway |
| Time-of-day multiplier m(h) | curve in §4.2 | local time of the airport |
| Approach speed V_app | 140 to 150 kt (medium), 150 to 160 kt (heavy) | seeded per aircraft; 70 percent medium |
| Corridor-start speed | 185 kt at 12 NM | linear in distance down to V_app at 6 NM, constant V_app from 6 NM in |
| Minimum spacing (simulated worst case) | 3.4 NM | Δ = 150 s, J = 25 s, V_app in 140 to 160 kt |
| Maximum drawn at once | 6 aerial, 3 street | §5 |
| Appear and vanish | fade over 1.5 NM at corridor ends; over 3 s at rollout end | §4.5 |
| Quiet hours | 00:00 to 05:00 local | arrivals at the m = 0.08 floor; departures off from 22:00 to 05:00 |
| Sound | none | |

### 4.2 Time-of-day curve (assumption, not measured)

Local hour *h* (airport time zone, handles daylight saving because the wall clock is used) to multiplier *m*; linear interpolation between hour centres. Arrival slot occupancy is `p(t) = P_arr * m(t)`; departures use `P_dep * m(t)`, with m forced to 0 from 22:00 to 05:00.

| h | 0-4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| m | 0.08 | 0.25 | 0.60 | 0.85 | 1.00 | 0.90 | 0.75 | 0.70 | 0.75 | 0.80 | 0.80 | 0.85 | 0.95 | 1.00 | 0.95 | 0.90 | 0.75 | 0.55 | 0.35 | 0.20 |

Two banks (morning and evening) and a quiet night, the usual shape of a hub's day [A]. With these numbers each arrival runway gets about 206 arrivals a day, so **about 412 per airport per day and about 128 departures per departure runway** [A]. That is deliberately a **small fraction of real traffic** (low density is a rule, §5); the real figures were not looked up for this document and the curve is labelled an assumption.

### 4.3 Slots and seeding (deterministic, same on every device)

The local day (counted in elapsed seconds from local midnight) is cut into slots of Δ seconds, **per runway and per stream** (arrival or departure). Whether a slot holds an aircraft, and everything about it, comes from one `StableRandom` seeded as the repo convention requires (never `Hasher`, `random()` or `SystemRandomNumberGenerator`; `Sources/WorldGeo/StableRandom.swift`):

```
rng = StableRandom(dayNumber, slotInDay, salt: "ambient-planes/<airport>/<runway>/<arr|dep>")
```

- `dayNumber` is the airport-local civil date as days since 1970-01-01; `slotInDay` the slot's index. The salt separates airport, runway and stream (the same way `OSMRef.random(salt)` separates uses, `Sources/WorldMap/OSMDocument.swift`).
- **Fixed draw order** (part of the format; any later draw is appended at the end): u1 occupied if `u1 < p(t_slot)`; u2 position in the jitter window; u3 class (medium if `u3 < 0.7`); u4 V_app inside the class range; u5 hull variant; u6 ground-roll length (departures).
- **Time at the threshold** (arrivals) or at brake release (departures): `t = slotStart + Δ/2 + (u2 - 0.5) * (Δ - 100 s)`. With Δ = 150 s that is ±25 s, so two successive aircraft on one runway are at least 100 s apart at the threshold.
- To evaluate world time *t*, enumerate the slots whose aircraft could be on the corridor: for arrivals those with threshold time in `[t - 60 s, t + 273 s]` (the corridor time plus the roll-out; 2 to 3 slots per runway); for departures those with brake release in `[t - 300 s, t]` (about 35 s of roll plus 12 NM of climb) [A]. Within 5 minutes of local midnight the enumeration also looks at the neighbouring day. No history, no replay, no state: **position is a closed-form function of `t`**.
- **Flow belongs to the slot.** Which runways a slot's aircraft uses is fixed by the flow of the hour containing the slot's threshold time (§3).
- **Same traffic on every device** given the same area data, world time and flow (the flow can differ only where devices have different weather).

### 4.4 Speed profile and time on corridor

Arrival ground speed against distance *d* before the threshold (D = 6 NM, V_far = 185 kt, ΔV = V_far − V_app):

```
d >= 6 NM:   V(d) = V_app + ΔV * (d - 6 NM) / D                      (linear in distance)
d <  6 NM:   V(d) = V_app
time to go:  T(d) = d / V_app                                         for d <= 6 NM
             T(d) = 6 NM / V_app + (D / ΔV) * ln( V(d) / V_app )      for d > 6 NM
```

`T(d)` has a closed form and is inverted by a short lookup table to get the position at a given time. At V_app = 150 kt the 12 NM corridor takes about **273 s** [A]. Altitude follows `h(d)` (§2.2), so the descent rate stays near 800 ft per minute. Wind is ignored (ground speed equals airspeed); an aircraft's heading is the runway heading.

**Expected density** at peak: each arrival runway has about 1.1 aircraft on its corridor on average (14.4 per hour times 273 s), so about two arrivals and one or two departures are on corridors at once, well under the draw cap (§5) [A].

### 4.5 Fades, quiet hours, label

- **Stateless fades.** Opacity is a function of position, not of an event: at the arrival corridor's far end, opacity rises from 0 to 1 over the first 1.5 NM; on departure, opacity falls from 1 to 0 over the last 1.5 NM; at the end of an arrival's roll, opacity falls to 0 over 3 s. A second fade, by camera distance, applies at the edge of the visible region (§5). An aircraft therefore never pops in or out where the camera can see it.
- **Quiet hours** are local 00:00 to 05:00. Arrivals continue at the m = 0.08 floor (about one an hour per runway), which is a few lit aircraft at night rather than an empty sky; departures are off from 22:00 to 05:00. Night appearance: navigation lights and strobes only, no fuselage lighting.
- The persistent label (§1) is independent of quiet hours and fades.

---

## 5. Visibility rules

Render an ambient aircraft only when the camera could plausibly see it; draw nothing, and run no generator, otherwise.

1. **The area has the option on** (`aircraftMode: "ambient"`, §8) **and the camera is within 30 km of the airport reference point** (the mean of the runway thresholds). Corridors are 22 km long, so views over the neighbouring suburbs and city can still see aircraft.
2. **Aerial view:** slant range from the camera to the aircraft at most **12 km**. Opacity falls from 1 at 9 km to 0 at 12 km.
3. **Street (walking) view:** slant range at most **8 km** and elevation angle above the camera's horizon at least **8 degrees**, so aircraft hidden by roofs and trees are not drawn. At 1,200 m altitude that limits the ground distance to roughly 8 km, at 500 m to roughly 3.5 km; street views near, but not under, a corridor see nothing, which is correct.
4. **Low density.** At most **6** ambient aircraft drawn at once in aerial view and **3** in street view; a nearer aircraft wins when the cap bites.
5. **No sound.** No audio of any kind.
6. **Optional, owner to decide:** hide aircraft above the cloud base when the weather sample's cloud cover is high (the engine's cloud cover is a 0 to 1 fraction), so planes do not fly in front of an overcast sky.
7. **Cost.** Evaluation is a handful of slot draws per runway per tick; no network, no assets beyond the hulls.

---

## 6. Data and licensing

- **Runway geometry** comes from OpenStreetMap (ODbL). The derived runway tables (§2.3) are OSM-derived data: ship them as area data under the same ODbL notice and credit as the world package's data part (`docs/data-licensing.md` §1 to §2), with **"© OpenStreetMap contributors"** visible whenever the world is on screen (CLAUDE.md). The derived table is a small Derived Database; whether anything more is owed under share-alike is the same lawyer question as for the world package itself (`licensing.md` §2.3 and Q1; decisions in `docs/data-licensing.md`), not a new one.
- **No flight data of any kind is used**, so **no aircraft-feed licence applies** (nothing from adsb.lol, OpenSky, FlightAware or any other source). The LADD and PIA rules (`live-feeds.md` §3.3) do not apply because no real aircraft is involved.
- **Credits.** Add one credits entry when built: "Illustrative air traffic, not real flights. Runway geometry © OpenStreetMap contributors." Marked clearly as illustrative, and shown whenever the option is on. No non-affiliation or trademark text is needed because no airline, airport or agency mark is used; the airport name appears nowhere in the scene.
- **Not legal advice.** Same stance as the other research documents.

---

## 7. Data contract

Ambient aircraft use **the same vehicle record as live feeds**: the contract in `live-feeds.md` §8 (schema 1), so the host's drawing path is one path. Ambient records add two fields, `altitudeM` and `label`, as the contract allows (additive fields, §8.10; aircraft kinds add optional fields such as `altitudeM`, §8.4). They travel in an on-device snapshot whose top-level `live` is `false`.

```jsonc
// The snapshot the host hands to the engine (generated on device, never from the relay)
{
  "schema": 1,
  "live": false,                    // never presented as live (§1)
  "generatedAt": 1791281250,        // world time the records are evaluated for (Unix seconds): 2026-10-06 10:07:30Z, i.e. 05:07:30 local, the start of slot 123 of dayNumber 20732 (matches the id below)
  "feedTimestamp": null,            // no feed
  "state": "fresh", "stale": false,
  "vehicles": [
    {
      "id": "amb:ORD:27L:20732:0123",  // opaque, stable, deterministic: airport:runway:dayNumber:slot (20732 = 2026-10-06). Not an ICAO address, never real.
      "kind": "aircraft-ambient",
      "route": "ORD 27L",              // the runway in use; never a callsign, flight number or airline
      "routeName": null,
      "lat": 41.98391, "lon": -87.81234,  // WGS84
      "heading": 270.0,                // degrees clockwise from true north, the runway's landing heading
      "speedMps": 77.2,                // ground speed (150 kt)
      "stopStatus": null,
      "timestamp": 1791281250,         // same instant as generatedAt
      "ageSeconds": 0,
      "source": "ambient",             // not a feed key, so no feed credit is claimed (contract §8.4)
      "altitudeM": 352.7,              // additive: metres above the threshold elevation of the runway in use (3.5 NM out: 15 + 0.052408 * 6,444 m)
      "label": "Illustrative air traffic — not live"   // additive: the not-live text the host must show (§1)
    }
  ],
  "attribution": [
    { "source": "ambient", "text": "Illustrative air traffic, not live. Runway geometry © OpenStreetMap contributors.",
      "url": "https://www.openstreetmap.org/copyright",
      "live": false }                  // the host passes this entry to the credits slot as illustrative (live-feeds §8.8)
  ]
}
```

- **Omitted top-level fields.** `pollIntervalSeconds` and `area` (contract §8.3) are left out of the on-device snapshot: nothing is polled and there is no tile area.
- **`altitudeM` is height above the threshold elevation**, so the generator needs no elevation data; the host adds its own ground height if the world has terrain (not covered by the plan [C]).
- **Generated on device, no server.** Because the traffic is a pure function of `(area data, world time, flow)`, every device computes the same records itself: no relay, no key, no network, nothing to cache. It is *not* served through the relay, so it also needs no relay `feeds` entry; if a host wants one for uniformity, use `{ "status": "fresh", "attribution": "Illustrative air traffic, not live" }`.
- **Where it lives** (an optional engine module, a small separate package, or host code) is an owner decision not covered by the plan, so nothing is built yet. The engine stays generic: it receives plain vehicle values and never knows about airports.
- **Area data (shape, one airport, trimmed).** Areas are data, nothing place-specific in code:

```jsonc
{
  "airport": "ORD", "timeZone": "America/Chicago",
  "osmBaseTimestamp": "2026-10-06T14:13:27Z",
  "runways": [ { "ref": "27L", "threshold": [41.98391, -87.89019], "headingTrueDeg": 270.0, "lengthM": 3430 } /* ... */ ],
  "defaultFlow": "west",
  "flows": { "west": { "landingHeadingTrueDeg": 270.0, "arrivals": ["27L","28R"], "departures": ["27C","28C"] },
             "east": { "landingHeadingTrueDeg": 90.0,  "arrivals": ["09R","10L"], "departures": ["09C","10C"] } },
  "model": { "corridorNm": 12, "slotSeconds": 150, "jitterSeconds": 25, "arrivalPeak": 0.6, "departurePeak": 0.4,
             "hourlyMultiplier": [0.08, 0.08, 0.08, 0.08, 0.08, 0.25, 0.60, 0.85, 1.0, 0.9, 0.75, 0.70,
                                  0.75, 0.80, 0.80, 0.85, 0.95, 1.0, 0.95, 0.90, 0.75, 0.55, 0.35, 0.20] },
  "attribution": "© OpenStreetMap contributors"
}
```

A small offline tool (a sibling of the region kit) would build this file from one Overpass query per airport, exactly as in §2.1, and record the base timestamp.

---

## 8. Switch-over to live aircraft

- **Per-area mode** in area data: `aircraftMode: "off" | "ambient" | "live"`. The default until the owner decides is `"off"` (or `"ambient"` if approved as a default; §9).
- **If the adsb.lol operator grants permission**, `"live"` replaces `"ambient"` **for that area**: the ambient generator stops, live vehicles (`kind: "aircraft"`, `live: true`) arrive through the relay, and the label changes to the live feed's attribution (ODbL credit for adsb.lol, `live-feeds.md` §4.8). Live aircraft keep the live rules there (LADD and PIA filtered, no identity sent to phones).
- **Never mix in one view without distinct labelling.** Ambient and live aircraft must not appear in the same view under one label. Where both could appear (an area boundary), each shows its own label, and ambient hulls are drawn in a visibly different treatment (flat, unmarked, no beacon strobes).
- **No silent fallback.** If live data becomes `stale` or `unavailable` (`live-feeds.md` §4.7), the sky goes empty rather than switching to invented traffic. Switching an area back to `"ambient"` is a deliberate configuration change that swaps the label in the same moment, so illustrative planes are never taken for the live ones that were there a moment earlier.
- **Rights are not transferable.** Nothing in the ambient option relaxes any feed licence; it uses no feed.

---

## 9. Decisions for the owner

These are not covered by the plan (CLAUDE.md: report before going into code). My recommendation is in bold.

1. **Default state.** `"off"` until a host opts in, or `"ambient"` in ORD and DEN areas? **Opt-in at first.**
2. **Density.** Peak 28.8 arrivals per hour and 19.2 departures per hour per airport (§4.1), a small fraction of real traffic. Raise or lower?
3. **Straight-in only** (§2.2), no downwind or base. **Keep.**
4. **Label wording** (§1). The owner's example wording is used verbatim; shorter alternatives such as "Illustrative planes — not live" are possible.
5. **Where the generator lives** (engine module, package, or host) and whether quiet hours should be zero rather than the 0.08 floor.
6. **Departures** (§2.2): optional; recommend **on**, with arrivals, for a fuller sky.

---

## 10. Unverified items, blocked URLs and sources

All accessed **2026-10-06**. Honest client throughout: `curl` with User-Agent `WorldEngine-research/0.1` for Overpass, the session's default fetch tool for pages. No browser identity was imitated, no archive copy was used to get round a block, and no blocked URL was retried another way.

**Blocked (stopped, marked unverified).**

| URL | What happened | Affects |
|---|---|---|
| `https://cdn.flydenver.com/app/uploads/2023/09/20162330/210_noise-1.pdf` | HTTP 403 | DEN flow percentages and roles (§3) are [T] only |
| `https://www.faa.gov/sites/faa.gov/files/air_traffic/community_engagement/den/DEN_FinalBoards.pdf` | HTTP 403 | DEN runway use [U] |
| `https://www.faa.gov/sites/faa.gov/files/airports/planning_capacity/profiles/DEN-Airport-Capacity-Profile-2014.pdf` | HTTP 403 | DEN configurations by weather [U] |
| `https://www.faa.gov/air_traffic/publications/atpubs/aim_html/chap1_section_1.html` | HTTP 403 | 3° glide path and 50 ft TCH [T] only |
| `https://skybrary.aero/articles/instrument-landing-system-ils` | returned only a bot-check page | same |

Three different `faa.gov` documents each returned 403; I stopped after the third and did not retry any of them another way, and I requested only that one `flydenver.com` document. Other pages that did not load were dropped: the Boeing noise pages redirect to PDFs (the ORD one returned 404; the DEN one was not requested), and the FAA's DEN traffic-management page redirected to the FAA's NAS-status site.

**Read and relied on [V].**
- Overpass API, `overpass-api.de/api/interpreter` (two queries, §2.1); the OSM data base timestamps above [O].
- Fly Chicago, O'Hare Fly Quiet manual (page updated February 2026): https://www.flychicago.com/SiteCollectionDocuments/Community/ArchivedPDFs/Noise/OHare/FQ/ORD_FQ_Manual_2026_ADA.pdf. Used for: the eight runways and that they are used depending on airfield and air traffic conditions; the advisory 4,000 ft MSL descent item (no hours stated); the 22:00 to 07:00 hours, which apply to reverse thrust only. Its preferential-runway list could not be extracted from the PDF and is unverified.

**Third-party or search-summary [T], pages not opened.** ORD west flow about 70 percent and east flow about 30 percent (an older O'Hare noise FAQ, as summarised by a search engine); DEN south, north and crosswind about 68, 30 and 2 percent, east-west runways 25 and 26 noise-sensitive, arrivals on one side and departures on the other (Denver airport noise material, as summarised); ILS glide slope 3° and nominal TCH 50 ft; radar separation 3 NM and wake-turbulence minima up to 6 NM on final (FAA Order JO 7110.65 §5-5-4, as summarised; not used to size the model beyond the 3.4 NM spacing check).

**Unverified or open.**
- DEN true headings and the one-number difference between the `16/34` and `17/35` pairs in OSM (§2.1): check against the FAA airport diagram in a normal browser.
- Field elevations (ORD about 670 ft MSL is from memory [C]); not needed by the model, which uses height above the threshold.
- Whether METAR-style wind direction from every weather provider is true rather than magnetic [C].
- All real-traffic figures (arrival rates, hub banks) were not looked up; the curve and densities are assumptions [A].
- The ORD and DEN default arrival and departure runway sets (§3) are my choice for visual spread, not the airports' practice.
- Whether OSM `aeroway=runway` ends match the FAA's landing thresholds to within a few hundred metres; displaced thresholds are not modelled.
