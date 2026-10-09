# P2 Batch 0 — native ladder frames, lawn tone, #9F390C, controls (9 Oct 2026)

Measure only: no code, look value or default changed. Main `b95e060`, `scripts/capture-native.sh --view VIEW --inspectionpose lat,lon,AGL,270,45 --date 2026-10-15T20:30:00Z`, one heavy admission each. Map data © OpenStreetMap contributors. The raw frames are the 3D view only; the app's on-screen attribution is in each run's UI frame.

## 1. Native scoring path (for A3's paired protocol)

The cameras match the web ladder: `scripts/web_sloans_ladder.json` for Sloan's, and the saved Lakeview eye 41.945182,−87.66432 (`web_capture_blocks.mjs` lakeview-ladder). Shared settings: heading 270°, pitch down 45°, FOV 50°, 1005×565, UTC 2026-10-15T20:30:00Z. Exposure is pinned (gain 1.0), the weather is clear/cloud 0/wind 0, and there is no character. Full hashes, observed camera lines and pass counts are in [manifest.json](manifest.json).

| View | Main tris / draws | Frame |
|---|---:|---|
| Sloan's 40 | 312,880 / 53 | [png](sloans-40-native.png) |
| Sloan's 150 | 333,744 / 50 | [png](sloans-150-native.png) |
| Sloan's 600 | 228,013 / 43 | [png](sloans-600-native.png) |
| Lakeview 40 | 295,759 / 56 | [png](lakeview-40-native.png) |
| Lakeview 150 | 271,763 / 48 | [png](lakeview-150-native.png) |
| Lakeview 600 | 194,160 / 35 | [png](lakeview-600-native.png) |

Known confounds against web for A3 to register:
- The web fixture has wind 10 km/h from 225°; native has wind 0.
- Exposure: web uses gain 1.2746, saturation 1.08 and contrast 1.06; native is pinned at 1.0 with no grade.
- Native's resolved eye is +0.16 m (the earlier audit).
- Lakeview 600 shows the known blank context field ([lakeview-600m-blank-field](../../../review/lakeview-600m-blank-field.md)).
- The 600 m noise is 5A's ([native-ladder-batch0](../../../perf/native-ladder-batch0.md) §2): with exposure pinned, the repeat is ≤1/255.

## 2. Lawn tone: native versus the web "pale yellow rectangles"

Native does give each lot a uniform tone, so lot rectangles exist. The generator steps each lot's shade from 0.92 to 1.07 in four steps (yards.json `lawnShade`), and the shader mixes lawnA→lawnB tone per lot. By calculation that is about ΔL* 15 between the darkest and brightest lot.

In the frames they read as **green steps, not pale yellow**:
- Lawn blocks: Sloan's L* p10/p50/p90 is about 48/59/70 at 40 m; Lakeview is 49/53/62.
- The brightest native lots are sage green, e.g. #92A962 and #859F4D.
- Web OFF lawns are a uniform pale green (L* about 72–77).

[Crop: native left, web right](sloans-150-roof-lawn-native-vs-web.png).

Proposed general softening (not built, every region): halve the lot-to-lot spread. That means `lawnShade` 0.92–1.07 → 0.96–1.035, and lawnA/lawnB pulled halfway to their mean, so about ΔL* 7 between lots. There is no new variation and no per-place value. It would ship default off for A3 paired scoring. The autumn endpoints (#858949/#ABA16A) are the yellowest, so they matter most on October dates.

## 3. #9F390C (12 mapped `roof:colour` roofs, Sloan's)

Both renderers take the same exported OSM colour (`BuildingGenerator` mapped roof:colour wins; shade ×0.96–1.04). The difference comes from the renderer:

| Renderer | Hue | Lit-side mean at 40 m | At 150 m |
|---|---|---|---|
| Native | Saturated red (hue ≈11°, blue clipped near 0) | #C22F0C | #CA2501 |
| Web | Brighter orange (hue ≈20°) | #E5570C | #E44B00 |

The source hue is ≈16°, so native shifts it redder and web shifts it more orange and lighter. Both are well above the source chroma. Fixing it is a renderer grade or exposure matter (5A/A2), not a data change: palette-diagnosis's mapped-colour guard is still a hypothesis and is not applied.

## 4. Controls

Batch 0 changed nothing, so OFF is current main. The same frames from 5A's independent run on `b95e060`:
- **Byte-exact (4 of 6):** Sloan's 40 and Lakeview 40/150/600.
- **Within 1/255 (2 of 6):** Sloan's 150 and 600 (28 and 31 bytes differ, mean ≤2e-5).

So "exact" holds for 4 of 6. The rest are inside 5A's ≤2/255 control gate but not byte-identical.

Sloan's counts are 142 triangles below A10's earlier 313,022/333,886/228,159 at every height. That comes from main changes since A10; it is not a flag.

Used: restart-P2.md Batch 0; paired-preference-protocol.md (freeze/register); web-native-look-parity.md rows 2, 6 and 11; palette-diagnosis.md roof rows. Mock: style-b-calibration-v2 06-sloans / 01-lakeview (context only; no grade). Deviation: no repeat captures beyond the six listed; 5A's run serves as the repeat.
