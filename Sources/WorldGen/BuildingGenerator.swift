import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// How much detail to generate.
public enum DetailLevel: String, Sendable, Codable {
    /// Street level: windows, doors, porches, trim, chimneys, baked AO bands.
    case full
    /// Context: walls and roofs only (the far building LOD).
    case simple
}

/// Building level of detail by distance (regions-chicagoland-miami §4, v2 §8.1).
public enum BuildingLOD: Int, Sendable, Codable, CaseIterable, Comparable {
    /// 0–50 m: the full family grammar (dormers, chimney cap, trim, porches, rear stairs).
    case near
    /// 50–150 m: masses, roof assembly with eaves, chimney body, window rhythm, porch silhouettes.
    case mid
    /// 150–600 m: body and roof outline only (no overhangs, openings or details).
    case far
    /// Beyond 600 m: one extruded skyline mass per building.
    case skyline

    public static func < (a: BuildingLOD, b: BuildingLOD) -> Bool { a.rawValue < b.rawValue }

    /// The LOD for a camera distance in meters.
    public static func forDistance(_ d: Double) -> BuildingLOD {
        d < 50 ? .near : d < 150 ? .mid : d < 600 ? .far : .skyline
    }
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
    /// Family for any role that has one (house families and block families such as six-flats).
    public var family: String?
    /// The style profile that generated this building (zones can differ within one area).
    public var profileID: String?
    /// Front door: a point on the wall and the outward normal (walks start here). Nil without a door.
    public var entry: (point: LocalPoint, normal: LocalPoint)?
    /// Which color tuple (0 = A, 1 = B) and the resolved hex colors [wall, trim, door, roof].
    public var colorSet = 0
    public var colors: [String] = []
    public var floors = 1
    /// True when floors came from OSM `building:levels`; false when inferred from the type.
    public var floorsFromOSM = false
    public var mesh = MeshBuffers()
    public var lod = BuildingLOD.near
    /// Edge index (outer ring) with the front door, if any.
    public var frontEdge: Int?
    /// Edge index with the garage door, if any.
    public var garageDoorEdge: Int?
    /// True if the garage door faces an alley/service road (vs. a street).
    public var garageDoorFacesAlley = false
    public var eaveHeight: Double = 0
    /// Ground-floor (foundation) height: the top of the stoop or porch floor.
    public var floorHeight: Double = 0
    /// Covered porch built from family details (house-details-v1): its plan rectangle.
    public var porchOutline: [LocalPoint] = []
    public var topHeight: Double = 0
    public var hasPorch = false
    public var porchStyle: String?
    /// Roof masses in the assembly (1 = one simple roof).
    public var roofMasses = 0
    /// A flush crossing gable was added on the street side.
    public var crossGable = false
    public var dormers = 0
    public var hasChimney = false
    public var hasRearPorch = false
    /// Set when a conservative sealed envelope replaced a decomposed roof (flagged for review).
    public var roofFallback: String?
    /// Triangles of optional roof detail (crossing gable, dormers, chimney), capped at 200.
    public var optionalRoofTriangles = 0
    /// Where to plant foundation bushes (local points) with a seeded scale.
    public var bushSpots: [(LocalPoint, Float)] = []
    /// Entry kit on the front door (portico | vestibule | surround), nil for the plain stoop/canopy.
    public var entryKit: String?
    /// Inferred facade elements (not in the mapped footprint): plan outlines of street bays added
    /// in front of the facade. Logged for review like `roofFallback`.
    public var inferredBays: [[LocalPoint]] = []
    /// Mapped footprint protrusions dressed as bays.
    public var mappedBays = 0
    /// The chimney stands on a side wall as a shallow masonry breast (inferred, 0.25–0.4 m proud).
    public var chimneyBreast = false
    /// Gangway window stacks (one window per story each) on side walls facing a 1–3 m gap.
    public var gangwayStacks = 0
    /// Mapped footprint protrusions on side walls dressed with windows.
    public var sideBays = 0
}

public struct BuildingGenerator: Sendable {
    public var profile: StyleProfile
    public var context: StreetContext
    /// Family grammar (roof assemblies, facade kits).
    public var families: HouseFamilyLibrary = .bundled
    /// Other buildings' footprints: keeps rear porches out of neighbors. Nil = no such details.
    public var obstacles: PolygonIndex?
    /// Phone-size house contrast values (`look.json` houseContrast).
    static var contrast: LookSpec.HouseContrast? { LookSpec.bundled?.houseContrast }

    /// Combined optional roof detail per near building (regions spec §4 table).
    public static let optionalRoofCap = 200
    /// Small `building=yes` outbuildings standing behind a principal building on the same block
    /// side (computed per area by the scene): detached garages even without an alley.
    public var detachedGarages: Set<OSMRef> = []
    /// Size thresholds resolved for this area (percentiles of local house footprints); nil = the profile's.
    public var areaThresholds: StyleProfile.Thresholds?
    var thresholds: StyleProfile.Thresholds { areaThresholds ?? profile.typeThresholds }

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
        let t = thresholds
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

    /// The house type as chosen by the profile and the family grammar (kept for callers of the
    /// original API).
    public func houseType(for b: Building, shape: FootprintAnalysis, frontEdge: Int?) -> (StyleProfile.HouseType, String) {
        houseFamily(for: b, shape: shape, frontEdge: frontEdge)
    }

    // MARK: - Generation

    public func generate(_ b: Building, palette: inout Palette, detail: DetailLevel) -> GeneratedBuilding {
        // `.simple` keeps the old context budget (walls and roofs); the richer mid LOD is opt-in.
        generate(b, palette: &palette, lod: detail == .full ? .near : .far)
    }

    /// The role with this profile's thresholds and the street context: `building=yes` up to the
    /// profile's huge-house area is a house (large suburban houses are not blocks), and a small
    /// `building=yes` beside a mapped alley is an alley garage (footprint and access evidence).
    public func role(for b: Building) -> GeneratedBuilding.Role {
        let base = Self.role(of: b)
        guard b.type == "yes" else { return base }
        let area = b.footprint.area
        if base == .house, area >= 14, area <= 75, b.levels.map({ $0 <= 1.5 }) ?? true,
           context.alleyEdge(of: b.footprint.outer, radius: 9) != nil, context.frontEdge(of: b.footprint.outer, radius: 9) == nil {
            return .garage
        }
        if base == .house, detachedGarages.contains(b.ref) { return .garage }
        // Absolute huge-house area here: relative thresholds are percentiles of houses already under
        // the static 250 m² rule, so they can't decide whether a larger building is a house.
        if base == .block, area < profile.typeThresholds.hugeArea, b.levels.map({ $0 <= 3 }) ?? true { return .house }
        return base
    }

