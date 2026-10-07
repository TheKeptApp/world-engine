import Foundation

/// Errors from element parsing and SGP4 propagation (mirrors the Python `ElementError`, `DeepSpace`,
/// `PropagationError`).
public enum SatelliteError: Error, Sendable, Equatable {
    case element(String)
    case deepSpace(String)
    case propagation(String)
}

/// A plain 3-vector (km or km/s) in the frame the producing function names.
public struct SatVec3: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Python semantics helpers, so the port matches the reference bit for bit where it matters.
enum PyMath {
    /// Python `a % b` for floats: the result has the sign of `b`.
    static func mod(_ a: Double, _ b: Double) -> Double {
        var m = fmod(a, b)
        if m != 0 {
            if (b < 0) != (m < 0) {
                m += b
            }
        } else {
            m = b < 0 ? -0.0 : 0.0
        }
        return m
    }

    /// Python `a // b` for floats (CPython float_floor_div).
    static func floorDiv(_ a: Double, _ b: Double) -> Double {
        var m = fmod(a, b)
        var div = (a - m) / b
        if m != 0 {
            if (b < 0) != (m < 0) {
                m += b
                div -= 1.0
            }
        }
        if div != 0 {
            var fl = floor(div)
            if div - fl > 0.5 {
                fl += 1.0
            }
            return fl
        }
        return b < 0 ? -0.0 : 0.0
    }

    /// Python `round(x, digits)`: correctly rounded on the exact binary value, ties to even.
    static func round(_ x: Double, _ digits: Int) -> Double {
        if !x.isFinite {
            return x
        }
        let s = String(format: "%.\(digits)f", x)
        return Double(s) ?? x
    }
}
