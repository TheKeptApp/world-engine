# SF life kit v1

Open [index.html](index.html). Six category boards contain 22 scene studies, each in street/quayside, 45° aerial and far context. Every study also has an individual HTML sheet, artwork PNG and full-sheet PNG. Category-board PNGs collect the requested scenes with sizes, speeds, placement, hexes and projected-size tiers. The values are in [sf-life-values.json](sf-life-values.json); exact built-in imagegen prompts/input hashes/selected output hashes are in [prompts.json](prompts.json).

The lighting object is copied unchanged from SF-r2, and hill scenes retain 15–25% authored review grades plus a 30% stair-street overall profile. Houses remain vertical with level floors and stepped foundations. Marina/Mission/waterfront contexts stay relatively level where selected. Every route, pier, street, curb, overhead network, parklet, stair path and landmark sightline must come from the map. These are geographically plausible character studies, not surveyed intersections or registered capture paint-overs.

People use natural near-photoreal anatomy, posture, proportions and light with anonymous simplified faces. Vehicles have original generic silhouettes and plain liveries. The architecture remains rich Style B with matte simplified planes, small bevels and sparse narrow SF trees. No readable signs/plates/package labels, brands, logos, agency patches, murals, public art, dogs, leashed animals, app/host overlays, encampments or poverty stereotypes. Wild sea lions on a haul-out dock are expressly part of this kit; no staged pet interaction.

## What is delivered

- [Transit](01-transit.html): grip operator and running-board riders; paired trolleybus overhead network across an intersection; waterfront historic streetcar; commuter ferry.
- [Tech-city](02-tech-city.html): generic sensor-pod robotaxi, white shuttle coach/commuter queue, scooter corral/riders, uphill cyclists.
- [Shops/food](03-shops-food.html): Mission taqueria, corner store, curb-lane café parklet, Chinatown paper lanterns without text, waterfront market.
- [Workers](04-workers.html): generic mail carrier, delivery riders, two-person turntable push.
- [Hills](05-hills.html): downhill wheel-curbing, designated back-in angled bays, pedestrian stair street.
- [Water/fog](06-water-fog.html): sailing/container-ship scale, wild sea-lion float, half-hidden ship/bridge fog-horn atmosphere.

## Numbers and evidence

Dimensions and most speeds are **authored render/animation targets**, not surveyed fleet specifications. The cable-car cruise target is approximately 15.3 km/h, based on the Cable Car Museum's 9.5 mph description; speed is 0 at a stop, and 15.3 is not a journey-average speed. Generic trolleybus 12.2 × 2.55 × 3.5 m, coach 13 × 2.55 × 3.6 m, streetcar 14.3 × 2.55 × 3.4 m and ferry 38 × 10 m are selected plausible classes, not replicas of real models. Ship 250 × 38 m and 10 m sailboat proportions keep true scale; actual marine clearance/routes override. The wire targets 5.5 m above local road, 30 m support spacing, 0.6 m paired-contact separation and 8 m poles are **UNVERIFIED authoring numbers**, not SFMTA safety/engineering specifications.

All 24 local-hour envelopes, weekend/season multipliers and visible-subject caps are **UNVERIFIED activity priors**. They create typical-looking life without claiming to know actual people, traffic or fleet positions. Urban units are concurrent subjects per eligible 100 m block face; ferry/shipping counts use a 1 km water-view window; sea lions use one visible 12 × 6 m mapped dock. Riders, crew, vendors and stalls have separate count fields. Do not confuse concurrent counts with trips/hour or apply marine counts to street faces. Apply mapped site existence/service/event hours first, then an observed/licensed operational feed if available, then hour/weekend/season/weather fallback, round once and clamp. No eligible location means count 0. Markets require an active schedule. Sea-lion abundance varies substantially; the winter/summer multipliers are illustrative, not a census or guaranteed seasonal rule.

The default fog-horn clip is original authored ambience 2.5 s with a 120 s minimum repeat interval, **not a live horn report or a regulatory signal pattern**. Vessel position and weather must justify the sound source. The fog scene inherits SF-r2 western advection base 0 / top 360 m MSL, 180 m western visibility and a 350 m transition; do not put the whole downtown/east side under the same fog slab. Integrate density once in linear light before exposure.

## Build-cost priority at phone size

| Cost | What sells it | Dependency |
|---|---|---|
| Low | Plain coach/robotaxi/scooter silhouettes, blank awnings, tents/crates, parked cars and small worker groups | Mapped eligible POI/curb/site, stable count seed and local time |
| Low | Correct vehicle/person size, cast/contact shadows and SF attached pastel terrain context | DEM road pitch, vertical buildings and shared lighting |
| Medium | Running-board riders, cyclists leaning uphill, mail carrier stairs and turned parking wheels | Poses/foot-wheel ground contact, handedness and local grade |
| Medium | Parklet physically in parking lane, waterfront market hours and sea-lion broad resting shapes | Mapped curb/plaza/dock, clear walking route, site activity state |
| Medium | Ferries/sailboats/ships at true scale with soft wakes and regional fog occlusion | Marine lane/clearance, water plane and weather-density field |
| High | Paired trolley contact wires with switches/crossing frogs and trolley-pole contact | Actual overhead topology; road-relative clearances; antialiased wire LOD |
| High | Turntable rotation with two pushing workers, rider boarding and close human hand contact | Terminal pad geometry, episodic animation and synchronized hand/foot contact |

The wheel-curbing study adds a close 3–5 m witness view; other urban street studies use 15–20 m framing.

Below 6 projected pixels, keep correct-scale silhouettes/masses; 6–20 px keep body posture and vehicle identity; above 20 px keep simple connections/turned wheels/props, while faces remain anonymous. Drop sub-2 px small details rather than inflate people or cars. Wire visibility has its own antialiased 0.6 px fade threshold; never thicken all wires into a cartoon cable net. These are image/readability checks, not phone GPU benchmarks.

## Placement details that matter

Cable car: underground cable slot, no trolley poles or overhead power; moving riders hold running-board grab rails. Trolleybus: two poles/two contact wires, paired route network and actual crossing hardware, no rail needed. Historic streetcar: one overhead contact system and rails, waterfront only in this pack. Cable-car turntable: level terminal pad, manual crew push, riders wait outside rotating zone. The current sheets contain no elevated neighborhood railway.

Downhill parallel-parking study turns wheels toward curb. Uphill with a curb requires the opposite steering direction so rollback meets the curb; do not apply the downhill sign everywhere. Angled parking is back-in and only at mapped designated bays. Stair streets are pedestrian paths, not car routes. Stair riser 0.165 m / tread 0.30 m and 12-riser flights / 1.8 m landings are authored components; overall 30% profile uses landings and mixed flights, not a single continuous stair flight with a 30% riser/tread ratio.

Parklet deck is in the parking lane beyond the curb, leaving a 2 m clear sidewalk and real entry. These are visual dimensions, not a permit-compliance design. Scooter corrals preserve walking space. Lanterns are text-free decorative props on a mapped Chinatown street, not invented costume/folk-art stereotypes. Workers represent ordinary city routines, with no personal identity or actual employer inferred.

[Primary sources](sources.md) distinguish documented mechanisms/locations from authored numerical targets. [Verification](verification.json) records phone-width, image/link and lighting checks plus the visual audit. No renderer integration, live-data hookup or device performance benchmark is claimed. No git; nothing was written to repository docs/proposals.

Phone layout: all 29 HTML pages passed at 320 and 390 CSS pixels. Preview captures: [gallery](phone-gallery-preview.png) and [cable-car study](phone-study-preview.png).
