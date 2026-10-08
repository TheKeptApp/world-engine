# Pack usage: who uses which pack, and when

Maintained by A3; P3's filing is retained (R, 8 Oct 2026). Owner lane is the lane that builds from the pack; phase is when. Phases follow `docs/roadmap.md` (look gate now; Builder phase and the ambient life layer after it; launch countries; data release). Where R did not name a phase, it is P3's reading and R can change it. Status of each pack is in `docs/design-registry.md` and `docs/proposals/INDEX.md`; look is owned by `style-b-calibration-v2`.

## Approved by R on 8 Oct 2026

| Pack | Owner lane | Phase | What it is used for |
|---|---|---|---|
| chicago-denver-life-v1 | P2, 5A, L1 | Ambient life layer, after the look gate (test locations Chicago and Denver) | People, vehicles, props and counts for Chicago and Denver street life; one actor pool; game-day crowds only when verified. |
| nyc-life-v1 | P2, 5A, L1 | Ambient life layer, after the look gate (hero market New York) | Street-life actors, motion presets and object sizes for New York; one actor pool; events only when verified. |
| sf-life-v1 | P2, 5A, L1 | Ambient life layer, after the look gate (hero market San Francisco) | Street-life activity, overhead wires, trolleybus and streetcar placement for San Francisco; one actor pool; events only when verified. |
| nyc-hero-v1 | P2, 5A, P1 | Hero market New York, after the look gate | New York archetypes, streets, infrastructure, bridges and canyon lighting cases. |
| us-metros-wave2-v1 | P2, P1, 5A | US metro expansion; San Francisco is a hero market (SF r2); after the look gate | Eight metros plus San Francisco revision 2: archetypes, districts and block paint-overs; SF r2 slope, lot, tree and fog values. |
| us-metros-wave3-v1 | P2, P1 | US metro expansion, after the look gate | Twelve more metros' houses and districts. |
| weather-moments-v1 | 5A, L1 | Weather states (look gate and the alive layer); NYC board included | Weather moments by region, with the NYC verification board; live-state policy for observation against forecast. |
| venues-campuses-v1 | Builder, P2 | Builder phase (after the engine look gate) | Venue, event and campus parts for the Builder; not engine content. |
| regional-car-mix-v1 | P2 | Ambient vehicles, after the look gate | Regional vehicle mixes, plates, densities and hour profiles for P2's ambient vehicles. |
| mexico-australia-v1 | P2, P1 | Launch countries Mexico and Australia | Mexico (Mexico City, Guadalajara) and Australia (Sydney, Melbourne) archetypes, districts, trees, streets and lawns; Australia drives on the left. |
| mountain-terrain-v1 | P1, 5A, P0 | Engine capability: terrain, slope and mountains | Front Range mountain terrain, elevation bands, snow history, DEM by distance, haze, LOD and hiking trails. |
| creator-kit-ux-v3 | Builder | Builder phase, after the engine look gate | Easy and Pro creator kit UX (app design, not engine). |
| greenville-sc-v1 | P1, P2 | Test location 3 | Greenville, SC regional content for R's third test location. |
| metro-data-coverage-v1 | A1 | Data release (A1 coverage/import QA) | Per-metro data coverage; P1 import order: New York and Amsterdam are the best next; only GREEN datasets are loaded; red flags listed in the pack. |
| live-flights-v1 | A1 (live-world later) | Source/privacy QA now; launch integration later (live flights ON) | Live flight design and airport audit; adsb.lol hosted feed, airliners only. |
| real-flights-path-v1 | A1 (live-world later) | Backend/source QA now; live-world launch integration later | The adsb.lol path to real flights: pooled backend, airliners only, no actual gate assignments. |
| uk-style-b-v1 | P2, P1 | Launch country UK (left-hand traffic), after the look gate | UK archetypes, districts, streets, trees and lawns; the UK drives on the left. |
| netherlands-style-b-v1 | P2, P1 | Launch country Netherlands, after the look gate | Netherlands archetypes, districts, streets with cycling infrastructure, trees and seasons. |
| canada-style-b-v2 | P2, P1 | Launch country Canada, after the look gate | Toronto, Vancouver and Montreal archetypes, districts, trees, snow and street details; supersedes canada-style-b-v1. |
| seasonal-holiday-life-v1 | P2, 5A, L1 | Ambient life layer, after the look gate | Seasonal and holiday street life: actors, props and decorations; one actor pool; holiday events only when verified. |
| race-organizer-ops-v1 | Builder | Builder phase (after the engine look gate) | Race organiser operations rules and layouts for the Builder; not engine content. |
| builder-event-templates-v1 | Builder | Builder phase (after the engine look gate) | Event templates (festival, market and similar) for the Builder; not engine content. |
| neighborhood-product-v1 | owner, Builder | Product design (app, not engine) | The jobs game product study (jobs-game/); app design, not engine. |
| licensing-demo-v1 | A2 web/W1 | B2B licensing demo (web), after the look gate | Internal B2B licensing demo design: landing page, SDK snippets, pricing placeholders and customer examples; not engine content. |

