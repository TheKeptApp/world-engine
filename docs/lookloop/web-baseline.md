# A3 web baseline — 8 October 2026

**Web pair: FAIL, 0/2.** Full four-hero gate: **NOT EVALUATED**. A3 independently reviewed A2 candidate `08e2cce`, not merged on main at review (`eb9bba6`). This baseline is separate from [iOS](a3-baseline.md); no renderer-to-renderer score delta is claimed. Same §M rubric and calibration-v2 targets, using the same frozen A2 portrait views. Grader: A3-Codex; first A3 web grade, not a comparison with earlier Claude grades.

| View / target | Closeness | Sky | Light | Saturation | Ground | Foliage | Materials |
|---|---|---|---|---|---|---|---|
| Sloan's / 06-sloans | 2 | 3 | 2 | 2 | 2 | 2 | 2 |
| Lakeview / 01-lakeview | 2 | 3 | 2 | 2 | 2 | 2 | 3 |

Scores are out of five. Pair threshold applies the §M per-view requirements: closeness ≥4 and every aspect ≥3. Two views cannot clear the project's four-hero gate or its confirmation requirement.

## Visual findings

- **Sloan's:** pale sky is broadly plausible, but distant surfaces wash into cyan and the light lacks the reference's directional modelling. Lawn and path read as uniform fills; water has conspicuous horizontal bands. Crowns have little soft internal shading. These light, surface and foliage gaps support closeness 2.
- **Lakeview:** matte building surfaces read reasonably, but light and pavement remain flat. Large smooth crown lobes have visible overlap without the reference's soft layered shading; green/grey colour relationships remain distant from the target. Closeness 2.

No penalties for different layout, absent actors, fine leaf/brick texture, building hue or mountain geometry. Haze is assessed by its visible effect on light and material separation, not by demanding painted geography. A2 documents the unresolved pack haze conflict in the [filed rules](../tracking/A2-RULES.md); scoring does not authorize a local override.

## Capture and provenance

A3 visually inspected the candidate PNGs and approved calibration-v2 frames. These are **verified saved captures, not newly rendered frames**. Capture times and image hashes are in [grades.json](web-baseline/grades.json). A2 rebased from `4b96e56` to `08e2cce` during review and refreshed captures; A3 reviewed the refreshed images. The read-only live input hash still matches the refreshed capture manifest exactly: `93061a2e8440bef101ee2b22ee201bb1a15c20103888d50535021cfdd62a73ca`, zero changed inputs. All eight before/after capture events have that digest, ordered Sloan's then Lakeview.

[Capture proof](web-baseline/holdout-proof.json), [frozen cameras](web-baseline/scenes.json), [fixture](web-baseline/fixture.json). PNGs are local-only under `/private/tmp/worldengine-a3-web-baseline/.build/lookloop/web-a3-08e2cce/`; source captures remain in A2's `web/bakeoff/evidence/candidate/`. Images are not committed. The filed RULES snapshot is byte-identical to A2 `08e2cce`; its hash is in grades.json.

Sloan's viewport is 390×585, FOV 35; Lakeview is 390×780, FOV 47. Both use the shared simulated summer/clear fixture, 10 km/h wind and pack-derived sun. WebGL2 on the captured Mac is not phone-performance evidence. A2's existing-viewer control labelled `baseline` is a different renderer, **not** a prior A3 web score. Its colour/difference report cannot establish a before/after merge improvement. Fixed region boxes can sample different surfaces between those renderers; no composition-confounded colour mean is used as a visual grade.

## Subsequent merges

For every A2 merge, A3 records merged SHA, candidate/input hashes, capture IDs, Sloan's and Lakeview before/after closeness **and all six aspects**, plus paired frame-difference evidence under §N. Keep these views, fixture, targets and grader fixed, with identical code and no hold-out tuning. A changed contract requires an explicit new baseline, not a progress claim. Unchanged-frame score movement is grader variance; preserve prior grades for unchanged views. Reject-flag a Sloan's gain with a Lakeview/required hold-out loss, retaining individual scores rather than an average. Missing evidence stays pending. A flag does not authorize an engine revert.

West Highland remains pending A1 data/export and a frozen camera. Greenville's A1 area, heights and roof evidence now exist, but its web export and frozen camera remain pending; no visual score is inferred from data quality checks. The requested web comparison is Sloan's plus Lakeview; no Wilmette web capture was supplied. No scheduled automation or unattended merges.

**Publication update (8 Oct):** A2 `08e2cce` reached main while this report was being filed. Its captured look inputs are identical to the reviewed baseline. This is the initial A3 web baseline on that merge: Sloan's 2/5, Lakeview 2/5; no comparable pre-merge A3 web score exists, so the reject comparison remains N/A, not a pass.
