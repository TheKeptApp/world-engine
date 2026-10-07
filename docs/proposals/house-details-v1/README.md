# WorldEngine house details v1 — Style B
6 October 2026 · Rich stylized · Design proposal for phone-size, street-level rendering

## Read first
Style B means simplified 3D shapes with soft bevels, clear silhouettes and rich saturated colour. Strong warm light, long soft cast shadows in a low-sun fixture, deep coloured shade beneath trees/eaves, bright highlights and atmospheric depth do the realism work. Keep building materials broad and smooth. No photo textures, individual bricks, shingles, blades, leaf noise or realistic cars. Trees use smooth unequal puff clusters, darker interiors and thick branching trunks.

The user's Style B clarification governs this pack. Read-only appearance references reviewed: Desktop/world-engine/docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md; paintover-v1/README.md and paintover-values.json; vegetation-v1/README.md; ground-v1/README.md; rain-v1/README.md; live-world-v1/README.md. Viewed look-fix-v1/images/lighting-03-ordinary-1530.png and paintover-v1/images/ordinary-street-paintover.png as image references. The project sources/ mirror was empty.

All dimensions, colour ranges, bevels and detail thresholds below are authored starting values, not surveyed house dimensions or measured device results. JSON and this document govern construction; incidental raster microdetail is not a requirement. The sheets are family concepts, not exact camera/scale tests or production meshes.

## Files
- 01-house-families.png — Tudor, Colonial, Prairie, Queen Anne, Chicago bungalow, two-flat.
- 02-urban-denver-families.png — greystone, courtyard, Denver bungalow/ranch/Victorian, porch close-up.
- 03-distance-and-bevel.svg — exact projection and bevel guidance.
- 04-material-colours.svg — exact six-material endpoint swatches for all 11 families.
- house-details-colours.json — 11 family records, six material slots each, shared glass/door/shutter/foundation/planting colours and roughness.
- image-prompts.json — final prompts, style inputs, generation provenance and discarded first draft.
- index.html — phone-width inspection of six panels per raster sheet plus exact charts.
- manifest.json — file sizes/hashes and validation limits.

## Family construction recipes
The eight main families mix styles, building forms and facade materials. A two-flat can also be a greystone; a bungalow can have Craftsman styling. Keep those axes separate in future asset metadata. Colonial here means Colonial Revival. Denver Victorian is a regional umbrella, illustrated as a compact brick vernacular/Queen Anne-influenced house; a turret is optional, never universal.

### Tudor
Identity: steep asymmetrical cross-gables, tall chimney, brick/stucco contrast and a compact entry. Porch/columns: small recessed or projecting entry shelter; use masonry jambs or plain timber supports, not a broad classical colonnade. Steps: short broad masonry stoop. Windows: vertically grouped casements in substantial surrounds; 2–3 major divisions, fine leaded diamonds painted only near. Shutters: normally omit. Eaves: tight 0.2–0.4 m overhang, distinct gable edge. Chimney: prominent 0.6–1.0 m wide shaft with simplified cap; omit tiny pots beyond near view. Dormer: occasional steep small gable; main cross-gable is not a dormer. Door: arched or heavy rectangular, dark wood, shallow recess. Plantings: low irregular cushions framing the entry, not hiding stucco/brick boundary.
Do not require half-timbering on every Tudor: brick-only versions retain roof and chimney identity.

### Colonial
Identity: balanced two-storey front, central entry and regular vertical sash rhythm. Porch/columns: small pedimented portico or restrained side porch; round/slender 0.18–0.28 m columns with one simplified base/capital. Steps: central symmetric stoop. Windows: white rectangular casings, sash meeting rail and a coarse 6-over-6 painted pattern near. Shutters: optional paired rectangles, each about half opening width; use plain slabs with broad colour, no louver geometry. Eaves: moderate 0.3–0.5 m overhang. Chimneys: one or two restrained end-wall masses. Dormers: optional symmetric gabled pair on side-gable roof; no random dormer scatter. Door: centred panel door with transom or sidelights as one readable frame. Plantings: paired low masses, broken at access.
Do not turn every Colonial into a full-width monumental porch.

