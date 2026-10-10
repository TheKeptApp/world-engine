import Foundation
import simd
import Testing
import WorldGeo
import WorldMap
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

    static let batch2: [(String, String)] = [("sloans-lake", "front-range"), ("lakeview-sheil-park", "chicago-dense-north"),
                                              ("wilmette-vattmann-park", "wilmette")]

    /// roadclip: no mapped sidewalk or path piece crosses a street carriageway; only those features change.
    @Test(arguments: batch2)
    func roadClipRemovesCarriagewayCrossings(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let off = try Self.build(area, profile, []), on = try Self.build(area, profile, [LookExperiments.roadClip])
        let clip = RoadClip(off.features.roads)
        var before = (0, 0.0, 0, 0.0), after = (0, 0.0, 0, 0.0)
        func add(_ a: inout (Int, Double, Int, Double), _ o: (crossingRuns: Int, crossingM: Double, parallelRuns: Int, parallelM: Double)) {
            a.0 += o.crossingRuns; a.1 += o.crossingM; a.2 += o.parallelRuns; a.3 += o.parallelM
        }
        let lines = off.features.sidewalks.filter { !$0.suppressesPedestrianSurfaceRendering }.map(\.centerline)
            + off.features.paths.filter { !$0.isCrossing && !$0.suppressesPedestrianSurfaceRendering }.map(\.centerline)
        for l in lines {
            add(&before, clip.overlap(l))
            for piece in clip.pieces(l) { add(&after, clip.overlap(piece)) }
        }
        print("roadclip \(area): crossing runs \(before.0) / \(Int(before.1)) m → \(after.0) / \(Int(after.1)) m; lying along \(before.2) / \(Int(before.3)) m (kept)")
        #expect(after.1 <= 2 * RoadClip.step * Double(before.0), "at most one sample per cut end remains")
        #expect(on.scene.buildings.count == off.scene.buildings.count)
        let changed = Set(zip(off.scene.chunks, on.scene.chunks).flatMap { x, y in
            Set(x.staticFeatures.map(\.feature)).symmetricDifference(y.staticFeatures.map(\.feature))
                .union(x.staticFeatures.filter { f in !y.staticFeatures.contains(where: { $0.feature == f.feature && $0.count == f.count }) }.map(\.feature))
        })
        let mapped = Set(off.features.sidewalks.map(\.ref.description) + off.features.paths.map(\.ref.description))
        #expect(changed.isSubset(of: mapped), "only mapped sidewalks/paths change: \(changed.subtracting(mapped).prefix(3))")
    }

    /// commercialpoints: footprints ≥ 250 m² holding a shop/food point become commercial blocks; nothing else changes role.
    @Test(arguments: batch2)
    func commercialPointsMapToMixedUse(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        func zoned() throws -> WorldBuild {
            try WorldBuild.generate(areaDirectory: BuildingAreaTests.dir(area), recipe: WorldRecipe(date: ISO8601DateFormatter().date(from: "2026-10-15T20:30:00Z")!))
        }
        let off = try LookExperiments.$active.withValue([]) { try zoned() }
        let on = try LookExperiments.$active.withValue([LookExperiments.commercialPoints]) { try zoned() }
        let a = Dictionary(off.scene.buildings.map { ($0.ref, $0) }, uniquingKeysWith: { x, _ in x })
        var changes: [String: Int] = [:]
        var seen = Set<OSMRef>()
        for g in on.scene.buildings where seen.insert(g.ref).inserted {
            guard let o = a[g.ref], o.role != g.role || o.family != g.family else { continue }
            changes["\(o.role.rawValue):\(o.family ?? "-") → \(g.role.rawValue):\(g.family ?? "-")", default: 0] += 1
            #expect(["cornerMixedUse", "denverMixedUse"].contains(g.family ?? ""), "\(g.ref) → \(g.family ?? "-")")
        }
        print("commercialpoints \(area): \(changes.values.reduce(0, +)) buildings change: \(changes.sorted { $0.key < $1.key })")
    }

    /// Batch 3: per-area counts for the five ground/building experiments (all default off).
    @Test(arguments: batch2)
    func batch3Counts(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        func zoned(_ on: Set<String>) throws -> WorldBuild {
            try LookExperiments.$active.withValue(on) {
                try WorldBuild.generate(areaDirectory: BuildingAreaTests.dir(area), recipe: WorldRecipe(date: ISO8601DateFormatter().date(from: "2026-10-15T20:30:00Z")!))
            }
        }
        let off = try zoned([])
        let f = off.features
        // sidewalkendshort: curb ends whose ribbon reaches a carriageway, before (roadclip pieces) and after.
        let clip = RoadClip(f.roads)
        var before = 0, after = 0, dropped = 0
        for sw in f.sidewalks where !sw.suppressesPedestrianSurfaceRendering {
            for piece in clip.pieces(sw.centerline) {
                before += clip.curbEnds(piece, halfWidth: 0.8)
                if let short = clip.endShort(piece, halfWidth: 0.8) { after += clip.curbEnds(short, halfWidth: 0.8) } else { dropped += 1 }
            }
        }
        // The trim is capped at 4 m so a long sidewalk is never deleted; an end needing more stays (reported).
        #expect(after * 50 <= before, "\(area): \(after) of \(before) curb ends still reach the road")
        let retail = f.areas.filter { $0.kind == .commercial }.count
        let parking = f.areas.filter { $0.kind == .parking }
        let notGround = parking.filter { ["underground", "rooftop", "multi-storey"].contains($0.tags["parking"] ?? "") }.count
        var sports: [String: Int] = [:]
        for a in f.areas where a.kind == .pitch {
            let k = SportsLook.kind(a.tags)
            let name = switch k { case .court: "court"; case .field: "field"; case .diamond: "diamond"; case .track: "track"; case .plain: "plain" }
            sports[name, default: 0] += 1
            if case .diamond(let side) = k, SportsLook.infield(a.polygon, side: side) != nil { sports["infield", default: 0] += 1 }
        }
        let apartmentsOn = try zoned([LookExperiments.denverApartments])
        let a = Dictionary(off.scene.buildings.map { ($0.ref, $0) }, uniquingKeysWith: { x, _ in x })
        var apartments: [String: Int] = [:], seen = Set<OSMRef>()
        for g in apartmentsOn.scene.buildings where seen.insert(g.ref).inserted {
            guard let o = a[g.ref], o.role != g.role || o.family != g.family else { continue }
            apartments["\(o.family ?? "-") → \(g.family ?? "-")", default: 0] += 1
            #expect(["denverApartment", "denverCourtyard"].contains(g.family ?? ""))
        }
        let tracks = try zoned([LookExperiments.sportsFields])
        let trackRanges = tracks.scene.chunks.flatMap(\.staticFeatures).filter { $0.feature.hasPrefix("gen:track:") }.map(\.feature)
        print("batch3 \(area): curb ends \(before) → \(after) (pieces dropped \(dropped)); retail/commercial areas \(retail); parking \(parking.count) (not at ground \(notGround)); pitches \(sports.sorted { $0.key < $1.key }); tracks \(Set(trackRanges).count); denver apartments \(apartments.values.reduce(0, +)) \(apartments.sorted { $0.key < $1.key })")
    }

    /// Batch 4 warmwalls: Front Range unmapped wall/roof colours move into the measured mock ranges; Chicago is unchanged.
    @Test(arguments: [("sloans-lake", "front-range"), ("lakeview-sheil-park", "chicago-dense-north")])
    func warmWallsMoveFrontRangeOnly(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let off = try Self.build(area, profile, []), on = try Self.build(area, profile, [LookExperiments.warmWalls])
        #expect(Self.sameGeometry(off, on))
        let tags = Dictionary(off.features.buildings.map { ($0.ref, $0.tags) }, uniquingKeysWith: { a, _ in a })
        func stats(_ b: WorldBuild, _ i: Int, mappedKey: String) -> [WarmWalls.LCh] {
            var seen = Set<OSMRef>()
            return b.scene.buildings.filter { ($0.role == .house || $0.role == .block) && seen.insert($0.ref).inserted && $0.colors.count == 4
                && tags[$0.ref]?[mappedKey] == nil }.map { WarmWalls.lch($0.colors[i]) }
        }
        func summary(_ v: [WarmWalls.LCh]) -> String {
            func r(_ k: KeyPath<WarmWalls.LCh, Double>) -> String {
                let s = v.map { $0[keyPath: k] }.sorted()
                return s.isEmpty ? "-" : String(format: "%.0f–%.0f (p50 %.0f)", s[s.count / 10], s[s.count * 9 / 10], s[s.count / 2])
            }
            return "L* \(r(\.l)) C* \(r(\.c)) h \(r(\.h))"
        }
        let w0 = stats(off, 0, mappedKey: "building:colour"), w1 = stats(on, 0, mappedKey: "building:colour")
        let r0 = stats(off, 3, mappedKey: "roof:colour"), r1 = stats(on, 3, mappedKey: "roof:colour")
        print("warmwalls \(area): walls \(summary(w0)) → \(summary(w1)); roofs \(summary(r0)) → \(summary(r1)) (n=\(w1.count))")
        if profile == "front-range" {
            #expect(w1.allSatisfy { $0.h >= 29 && $0.h <= 64 && $0.l >= 56 && $0.l <= 78 && $0.c <= 22 })
            #expect(r1.allSatisfy { $0.l >= 35 && $0.l <= 41 && $0.c >= 11 && $0.c <= 19 })
        } else {
            #expect(zip(off.scene.buildings, on.scene.buildings).allSatisfy { $0.colors == $1.colors })
        }
    }
}
