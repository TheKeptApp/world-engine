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
        // style-b-calibration-v2 owns look (owner, 7 Oct): its shared values win where present. Its sky
        // has three stops without elevations (P3 sampled them from the frames); the mid stop keeps the
        // master's 30°. It has no warm-horizon key, so the master's stays.
        let c = "style-b/look/lighting."
        if let zen = m.string(c + "sky.zenithHex"), let mid = m.string(c + "sky.midHex"), let hor = m.string(c + "sky.horizonHex") {
            sky.stops = [(0, hor), (30, mid), (90, zen)]
        }
        if let s = m.string(c + "sky.cloudLitHex") { sky.cloudLitHex = s }
        if let s = m.string(c + "sky.cloudShadeHex") { sky.cloudShadeHex = s }
        if let s = m.string(c + "sun.hex") { sunColorHex = s }
        if let s = m.string(c + "sky.fillHex") { skyFillHex = s }
        if let s = m.string(c + "shadow.appearanceHex") { shadowTintHex = s }
        if let r = m.number(c + "shadow.neutralWitnessShadowToLitLinearY") { shadowStrength = 1 - r }
        if let ev = m.number(c + "exposure.relativeEV"), let con = m.number(c + "exposure.contrast"),
           let sat = m.number(c + "exposure.saturation"), let warm = m.number(c + "exposure.additionalWarmth") {
            grade = GradeTable.Look(exposureEV: ev, contrast: con, saturation: sat, warmth: warm)
        }
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

/// Lake water (owner 7 Oct): lake-winter-v1 owns colour, shoreline and reflection; water-surfaces-v1
/// (style-b/water) owns the wave mechanics (its four-term weights). Read by key from mock-values.json.
public struct LakeWater: Sendable {
    public struct Wave: Sendable { public var amplitudeM: Double; public var wavelengthM: Double; public var speedMps: Double }
    public struct Profile: Sendable {
        public var shallowHex: String
        public var shallowBlendWidthM: Double
        /// Wave by wind speed (km/h), ascending.
        public var waves: [(windKmh: Double, wave: Wave)]

        /// The wave at a wind speed, interpolated between the pack's rows (held past the last).
        public func wave(windKmh w: Double) -> Wave {
            guard let first = waves.first else { return Wave(amplitudeM: 0, wavelengthM: 1, speedMps: 0) }
            if w <= first.windKmh { return first.wave }
            for (a, b) in zip(waves, waves.dropFirst()) where w <= b.windKmh {
                let t = (w - a.windKmh) / max(b.windKmh - a.windKmh, 1e-6)
                func mix(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
                return Wave(amplitudeM: mix(a.wave.amplitudeM, b.wave.amplitudeM), wavelengthM: mix(a.wave.wavelengthM, b.wave.wavelengthM),
                            speedMps: mix(a.wave.speedMps, b.wave.speedMps))
            }
            return waves.last!.wave
        }
    }
    /// By P2's shore-profile order (look.json water.shoreProfiles.order; the index in water-mesh extra.w).
    public var profiles: [Profile]
    public var shoreDarkenMultiplier: Double
    public var shoreDarkenWidthM: Double
    public var shoreTransitionWidthM: Double
    public var grazingStrength: Double
    public var grazingExponent: Double
    public var f0: Double
    /// Sky blend looking straight down (lake-winter-v1 water.reflection.normalStrength; 0.12 → grazing 0.55).
    public var normalStrength: Double
    public var aerialScale: Double
    public var waveWeights: [Double]
    /// Water roughness by wind speed (km/h), ascending (lake-winter-v1 water.windStates).
    public var roughnessByWind: [(windKmh: Double, roughness: Double)]
    /// Ripple normal amplitude by wind speed (km/h) (lake-winter-v1 water.windStates.*.normalAmplitude).
    public var normalAmplitudeByWind: [(windKmh: Double, roughness: Double)]
    /// Ripple detail fades between these distances (m); aerial views scale it.
    public var detailFadeStartM: Double
    public var detailFadeEndM: Double
    public var aerialNormalScale: Double

    /// Roughness at a wind speed, interpolated (held past the ends).
    public func roughness(windKmh w: Double) -> Double { Self.interpolate(roughnessByWind, w) ?? 0.28 }

    /// Ripple normal amplitude at a wind speed (km/h).
    public func normalAmplitude(windKmh w: Double) -> Double { Self.interpolate(normalAmplitudeByWind, w) ?? 0 }

    static func interpolate(_ rows: [(windKmh: Double, roughness: Double)], _ w: Double) -> Double? {
        guard let first = rows.first else { return nil }
        if w <= first.windKmh { return first.roughness }
        for (a, b) in zip(rows, rows.dropFirst()) where w <= b.windKmh {
            return a.roughness + (b.roughness - a.roughness) * (w - a.windKmh) / max(b.windKmh - a.windKmh, 1e-6)
        }
        return rows.last!.roughness
    }

    public init(_ m: MockValues, order: [String]) throws {
        let p = "lake-winter-v1/water."
        func n(_ k: String) throws -> Double { try m.requireNumber(p + k) }
        profiles = try order.map { id in
            let winds = [0.0, 10, 25, 40, 60].filter { m.number(p + "profiles.\(id).waveByWindKmh.\(Int($0)).amplitudeM") != nil }
            return Profile(shallowHex: try m.requireHex(p + "profiles.\(id).shallowColourHex"),
                           shallowBlendWidthM: try n("profiles.\(id).shallowBlendWidthM"),
                           waves: try winds.map { w in
                               let k = "profiles.\(id).waveByWindKmh.\(Int(w))."
                               return (w, Wave(amplitudeM: try n(k + "amplitudeM"), wavelengthM: try n(k + "wavelengthM"), speedMps: try n(k + "phaseSpeedMps")))
                           })
        }
        shoreDarkenMultiplier = try n("shoreline.linearBaseMultiplier")
        shoreDarkenWidthM = try n("shoreline.darkeningWidthM")
        shoreTransitionWidthM = try n("shoreline.transitionWidthM")
        grazingStrength = try n("reflection.grazingStrength")
        grazingExponent = try n("reflection.grazingExponent")
        f0 = try n("reflection.physicalF0")
        normalStrength = try n("reflection.normalStrength")
        aerialScale = try n("reflection.aerialScale")
        waveWeights = (0..<4).compactMap { m.number("style-b/water/waveModelProposal.fourWaveWeights[\($0)]") }
        roughnessByWind = [0.0, 10, 25, 40, 60].compactMap { w in m.number(p + "windStates.\(Int(w)).roughness").map { (w, $0) } }
        normalAmplitudeByWind = [0.0, 10, 25, 40, 60].compactMap { w in m.number(p + "windStates.\(Int(w)).normalAmplitude").map { (w, $0) } }
        detailFadeStartM = try n("lod.normalDetailFadeStartM")
        detailFadeEndM = try n("lod.normalDetailFadeEndM")
        aerialNormalScale = try n("lod.aerialNormalAmplitudeScale")
    }
}

extension StyleLibrary {
    /// Lake water values for P2's shore-profile order.
    public static func lakeWater() throws -> LakeWater {
        try LakeWater(mockValues(), order: LookSpec.bundled?.water.shoreProfiles?.order ?? ["lake_michigan", "sloans_lake"])
    }
}
