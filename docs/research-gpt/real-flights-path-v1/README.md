# Real flights path v1
Checked 2026-10-07. Research only: no purchases, accounts, agreements accepted, or emails sent.

**Recommendation [Assumption/design]:** validate Denver with one owned 1090 MHz receiver, then use adsb.lol through a pooled backend after production coordination. Keep its flight database separate and ODbL-compliant. Pursue FAA SWIM surface tracks later. Do not promise actual gate assignments.

Evidence labels: **V** verified published primary source; **A** assumption, estimate or interpretation; **U** not verified. A published grant does not establish service capacity or an SLA. Every linked source was checked on the date above.

| Path | Commercial display | Store | Resell/relay | Decision |
|---|---|---|---|---|
| Own receiver observations | A: plausible, legal review of radio-publication law remains | A: own observations, not returned aggregator data | A: review before launch | Denver validation first |
| adsb.lol | V: ODbL commercial rights | V: license permits reproduction | V: under ODbL, no exclusive ownership | Best published open-data option; production capacity U |
| FAA SWIM/SMES | V: conditional secondary-product framework | A: subject to blocking and service terms | V: conditional redistribution framework; service-specific clearance U | Later, approved access only |
| adsb.fi | V: self-service noncommercial | Commercial U | Commercial U | Do not launch without agreement |
| Airplanes.live | U: no data grant retrieved | U | U | Apache API-spec label is insufficient |
| ADSBHub | U: commercial feed grant not found | U | U | Website disclaimer permits noncommercial downloads only |

See [Research](research.md), [Receiver guide](receiver-guide.md), [Unsent email](permission-email.md), [Cost assumptions](cost-estimate.json), [Sources](sources.md). Open index.html for a phone-friendly summary.
