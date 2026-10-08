# A2 overnight — 2026-10-08

Scope: `web/bakeoff/` only. Same exported geometry, source cameras, shared rules and fixed calibration-v2 boxes. Sloan always precedes untuned Lakeview; each capture freezes renderer/data/export/mock hashes. Lower mean ΔE76 is better. The boxes are surface-class samples, not image registration or an iOS parity grade.

Start: b012b71; Sloan 16.609379, Lakeview 22.258022. Preserved in `overnight/00-start/`.
Rollback gate: compare each candidate with the last accepted stage; if Sloan improves and Lakeview worsens, retain rejected evidence, restore only this step's implementation, and capture the restored state. No scene-specific rescue adjustments.
Atmosphere: approved `haze-visibility-v1/regions[front-range].seasons.summer.clear`, `regions[great-lakes].seasons.summer.clear`, `airlight.stateDayHex.clear`, `airlight.timeMix.day`, `integration.applyOnce`, `mountains` contrast/height/cloud gates. Trees' date-driven calendar prior is independent of these explicitly requested summer-clear atmosphere fixtures.
Disk guard: 83 GiB available before the first heavy capture (>8 GB). All capture/build verification uses `scripts/heavy.sh`; no other lane's lock is altered.

## 01-haze — ACCEPT
Ordered capture: Sloan then Lakeview, frozen inputs. sloans ΔE76 16.609379 (+0.000000), lakeview ΔE76 22.258022 (+0.000000).
Visual: Low pale real DEM ridge visible west of the shore; haze unchanged from approved prior round. Sloan still has regular water bands; Lakeview keeps the same pale crowns.
Evidence: `overnight/01-haze/`; Hold-out rollback condition did not trigger.
