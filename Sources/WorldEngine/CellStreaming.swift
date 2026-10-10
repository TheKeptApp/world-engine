import Foundation
import Metal
import RealityKit
import WorldGen
import WorldMesh

/// Streaming slice 1 (5A Batch 1, default off: `-diag streamCells`): the near level of each
/// building cell lives in a disk cache, not in memory, and is loaded and unloaded by camera
/// distance under a hard byte cap. Until a cell's near mesh is complete the cell keeps drawing its
/// mid level (coarse stays until the fine part is fully ready; the switch is atomic).
///
/// A8's A4 review rules, applied here: uploads are sliced so one frame spends at most
/// `frameBudget` in upload work, measured as the whole step (allocation, copies, part setup and
/// resource creation), not one API call; and every GPU buffer has one owner: an evicted or
/// cancelled cell drops its mesh resource and any partly filled `LowLevelMesh` at once, so nothing
/// prepared-but-never-drawn outlives its cell.
@MainActor
final class CellStreamer {
    struct Packed {
        let offset: Int
        let vertexBytes: Int
        let indexBytes: Int
        let vertexCount: Int
        let parts: [(indexCount: Int, bounds: BoundingBox)]
        var bytes: Int { vertexBytes + indexBytes }
    }

    /// One upload in flight: the file bytes, the pool slot being filled and how far the copies got.
    private struct Job {
        let cell: Int
        var data: Data?
        var slot: Int?
        var vertexDone = 0
        var indexDone = 0
        /// GPU copy and parts done; attach comes next frame.
        var copiedToGPU = false
    }

    /// A reusable mesh: buffers sized for the largest streamed cell and its resource, both created
    /// at load (allocation and resource creation are single calls longer than the frame budget).
    /// A slot belongs to at most one cell; release returns it to the free list after its entity
    /// stops drawing it, so no buffer is created or abandoned while streaming.
    private struct Slot {
        let mesh: LowLevelMesh
        let resource: MeshResource
    }
    private var slots: [Slot] = []
    private var freeSlots: [Int] = []
    private var slotOf: [Int: Int] = [:]
    /// Fixed bytes held by the slot pool (vertex + index capacity) and the staging buffer.
    private(set) var poolBytes = 0
    /// Shared staging buffer for the job in flight: the CPU fills it in slices; the GPU copies it into
    /// the slot's buffers in one blit (a CPU write to a `LowLevelMesh` buffer costs in proportion to
    /// the whole buffer, so the slices go here instead).
    private var staging: MTLBuffer?
    private var queue: MTLCommandQueue?

    struct Stats {
        var residentBytes = 0, residentCells = 0, loads = 0, evictions = 0, cancelled = 0
        /// Largest single-frame upload time since the last `takeFrameMax()` (seconds).
        var frameMax = 0.0
        var framesOverBudget = 0, uploadFrames = 0
        var reads = 0, readFailures = 0, wanted = 0, nearest = 0.0
        /// Worst time of each upload step (s): mesh allocation, one frame's copies, part setup + resource.
        var allocMax = 0.0, copyMax = 0.0, finishMax = 0.0
        var replaceMax = 0.0, partsMax = 0.0, attachMax = 0.0, finishesOver = 0
    }

    /// Near-level radius plus a prefetch margin (m): cells closer than this are wanted resident.
    var loadRadius: Double = 90
    /// Cells farther than this are released (hysteresis against `loadRadius`).
    var releaseRadius: Double = 140
    /// Hard cap on resident near-level bytes; the farthest resident cells go first.
    var capBytes = 16 * 1_048_576
    /// Upload budget per frame (s), whole step.
    var frameBudget = 0.0005
    /// Bytes copied per slice inside a frame's budget.
    var sliceBytes = 16 * 1024

    private(set) var packed: [Int: Packed] = [:]
    private(set) var resident: [Int: (resource: MeshResource, bytes: Int)] = [:]
    /// Pool slots: total, free (for logs).
    var slotCounts: (total: Int, free: Int) { (slots.count, freeSlots.count) }
    private(set) var stats = Stats()
    private var job: Job?
    private var reading: Int?
    private let file: URL
    private var handle: FileHandle?
    private var writeOffset = 0

    init() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("WorldEngineStream", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        file = dir.appendingPathComponent(UUID().uuidString + ".cells")
        FileManager.default.createFile(atPath: file.path, contents: nil)
        handle = try FileHandle(forWritingTo: file)
    }

    deinit {
        try? FileManager.default.removeItem(at: file)
    }

