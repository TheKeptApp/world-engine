# Weather-for-your-block design pack v1
7 October 2026 · Proposal only · WorldEngine Style B

Eight screen concepts and three original icon/name directions. [Open the gallery](index.html). [Download everything](weather-block-design-v1-all.zip). [One-page product logic](PRODUCT-LOGIC.md). [Screen/data rules](design-values.json). [Prompts](prompts.json).

All homes, weather values and the warning shown here are fictional. “DESIGN DEMO” and “sample” are deliberate. Nothing in this pack is a live forecast, an actual warning, a real user’s address or a running app. No real brand logos appear. Source-name text is an attribution placement placeholder.

## Screens and interactions

| Screen | Concept | Core decision |
|---|---|---|
| 1 | [Home block](images/01-home.png) | Open to one local house; street/aerial toggle; four-hour rail; nearby station observation is secondary and explicitly different from the area forecast. |
| 2 | [Hour scrub](images/02-hour-scrub.png) | Drag or play; the selected valid time is pinned while the same world geometry stays fixed; stop at the available forecast horizon. |
| 3 | [NWS warning example](images/03-alert.png) | Warning sheet takes priority over the world and playback; official issuer, validity, original text and official source link. |
| 4 | [Rain forecast](images/04-rain.png) | Grey light, wet broad pavement planes and restrained streaks; area precipitation rate remains readable. |
| 5 | [Snow forecast](images/05-snow.png) | Cold light, bare trees, exposed pavement and uneven snow appearance; distinguish forecast snowfall from estimated ground cover. |
| 6 | [Fog forecast](images/06-fog.png) | Distance contrast fades while near house and controls stay sharp. |
| 7 | [Night and simulated lights](images/07-night.png) | Quiet blue sky, restrained warm lamps/windows, coherent light pools and simulated shadows. |
| 8 | [Settings and stale preview](images/08-settings-stale.png) | Persistent local-home policy; units, motion, notification preferences, deletion and source links; stale example is prominent. |

## Icon/name directions

| Direction | Visual idea | Positioning |
|---|---|---|
| [Blocklight](images/09-name-blocklight.png) | Roof, sun arc, teal shadow | Lead recommendation: familiarity and moving light |
| [Nearcast](images/10-name-nearcast.png) | Group of roofs, cloud, drop | Most direct emphasis on local forecast |
| [Porchcast](images/11-name-porchcast.png) | Porch roof, horizon, drop | Friendly everyday planning |

These are exploratory original symbols, not existing agency or company logos. Names have not been checked for trademarks, domains or App Store availability. The boards are concept art, not production icon exports; small-size reduction and optical adjustment remain necessary.

## Value labels and freshness

**Proposed design rule:** each weather metric has its label beside it; a global legend alone is insufficient. Each nonnumeric weather-condition icon also inherits a visibly adjacent label. Time-axis labels, timestamps, units preferences and navigation are context rather than measurements.

| Label | Meaning | Required detail on tap |
|---|---|---|
| Observed | A sensor/station measurement at a stated time | Station name, observation time, retrieved time, distance/representativeness caveat |
| Forecast | Provider estimate for a valid time, including a current-condition estimate | Provider, issue/update time, valid time/range, area/grid scope |
| Simulated | Engine-computed or authored visual appearance | Input category, time, known/unknown history and assumptions |
| STALE supplement | Original value retained beyond freshness/validity | Last successful check, source age, reason; no live pulse or “now” implication |
| Unavailable | No valid usable value | Reason and retry; never substitute zero |

