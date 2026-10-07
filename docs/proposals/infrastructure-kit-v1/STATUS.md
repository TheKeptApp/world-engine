# Status

**R approved – 2026-10-07.** Binding target: all 48 sheets (roads 9, bridges 6, rail 5, airports 6, water 7, utility 7, parks and open land 8).

**What it binds (look):** markings, materials, colours (palettes), bridge, rail and airport styling, detail tiers and LOD controls. Values compile into `Resources/look/mock-values.json` under the key prefix `style-b/infrastructure/` (assets by id, palettes by name). The pack's own "proposal" labels stay attached to its values: observed geometry and map tags still win.

**What it does not bind (geometry):** `street-geometry-rules-v1` owns street geometry (carriageway, lane and sidewalk widths by country and class); US residential carriageway = 10.6 m. The kit's 10.2 m is superseded for geometry. The kit's street cross-section keys are marked `supersededFor: geometry` in the compiled values. "Images beat JSON" applies to look, not to measurements.

Daytime lighting stays house-contrast-v1 `sharedLighting` (the pack's copied lighting block is not compiled).
