import CoreGraphics
import Foundation
import RealityKit
import WorldEnvironment
import WorldGen
import WorldGeo

/// Runtime environment bookkeeping kept by the world.
struct EnvironmentRuntime {
    var seasonal = try? StyleLibrary.seasonalPalette()
    /// Light used for the last image-based-light update (sun elevation, exposure) and when.
    var lastIBL: (elevation: Double, exposure: Float, cloud: Float, time: Date)?
    var iblTask: Task<Void, Never>?
    var precipitation = ""
}

/// Section C: the resolved environment on screen. `apply(_:)` maps one `EnvironmentDocument`
/// (renderer-neutral, from WorldEnvironment) onto the sun, shadows, fog, fill, sky dome, Moon,
/// stars, seasonal palette, leaves, wetness, snow, wind and precipitation. Nothing is rebuilt;
/// it is cheap enough to call on every time-scrubber change.
extension World {
    /// Sky dome radius (inside the 5 km far plane, outside the world).
    static let skyRadius: Float = 4500
    static let starDistance: Float = 4400
    /// Moon display scale: 1.5× the physical diameter (sky-seasons §3.2 postcard option).
    public static let moonDisplayScale = 1.5

    public func apply(_ env: EnvironmentDocument) {
        environment = env
        let L = env.light.timeOfDay
        let w = env.light.weather
        let tint = SIMD3<Float>(Float(w.tintLinear.x), Float(w.tintLinear.y), Float(w.tintLinear.z))
        let tw = Float(w.tintWeight)
        func tinted(_ c: SIMD3<Float>) -> SIMD3<Float> { c + (tint - c) * tw }
        func lin(_ c: SIMD3<Float>) -> SIMD3<Float> { WorldGen.Color.linear(c) }
        let elevation = env.light.sunElevationDeg

        // Sun: time-of-day colour and intensity × direct strength (weather, cloud, 0–2° fade-in).
        let direct = Float(env.light.directStrength)
        var light = sunEntity.components[DirectionalLightComponent.self] ?? DirectionalLightComponent()
        let sc = WorldGen.Color.srgb(simd_normalize(L.sunColor + 1e-6))
        light.color = .init(red: CGFloat(sc.x), green: CGFloat(sc.y), blue: CGFloat(sc.z), alpha: 1)
        light.intensity = L.sunIntensity * direct * L.exposure * Self.sunLux
        sunEntity.components.set(light)
        if !options.diagnostics.contains("noShadows"), L.sunIntensity * direct > 0.01 {
            if !sunEntity.components.has(DirectionalLightComponent.Shadow.self) {
                var shadow = DirectionalLightComponent.Shadow()
                shadow.shadowProjection = .automatic(maximumDistance: 80)
                shadow.depthBias = 1.5
                sunEntity.components.set(shadow)
            }
        } else {
            sunEntity.components.remove(DirectionalLightComponent.Shadow.self)
        }
        let dir = SIMD3<Float>(Float(env.light.sunDirection.x), Float(env.light.sunDirection.y), Float(env.light.sunDirection.z))
        sunEntity.look(at: .zero, from: dir.y > 0.02 ? dir * 100 : [dir.x * 100, 2, dir.z * 100], relativeTo: nil)

        // Fog, fill and windows.
        var g = shaderGlobals
        g.fogColor = tinted(lin(L.fog))
        g.fogStart = Float(w.fogStartM)
        g.fogEnd = Float(w.fogEndM)
        g.fillSky = tinted(lin(L.ambientSky)) * Float(env.light.fillSky) * Self.fillScale * L.exposure
        g.fillGround = lin(L.ambientGround) * Float(env.light.fillGround) * Self.fillScale * L.exposure
        g.litFraction = L.litWindows
        g.litWindow = Palette.parse(elevation < -6 ? "#DCA967" : "#E9BE7C")

        // Surfaces: wetness and snow come from the accumulation model (decision 5), never the label.
        g.wetness = Float(env.state.wetness01 ?? 0)
        g.snow = Float(env.state.snowCover01 ?? 0)
        g.wetDarkening = Float(env.presentation.wetDarkeningMax)
        g.wetRoughness = Float(env.presentation.wetRoughness)

        // Wind (R10): direction of air transport, strength min(U/12, 1), frequency from the model.
        let v = SIMD2<Float>(Float(w.windVector.x), Float(w.windVector.z))
        let u = simd_length(v)
        g.windDirection = u > 0.01 ? v / u : SIMD2(0, 1)
        g.windStrength = min(u / 12, 1)
        g.swayFrequency = Float(env.state.wind.swayFrequencyHz)
        g.foliageSwayFactor = (g.wetness > 0.3 || g.snow > 0.05) ? 0.7 : 1

        // Sky: gradient (weather-tinted), clouds by cover, sun disk, Moon disk lit by its phase.
        let cloud = Float(env.state.cloudCover01 ?? 0)
        let daylight = Float(smoothstepD(-6, 6, elevation))
        let horizon = tinted(lin(L.skyHorizon))
        let cloudColor = tinted(simd_mix(lin(L.skyHorizon), lin(L.ambientSky), SIMD3(repeating: 0.25))) * (1.04 - 0.3 * cloud)
        g.skyHorizon = horizon
        g.skyTop = simd_mix(tinted(lin(L.skyTop)), cloudColor, SIMD3(repeating: 0.5 * cloud))
        g.cloudCover = cloud
        g.cloudColor = cloudColor
        g.sunDirection = dir
        g.sunDisk = elevation > -1.5 ? lin(sc) * 1.2 * Float(smoothstepD(-1.5, 1.0, elevation)) : .zero
        let moon = env.sky.moon
        g.moonDirection = SIMD3<Float>(Float(moon.direction.x), Float(moon.direction.y), Float(moon.direction.z))
        g.moonRadius = Float(moon.angularDiameterDeg * Self.moonDisplayScale / 2 * .pi / 180)
        g.moonOpacity = Float(env.light.moonDiskOpacity)
        g.moonLight = SIMD3<Float>(Float(moon.sunDirectionFromMoon.x), Float(moon.sunDirectionFromMoon.y), Float(moon.sunDirectionFromMoon.z))
        g.moonColor = SIMD3<Float>(0.86, 0.86, 0.82) * (0.55 + 0.45 * (1 - daylight))
        g.starStrength = Float(env.light.starStrength)

        // Season: continuous palettes and leaf fractions now and for trees ±7 days.
        if let phen = env.phenology, let profile = Self.phenologyProfiles.first(where: { $0.id == phen.profileID }) {
            let ahead = Phenology.resolve(dayOfYear: phen.dayOfYear + Phenology.treeShiftDays, profile: profile)
            let behind = Phenology.resolve(dayOfYear: phen.dayOfYear - Phenology.treeShiftDays, profile: profile)
            func palette(_ p: PhenologyState) -> Palette {
                scene.palette.blendingSeasons { key in
                    if key == "snow" { return nil }
                    let w = key.hasPrefix("deciduous") || key == "bushes" ? p.deciduous.paletteWeights : p.grass.paletteWeights
                    return SIMD4(w.spring, w.summer, w.autumn, w.winter)
                }
            }
            resources.setPalette(palette(phen), ahead: palette(ahead), behind: palette(behind))
            g.leafFraction = SIMD3(Float(phen.deciduous.leafFraction), Float(ahead.deciduous.leafFraction), Float(behind.deciduous.leafFraction))
        }
        shaderGlobals = g
        resources.update(globals: g)

        ensureSky()
        updateStars(env.sky.stars)
        updatePrecipitation(env.presentation.particles, wind: w.windVector)
        updateImageBasedLight(L, elevation: elevation, cloud: cloud)
    }

