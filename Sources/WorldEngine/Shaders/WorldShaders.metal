// WorldEngine surface shaders (RealityKit CustomMaterial).
//
// Every world vertex carries a "paint" in uv2: x = palette slot, y = shade multiplier,
// z = flags (1 glass, 2 emissive), w = sway weight.
//
// The material's custom texture (RGBA16F, 256 × 2) holds:
//   row 0: palette colors (sRGB), one per slot
//   row 1: globals
//     texel 0: fog color (linear RGB), fog density
//     texel 1: fog start (m), unused, cut-away radius (m), cut-away enabled (0/1)
//     texel 2: character position relative to the camera, world axes (xyz)
//     texel 3: wind strength, night factor, debug mode, unused
//     texel 4: camera world position rounded to whole meters (exact in half floats)
//     texel 5: camera world position remainder (−0.5…0.5 m)
//
// RealityKit has no scene fog, so fog is applied here: the lit color is scaled by (1 − f) and
// f × fog color is added as emission.

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

namespace {

struct Globals {
    half3 fogColor;
    float fogDensity;
    float fogStart;
    float cutRadius;
    bool cutEnabled;
    float3 characterView;
    float wind;
    float night;
    float debug;
    float3 camera;
};

Globals readGlobals(texture2d<half> tex) {
    half4 t0 = tex.read(uint2(0, 1));
    half4 t1 = tex.read(uint2(1, 1));
    half4 t2 = tex.read(uint2(2, 1));
    half4 t3 = tex.read(uint2(3, 1));
    Globals g;
    g.fogColor = t0.rgb;
    g.fogDensity = float(t0.a);
    g.fogStart = float(t1.r);
    g.cutRadius = float(t1.b);
    g.cutEnabled = t1.a > 0.5h;
    g.characterView = float3(t2.xyz);
    g.wind = float(t3.r);
    g.night = float(t3.g);
    g.debug = float(t3.b);
    g.camera = float3(tex.read(uint2(4, 1)).xyz) + float3(tex.read(uint2(5, 1)).xyz);
    return g;
}

half3 srgbToLinear(half3 c) {
    return select(pow((c + 0.055h) / 1.055h, half3(2.4h)), c / 12.92h, c <= 0.04045h);
}

float hash12(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/// 1 = keep, 0 = cut. Fragments near the line from the camera to the character (and in front
/// of the character) are dithered away so thin blockers never hide it. Works in world axes
/// relative to the camera, so it doesn't depend on the view-space convention.
half cutAway(realitykit::surface_parameters params, Globals g, float3 rel, float3 worldPos) {
    if (!g.cutEnabled) { return 1.0h; }
    float3 c = g.characterView;
    float len = length(c);
    if (len < 0.5) { return 1.0h; }
    float t = dot(rel, c) / (len * len);
    // Only between the camera and the character's front surface (~0.4 m before its center).
    float tEnd = 1.0 - 0.4 / len;
    if (t <= 0.0 || t >= tEnd) { return 1.0h; }
    // Never cut up-facing ground.
    float3 n = params.geometry().normal();
    if (n.y > 0.85 && worldPos.y < 0.3) { return 1.0h; }
    float d = length(rel - c * t);
    float keep = smoothstep(g.cutRadius * 0.55, g.cutRadius, d);
    float noise = hash12(floor(worldPos.xz * 22.0) + floor(worldPos.y * 22.0) * 17.0);
    return keep > noise ? 1.0h : 0.0h;
}

/// Smooth value noise for gentle color variation on large flat surfaces.
float valueNoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + float2(1, 0)), u.x), mix(hash12(i + float2(0, 1)), hash12(i + float2(1, 1)), u.x), u.y);
}

/// World position of the fragment. For instanced meshes, rebuilt from the model position and
/// the per-instance model-to-world matrix.
float3 fragmentWorldPosition(realitykit::surface_parameters params, bool instanced) {
    if (!instanced) { return params.geometry().world_position(); }
    return (params.uniforms().model_to_world() * float4(params.geometry().model_position(), 1.0)).xyz;
}

