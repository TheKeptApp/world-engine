# Neighborhood Jobs Game v1

WorldEngine Neighborhood product lead concept • internal only • 7 October 2026

**A cozy jobs game in a recognizable real neighbourhood.** Choose a job, plan a short route on real street geometry, do a satisfying physical task in the rendered world, earn game credits, and improve a fictional workshop. Weather makes today different; completed work leaves a visible mark. Common Ground supplies cooperative goals. Gather remains a secondary planning mode after Builder.

## What the player actually does

Play from anywhere on a normal phone. The player drives an in-game plow or rides an in-game bicycle; the phone never tracks a real journey. Manually choose Denver or Chicago and a broad play district, not a home address. Buildings resemble the real streets, but customers are generated game roles. No real resident names, occupancy, deliveries, municipal service status or household habits are represented.

A session takes roughly 5–12 minutes (authoring target). Pick from eligible jobs, preview the fictional route, then use simple steering plus one task action. A plow pushes a snow mask off a road segment; a paper toss lands on a generated front-walk point. Mowing direction leaves stripes; raking gathers leaf litter into a small heap. The pleasure is the before/after change, quiet tool sounds, familiar architecture and competent craft. No forced hurry, punishment for missing a day, or physical travel requirement.

## Core loop

1. **Pick:** job cards show the real-world trigger, data freshness, source confidence and gameplay duration. Unknown conditions do not become pretend observations.
2. **Route:** select a short connected real-street circuit. Job stops are anonymous generated targets such as “Stop 3”, never an address or resident. Route lines describe the player's current game session, not human activity.
3. **Do:** steer, clear, cut or toss. Reduced-motion, steering assist and tap-to-complete options give equivalent rewards. Camera and task controls support one-handed play; no precise joystick requirement.
4. **Earn:** earn credits for completion/coverage, with transparent fixed rewards. Coins have no cash value. Missing a toss permits retry, not a punitive fee.
5. **Upgrade:** earn functional alternatives through play; buy no power. Spend on a different blade feel, a cargo basket or mower pattern kit. Paid items are cosmetic only. Vehicle paint, tool finishes and fictional workshop decor make progress visible.
6. **Return:** persistent completed surfaces and new weather events give a reason to revisit. No streak debt, energy timer, loot box or paid weather bypass.

## Progression

Start with the standard plow and a walking paper bag; bike option unlocks after the first paper round. Three proposed tiers: Apprentice (learn controls), Reliable (new route lengths/tool handling choices), Craftsperson (pattern challenges and cosmetic workshop sets). Progress is local by default. Every job remains doable with standard equipment; unlocks change comfort, technique or choice rather than gating event rewards. Reward examples: short snow route 120 credits, short paper round 90, paint colour 200; these are untested economy proposals, not prices. No cross-player economy or resale.

Separate **skill mastery** (accuracy/coverage with no public ranking), **tool ownership** (earned variants) and **style collection** (cosmetics). Avoid upgrading speed until it turns cozy work into a grind. Monetized cosmetics cannot enlarge clearing width, improve traction, paper aim, eligibility, payout, or contribution weight. Accessibility assists are free and never reduce payout.

## Weather, daylight and availability

Snow jobs appear only after an eligible real snowfall event in the selected play area. A forecast alone can announce “may be available”, never activate plowing. Snow measurements have regional resolution; a district trigger is not proof of snow on every frontage. Daylight comes from place/date solar calculations. Paper routes are generated in the local dawn window and render that real dawn lighting. Once unlocked, the round can be completed later as an explicitly labeled recap using the captured time/weather snapshot; nobody has to wake at dawn. No fictitious current snow or paid time travel.

Growing season is species/site dependent. Rain can speed lawn growth only while grass is active and moisture-limited, with a cap; temperature, dormancy and unknown irrigation matter. Leaf jobs use foliage-seasons-v1's observations → validated models → labeled heuristics ladder. Declining leaf fraction produces litter; an orange canopy alone is not leaf-drop evidence. December lights are a calendar theme and not a claim about any real household.

## Persistent world contract

Road segment IDs, lane masks and walk-frontage masks bind gameplay to geometry. Maintain per-player, on-device `eventId + segmentId + clearedCoverage`; a plowed street remains cleared in that save through app restart and through the same snowfall event. New confirmed snowfall deposits only fresh accumulation; do not reset the entire world or re-pay duplicate completion. Melt reduces uncleared snow, never turns cleared pavement back into old snow. Repeated feed revisions deduplicate by source/event version. Unknown data freezes the last labeled snapshot; the current board says data unavailable. Historical practice is separate, clearly labeled and never contributes to a live snow-day goal.

Co-op is an abstract district project, not shared lane ownership. Each person's cleared map is private; no map of which player cleared which street. Common Ground receives optional anonymous completion units in delayed thresholded batches. Contributions are capped equally; paid or earned tools do not change social weight. Sparse groups see the project art without a count. Duplicate attempts should be limited with unlinkable tokens, not location/device tracking. Privacy design must be reviewed before real aggregation.

## Social and secondary modes

**Snow Day Together:** adults collectively complete a broad snow-event goal; delayed bands unlock a cosmetic community scene. Show no people dots, named contributors, footprints, live counts, heatmaps, attendance or exact street-by-street public progress. The scene is a fictional celebration, not a municipal clearance report.

**Common Ground:** keep the cooperative walking/browse challenges as an optional break from jobs. No route import or individual tracking. **Gather:** private conceptual public-place plans using Builder parts, separate from jobs and from customers. Never imply a player has permission to mow, plow or deliver at an actual property.

## Monetization hypotheses

- Cosmetic shop: fixed-price paint colours, non-branded tool finishes, bike baskets of identical capacity and workshop decoration. No randomized contents, expiry pressure or performance advantages.
- Optional seasonal collection pass: clearly listed cosmetics and decorative workshop chapters; no exclusive functional jobs, live weather access, earning multipliers, co-op weight or tool power. Missed seasonal content remains available in a collection archive. No daily completion quota required.
- Later organization licensing for curated place/content packs, without participant movement or home data. Pricing and willingness to pay remain unverified; test transparent hypothetical offers only during the prototype.

The enjoyable baseline and privacy are free. Do not create advertising tied to homes, routes, weather vulnerability or occupancy. A cozy adult game should not borrow gig-economy stress: no fictional customer abuse, rent/debt, payment penalties or grading pressure.

## Risks and decisions to test

Weather scarcity: Denver/Chicago may not snow during the 90-day calendar. Ship observed-event replay for testing, separate from live mode; Paper Route is the daily fallback. Thin game feel: validate plow snow response and paper flight before adding many jobs. Repetition: short authored route variants and lasting surface change, not more currencies. Scale: mask-based snow/grass/litter avoids per-flake geometry. Real-map errors: generated task points require valid frontage masks and stay outside windows/doors/private interiors. Creepy interpretation: explicitly label fictional customers, local progress and no resident data. Privacy leakage: map tile, weather query, log and invitation pipelines must not attach identities to areas. Mobile performance and data rights remain dependencies.
