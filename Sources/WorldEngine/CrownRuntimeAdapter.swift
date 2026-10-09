import Foundation

/// Renderer adapter contract. No species inference, hypothetical cost substitution or culling.
public struct CrownRuntimeAdapter {
    public struct Candidate {
        public var sourceID: String, species: String?
        public var bare: Bool
        public var distance: Double, projectedPixels: Double
        public var skylineEligible: Bool
        public var legacySlot: Int
        /// Complete current native mesh cost per level, including the near cut-away slot.
        public var costs: [CrownLODAllocator.Level: CrownLODAllocator.Cost]
        public init(sourceID: String, species: String?, bare: Bool, distance: Double, projectedPixels: Double,
                    skylineEligible: Bool, legacySlot: Int, costs: [CrownLODAllocator.Level: CrownLODAllocator.Cost]) {
            self.sourceID = sourceID; self.species = species; self.bare = bare; self.distance = distance
            self.projectedPixels = projectedPixels; self.skylineEligible = skylineEligible
            self.legacySlot = legacySlot; self.costs = costs
        }
    }
    public var enabled = false
    public private(set) var previous: [String: CrownLODAllocator.Level] = [:]
    public private(set) var result: CrownLODAllocator.Result?
    public init() {}
    /// Returns nil while OFF. Enabled errors preserve the previous state; caller must reject candidate.
    public mutating func plan(_ candidates: [Candidate], inputs: CrownLODAllocator.Inputs) throws -> [String: Int]? {
        guard enabled else { return nil }
        let eligible = candidates.filter { $0.species == "ulmus_americana" && !$0.bare }
        guard eligible.allSatisfy({ $0.projectedPixels.isFinite && $0.projectedPixels >= 0 && (0...4).contains($0.legacySlot) }) else {
            throw CrownLODAllocator.Failure.invalidInput
        }
        let crowns = eligible.map { c in
            let desired = CrownLODAllocator.desired(pixels: c.projectedPixels, previous: previous[c.sourceID], skylineEligible: c.skylineEligible)
            let fallback: CrownLODAllocator.Level = c.skylineEligible ? .skyline : .far
            return CrownLODAllocator.Crown(sourceID: c.sourceID, eyeDistance: c.distance, fallback: fallback,
                requested: max(fallback, desired), costs: c.costs)
        }
        var enabledInputs = inputs; enabledInputs.enabled = true
        let allocated = try CrownLODAllocator.allocate(crowns, inputs: enabledInputs)!
        let legacy = Dictionary(uniqueKeysWithValues: eligible.map { ($0.sourceID, $0.legacySlot) })
        var slots: [String: Int] = [:]
        for (id, level) in allocated.assigned {
            slots[id] = level == .near ? (legacy[id] == 0 ? 0 : 1) : (level == .middle ? 2 : (level == .far ? 3 : 4))
        }
        previous = allocated.assigned; result = allocated
        return slots
    }
}

/// P2/5A handoff: caller certifies current-frame submitted costs, not mesh-cap hypotheses.
public struct CrownBudgetMeasurement {
    public var inputs: CrownLODAllocator.Inputs
    public var costs: [String: [CrownLODAllocator.Level: CrownLODAllocator.Cost]]
    public init(inputs: CrownLODAllocator.Inputs, costs: [String: [CrownLODAllocator.Level: CrownLODAllocator.Cost]]) {
        self.inputs = inputs; self.costs = costs
    }
}
public struct CrownMeshRequest {
    public var sourceID: String
    public var nativeTriangles: [CrownLODAllocator.Level: Int]
    public var batchSlots: [CrownLODAllocator.Level: Int]
    public init(sourceID: String, nativeTriangles: [CrownLODAllocator.Level: Int], batchSlots: [CrownLODAllocator.Level: Int]) {
        self.sourceID = sourceID; self.nativeTriangles = nativeTriangles; self.batchSlots = batchSlots
    }
}
@MainActor
public struct CrownBudgetRuntime {
    public var adapter = CrownRuntimeAdapter()
    /// Actual drawable height, never SwiftUI points. Host supplies renderer drawable size.
    public var drawableHeight: Double = 0
    /// Invariant measured crown height in object metres, supplied with P2's mesh (not whole-tree bounds).
    public var referenceCrownHeight: ((String) -> Double?)?
    /// Called on each enabled re-evaluation; includes every pass/cascade and non-elm submissions.
    public var measure: (([CrownMeshRequest]) throws -> CrownBudgetMeasurement)?
    public private(set) var failure: String?
    public init() {}
    public mutating func allocate(_ candidates: [CrownRuntimeAdapter.Candidate], requests: [CrownMeshRequest]) throws -> [String: Int]? {
        guard adapter.enabled else { return nil }
        do {
            guard drawableHeight.isFinite, drawableHeight > 0, referenceCrownHeight != nil, let measure else { throw CrownLODAllocator.Failure.invalidInput }
            for candidate in candidates {
                guard let height = referenceCrownHeight?(candidate.sourceID), height.isFinite, height > 0 else {
                    throw CrownLODAllocator.Failure.invalidInput
                }
            }
            let measurements = try measure(requests)
            var measured = candidates
            for index in measured.indices {
                guard let costs = measurements.costs[measured[index].sourceID] else {
                    throw CrownLODAllocator.Failure.missingMeasuredCost(measured[index].sourceID)
                }
                measured[index].costs = costs
                // Costs must describe the actual batch slot occupied by this candidate.
                for (level, cost) in costs {
                    guard let request = requests.first(where: { $0.sourceID == measured[index].sourceID }),
                          let slot = request.batchSlots[level], (cost.drawSlots == ["batch-\(slot)"] || (cost.main == 0 && cost.drawSlots.isEmpty)) else {
                        throw CrownLODAllocator.Failure.invalidInput
                    }
                }
            }
            let slots = try adapter.plan(measured, inputs: measurements.inputs)
            failure = nil
            if let result = adapter.result {
                let l = result.ledger
                print("CROWN_LEDGER N=\(l.nonFoliageMain) U=\(l.otherFoliageMain) F=\(l.foliageAllowance) E=\(l.elmAllowance) elm=\(l.elmMain) main=\(l.wholeMain) allPassShadow=\(l.allPassShadow) mainDraws=\(l.mainDraws) postprocessDraws=\(l.postprocessDraws.map(String.init) ?? "unknown") floorMainGap=\(l.mainFloorGap) floorShadowGap=\(l.shadowFloorGap) floorDrawGap=\(l.drawFloorGap) strictFloorPass=\(l.strictFloorPass) standardMainHeadroom=\(l.standardMainHeadroom) standardShadowHeadroom=\(l.standardShadowHeadroom) standardDrawHeadroom=\(l.standardDrawHeadroom)")
                for denied in result.denied { print(denied.log) }
            }
            return slots
        } catch { failure = String(describing: error); throw error }
    }
}