    /// Writes a cell's near mesh to the cache (the `MeshUpload` layout: 56-byte vertices, then
    /// rebased 32-bit indices). Nothing is uploaded.
    func store(cell: Int, mesh m: WorldMesh.MeshBuffers) throws {
        guard let handle, let b = m.bounds, !m.isEmpty else { return }
        var vertices = Data(count: m.vertexCount * MeshUpload.stride)
        vertices.withUnsafeMutableBytes { raw in MeshUpload.writeVertices(of: [m], into: raw) }
        var indices = Data(count: m.indices.count * 4)
        indices.withUnsafeMutableBytes { raw in
            let dst = raw.bindMemory(to: UInt32.self)
            for (j, idx) in m.indices.enumerated() { dst[j] = idx }
        }
        try handle.write(contentsOf: vertices)
        try handle.write(contentsOf: indices)
        packed[cell] = Packed(offset: writeOffset, vertexBytes: vertices.count, indexBytes: indices.count, vertexCount: m.vertexCount,
                              parts: [(m.indices.count, BoundingBox(min: b.min, max: b.max))])
        writeOffset += vertices.count + indices.count
    }

    /// Ends the write phase (the file is then only read).
    func finishStoring() throws {
        try handle?.close()
        handle = nil
        guard let maxV = packed.values.map(\.vertexCount).max(), let maxI = packed.values.map({ $0.indexBytes / 4 }).max() else { return }
        let slotBytes = maxV * MeshUpload.stride + maxI * 4
        let count = max(2, min(16, capBytes / max(slotBytes, 1)))
        for _ in 0..<count {
            let desc = LowLevelMesh.Descriptor(vertexCapacity: maxV, vertexAttributes: MeshUpload.attributes,
                                               vertexLayouts: [.init(bufferIndex: 0, bufferStride: MeshUpload.stride)],
                                               indexCapacity: maxI, indexType: .uint32)
            let mesh = try LowLevelMesh(descriptor: desc)
            mesh.parts.replaceAll([LowLevelMesh.Part(indexOffset: 0, indexCount: 0, topology: .triangle, materialIndex: 0,
                                                     bounds: BoundingBox(min: .zero, max: .zero))])
            slots.append(Slot(mesh: mesh, resource: try MeshResource(from: mesh)))
        }
        freeSlots = Array(slots.indices)
        let device = MTLCreateSystemDefaultDevice()
        staging = device?.makeBuffer(length: slotBytes, options: .storageModeShared)
        queue = device?.makeCommandQueue()
        poolBytes = (count + 1) * slotBytes
        // Warm the queue and blit path once at load (the first GPU copy costs a few ms of setup;
        // in a frame it broke the upload budget once). Copies 4 bytes into slot 0, whose parts
        // stay empty until it is used.
        if let staging, let cb = queue?.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder(), let first = slots.first {
            let vb = first.mesh.replace(bufferIndex: 0, using: cb)
            blit.copy(from: staging, sourceOffset: 0, to: vb, destinationOffset: 0, size: 4)
            blit.endEncoding()
            cb.commit()
            cb.waitUntilCompleted()
        }
    }

    func isResident(_ cell: Int) -> Bool { resident[cell] != nil }

    /// One frame: chooses the wanted cells from their distances, releases what is far or over the
    /// cap, and advances the upload within the frame budget. `attach`/`detach` give the caller the
    /// finished resource (or take it away); `changed` is true when residency changed (the caller
    /// re-picks LODs).
    func tick(distances: (Int) -> Double, attach: (Int, MeshResource) -> Void, detach: (Int) -> Void) -> Bool {
        var changed = false
        // Release: beyond the release radius, then farthest first while over the cap.
        for cell in resident.keys where distances(cell) > releaseRadius { release(cell, detach: detach); changed = true }
        if stats.residentBytes > capBytes {
            for cell in resident.keys.sorted(by: { distances($0) > distances($1) }) where stats.residentBytes > capBytes {
                release(cell, detach: detach); changed = true
            }
        }
        // A job whose cell went out of range is cancelled: its partial mesh is dropped now.
        if let j = job, distances(j.cell) > releaseRadius {
            if let s = j.slot { freeSlots.append(s) }
            job = nil
            stats.cancelled += 1
        }
        // Next wanted cell: the nearest not resident within the load radius that fits the cap.
        if job == nil, reading == nil {
            let wanted = packed.keys.filter { resident[$0] == nil && distances($0) <= loadRadius }
                .sorted { distances($0) < distances($1) }
            stats.wanted = wanted.count
            stats.nearest = packed.keys.map(distances).min() ?? -1
            if let cell = wanted.first, let p = packed[cell], !freeSlots.isEmpty, stats.residentBytes + p.bytes <= capBytes {
                read(cell, p)
            }
        }
        if upload(attach: attach) { changed = true }
        stats.residentCells = resident.count
        return changed
    }

    func takeFrameMax() -> Stats {
        let s = stats
        stats.frameMax = 0
        return s
    }

