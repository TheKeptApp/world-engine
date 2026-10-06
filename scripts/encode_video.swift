// Re-encodes a screen recording to H.264 at half size and a fixed bitrate (gate videos for the repo).
//   swift scripts/encode_video.swift in.mp4 out.mp4 [kbps]      (default 1600 kbps ≈ 12 MB a minute)
import AVFoundation

let args = CommandLine.arguments
let src = URL(fileURLWithPath: args[1]), dst = URL(fileURLWithPath: args[2])
let kbps = args.count > 3 ? Int(args[3]) ?? 1600 : 1600
try? FileManager.default.removeItem(at: dst)

let asset = AVURLAsset(url: src)
let done = DispatchSemaphore(value: 0)
Task {
    do {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { fatalError("no video track") }
        let size = try await track.load(.naturalSize)
        let w = Int(size.width / 2) & ~1, h = Int(size.height / 2) & ~1
        let reader = try AVAssetReader(asset: asset)
        let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        reader.add(out)
        let writer = try AVAssetWriter(outputURL: dst, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: kbps * 1000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
        ])
        input.expectsMediaDataInRealTime = false
        writer.add(input)
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        let queue = DispatchQueue(label: "encode")
        input.requestMediaDataWhenReady(on: queue) { [reader] in
            _ = reader   // keep the reader alive while the writer pulls samples
            while input.isReadyForMoreMediaData {
                guard let sample = out.copyNextSampleBuffer() else {
                    input.markAsFinished()
                    writer.finishWriting {
                        print(writer.status == .completed ? "ok \(dst.lastPathComponent) \(w)x\(h) \(kbps) kbps" : "failed \(String(describing: writer.error))")
                        done.signal()
                    }
                    return
                }
                input.append(sample)
            }
        }
    } catch {
        print("failed \(error)")
        done.signal()
    }
}
done.wait()
