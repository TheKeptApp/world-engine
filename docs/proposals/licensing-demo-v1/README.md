# WorldEngine licensing demo v1

Internal B2B design mock. Built in silence; no project files, git, real customer logos or customer contact. Nothing deployed or published.

## Review

Open `index.html` for the landing page. For interactive three.js scenes, run a local static server from this folder:

```sh
python3 -m http.server 8766 --bind 127.0.0.1
```

Then visit http://127.0.0.1:8766/. Direct file opening retains the reference-image fallback but module loading and weather fetching may be restricted.

- `index.html`: desktop/phone landing, layer controls, sun/weather, iframe → SDK → MapLibre code panel and pricing placeholders.
- `listing.html`, `event.html`, `story.html`, `explorer.html`: four fictional customer contexts.
- `configure.html`: area/radius, inherited look, layers, size, attribution placement, changing snippet and local JSON download.
- `research.html`: cited vendor pricing/licensing, caching/attribution, SLA/support benchmarks and proposed buyer evaluation checklist.
- `sources.md`: source register and evidence limits.
- `phone-check/`: desktop and 320/390 px captures plus interaction/layout checks.
- `assets/style-b-values.json`: unchanged Style B calibration v2 values. Reference frames copied unchanged from that pack. No animal/app content introduced.
- `vendor/`: pinned three.js r180 runtime and MIT licence, downloaded from jsDelivr. No external scripts/fonts required after download.

## Real versus simulated

The preview is a functional local three.js scene: orbit/zoom, layer visibility, shadows and rain/night fixtures work. Geometry is synthetic and Denver-inspired; no OSM geometry or production WorldEngine assets are imported. OSM attribution is intentionally visible in every viewport as the intended product treatment.

Sun direction is approximately calculated from latitude/longitude and device time; not a survey/engineering-grade daylight model. NOAA KDEN observations are real source responses, timestamped and identified as regional airport observations, not street conditions. Bundled snapshot is never presented as a continuously live feed; refresh makes an explicit optional public API request. Stale/error labels remain visible. No forecast or alert ingestion is implemented. Night/rain/clear presets are simulations and do not replace the displayed observation with invented values.

Style B values guide shared matte materials, simplified geometry, dark glazing, foliage and exposure. The procedural scene approximates the calibration and does not claim a pixel match. Existing calibrated frames are retained as visual reference/fallback. The scene intentionally omits people, logos, dogs and unrelated app content.

SDK/MapLibre snippets are proposed APIs on `.example` domains, not shipped packages. Pricing tiers are placeholders. No licence, token issuance, SLA, billing, publishing or customer submission occurs. Download creates a local mock configuration only. Area bounds are illustrative, not an actual geographic drawing tool. Customer/venue/property names and details are fictional.

## Check scope

Browser captures verify desktop and phone-sized Chrome viewports, image loading, no horizontal page overflow, visible attribution and controls, working layer toggles, code tabs, configuration update/download and weather fallback. They are not physical iPhone Safari/Android certification or a performance benchmark. Device/browser production QA and accessibility audit remain unverified.
