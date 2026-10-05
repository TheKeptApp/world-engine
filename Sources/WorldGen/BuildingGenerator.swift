import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// How much detail to generate.
public enum DetailLevel: Sendable {
    /// Street level: windows, doors, porches, trim, chimneys.
    case full
    /// Context: walls and roofs only.
    case simple
}

/// A generated building plus facts the scene and tests use.
public struct GeneratedBuilding: Sendable {
    public enum Role: String, Sendable { case house, garage, shed, block }
    public enum RoofShape: String, Sendable { case gabled, hipped, flat, slab }

    public var ref: OSMRef
    public var role: Role
    public var footprintClass: FootprintClass
    public var roofShape: RoofShape
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

    public func generate(_ b: Building, palette: inout Palette, detail: DetailLevel) -> GeneratedBuilding {
        let role = Self.role(of: b)
        let shape = FootprintAnalysis(b.footprint)
        var rng = b.ref.random("building")
        let houses = profile.houses

        // Colors: OSM tags first, then the profile.
        func color(_ tag: String, _ list: [StyleProfile.WeightedColor], _ salt: String) -> Int {
            if let hex = b.tags[tag].flatMap(Self.hexColor) { return palette.slot(hex: hex) }
            var r = b.ref.random(salt)
            return palette.slot(hex: r.pick(list) { $0.weight }.color)
        }
        let siding = Paint(slot: color("building:colour", houses.sidingPalette, "siding"), shade: Float(rng.range(0.94, 1.06)))
        let trim = Paint(slot: color("trim:colour", houses.trimPalette, "trim"))
        let roofPaint = Paint(slot: color("roof:colour", houses.roofPalette, "roof"), shade: Float(rng.range(0.92, 1.06)))
        let door = Paint(slot: color("door:colour", houses.doorPalette, "door"))
        let foundation = Paint(slot: palette.named("foundation"))
        let glass = Paint(slot: palette.named("glass"), flags: .glass)

        var g = GeneratedBuilding(ref: b.ref, role: role, footprintClass: shape.kind, roofShape: .flat)
        let fp = b.footprint

        // Roof shape: OSM roof:shape, else footprint class + profile mix.
        let mix = role == .garage ? profile.garages.roofMix : houses.roofMix
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
        case (.block, _): roofShape = b.roofShape == nil ? .flat : roofShape
        case (_, .irregular): roofShape = .flat
        default: break
        }
        if roofShape != .flat, roofShape != .slab, shape.roofRects.isEmpty { roofShape = .flat }
        g.roofShape = roofShape

        // Heights.
        let pitch = role == .garage ? rng.range(18, 28) : rng.range(houses.roofPitchDegrees)
        let overhang = role == .shed ? 0.15 : rng.range(houses.overhangMeters) * (role == .garage ? 0.6 : 1)
        let F: Double = switch role {
        case .house: rng.range(houses.foundationMeters)
        case .garage: 0.12
        case .shed: 0.05
        case .block: 0.3
        }
        let mainRect = shape.roofRects.max { $0.area < $1.area } ?? shape.obb
        let rise = (roofShape == .gabled || roofShape == .hipped) ? Roofs.rise(mainRect, pitch: pitch) : 0
        let H: Double
        if role == .garage {
            H = b.levels.map { $0 * 2.9 } ?? rng.range(profile.garages.wallHeightMeters)
        } else if role == .shed {
            H = min(b.height.top, 2.4)
        } else if let levels = b.levels, b.height.source == .levels {
            H = F + max(1, levels) * 2.9
        } else {
            H = max(F + 2.6, b.height.top - rise)
        }
        g.eaveHeight = H
        g.topHeight = H + rise

        var m = MeshBuffers()

        // Walls: foundation band, then siding.
        let parapet = (roofShape == .flat && role != .shed) ? (role == .block ? 0.6 : 0.35) : 0
        for ring in [fp.outer] + fp.holes {
            m.paint = foundation
            if detail == .full, F > 0.05 { addWalls(ring, z0: 0, z1: F, into: &m) }
            m.paint = siding
            addWalls(ring, z0: detail == .full ? F : 0, z1: H + parapet, into: &m)
        }

