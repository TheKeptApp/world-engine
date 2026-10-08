import Foundation
import CoreGraphics
import ImageIO
import RealityKit
import Metal
import Testing
import WorldGen
import WorldMesh
@testable import WorldEngine

/// foliage-exp1-spec.md Exact candidate math and R's 8 Oct corrected mask.
@MainActor
@Suite("Native foliage experiment 1", .serialized)
struct FoliageExperimentTests {
    static func eligible(_ paint: SIMD4<Float>, _ extra: SIMD4<Float>, leafCut: Bool = false) -> Bool {
        let slot = Int(paint.x + 0.5)
        return extra.y > 0 && extra.z < 0.5 && !leafCut && (Int(paint.z + 0.5) & 512) == 0 &&
            ((3...6).contains(slot) || (24...28).contains(slot))
    }
    @Test func arithmeticWitnesses() {
        for (a, wantedT, wantedAO, wantedM) in [(0.5,0.0,0.65,0.94), (0.65,0,0.65,0.94),
            (0.75,0.198251,0.719388,0.951895), (0.825,0.5,0.825,0.97),
            (0.9,0.801749,0.930612,0.988105), (1.0,1.0,1.0,1.0)] {
            let a0 = min(1.0, max(0.65, a)), x = (a0 - 0.65) / 0.35
            let t = x * x * (3 - 2 * x)
            #expect(abs(t - wantedT) < 0.0001)
            #expect(abs(0.65 + 0.35 * t - wantedAO) < 0.0001)
            #expect(abs(0.94 + 0.06 * t - wantedM) < 0.0001)
        }
    }
    static func palette() throws -> Palette {
        Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 1, base: try StyleLibrary.baseColors())
    }
    @Test func generatedControlsAreExcluded() throws {
        let palette = try Self.palette()
        #expect(SeasonalPalette.order.enumerated().filter { $0.element.hasPrefix("deciduous") }.map(\.offset) == [3,4,5,6,24,25,26,27,28])
        for kind in [PropKind.bush, .flowerBush, .conifer, .tuft, .lamp, .bench] {
            for lod in 0..<PropLibrary.lodCount(kind) {
                for variant in 0..<8 {
                    let mesh = PropLibrary.mesh(kind, variant: variant, lod: lod, palette: palette, style: .solid)
                    #expect(!mesh.isEmpty)
                    #expect(zip(mesh.paints, mesh.extras).allSatisfy { !Self.eligible($0.0, $0.1) }, "\(kind) LOD\(lod) variant\(variant)")
                }
            }
        }
        for kind in [PropKind.treeBroad, .treeOval, .treeSpreading, .treeWeeping] {
            for lod in 0..<3 {
                let mesh = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, style: .solid)
                #expect(zip(mesh.paints, mesh.extras).contains { Self.eligible($0.0, $0.1) })
                #expect(zip(mesh.paints, mesh.extras).allSatisfy { !Self.eligible($0.0, $0.1, leafCut: true) })
            }
            let skyline = PropLibrary.mesh(kind, variant: 0, lod: 3, palette: palette, style: .solid)
            #expect(zip(skyline.paints, skyline.extras).allSatisfy { !Self.eligible($0.0, $0.1) })
            let cards = PropLibrary.mesh(kind, variant: 0, lod: 0, palette: palette, style: .leafCards)
            #expect(zip(cards.paints, cards.extras).allSatisfy { !Self.eligible($0.0, $0.1) })
        }
    }

    /// Explicit opt-in: this GPU proof must use postcard_mac_check.sh, never a source-only library.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FOLIAGE_CONTROL_PHASE"] != nil))
    func nativeControlPixels() async throws {
        let env = ProcessInfo.processInfo.environment
        let phase = try #require(env["FOLIAGE_CONTROL_PHASE"])
        #expect(phase == "baseline" || phase == "candidate")
        #expect(RenderResources.shaderLibraryAvailable, "Compile the native Metal library first")
        let folder = URL(fileURLWithPath: try #require(env["FOLIAGE_CONTROL_OUT"]))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let palette = try Self.palette()
        for category in ["bush", "flower-bush", "conifer", "tuft", "bark", "skyline-crown", "leaf-cards"] {
            var meshes: [WorldMesh.MeshBuffers] = []
            let kinds: [PropKind] = category == "bush" ? [.bush] : category == "flower-bush" ? [.flowerBush] : category == "conifer" ? [.conifer] : category == "tuft" ? [.tuft] : []
            for kind in kinds {
                for lod in 0..<PropLibrary.lodCount(kind) {
                    meshes.append(PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, style: .solid))
                }
            }
            if category == "bark" {
                var bark = PropLibrary.mesh(.treeBroad, variant: 0, lod: 0, palette: palette, style: .solid)
                let indices = bark.indices
                bark.indices = stride(from: 0, to: indices.count, by: 3).flatMap { t -> [UInt32] in
                    let ids = Array(indices[t..<(t+3)])
                    return ids.allSatisfy { bark.extras[Int($0)].y == 0 } ? ids : []
                }
                meshes += [bark]
            }
            if category == "skyline-crown" { meshes = [PropLibrary.mesh(.treeBroad, variant: 0, lod: 3, palette: palette, style: .solid)] }
            if category == "leaf-cards" { meshes = [PropLibrary.mesh(.treeBroad, variant: 0, lod: 0, palette: palette, style: .leafCards)] }
            #expect(meshes.allSatisfy { !$0.isEmpty })
            for leaf in [Float(1), 0] {
                for mode in [env["FOLIAGE_EXP1_BUILD"] == "layered" ? 2 : env["FOLIAGE_EXP1_BUILD"] == "remove" ? 1 : 0] {
                    let resources = try RenderResources(palette: palette)
                    var globals = ShaderGlobals()
                    globals.windStrength = 0; globals.leafFraction = SIMD3(repeating: leaf)
                    globals.camera = [0, 5, 14]
                    resources.update(globals: globals)
                    let sync = try #require(resources.queue.makeCommandBuffer())
                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        sync.addCompletedHandler { _ in continuation.resume() }
                        sync.commit()
                    }
                    let root = Entity()
                    for (i, mesh) in meshes.enumerated() {
                        let model = Entity()
                        let uploaded = try MeshUpload.resource([mesh])
                        model.components.set(ModelComponent(mesh: try #require(uploaded), materials: [resources.foliageOpaqueMaterial]))
                        model.scale = SIMD3(repeating: 2)
                        model.position = [Float(i % 4) * 2.5 - 3.75, 0, Float(i / 4) * -2.5]
                        root.addChild(model)
                    }
                    let sun = Entity()
                    sun.components.set(DirectionalLightComponent(color: .white, intensity: 3000))
                    sun.look(at: .zero, from: [4,8,5], relativeTo: nil); root.addChild(sun)
                    let renderer = try OffscreenWorldRenderer(root: root, environment: nil, background: [0.12,0.14,0.16], post: nil)
                    var timing = PostcardTiming()
                    let image = try await renderer.render(pose: .init(eye: [0,5,14], target: [0,1,-1], verticalFOVDegrees: 50),
                        width: 512, height: 512, renderWidth: 512, renderHeight: 512, settleFrames: 8, grade: nil, timing: &timing)
                    let bytes = try Self.rgba(image)
                    let stem = "\(category)-leaf\(Int(leaf))"
                    let target = folder.appendingPathComponent("\(phase)-\(stem)-mode\(mode).png")
                    let dest = try #require(CGImageDestinationCreateWithURL(target as CFURL, "public.png" as CFString, 1, nil))
                    CGImageDestinationAddImage(dest, image, nil); #expect(CGImageDestinationFinalize(dest))
                    let baseline = folder.appendingPathComponent("baseline-\(stem).rgba")
                    if phase == "baseline" { try Data(bytes).write(to: baseline) }
                    else {
                        let before = [UInt8](try Data(contentsOf: baseline))
                        #expect(before.count == bytes.count)
                        let maximum = zip(before, bytes).map { abs(Int($0) - Int($1)) }.max() ?? 0
                        let mean = Double(zip(before, bytes).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }) / Double(bytes.count)
                        let different = zip(before, bytes).filter { $0 != $1 }.count
                        print("FOLIAGE_CONTROL category=\(category) leaf=\(leaf) mode=\(mode) maxDiff=\(maximum) meanAbsByte=\(mean) differingBytes=\(different)")
                        #expect(maximum <= (mode == 2 ? 2 : 0), "Final gate: non-mask maximum; remove/repeat must remain zero")
                        #expect(mean <= (mode == 2 ? 5e-4 : 0), "Final gate: mean absolute byte difference")
                    }
                    #expect(Set(bytes).count > 8, "Empty/flat frame is not control evidence")
                }
            }
        }
    }
    static func rgba(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let ok = bytes.withUnsafeMutableBytes { data -> Bool in
            guard let context = CGContext(data: data.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height)); return true
        }
        #expect(ok); return bytes
    }
}
