import Foundation
import Testing
@testable import WorldEngine

struct CaptureOutputStabilityTests {
    @Test func requiresThreeDistinctCompletedFramesAndResetsOnChange() {
        var tracker = CaptureOutputStability()
        func expect(_ actual: Bool, _ expected: Bool = false) { #expect(actual == expected) }
        let a = Data([0, 10, 20, 255]), b = Data([0, 11, 20, 255])
        expect(tracker.observe(pixels: Data(), completedSequence: 1))
        expect(tracker.observe(pixels: a, completedSequence: 1))
        expect(tracker.observe(pixels: a, completedSequence: 1))
        expect(tracker.observe(pixels: a, completedSequence: 2))
        expect(tracker.observe(pixels: b, completedSequence: 3))
        #expect(tracker.stableSamples == 1)
        expect(tracker.observe(pixels: b, completedSequence: 4))
        expect(tracker.observe(pixels: b, completedSequence: 5), true)
        #expect(tracker.observations == 5 && tracker.lastCompletedSequence == 5)
        expect(tracker.observe(pixels: a, completedSequence: 4))
        #expect(tracker.stableSamples == 3)
    }
}