    private func release(_ cell: Int, detach: (Int) -> Void) {
        guard let r = resident.removeValue(forKey: cell) else { return }
        detach(cell)
        if let s = slotOf.removeValue(forKey: cell) { freeSlots.append(s) }
        stats.residentBytes -= r.bytes
        stats.evictions += 1
    }

    /// Reads a cell's bytes off the main thread; the upload starts next frame.
    private func read(_ cell: Int, _ p: Packed) {
        reading = cell
        stats.reads += 1
        let url = file
        Task.detached(priority: .utility) {
            let data: Data? = {
                guard let h = try? FileHandle(forReadingFrom: url) else { return nil }
                defer { try? h.close() }
                try? h.seek(toOffset: UInt64(p.offset))
                return try? h.read(upToCount: p.bytes)
            }()
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.reading = nil
                guard let data, data.count == p.bytes else { self.stats.readFailures += 1; return }
                self.job = Job(cell: cell, data: data)
            }
        }
    }

    /// Advances the job by slices until the frame budget is spent. Returns true when a cell became
    /// resident.
    private func upload(attach: (Int, MeshResource) -> Void) -> Bool {
        guard var j = job, let data = j.data, let p = packed[j.cell] else { return false }
        let start = CFAbsoluteTimeGetCurrent()
        func spent() -> Double { CFAbsoluteTimeGetCurrent() - start }
        stats.uploadFrames += 1
        defer {
            let t = spent()
            stats.frameMax = max(stats.frameMax, t)
            if t > frameBudget { stats.framesOverBudget += 1 }
        }
        if j.slot == nil {
            // Oldest-freed slot first: the GPU has long finished with it.
            guard !freeSlots.isEmpty else { return false }
            let s = freeSlots.removeFirst()
            j.slot = s
            job = j
        }
        guard let slot = j.slot else { return false }
        let mesh = slots[slot].mesh
        guard let staging, let queue else { return false }
        // Slices into the staging buffer (plain memory copies) while the frame budget lasts.
        let copyStart = CFAbsoluteTimeGetCurrent()
        var copied = false
        let total = p.vertexBytes + p.indexBytes
        if j.vertexDone < total {
            copied = true
            var done = j.vertexDone
            data.withUnsafeBytes { src in
                repeat {
                    let n = min(sliceBytes, total - done)
                    staging.contents().advanced(by: done).copyMemory(from: src.baseAddress!.advanced(by: done), byteCount: n)
                    done += n
                } while done < total && spent() < frameBudget * 0.8
            }
            j.vertexDone = done
        }
        job = j
        if copied { stats.copyMax = max(stats.copyMax, CFAbsoluteTimeGetCurrent() - copyStart) }
        // Finishing (parts + attach) gets a frame of its own, after the last copy frame.
        if !copied, j.copiedToGPU {
            // Second finishing frame: attach only.
            let resource = slots[slot].resource
            slotOf[j.cell] = slot
            resident[j.cell] = (resource, p.bytes)
            stats.residentBytes += p.bytes
            stats.loads += 1
            let t0 = CFAbsoluteTimeGetCurrent()
            attach(j.cell, resource)
            stats.attachMax = max(stats.attachMax, CFAbsoluteTimeGetCurrent() - t0)
            if spent() > frameBudget { stats.finishesOver += 1 }
            job = nil   // drops the file bytes; the slot stays this cell's until released
            return true
        }
        if !copied {
            let finishStart = CFAbsoluteTimeGetCurrent()
            defer { stats.finishMax = max(stats.finishMax, CFAbsoluteTimeGetCurrent() - finishStart) }
            // One GPU copy into fresh slot buffers, ordered with RealityKit's rendering.
            guard let cb = queue.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder() else { return false }
            var t0 = CFAbsoluteTimeGetCurrent()
            let vb = mesh.replace(bufferIndex: 0, using: cb), ib = mesh.replaceIndices(using: cb)
            stats.replaceMax = max(stats.replaceMax, CFAbsoluteTimeGetCurrent() - t0)
            blit.copy(from: staging, sourceOffset: 0, to: vb, destinationOffset: 0, size: p.vertexBytes)
            blit.copy(from: staging, sourceOffset: p.vertexBytes, to: ib, destinationOffset: 0, size: p.indexBytes)
            blit.endEncoding()
            cb.commit()
            t0 = CFAbsoluteTimeGetCurrent()
            var offset = 0
            mesh.parts.replaceAll(p.parts.map { part in
                defer { offset += part.indexCount * 4 }
                return LowLevelMesh.Part(indexOffset: offset, indexCount: part.indexCount, topology: .triangle, materialIndex: 0, bounds: part.bounds)
            })
            stats.partsMax = max(stats.partsMax, CFAbsoluteTimeGetCurrent() - t0)
            j.copiedToGPU = true
            job = j
            if CFAbsoluteTimeGetCurrent() - finishStart > frameBudget { stats.finishesOver += 1 }
        }
        return false
    }
}
