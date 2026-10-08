import SwiftUI
import UIKit

/// Separate touch counts keep pinch/two-finger pan from also firing the orbit recognizer.
struct InspectionGestures: UIViewRepresentable {
    var orbit: (SIMD2<Double>) -> Void
    var pan: (SIMD2<Double>, Double) -> Void
    var zoom: (Double) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UIView {
        let view = UIView(); view.backgroundColor = .clear
        let orbit = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.orbit(_:)))
        orbit.minimumNumberOfTouches = 1; orbit.maximumNumberOfTouches = 1
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        pan.minimumNumberOfTouches = 2; pan.maximumNumberOfTouches = 2
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.zoom(_:)))
        for gesture in [orbit, pan, pinch] { gesture.delegate = context.coordinator; view.addGestureRecognizer(gesture) }
        return view
    }
    func updateUIView(_ view: UIView, context: Context) { context.coordinator.parent = self }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: InspectionGestures
        init(_ parent: InspectionGestures) { self.parent = parent }
        func gestureRecognizer(_ a: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith b: UIGestureRecognizer) -> Bool {
            // Permit the two-finger translation and scale together, never the one-finger orbit.
            let twoFingerPan = (a as? UIPanGestureRecognizer)?.minimumNumberOfTouches == 2 || (b as? UIPanGestureRecognizer)?.minimumNumberOfTouches == 2
            return twoFingerPan && (a is UIPinchGestureRecognizer || b is UIPinchGestureRecognizer)
        }
        @objc func orbit(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.numberOfTouches == 1 else { recognizer.setTranslation(.zero, in: recognizer.view); return }
            let d = recognizer.translation(in: recognizer.view)
            parent.orbit(SIMD2(Double(d.x), Double(d.y)))
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
        @objc func pan(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.numberOfTouches == 2 else { recognizer.setTranslation(.zero, in: recognizer.view); return }
            let d = recognizer.translation(in: recognizer.view)
            parent.pan(SIMD2(Double(d.x), Double(d.y)), Double(recognizer.view?.bounds.height ?? 1))
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
        @objc func zoom(_ recognizer: UIPinchGestureRecognizer) {
            parent.zoom(Double(recognizer.scale)); recognizer.scale = 1
        }
    }
}
