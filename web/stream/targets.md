# A4 current targets — R decision, 9 October 2026

Authoritative desktop criteria: [approved streaming-design §§7,15,17](../../docs/design/streaming-design.md). About 20 **other** Chrome tabs open, normal apps running, viewer foreground. Every streaming flight has an uploads-disabled control at the same speed/profile/package/route/duration/viewport. Record exact other-tab count, normal apps and maximum observed load **per flight and control**, including sampling cadence/gaps. Load <5 is optional quiet-reference evidence, not a validity condition.

| Metric | Current target/report requirement |
|---|---|
| Staged whole-step upload CPU, all foreground frames including zero-work | p99 ≤0.5 ms; max ≤2 ms; includes binds/queries/allocation/copy/restoration/telemetry |
| Renderer-side buffer uploads | Report peak and attribution separately; control still includes baseline renderer uploads; no all-context ≤0.5 ms maximum gate |
| Frame interval p99 | ≤20 ms |
| Intervals >33.33 ms | ≤0.1% |
| Compiles after startup | 0 |
| Completed detail groups per streaming flight | >0; control zero-detail is intentional |
| Resident geometry including partial construction | ≤48 MiB; report excluded memory honestly |
| Browser profile | About 20 other Chrome tabs, exact count and max load for each run, same normal apps for each pair |
| Unchanged coverage/queue/render limits | No holes, missing coarse coverage 0; staged reservations ≤16 MiB; ≤1 active primitive/frame; ≤100 main draws, <400k main triangles |

Results on this M1 Max do not prove mid-range laptop behavior; a lower-tier check is a later step. Desktop evidence also does not qualify a phone. A runtime JSON diagnostic/strict label reflects the earlier quiet-only rule and does not alone determine validity under this new decision; assess the raw run against every current criterion and profile evidence. No runtime code changed here. Do not retroactively promote earlier captures without tab counts and matching profiles.

## Historical targets and evidence — superseded for current desktop upload/load acceptance

The following text preserves the old decision/evidence. Its all-context upload maximum and quiet validity rules are historical, not current targets.

# A4 current target comparison — review-fixes-v2
Existing package-format, mobile-rendering-v1 streaming-design §7 and R’s additional desktop-Chrome criteria remain unchanged. Latest raw-backed evidence: human-review2-lakeview-both-long.json.gz and its summary; earlier original/adaptive results remain historical evidence.

| Metric | Target | Lakeview 60 m/s | Lakeview 600 m/s |
|---|---|---|---|
| Resident CPU geometry including partial meshes | ≤48 MiB | 44.40 MiB PASS | 25.86 MiB PASS |
| Decoded staging peak | ≤16 MiB reservation | 14.89 MiB PASS | 13.23 MiB PASS |
| Worst two independent leaf payloads | ≤16 MiB | A1 audited 3.983 MiB PASS | Same package PASS |
| Upload API CPU sum/frame, all context calls | ≤0.5 ms | 2.2 ms; 97 overrun frames FAIL | 3.3 ms; 64 overrun frames FAIL |
| Main draws / triangles | ≤100 / <400k | 23 / 197978 PASS | 22 / 135472 PASS |
| Required groups without coarse representation | 0 | 0 PASS (counter only) | 0 PASS (counter only) |
| Upload concurrency | ≤1 active primitive/frame | 1 PASS | 1 PASS |
| Desktop p99 interval | ≤20 ms | 17.8 ms PASS | 17.7 ms PASS |
| Desktop intervals >33.33 ms | ≤0.1% | 0.38149% FAIL | 0.08356% PASS |
| New detail completion (functional evidence) | Must not claim detail from coarse-only coverage | 103 groups | 0; refinement starves |
| JS heap, outside resident ledger | Report, no invented target | 963.31 MiB | 1744.02 MiB |

A1 packaging request is satisfied by current ≤8 MiB decoded leaves and ≤2 MiB decoded primitive parts; worst Sloan pair is 3.582 MiB, Lakeview 3.983 MiB. No further tile-file change is justified by this queue audit alone. 64 KiB runtime copies remove the permanent shrink but cannot preempt a slow API call; total ≤0.5 ms remains a FAIL. Shared materials/precompile reduce measured render CPU but precompile peaks 37.1/38.6 ms precede most long intervals; association is not GPU causality. Next work must address pipeline preparation, cancellation churn, detail starvation and measurement-heap overhead before another identical rerun. New Sloan flight and matched artifact classification remain pending human captures. No merge without R’s further instruction.


## startup-warm-v3 — unverified preparation, no new measurements
The prior table is historical review-fixes-v2 evidence. Required new table adds zero shader compiles/links/material creations after startup, completed detail groups >0 per STREAM run, and long-interval percentages for both upload-disabled controls. The upload column must include both whole staged-step+outside-renderer-upload CPU and the unchanged context-wide upload API sum; both ≤0.5 ms. No pass is possible from zero completed detail or from control results. One primitive may now use several bounded calls within the measured whole-step budget; slices adapt both ways. Validation wrapper refused after 600 s at load 52.43; tests/build and runtime cells remain unmeasured. No server or automation is running; do not use the previous built bundle.
