# WorldEngine landmark pack — Chicago + Denver · Style B

6 October 2026 · Proposal only.

28 fresh reference sheets: 18 Chicago and 10 Denver. Each reads left to right as street, aerial, dusk. [Open the gallery](index.html) or browse [images](images/). Names below identify locations for documentation only; generated scenes omit venue/team/university/sponsor names, logos and signs.

## Scope and evidence

**Verified** statements have a source and checked date in every entry. **Assumption** applies to all palette values, roughness, emission, occupancy, geometry caps, simplification advice and unsurveyed proportions. Images convey Style B lighting and massing; they are not measured reconstructions. A generated bay count, skyline position or street alignment never overrides mapped or surveyed data.

The latest user request adds Grant Park, the South Side ballpark, the Bean, United Center, Bahá’í Temple, Field Museum, Lower Wacker and Lake Shore Drive; Navy Pier and Northwestern were already included. Evanston and Wilmette are part of the Chicago-region selection. The user’s US Cellular Park means the South Side baseball stadium; its official current name is documented in its entry.

**User exception:** Cloud Gate/the Bean is included because the user explicitly requested it after the no-artwork instruction. All other public artwork remains excluded, including Cloud Gate from other sheets, the Picasso, Crown Fountain, athlete statues and museum plaza sculptures. Grant Park is a landscape/architecture precinct; fountain/monument features are deliberately excluded. Navy Pier uses buildings, not amusement rides.

## Style and construction

Preserve the major silhouette and relational plan first. Use calm material planes, broad sun/shadow contrast, restrained bevels, selective warm windows and grounded vegetation. Reuse look-fix-v1, paintover-v1 and house-details-v1 vocabulary. Avoid photo textures, dense masonry grain, outlined edges and miniature signage. Broad facade rhythms are colour or vertex patterns; only nearby silhouette-changing ledges and deep recesses earn geometry.

World coordinates are metres. Mapped footprint, height, orientation, shore geometry, road grade and layer/access data take precedence. Landmarks replace generic building meshes; do not render both. Inferred secondary masses are tagged inferred with source/confidence, never moved mapped data. Verify major roofs and plan from primary plans/field photos before construction. The sheets intentionally flatten figurative decoration to anonymous geometry.

At 50 m, retain large arches, entry recesses, colonnade rhythm and major roof/setback breaks. At 300 m, retain silhouette, large roof openings and material blocks; combine small detail into tonal bands. A tower is not automatically far LOD at 300 m: use projected feature size. The sheets are framing examples, not calibrated 50 m screenshots.

**Assumption / math:** p_draw ≈ H_draw × W / [2d tan(vFOV/2)]. Divide by actual render-to-logical-pixel ratio. With H_draw=700, vFOV=55°, ratio=3, a 1 m feature is 4.48 logical px at 50 m and 0.75 at 300 m. Drop below 1 logical px; use geometry only above 2 px if silhouette/depth justifies it. Crossfade LOD for 300 ms. Retain structure and real scale rather than enlarging details.

## Materials and dusk

[landmarks-colours.json](landmarks-colours.json) is the exact palette authority. [Chicago swatches](images/chicago-materials.svg) and [Denver swatches](images/denver-materials.svg) display those literal hex values; generated pixels are illustrative. Hex is sRGB; convert once to linear, leave albedo unchanged at night. Roughness/metallic are 0–1 renderer-neutral controls. Glass is opaque shaded colour. White temple surfaces represent **cast concrete**, not limestone. Painted steel uses nonmetallic coating response; bare metals use metallic response.

Night values are authored relative emission, not physical illuminance: diffuse white=1, typical warm windows #FFD09A at 1.2, neutral architectural light #F1E8D2, 18% window share for the pictured quiet dusk. These are reference settings only; environment.json time/weather and the night pack’s occupancy policy govern runtime. No promise of actual venue lighting schedules. Clouds, mountains and reflections follow actual weather, azimuth and visibility in production. The Bean has zero emission; use existing environment lighting or a cheap broad reflection approximation, with no new live capture. No stadium event show, billboard animation or facade artwork.

## Performance

