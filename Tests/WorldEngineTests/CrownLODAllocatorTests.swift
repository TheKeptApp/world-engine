import Foundation
import Testing
@testable import WorldEngine

@Suite("Crown budget allocator")
struct CrownLODAllocatorTests {
    @Test func budgetContract() throws {
        typealias A = CrownLODAllocator
        // Synthetic costs, including illustrative pack caps; not measured native mesh costs.
        func tree(_ id: String, _ distance: Double, _ requested: A.Level = .near) -> A.Crown {
            .init(sourceID: id, eyeDistance: distance, fallback: .far, requested: requested, costs: [
                .far: .init(main: 80, allPassShadow: 80, drawSlots: ["far"]),
                .middle: .init(main: 360, allPassShadow: 360, drawSlots: ["middle"]),
                .near: .init(main: 1200, allPassShadow: 1200, drawSlots: ["near"])])
        }
        var input = A.Inputs(nonFoliageMain: 172459, otherFoliageMain: 118000, nonElmAllPassShadow: 10000, nonElmMainDraws: 20)
        let disabled = try A.allocate([tree("b", 2)], inputs: input)
        #expect(disabled == nil)
        input.enabled = true
        let result = try A.allocate([tree("b", 2), tree("a", 1)], inputs: input)!
        #expect(result.assigned.count == 2 && result.assigned["a"] == .near && result.assigned["b"] == .middle)
        #expect(result.ledger.foliageAllowance == 120000 && result.ledger.elmAllowance == 2000)
        #expect(result.ledger.elmMain == 1560 && result.ledger.mainDraws == 22)
        #expect(result.denied.count == 1 && result.denied[0].sourceID == "b")
        print(result.denied[0].log + " fixture=true")
        let tie = try A.allocate([tree("b", 1), tree("a", 1)], inputs: input)!
        #expect(tie.assigned == result.assigned)
        input.nonElmMainDraws = 119
        let single = try A.allocate([tree("a", 1)], inputs: input)!
        #expect(single.assigned["a"] == .near && single.ledger.mainDraws == 120) // replaces last old slot
        let two = try A.allocate([tree("a", 1), tree("b", 2)], inputs: input)!
        #expect(two.assigned.values.allSatisfy { $0 == .far } && two.denied.allSatisfy { $0.reason == "mainDraws" })
        input.nonElmMainDraws = 20; input.nonElmAllPassShadow = 179000
        let shadow = try A.allocate([tree("a", 1)], inputs: input)!
        #expect(shadow.assigned["a"] == .middle && shadow.denied[0].reason == "allPassShadow")
        input.otherFoliageMain = 120000
        do { _ = try A.allocate([tree("a", 1)], inputs: input); fatalError("fallback should fail") }
        catch A.Failure.fallbackOverBudget(_) {}
        input.nonElmAllPassShadow = nil
        do { _ = try A.allocate([], inputs: input); fatalError("unknown shadow should fail") }
        catch A.Failure.unknownShadowCost(_) {}
        input.nonElmAllPassShadow = 0; input.otherFoliageMain = 0; input.nonFoliageMain = 480000
        let empty = try A.allocate([], inputs: input)!
        #expect(empty.ledger.foliageAllowance == 0)
        input.nonFoliageMain = 400000
        let boundary = try A.allocate([], inputs: input)!
        #expect(boundary.ledger.mainFloorGap == 0 && !boundary.ledger.strictFloorPass)
        input.nonFoliageMain = 450000
        let headroom = try A.allocate([], inputs: input)!
        #expect(headroom.ledger.foliageAllowance == 30000)
        var skyline = tree("skyline", 5000, .far)
        skyline.fallback = .skyline
        skyline.costs[.skyline] = .init(main: 12, allPassShadow: 24, drawSlots: ["skyline"])
        let reserved = try A.allocate([skyline], inputs: input)!
        #expect(reserved.assigned["skyline"] == .far)
        var unknown = tree("unknown", 1)
        unknown.costs[.near]?.allPassShadow = nil
        do { _ = try A.allocate([unknown], inputs: input); fatalError("unknown per-tree shadow should fail") }
        catch A.Failure.unknownShadowCost(_) {}
        do { _ = try A.allocate([tree("dup", 1),tree("dup", 2)], inputs: input); fatalError("duplicate IDs should fail") }
        catch A.Failure.invalidInput {}
        #expect(A.desired(pixels: 20) == .near && A.desired(pixels: 6) == .middle)
        #expect(A.desired(pixels: 18, previous: .near) == .near)
        #expect(A.desired(pixels: 21.9, previous: .middle) == .middle)
        #expect(A.desired(pixels: 22, previous: .middle) == .near)
        #expect(A.desired(pixels: 5.4, previous: .middle) == .middle)
        #expect(A.desired(pixels: 6.59, previous: .far) == .far)
        #expect(A.desired(pixels: 6.6, previous: .far) == .middle)
        #expect(A.desired(pixels: 2, skylineEligible: true) == .skyline)
        print("CrownLODAllocator: disabled, reserve, nearest-first, stable ties, conserved instances, draw replacement, shadow, fallback failure, missing data, floor boundary and hysteresis checks passed")
    }
}
