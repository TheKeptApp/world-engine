import Foundation
import WorldGeo

/// Typed map features for one area, in local meters (east = +x, north = +y) of `frame`.
/// Everything generators and renderers need, and nothing source-specific.
public struct MapFeatures: Sendable {
    public var frame: LocalFrame
    /// The area's extent in local meters. Features are clipped to it (buildings by centroid).
    public var bounds: Rect2D
    public var buildings: [Building] = []
    /// Vehicle roads (residential, primary, service, ...).
    public var roads: [WayFeature] = []
    /// Footways, paths, cycleways, steps, pedestrian streets (excluding sidewalks).
    public var paths: [WayFeature] = []
    /// Footways tagged `footway=sidewalk` (sidewalks mapped as separate ways).
    public var sidewalks: [WayFeature] = []
    public var areas: [AreaFeature] = []
    public var points: [PointFeature] = []
    public var lines: [LineFeature] = []
    public var report = LoadReport()

    public init(frame: LocalFrame, bounds: Rect2D) {
        self.frame = frame
        self.bounds = bounds
    }

    public func points(of kind: PointFeature.Kind) -> [PointFeature] {
        points.filter { $0.kind == kind }
    }

    public func areas(of kind: AreaFeature.Kind) -> [AreaFeature] {
        areas.filter { $0.kind == kind }
    }
}

// MARK: - Buildings

public struct Building: Sendable {
    public var ref: OSMRef
    /// Cleaned footprint: outer ring CCW, courtyards CW.
    public var footprint: Polygon2D
    public var tags: Tags
    /// The `building=*` value (or `building:part=*` for parts), e.g. "house", "garage", "yes".
    public var type: String
    public var isPart: Bool
    public var height: BuildingHeight

    public var levels: Double? { tags["building:levels"].flatMap(TagParsing.number) }
    public var roofShape: String? { tags["roof:shape"] }
    public var hasHeightTag: Bool { tags["height"].flatMap(TagParsing.length) != nil }
    public var hasLevelsTag: Bool { levels != nil }
}

public struct BuildingHeight: Sendable, Equatable {
    public enum Source: String, Sendable, CaseIterable { case heightTag, levels, typeDefault }
    /// Bottom of the walls above ground (from `min_height` / `building:min_level`), in meters.
    public var base: Double
    /// Top of the building, in meters above ground.
    public var top: Double
    public var source: Source
}

// MARK: - Roads, paths, sidewalks

public enum HighwayKind: String, Sendable, CaseIterable {
    case motorway, trunk, primary, secondary, tertiary, unclassified, residential
    case livingStreet = "living_street"
    case service, road, busway, track
    case pedestrian, footway, path, cycleway, bridleway, steps, corridor
    case other

    /// Roads meant for vehicles. Everything else is a path.
    public var isVehicular: Bool {
        switch self {
        case .motorway, .trunk, .primary, .secondary, .tertiary, .unclassified, .residential,
             .livingStreet, .service, .road, .busway, .track:
            return true
        default:
            return false
        }
    }

    init(tag: String) {
        let base = tag.hasSuffix("_link") ? String(tag.dropLast(5)) : tag
        self = HighwayKind(rawValue: base) ?? .other
    }
}

/// What a road's `sidewalk*` tags say about each side.
public enum SidewalkState: String, Sendable {
    /// No tag: unknown, so a generator decides from the road type.
    case unknown
    /// Explicitly no sidewalk.
    case none
    /// There is a sidewalk, mapped as its own way (don't generate one).
    case separate
    /// There is a sidewalk, but only as a tag on the road (generate it).
    case tagged
}

public struct WayFeature: Sendable {
    public var ref: OSMRef
    public var kind: HighwayKind
    /// Centerline in local meters, clipped to the area. A clipped way may yield several features
    /// with the same `ref`.
    public var centerline: [LocalPoint]
    public var tags: Tags
    /// Resolved width in meters (tag, lanes or default by kind).
    public var width: Double
    public var sidewalkLeft: SidewalkState
    public var sidewalkRight: SidewalkState
    /// `footway=crossing` or `crossing=*` on a footway.
    public var isCrossing: Bool
    public var layer: Int
    public var isBridge: Bool
    public var isTunnel: Bool
}

// MARK: - Areas

public struct AreaFeature: Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case water, park, garden, grass, meadow, wood, scrub, pitch, playground, parking
        case sand, wetland, pool, pier, cemetery, recreation
        case residential, commercial, pedestrianArea
    }

    public var ref: OSMRef
    public var kind: Kind
    /// Clipped to the area and cleaned. A multipolygon may yield several features with one `ref`.
    public var polygon: Polygon2D
    public var tags: Tags
}

// MARK: - Points and lines

public struct PointFeature: Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case tree, bench, streetLamp, wasteBasket, picnicTable, drinkingWater, fireHydrant
        case bicycleParking, toilets, postBox, bollard, flagpole, playgroundEquipment
        /// `highway=crossing` node: where a crossing meets a road (its `crossing*` tags say how it is marked).
        case crossing
    }

    public var ref: OSMRef
    public var kind: Kind
    public var position: LocalPoint
    public var tags: Tags
    /// True if the feature was mapped as a way or area and reduced to its centroid.
    public var fromWay: Bool = false
}

public struct LineFeature: Sendable {
    public enum Kind: String, Sendable, CaseIterable {
        case treeRow, hedge, fence, wall, retainingWall, kerb, stream
    }

    public var ref: OSMRef
    public var kind: Kind
    public var line: [LocalPoint]
    public var tags: Tags
}

// MARK: - Report

public struct LoadReport: Sendable {
    public struct Skipped: Sendable {
        public var ref: OSMRef
        public var reason: String
    }

    public var skipped: [Skipped] = []
    /// Elements read from the source documents.
    public var nodeCount = 0
    public var wayCount = 0
    public var relationCount = 0
    /// Tagged ways/relations that matched no feature rule.
    public var unclassifiedCount = 0
    /// Overture buildings merged as a second footprint source (see `OvertureBuildings`).
    public var overture = OvertureMergeReport()
}
