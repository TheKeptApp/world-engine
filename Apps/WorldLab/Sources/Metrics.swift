import Foundation
import Observation
import WorldEngine

/// Frame, GPU, memory and thermal metrics. With `-metrics on`, logs one CSV row per second to
/// Documents/metrics.csv (pulled off the device after the 10-minute walk test).
@MainActor
@Observable
final class Metrics {
    var fps = 0.0
    var frameMs = 0.0
    var frameMaxMs = 0.0
    var memoryMB = 0.0
    var thermal = "nominal"

    @ObservationIgnored private var frameTimes: [Double] = []
    @ObservationIgnored private var lastPublish = Date()
    @ObservationIgnored private var start = Date()
    @ObservationIgnored private var log: FileHandle?

    func start(logging: Bool, world: World) {
        start = Date()
        guard logging else { return }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("metrics.csv")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        log = try? FileHandle(forWritingTo: url)
        let s = world.stats
        write("# triangles=\(s.triangles) drawCalls=\(s.drawCalls) meshBytes=\(s.meshBytes) chunks=\(s.chunkCount) props=\(s.propInstances) buildSeconds=\(String(format: "%.2f", s.buildSeconds)) profile=\(s.profileID)\n")
        write("seconds,fps,frame_ms_avg,frame_ms_max,memory_mb,thermal\n")
    }

    /// Called every rendered frame with RealityKit's frame delta. GPU time comes from
    /// Instruments (RealityKit Trace) during the device test; it isn't observable in-app.
    func frame(dt: Double, world: World) {
        frameTimes.append(dt * 1000)
        let now = Date()
        guard now.timeIntervalSince(lastPublish) >= 1 else { return }
        frameMs = frameTimes.reduce(0, +) / Double(frameTimes.count)
        frameMaxMs = frameTimes.max() ?? 0
        fps = Double(frameTimes.count) / now.timeIntervalSince(lastPublish)
        memoryMB = Self.footprintMB()
        thermal = switch ProcessInfo.processInfo.thermalState {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
        write(String(format: "%.0f,%.1f,%.2f,%.2f,%.0f,%@\n", now.timeIntervalSince(start), fps, frameMs, frameMaxMs, memoryMB, thermal))
        frameTimes.removeAll(keepingCapacity: true)
        lastPublish = now
    }

    private func write(_ s: String) {
        if let d = s.data(using: .utf8) { log?.write(d) }
    }

    /// Physical memory footprint of the app (what iOS counts against its memory limit).
    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : 0
    }
}
