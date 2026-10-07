# Ambient Life Kit · Style B v1

Design proposal, 2026-10-07. **A few readable movements should make the world feel inhabited; detail and population must never compete with its geography, lighting or phone performance.**

Open **index.html** in a browser for three illustrated reference sheets, phone-width comparisons, asset filters, recolour swatches, the complete values and a small moving density diagram. On Mac, double-click index.html or drag it into Safari. It works without a server or network after opening because the values are embedded. The JSON remains the authoritative design data; the page is a reference tool, not a WorldEngine renderer or downloadable mesh library.

## Contents and evidence

- index.html — offline gallery and simple synthetic motion instrument.
- ambient-life-values.json — all34asset definitions,7effects, dimensions, palettes, screen-size tiers, animation and density caps.
- images/01-road-vehicles.png —15road forms.
- images/02-transport-wildlife.png — rail, air, water and animals.
- images/03-people-effects.png — faceless people, distance/size simplification and effects.
- prompts.json — exact built-in image-generation prompts and saved-output provenance.

**Source constraints:** WorldEngine visual-v2 §3.2–3.3 and §8.1, docs/VISUAL_DIRECTION.md, and existing look-fix/paintover/vegetation proposals read as local style anchors. The golden-hour reference uses approved v2 sun #FFC788 at normalized0.78, sky fill #B6BED0, ground fill #C0A487 and shadow tint #85829A. These are material/light inputs, not promised final pixel colors. The scene always inherits environment.json lighting, actual sun direction, weather and exposure: no independent vehicle key light, orange material tint or arbitrary HDR brightness.

**All new exact dimensions, palettes, speeds, densities, mesh counts and timings are author design assumptions**, not surveyed fleet standards, real population estimates or measured device costs. Image sheets are visual concepts; labels and silhouettes may contain generation approximations. JSON/note values take precedence. No external factual recommendation or source research is claimed here.

## Shape language

Hard surfaces use broad flat-color planes, modest silhouette bevels and rounded wheel cylinders. Organics use smooth simple volumes, readable limb/wing gaps and no facial features. No photo textures, authored surface imagery, panel-line noise, chrome sparkle, visible vehicle interiors, license plates, route numbers, personal clothing marks, badges, medical emblems, corporate logos or manufacturer styling. Generic class silhouettes are intentional; no actual fleet reconstruction is implied.

Sedan = low separate cabin/hood/trunk. SUV = taller enclosed cabin. Pickup = visibly open bed. Taxi = restrained warm gold and a plain roof block, no checkerboard. City bus = long simple window band; school bus = hooded ochre form. Van/box truck/semi separate by tall integrated body, rear cargo box, or tractor/trailer hitch. Emergency classes use body layout and restrained color, not real markings; roof light housings remain nonflashing by default. School/emergency colors are generic categorical cues, not a jurisdiction fleet claim.

Rail cars use window rhythm and articulated joints without operator livery. Commuter cars are long; light rail uses a low body/articulation. Aircraft recognition comes from wings, tail and engine/rotor placement, not airlines. Use correct mapped/entitled altitude and orientation, never enlarge aircraft toward camera to make them dramatic. Contrails are optional and default off when formation conditions are unknown.

Sailboats show mast/sail; motorboats low hull/open stern; ferries broad cabin decks; cargo ships a long hull and coarse cargo stacks. Cargo ships never appear on small lakes. Avoid physically implausible routes/wakes or deep boats on shallow water. Water wakes may be procedural simple strips; no fluid simulation.

People are adults with neutral proportion, smooth faceless heads and broad coat/limb shapes. Diverse neutral skin/clothing palette is stable per synthetic entity, not inferred from an actual person. Pedestrians, runners and cyclists differ by posture/motion. Groups2–4members keep normal space; no crowd-wall or identical synchronized clones. Small generic dogs remain secondary and attached to a pedestrian by a lead; both count against appropriate caps. Birds have thick wing silhouettes; ducks short necks, geese longer necks. Never promote an ambient dog into hero framing.

## Detail tiers at phone size

Use projected CSS-equivalent pixels at390px viewport width (convert actual drawable pixels by its scale); do not compare native pixels directly to CSS thresholds. A long vehicle/wing/hull uses projected longest dimension; a person uses projected height. Every asset uses three shared tiers:

| Tier | Screen extent | Retained detail |
|---|---|---|
| Near | ≥48px | Silhouette, cabin/head, limb/wheel gaps, broad bevels and up to2accent masses |
| Mid |16–47px | Merged mass/cabin, broad legs/wings; no thin frame/door handles/wheel spokes |
| Far |5–15px | Simple class silhouette and stable color; no tiny windows, mesh limbs or light housings |
| Optional subpixel |<5px | Cull optional life; required tracked data may use a separate accessible UI representation |

Illustrative people distances: near5–12m, mid12–35m, far35–80m; actual projection always wins. Never treat those ranges as simultaneous distance and screen gates. Change tier with15%hysteresis and0.4s hold, retaining entity identity; no size inflation. Facial/identity detail remains absent even near.

Animation poses may update30/15/8Hz by tier and interpolate at the renderer's frame rate. Simulation starts10Hz fixed-step with interpolated transforms. Distant pedestrians use whole-body translation and minimal pose; remove expensive joints before removing meaningful motion. Wheels rotate only near; rotor/prop disks avoid flicker. No cloth, hair, ragdolls or animal fur simulation.

## Recolouring

