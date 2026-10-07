# Look loop: regressions

This run (2026-10-07 14:59, engine `bfc9fb4`) against the previous published run (2026-10-07 14:13, engine `7c4e15b`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

**4 regression flag(s) in 2 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [lakeview-postcard](sheets/lakeview-postcard.jpg) | softnessAO | 3 | 2 | The near trunk meets the grass with a hard cut and no 10-20 % base darkening; single-capsule shrubs have no contact shade; crown shading is hard-edged near-black blotches rather than gentle occlusion; a thin dark rim run |
| [lakeview-street-afternoon](sheets/lakeview-street-afternoon.jpg) | v2 /50 | 31.1 | 28.9 | At phone size this reads as the mock's scene in flat-shaded form: layout, exposure and sky match, but the left block is a flat saturated orange wall, the lawns are an even minty green beside cool-white concrete, and tree |
| [lakeview-street-afternoon](sheets/lakeview-street-afternoon.jpg) | softnessAO | 3 | 2 | No contact darkening or ring at the near trunk base (it sits on the lawn like a pasted cylinder), the flat khaki plinth meets the slate strip with no seam shade, the stoop and steps have no contact shade, and cast shadow |
| [lakeview-street-afternoon](sheets/lakeview-street-afternoon.jpg) | groundRichness | 3 | 2 | Both lawns are a single flat tone with no patches, shade tone, worn edges or leaf litter; richness is limited to faint sidewalk slab joints, a white curb line, a few grass tufts at the foundation shrubs and far parkway,  |

**Not counted: 9 flag(s) in 2 view(s) whose frame did not change since the previous run** (under 0.5% of pixels differ by more than 12 levels), so the move is grader variance, not a regression: evanston-street, wilmette-aerial.

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | v2 /50 | 29.5 | 27.4 | At phone size this reads as a bright, tidy peak-fall neighbourhood with readable roof and wall families, a coherent sun and a believable street grid, but the trees are saturated lollipop and stacked-sphere crowns standin |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | groundRichness | 3 | 2 | Lawns are one flat green (hue about 100, value about 0.58 at all depths) varied only by tree shadows. Seams exist (white sidewalk strips, pale driveways, alleys, a lighter circle in the park) and a few small shrub lumps  |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | houseVariety | 4 | 3 | Several believable kit families: red brick cross-gable with porch hoods and arched doors, tan brick, cream siding, white flat-roof blocks, detached garages with driveways, chimneys. Mid-field houses share the same dark g |
| [wilmette-aerial](sheets/wilmette-aerial.jpg) | adRegional | 4 | 3 | Reads as a Chicago-area grid suburb: brick and tan two-storey houses, detached garages and driveways, an orange and yellow deciduous mix with a few spruce, a park at one side. It lacks the continuous parkway canopy, Tudo |
| [evanston-street](sheets/evanston-street.jpg) | v2 /50 | 30.0 | 24.7 | At phone size this is a bright, clean stylized fall street with well-differentiated yellow and orange crowns and readable houses, but it looks flat and toy-like because the afternoon sun leaves almost no readable shadows |
| [evanston-street](sheets/evanston-street.jpg) | silhouettes | 3 | 2 | Houses read well (cross-gable frame house, low brick cottage with chimney, long ochre block), but the trees that fill the top of the frame are faceted stacked-lobe crowns of one construction, trunk tops end in flat caps  |
| [evanston-street](sheets/evanston-street.jpg) | light | 3 | 2 | One coherent sun and nothing contradicts it (faint lawn shadow bands fall toward camera-left), but it is weak: lawn luma only drifts 117-141 with no defined shadow shapes, the sunlit west wall is about 9 % brighter than  |
| [evanston-street](sheets/evanston-street.jpg) | groundRichness | 3 | 2 | Sparse leaf flecks, a few grass tufts, walk joints and a cross-walk give some seams, but both lawns are near-flat tones (parkway luma spread about 3), grass meets the walk with hard edges, and there are no beds, patches  |
| [evanston-street](sheets/evanston-street.jpg) | depthFog | 3 | 2 | Depth comes only from perspective and the tree rows: far crowns, far houses and the far road keep the saturation of near ones (tan walls 0.37 vs 0.42), the sky is not paler toward the horizon and there is no haze or sun- |

**P3 note (commit bfc9fb4, P2 house archetypes):** 4 counted flags on changed frames (lakeview-postcard softnessAO; lakeview-street-afternoon v2 −2.2, softnessAO, groundRichness): contact shading and lawns, none about houses. No view is down more than 3 points on /50 on a changed frame. The evanston-street −5.3 /50 and wilmette-aerial −2.1 /50 are on unchanged frames (grader variance). Mock closeness did not rise; see the scoreboard (14:59).