## Approved by R on 7 Oct 2026

| Pack | Owner lane | Phase | What it is used for |
|---|---|---|---|
| terrain-slope-v1 | P1, P2, 5A | Engine capability: terrain and slope | Floors level, foundations from the footprint, breaklines, stairs, retaining walls, mesh budget. |
| road-signs-signals-v1 | P2 | Launch countries | Signs and signals everywhere; all markings outside the US. |
| water-surfaces-v1 | 5A, L1 | Water mechanics | Wave terms, foam, shore types, ice gating, live inputs, budget (mechanics only). |
| infrastructure-kit-v1 | P2 | Infrastructure stages | Roads, bridges, rail, airports, water, utilities, parks look; US lane markings and crosswalks. |
| foliage-seasons-v1 | P2, 5A | Look gate (foliage) | Species crowns, season colours, city mixes. |
| style-b-calibration-v2 | 5A, P2, P3 | Look gate (the look owner) | Lighting, exposure, saturation, matte materials; the look-gate target. |
| landmarks-style-b-v2 | P2, P1 | Landmarks after the infrastructure stages and the v1 shells (SF and NYC first) | 65 landmark studies and 13 skylines for 13 metros. |
| house-archetypes-v1 | P2 | Look gate (houses) | Chicago, Denver and Miami house archetypes. |
| house-contrast-v1 | 5A, P2 | Look gate (daytime master) | The daytime lighting master and house contrast. |
| night-fog-v1 | 5A | Weather and night states | Night, blue hour, morning fog. |
| lake-winter-v1 | 5A | Water colour and winter | Lake water colour, ice, tree snow, old snow. |

## Delivered or research (R, 8 Oct 2026): filed, not binding

| Pack | Owner lane | Phase | What it is used for |
|---|---|---|---|
| mobile-rendering-v1 | 5A, P0 | After the look gate (streaming, device tiers hero / standard / floor) | Mobile rendering research; streaming-design.md and compatibility.md. |
| strategic-research-v1 | owner | Strategy | Strategic and data research. |
| data-layers-research-v1 | P1 | Data release | Data layers research (crop, water, terrain, tides, footprints). |
| street-trees-by-metro-v1 | P2, P1 | City kits (trees) | Street trees by metro. |
| regional-look-catalog-v1 | P1, P2 | City kits (regional looks) | Catalog of regional looks. |
| data-licence-check-v1 | P1, owner | Data release (licences) | Tree and city data licence check. |
| event-sitemap-ai-v1 | Builder | Builder phase | Event site map and AI layout design. |
| building-heights-v1 | P1, P2 | Data release | Building height sources and rules. |
| web-stack-v1 | owner, 5A | After the look gate (web viewer) | Web stack research. |
| street-geometry-rules-v1 | P1, P2 | Look gate and city kits (street geometry owner, R 7 Oct) | Street geometry rules by country and class. |
| country-shortlist-v1 | owner | Launch countries (decided: Canada, UK, Netherlands, Mexico, Australia, Japan) | Country shortlist research. |
| japan-showcase-v1 | P2, owner | Launch country Japan | Japan showcase research. |
| canada-style-b-v1 | P2 | Launch country Canada; superseded by canada-style-b-v2 (approved 8 Oct 2026) | Canada Style B sheets (Toronto, Vancouver). Superseded by canada-style-b-v2 (approved 8 Oct 2026). |
| japan-infrastructure-kit-v1 | P2 | Launch country Japan | Japan infrastructure kit. |
| metro-onboarding-v1 | P1 | City-kit checklist (onboarding) | Metro onboarding boxes, datasets and block mix; feeds the city-kit checklist. |
| live-layers-catalog-v1 | L1 | Live layers | Live layers catalog. |
| creator-kit-demand-v1 | owner | Builder demand | Creator kit demand research. |

## Parked (R, 8 Oct 2026)

