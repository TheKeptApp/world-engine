// WorldEngine surface shaders (RealityKit CustomMaterial).
//
// Vertex channels:
//   uv2 "paint": x = palette slot, y = shade multiplier, z = flags, w = sway weight
//   uv3 "extra": x = baked AO (1 open … 0 closed), y = stable seed, z = meters along a path,
//                w = meters across a path
// Flags: 1 glass, 2 emissive, 4 lawn, 8 sidewalk, 16 road, 32 variant of 4 slots, 64 variant of 2,
//        128 distance fade.
//
// The material's custom texture (RGBA16F, 256 × 4):
//   row 0: palette colors (sRGB), one per slot
//   row 1: globals (see RenderResources.update)
//   rows 2, 3: palette for trees running 7 days ahead / behind the season (per-tree offsets)
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
    float wetness; float snow; float wetDarkening; float wetRoughness;
    float2 windDir; float windStrength; float swayFrequency; float foliageSway;
    float3 leafFraction;             // now, trees ahead, trees behind
    half3 snowColor; float starStrength;
    half3 skyTop; float cloudCover; half3 skyHorizon;
    float3 sunDir; half3 sunDisk; half3 cloudColor;
    float3 moonDir; float moonRadius; float3 moonLight; float moonOpacity; half3 moonColor;
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
    g.wetness = float(t11.r); g.snow = float(t11.g); g.wetDarkening = float(t11.b); g.wetRoughness = float(t11.a);
    half4 t12 = tex.read(uint2(12, 1)), t13 = tex.read(uint2(13, 1)), t14 = tex.read(uint2(14, 1));
    g.windDir = float2(t12.xy); g.windStrength = float(t12.z); g.swayFrequency = float(t12.w);
    g.leafFraction = float3(t13.xyz); g.foliageSway = float(t13.w);
    g.snowColor = t14.rgb; g.starStrength = float(t14.a);
    half4 t15 = tex.read(uint2(15, 1)), t16 = tex.read(uint2(16, 1)), t17 = tex.read(uint2(17, 1)), t18 = tex.read(uint2(18, 1));
    half4 t19 = tex.read(uint2(19, 1)), t20 = tex.read(uint2(20, 1)), t21 = tex.read(uint2(21, 1)), t22 = tex.read(uint2(22, 1));
    g.skyTop = t15.rgb; g.cloudCover = float(t15.a); g.skyHorizon = t16.rgb;
    g.sunDir = float3(t17.xyz); g.sunDisk = t18.rgb; g.cloudColor = t19.rgb;
    g.moonDir = float3(t20.xyz); g.moonRadius = float(t20.w) / 100.0;
    g.moonLight = float3(t21.xyz); g.moonOpacity = float(t21.w); g.moonColor = t22.rgb;
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

uint paletteSlot(float4 paint, float3 instanceOrigin) {
    uint slot = uint(clamp(paint.x + 0.5, 0.0, 255.0));
    uint flags = uint(paint.z + 0.5);
    if (flags & 32u) { slot += uint(hash12(instanceOrigin.xz * 0.173) * 3.999); }
    if (flags & 64u) { slot += uint(hash12(instanceOrigin.xz * 0.211) * 1.999); }
    return slot;
}

half3 paletteColor(texture2d<half> tex, float4 paint, float3 instanceOrigin) {
    return srgbToLinear(tex.read(uint2(paletteSlot(paint, instanceOrigin), 0)).rgb) * half(paint.y);
}

/// Snow on exposed upward surfaces as stable patches (0.4–1.2 m detail over 2–5 m patches) whose
/// covered share follows the coverage (weather v1 §4, experience-v1 §1.3).
float snowMask(Globals g, float3 wp, float3 n) {
    if (g.snow <= 0.001) { return 0.0; }
    float up = smoothstep(0.55, 0.85, n.y);
    if (up <= 0.0) { return 0.0; }
    float m = 0.65 * valueNoise(wp.xz / 3.5 + 31.7) + 0.35 * valueNoise(wp.xz / 0.8);
    // Calibrated so the covered share of eligible area ≈ coverage (see RenderResources).
    float t = mix(0.18, 0.86, pow(clamp(g.snow, 0.0, 1.0), 0.85));
    return up * (1.0 - smoothstep(t - 0.035, t + 0.035, m));
}

