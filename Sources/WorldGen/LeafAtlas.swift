import Foundation
import simd
import WorldGeo

/// The procedural leaf-cluster alpha atlas for leaf cards (`Paint.Flags.leafCard`): one R8 channel
/// (coverage; colour comes from the card's palette slot), a 4 × 4 grid of cells, drawn
/// deterministically from `StableRandom` (no photos). Rows: 0 broadleaf clusters, 1 small-leaf
/// clusters, 2 needle sprays, 3 willow strands; four variants per row. Each cell is mostly opaque in
/// its middle (cards are alpha-tested at 0.5 and opaque, so coverage keeps overdraw useful) with a
/// ragged leafy edge, and stays clear of its border (`padding`) so mipmaps don't bleed.
///
/// Layout: `bytes[y * width + x]`, row 0 first; texture coordinate (0, 0) is the first byte and v
/// grows with rows (the renderer flips if its convention differs).
public struct LeafAtlas: Sendable, Equatable {
    public enum Family: Int, Sendable, CaseIterable {
        case broadleaf = 0, smallLeaf, needles, strands
    }

    public let width: Int
    public let height: Int
    /// One byte per texel: coverage 0…255.
    public let bytes: [UInt8]
    /// Texel format of `bytes`.
    public let format = "r8Unorm"
    /// Cells per row and column.
    public static let grid = 4
    /// Clear border inside each cell, texels.
    public static let padding = 6

    /// UV rectangle (min, max) of a cell: `family` picks the row, `variant` (any integer) the column.
    public static func cell(_ family: Family, variant: Int) -> (min: SIMD2<Float>, max: SIMD2<Float>) {
        let c = Float(((variant % grid) + grid) % grid), r = Float(family.rawValue), s = 1 / Float(grid)
        return (SIMD2(c * s, r * s), SIMD2((c + 1) * s, (r + 1) * s))
    }

    /// Generates the atlas (`size` × `size` texels).
    public static func generate(size: Int = 1024) -> LeafAtlas {
        var px = [Float](repeating: 0, count: size * size)
        let cellSize = size / grid
        for family in Family.allCases {
            for column in 0..<grid {
                var rng = StableRandom(UInt64(family.rawValue), UInt64(column), salt: "leaf-atlas")
                let origin = SIMD2(column * cellSize, family.rawValue * cellSize)
                var painter = CellPainter(origin: origin, size: cellSize, stride: size)
                switch family {
                case .broadleaf: painter.cluster(&px, leaves: 130, reach: 0.4, length: 0.07...0.11, width: 0.035...0.05, core: 0.23, rng: &rng)
                case .smallLeaf: painter.cluster(&px, leaves: 300, reach: 0.41, length: 0.045...0.065, width: 0.02...0.03, core: 0.25, rng: &rng)
                case .needles: painter.spray(&px, rng: &rng)
                case .strands: painter.strands(&px, rng: &rng)
                }
            }
        }
        return LeafAtlas(width: size, height: size, bytes: px.map { UInt8(max(0, min(255, ($0 * 255).rounded()))) })
    }

    /// Coverage 0…1 at texture coordinate `uv` (nearest texel).
    public func coverage(_ uv: SIMD2<Float>) -> Float {
        let x = max(0, min(width - 1, Int(uv.x * Float(width)))), y = max(0, min(height - 1, Int(uv.y * Float(height))))
        return Float(bytes[y * width + x]) / 255
    }

    /// Draws one cell: coordinates in cell units (0…1, y down), kept inside the padding.
    struct CellPainter {
        var origin: SIMD2<Int>, size: Int, stride: Int

        /// A pointed leaf (lens) from `base` along `angle`: `length` long, `width` at its widest.
        func leaf(_ px: inout [Float], base: SIMD2<Float>, angle: Float, length: Float, width: Float) {
            let d = SIMD2<Float>(cos(angle), sin(angle)), n = SIMD2<Float>(-d.y, d.x)
            let mid = base + d * (length / 2), half = length / 2
            let s = Float(size), pad = Float(LeafAtlas.padding) / s
            let lo = simd_max(simd_min(base, base + d * length) - width, SIMD2(repeating: pad))
            let hi = simd_min(simd_max(base, base + d * length) + width, SIMD2(repeating: 1 - pad))
            guard lo.x < hi.x, lo.y < hi.y else { return }
            for y in Int(lo.y * s)...Int(hi.y * s) {
                for x in Int(lo.x * s)...Int(hi.x * s) {
                    let p = (SIMD2(Float(x), Float(y)) + 0.5) / s - mid
                    let u = simd_dot(p, d) / half, v = abs(simd_dot(p, n))
                    guard abs(u) < 1 else { continue }
                    let edge = (width / 2 * (1 - u * u) - v) * s   // texels inside the lens edge
                    let a = max(0, min(1, edge + 0.5))
                    let i = (origin.y + y) * stride + origin.x + x
                    px[i] = max(px[i], a)
                }
            }
        }

