import Foundation
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// House contrast (house-contrast-v1 swatches via look.json): mapped families take their house type's
/// soffit and porch-underside colours (down-facing faces) and eave/cornice shadow band at near detail; trim stays
/// house-details-v1's.
struct HouseContrastTests {
    @Test func lookCarriesThePackSwatches() throws {
        let hc = try #require(BuildingGenerator.contrast)
        #expect(hc.values("chicago_three_flat")?.soffit == "#51463E" && hc.values("chicago_three_flat")?.trim == "#DBC8A7")
        #expect(hc.type(family: "brickStackedFacade", floors: 3) == hc.values("chicago_three_flat"))
        #expect(hc.type(family: "brickStackedFacade", floors: 2) == hc.values("chicago_two_flat"))
        for (fam, id) in hc.families where id != "flat" { #expect(hc.values(id) != nil, "\(fam) → \(id) missing in mock values") }
        #expect(hc.type(family: "modernInfill", floors: 3) == nil)
    }

    @Test(arguments: ["evanston", "chicago-dense-north"])
    func soffitsTrimAndBandFollowTheType(_ profile: String) throws {
        let gen = try HouseDetailTests.generator(profile)
        let hc = try #require(BuildingGenerator.contrast)
        var palette = Palette(base: try StyleLibrary.baseColors())
        var checked = 0
        for (_, ring) in HouseDetailTests.rings {
            for id in Int64(1)...Int64(40) {
                let g = gen.generate(testBuilding(41_000 + id, ring), palette: &palette, lod: .near)
                guard g.role == .house, gen.families.grammar(g.family).details != nil,
                      let t = hc.type(family: g.family, floors: g.floors) ?? hc.type(family: g.family, floors: 2) else { continue }
                let m = g.mesh
                let down = (0..<m.vertexCount).filter { m.normals[$0].y < -0.5 }
                let allowed = Set([Float(palette.slot(hex: t.soffit)), Float(palette.slot(hex: t.porchShadow))])
                #expect(down.allSatisfy { allowed.contains(m.paints[$0].x) }, "\(g.family ?? "-"): soffit colour")
                let top = g.roofShape == .flat ? nil : Optional(g.eaveHeight)
                if let top {
                    let wall = Float(palette.slot(hex: g.colors[0]))
                    let band = (0..<m.vertexCount).filter { abs(m.normals[$0].y) < 0.3 && abs(Double(m.positions[$0].y) - top) < 0.02 && m.paints[$0].x == wall }.map { m.paints[$0].y }
                    if !band.isEmpty { #expect(band.max()! <= Float(t.eaveShadow) * 1.04 + 0.01, "\(g.family ?? "-"): eave band \(band.max()!)") }
                }
                checked += 1
            }
        }
        #expect(checked > 10, "\(profile): \(checked) houses checked")
    }

    /// look.json houseContrast is identical to the shared mock values (Resources/look/mock-values.json).
    @Test func valuesMatchSharedMockValues() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/look/mock-values.json")
        guard let data = try? Data(contentsOf: url) else { return }
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let entries = try #require(json["entries"] as? [String: Any])
        func value(_ key: String) -> Any? {
            let e = entries["house-contrast-v1/" + key]
            return (e as? [String: Any])?["value"] ?? e
        }
        let hc = try #require(BuildingGenerator.contrast)
        for name in ["chicago_three_flat", "chicago_two_flat", "workers_cottage", "chicago_bungalow"] {
            let t = try #require(hc.values(name))
            for (field, surface) in [("trim", t.trim), ("soffit", t.soffit), ("porch_shadow", t.porchShadow), ("window_glass_day", t.glass), ("roof", t.roof)] {
                let v = value("houseTypes.\(name).surfaces.\(field).hex") as? String
                #expect(v?.uppercased() == surface.uppercased(), "\(name) \(field): look \(surface) vs mock \(v ?? "nil")")
            }
            let e = value("houseTypes.\(name).surfaces.eave_shadow.relativeBrightness") as? Double
            #expect(e.map { abs($0 - t.eaveShadow) < 1e-6 } == true, "\(name) eave_shadow")
        }
    }
}
