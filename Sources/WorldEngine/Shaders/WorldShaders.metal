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
    half3 skyTop; float cloudCover; half3 skyHorizon; float cloudThreshold;
    float3 sunDir; half3 sunDisk; half3 cloudColor;
    float3 moonDir; float moonRadius; float3 moonLight; float moonOpacity; half3 moonColor;
    half3 litterA; half3 litterB; float leafLitter; float2 canopyOrigin; float2 canopySize;
    half3 airColor; float airCap; float airStart; float airD50; float fogWeight; float fogFloor;
    // Rain pack wet ground (texels 30–33, 35): per surface (darken, roughness, sheen, extra):
    // wetA concrete + puddle cover, wetB asphalt + puddle roughness, wetC brick + puddle sky mix
    // looking down, wetD lawn + puddle sky mix at grazing, wetE roof + raining (lake ripples).
    float4 wetA; float4 wetB; float4 wetC; float4 wetD; float4 water; float4 wetE; float4 waterB;
    float postcardAO; bool postcardQuality;   // postcard quality mode only (texel 29; zero on screen)
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
    g.skyTop = t15.rgb; g.cloudCover = float(t15.a); g.skyHorizon = t16.rgb; g.cloudThreshold = float(t16.a);
    g.sunDir = float3(t17.xyz); g.sunDisk = t18.rgb; g.cloudColor = t19.rgb;
    g.moonDir = float3(t20.xyz); g.moonRadius = float(t20.w) / 100.0;
    g.moonLight = float3(t21.xyz); g.moonOpacity = float(t21.w); g.moonColor = t22.rgb;
    half4 t23 = tex.read(uint2(23, 1)), t24 = tex.read(uint2(24, 1)), t25 = tex.read(uint2(25, 1)), t26 = tex.read(uint2(26, 1));
    g.litterA = t23.rgb; g.leafLitter = float(t23.a); g.litterB = t24.rgb;
    g.canopyOrigin = float2(t25.xy) + float2(t25.zw);
    g.canopySize = max(float2(t26.xy) + float2(t26.zw), float2(1.0));
    half4 t27 = tex.read(uint2(27, 1)), t28 = tex.read(uint2(28, 1));
    g.airColor = t27.rgb; g.airCap = float(t27.a);
    g.airStart = float(t28.r); g.airD50 = max(float(t28.g), float(t28.r) + 1.0); g.fogWeight = float(t28.b); g.fogFloor = float(t28.a);
    g.wetA = float4(tex.read(uint2(30, 1))); g.wetB = float4(tex.read(uint2(31, 1)));
    g.wetC = float4(tex.read(uint2(32, 1))); g.wetD = float4(tex.read(uint2(33, 1)));
    g.water = float4(tex.read(uint2(34, 1))); g.wetE = float4(tex.read(uint2(35, 1)));
    g.waterB = float4(tex.read(uint2(36, 1)));
    half4 t29 = tex.read(uint2(29, 1));
    g.postcardAO = float(t29.x); g.postcardQuality = t29.w > 0.5h;
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
    // The 0.8 m detail fades out with distance (it would alias into speckle from the air); far
    // away only the 3.5 m patches (and, beyond ~600 m, their average) remain.
    float dist = length(wp - g.camera);
    float fine = 1.0 - smoothstep(40.0, 90.0, dist);
    float mid = 1.0 - smoothstep(300.0, 700.0, dist);
    float n18 = valueNoise(wp.xz / 18.0 + 7.3);
    float m = 0.40 * n18 + 0.40 * mix(0.5, valueNoise(wp.xz / 3.5 + 31.7), mid)
            + 0.20 * mix(0.5, valueNoise(wp.xz / 0.8), fine);
    // From the air (experience-v1 image 11: "broad irregular exposed and shaded snow patches"),
    // 25–60 m patches on rotated domains (value noise on one grid reads as blocks) with wide,
    // soft edges, so the ground mottles white and tan instead of reading as camouflage.
    float far = smoothstep(250.0, 900.0, dist);
    if (far > 0.0) {
        float2 q = wp.xz;
        float2 r1 = float2(0.8 * q.x - 0.6 * q.y, 0.6 * q.x + 0.8 * q.y);
        float2 r2 = float2(0.28 * q.x + 0.96 * q.y, -0.96 * q.x + 0.28 * q.y);
        float broad = 0.55 * valueNoise(r1 / 60.0 + 3.1) + 0.45 * valueNoise(r2 / 25.0 + 11.7);
        m = mix(m, broad, far);
    }
    float edge = mix(0.035, 0.15, far);
    // Calibrated so the covered share of eligible area ≈ coverage (see RenderResources).
    float t = mix(0.18, 0.86, pow(clamp(g.snow, 0.0, 1.0), 0.85));
    return up * (1.0 - smoothstep(t - edge, t + edge, m));
}

