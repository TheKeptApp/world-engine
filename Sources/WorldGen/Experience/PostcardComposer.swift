import Foundation
import simd
import WorldGeo
import WorldMap

/// experience-v1 §4: postcards composed from map data alone (renderer-neutral, CPU, run while a
/// world is prepared, never per frame). The bounded heuristic of the spec:
///
/// 1. Candidates every ~10 m along public paths and park edges, plus waterfront points on public
///    paths; never in water, buildings or private ways; at most 256, spread out.
/// 2. 24 headings (15°), 50° vertical FOV, eye 1.65 m; ≤32 coarse rays per pose against building
///    hulls, tree crowns and a classified ground grid.
/// 3. Normalized scores: open depth, geographic interest, composition, light fit, weather fit,
///    coverage confidence, weighted 0.25 / 0.20 / 0.20 / 0.15 / 0.10 / 0.10.
/// 4. The best 12 are refined with denser rays and ±7.5° headings. Light fit averages several
///    real times so a sunset-only winner can't become an unreadable noon view.
///
/// Every input is map data or generated scene data; ties break on stable candidate IDs.
public struct PostcardComposer: Sendable {
    public struct Settings: Sendable {
        public var eyeHeight = 1.65
        public var downPitchDegrees = 3.0
        public var verticalFOVDegrees = 50.0
        /// Scoring frame (the spec's 16:9 comparison frame; portrait hosts keep the pose).
        public var aspect = 16.0 / 9.0
        public var sampleSpacing = 10.0
        public var maxCandidates = 256
        public var headingStepDegrees = 15.0
        public var coarseRays = (columns: 8, rows: 4)
        public var refineRays = (columns: 16, rows: 6)
        public var refineCount = 12
        public var maxDistance = 1500.0
        /// Look-at marker distance along the view (experience-v1 §1.2: 30 m).
        public var targetDistance = 30.0
        public init() {}
    }

    public struct Scores: Codable, Sendable, Equatable {
        public var openDepth: Double
        public var geographicInterest: Double
        public var composition: Double
        public var lightFit: Double
        public var weatherFit: Double
        public var coverageConfidence: Double
        public var total: Double
    }

    /// One composed postcard: pose in scene metres (east +X, up +Y, north −Z) and geographic origin.
    public struct Postcard: Codable, Sendable, Equatable {
        public var id: String
        public var source: String
        public var origin: GeoCoordinate
        public var eye: [Double]
        public var target: [Double]
        public var headingDegrees: Double
        public var downPitchDegrees: Double
        public var verticalFOVDegrees: Double
        public var scores: Scores
        /// Measured shares of the frame (rays): water, sky, green, buildings.
        public var frame: [String: Double]
        public var reasons: [String]
    }

    public struct Result: Codable, Sendable, Equatable {
        public var postcards: [Postcard]
        public var candidatesConsidered: Int
        public var posesScored: Int
        public var rejected: [String: Int]
        public var fallback: String?
    }

    public var settings = Settings()
    let features: MapFeatures
    let scene: GeneratedScene
    let focus: Rect2D
    let frame: LocalFrame
    /// Moments whose real sun direction the light fit averages (e.g. golden hour, noon, morning).
    let lightTimes: [Date]

    public init(features: MapFeatures, scene: GeneratedScene, focus: Rect2D, lightTimes: [Date]) {
        self.features = features
        self.scene = scene
        self.focus = focus
        frame = features.frame
        self.lightTimes = lightTimes
    }

    // MARK: - Compose

