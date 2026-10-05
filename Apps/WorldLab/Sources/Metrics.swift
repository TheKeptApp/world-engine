import Foundation
import Observation
import UIKit
import WorldEngine

/// HUD numbers, refreshed once a second.
@MainActor
@Observable
final class Metrics {
    var fps = 0.0
    var frameMs = 0.0
    var gpuMs = 0.0
    var memoryMB = 0.0
    var thermal = "nominal"

    @ObservationIgnored private var frames: [Double] = []
    @ObservationIgnored private var gpu: [Double] = []
    @ObservationIgnored private var last = Date()

    func start(world: World?) { last = Date() }

    func frame(dt: Double, gpuMs sample: Double?) {
        frames.append(dt * 1000)
        if let g = sample { gpu.append(g) }
        let now = Date()
        guard now.timeIntervalSince(last) >= 1 else { return }
        fps = Double(frames.count) / now.timeIntervalSince(last)
        frameMs = frames.reduce(0, +) / Double(max(1, frames.count))
        gpuMs = gpu.isEmpty ? 0 : gpu.reduce(0, +) / Double(gpu.count)
        memoryMB = Self.footprintMB()
        thermal = Self.thermalName()
        frames.removeAll(keepingCapacity: true)
        gpu.removeAll(keepingCapacity: true)
        last = now
    }

    static func thermalName() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }

    /// Physical memory footprint of the app process (what iOS counts against its limit).
    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : 0
    }
}

/// The 10-minute matched test: identical loop, camera, time, brightness for every renderer.
/// Writes Documents/<renderer>-<stamp>-frames.csv (every frame), -seconds.csv (per second) and
/// -summary.json, then restores the screen settings.
@MainActor
@Observable
final class TestRun {
    /// 600 s for the matched test; `-testseconds N` shortens it for checks.
    static let duration: Double = ProcessInfo.processInfo.arguments.firstIndex(of: "-testseconds")
        .flatMap { i in ProcessInfo.processInfo.arguments.dropFirst(i + 1).first.flatMap(Double.init) } ?? 600
    static let brightness: CGFloat = 0.5

    let renderer: String
    var statusLine = ""
    var finished = false
    /// Extra header text (e.g. the web backend actually in use), set before `begin()`.
    @ObservationIgnored var note = ""

    @ObservationIgnored private var start = Date()
    @ObservationIgnored private var lastSecond = Date()
    @ObservationIgnored private var frames: [Float] = []
    @ObservationIgnored private var secondFrames: [Double] = []
    @ObservationIgnored private var gpuAll: [Float] = []
    @ObservationIgnored private var secondGPU: [Double] = []
    @ObservationIgnored private var thermal: [(Double, String)] = []
    @ObservationIgnored private var memoryPeak = 0.0
    @ObservationIgnored private var batteryStart: Float = -1
    @ObservationIgnored private var savedBrightness: CGFloat = 0.5
    @ObservationIgnored private var secondsLog: FileHandle?
    @ObservationIgnored private var framesLog: FileHandle?
    @ObservationIgnored private var base = ""
    @ObservationIgnored private let header: String

    init(renderer: String, stats: WorldStats?) {
        self.renderer = renderer
        if let s = stats {
            header = "# renderer=\(renderer) triangles=\(s.triangles) drawCalls=\(s.drawCalls) meshBytes=\(s.meshBytes) build=\(String(format: "%.2f", s.buildSeconds))s light=\(s.lightKeys)"
        } else {
            header = "# renderer=\(renderer)"
        }
    }

