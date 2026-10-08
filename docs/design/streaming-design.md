# Streaming design — approved desktop browser validation amendment

**R decision, 9 October 2026.** This amendment supersedes the earlier A4 quiet-machine validity requirement and all-context maximum-upload ≤0.5 ms gate **for desktop Chrome streaming validation only**. It supplements [mobile-rendering-v1 streaming-design](../research-gpt/mobile-rendering-v1/streaming-design.md); unmodified native/A16 assumptions, queue/draw/triangle budgets and approved look values remain in that document. This is an acceptance decision, not measured proof of a pass.

## 7. Residency, queues and memory

Validate with **about 20 other Chrome tabs open and normal apps running**. Record the exact number of other Chrome tabs (excluding the viewer) and normal apps at the start of each streaming flight and its paired uploads-disabled control. Keep the same tab/app profile, package, speed, route, duration, viewport and device for the pair. Each flight needs its own paired control; do not reuse one control across speeds. Record timestamped load samples and **maximum observed one-minute load per flight**, with sample cadence and gaps. Load <5 is an **optional quiet reference run**, not a validity condition; a load spike ≥5 does not invalidate a realistic-profile flight.

| Desktop Chrome metric | Approved pass/report criterion |
|---|---|
| Staged uploader whole-step CPU per frame | **p99 ≤0.5 ms; max ≤2 ms**, including queries, binds, copies/allocation, restoration and uploader telemetry |
| Renderer-side buffer upload CPU | **Report peak and attribute** to uniform/vertex/index buffers, mesh/binding when recorded, allocation versus update, calls/bytes and frame; separate from staged whole-step, no invented numeric gate |
| Resident geometry including partial construction | **≤48 MiB**; retain honest exclusions for driver/GPU textures/targets, worker overhead and total process/heap memory |

Compute staged percentiles across all measured foreground flight frames, including frames with no staged work. Do not double-count staged GL API time already inside the whole step. A control disables tile fetching/staged uploads; baseline renderer uniform updates may remain and must be reported. Do not subtract independently occurring maxima to invent an attributable streaming cost. Existing staging ≤16 MiB, ≤1 active primitive per frame, main draws ≤100 and triangles <400k remain unchanged.

## 15. Seamless refinement and useful detail

**Compiles after startup: 0. Completed detail groups loaded: >0 per streaming flight.** A zero-detail streaming flight fails even with coarse coverage. Control zero-detail is intentional and never substituted for this requirement. Record program/link/material-creation counters separately when available; missing attribution remains missing, not zero.

Keep atomic coverage: retain a valid outgoing/coarse representation until the complete replacement group is ready, and reserve both representations during a transition. No holes; zero missing-coverage counters alone are not pixel-level visual proof. Review visible popping, overlap and silhouette transitions alongside timing; the revised upload criteria do not waive visual requirements. Each streaming flight is paired with its uploads-disabled control under the same realistic browser profile.

## 17. Desktop frame timing and qualification limits

| Desktop Chrome metric | Approved criterion |
|---|---|
| Frame interval p99 | **≤20 ms** |
| Intervals strictly >33.33 ms | **≤0.1%** of measured foreground intervals |
| Post-startup compiles | **0** |
| Completed streaming detail groups | **>0** |
| Resident geometry | **≤48 MiB** |
| Staged whole-step upload | **p99 ≤0.5 ms; max ≤2 ms** |
| Renderer-side upload | Peak reported and attributed; paired control reported |
| Browser profile evidence | Exact other-tab count and max observed load for each flight/control, normal apps and matching conditions recorded |

Results on this **M1 Max do not prove mid-range laptop behavior; a lower-tier check is a later step**. Nor do desktop results qualify a phone or change native A16 GPU targets. Quiet reference runs may be kept separately, but cannot replace the realistic-profile runs. Historical captures without tab-count/profile evidence cannot establish this newly approved pass. Preserve raw measurements and state attribution limits.

Source: R’s “Record the new streaming pass criteria” decision, 9 October 2026. No runtime gate, code, renderer or look change is authorized by this documentation update itself.
