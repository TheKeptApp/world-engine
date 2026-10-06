# Roof and wall tone targets for P2 (from P0, 6 Oct 2026)

Source: the lighting bible, `docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md` §1 (colour convention), §2.1–2.4, plus P0's exposure work on `phase5b` (`c5d940f`: per-state grade, solved auto exposure, clear-air fade). Phone measurements are from WorldLab on the iPhone 14 Pro.

## 1. What the palette should hold (P2)

Palette hexes are **base colours under neutral reference light** (bible §1: "sRGB base-color swatches … not already shaded pixel colors"). Pick them for what the material is, not to rescue dark rendering. The bible's order (§2.1) is: fix fill and shadow hue first, exposure second; never brighten a correct surface to save a black roof. The renderer side of this is P0's job (section 3).

| Surface | Base-colour floor | Where it comes from |
|---|---|---|
| Roofs (all families) | **#303942** (Y8 ≈ 56). No roof base darker | v2 and bible §2.4: "Material base roof floor remains v2 #303942" |
| Walls | Keep the regional swatches (regions spec §6) | Bible §2.4: night walls must read 35–65 while roofs read 22–40, so walls should sit clearly above roofs in value. A working floor of about Y8 80 (for example #4F5257 grey, #5A4636 dark brick) keeps that order |
| Trunks | No change from P2 (P0 fixes their fill) | §2.4 moonlit trunk 25–45 |

Y8 = 0.2126 R + 0.7152 G + 0.0722 B on sRGB 0–255, the look loop's measure.

## 2. What the rendered frame must show (targets for both of us)

Whole frame, bible §2.2. P0's auto exposure now aims at these means.

| State | Y mean | P5 / P50 / P95 |
|---|---:|---|
| Ordinary 15:30 | 140 | 48 / 143 / 224 |
| Midday | 145 | 55 / 148 / 226 |
| Golden hour | 130 | 36 / 128 / 222 |
| Overcast | 137 | 64 / 139 / 207 |
| Moon night | 57 | 18 / 45 / 109 |

Shade (§2.3): a shaded surface renders at **0.30–0.38 of the same surface in sun** (linear luminance) at 15:30, and 0.33–0.43 at golden hour. The shade tint is cool: **#6E7FAC** at 15:30 and **#7777AA** at golden hour. AO may take another 10–20% within 0.15–0.4 m of a contact, and no more.

So at 15:30 the darkest building surfaces in shade should render around **Y8 45–60** (the frame's P5 is 48 ± 12), and never near-black. At night (§2.4, without lamps): moonlit roofs 22–40 and walls 35–65; moonless roofs 16–30 and walls 25–48.

## 3. Where the renderer is today (P0, phone)

| Measurement (iPhone, 15:30 clear) | Now | Target |
|---|---:|---:|
| Path, shade-to-sun ratio (the bible's lift) | **0.17** | 0.30–0.38 |
| Frame P5 (darkest 5%) | 14 | 48 |
| Near crown underside | Y8 13 (#011200) | about 35–50 |
| Sloan's Lake house wall in shade (v2-01) | Y8 118 (#7F746A, warm grey-brown) | cooler, toward the #6E7FAC tint |
| Lakeview Roscoe brick wall in shade | Y8 100 (#776246, muddy brown) | cooler and lifted |

The lift is half of what the bible asks, and the shade is warm-neutral instead of blue-violet. That is why roofs go near-black and walls muddy, and it is P0's to fix:
- more sky and ground fill and less key (key:fill toward 2.2);
- sky-fill tint toward #99AFE0;
- a blue shade tint.

P0 is tuning this now on the phone with `scripts/lighting_bible.py` (`-tune` sweeps). When it lands, P0 will send measured sun and shade renders for a few palette hexes (a transfer table), so P2 can check the families against these bands.

## 4. Until then (P2)

- Keep roofs at or above #303942 and walls clearly above roofs (section 1).
- Don't lift palettes further to compensate for today's 0.17 lift: once the fill is fixed they would read washed out.
- A temporary documented tone floor in generator data is fine. Please list the hexes it changes in your report, so we can revert any that turn out too light after the lift fix.
