# Look-loop scoreboard

One row per run (`/lookloop`, or `Tools/lookloop/lookloop.sh run`), newest last. Views counts graded/captured and how many were reused unchanged; Regressions counts flags from the guard (latest/regressions.md). /50 is the mean v2 §8.3 score normalised over scorable criteria; AD is the art-direction mean (ground richness, rain readability, regional signature). Simulator frame time and triangles are for change tracking only, not device performance.

| Date | Engine | Branch | Views | Mean /50 | Ordinary /50 | AD /5 | Gate passes | Worst view | Median tris | Median frame ms | Run min | Grader | Regressions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-06 01:02 | `04d66ad` | p3-lookloop | 17/17 | 26.0 | 27.4 | 2.07 | 0 | showcase-11 18.8 | 401k | 16.69 | 16.9 | claude-opus-5-5 (gate) | – |
| 2026-10-06 06:39 | `651649b` | p3-lookloop | 17/17 | 27.5 (78% parity) | 28.9 | 2.06 | 0 (AD 0) | showcase-10 21.3 | 460k | 16.67 | 9.6 | claude-sonnet-5-5 | 11 |