    public func compose(count: Int = 8) -> Result {
        let world = RayWorld(features: features, scene: scene)
        var rejected: [String: Int] = [:]
        let candidates = makeCandidates(world: world, rejected: &rejected)
        let suns = lightTimes.map { SolarPosition(date: $0, at: frame.origin) }
        var scored: [(Postcard, Double)] = []
        var poses = 0
        for c in candidates {
            var best: (Postcard, Double)?
            for k in 0..<Int(360 / settings.headingStepDegrees) {
                poses += 1
                let heading = Double(k) * settings.headingStepDegrees
                guard let p = evaluate(c, heading: heading, rays: settings.coarseRays, world: world, suns: suns, rejected: &rejected) else { continue }
                if best == nil || p.scores.total > best!.1 { best = (p, p.scores.total) }
            }
            if let best { scored.append(best) }
        }
        scored.sort { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.id < $1.0.id }

        // Refine the best distinct locations (≥ 40 m apart) with denser rays and finer headings.
        var refined: [Postcard] = []
        for (p, _) in scored where refined.count < settings.refineCount {
            let here = LocalPoint(p.eye[0], -p.eye[2])
            if refined.contains(where: { simd_distance(LocalPoint($0.eye[0], -$0.eye[2]), here) < 40 }) { continue }
            let c = Candidate(point: here, source: p.source, waterfront: p.reasons.contains("waterfront"))
            var best = p
            for dh in stride(from: -7.5, through: 7.5, by: 2.5) {
                let heading = (p.headingDegrees + dh + 360).truncatingRemainder(dividingBy: 360)
                if let q = evaluate(c, heading: heading, rays: settings.refineRays, world: world, suns: suns, rejected: &rejected),
                   q.scores.total > best.scores.total || dh == 0 && best == p {
                    best = q
                }
            }
            refined.append(best)
        }
        refined.sort { $0.scores.total != $1.scores.total ? $0.scores.total > $1.scores.total : $0.id < $1.id }
        let fallback = refined.isEmpty ? "aerial: no valid street candidate" : nil
        return Result(postcards: Array(refined.prefix(count)), candidatesConsidered: candidates.count, posesScored: poses,
                      rejected: rejected, fallback: fallback)
    }

    // MARK: - Candidates

    struct Candidate {
        var point: LocalPoint
        var source: String
        var waterfront: Bool
    }

    static let publicPathKinds: Set<HighwayKind> = [.footway, .path, .cycleway, .pedestrian, .bridleway]
    static let greenKinds: Set<AreaFeature.Kind> = [.park, .garden, .grass, .meadow, .recreation, .pitch, .playground, .cemetery]

    private func isPublic(_ tags: Tags) -> Bool {
        let access = tags["access"] ?? tags["foot"]
        return !["private", "no", "customers"].contains(access ?? "")
    }

    func makeCandidates(world: RayWorld, rejected: inout [String: Int]) -> [Candidate] {
        var out: [Candidate] = []
        let inner = features.bounds.insetBy(60)
        func consider(_ p: LocalPoint, _ source: String) {
            guard inner.contains(p) else { rejected["outsideCoverage", default: 0] += 1; return }
            switch world.ground(p) {
            case .water: rejected["inWater", default: 0] += 1; return
            case .building: rejected["inBuilding", default: 0] += 1; return
            default: break
            }
            if world.insideBuilding(p) { rejected["inBuilding", default: 0] += 1; return }
            out.append(Candidate(point: p, source: source, waterfront: world.nearWater(p, within: 25)))
        }
        for way in features.paths where Self.publicPathKinds.contains(way.kind) && isPublic(way.tags) && !way.isTunnel {
            for (i, p) in Self.resample(way.centerline, every: settings.sampleSpacing).enumerated() {
                consider(p, "\(way.ref)@\(Int(Double(i) * settings.sampleSpacing))m")
            }
        }
        for area in features.areas where Self.greenKinds.contains(area.kind) && isPublic(area.tags) {
            for (i, p) in Self.resample(area.polygon.outer + [area.polygon.outer[0]], every: settings.sampleSpacing * 2).enumerated() {
                // Step 3 m inside the edge so the eye stands on the park, not the street.
                let c = area.polygon.centroid
                let inward = simd_length(c - p) > 1 ? p + simd_normalize(c - p) * 3 : p
                consider(inward, "\(area.ref)/edge@\(i * Int(settings.sampleSpacing * 2))m")
            }
        }
        // Spread out: keep one candidate per grid cell (waterfront first, then stable order),
        // growing the cell until at most `maxCandidates` remain.
        var cell = 20.0
        var kept = out
        while kept.count > settings.maxCandidates {
            var seen: Set<SIMD2<Int>> = []
            kept = []
            let ordered = out.sorted { $0.waterfront != $1.waterfront ? $0.waterfront : $0.source < $1.source }
            for c in ordered {
                let key = SIMD2(Int((c.point.x / cell).rounded(.down)), Int((c.point.y / cell).rounded(.down)))
                if seen.insert(key).inserted { kept.append(c) }
            }
            cell *= 1.25
        }
        return kept.sorted { $0.source < $1.source }
    }

