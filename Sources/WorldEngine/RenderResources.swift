import Foundation
import Metal
import RealityKit
import WorldGen

/// Scene-wide shader inputs written into the shared globals texture each frame.
public struct ShaderGlobals: Sendable, Equatable {
    /// Linear RGB.
    public var fogColor = SIMD3<Float>(0.9, 0.8, 0.7)
    /// Exponential fog density per meter.
    public var fogDensity: Float = 0.0018
    /// Distance before fog starts (m).
    public var fogStart: Float = 60
    /// Character position relative to the camera (world axes); nil disables the cut-away.
    public var characterView: SIMD3<Float>?
    public var cutRadius: Float = 1.1
    public var wind: Float = 1
    public var night: Float = 0
    /// Shader debug view (1 = cut-away geometry as colors).
    public var debug: Float = 0
    /// Camera world position (fog distance and cut-away are measured from it).
    public var camera: SIMD3<Float> = .zero
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

    let staticMaterial: CustomMaterial
    /// Same shader as `staticMaterial`, but drawn so the cut-away can remove pixels (lamps, benches).
    let propMaterial: CustomMaterial
    let foliageMaterial: CustomMaterial
    /// Foliage without cut-away support (opaque pipeline), for performance comparison.
    let foliageOpaqueMaterial: CustomMaterial
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

        paletteRow = (0..<Self.textureWidth).map { i in
            let c = i < palette.colors.count ? palette.colors[i] : SIMD3<Float>(1, 0, 1)
            return SIMD4(Float16(c.x), Float16(c.y), Float16(c.z), 1)
        }

        let lib = library, tex = textureResource
        // RealityKit ignores shader opacity on opaque custom materials, so materials that must be
        // cut away (thin blockers: trees, bushes, lamps, benches) use the transparent pipeline at
        // full opacity with depth writes on and an alpha threshold. They look the same; the
        // shader's cut-away can then discard pixels. Buildings stay opaque (the camera pushes in).
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
        propMaterial = try material("worldStaticSurface", cuttable: true)
        foliageMaterial = try material("worldFoliageSurface", geometry: "worldFoliageGeometry", cuttable: true)
        foliageOpaqueMaterial = try material("worldFoliageSurface", geometry: "worldFoliageGeometry", cuttable: false)
        waterMaterial = try material("worldWaterSurface", cuttable: false)
        update(globals: ShaderGlobals())
    }

    /// Uploads the palette and globals (skipped when nothing changed).
    func update(globals g: ShaderGlobals) {
        guard g != lastGlobals else { return }
        lastGlobals = g
        let w = Self.textureWidth
        let p = staging.contents().bindMemory(to: SIMD4<Float16>.self, capacity: w * 2)
        for i in 0..<w { p[i] = paletteRow[i] }
        for i in 0..<w { p[w + i] = .zero }
        p[w + 0] = SIMD4(Float16(g.fogColor.x), Float16(g.fogColor.y), Float16(g.fogColor.z), Float16(g.fogDensity))
        p[w + 1] = SIMD4(Float16(g.fogStart), 0, Float16(g.cutRadius), g.characterView == nil ? 0 : 1)
        let c = g.characterView ?? .zero
        p[w + 2] = SIMD4(Float16(c.x), Float16(c.y), Float16(c.z), 0)
        p[w + 3] = SIMD4(Float16(g.wind), Float16(g.night), Float16(g.debug), 0)
        // Split so half floats keep millimeter precision across a few kilometers.
        let coarse = g.camera.rounded(.toNearestOrEven)
        let fine = g.camera - coarse
        p[w + 4] = SIMD4(Float16(coarse.x), Float16(coarse.y), Float16(coarse.z), 0)
        p[w + 5] = SIMD4(Float16(fine.x), Float16(fine.y), Float16(fine.z), 0)

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
