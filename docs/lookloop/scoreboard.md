# Look-loop scoreboard

One row per run (`/lookloop`, or `Tools/lookloop/lookloop.sh run`), newest last. Views counts graded/captured and how many were reused unchanged; Regressions counts flags from the guard (latest/regressions.md). **Parity** (first) is the mean concept parity: each view's /50 as a share of its target concept's calibrated /50; the gate is parity ≥ 100 % plus v2's per-criterion floors (milestones: ≥ 85 % at the end of 5A's wrap, ≥ 100 % by the end of 5B). Mean /50 is the v2 §8.3 score, kept as the long-term goal (40); AD is the art-direction mean (ground richness, rain readability, regional signature). Simulator frame time and triangles are for change tracking only, not device performance.

Rows before 6 Oct 2026 07:30 were re-expressed with the parity gate from their stored grades (the 01:02 row was graded before the GRADING.md tuning, see calibration.md).

| Date | Engine | Branch | Views | Parity | Gate passes | Ordinary parity | Mean /50 | AD /5 | Worst view | Median tris | Median frame ms | Run min | Grader | Regressions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-06 01:02 | `04d66ad` | p3-lookloop | 17/17 | **74%** | 0 (AD 0) | 77% | 26.0 | 2.07 | showcase-11 52% | 401k | 16.69 | 16.9 | claude-opus-5-5 (gate) | – |
| 2026-10-06 06:39 | `651649b` | p3-lookloop | 17/17 | **78%** | 0 (AD 0) | 82% | 27.5 | 2.06 | showcase-10 63% | 460k | 16.67 | 9.6 | claude-sonnet-5-5 | 11 |
| 2026-10-06 09:16 | `78e7541` | p3-lookloop | 32/32 | **77%** | 0 (5B 0) | 82% | 27.1 | 2.11 | wilmette-street-snow 58% | 95k | 16.75 | 35.0 | claude-opus-5-5 (gate) | 20 |
| 2026-10-06 12:40 | `0125f38` | p3-lookloop | 32/32 | **76%** | 0 (5B 0) | 75% | 26.9 | 2.23 | showcase-11 52% | 95k | 16.72 | 16.0 | claude-opus-5-5 (gate) | 51 |
| 2026-10-06 13:24 | `8727461` | p3-lookloop | 32/32 | **82%** | 0 (5B 0) | 83% | 28.8 | 2.46 | showcase-11 55% | 121k | 16.67 | 15.4 | claude-sonnet-5-5 | 6 |

**Delta 13:24 (routine, P2 yards ad2ebfc) vs ccb5f77 gate (12:40):** parity 76 → 82 % (+6) · ordinary-day 75 → 83 % · ground mean 1.88 → 2.09 · art direction 2.23 → 2.46 · region buildings & ground 2.42 → 2.6 · aerials v2-06 23.8 → 23.8, showcase-10 21.3 → 22.5, showcase-11 18.8 → 20.0, wilmette 30.0 → 30.0, evanston 30.0 → 33.8, lakeview 28.8 → 31.3. No view down > 3 points (largest drop 0). Caution: Sonnet routine grader vs Opus gate grader; part of the rise may be grader leniency. Parity < 85 %, so no full gate yet.

**Same-grader check (Sonnet re-grade of the ccb5f77 gate frames, no new render):** parity 82.3 % · ordinary-day 83.7 % · region 86.3 % · v2 29.1 · art direction 2.45 · ground 2.03. Against the Sonnet yards run (ad2ebfc): parity 82.3 → 81.7 % · ordinary-day 83.7 → 83.0 % · region 86.3 → 86.3 % · v2 29.1 → 28.8 · art direction 2.45 → 2.46 · ground 2.03 → 2.09. **The +6 parity in the 13:24 row was the grader (Opus → Sonnet), not the yards: grader-to-grader the yards are flat (ground +0.06).** Per-view moves are within ±2.5 except showcase-11 23.8 → 20.0 (flagged in regressions.md). Grader rule from now: routine rows = claude-sonnet-5-5, gate rows = claude-opus-5-5 (gate); the Graders column names which. Compare rows only within one grader.
| 2026-10-06 13:50 | `f7ca60b` | p3-lookloop | 32/32 | **84%** | 2 (5B 1) | 85% | 29.6 | 2.57 | showcase-11 69% | 121k | 16.86 | 11.6 | claude-sonnet-5-5 | 14 |

**Delta 13:50 (routine, Sonnet, 5A 35827f6: context rings, teal fix, smoke veil, low-sun shadows, wet ground) vs ccb5f77 gate frames re-graded by Sonnet (same grader):** parity 82.3 → 84.3 % · ordinary-day 83.7 → 84.7 % · v2 29.1 → 29.6 · art direction 2.45 → 2.57 · ground 2.03 → 2.31 · depth/fog 2.91 → 2.97 · gate passes 0 → 2 (5B 0 → 1). Aerials: v2-06 22.5 → 26.3 (fog 2 → 3), showcase-10 22.5 → 26.3 (fog 1 → 3), showcase-11 23.8 → 25.0, wilmette 30.0 → 31.3, lakeview 30.0 → 31.3, evanston 36.3 → 31.3 (flagged). Parity < 85 %, so no full gate yet.

**Gate trigger raised (owner, 6 Oct 2026):** a full Opus `--gate` run starts only when a routine (Sonnet) loop reaches mean parity ≥ 90 % (was 85 %). Reason: on identical frames (ccb5f77) Sonnet scored 82.3 % against Opus 76.3 %, about 6 points high, so a Sonnet 85 % is about 79 % on the Opus scale and still below the 85 % milestone. Milestones themselves stay on the Opus scale (gate rows).
