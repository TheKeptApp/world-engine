import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// How much detail to generate.
public enum DetailLevel: String, Sendable, Codable {
    /// Street level: windows, doors, porches, trim, chimneys, baked AO bands.
    case full
    /// Context: walls and roofs only.
    case simple
}

/// A generated building plus the choices made for it (exported in scene.json).
public struct GeneratedBuilding: Sendable {
    public enum Role: String, Sendable, Codable { case house, garage, shed, block }
    public enum RoofShape: String, Sendable, Codable { case gabled, hipped, flat, slab }

    public var ref: OSMRef
    public var role: Role
    public var footprintClass: FootprintClass
    public var roofShape: RoofShape
    /// House family from the profile (bungalow, foursquare, …), nil for non-houses.
    public var houseType: String?
    /// Which color tuple (0 = A, 1 = B) and the resolved hex colors [wall, trim, door, roof].
    public var colorSet = 0
    public var colors: [String] = []
    public var floors = 1
    /// True when floors came from OSM `building:levels`; false when inferred from the type.
    public var floorsFromOSM = false
    public var mesh = MeshBuffers()
    /// Edge index (outer ring) with the front door, if any.
    public var frontEdge: Int?
    /// Edge index with the garage door, if any.
    public var garageDoorEdge: Int?
    /// True if the garage door faces an alley/service road (vs. a street).
    public var garageDoorFacesAlley = false
    public var eaveHeight: Double = 0
    public var topHeight: Double = 0
    public var hasPorch = false
    public var porchStyle: String?
    /// Where to plant foundation bushes (local points) with a seeded scale.
    public var bushSpots: [(LocalPoint, Float)] = []
}

public struct BuildingGenerator: Sendable {
    public var profile: StyleProfile
    public var context: StreetContext

    public init(profile: StyleProfile, context: StreetContext) {
        self.profile = profile
        self.context = context
    }

    static let houseTypes: Set<String> = ["house", "detached", "semidetached_house", "bungalow", "residential", "terrace", "cabin"]
    static let garageTypes: Set<String> = ["garage", "garages", "carport"]
    static let shedTypes: Set<String> = ["shed", "hut", "kiosk", "toilets"]

    public static func role(of b: Building) -> GeneratedBuilding.Role {
        let area = b.footprint.area
        if garageTypes.contains(b.type) { return .garage }
        if shedTypes.contains(b.type) || area < FootprintAnalysis.tinyArea { return .shed }
        if houseTypes.contains(b.type) || (b.type == "yes" && area < 250) { return .house }
        return .block
    }

    // MARK: - Type choice (v2 §4.4)

    /// The footprint situation key for the profile's type rules.
    func situation(_ b: Building, shape: FootprintAnalysis, broadFront: Bool) -> String {
        let t = profile.typeThresholds
        let area = b.footprint.area
        let aspect = shape.obb.halfWidth > 0 ? shape.obb.halfLength / shape.obb.halfWidth : 1
        if b.type == "semidetached_house" { return "semidetached" }
        if let levels = b.levels.map({ Int($0.rounded()) }), levels > 0 {
            switch levels {
            case 1: return aspect >= t.broadAspect && broadFront ? "oneFloorBroad" : "oneFloor"
            case 2:
                if aspect <= t.squareAspect && shape.rectangularity >= t.squareRectangularity { return "twoFloorSquare" }
                return aspect >= t.narrowAspect ? "twoFloorNarrow" : "twoFloor"
            default: return "threeFloor"
            }
        }
        if area < t.smallArea { return "small" }
        if area > t.largeArea { return "large" }
        return "unknown"
    }

