import Foundation

@MainActor
private final class CaptureTaskCompletion { var done = false }

@MainActor
extension World {
    /// Capture-only wait; interactive World.load still returns before the context ring.
    public func awaitCaptureSceneCompletion(timeout: TimeInterval = 60) async throws {
        try Task.checkCancellation()
        let deadline = Date().addingTimeInterval(timeout)
        func check() throws {
            try Task.checkCancellation()
            if Date() >= deadline { throw NSError(domain: "SceneReady", code: 1, userInfo: [NSLocalizedDescriptionKey: "Scene loading timed out"]) }
        }
        while captureSceneState == .pending {
            try check(); try await Task.sleep(for: .milliseconds(20))
        }
        if case .failed(let reason) = captureSceneState {
            throw NSError(domain: "SceneReady", code: 2, userInfo: [NSLocalizedDescriptionKey: reason])
        }
        // Context attachment can reapply the environment; drain the latest pending IBL generation.
        while let task = environmentState.iblTask {
            let generation = environmentState.lastIBL?.time
            let completion = CaptureTaskCompletion()
            let observer = Task { @MainActor in await task.value; completion.done = true }
            defer { observer.cancel() }
            while !completion.done { try check(); try await Task.sleep(for: .milliseconds(20)) }
            if generation != environmentState.lastIBL?.time { continue }
            guard !task.isCancelled, skyEnvironment != nil else {
                throw NSError(domain: "SceneReady", code: 3, userInfo: [NSLocalizedDescriptionKey: "Image-based light did not finish successfully"])
            }
            break
        }
    }
}
