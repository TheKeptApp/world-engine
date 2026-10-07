# Why the yards merge didn't register (P2, 2026-10-06)

Contact sheet: [yards-visibility.jpg](yards-visibility.jpg). It shows P3's in-app frames (1005 × 565, phone size)
for the 8 ground-heavy views: gate ccb5f77 on the left, yards ad2ebfc on the right
(`.build/lookloop/runs/20261006-124042` and `…-132418` in the p3-lookloop worktree).

## Present in the captures?

The frames really differ (mean pixel difference 11–45 on these views; nothing was reused). No
data-path, LOD, focus or profile problem was found: every camera is inside its area's focus box,
and areas load their own profile.

| Element | In the frames | Reads at phone size? |
|---|---|---|
| Foundation shrubs, hedge rows | yes | as rows of identical green spheres (new shrub forms not merged yet) |
| Front walks | yes | yes (concrete against grass) |
| Parkway trees | yes | yes |
| Leaf litter | evanston-street only | the renderer's canopy-map litter; `litterPatches` aren't wired yet (5A queue) |
| Foundation beds (mulch) | generated (tests) | **no**: 0.6–1.2 m strips behind the shrub rows; at 1.7 m eye height and 3° pitch they are 1–2 px or hidden |
| Lot-to-lot lawn tone | generated | **no**: see the next section |
| Lakeview gardens and paved rear yards | a few, in lakeview-aerial | barely; most visible green is base lawn around large blocks |
| Roscoe St carriageway | wrong | grass strip with trees down the middle (road-width bug; fix in progress) |

## Why lawn variation doesn't read

At ad2ebfc a lot's tone is only its paint shade: four steps 5 % apart. The lawn shader then adds
its own world-space variation, which is several times larger:
- broad noise ±12 %;
- a dry/lush mix up to 75 % at a 4–11 m scale.

That variation runs continuously across lot lines, so it hides the lot structure. The regional
endpoint pair lawnA/lawnB carries the real lot contrast (summer North Shore #648146 → #8C9C59), but
the renderer did not read it at ad2ebfc. 5A has since wired it on phase5b, and it is not on main
yet.

## The three changes with the most contrast

1. **Lot tone through the endpoint pair, with less world noise on lots.**
   - 5A's lawnA/lawnB wiring (pending merge): neighbouring lots differ by part of the regional
     endpoint spread, not by 5 %.
   - Ask 5A to cut the world-space dry/lush mix on lot lawns (`extra.w > 0`) to about a third, so
     lot edges show.
   - P2 bakes broad patches inside each lot instead: 3–5 per lawn, ±6 %, never crossing the lot line.
2. **Darker ground under every tree, hedge and shrub.** A value drop of 12–15 % under 0.85 × the
   crown radius, baked into lawn vertices. It repeats on every lot and reads at both postcard and
   aerial range.
3. **Beds you can see from the street.**
   - Full spec depth (1.2 m) at the front.
   - Shrubs set back inside the bed with gaps, so the mulch (#6F5A48, the strongest value contrast
     on the lot) shows between them.
   - Wider corner returns.

   Mulch rings round yard-tree trunks would add more contrast, but look-fix §1.2 doesn't cover
   them. That needs an owner decision.

Mowing bands at the spec contrast (2–3 %) won't read at phone size. I'll keep them in spec on part
of the lots and rank them low. Worn edges and the curb/parkway band follow after these three.
