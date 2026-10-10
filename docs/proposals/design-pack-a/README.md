# Design pack A — churches and schools

Proposal for R review, not approval or runtime implementation. Fourteen original variants, 28 requested views. Authored dimensions/hexes and relative commonness priors are design proposals, not surveys or measured prevalence. The JSON and mapped geometry outrank image-generation geometry. Images may show excess surface detail; omit it in builds.

## Variants and build specs

All dimensions metres. Footprint is bounding width × depth; area is component union, not the bounding rectangle. Roof pitch is degrees. Heights are eaves; peaks and special parts appear under features. [Machine-readable specifications](values.json).

|ID / variant / sheet|Region|Footprint / area|Levels / eaves|Roof / pitch|Wall / hex|Roof / trim|Features|Commonness /10|Registry|
|---|---|---|---|---|---|---|---|---|---|
|[C01 White clapboard steeple](images/C01.png) · [prompt](prompts/C01.txt)|Southeast|[12, 26] / 294.4 m²|1 / 5|steep gable and pointed steeple / 42°|painted clapboard #E6E0D1|#454B52 / #CEC3AC|3.2 m square entry tower; plain steeple 17 m; tall narrow windows|7|worship → WorshipMass|
|[C02 Gothic-revival brick tower](images/C02.png) · [prompt](prompts/C02.txt)|Chicago north shore|[20, 36] / 460 m²|2 / 8|cross gables and flat tower / 50°|dark red brick #784F43|#414851 / #C9BEA8|6 m square offset tower 19 m; pointed window groups; broad entry steps|6|worship → WorshipMass|
|[C03 Stone Romanesque](images/C03.png) · [prompt](prompts/C03.txt)|Chicago north shore|[18, 30] / 505.23 m²|1 / 7|hip with conical apse / 30°|limestone #B5AC98|#555C65 / #DDD2BA|round arch entry 3 m wide; paired round arches; heavy 0.35 m surrounds; no tower|4|worship → WorshipMass|
|[C04 1960s low brick detached bell tower](images/C04.png) · [prompt](prompts/C04.txt)|Front Range|[34, 28] / 600 m²|1 / 4|low butterfly / 8°|tan brick #AA8967|#72736C / #D8D0BA|detached open 3 m square bell frame 13 m tall; low clerestory; covered entry|6|worship → WorshipMass|
|[C05 Modern A-frame glass](images/C05.png) · [prompt](prompts/C05.txt)|Front Range|[22, 32] / 704 m²|1 / 3|A-frame / 55°|timber with glass #756B5C|#505A60 / #A9997B|18.71 m ridge; dark flat front glazing; structural ribs at 4 m bays; no tower|3|worship → WorshipMass|
|[C06 Spanish mission stucco](images/C06.png) · [prompt](prompts/C06.txt)|Front Range|[30, 32] / 740 m²|1 / 5|shallow tile gables / 20°|stucco #C5A17D|#926F58 / #E2D0AD|curved plain parapet 7 m high; 2.6 m deep arcade; courtyard open at front; no symbols|4|worship → WorshipMass|
|[C07 Tiny country chapel](images/C07.png) · [prompt](prompts/C07.txt)|Southeast|[7, 12] / 84 m²|1 / 3.2|simple metal gable / 28°|painted board-and-batten #BBC1B9|#737D7E / #E5E0D2|4.86 m ridge; tiny covered porch; three rectangular side windows; no tower|5|worship → WorshipMass|
|[C08 Large low modern worship hall](images/C08.png) · [prompt](prompts/C08.txt)|Southeast|[60, 44] / 2448 m²|1 / 6|flat parapet / 0°|light brick with metal panels #C8B399|#666F73 / #E1D7C7|8 m entry canopy; 7 m parapet; broad glazing band; concept parking lot 100 by 90 m|7|worship → WorshipMass|
|[S01 1920s brick entrance tower](images/S01.png) · [prompt](prompts/S01.txt)|Chicago north shore|[64, 42] / 2064 m²|3 / 12|hip and entrance tower / 25°|red brick with limestone #945D4B|#4B525B / #D3C5AE|7 m wide central entrance tower 17 m; regular classroom bays; limestone entry|7|school → InstitutionMass|
|[S02 1950s long low wings](images/S02.png) · [prompt](prompts/S02.txt)|Southeast|[88, 44] / 1968 m²|1 / 4.2|low gables / 12°|cream brick #C7B998|#78817C / #E6DFC9|paired classroom wings; covered walkway; continuous rectangular window band|8|school → InstitutionMass|
|[S03 1970s blocky brick](images/S03.png) · [prompt](prompts/S03.txt)|Chicago north shore|[54, 46] / 1056 m²|2 / 8|flat stepped parapets / 0°|brown brick #806A57|#646B6C / #B8B4A5|9 m parapet; recessed entry 4 m; offset gym mass 9 m; deep window bands|8|school → InstitutionMass|
|[S04 Modern glass and metal](images/S04.png) · [prompt](prompts/S04.txt)|Front Range|[62, 40] / 1220 m²|3 / 11.4|sawtooth and flat wings / 15°|painted metal with glass #9DAAA9|#596A70 / #D4D2C1|14 m atrium crest; simple metal panels; broad flat dark glazing; shaded canopy|6|school → InstitutionMass|
|[S05 Private school converted house](images/S05.png) · [prompt](prompts/S05.txt)|Southeast|[16, 20] / 240 m²|2 / 6.2|cross gable / 35°|painted wood siding #BCA184|#6D797C / #E5DCC7|9.70 m ridge; modest porch; retained house-form windows; no institutional tower|4|school → InstitutionMass|
|[S06 Charter former strip building](images/S06.png) · [prompt](prompts/S06.txt)|Front Range|[58, 16] / 928 m²|1 / 4.5|mono-pitch behind parapet / 3°|light stucco #C9C3B6|#737C80 / #9F927E|5.4 m parapet; repeated former retail bays; single plain entry; no new school crest|5|school → InstitutionMass|

