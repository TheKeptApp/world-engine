# WorldLab inspection camera

## 1. Controls (R, A10, 8 October 2026)

Choose **Aerial** or **Explore** in WorldLab. Spread two fingers to zoom in; pinch to zoom out. Drag two fingers to pan and one finger to orbit. The camera remains inside the loaded-area bounds extended to include the default hero eye, 8–1,500 metres above rendered ground. Pitch is 5–85 degrees downward. The existing options menu contains **Reset view**, which returns to the current default aerial hero camera, and **Debug → Camera pose**, off by default. The overlay records altitude above ground, heading, pitch and latitude/longitude. **Debug → Copy camera launch argument** copies the complete reproducible pose.

The app uses the existing public postcard camera API. Renderers, shaders, tile selection and budgets are unchanged. Route and Follow keep their existing behaviour. Ground clearance uses the upper visual bounds of the existing named ground meshes, including curb allowance, within the manifest bounds. Current native terrain is flat; this is conservative clearance for that terrain, not a future heightfield sampler or building-collision system.

## 2. Reproducible launch pose

Use `-renderer realitykit -inspectionpose LAT,LON,ALT,HEADING,PITCH`. Coordinates are WGS84 decimal degrees; altitude is metres above ground; heading is clockwise from north; pitch is positive downward in degrees. The pose selects Aerial inspection mode. Nonfinite/malformed coordinates and pitch outside 5–85 are rejected; altitude and horizontal position are clamped. The camera retains the existing default vertical field of view. `-cameradebug` enables the overlay for captures. Default launches leave it off.

For example: `-inspectionpose 39.7511195,-105.0389,40,270,45`. For matching web captures, project those coordinates into the same local frame, add terrain height to ALT for eye Y, and aim along `(sin heading*cos pitch, -sin pitch, -cos heading*cos pitch)`. Match viewport, FOV, environment, fixture and renderer separately; equal pose does not assert equal pixels across renderers.

## 3. Verification evidence

Camera arithmetic tests cover limits, default hero/reset, pan/orbit angles and clearance, invalid input/scale and launch round-trip precision (<0.2 mm). Simulator: iPhone 17 Pro, iOS 26.4. Xcode simulator build passed. Sloan’s Lake captures at 40, 150 and 600 m AGL use lat 39.7511195, lon -105.0389, heading 270°, pitch 45°, 15 October 2026 20:30 UTC, synthetic clear/cloud 0/wind 0, character none. Repeated 40 m launches report identical pose. The final 1005×2185 renders differ by at most 1/255 in each RGB channel, with channel mean absolute differences 0.000174, 0.000467 and 0.000326 (on a 0–255 scale); the earlier paired run was pixel-identical. This proves repeatability for that fixed simulator fixture, not device performance or web pixel parity.

Local evidence: `/private/tmp/worldengine-a10/.build/a10-camera-evidence/`: `near.png`, `middle.png`, `far.png`, corresponding `*-ui.png` screenshots, `near-repeat.png`, `poses.json`, `verification.json`, and `zoom-levels.png`. Images stay out of Git. Build/test/capture logs are archived there. Heavy admission was below 25; ≥8 GB free. Earlier harness attempts misread simulator-local log paths; `RuntimeError: capture timeout near` was a harness failure with no renderer change. Readback was corrected to the simulator data `tmp` directory. No device installation or visual score is claimed. The unchanged-world reference is `docs/proposals/style-b-calibration-v2/frames/06-sloans.png`; the inspection controls implement R’s request, not a new rendering target.
