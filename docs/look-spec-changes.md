# Look spec changes (porting checklist for the three.js renderer)

Every look value is renderer-neutral data that RealityKit reads; this log lists what changed, where and why, so the web renderer can follow. Spec files: `Sources/WorldGen/Profiles/lighting-bible.json` (generated from docs/proposals/look-fix-v1), `grade.json`, `look.json`, `time-of-day.json`, `seasonal-palette.json`, `weather.json`.

| Date | Spec file | Change | Why |
|---|---|---|---|
| 2026-10-06 | look.json (new) | Wet ground: asphalt darkens 50% / walks 45% when soaked, light rain shows 65% of that; lawn 6%; paving gloss floor 0.22; puddles from wetness 0.2, up to 16% asphalt / 14% walks; puddle base 0.8 of the wet ground, sky reflection 0.35–0.7; ripple rings 0.45 while raining | Owner's phone check: rain read dry, puddles read as dark holes |
| 2026-10-06 | look.json (new) | Rain streaks: 600 drops, 2.2 cm wide, 10× long, #C7D0DB at 0.7 | No rainfall visible at phone size |
| 2026-10-06 | grade.json, lighting-bible.json, time-of-day.json, seasonal-palette.json | Lighting bible as data, per-state grade, weather direct cut, sky colours, context-ring and backdrop colours (see git log of these files) | Look-fix pass, earlier today |