### Prairie
Identity: low hip roof, very wide eaves, horizontal wall bands and grouped glazing. Porch/columns: broad square masonry piers, integrated terrace; 0.4–0.7 m supports rather than classical columns. Steps: broad low terrace steps. Windows: long groups with strong vertical mullions inside a continuous horizontal surround; geometric glass marks only near. Shutters: omit. Eaves: 0.8–1.2 m, thin fascia, continuous shadow beneath. Chimney: broad low rectangular mass integrated with the house. Dormers: omit in default exemplar. Door: sheltered/recessed, often offset, with simple wood/glass composition. Plantings: low spreading bands that reinforce horizontal mass.
Do not thicken the roof into a rounded cushion or substitute tall Victorian gables.

### Queen Anne
Identity: asymmetry, projecting bay, varied steep roof and expansive porch; turret optional. Porch/columns: wrap or partial wrap, slender 0.12–0.20 m posts with 2–3 coarse changes of profile and one bracket wedge; rail top/bottom with sparse broad uprights near. Steps: offset timber/masonry approach. Windows: tall sash, broad trim, occasional coloured upper sash represented by a few flat patches. Shutters: usually omit in this exemplar. Eaves: 0.3–0.6 m, prominent gable trim. Chimneys: one or two roof punctuation masses. Dormers: at most 1–2 well-placed gables, coordinated with main roof. Door: tall wood/glazed leaf, simplified transom. Plantings: informal low shrubs revealing porch posts and stair.
Use a coherent body/trim/accent set; avoid rainbow ornament, lace geometry and mandatory castle turrets.

### Chicago bungalow
Identity: narrow brick one-and-half-storey body, low hip roof, front window group/bay and small recessed entry. Porch/columns: recessed corner/side porch on stout masonry supports, not the Denver exemplar's obligatory broad front gable. Steps: raised basement produces a distinct stoop, typically 4–7 illustrative risers. Windows: 3–4 front sash units in one architectural frame; coarse transom or art-glass colour patches near. Shutters: omit. Eaves: 0.4–0.7 m. Chimney: modest brick shaft. Dormer: one centred hip or gable dormer on an optional variant; preserve its volume at distance. Door: side-front recessed door, one surround, no microscopic hardware. Plantings: compact strips beside stoop and bay; leave basement windows clear.
Brick is a colour mass with contrasting lintel/sill bands, never a mortar grid.

### Chicago two-flat
Identity: two full stacked residential storeys with repeated bays/window positions; default is narrow brick/parapet form. Porch/columns: shared side-front stoop and shallow covered entry; rear porches only where visible/supported. Steps: raised entry, opaque cheek walls and simple top rail. Windows: two vertically aligned polygonal bays, thick sills/lintels and tall sash; retain floor distinction. Shutters: omit. Eaves: flat roof hidden behind parapet; use projecting cornice rather than suburban roof overhang. Chimney: optional rear shaft. Dormers: none on this flat-roof variant. Door: shared vestibule may contain two apartment doors; do not force two exposed street doors on every asset. Plantings: tiny setback bed, not a suburban lawn.
Gable-front wood/masonry variants are legitimate. Two-flat means unit arrangement, not one roof style.

### Greystone
Identity: warm grey limestone front, tall stacked bays, raised stone stoop and strong cornice/parapet. Porch/columns: recessed entry with substantial stone jambs, occasional simple engaged columns. Steps: broad stone treads with solid cheek walls. Windows: deep surrounds, lintel/sill bands; carved ornament becomes a few large relief shapes. Shutters: omit. Eaves: modest cornice projection 0.25–0.5 m, roof concealed behind parapet. Chimney: optional brick rear shaft. Dormers: none in default urban exemplar. Door: tall dark glazed/panel door in deep shade. Plantings: 1–3 low masses in small fenced setback; avoid covering stoop/base.
Keep limestone front separate from cheaper side/rear brick. Not all greystones are two-flat buildings.

### Courtyard building
Identity: U-shaped or related multi-wing apartment mass with a real open court toward street, repeated windows and several entrances. Porch/columns: entry canopies, stone portals or short piers, not detached-house porches. Steps: individual short entry stoops; central walk remains continuous. Windows: repeated tall sash or grouped units, simple stone bands; use rhythm over tiny mullions. Shutters: omit. Eaves: parapet/cornice edges; flat roof default. Chimneys: small rear roof groups optional. Dormers: none in default. Doors: repeated recessed entrances with one strong central portal if exemplar supports it. Plantings: low courtyard beds with a central open walk, trees only where space permits.
At 50 m keep courtyard void and wing spacing; never collapse it into one solid slab or a painted black rectangle.