        /// A filled, slightly irregular disc (the cluster's dense middle).
        func disc(_ px: inout [Float], center: SIMD2<Float>, radius: Float, rng: inout StableRandom) {
            let wobble = (0..<5).map { _ in (Float(rng.range(0, 2 * .pi)), Float(rng.range(0.04, 0.1))) }
            let s = Float(size)
            for y in 0..<size { for x in 0..<size {
                let p = (SIMD2(Float(x), Float(y)) + 0.5) / s - center
                let a = atan2(p.y, p.x)
                let r = radius * (1 + wobble.enumerated().reduce(Float(0)) { $0 + $1.element.1 * sin(Float($1.offset + 2) * a + $1.element.0) })
                let edge = (r - simd_length(p)) * s
                guard edge > -1 else { continue }
                let i = (origin.y + y) * stride + origin.x + x
                px[i] = max(px[i], max(0, min(1, edge + 0.5)))
            } }
        }

        /// Broad- or small-leaf cluster: a dense middle and leaves pointing outward around it.
        func cluster(_ px: inout [Float], leaves: Int, reach: Float, length: ClosedRange<Double>, width: ClosedRange<Double>,
                     core: Float, rng: inout StableRandom) {
            let c = SIMD2<Float>(0.5, 0.5)
            disc(&px, center: c, radius: core, rng: &rng)
            for _ in 0..<leaves {
                let r = reach * Float(rng.unit()).squareRoot(), a = Float(rng.range(0, 2 * .pi))
                let base = c + SIMD2(cos(a), sin(a)) * r
                let l = Float(rng.range(length.lowerBound, length.upperBound))
                let tip = min(l, max(0.02, 0.47 - r))
                leaf(&px, base: base, angle: a + Float(rng.range(-0.6, 0.6)), length: tip, width: Float(rng.range(width.lowerBound, width.upperBound)))
            }
        }

        /// Needle spray: a dense middle and 9–11 branchlets fanning out, each with needles on both sides.
        func spray(_ px: inout [Float], rng: inout StableRandom) {
            let c = SIMD2<Float>(0.5, 0.55)
            disc(&px, center: c, radius: 0.17, rng: &rng)
            let count = 9 + Int(rng.next() % 3)
            for k in 0..<count {
                let a = -Float.pi / 2 + (Float(k) / Float(count - 1) - 0.5) * 2.6 + Float(rng.range(-0.15, 0.15))
                let d = SIMD2<Float>(cos(a), sin(a)), len = Float(rng.range(0.34, 0.42))
                leaf(&px, base: c, angle: a, length: len, width: 0.012)
                var t: Float = 0.04
                while t < len - 0.02 {
                    let p = c + d * t
                    for side: Float in [-1, 1] {
                        leaf(&px, base: p, angle: a + side * 1.0, length: Float(rng.range(0.06, 0.09)) * (1 - 0.5 * t / len), width: 0.014)
                    }
                    t += 0.014
                }
            }
        }

        /// Willow strands: a leafy band at the top and 11–13 hanging strands of narrow leaves.
        func strands(_ px: inout [Float], rng: inout StableRandom) {
            let count = 11 + Int(rng.next() % 3)
            for k in 0..<count {
                let x0 = 0.12 + 0.76 * (Float(k) + Float(rng.range(0.2, 0.8))) / Float(count)
                let bottom = Float(rng.range(0.82, 0.95)), sway = Float(rng.range(-0.05, 0.05))
                var y: Float = 0.06
                var side: Float = 1
                while y < bottom {
                    let t = (y - 0.06) / (bottom - 0.06)
                    let x = x0 + sway * t * t
                    leaf(&px, base: SIMD2(x, y), angle: .pi / 2 + side * 0.45, length: 0.05 * (1 - 0.3 * t), width: 0.016)
                    leaf(&px, base: SIMD2(x, y), angle: .pi / 2, length: 0.03, width: 0.008)
                    side = -side
                    y += 0.016
                }
            }
            for _ in 0..<40 {
                let base = SIMD2<Float>(Float(rng.range(0.08, 0.92)), Float(rng.range(0.05, 0.16)))
                leaf(&px, base: base, angle: .pi / 2 + Float(rng.range(-0.8, 0.8)), length: 0.06, width: 0.02)
            }
        }
    }
}
