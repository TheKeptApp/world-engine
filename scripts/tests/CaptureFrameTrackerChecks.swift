import Foundation

@main struct CaptureFrameTrackerChecks {
    static func main() {
        let tracker = CaptureFrameTracker()
        precondition(tracker.submit(width: 1005, height: 565) == nil)
        tracker.begin(); precondition(tracker.proof() == nil)
        tracker.noteScene("pose-A/context-6")
        let a = tracker.submit(width: 1005, height: 565)!
        let b = tracker.submit(width: 1005, height: 565)!
        let c = tracker.submit(width: 1005, height: 565)!
        tracker.complete(c, succeeded: true); precondition(tracker.proof() == nil) // out of order
        tracker.complete(a, succeeded: true); precondition(tracker.proof() == nil)
        tracker.complete(b, succeeded: true); precondition(tracker.proof()?.stableFrames == 3)
        tracker.complete(b, succeeded: true); precondition(tracker.proof()?.stableFrames == 3) // duplicate
        tracker.noteScene("pose-B/context-6"); precondition(tracker.proof() == nil)
        let old = tracker.submit(width: 1005, height: 565)!
        tracker.begin(); tracker.noteScene("pose-B/context-6")
        tracker.complete(old, succeeded: true); precondition(tracker.proof() == nil) // prior epoch
        for _ in 0..<3 { tracker.complete(tracker.submit(width: 1005, height: 565)!, succeeded: true) }
        precondition(tracker.proof() != nil)
        tracker.complete(tracker.submit(width: 1010, height: 565)!, succeeded: true)
        precondition(tracker.proof() == nil) // resize resets stability
        tracker.complete(tracker.submit(width: 1010, height: 565)!, succeeded: false)
        precondition(tracker.failure != nil && tracker.proof() == nil)
        tracker.end(); precondition(tracker.submit(width: 1005, height: 565) == nil)
        tracker.begin(); tracker.noteScene("A")
        let stale = tracker.submit(width: 1005, height: 565)!
        tracker.noteScene("B"); tracker.complete(stale, succeeded: true)
        precondition(tracker.proof(requiredFrames: 1) == nil) // old scene revision
        precondition(tracker.submit(width: 0, height: 565) == nil)
        print("CaptureFrameTracker: inactive/pending, ordered completions, duplicates, pose, epoch, resize, failure, stale revision, zero-size checks passed")
    }
}
