import Foundation
import simd

/// How a postcard pose is framed for each picture (docs/postcards.md, "Reframing").
///
/// Postcard poses are composed and scored in the spec's 16:9 frame (`PostcardComposer`, 50°
/// vertical FOV). Each export picture has its own aspect ratio (wider than square for the square
/// postcard, about square for portrait, taller than wide for story), and each is rendered on its
/// own; none is a crop of another (experience-v1: "retain pose and use a separately selected field
/// of view").
///
/// The rule: **same eye, same look-at point, same diagonal field of view.** Every picture sees
/// through the lens of the composed frame: a narrower picture trades some width for height
/// instead of cutting the sides off, so regional landmarks at the edges of the composition stay in
/// the frame. The look-at point keeps the horizon where the composer put it. The narrowest postcard
/// picture (classic story, about 0.8 wide per 1 high) keeps about three quarters of the composed
/// horizontal field, the square postcard over 95%; the vertical field never exceeds 75°, so nothing
/// stretches at the corners.
public enum PostcardReframe {
    /// The frame postcard poses are composed in (16:9).
    public static let composedAspect = PostcardComposer.Settings().aspect
    /// Upper bound for the vertical field of view.
    public static let maxVerticalFOVDegrees = 75.0

    /// The vertical FOV for a picture of `aspect` (width / height) that keeps the diagonal field of
    /// view of a frame of `composedAspect` with `composedVerticalFOV`.
    public static func verticalFOV(forAspect aspect: Double, composedVerticalFOV: Double, composedAspect: Double = PostcardReframe.composedAspect,
                                   maxVerticalFOV: Double = PostcardReframe.maxVerticalFOVDegrees) -> Double {
        guard aspect > 0, composedAspect > 0, composedVerticalFOV > 0 else { return composedVerticalFOV }
        let half = tan(composedVerticalFOV / 2 * .pi / 180)
        let diagonal = half * (1 + composedAspect * composedAspect).squareRoot()
        let fov = 2 * atan(diagonal / (1 + aspect * aspect).squareRoot()) * 180 / .pi
        return min(maxVerticalFOV, fov)
    }

    /// Horizontal FOV of a picture with this vertical FOV and aspect.
    public static func horizontalFOV(verticalFOV: Double, aspect: Double) -> Double {
        2 * atan(tan(verticalFOV / 2 * .pi / 180) * aspect) * 180 / .pi
    }

    /// Diagonal FOV of a picture with this vertical FOV and aspect.
    public static func diagonalFOV(verticalFOV: Double, aspect: Double) -> Double {
        2 * atan(tan(verticalFOV / 2 * .pi / 180) * (1 + aspect * aspect).squareRoot()) * 180 / .pi
    }
}

extension CameraPose {
    /// This pose framed for a picture of `aspect` (width / height): eye and look-at point kept,
    /// vertical FOV from `PostcardReframe.verticalFOV`.
    public func reframed(forAspect aspect: Double, composedAspect: Double = PostcardReframe.composedAspect) -> CameraPose {
        CameraPose(eye: eye, target: target,
                   verticalFOVDegrees: PostcardReframe.verticalFOV(forAspect: aspect, composedVerticalFOV: verticalFOVDegrees,
                                                                   composedAspect: composedAspect))
    }
}