Every class has neutral-light sRGB body alternatives in JSON; glass #526878, tires #303942, trim #DAD5C6. Choose one coherent stable tuple per entity; do not assign random colors to every panel. Interpolate in linear light; apply seasonal/weather lighting through shared world materials. Opaque dark glass avoids sorting/interiors. Near body roughness0.65, glass0.28, tire0.95 are artistic starting values, renderer-specific response unmeasured. Limit three logical materials and share palette-indexed materials across instances. Emergency/nav colors are muted, not blinking warnings.

## How much life

The caps are **scene maximums**, not spawn quotas or added entitlements. Residential street default about30–50%of caps, quiet neighborhood20–40%, busy corridor50–75%; these are synthetic art assumptions. Actual entitled live transit may differ. Keep the immediate route clear and avoid empty-to-packed changes when orbiting.

| View | Vehicles | People | Animals | Rail consists | Aircraft | Boats | Ambient triangles / extra draws |
|---|---:|---:|---:|---:|---:|---:|---|
| Street |12|16|12|1|1|2|18k /8|
| Neighborhood |28|32|24|2|2|4|24k /10|
| Aerial |48|24|24|3|3|6|18k /10|

Counts are simultaneous **visible/active** maxima, spatially culled. Count each person in a group and each bird in a flock. A cyclist is one person asset, not a separately counted bicycle+person; parked bicycles count in opaque geometry and the optional prop policy. Rail counts consists but triangle count includes every visible car. Aircraft/boats/rail are allowed only where relevant. Parked vehicles are not active motion counts but still consume geometry/draw/occlusion budgets; initial parked cap equals active road cap, trading within the same total triangle ceiling.

Street: a few passing cars,2–6walkers, one cyclist when appropriate, occasional birds/ducks near water. Neighborhood: spread movement across connected routes; keep side streets quieter. Aerial: roads get sparse colored motion, people often culled, rail/boats remain larger visual cues. Do not fill every street simultaneously. School bus, taxi, emergency and freight shares are region/context-dependent; no blind class-frequency percentages are asserted.

Placement uses mapped connected roads/footways/tracks/navigable water, local direction/turn/access rules and safe object clearance. Missing navigation evidence means less life, not a fabricated route across lawns/private grounds. Generic ranges in JSON are art priors; verified live source dimensions/speeds override. Respect bridge/tunnel elevation, stop lines and rail crossing context. Do not show synthetic flows through known closed roads.

Population is seeded from existing stable world identifiers and semantic salts. Spawn outside foreground/at plausible occluded boundaries, not under camera; fade optional entities smoothly without changing known tracked positions. Authentic live motion carries observed/interpolated timestamps. Schedule simulation and synthetic ambience are clearly labeled in accessible source information, rather than masquerading as live crowds.

## Effects

Rain splashes: brief bright procedural rings and1–2drops on hard wet surfaces; prioritize falling-rain readability. Snow drift: low sparse ribbons only with loose snow+wind, not invented plowing history. Blowing leaves: opaque rust/gold meshes during plausible deciduous leaf fall. Steam: pale small known-vent or labeled synthetic puffs. Chimney smoke: a few pale gray wisps at existing plausible chimneys, not every house, not wildfire haze. Sprinklers: optional synthetic short arcs on eligible lawn, off rain/freezing or drought restriction/unknown watering policy.

The effects in JSON share existing particle/overdraw caps. Maximum150rain streaks OR100snowflakes;24airborne leaves,24splash rings,6drift ribbons,12steam puffs,12chimney puffs,24sprinkler segments are competing limits. Total transparent primitives≤160 and summed alpha footprint≤4%of screen are proposed checks, not guaranteed costs. Depth occlusion and shelter apply. No full-screen steam veil or layered smoke over the route. Fade/simplify effects before reducing primary geometry.

## Performance and build order

Existing v2 ceilings:60fps sustained,10msGPU total,400kmain triangles,150kshadow triangles,100main draws. The existing4.25msbase world covers ambient opaque additions; **proposed ambient opaque increment≤0.35ms is inside that bucket**, not added after it. Existing0.20msweather-particle and0.35mswet/local-light buckets remain shared. Reserve existing2.10mssafety margin. No cost was measured and the kit does not grant extra budget.

Instance repeated geometry by mesh/material/tier in spatially bounded groups; color indices share buffers. Use simple transform animation over skeletons where possible. Limit full cast shadows to nearest6road vehicles and8people within about35m initially; animals and distant life use optional cheap contact treatment only within the existing shadow/contact solution. Aircraft/contrails get no additional shadow solve. Emergency lights are nonflashing emissive housings; existing maximum2local unshadowed lights cover the entire scene, not2per vehicle.

Degrade: optional alpha effects → flock/group numbers → distant pose frequency → micro-detail → optional parked/active synthetic life. Keep known live positions correct; if they cannot be rendered, disclose suppression instead of changing coordinates. Pause hidden view simulation/rendering, honor reduced motion, limit frame rate/resolution for long-running views per host mode. The gallery is not evidence of actual renderer performance.

First build: sedan/SUV/van, pedestrian/cyclist, duck/flock, then city bus and simple ferry where source/navigation permits. Next rail and articulated freight. Later aircraft/helicopters/emergency variants and small effects. Measure sustained device frame time and heat with worst relevant rainy dusk plus active population before expanding density.

## Review checklist

- At390px width, near silhouettes recognize class without text/logo; mid loses detail cleanly; far reads as colored life without shimmer.
- No independent asset lighting or photo imagery; organics smooth, hard surfaces restrained.
- No real badges/logos/plates/faces/nameplates; no implied resident identity.
- No fake emergency, live crowd claim, unmapped shortcut or unsupported boat/rail/air route.
- Caps and triangle/draw totals apply together; effects trade against existing weather costs.
- Image sheets illustrate art direction; JSON and geometry rules are exact build targets.
