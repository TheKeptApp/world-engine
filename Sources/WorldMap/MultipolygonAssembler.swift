import Foundation
import WorldGeo

/// Joins a multipolygon relation's member ways into closed rings and pairs holes with outers.
public enum MultipolygonAssembler {
    public enum Failure: Error, CustomStringConvertible {
        case missingMember(Int64)
        case unclosedRing
        case noOuterRing

        public var description: String {
            switch self {
            case .missingMember(let id): "multipolygon member way/\(id) missing"
            case .unclosedRing: "multipolygon ring does not close"
            case .noOuterRing: "multipolygon has no outer ring"
            }
        }
    }

    /// Returns one polygon per outer ring, each with the inner rings it contains.
    public static func assemble(_ rel: OSMRelation, in doc: OSMDocument, frame: LocalFrame) -> Result<[Polygon2D], Failure> {
        var outerWays: [[Int64]] = []
        var innerWays: [[Int64]] = []
        for m in rel.members where m.kind == .way {
            guard let way = doc.ways[m.ref] else { return .failure(.missingMember(m.ref)) }
            if m.role == "inner" { innerWays.append(way.nodeIDs) } else { outerWays.append(way.nodeIDs) }
        }
        guard let outerIDs = joinRings(outerWays), let innerIDs = joinRings(innerWays) else {
            return .failure(.unclosedRing)
        }
        func ring(_ ids: [Int64]) -> Ring? {
            var r: Ring = []
            for id in ids.dropLast() {
                guard let n = doc.nodes[id] else { return nil }
                r.append(frame.localPoint(of: n.coordinate))
            }
            return r
        }
        let outers = outerIDs.compactMap(ring)
        let inners = innerIDs.compactMap(ring)
        guard !outers.isEmpty else { return .failure(.noOuterRing) }

        var polygons = outers.map { Polygon2D(outer: $0) }
        for inner in inners {
            guard let probe = inner.first else { continue }
            // Smallest containing outer wins (handles nested outer-inner-outer islands).
            let containing = polygons.indices
                .filter { RingMath.contains(polygons[$0].outer, probe) }
                .min { abs(RingMath.signedArea(polygons[$0].outer)) < abs(RingMath.signedArea(polygons[$1].outer)) }
            if let i = containing { polygons[i].holes.append(inner) }
        }
        return .success(polygons)
    }

    /// Joins open node-ID chains end-to-end into closed rings (first == last).
    /// Returns nil if any chain cannot be closed.
    public static func joinRings(_ chains: [[Int64]]) -> [[Int64]]? {
        var remaining = chains.filter { $0.count >= 2 }
        var rings: [[Int64]] = []
        while var current = remaining.popLast() {
            while current.first != current.last {
                guard let tail = current.last,
                      let i = remaining.firstIndex(where: { $0.first == tail || $0.last == tail }) else {
                    return nil
                }
                let next = remaining.remove(at: i)
                current += (next.first == tail ? next : next.reversed()).dropFirst()
            }
            if current.count >= 4 { rings.append(current) }
        }
        return rings
    }
}
