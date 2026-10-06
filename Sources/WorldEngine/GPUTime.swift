import Darwin
import Foundation

/// GPU time used by this process so far, from the kernel's per-task accounting
/// (`TASK_POWER_INFO_V2`, `gpu_energy.task_gpu_utilisation`, nanoseconds). RealityKit renders in
/// the app's process, so the per-frame difference is the frame's GPU time at the GPU's real clock
/// (unlike Instruments, which pins the GPU to its minimum clock while tracing).
enum TaskGPUTime {
    static func nanoseconds() -> UInt64? {
        var info = task_power_info_v2()
        var count = mach_msg_type_number_t(MemoryLayout<task_power_info_v2>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_POWER_INFO_V2), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? info.gpu_energy.task_gpu_utilisation : nil
    }
}
