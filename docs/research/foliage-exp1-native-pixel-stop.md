# Native foliage experiment 1: strict pixel gate stopped

8 October 2026. Approved mask amendment merged as `66aac35`; implementation remains on local branch `astra/a10-native-foliage-exp1`, diagnostic head `bba0a3a`, and is not merged.

The arithmetic witnesses and generated exclusion tests pass. Native Metal compilation passes. The isolated native rendered controls fail the required exact identity gate: `Expectation failed: (maximum → 1) == 0`, `FoliageExperimentTests.swift:130:25`. For bush (including flower-bush), conifer and other non-mask controls, maximum RGBA byte difference is **1/255** in **each** off/remove/layered mode, at both leaf fractions 1 and 0: 18 failures. Other controls include tuft, bark, skyline crown and leaf cards. This is macOS RealityKit fixture evidence, not iPhone or Sloan’s evidence.

An unchanged-baseline shader repeat passes every category/mode with maximum difference **0**. A separate early-return baseline path in the candidate still fails with the same maximum 1. Shader code-generation/precision changes are a possible explanation, not a proved cause. Do not weaken the zero threshold, adjust images, claim mode-off identity, or score this experiment.

Final verification admitted through `scripts/heavy.sh` at load **8.83**, with zero seconds waiting; no A4/A7 lock bypass. Heavy job exits 1 and releases its lock. Sloan’s 40/150/600 m baseline and three-mode captures were not started because the prerequisite pixel gate failed. Shipping main retains its original foliage shader. Capture command extensions and runtime selection remain only on the unmerged branch.

Local diagnostics (ignored build output): `/private/tmp/worldengine-a10/.build/a10-foliage-exp1/controls`, `baseline-repeat`, `first-gpu-proof.log`; last verification log `/private/tmp/a10-foliage-heavy.log`. Baseline repeat images are controls, not experimental captures.

Used: foliage-exp1-spec.md Exact candidate math / Mask / Cost and stop conditions; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png (reference only). Deviation: strict rendered identity failed; no Sloan’s captures, native integration or A3 score.

Diagnostic baseline.metal SHA-256: `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`.

Diagnostic candidate.metal SHA-256: `43b7ae59186dbf3d4353a9251aed6076d46da4f3ee1a2e36e56d2f59d016f50b`.
