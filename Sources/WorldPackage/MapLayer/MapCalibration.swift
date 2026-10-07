import Foundation

/// Calibration tables for `MapConfidence`, from `Tools/regionkit/mapconf` (bins and shares in
/// `Tools/regionkit/mapconf/results/calibration.json`; method and samples in
/// `docs/research/map-confidence.md`). A confidence is the pooled share of a validation sample in the
/// record's bin whose value was right, over Sloan's Lake (Denver), Evanston South and Lakeview
/// (Chicago). The bin rules here and in `fit.py` must stay identical.
enum Calibration {
    // MARK: Frontage

    static let frontageDefinition = "The share of a validation sample in the same bin whose frontage segment is named as the building's OSM addr:street (2,881 buildings with addr:street in Sloan's Lake, Evanston South and Lakeview; names normalized; addr:street is used only for this check and never exported). Bins: corner houses (another, differently named street within 40 m of the centroid) by the distance to that other street (< 20, 20–30, 30–40 m); other houses by the door's distance to the chosen street (< 12, 12–20, ≥ 20 m). Leave-one-area-out gaps up to 0.39 in small bins: a bin's share can differ by that much in an unseen area (Tools/regionkit/mapconf/results/calibration.json)."

    static func frontage(_ f: [String: Any]) -> Double {
        let corner = f["corner"] as? Bool ?? false
        if corner {
            let other = f["otherStreetM"] as? Double ?? 0
            return other < 20 ? 0.189 : other < 30 ? 0.475 : 0.864
        }
        let d = f["distanceM"] as? Double ?? 0
        return d < 12 ? 0.950 : d < 20 ? 0.991 : 0.812
    }

    // MARK: Lots

    static let lotDefinition = "The share of a validation sample in the same bin whose outline overlaps the real yard at IoU ≥ 0.6, the real yard being the county parcel minus the building footprint, split at the same front line (5,538 lots: Denver parcels, CC BY 3.0; Cook County 2025 parcels, internal use; geometry only, never stored in the repository). Bins: a part whose dropped pieces exceed 5 % of its area; back yards by area (< 150, 150–250, 250–600, ≥ 600 m²); front yards < 40 m² or ≥ 250 m²; front yards of 40–250 m² by the door's distance to the frontage street (< 12 or no frontage, 12–16, 16–20, 20–30, ≥ 30 m). Leave-one-area-out gaps up to 0.30 (Tools/regionkit/mapconf/results/calibration.json)."

    static func lot(_ f: [String: Any]) -> Double {
        let part = f["part"] as? String ?? "back"
        let dropped = f["droppedShare"] as? Double ?? 0
        let area = f["areaM2"] as? Double ?? 0
        if dropped >= 0.05 { return part == "front" ? 0.264 : 0.067 }
        if part == "back" { return area < 150 ? 0.047 : area < 250 ? 0.192 : area < 600 ? 0.263 : 0.164 }
        if area < 40 { return 0.388 }
        if area >= 250 { return 0.409 }
        let d = f["frontageM"] as? Double ?? -1
        return d < 12 ? 0.139 : d < 16 ? 0.647 : d < 20 ? 0.749 : d < 30 ? 0.701 : 0.041
    }

    // MARK: Entry points

    static let entryDefinition = "front_door: the share of a validation sample whose door, labelled blind on USDA NAIP 0.3 m imagery (where the front walk, steps or stoop meet the house), lies on the same wall within 2.0 m along it: 21 of 58 labelled doors (210 sampled; most not discernible under trees or shadow), one bin, leave-one-area-out gap up to 0.45. driveway_end: the share whose blind-labelled driveway mouth lies within 3.0 m: 87 of 101 labelled (120 sampled), one bin, gap up to 0.28; most sampled garages open onto alleys, so most mouths are short. Labels are an agent's reading of 0.3 m imagery (about ±1 m), not a field survey; only discernible cases are scored. Detail: docs/research/map-confidence.md."

    static func door(_ f: [String: Any]) -> Double { 0.362 }
    static func driveway(_ f: [String: Any]) -> Double { 0.861 }
}
