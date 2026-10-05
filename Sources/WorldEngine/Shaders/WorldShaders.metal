// WorldEngine surface shaders (RealityKit CustomMaterial).
//
// Vertex channels:
//   uv2 "paint": x = palette slot, y = shade multiplier, z = flags, w = sway weight
//   uv3 "extra": x = baked AO (1 open … 0 closed), y = stable seed, z = meters along a path,
//                w = meters across a path
// Flags: 1 glass, 2 emissive, 4 lawn, 8 sidewalk, 16 road, 32 variant of 4 slots, 64 variant of 2,
//        128 distance fade.
//
// The material's custom texture (RGBA16F, 256 × 2):
//   row 0: palette colors (sRGB), one per slot
//   row 1: globals (see RenderResources.update)
//
// Lighting model shared with the web renderer (web/src/materials.js):
//   lit      = RealityKit PBR with the sun (shadowed) + a weak IBL for speculars
//   fill     = base × max(0.65, AO) × mix(ground fill, sky fill, n.y·0.5+0.5)   (R8, emissive)
//   contact  = soft ellipse under the character darkens ground (R8)
//   fog      = lit × (1 − f) + fogColor × f, f from start/end distance

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

namespace {

struct Globals {
    half3 fogColor; float fogStart; float fogEnd;
    float cutRadius; bool cutEnabled; float debug;
    float3 characterRel;            // character center relative to camera
    float wind; float litFraction;
    float3 camera;
    half3 fillSky; half3 fillGround;
    half3 litWindow;
    float3 contactRel;              // character ground point relative to camera
    float2 contactHalf; float contactHeading; float contactOpacity; float contactSoftness;
    float wetness; float snow;
};

Globals readGlobals(texture2d<half> tex) {
    Globals g;
    half4 t0 = tex.read(uint2(0, 1)), t1 = tex.read(uint2(1, 1)), t2 = tex.read(uint2(2, 1)), t3 = tex.read(uint2(3, 1));
    half4 t6 = tex.read(uint2(6, 1)), t7 = tex.read(uint2(7, 1)), t8 = tex.read(uint2(8, 1)), t9 = tex.read(uint2(9, 1));
    half4 t10 = tex.read(uint2(10, 1)), t11 = tex.read(uint2(11, 1));
    g.fogColor = t0.rgb; g.fogStart = float(t0.a);
    g.fogEnd = float(t1.r); g.cutRadius = float(t1.g); g.cutEnabled = t1.b > 0.5h; g.debug = float(t1.a);
    g.characterRel = float3(t2.xyz);
    g.wind = float(t3.r); g.litFraction = float(t3.g);
    g.camera = float3(tex.read(uint2(4, 1)).xyz) + float3(tex.read(uint2(5, 1)).xyz);
    g.fillSky = t6.rgb; g.fillGround = t7.rgb;
    g.litWindow = t8.rgb;
    g.contactHalf = float2(t9.xy); g.contactHeading = float(t9.z); g.contactSoftness = float(t9.w);
    g.contactRel = float3(t10.xyz); g.contactOpacity = float(t10.w);
    g.wetness = float(t11.r); g.snow = float(t11.g);
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

float valueNoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + float2(1, 0)), u.x), mix(hash12(i + float2(0, 1)), hash12(i + float2(1, 1)), u.x), u.y);
}

/// 1 = keep, 0 = cut. Fragments near the camera→character line (in front of it) are dithered away.
half cutAway(Globals g, float3 rel, float3 worldPos, float3 n) {
    if (!g.cutEnabled) { return 1.0h; }
    float3 c = g.characterRel;
    float len = length(c);
    if (len < 0.5) { return 1.0h; }
    float t = dot(rel, c) / (len * len);
    float tEnd = 1.0 - 0.4 / len;
    if (t <= 0.0 || t >= tEnd) { return 1.0h; }
    if (n.y > 0.85 && worldPos.y < 0.3) { return 1.0h; }
    float d = length(rel - c * t);
    float keep = smoothstep(g.cutRadius * 0.55, g.cutRadius, d);
    float noise = hash12(floor(worldPos.xz * 22.0) + floor(worldPos.y * 22.0) * 17.0);
    return keep > noise ? 1.0h : 0.0h;
}

