# Look-loop scoreboard

One row per run (`/lookloop`, or `Tools/lookloop/lookloop.sh run`), newest last. Views counts graded/captured and how many were reused unchanged; Regressions counts flags from the guard (latest/regressions.md). **Parity** (first) is the mean concept parity: each view's /50 as a share of its target concept's calibrated /50; the gate is parity ≥ 100 % plus v2's per-criterion floors (milestones: ≥ 85 % at the end of 5A's wrap, ≥ 100 % by the end of 5B). Mean /50 is the v2 §8.3 score, kept as the long-term goal (40); AD is the art-direction mean (ground richness, rain readability, regional signature). Simulator frame time and triangles are for change tracking only, not device performance.

Rows before 6 Oct 2026 07:30 were re-expressed with the parity gate from their stored grades (the 01:02 row was graded before the GRADING.md tuning, see calibration.md).

| Date | Engine | Branch | Views | Parity | Gate passes | Ordinary parity | Mean /50 | AD /5 | Worst view | Median tris | Median frame ms | Run min | Grader | Regressions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-06 01:02 | `04d66ad` | p3-lookloop | 17/17 | **74%** | 0 (AD 0) | 77% | 26.0 | 2.07 | showcase-11 52% | 401k | 16.69 | 16.9 | claude-opus-5-5 (gate) | – |
| 2026-10-06 06:39 | `651649b` | p3-lookloop | 17/17 | **78%** | 0 (AD 0) | 82% | 27.5 | 2.06 | showcase-10 63% | 460k | 16.67 | 9.6 | claude-sonnet-5-5 | 11 |
| 2026-10-06 09:16 | `78e7541` | p3-lookloop | 32/32 | **77%** | 0 (5B 0) | 82% | 27.1 | 2.11 | wilmette-street-snow 58% | 95k | 16.75 | 35.0 | claude-opus-5-5 (gate) | 20 |