    /// Picks the house type: rule weights for the situation, filtered by each type's eligibility.
    public func houseType(for b: Building, shape: FootprintAnalysis, frontEdge: Int?) -> (StyleProfile.HouseType, String) {
        let ring = b.footprint.outer
        var broadFront = false
        if let e = frontEdge {
            let (_, dir, _, _) = Self.edge(ring, e)
            broadFront = abs(simd_dot(dir, shape.obb.u)) > 0.85
        }
        let key = situation(b, shape: shape, broadFront: broadFront)
        let weights = profile.typeRules[key] ?? profile.typeRules["unknown"] ?? [:]
        let aspect = shape.obb.halfWidth > 0 ? shape.obb.halfLength / shape.obb.halfWidth : 1
        let levels = b.levels.map { Int($0.rounded()) }
        func eligible(_ t: StyleProfile.HouseType) -> Bool {
            if let l = levels, l > 0, !t.floors.contains(l) { return false }
            if let m = t.minAspect, aspect < m { return false }
            if let m = t.maxAspect, aspect > m { return false }
            if let q = t.minRectangularity, shape.rectangularity < q { return false }
            if t.broadFrontage == true, !broadFront { return false }
            return true
        }
        let all = weights.keys.sorted().compactMap { id in profile.houseType(id).map { ($0, weights[id]!) } }
        let candidates = all.filter { eligible($0.0) }
        var r = b.ref.random("house-type")
        let chosen = r.pick(candidates.isEmpty ? all : candidates) { $0.1 }.0
        return (chosen, key)
    }

    // MARK: - Generation

