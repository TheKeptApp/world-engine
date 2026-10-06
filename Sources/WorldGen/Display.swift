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

/// The shared display policy (`Profiles/display.json`): render scale by device heat and pausing
/// when hidden. Renderer-neutral; each renderer applies the results (RealityKit in `WorldView`,
/// three.js in `web/src/display.js`). Calm mode (a lower frame rate for an idle view) was dropped
/// on 2026-10-06: RealityView offers no frame-rate control.
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

    public struct Hidden: Codable, Sendable, Equatable {
        public var pause: Bool
    }

    public var version: Int
    public var renderScale: RenderScale
    public var hidden: Hidden

    /// The bundled policy.
    public static let standard: DisplayPolicy = (try? StyleLibrary.display()) ?? builtIn

    /// Same values as display.json, for a bundle without it.
    static let builtIn = DisplayPolicy(
        version: 1,
        renderScale: .init(byThermalState: ["nominal": 2.5, "fair": 2.25, "serious": 2.0, "critical": 2.0], raiseAfterSeconds: 60),
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
