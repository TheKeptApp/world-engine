import Foundation
import simd

/// How hot the device is, in the four steps both platforms report (iOS `ProcessInfo.ThermalState`;
/// web hosts pass it in).
public enum DeviceHeat: String, Codable, Sendable, Comparable, CaseIterable {
    case nominal, fair, serious, critical

    public static func < (a: DeviceHeat, b: DeviceHeat) -> Bool {
        allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)!
    }
}

/// The shared display policy (`Profiles/display.json`): render scale by device heat, calm-mode
/// frame rate for an idle view, pausing when hidden. Renderer-neutral; each renderer applies the
/// results (RealityKit in `WorldView`, three.js in `web/src/display.js`).
public struct DisplayPolicy: Codable, Sendable, Equatable {
    public struct RenderScale: Codable, Sendable, Equatable {
        /// Pixels per point for each heat step.
        public var byThermalState: [String: Double]
        public var raiseAfterSeconds: Double

        public init(byThermalState: [String: Double], raiseAfterSeconds: Double) {
            self.byThermalState = byThermalState
            self.raiseAfterSeconds = raiseAfterSeconds
        }

        public func scale(for heat: DeviceHeat) -> Double {
            byThermalState[heat.rawValue] ?? byThermalState["nominal"] ?? 2.5
        }
    }

    public struct Calm: Codable, Sendable, Equatable {
        public var framesPerSecond: Int
        public var fullFramesPerSecond: Int
        public var afterSeconds: Double
        public var positionEpsilonMeters: Double
        public var angleEpsilonDegrees: Double

        public init(framesPerSecond: Int, fullFramesPerSecond: Int, afterSeconds: Double, positionEpsilonMeters: Double, angleEpsilonDegrees: Double) {
            self.framesPerSecond = framesPerSecond
            self.fullFramesPerSecond = fullFramesPerSecond
            self.afterSeconds = afterSeconds
            self.positionEpsilonMeters = positionEpsilonMeters
            self.angleEpsilonDegrees = angleEpsilonDegrees
        }
    }

    public struct Hidden: Codable, Sendable, Equatable {
        public var pause: Bool
    }

    public var version: Int
    public var renderScale: RenderScale
    public var calm: Calm
    public var hidden: Hidden

    /// The bundled policy.
    public static let standard: DisplayPolicy = (try? StyleLibrary.display()) ?? builtIn

    /// Same values as display.json, for a bundle without it.
    static let builtIn = DisplayPolicy(
        version: 1,
        renderScale: .init(byThermalState: ["nominal": 2.5, "fair": 2.25, "serious": 2.0, "critical": 2.0], raiseAfterSeconds: 60),
        calm: .init(framesPerSecond: 30, fullFramesPerSecond: 60, afterSeconds: 1.5, positionEpsilonMeters: 0.002, angleEpsilonDegrees: 0.05),
        hidden: .init(pause: true))
}

/// Render scale from device heat, with hysteresis: steps down as soon as the device heats, back
/// up only after it has stayed cooler for `raiseAfterSeconds`. Never above the native scale.
public struct RenderScaleGovernor: Sendable {
    public let policy: DisplayPolicy.RenderScale
    public let nativeScale: Double
    public private(set) var scale: Double
    private var coolerSince: Double?

    public init(policy: DisplayPolicy.RenderScale, nativeScale: Double, heat: DeviceHeat = .nominal) {
        self.policy = policy
        self.nativeScale = nativeScale
        scale = min(nativeScale, policy.scale(for: heat))
    }

    /// The heat at time `t` (seconds on any steady clock). Returns true when the scale changed.
    public mutating func update(heat: DeviceHeat, at t: Double) -> Bool {
        let target = min(nativeScale, policy.scale(for: heat))
        if target < scale {
            scale = target
            coolerSince = nil
            return true
        }
        guard target > scale else {
            coolerSince = nil
            return false
        }
        guard let since = coolerSince else {
            coolerSince = t
            return false
        }
        guard t - since >= policy.raiseAfterSeconds else { return false }
        scale = target
        coolerSince = nil
        return true
    }
}

/// Detects an idle view for calm mode: the camera has stayed within a few millimeters and a
/// fraction of a degree of where it settled, and nothing else moved, for `afterSeconds`.
/// Comparing against the settled pose (not the previous frame) catches slow camera drifts.
public struct CalmDetector: Sendable {
    public let policy: DisplayPolicy.Calm
    public private(set) var isCalm = false
    private var anchor: (position: SIMD3<Float>, forward: SIMD3<Float>, since: Double)?

    public init(policy: DisplayPolicy.Calm) {
        self.policy = policy
    }

    /// The frame rate to ask for now.
    public var framesPerSecond: Int { isCalm ? policy.framesPerSecond : policy.fullFramesPerSecond }

    /// One frame: camera position and unit forward vector, whether anything else is moving (a
    /// walking entity, a touch in progress) and the time. Returns true when calm mode changed.
    public mutating func update(cameraPosition p: SIMD3<Float>, cameraForward f: SIMD3<Float>, sceneMoving: Bool, at t: Double) -> Bool {
        let was = isCalm
        let cosLimit = Float(cos(policy.angleEpsilonDegrees * .pi / 180))
        if let a = anchor, !sceneMoving,
           simd_distance(a.position, p) <= Float(policy.positionEpsilonMeters),
           simd_dot(a.forward, f) >= cosLimit {
            isCalm = t - a.since >= policy.afterSeconds
        } else {
            anchor = (p, f, t)
            isCalm = false
        }
        return isCalm != was
    }

    /// Leaves calm mode at once (a touch began).
    public mutating func wake(at t: Double) {
        if let a = anchor { anchor = (a.position, a.forward, t) }
        isCalm = false
    }
}
