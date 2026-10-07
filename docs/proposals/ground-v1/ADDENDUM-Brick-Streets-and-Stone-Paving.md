# Ground v1 addendum — Chicago brick streets and stone paving

**6 October 2026 · Style B · Proposal only**

Adds aged red clay paving brick, rectangular stone setts, and rounded cobblestone, with dry, wet, snow and fall-leaf references. Brick is clay; setts are block-shaped stone; the rounded-cobble variant uses irregular rounded units. None becomes a Chicago-wide default.

## Files and authority

- [Weather sheet](images/addendum-01-chicago-brick-stone-weather.png)
- [Street distance and aerial sheet](images/addendum-02-brick-stone-phone-aerial.png)
- [Exact color chart](images/addendum-03-brick-stone-exact-colours.svg)
- [Color JSON](ground-colours.json): new brickAndCobblestoneAddendum section
- [Prompts](addendum-prompts.json)

**Artwork limitation:** distance columns mean **5 m, 20 m, 40 m, aerial**, left to right. Some generated labels remain wrong after one edit; this document and JSON govern. Rasters are illustrative, not calibrated phone views or scale/contrast measurements. Close paving is exaggerated in the concepts; use the dimensions below.

## Evidence and selection

**Verified:** historic brick streets/alleys and granite paving are documented in Chicago. The report says their remaining extent was not accurately surveyed and describes brick restoration in Wilmette. [Preservation Chicago, 4 March 2018; checked 6 October 2026](https://www.preservationchicago.org/brick-paved-streets-and-alleys/).

**Assumption:** stone-sett and rounded-cobble scenes are authored visual variants, not actual surveyed alleys. Select from mapped surface/material or independent site evidence. Unknown paving keeps the existing regional fallback. Do not expose buried brick because a district is historic. Preserve mapped routes, widths, curbs and elevations. Use stable object seeds for patterns; never reroll with weather.

All numbers below are **authored design assumptions**, following the existing linear-luminance contrast definition.

## Scale and phone reading

| Material | Nominal unit | Joint width | Joint delta Y | Per-unit variation | Broad patch variation |
|---|---|---|---|---|---|
| Red brick | 20 × 10 cm | 8–15 mm | −14% | ±3% | ±5% |
| Stone setts | 20 × 15 cm | 10–25 mm | −16% | ±4% | ±5% |
| Rounded cobble | 10–18 cm diameter | 10–25 mm | −18% | ±4% | ±5% |

Broad patches span 1.5–4 m. Clamp combined non-joint unit/patch variation to ±7% of substrate. Joint targets are separate; do not stack every dark feature at one point.

At **5 m**, show thin softened joints; at **20 m**, emphasize groups and patch rhythm; at **40 m**, retain hue and boundaries while fine joints disappear. Aerial uses projected unit size. Given unit width p in pixels: t=clamp((p−1.5)/1.5,0,1), amplitude=t²(3−2t). Full joint/unit variation at 3 px, zero at 1.5 px or less. Keep broad patches. Mipmapped masks or derivative filtering prevent shimmer; never clamp a tiny joint to a black one-pixel line. Validate on an actual phone at matched field of view.

## Weather, materials and colors

Dry albedos: brick #9B6753, setts #8B8981, rounded cobble #929084. Light rain lowers linear luminance 10%; soaked lowers it 15%. Roughness: dry 0.82/0.86/0.88 respectively, light rain 0.62, soaked 0.55. Interpolate in linear space. These are stylized targets, not measured material constants.

Apply feature percentages to the current wet substrate, not the exported dry feature hex. Soft highlights distinguish wet paving without chrome. Puddles require supported depressions/history or explicit demo inference; no mirror in every joint.

Fresh/trodden/plowed snow reuse the existing overlay palette and independent coverage model. Covered joints disappear. Tracks and banks require supplied history; cold temperature alone does not prove snow cover. Fall litter reuses gold/russet families, gathering sparsely at curbs and joints. Wet plus leaves combines wet substrate with litter; the named fall-leaves swatch is a dry baseline. Keep unsupported coverage unknown.

Warm swatches follow the existing golden-hour display transform. Do not apply warm display colors as albedos and light them a second time. Exact JSON/SVG values override generated artwork.

## Performance

Paving is authored masks/material data: **zero geometry or draw calls per brick/cobble**. Geometry only supports existing curb/threshold silhouettes and bounded optional edging. Reuse the existing 4 MiB mask allowance. Patterns share 0.25 ms, wet effects 0.35 ms, optional edge/snow/litter geometry 0.35 ms and the existing 35k near reserve. No new budget: 400k scene triangles, 150k shadow triangles, 100 draws, 10 ms GPU. These are allocations, not profiling measurements.

Reject oversized units, glittering grids, uniform puddle sheen, snow-through-joint artifacts and full-plane leaf confetti. Existing materials and images remain intact.