/// Fog distance along optical depth (experience-v1 aerial: "fog along optical depth: foreground
/// clear, outer blocks subtly softened"): haze thins with height (scale height 1500 m), so a ray
/// looking down from the aerial camera crosses less of it than a level ray of the same length.
/// At the spec's aerial pose the near edge stays ~10% hazed, the centre ~25%, the far edge ~70%
/// (1000 m left the aerial too crisp and dark against the concepts, P3's look loop).
/// Street views are effectively unchanged (rays stay within a few metres of the ground).
float opticalDistance(float dist, float h1, float h2) {
    const float H = 1500.0;
    float lo = max(min(h1, h2), 0.0), hi = max(max(h1, h2), 0.0);
    float dh = hi - lo;
    float f = dh < 1.0 ? exp(-lo / H) : H * (exp(-lo / H) - exp(-hi / H)) / dh;
    return dist * f;
}

/// Lighting bible atmosphere (look-fix-v1): a clear-air fade capped at `airCap` that reaches half
/// the cap at `airD50` (§2.3), and weather extinction with 90% of contrast gone at `fogEnd` (§3.2,
/// T = exp(−k·(d − start)), k = ln 10 / (end − start)) at strength `fogWeight`. Transmissions
/// multiply; the scattered colour is weighted by each part's contribution. xyz = colour, w = amount.
float4 atmosphere(Globals g, float od) {
    float air = g.airCap * (1.0 - exp(-0.693147 * max(0.0, od - g.airStart) / (g.airD50 - g.airStart)));
    float k = 2.302585 / max(g.fogEnd - g.fogStart, 1.0);
    // fogFloor: a haze already present at the camera (smoke fills the near field, not only distance).
    float wx = max(g.fogWeight * (1.0 - exp(-k * max(0.0, od - g.fogStart))), g.fogFloor * smoothstep(0.0, 8.0, od));
    float amount = 1.0 - (1.0 - air) * (1.0 - wx);
    float3 col = (air + wx) > 1e-4 ? (float3(g.airColor) * air + float3(g.fogColor) * wx) / (air + wx) : float3(g.fogColor);
    return float4(col, amount);
}

