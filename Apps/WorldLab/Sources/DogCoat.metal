#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

// Luna's coat. RealityKit's standard material ignores vertex colors, so this reads COLOR_0
// (coat color × baked AO, linear) and adds two terms the world's own shaders also use:
// the hemispheric sky/ground fill (custom.rgb = sky fill) and a soft rim so a black coat
// stays readable (custom.a = rim strength). The three.js renderer uses the same formula.
[[visible]]
void dogCoatSurface(realitykit::surface_parameters params) {
    auto g = params.geometry();
    half3 coat = half3(g.color().rgb);
    float3 n = normalize(g.normal());
    float3 v = normalize(g.view_direction());
    float4 c = params.uniforms().custom_parameter();
    half hemi = half(n.y * 0.5 + 0.5);
    half3 skyFill = half3(c.rgb);
    half3 fill = coat * mix(skyFill * 0.35h, skyFill, hemi);
    half rim = half(pow(1.0 - saturate(abs(dot(n, v))), 3.0)) * half(c.a);
    auto s = params.surface();
    s.set_base_color(coat);
    s.set_roughness(0.7h);
    s.set_metallic(0.0h);
    s.set_emissive_color(fill + rim * half3(0.60h, 0.56h, 0.50h));
}
