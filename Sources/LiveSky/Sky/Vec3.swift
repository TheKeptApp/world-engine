import Foundation

/// A plain 3-vector of doubles (the Python reference's 3-tuple).
public struct Vec3: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = Vec3(0.0, 0.0, 0.0)

    public subscript(i: Int) -> Double {
        switch i {
        case 0: return x
        case 1: return y
        default: return z
        }
    }

    public func dot(_ b: Vec3) -> Double {
        x * b.x + y * b.y + z * b.z
    }

    public var norm: Double {
        dot(self).squareRoot()
    }

    public var unit: Vec3 {
        let n = norm
        return Vec3(x / n, y / n, z / n)
    }

    public func scaled(_ k: Double) -> Vec3 {
        Vec3(x * k, y * k, z * k)
    }

    public var array: [Double] {
        [x, y, z]
    }

    public static func + (a: Vec3, b: Vec3) -> Vec3 {
        Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
    }

    public static func - (a: Vec3, b: Vec3) -> Vec3 {
        Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
    }
}

/// A 3x3 matrix stored as three rows.
public struct Mat3: Sendable, Equatable {
    public var r0: Vec3
    public var r1: Vec3
    public var r2: Vec3

    public init(_ r0: Vec3, _ r1: Vec3, _ r2: Vec3) {
        self.r0 = r0
        self.r1 = r1
        self.r2 = r2
    }

    public func row(_ i: Int) -> Vec3 {
        switch i {
        case 0: return r0
        case 1: return r1
        default: return r2
        }
    }

    public func element(_ i: Int, _ j: Int) -> Double {
        row(i)[j]
    }

    public static func * (m: Mat3, v: Vec3) -> Vec3 {
        Vec3(m.r0.x * v.x + m.r0.y * v.y + m.r0.z * v.z,
             m.r1.x * v.x + m.r1.y * v.y + m.r1.z * v.z,
             m.r2.x * v.x + m.r2.y * v.y + m.r2.z * v.z)
    }

    public static func * (a: Mat3, b: Mat3) -> Mat3 {
        func cell(_ i: Int, _ j: Int) -> Double {
            var s = 0.0
            for k in 0..<3 {
                s += a.element(i, k) * b.element(k, j)
            }
            return s
        }
        return Mat3(Vec3(cell(0, 0), cell(0, 1), cell(0, 2)),
                    Vec3(cell(1, 0), cell(1, 1), cell(1, 2)),
                    Vec3(cell(2, 0), cell(2, 1), cell(2, 2)))
    }
}
