# Handoff: P2 (buildings, yards) — paused 2026-10-06 for the usage limit

## Done and on origin/main
Facades (a8cf90c), yards + zones (fd1680f), relative thresholds (b8f6c71), Wilmette area with Overture
(680d47b), canopy calibration (77962e2), hedges (64cab0b), lidar roof complexity + roof decisions in
scene.json (56addf9), map fixes (1085568). Design and decisions: docs/buildings/README.md (1–33), yards.md.

## In progress: branch `p2/yards` at 5dad679 (pushed, NOT merged; tests not yet green)
Look-fix v1 §1/§2 pass: regional densities (yards.json), lawn value steps between neighbouring lots,
`lawnA`/`lawnB` seasonal palette keys + lot tone in vertex extra.y and seed in extra.w (5A switches its
lawn shader in the same merge — tell 5A the merge commit), bed areas, Lakeview front gardens / paved
rear yards / iron and alley fences, detached garages behind houses, floors from measured height,
litter patches, tone guard (no hex changed).

Last test run (before the final fixes in 5dad679) failed on: (a) neighbouring-lot value steps outside
4–10 % for 9–21 % of pairs (fix: wider neighbour search, now committed, unverified); (b) a garden shrub
inside a building (fix committed, unverified). Shrubs in view are 11–24k tris vs look-fix §7's
suggested 4k: Lakeview garden density was halved; still over — needs a decision or cheaper shrub LODs.

## Exact next step
1. Replace the TEMPORARY Overture guard in BuildingGenerator.generate (`lowOvertureHouse`, "< 6 m") with
   P1's rule: ignore Overture heights on footprints ≥ 90 m² (P1 implements this data-side after resume;
   then delete the guard entirely).
2. Through the lock wrapper (scratchpad heavy.sh, or take ~/.agent-heavy-lock by hand):
   `swift test --filter "LookFixYard|YardTests|BuildingRoleTests|BuildingGeometryTests|RoofEnvelope|BuildingAreaTests"`,
   fix, then full `swift test`, merge p2/yards to main (detached merge worktree, `git push origin HEAD:main`),
   message 5A (lawn shader switch) and P3 (rerun region views).
3. Road-width map fix (separate merge): RoadRules uses lanes × 3.3 m only (W Roscoe St lanes=1 → 3.3 m);
   add parking allowance (2.3 m per side, assumed both sides on untagged residential/tertiary/unclassified),
   residential default 6 → 8 m, clamp so carriageways never reach mapped sidewalks; tell P3 (lakeview-postcard geography).
4. Shrub-form sub-agent: branch `worktree-agent-a0a5538e9eea80aaf` (stopped at a safe point; needs LOD
   level 3 for 5A's new 4-level bush LODs and a rebase onto 5A's bush changes), then select the new
   forms in yards (cushions in beds/gardens, upright at corners, hedge segments for hedges).

## Waiting on the owner
- Evanston roof pitch and gable/hip mix toward the lidar pilot (P1 holds it; I support it).
- Shrub view budget: accept ~10k tris for near shrubs (look-fix §1.2 densities) or hold to §7's 4k.

## Coordination state
5A: tone targets in docs/m3/tone-targets.md (fill fix pending; no palette lift); bush LODs now 4 levels;
tree variety via per-tree stretch. P1: Overture ML heights −2.35 m vs lidar (rule pending), canopy and tree
heights from lidar coming. P3: region run 2.3/5 building+ground average; reruns after my merges.

## Shrub-form branch (sub-agent, stopped)
`worktree-agent-a0a5538e9eea80aaf` at 86a754f (local only): Props.swift bush/flowerBush variants 2/6/7 cushions,
3 loose (leans ~7°), 4 upright, 5 hedge segment (1 m along +X); near 72 (flower 80) / mid 24 / far 8 /
skyline 3 tris; variants 0/1 byte-identical. Full suite passed before the last hedge tweak (untested).
Next: rebase onto 5A's phase5b bush changes, rerun tests, then make yards pick the forms and give
variant 5 the hedge row's direction as yaw.
