# Status

**R approved – 2026-10-08.** Approved as the B2B licensing demo design.

**Owner lane:** owner. **Phase:** B2B licensing demo (web), after the look gate.

An internal B2B web mock for licensing WorldEngine to other businesses: a landing page with a three.js Denver-style scene, four fictional customer pages, an embed builder with iframe, SDK and MapLibre snippets, price-placeholder tiers, and a research page on four map vendors' terms.

Binding rules from the pack:
- The OpenStreetMap credit ('© OpenStreetMap contributors', linked to the copyright page) stays visible in every viewport. The configure page can only move it bottom-left or bottom-right; it cannot be disabled. NOAA/NWS weather credit sits beside it.
- Never show the bundled weather as live. Show the source (NOAA station KDEN, an airport, not street weather), the observation time and stale or error labels. Rain, night and clear presets are simulations and must not replace the real observation. No forecast or alert feed is implemented.
- Nothing is published or sold: no real customer logos, endorsements, customer contact, tokens, SLA, billing or licence. Customer, venue and property names are fictional. Tier names and prices are placeholders. SDK and MapLibre snippets are proposed APIs on .example domains, not shipped packages.
- Do not publish a WorldEngine uptime percentage until infrastructure, monitoring and the contract support it: a target is not an SLA. Publish coverage and freshness instead of implying every street has measured height, exact daylight or a local weather station.
- An iframe, SDK or plug-in is a delivery path, not a data right. Review viewer software, cloud use, third-party data, customer models, redistribution and OEM scope, and service commitment separately. The customer owns uploaded material; hosting and processing permissions must be explicit.
- Look: inherit Style B calibration v2 unchanged; the procedural scene approximates it and claims no pixel match. The scene leaves out people, logos, dogs and unrelated app content.

Authored or unverified: (1) Vendor prices, terms and the pack's readings of them (for example, Cesium needs an integration licence to ship inside another firm's product) come from vendor pages dated 7 Oct 2026. Not spot-checked by us. The pack says it is no legal opinion. (2) Everything about WorldEngine's offer is authored: tier names, the 'annual minimum plus capped sessions' price idea, SDK package names (@worldengine/viewer, @worldengine/maplibre), iframe address, buyer needs (inferred, no interviews) and customer examples. No demand or willingness to pay is shown. (3) The 3D scene is synthetic box geometry with a simple sun formula (not NOAA's calculator; elevation and azimuth unverified). It does not match Style B frames and is not OSM data. Checks ran in headless Chrome with software WebGL; no physical phone or performance test.

Flags for R:
- Look: the three.js scene colours (sky #A2C4DC, fog #DBDCD1) and style-b-values.json are the pale pre-correction values; R's images-beat-JSON rule corrected the sky to #7AAFE2, #8FBAE7, #A0C8F2. The box-building scene also looks far from the Style B frames shown on the same page. Calibration-v2 owns look and wins; do not compile this pack's values.
- Order of the licensing path: the roadmap (PROPOSED) puts the web viewer with the streaming core first, then a MapLibre SDK, then an iframe viewer. This demo and web-stack-v1 (delivered, not binding) go iframe, then JS SDK, then MapLibre. R has not decided, so unclear which order wins.
- Engine stays generic (CLAUDE.md): the embed builder, scoped tokens, tiers, SDK and iframe are service and product layers, not engine code. The vendored three.js and its MIT notice are third-party and must not be compiled into the engine or counted as agent-built. The owner log (6 Oct) puts the web renderer after the look gate.
- Not on the lawyer list (Q1 to Q55): SLA and service-credit wording, usage-metered pricing terms, accuracy claims in real-estate and news embeds (sun and 'park nearby'), and the demo's 'defined embed and OEM scope' and 'clear data rights' claims beyond Q15 (ODbL flow-down). Add these before any pilot or outreach.

Not compiled into `mock-values.json`: this content is for the Builder phase, and the engine stays generic (CLAUDE.md).