### Denver bungalow
Identity: low brick/Craftsman body, front-gable roof and substantial shaded front porch. Porch/columns: tapered square wood posts 0.25–0.4 m at base on 0.45–0.65 m brick piers; preserve taper and pier separation. Steps: broad 3–6 illustrative risers. Windows: grouped double-hung sash, chunky simple casing, coarse 3-over-1 marks near. Shutters: omit. Eaves: 0.6–0.9 m with 2–4 large rafter/bracket indications per visible face near. Chimney: modest brick mass. Dormers: occasional shed/gable on variants, not mandatory. Door: wood with one upper glass patch. Plantings: low green cushions and optional sparse xeric gravel beds, grounded in actual available frontage.
Hipped-roof Denver examples exist; this front-gabled exemplar deliberately separates from the Chicago default.

### Denver ranch
Identity: wide single-storey body, shallow roof and broad picture window. Porch/columns: modest recessed entry with slender square supports, 0.12–0.20 m; no bungalow taper by default. Steps: slab or 1–2 risers. Windows: picture pane plus smaller side units, thin broad casing; do not impose vertical Victorian sash rhythm. Shutters: optional simple decorative panels only on a supported variant, omitted by default. Eaves: 0.45–0.8 m thin continuous fascia. Chimney: low wide brick stack, optional. Dormers: omit. Door: simple offset flush/panel leaf, small glass patch. Plantings: scattered low shrubs, gravel/open lawn mix; don't assume every yard is xeric.
Garage mass only when mapped or selected variant supports it, never invented as a mandatory frontage.

### Denver Victorian
Identity: compact tall brick or siding body, steep front/cross-gable, tall sash and projecting bay. Porch/columns: small front/side porch with slim 0.12–0.20 m simplified turned posts and restrained brackets. Steps: raised 3–6 illustrative risers. Windows: tall narrow sash, light lintels/casings, coarse meeting rail. Shutters: uncommon in chosen exemplar; omit. Eaves: 0.3–0.5 m, strong contrasting gable board. Chimney: tall simple brick shaft. Dormers: optional small gable only if coherent with main roof. Door: tall panel/glass leaf, simple transom. Plantings: sparse low beds revealing brick base and entry.
Treat Queen Anne, Italianate and other Victorian variants as different subtypes rather than mixing every ornament into one house.

## Model / paint / drop at 10, 25 and 50 m
M = real geometry, including recesses and silhouettes. P = broad material/vertex-colour/procedural mask; no photo textures. D = remove. Distance is to feature, not building centroid. These are default tiers; projected size and grazing angles override. Primary silhouettes and access volumes remain geometry at every tier while the building is visible.

| Detail | 10 m | 25 m | 50 m |
|---|---|---|---|
| Roof profile, gables, bay, turret, courtyard void | M | M, fewer segments | M, coarse coherent volumes |
| Porch roof, primary columns/piers, entry recess | M | M, simple profiles | M; keep negative gaps and shadow |
| Steps | M treads/risers; cap nosing bevel | M stair envelope; P riser rhythm if subpixel | M stoop height + coarse ramp/wedge; D riser lines |
| Stair/porch rails | M top rail + few stout uprights if resolved | M only silhouette rail, P sparse divisions | D interior balusters; retain meaningful outer rail outline |
| Window opening, front door | M 4–8 cm recess or inset surface | M coarse recess where visible; P frame | P glazing/door masses; M major bay/portal |
| Outer casing, sill, lintel | M strongest 3–6 cm relief | P except strong projecting stone bands | P broad frame/band, D secondary profiles |
| Structural mullions between grouped units | M if thickness >=1.5 px | P unless silhouette/recess makes M necessary | P major group split if >=1 px; otherwise D |
| Fine glazing bars / leaded pattern | P only if >=1 px | D | D |
| Shutters | M plain slab; P broad face | P paired rectangles | P only if colour silhouette remains distinct |
| Eaves / overhang / cornice | M, keep underside shade | M, no small molding stack | M minimum distinct projection |
| Chimney / major dormer | M shaft/cap and dormer shell | M shaft and broad cap; simplify cheek trim | M primary silhouette only |
| Door panels/transom/handle | P panels, M major surround, optional handle only resolved | P glass/transom; D handle/panels | P one door region; D small divisions |
| Tudor half-timber bands | P broad bands, M only major projecting member | P simplify to major gable divisions | P only 2–3 strongest bands; never noise |
| Brackets, capitals, carved relief | M a few large blocks/wedges | P shadow/colour suggestion; M silhouette brackets | D non-silhouette decoration |
| Brick/mortar, siding courses, shingles | D individual marks at all tiers | D | D |
| Foundation planting | M 3–7 unequal smooth cushions; one flat bed | M 2–4 merged groups + P bed | M 1–2 masses only if resolved, otherwise P bed |
| Foundation/basement windows | M broad base, P small openings | M base, P openings | P base band; D subpixel windows |