    static let phenologyProfiles: [PhenologyProfile] = [.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo]

    // MARK: - Sky dome and stars

    private func ensureSky() {
        guard skyDome == nil else { return }
        let lib = resources.library, tex = resources.textureResource
        do {
            var sky = try CustomMaterial(surfaceShader: .init(named: "worldSkySurface", in: lib), lightingModel: .lit)
            sky.custom.texture = .init(tex)
            sky.faceCulling = .none
            let dome = Entity()
            dome.name = "Sky dome"
            dome.components.set(ModelComponent(mesh: .generateSphere(radius: Self.skyRadius), materials: [sky]))
            dome.components.set(DynamicLightShadowComponent(castsShadow: false))
            rootEntity.addChild(dome)
            skyDome = dome

            var star = try CustomMaterial(surfaceShader: .init(named: "worldStarSurface", in: lib), lightingModel: .lit)
            star.custom.texture = .init(tex)
            star.faceCulling = .none
            star.blending = .transparent(opacity: .init(floatLiteral: 1))
            star.writesDepth = false
            let quad = MeshResource.generatePlane(width: 1, height: 1)
            let data = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: Stars.maxVisible)
            let field = Entity()
            field.name = "Stars"
            field.components.set(ModelComponent(mesh: quad, materials: [star]))
            field.components.set(DynamicLightShadowComponent(castsShadow: false))
            field.isEnabled = false
            rootEntity.addChild(field)
            starField = (field, data)
        } catch {
            print("WorldEngine: sky materials failed: \(error)")
        }
    }

    /// Star quads at their real directions (≤ 128), facing the dome centre (= the camera), sized by
    /// brightness. Rebuilt only when the visible set changes.
    private func updateStars(_ field: StarField) {
        guard let (entity, data) = starField else { return }
        let visible = field.strength > 0.001 ? field.visible : []
        entity.isEnabled = !visible.isEmpty
        guard !visible.isEmpty else { return }
        data.instanceCount = visible.count
        data.withMutableTransforms { out in
            for (i, s) in visible.enumerated() {
                let d = simd_normalize(SIMD3<Float>(Float(s.direction.x), Float(s.direction.y), Float(s.direction.z)))
                // Quad faces −d (toward the centre): rotate +Z onto −d.
                let rot = simd_quatf(from: SIMD3(0, 0, 1), to: -d)
                let size = Float(4 + 8 * s.brightness)
                var m = simd_float4x4(rot) * simd_float4x4(diagonal: SIMD4(size, size, size, 1))
                m.columns.3 = SIMD4(d * Self.starDistance, 1)
                out[i] = m
            }
        }
        if let mesh = entity.components[ModelComponent.self]?.mesh,
           let comp = try? MeshInstancesComponent(mesh: mesh, instances: data,
                                                  bounds: BoundingBox(min: SIMD3(repeating: -Self.skyRadius), max: SIMD3(repeating: Self.skyRadius))) {
            entity.components.set(comp)
        }
    }

    /// Keeps the dome, stars and precipitation centred on the camera (they live at infinity / in
    /// a camera-local box).
    func followCamera(_ camera: SIMD3<Float>, dt: Double) {
        skyDome?.position = camera
        starField?.entity.position = camera
        precipitation?.position = camera + SIMD3(0, 6, 0)
    }

    // MARK: - Precipitation

    /// Camera-local rain streaks or snowflakes (weather v1 §6): ~30 × 20 × 30 m box, counts from
    /// the particle budget (rain ≤ 600, snow ≤ 300), rain 12 m/s, snow 1.2 m/s, drift with the wind.
    private func updatePrecipitation(_ budget: ParticleBudget, wind: SIMD3<Double>) {
        let kind = budget.rain >= budget.snow ? (budget.rain > 0 ? "rain" : "") : "snow"
        let count = kind == "rain" ? budget.rain : budget.snow
        guard !kind.isEmpty, count > 0 else {
            precipitation?.isEnabled = false
            environmentState.precipitation = ""
            return
        }
        let entity = precipitation ?? {
            let e = Entity()
            e.name = "Precipitation"
            rootEntity.addChild(e)
            precipitation = e
            return e
        }()
        entity.isEnabled = true
        var p = entity.components[ParticleEmitterComponent.self] ?? ParticleEmitterComponent()
        p.emitterShape = .box
        p.birthLocation = .volume
        p.emitterShapeSize = SIMD3(30, 20, 30)
        p.fieldSimulationSpace = .global
        p.isEmitting = true
        let drift = SIMD3<Float>(Float(wind.x), 0, Float(wind.z))
        var e = p.mainEmitter
        if kind == "rain" {
            let fall: Float = 12
            let side = simd_length(drift) > 0 ? simd_normalize(drift) * min(2, 0.2 * simd_length(drift)) : .zero
            p.emissionDirection = simd_normalize(SIMD3(side.x, -fall, side.z))
            p.speed = fall
            e.lifeSpan = 1.6
            e.size = 0.012
            e.stretchFactor = 6
            e.billboardMode = .billboardYAligned
            e.color = .constant(.single(.init(red: 0.78, green: 0.82, blue: 0.86, alpha: 0.32)))
        } else {
            let fall: Float = 1.2
            let side = simd_length(drift) > 0 ? simd_normalize(drift) * min(3, 0.35 * simd_length(drift)) : .zero
            p.emissionDirection = simd_normalize(SIMD3(side.x, -fall, side.z))
            p.speed = simd_length(SIMD3(side.x, fall, side.z))
            e.lifeSpan = 12
            e.size = 0.035
            e.stretchFactor = 0
            e.billboardMode = .billboard
            e.noiseStrength = 0.15
            e.color = .constant(.single(.init(red: 0.95, green: 0.96, blue: 0.98, alpha: 0.85)))
        }
        e.birthRate = Float(count) / Float(e.lifeSpan)
        e.blendMode = .alpha
        e.opacityCurve = .quickFadeInOut
        e.isLightingEnabled = false
        p.mainEmitter = e
        entity.components.set(p)
        environmentState.precipitation = kind
    }

    // MARK: - Image-based light

    /// The sky light (speculars and a touch of sky colour) follows the time of day. Regenerating
    /// the environment is slow, so it updates only when the sun has moved ≥ 2°, exposure or
    /// cloud changed noticeably, at most every 2 s, off the frame loop.
    private func updateImageBasedLight(_ L: LightingState, elevation: Double, cloud: Float) {
        if let last = environmentState.lastIBL, abs(last.elevation - elevation) < 2, abs(last.exposure - L.exposure) < 0.1,
           abs(last.cloud - cloud) < 0.15 { return }
        if let last = environmentState.lastIBL, Date().timeIntervalSince(last.time) < 2 { return }
        environmentState.lastIBL = (elevation, L.exposure, cloud, Date())
        environmentState.iblTask?.cancel()
        let light = L
        environmentState.iblTask = Task { @MainActor [weak self] in
            let pixels = await Task.detached(priority: .utility) { SkyImage.render(light, width: 512, height: 256, convention: .realityKit) }.value
            guard !Task.isCancelled, let self, let image = World.cgImage(pixels, width: 512, height: 256),
                  let env = try? await EnvironmentResource(equirectangular: image) else { return }
            self.skyEnvironment = env
            self.iblEntity.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: -1.2 + log2(max(0.05, light.exposure))))
        }
    }
}
