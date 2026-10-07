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
    static let weatherExposureGain: Float = 0.3
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
        // The lighting bible's per-state grade (look-fix-v1 §2.2-2.4; Profiles/lighting-bible.json
        // with our tuning in grade.json): clear states by sun elevation, night by moon light, weather
        // over them by its weight. A label's bible state applies in full from `weatherFullAt` (the
        // bible's light rain is 0.7 mm/h, intensity 0.22); snow by the larger of intensity and cover.
        let state = env.state.dominantState
        var raw = min(1, max(0, env.state.intensity01 ?? (state == .cloudy ? env.state.cloudCover01 ?? 0 : 0)))
        if state == .snow { raw = max(raw, env.state.snowCover01 ?? 0) }
        let weight = min(1, raw / max(1e-3, Self.gradeTable?.fullAt[state?.rawValue ?? ""] ?? 1))
        let moonState = env.sky.moon
        let moonLight = pow(max(0, moonState.illuminatedFraction), 1.5) * max(0, sin(moonState.altitudeDeg * .pi / 180))
            * pow(1 - (env.state.cloudCover01 ?? 0), 2)
        let elevationDeg = env.light.sunElevationDeg
        let clearGrade = Self.gradeTable?.resolve(sunElevation: elevationDeg, moonLight: min(1, moonLight * 2), weather: nil, weight: 0)
        let grade = Self.gradeTable?.resolve(sunElevation: elevationDeg, moonLight: min(1, moonLight * 2),
                                             weather: state?.rawValue, weight: weight)
        if let grade {
            exposureTarget = Float(grade.luma / 255) + lookTuning.exposureTarget
            gradeSaturation = Float(grade.saturation)
        }
        // Weather key:fill (grade.json weather `direct`): the renderer takes away more of the direct
        // sun under cloud, rain and fog than the weather model does, and the sky fill grows as the
        // sun is hidden. Exposure compensation is small now: the solved auto exposure meets each
        // state's brightness, so a large boost here only fought it (storms rendered too bright).
        let directCut = Self.weatherDirectCut(state, weight: weight)
        let directEff = env.light.directStrength * directCut
        let hidden = Float(max(0, 1 - directEff))
        let dayWeight = Float(smoothstepD(-2, 8, elevationDeg))
        L.exposure *= 1 + dayWeight * Self.weatherExposureGain * pow(hidden, 1.2)
        let skyFillGain = 1 + dayWeight * Self.weatherSkyFillGain * hidden
        // Low clear sun (golden hour, early morning): at 6° the sun puts only ~10% of its light on
        // flat ground, so the sky fill washes its shadows out. A stronger key and less fill keep
        // the warm light and the long shadows readable (art direction: warm light that picks out
        // materials; P3 look loop: "no golden-hour key light"). The sun direction stays true.
        let lowSun = Float(1 - smoothstepD(4, 25, env.light.sunElevationDeg)) * Float(smoothstepD(0, 2, env.light.sunElevationDeg)) * (1 - hidden)
        // The clear state's key (grade.json `direct` on clear states: the bible's lift at 15:30 needs a
        // weaker key with more fill, measured on the phone).
        L.sunIntensity *= (1 + Self.lowSunKeyGain * lowSun) * lookTuning.key * Float(clearGrade?.direct ?? 1)
        let lowSunFill = 1 - Self.lowSunFillCut * lowSun
        var tint = SIMD3<Float>(Float(w.tintLinear.x), Float(w.tintLinear.y), Float(w.tintLinear.z))
        var tw = Float(w.tintWeight)
        // Smoke warms the whole scene, not only the distance (owner: ochre/peach; P3: the near lawn and
        // path stayed cool): a peach tint on fill and fog and an orange cast on the sun, at its weight.
        if state == .smoke {
            tint = WorldGen.Color.linear(Palette.parse("#D9A06A"))
            tw = 0.4 * Float(weight)
            L.sunColor = simd_mix(L.sunColor, WorldGen.Color.linear(Palette.parse("#FF9A4D")) * simd_length(L.sunColor) / 1.2, SIMD3(repeating: 0.6 * Float(weight)))
        }
        func tinted(_ c: SIMD3<Float>) -> SIMD3<Float> { c + (tint - c) * tw }
        func lin(_ c: SIMD3<Float>) -> SIMD3<Float> { WorldGen.Color.linear(c) }
        let elevation = env.light.sunElevationDeg

        // Sun: time-of-day colour and intensity × direct strength (weather, cloud, 0–2° fade-in).
        let direct = Float(directEff)
        var light = sunEntity.components[DirectionalLightComponent.self] ?? DirectionalLightComponent()
        let sc = WorldGen.Color.srgb(simd_normalize(L.sunColor + 1e-6))
        light.color = .init(red: CGFloat(sc.x), green: CGFloat(sc.y), blue: CGFloat(sc.z), alpha: 1)
        light.intensity = L.sunIntensity * direct * L.exposure * Self.sunLux
        sunEntity.components.set(light)
        if !options.diagnostics.contains("noShadows"), L.sunIntensity * direct > 0.01 {
            // Low sun casts long shadows (at 6.5° a 10 m tree's shadow is 88 m long), so the range opens
            // from 60 m to the bible's upper 80 m below 15° of sun (look-fix §2.3: 60–80 m coverage).
            let range = elevation < 15 ? max(shadowDistance, 80) : shadowDistance
            var shadow = sunEntity.components[DirectionalLightComponent.Shadow.self] ?? DirectionalLightComponent.Shadow()
            if shadow.depthBias != 1.5 || appliedShadowRange != range {
                shadow.shadowProjection = .automatic(maximumDistance: range)
                shadow.depthBias = 1.5
                sunEntity.components.set(shadow)
                appliedShadowRange = range
            }
            // Where shadows fall (`World.updateLODs` keeps out-of-view trees whose shadow reaches the
            // view): horizontal direction away from the sun, shadow length per metre of height.
            let sun = SIMD2<Float>(Float(env.light.sunDirection.x), Float(env.light.sunDirection.z))
            let away = simd_length(sun) > 1e-4 ? -simd_normalize(sun) : SIMD2<Float>(0, 0)
            shadowCast = SIMD3(away.x, away.y, Float(1 / tan(max(elevation, 3) * .pi / 180)))
        } else {
            sunEntity.components.remove(DirectionalLightComponent.Shadow.self)
            shadowCast = nil
        }
        let dir = SIMD3<Float>(Float(env.light.sunDirection.x), Float(env.light.sunDirection.y), Float(env.light.sunDirection.z))
        sunEntity.look(at: .zero, from: dir.y > 0.02 ? dir * 100 : [dir.x * 100, 2, dir.z * 100], relativeTo: nil)

        // Fog, fill and windows.
        var g = shaderGlobals
        g.fogColor = tinted(lin(L.fog))
        g.fogStart = Float(w.fogStartM)
        g.fogEnd = Float(w.fogEndM)
        // Lighting bible §3.2 presets where it has them (fog and smoke light → dense by intensity,
        // light rain, storm rain): their scattering colour and distances; a reported visibility
        // still caps the end (bounded calibration, §3.2).
        if let label = state, let e = Self.lightingBible?.extinction(label: label.rawValue, intensity: raw) {
            var end = e.end
            if let v = env.state.visibilityM { end = min(end, max(60, v)) }
            g.fogColor = e.color
            g.fogStart = Float(min(label == .smoke ? 0 : e.start, end * 0.5))
            g.fogEnd = Float(end)
        }
        // Lighting bible atmosphere: the clear-air fade of the state (§2.3), and weather extinction
        // (§3.2) only for weather that carries it, at its intensity.
        if let air = grade?.air {
            g.airColor = air.linear
            g.airCap = Float(air.cap)
            g.airStart = Float(air.start)
            g.airD50 = Float(air.d50)
        }
        let extinction: Bool = switch state {
        case .rain, .thunderstorm, .fog, .smoke, .haze, .dust, .snow: true
        default: false
        }
        // Falling snow, not lying snow, takes the view away.
        g.fogWeight = extinction ? Float(state == .snow ? min(1, max(0, env.state.intensity01 ?? 0)) : weight) : 0
        // Smoke fills the near field: up to 30% haze from the camera at full weight (owner's phone check).
        g.fogFloor = state == .smoke ? 0.3 * Float(weight) : 0
        // Wet ground from the rain pack (rain-bible.json, generated from docs/proposals/rain-v1): its
        // states interpolated at the current wetness, per surface; rain intensity drives lake ripples.
        if let rb = Self.rainBible {
            let at = rb.at(wetness: env.state.wetness01 ?? 0)
            func row(_ n: String, _ extra: Double) -> SIMD4<Float> {
                let v = at.surfaces[n] ?? .init(darken: 0, roughness: 1, sheen: 0)
                return SIMD4(Float(v.darken), Float(v.roughness), Float(v.sheen), Float(extra))
            }
            let raining = state == .rain || state == .thunderstorm ? Float(min(1, max(0.3, env.state.intensity01 ?? 0.5))) : 0
            g.wetA = row("concrete", min(at.puddleCoverage, rb.puddles.maxCoverage))
            g.wetB = row("asphalt", rb.puddles.roughness)
            g.wetC = row("brick", rb.puddles.skyMixNormal)
            g.wetD = row("lawn", rb.puddles.skyMixGrazing)
            g.wetE = row("roof", Double(raining))
        }
        if let water = Self.lookSpec?.water {
            g.water = SIMD4(Float(water.skyReflectClear), Float(water.skyReflectOvercast), Float(water.overcastSaturation), Float(water.rainRipples))
            g.waterB.x = Float(water.overcastReflectGain)
        }
        // The bible's per-state fill (grade.json `fill`, `groundFill`) on top of the time key's.
        let gradeFill = Float(grade?.fill ?? 1), gradeGround = Float(grade?.groundFill ?? 1)
        g.fillSky = tinted(lin(L.ambientSky)) * Float(env.light.fillSky) * Self.fillScale * L.exposure * skyFillGain * lowSunFill
            * lookTuning.fill * gradeFill
        g.fillGround = lin(L.ambientGround) * Float(env.light.fillGround) * Self.fillScale * L.exposure * lowSunFill
            * lookTuning.fill * lookTuning.groundFill * gradeFill * gradeGround
        // The sky fill keeps the bible's hue but only half its chroma: at the ×3.2 fill that sets the
        // bible's lift, the full #99AFE0 tint dominated foliage shading and cast crowns teal
        // (owner, gate on ccb5f77: "remove the cyan/teal cast"; autumn colours muddied).
        let fillLuma = simd_dot(g.fillSky, SIMD3<Float>(0.2126, 0.7152, 0.0722))
        g.fillSky = simd_mix(SIMD3(repeating: fillLuma), g.fillSky, SIMD3(repeating: 0.5))
        g.litFraction = L.litWindows
        // Lit windows (lighting bible §2.4): the core colour at night, the surround tone in twilight.
        let night = Self.lightingBible?.night
        g.litWindow = Palette.parse(elevation < -6 ? night?.windowCore ?? "#FFD19A" : night?.windowSurround ?? "#E8A968")

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
        // Fair-weather clouds near white with cool bases (bible §6.1); the deck greys as cover closes.
        let deck = simd_mix(lin(L.skyHorizon), lin(L.ambientSky), SIMD3(repeating: 0.25))
        let fair = simd_mix(SIMD3<Float>(repeating: 0.92), deck, SIMD3(repeating: 0.25))
        let cloudColor = tinted(simd_mix(fair, deck, SIMD3(repeating: min(1, cloud * 1.4)))) * (1.04 - 0.3 * cloud) * (1 - wetSky)
        // Fog, haze, smoke and dust veil the sky itself, not just the distance: dense fog closes to
        // a uniform pale grey (experience-v1 05: "uniform pale gray horizon", no sun disk), smoke
        // to a flat beige-grey (06). The veil leans toward the obscurant's own colour.
        let obscured = label?.isObscuration ?? false
        // Smoke flattens the sky into one warm veil (owner: ochre/peach with distance), at the
        // smoke's full weight; fog closes to its own grey; haze and dust as before.
        let veil: Float = obscured ? (label == .fog ? 0.95 * intensity : label == .smoke ? 0.92 * Float(weight) : 0.75 * intensity) : 0
        let veilColor = label == .fog || label == .smoke ? g.fogColor : simd_mix(g.fogColor, tint, SIMD3(repeating: 0.6))
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

    public static let phenologyProfiles: [PhenologyProfile] = [.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo, .chicagoland]

    /// Direct-sun multiplier of the bible's weather grade (1 when clear), at the weather's weight.
    static func weatherDirectCut(_ state: DominantState?, weight: Double) -> Double {
        guard let state, let cut = gradeTable?.weather[state.rawValue]?.direct else { return 1 }
        return 1 + (cut - 1) * weight
    }

    /// The sky shader's cloud noise (0.55·n1 + 0.30·n2 + 0.15·n3 of value noise) has mean 0.5 and
    /// sd 0.139; its threshold for a cover is the noise's measured (1 − cover) quantile. A street
    /// camera sees the dome near the horizon, where perspective crowds the clouds, so low covers
    /// are thinned for the view (lighting bible §6.1: 0–0.15 cover shows 0–3 forms, a broad clear
    /// gradient; 0.15–0.4 separated clouds with 40%+ clear gaps); from 0.6 the cover is as given.
    static func cloudThreshold(cover: Float) -> Float {
        let c = min(0.999, max(0.001, cover))
        let shown = c * (0.45 + 0.55 * smoothstepF(0.15, 0.6, c))
        // (cover, threshold) measured from 200,000 samples of the shader's noise.
        let table: [(Float, Float)] = [(0.0, 0.86), (0.02, 0.7747), (0.05, 0.7277), (0.10, 0.6824), (0.15, 0.6500),
                                       (0.20, 0.6228), (0.30, 0.5777), (0.40, 0.5373), (0.50, 0.4991), (0.60, 0.4609),
                                       (0.70, 0.4215), (0.80, 0.3765), (0.90, 0.3176), (0.95, 0.2726), (1.0, 0.15)]
        for (a, b) in zip(table, table.dropFirst()) where shown >= a.0 && shown <= b.0 {
            return a.1 + (b.1 - a.1) * (shown - a.0) / (b.0 - a.0)
        }
        return table.last!.1
    }

    static func smoothstepF(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
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
        // Rain streak count from the rain pack's state at this wetness (street views: precipitation is
        // off above 60 m, so aerial counts never apply); snow keeps a floor of 120 flakes.
        let packCount: Int = {
            guard let rb = Self.rainBible else { return 240 }
            let w = environment?.state.wetness01 ?? 0.5
            let st = rb.states.filter { $0.id != "drying" }.min { abs($0.wetness - w) < abs($1.wetness - w) }
            return st?.rainCountStreet ?? 240
        }()
        let count = kind == "rain" ? min(max(budget.rain, packCount), Self.rainBible?.rain.maxRainStreaks ?? 600) : max(budget.snow, 120)
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
            // Rain pack streaks: thin, 7–24 cm long, opacity by intensity, tinted by the sky and fog.
            let rp = Self.rainBible?.rain
            let length = Float(rp?.streakLengthM.last ?? 0.2)
            e.size = 0.008
            e.stretchFactor = length / 0.008
            e.billboardMode = .billboard
            e.acceleration = .zero
            // Mid grey-blue: lighter than dark trees, a touch darker than a bright overcast sky.
            let i = environment?.state.intensity01 ?? 0.3
            let night = (environment?.light.sunElevationDeg ?? 10) < -6
            let alpha = night ? rp?.nightOpacity ?? 0.28 : i < 0.4 ? rp?.opacityLight ?? 0.26 : i < 0.8 ? rp?.opacitySteady ?? 0.34 : rp?.opacityHeavy ?? 0.4
            let fogC = WorldGen.Color.srgb(shaderGlobals.fogColor)
            e.color = .constant(.single(.init(red: CGFloat(min(1, fogC.x * 1.1)), green: CGFloat(min(1, fogC.y * 1.1)), blue: CGFloat(min(1, fogC.z * 1.15)),
                                              alpha: CGFloat(alpha))))
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
        let iblEV = lookTuning.iblEV
        logEvent("ibl start")
        environmentState.iblTask = Task { @MainActor [weak self] in
            let pixels = await Task.detached(priority: .utility) { SkyImage.render(light, width: 512, height: 256, convention: .realityKit) }.value
            guard !Task.isCancelled, let self, let image = World.cgImage(pixels, width: 512, height: 256),
                  let env = try? await EnvironmentResource(equirectangular: image) else { return }
            self.logEvent("ibl set")
            self.skyEnvironment = env
            self.iblEntity.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: -1.2 + log2(max(0.05, light.exposure)) + iblEV))
        }
    }
}
