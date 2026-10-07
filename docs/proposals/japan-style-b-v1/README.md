# Japan Style B v1 — r2 lane-scale correction

[Corrected gallery](index.html) · [Complete download](japan-style-b-v1-all-files.zip) · [Values](japan-values.json) · [Revision prompts](prompts.json) · [Superseded r1 gallery](superseded/r1-us-scale/index.html)

**7 October 2026 · Proposals only.** This revision supersedes r1's street geometry and composition. The previous pack, including all seasons, night, boards, values and its ZIP, is preserved in `superseded/r1-us-scale/`. It is retained for comparison, not as an accepted lane-scale reference.

## What changed

All eight archetype illustrations have their street context corrected. The street-character board, Tokyo lane and Kyoto summer base are rebuilt; Kyoto spring, autumn, light snow and night are regenerated from that corrected base. Sheets, boards, gallery and values follow the new images. The generic river skyline contains no lane and remains unchanged; it is not claimed to be a river view inside the Yanaka test area.

- **4–6 m wall-to-wall**, nominal **5 m**, using roughly 5–6 m house frontages and 5.8 m two-storey height as visual scale references. No curbs, raised sidewalks, lawn strips or broad sidewalk aprons. Flush thresholds, paint lines or a **10–20 cm** flush gutter edge only.
- Buildings and boundary walls meet the lane; eaves overhang toward it by a proposed **0.45–0.8 m**. New frontage setbacks are **0–0.3 m** for the lane-context sheets. Private gardens remain behind the frontage; no sidewalk-shaped garden strip.
- Short, slightly irregular views: staggered frontage and a gentle bend/dogleg around **25–35 m** limit the sightline. No endless straight US boulevard composition.
- Different frontages and eave heights, with traditional timber/machiya, workshops, pale modern houses and small concrete infill. The Kyoto lane is a living mixed neighbourhood, not an all-historic repeated-house set.
- Poles stand at the **asphalt lane edge**, not a sidewalk. At most **two near-camera poles / three major spans within 30 m** in these art presets; distant strands fade. No utility survey or clearance claim.
- Sparse pots and localized garden trees, unbranded vending cabinets and bicycles in recesses. Signs are blank colour slabs or simple fictional category tea/book silhouettes. No pseudo-kanji, readable brands, resident names, addresses, people or religious emblems. No Japanese textual labels without a later native-language review.

All numeric lane, bend, prop and envelope values above are **authored targets requested by the user**, not measured street surveys. AI concepts cannot prove metre scale; actual map geometry remains authoritative. The new pictures are checked for the requested enclosing proportions and flush-edge treatment, not certified against a solved camera.

## Named test-area context

Read `japan-showcase-v1/README.md` §“Two recommended test areas and Style B treatment,” plus its source register and dataset notes. Source hashes are recorded in the values JSON.

**Tokyo:** Yanaka Ginza and adjoining **Yanaka–Sendagi public lanes**, with varied low-rise homes, independent shops and small modern infill. **Kyoto:** **Nishijin**, the **Itsutsuji-dori / Omiya-dori** vicinity, as a mixed machiya/workshop/modern-infill context. The Kyoto concept is a side-lane study; it does not assert that the entire named main road has the requested five-metre width.

The showcase proposes approximately **600 × 600 m** windows but marks exact boundaries, camera coordinates, road widths and current geometry checks unverified. This revision follows those area choices and look notes, without claiming a surveyed scene, exact address, PLATEAU conversion or current engine render. No Japan source render was supplied. R1's Lakeview vanishing-road constraint is intentionally superseded.

The source pack's official-context links include [Yanaka Ginza](https://www.gotokyo.org/en/spot/170/index.html), [Yanaka/Nezu backstreets](https://www.gotokyo.org/en/story/walks-and-tours/yanaka-and-nezu/), [Nishijin exterior-view context](https://global.kyoto.travel/en/faq/detail.php?faq_id=1015) and [Kyoto landscape plan](https://www.city.kyoto.lg.jp/tokei/page/0000281270.html). These are inherited research references, not freshly measured camera/width evidence. All depicted mixes and proportions remain proposals.

## Lighting, materials and sheet format

Daytime `sharedLighting` and approved contrast witnesses remain **unchanged** from house-contrast-v1 and house-archetypes-v1: sun **#FFE8C6**, elevation **40°**, azimuth **225°**; sky **#73A5CC / #A2C4DC / #DBDCD1**; neutral shadow cue **#7F8F99**; exposure **+0.35 EV**, contrast **1.06**, saturation **1.08**, applied once. No per-scene lavender/pink grade or yellow outlines.

The original v1 CSS/sheet structure remains: street/aerial pair, six geometry fields, four palette variants, three phone tiers and access/yard notes. `surfaceValuesProposal` gives Japan hexes and sRGB-decoded linear luminance/relative brightness; inherited Chicago values are comparison witnesses, not Japan wall colours.

Smooth forms and plain matte surfaces; no photo textures. Machiya lattice, broad eave shadow, roof-edge silhouette, modern balcony bands and compact entry voids do the visual work. Fine roof/foliage marks in art are not a runtime geometry requirement. The open gate has zero enclosed floors; the mixed-block footprint is an envelope with distinct 2–3-storey components. Neither should be treated as an ordinary house extrusion.

The four Kyoto seasons share the **corrected summer base**, its camera, facade order and original localized tree positions. Summer is a byte-identical alias. Sakura changes the right cherry; momiji changes the left maple; light snow adds thin caps/edge pockets while keeping the central lane mostly clear. No calendar/weather forecast is implied.

Night uses the **exact copied night-fog-v1 night state**, windows and streetlight limits: direct sun **0**, sky **#15243C / #243854 / #344255**, sky fill **0.24**, ground fill **0.08**, exposure **+0.35 EV** once, haze **#475568**, extinction **0.002 / m**, no ground fog. Window-aperture lit share **0.30**, warm **#F3D0A0**. Plain lantern dimensions/emission remain art proposals; no point light per lantern/window. At most **six pool fields / two actual unshadowed lights** shared across all emitters. Night replaces the daytime state rather than stacking it. Golden-hour river state remains separately authored, not the afternoon fixture.

## Performance and provenance

Retain v1 building-height tiers: **<6 px** silhouette/colour; **6–20 px** entry/eave/voids; **>20 px** broad windows, trim and sparse lattice. No subpixel slat/spoke/strand detail. Batch near props and utility bundles; no per-wire draws or wire shadows. Add no daytime lights, global passes or shadow maps; fit the existing geometry budgets. No A16 benchmark is claimed.

Built-in image_gen performs the revisions and requested season/night edits. Prompts and selected-output hashes are saved. HTML typography and PNG board/sheet exports come from the browser. No engine code, builds, map downloads or git commands. Older source packs remain unchanged.

## Verification

All **15 revised artworks** were visually reviewed for enclosing proportions, flush lane edges, varied frontage and short/bending views. All eight specification sheets and four boards were re-exported. The seasons board and a full sheet were inspected. At **390 px**, all **17 gallery images load**, with no horizontal overflow or page errors.

The shared daylight and copied night settings remain exactly equal to r1/approved inputs. Summer remains a byte-identical corrected-base alias. The river image is unchanged. Before active replacement, every previous root file was confirmed byte-identical to its superseded copy; source input hashes were checked.

Meter widths and sightline lengths are authored targets, not camera-solved measurements. These area-inspired illustrations do not establish exact surveyed Yanaka/Nishijin geometry. Minor AI variant details can differ; use the base composition and numeric values as design references.