    public func generate(_ b: Building, palette: inout Palette, lod: BuildingLOD) -> GeneratedBuilding {
        let role = role(for: b)
        let shape = FootprintAnalysis(b.footprint)
        let fp = b.footprint
        let ring = fp.outer
        var g = GeneratedBuilding(ref: b.ref, role: role, footprintClass: shape.kind, roofShape: .flat)
        g.lod = lod
        g.profileID = profile.id

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

        // Family, colors, dimensions.
        var rng = b.ref.random("building")
        let type: StyleProfile.HouseType? = switch role {
        case .house: houseFamily(for: b, shape: shape, frontEdge: g.frontEdge).0
        case .block: blockFamily(for: b, shape: shape)
        default: nil
        }
        g.houseType = role == .house ? type?.id : nil
        g.family = type?.id
        let grammar = families.grammar(type?.id)
        let facade = grammar.facade ?? HouseFamilyGrammar.Facade()
        // House details apply to houses and block families (not garages or sheds).
        let details = role == .house || role == .block ? grammar.details : nil
        let tuples: [[String]] = switch role {
        case .garage: profile.garage.colors
        case .shed: profile.shed.colors
        default: type?.colors ?? profile.houseTypes[0].colors
        }
        var cr = b.ref.random("palette")
        g.colorSet = Int(cr.next() % UInt64(max(1, tuples.count)))
        var tuple = tuples[g.colorSet]
        if let floors = families.toneFloors {
            tuple[0] = HouseFamilyLibrary.lifted(tuple[0], gain: floors.wallGain, floor: floors.wall)
            tuple[3] = HouseFamilyLibrary.lifted(tuple[3], gain: floors.roofGain, floor: floors.roof)
        }
        if let wall = b.tags["building:colour"].flatMap(Self.hexColor) { tuple[0] = wall }
        if let roof = b.tags["roof:colour"].flatMap(Self.hexColor) { tuple[3] = roof }
        // The profile's light trim stays the gable / stucco panel colour; the family trim colour
        // (house-details-v1) takes casings, fascia, soffits, corner boards and porch posts.
        let panelHex = tuple[1]
        // House contrast (house-contrast-v1) type: trim, roof, glass, soffit, porch-underside and eave-band values.
        // Storeys aren't final yet here: mapped levels, else the family's first floor count.
        let contrastType = details != nil ? Self.contrast?.type(family: g.family, floors: b.levels.map { Int($0.rounded()) } ?? type?.floors.first ?? 2) : nil
        if let range = details?.trim, let hex = HouseDetailColours.pick(range, ref: b.ref, salt: "trim-colour") { tuple[1] = hex }
        // house-contrast-v1 defines trim and roof per house type: they replace the family ranges (owner 7 Oct).
        // Mapped roof:colour still wins.
        // Chicago brick families: one of the pack's brick wall swatches per building, unless the wall colour is mapped.
        let brickWalls = contrastType != nil && (Self.contrast?.brickWallFamilies ?? []).contains(g.family ?? "")
        if let t = contrastType {
            tuple[1] = t.trim
            if b.tags["roof:colour"].flatMap(Self.hexColor) == nil { tuple[3] = t.roof }
            let walls = Self.contrast?.brickWalls ?? []
            if brickWalls, !walls.isEmpty, b.tags["building:colour"].flatMap(Self.hexColor) == nil {
                var wr = b.ref.random("brick-wall")
                tuple[0] = walls[Int(wr.next() % UInt64(walls.count))]
            }
        }
        g.colors = tuple
        let wallPaint = Paint(slot: palette.slot(hex: tuple[0]), shade: Float(rng.range(0.97, 1.03)))
        let trim = Paint(slot: palette.slot(hex: tuple[1]))
        let doorPaint = Paint(slot: palette.slot(hex: tuple[2]))
        let roofPaint = Paint(slot: palette.slot(hex: tuple[3]), shade: Float(rng.range(0.96, 1.04)))
        // Brick families stand on a stone base course in the trim (stone) colour (house-contrast-v1 paint-overs).
        let foundation = Paint(slot: brickWalls ? palette.slot(hex: tuple[1]) : palette.named("foundation"))
        let glass = Paint(slot: contrastType.map { palette.slot(hex: $0.glass) } ?? palette.named("windowDay"), flags: .glass)
        var sideWall: Paint?
        if let sides = facade.sideWall, !sides.isEmpty, b.tags["building:colour"] == nil {
            var sr = b.ref.random("side-wall")
            sideWall = Paint(slot: palette.slot(hex: sides[Int(sr.next() % UInt64(sides.count))]), shade: wallPaint.shade)
        }

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
        case (.house, .irregular) where fp.holes.isEmpty && shape.rectangularity >= 0.6: break // conservative envelope
        case (_, .irregular): roofShape = .flat
        default: break
        }
        if roofShape != .flat, roofShape != .slab, shape.roofRects.isEmpty, shape.kind != .irregular { roofShape = .flat }

