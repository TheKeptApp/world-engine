import Metal
import RealityKit
import SwiftUI

// Minimal reproduction for: assigning RealityViewCameraContent.renderingEffects.customPostProcessing
// traps (EXC_BREAKPOINT in ARView.renderCallbacks.setter) on iOS 26.4.
// Launch argument `-variant` picks the variant:
//   make      set the effect inside RealityView's make closure        (traps)
//   update    set it in the update closure                            (?)
//   virtual   set content.camera = .virtual first, then the effect     (?)
//   none      no post-processing (control)
//   arview    ARView(cameraMode: .nonAR) + renderCallbacks.postProcess (workaround candidate)
//   arview-late  same, but assigned 2 s after the view is on screen
//   late      RealityView, effect assigned in `update` 2 s after the view is on screen

/// Counts post-process calls and writes Documents/status.txt so a device run can be checked remotely.
final class Status: @unchecked Sendable {
    static let shared = Status()
    private let lock = NSLock()
    private var calls = 0
    func hit() { lock.lock(); calls += 1; lock.unlock() }
    func write() {
        lock.lock(); let n = calls; lock.unlock()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("status.txt")
        try? "variant=\(variant) postProcessCalls=\(n)\n".write(to: url, atomically: true, encoding: .utf8)
    }
}

/// Inverts colors with a tiny compute kernel compiled at runtime.
final class Inverter: @unchecked Sendable {
    let pipeline: MTLComputePipelineState
    init(device: MTLDevice) {
        let src = """
        #include <metal_stdlib>
        using namespace metal;
        kernel void invert(texture2d<half, access::read> src [[texture(0)]],
                           texture2d<half, access::write> dst [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
            if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
            half4 c = src.read(gid);
            dst.write(half4(1.0h - c.rgb, c.a), gid);
        }
        """
        let lib = try! device.makeLibrary(source: src, options: nil)
        pipeline = try! device.makeComputePipelineState(function: lib.makeFunction(name: "invert")!)
    }
    func encode(_ cb: MTLCommandBuffer, src: MTLTexture, dst: MTLTexture) {
        guard let enc = cb.makeComputeCommandEncoder() else { return }
        enc.setComputePipelineState(pipeline)
        enc.setTexture(src, index: 0)
        enc.setTexture(dst, index: 1)
        let w = pipeline.threadExecutionWidth, h = pipeline.maxTotalThreadsPerThreadgroup / w
        enc.dispatchThreads(MTLSize(width: dst.width, height: dst.height, depth: 1),
                            threadsPerThreadgroup: MTLSize(width: w, height: h, depth: 1))
        enc.endEncoding()
    }
}

struct InvertEffect: PostProcessEffect {
    var inverter: Inverter?
    mutating func prepare(for device: MTLDevice) { inverter = Inverter(device: device) }
    mutating func postProcess(context: borrowing PostProcessEffectContext<any MTLCommandBuffer>) {
        inverter?.encode(context.commandBuffer, src: context.sourceColorTexture, dst: context.targetColorTexture)
        Status.shared.hit()
    }
}

@MainActor func makeCube() -> ModelEntity {
    let cube = ModelEntity(mesh: .generateBox(size: 0.4), materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)])
    cube.orientation = simd_quatf(angle: 0.6, axis: simd_normalize([1, 1, 0]))
    return cube
}

let variant: String = {
    let a = ProcessInfo.processInfo.arguments
    if let i = a.firstIndex(of: "-variant"), i + 1 < a.count { return a[i + 1] }
    return "make"
}()

@main
struct ReproApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                if variant.hasPrefix("arview") { ARViewContainer() } else { RealityViewVariant() }
                Text("variant: \(variant)").padding(8).background(.white)
            }
            .task {
                Status.shared.write()
                for _ in 0..<10 { try? await Task.sleep(for: .seconds(1)); Status.shared.write() }
            }
        }
    }
}

struct RealityViewVariant: View {
    @State private var armed = false
    var body: some View {
        RealityView { content in
            let cam = PerspectiveCamera()
            cam.position = [0, 0, 1.5]
            content.add(cam)
            content.add(makeCube())
            content.add({ let l = DirectionalLight(); l.look(at: .zero, from: [1, 2, 2], relativeTo: nil); return l }())
            if variant == "virtual" { content.camera = .virtual }
            if variant == "make" || variant == "virtual" {
                content.renderingEffects.customPostProcessing = .effect(InvertEffect())
            }
        } update: { content in
            if variant == "update" || (variant == "late" && armed) {
                content.renderingEffects.customPostProcessing = .effect(InvertEffect())
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            armed = true
        }
    }
}

/// Workaround candidate: ARView in non-AR mode with the classic render callback.
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(makeCube())
        let cam = PerspectiveCamera()
        cam.position = [0, 0, 1.5]
        anchor.addChild(cam)
        view.scene.addAnchor(anchor)
        let install = {
            var inverter: Inverter?
            var callbacks = ARView.RenderCallbacks()
            callbacks.prepareWithDevice = { device in inverter = Inverter(device: device) }
            callbacks.postProcess = { ctx in
                inverter?.encode(ctx.commandBuffer, src: ctx.sourceColorTexture, dst: ctx.targetColorTexture)
                Status.shared.hit()
            }
            view.renderCallbacks = callbacks
        }
        if variant == "arview-late" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { install() }
        } else {
            install()
        }
        return view
    }
    func updateUIView(_ view: ARView, context: Context) {}
}
