# Ground diagnosis: mocks vs renders (P2, 2026-10-06)

Sheet: [ground-diagnosis.jpg](ground-diagnosis.jpg). It puts each look-fix-v1 mock next to our in-app
frames of the views P3 compares it with, all at phone size, from P3's run on ec7a62a (ground pass 2):
- ground-01 (North Shore clear) against wilmette-street and evanston-street;
- ground-04 (Lakeview clear) against lakeview-street and lakeview-postcard.

## The three biggest differences (estimated share of the visual gap)

1. **Sun and cast shadow on the ground, about 45 %. Lighting (5A), not P2.**
   - The mocks are late-morning sun with dappled crown shadows covering 30–50 % of lawn and
     sidewalk. Lit grass is bright and saturated, shadowed grass is a deep cool green, and that
     two-tone pattern is what makes their ground read.
   - Our frames are late-day (pink sky, low sun). Lawns are evenly lit with few or no crown
     shadows near the camera.
   - With flat lighting, the lot-tone, patch and mowing variation (8–15 %) is too small to carry
     the ground on its own.
2. **Planting mass near the camera and along house fronts, about 25 %. P2.**
   - The mocks have big overlapping shrub masses (0.6–1.5 m) in drifts at the walk, along the
     foundations and at lot corners, sitting in dark mulch beds with clear edges. Lakeview adds
     front gardens packed with shrubs behind iron fences.
   - Ours: small scattered shrubs (0.3–0.8 m), beds mostly hidden behind them, lots of empty lawn
     between house and sidewalk.
3. **Canopy over the street and lawn, about 20 %. P2 (vegetation sub-agent).**
   - The mocks have dense, irregular crowns that overhang the frame and cast the shadows in item 1.
   - Ours are sparser crowns that read as balls on sticks, few of them overhanging near the camera.

The remaining ~10 % is lawn tone, curb and parkway definition, and stoops and fences.

## P2's next steps

- **Planting masses** (item 2):
  - Group shrubs into drifts of 3–5 overlapping plants, as the vegetation-v1 shrubs section says
    ("adjacent shrubs overlap visually"): along the foundation bed, at the walk, at lot corners.
  - Shift the mix toward the medium and upright forms the spec's size table allows (0.6–1.7 m).
  - Make the mulch bed visible as a band in front of the drift.
  - Stay inside look-fix §1.2's per-lot counts and the shrub triangle budget.
- **Trees** (item 3): vegetation-v1 crowns, species colours and trunk AO, already in progress with
  the sub-agent.
- **Hedges:** one continuous envelope (in test).
- **Lighting** (item 1): 5A is moving cast shadows up. Crown shadows on lawns are the largest single
  lever.
