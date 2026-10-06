import CoreGraphics
import Foundation
import Metal
import RealityKit
import WorldEnvironment
import WorldGen
import WorldGeo
import WorldMesh

// Postcard quality mode (docs/postcards.md, "Quality mode"): a still doesn't need 60 fps, so the
// offscreen copy of the world is drawn at maximum quality. Everything here acts on the copy; the
// live world's entities and the live view's settings never change.

/// How hard a postcard render works.
public struct PostcardQuality: Sendable, Equatable {
    /// The picture is rendered at this factor × its size (4× multisampling on top) and filtered
    /// down with a Lanczos-2 filter. 1 renders at the picture's size.
    public var supersample: Double
    /// Cap on the rendered pixels (memory and time): a big picture gets a smaller factor.
    public var maxRenderPixels: Int
    /// Sun shadow range in metres: 0 keeps the live view's range (`World.shadowDistance`, 80 m);
    /// otherwise the shadow reaches the farthest building or tree in frame, up to this distance.
    public var maxShadowDistance: Double
    /// Trees, bushes and building cells in frame at their nearest detail (opaque).
    public var nearDetail: Bool
    /// Edge tufts over all visible lawn edges out to this distance (m); 0 keeps the live view's
    /// ≤ 200 tufts near the camera.
    public var tuftRange: Double
    /// Extra ambient occlusion: the baked contact AO takes this share more of the ambient fill
    /// (bible §2.3: another 10–20% within a contact). 0 = off.
    public var ambientOcclusion: Double
    /// Ground bounce: the ground-coloured fill from below × (1 + this). 0 = off.
    public var groundBounce: Double
    /// Shade lift: the sky fill × (1 + this). 0 = off.
    public var shadeLift: Double
    /// The per-state final grade of `Profiles/postcard-grade.json`.
    public var finalGrade: Bool
    /// Frames drawn before the first picture of a copy (later pictures need none: on the Mac the
    /// first frame of a fresh copy already matched one drawn after two settle frames).
    public var settleFrames: Int

    public init(supersample: Double, maxRenderPixels: Int, maxShadowDistance: Double, nearDetail: Bool, tuftRange: Double,
                ambientOcclusion: Double, groundBounce: Double, shadeLift: Double, finalGrade: Bool, settleFrames: Int) {
        self.supersample = supersample
        self.maxRenderPixels = maxRenderPixels
        self.maxShadowDistance = maxShadowDistance
        self.nearDetail = nearDetail
        self.tuftRange = tuftRange
        self.ambientOcclusion = ambientOcclusion
        self.groundBounce = groundBounce
        self.shadeLift = shadeLift
        self.finalGrade = finalGrade
        self.settleFrames = settleFrames
    }

    /// The live view's settings: picture size, live detail, live shadow range, no extras.
    public static let live = PostcardQuality(supersample: 1, maxRenderPixels: .max, maxShadowDistance: 0, nearDetail: false, tuftRange: 0,
                                             ambientOcclusion: 0, groundBounce: 0, shadeLift: 0, finalGrade: false, settleFrames: 1)

    /// Quality mode (the owner's "maximum quality for a still").
    public static let max = PostcardQuality(supersample: 2, maxRenderPixels: 6_000_000, maxShadowDistance: 160, nearDetail: true,
                                            tuftRange: 80, ambientOcclusion: 0.15, groundBounce: 0.25, shadeLift: 0.08,
                                            finalGrade: true, settleFrames: 1)

    /// The supersample factor for a picture of `width` × `height` (never below 1).
    public func factor(width: Int, height: Int) -> Double {
        let pixels = Double(Swift.max(1, width * height))
        let capped = Swift.min(supersample, (Double(maxRenderPixels) / pixels).squareRoot())
        return Swift.max(1, capped)
    }

    /// The rendered size for a picture (whole pixels).
    public func renderSize(width: Int, height: Int) -> (width: Int, height: Int) {
        let f = factor(width: width, height: height)
        return (Int((Double(width) * f).rounded()), Int((Double(height) * f).rounded()))
    }
}

/// Where the time of one postcard went (milliseconds), for `POSTCARD timing` lines.
public struct PostcardTiming: Sendable, Equatable {
    /// Camera state for the pose, the world copy and quality work, renderer set-up (the first
    /// picture of an export carries it; later pictures reuse the copy): the sum of the four parts.
    public var clone: Double { prepare + copy + quality + setUp }
    /// The world's camera state for the pose (`World.update` for the export camera).
    public var prepare: Double = 0
    /// Cloning the world, its instance data and frozen globals.
    public var copy: Double = 0
    /// Quality mode on the copy: near detail, tufts, shadow fit.
    public var quality: Double = 0
    /// RealityRenderer and GPU kernels.
    public var setUp: Double = 0
    /// Settle frames, and filling the air with rain or snow (first picture).
    public var settle: Double = 0
    /// The final frame (submitted to finished on the GPU).
    public var render: Double = 0
    /// Grade and bloom, downsampling, final grade, read-back.
    public var post: Double = 0
    /// Frame, type and credits.
    public var frame: Double = 0
    public var total: Double { clone + settle + render + post + frame }

