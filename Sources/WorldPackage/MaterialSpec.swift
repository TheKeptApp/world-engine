import Foundation
import WorldGen
import WorldMesh

/// materials.json: what the package's vertex channels and material names mean, with every
/// constant the renderers need. Sources/WorldEngine/Shaders/WorldShaders.metal (RealityKit) and
/// web/src/materials.js (three.js) both implement exactly this; change all three together.
enum MaterialSpec {
    static var document: [String: Any] { [
        "schema": 1,
        "vertexChannels": [
            "_PAINT": ["x": "palette slot (integer-valued float)", "y": "shade multiplier on the slot color",
                       "z": "flags bitmask (integer-valued float)", "w": "sway weight 0–1 (foliage motion)"],
            "_EXTRA": ["x": "baked ambient occlusion 1 open … 0 closed (applies to fill light only)",
                       "y": "stable seed 0–1 (a window lights when seed < litFraction)",
                       "z": "meters along a path (sidewalk joints)", "w": "meters across a path"],
            "_FEATURE": "index into the chunk's scene.json features (65535 = none)",
        ],
        "flags": [
            "glass": Paint.Flags.glass.rawValue, "emissive": Paint.Flags.emissive.rawValue, "lawn": Paint.Flags.lawn.rawValue,
            "sidewalk": Paint.Flags.sidewalk.rawValue, "road": Paint.Flags.road.rawValue, "variant4": Paint.Flags.variant4.rawValue,
            "variant2": Paint.Flags.variant2.rawValue, "distanceFade": Paint.Flags.distanceFade.rawValue,
        ],
        "functions": [
            "srgbToLinear": "IEC 61966-2-1 piecewise curve",
            "hash12(p)": "p3 = fract(vec3(p.xyx) × 0.1031); p3 += dot(p3, p3.yzx + 33.33); fract((p3.x + p3.y) × p3.z)",
            "valueNoise(p)": "bilinear value noise of hash12 at integer lattice points with smoothstep weights f²(3 − 2f)",
        ],
        "palette": [
            "lookup": "color = srgbToLinear(palette[slot]) × shade",
            "variant4": "slot += floor(hash12(instanceOrigin.xz × 0.173) × 3.999)",
            "variant2": "slot += floor(hash12(instanceOrigin.xz × 0.211) × 1.999)",
        ],
        "materials": [
            "worldStatic": ["roughness": 0.88, "specular": 0.3, "cutAway": false,
                            "lawn": ["broad": "valueNoise(worldPos.xz / 2.6) − 0.5", "fine": "(valueNoise(worldPos.xz / 0.45 + 17) − 0.5) × (1 − smoothstep(30, 50, distance))",
                                     "value": "base × (1 + broad × 0.10 + fine × 0.06)", "saturation": "mix(luma, base, 1 + broad × 0.08)",
                                     "roughness": 0.95, "specular": 0.15],
                            "sidewalk": ["slabMeters": 1.75, "jointHalfWidthMeters": 0.006, "darkening": 0.14, "fade": [35, 60],
                                         "antialias": "line = 1 − smoothstep(hw, hw + 1.5·fwidth(u), |fract(u + 0.5) − 0.5|) with u = along / 1.75, hw = 0.006 / 1.75; × clamp(4·hw / fwidth(u), 0, 1)"],
                            "glass": ["roughness": 0.35, "specular": 0.55, "lit": "seed < litFraction: emissive = srgbToLinear(litWindow) × 1.4, base × 0.4"],
                            "emissive": "emissive = base × (0.25 + 2 × litFraction)"],
            "worldProp": ["roughness": 0.75, "specular": 0.35, "cutAway": true, "emissive": "flag emissive: base × (0.25 + 2 × litFraction)"],
            "worldFoliage": ["roughness": 0.95, "specular": 0.1, "cutAway": true,
                             "instanceValue": "base × (0.95 + 0.10 × hash12(instanceOrigin.xz × 0.37))",
                             "translucency": "emissive = base × 0.05 × ao",
                             "sway": "offset = (sin(t·0.9 + φ), 0, cos(t·0.7 + 1.7φ)) × 0.0025 × sway × modelY (model space), φ = origin.x·0.31 + origin.z·0.23"],
            "worldWater": ["roughness": 0.45, "specular": 0.6, "ripple": "base × (0.95 + 0.08 × valueNoise(worldPos.xz × 0.05 + (t·0.02, t·0.013)))"],
        ],
        "lighting": [
            "sun": "directional, color = light.sunColor normalized, strength = sunIntensity × exposure × renderer calibration; casts shadows within 80 m",
            "fill": "emissive += base × mix(fillGround, fillSky, n.y·0.5 + 0.5) × max(0.65, ao) × contact; fillSky = linear(ambientSky) × fill.sky × fillScale × exposure (same for ground)",
            "fillScale": 2.4,
            "ibl": "sky image as environment light for speculars only (weak)",
            "fog": "f = smoothstep(fogStart, fogEnd, distance to camera) × 0.96; base × (1 − f); emissive = (fill + emissive) × (1 − f) + fogColor × f",
            "contactShadow": ["opacity": 0.18, "softnessMeters": 0.12, "halfExtents": "character visual bounds × 0.575 (x, z)",
                              "mask": "ellipse in the character's heading frame; 1 − opacity × (1 − smoothstep(1 − e, 1 + e, r)), e = softness / min(half extents); upward faces within 0.25 m of its ground point"],
            "cutAway": ["radius": 1.1, "rule": "fragments of cut-away materials near the camera→character segment (t in (0, 1 − 0.4/len)) are dithered out: keep if smoothstep(0.55·r, r, distance to segment) > hash12(floor(worldPos.xz × 22) + floor(worldPos.y × 22) × 17); upward faces below 0.3 m are kept"],
            "rendererCalibration": ["realitykit": ["sunLux": 14000, "iblIntensityExponent": "−1.2 + log2(exposure)"],
                                    "threejs": "web/src/lighting.js (tuned to match RealityKit captures)"],
        ],
        "post": ["grade": ["contrast": 1.03, "saturation": 0.99], "bloom": ["threshold": 0.9, "strength": 0.04, "resolution": "half"]],
        "character": ["coat": "COLOR_0 (coat × AO); emissive += coat × mix(0.35·fillSky, fillSky, n.y·0.5 + 0.5) + rim × (0.60, 0.56, 0.50)",
                      "rim": "rimStrength × (1 − |n·v|)³, rimStrength 0.35", "framing": "projected bounds fill 22% of the view height"],
    ] }
}
