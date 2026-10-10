import Foundation
import simd
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// P2 Batch 1 default-off look experiments: off is main, on keeps every triangle and changes only paint.
@Suite(.serialized) struct LookExperimentsTests {
    @Test func flagsParseFromLaunchArgumentsAndEnvironment() {
        #expect(LookExperiments.parse([], [:]).isEmpty)
        #expect(LookExperiments.parse(["app", "-lookexp", "lawnsmooth,bogus"], [:]) == ["lawnsmooth"])
        #expect(LookExperiments.parse([], ["WORLDENGINE_LOOKEXP": "wallspread"]) == ["wallspread"])
    }

    @Test func broadFieldIsSmoothAndBounded() {
        let f = BroadField(wavelength: 60, salt: "t")
        var worst = 0.0
        for k in 0..<2000 {
            let p = LocalPoint(Double(k) * 0.7, Double(k % 37) * 3.1)
            let v = f.value(p)
            #expect(v >= -1 && v <= 1)
            worst = max(worst, abs(f.value(p + LocalPoint(1, 0)) - v))
        }
        #expect(worst < 0.06, "1 m step changes the field by at most ~3/λ: \(worst)")
    }

    static func build(_ area: String, _ profile: String, _ on: Set<String>) throws -> WorldBuild {
        try LookExperiments.$active.withValue(on) { try YardTests.build(area, profile) }
    }

    static func sameGeometry(_ a: WorldBuild, _ b: WorldBuild) -> Bool {
        a.scene.chunks.count == b.scene.chunks.count
            && zip(a.scene.chunks, b.scene.chunks).allSatisfy { $0.staticMesh.positions == $1.staticMesh.positions && $0.staticMesh.indices == $1.staticMesh.indices }
            && zip(a.scene.buildings, b.scene.buildings).allSatisfy { $0.mesh.positions == $1.mesh.positions && $0.mesh.indices == $1.mesh.indices }
    }

    @Test(arguments: [("sloans-lake", "front-range"), ("lakeview-sheil-park", "chicago-dense-north")])
    func lawnSmoothHalvesLotToLotSpread(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let off = try Self.build(area, profile, []), on = try Self.build(area, profile, [LookExperiments.lawnSmooth])
        #expect(Self.sameGeometry(off, on))
        // Only lot lawns change.
        for (x, y) in zip(off.scene.chunks, on.scene.chunks) {
            for fr in x.staticFeatures where !fr.feature.hasPrefix("gen:lot:") {
                #expect(x.staticMesh.paints[fr.start..<(fr.start + fr.count)] == y.staticMesh.paints[fr.start..<(fr.start + fr.count)], "\(fr.feature)")
            }
        }
        // Mean lawn paint per lot; neighbouring lots (anchors within 30 m) compared.
        func lots(_ b: WorldBuild) -> [String: (LocalPoint, Double, Double)] {
            var acc: [String: (LocalPoint, Double, Double, Int)] = [:]
            for chunk in b.scene.chunks {
                for fr in chunk.staticFeatures where fr.feature.hasPrefix("gen:lot:") {
                    for i in fr.start..<(fr.start + fr.count) {
                        let q = chunk.staticMesh.positions[i]
                        var e = acc[fr.feature] ?? (LocalPoint(0, 0), 0, 0, 0)
                        e.0 += LocalPoint(Double(q.x), -Double(q.z)); e.1 += Double(chunk.staticMesh.paints[i].y)
                        e.2 += Double(chunk.staticMesh.extras[i].y); e.3 += 1
                        acc[fr.feature] = e
                    }
                }
            }
            return acc.mapValues { ($0.0 / Double($0.3), $0.1 / Double($0.3), $0.2 / Double($0.3)) }
        }
        let a = lots(off), b = lots(on)
        let keys = a.keys.sorted()
        var dOff = 0.0, dOn = 0.0, tOff = 0.0, tOn = 0.0, n = 0
        for (i, k) in keys.enumerated() {
            for k2 in keys[(i + 1)...].prefix(60) where simd_distance(a[k]!.0, a[k2]!.0) < 30 {
                dOff += abs(a[k]!.1 - a[k2]!.1); dOn += abs(b[k]!.1 - b[k2]!.1)
                tOff += abs(a[k]!.2 - a[k2]!.2); tOn += abs(b[k]!.2 - b[k2]!.2); n += 1
            }
        }
        print("lawnsmooth \(area): \(n) neighbour pairs, |Δshade| \(dOff / Double(n)) → \(dOn / Double(n)), |Δtone| \(tOff / Double(n)) → \(tOn / Double(n))")
        #expect(n > 100)
        #expect(dOn < 0.5 * dOff && tOn < 0.5 * tOff)
    }

    @Test(arguments: [("sloans-lake", "front-range"), ("lakeview-sheil-park", "chicago-dense-north")])
    func wallSpreadScalesOnlyUnmappedHouseWalls(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let off = try Self.build(area, profile, []), on = try Self.build(area, profile, [LookExperiments.wallSpread])
        #expect(Self.sameGeometry(off, on))
        let tags = Dictionary(off.features.buildings.map { ($0.ref.description, $0.tags) }, uniquingKeysWith: { a, _ in a })
        var ratios: [String: Double] = [:], mappedChanged = 0, otherChanged = 0
        for (x, y) in zip(off.scene.chunks, on.scene.chunks) {
            for fr in x.staticFeatures {
                let range = fr.start..<(fr.start + fr.count)
                let changed = zip(x.staticMesh.paints[range], y.staticMesh.paints[range]).filter { $0 != $1 }
                guard let first = changed.first else { continue }
                guard let t = tags[fr.feature] else { otherChanged += changed.count; continue }
                if t["building:colour"] != nil { mappedChanged += changed.count; continue }
                let r = Double(first.1.y / first.0.y)
                #expect(changed.allSatisfy { abs(Double($0.1.y / $0.0.y) - r) < 1e-3 && $0.0.x == $0.1.x }, "\(fr.feature): one factor, slots unchanged")
                if let prev = ratios[fr.feature] { #expect(abs(prev - r) < 1e-3) }
                ratios[fr.feature] = r
            }
        }
        #expect(otherChanged == 0, "only building walls change")
        #expect(mappedChanged == 0)
        #expect(ratios.count > 100 && ratios.values.allSatisfy { $0 >= 0.82 - 1e-3 && $0 <= 1.22 + 1e-3 })
        print("wallspread \(area): \(ratios.count) buildings, factor \(ratios.values.min() ?? 0)…\(ratios.values.max() ?? 0)")
    }
}