    public init() {}

    /// `clone=… settle=… render=… post=… frame=… total=… ms`.
    public var line: String {
        String(format: "clone=%.1f settle=%.1f render=%.1f post=%.1f frame=%.1f total=%.1f ms", clone, settle, render, post, frame, total)
    }

    /// `prepare=… copy=… quality=… setup=… ms` (the parts of `clone`).
    public var cloneLine: String {
        String(format: "prepare=%.1f copy=%.1f quality=%.1f setup=%.1f ms", prepare, copy, quality, setUp)
    }
}

/// What a postcard picture was rendered with.
public struct PostcardRenderInfo: Sendable, Equatable {
    /// Rendered pixels before the downsample.
    public var renderWidth = 0
    public var renderHeight = 0
    public var supersample = 1.0
    /// Sun shadow range used (m).
    public var shadowDistance = 0.0
    /// Side of the fitted shadow box (m; 0 with RealityKit's automatic fit).
    public var shadowBox = 0.0
    /// Metal memory the process holds when the picture's GPU work is done (MB), the peak of an
    /// export in practice.
    public var metalMegabytes = 0.0
    /// Edge tufts drawn.
    public var tufts = 0
    /// Tree and bush instances moved to their nearest detail, and building cells at their finest.
    public var nearInstances = 0
    public var nearBuildingCells = 0
    /// The lighting state whose final grade was applied (nil: no grade).
    public var gradeState: PostcardLightState?

    public init() {}
}

@MainActor
extension World {
    /// The lighting-bible state of the world's current light and weather
    /// (`PostcardLightState.resolve`; the light of `apply`, or the build's light before any).
    public var postcardLightState: PostcardLightState {
        guard let env = environment else {
            return PostcardLightState.resolve(.init(sunElevation: lighting.sunElevation, sunAzimuth: lighting.sunAzimuth))
        }
        var dayFraction: Double?
        if let day = env.sky.sunDay, let rise = day.sunrise.first?.utc, let set = day.sunset.first?.utc, set > rise {
            dayFraction = env.time.validTime.timeIntervalSince(rise) / set.timeIntervalSince(rise)
        }
        return PostcardLightState.resolve(.init(
            sunElevation: env.light.sunElevationDeg, sunAzimuth: env.light.sunAzimuthDeg, weather: env.state.dominantState?.rawValue,
            intensity: env.state.intensity01 ?? 0, cloudCover: env.state.cloudCover01 ?? 0, moonAltitude: env.sky.moon.altitudeDeg,
            moonIlluminatedFraction: env.sky.moon.illuminatedFraction, dayFraction: dayFraction))
    }

    /// Frustum planes for the widest of a set of pictures from `eye` towards `target`.
    static func postcardFrustum(eye: SIMD3<Float>, target: SIMD3<Float>, verticalFOV: Double, aspect: Double) -> [SIMD4<Float>] {
        let camera = Entity()
        camera.look(at: simd_distance(eye, target) > 1e-3 ? target : eye + SIMD3(0, 0, -1), from: eye, relativeTo: nil)
        return frustumPlanes(view: camera.transformMatrix(relativeTo: nil).inverse, fovY: Float(verticalFOV * .pi / 180),
                             aspect: Float(aspect), near: 0.1, far: 5000)
    }

