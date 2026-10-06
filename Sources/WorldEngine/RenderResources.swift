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
    /// Surface weather: exposed wetness 0–1 and snow coverage of eligible surfaces 0–1
    /// (weather v1 §4: coverage = 1 − exp(−S/6)).
    public var wetness: Float = 0
    public var snow: Float = 0
    /// Wet response (weather.json): albedo darkening at full wetness and wet roughness.
    public var wetDarkening: Float = 0.12
    public var wetRoughness: Float = 0.5
    /// R10 wind: transport direction (scene x, z, unit), strength min(U/12, 1), sway frequency Hz,
    /// and a foliage factor (0.7 when wet or cold).
    public var windDirection = SIMD2<Float>(0, 1)
    public var windStrength: Float = 0.3
    public var swayFrequency: Float = 0.12
    public var foliageSwayFactor: Float = 1
    /// Deciduous leaf fraction now and for trees running 7 days ahead / behind (per-tree offsets
    /// interpolate between them, sky-seasons §5.3).
    public var leafFraction = SIMD3<Float>(1, 1, 1)
    /// Snow surface color (linear).
    public var snowColor = SIMD3<Float>(0.80, 0.84, 0.87)
    /// Sky dome: zenith and horizon (linear), sun direction, sun disk color (linear, 0 = none),
    /// cloud cover 0–1 and cloud color (linear), moon direction, disk radius (radians), disk
    /// opacity, and the Moon→Sun light direction, star strength.
    public var skyTop = SIMD3<Float>(0.35, 0.5, 0.75)
    public var skyHorizon = SIMD3<Float>(0.75, 0.75, 0.75)
    public var sunDirection = SIMD3<Float>(0, 1, 0)
    public var sunDisk = SIMD3<Float>(0, 0, 0)
    public var cloudCover: Float = 0
    /// Noise threshold that yields `cloudCover` of the dome (set with the cover).
    public var cloudThreshold: Float = 1
    public var cloudColor = SIMD3<Float>(0.8, 0.8, 0.8)
    public var moonDirection = SIMD3<Float>(0, -1, 0)
    public var moonRadius: Float = 0.0072
    public var moonOpacity: Float = 0
    public var moonLight = SIMD3<Float>(0, 1, 0)
    public var moonColor = SIMD3<Float>(0.85, 0.85, 0.82)
    public var starStrength: Float = 0
    /// Fallen leaves under deciduous crowns (0–1, from leaf drop) and their colours (linear).
    public var leafLitter: Float = 0
    public var litterColorA = SIMD3<Float>(0.45, 0.25, 0.08)
    public var litterColorB = SIMD3<Float>(0.55, 0.38, 0.12)
    /// Canopy map placement: scene x, z of its minimum corner and its size (metres).
    public var canopyOrigin = SIMD2<Float>(0, 0)
    public var canopySize = SIMD2<Float>(1, 1)
    /// Lighting bible §2.3 clear-air fade: colour (linear), cap (share at long range), start and
    /// the distance where it reaches half the cap (m). Weather extinction (§3.2) uses
    /// `fogStart`/`fogEnd` (90% of contrast gone at the end) at strength `fogWeight` (0 = none).
    public var airColor = SIMD3<Float>(0.33, 0.48, 0.69)
    public var airCap: Float = 0.35
    public var airStart: Float = 300
    public var airD50: Float = 1800
    public var fogWeight: Float = 0
}

/// Metal library, the palette/globals texture and the shared world materials.
@MainActor
final class RenderResources {
    static let textureWidth = 256
    /// Rows: 0 palette, 1 globals, 2 palette for trees ahead (+7 d), 3 behind (−7 d).
    static let textureHeight = 4

    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    let texture: LowLevelTexture
    let textureResource: TextureResource
    private var staging: MTLBuffer
    private var paletteRow: [SIMD4<Float16>]
    /// Palette rows for trees running 7 days ahead and behind the season (rows 2 and 3).
    private var paletteAhead: [SIMD4<Float16>] = []
    private var paletteBehind: [SIMD4<Float16>] = []
    private var lastGlobals: ShaderGlobals?
    private var paletteDirty = true

