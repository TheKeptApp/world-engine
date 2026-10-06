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
    /// Stop rendering while the view is off screen or the app is in the background.
    public var pauseWhenHidden: Bool

    public init(policy: DisplayPolicy = .standard) {
        scale = policy.renderScale
        pauseWhenHidden = policy.hidden.pause
    }

    /// Native scale (the milestone 2 behavior).
    public static var native: WorldRenderSettings {
        var s = WorldRenderSettings()
        s.scale = nil
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
    public internal(set) var isPaused = false
    public internal(set) var heat: DeviceHeat = .nominal
    /// Whether the renderer's view was found (scale and frame rate can only be applied then).
    public internal(set) var attached = false
    /// GPU time of the most recent frame (ms) when known. RealityView exposes no frame GPU timing,
    /// so this is nil today; device GPU time comes from Metal System Trace
    /// (`scripts/device_attribution.sh`, `scripts/gpu_frames.py`). Not observed (changes every frame).
    @ObservationIgnored public internal(set) var gpuFrameMs: Double?
    /// The surface drawing into this state, set once its view is found. Weak: the `WorldView` owns it.
    @ObservationIgnored weak var surface: RenderSurface?

    public init() {}

    /// One-line summary, e.g. "2.50× 1005x2185 60 fps nominal".
    public var summary: String {
        let size = "\(Int(drawableSize.width))x\(Int(drawableSize.height))"
        return String(format: "%.2f× %@ %@ %@", scale, size, isPaused ? "paused" : "\(framesPerSecond) fps", heat.rawValue)
    }

    /// How `snapshot(source:)` captures the world.
    public enum SnapshotSource: Sendable {
        /// RealityKit's own capture of the view (`ARView.snapshot`, which Apple documents only as "Takes a
        /// screenshot"). Whether the image includes the world's custom post-processing (the grade and bloom
        /// of `WorldPostProcess`) is undocumented and not yet verified on a device: compare it with `.compositor`.
        case realityKit
        /// The view as the system composites it for the display (UIKit `drawHierarchy`), one image pixel per
        /// drawable pixel: the frame the screen presents, post-processing included.
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
/// RealityView has no resolution or pause API on iOS 26. The view behind it is an `ARView`; its
/// `contentScaleFactor` (public UIKit API) sets the drawable size. Pausing removes the RealityView
/// from the hierarchy (see `WorldView`). There is no frame-rate control: RealityKit ignores
/// `ARView.__preferredFrameRate`, so the calm mode Prompt 5 asked for was dropped (owner decision,
/// 2026-10-06).
@MainActor
final class RenderSurface {
    let settings: WorldRenderSettings
    let state: WorldRenderState
    private(set) weak var arView: ARView?
    private var governor: RenderScaleGovernor?
    private var clockStart = Date()
    private var lastHeatCheck = -1.0
    private var visible = true
    private var background = false
    private var hostPaused = false

    init(settings: WorldRenderSettings, state: WorldRenderState) {
        self.settings = settings
        self.state = state
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
    }

    /// Per frame (from the scene update): heat check once a second.
    func frame(camera: Entity) {
        let t = now
        guard t - lastHeatCheck >= 1 else { return }
        lastHeatCheck = t
        let heat = Self.heat()
        state.heat = heat
        if var g = governor, g.update(heat: heat, at: t) {
            governor = g
            applyScale()
        } else if let g = governor {
            governor = g
        }
        if let ar = arView {
            let size = Self.drawableSize(of: ar)
            if size != state.drawableSize { state.drawableSize = size }
        }
    }

    func setVisible(_ v: Bool) { visible = v; applyPause() }
    func setHostPaused(_ p: Bool) { hostPaused = p; applyPause() }
    /// Background: paused. Inactive (Control Center, a system alert over the app) stays visible and
    /// keeps rendering.
    func setPhase(active a: Bool, background b: Bool) {
        background = b
        applyPause()
    }

    var shouldPause: Bool { hostPaused || (settings.pauseWhenHidden && (!visible || background)) }

    private func applyPause() {
        let paused = shouldPause
        guard paused != state.isPaused else { return }
        state.isPaused = paused
        state.gpuFrameMs = nil
        state.framesPerSecond = paused ? 0 : 60
    }

    private func applyScale() {
        guard let ar = arView else { return }
        let scale = governor?.scale ?? Double(ar.window?.screen.scale ?? 3)
        if abs(Double(ar.contentScaleFactor) - scale) > 0.001 {
            ar.contentScaleFactor = CGFloat(scale)
            ar.setNeedsLayout()
        }
        state.scale = Double(ar.contentScaleFactor)
        state.drawableSize = Self.drawableSize(of: ar)
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

    init(settings: WorldRenderSettings, state: WorldRenderState) {
        self.settings = settings
        self.state = state
    }

    func frame(camera: Entity) {}
    func setVisible(_ v: Bool) {}
    func setHostPaused(_ p: Bool) {}
    func setPhase(active a: Bool, background b: Bool) {}
    /// No view to capture here: `WorldRenderState.snapshot` returns nil on macOS.
    func snapshot(source: WorldRenderState.SnapshotSource) async -> CGImage? { nil }
}
#endif