    /// Quality mode on the world copy (`offscreenCopy`): near detail for everything in frame,
    /// tufts over the visible lawn edges, the sun's shadow reaching the farthest caster in frame.
    /// `copies` maps the live world's entities to their copies; only copies change.
    func applyQuality(_ q: PostcardQuality, root: Entity, copies: [ObjectIdentifier: Entity], eye: SIMD3<Float>,
                      planes: [SIMD4<Float>], info: inout PostcardRenderInfo) {
        let camera = SIMD2(eye.x, eye.z)
        var farthest: Float = 0
        func inFrame(_ b: BoundingBox) -> Bool { Self.intersects(b, planes) }
        func reach(_ b: BoundingBox) {
            let p = simd_clamp(eye, b.min, b.max)
            farthest = Swift.max(farthest, simd_distance(SIMD2(p.x, p.z), camera))
        }

        // Trees and bushes: in frame at the near mesh (slot 1, opaque); the rest by distance, as
        // live, for the shadows they throw into the frame. Slot 0 (the follow camera's cut-away
        // zone) stays empty: postcards have no cut-away.
        let edges = PropLibrary.lodDistances.map(Float.init)
        for g in lodGroups {
            let slots = g.levels.map { copies[ObjectIdentifier($0.entity)] }
            guard slots.count >= 3, slots.allSatisfy({ $0 != nil }) else { continue }
            let last = slots.count - 1
            var buckets = [[simd_float4x4]](repeating: [], count: slots.count)
            for inst in g.instances {
                let t = inst.transform
                if let b = Self.bounds(of: g.levels[1].buffers, [t]), inFrame(b) {
                    reach(b)
                    if q.nearDetail { buckets[1].append(t); continue }
                }
                // As live (`World.updateLODs`): eye distance, cut-away slot 0 left empty.
                let d = simd_distance(SIMD3(Float(inst.x), Float(inst.height), Float(-inst.y)), eye)
                var slot = 1
                for e in edges where d >= e { slot += 1 }
                buckets[min(slot, last)].append(t)
            }
            guard q.nearDetail else { continue }
            info.nearInstances += buckets[1].count
            for slot in slots.indices { Self.setInstances(slots[slot]!, buckets[slot], buffers: g.levels[slot].buffers) }
        }

        // Building cells: the finest level the cell has (near where it has one) when in frame.
        for cell in buildingCells {
            guard let b = cell.bounds else { continue }
            let visible = inFrame(b)
            if visible { reach(b) }
            guard q.nearDetail, visible, !cell.levels.isEmpty else { continue }
            let pick = cell.levels.firstIndex { $0.lod == .near } ?? 0
            for (j, level) in cell.levels.enumerated() { copies[ObjectIdentifier(level.entity)]?.isEnabled = j == pick }
            info.nearBuildingCells += 1
        }

        // Tufts over every visible lawn edge in range, shrinking away over the last quarter.
        if q.tuftRange > 0, !options.diagnostics.contains("noClutter"),
           let tufts = root.children.first(where: { $0.name == "Clutter tufts" }) {
            let field = scene.clutter
            let r = q.tuftRange, cs = field.cellSize
            let c = LocalPoint(Double(eye.x), Double(-eye.z))
            var ts: [simd_float4x4] = []
            for cx in Int(((c.x - r) / cs).rounded(.down))...Int(((c.x + r) / cs).rounded(.up)) {
                for cy in Int(((c.y - r) / cs).rounded(.down))...Int(((c.y + r) / cs).rounded(.up)) {
                    for p in field.candidates(cellX: cx, cellY: cy) {
                        let d = simd_distance(LocalPoint(p.x, p.y), c)
                        guard d <= r else { continue }
                        let pos = LocalFrame.scenePosition(LocalPoint(p.x, p.y), y: 0)
                        guard inFrame(BoundingBox(min: pos - SIMD3(0.5, 0, 0.5), max: pos + SIMD3(0.5, 0.6, 0.5))),
                              field.isLawnEdge(LocalPoint(p.x, p.y)) else { continue }
                        let fade = Float(1 - smoothstepD(r * 0.75, r, d))
                        ts.append(simd_float4x4(translation: pos, yaw: Float(p.z), scale: Float(p.w) * fade))
                    }
                }
            }
            Self.setInstances(tufts, ts, buffers: PropLibrary.mesh(.tuft, variant: 0, palette: scene.palette))
            info.tufts = ts.count
        }

        // The sun's shadow out to the farthest caster in frame (live range at least, the cap at most,
        // never past the fog's end), its bias growing with the coarser shadow texels.
        info.shadowDistance = Double(shadowDistance)
        if q.maxShadowDistance > 0, let sun = root.children.first(where: { $0.name == "Sun" }),
           sun.components.has(DirectionalLightComponent.Shadow.self) {
            let fogEnd = Float(environment?.light.weather.fogEndM ?? 5000)
            let d = Swift.max(shadowDistance, Swift.min(Float(q.maxShadowDistance), farthest, fogEnd))
            var s = DirectionalLightComponent.Shadow()
            s.depthBias = 1.5 * Swift.max(1, d / shadowDistance)
            switch Self.postcardShadowFit {
            case .automatic:
                s.shadowProjection = .automatic(maximumDistance: d)
            case let .box(halfExtent):
                let fit = Self.fitShadowBox(sun: sun, eye: eye, planes: planes, distance: d, halfExtent: halfExtent)
                s.shadowProjection = fit.projection
                info.shadowBox = Double(fit.side)
            }
            sun.components.set(s)
            info.shadowDistance = Double(d)
        }
    }