        // Roof.
        let roofStyle = Roofs.Style(pitchDegrees: pitch, overhang: overhang, roof: roofPaint, gableWall: siding, trim: trim)
        switch roofShape {
        case .gabled:
            for r in shape.roofRects { Roofs.gabled(r, eave: H, style: roofStyle, into: &m) }
        case .hipped:
            for r in shape.roofRects { Roofs.hipped(r, eave: H, style: roofStyle, into: &m) }
        case .flat:
            Roofs.flatWithParapet(fp, z: H, parapet: parapet, roof: roofPaint, wall: siding, into: &m)
        case .slab:
            Roofs.slab(shape.obb, z: H, thickness: 0.12, overhang: overhang, paint: roofPaint, into: &m)
        }
        if roofShape == .gabled || roofShape == .hipped {
            for r in shape.flatRects { Roofs.slab(r, z: H, thickness: 0.15, overhang: 0.1, paint: roofPaint, into: &m) }
        }

        // Openings.
        let ring = fp.outer
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
            break
        }

        if detail == .full {
            let spacing = rng.range(houses.windowSpacingMeters)
            let winW = rng.range(0.9, 1.25), winH = rng.range(1.2, 1.55)
            let stories = role == .garage ? 1 : max(1, Int(((H - F) + 0.4) / 2.9))
            var doorSpan: (edge: Int, s0: Double, s1: Double)?

            if role == .house, let e = g.frontEdge {
                let (p, dir, n, len) = Self.edge(ring, e)
                var r = b.ref.random("door")
                let doorS = len > 6 ? len / 2 + r.range(-0.2, 0.2) * len : len / 2
                let porch = r.chance(houses.porchLikelihood) && len >= 4
                g.hasPorch = porch
                let porchW = porch ? min(len - 0.4, r.range(3.0, 5.5)) : 1.6
                let porchS0 = max(0.2, min(len - 0.2 - porchW, doorS - porchW / 2))
                doorSpan = (e, porchS0 - 0.3, porchS0 + porchW + 0.3)
                // Door with trim frame.
                m.paint = trim
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.6, s1: doorS + 0.6, z0: F, z1: F + 2.25, offset: 0.025)
                m.paint = door
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.48, s1: doorS + 0.48, z0: F, z1: F + 2.12, offset: 0.045)
                let eave = H - overhang * tan(pitch * .pi / 180)
                if porch {
                    let depth = r.range(1.8, 2.5)
                    let c = p + dir * (porchS0 + porchW / 2) + n * (depth / 2)
                    m.paint = foundation
                    m.addBox(center: c, u: dir, halfLength: porchW / 2, halfWidth: depth / 2, z0: 0, z1: F)
                    let roofZ = max(F + 2.45, min(F + 2.7, eave - 0.05))
                    m.paint = trim
                    for sx in [-1.0, 1.0] {
                        let post = c + dir * (sx * (porchW / 2 - 0.15)) + n * (depth / 2 - 0.15)
                        m.addBox(center: post, u: dir, halfLength: 0.1, halfWidth: 0.1, z0: F, z1: roofZ)
                    }
                    Roofs.slab(OrientedRect(center: c, u: dir, halfLength: porchW / 2, halfWidth: depth / 2),
                               z: roofZ, thickness: 0.16, overhang: 0.15, paint: roofPaint, into: &m)
                    addSteps(at: p + dir * doorS + n * depth, dir: dir, n: n, width: 1.4, height: F, foundation: foundation, into: &m)
                } else {
                    // Stoop + small canopy.
                    let c = p + dir * doorS + n * 0.6
                    m.paint = foundation
                    m.addBox(center: c, u: dir, halfLength: 0.8, halfWidth: 0.6, z0: 0, z1: F)
                    Roofs.slab(OrientedRect(center: p + dir * doorS + n * 0.45, u: dir, halfLength: 0.8, halfWidth: 0.45),
                               z: F + 2.4, thickness: 0.1, overhang: 0.05, paint: roofPaint, into: &m)
                    addSteps(at: p + dir * doorS + n * 1.2, dir: dir, n: n, width: 1.2, height: F, foundation: foundation, into: &m)
                }
                // Foundation bushes along the front, skipping the door/porch.
                var bush = b.ref.random("bushes")
                var s = 0.8
                while s < len - 0.6 {
                    if !(s > porchS0 - 0.8 && s < porchS0 + porchW + 0.8) && bush.chance(0.75) {
                        g.bushSpots.append((p + dir * s + n * 0.9, Float(bush.range(0.7, 1.2))))
                    }
                    s += bush.range(1.4, 2.2)
                }
            }

            if role == .garage, let e = g.garageDoorEdge {
                let (p, dir, n, len) = Self.edge(ring, e)
                let doubleDoor = len >= profile.garages.doubleDoorMinWidthMeters
                let w = min(len - 0.6, doubleDoor ? 4.9 : 2.6)
                let s0 = (len - w) / 2
                m.paint = trim
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 - 0.12, s1: s0 + w + 0.12, z0: F, z1: F + 2.25, offset: 0.025)
                m.paint = Paint(slot: trim.slot, shade: 0.93)
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0, s1: s0 + w, z0: F, z1: F + 2.12, offset: 0.04)
                // Panel lines.
                m.paint = Paint(slot: siding.slot, shade: 0.75)
                for k in 1..<4 {
                    let z = F + 2.12 * Double(k) / 4
                    m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 + 0.05, s1: s0 + w - 0.05, z0: z - 0.02, z1: z + 0.02, offset: 0.05)
                }
                doorSpan = (e, s0 - 0.3, s0 + w + 0.3)
            }

            if role == .house || role == .block || (role == .garage && rng.chance(0.4)) {
                for e in 0..<ring.count {
                    let (p, dir, n, len) = Self.edge(ring, e)
                    guard len >= 2.0 else { continue }
                    if role == .garage, e == g.garageDoorEdge { continue }
                    let count = max(1, Int((len - 0.6) / spacing))
                    let step = len / Double(count)
                    for story in 0..<(role == .garage ? 1 : stories) {
                        let z0 = F + Double(story) * 2.9 + (story == 0 ? 0.85 : 0.75)
                        let z1 = min(z0 + winH, H - 0.3)
                        guard z1 - z0 > 0.6 else { continue }
                        for k in 0..<count {
                            let sc = step * (Double(k) + 0.5)
                            if story == 0, let span = doorSpan, span.edge == e, sc + winW / 2 > span.s0, sc - winW / 2 < span.s1 { continue }
                            addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: min(winW, step - 0.4), z0: z0, z1: z1,
                                      glass: glass, trim: trim, into: &m)
                        }
                    }
                }
            }

            // Chimney on some pitched house roofs.
            if role == .house, roofShape == .gabled || roofShape == .hipped {
                var r = b.ref.random("chimney")
                if r.chance(houses.chimneyLikelihood) {
                    let along = (mainRect.halfLength - 0.9) * (r.chance(0.5) ? 1 : -1)
                    let c = mainRect.point(along, mainRect.halfWidth * 0.35)
                    m.paint = Paint(slot: palette.named("chimney"))
                    m.addBox(center: c, u: mainRect.u, halfLength: 0.35, halfWidth: 0.45, z0: H - 0.5, z1: g.topHeight + 0.8)
                }
            }
        }
        g.mesh = m
        return g
    }

    // MARK: - Helpers

    /// Edge `i` of a CCW ring: start point, unit direction, outward normal, length.
    static func edge(_ ring: Ring, _ i: Int) -> (LocalPoint, LocalPoint, LocalPoint, Double) {
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
            "white": "#F2F0EA", "black": "#3A3A3C", "grey": "#9A9A9A", "gray": "#9A9A9A", "red": "#A4483E",
            "brown": "#7A5A44", "beige": "#D8C8A8", "yellow": "#E3CD7A", "green": "#6F8F5E", "blue": "#6F8AA8",
            "tan": "#C8A882", "darkgrey": "#5E5E62", "darkgray": "#5E5E62", "lightgrey": "#C8C8C8", "lightgray": "#C8C8C8",
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
        let s0 = sCenter - width / 2, s1 = sCenter + width / 2, f = 0.09
        m.paint = glass
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: z0, z1: z1, offset: 0.03)
        m.paint = trim
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z0 - f, z1: z0, offset: 0.05)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z1, z1: z1 + f, offset: 0.05)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s0, z0: z0, z1: z1, offset: 0.05)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s1, s1: s1 + f, z0: z0, z1: z1, offset: 0.05)
        // Muntin (center bar) for a classic look.
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: (z0 + z1) / 2 - 0.03, z1: (z0 + z1) / 2 + 0.03, offset: 0.045)
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