/// R8 contact: soft ellipse under the character, oriented to its heading.
half contactShadow(Globals g, float3 rel, float3 n) {
    if (g.contactOpacity <= 0.0 || n.y < 0.85) { return 1.0h; }
    float3 d = rel - g.contactRel;
    if (abs(d.y) > 0.25) { return 1.0h; }
    float s = sin(g.contactHeading), c = cos(g.contactHeading);
    float2 local = float2(d.x * c - d.z * s, d.x * s + d.z * c);
    float2 q = local / max(g.contactHalf, float2(0.05));
    float r = length(q);
    float edge = g.contactSoftness / max(min(g.contactHalf.x, g.contactHalf.y), 0.05);
    float mask = 1.0 - smoothstep(1.0 - edge, 1.0 + edge, r);
    return half(1.0 - g.contactOpacity * mask);
}

half3 paletteColor(texture2d<half> tex, float4 paint, float3 instanceOrigin) {
    uint slot = uint(clamp(paint.x + 0.5, 0.0, 255.0));
    uint flags = uint(paint.z + 0.5);
    if (flags & 32u) { slot += uint(hash12(instanceOrigin.xz * 0.173) * 3.999); }
    if (flags & 64u) { slot += uint(hash12(instanceOrigin.xz * 0.211) * 1.999); }
    return srgbToLinear(tex.read(uint2(slot, 0)).rgb) * half(paint.y);
}

struct Surface {
    half3 base; half3 emissive; half roughness; half specular; half ao; bool cuttable;
};

void finish(realitykit::surface_parameters params, Globals g, Surface su, float3 wp) {
    float3 rel = wp - g.camera;
    float dist = length(rel);
    float3 n = normalize(params.geometry().normal());
    auto s = params.surface();
    if (g.debug > 1.5 && g.debug < 2.5) {
        half keep = su.cuttable ? cutAway(g, rel, wp, n) : 1.0h;
        s.set_base_color(half3(0.0h));
        s.set_emissive_color(keep > 0.5h ? half3(0.0h, 0.6h, 0.0h) : half3(1.0h, 0.0h, 0.0h));
        s.set_opacity(1.0h);
        return;
    }
    if (g.debug > 2.5 && g.debug < 3.5) { // AO view
        s.set_base_color(half3(0.0h)); s.set_emissive_color(half3(su.ao)); s.set_opacity(1.0h); return;
    }
    half contact = contactShadow(g, rel, n);
    // R8 fill: hemispheric sky/ground, occluded by baked AO (floor 0.65). Emissive, so no extra
    // shadow-casting light.
    half hemi = half(n.y * 0.5 + 0.5);
    half3 fill = su.base * mix(g.fillGround, g.fillSky, hemi) * max(0.65h, su.ao) * contact;
    half fog = half(smoothstep(g.fogStart, g.fogEnd, dist) * 0.96);
    s.set_base_color(su.base * contact * (1.0h - fog));
    s.set_emissive_color((fill + su.emissive) * (1.0h - fog) + g.fogColor * fog);
    s.set_roughness(su.roughness);
    s.set_specular(su.specular * (1.0h - fog));
    s.set_metallic(0.0h);
    s.set_ambient_occlusion(su.ao);
    s.set_opacity(su.cuttable ? cutAway(g, rel, wp, n) : 1.0h);
}

} // namespace