struct Surface {
    half3 base; half3 emissive; half roughness; half specular; half ao; bool cuttable;
    /// Takes wetness and snow (not water).
    bool weathered = true;
    /// Rain-pack surface: 0 other, 1 concrete walk, 2 asphalt road (paving collects puddles).
    int surfaceClass = 0;
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
    // Debug 5 (GPU attribution): skip the weather/ground extras.
    if (su.weathered && !(g.debug > 4.5 && g.debug < 5.5)) {
        // Wet ground from the rain pack (docs/proposals/rain-v1, rain-bible.json; values interpolated
        // by wetness on the CPU): per surface darkening, roughness and sky sheen
        // k = sheen·(1−|N·V|)³; puddles on flat paving mixing the sky by k = n + (g − n)·(1−|N·V|)⁵.
        // Walls get half (exposure). Rows: wetA concrete, wetB asphalt, wetC brick, wetD lawn, wetE roof.
        float exposure = mix(0.5, 1.0, smoothstep(0.3, 0.8, n.y));
        bool lawnLike = su.roughness > 0.9h && n.y > 0.6;
        float4 row = su.surfaceClass == 1 ? g.wetA : su.surfaceClass == 2 ? g.wetB
                   : lawnLike ? g.wetD : n.y > 0.6 ? g.wetE : g.wetC;
        if (g.wetness > 0.01) {
            float3 v = normalize(g.camera - wp);
            float nv = abs(dot(n, v));
            float3 r = reflect(-v, n);
            half3 sky = half3(mix(float3(g.skyHorizon), float3(g.skyTop), pow(clamp(r.y, 0.0, 1.0), 0.5)));
            su.base *= half(1.0 - row.x * exposure);
            su.roughness = min(su.roughness, half(row.y));
            half k = half(row.z * pow(1.0 - nv, 3.0) * exposure);
            su.base *= 1.0h - k;
            su.emissive += sky * k;
            if (su.surfaceClass > 0 && n.y > 0.95 && g.wetA.w > 0.0) {
                // Puddle mask: stable two-band field, threshold for the state's eligible coverage.
                float p = valueNoise(wp.xz / 2.0 + 13.1) * 0.7 + valueNoise(wp.xz / 0.7 + 5.7) * 0.3;
                float t = 0.157 + 1.33 * g.wetA.w;
                half puddle = half(1.0 - smoothstep(t - 0.02, t + 0.005, p));
                half kp = half(g.wetC.w + (g.wetD.w - g.wetC.w) * pow(1.0 - nv, 5.0));
                su.base = mix(su.base, su.base * (1.0h - kp), puddle);
                su.emissive = mix(su.emissive, su.emissive + sky * kp, puddle);
                su.roughness = mix(su.roughness, half(g.wetB.w), puddle);
                su.specular = mix(su.specular, 1.0h, puddle);
            }
        }
        // Snow covers patterns, leaves and wetness where it lies.
        half snow = half(snowMask(g, wp, n));
        // Paving (walks, roads) holds a thinner, patchier dusting than lawn, so a snowed path still
        // leads into the frame (look-fix §3.3 gives lawn 60–90% and no plowing; no tracks invented).
        if (su.surfaceClass > 0) { snow *= half(0.45 + 0.4 * valueNoise(wp.xz / 1.7 + 61.0)); }
        su.base = mix(su.base, g.snowColor, snow);
        su.roughness = mix(su.roughness, 0.85h, snow);
        su.specular = mix(su.specular, 0.25h, snow);
        su.ao = mix(su.ao, max(su.ao, 0.85h), snow);
    }
    half contact = contactShadow(g, rel, n);
    // R8 fill: hemispheric sky/ground, occluded by baked AO (floor 0.65). Emissive, so no extra
    // shadow-casting light.
    half hemi = half(n.y * 0.5 + 0.5);
    // Contact shading (look-fix §2.3: AO may take another 10–20% of ambient within 0.15–0.4 m of a
    // contact): upright surfaces darken softly toward the ground (wall bases, trunks, posts).
    half baseAO = abs(n.y) < 0.5 ? half(1.0 - 0.2 * (1.0 - smoothstep(0.05, 0.4, wp.y))) : 1.0h;
    half3 fill = su.base * mix(g.fillGround, g.fillSky, hemi) * max(0.65h, su.ao) * contact * baseAO;
    // Postcard quality mode only (never on screen): the baked contact AO takes a further share of
    // the fill (lighting bible §2.3: another 10–20% within a contact; open surfaces have AO 1).
    if (g.postcardQuality) { fill *= 1.0h - half(g.postcardAO) * (1.0h - su.ao); }
    // Atmosphere along optical depth (lighting bible: clear-air fade plus weather extinction).
    float4 atm = atmosphere(g, opticalDistance(dist, g.camera.y, wp.y));
    half fog = half(atm.w);
    s.set_base_color(su.base * contact * (1.0h - fog));
    s.set_emissive_color((fill + su.emissive) * (1.0h - fog) + half3(atm.xyz) * fog);
    s.set_roughness(su.roughness);
    s.set_specular(su.specular * (1.0h - fog));
    s.set_metallic(0.0h);
    s.set_ambient_occlusion(su.ao);
    s.set_opacity(su.leafCut ? 0.0h : (su.cuttable ? cutAway(g, rel, wp, n) : 1.0h));
    if (su.leafCut) {
        // Removed lobes must add nothing: transparent materials keep specular at zero opacity.
        s.set_base_color(half3(0.0h)); s.set_emissive_color(half3(0.0h)); s.set_specular(0.0h); s.set_roughness(1.0h);
    }
}

// ---- Context ring coverage fade (look-fix-v1 §4; WorldGen/Context/ContextRing.swift) --------------
// Context-ring vertices (flag 256) carry their coverage box in uv3 (scene x min, z min, x max, z max)
// and the fade width in paint.w. Over the last `width` metres inside the box the surface becomes the
// boundary plain under the world (backdrop slot, roughness 0.88, specular 0.3, AO 1), so the data
// ends without a cut. Mirrored on the CPU by ContextRing.fadeWeight (tests, offline renders).
constant uint kBackdropSlot = 17;   // SeasonalPalette.order index of "backdrop" (tested)