    /// How quality mode fits the sun's shadow map: an orthographic box around the frame's view
    /// slice (`.fixed`), or RealityKit's automatic fit to the camera frustum. RealityKit doesn't
    /// document whether `orthographicScale` is the box's full or half size; Mac renders show it is
    /// the full size (read as half, the box misses casters near the frame's edge). On the Mac the
    /// fitted box out to 160 m kept shadow edges as crisp as the automatic fit at 80 m.
    enum PostcardShadowFit: Equatable {
        case automatic
        case box(halfExtent: Bool)
    }

    static var postcardShadowFit = PostcardShadowFit.box(halfExtent: false)

    /// An orthographic shadow box that holds the frustum slice out to `distance` (heights 0–40 m)
    /// plus 200 m toward the sun for casters outside the frame; turns the copy's sun about its
    /// own axis (the light's direction is unchanged) so the box lines up with the view.
    static func fitShadowBox(sun: Entity, eye: SIMD3<Float>, planes: [SIMD4<Float>], distance: Float,
                             halfExtent: Bool) -> (projection: DirectionalLightComponent.Shadow.ShadowProjectionType, side: Float) {
        let m = sun.transformMatrix(relativeTo: nil)
        let f = -simd_normalize(SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z))   // the light's travel direction
        // Corners of the view slice: intersect pairs of side planes with the near and far planes.
        let corners = frustumCorners(planes: planes, eye: eye, distance: distance).map { SIMD3($0.x, Swift.min(Swift.max($0.y, 0), 40), $0.z) }
        var up = SIMD3<Float>(0, 1, 0) - f * f.y
        if simd_length(up) < 1e-3 { up = SIMD3(0, 0, -1) }
        up = simd_normalize(up)
        let right = simd_normalize(simd_cross(f, up))
        var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
        for p in corners + [eye] {
            let q = SIMD3(simd_dot(p, right), simd_dot(p, up), simd_dot(p, f))
            lo = simd_min(lo, q)
            hi = simd_max(hi, q)
        }
        let side = Swift.max(hi.x - lo.x, hi.y - lo.y) + 2
        let back: Float = 200
        let center = right * (lo.x + hi.x) / 2 + up * (lo.y + hi.y) / 2 + f * (lo.z - back)
        sun.look(at: center + f, from: center, upVector: up, relativeTo: nil)
        return (.fixed(zNear: 0.1, zFar: hi.z - lo.z + back + 10, orthographicScale: halfExtent ? side / 2 : side), side)
    }

    /// The eight corners of a frustum cut at `distance` (near plane at the eye).
    static func frustumCorners(planes: [SIMD4<Float>], eye: SIMD3<Float>, distance: Float) -> [SIMD3<Float>] {
        // planes: left, right, bottom, top, near, far (World.frustumPlanes order).
        guard planes.count >= 4 else { return [eye] }
        func ray(_ a: SIMD4<Float>, _ b: SIMD4<Float>) -> SIMD3<Float>? {
            let d = simd_cross(SIMD3(a.x, a.y, a.z), SIMD3(b.x, b.y, b.z))
            guard simd_length(d) > 1e-6 else { return nil }
            return simd_normalize(d)
        }
        var out: [SIMD3<Float>] = [eye]
        let sides = [(planes[0], planes[2]), (planes[0], planes[3]), (planes[1], planes[2]), (planes[1], planes[3])]
        let center = sides.compactMap { ray($0.0, $0.1) }
        // Orient each edge ray away from the eye, toward the inside of the frustum.
        for r in center {
            let dir = Self.intersects(BoundingBox(min: eye + r * distance * 0.5 - 0.01, max: eye + r * distance * 0.5 + 0.01), planes) ? r : -r
            out.append(eye + dir * distance)
        }
        return out
    }

    /// Fresh instance data for a copied instanced entity (empty disables it).
    static func setInstances(_ e: Entity, _ ts: [simd_float4x4], buffers: WorldMesh.MeshBuffers) {
        guard !ts.isEmpty, let mesh = e.components[ModelComponent.self]?.mesh,
              let data = try? LowLevelInstanceData(instanceCount: ts.count) else {
            e.isEnabled = false
            return
        }
        data.withMutableTransforms { dst in for (i, t) in ts.enumerated() { dst[i] = t } }
        guard let instances = try? MeshInstancesComponent(mesh: mesh, instances: data, bounds: bounds(of: buffers, ts)) else {
            e.isEnabled = false
            return
        }
        e.components.set(instances)
        e.isEnabled = true
    }
}