/// Buildings, ground, roads, curbs, sidewalks (opaque).
[[visible]]
void worldStaticSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    float4 extra = params.geometry().uv3();
    float3 wp = params.geometry().world_position();
    uint flags = uint(paint.z + 0.5);
    Surface su;
    su.base = paletteColor(tex, paint, float3(0));
    su.emissive = half3(0.0h); su.roughness = 0.88h; su.specular = 0.3h; su.ao = half(extra.x); su.cuttable = false;
    float dist = length(wp - g.camera);

    if (flags & 4u) {
        // R3 lawn mottling: two low-frequency bands; fine band fades out by 50 m.
        float broad = valueNoise(wp.xz / 2.6) - 0.5;
        float fine = (valueNoise(wp.xz / 0.45 + 17.0) - 0.5) * (1.0 - smoothstep(30.0, 50.0, dist));
        float v = broad * 0.10 + fine * 0.06;
        su.base *= half(1.0 + v);
        half luma = dot(su.base, half3(0.2126h, 0.7152h, 0.0722h));
        su.base = mix(half3(luma), su.base, half(1.0 + broad * 0.08));
        su.roughness = 0.95h; su.specular = 0.15h;
    }
    if (flags & 8u) {
        // R7 sidewalk joints: transverse joints every 1.75 m along the path, ~1.2 cm wide,
        // darkening 14%; anti-aliased; gone by 60 m.
        float u = extra.z / 1.75;
        float w = max(fwidth(u), 1e-4);
        float distToJoint = abs(fract(u + 0.5) - 0.5);           // in slab units
        float halfWidth = 0.006 / 1.75;
        float line = 1.0 - smoothstep(halfWidth, halfWidth + w * 1.5, distToJoint);
        line *= (1.0 - smoothstep(35.0, 60.0, dist)) * clamp(halfWidth * 4.0 / w, 0.0, 1.0);
        su.base *= half(1.0 - 0.14 * line);
    }
    if (flags & 1u) {
        // Windows: opaque day color; a stable per-household subset lights at dusk and night.
        su.roughness = 0.35h; su.specular = 0.55h;
        if (extra.y < g.litFraction) { su.emissive = srgbToLinear(g.litWindow) * 1.4h; su.base *= 0.4h; }
    }
    if (flags & 2u) {
        su.emissive = su.base * half(0.25 + 2.0 * g.litFraction);
    }
    finish(params, g, su, wp);
}

/// Lamps and benches: same look, but cut-away capable (transparent pipeline, depth writes).
[[visible]]
void worldPropSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    float4 extra = params.geometry().uv3();
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    float3 wp = (params.uniforms().model_to_world() * float4(params.geometry().model_position(), 1.0)).xyz;
    uint flags = uint(paint.z + 0.5);
    Surface su;
    su.base = paletteColor(tex, paint, origin);
    su.emissive = (flags & 2u) ? su.base * half(0.25 + 2.0 * g.litFraction) : half3(0.0h);
    su.roughness = 0.75h; su.specular = 0.35h; su.ao = half(extra.x); su.cuttable = true;
    finish(params, g, su, wp);
}

/// Trees, bushes, tufts: soft and matte, a little light through leaves; ±5% value per instance.
[[visible]]
void worldFoliageSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    float4 extra = params.geometry().uv3();
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    float3 wp = (params.uniforms().model_to_world() * float4(params.geometry().model_position(), 1.0)).xyz;
    Surface su;
    su.base = paletteColor(tex, paint, origin) * half(0.95 + 0.10 * hash12(origin.xz * 0.37));
    su.emissive = su.base * 0.05h * half(extra.x);
    su.roughness = 0.95h; su.specular = 0.1h; su.ao = half(extra.x); su.cuttable = true;
    finish(params, g, su, wp);
}

/// R10 sway: very slow, low-amplitude motion of crowns; trunks nearly fixed.
[[visible]]
void worldFoliageGeometry(realitykit::geometry_parameters params)
{
    float sway = params.geometry().uv2().w;
    if (sway <= 0.0) { return; }
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    float time = params.uniforms().time();
    float phase = origin.x * 0.31 + origin.z * 0.23;
    float h = params.geometry().model_position().y;
    float amp = 0.0025 * sway * h;   // a few cm at the top of a 10 m tree
    float3 offset = float3(sin(time * 0.9 + phase), 0.0, cos(time * 0.7 + phase * 1.7)) * amp;
    params.geometry().set_model_position_offset(offset);
}

/// Lakes and ponds: broad highlights, roughness ~0.45 (v2 §3.4), slow color variation.
[[visible]]
void worldWaterSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float4 paint = params.geometry().uv2();
    float3 wp = params.geometry().world_position();
    float time = params.uniforms().time();
    Surface su;
    su.base = paletteColor(tex, paint, float3(0));
    float ripple = valueNoise(wp.xz * 0.05 + float2(time * 0.02, time * 0.013));
    su.base *= half(0.95 + 0.08 * ripple);
    su.emissive = half3(0.0h); su.roughness = 0.45h; su.specular = 0.6h; su.ao = 1.0h; su.cuttable = false;
    finish(params, g, su, wp);
}