void contextCoverageFade(texture2d<half> tex, Globals g, thread Surface &su, float4 box, float width, float3 wp) {
    float d = min(min(wp.x - box.x, box.z - wp.x), min(wp.z - box.y, box.w - wp.z));
    half t = half(1.0 - smoothstep(0.0, max(width, 1.0), d));
    su.ao = 1.0h;
    if (t <= 0.0h) { return; }
    su.base = mix(su.base, srgbToLinear(tex.read(uint2(kBackdropSlot, 0)).rgb), t);
    su.roughness = mix(su.roughness, 0.88h, t);
    su.specular = mix(su.specular, 0.3h, t);
    // Toward the edge the ground is plain backdrop: no paving wet response or puddles.
    if (t > 0.5h) { su.surfaceClass = 0; }
}
// ---- end context ring ---------------------------------------------------------------------------

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
        // Lot lawns (P2 yards, look-fix-v1 §1.1): extra = (1, tone t, 0, seed > 0). The base runs
        // between the seasonal lawnA/lawnB endpoints (palette slots 18, 19) by the lot's tone, times
        // its value step (paint shade); the seed offsets the patch field so neighbours differ.
        float2 lot = float2(0.0);
        if (extra.w > 0.0) {
            half3 a = srgbToLinear(tex.read(uint2(18, 0)).rgb), b = srgbToLinear(tex.read(uint2(19, 0)).rgb);
            su.base = mix(a, b, half(clamp(extra.y, 0.0, 1.0))) * half(paint.y);
            lot = float2(extra.w * 173.0, extra.w * 291.0);
        }
        // R3 lawn mottling: two low-frequency bands; fine band fades out by 50 m.
        float broad = valueNoise(wp.xz / 2.6 + lot) - 0.5;
        float fine = (valueNoise(wp.xz / 0.45 + 17.0) - 0.5) * (1.0 - smoothstep(30.0, 50.0, dist));
        // On lot lawns the lot's own tone and value step carry the variation (P2 bakes per-lot patches
        // into the shade), so the world-space bands run at a third and don't wash across lot lines.
        float lotScale = extra.w > 0.0 ? 0.33 : 1.0;
        float v = broad * 0.12 * lotScale + fine * 0.07;
        su.base *= half(1.0 + v);
        half luma = dot(su.base, half3(0.2126h, 0.7152h, 0.0722h));
        su.base = mix(half3(luma), su.base, half(1.0 + broad * 0.08));
        // Art direction (Prompt 5): ordinary lawns vary in colour, drier warm patches and lusher
        // cool ones over ~10 m, so a clear day doesn't read as one flat green.
        if (!(g.debug > 4.5 && g.debug < 5.5)) {
        float patchv = valueNoise(wp.xz / 11.0 + 3.3 + lot) - 0.5 + (valueNoise(wp.xz / 4.0 + 8.1 + lot) - 0.5) * 0.5;
        half3 dry = su.base * half3(1.16h, 1.06h, 0.72h), lush = su.base * half3(0.86h, 1.0h, 0.93h);
        su.base = mix(su.base, patchv > 0.0 ? dry : lush, half(clamp(abs(patchv) * 2.0, 0.0, 0.75) * lotScale));
        }
        su.roughness = 0.95h; su.specular = 0.15h;
    }
    if (((flags & 4u) || (flags & 8u)) && !(g.debug > 4.5 && g.debug < 5.5)) {
        // Fallen leaves under real crowns (canopy map from tree positions) through leaf drop:
        // speckles near the camera, a tint further away; darker when wet; snow covers them.
        float2 cuv = (wp.xz - g.canopyOrigin) / g.canopySize;
        constexpr sampler cs(filter::linear, address::clamp_to_zero);
        float canopy = float(params.textures().base_color().sample(cs, cuv).r);
        float litter = g.leafLitter * canopy;
        if (litter > 0.01) {
            float near = 1.0 - smoothstep(25.0, 60.0, dist);
            float speck = valueNoise(wp.xz / 0.16 + 41.0);
            float cover = mix(litter * 0.45, (1.0 - smoothstep(litter * 0.7 - 0.05, litter * 0.7 + 0.05, 1.0 - speck)) , near);
            half3 leaf = mix(g.litterA, g.litterB, half(valueNoise(wp.xz / 0.3 + 9.0)));
            su.base = mix(su.base, leaf * (1.0h - 0.25h * half(g.wetness)), half(clamp(cover, 0.0, 0.85)));
        }
    }
    // Wet response beyond the bible's §3.1 ranges (owner: wet must read on a phone; at 18–30% pale
    // concrete still read dry): asphalt 40%, walks 35%, lawn 15%, puddles up to 16%/14%, (owner and P3: rain must
    // read at phone size; at W 0.65 the bible's 1–3% of walks didn't show):
    // asphalt 30% darker, roughness to 0.42, puddles up to 8%; concrete walks 18%, 0.58, up to 4%.
    if (flags & 16u) { su.surfaceClass = 2; }
    if (flags & 8u) {
        su.surfaceClass = 1;
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
    if (flags & 256u) { contextCoverageFade(tex, g, su, extra, paint.w, wp); }   // context ring
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
    // Snow settles on crowns, conifers, bushes and tufts, not on thin bark (it read as floating arcs).
    su.weathered = paint.w >= 0.45 || paint.w <= 0.0 && extra.y > 0.0;
    // Crown lobes carry a leaf threshold in extra.y (0 = trunk, branches, other foliage).
    float leaf = mix(g.leafFraction.y, g.leafFraction.z, u);
    su.leafCut = extra.y > 0.0 && extra.y > leaf + 1e-3;
    if (su.leafCut && extra.z > 0.5) {
        // A bare skyline crown (beyond 400 m and from the air) reads as the tree's twig mass: the
        // bark colour lifted toward grey, unsnowed, instead of vanishing (look-fix-v1 §5: retain
        // aggregate height and colour; winter aerials showed no trees at all).
        half3 bark = srgbToLinear(tex.read(uint2(15, 0)).rgb);
        half bare = half(1.0 - smoothstep(0.0, 0.5, leaf));
        su.base = mix(su.base, mix(bark, half3(dot(bark, half3(0.3h, 0.59h, 0.11h))), 0.35h) * 1.25h, bare);
        su.leafCut = false;
        su.weathered = false;
    }
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
    // Leaf drop: a lobe past its threshold collapses to a point inside the crown, so it draws
    // nothing at all (alpha-cut transparent surfaces still showed grazing-angle rims).
    float lobe = params.geometry().uv3().y;
    // Skyline crowns (uv3.z = 1) stay in bare seasons as a twig mass (see worldFoliageSurface).
    if (lobe > 0.0 && params.geometry().uv3().z < 0.5) {
        float u = hash12(origin.xz * 0.37 + 3.1);
        float leaf = mix(g.leafFraction.y, g.leafFraction.z, u);
        if (lobe > leaf + 1e-3) {
            float3 p = params.geometry().model_position();
            params.geometry().set_model_position_offset(float3(0.0, 0.5, 0.0) - p);
            return;
        }
    }
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
    // Water takes its colour mostly from the sky it reflects (look.json water): more under cloud,
    // and its saturation drops with cover, so a lake under rain reads slate, not pool-blue.
    float3 v = normalize(g.camera - wp);
    float3 r = reflect(-v, float3(0, 1, 0));
    half3 sky = half3(mix(float3(g.skyHorizon), float3(g.skyTop), pow(clamp(r.y, 0.0, 1.0), 0.5)));
    float cover = clamp(g.cloudCover, 0.0, 1.0);
    half k = half(mix(g.water.x, g.water.y, cover));
    // Under cloud the reflected sky dims to look.json overcastReflectGain: a storm lake is dark slate.
    su.base = mix(su.base, sky * half(mix(0.9, g.waterB.x, cover)), k);
    half lum = dot(su.base, half3(0.2126h, 0.7152h, 0.0722h));
    su.base = mix(half3(lum), su.base, half(mix(1.0, g.water.z, cover)));
    su.emissive = half3(0.0h);
    // Rain rings on open water while it rains (look.json water.rainRipples).
    if (g.wetE.w > 0.01) {
        float2 cell = floor(wp.xz / 0.8), f = fract(wp.xz / 0.8) - 0.5;
        float tt = fract(time * 0.8 + hash12(cell * 1.3 + 2.0));
        float ring = abs(length(f - (float2(hash12(cell + 5.0), hash12(cell + 9.0)) - 0.5) * 0.5) - tt * 0.4);
        su.emissive += sky * half((1.0 - smoothstep(0.0, 0.04, ring)) * (1.0 - tt) * g.water.w * g.wetE.w);
    }
    su.roughness = 0.45h; su.specular = 0.6h; su.ao = 1.0h; su.cuttable = false;
    su.weathered = false;
    if (uint(paint.z + 0.5) & 256u) { contextCoverageFade(tex, g, su, params.geometry().uv3(), paint.w, wp); }   // context ring
    finish(params, g, su, wp);
}

