import CoreGraphics
import Foundation
import Observation
import RealityKit
import SwiftUI
#if os(iOS)
import UIKit
#endif
import WorldGen

/// Display settings for `WorldView`. Defaults follow the shared display policy
/// (`Profiles/display.json`), which the web renderer reads from the package as well.
public struct WorldRenderSettings: Sendable {
    /// Resolution by device heat; nil renders at the screen's native scale.
    public var scale: DisplayPolicy.RenderScale?
    /// Fixed pixels-per-point (tests and comparisons); wins over `scale`.
    public var fixedScale: Double?
    /// Calm mode for an idle view; nil keeps the full frame rate.
    public var calm: DisplayPolicy.Calm?
    /// Stop rendering while the view is off screen or the app is not active.
    public var pauseWhenHidden: Bool
    /// What draws the world: RealityView (default) or, experimentally, RealityRenderer in a Metal
    /// view WorldEngine owns (frame rate, pausing and GPU timing under its control).
    public var host: Host = .realityView

    public enum Host: Sendable { case realityView, realityRenderer }

    public init(policy: DisplayPolicy = .standard) {
        scale = policy.renderScale
        calm = policy.calm
        pauseWhenHidden = policy.hidden.pause
    }

    /// Native scale, full frame rate always (the milestone 2 behavior).
    public static var native: WorldRenderSettings {
        var s = WorldRenderSettings()
        s.scale = nil
        s.calm = nil
        return s
    }
}

/// What the view is doing right now, for HUDs and test logs.
@MainActor
@Observable
public final class WorldRenderState {
    /// Pixels per point being rendered.
    public internal(set) var scale: Double = 0
    /// The renderer's drawable in pixels.
    public internal(set) var drawableSize: CGSize = .zero
    /// The frame rate asked of the renderer (0 while paused).
    public internal(set) var framesPerSecond = 60
    public internal(set) var isCalm = false
    public internal(set) var isPaused = false
    public internal(set) var heat: DeviceHeat = .nominal
    /// Whether the renderer's view was found (scale and frame rate can only be applied then).
    public internal(set) var attached = false
    /// GPU time of the most recent frame (ms) from the kernel's per-process GPU accounting; nil
    /// where the system doesn't report it (the Simulator). Not observed (changes every frame).
    @ObservationIgnored public internal(set) var gpuFrameMs: Double?
    /// The surface drawing into this state, set once its view is found. Weak: the `WorldView` owns it.
    @ObservationIgnored weak var surface: RenderSurface?

    public init() {}

    /// One-line summary, e.g. "2.50× 1005x2185 60 fps nominal".
    public var summary: String {
        let size = "\(Int(drawableSize.width))x\(Int(drawableSize.height))"
        return String(format: "%.2f× %@ %@ %@", scale, size, isPaused ? "paused" : "\(framesPerSecond) fps\(isCalm ? " calm" : "")", heat.rawValue)
    }

    /// How `snapshot(source:)` captures the world.
    public enum SnapshotSource: Sendable {
        /// RealityKit's own capture of the view (`ARView.snapshot`, which Apple documents only as "Takes a
        /// screenshot"). Whether the image includes the world's custom post-processing (the grade and bloom
        /// of `WorldPostProcess`) is undocumented and not yet verified on a device: compare it with `.compositor`.
        case realityKit
        /// The view as the system composites it for the display (UIKit `drawHierarchy`), one image pixel per
        /// drawable pixel: the frame the screen presents, post-processing included. Always used for the
        /// experimental `RealityRenderer` host, which has no `ARView`.
        case compositor
    }

    /// A still of the world as it is drawn right now, for visual checks on a device (no Simulator needed).
    /// Call it from the main actor while the view is on screen.
    ///
    /// What it captures: the world's own view only (the 3D scene, sky and shadows, plus the post-processing
    /// as far as `source` includes it), at the view's render resolution (see `drawableSize`). Anything
    /// SwiftUI draws over the view is not in the image: no HUD, no controls, and not the "© OpenStreetMap
    /// contributors" credit that `WorldView` overlays. A capture is a test artifact, not a view shown to people.
    ///
    /// Returns nil while the view is paused or not on screen yet, on macOS (package tests), and when the
    /// capture fails or takes longer than 10 s.
    public func snapshot(source: SnapshotSource = .realityKit) async -> CGImage? {
        await surface?.snapshot(source: source)
    }
}

