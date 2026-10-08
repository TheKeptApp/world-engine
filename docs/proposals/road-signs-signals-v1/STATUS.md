# Status

**R approved – 2026-10-07.** This pack governs **signs and signals everywhere and all road markings outside the US**. `infrastructure-kit-v1` governs **US lane markings and crosswalks**; where the two differ the kit wins for the US (stripe gap 0.5 m here against 0.6 m there, yellow #CDB45D against #F0D067, white #E3E2D8 against #EEE9D9; listed in `docs/lookloop/mock-conflicts.md`).

Look comes from `style-b-calibration-v2` (the copied `sharedLook` is not compiled). Hexes and assembly dimensions are authored proposals; signal assemblies are verify-first; the budget (16k triangles, four batches, 1 MiB atlas, 0.25 ms GPU) is an allocation target, not an A16 measurement. Visual world dressing, not navigation or a compliant traffic-control plan; no readable text, names or brands.

Compiled under `style-b/road-signs` (countries by id).