struct Surface {
    half3 base; half3 emissive; half roughness; half specular; half ao; bool cuttable;
    /// Takes wetness and snow (not water).
    bool weathered = true;
    /// Wet roughness for this surface (roads 0.45, sidewalks 0.52, else the global value).
    half wetRoughness = -1.0h;
    /// Foliage removed by autumn (lobe threshold above the tree's leaf fraction).
    bool leafCut = false;
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
    if (su.weathered) {
        // Wet: darker (≤ 12%), smoother, a little more specular; walls half as much.
        float exposure = mix(0.5, 1.0, smoothstep(0.3, 0.8, n.y));
        half wet = half(g.wetness * exposure);
        su.base *= 1.0h - half(g.wetDarkening) * wet;
        half wr = su.wetRoughness >= 0.0h ? su.wetRoughness : half(g.wetRoughness);
        su.roughness = mix(su.roughness, min(su.roughness, wr), wet);
        su.specular = mix(su.specular, max(su.specular, 0.45h), wet);
        // Snow covers patterns, leaves and wetness where it lies.
        half snow = half(snowMask(g, wp, n));
        su.base = mix(su.base, g.snowColor, snow);
        su.roughness = mix(su.roughness, 0.85h, snow);
        su.specular = mix(su.specular, 0.25h, snow);
        su.ao = mix(su.ao, max(su.ao, 0.85h), snow);
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
    s.set_opacity(su.leafCut ? 0.0h : (su.cuttable ? cutAway(g, rel, wp, n) : 1.0h));
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
    if (flags & 16u) { su.wetRoughness = 0.45h; }
    if (flags & 8u) {
        su.wetRoughness = 0.52h;
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
    // Per-tree season timing (sky-seasons §5.3): each tree sits between the "7 days ahead" and
    // "7 days behind" palettes and leaf fractions by a stable per-tree value.
    float u = hash12(origin.xz * 0.37 + 3.1);
    uint slot = paletteSlot(paint, origin);
    half3 ahead = srgbToLinear(tex.read(uint2(slot, 2)).rgb), behind = srgbToLinear(tex.read(uint2(slot, 3)).rgb);
    su.base = mix(ahead, behind, half(u)) * half(paint.y) * half(0.95 + 0.10 * hash12(origin.xz * 0.37));
    su.emissive = su.base * 0.05h * half(extra.x);
    su.roughness = 0.95h; su.specular = 0.1h; su.ao = half(extra.x); su.cuttable = true;
    // Crown lobes carry a leaf threshold in extra.y (0 = trunk, branches, other foliage).
    float leaf = mix(g.leafFraction.y, g.leafFraction.z, u);
    su.leafCut = extra.y > 0.0 && extra.y > leaf + 1e-3;
    finish(params, g, su, wp);
}

/// R10 sway (weather v1 §6): leafy tips move at most 0.03 × min(U/12, 1) m along the wind, one
/// sine per tree at 0.10 + 0.08 × min(U/12, 1) Hz with a stable phase; bare branches 0.3×,
/// wet or cold foliage 0.7×; trunks fixed; fades out from 100 to 150 m.
[[visible]]
void worldFoliageGeometry(realitykit::geometry_parameters params)
{
    float sway = params.geometry().uv2().w;
    if (sway <= 0.0) { return; }
    Globals g = readGlobals(params.textures().custom());
    float4x4 m = params.uniforms().model_to_world();
    float3 origin = m[3].xyz;
    float scale = max(length(m[0].xyz), 1e-3);
    float fade = 1.0 - smoothstep(100.0, 150.0, length(origin - g.camera));
    if (fade <= 0.0) { return; }
    float time = params.uniforms().time();
    float phase = hash12(origin.xz * 0.31) * 6.2832;
    float y = clamp(params.geometry().model_position().y, 0.0, 1.0);
    float tip = 0.03 * g.windStrength * g.foliageSway * sway * pow(y, 1.5) * fade;   // metres
    float3 dir = float3(g.windDir.x, 0.0, g.windDir.y);
    float s = sin(time * 6.2832 * g.swayFrequency + phase);
    float3x3 rot = float3x3(m[0].xyz, m[1].xyz, m[2].xyz) / scale;
    float3 offset = transpose(rot) * (dir * tip * s) / scale;
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
    su.weathered = false;
    finish(params, g, su, wp);
}

namespace {

/// Cloud cover on the dome at a view direction (shared by the sky and the stars behind it).
float cloudAt(Globals g, float3 d, float time) {
    if (g.cloudCover <= 0.01 || d.y <= 0.0) { return 0.0; }
    float2 drift = g.windDir * time * 0.004;
    float2 q = d.xz / max(d.y + 0.18, 0.18) * 1.6 + drift;
    float n = valueNoise(q) * 0.65 + valueNoise(q * 2.3 + 7.1) * 0.35;
    float c = clamp(g.cloudCover, 0.0, 1.0);
    // Overcast closes to a full deck; partial cover keeps soft edges.
    float t = 1.0 - c;
    float cover = smoothstep(t - 0.12, t + 0.06, n) * smoothstep(0.0, 0.12, d.y);
    return max(cover, smoothstep(0.85, 1.0, c) * smoothstep(0.0, 0.08, d.y));
}

}

/// Sky dome (unlit, centred on the camera): gradient from the light state, horizon haze into the
/// fog colour, clouds by cover, the sun disk and glow, and the Moon as an analytic disk lit from
/// its real Sun direction (sky-seasons §3.2): no texture, terminator from the light vector.
[[visible]]
void worldSkySurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float3 wp = params.geometry().world_position();
    float3 d = normalize(wp - g.camera);
    float time = params.uniforms().time();
    float3 top = float3(g.skyTop), horizon = float3(g.skyHorizon), fog = float3(g.fogColor);
    float3 c = mix(horizon, top, pow(clamp(d.y / 0.85, 0.0, 1.0), 0.5));
    // Haze: the last few degrees meet the world's fog colour so distant geometry blends in.
    c = mix(c, fog, (1.0 - smoothstep(0.0, 0.10, d.y)) * 0.7);
    if (d.y < 0.0) { c = fog; }
    // Sun: 0.27° disk with a soft edge and glow, hidden by cloud.
    float cloud = cloudAt(g, d, time);
    float cosA = dot(d, normalize(g.sunDir));
    float disk = smoothstep(cos(0.30 * M_PI_F / 180.0), cos(0.24 * M_PI_F / 180.0), cosA);
    float glow = pow(max(0.0, cosA), 60.0) * 0.35 + pow(max(0.0, cosA), 8.0) * 0.08;
    c += float3(g.sunDisk) * (disk * 2.5 + glow) * (1.0 - cloud * 0.9);
    // Moon: analytic disk, normals facing the observer, lit by the Moon→Sun vector.
    if (g.moonOpacity > 0.001) {
        float3 md = normalize(g.moonDir);
        float r = g.moonRadius;
        float ang = acos(clamp(dot(d, md), -1.0, 1.0));
        if (ang < r * 1.2) {
            float3 right = normalize(cross(md, float3(0, 1, 0)));
            float3 up = cross(right, md);
            float2 xy = float2(dot(d - md, right), dot(d - md, up)) / r;
            float rr = dot(xy, xy);
            float edge = 1.0 - smoothstep(0.92, 1.0, sqrt(rr));
            float z = sqrt(max(0.0, 1.0 - rr));
            float3 n = xy.x * right + xy.y * up - z * md;
            float lit = smoothstep(-0.03, 0.12, dot(n, normalize(g.moonLight)));
            float a = edge * g.moonOpacity * (1.0 - cloud);
            c = mix(c, float3(g.moonColor), a * lit);
        }
    }
    // Clouds over the gradient (lit by the cloud colour; thin near the horizon).
    c = mix(c, float3(g.cloudColor), cloud);
    auto s = params.surface();
    s.set_base_color(half3(0.0h));
    s.set_emissive_color(half3(c));
    s.set_opacity(1.0h);
}

/// Star points (instanced quads, ≤ 128): soft round core; brightness from the instance size,
/// hidden behind cloud, below the horizon and by daylight (global strength).
[[visible]]
void worldStarSurface(realitykit::surface_parameters params)
{
    auto tex = params.textures().custom();
    Globals g = readGlobals(tex);
    float2 uv = params.geometry().uv0() * 2.0 - 1.0;
    float core = 1.0 - smoothstep(0.15, 1.0, length(uv));
    float3 origin = params.uniforms().model_to_world()[3].xyz;
    float3 d = normalize(origin - g.camera);
    float cloud = cloudAt(g, d, params.uniforms().time());
    float bright = clamp(length(params.uniforms().model_to_world()[0].xyz) / 12.0, 0.15, 1.0);
    float a = core * g.starStrength * bright * (1.0 - cloud) * smoothstep(0.0, 0.05, d.y);
    auto s = params.surface();
    s.set_base_color(half3(0.0h));
    s.set_emissive_color(half3(a * 1.6));
    s.set_opacity(half(a));
}
