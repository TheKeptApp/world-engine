# Look-gate tracker — A3

A3 owns scoring after R's 8 Oct takeover; Claude P3 is paused. No scheduled automation or auto-merges. Current reference: [A3 baseline](../lookloop/a3-baseline.md), captured main `0b9d255`, run `20261007-225009`. Look gate **FAIL, 0/4**; full hold-out coverage **PENDING**.

| Main / run | Sloan's score | hold-out score | Decision |
|---|---|---|---|
| `0b9d255` / `20261007-225009` | 3/5; foliage 2, other aspects 3 | Lakeview street 3/5 and postcard 3/5 (saturation 2, foliage 2); Wilmette 3/5 (foliage 2). West Highland proposed/pending data; Greenville deferred pending data. | New A3 baseline; FAIL 0/4. No cross-grader regression attribution; complete paired clearance pending. |

After each 5A/P2/A2 look merge, append its SHA and frozen-view run, each before/after closeness and aspect vector, colour/frame-diff evidence, and status. **REJECT-FLAG** a Sloan's gain paired with a hold-out loss; unchanged-frame score movement is grader variance and does not establish a look change. Missing required views are pending, never pass. Averages may not conceal an individual hold-out drop. A2 web captures require their own comparable renderer baseline. Update scoreboard, roadmap and handoffs with each reported result. No engine revert is authorized by a scoring flag.

## Foliage handoff — R, 8 Oct 2026

Foliage 2/5 in all 4 views, Lakeview saturation 2/5. Needs ONE general rule: layered/softer crown shading + region-driven greens. Owners: P2 (crowns), 5A (colour). Waiting for Claude restart.

Web merge `9b7403e` is isolated to `web/bakeoff/`; it leaves this iOS baseline unchanged. A3 web-specific scoring and complete hold-out coverage remain pending.

## Web baseline — 8 October 2026

The earlier pending web-baseline entry is superseded by this review; iOS scores above remain separate. [A3 web evidence](../lookloop/web-baseline.md).

| Renderer / build | Sloan's score (before → after) | hold-out score (before → after) | Decision |
|---|---|---|---|
| web / A2 `08e2cce` (unmerged at review) | — → 2/5; aspects — → 3/2/2/2/2/2 | Lakeview — → 2/5; aspects — → 3/2/2/2/2/3 | First A3 web baseline; pair FAIL 0/2; reject comparison N/A; full four-hero gate NOT EVALUATED. |

Aspect order: sky/light/saturation/ground/foliage/materials. Append each A2 merge's paired before/after scores and evidence here and in the scoreboard; reject-flag Sloan's gains paired with hold-out losses. West Highland pending data/export/camera. Greenville A1 data present, web export/camera pending. Current execution order: [map-only roadmap](roadmap.md).

**Publication update (8 Oct):** A2 `08e2cce` reached main while this report was being filed. Its captured look inputs are identical to the reviewed baseline. This is the initial A3 web baseline on that merge: Sloan's 2/5, Lakeview 2/5; no comparable pre-merge A3 web score exists, so the reject comparison remains N/A, not a pass.

## Web visual review — 8 Oct 2026

| Renderer / merge | Sloan’s score | hold-out score | Decision |
|---|---|---|---|
| web / 5c72bad | Sloan's 2 → 2; aspects 3/2/2/2/2/2 → same | Lakeview 2 → 2; aspects 3/2/2/2/2/3 → same | Pair FAIL 0/2; reject condition not triggered; flag no closeness gain. Foliage fixture changed; causal comparison limited. |

[Evidence](../lookloop/web-5c72bad.md). Aspect order: sky/light/saturation/ground/foliage/materials. ΔE ignored.

## West Highland decision — R / A3, 8 Oct 2026

West Highland camera `west-highland-aerial-north-01` confirmed unchanged and frozen (8 Oct): target (39.764, -105.04), scene y=0 m; eye (39.759946, -105.04), scene y=350 m; vertical FOV 47°, portrait 390×780. Shared atmosphere contract must accompany capture. R reports 19.1% height / 19.0% roof-form coverage, versus Lakeview heights 93.5% and Sloan's 29.1%. Separate data-poor hold-out; score/capture pending. A1 sparse-density test pending; ladder NOT PROMOTED. Earlier camera-pending notes are historical; source/package delivery must still be evidenced. [Frozen contract and cohort note](../lookloop/west-highland-holdout.md).