WeatherKit current conditions are conservatively classified as **Forecast · current estimate**, rather than station observation. Apple describes its service as a weather forecast providing current conditions; this is our chosen provenance policy, not an assertion that all provider data has a single acquisition method. A nearby NWS observation is **Observed**, with its actual station/time, and never implied to be the selected house’s temperature. [Apple WeatherKit overview](https://developer.apple.com/weatherkit/) · [NWS API](https://www.weather.gov/documentation/services-web-api), checked 7 October 2026.

The world always carries a **Simulated** scene label; individual derived values such as snow coverage also do. Solar position is calculated, therefore Simulated even if astronomical timing is accurate. Any authored fallback climate values are Simulated · seasonal default, never Forecast or Observed. Windows are illustrative, not occupancy detection. An official warning is a forecast/official message, not an observation of damage.

**Assumed initial freshness policy, to validate with provider metadata:** refresh area weather on foreground if older than 15 minutes; consider current estimates stale after 30 minutes without successful refresh; observations stale after 90 minutes from observation time unless the station cadence requires a tighter threshold; forecast runs older than 3 hours get an “older forecast” indicator and become stale if superseded, outside validity or contrary to provider freshness metadata. Source expiry can shorten these limits. A successful download of an old measurement does not reset its age.

Check active warnings on foreground and while visible using provider cache guidance, nominally every 60 seconds, with backoff; stale after five minutes without a successful check. Never infer “no warnings” from a failed request. Show “Warning status unavailable · last checked …” and retain the last official message with its expiry. Cancellation/update references replace prior alerts; expiry ends the active status even offline. Notifications are best-effort, and local background delivery needs platform validation; this pack promises no guaranteed emergency notification channel. Offline keeps dated cached records, then an explicitly Simulated seasonal scene; it cannot invent weather.

## Privacy: exact home stays on device

This is a mandatory product policy, not an optional switch. Store exact coordinates, selected building ID and user nickname in protected local storage; exclude them from cloud backup if the promise is strictly device-only. Delete local home removes these records and home-specific cache bindings. Purchase receipt validation, if required, is separate from location; do not attach home selection to a subscription account.

Weather requests use a proposed 5 km shared grid center. World packages use multi-block area bundles; marker placement, selected-house matching, time-zone lookup and warning polygon matching happen locally. Fetch regional NWS alert collections by state/zone/area, then test location against official polygons locally. Never send the exact home point in a weather, alert, analytics, crash log or geocoding request. Do not build an external address-search flow that violates this promise: choose a coarse city area, then select the house on downloaded local map data. A location permission is requested only when the user selects “Use my location.”

Approximate area, IP address and package access can still be visible to network providers. The promise is that the exact home selection stays local, not complete anonymity. Do not include raw camera poses or world screenshots in diagnostics. V1 has no sharing of the home scene; a later share flow would need explicit preview and location removal, including recognizable geometry. No resident names, interiors, ownership data, smart-device signals or people models. Public OSM footprints are not a claim about who lives there.

## Attribution placement

**Apple — verified, 7 October 2026:** displaying Apple weather values requires its supplied Apple Weather mark and a legal data-source link. Obtain the appropriate light/dark artwork and attribution URL from WeatherAttribution; do not draw an imitation. Place the mark beside the persistent “Weather sources” link below weather content, outside movable sheets and above the bottom safe area. Settings/Sources repeats the full legal links; settings alone is insufficient for this design. [WeatherKit attribution requirements](https://developer.apple.com/weatherkit/) · [WeatherAttribution](https://developer.apple.com/documentation/weatherkit/weatherattribution).

**This pack follows the user’s no-real-logo rule:** all mockups reserve that area using plain “Apple Weather · Weather sources” text. It demonstrates location and contrast, not production-compliant artwork. A shipping WeatherKit version must replace the text placeholder with the official mark. This design pack asserts no waiver of attribution.

**OSM — verified, 7 October 2026:** credit contributors and identify ODbL. Keep “© OpenStreetMap contributors” visibly linked to the copyright/licence page whenever the 3D map is visible, including full-screen playback and cached views. Proposed placement is the persistent source strip; it must not disappear behind warning sheets. Preserve additional world-package data credits in Sources. [OSM copyright and attribution](https://www.openstreetmap.org/copyright).

**NWS — verified source, proposed placement:** the NWS API supplies forecasts, observations and alerts. Show “National Weather Service” next to every warning’s issuer and official link; show station source on observation detail. Repeat it in Sources. Use plain text, no NOAA/NWS seal. This proposed source credit is not a claim of an API-specific mandatory logo. [NWS API](https://www.weather.gov/documentation/services-web-api) · [NWS Alerts documentation](https://www.weather.gov/documentation/services-web-alerts), checked 7 October 2026.

Production default: take US warnings directly from NWS; preserve official headline, body, instructions, times and identifiers. Show original text in an expandable panel, no AI rewrite. If alerts instead arrive through WeatherKit, additionally preserve Apple’s supplied alert-details link and full issuing-agency name, and do not modify the official text, as Apple requires. Do not merge two feeds into duplicate warnings.

## Style, motion and performance

Reference inputs: look-fix-v1, paintover-v1, night-v1 vocabulary. Calm cream/teal interface around the rich stylized world; broad lawn/material colour, clustered crowns and real light falloff, no photo textures. Values and labels must stay legible independently of world contrast. Minimum proposed body 17 pt, source/badge 12 pt, controls 44×44 pt; Dynamic Type reflows the panel and reduces world height. Labels use words and icons, not colour alone. VoiceOver reads value, units, category, valid time and freshness together.

Forecast playback is a sequence of estimates, not a promise of minute-level timing. Hold mapped geometry fixed; blend sky/lighting/weather, move shadows with the engine solar model, animate bounded wind/precipitation. Pause at missing hours and expose the gap. Reduce Motion disables auto camera flights and particle/sway movement while preserving state changes. Scrub gestures have step buttons and adjustable accessibility actions. Alerts freeze autoplay and expose readable text first.

Reuse WorldEngine’s existing ≤10 ms GPU / 60 fps target on iPhone 13-class devices; no extra reflection, volumetric or whole-world shadow pass. Broad wetness and fog must read without heavy particles. Sparse night emitters, bounded lights and existing synthetic wet streaks; no sensor inference from window lights. Stop continuous rendering when backgrounded or a static settings sheet covers the world. These are proposed constraints, not measured device results.

## Screen-specific acceptance rules

1. **Home block:** Every visible numeric weather value has its own source badge. Station details must include observation time and station identity in the expanded Sources view.
2. **Hour scrub:** Interpolation is visual only. Readouts snap to actual valid-hour records. No interpolation presented as an observation; missing intervals are grey/unavailable.
3. **NWS warning:** This screen is a SIMULATED warning example. Production warning is FORECAST · official warning, not proof the hazardous event is observed at the home.
4. **Rain:** Wetness is simulated from history. Precipitation probability differs from rate; no deterministic raindrop arrival at the house.
5. **Snow:** Missing accumulation history yields unknown ground coverage. Demo art is illustrative; production should neutralize unsupported coverage rather than initialize a blanket.
6. **Fog:** Area visibility forecast is not a measured sight distance on the user’s street; do not obscure the text with world fog.
7. **Night:** Lights do not reveal residents’ activity or smart-home telemetry. Reduce city star density; solar/moon models, geometry and weather govern production light.
8. **Settings + stale:** Mandatory local home storage is not a toggle. Warning permissions are optional; declining does not hide in-app warnings. Refresh never makes stale data live without a new valid fetch.

## Deliverables and limits

- 8 screen PNG concepts + 3 icon/name PNG direction boards in images/.
- PRODUCT-LOGIC.md: one-page product proposal; free/paid is a hypothesis, no price forecast.
- design-values.json: palette, screen intent, provenance and freshness policy.
- prompts.json: generation and single-edit history.
- manifest.json: dimensions, bytes and image hashes.
- index.html: local gallery only; it does not fetch weather or locations.
- VALIDATION.md and a ZIP of the complete pack.

Generated screens are raster concepts with illustrative houses, shadows, timing and meteorology; they are not pixel-perfect native layouts or engine captures. Exact geometry consistency across screens, data fetching, warning delivery, name clearance, accessibility and performance need implementation validation. All visible samples are synthetic, even where a badge demonstrates the future Observed or Forecast UI.