    func begin() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        base = docs.appendingPathComponent("\(renderer)-\(f.string(from: Date()))").path
        FileManager.default.createFile(atPath: base + "-seconds.csv", contents: nil)
        FileManager.default.createFile(atPath: base + "-frames.csv", contents: nil)
        secondsLog = FileHandle(forWritingAtPath: base + "-seconds.csv")
        framesLog = FileHandle(forWritingAtPath: base + "-frames.csv")
        let screen = UIScreen.main.bounds.size, scale = UIScreen.main.scale
        write(secondsLog, "\(header) \(note) screen=\(Int(screen.width * scale))x\(Int(screen.height * scale))\n")
        write(secondsLog, "seconds,fps,frame_ms_avg,frame_ms_max,pct_over_16_9,gpu_ms_avg,memory_mb,thermal,battery\n")
        write(framesLog, "frame_ms,gpu_ms\n")
        UIApplication.shared.isIdleTimerDisabled = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryStart = UIDevice.current.batteryLevel
        savedBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = Self.brightness
        start = Date()
        lastSecond = start
        thermal = [(0, Metrics.thermalName())]
    }

    /// One presented frame (interval in seconds) and, when available, its GPU time in ms.
    func frame(dt: Double, gpuMs: Double?) {
        guard !finished else { return }
        let ms = dt * 1000
        frames.append(Float(ms))
        secondFrames.append(ms)
        if let g = gpuMs { gpuAll.append(Float(g)); secondGPU.append(g) }
        write(framesLog, String(format: "%.3f,%@\n", ms, gpuMs.map { String(format: "%.3f", $0) } ?? ""))
        let now = Date()
        let t = now.timeIntervalSince(start)
        guard now.timeIntervalSince(lastSecond) >= 1 else { return }
        let fps = Double(secondFrames.count) / now.timeIntervalSince(lastSecond)
        let avg = secondFrames.reduce(0, +) / Double(max(1, secondFrames.count))
        let over = Double(secondFrames.filter { $0 > 16.9 }.count) / Double(max(1, secondFrames.count)) * 100
        let gpu = secondGPU.isEmpty ? 0 : secondGPU.reduce(0, +) / Double(secondGPU.count)
        let mem = Metrics.footprintMB()
        memoryPeak = max(memoryPeak, mem)
        let th = Metrics.thermalName()
        if thermal.last?.1 != th { thermal.append((t, th)) }
        write(secondsLog, String(format: "%.0f,%.1f,%.2f,%.2f,%.2f,%.2f,%.0f,%@,%.2f\n", t, fps, avg, secondFrames.max() ?? 0, over, gpu, mem, th,
                                 UIDevice.current.batteryLevel))
        statusLine = String(format: "TEST %@ %.0f/%.0f s  %@", renderer, t, Self.duration, th)
        secondFrames.removeAll(keepingCapacity: true)
        secondGPU.removeAll(keepingCapacity: true)
        lastSecond = now
        if t >= Self.duration { finish() }
    }

    func finish() {
        guard !finished else { return }
        finished = true
        // Steady state: drop the first 5 s.
        let steadyStart = frames.firstIndex { _ in true }.map { _ in 0 } ?? 0
        var acc = 0.0
        var skip = 0
        for (i, f) in frames.enumerated() { acc += Double(f); if acc > 5000 { skip = i; break } }
        let steady = Array(frames.dropFirst(max(skip, steadyStart)))
        let total = steady.reduce(0) { $0 + Double($1) }
        let avgFps = Double(steady.count) / (total / 1000)
        let sorted = steady.sorted(by: >)
        let worst = sorted.prefix(max(1, sorted.count / 100))
        let low1 = 1000 / (worst.reduce(0) { $0 + Double($1) } / Double(worst.count))
        let over = Double(steady.filter { $0 > 16.9 }.count) / Double(max(1, steady.count)) * 100
        let gpuSorted = gpuAll.sorted()
        let batteryEnd = UIDevice.current.batteryLevel
        let summary: [String: Any] = [
            "renderer": renderer,
            "seconds": Date().timeIntervalSince(start),
            "frames": steady.count,
            "averageFps": avgFps,
            "onePercentLowFps": low1,
            "percentFramesOver16_9ms": over,
            "maxFrameMs": Double(sorted.first ?? 0),
            "gpuMsMean": gpuSorted.isEmpty ? NSNull() : gpuSorted.reduce(0, +) / Float(gpuSorted.count),
            "gpuMsP95": gpuSorted.isEmpty ? NSNull() : gpuSorted[min(gpuSorted.count - 1, Int(Double(gpuSorted.count) * 0.95))],
            "gpuMsMax": gpuSorted.last.map { $0 as Any } ?? NSNull(),
            "thermal": thermal.map { ["t": $0.0, "state": $0.1] },
            "memoryPeakMB": memoryPeak,
            "batteryStart": batteryStart,
            "batteryEnd": batteryEnd,
            "batteryUsedPercent": batteryStart >= 0 ? Double(batteryStart - batteryEnd) * 100 : -1,
            "header": header,
            "note": note,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: base + "-summary.json"))
        }
        try? secondsLog?.close()
        try? framesLog?.close()
        UIScreen.main.brightness = savedBrightness
        UIApplication.shared.isIdleTimerDisabled = false
        statusLine = String(format: "DONE %@: %.1f fps avg, 1%% low %.1f", renderer, avgFps, low1)
    }

    private func write(_ h: FileHandle?, _ s: String) {
        if let d = s.data(using: .utf8) { h?.write(d) }
    }
}