        let pitchRange: [Double] = switch role {
        case .garage: profile.garage.pitch
        case .shed: profile.shed.pitch
        default: type?.pitch ?? [20, 30]
        }
        let overhangRange: [Double] = switch role {
        case .garage: profile.garage.overhang
        case .shed: profile.shed.overhang
        default: details?.eave ?? type?.overhang ?? [0.3, 0.5]
        }
        let pitch = rng.range(pitchRange)
        let overhang = rng.range(overhangRange)
        let F: Double = switch role {
        case .house: rng.range(details?.foundation ?? profile.foundationMeters)
        case .garage: 0.12
        case .shed: 0.05
        case .block: facade.stoop == true ? rng.range(details?.foundation ?? profile.foundationMeters) : 0.3
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
                // A measured height without levels (e.g. Overture/Microsoft footprints) sets the
                // storey count, so windows fit the real wall instead of the family's default floors.
                if osmLevels == nil { g.floors = max(1, Int(((H - F) / perFloor).rounded())) }
            } else {
                H = F + Double(floors) * perFloor
            }
        }

        // Roof assembly for pitched roofs.
        var plan: RoofPlan?
        if roofShape == .gabled || roofShape == .hipped, lod != .skyline {
            let frontEdge = role == .garage ? g.garageDoorEdge : g.frontEdge
            let frontNormal = frontEdge.map { Self.edge(ring, $0).2 }
            let rr = grammar.roof
            var recipe = RoofRecipe(mainForm: roofShape == .hipped ? .hip : .gable, wingForm: rr?.wingForm, pitch: pitch, overhang: overhang)
            recipe.ridge = rr?.ridge ?? .long
            if role == .house, b.roofShape == nil {
                recipe.crossGable = rr?.crossGable ?? 0
                recipe.crossGableWidth = rr?.crossGableWidth ?? recipe.crossGableWidth
                recipe.crossGableCentered = rr?.crossGableCentered ?? false
                recipe.crossGablePitchBoost = rr?.crossGablePitchBoost ?? 0
                recipe.sideCrossGable = rr?.sideCrossGable ?? 0
            }
            var pr = b.ref.random("roof-plan")
            plan = RoofPlanner.plan(footprint: fp, shape: shape, front: frontNormal, recipe: recipe, eave: H, rng: &pr)
            if plan == nil { roofShape = .flat }
        }
        g.roofShape = roofShape
        let pitched = plan != nil
        let parapet: Double = roofShape == .flat && role != .shed ? rng.range(type?.parapet ?? [0.3, 0.4]) : 0

        if lod == .skyline {
            g.eaveHeight = H
            g.topHeight = H + max(parapet, rise)
            g.mesh = skylineMass(fp, shape: shape, top: H + (pitched || rise > 0 ? rise * 0.5 : parapet), wall: wallPaint, roof: roofPaint)
            return g
        }

        let envelope: RoofEnvelope? = plan.map { p in
            RoofEnvelope(masses: lod == .far ? p.masses.map { var m = $0; m.overhang = min(m.overhang, 0.35); return m } : p.masses, clip: p.clip)
        }
        g.eaveHeight = H
        g.floorHeight = F
        g.topHeight = envelope.map { max(H, $0.topHeight) } ?? H + rise + parapet
        if let plan {
            g.roofMasses = plan.masses.count
            g.crossGable = plan.crossGable != nil
            g.roofFallback = plan.fallback
        }

        var m = MeshBuffers()
        let near = lod == .near
        let streetFacing = streetFacingEdges(ring, front: g.frontEdge)
        let wallFor: (Int) -> Paint = { e in sideWall != nil && !streetFacing.contains(e) ? sideWall! : wallPaint }
        let panel = Paint(slot: palette.slot(hex: panelHex))
        let gablePaint: Paint? = (facade.gablePanel == true || facade.halfTimber == true) ? Paint(slot: panel.slot, shade: 0.97) : nil

        // Walls in bands so baked AO has vertices to live on: base contact, eave shadow.
        for (ri, wallRing) in ([fp.outer] + fp.holes).enumerated() {
            let paintFor: (Int) -> Paint = ri == 0 ? wallFor : { _ in wallPaint }
            if near, F > 0.05 {
                m.paint = foundation
                addWalls(wallRing, z0: 0, z1: F, into: &m)
            }
            let z0 = near ? F : 0
            if let envelope {
                envelope.emitWalls(wallRing, base: z0, bandTop: near ? H - (Self.contrast?.eaveBandHeight ?? 0.7) : H, fallbackTop: H, wall: paintFor,
                                   gableFrom: H, gablePaint: gablePaint, into: &m)
            } else {
                let top = H + parapet
                if near, top - z0 > 1.2 {
                    addWalls(wallRing, z0: z0, z1: top - (Self.contrast?.eaveBandHeight ?? 0.7), paint: paintFor, into: &m)
                    addWalls(wallRing, z0: top - (Self.contrast?.eaveBandHeight ?? 0.7), z1: top, paint: paintFor, into: &m)
                } else {
                    addWalls(wallRing, z0: z0, z1: top, paint: paintFor, into: &m)
                }
            }
        }
        // R1: contact darkening at the base, softer eave occlusion under pitched roofs.
        let eaveAO: Float = pitched ? 0.8 : 1.0
        m.bakeAO(from: 0) { p, _ in
            let y = Double(p.y)
            let base = 0.72 + 0.28 * smoothstep(0, max(F, 0.6) + 0.3, y)
            let eave = pitched ? 1 - (1 - Double(eaveAO)) * smoothstep(H - 0.7, H, y) * (1 - smoothstep(H + 0.1, H + 0.6, y)) : 1
            return Float(base * eave)
        }

        // Roof.
        let roofStart = m.positions.count
        if let envelope {
            var paints = RoofPaints(roof: roofPaint, trim: trim, wall: wallPaint, gable: gablePaint, fascia: near ? details?.fascia ?? 0.22 : 0.18)
            // Softened roof edges (house-details-v1): one 2.5 cm chamfer on street-facing fascia and rakes, near only.
            if near, details?.corners != nil, let f = g.frontEdge {
                paints.bevel = 0.025
                paints.bevelToward = Self.edge(ring, f).2
            }
            envelope.emitRoof(paints: paints, soffits: lod != .far, fascia: lod != .far, into: &m)
        } else {
            let roofStyle = Roofs.Style(pitchDegrees: pitch, overhang: overhang, roof: roofPaint, gableWall: wallPaint, trim: trim, fascia: 0.22)
            _ = roofStyle
            switch roofShape {
            case .flat: Roofs.flatWithParapet(fp, z: H, parapet: parapet, roof: roofPaint, wall: wallPaint, into: &m)
            case .slab: Roofs.slab(shape.obb, z: H, thickness: 0.12, overhang: lod == .far ? 0 : overhang, paint: roofPaint, into: &m)
            default: break
            }
        }
        // Soffits (down-facing) sit in the eave shadow; parapet insides get mild occlusion.
        m.bakeAO(from: roofStart) { _, n in n.y < -0.5 ? 0.7 : 1 }
        // Phone-size contrast (P3 / owner: geometry detail doesn't read, value does). Baked AO only
        // dims ambient light, so detail families also darken the base colour where shade lives:
        // soffits, and a band on the wall top under eaves and cornices. House-details families only.
        if let t = contrastType, let hc = Self.contrast, near {
            let top = pitched ? H : H + parapet
            for i in 0..<roofStart where abs(m.normals[i].y) < 0.3 {
                let y = Double(m.positions[i].y)
                guard y > top - hc.eaveBandHeight - 0.05, y < top + 0.05 else { continue }
                m.paints[i].y *= Float(1 - (1 - t.eaveShadow) * smoothstep(top - hc.eaveBandHeight, top, y))
            }
        }
        // The crossing gable's own fragments count against the optional roof budget.
        var optional = 0
        if let plan, let cg = plan.crossGable, let envelope {
            let frags = envelope.fragments.filter { $0.mass == cg }
            optional += frags.reduce(0) { $0 + max(0, $1.polygon.count - 2) * ($1.overhang ? 2 : 1) } + 8
        }

        var ctx = BuildContext(b: b, ring: ring, type: type, grammar: grammar, F: F, H: H, parapet: parapet, pitch: pitch,
                               overhang: overhang, wall: wallPaint, sideWall: sideWall, trim: trim, door: doorPaint, roof: roofPaint,
                               foundation: foundation, glass: glass, panel: panel, mainRect: mainRect, lod: lod, envelope: envelope, plan: plan,
                               streetFacing: streetFacing, floors: max(1, g.floors),
                               mappedBays: facade.mappedBays == true && (role == .house || role == .block)
                                   ? mappedBays(ring, front: g.frontEdge, streetFacing: streetFacing) : [])
        if brickWalls, let t = contrastType, near {
            ctx.reveal = Paint(slot: palette.slot(hex: t.soffit))
            ctx.stoneOpenings = true
        }
        if lod <= .mid {
            if facade.sideBays == true, role == .house || role == .block {
                ctx.sideBays = sideBayEdges(ring, front: g.frontEdge, streetFacing: streetFacing)
            }
            if role == .house { ctx.breast = planChimneyBreast(ctx, front: g.frontEdge) }
        }
        if lod <= .mid {
            addOpenings(ctx, &g, palette: &palette, into: &m)
            addFacadeDetails(ctx, &g, into: &m)
            addCornersAndFrieze(ctx, into: &m)
            optional += addRoofDetails(ctx, &g, palette: &palette, budget: Self.optionalRoofCap - optional, into: &m)
            if near { addContactSkirt(ring, palette: palette, into: &m) }
        }
        g.optionalRoofTriangles = optional
        if g.entry == nil, let e = g.frontEdge, role == .house || role == .block {
            g.entry = entryPoint(b, type: type, facade: facade, ring: ring, edge: e)
        }
        // House contrast: every down-facing face in the type's soffit colour (roof, dormer and bay soffits,
        // casing heads), porch undersides (below the eave by a storey) in its porch-shadow colour.
        if let t = contrastType, lod != .far {
            let soffit = Float(palette.slot(hex: t.soffit)), porch = Float(palette.slot(hex: t.porchShadow))
            for i in 0..<m.positions.count where m.normals[i].y < -0.5 {
                m.paints[i].x = Double(m.positions[i].y) < H - 1.5 ? porch : soffit
                m.paints[i].y = 1
            }
        }
        g.mesh = m
        return g
    }

    /// The front door's point and outward normal, the same draw `addOpenings` makes (so LODs
    /// without openings still know where the door is, e.g. for front walks).
    func entryPoint(_ b: Building, type: StyleProfile.HouseType?, facade: HouseFamilyGrammar.Facade, ring: Ring, edge e: Int) -> (point: LocalPoint, normal: LocalPoint) {
        let (p, dir, n, len) = Self.edge(ring, e)
        var r = b.ref.random("door")
        var doorAt = type.map { r.pick($0.door) { _ in 1 } } ?? 0.5
        if facade.symmetric == true { doorAt = 0.5 }
        let doorS = min(len - 0.7, max(0.7, len * doorAt))
        return (p + dir * doorS, n)
    }

    /// Edges on the street side: facing the same way as the front edge and close to its line.
    func streetFacingEdges(_ ring: Ring, front: Int?) -> Set<Int> {
        guard let f = front else { return [] }
        let (fp, _, fn, _) = Self.edge(ring, f)
        var out: Set<Int> = [f]
        for e in 0..<ring.count where e != f {
            let (p, dir, n, len) = Self.edge(ring, e)
            let mid = p + dir * (len / 2)
            if simd_dot(n, fn) > 0.5, simd_dot(mid - fp, fn) > -2.5 { out.insert(e) }
        }
        return out
    }

    // MARK: - Openings, porches

    func addOpenings(_ c: BuildContext, _ g: inout GeneratedBuilding, palette: inout Palette, into m: inout MeshBuffers) {
        let role = g.role
        let b = c.b, ring = c.ring, F = c.F, H = c.H
        let facade = c.grammar.facade ?? HouseFamilyGrammar.Facade()
        let details = role == .house || role == .block ? c.grammar.details : nil
        let near = c.lod == .near
        var rng = b.ref.random("openings")
        let win = c.type?.windows ?? StyleProfile.Windows(bay: [2.8, 3.2], width: [0.9, 1.2], height: [1.2, 1.5], broad: nil)
        let bay = rng.range(win.bay)
        var winW = rng.range(win.width), winH = rng.range(win.height)
        if facade.windowWidth != nil || facade.windowHeight != nil {
            // Family window size (own salt: the openings stream above is unchanged).
            var ws = b.ref.random("window-size")
            if let r = facade.windowWidth { winW = ws.range(r) }
            if let r = facade.windowHeight { winH = ws.range(r) }
        } else if facade.tallWindows == true {
            winW = min(winW, 1.0); winH = max(winH, 1.65)
        }
        let stories = role == .garage ? 1 : max(1, g.floors)
        let storyH = (H - F) / Double(stories)
        var doorSpan: (edge: Int, s0: Double, s1: Double)?
        // Household seed for stable lit-window grouping (v2 §10/05).
        var household = b.ref.random("household")
        let householdSeed = Float(household.unit())
        let storefront = facade.storefront == true
        var doorAtS: Double?
        var facadeBay: FacadeBay?

        if role == .house || role == .block, let e = g.frontEdge {
            let (p, dir, n, len) = Self.edge(ring, e)
            var r = b.ref.random("door")
            var doorAt = c.type.map { r.pick($0.door) { _ in 1 } } ?? 0.5
            if facade.symmetric == true { doorAt = 0.5 }
            let doorS = min(len - 0.7, max(0.7, len * doorAt))
            doorAtS = doorS
            g.entry = (p + dir * doorS, n)
            let porch = c.type?.porch
            let porchStyle = facade.porchStyle ?? porch?.style ?? "canopy"
            let wantsPorch = r.chance(facade.porchLikelihood ?? porch?.likelihood ?? 0.3) && len >= 3.5 && !storefront
            g.hasPorch = wantsPorch
            g.porchStyle = wantsPorch ? porchStyle : nil
            // Entry kit (family data), only where no covered porch takes the entry.
            var kit: String?
            if let k = facade.entry, !storefront, !(wantsPorch && porchStyle == "covered") {
                var kr = b.ref.random("entry-kit")
                if kr.chance(facade.entryChance ?? 1) { kit = k }
            }
            var kitHalf: Double?
            if kit == "portico" {
                kitHalf = addPortico(c, edge: e, doorS: doorS, into: &m)
                if kitHalf == nil { kit = nil }
            } else if kit == "vestibule" {
                kitHalf = addVestibule(c, edge: e, doorS: doorS, into: &m)
                if kitHalf == nil { kit = "surround" }
            }
            g.entryKit = kit
            // Door (0.9 × 2.05 m) with trim surround; the vestibule carries its own.
            if kit == "surround" {
                addArchedDoor(c, origin: p, dir: dir, n: n, doorS: doorS, into: &m)
            } else if kit != "vestibule" {
                if near {
                    m.paint = c.trim
                    m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.58, s1: doorS + 0.58, z0: F, z1: F + 2.2, offset: 0.025)
                }
                m.paint = c.door
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS - 0.45, s1: doorS + 0.45, z0: F, z1: F + 2.05, offset: 0.045)
                if near, details?.jambs == true {
                    // Heavy stone surround: jambs either side and a head block (greystone portal).
                    m.paint = c.trim
                    for sx in [-1.0, 1.0] {
                        let a = doorS + sx * 0.56, b2 = doorS + sx * 0.86
                        addLedge(origin: p, dir: dir, normal: n, s0: min(a, b2), s1: max(a, b2), z0: F, z1: F + 2.3, depth: 0.12, ends: true, into: &m)
                    }
                    addLedge(origin: p, dir: dir, normal: n, s0: doorS - 0.94, s1: doorS + 0.94, z0: F + 2.3, z1: F + 2.62, depth: 0.16, ends: true, into: &m)
                } else if near, details?.casings == true {
                    // Door head: a projecting cap over the surround.
                    m.paint = c.trim
                    addLedge(origin: p, dir: dir, normal: n, s0: doorS - 0.66, s1: doorS + 0.66, z0: F + 2.2, z1: F + 2.34, depth: 0.08, ends: true, into: &m)
                }
            }
            let eaveZ = H - c.overhang * tan(c.pitch * .pi / 180)
            let porchKit: PorchLayout? = if kitHalf == nil, wantsPorch, porchStyle == "covered", let spec = details?.porch {
                addPorch(c, spec, profilePorch: porch, edge: e, doorS: doorS, into: &m)
            } else { nil }
            if porchKit == nil, details?.porch != nil, wantsPorch, porchStyle == "covered" {
                // No room for the covered porch: the stoop with a small canopy instead.
                g.porchStyle = "canopy"
            }
            if let hw = kitHalf {
                doorSpan = (e, doorS - hw - 0.3, doorS + hw + 0.3)
            } else if let pk = porchKit {
                doorSpan = (e, pk.s0 - 0.3, pk.s1 + 0.3)
                g.porchOutline = [p + dir * pk.s0, p + dir * pk.s1, p + dir * pk.s1 + n * pk.depth, p + dir * pk.s0 + n * pk.depth]
            } else if wantsPorch, porchStyle == "covered", details?.porch == nil {
                let depth = r.range(porch?.depth ?? [1.6, 2.2])
                let width = min(len - 0.4, max(2.4, len * r.range(porch?.frontage ?? [0.5, 0.8])))
                let s0 = max(0.2, min(len - 0.2 - width, doorS - width / 2))
                doorSpan = (e, s0 - 0.3, s0 + width + 0.3)
                let cc = p + dir * (s0 + width / 2) + n * (depth / 2)
                let start = m.positions.count
                m.paint = c.foundation
                m.addBox(center: cc, u: dir, halfLength: width / 2, halfWidth: depth / 2, z0: 0, z1: F)
                let roofZ = max(F + 2.45, min(F + 2.75, eaveZ - 0.05))
                m.paint = c.trim
                for sx in [-1.0, 1.0] {
                    let post = cc + dir * (sx * (width / 2 - 0.16)) + n * (depth / 2 - 0.16)
                    m.addBox(center: post, u: dir, halfLength: 0.12, halfWidth: 0.12, z0: F, z1: roofZ)
                }
                Roofs.slab(OrientedRect(center: cc, u: dir, halfLength: width / 2, halfWidth: depth / 2),
                           z: roofZ, thickness: 0.2, overhang: 0.15, paint: c.roof, into: &m)
                // Porch floor darker near the wall, ceiling underside in shade, post bases grounded.
                let wallLine = (p, dir, n)
                m.bakeAO(from: start) { pos, nn in
                    let lp = LocalPoint(Double(pos.x), Double(-pos.z))
                    let out = simd_dot(lp - wallLine.0, wallLine.2)
                    if nn.y < -0.5 { return 0.68 }
                    if nn.y > 0.5, Double(pos.y) <= F + 0.01 { return Float(0.74 + 0.26 * smoothstep(0, depth, out)) }
                    return Float(0.8 + 0.2 * smoothstep(F, F + 0.6, Double(pos.y)))
                }
                if near { addSteps(at: p + dir * doorS + n * depth, dir: dir, n: n, width: 1.4, height: F, foundation: c.foundation, into: &m) }
            } else {
                // Stoop or entry with a small canopy (recessed/modern canopies get no posts).
                doorSpan = (e, doorS - 1.0, doorS + 1.0)
                let depth = porch.map { r.range($0.depth) } ?? 1.0
                let start = m.positions.count
                m.paint = c.foundation
                var stoopHalf = 0.8, stoopStair = 1.2
                if let st = details?.stoop {
                    var sr = b.ref.random("stoop")
                    stoopStair = min(sr.range(st.width ?? [1.2, 1.2]), 2 * min(doorS, len - doorS) - (st.cheeks == true ? 0.6 : 0.2))
                    stoopHalf = max(0.8, stoopStair / 2 + (st.cheeks == true ? 0.24 : 0.1))
                }
                m.addBox(center: p + dir * doorS + n * 0.6, u: dir, halfLength: stoopHalf, halfWidth: 0.6, z0: 0, z1: F)
                if kit == "surround" {
                    // The arched stone surround is the entry.
                } else if facade.entryPediment == true {
                    addPediment(at: p + dir * doorS, dir: dir, n: n, z: F + 2.3, paint: c.trim, roof: c.roof, into: &m)
                } else if wantsPorch || porchStyle == "canopy", !storefront {
                    Roofs.slab(OrientedRect(center: p + dir * doorS + n * min(depth, 1.2) / 2, u: dir, halfLength: 0.9, halfWidth: min(depth, 1.2) / 2),
                               z: F + 2.35, thickness: 0.12, overhang: 0.05, paint: roofPaint(c.roof, c.trim, porchStyle), into: &m)
                }
                m.bakeAO(from: start) { _, nn in nn.y < -0.5 ? 0.7 : 1 }
                if let st = details?.stoop {
                    addStair(c, top: p + dir * doorS + n * 1.2, dir: dir, n: n, width: stoopStair, height: F, cheeks: st.cheeks == true,
                             paint: detailPaint(c, st.steps), cheekPaint: detailPaint(c, st.cheekColour ?? st.steps), into: &m)
                } else if near {
                    addSteps(at: p + dir * doorS + n * 1.2, dir: dir, n: n, width: 1.2, height: F, foundation: c.foundation, into: &m)
                }
            }
            // Inferred street bay beside the entry (family data, clear space only).
            if let fb = planBay(c, g, doorSpan: doorSpan, winH: winH) {
                facadeBay = fb
                emitBay(c, fb, win: (winW, winH), lit: householdSeed, into: &m)
                g.inferredBays.append(bayPlan(c, fb))
            }
            // Foundation bushes along the front, skipping the entry (and any bay).
            if !storefront {
                var bush = b.ref.random("bushes")
                var s = 0.8
                let span = doorSpan!
                while s < len - 0.6 {
                    if !(s > span.s0 - 0.5 && s < span.s1 + 0.5) && bush.chance(0.7) {
                        let scale = Float(bush.range(0.7, 1.15))
                        if !(facadeBay.map { s > $0.s0 - 0.4 && s < $0.s1 + 0.4 } ?? false) {
                            g.bushSpots.append((p + dir * s + n * 0.9, scale))
                        }
                    }
                    s += bush.range(1.5, 2.3)
                }
            }
        }

        if role == .garage, let e = g.garageDoorEdge {
            let (p, dir, n, len) = Self.edge(ring, e)
            let doubleDoor = len >= (profile.garage.doubleDoorMinWidthMeters ?? 6)
            let w = min(len - 0.6, doubleDoor ? 5.0 : 2.7)
            let s0 = (len - w) / 2
            if near {
                m.paint = c.trim
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 - 0.12, s1: s0 + w + 0.12, z0: F, z1: F + 2.25, offset: 0.025)
            }
            m.paint = c.door
            m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0, s1: s0 + w, z0: F, z1: F + 2.12, offset: 0.04)
            if near {
                m.paint = Paint(slot: c.door.slot, shade: 0.85)
                for k in 1..<4 {
                    let z = F + 2.12 * Double(k) / 4
                    m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0 + 0.05, s1: s0 + w - 0.05, z0: z - 0.02, z1: z + 0.02, offset: 0.05)
                }
            }
            doorSpan = (e, s0 - 0.3, s0 + w + 0.3)
        }

        if role == .shed, let e = g.frontEdge ?? Optional(Self.longestEdge(ring)) {
            let (p, dir, n, len) = Self.edge(ring, e)
            if len >= 1.2 {
                m.paint = c.door
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: len / 2 - 0.42, s1: len / 2 + 0.42, z0: F, z1: min(H - 0.15, F + 1.9), offset: 0.03)
            }
        }

        // Windows: front facade gets the type's rhythm; sides and rear are sparser (v2 §4.2).
        guard role == .house || role == .block || (role == .garage && rng.chance(0.4)) else { return }
        let bayFaces = Set(c.mappedBays.flatMap { $0 })
        g.mappedBays = c.mappedBays.count
        g.sideBays = c.sideBays.count
        let sideBayFaces = Set(c.sideBays.flatMap { $0 })
        let lintel: Paint? = (facade.lintels == true || c.stoneOpenings) && near ? c.trim : nil
        let relief = near && details?.casings == true
        var shutter: Paint?
        if near, let sh = details?.shutters, let cols = sh.colours {
            var sr = b.ref.random("shutters")
            if sr.chance(sh.chance ?? 1), let hex = HouseDetailColours.pick(cols, ref: b.ref, salt: "shutter-colour") {
                shutter = Paint(slot: palette.slot(hex: hex))
            }
        }
        for e in 0..<ring.count {
            let (p, dir, n, len) = Self.edge(ring, e)
            if role == .garage, e == g.garageDoorEdge { continue }
            let isFront = e == g.frontEdge
            let street = c.streetFacing.contains(e)
            let stoneHere = street || bayFaces.contains(e) ? lintel : nil
            let reliefHere = relief && street && stoneHere == nil
            func lit(_ story: Int, _ k: Int) {
                var wr = StableRandom(UInt64(e), UInt64(story * 31 + k), salt: "lit")
                m.extra = SIMD4(1, min(0.999, householdSeed * 0.6 + Float(wr.unit()) * 0.4), 0, 0)
            }
            func rows(_ height: Double) -> [(Int, Double, Double)] {
                (0..<stories).compactMap { story in
                    let z0 = F + Double(story) * storyH + (story == 0 ? 0.85 : 0.8)
                    let z1 = min(z0 + height, F + Double(story + 1) * storyH - 0.35, H - 0.3)
                    return z1 - z0 > 0.6 ? (story, z0, z1) : nil
                }
            }
            // Mapped bay faces: one window per story on each narrow face.
            if bayFaces.contains(e), len < 2.0 {
                let w = min(winW, len - 0.3)
                guard w > 0.42 else { continue }
                for (story, z0, z1) in rows(winH) where !(storefront && story == 0) {
                    lit(story, 0)
                    addWindow(origin: p, dir: dir, normal: n, sCenter: len / 2, width: w, z0: z0, z1: z1,
                              glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, lintel: len >= w + 0.38 ? stoneHere : nil, into: &m)
                    m.extra = SIMD4(1, 0, 0, 0)
                }
                continue
            }
            // Mapped side-wall bays: windows on each face unless a neighbour touches the bay.
            if sideBayFaces.contains(e), !bayFaces.contains(e) {
                guard let bayFace = c.sideBays.first(where: { $0.contains(e) }), sideGap(c, edge: bayFace[1], reach: 1) > 0.6 else { continue }
                let narrow = len < 2.2
                let w = narrow ? min(winW * 0.85, len - 0.3) : min(winW, len - 0.4)
                guard w > 0.42 else { continue }
                let n2 = !narrow && len >= 2 * w + 1.3
                let centers = n2 ? [len / 2 - (w / 2 + 0.3), len / 2 + (w / 2 + 0.3)] : [len / 2]
                for (story, z0, z1) in rows(winH) where !(storefront && story == 0) {
                    for (k, sc) in centers.enumerated() {
                        lit(story, 80 + k)
                        addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: w, z0: z0, z1: z1,
                                  glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, into: &m)
                        m.extra = SIMD4(1, 0, 0, 0)
                    }
                }
                continue
            }
            // Gangway walls (1–3 m to the neighbour): one or two stacks of smaller windows, one per
            // story (stairs, bath), heads level with the other windows (family data).
            if facade.gangwayWindows == true, role == .house || role == .block, len >= 8, isSideWall(c, e, front: g.frontEdge) {
                let gap = sideGap(c, edge: e)
                if gap >= Self.gangwayGap.lowerBound, gap <= Self.gangwayGap.upperBound {
                    let w = min(max(0.5, winW * 0.65), 0.75), h = min(max(0.8, winH * 0.6), 1.1)
                    let centers = gangwayStackCenters(c, edge: e, width: w)
                    for (story, z0, z1) in rows(winH) {
                        for (k, sc) in centers.enumerated() {
                            lit(story, 60 + k)
                            addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: w, z0: max(z0, z1 - h), z1: z1,
                                      glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, into: &m)
                            m.extra = SIMD4(1, 0, 0, 0)
                        }
                    }
                    g.gangwayStacks += centers.count
                    continue
                }
            }
            // Long side walls: grouped rhythm with blank stretches (family data).
            if facade.sideRhythm == true, !street, len >= 12, role == .house || role == .block {
                let scale = facade.sideWindowScale ?? 0.85
                let w = max(0.6, winW * scale)
                let groups = sideRhythmCenters(c, edge: e, width: w)
                for (story, z0, z1) in rows(winH * (scale + 1) / 2) {
                    for (gi, grp) in groups.enumerated() {
                        for k in 0..<grp.count {
                            let sc = grp.center - grp.width / 2 + w / 2 + Double(k) * (w + 0.4)
                            if breastCovers(c, edge: e, s: sc, width: w) { continue }
                            lit(story, gi * 4 + k)
                            addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: w, z0: z0, z1: z1,
                                      glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, into: &m)
                            m.extra = SIMD4(1, 0, 0, 0)
                        }
                    }
                }
                continue
            }
            let bayHere = street ? bay : bay * (role == .garage ? 2.5 : role == .house ? 1.35 : 1.7)
            var count: Int
            if len < 2.0 { continue }
            if len < 3.0 { count = rng.chance(0.5) ? 1 : 0 } else { count = max(1, Int(len / bayHere)) }
            if role == .garage { count = min(count, 1) }
            guard count > 0 else { continue }
            let group = facade.groupedWindows == true && street && len >= 5 ? max(2, facade.windowGroup ?? 2) : 1
            // Symmetric front: window bays mirrored about the centered door (Colonial / Georgian).
            if isFront, facade.symmetric == true, let doorS = doorAtS, let span = doorSpan, span.edge == e {
                let entryHalf = (span.s1 - span.s0) / 2
                for (story, z0, z1) in rows(winH) where !(storefront && story == 0) {
                    let offs = symmetricOffsets(len: len, doorS: doorS, minPitch: winW + 1.0, width: winW, entryHalf: entryHalf, story: story)
                    // Shutters fit the narrowest gap between neighbouring windows (and the corners).
                    var gap = min(doorS, len - doorS) - (offs.map { abs($0) }.max() ?? 0) - winW / 2 - 0.15
                    for (a, b2) in zip(offs, offs.dropFirst()) { gap = min(gap, (b2 - a - winW) / 2) }
                    let sw = min(winW * 0.45, gap - 0.15)
                    for (k, o) in offs.enumerated() {
                        // Over the door only where the entry roof stays below the sill.
                        if o == 0, g.entryKit == "portico", z0 < F + 3.75 { continue }
                        lit(story, k)
                        addWindow(origin: p, dir: dir, normal: n, sCenter: doorS + o, width: winW, z0: z0, z1: z1,
                                  glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, lintel: stoneHere, relief: reliefHere, into: &m)
                        m.extra = SIMD4(1, 0, 0, 0)
                        if let sp = shutter {
                            addShutters(origin: p, dir: dir, normal: n, sCenter: doorS + o, width: winW, z0: z0, z1: z1,
                                        shutterWidth: sw, paint: sp, into: &m)
                        }
                    }
                }
                continue
            }
            for story in 0..<stories {
                // Shopfronts take the street side of the ground floor.
                if storefront, story == 0, street { continue }
                let z0 = F + Double(story) * storyH + (story == 0 ? 0.85 : 0.8)
                let z1 = min(z0 + winH, F + Double(story + 1) * storyH - 0.35, H - 0.3)
                guard z1 - z0 > 0.6 else { continue }
                // Ranch: one broad living-room window on the front, ground floor.
                var widths = [Double](repeating: winW * Double(group) + 0.12 * Double(group - 1), count: max(1, count / group))
                // Ribbons of three or more: as many as fit with ≥ 1.2 m of wall between them.
                if group > 2 { widths = [Double](repeating: widths[0], count: max(1, Int((len - 0.9 + 1.2) / (widths[0] + 1.2)))) }
                if isFront, story == 0, let broad = win.broad, widths.count >= 2 { widths[0] = rng.range(broad) }
                // Fit within corner clearance 0.45 m and 0.35 m between openings; drop windows first.
                while !widths.isEmpty, widths.reduce(0, +) + Double(widths.count - 1) * 0.35 > len - 0.9 { widths.removeLast() }
                guard !widths.isEmpty else { continue }
                let step = (len - 0.9) / Double(widths.count)
                for (k, w) in widths.enumerated() {
                    let sc = 0.45 + step * (Double(k) + 0.5)
                    if story == 0, let span = doorSpan, span.edge == e, sc + w / 2 > span.s0, sc - w / 2 < span.s1 { continue }
                    let ww = min(w, step - 0.35)
                    if breastCovers(c, edge: e, s: sc, width: ww) { continue }
                    if let fb = facadeBay, fb.edge == e, story < fb.stories, sc + ww / 2 > fb.s0 - 0.1, sc - ww / 2 < fb.s1 + 0.1 { continue }
                    lit(story, k)
                    addWindow(origin: p, dir: dir, normal: n, sCenter: sc, width: ww, z0: z0, z1: z1,
                              glass: c.glass, trim: c.trim, reveal: c.reveal, frames: near, mullions: w > winW * 1.5 ? group : 1, lintel: stoneHere,
                              relief: reliefHere, into: &m)
                    m.extra = SIMD4(1, 0, 0, 0)
                }
            }
        }
    }

    func roofPaint(_ roof: Paint, _ trim: Paint, _ style: String) -> Paint { style == "canopy" ? trim : roof }

    /// R1: a soft occlusion strip on the ground around the walls (contact with the lawn).
    func addContactSkirt(_ ring: Ring, palette: Palette, into m: inout MeshBuffers) {
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

    func addWalls(_ ring: Ring, z0: Double, z1: Double, paint: ((Int) -> Paint)? = nil, into m: inout MeshBuffers) {
        for i in 0..<ring.count {
            let p = ring[i], q = ring[(i + 1) % ring.count]
            let d = q - p
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            if let paint { m.paint = paint(i) }
            m.addFace([P(p, z0), P(q, z0), P(q, z1), P(p, z1)], facing: D(LocalPoint(d.y, -d.x) / len))
        }
    }

    // swiftlint:disable:next function_parameter_count
    func addWindow(origin: LocalPoint, dir: LocalPoint, normal: LocalPoint, sCenter: Double, width: Double,
                   z0: Double, z1: Double, glass: Paint, trim: Paint, reveal: Paint? = nil, frames: Bool = true, mullions: Int = 1,
                   lintel: Paint? = nil, relief: Bool = false, into m: inout MeshBuffers) {
        guard width > 0.4 else { return }
        let s0 = sCenter - width / 2, s1 = sCenter + width / 2, f = 0.1
        m.paint = glass
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: z0, z1: z1, offset: 0.03)
        guard frames else { return }
        if let reveal {
            // Deep-window cue (house-contrast-v1: "deep glass"): a shadow-coloured reveal along the head and jambs.
            m.paint = reveal
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: z1 - 0.14, z1: z1, offset: 0.04)
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s0 + 0.07, z0: z0, z1: z1 - 0.14, offset: 0.04)
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s1 - 0.07, s1: s1, z0: z0, z1: z1 - 0.14, offset: 0.04)
        }
        let seed = m.extra
        m.extra = SIMD4(1, 0, 0, 0)
        m.paint = trim
        if let stone = lintel {
            // Masonry opening: projecting sill below, lintel above, plain side frames.
            m.paint = stone
            addLedge(origin: origin, dir: dir, normal: normal, s0: s0 - 0.14, s1: s1 + 0.14, z0: z0 - 0.13, z1: z0, depth: 0.1, ends: true, into: &m)
            addLedge(origin: origin, dir: dir, normal: normal, s0: s0 - 0.18, s1: s1 + 0.18, z0: z1, z1: z1 + 0.28, depth: 0.07, ends: true, into: &m)
            m.paint = trim
        } else if relief {
            // Relief casing (house-details-v1, 3–8 cm): projecting sill and head with top faces.
            addLedge(origin: origin, dir: dir, normal: normal, s0: s0 - f - 0.03, s1: s1 + f + 0.03, z0: z0 - 0.08, z1: z0, depth: 0.08, ends: false, into: &m)
            addLedge(origin: origin, dir: dir, normal: normal, s0: s0 - f - 0.02, s1: s1 + f + 0.02, z0: z1, z1: z1 + 0.12, depth: 0.07, ends: false, into: &m)
        } else {
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z0 - f, z1: z0, offset: 0.06)
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s1 + f, z0: z1, z1: z1 + f, offset: 0.06)
        }
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0 - f, s1: s0, z0: z0, z1: z1, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s1, s1: s1 + f, z0: z0, z1: z1, offset: 0.06)
        m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s0, s1: s1, z0: (z0 + z1) / 2 - 0.03, z1: (z0 + z1) / 2 + 0.03, offset: 0.05)
        // Vertical mullions between grouped windows.
        if mullions > 1 {
            for k in 1..<mullions {
                let s = s0 + width * Double(k) / Double(mullions)
                m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: s - 0.06, s1: s + 0.06, z0: z0, z1: z1, offset: 0.055)
            }
        }
        m.extra = seed
    }

    /// A ledge standing out from a wall by `depth`: front and top faces, plus the two ends.
    // swiftlint:disable:next function_parameter_count
    func addLedge(origin: LocalPoint, dir: LocalPoint, normal: LocalPoint, s0: Double, s1: Double, z0: Double, z1: Double,
                  depth: Double, ends: Bool, into m: inout MeshBuffers) {
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(origin + dir * s + normal * t, z) }
        m.addFace([q(s0, depth, z0), q(s1, depth, z0), q(s1, depth, z1), q(s0, depth, z1)], facing: D(normal))
        m.addFace([q(s0, 0, z1), q(s0, depth, z1), q(s1, depth, z1), q(s1, 0, z1)], facing: sceneUp)
        if ends {
            m.addFace([q(s0, 0, z0), q(s0, depth, z0), q(s0, depth, z1), q(s0, 0, z1)], facing: D(-dir))
            m.addFace([q(s1, 0, z0), q(s1, depth, z0), q(s1, depth, z1), q(s1, 0, z1)], facing: D(dir))
        }
    }

    /// Steps descending from `height` to the ground, starting at `top` and going out along `n`.
    func addSteps(at top: LocalPoint, dir: LocalPoint, n: LocalPoint, width: Double, height: Double, foundation: Paint, into m: inout MeshBuffers) {
        guard height > 0.12 else { return }
        let count = max(1, Int((height / 0.18).rounded()))
        let rise = height / Double(count + 1)
        m.paint = foundation
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(top + dir * s + n * t, z) }
        let hw = width / 2
        for k in 0..<count {
            // Top, front and sides; the back face is hidden by the step (or stoop) behind it.
            let z1 = height - rise * Double(k + 1)
            let t0 = 0.3 * Double(k), t1 = t0 + 0.3
            m.addFace([q(-hw, t0, z1), q(hw, t0, z1), q(hw, t1, z1), q(-hw, t1, z1)], facing: sceneUp)
            m.addFace([q(-hw, t1, 0), q(hw, t1, 0), q(hw, t1, z1), q(-hw, t1, z1)], facing: D(n))
            for sx in [-1.0, 1.0] {
                m.addFace([q(sx * hw, t0, 0), q(sx * hw, t1, 0), q(sx * hw, t1, z1), q(sx * hw, t0, z1)], facing: D(dir * sx))
            }
        }
    }
}