namespace {

/// Cloud cover on the dome at a view direction (shared by the sky and the stars behind it).
float cloudAt(Globals g, float3 d, float time) {
    if (g.cloudCover <= 0.01 || d.y <= 0.0) { return 0.0; }
    float2 drift = g.windDir * time * 0.004;
    float2 q = d.xz / max(d.y + 0.18, 0.18) * 1.6 + drift;
    float n = valueNoise(q) * 0.55 + valueNoise(q * 2.3 + 7.1) * 0.30 + valueNoise(q * 5.1 + 2.7) * 0.15;
    float c = clamp(g.cloudCover, 0.0, 1.0);
    // Overcast closes to a full deck; partial cover keeps soft edges. The threshold is the noise
    // quantile for the cover (computed on the CPU), so 25% cover shows about a quarter cloud.
    // Edges soften as the deck closes (look.json sky), so a gap in overcast never reads as a cut-out.
    float t = g.cloudThreshold;
    float e = mix(g.waterB.y, g.waterB.z, smoothstep(0.5, 1.0, c));
    float cover = smoothstep(t - e, t + e, n) * smoothstep(0.0, 0.12, d.y);
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
    float3 top = float3(g.skyTop), horizon = float3(g.skyHorizon);
    float3 c = mix(horizon, top, pow(clamp(d.y / 0.85, 0.0, 1.0), 0.5));
    // Haze: the last few degrees take the atmosphere's colour and amount at the far end of the
    // world (4 km), so distant geometry blends into the sky.
    float4 far = atmosphere(g, 4000.0);
    float3 fog = far.xyz;
    c = mix(c, fog, (1.0 - smoothstep(0.0, 0.10, d.y)) * max(far.w, 0.35));
    if (d.y < 0.0) { c = mix(c, fog, max(far.w, 0.5)); }
    // Sun: 0.27° disk with a soft edge and glow, hidden by cloud.
    float cloud = cloudAt(g, d, time);
    float cosA = dot(d, normalize(g.sunDir));
    float disk = smoothstep(cos(0.30 * M_PI_F / 180.0), cos(0.24 * M_PI_F / 180.0), cosA);
    float glow = pow(max(0.0, cosA), 60.0) * 0.35 + pow(max(0.0, cosA), 8.0) * 0.08;
    // Sunset glow: a low sun warms a wide patch of sky around it (v2 01, experience-v1 01).
    float low = 1.0 - smoothstep(2.0, 20.0, asin(clamp(normalize(g.sunDir).y, -1.0, 1.0)) * 180.0 / M_PI_F);
    glow += low * (pow(max(0.0, cosA), 4.0) * 0.22 + pow(max(0.0, cosA), 16.0) * 0.25);
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
    // Clouds over the gradient: brighter toward the sun (warm at golden hour), slightly darker
    // bases low in the sky, so fair-weather cloud gives a clear day some interest.
    float3 sunD = normalize(g.sunDir);
    float silver = pow(max(0.0, dot(d, sunD)), 5.0) * 0.6 + pow(max(0.0, dot(d, sunD)), 40.0) * 0.6;
    // Billows: lighter tops and darker bases from a second noise sample, so a deck has texture.
    float2 q2 = d.xz / max(d.y + 0.18, 0.18) * 3.1 + g.windDir * time * 0.006;
    float billow = valueNoise(q2) * 0.6 + valueNoise(q2 * 2.7 + 3.3) * 0.4;
    float3 cc = float3(g.cloudColor) * (0.78 + 0.34 * billow) * (0.88 + 0.22 * smoothstep(0.0, 0.5, d.y))
              + float3(g.sunDisk) * silver * 0.35 * (1.0 - smoothstep(0.5, 1.0, clamp(g.cloudCover, 0.0, 1.0)));
    c = mix(c, cc, cloud);
    auto s = params.surface();
    // Unlit material: RealityKit shows the emissive colour (the base colour is ignored).
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
    float bright = clamp((length(params.uniforms().model_to_world()[0].xyz) - 10.0) / 18.0, 0.15, 1.0);
    float a = core * core * g.starStrength * (0.35 + 0.65 * bright) * (1.0 - cloud) * smoothstep(0.0, 0.05, d.y);
    auto s = params.surface();
    s.set_base_color(half3(0.0h));
    s.set_emissive_color(half3(a * 1.6));
    s.set_opacity(half(a));
}
