import QuartzCore
import RealityKit
import UIKit

/// `-viewdiag`: prints the rendering views under the key window (class, scale, Metal drawable
/// size) so the actual render resolution of each renderer is measured, not assumed.
@MainActor
enum ViewDiagnostics {
    static func dump(tag: String) {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first else {
            print("VIEWDIAG \(tag): no key window"); return
        }
        func visit(_ v: UIView, depth: Int) {
            let layer = v.layer
            var line = "\(String(describing: type(of: v))) bounds=\(Int(v.bounds.width))x\(Int(v.bounds.height)) scale=\(v.contentScaleFactor)"
            if let m = layer as? CAMetalLayer {
                line += " CAMetalLayer drawable=\(Int(m.drawableSize.width))x\(Int(m.drawableSize.height)) contentsScale=\(m.contentsScale)"
            }
            for sub in layer.sublayers ?? [] where sub is CAMetalLayer {
                let m = sub as! CAMetalLayer
                line += " subMetal drawable=\(Int(m.drawableSize.width))x\(Int(m.drawableSize.height))"
            }
            if v is ARView { line += " [ARView]" }
            if line.contains("Metal") || v is ARView || depth < 3 { print("VIEWDIAG \(tag) " + String(repeating: "  ", count: depth) + line) }
            for s in v.subviews { visit(s, depth: depth + 1) }
        }
        visit(window, depth: 0)
    }
}
