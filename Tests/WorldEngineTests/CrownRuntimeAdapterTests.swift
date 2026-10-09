import Testing
@testable import WorldEngine

struct CrownRuntimeAdapterTests {
    @Test func offIdentityElmOnlyCutAwayAndFailureAtomicity() throws {
        var adapter = CrownRuntimeAdapter()
        let costs = Dictionary(uniqueKeysWithValues: CrownLODAllocator.Level.allCases.map {
            ($0, CrownLODAllocator.Cost(main: [12,80,360,1200][$0.rawValue], allPassShadow: 0, drawSlots: ["slot-\($0.rawValue)"]))
        })
        func c(_ id: String, _ species: String? = "ulmus_americana", bare: Bool = false, slot: Int = 1) -> CrownRuntimeAdapter.Candidate {
            .init(sourceID: id, species: species, bare: bare, distance: 10, projectedPixels: 30,
                  skylineEligible: false, legacySlot: slot, costs: costs)
        }
        let inputs = CrownLODAllocator.Inputs(nonFoliageMain: 10000, otherFoliageMain: 1000, nonElmAllPassShadow: 0, nonElmMainDraws: 10)
        let off = try adapter.plan([c("elm")], inputs: inputs)
        #expect(off == nil); #expect(adapter.previous.isEmpty); #expect(adapter.result == nil)
        adapter.enabled = true
        let slots = try adapter.plan([c("elm", slot: 0), c("cottonwood", "populus_deltoides"), c("unknown", nil), c("bare", bare: true)], inputs: inputs)
        #expect(slots == ["elm": 0]); #expect(adapter.result?.ledger.elmMain == 1200)
        var shared = inputs; shared.occupiedNonElmDrawSlots = ["slot-3"]
        let sharedResult = try adapter.plan([c("elm")], inputs: shared)
        #expect(sharedResult == ["elm": 1]); #expect(adapter.result?.ledger.mainDraws == 10)
        var missing = inputs; missing.nonElmAllPassShadow = nil
        #expect(throws: CrownLODAllocator.Failure.unknownShadowCost("non-elm")) { try adapter.plan([c("elm")], inputs: missing) }
        #expect(adapter.previous == ["elm": .near])
        adapter.enabled = false
        let disabled = try adapter.plan([], inputs: missing)
        #expect(disabled == nil)
    }
}

@MainActor
struct CrownBudgetRuntimeTests {
    @Test func measurementsRequiredAndOccupiedBatchIdentity() throws {
        var runtime = CrownBudgetRuntime()
        let off = try runtime.allocate([], requests: [])
        #expect(off == nil)
        runtime.adapter.enabled = true
        #expect(throws: CrownLODAllocator.Failure.invalidInput) { try runtime.allocate([], requests: []) }
        #expect(runtime.failure != nil)
        runtime.drawableHeight = 565
        runtime.referenceCrownHeight = { _ in 10 }
        let costs = Dictionary(uniqueKeysWithValues: CrownLODAllocator.Level.allCases.map {
            ($0, CrownLODAllocator.Cost(main: [12,80,360,1200][$0.rawValue], allPassShadow: 0, drawSlots: ["batch-\($0.rawValue)"]))
        })
        let request = CrownMeshRequest(sourceID: "elm", nativeTriangles: costs.mapValues(\.main),
            batchSlots: Dictionary(uniqueKeysWithValues: CrownLODAllocator.Level.allCases.map { ($0,$0.rawValue) }))
        let candidate = CrownRuntimeAdapter.Candidate(sourceID: "elm", species: "ulmus_americana", bare: false,
            distance: 10, projectedPixels: 30, skylineEligible: false, legacySlot: 1, costs: [:])
        runtime.measure = { requests in
            #expect(requests.count == 1)
            return .init(inputs: .init(nonFoliageMain: 10000, otherFoliageMain: 1000, nonElmAllPassShadow: 0, nonElmMainDraws: 10), costs: ["elm": costs])
        }
        let on = try runtime.allocate([candidate], requests: [request])
        #expect(on == ["elm": 1]); #expect(runtime.failure == nil)
        runtime.measure = { _ in
            var wrong = costs; wrong[.near]?.drawSlots = ["wrong-batch"]
            return .init(inputs: .init(nonFoliageMain: 10000, otherFoliageMain: 1000, nonElmAllPassShadow: 0, nonElmMainDraws: 10), costs: ["elm": wrong])
        }
        #expect(throws: CrownLODAllocator.Failure.invalidInput) { try runtime.allocate([candidate], requests: [request]) }
        #expect(runtime.adapter.previous == ["elm": .near])
        runtime.referenceCrownHeight = { _ in nil }
        #expect(throws: CrownLODAllocator.Failure.invalidInput) { try runtime.allocate([candidate], requests: [request]) }
        #expect(runtime.adapter.previous == ["elm": .near])
    }
}
