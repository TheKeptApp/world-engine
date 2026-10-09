# Sloan native summer BEFORE evidence — 2026-10-08

R requested fresh native BEFORE frames at 40/150/600 m and one independent 150 m repeat. All four use **2026-07-15T20:30:00Z**, clear/cloud0/wind0, character none, pose latitude 39.7511195 / longitude -105.0389 / heading 270 / pitch down 45 / vertical FOV 50. The native log confirms summer **season=1** for every run; the 40 m frame was inspected and shows green foliage. RealityKit, HUD off, 16:9, drawable 1005×565. Pin-only exposure gain 1.0 and foliage experiment off; no crown adapter build flag. Captures ran on the existing LookLoop iPhone 17 Pro iOS 26.4 Simulator, with no phone install and no render-code changes.

Captured revision **0600748** (main baseline fdf19ec plus capture-tool-only UTC date override). The worker now accepts --date, validates strict UTC date/calendar values and changes only the selected view's clock argument; frozen defaults are unchanged. Twelve focused Python capture-worker tests pass. The native app built successfully for each run through its prerequisite-safe build workflow. SCENEREADY proves context completion and at least three stable completed Metal frames before every VIEWSHOT; the audit decoded FOV 50 from the signature and checked actual camera lines, summer season, date, fixed-gain provenance, shader/frame hashes and absence of crashes.

## Frames and metadata

| Run | Main triangles / draws | Frame | PNG SHA-256 |
|---|---:|---|---|
| fresh-40 | 308805 / 53 | [fresh-40](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/fresh-40/raw/ordinary-street-afternoon.png) | `05790d7cc7e1495e706a8d513e950471fd1381ca5b72e25073ab068b6976dd89` |
| fresh-150 | 331895 / 50 | [fresh-150](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/fresh-150/raw/ordinary-street-afternoon.png) | `3796b3e3416319533656e0de4f6f7d0c5832ef592abd8e1f79ab10102b78fe20` |
| fresh-600 | 227442 / 43 | [fresh-600](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/fresh-600/raw/ordinary-street-afternoon.png) | `ba131806a9cf72243715a587c73833fbfdd23741713da1d62ac4c17e058ad299` |
| repeat-150 | 331895 / 50 | [repeat-150](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/repeat-150/raw/ordinary-street-afternoon.png) | `245322de743f125f1bb59774e4892c2c2a650ac7136055a03cbcf416e25bb234` |

Each frame has `native-capture.json` in its parent run directory, a pipeline log, launch log and raw image. The [four-frame manifest](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/manifest.json) retains exact args, poses, exposure/readiness proof, commit, frame and library hashes. All four share shipping shader source SHA-256 `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a` and both compiled metallib hashes.

## 150 m fresh versus repeat

Decoded RGBA8 byte comparison, no resizing/normalization/color conversion beyond PNG decoding: **max 1 byte value (1/255)**, **mean absolute difference 0.000213093822921 byte units**, **484 differing bytes out of 2,271,300**. PNG files are not byte-identical. [Diff report](/private/tmp/worldengine-a10/.build/a10-summer-before-20260715/control-150-diff.json) preserves exact values. The two runs have identical six-category triangle/draw fingerprints, complete scene signatures, poses/date, source revision, drawable size and shader/library hashes. This is a raw control result; no shader or control gate was amended.

## Reproduce

Use a unique output path for each independent run:

```sh
HEAVY_AGENT=A10 HEAVY_LOAD=25 scripts/capture-native.sh \
  --view ordinary-street-afternoon --date 2026-07-15T20:30:00Z \
  --inspectionpose '39.7511195,-105.0389,ALT,270,45' --foliageexp1 off \
  --output .build/NEW-SUMMER-RUN
```

ALT is 40, 150, 600, then 150 for the repeat. The wrapper owns scripts/heavy.sh; do not nest locks. All four were independently admitted at loads 6.98/10.75/12.49/9.06 (<25) and released their lock after completion. Initial admission waited for A8's tunnel audit. Old captures were preserved. Simulator evidence does not certify device performance.

## Ledger text for A3

Summer native BEFORE frames are available at the four absolute paths above with exact frozen pose/FOV50, July 15 afternoon date, green foliage and pin-only gain. 150 m control max=1/255, mean=0.000213093822921 byte units, differing bytes=484/2271300; matched coverage and source/library hashes. Changes are capture tooling/tests and this evidence doc only; render sources, shipping exposure behaviour and FINAL shader gate are unchanged. INTEGRATION.md/STATE.md/handoffs.md untouched.
