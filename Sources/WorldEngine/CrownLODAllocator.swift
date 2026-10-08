import Foundation

/// Pure opt-in policy from docs/execution/crowns.md. No shipping renderer calls this policy.
/// Costs must be measured submissions, including duplicates and every shadow pass; pack caps
/// (1200/360/80/12) are hypotheses, never substituted for missing measurements.
public enum CrownLODAllocator {
    public enum Level: Int, CaseIterable, Sendable, Comparable {
        case skyline, far, middle, near
        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }
    public struct Cost: Sendable {
        public var main: Int
        public var allPassShadow: Int?
        public var drawSlots: Set<String>
        public init(main: Int, allPassShadow: Int?, drawSlots: Set<String>) {
            self.main = main; self.allPassShadow = allPassShadow; self.drawSlots = drawSlots
        }
    }
    public struct Crown: Sendable {
        public var sourceID: String
        public var eyeDistance: Double
        public var fallback: Level
        public var requested: Level
        public var costs: [Level: Cost]
        public init(sourceID: String, eyeDistance: Double, fallback: Level, requested: Level, costs: [Level: Cost]) {
            self.sourceID = sourceID; self.eyeDistance = eyeDistance; self.fallback = fallback
            self.requested = requested; self.costs = costs
        }
    }
    public struct Inputs: Sendable {
        public var enabled = false
        public var nonFoliageMain: Int
        public var otherFoliageMain: Int
        /// All submitted non-elm shadow triangles over all passes, not just on-camera casters.
        public var nonElmAllPassShadow: Int?
        /// Occupied main draw slots excluding elms. Postprocessing is reported separately.
        public var nonElmMainDraws: Int
        public var postprocessDraws: Int?
        public init(nonFoliageMain: Int, otherFoliageMain: Int, nonElmAllPassShadow: Int?, nonElmMainDraws: Int, postprocessDraws: Int? = nil) {
            self.nonFoliageMain = nonFoliageMain; self.otherFoliageMain = otherFoliageMain
            self.nonElmAllPassShadow = nonElmAllPassShadow; self.nonElmMainDraws = nonElmMainDraws
            self.postprocessDraws = postprocessDraws
        }
    }
    public struct Ledger: Sendable {
        public let foliageAllowance: Int, elmAllowance: Int, nonFoliageMain: Int, otherFoliageMain: Int
        public let elmMain: Int, wholeMain: Int, allPassShadow: Int, mainDraws: Int
        public let postprocessDraws: Int?
        public var standardMainHeadroom: Int { 500_000 - wholeMain }
        public var standardShadowHeadroom: Int { 180_000 - allPassShadow }
        public var standardDrawHeadroom: Int { 120 - mainDraws }
        public var mainFloorGap: Int { max(0, wholeMain - 400_000) }
        public var shadowFloorGap: Int { max(0, allPassShadow - 150_000) }
        public var drawFloorGap: Int { max(0, mainDraws - 100) }
        public var strictFloorPass: Bool { wholeMain < 400_000 && allPassShadow < 150_000 && mainDraws < 100 }
    }
    public struct Denial: Sendable {
        public let sourceID: String, requested: Level, assigned: Level, reason: String
        public var log: String { "CROWN_DENIED source=\(sourceID) requested=\(requested) assigned=\(assigned) reason=\(reason)" }
    }
    public struct Result: Sendable {
        public let assigned: [String: Level], ledger: Ledger, denied: [Denial]
    }
    public enum Failure: Error, Equatable {
        case invalidInput, missingMeasuredCost(String), unknownShadowCost(String), fallbackOverBudget(String)
    }
    /// Use actual projected crown height in drawable pixels and invariant reference bounds.
    /// Skyline eligibility comes from the existing distance rule; this method never culls a tree.
    public static func desired(pixels: Double, previous: Level? = nil, skylineEligible: Bool = false) -> Level {
        let near = previous == .near ? 18.0 : (previous == nil ? 20.0 : 22.0)
        let middle = (previous.map { $0 >= .middle } ?? false) ? 5.4 : (previous == nil ? 6.0 : 6.6)
        if pixels >= near { return .near }
        if pixels >= middle { return .middle }
        return skylineEligible ? .skyline : .far
    }
    /// Returns nil when disabled, without examining data or changing existing assignments.
    public static func allocate(_ crowns: [Crown], inputs: Inputs) throws -> Result? {
        guard inputs.enabled else { return nil }
        guard inputs.nonFoliageMain >= 0, inputs.otherFoliageMain >= 0, inputs.nonElmMainDraws >= 0,
              inputs.postprocessDraws.map({ $0 >= 0 }) ?? true,
              Set(crowns.map(\.sourceID)).count == crowns.count,
              crowns.allSatisfy({ !$0.sourceID.isEmpty && $0.eyeDistance.isFinite && $0.eyeDistance >= 0 && $0.fallback <= .far && $0.requested >= $0.fallback }) else { throw Failure.invalidInput }
        guard let baseShadow = inputs.nonElmAllPassShadow else { throw Failure.unknownShadowCost("non-elm") }
        guard baseShadow >= 0 else { throw Failure.invalidInput }
        let f = max(0, min(120_000, 500_000 - inputs.nonFoliageMain - 20_000))
        let e = max(0, f - inputs.otherFoliageMain)
        // Validate the entire requested chain before decisions; unknown costs never become zero.
        for crown in crowns {
            for level in Level.allCases where level >= crown.fallback && level <= crown.requested {
                guard let cost = crown.costs[level] else { throw Failure.missingMeasuredCost(crown.sourceID) }
                guard cost.main >= 0, (cost.main == 0 || !cost.drawSlots.isEmpty), cost.drawSlots.allSatisfy({ !$0.isEmpty }) else { throw Failure.invalidInput }
                guard let shadow = cost.allPassShadow else { throw Failure.unknownShadowCost(crown.sourceID) }
                guard shadow >= 0 else { throw Failure.invalidInput }
            }
        }
        var assigned = Dictionary(uniqueKeysWithValues: crowns.map { ($0.sourceID, $0.fallback) })
        var elm = 0, shadow = baseShadow, slots: [String: Int] = [:]
        func add(_ cost: Cost, sign: Int) {
            elm += sign * cost.main; shadow += sign * cost.allPassShadow!
            for slot in cost.drawSlots { slots[slot, default: 0] += sign; if slots[slot] == 0 { slots.removeValue(forKey: slot) } }
        }
        for crown in crowns { add(crown.costs[crown.fallback]!, sign: 1) }
        func violation() -> String? {
            if elm > e || inputs.otherFoliageMain + elm > f { return "foliageAllowance" }
            if inputs.nonFoliageMain + inputs.otherFoliageMain + elm > 500_000 { return "mainTriangles" }
            if inputs.nonElmMainDraws + slots.count > 120 { return "mainDraws" }
            if shadow > 180_000 { return "allPassShadow" }
            return nil
        }
        if let reason = violation() { throw Failure.fallbackOverBudget(reason) }
        var denied: [Denial] = []
        let ordered = crowns.sorted { $0.eyeDistance == $1.eyeDistance ? $0.sourceID < $1.sourceID : $0.eyeDistance < $1.eyeDistance }
        for crown in ordered {
            for level in Level.allCases where level > crown.fallback && level <= crown.requested {
                let old = crown.costs[assigned[crown.sourceID]!]!, next = crown.costs[level]!
                add(old, sign: -1); add(next, sign: 1)
                if let reason = violation() {
                    add(next, sign: -1); add(old, sign: 1)
                    denied.append(Denial(sourceID: crown.sourceID, requested: crown.requested, assigned: assigned[crown.sourceID]!, reason: reason))
                    break
                }
                assigned[crown.sourceID] = level
            }
        }
        return Result(assigned: assigned, ledger: Ledger(foliageAllowance: f, elmAllowance: e,
            nonFoliageMain: inputs.nonFoliageMain, otherFoliageMain: inputs.otherFoliageMain,
            elmMain: elm, wholeMain: inputs.nonFoliageMain + inputs.otherFoliageMain + elm,
            allPassShadow: shadow, mainDraws: inputs.nonElmMainDraws + slots.count,
            postprocessDraws: inputs.postprocessDraws), denied: denied)
    }
}
