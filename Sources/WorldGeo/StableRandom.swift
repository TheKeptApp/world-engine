/// A seeded random generator that gives identical results on every run and every device.
///
/// All generated detail (house colors, tree scatter, height jitter) is seeded from stable
/// inputs such as an OSM element ID. Never seed from Swift's `Hasher`: it is randomized per
/// process.
public struct StableRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    /// Seeds from a list of integers plus a salt string that separates independent uses
    /// (e.g. "roof-color" and "door-color" for the same building).
    public init(_ parts: UInt64..., salt: String) {
        var h = StableRandom.fnv1a(salt)
        for p in parts { h = StableRandom.mix(h ^ p) }
        state = h
    }

    /// SplitMix64.
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        return StableRandom.mix(state)
    }

    /// A Double in [0, 1).
    public mutating func unit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    /// A Double in [lo, hi).
    public mutating func range(_ lo: Double, _ hi: Double) -> Double {
        lo + (hi - lo) * unit()
    }

    static func mix(_ x: UInt64) -> UInt64 {
        var z = x
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    static func fnv1a(_ s: String) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 0x100_0000_01B3
        }
        return h
    }
}
