# Regional car mix v1

Open [index.html](index.html). Twelve regional sheets each contain street and45° aerial views, body/colour/BEV/age/parking targets, shared rain-film/salt/snow witnesses, dimensions and density examples. The additional material atlas is linked separately. PNG posters are in sheets/; scene artwork is in images/.

[values.json](values.json) provides12 regional defaults, seven mutually exclusive body classes, BEV as a separate powertrain overlay, separate parked/moving body percentages, colour percentages, metre dimensions, plate proxies and all12×5street classes×5local-hour density cases. Body/colour/location/age totals are validated. Shared calibration-v2 values are copied unchanged.

All fine city body and colour mixes, age distributions, parking shares, density/time profiles and material-state parameters are labelled **UNVERIFIED AUTHORING FIXTURES**. Canada’s national 2024 SUV/crossover 41.9% and passenger 35% aggregates are verified national proxies; subdivisions and local transfers remain estimates. Japan’s38% kei fixture is informed by a37.716% national mini-passenger share, not an observed Tokyo sample. EV refers to BEV in this kit: Canada’s5.2% reported EV includes hybrids and is not used as BEV share.

[research.md](research.md) explains registration-vs-production-vs-visible-traffic distinctions. [sources.md](sources.md) links primary registration, colour, driving and plate sources with status. Country defaults show representative urban/suburban streets, not one national look. One-way topology, curb restrictions, driveway and pad geometry always override priors. The weather atlas is shared; regional notes control when each state is eligible. No automatic snow/salt or regional damage stereotype.

Artwork is conceptual, not a registered camera pair, measured traffic sample, physical vehicle geometry specification or engine screenshot. Exact in-engine counts/dimensions come from JSON; generated pictures illustrate form and mix. No logos, badges, plate text, dogs or app content are intended. The built-in image tool created scenes; exact prompts, selected revisions and provenance are saved in prompts.json.

No project files changed; no git used. Final verification: all 14 pages checked at 320, 390 and 1440 px (42 checks), with image loads and page overflow checked. Body/colour/age/parking totals, 300 density cases, exact calibration copy and local links also checked. Desktop Chrome viewport simulation only, not iPhone GPU testing. Reports and representative screenshots are in phone-check/.
