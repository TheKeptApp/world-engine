import Foundation
import WorldGeo

/// Default-off generator look experiments for A3 paired scoring (R, P2 Batch 1, 9 Oct 2026). With none active
/// the generator output is current main, unchanged. Enabled only by the capture launch argument
/// `-lookexp name[,name]` or the `WORLDENGINE_LOOKEXP` environment variable; tests use `$active.withValue`.
public enum LookExperiments {
    /// Lot lawns take shade and tone from one smooth field across lots, at half the lot-to-lot spread.
    public static let lawnSmooth = "lawnsmooth"
    /// Unmapped house walls take a wider per-building value spread.
    public static let wallSpread = "wallspread"
    /// Mapped sidewalks and paths are cut where they cross a street carriageway (RoadClip).
    public static let roadClip = "roadclip"
    /// A shop or food/drink point inside a footprint of 250 m² or more is commercial evidence (mixed-use strip family).
    public static let commercialPoints = "commercialpoints"
    /// Batch 3: mapped sidewalks (and paths) end short of a street carriageway by their ribbon half-width (includes roadclip).
    public static let sidewalkEndShort = "sidewalkendshort"
    /// Batch 3: landuse=retail / commercial areas drawn as paved commercial ground (seasonal key `commercial`).
    public static let retailGround = "retailground"
    /// Batch 3: parking areas get a kerb edge; underground / rooftop / multi-storey parking is not drawn on the ground.
    public static let parkingArea = "parkingarea"
    /// Batch 3: front-range apartment and courtyard families (facade-detail-v2 denver-apartment / denver-courtyard).
    public static let denverApartments = "denverapartments"
    /// Batch 3: pitches by sport (courts, fields with lines, baseball infields) and leisure=track.
    public static let sportsFields = "sportsfields"
    /// Batch 4: unmapped walls toward a warm hue band and roofs toward slate, per profile (`lookExperiments.warmwalls`).
    public static let warmWalls = "warmwalls"
    public static let known: Set<String> = [lawnSmooth, wallSpread, roadClip, commercialPoints, sidewalkEndShort, retailGround,
                                            parkingArea, denverApartments, sportsFields, warmWalls]

    @TaskLocal public static var active: Set<String> = parse(ProcessInfo.processInfo.arguments, ProcessInfo.processInfo.environment)

    static func parse(_ args: [String], _ env: [String: String]) -> Set<String> {
        var names = env["WORLDENGINE_LOOKEXP"].map { [$0] } ?? []
        if let i = args.firstIndex(of: "-lookexp"), i + 1 < args.count { names.append(args[i + 1]) }
        return Set(names.flatMap { $0.split(separator: ",").map(String.init) }).intersection(known)
    }

    static func on(_ name: String) -> Bool { active.contains(name) }
}

/// Smooth value noise in [-1, 1] over local metres, seeded from lattice coordinates (StableRandom).
struct BroadField: Sendable {
    var wavelength: Double
    var salt: String

    func value(_ p: LocalPoint) -> Double {
        let x = p.x / wavelength, y = p.y / wavelength
        let i = x.rounded(.down), j = y.rounded(.down)
        func corner(_ di: Double, _ dj: Double) -> Double {
            var r = StableRandom(UInt64(bitPattern: Int64(i + di)), UInt64(bitPattern: Int64(j + dj)), salt: salt)
            return r.unit() * 2 - 1
        }
        func smooth(_ t: Double) -> Double { t * t * (3 - 2 * t) }
        let u = smooth(x - i), v = smooth(y - j)
        let a = corner(0, 0) + (corner(1, 0) - corner(0, 0)) * u
        let b = corner(0, 1) + (corner(1, 1) - corner(0, 1)) * u
        return a + (b - a) * v
    }
}

/// The lawnsmooth experiment: shade and tone vary smoothly across neighbouring lots instead of by lot steps.
/// Centred on the lot range's middle with half its spread (P2 Batch 0 proposal: lot-to-lot ~ΔL* 15 → ~7).
struct BroadLawn: Sendable {
    var shadeMid: Double, shadeAmp: Double
    var toneMid: Double = 0.5, toneAmp: Double = 0.25
    /// A few lots across (lots are ~15–40 m): neighbours nearly match, a block drifts.
    static let wavelength = 60.0
    var shadeField = BroadField(wavelength: wavelength, salt: "lawn-broad-shade")
    var toneField = BroadField(wavelength: wavelength, salt: "lawn-broad-tone")

    init(range: [Double]) {
        shadeMid = (range[0] + range[1]) / 2
        shadeAmp = (range[1] - range[0]) / 4
    }

    func shade(_ p: LocalPoint) -> Double { shadeMid + shadeAmp * shadeField.value(p) }
    func tone(_ p: LocalPoint) -> Float { Float(toneMid + toneAmp * toneField.value(p)) }
}
