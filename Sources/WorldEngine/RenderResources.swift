import Foundation
import Metal
import RealityKit
import WorldGen

/// Scene-wide shader inputs written into the shared globals texture each frame.
public struct ShaderGlobals: Sendable, Equatable {
    /// Linear RGB.
    public var fogColor = SIMD3<Float>(0.8, 0.75, 0.7)
    public var fogStart: Float = 350
    public var fogEnd: Float = 1100
    /// Character center relative to the camera (world axes); nil disables the cut-away.
    public var characterRel: SIMD3<Float>?
    public var cutRadius: Float = 1.1
    public var wind: Float = 1
    /// Share of windows lit (dusk/night) and their color (sRGB).
    public var litFraction: Float = 0
    public var litWindow = SIMD3<Float>(0.91, 0.75, 0.49)
    /// Shader debug view (2 = cut-away decision, 3 = baked AO).
    public var debug: Float = 0
    /// Camera world position (fog distance and cut-away are measured from it).
    public var camera: SIMD3<Float> = .zero
    /// R8 hemispheric fill (linear RGB × strength).
    public var fillSky = SIMD3<Float>(0.15, 0.17, 0.2)
    public var fillGround = SIMD3<Float>(0.05, 0.045, 0.04)
    /// R8 contact: character ground point relative to the camera, footprint half extents
    /// (along/across heading), heading (radians), opacity and edge softness (m).
    public var contactRel: SIMD3<Float>?
    public var contactHalf = SIMD2<Float>(0.3, 0.7)
    public var contactHeading: Float = 0
    public var contactOpacity: Float = 0.18
    public var contactSoftness: Float = 0.12
    /// Weather hooks (stubs in M1): wetness and snow coverage 0–1.
    public var wetness: Float = 0
    public var snow: Float = 0
}

/// Metal library, the palette/globals texture and the shared world materials.
@MainActor
final class RenderResources {
    static let textureWidth = 256

    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    let texture: LowLevelTexture
    let textureResource: TextureResource
    private var staging: MTLBuffer
    private var paletteRow: [SIMD4<Float16>]
    private var lastGlobals: ShaderGlobals?
    private var paletteDirty = true

    let staticMaterial: CustomMaterial
    /// Same shader family as `staticMaterial`, but cut-away capable (lamps, benches).
    let propMaterial: CustomMaterial
    let foliageMaterial: CustomMaterial
    let waterMaterial: CustomMaterial

    init(palette: Palette) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw WorldError.metalUnavailable
        }
        self.device = device
        self.queue = queue
        library = try device.makeDefaultLibrary(bundle: .module)

        texture = try LowLevelTexture(descriptor: .init(
            pixelFormat: .rgba16Float, width: Self.textureWidth, height: 2, textureUsage: [.shaderRead]))
        textureResource = try TextureResource(from: texture)
        staging = device.makeBuffer(length: Self.textureWidth * 2 * 8, options: .storageModeShared)!
        paletteRow = []

        // RealityKit ignores shader opacity on opaque custom materials, so materials that must be
        // cut away (thin blockers: trees, bushes, lamps, benches) use the transparent pipeline at
        // full opacity with depth writes and an alpha threshold. Buildings stay opaque (the
        // camera pushes in instead).
        let lib = library, tex = textureResource
        func material(_ surface: String, geometry: String? = nil, cuttable: Bool) throws -> CustomMaterial {
            var m = try CustomMaterial(
                surfaceShader: .init(named: surface, in: lib),
                geometryModifier: geometry.map { .init(named: $0, in: lib) },
                lightingModel: .lit)
            m.custom.texture = .init(tex)
            m.faceCulling = .back
            if cuttable {
                m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
                m.opacityThreshold = 0.5
                m.writesDepth = true
            }
            return m
        }
        staticMaterial = try material("worldStaticSurface", cuttable: false)
        propMaterial = try material("worldPropSurface", cuttable: true)
        foliageMaterial = try material("worldFoliageSurface", geometry: "worldFoliageGeometry", cuttable: true)
        waterMaterial = try material("worldWaterSurface", cuttable: false)
        setPalette(palette)
        update(globals: ShaderGlobals())
    }

    /// Replaces the palette row (season changes rewrite colors without touching meshes).
    func setPalette(_ palette: Palette) {
        paletteRow = (0..<Self.textureWidth).map { i in
            let c = i < palette.colors.count ? palette.colors[i] : SIMD3<Float>(1, 0, 1)
            return SIMD4(Float16(c.x), Float16(c.y), Float16(c.z), 1)
        }
        paletteDirty = true
        lastGlobals = nil
    }

    /// Uploads the palette and globals (skipped when nothing changed).
    func update(globals g: ShaderGlobals) {
        guard g != lastGlobals || paletteDirty else { return }
        lastGlobals = g
        paletteDirty = false
        let w = Self.textureWidth
        let p = staging.contents().bindMemory(to: SIMD4<Float16>.self, capacity: w * 2)
        for i in 0..<w { p[i] = paletteRow[i] }
        for i in 0..<w { p[w + i] = .zero }
        func h(_ v: Float) -> Float16 { Float16(v) }
        p[w + 0] = SIMD4(h(g.fogColor.x), h(g.fogColor.y), h(g.fogColor.z), h(g.fogStart))
        p[w + 1] = SIMD4(h(g.fogEnd), h(g.cutRadius), g.characterRel == nil ? 0 : 1, h(g.debug))
        let c = g.characterRel ?? .zero
        p[w + 2] = SIMD4(h(c.x), h(c.y), h(c.z), 0)
        p[w + 3] = SIMD4(h(g.wind), h(g.litFraction), 0, 0)
        // Camera split so half floats keep millimeter precision across a few kilometers.
        let coarse = g.camera.rounded(.toNearestOrEven)
        let fine = g.camera - coarse
        p[w + 4] = SIMD4(h(coarse.x), h(coarse.y), h(coarse.z), 0)
        p[w + 5] = SIMD4(h(fine.x), h(fine.y), h(fine.z), 0)
        p[w + 6] = SIMD4(h(g.fillSky.x), h(g.fillSky.y), h(g.fillSky.z), 0)
        p[w + 7] = SIMD4(h(g.fillGround.x), h(g.fillGround.y), h(g.fillGround.z), 0)
        p[w + 8] = SIMD4(h(g.litWindow.x), h(g.litWindow.y), h(g.litWindow.z), 0)
        p[w + 9] = SIMD4(h(g.contactHalf.x), h(g.contactHalf.y), h(g.contactHeading), h(g.contactSoftness))
        let cr = g.contactRel ?? .zero
        p[w + 10] = SIMD4(h(cr.x), h(cr.y), h(cr.z), g.contactRel == nil ? 0 : h(g.contactOpacity))
        p[w + 11] = SIMD4(h(g.wetness), h(g.snow), 0, 0)

        guard let cb = queue.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder() else { return }
        let target = texture.replace(using: cb)
        blit.copy(from: staging, sourceOffset: 0, sourceBytesPerRow: w * 8, sourceBytesPerImage: w * 2 * 8,
                  sourceSize: MTLSize(width: w, height: 2, depth: 1),
                  to: target, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin())
        blit.endEncoding()
        cb.commit()
    }
}

public enum WorldError: Error {
    case metalUnavailable
    case meshTooLarge
}
