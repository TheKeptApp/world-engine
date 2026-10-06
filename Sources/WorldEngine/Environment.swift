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
    /// Extra exposure at full sun cover (×(1 + gain)), and extra sky fill (see `apply`).
    static let weatherExposureGain: Float = 1.1
    static let weatherSkyFillGain: Float = 1.2
    /// Low clear sun: key ×(1 + gain) and fill ×(1 − cut) at ≤ 4° elevation, fading out by 25°.
    static let lowSunKeyGain: Float = 0.8
    static let lowSunFillCut: Float = 0.12
    static let starDistance: Float = 4400
    /// Moon display scale: 1.5× the physical diameter (sky-seasons §3.2 postcard option).
    public static let moonDisplayScale = 1.5

    public func apply(_ env: EnvironmentDocument) {
        environment = env
        logEvent("apply")
        let w = env.light.weather
        // Exposure compensation, like a camera's auto exposure: weather that hides the sun (cloud,
        // rain, fog, smoke) otherwise leaves the frame dark and dull, but the targets are as bright
        // as clear days (experience-v1 02 overcast, 05 fog: mean luma ~150 vs ~141 golden). The
        // diffuse sky also becomes the main light source, so sky fill grows as the sun is hidden.
        // Daytime only: night keeps its own key.
        var L = env.light.timeOfDay
        let hidden = Float(max(0, 1 - env.light.directStrength))
        let dayWeight = Float(smoothstepD(-2, 8, env.light.sunElevationDeg))
        L.exposure *= 1 + dayWeight * Self.weatherExposureGain * pow(hidden, 1.2)
        let skyFillGain = 1 + dayWeight * Self.weatherSkyFillGain * hidden
        // Auto exposure aims lower at night (experience-v1 09: mean luma ~65 vs ~135 by day), and by
        // day leans with the weather the way the concepts do: fog and snow bright (155-164), overcast
        // a little bright (148), rain a little and storms clearly darker (131, 107).
        let state = env.state.dominantState
        let weight = Float(min(1, max(0, env.state.intensity01 ?? (state == .cloudy ? Double(env.state.cloudCover01 ?? 0) : 0))))
        let bias: Float = switch state {
        case .fog: 0.07
        case .snow: 0.08
        case .cloudy: 0.04
        case .smoke, .haze, .dust: 0.02
        case .rain: -0.02
        case .thunderstorm: -0.12
        default: 0
        }
        exposureTarget = 0.28 + (0.26 + bias * weight) * Float(smoothstepD(-8, 4, env.light.sunElevationDeg))
        // Low clear sun (golden hour, early morning): at 6° the sun puts only ~10% of its light on
        // flat ground, so the sky fill washes its shadows out. A stronger key and less fill keep
        // the warm light and the long shadows readable (art direction: warm light that picks out
        // materials; P3 look loop: "no golden-hour key light"). The sun direction stays true.
        let lowSun = Float(1 - smoothstepD(4, 25, env.light.sunElevationDeg)) * Float(smoothstepD(0, 2, env.light.sunElevationDeg)) * (1 - hidden)
        L.sunIntensity *= 1 + Self.lowSunKeyGain * lowSun
        let lowSunFill = 1 - Self.lowSunFillCut * lowSun
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
                shadow.shadowProjection = .automatic(maximumDistance: shadowDistance)
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
        g.fillSky = tinted(lin(L.ambientSky)) * Float(env.light.fillSky) * Self.fillScale * L.exposure * skyFillGain * lowSunFill
        g.fillGround = lin(L.ambientGround) * Float(env.light.fillGround) * Self.fillScale * L.exposure * lowSunFill
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
        let label = env.state.dominantState
        let intensity = Float(env.state.intensity01 ?? 0)
        let wetSky: Float = (label == .rain || label == .thunderstorm) ? 0.25 + 0.35 * min(1, intensity * 2) : 0
        let cloudColor = tinted(simd_mix(lin(L.skyHorizon), lin(L.ambientSky), SIMD3(repeating: 0.25))) * (1.04 - 0.3 * cloud) * (1 - wetSky)
        // Fog, haze, smoke and dust veil the sky itself, not just the distance: dense fog closes to
        // a uniform pale grey (experience-v1 05: "uniform pale gray horizon", no sun disk), smoke
        // to a flat beige-grey (06). The veil leans toward the obscurant's own colour.
        let obscured = label?.isObscuration ?? false
        let veil: Float = obscured ? (label == .fog ? 0.95 : 0.75) * intensity : 0
        let veilColor = label == .fog ? g.fogColor : simd_mix(g.fogColor, tint, SIMD3(repeating: 0.6))
        g.skyHorizon = simd_mix(horizon, veilColor, SIMD3(repeating: veil))
        g.skyTop = simd_mix(simd_mix(tinted(lin(L.skyTop)), cloudColor, SIMD3(repeating: 0.5 * cloud)), veilColor, SIMD3(repeating: veil * 0.9))
        if veil > 0, label != .fog { g.fogColor = simd_mix(g.fogColor, veilColor, SIMD3(repeating: veil * 0.6)) }
        g.cloudCover = cloud
        g.cloudThreshold = Self.cloudThreshold(cover: cloud)
        g.cloudColor = simd_mix(cloudColor, veilColor, SIMD3(repeating: veil))
        g.sunDirection = dir
        g.sunDisk = elevation > -1.5 ? lin(sc) * 1.2 * Float(smoothstepD(-1.5, 1.0, elevation)) * (1 - veil) : .zero
        let moon = env.sky.moon
        g.moonDirection = SIMD3<Float>(Float(moon.direction.x), Float(moon.direction.y), Float(moon.direction.z))
        g.moonRadius = Float(moon.angularDiameterDeg * Self.moonDisplayScale / 2 * .pi / 180)
        g.moonOpacity = Float(env.light.moonDiskOpacity) * (1 - veil)
        g.moonLight = SIMD3<Float>(Float(moon.sunDirectionFromMoon.x), Float(moon.sunDirectionFromMoon.y), Float(moon.sunDirectionFromMoon.z))
        g.moonColor = SIMD3<Float>(0.86, 0.86, 0.82) * (0.55 + 0.45 * (1 - daylight))
        g.starStrength = Float(env.light.starStrength) * (1 - veil)

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
            // Leaf litter: a little as colour turns, most once leaves drop, cleared/decayed about
            // a month after the drop ends (until then it stays, wet or dry; snow covers it).
            let dec = phen.deciduous
            let fade = 1 - smoothstepD(profile.dropEnd + 20, profile.dropEnd + 55, phen.dayOfYear)
            g.leafLitter = Float(max(dec.drop, 0.25 * dec.color * dec.greenUp) * fade)
            if let s = environmentState.seasonal {
                func fallen(_ key: String) -> SIMD3<Float> { lin(Palette.parse(s.surfaces[key]?[2] ?? "#A0703C")) * 0.72 }
                g.litterColorA = fallen("deciduous1")
                g.litterColorB = fallen("deciduous3")
            }
        }
        shaderGlobals = g
        resources.update(globals: g)

        ensureSky()
        updateStars(env.sky.stars)
        updatePrecipitation(env.presentation.particles, wind: w.windVector)
        updateImageBasedLight(L, elevation: elevation, cloud: cloud)
    }

    public static let phenologyProfiles: [PhenologyProfile] = [.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo]

    /// The sky shader's cloud noise is roughly normal (mean 0.5, sd 0.10); the threshold is its
    /// (1 − cover) quantile so the covered share of the dome follows the cover.
    static func cloudThreshold(cover: Float) -> Float {
        let c = min(0.999, max(0.001, Double(cover)))
        // Acklam-style rational approximation of the inverse normal CDF at p = 1 − c.
        let p = 1 - c
        func inv(_ p: Double) -> Double {
            let a = [-39.6968302866538, 220.946098424521, -275.928510446969, 138.357751867269, -30.6647980661472, 2.50662827745924]
            let b = [-54.4760987982241, 161.585836858041, -155.698979859887, 66.8013118877197, -13.2806815528857]
            let cc = [-0.00778489400243029, -0.322396458041136, -2.40075827716184, -2.54973253934373, 4.37466414146497, 2.93816398269878]
            let d = [0.00778469570904146, 0.32246712907004, 2.445134137143, 3.75440866190742]
            if p < 0.02425 {
                let q = (-2 * log(p)).squareRoot()
                return (((((cc[0] * q + cc[1]) * q + cc[2]) * q + cc[3]) * q + cc[4]) * q + cc[5]) / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
            }
            if p > 1 - 0.02425 { return -inv(1 - p) }
            let q = p - 0.5, r = q * q
            return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
        }
        return Float(0.5 + 0.10 * inv(p))
    }

    /// Canopy map for leaf litter: a top-down 8-bit coverage of deciduous crowns over the area
    /// (~2 m per texel), sampled by the ground shader. Built once from the placed trees.
    func buildCanopyMap() {
        let b = features.bounds
        let size = b.max - b.min
        let n = 1024
        var px = [UInt8](repeating: 0, count: n * n)
        let mpp = max(size.x, size.y) / Double(n)
        for t in scene.instances where t.kind.isTree && t.kind != .conifer {
            let shape = PropLibrary.lobes(t.kind)
            let r = Double((shape.radii.x + shape.radii.z) / 2) * t.scale * 1.25
            let cx = (t.x - b.min.x) / mpp, cy = (b.max.y - t.y) / mpp   // row 0 = north edge (scene −z)
            let rp = r / mpp
            let x0 = max(0, Int(cx - rp)), x1 = min(n - 1, Int(cx + rp)), y0 = max(0, Int(cy - rp)), y1 = min(n - 1, Int(cy + rp))
            guard x0 <= x1, y0 <= y1 else { continue }
            for y in y0...y1 {
                let dy: Double = Double(y) + 0.5 - cy
                for x in x0...x1 {
                    let dx: Double = Double(x) + 0.5 - cx
                    let d: Double = (dx * dx + dy * dy).squareRoot() / rp
                    guard d < 1 else { continue }
                    let i = y * n + x
                    let add: Double = 255 * (1 - d * d)
                    px[i] = UInt8(min(255.0, Double(px[i]) + add))
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(px) as CFData),
              let image = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: n,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent),
              let texture = try? TextureResource(image: image, options: .init(semantic: .raw)) else { return }
        resources.staticMaterial.baseColor.texture = .init(texture)
        // Scene axes: x = east, z = −north; the map's v runs north → south.
        shaderGlobals.canopyOrigin = SIMD2(Float(b.min.x), Float(-b.max.y))
        shaderGlobals.canopySize = SIMD2(Float(mpp * Double(n)), Float(mpp * Double(n)))
    }

    /// A resolver for this world's place: the area centre as observer, the bundled time-of-day
    /// tables and star catalogue, and a phenology profile (calendar prior) by ID.
    public func environmentResolver(timeZone: TimeZone, phenologyProfileID: String?) throws -> EnvironmentResolver {
        let c = manifest.center
        let observer = SkyObserver(latitude: c.latitude, longitude: c.longitude, timeZoneID: timeZone.identifier)
        return EnvironmentResolver(observer: observer, tables: try StyleLibrary.lighting(), stars: try? StarCatalog.bundled(),
                                   phenologyProfile: Self.phenologyProfiles.first { $0.id == phenologyProfileID })
    }

    // MARK: - Sky dome and stars

    private func ensureSky() {
        guard skyDome == nil else { return }
        let lib = resources.library, tex = resources.textureResource
        do {
            // Unlit: the dome's colour is all ours, so RealityKit's lighting (sun, shadow lookups,
            // image-based light) would be wasted work on a large share of the screen.
            var sky = try CustomMaterial(surfaceShader: .init(named: "worldSkySurface", in: lib), lightingModel: .unlit)
            sky.custom.texture = .init(tex)
            sky.faceCulling = .none
            let dome = Entity()
            dome.name = "Sky dome"
            dome.components.set(ModelComponent(mesh: .generateSphere(radius: Self.skyRadius), materials: [sky]))
            dome.components.set(DynamicLightShadowComponent(castsShadow: false))
            rootEntity.addChild(dome)
            skyDome = dome

            var star = try CustomMaterial(surfaceShader: .init(named: "worldStarSurface", in: lib), lightingModel: .unlit)
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
                // 0.13°–0.36° quads; the soft core reads as a 2–6 px point on a phone.
                let size = Float(10 + 18 * s.brightness)
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
    func followCamera(_ camera: SIMD3<Float>, forward: SIMD3<Float>, dt: Double) {
        skyDome?.position = camera
        starField?.entity.position = camera
        // Precipitation box centred ~9 m ahead (most particles inside the view), 4 m up.
        let flat = simd_length(SIMD2(forward.x, forward.z)) > 1e-3 ? simd_normalize(SIMD3(forward.x, 0, forward.z)) : SIMD3<Float>(0, 0, -1)
        precipitation?.position = camera + flat * 9 + SIMD3(0, 4, 0)
        // From the air there are no local streaks (experience-v1 §10: "remove giant screen-spanning
        // rain streaks at this altitude"; weather v1 §6 allows omitting them): wetness, cloud and
        // fog carry the weather.
        if let p = precipitation {
            let wanted = particlesAllowed && !environmentState.precipitation.isEmpty && camera.y < Self.precipitationCeiling
            if p.isEnabled != wanted { p.isEnabled = wanted }
        }
    }

    /// Camera height above which rain and snow particles are switched off (aerial views).
    static let precipitationCeiling: Float = 60

    // MARK: - Precipitation

    /// Camera-local rain streaks or snowflakes (weather v1 §6): ~30 × 20 × 30 m box, counts from
    /// the particle budget (rain ≤ 600, snow ≤ 300), rain 12 m/s, snow 1.2 m/s, drift with the wind.
    private func updatePrecipitation(_ budget: ParticleBudget, wind: SIMD3<Double>) {
        let kind = budget.rain >= budget.snow ? (budget.rain > 0 ? "rain" : "") : "snow"
        // Art direction (Prompt 5): rain must read, so light rain keeps a floor of 240 streaks
        // (snow 120 flakes) within the 600/300 caps.
        let count = kind == "rain" ? max(budget.rain, 240) : max(budget.snow, 120)
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
        // Start from RealityKit's own presets (a known-good emitter), then set the box, counts,
        // speeds and look from the weather budget.
        var p = environmentState.precipitation == kind ? (entity.components[ParticleEmitterComponent.self] ?? Self.preset(kind)) : Self.preset(kind)
        p.emitterShape = .box
        p.birthLocation = .volume
        p.emitterShapeSize = SIMD3(24, 16, 22)
        p.fieldSimulationSpace = .global
        p.isEmitting = true
        p.simulationState = .play
        let drift = SIMD3<Float>(Float(wind.x), 0, Float(wind.z))
        var e = p.mainEmitter
        if kind == "rain" {
            let fall: Float = 12
            let side = simd_length(drift) > 0 ? simd_normalize(drift) * min(2, 0.2 * simd_length(drift)) : .zero
            p.birthDirection = .world
            p.emissionDirection = simd_normalize(SIMD3(side.x, -fall, side.z))
            p.speed = fall
            p.speedVariation = 1
            e.lifeSpan = 1.6
            e.lifeSpanVariation = 0.2
            e.size = 0.012
            e.stretchFactor = 4
            e.billboardMode = .billboard
            e.acceleration = .zero
            // Mid grey-blue: lighter than dark trees, a touch darker than a bright overcast sky.
            e.color = .constant(.single(.init(red: 0.72, green: 0.76, blue: 0.82, alpha: 0.55)))
        } else {
            let fall: Float = 1.2
            let side = simd_length(drift) > 0 ? simd_normalize(drift) * min(3, 0.35 * simd_length(drift)) : .zero
            p.birthDirection = .world
            p.emissionDirection = simd_normalize(SIMD3(side.x, -fall, side.z))
            p.speed = simd_length(SIMD3(side.x, fall, side.z))
            e.lifeSpan = 12
            e.size = 0.035
            e.stretchFactor = 0
            e.billboardMode = .billboard
            e.acceleration = .zero
            e.noiseStrength = 0.15
            e.color = .constant(.single(.init(red: 0.95, green: 0.96, blue: 0.98, alpha: 0.85)))
        }
        if options.diagnostics.contains("particleDebug") {
            e.size = 0.15
            e.stretchFactor = 0
            e.color = .constant(.single(.init(red: 1, green: 0, blue: 0, alpha: 1)))
        }
        e.birthRate = Float(count) / Float(e.lifeSpan)
        e.blendMode = .alpha
        e.opacityCurve = .quickFadeInOut
        e.isLightingEnabled = false
        p.mainEmitter = e
        entity.components.set(p)
        logEvent("precipitation \(kind) \(count)")
        environmentState.precipitation = kind
    }

    /// `diagnostics: ["events"]`: timestamped environment events (system uptime) for lining up
    /// frame hitches on the device.
    func logEvent(_ what: @autoclosure () -> String) {
        guard options.diagnostics.contains("events") else { return }
        print(String(format: "EVENT up=%.3f ", ProcessInfo.processInfo.systemUptime) + what())
    }

    static func preset(_ kind: String) -> ParticleEmitterComponent {
        kind == "rain" ? .Presets.rain : .Presets.snow
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
        logEvent("ibl start")
        environmentState.iblTask = Task { @MainActor [weak self] in
            let pixels = await Task.detached(priority: .utility) { SkyImage.render(light, width: 512, height: 256, convention: .realityKit) }.value
            guard !Task.isCancelled, let self, let image = World.cgImage(pixels, width: 512, height: 256),
                  let env = try? await EnvironmentResource(equirectangular: image) else { return }
            self.logEvent("ibl set")
            self.skyEnvironment = env
            self.iblEntity.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: -1.2 + log2(max(0.05, light.exposure))))
        }
    }
}