| Pack | Owner lane | Phase | What it is used for |
|---|---|---|---|
| hyperlocal-weather-v1 | owner (R), P1 | Parked (Blocklight) | Blocklight hyperlocal weather research. |
| weather-block-design-v1 | owner (R) | Parked (Blocklight) | Blocklight weather-for-your-block design. |

## Not named in R's 8 Oct list: status unchanged

| Pack | Owner lane | Phase | What it is used for |
|---|---|---|---|
| osm-licence-v1 | owner, P1 | Licensing | OSM licence research (status unchanged). |

## Not filed

- `somewhere-brand`: R is deciding (8 Oct 2026); held by `Tools/lookloop/drop-hold.json`, never filed.
- `Southern`: not in the drop folder; awaiting R.

## Zips for R to move to the external drive (12 in the drop folder, 570 MB)

R's rule (8 Oct 2026): no zips are filed. These stay in the drop folder (nothing there is deleted); the four already in the owner's checkout from earlier filings are listed below and left in place.

| MB | Zip |
|---:|---|
| 104.3 | `japan-style-b-v1/japan-style-b-v1-all-files.zip` |
| 80.2 | `house-archetypes-v2/house-archetypes-v2-all-files.zip` |
| 72.0 | `foliage-seasons-v1/foliage-seasons-v1-complete.zip` |
| 53.7 | `landmarks-v1/landmarks-v1-all.zip` |
| 52.4 | `water-surfaces-v1/water-surfaces-v1.zip` |
| 51.9 | `builder-event-templates-v1/builder-event-templates-v1.zip` |
| 51.3 | `japan-style-b-v1/superseded/r1-us-scale/japan-style-b-v1-all-files.zip` |
| 42.5 | `japan-infrastructure-kit-v1/japan-infrastructure-kit-v1-all-files.zip` |
| 31.1 | `japan-regional-kit-v1/japan-regional-kit-v1-all-files.zip` |
| 15.7 | `weather-block-design-v1/weather-block-design-v1-all.zip` |
| 14.8 | `road-signs-signals-v1/road-signs-signals-v1.zip` |
| 0.0 | `metro-data-coverage-v1/metro-data-coverage-v1.zip` |

Already in the owner's checkout (gitignored, left in place):

| MB | Zip |
|---:|---|
| 53.7 | `docs/proposals/landmarks-v1/landmarks-v1-all.zip` |
| 52.4 | `docs/proposals/water-surfaces-v1/water-surfaces-v1.zip` |
| 15.7 | `docs/proposals/weather-block-design-v1/weather-block-design-v1-all.zip` |
| 14.8 | `docs/proposals/road-signs-signals-v1/road-signs-signals-v1.zip` |

## Haze visibility — R approval, 8 Oct 2026

| Pack | Status | Owner lane | Phase | Usage / precedence |
|---|---|---|---|---|
| [haze-visibility-v1](proposals/haze-visibility-v1/STATUS.md) | Approved by R (8 Oct 2026) | A2 now; 5A on restart | Map/look gate now; 5A weather-moments migration on restart | 5% MOR, not 2%; field-level haze overrides for lake-winter-v1, weather-moments-v1, mountain-terrain-v1 and night-fog-v1. Mountain retained contrast ≥0.05 AND projected height ≥2 px; preserve real DEM sightlines and local fog. Integration pending lane evidence. |

## Facade and concept filing — 8 Oct 2026

| Pack | Status | Owner / prospective consumer lane | Phase | Scope |
|---|---|---|---|---|
| [facade-detail-v1](proposals/facade-detail-v1/STATUS.md) | APPROVED by R (8 Oct 2026) | A2 and P2 | Map/look gate now | Facade families, bays, trim, porch and window junctions. Far: massing/colour bands; mid: bays/trim; near: geometry. Calibration-v2 owns simplification. |
| [sky-cloud-v1](proposals/sky-cloud-v1/STATUS.md) | concept pending approval | 5A; A2 web reference review only | Pending R approval; no implementation authorization | World-angle sky gradients and sparse unequal cumulus; haze-visibility-v1 remains the approved haze authority. |
| [street-ground-v1](proposals/street-ground-v1/STATUS.md) | concept pending approval | P2; 5A for surface response; A2 web reference review only | Pending R approval; no implementation authorization | Regional seasonal ground junctions; existing mapped widths, markings and wet-surface authorities remain. |
| [crown-silhouettes-v2](proposals/crown-silhouettes-v2/STATUS.md) | concept pending approval | P2; 5A for colour; A2 web reference review only | Pending R approval; no implementation authorization | Layered species crown candidates and distance detail; no verified abundance ranking or automatic supersession of approved foliage packs. |
