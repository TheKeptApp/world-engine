# House contrast v1

Three completed architectural appearance paint-overs from the latest available P3 look-loop capture set, **20261007-062707**, checked on 2026-10-07. Open `index.html` for full-frame current/paint-over comparisons, each panel 390 CSS pixels wide. Use the fit button for overview; default width is the phone-size review.

## Exact source files

- **lakeview**: `~/Desktop/world-engine/.claude/worktrees/p3-lookloop/.build/lookloop/runs/20261007-062707/raw/lakeview-street.png`
- **wilmette**: `~/Desktop/world-engine/.claude/worktrees/p3-lookloop/.build/lookloop/runs/20261007-062707/raw/wilmette-street.png`
- **denver**: `~/Desktop/world-engine/.claude/worktrees/p3-lookloop/.build/lookloop/runs/20261007-062707/raw/ordinary-street.png`

Denver uses `ordinary-street.png`: the repository view registry identifies it as W 23rd Ave (v2 camera). Night-fog-v1 used `showcase-01.png`, a lake-facing view without useful nearby houses. The same October 7 P3 run supplies all three house comparison views. Main-checkout look-loop metadata is older (October 6); no new simulator captures were made.

## Deliverables

- `images/*-paintover.png`: three full-resolution built-in imagegen outputs.
- `images/*-current.png`: unchanged copies of the source captures.
- `images/*-phone-comparison.svg`: portable embedded-image side-by-sides, 390px per panel, no cropping.
- `paintover-values.json`: hex swatches, linear luminance and wall-normalized relative brightness for three-flats, two-flats, workers cottages and bungalows. Numeric values remain unchanged; metadata now records completed paint-overs. Generated pixels are locally lit variants, not exact palette measurements.
- `minimum-detail.md`: one-page ranking by expected visual impact per cost.
- `image-prompts.json`: exact prompts used with built-in imagegen.
- `manifest.json`: source paths and hashes, output inventory.

## Reading the paint-overs

Lakeview shows cream trim and deep glass, broad sill/lintel reveals, cornice termination on visible opposite-side flats and projecting bay returns. Wilmette shows the clearest soffit/eave hierarchy and porch-canopy shadow line, with lighter siding distinct from brick. Denver shows recess and canopy detail on the near house and stronger roof termination across the road. Preserve house type from source/data: these views do not expose every archetype equally. Workers cottages and bungalows remain specified in the values and detail sheet; neither a cropped roof nor a two-storey block should be replaced just to demonstrate a type.

## Verification and limits

Inputs inspected before editing; generated outputs inspected full frame. Camera composition, dominant tree placements and lighting direction remain visually close. These generative paint-overs are **not pixel-exact houses-only composites**: minor non-house surface/shading changes, extra fine courses, and small facade/roof interpretation changes remain. Do not implement incidental texture or silhouette deviations. Original captures govern footprints, openings, height, roof shape, foliage and lighting. Full-frame phone comparisons expose the differences. No phone device test, rendering benchmark or official look-loop gate was run; these are design proposals, not engine visual changes.

Visible OSM attribution is supplied in the gallery/comparison margins because raw source captures omit app UI credit. No people, logos or real house numbers were added. Minimum iOS remains 26.0. No engine files or git operations were used.
