# Live Flights v1

[Open gallery](index.html) · [Full research and rights comparison](research.md) · [Airport audit](airport-audit.md)

Recommendation: seek a scoped FlightAware Firehose production contract for positions/surface/gates. AeroAPI prototype only after explicit 3D display approval; both published Standard and Premium licenses exclude commercial aircraft situational displays. Cirium is the fallback bid. No provider is fully cleared for WorldEngine plus a resale API by this research alone.

Phases: labelled approach demonstrations → observed airborne positions → validated airport stands and occupancy evidence. Never substitute scheduled gate assignment for occupied gate, or reconstructed taxi for observed taxi.

Contents: three calibration-v2 PNG mocks; full provider rights/coverage/freshness comparison; assumption-driven 1k/100k/1M cost scenarios; six measured OSM inventories/raw extracts; aircraft class mapping; privacy/LADD policy; values JSON; sources and prompts. All claims are marked verified, assumed or unverified. Provider marketing is not a measured SLA.

Gate completeness percentages and airport-specific feed accuracy remain unverified; counts are bounded OSM inventories. Custom provider fees/retention/resale rights require quotes and signed orders. Mock airports/paths are illustrative, not surveyed. No signups, purchases, git or project changes.

Image generation used the built-in imagegen tool; prompt set is in prompts.json. FlightAware, OSM and other provider attributions must follow actual applicable contracts/licenses in a shipping app; airline logos are absent from mock aircraft.

## Verification

24 deliverable files saved (Finder metadata excluded). Three PNGs visually reviewed; all gallery images and local links load. Desktop Chrome checks passed at390×844 and430×844 CSS pixels with no document horizontal overflow; the provider table scrolls within its container. Gallery phone screenshot inspected. All7 JSON files parse. Six raw OSM extracts parsed, with measured inventory counts recorded. This does not verify actual iPhone rendering, provider latency, gate accuracy or a license grant.

## File inventory

- [README.md](README.md)
- [airport-audit.md](airport-audit.md)
- [airport-gates.json](airport-gates.json)
- [cost-estimate.json](cost-estimate.json)
- [image-manifest.json](image-manifest.json)
- [images/01-chicago-approach.png](images/01-chicago-approach.png)
- [images/02-midway-taxi.png](images/02-midway-taxi.png)
- [images/03-denver-apron.png](images/03-denver-apron.png)
- [index.html](index.html)
- [osm-den-raw.osm](osm-den-raw.osm)
- [osm-gsp-raw.osm](osm-gsp-raw.osm)
- [osm-jfk-raw.osm](osm-jfk-raw.osm)
- [osm-mdw-raw.osm](osm-mdw-raw.osm)
- [osm-ord-raw.osm](osm-ord-raw.osm)
- [osm-sfo-raw.osm](osm-sfo-raw.osm)
- [phone-check.cjs](phone-check.cjs)
- [phone-check/390-gallery.png](phone-check/390-gallery.png)
- [phone-check/430-gallery.png](phone-check/430-gallery.png)
- [phone-check/report.json](phone-check/report.json)
- [prompts.json](prompts.json)
- [providers.json](providers.json)
- [research.md](research.md)
- [sources.md](sources.md)
- [values.json](values.json)