Family survival contract:
| Family | 10 m strongest extra cue | 25 m keep modelled | 50 m recognition minimum |
|---|---|---|---|
| Tudor | arched entry and casement grouping | cross-gable + chimney + grouped openings | steep asymmetry + chimney + broad wall contrast |
| Colonial | portico/sash/shutter proportions | central portico and balanced opening rhythm | symmetry + central entry + roof |
| Prairie | square pier, grouped glazing, thin fascia | broad roof projection and horizontal bands | low roof + deep eave + long window groups |
| Queen Anne | post profile and bracket wedge | wrap porch + bay + roof/turret variant | asymmetry + porch silhouette + varied roof |
| Chicago bungalow | bay frame and raised stoop | low hip/dormer + front group + recessed entry | narrow low brick mass + hip + bay |
| Two-flat | shared stoop and repeated sash | stacked bays and two-storey rhythm | two floors + vertically repeated bay + parapet |
| Greystone | heavy surround and stone cheek walls | stone bay + cornice + raised stoop | pale stone front + stacked bay + strong crown |
| Courtyard | portals, walk and repeated openings | real court void + wings + window rhythm | open U/wing silhouette, never one block |
| Denver bungalow | tapered post on masonry pier | front gable + deep porch + grouped windows | broad shaded porch + low gable |
| Denver ranch | picture window and low entry | wide low roof + picture window + shallow porch | horizontal single-storey ratio + shallow roof |
| Denver Victorian | tall sash and small porch profiles | steep gable + tall bay + porch | vertical compact mass + steep roof + tall openings |

## Projection at phone size
Use 390 CSS px width, 60 degree horizontal FOV, landscape feature near view centre. f = W / (2 tan(FOV/2)) = 337.75 layout pixels. Projected width = f * featureWidth / depth. A 10 cm feature occupies 3.38 / 1.35 / 0.68 px at 10 / 25 / 50 m; 4 cm occupies 1.35 / 0.54 / 0.27 px. A 1 m opening remains 33.8 / 13.5 / 6.8 px. Device drawable pixels equal these values times device scale; do not confuse 3x drawable resolution with larger perceived detail.

Use geometry for shading/silhouette changes even when local thickness is small, particularly deep eaves and a tall column. As a starting rule, geometry ornament should exceed 1.5 layout px; painted marks should exceed 1 px. Below 0.75 px drop decorative marks to avoid flicker. Do not enlarge a 2 cm mullion into a 20 cm bar just to hold it at 50 m. Merge sash detail while keeping the overall window grouping. Transition with approximately 15% hysteresis; any crossfade counts both versions against the scene budget. These thresholds are design assumptions, to tune on device.

## Softened edges without boxy or melted houses
Bevel width below means offset measured along each adjacent face from the original edge. A rounded 90-degree fillet uses approximately the same radius. Values are real metres, not fractions of house size.

| Part | Default bevel/rounding | Near geometry | At 25 / 50 m |
|---|---|---|---|
| Major wall corner | 0.025–0.06 m; preferred 0.04 m | 1 chamfer or 2 rounded segments | simple chamfer/vertex normals; broad wall planes stay flat |
| Masonry pier, chimney, stone band | 0.02–0.04 m | 1–2 segments | 1 chamfer if silhouette useful, else normals |
| Timber post, door/window casing | 0.005–0.015 m | 1 chamfer | normals; no extra ring loops |
| Step nosing / porch slab | 0.008–0.02 m | 1 chamfer | D nosing loops, keep step/stoop envelope |
| Fascia / roof ridge / parapet cap | 0.01–0.025 m | 1 chamfer | simplified crisp edge; never bulging roof |
| Turret / rounded bay | shape radius from subtype, edge fillet 0.015–0.03 m | 8–12 sides for broad curve | 6–8 / 5–6 sides if silhouette permits |
| Low shrubs | organic lobes, not cube bevels | 3–7 unequal smooth groups | merge groups by projected size |

