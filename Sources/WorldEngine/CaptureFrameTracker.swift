import Foundation

public enum CaptureSceneState: Sendable, Equatable {
    case notRequired, pending, ready, failed(String)
}

/// Capture-only observer. Scene updates are not GPU completions; tickets finish from Metal callbacks.
public final class CaptureFrameTracker: @unchecked Sendable {
    public struct Ticket: Sendable {
        fileprivate let epoch: Int, revision: Int
        public let sequence: Int, signature: String, width: Int, height: Int
    }
    public struct Proof: Sendable {
        public let sequence: Int, signature: String, width: Int, height: Int, stableFrames: Int
    }
    private let lock = NSLock()
    private var armed = false
    private var epoch = 0, revision = 0, issued = 0, processed = 0, stable = 0
    private var scene: String?
    private var previous: Ticket?
    private var pending: [Int: (Ticket, Bool)] = [:]
    private var error: String?
    public init() {}
    public var isArmed: Bool { lock.lock(); defer { lock.unlock() }; return armed }
    public func begin() {
        lock.lock(); defer { lock.unlock() }
        epoch += 1; revision = 0; issued = 0; processed = 0; stable = 0
        scene = nil; previous = nil; pending = [:]; error = nil; armed = true
    }
    public func end() { lock.lock(); defer { lock.unlock() }; armed = false; epoch += 1; pending = [:] }
    public func noteScene(_ signature: String) {
        lock.lock(); defer { lock.unlock() }
        guard armed else { return }
        if scene != signature { revision += 1; stable = 0; previous = nil }
        scene = signature
    }
    public func submit(width: Int, height: Int) -> Ticket? {
        lock.lock(); defer { lock.unlock() }
        guard armed, let scene, width > 0, height > 0 else { return nil }
        issued += 1
        return Ticket(epoch: epoch, revision: revision, sequence: issued, signature: scene, width: width, height: height)
    }
    public func complete(_ ticket: Ticket, succeeded: Bool) {
        lock.lock(); defer { lock.unlock() }
        guard armed, ticket.epoch == epoch, ticket.sequence > processed else { return }
        pending[ticket.sequence] = (ticket, succeeded)
        while let (next, success) = pending.removeValue(forKey: processed + 1) {
            processed += 1
            guard success else { error = "Metal frame command buffer failed"; stable = 0; continue }
            guard next.revision == revision else { continue }
            if let old = previous, old.revision == next.revision, old.width == next.width, old.height == next.height {
                stable += 1
            } else { stable = 1 }
            previous = next
        }
    }
    public var failure: String? { lock.lock(); defer { lock.unlock() }; return error }
    public func proof(requiredFrames: Int = 3) -> Proof? {
        lock.lock(); defer { lock.unlock() }
        guard armed, error == nil, stable >= requiredFrames, let last = previous, last.revision == revision else { return nil }
        return Proof(sequence: last.sequence, signature: last.signature, width: last.width, height: last.height, stableFrames: stable)
    }
}