**Verified against the local v2 proposal, checked 2026-10-06:** §8.1 sets sustained 60 fps, ≤10 ms GPU, 400k scene triangles, 150k shadow triangles and ≤100 scene draws; its times are provisional rather than device measurements.

| Existing v2 bucket | ms | Landmark treatment |
|---|---:|---|
| Base opaque | 4.25 | Replacement landmark meshes, shared material palette, opaque glazing |
| Shadows | 1.45 | Simplified caster meshes; no new shadow lights |
| Crown variation/sway | 0.15 | Existing vegetation rules only |
| Surface masks | 0.25 | Broad facade rhythm and existing ground/weather masks |
| Near geometry | 0.35 | Nearby bevel/recess selection |
| Wet light streaks | 0.35 | Existing synthetic lamp/window streaks only |
| Particles | 0.20 | No landmark-specific particles |
| Post processing | 0.90 | Existing grade/bloom/optional aerial treatment |
| Reserve | 2.10 | Preserve headroom; no assumed spend |
| Total | 10.00 | Shared whole-world envelope |

**Assumption / proposed subcaps:** all visible landmarks together ≤50k main triangles, ≤20k shadow triangles and ≤12 shared draws, inside the scene caps. Per-entry near/medium/far maxima are below and in JSON. These are ceilings, not guaranteed runtime costs; do not load the entire catalog at near LOD. Reduce peripheral/far detail when several landmarks share a view. No new SSAO, planar/SSR reflections, transparent interior pass or dynamic cubemap capture. Dome lace uses coarse nearby ribs and an opaque tonal representation at distance. Stadium seats are bands, not separate chairs. Park allees instance the vegetation pack. Record actual drawable size, GPU worst frames and thermals on iPhone 13 before acceptance.

## Reference catalog

### Chicago 01 — Willis Tower

[Street / aerial / dusk sheet](images/chicago-01-willis-tower.png)