Clamp bevel to <=10% of the narrowest adjacent member thickness; keep close edges from colliding. Prefer angle-weighted/weighted normals and explicit smoothing boundaries to adding subdivision everywhere. Do not smooth wall normals across the entire building: large faces must remain planar, with highlight confined to the bevel. A 4 cm wall bevel is about 1.35 layout px at 10 m and supplies a thin warm highlight; 20 cm rounds read as toy foam and weaken style identity. The bevel cannot fix a box by itself: roof pitch, overhang, bay depth, porch void, stoop and chimney supply the decisive silhouette breaks. Two-storey base boxes need at least roof/parapet structure, one facade depth event, and an entry volume where the family supports them.

## Material and light use
house-details-colours.json supplies neutral sRGB base ranges per family for brick, siding, stone, stucco, trim and roof. Disabled slots represent absent default material, not a ban on authentic variants. Pick one coherent palette per house, with no more than two wall materials, trim and a small accent. Use coloured siding and door accents for chroma; don't make limestone neon. Queen Anne includes coordinated alternate sets.

Decode sRGB to linear before interpolation and lighting. All opaque materials have metallic=0. Roughness values are proposed perceptual parameters and need backend calibration. Broad variation <=3% linear luminance, no random bricks or speckled wall noise. Window colour is a stylized broad reflected-sky surface, with simple dark recess; avoid a realistic interior scene or mirror-sharp environment.

Warm sun / cool sky reference comes from look-fix. A deliberately long-shadow fixture at 25 degrees solar elevation has length/height=2.1445; runtime uses actual solar elevation and bearing. Keep deep eave shade coloured, with readable piers and door, not black holes. Atmospheric haze belongs to distant neighbourhood layers (clear-air reference begins around 300 m); the 10/25/50 m house does not become pastel through arbitrary fog. Strong light provides bright edge highlights without baking them into colour masks.

Weather inherits rain/ground packs: wetness changes diffuse response and roughness, not new photo detail. Snow sits on eligible roof/step tops without filling porch/courtyard voids. Strong long shadows are a sunny fixture, not a rule for overcast rain. Existing real geography and known door/walk clearance override inferred dressing.

## Review and limits
Open index.html and inspect each panel at 390 px without zooming. Then build real engine captures at 10/25/50 m with fixed FOV, sun and lot identity. Confirm each family by silhouette in grayscale; test sun and shade, then motion for disappearing bars and sparkling trim. Compare silhouette before/after LOD swaps. Preserve access, basement openings and courtyard negative space. Verify ordinary clear day plus wet overcast so family recognition does not depend on sunny shadows alone.

No engine code, assets, other proposal directories or git were changed. No device performance or production readability test was run. Generated sheets are art direction: they may contain incidental fine marks or simplified/ambiguous doors; follow numeric recipes instead. The first muted raster was discarded after the user clarified Style B and is not included in this pack.

## Architectural grounding
Checked 6 October 2026. These sources support family cues, not palette hex values or rendering dimensions:
- [City of Chicago: Tudor Revival](https://webapps1.chicago.gov/landmarksweb/web/styledetails.htm?styId=215) — irregular steep-gabled massing and stucco.
- [City of Chicago: Colonial Revival](https://webapps1.chicago.gov/landmarksweb/web/styledetails.htm?styId=206) — symmetry, brick/clapboard, articulated entrance and hip/gable roofs.
- [City of Chicago: Prairie School](https://webapps1.chicago.gov/landmarksweb/web/styledetails.htm?styId=201) — horizontal form, grouped decorative glazing and broad eaves.
- [City of Chicago: Queen Anne](https://webapps1.chicago.gov/landmarksweb/web/styledetails.htm?styId=203) — bays, expansive porches and varied roof forms.
- [Chicago History Museum: Chicago's Bungalows](https://www.chicagohistory.org/chicagos-bungalows/) — narrow brick form, hip roof and modest front porch; variations exist.
- [Chicago Workers Cottage Initiative: Two-flats](https://workerscottage.org/twoflats.html) — stacked apartment form, flat-roof and gable-front variants, overlap with greystones.
Denver family choices and regional variations are authored exemplar choices based on the user's list, not a claim of a surveyed district inventory. Denver city character-feature/survey PDFs were found in search but unavailable for full inspection; they are not used as verified evidence.