    /// Static surfaces (buildings, ground); its base-colour slot carries the canopy map.
    var staticMaterial: CustomMaterial
    /// Same shader family as `staticMaterial`, but cut-away capable (lamps, benches).
    let propMaterial: CustomMaterial
    let foliageMaterial: CustomMaterial
    /// Opaque variants for detail that can't stand between the camera and the character (trees
    /// and bushes beyond the cut-away zone). The cut-away's transparent pipeline costs the GPU its
    /// hidden-surface removal, so every overlapping lobe was shaded; opaque lobes are shaded once.
    let propOpaqueMaterial: CustomMaterial
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
            pixelFormat: .rgba16Float, width: Self.textureWidth, height: Self.textureHeight, textureUsage: [.shaderRead]))
        textureResource = try TextureResource(from: texture)
        staging = device.makeBuffer(length: Self.textureWidth * Self.textureHeight * 8, options: .storageModeShared)!
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
        propOpaqueMaterial = try material("worldPropSurface", cuttable: false)
        foliageOpaqueMaterial = try material("worldFoliageSurface", geometry: "worldFoliageGeometry", cuttable: false)
        waterMaterial = try material("worldWaterSurface", cuttable: false)
        setPalette(palette)
        update(globals: ShaderGlobals())
    }

    /// Replaces the palette row (season changes rewrite colors without touching meshes). Trees
    /// ahead/behind get their own rows; without them they match the main row.
    func setPalette(_ palette: Palette, ahead: Palette? = nil, behind: Palette? = nil) {
        func row(_ p: Palette) -> [SIMD4<Float16>] {
            (0..<Self.textureWidth).map { i in
                let c = i < p.colors.count ? p.colors[i] : SIMD3<Float>(1, 0, 1)
                return SIMD4(Float16(c.x), Float16(c.y), Float16(c.z), 1)
            }
        }
        paletteRow = row(palette)
        paletteAhead = ahead.map(row) ?? paletteRow
        paletteBehind = behind.map(row) ?? paletteRow
        paletteDirty = true
        lastGlobals = nil
    }

    /// Uploads the palette and globals (skipped when nothing changed).
    func update(globals g: ShaderGlobals) {
        guard g != lastGlobals || paletteDirty else { return }
        lastGlobals = g
        paletteDirty = false
        let w = Self.textureWidth
        let p = staging.contents().bindMemory(to: SIMD4<Float16>.self, capacity: w * Self.textureHeight)
        for i in 0..<w { p[i] = paletteRow[i] }
        for i in 0..<w { p[w + i] = .zero }
        for i in 0..<w { p[2 * w + i] = paletteAhead.isEmpty ? paletteRow[i] : paletteAhead[i] }
        for i in 0..<w { p[3 * w + i] = paletteBehind.isEmpty ? paletteRow[i] : paletteBehind[i] }
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
        p[w + 11] = SIMD4(h(g.wetness), h(g.snow), h(g.wetDarkening), h(g.wetRoughness))
        p[w + 12] = SIMD4(h(g.windDirection.x), h(g.windDirection.y), h(g.windStrength), h(g.swayFrequency))
        p[w + 13] = SIMD4(h(g.leafFraction.x), h(g.leafFraction.y), h(g.leafFraction.z), h(g.foliageSwayFactor))
        p[w + 14] = SIMD4(h(g.snowColor.x), h(g.snowColor.y), h(g.snowColor.z), h(g.starStrength))
        p[w + 15] = SIMD4(h(g.skyTop.x), h(g.skyTop.y), h(g.skyTop.z), h(g.cloudCover))
        p[w + 16] = SIMD4(h(g.skyHorizon.x), h(g.skyHorizon.y), h(g.skyHorizon.z), h(g.cloudThreshold))
        p[w + 17] = SIMD4(h(g.sunDirection.x), h(g.sunDirection.y), h(g.sunDirection.z), 0)
        p[w + 18] = SIMD4(h(g.sunDisk.x), h(g.sunDisk.y), h(g.sunDisk.z), 0)
        p[w + 19] = SIMD4(h(g.cloudColor.x), h(g.cloudColor.y), h(g.cloudColor.z), 0)
        p[w + 20] = SIMD4(h(g.moonDirection.x), h(g.moonDirection.y), h(g.moonDirection.z), h(g.moonRadius * 100))
        p[w + 21] = SIMD4(h(g.moonLight.x), h(g.moonLight.y), h(g.moonLight.z), h(g.moonOpacity))
        p[w + 22] = SIMD4(h(g.moonColor.x), h(g.moonColor.y), h(g.moonColor.z), 0)
        p[w + 23] = SIMD4(h(g.litterColorA.x), h(g.litterColorA.y), h(g.litterColorA.z), h(g.leafLitter))
        p[w + 24] = SIMD4(h(g.litterColorB.x), h(g.litterColorB.y), h(g.litterColorB.z), 0)
        // Canopy origin/size as coarse + fine halves (kilometres need more than half precision).
        let co = g.canopyOrigin.rounded(.toNearestOrEven), cs = g.canopySize.rounded(.toNearestOrEven)
        p[w + 25] = SIMD4(h(co.x), h(co.y), h(g.canopyOrigin.x - co.x), h(g.canopyOrigin.y - co.y))
        p[w + 26] = SIMD4(h(cs.x), h(cs.y), h(g.canopySize.x - cs.x), h(g.canopySize.y - cs.y))
        p[w + 27] = SIMD4(h(g.airColor.x), h(g.airColor.y), h(g.airColor.z), h(g.airCap))
        p[w + 28] = SIMD4(h(g.airStart), h(g.airD50), h(g.fogWeight), 0)

        guard let cb = queue.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder() else { return }
        let target = texture.replace(using: cb)
        blit.copy(from: staging, sourceOffset: 0, sourceBytesPerRow: w * 8, sourceBytesPerImage: w * Self.textureHeight * 8,
                  sourceSize: MTLSize(width: w, height: Self.textureHeight, depth: 1),
                  to: target, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin())
        blit.endEncoding()
        cb.commit()
    }
}

public enum WorldError: Error {
    case metalUnavailable
    case meshTooLarge
}
