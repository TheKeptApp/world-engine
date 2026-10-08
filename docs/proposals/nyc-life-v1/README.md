# NYC LIFE KIT v1

Open **index.html** for the responsive gallery. This pack adds city life to the approved NYC hero world: near-real people and vehicles, rich matte Style B architecture, attached New York streets and the hero lighting family. All artwork is generic, with blank commercial fascia and no intended branding or detailed faces.

## Deliverables

- **32 native PNG triptychs / 96 view panels** in `images/`: street level, intended 45° aerial and far context.
- **32 HTML sheets and 32 PNG sheet exports** in `sheets/`.
- **Six category boards**, HTML and PNG, in `boards/`.
- **values.json**: version 1.0.0, object envelopes in metres; walking, riding, driving and water-motion speeds; explicit 6am/noon/6pm/11pm profiles for spring, summer, autumn and winter; street context and scenario conditions.
- **prompts.json** and **generation-manifest.json**: final prompt set, reference inputs, original generation paths, corrections and hashes.
- **checks/**: desktop/phone captures and complete layout verification.

## Sheet coverage

**Shops:** pizza by the slice, bodega/corner deli, laundromat, newsstand, diner, Chinatown produce stalls.

**Vendors:** street-food cart, hot dog cart, fruit stand and seasonal Christmas-tree seller.

**Workers:** mail carrier with cart, delivery e-bike riders, sanitation crew/truck, doorman and construction crew beneath a sidewalk shed.

**Vehicles:** yellow taxi, city bus, double-parked box trucks, ice-cream truck, fire engine, ambulance, horse carriage and pedicab.

**Rhythms:** pickup-night curbside bags, morning subway commuters, lunch queues, evening stoop sitting, alternate-side sweeper, snow plow/salt spreader and summer window AC units.

**Waterfront:** commuter ferry and park-lake rowboats.

All sheets retain three views. The far view shows activity as a small coherent cluster rather than pretending that faces, menus or individual tools remain readable at district distance. On a 390 px phone, the three panels stack vertically. PNG exports provide the desktop presentation; HTML adapts to phone width.

## Values conventions

Dimensions and speeds are **authored representative targets**, not measurements of exact suppliers, people or vehicles. Use JSON as the modeling authority; generated pixels do not certify scale, geometry, camera angle or physical light. No metric meshes, rigging or working animation engine are included.

Activity counts are **UNVERIFIED illustrative density presets**, not measured city averages. A block face means one 150 m street edge and adjacent carriageway; waterfront/park-lake profiles use an equivalent landing or bank reach. Counts are expected simultaneous visible instances, not per-hour throughput. Fractional values express expected occupancy and must be sampled to whole objects. Times are illustrative local clock hours rather than a live schedule.

Shop counts mean physical shop/kiosk/stall presence, including closed shops. Customer activity is a separate profile. Crew and carriage counts mean whole assemblies, including their people; do not count/spawn those components twice. Select a compatible district and scenario before combining families. Do not place all 32 activities on one block or add every count table together.

Christmas-tree sales activate only in the proposed 25 November–24 December window. Snow maintenance activates only during a selected winter clearing operation. Trash, collection and sweeping require an explicitly selected activity scenario; this is not a citywide schedule or a statement of current waste-container rules. Emergency vehicles are optional generic background activity, not inferred incidents or live dispatch. Summer AC counts represent installed units rather than active cooling. No legal speed limit is inferred from animation speeds.

## Generic appearance and light

People use natural proportions and ordinary varied clothing, viewed from side/back or at sufficient distance to avoid detailed faces. Uniforms omit agency insignia. Vehicle forms, body panels, destinations and plates are generic and blank. Shop awnings have no names; product packages and publication covers have abstract colors without readable text. No murals, copied public art, dogs, pets or animals walked on leads are intended.

The requested **carriage horse is the sole animal exception**: one horse harnessed to its carriage shafts, never walked on a lead. Rowboats contain people, not animals.

The NYC hero street-surface triptych is the visual reference for the new images. The clear-day hero-light block is retained in JSON as a reference; winter, snow, evening and night studies replace the applicable day conditions. Night trash scenes are dry; wetness does not automatically follow from the night-light reference. Match visual softness and masonry separation without claiming measured exposure or shadow bearings.

## Production and checks

Created with the **built-in image-generation tool**. Typography and numeric metadata sit outside the artwork. The final prompts and correction history are included. Browser checks cover every gallery, sheet and board at desktop and 390×844 phone width, including image loading, panel stacking, local links and horizontal overflow. This is a layout check, not a mobile rendering or crowd-simulation benchmark.

Saved only to the designated `worldengine-gpt-drop/nyc-life-v1/` output folder. No git, repository proposals, source maps, real-person images or live data were used or changed.
