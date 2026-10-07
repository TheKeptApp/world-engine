import Foundation

/// Throwing lookups on the shared mock values (`MockValues`, Look.swift): a missing key is an error.
extension MockValues {
    public func requireNumber(_ key: String) throws -> Double {
        guard let d = number(key) else { throw StyleLibrary.LoadError.missing("mock value \(key)") }
        return d
    }

    public func requireHex(_ key: String) throws -> String {
        guard let s = string(key), s.hasPrefix("#") else { throw StyleLibrary.LoadError.missing("mock colour \(key)") }
        return s
    }
}

/// house-contrast-v1's `sharedLighting`, the daytime lighting master (owner, 7 Oct): one clear
/// mid-afternoon for every view. Sky, sun, fill, shadow and grade values as the pack gives them.
public struct DaytimeMaster: Sendable, Equatable {
    public struct Sky: Sendable, Equatable {
        /// Gradient stops by elevation (degrees, ascending: horizon first).
        public var stops: [(elevation: Double, hex: String)]
        public var warmHorizonHex: String
        public var warmHorizonMaxMix: Double
        public var warmHorizonMaxElevation: Double
        public var cloudLitHex: String
        public var cloudShadeHex: String

        public static func == (a: Sky, b: Sky) -> Bool {
            a.stops.map(\.elevation) == b.stops.map(\.elevation) && a.stops.map(\.hex) == b.stops.map(\.hex)
                && a.warmHorizonHex == b.warmHorizonHex && a.warmHorizonMaxMix == b.warmHorizonMaxMix
                && a.warmHorizonMaxElevation == b.warmHorizonMaxElevation && a.cloudLitHex == b.cloudLitHex
                && a.cloudShadeHex == b.cloudShadeHex
        }
    }

    public var sky: Sky
    public var sunColorHex: String
    public var skyFillHex: String
    public var shadowTintHex: String
    /// 1 − shadow/lit linear luminance on a neutral witness patch (0.38: shadow/lit 0.62).
    public var shadowStrength: Double
    /// The grade, applied once in the pack's order: exposure EV, contrast about 0.18, saturation, warmth.
    public var grade: GradeTable.Look

    static let prefix = "house-contrast-v1/sharedLighting."

    public init(_ m: MockValues) throws {
        func n(_ k: String) throws -> Double { try m.requireNumber(Self.prefix + k) }
        func h(_ k: String) throws -> String { try m.requireHex(Self.prefix + k) }
        var stops: [(Double, String)] = []
        var i = 0
        while let e = try? n("sky.gradient[\(i)].elevationDeg") {
            stops.append((e, try h("sky.gradient[\(i)].hex")))
            i += 1
        }
        guard stops.count >= 2 else { throw StyleLibrary.LoadError.missing("daytime master sky gradient") }
        sky = Sky(stops: stops.sorted { $0.0 < $1.0 }.map { (elevation: $0.0, hex: $0.1) },
                  warmHorizonHex: try h("sky.warmHorizon.tintHex"), warmHorizonMaxMix: try n("sky.warmHorizon.maximumMix01"),
                  warmHorizonMaxElevation: try n("sky.warmHorizon.maxElevationDeg"),
                  cloudLitHex: try h("sky.cloudLitHex"), cloudShadeHex: try h("sky.cloudShadeHex"))
        sunColorHex = try h("sun.colorHex")
        skyFillHex = try h("sun.skyFillColorHex")
        shadowTintHex = try h("shadows.appearanceTintHex")
        shadowStrength = try n("shadows.strengthPercent") / 100
        grade = GradeTable.Look(exposureEV: try n("exposure.relativeEV"), contrast: try n("exposure.contrastSlope"),
                                saturation: try n("exposure.saturationFactor"), warmth: try n("exposure.additionalWarmthPercent") / 100)
    }
}

extension StyleLibrary {
    /// The approved mocks' values (`Profiles/mock-values.json`).
    public static func mockValues() throws -> MockValues {
        guard let m = MockValues.bundled else { throw LoadError.missing("mock-values") }
        return m
    }

    /// The daytime lighting master (house-contrast-v1 sharedLighting).
    public static func daytimeMaster() throws -> DaytimeMaster {
        try DaytimeMaster(mockValues())
    }
}