/// Everything the detail passes need about one building.
struct BuildContext {
    var b: Building
    var ring: Ring
    var type: StyleProfile.HouseType?
    var grammar: HouseFamilyGrammar
    var F: Double
    var H: Double
    var parapet: Double
    var pitch: Double
    var overhang: Double
    var wall: Paint
    var sideWall: Paint?
    var trim: Paint
    var door: Paint
    var roof: Paint
    var foundation: Paint
    var glass: Paint
    /// Window reveal strip (soffit colour) for house-contrast brick families, nil otherwise.
    var reveal: Paint? = nil
    /// Stone lintel/sill openings on every street window (house-contrast brick families).
    var stoneOpenings = false
    /// The profile's light trim (gable panels, stucco gable triangles); `trim` may be the family's.
    var panel: Paint
    var mainRect: OrientedRect
    var lod: BuildingLOD
    var envelope: RoofEnvelope?
    var plan: RoofPlan?
    var streetFacing: Set<Int>
    var floors = 1
    /// Mapped street bays: [side, front, side] edge indices (facade `mappedBays`).
    var mappedBays: [[Int]] = []
    /// Mapped side-wall protrusions: [side, face, side] edge indices (facade `sideBays`).
    var sideBays: [[Int]] = []
    /// The chimney as a side-wall breast (facade `chimneyBreast`), planned before the openings.
    var breast: SideBreast?
}

@inline(__always)
func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
    let t = min(1, max(0, (x - e0) / max(e1 - e0, 1e-9)))
    return t * t * (3 - 2 * t)
}