#if os(iOS)
/// Applies `WorldRenderSettings` to the `ARView` that backs a `RealityView`.
///
/// RealityView has no resolution, frame-rate or pause API on iOS 26. The view behind it is an
/// `ARView`; its `contentScaleFactor` (public UIKit API) sets the drawable size. Frame rate uses
/// `ARView.__preferredFrameRate`, an underscored RealityKit property: public in the SDK but
/// undocumented, so it may change in any OS update (it is only used for calm mode, and calm mode
/// switches itself off if the property stops working).
@MainActor
final class RenderSurface {
    let settings: WorldRenderSettings
    let state: WorldRenderState
    private(set) weak var arView: ARView?
    private(set) weak var host: RendererHostView?
    private var governor: RenderScaleGovernor?
    private var calm: CalmDetector?
    private var clockStart = Date()
    private var lastHeatCheck = -1.0
    private var visible = true
    private var active = true
    private var background = false
    private var hostPaused = false
    private var lastGPU: UInt64?

    init(settings: WorldRenderSettings, state: WorldRenderState) {
        self.settings = settings
        self.state = state
        calm = settings.calm.map(CalmDetector.init(policy:))
    }

    private var now: Double { Date().timeIntervalSince(clockStart) }

    /// Called by the probe once the view is in a window: finds the ARView whose frame matches.
    func attach(near probe: UIView) {
        // A paused view is torn down; its successor attaches again.
        if let ar = arView, ar.window != nil { return }
        guard let window = probe.window else { return }
        let target = probe.convert(probe.bounds, to: nil)
        var found: ARView?
        var bestScore = CGFloat.infinity
        var stack: [UIView] = [window]
        while let v = stack.popLast() {
            if let candidate = v as? ARView {
                let f = candidate.convert(candidate.bounds, to: nil)
                let score = abs(f.minX - target.minX) + abs(f.minY - target.minY) + abs(f.width - target.width) + abs(f.height - target.height)
                if score < bestScore { found = candidate; bestScore = score }
            }
            stack.append(contentsOf: v.subviews)
        }
        guard let ar = found else { return }
        arView = ar
        state.surface = self
        state.attached = true
        let native = Double(window.screen.scale)
        if let fixed = settings.fixedScale {
            governor = RenderScaleGovernor(policy: .init(byThermalState: ["nominal": fixed], raiseAfterSeconds: 0), nativeScale: native)
        } else if let policy = settings.scale {
            governor = RenderScaleGovernor(policy: policy, nativeScale: native, heat: Self.heat())
        }
        state.heat = Self.heat()
        applyScale()
        applyFrameRate()
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-fpsexp"), i + 1 < args.count {
            print("GPUSTAT default automatic=\(ar.__enableAutomaticFrameRate) preferred=\(ar.__preferredFrameRate)")
            switch args[i + 1] {
            case "auto": ar.__enableAutomaticFrameRate = true
            case "fixed30": ar.__enableAutomaticFrameRate = false; ar.__preferredFrameRate = 30
            case "auto30": ar.__enableAutomaticFrameRate = true; ar.__preferredFrameRate = 30
            case "rehost30":
                ar.__enableAutomaticFrameRate = false; ar.__preferredFrameRate = 30
                let parent = ar.superview, index = parent?.subviews.firstIndex(of: ar)
                ar.removeFromSuperview()
                if let parent, let index { parent.insertSubview(ar, at: index) }
            default: break
            }
            print("GPUSTAT exp \(args[i + 1]) automatic=\(ar.__enableAutomaticFrameRate) preferred=\(ar.__preferredFrameRate)")
        }
    }

    /// Experiment: print the kernel's GPU time and RealityKit's statistics once a second.
    var gpuStats = false
    private var statFrames = 0
    private var statGPU: UInt64?
    private var statsEnabled = false

    private func printStats() {
        guard let ar = arView else { return }
        if !statsEnabled {
            statsEnabled = true
            print("GPUSTAT automaticFrameRate=\(ar.__enableAutomaticFrameRate) preferredFrameRate=\(ar.__preferredFrameRate)")
            ar.debugOptions.insert(.showStatistics)
            ar.__statisticsOptions = [.frameTimeStatistics, .renderingStatistics, .mtlCounterAPIStatistics, .thermalStatistics]
            ar.__setProfilerUpdateInterval(newInterval: 0.5)
            if ProcessInfo.processInfo.arguments.contains("-hidestats") { ar.__disableStatisticsRendering = true }
        }
        let g = TaskGPUTime.nanoseconds()
        if let g, let last = statGPU, statFrames > 0 {
            print(String(format: "GPUSTAT task gpu %.2f ms/frame over %d frames (%.1f%% busy)", Double(g - last) / 1e6 / Double(statFrames), statFrames, Double(g - last) / 1e7))
        } else {
            print("GPUSTAT task gpu \(g.map(String.init) ?? "unavailable")")
        }
        statGPU = g
        statFrames = 0
        print("GPUSTAT frameTime() \(ar.__frameTime())")
        for (name, o) in [("frame", ARView.__StatisticsOptions.frameTimeStatistics), ("render", .renderingStatistics),
                          ("mtl", .mtlCounterAPIStatistics), ("thermal", .thermalStatistics)] {
            print("GPUSTAT \(name): \(ar.__getStatisticsStringForSingleOption(statisticOption: o).replacingOccurrences(of: "\n", with: " | "))")
        }
    }

    /// The experimental RealityRenderer host is ready: scale and frame rate apply to it directly.
    func attachHost(_ h: RendererHostView) {
        host = h
        state.surface = self
        state.attached = true
        let native = Double(h.window?.screen.scale ?? 3)
        if let fixed = settings.fixedScale {
            governor = RenderScaleGovernor(policy: .init(byThermalState: ["nominal": fixed], raiseAfterSeconds: 0), nativeScale: native)
        } else if let policy = settings.scale {
            governor = RenderScaleGovernor(policy: policy, nativeScale: native, heat: Self.heat())
        }
        state.heat = Self.heat()
        applyScale()
        applyFrameRate()
    }

    /// Per frame (from the scene update): heat check once a second, calm detection.
    func frame(camera: Entity, sceneMoving: Bool) {
        let t = now
        statFrames += 1
        if host != nil {
            state.gpuFrameMs = RendererHostView.lastGPUms
        } else if let g = TaskGPUTime.nanoseconds(), g > 0 {
            if let last = lastGPU, g >= last { state.gpuFrameMs = Double(g - last) / 1e6 }
            lastGPU = g
        }
        if t - lastHeatCheck >= 1 {
            lastHeatCheck = t
            if gpuStats { printStats() }
            let heat = Self.heat()
            state.heat = heat
            if var g = governor, g.update(heat: heat, at: t) {
                governor = g
                applyScale()
            } else if let g = governor {
                governor = g
            }
            if let h = host {
                if h.drawableSize != state.drawableSize { state.drawableSize = h.drawableSize }
            } else if let ar = arView {
                let size = Self.drawableSize(of: ar)
                if size != state.drawableSize { state.drawableSize = size }
            }
        }
        guard var c = calm else { return }
        let m = camera.transformMatrix(relativeTo: nil)
        let p = SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        let f = -SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        if c.update(cameraPosition: p, cameraForward: simd_normalize(f), sceneMoving: sceneMoving, at: t) {
            calm = c
            applyFrameRate()
        } else {
            calm = c
        }
    }

    /// A touch began: full frame rate at once.
    func wake() {
        guard var c = calm, c.isCalm else { return }
        c.wake(at: now)
        calm = c
        applyFrameRate()
    }

    func setVisible(_ v: Bool) { visible = v; applyPause() }
    func setHostPaused(_ p: Bool) { hostPaused = p; applyPause() }
    /// Inactive (Control Center, a system alert over the app): still visible, so calm rate rather
    /// than a pause. Background: paused.
    func setPhase(active a: Bool, background b: Bool) {
        active = a
        background = b
        applyPause()
        applyFrameRate()
    }

    var shouldPause: Bool { hostPaused || (settings.pauseWhenHidden && (!visible || background)) }

    private func applyPause() {
        let paused = shouldPause
        guard paused != state.isPaused else { return }
        state.isPaused = paused
        lastGPU = nil
        state.gpuFrameMs = nil
        if paused { state.framesPerSecond = 0 } else { applyFrameRate() }
    }

    private func applyScale() {
        if let h = host {
            let scale = governor?.scale ?? Double(h.window?.screen.scale ?? 3)
            h.applyScale(scale)
            state.scale = scale
            state.drawableSize = h.drawableSize
            return
        }
        guard let ar = arView else { return }
        let scale = governor?.scale ?? Double(ar.window?.screen.scale ?? 3)
        if abs(Double(ar.contentScaleFactor) - scale) > 0.001 {
            ar.contentScaleFactor = CGFloat(scale)
            ar.setNeedsLayout()
        }
        state.scale = Double(ar.contentScaleFactor)
        state.drawableSize = Self.drawableSize(of: ar)
    }

    private func applyFrameRate() {
        guard !state.isPaused else { return }
        let calmNow = (calm?.isCalm ?? false) || (calm != nil && !active)
        let fps = calmNow ? (settings.calm?.framesPerSecond ?? 60) : (settings.calm?.fullFramesPerSecond ?? 60)
        state.isCalm = calmNow
        state.framesPerSecond = fps
        if let h = host { h.setFramesPerSecond(fps); return }
        guard let ar = arView, calm != nil else { return }
        if ProcessInfo.processInfo.arguments.contains("-noautofps") { ar.__enableAutomaticFrameRate = false }
        ar.__preferredFrameRate = Float(fps)
        if gpuStats { print("GPUSTAT set preferredFrameRate=\(fps) -> automatic=\(ar.__enableAutomaticFrameRate) preferred=\(ar.__preferredFrameRate)") }
    }

    static func heat() -> DeviceHeat {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .serious
        }
    }

    /// The drawable of the Metal layer under the ARView.
    static func drawableSize(of view: UIView) -> CGSize {
        func find(_ layer: CALayer) -> CAMetalLayer? {
            if let m = layer as? CAMetalLayer { return m }
            for s in layer.sublayers ?? [] { if let m = find(s) { return m } }
            return nil
        }
        return find(view.layer)?.drawableSize ?? .zero
    }

    // MARK: Snapshots

    /// See `WorldRenderState.snapshot(source:)`.
    func snapshot(source: WorldRenderState.SnapshotSource) async -> CGImage? {
        guard !state.isPaused else { return nil }
        // The experimental host has no ARView: its Metal layer is only reachable through the compositor.
        if let h = host { return Self.compositedImage(of: h) }
        guard let ar = arView, ar.window != nil, !ar.bounds.isEmpty else { return nil }
        switch source {
        case .realityKit: return await Self.realityKitImage(of: ar)
        case .compositor: return Self.compositedImage(of: ar)
        }
    }

    /// `ARView.snapshot`: RealityKit's own capture. Its completion handler may run on any thread and is
    /// not guaranteed to run at all (a view that stopped drawing), so it races a 10 s timeout.
    private static func realityKitImage(of ar: ARView) async -> CGImage? {
        await withCheckedContinuation { (continuation: CheckedContinuation<CGImage?, Never>) in
            let once = SnapshotResume(continuation)
            ar.snapshot(saveToHDR: false) { @Sendable image in
                once.finish(image.flatMap { RenderSurface.pixels(of: $0) })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { once.finish(nil) }
        }
    }

    /// RealityKit's image as plain pixels in display orientation.
    private nonisolated static func pixels(of image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cg = image.cgImage { return cg }
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = image.scale
        format.opaque = true
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in image.draw(at: .zero) }.cgImage
    }

    /// What the system composites for `view` (UIKit `drawHierarchy`), one image pixel per drawable pixel.
    private static func compositedImage(of view: UIView) -> CGImage? {
        guard view.window != nil, !view.bounds.isEmpty else { return nil }
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = view.contentScaleFactor
        format.opaque = true
        format.preferredRange = .standard
        var drawn = false
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            drawn = view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        return drawn ? image.cgImage : nil
    }
}

