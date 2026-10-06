import WorldGen
import WorldGeo

/// A WGS84 latitude/longitude (re-exported so apps only import WorldEngine).
public typealias GeoCoordinate = WorldGeo.GeoCoordinate
/// A latitude/longitude box (south, west, north, east).
public typealias GeoBoundingBox = WorldGeo.GeoBoundingBox

/// No-character experience types (renderer-neutral, from WorldGen), re-exported for host apps.
public typealias CameraPose = WorldGen.CameraPose
public typealias AerialRig = WorldGen.AerialRig
public typealias ExploreRig = WorldGen.ExploreRig
public typealias RouteRig = WorldGen.RouteRig
public typealias ExperienceDefaults = WorldGen.ExperienceDefaults
public typealias Postcard = WorldGen.PostcardComposer.Postcard
