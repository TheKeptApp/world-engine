import Foundation

/// Capture-only decoded-pixel witness. Exact output equality is stronger than stable luminance.
/// Each accepted sample must follow a new completed Metal frame; duplicate observations don't count.
public struct CaptureOutputStability: Sendable {
    public private(set) var stableSamples = 0
    public private(set) var observations = 0
    public private(set) var lastCompletedSequence = 0
    private var previous: Data?
    public init() {}
    public mutating func observe(pixels: Data, completedSequence: Int) -> Bool {
        guard !pixels.isEmpty, completedSequence > lastCompletedSequence else { return false }
        lastCompletedSequence = completedSequence; observations += 1
        stableSamples = previous == pixels ? stableSamples + 1 : 1
        previous = pixels
        return stableSamples >= 3
    }
}
