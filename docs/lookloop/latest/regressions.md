# Look loop: regressions

This run (2026-10-06 09:16, engine `78e7541`) against the previous published run (2026-10-06 06:39, engine `651649b`). Rule: a view down 2 or more on /50, or any criterion down 1 or more. 17 freshly graded view(s) compared; 0 reused unchanged view(s) cannot regress.

Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come from the procedure rather than the render; compare the sheets before acting.

Caution: graders differ (claude-sonnet-5-5 then, claude-opus-5-5 now). A one-point move can be grader variance; check the two sheets side by side before acting.

**20 regression flag(s) in 11 view(s).**

| View | What | Before | Now | Reviewer's reason now |
|---|---|---|---|---|
| [v2-06](sheets/v2-06.jpg) | depthFog | 2 | 1 | The world is a hard-edged rectangular tile floating in an empty mauve-tan void, filling only about half the frame: missing edge, no continuation, no aerial perspective. |
| [showcase-03](sheets/showcase-03.jpg) | adGroundRich | 2 | 1 | One flat lawn colour everywhere, no shrubs or beds, hard grass/path and grass/shore edges; a handful of tufts barely register. |
| [showcase-03](sheets/showcase-03.jpg) | adRegional | 3 | 2 | Generic park: lollipop broadleaves and cone conifers, no cottonwood character, no bungalows or downtown skyline visible; little reads as Sloan's Lake. |
| [showcase-04](sheets/showcase-04.jpg) | v2 /50 | 28.8 | 26.3 | At phone size this reads as an ordinary bright park with a dark sky pasted above it: the ground, path and lake show no wetness and the lawn is one flat carpet. The biggest gap is weather readability, with no wet darkenin |
| [showcase-04](sheets/showcase-04.jpg) | palette | 3 | 2 | Autumn crown colours are coherent, but a bright mid-green lawn, pale dry path and saturated teal lake sit under a near-black storm sky: the base colours do not respond to the storm at all. |
| [showcase-04](sheets/showcase-04.jpg) | light | 3 | 2 | Ground and lake are lit like a bright overcast day while the sky is a thunderstorm; soft blotchy dark patches on the path read as crown shadows (or an unclear reflection), which contradicts a fully overcast storm key. |
| [showcase-04](sheets/showcase-04.jpg) | adGroundRich | 2 | 1 | One flat lawn colour everywhere, no shrubs, beds, shoreline planting or leaf litter under the crowns; hard grass/path edges. |
| [showcase-05](sheets/showcase-05.jpg) | palette | 3 | 2 | Lawn stays a saturated uniform mid-green and the conifers a mint teal right up to the mid-ground; fog barely desaturates anything, so the weather variation is very modest and the greens look candy-like for a fog day |
| [showcase-05](sheets/showcase-05.jpg) | adGroundRich | 2 | 1 | One flat lawn colour everywhere, no shrubs or beds along the path or shore, hard grass/path edges; a few tiny tufts and leaf flecks do not lift it |
| [showcase-07](sheets/showcase-07.jpg) | houseVariety | 3 | 2 | Houses appear only as tiny low indistinct boxes on the far-left horizon; no families, roofs or openings are readable at phone size, where the target shows a row of distinct homes. |
| [showcase-08](sheets/showcase-08.jpg) | silhouettes | 3 | 2 | Bare deciduous crowns branch believably, but the conifers are identical toy stacked-cone tiers (three near-clones mid-frame) and the houses are unreadable specks; well below refs 01/07/09. |
| [showcase-10](sheets/showcase-10.jpg) | depthFog | 2 | 1 | Missing edge: the world is a rectangular tile floating in a flat grey void that fills about half the frame, with hard edges on all four sides. There is no continuation beyond the data and no atmospheric separation over t |
| [showcase-11](sheets/showcase-11.jpg) | v2 /50 | 23.8 | 21.3 | At phone size this reads as a small model tile of Sloan's Lake floating on an endless grey-brown camouflage plane, with houses and trees reduced to specks and no low-sun light. The biggest gap is the exposed world edge a |
| [showcase-11](sheets/showcase-11.jpg) | palette | 3 | 2 | No clipping, but the frame is dominated by a grey/brown camouflage mottle; the world itself is muted olive-grey with noisy orange roof glints, nowhere near the restrained winter whites, lake blue and warm brick of the ta |
| [showcase-11](sheets/showcase-11.jpg) | depthFog | 3 | 1 | The world ends in a hard rectangle with an infinite flat mottled plane beyond it; the edge is fully exposed and there is no atmospheric depth or backdrop continuation. |
| [ordinary-trail](sheets/ordinary-trail.jpg) | adRegional | 3 | 2 | Reads as a generic anywhere-park: lollipop deciduous and cone conifers carry only a weak cottonwood/conifer cue, with no Denver skyline or Sloan's Lake shore character across the water. |
| [ordinary-street](sheets/ordinary-street.jpg) | silhouettes | 3 | 2 | Houses read as roofless or flat-roofed boxes (left house, long tan blocks across the street); tree crowns are one lumpy round-cluster archetype in orange/yellow/olive, repetitive down the street. |
| [light-rain-street](sheets/light-rain-street.jpg) | v2 /50 | 30.0 | 27.8 | At phone size this reads as a clean but flat, dry overcast afternoon on a generic street: bright uniform lawns, pale walk, lollipop trees and boxy houses, with the black dog readable on the path. The biggest gap is that  |
| [light-rain-street](sheets/light-rain-street.jpg) | silhouettes | 3 | 2 | Near house is a flat tall wall with no readable roof or porch, distant yellow buildings read as flat-roofed boxes, and the trees are all the same sphere-cluster lollipop with only colour changes; no bungalow/foursquare p |
| [light-rain-street](sheets/light-rain-street.jpg) | softnessAO | 3 | 2 | Foundation shrubs sit down, but no visible occlusion at trunk bases, wall/ground seam or stoop, no contact shadow under the dog's feet, and facades are unshaded flat tones. |
