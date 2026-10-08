# A7 scoring tools and push guard

Scope: map scoring and local Git tooling only. No renderer, look, generator, bundled values or captures changed. Mock closeness is unchanged because this work only reports existing human judgments.

`finish.py` now accepts both full legacy grades and A3 calibration-only grades. Its JSON, summary and scoreboard carry Sloan's score and each frozen hold-out view's human calibration closeness. Required areas without captures remain PENDING. The frozen contract is `docs/lookloop/a3-capture-contract.json`; adding an area requires its reviewed capture contract, not a guessed view. Coverage is not clearance; the existing human hold-out regression review and full confirmation remain required.

The colour pre-screen uses whole-frame mean RGB distance from the first approved mock in stored signals. This is a deliberately small linear fit per grader, without mixing the Claude/A3 grader change. Sources are the existing `latest/grades.json` and A3 baseline evidence in `docs/lookloop`. Packs: `house-contrast-v1` hero images supply the signal references; `style-b-calibration-v2` supplies the human calibration-closeness target. There are no new look values.

Reproduce the fit with `python3 Tools/lookloop/colour_prescreen.py`. The recorded `docs/lookloop/colour-prescreen-fit.json` contains every input, fit coefficients, training MAE/RMSE and leave-view-out MAE. Current evidence: four observations per grader, eight total; all labels are 3/5. Both training errors and validation MAE are 0, but this is a constant-label baseline with **no demonstrated predictive ability**. Screening is unavailable until grades vary. New numeric screens are also withheld outside the fitting feature range. Never substitute this screen for visual grading or gate clearance. Future evaluation needs independently graded runs spanning quality levels; leave-view-out error alone does not establish generalisation to future runs.

Install with `scripts/install_push_guard.sh`. Git invokes `.githooks/pre-push` only on an explicit push; no schedule, commit hook or merge action is added. Existing hook configurations cause installation to stop for integration. This is a local guard, not server enforcement.

The guard reads Git's proposed ref updates and checks every outgoing commit, including intermediate versions later deleted. Deletion-only pushes send no new content. For a new branch it excludes known remote-tracking refs. Every new/changed blob is checked for recognisable credentials/private keys, personal email addresses or absolute home paths, and the 50 MiB limit. Generic agency role addresses and reserved example domains are allowed. Findings print only commit/blob IDs and categories, never matched values or filenames. Pattern matching cannot prove the absence of every secret or personal detail.

Mock freshness is recomputed from committed inputs in a temporary export, including street-geometry rules; dirty working files cannot hide a stale commit. The compiler's full values, slim bundle and conflict report must match. Nothing is regenerated or edited by the hook.

Instruction drift uses a reviewed fingerprint pair in `scripts/instruction-pair.json` because AGENTS.md and CLAUDE.md express the rules in different wording. A change to either requires both in that same commit and refreshed fingerprints after semantic review. This detects unreviewed drift; hashes cannot establish semantic equivalence. The initial pair is the existing source-of-truth/mirror pair; no rule was added or changed.

Validation covers A3 finish/publish in temporary folders, scoreboard column alignment, missing hold-outs, invalid scores, real flat-label evidence, fit error and grader separation, secrets/privacy, oversized and intermediate blobs, instruction drift, committed freshness and stale-output rejection. Existing lookloop conformance and wall-variant tests also apply.

The old exception-parser test assumed a removed rain exception remained approved. It now tests approved, proposed and removed rows using a fixture, without depending on the changing live exception ledger.
