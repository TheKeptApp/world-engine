# A2 → A4 streaming validation — blocked

R authorized one-time, read-only validation of A4's streaming viewer with headed Chrome on localhost, under the heavy lock with load below 25. Requested order: Sloan at 60 m/s for 60 seconds, Sloan at 600 m/s for 60 seconds, then unchanged Lakeview.

The A4 implementation is in the primary checkout at `0dcf2f8c18e2360dfc3dd7f02a0105a533fe1c5e`, on `astra/a4-streaming-prototype`; it is not present in this evidence branch's main-based tree. Its `web/stream/REPORT.md` says localhost was denied because the browser tool could not verify an administrator-enforced security policy and identifies another Chrome driver as a bypass. `overnight-progress.json` independently records that blocked status. The authorized handoff does not resolve the administrator-policy verification failure. A2 did not launch another driver or attempt a different localhost route.

Serving instructions were read from A4's `README.md` and `serve.mjs`: existing server binds only `127.0.0.1:8784`, supports `?area=...`, and the two UI flight buttons run 60-second out-and-back paths. The server's current gate is strictly load <25; README's older half-core/idle gate differs. No server, build, browser trial or heavy job was started in this handoff.

| Requested view/run | FPS median / p5 / p1 | Tile-load median / p95 | Tiles without coverage | Memory | Load before |
|---|---|---|---|---|---|
| Sloan 60 m/s, 60 s | Not measured | Not measured | Not measured | Not measured | Not measured |
| Sloan 600 m/s, 60 s | Not measured | Not measured | Not measured | Not measured | Not measured |
| Lakeview unchanged | Not measured | Not measured | Not measured | Not measured | Not measured |

A4 reports Apple M1 Max (10 CPU / 24 GPU cores); this is source metadata, not a fresh runtime measurement. No prior load or packing figures are presented as current browser results. `blocked.json` retains null measurements and hashes of the inspected top-level A4 files. No `web/stream/` file was edited. This is a blocker record, not completed validation or permission to merge A4's implementation.

Required next step: restore administrator-policy verification for an authorized browser route, then perform the requested sequence under the real heavy lock with a fresh load check below 25. Do not substitute a different driver to evade the denial.