    static func resample(_ line: [LocalPoint], every step: Double) -> [LocalPoint] {
        guard line.count >= 2 else { return line }
        var out: [LocalPoint] = [line[0]]
        var carry = 0.0
        for (a, b) in zip(line, line.dropFirst()) {
            let len = simd_distance(a, b)
            guard len > 0 else { continue }
            var t = step - carry
            while t <= len {
                out.append(a + (b - a) * (t / len))
                t += step
            }
            carry = len - (t - step)
        }
        return out
    }

    // MARK: - Scoring

    func evaluate(_ c: Candidate, heading: Double, rays: (columns: Int, rows: Int), world: RayWorld, suns: [SolarPosition],
                  rejected: inout [String: Int]) -> Postcard? {
        let s = settings
        let rad = Double.pi / 180
        let eye = SIMD3(c.point.x, s.eyeHeight, -c.point.y)
        let vHalf = s.verticalFOVDegrees / 2 * rad
        let hHalf = atan(tan(vHalf) * s.aspect)
        let yaw = heading * rad, pitch = -s.downPitchDegrees * rad
        let forward = SIMD3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
        let right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
        let up = simd_cross(right, forward)

        var sky = 0, water = 0, green = 0, building = 0, outside = 0, unfocused = 0, total = 0
        var depthSum = 0.0, depthCount = 0
        var nearCenter = 0, centerRays = 0
        var foreground = false, middle = false, far = false
        for row in 0..<rays.rows {
            for col in 0..<rays.columns {
                let u = (Double(col) + 0.5) / Double(rays.columns) * 2 - 1
                let v = (Double(row) + 0.5) / Double(rays.rows) * 2 - 1
                let dir = simd_normalize(forward + right * (u * tan(hHalf)) + up * (-v * tan(vHalf)))
                let hit = world.cast(from: eye, direction: dir, maxDistance: s.maxDistance)
                total += 1
                let centerColumn = abs(u) < 1.0 / 3
                if centerColumn { centerRays += 1 }
                switch hit.kind {
                case .sky:
                    sky += 1
                    continue
                case .building: building += 1
                case .tree: break
                case .ground(let g):
                    if g == .water { water += 1 }
                    if g == .green { green += 1 }
                    if g == .outside { outside += 1 }
                }
                if !focus.contains(LocalPoint(hit.point.x, -hit.point.z)) { unfocused += 1 }
                depthSum += log(1 + hit.distance) / log(1 + s.maxDistance)
                depthCount += 1
                if centerColumn, hit.distance < 8, hit.kind != .ground(.road), hit.kind != .ground(.other),
                   hit.kind != .ground(.green), hit.kind != .ground(.water) {
                    nearCenter += 1
                }
                if hit.distance < 25 { foreground = true } else if hit.distance < 200 { middle = true } else { far = true }
            }
        }
        let n = Double(total)
        let skyF = Double(sky) / n, waterF = Double(water) / n, greenF = Double(green) / n, buildingF = Double(building) / n
        let occlusion = centerRays > 0 ? Double(nearCenter) / Double(centerRays) : 0
        if occlusion > 0.5 { rejected["nearOcclusion", default: 0] += 1; return nil }
        if Double(outside) / n > 0.3 { rejected["missingGeometry", default: 0] += 1; return nil }

        let depth = depthCount > 0 ? depthSum / Double(depthCount) : 0
        let openDepth = clamp01(depth / 0.75) * (1 - occlusion)
        var reasons: [String] = []
        var interest = 0.0
        if waterF >= 0.04 { interest += 0.5; reasons.append("water") }
        if greenF >= 0.08 { interest += 0.3; reasons.append("park") }
        if buildingF >= 0.04 { interest += 0.25; reasons.append("architecture") }
        if c.waterfront { reasons.append("waterfront") }
        interest = min(1, interest)
        func band(_ x: Double, _ lo: Double, _ hi: Double, soft: Double) -> Double {
            x < lo ? clamp01(1 - (lo - x) / soft) : (x > hi ? clamp01(1 - (x - hi) / soft) : 1)
        }
        let layers = (foreground ? 1.0 : 0) + (middle ? 1 : 0) + (far ? 1 : 0)
        let composition = 0.3 * band(waterF, 0.15, 0.40, soft: 0.15) * (waterF > 0 ? 1 : 0.5)
            + 0.3 * band(skyF, 0.25, 0.45, soft: 0.2)
            + 0.25 * layers / 3
            + 0.15 * (1 - occlusion)
        // Light: side or back light at low sun; looking into a low sun only when it is in frame.
        var light = 0.0
        for sun in suns {
            if sun.elevation <= 0 { light += 0.5; continue }
            var delta = abs(sun.azimuth - heading).truncatingRemainder(dividingBy: 360)
            if delta > 180 { delta = 360 - delta }
            let low = 1 - smoothstep(10, 45, sun.elevation)
            let side = delta >= 60 ? 1.0 : (delta <= 25 && sun.elevation < s.verticalFOVDegrees / 2 - s.downPitchDegrees ? 0.6 : 0.25)
            light += low * side + (1 - low) * 0.7
        }
        let lightFit = suns.isEmpty ? 0.5 : light / Double(suns.count)
        let coverage = depthCount > 0 ? 1 - 0.5 * Double(unfocused) / Double(depthCount) - Double(outside) / Double(depthCount) : 0
        let scores = Scores(openDepth: openDepth, geographicInterest: interest, composition: composition, lightFit: lightFit,
                            weatherFit: 0.5, coverageConfidence: clamp01(coverage), total: 0)
        var scored = scores
        scored.total = 0.25 * openDepth + 0.20 * interest + 0.20 * composition + 0.15 * lightFit + 0.10 * 0.5 + 0.10 * scores.coverageConfidence
        let target = eye + forward * s.targetDistance
        let origin = frame.coordinate(at: c.point)
        func r(_ x: Double, _ d: Double = 1000) -> Double { (x * d).rounded() / d }
        return Postcard(id: "\(c.source)#\(Int(heading.rounded()))", source: c.source, origin: origin,
                        eye: [eye.x, eye.y, eye.z].map { r($0) }, target: [target.x, target.y, target.z].map { r($0) },
                        headingDegrees: r(heading, 100), downPitchDegrees: s.downPitchDegrees, verticalFOVDegrees: s.verticalFOVDegrees,
                        scores: Scores(openDepth: r(scored.openDepth), geographicInterest: r(scored.geographicInterest),
                                       composition: r(scored.composition), lightFit: r(scored.lightFit), weatherFit: r(scored.weatherFit),
                                       coverageConfidence: r(scored.coverageConfidence), total: r(scored.total, 10000)),
                        frame: ["water": r(waterF), "sky": r(skyF), "green": r(greenF), "buildings": r(buildingF)],
                        reasons: reasons)
    }
}

private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

extension Rect2D {
    func insetBy(_ d: Double) -> Rect2D { Rect2D(min: min + LocalPoint(d, d), max: max - LocalPoint(d, d)) }
}
