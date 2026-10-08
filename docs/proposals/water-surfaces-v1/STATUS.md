# Status

**R approved – 2026-10-07, for MECHANICS only:** the wave terms (the four-term wave model), foam, shore types (seawall, riprap, beach, marsh, marina), ice gating, live inputs (the live policy) and the performance budget.

**Water COLOUR is not approved here.** The approved lake pack (`lake-winter-v1`) and `style-b-calibration-v2` own water colour; Lake Michigan stays the #315F7F family (this pack's #477C8D is not used). Not compiled into `mock-values.json`: this pack's colour conditions and colour model, its reflection and roughness limits (minimum roughness 0.28), atmosphere and exposure, ice colours and ice roughness (0.55), and its copied lighting. `lake-winter-v1` stays authoritative for those (roughness floor 0.18, ice roughness 0.32) until R says otherwise. `lake-winter-v1`'s wave tables (two terms) are superseded by this pack's wave model for mechanics.

Compiled under `style-b/water`. The fetch and duration limiter and the budgets are authored proposals, not calibrated or measured; the live inputs are candidate source families whose coverage and licences P1 and L1 verify.