## Generator selection and reconciliation

Implements [archetypes registry](../../execution/archetypes.md) §1, rows17/20 and §3: all C variants map to existing `worship`/proposed `WorshipMass`; all S variants to existing `school`/proposed `InstitutionMass`. These are 14 new visual subtype IDs, not new semantic archetypes or implemented symbols. S05 retains explicitly known house physical form with school use; S06 retains explicitly known former retail form. Never promote an unknown small building to either converted form. Site boundaries, campus buildings and occupied frontages remain separate.

Each JSON row gives an area range, mapped levels and region candidate predicate. Resolve semantic class first, honor mapped footprint/roof/height/material/era, then filter compatible candidates. Region cannot choose a religion or school grade. Area/levels alone cannot pick a historic style, steeple, tower, bell frame or courtyard. Missing architectural evidence: fallback B plain mass, or explicit private Builder selection labelled authored. Tag-certain use and geometry-inferred form must be recorded separately. Commonness is an unverified review prior, not a production random weight. No location-specific IDs, names or geographic patches.

## Buildable assembly and detail

Coordinates: x across front, y toward rear, z up; front y=0. JSON rectangle components are nonoverlapping; union them before extruding, remove interior faces. C03 adds a rear half-disc centred(9,21),radius9; use12 segments near/6 aerial. Fit to mapped footprint without modifying topology; reject a candidate that requires invented wings. Main eaves apply to wings unless special feature height overrides; all floors remain level. Gables ridge along wing long axis; cross gables follow each wing; hip ridge on long axis; butterfly valley centred along wing; A-frame ridge18.71m; mono roof falls toward rear, parapet hides it. Flat roofs have0° deck, drainage out of scope. Tower dimensions are explicit features and require mapped/approved placement, not automatic use-tag inference. Window bays3m schools/4m churches, centre bays on each eligible wall; windows1.5×2m schools,1.1×2.6m churches, chapel0.8×1.2m; doorway1.8×2.4m; entry steps0.15m rise/0.30m tread, only where terrain requires. Walls0.25m visual thickness, trim0.12m face/0.04m depth, overhang0.35m. No accessibility compliance inferred.

These structural detail targets are authored here, subject to approval: bevel primary edges0.04m(two segments), stone surrounds0.06m; never round entire silhouette. Use calibration masonry/wood/plaster roughness0.82, painted-metal0.68, glass0.28 and flat dark panes; no individual bricks, tiles, grains, textured dirt or religious imagery. Use calibration exposure+0.35EV, saturation1.08 and contrast1.06 once; requested west sun270° replaces only the225° calibration fixture. No per-region lighting/exposure differences.

Projected building-height tiers on a390px-wide viewport: ≥120px retain entry recess and large mullions;40–119px retain bays, roof/tower and trim bands, drop small mullions;12–39px mass, roof, broad glazing only; <12px merge broad mass/roof colours without enlarging.40m and150m are view fixtures, not LOD triggers. Per-building authored caps: street2400main triangles, aerial600,800shadow triangles,3main material batches; unmeasured, not whole-scene passes. Reuse shared materials and instance repeats; shadows omit interior mullions. Measure scene floor400k/150k/100 and standard500k/180k/120 before implementation approval.

## Frame contract and review

Two equal panels per variant: left eye1.65m,40m from nearest facade,45°azimuth to front; right altitude150m AGL,45°down, target footprint centre. Choose FOV to contain whole mapped mass, record camera when implemented. Neutral concrete plane; no real place, signs, logos, public art or faith symbols. Big lot is schematic concept only; on maps use actual parking geometry. Generated perspective is illustrative, not verified camera matrices or a metric capture. Review at390px width for mass/colour identity; images cannot establish A3 engine scores. No code, captures or exports changed.

## Sameness check — all 43 within-type pairs

Axes are categorical footprint shape, occupied levels, roof form, wall material, colour family and era. Numeric size alone is not an axis. Every pair differs on at least3 axes; no pair shares both silhouette family and colour family.

|Pair|Differing axes|Count|Pass|
|---|---|---|---|
|C01/C02|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C01/C03|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C01/C04|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C01/C05|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C01/C06|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C01/C07|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C01/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C02/C03|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C02/C04|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C02/C05|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C02/C06|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C02/C07|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C02/C08|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|C03/C04|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C03/C05|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C03/C06|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C03/C07|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C03/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C04/C05|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C04/C06|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C04/C07|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C04/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C05/C06|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C05/C07|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C05/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C06/C07|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C06/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|C07/C08|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|S01/S02|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S01/S03|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S01/S04|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|S01/S05|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S01/S06|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S02/S03|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S02/S04|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S02/S05|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S02/S06|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|S03/S04|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S03/S05|footprint_shape, roof_form, wall_material, colour_family, era|5|yes|
|S03/S06|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S04/S05|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S04/S06|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|
|S05/S06|footprint_shape, levels, roof_form, wall_material, colour_family, era|6|yes|

## Used / Mock / Deviation

Used: docs/tracking/handoffs.md; docs/execution/archetypes.md §§1–3, rows17/20; style-b-calibration-v2/values.json#/sharedLook. Mock: frames/06-sloans.png and01-lakeview.png inspected in owner checkout. Deviation: R-requested muted palette and due-west sun270°, neutral isolated ground and new architecture instead of mock street composition; camera geometry and prevalence unverified; all new content pending approval.

[Phone-width gallery](index.html) · [Visual inspection and known deviations](visual-review.md) · [Image hashes](images/manifest.json).
