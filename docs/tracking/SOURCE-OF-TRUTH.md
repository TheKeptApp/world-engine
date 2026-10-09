# Source of truth

The repository is the only source of truth. Chat memory, outside packs and informal reports are not build authority until their decisions, status and evidence are filed here. Local ignored images/data must match the repository’s recorded paths/hashes; if absent, record the missing input. Source-document suggestions are not permission to expand a task.

**Read first:** [R’s dated decisions](DECISIONS.md), then the [feature index](INDEX.md) and [complete mock registry](MOCKS.md). Read every research document and mock for each affected feature, not only the two familiar calibration frames; list them in the Used / Mock / Deviation evidence line. A report without feature research/mock references is incomplete. Current decisions supersede conflicting historical gate/process wording.

**Continue in order:** [STATE.md](STATE.md) → [INDEX.md](INDEX.md) → [INTEGRATION.md](INTEGRATION.md) → the relevant [REFERENCE-MAP](REFERENCE-MAP.md) row and its linked spec sections / [MOCKS.md](MOCKS.md) entries. Read the applicable lane rules and newest [handoff](handoffs.md) before acting. INDEX is the input inventory; INTEGRATION is implementation evidence; MOCKS is visual-reference evidence; STATE is the current handover. REFERENCE-MAP owns navigation, camera scope, visible checks and citation history, not approvals or scores. Keep history in handoffs and reports, not competing state files.

| Status | Required proof |
|---|---|
| not started | No traced renderer consumer for the named scope, or a specification only; state the audit’s limits. Filing, approval and compilation alone are insufficient. |
| partial | Name the reachable consumer file and implemented subset, plus the missing scope and evidence. |
| integrated | Name the renderer call path consuming the specified input, build commit and relevant tests. This proves the stated mechanism is wired, not a visual/performance pass. |
| verified (score moved) | Comparable A3 before/after grades and frames demonstrate an attributable improvement under matched conditions; name the run/commit, all aspects and untuned hold-outs, and pass relevant correctness/budget checks. Unchanged scores, grader changes and diagnostic colour differences are not this status. |

Pending or unapproved packs are never used in builds. Retain their inventory rows as unavailable/unused; explicit scoped owner approvals govern only their recorded scope. Superseded fields are not new targets. An authorized experiment uses its approved task/spec scope, with guessed coefficients labelled experimental; it does not approve a pending pack.

A feature is done only when a renderer file actually consumes it **and INTEGRATION.md records that consumption**. This is a necessary delivery condition, not permission to waive visual, performance or rights gates. The builder updates its INTEGRATION row, input consumption and mock citations **in the same commit**. A3 records actual scores; missing evidence stays pending. Update STATE after every report by rewriting its current snapshot; retain history in handoffs. Before a lane changes hands, its state note must be current.

Every build report lists every research doc and mock actually used in the evidence line immediately before `Tracker update:`; without a feature-specific research doc or mock it is incomplete. Compare the REFERENCE-MAP traits for the touched features, not only the two calibration frames. Record a missing mock as a gap/deviation. Reports are at most ten lines plus one evidence link, whose destination can contain the full list:

`Used: <doc §>. Mock: <file/frame>. Deviation: <none or why>`

Heavy builds/tests/rendering use `scripts/heavy.sh`, actual load <25 and only the job’s own lock; docs-only edits need no heavy lock. General rules only: no block-specific tuning; preserve frozen cameras/fixtures and reject focus gains paired with hold-out losses. No recurring automation, unattended merges, blocked-site bypass or guessed source rights. Conflicts outside add-only handoffs stop; handoff conflicts keep both entries in date order.