    public func generate(_ b: Building, palette: inout Palette, detail: DetailLevel) -> GeneratedBuilding {
        let role = Self.role(of: b)
        let shape = FootprintAnalysis(b.footprint)
        let fp = b.footprint
        let ring = fp.outer
        var g = GeneratedBuilding(ref: b.ref, role: role, footprintClass: shape.kind, roofShape: .flat)

        // Orientation first: it informs the house type (broad frontage) and the openings.
        switch role {
        case .house, .block:
            g.frontEdge = context.frontEdge(of: ring)
        case .garage:
            if let e = context.alleyEdge(of: ring) {
                g.garageDoorEdge = e
                g.garageDoorFacesAlley = true
            } else {
                g.garageDoorEdge = context.frontEdge(of: ring) ?? Self.longestEdge(ring)
            }
        case .shed:
            g.frontEdge = context.alleyEdge(of: ring) ?? context.frontEdge(of: ring)
        }

        // Type, colors, dimensions.
        var rng = b.ref.random("building")
        let type: StyleProfile.HouseType? = role == .house ? houseType(for: b, shape: shape, frontEdge: g.frontEdge).0
            : role == .block ? (profile.houseTypes.first { $0.roof.flat >= 1 } ?? profile.houseTypes.last) : nil
        g.houseType = role == .house ? type?.id : nil
        let tuples: [[String]] = switch role {
        case .garage: profile.garage.colors
        case .shed: profile.shed.colors
        default: type?.colors ?? profile.houseTypes[0].colors
        }
        var cr = b.ref.random("palette")
        g.colorSet = Int(cr.next() % UInt64(max(1, tuples.count)))
        var tuple = tuples[g.colorSet]
        if let wall = b.tags["building:colour"].flatMap(Self.hexColor) { tuple[0] = wall }
        if let roof = b.tags["roof:colour"].flatMap(Self.hexColor) { tuple[3] = roof }
        g.colors = tuple
        let wallPaint = Paint(slot: palette.slot(hex: tuple[0]), shade: Float(rng.range(0.97, 1.03)))
        let trim = Paint(slot: palette.slot(hex: tuple[1]))
        let doorPaint = Paint(slot: palette.slot(hex: tuple[2]))
        let roofPaint = Paint(slot: palette.slot(hex: tuple[3]), shade: Float(rng.range(0.96, 1.04)))
        let foundation = Paint(slot: palette.named("foundation"))
        let glass = Paint(slot: palette.named("windowDay"), flags: .glass)

        // Roof shape: OSM roof:shape, else type/outbuilding mix, then footprint constraints.
        let mix: StyleProfile.RoofMix = switch role {
        case .garage: profile.garage.roof ?? .init(gabled: 1, hipped: 0, flat: 0)
        case .shed: .init(gabled: 0, hipped: 0, flat: 1)
        default: type?.roof ?? .init(gabled: 0, hipped: 0, flat: 1)
        }
        var roofShape: GeneratedBuilding.RoofShape
        switch b.roofShape {
        case "gabled", "saltbox", "gambrel", "mansard": roofShape = .gabled
        case "hipped", "pyramidal", "half-hipped", "side_hipped": roofShape = .hipped
        case "flat": roofShape = .flat
        case "skillion": roofShape = .slab
        default:
            var r = b.ref.random("roof-shape")
            roofShape = r.pick([(GeneratedBuilding.RoofShape.gabled, mix.gabled), (.hipped, mix.hipped), (.flat, mix.flat)]) { $0.1 }.0
        }
        switch (role, shape.kind) {
        case (.shed, _), (_, .tiny): roofShape = .slab
        case (_, .irregular): roofShape = .flat
        default: break
        }
        if roofShape != .flat, roofShape != .slab, shape.roofRects.isEmpty { roofShape = .flat }
        g.roofShape = roofShape

        let pitchRange: [Double] = switch role {
        case .garage: profile.garage.pitch
        case .shed: profile.shed.pitch
        default: type?.pitch ?? [20, 30]
        }
        let overhangRange: [Double] = switch role {
        case .garage: profile.garage.overhang
        case .shed: profile.shed.overhang
        default: type?.overhang ?? [0.3, 0.5]
        }
        let pitch = rng.range(pitchRange)
        let overhang = rng.range(overhangRange)
        let F: Double = switch role {
        case .house: rng.range(profile.foundationMeters)
        case .garage: 0.12
        case .shed: 0.05
        case .block: 0.3
        }
        let mainRect = shape.roofRects.max { $0.area < $1.area } ?? shape.obb
        let rise = (roofShape == .gabled || roofShape == .hipped) ? Roofs.rise(mainRect, pitch: pitch) : 0
        let osmLevels = b.levels.map { max(1, Int($0.rounded())) }
        g.floorsFromOSM = osmLevels != nil
        var H: Double
        switch role {
        case .garage:
            H = osmLevels.map { Double($0) * 2.9 } ?? rng.range(profile.garage.wallHeight)
        case .shed:
            H = min(b.height.top, rng.range(profile.shed.wallHeight))
        case .house, .block:
            let floors = osmLevels ?? type?.floors.first ?? max(1, Int((b.height.top / 3.1).rounded()))
            g.floors = floors
            let perFloor = rng.range(type?.perFloor ?? [3.0, 3.2])
            if b.height.source == .heightTag {
                H = max(F + 2.6, b.height.top - rise)
            } else {
                H = F + Double(floors) * perFloor
            }
        }
        g.eaveHeight = H
        g.topHeight = H + rise

        var m = MeshBuffers()
        let full = detail == .full
        let pitched = roofShape == .gabled || roofShape == .hipped
        let parapet: Double = roofShape == .flat && role != .shed ? rng.range(type?.parapet ?? [0.3, 0.4]) : 0

        // Walls in bands so baked AO has vertices to live on: base contact, eave shadow.
        for wallRing in [fp.outer] + fp.holes {
            if full, F > 0.05 {
                m.paint = foundation
                addWalls(wallRing, z0: 0, z1: F, into: &m)
            }
            m.paint = wallPaint
            let top = H + parapet
            let z0 = full ? F : 0
            if full, pitched, top - z0 > 1.2 {
                addWalls(wallRing, z0: z0, z1: top - 0.7, into: &m)
                addWalls(wallRing, z0: top - 0.7, z1: top, into: &m)
            } else {
                addWalls(wallRing, z0: z0, z1: top, into: &m)
            }
        }
        // R1: contact darkening at the base, softer eave occlusion under pitched roofs.
        let eaveAO: Float = pitched ? 0.8 : 1.0
        m.bakeAO(from: 0) { p, _ in
            let y = Double(p.y)
            let base = 0.72 + 0.28 * smoothstep(0, max(F, 0.6) + 0.3, y)
            let eave = pitched ? 1 - (1 - Double(eaveAO)) * smoothstep(H - 0.7, H, y) : 1
            return Float(base * eave)
        }

        // Roof.
        let roofStart = m.positions.count
        let roofStyle = Roofs.Style(pitchDegrees: pitch, overhang: overhang, roof: roofPaint, gableWall: wallPaint, trim: trim, fascia: 0.22)
        switch roofShape {
        case .gabled:
            for r in shape.roofRects { Roofs.gabled(r, eave: H, style: roofStyle, into: &m) }
        case .hipped:
            for r in shape.roofRects { Roofs.hipped(r, eave: H, style: roofStyle, into: &m) }
        case .flat:
            Roofs.flatWithParapet(fp, z: H, parapet: parapet, roof: roofPaint, wall: wallPaint, into: &m)
        case .slab:
            Roofs.slab(shape.obb, z: H, thickness: 0.12, overhang: overhang, paint: roofPaint, into: &m)
        }
        if pitched {
            for r in shape.flatRects { Roofs.slab(r, z: H, thickness: 0.15, overhang: 0.1, paint: roofPaint, into: &m) }
        }
        // Soffits (down-facing) sit in the eave shadow; parapet insides get mild occlusion.
        m.bakeAO(from: roofStart) { _, n in n.y < -0.5 ? 0.7 : 1 }

        if full {
            addOpenings(b, &g, type: type, ring: ring, F: F, H: H, pitched: pitched, overhang: overhang, pitch: pitch,
                        wall: wallPaint, trim: trim, door: doorPaint, roof: roofPaint, foundation: foundation, glass: glass,
                        palette: &palette, mainRect: mainRect, into: &m)
            addContactSkirt(ring, palette: palette, into: &m)
        }
        g.mesh = m
        return g
    }

