# A3 native foliage exp1 — nine-frame blind review, 8 October 2026

> **Attribution correction — 9 Oct 2026:** R’s 9 Oct correction, relaying A10: the 600 m layered coverage loss was a capture loading race, not a variant defect. Original frames/grades remain unchanged; no repeat capture or new score is claimed. The below cause-unknown warning records the original review; its cause is now resolved.

**Result: no demonstrated foliage improvement. Do not promote layered as a look improvement.** All nine inspection frames score foliage **2/5**, overall calibration closeness **2/5**. This is a review of supplied frames only, not a new capture/build or a four-hero gate. Hold-outs remain pending. The 600 m layered frame also has a visible coverage mismatch requiring investigation before a clean paired conclusion.

## Method and provenance

Read [A10 FINAL evidence, 3f347f1](../research/foliage-exp1-native-final-evidence.md) and GRADING.md §M/§N. Copied the nine original PNGs unchanged to `/private/tmp/a3-exp1-blind-review/`, randomly shuffled with system randomness into A–I, and withheld the mode/altitude key from the grader. Inspected all nine neutral frames and approved calibration `frames/06-sloans.png`; locked the grades/reasons in `blind-scores-locked.json` before reading `sealed-key.json`. Altitude is visually apparent; mode labels were hidden. No ΔE determined grades. All nine original SHA-256 values independently match A10’s batch.json; originals remain untouched. The [score record](foliage-exp1-native-scores.json) contains the revealed key, hashes, locked time and per-frame grades.

Capture build `ec14fed65c358c8b1271a93b61b1d5124ff8c5f8`, nine 1005×565 iOS Simulator frames. Source root: `/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/`, each `{baseline,remove,layered}/{40,150,600}/raw/ordinary-street-afternoon.png`. A10’s numeric category gate passed under R’s FINAL tolerance; that proves neither visual gain nor identical scene coverage. No iPhone performance claim.

## Locked grades, then unblinded

Each entry is **foliage / overall**, out of 5.

| Altitude AGL | Baseline | Remove | Layered | Blind labels baseline / remove / layered |
|---|---|---|---|---|
| 40 m | 2 / 2 | 2 / 2 | 2 / 2 | C / G / H |
| 150 m | 2 / 2 | 2 / 2 | 2 / 2 | B / I / E |
| 600 m | 2 / 2 | 2 / 2 | 2 / 2 | D / F / A |

**Layered does not move foliage from 2 to 3 at any altitude.** At 40 m crowns remain large faceted blobs with angular outlines, few broad lobes and abrupt lobe joins. Minor shading differences do not give the mock’s layered organic crown response. At 150 m the same simplified forms and vivid yellow/orange masses dominate; at 600 m individual crowns are too small to establish better internal modelling. No geometry/layout penalty is inferred merely because the calibration painting uses another camera. The overall 2 is for these inspection frames’ visible look; the historical street-hero 3/5 remains unchanged and is not a controlled 3→2 regression.

Other §M aspects, for visible portions of all nine frames: light 2, saturation 2, ground 2, materials 2. Sky is **not assessable** in these downward inspection views; the grey exterior field is not a sky assessment. AO and water are qualitative checks, not additional official §M score axes. No clear visible AO/contact-shadow, ground-material or saturation worsening at 40/150 m. Water is absent at 40 m and only a narrow strip at 150 m; at 600 m it remains a broad, uniform cyan surface with a bright glint, without a clear additional degradation attributable to layered. These are visual observations, not numeric isolation tests or proof that unseen sky/water is unchanged.

**Coverage warning at 600 m:** layered (blind A) lacks the outer road/ground grid visible in baseline (D) and remove (F), leaving a plain exterior field. This is visibly worse coverage, distinct from the unchanged integer ground-material score. Cause unknown: do not attribute it to the foliage shader without loading/visibility evidence. The whole-frame 600 m pair is confounded even with matched camera metadata. Thus “nothing else got worse” is not supported. No focus gain is demonstrated; the focus-gain/hold-out-loss reject rule cannot be evaluated until actual hold-outs exist. Keep the shipping baseline; 5A’s review is **no demonstrated benefit / hold-out acceptance pending**, not a completed gate.

## Hold-outs needed — do not run until A4 finishes

Require native **off and layered**, matched per view (remove optional diagnostic): Wilmette street afternoon; Lakeview street and postcard afternoon; West Highland frozen data-poor camera; Greenville Downtown frozen, approved native view. Preserve source/data/pose/fixture/drawable hashes. Lakeview/Wilmette use their existing native contract. West Highland’s separate contract is scene-Y/portrait/FOV based; do not substitute the Sloan AGL inspection pose or web atmosphere into native. Greenville needs a frozen native camera. Neither West Highland nor Greenville is currently registered in `a3-capture-contract.json`, whose worker resolves only its four heroes. Native data/fixture readiness and a faithful contract adapter must be filed before those two can run. Do not silently skip them or call a partial batch complete.

Single planned batch below, **not executed**. `WEST_HIGHLAND_NATIVE_VIEW` and `GREENVILLE_NATIVE_VIEW` must be the subsequently frozen, registered native IDs (not guessed IDs); `A3_HOLDOUT_OUTPUT` must be a new evidence directory. The preflight requires all five views before any capture, so currently this is blocked. After A4 releases its lock and these prerequisites are filed, one heavy admission invokes the worker directly without nested wrappers:

```sh
HEAVY_AGENT=A3 HEAVY_LOAD=25 scripts/heavy.sh 'A3 foliage untouched hold-outs' python3 - <<'PYCODE'
import json, os, pathlib, subprocess, sys
views = ['wilmette-street-afternoon', os.environ['WEST_HIGHLAND_NATIVE_VIEW'],
         'lakeview-street-afternoon', 'lakeview-postcard-afternoon',
         os.environ['GREENVILLE_NATIVE_VIEW']]
registered = {v['id'] for v in json.loads(pathlib.Path('docs/lookloop/a3-capture-contract.json').read_text())['views']}
assert len(set(views)) == 5 and set(views) <= registered, 'Hold-out contracts incomplete; no capture started'
out = pathlib.Path(os.environ['A3_HOLDOUT_OUTPUT'])
out.mkdir(parents=True, exist_ok=False)
for mode in ('off', 'layered'):
    for view in views:
        subprocess.run([sys.executable, 'scripts/capture_native.py', '--view', view,
                        '--foliageexp1', mode, '--output', str(out / mode / view)], check=True)
PYCODE
```

No command in this report was executed. No heavy lock, build, Simulator run or new capture was used for scoring.

Used: GRADING.md §M/§N; foliage-exp1-native-final-evidence.md; foliage-exp1-spec.md FINAL amendment. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: supplied inspection views only; 600 m coverage mismatch; hold-outs deferred.
Tracker update:
