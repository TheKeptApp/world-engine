// World materials, ported line for line from Sources/WorldEngine/Shaders/WorldShaders.metal.
// The meaning and constants are specified in the package's materials.json; keep all three in step.
import * as THREE from 'three/webgpu';
import {
  Fn, If, abs, attribute, cameraPosition, clamp, cos, dot, float, floor, fract, fwidth, int, length, max, min, mix,
  normalize, normalWorld, positionLocal, positionWorld, select, sin, smoothstep, texture, time, uniform, vec2, vec3,
} from 'three/tsl';

/** sRGB (0–1) → linear, IEC 61966-2-1 (same curve as the Metal srgbToLinear). */
export function srgbToLinear(c) {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** Per-frame values shared by every world material (the Metal "globals" row). */
export function createGlobals() {
  return {
    fogColor: uniform(new THREE.Color(0, 0, 0)),
    fogStart: uniform(350),
    fogEnd: uniform(1100),
    fillSky: uniform(new THREE.Color(0, 0, 0)),
    fillGround: uniform(new THREE.Color(0, 0, 0)),
    litFraction: uniform(0),
    litWindow: uniform(new THREE.Color(0, 0, 0)), // linear
    cutEnabled: uniform(0),
    cutRadius: uniform(1.1),
    character: uniform(new THREE.Vector3()),
    contactPos: uniform(new THREE.Vector3()),
    contactHalf: uniform(new THREE.Vector2(0.2, 0.2)),
    contactHeading: uniform(0),
    contactOpacity: uniform(0),
    contactSoftness: uniform(0.12),
  };
}

/** The palette as a 256 × 1 float texture of linear colors (slot = x). */
export function createPaletteTexture() {
  const data = new Float32Array(256 * 4);
  const tex = new THREE.DataTexture(data, 256, 1, THREE.RGBAFormat, THREE.FloatType);
  tex.magFilter = THREE.NearestFilter;
  tex.minFilter = THREE.NearestFilter;
  tex.generateMipmaps = false;
  tex.colorSpace = THREE.NoColorSpace;
  tex.needsUpdate = true;
  return tex;
}

/** Fills the palette texture from palettes.json slots, with the seasonal slots for `season`. */
export function setPalette(tex, palettes, season) {
  const data = tex.image.data;
  const hexes = palettes.slots.map((s) => s.srgb);
  for (const key of Object.keys(palettes.seasonalSlots)) {
    const s = palettes.seasonalSlots[key];
    hexes[s.slot] = s.srgb[season];
  }
  hexes.forEach((hex, i) => {
    const v = parseInt(hex.slice(1), 16);
    data[i * 4] = srgbToLinear(((v >> 16) & 255) / 255);
    data[i * 4 + 1] = srgbToLinear(((v >> 8) & 255) / 255);
    data[i * 4 + 2] = srgbToLinear((v & 255) / 255);
    data[i * 4 + 3] = 1;
  });
  tex.needsUpdate = true;
}

const hash12 = Fn(([p]) => {
  const p3 = fract(vec3(p.x, p.y, p.x).mul(0.1031)).toVar();
  p3.addAssign(dot(p3, p3.yzx.add(33.33)));
  return fract(p3.x.add(p3.y).mul(p3.z));
});

const valueNoise = Fn(([p]) => {
  const i = floor(p), f = fract(p);
  const u = f.mul(f).mul(f.mul(-2).add(3));
  const a = hash12(i), b = hash12(i.add(vec2(1, 0))), c = hash12(i.add(vec2(0, 1))), d = hash12(i.add(vec2(1, 1)));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
});

const hasFlag = (flags, bit) => flags.bitAnd(int(bit)).notEqual(int(0));

/**
 * Builds one of the four world materials. kind: 'static' | 'prop' | 'foliage' | 'water'.
 * Instanced props carry a per-instance `instOrigin` attribute (the instance translation), which
 * plays the role of model_to_world[3] in Metal.
 */
export function createWorldMaterial(kind, g, paletteTex) {
  const material = new THREE.MeshPhysicalNodeMaterial();
  material.name = `world-${kind}`;
  material.metalness = 0;
  const instanced = kind === 'prop' || kind === 'foliage';

  const paint = attribute('_paint', 'vec4');
  const extra = attribute('_extra', 'vec4');
  const origin = instanced ? attribute('instOrigin', 'vec3') : vec3(0, 0, 0);
  const wp = positionWorld;
  const n = normalize(normalWorld);
  const dist = length(wp.sub(cameraPosition));
  const flags = int(paint.z.add(0.5));
  const ao = extra.x;

  // Palette lookup with per-instance variants.
  const slot = floor(paint.x.add(0.5))
    .add(select(hasFlag(flags, 32), floor(hash12(origin.xz.mul(0.173)).mul(3.999)), 0))
    .add(select(hasFlag(flags, 64), floor(hash12(origin.xz.mul(0.211)).mul(1.999)), 0));
  const paletteColor = texture(paletteTex, vec2(slot.add(0.5).div(256), 0.5)).rgb.mul(paint.y);

  let base = paletteColor, emissive = vec3(0, 0, 0), roughness = float(0.88), specular = float(0.3);
  if (kind === 'static') {
    const isLawn = hasFlag(flags, 4), isSidewalk = hasFlag(flags, 8), isGlass = hasFlag(flags, 1), isEmissive = hasFlag(flags, 2);
    // R3 lawn mottling (branch: only lawn fragments pay for the noise).
    const lawn = Fn(([c, isLawn, dist]) => {
      const out = vec3(c).toVar();
      If(isLawn, () => {
        const broad = valueNoise(wp.xz.div(2.6)).sub(0.5);
        const fine = valueNoise(wp.xz.div(0.45).add(17)).sub(0.5).mul(float(1).sub(smoothstep(30, 50, dist)));
        const v = out.mul(broad.mul(0.1).add(fine.mul(0.06)).add(1));
        const luma = dot(v, vec3(0.2126, 0.7152, 0.0722));
        out.assign(mix(vec3(luma), v, broad.mul(0.08).add(1)));
      });
      return out;
    });
    // R7 sidewalk joints.
    const joints = Fn(([c, isSidewalk, along, dist]) => {
      const out = vec3(c).toVar();
      If(isSidewalk, () => {
        const u = along.div(1.75);
        const w = max(fwidth(u), 1e-4);
        const distToJoint = abs(fract(u.add(0.5)).sub(0.5));
        const halfWidth = 0.006 / 1.75;
        const line = float(1).sub(smoothstep(halfWidth, w.mul(1.5).add(halfWidth), distToJoint))
          .mul(float(1).sub(smoothstep(35, 60, dist))).mul(clamp(float(halfWidth * 4).div(w), 0, 1));
        out.mulAssign(float(1).sub(line.mul(0.14)));
      });
      return out;
    });
    const litOn = isGlass.and(extra.y.lessThan(g.litFraction));
    const b2 = joints(lawn(paletteColor, isLawn, dist), isSidewalk, extra.z, dist);
    const b3 = select(litOn, b2.mul(0.4), b2);
    base = b3;
    emissive = select(isEmissive, b3.mul(g.litFraction.mul(2).add(0.25)), select(litOn, vec3(g.litWindow).mul(1.4), vec3(0, 0, 0)));
    roughness = select(isLawn, 0.95, select(isGlass, 0.35, 0.88));
    specular = select(isLawn, 0.15, select(isGlass, 0.55, 0.3));
  } else if (kind === 'prop') {
    base = paletteColor;
    emissive = select(hasFlag(flags, 2), base.mul(g.litFraction.mul(2).add(0.25)), vec3(0, 0, 0));
    roughness = float(0.75); specular = float(0.35);
  } else if (kind === 'foliage') {
    base = paletteColor.mul(hash12(origin.xz.mul(0.37)).mul(0.1).add(0.95));
    emissive = base.mul(0.05).mul(ao);
    roughness = float(0.95); specular = float(0.1);
  } else if (kind === 'water') {
    const ripple = valueNoise(wp.xz.mul(0.05).add(vec2(time.mul(0.02), time.mul(0.013))));
    base = paletteColor.mul(ripple.mul(0.08).add(0.95));
    roughness = float(0.45); specular = float(0.6);
  }

  // R8 contact shadow under the character.
  const dc = wp.sub(g.contactPos);
  const s = sin(g.contactHeading), co = cos(g.contactHeading);
  const local = vec2(dc.x.mul(co).sub(dc.z.mul(s)), dc.x.mul(s).add(dc.z.mul(co)));
  const r = length(local.div(max(g.contactHalf, vec2(0.05))));
  const edge = g.contactSoftness.div(max(min(g.contactHalf.x, g.contactHalf.y), 0.05));
  const mask = float(1).sub(smoothstep(float(1).sub(edge), float(1).add(edge), r));
  const contact = select(g.contactOpacity.greaterThan(0).and(n.y.greaterThanEqual(0.85)).and(abs(dc.y).lessThanEqual(0.25)),
    float(1).sub(g.contactOpacity.mul(mask)), float(1));

  // R8 fill (emissive) and fog.
  const hemi = n.y.mul(0.5).add(0.5);
  const fill = base.mul(mix(vec3(g.fillGround), vec3(g.fillSky), hemi)).mul(max(0.65, ao)).mul(contact);
  const fog = smoothstep(g.fogStart, g.fogEnd, dist).mul(0.96);
  const dbg = new URLSearchParams(globalThis.location?.search || '').get('matdebug');
  if (dbg === 'plain' && kind === 'static') { material.colorNode = paletteColor; return material; }
  material.colorNode = base.mul(contact).mul(float(1).sub(fog));
  material.emissiveNode = fill.add(emissive).mul(float(1).sub(fog)).add(vec3(g.fogColor).mul(fog));
  material.roughnessNode = roughness;
  // RealityKit's `specular` 0.5 is the default 4% dielectric reflectance, three's specularIntensity 1.
  if (dbg !== 'nospec') material.specularIntensityNode = specular.mul(float(1).sub(fog)).mul(2);
  if (dbg !== 'noao') material.aoNode = ao;

  if (instanced) {
    // Cut-away: dither out fragments near the camera→character segment (alpha test discards).
    const c = vec3(g.character).sub(cameraPosition);
    const len = length(c);
    const rel = wp.sub(cameraPosition);
    const t = dot(rel, c).div(len.mul(len));
    const tEnd = float(1).sub(float(0.4).div(len));
    const d = length(rel.sub(c.mul(t)));
    const keep = smoothstep(g.cutRadius.mul(0.55), g.cutRadius, d);
    const noise = hash12(floor(wp.xz.mul(22)).add(floor(wp.y.mul(22)).mul(17)));
    const ground = n.y.greaterThan(0.85).and(wp.y.lessThan(0.3));
    const cut = g.cutEnabled.greaterThan(0.5).and(len.greaterThanEqual(0.5)).and(t.greaterThan(0)).and(t.lessThan(tEnd))
      .and(ground.not()).and(keep.lessThanEqual(noise));
    material.opacityNode = select(cut, float(0), float(1));
    material.alphaTest = 0.5;
  }

  if (kind === 'foliage') {
    // R10 slow sway (model space): trunks nearly fixed, crown tops a few centimeters.
    const sway = paint.w;
    const phase = origin.x.mul(0.31).add(origin.z.mul(0.23));
    const amp = float(0.0025).mul(sway).mul(positionLocal.y);
    const offset = vec3(sin(time.mul(0.9).add(phase)), 0, cos(time.mul(0.7).add(phase.mul(1.7)))).mul(amp);
    material.positionNode = positionLocal.add(select(sway.greaterThan(0), offset, vec3(0, 0, 0)));
  }
  return material;
}