    // MARK: - Openings, porches, chimneys

    // swiftlint:disable:next function_parameter_count
    func addOpenings(_ b: Building, _ g: inout GeneratedBuilding, type: StyleProfile.HouseType?, ring: Ring, F: Double, H: Double,
                     pitched: Bool, overhang: Double, pitch: Double, wall: Paint, trim: Paint, door: Paint, roof: Paint,
                     foundation: Paint, glass: Paint, palette: inout Palette, mainRect: OrientedRect, into m: inout MeshBuffers) {
        let role = g.role
        var rng = b.ref.random("openings")
        let win = type?.windows ?? StyleProfile.Windows(bay: [2.8, 3.2], width: [0.9, 1.2], height: [1.2, 1.5], broad: nil)
        let bay = rng.range(win.bay)
        let winW = rng.range(win.width), winH = rng.range(win.height)
        let stories = role == .garage ? 1 : max(1, g.floors)
        let storyH = (H - F) / Double(stories)
        var doorSpan: (edge: Int, s0: Double, s1: Double)?
        // Household seed for stable lit-window grouping (v2 §10/05).
        var household = b.ref.random("household")
        let householdSeed = Float(household.unit())

        if role == .house || role == .block, let e = g.frontEdge {
            let (p, dir, n, len) = Self.edge(ring, e)
            var r = b.ref.random("door")
            let doorAt = type.map { r.pick($0.door) { _ in 1 } } ?? 0.5
            let doorS = min(len - 0.7, max(0.7, len * doorAt))
            let porch = type?.porch
            let porchStyle = porch?.style ?? "canopy"
            let wantsPorch = r.chance(porch?.likelihood ?? 0.3) && len >= 3.5
            g.hasPorch = wantsPorch
            g.porchStyle = wantsPorch ? porchStyle : nil
            // Door (0.9 × 2.05 m) with trim surround.
            m.paint = trim
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.58, s1: doorS + 0.58, z0: F, z1: F + 2.2, offset: 0.025)
            m.paint = door
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.45, s1: doorS + 0.45, z0: F, z1: F + 2.05, offset: 0.045)
            let eaveZ = H - overhang * tan(pitch * .pi / 180)
            if wantsPorch, porchStyle == "covered" {
                let depth = r.range(porch!.depth)
                let width = min(len - 0.4, max(2.4, len * r.range(porch!.frontage)))
                let s0 = max(0.2, min(len - 0.2 - width, doorS - width / 2))
                doorSpan = (e, s0 - 0.3, s0 + width + 0.3)
                let c = p + dir * (s0 + width / 2) + n * (depth / 2)
                let start = m.positions.count
                m.paint = foundation
                m.addBox(center: c, u: dir, halfLength: width / 2, halfWidth: depth / 2, z0: 0, z1: F)
                let roofZ = max(F + 2.45, min(F + 2.75, eaveZ - 0.05))
                m.paint = trim
                for sx in [-1.0, 1.0] {
                    let post = c + dir * (sx * (width / 2 - 0.16)) + n * (depth / 2 - 0.16)
                    m.addBox(center: post, u: dir, halfLength: 0.12, halfWidth: 0.12, z0: F, z1: roofZ)
                }
                Roofs.slab(OrientedRect(center: c, u: dir, halfLength: width / 2, halfWidth: depth / 2),
                           z: roofZ, thickness: 0.2, overhang: 0.15, paint: roof, into: &m)
                // Porch floor darker near the wall, ceiling underside in shade, post bases grounded.
                let wallLine = (p, dir, n)
                m.bakeAO(from: start) { pos, nn in
                    let lp = LocalPoint(Double(pos.x), Double(-pos.z))
                    let out = simd_dot(lp - wallLine.0, wallLine.2)
                    if nn.y < -0.5 { return 0.68 }
                    if nn.y > 0.5, Double(pos.y) <= F + 0.01 { return Float(0.74 + 0.26 * smoothstep(0, depth, out)) }
                    return Float(0.8 + 0.2 * smoothstep(F, F + 0.6, Double(pos.y)))
                }
                addSteps(at: p + dir * doorS + n * depth, dir: dir, n: n, width: 1.4, height: F, foundation: foundation, into: &m)
            } else {
                // Stoop or entry with a small canopy (recessed/modern canopies get no posts).
                doorSpan = (e, doorS - 1.0, doorS + 1.0)
                let depth = porch.map { r.range($0.depth) } ?? 1.0
                let start = m.positions.count
                m.paint = foundation
                m.addBox(center: p + dir * doorS + n * 0.6, u: dir, halfLength: 0.8, halfWidth: 0.6, z0: 0, z1: F)
                if wantsPorch || porchStyle == "canopy" {
                    Roofs.slab(OrientedRect(center: p + dir * doorS + n * min(depth, 1.2) / 2, u: dir, halfLength: 0.9, halfWidth: min(depth, 1.2) / 2),
                               z: F + 2.35, thickness: 0.12, overhang: 0.05, paint: roofPaint(roof, trim, porchStyle), into: &m)
                }
                m.bakeAO(from: start) { _, nn in nn.y < -0.5 ? 0.7 : 1 }
                addSteps(at: p + dir * doorS + n * 1.2, dir: dir, n: n, width: 1.2, height: F, foundation: foundation, into: &m)
            }
            // Foundation bushes along the front, skipping the entry.
            var bush = b.ref.random("bushes")
            var s = 0.8
            let span = doorSpan!
            while s < len - 0.6 {
                if !(s > span.s0 - 0.5 && s < span.s1 + 0.5) && bush.chance(0.7) {
                    g.bushSpots.append((p + dir * s + n * 0.9, Float(bush.range(0.7, 1.15))))
                }
                s += bush.range(1.5, 2.3)
            }
        }

        if role == .garage, let e = g.garageDoorEdge {
            let (p, dir, n, len) = Self.edge(ring, e)
            let doubleDoor = len >= (profile.garage.doubleDoorMinWidthMeters ?? 6)
            let w = min(len - 0.6, doubleDoor ? 5.0 : 2.7)
            let s0 = (len - w) / 2
            m.paint = trim
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 - 0.12, s1: s0 + w + 0.12, z0: F, z1: F + 2.25, offset: 0.025)
            m.paint = door
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0, s1: s0 + w, z0: F, z1: F + 2.12, offset: 0.04)
            m.paint = Paint(slot: door.slot, shade: 0.85)
            for k in 1..<4 {
                let z = F + 2.12 * Double(k) / 4
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 + 0.05, s1: s0 + w - 0.05, z0: z - 0.02, z1: z + 0.02, offset: 0.05)
            }
            doorSpan = (e, s0 - 0.3, s0 + w + 0.3)
        }

        if role == .shed, let e = g.frontEdge ?? Optional(Self.longestEdge(ring)) {
            let (p, dir, n, len) = Self.edge(ring, e)
            if len >= 1.2 {
                m.paint = door
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: len / 2 - 0.42, s1: len / 2 + 0.42, z0: F, z1: min(H - 0.15, F + 1.9), offset: 0.03)
            }
        }

        // Windows: front facade gets the type's rhythm; sides and rear are sparser (v2 §4.2).
        if role == .house || role == .block || (role == .garage && rng.chance(0.4)) {
            for e in 0..<ring.count {
                let (p, dir, n, len) = Self.edge(ring, e)
                if role == .garage, e == g.garageDoorEdge { continue }
                let isFront = e == g.frontEdge
                let bayHere = isFront ? bay : bay * (role == .garage ? 2.5 : 1.7)
                var count: Int
                if len < 2.0 { continue }
                if len < 3.0 { count = rng.chance(0.5) ? 1 : 0 } else { count = max(1, Int(len / bayHere)) }
                if role == .garage { count = min(count, 1) }
                guard count > 0 else { continue }
                for story in 0..<stories {
                    let z0 = F + Double(story) * storyH + (story == 0 ? 0.85 : 0.8)
                    let z1 = min(z0 + winH, F + Double(story + 1) * storyH - 0.35, H - 0.3)
                    guard z1 - z0 > 0.6 else { continue }
                    // Ranch: one broad living-room window on the front, ground floor.
                    var widths = [Double](repeating: winW, count: count)
                    if isFront, story == 0, let broad = win.broad, count >= 2 { widths[0] = rng.range(broad) }
                    // Fit within corner clearance 0.45 m and 0.35 m between openings; drop windows first.
                    while !widths.isEmpty, widths.reduce(0, +) + Double(widths.count - 1) * 0.35 > len - 0.9 { widths.removeLast() }
                    guard !widths.isEmpty else { continue }
                    let step = (len - 0.9) / Double(widths.count)
                    for (k, w) in widths.enumerated() {
                        let sc = 0.45 + step * (Double(k) + 0.5)
                        if story == 0, let span = doorSpan, span.edge == e, sc + w / 2 > span.s0, sc - w / 2 < span.s1 { continue }
                        var wr = StableRandom(UInt64(e), UInt64(story * 31 + k), salt: "lit")
                        m.extra = SIMD4(1, min(0.999, householdSeed * 0.6 + Float(wr.unit()) * 0.4), 0, 0)
                        addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: min(w, step - 0.35), z0: z0, z1: z1,
                                  glass: glass, trim: trim, into: &m)
                        m.extra = SIMD4(1, 0, 0, 0)
                    }
                }
            }
        }

        // Chimney on some pitched house roofs.
        if role == .house, pitched {
            var r = b.ref.random("chimney")
            if r.chance(profile.chimneyLikelihood) {
                let along = (mainRect.halfLength - 0.9) * (r.chance(0.5) ? 1 : -1)
                let c = mainRect.point(along, mainRect.halfWidth * 0.35)
                m.paint = Paint(slot: palette.named("chimney"))
                m.addBox(center: c, u: mainRect.u, halfLength: 0.35, halfWidth: 0.45, z0: H - 0.5, z1: g.topHeight + 0.8)
            }
        }
    }

    func roofPaint(_ roof: Paint, _ trim: Paint, _ style: String) -> Paint { style == "canopy" ? trim : roof }

    /// R1: a soft occlusion strip on the ground around the walls (contact with the lawn).
    func addContactSkirt(_ ring: Ring, palette: Palette, into m: inout MeshBuffers) {
        let start = m.positions.count
        let lawn = Paint(slot: palette.named("lawn"), flags: .lawn)
        m.paint = lawn
        let width = 0.9
        for i in 0..<ring.count {
            let p = ring[i], q = ring[(i + 1) % ring.count]
            let d = q - p
            let len = simd_length(d)
            guard len > 0.05 else { continue }
            let out = LocalPoint(d.y, -d.x) / len // outward for a CCW ring
            let y = 0.005
            let a = P(p, y), b = P(q, y), c = P(q + out * width, y), dd = P(p + out * width, y)
            m.extra = SIMD4(0.72, 0, 0, 0)
            let i0 = m.addVertex(a, normal: sceneUp)
            let i1 = m.addVertex(b, normal: sceneUp)
            m.extra = SIMD4(1, 0, 0, 0)
            let i2 = m.addVertex(c, normal: sceneUp)
            let i3 = m.addVertex(dd, normal: sceneUp)
            // Wind so the face points up.
            if simd_cross(b - a, c - a).y > 0 { m.addTriangle(i0, i1, i2); m.addTriangle(i0, i2, i3) }
            else { m.addTriangle(i0, i2, i1); m.addTriangle(i0, i3, i2) }
        }
        _ = start
        m.extra = SIMD4(1, 0, 0, 0)
    }

    // MARK: - Helpers

    /// Edge `i` of a CCW ring: start point, unit direction, outward normal, length.
    public static func edge(_ ring: Ring, _ i: Int) -> (LocalPoint, LocalPoint, LocalPoint, Double) {
        let p = ring[i], q = ring[(i + 1) % ring.count]
        let d = q - p
        let len = simd_length(d)
        let dir = len > 0 ? d / len : LocalPoint(1, 0)
        return (p, dir, LocalPoint(dir.y, -dir.x), len)
    }

    static func longestEdge(_ ring: Ring) -> Int {
        (0..<ring.count).max { simd_distance(ring[$0], ring[($0 + 1) % ring.count]) < simd_distance(ring[$1], ring[($1 + 1) % ring.count]) } ?? 0
    }

    static func hexColor(_ v: String) -> String? {
        let named: [String: String] = [
            "white": "#E8E3D8", "black": "#3A3D42", "grey": "#9A9A97", "gray": "#9A9A97", "red": "#A4564A",
            "brown": "#7A5E4A", "beige": "#D2C3A6", "yellow": "#DCC87E", "green": "#728F66", "blue": "#7088A3",
            "tan": "#C4A886", "darkgrey": "#5E6064", "darkgray": "#5E6064", "lightgrey": "#C6C5C0", "lightgray": "#C6C5C0",
        ]
        let s = v.trimmingCharacters(in: .whitespaces).lowercased()
        if let n = named[s] { return n }
        if s.hasPrefix("#"), s.count == 7, UInt32(s.dropFirst(), radix: 16) != nil { return s }
        return nil
    }

    func addWalls(_ ring: Ring, z0: Double, z1: Double, into m: inout MeshBuffers) {
        for i in 0..<ring.count {
            let p = ring[i], q = ring[(i + 1) % ring.count]
            let d = q - p
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            m.addFace([P(p, z0), P(q, z0), P(q, z1), P(p, z1)], facing: D(LocalPoint(d.y, -d.x) / len))
        }
    }

    func addWindow(origin: LocalPoint, dir: LocalPoint, normal: LocalPoint, sCenter: Double, width: Double,
                   z0: Double, z1: Double, glass: Paint, trim: Paint, into m: inout MeshBuffers) {
        guard width > 0.4 else { return }
        let s0 = sCenter - width / 2, s1 = sCenter + width / 2, f = 0.1
        m.paint = glass
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: z0, z1: z1, offset: 0.03)
        let seed = m.extra
        m.extra = SIMD4(1, 0, 0, 0)
        m.paint = trim
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z0 - f, z1: z0, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z1, z1: z1 + f, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s0, z0: z0, z1: z1, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s1, s1: s1 + f, z0: z0, z1: z1, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: (z0 + z1) / 2 - 0.03, z1: (z0 + z1) / 2 + 0.03, offset: 0.05)
        m.extra = seed
    }

    /// Steps descending from `height` to the ground, starting at `top` and going out along `n`.
    func addSteps(at top: LocalPoint, dir: LocalPoint, n: LocalPoint, width: Double, height: Double, foundation: Paint, into m: inout MeshBuffers) {
        guard height > 0.12 else { return }
        let count = max(1, Int((height / 0.18).rounded()))
        let rise = height / Double(count + 1)
        m.paint = foundation
        for k in 0..<count {
            let z1 = height - rise * Double(k + 1)
            let c = top + n * (0.15 + 0.3 * Double(k))
            m.addBox(center: c, u: dir, halfLength: width / 2, halfWidth: 0.15, z0: 0, z1: z1)
        }
    }
}

@inline(__always)
func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
    let t = min(1, max(0, (x - e0) / max(e1 - e0, 1e-9)))
    return t * t * (3 - 2 * t)
}
