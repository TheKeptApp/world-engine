import Foundation
import simd
import WorldGeo
import WorldMap
import WorldGen

/// Synthetic footprints for `--gallery` (same shapes as Tests/WorldGenTests/BuildingGeometryTests.swift).
enum Gallery {
    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    static let footprints: [(String, Ring)] = [
        ("rectangle", rect(0, 0, 12, 9)),
        ("narrow-deep", rect(0, 0, 7.5, 18)),
        ("L", [LocalPoint(0, 0), LocalPoint(14, 0), LocalPoint(14, 6), LocalPoint(6, 6), LocalPoint(6, 12), LocalPoint(0, 12)]),
        ("T", [LocalPoint(0, 4), LocalPoint(4, 4), LocalPoint(4, 0), LocalPoint(9, 0), LocalPoint(9, 4), LocalPoint(13, 4),
               LocalPoint(13, 10), LocalPoint(0, 10)]),
        ("U", [LocalPoint(0, 0), LocalPoint(16, 0), LocalPoint(16, 12), LocalPoint(11, 12), LocalPoint(11, 5), LocalPoint(5, 5),
               LocalPoint(5, 12), LocalPoint(0, 12)]),
        ("front-bay", [LocalPoint(0, 1.2), LocalPoint(3, 1.2), LocalPoint(3, 0), LocalPoint(6, 0), LocalPoint(6, 1.2), LocalPoint(9, 1.2),
                       LocalPoint(9, 14), LocalPoint(0, 14)]),
        ("stepped", [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 5), LocalPoint(12, 5), LocalPoint(12, 11), LocalPoint(3, 11),
                     LocalPoint(3, 8), LocalPoint(0, 8)]),
        ("notched-corner", [LocalPoint(0, 0), LocalPoint(11, 0), LocalPoint(11, 7), LocalPoint(9.5, 7), LocalPoint(9.5, 9),
                            LocalPoint(0, 9)]),
        ("trapezoid", [LocalPoint(0, 0), LocalPoint(12, 0), LocalPoint(11, 9), LocalPoint(1.5, 9)]),
        ("chamfered", [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(12, 2), LocalPoint(12, 10), LocalPoint(0, 10)]),
        ("rotated-L", [LocalPoint(0, 0), LocalPoint(12, 5), LocalPoint(9.7, 10.5), LocalPoint(4.2, 8.2), LocalPoint(1.9, 13.7),
                       LocalPoint(-3.6, 11.4)]),
        ("jittered", [LocalPoint(0, 0), LocalPoint(6.02, 0.03), LocalPoint(12, 0), LocalPoint(12.05, 9.97), LocalPoint(0.04, 10)]),
    ]

    static let defaultShapes = ["rectangle", "L", "T", "U", "front-bay", "stepped", "trapezoid", "chamfered"]

    struct Cell {
        var shape: String
        var column: Int
        var row: Int
        var id: Int64
        var origin: LocalPoint
    }

    /// Builds features for a grid: one row per shape (north to south), one column per building ID.
    /// Each row has a named residential street 12 m south of the footprint origin.
    static func features(shapes: [String], columns: Int, spacing: Double, rowSpacing: Double) throws -> (MapFeatures, [Cell]) {
        let frame = LocalFrame(origin: GeoCoordinate(latitude: 42, longitude: -87.7))
        var nodes: [String] = []
        var ways: [String] = []
        var nextNode: Int64 = 1
        var cells: [Cell] = []

        func node(_ p: LocalPoint) -> Int64 {
            let c = frame.coordinate(at: p)
            let id = nextNode
            nextNode += 1
            nodes.append(#"{"type":"node","id":\#(id),"lat":\#(c.latitude),"lon":\#(c.longitude)}"#)
            return id
        }

        let width = Double(columns) * spacing + 60
        var wayID: Int64 = 9_000_000
        for (r, name) in shapes.enumerated() {
            // "sheet:<archetype id>": the archetype sheet's footprint (house-archetypes-v1 width x depth).
            let sheet = name.hasPrefix("sheet:") ? HouseArchetype.named(String(name.dropFirst(6))).map { rect(0, 0, $0.footprintWidth, $0.footprintDepth) } : nil
            guard let ring = sheet ?? footprints.first(where: { $0.0 == name })?.1 else {
                throw NSError(domain: "buildingviz", code: 3, userInfo: [NSLocalizedDescriptionKey: "unknown shape \(name)"])
            }
            let oy = -Double(r) * rowSpacing
            for c in 0..<columns {
                let ox = Double(c) * spacing
                let id = Int64(c + 1) * 101
                let pts = ring.map { LocalPoint($0.x + ox, $0.y + oy) }
                var ids = pts.map(node)
                ids.append(ids[0])
                ways.append(#"{"type":"way","id":\#(id + Int64(r) * 100_000),"nodes":[\#(ids.map(String.init).joined(separator: ","))],"tags":{"building":"house"}}"#)
                cells.append(Cell(shape: name, column: c, row: r, id: id + Int64(r) * 100_000, origin: LocalPoint(ox, oy)))
            }
            let a = node(LocalPoint(-30, oy - 12)), b = node(LocalPoint(width - 30, oy - 12))
            wayID += 1
            ways.append(#"{"type":"way","id":\#(wayID),"nodes":[\#(a),\#(b)],"tags":{"highway":"residential","name":"Test Street"}}"#)
        }
        let json = #"{"elements":[\#((nodes + ways).joined(separator: ","))]}"#
        let doc = try OSMDocument(overpassJSON: Data(json.utf8))
        let rows = Double(shapes.count) * rowSpacing
        let bounds = Rect2D(min: LocalPoint(-100, -rows - 100), max: LocalPoint(width + 100, 100))
        let builder = MapFeatureBuilder(frame: frame, bounds: bounds)
        return (builder.build(doc), cells)
    }
}
