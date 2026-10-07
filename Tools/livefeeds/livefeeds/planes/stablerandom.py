"""Python port of `Sources/WorldGeo/StableRandom.swift` (SplitMix64 seeded by FNV-1a of a salt), bit for bit,
so a Swift port of the ambient-planes generator draws the same numbers on every device."""

M64 = (1 << 64) - 1


def mix(x: int) -> int:
    z = x & M64
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)


def fnv1a(s: str) -> int:
    h = 0xCBF29CE484222325
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x100000001B3) & M64
    return h


class StableRandom:
    def __init__(self, *parts: int, salt: str):
        h = fnv1a(salt)
        for p in parts:
            h = mix(h ^ (p & M64))
        self.state = h

    def next(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & M64
        return mix(self.state)

    def unit(self) -> float:
        return (self.next() >> 11) * 2.0 ** -53

    def range(self, lo: float, hi: float) -> float:
        return lo + (hi - lo) * self.unit()
