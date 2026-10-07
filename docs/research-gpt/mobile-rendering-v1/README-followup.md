# Streaming design + RealityKit check — read-only follow-up

**7 October 2026. Proposal for R; Claude lane review before code.**

The repo already has iOS 26, RealityView, explicit instancing, building/foliage LODs, opaque distant trees and thermal resolution control. The highest-value next step is bounded tile residency with one shared export, building on those mechanisms rather than recreating them.

- [compatibility.md](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/compatibility.md) — actual view/API paths, top-10 adoption matrix, OS floors, counter semantics, tree opacity and export gaps. Code-reading conclusions are labeled **inferred**.
- [streaming-design.md](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/streaming-design.md) — 200 m ground leaves / 100 m building cells / 400–1,600 m parents; tile/metadata contract, projected selection, prefetch, memory/work limits, launch and three.js reuse; seven phases totaling an **assumed 21–36 engineer-days**.

## Corrections to the generic research

- **Inferred:** RealityView is the public view; an ARView hierarchy probe controls scale. Probe reliability requires runtime review.
- **Inferred:** native ≤100 draws / <400k triangles gates are **main-view bounds estimates**, excluding shadow repetition and host characters; v2 separately specifies 150k shadow triangles. They are not all-pass hardware counters.
- **Inferred:** foliage is opaque outside the nearby cut-away slot, and skyline trees already use about 12 triangles. Textured impostors are an optional experiment, not the first win.
- **Inferred:** current owner look data sets sun shadows to **120 m / 150 m at low sun**. The design preserves that policy pending review.
- **Unverified — checkout behind main:** user-described P1 mapmeta/confidence/migrations, independent slope and NJ structured lot/access export are absent here. The proposal fits inspected package/1 and specifies preservation requirements for the newer fields without inventing their schema.

## Scope and evidence

Read-only sources: the active `~/Desktop/world-engine` checkout, its existing exported Sloan's Lake package, installed iOS 26.4 public SDK declarations, prior research pack and public documentation. No other lane worktree was inspected. No repo edits, git, builds, tests or app runs were performed. Runtime availability, performance, memory ceilings and the actual newer P1 schema remain unverified.

The previous [README.md](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/README.md), techniques.csv and sources.md are preserved. This uniquely named README satisfies the request to add files without overwriting the earlier README.

Proposed reviewers: P1/map/NJ for identity/provenance/slope contract; P2/engine for loader, residency, instances/shadows/API surface; P3/look/perf for visual equivalence and budget acceptance; web lane for shared tile reuse. No messages were sent and no implementation was initiated.