void finish(realitykit::surface_parameters params, Globals g, half3 base, half3 emissive,
            half roughness, half specular, bool allowCut, bool instanced = false) {
    float3 wp = fragmentWorldPosition(params, instanced);
    float3 rel = wp - g.camera;
    float dist = length(rel);
    half fog = half(1.0 - exp(-g.fogDensity * max(0.0, dist - g.fogStart)));
    auto s = params.surface();
    if (g.debug > 1.5 && g.debug < 2.5) {
        // Debug 2: the cut-away decision (red = cut, green = keep).
        half keep = allowCut ? cutAway(params, g, rel, wp) : 1.0h;
        s.set_base_color(half3(0.0h));
        s.set_emissive_color(keep > 0.5h ? half3(0.0h, 0.6h, 0.0h) : half3(1.0h, 0.0h, 0.0h));
        s.set_opacity(1.0h);
        return;
    }
    if (g.debug > 0.5 && g.debug < 1.5) {
        // Debug: red = position along camera→character (t), green = distance from that line / radius.
        float3 c = g.characterView;
        float t = dot(rel, c) / max(dot(c, c), 1e-4);
        float d = length(rel - c * t);
        s.set_base_color(half3(0.0h));
        s.set_emissive_color(half3(half(clamp(t, 0.0, 1.0)), half(clamp(d / max(g.cutRadius, 0.01), 0.0, 1.0)), half(dist / 50.0)));
        s.set_opacity(1.0h);
        return;
    }
    s.set_base_color(base * (1.0h - fog));
    s.set_emissive_color(emissive * (1.0h - fog) + g.fogColor * fog);
    s.set_roughness(roughness);
    s.set_specular(specular * (1.0h - fog));
    s.set_metallic(0.0h);
    s.set_opacity(allowCut ? cutAway(params, g, rel, wp) : 1.0h);
}

half3 paletteColor(texture2d<half> tex, float4 paint) {
    uint slot = uint(clamp(paint.x + 0.5, 0.0, 255.0));
    return srgbToLinear(tex.read(uint2(slot, 0)).rgb) * half(paint.y);
}

} // namespace

/// Buildings, ground, roads, curbs, lamps, benches.
[[visible]]
void worldStaticSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    half3 base = paletteColor(tex, paint);
    uint flags = uint(paint.z + 0.5);
    half roughness = 0.88h, specular = 0.3h;
    half3 emissive = half3(0.0h);
    // Break up large flat ground areas with soft, world-anchored variation.
    float3 n = params.geometry().normal();
    if (n.y > 0.9 && flags == 0u) {
        float3 wp = params.geometry().world_position();
        float v = valueNoise(wp.xz * 0.11) * 0.6 + valueNoise(wp.xz * 0.47) * 0.4;
        base *= half(0.9 + 0.2 * v);
    }
    if (flags & 1u) {            // window glass
        roughness = 0.14h;
        specular = 0.9h;
        base *= 0.8h;
    }
    if (flags & 2u) {            // lamp heads
        emissive = base * half(0.25 + 2.2 * g.night);
    }
    finish(params, g, base, emissive, roughness, specular, true);
}

/// Trees, bushes, grass: soft and matte with a little light passing through leaves.
[[visible]]
void worldFoliageSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    half3 base = paletteColor(tex, paint);
    // Per-instance tint from the instance's world origin (stable, no per-instance data needed).
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    half tint = half(0.9 + 0.2 * hash12(origin.xz * 0.37));
    base *= half3(tint, 1.0h, 2.0h - tint);
    finish(params, g, base, base * 0.07h, 0.95h, 0.12h, true, true);
}

/// Wind sway for foliage: moves vertices by their sway weight.
[[visible]]
void worldFoliageGeometry(realitykit::geometry_parameters params)
{
    float sway = params.geometry().uv2().w;
    if (sway <= 0.0) { return; }
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    float time = params.uniforms().time();
    float phase = origin.x * 0.31 + origin.z * 0.23;
    // Offset grows with height in the prop's own units, so it scales with the instance:
    // a 10 m tree sways ~20 cm at the top, a grass tuft a few millimeters.
    float h = params.geometry().model_position().y;
    float amp = 0.02 * sway * h;
    float3 offset = float3(sin(time * 1.3 + phase), 0.0, cos(time * 1.1 + phase * 1.7)) * amp;
    params.geometry().set_model_position_offset(offset);
}

/// Lakes and ponds: glossy, with slow color variation.
[[visible]]
void worldWaterSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    half3 base = paletteColor(tex, paint);
    float3 wp = params.geometry().world_position();
    float time = params.uniforms().time();
    float ripple = sin(wp.x * 0.35 + time * 0.6) * sin(wp.z * 0.29 - time * 0.45);
    base *= half(0.94 + 0.06 * ripple);
    finish(params, g, base, half3(0.0h), 0.07h, 0.7h, false);
}
