import simd
import WorldGeo

/// General clipped cell grid. Extent changes may keep a previous geographic anchor;
/// absent an anchor, the arithmetic and cells are identical to the legacy layout.
struct ChunkGrid {
    let bounds: Rect2D
    let size: Double
    let start: LocalPoint
    let count: SIMD2<Int>

    init(bounds: Rect2D, size: Double, anchor: LocalPoint? = nil) {
        precondition(size > 0 && size.isFinite && bounds.width > 0 && bounds.height > 0)
        self.bounds = bounds
        self.size = size
        if let anchor {
            start = anchor + LocalPoint(((bounds.min.x - anchor.x) / size).rounded(.down),
                                        ((bounds.min.y - anchor.y) / size).rounded(.down)) * size
        } else {
            start = bounds.min
        }
        count = SIMD2(Int(((bounds.max.x - start.x) / size).rounded(.up)),
                      Int(((bounds.max.y - start.y) / size).rounded(.up)))
    }

    func index(_ p: LocalPoint) -> SIMD2<Int> {
        SIMD2(Int(((p.x - start.x) / size).rounded(.down)),
              Int(((p.y - start.y) / size).rounded(.down)))
    }

    func rect(_ index: SIMD2<Int>) -> Rect2D {
        let lo = start + LocalPoint(Double(index.x), Double(index.y)) * size
        let hi = start + LocalPoint(Double(index.x + 1), Double(index.y + 1)) * size
        return Rect2D(min: simd_max(bounds.min, lo), max: simd_min(bounds.max, hi))
    }
}