/// Resumes a snapshot's continuation exactly once from any thread: RealityKit's completion handler
/// and the timeout race, the first one wins.
private final class SnapshotResume: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<CGImage?, Never>?

    init(_ continuation: CheckedContinuation<CGImage?, Never>) { self.continuation = continuation }

    func finish(_ image: CGImage?) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: image)
    }
}

/// An invisible view placed behind the RealityView so the surface can find its ARView.
struct RenderSurfaceProbe: UIViewRepresentable {
    let surface: RenderSurface

    func makeUIView(context: Context) -> ProbeView {
        let v = ProbeView()
        v.surface = surface
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ view: ProbeView, context: Context) {}

    final class ProbeView: UIView {
        weak var surface: RenderSurface?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            // The RealityView's own view joins the window in the same pass; look after it has.
            DispatchQueue.main.async { [weak self] in
                guard let self, let surface = self.surface else { return }
                surface.attach(near: self)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let surface, surface.arView == nil { surface.attach(near: self) }
        }
    }
}
#else
/// macOS builds (package tests) compile the engine without the iOS view plumbing: settings are
/// carried but not applied.
@MainActor
final class RenderSurface {
    let settings: WorldRenderSettings
    let state: WorldRenderState
    var gpuStats = false

    init(settings: WorldRenderSettings, state: WorldRenderState) {
        self.settings = settings
        self.state = state
    }

    func frame(camera: Entity, sceneMoving: Bool) {}
    func wake() {}
    func setVisible(_ v: Bool) {}
    func setHostPaused(_ p: Bool) {}
    func setPhase(active a: Bool, background b: Bool) {}
    /// No view to capture here: `WorldRenderState.snapshot` returns nil on macOS.
    func snapshot(source: WorldRenderState.SnapshotSource) async -> CGImage? { nil }
}
#endif