**Verified, 2026-10-06:** Nine connected structural tubes form the stepped tower. [Source](https://www.architecture.org/online-resources/buildings-of-chicago/willis-tower/).

**Recognition priorities — authored assumptions:**

- Nine connected square tubes
- Unequal setback heights
- Dark vertical planes
- Bronze glazing bands
- Twin antenna silhouette
- Broad rectangular base

**Simplify:** Preserve bundle plan and every major setback; merge window mullions into broad bands; omit roof equipment below 2 logical pixels.

**50 m:** Retain nine connected square tubes, unequal setback heights, dark vertical planes, bronze glazing bands. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain nine connected square tubes and unequal setback heights. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** black-metal #30363D; bronze-glass #626B72; light-concrete #BFC3BF. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 5000/1800/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 02 — Wrigley Field area

[Street / aerial / dusk sheet](images/chicago-02-wrigley-area.png)

**Verified, 2026-10-06:** Ivy walls and the original scoreboard are documented. [Source](https://www.mlb.com/cubs/ballpark/information/history).

**Recognition priorities — authored assumptions:**

- Compact neighborhood stadium
- Brick street wall
- Blank entry marquee frame
- Ivy-colored outfield strip
- Open seating bowl
- Plain scoreboard mass

**Simplify:** Keep the neighborhood enclosure and bowl opening; group seat rows into bands; flatten brick courses and leave all marquee/scoreboard faces blank.

**50 m:** Retain compact neighborhood stadium, brick street wall, blank entry marquee frame, ivy-colored outfield strip. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain compact neighborhood stadium and brick street wall. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** red-brick #AA7359; dark-green-metal #3D554C; muted-turf #81915A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 10000/3000/800 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 03 — Soldier Field

[Street / aerial / dusk sheet](images/chicago-03-soldier-field.png)

**Verified, 2026-10-06:** The venue combines historic architecture with a modern stadium. [Source](https://www.soldierfield.com/stadium-info/about).

**Recognition priorities — authored assumptions:**

- Parallel classical colonnades
- Modern bowl above old base
- Asymmetric upper profile
- Oval seating geometry
- Pale stone versus cool metal
- Lakefront setbacks

**Simplify:** Keep the old-colonnade/new-bowl contrast; instance plain columns nearby, merge them into a rhythm band far away; omit sculpted ornament.

**50 m:** Retain parallel classical colonnades, modern bowl above old base, asymmetric upper profile, oval seating geometry. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain parallel classical colonnades and modern bowl above old base. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; cool-metal #A6AEB2; blue-glass #597787. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 10000/3000/800 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 04 — Chicago Riverwalk and bridges

[Street / aerial / dusk sheet](images/chicago-04-riverwalk-bridges.png)

**Verified, 2026-10-06:** The Riverwalk forms a sequence of lower riverside spaces. [Source](https://www.sasaki.com/projects/chicago-riverwalk/).

**Recognition priorities — authored assumptions:**

- Promenade below roadway
- Stepped river terraces
- Closed bascule crossing
- Dark bridge trusses
- Plain bridgehouse masses
- Continuous river street wall

**Simplify:** Keep vertical street/promenade separation and closed bridge geometry; reduce truss members at distance; omit rail pickets and deck seams.

**50 m:** Retain promenade below roadway, stepped river terraces, closed bascule crossing, dark bridge trusses. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain promenade below roadway and stepped river terraces. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; bridge-steel #5C4845; river-water #4E7780. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 05 — Navy Pier area

[Street / aerial / dusk sheet](images/chicago-05-navy-pier.png)

**Verified, 2026-10-06:** The pier has a landward headhouse and lakeward ballroom. [Source](https://www.wttw.com/navypier/timeline).

**Recognition priorities — authored assumptions:**

- Long narrow pier
- Landward headhouse
- Low linear halls
- Lakeward ballroom dome
- Broad lake surround
- Continuous waterfront edge

**Simplify:** Keep the long pier and opposite-end roof masses; merge low halls; omit amusements, boats and all decoration not needed for the building silhouette.

**50 m:** Retain long narrow pier, landward headhouse, low linear halls, lakeward ballroom dome. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain long narrow pier and landward headhouse. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; roof-grey #59616A; blue-glass #597787. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 06 — Northwestern lakefront campus (Evanston)

[Street / aerial / dusk sheet](images/chicago-06-northwestern-lakefront.png)

**Verified, 2026-10-06:** Deering Library has a Gothic limestone exterior. [Source](https://www.library.northwestern.edu/about/at-a-glance/libraries-art-architechture.html).

**Recognition priorities — authored assumptions:**

- Inland Gothic library
- Pointed window rhythm
- Modern lakefront glass mass
- Open campus lawns
- Lakefill shoreline
- Separation of old and new

**Simplify:** Keep the inland/waterfront split; merge buttresses and arch recesses at distance; simplify individual Gothic carvings and shoreline planting.

**50 m:** Retain inland gothic library, pointed window rhythm, modern lakefront glass mass, open campus lawns. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain inland gothic library and pointed window rhythm. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; blue-glass #597787; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 07 — Chicago Water Tower

[Street / aerial / dusk sheet](images/chicago-07-water-tower.png)

**Verified, 2026-10-06:** The Water Tower uses castellated Gothic forms and warm limestone. [Source](https://www.architecture.org/online-resources/buildings-of-chicago/chicago-water-tower).

**Recognition priorities — authored assumptions:**

- Slender central tower
- Octagonal shaft
- Castellated low base
- Pointed openings
- Buff limestone family
- Small footprint among tall buildings

**Simplify:** Keep octagonal tower and battlement silhouette; merge small turrets at distance; omit all carvings and stone joints.

**50 m:** Retain slender central tower, octagonal shaft, castellated low base, pointed openings. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain slender central tower and octagonal shaft. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** buff-stone #CBB99B; roof-grey #59616A; dark-glass #3B4C57. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 08 — Marina City

[Street / aerial / dusk sheet](images/chicago-08-marina-city.png)

**Verified, 2026-10-06:** Marina City has paired concrete towers with radial balconies. [Source](https://www.architecture.org/online-resources/buildings-of-chicago/marina-city).

**Recognition priorities — authored assumptions:**

- Paired circular towers
- Scalloped balcony silhouette
- Equal tower height
- Radial floor plates
- Open lower parking bands
- Shared low podium

**Simplify:** Keep equal tower heights and scalloped outer contour; merge balcony stacks into shaded bands; omit handrails and parked cars.

**50 m:** Retain paired circular towers, scalloped balcony silhouette, equal tower height, radial floor plates. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain paired circular towers and scalloped balcony silhouette. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-concrete #C8C8BD; dark-glass #3B4C57; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 5000/1800/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 09 — Merchandise Mart

[Street / aerial / dusk sheet](images/chicago-09-merchandise-mart.png)

**Verified, 2026-10-06:** The Mart is a large limestone Art Deco riverfront block. [Source](https://www.architecture.org/online-resources/buildings-of-chicago/merchandise-mart).

**Recognition priorities — authored assumptions:**

- Very broad riverfront block
- Horizontal limestone mass
- Dense regular bay rhythm
- Stepped upper crown
- Deep base entry
- Roof setbacks

**Simplify:** Keep broad block and upper setbacks; turn regular bays into a quiet surface pattern; omit carved panels and facade projections.

**50 m:** Retain very broad riverfront block, horizontal limestone mass, dense regular bay rhythm, stepped upper crown. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain very broad riverfront block and horizontal limestone mass. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** buff-stone #CBB99B; dark-glass #3B4C57; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 10 — Rookery

[Street / aerial / dusk sheet](images/chicago-10-rookery.png)

**Verified, 2026-10-06:** The Rookery exterior combines brick and granite. [Source](https://www.architecture.org/city-tours/rookery-building).

**Recognition priorities — authored assumptions:**

- Heavy granite base
- Red-brown brick upper walls
- Large entry arch
- Horizontal stringcourses
- Grouped arched bays
- Central light court

**Simplify:** Keep entry arch, stringcourses and roof court; flatten brick/stone joints; omit figurative ornament.

**50 m:** Retain heavy granite base, red-brown brick upper walls, large entry arch, horizontal stringcourses. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain heavy granite base and red-brown brick upper walls. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** deep-red-brick #8C5145; red-granite #9A6557; dark-glass #3B4C57. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 01 — Colorado State Capitol

[Street / aerial / dusk sheet](images/denver-01-state-capitol.png)

**Verified, 2026-10-06:** The Capitol has grey granite walls and a gold dome. [Source](https://content.leg.colorado.gov/Visit-Learn).

**Recognition priorities — authored assumptions:**

- Central gold dome
- Columned dome drum
- Symmetrical civic wings
- Grey granite planes
- Broad stairs
- Plain pediment porticos

**Simplify:** Keep dome, drum, wings and stairs; reduce columns at distance; remove inscriptions, flags and statuary.

**50 m:** Retain central gold dome, columned dome drum, symmetrical civic wings, grey granite planes. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain central gold dome and columned dome drum. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** grey-granite #B2B5AF; gold-metal #C3A361; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 02 — Coors Field

[Street / aerial / dusk sheet](images/denver-02-coors-field.png)

**Verified, 2026-10-06:** Brick and a signature entry clock tower are documented by an installation contractor. [Source](https://www.fordav.com/projects/coors-field/).

**Recognition priorities — authored assumptions:**

- Curved brick entry
- Plain clock above entrance
- Dark green structural frame
- Open baseball bowl
- Broad outfield opening
- Warehouse street context

**Simplify:** Keep brick entry and plain clock mass; use seat-color bands; remove ads, scoreboard content and seat hardware.

**50 m:** Retain curved brick entry, plain clock above entrance, dark green structural frame, open baseball bowl. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain curved brick entry and plain clock above entrance. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** red-brick #AA7359; dark-green-metal #3D554C; muted-turf #81915A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 10000/3000/800 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 03 — Red Rocks Amphitheatre

[Street / aerial / dusk sheet](images/denver-03-red-rocks.png)

**Verified, 2026-10-06:** The amphitheatre seats lie between large sandstone formations. [Source](https://www.redrocksonline.com/our-story/history/).

**Recognition priorities — authored assumptions:**

- Two inclined sandstone walls
- Seating between rock walls
- Descending terrace rows
- Low stage roof
- Stone stair aisles
- Terrain rather than isolated pedestal

**Simplify:** Keep the two rock-wall slopes and seating relationship; terrace rows become bands at distance; omit individual stone chips and concert equipment.

**50 m:** Retain two inclined sandstone walls, seating between rock walls, descending terrace rows, low stage roof. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain two inclined sandstone walls and seating between rock walls. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** red-sandstone #B77655; weathered-concrete #B5B1A5; dark-stage-metal #40484D. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 8500/2500/600 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 04 — Denver Union Station

[Street / aerial / dusk sheet](images/denver-04-union-station.png)

**Verified, 2026-10-06:** The terminal was rebuilt in 1914. [Source](https://www.denverunionstation.com/about/our-history/).

**Recognition priorities — authored assumptions:**

- Tall central terminal hall
- Long low masonry wings
- Grouped arch windows
- Plain facade clock
- Front plaza
- Rear white rail canopy

**Simplify:** Keep tall hall/low-wing composition and front/rear relationship; merge window divisions; remove the lettering frame entirely.

**50 m:** Retain tall central terminal hall, long low masonry wings, grouped arch windows, plain facade clock. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain tall central terminal hall and long low masonry wings. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; roof-grey #59616A; canopy-white #DDDCD2. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 05 — Sloan’s Lake park

[Street / aerial / dusk sheet](images/denver-05-sloans-lake.png)

**Verified, 2026-10-06:** A city project record documents boathouse improvements. [Source](https://www.denvergov.org/content/dam/denvergov/Portals/642/documents/Better_Denver/final/BDBond-project-1.04.18.01.pdf).

**Recognition priorities — authored assumptions:**

- Broad lake basin
- Continuous shoreline path
- Low support building
- Lawn strip
- Spaced shade trees
- Low surrounding neighborhood

**Simplify:** Use actual lake outline and mapped support footprint; keep the support building low and schematic until surveyed; omit decorative towers and invented arcades.

**50 m:** Retain broad lake basin, continuous shoreline path, low support building, lawn strip. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain broad lake basin and continuous shoreline path. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** buff-stone #CBB99B; path-concrete #C3C0B5; lake-water #547F91. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 8000/2000/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 06 — Denver skyline from City Park

[Street / aerial / dusk sheet](images/denver-06-city-park-skyline.png)

**Verified, 2026-10-06:** The master plan treats downtown and mountain views as park assets. [Source](https://denvergov.org/files/assets/public/v/1/parks-and-recreation/documents/planning/citypark_2018_masterplan_part1.pdf).

**Recognition priorities — authored assumptions:**

- Park foreground
- Lake and pavilion
- Red pavilion roof family
- Separated downtown skyline
- Distinctive skyline crowns
- Distant mountain layer

**Simplify:** Keep park/skyline/mountain separation; use surveyed skyline masses; simplify pavilion arches and roof tiles. Generated skyline placement is illustrative.

**50 m:** Retain park foreground, lake and pavilion, red pavilion roof family, separated downtown skyline. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain park foreground and lake and pavilion. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** buff-stone #CBB99B; tile-roof #98694F; blue-glass #597787. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 07 — Daniels & Fisher Tower

[Street / aerial / dusk sheet](images/denver-07-daniels-fisher.png)

**Verified, 2026-10-06:** The tower has a square shaft, clock faces and an arched upper level. [Source](https://history.denverlibrary.org/building/daniels-and-fishers-clock-tower).

**Recognition priorities — authored assumptions:**

- Slender square shaft
- Pale brick/terracotta family
- Large clock circles
- Arched belfry
- Pyramidal cap
- Small street-level base

**Simplify:** Keep square slender shaft, large clock circles, belfry and pyramid; drop numerals and tiny masonry joints.

**50 m:** Retain slender square shaft, pale brick/terracotta family, large clock circles, arched belfry. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain slender square shaft and pale brick/terracotta family. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** buff-brick #B9A07D; pale-stone #D5CCB8; tile-roof #98694F. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 5000/1800/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 08 — Brown Palace

[Street / aerial / dusk sheet](images/denver-08-brown-palace.png)

**Verified, 2026-10-06:** The hotel uses red granite and sandstone. [Source](https://www.historichotels.org/us/hotels-resorts/the-brown-palace-hotel-and-spa-autograph-collection/history).

**Recognition priorities — authored assumptions:**

- Triangular block plan
- Rounded wedge corner
- Sandstone upper walls
- Dark granite base
- Horizontal sill bands
- Heavy cornice

**Simplify:** Keep triangular plan and rounded corner; merge bay rhythm far away; omit carved medallions and hotel branding.

**50 m:** Retain triangular block plan, rounded wedge corner, sandstone upper walls, dark granite base. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain triangular block plan and rounded wedge corner. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** red-sandstone #B77655; dark-granite #68645D; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 09 — Denver Art Museum — Hamilton Building

[Street / aerial / dusk sheet](images/denver-09-hamilton-building.png)

**Verified, 2026-10-06:** The contractor documents the Hamilton Building’s angular titanium-clad construction. [Source](https://www.mortenson.com/projects/denver-art-museum-frederic-c-hamilton-building).

**Recognition priorities — authored assumptions:**

- Faceted metallic volumes
- Strong cantilever
- Sloping walls
- Sharp roof silhouette
- Glass seams
- Open plaza

**Simplify:** Keep major facets and cantilever; merge titanium panel seams; omit plaza artworks and exhibition banners.

**50 m:** Retain faceted metallic volumes, strong cantilever, sloping walls, sharp roof silhouette. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain faceted metallic volumes and strong cantilever. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** titanium-grey #A7ACAD; blue-glass #597787; path-concrete #C3C0B5. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Denver 10 — Denver Central Library

[Street / aerial / dusk sheet](images/denver-10-central-library.png)

**Verified, 2026-10-06:** The library documents Michael Graves’s postmodern addition. [Source](https://www.denverlibrary.org/content/michael-graves).

**Recognition priorities — authored assumptions:**

- Ochre and buff blocks
- Rounded tower volume
- Stepped roof forms
- Green-grey roof family
- Geometric entry rhythm
- Restrained window grid

**Simplify:** Keep warm/cool geometric masses; merge window grids; omit names and decorative graphics.

**50 m:** Retain ochre and buff blocks, rounded tower volume, stepped roof forms, green-grey roof family. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain ochre and buff blocks and rounded tower volume. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** ochre-wall #BEA174; buff-stone #CBB99B; green-grey-metal #727E71. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 11 — Grant Park

[Street / aerial / dusk sheet](images/chicago-11-grant-park.png)

**Verified, 2026-10-06:** The Park District documents Grant Park as a formal lakefront park. [Source](https://www.chicagoparkdistrict.com/parks-facilities/grant-ulysses-park).

**Recognition priorities — authored assumptions:**

- Rectangular lawns
- Straight axial paths
- Tree allees
- Lakeward edge
- Michigan Avenue street wall
- Broad paved terraces

**Simplify:** Keep formal path/lawn axes and the lakeward edge; tree allees become grouped crowns far away; omit fountains, monuments and seasonal event infrastructure.

**50 m:** Retain rectangular lawns, straight axial paths, tree allees, lakeward edge. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain rectangular lawns and straight axial paths. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** muted-turf #81915A; path-concrete #C3C0B5; lake-water #547F91. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 8000/2000/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 12 — South Side ballpark (user: US Cellular Park)

[Street / aerial / dusk sheet](images/chicago-12-south-side-ballpark.png)

**Verified, 2026-10-06:** The current official ballpark name is Rate Field. [Source](https://www.mlb.com/whitesox/ballpark).

**Recognition priorities — authored assumptions:**

- Modern baseball seating bowl
- Broad grandstand tiers
- Masonry entry envelope
- Dark upper structure
- Plain scoreboard masses
- Open surrounding access area

**Simplify:** Keep modern bowl and access-space contrast with Wrigley; merge seats and floodlight hardware; blank all scoreboards and field marks.

**50 m:** Retain modern baseball seating bowl, broad grandstand tiers, masonry entry envelope, dark upper structure. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain modern baseball seating bowl and broad grandstand tiers. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** red-brick #AA7359; pale-stone #D5CCB8; dark-stage-metal #40484D. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 10000/3000/800 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 13 — Cloud Gate / the Bean — explicit user exception

[Street / aerial / dusk sheet](images/chicago-13-cloud-gate.png)

**Verified, 2026-10-06:** The fabricator documents seamless welded stainless-steel construction. [Source](https://jnicktaylor.com/portfolio/anish-kapoors-cloud-gate/).

**Recognition priorities — authored assumptions:**

- Squat kidney silhouette
- Seamless reflective skin
- Concave underside arch
- Two ground contact lobes
- Asymmetric rounded profile
- Plaza and skyline reflections

**Simplify:** Keep kidney outline and underside opening; smooth the surface with a modest mesh; approximate reflections with existing environment blocks; no extra live capture.

**50 m:** Retain squat kidney silhouette, seamless reflective skin, concave underside arch, two ground contact lobes. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain squat kidney silhouette and seamless reflective skin. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** polished-steel #BAC2C5; path-concrete #C3C0B5; blue-glass #597787. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 0; 0% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 2500/800/200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

**Exception:** User explicitly requested Cloud Gate, overriding exclusion of this one public artwork. No other artwork permitted.

### Chicago 14 — United Center

[Street / aerial / dusk sheet](images/chicago-14-united-center.png)

**Verified, 2026-10-06:** The operator identifies the building as an enclosed sports and entertainment arena. [Source](https://www.unitedcenter.com/venue/introduction-history/).

**Recognition priorities — authored assumptions:**

- Enclosed arena roof
- Broad low mass
- Repeated entrance piers
- Concrete wall family
- Brick entry accents
- Tall glass vestibules

**Simplify:** Keep enclosed roof and broad entrance rhythm; merge piers and glass bays at distance; omit all venue/team names and athlete statues.

**50 m:** Retain enclosed arena roof, broad low mass, repeated entrance piers, concrete wall family. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain enclosed arena roof and broad low mass. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-concrete #C8C8BD; red-brick #AA7359; roof-grey #59616A. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 10000/3000/800 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 15 — Bahá’í House of Worship (Wilmette)

[Street / aerial / dusk sheet](images/chicago-15-bahai-temple.png)

**Verified, 2026-10-06:** The ornamental exterior is white cast concrete, including dome panels. [Source](https://www.bahai.us/bahai-temple-welcome/architecture/).

**Recognition priorities — authored assumptions:**

- Ninefold radial plan
- Tall central dome
- Repeated entry arches
- Open geometric dome ribs
- Slender exterior pylons
- Formal garden approaches

**Simplify:** Keep ninefold plan and tall dome; retain coarse open ribs nearby, replace fine lace with opaque tonal pattern far away; omit religious glyphs and inscriptions.

**50 m:** Retain ninefold radial plan, tall central dome, repeated entry arches, open geometric dome ribs. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain ninefold radial plan and tall central dome. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** white-cast-concrete #DEDCD2; dark-glass #3B4C57; muted-turf #81915A. Roughness/metallic in JSON.

**Dusk:** #F1E8D2; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 16 — Field Museum

[Street / aerial / dusk sheet](images/chicago-16-field-museum.png)

**Verified, 2026-10-06:** The museum documents its monumental classical building. [Source](https://www.fieldmuseum.org/page/architecture).

**Recognition priorities — authored assumptions:**

- Broad symmetrical museum
- Central pediment portico
- Large column rhythm
- Monumental stairs
- Long low wings
- Roof courts and light wells

**Simplify:** Keep central portico, long wings and stairs; columns become broad rhythm at distance; remove figurative relief and exhibition banners.

**50 m:** Retain broad symmetrical museum, central pediment portico, large column rhythm, monumental stairs. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain broad symmetrical museum and central pediment portico. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-stone #D5CCB8; roof-grey #59616A; dark-glass #3B4C57. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 4500/1500/400 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

### Chicago 17 — Lower Wacker Drive

[Street / aerial / dusk sheet](images/chicago-17-lower-wacker.png)

**Verified, 2026-10-06:** The engineering paper documents a double-deck roadway. [Source](https://www.pci.org/PCI_Docs/Papers/2002/Variations-on-the-Structural-Scheme-for-Wacker-Drive-Reconstruction.pdf).

**Recognition priorities — authored assumptions:**

- Separated road decks
- Massive support piers
- Repeated cross beams
- Covered lower perspective
- Open portals where mapped
- Upper road continuity

**Simplify:** Keep independent road levels and mapped ramps; reduce small crossbeam details; cutaway is documentation only. Never flatten distinct levels into one road.

**50 m:** Retain separated road decks, massive support piers, repeated cross beams, covered lower perspective. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain separated road decks and massive support piers. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** pale-concrete #C8C8BD; dark-stage-metal #40484D; path-concrete #C3C0B5. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.6; 5% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 12000/4000/1200 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

**Exception:** Aerial is an explanatory cutaway; never transparent production geometry. Additional mapped road levels must be preserved.

### Chicago 18 — Lake Shore Drive

[Street / aerial / dusk sheet](images/chicago-18-lake-shore-drive.png)

**Verified, 2026-10-06:** The Park District documents the lakefront trail corridor. [Source](https://www.chicagoparkdistrict.com/lakefront-trail).

**Recognition priorities — authored assumptions:**

- Flat lake shoreline
- Curving road alignment
- Parallel separated trail
- Park lawn strip
- Inland building wall
- Continuous water-road-park layers

**Simplify:** Keep actual shoreline/road/trail separation and grade; use broad road surfaces; omit lane micro-wear and signs at distance.

**50 m:** Retain flat lake shoreline, curving road alignment, parallel separated trail, park lawn strip. Model only recesses/edges exceeding 2 logical pixels; tower/precinct may extend outside view.

**300 m:** Retain flat lake shoreline and curving road alignment. Merge fine bay, seat, joint and railing detail into calm planes. Large assets may still require medium LOD.

**Materials:** road-asphalt #606773; path-concrete #C3C0B5; lake-water #547F91. Roughness/metallic in JSON.

**Dusk:** #FFD09A; relative emission 1.2; 18% selected window area/bays as an illustrative setting; no added shadow lights.

**Proposed mesh ceiling:** 8000/2000/500 triangles near/medium/far. Includes landmark primary mesh, not already-budgeted surrounding vegetation/ground.

## Image limitations and production checks

All sheets are freshly generated concept references, with at most one targeted edit per sheet; prompts and edit history are preserved in [prompts.json](prompts.json). Proportions, surrounding skylines and shore alignments can be invented. Willis requires the surveyed nine-tube plan and proper river separation; Soldier Field requires the actual asymmetric bowl/colonnade layout; the temple requires a measured nine-sided plan; Sloan’s Lake’s low support building is schematic, not a verified building likeness. City Park skyline and pavilion details need georeferenced verification. Lower Wacker’s open riverward face is illustrative and must not be repeated where walls close the actual roadway; preserve additional mapped lower levels and ramps. Navy Pier’s ballroom and Northwestern’s modern building need roof references before detailed modeling. Written recognition rules take precedence over image inaccuracies.

**Legal production guardrails, user-defined:** no logos, team/university/sponsor names, ads, banners or readable in-world signage. Names in this document are identifiers only. Remove sculpted figurative decoration rather than tracing it. Architecture and the one user-requested artwork exception are design scope decisions, not a representation of rights clearance; no legal permission is asserted by this pack. No images scraped from source pages; links support research only. Generated OSM footer is a conceptual credit, not proof that a sheet uses measured OSM geometry. Actual mapped views must keep their existing map attribution.

## Five recommendations

1. Build silhouette and footprint first; use the six recognition priorities before spending detail triangles.
2. Prioritize the lakefront chain—Grant Park, Field Museum, Soldier Field, Navy Pier, Lake Shore Drive—for a coherent Chicago test walk/aerial view.
3. Give Lower Wacker real layer/grade data; use the cutaway only to review structure.
4. Keep one shared material palette and replace ordinary footprint meshes; gate views with multiple landmarks against shared caps.
5. Verify the Bean’s arch, temple’s ninefold plan and stadium layouts from surveyed references before implementing the concept sheets.
