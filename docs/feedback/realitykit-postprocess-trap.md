# Apple Feedback draft: RealityKit post-processing traps when set before the view is on screen

**Status:** Workaround found and in use (WorldEngine sets the effect after the view appears). Report ready to submit.

## How to submit (about 5 minutes, no Terminal)

1. On the Mac, open **Feedback Assistant**: press ⌘-Space, type `Feedback Assistant`, press Return.
2. Sign in with your Apple developer account if asked.
3. Click the **New Feedback** button (the pencil-and-square icon at the top of the window).
4. Choose **iOS & iPadOS**.
5. Fill in the fields:
   - **Title:** paste the title below.
   - **Which area are you seeing an issue with?** → **RealityKit**.
   - **What type of feedback are you reporting?** → **Incorrect/Unexpected Behavior**.
   - **Description:** paste everything under "Description" below.
6. Attach the reproduction project:
   - Click **Add Attachment** (the paperclip) at the bottom.
   - In the file picker choose **Desktop → world-engine → docs → feedback → PostProcessRepro.zip**, then click **Open**.
7. If it asks to collect a sysdiagnose, you can click **Don't Collect** (the zip reproduces it).
8. Click **Submit**.
9. Tell me the FB number it shows so I can record it here.

## Title

RealityKit: assigning RealityViewCameraContent.renderingEffects.customPostProcessing (or ARView.renderCallbacks) before the view is in a window traps with EXC_BREAKPOINT

## Description

**Summary**
On iOS 26.4 (device and Simulator), assigning a custom post-process effect crashes the app with `EXC_BREAKPOINT` in `ARView.renderCallbacks.setter` if the view is not yet in a window. This is true whether the effect is set through `RealityViewCameraContent.renderingEffects.customPostProcessing` or the older `ARView.renderCallbacks`. There is no console message. The same assignment works if it's made after the view is on screen.

**Environment**
- iPhone 14 Pro (iPhone15,2), iOS 26.4.2 (23E261), Release and Debug builds.
- iOS 26.4 Simulator (iPhone 17 Pro).
- Xcode 26.4 (17E192), Swift 6.3.

**Steps to reproduce** (attached project, PostProcessRepro.zip; pass the launch argument `-variant <name>`)
1. **`make`:** in `RealityView { content in … }`, set `content.renderingEffects.customPostProcessing = .effect(InvertEffect())`. Crashes.
2. **`update`:** set it in the `update:` closure on its first call. Crashes.
3. **`virtual`:** set `content.camera = .virtual` first, then the effect. Crashes.
4. **`arview`:** in `UIViewRepresentable.makeUIView`, create `ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)` and assign `renderCallbacks`. Crashes.
5. **`late`:** RealityView, set the effect in `update:` 2 seconds after the view appears. **Works** (~60 post-process calls per second).
6. **`arview-late`:** ARView, assign `renderCallbacks` 2 seconds after creation. **Works.**

**Expected**
Assigning the effect before the view is in a window either takes effect once rendering starts or fails with a clear message. The `make` closure is the natural place to configure a `RealityView`.

**Actual**
`EXC_BREAKPOINT` (SIGTRAP) with no message. Top of the stack:
```
RealityKit  ARView.renderCallbacks.setter
RealityKit  ARView.renderCallbacks.modify
_RealityKit_SwiftUI  RealityViewCameraContent.renderingEffects.didset
_RealityKit_SwiftUI  RealityViewCameraContent.renderingEffects.modify
<app>  closure #1 in RealityViewVariant.body.getter
```

**Workaround**
Defer the assignment until after the view appears (for example, set a `@State` flag in `.task`/`.onAppear` and assign in `update:`).
